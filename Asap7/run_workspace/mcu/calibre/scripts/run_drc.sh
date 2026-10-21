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

# print cal header
cal=run.drc.cal
echo "LAYOUT PRIMARY \"$DESIGN\""                     > $cal
echo "LAYOUT PATH \"$GDS_FILE\""                     >> $cal
echo "LAYOUT SYSTEM GDSII"                           >> $cal
echo "LAYOUT PRECISION $GDS_PRECISION"               >> $cal
echo "DRC RESULTS DATABASE \"$DESIGN.drc.db\" ASCII" >> $cal
echo "DRC SUMMARY REPORT \"$DESIGN.drc.sum\" HIER"   >> $cal
echo "DRC MAXIMUM RESULTS $DRC_MAX_RESULTS"          >> $cal

# include main rule file
echo "INCLUDE \"$PWD/$deck\""                        >> $cal

# run drc
$CALIBRE -64 -drc -hier -turbo $CORES $HYPER $cal
