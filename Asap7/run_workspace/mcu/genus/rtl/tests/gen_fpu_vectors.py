#!/usr/bin/env python3
"""Sinh tests/fpu_vectors.mem - vector kiem fpu_unit so voi MO HINH THAM CHIEU.

tb_fpu_core.sv chay RV32F tren CPU that nhung chi kiem duoc vai chuc gia tri
viet tay. File nay lam viec khac han: dung so huu ti CHINH XAC (fractions.
Fraction) de tinh ket qua dung tuyet doi cho tung phep toan, roi lam tron theo
DUNG chuan IEEE-754 voi ca 5 che do. Nho vay no bat duoc nhung loi ma test viet
tay khong the: lam tron sai o bit cuoi, sticky bi mat, subnormal bi cat, hoac
co ngoai le sai.

Vi sao Fraction chu khong phai float cua Python:
  * float cua Python la binary64. Voi +,-,*,/ thi tinh o binary64 roi lam tron
    xuong binary32 VAN dung (53 >= 2*24+2), nhung FMA thi KHONG: tich a*b can
    48 bit dinh tri roi moi cong voi c - qua 53 bit la mat chinh xac, va mo hinh
    tham chieu se "dung" theo dung kieu sai ma phan cung co the dang sai.
  * Fraction cho ket qua chinh xac tuyet doi, khong co lam tron hai lan.
sqrt khong phai so huu ti nen duoc xu ly rieng bang math.isqrt tren so nguyen.

    python gen_fpu_vectors.py          # ghi fpu_vectors.mem canh script
"""
import math
import os
import random
import struct
from fractions import Fraction

# ---- ma phep toan: PHAI khop core/fpu_defines.vh --------------------------
FPOP = {
    "add": 0, "sub": 1, "mul": 2, "madd": 3, "msub": 4, "nmsub": 5, "nmadd": 6,
    "div": 7, "sqrt": 8,
    "sgnj": 9, "sgnjn": 10, "sgnjx": 11, "mv_x_w": 12, "mv_w_x": 13, "class": 14,
    "eq": 15, "lt": 16, "le": 17, "min": 18, "max": 19,
    "cvt_w_s": 20, "cvt_wu_s": 21, "cvt_s_w": 22, "cvt_s_wu": 23,
}
NAME_OF = {v: k for k, v in FPOP.items()}

RNE, RTZ, RDN, RUP, RMM = 0, 1, 2, 3, 4

NX, UF, OF, DZ, NV = 1, 2, 4, 8, 16       # vi tri bit trong fflags

QNAN = 0x7FC00000
P = 24                                     # so bit dinh tri
EMIN, EMAX = -126, 127
SUB_Q = Fraction(1, 2) ** 149              # buoc cua mien subnormal = 2^-149


# ===========================================================================
# Giai ma binary32
# ===========================================================================
def unpack(b):
    """32 bit -> (sign, kind, Fraction). kind: 'n' | 'z' | 'i' | 'nan'."""
    s = (b >> 31) & 1
    e = (b >> 23) & 0xFF
    m = b & 0x7FFFFF
    if e == 0xFF:
        return (s, 'nan' if m else 'i', None)
    if e == 0:
        if m == 0:
            return (s, 'z', Fraction(0))
        return (s, 'n', Fraction(m) * SUB_Q)
    return (s, 'n', Fraction(m + (1 << 23)) * (Fraction(2) ** (e - 127 - 23)))


def is_snan(b):
    return ((b >> 23) & 0xFF) == 0xFF and (b & 0x7FFFFF) != 0 and not (b & 0x400000)


# ===========================================================================
# Lam tron mot so huu ti CHINH XAC ve binary32.
#
# Day la trai tim cua mo hinh tham chieu - moi phep toan so hoc deu di qua day,
# y het cach RTL chi co MOT chuoi NORM -> DENORM -> ROUND -> PACK.
# ===========================================================================
def round_frac(sign, mag, rm):
    """mag la Fraction >= 0 (DO LON chinh xac). sign la 0/1."""
    flags = 0
    if mag == 0:
        return ((sign << 31), 0)

    two = Fraction(2)
    e = 0
    if mag >= 1:
        while mag >= two ** (e + 1):
            e += 1
    else:
        while mag < two ** e:
            e -= 1

    subnormal = (e < EMIN)
    quantum = SUB_Q if subnormal else two ** (e - (P - 1))
    q_exact = mag / quantum
    q_floor = q_exact.numerator // q_exact.denominator
    rem = q_exact - q_floor
    inexact = (rem != 0)

    if not inexact:
        q = q_floor
    elif rm == RTZ:
        q = q_floor
    elif rm == RDN:
        q = q_floor + 1 if sign else q_floor    # ve -inf = ra xa 0 khi am
    elif rm == RUP:
        q = q_floor if sign else q_floor + 1
    elif rm == RMM:
        q = q_floor + 1 if rem >= Fraction(1, 2) else q_floor
    else:                                       # RNE
        if rem > Fraction(1, 2):
            q = q_floor + 1
        elif rem < Fraction(1, 2):
            q = q_floor
        else:
            q = q_floor + 1 if (q_floor & 1) else q_floor

    if inexact:
        flags |= NX

    if subnormal:
        if q >= (1 << (P - 1)):                 # lam tron day len so binh thuong
            return ((sign << 31) | (1 << 23) | (q - (1 << (P - 1))), flags)
        # "tiny AFTER rounding": chi bao UF khi ket qua DA lam tron van subnormal
        if inexact:
            flags |= UF
        return ((sign << 31) | q, flags)

    if q >= (1 << P):                           # tran len bit 24
        q >>= 1
        e += 1

    if e > EMAX:
        flags |= OF | NX
        if rm == RTZ or (rm == RDN and not sign) or (rm == RUP and sign):
            return ((sign << 31) | 0x7F7FFFFF, flags)
        return ((sign << 31) | 0x7F800000, flags)

    return ((sign << 31) | ((e + 127) << 23) | (q - (1 << (P - 1))), flags)


def ref_sqrt(mag, rm, flags):
    """mag la Fraction > 0. Dung so nguyen chinh xac, khong dung float."""
    two = Fraction(2)
    e = 0
    if mag >= 1:
        while mag >= two ** (2 * (e + 1)):
            e += 1
    else:
        while mag < two ** (2 * e):
            e -= 1
    subnormal = (e < EMIN)
    quantum = SUB_Q if subnormal else two ** (e - (P - 1))

    # r = (sqrt(mag)/quantum)^2 = mag / quantum^2, so huu ti chinh xac
    r = mag / (quantum * quantum)
    n, d = r.numerator, r.denominator
    q_floor = math.isqrt(n * d) // d
    while (q_floor + 1) * (q_floor + 1) * d <= n:
        q_floor += 1
    exact_sq = (q_floor * q_floor * d == n)

    if exact_sq:
        q = q_floor
        inexact = False
    else:
        inexact = True
        # So sanh voi diem giua bang BINH PHUONG: (q+1/2)^2 vs r
        #   <=>  (2q+1)^2 * d   vs   4n
        mid_cmp = (2 * q_floor + 1) ** 2 * d - 4 * n
        if rm in (RTZ, RDN):                     # sqrt luon duong
            q = q_floor
        elif rm == RUP:
            q = q_floor + 1
        elif rm == RMM:
            q = q_floor + 1 if mid_cmp <= 0 else q_floor
        else:                                    # RNE
            if mid_cmp < 0:
                q = q_floor + 1
            elif mid_cmp > 0:
                q = q_floor
            else:
                q = q_floor + 1 if (q_floor & 1) else q_floor

    if inexact:
        flags |= NX
    if subnormal:
        if q >= (1 << (P - 1)):
            return ((1 << 23) | (q - (1 << (P - 1))), flags)
        if inexact:
            flags |= UF
        return (q, flags)
    if q >= (1 << P):
        q >>= 1
        e += 1
    return (((e + 127) << 23) | (q - (1 << (P - 1))), flags)


# ===========================================================================
# Tung phep toan
# ===========================================================================
def ref_arith(op, a, b, c, rm):
    flags = 0
    name = NAME_OF[op]

    if name in ("add", "sub"):
        ops = [a, 0x3F800000, b]
        neg_c = (name == "sub")
        neg_p = False
        has_c = True
    elif name == "mul":
        ops = [a, b, 0]
        neg_c = neg_p = False
        has_c = False
    elif name in ("madd", "msub", "nmsub", "nmadd"):
        ops = [a, b, c]
        neg_c = name in ("msub", "nmadd")
        neg_p = name in ("nmsub", "nmadd")
        has_c = True
    elif name == "div":
        ops = [a, b, 0]
        neg_c = neg_p = False
        has_c = False
    else:                                        # sqrt
        ops = [a, 0, 0]
        neg_c = neg_p = False
        has_c = False

    sa, ka, va = unpack(ops[0])
    sb, kb, vb = unpack(ops[1])
    sc, kc, vc = unpack(ops[2])
    sc ^= (1 if neg_c else 0)
    sp = sa ^ sb ^ (1 if neg_p else 0)

    if is_snan(ops[0]) or is_snan(ops[1]) or (has_c and is_snan(ops[2])):
        flags |= NV

    if name == "sqrt":
        if ka == 'nan':
            return (QNAN, flags)
        if ka == 'z':
            return (ops[0], flags)               # sqrt(-0) = -0
        if sa:
            return (QNAN, flags | NV)
        if ka == 'i':
            return (0x7F800000, flags)
        return ref_sqrt(va, rm, flags)

    if ka == 'nan' or kb == 'nan' or (has_c and kc == 'nan'):
        return (QNAN, flags)

    if name == "div":
        if (ka == 'i' and kb == 'i') or (ka == 'z' and kb == 'z'):
            return (QNAN, flags | NV)
        if kb == 'z':
            return ((sp << 31) | 0x7F800000, flags | DZ)
        if ka == 'i':
            return ((sp << 31) | 0x7F800000, flags)
        if ka == 'z' or kb == 'i':
            return ((sp << 31), flags)
        r, f2 = round_frac(sp, va / vb, rm)
        return (r, flags | f2)

    # nhom FMA (gom ca add / sub / mul)
    if (ka == 'i' and kb == 'z') or (ka == 'z' and kb == 'i'):
        return (QNAN, flags | NV)                # 0 * inf
    if ka == 'i' or kb == 'i':
        if has_c and kc == 'i' and sc != sp:
            return (QNAN, flags | NV)            # inf - inf
        return ((sp << 31) | 0x7F800000, flags)
    if has_c and kc == 'i':
        return ((sc << 31) | 0x7F800000, flags)

    prod = va * vb
    addend = vc if has_c else Fraction(0)
    pv = -prod if sp else prod
    cv = -addend if sc else addend
    exact = pv + cv

    if exact == 0:
        # +-0: dau chi giu khi HAI dau giong nhau; nguoc lai +0, rieng RDN cho -0.
        if not has_c:
            sign = sp
        elif prod == 0 and addend == 0:
            sign = sp if sp == sc else (1 if rm == RDN else 0)
        else:
            sign = 1 if rm == RDN else 0         # trieu tieu hoan toan
        return ((sign << 31), flags)

    sign = 1 if exact < 0 else 0
    r, f2 = round_frac(sign, abs(exact), rm)
    return (r, flags | f2)


def ref_convert(op, a, rm):
    name = NAME_OF[op]
    flags = 0
    if name == "cvt_s_w":
        v = a - (1 << 32) if a & 0x80000000 else a
        if v == 0:
            return (0, 0)
        return round_frac(1 if v < 0 else 0, Fraction(abs(v)), rm)
    if name == "cvt_s_wu":
        if a == 0:
            return (0, 0)
        return round_frac(0, Fraction(a), rm)

    # float -> int
    s, k, v = unpack(a)
    unsigned = (name == "cvt_wu_s")
    lo, hi = (0, (1 << 32) - 1) if unsigned else (-(1 << 31), (1 << 31) - 1)
    if k == 'nan':
        return (hi & 0xFFFFFFFF, NV)
    if k == 'i':
        return (((hi if not s else lo) & 0xFFFFFFFF), NV)
    if k == 'z':
        return (0, 0)

    exact = -v if s else v
    fl = exact.numerator // exact.denominator          # floor (huong -inf)
    rem = exact - fl
    inexact = (rem != 0)
    if not inexact:
        n = fl
    elif rm == RTZ:
        n = fl + 1 if exact < 0 else fl
    elif rm == RDN:
        n = fl
    elif rm == RUP:
        n = fl + 1
    elif rm == RMM:
        if rem > Fraction(1, 2):
            n = fl + 1
        elif rem < Fraction(1, 2):
            n = fl
        else:
            n = fl if exact < 0 else fl + 1             # hoa -> RA XA 0
    else:                                              # RNE
        if rem > Fraction(1, 2):
            n = fl + 1
        elif rem < Fraction(1, 2):
            n = fl
        else:
            n = fl + 1 if (fl & 1) else fl

    if n < lo or n > hi:
        return (((hi if n > hi else lo) & 0xFFFFFFFF), NV)
    if inexact:
        flags |= NX
    return (n & 0xFFFFFFFF, flags)


# ===========================================================================
# Sinh vector
# ===========================================================================
random.seed(int(os.environ.get("FPU_VEC_SEED", "20260918")))

# So vector ngau nhien cho moi (phep toan x che do lam tron). Mac dinh giu nho
# de `run_soc_sim.sh all` khong cham; dat FPU_VEC_N cao hon khi muon quet sau:
#     FPU_VEC_N=2000 bash run_soc_sim.sh fpuv
# Ba loi that duoc tim ra ngay o muc mac dinh, nen quet sau chu yeu de tang tin
# cay sau khi sua, khong phai de tim loi lan dau.
NRAND = int(os.environ.get("FPU_VEC_N", "140"))

SPECIAL = [
    0x00000000, 0x80000000,                # +-0
    0x00000001, 0x80000001,                # +- subnormal nho nhat
    0x007FFFFF, 0x00800000, 0x80800000,    # subnormal lon nhat / thuong nho nhat
    0x3F800000, 0xBF800000,                # +-1.0
    0x40000000, 0x40400000, 0x3F000000,    # 2.0  3.0  0.5
    0x7F7FFFFF, 0xFF7FFFFF,                # +- huu han lon nhat
    0x7F800000, 0xFF800000,                # +-inf
    0x7FC00000, 0x7F800001,                # qNaN, sNaN
    0x4B7FFFFF, 0x4F000000, 0xCF000000,    # quanh 2^24, +-2^31
    0x33800000, 0x00000002,
]


def rand_f32():
    r = random.random()
    if r < 0.30:
        return random.choice(SPECIAL)
    if r < 0.45:                                    # subnormal
        return (random.getrandbits(1) << 31) | random.getrandbits(23)
    if r < 0.60:                                    # so mu gan nhau -> trieu tieu
        e = random.randint(120, 134)
        return (random.getrandbits(1) << 31) | (e << 23) | random.getrandbits(23)
    return random.getrandbits(32)


vectors = []
CONV_OPS = (FPOP["cvt_w_s"], FPOP["cvt_wu_s"], FPOP["cvt_s_w"], FPOP["cvt_s_wu"])


def add_vec(op, rm, a, b, c, note):
    if op in CONV_OPS:
        res, fl = ref_convert(op, a, rm)
    else:
        res, fl = ref_arith(op, a, b, c, rm)
    vectors.append((op, rm, a, b, c, res, fl, note))


ARITH = ["add", "sub", "mul", "div", "sqrt", "madd", "msub", "nmsub", "nmadd"]
CONV = ["cvt_w_s", "cvt_wu_s", "cvt_s_w", "cvt_s_wu"]

# 1. Moi to hop (phep toan x che do lam tron) voi toan hang dac biet
for name in ARITH:
    for rm in (RNE, RTZ, RDN, RUP, RMM):
        for a in SPECIAL:
            for b in (0x3F800000, 0x40000000, 0x00000001, 0x7F800000, 0x00000000):
                add_vec(FPOP[name], rm, a, b, 0x3F800000, name)

# 2. Ngau nhien, nang ve subnormal va cac truong hop trieu tieu
for name in ARITH:
    for rm in (RNE, RTZ, RDN, RUP, RMM):
        for _ in range(NRAND):
            add_vec(FPOP[name], rm, rand_f32(), rand_f32(), rand_f32(), name)

# 3. Chuyen doi
for name in CONV:
    for rm in (RNE, RTZ, RDN, RUP, RMM):
        for a in SPECIAL:
            add_vec(FPOP[name], rm, a, 0, 0, name)
        for _ in range(NRAND):
            add_vec(FPOP[name], rm, rand_f32(), 0, 0, name)

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fpu_vectors.mem")
with open(path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("// tests/fpu_vectors.mem - SINH TU DONG boi gen_fpu_vectors.py.\n")
    fh.write("// op rm a b c ket_qua fflags\n")
    for op, rm, a, b, c, res, fl, note in vectors:
        fh.write("%02x %01x %08x %08x %08x %08x %02x // %s\n"
                 % (op, rm, a, b, c, res, fl, note))
print("wrote %s (%d vector)" % (path, len(vectors)))
