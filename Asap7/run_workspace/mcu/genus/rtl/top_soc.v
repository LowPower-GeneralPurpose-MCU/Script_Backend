`timescale 1ns / 1ps

// =============================================================================
// MOT CLOCK DUY NHAT (2026-09-11)
//
// Toan bo SoC - CPU, cache, AXI, APB, DMA, ngoai vi - chay bang `clk` 250 MHz.
// Truoc day chip co 8 clock vao (clk_core 400, clk_axi 200, clk_apb 100,
// clk_sdram_ext, uart_clk, spi_clk, i2c_clk, rtc_clk) va SDC xu ly moi duong
// giua chung bang `set_clock_groups -asynchronous`, tuc BO timing ca nhung
// duong van can rang buoc (con tro Gray cua async FIFO, bus debug tua-tinh).
// Nay khong con CDC noi bo nao: hai axi_async_bridge, apb_async_bridge, cac
// async_fifo trong UART/SPI/I2C, ~30 cdc_sync_bit va 8 reset_sync theo mien
// deu da bo.
//
// Nhung gi CON dung bo dong bo, va vi sao:
//   * TCK (JTAG) - clock ngoai tu debugger, ban chat bat dong bo. Handshake DMI
//     trong rv_jtag_dtm / rv_debug_module_sba (req/resp qua 3FF) la CDC duy
//     nhat con lai; constraint.sdc rang buoc no bang false_path o tang sync dau
//     + max_delay tren bus du lieu DMI, KHONG dung -asynchronous.
//   * rtc_clk - khong con la clock: la chan vao duoc lay mau 2FF roi bat canh,
//     thanh `rtc_tick` cho CLINT va watchdog (xem muc 1).
//   * Cac chan vao ngoai (uart_rx, spi_miso, i2c sda, rst_n) - dong bo chan vao
//     nhu cu. Do khong phai CDC giua hai mien clock.
//
// Clock gating van giu (cg_*), vi ICG tren cung mot clock goc la DONG BO: STA
// tinh xuyen qua cong, khong can clock group.
// =============================================================================
module top_soc (
    // --- Xung nhip ---
    input  wire        clk,        // 250 MHz - clock he thong duy nhat
    input  wire        rtc_clk,    // 32.768 kHz - chan vao, lay mau bang clk

    input  wire        rst_n,

    // JTAG
    input  wire        tck,
    input  wire        trst_n,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,

    // -------------------------------------------------------------------------
    // 32 PAD DA NANG PA0..PA31 (2026-09-11) - thay cho chan rieng cua UART, SPI,
    // I2C, PWM va 32 GPIO. Chuc nang cua tung pad chon trong apb_pinmux.v (bang
    // AF co dinh). Mac dinh sau reset: PA0 = UART0_TX, PA1 = UART0_RX, con lai
    // la GPIO vao. Bo ba in/out/oe noi thang vao pad cell cua pad ring.
    // -------------------------------------------------------------------------
    input  wire [31:0] pad_in,
    output wire [31:0] pad_out,
    output wire [31:0] pad_oe,

    output wire        flash_sck,
    output wire        flash_cs_n,
    input  wire [3:0]  flash_io_i,
    output wire [3:0]  flash_io_o,
    output wire [3:0]  flash_io_oe,

    output wire        sdram_clk,
    output wire        sdram_cke,
    output wire        sdram_cs_n,
    output wire        sdram_ras_n,
    output wire        sdram_cas_n,
    output wire        sdram_we_n,
    output wire [1:0]  sdram_ba,
    output wire [12:0] sdram_addr,
    input  wire [15:0] sdram_dq_i,
    output wire [15:0] sdram_dq_o,
    output wire        sdram_dq_oe,
    output wire [1:0]  sdram_dqm
);
    // -------------------------------------------------------------------------
    // Clock SDRAM: `clk` DAO PHA, xuat ra chan.
    //
    // Controller doi lenh/dia chi/du lieu o canh LEN cua clk; chip SDRAM chot o
    // canh len cua sdram_clk = canh XUONG cua clk, tuc giua chu ky - nua chu ky
    // (2 ns) cho setup va nua chu ky cho hold. Truoc day vai tro nay do
    // clk_sdram_ext lech pha 180 do tu ben ngoai dam nhan; nay no la clock SINH
    // RA tu clk (create_generated_clock -invert trong constraint.sdc), cung goc
    // nen dong bo.
    //
    // CANH BAO: SDR SDRAM thong dung toi da 166-200 MHz. Chay 250 MHz can chip
    // co speed grade du, hoac mot buoc sau lam half-rate (controller chay bang
    // clock-enable, sdram_clk = clk/2). Tham so thoi gian cua controller da doi
    // sang so chu ky dung o 4 ns - xem u_axi_sdram.
    // -------------------------------------------------------------------------
    assign sdram_clk = ~clk;

    // =========================================================================
    // 1. RESET
    // =========================================================================
    wire wdt_rst;
    wire ndmreset_req;
    wire sw_rst_req;      // SYSCON SW_RESET (nhu AIRCR.SYSRESETREQ)
    wire dbg_allow;       // SYSCON SEC_CTRL: 0 -> Debug Module bi giu reset

    // -------------------------------------------------------------------------
    // BO DIEU KHIEN RESET
    //
    // Ban cu:  wire reset_sys_n_raw = rst_n & ~ndmreset_req & ~wdt_rst;
    //
    // Hai loi trong mot dong:
    //
    // 1. VONG PHAN HOI QUA CHINH CAY RESET. `wdt_rst` la mot flop o mien rtc_clk
    //    duoc reset boi rtc_rst_n, ma rtc_rst_n lai DAN XUAT TU reset_sys_n_raw.
    //    Nen: wdt_rst len -> reset he thong -> reset watchdog -> wdt_rst tu xoa
    //    -> reset nha. Do rong xung reset khong xac dinh, phu thuoc do tre cay
    //    clock, va co the qua ngan de reset dut diem mien 400 MHz. `ndmreset_req`
    //    dinh y het: no reset chinh Debug Module da phat ra no, nen lenh
    //    `reset halt` cua OpenOCD tu huy giua chung.
    //
    // 2. HAI TIN HIEU duoc AND to hop roi dua thang vao chan reset BAT DONG BO
    //    toan chip. Mot xung glitch tren duong do reset ca chip.
    //
    // Cach sua: mot bo keo dai chay bang clk va CHI reset boi chan rst_n NGOAI -
    // no khong nam trong mien ma no reset, nen khong the tu xoa minh.
    //
    // Hai duong ra rieng biet:
    //   sysrst_n_q : co ndmreset    -> reset lo, bus, ngoai vi (tat ca tru DM)
    //   dmrst_n_q  : KHONG ndmreset -> reset Debug Module
    // Dac ta RISC-V Debug noi ro: ndmreset reset "moi thu TRU Debug Module".
    // Neu DM tu reset minh thi thanh ghi dmcontrol bi xoa ngay giua lenh reset.
    //
    // wdt_rst va ndmreset_req deu la flop chay bang clk (watchdog va DM gio
    // cung mien), nen doc thang - hai bo cdc_sync_bit truoc day da bo.
    // -------------------------------------------------------------------------

    // 64 chu ky clk = 256 ns. Khong con mien clock cham nao phai cho bat reset.
    localparam [5:0] RST_STRETCH = 6'd63;

    reg [5:0] sysrst_cnt;
    reg       sysrst_n_q;
    reg [5:0] dmrst_cnt;
    reg       dmrst_n_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sysrst_cnt <= RST_STRETCH;
            sysrst_n_q <= 1'b0;
            dmrst_cnt  <= RST_STRETCH;
            dmrst_n_q  <= 1'b0;
        end else begin
            // --- reset he thong: watchdog, ndmreset HOAC SW reset ---
            if (wdt_rst | ndmreset_req | sw_rst_req) begin
                sysrst_cnt <= RST_STRETCH;
                sysrst_n_q <= 1'b0;
            end else if (sysrst_cnt != 6'd0) begin
                sysrst_cnt <= sysrst_cnt - 6'd1;
                sysrst_n_q <= 1'b0;
            end else begin
                sysrst_n_q <= 1'b1;
            end

            // --- reset Debug Module: CHI watchdog, khong co ndmreset ---
            if (wdt_rst) begin
                dmrst_cnt <= RST_STRETCH;
                dmrst_n_q <= 1'b0;
            end else if (dmrst_cnt != 6'd0) begin
                dmrst_cnt <= dmrst_cnt - 6'd1;
                dmrst_n_q <= 1'b0;
            end else begin
                dmrst_n_q <= 1'b1;
            end
        end
    end

    wire reset_sys_n_raw = rst_n & sysrst_n_q;
    // Debug Module con bi giu reset khi SYSCON chua cho phep debug (SEC_CTRL:
    // UNDECIDED sau POR, hoac LOCKED) - xem ghi chu KHOA DEBUG trong
    // apb_syscon.v. DM trong reset thi haltreq, ndmreset, SBA deu bang 0.
    wire reset_dm_n_raw  = rst_n & dmrst_n_q & dbg_allow;

    // Ba reset_sync, cung mot clock: he thong (warm), Debug Module (song sot
    // qua ndmreset - xem ghi chu tren), va POR (chi chan rst_n) cho cac thanh
    // ghi SYSCON phai song qua warm reset: RESET_VECTOR, RST_CAUSE, SEC_CTRL.
    wire reset_sys_n;
    wire reset_dbg_n;
    wire reset_por_n;
    reset_sync u_sys_rst_sync (.clk(clk), .rst_in_n(reset_sys_n_raw), .rst_out_n(reset_sys_n));
    reset_sync u_dbg_rst_sync (.clk(clk), .rst_in_n(reset_dm_n_raw),  .rst_out_n(reset_dbg_n));
    reset_sync u_por_rst_sync (.clk(clk), .rst_in_n(rst_n),           .rst_out_n(reset_por_n));

    // -------------------------------------------------------------------------
    // RTC TICK: chan rtc_clk -> xung mot chu ky clk moi chu ky RTC.
    //
    // rtc_clk khong con clock bat ky flop nao. No duoc lay mau nhu mot chan vao
    // bat dong bo (2FF - dong bo CHAN VAO, khong phai CDC giua hai mien) roi
    // bat canh len. CLINT tang mtime va watchdog giam bo dem theo xung nay, nen
    // tan so cua chung van la 32.768 kHz dung nhu RTC_CLOCK_HZ trong firmware.
    // 250 MHz / 32.768 kHz ~ 7629 mau moi chu ky RTC: khong the bo sot canh.
    // -------------------------------------------------------------------------
    wire rtc_in_s;
    reg  rtc_in_d;
    cdc_sync_bit u_sync_rtc_pin (.clk_dst(clk), .rst_dst_n(reset_sys_n),
                                 .d_in(rtc_clk), .q_out(rtc_in_s));
    always @(posedge clk or negedge reset_sys_n) begin
        if (!reset_sys_n) rtc_in_d <= 1'b0;
        else              rtc_in_d <= rtc_in_s;
    end
    wire rtc_tick = rtc_in_s & ~rtc_in_d;

    // =========================================================================
    // 2. CLOCK GATING NETWORK
    // =========================================================================
    wire clk_en_cpu, clk_en_dbg, clk_en_pwm, clk_en_uart;
    wire clk_en_spi, clk_en_i2c, clk_en_gpio, clk_en_acc, clk_en_asc;
    wire clk_en_uart1, clk_en_tim0, clk_en_tim1;

    wire clk_cpu, clk_dbg, clk_pwm, clk_gpio, clk_cordic, clk_ascon;
    wire clk_uart, clk_spi, clk_i2c;
    wire clk_uart1, clk_tim0, clk_tim1;

    // -------------------------------------------------------------------------
    // ENABLE cua clock gate: noi THANG, khong dong bo.
    //
    // Moi `clk_en_*` la flop trong apb_syscon, chay bang clk - chinh clock goc
    // cua moi cong. Latch cua clock_gate trong suot khi clk THAP, nen enable
    // doi o canh len duoc chot on dinh truoc canh len ke tiep; STA kiem duong
    // nay bang clock-gating check. Truoc day enable den tu clk_apb 100 MHz va
    // phai qua 2FF vao tung mien dich; cung mot clock thi 2FF do chi con la tre.
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // GIU CLOCK MO KHI NGOAI VI DANG BI TRUY CAP.
    //
    // apb_gpio / apb_pwm / apb_cordic / apb_ascon, va tu 2026-09-11 ca
    // apb_uart / apb_spi / apb_i2c, dat CA giao dien thanh ghi APB len clock DA
    // GATE (.pclk(clk_gpio) ...), va CLK_GATE_CTRL reset ve 8'b0100_0011 - tuc
    // SPI, I2C, GPIO, CORDIC, ASCON TAT ngay sau reset.
    //
    // Hau qua: `pready` cua chung la flop tren clock da dung -> khong bao gio len
    // 1. apb_interconnect chon slave theo dia chi roi CHO VO HAN (default-slave
    // chi cuu duoc khi KHONG match dia chi nao). APB treo -> axi_to_apb_bridge
    // treo -> D-cache treo -> CPU treo VINH VIEN. Truy cap GPIO dau tien sau
    // reset la du de chet chip.
    //
    // Sua ma VAN GIU duoc gating: mo cong bat cu khi nao ngoai vi do dang duoc
    // chon. `*_clk_req` keo dai them 2 chu ky sau khi PSEL ha, vi `pready` la
    // flop - neu cat clock ngay khi PSEL ha thi pready DONG BANG o 1, va giao
    // dich KE TIEP se bi interconnect coi la xong ngay o pha SETUP.
    //
    // Khong can dong bo o day: nguon (psel) va dich (clk) cung mot mien.
    //
    // UART / SPI / I2C: truoc day chi LOI ngoai vi (tren uart_clk/spi_clk/
    // i2c_clk rieng) bi gate, con giao dien APB chay clk_apb luon song. Nay ca
    // module mot clock, nen gate ca module va dung cung co che psel nay de APB
    // khong bao gio treo. Nghia cua bit CLK_GATE_CTRL giu nguyen: bit tat thi
    // loi ngung chay (TX/RX/SPI/I2C dung), truy cap thanh ghi van duoc.
    // -------------------------------------------------------------------------
    wire gpio_clk_req;
    wire pwm_clk_req;
    wire cordic_clk_req;
    wire cordic_active;   // loi CORDIC dang chay - phai giu clock cho no
    wire ascon_clk_req;
    wire ascon_active;    // ASCON/TRNG dang chay - cung phai giu clock
    wire uart_clk_req;
    wire spi_clk_req;
    wire i2c_clk_req;
    wire uart1_clk_req;
    wire tim0_clk_req;
    wire tim1_clk_req;

    // CPU: tat khi WFI (xem wfi_sleep_q)
    clock_gate cg_cpu   (.clk_in(clk), .en(clk_en_cpu),                   .test_en(1'b0), .clk_out(clk_cpu));
    // Debug Module - enable do DEBUGGER quyet dinh, xem clk_en_dbg o muc 6
    clock_gate cg_dbg   (.clk_in(clk), .en(clk_en_dbg),                   .test_en(1'b0), .clk_out(clk_dbg));
    // Ngoai vi APB - mo cong khi dang bi truy cap
    clock_gate cg_pwm   (.clk_in(clk), .en(clk_en_pwm  | pwm_clk_req),    .test_en(1'b0), .clk_out(clk_pwm));
    clock_gate cg_gpio  (.clk_in(clk), .en(clk_en_gpio | gpio_clk_req),   .test_en(1'b0), .clk_out(clk_gpio));
    clock_gate cg_cordic(.clk_in(clk), .en(clk_en_acc  | cordic_clk_req), .test_en(1'b0), .clk_out(clk_cordic));
    clock_gate cg_ascon (.clk_in(clk), .en(clk_en_asc  | ascon_clk_req),  .test_en(1'b0), .clk_out(clk_ascon));
    clock_gate cg_uart  (.clk_in(clk), .en(clk_en_uart | uart_clk_req),   .test_en(1'b0), .clk_out(clk_uart));
    clock_gate cg_spi   (.clk_in(clk), .en(clk_en_spi  | spi_clk_req),    .test_en(1'b0), .clk_out(clk_spi));
    clock_gate cg_i2c   (.clk_in(clk), .en(clk_en_i2c  | i2c_clk_req),    .test_en(1'b0), .clk_out(clk_i2c));
    // 2026-09-11 - UART1, TIM0, TIM1: cung co che voi UART0 (CLK_GATE_CTRL
    // [8]/[9]/[10] hoac dang bi truy cap). Timer tat bit thi bo dem dung - dung
    // nghia "gate ca ngoai vi" nhu PWM.
    clock_gate cg_uart1 (.clk_in(clk), .en(clk_en_uart1 | uart1_clk_req), .test_en(1'b0), .clk_out(clk_uart1));
    clock_gate cg_tim0  (.clk_in(clk), .en(clk_en_tim0  | tim0_clk_req),  .test_en(1'b0), .clk_out(clk_tim0));
    clock_gate cg_tim1  (.clk_in(clk), .en(clk_en_tim1  | tim1_clk_req),  .test_en(1'b0), .clk_out(clk_tim1));

    // =========================================================================
    // 3. TÍN HIỆU NGẮT
    //
    // Tat ca nguon ngat va yeu cau DMA gio cung mien clk voi noi nhan (CPU,
    // PLIC, DMA), nen noi thang. Truoc day moi duong co mot cdc_sync_bit 2FF.
    // =========================================================================
    wire [0:0] cpu_msip_raw;
    wire [0:0] cpu_mtip_raw;

    // CLIC -> core (xem interrupt/clic/clic.v va muc 9 ben duoi)
    wire       clic_irq_valid;
    wire [4:0] clic_irq_id;
    wire [7:0] clic_irq_level;
    wire       clic_irq_shv;
    wire       clic_ack;
    wire [4:0] clic_ack_id;

    // Danh thuc clock CPU: moi ngat CLIC dang cho va da enable, cong msip/mtip
    // cho che do CLINT. Den thua mot chut (core con so muc voi mil/mintthresh)
    // chi ton mot lan mo clock, khong the ket.
    wire cpu_irq_wake = clic_irq_valid | cpu_mtip_raw[0] | cpu_msip_raw[0];

    wire uart_irq, gpio_irq, spi_irq, i2c_irq, wdt_irq, ascon_irq;
    wire uart1_irq, tim0_irq, tim1_irq;
    wire uart_dma_tx, uart_dma_rx, spi_dma_tx, spi_dma_rx, i2c_dma_tx, i2c_dma_rx;
    wire uart1_dma_tx, uart1_dma_rx;

    wire [3:0] dma_irq;

    // PLIC source 7 - bus fault on a BUFFERED D-cache store.
    //
    // With a store buffer a cacheable store retires before its BRESP comes
    // back, so this fault cannot be a synchronous exception any more: mepc
    // would point at the wrong instruction.  It is reported as an interrupt
    // instead, the way most MCUs report an imprecise bus fault.  Uncached
    // stores (MMIO, CLINT, the DMA pool) are never buffered and keep the
    // precise mcause-7 path through `dcache_error`.
    //
    // Raised in clk_cpu, consumed by the CLIC in clk - the same clock tree, so
    // it is wired straight through.  dcache.v still stretches the pulse to 256
    // cycles; the CLIC treats source 26 as rising-edge by default, so the
    // stretch is harmless and a late ISR cannot miss it.
    wire dc_sb_error;

    // DMA request: UART1 lay slot 7/8 (periph_num 7/8 trong DMA CTRL).
    wire [31:1] periph_dma_req = { 23'd0, uart1_dma_rx, uart1_dma_tx,
                                   i2c_dma_rx, i2c_dma_tx, spi_dma_rx, spi_dma_tx, uart_dma_rx, uart_dma_tx };
    wire [31:1] periph_dma_clr;

    // -------------------------------------------------------------------------
    // Nguon ngat CLIC - ID = vi tri bit (bang ID cung nam o dau clic.v).
    //   0-2, 4-6, 8-15 : de trong (0-15 danh cho ngat chuan cua RISC-V)
    //   3 msip  7 mtip (tu CLINT - dung o che do CLIC; che do CLINT van qua mie)
    //   16 UART0 17 UART1 18 GPIO 19 SPI 20 I2C 21 WDT
    //   22..25 DMA kenh 0..3 - MOI KENH MOT NGUON (truoc day |dma_irq)
    //   26 loi store buffer D$  27 ASCON  28 TIM0  29 TIM1
    // -------------------------------------------------------------------------
    wire [31:0] clic_irq_src;
    assign clic_irq_src[2:0]   = 3'd0;
    assign clic_irq_src[3]     = cpu_msip_raw[0];
    assign clic_irq_src[6:4]   = 3'd0;
    assign clic_irq_src[7]     = cpu_mtip_raw[0];
    assign clic_irq_src[15:8]  = 8'd0;
    assign clic_irq_src[16]    = uart_irq;
    assign clic_irq_src[17]    = uart1_irq;
    assign clic_irq_src[18]    = gpio_irq;
    assign clic_irq_src[19]    = spi_irq;
    assign clic_irq_src[20]    = i2c_irq;
    assign clic_irq_src[21]    = wdt_irq;
    assign clic_irq_src[25:22] = dma_irq;
    assign clic_irq_src[26]    = dc_sb_error;
    assign clic_irq_src[27]    = ascon_irq;
    assign clic_irq_src[28]    = tim0_irq;
    assign clic_irq_src[29]    = tim1_irq;
    assign clic_irq_src[31:30] = 2'd0;

    wire [31:0] syscon_reset_vector;
    // -------------------------------------------------------------------------
    // WFI chi duoc phep TAT CLOCK khi bus da rong.
    //
    // Truoc day `wfi_sleep_state` di thang toi syscon -> clk_en_cpu -> tat
    // clk_cpu. Nhung `wfi_sleep_state` len ngay khi tang ID giai ma duoc lenh
    // WFI, KHONG he biet I-cache hay D-cache co dang giu mot giao dich AXI do
    // dang hay khong. Va I-cache thi phat yeu cau lien tuc, nen kha nang do rat
    // cao.
    //
    // Neu clk_cpu dung giua mot burst doc: I-cache khong bao gio dua RREADY len
    // nua -> slave dang tra burst do bi ket o R, va cac master khac (DMA,
    // debug) doc cung slave don lai phia sau cho toi khi treo ca bus.
    //
    // `*_stall` cua hai cache len trong suot moi giao dich va chi ha khi giao
    // dich xong, nen `~stall` chinh la dieu kien "khong con gi outstanding".
    // Chot lai bang mot flop chay bang clk_cpu (tuc no tu dong bang khi clock
    // tat, va cap nhat lai ngay khi clock quay lai luc thuc day).
    // -------------------------------------------------------------------------
    wire        wfi_sleep_state;

    // Khoi always dat o muc 4, sau khi cpu_inst_stall / cpu_data_stall duoc khai bao.
    // Di thang toi apb_syscon (cung mien clk).
    reg  wfi_sleep_q;

    // =========================================================================
    // 4. LÕI CPU VÀ CACHES (Chạy bằng clk_cpu đã qua Gating)
    // =========================================================================
    wire [31:0] cpu_inst_addr, cpu_inst_data, cpu_data_addr, cpu_data_wdata, cpu_data_rdata;
    // R1b - bat tay hai chu ky cho lenh nguyen tu (memory/dcache.v, pipeline_stage.v)
    wire        cpu_data_amo_req;
    wire        cpu_data_amo_capture;
    wire cpu_inst_req, cpu_inst_hit, cpu_inst_stall, cpu_data_rd_req, cpu_data_wr_req, cpu_data_hit, cpu_data_stall, cpu_data_unsigned;
    // P2c - `fence` tu tang MEM cua core toi D-cache.  Xem cpu_fence trong
    // memory/dcache.v va nhanh 7'b0001111 trong core/block_unit/control_unit.v.
    wire cpu_data_fence;
    wire cpu_inst_error, cpu_data_error;   // C1 - loi bus tu cache ve core
    wire [1:0] cpu_data_size;
    wire dbg_halt_req, dbg_resume_req, dbg_halted, dbg_reg_write_en;
    wire [15:0] dbg_reg_read_addr, dbg_reg_write_addr;
    wire [31:0] dbg_reg_read_data, dbg_reg_write_data;

    // WFI chi duoc phep tat clock khi ca hai cache da rong - xem ghi chu day du
    // o cho khai bao wfi_sleep_q (muc 3).
    always @(posedge clk_cpu or negedge reset_sys_n) begin
        if (!reset_sys_n) wfi_sleep_q <= 1'b0;
        else wfi_sleep_q <= wfi_sleep_state & ~cpu_inst_stall & ~cpu_data_stall;
    end

    // --- Debug Module <-> CPU: halt / resume / halted ---
    // clk_dbg va clk_cpu la hai nhanh DA GATE cua cung clk, nen noi thang.
    // Truoc day moi duong qua 2FF vi DM chay 200 MHz con CPU 400 MHz.
    wire dbg_halt_req_raw, dbg_resume_req_raw;
    wire dbg_halted_raw;

    // -------------------------------------------------------------------------
    // Duong GHI thanh ghi qua Debug Module.
    //
    // Bus addr/data (dbg_reg_write_addr/data) va write_en gio cung mot clock
    // goc, nen STA kiem day du ca ba - het cai gia dinh "tua-tinh" khong ai
    // rang buoc cua ban cu.
    //
    // Van giu bo BAT CANH LEN: DM giu write_en suot giao dich abstract-command
    // (nhieu chu ky), con CPU phai thay DUNG MOT xung - CSR co tac dung phu
    // hoac bo dem se sai neu bi ghi hai lan. Flop bat canh chay bang clk_cpu:
    // neu CPU dang tat clock (WFI) thi no dong bang cung CPU.
    // -------------------------------------------------------------------------
    wire dbg_reg_write_en_raw;
    reg  dbg_reg_write_en_d;

    always @(posedge clk_cpu or negedge reset_sys_n) begin
        if (!reset_sys_n) dbg_reg_write_en_d <= 1'b0;
        else              dbg_reg_write_en_d <= dbg_reg_write_en_raw;
    end

    // Xung dung MOT chu ky clk_cpu tren canh len.
    assign dbg_reg_write_en = dbg_reg_write_en_raw & ~dbg_reg_write_en_d;

    riscv_pipeline u_core (
        .clk                (clk_cpu),
        .reset_n            (reset_sys_n),
        .riscv_start        (1'b1),
        // PLIC da bo (2026-09-11): ngat ngoai chi con qua CLIC (mtvec.mode = 11).
        .meip_i             (1'b0),
        .msip_i             (cpu_msip_raw[0]),
        .mtip_i             (cpu_mtip_raw[0]),
        .clic_irq_valid_i   (clic_irq_valid),
        .clic_irq_id_i      (clic_irq_id),
        .clic_irq_level_i   (clic_irq_level),
        .clic_irq_shv_i     (clic_irq_shv),
        .clic_ack_o         (clic_ack),
        .clic_ack_id_o      (clic_ack_id),
        .reset_vector_in    (syscon_reset_vector),
        .riscv_done         (),
        .icache_read_req    (cpu_inst_req),
        .icache_addr        (cpu_inst_addr),
        .icache_read_data   (cpu_inst_data),
        .icache_hit         (cpu_inst_hit),
        .icache_stall       (cpu_inst_stall),
        .icache_error       (cpu_inst_error),
        .icache_read_req_lane1(),
        .icache_addr_lane1  (),
        .icache_read_data_lane1(32'b0),
        .icache_hit_lane1   (1'b0),
        .icache_stall_lane1 (1'b0),
        .dcache_read_req    (cpu_data_rd_req),
        .dcache_write_req   (cpu_data_wr_req),
        .dcache_fence       (cpu_data_fence),
        .dcache_addr        (cpu_data_addr),
        .dcache_write_data  (cpu_data_wdata),
        .dcache_read_data   (cpu_data_rdata),
        // R1b - bat tay hai chu ky cho AMO (xem ghi chu trong memory/dcache.v)
        .dcache_amo_req     (cpu_data_amo_req),
        .dcache_amo_capture (cpu_data_amo_capture),
        .dcache_hit         (cpu_data_hit),
        .dcache_stall       (cpu_data_stall),
        .dcache_error       (cpu_data_error),
        .mem_size_top       (cpu_data_size),
        .mem_unsigned_top   (cpu_data_unsigned),
        .wfi_sleep_out      (wfi_sleep_state),
        .dbg_halt_req       (dbg_halt_req_raw),
        .dbg_resume_req     (dbg_resume_req_raw),
        .dbg_halted         (dbg_halted_raw),
        .dbg_reg_read_addr  (dbg_reg_read_addr),
        .dbg_reg_read_data  (dbg_reg_read_data),
        .dbg_reg_write_en   (dbg_reg_write_en),
        .dbg_reg_write_addr (dbg_reg_write_addr),
        .dbg_reg_write_data (dbg_reg_write_data)
    );

    // =========================================================================
    // 5. KHAI BÁO CÁC KÊNH AXI CHI TIẾT (Không viết tắt)
    // =========================================================================
    localparam MST_AMT = 4;
    // Slave 1 and slave 6 are the two halves of system RAM.  They are separate
    // slave ports on purpose: the bank decode inside one axi_ram serialises, so
    // only distinct ports let a CPU access and a DMA access proceed together.
    localparam SLV_AMT = 7;
    localparam MST_ID_WIDTH = 5;
    // Số read burst outstanding tối đa mà interconnect theo dõi cho mỗi master.
    // Ràng buộc thật của hệ thống: DMA read master có CMD_DEPTH = 4
    // (interrupt/dma/dma_axi_master.v); icache, dcache và debug-DTM chỉ phát
    // 1 outstanding read. Giá trị cũ (8) làm các FIFO outstanding to gấp đôi
    // mà không thêm băng thông.
    localparam AXI_OUTSTANDING_AMT = 4;
    // ID phía slave = {master_id, ID gốc của master} = 2 + 5 = 7 bit.
    // Trước 2026-09-11 còn thêm 2 bit ROB tag ở giữa (9 bit); ROB đã bỏ - xem
    // ghi chú ở dsp_read_channel trong bus/axi_interconnect/axi_dispatcher_channel.v.
    localparam SLV_ID_WIDTH = MST_ID_WIDTH + $clog2(MST_AMT);
    // FIFO RDATA của mỗi cặp (master, slave) trong dispatcher đọc. Nó chỉ tách
    // nhịp slave khỏi master, không phải chỗ đệm cả burst: R đi đúng thứ tự AR
    // và mọi master nhận R ngay (xem điều kiện 3 ở dsp_read_channel), nên 2 ô
    // đủ cho 1 beat/chu kỳ. 16 (mặc định) = 4 x 7 x 16 x 40 = 17920 flop.
    localparam AXI_RDATA_DEPTH = 2;

    wire [MST_AMT*5-1:0]  m_axi_awid;   wire [MST_AMT*32-1:0] m_axi_awaddr; wire [MST_AMT*8-1:0]  m_axi_awlen;
    wire [MST_AMT*3-1:0]  m_axi_awsize; wire [MST_AMT*2-1:0]  m_axi_awburst; wire [MST_AMT*3-1:0]  m_axi_awprot;
    wire [MST_AMT-1:0]    m_axi_awvalid; wire [MST_AMT-1:0]    m_axi_awready; wire [MST_AMT*32-1:0] m_axi_wdata;
    wire [MST_AMT*4-1:0]  m_axi_wstrb;  wire [MST_AMT-1:0]    m_axi_wlast;  wire [MST_AMT-1:0]    m_axi_wvalid;
    wire [MST_AMT-1:0]    m_axi_wready; wire [MST_AMT*5-1:0]  m_axi_bid;    wire [MST_AMT*2-1:0]  m_axi_bresp;
    wire [MST_AMT-1:0]    m_axi_bvalid; wire [MST_AMT-1:0]    m_axi_bready; wire [MST_AMT*5-1:0]  m_axi_arid;
    wire [MST_AMT*32-1:0] m_axi_araddr; wire [MST_AMT*8-1:0]  m_axi_arlen;  wire [MST_AMT*3-1:0]  m_axi_arsize;
    wire [MST_AMT*2-1:0]  m_axi_arburst; wire [MST_AMT*3-1:0]  m_axi_arprot; wire [MST_AMT-1:0]    m_axi_arvalid;
    wire [MST_AMT-1:0]    m_axi_arready; wire [MST_AMT*5-1:0]  m_axi_rid;    wire [MST_AMT*32-1:0] m_axi_rdata;
    wire [MST_AMT*2-1:0]  m_axi_rresp;  wire [MST_AMT-1:0]    m_axi_rlast;  wire [MST_AMT-1:0]    m_axi_rvalid;
    wire [MST_AMT-1:0]    m_axi_rready;

    // Master 0: ICache
    wire [4:0]  m0_awid;    wire [31:0] m0_awaddr;  wire [7:0]  m0_awlen;   wire [2:0]  m0_awsize;  wire [1:0]  m0_awburst; wire [2:0]  m0_awprot;  wire m0_awvalid; wire m0_awready;
    wire [31:0] m0_wdata;   wire [3:0]  m0_wstrb;   wire        m0_wlast;   wire        m0_wvalid;  wire m0_wready;
    wire [4:0]  m0_bid;     wire [1:0]  m0_bresp;   wire        m0_bvalid;  wire        m0_bready;
    wire [4:0]  m0_arid;    wire [31:0] m0_araddr;  wire [7:0]  m0_arlen;   wire [2:0]  m0_arsize;  wire [1:0]  m0_arburst; wire [2:0]  m0_arprot;  wire m0_arvalid; wire m0_arready;
    wire [4:0]  m0_rid;     wire [31:0] m0_rdata;   wire [1:0]  m0_rresp;   wire        m0_rlast;   wire m0_rvalid; wire m0_rready;

    // Master 1: DCache
    wire [4:0]  m1_awid;    wire [31:0] m1_awaddr;  wire [7:0]  m1_awlen;   wire [2:0]  m1_awsize;  wire [1:0]  m1_awburst; wire [2:0]  m1_awprot;  wire m1_awvalid; wire m1_awready;
    wire [31:0] m1_wdata;   wire [3:0]  m1_wstrb;   wire        m1_wlast;   wire        m1_wvalid;  wire m1_wready;
    wire [4:0]  m1_bid;     wire [1:0]  m1_bresp;   wire        m1_bvalid;  wire        m1_bready;
    wire [4:0]  m1_arid;    wire [31:0] m1_araddr;  wire [7:0]  m1_arlen;   wire [2:0]  m1_arsize;  wire [1:0]  m1_arburst; wire [2:0]  m1_arprot;  wire m1_arvalid; wire m1_arready;
    wire [4:0]  m1_rid;     wire [31:0] m1_rdata;   wire [1:0]  m1_rresp;   wire        m1_rlast;   wire m1_rvalid; wire m1_rready;

    // Master 2: DTM (Debug)
    wire [4:0]  m2_awid;    wire [31:0] m2_awaddr;  wire [7:0]  m2_awlen;   wire [2:0]  m2_awsize;  wire [1:0]  m2_awburst; wire [2:0]  m2_awprot;  wire m2_awvalid; wire m2_awready;
    wire [31:0] m2_wdata;   wire [3:0]  m2_wstrb;   wire        m2_wlast;   wire        m2_wvalid;  wire m2_wready;
    wire [4:0]  m2_bid;     wire [1:0]  m2_bresp;   wire        m2_bvalid;  wire        m2_bready;
    wire [4:0]  m2_arid;    wire [31:0] m2_araddr;  wire [7:0]  m2_arlen;   wire [2:0]  m2_arsize;  wire [1:0]  m2_arburst; wire [2:0]  m2_arprot;  wire m2_arvalid; wire m2_arready;
    wire [4:0]  m2_rid;     wire [31:0] m2_rdata;   wire [1:0]  m2_rresp;   wire        m2_rlast;   wire m2_rvalid; wire m2_rready;
    wire m2_awlock_unused, m2_arlock_unused;
    wire [3:0] m2_awcache_unused, m2_awqos_unused, m2_awregion_unused;
    wire [3:0] m2_arcache_unused, m2_arqos_unused, m2_arregion_unused;

    // Master 3: DMA
    wire [4:0]  m3_awid;    wire [31:0] m3_awaddr;  wire [7:0]  m3_awlen;   wire [2:0]  m3_awsize;  wire [1:0]  m3_awburst; wire [2:0]  m3_awprot;  wire m3_awvalid; wire m3_awready;
    wire [31:0] m3_wdata;   wire [3:0]  m3_wstrb;   wire        m3_wlast;   wire        m3_wvalid;  wire m3_wready;
    wire [4:0]  m3_bid;     wire [1:0]  m3_bresp;   wire        m3_bvalid;  wire        m3_bready;
    wire [4:0]  m3_arid;    wire [31:0] m3_araddr;  wire [7:0]  m3_arlen;   wire [2:0]  m3_arsize;  wire [1:0]  m3_arburst; wire [2:0]  m3_arprot;  wire m3_arvalid; wire m3_arready;
    wire [4:0]  m3_rid;     wire [31:0] m3_rdata;   wire [1:0]  m3_rresp;   wire        m3_rlast;   wire m3_rvalid; wire m3_rready;

    assign m_axi_awid    = {m3_awid, m2_awid, m1_awid, m0_awid};
    assign m_axi_awaddr  = {m3_awaddr, m2_awaddr, m1_awaddr, m0_awaddr};
    assign m_axi_awlen   = {m3_awlen, m2_awlen, m1_awlen, m0_awlen};
    assign m_axi_awsize  = {m3_awsize, m2_awsize, m1_awsize, m0_awsize};
    assign m_axi_awburst = {m3_awburst, m2_awburst, m1_awburst, m0_awburst};
    assign m_axi_awprot  = {m3_awprot, m2_awprot, m1_awprot, m0_awprot};
    assign m_axi_awvalid = {m3_awvalid, m2_awvalid, m1_awvalid, m0_awvalid};
    assign {m3_awready, m2_awready, m1_awready, m0_awready} = m_axi_awready;

    assign m_axi_wdata   = {m3_wdata, m2_wdata, m1_wdata, m0_wdata};
    assign m_axi_wstrb   = {m3_wstrb, m2_wstrb, m1_wstrb, m0_wstrb};
    assign m_axi_wlast   = {m3_wlast, m2_wlast, m1_wlast, m0_wlast};
    assign m_axi_wvalid  = {m3_wvalid, m2_wvalid, m1_wvalid, m0_wvalid};
    assign {m3_wready, m2_wready, m1_wready, m0_wready} = m_axi_wready;

    assign m_axi_bready  = {m3_bready, m2_bready, m1_bready, m0_bready};
    assign {m3_bid, m2_bid, m1_bid, m0_bid}             = m_axi_bid;
    assign {m3_bresp, m2_bresp, m1_bresp, m0_bresp}       = m_axi_bresp;
    assign {m3_bvalid, m2_bvalid, m1_bvalid, m0_bvalid}    = m_axi_bvalid;

    assign m_axi_arid    = {m3_arid, m2_arid, m1_arid, m0_arid};
    assign m_axi_araddr  = {m3_araddr, m2_araddr, m1_araddr, m0_araddr};
    assign m_axi_arlen   = {m3_arlen, m2_arlen, m1_arlen, m0_arlen};
    assign m_axi_arsize  = {m3_arsize, m2_arsize, m1_arsize, m0_arsize};
    assign m_axi_arburst = {m3_arburst, m2_arburst, m1_arburst, m0_arburst};
    assign m_axi_arprot  = {m3_arprot, m2_arprot, m1_arprot, m0_arprot};
    assign m_axi_arvalid = {m3_arvalid, m2_arvalid, m1_arvalid, m0_arvalid};
    assign {m3_arready, m2_arready, m1_arready, m0_arready} = m_axi_arready;

    assign m_axi_rready  = {m3_rready, m2_rready, m1_rready, m0_rready};
    assign {m3_rid, m2_rid, m1_rid, m0_rid}             = m_axi_rid;
    assign {m3_rdata, m2_rdata, m1_rdata, m0_rdata}       = m_axi_rdata;
    assign {m3_rresp, m2_rresp, m1_rresp, m0_rresp}       = m_axi_rresp;
    assign {m3_rlast, m2_rlast, m1_rlast, m0_rlast}       = m_axi_rlast;
    assign {m3_rvalid, m2_rvalid, m1_rvalid, m0_rvalid}    = m_axi_rvalid;

    // Slaves Arrays
    wire [SLV_AMT*SLV_ID_WIDTH-1:0]  s_axi_awid;   wire [SLV_AMT*32-1:0] s_axi_awaddr; wire [SLV_AMT*8-1:0]  s_axi_awlen;
    wire [SLV_AMT*3-1:0]  s_axi_awsize; wire [SLV_AMT*2-1:0]  s_axi_awburst; wire [SLV_AMT*3-1:0]  s_axi_awprot;
    wire [SLV_AMT-1:0]    s_axi_awlock; wire [SLV_AMT*4-1:0]  s_axi_awcache; wire [SLV_AMT*4-1:0]  s_axi_awqos; wire [SLV_AMT*4-1:0] s_axi_awregion;
    wire [SLV_AMT-1:0]    s_axi_awvalid; wire [SLV_AMT-1:0]    s_axi_awready; wire [SLV_AMT*32-1:0] s_axi_wdata;
    wire [SLV_AMT*4-1:0]  s_axi_wstrb;  wire [SLV_AMT-1:0]    s_axi_wlast;  wire [SLV_AMT-1:0]    s_axi_wvalid;
    wire [SLV_AMT-1:0]    s_axi_wready; wire [SLV_AMT*SLV_ID_WIDTH-1:0]  s_axi_bid;    wire [SLV_AMT*2-1:0]  s_axi_bresp;
    wire [SLV_AMT-1:0]    s_axi_bvalid; wire [SLV_AMT-1:0]    s_axi_bready; wire [SLV_AMT*SLV_ID_WIDTH-1:0]  s_axi_arid;
    wire [SLV_AMT*32-1:0] s_axi_araddr; wire [SLV_AMT*8-1:0]  s_axi_arlen;  wire [SLV_AMT*3-1:0]  s_axi_arsize;
    wire [SLV_AMT*2-1:0]  s_axi_arburst; wire [SLV_AMT*3-1:0]  s_axi_arprot; wire [SLV_AMT-1:0]    s_axi_arvalid;
    wire [SLV_AMT-1:0]    s_axi_arlock; wire [SLV_AMT*4-1:0]  s_axi_arcache; wire [SLV_AMT*4-1:0]  s_axi_arqos; wire [SLV_AMT*4-1:0] s_axi_arregion;
    wire [SLV_AMT-1:0]    s_axi_arready; wire [SLV_AMT*SLV_ID_WIDTH-1:0]  s_axi_rid;    wire [SLV_AMT*32-1:0] s_axi_rdata;
    wire [SLV_AMT*2-1:0]  s_axi_rresp;  wire [SLV_AMT-1:0]    s_axi_rlast;  wire [SLV_AMT-1:0]    s_axi_rvalid;
    wire [SLV_AMT-1:0]    s_axi_rready;

    // Từng Slave đơn lẻ
    wire [SLV_ID_WIDTH-1:0] s0_awid; wire [31:0] s0_awaddr; wire [7:0] s0_awlen; wire [2:0] s0_awsize; wire [1:0] s0_awburst; wire [2:0] s0_awprot; wire s0_awvalid; wire s0_awready;
    wire [31:0] s0_wdata; wire [3:0] s0_wstrb; wire s0_wlast; wire s0_wvalid; wire s0_wready;
    wire [SLV_ID_WIDTH-1:0] s0_bid; wire [1:0] s0_bresp; wire s0_bvalid; wire s0_bready;
    wire [SLV_ID_WIDTH-1:0] s0_arid; wire [31:0] s0_araddr; wire [7:0] s0_arlen; wire [2:0] s0_arsize; wire [1:0] s0_arburst; wire [2:0] s0_arprot; wire s0_arvalid; wire s0_arready;
    wire [SLV_ID_WIDTH-1:0] s0_rid; wire [31:0] s0_rdata; wire [1:0] s0_rresp; wire s0_rlast; wire s0_rvalid; wire s0_rready;

    wire [SLV_ID_WIDTH-1:0] s1_awid; wire [31:0] s1_awaddr; wire [7:0] s1_awlen; wire [2:0] s1_awsize; wire [1:0] s1_awburst; wire [2:0] s1_awprot; wire s1_awvalid; wire s1_awready;
    wire [31:0] s1_wdata; wire [3:0] s1_wstrb; wire s1_wlast; wire s1_wvalid; wire s1_wready;
    wire [SLV_ID_WIDTH-1:0] s1_bid; wire [1:0] s1_bresp; wire s1_bvalid; wire s1_bready;
    wire [SLV_ID_WIDTH-1:0] s1_arid; wire [31:0] s1_araddr; wire [7:0] s1_arlen; wire [2:0] s1_arsize; wire [1:0] s1_arburst; wire [2:0] s1_arprot; wire s1_arvalid; wire s1_arready;
    wire [SLV_ID_WIDTH-1:0] s1_rid; wire [31:0] s1_rdata; wire [1:0] s1_rresp; wire s1_rlast; wire s1_rvalid; wire s1_rready;

    wire [SLV_ID_WIDTH-1:0] s2_awid; wire [31:0] s2_awaddr; wire [7:0] s2_awlen; wire [2:0] s2_awsize; wire [1:0] s2_awburst; wire [2:0] s2_awprot; wire s2_awvalid; wire s2_awready;
    wire [31:0] s2_wdata; wire [3:0] s2_wstrb; wire s2_wlast; wire s2_wvalid; wire s2_wready;
    wire [SLV_ID_WIDTH-1:0] s2_bid; wire [1:0] s2_bresp; wire s2_bvalid; wire s2_bready;
    wire [SLV_ID_WIDTH-1:0] s2_arid; wire [31:0] s2_araddr; wire [7:0] s2_arlen; wire [2:0] s2_arsize; wire [1:0] s2_arburst; wire [2:0] s2_arprot; wire s2_arvalid; wire s2_arready;
    wire [SLV_ID_WIDTH-1:0] s2_rid; wire [31:0] s2_rdata; wire [1:0] s2_rresp; wire s2_rlast; wire s2_rvalid; wire s2_rready;

    wire [SLV_ID_WIDTH-1:0] s3_awid; wire [31:0] s3_awaddr; wire [7:0] s3_awlen; wire [2:0] s3_awsize; wire [1:0] s3_awburst; wire [2:0] s3_awprot; wire s3_awvalid; wire s3_awready;
    wire [31:0] s3_wdata; wire [3:0] s3_wstrb; wire s3_wlast; wire s3_wvalid; wire s3_wready;
    wire [SLV_ID_WIDTH-1:0] s3_bid; wire [1:0] s3_bresp; wire s3_bvalid; wire s3_bready;
    wire [SLV_ID_WIDTH-1:0] s3_arid; wire [31:0] s3_araddr; wire [7:0] s3_arlen; wire [2:0] s3_arsize; wire [1:0] s3_arburst; wire [2:0] s3_arprot; wire s3_arvalid; wire s3_arready;
    wire [SLV_ID_WIDTH-1:0] s3_rid; wire [31:0] s3_rdata; wire [1:0] s3_rresp; wire s3_rlast; wire s3_rvalid; wire s3_rready;

    wire [SLV_ID_WIDTH-1:0] s4_awid; wire [31:0] s4_awaddr; wire [7:0] s4_awlen; wire [2:0] s4_awsize; wire [1:0] s4_awburst; wire [2:0] s4_awprot; wire s4_awvalid; wire s4_awready;
    wire [31:0] s4_wdata; wire [3:0] s4_wstrb; wire s4_wlast; wire s4_wvalid; wire s4_wready;
    wire [SLV_ID_WIDTH-1:0] s4_bid; wire [1:0] s4_bresp; wire s4_bvalid; wire s4_bready;
    wire [SLV_ID_WIDTH-1:0] s4_arid; wire [31:0] s4_araddr; wire [7:0] s4_arlen; wire [2:0] s4_arsize; wire [1:0] s4_arburst; wire [2:0] s4_arprot; wire s4_arvalid; wire s4_arready;
    wire [SLV_ID_WIDTH-1:0] s4_rid; wire [31:0] s4_rdata; wire [1:0] s4_rresp; wire s4_rlast; wire s4_rvalid; wire s4_rready;

    wire [SLV_ID_WIDTH-1:0] s5_awid; wire [31:0] s5_awaddr; wire [7:0] s5_awlen; wire [2:0] s5_awsize; wire [1:0] s5_awburst; wire [2:0] s5_awprot; wire s5_awvalid; wire s5_awready;
    wire [31:0] s5_wdata; wire [3:0] s5_wstrb; wire s5_wlast; wire s5_wvalid; wire s5_wready;
    wire [SLV_ID_WIDTH-1:0] s5_bid; wire [1:0] s5_bresp; wire s5_bvalid; wire s5_bready;
    wire [SLV_ID_WIDTH-1:0] s5_arid; wire [31:0] s5_araddr; wire [7:0] s5_arlen; wire [2:0] s5_arsize; wire [1:0] s5_arburst; wire [2:0] s5_arprot; wire s5_arvalid; wire s5_arready;
    wire [SLV_ID_WIDTH-1:0] s5_rid; wire [31:0] s5_rdata; wire [1:0] s5_rresp; wire s5_rlast; wire s5_rvalid; wire s5_rready;

    wire [SLV_ID_WIDTH-1:0] s6_awid; wire [31:0] s6_awaddr; wire [7:0] s6_awlen; wire [2:0] s6_awsize; wire [1:0] s6_awburst; wire [2:0] s6_awprot; wire s6_awvalid; wire s6_awready;
    wire [31:0] s6_wdata; wire [3:0] s6_wstrb; wire s6_wlast; wire s6_wvalid; wire s6_wready;
    wire [SLV_ID_WIDTH-1:0] s6_bid; wire [1:0] s6_bresp; wire s6_bvalid; wire s6_bready;
    wire [SLV_ID_WIDTH-1:0] s6_arid; wire [31:0] s6_araddr; wire [7:0] s6_arlen; wire [2:0] s6_arsize; wire [1:0] s6_arburst; wire [2:0] s6_arprot; wire s6_arvalid; wire s6_arready;
    wire [SLV_ID_WIDTH-1:0] s6_rid; wire [31:0] s6_rdata; wire [1:0] s6_rresp; wire s6_rlast; wire s6_rvalid; wire s6_rready;

    wire s0_awlock, s1_awlock, s2_awlock, s3_awlock, s4_awlock, s5_awlock, s6_awlock;
    wire [3:0] s0_awcache, s1_awcache, s2_awcache, s3_awcache, s4_awcache, s5_awcache, s6_awcache;
    wire [3:0] s0_awqos, s1_awqos, s2_awqos, s3_awqos, s4_awqos, s5_awqos, s6_awqos;
    wire [3:0] s0_awregion, s1_awregion, s2_awregion, s3_awregion, s4_awregion, s5_awregion, s6_awregion;
    wire s0_arlock, s1_arlock, s2_arlock, s3_arlock, s4_arlock, s5_arlock, s6_arlock;
    wire [3:0] s0_arcache, s1_arcache, s2_arcache, s3_arcache, s4_arcache, s5_arcache, s6_arcache;
    wire [3:0] s0_arqos, s1_arqos, s2_arqos, s3_arqos, s4_arqos, s5_arqos, s6_arqos;
    wire [3:0] s0_arregion, s1_arregion, s2_arregion, s3_arregion, s4_arregion, s5_arregion, s6_arregion;

      // --- KÊNH WRITE ADDRESS ---
    assign s_axi_awready = {s6_awready, s5_awready, s4_awready, s3_awready, s2_awready, s1_awready, s0_awready};
    assign {s6_awid, s5_awid, s4_awid, s3_awid, s2_awid, s1_awid, s0_awid}       = s_axi_awid;
    assign {s6_awaddr, s5_awaddr, s4_awaddr, s3_awaddr, s2_awaddr, s1_awaddr, s0_awaddr} = s_axi_awaddr;
    assign {s6_awlen, s5_awlen, s4_awlen, s3_awlen, s2_awlen, s1_awlen, s0_awlen}   = s_axi_awlen;
    assign {s6_awsize, s5_awsize, s4_awsize, s3_awsize, s2_awsize, s1_awsize, s0_awsize} = s_axi_awsize;
    assign {s6_awburst, s5_awburst, s4_awburst, s3_awburst, s2_awburst, s1_awburst, s0_awburst} = s_axi_awburst;
    assign {s6_awlock, s5_awlock, s4_awlock, s3_awlock, s2_awlock, s1_awlock, s0_awlock} = s_axi_awlock;
    assign {s6_awcache, s5_awcache, s4_awcache, s3_awcache, s2_awcache, s1_awcache, s0_awcache} = s_axi_awcache;
    assign {s6_awprot, s5_awprot, s4_awprot, s3_awprot, s2_awprot, s1_awprot, s0_awprot} = s_axi_awprot;
    assign {s6_awqos, s5_awqos, s4_awqos, s3_awqos, s2_awqos, s1_awqos, s0_awqos} = s_axi_awqos;
    assign {s6_awregion, s5_awregion, s4_awregion, s3_awregion, s2_awregion, s1_awregion, s0_awregion} = s_axi_awregion;
    assign {s6_awvalid, s5_awvalid, s4_awvalid, s3_awvalid, s2_awvalid, s1_awvalid, s0_awvalid} = s_axi_awvalid;

    // --- KÊNH WRITE DATA ---
    assign s_axi_wready  = {s6_wready, s5_wready, s4_wready, s3_wready, s2_wready, s1_wready, s0_wready};
    assign {s6_wdata, s5_wdata, s4_wdata, s3_wdata, s2_wdata, s1_wdata, s0_wdata}   = s_axi_wdata;
    assign {s6_wstrb, s5_wstrb, s4_wstrb, s3_wstrb, s2_wstrb, s1_wstrb, s0_wstrb}   = s_axi_wstrb;
    assign {s6_wlast, s5_wlast, s4_wlast, s3_wlast, s2_wlast, s1_wlast, s0_wlast}   = s_axi_wlast;
    assign {s6_wvalid, s5_wvalid, s4_wvalid, s3_wvalid, s2_wvalid, s1_wvalid, s0_wvalid} = s_axi_wvalid;

    // --- KÊNH WRITE RESPONSE ---
    assign {s6_bready, s5_bready, s4_bready, s3_bready, s2_bready, s1_bready, s0_bready} = s_axi_bready;
    assign s_axi_bid     = {s6_bid, s5_bid, s4_bid, s3_bid, s2_bid, s1_bid, s0_bid};
    assign s_axi_bresp   = {s6_bresp, s5_bresp, s4_bresp, s3_bresp, s2_bresp, s1_bresp, s0_bresp};
    assign s_axi_bvalid  = {s6_bvalid, s5_bvalid, s4_bvalid, s3_bvalid, s2_bvalid, s1_bvalid, s0_bvalid};

    // --- KÊNH READ ADDRESS ---
    assign s_axi_arready = {s6_arready, s5_arready, s4_arready, s3_arready, s2_arready, s1_arready, s0_arready};
    assign {s6_arid, s5_arid, s4_arid, s3_arid, s2_arid, s1_arid, s0_arid}       = s_axi_arid;
    assign {s6_araddr, s5_araddr, s4_araddr, s3_araddr, s2_araddr, s1_araddr, s0_araddr} = s_axi_araddr;
    assign {s6_arlen, s5_arlen, s4_arlen, s3_arlen, s2_arlen, s1_arlen, s0_arlen}   = s_axi_arlen;
    assign {s6_arsize, s5_arsize, s4_arsize, s3_arsize, s2_arsize, s1_arsize, s0_arsize} = s_axi_arsize;
    assign {s6_arburst, s5_arburst, s4_arburst, s3_arburst, s2_arburst, s1_arburst, s0_arburst} = s_axi_arburst;
    assign {s6_arlock, s5_arlock, s4_arlock, s3_arlock, s2_arlock, s1_arlock, s0_arlock} = s_axi_arlock;
    assign {s6_arcache, s5_arcache, s4_arcache, s3_arcache, s2_arcache, s1_arcache, s0_arcache} = s_axi_arcache;
    assign {s6_arprot, s5_arprot, s4_arprot, s3_arprot, s2_arprot, s1_arprot, s0_arprot} = s_axi_arprot;
    assign {s6_arqos, s5_arqos, s4_arqos, s3_arqos, s2_arqos, s1_arqos, s0_arqos} = s_axi_arqos;
    assign {s6_arregion, s5_arregion, s4_arregion, s3_arregion, s2_arregion, s1_arregion, s0_arregion} = s_axi_arregion;
    assign {s6_arvalid, s5_arvalid, s4_arvalid, s3_arvalid, s2_arvalid, s1_arvalid, s0_arvalid} = s_axi_arvalid;

    // --- KÊNH READ DATA ---
    assign {s6_rready, s5_rready, s4_rready, s3_rready, s2_rready, s1_rready, s0_rready} = s_axi_rready;
    assign s_axi_rid     = {s6_rid, s5_rid, s4_rid, s3_rid, s2_rid, s1_rid, s0_rid};
    assign s_axi_rdata   = {s6_rdata, s5_rdata, s4_rdata, s3_rdata, s2_rdata, s1_rdata, s0_rdata};
    assign s_axi_rresp   = {s6_rresp, s5_rresp, s4_rresp, s3_rresp, s2_rresp, s1_rresp, s0_rresp};
    assign s_axi_rlast   = {s6_rlast, s5_rlast, s4_rlast, s3_rlast, s2_rlast, s1_rlast, s0_rlast};
    assign s_axi_rvalid  = {s6_rvalid, s5_rvalid, s4_rvalid, s3_rvalid, s2_rvalid, s1_rvalid, s0_rvalid};
    // =========================================================================
    // 6. INSTANTIATE CÁC MASTER MODULES
    // =========================================================================    
// --- KHAI BÁO DÂY LÕI ICACHE (clk_cpu) ---
    wire [4:0]  ic_arid;    wire [31:0] ic_araddr;  wire [7:0]  ic_arlen;   
    wire [2:0]  ic_arsize;  wire [1:0]  ic_arburst; wire [2:0]  ic_arprot;  
    wire        ic_arvalid; wire        ic_arready; wire [4:0]  ic_rid;     
    wire [31:0] ic_rdata;   wire [1:0]  ic_rresp;   wire        ic_rlast;   
    wire        ic_rvalid;  wire        ic_rready;

    // =========================================================================
    // Tightly Coupled Memory
    //
    // ITCM and DTCM hang off the core ports, before the caches and off the AXI
    // interconnect entirely, so an access can neither miss nor queue behind a
    // DMA burst.  Latency is a constant 2 cycles (3 for a byte/halfword store,
    // which the macro's missing byte-write mask turns into read-modify-write) -
    // the same as a cache hit, with the miss case and the bus removed.
    //
    //   ITCM  0x0002_0000 - 0x0002_3FFF  16 KiB  ISR and DSP/CNN inner loops
    //   DTCM  0x0002_4000 - 0x0002_7FFF  16 KiB  core stack, real-time state
    //
    // Neither range is claimed by any interconnect slave, so a DMA access to
    // them decodes to no slave and is reported as an error rather than
    // silently landing somewhere else.  Code is copied into the ITCM through
    // the load/store port, which is why the ITCM has both a fetch and a data
    // port and the DTCM only a data port.
    // =========================================================================
    `define SOC_IS_ITCM(a) (((a) & 32'hFFFF_C000) == 32'h0002_0000)
    `define SOC_IS_DTCM(a) (((a) & 32'hFFFF_C000) == 32'h0002_4000)

    wire if_sel_itcm = `SOC_IS_ITCM(cpu_inst_addr);
    wire ls_sel_itcm = `SOC_IS_ITCM(cpu_data_addr);
    wire ls_sel_dtcm = `SOC_IS_DTCM(cpu_data_addr);
    wire ls_sel_tcm  = ls_sel_itcm | ls_sel_dtcm;

    // -------------------------------------------------------------------------
    // P2c - mot `fence` KHONG CO DIA CHI.  `cpu_data_addr` luc do la ket qua ALU
    // cua chinh lenh fence (rs1 + imm cua mot lenh khong dung toan hang nao),
    // tuc rac.  Neu no tinh co roi vao dai TCM thi mux tra loi ben duoi se lay
    // hit/stall cua TCM - va TCM tra hit ngay - nen fence tro thanh NOP, dung
    // lai loi ma P2c ton tai de sua, chi khac la bay gio no ngau nhien.
    //
    // Vi vay duong TRA LOI dung ban `_rsp`: khi fence dang bat, cau tra loi luon
    // den tu D-cache.  Duong YEU CAU (`& ~ls_sel_tcm` o cac cong cpu_read_req /
    // cpu_write_req) van dung ban goc - vo hai, vi ca hai deu bang 0 trong mot
    // fence.
    //
    // TCM khong can xa gi: no la SRAM noi thang core, khong co store buffer,
    // khong qua bus.  Mot ghi vao TCM da nhin thay duoc ngay khi no retire.
    // -------------------------------------------------------------------------
    wire ls_sel_itcm_rsp = ls_sel_itcm & ~cpu_data_fence;
    wire ls_sel_dtcm_rsp = ls_sel_dtcm & ~cpu_data_fence;
    wire ls_sel_tcm_rsp  = ls_sel_tcm  & ~cpu_data_fence;

    // Cache-side responses, muxed onto the core ports further down.
    wire [31:0] ic_cpu_rdata; wire ic_cpu_hit; wire ic_cpu_stall; wire ic_cpu_error;
    wire [31:0] dc_cpu_rdata; wire dc_cpu_hit; wire dc_cpu_stall; wire dc_cpu_error;

    // TCM responses.
    wire [31:0] itcm_f_rdata; wire itcm_f_hit; wire itcm_f_stall;
    wire [31:0] itcm_d_rdata; wire itcm_d_hit; wire itcm_d_stall;
    wire [31:0] dtcm_d_rdata; wire dtcm_d_hit; wire dtcm_d_stall;

    // --- M0. ICACHE ---
    // =========================================================================
    // PMA - vung KHONG duoc cache
    //
    // Ban cu chi liet ke cua so APB:
    //     (addr >= 32'h4000_0000 && addr <= 32'h47FF_FFFF)
    // va BO SOT CLINT o 0x0200_0000. Hau qua tren D-cache la mot loi chan boot:
    //
    //   D-cache la write-through nen GHI mtimecmp van toi noi. Nhung DOC `mtime`
    //   thi HIT cache va tra ve gia tri cu VINH VIEN (mtime la bo dem chay lien
    //   tuc trong CLINT, khong ai lam dong cache line do dirty hay invalid).
    //   Moi vong `while (mtime < deadline)` khong bao gio thoat; toan bo
    //   timekeeping va tick cua RTOS chet.
    //
    // Cac cua so con lai deu DUOC cache va dung nhu vay: ROM 0x0001_0000, SRAM
    // 0x2000_0000 (nua LO), QSPI flash 0x3000_0000, SDRAM 0x8000_0000.
    //
    // NUA HI CUA SYSTEM RAM (0x2002_0000, slave 6) LA UNCACHED - CO Y.
    //
    // System RAM duoc tach thanh hai slave port de CPU va DMA chay song song
    // (xem ghi chu o muc 5).  Nhung song song ve BANG THONG khong tu dong dung
    // ve CHUC NANG: chip nay khong co snoop, D-cache la write-through va KHONG
    // co cong invalidate/flush nao ca.  Nen chieu "DMA ghi -> CPU doc" bi hong:
    // DMA ghi thang vao SRAM, D-cache van giu line cu (clean, hop le), CPU doc
    // ra gia tri cu MAI MAI cho toi khi line bi evict ngau nhien.  Khong the
    // vong tranh bang phan mem vi truoc day RAM khong he co bi danh uncached.
    //
    // Cach re nhat de dong lo hong do la cho hai nua HAI THUOC TINH khac nhau,
    // thay vi chi hai cong khac nhau:
    //
    //   LO 0x2000_0000-0x2001_FFFF  cacheable  - vung lam viec cua CPU (.data,
    //                                            .bss, stack, heap)
    //   HI 0x2002_0000-0x2003_FFFF  UNCACHED   - pool DMA buffer
    //
    // Dat buffer DMA vao nua HI thi bai toan coherency BIEN MAT tu goc, khong
    // can snoop, khong can dirty bit, khong can lenh CMO.  Day la mo hinh chuan
    // cua MCU khong coherent (vung NOCACHE cua STM32H7, .sram2 cua NXP).
    // Linker script Driver/ld/soc.ld dinh nghia vung DMAPOOL va section
    // `.dmabuf` tro vao day.
    //
    // Doi lai: doc/ghi nua HI tu CPU cham hon vi khong co cache - dung noi.  Do
    // la vung cho DMA, khong phai cho CPU tinh toan.
    //
    // Viet bang mat na bit thay vi so sanh >= / <= : re hon ve dien tich va khop
    // 1:1 voi SLV_BASE_ADDR / SLV_ADDR_MASK cua axi_interconnect ben duoi, nen
    // hai bang dia chi khong the lech nhau ma khong ai thay.
    //
    //   0x4000_0000 mask 0xF800_0000 -> cua so APB      (slave 4, 128 MB)
    //   0x0200_0000 mask 0xFFFF_0000 -> CLINT           (slave 5, 64 KB)
    //   0x2002_0000 mask 0xFFFE_0000 -> RAM HI / DMA    (slave 6, 128 KB)
    // =========================================================================
    `define SOC_IS_UNCACHED(a) ( ((a) & 32'hF800_0000) == 32'h4000_0000 ||                                  ((a) & 32'hFFFF_0000) == 32'h0200_0000 ||                                  ((a) & 32'hFFFE_0000) == 32'h2002_0000 )

    wire ic_uncache_en = `SOC_IS_UNCACHED(cpu_inst_addr);
    instruction_cache #(
        .C_CACHE_SIZE (16384),   // 16 KiB - xem ghi chu macro budget trong
        .C_BLOCK_SIZE (16),      // rtl/flow/project_config.tcl
        .C_WAYS       (2)
    ) u_icache (
        .clk             (clk_cpu),              // clk da gate (cg_cpu)
        .rst_n           (reset_sys_n),
        .cpu_read_req    (cpu_inst_req & ~if_sel_itcm),
        .cpu_addr        (cpu_inst_addr),
        .uncache_en_i    (ic_uncache_en),
        .cpu_read_data   (ic_cpu_rdata),
        .icache_hit      (ic_cpu_hit),
        .icache_stall    (ic_cpu_stall),
        .icache_error    (ic_cpu_error),
        
        // Nối vào dây lõi ICache
        .m_axi_awready   (1'b0),      .m_axi_wready  (1'b0),
        .m_axi_bid       (5'b0),      .m_axi_bresp   (2'b00),     .m_axi_bvalid  (1'b0),
        .m_axi_arid      (ic_arid),   .m_axi_araddr  (ic_araddr), .m_axi_arlen   (ic_arlen),
        .m_axi_arsize    (ic_arsize), .m_axi_arburst (ic_arburst),.m_axi_arprot  (ic_arprot), .m_axi_arvalid (ic_arvalid),
        .m_axi_arready   (ic_arready),.m_axi_rdata   (ic_rdata),  .m_axi_rresp   (ic_rresp),
        .m_axi_rid       (ic_rid),    .m_axi_rlast   (ic_rlast),  .m_axi_rvalid  (ic_rvalid), .m_axi_rready  (ic_rready)
    );

    // --- ICACHE -> AXI INTERCONNECT M0: noi thang ---
    // Truoc day la axi_async_bridge (clk_cpu 400 -> clk_axi 200 MHz). Cung mot
    // clock thi cau do chi con them tre + dien tich FIFO, nen bo. I-cache chi
    // doc: AW/W bi noi cung 0, B luon san sang.
    assign m0_awid    = 5'b0;  assign m0_awaddr = 32'b0; assign m0_awlen  = 8'b0;
    assign m0_awsize  = 3'b0;  assign m0_awburst = 2'b0; assign m0_awprot = 3'b0;
    assign m0_awvalid = 1'b0;
    assign m0_wdata   = 32'b0; assign m0_wstrb  = 4'b0;  assign m0_wlast  = 1'b0;
    assign m0_wvalid  = 1'b0;
    assign m0_bready  = 1'b1;

    assign m0_arid    = ic_arid;    assign m0_araddr  = ic_araddr;
    assign m0_arlen   = ic_arlen;   assign m0_arsize  = ic_arsize;
    assign m0_arburst = ic_arburst; assign m0_arprot  = ic_arprot;
    assign m0_arvalid = ic_arvalid; assign ic_arready = m0_arready;
    assign ic_rid     = m0_rid;     assign ic_rdata   = m0_rdata;
    assign ic_rresp   = m0_rresp;   assign ic_rlast   = m0_rlast;
    assign ic_rvalid  = m0_rvalid;  assign m0_rready  = ic_rready;

    // --- KHAI BÁO DÂY LÕI DCACHE ---
    wire [4:0]  dc_awid;    wire [31:0] dc_awaddr;  wire [7:0]  dc_awlen;   wire [2:0]  dc_awsize;  wire [1:0]  dc_awburst; wire [2:0]  dc_awprot;  wire dc_awvalid; wire dc_awready;
    wire [31:0] dc_wdata;   wire [3:0]  dc_wstrb;   wire        dc_wlast;   wire        dc_wvalid;  wire dc_wready;
    wire [4:0]  dc_bid;     wire [1:0]  dc_bresp;   wire        dc_bvalid;  wire        dc_bready;
    wire [4:0]  dc_arid;    wire [31:0] dc_araddr;  wire [7:0]  dc_arlen;   wire [2:0]  dc_arsize;  wire [1:0]  dc_arburst; wire [2:0]  dc_arprot;  wire dc_arvalid; wire dc_arready;
    wire [4:0]  dc_rid;     wire [31:0] dc_rdata;   wire [1:0]  dc_rresp;   wire        dc_rlast;   wire dc_rvalid; wire dc_rready;

    // --- M1. DCACHE ---
    // Cung mot dinh nghia PMA voi I-cache - xem ghi chu o `SOC_IS_UNCACHED tren.
    // Day la duong QUAN TRONG: thieu CLINT o day thi `mtime` bi cache va chet.
    wire dc_uncache_en = `SOC_IS_UNCACHED(cpu_data_addr);
    data_cache #(
        .C_CACHE_SIZE    (16384), // 16 KiB - xem ghi chu macro budget trong
        .C_BLOCK_SIZE    (16),    // rtl/flow/project_config.tcl
        // 2-way, khong phai 4-way: mot macro 1024x32 giu tron mot way, nen
        // 4-way ton 4 macro tag ma moi macro chi dung 256x20 bit.  Ha xuong
        // 2-way gap doi so set, tag vua 2 macro (8 -> 6 macro, 32 -> 24 KiB),
        // so macro data khong doi.
        .C_WAYS          (2),
        .STORE_BUF_DEPTH (4)
    ) u_dcache (
        .clk             (clk_cpu),              // clk da gate (cg_cpu)
        .rst_n           (reset_sys_n),
        .cpu_read_req    (cpu_data_rd_req & ~ls_sel_tcm),
        .cpu_write_req   (cpu_data_wr_req & ~ls_sel_tcm),
        // KHONG gate bang ~ls_sel_tcm: xem ghi chu ls_sel_*_rsp ben tren.
        .cpu_fence       (cpu_data_fence),
        .cpu_addr        (cpu_data_addr),
        .cpu_write_data  (cpu_data_wdata),
        .mem_unsigned    (cpu_data_unsigned),
        .mem_size        (cpu_data_size),
        .uncache_en_i    (dc_uncache_en),
        .cpu_amo_req         (cpu_data_amo_req),
        .dcache_amo_capture  (cpu_data_amo_capture),
        .cpu_read_data   (dc_cpu_rdata),
        .dcache_hit      (dc_cpu_hit),
        .dcache_stall    (dc_cpu_stall),
        .dcache_error    (dc_cpu_error),
        .dcache_sb_error (dc_sb_error),
        
        // Nối vào dây lõi DCache
        .m_axi_awid      (dc_awid),   .m_axi_awaddr  (dc_awaddr), .m_axi_awlen   (dc_awlen),
        .m_axi_awsize    (dc_awsize), .m_axi_awburst (dc_awburst),.m_axi_awprot  (dc_awprot),
        .m_axi_awvalid   (dc_awvalid), .m_axi_awready (dc_awready),
        .m_axi_wdata     (dc_wdata),  .m_axi_wstrb   (dc_wstrb),  .m_axi_wlast   (dc_wlast),  .m_axi_wvalid  (dc_wvalid), .m_axi_wready (dc_wready),
        .m_axi_bid       (dc_bid),    .m_axi_bresp   (dc_bresp),  .m_axi_bvalid  (dc_bvalid), .m_axi_bready  (dc_bready),
        .m_axi_arid      (dc_arid),   .m_axi_araddr  (dc_araddr), .m_axi_arlen   (dc_arlen),
        .m_axi_arsize    (dc_arsize), .m_axi_arburst (dc_arburst),.m_axi_arprot  (dc_arprot),
        .m_axi_arvalid   (dc_arvalid), .m_axi_arready (dc_arready),
        .m_axi_rid       (dc_rid),    .m_axi_rdata   (dc_rdata),  .m_axi_rresp   (dc_rresp),  .m_axi_rlast   (dc_rlast),  .m_axi_rvalid  (dc_rvalid), .m_axi_rready (dc_rready)
    );

    // --- DCACHE -> AXI INTERCONNECT M1: noi thang ---
    // Truoc day la axi_async_bridge voi kenh W 8 slot de hap thu chum store
    // 400 -> 200 MHz. Cung mot clock thi khong con chenh bang thong can dem;
    // store buffer 4 muc trong dcache.v da la bo dem do.
    assign m1_awid    = dc_awid;    assign m1_awaddr  = dc_awaddr;
    assign m1_awlen   = dc_awlen;   assign m1_awsize  = dc_awsize;
    assign m1_awburst = dc_awburst; assign m1_awprot  = dc_awprot;
    assign m1_awvalid = dc_awvalid; assign dc_awready = m1_awready;
    assign m1_wdata   = dc_wdata;   assign m1_wstrb   = dc_wstrb;
    assign m1_wlast   = dc_wlast;   assign m1_wvalid  = dc_wvalid;
    assign dc_wready  = m1_wready;
    assign dc_bid     = m1_bid;     assign dc_bresp   = m1_bresp;
    assign dc_bvalid  = m1_bvalid;  assign m1_bready  = dc_bready;
    assign m1_arid    = dc_arid;    assign m1_araddr  = dc_araddr;
    assign m1_arlen   = dc_arlen;   assign m1_arsize  = dc_arsize;
    assign m1_arburst = dc_arburst; assign m1_arprot  = dc_arprot;
    assign m1_arvalid = dc_arvalid; assign dc_arready = m1_arready;
    assign dc_rid     = m1_rid;     assign dc_rdata   = m1_rdata;
    assign dc_rresp   = m1_rresp;   assign dc_rlast   = m1_rlast;
    assign dc_rvalid  = m1_rvalid;  assign m1_rready  = dc_rready;

    // M2: Debug Module (JTAG + DTM AXI Master)
    wire dmi_req_valid, dmi_resp_valid, dmi_resp_ready;
    wire [6:0] dmi_req_addr; wire [31:0] dmi_req_data, dmi_resp_data; wire [1:0] dmi_req_op, dmi_resp_op;

    rv_jtag_dtm u_jtag_dtm (
        .tck(tck), .trst_n(trst_n), .tms(tms), .tdi(tdi), .tdo(tdo),
        .dmi_req_valid(dmi_req_valid), .dmi_req_addr(dmi_req_addr), .dmi_req_data(dmi_req_data), .dmi_req_op(dmi_req_op),
        .dmi_resp_ready(dmi_resp_ready), .dmi_resp_valid(dmi_resp_valid), .dmi_resp_data(dmi_resp_data), .dmi_resp_op(dmi_resp_op)
    );

    wire sba_req, sba_ack;
    wire [1:0] sba_op, sba_size, sba_resp;
    wire [31:0] sba_addr, sba_wdata, sba_rdata;
    wire dm_active, dm_busy, dbg_sleep, dbg_wdt_stop;

    // -------------------------------------------------------------------------
    // CLOCK DEBUG MODULE DO DEBUGGER QUYET DINH (2026-09-11).
    //
    // Ban cu: clk_en_dbg = CLK_GATE_CTRL[6], bit FIRMWARE ghi. Firmware tat bit
    // do la tu khoa JTAG vinh vien: DM dong bang, khong nhan duoc lenh DMI nao
    // de ma bat lai.
    //
    // Nay clock DM mo khi:
    //   dm_active  - debugger da ghi dmactive = 1 (dang trong phien debug)
    //   dmi_req_s  - co mot lenh DMI dang cho: danh thuc DM de no tra loi, ke ca
    //                khi dmactive = 0 (OpenOCD doc dmstatus truoc tien)
    //   dm_busy    - DM dang tra loi / cho SBA
    //   dbg_clk_hold - them 8 chu ky sau cung, de dtm_axi_master ve IDLE va
    //                resp_valid ha han truoc khi cong dong
    // Tuong duong CDBGPWRUPREQ cua ARM: mien debug bat/tat theo debugger.
    //
    // dmi_req_valid la tin hieu mien TCK: dong bo 2FF bang clk KHONG gate (chinh
    // clk_dbg dang tat thi khong dong bo duoc). Duong TCK -> CLK_SYS nam trong
    // rang buoc max_delay/false_path -hold co san cua constraint.sdc.
    // -------------------------------------------------------------------------
    wire      dmi_req_s;
    reg [3:0] dbg_clk_hold;
    cdc_sync_bit u_sync_dmi_wake (.clk_dst(clk), .rst_dst_n(reset_dbg_n),
                                  .d_in(dmi_req_valid), .q_out(dmi_req_s));
    always @(posedge clk or negedge reset_dbg_n) begin
        if (!reset_dbg_n)
            dbg_clk_hold <= 4'd0;
        else if (dm_active | dmi_req_s | dm_busy)
            dbg_clk_hold <= 4'd8;
        else if (dbg_clk_hold != 4'd0)
            dbg_clk_hold <= dbg_clk_hold - 4'd1;
    end
    assign clk_en_dbg = dm_active | dmi_req_s | dm_busy | (dbg_clk_hold != 4'd0);

    // DMI giua u_jtag_dtm (tck) va u_debug_module (clk_dbg): CDC DUY NHAT con
    // lai trong chip - handshake req/resp qua 3FF o moi ben, bus du lieu giu
    // on dinh trong suot handshake. constraint.sdc rang buoc no tuong minh.
    rv_debug_module_sba u_debug_module (
        .clk_sys            (clk_dbg), // clk da gate (cg_dbg)
        // Dac ta RISC-V Debug: ndmreset reset "moi thu TRU Debug Module". Neu DM
        // dung reset he thong thi chinh no bi reset boi ndmreset ma no phat ra,
        // nen dmcontrol tu xoa giua chung va `reset halt` cua OpenOCD khong bao
        // gio hoan tat. reset_dbg_n chi chua rst_n va watchdog.
        //
        // Luu y: dtm_axi_master ben duoi VAN dung reset_sys_n - no la mot AXI
        // master, phai reset cung bus de khong bo lai giao dich do dang. An toan
        // vi OpenOCD phat ndmreset bang mot lenh DMI rieng, khong nam giua mot
        // burst SBA.
        .rst_sys_n          (reset_dbg_n),
        .dmi_req_valid      (dmi_req_valid), .dmi_req_addr(dmi_req_addr), .dmi_req_data(dmi_req_data), .dmi_req_op(dmi_req_op),
        .dmi_resp_ready     (dmi_resp_ready), .dmi_resp_valid(dmi_resp_valid), .dmi_resp_data(dmi_resp_data), .dmi_resp_op(dmi_resp_op),
        .axi_req            (sba_req), .axi_op(sba_op), .axi_size(sba_size), .axi_addr(sba_addr), .axi_wdata(sba_wdata), .axi_ack(sba_ack), .axi_rdata(sba_rdata), .axi_resp(sba_resp),
        .cpu_halt_req       (dbg_halt_req_raw), .cpu_resume_req (dbg_resume_req_raw), .cpu_halted (dbg_halted_raw),
        .cpu_reg_read_addr  (dbg_reg_read_addr), .cpu_reg_read_data(dbg_reg_read_data), .cpu_reg_write_en(dbg_reg_write_en_raw), .cpu_reg_write_addr(dbg_reg_write_addr), .cpu_reg_write_data(dbg_reg_write_data),
        .ndmreset_req       (ndmreset_req),
        .dmactive_o         (dm_active),
        .busy_o             (dm_busy),
        .dbg_sleep_o        (dbg_sleep),
        .dbg_wdt_stop_o     (dbg_wdt_stop)
    );

    dtm_axi_master u_dtm_axi (
        .clk_sys         (clk_dbg), // Dùng clk_dbg
        .rst_sys_n       (reset_sys_n),
        .i_req           (sba_req), .i_op(sba_op), .i_size(sba_size), .i_addr(sba_addr), .i_wdata(sba_wdata), .o_ack(sba_ack), .o_resp(sba_resp), .o_rdata(sba_rdata),
        .m_axi_awid      (m2_awid), .m_axi_awaddr(m2_awaddr), .m_axi_awlen(m2_awlen), .m_axi_awsize(m2_awsize), .m_axi_awburst(m2_awburst), .m_axi_awlock(m2_awlock_unused), .m_axi_awcache(m2_awcache_unused), .m_axi_awprot(m2_awprot), .m_axi_awqos(m2_awqos_unused), .m_axi_awregion(m2_awregion_unused), .m_axi_awvalid(m2_awvalid), .m_axi_awready(m2_awready),
        .m_axi_wdata     (m2_wdata), .m_axi_wstrb(m2_wstrb), .m_axi_wlast(m2_wlast), .m_axi_wvalid(m2_wvalid), .m_axi_wready(m2_wready),
        .m_axi_bid       (m2_bid), .m_axi_bresp(m2_bresp), .m_axi_bvalid(m2_bvalid), .m_axi_bready(m2_bready),
        .m_axi_arid      (m2_arid), .m_axi_araddr(m2_araddr), .m_axi_arlen(m2_arlen), .m_axi_arsize(m2_arsize), .m_axi_arburst(m2_arburst), .m_axi_arlock(m2_arlock_unused), .m_axi_arcache(m2_arcache_unused), .m_axi_arprot(m2_arprot), .m_axi_arqos(m2_arqos_unused), .m_axi_arregion(m2_arregion_unused), .m_axi_arvalid(m2_arvalid), .m_axi_arready(m2_arready),
        .m_axi_rid       (m2_rid), .m_axi_rdata(m2_rdata), .m_axi_rresp(m2_rresp), .m_axi_rlast(m2_rlast), .m_axi_rvalid(m2_rvalid), .m_axi_rready(m2_rready)
    );


    // =========================================================================
    // 6b. TIGHTLY COUPLED MEMORY
    // =========================================================================
    tcm #(
        .SIZE_BYTES     (16384),
        .HAS_FETCH_PORT (1)
    ) u_itcm (
        .clk        (clk_cpu),
        .rst_n      (reset_sys_n),
        .f_req      (cpu_inst_req & if_sel_itcm),
        .f_addr     (cpu_inst_addr),
        .f_rdata    (itcm_f_rdata),
        .f_hit      (itcm_f_hit),
        .f_stall    (itcm_f_stall),
        .d_rd_req   (cpu_data_rd_req & ls_sel_itcm),
        .d_wr_req   (cpu_data_wr_req & ls_sel_itcm),
        .d_addr     (cpu_data_addr),
        .d_wdata    (cpu_data_wdata),
        .d_size     (cpu_data_size),
        .d_unsigned (cpu_data_unsigned),
        .d_rdata    (itcm_d_rdata),
        .d_hit      (itcm_d_hit),
        .d_stall    (itcm_d_stall)
    );

    // No instruction is ever fetched from the DTCM, so its fetch port is tied
    // off and optimised away by HAS_FETCH_PORT = 0.
    tcm #(
        .SIZE_BYTES     (16384),
        .HAS_FETCH_PORT (0)
    ) u_dtcm (
        .clk        (clk_cpu),
        .rst_n      (reset_sys_n),
        .f_req      (1'b0),
        .f_addr     (32'b0),
        .f_rdata    (),
        .f_hit      (),
        .f_stall    (),
        .d_rd_req   (cpu_data_rd_req & ls_sel_dtcm),
        .d_wr_req   (cpu_data_wr_req & ls_sel_dtcm),
        .d_addr     (cpu_data_addr),
        .d_wdata    (cpu_data_wdata),
        .d_size     (cpu_data_size),
        .d_unsigned (cpu_data_unsigned),
        .d_rdata    (dtcm_d_rdata),
        .d_hit      (dtcm_d_hit),
        .d_stall    (dtcm_d_stall)
    );

    // Core ports: exactly one responder is selected by the address, so these
    // are pure selects, not a merge of concurrent answers.
    assign cpu_inst_data  = if_sel_itcm ? itcm_f_rdata : ic_cpu_rdata;
    assign cpu_inst_hit   = if_sel_itcm ? itcm_f_hit   : ic_cpu_hit;
    assign cpu_inst_stall = if_sel_itcm ? itcm_f_stall : ic_cpu_stall;

    assign cpu_data_rdata = ls_sel_dtcm_rsp ? dtcm_d_rdata :
                            ls_sel_itcm_rsp ? itcm_d_rdata : dc_cpu_rdata;
    assign cpu_data_hit   = ls_sel_dtcm_rsp ? dtcm_d_hit   :
                            ls_sel_itcm_rsp ? itcm_d_hit   : dc_cpu_hit;
    assign cpu_data_stall = ls_sel_dtcm_rsp ? dtcm_d_stall :
                            ls_sel_itcm_rsp ? itcm_d_stall : dc_cpu_stall;

    // -------------------------------------------------------------------------
    // C1 - duong bao loi bus ve CPU.
    //
    // TCM khong bao gio loi: no la SRAM noi thang core, khong qua bus, khong co
    // dia chi nao trong dai cua no ma khong ton tai. Nen khi TCM duoc chon thi
    // ep 0.
    //
    // DUNG ls_sel_tcm, KHONG dung ls_sel_tcm_rsp nhu ba mux o tren. Ban _rsp
    // chua ~cpu_data_fence, ma trong core dcache_fence = commit_kill ? 0 : fence
    // va commit_kill = trap_enter <- trap_data_access <- dcache_error. Dung _rsp
    // o day khep mot VONG TO HOP (Genus 2026-09-11: TIM-20 + 2 cdn_loop_breaker
    // trong u_core/MEM, "timing results should not be trusted").
    // Bo _rsp o duong LOI la an toan: core chi xet dcache_error khi
    // ex_mem_is_mem (= mem_read | mem_write), ma mot fence co ca hai bang 0 -
    // luc do loi bi bo qua bat ke mux chon gi. Khi khong co fence, hai tin hieu
    // bang nhau. Hit/stall/rdata van phai dung _rsp (ly do P2c o tren).
    // -------------------------------------------------------------------------
    assign cpu_inst_error = if_sel_itcm ? 1'b0 : ic_cpu_error;
    assign cpu_data_error = ls_sel_tcm ? 1'b0 : dc_cpu_error;

    // =========================================================================
    // 7. AXI INTERCONNECT
    // =========================================================================
    axi_interconnect #(
        .MST_AMT(MST_AMT), .SLV_AMT(SLV_AMT),
        .OUTSTANDING_AMT(AXI_OUTSTANDING_AMT),
        .TRANS_MST_ID_W(MST_ID_WIDTH), .TRANS_SLV_ID_W(SLV_ID_WIDTH),
        .DSP_RDATA_DEPTH(AXI_RDATA_DEPTH),
        .MST_WEIGHT (128'h00000005_00000004_00000003_00000001),
        // slave 6..0, most significant field first:
        //   6: 0x2002_0000 RAM hi  128 KB   mask FFFE_0000
        //   5: 0x0200_0000 CLINT   64 KB    mask FFFF_0000
        //   4: 0x4000_0000 APB     128 MB   mask F800_0000
        //   3: 0x8000_0000 SDRAM   64 MB    mask FC00_0000
        //   2: 0x3000_0000 QSPI    16 MB    mask FF00_0000
        //   1: 0x2000_0000 RAM lo  128 KB   mask FFFE_0000
        //   0: 0x0001_0000 ROM     32 KB    mask FFFF_8000
        // ROM tung chiem cua so 64 KB; nay 32 KB, nen 0x0001_8000-0x0001_FFFF
        // KHONG thuoc slave nao va tra DECERR thay vi lap lai (alias) anh ROM.
        .SLV_BASE_ADDR (224'h2002_0000_0200_0000_4000_0000_8000_0000_3000_0000_2000_0000_0001_0000),
        .SLV_ADDR_MASK (224'hFFFE_0000_FFFF_0000_F800_0000_FC00_0000_FF00_0000_FFFE_0000_FFFF_8000),
        // T3 - do sau FIFO write-data theo tung slave, cung thu tu 6..0 nhu tren.
        // Mot bo cho moi master (MST_AMT=4), moi o rong 36 bit; 32 -> 8 tiet kiem
        // 4*24*36 = 3456 flop moi slave, 32 -> 2 tiet kiem 4320.
        //   6 RAM hi : 8  - chiu burst cua cache line
        //   5 CLINT  : 2  - chi ghi don nhip
        //   4 APB    : 2  - chi ghi don nhip
        //   3 SDRAM  : 8  - chiu burst
        //   2 QSPI   : 2  - chi doc; Genus da tu xoa duong W
        //   1 RAM lo : 8  - chiu burst
        //   0 ROM    : 2  - chi doc; Genus da tu xoa duong W
        .SLV_W_FIFO_DEPTH (224'h0000_0008_0000_0002_0000_0002_0000_0008_0000_0002_0000_0008_0000_0002),
        // R4 - bon truong sideband duoi day duoc noi CUNG bang hang so o phan
        // .m_AWLOCK_i / .m_AWCACHE_i / .m_AWQOS_i / .m_AWREGION_i ngay ben duoi,
        // giong het cho ca AR. Bao interconnect dung mang chung qua FIFO cua tung
        // master nua; gia tri o chan slave giu nguyen tung bit nho bon hang so
        // nay. AxPROT KHONG nam trong day - no la tin hieu that cua tung master.
        .AXI_SIDEBAND_EN  (0),
        .AXI_LOCK_CONST   (1'b0),
        .AXI_CACHE_CONST  (4'b0011),
        .AXI_QOS_CONST    (4'b0000),
        .AXI_REGION_CONST (4'b0000)
    ) u_axi_interconnect (
        .ACLK_i          (clk),     // AXI bus chay clk (khong gate)
        .ARESETn_i       (reset_sys_n),
        .m_AWID_i(m_axi_awid), .m_AWADDR_i(m_axi_awaddr), .m_AWBURST_i(m_axi_awburst), .m_AWLEN_i(m_axi_awlen), .m_AWSIZE_i(m_axi_awsize), .m_AWLOCK_i({MST_AMT{1'b0}}), .m_AWCACHE_i({MST_AMT{4'b0011}}), .m_AWPROT_i(m_axi_awprot), .m_AWQOS_i({MST_AMT{4'b0000}}), .m_AWREGION_i({MST_AMT{4'b0000}}), .m_AWVALID_i(m_axi_awvalid), .m_AWREADY_o(m_axi_awready),
        .m_WDATA_i(m_axi_wdata), .m_WSTRB_i(m_axi_wstrb), .m_WLAST_i(m_axi_wlast), .m_WVALID_i(m_axi_wvalid), .m_WREADY_o(m_axi_wready),
        .m_BID_o(m_axi_bid), .m_BRESP_o(m_axi_bresp), .m_BVALID_o(m_axi_bvalid), .m_BREADY_i(m_axi_bready),
        .m_ARID_i(m_axi_arid), .m_ARADDR_i(m_axi_araddr), .m_ARBURST_i(m_axi_arburst), .m_ARLEN_i(m_axi_arlen), .m_ARSIZE_i(m_axi_arsize), .m_ARLOCK_i({MST_AMT{1'b0}}), .m_ARCACHE_i({MST_AMT{4'b0011}}), .m_ARPROT_i(m_axi_arprot), .m_ARQOS_i({MST_AMT{4'b0000}}), .m_ARREGION_i({MST_AMT{4'b0000}}), .m_ARVALID_i(m_axi_arvalid), .m_ARREADY_o(m_axi_arready),
        .m_RID_o(m_axi_rid), .m_RDATA_o(m_axi_rdata), .m_RRESP_o(m_axi_rresp), .m_RLAST_o(m_axi_rlast), .m_RVALID_o(m_axi_rvalid), .m_RREADY_i(m_axi_rready),
        .s_AWID_o(s_axi_awid), .s_AWADDR_o(s_axi_awaddr), .s_AWBURST_o(s_axi_awburst), .s_AWLEN_o(s_axi_awlen), .s_AWSIZE_o(s_axi_awsize), .s_AWLOCK_o(s_axi_awlock), .s_AWCACHE_o(s_axi_awcache), .s_AWPROT_o(s_axi_awprot), .s_AWQOS_o(s_axi_awqos), .s_AWREGION_o(s_axi_awregion), .s_AWVALID_o(s_axi_awvalid), .s_AWREADY_i(s_axi_awready),
        .s_WDATA_o(s_axi_wdata), .s_WSTRB_o(s_axi_wstrb), .s_WLAST_o(s_axi_wlast), .s_WVALID_o(s_axi_wvalid), .s_WREADY_i(s_axi_wready),
        .s_BID_i(s_axi_bid), .s_BRESP_i(s_axi_bresp), .s_BVALID_i(s_axi_bvalid), .s_BREADY_o(s_axi_bready),
        .s_ARID_o(s_axi_arid), .s_ARADDR_o(s_axi_araddr), .s_ARBURST_o(s_axi_arburst), .s_ARLEN_o(s_axi_arlen), .s_ARSIZE_o(s_axi_arsize), .s_ARLOCK_o(s_axi_arlock), .s_ARCACHE_o(s_axi_arcache), .s_ARPROT_o(s_axi_arprot), .s_ARQOS_o(s_axi_arqos), .s_ARREGION_o(s_axi_arregion), .s_ARVALID_o(s_axi_arvalid), .s_ARREADY_i(s_axi_arready),
        .s_RID_i(s_axi_rid), .s_RDATA_i(s_axi_rdata), .s_RRESP_i(s_axi_rresp), .s_RLAST_i(s_axi_rlast), .s_RVALID_i(s_axi_rvalid), .s_RREADY_o(s_axi_rready)
    );

    // =========================================================================
    // 8. KHỞI TẠO CÁC AXI SLAVES
    // =========================================================================
    // =========================================================================
    // Boot ROM 32 KiB @ 0x0001_0000 - MASK ROM that, tong hop thanh logic chuan
    // (ASAP7 khong co ROM compiler; macro SRAM thi X luc cap nguon).  Noi dung
    // la ma boot tang 1 trong rtl/memory/boot.mem: dat mtvec, kiem header anh o
    // dau QSPI flash, chep (tuy chon) roi nhay vao firmware - chay XIP tu
    // 0x3000_0000 hoac tu ITCM/RAM.  Xem MEMORY_ARCHITECTURE.md muc 6.
    // 32 KiB la dung luong DIA CHI; dien tich chi ton theo so word boot.mem that
    // su dung (cac word con lai la nhanh `default` = 0 cua bang case).
    // =========================================================================
    axi_rom #(
        .ID_WIDTH(SLV_ID_WIDTH),
        .ADDR_MASK(32'h0000_7FFF),
        .MEM_DEPTH(8192),
        // genus.tcl always changes directory to mcu/genus before elaborate.
        .INIT_FILE("rtl/memory/boot.mem")
    ) u_axi_rom (
        .clk(clk), .rst_n(reset_sys_n),
        .s_axi_awid(s0_awid), .s_axi_awaddr(s0_awaddr), .s_axi_awlen(s0_awlen), .s_axi_awsize(s0_awsize), .s_axi_awburst(s0_awburst), .s_axi_awlock(s0_awlock), .s_axi_awcache(s0_awcache), .s_axi_awprot(s0_awprot), .s_axi_awqos(s0_awqos), .s_axi_awregion(s0_awregion), .s_axi_awvalid(s0_awvalid), .s_axi_awready(s0_awready),
        .s_axi_wdata(s0_wdata), .s_axi_wstrb(s0_wstrb), .s_axi_wlast(s0_wlast), .s_axi_wvalid(s0_wvalid), .s_axi_wready(s0_wready),
        .s_axi_bid(s0_bid), .s_axi_bresp(s0_bresp), .s_axi_bvalid(s0_bvalid), .s_axi_bready(s0_bready),
        .s_axi_arid(s0_arid), .s_axi_araddr(s0_araddr), .s_axi_arlen(s0_arlen), .s_axi_arsize(s0_arsize), .s_axi_arburst(s0_arburst), .s_axi_arlock(s0_arlock), .s_axi_arcache(s0_arcache), .s_axi_arprot(s0_arprot), .s_axi_arqos(s0_arqos), .s_axi_arregion(s0_arregion), .s_axi_arvalid(s0_arvalid), .s_axi_arready(s0_arready),
        .s_axi_rid(s0_rid), .s_axi_rdata(s0_rdata), .s_axi_rresp(s0_rresp), .s_axi_rlast(s0_rlast), .s_axi_rvalid(s0_rvalid), .s_axi_rready(s0_rready)
    );

    // =========================================================================
    // System RAM, 256 KiB split into two independent 128 KiB slave ports.
    //
    // One axi_ram serialises every access it owns (single-port 1RW macros, no
    // byte-write mask), and the interconnect gives each slave port its own
    // arbiter.  Splitting the range is therefore what removes CPU/DMA
    // contention; the 32-macro bank decode inside each half does not.
    //
    // Software places DMA buffers in the hi half and stack/heap in the lo half:
    //   lo  0x2000_0000 - 0x2001_FFFF  CPU: RTOS stack, heap, static data
    //   hi  0x2002_0000 - 0x2003_FFFF  DMA: network RX/TX, ADC, framebuffer
    // =========================================================================
    axi_ram #(
        .ID_WIDTH(SLV_ID_WIDTH),
        .ADDR_MASK(32'h0001_FFFF),
        .MEM_DEPTH(32768)
    ) u_axi_ram_lo (
        .clk(clk), .rst_n(reset_sys_n),
        .s_axi_awid(s1_awid), .s_axi_awaddr(s1_awaddr), .s_axi_awlen(s1_awlen), .s_axi_awsize(s1_awsize), .s_axi_awburst(s1_awburst), .s_axi_awlock(s1_awlock), .s_axi_awcache(s1_awcache), .s_axi_awprot(s1_awprot), .s_axi_awqos(s1_awqos), .s_axi_awregion(s1_awregion), .s_axi_awvalid(s1_awvalid), .s_axi_awready(s1_awready),
        .s_axi_wdata(s1_wdata), .s_axi_wstrb(s1_wstrb), .s_axi_wlast(s1_wlast), .s_axi_wvalid(s1_wvalid), .s_axi_wready(s1_wready),
        .s_axi_bid(s1_bid), .s_axi_bresp(s1_bresp), .s_axi_bvalid(s1_bvalid), .s_axi_bready(s1_bready),
        .s_axi_arid(s1_arid), .s_axi_araddr(s1_araddr), .s_axi_arlen(s1_arlen), .s_axi_arsize(s1_arsize), .s_axi_arburst(s1_arburst), .s_axi_arlock(s1_arlock), .s_axi_arcache(s1_arcache), .s_axi_arprot(s1_arprot), .s_axi_arqos(s1_arqos), .s_axi_arregion(s1_arregion), .s_axi_arvalid(s1_arvalid), .s_axi_arready(s1_arready),
        .s_axi_rid(s1_rid), .s_axi_rdata(s1_rdata), .s_axi_rresp(s1_rresp), .s_axi_rlast(s1_rlast), .s_axi_rvalid(s1_rvalid), .s_axi_rready(s1_rready)
    );

    // Hi half: DMA-facing buffers.  Same macro budget as the lo half.
    axi_ram #(
        .ID_WIDTH(SLV_ID_WIDTH),
        .ADDR_MASK(32'h0001_FFFF),
        .MEM_DEPTH(32768)
    ) u_axi_ram_hi (
        .clk(clk), .rst_n(reset_sys_n),
        .s_axi_awid(s6_awid), .s_axi_awaddr(s6_awaddr), .s_axi_awlen(s6_awlen), .s_axi_awsize(s6_awsize), .s_axi_awburst(s6_awburst), .s_axi_awlock(s6_awlock), .s_axi_awcache(s6_awcache), .s_axi_awprot(s6_awprot), .s_axi_awqos(s6_awqos), .s_axi_awregion(s6_awregion), .s_axi_awvalid(s6_awvalid), .s_axi_awready(s6_awready),
        .s_axi_wdata(s6_wdata), .s_axi_wstrb(s6_wstrb), .s_axi_wlast(s6_wlast), .s_axi_wvalid(s6_wvalid), .s_axi_wready(s6_wready),
        .s_axi_bid(s6_bid), .s_axi_bresp(s6_bresp), .s_axi_bvalid(s6_bvalid), .s_axi_bready(s6_bready),
        .s_axi_arid(s6_arid), .s_axi_araddr(s6_araddr), .s_axi_arlen(s6_arlen), .s_axi_arsize(s6_arsize), .s_axi_arburst(s6_arburst), .s_axi_arlock(s6_arlock), .s_axi_arcache(s6_arcache), .s_axi_arprot(s6_arprot), .s_axi_arqos(s6_arqos), .s_axi_arregion(s6_arregion), .s_axi_arvalid(s6_arvalid), .s_axi_arready(s6_arready),
        .s_axi_rid(s6_rid), .s_axi_rdata(s6_rdata), .s_axi_rresp(s6_rresp), .s_axi_rlast(s6_rlast), .s_axi_rvalid(s6_rvalid), .s_axi_rready(s6_rready)
    );

    axi_spi_flash #(
        .ID_WIDTH(SLV_ID_WIDTH)
    ) u_axi_flash (
        .clk(clk), .rst_n(reset_sys_n),
        
        // Giao diện Quad SPI vật lý
        .spi_clk_o  (flash_sck), 
        .spi_cs_n_o (flash_cs_n), 
        .spi_io0_o  (flash_io_o[0]), .spi_io0_i  (flash_io_i[0]), .spi_io0_oe (flash_io_oe[0]),
        .spi_io1_o  (flash_io_o[1]), .spi_io1_i  (flash_io_i[1]), .spi_io1_oe (flash_io_oe[1]),
        .spi_io2_o  (flash_io_o[2]), .spi_io2_i  (flash_io_i[2]), .spi_io2_oe (flash_io_oe[2]),
        .spi_io3_o  (flash_io_o[3]), .spi_io3_i  (flash_io_i[3]), .spi_io3_oe (flash_io_oe[3]),

        // Các kênh AXI giữ nguyên
        .s_axi_arid   (s2_arid),    .s_axi_araddr (s2_araddr), 
        .s_axi_arlen  (s2_arlen),   .s_axi_arsize (s2_arsize), 
        .s_axi_arburst(s2_arburst), .s_axi_arvalid(s2_arvalid), 
        .s_axi_arready(s2_arready),
        .s_axi_rid    (s2_rid),     .s_axi_rdata  (s2_rdata), 
        .s_axi_rresp  (s2_rresp),   .s_axi_rlast  (s2_rlast), 
        .s_axi_rvalid (s2_rvalid),  .s_axi_rready (s2_rready),
        
        // Cắm cứng kênh Ghi bằng 0 vì module bạn chặn kênh Ghi rồi (Hoặc nối vào s2_*)
        .s_axi_awid(s2_awid), .s_axi_awaddr(s2_awaddr), .s_axi_awlen(s2_awlen), .s_axi_awsize(s2_awsize), .s_axi_awburst(s2_awburst), .s_axi_awvalid(s2_awvalid), .s_axi_awready(s2_awready),
        .s_axi_wdata(s2_wdata), .s_axi_wstrb(s2_wstrb), .s_axi_wlast(s2_wlast), .s_axi_wvalid(s2_wvalid), .s_axi_wready(s2_wready),
        .s_axi_bid(s2_bid), .s_axi_bresp(s2_bresp), .s_axi_bvalid(s2_bvalid), .s_axi_bready(s2_bready)
    );

    // Tham so thoi gian tinh lai cho chu ky 4 ns (250 MHz). Mac dinh cua
    // module la cho 5 ns; giu nguyen so chu ky thi tRP/tRCD con 16 ns va tRFC
    // 56 ns - vi pham chip SDRAM. Moi gia tri duoi day >= gia tri ns cu:
    //   tRP/tRCD/tWR 20 ns -> 5, tRFC 70 ns -> 18, init 200 us -> 50000,
    //   refresh 7.8 us -> 1950. CL van la 3 (don vi la chu ky SDRAM, khong
    //   phai ns) - chip phai ho tro CL3 o 250 MHz, xem ghi chu o sdram_clk.
    axi_sdram_controller #(
        .ID_WIDTH(SLV_ID_WIDTH),
        .SDRAM_DATA_WIDTH(16),
        .INIT_DELAY_CYCLES     (50000),
        .TRP_CYCLES            (5),
        .TRCD_CYCLES           (5),
        .TCAS_CYCLES           (3),
        .TRFC_CYCLES           (18),
        .TWR_CYCLES            (5),
        .REFRESH_PERIOD_CYCLES (1950)
    ) u_axi_sdram (
        .clk(clk), .rst_n(reset_sys_n),
        .sdram_clk(), .sdram_cke(sdram_cke), .sdram_cs_n(sdram_cs_n), .sdram_ras_n(sdram_ras_n),
        .sdram_cas_n(sdram_cas_n), .sdram_we_n(sdram_we_n), .sdram_ba(sdram_ba), .sdram_addr(sdram_addr),
        .sdram_dqm(sdram_dqm), .sdram_dq_i(sdram_dq_i), .sdram_dq_o(sdram_dq_o), .sdram_dq_oe(sdram_dq_oe),
        .s_axi_awid(s3_awid), .s_axi_awaddr(s3_awaddr), .s_axi_awlen(s3_awlen), .s_axi_awsize(s3_awsize), .s_axi_awburst(s3_awburst), .s_axi_awvalid(s3_awvalid), .s_axi_awready(s3_awready),
        .s_axi_wdata(s3_wdata), .s_axi_wstrb(s3_wstrb), .s_axi_wlast(s3_wlast), .s_axi_wvalid(s3_wvalid), .s_axi_wready(s3_wready),
        .s_axi_bid(s3_bid), .s_axi_bresp(s3_bresp), .s_axi_bvalid(s3_bvalid), .s_axi_bready(s3_bready),
        .s_axi_arid(s3_arid), .s_axi_araddr(s3_araddr), .s_axi_arlen(s3_arlen), .s_axi_arsize(s3_arsize), .s_axi_arburst(s3_arburst), .s_axi_arvalid(s3_arvalid), .s_axi_arready(s3_arready),
        .s_axi_rid(s3_rid), .s_axi_rdata(s3_rdata), .s_axi_rresp(s3_rresp), .s_axi_rlast(s3_rlast), .s_axi_rvalid(s3_rvalid), .s_axi_rready(s3_rready)
    );

    wire [31:0] apb_paddr, apb_pwdata, apb_prdata; wire [3:0] apb_pstrb; wire [2:0] apb_pprot;
    wire apb_psel, apb_penable, apb_pwrite, apb_pready, apb_pslverr;
    axi_to_apb_bridge #(
        .ID_WIDTH(SLV_ID_WIDTH)
    ) u_axi_to_apb (
        .clk(clk), .rst_n(reset_sys_n),
        .s_axi_awid(s4_awid), .s_axi_awaddr(s4_awaddr), .s_axi_awlen(s4_awlen), .s_axi_awsize(s4_awsize), .s_axi_awburst(s4_awburst), .s_axi_awprot(s4_awprot), .s_axi_awvalid(s4_awvalid), .s_axi_awready(s4_awready),
        .s_axi_wdata(s4_wdata), .s_axi_wstrb(s4_wstrb), .s_axi_wlast(s4_wlast), .s_axi_wvalid(s4_wvalid), .s_axi_wready(s4_wready),
        .s_axi_bid(s4_bid), .s_axi_bresp(s4_bresp), .s_axi_bvalid(s4_bvalid), .s_axi_bready(s4_bready),
        .s_axi_arid(s4_arid), .s_axi_araddr(s4_araddr), .s_axi_arlen(s4_arlen), .s_axi_arsize(s4_arsize), .s_axi_arburst(s4_arburst), .s_axi_arprot(s4_arprot), .s_axi_arvalid(s4_arvalid), .s_axi_arready(s4_arready),
        .s_axi_rid(s4_rid), .s_axi_rdata(s4_rdata), .s_axi_rresp(s4_rresp), .s_axi_rlast(s4_rlast), .s_axi_rvalid(s4_rvalid), .s_axi_rready(s4_rready),
        .m_apb_paddr(apb_paddr), .m_apb_psel(apb_psel), .m_apb_penable(apb_penable), .m_apb_pwrite(apb_pwrite), .m_apb_pwdata(apb_pwdata), .m_apb_pstrb(apb_pstrb), .m_apb_pprot(apb_pprot),
        .m_apb_pready(apb_pready), .m_apb_prdata(apb_prdata), .m_apb_pslverr(apb_pslverr)
    );

    // S5: CLINT
    axi_clint #(
        .NUM_HARTS      (1),
        .HART_IDX_W     (1),
        .AXI_ADDR_WIDTH (32),
        .AXI_ID_WIDTH   (SLV_ID_WIDTH),     // = MST_ID_WIDTH + $clog2(MST_AMT)
        .PIPELINE_IRQ   (1)
    ) u_clint (
        // Clocks & Reset
        .clk_i          (clk),
        .rst_ni         (reset_sys_n),
        .rtc_tick_i     (rtc_tick),         // mtime tang 32.768 kHz (muc 1)
        
        // AXI Write Address Channel
        .s_axi_awid     (s5_awid), 
        .s_axi_awaddr   (s5_awaddr), 
        .s_axi_awlen    (s5_awlen), 
        .s_axi_awsize   (s5_awsize), 
        .s_axi_awburst  (s5_awburst), 
        .s_axi_awlock   (s5_awlock),
        .s_axi_awcache  (s5_awcache),
        .s_axi_awprot   (s5_awprot), 
        .s_axi_awqos    (s5_awqos),
        .s_axi_awregion (s5_awregion),
        .s_axi_awvalid  (s5_awvalid), 
        .s_axi_awready  (s5_awready),    
        
        // AXI Write Data Channel
        .s_axi_wdata    (s5_wdata), 
        .s_axi_wstrb    (s5_wstrb), 
        .s_axi_wlast    (s5_wlast), 
        .s_axi_wvalid   (s5_wvalid), 
        .s_axi_wready   (s5_wready),
        
        // AXI Write Response Channel
        .s_axi_bid      (s5_bid), 
        .s_axi_bresp    (s5_bresp), 
        .s_axi_bvalid   (s5_bvalid), 
        .s_axi_bready   (s5_bready),
        
        // AXI Read Address Channel
        .s_axi_arid     (s5_arid), 
        .s_axi_araddr   (s5_araddr), 
        .s_axi_arlen    (s5_arlen), 
        .s_axi_arsize   (s5_arsize), 
        .s_axi_arburst  (s5_arburst), 
        .s_axi_arlock   (s5_arlock),
        .s_axi_arcache  (s5_arcache),
        .s_axi_arprot   (s5_arprot), 
        .s_axi_arqos    (s5_arqos),
        .s_axi_arregion (s5_arregion),
        .s_axi_arvalid  (s5_arvalid), 
        .s_axi_arready  (s5_arready),     
        
        // AXI Read Data Channel
        .s_axi_rid      (s5_rid), 
        .s_axi_rdata    (s5_rdata), 
        .s_axi_rresp    (s5_rresp), 
        .s_axi_rlast    (s5_rlast), 
        .s_axi_rvalid   (s5_rvalid), 
        .s_axi_rready   (s5_rready),
        
        // Interrupt Outputs (Nối vào tín hiệu raw đã được tạo, sẽ qua Sync bọc lại sau)
        .msip_o         (cpu_msip_raw),
        .mtip_o         (cpu_mtip_raw)
    );

    // =========================================================================
    // 9. APB INTERCONNECT VÀ CÁC NGOẠI VI
    //
    // Ban do dia chi (khop 1:1 voi param SLVn_BASE/SLVn_MASK cua
    // apb_interconnect - sua mot ben ma quen ben kia la loi im lang):
    //   S0  0x4000_0000  4 KB   UART
    //   S1  0x4000_1000  4 KB   GPIO
    //   S2  0x4000_2000  4 KB   PWM / Timer
    //   S3  0x4000_3000  4 KB   SPI
    //   S4  0x4000_4000  4 KB   I2C
    //   S5  0x4000_5000  4 KB   Watchdog
    //   S6  0x4000_6000  4 KB   CORDIC
    //   S7  0x4000_7000  4 KB   Syscon
    //   S9  0x4000_8000  16 KB  DMA config   (0x4000_8000-0x4000_BFFF)
    //   S10 0x4000_C000  4 KB   ASCON + TRNG
    //   S11 0x4000_D000  4 KB   UART1                 (2026-09-11)
    //   S12 0x4000_E000  4 KB   TIM0                  (2026-09-11)
    //   S13 0x4000_F000  4 KB   TIM1                  (2026-09-11)
    //   S14 0x4002_0000  4 KB   PINMUX                (2026-09-11)
    //   S8  0x4400_0000  64 MB  CLIC (thay PLIC; thanh ghi o 8 KB dau)
    // =========================================================================
    wire [31:0] paddr_0, paddr_1, paddr_2, paddr_3, paddr_4, paddr_5, paddr_6, paddr_7, paddr_8, paddr_9, paddr_10;
    wire [31:0] pwdata_0, pwdata_1, pwdata_2, pwdata_3, pwdata_4, pwdata_5, pwdata_6, pwdata_7, pwdata_8, pwdata_9, pwdata_10;
    wire [31:0] prdata_0, prdata_1, prdata_2, prdata_3, prdata_4, prdata_5, prdata_6, prdata_7, prdata_8, prdata_9, prdata_10;
    wire [3:0] pstrb_0, pstrb_1, pstrb_2, pstrb_3, pstrb_4, pstrb_5, pstrb_6, pstrb_7, pstrb_8;
    wire [2:0] pprot_0, pprot_1, pprot_2, pprot_3, pprot_4, pprot_5, pprot_6, pprot_7;
    wire psel_0, psel_1, psel_2, psel_3, psel_4, psel_5, psel_6, psel_7, psel_8, psel_9, psel_10;
    wire penable_0, penable_1, penable_2, penable_3, penable_4, penable_5, penable_6, penable_7, penable_8, penable_9, penable_10;
    wire pwrite_0, pwrite_1, pwrite_2, pwrite_3, pwrite_4, pwrite_5, pwrite_6, pwrite_7, pwrite_8, pwrite_9, pwrite_10;
    wire pready_0, pready_1, pready_2, pready_3, pready_4, pready_5, pready_6, pready_7, pready_8, pready_9, pready_10;
    wire pslverr_0, pslverr_1, pslverr_2, pslverr_3, pslverr_4, pslverr_5, pslverr_6, pslverr_7, pslverr_8, pslverr_9, pslverr_10;
    wire [31:0] paddr_11, paddr_12, paddr_13, paddr_14;
    wire [31:0] pwdata_11, pwdata_12, pwdata_13, pwdata_14;
    wire [31:0] prdata_11, prdata_12, prdata_13, prdata_14;
    wire [3:0]  pstrb_11, pstrb_12, pstrb_13, pstrb_14;
    wire psel_11, psel_12, psel_13, psel_14;
    wire penable_11, penable_12, penable_13, penable_14;
    wire pwrite_11, pwrite_12, pwrite_13, pwrite_14;
    wire pready_11, pready_12, pready_13, pready_14;
    wire pslverr_11, pslverr_12, pslverr_13, pslverr_14;

    // Tin hieu ngoai vi <-> pinmux (truoc day la chan top_soc)
    wire        uart_rx, uart_tx, uart1_rx, uart1_tx;
    wire [31:0] gpio_in, gpio_out, gpio_oe;
    wire        pwm_out;
    wire        spi_sck, spi_mosi, spi_miso, spi_ss;
    wire        i2c_scl_i, i2c_scl_o, i2c_scl_oe;
    wire        i2c_sda_i, i2c_sda_o, i2c_sda_oe;
    wire [3:0]  tim0_ch_i, tim0_ch_o, tim0_ch_oe;
    wire [3:0]  tim1_ch_i, tim1_ch_o, tim1_ch_oe;

    apb_interconnect u_apb_interconnect (
        .clk(clk), .rst_n(reset_sys_n),
        .m_paddr(apb_paddr), .m_psel(apb_psel), .m_penable(apb_penable), .m_pwrite(apb_pwrite), .m_pwdata(apb_pwdata), .m_pstrb(apb_pstrb), .m_pprot(apb_pprot), .m_pready(apb_pready), .m_prdata(apb_prdata), .m_pslverr(apb_pslverr),
        .s0_paddr(paddr_0), .s0_psel(psel_0), .s0_penable(penable_0), .s0_pwrite(pwrite_0), .s0_pwdata(pwdata_0), .s0_pstrb(pstrb_0), .s0_pprot(pprot_0), .s0_pready(pready_0), .s0_prdata(prdata_0), .s0_pslverr(pslverr_0),
        .s1_paddr(paddr_1), .s1_psel(psel_1), .s1_penable(penable_1), .s1_pwrite(pwrite_1), .s1_pwdata(pwdata_1), .s1_pstrb(pstrb_1), .s1_pprot(pprot_1), .s1_pready(pready_1), .s1_prdata(prdata_1), .s1_pslverr(pslverr_1),
        .s2_paddr(paddr_2), .s2_psel(psel_2), .s2_penable(penable_2), .s2_pwrite(pwrite_2), .s2_pwdata(pwdata_2), .s2_pstrb(pstrb_2), .s2_pprot(pprot_2), .s2_pready(pready_2), .s2_prdata(prdata_2), .s2_pslverr(pslverr_2),
        .s3_paddr(paddr_3), .s3_psel(psel_3), .s3_penable(penable_3), .s3_pwrite(pwrite_3), .s3_pwdata(pwdata_3), .s3_pstrb(pstrb_3), .s3_pprot(pprot_3), .s3_pready(pready_3), .s3_prdata(prdata_3), .s3_pslverr(pslverr_3),
        .s4_paddr(paddr_4), .s4_psel(psel_4), .s4_penable(penable_4), .s4_pwrite(pwrite_4), .s4_pwdata(pwdata_4), .s4_pstrb(pstrb_4), .s4_pprot(pprot_4), .s4_pready(pready_4), .s4_prdata(prdata_4), .s4_pslverr(pslverr_4),
        .s5_paddr(paddr_5), .s5_psel(psel_5), .s5_penable(penable_5), .s5_pwrite(pwrite_5), .s5_pwdata(pwdata_5), .s5_pstrb(pstrb_5), .s5_pprot(pprot_5), .s5_pready(pready_5), .s5_prdata(prdata_5), .s5_pslverr(pslverr_5),
        .s6_paddr(paddr_6), .s6_psel(psel_6), .s6_penable(penable_6), .s6_pwrite(pwrite_6), .s6_pwdata(pwdata_6), .s6_pstrb(pstrb_6), .s6_pprot(pprot_6), .s6_pready(pready_6), .s6_prdata(prdata_6), .s6_pslverr(pslverr_6),
        .s7_paddr(paddr_7), .s7_psel(psel_7), .s7_penable(penable_7), .s7_pwrite(pwrite_7), .s7_pwdata(pwdata_7), .s7_pstrb(pstrb_7), .s7_pprot(pprot_7), .s7_pready(pready_7), .s7_prdata(prdata_7), .s7_pslverr(pslverr_7),
        .s8_paddr(paddr_8), .s8_psel(psel_8), .s8_penable(penable_8), .s8_pwrite(pwrite_8), .s8_pwdata(pwdata_8), .s8_pstrb(pstrb_8), .s8_pready(pready_8), .s8_prdata(prdata_8), .s8_pslverr(pslverr_8),
        .s9_paddr(paddr_9), .s9_psel(psel_9), .s9_penable(penable_9), .s9_pwrite(pwrite_9), .s9_pwdata(pwdata_9), .s9_pready(pready_9), .s9_prdata(prdata_9), .s9_pslverr(pslverr_9),
        .s10_paddr(paddr_10), .s10_psel(psel_10), .s10_penable(penable_10), .s10_pwrite(pwrite_10), .s10_pwdata(pwdata_10), .s10_pready(pready_10), .s10_prdata(prdata_10), .s10_pslverr(pslverr_10),
        .s11_paddr(paddr_11), .s11_psel(psel_11), .s11_penable(penable_11), .s11_pwrite(pwrite_11), .s11_pwdata(pwdata_11), .s11_pstrb(pstrb_11), .s11_pready(pready_11), .s11_prdata(prdata_11), .s11_pslverr(pslverr_11),
        .s12_paddr(paddr_12), .s12_psel(psel_12), .s12_penable(penable_12), .s12_pwrite(pwrite_12), .s12_pwdata(pwdata_12), .s12_pstrb(pstrb_12), .s12_pready(pready_12), .s12_prdata(prdata_12), .s12_pslverr(pslverr_12),
        .s13_paddr(paddr_13), .s13_psel(psel_13), .s13_penable(penable_13), .s13_pwrite(pwrite_13), .s13_pwdata(pwdata_13), .s13_pstrb(pstrb_13), .s13_pready(pready_13), .s13_prdata(prdata_13), .s13_pslverr(pslverr_13),
        .s14_paddr(paddr_14), .s14_psel(psel_14), .s14_penable(penable_14), .s14_pwrite(pwrite_14), .s14_pwdata(pwdata_14), .s14_pstrb(pstrb_14), .s14_pready(pready_14), .s14_prdata(prdata_14), .s14_pslverr(pslverr_14)
    );

    // -------------------------------------------------------------------------
    // Keo dai yeu cau clock cua ba ngoai vi dat thanh ghi tren clock da gate.
    // Xem ghi chu day du o muc 2 (CLOCK GATING NETWORK).
    //
    // Hai chu ky la du: `pready <= psel && penable` la mot tang flop duy nhat,
    // nen no can DUNG mot canh sau khi psel ha de tro ve 0.
    // -------------------------------------------------------------------------
    reg [1:0] psel_gpio_ext, psel_pwm_ext, psel_cordic_ext, psel_ascon_ext;
    reg [1:0] psel_uart_ext, psel_spi_ext, psel_i2c_ext;
    reg [1:0] psel_uart1_ext, psel_tim0_ext, psel_tim1_ext;
    always @(posedge clk or negedge reset_sys_n) begin
        if (!reset_sys_n) begin
            psel_gpio_ext   <= 2'b00;
            psel_pwm_ext    <= 2'b00;
            psel_cordic_ext <= 2'b00;
            psel_ascon_ext  <= 2'b00;
            psel_uart_ext   <= 2'b00;
            psel_spi_ext    <= 2'b00;
            psel_i2c_ext    <= 2'b00;
            psel_uart1_ext  <= 2'b00;
            psel_tim0_ext   <= 2'b00;
            psel_tim1_ext   <= 2'b00;
        end else begin
            psel_gpio_ext   <= {psel_gpio_ext[0],   psel_1};
            psel_pwm_ext    <= {psel_pwm_ext[0],    psel_2};
            psel_cordic_ext <= {psel_cordic_ext[0], psel_6};
            psel_ascon_ext  <= {psel_ascon_ext[0],  psel_10};
            psel_uart_ext   <= {psel_uart_ext[0],   psel_0};
            psel_spi_ext    <= {psel_spi_ext[0],    psel_3};
            psel_i2c_ext    <= {psel_i2c_ext[0],    psel_4};
            psel_uart1_ext  <= {psel_uart1_ext[0],  psel_11};
            psel_tim0_ext   <= {psel_tim0_ext[0],   psel_12};
            psel_tim1_ext   <= {psel_tim1_ext[0],   psel_13};
        end
    end
    assign uart1_clk_req  = psel_11 | (|psel_uart1_ext);
    assign tim0_clk_req   = psel_12 | (|psel_tim0_ext);
    assign tim1_clk_req   = psel_13 | (|psel_tim1_ext);
    assign gpio_clk_req   = psel_1 | (|psel_gpio_ext);
    assign pwm_clk_req    = psel_2 | (|psel_pwm_ext);
    // UART / SPI / I2C: chi psel, KHONG co "core active" nhu CORDIC. Dung nghia
    // cu cua CLK_GATE_CTRL: bit tat thi loi ngung, ke ca giua mot byte.
    assign uart_clk_req   = psel_0 | (|psel_uart_ext);
    assign spi_clk_req    = psel_3 | (|psel_spi_ext);
    assign i2c_clk_req    = psel_4 | (|psel_i2c_ext);
    // CORDIC khac GPIO/PWM: no khong chi la mot dong thanh ghi, ma la mot LOI
    // TINH TOAN nhieu chu ky.  Neu chi keo dai theo PSEL thi lenh START se mat
    // clock ngay sau chu ky ghi va FSM ket o CALC vinh vien (STATUS ket BUSY,
    // X_OUT/Y_OUT khong bao gio ra).  Vi vay phai OR them `cordic_active`.
    assign cordic_clk_req = psel_6 | (|psel_cordic_ext) | cordic_active;
    // ASCON giong CORDIC: mot lenh START chay 12 chu ky, mot khoi du lieu 6/12
    // chu ky, va TRNG can 128 chu ky lien tuc de `valid` len. `ascon_active`
    // (busy | START | DATA_VALID | TRNG_EN) giu cong mo suot thoi gian do.
    assign ascon_clk_req  = psel_10 | (|psel_ascon_ext) | ascon_active;

    // S0: UART
    // Baud = f_clk / CLK_DIV: o 250 MHz, 115200 baud can TX_DIV = 2170,
    // RX_DIV = 135 (Driver/src/main.c: UART_CLK).
    apb_uart u_apb_uart (
        .pclk(clk_uart), .presetn(reset_sys_n),
        .psel(psel_0), .penable(penable_0), .pwrite(pwrite_0), .paddr(paddr_0[11:0]), .pwdata(pwdata_0), .prdata(prdata_0), .pready(pready_0), .pslverr(pslverr_0),
        .rxd(uart_rx), .txd(uart_tx),
        .uart_irq(uart_irq), .dma_tx_req(uart_dma_tx), .dma_rx_req(uart_dma_rx)
    );

    // S1: GPIO (Dùng nguyên bản gốc)
    apb_gpio u_apb_gpio (
        .pclk(clk_gpio), .presetn(reset_sys_n),
        .psel(psel_1), .penable(penable_1), .pwrite(pwrite_1), .paddr(paddr_1[11:0]), .pwdata(pwdata_1), .prdata(prdata_1), .pready(pready_1), .pslverr(pslverr_1),
        .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_dir(gpio_oe),
        .gpio_irq(gpio_irq)
    );

    // S2: PWM
    apb_pwm u_apb_pwm (
        .pclk(clk_pwm), .presetn(reset_sys_n),
        .psel(psel_2), .penable(penable_2), .pwrite(pwrite_2), .paddr(paddr_2[11:0]), .pwdata(pwdata_2), .pstrb(pstrb_2), .prdata(prdata_2), .pready(pready_2), .pslverr(pslverr_2),
        .pwm_out(pwm_out)
    );

    // S3: SPI
    apb_spi u_apb_spi (
        .pclk(clk_spi), .presetn(reset_sys_n),
        .psel(psel_3), .penable(penable_3), .pwrite(pwrite_3), .paddr(paddr_3[11:0]), .pwdata(pwdata_3), .pstrb(pstrb_3), .prdata(prdata_3), .pready(pready_3), .pslverr(pslverr_3),
        .sclk(spi_sck), .mosi(spi_mosi), .miso(spi_miso), .cs_n(spi_ss),
        .spi_irq(spi_irq), .dma_tx_req(spi_dma_tx), .dma_rx_req(spi_dma_rx)
    );

    // S4: I2C
    wire i2c_scl_oen;
    wire i2c_sda_oen;
    // apb_i2c exposes active-low OEN signals; convert them to the active-high
    // output enables expected by the chip I/O wrapper/pad ring.
    assign i2c_scl_oe = ~i2c_scl_oen;
    assign i2c_sda_oe = ~i2c_sda_oen;
    apb_i2c u_apb_i2c (
        .pclk(clk_i2c), .presetn(reset_sys_n),
        .psel(psel_4), .penable(penable_4), .pwrite(pwrite_4), .paddr(paddr_4[11:0]), .pwdata(pwdata_4), .pstrb(pstrb_4), .prdata(prdata_4), .pready(pready_4), .pslverr(pslverr_4),
        .scl_o(i2c_scl_o), .scl_oen(i2c_scl_oen), .scl_i(i2c_scl_i), .sda_o(i2c_sda_o), .sda_oen(i2c_sda_oen), .sda_i(i2c_sda_i),
        .i2c_irq(i2c_irq), .dma_tx_req(i2c_dma_tx), .dma_rx_req(i2c_dma_rx)
    );

    // S5: Watchdog - dem theo rtc_tick (muc 1), chay bang clk KHONG gate.
    // DBGCTRL.DBG_WDT_STOP (DM) dung bo dem khi core dang halt, nhu
    // DBGMCU_APB1_FZ.DBG_IWDG_STOP: neu khong, dung o breakpoint vai giay la
    // watchdog reset ca chip giua phien debug.
    wire wdt_tick = rtc_tick & ~(dbg_wdt_stop & dbg_halted_raw);
    apb_watchdog u_apb_watchdog (
        .pclk(clk), .presetn(reset_sys_n),
        .psel(psel_5), .penable(penable_5), .pwrite(pwrite_5), .paddr(paddr_5[11:0]), .pwdata(pwdata_5), .pstrb(pstrb_5), .prdata(prdata_5), .pready(pready_5), .pslverr(pslverr_5),
        .rtc_tick(wdt_tick),
        .wdt_irq(wdt_irq), .wdt_rst(wdt_rst)
    );

    // S6: CORDIC
    apb_cordic u_apb_cordic (
        .pclk(clk_cordic), .presetn(reset_sys_n),
        .psel(psel_6), .penable(penable_6), .pwrite(pwrite_6), .paddr(paddr_6[11:0]), .pwdata(pwdata_6), .pstrb(pstrb_6), .prdata(prdata_6), .pready(pready_6), .pslverr(pslverr_6),
        .o_active(cordic_active)
    );

    // S7: Syscon - xem register map va hai mien reset trong apb_syscon.v
    apb_syscon u_apb_syscon (
        .pclk(clk), .presetn(reset_sys_n), .porn(reset_por_n),
        .psel(psel_7), .penable(penable_7), .pwrite(pwrite_7), .paddr(paddr_7[11:0]), .pwdata(pwdata_7), .prdata(prdata_7), .pready(pready_7), .pslverr(pslverr_7),
        .o_reset_vector(syscon_reset_vector), .i_wfi_sleep(wfi_sleep_q), .i_ext_irq(cpu_irq_wake),
        // haltreq cua debugger danh thuc CPU dang WFI (muc 4 cua review):
        // haltreq vao core qua clk_cpu, nen neu clock khong mo lai thi core
        // khong bao gio thay no.
        .i_dbg_halt_req(dbg_halt_req_raw),
        .i_dbg_keep_clk(dbg_sleep),
        .i_wdt_rst     (wdt_rst),
        .i_ndm_rst     (ndmreset_req),
        .o_sw_rst_req  (sw_rst_req),
        .i_dbg_clk_on  (clk_en_dbg),
        .o_dbg_allow   (dbg_allow),
        .o_cpu_clk_en  (clk_en_cpu),
        .o_pwm_clk_en  (clk_en_pwm),
        .o_urt_clk_en  (clk_en_uart),
        .o_spi_clk_en  (clk_en_spi),
        .o_i2c_clk_en  (clk_en_i2c),
        .o_gpo_clk_en  (clk_en_gpio),
        .o_acc_clk_en  (clk_en_acc),
        .o_asc_clk_en  (clk_en_asc),
        .o_ur1_clk_en  (clk_en_uart1),
        .o_tm0_clk_en  (clk_en_tim0),
        .o_tm1_clk_en  (clk_en_tim1)
    );

    // -------------------------------------------------------------------------
    // S8: CLIC (thay PLIC, 2026-09-11). Chay clk KHONG gate: phai thay moi canh
    // cua nguon ngat ke ca khi CPU dang ngu, va chinh no danh thuc CPU qua
    // cpu_irq_wake. Dau ra {valid, id, level, shv} di thang vao core - xem
    // interrupt/clic/clic.v de biet vi sao khong con claim/complete.
    // -------------------------------------------------------------------------
    clic #(
        .NUM_IRQ       (32),
        .CTLBITS       (3),
        .TRIG_EDGE_RST (32'h0400_0000)      // nguon 26 (loi store buffer) canh len
    ) u_clic (
        .clk        (clk),
        .rst_n      (reset_sys_n),
        .paddr      (paddr_8[25:0]),
        .psel       (psel_8),
        .penable    (penable_8),
        .pwrite     (pwrite_8),
        .pwdata     (pwdata_8),
        .pstrb      (pstrb_8),
        .pready     (pready_8),
        .prdata     (prdata_8),
        .pslverr    (pslverr_8),
        .irq_src    (clic_irq_src),
        .irq_valid  (clic_irq_valid),
        .irq_id     (clic_irq_id),
        .irq_level  (clic_irq_level),
        .irq_shv    (clic_irq_shv),
        .irq_ack    (clic_ack),
        .irq_ack_id (clic_ack_id)
    );

    // S11: UART1 - cung module voi UART0, clock gate rieng (CLK_GATE_CTRL[8]).
    apb_uart u_apb_uart1 (
        .pclk(clk_uart1), .presetn(reset_sys_n),
        .psel(psel_11), .penable(penable_11), .pwrite(pwrite_11), .paddr(paddr_11[11:0]), .pwdata(pwdata_11), .prdata(prdata_11), .pready(pready_11), .pslverr(pslverr_11),
        .rxd(uart1_rx), .txd(uart1_tx),
        .uart_irq(uart1_irq), .dma_tx_req(uart1_dma_tx), .dma_rx_req(uart1_dma_rx)
    );

    // S12 / S13: timer da nang 4 kenh capture/compare (peripheral/apb_timer.v).
    apb_timer u_tim0 (
        .pclk(clk_tim0), .presetn(reset_sys_n),
        .paddr(paddr_12[11:0]), .psel(psel_12), .penable(penable_12), .pwrite(pwrite_12), .pwdata(pwdata_12), .pstrb(pstrb_12), .pready(pready_12), .prdata(prdata_12), .pslverr(pslverr_12),
        .ch_i(tim0_ch_i), .ch_o(tim0_ch_o), .ch_oe(tim0_ch_oe),
        .irq(tim0_irq)
    );

    apb_timer u_tim1 (
        .pclk(clk_tim1), .presetn(reset_sys_n),
        .paddr(paddr_13[11:0]), .psel(psel_13), .penable(penable_13), .pwrite(pwrite_13), .pwdata(pwdata_13), .pstrb(pstrb_13), .pready(pready_13), .prdata(prdata_13), .pslverr(pslverr_13),
        .ch_i(tim1_ch_i), .ch_o(tim1_ch_o), .ch_oe(tim1_ch_oe),
        .irq(tim1_irq)
    );

    // S14: PINMUX - 32 pad, bang AF co dinh (peripheral/apb_pinmux.v). Clock
    // KHONG gate: phan mux la to hop, chi thanh ghi AFSEL can clock.
    apb_pinmux u_pinmux (
        .pclk(clk), .presetn(reset_sys_n),
        .paddr(paddr_14[11:0]), .psel(psel_14), .penable(penable_14), .pwrite(pwrite_14), .pwdata(pwdata_14), .pready(pready_14), .prdata(prdata_14), .pslverr(pslverr_14),
        .pad_in(pad_in), .pad_out(pad_out), .pad_oe(pad_oe),
        .gpio_out(gpio_out), .gpio_oe(gpio_oe), .gpio_in(gpio_in),
        .uart0_tx(uart_tx),  .uart0_rx(uart_rx),
        .uart1_tx(uart1_tx), .uart1_rx(uart1_rx),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_ss(spi_ss), .spi_miso(spi_miso),
        .i2c_scl_o(i2c_scl_o), .i2c_scl_oe(i2c_scl_oe), .i2c_scl_i(i2c_scl_i),
        .i2c_sda_o(i2c_sda_o), .i2c_sda_oe(i2c_sda_oe), .i2c_sda_i(i2c_sda_i),
        .pwm_out(pwm_out),
        .tim0_o(tim0_ch_o), .tim0_oe(tim0_ch_oe), .tim0_i(tim0_ch_i),
        .tim1_o(tim1_ch_o), .tim1_oe(tim1_ch_oe), .tim1_i(tim1_ch_i)
    );

    // S10: ASCON-128 AEAD / ASCON-HASH + TRNG 128-bit  (0x4000_C000, 4 KB)
    // Chay tren clock DA GATE nhu CORDIC, nen `o_active` bat buoc phai vong ve
    // `ascon_clk_req` - neu khong FSM se dong bang giua 12 vong hoan vi.
    apb_ascon u_apb_ascon (
        .PCLK(clk_ascon), .PRESETn(reset_sys_n),
        .PSEL(psel_10), .PENABLE(penable_10), .PWRITE(pwrite_10), .PADDR(paddr_10[11:0]),
        .PWDATA(pwdata_10), .PRDATA(prdata_10), .PREADY(pready_10), .PSLVERR(pslverr_10),
        .ascon_irq(ascon_irq),
        .o_active(ascon_active)
    );

    // =========================================================================
    // 10. DMA CONTROLLER
    //
    // Cong cau hinh APB cua DMA noi THANG vao slave S9 cua apb_interconnect.
    // Truoc day giua hai ben co apb_async_bridge (clk_apb 100 -> clk_axi 200
    // MHz) voi hai async FIFO; cung mot clock thi cau do da bo.
    // =========================================================================
    wire [13:0] dma_paddr   = paddr_9[13:0];
    wire [31:0] dma_pwdata  = pwdata_9;
    wire [31:0] dma_prdata;
    wire        dma_psel    = psel_9;
    wire        dma_penable = penable_9;
    wire        dma_pwrite  = pwrite_9;
    wire        dma_pready, dma_pslverr;
    assign prdata_9  = dma_prdata;
    assign pready_9  = dma_pready;
    assign pslverr_9 = dma_pslverr;

    wire [3:0] dma_axi_awid, dma_axi_awlen, dma_axi_bid;
    wire [3:0] dma_axi_arid, dma_axi_arlen, dma_axi_rid;

    assign m3_awid     = {1'b0, dma_axi_awid};
    assign m3_awlen    = {4'b0000, dma_axi_awlen};
    assign dma_axi_bid = m3_bid[3:0];
    assign m3_arid     = {1'b0, dma_axi_arid};
    assign m3_arlen    = {4'b0000, dma_axi_arlen};
    assign dma_axi_rid = m3_rid[3:0];
    assign m3_awprot   = 3'b000;
    assign m3_arprot   = 3'b000;

    axi_apb_dma u_axi_apb_dma (
        .clk_bus        (clk),
        .rst_bus_n      (reset_sys_n),

        // Giao tiếp APB Slave (S9 cua apb_interconnect)
        .s_apb_psel     (dma_psel), 
        .s_apb_penable  (dma_penable), 
        .s_apb_pwrite   (dma_pwrite), 
        .s_apb_paddr    (dma_paddr), 
        .s_apb_pwdata   (dma_pwdata), 
        .s_apb_prdata   (dma_prdata), 
        .s_apb_pslverr  (dma_pslverr), 
        .s_apb_pready   (dma_pready),

        // Ngắt và DMA Request từ ngoại vi (cùng miền clk, nối thẳng)
        .dma_irq        (dma_irq), 
        .periph_dma_req (periph_dma_req), 
        .periph_dma_clr (periph_dma_clr),

        // M-AXI Interface
        // Write Address Channel
        .m_axi_awid     (dma_axi_awid),
        .m_axi_awaddr   (m3_awaddr),
        .m_axi_awlen    (dma_axi_awlen),
        .m_axi_awsize   (m3_awsize),
        .m_axi_awburst  (m3_awburst),
        .m_axi_awvalid  (m3_awvalid),
        .m_axi_awready  (m3_awready),

        // Write Data Channel
        .m_axi_wdata    (m3_wdata),
        .m_axi_wstrb    (m3_wstrb),
        .m_axi_wlast    (m3_wlast),
        .m_axi_wvalid   (m3_wvalid),
        .m_axi_wready   (m3_wready),

        // Write Response Channel
        .m_axi_bid      (dma_axi_bid),
        .m_axi_bresp    (m3_bresp),
        .m_axi_bvalid   (m3_bvalid),
        .m_axi_bready   (m3_bready),

        // Read Address Channel
        .m_axi_arid     (dma_axi_arid),
        .m_axi_araddr   (m3_araddr),
        .m_axi_arlen    (dma_axi_arlen),
        .m_axi_arsize   (m3_arsize),
        .m_axi_arburst  (m3_arburst),
        .m_axi_arvalid  (m3_arvalid),
        .m_axi_arready  (m3_arready),

        // Read Data Channel
        .m_axi_rid      (dma_axi_rid),
        .m_axi_rdata    (m3_rdata),
        .m_axi_rresp    (m3_rresp),
        .m_axi_rlast    (m3_rlast),
        .m_axi_rvalid   (m3_rvalid),
        .m_axi_rready   (m3_rready)
    );

endmodule
