`timescale 1ns / 1ps

// =============================================================================
// PINMUX - 32 pad PA0..PA31, bang chuc nang thay the (AF) CO DINH kieu STM32
// (2026-09-11).
//
// Truoc day moi ngoai vi co chan rieng tren top_soc (uart 2, spi 4, i2c 6,
// pwm 1) cong 32 GPIO x 3 tin hieu: 41 chan package cho nhom nay, va moi ngoai
// vi moi (UART1, 8 kenh timer) se them chan nua. Nay moi chuc nang di qua 32 pad
// dung chung; them ngoai vi khong them chan nao.
//
// Moi pad co 2 bit AFSEL:  0 = GPIO,  1..3 = AF1..AF3 theo bang duoi.
// Bang cua PA0-15 va PA16-31 GIONG HET NHAU (q = so pad mod 16), nen moi chuc
// nang co it nhat HAI vi tri - de chon khi layout PCB.
//
//    q | AF1       | AF2       | AF3
//   ---+-----------+-----------+-----------
//    0 | UART0_TX  | TIM0_CH0  |  -
//    1 | UART0_RX  | TIM0_CH1  |  -
//    2 | UART1_TX  | TIM0_CH2  |  -
//    3 | UART1_RX  | TIM0_CH3  |  -
//    4 | SPI_SCK   | TIM1_CH0  |  -
//    5 | SPI_MOSI  | TIM1_CH1  |  -
//    6 | SPI_MISO  | TIM1_CH2  |  -
//    7 | SPI_SS    | TIM1_CH3  |  -
//    8 | I2C_SCL   | PWM_OUT   | UART1_TX
//    9 | I2C_SDA   |  -        | UART1_RX
//   10 |  -        | TIM0_CH0  | UART0_TX
//   11 |  -        | TIM0_CH1  | UART0_RX
//   12 |  -        | TIM1_CH0  | I2C_SCL
//   13 |  -        | TIM1_CH1  | I2C_SDA
//   14 |  -        | PWM_OUT   | SPI_SS
//   15 |  -        |  -        |  -
//   "-" = reserved: pad thanh dau vao (oe = 0), giong AF khong dinh nghia.
//
// MAC DINH SAU RESET: PA0 = UART0_TX, PA1 = UART0_RX (AFSEL0 = 0x5), moi pad
// khac la GPIO vao. Console UART0 co san cho boot ROM ma khong can cau hinh -
// nhu ESP32 - va firmware cu (khong biet pinmux) van in duoc ra PA0.
//
// Dau vao cua ngoai vi:
//   * khong pad nao chon -> gia tri NGHI: RX = 1, SCL/SDA = 1 (bus ranh),
//     MISO = 0, kenh capture = 0.
//   * nhieu pad cung chon mot dau vao -> tin hieu nghi-muc-1 duoc AND (nhu bus
//     wired-AND), tin hieu nghi-muc-0 duoc OR. Xac dinh, khong phu thuoc thu tu.
// GPIO LUON doc duoc muc cua moi pad bat ke AF (nhu IDR cua STM32).
// I2C van la open-drain: loi I2C tu dat out/oe (out = 0, oe = keo xuong).
//
// BAN DO THANH GHI (APB slave S14, base 0x4002_0000)
//   0x00 AFSEL0  pad 0-15,  pad p o bit [2p+1:2p]    reset 0x0000_0005
//   0x04 AFSEL1  pad 16-31, pad p o bit [2(p-16)+1:2(p-16)]  reset 0
//   offset khac -> PSLVERR
// =============================================================================
module apb_pinmux #(
    parameter ADDR_WIDTH = 12
)(
    input  wire                  pclk,
    input  wire                  presetn,
    input  wire [ADDR_WIDTH-1:0] paddr,
    input  wire                  psel,
    input  wire                  penable,
    input  wire                  pwrite,
    input  wire [31:0]           pwdata,
    output reg                   pready,
    output reg  [31:0]           prdata,
    output reg                   pslverr,

    // --- Pad (toi pad ring) ---
    input  wire [31:0]           pad_in,
    output reg  [31:0]           pad_out,
    output reg  [31:0]           pad_oe,

    // --- GPIO ---
    input  wire [31:0]           gpio_out,
    input  wire [31:0]           gpio_oe,
    output wire [31:0]           gpio_in,

    // --- Ngoai vi ---
    input  wire                  uart0_tx,
    output wire                  uart0_rx,
    input  wire                  uart1_tx,
    output wire                  uart1_rx,
    input  wire                  spi_sck,
    input  wire                  spi_mosi,
    input  wire                  spi_ss,
    output wire                  spi_miso,
    input  wire                  i2c_scl_o,
    input  wire                  i2c_scl_oe,
    output wire                  i2c_scl_i,
    input  wire                  i2c_sda_o,
    input  wire                  i2c_sda_oe,
    output wire                  i2c_sda_i,
    input  wire                  pwm_out,
    input  wire [3:0]            tim0_o,
    input  wire [3:0]            tim0_oe,
    output wire [3:0]            tim0_i,
    input  wire [3:0]            tim1_o,
    input  wire [3:0]            tim1_oe,
    output wire [3:0]            tim1_i
);

    // Ma chuc nang
    localparam [4:0] F_NONE = 5'd0,
                     F_U0TX = 5'd1,  F_U0RX = 5'd2,
                     F_U1TX = 5'd3,  F_U1RX = 5'd4,
                     F_SCK  = 5'd5,  F_MOSI = 5'd6,  F_MISO = 5'd7,  F_SS = 5'd8,
                     F_SCL  = 5'd9,  F_SDA  = 5'd10, F_PWM  = 5'd11,
                     F_T0C0 = 5'd12,                                 // ..15
                     F_T1C0 = 5'd16;                                 // ..19

    // Bang AF (xem dau file). q = pad mod 16, af = 1..3.
    function automatic [4:0] af_func;
        input [3:0] q;
        input [1:0] af;
        begin
            af_func = F_NONE;
            case (af)
                2'd1: case (q)
                    4'd0: af_func = F_U0TX;   4'd1: af_func = F_U0RX;
                    4'd2: af_func = F_U1TX;   4'd3: af_func = F_U1RX;
                    4'd4: af_func = F_SCK;    4'd5: af_func = F_MOSI;
                    4'd6: af_func = F_MISO;   4'd7: af_func = F_SS;
                    4'd8: af_func = F_SCL;    4'd9: af_func = F_SDA;
                    default: af_func = F_NONE;
                endcase
                2'd2: case (q)
                    4'd0: af_func = F_T0C0 + 5'd0;  4'd1: af_func = F_T0C0 + 5'd1;
                    4'd2: af_func = F_T0C0 + 5'd2;  4'd3: af_func = F_T0C0 + 5'd3;
                    4'd4: af_func = F_T1C0 + 5'd0;  4'd5: af_func = F_T1C0 + 5'd1;
                    4'd6: af_func = F_T1C0 + 5'd2;  4'd7: af_func = F_T1C0 + 5'd3;
                    4'd8: af_func = F_PWM;
                    4'd10: af_func = F_T0C0 + 5'd0; 4'd11: af_func = F_T0C0 + 5'd1;
                    4'd12: af_func = F_T1C0 + 5'd0; 4'd13: af_func = F_T1C0 + 5'd1;
                    4'd14: af_func = F_PWM;
                    default: af_func = F_NONE;
                endcase
                2'd3: case (q)
                    4'd8:  af_func = F_U1TX;  4'd9:  af_func = F_U1RX;
                    4'd10: af_func = F_U0TX;  4'd11: af_func = F_U0RX;
                    4'd12: af_func = F_SCL;   4'd13: af_func = F_SDA;
                    4'd14: af_func = F_SS;
                    default: af_func = F_NONE;
                endcase
                default: af_func = F_NONE;
            endcase
        end
    endfunction

    // -------------------------------------------------------------------------
    // APB
    // -------------------------------------------------------------------------
    reg [63:0] afsel;   // {AFSEL1, AFSEL0}

    wire apb_write = psel && penable &&  pwrite;
    wire apb_read  = psel && penable && !pwrite;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            afsel   <= 64'h0000_0000_0000_0005;   // PA0/PA1 = UART0
            pready  <= 1'b0;
            prdata  <= 32'd0;
            pslverr <= 1'b0;
        end else begin
            pready  <= psel && penable;
            pslverr <= 1'b0;
            if (apb_write) begin
                case (paddr[11:0])
                    12'h000: afsel[31:0]  <= pwdata;
                    12'h004: afsel[63:32] <= pwdata;
                    default: pslverr <= 1'b1;
                endcase
            end
            if (apb_read) begin
                case (paddr[11:0])
                    12'h000: prdata <= afsel[31:0];
                    12'h004: prdata <= afsel[63:32];
                    default: begin prdata <= 32'd0; pslverr <= 1'b1; end
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // Mux ra pad, va vector "pad p dang mang dau vao f"
    // -------------------------------------------------------------------------
    reg [31:0] sel_u0rx, sel_u1rx, sel_miso, sel_scl, sel_sda;
    reg [31:0] sel_t0 [0:3];
    reg [31:0] sel_t1 [0:3];

    integer p, c;
    reg [1:0] af;
    reg [4:0] f;
    always @(*) begin
        sel_u0rx = 32'd0; sel_u1rx = 32'd0; sel_miso = 32'd0;
        sel_scl  = 32'd0; sel_sda  = 32'd0;
        for (c = 0; c < 4; c = c + 1) begin
            sel_t0[c] = 32'd0;
            sel_t1[c] = 32'd0;
        end
        for (p = 0; p < 32; p = p + 1) begin
            af = afsel[2*p +: 2];
            f  = af_func(p[3:0], af);
            if (af == 2'd0) begin
                pad_out[p] = gpio_out[p];
                pad_oe[p]  = gpio_oe[p];
            end else begin
                pad_out[p] = 1'b0;
                pad_oe[p]  = 1'b0;
                case (f)
                    F_U0TX: begin pad_out[p] = uart0_tx;  pad_oe[p] = 1'b1;       end
                    F_U1TX: begin pad_out[p] = uart1_tx;  pad_oe[p] = 1'b1;       end
                    F_SCK:  begin pad_out[p] = spi_sck;   pad_oe[p] = 1'b1;       end
                    F_MOSI: begin pad_out[p] = spi_mosi;  pad_oe[p] = 1'b1;       end
                    F_SS:   begin pad_out[p] = spi_ss;    pad_oe[p] = 1'b1;       end
                    F_PWM:  begin pad_out[p] = pwm_out;   pad_oe[p] = 1'b1;       end
                    F_SCL:  begin pad_out[p] = i2c_scl_o; pad_oe[p] = i2c_scl_oe;
                                  sel_scl[p] = 1'b1;                              end
                    F_SDA:  begin pad_out[p] = i2c_sda_o; pad_oe[p] = i2c_sda_oe;
                                  sel_sda[p] = 1'b1;                              end
                    F_U0RX: sel_u0rx[p] = 1'b1;
                    F_U1RX: sel_u1rx[p] = 1'b1;
                    F_MISO: sel_miso[p] = 1'b1;
                    default: begin
                        for (c = 0; c < 4; c = c + 1) begin
                            if (f == F_T0C0 + c) begin
                                pad_out[p] = tim0_o[c]; pad_oe[p] = tim0_oe[c];
                                sel_t0[c][p] = 1'b1;
                            end
                            if (f == F_T1C0 + c) begin
                                pad_out[p] = tim1_o[c]; pad_oe[p] = tim1_oe[c];
                                sel_t1[c][p] = 1'b1;
                            end
                        end
                    end
                endcase
            end
        end
    end

    // Nghi-muc-1: AND tren cac pad duoc chon (khong chon pad nao -> 1).
    // Nghi-muc-0: OR  tren cac pad duoc chon (khong chon pad nao -> 0).
    assign uart0_rx  = &(~sel_u0rx | pad_in);
    assign uart1_rx  = &(~sel_u1rx | pad_in);
    assign i2c_scl_i = &(~sel_scl  | pad_in);
    assign i2c_sda_i = &(~sel_sda  | pad_in);
    assign spi_miso  = |( sel_miso & pad_in);

    genvar gc;
    generate
        for (gc = 0; gc < 4; gc = gc + 1) begin : g_tin
            assign tim0_i[gc] = |(sel_t0[gc] & pad_in);
            assign tim1_i[gc] = |(sel_t1[gc] & pad_in);
        end
    endgenerate

    assign gpio_in = pad_in;

endmodule
