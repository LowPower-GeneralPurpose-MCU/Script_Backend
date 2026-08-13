############################################################
## Innovus macro-floorplan session
## Based on x_Hierarchy Layout.pdf, pages 31-36
##
## Prerequisite:
##   ./outputs/FloorPlan.fp from finish_hierFP.tcl
############################################################

set USER $::env(USER)
if {[catch {file delete -force /tmp/$USER/innovus_macrofp}]} {}
set auto_file_dir "/tmp/$USER/innovus_macrofp"

foreach d {outputs reports verify_rpt saved} {
    file mkdir $d
}

set init_design_uniquify 1
source ./tcl/innovus.globals
init_design

setDesignMode -process 7

set HIER_FP_FILE "./outputs/FloorPlan.fp"
if {![file exists $HIER_FP_FILE]} {
    error "Missing hierarchy floorplan: [file normalize $HIER_FP_FILE]"
}

loadFPlan $HIER_FP_FILE

# Put in the SRAMs only after the reviewed hierarchy floorplan is loaded.
# This stage creates the physical group/fence and packs all sixteen macros
# into the verified 4x4 island.
set SRAM_AUTO_PACK_4X4 1
source ./tcl/sram_macro_floorplan.tcl

saveDesign ./saved/axi_ram_macroFP_review.enc

puts "===================================================="
puts "MACRO FLOORPLAN READY FOR MANUAL REVIEW"
puts " - Input  : $HIER_FP_FILE"
puts " - Review DB: ./saved/axi_ram_macroFP_review.enc"
puts " - Deterministic map: ./reports/sram_macro_deterministic_map.rpt"
puts ""
puts "After reviewing connectivity, orientation, gaps and notches:"
puts "  source ./tcl/finish_macroFP.tcl"
puts "===================================================="
