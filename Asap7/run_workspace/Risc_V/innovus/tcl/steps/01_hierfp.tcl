# =============================================================================
# Step 01: initialize design and save hierarchy floorplan.
#
# Paste after 00_setup:
#   source ./tcl/steps/01_hierfp.tcl
# =============================================================================

if {![info exists ::INNOVUS_KEEP_OPEN]} {
    set ::INNOVUS_KEEP_OPEN 1
}
set ::INNOVUS_COMBINED_FLOW 1

riscv_step_banner "STEP 01: hierarchy floorplan"
source ./tcl/innovus_hierFP.tcl
riscv_step_banner "STEP 01 DONE: saved/${TOP}_hierFP.enc"

