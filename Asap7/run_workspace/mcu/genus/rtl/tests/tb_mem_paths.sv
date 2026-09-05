`timescale 1ns / 1ps

// =============================================================================
// tb_mem_paths.sv - directed testbench cho cac duong bo nho MOI MO o Phase 0
// =============================================================================
//
// MEMORY_FIX_PLAN.md muc 5 ("No verification") ghi ro: hai testbench dang co
// (SoC_testbench.sv, tb_top_soc.v) chi chung minh KHONG GAY HOI QUY, chua he
// cham vao nua RAM `hi` (0x2002_0000), vao TCM, hay vao thu tu store MMIO.
// File nay tra mon no do.
//
// Cach lam: KHONG can firmware.  Testbench `force` thang cac chan core-side cua
// top_soc va dong vai CPU:
//
//     cpu_inst_req / cpu_inst_addr             <- port fetch
//     cpu_data_rd_req / cpu_data_wr_req / ...  <- port load-store
//
// Nho vay moi transaction la mot lenh RISC-V don le do testbench chon, chay
// dung qua decode `SOC_IS_UNCACHED` / `SOC_IS_ITCM` / `SOC_IS_DTCM` that, qua
// D-cache that, qua AXI interconnect that.  Khong mo hinh gia nao ca.
//
// `clk_en_cpu_s` bi force len 1 vi loi CPU that dang treo o fetch (ta cuop port
// cua no).  Neu no giai ma nham mot lenh rac thanh WFI thi clock CPU tat va
// testbench treo; force la cach re nhat de loai bo hoan toan kha nang do.
//
// Cac nhom test:
//   T1  RAM hi, truy cap word           - chung minh slave 6 + duong uncached
//   T2  RAM hi, truy cap byte/halfword  - sb/sh/lb/lh vao DMAPOOL
//   T3  DTCM                            - TCM chua tung duoc kich hoat lan nao
//   T4  ITCM: ghi bang port D roi fetch bang port F (rang buoc thu tu boot)
//   T5  ITCM: tranh chap F/D, luat f_starved
//   T6  DMA ghi DMAPOOL roi CPU doc lai - chung minh P0 that su dong
//   T7  Thu tu store vao MMIO           - bai test BAT BUOC truoc Phase 1
//
// Chay: genus/rtl/tests/run_soc_sim.sh mem
// =============================================================================

module tb_mem_paths;

    // ---- ban do dia chi (khop rtl/top_soc.v va Driver/ld/soc.ld) -----------
    localparam [31:0] ADDR_ITCM    = 32'h0002_0000;
    localparam [31:0] ADDR_DTCM    = 32'h0002_4000;
    localparam [31:0] ADDR_RAM_LO  = 32'h2000_0000;
    localparam [31:0] ADDR_RAM_HI  = 32'h2002_0000;   // DMAPOOL, uncached
    localparam [31:0] ADDR_SYSCON  = 32'h4000_7000;
    localparam [31:0] ADDR_DMA_CH0 = 32'h4000_8000;
    localparam [31:0] ADDR_DMA_CH1 = 32'h4000_9000;

    // offset thanh ghi DMA (rtl/interrupt/dma/dma_defines.vh)
    localparam [31:0] DMA_SRC   = 32'h00, DMA_DST = 32'h04, DMA_LEN = 32'h08,
                      DMA_CTL   = 32'h0C, DMA_STS = 32'h10, DMA_ISTAT = 32'h18;

    localparam [1:0] SZ_B = 2'b00, SZ_H = 2'b01, SZ_W = 2'b10;

    // ---- scoreboard --------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer timeout_hits;

    task automatic chk32(input [255:0] name, input [31:0] got, input [31:0] exp);
        begin
            if (got === exp) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s = %08h", name, got);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s = %08h  (mong doi %08h)", name, got, exp);
            end
        end
    endtask

    // ---- clock / reset -----------------------------------------------------
    reg clk_400m, clk_200m, clk_100m, rtc_clk;
    reg rst_n;

    initial begin clk_400m = 0; forever #1.25  clk_400m = ~clk_400m; end
    initial begin clk_200m = 0; forever #2.5   clk_200m = ~clk_200m; end
    initial begin clk_100m = 0; forever #5.0   clk_100m = ~clk_100m; end
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
        .clk_core      (clk_400m),
        .clk_axi       (clk_200m),
        .clk_apb       (clk_100m),
        .clk_sdram_ext (clk_200m),
        .uart_clk      (clk_100m),
        .spi_clk       (clk_100m),
        .i2c_clk       (clk_100m),
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

    // =========================================================================
    // Backdoor core-side: testbench dong vai CPU
    // =========================================================================
    reg        tb_if_req;
    reg [31:0] tb_if_addr;
    reg        tb_d_rd, tb_d_wr;
    reg [31:0] tb_d_addr, tb_d_wdata;
    reg [1:0]  tb_d_size;
    reg        tb_d_uns;

    initial begin
        tb_if_req = 1'b0;  tb_if_addr = 32'h0;
        tb_d_rd   = 1'b0;  tb_d_wr    = 1'b0;
        tb_d_addr = 32'h0; tb_d_wdata = 32'h0;
        tb_d_size = SZ_W;  tb_d_uns   = 1'b0;

        force uut.clk_en_cpu_s      = 1'b1;
        force uut.clk_en_dbg_s      = 1'b1;
        force uut.cpu_inst_req      = tb_if_req;
        force uut.cpu_inst_addr     = tb_if_addr;
        force uut.cpu_data_rd_req   = tb_d_rd;
        force uut.cpu_data_wr_req   = tb_d_wr;
        force uut.cpu_data_addr     = tb_d_addr;
        force uut.cpu_data_wdata    = tb_d_wdata;
        force uut.cpu_data_size     = tb_d_size;
        force uut.cpu_data_unsigned = tb_d_uns;
    end

    localparam integer HANDSHAKE_TIMEOUT = 4000;   // chu ky clk_cpu

    // So chu ky cua giao dich core-side gan nhat.  Phan biet cache hit (2 chu
    // ky) voi cache miss (mot vong AXI qua CDC 400/200) - hai truong hop tra ve
    // cung gia tri nen khong the phan biet bang du lieu.
    integer last_xact_cycles;

    // Giu request on dinh cho toi khi thay `hit` - dung giao thuc ma dcache,
    // icache va tcm deu dung: `stall` cao suot, `hit` la xung mot chu ky.
    task automatic cpu_xact(input         is_write,
                            input  [31:0] addr,
                            input  [31:0] wdata,
                            input  [1:0]  size,
                            input         uns,
                            output [31:0] rdata);
        integer n;
        begin
            @(negedge clk_400m);
            tb_d_addr  = addr;
            tb_d_wdata = wdata;
            tb_d_size  = size;
            tb_d_uns   = uns;
            tb_d_wr    = is_write;
            tb_d_rd    = ~is_write;

            n = 0;
            while ((uut.cpu_data_hit !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk_400m);
                #0.2;
                n = n + 1;
            end

            if (n >= HANDSHAKE_TIMEOUT) begin
                timeout_hits = timeout_hits + 1;
                fail_count   = fail_count + 1;
                $display("[FAIL] TIMEOUT %0s addr=%08h sau %0d chu ky",
                         is_write ? "store" : "load", addr, n);
                rdata = 32'hDEAD_DEAD;
            end else begin
                rdata = uut.cpu_data_rdata;
            end
            last_xact_cycles = n;

            // Giu request them tron mot canh len nua.  Loi CPU that co
            // `dcache_read_req` la dau ra CHOT: no chi ha o canh len ke tiep,
            // nen o chinh canh do, cac flop trong dcache van nhin thay request
            // con cao.  Cap nhat valid/tag cua mot read miss xay ra dung o
            // canh nay (`state == DONE && cpu_read_req`), nen neu testbench ha
            // request som nua chu ky thi khong line nao duoc allocate va moi
            // lan doc deu miss - dung nhu da quan sat luc dau.
            @(posedge clk_400m);
            #0.2;
            tb_d_wr = 1'b0;
            tb_d_rd = 1'b0;
        end
    endtask

    reg [31:0] junk;

    task automatic sw (input [31:0] a, input [31:0] d);
        begin cpu_xact(1'b1, a, d, SZ_W, 1'b0, junk); end
    endtask
    task automatic sh_(input [31:0] a, input [31:0] d);
        begin cpu_xact(1'b1, a, d, SZ_H, 1'b0, junk); end
    endtask
    task automatic sb_(input [31:0] a, input [31:0] d);
        begin cpu_xact(1'b1, a, d, SZ_B, 1'b0, junk); end
    endtask
    task automatic lw (input [31:0] a, output [31:0] d);
        begin cpu_xact(1'b0, a, 32'h0, SZ_W, 1'b0, d); end
    endtask
    task automatic lhu(input [31:0] a, output [31:0] d);
        begin cpu_xact(1'b0, a, 32'h0, SZ_H, 1'b1, d); end
    endtask
    task automatic lbu(input [31:0] a, output [31:0] d);
        begin cpu_xact(1'b0, a, 32'h0, SZ_B, 1'b1, d); end
    endtask
    task automatic lb (input [31:0] a, output [31:0] d);
        begin cpu_xact(1'b0, a, 32'h0, SZ_B, 1'b0, d); end
    endtask

    // Port fetch: chi doc, dung cho ITCM.
    task automatic ifetch(input [31:0] addr, output [31:0] data);
        integer n;
        begin
            @(negedge clk_400m);
            tb_if_addr = addr;
            tb_if_req  = 1'b1;
            n = 0;
            while ((uut.cpu_inst_hit !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk_400m);
                #0.2;
                n = n + 1;
            end
            if (n >= HANDSHAKE_TIMEOUT) begin
                timeout_hits = timeout_hits + 1;
                fail_count   = fail_count + 1;
                $display("[FAIL] TIMEOUT fetch addr=%08h", addr);
                data = 32'hDEAD_DEAD;
            end else begin
                data = uut.cpu_inst_data;
            end
            @(posedge clk_400m);
            #0.2;
            tb_if_req = 1'b0;
        end
    endtask

    // =========================================================================
    // Backdoor debug: dong vai System Bus Access cua Debug Module.
    //
    // rv_debug_module_sba dich thanh ghi sbaddress/sbdata cua OpenOCD thanh
    // giao dich {req, op, size, addr, wdata} roi dua cho dtm_axi_master.  Cuop
    // dung cho do la du de kiem tra duong debug -> AXI ma khong can mo hinh
    // JTAG: sbaccess (8/16/32 bit) di thang vao `size`.
    // =========================================================================
    reg        tb_sba_req;
    reg [1:0]  tb_sba_op, tb_sba_size;
    reg [31:0] tb_sba_addr, tb_sba_wdata;

    initial begin
        tb_sba_req  = 1'b0; tb_sba_op = 2'd0; tb_sba_size = 2'd2;
        tb_sba_addr = 32'h0; tb_sba_wdata = 32'h0;
        force uut.sba_req   = tb_sba_req;
        force uut.sba_op    = tb_sba_op;
        force uut.sba_size  = tb_sba_size;
        force uut.sba_addr  = tb_sba_addr;
        force uut.sba_wdata = tb_sba_wdata;
    end

    task automatic sba_xact(input  [1:0]  op,      // 2'd1 = doc, 2'd2 = ghi
                            input  [1:0]  size,    // 0 = byte, 1 = half, 2 = word
                            input  [31:0] addr,
                            input  [31:0] wdata,
                            output [31:0] rdata,
                            output [1:0]  resp);
        integer n;
        begin
            @(negedge clk_200m);
            tb_sba_op    = op;
            tb_sba_size  = size;
            tb_sba_addr  = addr;
            tb_sba_wdata = wdata;
            tb_sba_req   = 1'b1;

            n = 0;
            while ((uut.sba_ack !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk_200m);
                #0.2;
                n = n + 1;
            end
            if (n >= HANDSHAKE_TIMEOUT) begin
                timeout_hits = timeout_hits + 1;
                fail_count   = fail_count + 1;
                $display("[FAIL] TIMEOUT SBA op=%0d addr=%08h", op, addr);
                rdata = 32'hDEAD_DEAD;
                resp  = 2'b11;
            end else begin
                rdata = uut.sba_rdata;
                resp  = uut.sba_resp;
            end
            @(negedge clk_200m);
            tb_sba_req = 1'b0;
            repeat (2) @(posedge clk_200m);
        end
    endtask

    // =========================================================================
    // Helper DMA - cau hinh qua APB bang chinh duong store uncached cua CPU
    // =========================================================================
    task automatic dma_copy(input  [31:0] ch_base,
                            input  [31:0] src,
                            input  [31:0] dst,
                            input  [31:0] len_bytes,
                            output        ok);
        reg [31:0] sts;
        integer    poll;
        begin
            sw(ch_base + DMA_ISTAT, 32'h3);          // W1C co cu
            sw(ch_base + DMA_SRC,   src);
            sw(ch_base + DMA_DST,   dst);
            sw(ch_base + DMA_LEN,   len_bytes);
            // [0]=start, [7:1]=burst_max (0 = dung MAX_BURST), [8]=src_incr,
            // [9]=dst_incr, [14:10]=periph_num (0 = memory-to-memory)
            sw(ch_base + DMA_CTL,   32'h0000_0301);

            ok   = 1'b0;
            poll = 0;
            while ((poll < 400) && !ok) begin
                lw(ch_base + DMA_STS, sts);
                if (sts[1]) ok = 1'b1;               // STATUS.done (latched)
                else if (sts[3:2] != 2'b00) begin
                    $display("[FAIL] DMA bao loi err=%b (src=%08h dst=%08h)",
                             sts[3:2], src, dst);
                    poll = 400;
                end
                poll = poll + 1;
            end
            if (!ok)
                $display("[FAIL] DMA khong bao done: src=%08h dst=%08h len=%0d",
                         src, dst, len_bytes);
            sw(ch_base + DMA_ISTAT, 32'h3);
        end
    endtask

    // =========================================================================
    // Kich ban
    // =========================================================================
    reg [31:0] d, e;
    reg [1:0]  sba_resp;
    reg        ok;
    integer    i;
    integer    n_fetch_wait;
    reg [31:0] itcm_words [0:7];

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        timeout_hits = 0;
        gpio_in      = 32'h0;
        tck = 0; trst_n = 0; tms = 0; tdi = 0;
        rst_n = 1'b0;
        repeat (40) @(posedge clk_100m);
        rst_n  = 1'b1;
        trst_n = 1'b1;
        repeat (40) @(posedge clk_100m);

        $display("");
        $display("=== tb_mem_paths: cac duong bo nho mo o Phase 0 ===");
        $display("");

        // ------------------------------------------------------------------
        // T0 - decode: nua nao cua system RAM la uncached
        // ------------------------------------------------------------------
        $display("--- T0: decode SOC_IS_UNCACHED ---");
        @(negedge clk_400m);
        tb_d_addr = ADDR_RAM_LO; #0.2;
        chk32("RAM lo  0x20000000 -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h0);
        @(negedge clk_400m);
        tb_d_addr = ADDR_RAM_HI; #0.2;
        chk32("RAM hi  0x20020000 -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h1);
        @(negedge clk_400m);
        tb_d_addr = ADDR_RAM_HI + 32'h1_FFFC; #0.2;
        chk32("RAM hi  0x2003FFFC -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h1);
        @(negedge clk_400m);
        tb_d_addr = ADDR_RAM_LO + 32'h1_FFFC; #0.2;
        chk32("RAM lo  0x2001FFFC -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h0);
        @(negedge clk_400m);
        tb_d_addr = ADDR_DTCM; #0.2;
        chk32("DTCM    0x00024000 -> ls_sel_dtcm", {31'b0, uut.ls_sel_dtcm}, 32'h1);
        @(negedge clk_400m);
        tb_d_addr = ADDR_ITCM; #0.2;
        chk32("ITCM    0x00020000 -> ls_sel_itcm", {31'b0, uut.ls_sel_itcm}, 32'h1);
        @(negedge clk_400m);
        tb_d_addr = 32'h0;

        // ------------------------------------------------------------------
        // TP - D-cache co THAT SU hit khong?
        //
        //   Doc lan dau  = miss, phai di tron mot vong AXI qua CDC 400/200.
        //   Doc lan sau  = hit,  phai xong trong vai chu ky clk_cpu.
        //
        // Khong bai test chuc nang nao phan biet duoc hai truong hop nay: ca
        // hai deu tra ve dung gia tri, chi khac toc do.  Mot cache khong bao
        // gio allocate van "chay dung" va van im lang lam chip cham gap chuc
        // lan.  Do do tre la cach duy nhat bat duoc, va Phase 1 (store buffer)
        // dung vao chinh duong nay nen phai co chot o day truoc.
        // ------------------------------------------------------------------
        $display("");
        $display("--- TP: D-cache co hit khong (do do tre) ---");
        sw(ADDR_RAM_LO + 32'h7000, 32'h0F0F_0F0F);

        lw(ADDR_RAM_LO + 32'h7000, d);
        chk32("TP doc lan dau tra ve dung gia tri", d, 32'h0F0F_0F0F);
        if (last_xact_cycles >= 10) begin
            pass_count = pass_count + 1;
            $display("[PASS] doc lan dau la miss: %0d chu ky", last_xact_cycles);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] doc lan dau chi ton %0d chu ky - dang le phai la miss",
                     last_xact_cycles);
        end

        for (i = 1; i < 4; i = i + 1) begin
            lw(ADDR_RAM_LO + 32'h7000, d);
            chk32("TP doc lai tra ve dung gia tri", d, 32'h0F0F_0F0F);
            if (last_xact_cycles <= 3) begin
                pass_count = pass_count + 1;
                $display("[PASS] doc lai lan %0d la hit: %0d chu ky",
                         i, last_xact_cycles);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] doc lai lan %0d ton %0d chu ky - D-cache khong hit",
                         i, last_xact_cycles);
            end
        end

        if (uut.u_dcache.valid_arr[0] != 0) begin
            pass_count = pass_count + 1;
            $display("[PASS] D-cache da allocate line: valid_arr[set 0] = %b",
                     uut.u_dcache.valid_arr[0]);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] D-cache khong allocate line nao: valid_arr[set 0] = %b",
                     uut.u_dcache.valid_arr[0]);
        end

        // ------------------------------------------------------------------
        // T1 - RAM hi, truy cap word. Chung minh slave 6 ton tai va tra loi.
        //      Bao gom bien macro (4 KiB) va word cuoi cung cua instance.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T1: RAM hi (slave 6, uncached) truy cap word ---");
        sw(ADDR_RAM_HI + 32'h00000, 32'hCAFE_0001);
        sw(ADDR_RAM_HI + 32'h00004, 32'hCAFE_0002);
        sw(ADDR_RAM_HI + 32'h00FFC, 32'hCAFE_0003);   // word cuoi macro 0
        sw(ADDR_RAM_HI + 32'h01000, 32'hCAFE_0004);   // word dau macro 1
        sw(ADDR_RAM_HI + 32'h1FFFC, 32'hCAFE_0005);   // word cuoi instance

        lw(ADDR_RAM_HI + 32'h00000, d); chk32("RAM hi word 0x00000", d, 32'hCAFE_0001);
        lw(ADDR_RAM_HI + 32'h00004, d); chk32("RAM hi word 0x00004", d, 32'hCAFE_0002);
        lw(ADDR_RAM_HI + 32'h00FFC, d); chk32("RAM hi word 0x00FFC cuoi macro 0", d, 32'hCAFE_0003);
        lw(ADDR_RAM_HI + 32'h01000, d); chk32("RAM hi word 0x01000 dau macro 1", d, 32'hCAFE_0004);
        lw(ADDR_RAM_HI + 32'h1FFFC, d); chk32("RAM hi word 0x1FFFC cuoi instance", d, 32'hCAFE_0005);

        // RAM lo phai khong bi anh huong: hai instance thuc su tach roi.
        sw(ADDR_RAM_LO + 32'h00000, 32'h1234_5678);
        lw(ADDR_RAM_LO + 32'h00000, d); chk32("RAM lo word 0x00000 cacheable", d, 32'h1234_5678);
        lw(ADDR_RAM_HI + 32'h00000, d); chk32("RAM hi khong bi RAM lo ghi de", d, 32'hCAFE_0001);

        // ------------------------------------------------------------------
        // T2 - RAM hi, byte/halfword.
        //      Day la duong MOI: vung uncached truoc Phase 0 chi co APB va
        //      CLINT (deu la thanh ghi word).  Gio DMAPOOL la bo nho that, nen
        //      sb/sh/lb/lh phai chay dung qua read-modify-write cua axi_ram.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T2: RAM hi, truy cap byte / halfword ---");
        sw (ADDR_RAM_HI + 32'h0100, 32'h0000_0000);
        sb_(ADDR_RAM_HI + 32'h0101, 32'h0000_00AB);
        lw (ADDR_RAM_HI + 32'h0100, d); chk32("sb lane 1 -> word", d, 32'h0000_AB00);
        lbu(ADDR_RAM_HI + 32'h0101, d); chk32("lbu lane 1", d, 32'h0000_00AB);
        lb (ADDR_RAM_HI + 32'h0101, d); chk32("lb lane 1 sign-extend", d, 32'hFFFF_FFAB);

        sh_(ADDR_RAM_HI + 32'h0102, 32'h0000_1234);
        lw (ADDR_RAM_HI + 32'h0100, d); chk32("sh half tren -> word", d, 32'h1234_AB00);
        lhu(ADDR_RAM_HI + 32'h0102, d); chk32("lhu half tren", d, 32'h0000_1234);

        sb_(ADDR_RAM_HI + 32'h0100, 32'h0000_005A);
        lw (ADDR_RAM_HI + 32'h0100, d); chk32("sb lane 0 giu nguyen lane khac", d, 32'h1234_AB5A);

        // ------------------------------------------------------------------
        // T3 - DTCM.  Truoc test nay TCM chua tung duoc kich hoat lan nao.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T3: DTCM (ngoai AXI, noi thang core) ---");
        sw(ADDR_DTCM + 32'h0000, 32'hD7C0_0001);
        sw(ADDR_DTCM + 32'h0004, 32'hD7C0_0002);
        sw(ADDR_DTCM + 32'h3FFC, 32'hD7C0_0003);     // word cuoi 16 KiB
        lw(ADDR_DTCM + 32'h0000, d); chk32("DTCM word 0x0000", d, 32'hD7C0_0001);
        lw(ADDR_DTCM + 32'h0004, d); chk32("DTCM word 0x0004", d, 32'hD7C0_0002);
        lw(ADDR_DTCM + 32'h3FFC, d); chk32("DTCM word 0x3FFC cuoi vung", d, 32'hD7C0_0003);

        sw (ADDR_DTCM + 32'h0100, 32'h0000_0000);
        sb_(ADDR_DTCM + 32'h0103, 32'h0000_0099);
        lw (ADDR_DTCM + 32'h0100, d); chk32("DTCM sb lane 3 (RMW 3 chu ky)", d, 32'h9900_0000);
        sh_(ADDR_DTCM + 32'h0100, 32'h0000_BEEF);
        lw (ADDR_DTCM + 32'h0100, d); chk32("DTCM sh half duoi", d, 32'h9900_BEEF);
        lhu(ADDR_DTCM + 32'h0100, d); chk32("DTCM lhu half duoi", d, 32'h0000_BEEF);
        lbu(ADDR_DTCM + 32'h0103, d); chk32("DTCM lbu lane 3", d, 32'h0000_0099);

        // DTCM khong duoc dung chung mang voi RAM.
        lw(ADDR_RAM_LO + 32'h0000, d); chk32("RAM lo khong bi DTCM ghi de", d, 32'h1234_5678);

        // ------------------------------------------------------------------
        // T4 - ITCM: copy code bang port D roi fetch bang port F.
        //      Day chinh la rang buoc thu tu boot ma soc.ld va crt0 phai giu:
        //      ITCM la X luc power-up, phai ghi truoc khi nhay vao.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T4: ITCM, ghi bang port D roi fetch bang port F ---");
        itcm_words[0] = 32'h0000_0013;   // nop
        itcm_words[1] = 32'h0010_0093;   // li x1,1
        itcm_words[2] = 32'h0020_0113;   // li x2,2
        itcm_words[3] = 32'h0030_0193;   // li x3,3
        itcm_words[4] = 32'h0040_0213;
        itcm_words[5] = 32'h0050_0293;
        itcm_words[6] = 32'h0060_0313;
        itcm_words[7] = 32'h0070_0393;

        for (i = 0; i < 8; i = i + 1)
            sw(ADDR_ITCM + i*4, itcm_words[i]);

        // Doc lai bang port D truoc (chung minh mang da co du lieu)
        for (i = 0; i < 8; i = i + 1) begin
            lw(ADDR_ITCM + i*4, d);
            chk32("ITCM doc lai bang port D", d, itcm_words[i]);
        end

        // Roi fetch bang port F - duong ma steady-state se dung
        for (i = 0; i < 8; i = i + 1) begin
            ifetch(ADDR_ITCM + i*4, d);
            chk32("ITCM fetch bang port F", d, itcm_words[i]);
        end

        sw(ADDR_ITCM + 32'h3FFC, 32'hF17C_0001);
        ifetch(ADDR_ITCM + 32'h3FFC, d);
        chk32("ITCM fetch word cuoi 0x3FFC", d, 32'hF17C_0001);

        lw(ADDR_DTCM + 32'h0000, d); chk32("DTCM khong bi ITCM ghi de", d, 32'hD7C0_0001);

        // ------------------------------------------------------------------
        // T5 - ITCM: tranh chap port F / port D.
        //      Luat trong tcm.v: port D thang, TRU KHI mot fetch da thua o chu
        //      ky truoc (bit f_starved).  Nghia la mot chuoi load/store lien
        //      tiep khong the giu fetch lai vo han.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T5: ITCM, trong tai F/D (luat f_starved) ---");
        @(negedge clk_400m);
        tb_if_addr = ADDR_ITCM + 32'h0004;
        tb_if_req  = 1'b1;
        tb_d_addr  = ADDR_ITCM + 32'h0000;
        tb_d_size  = SZ_W;
        tb_d_uns   = 1'b0;
        tb_d_rd    = 1'b1;

        n_fetch_wait = 0;
        while ((uut.cpu_inst_hit !== 1'b1) && (n_fetch_wait < 200)) begin
            @(posedge clk_400m);
            #0.2;
            n_fetch_wait = n_fetch_wait + 1;
        end
        d = uut.cpu_inst_data;
        @(negedge clk_400m);
        tb_if_req = 1'b0;
        tb_d_rd   = 1'b0;

        if (n_fetch_wait < 200) begin
            pass_count = pass_count + 1;
            $display("[PASS] fetch duoc phuc vu sau %0d chu ky du port D giu lien tuc",
                     n_fetch_wait);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] fetch bi bo doi: port D giu ITCM vo han");
        end
        chk32("ITCM du lieu fetch trong luc tranh chap", d, itcm_words[1]);

        // ------------------------------------------------------------------
        // T6 - P0: DMA ghi DMAPOOL roi CPU doc lai.
        //      Day la ly do ton tai cua ca Phase 0.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T6: DMA -> DMAPOOL -> CPU (chung minh P0) ---");

        // Nguon nam o RAM lo (cacheable).  CPU ghi write-through nen RAM that
        // su co du lieu, DMA doc ra dung.
        for (i = 0; i < 16; i = i + 1)
            sw(ADDR_RAM_LO + 32'h1000 + i*4, 32'h000D_A000 + i);

        for (i = 0; i < 16; i = i + 1)
            sw(ADDR_RAM_HI + 32'h0200 + i*4, 32'h0);

        dma_copy(ADDR_DMA_CH0, ADDR_RAM_LO + 32'h1000, ADDR_RAM_HI + 32'h0200, 32'd64, ok);
        if (ok) begin
            pass_count = pass_count + 1;
            $display("[PASS] DMA bao done cho 64 byte lo -> hi");
        end else begin
            fail_count = fail_count + 1;
        end

        for (i = 0; i < 16; i = i + 1) begin
            lw(ADDR_RAM_HI + 32'h0200 + i*4, d);
            chk32("CPU doc DMAPOOL sau khi DMA ghi", d, 32'h000D_A000 + i);
        end

        // Chieu nguoc lai: DMA doc DMAPOOL do CPU vua ghi.  Vi vung nay
        // uncached nen khong co line ban nao ket trong D-cache.
        for (i = 0; i < 4; i = i + 1)
            sw(ADDR_RAM_HI + 32'h0400 + i*4, 32'h000B_B000 + i);
        dma_copy(ADDR_DMA_CH0, ADDR_RAM_HI + 32'h0400, ADDR_RAM_HI + 32'h0500, 32'd16, ok);
        for (i = 0; i < 4; i = i + 1) begin
            lw(ADDR_RAM_HI + 32'h0500 + i*4, d);
            chk32("DMA doc DMAPOOL do CPU ghi", d, 32'h000B_B000 + i);
        end

        // Store duoi 32 bit vao RAM lo co THAT SU toi RAM khong?  D-cache co
        // the che mat loi nay: mot write hit cap nhat mang SRAM cua cache nen
        // CPU doc lai van dung, ke ca khi AXI beat bi slave tu choi.  Dung DMA
        // - master khac, khong qua cache - de doc ra su that.
        sw (ADDR_RAM_LO + 32'h2000, 32'h0000_0000);
        lw (ADDR_RAM_LO + 32'h2000, d);              // nap line vao cache
        sb_(ADDR_RAM_LO + 32'h2001, 32'h0000_007E);
        sh_(ADDR_RAM_LO + 32'h2002, 32'h0000_5A5A);
        dma_copy(ADDR_DMA_CH0, ADDR_RAM_LO + 32'h2000, ADDR_RAM_HI + 32'h0600, 32'd4, ok);
        lw(ADDR_RAM_HI + 32'h0600, d);
        chk32("sb/sh vao RAM lo co toi RAM that (doc bang DMA)", d, 32'h5A5A_7E00);

        // ------------------------------------------------------------------
        // T7 - Thu tu store vao MMIO.
        //      Bat buoc phai co TRUOC Phase 1: store buffer chi duoc phep dem
        //      vung cacheable.  Neu no dem ca store thiet bi thi bai test nay
        //      se do - va do la ca muc dich cua no.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T7: thu tu store vao MMIO (baseline cho Phase 1) ---");

        lw(ADDR_SYSCON + 32'h000, e);                 // giu lai de tra ve sau
        sw(ADDR_SYSCON + 32'h000, 32'h0001_0000);
        lw(ADDR_SYSCON + 32'h000, d);
        chk32("syscon ghi roi doc ngay", d, 32'h0001_0000);
        sw(ADDR_SYSCON + 32'h000, 32'h0002_0000);
        lw(ADDR_SYSCON + 32'h000, d);
        chk32("syscon ghi de roi doc ngay", d, 32'h0002_0000);
        sw(ADDR_SYSCON + 32'h000, e);                 // tra lai reset vector cu

        // Chuoi store toi NHIEU thanh ghi thiet bi khac nhau, roi doc lai tat
        // ca.  Bat duoc truong hop store buffer dao thu tu hoac nuot entry.
        sw(ADDR_DMA_CH1 + DMA_SRC, 32'h2000_3000);
        sw(ADDR_DMA_CH1 + DMA_DST, 32'h2002_3000);
        sw(ADDR_DMA_CH1 + DMA_LEN, 32'h0000_0020);
        lw(ADDR_DMA_CH1 + DMA_SRC, d); chk32("DMA ch1 SRC sau chuoi store", d, 32'h2000_3000);
        lw(ADDR_DMA_CH1 + DMA_DST, d); chk32("DMA ch1 DST sau chuoi store", d, 32'h2002_3000);
        lw(ADDR_DMA_CH1 + DMA_LEN, d); chk32("DMA ch1 LEN sau chuoi store", d, 32'h0000_0020);

        // Store thiet bi xen ke store bo nho: khong duoc phep vuot nhau.
        sw(ADDR_DMA_CH1 + DMA_SRC, 32'h2000_4000);
        sw(ADDR_RAM_HI + 32'h0700, 32'h0BAD_0001);
        sw(ADDR_DMA_CH1 + DMA_DST, 32'h2002_4000);
        sw(ADDR_RAM_LO + 32'h3000, 32'h0BAD_0002);
        lw(ADDR_DMA_CH1 + DMA_SRC, d); chk32("MMIO/RAM xen ke SRC", d, 32'h2000_4000);
        lw(ADDR_DMA_CH1 + DMA_DST, d); chk32("MMIO/RAM xen ke DST", d, 32'h2002_4000);
        lw(ADDR_RAM_HI + 32'h0700, d); chk32("MMIO/RAM xen ke RAM hi", d, 32'h0BAD_0001);
        lw(ADDR_RAM_LO + 32'h3000, d); chk32("MMIO/RAM xen ke RAM lo", d, 32'h0BAD_0002);

        // ------------------------------------------------------------------
        // T9 - Duong debug (DTM / System Bus Access).
        //      axi_ram ghi ro trong header rang chi phi read-modify-write roi
        //      vao "sb/sh cua D-cache write-through VA ghi tu debug module".
        //      Nghia la ghi duoi 32 bit tu debugger phai chay dung.  Neu no
        //      hong thi `set variable` cua GDB tren mot bien char/short se am
        //      tham khong co tac dung.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T9: debug System Bus Access (DTM -> AXI) ---");

        sba_xact(2'd2, 2'd2, ADDR_RAM_HI + 32'h0800, 32'h0000_0000, d, sba_resp);
        chk32("SBA ghi word: BRESP OKAY", {30'b0, sba_resp}, 32'h0);
        sba_xact(2'd1, 2'd2, ADDR_RAM_HI + 32'h0800, 32'h0, d, sba_resp);
        chk32("SBA doc word ngay sau khi ghi", d, 32'h0000_0000);

        sba_xact(2'd2, 2'd2, ADDR_RAM_HI + 32'h0800, 32'hAABB_CCDD, d, sba_resp);
        lw(ADDR_RAM_HI + 32'h0800, d);
        chk32("CPU doc lai word do SBA ghi", d, 32'hAABB_CCDD);

        // Ghi byte tu debugger: chi lane 2 duoc doi.
        sba_xact(2'd2, 2'd0, ADDR_RAM_HI + 32'h0802, 32'h0000_0011, d, sba_resp);
        chk32("SBA ghi byte: BRESP OKAY", {30'b0, sba_resp}, 32'h0);
        lw(ADDR_RAM_HI + 32'h0800, d);
        chk32("CPU doc lai sau SBA ghi byte lane 2", d, 32'hAA11_CCDD);

        // Ghi halfword tu debugger: chi hai lane duoi doi.
        sba_xact(2'd2, 2'd1, ADDR_RAM_HI + 32'h0800, 32'h0000_2233, d, sba_resp);
        chk32("SBA ghi half: BRESP OKAY", {30'b0, sba_resp}, 32'h0);
        lw(ADDR_RAM_HI + 32'h0800, d);
        chk32("CPU doc lai sau SBA ghi half duoi", d, 32'hAA11_2233);

        // Debugger doc lai vung CPU vua ghi.
        sw(ADDR_RAM_HI + 32'h0810, 32'h5566_7788);
        sba_xact(2'd1, 2'd2, ADDR_RAM_HI + 32'h0810, 32'h0, d, sba_resp);
        chk32("SBA doc word do CPU ghi", d, 32'h5566_7788);
        chk32("SBA doc word: RRESP OKAY", {30'b0, sba_resp}, 32'h0);

        // Doc duoi 32 bit: slave chi tra ve nguyen word, nhung phai la OKAY -
        // khong duoc bien thanh SLVERR.
        sba_xact(2'd1, 2'd0, ADDR_RAM_HI + 32'h0812, 32'h0, d, sba_resp);
        chk32("SBA doc byte: RRESP OKAY", {30'b0, sba_resp}, 32'h0);

        // Cung nhu vay tren RAM lo (cacheable) - debugger khong qua cache nen
        // day la duong khac han.
        sw(ADDR_RAM_LO + 32'h6000, 32'h0000_0000);
        sba_xact(2'd2, 2'd0, ADDR_RAM_LO + 32'h6001, 32'h0000_00C3, d, sba_resp);
        chk32("SBA ghi byte vao RAM lo: BRESP OKAY", {30'b0, sba_resp}, 32'h0);
        dma_copy(ADDR_DMA_CH0, ADDR_RAM_LO + 32'h6000, ADDR_RAM_HI + 32'h0900, 32'd4, ok);
        lw(ADDR_RAM_HI + 32'h0900, d);
        chk32("SBA ghi byte co toi RAM lo that (doc bang DMA)", d, 32'h0000_C300);

        // ------------------------------------------------------------------
        // T8 - Doi chung: vi sao buffer DMA PHAI nam o nua hi.
        //      Khong tinh diem - day la mo ta hanh vi, khong phai yeu cau.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T8: doi chung, hazard coherency tren vung cacheable ---");
        // Dia chi phai roi vao set con trong: index = addr[11:4], nen moi dia
        // chi boi cua 0x1000 o cac test tren deu dung chung set 0 va line se bi
        // evict truoc khi kip quan sat.
        sw(ADDR_RAM_LO + 32'h4010, 32'h1111_1111);
        lw(ADDR_RAM_LO + 32'h4010, d);   // nap line vao D-cache (set 0x01)
        $display("[INFO] doc lan 1 (miss, nap line): %08h sau %0d chu ky",
                 d, last_xact_cycles);
        sw(ADDR_RAM_LO + 32'h5020, 32'h2222_2222);
        dma_copy(ADDR_DMA_CH0, ADDR_RAM_LO + 32'h5020, ADDR_RAM_LO + 32'h4010, 32'd4, ok);
        lw(ADDR_RAM_LO + 32'h4010, d);
        $display("[INFO] doc sau khi DMA ghi:         %08h sau %0d chu ky",
                 d, last_xact_cycles);
        if (d === 32'h1111_1111)
            $display("[INFO] CPU van doc 1111_1111 sau khi DMA ghi 2222_2222 vao vung");
        else if (d === 32'h2222_2222)
            $display("[INFO] line da bi evict nen lan nay khong quan sat duoc hazard");
        else
            $display("[INFO] gia tri khac: %08h", d);
        $display("[INFO] -> day chinh la ly do .dmabuf phai nam o DMAPOOL uncached");

        // ------------------------------------------------------------------
        $display("");
        $display("=== tb_mem_paths ket qua ===");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("TIMEOUTS   = %0d", timeout_hits);
        if (fail_count == 0) $display("RESULT: PASS");
        else                 $display("RESULT: FAIL");
        $display("");
        $finish;
    end

    // Chot an toan: khong bai test nao duoc phep chay lau hon muc nay.
    initial begin
        #4000000;
        $display("[FAIL] TIMEOUT TOAN CUC - testbench treo");
        $display("RESULT: FAIL");
        $finish;
    end

endmodule
