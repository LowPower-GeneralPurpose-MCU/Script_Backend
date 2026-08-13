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
set macro_setup [file join $tcl_dir sram_macro_setup.tcl]

set macro_text [assert_file_complete $macro_floorplan]
set finish_text [assert_file_complete $finish_macro_fp]
set setup_text [assert_file_complete $macro_setup]

if {![regexp {set[[:space:]]+LOGIC_REGION_WIDTH[[:space:]]+\[sram_env_double_or_default[[:space:]]+SRAM_LOGIC_REGION_WIDTH[[:space:]]+120\.000[[:space:]]+80\.000\]} $setup_text]} {
    fail "sram_macro_setup.tcl must default to a compact 120um right-side logic channel with env override"
}

if {![regexp {set[[:space:]]+LOGIC_REGION_HEIGHT[[:space:]]+\[sram_env_double_or_default[[:space:]]+SRAM_LOGIC_REGION_HEIGHT[[:space:]]+60\.000[[:space:]]+40\.000\]} $setup_text]} {
    fail "sram_macro_setup.tcl must default to a compact 60um top logic channel with env override"
}

if {[regexp {set[[:space:]]+LOGIC_REGION_WIDTH[[:space:]]+600\.000} $setup_text] ||
    [regexp {set[[:space:]]+LOGIC_REGION_HEIGHT[[:space:]]+260\.000} $setup_text]} {
    fail "sram_macro_setup.tcl must not keep the old oversized logic reserve that produced sub-1% std-cell density"
}

if {[string first {source ./tcl/sram_pg_model_for_macro_place.tcl} $macro_text] >= 0 ||
    [string first {place_design -concurrent_macros} $macro_text] >= 0 ||
    [regexp {SRAM_PG_MODEL} $setup_text]} {
    fail "SRAM macro floorplan must not use the old temporary PG model or concurrent macro placement path"
}

if {[string first {./outputs/golden_mimic_sram_power_mesh.tcl} $macro_text] >= 0 ||
    [string first {./reports/sram_macro_concurrent_map.rpt} $macro_text] >= 0} {
    fail "SRAM macro floorplan must not reference obsolete temporary-PG/concurrent reports"
}

if {[string first {./reports/sram_macro_deterministic_map.rpt} $macro_text] < 0 ||
    [string first {set SRAM_PACK_RECORDS} $macro_text] < 0} {
    fail "SRAM macro floorplan must write a deterministic SRAM placement map"
}

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
