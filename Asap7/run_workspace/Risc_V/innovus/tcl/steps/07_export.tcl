# =============================================================================
# Step 07: optional fill, extraction, and signoff-oriented exports.
#
# Paste after 06_route:
#   source ./tcl/steps/07_export.tcl
# =============================================================================

riscv_step_banner "STEP 07: export"

set RUN_LEGACY_METAL_FILL [env_flag INNOVUS_RUN_LEGACY_METAL_FILL 0]

if {$RUN_LEGACY_METAL_FILL} {
    addMetalFill -snap -squareShape

    verify_drc -report ./verify_rpt/drc_after_metal_fill.rpt
    verifyConnectivity -type all -error 1000 -warning 100 \
        -report ./verify_rpt/connectivity_after_metal_fill.rpt
    assert_clean_drc_report ./verify_rpt/drc_after_metal_fill.rpt
    assert_clean_connectivity_report ./verify_rpt/connectivity_after_metal_fill.rpt
} else {
    write_skipped_report ./verify_rpt/drc_after_metal_fill.rpt \
        "Legacy addMetalFill skipped. Set INNOVUS_RUN_LEGACY_METAL_FILL=1 only for fill experiments, or use Pegasus/signoff fill."
    write_skipped_report ./verify_rpt/connectivity_after_metal_fill.rpt \
        "Skipped because legacy metal fill was not run."
    puts "INFO: Legacy addMetalFill skipped; routed DRC/connectivity remain the signoff gate for this run."
}

foreach gds_file $GDS_MERGE {
    if {![file isfile $gds_file]} {
        error "Missing standard-cell GDS for streamOut: $gds_file"
    }
}
if {![file isfile $STREAM_MAP]} {
    error "Missing stream-out map: $STREAM_MAP"
}

extractRC
rcOut -spef ./outputs/${TOP}_pnr.spef -rc_corner rc_typ
writeTimingCon ./outputs/${TOP}_pnr.sdc

saveNetlist ./outputs/${TOP}_pnr_lec.v \
    -excludeLeafCell -removePowerGround
saveNetlist ./outputs/${TOP}_pnr_sta.v -excludeLeafCell
saveNetlist ./outputs/${TOP}_pnr_pg.v \
    -excludeLeafCell -includePowerGround -includePhysicalInst

setStreamOutMode \
    -labelAllPinShape true \
    -pinTextOrientation automatic \
    -virtualConnection false \
    -textSize 1

streamOut ./outputs/${TOP}.gds \
    -mapFile $STREAM_MAP \
    -merge $GDS_MERGE \
    -units 4000 \
    -dieAreaAsBoundary \
    -outputMacros

write_lef_abstract -noCutObs ./outputs/${TOP}.lef
defOut -floorplan -netlist -routing ./outputs/${TOP}_pnr.def

report_area   > ./reports/area_pnr.rpt
report_power  > ./reports/power_pnr.rpt
report_timing > ./reports/timing_pnr.rpt

saveDesign ./saved/${TOP}_final.enc

puts "============================================================"
puts "Innovus RISC-V PnR completed."
puts "Final checkpoint : saved/${TOP}_final.enc"
puts "GDS              : outputs/${TOP}.gds"
puts "DEF              : outputs/${TOP}_pnr.def"
puts "SPEF             : outputs/${TOP}_pnr.spef"
puts "Review verify_rpt before Calibre signoff."
puts "============================================================"

