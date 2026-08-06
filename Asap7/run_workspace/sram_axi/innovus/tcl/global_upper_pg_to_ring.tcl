############################################################
## Phase 4: M8/M9 upper PG OUTSIDE the SRAM island
##
## Purpose:
##   - connect the external M6/M7 mesh to the M8/M9 core ring;
##   - keep all regular M8/M9 stripes off the complete SRAM island;
##   - preserve one common global stripe phase across split boxes;
##   - use straight addStripe shapes and let area-boundary targets close them.
##
## Geometry decomposition of the L-shaped non-SRAM region:
##
##   M8 horizontal:
##     1) TOP_FULL_BOX
##     2) RIGHT_LOWER_BOX
##
##   M9 vertical:
##     1) RIGHT_FULL_BOX
##     2) TOP_LEFT_BOX
##
## The boxes extend to the DIE boundary so their stripes can be
## trimmed/stitch-connected to the M8/M9 core ring.  They never enter
## SRAM_ISLAND_CUT_BOX, including its top/right escape channels.
############################################################

puts "===================================================="
puts "PHASE 4: UPPER M8/M9 PG OUTSIDE SRAM ISLAND"
puts "===================================================="

foreach required_var {
    SRAM_ISLAND_CUT_URX SRAM_ISLAND_CUT_URY
    core_llx core_lly core_urx core_ury
} {
    if {![info exists $required_var]} {
        error "Missing variable $required_var before upper PG phase"
    }
}

proc pg_upper_positive_mod {value period} {
    set result [expr {fmod($value, $period)}]
    if {$result < 0.0} {
        set result [expr {$result + $period}]
    }
    return $result
}

# Decode die box.  The core ring lies in the die-to-core margin, so the
# upper-mesh areas must reach the die region rather than stop at coreBox.
set DIE_BOX [join [dbGet top.fPlan.box]]
if {[llength $DIE_BOX] != 4} {
    error "Cannot decode die box: [dbGet top.fPlan.box]"
}
lassign $DIE_BOX die_llx die_lly die_urx die_ury

# L-shaped region outside the complete rectangular island cut box.
# Horizontal-layer decomposition.
set UPPER_TOP_FULL_BOX [list \
    $die_llx $SRAM_ISLAND_CUT_URY \
    $die_urx $die_ury]

set UPPER_RIGHT_LOWER_BOX [list \
    $SRAM_ISLAND_CUT_URX $die_lly \
    $die_urx $SRAM_ISLAND_CUT_URY]

# Vertical-layer decomposition.
set UPPER_RIGHT_FULL_BOX [list \
    $SRAM_ISLAND_CUT_URX $die_lly \
    $die_urx $die_ury]

set UPPER_TOP_LEFT_BOX [list \
    $die_llx $SRAM_ISLAND_CUT_URY \
    $SRAM_ISLAND_CUT_URX $die_ury]

puts " - Die box          : $DIE_BOX"
puts " - SRAM cut UR      : $SRAM_ISLAND_CUT_URX $SRAM_ISLAND_CUT_URY"
puts " - M8 top box       : $UPPER_TOP_FULL_BOX"
puts " - M8 right-lower   : $UPPER_RIGHT_LOWER_BOX"
puts " - M9 right box     : $UPPER_RIGHT_FULL_BOX"
puts " - M9 top-left      : $UPPER_TOP_LEFT_BOX"

# 4x Innovus database values.
set stripe_m89_pitch   34.560
set stripe_m8_w         1.600
set stripe_m8_s         1.280
set stripe_m8_offset   17.280
set stripe_m9_w         1.600
set stripe_m9_s         1.280
set stripe_m9_offset   17.280

# Use the same global phase in every split area.  The reference first
# stripe is measured from the core lower-left, not from each local box.
set global_m8_first_y [expr {$core_lly + $stripe_m8_offset}]
set global_m9_first_x [expr {$core_llx + $stripe_m9_offset}]

# ------------------------------------------------------------
# M8 horizontal upper mesh, outside SRAM island only.
# ViaGen may connect down to existing M7 and up to existing M9 ring.
# ------------------------------------------------------------
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M7 \
    -stacked_via_top_layer M9

foreach area [list $UPPER_TOP_FULL_BOX $UPPER_RIGHT_LOWER_BOX] {
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

foreach area [list $UPPER_RIGHT_FULL_BOX $UPPER_TOP_LEFT_BOX] {
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
        -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

puts "Upper M8/M9 mesh created only outside SRAM_ISLAND_CUT_BOX."
puts "No M8/M9 regular stripe was generated over SRAM macro bodies."
puts "===================================================="
