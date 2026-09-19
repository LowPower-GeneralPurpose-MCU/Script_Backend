`timescale 1ns / 1ps
`include "dma_defines.vh"

// ============================================================
// dma_iopmp.v — Kiem tra dia chi/quyen tren duong AXI cua DMA
// Layer : Reusable IP (noi bo dma_engine)
//
// Vi sao can module nay
// ---------------------
// Truoc DMA v2, DMA bo qua hoan toan PMP cua CPU: AWPROT/ARPROT
// tied 0 (top_soc.v:1705) va khong co bo kiem tra nao tren duong
// master. Mot kenh cau hinh sai — hoac phan mem bi chiem quyen —
// ghi de duoc moi noi, ke ca vung PMP dang bao ve.
//
// Chinh sach
// ----------
// - Neu KHONG vung nao bat (EN=0 het): cho qua tat ca. Day la
//   trang thai sau reset, giu tuong thich voi firmware va
//   testbench co san. Giong PMP cua RISC-V: khong entry nao khop
//   thi M-mode duoc phep.
// - Neu CO it nhat mot vung bat: chi cho qua khi mot vung dang
//   bat, dung kenh (CH_MASK), phu ca dia chi DAU va CUOI cua
//   burst, va cap dung quyen R/W.
//
// Kiem ca dia chi CUOI burst la bat buoc: neu chi kiem dia chi
// dau thi mot burst co the bat dau trong vung hop le roi ket thuc
// ben ngoai no.
//
// Do chi tiet 16 byte (BASE[31:4], LIMIT[31:4]).
//
// Bo nho cau hinh (2 word moi vung)
//   word0 = {BASE[31:4],  CH_MASK[3:0]}
//   word1 = {LIMIT[31:4], 1'b0, EN, PERM_W, PERM_R}
//
// LOCK nam o thanh ghi rieng (REG_IOPMP_LOCK), dinh toi khi hard
// reset — soft-reset toan cuc KHONG xoa duoc.
//
// Timing: ket qua duoc dang ky o dma_engine truoc khi vao arbiter,
// khong de to hop thang ra AR/AW. Bien SS cua chip chi khoang
// 100 ps o 4 ns nen khong duoc noi them chuoi so sanh vao do.
// ============================================================

module dma_iopmp #(
    parameter ADDR_W = 32,
    parameter N_CH   = 4,
    parameter N_RGN  = `DMA_IOPMP_N
) (
    //  Cau hinh (tu dma_regfile, on dinh khi dang kiem tra)
    input  wire [N_RGN*32-1:0] cfg_word0,
    input  wire [N_RGN*32-1:0] cfg_word1,

    //  Yeu cau kiem tra — to hop thuan
    input  wire [ADDR_W-1:0]   req_addr,     // dia chi dau burst
    input  wire [12:0]         req_bytes,    // so byte cua burst (>=1)
    input  wire                req_is_wr,    // 1 = ghi, 0 = doc
    input  wire [N_CH-1:0]     req_ch_oh,    // kenh yeu cau, one-hot

    //  Ket qua
    output wire                allow         // 1 = cho phep phat lenh
);

    //  Dia chi cuoi cung ma burst cham toi
    wire [ADDR_W-1:0] req_last =
        req_addr + {{(ADDR_W-13){1'b0}}, req_bytes} - {{(ADDR_W-1){1'b0}}, 1'b1};

    wire [ADDR_W-5:0] first_gr = req_addr[ADDR_W-1:4];
    wire [ADDR_W-5:0] last_gr  = req_last[ADDR_W-1:4];

    wire [N_RGN-1:0] rgn_en;
    wire [N_RGN-1:0] rgn_hit;

    genvar r;
    generate
        for (r = 0; r < N_RGN; r = r + 1) begin : gen_rgn
            wire [31:0] w0 = cfg_word0[r*32 +: 32];
            wire [31:0] w1 = cfg_word1[r*32 +: 32];

            wire [27:0] base_gr  = w0[31:4];
            wire [3:0]  ch_mask  = w0[3:0];
            wire [27:0] limit_gr = w1[31:4];
            wire        en       = w1[2];
            wire        perm_w   = w1[1];
            wire        perm_r   = w1[0];

            // Kenh nay co duoc vung nay phuc vu khong
            wire ch_ok = |(req_ch_oh & ch_mask[N_CH-1:0]);

            // Phu CA dia chi dau VA dia chi cuoi
            wire covers = (first_gr >= base_gr) & (first_gr <= limit_gr) &
                          (last_gr  >= base_gr) & (last_gr  <= limit_gr);

            wire perm_ok = req_is_wr ? perm_w : perm_r;

            assign rgn_en[r]  = en;
            assign rgn_hit[r] = en & ch_ok & covers & perm_ok;
        end
    endgenerate

    // Khong vung nao bat -> cho qua (trang thai sau reset).
    assign allow = (~|rgn_en) | (|rgn_hit);

endmodule
