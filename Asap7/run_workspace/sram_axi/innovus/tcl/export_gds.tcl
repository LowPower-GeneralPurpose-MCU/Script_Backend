############################################################
## Final netlist/DEF/GDS export after filled-design verification
############################################################

if {![info exists FINAL_VERIFY_CLEAN] || !$FINAL_VERIFY_CLEAN} {
    error "Set FINAL_VERIFY_CLEAN 1 only after clean post-fill verification"
}

if {$GDS_MAP_FILE eq ""} {
    error "ASAP7_GDS_MAP_FILE is not set; refusing an unmapped GDS stream-out"
}
if {![file exists $GDS_MAP_FILE]} {
    error "Missing GDS map file: [file normalize $GDS_MAP_FILE]"
}
if {![file exists $SRAM_GDS]} {
    error "Missing SRAM GDS: [file normalize $SRAM_GDS]"
}

# Re-run final in-design checks immediately before export.
verify_drc \
    -report ./verify_rpt/drc_final.rpt

verifyProcessAntenna \
    -report ./verify_rpt/antenna_final.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_final.rpt

saveNetlist \
    ./outputs/axi_ram_pnr_lec.v \
    -excludeLeafCell \
    -removePowerGround

saveNetlist ./outputs/axi_ram_pnr_sta.v
write_sdc ./outputs/axi_ram_pnr.sdc

defOut \
    -floorplan \
    -netlist \
    -routing \
    ./outputs/axi_ram_pnr.def

streamOut ./outputs/axi_ram_pnr.gds \
    -libName WORK \
    -units $STREAMOUT_UNITS \
    -mode ALL \
    -mapFile $GDS_MAP_FILE \
    -dieAreaAsBoundary \
    -outputMacros \
    -merge [list $SRAM_GDS]

report_area   > ./verify_rpt/area_final.rpt
report_power  > ./verify_rpt/power_final.rpt
report_timing > ./verify_rpt/timing_final.rpt
report_gate   > ./verify_rpt/gate_final.rpt

saveDesign ./saved/axi_ram_final.enc

puts "===================================================="
puts "FINAL INNOVUS EXPORT COMPLETED"
puts " - GDS : ./outputs/axi_ram_pnr.gds"
puts " - DEF : ./outputs/axi_ram_pnr.def"
puts " - SDC : ./outputs/axi_ram_pnr.sdc"
puts "Run Calibre DRC/LVS/antenna with standard-cell and SRAM GDS."
puts "===================================================="
