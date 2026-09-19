`timescale 1ns / 1ps
`include "dma_defines.vh"

// ============================================================
// dma_channel.v — Mot kenh DMA (src -> FIFO -> align -> dst)
// Layer : Reusable IP
// Tach ra tu dma_core.v o DMA v2, sua lon.
//
// Khac voi DMA v1
// ---------------
//  1. Can byte tuy y + doi do rong, nho dma_align. `cfg_bad` khong
//     con tu choi dia chi/do dai lech 4 byte.
//  2. FIXED burst khi incr=0 — doc FIFO ngoai vi cho dung.
//  3. Ke toan theo BEAT thay vi byte: don gian hon nhieu khi lan
//     nguon va lan dich lech nhau.
//  4. Scatter-gather: trang thai ST_FETCH, chuoi NEXT_PTR.
//  5. 2D/stride, shadow reload, circular.
//  6. Abort/suspend theo kenh, XFER_CNT, ERR_ADDR, ngat HALF.
//  7. LEN 32 bit (v1: 16 bit -> toi da 64 KB).
//
// Hai cho lech so voi spec, co chu y
// ----------------------------------
//  a) Bo chon nguon cau hinh (APB / descriptor / shadow) nam NGAY
//     TRONG module nay chu khong tach thanh dma_cfg_mux rieng nhu
//     spec §3 phac ra. Mot module 20 dong chi de chon 8 thanh ghi
//     lam ranh gioi xau hon: no phai lo ca tin hieu tai, ma tai lai
//     gan chat voi FSM o day.
//  b) Ngat HALF lay moc theo LEN cua descriptor hien tai, khong
//     phai theo LEN*NUM_LINES. Tinh tich do se sinh mot bo nhan
//     32x16 THAT trong phan cung — dat va nam gan duong gang.
//     HALF sinh ra cho ping-pong buffer (nlines=1), nen o che do 2D
//     no bao o giua DONG DAU. Ghi ro de phan mem khong hieu nham.
//
// Duong gang: `ch_bmax -> rd_addr` van la duong gang nhat chip
// (3761 ps, bien SS 3 ps o ban 2026-09-11). Moi phep so sanh rong
// o day deu tach thanh OR-reduce phan cao SONG SONG voi so sanh
// phan thap — xem `rd_need_small`. Do rong LEN khong lam duong
// gang dai them, chi them dung mot tang OR.
// ============================================================

module dma_channel #(
    parameter ADDR_W       = 32,
    parameter LEN_W        = 4,
    parameter ID_W         = 4,
    parameter N_CH_W       = 2,
    parameter CH_IDX       = 0,
    parameter FIFO_DEPTH   = 16,
    parameter MAX_BURST    = 64,
    parameter BURST_W      = 7,
    parameter TOKEN_W      = 4,
    parameter OUT_W        = 4,
    parameter PERIPH_NUM_W = 5,
    parameter LEN_FIELD_W  = 32
) (
    input  wire                    clk,
    input  wire                    rst_n,

    //  Cau hinh tu dma_regfile (on dinh khi active=0)
    input  wire [ADDR_W-1:0]       cfg_src_addr,
    input  wire [ADDR_W-1:0]       cfg_dst_addr,
    input  wire [LEN_FIELD_W-1:0]  cfg_len,
    input  wire [31:0]             cfg_ctrl,
    input  wire [ADDR_W-1:0]       cfg_desc_ptr,
    input  wire [31:0]             cfg_src_stride,
    input  wire [31:0]             cfg_dst_stride,
    input  wire [15:0]             cfg_num_lines,
    input  wire [ADDR_W-1:0]       cfg_sh_src,
    input  wire [ADDR_W-1:0]       cfg_sh_dst,
    input  wire [LEN_FIELD_W-1:0]  cfg_sh_len,
    input  wire [31:0]             cfg_sh_ctrl,
    input  wire [TOKEN_W-1:0]      cfg_tokens,
    input  wire [OUT_W-1:0]        cfg_rd_out_max,
    input  wire [OUT_W-1:0]        cfg_wr_out_max,

    //  Dieu khien
    input  wire                    start,
    output wire                    done,
    output wire                    active,
    output wire                    suspended,
    output wire                    chain_active,
    output reg  [`DMA_ERR_W-1:0]   err,
    output reg  [ADDR_W-1:0]       err_addr,
    output wire [LEN_FIELD_W-1:0]  xfer_cnt,
    output reg                     half_pulse,
    output reg                     chain_pulse,

    //  Cong descriptor (toi dma_desc)
    output wire                    desc_req,
    output wire [ADDR_W-1:0]       desc_addr,
    input  wire                    desc_ack,          // 1 chu ky: du lieu hop le
    input  wire [`DESC_BEATS*32-1:0] desc_data,
    input  wire                    desc_fail,         // fetch loi

    //  Trigger ngoai vi
    input  wire [31:1]             periph_req,
    output reg  [31:1]             periph_clr,

    //  Lenh doc
    output wire                    rd_cmd_valid,
    input  wire                    rd_cmd_ready,
    output wire [ADDR_W-1:0]       rd_cmd_addr,
    output wire [LEN_W-1:0]        rd_cmd_len,
    output wire [2:0]              rd_cmd_size,
    output wire [1:0]              rd_cmd_burst,
    output wire [ID_W-1:0]         rd_cmd_id,
    output wire [12:0]             rd_cmd_bytes,      // cho IOPMP
    input  wire                    rd_viol,           // IOPMP chan

    //  Du lieu doc
    input  wire                    rd_dat_valid,
    output wire                    rd_dat_ready,
    input  wire [`AXI_DATA_W-1:0]  rd_dat_data,
    input  wire                    rd_dat_last,

    //  Phan hoi doc
    input  wire                    rd_rsp_valid,
    input  wire [1:0]              rd_rsp_err,

    //  Lenh ghi
    output wire                    wr_cmd_valid,
    input  wire                    wr_cmd_ready,
    output wire [ADDR_W-1:0]       wr_cmd_addr,
    output wire [LEN_W-1:0]        wr_cmd_len,
    output wire [2:0]              wr_cmd_size,
    output wire [1:0]              wr_cmd_burst,
    output wire [ID_W-1:0]         wr_cmd_id,
    output wire [12:0]             wr_cmd_bytes,      // cho IOPMP
    input  wire                    wr_viol,           // IOPMP chan

    //  Du lieu ghi
    output wire                    wr_dat_valid,
    input  wire                    wr_dat_ready,
    output wire [`AXI_DATA_W-1:0]  wr_dat_data,
    output wire [`AXI_STRB_W-1:0]  wr_dat_strb,

    //  Phan hoi ghi
    input  wire                    wr_rsp_valid,
    input  wire [1:0]              wr_rsp_err,

    //  Sideband AXI (tu CTRL cua transfer dang chay)
    output wire [2:0]              axi_prot,
    output wire [3:0]              axi_cache,

    //  Timeout
    input  wire                    timeout_rd,
    input  wire                    timeout_wr_aw,
    input  wire                    timeout_wr_w
);

    // =========================================================
    // Ham va hang
    // =========================================================
    function automatic integer clog2_fn;
        input integer v;
        integer i;
        begin
            clog2_fn = 0;
            for (i = v-1; i > 0; i = i >> 1)
                clog2_fn = clog2_fn + 1;
        end
    endfunction

    localparam FIFO_PTR_W = clog2_fn(FIFO_DEPTH);
    localparam FIFO_CNT_W = FIFO_PTR_W + 1;
    localparam SEQ_W      = ID_W - N_CH_W;
    localparam BEATS_W    = LEN_W + 1;              // giu duoc 1..2^LEN_W
    localparam MAX_BEATS  = (1 << LEN_W);
    localparam MAX_BURST_LIMIT_INT =
        (MAX_BURST < MAX_BEATS*`AXI_BYTES) ? MAX_BURST : MAX_BEATS*`AXI_BYTES;
    localparam INFL_W     = FIFO_CNT_W + 1;

    // FIFO luu kem lan/so byte cua moi beat — xem muc "Phia nhan".
    localparam FIFO_W = `AXI_DATA_W + 2 + 3;

    // =========================================================
    // KHAI BAO TRUOC — moi tin hieu duoc FSM doc phai co o day,
    // truoc khoi always cua FSM.
    // =========================================================
    wire        rd_cmd_fire, wr_cmd_fire;
    wire        wr_dat_beat;
    wire        abort_req, suspend_req;
    wire        fifo_wr_en, fifo_empty;
    wire [2:0]  rx_cnt, tx_cnt;
    wire [4:0]  al_level;
    wire        rd_rsp_error, wr_rsp_error, timeout_seen, viol_seen;
    wire [LEN_FIELD_W-1:0] rd_payload, wr_payload;
    wire [1:0]  rd_lane, wr_lane;
    reg  [OUT_W-1:0] rd_outs, wr_outs;

    // =========================================================
    // Thanh ghi lam viec — nguon: APB, descriptor, hoac shadow
    // =========================================================
    reg [ADDR_W-1:0]      w_src;
    reg [ADDR_W-1:0]      w_dst;
    reg [LEN_FIELD_W-1:0] w_len;
    reg [31:0]            w_ctrl;
    reg [ADDR_W-1:0]      w_next;
    reg [31:0]            w_sstride;
    reg [31:0]            w_dstride;
    reg [15:0]            w_nlines;

    wire        c_src_incr = w_ctrl[`CTRL_SI];
    wire        c_dst_incr = w_ctrl[`CTRL_DI];
    wire [1:0]  c_src_w    = w_ctrl[`CTRL_SW_LSB+1 : `CTRL_SW_LSB];
    wire [1:0]  c_dst_w    = w_ctrl[`CTRL_DW_LSB+1 : `CTRL_DW_LSB];
    wire [BURST_W-1:0] c_bmax = w_ctrl[BURST_W : `CTRL_BMAX_LSB];
    wire [PERIPH_NUM_W-1:0] c_pnum =
        w_ctrl[`CTRL_PNUM_LSB+PERIPH_NUM_W-1 : `CTRL_PNUM_LSB];
    wire        c_reload   = w_ctrl[`CTRL_RELOAD];
    wire        c_circ     = w_ctrl[`CTRL_CIRCULAR];

    assign axi_prot  = {1'b0, ~w_ctrl[`CTRL_SECURE], w_ctrl[`CTRL_PRIV]};
    assign axi_cache = w_ctrl[`CTRL_CACHE_LSB+3 : `CTRL_CACHE_LSB];

    // Do rong -> so byte moi beat va ma AxSIZE. Chi co hieu luc khi
    // FIXED; INCR luon 32-bit va de dma_align lo phan can byte.
    function [2:0] w_bytes_fn;
        input [1:0] wsel;
        begin
            case (wsel)
                `DMA_W8:  w_bytes_fn = 3'd1;
                `DMA_W16: w_bytes_fn = 3'd2;
                default:  w_bytes_fn = 3'd4;
            endcase
        end
    endfunction

    function [2:0] w_size_fn;
        input [1:0] wsel;
        begin
            case (wsel)
                `DMA_W8:  w_size_fn = `AXI_SIZE_1B;
                `DMA_W16: w_size_fn = `AXI_SIZE_2B;
                default:  w_size_fn = `AXI_SIZE_4B;
            endcase
        end
    endfunction

    wire [2:0] src_bytes = c_src_incr ? 3'd4 : w_bytes_fn(c_src_w);
    wire [2:0] dst_bytes = c_dst_incr ? 3'd4 : w_bytes_fn(c_dst_w);
    wire [2:0] src_size  = c_src_incr ? `AXI_SIZE_4B : w_size_fn(c_src_w);
    wire [2:0] dst_size  = c_dst_incr ? `AXI_SIZE_4B : w_size_fn(c_dst_w);

    // =========================================================
    // May trang thai
    // =========================================================
    localparam [2:0]
        ST_IDLE  = 3'd0,
        ST_FETCH = 3'd1,
        ST_RUN   = 3'd2,
        ST_DRAIN = 3'd3,
        ST_DONE  = 3'd4;

    reg [2:0] state;
    reg       abort_lat;
    reg       chain_r;
    reg       start_pend;

    assign active       = (state != ST_IDLE);
    assign done         = (state == ST_DONE);
    assign chain_active = chain_r;

    // Huy / tam dung doc thang tu thanh ghi APB (khong phai ban lam
    // viec) vi phan mem ghi chung KHI kenh dang chay.
    assign abort_req   = cfg_ctrl[`CTRL_ABORT];
    assign suspend_req = cfg_ctrl[`CTRL_SUSPEND];
    assign suspended   = suspend_req & active;

    // Chi khoi dong khi FIFO da sach. Xung `start` co the chi dai
    // mot chu ky, nen phai chot lai — neu khong yeu cau chuyen se
    // bien mat trong luc cho xa (toi da FIFO_DEPTH chu ky).
    wire start_go = (start | start_pend) & fifo_empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                start_pend <= 1'b0;
        else if (state != ST_IDLE) start_pend <= 1'b0;
        else if (start_go)         start_pend <= 1'b0;
        else if (start)            start_pend <= 1'b1;
    end

    // =========================================================
    // Dem dia chi / so byte
    // =========================================================
    reg [ADDR_W-1:0]      rd_addr, wr_addr;
    reg [LEN_FIELD_W-1:0] rd_remain;   // byte chua PHAT lenh doc
    reg [LEN_FIELD_W-1:0] wr_remain;   // byte chua PHAT lenh ghi
    reg [LEN_FIELD_W-1:0] rx_remain;   // byte chua NHAN ve
    reg [LEN_FIELD_W-1:0] tx_remain;   // byte chua GUI di
    reg [ADDR_W-1:0]      rd_line_base, wr_line_base;
    reg [15:0]            rd_line, wr_line;
    reg [LEN_FIELD_W-1:0] done_bytes;
    reg                   half_done_r;
    reg                   rx_first, tx_first;
    reg                   start_line_load;

    assign xfer_cnt = done_bytes;
    assign rd_lane  = rd_addr[1:0];
    assign wr_lane  = wr_addr[1:0];

    // =========================================================
    // Gioi han burst
    // =========================================================
    wire [BURST_W-1:0] bmax_eff =
        (c_bmax == {BURST_W{1'b0}}) ? MAX_BURST_LIMIT_INT[BURST_W-1:0] :
        (c_bmax >  MAX_BURST_LIMIT_INT[BURST_W-1:0]) ?
                   MAX_BURST_LIMIT_INT[BURST_W-1:0] : c_bmax;

    function [BEATS_W-1:0] cap_beats_fn;
        input [BURST_W-1:0] bytes;
        input [2:0]         per_beat;
        reg   [BURST_W-1:0] q;
        begin
            case (per_beat)
                3'd1:    q = bytes;
                3'd2:    q = bytes >> 1;
                default: q = bytes >> 2;
            endcase
            if (q == {BURST_W{1'b0}})
                cap_beats_fn = {{(BEATS_W-1){1'b0}}, 1'b1};
            else if (q > MAX_BEATS[BURST_W-1:0])
                cap_beats_fn = MAX_BEATS[BEATS_W-1:0];
            else
                cap_beats_fn = q[BEATS_W-1:0];
        end
    endfunction

    wire [BEATS_W-1:0] rd_cap_beats = cap_beats_fn(bmax_eff, src_bytes);
    wire [BEATS_W-1:0] wr_cap_beats = cap_beats_fn(bmax_eff, dst_bytes);

    // =========================================================
    // So beat con CAN cho phan con lai cua dong hien tai
    //   INCR : ceil((lan + con_lai) / 4)
    //   FIXED: ceil(con_lai / so_byte_moi_beat)
    // =========================================================
    function [LEN_FIELD_W-1:0] beats_need_fn;
        input [LEN_FIELD_W-1:0] rem;
        input [1:0]             lane;
        input                   is_incr;
        input [2:0]             per_beat;
        reg   [LEN_FIELD_W-1:0] span;
        begin
            if (is_incr) begin
                span = rem + {{(LEN_FIELD_W-2){1'b0}}, lane};
                beats_need_fn = (span + {{(LEN_FIELD_W-2){1'b0}}, 2'd3}) >> 2;
            end else begin
                case (per_beat)
                    3'd1: beats_need_fn = rem;
                    3'd2: beats_need_fn =
                          (rem + {{(LEN_FIELD_W-1){1'b0}}, 1'b1}) >> 1;
                    default: beats_need_fn =
                          (rem + {{(LEN_FIELD_W-2){1'b0}}, 2'd3}) >> 2;
                endcase
            end
        end
    endfunction

    wire [LEN_FIELD_W-1:0] rd_beats_need =
        beats_need_fn(rd_remain, rd_lane, c_src_incr, src_bytes);
    wire [LEN_FIELD_W-1:0] wr_beats_need =
        beats_need_fn(wr_remain, wr_lane, c_dst_incr, dst_bytes);

    // Tach so sanh: OR-reduce phan cao SONG SONG voi so sanh phan
    // thap. Nho vay do rong LEN 32 bit khong noi dai duong gang
    // ch_bmax -> rd_addr, chi them dung mot tang OR.
    wire rd_need_small = ~|rd_beats_need[LEN_FIELD_W-1:BEATS_W];
    wire wr_need_small = ~|wr_beats_need[LEN_FIELD_W-1:BEATS_W];

    // Cho trong toi bien 4 KB, tinh theo beat. Chi INCR moi can:
    // FIXED giu nguyen dia chi nen khong cat bien nao.
    wire [10:0] rd_room_beats = 11'd1024 - {1'b0, rd_addr[11:2]};
    wire [10:0] wr_room_beats = 11'd1024 - {1'b0, wr_addr[11:2]};

    function [BEATS_W-1:0] min3_beats_fn;
        input [LEN_FIELD_W-1:0] need;
        input                   need_small;
        input [BEATS_W-1:0]     cap;
        input [10:0]            room;
        input                   is_incr;
        reg   [BEATS_W-1:0]     n;
        reg   [BEATS_W-1:0]     r;
        reg   [BEATS_W-1:0]     m;
        begin
            n = need_small ? need[BEATS_W-1:0] : {BEATS_W{1'b1}};
            if (!is_incr)
                r = {BEATS_W{1'b1}};
            else if (room > {{(11-BEATS_W){1'b0}}, {BEATS_W{1'b1}}})
                r = {BEATS_W{1'b1}};
            else
                r = room[BEATS_W-1:0];
            m = (n < cap) ? n : cap;
            min3_beats_fn = (r < m) ? r : m;
        end
    endfunction

    wire [BEATS_W-1:0] rd_beats = min3_beats_fn(
        rd_beats_need, rd_need_small, rd_cap_beats, rd_room_beats, c_src_incr);
    wire [BEATS_W-1:0] wr_beats = min3_beats_fn(
        wr_beats_need, wr_need_small, wr_cap_beats, wr_room_beats, c_dst_incr);

    // So byte payload ma burst nay tieu thu.
    // INCR: beats*4 tru phan dem dan dau (lan), kep theo so con lai.
    function [LEN_FIELD_W-1:0] payload_fn;
        input [BEATS_W-1:0]     beats;
        input [1:0]             lane;
        input                   is_incr;
        input [2:0]             per_beat;
        input [LEN_FIELD_W-1:0] rem;
        reg   [15:0]            raw;
        begin
            if (is_incr)
                raw = ({{(16-BEATS_W){1'b0}}, beats} << 2) - {14'd0, lane};
            else
                case (per_beat)
                    3'd1:    raw = {{(16-BEATS_W){1'b0}}, beats};
                    3'd2:    raw = {{(16-BEATS_W){1'b0}}, beats} << 1;
                    default: raw = {{(16-BEATS_W){1'b0}}, beats} << 2;
                endcase
            payload_fn = ({{(LEN_FIELD_W-16){1'b0}}, raw} > rem) ?
                         rem : {{(LEN_FIELD_W-16){1'b0}}, raw};
        end
    endfunction

    assign rd_payload =
        payload_fn(rd_beats, rd_lane, c_src_incr, src_bytes, rd_remain);
    assign wr_payload =
        payload_fn(wr_beats, wr_lane, c_dst_incr, dst_bytes, wr_remain);

    // So byte AXI cham toi — cho IOPMP. Khac payload vi INCR con
    // doc ca phan dem dan dau/duoi cua word bien.
    assign rd_cmd_bytes = c_src_incr
        ? ({{(13-BEATS_W){1'b0}}, rd_beats} << 2)
        : rd_payload[12:0];
    assign wr_cmd_bytes = c_dst_incr
        ? ({{(13-BEATS_W){1'b0}}, wr_beats} << 2)
        : wr_payload[12:0];

    // =========================================================
    // Dem lenh dang bay
    // =========================================================
    assign rd_cmd_fire = rd_cmd_valid & rd_cmd_ready;
    assign wr_cmd_fire = wr_cmd_valid & wr_cmd_ready;

    wire rd_stall = (cfg_rd_out_max != {OUT_W{1'b0}}) & (rd_outs >= cfg_rd_out_max);
    wire wr_stall = (cfg_wr_out_max != {OUT_W{1'b0}}) & (wr_outs >= cfg_wr_out_max);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_outs <= {OUT_W{1'b0}};
            wr_outs <= {OUT_W{1'b0}};
        end else if (state == ST_IDLE) begin
            rd_outs <= {OUT_W{1'b0}};
            wr_outs <= {OUT_W{1'b0}};
        end else begin
            case ({rd_cmd_fire, rd_rsp_valid})
                2'b10: rd_outs <= rd_outs + 1'b1;
                2'b01: rd_outs <= (rd_outs == {OUT_W{1'b0}}) ?
                                  {OUT_W{1'b0}} : rd_outs - 1'b1;
                default: ;
            endcase
            case ({wr_cmd_fire, wr_rsp_valid})
                2'b10: wr_outs <= wr_outs + 1'b1;
                2'b01: wr_outs <= (wr_outs == {OUT_W{1'b0}}) ?
                                  {OUT_W{1'b0}} : wr_outs - 1'b1;
                default: ;
            endcase
        end
    end

    // Token — dieu hoa toc do doc so voi ghi
    reg [TOKEN_W-1:0] tokens;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tokens <= {TOKEN_W{1'b0}};
        else if ((state == ST_IDLE) || (state == ST_DONE))
            tokens <= cfg_tokens;
        else if (rd_cmd_fire & ~wr_rsp_valid)
            tokens <= (tokens == {TOKEN_W{1'b0}}) ? {TOKEN_W{1'b0}} : tokens - 1'b1;
        else if (~rd_cmd_fire & wr_rsp_valid)
            tokens <= tokens + 1'b1;
    end

    wire token_ok = (cfg_tokens == {TOKEN_W{1'b0}}) |
                    (tokens != {TOKEN_W{1'b0}}) |
                    (wr_remain == {LEN_FIELD_W{1'b0}});

    // =========================================================
    // Bat tay ngoai vi
    // =========================================================
    wire [31:0] periph_req_ext = {periph_req, 1'b1};
    wire        periph_rdy     = periph_req_ext[c_pnum];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            periph_clr <= 31'b0;
        end else begin
            periph_clr <= 31'b0;
            if (rd_cmd_fire && (c_pnum != {PERIPH_NUM_W{1'b0}}))
                periph_clr <= (31'b1 << (c_pnum - 1'b1));
        end
    end

    // =========================================================
    // Phia nhan: tinh lan/so byte cho TUNG beat ve, luu KEM du lieu
    // vao FIFO. Nho vay phia dong goi khong phai tinh lai — thu tu
    // FIFO dam bao khop tung beat mot.
    // =========================================================
    wire        fifo_rd_en;
    wire        fifo_full;
    wire [FIFO_W-1:0] fifo_rdata;
    wire [FIFO_CNT_W-1:0] fifo_count;

    wire [1:0] rx_lane = c_src_incr ? (rx_first ? w_src[1:0] : 2'b00)
                                    : w_src[1:0];
    wire [2:0] rx_room = c_src_incr ? (3'd4 - {1'b0, rx_lane}) : src_bytes;
    assign     rx_cnt  = (rx_remain < {{(LEN_FIELD_W-3){1'b0}}, rx_room})
                         ? rx_remain[2:0] : rx_room;

    assign fifo_wr_en   = rd_dat_valid & rd_dat_ready;
    assign rd_dat_ready = ~fifo_full;

    sync_ff #(
        .DATA_W    (FIFO_W),
        .DEPTH     (FIFO_DEPTH),
        .PTR_W     (FIFO_PTR_W),
        .AFULL_TH  (4),
        .AEMPTY_TH (1),
        .OUTREG    (0)
    ) u_data_fifo (
        .clk         (clk),
        .rst_n       (rst_n),
        .wr_en       (fifo_wr_en),
        .wr_data     ({rx_cnt, rx_lane, rd_dat_data}),
        .rd_en       (fifo_rd_en),
        .rd_data     (fifo_rdata),
        .full        (fifo_full),
        .empty       (fifo_empty),
        .almost_full (),
        .almost_empty(),
        .count       (fifo_count)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_first  <= 1'b1;
            rx_remain <= {LEN_FIELD_W{1'b0}};
        end else if (state == ST_IDLE) begin
            rx_first  <= 1'b1;
            rx_remain <= {LEN_FIELD_W{1'b0}};
        end else if (start_line_load) begin
            rx_first  <= 1'b1;
            rx_remain <= w_len;
        end else if (fifo_wr_en) begin
            rx_first  <= 1'b0;
            if (rx_remain == {{(LEN_FIELD_W-3){1'b0}}, rx_cnt}) begin
                // Het mot dong 2D -> dong ke tiep bat dau lai
                rx_remain <= w_len;
                rx_first  <= 1'b1;
            end else begin
                rx_remain <= rx_remain - {{(LEN_FIELD_W-3){1'b0}}, rx_cnt};
            end
        end
    end

    // =========================================================
    // Dat cho FIFO cho cac burst DA PHAT nhung chua ve.
    // Giu nguyen co che cua v1: neu khong, rd_dat_ready ha giua
    // burst va DMA ep nguoc RREADY len slave — chan moi master khac
    // doc cung slave (dieu kien 3 o dsp_read_channel).
    // =========================================================
    reg [INFL_W-1:0] rd_inflight;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_inflight <= {INFL_W{1'b0}};
        else if (state == ST_IDLE)
            rd_inflight <= {INFL_W{1'b0}};
        else
            rd_inflight <= rd_inflight
                + (rd_cmd_fire ? {{(INFL_W-BEATS_W){1'b0}}, rd_beats}
                               : {INFL_W{1'b0}})
                - {{(INFL_W-1){1'b0}},
                   (fifo_wr_en & (rd_inflight != {INFL_W{1'b0}}))};
    end

    wire [INFL_W-1:0] fifo_free =
        FIFO_DEPTH[INFL_W-1:0] - {{(INFL_W-FIFO_CNT_W){1'b0}}, fifo_count};
    wire fifo_has_room =
        (fifo_free >= (rd_inflight + {{(INFL_W-BEATS_W){1'b0}}, rd_beats}));

    // =========================================================
    // Bo dong goi byte
    // =========================================================
    wire       al_push_ready;
    wire       al_pop_valid;
    reg        wr_dat_active;

    // O IDLE phai XA HET FIFO. sync_ff khong co cong flush (them
    // vao se phai sua ca 5 cho instantiate, ke ca code cu trong
    // dma_core.v / dma_axi_master.v), nen xa bang chinh duong
    // rd_en. dma_align dang bi flush o trang thai nay nen word
    // lay ra bi bo di, dung nhu mong muon.
    // Khong co no: rac con lai sau mot lan abort lam lan chuyen
    // ke tiep vua sai du lieu vua khong thoat duoc ST_DRAIN, vi
    // dieu kien thoat doi fifo_empty.
    assign fifo_rd_en = ~fifo_empty & (al_push_ready | (state == ST_IDLE));

    wire [1:0] tx_lane = c_dst_incr ? (tx_first ? w_dst[1:0] : 2'b00)
                                    : w_dst[1:0];
    wire [2:0] tx_room = c_dst_incr ? (3'd4 - {1'b0, tx_lane}) : dst_bytes;
    assign     tx_cnt  = (tx_remain < {{(LEN_FIELD_W-3){1'b0}}, tx_room})
                         ? tx_remain[2:0] : tx_room;

    dma_align #(.DEPTH_BYTES(8)) u_align (
        .clk        (clk),
        .rst_n      (rst_n),
        .flush      (state == ST_IDLE),
        .push_valid (~fifo_empty),
        .push_ready (al_push_ready),
        .push_data  (fifo_rdata[`AXI_DATA_W-1:0]),
        .push_lane  (fifo_rdata[`AXI_DATA_W+1 : `AXI_DATA_W]),
        .push_cnt   (fifo_rdata[`AXI_DATA_W+4 : `AXI_DATA_W+2]),
        .pop_valid  (al_pop_valid),
        .pop_ready  (wr_dat_ready & wr_dat_active),
        .pop_lane   (tx_lane),
        .pop_cnt    (tx_cnt),
        .pop_data   (wr_dat_data),
        .pop_strb   (wr_dat_strb),
        .level      (al_level)
    );

    // =========================================================
    // So byte payload DA VE ma chua lenh ghi nao dat cho.
    // Dieu kien phat AW: du byte cho CA burst. Phai dem o day thay
    // vi nhin fifo_count, vi word dau tien co the chua byte dem.
    // =========================================================
    reg [LEN_FIELD_W-1:0] avail;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            avail <= {LEN_FIELD_W{1'b0}};
        else if (state == ST_IDLE)
            avail <= {LEN_FIELD_W{1'b0}};
        else
            avail <= avail
                   + (fifo_wr_en  ? {{(LEN_FIELD_W-3){1'b0}}, rx_cnt}
                                  : {LEN_FIELD_W{1'b0}})
                   - (wr_cmd_fire ? wr_payload : {LEN_FIELD_W{1'b0}});
    end

    wire wr_has_data = (avail >= wr_payload);

    // =========================================================
    // Loi
    // =========================================================
    assign rd_rsp_error = rd_rsp_valid & (rd_rsp_err != `AXI_RESP_OKAY);
    assign wr_rsp_error = wr_rsp_valid & (wr_rsp_err != `AXI_RESP_OKAY);
    assign timeout_seen = timeout_rd | timeout_wr_aw | timeout_wr_w;
    assign viol_seen    = rd_viol | wr_viol;

    // Sau DMA v2 chi con mot truong hop that su vo nghia.
    wire cfg_bad = (w_len == {LEN_FIELD_W{1'b0}});

    // =========================================================
    // Giai ma descriptor
    // =========================================================
    reg              desc_req_r;
    reg [ADDR_W-1:0] desc_ptr_r;

    assign desc_req  = desc_req_r;
    assign desc_addr = desc_ptr_r;

    wire [31:0] d_src     = desc_data[32*`DESC_W_SRC     +: 32];
    wire [31:0] d_dst     = desc_data[32*`DESC_W_DST     +: 32];
    wire [31:0] d_len     = desc_data[32*`DESC_W_LEN     +: 32];
    wire [31:0] d_ctrl    = desc_data[32*`DESC_W_CTRL    +: 32];
    wire [31:0] d_next    = desc_data[32*`DESC_W_NEXT    +: 32];
    wire [31:0] d_sstride = desc_data[32*`DESC_W_SSTRIDE +: 32];
    wire [31:0] d_dstride = desc_data[32*`DESC_W_DSTRIDE +: 32];
    wire [31:0] d_nlines  = desc_data[32*`DESC_W_NLINES  +: 32];

    // NEXT_PTR phai can 32 byte, neu khong chuoi hong.
    wire desc_next_bad = (d_next != 32'h0) & (|d_next[4:0]);
    wire desc_bad      = desc_fail | desc_next_bad | (d_len == 32'h0);

    wire [15:0] d_nl_eff = (!d_ctrl[`CTRL_TWO_D]) ? 16'd1 :
                           (d_nlines[15:0] == 16'd0) ? 16'd1 : d_nlines[15:0];
    wire [15:0] c_nl_eff = (!cfg_ctrl[`CTRL_TWO_D]) ? 16'd1 :
                           (cfg_num_lines == 16'd0) ? 16'd1 : cfg_num_lines;

    // =========================================================
    // May trang thai chinh
    // =========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            err          <= `DMA_ERR_NONE;
            err_addr     <= {ADDR_W{1'b0}};
            abort_lat    <= 1'b0;
            chain_r      <= 1'b0;
            desc_req_r   <= 1'b0;
            desc_ptr_r   <= {ADDR_W{1'b0}};
            w_src        <= {ADDR_W{1'b0}};
            w_dst        <= {ADDR_W{1'b0}};
            w_len        <= {LEN_FIELD_W{1'b0}};
            w_ctrl       <= 32'h0;
            w_next       <= {ADDR_W{1'b0}};
            w_sstride    <= 32'h0;
            w_dstride    <= 32'h0;
            w_nlines     <= 16'd1;
            rd_addr      <= {ADDR_W{1'b0}};
            wr_addr      <= {ADDR_W{1'b0}};
            rd_remain    <= {LEN_FIELD_W{1'b0}};
            wr_remain    <= {LEN_FIELD_W{1'b0}};
            tx_remain    <= {LEN_FIELD_W{1'b0}};
            rd_line_base <= {ADDR_W{1'b0}};
            wr_line_base <= {ADDR_W{1'b0}};
            rd_line      <= 16'd1;
            wr_line      <= 16'd1;
            done_bytes   <= {LEN_FIELD_W{1'b0}};
            half_done_r  <= 1'b0;
            tx_first     <= 1'b1;
            start_line_load <= 1'b0;
            half_pulse   <= 1'b0;
            chain_pulse  <= 1'b0;
        end else begin
            start_line_load <= 1'b0;
            half_pulse      <= 1'b0;
            chain_pulse     <= 1'b0;

            case (state)

            // -------------------------------------------------
            ST_IDLE: begin
                abort_lat  <= 1'b0;
                desc_req_r <= 1'b0;
                if (start_go) begin
                    err         <= `DMA_ERR_NONE;
                    err_addr    <= {ADDR_W{1'b0}};
                    done_bytes  <= {LEN_FIELD_W{1'b0}};
                    half_done_r <= 1'b0;
                    w_ctrl      <= cfg_ctrl;
                    if (cfg_ctrl[`CTRL_SG_EN] &&
                        (cfg_desc_ptr != {ADDR_W{1'b0}})) begin
                        chain_r    <= 1'b1;
                        desc_ptr_r <= cfg_desc_ptr;
                        desc_req_r <= 1'b1;
                        state      <= ST_FETCH;
                    end else if (cfg_len == {LEN_FIELD_W{1'b0}}) begin
                        chain_r <= 1'b0;
                        w_len   <= {LEN_FIELD_W{1'b0}};
                        state   <= ST_DONE;
                    end else begin
                        chain_r      <= 1'b0;
                        w_src        <= cfg_src_addr;
                        w_dst        <= cfg_dst_addr;
                        w_len        <= cfg_len;
                        w_next       <= {ADDR_W{1'b0}};
                        w_sstride    <= cfg_src_stride;
                        w_dstride    <= cfg_dst_stride;
                        w_nlines     <= c_nl_eff;
                        rd_addr      <= cfg_src_addr;
                        wr_addr      <= cfg_dst_addr;
                        rd_line_base <= cfg_src_addr;
                        wr_line_base <= cfg_dst_addr;
                        rd_remain    <= cfg_len;
                        wr_remain    <= cfg_len;
                        tx_remain    <= cfg_len;
                        tx_first     <= 1'b1;
                        rd_line      <= c_nl_eff;
                        wr_line      <= c_nl_eff;
                        start_line_load <= 1'b1;
                        state        <= ST_RUN;
                    end
                end
            end

            // -------------------------------------------------
            ST_FETCH: begin
                if (abort_req) begin
                    abort_lat  <= 1'b1;
                    desc_req_r <= 1'b0;
                    err        <= `DMA_ERR_ABORT;
                    state      <= ST_DONE;
                end else if (desc_ack) begin
                    desc_req_r <= 1'b0;
                    if (desc_bad) begin
                        err      <= `DMA_ERR_DESC;
                        err_addr <= desc_ptr_r;
                        state    <= ST_DONE;
                    end else begin
                        w_src        <= d_src;
                        w_dst        <= d_dst;
                        w_len        <= d_len;
                        w_ctrl       <= d_ctrl;
                        w_next       <= d_next;
                        w_sstride    <= d_sstride;
                        w_dstride    <= d_dstride;
                        w_nlines     <= d_nl_eff;
                        rd_addr      <= d_src;
                        wr_addr      <= d_dst;
                        rd_line_base <= d_src;
                        wr_line_base <= d_dst;
                        rd_remain    <= d_len;
                        wr_remain    <= d_len;
                        tx_remain    <= d_len;
                        tx_first     <= 1'b1;
                        rd_line      <= d_nl_eff;
                        wr_line      <= d_nl_eff;
                        start_line_load <= 1'b1;
                        state        <= ST_RUN;
                    end
                end
            end

            // -------------------------------------------------
            ST_RUN: begin
                //  Phat lenh doc.
                //  rd_addr tien DUNG rd_payload byte: phan dem dan
                //  dau (lan) da nam trong word dau, khong cong them.
                if (rd_cmd_fire) begin
                    if ((rd_remain == rd_payload) && (rd_line > 16'd1)) begin
                        rd_line      <= rd_line - 16'd1;
                        rd_line_base <= rd_line_base + w_sstride;
                        rd_addr      <= rd_line_base + w_sstride;
                        rd_remain    <= w_len;
                    end else begin
                        if (c_src_incr)
                            rd_addr <= rd_addr + rd_payload;
                        rd_remain <= rd_remain - rd_payload;
                    end
                end

                //  Phat lenh ghi
                if (wr_cmd_fire) begin
                    if ((wr_remain == wr_payload) && (wr_line > 16'd1)) begin
                        wr_line      <= wr_line - 16'd1;
                        wr_line_base <= wr_line_base + w_dstride;
                        wr_addr      <= wr_line_base + w_dstride;
                        wr_remain    <= w_len;
                    end else begin
                        if (c_dst_incr)
                            wr_addr <= wr_addr + wr_payload;
                        wr_remain <= wr_remain - wr_payload;
                    end
                end

                //  Tien do, theo beat ghi DA GUI
                if (wr_dat_beat) begin
                    done_bytes <= done_bytes + {{(LEN_FIELD_W-3){1'b0}}, tx_cnt};
                    if (tx_remain == {{(LEN_FIELD_W-3){1'b0}}, tx_cnt}) begin
                        tx_remain <= w_len;      // dong 2D ke tiep
                        tx_first  <= 1'b1;
                    end else begin
                        tx_remain <= tx_remain - {{(LEN_FIELD_W-3){1'b0}}, tx_cnt};
                        tx_first  <= 1'b0;
                    end
                    // Moc HALF lay theo LEN cua descriptor hien tai —
                    // xem ghi chu (b) o dau file.
                    if (!half_done_r &&
                        ((done_bytes + {{(LEN_FIELD_W-3){1'b0}}, tx_cnt})
                          >= (w_len >> 1))) begin
                        half_done_r <= 1'b1;
                        half_pulse  <= 1'b1;
                    end
                end

                //  Thu thap loi
                if (rd_rsp_error) begin
                    err      <= (rd_rsp_err == `AXI_RESP_SLVERR) ?
                                `DMA_ERR_SLVERR : `DMA_ERR_DECERR;
                    err_addr <= rd_addr;
                end
                if (wr_rsp_error) begin
                    err      <= (wr_rsp_err == `AXI_RESP_SLVERR) ?
                                `DMA_ERR_SLVERR : `DMA_ERR_DECERR;
                    err_addr <= wr_addr;
                end
                if (rd_viol) begin
                    err      <= `DMA_ERR_ACCESS;
                    err_addr <= rd_addr;
                end
                if (wr_viol) begin
                    err      <= `DMA_ERR_ACCESS;
                    err_addr <= wr_addr;
                end
                if (timeout_seen)
                    err <= `DMA_ERR_TIMEOUT;

                //  Chuyen trang thai
                if (abort_req) begin
                    abort_lat <= 1'b1;
                    err       <= `DMA_ERR_ABORT;
                    state     <= ST_DRAIN;
                end else if (timeout_seen) begin
                    state <= ST_DONE;
                end else if (viol_seen | rd_rsp_error | wr_rsp_error) begin
                    state <= ST_DRAIN;
                end else if (rd_line <= 16'd1) begin
                    if ((rd_remain == {LEN_FIELD_W{1'b0}} && !rd_cmd_fire) ||
                        (rd_cmd_fire && (rd_remain == rd_payload)))
                        state <= ST_DRAIN;
                end
            end

            // -------------------------------------------------
            ST_DRAIN: begin
                if (wr_cmd_fire) begin
                    if ((wr_remain == wr_payload) && (wr_line > 16'd1)) begin
                        wr_line      <= wr_line - 16'd1;
                        wr_line_base <= wr_line_base + w_dstride;
                        wr_addr      <= wr_line_base + w_dstride;
                        wr_remain    <= w_len;
                    end else begin
                        if (c_dst_incr)
                            wr_addr <= wr_addr + wr_payload;
                        wr_remain <= wr_remain - wr_payload;
                    end
                end

                if (wr_dat_beat) begin
                    done_bytes <= done_bytes + {{(LEN_FIELD_W-3){1'b0}}, tx_cnt};
                    if (tx_remain == {{(LEN_FIELD_W-3){1'b0}}, tx_cnt}) begin
                        tx_remain <= w_len;
                        tx_first  <= 1'b1;
                    end else begin
                        tx_remain <= tx_remain - {{(LEN_FIELD_W-3){1'b0}}, tx_cnt};
                        tx_first  <= 1'b0;
                    end
                end

                if (rd_rsp_error) begin
                    err      <= (rd_rsp_err == `AXI_RESP_SLVERR) ?
                                `DMA_ERR_SLVERR : `DMA_ERR_DECERR;
                    err_addr <= rd_addr;
                end
                if (wr_rsp_error) begin
                    err      <= (wr_rsp_err == `AXI_RESP_SLVERR) ?
                                `DMA_ERR_SLVERR : `DMA_ERR_DECERR;
                    err_addr <= wr_addr;
                end
                if (timeout_seen)
                    err <= `DMA_ERR_TIMEOUT;

                if (abort_req)
                    abort_lat <= 1'b1;

                // Huy: CHI ve DONE khi moi lenh dang bay DA quay ve.
                // Reset thang se de lai response mo coi tren bus.
                if (abort_lat) begin
                    if ((rd_outs == {OUT_W{1'b0}}) && (wr_outs == {OUT_W{1'b0}}))
                        state <= ST_DONE;
                end else if (timeout_seen) begin
                    state <= ST_DONE;
                end else if (err != `DMA_ERR_NONE) begin
                    // Loi bus / IOPMP: so byte con thieu se KHONG
                    // bao gio ve nua, nen khong duoc cho
                    // wr_remain == 0 nhu duong binh thuong — cho
                    // the la treo cung, ACTIVE ket o 1 vinh vien.
                    // Van doi lenh dang bay quay ve, giong abort.
                    if ((rd_outs == {OUT_W{1'b0}}) &&
                        (wr_outs == {OUT_W{1'b0}}))
                        state <= ST_DONE;
                end else if (fifo_empty && (al_level == 5'd0) &&
                             (rd_outs == {OUT_W{1'b0}}) &&
                             (wr_outs == {OUT_W{1'b0}}) &&
                             (wr_remain == {LEN_FIELD_W{1'b0}}) &&
                             (wr_line <= 16'd1)) begin
                    state <= ST_DONE;
                end
            end

            // -------------------------------------------------
            ST_DONE: begin
                if (err != `DMA_ERR_NONE) begin
                    chain_r <= 1'b0;
                    state   <= ST_IDLE;
                end else if (chain_r && (w_next != {ADDR_W{1'b0}})) begin
                    chain_pulse <= 1'b1;
                    desc_ptr_r  <= w_next;
                    desc_req_r  <= 1'b1;
                    state       <= ST_FETCH;
                end else if (c_circ) begin
                    rd_addr      <= w_src;
                    wr_addr      <= w_dst;
                    rd_line_base <= w_src;
                    wr_line_base <= w_dst;
                    rd_remain    <= w_len;
                    wr_remain    <= w_len;
                    tx_remain    <= w_len;
                    tx_first     <= 1'b1;
                    rd_line      <= w_nlines;
                    wr_line      <= w_nlines;
                    done_bytes   <= {LEN_FIELD_W{1'b0}};
                    half_done_r  <= 1'b0;
                    start_line_load <= 1'b1;
                    state        <= ST_RUN;
                end else if (c_reload && (cfg_sh_len != {LEN_FIELD_W{1'b0}})) begin
                    w_src        <= cfg_sh_src;
                    w_dst        <= cfg_sh_dst;
                    w_len        <= cfg_sh_len;
                    w_ctrl       <= cfg_sh_ctrl;
                    w_nlines     <= 16'd1;
                    rd_addr      <= cfg_sh_src;
                    wr_addr      <= cfg_sh_dst;
                    rd_line_base <= cfg_sh_src;
                    wr_line_base <= cfg_sh_dst;
                    rd_remain    <= cfg_sh_len;
                    wr_remain    <= cfg_sh_len;
                    tx_remain    <= cfg_sh_len;
                    tx_first     <= 1'b1;
                    rd_line      <= 16'd1;
                    wr_line      <= 16'd1;
                    done_bytes   <= {LEN_FIELD_W{1'b0}};
                    half_done_r  <= 1'b0;
                    start_line_load <= 1'b1;
                    state        <= ST_RUN;
                end else begin
                    chain_r <= 1'b0;
                    state   <= ST_IDLE;
                end
            end

            default: state <= ST_IDLE;
            endcase
        end
    end

    // =========================================================
    // Sinh lenh doc
    // =========================================================
    reg [SEQ_W-1:0] rd_id_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                 rd_id_cnt <= {SEQ_W{1'b0}};
        else if (state == ST_IDLE)  rd_id_cnt <= {SEQ_W{1'b0}};
        else if (rd_cmd_fire)       rd_id_cnt <= rd_id_cnt + 1'b1;
    end

    assign rd_cmd_valid = (state == ST_RUN) &
                          (rd_remain != {LEN_FIELD_W{1'b0}}) &
                          ~cfg_bad      &
                          ~abort_req    &
                          ~suspend_req  &
                          ~rd_stall     &
                          fifo_has_room &
                          token_ok      &
                          periph_rdy;

    // INCR doc tu bien word chua dia chi; FIXED giu nguyen dia chi.
    assign rd_cmd_addr  = c_src_incr ? {rd_addr[ADDR_W-1:2], 2'b00} : rd_addr;
    assign rd_cmd_len   = rd_beats[LEN_W-1:0] - 1'b1;
    assign rd_cmd_size  = src_size;
    assign rd_cmd_burst = c_src_incr ? `AXI_BURST_INCR : `AXI_BURST_FIXED;
    assign rd_cmd_id    = {CH_IDX[N_CH_W-1:0], rd_id_cnt};

    // =========================================================
    // Sinh lenh ghi
    // =========================================================
    reg [SEQ_W-1:0] wr_id_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                 wr_id_cnt <= {SEQ_W{1'b0}};
        else if (state == ST_IDLE)  wr_id_cnt <= {SEQ_W{1'b0}};
        else if (wr_cmd_fire)       wr_id_cnt <= wr_id_cnt + 1'b1;
    end

    assign wr_cmd_valid = ((state == ST_RUN) | (state == ST_DRAIN)) &
                          (wr_remain != {LEN_FIELD_W{1'b0}}) &
                          ~cfg_bad     &
                          ~abort_req   &
                          ~suspend_req &
                          ~wr_stall    &
                          wr_has_data;

    assign wr_cmd_addr  = c_dst_incr ? {wr_addr[ADDR_W-1:2], 2'b00} : wr_addr;
    assign wr_cmd_len   = wr_beats[LEN_W-1:0] - 1'b1;
    assign wr_cmd_size  = dst_size;
    assign wr_cmd_burst = c_dst_incr ? `AXI_BURST_INCR : `AXI_BURST_FIXED;
    assign wr_cmd_id    = {CH_IDX[N_CH_W-1:0], wr_id_cnt};

    // =========================================================
    // Duong du lieu ghi — dem beat trong burst
    // =========================================================
    reg [LEN_W-1:0] wr_beat_cnt;

    assign wr_dat_beat = wr_dat_valid & wr_dat_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_dat_active <= 1'b0;
            wr_beat_cnt   <= {LEN_W{1'b0}};
        end else if (state == ST_IDLE) begin
            wr_dat_active <= 1'b0;
            wr_beat_cnt   <= {LEN_W{1'b0}};
        end else begin
            if (~wr_dat_active & wr_cmd_fire) begin
                wr_dat_active <= 1'b1;
                wr_beat_cnt   <= wr_beats[LEN_W-1:0] - 1'b1;
            end else if (wr_dat_active & wr_dat_beat) begin
                if (wr_beat_cnt == {LEN_W{1'b0}}) begin
                    if (wr_cmd_fire) begin
                        wr_dat_active <= 1'b1;
                        wr_beat_cnt   <= wr_beats[LEN_W-1:0] - 1'b1;
                    end else begin
                        wr_dat_active <= 1'b0;
                    end
                end else begin
                    wr_beat_cnt <= wr_beat_cnt - 1'b1;
                end
            end
        end
    end

    assign wr_dat_valid = wr_dat_active & al_pop_valid;

endmodule
