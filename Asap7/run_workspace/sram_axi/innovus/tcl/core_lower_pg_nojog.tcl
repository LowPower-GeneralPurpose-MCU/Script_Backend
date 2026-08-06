############################################################
## Post-placement lower PG for standard-cell region
##
## 1. Create straight same-layer M1 follow-pin rails.
## 2. Add external M5 vertical taps with explicit M1->M6 VIAGEN stacks.
## No regular M5 mesh is created inside the SRAM island.
############################################################

setSrouteMode \
    -viaConnectToShape {stripe ring}

sroute \
    -connect {corePin} \
    -nets {VDD VSS} \
    -allowJogging 0 \
    -allowLayerChange 0

set global_m5_first_x [expr {$core_llx + $stripe_m5_offset}]
setAddStripeMode \
    -allow_jog none \
    -stacked_via_bottom_layer M1 \
    -stacked_via_top_layer M6

foreach area [list $LOGIC_RIGHT_FULL_BOX $LOGIC_TOP_LEFT_BOX] {
    set area_llx [lindex $area 0]
    set area_urx [lindex $area 2]
    set area_offset [pg_track_aligned_global_offset \
        $area_llx $area_urx $global_m5_first_x \
        M5 $stripe_m5_w $stripe_m5_s $stripe_m45_pitch]

    addStripe \
        -nets {VDD VSS} \
        -layer M5 \
        -direction vertical \
        -width $stripe_m5_w \
        -spacing $stripe_m5_s \
        -set_to_set_distance $stripe_m45_pitch \
        -start_from left \
        -start_offset $area_offset \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

puts "Post-placement M1/M5 core PG completed with no jog/no layer change."
