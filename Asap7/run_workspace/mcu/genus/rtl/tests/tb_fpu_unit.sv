`timescale 1ns / 1ps

// =============================================================================
// tb_fpu_unit.sv - fpu_unit so voi MO HINH THAM CHIEU (run_soc_sim.sh fpuv).
//
// Chi compile core/block_unit/floating_point_unit.v, khong compile ca SoC -
// giong cach tb_pmp_unit.sv lam voi pmp_unit.
//
// Vector den tu tests/fpu_vectors.mem, sinh boi gen_fpu_vectors.py bang so huu
// ti CHINH XAC (fractions.Fraction). Day la khac biet quan trong so voi
// tb_fpu_core.sv: test kia kiem vai chuc gia tri viet tay, con test nay kiem
// TUNG BIT cua ket qua va TUNG CO ngoai le tren hang nghin truong hop, bao gom
// subnormal, trieu tieu toan phan va ca 5 che do lam tron.
// =============================================================================
module tb_fpu_unit;

    localparam integer MAX_PRINT = 40;   // khong ngap man hinh khi hong nang

    reg         clk = 0;
    reg         reset_n = 0;
    reg         start = 0;
    reg  [4:0]  op = 0;
    reg  [2:0]  rm = 0;
    reg  [31:0] a = 0, b = 0, c = 0;
    wire [31:0] result;
    wire [4:0]  fflags;
    wire        fpu_stall, fpu_done;

    always #2.0 clk = ~clk;              // 250 MHz, giong SoC

    fpu_unit DUT (
        .clk(clk),
        .reset_n(reset_n),
        .stall_id_ex(1'b0),
        .fpu_start(start),
        .fpu_op(op),
        .fpu_rm(rm),
        .frm_i(3'b000),                  // khong dung DYN o day
        .operand_a(a),
        .operand_b(b),
        .operand_c(c),
        .result(result),
        .fflags(fflags),
        .fpu_stall(fpu_stall),
        .fpu_done(fpu_done)
    );

    integer pass_count = 0;
    integer fail_count = 0;
    integer printed    = 0;
    integer max_cycles = 0;

    // Dem rieng theo phep toan de biet loi tap trung o dau.
    integer fail_by_op [0:31];
    integer run_by_op  [0:31];

    reg [31:0] got_res;
    reg [4:0]  got_fl;
    integer    cyc;

    task automatic run_one(input [4:0] o, input [2:0] r,
                           input [31:0] va, input [31:0] vb, input [31:0] vc);
        begin
            @(negedge clk);
            op = o; rm = r; a = va; b = vb; c = vc;
            start = 1'b1;
            @(negedge clk);              // suon len vua roi: IDLE -> UNPACK
            cyc = 0;
            while (!fpu_done && cyc < 400) begin
                @(negedge clk);
                cyc = cyc + 1;
            end
            got_res = result;
            got_fl  = fflags;
            if (cyc > max_cycles) max_cycles = cyc;
            start = 1'b0;
            @(negedge clk);              // DONE -> IDLE (stall_id_ex = 0)
        end
    endtask

    // ---- doc file vector ---------------------------------------------------
    integer fd, code, i;
    reg [1023:0] line;
    integer v_op, v_rm, v_a, v_b, v_c, v_res, v_fl;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            fail_by_op[i] = 0;
            run_by_op[i]  = 0;
        end

        reset_n = 1'b0;
        repeat (5) @(negedge clk);
        reset_n = 1'b1;
        repeat (2) @(negedge clk);

        fd = $fopen("fpu_vectors.mem", "r");
        if (fd == 0) begin
            $display("[TB][FAIL] khong mo duoc fpu_vectors.mem");
            $display("RESULT: FAIL");
            $finish;
        end

        $display("");
        $display("=== tb_fpu_unit: fpu_unit so voi mo hinh tham chieu chinh xac ===");

        while (!$feof(fd)) begin
            code = $fgets(line, fd);
            if (code != 0) begin
                code = $sscanf(line, "%h %h %h %h %h %h %h",
                               v_op, v_rm, v_a, v_b, v_c, v_res, v_fl);
                // Dong chu thich khong khop du 7 truong -> code != 7 -> bo qua.
                if (code == 7) begin
                    run_by_op[v_op] = run_by_op[v_op] + 1;
                    run_one(v_op[4:0], v_rm[2:0], v_a, v_b, v_c);
                    if (got_res === v_res[31:0] && got_fl === v_fl[4:0]) begin
                        pass_count = pass_count + 1;
                    end else begin
                        fail_count = fail_count + 1;
                        fail_by_op[v_op] = fail_by_op[v_op] + 1;
                        if (printed < MAX_PRINT) begin
                            printed = printed + 1;
                            $display("[TB][FAIL] op=%0d rm=%0d a=%08h b=%08h c=%08h -> %08h/%02h  mong doi %08h/%02h",
                                     v_op, v_rm, v_a, v_b, v_c,
                                     got_res, got_fl, v_res[31:0], v_fl[4:0]);
                        end
                    end
                end
            end
        end
        $fclose(fd);

        if (fail_count != 0) begin
            $display("[TB] --- phan bo loi theo phep toan ---");
            for (i = 0; i < 32; i = i + 1)
                if (fail_by_op[i] != 0)
                    $display("[TB]   op %0d: %0d / %0d sai", i, fail_by_op[i], run_by_op[i]);
        end
        if (printed >= MAX_PRINT)
            $display("[TB][INFO] chi in %0d dong dau, con lai bi cat", MAX_PRINT);

        $display("[TB][INFO] chu ky dai nhat cua mot phep toan: %0d", max_cycles);
        $display("");
        $display("PASS COUNT = %0d  FAIL COUNT = %0d", pass_count, fail_count);
        $display("RESULT: %s", (fail_count == 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
