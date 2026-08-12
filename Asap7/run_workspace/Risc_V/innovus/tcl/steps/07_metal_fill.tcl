# =============================================================================
# Step 07: metal fill and post-fill checks.
#
# Paste after 06_route:
#   source ./tcl/steps/07_metal_fill.tcl
#
# Default: run legacy Innovus addMetalFill because this is the explicit fill
# checkpoint.  If the educational ASAP7 LEF reports fill DRCs in your setup,
# rerun with:
#   set ::env(INNOVUS_RUN_LEGACY_METAL_FILL) 0
# =============================================================================

riscv_step_banner "STEP 07: metal fill"

set RUN_LEGACY_METAL_FILL [env_flag INNOVUS_RUN_LEGACY_METAL_FILL 1]

file delete -force \
    ./verify_rpt/drc_after_metal_fill.rpt \
    ./verify_rpt/connectivity_after_metal_fill.rpt

if {$RUN_LEGACY_METAL_FILL} {
    addMetalFill -snap -squareShape

    verify_drc -report ./verify_rpt/drc_after_metal_fill.rpt
    verifyConnectivity -type all -error 1000 -warning 100 \
        -report ./verify_rpt/connectivity_after_metal_fill.rpt
    assert_clean_drc_report ./verify_rpt/drc_after_metal_fill.rpt
    assert_clean_connectivity_report ./verify_rpt/connectivity_after_metal_fill.rpt

    report_area  > ./reports/area_metal_fill.rpt
    report_power > ./reports/power_metal_fill.rpt
    saveDesign ./saved/${TOP}_metalFill.enc

    riscv_step_banner "STEP 07 DONE: saved/${TOP}_metalFill.enc"
} else {
    write_skipped_report ./verify_rpt/drc_after_metal_fill.rpt \
        "Legacy addMetalFill skipped by INNOVUS_RUN_LEGACY_METAL_FILL=0. Use Pegasus/signoff fill for production signoff."
    write_skipped_report ./verify_rpt/connectivity_after_metal_fill.rpt \
        "Skipped because legacy metal fill was not run."

    puts "INFO: Legacy addMetalFill skipped by INNOVUS_RUN_LEGACY_METAL_FILL=0."
    riscv_step_banner "STEP 07 SKIPPED: metal fill was not run"
}

