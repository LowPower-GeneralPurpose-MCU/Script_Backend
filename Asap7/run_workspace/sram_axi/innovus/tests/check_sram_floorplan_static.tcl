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

if {![regexp {set[[:space:]]+SRAM_ROWS[[:space:]]+4} $setup_text] ||
    ![regexp {set[[:space:]]+SRAM_COLS[[:space:]]+4} $setup_text]} {
    fail "SRAM hierarchy must remain one complete rectangular 4x4 cluster"
}
if {![regexp {set[[:space:]]+SRAM_ISLAND_ORIENT[[:space:]]+"R180"} $setup_text]} {
    fail "SRAM orientation must be an explicitly reviewed R0/R180 choice"
}
if {![regexp {set[[:space:]]+SRAM_MACRO_GAP_ROWS[[:space:]]+4} $setup_text]} {
    fail "Inter-macro channels must reserve four ASAP7 rows for power and signal escape"
}
if {![regexp {createInstGroup[[:space:]]+\$SRAM_GROUP_NAME([[:space:]]|$)} $macro_text]} {
    fail "All SRAM macros must be recorded in one hierarchy group"
}
if {[regexp {createInstGroup[^\r\n]*-fence|createInstGroup[^\r\n]*\\[\r\n]+[[:space:]]*-fence} $macro_text]} {
    fail "The macro-only SRAM group must not be an exclusive fence for standard cells"
}
if {![regexp {addInstToInstGroup[[:space:]]+\\[[:space:]]*\n[[:space:]]*\$SRAM_GROUP_NAME} $macro_text]} {
    fail "Every SRAM record must be added to the SRAM hierarchy group"
}
if {![regexp {dbSet[[:space:]]+\$ptr\.pStatus[[:space:]]+fixed} $finish_text]} {
    fail "SRAM macros must be FIXED after manual placement and validation"
}

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

if {![regexp {cutRow[[:space:]]+-area[[:space:]]+\$SRAM_ISLAND_CUT_BOX} $finish_text]} {
    fail "finish_macroFP.tcl must cut rows only across the SRAM island keepout"
}
if {![regexp {createPlaceBlockage[[:space:]]+\\[^#]+-box[[:space:]]+\$SRAM_ISLAND_CUT_BOX} $finish_text]} {
    fail "finish_macroFP.tcl must hard-block only the SRAM island keepout"
}
if {![regexp {set[[:space:]]+SRAM_NO_MESH_URY[[:space:]]+\$SRAM_ISLAND_CUT_URY} $finish_text]} {
    fail "finish_macroFP.tcl must end the no-mesh region at the SRAM island border"
}
if {![regexp {set[[:space:]]+SRAM_MACRO_BOXES[[:space:]]+\$actual_boxes} $finish_text]} {
    fail "finish_macroFP.tcl must export nominal hard-macro boxes for hierarchical top-level DRC scoping"
}
if {![regexp {SRAM_MACRO_BOXES} [string range $finish_text [string first {foreach variable} $finish_text] end]]} {
    fail "finish_macroFP.tcl must persist SRAM_MACRO_BOXES in outputs/sram_macro_geometry.tcl"
}
if {[regexp {set[[:space:]]+SRAM_NO_MESH_URY[[:space:]]+\$core_ury} $finish_text]} {
    fail "finish_macroFP.tcl must not reserve the legal logic channel above the SRAM island"
}
if {![regexp {puts[[:space:]]+\$blockage_report[[:space:]]+"no_mesh_box[[:space:]]+\$SRAM_NO_MESH_BOX"} $finish_text]} {
    fail "finish_macroFP.tcl must report the no-mesh SRAM reservation for GUI/log correlation"
}
if {[regexp {createPlaceBlockage[[:space:]]+\\[^#]+-box[[:space:]]+\$SRAM_ISLAND_BLOCKAGE_BOX} $finish_text]} {
    fail "finish_macroFP.tcl must not create a placement blockage from the unclamped die-edge SRAM_ISLAND_BLOCKAGE_BOX"
}
set geometry_output [file join $innovus_dir outputs sram_macro_geometry.tcl]
if {[file exists $geometry_output]} {
    set geometry_text [assert_file_complete $geometry_output]
    if {![regexp {set[[:space:]]+SRAM_NO_MESH_BOX[[:space:]]+\{2\.16[[:space:]]+2\.16[[:space:]]+502\.848[[:space:]]+708\.48\}} $geometry_text]} {
        puts stderr "WARN: outputs/sram_macro_geometry.tcl is from the previous full-column blockage run; rerun Innovus to regenerate it"
    }
}

set blockage_report_path \
    [file join $innovus_dir reports sram_island_blockage_geometry.rpt]
if {[file exists $blockage_report_path]} {
    set fh [open $blockage_report_path r]
    set blockage_report_text [read $fh]
    close $fh

    foreach expected_line {
        {row_cut_box 2.16 2.16 502.848 708.48}
        {local_sram_pg_cut_box 2.16 2.16 502.848 708.48}
        {no_mesh_box 2.16 2.16 502.848 708.48}
        {place_blockage_box 2.16 2.16 502.848 708.48}
    } {
        if {[string first $expected_line $blockage_report_text] < 0} {
            puts stderr "WARN: reports/sram_island_blockage_geometry.rpt is stale; rerun Innovus to produce '$expected_line'"
            break
        }
    }
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
