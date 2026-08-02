//==================================================================================================
// File: pipeline_register.v
// Description: RV32IM pipeline registers with explicit valid bits.
//==================================================================================================

module if_id_register (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        stall,
    input  wire        flush,
    input  wire        riscv_start,
    input  wire        riscv_done,
    input  wire [31:0] instr,
    input  wire [31:0] pc_plus_4,
    input  wire [31:0] pc_in,
    input  wire        predict_taken,
    input  wire        btb_hit,
    output reg  [31:0] if_id_instr,
    output reg  [31:0] if_id_pc_plus_4,
    output reg  [31:0] if_id_pc_in,
    output reg         if_id_predict_taken,
    output reg         if_id_btb_hit,
    output reg         if_id_valid
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            if_id_instr         <= 32'h0000_0013;
            if_id_pc_plus_4     <= 32'd0;
            if_id_pc_in         <= 32'd0;
            if_id_predict_taken <= 1'b0;
            if_id_btb_hit       <= 1'b0;
            if_id_valid         <= 1'b0;
        end else if (!riscv_start) begin
            if_id_instr         <= 32'h0000_0013;
            if_id_predict_taken <= 1'b0;
            if_id_btb_hit       <= 1'b0;
            if_id_valid         <= 1'b0;
        end else if (!riscv_done) begin
            if (stall) begin
                // Hold the current instruction.
            end else if (flush) begin
                if_id_instr         <= 32'h0000_0013;
                if_id_pc_plus_4     <= 32'd0;
                if_id_pc_in         <= 32'd0;
                if_id_predict_taken <= 1'b0;
                if_id_btb_hit       <= 1'b0;
                if_id_valid         <= 1'b0;
            end else begin
                if_id_instr         <= instr;
                if_id_pc_plus_4     <= pc_plus_4;
                if_id_pc_in         <= pc_in;
                if_id_predict_taken <= predict_taken;
                if_id_btb_hit       <= btb_hit;
                if_id_valid         <= 1'b1;
            end
        end
    end
endmodule


module id_ex_register (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        stall,
    input  wire        flush,
    input  wire        riscv_start,
    input  wire        riscv_done,
    input  wire        if_id_valid,
    input  wire [31:0] if_id_pc_plus_4,
    input  wire [31:0] if_id_pc_in,
    input  wire [2:0]  funct3,
    input  wire [31:0] read_data1,
    input  wire [31:0] read_data2,
    input  wire [31:0] ext_imm,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire        reg_write,
    input  wire        alu_src,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire        mem_to_reg,
    input  wire        branch,
    input  wire        jal,
    input  wire        jalr,
    input  wire        lui,
    input  wire        auipc,
    input  wire        mem_unsigned,
    input  wire [1:0]  mem_size,
    input  wire [3:0]  alu_ctrl,
    input  wire [31:0] branch_target,
    input  wire [31:0] jal_target,
    input  wire        if_id_predict_taken,
    input  wire        if_id_btb_hit,
    input  wire        ecall,
    input  wire        ebreak,
    input  wire        mret,
    input  wire [11:0] csr_addr,
    input  wire [1:0]  csr_op,
    input  wire        csr_we,
    input  wire        md_type,
    input  wire [2:0]  md_operation,
    input  wire [31:0] if_id_instr,
    output reg         id_ex_valid,
    output reg  [31:0] id_ex_pc_plus_4,
    output reg  [31:0] id_ex_pc_in,
    output reg  [2:0]  id_ex_funct3,
    output reg  [31:0] id_ex_read_data1,
    output reg  [31:0] id_ex_read_data2,
    output reg  [31:0] id_ex_ext_imm,
    output reg  [4:0]  id_ex_rs1,
    output reg  [4:0]  id_ex_rs2,
    output reg  [4:0]  id_ex_rd,
    output reg         id_ex_reg_write,
    output reg         id_ex_alu_src,
    output reg         id_ex_mem_write,
    output reg         id_ex_mem_read,
    output reg         id_ex_mem_to_reg,
    output reg         id_ex_branch,
    output reg         id_ex_jal,
    output reg         id_ex_jalr,
    output reg         id_ex_lui,
    output reg         id_ex_auipc,
    output reg         id_ex_mem_unsigned,
    output reg  [1:0]  id_ex_mem_size,
    output reg  [3:0]  id_ex_alu_ctrl,
    output reg  [31:0] id_ex_branch_target,
    output reg  [31:0] id_ex_jal_target,
    output reg         id_ex_predict_taken,
    output reg         id_ex_btb_hit,
    output reg         id_ex_ecall,
    output reg         id_ex_ebreak,
    output reg         id_ex_mret,
    output reg  [11:0] id_ex_csr_addr,
    output reg  [1:0]  id_ex_csr_op,
    output reg         id_ex_csr_we,
    output reg         id_ex_md_type,
    output reg  [2:0]  id_ex_md_operation,
    output reg  [31:0] id_ex_instr
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            id_ex_valid         <= 1'b0;
            id_ex_pc_plus_4     <= 32'd0;
            id_ex_pc_in         <= 32'd0;
            id_ex_funct3        <= 3'd0;
            id_ex_read_data1    <= 32'd0;
            id_ex_read_data2    <= 32'd0;
            id_ex_ext_imm       <= 32'd0;
            id_ex_rs1           <= 5'd0;
            id_ex_rs2           <= 5'd0;
            id_ex_rd            <= 5'd0;
            id_ex_reg_write     <= 1'b0;
            id_ex_alu_src       <= 1'b0;
            id_ex_mem_write     <= 1'b0;
            id_ex_mem_read      <= 1'b0;
            id_ex_mem_to_reg    <= 1'b0;
            id_ex_branch        <= 1'b0;
            id_ex_jal           <= 1'b0;
            id_ex_jalr          <= 1'b0;
            id_ex_lui           <= 1'b0;
            id_ex_auipc         <= 1'b0;
            id_ex_mem_unsigned  <= 1'b0;
            id_ex_mem_size      <= 2'd0;
            id_ex_alu_ctrl      <= 4'd0;
            id_ex_branch_target <= 32'd0;
            id_ex_jal_target    <= 32'd0;
            id_ex_predict_taken <= 1'b0;
            id_ex_btb_hit       <= 1'b0;
            id_ex_ecall         <= 1'b0;
            id_ex_ebreak        <= 1'b0;
            id_ex_mret          <= 1'b0;
            id_ex_csr_addr      <= 12'd0;
            id_ex_csr_op        <= 2'd0;
            id_ex_csr_we        <= 1'b0;
            id_ex_md_type       <= 1'b0;
            id_ex_md_operation  <= 3'd0;
            id_ex_instr         <= 32'h0000_0013;
        end else if (!riscv_start) begin
            id_ex_valid         <= 1'b0;
            id_ex_reg_write     <= 1'b0;
            id_ex_mem_write     <= 1'b0;
            id_ex_mem_read      <= 1'b0;
            id_ex_mem_to_reg    <= 1'b0;
            id_ex_branch        <= 1'b0;
            id_ex_jal           <= 1'b0;
            id_ex_jalr          <= 1'b0;
            id_ex_csr_we        <= 1'b0;
            id_ex_md_type       <= 1'b0;
            id_ex_ecall         <= 1'b0;
            id_ex_ebreak        <= 1'b0;
            id_ex_mret          <= 1'b0;
            id_ex_instr         <= 32'h0000_0013;
        end else if (!riscv_done) begin
            if (stall) begin
                // Hold the current instruction.
            end else if (flush) begin
                id_ex_valid         <= 1'b0;
                id_ex_reg_write     <= 1'b0;
                id_ex_mem_write     <= 1'b0;
                id_ex_mem_read      <= 1'b0;
                id_ex_mem_to_reg    <= 1'b0;
                id_ex_branch        <= 1'b0;
                id_ex_jal           <= 1'b0;
                id_ex_jalr          <= 1'b0;
                id_ex_lui           <= 1'b0;
                id_ex_auipc         <= 1'b0;
                id_ex_csr_we        <= 1'b0;
                id_ex_md_type       <= 1'b0;
                id_ex_ecall         <= 1'b0;
                id_ex_ebreak        <= 1'b0;
                id_ex_mret          <= 1'b0;
                id_ex_predict_taken <= 1'b0;
                id_ex_btb_hit       <= 1'b0;
                id_ex_instr         <= 32'h0000_0013;
            end else begin
                id_ex_valid         <= if_id_valid;
                id_ex_pc_plus_4     <= if_id_pc_plus_4;
                id_ex_pc_in         <= if_id_pc_in;
                id_ex_funct3        <= funct3;
                id_ex_read_data1    <= read_data1;
                id_ex_read_data2    <= read_data2;
                id_ex_ext_imm       <= ext_imm;
                id_ex_rs1           <= rs1;
                id_ex_rs2           <= rs2;
                id_ex_rd            <= rd;
                id_ex_reg_write     <= reg_write;
                id_ex_alu_src       <= alu_src;
                id_ex_mem_write     <= mem_write;
                id_ex_mem_read      <= mem_read;
                id_ex_mem_to_reg    <= mem_to_reg;
                id_ex_branch        <= branch;
                id_ex_jal           <= jal;
                id_ex_jalr          <= jalr;
                id_ex_lui           <= lui;
                id_ex_auipc         <= auipc;
                id_ex_mem_unsigned  <= mem_unsigned;
                id_ex_mem_size      <= mem_size;
                id_ex_alu_ctrl      <= alu_ctrl;
                id_ex_branch_target <= branch_target;
                id_ex_jal_target    <= jal_target;
                id_ex_predict_taken <= if_id_predict_taken;
                id_ex_btb_hit       <= if_id_btb_hit;
                id_ex_ecall         <= ecall;
                id_ex_ebreak        <= ebreak;
                id_ex_mret          <= mret;
                id_ex_csr_addr      <= csr_addr;
                id_ex_csr_op        <= csr_op;
                id_ex_csr_we        <= csr_we;
                id_ex_md_type       <= md_type;
                id_ex_md_operation  <= md_operation;
                id_ex_instr         <= if_id_instr;
            end
        end
    end
endmodule


module ex_mem_register (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        stall,
    input  wire        flush,
    input  wire        riscv_start,
    input  wire        riscv_done,
    input  wire        id_ex_valid,
    input  wire [31:0] alu_result,
    input  wire [4:0]  id_ex_rd,
    input  wire [31:0] id_ex_pc_plus_4,
    input  wire [31:0] id_ex_pc_in,
    input  wire [31:0] id_ex_branch_target,
    input  wire        id_ex_mem_write,
    input  wire        id_ex_mem_read,
    input  wire        id_ex_mem_to_reg,
    input  wire        id_ex_reg_write,
    input  wire        id_ex_branch,
    input  wire        branch_taken,
    input  wire        id_ex_jal,
    input  wire        id_ex_mem_unsigned,
    input  wire [1:0]  id_ex_mem_size,
    input  wire [31:0] mem_write_data,
    input  wire        id_ex_predict_taken,
    input  wire        id_ex_btb_hit,
    input  wire        id_ex_ecall,
    input  wire        id_ex_ebreak,
    input  wire        id_ex_mret,
    input  wire [11:0] id_ex_csr_addr,
    input  wire [1:0]  id_ex_csr_op,
    input  wire        id_ex_csr_we,
    input  wire [31:0] csr_write_data_in,
    input  wire [31:0] id_ex_instr,
    output reg         ex_mem_valid,
    output reg  [31:0] ex_mem_alu_result,
    output reg  [31:0] ex_mem_branch_target,
    output reg  [31:0] ex_mem_pc_plus_4,
    output reg  [31:0] ex_mem_pc_in,
    output reg  [4:0]  ex_mem_rd,
    output reg         ex_mem_mem_write,
    output reg         ex_mem_mem_read,
    output reg         ex_mem_mem_to_reg,
    output reg         ex_mem_reg_write,
    output reg         ex_mem_branch,
    output reg         ex_mem_branch_taken,
    output reg         ex_mem_jal,
    output reg         ex_mem_mem_unsigned,
    output reg  [1:0]  ex_mem_mem_size,
    output reg  [31:0] ex_mem_mem_write_data,
    output reg         ex_mem_predict_taken,
    output reg         ex_mem_btb_hit,
    output reg         ex_mem_ecall,
    output reg         ex_mem_ebreak,
    output reg         ex_mem_mret,
    output reg  [11:0] ex_mem_csr_addr,
    output reg  [1:0]  ex_mem_csr_op,
    output reg         ex_mem_csr_we,
    output reg  [31:0] ex_mem_csr_write_data,
    output reg  [31:0] ex_mem_instr
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ex_mem_valid          <= 1'b0;
            ex_mem_alu_result     <= 32'd0;
            ex_mem_branch_target  <= 32'd0;
            ex_mem_pc_plus_4      <= 32'd0;
            ex_mem_pc_in          <= 32'd0;
            ex_mem_rd             <= 5'd0;
            ex_mem_mem_write      <= 1'b0;
            ex_mem_mem_read       <= 1'b0;
            ex_mem_mem_to_reg     <= 1'b0;
            ex_mem_reg_write      <= 1'b0;
            ex_mem_branch         <= 1'b0;
            ex_mem_branch_taken   <= 1'b0;
            ex_mem_jal            <= 1'b0;
            ex_mem_mem_unsigned   <= 1'b0;
            ex_mem_mem_size       <= 2'd0;
            ex_mem_mem_write_data <= 32'd0;
            ex_mem_predict_taken  <= 1'b0;
            ex_mem_btb_hit        <= 1'b0;
            ex_mem_ecall          <= 1'b0;
            ex_mem_ebreak         <= 1'b0;
            ex_mem_mret           <= 1'b0;
            ex_mem_csr_addr       <= 12'd0;
            ex_mem_csr_op         <= 2'd0;
            ex_mem_csr_we         <= 1'b0;
            ex_mem_csr_write_data <= 32'd0;
            ex_mem_instr          <= 32'h0000_0013;
        end else if (!riscv_start) begin
            ex_mem_valid       <= 1'b0;
            ex_mem_mem_write   <= 1'b0;
            ex_mem_mem_read    <= 1'b0;
            ex_mem_reg_write   <= 1'b0;
            ex_mem_branch      <= 1'b0;
            ex_mem_jal         <= 1'b0;
            ex_mem_csr_we      <= 1'b0;
            ex_mem_ecall       <= 1'b0;
            ex_mem_ebreak      <= 1'b0;
            ex_mem_mret        <= 1'b0;
            ex_mem_instr       <= 32'h0000_0013;
        end else if (!riscv_done) begin
            if (stall) begin
                // Hold the current instruction.
            end else if (flush) begin
                ex_mem_valid          <= 1'b0;
                ex_mem_mem_write      <= 1'b0;
                ex_mem_mem_read       <= 1'b0;
                ex_mem_mem_to_reg     <= 1'b0;
                ex_mem_reg_write      <= 1'b0;
                ex_mem_branch         <= 1'b0;
                ex_mem_branch_taken   <= 1'b0;
                ex_mem_jal            <= 1'b0;
                ex_mem_predict_taken  <= 1'b0;
                ex_mem_btb_hit        <= 1'b0;
                ex_mem_ecall          <= 1'b0;
                ex_mem_ebreak         <= 1'b0;
                ex_mem_mret           <= 1'b0;
                ex_mem_csr_we         <= 1'b0;
                ex_mem_instr          <= 32'h0000_0013;
            end else begin
                ex_mem_valid          <= id_ex_valid;
                ex_mem_alu_result     <= alu_result;
                ex_mem_branch_target  <= id_ex_branch_target;
                ex_mem_pc_plus_4      <= id_ex_pc_plus_4;
                ex_mem_pc_in          <= id_ex_pc_in;
                ex_mem_rd             <= id_ex_rd;
                ex_mem_mem_write      <= id_ex_mem_write;
                ex_mem_mem_read       <= id_ex_mem_read;
                ex_mem_mem_to_reg     <= id_ex_mem_to_reg;
                ex_mem_reg_write      <= id_ex_reg_write;
                ex_mem_branch         <= id_ex_branch;
                ex_mem_branch_taken   <= branch_taken;
                ex_mem_jal            <= id_ex_jal;
                ex_mem_mem_unsigned   <= id_ex_mem_unsigned;
                ex_mem_mem_size       <= id_ex_mem_size;
                ex_mem_mem_write_data <= mem_write_data;
                ex_mem_predict_taken  <= id_ex_predict_taken;
                ex_mem_btb_hit        <= id_ex_btb_hit;
                ex_mem_ecall          <= id_ex_ecall;
                ex_mem_ebreak         <= id_ex_ebreak;
                ex_mem_mret           <= id_ex_mret;
                ex_mem_csr_addr       <= id_ex_csr_addr;
                ex_mem_csr_op         <= id_ex_csr_op;
                ex_mem_csr_we         <= id_ex_csr_we;
                ex_mem_csr_write_data <= csr_write_data_in;
                ex_mem_instr          <= id_ex_instr;
            end
        end
    end
endmodule


module mem_wb_register (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        stall,
    input  wire        flush,
    input  wire        riscv_start,
    input  wire        riscv_done,
    input  wire        ex_mem_valid,
    input  wire [31:0] mem_read_data,
    input  wire [31:0] ex_mem_pc_plus_4,
    input  wire        ex_mem_mem_to_reg,
    input  wire        ex_mem_reg_write,
    input  wire        ex_mem_jal,
    input  wire [31:0] ex_mem_alu_result,
    input  wire [4:0]  ex_mem_rd,
    input  wire        ex_mem_ecall,
    output reg         mem_wb_valid,
    output reg  [31:0] mem_wb_mem_read_data,
    output reg  [31:0] mem_wb_pc_plus_4,
    output reg  [31:0] mem_wb_alu_result,
    output reg         mem_wb_mem_to_reg,
    output reg         mem_wb_reg_write,
    output reg         mem_wb_jal,
    output reg         mem_wb_ecall,
    output reg  [4:0]  mem_wb_rd
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mem_wb_valid         <= 1'b0;
            mem_wb_mem_read_data <= 32'd0;
            mem_wb_pc_plus_4     <= 32'd0;
            mem_wb_alu_result    <= 32'd0;
            mem_wb_mem_to_reg    <= 1'b0;
            mem_wb_reg_write     <= 1'b0;
            mem_wb_jal           <= 1'b0;
            mem_wb_ecall         <= 1'b0;
            mem_wb_rd            <= 5'd0;
        end else if (!riscv_start) begin
            mem_wb_valid      <= 1'b0;
            mem_wb_reg_write  <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
            mem_wb_jal        <= 1'b0;
            mem_wb_ecall      <= 1'b0;
        end else if (!riscv_done) begin
            if (stall) begin
                // Hold the current instruction.
            end else if (flush) begin
                mem_wb_valid      <= 1'b0;
                mem_wb_reg_write  <= 1'b0;
                mem_wb_mem_to_reg <= 1'b0;
                mem_wb_jal        <= 1'b0;
                mem_wb_ecall      <= 1'b0;
            end else begin
                mem_wb_valid         <= ex_mem_valid;
                mem_wb_mem_read_data <= mem_read_data;
                mem_wb_pc_plus_4     <= ex_mem_pc_plus_4;
                mem_wb_alu_result    <= ex_mem_alu_result;
                mem_wb_mem_to_reg    <= ex_mem_mem_to_reg;
                mem_wb_reg_write     <= ex_mem_reg_write;
                mem_wb_jal           <= ex_mem_jal;
                mem_wb_ecall         <= ex_mem_ecall;
                mem_wb_rd            <= ex_mem_rd;
            end
        end
    end
endmodule
