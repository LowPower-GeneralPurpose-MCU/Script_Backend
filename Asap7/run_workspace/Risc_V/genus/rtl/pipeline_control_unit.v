//==================================================================================================
// File: pipeline_control_unit.v
//==================================================================================================

module pipeline_control_unit (
    input clk,
    input reset_n,
    input riscv_start,

    input [6:0] opcode,
    input [2:0] funct3,
    input [4:0] rs1,
    input [4:0] rs2,
    input id_ex_mem_read,
    input id_ex_jal,
    input id_ex_jalr,
    input [4:0] id_ex_rd,
    input bpu_correct,
    input trap_enter,
    input mret_exec,
    input icache_stall,
    input dcache_stall,
    input md_alu_stall,

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
    reg load_use_hazard;
    reg uses_rs1;
    reg uses_rs2;

    always @(*) begin
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;

        // RV32IM source-register usage. This avoids false stalls on I-type,
        // LUI/AUIPC/JAL and immediate CSR instructions.
        case (opcode)
            7'b0110011: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end // OP/M
            7'b0010011: begin uses_rs1 = 1'b1; end                  // OP-IMM
            7'b0000011: begin uses_rs1 = 1'b1; end                  // LOAD
            7'b0100011: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end // STORE
            7'b1100011: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end // BRANCH
            7'b1100111: begin uses_rs1 = 1'b1; end                  // JALR
            7'b1110011: begin
                if ((funct3 != 3'b000) && !funct3[2]) begin
                    uses_rs1 = 1'b1; // CSRRW/CSRRS/CSRRC register forms
                end
            end
            default: begin end
        endcase

        load_use_hazard = 1'b0;
        if (id_ex_mem_read && (id_ex_rd != 5'd0)) begin
            load_use_hazard = (uses_rs1 && (id_ex_rd == rs1)) ||
                              (uses_rs2 && (id_ex_rd == rs2));
        end
    end

    // =========================================================================
    // LOGIC BƠM BONG BÓNG (NOP) VÀ KIỂM TRA ĐƯỜNG ỐNG
    // =========================================================================
    reg [6:0] drain_cnt;
    reg dbg_halted_reg;
    reg step_active;

    wire is_draining = (dbg_halt_req || step_active) && !dbg_halted_reg;

    // Tách riêng: Đây là tín hiệu kẹt do Hazard thật sự của CPU
    wire real_load_use_stall = load_use_hazard && !flush_branch && !flush_jal;

    // SỰ LỢI HẠI: Pipeline được coi là "moving" nếu không bị kẹt bộ nhớ, ALU, hoặc Hazard thật.
    // Việc ta cố tình bơm NOP sẽ KHÔNG làm pipeline_moving bị kéo xuống 0 nữa!
    wire pipeline_moving = !(icache_stall || dcache_stall || md_alu_stall || real_load_use_stall);

    // Bơm NOP từ chu kỳ xả rác THỨ 1 trở đi (Bảo vệ lệnh Step lọt an toàn xuống EX)
    wire inject_nop = is_draining && (drain_cnt >= 7'd1);

    always @(*) begin
        flush_trap = trap_enter || mret_exec;
        flush_branch = !bpu_correct;
        flush_jal = id_ex_jal || id_ex_jalr;

        if (inject_nop) begin
            load_use_stall = 1'b1;
        end else begin
            load_use_stall = load_use_hazard && !flush_trap && !flush_branch && !flush_jal;
        end
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
        end else if (!riscv_start) begin
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
    // wfi_req is an acceptance pulse generated only when WFI can leave IF/ID.
    // Do not include it directly in the stall or the request would hold itself.
    // A pending enabled interrupt releases the stall combinationally while
    // sleeping_reg is cleared on the same clock edge.
    wire wfi_stall = sleeping_reg && !trap_interrupt;

    assign stall_IF  = ((dbg_halted_reg || dbg_halt_req || step_active) && !resume_pulse) || wfi_stall;
    assign stall_ID  = ((dbg_halted_reg) && !resume_pulse) || wfi_stall;

    assign stall_EX  = dbg_halted_reg;
    assign stall_MEM = dbg_halted_reg;
    assign stall_WB  = dbg_halted_reg;

endmodule
