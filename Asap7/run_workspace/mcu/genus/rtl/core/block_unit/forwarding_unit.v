//==================================================================================================
// File: forwarding_unit.v
//==================================================================================================
module forwarding_unit (
    input [31:0] id_ex_read_data1,
    input [31:0] id_ex_read_data2,
    input [31:0] id_ex_ext_imm,
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    input ex_mem_reg_write,
    input mem_wb_reg_write,
    input id_ex_alu_src,
    input [4:0] ex_mem_rd,
    input [4:0] mem_wb_rd,
    input [31:0] ex_mem_alu_result,
    input [31:0] mem_wb_write_data,
    // ---- duong dau phay dong -----------------------------------------------
    // id_ex_rs1 / id_ex_rs2 duoc dung LAI cho fs1 / fs2: chung la CUNG truong
    // bit instr[19:15] va instr[24:20]. Chi fs3 (instr[31:27]) la moi.
    input [4:0] id_ex_fs3,
    input [31:0] id_ex_read_f_data1,
    input [31:0] id_ex_read_f_data2,
    input [31:0] id_ex_read_f_data3,
    input ex_mem_f_reg_write,
    input ex_mem_f_mem_to_reg,
    input mem_wb_f_reg_write,
    input [31:0] ex_mem_fpu_result,
    input [31:0] mem_wb_f_write_data,
    output [31:0] alu_in1,
    output [31:0] alu_in2,
    output [31:0] mem_write_data,
    output [31:0] fpu_in1,
    output [31:0] fpu_in2,
    output [31:0] fpu_in3
);
    reg [1:0] forward_a;
    reg [1:0] forward_b;

    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1) &&
                !(ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))) begin
            forward_a = 2'b01;
        end

        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2) &&
                !(ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2))) begin
            forward_b = 2'b01;
        end
    end

    assign alu_in1 = (forward_a == 2'b00) ? id_ex_read_data1 :
                     (forward_a == 2'b01) ? mem_wb_write_data :
                     ex_mem_alu_result;

    assign alu_in2 = (id_ex_alu_src) ? id_ex_ext_imm : mem_write_data;

    assign mem_write_data = (forward_b == 2'b00) ? id_ex_read_data2 :
                            (forward_b == 2'b01) ? mem_wb_write_data :
                            ex_mem_alu_result;

    // =========================================================================
    // Duong dau phay dong.
    //
    // HAI khac biet BAN CHAT so voi duong so nguyen - ban cu sai ca hai:
    //
    // 1. KHONG co ngoai le "rd != 0". f0 la mot thanh ghi THAT, ghi duoc va doc
    //    duoc (khong nhu x0). Chep dieu kien `!= 5'd0` tu ben x sang se lam MAT
    //    ket qua moi khi dich la f0 - loi im lang, chi lo ra khi trinh bien dich
    //    tinh co chon f0.
    //
    // 2. Nguon o EX/MEM phai LOAI FLW ra. Voi mot `flw` thi ex_mem_f_reg_write
    //    bang 1 nhung ex_mem_fpu_result KHONG mang du lieu doc ve - du lieu con
    //    nam tren duong bo nho va chi xuat hien o MEM/WB. Forward tu day se lay
    //    phai rac. pipeline_control_unit da co interlock chan truong hop nay,
    //    nen dieu kien o day la LOP CHAN THU HAI: neu interlock bi sua hong thi
    //    trieu chung se la mot bong bong thua chu khong phai du lieu sai.
    //
    // Khong can uu tien "EX/MEM che MEM/WB" bang mot phep phu dinh nhu ben x vi
    // chuoi dieu kien ?: da lam dung viec do theo thu tu.
    // =========================================================================
    wire fwd_ex_ok = ex_mem_f_reg_write && !ex_mem_f_mem_to_reg;

    wire fwd_f1_ex = fwd_ex_ok          && (ex_mem_rd == id_ex_rs1);
    wire fwd_f1_wb = mem_wb_f_reg_write && (mem_wb_rd == id_ex_rs1);
    wire fwd_f2_ex = fwd_ex_ok          && (ex_mem_rd == id_ex_rs2);
    wire fwd_f2_wb = mem_wb_f_reg_write && (mem_wb_rd == id_ex_rs2);
    wire fwd_f3_ex = fwd_ex_ok          && (ex_mem_rd == id_ex_fs3);
    wire fwd_f3_wb = mem_wb_f_reg_write && (mem_wb_rd == id_ex_fs3);

    assign fpu_in1 = fwd_f1_ex ? ex_mem_fpu_result :
                     fwd_f1_wb ? mem_wb_f_write_data : id_ex_read_f_data1;

    assign fpu_in2 = fwd_f2_ex ? ex_mem_fpu_result :
                     fwd_f2_wb ? mem_wb_f_write_data : id_ex_read_f_data2;

    assign fpu_in3 = fwd_f3_ex ? ex_mem_fpu_result :
                     fwd_f3_wb ? mem_wb_f_write_data : id_ex_read_f_data3;

endmodule
