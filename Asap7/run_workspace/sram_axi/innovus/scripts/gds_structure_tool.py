#!/usr/bin/env python3
"""Inspect and rename GDSII structures.

Why this exists
---------------
Innovus `streamOut -merge` matches merged GDS structures to design masters by
*exact name*.  It has no cell-name remapping parameter.  When the SRAM GDS
stores its layout under a name that differs from the LEF/Liberty master, the
merge silently drops the macro and the run only prints:

    **WARN: (IMPOGDS-217): Master cell: <master> not found in merged file(s)
    **WARN: (IMPOGDS-218): Number of master cells not found after merging: 1

and the exported top-level GDS contains empty boxes where the macros should be.

Usage
-----
    python3 gds_structure_tool.py list   <in.gds>
    python3 gds_structure_tool.py rename <in.gds> <out.gds> --to NEW [--from OLD]

`list` is the diagnostic: it prints every structure and marks the ones no
SREF/AREF references.

`rename` is only correct when the file really does contain the macro layout
under a different name.  It is NOT a way to make a primitive library stand in
for an assembled macro: ASAP7's gds/srambank_32b.gds holds the SRAM building
blocks (bitcell, column, sense amp, tap, filler), and renaming one of those
to the bank name would place the wrong geometry under every macro instance.
When `list` shows building blocks rather than a bank, find the generated
per-macro GDS instead.

The tool is dependency-free and streams the file record by record, so it works
on large GDS files without loading them into memory.
"""

import argparse
import os
import shutil
import struct
import sys

HEADER = struct.Struct(">HBB")

REC_STRNAME = (0x06, 0x06)   # structure definition name
REC_SNAME = (0x12, 0x06)     # structure reference name (SREF / AREF)
REC_BGNSTR = (0x05, 0x02)
REC_ENDLIB = (0x04, 0x00)


class GdsError(RuntimeError):
    pass


def _decode(raw):
    return raw.rstrip(b"\x00").decode("ascii", "replace")


def _encode(name):
    raw = name.encode("ascii")
    if len(raw) % 2:
        raw += b"\x00"
    return raw


def read_records(path):
    """Yield (rtype, rdtype, payload) for every record in the file."""
    with open(path, "rb") as fh:
        while True:
            head = fh.read(4)
            if not head:
                return
            if len(head) < 4:
                raise GdsError("truncated record header near end of %s" % path)
            length, rtype, rdtype = HEADER.unpack(head)
            if length < 4:
                raise GdsError(
                    "invalid record length %d at offset %d" % (length, fh.tell() - 4)
                )
            payload = fh.read(length - 4)
            if len(payload) < length - 4:
                raise GdsError("truncated record payload in %s" % path)
            yield rtype, rdtype, payload
            if (rtype, rdtype) == REC_ENDLIB:
                return


def scan(path):
    """Return (defined_names, referenced_names) preserving definition order."""
    defined = []
    referenced = set()
    for rtype, rdtype, payload in read_records(path):
        if (rtype, rdtype) == REC_STRNAME:
            defined.append(_decode(payload))
        elif (rtype, rdtype) == REC_SNAME:
            referenced.add(_decode(payload))
    return defined, referenced


def top_structures(defined, referenced):
    return [name for name in defined if name not in referenced]


def cmd_list(args):
    defined, referenced = scan(args.gds)
    if not defined:
        print("No structures found in %s" % args.gds, file=sys.stderr)
        return 2
    tops = top_structures(defined, referenced)
    print("# %d structure(s) in %s" % (len(defined), args.gds))
    print("# TOP marks a structure that no SREF/AREF references")
    for name in defined:
        print("%-6s %s" % ("TOP" if name in tops else "", name))
    print()
    print("# top structures: %s" % (", ".join(tops) if tops else "(none)"))
    return 0


def cmd_rename(args):
    defined, referenced = scan(args.gds)
    if not defined:
        raise GdsError("no structures found in %s" % args.gds)

    new = args.to_name

    if new in defined:
        print("Structure %r already exists in %s; nothing to rename." % (new, args.gds))
        if os.path.abspath(args.out) != os.path.abspath(args.gds):
            shutil.copyfile(args.gds, args.out)
            print("Copied unchanged to %s" % args.out)
        return 0

    old = args.from_name
    if old is None:
        tops = top_structures(defined, referenced)
        if len(tops) != 1:
            raise GdsError(
                "cannot pick a source structure automatically: %d top structures "
                "(%s). Re-run with --from <name>."
                % (len(tops), ", ".join(tops) if tops else "none")
            )
        old = tops[0]
        print("Auto-selected top structure %r" % old)
    elif old not in defined:
        raise GdsError(
            "structure %r is not defined in %s. Defined: %s"
            % (old, args.gds, ", ".join(defined))
        )

    old_raw = _encode(old)
    new_raw = _encode(new)
    renamed_defs = 0
    renamed_refs = 0

    tmp = args.out + ".tmp"
    with open(tmp, "wb") as out:
        for rtype, rdtype, payload in read_records(args.gds):
            if (rtype, rdtype) in (REC_STRNAME, REC_SNAME) and payload == old_raw:
                payload = new_raw
                if (rtype, rdtype) == REC_STRNAME:
                    renamed_defs += 1
                else:
                    renamed_refs += 1
            out.write(HEADER.pack(len(payload) + 4, rtype, rdtype))
            out.write(payload)
    os.replace(tmp, args.out)

    if renamed_defs == 0:
        raise GdsError("no structure definition matched %r" % old)

    print(
        "Renamed %r -> %r (%d definition, %d reference(s))"
        % (old, new, renamed_defs, renamed_refs)
    )
    print("Wrote %s" % args.out)
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    p_list = sub.add_parser("list", help="print every structure name in a GDS")
    p_list.add_argument("gds")
    p_list.set_defaults(func=cmd_list)

    p_ren = sub.add_parser(
        "rename",
        help="write a copy with one structure renamed (only when the file "
             "really holds the macro layout under another name)",
    )
    p_ren.add_argument("gds")
    p_ren.add_argument("out")
    p_ren.add_argument("--to", dest="to_name", required=True,
                       help="new structure name, e.g. the LEF/Liberty master")
    p_ren.add_argument("--from", dest="from_name", default=None,
                       help="source structure name (default: the single top structure)")
    p_ren.set_defaults(func=cmd_rename)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except GdsError as exc:
        print("error: %s" % exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
