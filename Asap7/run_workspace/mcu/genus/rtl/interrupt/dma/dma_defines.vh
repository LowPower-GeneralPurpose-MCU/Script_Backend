// ============================================================
// dma_defines.vh
// File `define toan cuc — include mot lan o dau moi file .v
//
//   `include "dma_defines.vh"
//
// DMA v2 (2026-09-19): them scatter-gather, IOPMP, can byte,
// doi do rong, clock gating. Xem docs/superpowers/specs/
// 2026-09-18-dma-v2-design.md
// ============================================================
`ifndef DMA_DEFINES_VH
`define DMA_DEFINES_VH

// ------------------------------------------------------------
// AXI4 bus (fixed 32-bit data width theo yeu cau)
// ------------------------------------------------------------
`define AXI_DATA_W   32          // data width — co dinh cho thu vien nay
`define AXI_STRB_W   4           // = AXI_DATA_W/8
`define AXI_BYTES    4           // so byte moi beat = AXI_DATA_W/8

// AXI ARSIZE/AWSIZE encoding cho 32-bit bus
`define AXI_SIZE_1B  3'b000
`define AXI_SIZE_2B  3'b001
`define AXI_SIZE_4B  3'b010      // default cho 32-bit bus

// AXI AxBURST encoding
//   FIXED dung cho FIFO ngoai vi: moi beat cung dia chi.
//   Truoc DMA v2 ca hai duong deu tied INCR, nen doc FIFO ngoai vi
//   voi ARLEN>0 bi slave tu tang dia chi giua burst — doc sai.
`define AXI_BURST_FIXED 2'b00
`define AXI_BURST_INCR  2'b01
`define AXI_BURST_WRAP  2'b10

// AXI RRESP/BRESP codes
`define AXI_RESP_OKAY    2'b00
`define AXI_RESP_EXOKAY  2'b01
`define AXI_RESP_SLVERR  2'b10
`define AXI_RESP_DECERR  2'b11

// ------------------------------------------------------------
// DMA channel error codes — MO TU 2 LEN 3 BIT o DMA v2.
// STATUS[3:2] giu nguyen nghia cho 4 ma cu; STATUS[4] truoc day
// luon 0 nen phan mem cu doc [3:2] van dung.
// ------------------------------------------------------------
`define DMA_ERR_W       3
`define DMA_ERR_NONE    3'b000
`define DMA_ERR_SLVERR  3'b001
`define DMA_ERR_DECERR  3'b010
`define DMA_ERR_TIMEOUT 3'b011
`define DMA_ERR_ACCESS  3'b100   // IOPMP chan
`define DMA_ERR_DESC    3'b101   // descriptor hong
`define DMA_ERR_ABORT   3'b110   // phan mem huy

// ------------------------------------------------------------
// Transfer width encoding (CTRL.SRC_WIDTH / CTRL.DST_WIDTH)
// Chi co hieu luc o che do FIXED (ngoai vi). Truy cap bo nho
// (INCR) luon dung 32-bit va de dma_align lo phan can byte.
// ------------------------------------------------------------
`define DMA_W8   2'b00
`define DMA_W16  2'b01
`define DMA_W32  2'b10

// ------------------------------------------------------------
// Register offsets theo kenh (moi kenh chiem 0x1000 byte)
// 0x00..0x18 GIU NGUYEN vi tri de tb_mem_paths.sv chay tiep.
// ------------------------------------------------------------
`define REG_SRC_ADDR   8'h00
`define REG_DST_ADDR   8'h04
`define REG_LEN        8'h08     // DMA v2: 32-bit (truoc la 16-bit)
`define REG_CTRL       8'h0C     // [14:0] giu nguyen, [31:15] moi
`define REG_STATUS     8'h10     // RO
`define REG_INT_EN     8'h14     // [0]done [1]err [2]half [3]chain
`define REG_INT_STAT   8'h18     // W1C, cung bit
// --- moi tu DMA v2 ---
`define REG_DESC_PTR   8'h1C     // descriptor dau chuoi; 0 = tat SG
`define REG_XFER_CNT   8'h20     // RO: byte da hoan thanh
`define REG_ERR_ADDR   8'h24     // RO: dia chi gay loi
`define REG_SRC_STRIDE 8'h28     // 2D, co dau
`define REG_DST_STRIDE 8'h2C     // 2D, co dau
`define REG_NUM_LINES  8'h30     // 2D
`define REG_PRIO       8'h34     // [3:0] trong so arbiter
`define REG_TUNING     8'h38     // [3:0]tokens [11:8]rd_out [19:16]wr_out
`define REG_SHADOW_SRC 8'h40
`define REG_SHADOW_DST 8'h44
`define REG_SHADOW_LEN 8'h48
`define REG_SHADOW_CTL 8'h4C

// ------------------------------------------------------------
// CTRL bit layout
//   [14:0] GIU NGUYEN tu DMA v1 — khong duoc doi.
// ------------------------------------------------------------
`define CTRL_START      0
`define CTRL_BMAX_LSB   1
// CTRL_BMAX_MSB = BURST_W (parameter), tinh trong module
`define CTRL_SI         8       // src_incr; 0 -> FIXED burst
`define CTRL_DI         9       // dst_incr; 0 -> FIXED burst
`define CTRL_PNUM_LSB   10      // .. 14 (PERIPH_NUM_W = 5)
`define CTRL_SW_LSB     15      // src_width [16:15]
`define CTRL_DW_LSB     17      // dst_width [18:17]
`define CTRL_SG_EN      19
`define CTRL_RELOAD     20
`define CTRL_CIRCULAR   21
`define CTRL_TWO_D      22
`define CTRL_ABORT      23
`define CTRL_SUSPEND    24
`define CTRL_PRIV       25      // -> AxPROT[0]
`define CTRL_SECURE     26      // -> AxPROT[1] = ~SECURE (AMBA: 0 = secure)
`define CTRL_CACHE_LSB  27      // .. 30  -> AxCACHE[3:0]
`define CTRL_PERIPH_MD  31      // 0 = level (tuong thich nguoc), 1 = handshake

// ------------------------------------------------------------
// STATUS bit layout (RO)
// ------------------------------------------------------------
`define STAT_ACTIVE     0
`define STAT_DONE       1
`define STAT_ERR_LSB    2       // .. 4  (3 bit)
`define STAT_SUSPENDED  5
`define STAT_CHAIN_ACT  6

// ------------------------------------------------------------
// INT_EN / INT_STAT bit layout
// ------------------------------------------------------------
`define INT_DONE        0
`define INT_ERR         1
`define INT_HALF        2
`define INT_CHAIN       3
`define DMA_INT_W       4

// ------------------------------------------------------------
// Global control (offset tu engine base, khong phai channel base)
// ------------------------------------------------------------
`define REG_GLOBAL_CTRL 12'hF00  // [0]=soft_rst [1]=dma_en
`define REG_GLOBAL_STAT 12'hF04  // RO: bitmap kenh dang chay
`define REG_IOPMP_BASE  12'hF10  // 8 vung x 2 word = 0xF10..0xF4C
`define REG_IOPMP_LOCK  12'hF50  // [7:0] sticky

`define DMA_IOPMP_N     8        // so vung IOPMP

// ------------------------------------------------------------
// Descriptor layout — 32 byte = 8 word, CAN 32 BYTE nen mot
// burst 8 beat khong bao gio cat bien 4 KB.
// ------------------------------------------------------------
`define DESC_BYTES      32
`define DESC_BEATS      8
`define DESC_W_SRC      0
`define DESC_W_DST      1
`define DESC_W_LEN      2
`define DESC_W_CTRL     3
`define DESC_W_NEXT     4
`define DESC_W_SSTRIDE  5
`define DESC_W_DSTRIDE  6
`define DESC_W_NLINES   7

// ------------------------------------------------------------
// Misc
// ------------------------------------------------------------
`define DMA_CH_STRIDE  12        // bits: moi kenh cach nhau 2^12 = 0x1000
                                 // paddr[11+N_CH_W : 12] = channel index

`endif // DMA_DEFINES_VH
