############################################################
## Phase 1A: SRAM-island local M6/M7 power mesh
##
## The island PG is created FIRST and is geometrically limited to:
##   - the three vertical gaps between SRAM columns,
##   - the three horizontal gaps between SRAM rows,
##
## No regular core mesh is generated over SRAM macro bodies.
## The three gap pairs themselves are extended into the external
## core mesh by stitch_island_to_core.tcl.  This avoids forcing a
## 2.176 um M6/M7 pair into a two-row 2.160 um outer channel.
############################################################

set gap_pair_width   0.640
set gap_pair_spacing 0.896
set gap_pair_total \
    [expr {2.0 * $gap_pair_width + $gap_pair_spacing}]

if {$SRAM_MACRO_GAP_X <= $gap_pair_total} {
    error "SRAM_MACRO_GAP_X=$SRAM_MACRO_GAP_X is too small for one VDD/VSS pair"
}
if {$SRAM_MACRO_GAP_Y <= $gap_pair_total} {
    error "SRAM_MACRO_GAP_Y=$SRAM_MACRO_GAP_Y is too small for one VDD/VSS pair"
}

# ------------------------------------------------------------
# Vertical M7 pairs: only inside the three column gaps.
# Each pair reaches the top edge of the SRAM blockage.
# ------------------------------------------------------------
setAddStripeMode \
    -allow_jog none \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M8

for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
    set gap_llx [expr {$SRAM_X0 + \
        ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X}]
    set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
    set local_offset [pg_track_aligned_pair_offset \
        $gap_llx $gap_urx M7 $gap_pair_width $gap_pair_spacing]
    set area [list \
        $gap_llx $SRAM_ISLAND_CUT_LLY \
        $gap_urx $SRAM_ISLAND_CUT_URY]

    addStripe \
        -nets {VDD VSS} \
        -layer M7 \
        -direction vertical \
        -width $gap_pair_width \
        -spacing $gap_pair_spacing \
        -start_from left \
        -start_offset $local_offset \
        -number_of_sets 1 \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# ------------------------------------------------------------
# Horizontal M6 pairs: only inside the three row gaps.
# Each pair reaches the right edge of the SRAM blockage.
# ------------------------------------------------------------
setAddStripeMode \
    -allow_jog none \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M7

for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
    set gap_lly [expr {$SRAM_Y0 + \
        ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y}]
    set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
    set local_offset [pg_track_aligned_pair_offset \
        $gap_lly $gap_ury M6 $gap_pair_width $gap_pair_spacing]
    set area [list \
        $SRAM_ISLAND_CUT_LLX $gap_lly \
        $SRAM_ISLAND_CUT_URX $gap_ury]

    addStripe \
        -nets {VDD VSS} \
        -layer M6 \
        -direction horizontal \
        -width $gap_pair_width \
        -spacing $gap_pair_spacing \
        -start_from bottom \
        -start_offset $local_offset \
        -number_of_sets 1 \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

puts "===================================================="
puts "LOCAL SRAM-ISLAND PG CREATED"
puts " - 3 M7 column-gap VDD/VSS pairs"
puts " - 3 M6 row-gap VDD/VSS pairs"
puts " - no wide M6/M7 pair forced into a two-row edge channel"
puts " - no regular core mesh over SRAM macro bodies"
puts "===================================================="
