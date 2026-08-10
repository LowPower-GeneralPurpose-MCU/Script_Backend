############################################################
## SRAM-island collectors connected to the global M8/M9 ring
##
## Reference flow:
##   1. Build an open local ring on the exposed top/right island edges.
##   2. Reuse the global M9-left/M8-bottom ring edges beside the island.
##   3. Add a narrow M5 transition spine at the reused left edge so M4
##      row collectors are electrically tied into the M8/M9 global network.
##   4. Add no-jog M4/M5 collectors in the actual SRAM gaps.
##   5. Use stacked ViaGen connections only at matching-net intersections.
##   6. Connect SRAM block pins to the nearest collector stripe and trim stubs.
##
## ASAP7 layer mapping:
##   M4 is horizontal, M5 is vertical in asap7_tech_4x_201209.lef.
############################################################

foreach required_variable {
    SRAM_MASTER
    SRAM_COUNT
    SRAM_ROWS
    SRAM_COLS
    SRAM_X0
    SRAM_Y0
    SRAM_W
    SRAM_H
    SRAM_MACRO_GAP_X
    SRAM_MACRO_GAP_Y
    SRAM_ISLAND_URX
    SRAM_ISLAND_URY
    SRAM_ISLAND_CUT_URX
    SRAM_ISLAND_CUT_URY
    ASAP7_ROW_HEIGHT
    power_die_llx
    power_die_lly
    stripe_m45_w
    stripe_m45_s
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

set sram_stripe_w $stripe_m45_w
set sram_stripe_s $stripe_m45_s

set sram_pair_total [expr {2.0 * $sram_stripe_w + $sram_stripe_s}]
if {$SRAM_MACRO_GAP_Y <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_Y=$SRAM_MACRO_GAP_Y is too small for one M4 VSS/VDD pair"
}
if {$SRAM_MACRO_GAP_X <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_X=$SRAM_MACRO_GAP_X is too small for one M5 VSS/VDD pair"
}

if {![info exists power_die_urx] || ![info exists power_die_ury]} {
    set sram_pg_die_box [join [dbGet top.fPlan.box]]
    if {[llength $sram_pg_die_box] != 4} {
        error "Cannot decode die box before SRAM island PG: [dbGet top.fPlan.box]"
    }
    lassign $sram_pg_die_box \
        power_die_llx power_die_lly power_die_urx power_die_ury
}
if {![info exists PG_BOUNDARY_EPS]} {
    set PG_BOUNDARY_EPS 0.192
}

# Keep the local collector areas inside the design boundary, while still
# crossing the M8/M9 ring lanes in the die-to-core margin.
set sram_pg_left [expr {$power_die_llx + $PG_BOUNDARY_EPS}]
set sram_pg_bottom [expr {$power_die_lly + $PG_BOUNDARY_EPS}]
set sram_pg_right [expr {min($SRAM_ISLAND_CUT_URX, $power_die_urx - $PG_BOUNDARY_EPS)}]
set sram_pg_top [expr {min($SRAM_ISLAND_CUT_URY, $power_die_ury - $PG_BOUNDARY_EPS)}]

set sram_local_top_lly $SRAM_ISLAND_URY
set sram_local_top_ury $sram_pg_top
set sram_local_left_llx $sram_pg_left
set sram_local_left_urx $SRAM_X0
set sram_local_right_llx $SRAM_ISLAND_URX
set sram_local_right_urx $sram_pg_right
if {![info exists sram_edge_report]} {
    set sram_edge_report ./reports/sram_island_pg_edges.rpt
}

if {$sram_local_top_ury - $sram_local_top_lly <= $sram_pair_total} {
    error "SRAM top halo is too small for the open M4 local-ring pair"
}
if {$sram_local_left_urx - $sram_local_left_llx <= $sram_pair_total} {
    error "SRAM left die/core margin is too small for the M5 transition spine"
}
if {$sram_local_right_urx - $sram_local_right_llx <= $sram_pair_total} {
    error "SRAM right halo is too small for the open M5 local-ring pair"
}

proc sram_pg_overlap_length {wire_box area direction} {
    lassign $wire_box w_llx w_lly w_urx w_ury
    lassign $area a_llx a_lly a_urx a_ury

    set overlap_llx [expr {max($w_llx, $a_llx)}]
    set overlap_lly [expr {max($w_lly, $a_lly)}]
    set overlap_urx [expr {min($w_urx, $a_urx)}]
    set overlap_ury [expr {min($w_ury, $a_ury)}]

    if {$overlap_urx <= $overlap_llx ||
        $overlap_ury <= $overlap_lly} {
        return 0.0
    }

    if {$direction eq "horizontal"} {
        return [expr {$overlap_urx - $overlap_llx}]
    }
    if {$direction eq "vertical"} {
        return [expr {$overlap_ury - $overlap_lly}]
    }

    error "Unsupported SRAM PG edge direction: $direction"
}

proc sram_pg_wire_has_direction {wire_box direction} {
    lassign $wire_box llx lly urx ury
    set is_horizontal [expr {($urx - $llx) >= ($ury - $lly)}]
    if {$direction eq "horizontal"} {
        return $is_horizontal
    }
    if {$direction eq "vertical"} {
        return [expr {!$is_horizontal}]
    }

    error "Unsupported SRAM PG wire direction: $direction"
}

proc sram_pg_edge_wire_stats {net layer direction area} {
    set net_ptr [lindex [dbGet -p top.nets.name $net] 0]
    if {$net_ptr eq "" || $net_ptr eq "0x0"} {
        return [list 0 0.0 0.0]
    }

    if {$direction eq "horizontal"} {
        set required_length [expr {0.75 * ([lindex $area 2] - [lindex $area 0])}]
    } elseif {$direction eq "vertical"} {
        set required_length [expr {0.75 * ([lindex $area 3] - [lindex $area 1])}]
    } else {
        error "Unsupported SRAM PG edge direction: $direction"
    }

    set total_coverage 0.0
    set wire_count 0
    set wire_ptrs [dbGet -p2 $net_ptr.sWires.layer.name $layer]
    if {$wire_ptrs eq "" || $wire_ptrs eq "0x0"} {
        return [list 0 0.0 $required_length]
    }

    foreach wire_ptr $wire_ptrs {
        set wire_box [join [dbGet $wire_ptr.box]]
        if {[llength $wire_box] != 4} {
            continue
        }
        if {![sram_pg_wire_has_direction $wire_box $direction]} {
            continue
        }

        set overlap_length [sram_pg_overlap_length \
            $wire_box $area $direction]
        if {$overlap_length > 0.0} {
            incr wire_count
            set total_coverage [expr {$total_coverage + $overlap_length}]
        }
    }

    return [list $wire_count $total_coverage $required_length]
}

proc sram_pg_assert_edge_wires {report_path edge_specs} {
    file mkdir [file dirname $report_path]

    set fh [open $report_path w]
    puts $fh "edge net layer direction wires coverage_um required_um area"

    set missing_edges {}
    foreach edge_spec $edge_specs {
        lassign $edge_spec edge_name layer direction area
        foreach net {VSS VDD} {
            lassign [sram_pg_edge_wire_stats \
                $net $layer $direction $area] \
                wire_count coverage required

            puts $fh [format "%s %s %s %s %d %.6f %.6f {%s}" \
                $edge_name $net $layer $direction \
                $wire_count $coverage $required [join $area { }]]

            if {$wire_count < 1 || $coverage < $required} {
                lappend missing_edges \
                    "$edge_name/$net/$layer coverage=[format %.6f $coverage] required=[format %.6f $required]"
            }
        }
    }
    close $fh

    if {[llength $missing_edges] != 0} {
        error "Missing SRAM island PG edge wires after editTrim: [join $missing_edges {; }]. See $report_path"
    }

    puts "SRAM island PG edge report: $report_path"
}

# The left global M9 ring is reused as the global edge, but the ASAP7 stack
# still needs a local M5 transition spine.  Create it before the M4 row
# collectors so the horizontal addStripe calls have an existing same-net M5
# target and do not become floating segments before editTrim.
setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M8

set local_left_offset [pg_track_aligned_pair_offset \
    $sram_local_left_llx $sram_local_left_urx \
    M5 $sram_stripe_w $sram_stripe_s]
set local_left_area [list \
    $sram_local_left_llx $sram_pg_bottom \
    $sram_local_left_urx $sram_pg_top]

addStripe \
    -nets {VSS VDD} \
    -layer M5 \
    -direction vertical \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -start_from left \
    -start_offset $local_left_offset \
    -number_of_sets 1 \
    -create_pins 0 \
    -area $local_left_area \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M5

# Exposed top edge of the open local ring.  The M4 pair is stitched to M5
# transition/column collectors.  In the latest Innovus log, direct M4->M9
# stacking created 0 vias, so the reliable topology is M4->M5->M8/M9.
set local_top_offset [pg_track_aligned_pair_offset \
    $sram_local_top_lly $sram_local_top_ury \
    M4 $sram_stripe_w $sram_stripe_s]
set local_top_area [list \
    $sram_pg_left $sram_local_top_lly \
    $sram_pg_right $sram_local_top_ury]

addStripe \
    -nets {VSS VDD} \
    -layer M4 \
    -direction horizontal \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -start_from bottom \
    -start_offset $local_top_offset \
    -number_of_sets 1 \
    -create_pins 0 \
    -area $local_top_area \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
    set gap_lly [expr {
        $SRAM_Y0 + ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y
    }]
    set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
    set stripe_offset [pg_track_aligned_pair_offset \
        $gap_lly $gap_ury M4 $sram_stripe_w $sram_stripe_s]
    set stripe_area [list $sram_pg_left $gap_lly $sram_pg_right $gap_ury]

    addStripe \
        -nets {VSS VDD} \
        -layer M4 \
        -direction horizontal \
        -width $sram_stripe_w \
        -spacing $sram_stripe_s \
        -start_from bottom \
        -start_offset $stripe_offset \
        -number_of_sets 1 \
        -create_pins 0 \
        -area $stripe_area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M8

# Exposed right edge of the open local ring.  Starting at die-bottom lets the
# M5 pair cross the matching M8 global-ring net.  Allowing the via range down
# to M4 also stitches the top edge and internal M4 collectors at same-net
# crossings without any jog.
set local_right_offset [pg_track_aligned_pair_offset \
    $sram_local_right_llx $sram_local_right_urx \
    M5 $sram_stripe_w $sram_stripe_s]
set local_right_area [list \
    $sram_local_right_llx $sram_pg_bottom \
    $sram_local_right_urx $sram_pg_top]

addStripe \
    -nets {VSS VDD} \
    -layer M5 \
    -direction vertical \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -start_from left \
    -start_offset $local_right_offset \
    -number_of_sets 1 \
    -create_pins 0 \
    -area $local_right_area \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
    set gap_llx [expr {
        $SRAM_X0 + ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X
    }]
    set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
    set stripe_offset [pg_track_aligned_pair_offset \
        $gap_llx $gap_urx M5 $sram_stripe_w $sram_stripe_s]
    set stripe_area [list $gap_llx $sram_pg_bottom $gap_urx $sram_pg_top]

    addStripe \
        -nets {VSS VDD} \
        -layer M5 \
        -direction vertical \
        -width $sram_stripe_w \
        -spacing $sram_stripe_s \
        -start_from left \
        -start_offset $stripe_offset \
        -number_of_sets 1 \
        -create_pins 0 \
        -area $stripe_area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# Route macro M3 PG pins only after the stripe targets exist.  Restricting the
# target to stripe prevents a long direct block-pin route to the distant ring.
setSrouteMode -reset
setSrouteMode \
    -extendNearestTarget true \
    -blockPinRouteWithPinWidth true \
    -viaConnectToShape stripe

sroute \
    -connect {blockPin} \
    -nets {VSS VDD} \
    -blockPin useLef \
    -blockPinTarget {stripe}

editTrim -nets {VSS VDD}

set reused_left_area [list \
    $sram_pg_left $sram_pg_bottom \
    $SRAM_X0 $sram_pg_top]
set reused_bottom_area [list \
    $sram_pg_left $sram_pg_bottom \
    $sram_pg_right $SRAM_Y0]
set sram_edge_specs [list \
    [list reused_left M9 vertical $reused_left_area] \
    [list reused_bottom M8 horizontal $reused_bottom_area] \
    [list local_top M4 horizontal $local_top_area] \
    [list local_left M5 vertical $local_left_area] \
    [list local_right M5 vertical $local_right_area]]
sram_pg_assert_edge_wires $sram_edge_report $sram_edge_specs
clearDrc
deselectAll

puts "===================================================="
puts "SRAM ISLAND COLLECTOR PG CREATED"
puts " - Local ring: open M4-top/M5-right pair around exposed island edges"
puts " - Reused edge: global M9-left and M8-bottom; no duplicate closed ring"
puts " - Left stitch: narrow M5 transition spine for M4->M5->M8 connectivity"
puts " - BlockPin: nearest M4/M5 stripe target"
puts " - Stripes : one VSS/VDD pair in every SRAM row/column gap"
puts "===================================================="
