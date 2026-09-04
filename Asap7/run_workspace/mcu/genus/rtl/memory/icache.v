`timescale 1ns / 1ps

// =============================================================================
// MAIN MODULE: Instruction Cache
// =============================================================================
//
// 16 KiB, 2-way set associative, 16-byte blocks (512 sets).
//
// Storage is held in ASAP7 srambank_256x4x32_6t122 hard macros through
// cache_data_array / cache_tag_array:
//   data : 2 ways x 2 macros, addressed by {index[8:0], word_idx[1:0]}
//   tag  : 2 ways x 1 macro,  addressed by index[8:0]
// Valid bits and the round-robin victim pointer stay in flip-flops because the
// macros have no reset.
//
// The macros read synchronously, so a cached access takes two cycles: the
// address phase (IDLE) issues the array read and the compare phase (LOOKUP)
// resolves hit/miss.  A hit therefore stalls the fetch stage for one cycle;
// removing that cycle would require the core to present the next PC one cycle
// early, which is outside this module.
//
// Refill writes each AXI read beat straight into the data array, so no
// block-wide fetch buffer is needed.  The tag is written in DONE together with
// the valid bit, keeping tag and valid consistent for the next lookup.
// =============================================================================
module instruction_cache #(
    parameter C_CACHE_SIZE       = 16384,
    parameter C_BLOCK_SIZE       = 16,
    parameter C_WAYS             = 2,
    parameter C_M_AXI_ID_W       = 5,
    parameter C_M_AXI_ADDR_W     = 32,
    parameter C_M_AXI_DATA_W     = 32
)(
    input  wire                          clk,
    input  wire                          rst_n,

    input  wire                          cpu_read_req,
    input  wire [C_M_AXI_ADDR_W-1:0]     cpu_addr,
    // Ban TO HOP tu dia chi song cua CPU. KHONG dung truc tiep trong FSM - xem
    // ghi chu ve chot uncache ben duoi; ten `uncache_en` la ban DA CHOT.
    input  wire                          uncache_en_i,
    output reg  [C_M_AXI_DATA_W-1:0]     cpu_read_data,
    output reg                           icache_hit,
    output reg                           icache_stall,

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
    output wire                          m_axi_awvalid,
    input  wire                          m_axi_awready,
    output wire [C_M_AXI_DATA_W-1:0]     m_axi_wdata,
    output wire [(C_M_AXI_DATA_W/8)-1:0] m_axi_wstrb,
    output wire                          m_axi_wlast,
    output wire                          m_axi_wvalid,
    input  wire                          m_axi_wready,
    input  wire [C_M_AXI_ID_W-1:0]       m_axi_bid,
    input  wire [1:0]                    m_axi_bresp,
    input  wire                          m_axi_bvalid,
    output wire                          m_axi_bready,
    output wire [C_M_AXI_ID_W-1:0]       m_axi_arid,
    output reg  [C_M_AXI_ADDR_W-1:0]     m_axi_araddr,
    output reg  [7:0]                    m_axi_arlen,
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

    // =========================================================================
    // uncache_en PHAI duoc chot cung luc voi miss_addr.
    //
    // `uncache_en_i` la to hop tu PC SONG cua CPU (xem macro `SOC_IS_UNCACHED
    // trong top_soc.v). ARADDR da duoc chot vao miss_addr, nhung truoc day
    // ARLEN va ARCACHE van lay tu tin hieu song:
    //
    //     m_axi_arlen = uncache_en ? 8'd0 : BURST_LEN;
    //
    // Khi mot nhanh doan sai / trap doi PC tu vung CACHEABLE sang vung UNCACHED
    // trong luc ARVALID dang cho ARREADY, ARLEN nhay 3 -> 0 GIUA HANDSHAKE.
    // AXI4 yeu cau moi tin hieu cua kenh dia chi phai ON DINH tu khi VALID len
    // cho toi khi READY len. Vi pham nay lam slave va interconnect bat dong y ve
    // so beat cua burst -> ROB treo slot, bus chet.
    //
    // Rang buoc do CO THAT: chinh FSM ben duoi da xu ly ca "PC doi giua mot lan
    // miss" (`if (cpu_addr == miss_addr)` o trang thai DONE).
    //
    // Sua bang cach chot uncache cung nhip voi miss_addr, roi dat lai ten
    // `uncache_en` cho ban DA CHOT - nho vay moi cho dung ben duoi tu dong lay
    // ban dung ma khong sot cho nao.
    // =========================================================================
    localparam IDLE   = 3'd0,
               LOOKUP = 3'd1,
               AR_REQ = 3'd2,
               R_WAIT = 3'd3,
               DONE   = 3'd4;

    reg [2:0] state, next_state;
    reg       uncache_r;

    wire uncache_en = (state == IDLE) ? uncache_en_i : uncache_r;

    assign m_axi_awid = 0; assign m_axi_awaddr = 0; assign m_axi_awlen = 0;
    assign m_axi_awsize = 0; assign m_axi_awburst = 0; assign m_axi_awlock = 0;
    assign m_axi_awcache = 0; assign m_axi_awprot = 0; assign m_axi_awqos = 0;
    assign m_axi_awregion = 0; assign m_axi_awvalid = 0;
    assign m_axi_wdata = 0; assign m_axi_wstrb = 0; assign m_axi_wlast = 0;
    assign m_axi_wvalid = 0; assign m_axi_bready = 1'b1;

    assign m_axi_arid = 0; assign m_axi_arsize = $clog2(C_M_AXI_DATA_W/8);
    assign m_axi_arburst = 2'b01; assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = uncache_en ? 4'b0000 : 4'b0011;
    assign m_axi_arprot = 3'b100; assign m_axi_arqos = 4'b0000; assign m_axi_arregion = 4'b0000;


    reg [C_M_AXI_ADDR_W-1:0]   miss_addr;
    reg [C_M_AXI_DATA_W-1:0]   refill_word;
    reg [WORD_IDX_W-1:0]       beat_cnt;

    // Valid bits and the victim pointer must survive reset, so they stay in
    // flip-flops instead of the reset-less SRAM macros.
    reg [C_WAYS-1:0]           valid_arr [0:NUM_SETS-1];
    reg [WAY_IDX_W-1:0]        rr_ptr    [0:NUM_SETS-1];

    wire [C_M_AXI_ADDR_W-1:0] current_addr = (state == IDLE) ? cpu_addr : miss_addr;
    wire [TAG_W-1:0]          tag      = current_addr[C_M_AXI_ADDR_W-1 : C_M_AXI_ADDR_W-TAG_W];
    wire [INDEX_W-1:0]        index    = current_addr[OFFSET_W+INDEX_W-1 : OFFSET_W];
    wire [OFFSET_W-1:0]       offset   = current_addr[OFFSET_W-1 : 0];
    wire [WORD_IDX_W-1:0]     word_idx = offset[OFFSET_W-1 : $clog2(C_M_AXI_DATA_W/8)];

    wire [WAY_IDX_W-1:0]      victim_way = rr_ptr[index];

    // Array control
    reg  [C_WAYS-1:0]         way_update;
    wire                      array_read  = (state == IDLE) && cpu_read_req && !uncache_en;
    wire                      refill_beat = (state == R_WAIT) && !uncache_en &&
                                            m_axi_rvalid && m_axi_rready;

    reg  [C_WAYS-1:0]         data_write_en;
    wire [DATA_ADDR_W-1:0]    data_addr = (state == R_WAIT) ? {index, beat_cnt}
                                                            : {index, word_idx};

    wire [(C_WAYS*C_M_AXI_DATA_W)-1:0] data_out_bus;
    wire [(C_WAYS*TAG_W)-1:0]          tag_out_bus;

    always @(*) begin
        data_write_en = {C_WAYS{1'b0}};
        if (refill_beat) data_write_en[victim_way] = 1'b1;
    end

    cache_data_array #(
        .WAYS   (C_WAYS),
        .ADDR_W (DATA_ADDR_W)
    ) DATA_RAM (
        .clk        (clk),
        .addr       (data_addr),
        .read       (array_read),
        .write_en   (data_write_en),
        .write_data (m_axi_rdata),
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
            miss_addr   <= 0;
            refill_word <= 0;
            beat_cnt    <= 0;
            uncache_r   <= 1'b0;
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                valid_arr[i] <= 0;
                rr_ptr[i]    <= 0;
            end
        end else begin
            state <= next_state;

            // Chot dia chi VA thuoc tinh cacheability cua no trong CUNG mot nhip.
            if (state == IDLE && cpu_read_req) begin
                miss_addr <= cpu_addr;
                uncache_r <= uncache_en_i;
            end

            if (state == AR_REQ) beat_cnt <= 0;

            if (state == R_WAIT && m_axi_rvalid && m_axi_rready) begin
                beat_cnt <= beat_cnt + 1'b1;
                if (uncache_en || beat_cnt == word_idx) refill_word <= m_axi_rdata;
            end

            if (state == DONE && !uncache_en) begin
                for (w = 0; w < C_WAYS; w = w + 1)
                    if (way_update[w]) valid_arr[index][w] <= 1'b1;
                rr_ptr[index] <= rr_ptr[index] + 1'b1;
            end
        end
    end

    reg hit_flag;
    reg [C_M_AXI_DATA_W-1:0] read_word;

    // Hit resolution uses the array outputs captured for miss_addr, so it is
    // only meaningful in LOOKUP.
    always @(*) begin
        hit_flag  = 1'b0;
        read_word = {C_M_AXI_DATA_W{1'b0}};
        for (w = 0; w < C_WAYS; w = w + 1) begin
            if (valid_arr[index][w] && tag_out_bus[w*TAG_W +: TAG_W] == tag) begin
                hit_flag  = 1'b1;
                read_word = data_out_bus[w*C_M_AXI_DATA_W +: C_M_AXI_DATA_W];
            end
        end
    end

    always @(*) begin
        next_state    = state;
        icache_hit    = 1'b0;
        icache_stall  = 1'b0;
        cpu_read_data = {C_M_AXI_DATA_W{1'b0}};
        way_update    = {C_WAYS{1'b0}};
        m_axi_arvalid = 1'b0;
        m_axi_rready  = 1'b0;

        if (uncache_en) begin
            m_axi_arlen  = 8'd0;
            m_axi_araddr = current_addr;
        end else begin
            m_axi_arlen  = BURST_LEN;
            m_axi_araddr = {tag, index, {OFFSET_W{1'b0}}};
        end

        case (state)
            IDLE: begin
                // Address phase: the SRAM read is issued here and resolved in
                // LOOKUP, so even a hit costs one stall cycle.
                if (cpu_read_req) begin
                    icache_stall = 1'b1;
                    next_state   = uncache_en ? AR_REQ : LOOKUP;
                end
            end
            LOOKUP: begin
                next_state = IDLE;
                if (cpu_read_req && cpu_addr == miss_addr) begin
                    if (hit_flag) begin
                        icache_hit    = 1'b1;
                        cpu_read_data = read_word;
                    end else begin
                        icache_stall = 1'b1;
                        next_state   = AR_REQ;
                    end
                end else begin
                    // Lệnh fetch đã bị flush trong lúc đọc mảng SRAM
                    icache_stall = 1'b1;
                end
            end
            AR_REQ: begin
                icache_stall = 1'b1; m_axi_arvalid = 1'b1;
                if (m_axi_arready) next_state = R_WAIT;
            end
            R_WAIT: begin
                icache_stall = 1'b1; m_axi_rready = 1'b1;
                if (m_axi_rvalid && m_axi_rlast) next_state = DONE;
            end
            DONE: begin
                // Kiểm tra xem CPU có vừa bị flush nhảy PC đi nơi khác không
                if (cpu_addr == miss_addr) begin
                    icache_stall  = 1'b0;
                    icache_hit    = 1'b1;
                    cpu_read_data = refill_word;
                end else begin
                    // Nếu PC đã thay đổi, HỦY việc trả lệnh này cho CPU
                    icache_stall  = 1'b1;
                    icache_hit    = 1'b0;
                    cpu_read_data = {C_M_AXI_DATA_W{1'b0}};
                end

                // Tag và valid được ghi cùng lúc để lookup kế tiếp luôn nhất quán
                if (!uncache_en) way_update[victim_way] = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    wire _unused_ok = &{1'b0, m_axi_awready, m_axi_wready, m_axi_bid,
                        m_axi_bresp, m_axi_bvalid, m_axi_rid, m_axi_rresp};

endmodule
