#!/bin/bash
source ../scripts/sourceme

cal=run.lvs.cal
echo "LAYOUT PRIMARY \"$DESIGN\""        > $cal

echo -n "LAYOUT PATH \"$GDS_FILE\" " >> $cal
for gds in ../../../../tkvm/asap7/asap7sc7p5t_28/GDS/*.gds; do
    if [ -f "$gds" ]; then
        echo -n "\"$gds\" " >> $cal
    fi
done
echo "" >> $cal

echo "LAYOUT SYSTEM GDSII"               >> $cal
echo "SOURCE PRIMARY \"$DESIGN\""        >> $cal
echo "SOURCE PATH \"$DESIGN.v2lvs.net\"" >> $cal
echo "SOURCE SYSTEM SPICE"               >> $cal
echo "#DEFINE CAL_XRC NO //(YES/NO/CCI)" >> $cal

if [ ! -z "$LVS_BOX" ]; then
    echo "LVS BOX $LVS_BOX" >> $cal
fi

echo "INCLUDE \"$LVS_DECK\"" >> $cal

if [ ! -f hcell.list ]; then
    echo "$DESIGN $DESIGN" > hcell.list
fi

calibre -64 -turbo $CORES -hyper -spice $DESIGN.extracted.net -lvs $cal -hier -hcell hcell.list