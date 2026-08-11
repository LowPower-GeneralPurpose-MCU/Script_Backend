# =============================================================================
# Stage 1: create and save the hierarchy-aware RISC-V floorplan.
# Teacher flow: timeDesign -proto -> set_proto_design_mode -> proto_design.
# Run from: Asap7/run_workspace/Risc_V/innovus
# =============================================================================

source ./tcl/tool_setup.tcl

set init_design_uniquify 1
source ./tcl/innovus.globals

# ASAP7 provides explicit/generated via rules; keep automatic via generation
# disabled, matching the working teacher/multiplier flow.
setGenerateViaMode -auto false
init_design

if {[sizeof_collection [all_clocks]] == 0} {
    error "No clock was created. Check clk in $FUNC_SDC."
}

set design_name [dbGet top.name]
if {$design_name ne $TOP} {
    error "Loaded top '$design_name', expected '$TOP'."
}

floorPlan -r $CORE_ASPECT $CORE_UTIL \
    $CORE_MARGIN $CORE_MARGIN $CORE_MARGIN $CORE_MARGIN

set CoreArea [dbGet top.fPlan.area]
set CoreSize [dbGet top.fPlan.coreBox_size]
set DieSize  [dbGet top.fPlan.box_size]

puts "============================================================"
puts "INITIAL RISC-V FLOORPLAN"
puts "Core utilization target : $CORE_UTIL"
puts "Core size                : $CoreSize um"
puts "Die size                 : $DieSize um"
puts "Floorplan area           : $CoreArea um^2"
puts "============================================================"

# Generate timing/congestion-aware hierarchy guides from the module boundaries
# preserved by Genus.  The guides may be manually adjusted in the GUI before
# executing the save commands again.
timeDesign -proto -prePlace
set_proto_design_mode -timing_aware true -congestion_aware true
proto_design

snapFPlan -guide
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP.rpt
saveFPlan ./outputs/${TOP}_hierFP.fp
saveDesign ./saved/${TOP}_hierFP.enc

report_area   > ./reports/area_hierFP.rpt
report_timing > ./reports/timing_hierFP.rpt

puts "============================================================"
puts "Hierarchy floorplan saved."
puts "Checkpoint : saved/${TOP}_hierFP.enc"
puts "Floorplan  : outputs/${TOP}_hierFP.fp"
puts "Inspect every guide: target density < 80%, preferably ~75%."
puts "Then run the PnR stage."
puts "============================================================"

# When this stage is sourced by innovus.tcl, reaching EOF returns control to the
# common driver so that PnR can continue in the same Innovus session.  When the
# stage is launched directly, keep the original behavior and terminate Innovus.
if {![info exists ::INNOVUS_COMBINED_FLOW] || !$::INNOVUS_COMBINED_FLOW} {
    exit
}
