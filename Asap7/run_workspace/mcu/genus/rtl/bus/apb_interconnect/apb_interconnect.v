`timescale 1ns / 1ps

module apb_interconnect #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    
    // Memory Map Cấu hình (Base Address & Mask)
    parameter SLV0_BASE = 32'h4000_0000, parameter SLV0_MASK = 32'hFFFF_F000, // S0: UART
    parameter SLV1_BASE = 32'h4000_1000, parameter SLV1_MASK = 32'hFFFF_F000, // S1: GPIO
    parameter SLV2_BASE = 32'h4000_2000, parameter SLV2_MASK = 32'hFFFF_F000, // S2: Timer
    parameter SLV3_BASE = 32'h4000_3000, parameter SLV3_MASK = 32'hFFFF_F000, // S3: SPI
    parameter SLV4_BASE = 32'h4000_4000, parameter SLV4_MASK = 32'hFFFF_F000, // S4: I2C
    parameter SLV5_BASE = 32'h4000_5000, parameter SLV5_MASK = 32'hFFFF_F000, // S5: Watchdog
    parameter SLV6_BASE = 32'h4000_6000, parameter SLV6_MASK = 32'hFFFF_F000, // S6: CORDIC
    parameter SLV7_BASE = 32'h4000_7000, parameter SLV7_MASK = 32'hFFFF_F000, // S7: Syscon
    parameter SLV8_BASE = 32'h4400_0000, parameter SLV8_MASK = 32'hFC00_0000, // S8: CLIC (thay PLIC 2026-09-11)
    parameter SLV9_BASE = 32'h4000_8000, parameter SLV9_MASK = 32'hFFFF_C000, // S9: DMA Config (0x4000_8000-0x4000_BFFF)
    parameter SLV10_BASE = 32'h4000_C000, parameter SLV10_MASK = 32'hFFFF_F000, // S10: ASCON + TRNG
    // 2026-09-11 - muc 8: them ngoai vi. 0x4001_xxxx co y de TRONG (testbench
    // APB dung no lam dia chi decode-error), pinmux o 0x4002_0000.
    parameter SLV11_BASE = 32'h4000_D000, parameter SLV11_MASK = 32'hFFFF_F000, // S11: UART1
    parameter SLV12_BASE = 32'h4000_E000, parameter SLV12_MASK = 32'hFFFF_F000, // S12: TIM0
    parameter SLV13_BASE = 32'h4000_F000, parameter SLV13_MASK = 32'hFFFF_F000, // S13: TIM1
    parameter SLV14_BASE = 32'h4002_0000, parameter SLV14_MASK = 32'hFFFF_F000, // S14: PINMUX
    // ------------------------------------------------------------------------
    // 2026-09-11 - MOI LENH GHI APB TOI SLAVE DUNG MOT LAN.
    //
    // Cac slave o day (tru ASCON) sinh `pready <= psel && penable` - mot FLOP.
    // Nen pha ACCESS co HAI canh ma slave thay psel & penable: canh B (slave
    // ghi, dat pready) va canh C (axi_to_apb_bridge thay pready = 1 va ket
    // thuc). Slave GHI O CA HAI canh. Thanh ghi thuong thi vo hai; FIFO thi
    // khong: moi lenh ghi UART TX_DATA day HAI byte (do tren fw: 48 lan day cho
    // 24 lenh ghi - moi ky tu ra chan hai lan), TIM EGR.CCxG chup hai lan va
    // tu bao over-capture.
    //
    // Sua mot cho cho moi slave: che penable toi slave khi chinh slave do dang
    // bao pready. Canh B khong doi (pready con 0); o canh C slave thay penable
    // = 0 nen khong ghi lai, pready tu ve 0. Bridge lay mau pready/prdata/
    // pslverr NGAY TRUOC canh C nen van thay gia tri dat o canh B.
    // Bit = 0 cho slave co pready TO HOP (ASCON: PREADY = 1, zero wait) - che
    // penable cua no bang chinh pready se lam no khong bao gio thay penable.
    // ------------------------------------------------------------------------
    parameter [14:0] PREADY_REG = 15'b111_1011_1111_1111
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // APB4 MASTER PORT (Tới từ Bridge)
    input  wire [ADDR_WIDTH-1:0]    m_paddr,
    input  wire                     m_psel,
    input  wire                     m_penable,
    input  wire                     m_pwrite,
    input  wire [DATA_WIDTH-1:0]    m_pwdata,
    input  wire [(DATA_WIDTH/8)-1:0]m_pstrb,
    input  wire [2:0]               m_pprot,
    output reg                      m_pready,
    output reg  [DATA_WIDTH-1:0]    m_prdata,
    output reg                      m_pslverr,

    // SLAVE 0: UART
    output wire [ADDR_WIDTH-1:0]    s0_paddr, output wire s0_psel, output wire s0_penable,
    output wire s0_pwrite, output wire [DATA_WIDTH-1:0] s0_pwdata, output wire [(DATA_WIDTH/8)-1:0] s0_pstrb,
    output wire [2:0] s0_pprot, input wire s0_pready, input wire [DATA_WIDTH-1:0] s0_prdata, input wire s0_pslverr,

    // SLAVE 1: GPIO
    output wire [ADDR_WIDTH-1:0]    s1_paddr, output wire s1_psel, output wire s1_penable,
    output wire s1_pwrite, output wire [DATA_WIDTH-1:0] s1_pwdata, output wire [(DATA_WIDTH/8)-1:0] s1_pstrb,
    output wire [2:0] s1_pprot, input wire s1_pready, input wire [DATA_WIDTH-1:0] s1_prdata, input wire s1_pslverr,

    // SLAVE 2: Timer
    output wire [ADDR_WIDTH-1:0]    s2_paddr, output wire s2_psel, output wire s2_penable,
    output wire s2_pwrite, output wire [DATA_WIDTH-1:0] s2_pwdata, output wire [(DATA_WIDTH/8)-1:0] s2_pstrb,
    output wire [2:0] s2_pprot, input wire s2_pready, input wire [DATA_WIDTH-1:0] s2_prdata, input wire s2_pslverr,

    // SLAVE 3: SPI
    output wire [ADDR_WIDTH-1:0]    s3_paddr, output wire s3_psel, output wire s3_penable,
    output wire s3_pwrite, output wire [DATA_WIDTH-1:0] s3_pwdata, output wire [(DATA_WIDTH/8)-1:0] s3_pstrb,
    output wire [2:0] s3_pprot, input wire s3_pready, input wire [DATA_WIDTH-1:0] s3_prdata, input wire s3_pslverr,

    // SLAVE 4: I2C
    output wire [ADDR_WIDTH-1:0]    s4_paddr, output wire s4_psel, output wire s4_penable,
    output wire s4_pwrite, output wire [DATA_WIDTH-1:0] s4_pwdata, output wire [(DATA_WIDTH/8)-1:0] s4_pstrb,
    output wire [2:0] s4_pprot, input wire s4_pready, input wire [DATA_WIDTH-1:0] s4_prdata, input wire s4_pslverr,

    // SLAVE 5: Watchdog
    output wire [ADDR_WIDTH-1:0]    s5_paddr, output wire s5_psel, output wire s5_penable,
    output wire s5_pwrite, output wire [DATA_WIDTH-1:0] s5_pwdata, output wire [(DATA_WIDTH/8)-1:0] s5_pstrb,
    output wire [2:0] s5_pprot, input wire s5_pready, input wire [DATA_WIDTH-1:0] s5_prdata, input wire s5_pslverr,

    // SLAVE 6: CORDIC
    output wire [ADDR_WIDTH-1:0]    s6_paddr, output wire s6_psel, output wire s6_penable,
    output wire s6_pwrite, output wire [DATA_WIDTH-1:0] s6_pwdata, output wire [(DATA_WIDTH/8)-1:0] s6_pstrb,
    output wire [2:0] s6_pprot, input wire s6_pready, input wire [DATA_WIDTH-1:0] s6_prdata, input wire s6_pslverr,

    // SLAVE 7: Syscon
    output wire [ADDR_WIDTH-1:0]    s7_paddr, output wire s7_psel, output wire s7_penable,
    output wire s7_pwrite, output wire [DATA_WIDTH-1:0] s7_pwdata, output wire [(DATA_WIDTH/8)-1:0] s7_pstrb,
    output wire [2:0] s7_pprot, input wire s7_pready, input wire [DATA_WIDTH-1:0] s7_prdata, input wire s7_pslverr,

    // S8: CLIC (can pstrb: clicintip/ie/attr/ctl ghi tung byte)
    output wire [ADDR_WIDTH-1:0] s8_paddr,
    output wire                  s8_psel,
    output wire                  s8_penable,
    output wire                  s8_pwrite,
    output wire [DATA_WIDTH-1:0] s8_pwdata,
    output wire [(DATA_WIDTH/8)-1:0] s8_pstrb,
    input  wire [DATA_WIDTH-1:0] s8_prdata,
    input  wire                  s8_pready,
    input  wire                  s8_pslverr,

    // S9: DMA Config
    output wire [ADDR_WIDTH-1:0] s9_paddr,
    output wire                  s9_psel,
    output wire                  s9_penable,
    output wire                  s9_pwrite,
    output wire [DATA_WIDTH-1:0] s9_pwdata,
    input  wire [DATA_WIDTH-1:0] s9_prdata,
    input  wire                  s9_pready,
    input  wire                  s9_pslverr,

    // S10: ASCON / TRNG
    output wire [ADDR_WIDTH-1:0] s10_paddr,
    output wire                  s10_psel,
    output wire                  s10_penable,
    output wire                  s10_pwrite,
    output wire [DATA_WIDTH-1:0] s10_pwdata,
    input  wire [DATA_WIDTH-1:0] s10_prdata,
    input  wire                  s10_pready,
    input  wire                  s10_pslverr,

    // S11: UART1   S12: TIM0   S13: TIM1   S14: PINMUX
    output wire [ADDR_WIDTH-1:0] s11_paddr, output wire s11_psel, output wire s11_penable,
    output wire s11_pwrite, output wire [DATA_WIDTH-1:0] s11_pwdata, output wire [(DATA_WIDTH/8)-1:0] s11_pstrb,
    input wire s11_pready, input wire [DATA_WIDTH-1:0] s11_prdata, input wire s11_pslverr,

    output wire [ADDR_WIDTH-1:0] s12_paddr, output wire s12_psel, output wire s12_penable,
    output wire s12_pwrite, output wire [DATA_WIDTH-1:0] s12_pwdata, output wire [(DATA_WIDTH/8)-1:0] s12_pstrb,
    input wire s12_pready, input wire [DATA_WIDTH-1:0] s12_prdata, input wire s12_pslverr,

    output wire [ADDR_WIDTH-1:0] s13_paddr, output wire s13_psel, output wire s13_penable,
    output wire s13_pwrite, output wire [DATA_WIDTH-1:0] s13_pwdata, output wire [(DATA_WIDTH/8)-1:0] s13_pstrb,
    input wire s13_pready, input wire [DATA_WIDTH-1:0] s13_prdata, input wire s13_pslverr,

    output wire [ADDR_WIDTH-1:0] s14_paddr, output wire s14_psel, output wire s14_penable,
    output wire s14_pwrite, output wire [DATA_WIDTH-1:0] s14_pwdata, output wire [(DATA_WIDTH/8)-1:0] s14_pstrb,
    input wire s14_pready, input wire [DATA_WIDTH-1:0] s14_prdata, input wire s14_pslverr
);

    // ADDRESS DECODING
    wire match_s0 = ((m_paddr & SLV0_MASK) == SLV0_BASE);
    wire match_s1 = ((m_paddr & SLV1_MASK) == SLV1_BASE);
    wire match_s2 = ((m_paddr & SLV2_MASK) == SLV2_BASE);
    wire match_s3 = ((m_paddr & SLV3_MASK) == SLV3_BASE);
    wire match_s4 = ((m_paddr & SLV4_MASK) == SLV4_BASE);
    wire match_s5 = ((m_paddr & SLV5_MASK) == SLV5_BASE);
    wire match_s6 = ((m_paddr & SLV6_MASK) == SLV6_BASE);
    wire match_s7 = ((m_paddr & SLV7_MASK) == SLV7_BASE);
    wire match_s8 = ((m_paddr & SLV8_MASK) == SLV8_BASE);
    wire match_s9 = ((m_paddr & SLV9_MASK) == SLV9_BASE);
    wire match_s10 = ((m_paddr & SLV10_MASK) == SLV10_BASE);
    wire match_s11 = ((m_paddr & SLV11_MASK) == SLV11_BASE);
    wire match_s12 = ((m_paddr & SLV12_MASK) == SLV12_BASE);
    wire match_s13 = ((m_paddr & SLV13_MASK) == SLV13_BASE);
    wire match_s14 = ((m_paddr & SLV14_MASK) == SLV14_BASE);
    wire match_any = match_s0 | match_s1 | match_s2 | match_s3 | match_s4 | match_s5 | match_s6 | match_s7 | match_s8 | match_s9 | match_s10 |
                     match_s11 | match_s12 | match_s13 | match_s14;

    // COMMON SIGNALS TO ALL SLAVES
    assign s0_paddr = m_paddr; assign s0_penable = m_penable & ~(PREADY_REG[0] & s0_pready); assign s0_pwrite = m_pwrite; assign s0_pwdata = m_pwdata; assign s0_pstrb = m_pstrb; assign s0_pprot = m_pprot;
    assign s1_paddr = m_paddr; assign s1_penable = m_penable & ~(PREADY_REG[1] & s1_pready); assign s1_pwrite = m_pwrite; assign s1_pwdata = m_pwdata; assign s1_pstrb = m_pstrb; assign s1_pprot = m_pprot;
    assign s2_paddr = m_paddr; assign s2_penable = m_penable & ~(PREADY_REG[2] & s2_pready); assign s2_pwrite = m_pwrite; assign s2_pwdata = m_pwdata; assign s2_pstrb = m_pstrb; assign s2_pprot = m_pprot;
    assign s3_paddr = m_paddr; assign s3_penable = m_penable & ~(PREADY_REG[3] & s3_pready); assign s3_pwrite = m_pwrite; assign s3_pwdata = m_pwdata; assign s3_pstrb = m_pstrb; assign s3_pprot = m_pprot;
    assign s4_paddr = m_paddr; assign s4_penable = m_penable & ~(PREADY_REG[4] & s4_pready); assign s4_pwrite = m_pwrite; assign s4_pwdata = m_pwdata; assign s4_pstrb = m_pstrb; assign s4_pprot = m_pprot;
    assign s5_paddr = m_paddr; assign s5_penable = m_penable & ~(PREADY_REG[5] & s5_pready); assign s5_pwrite = m_pwrite; assign s5_pwdata = m_pwdata; assign s5_pstrb = m_pstrb; assign s5_pprot = m_pprot;
    assign s6_paddr = m_paddr; assign s6_penable = m_penable & ~(PREADY_REG[6] & s6_pready); assign s6_pwrite = m_pwrite; assign s6_pwdata = m_pwdata; assign s6_pstrb = m_pstrb; assign s6_pprot = m_pprot;
    assign s7_paddr = m_paddr; assign s7_penable = m_penable & ~(PREADY_REG[7] & s7_pready); assign s7_pwrite = m_pwrite; assign s7_pwdata = m_pwdata; assign s7_pstrb = m_pstrb; assign s7_pprot = m_pprot;
    assign s8_paddr = m_paddr; assign s8_penable = m_penable & ~(PREADY_REG[8] & s8_pready); assign s8_pwrite = m_pwrite; assign s8_pwdata = m_pwdata; assign s8_pstrb = m_pstrb;
    assign s9_paddr = m_paddr; assign s9_penable = m_penable & ~(PREADY_REG[9] & s9_pready); assign s9_pwrite = m_pwrite; assign s9_pwdata = m_pwdata;
    assign s10_paddr = m_paddr; assign s10_penable = m_penable & ~(PREADY_REG[10] & s10_pready); assign s10_pwrite = m_pwrite; assign s10_pwdata = m_pwdata;
    assign s11_paddr = m_paddr; assign s11_penable = m_penable & ~(PREADY_REG[11] & s11_pready); assign s11_pwrite = m_pwrite; assign s11_pwdata = m_pwdata; assign s11_pstrb = m_pstrb;
    assign s12_paddr = m_paddr; assign s12_penable = m_penable & ~(PREADY_REG[12] & s12_pready); assign s12_pwrite = m_pwrite; assign s12_pwdata = m_pwdata; assign s12_pstrb = m_pstrb;
    assign s13_paddr = m_paddr; assign s13_penable = m_penable & ~(PREADY_REG[13] & s13_pready); assign s13_pwrite = m_pwrite; assign s13_pwdata = m_pwdata; assign s13_pstrb = m_pstrb;
    assign s14_paddr = m_paddr; assign s14_penable = m_penable & ~(PREADY_REG[14] & s14_pready); assign s14_pwrite = m_pwrite; assign s14_pwdata = m_pwdata; assign s14_pstrb = m_pstrb;

    // CHIP SELECT MUX
    assign s0_psel = m_psel & match_s0;
    assign s1_psel = m_psel & match_s1;
    assign s2_psel = m_psel & match_s2;
    assign s3_psel = m_psel & match_s3;
    assign s4_psel = m_psel & match_s4;
    assign s5_psel = m_psel & match_s5;
    assign s6_psel = m_psel & match_s6;
    assign s7_psel = m_psel & match_s7;
    assign s8_psel = m_psel & match_s8;
    assign s9_psel = m_psel & match_s9;
    assign s10_psel = m_psel & match_s10;
    assign s11_psel = m_psel & match_s11;
    assign s12_psel = m_psel & match_s12;
    assign s13_psel = m_psel & match_s13;
    assign s14_psel = m_psel & match_s14;

    // DEFAULT SLAVE (Chống treo bus)
    reg def_slv_ready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) def_slv_ready <= 1'b0;
        else if (m_psel && !match_any && m_penable && !def_slv_ready) def_slv_ready <= 1'b1;
        else def_slv_ready <= 1'b0;
    end

    // READ MULTIPLEXER
    always @(*) begin
        if (match_s0) begin m_prdata = s0_prdata; m_pready = s0_pready; m_pslverr = s0_pslverr; end
        else if (match_s1) begin m_prdata = s1_prdata; m_pready = s1_pready; m_pslverr = s1_pslverr; end
        else if (match_s2) begin m_prdata = s2_prdata; m_pready = s2_pready; m_pslverr = s2_pslverr; end
        else if (match_s3) begin m_prdata = s3_prdata; m_pready = s3_pready; m_pslverr = s3_pslverr; end
        else if (match_s4) begin m_prdata = s4_prdata; m_pready = s4_pready; m_pslverr = s4_pslverr; end
        else if (match_s5) begin m_prdata = s5_prdata; m_pready = s5_pready; m_pslverr = s5_pslverr; end
        else if (match_s6) begin m_prdata = s6_prdata; m_pready = s6_pready; m_pslverr = s6_pslverr; end
        else if (match_s7) begin m_prdata = s7_prdata; m_pready = s7_pready; m_pslverr = s7_pslverr; end
        else if (match_s8) begin m_prdata = s8_prdata; m_pready = s8_pready; m_pslverr = s8_pslverr; end
        else if (match_s9) begin m_prdata = s9_prdata; m_pready = s9_pready; m_pslverr = s9_pslverr; end
        else if (match_s10) begin m_prdata = s10_prdata; m_pready = s10_pready; m_pslverr = s10_pslverr; end
        else if (match_s11) begin m_prdata = s11_prdata; m_pready = s11_pready; m_pslverr = s11_pslverr; end
        else if (match_s12) begin m_prdata = s12_prdata; m_pready = s12_pready; m_pslverr = s12_pslverr; end
        else if (match_s13) begin m_prdata = s13_prdata; m_pready = s13_pready; m_pslverr = s13_pslverr; end
        else if (match_s14) begin m_prdata = s14_prdata; m_pready = s14_pready; m_pslverr = s14_pslverr; end
        else begin m_prdata = 32'h0; m_pready = def_slv_ready; m_pslverr = 1'b1; end
    end
endmodule
