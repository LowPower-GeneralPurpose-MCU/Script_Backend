`timescale 1ns / 1ps

// =============================================================================
// SYSCON - dieu khien he thong: clock gating, ngu/thuc CPU, reset, boot, khoa
// debug.
//
// HAI MIEN RESET (2026-09-11)
//
//   presetn : warm reset = rst_n | watchdog | ndmreset | SW reset. Moi thanh
//             ghi "van hanh" (CLK_GATE_CTRL, trang thai ngu, APB) nam o day.
//   porn    : CHI chan rst_n (POR / nut reset). Cac thanh ghi phai SONG QUA
//             warm reset nam o day - neu khong chung vo nghia:
//               RESET_VECTOR - truoc day bi reset cung he thong, nen gia tri
//                 firmware ghi vao bi xoa dung luc no can co tac dung (C8).
//               RST_CAUSE    - sau mot watchdog reset firmware phai doc duoc
//                 rang do la watchdog reset.
//               SEC_CTRL     - khoa boot vector va khoa debug phai dinh toi POR,
//                 neu khong mot warm reset la mo khoa.
//
// REGISTER MAP (0x000 va 0x004 giu tuong thich firmware cu, Driver/inc/syscon.h)
//   0x000 RESET_VECTOR  RW   giu qua warm reset; ghi bi bo qua khi BOOT_LOCK
//   0x004 CLK_GATE_CTRL RW   [0] PWM [1] UART [2] SPI [3] I2C [4] GPIO
//                            [5] CORDIC [7] ASCON
//                            [8] UART1 [9] TIM0 [10] TIM1 (2026-09-11)
//                            [6] CHI DOC: clock Debug Module dang chay. Truoc
//                                day firmware tat duoc clock DM va tu khoa JTAG;
//                                nay DM tu bat/tat theo debugger (top_soc.v,
//                                clk_en_dbg), giong CDBGPWRUPREQ cua ARM.
//   0x008 RST_CAUSE     R/W1C giu qua warm reset; POR dat = 0x1
//                            [0] EXT  chan rst_n / POR
//                            [1] WDT  watchdog
//                            [2] NDM  debugger (dmcontrol.ndmreset)
//                            [3] SW   ghi SW_RESET
//                            Cac co CONG DON cho toi khi firmware ghi 1 de xoa.
//   0x00C SW_RESET      W    ghi DUNG 0x05FA_0001 -> warm reset toan chip tru
//                            Debug Module (nhu AIRCR.SYSRESETREQ, khoa 0x05FA
//                            chong ghi nham). Gia tri khac -> PSLVERR.
//   0x010 SEC_CTRL      RW1S giu qua warm reset; chi xoa bang POR
//                            [0] BOOT_LOCK  ghi 1: khoa RESET_VECTOR
//                            [1] DBG_OPEN   ghi 1: mo debug (chi tu UNDECIDED)
//                            [2] DBG_LOCK   ghi 1: khoa debug toi POR
//
// KHOA DEBUG (thay cho RDP cua STM32 - chip khong co OTP/option byte)
//
//   Sau POR debug o trang thai UNDECIDED: Debug Module bi GIU RESET (top_soc.v)
//   nen JTAG khong halt, khong doc bo nho, khong ndmreset duoc. Boot ROM co
//   DBG_DECIDE_CYCLES chu ky de chon:
//     ghi DBG_LOCK -> LOCKED, dinh toi POR (anh san pham)
//     ghi DBG_OPEN -> OPEN (anh phat trien, mo som)
//     khong ghi gi -> tu OPEN khi het cua so (ROM cu khong biet thanh ghi nay)
//   OPEN -> LOCKED van duoc (khoa them luc nao cung duoc); LOCKED -> OPEN thi
//   khong. Cua so cho la de dong lo POR: debugger co the xep san mot lenh DMI
//   haltreq, DM thuc hien no vai chu ky sau reset - TRUOC khi ROM kip khoa. Voi
//   UNDECIDED lenh do nam cho, va ROM dung cua so de khoa truoc.
//
//   Gioi han: khong co bit lifecycle trong OTP nen chinh sach nam trong ROM. ROM
//   da khoa thi anh phat trien cung khong debug duoc, va nguoc lai.
// =============================================================================
module apb_syscon #(
    parameter ADDR_WIDTH        = 12,
    parameter DATA_WIDTH        = 32,
    parameter [31:0] RESET_VECTOR_POR = 32'h0001_0000,   // boot ROM
    parameter DBG_DECIDE_CYCLES = 4096                    // 16.4 us o 250 MHz
)(
    input  wire                   pclk,
    input  wire                   presetn,   // warm reset
    input  wire                   porn,      // chi POR / chan rst_n
    input  wire [ADDR_WIDTH-1:0]  paddr,
    input  wire                   psel,
    input  wire                   penable,
    input  wire                   pwrite,
    input  wire [DATA_WIDTH-1:0]  pwdata,
    output reg                    pready,
    output reg  [DATA_WIDTH-1:0]  prdata,
    output reg                    pslverr,

    output wire [31:0]            o_reset_vector,

    // Ngu / thuc CPU
    input  wire                   i_wfi_sleep,
    input  wire                   i_ext_irq,
    input  wire                   i_dbg_halt_req,  // haltreq cua DM: su kien danh thuc
    input  wire                   i_dbg_keep_clk,  // DBGCTRL.DBG_SLEEP cua DM

    // Reset
    input  wire                   i_wdt_rst,
    input  wire                   i_ndm_rst,
    output reg                    o_sw_rst_req,

    // Debug
    input  wire                   i_dbg_clk_on,    // clk_en_dbg, doc o CLK_GATE_CTRL[6]
    output wire                   o_dbg_allow,     // 0 -> top_soc giu DM trong reset

    output wire                   o_cpu_clk_en,
    output wire                   o_pwm_clk_en,
    output wire                   o_urt_clk_en,
    output wire                   o_spi_clk_en,
    output wire                   o_i2c_clk_en,
    output wire                   o_gpo_clk_en,
    output wire                   o_acc_clk_en,
    output wire                   o_asc_clk_en,
    output wire                   o_ur1_clk_en,
    output wire                   o_tm0_clk_en,
    output wire                   o_tm1_clk_en
);

    localparam [31:0] SW_RESET_KEY = 32'h05FA_0001;

    localparam [1:0] DBG_UNDECIDED = 2'b00;
    localparam [1:0] DBG_OPEN      = 2'b01;
    localparam [1:0] DBG_LOCKED    = 2'b11;

    localparam DBG_TMR_W = $clog2(DBG_DECIDE_CYCLES) + 1;
    localparam [DBG_TMR_W-1:0] DBG_TMR_LAST = DBG_DECIDE_CYCLES - 1;

    wire apb_write = psel && penable && pwrite;
    wire apb_read  = psel && penable && !pwrite;

    wire wr_vector = apb_write && (paddr[11:0] == 12'h000);
    wire wr_cause  = apb_write && (paddr[11:0] == 12'h008);
    wire wr_swrst  = apb_write && (paddr[11:0] == 12'h00C) && (pwdata == SW_RESET_KEY);
    wire wr_sec    = apb_write && (paddr[11:0] == 12'h010);

    // =========================================================================
    // MIEN POR - song qua warm reset
    // =========================================================================
    reg [31:0]          reset_vector_q;
    reg [3:0]           rst_cause_q;
    reg                 boot_lock_q;
    reg [1:0]           dbg_state_q;
    reg [DBG_TMR_W-1:0] dbg_tmr_q;

    wire [3:0] rst_cause_set = {wr_swrst, i_ndm_rst, i_wdt_rst, 1'b0};

    always @(posedge pclk or negedge porn) begin
        if (!porn) begin
            reset_vector_q <= RESET_VECTOR_POR;
            rst_cause_q    <= 4'b0001;          // EXT
            boot_lock_q    <= 1'b0;
            dbg_state_q    <= DBG_UNDECIDED;
            dbg_tmr_q      <= {DBG_TMR_W{1'b0}};
        end else begin
            if (wr_vector && !boot_lock_q)
                reset_vector_q <= pwdata;

            // Co moi dat thang co xoa trong cung chu ky.
            rst_cause_q <= (rst_cause_q & ~(wr_cause ? pwdata[3:0] : 4'b0)) | rst_cause_set;

            if (wr_sec && pwdata[0])
                boot_lock_q <= 1'b1;

            case (dbg_state_q)
                DBG_UNDECIDED: begin
                    if (wr_sec && pwdata[2])
                        dbg_state_q <= DBG_LOCKED;
                    else if ((wr_sec && pwdata[1]) || (dbg_tmr_q == DBG_TMR_LAST))
                        dbg_state_q <= DBG_OPEN;
                    dbg_tmr_q <= dbg_tmr_q + 1'b1;
                end
                DBG_OPEN: begin
                    if (wr_sec && pwdata[2])
                        dbg_state_q <= DBG_LOCKED;
                end
                default: dbg_state_q <= DBG_LOCKED;   // LOCKED dinh toi POR
            endcase
        end
    end

    assign o_reset_vector = reset_vector_q;
    assign o_dbg_allow    = (dbg_state_q == DBG_OPEN);

    // =========================================================================
    // MIEN WARM RESET
    // =========================================================================
    reg [10:0] clk_gate_reg;
    reg       cpu_sleep_state;

    // -------------------------------------------------------------------------
    // Ngu / thuc CPU.
    //
    // Ban cu chi thuc khi co ngat. Nhung haltreq cua debugger vao core qua
    // clk_cpu - chinh clock dang tat - nen debugger KHONG halt duoc mot core
    // dang WFI. Nay haltreq cung la su kien danh thuc (nhu Cortex-M: C_HALT la
    // wake-up event), va core xoa trang thai ngu khi thay haltreq
    // (pipeline_control_unit.v). DBG_SLEEP cua DM giu clock suot luc ngu, nhu
    // DBGMCU_CR.DBG_SLEEP.
    // -------------------------------------------------------------------------
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            cpu_sleep_state <= 1'b0;
        end else begin
            if (i_ext_irq || i_dbg_halt_req) begin
                cpu_sleep_state <= 1'b0;
            end else if (i_wfi_sleep) begin
                cpu_sleep_state <= 1'b1;
            end
        end
    end

    assign o_cpu_clk_en = ~cpu_sleep_state | i_dbg_keep_clk;

    assign o_pwm_clk_en = clk_gate_reg[0];
    assign o_urt_clk_en = clk_gate_reg[1];
    assign o_spi_clk_en = clk_gate_reg[2];
    assign o_i2c_clk_en = clk_gate_reg[3];
    assign o_gpo_clk_en = clk_gate_reg[4];
    assign o_acc_clk_en = clk_gate_reg[5];
    assign o_asc_clk_en = clk_gate_reg[7];
    assign o_ur1_clk_en = clk_gate_reg[8];
    assign o_tm0_clk_en = clk_gate_reg[9];
    assign o_tm1_clk_en = clk_gate_reg[10];

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            // Mac dinh luc boot: UART, PWM bat. Bit 6 khong con dung (chi doc).
            // Bit 7 (ASCON) TAT sau reset - clock cua no do o_active/psel giu.
            // Bit 8-10 (UART1, TIM0, TIM1) TAT sau reset nhu SPI/I2C.
            clk_gate_reg   <= 11'b000_0000_0011;
            o_sw_rst_req   <= 1'b0;
            pready         <= 1'b0;
            prdata         <= 32'b0;
            pslverr        <= 1'b0;
        end else begin
            pready  <= psel && penable;
            pslverr <= 1'b0;

            // Giu muc 1 cho toi khi warm reset xoa chinh no.
            if (wr_swrst)
                o_sw_rst_req <= 1'b1;

            if (apb_write) begin
                case (paddr[11:0])
                    12'h000: ;                                  // mien POR
                    12'h004: clk_gate_reg <= pwdata[10:0];
                    12'h008: ;                                  // mien POR
                    12'h00C: if (pwdata != SW_RESET_KEY) pslverr <= 1'b1;
                    12'h010: ;                                  // mien POR
                    default: pslverr <= 1'b1;
                endcase
            end

            if (apb_read) begin
                case (paddr[11:0])
                    12'h000: prdata <= reset_vector_q;
                    12'h004: prdata <= {21'b0, clk_gate_reg[10:7], i_dbg_clk_on, clk_gate_reg[5:0]};
                    12'h008: prdata <= {28'b0, rst_cause_q};
                    12'h00C: prdata <= 32'h0;
                    12'h010: prdata <= {29'b0, dbg_state_q == DBG_LOCKED, dbg_state_q == DBG_OPEN, boot_lock_q};
                    default: begin prdata <= 32'h0; pslverr <= 1'b1; end
                endcase
            end
        end
    end
endmodule
