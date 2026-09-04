//==================================================================================================
// File: register_file.v
//==================================================================================================

module register_file (
    input clk,
    input reset_n,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] read_reg1_lane1,
    input [4:0] read_reg2_lane1,
    input mem_wb_reg_write,
    input [4:0] mem_wb_rd,
    input [31:0] mem_wb_write_data,
    input mem_wb_reg_write_lane1,
    input [4:0] mem_wb_rd_lane1,
    input [31:0] mem_wb_write_data_lane1,
    input ooo_commit_valid0,
    input [4:0] ooo_commit_rd0,
    input [31:0] ooo_commit_data0,
    input ooo_commit_valid1,
    input [4:0] ooo_commit_rd1,
    input [31:0] ooo_commit_data1,
    output [31:0] read_data1,
    output [31:0] read_data2,
    output [31:0] read_data1_lane1,
    output [31:0] read_data2_lane1,
    
    // --- DEBUG CHUYÊN DỤNG ---
    input  wire        dbg_mode,           // Báo hiệu CPU đang Halt
    input  wire [4:0]  dbg_read_addr,      // DM muốn đọc thanh ghi nào
    output wire [31:0] dbg_read_data,      // Dữ liệu trả về cho DM
    input  wire        dbg_write_en,       // DM muốn ghi đè
    input  wire [4:0]  dbg_write_addr,     // Địa chỉ DM muốn ghi
    input  wire [31:0] dbg_write_data      // Dữ liệu DM ghi
);

`ifdef FPGA
    (* ram_style = "distributed" *)
`endif
    reg [31:0] rf_main [0:31];
    reg [31:0] x2_sp;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            x2_sp <= 32'h8001_0000;
        end else begin
            // Ưu tiên cao nhất cho Debug Mode ghi đè
            if (dbg_mode && dbg_write_en) begin
                if (dbg_write_addr == 5'd2) begin
                    x2_sp <= dbg_write_data;
                end else if (dbg_write_addr != 5'd0) begin
                    rf_main[dbg_write_addr] <= dbg_write_data;
                end
            end 
            // Nếu không Halt, pipeline hoạt động bình thường
            else begin
                // Ghi nhiều kết quả commit trong cùng chu kỳ; cổng trẻ hơn nằm sau.
                if (mem_wb_reg_write) begin
                    if (mem_wb_rd == 5'd2) begin
                        x2_sp <= mem_wb_write_data;
                    end else if (mem_wb_rd != 5'd0) begin
                        rf_main[mem_wb_rd] <= mem_wb_write_data;
                    end
                end
                if (mem_wb_reg_write_lane1) begin
                    if (mem_wb_rd_lane1 == 5'd2) begin
                        x2_sp <= mem_wb_write_data_lane1;
                    end else if (mem_wb_rd_lane1 != 5'd0) begin
                        rf_main[mem_wb_rd_lane1] <= mem_wb_write_data_lane1;
                    end
                end
                if (ooo_commit_valid0) begin
                    if (ooo_commit_rd0 == 5'd2) begin
                        x2_sp <= ooo_commit_data0;
                    end else if (ooo_commit_rd0 != 5'd0) begin
                        rf_main[ooo_commit_rd0] <= ooo_commit_data0;
                    end
                end
                if (ooo_commit_valid1) begin
                    if (ooo_commit_rd1 == 5'd2) begin
                        x2_sp <= ooo_commit_data1;
                    end else if (ooo_commit_rd1 != 5'd0) begin
                        rf_main[ooo_commit_rd1] <= ooo_commit_data1;
                    end
                end
            end
        end
    end

    // Các cổng đọc của CPU
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 :
                        (read_reg1 == 5'd2) ? x2_sp : rf_main[read_reg1];
                        
    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 :
                        (read_reg2 == 5'd2) ? x2_sp : rf_main[read_reg2];

    assign read_data1_lane1 = (read_reg1_lane1 == 5'd0) ? 32'd0 :
                              (read_reg1_lane1 == 5'd2) ? x2_sp : rf_main[read_reg1_lane1];
                        
    assign read_data2_lane1 = (read_reg2_lane1 == 5'd0) ? 32'd0 :
                              (read_reg2_lane1 == 5'd2) ? x2_sp : rf_main[read_reg2_lane1];

    // Cổng đọc riêng biệt của Debug (Tổ hợp, trả về ngay lập tức)
    assign dbg_read_data = (dbg_read_addr == 5'd0) ? 32'd0 :
                           (dbg_read_addr == 5'd2) ? x2_sp : rf_main[dbg_read_addr];
                        
endmodule


module f_register_file (
    input clk, 
    input reset_n,
    input [4:0] read_reg1, 
    input [4:0] read_reg2,
    input [4:0] read_reg1_lane1,
    input [4:0] read_reg2_lane1,
    output [31:0] read_data1, 
    output [31:0] read_data2,
    output [31:0] read_data1_lane1,
    output [31:0] read_data2_lane1,
    input reg_write_en,   
    input [4:0] write_reg,    
    input [31:0] write_data,
    input reg_write_en_lane1,
    input [4:0] write_reg_lane1,
    input [31:0] write_data_lane1,
    
    // --- BỔ SUNG CỔNG DEBUG CHUYÊN DỤNG ---
    input  wire        dbg_mode,           // Trạng thái CPU đang Halt
    input  wire [4:0]  dbg_read_addr,      // Địa chỉ FPR cần đọc
    output wire [31:0] dbg_read_data,      // Dữ liệu trả về
    input  wire        dbg_write_en,       // Cho phép DM ghi đè
    input  wire [4:0]  dbg_write_addr,     // Địa chỉ FPR cần ghi
    input  wire [31:0] dbg_write_data      // Dữ liệu DM ghi
);
`ifdef FPGA
    (* ram_style = "distributed" *)
`endif
    reg [31:0] f_regfile [0:31];
    
    // Đọc cho Pipeline
    assign read_data1 = f_regfile[read_reg1];
    assign read_data2 = f_regfile[read_reg2];
    assign read_data1_lane1 = f_regfile[read_reg1_lane1];
    assign read_data2_lane1 = f_regfile[read_reg2_lane1];
    
    // Đọc cho Debug (Tổ hợp, trả về ngay lập tức)
    assign dbg_read_data = f_regfile[dbg_read_addr];
    
    integer i;
    // CO Y dung reset dong bo o day, va nhanh reset CO Y de trong: mang thanh
    // ghi dau phay dong khong duoc reset (phan mem phai tu nap truoc khi doc),
    // nen khong co trang thai nao can xoa - `if (!reset_n)` chi de CHAN GHI
    // trong luc reset.  Dung doi sang `posedge clk or negedge reset_n`: lam vay
    // se sinh ra chan reset cho 32 thanh ghi 32-bit ma khong duoc gi ca.
    // Moi khoi tuan tu KHAC trong thiet ke deu dung reset bat dong bo.
    always @(posedge clk) begin
        if (!reset_n) begin

        end else begin
            // Ưu tiên cao nhất cho Debug Mode ghi đè
            if (dbg_mode && dbg_write_en) begin
                f_regfile[dbg_write_addr] <= dbg_write_data;
            end 
            // Nếu không Halt, pipeline hoạt động bình thường
            else begin
                if (reg_write_en) begin
                    f_regfile[write_reg] <= write_data;
                end
                if (reg_write_en_lane1) begin
                    f_regfile[write_reg_lane1] <= write_data_lane1;
                end
            end
        end
    end
endmodule


module csr_register_file (
    input clk,
    input reset_n,
    input meip_i, // External Interrupt Pending
    input msip_i, // Software Interrupt Pending
    input mtip_i, // Timer Interrupt Pending
    input [11:0] csr_addr,
    output reg [31:0] csr_read_data,
    input [11:0] csr_addr_lane1,
    output reg [31:0] csr_read_data_lane1,
    input [11:0] csr_write_addr,
    input [31:0] csr_write_data,
    input [1:0] csr_op,
    input csr_write_en,
    input count_en,
    input instret_en,
    input trap_enter,
    input mret_exec,
    input [31:0] trap_cause,
    input [31:0] trap_pc,
    input [31:0] trap_val,
    output [31:0] mtvec_out,
    output [31:0] mepc_out,
    output [31:0] mie_out,
    output mstatus_mie,

    // --- CỔNG GIAO TIẾP DEBUG ---
    input         dbg_halt_req,
    input         dbg_halted,
    input  [31:0] debug_pc_in,
    output [31:0] dpc_out,
    output [31:0] dcsr_out,
    
    input  [11:0] dbg_reg_read_addr,  // Trỏ thẳng vào địa chỉ CSR 12-bit
    output reg [31:0] dbg_read_data,  // Đọc mọi CSR
    input         dbg_reg_write_en,
    input  [11:0] dbg_reg_write_addr, // Trỏ thẳng vào địa chỉ CSR 12-bit
    input  [31:0] dbg_reg_write_data,

    // Vi pham "ghi vao CSR chi doc" -> lenh nay phai raise illegal-instruction.
    // Tin hieu duoc tinh tu {csr_write_addr, csr_op, csr_write_en} nen no DA o
    // dung tang EX/MEM, cung tang voi ecall/ebreak - mepc se tro dung lenh gay
    // loi ma khong can them logic nao.
    output                   csr_illegal_write
);

    localparam [31:0] MVENDORID  = 32'h0;
    localparam [31:0] MARCHID    = 32'h0;
    localparam [31:0] MIMPID     = 32'h01000000;
    localparam [31:0] MHARTID    = 32'h0;
    // =====================================================================
    // F1 - MISA phai mo ta DUNG cai da hien thuc.
    //
    // Gia tri cu 32'h40001120 khai bao I + M + F, va KHONG khai A, KHONG khai C.
    // Ca ba deu sai so voi RTL:
    //
    //   F (bit 5)  : KHAI nhung KHONG CO. riscv_pipeline.v dat ENABLE_FPU = 0,
    //                f_register_file tra ve 0, wb_f_write_data = 0. Thu vien
    //                runtime doc MISA de chon code path -> se phat lenh FP roi
    //                nhan ket qua rac, im lang. Bo bit F.
    //   C (bit 2)  : CO nhung KHONG KHAI. Bo giai nen + FSM ghep nua lenh (F3)
    //                trong instruction_fetch da hien thuc day du RVC. Khai len.
    //   A (bit 0)  : mot phan. LR.W / SC.W chay dung. Nhung 9 ma AMO*.W thi
    //                KHONG: chung bat dong thoi mem_read va mem_write, ma FSM
    //                cua data_cache o IDLE kiem `if (cpu_read_req) ... else if
    //                (cpu_write_req)` - doc thang, phan GHI bi nuot im lang.
    //                Vi vay MAC DINH tat A. Khi nao data_cache co FSM
    //                AMO_READ -> ALU -> AMO_WRITE (va AWLOCK that) thi bat
    //                ENABLE_A_EXTENSION len 1 O CA HAI NOI:
    //                  - localparam ENABLE_A_EXTENSION o day
    //                  - parameter  ENABLE_A_EXTENSION cua main_control_unit
    //                Hai noi phai khop, neu khong MISA lai lech voi decoder.
    // =====================================================================
    localparam ENABLE_A_EXTENSION = 0;   // xem ghi chu tren truoc khi bat len 1

    localparam integer MISA_A = 0;
    localparam integer MISA_C = 2;
    localparam integer MISA_I = 8;
    localparam integer MISA_M = 12;

    localparam [31:0] MISA = (32'd1 << 30)     |  // MXL = 1 -> XLEN = 32
                             (32'd1 << MISA_I) |  // I - co so
                             (32'd1 << MISA_M) |  // M - nhan / chia
                             (32'd1 << MISA_C) |  // C - lenh nen 16 bit
                             ((ENABLE_A_EXTENSION != 0) ? (32'd1 << MISA_A) : 32'd0);

    reg [31:0] mstatus;
    reg [31:0] mie;
    reg [31:0] mtvec;
    reg [31:0] mscratch;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mtval;
    
    // Debug CSRs
    reg [31:0] dcsr;
    reg [31:0] dpc;
    reg [31:0] dscratch0;

    wire [31:0] mip_val = {20'd0, meip_i, 3'd0, mtip_i, 3'd0, msip_i, 3'd0};

    reg [63:0] mcycle;
    reg [63:0] minstret;
    reg        dbg_halted_q;

    assign mtvec_out = mtvec;
    assign mepc_out = mepc;
    assign mstatus_mie = mstatus[3];
    assign mie_out = mie;
    
    // Bổ sung: Gán giá trị dpc ra cổng dpc_out
    assign dpc_out = dpc;
    assign dcsr_out = dcsr;

    function automatic [31:0] csr_read_value;
        input [11:0] addr;
        begin
            case (addr)
                12'hF11: csr_read_value = MVENDORID;
                12'hF12: csr_read_value = MARCHID;
                12'hF13: csr_read_value = MIMPID;
                12'hF14: csr_read_value = MHARTID;
                12'h301: csr_read_value = MISA;
                12'h300: csr_read_value = mstatus;
                12'h304: csr_read_value = mie;
                12'h305: csr_read_value = mtvec;
                12'h340: csr_read_value = mscratch;
                12'h341: csr_read_value = mepc;
                12'h342: csr_read_value = mcause;
                12'h343: csr_read_value = mtval;
                12'h344: csr_read_value = mip_val;
                12'hB00, 12'hC00, 12'hC01: csr_read_value = mcycle[31:0];
                12'hB80, 12'hC80, 12'hC81: csr_read_value = mcycle[63:32];
                12'hB02, 12'hC02:          csr_read_value = minstret[31:0];
                12'hB82, 12'hC82:          csr_read_value = minstret[63:32];
                12'h7b0: csr_read_value = dcsr;
                12'h7b1: csr_read_value = dpc;
                12'h7b2: csr_read_value = dscratch0;
                default: csr_read_value = 32'b0;
            endcase
        end
    endfunction

    // =====================================================================
    // Phat hien ghi vao CSR chi doc.
    //
    // Quy uoc dia chi cua RISC-V: csr[11:10] == 2'b11 nghia la READ-ONLY. Nhom
    // nay gom mvendorid / marchid / mimpid / mhartid (0xF1x) va toan bo dai
    // 0xC00-0xCFF (cycle / time / instret ban chi doc). misa la 0x301 nen KHONG
    // thuoc nhom - dung, vi misa la WARL ghi duoc.
    //
    // Truoc day bang CSR xu ly moi dia chi nhu nhau: ghi vao mot CSR chi doc
    // hay khong ton tai chi don gian roi vao khoang khong, khong bao loi.
    //
    // Dieu kien PHAI la "lenh nay THUC SU ghi" (csr_op != 0): csrrs/csrrc voi
    // rs1 = x0 - tuc gia lenh `csrr` - khong ghi gi ca. Viec ep csr_op ve 0
    // trong truong hop do duoc lam o tang ID (instruction_decode.csr_op); neu
    // khong thi mot lenh `csrr t0, cycle` hoan toan hop le se bi bao illegal.
    // =====================================================================
    assign csr_illegal_write = csr_write_en && (csr_op != 2'b00) &&
                               (csr_write_addr[11:10] == 2'b11);

    // =====================================================================
    // G2 - danh sach nhay cua mux doc CSR PHAI liet ke tuong minh.
    //
    // `always @(*) csr_read_data = csr_read_value(csr_addr);` trong co ve dung,
    // nhung @(*) chi suy ra danh sach nhay tu cac tin hieu XUAT HIEN TRONG CAU
    // LENH. Cac thanh ghi ma function DOC BEN TRONG than cua no (mcycle,
    // minstret, mepc...) khong duoc mot so cong cu dua vao danh sach do.
    //
    // Hau qua rat kho thay: cong doc DONG BANG. Nhieu lenh `csrr t0, mcycle`
    // lien tiep co CUNG csr_addr, nen khoi khong bao gio duoc kich hoat lai va
    // deu tra ve gia tri tai thoi diem csr_addr doi lan cuoi. Bo dem VAN chay
    // dung, chi rieng duong doc la chet - mo hinh tham chieu khong bat duoc.
    //
    // KHI THEM MOT CSR MOI: them thanh ghi cua no vao ca csr_read_value LAN
    // danh sach duoi day. Quen dong thu hai = CSR do doc ra gia tri cu, im lang.
    // =====================================================================
    always @(csr_addr  or csr_addr_lane1 or dbg_reg_read_addr or
             mstatus   or mie            or mtvec     or mscratch or
             mepc      or mcause         or mtval     or mip_val  or
             mcycle    or minstret       or
             dcsr      or dpc            or dscratch0) begin
        csr_read_data = csr_read_value(csr_addr);
        csr_read_data_lane1 = csr_read_value(csr_addr_lane1);
        dbg_read_data = csr_read_value(dbg_reg_read_addr);
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mstatus   <= 32'h00003800;
            mie       <= 32'b0;
            mtvec     <= 32'b0;
            mscratch  <= 32'b0;
            mepc      <= 32'b0;
            mcause    <= 32'b0;
            mtval     <= 32'b0;
            mcycle    <= 64'b0;
            minstret  <= 64'b0;
            dcsr      <= 32'h00000003; // Privilege mode M
            dpc       <= 32'b0;
            dscratch0 <= 32'b0;
            dbg_halted_q <= 1'b0;
        end else begin
            dbg_halted_q <= dbg_halted;

            // 1. Logic tự động lưu PC & Cause khi CPU VỪA BỊ HALT (Cạnh lên)
            if (dbg_halted && !dbg_halted_q) begin
                dpc <= debug_pc_in;
                
                // Cập nhật nguyên nhân Halt vào dcsr[8:6]
                if (dbg_halt_req) begin
                    dcsr[8:6] <= 3'd3; // Cause 3: Dừng do bị yêu cầu Halt
                end else begin
                    dcsr[8:6] <= 3'd4; // Cause 4: Dừng do hoàn tất lệnh Step
                end
            end
            // 2. OpenOCD chủ động ghi đè DPC / DCSR qua lệnh Debug
            else if (dbg_reg_write_en && dbg_reg_write_addr == 12'h7b1) begin
                dpc <= dbg_reg_write_data;
            end
            else if (dbg_reg_write_en && dbg_reg_write_addr == 12'h7b0) begin
                dcsr <= dbg_reg_write_data;
            end
            // Nếu phần mềm cố tình ghi đè DPC bằng lệnh CSR write nội bộ...
            else if (csr_write_en && (csr_op != 2'b00) && (csr_write_addr == 12'h7b1)) begin
                dpc <= csr_write_data;
            end

            if (count_en) begin
                mcycle <= mcycle + 64'd1;
            end
            
            if (instret_en) begin
                minstret <= minstret + 64'd1;
            end
            
            if (trap_enter) begin
                mepc <= trap_pc;
                mcause <= trap_cause;
                mtval <= trap_val;
                mstatus[7] <= mstatus[3];
                mstatus[3] <= 1'b0;
                mstatus[12:11] <= 2'b11;
            end else if (mret_exec) begin
                mstatus[3] <= mstatus[7];
                mstatus[7] <= 1'b1;
                mstatus[12:11] <= 2'b11;
            end else if (csr_write_en && (csr_op != 2'b00)) begin
                case (csr_write_addr)
                    12'h300: begin
                        mstatus[3] <= csr_write_data[3];
                        mstatus[7] <= csr_write_data[7];
                        mstatus[12:11] <= csr_write_data[12:11];
                    end
                    12'h304: mie <= csr_write_data & 32'h00000888;
                    12'h305: mtvec <= csr_write_data;
                    12'h340: mscratch <= csr_write_data;
                    12'h341: mepc <= csr_write_data;
                    12'h342: mcause <= csr_write_data;
                    12'h343: mtval <= csr_write_data;
                    12'hB00: mcycle[31:0] <= csr_write_data;
                    12'hB80: mcycle[63:32] <= csr_write_data;
                    12'hB02: minstret[31:0] <= csr_write_data;
                    12'hB82: minstret[63:32] <= csr_write_data;
                    // Write Debug CSRs
                    12'h7b0: dcsr <= csr_write_data;
                    // 12'h7b1: dpc <= csr_write_data; // Đã xử lý ở khối ưu tiên phía trên
                    12'h7b2: dscratch0 <= csr_write_data;
                endcase
            end
        end
    end
    
endmodule
