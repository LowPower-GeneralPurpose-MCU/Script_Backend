###################################
## Prepare environment
###################################
set USER $::env(USER)
if {[catch {file delete -force /tmp/$USER/innovus}]} {}
set auto_file_dir "/tmp/$USER/innovus"

# Load design
set init_design_uniquify 1
source tcl/innovus.globals
setGenerateViaMode -auto false

#setPreference DesignPrecision 10000
init_design

# Propagate clocks
set_interactive_constraint_modes [all_constraint_modes]
set_propagated_clock [all_clocks]

# Setup multi-thread
if {![catch {open "/proc/cpuinfo"} f]} {
    set CORES [regexp -all -line {^processor\s} [read $f]]
    if {$CORES > 24} { set CORES 24 }
    close $f 
}
setDesignMode -process 7
setMultiCpuUsage -acquireLicense $CORES
setMultiCpuUsage -localCpu $CORES
setDistributeHost -local

###################################
## Prepare local variables
###################################
set row_height [dbGet head.sites.size_y]
set site_width [dbGet head.sites.size_x]

puts "========================================"
puts "SITE DIMENSION INFORMATION:"
puts " - Row Height (size_y)     : $row_height"
puts " - Site Width (size_x)     : $site_width"
puts "========================================"

set row_height_x2 [expr 2 * $row_height]
set row_height_x4 [expr 4 * $row_height]
set row_height_d2 [expr $row_height / 2.0]

set stripe_pitch [expr 32 * $row_height]
set margin_rows 32
set margin_dist [expr $margin_rows * $row_height]

# Set overall density
set Density 0.6

###################################
## Floor Plan
###################################
floorPlan -r 1.0 $Density $margin_dist $margin_dist $margin_dist $margin_dist

set Core_area [dbGet top.fPlan.area]
set CoreSize  [dbGet top.fPlan.coreBox_size]
set FPsize    [dbGet top.fPlan.box_size]
set FPx       [dbGet top.fPlan.box_sizex]
set FPy       [dbGet top.fPlan.box_sizey]

puts "===================================================="
puts "FLOORPLAN REPORT:"
puts " - Total Area      : $Core_area um^2"
puts " - Core Size {X Y} : $CoreSize um"
puts " - Die Size  {X Y} : $FPsize um"
puts " - Width (X)       : $FPx um"
puts " - Height (Y)      : $FPy um"
puts "===================================================="

set fo [open FPlanFinal.size w]
puts $fo "########################################"
puts $fo "## Final Floorplan Dimensions"
puts $fo "########################################"
puts $fo "Area: $Core_area"
puts $fo "CoreSize_XY: $CoreSize"
puts $fo "DieSize_XY: $FPsize"
puts $fo "DieWidth_X: $FPx"
puts $fo "DieHeight_Y: $FPy"
close $fo

###################################
## Power planning
###################################
# Ring constraints (M8/M9 pitch 0.320)
set ring_m89_w 1.600
set ring_m89_s 1.280
set ring_m89_o 1.280 ;# Offset distance: 4 pitches of M8/M9 (0.320 * 4)

setAddStripeMode -trim_antenna_back_to_shape core_ring
setAddStripeMode -split_vias true
setAddStripeMode -via_using_exact_crossover_size false

# Create global nets
clearGlobalNets
deleteAllPowerPreroutes

globalNetConnect VDD -type pgpin -pin VDD -inst * -module {}
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {}
globalNetConnect VDD -type tiehi -inst * -module {}
globalNetConnect VSS -type tielo -inst * -module {}
applyGlobalNets

# Add ring M8/M9
addRing -nets {VDD VSS} -type core_rings -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $ring_m89_w -spacing $ring_m89_s -offset $ring_m89_o

# Add PG pins
set vdd_m9_right [expr {$margin_dist - $ring_m89_o}]
set vdd_m9_left  [expr {$vdd_m9_right - $ring_m89_w}]
set vss_m9_right [expr {$vdd_m9_left - $ring_m89_s}]
set vss_m9_left  [expr {$vss_m9_right - $ring_m89_w}]

set vdd_m8_top    [expr {$margin_dist - $ring_m89_o}]
set vdd_m8_bottom [expr {$vdd_m8_top - $ring_m89_w}]
set vss_m8_top    [expr {$vdd_m8_bottom - $ring_m89_s}]
set vss_m8_bottom [expr {$vss_m8_top - $ring_m89_w}]

createPGPin VDD -geom M9 [expr {$vdd_m9_left}] [expr {$vdd_m8_bottom}] [expr {$vdd_m9_right}] [expr {$vdd_m8_top}] -net VDD
createPGPin VSS -geom M9 [expr {$vss_m9_left}] [expr {$vss_m8_bottom}] [expr {$vss_m9_right}] [expr {$vss_m8_top}] -net VSS

# Add stripes
set stripe_m45_pitch 17.280 ;# 16 * 1.08
set stripe_m67_pitch 25.920 ;# 24 * 1.08
set stripe_m89_pitch 34.560 ;# 32 * 1.08

set stripe_m4_w 0.096
set stripe_m4_s 0.288
set stripe_m4_offset 8.640 ;# On-grid: 45 * 0.192 (M4 pitch) = 8.640

set stripe_m5_w 0.096
set stripe_m5_s 0.288
set stripe_m5_offset 8.640 ;# On-grid: 45 * 0.192 (M5 pitch) = 8.640

set stripe_m6_w 0.640
set stripe_m6_s 0.896
set stripe_m6_offset 12.800 ;# On-grid: 50 * 0.256 (M6 pitch) = 12.800

set stripe_m7_w 0.640
set stripe_m7_s 0.896
set stripe_m7_offset 12.800 ;# On-grid: 50 * 0.256 (M7 pitch) = 12.800

set stripe_m8_w 1.600
set stripe_m8_s 1.280
set stripe_m8_offset 17.280 ;# On-grid: 54 * 0.320 (M8 pitch) = 17.280

set stripe_m9_w 1.600
set stripe_m9_s 1.280
set stripe_m9_offset 17.280 ;# On-grid: 54 * 0.320 (M9 pitch) = 17.280


# M7 (Vertical)
setAddStripeMode -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width $stripe_m7_w -spacing $stripe_m7_s -set_to_set_distance $stripe_m67_pitch -start_from left -start_offset $stripe_m7_offset -snap_wire_center_to_grid grid

# M6 (Horizontal)
setAddStripeMode -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width $stripe_m6_w -spacing $stripe_m6_s -set_to_set_distance $stripe_m67_pitch -start_from bottom -start_offset $stripe_m6_offset -snap_wire_center_to_grid grid

# M5 (Vertical)
setAddStripeMode -stacked_via_bottom_layer M5 -stacked_via_top_layer M6
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width $stripe_m5_w -spacing $stripe_m5_s -set_to_set_distance $stripe_m45_pitch -start_from left -start_offset $stripe_m5_offset -snap_wire_center_to_grid grid

# Sroute (Limited to M1-M5)
setSrouteMode -viaConnectToShape { stripe }
sroute -connect { corePin } -layerChangeRange { M1 M5 } -corePinTarget { stripe } -allowJogging 0 -allowLayerChange 0 -nets { VDD VSS }

# Trim dangling wires
editTrim -nets {VSS VDD}
clearDrc

# Load pins
setPinConstraint -corner_to_pin_distance 10;
source tcl/pins.tcl

###################################
## Placement
###################################
setDelayCalMode -SIAware false -equivalent_waveform_model none
setPlaceMode -reset
setPlaceMode -place_global_uniform_density true \
    -place_global_module_aware_spare true \
    -place_global_auto_blockage_in_channel soft \
    -place_detail_preroute_as_obs {2 3} -place_global_cong_effort high \
    -place_design_refine_macro true

place_design
refinePlace

checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil.rpt

###################################
## CTS
###################################
set BUFCells {BUFx4_ASAP7_75t_R BUFx8_ASAP7_75t_R BUFx12_ASAP7_75t_R} 
set INVCells {CKINVDCx8_ASAP7_75t_R CKINVDCx12_ASAP7_75t_R CKINVDCx16_ASAP7_75t_R}

create_route_type -name leaf_rule \
    -bottom_preferred_layer M2 -top_preferred_layer M3
create_route_type -name trunk_rule -shield_net VSS \
    -bottom_preferred_layer M4 -top_preferred_layer M5
create_route_type -name top_rule -shield_net VSS \
    -bottom_preferred_layer M6 -top_preferred_layer M7

set_ccopt_property -net_type leaf    route_type leaf_rule
set_ccopt_property -net_type trunk   route_type trunk_rule
set_ccopt_property -net_type top     route_type top_rule
set_ccopt_property routing_top_min_fanout 100
set_ccopt_property target_max_trans 0.3ns

set_ccopt_property buffer_cells $BUFCells
set_ccopt_property inverter_cells $INVCells
set_ccopt_property use_inverters auto

setOptMode -reclaimArea true -leakageToDynamicRatio 0.5 \
    -powerEffort high -fixFanoutLoad true

# CTS
optDesign -prefix preCTS -preCTS
create_ccopt_clock_tree_spec -filename ccopt.spec
source ccopt.spec
ccopt_design -prefix postCTS
optDesign -prefix postCTS -postCTS -setup -hold

###################################
## Routing
###################################
set FILLERCells {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R}

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
    
setFillerMode -core ${FILLERCells} -preserveUserOrder true \
    -honorPrerouteAsObs true -diffCellViol true
addFiller

routeDesign -globalDetail

ecoRoute -fix_drc

verify_drc -report ./verify_rpt/drc.rpt
verifyConnectivity -type all -error 1000 -warning 50 -report ./verify_rpt/connectivity.rpt
setAnalysisMode -analysisType onChipVariation
setDelayCalMode -SIAware true -equivalent_waveform_model propagation
setExtractRCMode -engine postRoute -effortLevel medium
optDesign -postRoute -setup -hold -prefix postRoute

###################################
## Add Filler
###################################
# M1 - M3: MinWidth 0.072, Max 0.936, Decrement 0.288
setMetalFill -layer { M1 M2 M3 } \
    -maxWidth 0.936 -minWidth 0.072 \
    -maxLength 5.0 -minLength 0.148 \
    -decrement 0.288 -activeSpacing 0.144 \
    -gapSpacing 0.144 -maxDensity 60 -minDensity 25 -preferredDensity 40

# M4 - M5: MinWidth 0.096, Max 1.248, Decrement 0.384
setMetalFill -layer { M4 M5 } \
    -maxWidth 1.248 -minWidth 0.096 \
    -maxLength 5.0 -minLength 0.384 \
    -decrement 0.384 -activeSpacing 0.192 \
    -gapSpacing 0.192 -maxDensity 35 -minDensity 10 -preferredDensity 25
    
# M6 - M7: MinWidth 0.128, Max 1.664, Decrement 0.512
setMetalFill -layer { M6 M7 } \
    -maxWidth 1.664 -minWidth 0.128 \
    -maxLength 5.0 -minLength 0.512 \
    -decrement 0.512 -activeSpacing 0.300 \
    -gapSpacing 0.300 -maxDensity 55 -minDensity 25 -preferredDensity 40

# M8 - M9: MinWidth 0.160, Max 2.500, Decrement 0.160 
setMetalFill -layer { M8 M9 } \
    -maxWidth 2.5 -minWidth 0.160 \
    -maxLength 5.0 -minLength 0.960 \
    -decrement 0.160 -activeSpacing 0.320 \
    -gapSpacing 0.320 -maxDensity 55 -minDensity 25 -preferredDensity 40

# Pad
setMetalFill -layer { Pad } \
    -maxWidth 8.0 -minWidth 0.8 \
    -maxLength 8.96 -minLength 8.96 \
    -decrement 0.160 -activeSpacing 8.16 \
    -gapSpacing 8.16 \
    -maxDensity 30 -minDensity 10 -preferredDensity 25

# Execute metal fill
addMetalFill -snap -squareShape

###################################
## Export FIles
###################################
verify_drc -report ./verify_rpt/final_drc.rpt
verifyConnectivity -type all -error 1000 -warning 50 -report ./verify_rpt/final_connectivity.rpt
saveNetlist outputs/Mul32_pnr.v
saveDesign saved/Mul32_final.enc

streamOut outputs/Mul32.gds -libName WORK -units 4000 -mode ALL

report_area > ./verify_rpt/final_area.rpt
report_power > ./verify_rpt/final_power.rpt
report_timing > ./verify_rpt/final_timing.rpt
report_gate > ./verify_rpt/final_gate.rpt
