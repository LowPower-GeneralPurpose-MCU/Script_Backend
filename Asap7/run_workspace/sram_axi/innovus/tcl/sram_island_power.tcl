############################################################
## SRAM-island collectors connected to the global M8/M9 ring
##
## Reference flow:
##   1. Build an open local ring on the exposed top/right island edges.
##   2. Reuse the global M9-left/M8-bottom ring edges beside the island.
##   3. Add no-jog M4/M5 collectors in the actual SRAM gaps.
##   4. Use stacked ViaGen connections only at matching-net intersections.
##   5. Connect SRAM block pins to the nearest collector stripe and trim stubs.
##
## ASAP7 layer mapping:
##   M4 is horizontal, M5 is vertical in asap7_tech_4x_201209.lef.
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
    SRAM_ISLAND_URX
    SRAM_ISLAND_URY
    SRAM_ISLAND_CUT_URX
    SRAM_ISLAND_CUT_URY
    ASAP7_ROW_HEIGHT
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

deselectAll

set sram_stripe_w $stripe_m45_w
set sram_stripe_s $stripe_m45_s

set sram_pair_total [expr {2.0 * $sram_stripe_w + $sram_stripe_s}]
if {$SRAM_MACRO_GAP_Y <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_Y=$SRAM_MACRO_GAP_Y is too small for one M4 VSS/VDD pair"
}
if {$SRAM_MACRO_GAP_X <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_X=$SRAM_MACRO_GAP_X is too small for one M5 VSS/VDD pair"
}

# Start at the die boundary so each area crosses the already existing global
# ring.  editTrim later removes the stub outside the matching-net landing.
set sram_pg_left $power_die_llx
set sram_pg_bottom $power_die_lly
set sram_pg_right $SRAM_ISLAND_CUT_URX
set sram_pg_top $SRAM_ISLAND_CUT_URY

set sram_local_top_lly $SRAM_ISLAND_URY
set sram_local_top_ury $SRAM_ISLAND_CUT_URY
set sram_local_right_llx $SRAM_ISLAND_URX
set sram_local_right_urx $SRAM_ISLAND_CUT_URX

if {$sram_local_top_ury - $sram_local_top_lly <= $sram_pair_total} {
    error "SRAM top halo is too small for the open M4 local-ring pair"
}
if {$sram_local_right_urx - $sram_local_right_llx <= $sram_pair_total} {
    error "SRAM right halo is too small for the open M5 local-ring pair"
}

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M9

# Exposed top edge of the open local ring.  The area begins at die-left so
# this M4 pair crosses and via-stacks to the matching M9 global-ring net.
set local_top_offset [pg_track_aligned_pair_offset \
    $sram_local_top_lly $sram_local_top_ury \
    M4 $sram_stripe_w $sram_stripe_s]
set local_top_area [list \
    $sram_pg_left $sram_local_top_lly \
    $sram_pg_right $sram_local_top_ury]

addStripe \
    -nets {VSS VDD} \
    -layer M4 \
    -direction horizontal \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -start_from bottom \
    -start_offset $local_top_offset \
    -number_of_sets 1 \
    -create_pins 0 \
    -area $local_top_area \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
    set gap_lly [expr {
        $SRAM_Y0 + ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y
    }]
    set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
    set stripe_offset [pg_track_aligned_pair_offset \
        $gap_lly $gap_ury M4 $sram_stripe_w $sram_stripe_s]
    set stripe_area [list $sram_pg_left $gap_lly $sram_pg_right $gap_ury]

    addStripe \
        -nets {VSS VDD} \
        -layer M4 \
        -direction horizontal \
        -width $sram_stripe_w \
        -spacing $sram_stripe_s \
        -start_from bottom \
        -start_offset $stripe_offset \
        -number_of_sets 1 \
        -create_pins 0 \
        -area $stripe_area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M8

# Exposed right edge of the open local ring.  Starting at die-bottom lets the
# M5 pair cross the matching M8 global-ring net.  Allowing the via range down
# to M4 also stitches the top edge and internal M4 collectors at same-net
# crossings without any jog.
set local_right_offset [pg_track_aligned_pair_offset \
    $sram_local_right_llx $sram_local_right_urx \
    M5 $sram_stripe_w $sram_stripe_s]
set local_right_area [list \
    $sram_local_right_llx $sram_pg_bottom \
    $sram_local_right_urx $sram_pg_top]

addStripe \
    -nets {VSS VDD} \
    -layer M5 \
    -direction vertical \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -start_from left \
    -start_offset $local_right_offset \
    -number_of_sets 1 \
    -create_pins 0 \
    -area $local_right_area \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
    set gap_llx [expr {
        $SRAM_X0 + ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X
    }]
    set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
    set stripe_offset [pg_track_aligned_pair_offset \
        $gap_llx $gap_urx M5 $sram_stripe_w $sram_stripe_s]
    set stripe_area [list $gap_llx $sram_pg_bottom $gap_urx $sram_pg_top]

    addStripe \
        -nets {VSS VDD} \
        -layer M5 \
        -direction vertical \
        -width $sram_stripe_w \
        -spacing $sram_stripe_s \
        -start_from left \
        -start_offset $stripe_offset \
        -number_of_sets 1 \
        -create_pins 0 \
        -area $stripe_area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# Route macro M3 PG pins only after the stripe targets exist.  Restricting the
# target to stripe prevents a long direct block-pin route to the distant ring.
setSrouteMode -reset
setSrouteMode \
    -extendNearestTarget true \
    -blockPinRouteWithPinWidth true \
    -viaConnectToShape stripe

sroute \
    -connect {blockPin} \
    -nets {VSS VDD} \
    -blockPin useLef \
    -blockPinTarget {stripe}

editTrim -nets {VSS VDD}
clearDrc
deselectAll

puts "===================================================="
puts "SRAM ISLAND COLLECTOR PG CREATED"
puts " - Local ring: open M4-top/M5-right pair around exposed island edges"
puts " - Reused edge: global M9-left and M8-bottom; no duplicate local metal"
puts " - BlockPin: nearest M4/M5 stripe target"
puts " - Stripes : one VSS/VDD pair in every SRAM row/column gap"
puts "===================================================="
