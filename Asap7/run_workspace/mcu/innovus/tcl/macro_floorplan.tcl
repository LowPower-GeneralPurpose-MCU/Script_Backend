############################################################
## Deterministic MCU SRAM floorplan: three macro islands, left to right
##   RAM   : SRAM_RAM_ROWS   x SRAM_RAM_COLS   64 x 256x4x32 (u_axi_ram_lo/hi)
##   cache : SRAM_CACHE_ROWS x SRAM_CACHE_COLS 16 x 256x4x32 (cache data + TCM)
##   tag   : SRAM_TAG_ROWS   x SRAM_TAG_COLS    4 x 128x4x20 (cache tags)
## then the standard-cell region.  Grids come from project_config.tcl.
############################################################

proc snap_up {value grid} {
    return [expr {ceil(double($value) / $grid) * $grid}]
}

# Place one island column-major, so a column holds consecutive instances in
# name order (e.g. D-cache data then DTCM in the cache island's first column).
proc place_island {island records rows cols x0 y0 w h gap map_fp} {
    set index 0
    foreach record $records {
        lassign $record name ptr
        set col [expr {$index / $rows}]
        set row [expr {$index % $rows}]
        set x [snap_up [expr {$x0 + $col * ($w + $gap)}] $::SITE_GRID]
        set y [snap_up [expr {$y0 + $row * ($h + $gap)}] $::SITE_GRID]
        set orient [expr {$col % 2 == 0 ? "R0" : "MY"}]

        dbSet $ptr.pStatus unplaced
        placeInstance $name $x $y $orient
        dbSet $ptr.pStatus fixed
        puts $map_fp "$island $index $name $row $col $x $y $orient"
        incr index
    }
}

set SITE_GRID   0.216
set ROW_HEIGHT  1.080
set MACRO_GAP   [expr {4.0 * $ROW_HEIGHT}]
set MACRO_HALO  [expr {2.0 * $ROW_HEIGHT}]
set EDGE_GAP    10.0
set ISLAND_GAP  20.0
set CORE_MARGIN 10.0

# ------------------------------------------------------------------------
# Collect and classify the macro instances
# ------------------------------------------------------------------------
# Sort by name with -dictionary so G_SRAM_BANK[10] follows G_SRAM_BANK[9].
set ram_records   {}
set cache_records {}
set tag_records   {}
foreach {master expected} [list \
    $SRAM_MASTER $SRAM_EXPECTED_COUNT $SRAM_TAG_MASTER $SRAM_TAG_EXPECTED_COUNT] {
    set ptrs [dbGet -p2 top.insts.cell.name $master]
    if {$ptrs eq "" || $ptrs eq "0x0"} {
        error "No physical instances found for SRAM master $master"
    }
    if {[llength $ptrs] != $expected} {
        error "Expected $expected x $master, found [llength $ptrs]"
    }
    set records {}
    foreach ptr $ptrs {
        lappend records [list [lindex [dbGet $ptr.name] 0] $ptr]
    }
    foreach record [lsort -dictionary -index 0 $records] {
        if {$master eq $SRAM_TAG_MASTER} {
            lappend tag_records $record
        } elseif {[string match "u_axi_ram_*" [lindex $record 0]]} {
            lappend ram_records $record
        } else {
            lappend cache_records $record
        }
    }
}

set CACHE_ISLAND_COUNT [expr {$SRAM_EXPECTED_COUNT - $SRAM_RAM_COUNT}]
foreach {island records count rows cols} [list \
    RAM   $ram_records   $SRAM_RAM_COUNT          $SRAM_RAM_ROWS   $SRAM_RAM_COLS \
    cache $cache_records $CACHE_ISLAND_COUNT      $SRAM_CACHE_ROWS $SRAM_CACHE_COLS \
    tag   $tag_records   $SRAM_TAG_EXPECTED_COUNT $SRAM_TAG_ROWS   $SRAM_TAG_COLS] {
    if {[llength $records] != $count} {
        error "$island island: expected $count macros, found [llength $records]"
    }
    if {$rows * $cols < $count} {
        error "$island island grid $rows x $cols cannot hold $count macros"
    }
}

# ------------------------------------------------------------------------
# Island and core sizes
# ------------------------------------------------------------------------
set big_ptr [lindex [lindex $ram_records 0] 1]
set tag_ptr [lindex [lindex $tag_records 0] 1]
set BIG_W [expr {double([dbGet $big_ptr.cell.size_x])}]
set BIG_H [expr {double([dbGet $big_ptr.cell.size_y])}]
set TAG_W [expr {double([dbGet $tag_ptr.cell.size_x])}]
set TAG_H [expr {double([dbGet $tag_ptr.cell.size_y])}]

set RAM_W   [expr {$SRAM_RAM_COLS   * $BIG_W + ($SRAM_RAM_COLS   - 1) * $MACRO_GAP}]
set RAM_H   [expr {$SRAM_RAM_ROWS   * $BIG_H + ($SRAM_RAM_ROWS   - 1) * $MACRO_GAP}]
set CACHE_W [expr {$SRAM_CACHE_COLS * $BIG_W + ($SRAM_CACHE_COLS - 1) * $MACRO_GAP}]
set CACHE_H [expr {$SRAM_CACHE_ROWS * $BIG_H + ($SRAM_CACHE_ROWS - 1) * $MACRO_GAP}]
set TAGI_W  [expr {$SRAM_TAG_COLS   * $TAG_W + ($SRAM_TAG_COLS   - 1) * $MACRO_GAP}]
set TAGI_H  [expr {$SRAM_TAG_ROWS   * $TAG_H + ($SRAM_TAG_ROWS   - 1) * $MACRO_GAP}]

set MACRO_W [expr {$RAM_W + $ISLAND_GAP + $CACHE_W + $ISLAND_GAP + $TAGI_W}]
set MACRO_H [expr {max($RAM_H, $CACHE_H, $TAGI_H)}]

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

set LOGIC_AREA_REQUIRED [expr {$STD_CELL_AREA / $MCU_TARGET_STD_UTIL}]
set LOGIC_SIDE [expr {sqrt(max($LOGIC_AREA_REQUIRED, 1.0))}]
set LOGIC_W [expr {max(500.0, $LOGIC_SIDE)}]
set LOGIC_H [expr {max($MACRO_H, $LOGIC_SIDE)}]

set CORE_W [snap_up \
    [expr {$EDGE_GAP + $MACRO_W + $ISLAND_GAP + $LOGIC_W + $EDGE_GAP}] \
    $SITE_GRID]
set CORE_H [snap_up [expr {$EDGE_GAP + $LOGIC_H + $EDGE_GAP}] $SITE_GRID]

if {$MCU_CORE_WIDTH_OVERRIDE > 0.0} {
    set CORE_W [snap_up $MCU_CORE_WIDTH_OVERRIDE $SITE_GRID]
}
if {$MCU_CORE_HEIGHT_OVERRIDE > 0.0} {
    set CORE_H [snap_up $MCU_CORE_HEIGHT_OVERRIDE $SITE_GRID]
}
if {$CORE_W < 2.0 * $EDGE_GAP + $MACRO_W || $CORE_H < 2.0 * $EDGE_GAP + $MACRO_H} {
    error "Core override is too small for the three SRAM islands ($MACRO_W x $MACRO_H um)"
}

floorPlan \
    -s $CORE_W $CORE_H \
    $CORE_MARGIN $CORE_MARGIN $CORE_MARGIN $CORE_MARGIN

# ------------------------------------------------------------------------
# Place the islands
# ------------------------------------------------------------------------
set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set x_ram   [snap_up [expr {$core_llx + $EDGE_GAP}] $SITE_GRID]
set y0      [snap_up [expr {$core_lly + $EDGE_GAP}] $SITE_GRID]
set x_cache [snap_up [expr {$x_ram + $RAM_W + $ISLAND_GAP}] $SITE_GRID]
set x_tag   [snap_up [expr {$x_cache + $CACHE_W + $ISLAND_GAP}] $SITE_GRID]
# Tag column centred on the cache island: the tag compare and the data mux
# sit on the same cache hit path.
set y_tag   [snap_up [expr {$y0 + ($CACHE_H - $TAGI_H) / 2.0}] $SITE_GRID]

file mkdir ./reports
set map_fp [open ./reports/sram_macro_map.rpt w]
puts $map_fp "island index instance row col x y orient"
place_island RAM   $ram_records   $SRAM_RAM_ROWS   $SRAM_RAM_COLS   $x_ram   $y0     $BIG_W $BIG_H $MACRO_GAP $map_fp
place_island cache $cache_records $SRAM_CACHE_ROWS $SRAM_CACHE_COLS $x_cache $y0     $BIG_W $BIG_H $MACRO_GAP $map_fp
place_island tag   $tag_records   $SRAM_TAG_ROWS   $SRAM_TAG_COLS   $x_tag   $y_tag  $TAG_W $TAG_H $MACRO_GAP $map_fp
close $map_fp

addHaloToBlock \
    -allBlock \
    $MACRO_HALO $MACRO_HALO $MACRO_HALO $MACRO_HALO

# One hard blockage per island; one extra site of slack covers the per-macro
# snap to the site grid.
foreach {name llx lly w h} [list \
    SRAM_RAM_BLOCKAGE   $x_ram   $y0    $RAM_W   $RAM_H \
    SRAM_CACHE_BLOCKAGE $x_cache $y0    $CACHE_W $CACHE_H \
    SRAM_TAG_BLOCKAGE   $x_tag   $y_tag $TAGI_W  $TAGI_H] {
    catch {deletePlaceBlockage $name}
    createPlaceBlockage \
        -name $name \
        -type hard \
        -box [list $llx $lly \
            [expr {$llx + $w + $SITE_GRID}] [expr {$lly + $h + $SITE_GRID}]]
}

puts "============================================================"
puts "MCU SRAM FLOORPLAN CREATED"
puts " - Core         : $CORE_W x $CORE_H um"
puts " - Stdcell area : $STD_CELL_AREA um^2"
puts " - Target util  : $MCU_TARGET_STD_UTIL"
puts " - RAM island   : $SRAM_RAM_ROWS x $SRAM_RAM_COLS, $RAM_W x $RAM_H um"
puts " - Cache island : $SRAM_CACHE_ROWS x $SRAM_CACHE_COLS, $CACHE_W x $CACHE_H um"
puts " - Tag island   : $SRAM_TAG_ROWS x $SRAM_TAG_COLS, $TAGI_W x $TAGI_H um"
puts "============================================================"
