#!/usr/bin/env python3
"""Sinh LEF 1x cho flow Innovus MCU_SCALE=1 tu nhung file 4x da chay sach.

Hai viec, hai lenh con:

  tech  Tech LEF 1x goc cua ASAP7 (asap7_tech_1x_201209.lef) mang DUNG nhung
        loi ma ban 4x trong repo da sua tay (Asap7/asap7/asap7sc7p5t_28/
        techlef_misc/asap7_tech_4x_201209.lef).  Moi sua deu kiem "khop dung
        mot lan" - file goc doi thi script dung chu khong ghi file nua voi.

  sram  LEF SRAM 1x = LEF SRAM 4x da chay sach DRC chia 4 (RECT/SIZE/ORIGIN/
        FOREIGN).  Ban 4x nam tren luoi 0.004 nen chia 4 ra dung luoi 0.001,
        khong lam tron gi.  Khong dung fix_sram_lef.py tren LEF 1x goc: ban goc
        256x4x32 co 64 wd/64 dataout/5 sdel, ban 4x cua repo (commit d1232874)
        da sua con 32/32/0 - snap lai tu ban goc la ra mot hinh KHAC voi hinh
        da route sach.

  python3 make_1x_lef.py tech <asap7_tech_1x_201209.lef> -o <...>.fixed.lef
  python3 make_1x_lef.py sram <m>.lef.4x.lef -o <m>.fixed.lef [--ref <m>.lef 1x goc]
"""

import argparse
import re
import sys
from decimal import Decimal

# ---------------------------------------------------------------------------
# tech
# ---------------------------------------------------------------------------
# (ten, regex tren file goc, thay the).  So 1x = so 4x / 4.
# thay the = None: comment khoi LEF58_ENCLOSURE (xem comment_block).
TECH_FIXES = [
    ("OVERLAP",
     r"#LAYER OVERLAP\n#  TYPE OVERLAP ;\n#END OVERLAP\n",
     "LAYER OVERLAP\n  TYPE OVERLAP ;\nEND OVERLAP\n"),
    # Ban 4x: TAT LEF58_ENCLOSURE o V3, V4, V5.  Bat o V3/V4 thi addStripe M5
    # std cell (KHOI 10) chi tao 3/8 via M1->M5 - 4562 loi verifyConnectivity
    # (run 2026-09-17 22:13).  V5: cut hinh chu nhat, mot luat chung khong
    # dung duoc cho ca M5 lan M6 -> 14691 VIAENCLOSURE V5 (run 2026-09-17 23:55).
    ("V3 LEF58_ENCLOSURE",
     r"(LAYER V3\n(?:(?!END V3).*\n)*?) PROPERTY LEF58_ENCLOSURE \"\n((?: ENCLOSURE[^\n]*\n)+) \" ;\n",
     None),
    ("V4 LEF58_ENCLOSURE",
     r"(LAYER V4\n(?:(?!END V4).*\n)*?) PROPERTY LEF58_ENCLOSURE \"\n((?: ENCLOSURE[^\n]*\n)+) \" ;\n",
     None),
    ("V5 LEF58_ENCLOSURE",
     r"(LAYER V5\n(?:(?!END V5).*\n)*?) PROPERTY LEF58_ENCLOSURE \"\n((?: ENCLOSURE[^\n]*\n)+) \" ;\n",
     None),
    # Ban 4x: V6 spacing 0.136 -> 0.180
    ("V6 DEFAULT spacing",
     r"(LAYER V6\n(?:(?!END V6).*\n)*? DEFAULT )0\.034\n",
     r"\g<1>0.045\n"),
    # Ban 4x: M7 EOL spacing 0.120 -> 0.128 (= M6)
    ("M7 EOL spacing",
     r"(LAYER M7\n(?:(?!END M7).*\n)*? PROPERTY LEF58_SPACING\n \" SPACING )0\.03( ENDOFLINE)",
     r"\g<1>0.032\2"),
    # Ban 4x: Pad pitch 0.32 -> 8.96.  Smoke 1x 2026-09-25 bao IMPTR-2101 dung
    # layer nay ("M10: Pitch ... still less than min width + min spacing"):
    # pitch 0.08 < width 0.04 + spacing 2.0 cua chinh no.
    ("Pad pitch",
     r"(LAYER Pad\n(?:(?!END Pad).*\n)*? PITCH )0\.08 0\.08 ;",
     r"\g<1>2.24 2.24 ;"),
]


def comment_block(m):
    block = ' PROPERTY LEF58_ENCLOSURE "\n' + m.group(2) + ' " ;'
    return (m.group(1)
            + "  # TAT nhu ban 4x repo (asap7_tech_4x_201209.lef) - xem make_1x_lef.py.\n"
            + "".join("#" + line + "\n" for line in block.split("\n")))


def do_tech(args):
    text = open(args.lef, encoding="latin-1").read().replace("\r\n", "\n")
    if "DATABASE MICRONS 1000" not in text or "MANUFACTURINGGRID 0.001" not in text:
        sys.exit("khong phai tech LEF 1x (can DATABASE MICRONS 1000, MANUFACTURINGGRID 0.001)")
    for name, pattern, repl in TECH_FIXES:
        rx = re.compile(pattern)
        hits = len(rx.findall(text))
        if hits != 1:
            sys.exit("sua '%s': khop %d lan, can dung 1 - file goc khac ban @f970bd3" %
                     (name, hits))
        text = rx.sub(comment_block if repl is None else repl, text, count=1)
        print("  da sua: %s" % name)
    header = ("# SINH BOI run_workspace/mcu/innovus/scripts/make_1x_lef.py tech - KHONG sua tay.\n"
              "# Nguon: asap7sc7p5t_28 @f970bd3 techlef_misc/asap7_tech_1x_201209.lef\n"
              "# + cac sua cua ban 4x trong repo (x 1/4).  Mat do M5/Pad cua ban 1x\n"
              "# da la phan tram (15/90, 20/80) nen khong can sua nhu ban 4x.\n")
    with open(args.out, "w", newline="\n") as f:
        f.write(header + text)
    print("ghi %s" % args.out)


# ---------------------------------------------------------------------------
# sram
# ---------------------------------------------------------------------------
GEOMETRY_KEYWORDS = ("RECT", "SIZE", "ORIGIN", "FOREIGN")
NUMBER_RE = re.compile(r"-?\d+\.\d+|-?\d+")
GRID = Decimal("0.001")
FACTOR = Decimal(4)


def fmt(d):
    return format(d.normalize(), "f")


def scale_line(line):
    stripped = line.lstrip()
    word = stripped.split(" ", 1)[0] if stripped else ""
    if word not in GEOMETRY_KEYWORDS:
        return line, 0
    offgrid = 0

    def repl(m):
        nonlocal offgrid
        v = Decimal(m.group(0)) / FACTOR
        if v % GRID != 0:
            offgrid += 1
        return fmt(v)

    indent = line[:len(line) - len(stripped)]
    if word == "FOREIGN":
        # FOREIGN <ten> x y ; - ten macro co chu so (256x4x32), chi doi phan sau ten
        head, name, rest = stripped.split(" ", 2)
        return indent + head + " " + name + " " + NUMBER_RE.sub(repl, rest), offgrid
    return indent + NUMBER_RE.sub(repl, stripped), offgrid


def rects(text):
    out = []
    for line in text.split("\n"):
        s = line.strip()
        if s.startswith("RECT"):
            out.append(tuple(Decimal(x) for x in NUMBER_RE.findall(s)))
    return out


def do_sram(args):
    src = open(args.lef, encoding="latin-1").read().replace("\r\n", "\n")
    out_lines = []
    offgrid = 0
    for line in src.split("\n"):
        new, n = scale_line(line)
        offgrid += n
        out_lines.append(new)
    if offgrid:
        sys.exit("%d toa do sau khi chia 4 khong nam tren luoi 0.001 - ban 4x chua sach"
                 " (chay fix_sram_lef.py --fix truoc)" % offgrid)
    text = "\n".join(out_lines)
    m = re.search(r"SIZE\s+(\S+)\s+BY\s+(\S+)", text)
    print("  SIZE %s BY %s" % (m.group(1), m.group(2)))

    if args.ref:
        ref = open(args.ref, encoding="latin-1").read().replace("\r\n", "\n")
        a, b = rects(text), rects(ref)
        print("  RECT: ban suy ra %d, ban 1x goc %d" % (len(a), len(b)))
        if len(a) == len(b):
            diffs = [abs(x - y) for ra, rb in zip(a, b) for x, y in zip(ra, rb)]
            moved = sum(1 for ra, rb in zip(a, b) if ra != rb)
            print("  so tung RECT: %d RECT khac, lech lon nhat %s um" %
                  (moved, max(diffs, default=Decimal(0))))
        else:
            print("  so RECT khac nhau - ban 4x cua repo da doi cau truc so voi ban goc,"
                  " khong so tung dong")

    name = args.lef.replace("\\", "/").split("/")[-1]
    header = ("# SINH BOI run_workspace/mcu/innovus/scripts/make_1x_lef.py sram - KHONG sua tay.\n"
              "# = %s chia 4 (ban 4x da chay sach DRC).\n" % name)
    with open(args.out, "w", newline="\n") as f:
        f.write(header + text)
    print("ghi %s" % args.out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("tech")
    t.add_argument("lef")
    t.add_argument("-o", "--out", required=True)
    s = sub.add_parser("sram")
    s.add_argument("lef")
    s.add_argument("-o", "--out", required=True)
    s.add_argument("--ref", help="LEF 1x goc cua ASU de so sanh")
    args = ap.parse_args()
    {"tech": do_tech, "sram": do_sram}[args.cmd](args)


if __name__ == "__main__":
    main()
