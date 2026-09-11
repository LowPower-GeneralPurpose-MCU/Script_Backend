`timescale 1ns / 1ps

// =============================================================================
// tb_sys_ctrl.sv - muc 4/5/6 cua review 2026-09-11, bang CPU THAT.
//
// run_soc_sim.sh sys bake tests/sys_ctrl.mem (sinh boi gen_sys_ctrl_mem.py) vao
// boot ROM. Testbench dong vai DTM o muc DMI: force thang dmi_req_* vao Debug
// Module, khong bit-bang JTAG.
//
//   Pha 0  Ngay sau POR, "debugger" xep san mot lenh DMI haltreq - dung kieu tan
//          cong dua voi boot ROM. SEC_CTRL con UNDECIDED nen DM bi giu reset:
//          lenh phai NAM CHO, core khong duoc halt.
//   Pha 1  Boot 1 doc RST_CAUSE (= EXT), xoa W1C, roi `wfi` voi mie = 0. SYSCON
//          phai tat clk_cpu that (clk_en_cpu = 0) - chi haltreq danh thuc duoc.
//   Pha 1b Het cua so DBG_DECIDE_CYCLES, debug tu OPEN. Lenh DMI dang cho duoc
//          thuc hien -> haltreq -> SYSCON mo lai clk_cpu -> core HALT. Day la loi
//          muc 4: truoc day core dang ngu khong bao gio halt.
//   Pha 2  Ghi/doc DBGCTRL (DMI 0x70), resume. Firmware ghi RESET_VECTOR roi
//          SW_RESET.
//   Pha 3  Boot 2 chi toi duoc neu RESET_VECTOR song qua warm reset. Doc
//          RST_CAUSE (= SW), khoa BOOT_LOCK va DBG_LOCK. Sau do lenh DMI haltreq
//          khong duoc tra loi va core khong halt.
// =============================================================================
module tb_sys_ctrl;

    localparam integer DECIDE_CYCLES = 4096;     // = apb_syscon.DBG_DECIDE_CYCLES

    integer pass_count = 0;
    integer fail_count = 0;

    task automatic chk(input [511:0] name, input ok);
        begin
            if (ok) begin
                pass_count = pass_count + 1;
                $display("[TB][PASS] %0s", name);
            end else begin
                fail_count = fail_count + 1;
                $display("[TB][FAIL] %0s  (t=%0t)", name, $time);
            end
        end
    endtask

    task automatic chk32(input [511:0] name, input [31:0] got, input [31:0] exp);
        begin
            if (got === exp) begin
                pass_count = pass_count + 1;
                $display("[TB][PASS] %0s = %08h", name, got);
            end else begin
                fail_count = fail_count + 1;
                $display("[TB][FAIL] %0s = %08h  (mong doi %08h)", name, got, exp);
            end
        end
    endtask

    // ---- clock / reset -------------------------------------------------------
    reg clk, rtc_clk;
    reg rst_n;
    initial begin clk     = 0; forever #2.0   clk     = ~clk;     end // 250 MHz
    initial begin rtc_clk = 0; forever #15258 rtc_clk = ~rtc_clk; end

    // ---- chan ngoai vi (giong tb_core_jalr.sv) --------------------------------
    reg  tck, trst_n, tms, tdi;
    wire tdo;
    wire uart_tx, uart_rx;
    wire spi_sck, spi_mosi, spi_miso, spi_ss;
    wire i2c_scl, i2c_sda;
    reg  [31:0] gpio_in;
    wire [31:0] gpio_out, gpio_oe;
    wire pwm_out;
    wire flash_sck, flash_cs_n;
    wire [3:0]  flash_io;
    wire sdram_clk, sdram_cke, sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n;
    wire [1:0]  sdram_ba, sdram_dqm;
    wire [12:0] sdram_addr;
    wire [15:0] sdram_dq;
    wire        dut_i2c_scl_o, dut_i2c_scl_oe;
    wire        dut_i2c_sda_o, dut_i2c_sda_oe;
    wire [3:0]  dut_flash_io_o, dut_flash_io_oe;
    wire [15:0] dut_sdram_dq_o;
    wire        dut_sdram_dq_oe;

    assign i2c_scl     = dut_i2c_scl_oe     ? dut_i2c_scl_o     : 1'bz;
    assign i2c_sda     = dut_i2c_sda_oe     ? dut_i2c_sda_o     : 1'bz;
    assign flash_io[0] = dut_flash_io_oe[0] ? dut_flash_io_o[0] : 1'bz;
    assign flash_io[1] = dut_flash_io_oe[1] ? dut_flash_io_o[1] : 1'bz;
    assign flash_io[2] = dut_flash_io_oe[2] ? dut_flash_io_o[2] : 1'bz;
    assign flash_io[3] = dut_flash_io_oe[3] ? dut_flash_io_o[3] : 1'bz;
    assign sdram_dq    = dut_sdram_dq_oe    ? dut_sdram_dq_o    : 16'hzzzz;
    assign uart_tx     = gpio_out[0];     // PA0 = UART0_TX sau reset
    assign uart_rx     = uart_tx;
    assign spi_miso    = spi_mosi;
    pullup(i2c_scl);
    pullup(i2c_sda);

    top_soc uut (
        .clk           (clk),
        .rtc_clk       (rtc_clk),
        .rst_n         (rst_n),
        .tck(tck), .trst_n(trst_n), .tms(tms), .tdi(tdi), .tdo(tdo),
        // 2026-09-11: 32 pad qua pinmux; mac dinh PA0 = UART0_TX, PA1 = RX.
        .pad_in({gpio_in[31:2], uart_rx, gpio_in[0]}), .pad_out(gpio_out), .pad_oe(gpio_oe),
        .flash_sck(flash_sck), .flash_cs_n(flash_cs_n),
        .flash_io_i(flash_io), .flash_io_o(dut_flash_io_o), .flash_io_oe(dut_flash_io_oe),
        .sdram_clk(sdram_clk), .sdram_cke(sdram_cke), .sdram_cs_n(sdram_cs_n),
        .sdram_ras_n(sdram_ras_n), .sdram_cas_n(sdram_cas_n), .sdram_we_n(sdram_we_n),
        .sdram_ba(sdram_ba), .sdram_addr(sdram_addr),
        .sdram_dq_i(sdram_dq), .sdram_dq_o(dut_sdram_dq_o), .sdram_dq_oe(dut_sdram_dq_oe),
        .sdram_dqm(sdram_dqm)
    );

    // ---- quan sat ---------------------------------------------------------------
    wire [31:0] reg_t2 = uut.u_core.RF.rf_main[7];
    wire [31:0] reg_a1 = uut.u_core.RF.rf_main[11];
    wire [31:0] reg_a2 = uut.u_core.RF.rf_main[12];
    wire [31:0] reg_a3 = uut.u_core.RF.rf_main[13];
    wire [31:0] reg_a4 = uut.u_core.RF.rf_main[14];
    wire [31:0] reg_a5 = uut.u_core.RF.rf_main[15];
    wire [31:0] reg_a6 = uut.u_core.RF.rf_main[16];

    wire halted    = uut.dbg_halted_raw;
    wire dbg_allow = uut.dbg_allow;

    // Core KHONG BAO GIO duoc halt khi debug chua mo.
    reg halted_while_closed = 1'b0;
    always @(posedge clk) if (halted && !dbg_allow) halted_while_closed <= 1'b1;

    // Dem warm reset (SW_RESET phai tao dung mot lan).
    integer warm_resets = 0;
    always @(negedge uut.reset_sys_n) if (rst_n) warm_resets = warm_resets + 1;

    // ---- DTM gia o muc DMI ------------------------------------------------------
    reg        dmi_valid_r = 1'b0;
    reg [6:0]  dmi_addr_r  = 7'd0;
    reg [31:0] dmi_data_r  = 32'd0;
    reg [1:0]  dmi_op_r    = 2'd0;

    initial begin
        force uut.dmi_req_valid = dmi_valid_r;
        force uut.dmi_req_addr  = dmi_addr_r;
        force uut.dmi_req_data  = dmi_data_r;
        force uut.dmi_req_op    = dmi_op_r;
    end

    task automatic dmi_start(input [6:0] addr, input [31:0] data, input [1:0] op);
        begin
            dmi_addr_r  = addr;
            dmi_data_r  = data;
            dmi_op_r    = op;
            #10;
            dmi_valid_r = 1'b1;
        end
    endtask

    // Cho resp_valid, ha req, cho resp_valid ha. ok = 0 neu het gio o buoc dau.
    task automatic dmi_finish(input integer timeout_ns, output reg ok, output reg [31:0] rdata);
        integer t;
        begin
            t = 0;
            while (uut.dmi_resp_valid !== 1'b1 && t < timeout_ns) begin #10; t = t + 10; end
            ok    = (uut.dmi_resp_valid === 1'b1);
            rdata = uut.dmi_resp_data;
            if (ok) begin
                dmi_valid_r = 1'b0;
                t = 0;
                while (uut.dmi_resp_valid !== 1'b0 && t < 2000) begin #10; t = t + 10; end
            end
        end
    endtask

    reg        ok;
    reg [31:0] rd;
    integer    waited;
    time       t_por_release, t_open;

    initial begin
        gpio_in = 32'h0;
        tck = 0; trst_n = 0; tms = 0; tdi = 0;   // DTM that nam yen trong reset
        rst_n = 1'b0;
        repeat (100) @(posedge clk);
        rst_n = 1'b1;
        t_por_release = $time;

        $display("");
        $display("=== tb_sys_ctrl: WFI + haltreq, RST_CAUSE, SW_RESET, RESET_VECTOR, khoa debug ===");

        // ---- Pha 0: lenh haltreq xep san, dua voi boot ROM ---------------------
        #100;
        dmi_start(7'h10, 32'h8000_0001, 2'd2);   // dmcontrol = haltreq | dmactive

        // ---- Pha 1: boot 1 toi wfi ---------------------------------------------
        waited = 0;
        while (reg_t2 !== 32'd1 && waited < 20_000) begin #50; waited = waited + 50; end
        chk("pha 1: boot 1 toi wfi (t2 = 1) du co haltreq dang cho", reg_t2 === 32'd1);
        chk32("RST_CAUSE sau POR (EXT)", reg_a1, 32'h1);
        chk32("RST_CAUSE sau W1C", reg_a2, 32'h0);
        chk32("CLK_GATE_CTRL: bit 6 (clock DM) = 0 khi debug chua mo", reg_a3, 32'h0000_0003);

        waited = 0;
        while (uut.clk_en_cpu !== 1'b0 && waited < 5_000) begin #10; waited = waited + 10; end
        chk("pha 1: WFI tat clk_cpu that (clk_en_cpu = 0)", uut.clk_en_cpu === 1'b0);
        chk("pha 1: debug con UNDECIDED, DM bi giu reset", !dbg_allow && (uut.reset_dbg_n === 1'b0));
        chk("pha 1: clock DM tat khi DM bi giu reset", uut.clk_en_dbg === 1'b0);
        chk("pha 1: lenh DMI dang cho KHONG duoc tra loi", uut.dmi_resp_valid !== 1'b1);
        chk("pha 1: core chua halt", halted !== 1'b1);

        // ---- Pha 1b: het cua so -> OPEN -> lenh cho chay -> halt ---------------
        waited = 0;
        while (dbg_allow !== 1'b1 && waited < 40_000) begin #10; waited = waited + 10; end
        t_open = $time;
        chk("pha 1b: debug tu OPEN khi ROM khong quyet dinh", dbg_allow === 1'b1);
        chk("pha 1b: cua so cho >= DBG_DECIDE_CYCLES chu ky",
            (t_open - t_por_release) >= DECIDE_CYCLES * 4);
        $display("[TB][INFO] debug mo sau %0t ns tu luc tha rst_n", t_open - t_por_release);

        dmi_finish(2_000, ok, rd);
        chk("pha 1b: DM tra loi lenh dmcontrol da xep san", ok);

        waited = 0;
        while (halted !== 1'b1 && waited < 2_000) begin #10; waited = waited + 10; end
        chk("pha 1b: haltreq danh thuc core dang WFI va core HALT", halted === 1'b1);
        chk("pha 1b: clk_cpu mo lai", uut.clk_en_cpu === 1'b1);
        chk("pha 1b: core het trang thai ngu", uut.wfi_sleep_state === 1'b0);
        chk32("pha 1b: t2 van = 1 (khong lenh nao chay them)", reg_t2, 32'd1);
        chk("khong co luc nao core halt khi debug dong", !halted_while_closed);

        // ---- Pha 2: DBGCTRL, resume --------------------------------------------
        dmi_start(7'h70, 32'h0000_0003, 2'd2);
        dmi_finish(2_000, ok, rd);
        chk("DMI ghi DBGCTRL", ok);
        dmi_start(7'h70, 32'h0, 2'd1);
        dmi_finish(2_000, ok, rd);
        chk32("DMI doc DBGCTRL (DBG_SLEEP | DBG_WDT_STOP)", rd, 32'h3);
        chk("DBGCTRL.DBG_SLEEP toi SYSCON", uut.dbg_sleep === 1'b1);

        dmi_start(7'h10, 32'h4000_0001, 2'd2);   // resumereq | dmactive, haltreq = 0
        dmi_finish(2_000, ok, rd);
        chk("DMI resumereq", ok);

        // ---- Pha 3: SW_RESET -> boot 2 tu RESET_VECTOR giu lai -----------------
        waited = 0;
        while (reg_t2 !== 32'd3 && waited < 40_000) begin #50; waited = waited + 50; end
        chk("pha 3: boot 2 chay tu RESET_VECTOR = 0x0001_0080 (song qua warm reset)", reg_t2 === 32'd3);
        chk("SW_RESET tao dung mot warm reset", warm_resets == 1);
        chk32("RST_CAUSE sau SW_RESET", reg_a4, 32'h8);
        chk32("RESET_VECTOR sau khi BOOT_LOCK chan lenh ghi", reg_a5, 32'h0001_0080);
        chk32("SEC_CTRL = BOOT_LOCK | DBG_LOCK", reg_a6, 32'h5);

        repeat (10) @(posedge clk);
        chk("pha 3: DBG_LOCK giu DM trong reset", !dbg_allow && (uut.reset_dbg_n === 1'b0));
        chk("pha 3: DBGCTRL bi xoa theo DM", uut.dbg_sleep === 1'b0);

        dmi_start(7'h10, 32'h8000_0001, 2'd2);
        dmi_finish(5_000, ok, rd);
        chk("pha 3: khi khoa, lenh DMI haltreq khong duoc tra loi", !ok);
        chk("pha 3: khi khoa, core khong halt", halted !== 1'b1);
        chk32("pha 3: t2 van = 3", reg_t2, 32'd3);
        dmi_valid_r = 1'b0;

        $display("");
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
