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

# init_design, CPU, PG net, derate SRAM, kiem clock, dont_touch TRNG RO.
source ./tcl/init_common.tcl

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
