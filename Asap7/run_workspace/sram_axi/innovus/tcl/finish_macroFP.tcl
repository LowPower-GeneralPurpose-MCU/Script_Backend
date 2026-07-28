############################################################
## Finish the manually reviewed SRAM macro floorplan
## Run in the same session as innovus_macroFP.tcl.
############################################################

foreach required_variable {
    SRAM_RECORDS SRAM_COUNT SRAM_MASTER SRAM_W SRAM_H SRAM_X0 SRAM_Y0
    core_llx core_lly core_urx core_ury
    SRAM_ISLAND_ORIENT FLOORPLAN_GRID
    ASAP7_ROW_HEIGHT SRAM_MACRO_GAP_ROWS
    SRAM_BLOCKAGE_BORDER_ROWS SRAM_BLOCKAGE_BORDER
    SRAM_MACRO_GAP_X SRAM_MACRO_GAP_Y
    SRAM_HALO_L SRAM_HALO_B SRAM_HALO_R SRAM_HALO_T
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable; run innovus_macroFP.tcl first"
    }
}

# dbGet may return an instance box as either:
#   {llx lly urx ury}
# or:
#   {{llx lly urx ury}}
# Flatten and validate it before any destructive unplace operation.
proc sram_decode_inst_box {ptr name} {
    set box [join [dbGet $ptr.box]]
    if {[llength $box] != 4} {
        error "Cannot decode box for $name: [dbGet $ptr.box]"
    }

    foreach coordinate $box {
        if {![string is double -strict $coordinate]} {
            error "Non-numeric box coordinate for $name: $box"
        }
    }
    return $box
}

proc sram_decode_inst_point {ptr name} {
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

if {[llength $SRAM_RECORDS] != $SRAM_COUNT} {
    error "finish_macroFP received [llength $SRAM_RECORDS] SRAM records; expected $SRAM_COUNT"
}
set finish_sram_ptrs [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {[llength $finish_sram_ptrs] != $SRAM_COUNT} {
    error "Innovus database contains [llength $finish_sram_ptrs] SRAM macros; expected $SRAM_COUNT"
}

# sram_macro_floorplan.tcl has already reset every macro to a complete,
# overlap-free 4x4 array with legal R180 orientation.  Do not call
# refine_macro_place here: the failing log shows that it flipped/moved the
# already packed macros, failed to resolve the dense fence, and destroyed the
# required four-row channels.  A snap plus strict geometry validation is the
# deterministic legalization for this constrained island.
addHaloToBlock \
    -allBlock \
    $SRAM_HALO_L $SRAM_HALO_B $SRAM_HALO_R $SRAM_HALO_T

snapFPlan -block

set actual_llx $core_urx
set actual_lly $core_ury
set actual_urx $core_llx
set actual_ury $core_lly

set actual_map [open ./reports/sram_macro_final_map.rpt w]
puts $actual_map \
    "bank instance origin_x origin_y nominal_llx nominal_lly nominal_urx nominal_ury db_llx db_lly db_urx db_ury orient status"
set actual_boxes {}

foreach record $SRAM_RECORDS {
    set bank [lindex $record 0]
    set name [lindex $record 1]
    set ptr  [lindex $record 2]

    set orient [dbGet $ptr.orient]
    if {$orient ne "R0" && $orient ne "R180"} {
        close $actual_map
        error "$name has illegal orientation $orient; only R0/R180 are allowed"
    }

    lassign [sram_decode_inst_point $ptr $name] x y

    # The generated SRAM LEF contains a V3 obstruction that extends roughly
    # 0.020 um outside the declared macro SIZE.  Innovus therefore expands
    # ptr.box and emits IMPPP-133.  Placement spacing and the required
    # two-row blockage border must be measured from the declared macro body,
    # namely origin + cell.size, not from that expanded routing obstruction.
    set nominal_llx $x
    set nominal_lly $y
    set nominal_urx [expr {$x + $SRAM_W}]
    set nominal_ury [expr {$y + $SRAM_H}]

    lassign [sram_decode_inst_box $ptr $name] \
        db_llx db_lly db_urx db_ury

    set actual_llx [min_value $actual_llx $nominal_llx]
    set actual_lly [min_value $actual_lly $nominal_lly]
    set actual_urx [max_value $actual_urx $nominal_urx]
    set actual_ury [max_value $actual_ury $nominal_ury]

    dbSet $ptr.pStatus fixed
    set status [dbGet $ptr.pStatus]
    if {$status ne "fixed"} {
        close $actual_map
        error "$name was not FIXED after snapFPlan"
    }

    puts $actual_map \
        "$bank $name $x $y $nominal_llx $nominal_lly $nominal_urx $nominal_ury $db_llx $db_lly $db_urx $db_ury $orient $status"
    lappend actual_boxes [list \
        $name \
        $nominal_llx \
        $nominal_lly \
        $nominal_urx \
        $nominal_ury \
    ]
}
close $actual_map

set geometry_tolerance 0.001
if {$actual_llx < [expr {$core_llx - $geometry_tolerance}] ||
    $actual_lly < [expr {$core_lly - $geometry_tolerance}] ||
    $actual_urx > [expr {$core_urx + $geometry_tolerance}] ||
    $actual_ury > [expr {$core_ury + $geometry_tolerance}]} {
    error "Packed SRAM macro bodies lie outside the core boundary"
}

# Verify that snap did not alter the exact four-row routing channels.
set min_horizontal_gap $core_urx
set min_vertical_gap   $core_ury
set adjacency_x 0
set adjacency_y 0

for {set i 0} {$i < [llength $actual_boxes]} {incr i} {
    set a [lindex $actual_boxes $i]
    set a_llx [lindex $a 1]
    set a_lly [lindex $a 2]
    set a_urx [lindex $a 3]
    set a_ury [lindex $a 4]

    for {set j [expr {$i + 1}]} \
        {$j < [llength $actual_boxes]} \
        {incr j} {
        set b [lindex $actual_boxes $j]
        set b_llx [lindex $b 1]
        set b_lly [lindex $b 2]
        set b_urx [lindex $b 3]
        set b_ury [lindex $b 4]

        set overlap_x [expr {
            [min_value $a_urx $b_urx] -
            [max_value $a_llx $b_llx]
        }]
        set overlap_y [expr {
            [min_value $a_ury $b_ury] -
            [max_value $a_lly $b_lly]
        }]

        if {$overlap_x > 0.0 && $overlap_y > 0.0} {
            error "SRAM overlap after snap: [lindex $a 0] and [lindex $b 0]"
        }

        if {$overlap_y > 0.0} {
            if {$a_urx <= $b_llx} {
                set gap_x [expr {$b_llx - $a_urx}]
            } else {
                set gap_x [expr {$a_llx - $b_urx}]
            }
            set min_horizontal_gap \
                [min_value $min_horizontal_gap $gap_x]
            incr adjacency_x
        }

        if {$overlap_x > 0.0} {
            if {$a_ury <= $b_lly} {
                set gap_y [expr {$b_lly - $a_ury}]
            } else {
                set gap_y [expr {$a_lly - $b_ury}]
            }
            set min_vertical_gap \
                [min_value $min_vertical_gap $gap_y]
            incr adjacency_y
        }
    }
}

set gap_tolerance 0.001

if {$adjacency_x == 0 || $adjacency_y == 0} {
    error "SRAM island is not a valid multi-row/multi-column arrangement"
}
if {abs($min_horizontal_gap - $SRAM_MACRO_GAP_X) > $gap_tolerance} {
    error "Horizontal SRAM gap $min_horizontal_gap is not four rows ($SRAM_MACRO_GAP_X um)"
}
if {abs($min_vertical_gap - $SRAM_MACRO_GAP_Y) > $gap_tolerance} {
    error "Vertical SRAM gap $min_vertical_gap is not four rows ($SRAM_MACRO_GAP_Y um)"
}

set gap_report [open ./reports/sram_macro_gap_check.rpt w]
puts $gap_report "configured_gap_x $SRAM_MACRO_GAP_X"
puts $gap_report "configured_gap_y $SRAM_MACRO_GAP_Y"
puts $gap_report "grid_tolerance $gap_tolerance"
puts $gap_report "minimum_horizontal_gap $min_horizontal_gap"
puts $gap_report "minimum_vertical_gap $min_vertical_gap"
puts $gap_report "horizontal_adjacencies $adjacency_x"
puts $gap_report "vertical_adjacencies $adjacency_y"
close $gap_report

set SRAM_ISLAND_LLX $actual_llx
set SRAM_ISLAND_LLY $actual_lly
set SRAM_ISLAND_URX $actual_urx
set SRAM_ISLAND_URY $actual_ury

# Decode the die boundary separately from the core boundary.  A placement
# blockage is normally clipped at the core edge, which leaves the lower-left
# core-to-die margin visible and makes the red blockage look offset from the
# SRAM island.  The teacher's reference instead covers that margin up to the
# die boundary (where the VDD/VSS ring and boundary pins are displayed).
set SRAM_DIE_BOX [join [dbGet top.fPlan.box]]
if {[llength $SRAM_DIE_BOX] != 4} {
    error "Cannot decode die box: [dbGet top.fPlan.box]"
}
foreach coordinate $SRAM_DIE_BOX {
    if {![string is double -strict $coordinate]} {
        error "Non-numeric die-box coordinate: $SRAM_DIE_BOX"
    }
}
lassign $SRAM_DIE_BOX die_llx die_lly die_urx die_ury

if {$core_llx < $die_llx || $core_lly < $die_lly ||
    $core_urx > $die_urx || $core_ury > $die_ury} {
    error "Core boundary $core_llx $core_lly $core_urx $core_ury is outside die $SRAM_DIE_BOX"
}

# Build one solid rectangular blockage from the validated post-snap SRAM
# bbox.  Expanding that bbox by two rows on every side guarantees that:
#   - every SRAM body is covered,
#   - every four-row inter-macro gap is covered, and
#   - the blockage boundary remains two rows from the outer SRAMs.
#
# Clamping to the die is only a safety guard.  With the intended lower-left
# placement and a two-row die-to-core margin, the expanded LL corner lands
# exactly on the die boundary.
set SRAM_ISLAND_BLOCKAGE_LLX \
    [max_value $die_llx \
        [expr {$SRAM_ISLAND_LLX - $SRAM_BLOCKAGE_BORDER}]]
set SRAM_ISLAND_BLOCKAGE_LLY \
    [max_value $die_lly \
        [expr {$SRAM_ISLAND_LLY - $SRAM_BLOCKAGE_BORDER}]]
set SRAM_ISLAND_BLOCKAGE_URX \
    [min_value $die_urx \
        [expr {$SRAM_ISLAND_URX + $SRAM_BLOCKAGE_BORDER}]]
set SRAM_ISLAND_BLOCKAGE_URY \
    [min_value $die_ury \
        [expr {$SRAM_ISLAND_URY + $SRAM_BLOCKAGE_BORDER}]]
set SRAM_ISLAND_BLOCKAGE_BOX [list \
    $SRAM_ISLAND_BLOCKAGE_LLX \
    $SRAM_ISLAND_BLOCKAGE_LLY \
    $SRAM_ISLAND_BLOCKAGE_URX \
    $SRAM_ISLAND_BLOCKAGE_URY \
]

# cutRow is meaningful only inside the core.  Use the core intersection of the
# two-row placement blockage while retaining the complete blockage through the
# core-to-die margin for the GUI and placer database.
set SRAM_ISLAND_CUT_LLX \
    [max_value $core_llx $SRAM_ISLAND_BLOCKAGE_LLX]
set SRAM_ISLAND_CUT_LLY \
    [max_value $core_lly $SRAM_ISLAND_BLOCKAGE_LLY]
set SRAM_ISLAND_CUT_URX \
    [min_value $core_urx $SRAM_ISLAND_BLOCKAGE_URX]
set SRAM_ISLAND_CUT_URY \
    [min_value $core_ury $SRAM_ISLAND_BLOCKAGE_URY]
set SRAM_ISLAND_CUT_BOX [list \
    $SRAM_ISLAND_CUT_LLX \
    $SRAM_ISLAND_CUT_LLY \
    $SRAM_ISLAND_CUT_URX \
    $SRAM_ISLAND_CUT_URY \
]

set blockage_clearance_left \
    [expr {$SRAM_ISLAND_LLX - $SRAM_ISLAND_BLOCKAGE_LLX}]
set blockage_clearance_bottom \
    [expr {$SRAM_ISLAND_LLY - $SRAM_ISLAND_BLOCKAGE_LLY}]
set blockage_clearance_right \
    [expr {$SRAM_ISLAND_BLOCKAGE_URX - $SRAM_ISLAND_URX}]
set blockage_clearance_top \
    [expr {$SRAM_ISLAND_BLOCKAGE_URY - $SRAM_ISLAND_URY}]

set blockage_clearance_tolerance 0.001
foreach {side clearance} [list \
    left   $blockage_clearance_left \
    bottom $blockage_clearance_bottom \
    right  $blockage_clearance_right \
    top    $blockage_clearance_top \
] {
    if {abs($clearance - $SRAM_BLOCKAGE_BORDER) >
        $blockage_clearance_tolerance} {
        error "SRAM blockage $side clearance $clearance is not two rows ($SRAM_BLOCKAGE_BORDER um)"
    }
}

cutRow -area $SRAM_ISLAND_CUT_BOX

createPlaceBlockage \
    -name SRAM_ISLAND_GROUP_BLOCKAGE \
    -type hard \
    -noCutByCore \
    -box $SRAM_ISLAND_BLOCKAGE_BOX

set blockage_report \
    [open ./reports/sram_island_blockage_geometry.rpt w]
puts $blockage_report "die_box $SRAM_DIE_BOX"
puts $blockage_report \
    "core_box $core_llx $core_lly $core_urx $core_ury"
puts $blockage_report \
    "macro_bbox $SRAM_ISLAND_LLX $SRAM_ISLAND_LLY $SRAM_ISLAND_URX $SRAM_ISLAND_URY"
puts $blockage_report "row_height $ASAP7_ROW_HEIGHT"
puts $blockage_report "inter_macro_gap_rows $SRAM_MACRO_GAP_ROWS"
puts $blockage_report "inter_macro_gap_um $SRAM_MACRO_GAP_X"
puts $blockage_report \
    "blockage_border_rows $SRAM_BLOCKAGE_BORDER_ROWS"
puts $blockage_report "blockage_border_um $SRAM_BLOCKAGE_BORDER"
puts $blockage_report \
    "blockage_clearance_tolerance $blockage_clearance_tolerance"
puts $blockage_report \
    "blockage_clearance_left $blockage_clearance_left"
puts $blockage_report \
    "blockage_clearance_bottom $blockage_clearance_bottom"
puts $blockage_report \
    "blockage_clearance_right $blockage_clearance_right"
puts $blockage_report \
    "blockage_clearance_top $blockage_clearance_top"
puts $blockage_report "row_cut_box $SRAM_ISLAND_CUT_BOX"
puts $blockage_report "place_blockage_box $SRAM_ISLAND_BLOCKAGE_BOX"
puts $blockage_report "place_blockage_type hard"
puts $blockage_report "no_cut_by_core true"
close $blockage_report

# saveFPlan does not preserve Tcl variables, so export PG geometry.
set geometry_file [open ./outputs/sram_macro_geometry.tcl w]
puts $geometry_file "############################################################"
puts $geometry_file "## Generated SRAM macro geometry - do not edit by hand"
puts $geometry_file "############################################################"
foreach variable {
    SRAM_W
    SRAM_H
    SRAM_X0
    SRAM_Y0
    ASAP7_ROW_HEIGHT
    SRAM_MACRO_GAP_ROWS
    SRAM_MACRO_GAP_X
    SRAM_MACRO_GAP_Y
    SRAM_BLOCKAGE_BORDER_ROWS
    SRAM_BLOCKAGE_BORDER
    SRAM_ISLAND_LLX
    SRAM_ISLAND_LLY
    SRAM_ISLAND_URX
    SRAM_ISLAND_URY
    SRAM_ISLAND_CUT_LLX
    SRAM_ISLAND_CUT_LLY
    SRAM_ISLAND_CUT_URX
    SRAM_ISLAND_CUT_URY
    SRAM_ISLAND_CUT_BOX
    SRAM_DIE_BOX
    SRAM_ISLAND_BLOCKAGE_LLX
    SRAM_ISLAND_BLOCKAGE_LLY
    SRAM_ISLAND_BLOCKAGE_URX
    SRAM_ISLAND_BLOCKAGE_URY
    SRAM_ISLAND_BLOCKAGE_BOX
} {
    puts $geometry_file "set $variable [list [set $variable]]"
}
close $geometry_file

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_after_macroFP.rpt

saveFPlan ./outputs/FloorPlan_withMacro.fp
saveDesign ./saved/axi_ram_macroFP.enc

puts "===================================================="
puts "SRAM MACRO FLOORPLAN SAVED"
puts " - Sequence    : PG model -> concurrent -> 4x4 pack -> snap -> validate -> FIXED"
puts " - Floorplan   : ./outputs/FloorPlan_withMacro.fp"
puts " - Geometry Tcl: ./outputs/sram_macro_geometry.tcl"
puts " - Row cut     : $SRAM_ISLAND_CUT_BOX"
puts " - Hard blockage to die: $SRAM_ISLAND_BLOCKAGE_BOX"
puts " - Database    : ./saved/axi_ram_macroFP.enc"
puts "===================================================="
