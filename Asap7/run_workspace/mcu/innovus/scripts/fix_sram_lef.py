#!/usr/bin/env python3
"""Sua LEF macro SRAM ASAP7 4x: snap toa do ve manufacturing grid va sua SITE.

Run Innovus 2026-09-18 bao 3908 loi ngay o init_design, tat ca tu mot file:
  IMPLF-82 x3907  srambank_128x4x20_6t122: toa do pin VDD (0.8660, 5.5060, ...)
                  lech 0.002 um = nua MANUFACTURINGGRID 0.004
  IMPLF-40 x1     macro tham chieu SITE 'coreSite' khong duoc dinh nghia
Keo theo IMPSR-552 luc sroute ("MACRO OBS or MACRO PIN is not on the
manufacturing grid") va IMPPP-133 (OBS V3 nam ngoai boundary macro).

LEF nay la nguon DUY NHAT cua hinh SRAM khi streamOut -outputMacros (ASAP7
khong co GDS rieng cho tung macro SRAM), nen toa do lech grid se di thang vao
GDS o KHOI 16.

  python3 fix_sram_lef.py srambank_128x4x20_6t122.lef.4x.lef
  python3 fix_sram_lef.py srambank_128x4x20_6t122.lef.4x.lef \\
      --fix -o srambank_128x4x20_6t122.lef.4x.fixed.lef --site coreSite=asap7sc7p5t

Khong co --fix thi chi doc va bao cao, khong ghi gi.
"""

import argparse
import collections
import decimal
import re
import sys

from decimal import Decimal

# Lenh LEF mang toa do.  Chi snap so tren nhung dong nay - khong dong vao
# VERSION, DATABASE MICRONS, MINIMUMDENSITY, RESISTANCE...
GEOMETRY_KEYWORDS = ("RECT", "POLYGON", "PATH", "ORIGIN", "SIZE", "FOREIGN")

NUMBER_RE = re.compile(r"-?\d+\.\d+|-?\d+")

# PHAI tinh bang Decimal, khong duoc dung float.  LEF 128x4x20 co 3903 toa do
# lech DUNG nua grid (2 nm tren grid 4 nm), va trong so thuc 0.086/0.004 ra
# 21.499999999999996 chu khong phai 21.5 -> floor(q+0.5) lam tron XUONG cho
# nhung toa do do va LEN cho nhung toa do khac.  Hai canh cua cung mot hinh di
# hai huong khac nhau thi hinh doi kich thuoc.  Decimal chia chinh xac nen
# 'nua grid' luon duoc xu ly nhat quan (ROUND_HALF_UP).
HALF = Decimal("0.5")


def snap(value, grid, mode):
    """Dua mot toa do ve boi so cua grid.  value/grid tinh bang Decimal."""
    q = value / grid
    if mode == "nearest":
        # floor(q + 1/2) tinh chinh xac.  KHONG dung ROUND_HALF_UP: no lam tron
        # 'ra xa so 0', nen toa do am nam dung nua grid se di NGUOC huong voi
        # toa do duong.  Cach nay cho moi truong hop hoa (nua grid) di cung mot
        # huong, bat ke dau -> ca 3903 toa do +2.000 nm dich deu, hinh giu nguyen
        # kich thuoc.
        n = (q + HALF).to_integral_value(rounding=decimal.ROUND_FLOOR)
    elif mode == "down":
        n = q.to_integral_value(rounding=decimal.ROUND_FLOOR)
    elif mode == "up":
        n = q.to_integral_value(rounding=decimal.ROUND_CEILING)
    else:
        raise ValueError(mode)
    return n * grid


def is_on_grid(value, grid):
    return value % grid == 0


def fmt(value, decimals):
    """Ghi lai so voi dung so chu so thap phan cua so goc (diff de doc)."""
    quantum = Decimal(1).scaleb(-decimals)
    text = str(value.quantize(quantum, rounding=decimal.ROUND_HALF_UP))
    return "0" if text.lstrip("-").strip("0.") == "" and text.startswith("-") else text


def process(lines, grid, mode, site_map, drop_site):
    out = []
    # so chu so thap phan toi thieu de ghi duoc mot boi so cua grid
    grid_decimals = max(0, -grid.normalize().as_tuple().exponent)
    stats = collections.Counter()
    residuals = collections.Counter()
    offenders = collections.Counter()   # (macro, context) -> so toa do lech
    resized = []                        # RECT bi doi kich thuoc sau khi snap
    macro = "<top>"
    context = "<none>"

    for raw in lines:
        line = raw.rstrip("\n")
        stripped = line.strip()
        upper = stripped.upper()

        if upper.startswith("MACRO "):
            macro = stripped.split()[1]
            context = "<none>"
        elif upper.startswith("PIN "):
            context = "PIN " + stripped.split()[1]
        elif upper.startswith("OBS"):
            context = "OBS"
        elif upper.startswith("END ") and context.startswith("PIN"):
            context = "<none>"

        # --- SITE -----------------------------------------------------------
        if upper.startswith("SITE "):
            name = stripped.split()[1].rstrip(";").strip()
            if drop_site:
                stats["site_removed"] += 1
                out.append("# %s   # bo boi fix_sram_lef.py: MACRO CLASS BLOCK"
                           " khong bat buoc co SITE\n" % line)
                continue
            if name in site_map:
                stats["site_renamed"] += 1
                out.append(line.replace(name, site_map[name], 1) + "\n")
                continue
            stats["site_kept"] += 1
            stats["site_kept_name_" + name] += 1
            out.append(raw)
            continue

        # --- toa do ---------------------------------------------------------
        if not any(upper.startswith(k) for k in GEOMETRY_KEYWORDS):
            out.append(raw)
            continue

        changed = [False]

        # Mode 'grow': canh duoi/trai lam tron XUONG, canh tren/phai lam tron LEN
        # -> hinh chi no ra, khong bao gio co lai.  Dung khi co hinh rong dung
        # min width: co lai 1 grid la thanh loi min-width that.  Chi ap dung cho
        # RECT 4 so; cac lenh hinh hoc khac quay ve 'nearest'.
        per_coord_mode = None
        if mode == "grow":
            nums = [t for t in NUMBER_RE.findall(stripped) if "." in t]
            if upper.startswith("RECT") and len(nums) == 4:
                x1, y1, x2, y2 = (Decimal(t) for t in nums)
                per_coord_mode = ["down" if x1 <= x2 else "up",
                                  "down" if y1 <= y2 else "up",
                                  "up" if x1 <= x2 else "down",
                                  "up" if y1 <= y2 else "down"]
            else:
                per_coord_mode = None
        seen = [0]

        def repl(m):
            text = m.group(0)
            if "." not in text:          # BY / so nguyen trong FOREIGN: bo qua
                return text
            value = Decimal(text)
            stats["coords_seen"] += 1
            idx = seen[0]
            seen[0] += 1
            if is_on_grid(value, grid):
                return text
            stats["coords_offgrid"] += 1
            offenders[(macro, context)] += 1
            # do lech so voi diem grid ngay duoi, tinh bang nm cho de doc
            residuals[float((value - snap(value, grid, "down")) * 1000)] += 1
            if per_coord_mode is not None:
                this_mode = per_coord_mode[idx]
            elif mode == "grow":
                this_mode = "nearest"
            else:
                this_mode = mode
            new = snap(value, grid, this_mode)
            if abs(new - value) > grid:            # khong bao gio nhay qua 1 grid
                return text
            changed[0] = True
            stats["coords_fixed"] += 1
            # Giu so chu so thap phan cua so goc cho diff de doc, nhung KHONG
            # duoc it hon so chu so ma grid can: 'RECT 0.01 ...' voi grid 0.004
            # ma ghi lai 2 chu so thi 0.012 bi lam tron ve dung 0.01 cu.
            return fmt(new, max(len(text.split(".")[1]), grid_decimals))

        new_line = NUMBER_RE.sub(repl, line)
        if changed[0]:
            stats["lines_fixed"] += 1
            # Cau hoi quan trong nhat: hinh co doi KICH THUOC khong?  Hai canh
            # cua mot RECT lech khac nhau thi sau khi snap chung dich khac nhau.
            if upper.startswith("RECT"):
                old_n = [Decimal(t) for t in NUMBER_RE.findall(line) if "." in t]
                new_n = [Decimal(t) for t in NUMBER_RE.findall(new_line) if "." in t]
                if len(old_n) == 4 and len(new_n) == 4:
                    old_wh = (old_n[2] - old_n[0], old_n[3] - old_n[1])
                    new_wh = (new_n[2] - new_n[0], new_n[3] - new_n[1])
                    if old_wh != new_wh:
                        stats["rect_resized"] += 1
                        resized.append((macro, context, old_wh, new_wh,
                                        stripped, new_line.strip()))
                    else:
                        stats["rect_moved_only"] += 1
        out.append(new_line + "\n")

    # Tu kiem tra lai ket qua: moi toa do trong file ghi ra phai nam tren grid.
    # Bat duoc truong hop fmt() lam tron nguoc ve vi tri cu khi so goc it chu so
    # thap phan hon grid (vd grid 0.004 can 3 chu so, so goc chi co 2).
    for text_line in out:
        s2 = text_line.strip()
        if not any(s2.upper().startswith(k) for k in GEOMETRY_KEYWORDS):
            continue
        for t in NUMBER_RE.findall(s2):
            if "." in t and not is_on_grid(Decimal(t), grid):
                stats["still_offgrid"] += 1

    return out, stats, residuals, offenders, resized


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("lef", help="file LEF macro can kiem tra / sua")
    ap.add_argument("--fix", action="store_true",
                    help="ghi file da sua (can -o).  Khong co thi chi bao cao.")
    ap.add_argument("-o", "--out", help="file LEF ket qua")
    ap.add_argument("--grid", type=Decimal, default=Decimal("0.004"),
                    help="MANUFACTURINGGRID, um (mac dinh 0.004 = tech LEF 4x)")
    ap.add_argument("--mode", choices=("nearest", "down", "up", "grow"),
                    default="nearest",
                    help="huong snap.  nearest: gan nhat (mac dinh).  down/up:"
                         " dich moi toa do cung mot huong.  grow: canh duoi/trai"
                         " lam tron xuong, canh tren/phai lam tron len - hinh chi"
                         " no ra, khong bao gio co lai (dung khi co hinh rong"
                         " dung min width).")
    ap.add_argument("--site", action="append", default=[], metavar="OLD=NEW|NEW",
                    help="doi ten SITE: 'coreSite=asap7sc7p5t', hoac chi NEW de"
                         " doi moi SITE gap duoc sang NEW")
    ap.add_argument("--drop-site", action="store_true",
                    help="bo han dong SITE (MACRO CLASS BLOCK khong can SITE)")
    ap.add_argument("--show-resize", type=int, default=0, metavar="N",
                    help="in nguyen van N dong RECT bi doi kich thuoc, ca ban goc"
                         " lan ban da sua - de xem tan mat chuyen gi xay ra")
    args = ap.parse_args(argv)

    site_map = {}
    fallback_site = None
    for item in args.site:
        if "=" in item:
            old, new = item.split("=", 1)
            site_map[old.strip()] = new.strip()
        else:
            fallback_site = item.strip()

    with open(args.lef, "r", errors="replace") as fh:
        lines = fh.readlines()

    if fallback_site:
        for line in lines:
            s = line.strip()
            if s.upper().startswith("SITE "):
                site_map.setdefault(s.split()[1].rstrip(";").strip(),
                                    fallback_site)

    out, stats, residuals, offenders, resized = process(
        lines, args.grid, args.mode, site_map, args.drop_site)

    print("file        : %s" % args.lef)
    print("grid        : %s um   mode: %s" % (args.grid, args.mode))
    print("toa do doc  : %d" % stats["coords_seen"])
    print("lech grid   : %d" % stats["coords_offgrid"])
    print("da snap     : %d  (tren %d dong)"
          % (stats["coords_fixed"], stats["lines_fixed"]))
    if stats["site_renamed"]:
        print("SITE doi ten: %d   %s" % (stats["site_renamed"], site_map))
    if stats["site_removed"]:
        print("SITE bo     : %d" % stats["site_removed"])
    if stats["site_kept"]:
        names = sorted(k[len("site_kept_name_"):] for k in stats
                       if k.startswith("site_kept_name_"))
        print("SITE giu    : %d  %s" % (stats["site_kept"], names))
        if not stats["site_renamed"]:
            print("              -> neu ten nay khong co trong LEF std cell thi"
                  " day chinh la IMPLF-40;")
            print("                 dung --site OLD=NEW hoac --drop-site.")

    if residuals:
        print("\nphan bo do lech (nm, so voi diem grid ngay duoi):")
        for res, count in sorted(residuals.items()):
            print("  %+8.3f nm : %d" % (res, count))

    # Day moi la cau tra loi cho "snap co lam hong hinh khong".
    print("")
    print("RECT sau khi snap:")
    print("  chi dich cho, giu nguyen kich thuoc : %d" % stats["rect_moved_only"])
    print("  DOI kich thuoc                      : %d" % stats["rect_resized"])
    if resized:
        dw = [new_wh[0] - old_wh[0] for _m, _c, old_wh, new_wh, _o, _n in resized]
        dh = [new_wh[1] - old_wh[1] for _m, _c, old_wh, new_wh, _o, _n in resized]
        n_w = sum(1 for d in dw if d != 0)
        n_h = sum(1 for d in dh if d != 0)
        print("  trong do doi be ngang X : %d  (lon nhat %s um)"
              % (n_w, max([abs(d) for d in dw]) if dw else 0))
        print("           doi be doc   Y : %d  (lon nhat %s um)"
              % (n_h, max([abs(d) for d in dh]) if dh else 0))

        # Hinh doi be ngang X thuong it, ma lai la cho nguy hiem nhat: mot hinh
        # rong dung min width ma co lai 1 grid la thanh loi min-width that.
        # In HET ra, kem dong LEF nguyen van, de xem tan mat.
        narrow = [r for r in resized if r[3][0] != r[2][0]]
        if narrow:
            print("")
            print("  %d hinh doi BE NGANG X - xem ky tung cai:" % len(narrow))
            for macro_name, ctx, old_wh, new_wh, old_line, new_line in narrow[:40]:
                delta = new_wh[0] - old_wh[0]
                print("    %s / %s   be ngang %s -> %s  (%s%s um)"
                      % (macro_name, ctx, old_wh[0], new_wh[0],
                         "+" if delta > 0 else "", delta))
                print("      cu  : %s" % old_line)
                print("      moi : %s" % new_line)
            if len(narrow) > 40:
                print("    ... con %d hinh nua" % (len(narrow) - 40))
            print("")
        print("  (kich thuoc cu -> moi, um)")
        for macro_name, ctx, old_wh, new_wh, _o, _n in resized[:20]:
            print("    %-26s %-16s %s x %s  ->  %s x %s"
                  % (macro_name, ctx, old_wh[0], old_wh[1], new_wh[0], new_wh[1]))
        if len(resized) > 20:
            print("    ... con %d hinh nua" % (len(resized) - 20))
        print("  -> xem lai nhung hinh nay. Doi 1 grid tren OBS hoac chan nguon")
        print("     thuong vo hai; doi tren chan tin hieu hep thi phai kiem tra ky.")
        print("     Them --show-resize N de xem N dong LEF goc va dong sau khi sua.")
    else:
        print("  -> khong hinh nao doi kich thuoc: snap an toan.")

    if args.show_resize:
        print("")
        print("%d dong RECT doi kich thuoc (nguyen van):"
              % min(args.show_resize, len(resized)))
        for macro_name, ctx, old_wh, new_wh, old_line, new_line in \
                resized[:args.show_resize]:
            print("  %s / %s" % (macro_name, ctx))
            print("    cu  : %s" % old_line)
            print("    moi : %s" % new_line)
            print("    kich thuoc %s x %s -> %s x %s"
                  % (old_wh[0], old_wh[1], new_wh[0], new_wh[1]))

    if stats["still_offgrid"]:
        print("")
        print("CANH BAO: sau khi sua van con %d toa do NGOAI grid."
              % stats["still_offgrid"])
        print("  Thuong la do so goc it chu so thap phan hon grid can.")
        print("  Bao lai cho nguoi viet script - dung file ket qua nay.")

    if offenders:
        print("\nnoi lech nhieu nhat:")
        for (macro_name, ctx), count in offenders.most_common(15):
            print("  %-32s %-22s %d" % (macro_name, ctx, count))

    if args.fix:
        if not args.out:
            ap.error("--fix can -o <file ket qua>")
        with open(args.out, "w", newline="\n") as fh:
            fh.writelines(out)
        print("\nda ghi: %s" % args.out)
        print("Tiep theo: tro SRAM_TAG_LEF (hoac SRAM_LEF) trong")
        print("  genus/rtl/flow/project_config.tcl sang file nay,")
        print("  hoac dat bien moi truong ASAP7_SRAM_TAG_LEF_FILE, roi chay lai KHOI 0.")
    elif stats["coords_offgrid"] or stats["site_kept"]:
        print("\n(chi kiem tra - them --fix -o <file> de ghi ban da sua)")

    return 1 if (stats["coords_offgrid"] and not args.fix) else 0


if __name__ == "__main__":
    sys.exit(main())
