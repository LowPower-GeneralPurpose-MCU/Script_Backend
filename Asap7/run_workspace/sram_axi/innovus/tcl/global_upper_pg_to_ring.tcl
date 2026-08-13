############################################################
## Phase 4: M8/M9 upper PG OUTSIDE the SRAM island
##
## Purpose:
##   - connect the external M6/M7 mesh to the M8/M9 core ring;
##   - keep all regular M8/M9 stripes off the complete SRAM no-mesh column;
##   - preserve one common global stripe phase across split boxes;
##   - use straight addStripe shapes and let area-boundary targets close them.
##
## Geometry decomposition of the non-SRAM region:
##
##   M8 horizontal:
##     1) RIGHT_FULL_BOX
##
##   M9 vertical:
##     1) RIGHT_FULL_BOX
##
## The boxes extend to the DIE boundary so their stripes can be
## trimmed/stitch-connected to the M8/M9 core ring.  They never enter
## SRAM_NO_MESH_BOX, including the column above the SRAM macros.
############################################################

puts "===================================================="
puts "PHASE 4: UPPER M8/M9 PG OUTSIDE SRAM ISLAND"
puts "===================================================="

foreach required_var {
    SRAM_ISLAND_CUT_URX SRAM_NO_MESH_URX
    core_llx core_lly core_urx core_ury
} {
    if {![info exists $required_var]} {
        error "Missing variable $required_var before upper PG phase; rerun finish_macroFP.tcl so outputs/sram_macro_geometry.tcl contains SRAM_NO_MESH_BOX"
    }
}

proc pg_upper_positive_mod {value period} {
    set result [expr {fmod($value, $period)}]
    if {$result < 0.0} {
        set result [expr {$result + $period}]
    }
    return $result
}

proc pg_upper_snap_up_to_layer_track {value layer} {
    set pitch [pg_layer_pitch $layer]
    set offset [pg_layer_offset $layer]
    set snapped [expr {$offset + ceil(($value - $offset) / $pitch) * $pitch}]
    return [pg_format_coord $snapped]
}

# Decode die box.  The core ring lies in the die-to-core margin, so the
# upper-mesh areas must reach the die region rather than stop at coreBox.
set DIE_BOX [join [dbGet top.fPlan.box]]
if {[llength $DIE_BOX] != 4} {
    error "Cannot decode die box: [dbGet top.fPlan.box]"
}
lassign $DIE_BOX die_llx die_lly die_urx die_ury
if {![info exists PG_BOUNDARY_EPS]} {
    set PG_BOUNDARY_EPS 0.192
}

set upper_die_llx [expr {$die_llx + $PG_BOUNDARY_EPS}]
set upper_die_lly [expr {$die_lly + $PG_BOUNDARY_EPS}]
set upper_die_urx [expr {$die_urx - $PG_BOUNDARY_EPS}]
set upper_die_ury [expr {$die_ury - $PG_BOUNDARY_EPS}]

# 4x Innovus database values.
set stripe_m89_pitch   34.560
set stripe_m8_w         1.600
set stripe_m8_s         1.280
set stripe_m8_offset   17.280
set stripe_m9_w         1.600
set stripe_m9_s         1.280
set stripe_m9_offset   17.280

set upper_m8_sram_guard [pg_layer_boundary_guard M8 $stripe_m8_w]
set upper_m9_sram_guard [pg_layer_boundary_guard M9 $stripe_m9_w]

set upper_m8_right_llx [pg_upper_snap_up_to_layer_track \
    [expr {$SRAM_NO_MESH_URX + $upper_m8_sram_guard}] M8]
set upper_m9_right_llx [pg_upper_snap_up_to_layer_track \
    [expr {$SRAM_NO_MESH_URX + $upper_m9_sram_guard}] M9]

# Right-side region outside the complete no-mesh SRAM column.
set UPPER_RIGHT_M8_BOX [list \
    $upper_m8_right_llx $upper_die_lly \
    $upper_die_urx      $upper_die_ury]

set UPPER_RIGHT_M9_BOX [list \
    $upper_m9_right_llx $upper_die_lly \
    $upper_die_urx      $upper_die_ury]

pg_assert_box_clear_of_sram_cut \
    UPPER_RIGHT_M8_BOX $UPPER_RIGHT_M8_BOX right $upper_m8_sram_guard
pg_assert_box_clear_of_sram_cut \
    UPPER_RIGHT_M9_BOX $UPPER_RIGHT_M9_BOX right $upper_m9_sram_guard

puts " - Die box          : $DIE_BOX"
puts " - SRAM no-mesh UR  : $SRAM_NO_MESH_URX $core_ury"
puts " - SRAM guard       : M8=$upper_m8_sram_guard M9=$upper_m9_sram_guard"
puts " - M8 right box     : $UPPER_RIGHT_M8_BOX"
puts " - M9 right box     : $UPPER_RIGHT_M9_BOX"

# Use the same global phase in every split area.  The reference first
# stripe is measured from the core lower-left, not from each local box.
set global_m8_first_y [expr {$core_lly + $stripe_m8_offset}]
set global_m9_first_x [expr {$core_llx + $stripe_m9_offset}]

# ------------------------------------------------------------
# M8 horizontal upper mesh, outside SRAM island only.
# First connect down only to existing M7 mesh.  M8->M9 is created by the
# following M9 stripe pass, which avoids generating off-grid intermediate M7
# shapes at M9 stripe x-coordinates.
# ------------------------------------------------------------
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M7 \
    -stacked_via_top_layer M8

foreach area [list $UPPER_RIGHT_M8_BOX] {
    set area_lly [lindex $area 1]
    set area_ury [lindex $area 3]
    set area_offset [pg_track_aligned_global_offset \
        $area_lly $area_ury $global_m8_first_y \
        M8 $stripe_m8_w $stripe_m8_s $stripe_m89_pitch]

    addStripe \
        -nets {VDD VSS} \
        -layer M8 \
        -direction horizontal \
        -width $stripe_m8_w \
        -spacing $stripe_m8_s \
        -set_to_set_distance $stripe_m89_pitch \
        -start_from bottom \
        -start_offset $area_offset \
        -create_pins 0 \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# ------------------------------------------------------------
# M9 vertical upper mesh, outside SRAM island only.
# It crosses the new M8 mesh and reaches top/bottom M8 ring segments.
# ------------------------------------------------------------
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M8 \
    -stacked_via_top_layer M9

foreach area [list $UPPER_RIGHT_M9_BOX] {
    set area_llx [lindex $area 0]
    set area_urx [lindex $area 2]
    set area_offset [pg_track_aligned_global_offset \
        $area_llx $area_urx $global_m9_first_x \
        M9 $stripe_m9_w $stripe_m9_s $stripe_m89_pitch]

    addStripe \
        -nets {VDD VSS} \
        -layer M9 \
        -direction vertical \
        -width $stripe_m9_w \
        -spacing $stripe_m9_s \
        -set_to_set_distance $stripe_m89_pitch \
        -start_from left \
        -start_offset $area_offset \
        -create_pins 0 \
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

puts "Upper M8/M9 mesh created only to the right of SRAM_NO_MESH_BOX."
puts "No M8/M9 regular stripe was generated above or over the SRAM island."
puts "===================================================="
