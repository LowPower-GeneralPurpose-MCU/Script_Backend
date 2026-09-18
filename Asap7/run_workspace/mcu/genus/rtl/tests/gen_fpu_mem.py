#!/usr/bin/env python3
"""Sinh tests/fpu_core.mem - anh ROM cho tb_fpu_core.sv (run_soc_sim.sh fpu).

RV32F chay bang CPU THAT. Khong co trinh bien dich RISC-V tren may nay (xem
mcu-sim-setup), nen chuong trinh duoc ma hoa bang tay giong gen_amo_mem.py va
gen_irq_pmp_mem.py.

Chuong trinh kiem toan bo tap lenh RV32F cong voi cac goc canh cua IEEE-754 ma
ban FPU CU lam sai: subnormal, che do lam tron khac RNE, ngu nghia NaN cua
FMIN/FMAX so voi FLT so voi FEQ, va nam co ngoai le trong fcsr.

Ket qua dau phay dong nam trong f8..f31, ket qua so nguyen trong thanh ghi x -
testbench doc ca hai bang duong phan cap.

    python gen_fpu_mem.py          # ghi fpu_core.mem canh script
"""
import os
import struct

XREG = {n: i for i, n in enumerate(
    "zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 "
    "s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6".split())}
ROM_BASE = 0x0001_0000


def x(n):
    return XREG[n] if isinstance(n, str) else n


def f(n):
    """f0..f31 duoc viet thang bang so de khong lan voi ten thanh ghi x."""
    assert 0 <= n < 32
    return n


def bits(val):
    """float Python -> 32 bit IEEE-754 don chinh xac."""
    return struct.unpack('<I', struct.pack('<f', val))[0]


# ---------------------------------------------------------------------------
# Ma hoa
# ---------------------------------------------------------------------------
def enc_r(funct7, rs2, rs1, funct3, rd, opcode):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
           ((funct3 & 7) << 12) | ((rd & 0x1F) << 7) | opcode


def enc_r4(rs3, rs2, rs1, funct3, rd, opcode):
    # fmt = instr[26:25] = 00 (.S)
    return ((rs3 & 0x1F) << 27) | (0 << 25) | ((rs2 & 0x1F) << 20) | \
           ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | ((rd & 0x1F) << 7) | opcode


def enc_i(op, f3, rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | (f3 << 12) | \
           ((rd & 0x1F) << 7) | op


def enc_s(op, f3, rs2, rs1, imm):
    return (((imm >> 5) & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
           (f3 << 12) | ((imm & 0x1F) << 7) | op


# Doi chieu voi ma da biet (objdump cua GNU as):
#   fadd.s  f8, f0, f1     = 0x00100427     fmv.w.x f0, a0   = 0xf0050053
#   flw     f8, 0(a0)      = 0x00052407     fsw     f8, 0(a0) = 0x00852027
#   fmadd.s f8, f2, f3, f0 = 0x00317443
assert enc_r(0x00, 1, 0, 0, 8, 0x53) == 0x00100427
assert enc_r(0x78, 0, x("a0"), 0, 0, 0x53) == 0xF0050053
assert enc_i(0x07, 2, 8, x("a0"), 0) == 0x00052407
assert enc_s(0x27, 2, 8, x("a0"), 0) == 0x00852027
assert enc_r4(0, 3, 2, 0, 8, 0x43) == 0x00317443

# funct7[6:2] cua nhom OP-FP; funct7[1:0] = fmt = 00 (.S)
F7 = {"add": 0x00, "sub": 0x04, "mul": 0x08, "div": 0x0C, "sqrt": 0x2C,
      "sgnj": 0x10, "minmax": 0x14, "cmp": 0x50, "cvt_w": 0x60,
      "cvt_s": 0x68, "mv_x": 0x70, "mv_f": 0x78}

RM_RNE, RM_RTZ, RM_RDN, RM_RUP, RM_RMM, RM_DYN = 0, 1, 2, 3, 4, 7

out = []


def emit(word, text):
    out.append((ROM_BASE + 4 * len(out), word & 0xFFFFFFFF, text))


# ---- tien ich so nguyen ---------------------------------------------------
def li(rd, val):
    val &= 0xFFFFFFFF
    lo = val & 0xFFF
    lo_s = lo - 0x1000 if lo & 0x800 else lo
    hi = ((val - lo_s) >> 12) & 0xFFFFF
    emit((hi << 12) | (x(rd) << 7) | 0x37, "lui  %s, 0x%x" % (rd, hi))
    emit(enc_i(0x13, 0, x(rd), x(rd), lo_s),
         "addi %s, %s, %d   (%s = 0x%08x)" % (rd, rd, lo_s, rd, val))


def csrrw(rd, csr, rs1):
    emit((csr << 20) | (x(rs1) << 15) | (1 << 12) | (x(rd) << 7) | 0x73,
         "csrrw %s, 0x%03x, %s" % (rd, csr, rs1))


def csrr(rd, csr):
    # csrrs rd, csr, x0 - KHONG ghi (decoder ep csr_op ve 0)
    emit((csr << 20) | (0 << 15) | (2 << 12) | (x(rd) << 7) | 0x73,
         "csrr %s, 0x%03x" % (rd, csr))


# ---- lenh F ---------------------------------------------------------------
def fop(name, fd, fs1, fs2, rm=RM_RNE):
    emit(enc_r((F7[name] << 2), f(fs2), f(fs1), rm, f(fd), 0x53),
         "f%s.s f%d, f%d, f%d" % (name, fd, fs1, fs2))


def fsqrt(fd, fs1, rm=RM_RNE):
    emit(enc_r((F7["sqrt"] << 2), 0, f(fs1), rm, f(fd), 0x53),
         "fsqrt.s f%d, f%d" % (fd, fs1))


def fsgnj(kind, fd, fs1, fs2):
    f3 = {"": 0, "n": 1, "x": 2}[kind]
    emit(enc_r((F7["sgnj"] << 2), f(fs2), f(fs1), f3, f(fd), 0x53),
         "fsgnj%s.s f%d, f%d, f%d" % (kind, fd, fs1, fs2))


def fminmax(kind, fd, fs1, fs2):
    f3 = 0 if kind == "min" else 1
    emit(enc_r((F7["minmax"] << 2), f(fs2), f(fs1), f3, f(fd), 0x53),
         "f%s.s f%d, f%d, f%d" % (kind, fd, fs1, fs2))


def fcmp(kind, rd, fs1, fs2):
    f3 = {"le": 0, "lt": 1, "eq": 2}[kind]
    emit(enc_r((F7["cmp"] << 2), f(fs2), f(fs1), f3, x(rd), 0x53),
         "f%s.s %s, f%d, f%d" % (kind, rd, fs1, fs2))


def fcvt_w(rd, fs1, unsigned=False, rm=RM_RNE):
    emit(enc_r((F7["cvt_w"] << 2), 1 if unsigned else 0, f(fs1), rm, x(rd), 0x53),
         "fcvt.w%s.s %s, f%d (rm=%d)" % ("u" if unsigned else "", rd, fs1, rm))


def fcvt_s(fd, rs1, unsigned=False, rm=RM_RNE):
    emit(enc_r((F7["cvt_s"] << 2), 1 if unsigned else 0, x(rs1), rm, f(fd), 0x53),
         "fcvt.s.w%s f%d, %s" % ("u" if unsigned else "", fd, rs1))


def fmv_x_w(rd, fs1):
    emit(enc_r((F7["mv_x"] << 2), 0, f(fs1), 0, x(rd), 0x53),
         "fmv.x.w %s, f%d" % (rd, fs1))


def fclass(rd, fs1):
    emit(enc_r((F7["mv_x"] << 2), 0, f(fs1), 1, x(rd), 0x53),
         "fclass.s %s, f%d" % (rd, fs1))


def fmv_w_x(fd, rs1):
    emit(enc_r((F7["mv_f"] << 2), 0, x(rs1), 0, f(fd), 0x53),
         "fmv.w.x f%d, %s" % (fd, rs1))


def fma(kind, fd, fs1, fs2, fs3, rm=RM_RNE):
    op = {"madd": 0x43, "msub": 0x47, "nmsub": 0x4B, "nmadd": 0x4F}[kind]
    emit(enc_r4(f(fs3), f(fs2), f(fs1), rm, f(fd), op),
         "f%s.s f%d, f%d, f%d, f%d" % (kind, fd, fs1, fs2, fs3))


def flw(fd, off, rs1):
    emit(enc_i(0x07, 2, f(fd), x(rs1), off), "flw  f%d, %d(%s)" % (fd, off, rs1))


def fsw(fs2, off, rs1):
    emit(enc_s(0x27, 2, f(fs2), x(rs1), off), "fsw  f%d, %d(%s)" % (fs2, off, rs1))


def fconst(fd, value_bits, note):
    """Nap mot hang so 32 bit vao f[fd] qua t0."""
    li("t0", value_bits)
    fmv_w_x(fd, "t0")
    out[-1] = (out[-1][0], out[-1][1], out[-1][2] + "   <- " + note)


# ===========================================================================
# Chuong trinh
# ===========================================================================
TRAP = ROM_BASE + 0x600

# mtvec -> TRAP (t2 = 0xBAD). Bat ky lenh F nao bi bao illegal roi vao day, nen
# testbench phan biet duoc "giai ma sai" voi "treo".
li("t0", TRAP)
csrrw("zero", 0x305, "t0")

# fcsr = 0 (frm = RNE, fflags sach)
csrrw("zero", 0x003, "zero")

# ---- hang so --------------------------------------------------------------
fconst(0, bits(1.0),  "1.0")
fconst(1, bits(2.0),  "2.0")
fconst(2, bits(3.0),  "3.0")
fconst(3, bits(0.5),  "0.5")
fconst(4, bits(-1.5), "-1.5")
fconst(5, bits(10.0), "10.0")
fconst(6, 0x00000000, "+0.0")
fconst(7, 0x7FC00000, "qNaN")

# ---- so hoc co ban --------------------------------------------------------
fop("add", 8,  0, 1)                 # f8  = 1.0 + 2.0 = 3.0
fop("sub", 9,  2, 0)                 # f9  = 3.0 - 1.0 = 2.0
fop("mul", 10, 2, 3)                 # f10 = 3.0 * 0.5 = 1.5
fop("div", 11, 0, 2)                 # f11 = 1.0 / 3.0
fsqrt(12, 1)                         # f12 = sqrt(2.0)

# ---- FMA: lam tron DUNG MOT LAN -------------------------------------------
fma("madd",  13, 2, 3, 0)            # f13 =  (3.0*0.5) + 1.0 =  2.5
fma("msub",  14, 2, 3, 0)            # f14 =  (3.0*0.5) - 1.0 =  0.5
fma("nmsub", 15, 2, 3, 0)            # f15 = -(3.0*0.5) + 1.0 = -0.5
fma("nmadd", 16, 2, 3, 0)            # f16 = -(3.0*0.5) - 1.0 = -2.5

# ---- dau, min / max -------------------------------------------------------
fsgnj("",  17, 0, 4)                 # f17 = |1.0| voi dau cua -1.5 = -1.0
fsgnj("n", 18, 0, 4)                 # f18 =  1.0
fsgnj("x", 19, 4, 4)                 # f19 =  1.5  (dau xor chinh no = +)
fminmax("min", 20, 4, 0)             # f20 = -1.5
fminmax("max", 21, 4, 0)             # f21 =  1.0
# NaN YEN LANG khong duoc lam hong FMIN/FMAX: phai tra ve toan hang KIA va
# KHONG dat NV. Ban FPU cu tra ve qNaN cho ca hai - day la test bat no.
fminmax("min", 22, 7, 0)             # f22 =  1.0
fminmax("max", 23, 7, 4)             # f23 = -1.5

# ---- so sanh (ket qua so nguyen) ------------------------------------------
fcmp("eq", "a0", 0, 0)               # a0 = 1
fcmp("lt", "a1", 4, 0)               # a1 = 1  (-1.5 < 1.0; ban cu so bit tho
                                     #          nen ra 0)
fcmp("le", "a2", 0, 0)               # a2 = 1
fcmp("eq", "a3", 7, 0)               # a3 = 0  (NaN khong bang gi ca)
fclass("a4", 4)                      # a4 = 0x002  (-normal)
fclass("a5", 6)                      # a5 = 0x010  (+0)

# ---- chuyen doi -----------------------------------------------------------
fcvt_w("a6", 4, rm=RM_RTZ)           # a6 = -1  (ve 0)
fcvt_w("a7", 4, rm=RM_RNE)           # a7 = -2  (gan nhat, hoa -> chan)
fcvt_w("s2", 5, unsigned=True)       # s2 = 10
li("t0", -5 & 0xFFFFFFFF)
fcvt_s(24, "t0")                     # f24 = -5.0
li("t0", 0xFFFFFFFF)
fcvt_s(25, "t0", unsigned=True)      # f25 = 4294967296.0 (lam tron len)
fmv_x_w("s3", 0)                     # s3 = 0x3F800000

# ---- flw / fsw ------------------------------------------------------------
# Co y dung offset KHAC 0: day dung la cho ext_imm truoc kia tra ve 0 cho hai
# opcode nay, nen moi flw/fsw deu doc ghi sai dia chi.
li("s0", 0x2000_2000)
fsw(2, 8, "s0")                      # mem[s0+8] = 3.0
flw(26, 8, "s0")                     # f26 = 3.0

# ---- subnormal ------------------------------------------------------------
fconst(27, 0x00000002, "2 * 2^-149 (subnormal)")
fconst(28, 0x00000001, "1 * 2^-149 (subnormal nho nhat)")
fop("add", 29, 27, 28)               # f29 = 0x00000003 - CHINH XAC, khong co co
fconst(30, 0x00800000, "2^-126 (so binh thuong nho nhat)")
fop("mul", 31, 30, 3)                # f31 = 2^-127 = 0x00400000 (subnormal)

# ---- co ngoai le ----------------------------------------------------------
# Tu day tro di khong con f de chua ket qua, nen chi kiem fcsr va vai gia tri.
csrrw("zero", 0x003, "zero")         # xoa fflags
fop("div", 8, 0, 6)                  # 1.0 / 0.0 -> +inf, DZ
csrr("s4", 0x001)                    # s4 = 0x08 (DZ)
fmv_x_w("s5", 8)                     # s5 = 0x7F800000

csrrw("zero", 0x003, "zero")
fop("div", 9, 6, 6)                  # 0.0 / 0.0 -> qNaN, NV
csrr("s6", 0x001)                    # s6 = 0x10 (NV)
fmv_x_w("s7", 9)                     # s7 = 0x7FC00000

csrrw("zero", 0x003, "zero")
fcmp("lt", "s8", 7, 0)               # flt voi qNaN -> 0 VA NV (so sanh signal)
csrr("s9", 0x001)                    # s9 = 0x10
csrrw("zero", 0x003, "zero")
fcmp("eq", "s10", 7, 0)              # feq voi qNaN -> 0, KHONG NV (quiet)
csrr("s11", 0x001)                   # s11 = 0x00

# Tran tren: so huu han lon nhat * 2.0 -> +inf, OF + NX
csrrw("zero", 0x003, "zero")
fconst(10, 0x7F7FFFFF, "so huu han lon nhat")
fop("mul", 11, 10, 1)
csrr("t3", 0x001)                    # t3 = 0x05 (OF | NX)

# Che do lam tron DONG: frm = RTZ roi chia 1/3 -> phai NHO hon ket qua RNE.
li("t0", RM_RTZ << 5)
csrrw("zero", 0x003, "t0")           # fcsr = {frm = RTZ, fflags = 0}
fop("div", 12, 0, 2, rm=RM_DYN)      # f12 = 0x3EAAAAAA  (RNE cho ra ...AB)
li("t0", 0)
csrrw("zero", 0x003, "t0")

# ---- xong -----------------------------------------------------------------
emit(enc_i(0x13, 0, x("t2"), 0, 1), "addi t2, zero, 1   (done)")
emit(0x0000006F, "done: j done")

assert ROM_BASE + 4 * len(out) <= TRAP, \
    "chuong trinh dai %d tu, de len TRAP" % len(out)
while ROM_BASE + 4 * len(out) < TRAP:
    emit(0x00000013, "nop  (dem)")
li("t2", 0xBAD)
emit(0x0000006F, "trap: j trap")

lines = ["// tb_fpu_core.sv - RV32F bang CPU that (2026-09-18).",
         "// SINH TU DONG boi gen_fpu_mem.py - sua o do, khong sua tay file nay."]
for pc, w, text in out:
    lines.append("%08x  // %08x  %s" % (w, pc, text))

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fpu_core.mem")
with open(path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
print("wrote %s (%d tu)" % (path, len(out)))
