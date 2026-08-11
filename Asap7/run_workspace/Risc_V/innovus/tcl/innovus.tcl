# =============================================================================
# Common Innovus driver for the RISC-V ASAP7 flow.
#
# Default behavior:
#   hierarchy floorplan -> power plan -> placement -> CTS -> route -> export
#
# Optional stage selection from the shell:
#   INNOVUS_STAGE=hierfp innovus -stylus -files innovus.tcl
#   INNOVUS_STAGE=pnr    innovus -stylus -files innovus.tcl
#   INNOVUS_STAGE=all    innovus -stylus -files innovus.tcl
#
# Run from any directory; the driver changes to the innovus run directory so
# that paths used by the two stage scripts remain deterministic.
# =============================================================================

set driver_file [file normalize [info script]]
set run_dir [file dirname [file dirname $driver_file]]
cd $run_dir

if {[info exists ::env(INNOVUS_STAGE)]} {
    set FLOW_STAGE [string tolower [string trim $::env(INNOVUS_STAGE)]]
} else {
    set FLOW_STAGE all
}

set valid_stages {all hierfp pnr}
if {[lsearch -exact $valid_stages $FLOW_STAGE] < 0} {
    error "Invalid INNOVUS_STAGE='$FLOW_STAGE'; use all, hierfp, or pnr."
}

puts "============================================================"
puts "RISC-V ASAP7 INNOVUS DRIVER"
puts "Run directory : $run_dir"
puts "Selected stage: $FLOW_STAGE"
puts "============================================================"

switch -- $FLOW_STAGE {
    hierfp {
        # Standalone hierarchy-floorplan session.  The stage script exits after
        # saving the checkpoint, leaving time for manual guide inspection.
        source ./tcl/innovus_hierFP.tcl
    }
    pnr {
        # Standalone PnR session.  The stage script restores the approved
        # hierarchy-floorplan checkpoint and then exits after final export.
        source ./tcl/innovus_PnR.tcl
    }
    all {
        # Both stages run in one database/session.  The flag prevents each
        # stage from exiting Innovus and tells PnR to reuse the active design
        # instead of restoring the checkpoint over it.
        set ::INNOVUS_COMBINED_FLOW 1

        if {[catch {source ./tcl/innovus_hierFP.tcl} stage_error stage_options]} {
            unset ::INNOVUS_COMBINED_FLOW
            return -options $stage_options $stage_error
        }

        puts "============================================================"
        puts "Hierarchy floorplan completed; continuing to PnR."
        puts "For manual guide review, rerun with INNOVUS_STAGE=hierfp,"
        puts "inspect/save the guides, then use INNOVUS_STAGE=pnr."
        puts "============================================================"

        if {[catch {source ./tcl/innovus_PnR.tcl} stage_error stage_options]} {
            unset ::INNOVUS_COMBINED_FLOW
            return -options $stage_options $stage_error
        }

        unset ::INNOVUS_COMBINED_FLOW
        puts "INFO: Combined hierarchy-floorplan and PnR flow completed."
        exit
    }
}
