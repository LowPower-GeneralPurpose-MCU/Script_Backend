############################################################
## One-command Innovus master flow
##
## Sequence:
##   init -> hierarchy floorplan -> 4x4 SRAM floorplan
##   -> PG/pins -> placement -> CTS -> route
##   -> route verification -> metal fill -> final verification/export
##
## Run from the project root:
##   innovus -stylus -files tcl/innovus.tcl
##
## Default: INNOVUS_AUTO_RUN_ALL=1
## Set INNOVUS_AUTO_RUN_ALL=0 to stop after routed verification.
## Set INNOVUS_STOP_AFTER_POWER_PINS=1 to stop after PG and top-level pins.
############################################################

set AUTO_RUN_ALL 1
set MASTER_ONE_SHOT 1
set enc_source_continue_on_error false
if {[info exists ::env(INNOVUS_AUTO_RUN_ALL)]} {
    switch -nocase -- $::env(INNOVUS_AUTO_RUN_ALL) {
        1 - true - yes - on  { set AUTO_RUN_ALL 1 }
        0 - false - no - off { set AUTO_RUN_ALL 0 }
        default {
            error "INNOVUS_AUTO_RUN_ALL must be 0/1, false/true, no/yes or off/on"
        }
    }
}

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

set USER $::env(USER)
if {[catch {file delete -force /tmp/$USER/innovus_master}]} {}
set auto_file_dir "/tmp/$USER/innovus_master"

foreach dir {outputs reports verify_rpt saved} {
    file mkdir $dir
}

if {![file exists ./tcl/innovus.globals]} {
    error "Run this script from the project root; missing ./tcl/innovus.globals"
}

set init_design_uniquify 1
source ./tcl/innovus.globals
source ./tcl/prepare_innovus_sdc.tcl
source ./tcl/flow_checks.tcl
prepare_innovus_sdc $SYN_SDC_FILE $INNOVUS_SDC_FILE $INNOVUS_GROUP_PATH_FILE

init_design

if {[file exists $INNOVUS_GROUP_PATH_FILE] && [file size $INNOVUS_GROUP_PATH_FILE] > 0} {
    puts "Reading global path groups: $INNOVUS_GROUP_PATH_FILE"
    source $INNOVUS_GROUP_PATH_FILE
}

setDesignMode -process 7
setDesignMode \
    -bottomRoutingLayer 2 \
    -topRoutingLayer 7

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

if {$AUTO_RUN_ALL} {
    puts "===================================================="
    puts "ONE-SHOT MODE ENABLED"
    puts "Route/fill/export stages now stop unless their reports are clean."
    puts "Final GDS export also requires ASAP7_GDS_MAP_FILE."
    puts "===================================================="
}

# ------------------------------------------------------------------------
# 1. TIMING/CONGESTION-AWARE HIERARCHY FLOORPLAN
# ------------------------------------------------------------------------

proc snap_up {value grid} {
    return [expr {ceil($value / $grid) * $grid}]
}

set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {$SRAM_PTRS eq "" || $SRAM_PTRS eq "0x0"} {
    error "No SRAM instances found for master $SRAM_MASTER"
}
if {[llength $SRAM_PTRS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros, found [llength $SRAM_PTRS]"
}

set first_sram_ptr [lindex $SRAM_PTRS 0]
set SRAM_W [dbGet $first_sram_ptr.cell.size_x]
set SRAM_H [dbGet $first_sram_ptr.cell.size_y]

set SRAM_ISLAND_W [expr {
    $SRAM_COLS * $SRAM_W +
    ($SRAM_COLS - 1) * $SRAM_MACRO_GAP_X
}]
set SRAM_ISLAND_H [expr {
    $SRAM_ROWS * $SRAM_H +
    ($SRAM_ROWS - 1) * $SRAM_MACRO_GAP_Y
}]

set CORE_W [snap_up [expr {
    2.0 * $SRAM_EDGE_GAP_X +
    $SRAM_ISLAND_W +
    $SRAM_ISLAND_ESCAPE_RIGHT +
    $LOGIC_REGION_WIDTH
}] $FLOORPLAN_GRID]

set CORE_H [snap_up [expr {
    2.0 * $SRAM_EDGE_GAP_Y +
    $SRAM_ISLAND_H +
    $SRAM_ISLAND_ESCAPE_TOP +
    $LOGIC_REGION_HEIGHT
}] $FLOORPLAN_GRID]

puts "===================================================="
puts "FLOORPLAN SIZE SUMMARY"
puts " - SRAM island       : [format %.3f $SRAM_ISLAND_W] x [format %.3f $SRAM_ISLAND_H]"
puts " - Logic reserve     : [format %.3f $LOGIC_REGION_WIDTH] x [format %.3f $LOGIC_REGION_HEIGHT]"
puts " - Core size snapped : [format %.3f $CORE_W] x [format %.3f $CORE_H]"
puts "===================================================="

floorPlan \
    -s $CORE_W $CORE_H \
    $margin_dist $margin_dist $margin_dist $margin_dist

# Keep the clock ideal during hierarchy and macro floorplanning.
# proto_design is optional because it requires the invs_ehfs license.
if {$RUN_PROTO_DESIGN} {
    timeDesign -proto -prePlace \
        -outDir ./reports/hierFP_proto_timing

    set_proto_design_mode \
        -timing_aware true \
        -congestion_aware true

    proto_design
} else {
    puts "INFO: proto_design skipped; using deterministic floorplan base."
}

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_hierFP_proto.rpt

# In one-shot mode the generated guides are snapped and accepted
# automatically.  Use the staged scripts for interactive guide editing.
source ./tcl/finish_hierFP.tcl

# ------------------------------------------------------------------------
# 2. SRAM MACRO FLOORPLAN
# ------------------------------------------------------------------------

# Create a deterministic lower-left 4x4 SRAM island.  The final sequence is
# snap -> geometry validation -> FIXED.
source ./tcl/sram_macro_floorplan.tcl
source ./tcl/finish_macroFP.tcl

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

source ./tcl/sram_route_guard.tcl

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_before_pnr.rpt

# ------------------------------------------------------------------------
# 3. POWER PLAN AND TOP-LEVEL PINS
# ------------------------------------------------------------------------

set sram_edge_report ./reports/sram_island_pg_edges.rpt
file delete -force $sram_edge_report

puts "POWER PLAN ENTRY: [file normalize ./tcl/power_plan.tcl]"
if {[catch {source ./tcl/power_plan.tcl} power_plan_error]} {
    puts stderr "Power plan failed before pin assignment: $power_plan_error"
    error $power_plan_error
}
stop_if_dirty_pg_connectivity_report \
    ./verify_rpt/pg_connectivity_before_stdcell_place.rpt \
    "Power plan PG connectivity"
stop_if_dirty_pg_special_drc_report \
    ./verify_rpt/pg_drc_before_stdcell_place.rpt \
    "Power plan PG DRC"
puts "POWER PLAN RETURN: ./tcl/power_plan.tcl returned cleanly"

if {![file exists $sram_edge_report]} {
    puts "POWER PLAN DIRECT SRAM ISLAND SOURCE: $sram_edge_report missing after power_plan.tcl"

    if {![info exists SRAM_ISLAND_URX]} {
        if {[catch {source ./outputs/sram_macro_geometry.tcl} sram_geometry_error]} {
            puts stderr "Cannot reload SRAM macro geometry before direct SRAM island PG: $sram_geometry_error"
            error $sram_geometry_error
        }
    }

    if {![info exists power_die_llx] || ![info exists power_die_lly]} {
        set direct_power_die_box [join [dbGet top.fPlan.box]]
        if {[llength $direct_power_die_box] != 4} {
            puts stderr "Cannot decode die box before direct SRAM island PG: [dbGet top.fPlan.box]"
            error "Cannot decode die box before direct SRAM island PG"
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
        error $direct_sram_power_error
    }
    puts "POWER PLAN DIRECT SRAM ISLAND RETURNED"
}

setPinConstraint \
    -cell $DESIGN \
    -corner_to_pin_distance 8
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
# 4. STANDARD-CELL PLACEMENT
# ------------------------------------------------------------------------

setDelayCalMode \
    -SIAware false \
    -equivalent_waveform_model none \
    -ewm_type moments

setPlaceMode -reset
setPlaceMode \
    -place_global_uniform_density false \
    -place_global_module_aware_spare true \
    -place_global_auto_blockage_in_channel soft \
    -place_detail_preroute_as_obs {2 3} \
    -place_global_cong_effort high \
    -place_global_reorder_scan false \
    -place_design_refine_macro false

place_opt_design
refinePlace

checkPlace ./verify_rpt/checkPlace_after_place.rpt
assert_clean_check_place ./verify_rpt/checkPlace_after_place.rpt
checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_after_place.rpt

timeDesign \
    -preCTS \
    -outDir ./reports/timing_preCTS

# Standard-cell M1 rails exist after placement.  Build the PG stack upward in
# legal ASAP7 grid steps: M1->M5 taps, M5/M6/M7 core mesh, then M7/M8/M9 upper mesh.
foreach stale_post_place_pg_report {
    ./verify_rpt/pg_connectivity_before_trim.rpt
    ./verify_rpt/pg_connectivity_after_trim.rpt
    ./verify_rpt/pg_drc_after_trim.rpt
} {
    file delete -force $stale_post_place_pg_report
}
source ./tcl/core_lower_pg_nojog.tcl
source ./tcl/core_pg_outside_island.tcl
source ./tcl/global_upper_pg_to_ring.tcl

if {[catch {
    connect_core_pg_pins_nojog ./verify_rpt/pg_connectivity_after_trim.rpt
} post_place_pg_error]} {
    puts stderr "Post-placement PG reconnect/verify failed: $post_place_pg_error"
    error $post_place_pg_error
}
if {[catch {
    verify_pg_special_drc_or_stop ./verify_rpt/pg_drc_after_trim.rpt {M4 M9}
} post_place_pg_drc_error]} {
    puts stderr "Post-placement PG DRC failed: $post_place_pg_drc_error"
    error $post_place_pg_drc_error
}
stop_if_dirty_pg_connectivity_report \
    ./verify_rpt/pg_connectivity_after_trim.rpt \
    "Post-placement PG connectivity"
stop_if_dirty_pg_special_drc_report \
    ./verify_rpt/pg_drc_after_trim.rpt \
    "Post-placement PG DRC"

saveDesign ./saved/axi_ram_placed.enc

# ------------------------------------------------------------------------
# 5. CLOCK TREE SYNTHESIS
# ------------------------------------------------------------------------

# Use RVT clock cells for lower leakage and stable clock behavior.  LVT
# remains available to timing optimization for non-clock critical paths.
set BUFCells {
    BUFx4_ASAP7_75t_R
    BUFx8_ASAP7_75t_R
    BUFx10_ASAP7_75t_R
    BUFx12_ASAP7_75t_R
    BUFx12f_ASAP7_75t_R
    BUFx16f_ASAP7_75t_R
    BUFx24_ASAP7_75t_R
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
    -bottom_preferred_layer M4 \
    -top_preferred_layer M5

create_route_type \
    -name top_rule \
    -bottom_preferred_layer M6 \
    -top_preferred_layer M7

set_ccopt_property -net_type leaf  route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top   route_type top_rule
set_ccopt_property routing_top_min_fanout 100
set_ccopt_property target_max_trans 0.3ns
# Keep the SDC source transition at 40 ps, but do not force every hard-macro
# clock leaf to meet the same number.  The ASAP7 SRAM clk pin is a hard macro
# sink; the latest CTS log showed 64-109 ps at SRAM leaves with clean timing.
set_ccopt_property -net_type leaf  target_max_trans 120ps
set_ccopt_property -net_type trunk target_max_trans 160ps
set_ccopt_property -net_type top   target_max_trans 200ps
set_ccopt_property target_skew 50ps
set_ccopt_property buffer_cells $BUFCells
set_ccopt_property inverter_cells $INVCells
set_ccopt_property use_inverters auto

setOptMode \
    -reclaimArea true \
    -leakageToDynamicRatio 0.5 \
    -powerEffort high \
    -fixFanoutLoad true

optDesign -prefix preCTS -preCTS
refinePlace
checkPlace ./verify_rpt/checkPlace_before_cts.rpt
assert_clean_check_place ./verify_rpt/checkPlace_before_cts.rpt
setDesignMode \
    -bottomRoutingLayer 2 \
    -topRoutingLayer 7

# Do not extract/source ccopt.spec.  clock_opt_design avoids the
# IMPCCOPT-2048 "clock trees are already defined" failure in this flow.
clock_opt_design

# Propagated clocks are valid only after CTS.
proc apply_post_cts_propagated_clocks {} {
    set active_constraint_modes [all_constraint_modes -active]

    if {[catch {
        set_interactive_constraint_modes $active_constraint_modes
        set_propagated_clock [all_clocks]
    } propagated_clock_setup_error]} {
        catch {set_interactive_constraint_modes {}}
        return -code error $propagated_clock_setup_error
    }

    set_interactive_constraint_modes {}
}

if {[catch {apply_post_cts_propagated_clocks} propagated_clock_error]} {
    puts stderr "Post-CTS propagated-clock setup failed: $propagated_clock_error"
    error $propagated_clock_error
}

optDesign \
    -prefix postCTS \
    -postCTS \
    -setup \
    -hold

# CTS/postCTS inserts FE_* and CTS_* cells after the first corePin sroute.
# Reconnect only same-layer core PG pins, then verify before saving/filler.
connect_core_pg_pins_nojog ./verify_rpt/pg_connectivity_after_postcts.rpt

timeDesign \
    -postCTS \
    -outDir ./reports/timing_postCTS

saveDesign ./saved/axi_ram_postCTS.enc

# ------------------------------------------------------------------------
# 6. FILLER BEFORE ROUTING
# ------------------------------------------------------------------------

set FILLERCells [list \
    FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R \
    FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L]

setFillerMode \
    -core $FILLERCells \
    -preserveUserOrder true \
    -honorPrerouteAsObs true \
    -diffCellViol true

addFiller \
    -cell $FILLERCells \
    -prefix FILLER \
    -honorPrerouteAsObs true \
    -diffCellViol true

assert_filler_inserted FILLER
connect_core_pg_pins_nojog ./verify_rpt/pg_connectivity_after_filler.rpt

# ------------------------------------------------------------------------
# 7. SIGNAL ROUTING AND POST-ROUTE OPTIMIZATION
# ------------------------------------------------------------------------

setNanoRouteMode -reset
setDesignMode \
    -bottomRoutingLayer 2 \
    -topRoutingLayer 7
source ./tcl/sram_route_guard.tcl
setNanoRouteMode -quiet \
    -route_strict_honor_route_rule true \
    -route_strictly_honor_1d_routing true \
    -route_detail_no_taper_in_layers "2:7" \
    -route_detail_no_taper_on_output_pin true \
    -route_use_auto_via false \
    -route_with_via_only_for_stdcell_pin true \
    -route_detail_use_multi_cut_via_effort low \
    -route_with_timing_driven true \
    -route_with_si_driven false \
    -route_detail_fix_antenna true \
    -route_detail_merge_abutting_cut true \
    -route_detail_end_iteration 20

routeDesign -globalDetail
routeDesign -viaOpt -wireOpt -trackOpt
setNanoRouteMode -quiet \
    -route_with_timing_driven false \
    -route_with_si_driven false
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

connect_core_pg_pins_nojog ./verify_rpt/pg_connectivity_after_postroute_opt.rpt
ecoRoute -fix_drc

timeDesign \
    -postRoute \
    -outDir ./reports/timing_postRoute

verify_drc \
    -report ./verify_rpt/drc_postroute.rpt

verify_antenna_if_enabled ./verify_rpt/antenna_postroute.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_postroute.rpt

set ROUTE_REPORTS_CLEAN 0
if {[catch {
    assert_clean_drc_report ./verify_rpt/drc_postroute.rpt
    assert_clean_connectivity_report ./verify_rpt/connectivity_postroute.rpt
    set ROUTE_REPORTS_CLEAN 1
} route_report_error]} {
    puts stderr "Post-route reports are not clean: $route_report_error"
}

saveDesign ./saved/axi_ram_routed.enc

puts "===================================================="
puts "ROUTED CHECKPOINT CREATED"
puts " - ./verify_rpt/drc_postroute.rpt"
puts " - ./verify_rpt/antenna_postroute.rpt"
puts " - ./verify_rpt/connectivity_postroute.rpt"
puts "===================================================="

# ------------------------------------------------------------------------
# 8. ROUTE RECHECK, METAL FILL AND FINAL EXPORT
# ------------------------------------------------------------------------

if {!$ROUTE_REPORTS_CLEAN} {
    puts "===================================================="
    puts "STRICT CHECKPOINT MODE: FLOW STOPPED AFTER ROUTE"
    puts "Repair DRC/connectivity before metal fill."
    puts " - ./verify_rpt/drc_postroute.rpt"
    puts " - ./verify_rpt/connectivity_postroute.rpt"
    puts " - ./saved/axi_ram_routed.enc"
    puts "===================================================="
    return
}

source ./tcl/verify_route.tcl

if {$AUTO_RUN_ALL} {
    set ROUTE_VERIFY_CLEAN 1
    source ./tcl/add_fill_and_verify.tcl

    if {[info exists FINAL_REPORTS_CLEAN] && $FINAL_REPORTS_CLEAN} {
        if {$GDS_MAP_FILE eq ""} {
            puts "Skipping final GDS export because ASAP7_GDS_MAP_FILE is not set."
        } else {
            set FINAL_VERIFY_CLEAN 1
            source ./tcl/export_gds.tcl
        }
    } else {
        puts "===================================================="
        puts "STRICT CHECKPOINT MODE: FLOW STOPPED BEFORE FINAL EXPORT"
        puts "Metal fill was skipped or post-fill reports are not clean."
        puts "Set INNOVUS_RUN_LEGACY_METAL_FILL=1 only after routed reports are clean,"
        puts "or use the Pegasus signoff fill flow recommended by Cadence."
        puts "===================================================="
    }

    puts "===================================================="
    puts "ONE-COMMAND INNOVUS FLOW REACHED A SAFE CHECKPOINT"
    puts "Review every report in ./verify_rpt and run Calibre signoff."
    puts "===================================================="
} else {
    puts "===================================================="
    puts "STRICT CHECKPOINT MODE: FLOW STOPPED BEFORE METAL FILL"
    puts "Repair and recheck DRC, antenna and connectivity."
    puts "When all routed reports are clean, run:"
    puts "  set ROUTE_VERIFY_CLEAN 1"
    puts "  source ./tcl/add_fill_and_verify.tcl"
    puts "After clean post-fill reports, run:"
    puts "  set FINAL_VERIFY_CLEAN 1"
    puts "  source ./tcl/export_gds.tcl"
    puts "===================================================="
}
