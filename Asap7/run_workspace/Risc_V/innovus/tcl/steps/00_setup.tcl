# =============================================================================
# Step 00: common run-directory setup.
#
# Paste first in a fresh Innovus session:
#   source ./tcl/steps/00_setup.tcl
# =============================================================================

set MASTER_ONE_SHOT 1
set enc_source_continue_on_error false

proc riscv_env_flag {name default_value} {
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

proc riscv_resolve_run_dir {} {
    set step_script [info script]
    if {$step_script ne ""} {
        return [file dirname [file dirname [file dirname [file normalize $step_script]]]]
    }

    set paste_cwd [file normalize [pwd]]
    if {[file exists [file join $paste_cwd tcl innovus.tcl]]} {
        return $paste_cwd
    }
    if {[file tail $paste_cwd] eq "tcl" &&
        [file exists [file join [file dirname $paste_cwd] tcl innovus.tcl]]} {
        return [file dirname $paste_cwd]
    }

    error "Cannot find the RISC-V Innovus run directory. cd to Asap7/run_workspace/Risc_V/innovus first."
}

proc riscv_step_banner {title} {
    puts "============================================================"
    puts $title
    puts "============================================================"
}

set run_dir [riscv_resolve_run_dir]
cd $run_dir

foreach out_dir {outputs reports verify_rpt saved logs} {
    file mkdir $out_dir
}

set ::INNOVUS_KEEP_OPEN 1

riscv_step_banner "STEP 00 DONE: run directory is [file normalize [pwd]]"

