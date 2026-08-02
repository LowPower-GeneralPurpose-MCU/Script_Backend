# =============================================================================
# Stage 2: use/restore the approved hierarchy floorplan and run RISC-V PnR.
# Run from: Asap7/run_workspace/Risc_V/innovus
# =============================================================================

set reuse_active_design [expr {
    [info exists ::INNOVUS_COMBINED_FLOW] && $::INNOVUS_COMBINED_FLOW
}]

if {$reuse_active_design} {
    # innovus_hierFP.tcl has just completed in this session.  Do not call
    # restoreDesign over the active database; continue from its validated and
    # saved hierarchy floorplan directly.
    if {![info exists TOP]} {
        error "Combined flow lost TOP configuration before the PnR stage."
    }
    set active_top [dbGet top.name]
    if {$active_top ne $TOP} {
        error "Active top '$active_top', expected '$TOP' before PnR."
    }
    puts "INFO: Continuing PnR from active hierarchy floorplan for $TOP."
} else {
    # Standalone PnR session: load common setup and restore the floorplan that
    # was reviewed/saved by the hierarchy-floorplan session.
    source ./tcl/tool_setup.tcl

    set HIER_CHECKPOINT ./saved/${TOP}_hierFP.enc
    if {![file isfile $HIER_CHECKPOINT]} {
        error "Missing $HIER_CHECKPOINT. Run innovus_hierFP.tcl first."
    }

    restoreDesign $HIER_CHECKPOINT $TOP
}

setMultiColorsHier

set_interactive_constraint_modes [all_constraint_modes]
if {[sizeof_collection [all_clocks]] == 0} {
    error "No functional clock is active after restoreDesign."
}

# Keep clock ideal through placement/pre-CTS.  It is changed to propagated only
# after ccopt_design.

# ----------------------------------------------------------------------------
# Floorplan information
# ----------------------------------------------------------------------------
set CoreArea [dbGet top.fPlan.area]
set CoreSize [dbGet top.fPlan.coreBox_size]
set DieSize  [dbGet top.fPlan.box_size]
set FPx      [dbGet top.fPlan.box_sizex]
set FPy      [dbGet top.fPlan.box_sizey]
set CoreBox  [dbGet top.fPlan.coreBox]

set core_llx [lindex $CoreBox 0]
set core_lly [lindex $CoreBox 1]
set core_urx [lindex $CoreBox 2]
set core_ury [lindex $CoreBox 3]

set size_report [open ./outputs/FPlanFinal.size w]
puts $size_report "Top: $TOP"
puts $size_report "Area: $CoreArea"
puts $size_report "CoreBox: $CoreBox"
puts $size_report "CoreSize_XY: $CoreSize"
puts $size_report "DieSize_XY: $DieSize"
close $size_report

# ----------------------------------------------------------------------------
# Power planning
# Layer use follows preferred directions in the ASAP7 4x tech LEF:
#   M4 horizontal, M5 vertical, M6 horizontal, M7 vertical,
#   M8 horizontal ring sides, M9 vertical ring sides.
# ----------------------------------------------------------------------------
setAddStripeMode -trim_antenna_back_to_shape core_ring
setAddStripeMode -split_vias true
setAddStripeMode -via_using_exact_crossover_size false

clearGlobalNets
deleteAllPowerPreroutes

globalNetConnect VDD -type pgpin -pin VDD -inst * -module {}
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {}
globalNetConnect VDD -type tiehi -inst * -module {}
globalNetConnect VSS -type tielo -inst * -module {}
applyGlobalNets

addRing -nets {VDD VSS} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $RING_WIDTH \
    -spacing $RING_SPACING \
    -offset $RING_OFFSET

# Add explicit top-level VDD/VSS pins at the lower-left ring corner.  Coordinates
# use the actual snapped core box rather than assuming floorPlan kept the nominal
# margin unchanged.
set vdd_m9_right [expr {$core_llx - $RING_OFFSET}]
set vdd_m9_left  [expr {$vdd_m9_right - $RING_WIDTH}]
set vss_m9_right [expr {$vdd_m9_left - $RING_SPACING}]
set vss_m9_left  [expr {$vss_m9_right - $RING_WIDTH}]

set vdd_m8_top    [expr {$core_lly - $RING_OFFSET}]
set vdd_m8_bottom [expr {$vdd_m8_top - $RING_WIDTH}]
set vss_m8_top    [expr {$vdd_m8_bottom - $RING_SPACING}]
set vss_m8_bottom [expr {$vss_m8_top - $RING_WIDTH}]

createPGPin VDD -geom M9 \
    $vdd_m9_left $vdd_m8_bottom $vdd_m9_right $vdd_m8_top -net VDD
createPGPin VSS -geom M9 \
    $vss_m9_left $vss_m8_bottom $vss_m9_right $vss_m8_top -net VSS

# Upper PG mesh: M7 vertical into M8 ring, M6 horizontal into M7.
setAddStripeMode -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} \
    -layer M7 -direction vertical \
    -width $M67_WIDTH -spacing $M67_SPACING \
    -set_to_set_distance $M67_SET_PITCH \
    -start_from left -start_offset $M67_OFFSET \
    -snap_wire_center_to_grid grid

setAddStripeMode -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} \
    -layer M6 -direction horizontal \
    -width $M67_WIDTH -spacing $M67_SPACING \
    -set_to_set_distance $M67_SET_PITCH \
    -start_from bottom -start_offset $M67_OFFSET \
    -snap_wire_center_to_grid grid

# Mid-level mesh: legal WIDTHTABLE width 0.480 um on M4/M5.
setAddStripeMode -stacked_via_bottom_layer M5 -stacked_via_top_layer M6
addStripe -nets {VDD VSS} \
    -layer M5 -direction vertical \
    -width $M45_WIDTH -spacing $M45_SPACING \
    -set_to_set_distance $M45_SET_PITCH \
    -start_from left -start_offset $M45_OFFSET \
    -snap_wire_center_to_grid grid

setAddStripeMode -stacked_via_bottom_layer M1 -stacked_via_top_layer M5
addStripe -nets {VDD VSS} \
    -layer M4 -direction horizontal \
    -width $M45_WIDTH -spacing $M45_SPACING \
    -set_to_set_distance $M45_SET_PITCH \
    -start_from bottom -start_offset $M45_OFFSET \
    -snap_wire_center_to_grid grid

# Project requirement: do not permit special-route jogging or layer changes.
setSrouteMode -viaConnectToShape {ring stripe}
sroute -nets {VDD VSS} \
    -connect {corePin} \
    -corePinTarget {stripe} \
    -allowJogging 0 \
    -allowLayerChange 0

editTrim -nets {VDD VSS}
clearDrc

verifyConnectivity -type all -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_pg.rpt
verify_drc -report ./verify_rpt/drc_after_pg.rpt

# Assign every top port after PG shapes exist, allowing editPin to avoid overlap.
setPinConstraint -corner_to_pin_distance 8
source ./tcl/pins.tcl

saveDesign ./saved/${TOP}_powerplan.enc

# ----------------------------------------------------------------------------
# Standard-cell placement
# ----------------------------------------------------------------------------
setDelayCalMode -SIAware false -equivalent_waveform_model none
setHierMode -optStage preCTS

setPlaceMode -reset
setPlaceMode \
    -place_global_uniform_density true \
    -place_global_module_aware_spare true \
    -place_global_auto_blockage_in_channel soft \
    -place_detail_preroute_as_obs {2 3} \
    -place_global_cong_effort high \
    -place_design_refine_macro false

place_design
refinePlace

checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_postPlace.rpt
report_timing > ./reports/timing_postPlace.rpt
report_area   > ./reports/area_postPlace.rpt
saveDesign ./saved/${TOP}_postPlace.enc

# ----------------------------------------------------------------------------
# Pre-CTS optimization and clock-tree synthesis
# ----------------------------------------------------------------------------
create_route_type -name leaf_rule \
    -bottom_preferred_layer M2 -top_preferred_layer M3
create_route_type -name trunk_rule \
    -shield_net VSS -bottom_preferred_layer M4 -top_preferred_layer M5
create_route_type -name top_rule \
    -shield_net VSS -bottom_preferred_layer M6 -top_preferred_layer M7

set_ccopt_property -net_type leaf  route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top   route_type top_rule
set_ccopt_property routing_top_min_fanout 100
# Explicit suffix prevents a 1000x mistake if the session time unit changes.
set_ccopt_property target_max_trans 0.300ns
set_ccopt_property buffer_cells $CTS_BUF_CELLS
set_ccopt_property inverter_cells $CTS_INV_CELLS
set_ccopt_property use_inverters auto

setOptMode -reclaimArea true -leakageToDynamicRatio 0.5 \
    -powerEffort high -fixFanoutLoad true

optDesign -prefix preCTS -preCTS
report_timing > ./reports/timing_preCTS.rpt

create_ccopt_clock_tree_spec -filename ./outputs/ccopt.spec
source ./outputs/ccopt.spec
ccopt_design -prefix postCTS

set_propagated_clock [all_clocks]
setHierMode -optStage postCTS
optDesign -prefix postCTS -postCTS -setup -hold

report_timing > ./reports/timing_postCTS.rpt
report_area   > ./reports/area_postCTS.rpt
saveDesign ./saved/${TOP}_postCTS.enc

# Teacher flow places filler cells before detailed routing.
setFillerMode -core $FILLER_CELLS \
    -preserveUserOrder true \
    -honorPrerouteAsObs true \
    -diffCellViol true
addFiller

# ----------------------------------------------------------------------------
# Signal routing and post-route closure
# ----------------------------------------------------------------------------
setNanoRouteMode -reset
setNanoRouteMode -quiet \
    -route_strict_honor_route_rule true \
    -route_strictly_honor_1d_routing true \
    -route_detail_no_taper_in_layers "1:9" \
    -route_detail_no_taper_on_output_pin true \
    -route_use_auto_via false \
    -route_with_via_only_for_stdcell_pin true \
    -route_detail_use_multi_cut_via_effort low \
    -route_with_timing_driven true \
    -route_with_si_driven true \
    -route_detail_fix_antenna true \
    -route_detail_merge_abutting_cut true \
    -route_detail_end_iteration 5

routeDesign -globalDetail
routeDesign -viaOpt -wireOpt -trackOpt
ecoRoute -fix_drc

verify_drc -report ./verify_rpt/drc_after_route.rpt
verifyConnectivity -type all -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_route.rpt
verifyProcessAntenna > ./verify_rpt/antenna_after_route.rpt

setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -SIAware true -equivalent_waveform_model propagation
setExtractRCMode -engine postRoute -effortLevel medium

optDesign -prefix postRoute -postRoute -setup -hold
optDesign -prefix postRouteDRV -postRoute -drv
ecoRoute -fix_drc

report_timing > ./reports/timing_postRoute.rpt
report_area   > ./reports/area_postRoute.rpt
report_power  > ./reports/power_postRoute.rpt
saveDesign ./saved/${TOP}_postRoute.enc

verify_drc -report ./verify_rpt/drc_postRoute_final.rpt
verifyConnectivity -type all -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_postRoute_final.rpt
verifyProcessAntenna > ./verify_rpt/antenna_postRoute_final.rpt

# ASAP7 fill is driven by the loaded technology rules.  Keep the exact teacher
# command instead of inventing density targets that conflict with the tech LEF.
addMetalFill -snap -squareShape

verify_drc -report ./verify_rpt/drc_after_metal_fill.rpt
verifyConnectivity -type all -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_metal_fill.rpt

# ----------------------------------------------------------------------------
# Signoff-oriented outputs
# ----------------------------------------------------------------------------
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

if {!$reuse_active_design} {
    exit
}
