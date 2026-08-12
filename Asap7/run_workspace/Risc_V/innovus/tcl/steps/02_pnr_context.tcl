# =============================================================================
# Step 02: enter PnR context and define shared helpers.
#
# Paste after 01_hierfp, or run standalone after a saved hierFP checkpoint:
#   source ./tcl/steps/02_pnr_context.tcl
# =============================================================================

riscv_step_banner "STEP 02: PnR context"

if {![info exists TOP]} {
    source ./tcl/tool_setup.tcl
}

set reuse_active_design 0
if {[info exists ::INNOVUS_COMBINED_FLOW] && $::INNOVUS_COMBINED_FLOW} {
    if {![catch {dbGet top.name} active_top] && $active_top eq $TOP} {
        set reuse_active_design 1
    }
}

if {$reuse_active_design} {
    puts "INFO: Continuing from active hierarchy floorplan for $TOP."
} else {
    source ./tcl/tool_setup.tcl

    set HIER_CHECKPOINT ./saved/${TOP}_hierFP.enc
    if {![file isfile $HIER_CHECKPOINT]} {
        error "Missing $HIER_CHECKPOINT. Run step 01 first."
    }

    restoreDesign $HIER_CHECKPOINT $TOP
    setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
}

setMultiColorsHier

set_interactive_constraint_modes [all_constraint_modes]
if {[sizeof_collection [all_clocks]] == 0} {
    error "No functional clock is active before PnR."
}

proc write_skipped_report {report_file reason} {
    set fh [open $report_file w]
    puts $fh "SKIPPED"
    puts $fh $reason
    close $fh
}

proc assert_clean_drc_report {report_file} {
    if {![file exists $report_file]} {
        error "Missing DRC report: $report_file"
    }

    set fh [open $report_file r]
    set text [read $fh]
    close $fh

    if {[regexp {No DRC violations were found} $text] ||
        [regexp {Total number of DRC violations[[:space:]]*=[[:space:]]*0} $text] ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $text]} {
        return
    }

    error "DRC is not clean: review $report_file"
}

proc assert_clean_connectivity_report {report_file} {
    if {![file exists $report_file]} {
        error "Missing connectivity report: $report_file"
    }

    set fh [open $report_file r]
    set text [read $fh]
    close $fh

    if {[regexp {Found no problems or warnings\.} $text]} {
        return
    }

    error "Connectivity is not clean: review $report_file"
}

proc env_flag {name default_value} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        return $default_value
    }

    switch -nocase -- $::env($name) {
        1 - true - yes - on  { return 1 }
        0 - false - no - off { return 0 }
        default {
            error "$name must be 0/1, false/true, no/yes, or off/on"
        }
    }
}

proc verify_antenna_if_enabled {report_file} {
    if {![env_flag INNOVUS_RUN_ANTENNA_CHECK 0]} {
        write_skipped_report $report_file \
            "Antenna check skipped. ASAP7 educational LEFs used here do not load process antenna rules by default."
        puts "INFO: Antenna check skipped. Set INNOVUS_RUN_ANTENNA_CHECK=1 only when antenna rules are loaded."
        return 0
    }

    if {[catch {verify_antenna -report $report_file} antenna_error]} {
        if {[string first "no process antenna information" $antenna_error] >= 0 ||
            [string first "IMPVPA-22" $antenna_error] >= 0} {
            write_skipped_report $report_file \
                "Antenna check skipped because Innovus reported no process antenna information."
            puts "INFO: Antenna check skipped: no process antenna information is loaded."
            return 0
        }
        return -code error $antenna_error
    }

    return 1
}

proc format_pg_coord {value} {
    return [format %.3f $value]
}

proc find_left_m9_ring_box {net core_llx core_lly core_ury} {
    set net_ptr [lindex [dbGet -p top.nets.name $net] 0]
    if {$net_ptr eq "" || $net_ptr eq "0x0"} {
        error "Cannot find PG net $net while creating the M9 ring pin"
    }

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

proc create_left_m9_ring_pg_pins {core_llx core_lly core_ury} {
    catch {deletePGPin -net VDD}
    catch {deletePGPin -net VSS}

    set pg_pin_length [expr {6.0 * 0.320}]
    set pg_pin_center_y [expr {($core_lly + $core_ury) / 2.0}]

    foreach net {VDD VSS} {
        lassign [find_left_m9_ring_box \
            $net $core_llx $core_lly $core_ury] \
            ring_llx ring_lly ring_urx ring_ury

        set pg_pin_lly [expr {max($ring_lly, $pg_pin_center_y - $pg_pin_length / 2.0)}]
        set pg_pin_ury [expr {min($ring_ury, $pg_pin_center_y + $pg_pin_length / 2.0)}]
        if {$pg_pin_ury - $pg_pin_lly < 0.320} {
            error "Left M9 ring segment for $net is too short for a PG pin"
        }

        createPGPin $net -geom M9 \
            [format_pg_coord $ring_llx] [format_pg_coord $pg_pin_lly] \
            [format_pg_coord $ring_urx] [format_pg_coord $pg_pin_ury] \
            -net $net
    }
}

set CoreArea [dbGet top.fPlan.area]
set CoreSize [dbGet top.fPlan.coreBox_size]
set DieSize  [dbGet top.fPlan.box_size]
set FPx      [dbGet top.fPlan.box_sizex]
set FPy      [dbGet top.fPlan.box_sizey]

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set core_urx [dbGet top.fPlan.coreBox_urx]
set core_ury [dbGet top.fPlan.coreBox_ury]
set CoreBox  [list $core_llx $core_lly $core_urx $core_ury]

set size_report [open ./outputs/FPlanFinal.size w]
puts $size_report "Top: $TOP"
puts $size_report "Area: $CoreArea"
puts $size_report "CoreBox: $CoreBox"
puts $size_report "CoreSize_XY: $CoreSize"
puts $size_report "DieSize_XY: $DieSize"
close $size_report

set power_die_box [join [dbGet top.fPlan.box]]
if {[llength $power_die_box] != 4} {
    error "Cannot decode die box for power planning: [dbGet top.fPlan.box]"
}
lassign $power_die_box \
    power_die_llx power_die_lly power_die_urx power_die_ury

riscv_step_banner "STEP 02 DONE: PnR context ready"

