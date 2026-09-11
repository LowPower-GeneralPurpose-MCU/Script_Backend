`timescale 1ns / 1ps

// =============================================================================
// tb_core_jalr.sv - R13 va R14 chay bang CPU THAT, khong force gi.
//
// run_soc_sim.sh core bake tests/core_jalr.mem vao boot ROM (cung co che voi
// suite fw) roi cho CPU chay tu reset.  Chuong trinh (liet ke day du trong file
// .mem) lam hai viec:
//
//   R13  goi `getter` HAI lan.  getter = `lw a0, 0(s0); ret; addi a0, a0, 1`.
//        Lan 1 lw truot D-cache va nap line; lan 2 lw HIT -> dcache_stall dung 1
//        chu ky trong luc `ret` o IF/ID -> I-cache tra lenh K = `addi a0, a0, 1`
//        ngay chu ky nha stall -> ret va K lien nhau.  Day la mau tat dinh da
//        phan tich trong CORE_FIX_PLAN.md §10.  K la duong sai: neu no chay thi
//        a2 = 0x1234_5001 thay vi 0x1234_5000.
//
//   R14  `jalr ra, 0(t0)` goi gian tiep func2 (chi co `ret`).  ra phai la dia
//        chi lenh ke sau jalr (0x0001_0024).  RTL cu ghi ra = dich nhay, func2
//        `ret` ve chinh no va chuong trinh khong bao gio toi `done`.
//
// Ngoai ket qua kien truc, testbench doc bo dem cua monitor R13 trong
// riscv_pipeline.v: no phai >= 1, tuc la mau nguy hiem THUC SU da xay ra trong
// lan chay nay - neu khong thi a2 dung chi vi test khong cham toi truong hop do.
// =============================================================================
module tb_core_jalr;

    localparam [31:0] EXP_A2 = 32'h1234_5000;
    localparam [31:0] EXP_A1 = 32'h0001_0024;
    localparam integer TIMEOUT_NS = 200_000;

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

    // ---- clock / reset (giong tb_mem_paths.sv) -----------------------------
    reg clk, rtc_clk;   // SoC mot clock tu 2026-09-11: clk 250 MHz
    reg rst_n;

    initial begin clk      = 0; forever #2.0   clk      = ~clk;      end // 250 MHz
    initial begin rtc_clk  = 0; forever #15258 rtc_clk  = ~rtc_clk;  end

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
    assign uart_rx     = uart_tx;
    assign spi_miso    = spi_mosi;
    pullup(i2c_scl);
    pullup(i2c_sda);

    top_soc uut (
        .clk           (clk),
        .rtc_clk       (rtc_clk),
        .rst_n         (rst_n),
        .tck(tck), .trst_n(trst_n), .tms(tms), .tdi(tdi), .tdo(tdo),
        .uart_rx(uart_rx), .uart_tx(uart_tx),
        .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_oe(gpio_oe),
        .pwm_out(pwm_out),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso), .spi_ss(spi_ss),
        .i2c_scl_i(i2c_scl), .i2c_scl_o(dut_i2c_scl_o), .i2c_scl_oe(dut_i2c_scl_oe),
        .i2c_sda_i(i2c_sda), .i2c_sda_o(dut_i2c_sda_o), .i2c_sda_oe(dut_i2c_sda_oe),
        .flash_sck(flash_sck), .flash_cs_n(flash_cs_n),
        .flash_io_i(flash_io), .flash_io_o(dut_flash_io_o), .flash_io_oe(dut_flash_io_oe),
        .sdram_clk(sdram_clk), .sdram_cke(sdram_cke), .sdram_cs_n(sdram_cs_n),
        .sdram_ras_n(sdram_ras_n), .sdram_cas_n(sdram_cas_n), .sdram_we_n(sdram_we_n),
        .sdram_ba(sdram_ba), .sdram_addr(sdram_addr),
        .sdram_dq_i(sdram_dq), .sdram_dq_o(dut_sdram_dq_o), .sdram_dq_oe(dut_sdram_dq_oe),
        .sdram_dqm(sdram_dqm)
    );

    // x7 = t2 (co "xong"), x11 = a1 (link cua jalr), x12 = a2 (gia tri getter).
    wire [31:0] reg_t2 = uut.u_core.RF.rf_main[7];
    wire [31:0] reg_a1 = uut.u_core.RF.rf_main[11];
    wire [31:0] reg_a2 = uut.u_core.RF.rf_main[12];

    integer waited;

    initial begin
        gpio_in = 32'h0;
        tck = 0; trst_n = 0; tms = 0; tdi = 0;
        rst_n = 1'b0;
        repeat (100) @(posedge clk);   // = 400 ns, nhu 40 chu ky clk_100m cu
        rst_n  = 1'b1;
        trst_n = 1'b1;

        $display("");
        $display("=== tb_core_jalr: R13 (duong sai sau JALR) + R14 (link cua JALR) ===");

        waited = 0;
        while (reg_t2 !== 32'd1 && waited < TIMEOUT_NS) begin
            #100;
            waited = waited + 100;
        end

        if (reg_t2 !== 32'd1) begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] khong toi `done` sau %0d ns - pc = %08h (0001004x: ket o func2 => R14)",
                     TIMEOUT_NS, uut.u_core.pc_reg);
        end else begin
            $display("[TB][INFO] toi `done` sau ~%0d ns", waited);
            chk32("R13 a2 = ket qua getter lan 2 (K khong duoc chay)", reg_a2, EXP_A2);
            chk32("R14 a1 = ra sau jalr ra, 0(t0)", reg_a1, EXP_A1);
        end

        // Mau R13 phai da xay ra it nhat mot lan, neu khong a2 dung la vo nghia.
        if (uut.u_core.r13_wrong_path_cnt >= 1) begin
            pass_count = pass_count + 1;
            $display("[TB][PASS] monitor R13 thay %0d lenh duong sai o ID/EX luc JALR doi huong",
                     uut.u_core.r13_wrong_path_cnt);
        end else begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] monitor R13 dem 0 - test khong tao duoc mau ret/K lien nhau");
        end

        $display("");
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
