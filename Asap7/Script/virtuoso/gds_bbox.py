#!/usr/bin/env python3
"""Do kich thuoc that cua cell trong file GDS, khong can Virtuoso/KLayout.

Duyet het hierarchy (SREF/AREF co transform) roi in bbox cua top cell.  Dung de
doi chieu voi SIZE trong LEF: hai so khac nhau thi GDS do khong phai layout cua
macro do.

  python gds_bbox.py srambank_128b.gds          # theo dung UNITS trong file
  python gds_bbox.py -x4 srambank_128b.gds      # nhan 4, de so voi LEF 4x

CANH BAO: dung lay min/max cua moi record XY roi coi la bbox.  AREF mang diem
tham chieu cot/hang nam NGOAI vung thuc te (vi du COLROW (1,32) van co diem cot
o xa), doc tho se ra so lon hon that.
"""
import struct, sys, math

BOUNDARY, PATH, SREF, AREF, TEXT = 0x08, 0x09, 0x0a, 0x0b, 0x0c


def _real8(b):
    exp = (b[0] & 0x7f) - 64
    v = int.from_bytes(b[1:], 'big') / float(1 << 56) * (16.0 ** exp)
    return -v if b[0] & 0x80 else v


def parse(path):
    data = open(path, 'rb').read()
    structs, order, dbu = {}, [], None
    cur = elem = None
    i = 0
    while i < len(data) - 3:
        ln = struct.unpack('>H', data[i:i + 2])[0]
        if ln < 4:
            break
        rec, dt, body = data[i + 2], data[i + 3], data[i + 4:i + ln]
        if rec == 0x03 and dt == 0x05:
            dbu = 1e-6 / _real8(body[8:16])
        elif rec == 0x06 and dt == 0x06:
            cur = body.split(b'\0')[0].decode('ascii')
            structs[cur] = []; order.append(cur)
        elif rec in (BOUNDARY, PATH, SREF, AREF, TEXT) and dt == 0x00:
            elem = {'kind': rec, 'xy': [], 'sname': None,
                    'strans': 0, 'mag': 1.0, 'angle': 0.0, 'colrow': (1, 1)}
        elif rec == 0x11:
            if elem is not None and cur is not None:
                structs[cur].append(elem)
            elem = None
        elif elem is not None:
            if rec == 0x10 and dt == 0x03:
                n = len(body) // 4
                v = struct.unpack('>%di' % n, body)
                elem['xy'] = list(zip(v[0::2], v[1::2]))
            elif rec == 0x12 and dt == 0x06:
                elem['sname'] = body.split(b'\0')[0].decode('ascii')
            elif rec == 0x1a and dt == 0x01:
                elem['strans'] = struct.unpack('>H', body[0:2])[0]
            elif rec == 0x1b and dt == 0x05:
                elem['mag'] = _real8(body[0:8])
            elif rec == 0x1c and dt == 0x05:
                elem['angle'] = _real8(body[0:8])
            elif rec == 0x13 and dt == 0x02:
                elem['colrow'] = struct.unpack('>hh', body[0:4])
        i += ln
    return structs, order, dbu


def _xform(pt, strans, angle, mag):
    x, y = pt
    if strans & 0x8000:
        y = -y
    a = math.radians(angle)
    c, s = math.cos(a), math.sin(a)
    return (mag * (x * c - y * s), mag * (x * s + y * c))


def _merge(bb, pts):
    for x, y in pts:
        if bb is None:
            bb = [x, y, x, y]
        else:
            bb[0] = min(bb[0], x); bb[1] = min(bb[1], y)
            bb[2] = max(bb[2], x); bb[3] = max(bb[3], y)
    return bb


def bbox(name, structs, memo, stack=()):
    if name in memo:
        return memo[name]
    if name not in structs or name in stack:
        return None
    bb = None
    for e in structs[name]:
        k = e['kind']
        if k in (BOUNDARY, PATH, TEXT):
            bb = _merge(bb, e['xy'])
        elif k in (SREF, AREF) and e['sname'] and e['xy']:
            cb = bbox(e['sname'], structs, memo, stack + (name,))
            if cb is None:
                continue
            corners = [(cb[0], cb[1]), (cb[2], cb[1]), (cb[0], cb[3]), (cb[2], cb[3])]
            corners = [_xform(p, e['strans'], e['angle'], e['mag']) for p in corners]
            if k == SREF:
                origins = [e['xy'][0]]
            else:
                nc, nr = e['colrow']
                p0, pc, pr = e['xy'][0], e['xy'][1], e['xy'][2]
                cv = ((pc[0] - p0[0]) / max(nc, 1), (pc[1] - p0[1]) / max(nc, 1))
                rv = ((pr[0] - p0[0]) / max(nr, 1), (pr[1] - p0[1]) / max(nr, 1))
                origins = [(p0[0] + i * cv[0] + j * rv[0],
                            p0[1] + i * cv[1] + j * rv[1])
                           for i in (0, max(nc - 1, 0)) for j in (0, max(nr - 1, 0))]
            for ox, oy in origins:
                bb = _merge(bb, [(ox + cx, oy + cy) for cx, cy in corners])
    memo[name] = bb
    return bb


def main(argv):
    scale, files = 1.0, []
    for a in argv:
        if a == '-x4':
            scale = 4.0
        else:
            files.append(a)
    if not files:
        print(__doc__); return 1
    for f in files:
        structs, order, dbu = parse(f)
        refd = {e['sname'] for s in structs.values() for e in s if e['sname']}
        tops = [n for n in order if n not in refd]
        print('=' * 68); print(f)
        print('  UNITS trong file : %g dbu/um' % dbu)
        print('  so structure     : %d' % len(structs))
        print('  top cell         : %s' % (', '.join(tops) or '(khong xac dinh)'))
        memo = {}
        for t in tops:
            bb = bbox(t, structs, memo)
            if bb is None:
                print('  %s: rong' % t); continue
            w, h = bb[2] - bb[0], bb[3] - bb[1]
            print('  %s' % t)
            print('    bbox dbu : %d x %d' % (w, h))
            print('    bbox um  : %.4f x %.4f%s' % (w / dbu * scale, h / dbu * scale,
                  '   (da nhan 4)' if scale != 1.0 else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
