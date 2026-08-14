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
    if {![regexp -- $pattern $text]} {
        fail $message
    }
}

set pins_tcl [file join $tcl_dir pins.tcl]
set pins_text [read_complete_file $pins_tcl]

assert_contains \
    $pins_text \
    {PIN[[:space:]]+PLAN[[:space:]]+REVISION:} \
    "pins.tcl must print a revision marker so innovus.log proves which pin plan ran"
assert_contains \
    $pins_text \
    {checkPinAssignment[[:space:]\\]+-outFile[[:space:]]+\./verify_rpt/checkPinAssignment_after_pin\.rpt} \
    "pins.tcl must run the Cadence pin-legality checker after batch assignment"
assert_contains \
    $pins_text \
    {top_requested_uniform_pitch} \
    "pins.tcl must report the requested uniform TOP-pin pitch and row"
assert_contains \
    $pins_text \
    {sram_axi_four_side_connectivity_v6} \
    "pins.tcl must use the LEF/DRM-aware four-side AXI pin-plan revision"

foreach field {
    top.fPlan.coreBox_llx
    top.fPlan.coreBox_lly
    top.fPlan.coreBox_urx
    top.fPlan.coreBox_ury
} {
    assert_contains \
        $pins_text \
        [string map {. \\.} $field] \
        "pins.tcl must place top-level pins from the core box, not the die box"
}

if {[regexp -- {top\.fPlan\.box} $pins_text]} {
    fail "pins.tcl must not use the die box for core-edge pin placement"
}

foreach side {TOP RIGHT BOTTOM LEFT} {
    if {[string first "-side $side" $pins_text] < 0} {
        fail "pins.tcl must use the legal $side boundary segment"
    }
}

foreach {side layer} {TOP M7 RIGHT M6 BOTTOM M7 LEFT M6} {
    set side_index [string first "-side $side" $pins_text]
    set layer_index [string first "-layer $layer" $pins_text $side_index]
    if {$side_index < 0 || $layer_index < $side_index} {
        fail "$side pins should use layer $layer"
    }
}

foreach pitch_name {
    top_requested_uniform_pitch
    right_requested_uniform_pitch
    bottom_requested_uniform_pitch
    left_requested_uniform_pitch
} {
    assert_contains $pins_text $pitch_name \
        "pins.tcl must report $pitch_name"
}
assert_contains \
    $pins_text \
    {set[[:space:]]+bottom_end[[:space:]]+\[list[[:space:]\\]+\[expr[[:space:]]+\{\$pin_core_llx[[:space:]]+\+[[:space:]]+\$PIN_EDGE_CLEARANCE\}\]} \
    "BOTTOM signal pins must use the full bottom core edge, not the SRAM no-mesh box"
assert_contains \
    $pins_text \
    {set[[:space:]]+left_end[[:space:]]+\[list[[:space:]\\]+\$pin_core_llx[[:space:]]+\[expr[[:space:]]+\{\$pin_core_lly[[:space:]]+\+[[:space:]]+\$PIN_EDGE_CLEARANCE\}\]} \
    "LEFT signal pins must use the full left core edge, not the SRAM no-mesh box"
if {[regexp -- {SRAM_NO_MESH_UR[XY]} $pins_text]} {
    fail "pins.tcl must not clip M6/M7 signal pins by the SRAM power no-mesh box"
}
foreach channel_marker {
    {left_group CLK_RST_AW}
    {bottom_group W}
    {top_group AR}
    {right_group B_R}
} {
    assert_contains \
        $pins_text \
        $channel_marker \
        "pins.tcl must report AXI channel marker '$channel_marker'"
}

set right_start_index [string first {set right_start [list} $pins_text]
set right_end_index [string first {set right_end [list} $pins_text]
set edit_pin_index [string first {setPinAssignMode -pinEditInBatch true} $pins_text]

if {$right_start_index < 0 ||
    [string first {$pin_core_ury - $PIN_EDGE_CLEARANCE} $pins_text $right_start_index] < 0 ||
    [string first {$pin_core_ury - $PIN_EDGE_CLEARANCE} $pins_text $right_start_index] > $right_end_index} {
    fail "RIGHT pins must start from the top of the right edge when using clockwise spreading"
}
if {$right_end_index < 0 ||
    [string first {$pin_core_lly + $PIN_EDGE_CLEARANCE} $pins_text $right_end_index] < 0 ||
    [string first {$pin_core_lly + $PIN_EDGE_CLEARANCE} $pins_text $right_end_index] > $edit_pin_index} {
    fail "RIGHT pins must end at the bottom of the right edge when using clockwise spreading"
}

puts "PASS: SRAM signal pin-plan Tcl static checks"
