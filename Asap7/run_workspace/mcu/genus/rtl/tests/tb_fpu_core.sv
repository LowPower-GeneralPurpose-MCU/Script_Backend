`timescale 1ns / 1ps

// =============================================================================
// tb_fpu_core.sv - RV32F bang CPU THAT, khong force gi (run_soc_sim.sh fpu).
//
// Chuong trinh: tests/fpu_core.mem, sinh boi gen_fpu_mem.py (ket qua mong doi
// duoc ghi ben canh tung lenh o do).
//
// ENABLE_F = 0 trong RTL - xem ghi chu o parameter cua riscv_pipeline.v: ban
// chay Innovus sach 2026-09-18 dua tren netlist KHONG co FPU, nen cong tac chi
// duoc bat khi da san sang chay lai ca luong. defparam duoi day bat F CHI cho
// mo phong nay.
// =============================================================================
module tb_fpu_core;

    defparam uut.u_core.ENABLE_F = 1;

    localparam integer TIMEOUT_NS = 2_000_000;

    integer pass_count = 0;
    integer fail_count = 0;

    task automatic chk32(input [255:0] name, input [31:0] got, input [31:0] exp);
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

    // ---- clock / reset (giong tb_amo_core.sv) ------------------------------
    reg clk, rtc_clk;   // SoC mot clock tu 2026-09-11: clk 250 MHz
    reg rst_n;

    initial begin clk     = 0; forever #2.0   clk     = ~clk;     end // 250 MHz
    initial begin rtc_clk = 0; forever #15258 rtc_clk = ~rtc_clk; end

    // ---- chan ngoai vi -----------------------------------------------------
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
        .pad_in({gpio_in[31:2], uart_rx, gpio_in[0]}), .pad_out(gpio_out), .pad_oe(gpio_oe),
        .flash_sck(flash_sck), .flash_cs_n(flash_cs_n),
        .flash_io_i(flash_io), .flash_io_o(dut_flash_io_o), .flash_io_oe(dut_flash_io_oe),
        .sdram_clk(sdram_clk), .sdram_cke(sdram_cke), .sdram_cs_n(sdram_cs_n),
        .sdram_ras_n(sdram_ras_n), .sdram_cas_n(sdram_cas_n), .sdram_we_n(sdram_we_n),
        .sdram_ba(sdram_ba), .sdram_addr(sdram_addr),
        .sdram_dq_i(sdram_dq), .sdram_dq_o(dut_sdram_dq_o), .sdram_dq_oe(dut_sdram_dq_oe),
        .sdram_dqm(sdram_dqm)
    );

    // x2 nam trong mot flop rieng (x2_sp), nhung chuong trinh khong dung sp.
    function automatic [31:0] xr(input integer i);
        xr = uut.u_core.RF.rf_main[i];
    endfunction

    // Tep f chi ton tai khi ENABLE_F = 1 - do la generate block gen_fregfile.
    function automatic [31:0] fr(input integer i);
        fr = uut.u_core.gen_fregfile.FRF.f_regfile[i];
    endfunction

    integer waited;

    initial begin
        gpio_in = 32'h0;
        tck = 0; trst_n = 0; tms = 0; tdi = 0;
        rst_n = 1'b0;
        repeat (100) @(posedge clk);
        rst_n  = 1'b1;
        trst_n = 1'b1;

        $display("");
        $display("=== tb_fpu_core: toan bo RV32F bang CPU that ===");

        waited = 0;
        while (xr(7) !== 32'd1 && xr(7) !== 32'hBAD && waited < TIMEOUT_NS) begin
            #200;
            waited = waited + 200;
        end

        if (xr(7) === 32'hBAD) begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] vao TRAP: mcause = %08h mepc = %08h mtval = %08h",
                     uut.u_core.CSR_RF.mcause, uut.u_core.CSR_RF.mepc,
                     uut.u_core.CSR_RF.mtval);
            $display("[TB][INFO] mcause = 2 la illegal-instruction: mot ma lenh F chua");
            $display("[TB][INFO] duoc decoder ha illegal_instr, hoac mstatus.FS = Off.");
        end else if (xr(7) !== 32'd1) begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] khong toi `done` sau %0d ns - pc = %08h",
                     TIMEOUT_NS, uut.u_core.pc_reg);
        end else begin
            $display("[TB][INFO] toi `done` sau ~%0d ns", waited);

            $display("[TB] --- so hoc co ban ---");
            chk32("fadd.s  1.0 + 2.0      f8",  fr(8),  32'h40400000);  // 3.0
            chk32("fsub.s  3.0 - 1.0      f9",  fr(9),  32'h40000000);  // 2.0
            chk32("fmul.s  3.0 * 0.5      f10", fr(10), 32'h3FC00000);  // 1.5
            chk32("fdiv.s  1.0 / 3.0      f11", fr(11), 32'h3EAAAAAB);
            chk32("fsqrt.s sqrt(2.0)      f12", fr(12), 32'h3FB504F3);

            $display("[TB] --- FMA (lam tron mot lan) ---");
            chk32("fmadd.s   3*0.5+1.0    f13", fr(13), 32'h40200000);  //  2.5
            chk32("fmsub.s   3*0.5-1.0    f14", fr(14), 32'h3F000000);  //  0.5
            chk32("fnmsub.s -(3*0.5)+1.0  f15", fr(15), 32'hBF000000);  // -0.5
            chk32("fnmadd.s -(3*0.5)-1.0  f16", fr(16), 32'hC0200000);  // -2.5

            $display("[TB] --- dau / min / max ---");
            chk32("fsgnj.s  (1.0, -1.5)   f17", fr(17), 32'hBF800000);  // -1.0
            chk32("fsgnjn.s (1.0, -1.5)   f18", fr(18), 32'h3F800000);  //  1.0
            chk32("fsgnjx.s (-1.5,-1.5)   f19", fr(19), 32'h3FC00000);  //  1.5
            chk32("fmin.s (-1.5, 1.0)     f20", fr(20), 32'hBFC00000);
            chk32("fmax.s (-1.5, 1.0)     f21", fr(21), 32'h3F800000);
            // Ban FPU cu tra ve qNaN cho ca hai dong duoi - dac ta doi toan hang KIA.
            chk32("fmin.s (qNaN, 1.0)     f22", fr(22), 32'h3F800000);
            chk32("fmax.s (qNaN, -1.5)    f23", fr(23), 32'hBFC00000);

            $display("[TB] --- so sanh va phan loai ---");
            chk32("feq.s (1.0, 1.0)       a0", xr(10), 32'd1);
            // Ban cu so BIT THO nen -1.5 < 1.0 cho ra 0. Day la phep thu bat no.
            chk32("flt.s (-1.5, 1.0)      a1", xr(11), 32'd1);
            chk32("fle.s (1.0, 1.0)       a2", xr(12), 32'd1);
            chk32("feq.s (qNaN, 1.0)      a3", xr(13), 32'd0);
            chk32("fclass.s (-1.5)        a4", xr(14), 32'h0000_0002); // -normal
            chk32("fclass.s (+0.0)        a5", xr(15), 32'h0000_0010); // +0

            $display("[TB] --- chuyen doi ---");
            chk32("fcvt.w.s  -1.5 RTZ     a6", xr(16), 32'hFFFFFFFF);  // -1
            chk32("fcvt.w.s  -1.5 RNE     a7", xr(17), 32'hFFFFFFFE);  // -2
            chk32("fcvt.wu.s 10.0         s2", xr(18), 32'd10);
            chk32("fcvt.s.w  -5           f24", fr(24), 32'hC0A00000);
            chk32("fcvt.s.wu 0xFFFFFFFF   f25", fr(25), 32'h4F800000);
            chk32("fmv.x.w   1.0          s3", xr(19), 32'h3F800000);

            $display("[TB] --- flw / fsw (offset khac 0) ---");
            chk32("flw sau fsw            f26", fr(26), 32'h40400000);

            $display("[TB] --- subnormal (ban cu flush ve 0) ---");
            chk32("subnormal nap duoc     f27", fr(27), 32'h00000002);
            chk32("subnormal nap duoc     f28", fr(28), 32'h00000001);
            chk32("2^-149 + 2*2^-149      f29", fr(29), 32'h00000003);
            chk32("2^-126 * 0.5 = 2^-127  f31", fr(31), 32'h00400000);

            $display("[TB] --- co ngoai le (fflags) ---");
            chk32("1.0/0.0 -> fflags DZ   s4", xr(20), 32'h0000_0008);
            chk32("1.0/0.0 -> +inf        s5", xr(21), 32'h7F800000);
            chk32("0.0/0.0 -> fflags NV   s6", xr(22), 32'h0000_0010);
            chk32("0.0/0.0 -> qNaN        s7", xr(23), 32'h7FC00000);
            chk32("flt.s(qNaN,1.0) = 0    s8", xr(24), 32'd0);
            chk32("flt signal -> NV       s9", xr(25), 32'h0000_0010);
            chk32("feq.s(qNaN,1.0) = 0    s10", xr(26), 32'd0);
            chk32("feq quiet -> KHONG NV  s11", xr(27), 32'h0000_0000);
            chk32("max*2 -> fflags OF|NX  t3", xr(28), 32'h0000_0005);
            chk32("max*2 -> +inf          t4", xr(29), 32'h7F800000);

            $display("[TB] --- che do lam tron dong (frm = RTZ) ---");
            // RNE cho 0x3EAAAAAB; RTZ cat duoi nen phai NHO hon dung mot ulp.
            chk32("fdiv.s 1/3 rm=DYN(RTZ) t5", xr(30), 32'h3EAAAAAA);

            $display("[TB] --- trang thai kien truc ---");
            // misa phai KHAI bit F khi F that su chay. Ghi chu F1 trong
            // register_file.v: khai ma khong co la loi, co ma khong khai cung la loi.
            if (uut.u_core.CSR_RF.MISA[5]) begin
                pass_count = pass_count + 1;
                $display("[TB][PASS] misa[5] (F) = 1");
            end else begin
                fail_count = fail_count + 1;
                $display("[TB][FAIL] misa[5] (F) = 0 nhung lenh F van chay");
            end
            // mstatus.FS phai la Dirty (11) sau khi da ghi thanh ghi f.
            chk32("mstatus.FS = Dirty      ",
                  {30'd0, uut.u_core.CSR_RF.mstatus[14:13]}, 32'd3);
        end

        $display("");
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
