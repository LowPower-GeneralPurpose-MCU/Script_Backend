############################################################
## Phase 3: stitch local SRAM-island PG to external core PG
##
## No jog and no sroute layer change are used.
##
## Instead of forcing one wide pair into each two-row outer channel:
##   - all three M6 row-gap pairs continue straight to the RIGHT;
##   - all three M7 column-gap pairs continue straight to the TOP.
##
## This preserves the slide's "power lines between SRAMs" principle
## while keeping every wide M6/M7 pair centered in a four-row gap.
############################################################

# Continue each local horizontal M6 row-gap pair from the SRAM blockage
# boundary to the right core boundary.
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M9

for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
    set gap_lly [expr {$SRAM_Y0 + \
        ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y}]
    set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
    set bridge_offset [pg_track_aligned_pair_offset \
        $gap_lly $gap_ury M6 $gap_pair_width $gap_pair_spacing]
    set bridge_area [list \
        $SRAM_ISLAND_CUT_URX $gap_lly \
        $core_urx             $gap_ury]

    addStripe \
        -nets {VDD VSS} \
        -layer M6 \
        -direction horizontal \
        -width $gap_pair_width \
        -spacing $gap_pair_spacing \
        -start_from bottom \
        -start_offset $bridge_offset \
        -number_of_sets 1 \
        -area $bridge_area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# Continue each local vertical M7 column-gap pair from the SRAM blockage
# boundary to the top core boundary.
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M8

for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
    set gap_llx [expr {$SRAM_X0 + \
        ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X}]
    set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
    set bridge_offset [pg_track_aligned_pair_offset \
        $gap_llx $gap_urx M7 $gap_pair_width $gap_pair_spacing]
    set bridge_area [list \
        $gap_llx $SRAM_ISLAND_CUT_URY \
        $gap_urx $core_ury]

    addStripe \
        -nets {VDD VSS} \
        -layer M7 \
        -direction vertical \
        -width $gap_pair_width \
        -spacing $gap_pair_spacing \
        -start_from left \
        -start_offset $bridge_offset \
        -number_of_sets 1 \
        -area $bridge_area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

puts "===================================================="
puts "SRAM ISLAND STITCHED TO EXTERNAL CORE PG"
puts " - 3 M6 row-gap feeders: island -> right-side mesh/ring"
puts " - 3 M7 column-gap feeders: island -> top-side mesh/ring"
puts " - straight, aligned, no jog"
puts "===================================================="
