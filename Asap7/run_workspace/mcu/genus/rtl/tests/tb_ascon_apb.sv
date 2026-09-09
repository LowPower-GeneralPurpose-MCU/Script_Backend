`timescale 1ns / 1ps
// =========================================================================
// tb_ascon_apb.sv - kiem tra apb_ascon bang KAT that cua ASCON v1.2
//
// Vector duoc sinh bang mo hinh tham chieu roi doi chieu voi KAT chinh thuc
// cua NIST LWC (Ascon128 Count=1 va Ascon-Hash chuoi rong) truoc khi dung.
//
//   KEY   = 000102030405060708090a0b0c0d0e0f
//   NONCE = 101112131415161718191a1b1c1d1e1f
//   AD    = 4142434445464748 || 8000000000000000   (8 byte AD + khoi padding)
//   PT    = 0011223344556677 || 8899aabb80000000   (12 byte, khoi cuoi padded)
//   =>  C0  = ea6ba66348113df6
//       C1  = 984f4ce52c807298
//       TAG = 36969abd80f491042d4200d3700c0867
//
//   HASH cua 0011223344556677 || 8000000000000000 (thong diep 8 byte)
//       = b52f717d7e1778a28c5a390dd17c8dd9 ded78fd2c48f80e2358404f627185a63
//
// TRNG: RingOscillator la mot VONG LAP TO HOP.  Truoc day nhanh mo phong cua
// no khong co tre nen bat `enable` len la XSim treo cung (do that: xsim bi
// timeout giet, exit 124).  Nhanh mo phong gio co tre 50 ps moi tang nen chay
// duoc - nhung do la song vuong TAT DINH, chi kiem bat tay valid, KHONG phai
// kiem entropy.
// =========================================================================
module tb_ascon_apb;

    localparam CMD_AD        = 3'd0;
    localparam CMD_AD_LAST   = 3'd1;
    localparam CMD_PT        = 3'd2;
    localparam CMD_PT_LAST   = 3'd3;
    localparam CMD_HASH      = 3'd4;
    localparam CMD_HASH_LAST = 3'd5;

    reg         PCLK = 1'b0;
    reg         PRESETn = 1'b0;
    reg         PSEL = 1'b0, PENABLE = 1'b0, PWRITE = 1'b0;
    reg  [11:0] PADDR = 12'h0;
    reg  [31:0] PWDATA = 32'h0;
    wire [31:0] PRDATA;
    wire        PREADY, PSLVERR, ascon_irq, o_active;

    integer pass_cnt = 0;
    integer fail_cnt = 0;
    reg [31:0] rd;
    reg        rd_err;
    reg [31:0] trng_a, trng_b;

    always #5 PCLK = ~PCLK;   // 100 MHz

    apb_ascon dut (
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
        .PADDR(PADDR), .PWDATA(PWDATA),
        .PRDATA(PRDATA), .PREADY(PREADY), .PSLVERR(PSLVERR),
        .ascon_irq(ascon_irq), .o_active(o_active)
    );

    // ---------------------------------------------------------------- BFM
    task apb_write(input [11:0] a, input [31:0] d);
        begin
            @(posedge PCLK);
            PSEL <= 1'b1; PENABLE <= 1'b0; PWRITE <= 1'b1; PADDR <= a; PWDATA <= d;
            @(posedge PCLK);
            PENABLE <= 1'b1;
            @(posedge PCLK);
            rd_err = PSLVERR;
            PSEL <= 1'b0; PENABLE <= 1'b0; PWRITE <= 1'b0;
        end
    endtask

    task apb_read(input [11:0] a);
        begin
            @(posedge PCLK);
            PSEL <= 1'b1; PENABLE <= 1'b0; PWRITE <= 1'b0; PADDR <= a;
            @(posedge PCLK);
            PENABLE <= 1'b1;
            @(posedge PCLK);
            rd     = PRDATA;
            rd_err = PSLVERR;
            PSEL <= 1'b0; PENABLE <= 1'b0;
        end
    endtask

    task chk32(input string name, input [31:0] got, input [31:0] exp);
        begin
            if (got === exp) begin
                pass_cnt = pass_cnt + 1;
                $display("[TB][PASS] %0s = 0x%08x", name, got);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[TB][FAIL] %0s = 0x%08x, mong doi 0x%08x", name, got, exp);
            end
        end
    endtask

    task chk1(input string name, input got, input exp);
        begin
            if (got === exp) begin
                pass_cnt = pass_cnt + 1;
                $display("[TB][PASS] %0s = %0b", name, got);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[TB][FAIL] %0s = %0b, mong doi %0b", name, got, exp);
            end
        end
    endtask

    // Cho toi khi loi o ST_WAIT_DATA: READY = 1 va BUSY = 1.
    task wait_wait_data;
        integer guard;
        begin
            guard = 0;
            rd = 32'h0;
            while (!(rd[0] && rd[3]) && guard < 200) begin
                apb_read(12'h004);
                guard = guard + 1;
            end
            if (guard >= 200) begin
                fail_cnt = fail_cnt + 1;
                $display("[TB][FAIL] timeout cho ST_WAIT_DATA, STATUS=0x%08x", rd);
            end
        end
    endtask

    task wait_done;
        integer guard;
        begin
            guard = 0;
            rd = 32'h0;
            while (!rd[1] && guard < 400) begin
                apb_read(12'h004);
                guard = guard + 1;
            end
            if (guard >= 400) begin
                fail_cnt = fail_cnt + 1;
                $display("[TB][FAIL] timeout cho DONE, STATUS=0x%08x", rd);
            end
        end
    endtask

    // Nap mot khoi 64-bit roi xung DATA_VALID voi lenh `cmd`.
    task push_block(input [2:0] cmd, input mode, input [63:0] blk);
        begin
            apb_write(12'h030, blk[63:32]);
            apb_write(12'h034, blk[31:0]);
            apb_write(12'h000, {24'h0, cmd, 1'b1, 1'b0, 1'b0, mode, 1'b0});
        end
    endtask

    initial begin
        repeat (5) @(posedge PCLK);
        PRESETn = 1'b1;
        repeat (5) @(posedge PCLK);

        // ---------------------------------------------------------------
        // 1. Thanh ghi / giai ma dia chi
        // ---------------------------------------------------------------
        $display("[TB] --- Register / decode ---");
        apb_read(12'h004);
        chk32("STATUS sau reset", rd, 32'h0000_0001);   // chi READY = 1
        chk1 ("SLVERR doc STATUS", rd_err, 1'b0);

        apb_read(12'h010);                              // KEY0 la write-only
        chk1 ("SLVERR doc KEY0 (WO)", rd_err, 1'b1);

        apb_write(12'h100, 32'hFFFF_FFFF);              // alias cu cua CTRL
        chk1 ("SLVERR ghi 0x100 (alias)", rd_err, 1'b1);
        apb_read(12'h000);
        chk32("CTRL khong bi alias ghi de", rd, 32'h0000_0000);

        apb_write(12'h000, 32'h0000_0002);              // MODE = 1, khong START
        apb_read(12'h000);
        chk32("CTRL ghi/doc", rd, 32'h0000_0002);
        apb_write(12'h000, 32'h0000_0000);

        // ---------------------------------------------------------------
        // 2. ASCON-128 AEAD encrypt
        // ---------------------------------------------------------------
        $display("[TB] --- ASCON-128 AEAD ---");
        apb_write(12'h010, 32'h00010203);
        apb_write(12'h014, 32'h04050607);
        apb_write(12'h018, 32'h08090a0b);
        apb_write(12'h01C, 32'h0c0d0e0f);
        apb_write(12'h020, 32'h10111213);
        apb_write(12'h024, 32'h14151617);
        apb_write(12'h028, 32'h18191a1b);
        apb_write(12'h02C, 32'h1c1d1e1f);

        apb_write(12'h000, 32'h0000_0001);              // START, MODE = 0
        wait_wait_data();

        push_block(CMD_AD,      1'b0, 64'h4142434445464748);
        wait_wait_data();
        push_block(CMD_AD_LAST, 1'b0, 64'h8000000000000000);
        wait_wait_data();

        push_block(CMD_PT,      1'b0, 64'h0011223344556677);
        wait_wait_data();
        apb_read(12'h040); chk32("C0 hi", rd, 32'hea6ba663);
        apb_read(12'h044); chk32("C0 lo", rd, 32'h48113df6);

        push_block(CMD_PT_LAST, 1'b0, 64'h8899aabb80000000);
        wait_done();

        apb_read(12'h040); chk32("C1 hi", rd, 32'h984f4ce5);
        apb_read(12'h044); chk32("C1 lo", rd, 32'h2c807298);

        apb_read(12'h050); chk32("TAG[127:96]", rd, 32'h36969abd);
        apb_read(12'h054); chk32("TAG[95:64]",  rd, 32'h80f49104);
        apb_read(12'h058); chk32("TAG[63:32]",  rd, 32'h2d4200d3);
        apb_read(12'h05C); chk32("TAG[31:0]",   rd, 32'h700c0867);

        chk1("ascon_irq len sau DONE", ascon_irq, 1'b1);
        apb_write(12'h004, 32'h0000_0002);              // W1C
        apb_read(12'h004);
        chk1("DONE xoa duoc bang W1C", rd[1], 1'b0);
        chk1("ascon_irq ha theo DONE", ascon_irq, 1'b0);

        // ---------------------------------------------------------------
        // 3. ASCON-Hash
        // ---------------------------------------------------------------
        $display("[TB] --- ASCON-Hash ---");
        apb_write(12'h000, 32'h0000_0003);              // START + MODE = 1
        wait_wait_data();
        push_block(CMD_HASH,      1'b1, 64'h0011223344556677);
        wait_wait_data();
        push_block(CMD_HASH_LAST, 1'b1, 64'h8000000000000000);
        wait_done();

        apb_read(12'h050); chk32("HASH[255:224]", rd, 32'hb52f717d);
        apb_read(12'h054); chk32("HASH[223:192]", rd, 32'h7e1778a2);
        apb_read(12'h058); chk32("HASH[191:160]", rd, 32'h8c5a390d);
        apb_read(12'h05C); chk32("HASH[159:128]", rd, 32'hd17c8dd9);
        apb_read(12'h060); chk32("HASH[127:96]",  rd, 32'hded78fd2);
        apb_read(12'h064); chk32("HASH[95:64]",   rd, 32'hc48f80e2);
        apb_read(12'h068); chk32("HASH[63:32]",   rd, 32'h358404f6);
        apb_read(12'h06C); chk32("HASH[31:0]",    rd, 32'h27185a63);

        // ---------------------------------------------------------------
        // 4. Clock-gate hint
        // ---------------------------------------------------------------
        apb_read(12'h004);
        chk1("o_active thap khi ranh", o_active, 1'b0);

        // ---------------------------------------------------------------
        // 5. TRNG - chi kiem bat tay, KHONG danh gia entropy
        // ---------------------------------------------------------------
        $display("[TB] --- TRNG handshake ---");
        apb_read(12'h004);
        chk1("TRNG_VALID thap khi chua bat", rd[2], 1'b0);

        apb_write(12'h000, 32'h0000_0008);              // TRNG_EN = 1
        // ctrl_reg cap nhat o chinh canh len ma apb_write ket thuc; doi qua
        // vung NBA roi moi doc tin hieu to hop `o_active`.
        #1;
        chk1("o_active cao khi TRNG_EN", o_active, 1'b1);
        repeat (200) @(posedge PCLK);
        apb_read(12'h004);
        chk1("TRNG_VALID len sau 128 chu ky", rd[2], 1'b1);

        apb_read(12'h070); trng_a = rd;
        if (trng_a !== 32'h0) begin
            pass_cnt = pass_cnt + 1;
            $display("[TB][PASS] TRNG_RAND khac 0 = 0x%08x", trng_a);
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("[TB][FAIL] TRNG_RAND van bang 0 - ring oscillator khong chay");
        end

        repeat (40) @(posedge PCLK);
        apb_read(12'h070); trng_b = rd;
        if (trng_b !== trng_a) begin
            pass_cnt = pass_cnt + 1;
            $display("[TB][PASS] TRNG_RAND doi theo thoi gian: 0x%08x -> 0x%08x", trng_a, trng_b);
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("[TB][FAIL] TRNG_RAND dung yen o 0x%08x", trng_a);
        end

        apb_write(12'h000, 32'h0000_0000);              // tat TRNG

        $display("[TB] ----------------------------------------------");
        $display("[TB] PASS COUNT = %0d", pass_cnt);
        $display("[TB] FAIL COUNT = %0d", fail_cnt);
        $display("[TB] RESULT: %0s", (fail_cnt == 0) ? "PASS" : "FAIL");
        $display("[TB] ----------------------------------------------");
        $finish;
    end

    initial begin
        #500000;
        $display("[TB][FAIL] global timeout");
        $display("[TB] RESULT: FAIL");
        $finish;
    end

endmodule
