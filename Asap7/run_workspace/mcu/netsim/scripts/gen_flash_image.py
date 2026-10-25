#!/usr/bin/env python3
"""Sinh hai anh QSPI flash cho tb_netsim.sv (make image).

Netlist chi chua boot ROM tang 1 (genus/rtl/memory/boot.mem, 26 lenh): ROM doc
header o 0x3000_0000; length = 0 thi nhay thang toi `entry` (XIP), con lai chep
payload toi `load` roi moi nhay.  Firmware Driver/ khong chay duoc tren netlist
(no duoc bake vao ROM o mo phong RTL va link cho dia chi ROM), nen netsim chay
chuong trinh nho duoi day, ma hoa tay vi may nay khong co toolchain RISC-V.

Chuong trinh (doc lap vi tri: dia chi MSG lay bang auipc):
  1. UART0 CLK_DIV = 0x0010_0008 (TX 8 chu ky clk / bit, khop UART_DIV trong tb)
  2. chep MSG (cong data) sang RAM hi 0x2002_0000 - vung uncached, tuc ghi/doc
     thang macro SRAM, khong qua D-cache - roi `fence` de store buffer xa het
     truoc khi doc lai (ket qua khong phu thuoc forward)
  3. doc lai tung byte tu RAM hi (lbu), cho TX_FULL = 0, ghi TX_DATA
  4. j .

Hai anh, cung mot chuong trinh, chi khac header:
  tb/netsim_flash.hex       XIP: chay tai cho o 0x3000_0010 qua I-cache, MSG doc
                            qua D-cache.  Anh mac dinh cua netsim - kiem netlist.
                            Duong da di qua: I-cache (ROM + flash), D-cache (flash),
                            AXI -> SRAM, APB -> UART, pinmux PA0.
  tb/netsim_flash_itcm.hex  chep vao ITCM 0x0002_0000 roi chay o do.  Doi chung
                            cua erratum E1 (MEMORY_ARCHITECTURE.md muc 3): cong
                            fetch ITCM tra lenh cu sau khi PC doi huong, nen tren
                            RTL/netlist hien tai anh nay FAIL voi byte 0 = 0x49 'I'
                            (make rtl 2026-10-25).  Sau khi sua tcm.v no phai PASS:
                                make rtl NS_FLASH_IMAGE=tb/netsim_flash_itcm.hex

    python3 scripts/gen_flash_image.py            # ghi ca hai file
"""
import os

ZERO, T0, T1, T2, S0 = 0, 5, 6, 7, 8
A0, A1, A2 = 10, 11, 12

MAGIC = 0x4255434D          # "MCUB", xem MEMORY_ARCHITECTURE.md muc 6
FLASH = 0x3000_0000
HEADER_BYTES = 16
ITCM = 0x0002_0000
UART0 = 0x4000_0000         # 0x00 CLK_DIV, 0x04 TX_DATA, 0x0C STATUS ([2] TX_FULL)
RAM_HI = 0x2002_0000        # SOC_IS_UNCACHED trong top_soc.v
UART_CLK_DIV = 0x0010_0008  # [31:16] RX_DIV, [15:0] TX_DIV
MSG = b"NETSIM OK\n"        # tb_netsim.sv: EXPECT


def lui(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0x37


def auipc(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0x17


def i_type(funct3, opcode, rd, rs1, imm):
    assert -2048 <= imm < 2048, imm
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def addi(rd, rs1, imm):
    return i_type(0, 0x13, rd, rs1, imm)


def andi(rd, rs1, imm):
    return i_type(7, 0x13, rd, rs1, imm)


def lw(rd, off, rs1):
    return i_type(2, 0x03, rd, rs1, off)


def lbu(rd, off, rs1):
    return i_type(4, 0x03, rd, rs1, off)


def sw(rs2, off, rs1):
    return (((off >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | ((off & 0x1F) << 7) | 0x23


def branch(funct3, rs1, rs2, off):
    assert off % 2 == 0 and -4096 <= off < 4096, off
    return ((((off >> 12) & 1) << 31) | (((off >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) |
            (funct3 << 12) | (((off >> 1) & 0xF) << 8) | (((off >> 11) & 1) << 7) | 0x63)


def bne(rs1, rs2, off):
    return branch(1, rs1, rs2, off)


def blt(rs1, rs2, off):
    return branch(4, rs1, rs2, off)


JAL_SELF = 0x0000006F       # jal zero, 0
FENCE = 0x0FF0000F          # fence iorw, iorw (nhu boot.mem)

# Doi chieu voi ma da chay that trong genus/rtl/memory/boot.mem.
assert auipc(T0, 0) == 0x00000297
assert lui(S0, 0x30000) == 0x30000437
assert lw(T1, 0, S0) == 0x00042303
assert addi(13, S0, 16) == 0x01040693
assert sw(28, 0, A1) == 0x01C5A023
assert bne(T1, T2, 0x38) == 0x02731C63
assert blt(ZERO, A2, -0x14) == 0xFEC046E3

# ---------------------------------------------------------------------------
# Hop ngu toi gian: moi muc la ham pc -> word, nhan tinh truoc khi ma hoa.
prog, labels = [], {}


def label(name):
    labels[name] = 4 * len(prog)


def emit(fn, text):
    prog.append((fn, text))


msg_words = (len(MSG) + 3) // 4

emit(lambda pc: lui(S0, UART0 >> 12),               "lui  s0, %hi(UART0)")
emit(lambda pc: lui(T0, UART_CLK_DIV >> 12),        "lui  t0, 0x00100")
emit(lambda pc: addi(T0, T0, UART_CLK_DIV & 0xFFF), "addi t0, t0, 8          CLK_DIV = 0x0010_0008")
emit(lambda pc: sw(T0, 0x00, S0),                   "sw   t0, 0(s0)")
label("here")
emit(lambda pc: auipc(A0, 0),                       "auipc a0, 0")
emit(lambda pc: addi(A0, A0, labels["msg"] - labels["here"]), "addi a0, a0, msg-here   a0 = &MSG")
emit(lambda pc: lui(A1, RAM_HI >> 12),              "lui  a1, %hi(RAM_HI)")
emit(lambda pc: addi(A2, ZERO, msg_words),          "addi a2, zero, %d" % msg_words)
label("copy")
emit(lambda pc: lw(T1, 0, A0),                      "lw   t1, 0(a0)          doc MSG qua cong data")
emit(lambda pc: sw(T1, 0, A1),                      "sw   t1, 0(a1)          ghi macro SRAM")
emit(lambda pc: addi(A0, A0, 4),                    "addi a0, a0, 4")
emit(lambda pc: addi(A1, A1, 4),                    "addi a1, a1, 4")
emit(lambda pc: addi(A2, A2, -1),                   "addi a2, a2, -1")
emit(lambda pc: bne(A2, ZERO, labels["copy"] - pc), "bne  a2, zero, copy")
emit(lambda pc: FENCE,                              "fence                   xa store buffer")
emit(lambda pc: lui(A1, RAM_HI >> 12),              "lui  a1, %hi(RAM_HI)")
emit(lambda pc: addi(A2, ZERO, len(MSG)),           "addi a2, zero, %d" % len(MSG))
label("send")
emit(lambda pc: lbu(T1, 0, A1),                     "lbu  t1, 0(a1)          doc lai tu macro SRAM")
label("wait")
emit(lambda pc: lw(T2, 0x0C, S0),                   "lw   t2, 12(s0)         UART0 STATUS")
emit(lambda pc: andi(T2, T2, 4),                    "andi t2, t2, 4          TX_FULL")
emit(lambda pc: bne(T2, ZERO, labels["wait"] - pc), "bne  t2, zero, wait")
emit(lambda pc: sw(T1, 0x04, S0),                   "sw   t1, 4(s0)          TX_DATA")
emit(lambda pc: addi(A1, A1, 1),                    "addi a1, a1, 1")
emit(lambda pc: addi(A2, A2, -1),                   "addi a2, a2, -1")
emit(lambda pc: bne(A2, ZERO, labels["send"] - pc), "bne  a2, zero, send")
emit(lambda pc: JAL_SELF,                           "j    .")
label("msg")
msg_padded = MSG + b"\0" * (4 * msg_words - len(MSG))
for i in range(msg_words):
    chunk = msg_padded[4 * i:4 * i + 4]
    emit(lambda pc, w=int.from_bytes(chunk, "little"): w, "MSG %r" % chunk)

payload = [(fn(4 * i), text) for i, (fn, text) in enumerate(prog)]
payload_bytes = 4 * len(payload)

# (file, tieu de, header, dia chi chay cua payload)
IMAGES = [
    ("netsim_flash.hex", "XIP: chay tai cho trong flash qua I-cache", [
        (MAGIC, "magic  'MCUB'"),
        (FLASH + HEADER_BYTES, "entry  flash + 16 (payload)"),
        (0, "load   (bo qua khi length = 0)"),
        (0, "length 0 = XIP"),
    ], FLASH + HEADER_BYTES),
    ("netsim_flash_itcm.hex", "chep vao ITCM - doi chung erratum E1, hien FAIL 'I'", [
        (MAGIC, "magic  'MCUB'"),
        (ITCM, "entry  ITCM"),
        (ITCM, "load   ITCM"),
        (payload_bytes, "length %d byte" % payload_bytes),
    ], ITCM),
]


def write_image(out, title, header, run_base):
    with open(out, "w", newline="\n") as f:
        f.write("// Sinh boi scripts/gen_flash_image.py - KHONG sua tay.\n")
        f.write("// Anh QSPI flash cho tb_netsim.sv: 4 byte / dong (little-endian), tu dia chi 0.\n")
        f.write("// %s\n" % title)
        f.write("@0\n")
        addr = 0
        for section, words in (("header ", header), ("payload", payload)):
            for word, text in words:
                where = "%08x" % (FLASH + addr)
                if section == "payload" and run_base != FLASH + HEADER_BYTES:
                    where += " chay %08x" % (run_base + addr - HEADER_BYTES)
                elif section == "payload":
                    where += " (XIP)        "
                else:
                    where += "              "
                f.write("%02x %02x %02x %02x  // %s %08x  %s\n" % (
                    word & 0xFF, (word >> 8) & 0xFF, (word >> 16) & 0xFF, (word >> 24) & 0xFF,
                    where, word, text))
                addr += 4
    print("%s: %d byte (header %d + payload %d)" % (out, addr, HEADER_BYTES, payload_bytes))


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    for name, title, header, run_base in IMAGES:
        out = os.path.normpath(os.path.join(here, "..", "tb", name))
        write_image(out, title, header, run_base)


if __name__ == "__main__":
    main()
