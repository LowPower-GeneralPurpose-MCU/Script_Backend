############################################################
## Deterministic 4-row x 8-column SRAM island
############################################################

proc snap_up {value grid} {
    return [expr {ceil(double($value) / $grid) * $grid}]
}

proc sram_bank_index {name fallback} {
    if {[regexp {G_SRAM_BANK[^0-9]*([0-9]+)} $name -> index]} {
        return $index
    }
    return $fallback
}

set SITE_GRID 0.216
set ROW_HEIGHT 1.080
set MACRO_GAP [expr {4.0 * $ROW_HEIGHT}]
set MACRO_HALO [expr {2.0 * $ROW_HEIGHT}]
set EDGE_GAP 10.0
set CORE_MARGIN 10.0

set sram_ptrs [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {$sram_ptrs eq "" || $sram_ptrs eq "0x0"} {
    error "No physical instances found for SRAM master $SRAM_MASTER"
}
if {[llength $sram_ptrs] != $SRAM_EXPECTED_COUNT} {
    error "Expected $SRAM_EXPECTED_COUNT SRAM macros, found [llength $sram_ptrs]"
}

set records {}
set fallback 0
foreach ptr $sram_ptrs {
    set name [lindex [dbGet $ptr.name] 0]
    lappend records [list [sram_bank_index $name $fallback] $name $ptr]
    incr fallback
}
set records [lsort -integer -index 0 $records]

set seen {}
foreach record $records {
    set bank [lindex $record 0]
    if {$bank < 0 || $bank >= $SRAM_EXPECTED_COUNT ||
        [lsearch -exact $seen $bank] >= 0} {
        error "Invalid or duplicate SRAM bank index $bank"
    }
    lappend seen $bank
}

set first_ptr [lindex [lindex $records 0] 2]
set SRAM_W [expr {double([dbGet $first_ptr.cell.size_x])}]
set SRAM_H [expr {double([dbGet $first_ptr.cell.size_y])}]
set SRAM_ARRAY_W [expr {
    $SRAM_COLS * $SRAM_W + ($SRAM_COLS - 1) * $MACRO_GAP
}]
set SRAM_ARRAY_H [expr {
    $SRAM_ROWS * $SRAM_H + ($SRAM_ROWS - 1) * $MACRO_GAP
}]

set STD_CELL_AREA 0.0
set std_ptrs [dbGet -p2 top.insts.cell.baseClass core]
if {$std_ptrs ne "" && $std_ptrs ne "0x0"} {
    foreach ptr $std_ptrs {
        set cell_area [dbGet $ptr.cell.area]
        if {[string is double -strict $cell_area]} {
            set STD_CELL_AREA [expr {$STD_CELL_AREA + double($cell_area)}]
        }
    }
}

set LOGIC_AREA_REQUIRED [expr {
    $STD_CELL_AREA / $MCU_TARGET_STD_UTIL
}]
set LOGIC_SIDE [expr {sqrt(max($LOGIC_AREA_REQUIRED, 1.0))}]
set LOGIC_W [expr {max(500.0, $LOGIC_SIDE)}]
set LOGIC_H [expr {max($SRAM_ARRAY_H, $LOGIC_SIDE)}]

set CORE_W [snap_up \
    [expr {$EDGE_GAP + $SRAM_ARRAY_W + 20.0 + $LOGIC_W + $EDGE_GAP}] \
    $SITE_GRID]
set CORE_H [snap_up \
    [expr {$EDGE_GAP + $LOGIC_H + $EDGE_GAP}] \
    $SITE_GRID]

if {$MCU_CORE_WIDTH_OVERRIDE > 0.0} {
    set CORE_W [snap_up $MCU_CORE_WIDTH_OVERRIDE $SITE_GRID]
}
if {$MCU_CORE_HEIGHT_OVERRIDE > 0.0} {
    set CORE_H [snap_up $MCU_CORE_HEIGHT_OVERRIDE $SITE_GRID]
}

set MIN_CORE_W [expr {2.0 * $EDGE_GAP + $SRAM_ARRAY_W}]
set MIN_CORE_H [expr {2.0 * $EDGE_GAP + $SRAM_ARRAY_H}]
if {$CORE_W < $MIN_CORE_W || $CORE_H < $MIN_CORE_H} {
    error "Core override is too small for the 4x8 SRAM island"
}

floorPlan \
    -s $CORE_W $CORE_H \
    $CORE_MARGIN $CORE_MARGIN $CORE_MARGIN $CORE_MARGIN

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set x0 [snap_up [expr {$core_llx + $EDGE_GAP}] $SITE_GRID]
set y0 [snap_up [expr {$core_lly + $EDGE_GAP}] $SITE_GRID]

file mkdir ./reports
set map_fp [open ./reports/sram_macro_map.rpt w]
puts $map_fp "bank instance row col x y orient"

foreach record $records {
    set bank [lindex $record 0]
    set name [lindex $record 1]
    set ptr  [lindex $record 2]
    set row [expr {int($bank / $SRAM_COLS)}]
    set col [expr {$bank % $SRAM_COLS}]
    set x [snap_up [expr {$x0 + $col * ($SRAM_W + $MACRO_GAP)}] $SITE_GRID]
    set y [snap_up [expr {$y0 + $row * ($SRAM_H + $MACRO_GAP)}] $SITE_GRID]
    set orient [expr {$col % 2 == 0 ? "R0" : "MY"}]

    dbSet $ptr.pStatus unplaced
    placeInstance $name $x $y $orient
    dbSet $ptr.pStatus fixed
    puts $map_fp "$bank $name $row $col $x $y $orient"
}
close $map_fp

addHaloToBlock \
    -allBlock \
    $MACRO_HALO $MACRO_HALO $MACRO_HALO $MACRO_HALO

set block_urx [expr {$x0 + $SRAM_ARRAY_W}]
set block_ury [expr {$y0 + $SRAM_ARRAY_H}]
catch {deletePlaceBlockage SRAM_ISLAND_BLOCKAGE}
createPlaceBlockage \
    -name SRAM_ISLAND_BLOCKAGE \
    -type hard \
    -box [list $x0 $y0 $block_urx $block_ury]

puts "============================================================"
puts "MCU SRAM FLOORPLAN CREATED"
puts " - Core         : $CORE_W x $CORE_H um"
puts " - Stdcell area : $STD_CELL_AREA um^2"
puts " - Target util  : $MCU_TARGET_STD_UTIL"
puts " - SRAM island  : $SRAM_ARRAY_W x $SRAM_ARRAY_H um"
puts " - SRAM grid    : $SRAM_ROWS rows x $SRAM_COLS columns"
puts "============================================================"

