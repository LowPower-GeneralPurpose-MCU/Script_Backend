#!/bin/bash
source ../scripts/sourceme

cal=run.ant.cal
echo "LAYOUT PRIMARY \"$DESIGN\""      > $cal

# N?p GDS thi?t k? và toàn b? GDS thu vi?n
echo -n "LAYOUT PATH \"$GDS_FILE\" " >> $cal
for gds in ../../../../tkvm/asap7/asap7sc7p5t_28/GDS/*.gds; do
    if [ -f "$gds" ]; then
        echo -n "\"$gds\" " >> $cal
    fi
done
echo "" >> $cal

# Khai báo d?nh d?ng và noi luu báo cáo
echo "LAYOUT SYSTEM GDSII"             >> $cal
echo "DRC RESULTS DATABASE \"$DESIGN.ant.db\" ASCII" >> $cal
echo "DRC SUMMARY REPORT \"$DESIGN.ant.sum\" HIER" >> $cal

echo "INCLUDE \"$ANT_DECK\"" >> $cal

calibre -64 -drc -hier -turbo $CORES -hyper $cal