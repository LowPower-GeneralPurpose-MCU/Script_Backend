#!/bin/bash
# Calibre DRC cho top_soc, khung pv/scripts/run_drc.sh cua thay: header
# run.drc.cal + INCLUDE deck.  Chay trong run_drc/ (Makefile goi).
source ../scripts/sourceme

# Deck ASAP7 tu khai bao 5 lenh dac ta (rul/calibreDRC.rul dong 30-34):
# LAYOUT SYSTEM, LAYOUT PATH "./test.gds", LAYOUT PRIMARY TOPCELL,
# DRC SUMMARY REPORT, DRC RESULTS DATABASE.  Header khai bao lai thi trung
# lenh (LAYOUT PATH con doc them ./test.gds), nen INCLUDE ban chep da comment
# dung 5 dong do.  LAYOUT PRECISION 4000 / LAYOUT MAGNIFY AUTO giu nguyen:
# GDS cua Innovus ghi 2000 dbu/um.
deck=asap7_drc.rul
tag='// [run_drc.sh]'
sed -E "s#^[[:space:]]*(LAYOUT[[:space:]]+(SYSTEM|PATH|PRIMARY)|DRC[[:space:]]+(SUMMARY[[:space:]]+REPORT|RESULTS[[:space:]]+DATABASE))[[:space:]]#$tag &#" \
    "$DRC_DECK" > $deck
n=$(grep -cF "$tag" $deck)
if [ "$n" != 5 ]; then
    echo "ERROR: comment duoc $n/5 lenh dac ta trong $DRC_DECK - deck da doi, sua run_drc.sh"
    exit 1
fi

# Offset luat track M4-M7 (VARIABLE ... ENVIRONMENT), tinh tu DEF o gen_env.tcl
for v in VAR_M4_YOFFSET VAR_M5_XOFFSET VAR_M6_YOFFSET VAR_M7_XOFFSET; do
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
echo "DRC RESULTS DATABASE \"$DESIGN.drc.db\" ASCII" >> $cal
echo "DRC SUMMARY REPORT \"$DESIGN.drc.sum\" HIER"   >> $cal
echo "DRC MAXIMUM RESULTS $DRC_MAX_RESULTS"          >> $cal

# include main rule file
echo "INCLUDE \"$PWD/$deck\""                        >> $cal

# run drc
$CALIBRE -64 -drc -hier -turbo $CORES $HYPER $cal
