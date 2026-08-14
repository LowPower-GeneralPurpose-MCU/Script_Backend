############################################################
## Reference-style SRAM island power
##
## Same intent as the teaching slide:
##   1. Build local PG only around the SRAM group/gaps.
##   2. Use every four-row column/row gap as a local collector.  Power access
##      has priority over signal escape inside the SRAM island.
##   3. Trim VDD/VSS stubs before the rest of the power grid continues.
##   4. Keep the regular global/floating mesh out of the SRAM island.
##
## ASAP7 mapping:
##   M4 is horizontal, M5 is vertical.
############################################################

foreach required_variable {
    SRAM_MASTER
    SRAM_COUNT
    SRAM_ROWS
    SRAM_COLS
    SRAM_X0
    SRAM_Y0
    SRAM_W
    SRAM_H
    SRAM_MACRO_GAP_X
    SRAM_MACRO_GAP_Y
    ASAP7_ROW_HEIGHT
    SRAM_BLOCKAGE_BORDER
    SRAM_ISLAND_URX
    SRAM_ISLAND_URY
    SRAM_ISLAND_CUT_URX
    SRAM_ISLAND_CUT_URY
    power_die_llx
    power_die_lly
    stripe_m45_w
    stripe_m45_s
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable before SRAM island power planning"
    }
}

set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {[llength $SRAM_PTRS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros before SRAM island PG; found [llength $SRAM_PTRS]"
}

if {![info exists power_die_urx] || ![info exists power_die_ury]} {
    set sram_pg_die_box [join [dbGet top.fPlan.box]]
    if {[llength $sram_pg_die_box] != 4} {
        error "Cannot decode die box before SRAM island PG: [dbGet top.fPlan.box]"
    }
    lassign $sram_pg_die_box \
        power_die_llx power_die_lly power_die_urx power_die_ury
}
if {![info exists PG_BOUNDARY_EPS]} {
    set PG_BOUNDARY_EPS 0.192
}
if {![info exists sram_edge_report]} {
    set sram_edge_report ./reports/sram_island_pg_edges.rpt
}
if {![info exists sram_stitch_intent_report]} {
    set sram_stitch_intent_report ./reports/sram_blockpin_stitch_intent.rpt
}
if {![info exists SRAM_ENABLE_COLUMN_GAP_PG]} {
    set SRAM_ENABLE_COLUMN_GAP_PG 1
}
if {![info exists SRAM_CONNECT_BLOCK_PINS]} {
    set SRAM_CONNECT_BLOCK_PINS 1
}
foreach bool_variable {
    SRAM_ENABLE_COLUMN_GAP_PG
    SRAM_CONNECT_BLOCK_PINS
} {
    if {![string is boolean -strict [set $bool_variable]]} {
        error "$bool_variable must be boolean, got [set $bool_variable]"
    }
}

set sram_stripe_w $stripe_m45_w
set sram_stripe_s $stripe_m45_s
set sram_pair_total [expr {2.0 * $sram_stripe_w + $sram_stripe_s}]
if {$SRAM_MACRO_GAP_Y <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_Y=$SRAM_MACRO_GAP_Y is too small for one M4 VSS/VDD pair"
}
if {$SRAM_ENABLE_COLUMN_GAP_PG && $SRAM_MACRO_GAP_X <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_X=$SRAM_MACRO_GAP_X is too small for one M5 VSS/VDD pair"
}
set sram_pg_left [expr {$power_die_llx + $PG_BOUNDARY_EPS}]
set sram_pg_bottom [expr {$power_die_lly + $PG_BOUNDARY_EPS}]
set sram_pg_right [expr {min($SRAM_ISLAND_CUT_URX, $power_die_urx - $PG_BOUNDARY_EPS)}]
set sram_pg_top [expr {min($SRAM_ISLAND_CUT_URY, $power_die_ury - $PG_BOUNDARY_EPS)}]

set local_left_area [list \
    $sram_pg_left $sram_pg_bottom \
    $SRAM_X0 $sram_pg_top]
set local_bottom_area [list \
    $sram_pg_left $sram_pg_bottom \
    $sram_pg_right $SRAM_Y0]
set local_top_area [list \
    $sram_pg_left $SRAM_ISLAND_URY \
    $sram_pg_right $sram_pg_top]
set local_right_area [list \
    $SRAM_ISLAND_URX $sram_pg_bottom \
    $sram_pg_right $sram_pg_top]

proc sram_area_overlaps_box {area box} {
    lassign $area area_llx area_lly area_urx area_ury
    lassign $box box_llx box_lly box_urx box_ury

    set overlap_x [expr {
        min($area_urx, $box_urx) - max($area_llx, $box_llx)
    }]
    set overlap_y [expr {
        min($area_ury, $box_ury) - max($area_lly, $box_lly)
    }]
    return [expr {$overlap_x > 0.000001 && $overlap_y > 0.000001}]
}

proc sram_assert_pg_area_clear_of_macro_bodies {name area} {
    upvar 1 SRAM_PTRS sram_ptrs

    foreach ptr $sram_ptrs {
        set macro_name [lindex [dbGet $ptr.name] 0]
        set macro_box [join [dbGet $ptr.box]]
        if {[llength $macro_box] != 4} {
            error "Cannot decode SRAM macro box while checking $name: $macro_name"
        }
        if {[sram_area_overlaps_box $area $macro_box]} {
            error "$name PG area $area overlaps SRAM macro body $macro_name $macro_box"
        }
    }
}

proc sram_add_local_pg_pair {layer direction area width spacing} {
    if {$direction eq "horizontal"} {
        set start_from bottom
        set area_start [lindex $area 1]
        set area_stop [lindex $area 3]
    } elseif {$direction eq "vertical"} {
        set start_from left
        set area_start [lindex $area 0]
        set area_stop [lindex $area 2]
    } else {
        error "Unsupported SRAM PG direction: $direction"
    }

    set offset [pg_track_aligned_pair_offset \
        $area_start $area_stop $layer $width $spacing]

    addStripe \
        -nets {VSS VDD} \
        -layer $layer \
        -direction $direction \
        -width $width \
        -spacing $spacing \
        -start_from $start_from \
        -start_offset $offset \
        -number_of_sets 1 \
        -create_pins 0 \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

deselectAll

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M5

sram_assert_pg_area_clear_of_macro_bodies local_left $local_left_area
sram_add_local_pg_pair \
    M5 vertical $local_left_area $sram_stripe_w $sram_stripe_s

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M5

sram_assert_pg_area_clear_of_macro_bodies local_bottom $local_bottom_area
sram_add_local_pg_pair \
    M4 horizontal $local_bottom_area $sram_stripe_w $sram_stripe_s

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M5

sram_assert_pg_area_clear_of_macro_bodies local_top $local_top_area
sram_add_local_pg_pair \
    M4 horizontal $local_top_area $sram_stripe_w $sram_stripe_s

for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
    set gap_lly [expr {
        $SRAM_Y0 + ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y
    }]
    set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
    set row_gap_area [list $sram_pg_left $gap_lly $sram_pg_right $gap_ury]

    sram_assert_pg_area_clear_of_macro_bodies row_gap_$r $row_gap_area
    sram_add_local_pg_pair \
        M4 horizontal $row_gap_area $sram_stripe_w $sram_stripe_s
}

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M5

sram_assert_pg_area_clear_of_macro_bodies local_right $local_right_area
sram_add_local_pg_pair \
    M5 vertical $local_right_area $sram_stripe_w $sram_stripe_s

if {$SRAM_ENABLE_COLUMN_GAP_PG} {
    for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
        set gap_llx [expr {
            $SRAM_X0 + ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X
        }]
        set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
        set col_gap_area [list $gap_llx $sram_pg_bottom $gap_urx $sram_pg_top]

        sram_assert_pg_area_clear_of_macro_bodies col_gap_$c $col_gap_area
        sram_add_local_pg_pair \
            M5 vertical $col_gap_area $sram_stripe_w $sram_stripe_s
    }
} else {
    puts "SRAM column-gap M5 PG skipped: only edge SRAM collectors are enabled for this debug run."
}

# The ASAP7 SRAM LEF exposes many long horizontal VDD/VSS rails on M4 and no
# M5 PG pin.  nearestTarget sroute selected arbitrary M4 power bars, promoted
# whole rails to special wires, and still left the bottom row open.  Build a
# deterministic two-stripe M5 access pair at the lower-right edge of every
# macro instead.  Each short tap overlaps only the edge portion of the M4 PG
# pin, reaches the M4 collector immediately below the macro, and does not form
# a regular mesh over the SRAM body.
if {![info exists SRAM_PIN_TAP_DEPTH]} {
    set SRAM_PIN_TAP_DEPTH [expr {8.0 * $ASAP7_ROW_HEIGHT}]
}
if {$SRAM_PIN_TAP_DEPTH <= 0.0 || $SRAM_PIN_TAP_DEPTH >= $SRAM_H} {
    error "SRAM_PIN_TAP_DEPTH=$SRAM_PIN_TAP_DEPTH must be inside the SRAM height $SRAM_H"
}

set SRAM_PIN_TAP_AREAS {}
set sram_pin_tap_index 0
setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M5

foreach ptr $SRAM_PTRS {
    set macro_name [lindex [dbGet $ptr.name] 0]
    set macro_point [join [dbGet $ptr.pt]]
    if {[llength $macro_point] != 2} {
        error "Cannot decode SRAM origin for PG tap: $macro_name"
    }
    lassign $macro_point macro_x macro_y

    set tap_llx [expr {$macro_x + $SRAM_W - $SRAM_BLOCKAGE_BORDER}]
    set tap_urx [expr {$macro_x + $SRAM_W - $PG_BOUNDARY_EPS}]
    set tap_lly [expr {max($sram_pg_bottom, $macro_y - $SRAM_MACRO_GAP_Y)}]
    set tap_ury [expr {$macro_y + $SRAM_PIN_TAP_DEPTH}]
    set tap_area [list $tap_llx $tap_lly $tap_urx $tap_ury]

    sram_add_local_pg_pair \
        M5 vertical $tap_area $sram_stripe_w $sram_stripe_s
    lappend SRAM_PIN_TAP_AREAS \
        [list $sram_pin_tap_index $macro_name $tap_area]
    incr sram_pin_tap_index
}

set SRAM_PIN_TAPS_BUILT 1
set SRAM_BLOCKPIN_STITCH_DONE 1

editTrim -nets {VSS VDD}

file mkdir [file dirname $sram_edge_report]
set edge_fh [open $sram_edge_report w]
puts $edge_fh "type name layer direction area"
puts $edge_fh "halo local_left M5 vertical {$local_left_area}"
puts $edge_fh "halo local_bottom M4 horizontal {$local_bottom_area}"
puts $edge_fh "halo local_top M4 horizontal {$local_top_area}"
puts $edge_fh "halo local_right M5 vertical {$local_right_area}"
for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
    set gap_lly [expr {
        $SRAM_Y0 + ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y
    }]
    set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
    puts $edge_fh "gap row_$r M4 horizontal {[list $sram_pg_left $gap_lly $sram_pg_right $gap_ury]}"
}
if {$SRAM_ENABLE_COLUMN_GAP_PG} {
    for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
        set gap_llx [expr {
            $SRAM_X0 + ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X
        }]
        set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
        puts $edge_fh "gap col_$c M5 vertical {[list $gap_llx $sram_pg_bottom $gap_urx $sram_pg_top]}"
    }
}
foreach tap_record $SRAM_PIN_TAP_AREAS {
    lassign $tap_record tap_index macro_name tap_area
    puts $edge_fh "tap macro_$tap_index M5 vertical {$tap_area} instance=$macro_name"
}
close $edge_fh

file mkdir [file dirname $sram_stitch_intent_report]
set stitch_fp [open $sram_stitch_intent_report w]
puts $stitch_fp "strategy deterministic_m5_edge_taps"
puts $stitch_fp "source_layer M4"
puts $stitch_fp "tap_layer M5"
puts $stitch_fp "tap_depth $SRAM_PIN_TAP_DEPTH"
puts $stitch_fp "tap_count [llength $SRAM_PIN_TAP_AREAS]"
puts $stitch_fp "expected_connected_ports [expr {2 * $SRAM_COUNT}]"
puts $stitch_fp "nearest_target_sroute disabled"
close $stitch_fp

clearDrc
deselectAll

puts "===================================================="
puts "SRAM ISLAND PG CREATED"
puts " - Local PG       : M4 bottom/row-gap/top straps plus M5 edge/column-gap spines"
puts " - Column-gap M5  : $SRAM_ENABLE_COLUMN_GAP_PG"
puts " - Skipped columns: none; SRAM PG has priority in all three column gaps"
puts " - SRAM pin taps  : [llength $SRAM_PIN_TAP_AREAS] deterministic M5 edge pairs"
puts " - nearestTarget  : disabled"
puts " - Report  : $sram_edge_report"
puts "===================================================="
