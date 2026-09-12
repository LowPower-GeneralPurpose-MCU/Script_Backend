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
// `clk_en_cpu` bi force len 1 vi loi CPU that dang treo o fetch (ta cuop port
// cua no).  Neu no giai ma nham mot lenh rac thanh WFI thi clock CPU tat va
// testbench treo; force la cach re nhat de loai bo hoan toan kha nang do.
//
// Cac nhom test (theo thu tu chay):
//   T0  decode SOC_IS_UNCACHED
//   TP  D-cache co hit khong            - do do tre, hit <= 3 / miss >= 10
//   TS  Store buffer cua D-cache       - Phase 1 / P2
//   TF  `fence` xa store buffer        - P2c
//   T1  RAM hi, truy cap word           - chung minh slave 6 + duong uncached
//   T2  RAM hi, truy cap byte/halfword  - sb/sh/lb/lh vao DMAPOOL
//   T3  DTCM                            - TCM chua tung duoc kich hoat lan nao
//   T4  ITCM: ghi bang port D roi fetch bang port F (rang buoc thu tu boot)
//   T5  ITCM: tranh chap F/D, luat f_starved
//   T6  DMA ghi DMAPOOL roi CPU doc lai - chung minh P0 that su dong
//   T7  Thu tu store vao MMIO           - bai test BAT BUOC truoc Phase 1
//   T9  Debugger SBA ghi/doc bo nho     - dung `fence_()` that (P2c)
//   T8  Doi chung hazard coherency      - vung cacheable, chung minh P0
//   T10 Lenh nguyen tu (AMO)            - R1b bat tay 2 chu ky, R11 AMO truot
//   T10e QUAN SAT (khong tinh diem)     - AMO vao vung uncached, R12 chua sua
//
// Tong so check mong doi: 128 (121 truoc P2c + 7 cua TF).
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
    // SoC mot clock tu 2026-09-11: moi thu chay bang clk 250 MHz.
    reg clk, rtc_clk;
    reg rst_n;

    initial begin clk      = 0; forever #2.0   clk      = ~clk;      end
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

    // =========================================================================
    // Backdoor core-side: testbench dong vai CPU
    // =========================================================================
    reg        tb_if_req;
    reg [31:0] tb_if_addr;
    reg        tb_d_rd, tb_d_wr;
    reg        tb_d_fence;                 // P2c
    reg [31:0] tb_d_addr, tb_d_wdata;
    reg [1:0]  tb_d_size;
    reg        tb_d_uns;

    // ---------------------------------------------------------------------
    // R1b / R11 - testbench dong vai TANG MEM cho lenh nguyen tu.
    //
    // Testbench nay force cong core-side cua top_soc nen bo qua `memory_access`,
    // tuc bo qua luon AMO ALU nam trong pipeline_stage.v.  Muon kiem duong AMO
    // ben trong dcache thi phai mo phong dung giao thuc ma pipeline dung:
    //   1. giu CA cpu_data_rd_req lan cpu_data_wr_req cung `cpu_data_amo_req`
    //   2. chot du lieu doc o chu ky co `cpu_data_amo_capture`
    //   3. tu chu ky sau dat KET QUA ALU len cpu_data_wdata
    // Day chinh la cach dong lo hong verification ghi trong §14 cua
    // GENUS_REVIEW_2026-09-09.md ma khong can toolchain RISC-V.
    // ---------------------------------------------------------------------
    localparam [4:0] AMO_ADD  = 5'b00000;
    localparam [4:0] AMO_SWAP = 5'b00001;
    localparam [4:0] AMO_XOR  = 5'b00100;
    localparam [4:0] AMO_OR   = 5'b01000;
    localparam [4:0] AMO_AND  = 5'b01100;

    reg        tb_d_amo;
    reg [4:0]  tb_amo_op;
    reg [31:0] tb_amo_rs2;
    reg [31:0] amo_read_q;
    integer    amo_capture_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) amo_read_q <= 32'h0;
        else if (uut.cpu_data_amo_capture) amo_read_q <= uut.cpu_data_rdata;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) amo_capture_cnt <= 0;
        else if (uut.cpu_data_amo_capture) amo_capture_cnt <= amo_capture_cnt + 1;
    end

    reg [31:0] amo_alu;
    always @(*) begin
        case (tb_amo_op)
            AMO_ADD : amo_alu = amo_read_q + tb_amo_rs2;
            AMO_SWAP: amo_alu = tb_amo_rs2;
            AMO_XOR : amo_alu = amo_read_q ^ tb_amo_rs2;
            AMO_OR  : amo_alu = amo_read_q | tb_amo_rs2;
            AMO_AND : amo_alu = amo_read_q & tb_amo_rs2;
            default : amo_alu = tb_amo_rs2;
        endcase
    end

    wire [31:0] tb_d_wdata_eff = tb_d_amo ? amo_alu : tb_d_wdata;

    initial begin
        tb_if_req = 1'b0;  tb_if_addr = 32'h0;
        tb_d_rd   = 1'b0;  tb_d_wr    = 1'b0;
        tb_d_fence = 1'b0;
        tb_d_addr = 32'h0; tb_d_wdata = 32'h0;
        tb_d_size = SZ_W;  tb_d_uns   = 1'b0;
        tb_d_amo  = 1'b0;  tb_amo_op  = AMO_ADD; tb_amo_rs2 = 32'h0;

        force uut.clk_en_cpu        = 1'b1;
        force uut.clk_en_dbg        = 1'b1;
        force uut.cpu_inst_req      = tb_if_req;
        force uut.cpu_inst_addr     = tb_if_addr;
        force uut.cpu_data_rd_req   = tb_d_rd;
        force uut.cpu_data_wr_req   = tb_d_wr;
        force uut.cpu_data_fence    = tb_d_fence;
        force uut.cpu_data_addr     = tb_d_addr;
        force uut.cpu_data_wdata    = tb_d_wdata_eff;
        force uut.cpu_data_amo_req  = tb_d_amo;
        force uut.cpu_data_size     = tb_d_size;
        force uut.cpu_data_unsigned = tb_d_uns;
    end

    localparam integer HANDSHAKE_TIMEOUT = 4000;   // chu ky clk_cpu

    // So chu ky cua giao dich core-side gan nhat.  Phan biet cache hit (2 chu
    // ky) voi cache miss (mot vong AXI qua interconnect) - hai truong hop tra ve
    // cung gia tri nen khong the phan biet bang du lieu.
    integer last_xact_cycles;
    integer dc_set;

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
            @(negedge clk);
            tb_d_addr  = addr;
            tb_d_wdata = wdata;
            tb_d_size  = size;
            tb_d_uns   = uns;
            tb_d_wr    = is_write;
            tb_d_rd    = ~is_write;

            n = 0;
            while ((uut.cpu_data_hit !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk);
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
            @(posedge clk);
            #0.2;
            tb_d_wr = 1'b0;
            tb_d_rd = 1'b0;
        end
    endtask

    reg [31:0] junk;

    // -------------------------------------------------------------------------
    // P2c - `fence`.  Cung giao thuc voi cpu_xact (`stall` cao suot, `hit` la
    // xung ket thuc), chi khac la khong co dia chi va khong co du lieu.
    //
    // `last_xact_cycles` cho biet fence da cho BAO NHIEU chu ky - do la cach duy
    // nhat de phan biet "fence that su xa buffer" voi "fence bi bo qua nhu NOP":
    // ca hai deu tra ve dung du lieu neu khong co master nao khac xen vao.
    // -------------------------------------------------------------------------
    task automatic fence_();
        integer n;
        begin
            @(negedge clk);
            tb_d_fence = 1'b1;

            n = 0;
            while ((uut.cpu_data_hit !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk);
                #0.2;
                n = n + 1;
            end

            if (n >= HANDSHAKE_TIMEOUT) begin
                timeout_hits = timeout_hits + 1;
                fail_count   = fail_count + 1;
                $display("[FAIL] TIMEOUT fence sau %0d chu ky", n);
            end
            last_xact_cycles = n;

            @(posedge clk);
            #0.2;
            tb_d_fence = 1'b0;
        end
    endtask

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

    // Mot lenh AMO.W hoan chinh.  `old_val` la gia tri D-cache tra ve o chu ky
    // capture - dung cai se di vao `rd` cua lenh nguyen tu.
    task automatic amo_w(input  [4:0]  op,
                         input  [31:0] addr,
                         input  [31:0] rs2,
                         output [31:0] old_val);
        integer n;
        begin
            @(negedge clk);
            tb_amo_op  = op;
            tb_amo_rs2 = rs2;
            tb_d_addr  = addr;
            tb_d_size  = SZ_W;
            tb_d_uns   = 1'b0;
            tb_d_rd    = 1'b1;
            tb_d_wr    = 1'b1;
            tb_d_amo   = 1'b1;

            n = 0;
            while ((uut.cpu_data_hit !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk);
                #0.2;
                n = n + 1;
            end

            if (n >= HANDSHAKE_TIMEOUT) begin
                timeout_hits = timeout_hits + 1;
                fail_count   = fail_count + 1;
                $display("[FAIL] TIMEOUT amo addr=%08h sau %0d chu ky", addr, n);
                old_val = 32'hDEAD_DEAD;
            end else begin
                old_val = amo_read_q;
            end
            last_xact_cycles = n;

            // Giu them mot canh len y het cpu_xact - xem ghi chu o do.
            @(posedge clk);
            #0.2;
            tb_d_rd  = 1'b0;
            tb_d_wr  = 1'b0;
            tb_d_amo = 1'b0;
        end
    endtask

    // Port fetch: chi doc, dung cho ITCM.
    task automatic ifetch(input [31:0] addr, output [31:0] data);
        integer n;
        begin
            @(negedge clk);
            tb_if_addr = addr;
            tb_if_req  = 1'b1;
            n = 0;
            while ((uut.cpu_inst_hit !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk);
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
            @(posedge clk);
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
            @(negedge clk);
            tb_sba_op    = op;
            tb_sba_size  = size;
            tb_sba_addr  = addr;
            tb_sba_wdata = wdata;
            tb_sba_req   = 1'b1;

            n = 0;
            while ((uut.sba_ack !== 1'b1) && (n < HANDSHAKE_TIMEOUT)) begin
                @(posedge clk);
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
            @(negedge clk);
            tb_sba_req = 1'b0;
            repeat (2) @(posedge clk);
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
    reg [31:0] amo_old;
    integer    cap_snap;
    integer    t10f_n;
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
        repeat (40) @(posedge clk);
        rst_n  = 1'b1;
        trst_n = 1'b1;
        // Bo keo dai reset trong top_soc giu he thong them 64 chu ky clk (+2 cua
        // reset_sync) sau khi rst_n nha - phai cho het truoc giao dich dau tien.
        repeat (100) @(posedge clk);

        $display("");
        $display("=== tb_mem_paths: cac duong bo nho mo o Phase 0 ===");
        $display("");

        // ------------------------------------------------------------------
        // T0 - decode: nua nao cua system RAM la uncached
        // ------------------------------------------------------------------
        $display("--- T0: decode SOC_IS_UNCACHED ---");
        @(negedge clk);
        tb_d_addr = ADDR_RAM_LO; #0.2;
        chk32("RAM lo  0x20000000 -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h0);
        @(negedge clk);
        tb_d_addr = ADDR_RAM_HI; #0.2;
        chk32("RAM hi  0x20020000 -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h1);
        @(negedge clk);
        tb_d_addr = ADDR_RAM_HI + 32'h1_FFFC; #0.2;
        chk32("RAM hi  0x2003FFFC -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h1);
        @(negedge clk);
        tb_d_addr = ADDR_RAM_LO + 32'h1_FFFC; #0.2;
        chk32("RAM lo  0x2001FFFC -> dc_uncache_en", {31'b0, uut.dc_uncache_en}, 32'h0);
        @(negedge clk);
        tb_d_addr = ADDR_DTCM; #0.2;
        chk32("DTCM    0x00024000 -> ls_sel_dtcm", {31'b0, uut.ls_sel_dtcm}, 32'h1);
        @(negedge clk);
        tb_d_addr = ADDR_ITCM; #0.2;
        chk32("ITCM    0x00020000 -> ls_sel_itcm", {31'b0, uut.ls_sel_itcm}, 32'h1);
        @(negedge clk);
        tb_d_addr = 32'h0;

        // ------------------------------------------------------------------
        // TP - D-cache co THAT SU hit khong?
        //
        //   Doc lan dau  = miss, phai di tron mot vong AXI qua interconnect.
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

        // Set index duoc TINH tu tham so cua chinh DUT, khong viet cung so 0.
        // Truoc day D-cache la 4-way / 256 set nen 0x2000_7000 roi vao set 0;
        // khi ha xuong 2-way so set gap doi va cung dia chi do roi vao set 256.
        // Bai test khong duoc doi hinh hoc cache la mot hang so.
        dc_set = ((ADDR_RAM_LO + 32'h7000) >> uut.u_dcache.OFFSET_W) &
                 ((1 << uut.u_dcache.INDEX_W) - 1);
        if (uut.u_dcache.valid_arr[dc_set] != 0) begin
            pass_count = pass_count + 1;
            $display("[PASS] D-cache da allocate line: valid_arr[set %0d] = %b",
                     dc_set, uut.u_dcache.valid_arr[dc_set]);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] D-cache khong allocate line nao: valid_arr[set %0d] = %b",
                     dc_set, uut.u_dcache.valid_arr[dc_set]);
        end

        // ------------------------------------------------------------------
        // TS - Store buffer (MEMORY_FIX_PLAN.md Phase 1 / P2).
        //
        // Ba thu phai dung cung luc, va chi do do tre moi thay duoc hai cai dau:
        //   1. store cacheable retire nhanh nhu mot load hit;
        //   2. chuoi store DAI HON do sau FIFO van khong nuot entry nao;
        //   3. du lieu that su toi RAM, khong chi nam trong mang cua cache.
        //
        // (3) duoc bao dam boi chinh chinh sach no-write-allocate: cac dia chi
        // duoi day chua tung duoc nap, nen store la MISS va khong dung vao mang.
        // Doc lai la mot read miss -> gia tri phai di tu RAM ve.
        // ------------------------------------------------------------------
        $display("");
        $display("--- TS: store buffer ---");

        // Xa buffer truoc khi do, de phep do khong dinh du am cua test truoc.
        lw(ADDR_SYSCON + 32'h000, junk);

        sw(ADDR_RAM_LO + 32'h7100, 32'hAAAA_0001);
        if (last_xact_cycles <= 3) begin
            pass_count = pass_count + 1;
            $display("[PASS] store cacheable retire trong %0d chu ky", last_xact_cycles);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] store cacheable ton %0d chu ky - store buffer khong nhan",
                     last_xact_cycles);
        end

        // Chuoi 8 store lien tiep vao FIFO sau 4: phai tran, stall va drain.
        for (i = 0; i < 8; i = i + 1)
            sw(ADDR_RAM_LO + 32'h7200 + i*4, 32'hB000_0000 + i);

        for (i = 0; i < 8; i = i + 1) begin
            lw(ADDR_RAM_LO + 32'h7200 + i*4, d);
            chk32("TS chuoi store vuot do sau FIFO", d, 32'hB000_0000 + i);
        end

        // Thu tu giua hai store cung dia chi: gia tri cuoi phai thang.
        sw(ADDR_RAM_LO + 32'h7300, 32'hC0DE_0001);
        sw(ADDR_RAM_LO + 32'h7300, 32'hC0DE_0002);
        lw(ADDR_RAM_LO + 32'h7300, d);
        chk32("TS hai store cung dia chi giu dung thu tu", d, 32'hC0DE_0002);

        // ------------------------------------------------------------------
        // TF - `fence` xa store buffer (P2c).
        //
        // T9 chung minh fence dung TRONG MOT KICH BAN.  Nhom nay do thang tinh
        // chat cua no, vi mot fence bi noi nham thanh NOP van lam T9 PASS: cac
        // buoc JTAG cua sba_xact tinh co du dai de buffer tu xa.
        //
        // Hai chieu phai kiem ca hai, khong duoc thieu chieu nao:
        //   - buffer CO du lieu  -> fence phai cho, va sau do buffer phai rong;
        //   - buffer DA rong     -> fence khong duoc cho, neu khong thi moi
        //                           `fence` trong vong lap deu tra tien vo ich.
        // ------------------------------------------------------------------
        $display("");
        $display("--- TF: fence xa store buffer (P2c) ---");

        // Do sau FIFO la 4 nen 4 store lien tiep chac chan de lai entry cho xa.
        for (i = 0; i < 4; i = i + 1)
            sw(ADDR_RAM_LO + 32'h7400 + i*4, 32'hFE0C_0000 + i);

        fence_();
        if (uut.u_dcache.sb_drained === 1'b1) begin
            pass_count = pass_count + 1;
            $display("[PASS] sau fence, store buffer rong (cho %0d chu ky)",
                     last_xact_cycles);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] sau fence, store buffer VAN chua xa: sb_state=%0d wptr=%0d rptr=%0d",
                     uut.u_dcache.sb_state, uut.u_dcache.sb_wptr, uut.u_dcache.sb_rptr);
        end

        // Va no phai THUC SU cho.  Mot entry duy nhat cung mat tron mot vong AXI
        // qua interconnect - hang chuc chu ky - nen nguong 3 phan biet dut khoat
        // "co xa" voi "tra ve ngay nhu NOP".
        if (last_xact_cycles > 3) begin
            pass_count = pass_count + 1;
            $display("[PASS] fence cho that su (%0d chu ky), khong tra ve ngay",
                     last_xact_cycles);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] fence tra ve sau %0d chu ky voi buffer con day - chay nhu NOP",
                     last_xact_cycles);
        end

        // Fence tren buffer da rong: khong duoc cho.  Nguong 3 chu ky la do tre
        // chot cua chinh giao thuc handshake, khong phai do tre xa.
        fence_();
        if (last_xact_cycles <= 3) begin
            pass_count = pass_count + 1;
            $display("[PASS] fence tren buffer rong khong cho (%0d chu ky)",
                     last_xact_cycles);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] fence tren buffer rong ton %0d chu ky", last_xact_cycles);
        end

        // Du lieu cua chuoi store tren van phai dung sau khi fence xa.
        for (i = 0; i < 4; i = i + 1) begin
            lw(ADDR_RAM_LO + 32'h7400 + i*4, d);
            chk32("TF du lieu con nguyen sau fence", d, 32'hFE0C_0000 + i);
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
        @(negedge clk);
        tb_if_addr = ADDR_ITCM + 32'h0004;
        tb_if_req  = 1'b1;
        tb_d_addr  = ADDR_ITCM + 32'h0000;
        tb_d_size  = SZ_W;
        tb_d_uns   = 1'b0;
        tb_d_rd    = 1'b1;

        n_fetch_wait = 0;
        while ((uut.cpu_inst_hit !== 1'b1) && (n_fetch_wait < 200)) begin
            @(posedge clk);
            #0.2;
            n_fetch_wait = n_fetch_wait + 1;
        end
        d = uut.cpu_inst_data;
        @(negedge clk);
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

        // P2c - FENCE THAT.  Store tren la CACHEABLE nen no chi di vao store
        // buffer roi retire ngay; chua chac da toi RAM khi debugger ghi de len
        // cung line ngay sau do.
        //
        // Truoc P2c cho nay phai gia lam fence bang mot lenh doc uncached bat ky
        // (`lw(ADDR_SYSCON + 0)`), dua vao quy tac 2 trong dcache.v: moi truy cap
        // uncached deu ep xa buffer truoc.  Cach do chay, nhung no la mot HIEU UNG
        // PHU - khong co gi trong RTL noi rang no phai tiep tuc dung, va phan mem
        // that thi khong the viet "doc bua mot thanh ghi APB" vao driver.
        //
        // Rang buoc nay khong dung cho DMA: thanh ghi DMA la MMIO, nen chinh
        // hanh dong khoi dong DMA da xa store buffer roi.  No chi dung cho
        // debugger, master duy nhat vao thang AXI ma khong qua CPU.
        fence_();
        $display("[INFO] fence cho %0d chu ky de xa store buffer", last_xact_cycles);

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
        // T10 - LENH NGUYEN TU (AMO).  Dong lo hong verification cua R1a/R1b/
        //       R11 ghi trong GENUS_REVIEW_2026-09-09.md §14: truoc bai nay
        //       KHONG testbench nao tren may thuc thi mot AMO, nen R1b va R11
        //       moi chi duoc kiem bang doc code.
        // ------------------------------------------------------------------
        $display("");
        $display("--- T10: lenh nguyen tu (R1b bat tay 2 chu ky, R11 AMO truot) ---");

        // T10a - AMO tren line DA nam trong cache.  Kiem duong R1b.
        sw(ADDR_RAM_LO + 32'h6000, 32'h0000_0010);
        lw(ADDR_RAM_LO + 32'h6000, d);      // nap line vao D-cache
        chk32("T10a chuan bi: gia tri ban dau", d, 32'h0000_0010);

        cap_snap = amo_capture_cnt;
        amo_w(AMO_ADD, ADDR_RAM_LO + 32'h6000, 32'h0000_0005, amo_old);
        chk32("T10a amoadd.w HIT tra ve gia tri CU", amo_old, 32'h0000_0010);
        if (amo_capture_cnt == cap_snap + 1) begin
            pass_count = pass_count + 1;
            $display("[PASS] T10a R1b: dcache_amo_capture xung dung 1 lan");
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] T10a R1b: dcache_amo_capture xung %0d lan, mong doi 1",
                     amo_capture_cnt - cap_snap);
        end
        lw(ADDR_RAM_LO + 32'h6000, d);
        chk32("T10a amoadd.w HIT da ghi 0x10+0x05", d, 32'h0000_0015);

        // T10b - AMO TRUOT cache.  Day chinh la nhanh R11.
        //   `sw` la write-through KHONG write-allocate nen dia chi nay chua
        //   bao gio duoc nap vao D-cache.  Truoc khi sua R11, AMO nay retire
        //   ma khong he ghi: `amo_old` van dung nen phan mem khong thay gi,
        //   chi co RAM la khong bao gio duoc cap nhat.
        sw(ADDR_RAM_LO + 32'h6800, 32'h1000_0000);
        cap_snap = amo_capture_cnt;
        amo_w(AMO_ADD, ADDR_RAM_LO + 32'h6800, 32'h0000_0007, amo_old);
        $display("[INFO] T10b AMO truot mat %0d chu ky (HIT o T10a: xem tren)",
                 last_xact_cycles);
        chk32("T10b amoadd.w MISS tra ve gia tri CU", amo_old, 32'h1000_0000);
        if (amo_capture_cnt == cap_snap + 1) begin
            pass_count = pass_count + 1;
            $display("[PASS] T10b R11: vong tra cuu thu hai co chay (1 capture)");
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] T10b R11: capture %0d lan, mong doi 1 - AMO truot khong ghi",
                     amo_capture_cnt - cap_snap);
        end

        // Bang chung manh nhat cho R11: doc lai bang SBA cua debug module, di
        // thang qua AXI nen KHONG dung mang cache.  Phan ghi cua AMO nam trong
        // store buffer nen phai xa het truoc.  P2c - dung `fence` that thay cho
        // ban cu `repeat (200) @(posedge clk)`: con so 200 la doan, con
        // fence cho DUNG toi khi `sb_drained` (TF da chung minh no khong la NOP).
        fence_();
        sba_xact(2'd1, 2'd2, ADDR_RAM_LO + 32'h6800, 32'h0, d, sba_resp);
        chk32("T10b R11: RAM THAT da duoc cap nhat (doc bang SBA)", d, 32'h1000_0007);

        lw(ADDR_RAM_LO + 32'h6800, d);
        chk32("T10b duong cache cung thay gia tri moi", d, 32'h1000_0007);

        // T10c - amoswap.w tren line da cache.
        amo_w(AMO_SWAP, ADDR_RAM_LO + 32'h6000, 32'hAABB_CCDD, amo_old);
        chk32("T10c amoswap.w tra ve gia tri CU", amo_old, 32'h0000_0015);
        lw(ADDR_RAM_LO + 32'h6000, d);
        chk32("T10c amoswap.w da ghi toan tu moi", d, 32'hAABB_CCDD);

        // T10d - amoand/amoor tren line da cache.
        amo_w(AMO_AND, ADDR_RAM_LO + 32'h6000, 32'h00FF_FF00, amo_old);
        lw(ADDR_RAM_LO + 32'h6000, d);
        chk32("T10d amoand.w", d, 32'h00BB_CC00);
        amo_w(AMO_OR, ADDR_RAM_LO + 32'h6000, 32'h1100_0011, amo_old);
        lw(ADDR_RAM_LO + 32'h6000, d);
        chk32("T10d amoor.w", d, 32'h11BB_CC11);

        // T10f - AMO HIT dung luc store buffer DAY (2026-09-13).
        //   Nhanh doc cua LOOKUP nha stall khi HIT ma truoc day khong nhin
        //   sb_full, con sb_push thi doi !sb_full -> AMO retire, rd dung, phan
        //   GHI mat.  Chan kenh AW de 4 lenh sw lap day buffer, chay AMO, roi
        //   30 chu ky sau moi tha AW.  AMO dung phai CHO toi luc do.
        $display("");
        $display("--- T10f: AMO khi store buffer day ---");
        // Xa het buffer truoc (AMO cua T10c/T10d co the con trong do), roi moi
        // chan AW va ghi cho toi khi day - khong gia dinh do sau buffer.
        fence_();
        // Chan CA HAI phia cua mot handshake (net lien tuc, release sach):
        // chi chan awready phia cache thi interconnect van thay awvalid va
        // nhan AW ma cache khong biet.
        force uut.m1_awvalid = 1'b0;
        force uut.dc_awready = 1'b0;
        t10f_n = 0;
        while (uut.u_dcache.sb_full !== 1'b1 && t10f_n < 8) begin
            sw(ADDR_RAM_LO + 32'h7000 + 4 * t10f_n, 32'hF000_0001 + t10f_n);
            t10f_n = t10f_n + 1;
        end
        if (uut.u_dcache.sb_full === 1'b1) begin
            pass_count = pass_count + 1;
            $display("[PASS] T10f chuan bi: store buffer day sau %0d sw (AW bi chan)", t10f_n);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] T10f chuan bi: sb_full = %b - test khong tao duoc dieu kien", uut.u_dcache.sb_full);
        end
        fork
            amo_w(AMO_ADD, ADDR_RAM_LO + 32'h6000, 32'h0000_0003, amo_old);
            begin
                repeat (30) @(posedge clk);
                // Tha o canh XUONG: tha ngay canh len thi cache va interconnect
                // lay mau hai phia handshake o hai thoi diem khac nhau (race).
                @(negedge clk);
                release uut.m1_awvalid;
                release uut.dc_awready;
            end
        join
        chk32("T10f amoadd.w tra ve gia tri CU", amo_old, 32'h11BB_CC11);
        if (last_xact_cycles >= 30) begin
            pass_count = pass_count + 1;
            $display("[PASS] T10f AMO cho buffer co cho (%0d chu ky)", last_xact_cycles);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] T10f AMO nha stall sau %0d chu ky trong luc buffer day", last_xact_cycles);
        end
        lw(ADDR_RAM_LO + 32'h6000, d);
        chk32("T10f duong cache thay 0x11BBCC11 + 3", d, 32'h11BB_CC14);
        fence_();
        sba_xact(2'd1, 2'd2, ADDR_RAM_LO + 32'h6000, 32'h0, d, sba_resp);
        chk32("T10f RAM THAT (SBA) thay 0x11BBCC11 + 3", d, 32'h11BB_CC14);
        sba_xact(2'd1, 2'd2, ADDR_RAM_LO + 32'h7000 + 4 * (t10f_n - 1), 32'h0, d, sba_resp);
        chk32("T10f sw cuoi cung van toi RAM", d, 32'hF000_0000 + t10f_n);

        // T10e - QUAN SAT (khong tinh diem): AMO vao vung UNCACHED.
        //   `dcache_amo_capture` doi !uncache_en, va nhanh sua R11 o DONE cung
        //   doi !uncache_en.  O IDLE, mot truy cap uncached co ca read lan
        //   write se di AR_REQ (uu tien doc).  In ra de bao cao, khong sua.
        $display("");
        $display("--- T10e: QUAN SAT - AMO vao vung uncached (DMAPOOL) ---");
        sw(ADDR_RAM_HI + 32'h0A00, 32'h0000_0021);
        cap_snap = amo_capture_cnt;
        amo_w(AMO_ADD, ADDR_RAM_HI + 32'h0A00, 32'h0000_0002, amo_old);
        lw(ADDR_RAM_HI + 32'h0A00, d);
        $display("[INFO] T10e capture = %0d lan, RAM sau amoadd = %08h (ban dau 0x21, rs2 = 0x2)",
                 amo_capture_cnt - cap_snap, d);
        if (d === 32'h0000_0023)
            $display("[INFO] T10e AMO uncached CO ghi");
        else
            $display("[INFO] T10e AMO uncached KHONG ghi - AMO tren vung uncached bi bo am tham");

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
