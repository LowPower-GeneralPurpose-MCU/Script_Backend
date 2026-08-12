# =============================================================================
# Step 08: extraction and signoff-oriented exports.
#
# Paste after 07_metal_fill:
#   source ./tcl/steps/08_export.tcl
# =============================================================================

riscv_step_banner "STEP 08: export"

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

