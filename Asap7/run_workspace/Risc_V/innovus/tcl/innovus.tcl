############################################################
## RISC-V ASAP7 Innovus step-by-step master flow
##
## One-command run:
##   innovus -stylus -files tcl/innovus.tcl -log innovus -overwrite
##
## Manual paste/debug run:
##   source ./tcl/steps/00_setup.tcl
##   source ./tcl/steps/01_hierfp.tcl
##   source ./tcl/steps/02_pnr_context.tcl
##   source ./tcl/steps/03_power_pins.tcl
##   source ./tcl/steps/04_place.tcl
##   source ./tcl/steps/05_cts.tcl
##   source ./tcl/steps/06_route.tcl
##   source ./tcl/steps/07_metal_fill.tcl
##   source ./tcl/steps/08_export.tcl
##
## Useful controls:
##   INNOVUS_STAGE=all|hierfp|pnr
##   INNOVUS_STOP_AFTER_HIERFP=1
##   INNOVUS_STOP_AFTER_POWER_PINS=1
##   INNOVUS_STOP_AFTER_PLACE=1
##   INNOVUS_STOP_AFTER_CTS=1
##   INNOVUS_STOP_AFTER_ROUTE=1
##   INNOVUS_STOP_AFTER_METAL_FILL=1
############################################################

set innovus_driver_script [info script]
if {$innovus_driver_script ne ""} {
    source [file join [file dirname [file normalize $innovus_driver_script]] steps 00_setup.tcl]
} else {
    source ./tcl/steps/00_setup.tcl
}
unset -nocomplain innovus_driver_script

set valid_stages {all hierfp pnr}
if {[info exists ::env(INNOVUS_STAGE)] && $::env(INNOVUS_STAGE) ne ""} {
    set FLOW_STAGE [string tolower [string trim $::env(INNOVUS_STAGE)]]
} elseif {![info exists FLOW_STAGE] || $FLOW_STAGE eq ""} {
    set FLOW_STAGE all
}

if {[lsearch -exact $valid_stages $FLOW_STAGE] < 0} {
    error "Invalid INNOVUS_STAGE='$FLOW_STAGE'; use all, hierfp, or pnr."
}

riscv_step_banner "RISC-V ASAP7 INNOVUS MASTER FLOW: $FLOW_STAGE"

set run_hierfp [expr {$FLOW_STAGE eq "all" || $FLOW_STAGE eq "hierfp"}]
set run_pnr    [expr {$FLOW_STAGE eq "all" || $FLOW_STAGE eq "pnr"}]

if {$run_hierfp} {
    source ./tcl/steps/01_hierfp.tcl
}

if {$run_hierfp && ($FLOW_STAGE eq "hierfp" ||
    [riscv_env_flag INNOVUS_STOP_AFTER_HIERFP 0])} {
    puts "FLOW STOPPED AFTER HIERARCHY FLOORPLAN"
    puts "Continue manually with:"
    puts "  source ./tcl/steps/02_pnr_context.tcl"
    puts "  source ./tcl/steps/03_power_pins.tcl"
    puts "  source ./tcl/steps/04_place.tcl"
    puts "  source ./tcl/steps/05_cts.tcl"
    puts "  source ./tcl/steps/06_route.tcl"
    puts "  source ./tcl/steps/07_metal_fill.tcl"
    puts "  source ./tcl/steps/08_export.tcl"
    return
}

if {$run_pnr} {
    source ./tcl/steps/02_pnr_context.tcl
    source ./tcl/steps/03_power_pins.tcl
    if {[riscv_env_flag INNOVUS_STOP_AFTER_POWER_PINS 0]} { return }

    source ./tcl/steps/04_place.tcl
    if {[riscv_env_flag INNOVUS_STOP_AFTER_PLACE 0]} { return }

    source ./tcl/steps/05_cts.tcl
    if {[riscv_env_flag INNOVUS_STOP_AFTER_CTS 0]} { return }

    source ./tcl/steps/06_route.tcl
    if {[riscv_env_flag INNOVUS_STOP_AFTER_ROUTE 0]} { return }

    source ./tcl/steps/07_metal_fill.tcl
    if {[riscv_env_flag INNOVUS_STOP_AFTER_METAL_FILL 0]} { return }

    source ./tcl/steps/08_export.tcl
}

unset -nocomplain ::INNOVUS_COMBINED_FLOW
riscv_step_banner "RISC-V ASAP7 Innovus flow reached its requested stop point"
