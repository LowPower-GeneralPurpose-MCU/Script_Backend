//==================================================================================================
// File: pipeline_stage.v
//==================================================================================================
module riscv_c_decompressor (
    input wire [15:0] instr16,
    output reg [31:0] instr32
);
    localparam [31:0] NOP32 = 32'h00000013;

    function automatic [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] enc_i;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] enc_s;
        input [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        begin
            enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011};
        end
    endfunction

    wire [1:0] quadrant = instr16[1:0];
    wire [2:0] funct3_c = instr16[15:13];
    wire [4:0] crd      = instr16[11:7];
    wire [4:0] crs2     = instr16[6:2];
    wire [4:0] crd_p    = {2'b01, instr16[4:2]};     // x8-x15
    wire [4:0] crs1_p   = {2'b01, instr16[9:7]};     // x8-x15
    wire [4:0] crs2_p   = {2'b01, instr16[4:2]};     // x8-x15

    // Immediate encodings
    wire [11:0] ci_imm   = {{6{instr16[12]}}, instr16[12], instr16[6:2]};
    wire [11:0] cl_imm   = {5'b00000, instr16[5], instr16[12:10], instr16[6], 2'b00};
    wire [11:0] lwsp_imm = {4'b0000, instr16[3:2], instr16[12], instr16[6:4], 2'b00};
    wire [11:0] swsp_imm = {4'b0000, instr16[8:7], instr16[12:9], 2'b00};
    wire [11:0] shamt_imm = {7'b0000000, instr16[6:2]};

    // C.ADDI4SPN: nzuimm[5:4|9:6|2|3] → offset scaled by 4
    wire [11:0] ciw_imm  = {2'b00, instr16[10:7], instr16[12:11], instr16[5], instr16[6], 2'b00};

    // C.ADDI16SP: nzimm[9|4|6|8:7|5] → sign-extended, scaled by 16
    wire [11:0] c16sp_imm = {{3{instr16[12]}}, instr16[12], instr16[4:3], instr16[5], instr16[2], instr16[6], 4'b0000};

    // C.LUI: nzimm[17|16:12]
    wire [31:0] clui_imm = {{15{instr16[12]}}, instr16[12], instr16[6:2], 12'b0};

    // C.J / C.JAL: offset[11|4|9:8|10|6|7|3:1|5]
    wire [20:0] cj_imm_raw = {{10{instr16[12]}}, instr16[12], instr16[8], instr16[10:9], instr16[6],
                               instr16[7], instr16[2], instr16[11], instr16[5:3], 1'b0};
    // Encode as JAL rd, offset: imm[20|10:1|11|19:12]
    wire [31:0] cj_jal;
    assign cj_jal = {cj_imm_raw[20], cj_imm_raw[10:1], cj_imm_raw[11], cj_imm_raw[19:12]};

    // C.BEQZ / C.BNEZ: offset[8|4:3|7:6|2:1|5]
    wire [12:0] cb_imm_raw = {{5{instr16[12]}}, instr16[12], instr16[6:5], instr16[2], instr16[11:10], instr16[4:3], 1'b0};
    // Encode as B-type: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
    wire [11:0] cb_imm_enc = {cb_imm_raw[12], cb_imm_raw[10:5], cb_imm_raw[4:1], cb_imm_raw[11]};

    always @(*) begin
        instr32 = NOP32;

        case (quadrant)
            // =========================================
            // Quadrant 0 (Q0)
            // =========================================
            2'b00: begin
                case (funct3_c)
                    3'b000: begin // C.ADDI4SPN: addi rd', x2, nzuimm
                        if (ciw_imm != 12'd0)
                            instr32 = enc_i(ciw_imm, 5'd2, 3'b000, crd_p, 7'b0010011);
                        else
                            instr32 = NOP32; // Reserved (nzuimm=0)
                    end
                    3'b010: instr32 = enc_i(cl_imm, crs1_p, 3'b010, crd_p, 7'b0000011); // C.LW
                    3'b110: instr32 = enc_s(cl_imm, crd_p, crs1_p, 3'b010);             // C.SW
                    default: instr32 = NOP32;
                endcase
            end

            // =========================================
            // Quadrant 1 (Q1)
            // =========================================
            2'b01: begin
                case (funct3_c)
                    3'b000: instr32 = enc_i(ci_imm, crd, 3'b000, crd, 7'b0010011);      // C.ADDI / C.NOP
                    3'b001: begin // C.JAL (RV32 only): jal x1, offset
                        instr32 = {cj_jal[19:0], 5'd1, 7'b1101111};
                    end
                    3'b010: instr32 = enc_i(ci_imm, 5'd0, 3'b000, crd, 7'b0010011);     // C.LI
                    3'b011: begin // C.LUI / C.ADDI16SP
                        if (crd == 5'd2) begin // C.ADDI16SP
                            if (c16sp_imm != 12'd0)
                                instr32 = enc_i(c16sp_imm, 5'd2, 3'b000, 5'd2, 7'b0010011);
                            else
                                instr32 = NOP32; // Reserved (nzimm=0)
                        end else if (crd != 5'd0) begin // C.LUI
                            instr32 = {clui_imm[31:12], crd, 7'b0110111};
                        end else begin
                            instr32 = NOP32; // Reserved (rd=0)
                        end
                    end
                    3'b100: begin // C.SRLI, C.SRAI, C.ANDI, C.SUB, C.XOR, C.OR, C.AND
                        case (instr16[11:10])
                            2'b00: begin // C.SRLI
                                instr32 = enc_i({7'b0000000, instr16[6:2]}, crs1_p, 3'b101, crs1_p, 7'b0010011);
                            end
                            2'b01: begin // C.SRAI
                                instr32 = enc_i({7'b0100000, instr16[6:2]}, crs1_p, 3'b101, crs1_p, 7'b0010011);
                            end
                            2'b10: begin // C.ANDI
                                instr32 = enc_i(ci_imm, crs1_p, 3'b111, crs1_p, 7'b0010011);
                            end
                            2'b11: begin // C.SUB, C.XOR, C.OR, C.AND
                                case ({instr16[12], instr16[6:5]})
                                    3'b000: instr32 = enc_r(7'b0100000, crs2_p, crs1_p, 3'b000, crs1_p, 7'b0110011); // C.SUB
                                    3'b001: instr32 = enc_r(7'b0000000, crs2_p, crs1_p, 3'b100, crs1_p, 7'b0110011); // C.XOR
                                    3'b010: instr32 = enc_r(7'b0000000, crs2_p, crs1_p, 3'b110, crs1_p, 7'b0110011); // C.OR
                                    3'b011: instr32 = enc_r(7'b0000000, crs2_p, crs1_p, 3'b111, crs1_p, 7'b0110011); // C.AND
                                    default: instr32 = NOP32;
                                endcase
                            end
                        endcase
                    end
                    3'b101: begin // C.J: jal x0, offset
                        instr32 = {cj_jal[19:0], 5'd0, 7'b1101111};
                    end
                    3'b110: begin // C.BEQZ: beq rs1', x0, offset
                        instr32 = {cb_imm_enc[11:5], 5'd0, crs1_p, 3'b000, cb_imm_enc[4:0], 7'b1100011};
                    end
                    3'b111: begin // C.BNEZ: bne rs1', x0, offset
                        instr32 = {cb_imm_enc[11:5], 5'd0, crs1_p, 3'b001, cb_imm_enc[4:0], 7'b1100011};
                    end
                endcase
            end

            // =========================================
            // Quadrant 2 (Q2)
            // =========================================
            2'b10: begin
                case (funct3_c)
                    3'b000: instr32 = enc_i(shamt_imm, crd, 3'b001, crd, 7'b0010011);   // C.SLLI
                    3'b010: instr32 = (crd != 5'd0) ?
                                      enc_i(lwsp_imm, 5'd2, 3'b010, crd, 7'b0000011) :
                                      NOP32;                                             // C.LWSP
                    3'b100: begin
                        if (!instr16[12]) begin
                            if (crs2 == 5'd0 && crd != 5'd0) begin
                                // C.JR: jalr x0, rs1, 0
                                instr32 = enc_i(12'd0, crd, 3'b000, 5'd0, 7'b1100111);
                            end else if (crs2 != 5'd0 && crd != 5'd0) begin
                                // C.MV: add rd, x0, rs2
                                instr32 = enc_r(7'b0000000, crs2, 5'd0, 3'b000, crd, 7'b0110011);
                            end else begin
                                instr32 = NOP32;
                            end
                        end else begin
                            if (crs2 == 5'd0 && crd == 5'd0) begin
                                // C.EBREAK
                                instr32 = 32'h00100073;
                            end else if (crs2 == 5'd0 && crd != 5'd0) begin
                                // C.JALR: jalr x1, rs1, 0
                                instr32 = enc_i(12'd0, crd, 3'b000, 5'd1, 7'b1100111);
                            end else if (crs2 != 5'd0 && crd != 5'd0) begin
                                // C.ADD: add rd, rd, rs2
                                instr32 = enc_r(7'b0000000, crs2, crd, 3'b000, crd, 7'b0110011);
                            end else begin
                                instr32 = NOP32;
                            end
                        end
                    end
                    3'b110: instr32 = enc_s(swsp_imm, crs2, 5'd2, 3'b010);             // C.SWSP
                    default: instr32 = NOP32;
                endcase
            end

            default: instr32 = NOP32;
        endcase
    end
endmodule

module instruction_fetch (
    input wire reset_n,
    input wire flush_temp, 
    input wire trap_enter, 
    input wire mret_exec,
    input wire [31:0] reset_vector_in,
    input wire [31:0] mtvec_in, 
    input wire [31:0] mepc_in,
    input wire [31:0] ex_mem_branch_target, 
    input wire [31:0] id_ex_jal_target, 
    input wire [31:0] pc_in, 
    input wire [31:0] ex_mem_pc_in,
    input wire [31:0] ex_mem_pc_plus_4,
    // R2 - JALR duoc phan giai o EX/MEM (nhu nhanh dieu kien), khong con o ID/EX.
    // `alu_in1` / `id_ex_ext_imm` khong con di vao tang nay nua.
    input wire ex_mem_jalr,
    input wire [31:0] ex_mem_jalr_target,
    input wire id_ex_jal, 
    input wire btb_hit,
    input wire predict_taken, 
    input wire actual_taken, 
    input wire bpu_correct,
    input wire [31:0] predict_target,
    input wire fetch_two_valid,

    // ---- F4: dong cong khi khong thuc su lay lenh ----
    // fetch_enable = ~(stall_IF | is_sleeping | dbg_halted), tinh o riscv_pipeline.v
    input wire clk,
    input wire icache_stall_in,
    input wire icache_error_in,   // B3 - loi bus tu I-cache, dong bien voi du lieu
    input wire fetch_enable,

    // ---- F3: bat tay voi thanh ghi IF/ID ----
    input  wire if_accept,        // IF/ID se chot trong chu ky nay (= !stall_if_id)
    output wire realign_stall,    // dang lay nua thu nhat: giu PC, bom bong bong

    output reg [31:0] pc_out,
    output wire [31:0] pc_plus_4,
    output wire [31:0] pc_plus_8,
    output wire [31:0] instr,
    output wire [31:0] instr_lane1,
    output wire instr_fault,      // B3 - lenh vua tra ve den tu dia chi loi bus
    output wire icache_read_req,
    output wire icache_read_req_lane1,
    output wire [31:0] icache_addr,
    output wire [31:0] icache_addr_lane1,
    input wire [31:0] icache_read_data,
    input wire [31:0] icache_read_data_lane1
);

    localparam [31:0] IF_NOP = 32'h00000013;

    // =============================================================================
    // F3 - lenh 32 bit VAT QUA HAI WORD khi C bat.
    //
    // Bo nho lenh tra ve WORD DA CAN LE chua pc_in. Voi C bat, mot lenh 32 bit co
    // the bat dau o bien 2 byte, khi do 32 bit cua no nam vat qua hai word:
    //
    //      dia chi:   ... 0x100 ......... 0x104 ...
    //      bo nho :  [ B B A A ]        [ D D C C ]
    //                      ^^^^ nua THAP cua lenh o 0x102
    //                                       ^^^^ nua CAO cua lenh o 0x102
    //
    // Ma cu:  assign instr = instr0_compressed ? instr0_expanded : icache_read_data;
    // tuc lay nguyen word tai 0x100 = {A,A,B,B} - KHONG LIEN QUAN GI den lenh that.
    //
    // Day la loi kinh dien cua RVC: khong xuat hien khi test chi co lenh 32 bit,
    // cung khong xuat hien khi test chi co lenh nen. No chi hien ra khi mot CHUOI
    // LE lenh nen day mot lenh 32 bit sang bien le - tuc trong MOI chuong trinh
    // that duoc bien dich voi -march=rv32imac.
    //
    // Cach sua: FSM hai trang thai, ton them 1 chu ky va CHI khi thuc su vat bien:
    //
    //   ST_IDLE, pc[1]=1, lenh khong nen  -> lay word tai {pc[31:2],00}, giu nua
    //                                        tren [31:16] vao rl_half. Bat
    //                                        realign_stall: bom bong bong vao
    //                                        IF/ID va giu pc_reg.
    //   ST_JOIN                           -> doi dia chi icache sang word ke tiep,
    //                                        ghep {icache_read_data[15:0], rl_half}.
    //                                        Ha realign_stall, pipeline chay tiep.
    //
    // Dung rl_pc lam bao ve thay vi liet ke cac tin hieu doi huong: PC co the bi
    // doi bat ngo boi trap, nhanh doan sai, jal/jalr, VA boi Debug Module ghi dpc.
    // So sanh rl_pc voi pc_in bat duoc TAT CA truong hop do bang mot dieu kien.
    //
    // Khong dung cong icache lane 1 (dia chi pc+4) cho re vi cong do da bi tie-off
    // o top_soc.v; lam vay se bat SoC phai phuc vu hai cong lenh vinh vien.
    // =============================================================================
    localparam ST_IDLE = 1'b0;
    localparam ST_JOIN = 1'b1;

    reg        rl_state;
    reg [15:0] rl_half;        // nua THAP cua lenh vat bien, lay o chu ky truoc
    reg [31:0] rl_pc;          // PC ma nua tren thuoc ve - dung de tu bao ve

    // Du lieu lenh chi hop le khi cong dang mo va bo nho khong stall (F4).
    wire fetch_valid = fetch_enable && !icache_stall_in;

    wire [15:0] instr0_half = pc_in[1] ? icache_read_data[31:16] : icache_read_data[15:0];
    wire        raw_compressed = (instr0_half[1:0] != 2'b11);

    // Lenh 32 bit bat dau o bien 2 byte -> vat qua hai word.
    wire need_realign = pc_in[1] && !raw_compressed;

    // Dang o nhip thu hai VA nua da giu van thuoc ve dung PC nay.
    wire joining = (rl_state == ST_JOIN) && (rl_pc == pc_in);

    // Trong nhip ghep, instr0_half tro toi word KE TIEP nen khong duoc dung de
    // xet "co nen hay khong" nua - ep ve khong nen.
    wire instr0_compressed = joining ? 1'b0 : raw_compressed;

    wire [31:0] instr0_expanded;

    // -------------------------------------------------------------------------
    // P1 - MUX PHAI DAT SAU ADDER, KHONG PHAI TRUOC.
    //
    // Ma cu:  seq_pc = pc_in + (instr0_compressed ? 32'd2 : 32'd4);
    //
    // `instr0_compressed` phu thuoc DU LIEU RA TU I-CACHE (qua fetch_valid <-
    // icache_stall_in). Viet mux TRUOC adder buoc bo cong 32 bit phai bat dau
    // SAU KHI cache tra loi. Genus khong tu dao duoc vi do la mot toan hang that.
    //
    // reports/timing_syn.rpt Path 1 (slack +6 ps tren chu ky 2500 ps) di dung
    // duong do:
    //     u_icache/state_reg[0] -> mux hit cua cache -> u_core/IF_add_279_30_*
    //                           -> IF_ID_if_id_pc_plus_4_reg[31]
    // Chuoi IF_add_279_30_g457..g401 la ~30 tang NAND2/NOR2 (ripple carry) va
    // chiem tu moc 974 ps den 2332 ps = 1358 ps, tuc 58 % duong toi han.
    //
    // Bay gio hai bo cong chay SONG SONG ngay tu dau chu ky, khong doi cache;
    // `instr0_compressed` chi con dieu khien mot tang mux 2:1 o cuoi.
    // pc+2 va pc+4 chi khac nhau o carry cua bit 1 nen tong hop chia se duoc gan
    // het logic - dien tich tang khong dang ke.
    //
    // Nhanh `fetch_two_valid ? 32'd8` da bi bo: riscv_pipeline.v noi cung cong do
    // bang 1'b0 (che do scalar, lane 1 tat), nen do la code chet.
    // -------------------------------------------------------------------------
    wire [31:0] pc_p2 = pc_in + 32'd2;
    wire [31:0] pc_p4 = pc_in + 32'd4;
    wire [31:0] seq_pc = instr0_compressed ? pc_p2 : pc_p4;

    // Giu PC va bom bong bong trong nhip lay nua thu nhat.
    assign realign_stall = (rl_state == ST_IDLE) && need_realign && fetch_valid;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rl_state <= ST_IDLE;
            rl_half  <= 16'd0;
            rl_pc    <= 32'd0;
        end else begin
            case (rl_state)
                ST_IDLE: begin
                    if (need_realign && fetch_valid) begin
                        rl_half  <= icache_read_data[31:16];
                        rl_pc    <= pc_in;
                        rl_state <= ST_JOIN;
                    end
                end
                ST_JOIN: begin
                    if (rl_pc != pc_in) begin
                        // PC bi doi huong duoi chan: bo nua da giu, lam lai tu dau.
                        rl_state <= ST_IDLE;
                    end else if (if_accept && fetch_valid) begin
                        rl_state <= ST_IDLE;
                    end
                end
            endcase
        end
    end

    riscv_c_decompressor C_DEC0 (
        .instr16(instr0_half),
        .instr32(instr0_expanded)
    );

    // -------------------------------------------------------------------------
    // R2 - JALR khong con duoc tinh o day.
    //
    // Truoc day tang nay chua `wire jalr_target = (alu_in1 + id_ex_ext_imm) &
    // 32'hFFFFFFFE;` va dung no ngay trong chuoi uu tien ben duoi, nen mot bo
    // cong 32 bit nam TRUOC ca mux next-PC trong cung mot chu ky. Do la critical
    // path #1 cua ban tong hop 2026-09-09 (2360 / 2361 ps, slack 0).
    //
    // Bay gio dia chi dich duoc tinh o tang EX (`execute`, xem ghi chu R2 o do),
    // chot vao EX/MEM, va den day chi con la mot dau vao thanh ghi -> mux.
    // JALR vi the phan giai CUNG TANG voi nhanh dieu kien.
    //
    // `ex_mem_jalr` va `!bpu_correct` loai tru nhau: JALR khong phai `ex_mem_branch`
    // nen khi `ex_mem_jalr` = 1 thi `bpu_correct` luon = 1. Thu tu giua hai nhanh
    // do khong quan trong; dat JALR truoc cho de doc.
    // -------------------------------------------------------------------------
    always @(*) begin
        if (!reset_n) begin
            pc_out = reset_vector_in;
        end else if (trap_enter) begin
            pc_out = mtvec_in;
        end else if (mret_exec) begin
            pc_out = mepc_in;
        end else if (ex_mem_jalr) begin
            pc_out = ex_mem_jalr_target;
        end else if (!bpu_correct && actual_taken) begin
            pc_out = ex_mem_branch_target;
        end else if (!bpu_correct && !actual_taken) begin
            // Use pipelined pc_plus_4: correct for compressed (pc+2) and 32-bit (pc+4)
            pc_out = ex_mem_pc_plus_4;
        end else if (id_ex_jal) begin
            pc_out = id_ex_jal_target;
        end else if (btb_hit && predict_taken) begin
            pc_out = predict_target;
        end else if (!flush_temp) begin
            pc_out = seq_pc;
        end else begin
            pc_out = pc_in;
        end
    end
    
    // ---- F4: khong phat yeu cau khi dang halt / ngu / stall ----
    // Truoc: `assign icache_read_req = 1'b1;` - phat yeu cau ke ca khi dang halt,
    // dang ngu (WFI), hay dang stall. Voi icache thuan thi vo hai ve chuc nang,
    // nhung no dot cong suat dong lien tuc: mang tag+data 4864 flip-flop bi doc
    // MOI chu ky. Voi mot MCU low-power day la lang phi khong the bien minh.
    //
    // Khi cong bi dong, `instr` duoc ep ve NOP thay vi du lieu cu. An toan vi moi
    // dieu kien dong cong deu keo theo pc_reg dung yen (stall_IF), nen lenh se
    // duoc lay lai dung o chu ky mo cong.
    assign icache_read_req = fetch_enable;
    assign icache_read_req_lane1 = 1'b0;

    // ---- F3: nhip ghep lay word KE TIEP ----
    assign icache_addr = joining ? ({pc_in[31:2], 2'b00} + 32'd4) : pc_in;
    assign icache_addr_lane1 = 32'd0;

    // Thu tu uu tien cua mux lenh:
    //   1. cong dong           -> NOP (an toan: pc_reg dung yen, se lay lai sau)
    //   2. dang ghep           -> {nua tren cua word ke tiep, nua duoi da giu}
    //   3. lenh nen            -> ban da giai nen
    //   4. dang lay nua dau    -> NOP (bong bong, di kem realign_stall)
    //   5. con lai             -> lenh 32 bit da can le
    // -------------------------------------------------------------------------
    // B3 - khi I-cache bao loi bus thi DU LIEU LA RAC.
    //
    // Ep ve NOP thay vi de rac chay vao decoder: neu khong, mot bit pattern ngau
    // nhien co the giai ma thanh `illegal` (mcause 2 - SAI nguyen nhan), hoac te
    // hon, thanh mot lenh HOP LE nhu `sw` va ghi that vao bo nho truoc khi trap
    // kip nhan. NOP thi vo hai; bit `instr_fault` di kem moi la thu sinh ra trap.
    // -------------------------------------------------------------------------
    assign instr_fault = fetch_valid & icache_error_in;

    assign instr = (!fetch_valid)     ? IF_NOP :
                   icache_error_in    ? IF_NOP :
                   joining            ? {icache_read_data[15:0], rl_half} :
                   instr0_compressed  ? instr0_expanded :
                   need_realign       ? IF_NOP :
                                        icache_read_data;
    assign instr_lane1 = IF_NOP;

    // `fetch_two_valid` chi phuc vu che do superscalar hai lane, ma riscv_pipeline
    // noi cung 1'b0. Giu cong de khong doi giao dien module, neu bo P1.
    wire _unused_if = &{1'b0, fetch_two_valid};
    // Cung mot bieu thuc voi seq_pc - dung lai thay vi suy dien them mot cap
    // adder nua tren cung duong toi han. Ten `pc_plus_4` giu nguyen cho tuong
    // thich; gia tri that la "PC cua lenh KE TIEP" (pc+2 voi lenh nen).
    assign pc_plus_4 = seq_pc;
    assign pc_plus_8 = pc_in + 32'd8;

endmodule


module instruction_decode (
    input [31:0] if_id_pc_in,
    input [31:0] if_id_instr,
    output [31:0] ext_imm, 
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,
    output reg [2:0] funct3,
    output reg [6:0] opcode,
    output reg [6:0] funct7,
    output [31:0] jal_target,
    output [31:0] branch_target,
    output reg_write,
    output alu_src,
    output mem_write,
    output mem_read,
    output mem_to_reg,
    output branch,
    output jal,
    output jalr,
    output lui,
    output auipc,
    output mem_unsigned,
    output [1:0] alu_op,
    output [1:0] mem_size,
    output [3:0] alu_ctrl,
    output md_type,
    output [2:0] md_operation,
    output ecall,
    output ebreak,
    output mret,
    output [11:0] csr_addr,
    output [1:0] csr_op,
    output csr_we,
    output wire wfi_req,
    output fence_op,        // P2c - `fence` xa store buffer cua D-cache
    output illegal_instr,   // V5 - ma lenh khong ton tai -> illegal-instruction
    output fpu_en,
    output f_reg_write,
    output f_mem_to_reg,
    output f_mem_write,
    output f_to_x,
    output x_to_f,
    output [4:0] fpu_operation
);

    reg [19:0] u_imm;
    reg [11:0] i_imm;
    reg [11:0] s_imm;
    reg [11:0] b_imm;
    reg [19:0] j_imm;
    
    always @(*) begin 
        opcode = if_id_instr[6:0];
        funct3 = if_id_instr[14:12];
        funct7 = if_id_instr[31:25];
        rs1 = if_id_instr[19:15];
        rs2 = if_id_instr[24:20];
        rd = if_id_instr[11:7];
        u_imm = if_id_instr[31:12];
        i_imm = if_id_instr[31:20];
        s_imm = {if_id_instr[31:25], if_id_instr[11:7]};
        b_imm = {if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8]};
        j_imm = {if_id_instr[31], if_id_instr[19:12], if_id_instr[20], if_id_instr[30:21]};
    end
    
    wire [31:0] u_imm_ext = {u_imm, 12'b0};
    wire [31:0] i_imm_ext = {{20{i_imm[11]}}, i_imm};
    wire [31:0] s_imm_ext = {{20{s_imm[11]}}, s_imm};
    wire [31:0] b_imm_ext = {{19{b_imm[11]}}, b_imm, 1'b0};
    wire [31:0] j_imm_ext = {{11{j_imm[19]}}, j_imm, 1'b0};
    
    assign ext_imm = (opcode == 7'b0110111 || opcode == 7'b0010111) ? u_imm_ext :
                     (opcode == 7'b0000011 || opcode == 7'b0010011 || opcode == 7'b1100111) ? i_imm_ext :
                     (opcode == 7'b0100011) ? s_imm_ext :
                     (opcode == 7'b1100011) ? b_imm_ext :
                     (opcode == 7'b1101111) ? j_imm_ext :
                     32'b0;

    assign md_type = (opcode == 7'b0110011 && funct7 == 7'b0000001);

    assign jal_target = if_id_pc_in + j_imm_ext;
    
    assign branch_target = if_id_pc_in + b_imm_ext;
    
    wire is_system = (opcode == 7'b1110011);
    assign ecall = (if_id_instr == 32'h00000073);
    assign ebreak = (if_id_instr == 32'h00100073);
    assign mret = (if_id_instr == 32'h30200073);
    assign wfi_req = (if_id_instr == 32'h10500073);
    
    assign csr_addr = if_id_instr[31:20];
    // -------------------------------------------------------------------------
    // Quy tac "lenh nay co THUC SU ghi CSR khong"
    //
    // Truoc day: csr_op = funct3[1:0] cho moi lenh SYSTEM co funct3 != 0. Sai voi
    // csrrs/csrrc (va hai bien the ...i) khi nguon bang 0:
    //
    //     csrr t0, mcycle     ==     csrrs t0, mcycle, x0
    //
    // Theo dac ta, csrrs/csrrc voi rs1 = x0 (hoac uimm = 0) KHONG duoc ghi CSR.
    // Loi cu van ghi lai chinh gia tri vua doc. Voi mcycle hau qua nhin thay
    // ngay: khoi `if (count_en) mcycle <= mcycle + 1` va nhanh ghi CSR cung nam
    // trong mot always, nhanh ghi dung sau nen thang - moi lan DOC mcycle lam
    // MAT mot nhip dem.
    //
    // Phai sua truoc csr_illegal_write, vi tin hieu do dua vao csr_op de phat
    // hien "ghi vao CSR chi doc". Neu khong sua thi mot lenh `csrr t0, cycle`
    // hoan toan hop le se bi bao illegal-instruction.
    //
    // Van giu csr_we = "day la mot lenh CSR" (tang EX dung no de chon
    // alu_result = csr_read_data, va rd van phai nhan gia tri cu). Chi co csr_op
    // bi ep ve 2'b00 khi khong ghi - do la tin hieu tep CSR dung lam write enable.
    // -------------------------------------------------------------------------
    wire csr_src_is_zero = (rs1 == 5'd0);            // rs1 hoac uimm[4:0]: cung truong bit
    wire csr_set_or_clr  = (funct3[1:0] != 2'b01);   // 10 = set, 11 = clear
    wire csr_does_write  = is_system && (funct3 != 3'b000) &&
                           !(csr_set_or_clr && csr_src_is_zero);

    assign csr_we = is_system && (funct3 != 3'b000);
    assign csr_op = csr_does_write ? funct3[1:0] : 2'b00;

    // -------------------------------------------------------------------------
    // KHOAN NO H - bon lenh dac quyen la ngoai le duy nhat khong nam trong bang
    // hop le cua main_control_unit.
    //
    // opcode = 0x73 voi funct3 = 000 khong phan biet duoc bang {opcode, funct3,
    // funct7}: ecall / ebreak / mret / wfi chi khac nhau o instr[31:20], ma
    // main_control_unit khong nhan du 32 bit. Vi vay no de nguyen
    // illegal_instr = 1 cho ca nhom, va o day - noi bon hang so 32 bit VON DA
    // ton tai - ta ha bit do xuong.
    //
    // KHONG chep bon hang so sang control_unit.v: chung se thanh hai ban sao va
    // hai noi de lech nhau.
    //
    // Truoc ban sua nay, MOI ma lenh 0x73 funct3 = 000 khac bon cai tren -
    // `sret` (0x10200073), `dret`, hay bat ky imm12 nao - deu chay im lang nhu
    // NOP thay vi raise illegal-instruction.
    //
    // Phep AND-NOT chinh xac vi sys_priv_ok KEO THEO (opcode = 0x73 && funct3 =
    // 000): no khong the ha nham illegal_instr cua mot opcode khac.
    // -------------------------------------------------------------------------
    wire cu_illegal;
    wire sys_priv_ok = ecall | ebreak | mret | wfi_req;
    assign illegal_instr = cu_illegal & ~sys_priv_ok;

    main_control_unit MCU (
        .opcode(opcode),
        .funct7(funct7),
        .funct3(funct3),
        .rs2(rs2),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc),
        .mem_unsigned(mem_unsigned),
        .alu_op(alu_op),
        .mem_size(mem_size),
        .md_operation(md_operation),
        .fpu_en(fpu_en),
        .f_reg_write(f_reg_write),
        .f_mem_to_reg(f_mem_to_reg),
        .f_mem_write(f_mem_write),
        .f_to_x(f_to_x),
        .x_to_f(x_to_f),
        .fpu_operation(fpu_operation),
        .fence_op(fence_op),
        .illegal_instr(cu_illegal)
    );

    alu_control_unit ACU (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .alu_ctrl(alu_ctrl)
    );
    
endmodule


module execute #(
    parameter ENABLE_MULDIV = 1,
    parameter ENABLE_FPU    = 1,
    parameter ENABLE_CSR    = 1,
    parameter ENABLE_BRANCH = 1
)(
    input clk,
    input reset_n,
    input stall_id_ex,
    input [31:0] alu_in1,
    input [31:0] alu_in2,
    input [3:0] id_ex_alu_ctrl,
    input [2:0] id_ex_funct3,
    input id_ex_branch,
    input [31:0] id_ex_instr,
    input id_ex_lui,
    input id_ex_auipc,
    input id_ex_md_type,
    input [2:0] id_ex_md_operation,
    input [31:0] id_ex_pc_in,
    input [31:0] id_ex_ext_imm,
    input [1:0] id_ex_csr_op,
    input id_ex_csr_we,
    input [31:0] csr_read_data,
    input [4:0] id_ex_rs1,
    input id_ex_fpu_en,
    input [4:0] id_ex_fpu_operation,
    input [31:0] id_ex_read_f_data1,
    input [31:0] id_ex_read_f_data2,
    input id_ex_f_to_x,
    input id_ex_x_to_f,
    output reg [31:0] alu_result,
    output reg branch_taken,
    output reg [31:0] csr_write_data,
    output mf_alu_stall,
    output [31:0] fpu_result_out,
    // R2 - dia chi dich cua JALR, tinh o EX. Xem ghi chu ngay duoi.
    output [31:0] jalr_target
);  

    // -------------------------------------------------------------------------
    // R2 - phep cong JALR chuyen tu tang IF sang tang EX va di qua MOT THANH GHI.
    //
    // Truoc: `instruction_fetch` tinh (alu_in1 + id_ex_ext_imm) & 32'hFFFFFFFE
    // NGAY TRONG chuoi uu tien next-PC, roi ket qua chay thang vao pc_reg. Duong
    // do la critical path #1 cua ban tong hop 2026-09-09:
    //
    //   EX_MEM_ex_mem_csr_addr_reg[9] -> 14 tang logic forward/CSR (719 ps)
    //     -> bo cong 32 bit (1326 ps, ripple MAJ/FA)
    //     -> mux uu tien next-PC + AND5 (315 ps)  -> pc_reg   = 2360 / 2361 ps
    //
    // T1 (2026-09-08) da keo phep cong ra mot `assign` rieng, giup datapath
    // extractor giu duoc no la mot toan tu, nhung KHONG du: no van nam trong
    // cung mot chu ky voi ca mux next-PC.
    //
    // Bay gio: tinh o EX va chot vao EX/MEM. Duong moi la
    //   forward mux (719 ps) -> bo cong (1326 ps) -> EX/MEM flop = ~2045 ps,
    // tuc BO duoc 315 ps cua mux next-PC ra khoi duong toi han, va lan doi huong
    // o chu ky sau chi con flop -> mux -> pc_reg (rat ngan).
    //
    // Gia phai tra: JALR bay gio phan giai o EX/MEM giong het nhanh dieu kien,
    // nen no flush HAI lenh thay vi mot -> them 1 chu ky moi lan JALR. JALR chiem
    // khoang 2-3 % lenh (chu yeu la `ret`), doi lay ~315 ps tren duong toi han.
    //
    // `{sum[31:1], 1'b0}` thay cho `sum & 32'hFFFFFFFE`: cung ngu nghia (spec
    // RISC-V noi tinh xong dia chi roi dat bit 0 ve 0) nhung la DAY NOI thuan,
    // khong ton 32 cong AND ngay sau bo cong.
    // -------------------------------------------------------------------------
    wire [31:0] jalr_sum = alu_in1 + id_ex_ext_imm;
    assign jalr_target = {jalr_sum[31:1], 1'b0};

    wire [31:0] mul_result;
    wire [31:0] div_result;
    wire mul_alu_done;
    wire div_alu_done;
    wire mul_alu_stall;
    wire div_alu_stall;

    wire fpu_stall;
    wire fpu_done;
    wire [31:0] fpu_result;
    
    wire [31:0] fpu_operand_a = id_ex_x_to_f ? alu_in1 : id_ex_read_f_data1;

    generate
        if (ENABLE_MULDIV) begin : gen_muldiv
            multiplier MUL (
                .clk(clk),
                .reset_n(reset_n),
                .stall_id_ex(stall_id_ex),
                .md_type(id_ex_md_type),
                .alu_in1(alu_in1),
                .alu_in2(alu_in2),
                .md_operation(id_ex_md_operation),
                .md_result(mul_result),
                .md_alu_stall(mul_alu_stall),
                .md_alu_done(mul_alu_done)
            );

            divider DIV (
                .clk(clk),
                .reset_n(reset_n),
                .stall_id_ex(stall_id_ex),
                .md_type(id_ex_md_type),
                .alu_in1(alu_in1),
                .alu_in2(alu_in2),
                .md_operation(id_ex_md_operation),
                .md_result(div_result),
                .md_alu_stall(div_alu_stall),
                .md_alu_done(div_alu_done)
            );
        end else begin : no_muldiv
            assign mul_result = 32'd0;
            assign div_result = 32'd0;
            assign mul_alu_stall = 1'b0;
            assign div_alu_stall = 1'b0;
            assign mul_alu_done = 1'b0;
            assign div_alu_done = 1'b0;
        end

        if (ENABLE_FPU) begin : gen_fpu
            fpu_unit FPU (
                .clk(clk),
                .reset_n(reset_n),
                .stall_id_ex(stall_id_ex),
                .fpu_start(id_ex_fpu_en),
                .fpu_op(id_ex_fpu_operation),
                .operand_a(fpu_operand_a),
                .operand_b(id_ex_read_f_data2),
                .result(fpu_result),
                .fpu_stall(fpu_stall),
                .fpu_done(fpu_done)
            );
        end else begin : no_fpu
            assign fpu_result = 32'd0;
            assign fpu_stall = 1'b0;
            assign fpu_done = 1'b0;
        end
    endgenerate

    assign fpu_result_out = fpu_result;
    assign mf_alu_stall = mul_alu_stall || div_alu_stall || fpu_stall;

    wire [31:0] csr_rs1_val = id_ex_funct3[2] ? {27'b0, id_ex_rs1} : alu_in1;

    always @(*) begin
        branch_taken = 1'b0;
        csr_write_data = 32'b0;
        
        if (ENABLE_CSR && id_ex_csr_we) begin
            alu_result = csr_read_data;
            case (id_ex_csr_op)
                2'b01: csr_write_data = csr_rs1_val;
                2'b10: csr_write_data = csr_read_data | csr_rs1_val;
                2'b11: csr_write_data = csr_read_data & ~csr_rs1_val;
                default: csr_write_data = csr_rs1_val;
            endcase
        end else if (ENABLE_FPU && id_ex_f_to_x) begin
            alu_result = fpu_result;
        end else if (id_ex_lui) begin
            alu_result = id_ex_ext_imm;
        end else if (id_ex_auipc) begin
            alu_result = id_ex_pc_in + id_ex_ext_imm;
        end else if (ENABLE_MULDIV && id_ex_md_type) begin
            if (mul_alu_done) begin
                alu_result = mul_result;
            end else if (div_alu_done) begin
                alu_result = div_result;
            end else begin
                alu_result = 32'd0;
            end
        end else begin 
            case (id_ex_alu_ctrl)
                4'b0000: alu_result = alu_in1 & alu_in2;  
                4'b0001: alu_result = alu_in1 | alu_in2;  
                4'b0010: alu_result = alu_in1 + alu_in2;  
                4'b0110: begin 
                    alu_result = alu_in1 - alu_in2;  
                    if (ENABLE_BRANCH && id_ex_branch) begin
                        case (id_ex_funct3)
                            3'b000: branch_taken = (alu_result == 32'd0); 
                            3'b001: branch_taken = (alu_result != 32'd0); 
                            3'b100: branch_taken = ($signed(alu_in1) < $signed(alu_in2)); 
                            3'b101: branch_taken = ($signed(alu_in1) >= $signed(alu_in2)); 
                            3'b110: branch_taken = (alu_in1 < alu_in2); 
                            3'b111: branch_taken = (alu_in1 >= alu_in2); 
                            default: branch_taken = 1'b0;
                        endcase
                    end
                end
                4'b0100: alu_result = alu_in1 ^ alu_in2;  
                4'b0111: begin
                    if ($signed(alu_in1) < $signed(alu_in2)) begin
                        alu_result = 32'd1;
                    end else begin
                        alu_result = 32'd0;
                    end
                end  
                4'b1010: begin
                    if (alu_in1 < alu_in2) begin
                        alu_result = 32'd1;
                    end else begin
                        alu_result = 32'd0;
                    end
                end  
                4'b1000: alu_result = alu_in1 << alu_in2[4:0];  
                4'b1001: alu_result = alu_in1 >> alu_in2[4:0];  
                4'b1011: alu_result = $signed(alu_in1) >>> alu_in2[4:0];  
                default: alu_result = alu_in1 + alu_in2;
            endcase
        end
    end
    
endmodule


module memory_access (
    input wire clk,
    input wire reset_n,
    input [31:0] ex_mem_alu_result,
    input [31:0] ex_mem_mem_write_data,
    input [31:0] ex_mem_instr,
    input ex_mem_mem_write,
    input ex_mem_mem_read,
    // P2c - `fence` da toi tang MEM.  Khong doc, khong ghi: no chi bao D-cache
    // giu core lai cho toi khi store buffer xa het.
    input ex_mem_fence_op,
    // -------------------------------------------------------------------------
    // KHOAN NO C - huy commit TO HOP trong chinh chu ky nhan trap.
    //
    // flush_ex_mem la xoa DONG BO: no chi co hieu luc o suon xung KE TIEP. Ngay
    // trong chu ky trap_enter = 1, lenh dang o MEM van lai to hop
    // dcache_write_req, nen mot `sw` GHI THAT vao bo nho trong khi reg_write cua
    // chinh no bi flush_mem_wb giet. Lenh commit MOT NUA roi chay lai sau mret
    // -> ghi hai lan.
    //
    // Doi chieu: csr_write_en KHONG dinh loi nay vi trong register_file.v no nam
    // trong chuoi `if (trap_enter) ... else if (csr_write_en)`. Ba duong ghi
    // cung o tang MEM, hai duong thieu la chan; day la mot trong hai.
    //
    // Doc KHONG bi chan: doc lai la vo hai voi RAM/cache, va chan no chi keo dai
    // duong to hop ma khong duoc gi.
    // -------------------------------------------------------------------------
    input commit_kill,
    output [31:0] mem_read_data,
    output dcache_read_req,
    output dcache_write_req,
    output dcache_fence,
    output [31:0] dcache_addr,
    output [31:0] dcache_write_data,
    input [31:0] dcache_read_data,

    // -------------------------------------------------------------------------
    // R1b - bat tay hai chu ky cho lenh nguyen tu.
    //
    // `dcache_amo_req`     : lenh o MEM la mot AMO that (doc-sua-ghi). D-cache
    //                        dung tin hieu nay de giu them DUNG mot chu ky.
    // `dcache_amo_capture` : xung mot chu ky tu D-cache, danh dau chu ky ma
    //                        `dcache_read_data` dang mang GIA TRI CU. MEM chot
    //                        no vao `amo_read_q` va tinh AMO o chu ky sau.
    // -------------------------------------------------------------------------
    output dcache_amo_req,
    input  dcache_amo_capture
);

    wire        ex_mem_atomic = (ex_mem_instr[6:0] == 7'b0101111);
    wire [4:0]  amo_op = ex_mem_instr[31:27];
    wire        amo_lr = ex_mem_atomic && (amo_op == 5'b00010);
    wire        amo_sc = ex_mem_atomic && (amo_op == 5'b00011);

    // LR/SC Reservation Set (single-hart, word-granularity)
    reg        reservation_valid;
    reg [31:0] reservation_addr;
    wire sc_success = amo_sc && reservation_valid &&
                      (reservation_addr == ex_mem_alu_result);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reservation_valid <= 1'b0;
            reservation_addr  <= 32'd0;
        end else begin
            if (commit_kill) begin
                // Giu nguyen reservation. Mot `sc.w` bi huy ma van xoa reservation
                // thi lan chay lai sau mret se that bai gia - dac ta cho phep SC
                // that bai ngau nhien nen khong sai, nhung vong lap LR/SC se song
                // vo ich.
                reservation_valid <= reservation_valid;
            end else if (amo_lr && ex_mem_mem_read) begin
                reservation_valid <= 1'b1;
                reservation_addr  <= ex_mem_alu_result;
            end else if (amo_sc) begin
                reservation_valid <= 1'b0;
            end else if (ex_mem_mem_write && !ex_mem_atomic) begin
                reservation_valid <= 1'b0;
            end
        end
    end
    // -------------------------------------------------------------------------
    // R1b - AMO ALU an du lieu tu MOT THANH GHI, khong an thang tu cache.
    //
    // Truoc: `amo_write_data` an truc tiep `dcache_read_data`, ma tin hieu do la
    // ket qua to hop cua ca chuoi trong D-cache (state -> so tag 2-way -> mux
    // way -> read_data_with_size). Cong voi mot bo cong 32 bit va bon bo so sanh
    // 32 bit ngay sau do, roi ket qua lai chay NGUOC ve D-cache. Toan bo chuoi
    // ba module nam trong MOT chu ky CPU - chinh la ho 99/100 duong toi han cua
    // ban tong hop 2026-09-09 (khoi `SUB_TC_OP_1_Y_SUB_TC_OP20_Y_ADD_TC_OP`
    // chiem 463 ps).
    //
    // Bay gio D-cache giu lenh AMO them dung mot chu ky:
    //   chu ky 1 (`dcache_amo_capture` = 1): tra ve gia tri cu -> chot amo_read_q
    //   chu ky 2                           : ALU chay tu FLOP, ket qua ve cache
    // Nho vay ca hai nua deu bat dau hoac ket thuc o mot thanh ghi.
    //
    // Chi lenh AMO that moi ton them chu ky. LR.W (chi doc) va SC.W (chi ghi)
    // khong dat `dcache_amo_req` nen khong bi anh huong.
    // -------------------------------------------------------------------------
    wire amo_rmw = ex_mem_atomic && ex_mem_mem_read && ex_mem_mem_write &&
                   !amo_lr && !amo_sc;
    assign dcache_amo_req = amo_rmw && !commit_kill;

    reg [31:0] amo_read_q;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            amo_read_q <= 32'd0;
        else if (dcache_amo_capture)
            amo_read_q <= dcache_read_data;
    end

    reg [31:0]  amo_write_data;

    always @(*) begin
        case (amo_op)
            5'b00000: amo_write_data = amo_read_q + ex_mem_mem_write_data; // AMOADD.W
            5'b00001: amo_write_data = ex_mem_mem_write_data;              // AMOSWAP.W
            5'b00100: amo_write_data = amo_read_q ^ ex_mem_mem_write_data; // AMOXOR.W
            5'b01100: amo_write_data = amo_read_q & ex_mem_mem_write_data; // AMOAND.W
            5'b01000: amo_write_data = amo_read_q | ex_mem_mem_write_data; // AMOOR.W
            5'b10000: amo_write_data = ($signed(amo_read_q) < $signed(ex_mem_mem_write_data)) ?
                                       amo_read_q : ex_mem_mem_write_data;  // AMOMIN.W
            5'b10100: amo_write_data = ($signed(amo_read_q) > $signed(ex_mem_mem_write_data)) ?
                                       amo_read_q : ex_mem_mem_write_data;  // AMOMAX.W
            5'b11000: amo_write_data = (amo_read_q < ex_mem_mem_write_data) ?
                                       amo_read_q : ex_mem_mem_write_data;  // AMOMINU.W
            5'b11100: amo_write_data = (amo_read_q > ex_mem_mem_write_data) ?
                                       amo_read_q : ex_mem_mem_write_data;  // AMOMAXU.W
            default:  amo_write_data = ex_mem_mem_write_data;              // SC.W write data
        endcase
    end

    // -------------------------------------------------------------------------
    // 2026-09-13 - KET QUA AMO CUNG VAO MOT THANH GHI (bat tay 3 chu ky).
    //
    // Sau R1b, nua thu hai van la: ex_mem_instr (chon phep) -> bo cong/tru dung
    // chung cua bon phep so sanh va AMOADD -> mux -> D-cache lane-align -> chan
    // `wd` cua SRAM.  Run Genus 2026-09-12 15:21: 51/100 duong toi han nhat la ho
    // nay (slack 0 ps o SS, bo cong ~1.9 ns van map ripple).  Va ho do ton tai
    // ca khi ENABLE_A_EXTENSION = 0: mux cu chon theo `ex_mem_atomic`, tin hieu
    // chi phu thuoc bit opcode, nen Genus phai toi uu no nhu mot duong that.
    //
    // Bay gio D-cache giu AMO them mot chu ky nua (dcache.v, amo_cnt):
    //   chu ky 1 (capture) : chot amo_read_q
    //   chu ky 2           : ALU tu flop -> chot amo_wdata_q
    //   chu ky 3           : amo_wdata_q (flop) -> store buffer / SRAM
    // Enable = amo_rmw: ex_mem_* dong bang suot thoi gian stall nen dau vao ALU
    // o chu ky 2 va 3 bang nhau, chot lai o chu ky 3 cung khong doi gia tri.
    //
    // Mux chon theo `amo_rmw` thay vi `ex_mem_atomic`: SC.W van ghi rs2 (nhanh
    // default o tren tra dung ex_mem_mem_write_data), LR.W khong ghi.
    // -------------------------------------------------------------------------
    reg [31:0] amo_wdata_q;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            amo_wdata_q <= 32'd0;
        else if (amo_rmw)
            amo_wdata_q <= amo_write_data;
    end

    // -------------------------------------------------------------------------
    // B1 - DOC cung phai bi commit_kill chan.
    //
    // Comment cu noi "doc lai la vo hai voi RAM/cache, va chan no chi keo dai
    // duong to hop ma khong duoc gi". Dieu do dung khi trap chi den tu
    // ecall/ebreak/ngat. No KHONG con dung khi chinh dia chi la thu gay trap:
    //
    //   lw a0, 1(s0)   <- misaligned, hoac tro vao vung khong map
    //   -> neu van phat cpu_read_req thi cache keo dcache_stall len ca chuc chu
    //      ky, `mem_freeze = dcache_stall` chan flush_trap, va trap bi HOAN lai
    //      cho toi khi giao dich rac chay xong. Voi dia chi khong map thi phai
    //      doi ca timeout cua interconnect.
    //
    // Khong tao vong to hop: trap_enter chi phu thuoc thanh ghi ex_mem_* va cac
    // chan ngat, khong phu thuoc dcache_stall.
    //
    // An toan voi FSM cua cache: o LOOKUP, `cpu_read_req` ha lam FSM roi vao
    // nhanh else -> next_state = IDLE, khong treo. O AR_REQ/R_WAIT/DONE, FSM
    // khong nhin cpu_read_req de tien state nen giao dich dang bay van ket thuc
    // binh thuong.
    // -------------------------------------------------------------------------
    assign dcache_read_req = ex_mem_mem_read & ~commit_kill;
    // SC.W: only write if reservation matches
    assign dcache_write_req = commit_kill ? 1'b0 :
                              amo_sc      ? sc_success : ex_mem_mem_write;
    // P2c - chan bang commit_kill dung nhu dcache_write_req, va vi mot ly do
    // KHAC: fence keo dcache_stall len cao cho toi khi buffer xa xong.  Neu
    // khong ha no trong chinh chu ky nhan trap thi mot fence DA BI HUY van giu
    // ca pipeline lai them may chuc chu ky truoc khi vao mtvec - do tre trap
    // ma khong ai giai thich duoc.  flush_ex_mem la xoa DONG BO, no chi co
    // hieu luc o suon xung ke tiep, nen mot minh no khong du.
    assign dcache_fence     = commit_kill ? 1'b0 : ex_mem_fence_op;
    assign dcache_addr = ex_mem_alu_result;
    assign dcache_write_data = amo_rmw ? amo_wdata_q : ex_mem_mem_write_data;
    // SC.W result: 0 = success, 1 = failure (per RISC-V spec)
    //
    // R1b - voi AMO that, gia tri tra ve rd la gia tri CU, ma o chu ky thu hai
    // `dcache_read_data` khong con giu no nua -> phai lay tu `amo_read_q`.
    // LR.W khong phai amo_rmw nen van doc thang tu cache nhu cu.
    assign mem_read_data = amo_sc  ? (sc_success ? 32'd0 : 32'd1) :
                           amo_rmw ? amo_read_q :
                                     dcache_read_data;
    
endmodule


module write_back (
    input [31:0] mem_wb_mem_read_data,
    input [31:0] mem_wb_alu_result,
    input [31:0] mem_wb_pc_plus_4,
    input mem_wb_mem_to_reg,
    input mem_wb_jal,
    output [31:0] mem_wb_write_data
);

    assign mem_wb_write_data = (mem_wb_jal) ? mem_wb_pc_plus_4 :
                                mem_wb_mem_to_reg ? mem_wb_mem_read_data : mem_wb_alu_result;
                                
endmodule
