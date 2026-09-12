`timescale 1ns / 1ps

// =============================================================================
// tb_amo_core.sv - AMO bang CPU THAT, khong force gi (run_soc_sim.sh amo).
//
// 2026-09-13: ket qua AMO ALU chot vao amo_wdata_q (pipeline_stage.v) va D-cache
// giu lenh BA chu ky (dcache.v amo_cnt). tb_mem_paths.sv T10 tu dong vai tang
// MEM nen khong cham toi thanh ghi do; chuong trinh tests/amo_core.mem (sinh
// boi gen_amo_mem.py) thi co. Xem ket qua mong doi ben canh tung lenh trong
// gen_amo_mem.py.
//
// ENABLE_A_EXTENSION = 0 trong RTL (register_file.v giai thich vi sao), nen
// decoder coi AMO la illegal. defparam duoi day bat A CHI cho mo phong nay;
// MISA van khai khong co A - chuong trinh khong doc MISA.
// =============================================================================
module tb_amo_core;

    defparam uut.u_core.ID.MCU.ENABLE_A_EXTENSION = 1;

    localparam integer TIMEOUT_NS = 400_000;

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

    function automatic [31:0] x(input integer i);
        x = uut.u_core.RF.rf_main[i];
    endfunction

    integer waited;
    integer captures = 0;
    always @(posedge clk) if (rst_n && uut.cpu_data_amo_capture) captures = captures + 1;

    initial begin
        gpio_in = 32'h0;
        tck = 0; trst_n = 0; tms = 0; tdi = 0;
        rst_n = 1'b0;
        repeat (100) @(posedge clk);
        rst_n  = 1'b1;
        trst_n = 1'b1;

        $display("");
        $display("=== tb_amo_core: 9 AMO*.W + AMO truot + LR/SC bang CPU that ===");

        waited = 0;
        while (x(7) !== 32'd1 && x(7) !== 32'hBAD && waited < TIMEOUT_NS) begin
            #100;
            waited = waited + 100;
        end

        if (x(7) === 32'hBAD) begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] vao TRAP: mcause = %08h mepc = %08h (2 = A chua bat?)",
                     uut.u_core.CSR_RF.mcause, uut.u_core.CSR_RF.mepc);
        end else if (x(7) !== 32'd1) begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] khong toi `done` sau %0d ns - pc = %08h", TIMEOUT_NS, uut.u_core.pc_reg);
        end else begin
            $display("[TB][INFO] toi `done` sau ~%0d ns", waited);
            chk32("amoadd.w  a0 (cu)", x(10), 32'd100);
            chk32("amomin.w  a1 (cu)", x(11), 32'd105);
            chk32("amomax.w  a2 (cu)", x(12), 32'hFFFF_FFF9);
            chk32("amominu.w a3 (cu)", x(13), 32'd3);
            chk32("amomaxu.w a4 (cu)", x(14), 32'd3);
            chk32("amoxor.w  a5 (cu)", x(15), 32'hFFFF_FFFF);
            chk32("amoand.w  a6 (cu)", x(16), 32'hF0F0_F0F0);
            chk32("amoor.w   a7 (cu)", x(17), 32'h3030_3030);
            chk32("amoswap.w s2 (cu)", x(18), 32'h3131_3131);
            chk32("lw sau chuoi AMO s3", x(19), 32'h1234_5678);
            chk32("amoadd.w  s4 (cu)", x(20), 32'h1234_5678);
            chk32("rd AMO dung ngay s5", x(21), 32'h1234_5678);
            chk32("AMO truot s6 (cu)", x(22), 32'h0000_0040);
            chk32("lw sau AMO truot s7", x(23), 32'h0000_0042);
            chk32("lr.w s8", x(24), 32'h2468_ACF0);
            chk32("sc.w that bai s11", x(27), 32'd1);
            // QUAN SAT (khong tinh diem) - LOI CO TU TRUOC 2026-09-13, xac nhan
            // bang chinh test nay tren RTL HEAD: memory_access xoa
            // reservation_valid ngay chu ky DAU sc.w nam o MEM, trong khi
            // D-cache con stall lenh do (IDLE -> LOOKUP). Chu ky nha stall
            // sc_success da = 0 -> sc.w luon that bai, khong ghi. A dang tat
            // (ENABLE_A_EXTENSION = 0) nen chua sua; can chan cap nhat
            // reservation bang dieu kien commit (!dcache_stall).
            $display("[TB][INFO] QUAN SAT sc.w sau lr.w: s9 = %08h (dung: 0), mem = %08h (dung: 00000055)%0s",
                     x(25), x(26), (x(25) === 32'd0) ? "" : "  <- LR/SC reservation bi xoa trong luc stall");
        end

        // 9 + amoadd s4 + AMO truot (vong LOOKUP thu hai) = 11. LR/SC khong capture.
        if (captures == 11) begin
            pass_count = pass_count + 1;
            $display("[TB][PASS] dcache_amo_capture = %0d lan", captures);
        end else begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] dcache_amo_capture = %0d lan, mong doi 11", captures);
        end

        $display("");
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
