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

    if {[llength $args] == 1 && [lindex $args 0] eq "top.fPlan.box"} {
        return {0.0 0.0 1105.2 970.848}
    }

    fail "Unexpected dbGet call while simulating SRAM island PG: $args"
}

proc deselectAll {} {}
proc selectInst {name} {}
proc addRing {args} {}
proc setSrouteMode {args} {}
proc sroute {args} {}
proc setAddStripeMode {args} {}
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
        [list $opts(-layer) $opts(-direction) $opts(-area) $create_pins]
}

proc simulate_sram_island_power {script_path} {
    global SRAM_STRIPE_CAPTURE
    global SRAM_MASTER SRAM_COUNT SRAM_ROWS SRAM_COLS
    global SRAM_X0 SRAM_Y0 SRAM_W SRAM_H
    global SRAM_MACRO_GAP_X SRAM_MACRO_GAP_Y
    global SRAM_ISLAND_LLX SRAM_ISLAND_LLY SRAM_ISLAND_URX SRAM_ISLAND_URY
    global SRAM_ISLAND_CUT_LLX SRAM_ISLAND_CUT_LLY
    global SRAM_ISLAND_CUT_URX SRAM_ISLAND_CUT_URY
    global SRAM_PG_MODEL_RING_W SRAM_PG_MODEL_RING_S
    global SRAM_PG_MODEL_STRIPE_W SRAM_PG_MODEL_STRIPE_S
    global SRAM_PG_MODEL_STRIPE_PITCH ASAP7_ROW_HEIGHT
    global core_llx core_lly ring_m89_span

    set SRAM_STRIPE_CAPTURE {}

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
    set SRAM_PG_MODEL_RING_W 0.096
    set SRAM_PG_MODEL_RING_S 0.288
    set SRAM_PG_MODEL_STRIPE_W 0.096
    set SRAM_PG_MODEL_STRIPE_S 0.288
    set SRAM_PG_MODEL_STRIPE_PITCH 25.920
    set ASAP7_ROW_HEIGHT 1.080
    set core_llx 2.16
    set core_lly 2.16
    set ring_m89_span 1.824

    if {[catch {source $script_path} message]} {
        fail "Simulated SRAM island PG failed: $message"
    }

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
    global_upper_pg_to_ring.tcl
    core_lower_pg_nojog.tcl
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

foreach old_child {
    sram_gap_stripes.tcl
    sram_macro_power.tcl
    stitch_island_to_core.tcl
    core_pg_outside_island.tcl
} {
    if {[string first "source ./tcl/$old_child" $power_text] >= 0} {
        fail "power_plan.tcl must not source $old_child; final SRAM island PG must follow the reference ring/stripe pattern"
    }
}

assert_contains \
    $power_text \
    {source[[:space:]]+\./tcl/sram_island_power\.tcl} \
    "power_plan.tcl must source the reference-style SRAM island PG script"
assert_contains \
    $power_text \
    {set[[:space:]]+PG_ENABLE_UPPER_MESH[[:space:]]+0} \
    "Upper M8/M9 mesh must be disabled by default at the floorplan power/pins checkpoint"
assert_contains \
    $power_text \
    {if[[:space:]]+\{\$PG_ENABLE_UPPER_MESH\}} \
    "Optional upper M8/M9 mesh must be gated behind PG_ENABLE_UPPER_MESH"
assert_contains \
    $power_text \
    {source[[:space:]]+\./tcl/global_upper_pg_to_ring\.tcl} \
    "power_plan.tcl must keep the optional outside-island M8/M9 mesh available behind a gate"

foreach proc_name {
    pg_layer_pitch
    pg_layer_offset
    pg_snap_value_to_layer_track
    pg_positive_mod
    pg_track_aligned_pair_offset
    pg_track_aligned_global_offset
    pg_create_core_ring_corner_pins
    pg_delete_core_pg_pins
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

foreach margin_var {die_core_margin_left die_core_margin_bottom die_core_margin_right die_core_margin_top} {
    if {[string first "set $margin_var" $power_text] < 0} {
        fail "power_plan.tcl must check $margin_var before adding the M8/M9 ring"
    }
}

set ring_snap_count [regexp -all -- {-snap_wire_center_to_grid[[:space:]]+Grid} $all_power_text]
if {$ring_snap_count < 2} {
    fail "Both core and SRAM addRing commands must snap wire centers to the routing grid"
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
    {pg_delete_core_pg_pins} \
    "power_plan.tcl must delete stale VDD/VSS PG pin shapes before recreating the ring"

if {[regexp {foreach[[:space:]]+side[[:space:]]+\{bottom[[:space:]]+top[[:space:]]+left[[:space:]]+right\}} $power_text]} {
    fail "Core PG pins must not be full-side duplicate ring shapes; create small corner pins only"
}

if {[regexp -- {createPGPin[[:space:]]+VDD|createPGPin[[:space:]]+VSS} $power_text]} {
    fail "Core PG pins must not be hard-coded as one lower-left VDD/VSS shape"
}

if {[regexp -- {-snap_wire_center_to_grid[[:space:]]+grid} $all_power_text]} {
    fail "Use Innovus documented Grid spelling for snap_wire_center_to_grid"
}

set addstripe_count [regexp -all {addStripe[[:space:]]+\\} $all_power_text]
set snap_override_count [regexp -all -- {-allow_snapping_override_custom_spacing[[:space:]]+1} $all_power_text]
if {$snap_override_count < $addstripe_count} {
    fail "Every addStripe in the SRAM power plan must allow snapping to override custom spacing"
}

set area_addstripe_count [regexp -all -- {-area[[:space:]]+\$[[:alnum:]_]+} $all_power_text]
set area_boundary_count [regexp -all -- {-extend_to_closest_target[[:space:]]+area_boundary} $all_power_text]
if {$area_boundary_count < $area_addstripe_count} {
    fail "Area-limited SRAM/core/global stripes must extend to area_boundary so Innovus does not silently skip edge stripes"
}

assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {pg_track_aligned_global_offset} \
    "core_lower_pg_nojog.tcl must derive repeated-mesh offsets from the ASAP7 routing track grid"
assert_contains \
    $child_text(core_lower_pg_nojog.tcl) \
    {info[[:space:]]+exists[[:space:]]+LOGIC_RIGHT_FULL_BOX} \
    "core_lower_pg_nojog.tcl must rebuild the logic boxes when floorplan PG no longer sources core_pg_outside_island.tcl"

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
if {[string first {Special[[:space:]]+(Wire|Via)} $power_text] < 0} {
    fail "PG DRC guard must fail on special-route wire/via DRCs, while allowing fake SRAM macro-pin DRCs to be reviewed later"
}
if {[regexp {\$count[[:space:]]*>[[:space:]]*0} $power_text]} {
    fail "PG DRC guard must not fail on total DRC count alone because fake SRAM macro-pin DRCs are expected in this flow"
}
assert_contains \
    $power_text \
    {editTrim[[:space:]]+-nets[[:space:]]+\{VDD[[:space:]]+VSS\}} \
    "power_plan.tcl must trim dangling VDD/VSS wires before final PG verification"

assert_contains \
    $child_text(sram_island_power.tcl) \
    {-viaConnectToShape[[:space:]]+blockring} \
    "SRAM blockPin sroute must target the shared-cluster blockring, matching the reference SRAM island flow"

if {[regexp -- {-allowJogging|-allowLayerChange} $child_text(sram_island_power.tcl)]} {
    fail "SRAM blockPin sroute must not pass explicit allowJogging/allowLayerChange switches"
}

set sram_island_code_only ""
foreach line [split $child_text(sram_island_power.tcl) "\n"] {
    if {![regexp {^[[:space:]]*#} $line]} {
        append sram_island_code_only $line "\n"
    }
}

assert_contains \
    $child_text(sram_island_power.tcl) \
    {-around[[:space:]]+shared_cluster} \
    "SRAM island ring must use the shared_cluster topology from the reference flow"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-break_at[[:space:]]+block_ring} \
    "SRAM island stripes must break at block rings like the reference flow"
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
set global_upper_stripes [regexp -all {addStripe[[:space:]]+\\} $global_upper_code_only]
set global_upper_no_pin_stripes [regexp -all -- {-create_pins[[:space:]]+0} $global_upper_code_only]
if {$global_upper_stripes == 0 || $global_upper_no_pin_stripes < $global_upper_stripes} {
    fail "Every M8/M9 outside-island addStripe must use -create_pins 0; top-level PG pins are created explicitly from the core ring"
}

set simulated_sram_stripes \
    [simulate_sram_island_power [file join $tcl_dir sram_island_power.tcl]]
if {[llength $simulated_sram_stripes] != 6} {
    fail "SRAM island power must generate exactly 3 M4 row-gap and 3 M5 column-gap stripe pairs"
}

foreach stripe $simulated_sram_stripes {
    lassign $stripe layer direction area create_pins
    if {$create_pins ne "0"} {
        fail "SRAM island addStripe must use -create_pins 0 so local gap stripes do not become boundary IO pins"
    }

    if {[llength $area] != 4} {
        fail "SRAM island addStripe area must be a four-coordinate box"
    }
    lassign $area llx lly urx ury

    if {$llx <= 0.0 || $lly <= 0.0 || $urx >= 1105.2 || $ury >= 970.848} {
        fail "SRAM island gap stripes must not span to the die boundary: $area"
    }

    switch -- $direction {
        horizontal {
            if {$layer ne "M4"} {
                fail "Horizontal SRAM island stripes must be on M4, got $layer"
            }
            assert_close $llx 0.336 "M4 SRAM row-gap stripe must start at the adjacent M8/M9 core-ring overlap, not the die edge"
            assert_close $urx 502.848 "M4 SRAM row-gap stripe must stop at the SRAM island cut boundary"
        }
        vertical {
            if {$layer ne "M5"} {
                fail "Vertical SRAM island stripes must be on M5, got $layer"
            }
            assert_close $lly 0.336 "M5 SRAM column-gap stripe must start at the adjacent M8/M9 core-ring overlap, not the die edge"
            assert_close $ury 708.48 "M5 SRAM column-gap stripe must stop at the SRAM island cut boundary"
        }
        default {
            fail "Unexpected SRAM island stripe direction: $direction"
        }
    }
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

warn_if_dirty_report [file join $innovus_dir verify_rpt pg_drc_before_stdcell_place.rpt]
warn_if_dirty_report [file join $innovus_dir verify_rpt pg_connectivity_before_stdcell_place.rpt]

puts "PASS: SRAM power-plan Tcl static checks"
