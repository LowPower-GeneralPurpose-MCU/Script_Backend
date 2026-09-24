#!/usr/bin/env python3
"""Kiem GDS hop den (do sram_blackbox.il sinh ra) co khop LEF khong.

  python check_blackbox_gds.py bb_gds/srambank_256x4x32_6t122.gds \\
         .../srambank_256x4x32_6t122.lef.4x.lef

So bang SO NGUYEN dbu (= toa do LEF x 1000), khong theo header UNITS: cung
day so, doc o 4000 dbu/um la 1x, o 1000 dbu/um la 4x (xem gds_rescale.py).
Kiem:
  1. dung 1 structure, ten = MACRO trong LEF, khong SREF/AREF (hop den phang)
  2. dung 1 BOUNDARY 100/0 = (0,0)-(W,H) cua SIZE
  3. bbox cua moi hinh = dung SIZE, khong gi lo ra ngoai
  4. moi PIN co 1 TEXT texttype 251 dung ten, nam tren 1 hinh cung layer dt 0
  5. so hinh tung layer = so RECT cua PIN sau khi cat vao SIZE
Tra ve 0 neu dat het, 1 neu co muc hong.
"""
import struct, sys
from collections import Counter

GDS_LAYER = {'M1': 19, 'V1': 21, 'M2': 20, 'V2': 25, 'M3': 30, 'V3': 35,
             'M4': 40, 'V4': 45, 'M5': 50, 'V5': 55, 'M6': 60, 'V6': 65,
             'M7': 70, 'V7': 75, 'M8': 80, 'V8': 85, 'M9': 90, 'V9': 95,
             'Pad': 96}
BOUNDARY_LAYER, PIN_TEXTTYPE = 100, 251


def _real8(b):
    exp = (b[0] & 0x7f) - 64
    v = int.from_bytes(b[1:], 'big') / float(1 << 56) * (16.0 ** exp)
    return -v if b[0] & 0x80 else v


def parse_gds(path):
    """-> (dbu_per_um, {struct: [elem]}); elem = dict kind/layer/dt/xy/text."""
    data = open(path, 'rb').read()
    structs, cur, elem, dbu, i = {}, None, None, None, 0
    kinds = {0x08: 'boundary', 0x09: 'path', 0x0a: 'sref', 0x0b: 'aref',
             0x0c: 'text', 0x2d: 'box'}
    while i < len(data) - 3:
        ln = struct.unpack('>H', data[i:i + 2])[0]
        if ln < 4:
            break
        rec, dt, body = data[i + 2], data[i + 3], data[i + 4:i + ln]
        if rec == 0x03:
            dbu = 1e-6 / _real8(body[8:16])
        elif rec == 0x06:
            cur = body.split(b'\0')[0].decode('ascii')
            structs[cur] = []
        elif rec in kinds:
            elem = {'kind': kinds[rec], 'layer': None, 'dt': None, 'xy': [],
                    'text': None}
        elif rec == 0x11:
            if elem is not None and cur is not None:
                structs[cur].append(elem)
            elem = None
        elif elem is not None:
            if rec == 0x0d:
                elem['layer'] = struct.unpack('>h', body[:2])[0]
            elif rec in (0x0e, 0x16, 0x2e):          # DATATYPE/TEXTTYPE/BOXTYPE
                elem['dt'] = struct.unpack('>h', body[:2])[0]
            elif rec == 0x10:
                v = struct.unpack('>%di' % (len(body) // 4), body)
                elem['xy'] = list(zip(v[0::2], v[1::2]))
            elif rec == 0x19:
                elem['text'] = body.split(b'\0')[0].decode('ascii')
        i += ln
    return dbu, structs


def parse_lef(path):
    """Cung may trang thai voi bbParseLef trong sram_blackbox.il."""
    macro = size = None
    pins, state, in_prop, layer, cur = {}, 'top', False, None, None
    for line in open(path):
        t = line.replace(';', ' ').split()
        if not t:
            continue
        k = t[0]
        if in_prop:
            in_prop = k != 'END'
        elif k == 'PROPERTYDEFINITIONS':
            in_prop = True
        elif state == 'top':
            if k == 'MACRO':
                macro, state = t[1], 'macro'
        elif state == 'macro':
            if k == 'SIZE':
                size = (float(t[1]), float(t[3]))
            elif k == 'PIN':
                cur, state = t[1], 'pin'
                pins[cur] = []
            elif k == 'OBS':
                state = 'obs'
            elif k == 'END' and len(t) > 1 and t[1] == macro:
                break
        elif state == 'pin':
            if k == 'PORT':
                state = 'port'
            elif k == 'END':
                state = 'macro'
        elif state == 'port':
            if k == 'LAYER':
                layer = t[1]
            elif k == 'RECT':
                r = t[1:]
                if r[0] == 'MASK':
                    r = r[2:]
                pins[cur].append((layer, [float(v) for v in r[:4]]))
            elif k == 'END':
                state = 'pin'
        elif state == 'obs' and k == 'END':
            state = 'macro'
    return macro, size, pins


def dbu_int(v):
    return int(round(v * 1000))


def clip(r, w, h):
    x0, x1 = sorted((r[0], r[2]))
    y0, y1 = sorted((r[1], r[3]))
    x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, w), min(y1, h)
    return (x0, y0, x1, y1) if x1 > x0 and y1 > y0 else None


def rect_of(xy):
    xs, ys = [p[0] for p in xy], [p[1] for p in xy]
    return min(xs), min(ys), max(xs), max(ys)


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2
    gds, lef = argv
    dbu, structs = parse_gds(gds)
    macro, size, pins = parse_lef(lef)
    W, H = dbu_int(size[0]), dbu_int(size[1])
    fails = []

    def check(ok, msg):
        print('  [%s] %s' % ('OK  ' if ok else 'HONG', msg))
        if not ok:
            fails.append(msg)

    print('GDS : %s' % gds)
    print('LEF : %s  (MACRO %s, SIZE %g x %g um 4x)' % (lef, macro, *size))
    print('UNITS %g dbu/um -> doc tho: %.4f x %.4f um' % (dbu, W / dbu, H / dbu))
    print('  (4x = so dbu/1000: %.3f x %.3f um, 1x = %.3f x %.3f um)'
          % (W / 1000, H / 1000, W / 4000, H / 4000))

    check(list(structs) == [macro],
          '1 structure ten %s (co: %s)' % (macro, ', '.join(structs) or '-'))
    elems = structs.get(macro, [])
    check(not any(e['kind'] in ('sref', 'aref') for e in elems),
          'khong co SREF/AREF')

    shapes = [e for e in elems if e['kind'] in ('boundary', 'box') and e['xy']]
    bnd = [e for e in shapes if e['layer'] == BOUNDARY_LAYER]
    check(len(bnd) == 1 and bnd[0]['dt'] == 0
          and rect_of(bnd[0]['xy']) == (0, 0, W, H),
          'BOUNDARY %d/0 = (0,0)-(%d,%d) dbu: %s'
          % (BOUNDARY_LAYER, W, H, [rect_of(e['xy']) for e in bnd]))

    allpts = [p for e in elems for p in e['xy']]
    bb = rect_of(allpts) if allpts else None
    check(bb == (0, 0, W, H), 'bbox moi hinh = SIZE: %s' % (bb,))

    # hinh chan mong doi (sau khi cat), theo layer GDS
    want = Counter()
    for rects in pins.values():
        for layer, r in rects:
            if clip(r, *size):
                want[GDS_LAYER[layer]] += 1
    got = Counter(e['layer'] for e in shapes
                  if e['layer'] != BOUNDARY_LAYER and e['dt'] == 0)
    for ly in sorted(set(want) | set(got)):
        check(want[ly] == got[ly],
              'layer %d/0: %d hinh (LEF sau cat: %d)' % (ly, got[ly], want[ly]))
    odd = [(e['layer'], e['dt']) for e in shapes
           if e['layer'] != BOUNDARY_LAYER and e['dt'] != 0]
    check(not odd, 'khong co hinh o datatype khac 0: %s' % Counter(odd))

    # nhan chan
    texts = [e for e in elems if e['kind'] == 'text']
    by_name = {}
    for e in texts:
        by_name.setdefault(e['text'], []).append(e)
    bad = []
    for p in pins:
        ts = by_name.get(p, [])
        if len(ts) != 1 or ts[0]['dt'] != PIN_TEXTTYPE:
            bad.append('%s: %d nhan' % (p, len(ts)))
            continue
        x, y = ts[0]['xy'][0]
        ly = ts[0]['layer']
        if not any(e['layer'] == ly and e['dt'] == 0 and
                   rect_of(e['xy'])[0] <= x <= rect_of(e['xy'])[2] and
                   rect_of(e['xy'])[1] <= y <= rect_of(e['xy'])[3]
                   for e in shapes):
            bad.append('%s: nhan o (%d,%d) layer %d khong nam tren hinh nao'
                       % (p, x, y, ly))
    check(not bad, '%d/%d chan co dung 1 nhan texttype %d nam tren hinh chan%s'
          % (len(pins) - len(bad), len(pins), PIN_TEXTTYPE,
             ('  <- ' + '; '.join(bad[:5])) if bad else ''))
    extra = sorted(set(by_name) - set(pins))
    check(not extra, 'khong co nhan la: %s' % extra[:5])

    print('KET QUA: %s' % ('DAT' if not fails else 'HONG %d muc' % len(fails)))
    return 0 if not fails else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
