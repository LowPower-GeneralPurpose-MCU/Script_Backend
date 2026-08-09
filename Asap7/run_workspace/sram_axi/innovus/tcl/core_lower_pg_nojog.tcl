############################################################
## Post-placement lower PG for standard-cell region
##
## 1. Create straight same-layer M1 follow-pin rails.
## 2. Add external M5 vertical taps with explicit M1->M5 VIAGEN stacks.
## No regular M5 mesh is created inside the SRAM island.
############################################################

setSrouteMode \
    -viaConnectToShape {ring stripe blockring}

sroute \
    -connect {corePin} \
    -nets {VDD VSS} \
    -corePinCheckStdcellGeoms \
    -allowJogging 0 \
    -allowLayerChange 0

if {![info exists stripe_m5_w]} {
    if {[info exists stripe_m45_w]} {
        set stripe_m5_w $stripe_m45_w
    } else {
        set stripe_m5_w 0.096
    }
}
if {![info exists stripe_m5_s]} {
    if {[info exists stripe_m45_s]} {
        set stripe_m5_s $stripe_m45_s
    } else {
        set stripe_m5_s 0.288
    }
}
if {![info exists stripe_m45_pitch]} {
    set stripe_m45_pitch 25.920
}
if {![info exists stripe_m5_offset]} {
    if {[info exists ASAP7_ROW_HEIGHT]} {
        set stripe_m5_offset [expr {$stripe_m45_pitch - 1.5 * $ASAP7_ROW_HEIGHT}]
    } else {
        set stripe_m5_offset [expr {0.5 * $stripe_m45_pitch}]
    }
}

set lower_pg_die_box [join [dbGet top.fPlan.box]]
if {[llength $lower_pg_die_box] != 4} {
    error "Cannot decode die box before lower core PG: [dbGet top.fPlan.box]"
}
lassign $lower_pg_die_box \
    lower_pg_die_llx lower_pg_die_lly lower_pg_die_urx lower_pg_die_ury

if {![info exists LOGIC_RIGHT_EDGE_TAP_BOX] ||
    ![info exists LOGIC_RIGHT_FULL_BOX] ||
    ![info exists LOGIC_TOP_LEFT_BOX]} {
    foreach required_var {
        SRAM_ISLAND_CUT_URX
        SRAM_ISLAND_CUT_URY
        core_llx
        core_lly
        core_urx
        core_ury
    } {
        if {![info exists $required_var]} {
            error "Missing $required_var before lower core PG box rebuild"
        }
    }

    if {[info exists ASAP7_ROW_HEIGHT]} {
        set logic_edge_tap_span [expr {4.0 * $ASAP7_ROW_HEIGHT}]
    } else {
        set logic_edge_tap_span 4.320
    }
    set logic_edge_tap_min_span [expr {
        2.0 * $stripe_m5_w + $stripe_m5_s + 2.0 * [pg_layer_pitch M5]
    }]
    if {$logic_edge_tap_span < $logic_edge_tap_min_span} {
        set logic_edge_tap_span $logic_edge_tap_min_span
    }
    set logic_edge_tap_urx [expr {
        min($core_urx, $SRAM_ISLAND_CUT_URX + $logic_edge_tap_span)
    }]
    if {$logic_edge_tap_urx <= $SRAM_ISLAND_CUT_URX + $logic_edge_tap_min_span} {
        error "Not enough logic channel beside SRAM island for first M5 edge tap"
    }

    set LOGIC_RIGHT_EDGE_TAP_BOX [list \
        $SRAM_ISLAND_CUT_URX $lower_pg_die_lly \
        $logic_edge_tap_urx  $lower_pg_die_ury]
    set LOGIC_RIGHT_FULL_BOX [list \
        $logic_edge_tap_urx $lower_pg_die_lly \
        $core_urx           $lower_pg_die_ury]
    set LOGIC_TOP_LEFT_BOX [list \
        $core_llx              $SRAM_ISLAND_CUT_URY \
        $SRAM_ISLAND_CUT_URX   $lower_pg_die_ury]
}

set global_m5_first_x [expr {$core_llx + $stripe_m5_offset}]
setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M1 \
    -stacked_via_top_layer M5

foreach area [list $LOGIC_RIGHT_EDGE_TAP_BOX $LOGIC_RIGHT_FULL_BOX $LOGIC_TOP_LEFT_BOX] {
    set area_llx [lindex $area 0]
    set area_urx [lindex $area 2]

    if {$area eq $LOGIC_RIGHT_EDGE_TAP_BOX} {
        set area_offset [pg_track_aligned_pair_offset \
            $area_llx $area_urx M5 $stripe_m5_w $stripe_m5_s]
        set area_sets 1
    } else {
        set area_offset [pg_track_aligned_global_offset \
            $area_llx $area_urx $global_m5_first_x \
            M5 $stripe_m5_w $stripe_m5_s $stripe_m45_pitch]
        set area_sets ""
    }

    if {$area_sets ne ""} {
        addStripe \
            -nets {VDD VSS} \
            -layer M5 \
            -direction vertical \
            -width $stripe_m5_w \
            -spacing $stripe_m5_s \
            -set_to_set_distance $stripe_m45_pitch \
            -start_from left \
            -start_offset $area_offset \
            -number_of_sets $area_sets \
            -create_pins 0 \
            -area $area \
            -snap_wire_center_to_grid Grid \
            -allow_snapping_override_custom_spacing 1
    } else {
        addStripe \
            -nets {VDD VSS} \
            -layer M5 \
            -direction vertical \
            -width $stripe_m5_w \
            -spacing $stripe_m5_s \
            -set_to_set_distance $stripe_m45_pitch \
            -start_from left \
            -start_offset $area_offset \
            -create_pins 0 \
            -area $area \
            -snap_wire_center_to_grid Grid \
            -allow_snapping_override_custom_spacing 1
    }
}

puts "Post-placement M1/M5 core PG completed with a first SRAM-edge tap and no jog/no layer change."
