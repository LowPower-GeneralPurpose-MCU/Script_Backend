`timescale 1ns / 1ps

// AXI4 SRAM slave for ASAP7 hard SRAM macros, sized by MEM_DEPTH.
//
// Memory implementation:
//   MEM_DEPTH words x 32 bits, built from srambank_256x4x32_6t122 macros
//   through asap7_sram_1rw, which banks 1024-word macros automatically.
//   MEM_DEPTH = 32768 -> 128 KiB -> 32 macros
//   MEM_DEPTH = 65536 -> 256 KiB -> 64 macros
//
// Important implementation choice:
//   The ASAP7 macro is single-port 1RW and has no byte-write mask.
//   One instance therefore serializes SRAM accesses across its own address
//   range: two instances on two interconnect slave ports are what makes CPU
//   and DMA traffic actually concurrent, not the bank decode inside one
//   instance.  See the system RAM split in top_soc.v.
//   Partial AXI writes (WSTRB != 4'b1111) are implemented by read-modify-write,
//   which costs two extra macro cycles: one to read the stored word, one to
//   write the merged word back.
//
//   Who pays it: only the CPU write-through path.  dma_axi_master always
//   drives WSTRB = 4'b1111 (see its WSTRB assign), so DMA traffic never
//   read-modify-writes.  The cost falls on sb/sh stores forwarded by the
//   write-through D-cache, and on debug-module writes.
//
// Supported:
//   DATA_WIDTH = 32
//   32-bit aligned transfers (AxSIZE = 3'd2)
//   FIXED and INCR bursts
//
// Unsupported:
//   WRAP bursts and unaligned/non-32-bit transfers return SLVERR.
//
// This is a correctness-first implementation for ASIC macro integration.
// A single instance intentionally does not attempt multi-bank concurrent
// access; concurrency comes from instantiating several of them.

module axi_ram #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 5,
    // ADDR_MASK must select exactly the MEM_DEPTH words this instance owns:
    //   MEM_DEPTH = 32768 -> ADDR_MASK = 32'h0001_FFFF
    //   MEM_DEPTH = 65536 -> ADDR_MASK = 32'h0003_FFFF
    parameter ADDR_MASK  = 32'h0001_FFFF,
    // Must be a power of two; asap7_sram_1rw banks it into 1024-word macros.
    parameter MEM_DEPTH  = 32768
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // AXI write address
    input  wire [ID_WIDTH-1:0]       s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [7:0]                s_axi_awlen,
    input  wire [2:0]                s_axi_awsize,
    input  wire [1:0]                s_axi_awburst,
    input  wire                      s_axi_awlock,
    input  wire [3:0]                s_axi_awcache,
    input  wire [2:0]                s_axi_awprot,
    input  wire [3:0]                s_axi_awqos,
    input  wire [3:0]                s_axi_awregion,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    // AXI write data
    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                      s_axi_wlast,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    // AXI write response
    output reg  [ID_WIDTH-1:0]       s_axi_bid,
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    // AXI read address
    input  wire [ID_WIDTH-1:0]       s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [7:0]                s_axi_arlen,
    input  wire [2:0]                s_axi_arsize,
    input  wire [1:0]                s_axi_arburst,
    input  wire                      s_axi_arlock,
    input  wire [3:0]                s_axi_arcache,
    input  wire [2:0]                s_axi_arprot,
    input  wire [3:0]                s_axi_arqos,
    input  wire [3:0]                s_axi_arregion,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    // AXI read data
    output reg  [ID_WIDTH-1:0]       s_axi_rid,
    output reg  [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rlast,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready
);

    localparam [1:0] AXI_OKAY   = 2'b00;
    localparam [1:0] AXI_SLVERR = 2'b10;

    localparam [1:0] AXI_BURST_FIXED = 2'b00;
    localparam [1:0] AXI_BURST_INCR  = 2'b01;

    // Unified controller states. One SRAM operation is active at a time.
    localparam [3:0]
        S_IDLE       = 4'd0,
        S_W_WAIT     = 4'd1,
        S_W_RMW_READ = 4'd2,
        S_W_WRITE    = 4'd3,
        S_W_RESP     = 4'd4,
        S_R_ISSUE    = 4'd5,
        S_R_WAIT     = 4'd6,
        S_R_SEND     = 4'd7;

    reg [3:0] state;

    // Byte address width of this instance: MEM_DEPTH words of 4 bytes.
    localparam WORD_ADDR_W = $clog2(MEM_DEPTH);
    localparam BYTE_ADDR_W = WORD_ADDR_W + 2;

    // Write burst context
    reg [ADDR_WIDTH-1:0] w_addr_reg;
    reg [7:0]            w_len_reg;
    reg                  w_incr_reg;
    reg [7:0]            w_count_reg;
    reg                  w_error_reg;
    reg                  w_drop_reg;

    // Current accepted W beat
    reg [31:0] wdata_hold;
    reg [3:0]  wstrb_hold;
    reg        w_finish_hold;

    // Read burst context
    reg [ID_WIDTH-1:0]   r_id_reg;
    reg [ADDR_WIDTH-1:0] r_addr_reg;
    reg [7:0]            r_len_reg;
    reg                  r_incr_reg;
    reg [7:0]            r_count_reg;
    reg                  r_error_reg;

    // Hard-macro SRAM interface
    reg         mem_read;
    reg         mem_write;
    reg  [BYTE_ADDR_W-1:0] mem_addr;
    reg  [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    // The slave accepts only 32-bit aligned transfers.
    // INCR bursts therefore advance by exactly four bytes.

    wire aw_request_invalid =
        (s_axi_awsize != 3'd2) ||
        (s_axi_awaddr[1:0] != 2'b00) ||
        !((s_axi_awburst == AXI_BURST_FIXED) ||
          (s_axi_awburst == AXI_BURST_INCR));

    wire ar_request_invalid =
        (s_axi_arsize != 3'd2) ||
        (s_axi_araddr[1:0] != 2'b00) ||
        !((s_axi_arburst == AXI_BURST_FIXED) ||
          (s_axi_arburst == AXI_BURST_INCR));

    // ASAP7 macro bank array.  asap7_sram_1rw decodes the upper word-address
    // bits into 1024-word macros, so MEM_DEPTH alone sets the macro count.
    asap7_sram_1rw #(
        .ADDR_W (WORD_ADDR_W),
        .DATA_W (32)
    ) u_mem (
        .clk   (clk),
        .read  (mem_read),
        .write (mem_write),
        .addr  (mem_addr[BYTE_ADDR_W-1:2]),
        .wdata (mem_wdata),
        .rdata (mem_rdata)
    );

    // Drive macro request from controller state.
    always @(*) begin
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_addr  = {BYTE_ADDR_W{1'b0}};
        mem_wdata = 32'b0;

        case (state)
            S_W_RMW_READ: begin
                mem_read = 1'b1;
                mem_addr = w_addr_reg[BYTE_ADDR_W-1:0] & ADDR_MASK[BYTE_ADDR_W-1:0];
            end

            S_W_WRITE: begin
                mem_write = 1'b1;
                mem_addr  = w_addr_reg[BYTE_ADDR_W-1:0] & ADDR_MASK[BYTE_ADDR_W-1:0];

                // Inline byte-lane merge for partial writes.
                // For a full write all four byte lanes are replaced.
                mem_wdata = mem_rdata;
                if (wstrb_hold[0]) mem_wdata[7:0]   = wdata_hold[7:0];
                if (wstrb_hold[1]) mem_wdata[15:8]  = wdata_hold[15:8];
                if (wstrb_hold[2]) mem_wdata[23:16] = wdata_hold[23:16];
                if (wstrb_hold[3]) mem_wdata[31:24] = wdata_hold[31:24];
            end

            S_R_ISSUE: begin
                mem_read = 1'b1;
                mem_addr = r_addr_reg[BYTE_ADDR_W-1:0] & ADDR_MASK[BYTE_ADDR_W-1:0];
            end

            default: begin
                mem_read  = 1'b0;
                mem_write = 1'b0;
            end
        endcase
    end



    always @(posedge clk) begin
        if (!rst_n) begin
            state          <= S_IDLE;

            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bid      <= {ID_WIDTH{1'b0}};
            s_axi_bresp    <= AXI_OKAY;

            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rid      <= {ID_WIDTH{1'b0}};
            s_axi_rdata    <= 32'b0;
            s_axi_rresp    <= AXI_OKAY;
            s_axi_rlast    <= 1'b0;

            w_addr_reg     <= {ADDR_WIDTH{1'b0}};
            w_len_reg      <= 8'b0;
            w_incr_reg     <= 1'b0;
            w_count_reg    <= 8'b0;
            w_error_reg    <= 1'b0;
            w_drop_reg     <= 1'b0;
            wdata_hold     <= 32'b0;
            wstrb_hold     <= 4'b0;
            w_finish_hold  <= 1'b0;

            r_id_reg       <= {ID_WIDTH{1'b0}};
            r_addr_reg     <= {ADDR_WIDTH{1'b0}};
            r_len_reg      <= 8'b0;
            r_incr_reg     <= 1'b0;
            r_count_reg    <= 8'b0;
            r_error_reg    <= 1'b0;
        end else begin
            case (state)
                // ---------------------------------------------------------
                // Accept either AW or AR. Write has priority on same cycle.
                // ---------------------------------------------------------
                S_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_arready <= 1'b1;
                    s_axi_wready  <= 1'b0;

                    if (s_axi_awvalid && s_axi_awready) begin
                        w_addr_reg    <= s_axi_awaddr;
                        w_len_reg     <= s_axi_awlen;
                        w_incr_reg    <= (s_axi_awburst == AXI_BURST_INCR);
                        w_count_reg   <= 8'd0;

                        w_error_reg   <= aw_request_invalid;
                        w_drop_reg    <= aw_request_invalid;

                        s_axi_bid     <= s_axi_awid;
                        s_axi_bresp   <= AXI_OKAY;
                        s_axi_bvalid  <= 1'b0;

                        s_axi_awready <= 1'b0;
                        s_axi_arready <= 1'b0;
                        s_axi_wready  <= 1'b1;
                        state         <= S_W_WAIT;
                    end else if (s_axi_arvalid && s_axi_arready) begin
                        r_id_reg      <= s_axi_arid;
                        r_addr_reg    <= s_axi_araddr;
                        r_len_reg     <= s_axi_arlen;
                        r_incr_reg    <= (s_axi_arburst == AXI_BURST_INCR);
                        r_count_reg   <= 8'd0;

                        r_error_reg   <= ar_request_invalid;

                        s_axi_rid     <= s_axi_arid;
                        s_axi_rvalid  <= 1'b0;
                        s_axi_rlast   <= 1'b0;

                        s_axi_awready <= 1'b0;
                        s_axi_arready <= 1'b0;

                        if (ar_request_invalid) begin
                            s_axi_rdata  <= 32'b0;
                            s_axi_rresp  <= AXI_SLVERR;
                            s_axi_rlast  <= (s_axi_arlen == 8'd0);
                            s_axi_rvalid <= 1'b1;
                            state        <= S_R_SEND;
                        end else begin
                            state <= S_R_ISSUE;
                        end
                    end
                end

                // ---------------------------------------------------------
                // Consume one W beat.
                // ---------------------------------------------------------
                S_W_WAIT: begin
                    s_axi_wready <= 1'b1;

                    if (s_axi_wvalid && s_axi_wready) begin
                        wdata_hold    <= s_axi_wdata;
                        wstrb_hold    <= s_axi_wstrb;
                        w_finish_hold <=
                            (w_count_reg == w_len_reg) || s_axi_wlast;

                        if (s_axi_wlast != (w_count_reg == w_len_reg))
                            w_error_reg <= 1'b1;

                        if (w_drop_reg) begin
                            // Consume the burst but do not touch SRAM.
                            if ((w_count_reg == w_len_reg) || s_axi_wlast) begin
                                s_axi_wready <= 1'b0;
                                s_axi_bresp  <= AXI_SLVERR;
                                s_axi_bvalid <= 1'b1;
                                state        <= S_W_RESP;
                            end else begin
                                w_count_reg <= w_count_reg + 8'd1;
                                if (w_incr_reg)
                                    w_addr_reg <= w_addr_reg +
                                        {{(ADDR_WIDTH-3){1'b0}}, 3'd4};
                            end
                        end else begin
                            s_axi_wready <= 1'b0;

                            if (s_axi_wstrb == 4'b1111)
                                state <= S_W_WRITE;
                            else
                                state <= S_W_RMW_READ;
                        end
                    end
                end

                // Issue the synchronous macro read for a partial write.  The
                // macro registers dataout on this state's clock edge, so
                // mem_rdata is already valid in S_W_WRITE and the separate wait
                // state this used to pass through was pure delay.  Removing it
                // takes a byte or halfword store from three extra macro cycles
                // to two, and does not lengthen any path: the
                // dataout -> merge -> din path was always inside S_W_WRITE.
                S_W_RMW_READ: begin
                    state <= S_W_WRITE;
                end

                // SRAM write is committed on this state's active clock edge.
                S_W_WRITE: begin
                    if (w_finish_hold) begin
                        s_axi_bresp  <= w_error_reg ? AXI_SLVERR : AXI_OKAY;
                        s_axi_bvalid <= 1'b1;
                        state        <= S_W_RESP;
                    end else begin
                        w_count_reg <= w_count_reg + 8'd1;
                        if (w_incr_reg)
                            w_addr_reg <= w_addr_reg +
                                {{(ADDR_WIDTH-3){1'b0}}, 3'd4};
                        s_axi_wready  <= 1'b1;
                        state         <= S_W_WAIT;
                    end
                end

                S_W_RESP: begin
                    s_axi_wready <= 1'b0;
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid  <= 1'b0;
                        s_axi_awready <= 1'b1;
                        s_axi_arready <= 1'b1;
                        state         <= S_IDLE;
                    end
                end

                // ---------------------------------------------------------
                // AXI read path.
                // ---------------------------------------------------------
                S_R_ISSUE: begin
                    state <= S_R_WAIT;
                end

                S_R_WAIT: begin
                    s_axi_rid    <= r_id_reg;
                    s_axi_rdata  <= mem_rdata;
                    s_axi_rresp  <= AXI_OKAY;
                    s_axi_rlast  <= (r_count_reg == r_len_reg);
                    s_axi_rvalid <= 1'b1;
                    state        <= S_R_SEND;
                end

                S_R_SEND: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        if (s_axi_rlast) begin
                            s_axi_rvalid  <= 1'b0;
                            s_axi_rlast   <= 1'b0;
                            s_axi_awready <= 1'b1;
                            s_axi_arready <= 1'b1;
                            state         <= S_IDLE;
                        end else begin
                            r_count_reg <= r_count_reg + 8'd1;

                            if (r_error_reg) begin
                                // Keep streaming SLVERR beats without SRAM access.
                                // The address is intentionally not updated because
                                // no memory access will be issued for an invalid burst.
                                s_axi_rdata  <= 32'b0;
                                s_axi_rresp  <= AXI_SLVERR;
                                s_axi_rlast  <= ((r_count_reg + 8'd1) == r_len_reg);
                                s_axi_rvalid <= 1'b1;
                                state        <= S_R_SEND;
                            end else begin
                                if (r_incr_reg)
                                    r_addr_reg <= r_addr_reg +
                                        {{(ADDR_WIDTH-3){1'b0}}, 3'd4};
                                s_axi_rvalid <= 1'b0;
                                s_axi_rlast  <= 1'b0;
                                state        <= S_R_ISSUE;
                            end
                        end
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // Unused AXI attributes are intentionally accepted but ignored.
    wire _unused_ok = &{
        1'b0,
        s_axi_awlock,
        s_axi_awcache,
        s_axi_awprot,
        s_axi_awqos,
        s_axi_awregion,
        s_axi_arlock,
        s_axi_arcache,
        s_axi_arprot,
        s_axi_arqos,
        s_axi_arregion,
        MEM_DEPTH[0]
    };

endmodule

