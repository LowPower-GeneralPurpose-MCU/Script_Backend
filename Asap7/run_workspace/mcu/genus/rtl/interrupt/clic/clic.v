`timescale 1ns / 1ps

// =============================================================================
// CLIC - Core-Local Interrupt Controller (theo Smclic), thay PLIC (2026-09-11).
//
// VI SAO BO PLIC
//   PLIC dua moi ngat ngoai vao MOT duong meip. ISR phai doc thanh ghi claim de
//   biet nguon nao: mot lenh load uncached D-cache -> AXI -> cau APB -> PLIC va
//   quay ve, ~15-20 chu ky moi lan ngat, cong them complete o cuoi. Khong co
//   vector theo nguon, khong co long nhau phan cung. 4 kenh DMA con bi OR thanh
//   mot nguon.
//
//   CLIC dua THANG {valid, id, level, shv} vao core. Core nhay vao vector cua
//   dung nguon do, mcause.exccode = id - khong can claim, khong can complete.
//   Ngat kich canh tu xoa pending khi core nhan (irq_ack). Muc (level) cho
//   phep ngat cao preempt ISR thap (mil / mintthresh trong core).
//
// BAN DO THANH GHI (APB slave S8, base 0x4400_0000; offset trong 8 KB dau)
//   0x0000 cliccfg   RO  [4:1] nlbits = 8: moi bit clicintctl deu la bit MUC
//                        (khong co truong uu tien rieng)
//   0x0004 clicinfo  RO  [12:0] so ngat = 32, [20:13] version = 0x01,
//                        [24:21] CLICINTCTLBITS = 3
//   0x1000 + 4*i     clicint[i], i = 0..31, truy cap duoc tung byte (pstrb):
//      byte 0 clicintip   [0]   pending. Ngat MUC: chi doc, bang muc chan hien
//                                tai. Ngat CANH: ghi 1 = kich bang phan mem,
//                                ghi 0 = xoa; tu xoa khi core nhan ngat.
//      byte 1 clicintie   [0]   enable
//      byte 2 clicintattr [0]   shv: 1 = nhay vao vector rieng (mtvec+4*id)
//                         [2:1] trig: 00 muc cao, 01 canh len,
//                                     10 muc thap, 11 canh xuong
//                         [7:6] mode = 11 (M, chi doc)
//      byte 3 clicintctl  [7:5] muc (8 muc); [4:0] doc ra 1. Muc 8 bit gui cho
//                                core = {ctl[7:5], 5'b11111} (Smclic).
//   Moi offset con lai trong cua so 64 MB cua S8 doc ra 0, ghi bi bo qua, KHONG
//   PSLVERR (dac ta goi la reserved). Nho vay lenh ghi PLIC cua firmware cu
//   (threshold 0x4420_0000, priority, enable) vo hai: che do CLINT khong co
//   ngat ngoai nao nen firmware cu van chay, chi mat ngat ngoai.
//
// PHAN XU
//   Trong cac nguon (pending & enable), MUC cao nhat thang; bang muc thi ID
//   LON hon thang (Smclic). Khoa {level[2:0], id[4:0]} la duy nhat, nen chi can
//   lay MAX cua 32 khoa 8 bit - cay 5 tang. ID 0 khong bao gio duoc chon: vector
//   0 trung voi loi vao ngoai le (BASE). Ket qua duoc CHOT truoc khi vao core:
//   cay so sanh khong nam tren duong trap/commit_kill/D-cache cua core.
//
// BANG ID (top_soc.v)
//   3 msip   7 mtip   16 UART0  17 UART1  18 GPIO  19 SPI  20 I2C  21 WDT
//   22-25 DMA kenh 0-3 (TACH rieng, truoc day OR chung)
//   26 loi bus cua store buffer D-cache (xung 256 chu ky -> mac dinh CANH LEN)
//   27 ASCON  28 TIM0  29 TIM1
// =============================================================================
module clic #(
    parameter integer NUM_IRQ = 32,          // co dinh: id 5 bit trong core
    parameter integer CTLBITS = 3,
    // Nguon mac dinh kich canh len sau reset (bit i = nguon i).
    parameter [31:0]  TRIG_EDGE_RST = 32'h0400_0000
)(
    input  wire        clk,
    input  wire        rst_n,

    // --- APB slave ---
    input  wire [25:0] paddr,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    input  wire [3:0]  pstrb,
    output reg         pready,
    output reg  [31:0] prdata,
    output reg         pslverr,

    // --- Nguon ngat (dong bo voi clk) ---
    input  wire [NUM_IRQ-1:0] irq_src,

    // --- Toi core ---
    output reg         irq_valid,
    output reg  [4:0]  irq_id,
    output reg  [7:0]  irq_level,
    output reg         irq_shv,
    input  wire        irq_ack,
    input  wire [4:0]  irq_ack_id
);

    reg [NUM_IRQ-1:0]  ip_edge_q;   // pending cua nguon kich canh
    reg [NUM_IRQ-1:0]  ie_q;
    reg [NUM_IRQ-1:0]  shv_q;
    reg [1:0]          trig_q [0:NUM_IRQ-1];
    reg [CTLBITS-1:0]  lvl_q  [0:NUM_IRQ-1];
    reg [NUM_IRQ-1:0]  src_d;       // muc da chuan hoa cuc cua chu ky truoc

    wire apb_wr = psel & penable &  pwrite;
    wire apb_rd = psel & penable & ~pwrite;

    // Cua so thanh ghi: 8 KB dau cua S8. Ngoai do la reserved.
    wire        in_win   = (paddr[25:13] == 13'd0);
    wire        is_int   = in_win & (paddr[12] == 1'b1) & (paddr[11:7] == 5'd0);
    wire [4:0]  int_idx  = paddr[6:2];

    // -------------------------------------------------------------------------
    // Pending
    // -------------------------------------------------------------------------
    wire [NUM_IRQ-1:0] trig_edge, trig_neg;
    genvar g;
    generate
        for (g = 0; g < NUM_IRQ; g = g + 1) begin : g_trig
            assign trig_edge[g] = trig_q[g][0];
            assign trig_neg[g]  = trig_q[g][1];
        end
    endgenerate

    wire [NUM_IRQ-1:0] src_n     = irq_src ^ trig_neg;          // 1 = tich cuc
    wire [NUM_IRQ-1:0] edge_seen = src_n & ~src_d & trig_edge;
    // Ngat canh: pending la flop. Ngat muc: pending la chinh muc chan.
    wire [NUM_IRQ-1:0] ip_vec    = (trig_edge & ip_edge_q) | (~trig_edge & src_n);
    wire [NUM_IRQ-1:0] eligible  = ip_vec & ie_q & {{(NUM_IRQ-1){1'b1}}, 1'b0};

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_d     <= {NUM_IRQ{1'b0}};
            ip_edge_q <= {NUM_IRQ{1'b0}};
            ie_q      <= {NUM_IRQ{1'b0}};
            shv_q     <= {NUM_IRQ{1'b0}};
            for (i = 0; i < NUM_IRQ; i = i + 1) begin
                trig_q[i] <= {1'b0, TRIG_EDGE_RST[i]};
                lvl_q[i]  <= {CTLBITS{1'b0}};
            end
        end else begin
            src_d <= src_n;

            for (i = 0; i < NUM_IRQ; i = i + 1) begin
                // Xoa (ack cua core / phan mem ghi 0) truoc, dat (canh moi /
                // phan mem ghi 1) sau: canh toi dung chu ky ack KHONG bi mat.
                if (irq_ack && (irq_ack_id == i))
                    ip_edge_q[i] <= 1'b0;
                if (apb_wr && is_int && (int_idx == i) && pstrb[0] && trig_edge[i])
                    ip_edge_q[i] <= pwdata[0];
                if (edge_seen[i])
                    ip_edge_q[i] <= 1'b1;
            end

            if (apb_wr && is_int) begin
                if (pstrb[1]) ie_q[int_idx] <= pwdata[8];
                if (pstrb[2]) begin
                    shv_q[int_idx]  <= pwdata[16];
                    trig_q[int_idx] <= pwdata[18:17];
                end
                if (pstrb[3]) lvl_q[int_idx] <= pwdata[31:32-CTLBITS];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Phan xu: max cua khoa {level, id}.
    // -------------------------------------------------------------------------
    reg [7:0] best_key;
    reg [7:0] key;
    integer k;
    always @(*) begin
        best_key = 8'd0;
        for (k = 0; k < NUM_IRQ; k = k + 1) begin
            key = eligible[k] ? {lvl_q[k], k[4:0]} : 8'd0;
            if (key > best_key)
                best_key = key;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_valid <= 1'b0;
            irq_id    <= 5'd0;
            irq_level <= 8'd0;
            irq_shv   <= 1'b0;
        end else begin
            // Chu ky ngay sau ack, pending cua ngat canh vua xoa chua kip di qua
            // cay: ep valid = 0 mot chu ky de core khong thay lai ngat cu. (Core
            // cung da ha MIE o chinh chu ky ack, day chi la phong ho.)
            irq_valid <= (best_key != 8'd0) & ~irq_ack;
            irq_id    <= best_key[4:0];
            irq_level <= {best_key[7:5], 5'b11111};
            irq_shv   <= shv_q[best_key[4:0]];
        end
    end

    // -------------------------------------------------------------------------
    // APB
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pready  <= 1'b0;
            prdata  <= 32'd0;
            pslverr <= 1'b0;
        end else begin
            pready  <= psel & penable;
            pslverr <= 1'b0;
            if (apb_rd) begin
                if (in_win && paddr[12:0] == 13'h0000)
                    prdata <= {27'd0, 4'd8, 1'b0};                       // cliccfg
                else if (in_win && paddr[12:0] == 13'h0004)
                    prdata <= {7'd0, 4'd3, 8'h01, 13'd32};               // clicinfo
                else if (is_int)
                    prdata <= {lvl_q[int_idx], 5'b11111,
                               2'b11, 3'b000, trig_q[int_idx], shv_q[int_idx],
                               7'd0, ie_q[int_idx],
                               7'd0, ip_vec[int_idx]};
                else
                    prdata <= 32'd0;                                    // reserved
            end
        end
    end

endmodule
