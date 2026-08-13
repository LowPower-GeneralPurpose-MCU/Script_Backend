############################################################
## Phase 2: regular core M6/M7 mesh OUTSIDE the SRAM island
##
## The L-shaped logic region is decomposed into non-overlapping boxes.
## A common global phase keeps separately generated segments aligned.
## M6 is later tied down to M5 taps and up to M7; M8/M9 connection is
## handled in global_upper_pg_to_ring.tcl.  Avoid direct M1->M8 stacks,
## because ASAP7 M5 and M7 tracks do not share the same pitch/grid.
############################################################

proc pg_positive_mod {value period} {
    set result [expr {fmod($value, $period)}]
    if {$result < 0.0} {
        set result [expr {$result + $period}]
    }
    return $result
}

if {![info exists stripe_m67_pitch]} {
    set stripe_m67_pitch 34.560
}
if {![info exists stripe_m6_w]} {
    set stripe_m6_w 0.128
}
if {![info exists stripe_m6_s]} {
    set stripe_m6_s 0.288
}
if {![info exists stripe_m6_offset]} {
    set stripe_m6_offset 17.280
}
if {![info exists stripe_m7_w]} {
    set stripe_m7_w 0.128
}
if {![info exists stripe_m7_s]} {
    set stripe_m7_s 0.288
}
if {![info exists stripe_m7_offset]} {
    set stripe_m7_offset 17.280
}

set core_m6_sram_guard [pg_layer_boundary_guard M6 $stripe_m6_w]
set core_m7_sram_guard [pg_layer_boundary_guard M7 $stripe_m7_w]

set core_m6_right_llx [expr {$SRAM_ISLAND_CUT_URX + $core_m6_sram_guard}]
set core_m6_top_lly [expr {$SRAM_ISLAND_CUT_URY + $core_m6_sram_guard}]
set core_m7_right_llx [expr {$SRAM_ISLAND_CUT_URX + $core_m7_sram_guard}]
set core_m7_top_lly [expr {$SRAM_ISLAND_CUT_URY + $core_m7_sram_guard}]

# Vertical-layer regions: right side full-height + top-left above island.
set LOGIC_RIGHT_FULL_BOX [list \
    $core_m7_right_llx $core_lly \
    $core_urx          $core_ury]
set LOGIC_TOP_LEFT_BOX [list \
    $core_llx            $core_m7_top_lly \
    $SRAM_ISLAND_CUT_URX $core_ury]

# Horizontal-layer regions: top full-width + right-lower beside island.
set LOGIC_TOP_FULL_BOX [list \
    $core_llx $core_m6_top_lly \
    $core_urx $core_ury]
set LOGIC_RIGHT_LOWER_BOX [list \
    $core_m6_right_llx $core_lly \
    $core_urx          $SRAM_ISLAND_CUT_URY]

pg_assert_box_clear_of_sram_cut \
    LOGIC_RIGHT_FULL_BOX $LOGIC_RIGHT_FULL_BOX right $core_m7_sram_guard
pg_assert_box_clear_of_sram_cut \
    LOGIC_TOP_LEFT_BOX $LOGIC_TOP_LEFT_BOX top $core_m7_sram_guard
pg_assert_box_clear_of_sram_cut \
    LOGIC_TOP_FULL_BOX $LOGIC_TOP_FULL_BOX top $core_m6_sram_guard
pg_assert_box_clear_of_sram_cut \
    LOGIC_RIGHT_LOWER_BOX $LOGIC_RIGHT_LOWER_BOX right $core_m6_sram_guard

puts "External vertical PG boxes:"
puts " - RIGHT FULL: $LOGIC_RIGHT_FULL_BOX"
puts " - TOP LEFT  : $LOGIC_TOP_LEFT_BOX"
puts "External horizontal PG boxes:"
puts " - TOP FULL  : $LOGIC_TOP_FULL_BOX"
puts " - RIGHT LOW : $LOGIC_RIGHT_LOWER_BOX"
puts " - SRAM guard: M6=$core_m6_sram_guard M7=$core_m7_sram_guard"

# M7 vertical mesh outside island, globally phase-aligned.
set global_m7_first_x [expr {$core_llx + $stripe_m7_offset}]
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M7

foreach area [list $LOGIC_RIGHT_FULL_BOX $LOGIC_TOP_LEFT_BOX] {
    set area_llx [lindex $area 0]
    set area_urx [lindex $area 2]
    set area_offset [pg_track_aligned_global_offset \
        $area_llx $area_urx $global_m7_first_x \
        M7 $stripe_m7_w $stripe_m7_s $stripe_m67_pitch]

    addStripe \
        -nets {VDD VSS} \
        -layer M7 \
        -direction vertical \
        -width $stripe_m7_w \
        -spacing $stripe_m7_s \
        -set_to_set_distance $stripe_m67_pitch \
        -start_from left \
        -start_offset $area_offset \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# M6 horizontal mesh outside island, globally phase-aligned.
set global_m6_first_y [expr {$core_lly + $stripe_m6_offset}]
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M5 \
    -stacked_via_top_layer M7

foreach area [list $LOGIC_TOP_FULL_BOX $LOGIC_RIGHT_LOWER_BOX] {
    set area_lly [lindex $area 1]
    set area_ury [lindex $area 3]
    set area_offset [pg_track_aligned_global_offset \
        $area_lly $area_ury $global_m6_first_y \
        M6 $stripe_m6_w $stripe_m6_s $stripe_m67_pitch]

    addStripe \
        -nets {VDD VSS} \
        -layer M6 \
        -direction horizontal \
        -width $stripe_m6_w \
        -spacing $stripe_m6_s \
        -set_to_set_distance $stripe_m67_pitch \
        -start_from bottom \
        -start_offset $area_offset \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

puts "Regular M6/M7 core mesh created only outside the SRAM island."
