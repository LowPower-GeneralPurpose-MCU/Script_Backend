#!/usr/bin/env python3
"""Sinh tests/sys_ctrl.mem - anh ROM cho tb_sys_ctrl.sv (run_soc_sim.sh sys).

Khong co toolchain RISC-V tren may nay, nen chuong trinh duoc ma hoa tay bang
vai ham duoi day. Ma hoa da doi chieu voi tests/core_jalr.mem:
    lui s0, 0x20000 = 20000437,  lw a0, 0(s0) = 00042503,  addi t2, zero, 1 = 00100393

    python gen_sys_ctrl_mem.py            # ghi sys_ctrl.mem canh script
"""
import os

ZERO, T0, T1, T2, S0 = 0, 5, 6, 7, 8
A1, A2, A3, A4, A5, A6 = 11, 12, 13, 14, 15, 16


def lui(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0x37


def addi(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (rd << 7) | 0x13


def lw(rd, off, rs1):
    return ((off & 0xFFF) << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x03


def sw(rs2, off, rs1):
    return (((off >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | ((off & 0x1F) << 7) | 0x23


JAL_SELF = 0x0000006F   # jal zero, 0
WFI = 0x10500073
NOP = 0x00000013

assert lui(S0, 0x20000) == 0x20000437
assert lw(10, 0, S0) == 0x00042503
assert addi(T2, ZERO, 1) == 0x00100393

SYSCON = 0x40007            # lui -> 0x4000_7000
ENTRY_B = 0x80              # byte offset cua loi vao boot 2 trong ROM

# Boot 1: vao tu RESET_VECTOR mac dinh 0x0001_0000 sau POR.
boot1 = [
    (lui(S0, SYSCON),      "lui  s0, 0x40007        s0 = SYSCON"),
    (lw(A1, 8, S0),        "lw   a1, 8(s0)          a1 = RST_CAUSE sau POR (mong doi 1 = EXT)"),
    (addi(T0, ZERO, 15),   "addi t0, zero, 15"),
    (sw(T0, 8, S0),        "sw   t0, 8(s0)          W1C xoa moi co"),
    (lw(A2, 8, S0),        "lw   a2, 8(s0)          a2 = RST_CAUSE sau khi xoa (mong doi 0)"),
    (lw(A3, 4, S0),        "lw   a3, 4(s0)          a3 = CLK_GATE_CTRL ([6] = clock DM)"),
    (addi(T2, ZERO, 1),    "addi t2, zero, 1        pha 1: sap ngu"),
    (WFI,                  "wfi                     mie = 0 -> chi haltreq danh thuc duoc"),
    (NOP,                  "nop                     (lenh ngay sau wfi chay truoc khi ngu)"),
    (NOP,                  "nop"),
    (addi(T2, ZERO, 2),    "addi t2, zero, 2        pha 2: debugger da resume"),
    (lui(T0, 0x10),        "lui  t0, 0x10"),
    (addi(T0, T0, ENTRY_B),"addi t0, t0, 0x80       t0 = 0x0001_0080"),
    (sw(T0, 0, S0),        "sw   t0, 0(s0)          RESET_VECTOR = loi vao boot 2"),
    (lui(T1, 0x05FA0),     "lui  t1, 0x05FA0"),
    (addi(T1, T1, 1),      "addi t1, t1, 1          t1 = 0x05FA_0001"),
    (sw(T1, 12, S0),       "sw   t1, 12(s0)         SW_RESET -> warm reset"),
    (JAL_SELF,             "jal  zero, 0"),
]

# Boot 2: chi toi duoc neu RESET_VECTOR song qua warm reset.
boot2 = [
    (lui(S0, SYSCON),      "lui  s0, 0x40007"),
    (lw(A4, 8, S0),        "lw   a4, 8(s0)          a4 = RST_CAUSE (mong doi 8 = SW)"),
    (addi(T0, ZERO, 1),    "addi t0, zero, 1"),
    (sw(T0, 16, S0),       "sw   t0, 16(s0)         SEC_CTRL.BOOT_LOCK"),
    (lui(T0, 0x10),        "lui  t0, 0x10"),
    (sw(T0, 0, S0),        "sw   t0, 0(s0)          thu ghi RESET_VECTOR = 0x10000 (phai bi bo qua)"),
    (lw(A5, 0, S0),        "lw   a5, 0(s0)          a5 = RESET_VECTOR (mong doi 0x0001_0080)"),
    (addi(T0, ZERO, 4),    "addi t0, zero, 4"),
    (sw(T0, 16, S0),       "sw   t0, 16(s0)         SEC_CTRL.DBG_LOCK"),
    (lw(A6, 16, S0),       "lw   a6, 16(s0)         a6 = SEC_CTRL (mong doi 5 = DBG_LOCK | BOOT_LOCK)"),
    (addi(T2, ZERO, 3),    "addi t2, zero, 3        pha 3: xong"),
    (JAL_SELF,             "jal  zero, 0"),
]

assert len(boot1) * 4 <= ENTRY_B

lines = [
    "// tb_sys_ctrl.sv - SYSCON reset/boot/khoa debug + halt khi WFI.",
    "// SINH TU DONG boi gen_sys_ctrl_mem.py - sua o do, khong sua tay file nay.",
]
for i, (word, text) in enumerate(boot1):
    lines.append("%08x  // %08x  %s" % (word, 0x10000 + 4 * i, text))
lines.append("@%x" % (ENTRY_B // 4))
for i, (word, text) in enumerate(boot2):
    lines.append("%08x  // %08x  %s" % (word, 0x10000 + ENTRY_B + 4 * i, text))

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sys_ctrl.mem")
with open(out, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
print("wrote", out)
