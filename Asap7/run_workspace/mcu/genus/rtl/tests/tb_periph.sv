`timescale 1ns / 1ps

// =============================================================================
// tb_periph.sv - muc 8 cua review 2026-09-11 (pinmux, UART1, TIM0/TIM1) va phan
// noi day cua CLIC (ID theo nguon, DMA tach kenh), qua pad THAT cua top_soc.
//
// Giong SoC_testbench.sv: testbench FORCE phia master cua APB (dut.apb_*), nen
// CPU va boot ROM khong lien quan. Nhip APB bam DUNG axi_to_apb_bridge: lay mau
// pready truoc canh, tha psel/penable o canh ma bridge cung tha. Pad duoc mo
// hinh nhu pad ring: pad dang oe = 1 doc lai chinh no, pad khong lai doc gia tri
// testbench dat.
//
//   T1  PINMUX: gia tri reset (PA0/PA1 = UART0), offset la -> PSLVERR
//   T2  UART1 qua PA2 (TX) -> vong ngoai -> PA3 (RX), ngat UART1 = CLIC ID 17
//   T3  TIM0 kenh 0 PWM1 ra PA16 (AF2): dung 30% trong 10 chu ky PWM
//   T4  TIM1 kenh 0 capture tu PA20 (AF2): CCR0 chot CNT, CC0IF, CC0OF, ID 29
//   T5  DMA: 4 kenh la 4 ID CLIC rieng (22..25) - truoc day OR chung
//   T6  CLIC qua APB: cliccfg/clicinfo, ghi tung byte (pstrb), vung reserved
//   T7  dau vao khong pad nao chon -> gia tri nghi; SPI ra dung pad AF1
// =============================================================================
module tb_periph;

    integer pass_count = 0;
    integer fail_count = 0;

    task automatic chk32(input [511:0] name, input [31:0] got, input [31:0] exp);
        begin
            if (got === exp) begin
                pass_count = pass_count + 1;
                $display("[TB][PASS] %0s = %08h", name, got);
            end else begin
                fail_count = fail_count + 1;
                $display("[TB][FAIL] %0s = %08h  (mong doi %08h)  t=%0t", name, got, exp, $time);
            end
        end
    endtask

    task automatic chk(input [511:0] name, input ok);
        begin
            if (ok) begin
                pass_count = pass_count + 1;
                $display("[TB][PASS] %0s", name);
            end else begin
                fail_count = fail_count + 1;
                $display("[TB][FAIL] %0s  t=%0t", name, $time);
            end
        end
    endtask

    // ---- clock / reset -------------------------------------------------------
    reg clk, rtc_clk, rst_n;
    initial begin clk     = 0; forever #2.0   clk     = ~clk;     end
    initial begin rtc_clk = 0; forever #15258 rtc_clk = ~rtc_clk; end

    // ---- pad -----------------------------------------------------------------
    reg  [31:0] tb_drive;                 // muc testbench dat len pad khong lai
    wire [31:0] pad_out, pad_oe;
    // Vong ngoai UART1: PA2 (TX) noi day sang PA3 (RX).
    wire [31:0] ext    = {tb_drive[31:4], pad_out[2], tb_drive[2:0]};
    wire [31:0] pad_in = (pad_oe & pad_out) | (~pad_oe & ext);

    reg  tck, trst_n, tms, tdi;
    wire tdo;
    wire flash_sck, flash_cs_n;
    wire [3:0]  flash_io, dut_flash_io_o, dut_flash_io_oe;
    wire sdram_clk, sdram_cke, sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n;
    wire [1:0]  sdram_ba, sdram_dqm;
    wire [12:0] sdram_addr;
    wire [15:0] sdram_dq, dut_sdram_dq_o;
    wire        dut_sdram_dq_oe;
    assign flash_io = 4'hF;
    assign sdram_dq = 16'h0000;

    top_soc dut (
        .clk(clk), .rtc_clk(rtc_clk), .rst_n(rst_n),
        .tck(tck), .trst_n(trst_n), .tms(tms), .tdi(tdi), .tdo(tdo),
        .pad_in(pad_in), .pad_out(pad_out), .pad_oe(pad_oe),
        .flash_sck(flash_sck), .flash_cs_n(flash_cs_n),
        .flash_io_i(flash_io), .flash_io_o(dut_flash_io_o), .flash_io_oe(dut_flash_io_oe),
        .sdram_clk(sdram_clk), .sdram_cke(sdram_cke), .sdram_cs_n(sdram_cs_n),
        .sdram_ras_n(sdram_ras_n), .sdram_cas_n(sdram_cas_n), .sdram_we_n(sdram_we_n),
        .sdram_ba(sdram_ba), .sdram_addr(sdram_addr),
        .sdram_dq_i(sdram_dq), .sdram_dq_o(dut_sdram_dq_o), .sdram_dq_oe(dut_sdram_dq_oe),
        .sdram_dqm(sdram_dqm)
    );

    // ---- APB master (force phia master cua apb_interconnect) -----------------
    reg [31:0] apb_addr, apb_wdata;
    reg [3:0]  apb_pstrb;
    reg        apb_psel, apb_penable, apb_pwrite;
    initial begin
        apb_addr = 0; apb_wdata = 0; apb_pstrb = 0;
        apb_psel = 0; apb_penable = 0; apb_pwrite = 0;
        force dut.apb_paddr   = apb_addr;
        force dut.apb_pwdata  = apb_wdata;
        force dut.apb_pstrb   = apb_pstrb;
        force dut.apb_pprot   = 3'b000;
        force dut.apb_psel    = apb_psel;
        force dut.apb_penable = apb_penable;
        force dut.apb_pwrite  = apb_pwrite;
    end

    reg [31:0] rd;
    reg        err;
    // Nhip nhu axi_to_apb_bridge: SETUP 1 canh, ACCESS cho toi canh ma pready
    // (lay mau NGAY TRUOC canh) = 1, tha psel/penable o chinh canh do.
    task automatic apb_xfer(input [31:0] a, input wr, input [31:0] d, input [3:0] strb);
        integer n;
        begin
            @(posedge clk);
            apb_addr <= a; apb_wdata <= d; apb_pwrite <= wr;
            apb_pstrb <= wr ? strb : 4'h0;
            apb_psel <= 1'b1; apb_penable <= 1'b0;
            @(posedge clk);
            apb_penable <= 1'b1;
            n = 0;
            do begin
                @(negedge clk);
                n = n + 1;
            end while (dut.apb_pready !== 1'b1 && n < 200);
            rd  = dut.apb_prdata;
            err = dut.apb_pslverr;
            @(posedge clk);
            apb_psel <= 1'b0; apb_penable <= 1'b0; apb_pwrite <= 1'b0;
        end
    endtask
    task automatic wr32(input [31:0] a, input [31:0] d);
        apb_xfer(a, 1'b1, d, 4'hF);
    endtask
    task automatic rd32(input [31:0] a);
        apb_xfer(a, 1'b0, 32'd0, 4'h0);
    endtask

    // So xung day FIFO TX va so byte FIFO RX cua UART1 - phan biet "ghi TX hai
    // lan" voi "nhan them mot byte rac" neu T2 thay hai byte.
    integer u1_txpush = 0, u1_rxpush = 0;
    always @(posedge clk) begin
        if (dut.u_apb_uart1.tx_fifo_wr) u1_txpush = u1_txpush + 1;
        if (dut.u_apb_uart1.rx_fifo_wr) u1_rxpush = u1_rxpush + 1;
    end

    localparam [31:0] SYSCON_CG = 32'h4000_7004;
    localparam [31:0] PINMUX    = 32'h4002_0000;
    localparam [31:0] UART1     = 32'h4000_D000;
    localparam [31:0] TIM0      = 32'h4000_E000;
    localparam [31:0] TIM1      = 32'h4000_F000;
    localparam [31:0] CLIC      = 32'h4400_0000;
    localparam [31:0] CLICINT   = 32'h4400_1000;

    integer i, hi_cnt, n;
    reg [31:0] cnt_at_edge;

    initial begin
        tb_drive = 32'h0000_0002;         // PA1 (UART0_RX) nghi muc 1
        tck = 0; trst_n = 0; tms = 0; tdi = 0;
        rst_n = 1'b0;
        repeat (50) @(posedge clk);
        rst_n = 1'b1; trst_n = 1'b1;
        repeat (100) @(posedge clk);      // bo keo dai reset 64 chu ky

        $display("");
        $display("=== tb_periph: pinmux / UART1 / TIM0-1 / CLIC ===");

        // ----------------------------------------------------------- T1
        $display("[TB] --- T1 PINMUX ---");
        rd32(PINMUX + 32'h0);  chk32("AFSEL0 reset (PA0/PA1 = UART0)", rd, 32'h0000_0005);
        rd32(PINMUX + 32'h4);  chk32("AFSEL1 reset", rd, 32'h0000_0000);
        chk("PA0 lai ra (UART0_TX), PA1 la dau vao", pad_oe[0] === 1'b1 && pad_oe[1] === 1'b0);
        wr32(PINMUX + 32'h8, 32'hFFFF_FFFF);  chk("offset la -> PSLVERR", err === 1'b1);

        // ----------------------------------------------------------- T7 (nghi)
        $display("[TB] --- T7 gia tri nghi ---");
        chk("UART1_RX khong pad nao chon -> 1", dut.uart1_rx === 1'b1);
        chk("I2C SCL/SDA khong pad nao chon -> 1", dut.i2c_scl_i === 1'b1 && dut.i2c_sda_i === 1'b1);
        chk("SPI MISO khong pad nao chon -> 0", dut.spi_miso === 1'b0);

        // ----------------------------------------------------------- T2
        $display("[TB] --- T2 UART1 qua PA2 -> PA3 ---");
        wr32(SYSCON_CG, 32'h0000_0703);            // UART0, PWM + UART1, TIM0, TIM1
        rd32(SYSCON_CG);  chk32("CLK_GATE_CTRL[10:8] = UART1/TIM0/TIM1", rd & 32'h700, 32'h700);
        wr32(PINMUX + 32'h0, 32'h0000_0055);       // PA2 = U1TX, PA3 = U1RX (AF1)
        chk("PA2 lai ra, PA3 la dau vao", pad_oe[2] === 1'b1 && pad_oe[3] === 1'b0);
        wr32(UART1 + 32'h00, 32'h0002_0020);       // RX_DIV 2, TX_DIV 32
        wr32(UART1 + 32'h10, 32'h0000_0002);       // RX_INT_EN
        wr32(CLICINT + 17*4, 32'h2000_0100);       // ID 17: muc 1, muc cao, ie
        wr32(UART1 + 32'h04, 32'h0000_00A5);
        n = 0;
        do begin rd32(UART1 + 32'h0C); n = n + 1; end while (rd[3] && n < 400);
        chk("UART1 nhan duoc byte qua pad (RX_EMPTY = 0)", rd[3] === 1'b0);
        repeat (4) @(posedge clk);
        chk("ngat UART1 la CLIC ID 17", dut.clic_irq_valid === 1'b1 && dut.clic_irq_id === 5'd17);
        rd32(UART1 + 32'h08);  chk32("UART1 RX_DATA", rd & 32'hFF, 32'h0000_00A5);
        repeat (800) @(posedge clk);               // du cho mot byte thu hai neu co
        $display("[TB][INFO] UART1: %0d xung day TX FIFO, %0d byte vao RX FIFO", u1_txpush, u1_rxpush);
        rd32(UART1 + 32'h0C);  chk("dung MOT byte (khong ghi TX hai lan)", rd[3] === 1'b1);
        chk("UART0 khong bi dong (PA0 van la UART0_TX nghi)", pad_out[0] === 1'b1);
        wr32(CLICINT + 17*4, 32'h0000_0000);

        // ----------------------------------------------------------- T3
        $display("[TB] --- T3 TIM0 PWM ra PA16 ---");
        wr32(PINMUX + 32'h4, 32'h0000_0002);       // PA16 = AF2 = TIM0_CH0
        wr32(TIM0 + 32'h04, 32'd0);                // PSC
        wr32(TIM0 + 32'h08, 32'd9);                // ARR -> chu ky 10
        wr32(TIM0 + 32'h24, 32'd3);                // CCR0
        wr32(TIM0 + 32'h1C, 32'h0000_0006);        // ch0 PWM1
        wr32(TIM0 + 32'h20, 32'h0000_0001);        // CC0E
        wr32(TIM0 + 32'h00, 32'h0000_0001);        // CEN
        chk("PA16 lai ra (TIM0_CH0)", pad_oe[16] === 1'b1);
        repeat (30) @(posedge clk);
        hi_cnt = 0;
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
            if (pad_out[16] === 1'b1) hi_cnt = hi_cnt + 1;
        end
        chk32("PWM1 CCR=3 ARR=9: 30 / 100 chu ky muc cao", hi_cnt, 32'd30);
        rd32(TIM0 + 32'h10);  chk("TIM0 SR.UIF va CC0IF da dat", rd[0] === 1'b1 && rd[1] === 1'b1);
        wr32(TIM0 + 32'h00, 32'h0000_0000);        // dung truoc, roi moi xoa
        wr32(TIM0 + 32'h10, 32'h0000_01FF);        // W1C
        rd32(TIM0 + 32'h10);  chk32("TIM0 SR sau W1C", rd, 32'd0);

        // ----------------------------------------------------------- T4
        $display("[TB] --- T4 TIM1 capture tu PA20 ---");
        wr32(PINMUX + 32'h4, 32'h0000_0202);       // + PA20 = AF2 = TIM1_CH0
        chk("PA20 la dau vao (kenh capture khong lai chan)", pad_oe[20] === 1'b0);
        wr32(TIM1 + 32'h08, 32'hFFFF_FFFF);
        wr32(TIM1 + 32'h1C, 32'h0000_0008);        // ch0 capture, canh len, khong loc
        wr32(TIM1 + 32'h20, 32'h0000_0001);        // CC0E
        wr32(TIM1 + 32'h14, 32'h0000_0002);        // CC0IE
        wr32(CLICINT + 29*4, 32'h2000_0100);       // ID 29
        wr32(TIM1 + 32'h00, 32'h0000_0001);        // CEN
        repeat (40) @(posedge clk);
        @(negedge clk);
        cnt_at_edge = dut.u_tim1.cnt;
        tb_drive[20] = 1'b1;
        repeat (10) @(posedge clk);
        rd32(TIM1 + 32'h24);
        chk("CCR0 chot CNT tai canh (tre 2FF + loc + bat canh <= 6 chu ky)",
            rd >= cnt_at_edge + 1 && rd <= cnt_at_edge + 6);
        $display("[TB][INFO] CNT luc canh = %0d, CCR0 = %0d", cnt_at_edge, rd);
        // Chi xet bit cua KENH 0 (CC0IF = bit 1, CC0OF = bit 5). Kenh 1-3 de
        // mac dinh o che do compare voi CCR = 0 nen CCxIF cua chung len khi CNT
        // = 0 - dung nhu STM32 (co compare dat khi khop ke ca khi CCxE = 0).
        rd32(TIM1 + 32'h10);  chk32("TIM1 SR: CC0IF", rd & 32'h22, 32'h0000_0002);
        chk("ngat TIM1 la CLIC ID 29", dut.clic_irq_valid === 1'b1 && dut.clic_irq_id === 5'd29);
        tb_drive[20] = 1'b0; repeat (10) @(posedge clk);
        tb_drive[20] = 1'b1; repeat (10) @(posedge clk);
        rd32(TIM1 + 32'h10);  chk32("TIM1 SR: canh thu hai khi CC0IF chua xoa -> CC0OF", rd & 32'h22, 32'h0000_0022);
        wr32(TIM1 + 32'h10, 32'h0000_0022);
        rd32(TIM1 + 32'h10);  chk32("TIM1 SR sau W1C (kenh 0)", rd & 32'h22, 32'd0);
        wr32(TIM1 + 32'h00, 32'h0);
        wr32(CLICINT + 29*4, 32'h0);

        // ----------------------------------------------------------- T5
        $display("[TB] --- T5 DMA: moi kenh mot ID CLIC ---");
        for (i = 22; i <= 25; i = i + 1)
            wr32(CLICINT + i*4, 32'h2000_0100);
        for (i = 0; i < 4; i = i + 1) begin
            force dut.dma_irq = (4'b0001 << i);
            repeat (4) @(posedge clk);
            chk32("DMA kenh -> ID CLIC", {27'd0, dut.clic_irq_id}, 32'd22 + i);
        end
        force dut.dma_irq = 4'b1111;
        repeat (4) @(posedge clk);
        chk32("ca 4 kenh cung muc: ID lon nhat thang (25)", {27'd0, dut.clic_irq_id}, 32'd25);
        wr32(CLICINT + 23*4, 32'hE000_0100);       // kenh 1 len muc 7
        repeat (4) @(posedge clk);
        chk32("kenh 1 muc 7 thang kenh 3 muc 1", {27'd0, dut.clic_irq_id}, 32'd23);
        chk32("muc gui toi core = 0xFF", {24'd0, dut.clic_irq_level}, 32'h0000_00FF);
        release dut.dma_irq;
        for (i = 22; i <= 25; i = i + 1)
            wr32(CLICINT + i*4, 32'h0);

        // ----------------------------------------------------------- T6
        $display("[TB] --- T6 CLIC qua APB ---");
        rd32(CLIC + 32'h0);  chk32("cliccfg (nlbits = 8)", rd, 32'h0000_0010);
        rd32(CLIC + 32'h4);  chk32("clicinfo (32 ngat, 3 bit ctl)", rd, 32'h0060_2020);
        apb_xfer(CLICINT + 20*4, 1'b1, 32'hA000_0000, 4'b1000);   // chi byte ctl
        apb_xfer(CLICINT + 20*4, 1'b1, 32'h0000_0100, 4'b0010);   // chi byte ie
        rd32(CLICINT + 20*4);
        chk32("ghi tung byte khong de len byte khac", rd, 32'hBFC0_0100);
        wr32(CLICINT + 20*4, 32'h0);
        rd32(32'h4420_0000);
        chk("vung reserved (threshold PLIC cu): doc 0, khong PSLVERR", rd === 32'd0 && err === 1'b0);
        wr32(32'h4400_2000, 32'hFFFF_FFFF);
        chk("ghi reserved (enable PLIC cu) khong PSLVERR", err === 1'b0);

        // ----------------------------------------------------------- T7 (SPI)
        $display("[TB] --- T7 SPI qua pad ---");
        wr32(PINMUX + 32'h0, 32'h0000_0500);       // PA4 = SCK, PA5 = MOSI (AF1)
        repeat (2) @(posedge clk);
        chk("PA4/PA5 lai ra (SPI SCK/MOSI)", pad_oe[4] === 1'b1 && pad_oe[5] === 1'b1);
        chk("PA4 = spi_sck, PA5 = spi_mosi", pad_out[4] === dut.spi_sck && pad_out[5] === dut.spi_mosi);
        chk("PA0/PA1 da ve GPIO vao (AFSEL0 moi)", pad_oe[0] === 1'b0);

        $display("");
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

    initial begin
        #2_000_000;
        $display("[TB][FAIL] timeout");
        $display("RESULT: FAIL");
        $finish;
    end

endmodule
