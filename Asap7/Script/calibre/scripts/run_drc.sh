#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

source "$SCRIPT_DIR/sourceme"

: "${DESIGN:?ERROR: DESIGN is not set}"
: "${GDS_FILE:?ERROR: GDS_FILE is not set}"
: "${DRC_DECK:?ERROR: DRC_DECK is not set}"
: "${CORES:?ERROR: CORES is not set}"

if [ ! -f "$GDS_FILE" ]; then
    echo "ERROR: Top GDS not found: $GDS_FILE"
    exit 1
fi

if [ ! -f "$DRC_DECK" ]; then
    echo "ERROR: DRC deck not found: $DRC_DECK"
    exit 1
fi


for var in $(grep "VARIABLE .* ENVIRONMENT" "$DRC_DECK" | awk '{print $2}' | sort -u); do
    if [ -z "${!var:-}" ]; then
        export "$var=0"
        echo "INFO: $var was not set. Defaulting to 0."
    else
        echo "INFO: $var=${!var}"
    fi
done

layout_path="LAYOUT PATH                     \"$GDS_FILE\""

cal=run.drc.cal

awk \
-v layout_path="$layout_path" \
-v top="$DESIGN" \
-v sum="$DESIGN.drc.sum" \
-v db="$DESIGN.drc.db" '
/^[ \t]*LAYOUT[ \t]+PATH[ \t]+/ {
    print layout_path
    next
}
/^[ \t]*LAYOUT[ \t]+PRIMARY[ \t]+/ {
    print "LAYOUT PRIMARY                  " top
    next
}
/^[ \t]*DRC[ \t]+SUMMARY[ \t]+REPORT[ \t]+/ {
    print "DRC SUMMARY REPORT              \"" sum "\" HIER"
    next
}
/^[ \t]*DRC[ \t]+RESULTS[ \t]+DATABASE[ \t]+/ {
    print "DRC RESULTS DATABASE            \"" db "\" ASCII"
    print "DRC MAXIMUM RESULTS             1000"
    next
}
/^[ \t]*DRC[ \t]+MAXIMUM[ \t]+RESULTS[ \t]+/ {
    next
}
{
    print
}
' "$DRC_DECK" > "$cal"

echo "============================================================"
echo "Generated ASAP7 DRC deck: $cal"
echo "DESIGN        = $DESIGN"
echo "TOP GDS       = $GDS_FILE"
echo "DRC DECK      = $DRC_DECK"
echo "CORES         = $CORES"
echo "MAX RESULTS   = 1000 per rule"
echo "============================================================"

grep -n "LAYOUT SYSTEM\|LAYOUT PATH\|LAYOUT PRIMARY\|DRC SUMMARY\|DRC RESULTS\|DRC MAXIMUM\|PRECISION" "$cal" | head -30

echo "============================================================"
echo "Checking if INCLUDE still exists..."
grep -n "INCLUDE" "$cal" | head || true
echo "============================================================"

calibre -64 -drc -hier -turbo "$CORES" -hyper "$cal" | tee "$DESIGN.drc.log"
