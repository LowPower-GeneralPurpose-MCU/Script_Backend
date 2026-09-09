`timescale 1ns / 1ps

// Scalar RV32IMAC pipeline.
//
// The old top-level was a two-lane superscalar shell with ROB/Tomasulo hooks.
// This replacement keeps the public ports compatible with the existing project,
// but only issues lane 0. Lane 1 fetch/cache ports are tied off.
module riscv_pipeline #(
    parameter ENABLE_TOMASULO_INTEGER = 0,
    // -------------------------------------------------------------------------
    // F6 - 0: `ecall` trap vao mtvec roi CHAY TIEP (dung chuan, mac dinh).
    //      1: giu hanh vi cu "dung han khi gap ecall" cho testbench nghiem thu cu.
    //
    // Voi gia tri cu (khong co tham so, luon dung han) thi `riscv_done` len 1 o
    // lan `ecall` DAU TIEN, va vi moi thanh ghi pipeline lan pc_reg deu co dieu
    // kien `riscv_start && !riscv_done`, ca loi DONG BANG VINH VIEN. Do la di
    // san cua testbench lot vao RTL production: mot syscall lam chet chip.
    // -------------------------------------------------------------------------
    parameter HALT_ON_ECALL = 0
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        riscv_start,
    input  wire        meip_i,
    input  wire        msip_i,
    input  wire        mtip_i,
    input  wire [31:0] reset_vector_in,
    output reg         riscv_done,

    // ICache interface
    output wire        icache_read_req,
    output wire [31:0] icache_addr,
    input  wire [31:0] icache_read_data,
    input  wire        icache_hit,
    input  wire        icache_stall,
    input  wire        icache_error,   // B3 - loi bus khi lay lenh -> mcause 1
    output wire        icache_read_req_lane1,
    output wire [31:0] icache_addr_lane1,
    input  wire [31:0] icache_read_data_lane1,
    input  wire        icache_hit_lane1,
    input  wire        icache_stall_lane1,

    // DCache interface
    output wire        dcache_read_req,
    output wire        dcache_write_req,
    output wire [31:0] dcache_addr,
    output wire [31:0] dcache_write_data,
    input  wire [31:0] dcache_read_data,
    // R1b - bat tay hai chu ky cho AMO. Xem ghi chu trong pipeline_stage.v.
    output wire        dcache_amo_req,
    input  wire        dcache_amo_capture,
    input  wire        dcache_hit,
    input  wire        dcache_stall,
    input  wire        dcache_error,   // B2 - loi bus khi truy cap du lieu -> mcause 5/7

    output wire [1:0]  mem_size_top,
    output wire        mem_unsigned_top,

    output wire        wfi_sleep_out,

    // Debug Module Interface
    input  wire        dbg_halt_req,
    input  wire        dbg_resume_req,
    output wire        dbg_halted,

    input  wire [15:0] dbg_reg_read_addr,
    output wire [31:0] dbg_reg_read_data,
    input  wire        dbg_reg_write_en,
    input  wire [15:0] dbg_reg_write_addr,
    input  wire [31:0] dbg_reg_write_data
);

    localparam ROB_TAG_W = 1;
    localparam [31:0] NOP = 32'h00000013;

    // Lane 1 is intentionally disabled in scalar mode.
    assign icache_read_req_lane1 = 1'b0;
    assign icache_addr_lane1     = 32'd0;

    // =========================================================================
    // IF wires and PC
    // =========================================================================
    wire [31:0] pc_in;
    wire [31:0] pc_out;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_plus_8_unused;
    wire [31:0] instr;
    wire [31:0] instr_lane1_unused;
    wire        if_lane1_req_unused;
    wire [31:0] if_lane1_addr_unused;

    reg [31:0] pc_reg;
    reg        flush_temp;

    // =========================================================================
    // IF/ID
    // =========================================================================
    wire [31:0] if_id_instr;
    wire [31:0] if_id_pc_plus_4;
    wire [31:0] if_id_pc_in;
    wire        if_id_predict_taken;
    wire        if_id_btb_hit;

    // =========================================================================
    // ID
    // =========================================================================
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] read_data1_temp;
    wire [31:0] read_data2_temp;
    wire [31:0] ext_imm;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [4:0]  rd;
    wire [2:0]  funct3;
    wire [6:0]  opcode;
    wire [6:0]  funct7;
    wire [31:0] jal_target;
    wire [31:0] branch_target;
    wire        reg_write;
    wire        alu_src;
    wire        mem_write;
    wire        mem_read;
    wire        mem_to_reg;
    wire        branch;
    wire        jal;
    wire        jalr;
    wire        lui;
    wire        auipc;
    wire        mem_unsigned;
    wire [1:0]  alu_op;
    wire [1:0]  mem_size;
    wire [3:0]  alu_ctrl;
    wire        ecall;
    wire        ebreak;
    wire        mret;
    wire [11:0] csr_addr;
    wire [1:0]  csr_op;
    wire        csr_we;
    wire        md_type;
    wire [2:0]  md_operation;
    wire        wfi_req_internal;
    wire        fpu_en;
    wire        f_reg_write;
    wire        f_mem_to_reg;
    wire        f_mem_write;
    wire        f_to_x;
    wire        x_to_f;
    wire [4:0]  fpu_operation;

    // =========================================================================
    // ID/EX
    // =========================================================================
    wire [31:0] id_ex_pc_plus_4;
    wire [31:0] id_ex_pc_in;
    wire [31:0] id_ex_instr;
    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;
    wire [31:0] id_ex_ext_imm;
    wire [4:0]  id_ex_rs1;
    wire [4:0]  id_ex_rs2;
    wire [4:0]  id_ex_rd;
    wire [2:0]  id_ex_funct3;
    wire        id_ex_reg_write;
    wire        id_ex_alu_src;
    wire        id_ex_mem_write;
    wire        id_ex_mem_read;
    wire        id_ex_mem_to_reg;
    wire        id_ex_branch;
    wire        id_ex_jal;
    wire        id_ex_jalr;
    wire        id_ex_lui;
    wire        id_ex_auipc;
    wire        id_ex_mem_unsigned;
    wire [1:0]  id_ex_mem_size;
    wire [3:0]  id_ex_alu_ctrl;
    wire [31:0] id_ex_branch_target;
    wire [31:0] id_ex_jal_target;
    wire        id_ex_predict_taken;
    wire        id_ex_btb_hit;
    wire        id_ex_ecall;
    wire        id_ex_ebreak;
    wire        id_ex_mret;
    wire [11:0] id_ex_csr_addr;
    wire [1:0]  id_ex_csr_op;
    wire        id_ex_csr_we;
    wire        id_ex_md_type;
    wire [2:0]  id_ex_md_operation;
    wire        id_ex_fpu_en;
    wire        id_ex_f_reg_write;
    wire        id_ex_f_mem_to_reg;
    wire        id_ex_f_mem_write;
    wire        id_ex_f_to_x;
    wire        id_ex_x_to_f;
    wire [4:0]  id_ex_fpu_operation;
    wire [31:0] id_ex_read_f_data1;
    wire [31:0] id_ex_read_f_data2;
    wire [ROB_TAG_W-1:0] id_ex_rob_tag;
    wire        id_ex_rob_valid;

    // =========================================================================
    // EX
    // =========================================================================
    wire [31:0] alu_in1;
    wire [31:0] alu_in2;
    wire [31:0] mem_write_data;
    wire [31:0] csr_write_data_ex;
    wire [31:0] fpu_in1;
    wire [31:0] fpu_in2;
    wire [31:0] alu_result;
    wire        branch_taken;
    wire        mf_alu_stall;
    wire [31:0] fpu_result_out;

    // =========================================================================
    // EX/MEM
    // =========================================================================
    wire [31:0] ex_mem_instr;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_mem_write_data;
    wire [31:0] ex_mem_branch_target;
    wire [31:0] ex_mem_pc_plus_4;
    wire [31:0] ex_mem_pc_in;
    wire [4:0]  ex_mem_rd;
    wire        ex_mem_mem_write;
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_to_reg;
    wire        ex_mem_branch;
    wire        ex_mem_branch_taken;
    wire        ex_mem_jal;
    wire        ex_mem_mem_unsigned;
    wire        ex_mem_reg_write;
    wire [1:0]  ex_mem_mem_size;
    wire        ex_mem_predict_taken;
    wire        ex_mem_btb_hit;
    wire        ex_mem_ecall;
    wire        ex_mem_ebreak;
    wire        ex_mem_mret;
    wire [11:0] ex_mem_csr_addr;
    wire [1:0]  ex_mem_csr_op;
    wire        ex_mem_csr_we;
    wire [31:0] ex_mem_csr_write_data;
    wire [31:0] ex_mem_fpu_result;
    wire [31:0] ex_mem_f_store_data;
    wire        ex_mem_f_reg_write;
    wire        ex_mem_f_mem_to_reg;
    wire        ex_mem_f_mem_write;
    wire [ROB_TAG_W-1:0] ex_mem_rob_tag;
    wire        ex_mem_rob_valid;
    wire [31:0] final_mem_write_data;
    wire [31:0] mem_read_data;

    // =========================================================================
    // MEM/WB
    // =========================================================================
    wire [31:0] mem_wb_mem_read_data;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_pc_plus_4;
    wire        mem_wb_mem_to_reg;
    wire        mem_wb_reg_write;
    wire        mem_wb_jal;
    wire [4:0]  mem_wb_rd;
    wire        mem_wb_ecall;
    wire [31:0] mem_wb_fpu_result;
    wire        mem_wb_f_reg_write;
    wire        mem_wb_f_mem_to_reg;
    wire [ROB_TAG_W-1:0] mem_wb_rob_tag;
    wire        mem_wb_rob_valid;
    wire [31:0] wb_write_data;
    wire [31:0] wb_f_write_data;

    // =========================================================================
    // CSR/debug/branch/stall
    // =========================================================================
    wire [31:0] mie_val;
    wire        mstatus_mie_val;
    wire [31:0] mtvec_pc;
    wire [31:0] mepc_pc;
    wire [31:0] csr_read_data_raw;
    wire [31:0] csr_read_data_fwd;
    wire [31:0] csr_dbg_read_data;
    wire [31:0] rf_dbg_read_data;
    wire [31:0] frf_dbg_read_data;
    wire [31:0] dpc_out;
    wire [31:0] dcsr_out;

    wire        predict_taken;
    wire        bpu_correct;
    wire        btb_hit;
    wire        actual_taken;
    wire [31:0] predict_target;

    wire        load_use_stall;
    wire        flush_branch;
    wire        flush_jal;
    // R2 - JALR phan giai o EX/MEM, nen no co tin hieu flush rieng hanh xu y het
    // `flush_branch`. Xem ghi chu R2 trong pipeline_stage.v.
    wire        flush_jalr;
    wire        ex_mem_jalr;
    wire [31:0] ex_mem_jalr_target;
    wire [31:0] jalr_target;
    wire        flush_trap;
    wire        stall_IF;
    wire        stall_ID;
    wire        stall_EX;
    wire        stall_MEM;
    wire        stall_WB;
    wire        is_sleeping_internal;

    // ---- day "lenh that, khong phai bong bong" chay suot ba tang ----
    wire        if_id_valid;
    wire        id_ex_valid;
    wire        ex_mem_valid;

    // ---- illegal-instruction: ID -> EX -> MEM ----
    // ---- B3: instruction access fault chay IF -> ID -> EX -> MEM ----
    wire        instr_fault;
    wire        if_id_fault;
    wire        id_ex_fault;
    wire        ex_mem_fault;      // MEM: nguon cua trap_instr_access

    wire        illegal_instr;     // ID:  ma lenh khong ton tai
    wire        id_ex_illegal;     // EX
    wire        ex_mem_illegal;    // MEM: nguon cua trap_illegal
    wire        csr_illegal_write; // MEM: ghi vao CSR chi doc
    wire        csr_illegal_addr;  // MEM: truy cap CSR khong hien thuc (C5/C6)

    // ---- F3: dang lay nua thu nhat cua lenh 32 bit vat bien ----
    wire        if_realign_stall;

    // =========================================================================
    // Trap and interrupt logic
    // =========================================================================
    wire wake_interrupt = (meip_i & mie_val[11]) |
                          (msip_i & mie_val[3])  |
                          (mtip_i & mie_val[7]);

    // -------------------------------------------------------------------------
    // KHOAN NO C - ngat duoc quy cho lenh dang o EX/MEM, KHONG cho lenh o tang IF.
    //
    // Truoc day: mepc = pc_in (PC tang IF) trong khi flush_trap xoa CA BON thanh
    // ghi pipeline. Bon lenh dang bay trong ID, EX, MEM, WB bi huy, nhung mepc
    // tro toi mot lenh TRE HON tat ca chung - mret quay ve SAU chung. Mot ngat
    // ngoai lang le nuot toi bon lenh, khong dau vet. Voi RTOS / ISR dinh ky thi
    // chuong trinh mat lenh lien tuc.
    //
    // Bay gio ngat duoc doi xu nhu mot ngoai le quy cho lenh o EX/MEM, tai dung
    // nguyen duong da chay dung cho ecall/ebreak: mepc = ex_mem_pc_in, lenh do bi
    // huy va CHAY LAI sau mret; moi lenh tre hon van con trong pipeline nen cung
    // chay lai.
    //
    // Dieu kien ex_mem_valid la BAT BUOC: flush khong xoa ex_mem_pc_in, nen nhan
    // ngat khi EX/MEM la bong bong se cho mepc tro vao lenh DA RETIRE -> chay hai
    // lan. Hoan ngat lai vai chu ky la vo hai (meip/msip/mtip la MUC, khong phai
    // xung), va khong be tac: bong bong chi sinh ra tu flush, ma sau moi flush
    // luon co lenh that di qua. WFI co duong danh thuc RIENG (wake_interrupt,
    // khong qua mstatus.MIE).
    // -------------------------------------------------------------------------
    wire irq_ok          = ex_mem_valid & mstatus_mie_val;
    wire is_external_irq = meip_i & mie_val[11] & irq_ok;
    wire is_software_irq = msip_i & mie_val[3]  & irq_ok;
    wire is_timer_irq    = mtip_i & mie_val[7]  & irq_ok;
    wire trap_interrupt  = is_external_irq | is_software_irq | is_timer_irq;

    // -------------------------------------------------------------------------
    // V5 - illegal-instruction (mcause = 2).
    //
    // Hai nguon, ca hai deu la thuoc tinh cua lenh dang o EX/MEM nen chung KHONG
    // the xung dot ve mepc/mtval:
    //   ex_mem_illegal    : ma lenh khong ton tai (decoder dat, di theo pipeline)
    //   csr_illegal_write : csrrw/csrrs/csrrc ghi vao CSR chi doc (csr[11:10]=11)
    //
    // Truoc ban sua nay KHONG co illegal-instruction nao: nhanh `default` rong
    // cua main_control_unit khien moi opcode la chay im lang nhu NOP - khong the
    // debug firmware, va mot ma lenh hong se troi qua ma khong ai biet.
    // -------------------------------------------------------------------------
    // C5/C6 bo sung nguon thu ba: truy cap CSR khong hien thuc (ke ca nhom debug
    // 0x7B0-0x7B2 khi khong o Debug Mode). Cung tang EX/MEM nen khong xung dot
    // mepc/mtval voi hai nguon kia.
    wire ex_mem_is_mem   = ex_mem_mem_read | ex_mem_mem_write;

    wire trap_illegal    = csr_illegal_write | csr_illegal_addr | ex_mem_illegal;

    // -------------------------------------------------------------------------
    // C1 - ACCESS FAULT (mcause 1 / 5 / 7).
    //
    // Hai nguon, sinh o hai tang khac nhau nhung deu NHAN o tang MEM:
    //   ex_mem_fault : loi khi LAY LENH nay. I-cache bao luc fetch, bit di theo
    //                  pipeline (B3) nen toi MEM van gan dung lenh do.
    //   dcache_error : loi khi TRUY CAP DU LIEU. Xung mot chu ky, dung chu ky
    //                  dcache_stall ha, nen lenh van con o MEM.
    //
    // dcache_error da duoc D-cache rang buoc bang `cpu_addr == req_addr` nen no
    // khong the len cho mot lenh da bi flush. Van AND them ex_mem_valid de bong
    // bong khong sinh trap - cung ly do voi irq_ok (khoan no C).
    // -------------------------------------------------------------------------
    wire trap_instr_access = ex_mem_valid & ex_mem_fault;
    wire trap_data_access  = ex_mem_valid & ex_mem_is_mem & dcache_error;
    wire trap_st_access    = trap_data_access &  ex_mem_mem_write;
    wire trap_ld_access    = trap_data_access & ~ex_mem_mem_write;

    // -------------------------------------------------------------------------
    // C2 - LOAD / STORE ADDRESS MISALIGNED (mcause 4 / 6).
    //
    // Truoc ban sua nay KHONG co kiem tra can le nao: `lw a0, 1(s0)` di thang
    // vao cache, cache lay word chua dia chi do va tra ve gia tri SAI. Khong
    // exception nao de RTOS bat, khong dau vet nao de debug.
    //
    // mem_size: 00 = byte, 01 = halfword, 10 = word (xem control_unit.v).
    // Byte thi khong bao gio lech duoc nen khong co nhanh cho no.
    //
    // Dieu kien (ex_mem_mem_read | ex_mem_mem_write) la BAT BUOC du mem_size
    // mac dinh 2'b00: no lam y dinh ro rang va khong phu thuoc vao gia tri mac
    // dinh cua mot tin hieu o module khac.
    //
    // ex_mem_valid loai bong bong - cung ly do voi irq_ok (khoan no C).
    // -------------------------------------------------------------------------
    wire mem_ms_word     = (ex_mem_mem_size == 2'b10) && (ex_mem_alu_result[1:0] != 2'b00);
    wire mem_ms_half     = (ex_mem_mem_size == 2'b01) &&  ex_mem_alu_result[0];
    wire mem_misaligned  = ex_mem_valid & ex_mem_is_mem & (mem_ms_word | mem_ms_half);

    // Store thang khi mot lenh vua doc vua ghi (AMO). A dang tat nen truong hop
    // do khong xay ra, nhung viet ro de khong phu thuoc vao dieu do.
    wire trap_st_misaligned = mem_misaligned &  ex_mem_mem_write;
    wire trap_ld_misaligned = mem_misaligned & ~ex_mem_mem_write;
    wire trap_misaligned    = trap_ld_misaligned | trap_st_misaligned;

    wire trap_enter      = ex_mem_ecall | ex_mem_ebreak | trap_interrupt |
                           trap_illegal | trap_misaligned |
                           trap_instr_access | trap_data_access;
    wire mret_exec       = ex_mem_mret;

    // Thu tu uu tien theo bang "Synchronous exception priority" cua dac ta:
    // ngat truoc moi ngoai le; roi illegal / ebreak / ecall (ba cai loai tru
    // nhau nen thu tu giua chung khong quan trong); roi MISALIGNED.
    wire [31:0] trap_cause = (trap_interrupt && is_external_irq) ? 32'h8000000b :
                             (trap_interrupt && is_software_irq) ? 32'h80000003 :
                             (trap_interrupt && is_timer_irq)    ? 32'h80000007 :
                             ex_mem_ecall                        ? 32'd11       :
                             ex_mem_ebreak                       ? 32'd3        :
                             trap_instr_access                   ? 32'd1        :
                             trap_illegal                        ? 32'd2        :
                             trap_st_misaligned                  ? 32'd6        :
                             trap_ld_misaligned                  ? 32'd4        :
                             trap_st_access                      ? 32'd7        :
                             trap_ld_access                      ? 32'd5        : 32'd0;

    // Mot nguon duy nhat cho ca ngoai le lan ngat - xem ghi chu khoan no C.
    wire [31:0] trap_pc_value = ex_mem_pc_in;

    // -------------------------------------------------------------------------
    // C3 - dia chi vector cua trap.
    //
    // mtvec[1:0] la truong MODE (WARL, ep o register_file.v):
    //   0 = DIRECT   : moi trap vao BASE
    //   1 = VECTORED : INTERRUPT vao BASE + 4*cause, EXCEPTION van vao BASE
    //
    // Tinh o day thay vi trong instruction_fetch vi day la noi da co trap_cause;
    // IF chi can nhan mot dia chi da san sang va khong phai doi.
    //
    // Bo cong nay nam trong cone cua nhanh `trap_enter` o mux PC - mot cone
    // RIENG, ngan, lay tu thanh ghi ex_mem_*. No khong dung vao duong toi han
    // seq_pc (xem P1 trong CORE_FIX_PLAN.md).
    //
    // cause[4:0] la du: 5 bit phu het 0-31, va mtvec_base da can le 4 byte nen
    // phep cong chi cham toi bit [6:2] - mot bo dem 5 bit, khong phai adder 32 bit.
    // -------------------------------------------------------------------------
    wire [31:0] mtvec_base   = {mtvec_pc[31:2], 2'b00};
    wire        mtvec_vector = mtvec_pc[0];
    wire [31:0] trap_vector  = (mtvec_vector && trap_cause[31])
                             ? (mtvec_base + {25'd0, trap_cause[4:0], 2'b00})
                             : mtvec_base;

    // mtval cua illegal-instruction mang chinh ma lenh gay loi (dac ta cho phep).
    // Truoc day mtval luon la 0, nen handler khong co cach nao biet lenh nao sai.
    // mtval cua misaligned mang DIA CHI gay loi (dac ta cho phep, va day la thu
    // duy nhat handler dung duoc). Uu tien phai KHOP voi trap_cause o tren:
    // trap_illegal thang trap_misaligned.
    // Uu tien PHAI khop tung dong voi trap_cause o tren.
    //   mcause 1       -> mtval = PC gay loi
    //   mcause 2       -> mtval = ma lenh
    //   mcause 4/5/6/7 -> mtval = dia chi gay loi
    wire [31:0] trap_val_value = trap_instr_access ? ex_mem_pc_in      :
                                 trap_illegal      ? ex_mem_instr      :
                                 trap_misaligned   ? ex_mem_alu_result :
                                 trap_data_access  ? ex_mem_alu_result : 32'd0;

    // =========================================================================
    // Stall/flush policy
    // =========================================================================
    // -------------------------------------------------------------------------
    // KHOAN NO D - stall bo nho DONG BANG TOAN BO mat phang dieu khien.
    //
    // Trong moi thanh ghi pipeline, `flush` duoc kiem TRUOC `stall`, nen khi hai
    // tin hieu cung len thi flush THANG. Voi bo nho tre 0 chu ky dieu do vo hai;
    // bat do tre len thi cac cap sau deu that:
    //
    //   flush_id_ex (load-use)  x  stall_id_ex (dcache)
    //       lw  a0, 0(s0)   <- o MEM, D$ miss, dcache_stall = 1 hang chuc chu ky
    //       lw  a1, 0(s1)   <- o EX
    //       add a2, a1, x0  <- o ID  => load_use_stall = 1 => flush_id_ex = 1
    //       Lenh o EX khong the di tiep vi EX/MEM dong bang, va ID/EX bi XOA.
    //       `lw a1` BIEN MAT khoi chuong trinh.
    //
    //   flush_ex_mem (mf_alu_stall)  x  stall_ex_mem (dcache)
    //       Bo nhan bom bong bong vao EX/MEM moi chu ky no chay. Neu MEM dang giu
    //       mot lenh CHO BO NHO thi lenh do bi xoa truoc khi lay duoc du lieu.
    //
    // Quy tac dung: mot stall TOAN CUC (bo nho) phai THANG MOI hanh dong cuc bo
    // (bong bong load-use, bong bong bo nhan, doi huong nhanh, trap). Pipeline
    // khong nhuc nhich thi khong co gi de bom bong bong vao, cung khong co gi de
    // xoa.
    //
    // An toan vi moi nguon flush deu la MUC lay tu trang thai dang dong bang, nen
    // chung GIU NGUYEN suot thoi gian dong bang va co hieu luc ngay khi no het:
    //     flush_branch / flush_trap  <- ex_mem_*        (dong bang)
    //     flush_jal / load_use_stall <- id_ex_*, if_id_* (dong bang)
    // Ngoai le duy nhat la trap_interrupt lay tu chan ben ngoai - nhung ngat la
    // MUC chu khong phai xung nen hoan lai vai chu ky la vo hai.
    //
    // Khong be tac: dcache_stall luon ha xuong sau do tre bo nho. Va neu lenh o
    // MEM la mot `sw` bi commit_kill chan thi yeu cau ghi rut xuong, giao dich
    // ket thuc, stall ha - trap dien ra ngay sau do.
    // -------------------------------------------------------------------------
    wire mem_freeze = dcache_stall;

    // F4 - cong lenh chi mo khi that su dang lay lenh.
    wire fetch_enable = ~(stall_IF | is_sleeping_internal | dbg_halted);

    wire stall_if_id  = dcache_stall | mf_alu_stall | load_use_stall | stall_ID;

    // KHOAN NO R - mot lan lay lenh chi SINH RA lenh that khi cong MO va bo nho
    // SAN SANG. Tang IF da co dung khai niem do (fetch_valid); o day gop lai
    // thanh DUNG mot tin hieu, khop tung chu voi no. Truoc day chi nua sau
    // (icache_stall) duoc bom bong bong; nua truoc (~fetch_enable) thi khong -
    // nen moi lan halt / ngu, IF/ID van CHOT mot NOP gia voi if_id_valid = 1 va
    // no duoc dem nhu mot lenh that.
    wire if_fetch_bubble = ~fetch_enable | icache_stall;

    // -------------------------------------------------------------------------
    // R2 - `flush_jalr` di kem `flush_branch` o IF/ID va ID/EX, nhung KHONG o
    // EX/MEM.
    //
    // Khi JALR nam o EX/MEM va doi huong: IF/ID giu lenh JALR+4 va ID/EX giu
    // lenh JALR+8, ca hai deu la duong sai -> phai xoa. Nhung EX/MEM giu CHINH
    // LENH JALR, no con phai ghi `ra`; xoa no o day la thua.
    //
    // Do bang tb firmware that (`rtl/tests/run_soc_sim.sh fw`, cung anh ROM):
    //     baseline (JALR o ID/EX)                     t = 1 528 046 000
    //     R2 co flush_jalr trong flush_ex_mem         t = 2 830 376 000  (+85 %)
    //     R2 bo flush_jalr khoi flush_ex_mem          t = 1 701 796 000  (+11.4 %)
    // Term thua do mot minh dat 74 diem phan tram. Dung them lai.
    //
    // +11.4 % con lai la gia THAT cua viec JALR chuyen tu 1 bong bong sang 2,
    // doi lay ~315 ps tren duong toi han (bo mux next-PC ra khoi duong cua bo
    // cong JALR). Firmware nay goi ham rat day nen day la can tren, khong phai
    // con so trung binh.
    // -------------------------------------------------------------------------
    wire flush_if_id  = ~mem_freeze &
                        (flush_trap | flush_branch | flush_jalr | flush_jal |
                         (if_fetch_bubble  & !stall_if_id) |
                         (if_realign_stall & !stall_if_id));
    wire stall_id_ex  = dcache_stall | mf_alu_stall | stall_EX;
    wire flush_id_ex  = ~mem_freeze &
                        (flush_trap | flush_branch | flush_jalr | load_use_stall |
                         (flush_jal & !stall_id_ex));
    wire stall_ex_mem = dcache_stall | stall_MEM;
    wire flush_ex_mem = ~mem_freeze & (flush_trap | flush_branch | mf_alu_stall);
    wire stall_mem_wb = dcache_stall | stall_WB;
    wire flush_mem_wb = ~mem_freeze & flush_trap;

    // -------------------------------------------------------------------------
    // KHOAN NO I - minstret phai dem LENH RETIRE, khong dem chu ky.
    //
    // Truoc day `instret_en = !dbg_halted`, dung y het `count_en` cua mcycle.
    // Nghia la minstret KHONG phai bo dem lenh - no la mot BAN SAO cua mcycle:
    // moi phep do IPC, moi profiler, moi con so CoreMark/Dhrystone doc ra so chu
    // ky chu khong phai so lenh.
    //
    // Diem retire cua loi 5 tang nay la RANH GIOI EX/MEM -> MEM/WB. Ba dieu kien,
    // moi dieu kien loai bo dung mot thu:
    //   ex_mem_valid   loai BONG BONG (load-use, mf_alu_stall, flush nhanh).
    //   !stall_mem_wb  loai DEM LAI - khi stall, ex_mem_valid giu 1 nhieu chu ky.
    //                  Day cung la dieu kien lam minstret BAT BIEN voi do tre
    //                  bo nho.
    //   !trap_enter    loai LENH BAY. Theo dac ta, lenh gay trap KHONG retire.
    //                  Dung trap_enter chu KHONG dung flush_trap: flush_trap con
    //                  bao gom mret_exec, ma `mret` la lenh binh thuong - no CO
    //                  retire.
    // -------------------------------------------------------------------------
    wire instret_pulse = ex_mem_valid & ~stall_mem_wb & ~trap_enter &
                         riscv_start  & ~riscv_done;

    assign pc_in = pc_reg;
    assign mem_size_top     = ex_mem_mem_size;
    assign mem_unsigned_top = ex_mem_mem_unsigned;
    assign wfi_sleep_out    = is_sleeping_internal;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // The SYSCTRL reset vector itself resets to 0x0001_0000.  Keep the
            // asynchronous reset value constant so synthesis and simulation
            // cannot disagree when reset_vector_in changes near reset release.
            pc_reg <= 32'h0001_0000;
        end else if (riscv_start && !riscv_done) begin
            if (dbg_halted && !dbg_resume_req) begin
                pc_reg <= dpc_out;
            end else if ((flush_trap || flush_branch || flush_jalr || flush_jal) && !dcache_stall) begin
                // Doi huong PC cung phai CHO bo nho: neu khong thi PC nhay di trong
                // khi IF/ID dang dong bang (mem_freeze chan flush), va lenh o dich
                // bi bo qua.
                pc_reg <= pc_out;
            // KHOAN NO R - PC chi duoc tien khi THAT SU co mot lan lay lenh.
            //
            // Truoc day dieu kien la `!stall_IF`, mot BAN SAO GAN DUNG cua
            // `fetch_enable`. Hai cai lech nhau dung mot chu ky o lan resume:
            //     resume_pulse = dbg_halted_reg && dbg_resume_req
            //     stall_IF     = ((dbg_halted_reg || ...) && !resume_pulse) || ...
            //     fetch_enable = ~(stall_IF | is_sleeping | dbg_halted)
            // Trong chu ky co resume_pulse, stall_IF da ha nhung dbg_halted VAN
            // con 1 (no chi xoa o canh sau), nen fetch_enable van bang 0. Ket qua:
            // pc_reg TIEN LEN trong khi khong lenh nao duoc lay - lenh o dia chi
            // do bi NHAY QUA. Dung mot lenh moi lan halt.
            //
            // Dung fetch_enable truc tiep: no la nguon duy nhat quyet dinh "chu ky
            // nay co lay lenh khong", va da duoc dung o ca ba cho khac
            // (icache_read_req, fetch_valid cua tang IF, if_fetch_bubble).
            end else if (fetch_enable && !load_use_stall && !if_realign_stall &&
                         !icache_stall && !dcache_stall && !mf_alu_stall) begin
                // F3: if_realign_stall giu PC dung yen trong nhip lay nua thu nhat,
                // de nhip sau tang IF van con pc_in de tinh dia chi word ke tiep.
                pc_reg <= pc_out;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            flush_temp <= 1'b0;
        end else if (riscv_start && !riscv_done && !dcache_stall) begin
            // Cung ly do: flush_temp la ban tre mot nhip cua lan doi huong. Neu no
            // chay trong luc pipeline dong bang thi no het han TRUOC khi lan doi
            // huong that su xay ra.
            flush_temp <= flush_branch || flush_jalr || flush_jal || flush_trap;
        end
    end

    // =========================================================================
    // IF
    // =========================================================================
    instruction_fetch IF (
        .reset_n(reset_n),
        .flush_temp(flush_temp),
        .trap_enter(trap_enter),
        .mret_exec(mret_exec),
        .reset_vector_in(reset_vector_in),
        .mtvec_in(trap_vector),   // C3 - da tinh ca che do vectored
        .mepc_in(mepc_pc),
        .ex_mem_branch_target(ex_mem_branch_target),
        .id_ex_jal_target(id_ex_jal_target),
        .pc_in(pc_in),
        .ex_mem_pc_in(ex_mem_pc_in),
        .ex_mem_pc_plus_4(ex_mem_pc_plus_4),
        .ex_mem_jalr(ex_mem_jalr),
        .ex_mem_jalr_target(ex_mem_jalr_target),
        .id_ex_jal(id_ex_jal),
        .btb_hit(btb_hit),
        .predict_taken(predict_taken),
        .actual_taken(actual_taken),
        .bpu_correct(bpu_correct),
        .predict_target(predict_target),
        .fetch_two_valid(1'b0),

        // F3/F4 - FSM ghep nua lenh va cong lay lenh
        .clk(clk),
        .icache_stall_in(icache_stall),
        .icache_error_in(icache_error),
        .fetch_enable(fetch_enable),
        .if_accept(~stall_if_id),
        .realign_stall(if_realign_stall),

        .pc_out(pc_out),
        .pc_plus_4(pc_plus_4),
        .pc_plus_8(pc_plus_8_unused),
        .instr(instr),
        .instr_fault(instr_fault),
        .instr_lane1(instr_lane1_unused),
        .icache_read_req(icache_read_req),
        .icache_read_req_lane1(if_lane1_req_unused),
        .icache_addr(icache_addr),
        .icache_addr_lane1(if_lane1_addr_unused),
        .icache_read_data(icache_read_data),
        .icache_read_data_lane1(icache_read_data_lane1)
    );

    if_id_register IF_ID (
        .clk(clk),
        .reset_n(reset_n),
        .stall(stall_if_id),
        .flush(flush_if_id),
        .riscv_start(riscv_start),
        .riscv_done(riscv_done),
        .instr(instr),
        .pc_plus_4(pc_plus_4),
        .pc_in(pc_in),
        .predict_taken(predict_taken),
        .btb_hit(btb_hit),
        .if_id_instr(if_id_instr),
        .if_id_pc_plus_4(if_id_pc_plus_4),
        .if_id_pc_in(if_id_pc_in),
        .if_id_predict_taken(if_id_predict_taken),
        .if_id_btb_hit(if_id_btb_hit),
        .instr_fault(instr_fault),
        .if_id_valid(if_id_valid),
        .if_id_fault(if_id_fault)
    );

    // =========================================================================
    // ID
    // =========================================================================
    instruction_decode ID (
        .if_id_pc_in(if_id_pc_in),
        .if_id_instr(if_id_instr),
        .ext_imm(ext_imm),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .opcode(opcode),
        .funct7(funct7),
        .jal_target(jal_target),
        .branch_target(branch_target),
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
        .alu_ctrl(alu_ctrl),
        .md_type(md_type),
        .md_operation(md_operation),
        .ecall(ecall),
        .ebreak(ebreak),
        .mret(mret),
        .csr_addr(csr_addr),
        .csr_op(csr_op),
        .csr_we(csr_we),
        .wfi_req(wfi_req_internal),
        .illegal_instr(illegal_instr),
        .fpu_en(fpu_en),
        .f_reg_write(f_reg_write),
        .f_mem_to_reg(f_mem_to_reg),
        .f_mem_write(f_mem_write),
        .f_to_x(f_to_x),
        .x_to_f(x_to_f),
        .fpu_operation(fpu_operation)
    );

    wire is_csr = (dbg_reg_read_addr[15:12] == 4'h0);
    wire is_gpr = (dbg_reg_read_addr[15:5]  == 11'h080);
    wire is_fpr = 1'b0;

    wire dbg_gpr_we = dbg_reg_write_en & (dbg_reg_write_addr[15:5]  == 11'h080);
    wire dbg_csr_we = dbg_reg_write_en & (dbg_reg_write_addr[15:12] == 4'h0);

    assign dbg_reg_read_data = is_csr ? csr_dbg_read_data :
                               is_gpr ? rf_dbg_read_data  :
                               is_fpr ? frf_dbg_read_data : 32'd0;

    csr_register_file CSR_RF (
        .clk(clk),
        .reset_n(reset_n),
        .meip_i(meip_i),
        .msip_i(msip_i),
        .mtip_i(mtip_i),
        .csr_addr(id_ex_csr_addr),
        .csr_read_data(csr_read_data_raw),
        .csr_addr_lane1(12'd0),
        .csr_read_data_lane1(),
        .csr_write_addr(ex_mem_csr_addr),
        .csr_write_data(ex_mem_csr_write_data),
        .csr_op(ex_mem_csr_op),
        .csr_write_en(ex_mem_csr_we),
        .count_en(!dbg_halted),
        .instret_en(instret_pulse),   // khoan no I - dem LENH RETIRE, khong dem chu ky
        .trap_enter(trap_enter),
        .mret_exec(mret_exec),
        .trap_cause(trap_cause),
        .trap_pc(trap_pc_value),
        .trap_val(trap_val_value),
        .mtvec_out(mtvec_pc),
        .mepc_out(mepc_pc),
        .mie_out(mie_val),
        .mstatus_mie(mstatus_mie_val),
        .dbg_halt_req(dbg_halt_req),
        .dbg_halted(dbg_halted),
        .debug_pc_in(pc_in),
        .dpc_out(dpc_out),
        .dcsr_out(dcsr_out),
        .dbg_reg_read_addr(dbg_reg_read_addr[11:0]),
        .dbg_read_data(csr_dbg_read_data),
        .dbg_reg_write_en(dbg_csr_we),
        .dbg_reg_write_addr(dbg_reg_write_addr[11:0]),
        .dbg_reg_write_data(dbg_reg_write_data),
        .csr_illegal_write(csr_illegal_write),
        .csr_illegal_addr(csr_illegal_addr)
    );

    assign csr_read_data_fwd =
        (ex_mem_csr_we && (ex_mem_csr_addr == id_ex_csr_addr)) ?
        ex_mem_csr_write_data : csr_read_data_raw;

    register_file RF (
        .clk(clk),
        .reset_n(reset_n),
        .read_reg1(rs1),
        .read_reg2(rs2),
        .read_reg1_lane1(5'd0),
        .read_reg2_lane1(5'd0),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_write_data(wb_write_data),
        .mem_wb_reg_write_lane1(1'b0),
        .mem_wb_rd_lane1(5'd0),
        .mem_wb_write_data_lane1(32'd0),
        .ooo_commit_valid0(1'b0),
        .ooo_commit_rd0(5'd0),
        .ooo_commit_data0(32'd0),
        .ooo_commit_valid1(1'b0),
        .ooo_commit_rd1(5'd0),
        .ooo_commit_data1(32'd0),
        .read_data1(read_data1_temp),
        .read_data2(read_data2_temp),
        .read_data1_lane1(),
        .read_data2_lane1(),
        .dbg_mode(dbg_halted),
        .dbg_read_addr(dbg_reg_read_addr[4:0]),
        .dbg_read_data(rf_dbg_read_data),
        .dbg_write_en(dbg_gpr_we),
        .dbg_write_addr(dbg_reg_write_addr[4:0]),
        .dbg_write_data(dbg_reg_write_data)
    );

    assign read_data1 = (rs1 != 5'd0 && rs1 == mem_wb_rd && mem_wb_reg_write) ?
                        wb_write_data : read_data1_temp;
    assign read_data2 = (rs2 != 5'd0 && rs2 == mem_wb_rd && mem_wb_reg_write) ?
                        wb_write_data : read_data2_temp;

    assign frf_dbg_read_data = 32'd0;
    assign wb_f_write_data   = 32'd0;

    id_ex_register #(.ROB_TAG_W(ROB_TAG_W)) ID_EX (
        .clk(clk),
        .reset_n(reset_n),
        .stall(stall_id_ex),
        .flush(flush_id_ex),
        .riscv_start(riscv_start),
        .riscv_done(riscv_done),
        .rob_tag({ROB_TAG_W{1'b0}}),
        .rob_valid(1'b0),
        .if_id_valid(if_id_valid),
        .if_id_fault(if_id_fault),
        .illegal_instr(illegal_instr),
        .if_id_pc_plus_4(if_id_pc_plus_4),
        .if_id_pc_in(if_id_pc_in),
        .funct3(funct3),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .ext_imm(ext_imm),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
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
        .mem_size(mem_size),
        .alu_ctrl(alu_ctrl),
        .branch_target(branch_target),
        .jal_target(jal_target),
        .if_id_predict_taken(if_id_predict_taken),
        .if_id_btb_hit(if_id_btb_hit),
        .ecall(ecall),
        .ebreak(ebreak),
        .mret(mret),
        .csr_addr(csr_addr),
        .csr_op(csr_op),
        .csr_we(csr_we),
        .md_type(md_type),
        .md_operation(md_operation),
        .if_id_instr(if_id_instr),
        .fpu_en(1'b0),
        .f_reg_write(1'b0),
        .f_mem_to_reg(1'b0),
        .f_mem_write(1'b0),
        .f_to_x(1'b0),
        .x_to_f(1'b0),
        .fpu_operation(5'd0),
        .read_f_data1(32'd0),
        .read_f_data2(32'd0),
        .id_ex_pc_plus_4(id_ex_pc_plus_4),
        .id_ex_pc_in(id_ex_pc_in),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_read_data1(id_ex_read_data1),
        .id_ex_read_data2(id_ex_read_data2),
        .id_ex_ext_imm(id_ex_ext_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_branch(id_ex_branch),
        .id_ex_jal(id_ex_jal),
        .id_ex_jalr(id_ex_jalr),
        .id_ex_lui(id_ex_lui),
        .id_ex_auipc(id_ex_auipc),
        .id_ex_mem_unsigned(id_ex_mem_unsigned),
        .id_ex_mem_size(id_ex_mem_size),
        .id_ex_alu_ctrl(id_ex_alu_ctrl),
        .id_ex_branch_target(id_ex_branch_target),
        .id_ex_jal_target(id_ex_jal_target),
        .id_ex_predict_taken(id_ex_predict_taken),
        .id_ex_btb_hit(id_ex_btb_hit),
        .id_ex_ecall(id_ex_ecall),
        .id_ex_ebreak(id_ex_ebreak),
        .id_ex_mret(id_ex_mret),
        .id_ex_csr_addr(id_ex_csr_addr),
        .id_ex_csr_op(id_ex_csr_op),
        .id_ex_csr_we(id_ex_csr_we),
        .id_ex_md_type(id_ex_md_type),
        .id_ex_md_operation(id_ex_md_operation),
        .id_ex_instr(id_ex_instr),
        .id_ex_fpu_en(id_ex_fpu_en),
        .id_ex_f_reg_write(id_ex_f_reg_write),
        .id_ex_f_mem_to_reg(id_ex_f_mem_to_reg),
        .id_ex_f_mem_write(id_ex_f_mem_write),
        .id_ex_f_to_x(id_ex_f_to_x),
        .id_ex_x_to_f(id_ex_x_to_f),
        .id_ex_fpu_operation(id_ex_fpu_operation),
        .id_ex_read_f_data1(id_ex_read_f_data1),
        .id_ex_read_f_data2(id_ex_read_f_data2),
        .id_ex_rob_tag(id_ex_rob_tag),
        .id_ex_rob_valid(id_ex_rob_valid),
        .id_ex_valid(id_ex_valid),
        .id_ex_illegal(id_ex_illegal),
        .id_ex_fault(id_ex_fault)
    );

    // =========================================================================
    // EX
    // =========================================================================
    forwarding_unit FU (
        .id_ex_read_data1(id_ex_read_data1),
        .id_ex_read_data2(id_ex_read_data2),
        .id_ex_ext_imm(id_ex_ext_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),
        .id_ex_alu_src(id_ex_alu_src),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),
        .ex_mem_alu_result(ex_mem_alu_result),
        .mem_wb_write_data(wb_write_data),
        .id_ex_read_f_data1(32'd0),
        .id_ex_read_f_data2(32'd0),
        .ex_mem_f_reg_write(1'b0),
        .mem_wb_f_reg_write(1'b0),
        .ex_mem_fpu_result(32'd0),
        .mem_wb_f_write_data(32'd0),
        .alu_in1(alu_in1),
        .alu_in2(alu_in2),
        .mem_write_data(mem_write_data),
        .fpu_in1(fpu_in1),
        .fpu_in2(fpu_in2)
    );

    execute #(
        .ENABLE_MULDIV(1),
        .ENABLE_FPU(0),
        .ENABLE_CSR(1),
        .ENABLE_BRANCH(1)
    ) EX (
        .clk(clk),
        .reset_n(reset_n),
        .stall_id_ex(stall_id_ex),
        .alu_in1(alu_in1),
        .alu_in2(alu_in2),
        .id_ex_alu_ctrl(id_ex_alu_ctrl),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_branch(id_ex_branch),
        .id_ex_instr(id_ex_instr),
        .id_ex_lui(id_ex_lui),
        .id_ex_auipc(id_ex_auipc),
        .id_ex_md_type(id_ex_md_type),
        .id_ex_md_operation(id_ex_md_operation),
        .id_ex_pc_in(id_ex_pc_in),
        .id_ex_ext_imm(id_ex_ext_imm),
        .id_ex_csr_op(id_ex_csr_op),
        .id_ex_csr_we(id_ex_csr_we),
        .csr_read_data(csr_read_data_fwd),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_fpu_en(1'b0),
        .id_ex_fpu_operation(5'd0),
        .id_ex_read_f_data1(32'd0),
        .id_ex_read_f_data2(32'd0),
        .id_ex_f_to_x(1'b0),
        .id_ex_x_to_f(1'b0),
        .alu_result(alu_result),
        .branch_taken(branch_taken),
        .csr_write_data(csr_write_data_ex),
        .mf_alu_stall(mf_alu_stall),
        .fpu_result_out(fpu_result_out),
        .jalr_target(jalr_target)
    );

    ex_mem_register #(.ROB_TAG_W(ROB_TAG_W)) EX_MEM (
        .clk(clk),
        .reset_n(reset_n),
        .stall(stall_ex_mem),
        .flush(flush_ex_mem),
        .riscv_start(riscv_start),
        .riscv_done(riscv_done),
        .id_ex_rob_tag(id_ex_rob_tag),
        .id_ex_rob_valid(id_ex_rob_valid),
        .id_ex_valid(id_ex_valid),
        .id_ex_illegal(id_ex_illegal),
        .id_ex_fault(id_ex_fault),
        .alu_result(alu_result),
        .id_ex_ext_imm(id_ex_ext_imm),
        .id_ex_rd(id_ex_rd),
        .id_ex_pc_plus_4(id_ex_pc_plus_4),
        .id_ex_pc_in(id_ex_pc_in),
        .id_ex_branch_target(id_ex_branch_target),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_branch(id_ex_branch),
        .branch_taken(branch_taken),
        .id_ex_jal(id_ex_jal),
        .id_ex_jalr(id_ex_jalr),
        .jalr_target(jalr_target),
        .id_ex_mem_unsigned(id_ex_mem_unsigned),
        .id_ex_mem_size(id_ex_mem_size),
        .id_ex_read_data2(id_ex_read_data2),
        .mem_write_data(mem_write_data),
        .id_ex_predict_taken(id_ex_predict_taken),
        .id_ex_btb_hit(id_ex_btb_hit),
        .id_ex_ecall(id_ex_ecall),
        .id_ex_ebreak(id_ex_ebreak),
        .id_ex_mret(id_ex_mret),
        .id_ex_csr_addr(id_ex_csr_addr),
        .id_ex_csr_op(id_ex_csr_op),
        .id_ex_csr_we(id_ex_csr_we),
        .csr_write_data_in(csr_write_data_ex),
        .id_ex_instr(id_ex_instr),
        .fpu_result(32'd0),
        .id_ex_read_f_data2(32'd0),
        .id_ex_f_reg_write(1'b0),
        .id_ex_f_mem_to_reg(1'b0),
        .id_ex_f_mem_write(1'b0),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_branch_target(ex_mem_branch_target),
        .ex_mem_pc_plus_4(ex_mem_pc_plus_4),
        .ex_mem_pc_in(ex_mem_pc_in),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_to_reg(ex_mem_mem_to_reg),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_branch(ex_mem_branch),
        .ex_mem_branch_taken(ex_mem_branch_taken),
        .ex_mem_jal(ex_mem_jal),
        .ex_mem_jalr(ex_mem_jalr),
        .ex_mem_jalr_target(ex_mem_jalr_target),
        .ex_mem_mem_unsigned(ex_mem_mem_unsigned),
        .ex_mem_mem_size(ex_mem_mem_size),
        .ex_mem_mem_write_data(ex_mem_mem_write_data),
        .ex_mem_predict_taken(ex_mem_predict_taken),
        .ex_mem_btb_hit(ex_mem_btb_hit),
        .ex_mem_ecall(ex_mem_ecall),
        .ex_mem_ebreak(ex_mem_ebreak),
        .ex_mem_mret(ex_mem_mret),
        .ex_mem_csr_addr(ex_mem_csr_addr),
        .ex_mem_csr_op(ex_mem_csr_op),
        .ex_mem_csr_we(ex_mem_csr_we),
        .ex_mem_csr_write_data(ex_mem_csr_write_data),
        .ex_mem_instr(ex_mem_instr),
        .ex_mem_fpu_result(ex_mem_fpu_result),
        .ex_mem_f_store_data(ex_mem_f_store_data),
        .ex_mem_f_reg_write(ex_mem_f_reg_write),
        .ex_mem_f_mem_to_reg(ex_mem_f_mem_to_reg),
        .ex_mem_f_mem_write(ex_mem_f_mem_write),
        .ex_mem_rob_tag(ex_mem_rob_tag),
        .ex_mem_rob_valid(ex_mem_rob_valid),
        .ex_mem_valid(ex_mem_valid),
        .ex_mem_illegal(ex_mem_illegal),
        .ex_mem_fault(ex_mem_fault)
    );

    // =========================================================================
    // MEM
    // =========================================================================
    assign final_mem_write_data =
        ex_mem_f_mem_write ? ex_mem_f_store_data : ex_mem_mem_write_data;

    memory_access MEM (
        .clk(clk),
        .reset_n(reset_n),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_mem_write_data(final_mem_write_data),
        .ex_mem_instr(ex_mem_instr),
        .ex_mem_mem_write(ex_mem_mem_write | ex_mem_f_mem_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        // KHOAN NO C - chan GHI to hop ngay trong chu ky nhan trap. flush_ex_mem
        // chi co hieu luc o suon xung ke tiep, nen khong co day nay thi mot `sw`
        // van GHI THAT roi chay lai sau mret -> ghi hai lan.
        .commit_kill(trap_enter),
        .mem_read_data(mem_read_data),
        .dcache_read_req(dcache_read_req),
        .dcache_write_req(dcache_write_req),
        .dcache_addr(dcache_addr),
        .dcache_write_data(dcache_write_data),
        .dcache_read_data(dcache_read_data),
        .dcache_amo_req(dcache_amo_req),
        .dcache_amo_capture(dcache_amo_capture)
    );

    mem_wb_register #(.ROB_TAG_W(ROB_TAG_W)) MEM_WB (
        .clk(clk),
        .reset_n(reset_n),
        .stall(stall_mem_wb),
        .flush(flush_mem_wb),
        .riscv_start(riscv_start),
        .riscv_done(riscv_done),
        .ex_mem_rob_tag(ex_mem_rob_tag),
        .ex_mem_rob_valid(ex_mem_rob_valid),
        .mem_read_data(mem_read_data),
        .ex_mem_pc_plus_4(ex_mem_pc_plus_4),
        .ex_mem_mem_to_reg(ex_mem_mem_to_reg),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_jal(ex_mem_jal),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_ecall(ex_mem_ecall),
        .ex_mem_fpu_result(32'd0),
        .ex_mem_f_reg_write(1'b0),
        .ex_mem_f_mem_to_reg(1'b0),
        .mem_wb_mem_read_data(mem_wb_mem_read_data),
        .mem_wb_pc_plus_4(mem_wb_pc_plus_4),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_to_reg(mem_wb_mem_to_reg),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_jal(mem_wb_jal),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_ecall(mem_wb_ecall),
        .mem_wb_fpu_result(mem_wb_fpu_result),
        .mem_wb_f_reg_write(mem_wb_f_reg_write),
        .mem_wb_f_mem_to_reg(mem_wb_f_mem_to_reg),
        .mem_wb_rob_tag(mem_wb_rob_tag),
        .mem_wb_rob_valid(mem_wb_rob_valid)
    );

    write_back WB (
        .mem_wb_mem_read_data(mem_wb_mem_read_data),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_pc_plus_4(mem_wb_pc_plus_4),
        .mem_wb_mem_to_reg(mem_wb_mem_to_reg),
        .mem_wb_jal(mem_wb_jal),
        .mem_wb_write_data(wb_write_data)
    );

    // =========================================================================
    // Control and branch prediction
    // =========================================================================
    pipeline_control_unit PCU (
        .clk(clk),
        .reset_n(reset_n),
        .opcode(opcode),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .id_ex_mem_read(id_ex_mem_read),
        // G4 - interlock phai dua tren mem_to_reg: SC.W co mem_read = 0 nhung
        // rd VAN nhan ma trang thai 0/1 tu duong bo nho.
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_jal(id_ex_jal),
        .id_ex_jalr(id_ex_jalr),
        .ex_mem_jalr(ex_mem_jalr),
        .id_ex_rd(id_ex_rd),
        .bpu_correct(bpu_correct),
        .trap_enter(trap_enter),
        .mret_exec(mret_exec),
        .icache_stall(icache_stall),
        .dcache_stall(dcache_stall),
        .mf_alu_stall(mf_alu_stall),
        .wfi_req(wfi_req_internal),
        .trap_interrupt(wake_interrupt),
        .is_sleeping(is_sleeping_internal),
        .dbg_halt_req(dbg_halt_req),
        .dbg_resume_req(dbg_resume_req),
        .dcsr_step(dcsr_out[2]),
        .dbg_halted(dbg_halted),
        .load_use_stall(load_use_stall),
        .flush_branch(flush_branch),
        .flush_jal(flush_jal),
        .flush_jalr(flush_jalr),
        .flush_trap(flush_trap),
        .stall_IF(stall_IF),
        .stall_ID(stall_ID),
        .stall_EX(stall_EX),
        .stall_MEM(stall_MEM),
        .stall_WB(stall_WB)
    );

    branch_prediction_unit BPU (
        .clk(clk),
        .reset_n(reset_n),
        .stall(stall_mem_wb),
        .pc_in(pc_in),
        .ex_mem_pc_in(ex_mem_pc_in),
        .ex_mem_branch(ex_mem_branch),
        .ex_mem_branch_taken(ex_mem_branch_taken),
        .ex_mem_predict_taken(ex_mem_predict_taken),
        .ex_mem_btb_hit(ex_mem_btb_hit),
        .ex_mem_branch_target(ex_mem_branch_target),
        .bpu_correct(bpu_correct),
        .predict_taken(predict_taken),
        .btb_hit(btb_hit),
        .actual_taken(actual_taken),
        .predict_target(predict_target)
    );

    // =========================================================================
    // Done
    // =========================================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            riscv_done <= 1'b0;
        end else if (riscv_start && (HALT_ON_ECALL != 0)) begin
            // Chi dung han khi duoc yeu cau tuong minh (bo dung nghiem thu cu).
            // Mac dinh HALT_ON_ECALL = 0: `ecall` chi la mot trap binh thuong,
            // riscv_done giu 0 mai mai va loi chay tiep.
            if (ex_mem_ecall || mem_wb_ecall) begin
                riscv_done <= 1'b1;
            end
        end
    end

endmodule
