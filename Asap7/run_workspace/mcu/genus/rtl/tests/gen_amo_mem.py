#!/usr/bin/env python3
"""Sinh tests/amo_core.mem - anh ROM cho tb_amo_core.sv (run_soc_sim.sh amo).

AMO chay bang CPU THAT (2026-09-13). tb_mem_paths.sv T10 tu dong vai tang MEM
nen KHONG di qua AMO ALU va thanh ghi amo_wdata_q trong pipeline_stage.v - tuc
dung phan vua doi sang bat tay 3 chu ky. Chuong trinh nay:
  * chay du 9 ma AMO*.W tren mot line da cache, moi lenh dung rs2 vua duoc tinh
    o lenh ngay truoc (forwarding vao EX/MEM),
  * hai AMO lien tiep, rd cua AMO dung ngay o lenh sau,
  * AMO TRUOT cache (nhanh R11 -> vong LOOKUP thu hai),
  * LR/SC thanh cong va SC that bai (duong dcache_write_data khong phai RMW).
Moi ket qua giu trong mot thanh ghi, testbench doc rf_main.

ENABLE_A_EXTENSION = 0 trong RTL, nen testbench bat A bang defparam.

    python gen_amo_mem.py          # ghi amo_core.mem canh script
"""
import os

REG = {n: i for i, n in enumerate(
    "zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 "
    "s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6".split())}
ROM_BASE = 0x0001_0000


def r(n):
    return REG[n]


def enc_i(op, f3, rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | (r(rs1) << 15) | (f3 << 12) | (r(rd) << 7) | op


def enc_s(f3, rs2, rs1, imm):
    return (((imm >> 5) & 0x7F) << 25) | (r(rs2) << 20) | (r(rs1) << 15) | \
           (f3 << 12) | ((imm & 0x1F) << 7) | 0x23


def enc_amo(f5, rd, rs2, rs1):
    return (f5 << 27) | (r(rs2) << 20) | (r(rs1) << 15) | (0b010 << 12) | (r(rd) << 7) | 0x2F


# Doi chieu voi ma da biet (gen_irq_pmp_mem.py) va voi objdump cua GNU as:
#   amoadd.w a0, t1, (s0) = 0x0064252f ; lr.w s8, (s0) = 0x10042c2f
assert enc_i(0x03, 2, "a0", "s0", 0) == 0x00042503
assert enc_s(2, "t0", "s0", 8) == 0x00542423
assert enc_amo(0b00000, "a0", "t1", "s0") == 0x0064252F
assert enc_amo(0b00010, "s8", "zero", "s0") == 0x10042C2F

AMO = {"add": 0b00000, "swap": 0b00001, "lr": 0b00010, "sc": 0b00011,
       "xor": 0b00100, "or": 0b01000, "and": 0b01100, "min": 0b10000,
       "max": 0b10100, "minu": 0b11000, "maxu": 0b11100}

out = []


def emit(word, text):
    out.append((ROM_BASE + 4 * len(out), word & 0xFFFFFFFF, text))


def li(rd, val):
    val &= 0xFFFFFFFF
    lo = val & 0xFFF
    lo_s = lo - 0x1000 if lo & 0x800 else lo
    hi = ((val - lo_s) >> 12) & 0xFFFFF
    emit((hi << 12) | (r(rd) << 7) | 0x37, "lui  %s, 0x%x" % (rd, hi))
    emit(enc_i(0x13, 0, rd, rd, lo_s), "addi %s, %s, %d  (%s = 0x%08x)" % (rd, rd, lo_s, rd, val))


def addi(rd, rs, imm):
    emit(enc_i(0x13, 0, rd, rs, imm), "addi %s, %s, %d" % (rd, rs, imm))


def amo(op, rd, rs2, rs1):
    name = op + ".w" if op in ("lr", "sc") else "amo" + op + ".w"
    emit(enc_amo(AMO[op], rd, rs2, rs1), "%s %s, %s, (%s)" % (name, rd, rs2, rs1))


def lw(rd, off, rs):
    emit(enc_i(0x03, 2, rd, rs, off), "lw   %s, %d(%s)" % (rd, off, rs))


def sw(rs2, off, rs):
    emit(enc_s(2, rs2, rs, off), "sw   %s, %d(%s)" % (rs2, off, rs))


# mtvec -> TRAP (t2 = 0xBAD) de testbench phan biet illegal-instruction voi treo.
TRAP = ROM_BASE + 0x100
li("t0", TRAP)
emit((0x305 << 20) | (r("t0") << 15) | (1 << 12) | 0x73, "csrw mtvec, t0")

li("s0", 0x2000_1000)                   # RAM lo, cached
li("t0", 100); sw("t0", 0, "s0")
lw("t3", 0, "s0")                       # nap line vao D-cache

addi("t1", "zero", 5);  amo("add", "a0", "t1", "s0")    # a0 = 100,        mem = 105
addi("t1", "zero", -7); amo("min", "a1", "t1", "s0")    # a1 = 105,        mem = -7
addi("t1", "zero", 3);  amo("max", "a2", "t1", "s0")    # a2 = -7,         mem = 3
addi("t1", "zero", -1); amo("minu", "a3", "t1", "s0")   # a3 = 3,          mem = 3
amo("maxu", "a4", "t1", "s0")                           # a4 = 3,          mem = 0xFFFFFFFF
li("t1", 0x0F0F_0F0F);  amo("xor", "a5", "t1", "s0")    # a5 = FFFFFFFF,   mem = F0F0F0F0
li("t1", 0x3C3C_3C3C);  amo("and", "a6", "t1", "s0")    # a6 = F0F0F0F0,   mem = 30303030
li("t1", 0x0101_0101);  amo("or", "a7", "t1", "s0")     # a7 = 30303030,   mem = 31313131
li("t1", 0x1234_5678);  amo("swap", "s2", "t1", "s0")   # s2 = 31313131,   mem = 12345678
lw("s3", 0, "s0")                                       # s3 = 12345678
amo("add", "s4", "t1", "s0")                            # s4 = 12345678,   mem = 2468ACF0
emit((r("zero") << 20) | (r("s4") << 15) | (r("s5") << 7) | 0x33, "add  s5, s4, zero")  # s5 = 12345678

li("s1", 0x2000_1800)                                   # line khac, chua cache
li("t0", 0x40); sw("t0", 0, "s1")                       # sw khong write-allocate
addi("t1", "zero", 2); amo("add", "s6", "t1", "s1")     # AMO TRUOT: s6 = 0x40, mem = 0x42
lw("s7", 0, "s1")                                       # s7 = 0x42

amo("lr", "s8", "zero", "s0")                           # s8 = 2468ACF0
addi("t1", "zero", 0x55); amo("sc", "s9", "t1", "s0")   # s9 = 0 (thanh cong) - HIEN = 1, xem tb
lw("s10", 0, "s0")                                      # s10 = 0x55
amo("sc", "s11", "t1", "s0")                            # s11 = 1 (khong reservation)
lw("t4", 0, "s0")                                       # t4 = 0x55 (SC that bai khong ghi)

addi("t2", "zero", 1)
emit(0x0000006F, "done: j done")

assert ROM_BASE + 4 * len(out) <= TRAP, "chuong trinh de len TRAP"
while ROM_BASE + 4 * len(out) < TRAP:
    emit(0x00000013, "nop  (dem)")
li("t2", 0xBAD)
emit(0x0000006F, "trap: j trap")

lines = ["// tb_amo_core.sv - AMO bang CPU that (bat tay 3 chu ky, 2026-09-13).",
         "// SINH TU DONG boi gen_amo_mem.py - sua o do, khong sua tay file nay."]
for pc, w, text in out:
    lines.append("%08x  // %08x  %s" % (w, pc, text))

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "amo_core.mem")
with open(path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
print("wrote %s (%d tu)" % (path, len(out)))
