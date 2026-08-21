############################################################
## 4x4 SRAM macro placement on a loaded hierarchy floorplan
##
## Required state:
##   - init_design completed
##   - FloorPlan.fp loaded
##   - sram_macro_setup.tcl sourced by innovus.globals
##
## Flow:
##   deterministic 4x4 seed -> physical group -> snap -> validate
##   -> FIXED -> save
############################################################

proc sram_bank_index {name fallback} {
    set numbers [regexp -all -inline {[0-9]+} $name]
    if {[llength $numbers] > 0} {
        return [lindex $numbers end]
    }
    return $fallback
}

proc min_value {a b} {
    return [expr {$a < $b ? $a : $b}]
}

proc max_value {a b} {
    return [expr {$a > $b ? $a : $b}]
}

proc sram_snap_to_grid {value grid} {
    if {![string is double -strict $value]} {
        error "Invalid snap-to-grid value: $value"
    }
    if {![string is double -strict $grid]} {
        error "Invalid snap-to-grid grid: $grid"
    }
    if {$grid <= 0.0} {
        error "Invalid snap-to-grid grid: $grid"
    }
    return [format %.6f [expr {round($value / $grid) * $grid}]]
}

proc sram_compare_yx {a b} {
    set ay [lindex $a 0]
    set by [lindex $b 0]
    if {$ay < $by} {
        return -1
    }
    if {$ay > $by} {
        return 1
    }

    set ax [lindex $a 1]
    set bx [lindex $b 1]
    if {$ax < $bx} {
        return -1
    }
    if {$ax > $bx} {
        return 1
    }
    return 0
}

proc sram_compare_x {a b} {
    set ax [lindex $a 1]
    set bx [lindex $b 1]
    if {$ax < $bx} {
        return -1
    }
    if {$ax > $bx} {
        return 1
    }
    return 0
}

# Innovus may return a point/box either as a flat list or as a one-element
# nested list.  Decode it before using the coordinates in placeInstance.
# Passing a nested point directly can leave one coordinate empty and make
# macros overlap or appear to be missing in the GUI.
proc sram_fp_decode_point {ptr name} {
    set point [join [dbGet $ptr.pt]]
    if {[llength $point] != 2} {
        error "Cannot decode placement point for $name: [dbGet $ptr.pt]"
    }

    foreach coordinate $point {
        if {![string is double -strict $coordinate]} {
            error "Non-numeric placement point for $name: $point"
        }
    }
    return $point
}

proc sram_fp_decode_box {ptr name} {
    set box [join [dbGet $ptr.box]]
    if {[llength $box] != 4} {
        error "Cannot decode placement box for $name: [dbGet $ptr.box]"
    }

    foreach coordinate $box {
        if {![string is double -strict $coordinate]} {
            error "Non-numeric placement box for $name: $box"
        }
    }
    return $box
}

# Default to packing all SRAMs into the required 4x4 island.  Set
# SRAM_AUTO_PACK_4X4=0 before sourcing this file only when manual GUI review
# of the deterministic seed is required.
if {![info exists SRAM_AUTO_PACK_4X4]} {
    set SRAM_AUTO_PACK_4X4 1
}

set SRAM_PACK_4X4 $SRAM_AUTO_PACK_4X4
if {[info exists MASTER_ONE_SHOT] && $MASTER_ONE_SHOT} {
    set SRAM_PACK_4X4 1
}

# ------------------------------------------------------------------------
# 1. FIND AND VALIDATE THE SRAM GROUP
# ------------------------------------------------------------------------

set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {$SRAM_PTRS eq "" || $SRAM_PTRS eq "0x0"} {
    error "No SRAM instances found for master $SRAM_MASTER"
}

set SRAM_RECORDS {}
set fallback 0
foreach ptr $SRAM_PTRS {
    set name [lindex [dbGet $ptr.name] 0]
    set index [sram_bank_index $name $fallback]
    lappend SRAM_RECORDS [list $index $name $ptr]
    incr fallback
}
set SRAM_RECORDS [lsort -integer -index 0 $SRAM_RECORDS]

if {[llength $SRAM_RECORDS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros, found [llength $SRAM_RECORDS]"
}

# Require one unique bank index for every physical SRAM.  This avoids a
# deterministic but incorrect snake order when hierarchy names contain
# unexpected trailing numbers.
set seen_bank_indices {}
foreach record $SRAM_RECORDS {
    set bank [lindex $record 0]
    if {[lsearch -exact $seen_bank_indices $bank] >= 0} {
        error "Duplicate SRAM bank index $bank; check the instance-name parser"
    }
    lappend seen_bank_indices $bank
}

set first_ptr [lindex [lindex $SRAM_RECORDS 0] 2]
set SRAM_W [dbGet $first_ptr.cell.size_x]
set SRAM_H [dbGet $first_ptr.cell.size_y]

set SRAM_ARRAY_W [expr {
    $SRAM_COLS * $SRAM_W +
    ($SRAM_COLS - 1) * $SRAM_MACRO_GAP_X
}]
set SRAM_ARRAY_H [expr {
    $SRAM_ROWS * $SRAM_H +
    ($SRAM_ROWS - 1) * $SRAM_MACRO_GAP_Y
}]

# ------------------------------------------------------------------------
# 2. CHECK THE LOADED HIERARCHY FLOORPLAN
# ------------------------------------------------------------------------

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set core_urx [dbGet top.fPlan.coreBox_urx]
set core_ury [dbGet top.fPlan.coreBox_ury]

set SRAM_X0 [expr {$core_llx + $SRAM_EDGE_GAP_X}]
set SRAM_Y0 [expr {$core_lly + $SRAM_EDGE_GAP_Y}]

set required_urx [expr {
    $SRAM_X0 + $SRAM_ARRAY_W + $SRAM_ISLAND_ESCAPE_RIGHT
}]
set required_ury [expr {
    $SRAM_Y0 + $SRAM_ARRAY_H + $SRAM_ISLAND_ESCAPE_TOP
}]

if {$required_urx > $core_urx || $required_ury > $core_ury} {
    error "Loaded FloorPlan.fp is too small for the 4x4 SRAM island"
}

puts "===================================================="
puts "SRAM MACRO GROUP"
puts " - Master       : $SRAM_MASTER"
puts " - Count        : [llength $SRAM_RECORDS]"
puts " - Array        : ${SRAM_ROWS} x ${SRAM_COLS}"
puts " - Array size   : $SRAM_ARRAY_W x $SRAM_ARRAY_H um"
puts " - Target corner: lower-left"
puts "===================================================="

# ------------------------------------------------------------------------
# 3. CREATE A DETERMINISTIC 4x4 SEED PLACEMENT
# ------------------------------------------------------------------------

set planned_map [open ./reports/sram_macro_planned_map.rpt w]
puts $planned_map "bank instance row col x y orient stage"

for {set k 0} {$k < $SRAM_COUNT} {incr k} {
    set record [lindex $SRAM_RECORDS $k]
    set bank [lindex $record 0]
    set name [lindex $record 1]
    set ptr  [lindex $record 2]

    set row [expr {int($k / $SRAM_COLS)}]
    set pos [expr {$k % $SRAM_COLS}]

    if {[expr {$row % 2}] == 0} {
        set col $pos
    } else {
        set col [expr {$SRAM_COLS - 1 - $pos}]
    }

    set x [expr {
    	$SRAM_X0 + $col * ($SRAM_W + $SRAM_MACRO_GAP_X)
    }]
    set y [expr {
    	$SRAM_Y0 + $row * ($SRAM_H + $SRAM_MACRO_GAP_Y)
    }]
    set snap_x [sram_snap_to_grid $x $ASAP7_SITE_WIDTH]
    set snap_y [sram_snap_to_grid $y $ASAP7_SITE_WIDTH]
    set orient [sram_orientation_for_column $col]
    dbSet $ptr.pStatus unplaced
    placeInstance $name $snap_x $snap_y $orient
    dbSet $ptr.pStatus placed

    puts $planned_map \
        "$bank $name $row $col $snap_x $snap_y $orient seed"
}
close $planned_map

# ------------------------------------------------------------------------
# 4. CREATE THE SRAM PHYSICAL GROUP
# ------------------------------------------------------------------------

# An explicit physical group records that all sixteen SRAMs belong to one
# hierarchy cluster.  The macros are placed deterministically and later fixed,
# so this group must not be a fence.  A fence is exclusive: standard cells not
# added to the group cannot legally be placed inside it.  The previous macro-
# only fence therefore rejected connected u_mem standard cells near the SRAM
# boundary and produced Not-of-Fence/overlap violations after place_opt_design.
# The hard placement blockage created by finish_macroFP.tcl remains the owner
# of the SRAM bodies and inter-macro PG channels.
set SRAM_GROUP_NAME SRAM_ISLAND_GROUP
set SRAM_MODEL_ROW $ASAP7_ROW_HEIGHT
set SRAM_MODEL_ROW_X2 [expr {2.0 * $SRAM_MODEL_ROW}]

createInstGroup $SRAM_GROUP_NAME

foreach record $SRAM_RECORDS {
    addInstToInstGroup \
        $SRAM_GROUP_NAME \
        [lindex $record 1]
}

addHaloToBlock \
    -allBlock \
    $SRAM_MODEL_ROW_X2 $SRAM_MODEL_ROW_X2 \
    $SRAM_MODEL_ROW_X2 $SRAM_MODEL_ROW_X2

set SRAM_PACK_RECORDS {}
set deterministic_map [open ./reports/sram_macro_deterministic_map.rpt w]
puts $deterministic_map "bank instance x y orient status"

foreach record $SRAM_RECORDS {
    set bank [lindex $record 0]
    set name [lindex $record 1]
    set ptr  [lindex $record 2]
    lassign [sram_fp_decode_point $ptr $name] x y
    set orient [lindex [dbGet $ptr.orient] 0]
    set status [lindex [dbGet $ptr.pStatus] 0]

    if {$status eq "unplaced"} {
        close $deterministic_map
        error "$name is unplaced after deterministic seed placement"
    }

    lappend SRAM_PACK_RECORDS \
        [list $y $x $bank $name $ptr]
    puts $deterministic_map "$bank $name $x $y $orient $status"
}
close $deterministic_map

if {[llength $SRAM_PACK_RECORDS] != $SRAM_COUNT} {
    error "Deterministic placement returned [llength $SRAM_PACK_RECORDS] SRAMs; expected $SRAM_COUNT"
}

# ------------------------------------------------------------------------
# 5. DETERMINISTIC 4x4 PACKING OR EXPLICIT SEED-PLACEMENT REVIEW
# ------------------------------------------------------------------------

if {$SRAM_PACK_4X4} {
    # Quantize the deterministic seed into the required 4x4 array.
    set pack_sorted \
        [lsort -command sram_compare_yx $SRAM_PACK_RECORDS]

    if {[llength $pack_sorted] != $SRAM_COUNT} {
        error "Cannot pack 4x4 island: deterministic result does not contain $SRAM_COUNT SRAMs"
    }

    set packed_map [open ./reports/sram_macro_auto_pack_map.rpt w]
    puts $packed_map "bank instance row col x y orient"
    set packed_names {}
    set packed_count 0

    for {set row 0} {$row < $SRAM_ROWS} {incr row} {
        set first [expr {$row * $SRAM_COLS}]
        set last  [expr {$first + $SRAM_COLS - 1}]
        set row_records \
            [lrange $pack_sorted $first $last]
        set row_records \
            [lsort -command sram_compare_x $row_records]

        if {[llength $row_records] != $SRAM_COLS} {
            close $packed_map
            error "Row $row contains [llength $row_records] SRAMs; expected $SRAM_COLS"
        }

        for {set col 0} {$col < $SRAM_COLS} {incr col} {
            set placed_record [lindex $row_records $col]
            set bank [lindex $placed_record 2]
            set name [lindex $placed_record 3]
            set ptr  [lindex $placed_record 4]

            if {[lsearch -exact $packed_names $name] >= 0} {
                close $packed_map
                error "Duplicate SRAM during 4x4 packing: $name"
            }
            lappend packed_names $name

            set x [expr {
            	$SRAM_X0 +
            	$col * ($SRAM_W + $SRAM_MACRO_GAP_X)
            }]
            set y [expr {
            	$SRAM_Y0 +
            	$row * ($SRAM_H + $SRAM_MACRO_GAP_Y)
            }]
            set snap_x [sram_snap_to_grid $x $ASAP7_SITE_WIDTH]
            set snap_y [sram_snap_to_grid $y $ASAP7_SITE_WIDTH]
            set orient [sram_orientation_for_column $col]
            
            dbSet $ptr.pStatus unplaced
            placeInstance $name $snap_x $snap_y $orient
            dbSet $ptr.pStatus placed
            
            set placed_orient [lindex [dbGet $ptr.orient] 0]
            if {$placed_orient ne $orient} {
                close $packed_map
                error "$name was not placed with orientation $orient (actual: $placed_orient)"
            }
            puts $packed_map \
                "$bank $name $row $col $snap_x $snap_y $orient"
            incr packed_count
        }
    }
    close $packed_map

    if {$packed_count != $SRAM_COUNT ||
        [llength $packed_names] != $SRAM_COUNT} {
        error "Packed $packed_count unique SRAMs; expected $SRAM_COUNT"
    }

    # Validate the database result immediately.  This catches a malformed
    # coordinate before finish_macroFP.tcl can refine or fix the macros.
    set packed_boxes {}
    set packed_box_keys {}
    foreach record $SRAM_RECORDS {
        set name [lindex $record 1]
        set ptr  [lindex $record 2]
        set status [lindex [dbGet $ptr.pStatus] 0]

        if {$status eq "unplaced"} {
            error "$name became unplaced during 4x4 packing"
        }

        set box [sram_fp_decode_box $ptr $name]
        if {[lsearch -exact $packed_box_keys $box] >= 0} {
            error "$name overlaps another SRAM at identical box $box"
        }
        lappend packed_box_keys $box
        lappend packed_boxes [concat [list $name] $box]
    }

    if {[llength $packed_boxes] != $SRAM_COUNT} {
        error "Database contains [llength $packed_boxes] packed SRAM boxes; expected $SRAM_COUNT"
    }

    # An identical-box check alone is insufficient because two macros can
    # partially overlap.  Reject every positive-area intersection.
    for {set i 0} {$i < [llength $packed_boxes]} {incr i} {
        set a [lindex $packed_boxes $i]
        set a_name [lindex $a 0]
        set a_llx  [lindex $a 1]
        set a_lly  [lindex $a 2]
        set a_urx  [lindex $a 3]
        set a_ury  [lindex $a 4]

        for {set j [expr {$i + 1}]} \
            {$j < [llength $packed_boxes]} \
            {incr j} {
            set b [lindex $packed_boxes $j]
            set b_name [lindex $b 0]
            set b_llx  [lindex $b 1]
            set b_lly  [lindex $b 2]
            set b_urx  [lindex $b 3]
            set b_ury  [lindex $b 4]

            set overlap_x [expr {
                [min_value $a_urx $b_urx] -
                [max_value $a_llx $b_llx]
            }]
            set overlap_y [expr {
                [min_value $a_ury $b_ury] -
                [max_value $a_lly $b_lly]
            }]

            if {$overlap_x > 0.0 && $overlap_y > 0.0} {
                error "SRAM overlap after 4x4 packing: $a_name and $b_name"
            }
        }
    }

    # Restore the final project halo after the temporary mixed-placement halo.
    addHaloToBlock \
        -allBlock \
        $SRAM_HALO_L $SRAM_HALO_B $SRAM_HALO_R $SRAM_HALO_T
}

puts "===================================================="
puts "DETERMINISTIC SRAM MACRO PLACEMENT CREATED"
if {$SRAM_PACK_4X4} {
    puts "All $SRAM_COUNT SRAMs were packed into a verified 4x4 island."
    if {[info exists MASTER_ONE_SHOT] && $MASTER_ONE_SHOT} {
        puts "Master flow will continue with snap -> validate -> FIXED."
        puts "Review ./reports/sram_macro_final_map.rpt after the run."
    } else {
        puts "Review the 4x4 island, then run:"
        puts "  source ./tcl/finish_macroFP.tcl"
    }
} else {
    puts "Manual review required before FIXED:"
    puts "  1. Follow connectivity fly-lines, not bank number alone."
    puts "  2. Keep all macros in one hierarchy group at the boundary."
    puts "  3. Preserve routing gaps and a rectangular, notch-free island."
    puts "  4. Use only the R0/MY horizontal mirror-pair pattern."
    puts "  5. Orient signal pins toward the controller/core where possible."
    puts ""
    puts "After manual edits in the GUI, run:"
    puts "  source ./tcl/finish_macroFP.tcl"
}
puts "===================================================="
