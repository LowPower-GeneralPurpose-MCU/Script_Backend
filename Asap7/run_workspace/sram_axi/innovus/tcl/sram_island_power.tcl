############################################################
## Final SRAM-island PG using the reference ring/stripe flow
##
## Reference flow:
##   1. Select all SRAMs in one group.
##   2. Create a shared-cluster block ring.
##   3. Connect SRAM block pins to the nearest block ring.
##   4. Add no-jog M4/M5 stripes that extend to design_boundary
##      and break at block rings.
##   5. Trim redundant PG stubs.
##
## ASAP7 layer mapping:
##   M4 is horizontal, M5 is vertical in asap7_tech_4x_201209.lef.
############################################################

foreach required_variable {
    SRAM_MASTER
    SRAM_COUNT
    SRAM_PG_MODEL_RING_W
    SRAM_PG_MODEL_RING_S
    SRAM_PG_MODEL_STRIPE_W
    SRAM_PG_MODEL_STRIPE_S
    SRAM_PG_MODEL_STRIPE_PITCH
    ASAP7_ROW_HEIGHT
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
foreach ptr $SRAM_PTRS {
    selectInst [lindex [dbGet $ptr.name] 0]
}

set sram_ring_w $SRAM_PG_MODEL_RING_W
set sram_ring_s $SRAM_PG_MODEL_RING_S
set sram_ring_o $ASAP7_ROW_HEIGHT

addRing \
    -nets {VDD VSS} \
    -type block_rings \
    -around shared_cluster \
    -layer {top M4 bottom M4 left M5 right M5} \
    -width [list \
        top $sram_ring_w \
        bottom $sram_ring_w \
        left $sram_ring_w \
        right $sram_ring_w] \
    -spacing [list \
        top $sram_ring_s \
        bottom $sram_ring_s \
        left $sram_ring_s \
        right $sram_ring_s] \
    -offset [list \
        top $sram_ring_o \
        bottom $sram_ring_o \
        left $sram_ring_o \
        right $sram_ring_o] \
    -snap_wire_center_to_grid Grid

setSrouteMode \
    -extendNearestTarget true \
    -blockPinRouteWithPinWidth true \
    -viaConnectToShape blockring

sroute \
    -connect {blockPin} \
    -nets {VDD VSS} \
    -blockPin useLef \
    -blockPinTarget nearestTarget

set sram_stripe_w $SRAM_PG_MODEL_STRIPE_W
set sram_stripe_s $SRAM_PG_MODEL_STRIPE_S
set sram_stripe_pitch $SRAM_PG_MODEL_STRIPE_PITCH
set sram_stripe_offset [expr {$sram_stripe_pitch - 1.5 * $ASAP7_ROW_HEIGHT}]

setAddStripeMode \
    -allow_jog none \
    -break_at block_ring \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M9

addStripe \
    -nets {VDD VSS} \
    -layer M4 \
    -direction horizontal \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -set_to_set_distance $sram_stripe_pitch \
    -extend_to design_boundary \
    -start_from bottom \
    -start_offset $sram_stripe_offset \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

addStripe \
    -nets {VDD VSS} \
    -layer M5 \
    -direction vertical \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -set_to_set_distance $sram_stripe_pitch \
    -extend_to design_boundary \
    -start_from left \
    -start_offset $sram_stripe_offset \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

editTrim -nets {VDD VSS}
clearDrc
deselectAll

puts "===================================================="
puts "REFERENCE-STYLE SRAM ISLAND PG CREATED"
puts " - Ring    : shared_cluster block ring, M4 horizontal / M5 vertical"
puts " - BlockPin: nearest blockring target"
puts " - Stripes : M4/M5, no jog, break_at block_ring, extend_to design_boundary"
puts "===================================================="
