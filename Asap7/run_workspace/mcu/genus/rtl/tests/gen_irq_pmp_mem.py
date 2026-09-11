#!/usr/bin/env python3
"""Sinh tests/irq_pmp.mem - anh ROM cho tb_irq_pmp.sv (run_soc_sim.sh irq).

Kiem muc 6 va 7 cua review 2026-09-11 bang CPU THAT:
  pha 1  PMP: load/store/fetch bi chan, entry khoa khong sua duoc (ke ca doc
         lai ngay sau lenh ghi - duong forwarding CSR), WARL R=0/W=1, entry
         >= 8 chi doc 0, entry KHONG khoa khong anh huong M-mode.
  pha 2  CLIC: vector theo nguon (mtvec + 4*id), mcause/mintstatus, pending
         cua ngat canh tu xoa khi core nhan.
  pha 3  CLIC long nhau: ISR muc thap bat MIE -> ngat muc cao preempt, ngat
         CUNG muc phai cho toi mret; mpil khoi phuc qua mcause.
  pha 4  mintthresh chan ngat co muc khong vuot nguong.
  pha 5  Hoi quy loi mat ngat: testbench bat mot ngat MUC dung luc D-cache
         dang stall voi mot lenh load o MEM. Handler phai chay DUNG MOT lan va
         MIE phai tro lai 1.
  pha 6  WFI: core ngu (clock tat), testbench bat ngat -> core thuc va vao ISR.

Khong co toolchain RISC-V tren may nay, nen day la mot assembler hai luot rat
nho (co nhan). Ma hoa doi chieu voi gen_sys_ctrl_mem.py / core_jalr.mem.

    python gen_irq_pmp_mem.py          # ghi irq_pmp.mem canh script
"""
import os

REG = {n: i for i, n in enumerate(
    "zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 "
    "s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6".split())}

CSR = {"mstatus": 0x300, "mtvec": 0x305, "mepc": 0x341, "mcause": 0x342,
       "mtval": 0x343, "mintthresh": 0x347, "mintstatus": 0xFB1,
       "pmpcfg0": 0x3A0, "pmpcfg1": 0x3A1, "pmpcfg2": 0x3A2,
       "pmpaddr0": 0x3B0, "pmpaddr1": 0x3B1, "pmpaddr2": 0x3B2,
       "pmpaddr3": 0x3B3, "pmpaddr4": 0x3B4, "pmpaddr8": 0x3B8}

ROM_BASE = 0x0001_0000
VTAB = 0x0001_0800          # can le 64 byte (CLIC), 32 o x 4 byte
CLIC_INT = 0x4400_1000      # clicint[0]


def r(n):
    return REG[n]


def enc_i(op, f3, rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | (r(rs1) << 15) | (f3 << 12) | (r(rd) << 7) | op


def enc_s(f3, rs2, rs1, imm):
    return (((imm >> 5) & 0x7F) << 25) | (r(rs2) << 20) | (r(rs1) << 15) | \
           (f3 << 12) | ((imm & 0x1F) << 7) | 0x23


def enc_b(f3, rs1, rs2, off):
    assert off % 2 == 0 and -4096 <= off < 4096, off
    o = off & 0x1FFF
    return (((o >> 12) & 1) << 31) | (((o >> 5) & 0x3F) << 25) | (r(rs2) << 20) | \
           (r(rs1) << 15) | (f3 << 12) | (((o >> 1) & 0xF) << 8) | \
           (((o >> 11) & 1) << 7) | 0x63


def enc_j(rd, off):
    assert off % 2 == 0 and -(1 << 20) <= off < (1 << 20), off
    o = off & 0x1FFFFF
    return (((o >> 20) & 1) << 31) | (((o >> 1) & 0x3FF) << 21) | \
           (((o >> 11) & 1) << 20) | (((o >> 12) & 0xFF) << 12) | (r(rd) << 7) | 0x6F


def enc_csr(f3, rd, csr, rs1_or_uimm):
    src = rs1_or_uimm if isinstance(rs1_or_uimm, int) else r(rs1_or_uimm)
    return (CSR[csr] << 20) | (src << 15) | (f3 << 12) | (r(rd) << 7) | 0x73


# Kiem ma hoa voi cac tu da biet trong gen_sys_ctrl_mem.py / core_jalr.mem
assert enc_i(0x13, 0, "t2", "zero", 1) == 0x00100393          # addi t2, zero, 1
assert enc_i(0x03, 2, "a0", "s0", 0) == 0x00042503            # lw a0, 0(s0)
assert enc_s(2, "t0", "s0", 8) == 0x00542423                  # sw t0, 8(s0)

MRET = 0x30200073
WFI = 0x10500073
NOP = 0x00000013


class Asm:
    def __init__(self):
        self.items = []          # (kind, payload, comment)

    def label(self, name):
        self.items.append(("label", name, ""))

    def org(self, addr):
        self.items.append(("org", addr, ""))

    def emit(self, fn, text):
        self.items.append(("ins", fn, text))

    # --- lenh ---
    def addi(self, rd, rs, imm):
        self.emit(lambda L, pc: enc_i(0x13, 0, rd, rs, imm), "addi %s, %s, %d" % (rd, rs, imm))

    def ori(self, rd, rs, imm):
        self.emit(lambda L, pc: enc_i(0x13, 6, rd, rs, imm), "ori  %s, %s, %d" % (rd, rs, imm))

    def slli(self, rd, rs, sh):
        self.emit(lambda L, pc: enc_i(0x13, 1, rd, rs, sh), "slli %s, %s, %d" % (rd, rs, sh))

    def srli(self, rd, rs, sh):
        self.emit(lambda L, pc: enc_i(0x13, 5, rd, rs, sh), "srli %s, %s, %d" % (rd, rs, sh))

    def add(self, rd, rs1, rs2):
        self.emit(lambda L, pc: (r(rs2) << 20) | (r(rs1) << 15) | (r(rd) << 7) | 0x33,
                  "add  %s, %s, %s" % (rd, rs1, rs2))

    def lw(self, rd, off, rs):
        self.emit(lambda L, pc: enc_i(0x03, 2, rd, rs, off), "lw   %s, %d(%s)" % (rd, off, rs))

    def sw(self, rs2, off, rs):
        self.emit(lambda L, pc: enc_s(2, rs2, rs, off), "sw   %s, %d(%s)" % (rs2, off, rs))

    def li(self, rd, val):
        """Luon hai lenh (lui + addi) de kich thuoc co dinh."""
        val &= 0xFFFFFFFF
        lo = val & 0xFFF
        lo_s = lo - 0x1000 if lo & 0x800 else lo
        hi = ((val - lo_s) >> 12) & 0xFFFFF
        self.emit(lambda L, pc: (hi << 12) | (r(rd) << 7) | 0x37, "lui  %s, 0x%x" % (rd, hi))
        self.emit(lambda L, pc: enc_i(0x13, 0, rd, rd, lo_s), "addi %s, %s, %d  (%s = 0x%08x)"
                  % (rd, rd, lo_s, rd, val))

    def la(self, rd, lab):
        def hi_fn(L, pc):
            v = L[lab]
            lo = v & 0xFFF
            lo_s = lo - 0x1000 if lo & 0x800 else lo
            return ((((v - lo_s) >> 12) & 0xFFFFF) << 12) | (r(rd) << 7) | 0x37

        def lo_fn(L, pc):
            lo = L[lab] & 0xFFF
            return enc_i(0x13, 0, rd, rd, lo - 0x1000 if lo & 0x800 else lo)
        self.emit(hi_fn, "lui  %s, %%hi(%s)" % (rd, lab))
        self.emit(lo_fn, "addi %s, %s, %%lo(%s)" % (rd, rd, lab))

    def beq(self, a, b, lab):
        self.emit(lambda L, pc: enc_b(0, a, b, L[lab] - pc), "beq  %s, %s, %s" % (a, b, lab))

    def bne(self, a, b, lab):
        self.emit(lambda L, pc: enc_b(1, a, b, L[lab] - pc), "bne  %s, %s, %s" % (a, b, lab))

    def jal(self, rd, lab):
        self.emit(lambda L, pc: enc_j(rd, L[lab] - pc), "jal  %s, %s" % (rd, lab))

    def jalr(self, rd, rs, off=0):
        self.emit(lambda L, pc: enc_i(0x67, 0, rd, rs, off), "jalr %s, %d(%s)" % (rd, off, rs))

    def csrw(self, csr, rs):
        self.emit(lambda L, pc: enc_csr(1, "zero", csr, rs), "csrw %s, %s" % (csr, rs))

    def csrr(self, rd, csr):
        self.emit(lambda L, pc: enc_csr(2, rd, csr, "zero"), "csrr %s, %s" % (rd, csr))

    def csrsi(self, csr, uimm):
        self.emit(lambda L, pc: enc_csr(6, "zero", csr, uimm), "csrsi %s, %d" % (csr, uimm))

    def csrci(self, csr, uimm):
        self.emit(lambda L, pc: enc_csr(7, "zero", csr, uimm), "csrci %s, %d" % (csr, uimm))

    def word(self, w, text):
        self.emit(lambda L, pc: w, text)

    # --- hai luot ---
    def assemble(self):
        labels, pc = {}, ROM_BASE
        for kind, p, _ in self.items:
            if kind == "label":
                labels[p] = pc
            elif kind == "org":
                assert p >= pc, "org 0x%x lui ve sau pc 0x%x" % (p, pc)
                pc = p
            else:
                pc += 4
        out, pc = [], ROM_BASE
        for kind, p, text in self.items:
            if kind == "org":
                while pc < p:
                    out.append((pc, NOP, "nop  (dem)"))
                    pc += 4
            elif kind == "ins":
                out.append((pc, p(labels, pc) & 0xFFFFFFFF, text))
                pc += 4
        return out, labels


a = Asm()

# =============================================================================
# PHA 1 - PMP (che do CLINT, mtvec direct = EXC)
# =============================================================================
a.label("MAIN")
a.addi("t2", "zero", 0)
a.la("t0", "EXC")
a.csrw("mtvec", "t0")
a.li("s0", 0x2002_0100)                 # RAM hi (uncached)
a.li("t0", 0x1111_1111); a.sw("t0", 0, "s0")
a.li("t0", 0x4444_4444); a.sw("t0", 4, "s0")
a.li("t0", 0x2222_2222); a.sw("t0", 0x100, "s0")
# entry0 OFF  (pmpaddr0 = can duoi TOR cua entry1 = 0x2002_0200)
# entry1 L|TOR|R   [0x2002_0200, 0x2002_0300)  doc duoc, ghi bi cam
# entry2 L|NA4     0x2002_0100                  cam het
# entry3 L|NA4|R   FUNC_NOX                     khong X -> loi lay lenh
# entry4 NA4 (KHONG L, khong quyen) FUNC_OK     M-mode van chay duoc
# entry5 ghi 0x02 (R=0,W=1 reserved)            WARL -> 0x00
a.li("t0", 0x2002_0200 >> 2); a.csrw("pmpaddr0", "t0")
a.li("t0", 0x2002_0300 >> 2); a.csrw("pmpaddr1", "t0")
a.li("t0", 0x2002_0100 >> 2); a.csrw("pmpaddr2", "t0")
a.la("t0", "FUNC_NOX"); a.srli("t0", "t0", 2); a.csrw("pmpaddr3", "t0")
a.la("t0", "FUNC_OK");  a.srli("t0", "t0", 2); a.csrw("pmpaddr4", "t0")
a.li("t0", 0x0000_0210); a.csrw("pmpcfg1", "t0")
a.li("t0", 0x9190_8900); a.csrw("pmpcfg0", "t0")
# P1 load bi cam -> mcause 5, mtval = dia chi
a.addi("t3", "zero", 0); a.addi("t4", "zero", 0)
a.lw("a0", 0, "s0")
a.addi("s2", "t3", 0); a.addi("s3", "t4", 0)
# P2 store bi cam -> 7
a.addi("t3", "zero", 0)
a.sw("t0", 0, "s0")
a.addi("s4", "t3", 0)
# P3 load trong TOR (R) duoc phep
a.addi("t3", "zero", 0)
a.lw("a1", 0x100, "s0")
# P4 store trong TOR bi cam, gia tri cu con nguyen
a.li("t1", 0x3333_3333)
a.sw("t1", 0x100, "s0")
a.addi("s5", "t3", 0)
a.lw("a2", 0x100, "s0")
# P5 dia chi khong thuoc entry nao
a.addi("t3", "zero", 0)
a.lw("a3", 4, "s0")
a.addi("s6", "t3", 0)
# P6 ghi pmpcfg0 bi khoa roi DOC NGAY (forwarding CSR).
# I-cache tra 1 lenh / 2 chu ky, nen binh thuong csrw va csrr cach nhau mot
# bong bong va KHONG di qua duong forwarding. Load uncached dung truoc tao mot
# lan dong bang dai: trong luc do I-cache lay xong csrr, bong bong bi nuot, va
# khi nha stall csrr o EX dung luc csrw o MEM (cung mau R13). tb_irq_pmp.sv dem
# so lan forwarding PMP thuc su xay ra.
a.lw("t1", 4, "s0")
a.csrw("pmpcfg0", "zero")
a.csrr("a4", "pmpcfg0")
# P7 pmpaddr cua entry khoa, va pmpaddr0 (can duoi TOR cua entry1 khoa)
a.csrw("pmpaddr2", "zero"); a.csrr("a5", "pmpaddr2")
a.csrw("pmpaddr0", "zero"); a.csrr("a6", "pmpaddr0")
# P8 WARL
a.csrr("a7", "pmpcfg1")
# P9 entry khong khoa, khong quyen: M-mode van goi duoc
a.addi("t3", "zero", 0)
a.jal("ra", "FUNC_OK")
a.addi("s7", "t3", 0)
# P10 entry khoa khong X: loi lay lenh
a.addi("t3", "zero", 0)
a.jal("ra", "FUNC_NOX")
a.addi("s8", "t3", 0); a.addi("s9", "t4", 0)
# P11 entry >= 8 chi doc 0
a.li("t0", 0x1234_5678)
a.csrw("pmpaddr8", "t0"); a.csrr("s10", "pmpaddr8")
a.csrw("pmpcfg2", "t0");  a.csrr("s11", "pmpcfg2")
a.addi("t2", "zero", 1)                           # ---- PHA 1 XONG

# =============================================================================
# PHA 2..6 - CLIC (mtvec = VTAB | 3)
# =============================================================================
a.la("t0", "VTAB"); a.ori("t0", "t0", 3); a.csrw("mtvec", "t0")
a.li("s1", CLIC_INT)
a.addi("gp", "zero", 0); a.addi("tp", "zero", 0)

CFG_L1_EDGE = 0x2003_0100    # ctl muc 1, attr shv|canh len, ie
CFG_L7_EDGE = 0xE003_0100    # ctl muc 7
CFG_L1_LVL  = 0x2001_0100    # ctl muc 1, attr shv|muc cao, ie

# ---- pha 2: ID 30 ----
a.li("t0", CFG_L1_EDGE); a.sw("t0", 30 * 4, "s1")
a.csrsi("mstatus", 8)
a.li("t0", CFG_L1_EDGE | 1); a.sw("t0", 30 * 4, "s1")
a.label("WA"); a.beq("gp", "zero", "WA")
a.addi("s2", "t3", 0); a.addi("s3", "t4", 0); a.addi("s4", "t5", 0)
a.addi("s5", "gp", 0); a.csrr("s6", "mintstatus")
a.addi("t2", "zero", 2)                           # ---- PHA 2 XONG

# ---- pha 3: long nhau 14 (muc 1) <- 15 (muc 7), 13 (muc 1) cho ----
a.addi("s11", "zero", 0); a.addi("tp", "zero", 0); a.addi("a1", "zero", 0)
a.li("t0", CFG_L1_EDGE); a.sw("t0", 13 * 4, "s1"); a.sw("t0", 14 * 4, "s1")
a.li("t0", CFG_L7_EDGE); a.sw("t0", 15 * 4, "s1")
a.li("t0", CFG_L1_EDGE | 1); a.sw("t0", 14 * 4, "s1")
a.label("WB"); a.beq("a1", "zero", "WB")
a.addi("t2", "zero", 3)                           # ---- PHA 3 XONG

# ---- pha 4: mintthresh ----
a.addi("t0", "zero", 0x3F); a.csrw("mintthresh", "t0")
a.li("t0", CFG_L1_EDGE | 1); a.sw("t0", 30 * 4, "s1")
a.addi("t0", "zero", 60)
a.label("DC"); a.addi("t0", "t0", -1); a.bne("t0", "zero", "DC")
a.addi("a2", "gp", 0)
a.csrw("mintthresh", "zero")
a.addi("t1", "zero", 2)
a.label("WC"); a.bne("gp", "t1", "WC")
a.addi("a4", "gp", 0)
a.addi("t2", "zero", 4)                           # ---- PHA 4 XONG

# ---- pha 5: ngat MUC toi giua luc D-cache stall (testbench bat) ----
a.li("s0", 0x2000_0000); a.li("t0", 0x5A5A_5A5A); a.sw("t0", 0, "s0")
a.li("t0", CFG_L1_LVL); a.sw("t0", 12 * 4, "s1")
a.addi("a5", "zero", 0); a.addi("a6", "zero", 0)
a.addi("t2", "zero", 5)                           # testbench bat dau canh
a.addi("t0", "zero", 300)
a.label("LD"); a.lw("t1", 0, "s0"); a.add("a6", "a6", "t1")
a.addi("t0", "t0", -1); a.bne("t0", "zero", "LD")
a.csrr("a7", "mstatus")
a.addi("t2", "zero", 6)                           # ---- PHA 5 XONG

# ---- pha 6: WFI, testbench bat ngat khi clock CPU da tat ----
a.li("t0", CFG_L1_LVL); a.sw("t0", 11 * 4, "s1")
a.addi("s2", "zero", 0)
a.addi("t2", "zero", 7)                           # testbench cho core ngu
a.word(WFI, "wfi")
a.word(NOP, "nop"); a.word(NOP, "nop")
a.label("WE"); a.beq("s2", "zero", "WE")
a.addi("t2", "zero", 8)                           # ---- PHA 6 XONG
a.label("DONE"); a.jal("zero", "DONE")

# =============================================================================
# Ham dich cho P9/P10 - moi ham mot word rieng
# =============================================================================
a.word(NOP, "nop  (tach ham)")
a.label("FUNC_OK");  a.jalr("zero", "ra", 0)
a.word(NOP, "nop  (tach ham)")
a.label("FUNC_NOX"); a.jalr("zero", "ra", 0)
a.word(NOP, "nop  (tach ham)")

# Ngoai le: mcause 1 -> quay ve ra (dich cam X), con lai -> mepc + 4
a.label("EXC")
a.csrr("t3", "mcause")
a.csrr("t4", "mtval")
a.addi("t5", "zero", 1)
a.bne("t3", "t5", "EXC_SKIP")
a.csrw("mepc", "ra")
a.word(MRET, "mret")
a.label("EXC_SKIP")
a.csrr("t6", "mepc"); a.addi("t6", "t6", 4); a.csrw("mepc", "t6")
a.word(MRET, "mret")

# =============================================================================
# Bang vector CLIC: o i = `j H_i`, o 0 (ngoai le) va o khong dung = `j EXC`
# =============================================================================
USED = (11, 12, 13, 14, 15, 30)
a.org(VTAB)
a.label("VTAB")
for i in range(32):
    a.jal("zero", "H%d" % i if i in USED else "EXC")

a.label("H30")
a.csrr("t3", "mcause"); a.csrr("t4", "mintstatus"); a.lw("t5", 30 * 4, "s1")
a.addi("gp", "gp", 1)
a.word(MRET, "mret")

a.label("H14")
a.slli("s11", "s11", 5); a.addi("s11", "s11", 14)
a.csrr("t5", "mepc"); a.csrr("t6", "mcause")
a.addi("a3", "t6", 0)
a.csrsi("mstatus", 8)                                   # cho phep long nhau
a.li("t0", CFG_L1_EDGE | 1); a.sw("t0", 13 * 4, "s1")   # cung muc: phai cho
a.li("t0", CFG_L7_EDGE | 1); a.sw("t0", 15 * 4, "s1")   # muc cao: preempt
a.label("W15"); a.beq("tp", "zero", "W15")
a.addi("t0", "zero", 40)
a.label("D14"); a.addi("t0", "t0", -1); a.bne("t0", "zero", "D14")
a.csrci("mstatus", 8)
a.csrw("mepc", "t5"); a.csrw("mcause", "t6")            # khoi phuc ca mpil
a.slli("s11", "s11", 5); a.addi("s11", "s11", 31)
a.word(MRET, "mret")

a.label("H15")
a.slli("s11", "s11", 5); a.addi("s11", "s11", 15)
a.csrr("s9", "mintstatus"); a.csrr("s10", "mcause")
a.addi("tp", "zero", 1)
a.word(MRET, "mret")

a.label("H13")
a.slli("s11", "s11", 5); a.addi("s11", "s11", 13)
a.addi("a1", "a1", 1)
a.word(MRET, "mret")

a.label("H12")
a.addi("a5", "a5", 1)
a.word(MRET, "mret")

a.label("H11")
a.addi("s2", "s2", 1)
a.word(MRET, "mret")

words, labels = a.assemble()

lines = [
    "// tb_irq_pmp.sv - PMP + CLIC bang CPU that (muc 6/7 review 2026-09-11).",
    "// SINH TU DONG boi gen_irq_pmp_mem.py - sua o do, khong sua tay file nay.",
    "// FUNC_NOX = 0x%08x (testbench kiem mtval cua loi lay lenh)" % labels["FUNC_NOX"],
]
for pc, w, text in words:
    lines.append("%08x  // %08x  %s" % (w, pc, text))

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "irq_pmp.mem")
with open(out, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
print("wrote %s (%d tu), FUNC_NOX=0x%08x" % (out, len(words), labels["FUNC_NOX"]))
