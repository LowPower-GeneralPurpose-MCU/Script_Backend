############################################################
## Add metal fill only after routed DRC/antenna/connectivity are clean
############################################################

if {![info exists ROUTE_VERIFY_CLEAN] || !$ROUTE_VERIFY_CLEAN} {
    error "Set ROUTE_VERIFY_CLEAN 1 only after reviewing clean post-route reports"
}

set IN_DESIGN_REPORTS_CLEAN 0
set SIGNOFF_CANDIDATE_READY 0
set DENSITY_SIGNOFF_STATUS "NOT_RUN"

assert_clean_drc_report ./verify_rpt/drc_postroute.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_postroute.rpt

# This project requires in-design fill after the strict routed-design gate.
# Set the environment override to 0 only when Pegasus owns the fill step.
set RUN_LEGACY_METAL_FILL 1
if {[info exists ::env(INNOVUS_RUN_LEGACY_METAL_FILL)]} {
    switch -nocase -- $::env(INNOVUS_RUN_LEGACY_METAL_FILL) {
        1 - true - yes - on  { set RUN_LEGACY_METAL_FILL 1 }
        0 - false - no - off { set RUN_LEGACY_METAL_FILL 0 }
        default {
            error "INNOVUS_RUN_LEGACY_METAL_FILL must be 0/1, false/true, no/yes or off/on"
        }
    }
}

if {!$RUN_LEGACY_METAL_FILL} {
    set DENSITY_SIGNOFF_STATUS "EXTERNAL_FILL_REQUIRED"
    write_skipped_report ./verify_rpt/drc_after_fill.rpt \
        "Skipped because INNOVUS_RUN_LEGACY_METAL_FILL=0. Use this override only when a separate Pegasus flow owns metal fill and density closure."
    write_skipped_report ./verify_rpt/antenna_after_fill.rpt \
        "Skipped because metal fill was not run."
    write_skipped_report ./verify_rpt/connectivity_after_fill.rpt \
        "Skipped because metal fill was not run."
    puts "Metal fill skipped because INNOVUS_RUN_LEGACY_METAL_FILL=0; a separate Pegasus fill flow must complete density closure."
} else {

# M1-M3
setMetalFill \
    -layer {M1 M2 M3} \
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

# M4
setMetalFill \
    -layer {M4} \
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

# M5 carries the only mid-stack density rule in the source tech LEF.
setMetalFill \
    -layer {M5} \
    -maxWidth 1.248 \
    -minWidth 0.096 \
    -maxLength 5.0 \
    -minLength 0.384 \
    -decrement 0.384 \
    -activeSpacing 0.192 \
    -gapSpacing 0.192 \
    -maxDensity 90 \
    -minDensity 15 \
    -preferredDensity 25

# M6-M7
setMetalFill \
    -layer {M6 M7} \
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

# M8-M9
setMetalFill \
    -layer {M8 M9} \
    -maxWidth 2.500 \
    -minWidth 0.160 \
    -maxLength 5.0 \
    -minLength 0.960 \
    -decrement 0.160 \
    -activeSpacing 0.640 \
    -gapSpacing 0.640 \
    -maxDensity 55 \
    -minDensity 25 \
    -preferredDensity 40

setMetalFill \
    -layer {Pad} \
    -maxWidth 8.0 \
    -minWidth 0.8 \
    -maxLength 8.96 \
    -minLength 8.96 \
    -decrement 0.160 \
    -activeSpacing 8.16 \
    -gapSpacing 8.16 \
    -maxDensity 80 \
    -minDensity 20 \
    -preferredDensity 25

# Keep the project-required fill command unchanged.
addMetalFill -snap -squareShape

set density_status [publish_metal_fill_density_status \
    "./${DESIGN}.metalfill.rpt" \
    ./verify_rpt/metal_density_abstract_after_fill.rpt]
set DENSITY_SIGNOFF_STATUS "PENDING_MERGED_GDS_SIGNOFF"

verify_drc \
    -report ./verify_rpt/drc_after_fill.rpt

verify_antenna_if_enabled ./verify_rpt/antenna_after_fill.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_after_fill.rpt

assert_clean_drc_report ./verify_rpt/drc_after_fill.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_after_fill.rpt

timeDesign \
    -postRoute \
    -outDir ./reports/timing_postFill

timeDesign \
    -postRoute \
    -hold \
    -outDir ./reports/timing_postFill_hold

set postfill_si_report \
    ./reports/timing_postFill/axi_ram_postRoute.SI_Glitches.rpt.gz
publish_si_glitch_report \
    $postfill_si_report \
    ./reports/si_glitch_postFill.rpt

saveDesign ./saved/axi_ram_filled.enc

if {[catch {
    assert_clean_timing_summary \
        ./reports/timing_postFill/axi_ram_postRoute.summary.gz setup 1
    assert_clean_timing_summary \
        ./reports/timing_postFill_hold/axi_ram_postRoute_hold.summary.gz hold
    assert_clean_si_glitch_report $postfill_si_report
    set IN_DESIGN_REPORTS_CLEAN 1
    set SIGNOFF_CANDIDATE_READY 1
} postfill_report_error]} {
    puts stderr "Post-fill reports are not clean: $postfill_report_error"
    puts stderr "Filled checkpoint was saved, but signoff-candidate export is blocked."
    return
}

puts "===================================================="
puts "METAL FILL ADDED"
puts "In-design DRC, connectivity, timing, DRV and SI glitch gates are clean."
puts "Density status remains $DENSITY_SIGNOFF_STATUS because SRAM internal metal"
puts "is visible only after GDS merge. Antenna status is $ANTENNA_CHECK_STATUS."
puts "Export a merged signoff candidate, then run Calibre/Pegasus density, DRC,"
puts "LVS and antenna checks."
puts ""
puts "To export the signoff candidate:"
puts "  source ./tcl/export_gds.tcl"
puts "===================================================="
}
