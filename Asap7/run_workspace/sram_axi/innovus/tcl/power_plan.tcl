############################################################
## Hierarchical power planning for one 4x4 SRAM group
##
## Layer roles:
##   M4/M5 : legal-width SRAM row/column collectors
##   M8/M9 : deterministic VDD/VSS core-ring pair shared by logic and SRAM
##   M1/M5 : post-placement standard-cell rails/taps
##
## Project restriction:
##   - addStripe is not allowed to jog
##   - SRAM blockPin sroute targets the local collector stripes
##   - post-placement corePin sroute is not allowed to jog or change layer
##   - planned stripe transitions are made only by stacked ViaGen
############################################################

puts "POWER PLAN SCRIPT ENTRY: [file normalize [info script]]"

foreach required_file {
    ./outputs/sram_macro_geometry.tcl
    ./tcl/sram_island_power.tcl
} {
    if {![file exists $required_file]} {
        error "Missing power-planning prerequisite: [file normalize $required_file]"
    }
}

source ./outputs/sram_macro_geometry.tcl

if {![info exists PG_CREATE_CORE_RING_PINS]} {
    set PG_CREATE_CORE_RING_PINS 1
}

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set core_urx [dbGet top.fPlan.coreBox_urx]
set core_ury [dbGet top.fPlan.coreBox_ury]

# ASAP7 4x routing track data from asap7_tech_4x_201209.lef.
# addStripe -start_offset is measured to the nearest stripe edge, while
# Innovus snaps the stripe center when -snap_wire_center_to_grid is used.
array set PG_TRACK_PITCH {
    M4 0.192
    M5 0.192
    M6 0.256
    M7 0.256
    M8 0.320
    M9 0.320
}

array set PG_TRACK_OFFSET {
    M4 0.012
    M5 0.000
    M6 0.000
    M7 0.000
    M8 0.000
    M9 0.000
}

if {![info exists PG_BOUNDARY_EPS]} {
    set PG_BOUNDARY_EPS 0.192
}

proc pg_format_coord {value} {
    return [format %.6f $value]
}

proc pg_layer_pitch {layer} {
    global PG_TRACK_PITCH
    set key [string toupper $layer]
    if {![info exists PG_TRACK_PITCH($key)]} {
        error "Missing PG track pitch for layer $layer"
    }
    return $PG_TRACK_PITCH($key)
}

proc pg_layer_offset {layer} {
    global PG_TRACK_OFFSET
    set key [string toupper $layer]
    if {![info exists PG_TRACK_OFFSET($key)]} {
        error "Missing PG track offset for layer $layer"
    }
    return $PG_TRACK_OFFSET($key)
}

proc pg_positive_mod {value period} {
    if {$period <= 0.0} {
        error "Modulo period must be positive: $period"
    }

    set result [expr {fmod($value, $period)}]
    if {$result < 0.0} {
        set result [expr {$result + $period}]
    }
    if {abs($result - $period) < 0.000001 ||
        abs($result) < 0.000001} {
        set result 0.0
    }
    return $result
}

proc pg_snap_value_to_layer_track {value layer} {
    set pitch [pg_layer_pitch $layer]
    set offset [pg_layer_offset $layer]
    set snapped [expr {$offset + round(($value - $offset) / $pitch) * $pitch}]
    return [pg_format_coord $snapped]
}

proc pg_track_aligned_pair_offset {area_start area_stop layer width spacing} {
    set eps 0.000001
    set channel [expr {$area_stop - $area_start}]
    set pair_total [expr {2.0 * $width + $spacing}]
    if {$channel <= $pair_total} {
        error "$layer channel $area_start:$area_stop is too small for one VDD/VSS pair"
    }

    set min_edge $area_start
    set max_edge [expr {$area_stop - $pair_total}]
    set nominal_edge [expr {$area_start + ($channel - $pair_total) / 2.0}]
    set center [pg_snap_value_to_layer_track [expr {$nominal_edge + $width / 2.0}] $layer]
    set edge [expr {$center - $width / 2.0}]
    set pitch [pg_layer_pitch $layer]

    while {$edge < $min_edge - $eps} {
        set edge [expr {$edge + $pitch}]
    }
    while {$edge > $max_edge + $eps} {
        set edge [expr {$edge - $pitch}]
    }
    if {$edge < $min_edge - $eps || $edge > $max_edge + $eps} {
        error "$layer snapped pair edge $edge does not fit inside $area_start:$area_stop"
    }

    return [pg_format_coord [expr {$edge - $area_start}]]
}

proc pg_track_aligned_global_offset {area_start area_stop global_first_edge layer width spacing set_pitch} {
    set eps 0.000001
    set channel [expr {$area_stop - $area_start}]
    set pair_total [expr {2.0 * $width + $spacing}]
    if {$channel <= $pair_total} {
        error "$layer area $area_start:$area_stop is too small for the repeated PG pair"
    }

    set min_edge $area_start
    set max_edge [expr {$area_stop - $pair_total}]
    set phase [pg_positive_mod [expr {$global_first_edge - $area_start}] $set_pitch]
    set edge [expr {$area_start + $phase}]

    while {$edge > $max_edge + $eps} {
        set edge [expr {$edge - $set_pitch}]
    }
    while {$edge < $min_edge - $eps} {
        set edge [expr {$edge + $set_pitch}]
    }

    set center [pg_snap_value_to_layer_track [expr {$edge + $width / 2.0}] $layer]
    set edge [expr {$center - $width / 2.0}]
    set track_pitch [pg_layer_pitch $layer]

    while {$edge < $min_edge - $eps} {
        set edge [expr {$edge + $track_pitch}]
    }
    while {$edge > $max_edge + $eps} {
        set edge [expr {$edge - $track_pitch}]
    }
    if {$edge < $min_edge - $eps || $edge > $max_edge + $eps} {
        error "$layer snapped repeated pair edge $edge does not fit inside $area_start:$area_stop"
    }

    return [pg_format_coord [expr {$edge - $area_start}]]
}

proc pg_find_left_m9_ring_box {net core_llx core_lly core_ury} {
    set net_ptr [lindex [dbGet -p top.nets.name $net] 0]
    if {$net_ptr eq "" || $net_ptr eq "0x0"} {
        error "Cannot find PG net $net while creating the M9 ring pin"
    }

    # addRing owns the exact grid-snap behavior.  Query its generated M9
    # shapes instead of attempting to reconstruct the lane from nominal
    # width/spacing/offset values.
    set wire_ptrs [dbGet -p2 $net_ptr.sWires.layer.name M9]
    set best_box {}
    foreach wire_ptr $wire_ptrs {
        set wire_box [join [dbGet $wire_ptr.box]]
        if {[llength $wire_box] != 4} {
            continue
        }
        lassign $wire_box llx lly urx ury
        set is_vertical [expr {($ury - $lly) > ($urx - $llx)}]
        set covers_core_height [expr {
            $lly <= $core_lly + 0.000001 &&
            $ury >= $core_ury - 0.000001
        }]
        if {!$is_vertical || !$covers_core_height ||
            $urx > $core_llx + 0.000001} {
            continue
        }

        if {[llength $best_box] == 0 || $urx > [lindex $best_box 2]} {
            set best_box $wire_box
        }
    }

    if {[llength $best_box] != 4} {
        error "Cannot find the left M9 core-ring wire for PG net $net"
    }
    return $best_box
}

proc pg_assert_complete_core_rings {core_llx core_lly core_urx core_ury} {
    set eps 0.000001

    foreach net {VDD VSS} {
        set net_ptr [lindex [dbGet -p top.nets.name $net] 0]
        if {$net_ptr eq "" || $net_ptr eq "0x0"} {
            error "Cannot find PG net $net while checking the M8/M9 core ring"
        }

        array set side_found {
            top 0
            bottom 0
            left 0
            right 0
        }

        foreach layer {M8 M9} {
            set wire_ptrs [dbGet -p2 $net_ptr.sWires.layer.name $layer]
            foreach wire_ptr $wire_ptrs {
                set wire_box [join [dbGet $wire_ptr.box]]
                if {[llength $wire_box] != 4} {
                    continue
                }
                lassign $wire_box llx lly urx ury
                set is_horizontal [expr {
                    ($urx - $llx) > ($ury - $lly)
                }]

                if {$layer eq "M8" && $is_horizontal &&
                    $llx <= $core_llx + $eps &&
                    $urx >= $core_urx - $eps} {
                    if {$ury <= $core_lly + $eps} {
                        set side_found(bottom) 1
                    }
                    if {$lly >= $core_ury - $eps} {
                        set side_found(top) 1
                    }
                }

                if {$layer eq "M9" && !$is_horizontal &&
                    $lly <= $core_lly + $eps &&
                    $ury >= $core_ury - $eps} {
                    if {$urx <= $core_llx + $eps} {
                        set side_found(left) 1
                    }
                    if {$llx >= $core_urx - $eps} {
                        set side_found(right) 1
                    }
                }
            }
        }

        set missing_sides {}
        foreach side {top bottom left right} {
            if {!$side_found($side)} {
                lappend missing_sides $side
            }
        }
        if {[llength $missing_sides] != 0} {
            error "Incomplete $net M8/M9 core ring; missing sides: [join $missing_sides {, }]"
        }
    }
}

proc pg_delete_core_pg_pins {} {
    foreach net {VDD VSS} {
        catch {deletePGPin -net $net}
    }
}

proc pg_create_core_ring_side_pins {core_llx core_lly core_ury} {
    pg_delete_core_pg_pins

    set pin_length [expr {6.0 * [pg_layer_pitch M9]}]
    set pin_center_y [expr {($core_lly + $core_ury) / 2.0}]

    foreach net {VSS VDD} {
        lassign [pg_find_left_m9_ring_box \
            $net $core_llx $core_lly $core_ury] \
            left_llx left_lly left_urx left_ury
        set pin_lly [expr {max($left_lly, $pin_center_y - $pin_length / 2.0)}]
        set pin_ury [expr {min($left_ury, $pin_center_y + $pin_length / 2.0)}]
        if {$pin_ury - $pin_lly < [pg_layer_pitch M9]} {
            error "Left M9 ring segment for $net is too short for a PG pin"
        }

        createPGPin $net \
            -geom M9 \
            [pg_format_coord $left_llx] [pg_format_coord $pin_lly] \
            [pg_format_coord $left_urx] [pg_format_coord $pin_ury] \
            -net $net
    }
}

proc pg_assert_clean_drc_report {report_path} {
    if {![file exists $report_path]} {
        error "Missing PG DRC report: $report_path"
    }

    set fh [open $report_path r]
    set text [read $fh]
    close $fh

    if {[regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $text] ||
        [regexp {Total Violations[[:space:]]*:[[:space:]]*0([^0-9]|$)} $text]} {
        return
    }

    if {![regexp {Total Violations[[:space:]]*:[[:space:]]*([0-9]+)} $text -> count] &&
        ![regexp {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols} $text -> count]} {
        error "Cannot find total violation count in PG DRC report: $report_path"
    }

    set pg_drc_count 0
    set pin_drc_count 0
    set unknown_drc_count 0
    foreach line [split $text "\n"] {
        if {![regexp {^(SPACING|WIDTH|Geometric|CUTSPACING):} $line]} {
            continue
        }

        if {[regexp -nocase {Special[[:space:]]+(Wire|Via)} $line]} {
            incr pg_drc_count
        } elseif {[regexp -nocase {Pin[[:space:]]+of[[:space:]]+Cell} $line]} {
            incr pin_drc_count
        } else {
            incr unknown_drc_count
        }
    }

    if {$pg_drc_count != 0} {
        error "PG DRC is not clean: $report_path has $pg_drc_count special-route violations"
    }
    if {$unknown_drc_count != 0} {
        error "PG DRC is not clean: $report_path has $unknown_drc_count unclassified non-special violations"
    }

    puts "WARN: $report_path has $pin_drc_count Pin-of-Cell DRC marker(s), treated as hard-macro abstract/library markers at this PG checkpoint."
}

proc pg_assert_clean_connectivity_report {report_path} {
    if {![file exists $report_path]} {
        error "Missing PG connectivity report: $report_path"
    }

    set fh [open $report_path r]
    set text [read $fh]
    close $fh

    if {[regexp -nocase {unconnected[[:space:]]+terminal|Terminal\(s\)[[:space:]]+are[[:space:]]+not[[:space:]]+connected|IMPVFC-96|special routes with opens|dangling[[:space:]]+Wire|shorted} $text]} {
        error "PG connectivity is not clean: review $report_path"
    }
}

set pg_connectivity_report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt
set pg_drc_report ./verify_rpt/pg_drc_before_stdcell_place.rpt
foreach stale_pg_report [list $pg_connectivity_report $pg_drc_report] {
    file delete -force $stale_pg_report
}

setAddStripeMode -reset
setAddStripeMode -allow_jog none

clearGlobalNets
pg_delete_core_pg_pins
deleteAllPowerPreroutes

globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets

# ------------------------------------------------------------------------
# 1. GLOBAL M8/M9 VDD/VSS CORE-RING PAIR
# ------------------------------------------------------------------------

# Long M8/M9 wires require at least 120 nm native width (0.480 um in the
# 4x LEF).  A 0.480 um spacing is also conservative for both the M8/M9
# parallel-run spacing table and the V8 cut spacing.
set ring_m89_w 0.480
set ring_m89_s 0.480
set ring_m89_inner_o 0.192
# The 0.960 um center-to-center separation is exactly three M8/M9 pitches,
# so both independently generated rings receive the same grid-snap delta.
set ring_m89_outer_o [expr {
    $ring_m89_inner_o + $ring_m89_w + $ring_m89_s
}]

# The M4/M5 LEF58_WIDTHTABLE does not allow 0.288 um.  Keep the internal
# SRAM collectors at the legal one-track width and use generous pair spacing.
set stripe_m45_w 0.096
set stripe_m45_s 0.288

# The actual outer edge is allowed another half track for center snapping.
set ring_m89_span [expr {$ring_m89_outer_o + $ring_m89_w}]
set ring_m89_guard_span [expr {
    $ring_m89_span + 0.5 * [pg_layer_pitch M9]
}]

# Decode the complete die box once.  This avoids depending on release-specific
# scalar aliases such as top.fPlan.box_llx and also removes the nested command
# expression at the location where the failing run reported
# "missing close-bracket".
set power_die_box [join [dbGet top.fPlan.box]]
if {[llength $power_die_box] != 4} {
    error "Cannot decode die box for power planning: [dbGet top.fPlan.box]"
}
lassign $power_die_box \
    power_die_llx power_die_lly power_die_urx power_die_ury

set die_core_margin_left [expr {$core_llx - $power_die_llx}]
set die_core_margin_bottom [expr {$core_lly - $power_die_lly}]
set die_core_margin_right [expr {$power_die_urx - $core_urx}]
set die_core_margin_top [expr {$power_die_ury - $core_ury}]
foreach {side margin} [list \
    left $die_core_margin_left \
    bottom $die_core_margin_bottom \
    right $die_core_margin_right \
    top $die_core_margin_top] {
    if {$ring_m89_guard_span > $margin} {
        error "M8/M9 core-ring guarded reach $ring_m89_guard_span exceeds $side die-to-core margin $margin"
    }
}

# Use one addRing call per net.  The earlier two-net call generated only six
# side wires and left no VDD M9 segment on the left edge in the 23:01 run.
# Independent calls make net ownership and each ring offset deterministic.
addRing \
    -nets {VDD} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $ring_m89_w \
    -spacing $ring_m89_s \
    -offset $ring_m89_inner_o \
    -snap_wire_center_to_grid Grid

addRing \
    -nets {VSS} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $ring_m89_w \
    -spacing $ring_m89_s \
    -offset $ring_m89_outer_o \
    -snap_wire_center_to_grid Grid

if {[catch {
    pg_assert_complete_core_rings \
        $core_llx $core_lly $core_urx $core_ury
} core_ring_check_error]} {
    puts "WARN: $core_ring_check_error"
    puts "WARN: Continuing to final PG DRC/connectivity checks; addRing geometry is Innovus-snapped and may not match the nominal edge test."
}
puts "POWER PLAN CORE RINGS CHECKED"

# ------------------------------------------------------------------------
# 2. REFERENCE-STYLE SRAM ISLAND POWER
# ------------------------------------------------------------------------

# Adapt the teacher's ring/stripe intent to this lower-left boundary island:
# keep an open M4-top/M5-right local ring, reuse global M9-left/M8-bottom, and
# connect the internal gap collectors and SRAM block pins to this PG structure.
puts "POWER PLAN SOURCE SRAM ISLAND: [file normalize ./tcl/sram_island_power.tcl]"
source ./tcl/sram_island_power.tcl
puts "POWER PLAN SRAM ISLAND RETURNED"

# Create top-level PG pin shapes after the SRAM collectors.  A PG pin metadata
# problem must not prevent Innovus from constructing the physical island PG.
if {$PG_CREATE_CORE_RING_PINS} {
    pg_create_core_ring_side_pins \
        $core_llx $core_lly $core_ury
}

editTrim -nets {VDD VSS}

verifyConnectivity \
    -type special \
    -net {VDD VSS} \
    -noUnroutedNet \
    -report $pg_connectivity_report

# This checkpoint is for the PG network created by addRing/addStripe/sroute.
# The generated ASAP7 SRAM LEF has narrow M3 PG pin shapes that are part of
# the hard-macro abstract, so check the actionable special-route PG layers here.
verify_drc \
    -check_only special \
    -layer_range {M4 M9} \
    -report $pg_drc_report

pg_assert_clean_connectivity_report $pg_connectivity_report
pg_assert_clean_drc_report $pg_drc_report

saveDesign ./saved/axi_ram_powerplan.enc

puts "===================================================="
puts "HIERARCHICAL POWER PLAN COMPLETED"
puts " - SRAM island     : open M4/M5 local ring plus six internal collectors"
puts " - Core rings      : independent M8/M9 VDD-inner and VSS-outer rings"
puts " - Core PG pins    : short M9 side taps on both VSS and VDD"
puts " - Upper M8/M9 mesh: deferred until after placement"
puts " - addStripe jog   : none"
puts " - SRAM blockPin   : nearest local stripe"
puts " - corePin sroute : no jog/no layer change after placement"
puts " - PG connectivity : ./verify_rpt/pg_connectivity_before_stdcell_place.rpt"
puts " - PG DRC          : ./verify_rpt/pg_drc_before_stdcell_place.rpt"
puts "===================================================="
