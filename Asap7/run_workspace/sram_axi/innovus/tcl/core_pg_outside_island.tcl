############################################################
## Phase 2: regular core M6/M7 mesh OUTSIDE the SRAM island
##
## The logic PG regions are the right side and the channel above the SRAM
## keepout.  The two boxes are disjoint, so regular PG never crosses a macro.
## A common global phase keeps separately generated layers aligned.
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

foreach required_var {
    SRAM_ISLAND_URX
    SRAM_ISLAND_CUT_URX
    SRAM_NO_MESH_URX
    SRAM_NO_MESH_URY
} {
    if {![info exists $required_var]} {
        error "Missing $required_var before outside-island core PG; rerun finish_macroFP.tcl so outputs/sram_macro_geometry.tcl contains SRAM_NO_MESH_BOX"
    }
}

# M6 is the controlled hand-off layer from the local SRAM M5 collector to the
# global logic mesh.  Its wire shapes begin at the macro-body boundary, cross
# only the right collector halo, and never enter an SRAM body.  M7 remains
# fully outside SRAM_NO_MESH_BOX because it is not needed for block-pin access.
set core_m6_right_llx $SRAM_ISLAND_URX
set core_m7_right_llx [expr {$SRAM_NO_MESH_URX + $core_m7_sram_guard}]
set core_m6_top_lly [expr {$SRAM_NO_MESH_URY + $core_m6_sram_guard}]
set core_m7_top_lly [expr {$SRAM_NO_MESH_URY + $core_m7_sram_guard}]

# Keep regular M6/M7 PG only in the right-side logic rectangle.
set LOGIC_RIGHT_M7_BOX [list \
    $core_m7_right_llx $core_lly \
    $core_urx          $core_ury]

set LOGIC_RIGHT_M6_BOX [list \
    $core_m6_right_llx $core_lly \
    $core_urx          $core_ury]

set LOGIC_TOP_LEFT_M7_BOX [list \
    $core_llx         $core_m7_top_lly \
    $SRAM_NO_MESH_URX $core_ury]

set LOGIC_TOP_LEFT_M6_BOX [list \
    $core_llx         $core_m6_top_lly \
    $SRAM_NO_MESH_URX $core_ury]

pg_assert_box_clear_of_sram_cut \
    LOGIC_RIGHT_M7_BOX $LOGIC_RIGHT_M7_BOX right $core_m7_sram_guard
if {[lindex $LOGIC_RIGHT_M6_BOX 0] < $SRAM_ISLAND_URX} {
    error "M6 SRAM-to-logic hand-off enters the SRAM macro body: $LOGIC_RIGHT_M6_BOX"
}
pg_assert_box_clear_of_sram_cut \
    LOGIC_TOP_LEFT_M7_BOX $LOGIC_TOP_LEFT_M7_BOX top $core_m7_sram_guard
pg_assert_box_clear_of_sram_cut \
    LOGIC_TOP_LEFT_M6_BOX $LOGIC_TOP_LEFT_M6_BOX top $core_m6_sram_guard

puts "External vertical PG boxes:"
puts " - RIGHT M7 : $LOGIC_RIGHT_M7_BOX"
puts " - TOP M7   : $LOGIC_TOP_LEFT_M7_BOX"
puts "External horizontal PG boxes:"
puts " - RIGHT M6 : $LOGIC_RIGHT_M6_BOX"
puts " - TOP M6   : $LOGIC_TOP_LEFT_M6_BOX"
puts " - SRAM guard: M6=$core_m6_sram_guard M7=$core_m7_sram_guard"
puts " - M5/M6 hand-off: right M6 shapes start at SRAM_ISLAND_URX=$SRAM_ISLAND_URX"

# M7 vertical mesh outside island, globally phase-aligned.
set global_m7_first_x [expr {$core_llx + $stripe_m7_offset}]
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M7

foreach area [list $LOGIC_RIGHT_M7_BOX $LOGIC_TOP_LEFT_M7_BOX] {
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

foreach area [list $LOGIC_RIGHT_M6_BOX $LOGIC_TOP_LEFT_M6_BOX] {
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

puts "Regular M6/M7 core mesh created in right and above-island logic regions."
