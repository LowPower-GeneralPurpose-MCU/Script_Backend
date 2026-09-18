//==================================================================================================
// File: core/fpu_defines.vh
//
// Ma hoa `fpu_operation` (5 bit) dung chung boi HAI file:
//   core/block_unit/control_unit.v        - giai ma, SINH ma
//   core/block_unit/floating_point_unit.v - thuc thi, TIEU THU ma
//
// Hai noi phai dung MOT bang. Chep hang so sang ca hai file la cach chac chan
// nhat de chung lech nhau sau vai lan sua - cung ly do `clint_defines.vh` va
// `dma_defines.vh` ton tai. Include theo duong tuong doi voi $RTL_ROOT (giong
// `include "memory/boot_rom_image.vh"` trong axi_rom.v), nen KHONG can them
// thu muc nao vao RTL_INCLUDE_DIRS cua rtl_filelist.tcl hay vao `-i` cua
// run_soc_sim.sh.
//==================================================================================================
`ifndef FPU_DEFINES_VH
`define FPU_DEFINES_VH

// ---- nhom FMA: a*b + c. FADD/FSUB/FMUL deu chay qua day (xem UNPACK) --------
`define FPOP_ADD       5'd0    // fadd.s     :  a * 1.0 + b
`define FPOP_SUB       5'd1    // fsub.s     :  a * 1.0 - b
`define FPOP_MUL       5'd2    // fmul.s     :  a * b   (khong co so hang cong)
`define FPOP_MADD      5'd3    // fmadd.s    :   (a*b) + c
`define FPOP_MSUB      5'd4    // fmsub.s    :   (a*b) - c
`define FPOP_NMSUB     5'd5    // fnmsub.s   : -(a*b) + c
`define FPOP_NMADD     5'd6    // fnmadd.s   : -(a*b) - c

// ---- duong lap rieng --------------------------------------------------------
`define FPOP_DIV       5'd7
`define FPOP_SQRT      5'd8

// ---- thao tac bit, khong lam tron, khong co co ngoai le ---------------------
`define FPOP_SGNJ      5'd9
`define FPOP_SGNJN     5'd10
`define FPOP_SGNJX     5'd11
`define FPOP_MV_X_W    5'd12    // fmv.x.w : f -> x, chuyen bit tho
`define FPOP_MV_W_X    5'd13    // fmv.w.x : x -> f, chuyen bit tho
`define FPOP_CLASS     5'd14    // fclass.s

// ---- so sanh: ket qua la mot so nguyen 0/1 trong thanh ghi x ---------------
`define FPOP_EQ        5'd15    // quiet   : chi sNaN moi dat NV
`define FPOP_LT        5'd16    // signal  : MOI NaN deu dat NV
`define FPOP_LE        5'd17    // signal
`define FPOP_MIN       5'd18    // NaN yen lang KHONG dat NV (spec 2.2 tro di)
`define FPOP_MAX       5'd19

// ---- chuyen doi -------------------------------------------------------------
`define FPOP_CVT_W_S   5'd20    // float -> int co dau
`define FPOP_CVT_WU_S  5'd21    // float -> int khong dau
`define FPOP_CVT_S_W   5'd22    // int co dau    -> float
`define FPOP_CVT_S_WU  5'd23    // int khong dau -> float

// ---- che do lam tron (fcsr.frm va instr[14:12]) ----------------------------
`define FRM_RNE        3'b000   // gan nhat, hoa thi chan
`define FRM_RTZ        3'b001   // ve 0
`define FRM_RDN        3'b010   // ve -inf
`define FRM_RUP        3'b011   // ve +inf
`define FRM_RMM        3'b100   // gan nhat, hoa thi ra xa 0
`define FRM_DYN        3'b111   // lay tu fcsr.frm

// ---- vi tri bit trong fflags / fcsr[4:0] -----------------------------------
`define FFLAG_NX       0        // inexact
`define FFLAG_UF       1        // underflow
`define FFLAG_OF       2        // overflow
`define FFLAG_DZ       3        // divide by zero
`define FFLAG_NV       4        // invalid operation

`endif
