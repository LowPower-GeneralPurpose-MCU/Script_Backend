`timescale 1ns / 1ps

// =============================================================================
// MAIN MODULE: Data Cache
// =============================================================================
//
// 16 KiB, 2-way set associative, 16-byte blocks (512 sets), write-through with
// no write allocate, and a store buffer in front of the AXI write channel.
//
// Storage is held in ASAP7 srambank_256x4x32_6t122 hard macros through
// cache_data_array / cache_tag_array:
//   data : 2 ways x 2 macros, addressed by {index[8:0], word_idx[1:0]}
//   tag  : 2 ways x 1 macro,  addressed by index[8:0]
//
// Associativity is 2, not 4.  The macro is 1024 x 32 and holds one way, so a
// 4-way cache needs four tag macros of which each stores 256 x 20 bits - 16 KiB
// of silicon for 640 bytes of tag.  Halving the ways doubles the sets, so the
// tags fit in two macros instead of four (8 -> 6 macros, 32 -> 24 KiB) while the
// data macros are unchanged.  The cost is the conflict-miss difference between
// 2-way and 4-way at 16 KiB, roughly 1-3 % on embedded workloads.
// Valid bits and the round-robin victim pointer stay in flip-flops because the
// macros have no reset.
//
// The macros read synchronously, so a cached access takes an extra cycle: IDLE
// issues the array read and LOOKUP resolves hit/miss.  A write hit merges the
// stored word with the CPU byte lanes inside LOOKUP and writes the full 32-bit
// word back, because the macro has no byte-write mask.
// =============================================================================
module data_cache #(
    parameter C_CACHE_SIZE       = 16384,
    parameter C_BLOCK_SIZE       = 16,
    parameter C_WAYS             = 2,
    // Store-buffer depth.  Must be a power of two and >= 2.
    parameter STORE_BUF_DEPTH    = 4,
    parameter C_M_AXI_ID_W       = 5,
    parameter C_M_AXI_ADDR_W     = 32,
    parameter C_M_AXI_DATA_W     = 32
)(
    input  wire                          clk,
    input  wire                          rst_n,

    input  wire                          cpu_read_req,
    input  wire                          cpu_write_req,
    // -------------------------------------------------------------------------
    // P2c - `fence` (opcode 0001111, funct3 000) tu tang MEM cua core.
    //
    // Khong mang dia chi, khong mang du lieu, khong bao gio bat cung luc voi
    // cpu_read_req / cpu_write_req: mot lenh o MEM chi la mot trong ba thu.
    // Tac dung duy nhat: giu `dcache_stall` cao cho toi khi `sb_drained`, tuc
    // toi khi BRESP cua entry cuoi cung trong store buffer da ve.
    //
    // Vi sao can: quy tac 2 cua store buffer chi ep xa khi CHINH CORE dung toi
    // bus.  Mot master khac - debugger qua System Bus Access - vao thang AXI ma
    // khong qua CPU, nen khong co gi ep xa cho no.  Truoc P2c, testbench phai
    // gia lam fence bang mot lenh doc uncached bat ky (xem T9 cu).
    // -------------------------------------------------------------------------
    input  wire                          cpu_fence,
    input  wire [C_M_AXI_ADDR_W-1:0]     cpu_addr,
    input  wire [C_M_AXI_DATA_W-1:0]     cpu_write_data,
    input  wire                          mem_unsigned,
    input  wire [1:0]                    mem_size,
    // Ban TO HOP tu dia chi song cua CPU. KHONG dung truc tiep trong FSM - xem
    // ghi chu ve chot uncache ben duoi; ten `uncache_en` la ban DA CHOT.
    input  wire                          uncache_en_i,

    // -------------------------------------------------------------------------
    // R1b - bat tay hai chu ky cho lenh nguyen tu doc-sua-ghi.
    //
    // `cpu_amo_req` len khi lenh o tang MEM la mot AMO that (khong phai LR/SC).
    // Cache giu no them DUNG mot chu ky trong LOOKUP: chu ky dau tra gia tri cu
    // va bao `dcache_amo_capture`, chu ky sau moi nhan ket qua ALU de day vao
    // store buffer. Nho vay chuoi
    //   state -> so tag -> mux way -> AMO ALU o u_core/MEM -> nguoc ve day
    // bi cat lam doi, moi nua bat dau hoac ket thuc o mot thanh ghi.
    // -------------------------------------------------------------------------
    input  wire                          cpu_amo_req,
    output wire                          dcache_amo_capture,

    output reg  [C_M_AXI_DATA_W-1:0]     cpu_read_data,
    output reg                           dcache_hit,
    output reg                           dcache_stall,

    // -------------------------------------------------------------------------
    // B2 - LOI BUS (mcause 5 / 7).
    //
    // Truoc day module nay CHU DONG vut bo m_axi_rresp / m_axi_bresp bang dong
    //     wire _unused_ok = &{1'b0, m_axi_bid, m_axi_bresp, ... m_axi_rresp};
    // Interconnect tra DECERR cho dia chi khong map, axi_ram tra SLVERR cho dia
    // chi lech word, APB default slave tra pslverr -> tat ca bay hoi. Toan bo ha
    // tang phat hien loi o phia bus da co, chi thieu day noi toi CPU.
    //
    // Xung dung MOT chu ky, dung chu ky dcache_stall ha, nen lenh gay loi VAN
    // con o tang MEM -> mepc/mtval tu dung.
    // -------------------------------------------------------------------------
    output wire                          dcache_error,

    // -------------------------------------------------------------------------
    // Bus error on a BUFFERED store - IMPRECISE by construction.
    //
    // A cacheable store retires as soon as it enters the store buffer, so the
    // BRESP that carries the error arrives long after the instruction left the
    // MEM stage: mepc/mtval can no longer point at it.  Reporting it through
    // `dcache_error` would therefore trap the WRONG instruction, which is worse
    // than not trapping at all.
    //
    // It is instead raised as a level on a spare PLIC line (see top_soc.v), the
    // way most MCUs route an imprecise bus fault.  The pulse is stretched so the
    // much slower clk_apb PLIC gateway cannot miss it.
    //
    // Stores that keep a PRECISE fault: every uncached store (MMIO, CLINT, the
    // DMA pool) still goes down the blocking AW/W/B path below and still reports
    // through `dcache_error`.  Only stores to normal cacheable memory become
    // imprecise.
    // -------------------------------------------------------------------------
    output wire                          dcache_sb_error,

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

    // Bus la 32 bit va moi slave phia sau (axi_ram, cau AXI-to-APB, CLINT) deu
    // decode theo WORD.  Tren AXI, mot store duoi 32 bit duoc dien dat bang
    // WSTRB - byte nam o LANE ung voi dia chi - chu khong phai bang AWSIZE nho
    // hon hay bang mot AWADDR le.  cpu_write_data thi nguoc lai: no can phai
    // (gia tri o [7:0] hoac [15:0]), vi mang trong cache tron bang
    // write_data_with_size chu khong theo lane.
    //
    // Nhan doi gia tri ra ca bon lane la cach re nhat de bac cau hai quy uoc
    // do: WSTRB da chon dung lane roi, cac lane con lai bi bo qua.
    function automatic [31:0] lane_align_wdata;
        input [31:0] w_data; input [1:0] size;
        reg [31:0] res;
        begin
            case (size)
                2'b00:   res = {4{w_data[7:0]}};
                2'b01:   res = {2{w_data[15:0]}};
                default: res = w_data;
            endcase
            lane_align_wdata = res;
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

    // =========================================================================
    // uncache_en PHAI duoc chot cung luc voi req_addr.
    //
    // `uncache_en_i` la to hop tu dia chi SONG cua CPU (xem macro
    // `SOC_IS_UNCACHED trong top_soc.v). ARADDR/AWADDR da duoc chot vao
    // req_addr, nhung truoc day ARLEN, ARCACHE va AWCACHE van lay tu tin hieu
    // song:
    //
    //     m_axi_arlen = uncache_en ? 8'd0 : BURST_LEN;
    //
    // Khi mot nhanh doan sai / trap doi dia chi tu vung CACHEABLE sang vung
    // UNCACHED trong luc ARVALID dang cho ARREADY, ARLEN nhay 3 -> 0 GIUA
    // HANDSHAKE. AXI4 yeu cau moi tin hieu cua kenh dia chi phai ON DINH tu khi
    // VALID len cho toi khi READY len. Vi pham nay lam slave va interconnect bat
    // dong y ve so beat cua burst -> ROB treo slot, bus chet.
    //
    // Rang buoc do CO THAT: chinh FSM ben duoi da xu ly ca "dia chi doi giua mot
    // lan miss" (`if (cpu_addr == req_addr)` o trang thai DONE).
    //
    // Sua bang cach chot uncache cung nhip voi req_addr, roi dat lai ten
    // `uncache_en` cho ban DA CHOT - nho vay moi cho dung ben duoi tu dong lay
    // ban dung ma khong sot cho nao.
    // =========================================================================
    localparam IDLE   = 3'd0,
               LOOKUP = 3'd1,
               AR_REQ = 3'd2,
               R_WAIT = 3'd3,
               AW_REQ = 3'd4,
               W_REQ  = 3'd5,
               B_WAIT = 3'd6,
               DONE   = 3'd7;

    reg [2:0] state, next_state;
    reg       fsm_awvalid, fsm_wvalid, fsm_bready;
    reg       uncache_r;
    reg       bus_err_r;   // B2 - da thay RRESP/BRESP loi trong giao dich nay

    wire uncache_en = (state == IDLE) ? uncache_en_i : uncache_r;

    // =========================================================================
    // STORE BUFFER (MEMORY_FIX_PLAN.md Phase 1 / P2)
    //
    // Before: every store - hit or miss - held dcache_stall high for a whole
    // AW/W/B round trip across the 400 MHz -> clk_axi CDC, so store-heavy code
    // ran at bus speed no matter how big the cache was.
    //
    // Now a CACHEABLE store retires in the same 2 cycles as a load hit: the
    // merged word goes into the SRAM array (on a hit) and the AXI write goes
    // into this FIFO, which a small independent FSM drains in the background.
    //
    // Four ordering rules keep that safe.  Each one is load-bearing:
    //
    //  1. UNCACHED stores are never buffered.  A device register write must be
    //     visible before the next register read, and its error must stay
    //     precise, so it keeps the blocking AW_REQ/W_REQ/B_WAIT path below.
    //  2. Any access that needs the bus - an uncached load or store, or a
    //     cacheable read MISS - waits for `sb_drained` first.  That is what
    //     stops a device access from passing an earlier buffered memory store,
    //     and what stops a refill from reading a line whose pending store has
    //     not landed yet.
    //  3. A cacheable load HIT needs no forwarding: a store hit already merged
    //     its bytes into the array, so the array is the newest copy.  A store
    //     MISS does not touch the array, but the line is invalid, so the next
    //     load to it misses and rule 2 drains the buffer before the refill.
    //  4. A store whose slot is unavailable (`sb_full`) simply keeps stalling
    //     in LOOKUP, which degrades to the old behaviour instead of dropping.
    //  5. P2c - `cpu_fence` waits for `sb_drained` explicitly.  Rules 1 and 2
    //     only drain when the CORE itself needs the bus; nothing forces a drain
    //     for another master reaching AXI directly (the debugger through SBA).
    //     `fence` is that force.
    //
    // Rules 1 and 2 together mean the buffer can only ever be non-empty while
    // the main FSM is in IDLE or LOOKUP, so the two never drive AW/W/B at the
    // same time and no arbiter is needed.  Rule 5 does not change that: a fence
    // waits in IDLE and touches no channel at all.
    //
    // Test T7 in tests/tb_mem_paths.sv exists specifically to catch a violation
    // of rule 1.
    // =========================================================================
    localparam SB_PTR_W = $clog2(STORE_BUF_DEPTH);

    localparam SB_IDLE = 2'd0,
               SB_AW   = 2'd1,
               SB_W    = 2'd2,
               SB_B    = 2'd3;

    reg [1:0]                    sb_state;
    reg [C_M_AXI_ADDR_W-1:0]     sb_addr [0:STORE_BUF_DEPTH-1];
    reg [C_M_AXI_DATA_W-1:0]     sb_data [0:STORE_BUF_DEPTH-1];
    reg [(C_M_AXI_DATA_W/8)-1:0] sb_strb [0:STORE_BUF_DEPTH-1];

    // One extra bit on each pointer separates full from empty.
    reg [SB_PTR_W:0] sb_wptr, sb_rptr;

    wire [SB_PTR_W-1:0] sb_head  = sb_rptr[SB_PTR_W-1:0];
    wire [SB_PTR_W-1:0] sb_tail  = sb_wptr[SB_PTR_W-1:0];
    wire                sb_empty = (sb_wptr == sb_rptr);
    wire                sb_full  = (sb_wptr[SB_PTR_W] != sb_rptr[SB_PTR_W]) &&
                                   (sb_tail == sb_head);
    wire                sb_active = (sb_state != SB_IDLE);

    // `sb_empty` alone is not enough to hand the write channel back: the last
    // entry is popped when its BRESP arrives, and the drain FSM is still in
    // SB_B at that moment.  Everything that needs the bus waits on this.
    wire                sb_drained = sb_empty && (sb_state == SB_IDLE);

    reg  [7:0] sb_err_cnt;   // stretches the imprecise error for the APB PLIC
    assign dcache_sb_error = (sb_err_cnt != 8'd0);

    // AWSIZE la be rong cua BUS, khong phai be rong cua lenh store.  De no
    // bang mem_size thi mot `sb` phat AWSIZE = 0 va axi_ram - chi nhan
    // AxSIZE = 3'd2 - tra SLVERR roi bo qua beat.  Xem ghi chu ve
    // m_axi_awaddr ben duoi.
    assign m_axi_awid = 0; assign m_axi_awsize = $clog2(C_M_AXI_DATA_W/8); assign m_axi_awburst = 2'b01;
    assign m_axi_awlock = 0; assign m_axi_awcache = (sb_active || !uncache_en) ? 4'b0011 : 4'b0000;
    assign m_axi_awprot = 3'b000; assign m_axi_awqos = 0; assign m_axi_awregion = 0; assign m_axi_awlen = 0;
    assign m_axi_arid = 0; assign m_axi_arsize = $clog2(C_M_AXI_DATA_W/8); assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 0; assign m_axi_arcache = uncache_en ? 4'b0000 : 4'b0011;
    assign m_axi_arprot = 3'b000; assign m_axi_arqos = 0; assign m_axi_arregion = 0;

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

    // A cacheable store enters the buffer in exactly one cycle: the LOOKUP
    // cycle that also releases the core.  Gating the array write with the same
    // term keeps the merge single-shot when the buffer is full and LOOKUP has
    // to be held for several cycles.
    // R1b - `amo_hold` danh dau chu ky DAU cua mot AMO: chua duoc day vao store
    // buffer, chua duoc nha stall, vi ket qua ALU chua ton tai.
    reg  amo_pending;
    wire amo_hold = cpu_amo_req && !amo_pending;

    wire sb_push = (state == LOOKUP) && cpu_write_req && !uncache_en &&
                   (cpu_addr == req_addr) && !sb_full && !amo_hold;

    // Keep the AXI payload/address datapath outside the cache control
    // combinational process.  This removes a false combinational loop between
    // CPU read data and AMO write data at the SoC boundary.
    // Dia chi phat ra bus PHAI can word.  Truoc day ca hai duong duoi day
    // mang nguyen hai bit thap cua dia chi CPU, nen moi `sb`/`sh` va moi
    // `lb`/`lh` uncached bi axi_ram tu choi bang SLVERR va am tham khong lam
    // gi.  D-cache khong kiem tra BRESP/RRESP nen loi hoan toan im lang:
    // voi vung cacheable, write hit van cap nhat mang cua cache nen CPU doc
    // lai thay dung trong khi RAM that khong bao gio nhan duoc byte do; voi
    // DMAPOOL (uncached, khong co cache che lai) du lieu mat ngay lap tuc.
    //
    // Byte lane van duoc bao toan: WSTRB chon lane khi ghi, va khi doc thi
    // read_data_with_size da trich lane bang byte_offset san roi - no von
    // luon giai thiet nhan ve nguyen word chua dia chi do.
    //
    // Hoi quy cho truong hop nay o tests/tb_mem_paths.sv nhom T2 va T6.
    //
    // While the buffer drains it owns the write channel; the direct path below
    // is what an UNCACHED store uses.  The two are mutually exclusive by
    // construction (see rules 1 and 2 above), so this is a select, not an
    // arbiter.
    // -------------------------------------------------------------------------
    // R1a - payload W cua duong FSM duoc CHOT, khong con to hop tu cpu_write_data.
    //
    // Truoc:  m_axi_wdata = sb_active ? sb_data[sb_head]
    //                                 : lane_align_wdata(cpu_write_data, mem_size);
    // Nhanh thu hai la mot duong TO HOP chay thang tu `cpu_write_data` ra chan
    // AXI, tuc ra thang FIFO CDC cua u_dc_axi_bridge. Ma `cpu_write_data` cho
    // mot lenh nguyen tu lai la ket qua cua ca chuoi
    //
    //   dcache state -> so tag 2-way -> mux way -> read_data_with_size
    //     -> AMO ALU trong u_core/MEM -> quay nguoc ve day
    //
    // Do chinh la 99 trong 100 duong toi han cua ban tong hop 2026-09-09
    // (`u_dcache_state_reg[0]` -> `u_dc_axi_bridge_u_w_fifo.../buffer_reg`,
    // slack +2 ps). Chot payload vao thanh ghi CAT HAN duong do: dau ra AXI gio
    // chi den tu flop (`sb_data[sb_head]` hoac `fsm_wdata_q`).
    //
    // An toan ve thoi diem chot: duong FSM (khac duong store buffer) chi phuc vu
    // giao dich UNCACHED. Suot IDLE -> AW_REQ -> W_REQ -> B_WAIT thi
    // `dcache_stall` giu nguyen 1, nen lenh dung yen o tang MEM va
    // `cpu_write_data` / `mem_size` / `cpu_addr` khong doi. Chot lap lai o moi
    // chu ky IDLE co yeu cau la vo hai va idempotent.
    //
    // KHONG doi hanh vi mot chu ky nao: gia tri co mat o W_REQ y het truoc day.
    // Gia: 32 + 4 flop.
    // -------------------------------------------------------------------------
    reg [C_M_AXI_DATA_W-1:0]     fsm_wdata_q;
    reg [(C_M_AXI_DATA_W/8)-1:0] fsm_wstrb_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_wdata_q <= {C_M_AXI_DATA_W{1'b0}};
            fsm_wstrb_q <= {(C_M_AXI_DATA_W/8){1'b0}};
        end else if (state == IDLE && (cpu_read_req || cpu_write_req)) begin
            fsm_wdata_q <= lane_align_wdata(cpu_write_data, mem_size);
            fsm_wstrb_q <= gen_wstrb(mem_size, byte_offset);
        end
    end

    assign m_axi_awaddr = sb_active ? sb_addr[sb_head]
                                    : {current_addr[C_M_AXI_ADDR_W-1:2], 2'b00};
    assign m_axi_wdata  = sb_active ? sb_data[sb_head] : fsm_wdata_q;
    assign m_axi_wstrb  = sb_active ? sb_strb[sb_head] : fsm_wstrb_q;
    assign m_axi_wlast  = 1'b1;
    assign m_axi_arlen  = uncache_en ? 8'd0 : BURST_LEN;
    assign m_axi_araddr = uncache_en
        ? {current_addr[C_M_AXI_ADDR_W-1:2], 2'b00}
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
            uncache_r   <= 1'b0;
            bus_err_r   <= 1'b0;
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                valid_arr[i] <= 0;
                rr_ptr[i]    <= 0;
            end
        end else begin
            state <= next_state;

            // Chot dia chi VA thuoc tinh cacheability cua no trong CUNG mot nhip.
            if (state == IDLE && (cpu_read_req || cpu_write_req)) begin
                req_addr  <= cpu_addr;
                uncache_r <= uncache_en_i;
                bus_err_r <= 1'b0;      // B2 - moi giao dich bat dau sach
            end

            // B2 - RRESP/BRESP = 2'b10 (SLVERR) hoac 2'b11 (DECERR); bit [1] phu
            // ca hai. Chot lai thay vi dung truc tiep vi mot burst refill co 4
            // beat: chi can MOT beat loi la ca line khong dung duoc.
            if (state == R_WAIT && m_axi_rvalid && m_axi_rready && m_axi_rresp[1])
                bus_err_r <= 1'b1;
            if (state == B_WAIT && m_axi_bvalid && m_axi_bready && m_axi_bresp[1])
                bus_err_r <= 1'b1;

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

    // =========================================================================
    // Store-buffer FIFO and its drain FSM.
    //
    // The FSM is deliberately single-outstanding (one AW/W/B at a time): the
    // win here is decoupling the CORE from the bus, not pipelining the bus, and
    // a single outstanding write keeps store order on the wire trivially equal
    // to program order without needing BID tracking.
    // =========================================================================
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sb_state   <= SB_IDLE;
            sb_wptr    <= {(SB_PTR_W+1){1'b0}};
            sb_rptr    <= {(SB_PTR_W+1){1'b0}};
            sb_err_cnt <= 8'd0;
            for (k = 0; k < STORE_BUF_DEPTH; k = k + 1) begin
                sb_addr[k] <= {C_M_AXI_ADDR_W{1'b0}};
                sb_data[k] <= {C_M_AXI_DATA_W{1'b0}};
                sb_strb[k] <= {(C_M_AXI_DATA_W/8){1'b0}};
            end
        end else begin
            // Push.  req_addr is the address the array lookup used, and
            // cpu_addr == req_addr in sb_push proves the store instruction is
            // still the one presenting mem_size / cpu_write_data.
            if (sb_push) begin
                sb_addr[sb_tail] <= {req_addr[C_M_AXI_ADDR_W-1:2], 2'b00};
                sb_data[sb_tail] <= lane_align_wdata(cpu_write_data, mem_size);
                sb_strb[sb_tail] <= gen_wstrb(mem_size, byte_offset);
                sb_wptr          <= sb_wptr + 1'b1;
            end

            case (sb_state)
                SB_IDLE: if (!sb_empty) sb_state <= SB_AW;
                SB_AW:   if (m_axi_awready) sb_state <= SB_W;
                SB_W:    if (m_axi_wready)  sb_state <= SB_B;
                SB_B: if (m_axi_bvalid) begin
                    // Pop on the response, not on the W beat: the entry has to
                    // stay addressable until the slave has taken it, and
                    // sb_drained must not go true before the B arrives.
                    sb_rptr  <= sb_rptr + 1'b1;
                    sb_state <= SB_IDLE;
                    // SLVERR (2'b10) or DECERR (2'b11); bit [1] covers both.
                    if (m_axi_bresp[1]) sb_err_cnt <= 8'd255;
                end
                // R8 - khong con `default`.
                //
                // `sb_state` rong 2 bit va bon ma SB_IDLE/SB_AW/SB_W/SB_B phu
                // KIN 4 gia tri, nen nhanh default khong the toi duoc va Genus
                // bao CDFG-472 moi lan chay. No khong he la luoi an toan: thanh
                // ghi khong the giu gia tri nao khac de ma roi vao do.
                //
                // Muon co phong thu that thi phai doi sang one-hot va kiem tra
                // popcount != 1 - do la mot quyet dinh khac, khong phai mot dong
                // `default` cho co.
            endcase

            // Hold the imprecise error long enough for the clk_apb PLIC gateway
            // to latch it, then release so a single fault cannot wedge the line
            // permanently.  A new fault reloads the counter above.
            if (sb_err_cnt != 8'd0 &&
                !(sb_state == SB_B && m_axi_bvalid && m_axi_bresp[1]))
                sb_err_cnt <= sb_err_cnt - 8'd1;
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

    // R1b - dat sau khoi tinh `hit_flag` o tren vi no dung tin hieu do.
    assign dcache_amo_capture = (state == LOOKUP) && amo_hold && !uncache_en &&
                                (cpu_addr == req_addr) && hit_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            amo_pending <= 1'b0;
        else if (state != LOOKUP)
            amo_pending <= 1'b0;
        else if (dcache_amo_capture)
            amo_pending <= 1'b1;
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
        end else if (sb_push && hit_flag) begin
            // The macro has no byte mask, so merge and rewrite the whole word.
            data_write_word = write_data_with_size(
                read_word, cpu_write_data, mem_size, byte_offset);
            data_write_en[hit_way] = 1'b1;
        end
    end

    // The main FSM only ever drives the write channel for an UNCACHED store;
    // the drain FSM drives it for everything else.  Rules 1 and 2 make the two
    // mutually exclusive, so these are ORs, not an arbiter.
    assign m_axi_awvalid = fsm_awvalid || (sb_state == SB_AW);
    assign m_axi_wvalid  = fsm_wvalid  || (sb_state == SB_W);
    assign m_axi_bready  = fsm_bready  || (sb_state == SB_B);

    always @(*) begin
        next_state    = state; dcache_hit    = 1'b0; dcache_stall  = 1'b0;
        way_update    = {C_WAYS{1'b0}};

        fsm_awvalid = 0; fsm_wvalid = 0; fsm_bready = 0; m_axi_arvalid = 0; m_axi_rready = 0;
        case (state)
            IDLE: begin
                // P2c - FENCE.  Giu core lai cho toi khi entry cuoi cung cua
                // store buffer nhan xong BRESP.  Khong dung toi mang SRAM,
                // khong dung toi kenh AXI nao, nen no o nguyen IDLE va khong
                // bao gio tranh chap voi FSM xa.
                //
                // `dcache_hit` van phai xung dung mot chu ky: giao thuc core-side
                // (`stall` cao suot, `hit` la xung ket thuc) la CHUNG cho ca ba
                // duong dcache/icache/tcm, va testbench cung cho tren no.  Fence
                // khong tra du lieu, nen `cpu_read_data` giu 0 - dung roi, tang
                // MEM khong lay gi tu duong nay cho mot fence.
                //
                // Khong be tac: FSM xa chay doc lap voi tin hieu nay.
                if (cpu_fence && !cpu_read_req && !cpu_write_req) begin
                    dcache_stall = !sb_drained;
                    dcache_hit   =  sb_drained;
                end
                // Address phase: the SRAM read is issued here and resolved in
                // LOOKUP, so even a hit costs one stall cycle.
                else if (cpu_read_req || cpu_write_req) begin
                    dcache_stall = 1'b1;
                    if (uncache_en) begin
                        // Rule 2.  A device access must not pass a buffered
                        // memory store, so hold here until the last BRESP has
                        // landed.  Re-latching the same req_addr every cycle
                        // while waiting is harmless.
                        if (sb_drained)
                            next_state = cpu_read_req ? AR_REQ : AW_REQ;
                    end else begin
                        next_state = LOOKUP;
                    end
                end
            end
            LOOKUP: begin
                dcache_stall = 1'b1;
                if (cpu_read_req && cpu_addr == req_addr) begin
                    if (hit_flag) begin
                        // R1b - mot AMO phai o lai them mot chu ky. `amo_hold`
                        // chi cao o chu ky dau; chu ky sau no ha va nhanh nay
                        // nha stall y het truoc day.
                        if (!amo_hold) begin
                            dcache_stall = 1'b0;
                            dcache_hit   = 1'b1;
                            next_state   = IDLE;
                        end
                    end else if (sb_drained) begin
                        next_state = AR_REQ;
                    end
                    // Rule 2 again, read side: a refill must not read a line
                    // that a still-buffered store belongs to.  Holding here is
                    // safe because array_read only fires in IDLE, so hit_flag
                    // and read_word keep the values this lookup produced.
                end else if (cpu_write_req && cpu_addr == req_addr) begin
                    // Write-through with a store buffer: the AXI write is
                    // handed to the FIFO and the core is released now.  On a
                    // hit the merged word went into the array in this same
                    // cycle (data_write_en, gated by sb_push).
                    //
                    // When the FIFO is full there is no slot to hand it to, so
                    // stay here stalling - the pre-buffer behaviour - until the
                    // drain FSM frees one.
                    if (!sb_full) begin
                        dcache_stall = 1'b0;
                        dcache_hit   = 1'b1;
                        next_state   = IDLE;
                    end
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
                dcache_stall = 1'b1; fsm_awvalid = 1'b1;
                if (m_axi_awready) next_state = W_REQ;
            end
            W_REQ: begin
                dcache_stall = 1'b1; fsm_wvalid = 1'b1;
                if (m_axi_wready) next_state = B_WAIT;
            end
            B_WAIT: begin
                dcache_stall = 1'b1; fsm_bready = 1'b1;
                if (m_axi_bvalid) next_state = DONE;
            end
            DONE: begin
                // 1. LUÔN CẬP NHẬT TAG/VALID NẾU LÀ READ MISS (Không Uncache).
                // Kể cả khi CPU đã Flush đổi địa chỉ, ta vẫn giữ block vừa fetch.
                // Dữ liệu đã được ghi từng beat trong R_WAIT.
                // B2 - `!bus_err_r` la BAT BUOC. Neu van danh dau valid thi line
                // rac (du lieu tu mot giao dich DECERR) tro thanh hop le, va lan
                // doc SAU se HIT vao no - tra du lieu sai ma khong con loi nao de
                // bao. Mot lan loi bien thanh loi VINH VIEN va im lang.
                // Du lieu da ghi vao mang o R_WAIT khong sao: valid = 0 nen khong
                // ai doc toi.
                if (cpu_read_req && !uncache_en && !bus_err_r) begin
                    way_update[victim_way] = 1'b1;
                end

                // 2. RÀNG BUỘC TÍN HIỆU TRẢ VỀ CPU BẰNG ĐỊA CHỈ
                if (cpu_addr == req_addr) begin
                    // ---------------------------------------------------------
                    // R11 - mot AMO TRUOT phai chay lai vong tra cuu, khong duoc
                    // nha o day.
                    //
                    // Loi NAY CO TU TRUOC R1b. Mot AMO dat CA cpu_read_req va
                    // cpu_write_req. O LOOKUP, nhanh doc duoc uu tien; neu TRUOT
                    // thi FSM di AR_REQ -> R_WAIT -> DONE. Nhung `sb_push` doi
                    // `state == LOOKUP`, nen khi DONE nha stall thi lenh nguyen
                    // tu RETIRE MA KHONG HE GHI. Mot `amoadd` vao line chua nam
                    // trong cache am tham bien thanh mot lenh doc.
                    //
                    // Sua: giu stall va quay ve IDLE. Line vua duoc nap va
                    // way_update da danh dau valid ngay trong chu ky nay, nen
                    // vong thu hai chac chan HIT roi chay dung nhip hai chu ky
                    // cua R1b.
                    //
                    // `!bus_err_r` la bat buoc: khi refill loi thi way_update bi
                    // chan (xem muc 1 o tren), line KHONG valid, nen vong thu hai
                    // se truot tiep -> lap vo han. Truong hop do phai nha ra de
                    // `dcache_error` o duoi bao trap.
                    // ---------------------------------------------------------
                    if (cpu_amo_req && !uncache_en && !bus_err_r) begin
                        dcache_stall = 1'b1;
                        dcache_hit   = 1'b0;
                    end else begin
                        // Nhả stall và báo Hit vì lệnh vẫn còn nguyên (không bị Flush)
                        dcache_stall = 1'b0;
                        dcache_hit   = 1'b1;
                    end
                end else begin
                    // Lệnh đã bị Flush sang địa chỉ khác. Giữ stall để FSM quay về IDLE.
                    dcache_stall  = 1'b1;
                    dcache_hit    = 1'b0;
                end

                next_state = IDLE;
            end
            // R8 - khong con `default`: xem ghi chu o case sb_state ben tren.
            // `state` rong 3 bit va tam ma IDLE..DONE (3'd0..3'd7) phu KIN 8 gia
            // tri, nen default la nhanh chet (CDFG-472). Moi ngo ra cua khoi nay
            // da duoc gan mac dinh o dau always @(*) nen bo default KHONG sinh
            // latch.
        endcase
    end

    // B2 - dong bien voi dcache_hit: chinh chu ky lenh duoc tra ve cho core.
    assign dcache_error = (state == DONE) && bus_err_r && (cpu_addr == req_addr);

    // m_axi_bresp / m_axi_rresp DA DUOC DUNG o tren - khong con nam trong danh
    // sach "co y bo qua" nua.
    wire _unused_ok = &{1'b0, m_axi_bid, m_axi_rid};

endmodule
