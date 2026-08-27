############################################################
## Merged-GDS signoff-candidate export after filled-design verification
############################################################

if {![info exists SIGNOFF_CANDIDATE_READY] || !$SIGNOFF_CANDIDATE_READY} {
    error "SIGNOFF_CANDIDATE_READY is false; clean post-fill DRC, connectivity, timing and real DRVs first"
}
if {![info exists DENSITY_SIGNOFF_STATUS]} {
    set DENSITY_SIGNOFF_STATUS "PENDING_MERGED_GDS_SIGNOFF"
}
if {![info exists ANTENNA_CHECK_STATUS]} {
    set ANTENNA_CHECK_STATUS "UNKNOWN_RECHECK_REQUIRED"
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

set merge_gds_files [concat $STDCELL_GDS_FILES [list $SRAM_GDS]]
foreach merge_gds $merge_gds_files {
    if {![file exists $merge_gds]} {
        error "Missing GDS required for merged stream-out: [file normalize $merge_gds]"
    }
}

# streamOut -merge drops any master whose exact name is absent from the merge
# files and reports it only as IMPOGDS-217/218, which does not stop the run.
# Verify every hard-macro master up front so a hollow GDS can never be handed
# off as a signoff candidate.
assert_merge_gds_masters $merge_gds_files

# Re-run final in-design checks immediately before export.
verify_drc \
    -report ./verify_rpt/drc_final.rpt

verify_antenna_if_enabled ./verify_rpt/antenna_final.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_final.rpt

assert_clean_drc_report ./verify_rpt/drc_final.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_final.rpt
assert_si_glitch_policy \
    ./reports/timing_postFill/axi_ram_postRoute.SI_Glitches.rpt.gz \
    pre-export

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
    -merge $merge_gds_files

report_area   > ./verify_rpt/area_final.rpt
report_power  > ./verify_rpt/power_final.rpt
report_timing > ./verify_rpt/timing_final.rpt
report_gate   > ./verify_rpt/gate_final.rpt

set handoff_file ./verify_rpt/signoff_handoff.rpt
set fp [open $handoff_file w]
puts $fp "# ASAP7 AXI SRAM signoff handoff"
puts $fp "# Status: SIGNOFF_CANDIDATE_EXPORTED"
puts $fp "# This status does not mean density, antenna, DRC or LVS signoff clean."
puts $fp "# In-design DRC/connectivity/timing/real-DRV: CLEAN"
puts $fp "# SI: $SI_GATE_STATUS"
puts $fp "# Innovus antenna: $ANTENNA_CHECK_STATUS"
puts $fp "# Density: $DENSITY_SIGNOFF_STATUS"
puts $fp "# Top-level GDS: [file normalize ./outputs/axi_ram_pnr.gds]"
puts $fp "# Stream-out map: [file normalize $GDS_MAP_FILE]"
puts $fp "# Merged libraries:"
foreach merge_gds $merge_gds_files {
    puts $fp "#   [file normalize $merge_gds]"
}
puts $fp "# Required next checks on merged GDS: density, DRC, LVS and antenna."
close $fp

saveDesign ./saved/axi_ram_signoff_candidate.enc

puts "===================================================="
puts "SIGNOFF-CANDIDATE EXPORT COMPLETED"
puts " - GDS : ./outputs/axi_ram_pnr.gds"
puts " - DEF : ./outputs/axi_ram_pnr.def"
puts " - SDC : ./outputs/axi_ram_pnr.sdc"
puts " - Status: ./verify_rpt/signoff_handoff.rpt"
puts "Run Calibre/Pegasus density, DRC, LVS and antenna on the merged GDS."
puts "===================================================="
