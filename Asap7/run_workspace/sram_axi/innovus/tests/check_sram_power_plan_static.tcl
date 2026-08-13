#!/usr/bin/env tclsh

set script_dir [file dirname [file normalize [info script]]]
set innovus_dir [file dirname $script_dir]
set tcl_dir [file join $innovus_dir tcl]

proc fail {message} {
    puts stderr "FAIL: $message"
    exit 1
}

proc read_complete_file {path} {
    set fh [open $path r]
    set text [read $fh]
    close $fh

    if {![info complete $text]} {
        fail "[file tail $path] is not a complete Tcl script"
    }
    return $text
}

proc assert_contains {text pattern message} {
    if {![regexp $pattern $text]} {
        fail $message
    }
}

proc assert_not_contains {text pattern message} {
    if {[regexp $pattern $text]} {
        fail $message
    }
}

proc assert_close {actual expected message} {
    set eps 0.000001
    if {abs($actual - $expected) > $eps} {
        fail "$message: expected $expected, got $actual"
    }
}

proc dbGet {args} {
    if {[llength $args] == 3 &&
        [lindex $args 0] eq "-p2" &&
        [lindex $args 1] eq "top.insts.cell.name"} {
        set ptrs {}
        for {set i 0} {$i < 16} {incr i} {
            lappend ptrs "sram_ptr_$i"
        }
        return $ptrs
    }

    if {[llength $args] == 1 &&
        [regexp {^sram_ptr_([0-9]+)\.name$} [lindex $args 0] -> index]} {
        return [format {u_mem/G_SRAM_BANK[%d].u_sram} $index]
    }

    if {[llength $args] == 3 &&
        [lindex $args 0] eq "-p" &&
        [lindex $args 1] eq "top.nets.name"} {
        set net [lindex $args 2]
        if {$net eq "VDD" || $net eq "VSS"} {
            return "net_$net"
        }
        return ""
    }

    if {[llength $args] == 3 &&
        [lindex $args 0] eq "-p2" &&
        [regexp {^net_(VDD|VSS)\.sWires\.layer\.name$} [lindex $args 1] -> net] &&
        [regexp {^M[0-9]+$} [lindex $args 2]]} {
        set layer [lindex $args 2]
        if {$layer eq "M5"} {
            return [list "wire_${net}_${layer}_left" "wire_${net}_${layer}_right"]
        }
        return [list "wire_${net}_${layer}_0"]
    }

    if {[llength $args] == 1 &&
        [regexp {^wire_(VDD|VSS)_(M[0-9]+)_(0|left|right)\.box$} [lindex $args 0] -> net layer which]} {
        switch -- $layer {
            M4 { return {0.816 706.860 502.032 707.724} }
            M5 {
                if {$which eq "left"} {
                    return {0.816 1.548 1.752 707.628}
                }
                return {501.192 1.548 502.128 707.628}
            }
            M8 { return {0.816 0.876 502.032 1.740} }
            M9 { return {0.720 0.972 1.656 707.628} }
            default { return {} }
        }
    }

    if {[llength $args] == 1 && [lindex $args 0] eq "top.fPlan.box"} {
        return {0.0 0.0 1105.2 970.848}
    }

    fail "Unexpected dbGet call while simulating SRAM island PG: $args"
}

proc deselectAll {} {}
proc selectInst {name} {}
proc addRing {args} {
    global SRAM_RING_CAPTURE
    lappend SRAM_RING_CAPTURE $args
}
proc setSrouteMode {args} {}
proc sroute {args} {}
proc setAddStripeMode {args} {
    global SRAM_STRIPE_MODE_CAPTURE
    lappend SRAM_STRIPE_MODE_CAPTURE $args
}
proc editTrim {args} {}
proc clearDrc {} {}

proc pg_track_aligned_pair_offset {area_start area_stop layer width spacing} {
    return 0.096000
}

proc addStripe {args} {
    global SRAM_STRIPE_CAPTURE

    array set opts {}
    for {set i 0} {$i < [llength $args]} {incr i} {
        set option [lindex $args $i]
        if {![string match "-*" $option]} {
            continue
        }
        if {$i + 1 >= [llength $args]} {
            fail "Missing value for addStripe option $option"
        }
        incr i
        set opts($option) [lindex $args $i]
    }

    foreach option {-layer -direction -area} {
        if {![info exists opts($option)]} {
            fail "SRAM addStripe is missing $option"
        }
    }

    set create_pins ""
    if {[info exists opts(-create_pins)]} {
        set create_pins $opts(-create_pins)
    }

    lappend SRAM_STRIPE_CAPTURE \
        [list \
            $opts(-layer) $opts(-direction) $opts(-area) $create_pins \
            $opts(-width) $opts(-spacing)]
}

proc simulate_sram_island_power {script_path} {
    global SRAM_STRIPE_CAPTURE
    global SRAM_STRIPE_MODE_CAPTURE
    global SRAM_RING_CAPTURE
    global SRAM_MASTER SRAM_COUNT SRAM_ROWS SRAM_COLS
    global SRAM_X0 SRAM_Y0 SRAM_W SRAM_H
    global SRAM_MACRO_GAP_X SRAM_MACRO_GAP_Y
    global SRAM_ISLAND_LLX SRAM_ISLAND_LLY SRAM_ISLAND_URX SRAM_ISLAND_URY
    global SRAM_ISLAND_CUT_LLX SRAM_ISLAND_CUT_LLY
    global SRAM_ISLAND_CUT_URX SRAM_ISLAND_CUT_URY
    global ASAP7_ROW_HEIGHT
    global core_llx core_lly
    global power_die_llx power_die_lly
    global ring_m89_w ring_m89_s ring_m89_inner_o ring_m89_outer_o ring_m89_span
    global stripe_m45_w stripe_m45_s

    set SRAM_STRIPE_CAPTURE {}
    set SRAM_STRIPE_MODE_CAPTURE {}
    set SRAM_RING_CAPTURE {}

    set SRAM_MASTER srambank_256x4x32_6t122
    set SRAM_COUNT 16
    set SRAM_ROWS 4
    set SRAM_COLS 4
    set SRAM_X0 2.16
    set SRAM_Y0 2.16
    set SRAM_W 121.392
    set SRAM_H 172.8
    set SRAM_MACRO_GAP_X 4.32
    set SRAM_MACRO_GAP_Y 4.32
    set SRAM_ISLAND_LLX 2.16
    set SRAM_ISLAND_LLY 2.16
    set SRAM_ISLAND_URX 500.688
    set SRAM_ISLAND_URY 706.32
    set SRAM_ISLAND_CUT_LLX 2.16
    set SRAM_ISLAND_CUT_LLY 2.16
    set SRAM_ISLAND_CUT_URX 502.848
    set SRAM_ISLAND_CUT_URY 708.48
    set ASAP7_ROW_HEIGHT 1.080
    set core_llx 2.16
    set core_lly 2.16
    set power_die_llx 0.0
    set power_die_lly 0.0
    set ring_m89_w 0.480
    set ring_m89_s 0.480
    set ring_m89_inner_o 0.192
    set ring_m89_outer_o 1.152
    set ring_m89_span 1.632
    set stripe_m45_w 0.096
    set stripe_m45_s 0.288

    if {[info exists ::env(TEMP)]} {
        set sram_edge_report [file join \
            $::env(TEMP) sram_island_pg_edges_static.rpt]
    } else {
        set sram_edge_report sram_island_pg_edges_static.rpt
    }
    file delete -force $sram_edge_report

    if {[catch {source $script_path} message]} {
        fail "Simulated SRAM island PG failed: $message"
    }
    file delete -force $sram_edge_report

    return $SRAM_STRIPE_CAPTURE
}

proc warn_if_dirty_report {path} {
    if {![file exists $path]} {
        return
    }

    set fh [open $path r]
    set text [read $fh]
    close $fh

    if {[regexp {Total Violations[[:space:]]*:[[:space:]]*([1-9][0-9]*)} $text -> count]} {
        puts stderr "WARN: [file tail $path] is from an older dirty run ($count DRC violations); rerun Innovus after script changes"
    }
    if {[regexp -nocase {special routes with opens|dangling[[:space:]]+Wire|shorted} $text]} {
        puts stderr "WARN: [file tail $path] is from an older dirty run; rerun Innovus after script changes"
    }
}

set power_plan [file join $tcl_dir power_plan.tcl]
set power_children {
    sram_island_power.tcl
    core_lower_pg_nojog.tcl
    core_pg_outside_island.tcl
    global_upper_pg_to_ring.tcl
}

set power_text [read_complete_file $power_plan]
set all_power_text $power_text
array set child_text {}
foreach child $power_children {
    set path [file join $tcl_dir $child]
    set child_text($child) [read_complete_file $path]
    append all_power_text "\n" $child_text($child)
}

set pnr_text [read_complete_file [file join $tcl_dir innovus_pnr.tcl]]
set innovus_text [read_complete_file [file join $tcl_dir innovus.tcl]]
set flow_checks_text [read_complete_file [file join $tcl_dir flow_checks.tcl]]
set route_guard_path [file join $tcl_dir sram_route_guard.tcl]
if {![file exists $route_guard_path]} {
    fail "Missing sram_route_guard.tcl; SRAM macro bodies must be reserved before placement/CTS"
}
set route_guard_text [read_complete_file $route_guard_path]

assert_not_contains \
    $route_guard_text \
    {createRouteBlk[[:space:]]+\\} \
    "sram_route_guard.tcl must not create hard routing blockages over ASAP7 SRAM pin-access layers"
assert_contains \
    $route_guard_text \
    {setRouteMode[[:space:]]+\\[[:space:]]+-earlyGlobalReverseDirection[[:space:]]+\$sram_egr_reverse_regions} \
    "SRAM route guard must use the documented setRouteMode -earlyGlobalReverseDirection option for early global route/CTS estimation"
assert_contains \
    $route_guard_text \
    {set[[:space:]]+SRAM_ROUTE_GUARD_EGR_LAYER[[:space:]]+M5} \
    "The SRAM early-global reverse-direction reservation must target the teacher-style M5 routing layer"
assert_not_contains \
    $route_guard_text \
    {deleteRouteBlk} \
    "sram_route_guard.tcl must not manage route blockage objects in the clean flow"

foreach obsolete_child {
    sram_gap_stripes.tcl
    sram_macro_power.tcl
    stitch_island_to_core.tcl
} {
    if {[file exists [file join $tcl_dir $obsolete_child]]} {
        fail "Obsolete SRAM PG helper must be removed: $obsolete_child"
    }
    if {[string first "source ./tcl/$obsolete_child" $power_text] >= 0} {
        fail "power_plan.tcl must not source removed helper $obsolete_child"
    }
}

if {[string first {source ./tcl/core_pg_outside_island.tcl} $power_text] >= 0} {
    fail "The power/pins checkpoint must not add the post-placement M6/M7 mesh"
}

assert_contains \
    $power_text \
    {source[[:space:]]+\./tcl/sram_island_power\.tcl} \
    "power_plan.tcl must source the SRAM collector PG script"
foreach marker {
    {POWER PLAN SCRIPT ENTRY:}
    {POWER PLAN CORE RINGS CHECKED}
    {POWER PLAN SOURCE SRAM ISLAND:}
    {POWER PLAN SRAM ISLAND RETURNED}
} {
    assert_contains \
        $power_text \
        $marker \
        "power_plan.tcl must print marker '$marker' for log/source correlation"
}
if {[string first {source ./tcl/global_upper_pg_to_ring.tcl} $power_text] >= 0} {
    fail "The power/pins checkpoint must not add the post-placement M8/M9 mesh"
}

foreach proc_name {
    pg_layer_pitch
    pg_layer_offset
    pg_layer_boundary_guard
    pg_assert_box_clear_of_sram_cut
    pg_snap_value_to_layer_track
    pg_positive_mod
    pg_track_aligned_pair_offset
    pg_track_aligned_global_offset
    pg_create_core_ring_side_pins
    pg_delete_core_pg_pins
    pg_assert_complete_core_rings
    pg_assert_clean_connectivity_report
    pg_assert_clean_drc_report
} {
    if {[string first "proc $proc_name" $power_text] < 0} {
        fail "power_plan.tcl must define $proc_name"
    }
}

assert_contains \
    $power_text \
    {array[[:space:]]+set[[:space:]]+PG_TRACK_PITCH} \
    "power_plan.tcl must declare ASAP7 PG track pitch data"
assert_contains \
    $power_text \
    {array[[:space:]]+set[[:space:]]+PG_TRACK_OFFSET} \
    "power_plan.tcl must declare ASAP7 PG track offset data"
assert_contains \
    $power_text \
    {set[[:space:]]+PG_BOUNDARY_EPS[[:space:]]+0\.192} \
    "power_plan.tcl must define a small boundary inset for area-constrained PG stripes"

foreach margin_var {die_core_margin_left die_core_margin_bottom die_core_margin_right die_core_margin_top} {
    if {[string first "set $margin_var" $power_text] < 0} {
        fail "power_plan.tcl must check $margin_var before adding the M8/M9 ring"
    }
}

set ring_snap_count [regexp -all -- {-snap_wire_center_to_grid[[:space:]]+Grid} $all_power_text]
if {$ring_snap_count < 2} {
    fail "Both one-net M8/M9 core rings must snap wire centers to the routing grid"
}

set global_ring_count [regexp -all {addRing[[:space:]]+\\} $power_text]
if {$global_ring_count != 2} {
    fail "power_plan.tcl must create exactly two deterministic one-net M8/M9 core rings"
}
foreach net {VDD VSS} {
    set one_net_pattern [format {-nets[[:space:]]+\{%s\}} $net]
    assert_contains \
        $power_text \
        $one_net_pattern \
        "The global M8/M9 ring must include an independent $net ring"
}
if {[regexp -- {addRing[[:space:]]+\\[[:space:]]+-nets[[:space:]]+\{(?:VDD[[:space:]]+VSS|VSS[[:space:]]+VDD)\}} $power_text]} {
    fail "Do not rely on one two-net addRing call at the 2.16 um die/core margin"
}

assert_contains \
    $power_text \
    {pg_assert_complete_core_rings[[:space:]]+\\} \
    "The flow must verify all four M8/M9 sides for both VDD and VSS after addRing"
set complete_ring_check_index [string first "pg_assert_complete_core_rings \\" $power_text]
set island_source_index [string first {source ./tcl/sram_island_power.tcl} $power_text]
if {$complete_ring_check_index < 0 ||
    $island_source_index < 0 ||
    $complete_ring_check_index >= $island_source_index} {
    fail "The complete-ring assertion must run before SRAM collectors are created"
}

assert_contains \
    $power_text \
    {foreach[[:space:]]+net[[:space:]]+\{VDD[[:space:]]+VSS\}} \
    "Core PG pin creation must cover both VDD and VSS"
assert_contains \
    $power_text \
    {deletePGPin[[:space:]]+-net[[:space:]]+\$net} \
    "Core PG pin creation must delete old VDD/VSS PG pin shapes before recreating them"

assert_contains \
    $power_text \
    {set[[:space:]]+PG_CREATE_CORE_RING_PINS[[:space:]]+1} \
    "Core ring PG pin shapes must be enabled so both VDD and VSS physical PG pins are visible at the power/pins checkpoint"
assert_contains \
    $power_text \
    {if[[:space:]]+\{\$PG_CREATE_CORE_RING_PINS\}} \
    "Manual core ring PG pin creation must be explicitly gated"
assert_contains \
    $power_text \
    {sWires\.layer\.name[[:space:]]+M9} \
    "Core PG pin creation must query the actual snapped M9 ring wires"
assert_contains \
    $power_text \
    {dbGet[[:space:]]+\$wire_ptr\.box} \
    "Core PG pin geometry must come from the actual M9 special-wire bbox"
if {[string first {pg_core_ring_lane_rect} $power_text] >= 0} {
    fail "Core PG pin creation must not predict the snapped ring lane from nominal offset geometry"
}
assert_contains \
    $power_text \
    {pg_delete_core_pg_pins} \
    "power_plan.tcl must delete stale VDD/VSS PG pin shapes before recreating the ring"

if {[regexp {foreach[[:space:]]+side[[:space:]]+\{bottom[[:space:]]+top[[:space:]]+left[[:space:]]+right\}} $power_text]} {
    fail "Core PG pins must not be full-side duplicate ring shapes; create small side taps only"
}

if {[regexp -- {createPGPin[[:space:]]+VDD|createPGPin[[:space:]]+VSS} $power_text]} {
    fail "Core PG pins must not be hard-coded as one lower-left VDD/VSS shape"
}

assert_contains \
    $power_text \
    {-layer[[:space:]]+\{top[[:space:]]+M8[[:space:]]+bottom[[:space:]]+M8[[:space:]]+left[[:space:]]+M9[[:space:]]+right[[:space:]]+M9\}} \
    "The only checkpoint core ring must use ASAP7 M8 horizontal and M9 vertical layers"
if {[regexp -- {-type[[:space:]]+core_rings[^\n]+-layer[[:space:]]+\{top[[:space:]]+M4} $power_text]} {
    fail "The floorplan power/pins checkpoint must not create a second M4/M5 core ring"
}
assert_contains \
    $power_text \
    {set[[:space:]]+ring_m89_w[[:space:]]+0\.480} \
    "The long M8/M9 core ring must use the scaled ASAP7 120 nm minimum width"
assert_contains \
    $power_text \
    {set[[:space:]]+ring_m89_s[[:space:]]+0\.480} \
    "The M8/M9 core ring must keep conservative pair spacing"
assert_contains \
    $power_text \
    {set[[:space:]]+ring_m89_inner_o[[:space:]]+0\.192} \
    "The inner M8/M9 core ring must leave deterministic grid-snap room"
assert_contains \
    $power_text \
    {set[[:space:]]+ring_m89_outer_o[[:space:]]+\[expr} \
    "The outer M8/M9 ring offset must be derived from inner offset, width, and spacing"
assert_contains \
    $power_text \
    {set[[:space:]]+stripe_m45_w[[:space:]]+0\.096} \
    "SRAM M4/M5 collectors must use a legal ASAP7 WIDTHTABLE width"
assert_contains \
    $power_text \
    {-net[[:space:]]+\{VDD[[:space:]]+VSS\}} \
    "PG verification must be restricted to VDD/VSS so pre-pin-assignment signal IOs do not create IMPVFC-97 warnings"

if {[regexp -- {-snap_wire_center_to_grid[[:space:]]+grid} $all_power_text]} {
    fail "Use Innovus documented Grid spelling for snap_wire_center_to_grid"
}

set addstripe_count [regexp -all {addStripe[[:space:]]+\\} $all_power_text]
set snap_override_count [regexp -all -- {-allow_snapping_override_custom_spacing[[:space:]]+1} $all_power_text]
if {$snap_override_count < $addstripe_count} {
    fail "Every addStripe in the SRAM power plan must allow snapping to override custom spacing"
}

assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {pg_track_aligned_global_offset} \
    "core_lower_pg_nojog.tcl must derive repeated-mesh offsets from the ASAP7 routing track grid"
assert_not_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {info[[:space:]]+exists[[:space:]]+LOGIC_RIGHT_FULL_BOX} \
    "core_lower_pg_nojog.tcl must always rebuild guarded logic boxes instead of reusing stale session variables"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {foreach[[:space:]]+required_var[[:space:]]+\{} \
    "core_lower_pg_nojog.tcl must validate geometry variables before rebuilding lower PG boxes"
foreach lower_pg_var {stripe_m5_offset stripe_m5_w stripe_m5_s stripe_m45_pitch} {
    set lower_pg_pattern [format \
        {if[[:space:]]+\{!\[info[[:space:]]+exists[[:space:]]+%s\]\}} \
        $lower_pg_var]
    assert_contains \
        $child_text(core_lower_pg_nojog.tcl) \
        $lower_pg_pattern \
        "core_lower_pg_nojog.tcl must default/check $lower_pg_var before using it"
}
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {-stacked_via_top_layer[[:space:]]+M5} \
    "post-placement lower taps must stop at M5 before the M6/M7 core mesh"
if {[regexp -- {-stacked_via_bottom_layer[[:space:]]+M1[[:space:]]+\\[[:space:]]+-stacked_via_top_layer[[:space:]]+M8} \
        $child_text(core_lower_pg_nojog.tcl)]} {
    fail "core_lower_pg_nojog.tcl must not use a direct M1-to-M8 stack because it can generate off-grid M7 intermediate metal"
}
assert_contains \
    $child_text(core_pg_outside_island.tcl) \
    {-stacked_via_bottom_layer[[:space:]]+M5} \
    "outside-island M6 mesh must connect down to the M5 standard-cell taps"
assert_contains \
    $child_text(core_pg_outside_island.tcl) \
    {-stacked_via_top_layer[[:space:]]+M7} \
    "outside-island M6 mesh must connect up to the M7 mesh"
assert_contains \
    $child_text(global_upper_pg_to_ring.tcl) \
    {-stacked_via_bottom_layer[[:space:]]+M7} \
    "upper M8 mesh must connect down to the M7 core mesh"
assert_contains \
    $child_text(global_upper_pg_to_ring.tcl) \
    {-stacked_via_top_layer[[:space:]]+M8} \
    "M8 stripe pass must stop at M8; M8-to-M9 vias are created by the M9 stripe pass"
foreach {script_name guard_name} {
    core_pg_outside_island.tcl core_m6_sram_guard
    core_pg_outside_island.tcl core_m7_sram_guard
    global_upper_pg_to_ring.tcl upper_m8_sram_guard
    global_upper_pg_to_ring.tcl upper_m9_sram_guard
} {
    assert_contains \
        $child_text($script_name) \
        [format {set[[:space:]]+%s[[:space:]]+\[pg_layer_boundary_guard} $guard_name] \
        "$script_name must derive $guard_name from stripe width and track pitch"
}
foreach script_name {core_pg_outside_island.tcl global_upper_pg_to_ring.tcl} {
    assert_contains \
        $child_text($script_name) \
        {pg_assert_box_clear_of_sram_cut} \
        "$script_name must assert guarded PG boxes before addStripe"
}
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {LOGIC_RIGHT_EDGE_TAP_BOX} \
    "core_lower_pg_nojog.tcl must create an explicit first M5 tap beside the SRAM island right edge"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {set[[:space:]]+stdcell_pg_area_lly[[:space:]]+\[expr} \
    "core_lower_pg_nojog.tcl must explicitly expand lower PG boxes for ASAP7 M1 pin overhang"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {core_lly[[:space:]]+-[[:space:]]+\$STDCELL_PG_AREA_OVERHANG} \
    "core_lower_pg_nojog.tcl must cover bottom-row VDD/VSS pins that protrude below the placement row bbox"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {set[[:space:]]+lower_m5_sram_guard[[:space:]]+\[pg_layer_boundary_guard[[:space:]]+M5[[:space:]]+\$stripe_m5_w\]} \
    "core_lower_pg_nojog.tcl must compute an M5 SRAM boundary guard from the actual stripe width and routing pitch"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {set[[:space:]]+LOGIC_RIGHT_EDGE_TAP_BOX[[:space:]]+\[list[[:space:]]+\\[[:space:]]+\$logic_right_guard_llx[[:space:]]+\$stdcell_pg_area_lly} \
    "core_lower_pg_nojog.tcl must rebuild lower PG boxes from guarded std-cell PG rail coverage, not the raw SRAM cut boundary"
if {[regexp {set[[:space:]]+LOGIC_RIGHT_EDGE_TAP_BOX[[:space:]]+\[list[[:space:]]+\\[[:space:]]+\$SRAM_ISLAND_CUT_URX[[:space:]]+\$lower_pg_die_lly} \
        $child_text(core_lower_pg_nojog.tcl)]} {
    fail "core_lower_pg_nojog.tcl must not use die-bottom/die-top for standard-cell corePin areas"
}
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {foreach[[:space:]]+area[[:space:]]+\[list[[:space:]]+\$LOGIC_RIGHT_EDGE_TAP_BOX[[:space:]]+\$LOGIC_RIGHT_FULL_BOX[[:space:]]+\$LOGIC_TOP_LEFT_BOX\]} \
    "the edge M5 tap must be generated before the repeated right/top M5 tap mesh"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {if[[:space:]]+\{\$area[[:space:]]+eq[[:space:]]+\$LOGIC_RIGHT_EDGE_TAP_BOX\}} \
    "the SRAM-adjacent M5 tap must use one fixed pair instead of the global repeated phase"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {set[[:space:]]+area_nets[[:space:]]+\{VSS[[:space:]]+VDD\}} \
    "the SRAM-adjacent M5 tap must put VDD on the second lane to overlap the bottom-row VDD pins reported near x=505..508"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {-number_of_sets[[:space:]]+\$area_sets} \
    "the SRAM-adjacent M5 tap must be constrained to exactly one VDD/VSS pair"

assert_contains \
    $power_text \
    {pg_assert_clean_connectivity_report[[:space:]]+\$pg_connectivity_report} \
    "power_plan.tcl must stop before saveDesign when PG connectivity is dirty"
assert_contains \
    $power_text \
    {unconnected[[:space:]]+terminal|Terminal\(s\)[[:space:]]+are[[:space:]]+not[[:space:]]+connected|IMPVFC-96} \
    "PG connectivity guard must reject unconnected VDD/VSS terminals, not only special-route opens"
assert_contains \
    $power_text \
    {pg_assert_clean_drc_report[[:space:]]+\$pg_drc_report} \
    "power_plan.tcl must stop before saveDesign when PG DRC is dirty"
assert_contains \
    $power_text \
    {verify_drc[[:space:]]+\\[[:space:]]+-check_only[[:space:]]+special[[:space:]]+\\[[:space:]]+-layer_range[[:space:]]+\{M4[[:space:]]+M9\}} \
    "The PG-stage DRC checkpoint must isolate actionable M4-M9 special-route PG DRC from generated SRAM M3 abstract-pin WIDTHTABLE markers"
assert_contains \
    $power_text \
    {file[[:space:]]+delete[[:space:]]+-force[[:space:]]+\$stale_pg_report} \
    "power_plan.tcl must delete stale PG reports before constructing a new power plan"
set stale_report_delete_index [string first {file delete -force $stale_pg_report} $power_text]
set first_global_ring_index [string first "\naddRing \\" $power_text]
if {$stale_report_delete_index < 0 ||
    $first_global_ring_index < 0 ||
    $stale_report_delete_index >= $first_global_ring_index} {
    fail "Stale PG reports must be deleted before the first global addRing command"
}
assert_contains \
    $power_text \
    {PG[[:space:]]+DRC[[:space:]]+is[[:space:]]+not[[:space:]]+clean:[[:space:]]+\$report_path[[:space:]]+has[[:space:]]+\$pg_drc_count[[:space:]]+special-route[[:space:]]+violations} \
    "PG DRC guard must stop on any nonzero actionable M4-M9 special-route DRC before placement/route"
assert_contains \
    $power_text \
    {treated[[:space:]]+as[[:space:]]+hard-macro[[:space:]]+abstract/library[[:space:]]+markers} \
    "PG DRC guard must not fail solely on generated SRAM hard-macro Pin-of-Cell markers"
assert_contains \
    $power_text \
    {editTrim[[:space:]]+-nets[[:space:]]+\{VDD[[:space:]]+VSS\}} \
    "power_plan.tcl must trim dangling VDD/VSS wires before final PG verification"

assert_contains \
    $child_text(sram_island_power.tcl) \
    {-viaConnectToShape[[:space:]]+stripe} \
    "SRAM blockPin sroute must target the internal M4/M5 collectors"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-blockPinRouteWithPinWidth[[:space:]]+false} \
    "SRAM blockPin sroute must not inherit the too-narrow generated ASAP7 SRAM M3 PG pin width"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-blockPinLayerRange[[:space:]]+\{M3[[:space:]]+M3\}} \
    "SRAM blockPin sroute must avoid generated SRAM M4 rail ports that create top-level PG DRC markers"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-blockPinWidthRange[[:space:]]+\{0\.0[[:space:]]+0\.150\}} \
    "SRAM blockPin sroute must prefer narrow M3 access pins instead of wide internal LEF shapes"
assert_not_contains \
    $all_power_text \
    {-blockPinRouteWithPinWidth[[:space:]]+true} \
    "No active SRAM power script may force block-pin routes to the generated SRAM LEF pin width"

assert_contains \
    $child_text(sram_island_power.tcl) \
    {set[[:space:]]+sram_edge_report[[:space:]]+\./reports/sram_island_pg_edges\.rpt} \
    "SRAM island power must write a small region report for GUI/debug correlation"
foreach edge_name {local_left local_top local_right} {
    assert_contains \
        $child_text(sram_island_power.tcl) \
        $edge_name \
        "SRAM island edge report must cover $edge_name"
}
assert_contains \
    $child_text(sram_island_power.tcl) \
    {proc[[:space:]]+sram_add_local_pg_pair} \
    "SRAM island power must keep repeated addStripe calls in one small helper"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {puts[[:space:]]+\$edge_fh[[:space:]]+"type[[:space:]]+name[[:space:]]+layer[[:space:]]+direction[[:space:]]+area"} \
    "SRAM island power must write a simple local PG region report after editTrim"

if {[regexp -- {-allowJogging|-allowLayerChange} $child_text(sram_island_power.tcl)]} {
    fail "SRAM blockPin sroute must not pass explicit allowJogging/allowLayerChange switches"
}

set sram_island_code_only ""
foreach line [split $child_text(sram_island_power.tcl) "\n"] {
    if {![regexp {^[[:space:]]*#} $line]} {
        append sram_island_code_only $line "\n"
    }
}

if {[regexp {addRing[[:space:]]+\\} $sram_island_code_only]} {
    fail "SRAM island must build an open top/right local ring instead of a closed shared-cluster addRing"
}
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-break_at[[:space:]]+none} \
    "SRAM collectors must cross the open local-ring edges without jogging"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-extend_to_closest_target[[:space:]]+area_boundary} \
    "SRAM collectors must cross the existing M8/M9 ring and extend to the explicit area boundary"
if {[regexp -- {-extend_to_first_ring|-max_extension_distance} $child_text(sram_island_power.tcl)]} {
    fail "SRAM collectors must not stop before crossing the reused M8/M9 ring"
}
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-stacked_via_bottom_layer[[:space:]]+M4} \
    "SRAM gap-stripe vias must start on M4"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-stacked_via_top_layer[[:space:]]+M5} \
    "Horizontal M4 collectors must be allowed to connect to the M5 island transition spine"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-stacked_via_top_layer[[:space:]]+M8} \
    "Vertical M5 collectors must be allowed to connect to the M8 bottom ring"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {local_left} \
    "SRAM island power must add a narrow M5 transition spine at the reused left global-ring edge"
if {[string first "-extend_to design_boundary" $sram_island_code_only] >= 0} {
    fail "Area-constrained SRAM island stripes must not also use -extend_to design_boundary; Innovus IMPPP-330 rejects that combination"
}
assert_contains \
    $child_text(sram_island_power.tcl) \
    {for[[:space:]]+\{set[[:space:]]+r[[:space:]]+0\}[[:space:]]+\{\$r[[:space:]]+<[[:space:]]+\[expr[[:space:]]+\{\$SRAM_ROWS[[:space:]]+-[[:space:]]+1\}\]\}} \
    "SRAM island power must place explicit horizontal M4 pairs in every SRAM row gap"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {for[[:space:]]+\{set[[:space:]]+c[[:space:]]+0\}[[:space:]]+\{\$c[[:space:]]+<[[:space:]]+\[expr[[:space:]]+\{\$SRAM_COLS[[:space:]]+-[[:space:]]+1\}\]\}} \
    "SRAM island power must place explicit vertical M5 pairs in every SRAM column gap"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {SRAM_MACRO_GAP_Y} \
    "SRAM island horizontal PG must be derived from the actual SRAM macro row gaps"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {SRAM_MACRO_GAP_X} \
    "SRAM island vertical PG must be derived from the actual SRAM macro column gaps"

set global_upper_code_only ""
foreach line [split $child_text(global_upper_pg_to_ring.tcl) "\n"] {
    if {![regexp {^[[:space:]]*#} $line]} {
        append global_upper_code_only $line "\n"
    }
}

if {[string first "-extend_to design_boundary" $global_upper_code_only] >= 0} {
    fail "M8/M9 outside-island stripes must use explicit -area boxes instead of -extend_to design_boundary"
}
assert_contains \
    $child_text(global_upper_pg_to_ring.tcl) \
    {set[[:space:]]+upper_die_llx[[:space:]]+\[expr[[:space:]]+\{\$die_llx[[:space:]]+\+[[:space:]]+\$PG_BOUNDARY_EPS\}\]} \
    "M8/M9 outside-island stripe boxes must be inset from the die boundary to avoid IMPPP-358"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {set[[:space:]]+sram_pg_left[[:space:]]+\[expr[[:space:]]+\{\$power_die_llx[[:space:]]+\+[[:space:]]+\$PG_BOUNDARY_EPS\}\]} \
    "SRAM island stripe boxes must be inset from die-left while still crossing the reused M9 ring"
set global_upper_stripes [regexp -all {addStripe[[:space:]]+\\} $global_upper_code_only]
set global_upper_no_pin_stripes [regexp -all -- {-create_pins[[:space:]]+0} $global_upper_code_only]
if {$global_upper_stripes == 0 || $global_upper_no_pin_stripes < $global_upper_stripes} {
    fail "Every M8/M9 outside-island addStripe must use -create_pins 0; top-level PG pins are created explicitly from the core ring"
}

set simulated_sram_stripes \
    [simulate_sram_island_power [file join $tcl_dir sram_island_power.tcl]]
if {[llength $simulated_sram_stripes] != 9} {
    fail "SRAM island power must generate top/right local-ring pairs, one left M5 transition spine, plus 3 M4 row-gap and 3 M5 column-gap pairs"
}

set horizontal_pair_count 0
set vertical_pair_count 0
set top_local_ring_found 0
set left_transition_found 0
set right_local_ring_found 0
foreach stripe $simulated_sram_stripes {
    lassign $stripe layer direction area create_pins width spacing
    if {$create_pins ne "0"} {
        fail "SRAM island addStripe must use -create_pins 0 so local gap stripes do not become boundary IO pins"
    }
    assert_close $width 0.096 "SRAM collector must use a legal M4/M5 WIDTHTABLE width"
    assert_close $spacing 0.288 "SRAM collector pair spacing"

    if {[llength $area] != 4} {
        fail "SRAM island addStripe area must be a four-coordinate box"
    }
    lassign $area llx lly urx ury

    if {$llx < 0.0 || $lly < 0.0 || $urx >= 1105.2 || $ury >= 970.848} {
        fail "SRAM island gap stripe area is outside the die: $area"
    }

    switch -- $direction {
        horizontal {
            incr horizontal_pair_count
            if {$layer ne "M4"} {
                fail "Horizontal SRAM island stripes must be on M4, got $layer"
            }
            assert_close $llx 0.192 "M4 SRAM row-gap stripe must cross the reused left M9 core ring without touching die boundary"
            assert_close $urx 502.848 "M4 SRAM row-gap stripe must stop at the SRAM island cut boundary"
            if {abs($lly - 706.320) < 0.000001 &&
                abs($ury - 708.480) < 0.000001} {
                set top_local_ring_found 1
            }
        }
        vertical {
            incr vertical_pair_count
            if {$layer ne "M5"} {
                fail "Vertical SRAM island stripes must be on M5, got $layer"
            }
            assert_close $lly 0.192 "M5 SRAM column-gap stripe must cross the reused bottom M8 core ring without touching die boundary"
            assert_close $ury 708.48 "M5 SRAM column-gap stripe must stop at the SRAM island cut boundary"
            if {abs($llx - 0.192) < 0.000001 &&
                abs($urx - 2.160) < 0.000001} {
                set left_transition_found 1
            }
            if {abs($llx - 500.688) < 0.000001 &&
                abs($urx - 502.848) < 0.000001} {
                set right_local_ring_found 1
            }
        }
        default {
            fail "Unexpected SRAM island stripe direction: $direction"
        }
    }
}

if {$horizontal_pair_count != 4 || $vertical_pair_count != 5} {
    fail "Open SRAM ring topology requires four M4 pairs and five M5 pairs"
}
if {!$top_local_ring_found || !$right_local_ring_found || !$left_transition_found} {
    fail "SRAM island must have top/right local collectors plus a left transition spine to keep M4 rows electrically tied to the reused global ring"
}

if {[llength $SRAM_RING_CAPTURE] != 0} {
    fail "SRAM island must not create a closed ring that duplicates the reused left/bottom global-ring edges"
}

if {[llength $SRAM_STRIPE_MODE_CAPTURE] != 3} {
    fail "SRAM island power must configure left-transition, horizontal, and right/column collector modes"
}
set mode_index 0
foreach mode $SRAM_STRIPE_MODE_CAPTURE {
    if {[lsearch -exact $mode -allow_jog] < 0 ||
        [lindex $mode [expr {[lsearch -exact $mode -allow_jog] + 1}]] ne "none"} {
        fail "Every SRAM stripe mode must explicitly disable jogging"
    }
    if {[lsearch -exact $mode -extend_to_closest_target] < 0 ||
        [lindex $mode [expr {[lsearch -exact $mode -extend_to_closest_target] + 1}]] ne "area_boundary"} {
        fail "Every SRAM stripe mode must extend to its explicit area boundary"
    }
    if {$mode_index == 1} {
        set expected_stack {-stacked_via_bottom_layer M4 -stacked_via_top_layer M5}
    } else {
        set expected_stack {-stacked_via_bottom_layer M4 -stacked_via_top_layer M8}
    }
    foreach {option expected} $expected_stack {
        set option_index [lsearch -exact $mode $option]
        if {$option_index < 0 || [lindex $mode [expr {$option_index + 1}]] ne $expected} {
            fail "Every SRAM stripe mode must set $option to $expected"
        }
    }
    incr mode_index
}

assert_contains \
    $pnr_text \
    {set[[:space:]]+orientation[[:space:]]+\[lindex[[:space:]]+\[dbGet[[:space:]]+\$ptr\.orient\][[:space:]]+0\]} \
    "innovus_pnr.tcl must normalize dbGet orientation before comparing it"
assert_contains \
    $pnr_text \
    {set[[:space:]]+status[[:space:]]+\[lindex[[:space:]]+\[dbGet[[:space:]]+\$ptr\.pStatus\][[:space:]]+0\]} \
    "innovus_pnr.tcl must normalize dbGet placement status before comparing it"
foreach flow_pair [list \
    [list innovus_pnr.tcl $pnr_text] \
    [list innovus.tcl $innovus_text] \
] {
    lassign $flow_pair flow_name flow_text
    assert_contains \
        $flow_text \
        {catch[[:space:]]+\{source[[:space:]]+\./tcl/power_plan\.tcl\}} \
        "$flow_name must stop before pin assignment when power_plan.tcl reports dirty PG"
    assert_contains \
        $flow_text \
        {POWER PLAN ENTRY:} \
        "$flow_name must print a power-plan entry marker before sourcing power_plan.tcl"
    assert_contains \
        $flow_text \
        {POWER PLAN EXIT:} \
        "$flow_name must print a power-plan exit marker after power_plan.tcl returns cleanly"
    assert_contains \
        $flow_text \
        {set[[:space:]]+sram_edge_report[[:space:]]+\./reports/sram_island_pg_edges\.rpt} \
        "$flow_name must track the SRAM island edge report generated by sram_island_power.tcl"
    assert_contains \
        $flow_text \
        {file[[:space:]]+delete[[:space:]]+-force[[:space:]]+\$sram_edge_report} \
        "$flow_name must delete the old SRAM island edge report before entering power_plan.tcl"
    assert_contains \
        $flow_text \
        {POWER PLAN DIRECT SRAM ISLAND SOURCE:} \
        "$flow_name must log a direct SRAM island fallback when power_plan.tcl did not create the island PG"
    assert_contains \
        $flow_text \
        {source[[:space:]]+\./tcl/sram_island_power\.tcl} \
        "$flow_name must directly source sram_island_power.tcl before pin assignment if the edge report is missing"
    assert_contains \
        $flow_text \
        {source[[:space:]]+\./tcl/global_upper_pg_to_ring\.tcl} \
        "$flow_name must build the post-placement M8/M9 upper PG mesh before lower M1/M5 taps"
    assert_contains \
        $flow_text \
        {connect_core_pg_pins_nojog[[:space:]]+\./verify_rpt/pg_connectivity_after_trim\.rpt} \
        "$flow_name must reconnect/verify VDD/VSS PG after post-placement mesh construction"
    assert_contains \
        $flow_text \
        {verify_pg_special_drc_or_stop[[:space:]]+\./verify_rpt/pg_drc_after_trim\.rpt[[:space:]]+\{M4[[:space:]]+M9\}} \
        "$flow_name must run a post-placement M4-M9 special-route PG DRC guard before saving axi_ram_placed.enc"
    assert_contains \
        $flow_text \
        {catch[[:space:]]+\{[[:space:]]+connect_core_pg_pins_nojog[[:space:]]+\./verify_rpt/pg_connectivity_after_trim\.rpt} \
        "$flow_name must catch the post-placement PG reconnect guard"
    assert_contains \
        $flow_text \
        {return[[:space:]]+-code[[:space:]]+error[[:space:]]+\$post_place_pg_error} \
        "$flow_name must hard-stop on dirty post-placement PG instead of saving axi_ram_placed.enc"
    assert_contains \
        $flow_text \
        {catch[[:space:]]+\{[[:space:]]+verify_pg_special_drc_or_stop[[:space:]]+\./verify_rpt/pg_drc_after_trim\.rpt[[:space:]]+\{M4[[:space:]]+M9\}} \
        "$flow_name must catch dirty post-placement PG special-route DRC"
    assert_contains \
        $flow_text \
        {return[[:space:]]+-code[[:space:]]+error[[:space:]]+\$post_place_pg_drc_error} \
        "$flow_name must hard-stop on dirty post-placement PG DRC instead of saving axi_ram_placed.enc"
    assert_contains \
        $flow_text \
        {source[[:space:]]+\./tcl/sram_route_guard\.tcl} \
        "$flow_name must source sram_route_guard.tcl before standard-cell placement"
    assert_contains \
        $flow_text \
        {set_interactive_constraint_modes[[:space:]]+\$active_constraint_modes} \
        "$flow_name must enable active interactive constraint modes before set_propagated_clock"
    assert_contains \
        $flow_text \
        {set_propagated_clock[[:space:]]+\[all_clocks\]} \
        "$flow_name must explicitly set clocks propagated only after CTS"
    assert_contains \
        $flow_text \
        {set_interactive_constraint_modes[[:space:]]+\{\}} \
        "$flow_name must clear interactive constraint modes after propagated-clock setup"
    assert_contains \
        $flow_text \
        {catch[[:space:]]+\{apply_post_cts_propagated_clocks\}} \
        "$flow_name must catch post-CTS propagated-clock setup failures"
    assert_contains \
        $flow_text \
        {error[[:space:]]+\$propagated_clock_error} \
        "$flow_name must hard-stop when propagated-clock setup fails"

    set power_catch_index [string first {catch {source ./tcl/power_plan.tcl}} $flow_text]
    set pin_source_index [string first {source ./tcl/pins.tcl} $flow_text $power_catch_index]
    set failure_return_index [string first "\n    return\n" $flow_text $power_catch_index]
    set power_entry_index [string first {POWER PLAN ENTRY:} $flow_text]
    set power_exit_index [string first {POWER PLAN EXIT:} $flow_text $power_catch_index]
    set edge_report_index [string first {set sram_edge_report ./reports/sram_island_pg_edges.rpt} $flow_text]
    set edge_delete_index [string first {file delete -force $sram_edge_report} $flow_text]
    set direct_sram_source_index [string first {source ./tcl/sram_island_power.tcl} $flow_text $power_catch_index]
    set upper_pg_index [string first {source ./tcl/global_upper_pg_to_ring.tcl} $flow_text]
    set lower_pg_index [string first {source ./tcl/core_lower_pg_nojog.tcl} $flow_text]
    set middle_pg_index [string first {source ./tcl/core_pg_outside_island.tcl} $flow_text]
    set stale_post_place_delete_index [string first {file delete -force $stale_post_place_pg_report} $flow_text]
    set post_place_guard_index [string first {connect_core_pg_pins_nojog ./verify_rpt/pg_connectivity_after_trim.rpt} $flow_text]
    set post_place_drc_guard_index [string first {verify_pg_special_drc_or_stop ./verify_rpt/pg_drc_after_trim.rpt {M4 M9}} $flow_text]
    set placed_save_index [string first {saveDesign ./saved/axi_ram_placed.enc} $flow_text]
    set before_trim_verify_seen [regexp {
        verifyConnectivity[[:space:]\n\\]+.*pg_connectivity_before_trim\.rpt
    } $flow_text]
    set power_error_return_index [string first {error $power_plan_error} $flow_text $power_catch_index]
    set route_guard_source_index [string first {source ./tcl/sram_route_guard.tcl} $flow_text]
    set place_opt_index [string first {place_opt_design} $flow_text]
    set propagated_clock_index [string first {set_propagated_clock [all_clocks]} $flow_text]
    set clock_opt_index [string first {clock_opt_design} $flow_text]
    if {$power_catch_index < 0 || $pin_source_index < 0 ||
        $power_error_return_index < $power_catch_index ||
        $power_error_return_index > $pin_source_index} {
        fail "$flow_name must raise a Tcl error immediately on a power-plan failure instead of continuing into pins.tcl"
    }
    if {$power_entry_index < 0 ||
        $power_entry_index > $power_catch_index ||
        $power_exit_index < $power_catch_index ||
        $power_exit_index > $pin_source_index} {
        fail "$flow_name must bracket power_plan.tcl in the log before pin assignment"
    }
    if {$edge_report_index < 0 ||
        $edge_report_index > $power_catch_index ||
        $edge_delete_index < $edge_report_index ||
        $edge_delete_index > $power_catch_index} {
        fail "$flow_name must delete stale SRAM edge evidence before sourcing power_plan.tcl"
    }
    if {$direct_sram_source_index < $power_exit_index ||
        $direct_sram_source_index > $pin_source_index} {
        fail "$flow_name must run the direct SRAM island fallback after power_plan.tcl and before pins.tcl"
    }
    if {$upper_pg_index < 0 ||
        $lower_pg_index < 0 ||
        $middle_pg_index < 0 ||
        $lower_pg_index > $middle_pg_index ||
        $middle_pg_index > $upper_pg_index} {
        fail "$flow_name must build post-placement PG upward: M1/M5 taps, then M6/M7 mesh, then M8/M9 upper mesh"
    }
    if {$stale_post_place_delete_index < 0 ||
        $stale_post_place_delete_index > $lower_pg_index} {
        fail "$flow_name must delete stale post-placement PG reports before rebuilding the mesh"
    }
    if {$post_place_guard_index < 0 ||
        $placed_save_index < 0 ||
        $post_place_guard_index > $placed_save_index} {
        fail "$flow_name must trim/reconnect and guard PG connectivity before saving axi_ram_placed.enc"
    }
    if {$post_place_drc_guard_index < 0 ||
        $post_place_drc_guard_index > $placed_save_index} {
        fail "$flow_name must guard post-placement PG DRC before saving axi_ram_placed.enc"
    }
    if {$before_trim_verify_seen} {
        fail "$flow_name must not verify a pre-trim PG state that is expected to contain dangling M1 rail endpoints"
    }
    if {$route_guard_source_index < 0 ||
        $place_opt_index < 0 ||
        $route_guard_source_index > $place_opt_index} {
        fail "$flow_name must install SRAM route reservation before place_opt_design"
    }
    if {$clock_opt_index < 0 ||
        $propagated_clock_index < $clock_opt_index} {
        fail "$flow_name must set propagated clocks only after CTS has run"
    }

    assert_contains \
        $flow_text \
        {INNOVUS_STOP_AFTER_POWER_PINS} \
        "$flow_name must support a checkpoint stop after power plan and top-level pin assignment"

    set save_index [string first "saveDesign ./saved/axi_ram_floorplan_power_pins.enc" $flow_text]
    set place_index [string first "place_opt_design" $flow_text]
    set stop_index [string first "STOP_AFTER_POWER_PINS" $flow_text $save_index]
    if {$save_index < 0 || $place_index < 0 || $stop_index < 0 ||
        $stop_index >= $place_index} {
        fail "$flow_name must check STOP_AFTER_POWER_PINS after saving the power/pins checkpoint and before place_opt_design"
    }
}

assert_contains \
    $flow_checks_text \
    {-connect[[:space:]]+\{floatingStripe\}} \
    "flow_checks.tcl must connect area-constrained floating PG stripes before corePin reconnect"
assert_contains \
    $flow_checks_text \
    {-floatingStripeTarget[[:space:]]+\{ring[[:space:]]+stripe[[:space:]]+blockring\}} \
    "flow_checks.tcl must target existing rings/stripes/blockrings for floating PG stripe stitching"
assert_contains \
    $flow_checks_text \
    {-net[[:space:]]+\{VDD[[:space:]]+VSS\}} \
    "post-placement PG verifyConnectivity must be restricted to VDD/VSS"
assert_contains \
    $flow_checks_text \
    {proc[[:space:]]+verify_pg_special_drc_or_stop} \
    "flow_checks.tcl must provide a shared PG special-route DRC guard"
assert_contains \
    $flow_checks_text \
    {-check_only[[:space:]]+special} \
    "flow_checks.tcl PG DRC guard must isolate special-route DRC"
assert_contains \
    $flow_checks_text \
    {assert_clean_connectivity_report[[:space:]]+\$report_file} \
    "flow_checks.tcl must hard-stop on dirty post-placement PG before saveDesign"

warn_if_dirty_report [file join $innovus_dir verify_rpt pg_drc_before_stdcell_place.rpt]
warn_if_dirty_report [file join $innovus_dir verify_rpt pg_connectivity_before_stdcell_place.rpt]

puts "PASS: SRAM power-plan Tcl static checks"
