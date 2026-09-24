#!/usr/bin/env python3
"""Doi record UNITS cua file GDS de chuyen giua khong gian 1x va 4x.

ASAP7 co hai he toa do.  GDS cua PDK va cua SRAM la 1x, ghi o 4000 dbu/um.
Database Innovus cua project nay la 4x, va streamOut ghi ra 1000 dbu/um.
Cung MOT day so nguyen, doc o 4000 thi ra 1x, doc o 1000 thi ra 4x.

Script chi sua 16 byte cua record UNITS, KHONG dong vao mot toa do nao.  Nho
vay phep chuyen la chinh xac tuyet doi, khong lam tron, khong mat hinh.

  python gds_rescale.py srambank_128b.gds srambank_128b_4x.gds --dbu 1000
  python gds_rescale.py top_soc.gds top_soc_1x.gds --dbu 4000

Kiem lai bang: python gds_bbox.py <file moi>
"""
import struct, sys, argparse


def _real8(b):
    exp = (b[0] & 0x7f) - 64
    v = int.from_bytes(b[1:], 'big') / float(1 << 56) * (16.0 ** exp)
    return -v if b[0] & 0x80 else v


def _to_real8(x):
    """So thuc -> 8 byte excess-64 base-16 cua GDS."""
    if x == 0:
        return b'\x00' * 8
    sign = 0x80 if x < 0 else 0
    x = abs(x)
    exp = 0
    while x >= 1.0:
        x /= 16.0; exp += 1
    while x < 1.0 / 16.0:
        x *= 16.0; exp -= 1
    mant = int(round(x * (1 << 56)))
    if mant >= (1 << 56):          # lam tron tran
        mant >>= 4; exp += 1
    return bytes([sign | (exp + 64)]) + mant.to_bytes(7, 'big')


def rescale(src, dst, dbu_per_um):
    data = bytearray(open(src, 'rb').read())
    i = 0
    while i < len(data) - 3:
        ln = struct.unpack('>H', data[i:i + 2])[0]
        if ln < 4:
            break
        if data[i + 2] == 0x03 and data[i + 3] == 0x05:      # UNITS
            old_uu, old_m = _real8(data[i + 4:i + 12]), _real8(data[i + 12:i + 20])
            new_uu = 1.0 / dbu_per_um          # 1 dbu tinh bang micron
            new_m = 1e-6 / dbu_per_um          # 1 dbu tinh bang met
            data[i + 4:i + 12] = _to_real8(new_uu)
            data[i + 12:i + 20] = _to_real8(new_m)
            print("UNITS: %g dbu/um  ->  %g dbu/um   (moi hinh to len %.4gx)"
                  % (1e-6 / old_m, dbu_per_um, new_m / old_m))
            open(dst, 'wb').write(bytes(data))
            print("da ghi", dst)
            return 0
        i += ln
    print("LOI: khong tim thay record UNITS trong", src)
    return 1


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('src'); p.add_argument('dst')
    p.add_argument('--dbu', type=float, required=True,
                   help='dbu/um MOI (1000 = khong gian 4x, 4000 = 1x)')
    a = p.parse_args()
    sys.exit(rescale(a.src, a.dst, a.dbu))
