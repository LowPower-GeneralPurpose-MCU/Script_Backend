############################################################
## RISC-V ASAP7 Innovus master flow
##
## Sequence:
##   setup -> hierarchy floorplan -> PG/pins -> placement
##   -> CTS -> route -> clean checks -> export
##
## Run from the RISC-V innovus directory:
##   innovus -stylus -files tcl/innovus.tcl -log innovus -overwrite
##
## Interactive paste/debug:
##   1. cd to Asap7/run_workspace/Risc_V/innovus
##   2. paste this file from the top, or paste one complete section at a time
##
## Useful controls:
##   INNOVUS_STAGE=all|hierfp|pnr
##   INNOVUS_STOP_AFTER_HIERFP=1
##   INNOVUS_STOP_AFTER_POWER_PINS=1
##   INNOVUS_STOP_AFTER_PLACE=1
##   INNOVUS_STOP_AFTER_CTS=1
##   INNOVUS_STOP_AFTER_ROUTE=1
############################################################

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
    set driver_script [info script]
    if {$driver_script ne ""} {
        return [file dirname [file dirname [file normalize $driver_script]]]
    }

    # Interactive paste mode: [info script] is empty.  Start Innovus from the
    # run directory, or from its tcl subdirectory, before pasting.
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

set run_dir [riscv_resolve_run_dir]
cd $run_dir

foreach out_dir {outputs reports verify_rpt saved logs} {
    file mkdir $out_dir
}

set valid_stages {all hierfp pnr}
if {[info exists ::env(INNOVUS_STAGE)] && $::env(INNOVUS_STAGE) ne ""} {
    set FLOW_STAGE [string tolower [string trim $::env(INNOVUS_STAGE)]]
} elseif {![info exists FLOW_STAGE] || $FLOW_STAGE eq ""} {
    set FLOW_STAGE all
}

if {[lsearch -exact $valid_stages $FLOW_STAGE] < 0} {
    error "Invalid INNOVUS_STAGE='$FLOW_STAGE'; use all, hierfp, or pnr."
}

set STOP_AFTER_HIERFP [riscv_env_flag INNOVUS_STOP_AFTER_HIERFP 0]

puts "============================================================"
puts "RISC-V ASAP7 INNOVUS MASTER FLOW"
puts "Run directory : $run_dir"
puts "Selected stage: $FLOW_STAGE"
puts "============================================================"

# Keep Innovus open after sourced stage scripts, matching the SRAM master flow.
set ::INNOVUS_KEEP_OPEN 1

# ------------------------------------------------------------------------
# 1. HIERARCHY FLOORPLAN
# ------------------------------------------------------------------------

set run_hierfp [expr {$FLOW_STAGE eq "all" || $FLOW_STAGE eq "hierfp"}]
set run_pnr    [expr {$FLOW_STAGE eq "all" || $FLOW_STAGE eq "pnr"}]

if {$run_hierfp} {
    set ::INNOVUS_COMBINED_FLOW 1

    if {[catch {source ./tcl/innovus_hierFP.tcl} stage_error stage_options]} {
        unset -nocomplain ::INNOVUS_COMBINED_FLOW
        puts stderr $stage_error
        error $stage_error
    }
}

if {$run_hierfp && ($FLOW_STAGE eq "hierfp" || $STOP_AFTER_HIERFP)} {
    unset -nocomplain ::INNOVUS_COMBINED_FLOW
    puts "============================================================"
    puts "FLOW STOPPED AFTER HIERARCHY FLOORPLAN"
    puts "Inspect:"
    puts " - saved/riscv_pipeline_hierFP.enc"
    puts " - outputs/riscv_pipeline_hierFP.fp"
    puts "Continue manually with:"
    puts " - set ::INNOVUS_COMBINED_FLOW 1"
    puts " - source ./tcl/innovus_PnR.tcl"
    puts "============================================================"
} elseif {$run_pnr} {
    if {$FLOW_STAGE eq "all"} {
        set ::INNOVUS_COMBINED_FLOW 1
        puts "============================================================"
        puts "Hierarchy floorplan completed; continuing to PnR."
        puts "============================================================"
    } else {
        unset -nocomplain ::INNOVUS_COMBINED_FLOW
    }

    # --------------------------------------------------------------------
    # 2. PNR, CHECKS, AND EXPORT
    # --------------------------------------------------------------------

    if {[catch {source ./tcl/innovus_PnR.tcl} stage_error stage_options]} {
        unset -nocomplain ::INNOVUS_COMBINED_FLOW
        puts stderr $stage_error
        error $stage_error
    }
}

unset -nocomplain ::INNOVUS_COMBINED_FLOW

puts "============================================================"
puts "RISC-V ASAP7 Innovus master flow reached its requested stop point."
puts "Review reports in ./verify_rpt before treating the layout as clean."
puts "============================================================"
