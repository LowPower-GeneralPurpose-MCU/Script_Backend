############################################################
## SRAM-island collectors connected to the global M8/M9 ring
##
## Reference flow:
##   1. Add no-jog M4/M5 collectors in the actual SRAM gaps.
##   2. Extend each collector straight to the single global M8/M9 ring.
##   3. Use stacked ViaGen connections only at the ring landing.
##   4. Connect SRAM block pins to the nearest collector stripe.
##   5. Trim redundant PG stubs.
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
    SRAM_ISLAND_CUT_URX
    SRAM_ISLAND_CUT_URY
    ASAP7_ROW_HEIGHT
    core_llx
    core_lly
    ring_m89_span
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

set sram_pg_left $core_llx
set sram_pg_bottom $core_lly
set sram_pg_right $SRAM_ISLAND_CUT_URX
set sram_pg_top $SRAM_ISLAND_CUT_URY

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target ring \
    -extend_to_first_ring true \
    -max_extension_distance $ring_m89_span \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M9

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
    -extend_to_closest_target ring \
    -extend_to_first_ring true \
    -max_extension_distance $ring_m89_span \
    -stacked_via_bottom_layer M5 \
    -stacked_via_top_layer M8

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
puts " - Ring    : reused global M8/M9 core ring; no local M4/M5 ring"
puts " - BlockPin: nearest M4/M5 stripe target"
puts " - Stripes : one pair in every gap, straight via-stack connection to M8/M9"
puts "===================================================="
