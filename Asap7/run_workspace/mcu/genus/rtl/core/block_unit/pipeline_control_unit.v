//==================================================================================================
// File: pipeline_control_unit.v
//==================================================================================================

module pipeline_control_unit (
    input clk,                 
    input reset_n,             
    
    input [6:0] opcode,
    input [2:0] funct3,
    input [4:0] rs1,
    input [4:0] rs2,
    input id_ex_mem_read,
    // G4 - interlock phai dua tren mem_to_reg, KHONG phai mem_read. Xem ghi chu
    // o khoi load_use_hazard ben duoi.
    input id_ex_mem_to_reg,
    input id_ex_jal,
    input id_ex_jalr,
    input [4:0] id_ex_rd,
    input bpu_correct,
    input trap_enter,
    input mret_exec,
    input icache_stall, 
    input dcache_stall, 
    input mf_alu_stall,

    input  wire wfi_req,
    input  wire trap_interrupt,
    output wire is_sleeping,
    
    // --- TÍN HIỆU TỪ DEBUG MODULE & CSR ---
    input  wire dbg_halt_req,
    input  wire dbg_resume_req,
    input  wire dcsr_step,         // Đọc trực tiếp cờ Step từ CSR File
    output wire dbg_halted,
    
    output reg  load_use_stall,
    output reg  flush_branch,
    output reg  flush_jal,
    output reg  flush_trap,
    output wire stall_IF,
    output wire stall_ID,
    output wire stall_EX,
    output wire stall_MEM,
    output wire stall_WB
);
    // =========================================================================
    // LOAD-USE INTERLOCK
    //
    // F2: danh sach cu la {OP, OP-IMM, LOAD, STORE, AMO, BRANCH, JALR} - THIEU
    // SYSTEM (0x73). Hau qua that:
    //
    //     lw    x5, 0(x10)      // LOAD dang o EX, chua co du lieu
    //     csrrw x1, mtvec, x5   // doc x5 -> KHONG bi interlock
    //
    // forwarding_unit se bypass ex_mem_alu_result, nhung voi mot LOAD thi
    // ex_mem_alu_result la DIA CHI (rs1+imm), khong phai du lieu doc ve. Ket qua
    // la ghi rac vao CSR - hong am tham, khong co canh bao nao.
    //
    // Sua khong chi la "them 7'b1110011". Danh sach cu con kiem ca rs2 cho nhung
    // lenh KHONG he doc rs2 (OP-IMM, LOAD, JALR: bit [24:20] la mot phan cua
    // immediate) -> stall gia, mat hieu nang vo co. Voi SYSTEM sai lam do con dat
    // hon: [24:20] cua csrrw la 5 bit thap cua DIA CHI CSR. Vi vay o day tach ro
    // uses_rs1 / uses_rs2 theo dinh dang lenh.
    //
    //   opcode    ten        rs1  rs2   ghi chu
    //   0110011   OP         co   co
    //   0010011   OP-IMM     co   khong imm[11:0] chiem [31:20]
    //   0000011   LOAD       co   khong imm[11:0] chiem [31:20]
    //   0100011   STORE      co   co    rs2 la du lieu ghi
    //   0101111   AMO        co   co    rs2 la du lieu ghi (tru LR.W)
    //   1100011   BRANCH     co   co
    //   1100111   JALR       co   khong imm[11:0] chiem [31:20]
    //   1110011   SYSTEM     tuy  khong xem duoi
    //
    // Voi SYSTEM chi csrrw/csrrs/csrrc (funct3 = 001/010/011) doc x[rs1]. Ba bien
    // the ...i (funct3 = 101/110/111) dung truong rs1 lam uimm[4:0] - KHONG duoc
    // interlock. funct3 = 000 (ecall/ebreak/mret/wfi) khong doc thanh ghi nao.
    // =========================================================================
    localparam [6:0] OP_OP     = 7'b0110011;
    localparam [6:0] OP_OPIMM  = 7'b0010011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_AMO    = 7'b0101111;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_SYSTEM = 7'b1110011;   // <== F2: truoc day bi bo sot

    // csrrw/csrrs/csrrc doc x[rs1]; ba bien the ...i thi khong (funct3[2] = 1).
    wire system_reads_rs1 = (funct3 != 3'b000) && (funct3[2] == 1'b0);

    reg uses_rs1;
    reg uses_rs2;

    always @(*) begin
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
        case (opcode)
            OP_OP, OP_BRANCH, OP_STORE, OP_AMO: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end
            OP_OPIMM, OP_LOAD, OP_JALR: begin
                uses_rs1 = 1'b1;
            end
            OP_SYSTEM: begin
                uses_rs1 = system_reads_rs1;
            end
            default: begin
                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;
            end
        endcase
    end

    reg load_use_hazard;

    // -------------------------------------------------------------------------
    // G4 - dieu kien PHAI la mem_to_reg, khong phai mem_read.
    //
    // Interlock ton tai vi mot ly do duy nhat: khi lenh o tang EX lay ket qua tu
    // DUONG BO NHO thi ex_mem_alu_result ma forwarding_unit bypass lai la DIA CHI.
    // Dieu do dung cho MOI lenh co mem_to_reg = 1.
    //
    // Voi load thuong va AMO*.W thi mem_read == mem_to_reg. Cho chung tach doi la
    // SC.W:
    //     sc.w  t6, t2, (t5)     // mem_read = 0 (no GHI), nhung mem_to_reg = 1
    //     bne   t6, zero, fail   //   vi rd nhan MA TRANG THAI 0/1 tu duong bo nho
    // mem_read = 0 nen interlock cu khong bat -> bne nhan dia chi thay vi 0/1.
    // -------------------------------------------------------------------------
    always @(*) begin
        load_use_hazard = 1'b0;
        if (id_ex_mem_to_reg && (id_ex_rd != 5'd0)) begin
            if ((uses_rs1 && (id_ex_rd == rs1)) ||
                (uses_rs2 && (id_ex_rd == rs2))) begin
                load_use_hazard = 1'b1;
            end
        end
    end

    // =========================================================================
    // LOGIC BƠM BONG BÓNG (NOP) VÀ KIỂM TRA ĐƯỜNG ỐNG
    // =========================================================================
    reg [6:0] drain_cnt;
    reg dbg_halted_reg;
    reg step_active;

    wire is_resuming = (dbg_halted_reg && dbg_resume_req);
    
    // Tách riêng: Đây là tín hiệu kẹt do Hazard thật sự của CPU
    wire real_load_use_stall = load_use_hazard && !flush_branch && !flush_jal;
    
    // SỰ LỢI HẠI: Pipeline được coi là "moving" nếu không bị kẹt bộ nhớ, ALU, hoặc Hazard thật.
    // Việc ta cố tình bơm NOP sẽ KHÔNG làm pipeline_moving bị kéo xuống 0 nữa!
    wire pipeline_moving = !(icache_stall || dcache_stall || mf_alu_stall || real_load_use_stall);

    // =========================================================================
    // KHOAN NO R - bo XA ONG dung sai co che, va no XOA lenh.
    //
    // Ban cu:
    //     wire inject_nop = is_draining && (drain_cnt >= 7'd1);
    //     if (inject_nop) load_use_stall = 1'b1;
    //
    // Y dinh la "bom NOP de xa ong". Nhung `load_use_stall` KHONG phai duong bom
    // NOP trung tinh - trong riscv_pipeline.v no la mot so hang cua `flush_id_ex`,
    // va trong pipeline_register flush THAY THE noi dung ID/EX bang bong bong.
    // Voi hazard load-use that thi vo hai: lenh bi xoa van con o IF/ID (dang bi
    // stall_if_id giu) va se duoc phat lai. Khi xa ong thi KHONG:
    //
    //     chu ky 0 : dbg_halt_req len -> stall_IF len -> cong lay lenh dong.
    //                stall_if_id con 0 nen lenh X di tu IF/ID sang ID/EX.
    //     chu ky 1 : inject_nop -> load_use_stall -> flush_id_ex -> X BI XOA
    //                khoi ID/EX, va no khong con o IF/ID de phat lai.
    //
    // X bien mat. Voi single-step con bat buoc hon: step_active mo cong dung mot
    // nhip, nen lenh duy nhat duoc lay chinh la lenh can step - va inject_nop xoa
    // dung no o chu ky ke tiep.
    //
    // SUA: bo han. Xa ong KHONG can bom gi - dong cong lay lenh la du, vi bong
    // bong tu troi vao tu IF (if_fetch_bubble o riscv_pipeline.v danh dau chung
    // invalid), con lenh DA o trong ong thi cu the chay het. drain_cnt chi con
    // lam dung mot viec: dem du lau de ong rong han.
    // =========================================================================
    always @(*) begin
        flush_trap = trap_enter || mret_exec;
        flush_branch = !bpu_correct;
        flush_jal = id_ex_jal || id_ex_jalr;
        load_use_stall = load_use_hazard && !flush_trap && !flush_branch && !flush_jal;
    end

    // =========================================================================
    // LOGIC ĐÓNG BĂNG (HALT) & NHÍCH LỆNH (STEP) 
    // =========================================================================    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dbg_halted_reg <= 1'b0;
            drain_cnt      <= 7'd0;
            step_active    <= 1'b0;
        end else begin
            // 1. Nhận lệnh Resume từ OpenOCD
            if (dbg_resume_req && dbg_halted_reg) begin
                dbg_halted_reg <= 1'b0;
                if (dcsr_step) begin // Tự động nhận diện nếu đang trong chế độ Step
                    step_active <= 1'b1;
                    drain_cnt   <= 7'd0;
                end
            end 
            // 2. Quá trình xả rác (Drain)
            else if ((dbg_halt_req || step_active) && !dbg_halted_reg) begin
                
                // GIỮ LẠI PIPELINE MOVING: Chỉ đếm khi lệnh thực sự tiến lên!
                if (pipeline_moving) begin
                    // GIẢM XUỐNG 10 CHU KỲ (Quá đủ cho Pipeline 5 tầng)
                    if (drain_cnt < 7'd10) begin 
                        drain_cnt <= drain_cnt + 1;
                    end else begin
                        dbg_halted_reg <= 1'b1;
                        step_active    <= 1'b0; 
                    end
                end
                
            end
        end
    end

    assign dbg_halted = dbg_halted_reg;

    // =========================================================================
    // LOGIC SLEEP (WFI) & WAKE-UP
    // =========================================================================
    reg sleeping_reg;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sleeping_reg <= 1'b0;
        end else begin
            if (trap_interrupt) sleeping_reg <= 1'b0;
            else if (wfi_req)   sleeping_reg <= 1'b1;
        end
    end
    assign is_sleeping = sleeping_reg;

    // =========================================================================
    // XUẤT TÍN HIỆU STALL
    // =========================================================================
    wire resume_pulse = (dbg_halted_reg && dbg_resume_req); // Mở van IF đúng 1 nhịp

    // =========================================================================
    // KHOAN NO S - `wfi` treo lo VO DIEU KIEN. Ban cu:
    //
    //     wfi_req   = (if_id_instr == 32'h10500073)     <- DOC tu IF/ID
    //     wfi_stall = sleeping_reg || wfi_req
    //     stall_ID  = ... || wfi_stall                  <- DONG BANG chinh IF/ID
    //
    // Diem GIAI MA va diem DONG BANG nam tren CUNG mot thanh ghi. Vong tu giu:
    // danh thuc xoa sleeping_reg, nhung wfi_req VAN bang 1 vi lenh van nam nguyen
    // o IF/ID, nen stall khong bao gio ha. Do la BE TAC, khong phai "cham".
    //
    // Ca chet nguoi la `csrci mstatus, 8; wfi` - mau low-power pho bien nhat.
    // Voi mstatus.MIE = 0 thi khong co trap nao de flush IF/ID, nen khong co
    // duong thoat: chip treo vinh vien. Dac ta RISC-V noi ro WFI PHAI thuc day
    // khi co enabled interrupt KE CA khi MIE = 0.
    //
    // SUA: pha vong bang cach cho `wfi` DI TIEP nhu moi lenh khac, va chi giu
    // trang thai ngu trong mot flip-flop rieng:
    //
    //   - stall_ID KHONG con wfi_stall  -> IF/ID khong bi dong bang, `wfi` chay
    //     qua ID/EX -> EX/MEM -> retire dung MOT lan. Dung ngu nghia: `wfi` la
    //     mot hint, no PHAI retire va PC phai tien toi wfi+4.
    //   - stall_IF chi con sleeping_reg (KHONG con wfi_req) -> pc_reg dung yen
    //     trong luc ngu va cong lay lenh dong. IF/ID nhan BONG BONG nho dieu kien
    //     ~fetch_enable trong flush_if_id.
    //   - sleeping_reg da co san uu tien dung: wake_interrupt xoa TRUOC khi
    //     wfi_req set, va ngat la MUC nen no tiep tuc xoa cho toi khi phan mem ha
    //     nguon ngat -> khong the ngu lai ngay o chu ky sau.
    //
    // He qua duoc chap nhan CO Y THUC: lenh NGAY SAU `wfi` da vao IF/ID truoc khi
    // sleeping_reg len, nen no chay TRUOC khi lo ngu. Dac ta cho phep - hien thuc
    // `wfi` nhu mot NOP hoan toan cung hop le.
    // =========================================================================
    wire wfi_stall = sleeping_reg;

    assign stall_IF  = ((dbg_halted_reg || dbg_halt_req || step_active) && !resume_pulse) || wfi_stall;
    assign stall_ID  = ((dbg_halted_reg) && !resume_pulse);
    
    assign stall_EX  = dbg_halted_reg;
    assign stall_MEM = dbg_halted_reg;
    assign stall_WB  = dbg_halted_reg;

endmodule
