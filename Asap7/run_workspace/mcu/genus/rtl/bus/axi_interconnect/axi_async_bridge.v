`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// R3 - do sau cua NAM FIFO CDC la tham so, khong con hard-code 16 slot.
//
// Truoc: ca nam kenh deu `DEPTH_LOG2(4)` = 16 entry. `async_fifo` dung buffer
// bang FLIP-FLOP (`utils/fifo_async.v`) va doc bang mux to hop, nen gia tien ty
// le thang voi depth x width. Hai instance cua module nay tra:
//
//   u_dc_axi_bridge/u_w_fifo   37 bit x 16 = 1887 cell / 4850 um2
//   u_ic_axi_bridge/u_ar_fifo  53 bit x 16 = 1752 cell / 4272 um2
//   u_ic_axi_bridge/u_r_fifo   40 bit x 16 = 1700 cell / 4353 um2
//   u_dc_axi_bridge/u_ar_fifo  53 bit x 16 = 1646 cell / 4029 um2
//   u_dc_axi_bridge/u_aw_fifo  53 bit x 16 = 1596 cell / 3908 um2
//   u_dc_axi_bridge/u_b_fifo    7 bit x 16 =  213 cell /  517 um2
//                                              -> 21 929 um2 tong
//   (reports/area_syn.rpt, ban tong hop 2026-09-09)
//
// Khong master nao can 16 slot:
//   - icache phat DUNG 1 read outstanding va KHONG BAO GIO ghi (top_soc.v noi
//     cung awvalid/wvalid = 0 cho cau nay).
//   - dcache: FSM chinh phat 1 giao dich mot luc; store buffer xa tuan tu
//     SB_AW -> SB_W -> SB_B nen cung chi 1 outstanding.
//   - refill mot block la 4 beat (C_BLOCK_SIZE 16 B / 4 B moi word).
//
// Depth CHI anh huong thong luong, khong anh huong dung sai: moi kenh deu co
// backpressure day du (`s_axi_*ready = ~full`, `m_axi_*ready = ~full`). Chieu
// R/B chay tu m_clk 200 MHz sang s_clk 400 MHz nen phia doc rut nhanh gap doi
// phia ghi, FIFO khong the day.
//
// Mac dinh giu nguyen 4 (= 16 slot) de bat ky ban instantiate nao khong khai
// bao gi van co hanh vi cu; top_soc.v dat gia tri that cho tung cau.
// -----------------------------------------------------------------------------
module axi_async_bridge #(
    parameter ID_WIDTH   = 5,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter AW_DEPTH_LOG2 = 4,
    parameter W_DEPTH_LOG2  = 4,
    parameter B_DEPTH_LOG2  = 4,
    parameter AR_DEPTH_LOG2 = 4,
    parameter R_DEPTH_LOG2  = 4
)(
    // --- Slave Interface (Nối với Master thiết bị - VD: Cache ở clk_core) ---
    input  wire                   s_clk,
    input  wire                   s_rst_n,
    
    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire [2:0]             s_axi_awprot,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready,
    
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,
    
    output wire [ID_WIDTH-1:0]    s_axi_bid,
    output wire [1:0]             s_axi_bresp,
    output wire                   s_axi_bvalid,
    input  wire                   s_axi_bready,
    
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire [2:0]             s_axi_arprot,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,
    
    output wire [ID_WIDTH-1:0]    s_axi_rid,
    output wire [DATA_WIDTH-1:0]  s_axi_rdata,
    output wire [1:0]             s_axi_rresp,
    output wire                   s_axi_rlast,
    output wire                   s_axi_rvalid,
    input  wire                   s_axi_rready,

    // --- Master Interface (Nối vào Bus Interconnect - miền clk_axi) ---
    input  wire                   m_clk,
    input  wire                   m_rst_n,

    output wire [ID_WIDTH-1:0]    m_axi_awid,
    output wire [ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]             m_axi_awlen,
    output wire [2:0]             m_axi_awsize,
    output wire [1:0]             m_axi_awburst,
    output wire [2:0]             m_axi_awprot,
    output wire                   m_axi_awvalid,
    input  wire                   m_axi_awready,
    
    output wire [DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output wire                   m_axi_wlast,
    output wire                   m_axi_wvalid,
    input  wire                   m_axi_wready,
    
    input  wire [ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]             m_axi_bresp,
    input  wire                   m_axi_bvalid,
    output wire                   m_axi_bready,
    
    output wire [ID_WIDTH-1:0]    m_axi_arid,
    output wire [ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]             m_axi_arlen,
    output wire [2:0]             m_axi_arsize,
    output wire [1:0]             m_axi_arburst,
    output wire [2:0]             m_axi_arprot,
    output wire                   m_axi_arvalid,
    input  wire                   m_axi_arready,
    
    input  wire [ID_WIDTH-1:0]    m_axi_rid,
    input  wire [DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]             m_axi_rresp,
    input  wire                   m_axi_rlast,
    input  wire                   m_axi_rvalid,
    output wire                   m_axi_rready
);

    // ==========================================
    // 1. Kênh AW (Ghi Địa Chỉ) : S_CLK -> M_CLK
    // ==========================================
    wire aw_full, aw_empty;
    wire aw_push = s_axi_awvalid & s_axi_awready;
    wire aw_pop  = m_axi_awvalid & m_axi_awready;
    
    assign s_axi_awready = ~aw_full;
    assign m_axi_awvalid = ~aw_empty;
    
    wire [52:0] aw_din = {s_axi_awid, s_axi_awaddr, s_axi_awlen, s_axi_awsize, s_axi_awburst, s_axi_awprot};
    wire [52:0] aw_dout;
    assign {m_axi_awid, m_axi_awaddr, m_axi_awlen, m_axi_awsize, m_axi_awburst, m_axi_awprot} = aw_dout;

    cdc_async_fifo_wrapper #(.DATA_WIDTH(53), .DEPTH_LOG2(AW_DEPTH_LOG2)) u_aw_fifo (
        .wclk(s_clk), .wrst_n(s_rst_n), .wen(aw_push), .wdata(aw_din), .wfull(aw_full),
        .rclk(m_clk), .rrst_n(m_rst_n), .ren(aw_pop),  .rdata(aw_dout), .rempty(aw_empty)
    );

    // ==========================================
    // 2. Kênh W (Ghi Dữ Liệu) : S_CLK -> M_CLK
    // ==========================================
    wire w_full, w_empty;
    wire w_push = s_axi_wvalid & s_axi_wready;
    wire w_pop  = m_axi_wvalid & m_axi_wready;
    
    assign s_axi_wready = ~w_full;
    assign m_axi_wvalid = ~w_empty;
    
    wire [36:0] w_din = {s_axi_wdata, s_axi_wstrb, s_axi_wlast};
    wire [36:0] w_dout;
    assign {m_axi_wdata, m_axi_wstrb, m_axi_wlast} = w_dout;

    cdc_async_fifo_wrapper #(.DATA_WIDTH(37), .DEPTH_LOG2(W_DEPTH_LOG2)) u_w_fifo (
        .wclk(s_clk), .wrst_n(s_rst_n), .wen(w_push), .wdata(w_din), .wfull(w_full),
        .rclk(m_clk), .rrst_n(m_rst_n), .ren(w_pop),  .rdata(w_dout), .rempty(w_empty)
    );

    // ==========================================
    // 3. Kênh B (Phản Hồi Ghi) : M_CLK -> S_CLK
    // ==========================================
    wire b_full, b_empty;
    wire b_push = m_axi_bvalid & m_axi_bready;
    wire b_pop  = s_axi_bvalid & s_axi_bready;
    
    assign m_axi_bready = ~b_full;
    assign s_axi_bvalid = ~b_empty;
    
    wire [6:0] b_din = {m_axi_bid, m_axi_bresp};
    wire [6:0] b_dout;
    assign {s_axi_bid, s_axi_bresp} = b_dout;

    cdc_async_fifo_wrapper #(.DATA_WIDTH(7), .DEPTH_LOG2(B_DEPTH_LOG2)) u_b_fifo (
        .wclk(m_clk), .wrst_n(m_rst_n), .wen(b_push), .wdata(b_din), .wfull(b_full),
        .rclk(s_clk), .rrst_n(s_rst_n), .ren(b_pop),  .rdata(b_dout), .rempty(b_empty)
    );

    // ==========================================
    // 4. Kênh AR (Đọc Địa Chỉ) : S_CLK -> M_CLK
    // ==========================================
    wire ar_full, ar_empty;
    wire ar_push = s_axi_arvalid & s_axi_arready;
    wire ar_pop  = m_axi_arvalid & m_axi_arready;
    
    assign s_axi_arready = ~ar_full;
    assign m_axi_arvalid = ~ar_empty;
    
    wire [52:0] ar_din = {s_axi_arid, s_axi_araddr, s_axi_arlen, s_axi_arsize, s_axi_arburst, s_axi_arprot};
    wire [52:0] ar_dout;
    assign {m_axi_arid, m_axi_araddr, m_axi_arlen, m_axi_arsize, m_axi_arburst, m_axi_arprot} = ar_dout;

    cdc_async_fifo_wrapper #(.DATA_WIDTH(53), .DEPTH_LOG2(AR_DEPTH_LOG2)) u_ar_fifo (
        .wclk(s_clk), .wrst_n(s_rst_n), .wen(ar_push), .wdata(ar_din), .wfull(ar_full),
        .rclk(m_clk), .rrst_n(m_rst_n), .ren(ar_pop),  .rdata(ar_dout), .rempty(ar_empty)
    );

    // ==========================================
    // 5. Kênh R (Đọc Dữ Liệu) : M_CLK -> S_CLK
    // ==========================================
    wire r_full, r_empty;
    wire r_push = m_axi_rvalid & m_axi_rready;
    wire r_pop  = s_axi_rvalid & s_axi_rready;
    
    assign m_axi_rready = ~r_full;
    assign s_axi_rvalid = ~r_empty;
    
    wire [39:0] r_din = {m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast};
    wire [39:0] r_dout;
    assign {s_axi_rid, s_axi_rdata, s_axi_rresp, s_axi_rlast} = r_dout;

    cdc_async_fifo_wrapper #(.DATA_WIDTH(40), .DEPTH_LOG2(R_DEPTH_LOG2)) u_r_fifo (
        .wclk(m_clk), .wrst_n(m_rst_n), .wen(r_push), .wdata(r_din), .wfull(r_full),
        .rclk(s_clk), .rrst_n(s_rst_n), .ren(r_pop),  .rdata(r_dout), .rempty(r_empty)
    );

endmodule