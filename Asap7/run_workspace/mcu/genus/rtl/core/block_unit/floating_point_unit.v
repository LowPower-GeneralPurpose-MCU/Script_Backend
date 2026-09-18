//==================================================================================================
// File: floating_point_unit.v
//
// RV32F - don vi dau phay dong IEEE 754-2008 binary32, day du:
//
//   * subnormal CA O DAU VAO LAN DAU RA (gradual underflow), khong flush-to-zero
//   * ca 5 che do lam tron (RNE/RTZ/RDN/RUP/RMM) + DYN lay tu fcsr.frm
//   * ca 5 co ngoai le NV/DZ/OF/UF/NX
//   * FMA lam tron DUNG MOT LAN (khong phai mul roi add)
//   * ngu nghia NaN dung chuan: canonical qNaN 0x7FC00000, sNaN -> NV,
//     FMIN/FMAX tra ve toan hang KIA khi mot ben la NaN, FLT/FLE la phep so
//     sanh "signal" con FEQ la "quiet"
//
// ------------------------------------------------------------------------------
// BAN CU (truoc 2026-09-18) sai o nhung cho sau - ghi lai de khong ai khoi phuc:
//   - STATE_PACK co `exp_res == 0 -> POS_ZERO`: MOI ket qua subnormal bi nuot
//     thanh 0, tuc flush-to-zero am tham.
//   - Chi co RNE. instr[14:12] bi bo qua hoan toan.
//   - Khong co fflags -> fcsr khong the ton tai -> misa khong the khai bit F
//     (xem ghi chu F1 trong register_file.v).
//   - `has_nan` tra ve QNAN cho MOI lenh co NaN, ke ca FSGNJ/FMIN/FMAX/FEQ la
//     nhung lenh spec BAT BUOC phai co hanh vi khac.
//   - FMIN/FMAX/FLT so sanh `operand_a < operand_b` tren BIT THO, nen -0.0 va
//     +0.0 khong bang nhau va thu tu bi dao voi so am.
//   - Khong co FMADD/FMSUB/FNMSUB/FNMADD, FSGNJ*, FCLASS - decoder sinh ma cho
//     chung nhung FSM roi vao `default: state <= STATE_DONE` voi result rac.
//   - Toan hang duoc DOC o STATE_UNPACK, tuc MOT chu ky sau khi lenh vao EX. Khi
//     do mf_alu_stall da bat flush_ex_mem nen ex_mem_* da thanh bong bong va gia
//     tri forward BIEN MAT. Ban nay chot toan hang ngay o S_IDLE.
// ------------------------------------------------------------------------------
//
// CAU TRUC DUONG DU LIEU
//
// Mot bo tich luy `acc` 80 bit mang BAT BIEN:   gia tri = acc * 2^acc_exp
// Moi duong (FMA, DIV, SQRT, int->float) chi co viec nap acc + acc_exp roi
// giao cho chuoi chung NORM -> DENORM -> ROUND -> PACK. Nho vay logic lam tron,
// subnormal va overflow/underflow chi ton tai DUNG MOT BAN.
//
// FMA dung mot duong duy nhat (single-path) nen acc phai du rong cho ca hai
// truong hop xau nhat "c lon hon han tich" va "tich lon hon han c": 24 bit cua
// c dat cao nhat o bit 53 -> 77 bit, cong 1 bit nho -> 78. Lay 80 cho thoai mai.
// Dich canh bi CHAN o [-25, +53]: ngoai khoang do mot ben chi con dong gop vao
// sticky, nen chan lai la CHINH XAC chu khong phai xap xi (chung minh o phan
// khai bao sh_c).
//
// FADD/FSUB/FMUL deu di qua duong FMA:
//     fadd.s a, b  ==  fma(a, 1.0,  b)
//     fsub.s a, b  ==  fma(a, 1.0, -b)
//     fmul.s a, b  ==  fma(a, b,  <khong co so hang cong>)
// Nho vay khong co bo cong dau phay dong thu hai trong thiet ke.
//
// GHI CHU THOI GIAN (ASAP7, 250 MHz = 4 ns):
// duong to hop dai nhat la bo cong 81 bit o S_ALIGN va bo dich 80 bit cung o
// day. O 4 ns ca hai deu con thua cho, nhung neu sau nay ep chu ky xuong thi
// cat phep cong thanh hai nua 40 bit voi mot flip-flop nho carry la du.
//==================================================================================================
`timescale 1ns / 1ps
`include "core/fpu_defines.vh"

module fpu_unit #(
    // So bit ket qua sinh ra moi chu ky. Moi don vi la MOT bo cong/tru rieng
    // mac NOI TIEP trong cung chu ky, nen tang len doi lay dien tich va duong
    // to hop dai hon. 2 / 2 / 1 la diem can bang cho MCU 250 MHz.
    parameter MUL_BITS_PER_CYCLE  = 2,   // 24 vong -> 12 chu ky
    parameter DIV_BITS_PER_CYCLE  = 2,   // 27 vong -> 14 chu ky
    parameter SQRT_BITS_PER_CYCLE = 1    // 30 vong -> 30 chu ky
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        stall_id_ex,
    input  wire        fpu_start,
    input  wire [4:0]  fpu_op,
    input  wire [2:0]  fpu_rm,      // instr[14:12]
    input  wire [2:0]  frm_i,       // fcsr.frm, dung khi fpu_rm = DYN
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [31:0] operand_c,   // f[rs3] cua nhom FMA
    output reg  [31:0] result,
    output wire [4:0]  fflags,      // hop le khi fpu_done
    output wire        fpu_stall,
    output wire        fpu_done
);

    // =========================================================================
    // Hang so va kich thuoc
    // =========================================================================
    localparam [31:0] CANON_QNAN = 32'h7FC00000;
    localparam [30:0] INF_31     = 31'h7F800000;
    localparam [30:0] MAXF_31    = 31'h7F7FFFFF;

    localparam integer ACC_W      = 80;
    localparam integer MSB_TARGET = 50;  // sau NORM, bit 1 dan dau nam dung o day
    localparam integer LSB_POS    = 27;  // => dinh tri [50:27], guard 26, round 25

    localparam [3:0] S_IDLE    = 4'd0,
                     S_UNPACK  = 4'd1,
                     S_MUL     = 4'd2,
                     S_ALIGN   = 4'd3,
                     S_ADDFIX  = 4'd4,
                     S_DIV     = 4'd5,
                     S_SQRT    = 4'd6,
                     S_NORM    = 4'd7,
                     S_DENORM  = 4'd8,
                     S_ROUND   = 4'd9,
                     S_PACK    = 4'd10,
                     S_F2I     = 4'd11,
                     S_F2I_RND = 4'd12,
                     S_DONE    = 4'd13;

    reg [3:0] state;

    // =========================================================================
    // Thanh ghi trang thai
    // =========================================================================
    reg [4:0]  op_q;
    reg [2:0]  rm_q;                  // DA phan giai DYN -> gia tri that
    reg [31:0] a_q, b_q, c_q;
    reg [4:0]  flags_q;

    reg signed [11:0] acc_exp;        // bat bien: gia tri = acc * 2^acc_exp
    reg [ACC_W-1:0]   acc;
    reg               res_sign;

    reg signed [11:0] pexp_q;         // ea + eb, so mu cua tich
    reg [47:0]        prod_q;         // tich chinh xac 24x24
    reg               sign_p_q;       // dau cua tich (da tinh FNMADD/FNMSUB)
    reg               sign_c_q;       // dau so hang cong (da tinh FSUB/FMSUB)
    reg signed [11:0] ec_q;
    reg [23:0]        mc_q;
    reg               has_addend_q;   // 0 cho FMUL va cho c = 0
    reg               f2i_unsigned_q;
    reg               f2i_oob_q;      // |gia tri| chac chan tran khoi 32 bit

    reg [48:0]        mul_p;          // {carry, hi[23:0], lo[23:0]}
    reg [23:0]        mul_a;
    reg [24:0]        div_rem;
    reg [23:0]        div_d;
    reg [27:0]        div_q;
    reg [59:0]        sq_rad;
    reg [33:0]        sq_rem;
    reg [29:0]        sq_root;
    reg [5:0]         iter_cnt;
    reg [2:0]         norm_step;
    reg [80:0]        sum_q;

    integer k;

    // =========================================================================
    // Giai ma toan hang (to hop tren ban DA CHOT a_q / b_q / c_q)
    // =========================================================================
    // Dem so 0 dan dau cua mot truong 23 bit KHAC 0 (0..22).
    function automatic [4:0] lzc23;
        input [22:0] v;
        begin
            casez (v)
                23'b1??????????????????????: lzc23 = 5'd0;
                23'b01?????????????????????: lzc23 = 5'd1;
                23'b001????????????????????: lzc23 = 5'd2;
                23'b0001???????????????????: lzc23 = 5'd3;
                23'b00001??????????????????: lzc23 = 5'd4;
                23'b000001?????????????????: lzc23 = 5'd5;
                23'b0000001????????????????: lzc23 = 5'd6;
                23'b00000001???????????????: lzc23 = 5'd7;
                23'b000000001??????????????: lzc23 = 5'd8;
                23'b0000000001?????????????: lzc23 = 5'd9;
                23'b00000000001????????????: lzc23 = 5'd10;
                23'b000000000001???????????: lzc23 = 5'd11;
                23'b0000000000001??????????: lzc23 = 5'd12;
                23'b00000000000001?????????: lzc23 = 5'd13;
                23'b000000000000001????????: lzc23 = 5'd14;
                23'b0000000000000001???????: lzc23 = 5'd15;
                23'b00000000000000001??????: lzc23 = 5'd16;
                23'b000000000000000001?????: lzc23 = 5'd17;
                23'b0000000000000000001????: lzc23 = 5'd18;
                23'b00000000000000000001???: lzc23 = 5'd19;
                23'b000000000000000000001??: lzc23 = 5'd20;
                23'b0000000000000000000001?: lzc23 = 5'd21;
                default:                     lzc23 = 5'd22;
            endcase
        end
    endfunction

    // ---- nguon cua ba toan hang sau khi anh xa theo lenh --------------------
    wire is_addsub = (op_q == `FPOP_ADD) || (op_q == `FPOP_SUB);
    wire is_fma    = (op_q == `FPOP_MADD)  || (op_q == `FPOP_MSUB) ||
                     (op_q == `FPOP_NMSUB) || (op_q == `FPOP_NMADD);
    wire use_fma_path = is_addsub || is_fma || (op_q == `FPOP_MUL);

    // fadd/fsub muon `a * 1.0 + b`: toan hang nhan thu hai la hang so 1.0 va so
    // hang cong la b. fmul khong co so hang cong.
    wire [31:0] mul_b_raw = is_addsub ? 32'h3F800000 : b_q;
    wire [31:0] add_c_raw = is_addsub ? b_q : c_q;
    wire        has_addend_raw = is_addsub || is_fma;

    // Dau bi dao: fsub/fmsub dao so hang cong, fnmsub/fnmadd dao tich.
    wire add_c_neg = (op_q == `FPOP_SUB) || (op_q == `FPOP_MSUB) ||
                     (op_q == `FPOP_NMADD);
    wire prod_neg  = (op_q == `FPOP_NMSUB) || (op_q == `FPOP_NMADD);

    // ---- phan loai ----------------------------------------------------------
    wire        sa = a_q[31],    sb = mul_b_raw[31],    sc = add_c_raw[31];
    wire [7:0]  xa = a_q[30:23], xb = mul_b_raw[30:23], xc = add_c_raw[30:23];
    wire [22:0] fa = a_q[22:0],  fb = mul_b_raw[22:0],  fc = add_c_raw[22:0];

    wire a_zero = (xa == 8'd0)  && (fa == 23'd0);
    wire b_zero = (xb == 8'd0)  && (fb == 23'd0);
    wire c_zero = (xc == 8'd0)  && (fc == 23'd0);
    wire a_sub  = (xa == 8'd0)  && (fa != 23'd0);
    wire b_sub  = (xb == 8'd0)  && (fb != 23'd0);
    wire c_sub  = (xc == 8'd0)  && (fc != 23'd0);
    wire a_inf  = (xa == 8'hFF) && (fa == 23'd0);
    wire b_inf  = (xb == 8'hFF) && (fb == 23'd0);
    wire c_inf  = (xc == 8'hFF) && (fc == 23'd0);
    wire a_nan  = (xa == 8'hFF) && (fa != 23'd0);
    wire b_nan  = (xb == 8'hFF) && (fb != 23'd0);
    wire c_nan  = (xc == 8'hFF) && (fc != 23'd0);
    wire a_snan = a_nan && ~fa[22];
    wire b_snan = b_nan && ~fb[22];
    wire c_snan = c_nan && ~fc[22];

    // ---- dinh tri va so mu da chuan hoa ------------------------------------
    // Subnormal: 0.f * 2^-126 = f * 2^-149. Dich trai cho bit 1 dan dau ve bit
    // 23 thi so mu khong lech tro thanh (-127 - lzc), y het cong thuc cua so
    // binh thuong. Day chinh la cho ban cu bo qua hoan toan.
    wire [4:0] lza = lzc23(fa);
    wire [4:0] lzb = lzc23(fb);
    wire [4:0] lzcc = lzc23(fc);

    wire signed [11:0] ea = a_sub ? (-12'sd127 - $signed({7'd0, lza}))
                                  : ($signed({4'd0, xa}) - 12'sd127);
    wire signed [11:0] eb = b_sub ? (-12'sd127 - $signed({7'd0, lzb}))
                                  : ($signed({4'd0, xb}) - 12'sd127);
    wire signed [11:0] ec = c_sub ? (-12'sd127 - $signed({7'd0, lzcc}))
                                  : ($signed({4'd0, xc}) - 12'sd127);

    wire [23:0] ma = a_sub ? ({1'b0, fa} << (lza  + 5'd1)) : {1'b1, fa};
    wire [23:0] mb = b_sub ? ({1'b0, fb} << (lzb  + 5'd1)) : {1'b1, fb};
    wire [23:0] mc = c_sub ? ({1'b0, fc} << (lzcc + 5'd1)) : {1'b1, fc};

    // =========================================================================
    // So sanh dau phay dong (FEQ / FLT / FLE / FMIN / FMAX)
    //
    // KHONG so sanh bit tho: -0.0 va +0.0 PHAI bang nhau, va voi hai so am thi
    // thu tu bit bi DAO. Ban cu sai ca hai diem.
    // =========================================================================
    wire        cmp_both_zero = a_zero && b_zero;
    wire [30:0] mag_a = a_q[30:0];
    wire [30:0] mag_b = b_q[30:0];
    wire cmp_lt_raw = (sa != sb) ? sa
                                 : (sa ? (mag_a > mag_b) : (mag_a < mag_b));
    wire cmp_eq = cmp_both_zero || (a_q == b_q);
    wire cmp_lt = !cmp_both_zero && cmp_lt_raw;
    wire cmp_any_nan = a_nan || b_nan;

    // =========================================================================
    // FCLASS.S - 10 bit one-hot (bang 11.5 cua dac ta)
    // =========================================================================
    wire a_norm_pos = !sa && !a_zero && !a_sub && !a_inf && !a_nan;
    wire a_norm_neg =  sa && !a_zero && !a_sub && !a_inf && !a_nan;
    wire [31:0] class_bits = {22'd0,
                              a_nan && fa[22],   // 9 : qNaN
                              a_snan,            // 8 : sNaN
                              !sa && a_inf,      // 7 : +inf
                              a_norm_pos,        // 6 : +normal
                              !sa && a_sub,      // 5 : +subnormal
                              !sa && a_zero,     // 4 : +0
                              sa  && a_zero,     // 3 : -0
                              sa  && a_sub,      // 2 : -subnormal
                              a_norm_neg,        // 1 : -normal
                              sa  && a_inf};     // 0 : -inf

    // =========================================================================
    // Lam tron: MOT ham duy nhat, dung cho ca ket qua thuc lan FCVT.W[U].S
    // =========================================================================
    function automatic round_inc;
        input       sign;
        input       lsb, g, r, s;
        input [2:0] rm;
        begin
            case (rm)
                `FRM_RNE: round_inc = g & (r | s | lsb);
                `FRM_RTZ: round_inc = 1'b0;
                `FRM_RDN: round_inc =  sign & (g | r | s);
                `FRM_RUP: round_inc = ~sign & (g | r | s);
                `FRM_RMM: round_inc = g;
                default:  round_inc = g & (r | s | lsb);  // rm cam: decoder da chan
            endcase
        end
    endfunction

    // =========================================================================
    // NORM - dua bit 1 dan dau ve dung MSB_TARGET bang tim kiem nhi phan.
    //
    // Sau moi buoc bat bien `gia tri = acc * 2^acc_exp` van dung vi acc_exp
    // duoc bu dung bang so bit vua dich. Dich PHAI mat bit thap -> gop vao
    // sticky o bit 0; dich TRAI khong mat gi.
    //
    // CO Y dung 6 buoc dich hang so thay vi mot bo dich thung 80 bit dieu khien
    // boi priority encoder: moi buoc chi la mot mux 2:1 cong mot phep OR rut
    // gon, duong to hop ngan hon nhieu va dien tich nho hon.
    // =========================================================================
    wire need_r16 = |acc[ACC_W-1:MSB_TARGET+16];
    wire need_r8  = |acc[ACC_W-1:MSB_TARGET+8];
    wire need_r4  = |acc[ACC_W-1:MSB_TARGET+4];
    wire need_r2  = |acc[ACC_W-1:MSB_TARGET+2];
    wire need_r1  = |acc[ACC_W-1:MSB_TARGET+1];

    wire lost_r16 = |acc[15:0];
    wire lost_r8  = |acc[7:0];
    wire lost_r4  = |acc[3:0];
    wire lost_r2  = |acc[1:0];
    wire lost_r1  =  acc[0];

    wire can_l32 = ~|acc[MSB_TARGET:MSB_TARGET-31];
    wire can_l16 = ~|acc[MSB_TARGET:MSB_TARGET-15];
    wire can_l8  = ~|acc[MSB_TARGET:MSB_TARGET-7];
    wire can_l4  = ~|acc[MSB_TARGET:MSB_TARGET-3];
    wire can_l2  = ~|acc[MSB_TARGET:MSB_TARGET-1];
    wire can_l1  = ~acc[MSB_TARGET];

    reg [5:0] norm_sh;
    reg       norm_need_r;
    reg       norm_lost;
    reg       norm_can_l;
    always @(*) begin
        case (norm_step)
            // Buoc 32 khong the la dich PHAI: MSB_TARGET + 32 = 82 > 79, tuc
            // acc khong bao gio vuot qua muc do nhieu nhu vay.
            3'd5: begin norm_sh = 6'd32; norm_need_r = 1'b0;     norm_lost = 1'b0;     norm_can_l = can_l32; end
            3'd4: begin norm_sh = 6'd16; norm_need_r = need_r16; norm_lost = lost_r16; norm_can_l = can_l16; end
            3'd3: begin norm_sh = 6'd8;  norm_need_r = need_r8;  norm_lost = lost_r8;  norm_can_l = can_l8;  end
            3'd2: begin norm_sh = 6'd4;  norm_need_r = need_r4;  norm_lost = lost_r4;  norm_can_l = can_l4;  end
            3'd1: begin norm_sh = 6'd2;  norm_need_r = need_r2;  norm_lost = lost_r2;  norm_can_l = can_l2;  end
            default: begin norm_sh = 6'd1; norm_need_r = need_r1; norm_lost = lost_r1; norm_can_l = can_l1; end
        endcase
    end

    // =========================================================================
    // So mu va cac bit lam tron, dung chung boi DENORM / ROUND / PACK
    // =========================================================================
    wire signed [11:0] exp_biased  = acc_exp + 12'sd177;   // = (acc_exp + 50) + 127
    wire signed [11:0] denorm_need = 12'sd1 - exp_biased;  // so bit phai dich phai

    wire        rnd_lsb     = acc[LSB_POS];
    wire        rnd_g       = acc[LSB_POS-1];
    wire        rnd_r       = acc[LSB_POS-2];
    wire        rnd_s       = |acc[LSB_POS-3:0];
    wire        rnd_inexact = rnd_g | rnd_r | rnd_s;
    wire        rnd_do      = round_inc(res_sign, rnd_lsb, rnd_g, rnd_r, rnd_s, rm_q);
    wire [24:0] rnd_sig     = {1'b0, acc[MSB_TARGET:LSB_POS]} + {24'd0, rnd_do};

    // =========================================================================
    // FCVT.W[U].S - lam tron ve so nguyen tai cung vi tri bit LSB_POS
    // =========================================================================
    wire        f2i_ovf_hi = |acc[ACC_W-1:LSB_POS+32];
    wire [32:0] f2i_mag    = {1'b0, acc[LSB_POS+31:LSB_POS]} + {32'd0, rnd_do};
    wire        f2i_neg_ok = (f2i_mag <= 33'd2147483648);   // -2^31 van hop le
    wire        f2i_pos_ok = (f2i_mag <= 33'd2147483647);
    wire        f2iu_ok    = (f2i_mag <= 33'd4294967295);

    // =========================================================================
    // Canh: dat so hang cong vao acc.
    //
    // acc_c = mc << (ec - pexp + 26). Dich bi chan trong [-25, +53]; ngoai
    // khoang do phep chan la CHINH XAC chu khong phai xap xi:
    //   * dich > 53 : LSB cua c nam tren bit 53 con tich cao nhat toi bit 50,
    //     nen tich chi con nam trong vung guard/round/sticky cua ket qua - ma
    //     phep chan KHONG lam mat bit nao cua tich (no van nguyen ven trong acc).
    //   * dich < -25: c nam hoan toan duoi bit 0, chi con la sticky. Khong the
    //     co trieu tieu lon o day vi hai so cach nhau hon 51 bac.
    // Sticky cua c duoc bom vao bit 0, tuc DUOI LSB cua tich (bit 3), nen no
    // khong bao gio lam hong bit nao cua tich.
    // =========================================================================
    // Neo vao so mu LON HON trong hai. Day la diem mau chot, va la cho ban dau
    // tien cua file nay SAI:
    //
    //   Ban dau acc luon duoc neo vao so mu cua TICH, con so hang cong thi dich
    //   theo, voi phep chan `sh_c > 53 -> 53`. Phep chan do KHONG vo hai nhu ghi
    //   chu cu khang dinh: neo van o pexp nen dich c xuong 53 co nghia la CHIA c
    //   cho 2^(sh_c_raw - 53). Voi `fadd(2^-149, 1.0)` thi sh_c_raw = 175, tuc
    //   1.0 bi chia cho 2^122 va ket qua ra 0 thay vi 1.0.
    //   Mo hinh tham chieu trong tests/gen_fpu_vectors.py bat 2250 / 14335 vector
    //   vi loi nay; nhan / chia / can bac hai khong dinh vi chung khong co so
    //   hang cong.
    //
    // Cach dung: neo vao max(pexp, ec) roi dich CA HAI. Ben nao nho hon se roi
    // xuong duoi bit 0 va tro thanh sticky - dieu do moi thuc su vo hai, vi hai
    // so cach nhau xa thi khong the trieu tieu. Khi chung GAN nhau (truong hop
    // duy nhat co trieu tieu lon) thi ca hai phep dich deu khong am nen khong
    // mat bit nao.
    //
    // has_addend_q PHAI nam trong dieu kien: voi FMUL thi ec_q / mc_q lay tu mot
    // toan hang c khong dung den, de lon hon pexp va keo neo di sai cho.
    wire signed [11:0] anchor_exp =
        (has_addend_q && (ec_q > pexp_q)) ? ec_q : pexp_q;

    // Tich: gia tri = p_sig * 2^(pexp-46). Khi neo trung pexp thi sh_p = 3, tuc
    // dung bo cuc cu - nho vay duong nhan thuan tuy khong doi hanh vi.
    wire signed [11:0] sh_p_raw = pexp_q - anchor_exp + 12'sd3;
    wire signed [11:0] sh_p     = (sh_p_raw < -12'sd56) ? -12'sd56 : sh_p_raw;
    wire [5:0]  sh_p_abs   = sh_p[11] ? (6'd0 - sh_p[5:0]) : sh_p[5:0];
    wire [47:0] p_shr      = prod_q >> sh_p_abs;
    wire        p_shr_lost = ((p_shr << sh_p_abs) != prod_q);
    wire [ACC_W-1:0] acc_p =
        sh_p[11] ? ({{(ACC_W-48){1'b0}}, p_shr} |
                    {{(ACC_W-1){1'b0}}, p_shr_lost})
                 : ({{(ACC_W-48){1'b0}}, prod_q} << sh_p_abs);

    // So hang cong: gia tri = mc * 2^(ec-23).
    wire signed [11:0] sh_c_raw = ec_q - anchor_exp + 12'sd26;
    wire signed [11:0] sh_c     = (sh_c_raw < -12'sd26) ? -12'sd26 : sh_c_raw;
    wire [5:0]  sh_c_abs   = sh_c[11] ? (6'd0 - sh_c[5:0]) : sh_c[5:0];
    wire [23:0] c_shr      = mc_q >> sh_c_abs;
    wire        c_shr_lost = ((c_shr << sh_c_abs) != mc_q);
    wire [ACC_W-1:0] acc_c =
        !has_addend_q ? {ACC_W{1'b0}} :
        sh_c[11]      ? ({{(ACC_W-24){1'b0}}, c_shr} |
                         {{(ACC_W-1){1'b0}}, c_shr_lost})
                      : ({{(ACC_W-24){1'b0}}, mc_q} << sh_c_abs);

    wire eff_sub = sign_p_q ^ sign_c_q;

    // =========================================================================
    // Bien tam cua khoi always (gan blocking, KHONG sinh thanh ghi)
    // =========================================================================
    reg [48:0] t_mul_p;
    reg [23:0] t_mul_a;
    reg [24:0] t_div_rem;
    reg [27:0] t_div_q;
    reg [24:0] t_div_a;
    reg [59:0] t_sq_rad;
    reg [33:0] t_sq_rem;
    reg [33:0] t_sq_trial;
    reg [29:0] t_sq_root;
    reg [5:0]  t_cnt;
    reg signed [11:0] t_u;
    reg signed [11:0] t_k;
    reg signed [11:0] t_f2i_s;
    reg [5:0]  t_f2i_sh;
    reg [23:0] t_f2i_shr;
    reg [31:0] t_int_mag;

    // =========================================================================
    // FSM
    // =========================================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state     <= S_IDLE;
            result    <= 32'd0;
            flags_q   <= 5'd0;
            acc       <= {ACC_W{1'b0}};
            acc_exp   <= 12'sd0;
            res_sign  <= 1'b0;
            op_q      <= 5'd0;
            rm_q      <= 3'd0;
            a_q       <= 32'd0;
            b_q       <= 32'd0;
            c_q       <= 32'd0;
            pexp_q    <= 12'sd0;
            prod_q    <= 48'd0;
            sign_p_q  <= 1'b0;
            sign_c_q  <= 1'b0;
            ec_q      <= 12'sd0;
            mc_q      <= 24'd0;
            has_addend_q   <= 1'b0;
            f2i_unsigned_q <= 1'b0;
            f2i_oob_q      <= 1'b0;
            mul_p     <= 49'd0;
            mul_a     <= 24'd0;
            div_rem   <= 25'd0;
            div_d     <= 24'd0;
            div_q     <= 28'd0;
            sq_rad    <= 60'd0;
            sq_rem    <= 34'd0;
            sq_root   <= 30'd0;
            iter_cnt  <= 6'd0;
            norm_step <= 3'd0;
            sum_q     <= 81'd0;
        end else begin
            case (state)

            // -----------------------------------------------------------------
            // CHOT toan hang NGAY tai chu ky khoi dong.
            //
            // Bat buoc phai o day chu khong phai o S_UNPACK: fpu_stall len ngay
            // trong chu ky nay -> mf_alu_stall -> flush_ex_mem, nen den chu ky
            // sau EX/MEM da thanh bong bong va gia tri do forwarding_unit chuyen
            // toi da bien mat. Ban cu doc o S_UNPACK nen mat toan hang forward.
            // Cung ly do multiplier chot a_val / b_val o STATE_IDLE.
            // -----------------------------------------------------------------
            S_IDLE: begin
                if (fpu_start) begin
                    op_q    <= fpu_op;
                    rm_q    <= (fpu_rm == `FRM_DYN) ? frm_i : fpu_rm;
                    a_q     <= operand_a;
                    b_q     <= operand_b;
                    c_q     <= operand_c;
                    flags_q <= 5'd0;
                    state   <= S_UNPACK;
                end
            end

            // -----------------------------------------------------------------
            // Phan loai + moi truong hop dac biet. Moi nhanh hoac ket thuc ngay
            // (S_DONE) hoac nap acc / duong lap roi di tiep.
            // -----------------------------------------------------------------
            S_UNPACK: begin
                res_sign <= 1'b0;
                state    <= S_DONE;       // mac dinh an toan; moi nhanh tu doi
                result   <= CANON_QNAN;

                case (op_q)

                // ---- chuyen bit tho: khong co co, khong dung toi NaN --------
                `FPOP_MV_X_W, `FPOP_MV_W_X: result <= a_q;

                `FPOP_SGNJ:  result <= { b_q[31],           a_q[30:0]};
                `FPOP_SGNJN: result <= {~b_q[31],           a_q[30:0]};
                `FPOP_SGNJX: result <= { a_q[31] ^ b_q[31], a_q[30:0]};

                `FPOP_CLASS: result <= class_bits;

                // ---- so sanh ------------------------------------------------
                // FEQ la phep so sanh "quiet": CHI sNaN moi dat NV.
                // FLT / FLE la "signal": MOI NaN - ke ca qNaN - deu dat NV.
                `FPOP_EQ: begin
                    if (a_snan || b_snan) flags_q[`FFLAG_NV] <= 1'b1;
                    result <= cmp_any_nan ? 32'd0 : {31'd0, cmp_eq};
                end
                `FPOP_LT: begin
                    if (cmp_any_nan) flags_q[`FFLAG_NV] <= 1'b1;
                    result <= cmp_any_nan ? 32'd0 : {31'd0, cmp_lt};
                end
                `FPOP_LE: begin
                    if (cmp_any_nan) flags_q[`FFLAG_NV] <= 1'b1;
                    result <= cmp_any_nan ? 32'd0 : {31'd0, (cmp_lt | cmp_eq)};
                end

                // ---- FMIN / FMAX --------------------------------------------
                // Dac ta tu 2.2: NaN YEN LANG khong dat NV, chi sNaN moi dat.
                // Mot ben NaN -> tra ve ben KIA. Hai ben NaN -> canonical qNaN.
                // -0.0 < +0.0 duoc ton trong nho cmp_lt (khong so bit tho).
                `FPOP_MIN, `FPOP_MAX: begin
                    if (a_snan || b_snan) flags_q[`FFLAG_NV] <= 1'b1;
                    if (a_nan && b_nan)       result <= CANON_QNAN;
                    else if (a_nan)           result <= b_q;
                    else if (b_nan)           result <= a_q;
                    else if (a_zero && b_zero)
                        // Ca hai deu la 0: chi con DAU phan biet duoc chung.
                        result <= (op_q == `FPOP_MIN)
                                    ? ((sa || sb) ? (sa ? a_q : b_q) : a_q)
                                    : ((sa && sb) ? a_q : (sa ? b_q : a_q));
                    else if (op_q == `FPOP_MIN) result <= cmp_lt ? a_q : b_q;
                    else                        result <= cmp_lt ? b_q : a_q;
                end

                // ---- int -> float -------------------------------------------
                // Nap thang DO LON vao acc voi acc_exp = 0: bat bien
                // "gia tri = acc * 2^0" dung theo dinh nghia. |int| toi 2^32 nen
                // 24 bit dinh tri khong du -> NORM/ROUND tu sinh co NX.
                `FPOP_CVT_S_W, `FPOP_CVT_S_WU: begin
                    if (a_q == 32'd0) begin
                        result <= 32'd0;
                    end else begin
                        t_int_mag = ((op_q == `FPOP_CVT_S_W) && a_q[31])
                                    ? (~a_q + 32'd1) : a_q;
                        acc       <= {{(ACC_W-32){1'b0}}, t_int_mag};
                        acc_exp   <= 12'sd0;
                        res_sign  <= (op_q == `FPOP_CVT_S_W) ? a_q[31] : 1'b0;
                        norm_step <= 3'd5;
                        state     <= S_NORM;
                    end
                end

                // ---- float -> int -------------------------------------------
                `FPOP_CVT_W_S, `FPOP_CVT_WU_S: begin
                    f2i_unsigned_q <= (op_q == `FPOP_CVT_WU_S);
                    if (a_nan) begin
                        flags_q[`FFLAG_NV] <= 1'b1;
                        result <= (op_q == `FPOP_CVT_W_S) ? 32'h7FFFFFFF
                                                          : 32'hFFFFFFFF;
                    end else if (a_inf) begin
                        flags_q[`FFLAG_NV] <= 1'b1;
                        if (op_q == `FPOP_CVT_W_S)
                            result <= sa ? 32'h80000000 : 32'h7FFFFFFF;
                        else
                            result <= sa ? 32'h00000000 : 32'hFFFFFFFF;
                    end else if (a_zero) begin
                        result <= 32'd0;
                    end else begin
                        res_sign  <= sa;
                        // > 52 vua la "chac chan tran" vua la gioi han dat vua
                        // acc (bit 1 dan dau se nam o 23 + ea + 4).
                        f2i_oob_q <= (ea > 12'sd52);
                        state     <= S_F2I;
                    end
                end

                // ---- chia -----------------------------------------------------
                `FPOP_DIV: begin
                    res_sign <= sa ^ sb;
                    if (a_snan || b_snan) flags_q[`FFLAG_NV] <= 1'b1;
                    if (a_nan || b_nan) begin
                        result <= CANON_QNAN;
                    end else if ((a_inf && b_inf) || (a_zero && b_zero)) begin
                        flags_q[`FFLAG_NV] <= 1'b1;         // inf/inf va 0/0
                        result <= CANON_QNAN;
                    end else if (b_zero) begin
                        flags_q[`FFLAG_DZ] <= 1'b1;
                        result <= {sa ^ sb, INF_31};
                    end else if (a_inf) begin
                        result <= {sa ^ sb, INF_31};
                    end else if (a_zero || b_inf) begin
                        result <= {sa ^ sb, 31'd0};
                    end else begin
                        // Chuan hoa truoc mot buoc de thuong luon nam trong
                        // [1,2): neu ma < mb thi nhan doi ma va bu -1 vao so mu.
                        // Nho vay bit nguyen cua thuong luon bang 1 va vong lap
                        // phuc hoi giu duoc bat bien rem < mb.
                        t_div_a  = (ma < mb) ? ({1'b0, ma} << 1) : {1'b0, ma};
                        div_rem  <= t_div_a - {1'b0, mb};   // da tru bit nguyen
                        div_d    <= mb;
                        div_q    <= 28'd1;
                        acc_exp  <= ea - eb - 12'sd28 -
                                    ((ma < mb) ? 12'sd1 : 12'sd0);
                        iter_cnt <= 6'd27;
                        state    <= S_DIV;
                    end
                end

                // ---- can bac hai ----------------------------------------------
                `FPOP_SQRT: begin
                    res_sign <= 1'b0;
                    if (a_snan) flags_q[`FFLAG_NV] <= 1'b1;
                    if (a_nan) begin
                        result <= CANON_QNAN;
                    end else if (a_zero) begin
                        result <= a_q;                      // sqrt(-0) = -0
                    end else if (sa) begin
                        flags_q[`FFLAG_NV] <= 1'b1;         // moi so am khac -0
                        result <= CANON_QNAN;
                    end else if (a_inf) begin
                        result <= {1'b0, INF_31};
                    end else begin
                        // gia tri = ma * 2^(ea-23). Ep so mu cua can thuc thanh
                        // CHAN: u le -> nhan doi ma. K = u >>> 1 dung cho ca hai
                        // truong hop (dich phai SO HOC = floor cua phep chia 2,
                        // ke ca khi u am).
                        t_u = ea - 12'sd23;
                        t_k = t_u >>> 1;
                        sq_rad   <= (t_u[0] ? ({36'd0, ma} << 1) : {36'd0, ma}) << 34;
                        sq_rem   <= 34'd0;
                        sq_root  <= 30'd0;
                        acc_exp  <= t_k - 12'sd18;          // K - F - 1, F = 17
                        iter_cnt <= 6'd30;
                        state    <= S_SQRT;
                    end
                end

                // ---- FADD / FSUB / FMUL / FMA ---------------------------------
                default: begin
                    if (use_fma_path) begin
                        sign_p_q     <= sa ^ sb ^ prod_neg;
                        sign_c_q     <= sc ^ add_c_neg;
                        ec_q         <= ec;
                        mc_q         <= mc;
                        pexp_q       <= ea + eb;
                        has_addend_q <= has_addend_raw && !c_zero;

                        if (a_snan || b_snan || (has_addend_raw && c_snan))
                            flags_q[`FFLAG_NV] <= 1'b1;

                        if (a_nan || b_nan || (has_addend_raw && c_nan)) begin
                            result <= CANON_QNAN;
                        end else if ((a_inf && b_zero) || (a_zero && b_inf)) begin
                            // 0 * inf la vo dinh, KE CA khi co so hang cong.
                            flags_q[`FFLAG_NV] <= 1'b1;
                            result <= CANON_QNAN;
                        end else if (a_inf || b_inf) begin
                            // Tich la vo cung; chi hong khi so hang cong cung la
                            // vo cung NGUOC DAU.
                            if (has_addend_raw && c_inf &&
                                ((sa ^ sb ^ prod_neg) != (sc ^ add_c_neg))) begin
                                flags_q[`FFLAG_NV] <= 1'b1;
                                result <= CANON_QNAN;
                            end else begin
                                result <= {sa ^ sb ^ prod_neg, INF_31};
                            end
                        end else if (has_addend_raw && c_inf) begin
                            result <= {sc ^ add_c_neg, INF_31};
                        end else if (a_zero || b_zero) begin
                            // Tich bang 0 -> ket qua la CHINH so hang cong, ma no
                            // da la mot so float hop le nen khong can lam tron.
                            if (!has_addend_raw) begin
                                result <= {sa ^ sb ^ prod_neg, 31'd0};
                            end else if (c_zero) begin
                                // 0 + 0: dau chi giu lai khi hai dau giong nhau;
                                // nguoc lai IEEE quy dinh +0, RIENG RDN cho -0.
                                if ((sa ^ sb ^ prod_neg) == (sc ^ add_c_neg))
                                    result <= {sa ^ sb ^ prod_neg, 31'd0};
                                else
                                    result <= {(rm_q == `FRM_RDN), 31'd0};
                            end else begin
                                result <= {sc ^ add_c_neg, add_c_raw[30:0]};
                            end
                        end else begin
                            // Duong chinh: nhan 24x24 chinh xac roi cong.
                            // fadd/fsub co mb = 1.0 nen tich dung bang ma << 23 -
                            // bo qua han 24 chu ky nhan.
                            if (is_addsub) begin
                                prod_q <= {1'b0, ma, 23'd0};
                                state  <= S_ALIGN;
                            end else begin
                                mul_p    <= {25'd0, mb};
                                mul_a    <= ma;
                                iter_cnt <= 6'd24;
                                state    <= S_MUL;
                            end
                        end
                    end
                end
                endcase
            end

            // -----------------------------------------------------------------
            // Nhan dich-cong: P = {carry, hi, lo}. Moi vong xet bit thap nhat cua
            // phan `lo` (chinh la toan hang nhan) roi dich ca P sang phai. Bo
            // cong chi rong 25 bit du tich rong 48.
            // -----------------------------------------------------------------
            S_MUL: begin
                t_mul_p = mul_p;
                t_mul_a = mul_a;
                t_cnt   = iter_cnt;
                for (k = 0; k < MUL_BITS_PER_CYCLE; k = k + 1) begin
                    if (t_cnt != 6'd0) begin
                        if (t_mul_p[0])
                            t_mul_p[48:24] = t_mul_p[48:24] + {1'b0, t_mul_a};
                        t_mul_p = {1'b0, t_mul_p[48:1]};
                        t_cnt   = t_cnt - 6'd1;
                    end
                end
                mul_p    <= t_mul_p;
                iter_cnt <= t_cnt;
                if (t_cnt == 6'd0) begin
                    prod_q <= t_mul_p[47:0];
                    state  <= S_ALIGN;
                end
            end

            // -----------------------------------------------------------------
            // Canh so hang cong voi tich roi cong/tru trong he bu hai theo dau
            // CUA TICH. Xem chung minh phep chan o phan khai bao sh_c.
            // -----------------------------------------------------------------
            S_ALIGN: begin
                acc_exp <= anchor_exp - 12'sd49;
                sum_q   <= eff_sub ? ({1'b0, acc_p} - {1'b0, acc_c})
                                   : ({1'b0, acc_p} + {1'b0, acc_c});
                state   <= S_ADDFIX;
            end

            // Tong am nghia la so hang cong lon hon tich -> dau ket qua la dau
            // cua so hang cong, va do lon la phan bu hai.
            S_ADDFIX: begin
                if (sum_q[80]) begin
                    acc      <= (~sum_q[ACC_W-1:0]) + {{(ACC_W-1){1'b0}}, 1'b1};
                    res_sign <= ~sign_p_q;
                end else begin
                    acc      <= sum_q[ACC_W-1:0];
                    res_sign <= sign_p_q;
                end
                norm_step <= 3'd5;
                state     <= S_NORM;
            end

            // -----------------------------------------------------------------
            // Chia phuc hoi: mot bit thuong moi vong.
            // -----------------------------------------------------------------
            S_DIV: begin
                t_div_rem = div_rem;
                t_div_q   = div_q;
                t_cnt     = iter_cnt;
                for (k = 0; k < DIV_BITS_PER_CYCLE; k = k + 1) begin
                    if (t_cnt != 6'd0) begin
                        t_div_rem = {t_div_rem[23:0], 1'b0};
                        if (t_div_rem >= {1'b0, div_d}) begin
                            t_div_rem = t_div_rem - {1'b0, div_d};
                            t_div_q   = {t_div_q[26:0], 1'b1};
                        end else begin
                            t_div_q   = {t_div_q[26:0], 1'b0};
                        end
                        t_cnt = t_cnt - 6'd1;
                    end
                end
                div_rem  <= t_div_rem;
                div_q    <= t_div_q;
                iter_cnt <= t_cnt;
                if (t_cnt == 6'd0) begin
                    acc <= {{(ACC_W-29){1'b0}}, t_div_q, (t_div_rem != 25'd0)};
                    norm_step <= 3'd5;
                    state     <= S_NORM;
                end
            end

            // -----------------------------------------------------------------
            // Can bac hai phuc hoi: hai bit can moi buoc -> mot bit ket qua.
            // -----------------------------------------------------------------
            S_SQRT: begin
                t_sq_rad  = sq_rad;
                t_sq_rem  = sq_rem;
                t_sq_root = sq_root;
                t_cnt     = iter_cnt;
                for (k = 0; k < SQRT_BITS_PER_CYCLE; k = k + 1) begin
                    if (t_cnt != 6'd0) begin
                        t_sq_rem   = {t_sq_rem[31:0], t_sq_rad[59:58]};
                        t_sq_rad   = {t_sq_rad[57:0], 2'b00};
                        t_sq_trial = {2'd0, t_sq_root, 2'b01};
                        if (t_sq_rem >= t_sq_trial) begin
                            t_sq_rem  = t_sq_rem - t_sq_trial;
                            t_sq_root = {t_sq_root[28:0], 1'b1};
                        end else begin
                            t_sq_root = {t_sq_root[28:0], 1'b0};
                        end
                        t_cnt = t_cnt - 6'd1;
                    end
                end
                sq_rad   <= t_sq_rad;
                sq_rem   <= t_sq_rem;
                sq_root  <= t_sq_root;
                iter_cnt <= t_cnt;
                if (t_cnt == 6'd0) begin
                    acc <= {{(ACC_W-31){1'b0}}, t_sq_root, (t_sq_rem != 34'd0)};
                    norm_step <= 3'd5;
                    state     <= S_NORM;
                end
            end

            // -----------------------------------------------------------------
            // Chuan hoa (6 buoc). Xem ghi chu o phan khai bao need_* / can_l*.
            // -----------------------------------------------------------------
            S_NORM: begin
                if (acc == {ACC_W{1'b0}}) begin
                    // Trieu tieu hoan toan: IEEE quy dinh +0, RIENG RDN cho -0.
                    result <= {(rm_q == `FRM_RDN), 31'd0};
                    state  <= S_DONE;
                end else begin
                    // HUONG dich phai quyet dinh bang need_r1 (co bat ky bit nao
                    // TREN MSB_TARGET khong), KHONG phai bang norm_need_r cua
                    // rieng buoc nay.
                    //
                    // Ban dau viet `if (norm_need_r) ... else if (norm_can_l)`,
                    // va do la mot loi: norm_need_r cua buoc sh chi hoi "co bit
                    // nao tu MSB_TARGET+sh tro len khong". Voi bit 1 dan dau nam
                    // o 51 thi need_r4 = |acc[79:54] = 0, trong khi can_l4 =
                    // ~|acc[50:47] hoan toan co the bang 1 - the la no DICH TRAI
                    // 4 bit mot gia tri dang o TREN dich. Mo hinh tham chieu bat
                    // duoc dung mot vector fmadd voi trieu tieu nhe (acc[50:47]
                    // tinh co bang 0) - xac suat thap nhung khong he hiem trong
                    // phan mem that.
                    if (need_r1) begin
                        if (norm_need_r) begin
                            acc     <= (acc >> norm_sh) |
                                       {{(ACC_W-1){1'b0}}, norm_lost};
                            acc_exp <= acc_exp + $signed({6'd0, norm_sh});
                        end
                    end else if (norm_can_l) begin
                        acc     <= acc << norm_sh;
                        acc_exp <= acc_exp - $signed({6'd0, norm_sh});
                    end
                    if (norm_step == 3'd0) begin
                        norm_step <= 3'd5;
                        state     <= S_DENORM;
                    end else begin
                        norm_step <= norm_step - 3'd1;
                    end
                end
            end

            // -----------------------------------------------------------------
            // Underflow dan dan: so mu lech <= 0 nghia la ket qua la subnormal.
            // Dich phai dung (1 - exp_biased) bit, GIU sticky, roi ep so mu ve 1.
            // Day dung la cho ban CU chi viet `exp_res == 0 -> POS_ZERO`.
            // -----------------------------------------------------------------
            S_DENORM: begin
                if (exp_biased > 12'sd0) begin
                    state <= S_ROUND;                    // ket qua binh thuong
                end else if (denorm_need > 12'sd63) begin
                    // Nho hon ca nua cua subnormal nho nhat: khong bit nao song
                    // sot, chi con sticky. S_ROUND van co the nang len subnormal
                    // nho nhat neu che do lam tron yeu cau (vd RUP voi so duong).
                    acc     <= {{(ACC_W-1){1'b0}}, |acc};
                    acc_exp <= 12'sd1 - 12'sd177;
                    state   <= S_ROUND;
                end else begin
                    if (denorm_need >= $signed({6'd0, norm_sh})) begin
                        acc     <= (acc >> norm_sh) |
                                   {{(ACC_W-1){1'b0}}, norm_lost};
                        acc_exp <= acc_exp + $signed({6'd0, norm_sh});
                    end
                    if (norm_step == 3'd0) state     <= S_ROUND;
                    else                   norm_step <= norm_step - 3'd1;
                end
            end

            // -----------------------------------------------------------------
            // Lam tron + phat hien tran duoi.
            // -----------------------------------------------------------------
            S_ROUND: begin
                if (rnd_inexact) flags_q[`FFLAG_NX] <= 1'b1;
                // "Tiny AFTER rounding": chi bao UF khi ket qua DA LAM TRON van
                // con la subnormal VA khong chinh xac. Neu phep lam tron day no
                // len thanh so binh thuong nho nhat thi KHONG co UF.
                if (rnd_inexact && !rnd_sig[23] && !rnd_sig[24])
                    flags_q[`FFLAG_UF] <= 1'b1;

                if (rnd_sig[24]) begin
                    // Lam tron tran len bit 24 (dinh tri toan 1) -> tang so mu.
                    acc     <= {{(ACC_W-25){1'b0}}, rnd_sig} << (LSB_POS - 1);
                    acc_exp <= acc_exp + 12'sd1;
                end else begin
                    acc     <= {{(ACC_W-25){1'b0}}, rnd_sig} << LSB_POS;
                end
                state <= S_PACK;
            end

            // -----------------------------------------------------------------
            // Dong goi. exp_biased o day da tinh tren acc SAU khi lam tron.
            // -----------------------------------------------------------------
            S_PACK: begin
                state <= S_DONE;
                if (exp_biased >= 12'sd255) begin
                    flags_q[`FFLAG_OF] <= 1'b1;
                    flags_q[`FFLAG_NX] <= 1'b1;
                    // Tran tren KHONG phai luc nao cung ra vo cung: RTZ luon ve
                    // so huu han lon nhat, con RDN / RUP chi ra vo cung ve DUNG
                    // mot phia (IEEE 754 muc 7.4).
                    case (rm_q)
                        `FRM_RTZ: result <= {res_sign, MAXF_31};
                        `FRM_RDN: result <= res_sign ? {1'b1, INF_31}
                                                     : {1'b0, MAXF_31};
                        `FRM_RUP: result <= res_sign ? {1'b1, MAXF_31}
                                                     : {1'b0, INF_31};
                        default:  result <= {res_sign, INF_31};
                    endcase
                end else if (acc[MSB_TARGET:LSB_POS] == 24'd0) begin
                    result <= {res_sign, 31'd0};
                end else if (acc[MSB_TARGET]) begin
                    result <= {res_sign, exp_biased[7:0], acc[MSB_TARGET-1:LSB_POS]};
                end else begin
                    // Subnormal: truong so mu bang 0, khong co bit 1 an.
                    result <= {res_sign, 8'd0, acc[MSB_TARGET-1:LSB_POS]};
                end
            end

            // -----------------------------------------------------------------
            // FCVT.W[U].S buoc 1: dat gia tri vao acc sao cho bit co trong so
            // 2^0 roi dung vao LSB_POS. Khi do guard / round / sticky nam dung
            // cho nhu duong so thuc va round_inc dung lai duoc, khong sua gi.
            //     acc = ma << (ea + 4)   vi   ma * 2^(ea-23) * 2^27 = ma << (ea+4)
            // -----------------------------------------------------------------
            S_F2I: begin
                t_f2i_s = ea + 12'sd4;
                if (f2i_oob_q) begin
                    acc <= {ACC_W{1'b1}};                  // chac chan ngoai pham vi
                end else if (t_f2i_s >= 12'sd0) begin
                    acc <= {{(ACC_W-24){1'b0}}, ma} << t_f2i_s[6:0];
                end else if (t_f2i_s < -12'sd56) begin
                    acc <= {{(ACC_W-1){1'b0}}, 1'b1};      // phan con lai chi la sticky
                end else begin
                    t_f2i_sh  = 6'd0 - t_f2i_s[5:0];
                    t_f2i_shr = ma >> t_f2i_sh;
                    acc <= {{(ACC_W-24){1'b0}}, t_f2i_shr} |
                           {{(ACC_W-1){1'b0}}, ((t_f2i_shr << t_f2i_sh) != ma)};
                end
                state <= S_F2I_RND;
            end

            // Dac ta: khi mot phep chuyen doi raise NV thi no KHONG raise NX.
            // Vi vay nhanh NV ha lai bit NX vua dat o tren.
            S_F2I_RND: begin
                state <= S_DONE;
                if (rnd_inexact) flags_q[`FFLAG_NX] <= 1'b1;
                if (f2i_unsigned_q) begin
                    // Mot so AM vuot pham vi phai ra 0 chu khong phai UINT_MAX.
                    // Dieu kien PHAI gom ca f2i_oob_q / f2i_ovf_hi: voi mot so am
                    // rat lon (vd -2^52) thi lat cat acc[58:27] co the tinh co
                    // bang 0, va ban dau chi kiem `f2i_mag != 0` nen no roi
                    // xuong nhanh ke tiep va tra ve UINT_MAX - sai dau hoan toan.
                    if (res_sign && (f2i_oob_q || f2i_ovf_hi || (f2i_mag != 33'd0))) begin
                        flags_q[`FFLAG_NV] <= 1'b1;
                        flags_q[`FFLAG_NX] <= 1'b0;
                        result <= 32'h00000000;
                    end else if (f2i_oob_q || f2i_ovf_hi || !f2iu_ok) begin
                        flags_q[`FFLAG_NV] <= 1'b1;
                        flags_q[`FFLAG_NX] <= 1'b0;
                        result <= 32'hFFFFFFFF;
                    end else begin
                        result <= f2i_mag[31:0];
                    end
                end else begin
                    if (f2i_oob_q || f2i_ovf_hi ||
                        (res_sign ? !f2i_neg_ok : !f2i_pos_ok)) begin
                        flags_q[`FFLAG_NV] <= 1'b1;
                        flags_q[`FFLAG_NX] <= 1'b0;
                        result <= res_sign ? 32'h80000000 : 32'h7FFFFFFF;
                    end else begin
                        result <= res_sign ? (~f2i_mag[31:0] + 32'd1)
                                           : f2i_mag[31:0];
                    end
                end
            end

            S_DONE: begin
                if (!stall_id_ex) state <= S_IDLE;
            end

            default: state <= S_IDLE;
            endcase
        end
    end

    assign fflags    = flags_q;
    assign fpu_done  = (state == S_DONE);
    assign fpu_stall = (state != S_IDLE && state != S_DONE) ||
                       (fpu_start && state == S_IDLE);

endmodule
