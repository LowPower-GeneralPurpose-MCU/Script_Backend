`timescale 1ns / 1ps

// =============================================================================
// MAIN MODULE: Tightly Coupled Memory
// =============================================================================
//
// A TCM is attached straight to the core ports, ahead of the caches and
// entirely off the AXI interconnect.  That is the whole point: an access can
// never miss and can never queue behind a DMA burst, so its latency is a
// constant instead of a distribution.
//
// Latency, in clk_cpu cycles, measured from the cycle the core presents the
// request to the cycle `hit` is asserted:
//
//   read                      2   (macro address phase + registered dataout)
//   write, full 32-bit word   2
//   write, byte or halfword   3   (read-modify-write: the ASAP7 macro has no
//                                  byte-write mask)
//
// This is NOT zero-wait-state.  srambank_256x4x32_6t122 registers its output,
// so the earliest any macro-backed memory can answer is the cycle after the
// address.  A cache hit costs the same 2 cycles (IDLE + LOOKUP); what the TCM
// removes is the miss case and the bus, not the pipeline cycle.  Going to one
// cycle would need the core to present the address a cycle early, which is a
// change in riscv_pipeline.v, not here.
//
// Two request ports, fixed priority:
//   port D (load/store unit) always wins
//   port F (instruction fetch) stalls while D owns the macro
//
// Port F exists so an ITCM can be fetched from.  Port D is how software copies
// code into that ITCM in the first place, and it is the only port a DTCM
// needs, so a DTCM instance ties port F off (HAS_FETCH_PORT = 0).
//
// Contention between the two ports only happens while code is being copied
// into the ITCM, which is a boot-time activity; steady-state fetch never
// stalls.
// =============================================================================
module tcm #(
    parameter SIZE_BYTES     = 16384,
    parameter HAS_FETCH_PORT = 1,
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // --- Port F: instruction fetch, read only, lower priority --------------
    input  wire                    f_req,
    input  wire [ADDR_WIDTH-1:0]   f_addr,
    output reg  [DATA_WIDTH-1:0]   f_rdata,
    output reg                     f_hit,
    output reg                     f_stall,

    // --- Port D: load/store, higher priority -------------------------------
    input  wire                    d_rd_req,
    input  wire                    d_wr_req,
    input  wire [ADDR_WIDTH-1:0]   d_addr,
    input  wire [DATA_WIDTH-1:0]   d_wdata,
    input  wire [1:0]              d_size,
    input  wire                    d_unsigned,
    output reg  [DATA_WIDTH-1:0]   d_rdata,
    output reg                     d_hit,
    output reg                     d_stall
);

    localparam WORD_ADDR_W = $clog2(SIZE_BYTES / 4);
    localparam BYTE_ADDR_W = WORD_ADDR_W + 2;

    // Same helpers as data_cache, so a load from TCM and a load from cache
    // extend identically.
    function automatic [31:0] read_data_with_size;
        input [31:0] data; input [1:0] size; input [1:0] offset; input unsigned_flag;
        reg [31:0] res;
        begin
            case (size)
                2'b10: res = data;
                2'b01: res = (offset[1] == 0)
                             ? (unsigned_flag ? {16'b0, data[15:0]}  : {{16{data[15]}}, data[15:0]})
                             : (unsigned_flag ? {16'b0, data[31:16]} : {{16{data[31]}}, data[31:16]});
                2'b00: begin
                    case (offset)
                        2'b00: res = unsigned_flag ? {24'b0, data[7:0]}   : {{24{data[7]}},  data[7:0]};
                        2'b01: res = unsigned_flag ? {24'b0, data[15:8]}  : {{24{data[15]}}, data[15:8]};
                        2'b10: res = unsigned_flag ? {24'b0, data[23:16]} : {{24{data[23]}}, data[23:16]};
                        2'b11: res = unsigned_flag ? {24'b0, data[31:24]} : {{24{data[31]}}, data[31:24]};
                    endcase
                end
                default: res = data;
            endcase
            read_data_with_size = res;
        end
    endfunction

    function automatic [31:0] merge_write_data;
        input [31:0] orig_data; input [31:0] w_data; input [1:0] size; input [1:0] offset;
        reg [31:0] res;
        begin
            res = orig_data;
            case (size)
                2'b10: res = w_data;
                2'b01: if (offset[1] == 0) res[15:0] = w_data[15:0];
                       else                res[31:16] = w_data[15:0];
                2'b00: case (offset)
                           2'b00: res[7:0]   = w_data[7:0];
                           2'b01: res[15:8]  = w_data[7:0];
                           2'b10: res[23:16] = w_data[7:0];
                           2'b11: res[31:24] = w_data[7:0];
                       endcase
                default: res = w_data;
            endcase
            merge_write_data = res;
        end
    endfunction

    // S_IDLE    address phase: the macro request is issued here
    // S_RESP    macro dataout is valid; a read and a full-word write end here,
    //           and a sub-word write issues its merged write-back here
    // S_RMW_ACK the merged write has committed; the sub-word write ends here
    localparam S_IDLE    = 2'd0,
               S_RESP    = 2'd1,
               S_RMW_ACK = 2'd2;

    localparam OWNER_F = 1'b0,
               OWNER_D = 1'b1;

    reg [1:0]              state;
    reg                    owner;
    // Set when a fetch was ready to go but lost the macro to the data port.
    // It lets that fetch win the next arbitration, so a run of back-to-back
    // loads and stores cannot hold instruction fetch off indefinitely.
    reg                    f_starved;
    reg [BYTE_ADDR_W-1:0]  addr_q;
    reg [DATA_WIDTH-1:0]   wdata_q;
    reg [1:0]              size_q;
    reg                    unsigned_q;
    reg                    is_write_q;
    reg                    is_subword_q;

    wire fetch_req = (HAS_FETCH_PORT != 0) && f_req;
    wire data_req  = d_rd_req || d_wr_req;

    // Port D wins, except against a fetch that already lost once.
    wire f_priority = fetch_req && f_starved;
    wire grant_d    = data_req && !f_priority;
    wire grant_f    = fetch_req && (!data_req || f_starved);
    wire start      = (state == S_IDLE) && (grant_d || grant_f);

    wire [BYTE_ADDR_W-1:0] start_addr = grant_d ? d_addr[BYTE_ADDR_W-1:0]
                                                : f_addr[BYTE_ADDR_W-1:0];
    wire                   start_wr   = grant_d && d_wr_req;
    wire                   start_sub  = start_wr && (d_size != 2'b10);

    // ---- macro request -----------------------------------------------------
    reg                    mem_read;
    reg                    mem_write;
    reg [BYTE_ADDR_W-1:0]  mem_addr;
    reg [DATA_WIDTH-1:0]   mem_wdata;
    wire [DATA_WIDTH-1:0]  mem_rdata;

    always @(*) begin
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_addr  = {BYTE_ADDR_W{1'b0}};
        mem_wdata = {DATA_WIDTH{1'b0}};

        case (state)
            S_IDLE: begin
                if (start) begin
                    mem_addr = start_addr;
                    // A full-word write goes straight into the macro.  Anything
                    // else needs the stored word first: a read to return, or a
                    // read to merge byte lanes into.
                    if (start_wr && !start_sub) begin
                        mem_write = 1'b1;
                        mem_wdata = d_wdata;
                    end else begin
                        mem_read = 1'b1;
                    end
                end
            end

            S_RESP: begin
                if (is_write_q && is_subword_q) begin
                    mem_write = 1'b1;
                    mem_addr  = addr_q;
                    mem_wdata = merge_write_data(mem_rdata, wdata_q,
                                                 size_q, addr_q[1:0]);
                end
            end

            default: begin
                mem_read  = 1'b0;
                mem_write = 1'b0;
            end
        endcase
    end

    asap7_sram_1rw #(
        .ADDR_W (WORD_ADDR_W),
        .DATA_W (DATA_WIDTH)
    ) u_mem (
        .clk   (clk),
        .read  (mem_read),
        .write (mem_write),
        .addr  (mem_addr[BYTE_ADDR_W-1:2]),
        .wdata (mem_wdata),
        .rdata (mem_rdata)
    );

    // ---- sequencing --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            owner        <= OWNER_F;
            f_starved    <= 1'b0;
            addr_q       <= {BYTE_ADDR_W{1'b0}};
            wdata_q      <= {DATA_WIDTH{1'b0}};
            size_q       <= 2'b10;
            unsigned_q   <= 1'b0;
            is_write_q   <= 1'b0;
            is_subword_q <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    // A fetch that is ready but not granted this cycle earns
                    // priority for the next one; winning clears the claim.
                    if (fetch_req && !grant_f)
                        f_starved <= 1'b1;
                    else if (grant_f)
                        f_starved <= 1'b0;

                    if (start) begin
                        state        <= S_RESP;
                        owner        <= grant_d ? OWNER_D : OWNER_F;
                        addr_q       <= start_addr;
                        wdata_q      <= d_wdata;
                        size_q       <= grant_d ? d_size : 2'b10;
                        unsigned_q   <= grant_d ? d_unsigned : 1'b0;
                        is_write_q   <= start_wr;
                        is_subword_q <= start_sub;
                    end
                end

                // The merged write is issued during S_RESP and commits on the
                // edge into S_RMW_ACK, so no separate write state is needed.
                S_RESP:    state <= (is_write_q && is_subword_q) ? S_RMW_ACK : S_IDLE;
                S_RMW_ACK: state <= S_IDLE;
                default:   state <= S_IDLE;
            endcase
        end
    end

    // ---- port responses ----------------------------------------------------
    //
    // `hit` is a single-cycle pulse on the resolving cycle and `stall` is high
    // for every cycle before it, matching the convention icache/dcache use so
    // the core sees one interface.
    wire resolve_read  = (state == S_RESP) && !is_write_q;
    wire resolve_write = ((state == S_RESP) && is_write_q && !is_subword_q) ||
                         (state == S_RMW_ACK);
    wire resolve       = resolve_read || resolve_write;

    always @(*) begin
        f_rdata = {DATA_WIDTH{1'b0}};
        f_hit   = 1'b0;
        f_stall = 1'b0;
        d_rdata = {DATA_WIDTH{1'b0}};
        d_hit   = 1'b0;
        d_stall = 1'b0;

        // Fetch is held off while the data port owns the macro, and while its
        // own access is still in flight.
        if (fetch_req && !(resolve && (owner == OWNER_F)))
            f_stall = 1'b1;
        if (data_req && !(resolve && (owner == OWNER_D)))
            d_stall = 1'b1;

        if (resolve && (owner == OWNER_F)) begin
            f_hit   = 1'b1;
            f_rdata = mem_rdata;
        end

        if (resolve && (owner == OWNER_D)) begin
            d_hit   = 1'b1;
            if (!is_write_q)
                d_rdata = read_data_with_size(mem_rdata, size_q,
                                              addr_q[1:0], unsigned_q);
        end
    end

    wire _unused_ok = &{1'b0, f_addr[ADDR_WIDTH-1:BYTE_ADDR_W],
                        d_addr[ADDR_WIDTH-1:BYTE_ADDR_W]};

endmodule
