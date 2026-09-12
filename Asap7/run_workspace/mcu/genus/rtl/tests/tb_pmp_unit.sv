`timescale 1ns / 1ps

// =============================================================================
// tb_pmp_unit.sv - doi chieu pmp_unit voi mo hinh tham chieu (run_soc_sim.sh pmp).
//
// 2026-09-13 pmp_unit doi hai thu ma CPU test (suite irq) KHONG phu kin duoc:
//   * `aw >= pmpaddr` -> cay tien to ge32 (5 tang)
//   * mat na NAPOT dc[b] = &pmpaddr[b-1:0] -> thanh ghi dc_q tinh luc ghi CSR
// Suite irq chi dung TOR va NA4 voi vai dia chi. O day ghi CSR ngau nhien qua
// DUNG cong ghi cua module (co khoa, WARL), roi so d_fault/i_fault voi mo hinh
// viet theo dac ta bang toan tu `>=` va chuoi AND nguyen ban, doc thang
// cfg_q/addr_q cua DUT. Neu dc_q lech addr_q, hoac ge32 sai o bat ky bit nao,
// ket qua se khac.
//
// Dia chi thu duoc chon lech +-8 byte quanh can cua mot entry de trung bien
// TOR/NAPOT, xen voi dia chi ngau nhien hoan toan. Reset lai sau moi dot vi
// entry da khoa thi khong ghi lai duoc.
// =============================================================================
module tb_pmp_unit;

    localparam integer N = 8;
    localparam integer ROUNDS = 400;
    localparam integer CHECKS_PER_ROUND = 400;

    reg         clk = 0;
    reg         reset_n = 0;
    reg         csr_we = 0;
    reg  [11:0] csr_waddr = 0;
    reg  [31:0] csr_wdata = 0;
    reg  [31:0] d_addr = 0, i_addr = 0;
    reg         d_read = 0, d_write = 0;
    wire        d_fault, i_fault;
    wire [31:0] rd_a, rd_b, wr_res;

    always #5 clk = ~clk;

    pmp_unit #(.PMP_ENTRIES(N)) dut (
        .clk(clk), .reset_n(reset_n),
        .csr_we(csr_we), .csr_waddr(csr_waddr), .csr_wdata(csr_wdata),
        .rd_addr_a(12'h3A0), .rd_data_a(rd_a),
        .rd_addr_b(12'h3B0), .rd_data_b(rd_b),
        .wr_result(wr_res),
        .d_addr(d_addr), .d_read(d_read), .d_write(d_write), .d_fault(d_fault),
        .i_addr(i_addr), .i_fault(i_fault)
    );

    // ---- mo hinh tham chieu (dac ta, khong toi uu) --------------------------
    function automatic [3:0] ref_perm(input [31:0] a);
        reg [31:0] aw, pa, lo, dc;
        integer e, b;
        reg hit, found;
        begin
            aw = {2'b00, a[31:2]};
            ref_perm = 4'b0111;
            found = 0;
            for (e = 0; e < N && !found; e = e + 1) begin
                pa = dut.addr_q[e];
                lo = (e == 0) ? 32'd0 : dut.addr_q[e-1];
                dc[0] = 1'b1;
                for (b = 1; b < 32; b = b + 1) dc[b] = dc[b-1] & pa[b-1];
                case (dut.cfg_q[e][4:3])
                    2'd1: hit = (aw >= lo) && (aw < pa);
                    2'd2: hit = (aw == pa);
                    2'd3: hit = ((aw ^ pa) & ~dc) == 32'd0;
                    default: hit = 1'b0;
                endcase
                if (hit) begin
                    found = 1;
                    ref_perm = dut.cfg_q[e][7] ? {1'b1, dut.cfg_q[e][2:0]} : 4'b0111;
                end
            end
        end
    endfunction

    integer pass_count = 0, fail_count = 0;
    integer r, c, k, dc_bad;
    reg [3:0]  pd, pi;
    reg        exp_d, exp_i;
    reg [31:0] base, v;
    integer    mode_hist [0:3];

    task automatic csr_write(input [11:0] a, input [31:0] d);
        begin
            @(negedge clk);
            csr_we = 1; csr_waddr = a; csr_wdata = d;
            @(negedge clk);
            csr_we = 0;
        end
    endtask

    // Gia tri pmpaddr kieu NAPOT: base ngau nhien voi k bit 1 cuoi va bit k = 0.
    function automatic [31:0] rand_pmpaddr(input integer kind);
        reg [31:0] x;
        integer kk;
        begin
            x = $random;
            x[31:30] = 2'b00;                  // dia chi vat ly 32 bit
            if (kind == 0) begin
                kk = {$random} % 28;
                x = (x & ~((32'd1 << (kk + 1)) - 1)) | ((32'd1 << kk) - 1);
            end
            rand_pmpaddr = x;
        end
    endfunction

    initial begin
        for (k = 0; k < 4; k = k + 1) mode_hist[k] = 0;
        dc_bad = 0;
        $display("=== tb_pmp_unit: ge32 + dc_q so voi mo hinh dac ta ===");

        for (r = 0; r < ROUNDS; r = r + 1) begin
            reset_n = 0;
            repeat (2) @(negedge clk);
            reset_n = 1;

            // pmpaddr tang dan mot phan (TOR co vung khac rong), xen NAPOT.
            base = 0;
            for (k = 0; k < N; k = k + 1) begin
                if ({$random} % 2) begin
                    base = base + ({$random} % 32'h0000_4000);
                    v = base;
                end else begin
                    v = rand_pmpaddr({$random} % 2);
                end
                csr_write(12'h3B0 + k, v);
            end
            // Ghi mot vai lan THEM de kiem dc_q theo kip addr_q o lan ghi sau.
            for (k = 0; k < 3; k = k + 1)
                csr_write(12'h3B0 + ({$random} % N), rand_pmpaddr({$random} % 2));
            // cfg: A ngau nhien, L voi xac suat cao, RWX ngau nhien. pmpcfg0 ghi
            // SAU cung de entry khoa khong chan cac lan ghi pmpaddr o tren.
            csr_write(12'h3A1, $random & 32'h9F9F_9F9F);
            csr_write(12'h3A0, $random & 32'h9F9F_9F9F);
            // Ghi pmpaddr SAU khi co the da khoa: phai bi bo qua o entry khoa.
            csr_write(12'h3B0 + ({$random} % N), $random);

            for (k = 0; k < N; k = k + 1) begin
                mode_hist[dut.cfg_q[k][4:3]] = mode_hist[dut.cfg_q[k][4:3]] + 1;
                v[0] = 1'b1;
                for (c = 1; c < 32; c = c + 1) v[c] = v[c-1] & dut.addr_q[k][c-1];
                if (v !== dut.dc_q[k]) dc_bad = dc_bad + 1;
            end

            for (c = 0; c < CHECKS_PER_ROUND; c = c + 1) begin
                @(negedge clk);
                k = {$random} % N;
                case ({$random} % 4)
                    0: d_addr = $random;
                    1: d_addr = (dut.addr_q[k] << 2) + ($signed($random) % 9);
                    2: d_addr = ((dut.addr_q[k] | ~dut.dc_q[k]) << 2) + ($signed($random) % 9);
                    default: d_addr = ((dut.addr_q[k] & dut.dc_q[k]) << 2) - ($signed($random) % 9);
                endcase
                i_addr = (c % 2) ? d_addr : $random;
                d_read = $random; d_write = $random;
                #1;
                pd = ref_perm(d_addr);
                pi = ref_perm(i_addr);
                exp_d = (d_read & ~pd[0]) | (d_write & ~pd[1]);
                exp_i = ~pi[2];
                if (d_fault === exp_d && i_fault === exp_i) begin
                    pass_count = pass_count + 1;
                end else begin
                    fail_count = fail_count + 1;
                    if (fail_count <= 10)
                        $display("[TB][FAIL] r=%0d d_addr=%08h d_fault=%b exp=%b | i_addr=%08h i_fault=%b exp=%b",
                                 r, d_addr, d_fault, exp_d, i_addr, i_fault, exp_i);
                end
            end
        end

        if (dc_bad == 0) begin
            pass_count = pass_count + 1;
            $display("[TB][PASS] dc_q khop &pmpaddr[b-1:0] o moi entry, moi dot");
        end else begin
            fail_count = fail_count + 1;
            $display("[TB][FAIL] dc_q lech addr_q %0d lan", dc_bad);
        end
        $display("[TB][INFO] che do entry: OFF %0d  TOR %0d  NA4 %0d  NAPOT %0d",
                 mode_hist[0], mode_hist[1], mode_hist[2], mode_hist[3]);
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
