#!/bin/bash
# Calibre LVS cho top_soc, khung pv/scripts/run_lvs.sh cua thay: header
# run.lvs.cal + INCLUDE deck.  Chay trong run_lvs/ sau scripts/v2lvs.tcl.
source ../scripts/sourceme

for f in "$DESIGN.source.net" hcell.list lvs_box.list; do
    if [ ! -s "$f" ]; then
        echo "ERROR: thieu run_lvs/$f - v2lvs.tcl hong, doc ../logs/calibre_v2lvs.log"
        exit 1
    fi
done
# Deck LVS khong khai LAYOUT PRECISION nen Calibre lay bang precision 4000 cua
# deck, khac 2000 dbu/um cua GDS -> loi nhu DRC 2026-10-21.  Khai o header theo
# ban ghi UNITS cua GDS (gen_env.tcl).  LAYOUT PRECISION chi la don vi, KHONG
# phong toa do: LVS 2026-10-21 19:22 chi co no -> "LAYOUT MAGNIFICATION = 1",
# Calibre doc dbu 2000 theo luoi 4000 cua deck, moi hinh nho con 1/2 (l 0.01
# vs 0.02 um, nfin 1.5 vs 3: 234 cell Property errors).  Them LAYOUT MAGNIFY
# AUTO nhu deck DRC (x PRECISION deck / precision GDS = x2).
if [ -z "$GDS_PRECISION" ]; then
    echo "ERROR: GDS_PRECISION chua dat - chay qua make (gen_env.tcl)"
    exit 1
fi
if grep -qiE '^[[:space:]]*LAYOUT[[:space:]]+MAGNIFY' "$LVS_DECK"; then
    echo "ERROR: $LVS_DECK da co LAYOUT MAGNIFY - bo dong do o header run_lvs.sh"
    exit 1
fi

# Deck ASAP7 (rul/calibreLVS.rul) tu khai bao LVS REPORT mask.lvs.rep (dong 52)
# va LVS POWER NAME "vdd!" "VDD!" / LVS GROUND NAME "VSS!" "vss!" (dong 23-24),
# trong khi net nguon cua thiet ke la VDD / VSS.  Header khai bao lai ca ba,
# nen INCLUDE ban chep da comment dung 3 dong do (LVS REPORT OPTION / MAXIMUM
# giu nguyen).
# Dong 47 LVS RECOGNIZE GATES NONE: LVS 2026-10-22 01:29 top_soc CORRECT nhung
# 23 std cell INCORRECT chi vi GDS va CDL cua thu vien xep transistor trong
# chong noi tiep khac thu tu (AO21x1: A1/A2 doi cho o in1/in2 cua _nand2b;
# AOI211xp5/XOR2x2: transistor o dau VDD/VSS khac nhau) - tuong duong logic.
# Header dat lai LVS RECOGNIZE GATES (mac dinh ALL: input tuong duong cua cong
# nhan dang duoc phep doi cho); LVS_RECOGNIZE_GATES=NONE = dung y deck goc.
deck=asap7_lvs.rul
tag='// [run_lvs.sh]'
sed -E "s#^[[:space:]]*(LVS[[:space:]]+REPORT[[:space:]]+[^[:space:]]+[[:space:]]*\$|LVS[[:space:]]+(POWER|GROUND)[[:space:]]+NAME[[:space:]]|LVS[[:space:]]+RECOGNIZE[[:space:]]+GATES[[:space:]])#$tag &#" \
    "$LVS_DECK" > $deck
n=$(grep -cF "$tag" $deck)
if [ "$n" != 4 ]; then
    echo "ERROR: comment duoc $n/4 lenh trong $LVS_DECK - deck da doi, sua run_lvs.sh"
    exit 1
fi

# print cal header
cal=run.lvs.cal
echo "LAYOUT PRIMARY \"$DESIGN\""                       > $cal
echo "LAYOUT PATH \"$GDS_FILE\""                       >> $cal
echo "LAYOUT SYSTEM GDSII"                             >> $cal
echo "LAYOUT PRECISION $GDS_PRECISION"                 >> $cal
echo "LAYOUT MAGNIFY AUTO"                             >> $cal
echo "SOURCE PRIMARY \"$DESIGN\""                      >> $cal
echo "SOURCE PATH \"$PWD/$DESIGN.source.net\""         >> $cal
echo "SOURCE SYSTEM SPICE"                             >> $cal
echo "LVS REPORT \"$DESIGN.lvs.report\""               >> $cal
echo "ERC RESULTS DATABASE \"$DESIGN.erc.db\" ASCII"   >> $cal
echo "ERC SUMMARY REPORT \"$DESIGN.lvs.summary\" REPLACE HIER" >> $cal
echo "LVS POWER NAME \"VDD\" \"vdd!\" \"VDD!\""        >> $cal
echo "LVS GROUND NAME \"VSS\" \"VSS!\" \"vss!\""       >> $cal
echo "LVS BOX $(tr '\n' ' ' < lvs_box.list)"           >> $cal
echo "LVS RECOGNIZE GATES ${LVS_RECOGNIZE_GATES:-ALL}"  >> $cal

# include main rule file
echo "INCLUDE \"$PWD/$deck\""                          >> $cal

# run lvs (file rule de cuoi cung)
$CALIBRE -64 -lvs -hier -spice $DESIGN.extracted.net -turbo $CORES $HYPER \
    -hcell hcell.list $cal
