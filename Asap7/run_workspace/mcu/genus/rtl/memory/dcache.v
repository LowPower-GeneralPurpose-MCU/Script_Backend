`timescale 1ns / 1ps

// =============================================================================
// MAIN MODULE: Data Cache
// =============================================================================
//
// 32 KiB, 4-way set associative, 16-byte blocks (512 sets), write-through with
// no write allocate.
//
// Storage is held in ASAP7 srambank_256x4x32_6t122 hard macros through
// cache_data_array / cache_tag_array:
//   data : 4 ways x 2 macros, addressed by {index[8:0], word_idx[1:0]}
//   tag  : 4 ways x 1 macro,  addressed by index[8:0]
// Valid bits and the round-robin victim pointer stay in flip-flops because the
// macros have no reset.
//
// The macros read synchronously, so a cached access takes an extra cycle: IDLE
// issues the array read and LOOKUP resolves hit/miss.  A write hit merges the
// stored word with the CPU byte lanes inside LOOKUP and writes the full 32-bit
// word back, because the macro has no byte-write mask.
// =============================================================================
module data_cache #(
    parameter C_CACHE_SIZE       = 32768,
    parameter C_BLOCK_SIZE       = 16,
    parameter C_WAYS             = 4,
    parameter C_M_AXI_ID_W       = 5,
    parameter C_M_AXI_ADDR_W     = 32,
    parameter C_M_AXI_DATA_W     = 32
)(
    input  wire                          clk,
    input  wire                          rst_n,

    input  wire                          cpu_read_req,
    input  wire                          cpu_write_req,
    input  wire [C_M_AXI_ADDR_W-1:0]     cpu_addr,
    input  wire [C_M_AXI_DATA_W-1:0]     cpu_write_data,
    input  wire                          mem_unsigned,
    input  wire [1:0]                    mem_size,
    input  wire                          uncache_en,
    output reg  [C_M_AXI_DATA_W-1:0]     cpu_read_data,
    output reg                           dcache_hit,
    output reg                           dcache_stall,

    output wire [C_M_AXI_ID_W-1:0]       m_axi_awid,
    output wire [C_M_AXI_ADDR_W-1:0]     m_axi_awaddr,
    output wire [7:0]                    m_axi_awlen,
    output wire [2:0]                    m_axi_awsize,
    output wire [1:0]                    m_axi_awburst,
    output wire                          m_axi_awlock,
    output wire [3:0]                    m_axi_awcache,
    output wire [2:0]                    m_axi_awprot,
    output wire [3:0]                    m_axi_awqos,
    output wire [3:0]                    m_axi_awregion,
    output reg                           m_axi_awvalid,
    input  wire                          m_axi_awready,
    output wire [C_M_AXI_DATA_W-1:0]     m_axi_wdata,
    output wire [(C_M_AXI_DATA_W/8)-1:0] m_axi_wstrb,
    output wire                          m_axi_wlast,
    output reg                           m_axi_wvalid,
    input  wire                          m_axi_wready,
    input  wire [C_M_AXI_ID_W-1:0]       m_axi_bid,
    input  wire [1:0]                    m_axi_bresp,
    input  wire                          m_axi_bvalid,
    output reg                           m_axi_bready,
    output wire [C_M_AXI_ID_W-1:0]       m_axi_arid,
    output wire [C_M_AXI_ADDR_W-1:0]     m_axi_araddr,
    output wire [7:0]                    m_axi_arlen,
    output wire [2:0]                    m_axi_arsize,
    output wire [1:0]                    m_axi_arburst,
    output wire                          m_axi_arlock,
    output wire [3:0]                    m_axi_arcache,
    output wire [2:0]                    m_axi_arprot,
    output wire [3:0]                    m_axi_arqos,
    output wire [3:0]                    m_axi_arregion,
    output reg                           m_axi_arvalid,
    input  wire                          m_axi_arready,
    input  wire [C_M_AXI_ID_W-1:0]       m_axi_rid,
    input  wire [C_M_AXI_DATA_W-1:0]     m_axi_rdata,
    input  wire [1:0]                    m_axi_rresp,
    input  wire                          m_axi_rlast,
    input  wire                          m_axi_rvalid,
    output reg                           m_axi_rready
);

    localparam BLOCK_W       = C_BLOCK_SIZE * 8;
    localparam OFFSET_W      = $clog2(C_BLOCK_SIZE);
    localparam NUM_SETS      = C_CACHE_SIZE / (C_BLOCK_SIZE * C_WAYS);
    localparam INDEX_W       = $clog2(NUM_SETS);
    localparam TAG_W         = C_M_AXI_ADDR_W - INDEX_W - OFFSET_W;
    localparam WORDS_PER_BLK = BLOCK_W / C_M_AXI_DATA_W;
    localparam WORD_IDX_W    = $clog2(WORDS_PER_BLK);
    localparam DATA_ADDR_W   = INDEX_W + WORD_IDX_W;
    localparam BURST_LEN     = WORDS_PER_BLK - 1;
    localparam WAY_IDX_W     = $clog2(C_WAYS);

    function automatic [31:0] read_data_with_size;
        input [31:0] data; input [1:0] size; input [1:0] offset; input unsigned_flag;
        reg [31:0] res;
        begin
            case (size)
                2'b10: res = data;
                2'b01: res = (offset[1] == 0) ? (unsigned_flag ? {16'b0, data[15:0]} : {{16{data[15]}}, data[15:0]}) : (unsigned_flag ? {16'b0, data[31:16]} : {{16{data[31]}}, data[31:16]});
                2'b00: begin
                    case (offset)
                        2'b00: res = unsigned_flag ? {24'b0, data[7:0]}   : {{24{data[7]}}, data[7:0]};
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

    function automatic [31:0] write_data_with_size;
        input [31:0] orig_data; input [31:0] w_data; input [1:0] size; input [1:0] offset;
        reg [31:0] res;
        begin
            res = orig_data;
            case (size)
                2'b10: res = w_data;
                2'b01: if (offset[1] == 0) res[15:0] = w_data[15:0]; else res[31:16] = w_data[15:0];
                2'b00: case (offset)
                        2'b00: res[7:0]   = w_data[7:0];
                        2'b01: res[15:8]  = w_data[7:0];
                        2'b10: res[23:16] = w_data[7:0];
                        2'b11: res[31:24] = w_data[7:0];
                    endcase
            endcase
            write_data_with_size = res;
        end
    endfunction

    function automatic [3:0] gen_wstrb;
        input [1:0] size; input [1:0] offset;
        reg [3:0] strb;
        begin
            case (size)
                2'b10: strb = 4'b1111;
                2'b01: strb = (offset[1] == 0) ? 4'b0011 : 4'b1100;
                2'b00: strb = (4'b0001 << offset);
                default: strb = 4'b1111;
            endcase
            gen_wstrb = strb;
        end
    endfunction

    assign m_axi_awid = 0; assign m_axi_awsize = mem_size; assign m_axi_awburst = 2'b01;
    assign m_axi_awlock = 0; assign m_axi_awcache = uncache_en ? 4'b0000 : 4'b0011;
    assign m_axi_awprot = 3'b000; assign m_axi_awqos = 0; assign m_axi_awregion = 0; assign m_axi_awlen = 0;
    assign m_axi_arid = 0; assign m_axi_arsize = $clog2(C_M_AXI_DATA_W/8); assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 0; assign m_axi_arcache = uncache_en ? 4'b0000 : 4'b0011;
    assign m_axi_arprot = 3'b000; assign m_axi_arqos = 0; assign m_axi_arregion = 0;

    localparam IDLE   = 3'd0,
               LOOKUP = 3'd1,
               AR_REQ = 3'd2,
               R_WAIT = 3'd3,
               AW_REQ = 3'd4,
               W_REQ  = 3'd5,
               B_WAIT = 3'd6,
               DONE   = 3'd7;

    reg [2:0]                state, next_state;
    reg [C_M_AXI_ADDR_W-1:0] req_addr;
    reg [C_M_AXI_DATA_W-1:0] refill_word;
    reg [WORD_IDX_W-1:0]     beat_cnt;

    // Valid bits and the victim pointer must survive reset, so they stay in
    // flip-flops instead of the reset-less SRAM macros.
    reg [C_WAYS-1:0]         valid_arr [0:NUM_SETS-1];
    reg [WAY_IDX_W-1:0]      rr_ptr    [0:NUM_SETS-1];

    wire [C_M_AXI_ADDR_W-1:0] current_addr = (state == IDLE) ? cpu_addr : req_addr;
    wire [TAG_W-1:0]          tag         = current_addr[C_M_AXI_ADDR_W-1 : C_M_AXI_ADDR_W-TAG_W];
    wire [INDEX_W-1:0]        index       = current_addr[OFFSET_W+INDEX_W-1 : OFFSET_W];
    wire [OFFSET_W-1:0]       offset      = current_addr[OFFSET_W-1 : 0];
    wire [1:0]                byte_offset = offset[1:0];
    wire [WORD_IDX_W-1:0]     word_idx    = offset[OFFSET_W-1 : 2];

    wire [WAY_IDX_W-1:0]      victim_way  = rr_ptr[index];

    // Keep the AXI payload/address datapath outside the cache control
    // combinational process.  This removes a false combinational loop between
    // CPU read data and AMO write data at the SoC boundary.
    assign m_axi_awaddr = current_addr;
    assign m_axi_wdata  = cpu_write_data;
    assign m_axi_wstrb  = gen_wstrb(mem_size, byte_offset);
    assign m_axi_wlast  = 1'b1;
    assign m_axi_arlen  = uncache_en ? 8'd0 : BURST_LEN;
    assign m_axi_araddr = uncache_en
        ? current_addr
        : {tag, index, {OFFSET_W{1'b0}}};

    // Array control
    reg  [C_WAYS-1:0]      way_update;      // tag write (read-miss refill)
    reg  [C_WAYS-1:0]      data_write_en;
    reg  [31:0]            data_write_word;

    wire                   array_read  = (state == IDLE) &&
                                         (cpu_read_req || cpu_write_req) && !uncache_en;
    wire                   refill_beat = (state == R_WAIT) && !uncache_en &&
                                         m_axi_rvalid && m_axi_rready;

    wire [DATA_ADDR_W-1:0] data_addr   = (state == R_WAIT) ? {index, beat_cnt}
                                                           : {index, word_idx};

    wire [(C_WAYS*C_M_AXI_DATA_W)-1:0] data_out_bus;
    wire [(C_WAYS*TAG_W)-1:0]          tag_out_bus;

    cache_data_array #(
        .WAYS   (C_WAYS),
        .ADDR_W (DATA_ADDR_W)
    ) DATA_RAM (
        .clk        (clk),
        .addr       (data_addr),
        .read       (array_read),
        .write_en   (data_write_en),
        .write_data (data_write_word),
        .read_data  (data_out_bus)
    );

    cache_tag_array #(
        .WAYS   (C_WAYS),
        .ADDR_W (INDEX_W),
        .TAG_W  (TAG_W)
    ) TAG_RAM (
        .clk       (clk),
        .addr      (index),
        .read      (array_read),
        .write_en  (way_update),
        .write_tag (tag),
        .read_tag  (tag_out_bus)
    );

    integer i, w;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            req_addr    <= 0;
            refill_word <= 0;
            beat_cnt    <= 0;
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                valid_arr[i] <= 0;
                rr_ptr[i]    <= 0;
            end
        end else begin
            state <= next_state;

            if (state == IDLE && (cpu_read_req || cpu_write_req)) req_addr <= cpu_addr;

            if (state == AR_REQ) beat_cnt <= 0;

            if (state == R_WAIT && m_axi_rvalid && m_axi_rready) begin
                beat_cnt <= beat_cnt + 1'b1;
                if (uncache_en || beat_cnt == word_idx) refill_word <= m_axi_rdata;
            end

            if (state == DONE && !uncache_en && cpu_read_req) begin
                for (w = 0; w < C_WAYS; w = w + 1)
                    if (way_update[w]) valid_arr[index][w] <= 1'b1;
                rr_ptr[index] <= rr_ptr[index] + 1'b1;
            end
        end
    end

    reg                      hit_flag;
    reg [WAY_IDX_W-1:0]      hit_way;
    reg [C_M_AXI_DATA_W-1:0] read_word;

    // Isolate lookup/read-data logic from the write datapath.  Keeping both
    // in one combinational process made the AMO path appear as a real loop:
    // dcache_read_data -> AMO result -> cpu_write_data -> dcache_read_data.
    //
    // The array outputs belong to req_addr, so this is only meaningful in LOOKUP.
    always @(*) begin
        hit_flag  = 1'b0;
        hit_way   = {WAY_IDX_W{1'b0}};
        read_word = {C_M_AXI_DATA_W{1'b0}};
        for (w = 0; w < C_WAYS; w = w + 1) begin
            if (valid_arr[index][w] && tag_out_bus[w*TAG_W +: TAG_W] == tag) begin
                hit_flag  = 1'b1;
                hit_way   = w[WAY_IDX_W-1:0];
                read_word = data_out_bus[w*C_M_AXI_DATA_W +: C_M_AXI_DATA_W];
            end
        end
    end

    always @(*) begin
        cpu_read_data = {C_M_AXI_DATA_W{1'b0}};
        if (state == LOOKUP && cpu_read_req && !uncache_en &&
            cpu_addr == req_addr && hit_flag) begin
            cpu_read_data = read_data_with_size(
                read_word, mem_size, byte_offset, mem_unsigned);
        end else if (state == DONE && cpu_addr == req_addr && cpu_read_req) begin
            cpu_read_data = read_data_with_size(
                refill_word, mem_size, byte_offset, mem_unsigned);
        end
    end

    // Data-array write sources: a store that hits (LOOKUP) or a refill beat.
    // The store write is gated by cpu_addr == req_addr for the same reason the
    // AXI write is: a flushed store must update neither the array nor memory.
    always @(*) begin
        data_write_en   = {C_WAYS{1'b0}};
        data_write_word = m_axi_rdata;

        if (refill_beat) begin
            data_write_en[victim_way] = 1'b1;
        end else if (state == LOOKUP && cpu_write_req && !uncache_en &&
                     cpu_addr == req_addr && hit_flag) begin
            // The macro has no byte mask, so merge and rewrite the whole word.
            data_write_word = write_data_with_size(
                read_word, cpu_write_data, mem_size, byte_offset);
            data_write_en[hit_way] = 1'b1;
        end
    end

    always @(*) begin
        next_state    = state; dcache_hit    = 1'b0; dcache_stall  = 1'b0;
        way_update    = {C_WAYS{1'b0}};

        m_axi_awvalid = 0; m_axi_wvalid = 0; m_axi_bready = 0; m_axi_arvalid = 0; m_axi_rready = 0;
        case (state)
            IDLE: begin
                // Address phase: the SRAM read is issued here and resolved in
                // LOOKUP, so even a hit costs one stall cycle.
                if (cpu_read_req || cpu_write_req) begin
                    dcache_stall = 1'b1;
                    if (uncache_en) next_state = cpu_read_req ? AR_REQ : AW_REQ;
                    else            next_state = LOOKUP;
                end
            end
            LOOKUP: begin
                dcache_stall = 1'b1;
                if (cpu_read_req && cpu_addr == req_addr) begin
                    if (hit_flag) begin
                        dcache_stall = 1'b0;
                        dcache_hit   = 1'b1;
                        next_state   = IDLE;
                    end else begin
                        next_state = AR_REQ;
                    end
                end else if (cpu_write_req && cpu_addr == req_addr) begin
                    // Write-through: the store always goes to AXI.  On a hit the
                    // merged word was written into the array by data_write_en.
                    next_state = AW_REQ;
                end else begin
                    // Lệnh đã bị flush trong lúc đọc mảng SRAM
                    next_state = IDLE;
                end
            end
            AR_REQ: begin
                dcache_stall = 1'b1; m_axi_arvalid = 1'b1;
                if (m_axi_arready) next_state = R_WAIT;
            end
            R_WAIT: begin
                dcache_stall = 1'b1; m_axi_rready = 1'b1;
                if (m_axi_rvalid) begin
                    if (uncache_en) next_state = DONE;
                    else if (m_axi_rlast) next_state = DONE;
                end
            end
            AW_REQ: begin
                dcache_stall = 1'b1; m_axi_awvalid = 1'b1;
                if (m_axi_awready) next_state = W_REQ;
            end
            W_REQ: begin
                dcache_stall = 1'b1; m_axi_wvalid = 1'b1;
                if (m_axi_wready) next_state = B_WAIT;
            end
            B_WAIT: begin
                dcache_stall = 1'b1; m_axi_bready = 1'b1;
                if (m_axi_bvalid) next_state = DONE;
            end
            DONE: begin
                // 1. LUÔN CẬP NHẬT TAG/VALID NẾU LÀ READ MISS (Không Uncache).
                // Kể cả khi CPU đã Flush đổi địa chỉ, ta vẫn giữ block vừa fetch.
                // Dữ liệu đã được ghi từng beat trong R_WAIT.
                if (cpu_read_req && !uncache_en) begin
                    way_update[victim_way] = 1'b1;
                end

                // 2. RÀNG BUỘC TÍN HIỆU TRẢ VỀ CPU BẰNG ĐỊA CHỈ
                if (cpu_addr == req_addr) begin
                    // Nhả stall và báo Hit vì lệnh vẫn còn nguyên (không bị Flush)
                    dcache_stall = 1'b0;
                    dcache_hit   = 1'b1;
                end else begin
                    // Lệnh đã bị Flush sang địa chỉ khác. Giữ stall để FSM quay về IDLE.
                    dcache_stall  = 1'b1;
                    dcache_hit    = 1'b0;
                end

                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    wire _unused_ok = &{1'b0, m_axi_bid, m_axi_bresp, m_axi_rid, m_axi_rresp};

endmodule
