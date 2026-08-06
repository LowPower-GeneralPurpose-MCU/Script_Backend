#!/usr/bin/env tclsh

set script_dir [file dirname [file normalize [info script]]]
set innovus_dir [file dirname $script_dir]
set tcl_dir [file join $innovus_dir tcl]

proc fail {message} {
    puts stderr "FAIL: $message"
    exit 1
}

proc assert_file_complete {path} {
    set fh [open $path r]
    set text [read $fh]
    close $fh

    if {![info complete $text]} {
        fail "[file tail $path] is not a complete Tcl script"
    }
    return $text
}

set macro_floorplan [file join $tcl_dir sram_macro_floorplan.tcl]
set finish_macro_fp [file join $tcl_dir finish_macroFP.tcl]

set macro_text [assert_file_complete $macro_floorplan]
set finish_text [assert_file_complete $finish_macro_fp]

if {![regexp {proc[[:space:]]+sram_snap_to_grid[[:space:]]+\{} $macro_text]} {
    fail "sram_macro_floorplan.tcl must define sram_snap_to_grid before placing SRAMs"
}

if {![regexp {set[[:space:]]+placed_orient[[:space:]]+\[lindex[[:space:]]+\[dbGet[[:space:]]+\$ptr\.orient\][[:space:]]+0\]} $macro_text]} {
    fail "sram_macro_floorplan.tcl must normalize dbGet orientation before comparing it"
}

if {![regexp {set[[:space:]]+orient[[:space:]]+\[lindex[[:space:]]+\[dbGet[[:space:]]+\$ptr\.orient\][[:space:]]+0\]} $finish_text]} {
    fail "finish_macroFP.tcl must normalize dbGet orientation before validating it"
}

set stale_map [file join $innovus_dir reports sram_macro_final_map.rpt]
if {![regexp {set[[:space:]]+status[[:space:]]+\[lindex[[:space:]]+\[dbGet[[:space:]]+\$ptr\.pStatus\][[:space:]]+0\]} $finish_text]} {
    fail "finish_macroFP.tcl must normalize dbGet placement status before validating it"
}

if {![regexp {createPlaceBlockage[[:space:]]+\\[^#]+-box[[:space:]]+\$SRAM_ISLAND_CUT_BOX} $finish_text]} {
    fail "finish_macroFP.tcl must clamp the hard placement blockage to SRAM_ISLAND_CUT_BOX so it stays inside the core"
}
if {[regexp {createPlaceBlockage[[:space:]]+\\[^#]+-box[[:space:]]+\$SRAM_ISLAND_BLOCKAGE_BOX} $finish_text]} {
    fail "finish_macroFP.tcl must not create a placement blockage from the unclamped die-edge SRAM_ISLAND_BLOCKAGE_BOX"
}

if {[file exists $stale_map]} {
    set fh [open $stale_map r]
    set lines [split [read $fh] "\n"]
    close $fh

    set origins {}
    foreach line [lrange $lines 1 end] {
        set fields [regexp -all -inline {\S+} $line]
        if {[llength $fields] < 4} {
            continue
        }
        lappend origins "[lindex $fields 2],[lindex $fields 3]"
    }

    if {[llength $origins] > 1 && [llength [lsort -unique $origins]] == 1} {
        puts stderr "WARN: stale sram_macro_final_map.rpt has all SRAM macros at the same origin; rerun macro floorplan after fixing Tcl"
    }
}

puts "PASS: SRAM floorplan Tcl static checks"
