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
import math
import re
import sys

# Lenh LEF mang toa do.  Chi snap so tren nhung dong nay - khong dong vao
# VERSION, DATABASE MICRONS, MINIMUMDENSITY, RESISTANCE...
GEOMETRY_KEYWORDS = ("RECT", "POLYGON", "PATH", "ORIGIN", "SIZE", "FOREIGN")

NUMBER_RE = re.compile(r"-?\d+\.\d+|-?\d+")


def snap(value, grid, mode):
    """Dua mot toa do ve boi so cua grid."""
    q = value / grid
    if mode == "nearest":
        n = math.floor(q + 0.5)
    elif mode == "down":
        n = math.floor(q)
    elif mode == "up":
        n = math.ceil(q)
    else:
        raise ValueError(mode)
    return n * grid


def is_on_grid(value, grid):
    q = value / grid
    return abs(q - round(q)) < 1e-6


def fmt(value, decimals):
    """Ghi lai so voi dung so chu so thap phan cua so goc (diff de doc)."""
    text = "%.*f" % (decimals, value)
    return "0" if text.lstrip("-").strip("0.") == "" and text.startswith("-") else text


def process(lines, grid, mode, site_map, drop_site):
    out = []
    stats = collections.Counter()
    residuals = collections.Counter()
    offenders = collections.Counter()   # (macro, context) -> so toa do lech
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

        def repl(m):
            text = m.group(0)
            if "." not in text:          # BY / so nguyen trong FOREIGN: bo qua
                return text
            value = float(text)
            stats["coords_seen"] += 1
            if is_on_grid(value, grid):
                return text
            stats["coords_offgrid"] += 1
            offenders[(macro, context)] += 1
            # do lech so voi diem grid ngay duoi, tinh bang nm cho de doc
            residuals[round((value - snap(value, grid, "down")) * 1000, 4)] += 1
            new = snap(value, grid, mode)
            if abs(new - value) > grid:            # khong bao gio nhay qua 1 grid
                return text
            changed[0] = True
            stats["coords_fixed"] += 1
            return fmt(new, len(text.split(".")[1]))

        new_line = NUMBER_RE.sub(repl, line)
        if changed[0]:
            stats["lines_fixed"] += 1
        out.append(new_line + "\n")

    return out, stats, residuals, offenders


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("lef", help="file LEF macro can kiem tra / sua")
    ap.add_argument("--fix", action="store_true",
                    help="ghi file da sua (can -o).  Khong co thi chi bao cao.")
    ap.add_argument("-o", "--out", help="file LEF ket qua")
    ap.add_argument("--grid", type=float, default=0.004,
                    help="MANUFACTURINGGRID, um (mac dinh 0.004 = tech LEF 4x)")
    ap.add_argument("--mode", choices=("nearest", "down", "up"),
                    default="nearest",
                    help="huong snap.  nearest: gan nhat.  down/up: dich moi"
                         " toa do cung mot huong, giu nguyen kich thuoc hinh"
                         " khi do lech dong nhat.")
    ap.add_argument("--site", action="append", default=[], metavar="OLD=NEW|NEW",
                    help="doi ten SITE: 'coreSite=asap7sc7p5t', hoac chi NEW de"
                         " doi moi SITE gap duoc sang NEW")
    ap.add_argument("--drop-site", action="store_true",
                    help="bo han dong SITE (MACRO CLASS BLOCK khong can SITE)")
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

    out, stats, residuals, offenders = process(
        lines, args.grid, args.mode, site_map, args.drop_site)

    print("file        : %s" % args.lef)
    print("grid        : %g um   mode: %s" % (args.grid, args.mode))
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
        if len(residuals) == 1:
            print("  -> moi toa do lech cung mot luong: snap chi dich ca macro,"
                  " kich thuoc tung hinh giu nguyen.")
        else:
            print("  -> do lech khong dong nhat: mode 'nearest' co the doi kich"
                  " thuoc vai hinh 1 grid.  Xem lai truoc khi dung.")

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
