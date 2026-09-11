`timescale 1ns / 1ps

// =============================================================================
// tb_irq_pmp.sv - muc 6 (PMP) va 7 (CLIC) cua review 2026-09-11, bang CPU THAT.
//
// run_soc_sim.sh irq bake tests/irq_pmp.mem (sinh boi gen_irq_pmp_mem.py) vao
// boot ROM. Chuong trinh bao pha qua t2 (x7); testbench doc thanh ghi kien truc
// NGAY chu ky t2 doi (moi lenh truoc do da ghi xong, lenh sau chua ghi de).
//
//   t2 = 1  PMP        load/store/fetch bi chan dung mcause/mtval, entry khoa
//                      bat bien ke ca doc lai NGAY sau lenh ghi, WARL, RO 0
//   t2 = 2  CLIC       vector theo nguon, mcause Smclic, mintstatus, tu xoa ip
//   t2 = 3  long nhau  14(muc1) bi 15(muc7) preempt; 13(muc1) doi toi mret
//   t2 = 4  mintthresh chan ngat muc <= nguong
//   t2 = 5  HOI QUY    testbench bat ngat MUC (ID 12) dung luc D-cache stall
//                      voi load o MEM. Truoc ban sua: CSR bi ghi (MIE <- 0)
//                      nhung PC khong doi huong -> handler khong chay, MIE ket 0.
//   t2 = 7  WFI        core ngu that (clk_en_cpu = 0), ngat ID 11 danh thuc
// =============================================================================
module tb_irq_pmp;

    localparam [31:0] FUNC_NOX  = 32'h0001_0284;    // xem dong 3 cua irq_pmp.mem
    localparam integer PHASE_TIMEOUT_NS = 400_000;

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
    reg clk, rtc_clk;
    reg rst_n;
    initial begin clk     = 0; forever #2.0   clk     = ~clk;     end // 250 MHz
    initial begin rtc_clk = 0; forever #15258 rtc_clk = ~rtc_clk; end

    // ---- chan ----------------------------------------------------------------
    reg  tck, trst_n, tms, tdi;
    wire tdo;
    reg  [31:0] pad_in;
    wire [31:0] pad_out, pad_oe;
    wire flash_sck, flash_cs_n;
    wire [3:0]  flash_io;
    wire sdram_clk, sdram_cke, sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n;
    wire [1:0]  sdram_ba, sdram_dqm;
    wire [12:0] sdram_addr;
    wire [15:0] sdram_dq;
    wire [3:0]  dut_flash_io_o, dut_flash_io_oe;
    wire [15:0] dut_sdram_dq_o;
    wire        dut_sdram_dq_oe;

    assign flash_io[0] = dut_flash_io_oe[0] ? dut_flash_io_o[0] : 1'bz;
    assign flash_io[1] = dut_flash_io_oe[1] ? dut_flash_io_o[1] : 1'bz;
    assign flash_io[2] = dut_flash_io_oe[2] ? dut_flash_io_o[2] : 1'bz;
    assign flash_io[3] = dut_flash_io_oe[3] ? dut_flash_io_o[3] : 1'bz;
    assign sdram_dq    = dut_sdram_dq_oe    ? dut_sdram_dq_o    : 16'hzzzz;

    top_soc uut (
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

    // ---- thanh ghi kien truc -------------------------------------------------
    function automatic [31:0] X(input integer n);
        X = uut.u_core.RF.rf_main[n];
    endfunction
    wire [31:0] reg_t2 = uut.u_core.RF.rf_main[7];

    // ---- dem ack cua CLIC theo ID -------------------------------------------
    integer ack_cnt [0:31];
    integer k;
    initial for (k = 0; k < 32; k = k + 1) ack_cnt[k] = 0;
    always @(negedge clk)
        if (rst_n && uut.clic_ack)
            ack_cnt[uut.clic_ack_id] = ack_cnt[uut.clic_ack_id] + 1;

    // ---- so lan forwarding CSR PMP THUC SU xay ra (P6 chi co nghia khi >= 1) --
    integer pmp_fwd_cnt = 0;
    always @(negedge clk)
        if (rst_n && uut.u_core.ex_mem_csr_we && uut.u_core.id_ex_valid &&
            uut.u_core.id_ex_csr_we &&
            (uut.u_core.ex_mem_csr_addr == uut.u_core.id_ex_csr_addr) &&
            (uut.u_core.id_ex_csr_addr[11:4] == 8'h3A ||
             uut.u_core.id_ex_csr_addr[11:4] == 8'h3B) &&
            !uut.u_core.dcache_stall)
            pmp_fwd_cnt = pmp_fwd_cnt + 1;

    task automatic wait_t2(input [31:0] v);
        integer waited;
        begin
            waited = 0;
            while (reg_t2 !== v && waited < PHASE_TIMEOUT_NS) begin
                @(negedge clk);
                waited = waited + 4;
            end
            if (reg_t2 !== v) begin
                fail_count = fail_count + 1;
                $display("[TB][FAIL] khong toi pha t2=%0d sau %0d ns (t2=%0d pc=%08h)",
                         v, PHASE_TIMEOUT_NS, reg_t2, uut.u_core.pc_reg);
                $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
                $display("RESULT: FAIL");
                $finish;
            end
        end
    endtask

    reg [31:0] exp_sum;
    reg        saw_stall_force;
    reg        saw_sleep;
    integer    waited;

    initial begin
        pad_in = 32'h0000_0002;       // PA1 (UART0_RX) nghi muc 1
        tck = 0; trst_n = 0; tms = 0; tdi = 0;
        rst_n = 1'b0;
        repeat (100) @(posedge clk);
        rst_n  = 1'b1;
        trst_n = 1'b1;

        $display("");
        $display("=== tb_irq_pmp: PMP (muc 6) + CLIC (muc 7) bang CPU that ===");

        // ------------------------------------------------------------ pha 1
        wait_t2(1);
        $display("[TB] --- pha 1: PMP ---");
        chk32("P1 load vung khoa R=0: mcause",            X(18), 32'd5);
        chk32("P1 load vung khoa R=0: mtval",             X(19), 32'h2002_0100);
        chk("P1 lenh load bi chan KHONG ghi rd (a0 khac bi mat)", X(10) !== 32'h1111_1111);
        chk32("P2 store vung khoa W=0: mcause",           X(20), 32'd7);
        chk32("P3 load vung TOR R=1 duoc phep",           X(11), 32'h2222_2222);
        chk32("P4 store vung TOR W=0: mcause",            X(21), 32'd7);
        chk32("P4 gia tri cu con nguyen (store bi chan truoc bus)", X(12), 32'h2222_2222);
        chk32("P5 dia chi ngoai moi entry: doc duoc",     X(13), 32'h4444_4444);
        chk32("P5 khong co trap",                          X(22), 32'd0);
        chk32("P6 pmpcfg0 khoa, doc NGAY sau csrw 0",     X(14), 32'h9190_8900);
        chk("P6 duong forwarding CSR PMP thuc su duoc dung", pmp_fwd_cnt >= 1);
        $display("[TB][INFO] so lan forwarding CSR PMP: %0d", pmp_fwd_cnt);
        chk32("P7 pmpaddr2 (entry khoa) bat bien",        X(15), 32'h0800_8040);
        chk32("P7 pmpaddr0 (can duoi TOR cua entry khoa) bat bien", X(16), 32'h0800_8080);
        chk32("P8 pmpcfg1: entry5 R=0,W=1 -> WARL 0",     X(17), 32'h0000_0010);
        chk32("P9 entry KHONG khoa: M-mode van goi duoc", X(23), 32'd0);
        chk32("P10 fetch vung khoa X=0: mcause",          X(24), 32'd1);
        chk32("P10 fetch vung khoa X=0: mtval = PC",      X(25), FUNC_NOX);
        chk32("P11 pmpaddr8 (entry >= 8) chi doc 0",      X(26), 32'd0);
        chk32("P11 pmpcfg2 chi doc 0",                    X(27), 32'd0);

        // ------------------------------------------------------------ pha 2
        wait_t2(2);
        $display("[TB] --- pha 2: CLIC vector + mcause ---");
        chk32("ID30 mcause (int|mpp=11|mpie|mpil=0|id 30)", X(18), 32'hB800_001E);
        chk32("ID30 mintstatus trong ISR (mil = 0x3F)",   X(19), 32'h3F00_0000);
        chk32("ID30 clicint[30] trong ISR: ip da tu xoa", X(20), 32'h3FC3_0100);
        chk32("ID30 handler chay dung mot lan",           X(21), 32'd1);
        chk32("mintstatus sau mret (mil = 0)",            X(22), 32'd0);
        chk("khong claim qua bus: ack CLIC cho ID30 = 1", ack_cnt[30] == 1);

        // ------------------------------------------------------------ pha 3
        wait_t2(3);
        $display("[TB] --- pha 3: long nhau ---");
        chk32("thu tu 14 -> 15 (preempt) -> ra 14 -> 13", X(27),
              (14 << 15) | (15 << 10) | (31 << 5) | 13);
        chk32("ID15 mintstatus (mil = 0xFF)",             X(25), 32'hFF00_0000);
        chk32("ID15 mcause.mpil = 0x3F (muc cua ISR 14)", X(26), 32'hB83F_000F);
        chk32("ID14 mcause",                              X(13), 32'hB800_000E);
        chk32("ID13 chay dung mot lan",                   X(11), 32'd1);

        // ------------------------------------------------------------ pha 4
        wait_t2(4);
        $display("[TB] --- pha 4: mintthresh ---");
        chk32("muc 0x3F KHONG vuot nguong 0x3F: chua vao ISR", X(12), 32'd1);
        chk32("ha nguong -> vao ISR",                     X(14), 32'd2);

        // ------------------------------------------------------------ pha 5
        wait_t2(5);
        $display("[TB] --- pha 5: ngat toi giua luc D-cache stall ---");
        saw_stall_force = 1'b0;
        waited = 0;
        while (!(uut.u_core.dcache_stall && uut.u_core.ex_mem_valid &&
                 uut.u_core.ex_mem_mem_read) && waited < 100_000) begin
            @(negedge clk);
            waited = waited + 4;
        end
        if (uut.u_core.dcache_stall) begin
            saw_stall_force = 1'b1;
            force uut.clic_irq_src[12] = 1'b1;
            $display("[TB][INFO] bat ID12 luc dcache_stall=1, load o MEM pc=%08h t=%0t",
                     uut.u_core.ex_mem_pc_in, $time);
        end
        chk("tim duoc chu ky D-cache stall voi load o MEM", saw_stall_force);
        waited = 0;
        while (ack_cnt[12] == 0 && waited < 100_000) begin
            @(negedge clk);
            waited = waited + 4;
        end
        release uut.clic_irq_src[12];
        wait_t2(6);
        exp_sum = 32'h5A5A_5A5A * 32'd300;
        chk32("handler ID12 chay DUNG MOT lan",           X(15), 32'd1);
        chk32("mstatus.MIE tro lai 1 sau mret",           X(17) & 32'h8, 32'h8);
        chk32("300 lenh load van dung (khong lap / mat)", X(16), exp_sum);
        chk("CLIC ack ID12 = 1",                          ack_cnt[12] == 1);

        // ------------------------------------------------------------ pha 6
        wait_t2(7);
        $display("[TB] --- pha 6: WFI + CLIC ---");
        saw_sleep = 1'b0;
        waited = 0;
        while (uut.clk_en_cpu !== 1'b0 && waited < 100_000) begin
            @(negedge clk);
            waited = waited + 4;
        end
        saw_sleep = (uut.clk_en_cpu === 1'b0);
        chk("core ngu that (clk_en_cpu = 0)", saw_sleep);
        repeat (50) @(negedge clk);
        force uut.clic_irq_src[11] = 1'b1;
        waited = 0;
        while (ack_cnt[11] == 0 && waited < 100_000) begin
            @(negedge clk);
            waited = waited + 4;
        end
        release uut.clic_irq_src[11];
        wait_t2(8);
        chk32("ngat CLIC danh thuc WFI, ISR 11 chay",    X(18), 32'd1);

        $display("");
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
