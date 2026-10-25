`timescale 1ns / 1ps
// =============================================================================
// tb_netsim - testbench netsim (mo phong netlist) cho top_soc.
//
// CHI dung cong cua top_soc nen chay y het tren RTL (make rtl) va tren netlist
// Genus / Innovus (make syn / func / sdf_max / sdf_min).  Driver/tb_top_soc.v khong
// dung lai duoc: no ket luan PASS bang tin hieu ben trong (uut.apb_*,
// uut.wfi_sleep_state, uut.u_core.*) - netlist khong con ten do - va dua vao
// firmware bake vao ROM, trong khi ROM cua netlist la boot ROM tang 1.
//
// Kich ban: boot ROM doc header flash -> nhay vao chuong trinh cua
// scripts/gen_flash_image.py, chay XIP trong flash qua I-cache -> chuong trinh
// chep EXPECT qua RAM hi (macro SRAM) roi gui ra UART0 = PA0.  tb giai ma UART
// tren pad_out[0].  Anh tb/netsim_flash_itcm.hex chay cung chuong trinh trong
// ITCM: hien FAIL vi erratum E1 (MEMORY_ARCHITECTURE.md muc 3).
//     [NETSIM][RESULT] PASS            nhan du EXPECT dung thu tu
//     [NETSIM][RESULT] FAIL: <ly do>   sai byte, X tren chan, het gio
// scripts/summarize.tcl doc dong RESULT.
//
// Plusarg:  +FLASH_IMAGE=<file>  anh flash (spi_flash_model)
//           +TIMEOUT_US=<n>      gioi han thoi gian mo phong (mac dinh 400)
// =============================================================================
module tb_netsim;
    localparam real    CLK_PERIOD_NS = 4.0;   // clk 250 MHz (constraint.sdc)
    localparam integer UART_DIV      = 8;     // TX_DIV chuong trinh flash ghi vao UART0
    localparam real    UART_BIT_NS   = UART_DIV * CLK_PERIOD_NS;
    localparam string  EXPECT        = "NETSIM OK\n";   // = MSG trong gen_flash_image.py

    reg clk     = 1'b0;
    reg rtc_clk = 1'b0;
    reg rst_n   = 1'b0;
    // TAP (rv_jtag_dtm) chi reset bang trst_n: giu thap cung rst_n, neu khong
    // netlist mang X tu TAP sang debug module.
    reg tck = 1'b0, trst_n = 1'b0, tms = 1'b0, tdi = 1'b0;
    wire tdo;

    reg  [31:0] pad_in = 32'h0000_0002;   // PA1 = UART0_RX nghi o muc 1
    wire [31:0] pad_out, pad_oe;

    wire       flash_sck, flash_cs_n;
    wire [3:0] flash_io_o, flash_io_oe;
    tri1 [3:0] flash_io;                  // dien tro keo len tren board
    wire       flash_miso;

    wire        sdram_clk, sdram_cke, sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n;
    wire [1:0]  sdram_ba, sdram_dqm;
    wire [12:0] sdram_addr;
    wire [15:0] sdram_dq_o;
    wire        sdram_dq_oe;

    always #(CLK_PERIOD_NS / 2.0) clk = ~clk;
    always #15258 rtc_clk = ~rtc_clk;     // ~32.768 kHz

    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : g_flash_pad
            assign flash_io[g] = flash_io_oe[g] ? flash_io_o[g] : 1'bz;
        end
    endgenerate
    assign flash_io[1] = flash_miso;      // MISO: model flash, Z khi khong lai

    top_soc uut (
        .clk        (clk),
        .rtc_clk    (rtc_clk),
        .rst_n      (rst_n),
        .tck        (tck),
        .trst_n     (trst_n),
        .tms        (tms),
        .tdi        (tdi),
        .tdo        (tdo),
        .pad_in     (pad_in),
        .pad_out    (pad_out),
        .pad_oe     (pad_oe),
        .flash_sck  (flash_sck),
        .flash_cs_n (flash_cs_n),
        .flash_io_i (flash_io),
        .flash_io_o (flash_io_o),
        .flash_io_oe(flash_io_oe),
        .sdram_clk  (sdram_clk),
        .sdram_cke  (sdram_cke),
        .sdram_cs_n (sdram_cs_n),
        .sdram_ras_n(sdram_ras_n),
        .sdram_cas_n(sdram_cas_n),
        .sdram_we_n (sdram_we_n),
        .sdram_ba   (sdram_ba),
        .sdram_addr (sdram_addr),
        .sdram_dq_i (16'h0000),           // khong co chip SDRAM
        .sdram_dq_o (sdram_dq_o),
        .sdram_dq_oe(sdram_dq_oe),
        .sdram_dqm  (sdram_dqm)
    );

    spi_flash_model u_flash (
        .sck (flash_sck),
        .cs_n(flash_cs_n),
        .mosi(flash_io[0]),
        .miso(flash_miso)
    );

`ifdef NS_WAVES
    // Chi cong cua uut + tin hieu tb: probe ca netlist cho vai chuc us la hang GB.
    initial begin
        $shm_open("waves.shm");
        $shm_probe(tb_netsim, "A");
    end
`endif

    integer n_rx = 0;

    task automatic finish_fail(input string why);
        $display("[NETSIM][RESULT] FAIL: %s (t=%0t, UART %0d/%0d byte, flash doc %0d lan)",
                 why, $time, n_rx, EXPECT.len(), u_flash.nreads);
        $finish;
    endtask

    // Reset: nha o canh xuong clk (t = 100 ns), xa canh len cua flop.
    initial begin
        #100;
        rst_n  = 1'b1;
        trst_n = 1'b1;
        $display("[NETSIM] t=%0t nha rst_n / trst_n", $time);
    end

    // Chan ra phai xac dinh som sau reset; X o day thuong la flop khong reset
    // hoac ICG ma enable con X - xem song quanh uut truoc khi xem UART.
    initial begin
        wait (rst_n === 1'b1);
        #2000;
        if ((^{pad_out[0], pad_oe[0], flash_cs_n, flash_sck}) === 1'bx)
            finish_fail($sformatf("X tren chan 2 us sau reset: pad_out[0]=%b pad_oe[0]=%b flash_cs_n=%b flash_sck=%b",
                                  pad_out[0], pad_oe[0], flash_cs_n, flash_sck));
    end

    // Giai ma UART0 tren PA0: 8N1, LSB truoc, UART_BIT_NS moi bit, lay mau giua bit.
    initial begin : uart_rx
        reg [7:0] rx_byte;
        integer   b;
        wait (rst_n === 1'b1);
        wait (pad_out[0] === 1'b1);
        forever begin
            @(negedge pad_out[0]);
            if (pad_out[0] !== 1'b0)
                finish_fail($sformatf("PA0 (UART0_TX) = %b", pad_out[0]));
            if (pad_oe[0] !== 1'b1)
                finish_fail($sformatf("pad_oe[0] = %b khi UART phat (pinmux PA0?)", pad_oe[0]));
            #(UART_BIT_NS / 2.0);
            if (pad_out[0] !== 1'b0)
                finish_fail("start bit ngan hon nua bit - sai UART_DIV?");
            for (b = 0; b < 8; b = b + 1) begin
                #(UART_BIT_NS);
                if (pad_out[0] !== 1'b0 && pad_out[0] !== 1'b1)
                    finish_fail($sformatf("bit %0d cua byte %0d = %b", b, n_rx, pad_out[0]));
                rx_byte[b] = pad_out[0];
            end
            #(UART_BIT_NS);
            if (pad_out[0] !== 1'b1)
                finish_fail($sformatf("stop bit = %b sau byte 0x%02h", pad_out[0], rx_byte));
            $display("[NETSIM][UART] t=%0t byte %0d = 0x%02h", $time, n_rx, rx_byte);
            if (n_rx >= EXPECT.len())
                finish_fail($sformatf("byte thua 0x%02h", rx_byte));
            if (rx_byte !== EXPECT[n_rx])
                finish_fail($sformatf("byte %0d = 0x%02h, mong doi 0x%02h", n_rx, rx_byte, EXPECT[n_rx]));
            n_rx = n_rx + 1;
            if (n_rx == EXPECT.len()) begin
                $display("[NETSIM][RESULT] PASS t=%0t UART \"NETSIM OK\" qua boot ROM -> flash -> SRAM, flash doc %0d lan",
                         $time, u_flash.nreads);
                $finish;
            end
        end
    end

    initial begin : watchdog
        integer timeout_us;
        if (!$value$plusargs("TIMEOUT_US=%d", timeout_us)) timeout_us = 400;
        $display("[NETSIM] timeout %0d us", timeout_us);
        #(timeout_us * 1000.0);
        finish_fail($sformatf("het %0d us", timeout_us));
    end
endmodule
