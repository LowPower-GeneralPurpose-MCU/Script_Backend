`timescale 1ns / 1ps

// =============================================================================
// PMP - Physical Memory Protection (RISC-V Privileged 1.12, muc 3.7), 2026-09-11.
//
// Core chi co M-mode, nen PMP o day co DUNG MOT tac dung: entry co bit L (lock)
// ap luat R/W/X len chinh M-mode, va entry da khoa thi khong ai sua duoc cho
// toi reset. Entry khong khoa khop dia chi thi truy cap M-mode van duoc phep
// (dac ta), nen chung chi co y nghia de "che" entry khoa phia sau.
//
// Muc dich: secure boot. Boot ROM (tang 1) dung ASCON-Hash kiem anh firmware,
// roi truoc khi nhay vao firmware thi KHOA:
//   - vung khoa/key (vi du thanh ghi key cua ASCON, hoac mot vung RAM giu key)
//     -> R=W=X=0: firmware bi xam nhap cung khong doc duoc key.
//   - chinh boot ROM -> X only (hoac R|X): khong the doc tron ROM de do quy trinh.
//   - vung code firmware -> R|X (khong W): chong ghi de code dang chay.
// Bo sung cho khoa JTAG trong apb_syscon.v (SEC_CTRL.DBG_LOCK): PMP chan CPU,
// khoa JTAG chan debugger.
//
// GIOI HAN (co y, ghi ro):
//   * PMP chi kiem truy cap CUA CPU. DMA (master AXI 3) va SBA cua Debug Module
//     (master AXI 2) di thang len bus, khong qua day. SBA bi khoa JTAG chan;
//     DMA can mot firewall tren bus (IOPMP) - chua co.
//   * Lenh lay ve duoc kiem theo dia chi PC cua no (word chua PC). Mot lenh 32
//     bit nam VAT qua ranh gioi 4 byte giua hai vung khac quyen chi duoc kiem
//     nua dau. Tranh bang cach dat ranh gioi vung o dia chi can 4 byte - dieu
//     vo cung tu nhien voi linker script.
//   * Ghi pmpcfg/pmpaddr co hieu luc tu lenh THU BA sau no voi phia lay lenh
//     (hai lenh ke tiep da duoc kiem X o tang ID truoc khi lenh ghi toi MEM).
//     Phia load/store co hieu luc ngay lenh ke tiep. Doan khoa trong boot ROM
//     ket thuc bang lenh nhay sang firmware nen dieu nay khong can gi them.
//
// Thong so:
//   PMP_ENTRIES = 8 (FE310). Dac ta chi cho phep hien thuc 0/16/64 CSR, nen van
//   co du 16 pmpaddr va 4 pmpcfg; entry >= PMP_ENTRIES la READ-ONLY 0.
//   G = 0 (granularity 4 byte) -> ca TOR, NA4, NAPOT deu dung duoc.
//   pmpaddr giu dia chi[33:2] (RV32). Dia chi vat ly o day 32 bit nen so sanh
//   voi {2'b00, addr[31:2]}.
//
// Tu cach kiem tra (ca hai cong giong nhau, chi khac dia chi):
//   * Cong DU LIEU (tang MEM, dia chi = ex_mem_alu_result). Vi pham -> access
//     fault mcause 5 (load) / 7 (store), mtval = dia chi. Loi di vao trap_enter,
//     trap_enter la commit_kill cua tang MEM, nen yeu cau D-cache/TCM bi CHAN
//     ngay trong chu ky do - truy cap bi cam KHONG BAO GIO ra toi bus, ke ca
//     mot lenh doc MMIO co tac dung phu (pop FIFO).
//   * Cong LAY LENH (tang ID, dia chi = if_id_pc_in - mot THANH GHI). Vi pham
//     di chung bit loi lay lenh da co (B3) -> mcause 1, mtval = PC. Kiem o ID
//     thay vi o IF de khong chen them bo so sanh vao sau PC-mux (duong toi han
//     cua core): dau vao o day la flop, dau ra la flop id_ex_fault.
// =============================================================================
module pmp_unit #(
    parameter PMP_ENTRIES = 8
)(
    input  wire        clk,
    input  wire        reset_n,

    // --- Ghi CSR (tang MEM, da loc: lenh that su ghi va khong bi trap) ---
    input  wire        csr_we,
    input  wire [11:0] csr_waddr,
    input  wire [31:0] csr_wdata,

    // --- Doc CSR: cong pipeline (tang EX) va cong debugger ---
    input  wire [11:0] rd_addr_a,
    output wire [31:0] rd_data_a,
    input  wire [11:0] rd_addr_b,
    output wire [31:0] rd_data_b,

    // Gia tri CSR SE CO sau lenh ghi o csr_waddr - da ap WARL va khoa. Cho
    // mang forwarding CSR cua core: doc lai ngay sau mot lenh ghi bi khoa phai
    // thay gia tri CU, khong phai du lieu vua ghi.
    output wire [31:0] wr_result,

    // --- Kiem tra ---
    input  wire [31:0] d_addr,
    input  wire        d_read,
    input  wire        d_write,
    output wire        d_fault,

    input  wire [31:0] i_addr,
    output wire        i_fault
);

    localparam [1:0] A_OFF   = 2'd0;
    localparam [1:0] A_TOR   = 2'd1;
    localparam [1:0] A_NA4   = 2'd2;
    localparam [1:0] A_NAPOT = 2'd3;

    reg [7:0]  cfg_q  [0:PMP_ENTRIES-1];
    reg [31:0] addr_q [0:PMP_ENTRIES-1];

    // -------------------------------------------------------------------------
    // WARL cho mot byte pmpcfg: bit [6:5] luon 0; to hop R=0,W=1 la reserved
    // (khong co Smepmp) -> ep ve R=W=0, giong Ibex.
    // -------------------------------------------------------------------------
    function automatic [7:0] cfg_legal;
        input [7:0] v;
        begin
            cfg_legal = {v[7], 2'b00, v[4:3], v[2], v[1] & v[0], v[0]};
        end
    endfunction

    // Entry j bi khoa GHI pmpaddr khi chinh no L, hoac entry j+1 la TOR va L
    // (pmpaddr[j] la can duoi cua vung TOR do).
    function automatic addr_locked;
        input integer j;
        begin
            addr_locked = cfg_q[j][7];
            if (j + 1 < PMP_ENTRIES)
                if (cfg_q[j+1][7] && (cfg_q[j+1][4:3] == A_TOR))
                    addr_locked = 1'b1;
        end
    endfunction

    // Doc: pmpcfg0..3 = 0x3A0..0x3A3, pmpaddr0..15 = 0x3B0..0x3BF.
    function automatic [31:0] csr_value;
        input [11:0] a;
        integer b, e;
        begin
            csr_value = 32'd0;
            if (a[11:2] == 10'b0011_1010_00) begin          // 0x3A0-0x3A3
                for (b = 0; b < 4; b = b + 1) begin
                    e = a[1:0] * 4 + b;
                    if (e < PMP_ENTRIES)
                        csr_value[8*b +: 8] = cfg_q[e];
                end
            end else if (a[11:4] == 8'h3B) begin            // 0x3B0-0x3BF
                if (a[3:0] < PMP_ENTRIES)
                    csr_value = addr_q[a[3:0]];
            end
        end
    endfunction

    // Gia tri sau khi ghi `v` vao CSR `a` (khong doi neu bi khoa / RO).
    function automatic [31:0] csr_after_write;
        input [11:0] a;
        input [31:0] v;
        integer b, e;
        begin
            csr_after_write = csr_value(a);
            if (a[11:2] == 10'b0011_1010_00) begin
                for (b = 0; b < 4; b = b + 1) begin
                    e = a[1:0] * 4 + b;
                    if (e < PMP_ENTRIES)
                        if (!cfg_q[e][7])
                            csr_after_write[8*b +: 8] = cfg_legal(v[8*b +: 8]);
                end
            end else if (a[11:4] == 8'h3B) begin
                if (a[3:0] < PMP_ENTRIES)
                    if (!addr_locked(a[3:0]))
                        csr_after_write = v;
            end
        end
    endfunction

    // Danh sach nhay tuong minh cho ly do G2 cua register_file.v: ham doc mang
    // cfg_q/addr_q ben trong than, mot so cong cu khong tu dua chung vao @(*).
    // Mang duoc "trai" ra bang flat_* de liet ke duoc.
    wire [8*PMP_ENTRIES-1:0]  flat_cfg;
    wire [32*PMP_ENTRIES-1:0] flat_addr;
    genvar gf;
    generate
        for (gf = 0; gf < PMP_ENTRIES; gf = gf + 1) begin : g_flat
            assign flat_cfg [8*gf  +: 8]  = cfg_q[gf];
            assign flat_addr[32*gf +: 32] = addr_q[gf];
        end
    endgenerate

    reg [31:0] rd_a_r, rd_b_r, wr_res_r;
    always @(rd_addr_a or rd_addr_b or csr_waddr or csr_wdata or
             flat_cfg or flat_addr) begin
        rd_a_r   = csr_value(rd_addr_a);
        rd_b_r   = csr_value(rd_addr_b);
        wr_res_r = csr_after_write(csr_waddr, csr_wdata);
    end
    assign rd_data_a = rd_a_r;
    assign rd_data_b = rd_b_r;
    assign wr_result = wr_res_r;

    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < PMP_ENTRIES; i = i + 1) begin
                cfg_q[i]  <= 8'd0;
                addr_q[i] <= 32'd0;
            end
        end else if (csr_we) begin
            if (csr_waddr[11:2] == 10'b0011_1010_00) begin
                for (i = 0; i < 4; i = i + 1)
                    if ((csr_waddr[1:0] * 4 + i) < PMP_ENTRIES)
                        if (!cfg_q[csr_waddr[1:0] * 4 + i][7])
                            cfg_q[csr_waddr[1:0] * 4 + i] <= cfg_legal(csr_wdata[8*i +: 8]);
            end else if (csr_waddr[11:4] == 8'h3B) begin
                if (csr_waddr[3:0] < PMP_ENTRIES)
                    if (!addr_locked(csr_waddr[3:0]))
                        addr_q[csr_waddr[3:0]] <= csr_wdata;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Khop dia chi. aw = dia chi word {2'b00, a[31:2]}, cung don vi voi pmpaddr.
    //
    //   TOR  : pmpaddr[i-1] <= aw < pmpaddr[i]   (i = 0: can duoi = 0)
    //   NA4  : aw == pmpaddr[i]
    //   NAPOT: pmpaddr = base | 0..0111 (k so 1 cuoi) -> vung 2^(k+3) byte. Bit b
    //          cua aw la "khong quan tam" khi moi bit THAP HON b cua pmpaddr deu
    //          bang 1 (dc[b] = &pmpaddr[b-1:0], dc[0] = 1) - tuc cac bit 1 cuoi
    //          VA bit 0 dau tien. Synthesis dung chung cay AND tien to; khong
    //          co bo cong pmpaddr+1 (chuoi carry 32 bit).
    //
    // ge[i] = (aw >= pmpaddr[i]) duoc DUNG CHUNG: TOR cua entry i can ~ge[i] va
    // ge[i-1], nen 8 entry chi can 8 bo so sanh moi cong, khong phai 16.
    // Truy cap da can le (misaligned bi trap truoc) va nam gon trong 1 word, nen
    // khong co truong hop chi mot phan byte khop.
    // -------------------------------------------------------------------------
    function automatic [PMP_ENTRIES-1:0] match_vec;
        input [31:0] a;
        reg   [31:0] aw;
        reg   [PMP_ENTRIES-1:0] ge;
        reg   [31:0] dc;
        integer e, b;
        begin
            aw = {2'b00, a[31:2]};
            for (e = 0; e < PMP_ENTRIES; e = e + 1)
                ge[e] = (aw >= addr_q[e]);
            for (e = 0; e < PMP_ENTRIES; e = e + 1) begin
                dc[0] = 1'b1;
                for (b = 1; b < 32; b = b + 1)
                    dc[b] = dc[b-1] & addr_q[e][b-1];
                case (cfg_q[e][4:3])
                    A_TOR:   match_vec[e] = ((e == 0) ? 1'b1 : ge[(e == 0) ? 0 : e-1]) & ~ge[e];
                    A_NA4:   match_vec[e] = (aw == addr_q[e]);
                    A_NAPOT: match_vec[e] = ~|((aw ^ addr_q[e]) & ~dc);
                    default: match_vec[e] = 1'b0;
                endcase
            end
        end
    endfunction

    // Entry khop co SO THU TU NHO NHAT quyet dinh. Khong khop gi, hoac khop mot
    // entry khong khoa -> M-mode duoc phep. Tra ve {locked, X, W, R}.
    function automatic [3:0] decide;
        input [PMP_ENTRIES-1:0] m;
        integer e;
        begin
            decide = 4'b0111;
            for (e = PMP_ENTRIES - 1; e >= 0; e = e - 1)
                if (m[e])
                    decide = cfg_q[e][7] ? {1'b1, cfg_q[e][2:0]} : 4'b0111;
        end
    endfunction

    reg [3:0] d_perm, i_perm;
    always @(d_addr or i_addr or flat_cfg or flat_addr) begin
        d_perm = decide(match_vec(d_addr));
        i_perm = decide(match_vec(i_addr));
    end

    assign d_fault = (d_read & ~d_perm[0]) | (d_write & ~d_perm[1]);
    assign i_fault = ~i_perm[2];

endmodule
