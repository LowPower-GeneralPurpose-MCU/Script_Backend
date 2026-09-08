//==================================================================================================
// File: control_unit.v
//==================================================================================================
`timescale 1ns / 1ps

module main_control_unit #(
    // AMO*.W bat DONG THOI mem_read va mem_write, nhung FSM cua data_cache o
    // IDLE kiem `if (cpu_read_req) ... else if (cpu_write_req)` - doc thang,
    // phan GHI bi nuot im lang. Vi vay A mac dinh TAT: AMO tro thanh
    // illegal-instruction thay vi chay sai am tham.
    //
    // Bat len 1 CHI KHI data_cache da co FSM AMO_READ -> ALU -> AMO_WRITE (va
    // AWLOCK that), va phai bat CUNG LUC voi localparam ENABLE_A_EXTENSION
    // trong register_file.v (bit A cua MISA) - neu khong MISA lai lech decoder.
    parameter ENABLE_A_EXTENSION = 0,
    parameter ENABLE_F_EXTENSION = 0
) (
    input [6:0] opcode,
    input [6:0] funct7,
    input [2:0] funct3,
    input [4:0] rs2,
    output reg reg_write,
    output reg alu_src,
    output reg mem_write,
    output reg mem_read,
    output reg mem_to_reg,
    output reg branch,
    output reg jal,
    output reg jalr,
    output reg lui,
    output reg auipc,
    output reg mem_unsigned,
    output reg [1:0] alu_op,
    output reg [1:0] mem_size,
    output reg [2:0] md_operation,
    output reg fpu_en,
    output reg f_reg_write,
    output reg f_mem_to_reg,
    output reg f_mem_write,
    output reg f_to_x,
    output reg x_to_f,
    output reg [4:0] fpu_operation,
    // V5 - ma lenh khong ton tai -> illegal-instruction (mcause = 2, mtval = ma lenh).
    // Quy tac fail-safe: khoi tao bang 1, MOI nhanh hop le phai tu ha xuong 0.
    // Nhanh `default` rong cua case cu khien moi opcode la chay im lang nhu NOP.
    output reg illegal_instr
);

    always @(*) begin 
        reg_write = 1'b0;
        alu_src = 1'b0;
        mem_write = 1'b0;
        mem_read = 1'b0;
        mem_to_reg = 1'b0;
        branch = 1'b0;
        jal = 1'b0;
        jalr = 1'b0;
        lui = 1'b0;
        auipc = 1'b0;
        alu_op = 2'b00;
        mem_size = 2'b00;
        mem_unsigned = 1'b0;
        md_operation = 3'b000;
        fpu_en = 1'b0;
        f_reg_write = 1'b0;
        f_mem_to_reg = 1'b0;
        f_mem_write = 1'b0;
        f_to_x = 1'b0;
        x_to_f = 1'b0;
        fpu_operation = 5'b00000;
        illegal_instr = 1'b1;      // fail-safe: nhanh hop le phai tu ha xuong

        case (opcode)
            7'b0110011: begin
                reg_write = 1'b1;
                alu_op = 2'b10;
                // Bang tra cuu cu la ANH XA DONG NHAT funct3 -> md_operation.
                // Gan vo dieu kien la vo hai: chi khi funct7 = 0x01 thi md_type moi bat.
                md_operation = funct3;
                case (funct7)
                    7'b0000000: illegal_instr = 1'b0;   // add sll slt sltu xor srl or and
                    7'b0000001: illegal_instr = 1'b0;   // M: ca 8 funct3 deu ton tai
                    // sub / sra la HAI o duy nhat cua funct7 = 0x20. `xor`/`add` voi
                    // funct7 = 0x20 KHONG ton tai - truoc day chung chay nhu add.
                    7'b0100000: illegal_instr = (funct3 != 3'b000) && (funct3 != 3'b101);
                    default:    ;                       // giu illegal_instr = 1
                endcase
            end
            
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b10;
                case (funct3)
                    // RV32: shamt = instr[24:20], nen instr[25] PHAI bang 0.
                    3'b001:  illegal_instr = (funct7 != 7'b0000000);                  // slli
                    3'b101:  illegal_instr = (funct7 != 7'b0000000) &&
                                             (funct7 != 7'b0100000);                  // srli/srai
                    default: illegal_instr = 1'b0;
                endcase
            end
            
            7'b0000011: begin
                alu_src = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;
                reg_write = 1'b1;
                alu_op = 2'b00;
                case (funct3)
                    3'b000: begin mem_size = 2'b00; mem_unsigned = 1'b0; illegal_instr = 1'b0; end // lb
                    3'b001: begin mem_size = 2'b01; mem_unsigned = 1'b0; illegal_instr = 1'b0; end // lh
                    3'b010: begin mem_size = 2'b10; mem_unsigned = 1'b0; illegal_instr = 1'b0; end // lw
                    3'b100: begin mem_size = 2'b00; mem_unsigned = 1'b1; illegal_instr = 1'b0; end // lbu
                    3'b101: begin mem_size = 2'b01; mem_unsigned = 1'b1; illegal_instr = 1'b0; end // lhu
                    // 011 = ld, 110 = lwu, 111 = reserved: deu la RV64. Truoc day chung
                    // chay nhu `lw`. Ha mem_read de dia chi rac khong di toi bo nho.
                    default: begin mem_size = 2'b10; mem_unsigned = 1'b0; mem_read = 1'b0; end
                endcase
            end
            
            7'b0100011: begin
                alu_src = 1'b1;
                mem_write = 1'b1;
                alu_op = 2'b00;
                case (funct3)
                    3'b000: begin mem_size = 2'b00; illegal_instr = 1'b0; end   // sb
                    3'b001: begin mem_size = 2'b01; illegal_instr = 1'b0; end   // sh
                    3'b010: begin mem_size = 2'b10; illegal_instr = 1'b0; end   // sw
                    // 011 = sd (RV64), 100..111 = reserved. Truoc day chay nhu `sw`:
                    // mot ma lenh khong ton tai GHI THAT vao bo nho.
                    default: begin mem_size = 2'b10; mem_write = 1'b0; end
                endcase
            end

            7'b0101111: begin
                // funct3 = 011 la AMO*.D - chi RV64. Moi funct3 khac khong ton tai.
                // Khi ENABLE_A_EXTENSION = 0 thi ca nhom giu illegal_instr = 1.
                if (ENABLE_A_EXTENSION && funct3 == 3'b010) begin
                    alu_src = 1'b1;
                    alu_op = 2'b00;
                    mem_size = 2'b10;
                    reg_write = 1'b1;
                    mem_to_reg = 1'b1;
                    case (funct7[6:2])
                        5'b00010: begin mem_read = 1'b1; mem_write = 1'b0; illegal_instr = 1'b0; end // LR.W
                        5'b00011: begin mem_read = 1'b0; mem_write = 1'b1; illegal_instr = 1'b0; end // SC.W
                        // Chin ma AMO con lai: doc gia tri cu VA ghi gia tri moi.
                        5'b00000, 5'b00001, 5'b00100, 5'b01000, 5'b01100,
                        5'b10000, 5'b10100, 5'b11000, 5'b11100: begin
                            mem_read = 1'b1; mem_write = 1'b1; illegal_instr = 1'b0;
                        end
                        // Ma chua dinh nghia: truoc day roi vao `default` va chay
                        // read-modify-write voi amo_write_data = rs2 - tuc nhu mot `sw`.
                        default: begin mem_read = 1'b0; mem_write = 1'b0; end
                    endcase
                end
            end
            
            7'b1100011: begin
                branch = 1'b1;
                alu_op = 2'b01;
                // 010 va 011 la hai o duy nhat khong ton tai. Truoc day chung chay qua
                // bo so sanh voi `default: branch_taken = 0` - mot lenh nhay "khong bao
                // gio nhay", chay im lang.
                illegal_instr = (funct3 == 3'b010) || (funct3 == 3'b011);
            end
            
            7'b0110111: begin lui   = 1'b1; reg_write = 1'b1; illegal_instr = 1'b0; end  // LUI
            7'b0010111: begin auipc = 1'b1; reg_write = 1'b1; illegal_instr = 1'b0; end  // AUIPC
            7'b1101111: begin jal   = 1'b1; reg_write = 1'b1; illegal_instr = 1'b0; end  // JAL

            7'b1100111: begin                                                            // JALR
                jalr = 1'b1;
                reg_write = 1'b1;
                alu_src = 1'b1;
                illegal_instr = (funct3 != 3'b000);
            end

            // ---- FENCE ----
            // Viet thanh nhanh RIENG de no khong bi mac dinh moi thanh illegal.
            // funct3 = 001 la FENCE.I (Zifencei): CHUA hien thuc duong invalidate
            // I-cache o SoC nay, nen bao illegal thay vi chay im lang nhu NOP.
            //
            // funct3 = 000 (FENCE) hien van la NOP, nhung ly do CU cho dieu do -
            // "mot hart, bo nho hop nhat khong dat lai thu tu" - DA KHONG CON
            // DUNG tu khi D-cache co store buffer (MEMORY_FIX_PLAN.md Phase 1):
            // mot store cacheable retire truoc khi no toi RAM, nen no CO the bi
            // mot master khac (debugger qua SBA) nhin thay dao thu tu.
            //
            // Thu tu voi DMA van an toan theo cau truc: khoi dong DMA la mot ghi
            // MMIO, ma moi truy cap uncached deu ep D-cache xa het store buffer
            // truoc.  Cho ho duy nhat la debugger ghi bo nho luc core dang chay.
            //
            // De `fence` xa buffer that su can dan mot bit dieu khien tu day
            // xuyen id_ex/ex_mem toi cong `cpu_fence` cua data_cache.  Chua lam.
            7'b0001111: begin
                illegal_instr = (funct3 != 3'b000);
            end

            // ---- SYSTEM ----
            // funct3 = 000: bon lenh dac quyen ecall/ebreak/mret/wfi chi khac nhau o
            // instr[31:20] ma o day khong co du 32 bit - GIU illegal_instr = 1, va
            // instruction_decode (noi bon hang so 32 bit da ton tai) ha no xuong.
            // funct3 = 100 khong ton tai trong Zicsr: truoc day no dat reg_write = 1 va
            // csr_op = 2'b00, nen chay nhu mot lenh doc CSR khong ghi.
            7'b1110011: begin
                if (funct3 != 3'b000) begin
                    reg_write = 1'b1;
                    illegal_instr = (funct3 == 3'b100);
                end
            end
            
            7'b0000111: begin
                if (ENABLE_F_EXTENSION) begin
                    alu_src = 1'b1;
                    mem_read = 1'b1;
                    f_mem_to_reg = 1'b1;
                    f_reg_write = 1'b1;
                    alu_op = 2'b00;
                    mem_size = 2'b10;
                end
            end
            
            7'b0100111: begin
                if (ENABLE_F_EXTENSION) begin
                    alu_src = 1'b1;
                    mem_write = 1'b1;
                    f_mem_write = 1'b1;
                    alu_op = 2'b00;
                    mem_size = 2'b10;
                end
            end
            
            7'b1010011: begin
                if (ENABLE_F_EXTENSION) begin
                    fpu_en = 1'b1;
                    case (funct7)
                        7'b0000000: begin
                            f_reg_write = 1'b1;
                            fpu_operation = 5'b00000;
                        end
                        7'b0000100: begin
                            f_reg_write = 1'b1;
                            fpu_operation = 5'b00001;
                        end
                        7'b0001000: begin
                            f_reg_write = 1'b1;
                            fpu_operation = 5'b00010;
                        end
                        7'b0001100: begin
                            f_reg_write = 1'b1;
                            fpu_operation = 5'b01000;
                        end
                        7'b0101100: begin
                            f_reg_write = 1'b1;
                            fpu_operation = 5'b01001;
                        end
                        7'b0010000: begin
                            f_reg_write = 1'b1;
                            case (funct3)
                                3'b000: fpu_operation = 5'b01100;
                                3'b001: fpu_operation = 5'b01101;
                                3'b010: fpu_operation = 5'b01110;
                                default: fpu_operation = 5'b01100;
                            endcase
                        end
                        7'b0010100: begin
                            f_reg_write = 1'b1;
                            case (funct3)
                                3'b000: fpu_operation = 5'b01010;
                                3'b001: fpu_operation = 5'b01011;
                                default: fpu_operation = 5'b01010;
                            endcase
                        end
                        7'b1010000: begin
                            f_to_x = 1'b1;
                            reg_write = 1'b1;
                            case (funct3)
                                3'b010: fpu_operation = 5'b00101;
                                3'b001: fpu_operation = 5'b00110;
                                3'b000: fpu_operation = 5'b00111;
                                default: fpu_operation = 5'b00101;
                            endcase
                        end
                        7'b1100000: begin
                            f_to_x = 1'b1;
                            reg_write = 1'b1;
                            if (rs2[0]) begin
                                fpu_operation = 5'b10010;
                            end else begin
                                fpu_operation = 5'b00011;
                            end
                        end
                        7'b1101000: begin
                            x_to_f = 1'b1;
                            f_reg_write = 1'b1;
                            if (rs2[0]) begin
                                fpu_operation = 5'b10011;
                            end else begin
                                fpu_operation = 5'b00100;
                            end
                        end
                        7'b1110000: begin
                            f_to_x = 1'b1;
                            reg_write = 1'b1;
                            case (funct3)
                                3'b000: fpu_operation = 5'b01111;
                                3'b001: fpu_operation = 5'b10001;
                                default: fpu_operation = 5'b01111;
                            endcase
                        end
                        7'b1111000: begin
                            x_to_f = 1'b1;
                            f_reg_write = 1'b1;
                            fpu_operation = 5'b10000;
                        end
                        default: fpu_en = 1'b0;
                    endcase
                end
            end
            
            7'b1000011: begin
                if (ENABLE_F_EXTENSION) begin
                    fpu_en = 1'b1;
                    f_reg_write = 1'b1;
                    fpu_operation = 5'b10100;
                end
            end
            
            7'b1000111: begin
                if (ENABLE_F_EXTENSION) begin
                    fpu_en = 1'b1;
                    f_reg_write = 1'b1;
                    fpu_operation = 5'b10101;
                end
            end
            
            7'b1001011: begin
                if (ENABLE_F_EXTENSION) begin
                    fpu_en = 1'b1;
                    f_reg_write = 1'b1;
                    fpu_operation = 5'b10110;
                end
            end
            
            7'b1001111: begin
                if (ENABLE_F_EXTENSION) begin
                    fpu_en = 1'b1;
                    f_reg_write = 1'b1;
                    fpu_operation = 5'b10111;
                end
            end
            
            default: begin
            end
        endcase
    end
    
endmodule


module alu_control_unit (
    input [1:0] alu_op,
    input [2:0] funct3,
    input [6:0] funct7,
    input [6:0] opcode,
    output reg [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0010;
            2'b01: alu_ctrl = 4'b0110;
            2'b10: begin
                if (opcode == 7'b0010011) begin
                    case (funct3)
                        3'b000: alu_ctrl = 4'b0010;
                        3'b010: alu_ctrl = 4'b0111;
                        3'b011: alu_ctrl = 4'b1010;
                        3'b100: alu_ctrl = 4'b0100;
                        3'b110: alu_ctrl = 4'b0001;
                        3'b111: alu_ctrl = 4'b0000;
                        3'b001: alu_ctrl = 4'b1000;
                        3'b101: begin
                            if (funct7[5]) begin
                                alu_ctrl = 4'b1011;
                            end else begin
                                alu_ctrl = 4'b1001;
                            end
                        end
                    endcase
                end else begin
                    case (funct3)
                        3'b000: begin
                            if (funct7[5]) begin
                                alu_ctrl = 4'b0110;
                            end else begin
                                alu_ctrl = 4'b0010;
                            end
                        end
                        3'b001: alu_ctrl = 4'b1000;
                        3'b010: alu_ctrl = 4'b0111;
                        3'b011: alu_ctrl = 4'b1010;
                        3'b100: alu_ctrl = 4'b0100;
                        3'b101: begin
                            if (funct7[5]) begin
                                alu_ctrl = 4'b1011;
                            end else begin
                                alu_ctrl = 4'b1001;
                            end
                        end
                        3'b110: alu_ctrl = 4'b0001;
                        3'b111: alu_ctrl = 4'b0000;
                    endcase
                end
            end
            default: alu_ctrl = 4'b0010;
        endcase
    end
    
endmodule
