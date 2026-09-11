`timescale 1ns / 1ps

// =============================================================================
// TIMER DA NANG 4 KENH capture / compare / PWM (2026-09-11) - TIM0, TIM1.
//
// Truoc day chip chi co apb_pwm: mot kenh, khong capture, khong ngat. MCU thuong
// co vai timer kieu nay (TIMx cua STM32, GPTM cua TI). Module nay lay lai mo hinh
// quen thuoc cua STM32 o muc toi thieu dung duoc:
//
//   bo dem tang 32 bit, prescaler 16 bit, auto-reload, one-pulse
//   4 kenh, moi kenh chon mot trong hai:
//     COMPARE: frozen / active / inactive / toggle khi khop, force 0/1, PWM1/2
//     CAPTURE: chot CNT o canh len / xuong / ca hai, loc so 1/2/4/8 mau
//   co ngat: update (tran), CCx (khop / da chup), CCxOF (chup de len)
//
// BAN DO THANH GHI (offset 12 bit; offset khac -> PSLVERR nhu moi ngoai vi)
//   0x00 CR    [0] CEN bat bo dem  [1] OPM one-pulse (tu xoa CEN khi tran)
//   0x04 PSC   [15:0] bo dem tang moi PSC+1 chu ky clk
//   0x08 ARR   [31:0] dem 0..ARR roi quay ve 0 (su kien UPDATE)
//   0x0C CNT   [31:0] doc/ghi
//   0x10 SR    W1C  [0] UIF  [4:1] CC0IF..CC3IF  [8:5] CC0OF..CC3OF
//   0x14 DIER       [0] UIE  [4:1] CC0IE..CC3IE
//   0x18 EGR   W    [0] UG: CNT = 0, prescaler = 0, dat UIF
//                   [4:1] CCxG: compare -> dat CCxIF; capture -> chup CNT
//   0x1C CCMR  moi kenh mot byte (kenh c o bit [8c+7:8c]):
//                   [2:0] OCM  000 frozen   001 len 1 khi khop
//                              010 ve 0 khi khop 011 dao khi khop
//                              100 ep 0     101 ep 1
//                              110 PWM1: 1 khi CNT <  CCR
//                              111 PWM2: 1 khi CNT >= CCR
//                   [3]   CCS  0 = compare (ra chan), 1 = capture (vao)
//                   [5:4] ICE  canh chup: 00 len, 01 xuong, 1x ca hai
//                   [7:6] ICF  loc: 00 khong, 01 2 mau, 10 4 mau, 11 8 mau
//   0x20 CCER  kenh c: [2c] CCxE (compare: lai chan; capture: cho phep chup)
//                      [2c+1] CCxP (compare: dao cuc dau ra)
//   0x24/0x28/0x2C/0x30 CCR0..CCR3
//
// Chan ra/vao di qua apb_pinmux (bang AF2). ch_oe = CCxE & ~CCS: kenh capture
// hoac kenh tat khong bao gio lai chan. Dau vao capture la chan ngoai bat dong
// bo nen qua 2FF o day truoc bo loc.
// =============================================================================
module apb_timer #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire                   pclk,
    input  wire                   presetn,
    input  wire [ADDR_WIDTH-1:0]  paddr,
    input  wire                   psel,
    input  wire                   penable,
    input  wire                   pwrite,
    input  wire [DATA_WIDTH-1:0]  pwdata,
    input  wire [3:0]             pstrb,
    output reg                    pready,
    output reg  [DATA_WIDTH-1:0]  prdata,
    output reg                    pslverr,

    input  wire [3:0]             ch_i,
    output wire [3:0]             ch_o,
    output wire [3:0]             ch_oe,
    output wire                   irq
);

    reg        cen, opm;
    reg [15:0] psc;
    reg [31:0] arr;
    reg [31:0] cnt;
    reg [15:0] psc_cnt;
    reg [8:0]  sr;
    reg [4:0]  dier;
    reg [31:0] ccmr;
    reg [7:0]  ccer;
    reg [31:0] ccr [0:3];
    reg [3:0]  oc_ref;

    wire apb_write = psel && penable &&  pwrite;
    wire apb_read  = psel && penable && !pwrite;
    wire [11:0] a  = paddr[11:0];

    wire wr_cr   = apb_write && (a == 12'h000);
    wire wr_psc  = apb_write && (a == 12'h004);
    wire wr_arr  = apb_write && (a == 12'h008);
    wire wr_cnt  = apb_write && (a == 12'h00C);
    wire wr_sr   = apb_write && (a == 12'h010);
    wire wr_dier = apb_write && (a == 12'h014);
    wire wr_egr  = apb_write && (a == 12'h018);
    wire wr_ccmr = apb_write && (a == 12'h01C);
    wire wr_ccer = apb_write && (a == 12'h020);
    wire wr_ccr  = apb_write && ((a == 12'h024) || (a == 12'h028) ||
                                 (a == 12'h02C) || (a == 12'h030));
    // 0x24 -> 0, 0x28 -> 1, 0x2C -> 2, 0x30 -> 3
    wire [1:0] ccr_idx = a[5:2] - 4'd9;

    wire ug = wr_egr & pwdata[0];

    // -------------------------------------------------------------------------
    // Bo dem
    // -------------------------------------------------------------------------
    wire tick     = cen && (psc_cnt == psc);
    wire overflow = tick && (cnt >= arr);

    // -------------------------------------------------------------------------
    // Dau vao capture: 2FF -> loc -> bat canh
    // -------------------------------------------------------------------------
    reg [3:0] in_s1, in_s2, filt, filt_d;
    reg [2:0] fcnt [0:3];
    wire [3:0] cap_evt;

    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : g_ch
            wire [7:0] m      = ccmr[8*c +: 8];
            wire       is_cap = m[3];
            wire       en     = ccer[2*c];
            wire [3:0] flen   = (m[7:6] == 2'b00) ? 4'd1 :
                                (m[7:6] == 2'b01) ? 4'd2 :
                                (m[7:6] == 2'b10) ? 4'd4 : 4'd8;

            // Bo loc: muc moi chi duoc nhan khi giu nguyen flen mau lien tiep.
            always @(posedge pclk or negedge presetn) begin
                if (!presetn) begin
                    fcnt[c] <= 3'd0;
                    filt[c] <= 1'b0;
                end else if (in_s2[c] == filt[c]) begin
                    fcnt[c] <= 3'd0;
                end else if ({1'b0, fcnt[c]} + 4'd1 >= flen) begin
                    filt[c] <= in_s2[c];
                    fcnt[c] <= 3'd0;
                end else begin
                    fcnt[c] <= fcnt[c] + 3'd1;
                end
            end

            wire rise    =  filt[c] & ~filt_d[c];
            wire fall    = ~filt[c] &  filt_d[c];
            wire edge_ok = m[5] ? (rise | fall) : (m[4] ? fall : rise);
            assign cap_evt[c] = is_cap & en & edge_ok;

            // Tham chieu OC. PWM lay tu CNT da chot -> tre 1 chu ky, deu nhau
            // cho moi kenh nen khong lech pha giua cac kenh.
            wire match = tick && (cnt == ccr[c]);
            always @(posedge pclk or negedge presetn) begin
                if (!presetn) begin
                    oc_ref[c] <= 1'b0;
                end else begin
                    case (m[2:0])
                        3'b001: if (match) oc_ref[c] <= 1'b1;
                        3'b010: if (match) oc_ref[c] <= 1'b0;
                        3'b011: if (match) oc_ref[c] <= ~oc_ref[c];
                        3'b100: oc_ref[c] <= 1'b0;
                        3'b101: oc_ref[c] <= 1'b1;
                        3'b110: oc_ref[c] <=  (cnt < ccr[c]);
                        3'b111: oc_ref[c] <= ~(cnt < ccr[c]);
                        default: ;                                   // frozen
                    endcase
                end
            end

            assign ch_o[c]  = oc_ref[c] ^ ccer[2*c+1];
            assign ch_oe[c] = en & ~is_cap;
        end
    endgenerate

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            in_s1  <= 4'd0;
            in_s2  <= 4'd0;
            filt_d <= 4'd0;
        end else begin
            in_s1  <= ch_i;
            in_s2  <= in_s1;
            filt_d <= filt;
        end
    end

    // -------------------------------------------------------------------------
    // Su kien -> SR
    // -------------------------------------------------------------------------
    integer n;
    reg [8:0] sr_set;
    reg [3:0] cap_now;
    always @(*) begin
        sr_set  = 9'd0;
        cap_now = 4'd0;
        sr_set[0] = overflow | ug;
        for (n = 0; n < 4; n = n + 1) begin
            if (ccmr[8*n+3]) begin
                // capture: chup lan nua khi co cu con dat -> over-capture
                cap_now[n]  = cap_evt[n] | (wr_egr & pwdata[n+1]);
                sr_set[n+1] = cap_now[n];
                sr_set[n+5] = cap_now[n] & sr[n+1];
            end else begin
                sr_set[n+1] = (tick && (cnt == ccr[n])) | (wr_egr & pwdata[n+1]);
            end
        end
    end

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            cen     <= 1'b0;
            opm     <= 1'b0;
            psc     <= 16'd0;
            arr     <= 32'hFFFF_FFFF;
            cnt     <= 32'd0;
            psc_cnt <= 16'd0;
            sr      <= 9'd0;
            dier    <= 5'd0;
            ccmr    <= 32'd0;
            ccer    <= 8'd0;
            for (n = 0; n < 4; n = n + 1) ccr[n] <= 32'd0;
            pready  <= 1'b0;
            prdata  <= 32'd0;
            pslverr <= 1'b0;
        end else begin
            pready  <= psel && penable;
            pslverr <= 1'b0;

            // --- bo dem ---
            if (ug) begin
                cnt     <= 32'd0;
                psc_cnt <= 16'd0;
            end else if (wr_cnt) begin
                cnt <= pwdata;
            end else if (cen) begin
                psc_cnt <= (psc_cnt == psc) ? 16'd0 : psc_cnt + 16'd1;
                if (tick)
                    cnt <= overflow ? 32'd0 : cnt + 32'd1;
            end

            if (wr_cr) begin
                cen <= pwdata[0];
                opm <= pwdata[1];
            end else if (overflow && opm) begin
                cen <= 1'b0;
            end

            // SR: W1C, su kien moi thang lenh xoa trong cung chu ky.
            sr <= (sr & ~(wr_sr ? pwdata[8:0] : 9'd0)) | sr_set;

            for (n = 0; n < 4; n = n + 1)
                if (cap_now[n])
                    ccr[n] <= cnt;

            if (wr_psc)  psc  <= pwdata[15:0];
            if (wr_arr)  arr  <= pwdata;
            if (wr_dier) dier <= pwdata[4:0];
            if (wr_ccmr) ccmr <= pwdata;
            if (wr_ccer) ccer <= pwdata[7:0];
            if (wr_ccr)  ccr[ccr_idx] <= pwdata;

            if (apb_write && !(wr_cr || wr_psc || wr_arr || wr_cnt || wr_sr ||
                               wr_dier || wr_egr || wr_ccmr || wr_ccer || wr_ccr))
                pslverr <= 1'b1;

            if (apb_read) begin
                case (a)
                    12'h000: prdata <= {30'd0, opm, cen};
                    12'h004: prdata <= {16'd0, psc};
                    12'h008: prdata <= arr;
                    12'h00C: prdata <= cnt;
                    12'h010: prdata <= {23'd0, sr};
                    12'h014: prdata <= {27'd0, dier};
                    12'h018: prdata <= 32'd0;
                    12'h01C: prdata <= ccmr;
                    12'h020: prdata <= {24'd0, ccer};
                    12'h024: prdata <= ccr[0];
                    12'h028: prdata <= ccr[1];
                    12'h02C: prdata <= ccr[2];
                    12'h030: prdata <= ccr[3];
                    default: begin prdata <= 32'd0; pslverr <= 1'b1; end
                endcase
            end
        end
    end

    assign irq = |(sr[4:0] & dier);

    wire _unused = &{1'b0, pstrb};

endmodule
