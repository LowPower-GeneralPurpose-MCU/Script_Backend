############################################################
## Finish the manually reviewed hierarchy-floorplan session
## Run inside the same Innovus session as innovus_hierFP.tcl.
############################################################

foreach d {outputs reports verify_rpt saved} {
    file mkdir $d
}

# Snap hierarchy guides only when proto_design actually created them.
if {[info exists RUN_PROTO_DESIGN] && $RUN_PROTO_DESIGN} {
    snapFPlan -guide
}

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_hierFP_final.rpt

saveFPlan ./outputs/FloorPlan.fp
saveDesign ./saved/axi_ram_hierFP.enc

puts "===================================================="
puts "HIERARCHY FLOORPLAN SAVED"
puts " - Floorplan : ./outputs/FloorPlan.fp"
puts " - Database  : ./saved/axi_ram_hierFP.enc"
if {![info exists MASTER_ONE_SHOT] || !$MASTER_ONE_SHOT} {
    puts ""
    puts "Next session:"
    puts "  innovus -stylus -files tcl/innovus_macroFP.tcl"
}
puts "===================================================="
