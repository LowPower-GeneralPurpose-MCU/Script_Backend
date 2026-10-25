#!/bin/bash
# Thu license Calibre DRC (make drc_lic), vai phut, khong chay rule nao.
# Lan 2026-10-25 nhom feol cua make drc dung o "Unable to acquire the first
# license" ca khi da tra ve -turbo 4 -hyper nhu lan 2026-10-21 (lay duoc
# license).  So voi lan 2026-10-22 (lay duoc license, chay 18.4 h), file cal
# Calibre doc chi khac o cac dong DRC SELECT CHECK.  Hai lan Calibre, cung
# option va cung deck voi make drc:
#   A  run_drc/run.drc.feol.cal bo het DRC SELECT CHECK (= header lan 2026-10-22)
#   B  run_drc/run.drc.feol.cal nguyen ven (= file vua hong)
# LAYOUT PRECISION co y sai (x2): Calibre lay license xong moi doc GDS va dung
# ngay o loi precision, nhu lan 2026-10-21 15:58.  Chay trong run_lic/.
source ../scripts/sourceme

src=../run_drc/run.drc.feol.cal
if [ ! -f $src ]; then
    echo "ERROR: chua co run_drc/run.drc.feol.cal - chay make drc truoc (dung o license cung duoc)"
    exit 1
fi

echo "INFO: MGLS_LICENSE_FILE='$MGLS_LICENSE_FILE'"
echo "INFO: LM_LICENSE_FILE='$LM_LICENSE_FILE'"
echo "INFO: SALT_LICENSE_SERVER='$SALT_LICENSE_SERVER'"
echo "INFO: tien trinh calibre / license daemon dang chay (con giu license thi kill truoc):"
ps -eo pid,stat,etime,cmd | grep -E -i '[c]alibre|[l]mgrd|[m]gcld|[s]altd' || echo "    (khong co)"

bad=$((GDS_PRECISION * 2))
sed -E "s/^LAYOUT PRECISION .*/LAYOUT PRECISION $bad/" $src > probe_B.cal
grep -v '^DRC SELECT CHECK ' probe_B.cal > probe_A.cal
if [ "$(grep -c "^LAYOUT PRECISION $bad\$" probe_B.cal)" != 1 ] ||
   [ "$(grep -c '^DRC SELECT CHECK ' probe_B.cal)" = 0 ]; then
    echo "ERROR: $src khong co dung 1 dong LAYOUT PRECISION hoac khong co DRC SELECT CHECK - run_drc.sh da doi"
    exit 1
fi

# Ket qua vao bien result: OK / FAIL / ? (khong thay dong license nao)
probe() {
    local name=$1 cal=probe_$1.cal log=calibre_lic_$1.log rc
    echo "INFO: thu $name ($(grep -c '^DRC SELECT CHECK ' $cal) dong DRC SELECT CHECK) bat dau $(date '+%F %T')"
    $CALIBRE -64 -drc -hier -turbo $CORES $HYPER $cal > $log 2>&1
    rc=$?
    echo "INFO: thu $name ket thuc $(date '+%F %T'), ma thoat calibre $rc, log logs/$log"
    grep -E '^--- CALIBRE::DRC-H - |license acquired|could not be licensed|^(//  )?ERROR' $log | sed 's/^/    /'
    cp $log ../logs/
    if grep -q 'license acquired' $log; then
        result=OK
    elif grep -q 'could not be licensed' $log; then
        result=FAIL
    else
        result=?
    fi
}

probe A
a=$result
if [ $a = FAIL ]; then
    echo "KET LUAN: A (khong DRC SELECT CHECK, nhu lan 2026-10-22) cung khong lay duoc license:"
    echo "          loi o license server / moi truong cua may, khong phai script. Bo qua B."
    exit 1
fi
probe B
b=$result
if [ $a = OK ] && [ $b = FAIL ]; then
    echo "KET LUAN: A lay duoc license, B khong: DRC SELECT CHECK lam hong license - phai bo no khoi run_drc.sh"
    exit 1
elif [ $a = OK ] && [ $b = OK ]; then
    echo "KET LUAN: ca A va B deu lay duoc license luc nay - chay lai make drc"
else
    echo "KET LUAN: khong ro (A=$a, B=$b) - xem logs/calibre_lic_A.log, logs/calibre_lic_B.log"
    exit 1
fi
