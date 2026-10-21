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

# Deck ASAP7 (rul/calibreLVS.rul) tu khai bao LVS REPORT mask.lvs.rep (dong 52)
# va LVS POWER NAME "vdd!" "VDD!" / LVS GROUND NAME "VSS!" "vss!" (dong 23-24),
# trong khi net nguon cua thiet ke la VDD / VSS.  Header khai bao lai ca ba,
# nen INCLUDE ban chep da comment dung 3 dong do (LVS REPORT OPTION / MAXIMUM
# giu nguyen).
deck=asap7_lvs.rul
tag='// [run_lvs.sh]'
sed -E "s#^[[:space:]]*(LVS[[:space:]]+REPORT[[:space:]]+[^[:space:]]+[[:space:]]*\$|LVS[[:space:]]+(POWER|GROUND)[[:space:]]+NAME[[:space:]])#$tag &#" \
    "$LVS_DECK" > $deck
n=$(grep -cF "$tag" $deck)
if [ "$n" != 3 ]; then
    echo "ERROR: comment duoc $n/3 lenh trong $LVS_DECK - deck da doi, sua run_lvs.sh"
    exit 1
fi

# print cal header
cal=run.lvs.cal
echo "LAYOUT PRIMARY \"$DESIGN\""                       > $cal
echo "LAYOUT PATH \"$GDS_FILE\""                       >> $cal
echo "LAYOUT SYSTEM GDSII"                             >> $cal
echo "SOURCE PRIMARY \"$DESIGN\""                      >> $cal
echo "SOURCE PATH \"$PWD/$DESIGN.source.net\""         >> $cal
echo "SOURCE SYSTEM SPICE"                             >> $cal
echo "LVS REPORT \"$DESIGN.lvs.report\""               >> $cal
echo "ERC RESULTS DATABASE \"$DESIGN.erc.db\" ASCII"   >> $cal
echo "ERC SUMMARY REPORT \"$DESIGN.lvs.summary\" REPLACE HIER" >> $cal
echo "LVS POWER NAME \"VDD\" \"vdd!\" \"VDD!\""        >> $cal
echo "LVS GROUND NAME \"VSS\" \"VSS!\" \"vss!\""       >> $cal
echo "LVS BOX $(tr '\n' ' ' < lvs_box.list)"           >> $cal

# include main rule file
echo "INCLUDE \"$PWD/$deck\""                          >> $cal

# run lvs (file rule de cuoi cung)
$CALIBRE -64 -lvs -hier -spice $DESIGN.extracted.net -turbo $CORES $HYPER \
    -hcell hcell.list $cal
