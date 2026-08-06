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
    global_upper_pg_to_ring.tcl
} {
    if {[string first "source ./tcl/$old_child" $power_text] >= 0} {
        fail "power_plan.tcl must not source $old_child; final SRAM island PG must follow the reference ring/stripe pattern"
    }
}

assert_contains \
    $power_text \
    {source[[:space:]]+\./tcl/sram_island_power\.tcl} \
    "power_plan.tcl must source the reference-style SRAM island PG script"

foreach proc_name {
    pg_layer_pitch
    pg_layer_offset
    pg_snap_value_to_layer_track
    pg_positive_mod
    pg_track_aligned_pair_offset
    pg_track_aligned_global_offset
    pg_create_core_ring_pin_shapes
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
    {foreach[[:space:]]+side[[:space:]]+\{bottom[[:space:]]+top[[:space:]]+left[[:space:]]+right\}} \
    "Core PG pins must be created on all four sides of the core ring"
assert_contains \
    $power_text \
    {foreach[[:space:]]+net[[:space:]]+\{VDD[[:space:]]+VSS\}} \
    "Core PG pin creation must cover both VDD and VSS"
assert_contains \
    $power_text \
    {deletePGPin[[:space:]]+-net[[:space:]]+\$net} \
    "Core PG pin creation must delete old VDD/VSS PG pin shapes before recreating them"

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
    {pg_assert_clean_drc_report[[:space:]]+\$pg_drc_report} \
    "power_plan.tcl must stop before saveDesign when PG DRC is dirty"
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

assert_contains \
    $child_text(sram_island_power.tcl) \
    {-around[[:space:]]+shared_cluster} \
    "SRAM island ring must use the shared_cluster topology from the reference flow"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-break_at[[:space:]]+block_ring} \
    "SRAM island stripes must break at block rings like the reference flow"
assert_contains \
    $child_text(sram_island_power.tcl) \
    {-extend_to[[:space:]]+design_boundary} \
    "SRAM island stripes must extend to the design boundary like the reference flow"
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
}

warn_if_dirty_report [file join $innovus_dir verify_rpt pg_drc_before_stdcell_place.rpt]
warn_if_dirty_report [file join $innovus_dir verify_rpt pg_connectivity_before_stdcell_place.rpt]

puts "PASS: SRAM power-plan Tcl static checks"
