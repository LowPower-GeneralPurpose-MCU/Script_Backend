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

if {[regexp -- {SRAM_ISLAND_CUT|PIN_ISLAND_CLEARANCE|above island|right of island} $pins_text]} {
    fail "pins.tcl must spread signal pins on the complete four core edges, not only island-avoidance sub-ranges"
}

foreach side {TOP RIGHT LEFT BOTTOM} {
    if {[string first "-side $side" $pins_text] < 0} {
        fail "pins.tcl must assign pins on the $side core edge"
    }
}

foreach {side layer} {TOP M7 BOTTOM M7 LEFT M6 RIGHT M6} {
    set side_index [string first "-side $side" $pins_text]
    set layer_index [string first "-layer $layer" $pins_text $side_index]
    if {$side_index < 0 || $layer_index < $side_index} {
        fail "$side pins should use layer $layer"
    }
}

puts "PASS: SRAM signal pin-plan Tcl static checks"
