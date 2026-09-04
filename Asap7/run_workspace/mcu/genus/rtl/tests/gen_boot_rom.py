#!/usr/bin/env python3
"""Sinh boot_rom_image.vh tu mot file .mem, dung cho MO PHONG.

axi_rom.v `include "memory/boot_rom_image.vh"`.  Luong synthesis sinh file do tu
rtl/memory/boot.mem bang tcl/genus.tcl.  De chay mot firmware KHAC ma khong dung
den ban ROM vang, script nay ghi mot ban sao vao mot thu muc include rieng; chi
can dat thu muc do TRUOC rtl/ tren duong dan -i cua trinh bien dich la ban sim
se thang.

    python gen_boot_rom.py <input.mem> <sim_include_dir> [--depth 16384]

Thuat toan doc file .mem giu DUNG y het phan sinh trong tcl/genus.tcl: bo comment
`//` va `#`, `@xxxx` dat lai dia chi, moi token con lai la mot tu 32-bit.
"""
import argparse
import os
import re
import sys


def parse_mem(path, depth):
    entries, seen, addr = [], set(), 0
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = re.sub(r"#.*$", "", re.sub(r"//.*$", "", raw)).strip()
            if not line:
                continue
            for token in line.split():
                m = re.match(r"^@([0-9A-Fa-f]+)$", token)
                if m:
                    addr = int(m.group(1), 16)
                    continue
                word = token.replace("_", "")
                if not re.match(r"^[0-9A-Fa-f]{1,8}$", word):
                    sys.exit("%s:%d: khong phai tu 32-bit hop le: %r" % (path, lineno, token))
                if not 0 <= addr < depth:
                    sys.exit("%s:%d: dia chi %d nam ngoai do sau %d" % (path, lineno, addr, depth))
                if addr in seen:
                    sys.exit("%s:%d: dia chi %d bi ghi hai lan" % (path, lineno, addr))
                seen.add(addr)
                entries.append((addr, word.zfill(8)))
                addr += 1
    if not entries:
        sys.exit("%s: khong co tu du lieu nao" % path)
    return entries


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mem")
    ap.add_argument("out_dir", help="thu muc include cho sim; file se nam o <out_dir>/memory/")
    ap.add_argument("--depth", type=int, default=16384, help="MEM_DEPTH cua axi_rom (mac dinh 16384)")
    args = ap.parse_args()

    entries = parse_mem(args.mem, args.depth)
    out_dir = os.path.join(args.out_dir, "memory")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "boot_rom_image.vh")
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("// Sinh tu %s boi rtl/tests/gen_boot_rom.py - CHI DUNG DE MO PHONG.\n"
                 % os.path.basename(args.mem))
        for addr, word in entries:
            fh.write("                %d: rom_lookup = 32'h%s;\n" % (addr, word))
    print("%s: %d tu, dia chi cao nhat %d" % (out_path, len(entries), max(a for a, _ in entries)))


if __name__ == "__main__":
    main()
