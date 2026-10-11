#!/usr/bin/env python3
"""Kiem tra dien ap ma cac .lib std cell ASAP7 tu khai bao, va thay file sai.

Vi sao co script nay.  Tempus run 2026-10-11: asap7sc7p5t_SIMPLE_RVT_FF_ccs_211120.lib
tu khai bao 0.7 V trong khi 9 lib FF con lai la 0.77 V - 33865 instance (23.9 %
thiet ke) bi tinh sai dien ap o goc hold, nen hold +10 ps chua tin duoc.

Chay tren may Linux co PDK (mac dinh chi DOC, khong sua gi):

    python3 scripts/fix_ff_lib.py                 # bao cao + tim ban dung
    python3 scripts/fix_ff_lib.py --apply         # thay file sai
    python3 scripts/fix_ff_lib.py --from X.lib.7z --apply   # chi ro ban dung

Tim ban dung o dau: file nen (.7z/.gz/.xz/.bz2) cung ten trong PDK, ban trong
git cua PDK (git show HEAD:...), va moi file cung ten duoi cac thu muc --search.
Mot ung vien chi duoc dung khi no khai bao DUNG dien ap cua goc va ten library
ben trong mang DUNG goc.

--apply con thay ca BAN SAO trong checkpoint Innovus: saveDesign chep .lib vao
<ten>.enc.dat/libs/mmmc/ va viewDefinition.tcl cua checkpoint tro vao do, nen
restoreDesign van nap file cu du PDK da sua.

Ma thoat: 0 = moi lib dung (hoac da thay xong), 1 = con lib sai va co ban dung
(chay lai voi --apply), 2 = con lib sai va KHONG tim duoc ban dung.
"""

import argparse
import bz2
import glob
import gzip
import hashlib
import lzma
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter

LIB_RE = re.compile(r"^(asap7sc7p5t_\w+?)_(SS|TT|FF)_(ccs\w*|nldm)_(\d+)\.lib$")
ARCHIVE_EXTS = (".7z", ".gz", ".xz", ".bz2")
HEADER_LINES = 20000


def read_header(path):
    """Doc tu dau file toi cell dau tien: ten library va moi dien ap khai bao."""
    info = {"library": "", "volts": [], "temps": []}
    with open(path, "r", errors="replace") as fp:
        for count, line in enumerate(fp):
            if count > HEADER_LINES or re.match(r"\s*cell\s*\(", line):
                break
            m = re.match(r"\s*library\s*\(\s*\"?([^\s\")]+)", line)
            if m and not info["library"]:
                info["library"] = m.group(1)
            # Mot dong co the chua nhieu khai bao (operating_conditions viet gon).
            for volt in re.findall(r"(?:^|[\s{;])(?:nom_)?voltage\s*:\s*([0-9.]+)", line) + \
                    re.findall(r"voltage_map\s*\(\s*\"?VDD\"?\s*,\s*([0-9.]+)", line):
                info["volts"].append("%g" % float(volt))
            for temp in re.findall(r"(?:^|[\s{;])(?:nom_)?temperature\s*:\s*(-?[0-9.]+)", line):
                info["temps"].append("%g" % float(temp))
    info["volt"] = "/".join(sorted(set(info["volts"]))) or "?"
    info["temp"] = "/".join(sorted(set(info["temps"]))) or "?"
    return info


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as fp:
        for chunk in iter(lambda: fp.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def first_table(path, group="cell_rise", limit=2000000):
    """Cac so cua bang 'values' dau tien trong nhom <group> dau tien."""
    inside = False
    text = ""
    with open(path, "r", errors="replace") as fp:
        for count, line in enumerate(fp):
            if count > limit:
                break
            if not inside:
                if re.match(r"\s*%s\s*\(" % group, line):
                    inside = True
                continue
            text += line
            if ");" in line and "values" in text:
                break
    m = re.search(r"values\s*\((.*?)\)\s*;", text, re.S)
    if not m:
        return []
    return [float(x) for x in re.findall(r"-?\d+\.?\d*(?:[eE][-+]?\d+)?", m.group(1))]


def table_ratio(path_a, path_b):
    """Ti le trung binh bang tre dau tien cua a so voi b; None neu khong so duoc."""
    a, b = first_table(path_a), first_table(path_b)
    if not a or len(a) != len(b):
        return None
    pairs = [(x, y) for x, y in zip(a, b) if y > 0]
    if not pairs:
        return None
    return sum(x / y for x, y in pairs) / len(pairs)


def count_diff_lines(path_a, path_b):
    """(so dong khac nhau, so dong cua a, so dong cua b)."""
    diff = na = nb = 0
    with open(path_a, "r", errors="replace") as fa, open(path_b, "r", errors="replace") as fb:
        while True:
            la, lb = fa.readline(), fb.readline()
            if not la and not lb:
                break
            na += bool(la)
            nb += bool(lb)
            if la != lb:
                diff += 1
    return diff, na, nb


def extract(src, dst):
    """Giai nen <src> ra file <dst>; file .lib thuong thi chep."""
    low = src.lower()
    if low.endswith(".7z"):
        tool = next((t for t in ("7z", "7za", "7zr") if shutil.which(t)), None)
        if tool is None:
            raise RuntimeError("can lenh 7z / 7za / 7zr de mo %s (goi p7zip)" % src)
        with open(dst, "wb") as out:
            subprocess.run([tool, "x", "-so", src], stdout=out,
                           stderr=subprocess.DEVNULL, check=True)
        return
    opener = {".gz": gzip.open, ".xz": lzma.open, ".bz2": bz2.open}.get(
        os.path.splitext(low)[1])
    if opener is None:
        shutil.copyfile(src, dst)
        return
    with opener(src, "rb") as fin, open(dst, "wb") as out:
        shutil.copyfileobj(fin, out, 1 << 20)


def git_candidates(lib_path, tmp_dir):
    """Ban trong git cua PDK (HEAD), ke ca khi file tren dia da bi sua."""
    lib_dir, base = os.path.split(lib_path)

    def git(*args, binary=False):
        res = subprocess.run(["git", "-C", lib_dir] + list(args),
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        if res.returncode != 0:
            return None
        return res.stdout if binary else res.stdout.decode(errors="replace").strip()

    found = []
    if not shutil.which("git") or git("rev-parse", "--show-toplevel") is None:
        return found, "thu muc lib khong nam trong repo git"
    head = git("rev-parse", "HEAD") or "?"
    status = git("status", "--short", "--", base + "*") or "(sach)"
    note = "git HEAD %s; git status cua %s*: %s" % (head[:12], base, status.replace("\n", " | "))
    for rel in (git("ls-files", "--", base + "*") or "").splitlines():
        blob = git("show", "HEAD:./" + rel, binary=True)
        if blob is None:
            continue
        dst = os.path.join(tmp_dir, "git_" + os.path.basename(rel))
        with open(dst, "wb") as out:
            out.write(blob)
        found.append((dst, "git HEAD:%s" % rel))
    return found, note


def find_candidates(lib_path, search_dirs, explicit, tmp_dir):
    """Danh sach (duong dan, nguon) co the la ban dung cua <lib_path>."""
    base = os.path.basename(lib_path)
    out = [(p, "--from") for p in explicit]
    seen = {os.path.realpath(lib_path)} | {os.path.realpath(p) for p in explicit}
    for root in search_dirs:
        for dirpath, dirnames, filenames in os.walk(root):
            # Checkpoint Innovus giu ban sao cua chinh file sai.
            dirnames[:] = [d for d in dirnames if not d.endswith(".enc.dat")]
            for name in filenames:
                if name == base or (name.startswith(base) and name.lower().endswith(ARCHIVE_EXTS)):
                    path = os.path.join(dirpath, name)
                    if os.path.realpath(path) not in seen:
                        seen.add(os.path.realpath(path))
                        out.append((path, "tim thay duoi %s" % root))
    from_git, note = git_candidates(lib_path, tmp_dir)
    return out + from_git, note


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    asap7_root = os.environ.get("ASAP7_ROOT") or os.environ.get("ASAP7_HOME") \
        or "/home/user1/Desktop/asap7"
    default_lib_dir = os.environ.get("ASAP7_STD_LIB_DIR") or os.path.join(
        os.environ.get("ASAP7_STDCELL_ROOT") or os.path.join(asap7_root, "asap7sc7p5t_28"),
        "LIB", "CCS")

    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lib-dir", default=default_lib_dir,
                    help="thu muc LIB/CCS cua asap7sc7p5t_28 (mac dinh: %(default)s)")
    ap.add_argument("--checkpoints", default=os.path.join(here, "..", "saved"),
                    help="thu muc chua *.enc.dat cua Innovus (mac dinh: %(default)s)")
    ap.add_argument("--search", action="append", default=[],
                    help="thu muc tim them ban dung (lap lai duoc); luon tim trong goc PDK")
    ap.add_argument("--from", dest="explicit", action="append", default=[],
                    help="file .lib hoac file nen duoc chi ro la ban dung")
    ap.add_argument("--apply", action="store_true", help="thay file sai (mac dinh chi bao cao)")
    args = ap.parse_args()

    lib_dir = os.path.abspath(args.lib_dir)
    if not os.path.isdir(lib_dir):
        sys.exit("Khong co thu muc %s - dat --lib-dir hoac ASAP7_ROOT" % lib_dir)
    for path in args.explicit:
        if not os.path.isfile(path):
            sys.exit("--from %s: khong co file" % path)

    # ---- 1. Moi lib khai bao gi ----------------------------------------
    libs = {}
    for name in sorted(os.listdir(lib_dir)):
        m = LIB_RE.match(name)
        if m:
            path = os.path.join(lib_dir, name)
            libs[name] = dict(read_header(path), path=path, family=m.group(1),
                              corner=m.group(2), kind=m.group(3), date=m.group(4))
    if not libs:
        sys.exit("Khong co file asap7sc7p5t_*_{SS,TT,FF}_*.lib nao trong %s" % lib_dir)

    major = {}
    for corner in ("SS", "TT", "FF"):
        volts = Counter(v["volt"] for v in libs.values() if v["corner"] == corner)
        if volts:
            major[corner] = volts.most_common(1)[0][0]

    print("Thu muc lib: %s" % lib_dir)
    print("%-52s %-9s %-8s %s" % ("file", "dien ap", "nhiet do", "library ben trong"))
    bad = []
    for name, v in libs.items():
        why = []
        if v["volt"] != major[v["corner"]]:
            why.append("dien ap %s V, cac lib %s khac la %s V" % (v["volt"], v["corner"], major[v["corner"]]))
        if "_%s_" % v["corner"] not in v["library"]:
            why.append("ten library ben trong (%s) khong mang goc %s" % (v["library"], v["corner"]))
        print("%-52s %-9s %-8s %s%s" % (name, v["volt"] + " V", v["temp"], v["library"],
                                      "   <-- SAI" if why else ""))
        if why:
            bad.append((name, why))
    print("Dien ap da so cua tung goc: %s" % ", ".join("%s %s V" % kv for kv in sorted(major.items())))

    if not bad:
        print("\nKET LUAN: moi lib trong mot goc khai bao cung dien ap - khong phai sua gi.")
        return 0

    bad_names = {name for name, _ in bad}
    status = 0
    tmp_dir = tempfile.mkdtemp(prefix="fix_ff_lib_")
    try:
        for name, why in bad:
            v = libs[name]
            print("\n" + "=" * 72)
            print("FILE SAI: %s" % v["path"])
            for reason in why:
                print("  - %s" % reason)

            # ---- 2. No la ban sao cua goc nao? ---------------------------
            bad_sha = sha256(v["path"])
            for other in ("TT", "SS", "FF"):
                sib = "%s_%s_%s_%s.lib" % (v["family"], other, v["kind"], v["date"])
                if other == v["corner"] or sib not in libs:
                    continue
                sib_path = libs[sib]["path"]
                if sha256(sib_path) == bad_sha:
                    print("  So voi %s: GIONG HET tung byte -> file nay la ban sao cua goc %s." % (sib, other))
                    continue
                diff, na, nb = count_diff_lines(v["path"], sib_path)
                ratio = table_ratio(v["path"], sib_path)
                print("  So voi %s: %d dong khac (%d / %d dong), bang tre dau tien ti le %s" % (
                    sib, diff, na, nb, "%.3f" % ratio if ratio else "khong so duoc"))
            # Moc: mot cap <goc>/TT DUNG cua ho khac lech nhau bao nhieu.
            if v["corner"] != "TT":
                for ref_name, ref in libs.items():
                    tt = ref_name.replace("_%s_" % v["corner"], "_TT_")
                    if ref["corner"] != v["corner"] or ref["kind"] != v["kind"] or \
                            ref_name in bad_names or tt not in libs:
                        continue
                    ratio = table_ratio(ref["path"], libs[tt]["path"])
                    if ratio:
                        print("  Moc: %s / ban TT cua no = %.3f.  File sai ma ti le voi TT ~1.000 thi"
                              " ca bang tre la cua TT;\n       gan moc thi bang tre dung goc, chi phan"
                              " dau file sai." % (ref_name, ratio))
                        break

            # ---- 3. Tim ban dung -----------------------------------------
            pdk_root = os.path.dirname(os.path.dirname(lib_dir))
            cands, git_note = find_candidates(v["path"], [pdk_root] + args.search, args.explicit, tmp_dir)
            print("  %s" % git_note)
            good = None
            for index, (src, origin) in enumerate(cands):
                plain = os.path.join(tmp_dir, "cand%d_%s" % (index, name))
                try:
                    extract(src, plain)
                    head = read_header(plain)
                except Exception as err:  # noqa: BLE001 - bao ly do roi thu ung vien khac
                    print("  ung vien %s (%s): khong doc duoc - %s" % (src, origin, err))
                    continue
                ok = head["volt"] == major[v["corner"]] and "_%s_" % v["corner"] in head["library"]
                print("  ung vien %s (%s): %s V, library %s -> %s" % (
                    src, origin, head["volt"], head["library"], "DUNG" if ok else "khong dung"))
                if ok and good is None:
                    good = (plain, src, origin)

            copies = sorted(glob.glob(os.path.join(
                os.path.abspath(args.checkpoints), "*.enc.dat", "libs", "mmmc", name)))
            stale = [p for p in copies if read_header(p)["volt"] != major[v["corner"]]]
            print("  Ban sao trong checkpoint Innovus: %d file, %d file con sai dien ap" % (len(copies), len(stale)))

            if good is None:
                status = 2
                if cands:
                    print("  KHONG ung vien nao dung.  Neu ca ban trong git/file nen cung khai bao %s V thi"
                          "\n  loi nam o chinh ban phat hanh cua PDK, khong phai o may nay." % v["volt"])
                else:
                    print("  KHONG tim thay ung vien nao.")
                print("  Lay lai tu repo goc: github.com/The-OpenROAD-Project/asap7sc7p5t_28,"
                      "\n    LIB/%s/%s.7z   (flow nay dung revision f970bd3)"
                      "\n  roi: python3 %s --from <file tai ve> --apply" % (
                          os.path.basename(lib_dir), name, os.path.relpath(__file__)))
                continue

            plain, src, origin = good
            if not args.apply:
                status = max(status, 1)
                print("  SE THAY bang %s (%s).  Chay lai voi --apply." % (src, origin))
                continue
            backup = "%s.bad_%sV" % (v["path"], v["volt"].replace("/", "_"))
            if not os.path.exists(backup):
                shutil.copy2(v["path"], backup)
                print("  Giu ban cu: %s" % backup)
            for target in [v["path"]] + stale:
                shutil.copyfile(plain, target)
                check = read_header(target)
                print("  DA THAY %s -> %s V, library %s" % (target, check["volt"], check["library"]))
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)

    print("\nKET LUAN: %s" % {
        0: "da thay xong.  Chay lai Tempus (cd ../tempus && make all); dong WARNING ve dien ap"
           " lib phai bien mat.",
        1: "con lib sai, da co ban dung - chay lai voi --apply.",
        2: "con lib sai va chua co ban dung - xem huong dan o tren.",
    }[status])
    return status


if __name__ == "__main__":
    sys.exit(main())
