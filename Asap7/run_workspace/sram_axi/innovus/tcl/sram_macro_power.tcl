############################################################
## Phase 1B: connect SRAM M3 PG pins to the local island PG
##
## Project restriction:
##   - follow the SRAM-island blockPin style from the reference flow
##   - do not pass explicit blockPin allowJogging/allowLayerChange switches
##
## M4 local straps and M5 local feeders are added explicitly.
## SRAM block pins connect to the nearest shared-cluster block ring.
############################################################

globalNetConnect VDD \
    -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS \
    -type pgpin -pin VSS -inst * -module {} -override
applyGlobalNets

set local_m4_w 0.096
set local_m4_s 0.288
set local_m5_w 0.096
set local_m5_s 0.288
set local_pair_total \
    [expr {2.0 * $local_m4_w + $local_m4_s}]

# Four M4 collector pairs: one above each physical SRAM row.
# Rows 0..2 use the row gaps; row 3 uses the top escape channel.
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M5

for {set r 0} {$r < $SRAM_ROWS} {incr r} {
    if {$r < [expr {$SRAM_ROWS - 1}]} {
        set channel_lly [expr {$SRAM_Y0 + \
            ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y}]
        set channel_ury [expr {$channel_lly + $SRAM_MACRO_GAP_Y}]
    } else {
        set channel_lly $SRAM_ISLAND_URY
        set channel_ury $SRAM_ISLAND_CUT_URY
    }

    set channel_h [expr {$channel_ury - $channel_lly}]
    if {$channel_h <= $local_pair_total} {
        error "M4 local channel is too small in row $r"
    }

    set local_offset [pg_track_aligned_pair_offset \
        $channel_lly $channel_ury M4 $local_m4_w $local_m4_s]
    set area [list \
        $SRAM_ISLAND_CUT_LLX $channel_lly \
        $SRAM_ISLAND_CUT_URX $channel_ury]

    addStripe \
        -nets {VDD VSS} \
        -layer M4 \
        -direction horizontal \
        -width $local_m4_w \
        -spacing $local_m4_s \
        -start_from bottom \
        -start_offset $local_offset \
        -number_of_sets 1 \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# Four M5 feeder pairs: three column gaps plus right escape channel.
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M7

for {set c 0} {$c < $SRAM_COLS} {incr c} {
    if {$c < [expr {$SRAM_COLS - 1}]} {
        set channel_llx [expr {$SRAM_X0 + \
            ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X}]
        set channel_urx [expr {$channel_llx + $SRAM_MACRO_GAP_X}]
    } else {
        set channel_llx $SRAM_ISLAND_URX
        set channel_urx $SRAM_ISLAND_CUT_URX
    }

    set channel_w [expr {$channel_urx - $channel_llx}]
    set pair_total [expr {2.0 * $local_m5_w + $local_m5_s}]
    if {$channel_w <= $pair_total} {
        error "M5 local channel is too small in column $c"
    }

    set local_offset [pg_track_aligned_pair_offset \
        $channel_llx $channel_urx M5 $local_m5_w $local_m5_s]
    set area [list \
        $channel_llx $SRAM_ISLAND_CUT_LLY \
        $channel_urx $SRAM_ISLAND_CUT_URY]

    addStripe \
        -nets {VDD VSS} \
        -layer M5 \
        -direction vertical \
        -width $local_m5_w \
        -spacing $local_m5_s \
        -start_from left \
        -start_offset $local_offset \
        -number_of_sets 1 \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

setSrouteMode \
    -extendNearestTarget true \
    -blockPinRouteWithPinWidth false \
    -viaConnectToShape blockring

# Follow the reference SRAM-island style: nearest target, blockring target
# shape, and no explicit allowJogging/allowLayerChange switches here.
sroute \
    -connect {blockPin} \
    -nets {VDD VSS} \
    -blockPin useLef \
    -blockPinLayerRange {M3 M3} \
    -blockPinWidthRange {0.0 0.150} \
    -blockPinTarget nearestTarget

puts "Local SRAM M4/M5 PG created; blockPin used nearest shared-cluster blockring target."
