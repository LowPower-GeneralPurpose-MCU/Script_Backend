############################################################
## Innovus implementation through routed checkpoint
##
## Prerequisite:
##   outputs/FloorPlan_withMacro.fp
##   outputs/sram_macro_geometry.tcl
##
## This script stops before metal fill and GDS export.
############################################################

set USER $::env(USER)
if {[catch {file delete -force /tmp/$USER/innovus_pnr}]} {}
set auto_file_dir "/tmp/$USER/innovus_pnr"

set STOP_AFTER_POWER_PINS 0
if {[info exists ::env(INNOVUS_STOP_AFTER_POWER_PINS)]} {
    switch -nocase -- $::env(INNOVUS_STOP_AFTER_POWER_PINS) {
        1 - true - yes - on  { set STOP_AFTER_POWER_PINS 1 }
        0 - false - no - off { set STOP_AFTER_POWER_PINS 0 }
        default {
            error "INNOVUS_STOP_AFTER_POWER_PINS must be 0/1, false/true, no/yes or off/on"
        }
    }
}

foreach dir {outputs reports verify_rpt saved} {
    file mkdir $dir
}

set init_design_uniquify 1
source ./tcl/innovus.globals
init_design

setDesignMode -process 7

if {![catch {open "/proc/cpuinfo"} cpu_file]} {
    set CORES [regexp -all -line {^processor\s} [read $cpu_file]]
    close $cpu_file
} else {
    set CORES 4
}
if {$CORES < 1} {
    set CORES 1
}
if {$CORES > 24} {
    set CORES 24
}
setMultiCpuUsage -acquireLicense $CORES
setMultiCpuUsage -localCpu $CORES
setDistributeHost -local

set MACRO_FP_FILE "./outputs/FloorPlan_withMacro.fp"
set MACRO_GEOMETRY_FILE "./outputs/sram_macro_geometry.tcl"

foreach prerequisite [list $MACRO_FP_FILE $MACRO_GEOMETRY_FILE] {
    if {![file exists $prerequisite]} {
        error "Missing PnR prerequisite: [file normalize $prerequisite]"
    }
}

loadFPlan $MACRO_FP_FILE
source $MACRO_GEOMETRY_FILE

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set core_urx [dbGet top.fPlan.coreBox_urx]
set core_ury [dbGet top.fPlan.coreBox_ury]

set row_height [dbGet head.sites.size_y]
set site_width [dbGet head.sites.size_x]

# Macro-slide audit before any power or standard-cell placement.
set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {[llength $SRAM_PTRS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros, found [llength $SRAM_PTRS]"
}

foreach ptr $SRAM_PTRS {
    set macro_name [lindex [dbGet $ptr.name] 0]
    set orientation [lindex [dbGet $ptr.orient] 0]
    set status [lindex [dbGet $ptr.pStatus] 0]

    if {$orientation ne "R0" && $orientation ne "R180"} {
        error "$macro_name has illegal orientation $orientation"
    }
    if {$status ne "fixed"} {
        error "$macro_name must be FIXED before PnR; current status is $status"
    }
}

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_before_pnr.rpt

# ------------------------------------------------------------------------
# 1. POWER PLAN AND TOP-LEVEL PINS
# ------------------------------------------------------------------------

set sram_edge_report ./reports/sram_island_pg_edges.rpt
file delete -force $sram_edge_report

puts "POWER PLAN ENTRY: [file normalize ./tcl/power_plan.tcl]"
if {[catch {source ./tcl/power_plan.tcl} power_plan_error]} {
    puts stderr "Power plan failed before pin assignment: $power_plan_error"
    return
}
puts "POWER PLAN EXIT: ./tcl/power_plan.tcl returned cleanly"

if {![file exists $sram_edge_report]} {
    puts "POWER PLAN DIRECT SRAM ISLAND SOURCE: $sram_edge_report missing after power_plan.tcl"

    if {![info exists SRAM_ISLAND_URX]} {
        if {[catch {source ./outputs/sram_macro_geometry.tcl} sram_geometry_error]} {
            puts stderr "Cannot reload SRAM macro geometry before direct SRAM island PG: $sram_geometry_error"
            return
        }
    }

    if {![info exists power_die_llx] || ![info exists power_die_lly]} {
        set direct_power_die_box [join [dbGet top.fPlan.box]]
        if {[llength $direct_power_die_box] != 4} {
            puts stderr "Cannot decode die box before direct SRAM island PG: [dbGet top.fPlan.box]"
            return
        }
        lassign $direct_power_die_box \
            power_die_llx power_die_lly power_die_urx power_die_ury
    }

    if {![info exists stripe_m45_w]} {
        set stripe_m45_w 0.096
    }
    if {![info exists stripe_m45_s]} {
        set stripe_m45_s 0.288
    }

    if {[catch {source ./tcl/sram_island_power.tcl} direct_sram_power_error]} {
        puts stderr "Direct SRAM island power failed before pin assignment: $direct_sram_power_error"
        return
    }
    puts "POWER PLAN DIRECT SRAM ISLAND RETURNED"
}

setPinConstraint -corner_to_pin_distance 8
source ./tcl/pins.tcl

saveDesign ./saved/axi_ram_floorplan_power_pins.enc

if {$STOP_AFTER_POWER_PINS} {
    puts "===================================================="
    puts "CHECKPOINT MODE: FLOW STOPPED AFTER POWER PLAN AND TOP-LEVEL PINS"
    puts " - ./saved/axi_ram_powerplan.enc"
    puts " - ./saved/axi_ram_floorplan_power_pins.enc"
    puts "Standard-cell placement has not been run."
    puts "===================================================="
    return
}

# ------------------------------------------------------------------------
# 2. STANDARD-CELL PLACEMENT
# ------------------------------------------------------------------------

setDelayCalMode \
    -SIAware false \
    -equivalent_waveform_model none

setPlaceMode -reset
setPlaceMode \
    -place_global_uniform_density true \
    -place_global_module_aware_spare true \
    -place_global_auto_blockage_in_channel soft \
    -place_detail_preroute_as_obs {2 3} \
    -place_global_cong_effort high \
    -place_design_refine_macro false

place_opt_design
refinePlace

checkPlace
checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_after_place.rpt

timeDesign \
    -preCTS \
    -outDir ./reports/timing_preCTS

# Standard-cell M1 rails exist after placement.  sroute is restricted to
# straight same-layer connections; M1-to-M8 taps are explicit addStripe vias.
source ./tcl/global_upper_pg_to_ring.tcl
source ./tcl/core_lower_pg_nojog.tcl

verifyConnectivity \
    -type special \
    -net {VDD VSS} \
    -noUnroutedNet \
    -report ./verify_rpt/pg_connectivity_before_trim.rpt

editTrim -nets {VDD VSS}
clearDrc

verifyConnectivity \
    -type special \
    -net {VDD VSS} \
    -noUnroutedNet \
    -report ./verify_rpt/pg_connectivity_after_trim.rpt

pg_assert_clean_connectivity_report ./verify_rpt/pg_connectivity_after_trim.rpt

saveDesign ./saved/axi_ram_placed.enc

# ------------------------------------------------------------------------
# 3. CLOCK TREE SYNTHESIS
# ------------------------------------------------------------------------

# Use RVT clock cells for lower leakage and stable clock behavior.  LVT
# remains available to timing optimization for non-clock critical paths.
set BUFCells {
    BUFx4_ASAP7_75t_R
    BUFx8_ASAP7_75t_R
    BUFx12_ASAP7_75t_R
}
set INVCells {
    CKINVDCx8_ASAP7_75t_R
    CKINVDCx12_ASAP7_75t_R
    CKINVDCx16_ASAP7_75t_R
}

create_route_type \
    -name leaf_rule \
    -bottom_preferred_layer M2 \
    -top_preferred_layer M3

create_route_type \
    -name trunk_rule \
    -shield_net VSS \
    -bottom_preferred_layer M4 \
    -top_preferred_layer M5

create_route_type \
    -name top_rule \
    -shield_net VSS \
    -bottom_preferred_layer M6 \
    -top_preferred_layer M7

set_ccopt_property -net_type leaf  route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top   route_type top_rule
set_ccopt_property routing_top_min_fanout 100
set_ccopt_property target_max_trans 0.3ns
set_ccopt_property buffer_cells $BUFCells
set_ccopt_property inverter_cells $INVCells
set_ccopt_property use_inverters auto

setOptMode \
    -reclaimArea true \
    -leakageToDynamicRatio 0.5 \
    -powerEffort high \
    -fixFanoutLoad true

optDesign -prefix preCTS -preCTS

# Do not extract/source ccopt.spec.  clock_opt_design avoids the
# IMPCCOPT-2048 "clock trees are already defined" failure in this flow.
clock_opt_design

# Propagated clocks are valid only after CTS.
set_propagated_clock [all_clocks]

optDesign \
    -prefix postCTS \
    -postCTS \
    -setup \
    -hold

timeDesign \
    -postCTS \
    -outDir ./reports/timing_postCTS

saveDesign ./saved/axi_ram_postCTS.enc

# ------------------------------------------------------------------------
# 4. FILLER BEFORE ROUTING
# ------------------------------------------------------------------------

set FILLERCells {
    FILLER_ASAP7_75t_R
    FILLERxp5_ASAP7_75t_R
    FILLER_ASAP7_75t_L
    FILLERxp5_ASAP7_75t_L
}

setFillerMode \
    -core $FILLERCells \
    -preserveUserOrder true \
    -honorPrerouteAsObs true \
    -diffCellViol true

addFiller

# ------------------------------------------------------------------------
# 5. SIGNAL ROUTING AND POST-ROUTE OPTIMIZATION
# ------------------------------------------------------------------------

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
ecoRoute -fix_drc

setAnalysisMode -analysisType onChipVariation
setDelayCalMode \
    -SIAware true \
    -equivalent_waveform_model propagation
setExtractRCMode \
    -engine postRoute \
    -effortLevel medium

optDesign \
    -postRoute \
    -setup \
    -hold \
    -prefix postRoute

ecoRoute -fix_drc

timeDesign \
    -postRoute \
    -outDir ./reports/timing_postRoute

verify_drc \
    -report ./verify_rpt/drc_postroute.rpt

verifyProcessAntenna \
    -report ./verify_rpt/antenna_postroute.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_postroute.rpt

saveDesign ./saved/axi_ram_routed.enc

puts "===================================================="
puts "ROUTED CHECKPOINT CREATED"
puts "Review and repair until all three reports are clean:"
puts " - ./verify_rpt/drc_postroute.rpt"
puts " - ./verify_rpt/antenna_postroute.rpt"
puts " - ./verify_rpt/connectivity_postroute.rpt"
puts ""
puts "After every ECO repair, run:"
puts "  source ./tcl/verify_route.tcl"
puts "When clean, continue with:"
puts "  set ROUTE_VERIFY_CLEAN 1"
puts "  source ./tcl/add_fill_and_verify.tcl"
puts "===================================================="
