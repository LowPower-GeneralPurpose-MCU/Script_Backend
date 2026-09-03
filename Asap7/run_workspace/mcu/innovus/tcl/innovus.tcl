############################################################
## Innovus initialization and reviewed macro-floorplan checkpoint
##
## Canonical launch point:
##   cd Asap7/run_workspace/mcu/innovus
##   innovus -files tcl/innovus.tcl
############################################################

set INNOVUS_TCL_DIR [file dirname [file normalize [info script]]]
set INNOVUS_DIR [file dirname $INNOVUS_TCL_DIR]
cd $INNOVUS_DIR

foreach dir {outputs reports verify_rpt saved logs} {
    file mkdir $dir
}

source ./preflight.tcl
source ./tcl/innovus.globals

set init_design_uniquify 1
init_design
setDesignMode -process 7
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7

globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose

set_interactive_constraint_modes [all_constraint_modes]
if {[sizeof_collection [all_clocks]] < 18} {
    error "Incomplete multi-clock SDC handoff; fewer than 18 clocks are active"
}
set_interactive_constraint_modes {}

source ./tcl/macro_floorplan.tcl

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_floorplan.rpt
report_clocks > ./reports/clocks_floorplan.rpt
report_analysis_views > ./reports/analysis_views.rpt

set FLOORPLAN_DB [file join $INNOVUS_DIR saved \
    [format "%s_floorplan.enc" $TOP]]
saveDesign $FLOORPLAN_DB

puts "============================================================"
puts "INNOVUS MCU PREPARATION CHECKPOINT COMPLETED"
puts " - Database : [file normalize $FLOORPLAN_DB]"
puts " - Macro map: [file normalize ./reports/sram_macro_map.rpt]"
puts "Review macro connectivity, pin access, congestion and PG strategy"
puts "before placement/CTS/route."
puts "============================================================"
