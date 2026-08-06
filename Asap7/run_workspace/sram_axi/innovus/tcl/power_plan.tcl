############################################################
## Hierarchical power planning for one 4x4 SRAM group
##
## Layer roles:
##   M4/M5 : aligned core/SRAM rings and reference-style stripes
##   M8/M9 : reserved for a later post-placement global mesh
##   M1/M5 : post-placement standard-cell rails/taps
##
## Project restriction:
##   - addStripe is not allowed to jog
##   - SRAM blockPin sroute follows nearest blockring target
##   - post-placement corePin sroute is not allowed to jog or change layer
##   - planned stripe transitions are made only by stacked ViaGen
############################################################

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

proc pg_core_ring_lane_rect {side net core_llx core_lly core_urx core_ury width spacing offset} {
    switch -- $net {
        VSS {
            set net_delta 0.0
        }
        VDD {
            set net_delta [expr {$width + $spacing}]
        }
        default {
            error "Unsupported core PG pin net: $net"
        }
    }

    switch -- $side {
        bottom {
            set center [pg_snap_value_to_layer_track \
                [expr {$core_lly - $offset - $net_delta - $width / 2.0}] M4]
            set lly [expr {$center - $width / 2.0}]
            set ury [expr {$center + $width / 2.0}]
            return [list M4 $core_llx $lly $core_urx $ury]
        }
        top {
            set center [pg_snap_value_to_layer_track \
                [expr {$core_ury + $offset + $net_delta + $width / 2.0}] M4]
            set lly [expr {$center - $width / 2.0}]
            set ury [expr {$center + $width / 2.0}]
            return [list M4 $core_llx $lly $core_urx $ury]
        }
        left {
            set center [pg_snap_value_to_layer_track \
                [expr {$core_llx - $offset - $net_delta - $width / 2.0}] M5]
            set llx [expr {$center - $width / 2.0}]
            set urx [expr {$center + $width / 2.0}]
            return [list M5 $llx $core_lly $urx $core_ury]
        }
        right {
            set center [pg_snap_value_to_layer_track \
                [expr {$core_urx + $offset + $net_delta + $width / 2.0}] M5]
            set llx [expr {$center - $width / 2.0}]
            set urx [expr {$center + $width / 2.0}]
            return [list M5 $llx $core_lly $urx $core_ury]
        }
        default {
            error "Unsupported core PG pin side: $side"
        }
    }
}

proc pg_delete_core_pg_pins {} {
    foreach net {VDD VSS} {
        catch {deletePGPin -net $net}
    }
}

proc pg_create_core_ring_side_pins {core_llx core_lly core_urx core_ury width spacing offset} {
    pg_delete_core_pg_pins

    set pin_length [expr {6.0 * [pg_layer_pitch M5]}]
    set pin_center_y [expr {($core_lly + $core_ury) / 2.0}]
    set pin_lly [expr {$pin_center_y - $pin_length / 2.0}]
    set pin_ury [expr {$pin_center_y + $pin_length / 2.0}]

    foreach net {VSS VDD} {
        lassign [pg_core_ring_lane_rect \
            left $net $core_llx $core_lly $core_urx $core_ury \
            $width $spacing $offset] \
            left_layer left_llx left_lly left_urx left_ury

        createPGPin $net \
            -geom $left_layer \
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

    if {![regexp {Total Violations[[:space:]]*:[[:space:]]*([0-9]+)} $text -> count]} {
        error "Cannot find total violation count in PG DRC report: $report_path"
    }

    set pg_drc_count 0
    foreach line [split $text "\n"] {
        if {[regexp -nocase {Special[[:space:]]+(Wire|Via)} $line]} {
            incr pg_drc_count
        }
    }

    if {$pg_drc_count != 0} {
        error "PG DRC is not clean: $report_path has $pg_drc_count special-route violations"
    }
    if {$count != 0} {
        puts "WARN: $report_path has $count non-special DRCs; review SRAM macro-pin/fake-layout DRCs at signoff"
    }
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
# 1. M4/M5 CORE RING ALIGNED WITH THE SRAM-ISLAND RING
# ------------------------------------------------------------------------

# ASAP7 4x scales the native 24 nm M4/M5 minimum width to 0.096 um.
# A V4 landing also needs 11 nm enclosure on both sides, so a one-track
# 0.096 um final PG wire is too narrow for a robust legal landing.  Use a
# three-track (0.288 um) final PG width and keep the one-track dimensions
# only in the temporary macro-placement resource model.
set ring_m45_w 0.288
set ring_m45_s 0.288
set ring_m45_o 0.384
set stripe_m45_w 0.288
set stripe_m45_s 0.288

# Include two routing tracks of snap allowance in the conservative reach.
# This bounds both the die-margin check and the maximum straight extension
# used by the SRAM gap stripes.
set ring_m45_span [expr {
    $ring_m45_o + 2.0 * $ring_m45_w + $ring_m45_s +
    2.0 * [pg_layer_pitch M5]
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
    if {$ring_m45_span > $margin} {
        error "M4/M5 core-ring reach $ring_m45_span exceeds $side die-to-core margin $margin"
    }
}

addRing \
    -nets {VSS VDD} \
    -type core_rings \
    -follow core \
    -layer {top M4 bottom M4 left M5 right M5} \
    -width $ring_m45_w \
    -spacing $ring_m45_s \
    -offset $ring_m45_o \
    -snap_wire_center_to_grid Grid

# Put each physical PG pin on a straight M5 side segment.  The previous
# lower-left corner rectangles ended before the snapped ring corner and left
# VSS disconnected (IMPVFC-96).
if {$PG_CREATE_CORE_RING_PINS} {
    pg_create_core_ring_side_pins \
        $core_llx $core_lly $core_urx $core_ury \
        $ring_m45_w $ring_m45_s $ring_m45_o
}

# ------------------------------------------------------------------------
# 2. REFERENCE-STYLE SRAM ISLAND POWER
# ------------------------------------------------------------------------

# Match the teacher's SRAM-island sequence: shared-cluster ring,
# blockPin-to-blockring sroute, M4/M5 gap stripes in SRAM channels, trim.
source ./tcl/sram_island_power.tcl

editTrim -nets {VDD VSS}

set pg_connectivity_report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt
set pg_drc_report ./verify_rpt/pg_drc_before_stdcell_place.rpt

verifyConnectivity \
    -type special \
    -net {VDD VSS} \
    -noUnroutedNet \
    -report $pg_connectivity_report

verify_drc \
    -report $pg_drc_report

pg_assert_clean_connectivity_report $pg_connectivity_report
pg_assert_clean_drc_report $pg_drc_report

saveDesign ./saved/axi_ram_powerplan.enc

puts "===================================================="
puts "HIERARCHICAL POWER PLAN COMPLETED"
puts " - SRAM island     : reference shared_cluster ring + M4/M5 stripes"
puts " - Core ring       : M4/M5, aligned with island left/bottom ring"
puts " - Core PG pins    : short M5 side taps on both VSS and VDD"
puts " - Upper M8/M9 mesh: deferred until after placement"
puts " - addStripe jog   : none"
puts " - SRAM blockPin  : nearest shared-cluster blockring"
puts " - corePin sroute : no jog/no layer change after placement"
puts " - PG connectivity : ./verify_rpt/pg_connectivity_before_stdcell_place.rpt"
puts " - PG DRC          : ./verify_rpt/pg_drc_before_stdcell_place.rpt"
puts "===================================================="
