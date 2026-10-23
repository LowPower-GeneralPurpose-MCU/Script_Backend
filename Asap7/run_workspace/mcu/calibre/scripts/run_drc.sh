#!/bin/bash
# Calibre DRC cho top_soc, khung pv/scripts/run_drc.sh cua thay: header
# run.drc.cal + INCLUDE deck.  Chay trong run_drc/ (Makefile goi).
source ../scripts/sourceme

# Deck ASAP7 tu khai bao 6 lenh dac ta (rul/calibreDRC.rul dong 30-34, 37):
# LAYOUT SYSTEM, LAYOUT PATH "./test.gds", LAYOUT PRIMARY TOPCELL,
# DRC SUMMARY REPORT, DRC RESULTS DATABASE, LAYOUT PRECISION 4000.  Header
# khai bao lai thi trung lenh (LAYOUT PATH con doc them ./test.gds), nen
# INCLUDE ban chep da comment dung 6 dong do.  LAYOUT PRECISION phai bang
# precision that cua GDS (KHOI 16 ghi 2000 dbu/um, gen_env.tcl doc tu ban ghi
# UNITS): de 4000 thi Calibre dung ngay khi doc GDS.  PRECISION 10000 va
# LAYOUT MAGNIFY AUTO giu nguyen - Calibre tu nhan toa do GDS len luoi deck.
deck=asap7_drc.rul
tag='// [run_drc.sh]'
sed -E "s#^[[:space:]]*(LAYOUT[[:space:]]+(SYSTEM|PATH|PRIMARY|PRECISION)|DRC[[:space:]]+(SUMMARY[[:space:]]+REPORT|RESULTS[[:space:]]+DATABASE))[[:space:]]#$tag &#" \
    "$DRC_DECK" > $deck
n=$(grep -cF "$tag" $deck)
if [ "$n" != 6 ]; then
    echo "ERROR: comment duoc $n/6 lenh dac ta trong $DRC_DECK - deck da doi, sua run_drc.sh"
    exit 1
fi

# Precision GDS + offset luat track M4-M7 (VARIABLE ... ENVIRONMENT), tinh o
# gen_env.tcl tu GDS / DEF
for v in GDS_PRECISION VAR_M4_YOFFSET VAR_M5_XOFFSET VAR_M6_YOFFSET VAR_M7_XOFFSET; do
    if [ -z "${!v}" ]; then
        echo "ERROR: $v chua dat - chay qua make (gen_env.tcl)"
        exit 1
    fi
    echo "INFO: $v=${!v}"
done

# ---- Nhom luat ---------------------------------------------------------------
# Lan 2026-10-22 chay ca 334 rule trong mot lan Calibre -hyper: 726/1009 ops
# sau 18.4 h thi may 13 GB het RAM va he thong giet ca make, khong con ket qua
# nao.  Chia deck theo lop, moi nhom mot lan Calibre rieng chi chon rule cua
# nhom (DRC SELECT CHECK): Calibre chi doc / tinh cac lop nhom do can, RAM tra
# lai giua hai nhom, nhom bi giet khong lam mat nhom da xong.
ALL_GROUPS="feol m1_m3 m4_m5 m6_m7 m8_m9"
rule_group() {
    case ${1%%.*} in
        GEOMETRY|WELL|FIN|GATE|ACTIVE|SRAM|GCUT|NSELECT|PSELECT|SLVT|LVT|SRAMVT|VT|DUMMY|SDT|LISD|LIG|V0)
                            echo feol ;;
        M1|M2|M3|V1|V2|V3)  echo m1_m3 ;;
        M4|M5|V4)           echo m4_m5 ;;
        M6|M7|V5|V6)        echo m6_m7 ;;
        V7|M8|M9|V8|V9)     echo m8_m9 ;;
    esac
}

# Ten rule = ten khoi "TEN {" (dau { co the o dong sau): 334 ten, trung dung
# danh sach SELECTED RULE CHECKS cua log Calibre 2026-10-21.
awk '
{ line = $0; sub(/\/\/.*/, "", line) }
line ~ /^[ \t]*[A-Za-z0-9_.]+[ \t]*\{[ \t]*$/ { gsub(/[ \t{]/, "", line); print line; prev = ""; next }
line ~ /^[ \t]*\{[ \t]*$/ && prev != "" { print prev; prev = ""; next }
{ t = line; gsub(/^[ \t]+|[ \t]+$/, "", t); if (t != "") prev = (t ~ /^[A-Za-z0-9_.]+$/) ? t : "" }
' $deck > rules.all
if [ ! -s rules.all ]; then
    echo "ERROR: khong doc duoc ten rule nao trong $DRC_DECK"
    exit 1
fi
for g in $ALL_GROUPS; do
    : > rules_$g.list
done
while read -r r; do
    g=$(rule_group "$r")
    if [ -z "$g" ]; then
        echo "ERROR: rule $r khong thuoc nhom nao - deck da doi, sua rule_group trong run_drc.sh"
        exit 1
    fi
    echo "$r" >> rules_$g.list
done < rules.all
: > groups.list
for g in $ALL_GROUPS; do
    echo "$g $(wc -l < rules_$g.list)" >> groups.list
done
echo "INFO: $(wc -l < rules.all) rule: $(tr '\n' ' ' < groups.list)"

groups=${DRC_GROUPS:-$ALL_GROUPS}
for g in $groups; do
    if [ ! -f rules_$g.list ]; then
        echo "ERROR: DRC_GROUPS co nhom '$g' khong ton tai (co: $ALL_GROUPS)"
        exit 1
    fi
done

for g in $groups; do
    cal=run.drc.$g.cal
    log=calibre_drc_$g.log
    rm -f $DESIGN.$g.drc.db $DESIGN.$g.drc.sum $log

    # print cal header
    echo "LAYOUT PRIMARY \"$DESIGN\""                        > $cal
    echo "LAYOUT PATH \"$GDS_FILE\""                        >> $cal
    echo "LAYOUT SYSTEM GDSII"                              >> $cal
    echo "LAYOUT PRECISION $GDS_PRECISION"                  >> $cal
    echo "DRC RESULTS DATABASE \"$DESIGN.$g.drc.db\" ASCII" >> $cal
    echo "DRC SUMMARY REPORT \"$DESIGN.$g.drc.sum\" HIER"   >> $cal
    echo "DRC MAXIMUM RESULTS $DRC_MAX_RESULTS"             >> $cal
    sed 's/^/DRC SELECT CHECK /' rules_$g.list              >> $cal

    # include main rule file
    echo "INCLUDE \"$PWD/$deck\""                           >> $cal

    # run drc
    echo "INFO: nhom $g ($(wc -l < rules_$g.list) rule) bat dau $(date '+%F %T'), log run_drc/$log"
    $CALIBRE -64 -drc -hier -turbo $CORES $HYPER $cal 2>&1 | tee $log
    echo "INFO: nhom $g ket thuc $(date '+%F %T'), ma thoat calibre ${PIPESTATUS[0]}"
done
