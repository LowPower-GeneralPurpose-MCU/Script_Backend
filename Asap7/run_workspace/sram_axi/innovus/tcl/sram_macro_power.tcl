############################################################
## Phase 1B: connect SRAM M4 PG pins to the local island PG
##
## Project restriction:
##   - no sroute jogging
##   - no sroute layer changes
##
## M4 local straps and M5 local feeders are added explicitly.
## Layer transitions are created only by addStripe/VIAGEN at legal
## same-net intersections.
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

    set local_offset [expr {($channel_h - $local_pair_total) / 2.0}]
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
        -snap_wire_center_to_grid grid
}

# Four M5 feeder pairs: three column gaps plus right escape channel.
setAddStripeMode \
    -allow_jog none \
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

    set local_offset [expr {($channel_w - $pair_total) / 2.0}]
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
        -snap_wire_center_to_grid grid
}

setSrouteMode \
    -extendNearestTarget true \
    -blockPinRouteWithPinWidth true \
    -viaConnectToShape {stripe blockring ring}

# Follow the slide's nearest-target block-pin connection, while retaining
# the project restriction of no jog and no automatic layer change.
# The nearest legal target can be a local stripe or the shared-cluster ring.
sroute \
    -connect {blockPin} \
    -nets {VDD VSS} \
    -blockPin useLef \
    -blockPinTarget nearestTarget \
    -allowJogging 0 \
    -allowLayerChange 0

puts "Local SRAM M4/M5 PG created; blockPin used nearest stripe/blockring with no jog/no layer change."
