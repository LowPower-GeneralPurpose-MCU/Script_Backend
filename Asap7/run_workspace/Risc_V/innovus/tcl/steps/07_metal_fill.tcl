# =============================================================================
# Step 07: metal fill and post-fill checks.
#
# Paste after 06_route:
#   source ./tcl/steps/07_metal_fill.tcl
#
# Default: configure ASAP7-compatible legacy Innovus fill rules and run
# addMetalFill.  If the educational ASAP7 LEF reports fill DRCs in your setup,
# rerun with:
#   set ::env(INNOVUS_RUN_LEGACY_METAL_FILL) 0
#
# Pad fill is intentionally disabled by default.  Enable it only when the
# signoff deck requires Pad density:
#   set ::env(INNOVUS_RUN_PAD_FILL) 1
# =============================================================================

riscv_step_banner "STEP 07: metal fill"

set RUN_LEGACY_METAL_FILL [env_flag INNOVUS_RUN_LEGACY_METAL_FILL 1]
set RUN_PAD_METAL_FILL    [env_flag INNOVUS_RUN_PAD_FILL 0]

file delete -force \
    ./verify_rpt/drc_after_metal_fill.rpt \
    ./verify_rpt/connectivity_after_metal_fill.rpt

if {$RUN_LEGACY_METAL_FILL} {
    puts "INFO: Configuring ASAP7 legacy metal-fill rules."

    if {[llength [info commands deleteMetalFill]]} {
        catch {deleteMetalFill -all}
    }

    # M1-M3: width table starts at 0.072um.
    setMetalFill -layer { M1 M2 M3 } \
        -maxWidth 0.936 \
        -minWidth 0.072 \
        -maxLength 5.0 \
        -minLength 0.148 \
        -decrement 0.288 \
        -activeSpacing 0.144 \
        -gapSpacing 0.144 \
        -maxDensity 60 \
        -minDensity 25 \
        -preferredDensity 40

    # M4-M5: width table starts at 0.096um.
    setMetalFill -layer { M4 M5 } \
        -maxWidth 1.248 \
        -minWidth 0.096 \
        -maxLength 5.0 \
        -minLength 0.384 \
        -decrement 0.384 \
        -activeSpacing 0.192 \
        -gapSpacing 0.192 \
        -maxDensity 35 \
        -minDensity 10 \
        -preferredDensity 25

    # M6-M7: keep fill away from the PG mesh with the wider spacing.
    setMetalFill -layer { M6 M7 } \
        -maxWidth 1.664 \
        -minWidth 0.128 \
        -maxLength 5.0 \
        -minLength 0.512 \
        -decrement 0.512 \
        -activeSpacing 0.300 \
        -gapSpacing 0.300 \
        -maxDensity 55 \
        -minDensity 25 \
        -preferredDensity 40

    # M8-M9: use min-width-only fill first; widen only if density is still low.
    setMetalFill -layer { M8 M9 } \
        -maxWidth 0.160 \
        -minWidth 0.160 \
        -maxLength 5.0 \
        -minLength 0.960 \
        -activeSpacing 0.320 \
        -gapSpacing 0.320 \
        -maxDensity 55 \
        -minDensity 25 \
        -preferredDensity 40

    if {$RUN_PAD_METAL_FILL} {
        puts "INFO: Pad metal fill enabled by INNOVUS_RUN_PAD_FILL=1."

        setMetalFill -layer { Pad } \
            -maxWidth 8.0 \
            -minWidth 0.8 \
            -maxLength 8.96 \
            -minLength 8.96 \
            -decrement 0.160 \
            -activeSpacing 8.16 \
            -gapSpacing 8.16 \
            -maxDensity 30 \
            -minDensity 10 \
            -preferredDensity 25
    } else {
        puts "INFO: Pad metal fill disabled. Set INNOVUS_RUN_PAD_FILL=1 only if Pad density is required."
    }

    addMetalFill -snap -squareShape

    verify_drc -report ./verify_rpt/drc_after_metal_fill.rpt
    verifyConnectivity -type all -error 1000 -warning 50 \
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
