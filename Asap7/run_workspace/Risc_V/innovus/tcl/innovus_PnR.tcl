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

    setDesignMode \
        -bottomRoutingLayer 2 \
        -topRoutingLayer 7
}

setMultiColorsHier

set_interactive_constraint_modes [all_constraint_modes]
if {[sizeof_collection [all_clocks]] == 0} {
    error "No functional clock is active after restoreDesign."
}

proc write_skipped_report {report_file reason} {
    set fh [open $report_file w]
    puts $fh "SKIPPED"
    puts $fh $reason
    close $fh
}

proc assert_clean_drc_report {report_file} {
    if {![file exists $report_file]} {
        error "Missing DRC report: $report_file"
    }

    set fh [open $report_file r]
    set text [read $fh]
    close $fh

    if {[regexp {No DRC violations were found} $text] ||
        [regexp {Total number of DRC violations[[:space:]]*=[[:space:]]*0} $text] ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $text]} {
        return
    }

    error "DRC is not clean: review $report_file"
}

proc assert_clean_connectivity_report {report_file} {
    if {![file exists $report_file]} {
        error "Missing connectivity report: $report_file"
    }

    set fh [open $report_file r]
    set text [read $fh]
    close $fh

    if {[regexp {Found no problems or warnings\.} $text]} {
        return
    }

    error "Connectivity is not clean: review $report_file"
}

proc env_flag {name default_value} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        return $default_value
    }

    switch -nocase -- $::env($name) {
        1 - true - yes - on  { return 1 }
        0 - false - no - off { return 0 }
        default {
            error "$name must be 0/1, false/true, no/yes, or off/on"
        }
    }
}

proc verify_antenna_if_enabled {report_file} {
    if {![env_flag INNOVUS_RUN_ANTENNA_CHECK 0]} {
        write_skipped_report $report_file \
            "Antenna check skipped. ASAP7 educational LEFs used here do not load process antenna rules by default."
        puts "INFO: Antenna check skipped. Set INNOVUS_RUN_ANTENNA_CHECK=1 only when antenna rules are loaded."
        return 0
    }

    if {[catch {verify_antenna -report $report_file} antenna_error]} {
        if {[string first "no process antenna information" $antenna_error] >= 0 ||
            [string first "IMPVPA-22" $antenna_error] >= 0} {
            write_skipped_report $report_file \
                "Antenna check skipped because Innovus reported no process antenna information."
            puts "INFO: Antenna check skipped: no process antenna information is loaded."
            return 0
        }
        return -code error $antenna_error
    }

    return 1
}

proc format_pg_coord {value} {
    return [format %.3f $value]
}

proc find_left_m9_ring_box {net core_llx core_lly core_ury} {
    set net_ptr [lindex [dbGet -p top.nets.name $net] 0]
    if {$net_ptr eq "" || $net_ptr eq "0x0"} {
        error "Cannot find PG net $net while creating the M9 ring pin"
    }

    # addRing snaps to the actual M9 track grid.  Query the generated wire
    # instead of reconstructing its box from nominal width/offset values.
    set wire_ptrs [dbGet -p2 $net_ptr.sWires.layer.name M9]
    set best_box {}
    foreach wire_ptr $wire_ptrs {
        set wire_box [join [dbGet $wire_ptr.box]]
        if {[llength $wire_box] != 4} {
            continue
        }
        lassign $wire_box llx lly urx ury
        set is_vertical [expr {($ury - $lly) > ($urx - $llx)}]
        set covers_core_height [expr {
            $lly <= $core_lly + 0.000001 &&
            $ury >= $core_ury - 0.000001
        }]
        if {!$is_vertical || !$covers_core_height ||
            $urx > $core_llx + 0.000001} {
            continue
        }

        if {[llength $best_box] == 0 || $urx > [lindex $best_box 2]} {
            set best_box $wire_box
        }
    }

    if {[llength $best_box] != 4} {
        error "Cannot find the left M9 core-ring wire for PG net $net"
    }
    return $best_box
}

proc create_left_m9_ring_pg_pins {core_llx core_lly core_ury} {
    catch {deletePGPin -net VDD}
    catch {deletePGPin -net VSS}

    set pg_pin_length [expr {6.0 * 0.320}]
    set pg_pin_center_y [expr {($core_lly + $core_ury) / 2.0}]

    foreach net {VDD VSS} {
        lassign [find_left_m9_ring_box \
            $net $core_llx $core_lly $core_ury] \
            ring_llx ring_lly ring_urx ring_ury

        set pg_pin_lly [expr {max($ring_lly, $pg_pin_center_y - $pg_pin_length / 2.0)}]
        set pg_pin_ury [expr {min($ring_ury, $pg_pin_center_y + $pg_pin_length / 2.0)}]
        if {$pg_pin_ury - $pg_pin_lly < 0.320} {
            error "Left M9 ring segment for $net is too short for a PG pin"
        }

        createPGPin $net -geom M9 \
            [format_pg_coord $ring_llx] [format_pg_coord $pg_pin_lly] \
            [format_pg_coord $ring_urx] [format_pg_coord $pg_pin_ury] \
            -net $net
    }
}

# Keep clock ideal through placement/pre-CTS.  It is changed to propagated only
# after clock_opt_design.

# ----------------------------------------------------------------------------
# Floorplan information
# ----------------------------------------------------------------------------
set CoreArea [dbGet top.fPlan.area]
set CoreSize [dbGet top.fPlan.coreBox_size]
set DieSize  [dbGet top.fPlan.box_size]
set FPx      [dbGet top.fPlan.box_sizex]
set FPy      [dbGet top.fPlan.box_sizey]

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set core_urx [dbGet top.fPlan.coreBox_urx]
set core_ury [dbGet top.fPlan.coreBox_ury]
set CoreBox  [list $core_llx $core_lly $core_urx $core_ury]

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
setAddStripeMode -reset
setAddStripeMode -allow_jog none
setAddStripeMode -trim_antenna_back_to_shape core_ring
setAddStripeMode -split_vias true
setAddStripeMode -via_using_exact_crossover_size false

clearGlobalNets
deleteAllPowerPreroutes

globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets

set vss_ring_offset [expr {$RING_OFFSET + $RING_WIDTH + $RING_SPACING}]
set ring_guard_span [expr {$vss_ring_offset + $RING_WIDTH + 0.160}]

set power_die_box [join [dbGet top.fPlan.box]]
if {[llength $power_die_box] != 4} {
    error "Cannot decode die box for power planning: [dbGet top.fPlan.box]"
}
lassign $power_die_box \
    power_die_llx power_die_lly power_die_urx power_die_ury

set die_core_margin_left [expr {$core_llx - $power_die_llx}]
set die_core_margin_bottom [expr {$core_lly - $power_die_lly}]
set die_core_margin_right [expr {$power_die_urx - $core_urx}]
set die_core_margin_top [expr {$power_die_ury - $core_ury}]
foreach {side margin} [list \
    left $die_core_margin_left \
    bottom $die_core_margin_bottom \
    right $die_core_margin_right \
    top $die_core_margin_top] {
    if {$ring_guard_span > $margin} {
        error "M8/M9 core-ring guarded reach $ring_guard_span exceeds $side die-to-core margin $margin"
    }
}

addRing -nets {VDD} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $RING_WIDTH \
    -spacing $RING_SPACING \
    -offset $RING_OFFSET \
    -snap_wire_center_to_grid Grid

addRing -nets {VSS} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $RING_WIDTH \
    -spacing $RING_SPACING \
    -offset $vss_ring_offset \
    -snap_wire_center_to_grid Grid

# Put explicit top-level PG pins directly on the left M9 ring segments.  Their
# x-box must match the snapped addRing wire exactly; otherwise a small notch is
# created and ASAP7 reports M9 MINSTEP at the pin ends.
create_left_m9_ring_pg_pins $core_llx $core_lly $core_ury

# Upper PG mesh: M7 vertical into M8 ring, M6 horizontal into M7.
setAddStripeMode -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} \
    -layer M7 -direction vertical \
    -width $M67_WIDTH -spacing $M67_SPACING \
    -set_to_set_distance $M67_SET_PITCH \
    -start_from left -start_offset $M67_OFFSET \
    -snap_wire_center_to_grid grid

setAddStripeMode -reset
setAddStripeMode \
    -allow_jog none \
    -split_vias true \
    -via_using_exact_crossover_size false \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M7
addStripe -nets {VDD VSS} \
    -layer M6 -direction horizontal \
    -width $M67_WIDTH -spacing $M67_SPACING \
    -set_to_set_distance $M67_SET_PITCH \
    -start_from bottom -start_offset $M67_OFFSET \
    -snap_wire_center_to_grid grid

# Low-level M1/M5 core-pin PG is built after standard-cell placement.  Creating
# full-chip M4 straps and core-pin sroute here produced VDD/VSS M4 shorts in
# the latest run.

editTrim -nets {VDD VSS}
clearDrc

# Assign every top port after PG shapes exist, allowing editPin to avoid overlap.
setPinConstraint -cell $TOP -corner_to_pin_distance 8
source ./tcl/pins.tcl

# Before standard-cell placement, only special-route PG connectivity is useful.
# A full connectivity check here reports every unplaced cell pin as noise.
verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
    -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_pg.rpt
verify_drc -report ./verify_rpt/drc_after_pg.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_after_pg.rpt
assert_clean_drc_report ./verify_rpt/drc_after_pg.rpt

saveDesign ./saved/${TOP}_powerplan.enc

if {[env_flag INNOVUS_STOP_AFTER_POWER_PINS 0]} {
    puts "============================================================"
    puts "FLOW STOPPED AFTER POWER PLAN AND TOP-LEVEL PINS"
    puts "Inspect:"
    puts " - saved/${TOP}_powerplan.enc"
    puts " - verify_rpt/connectivity_after_pg.rpt"
    puts " - verify_rpt/drc_after_pg.rpt"
    puts "Continue in the same Innovus session by pasting the next PnR section."
    puts "============================================================"
    return
}

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

# Post-placement lower PG: create M1 follow-pin rails first, then stitch them
# up to the M5/M6 mesh.  This mirrors the clean SRAM lower-PG topology but
# keeps the RISC-V flow macro-free.
setSrouteMode -reset
setSrouteMode -viaConnectToShape {ring stripe}
sroute -nets {VDD VSS} \
    -connect {corePin} \
    -corePinCheckStdcellGeoms \
    -allowJogging 0 \
    -allowLayerChange 0

setAddStripeMode -reset
setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M1 \
    -stacked_via_top_layer M6

addStripe -nets {VDD VSS} \
    -layer M5 -direction vertical \
    -width $M45_WIDTH -spacing $M45_SPACING \
    -set_to_set_distance $M45_SET_PITCH \
    -start_from left -start_offset $M45_OFFSET \
    -create_pins 0 \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

editTrim -nets {VDD VSS}
clearDrc

verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
    -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_postplace_pg.rpt
verify_drc -report ./verify_rpt/drc_after_postplace_pg.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_after_postplace_pg.rpt
assert_clean_drc_report ./verify_rpt/drc_after_postplace_pg.rpt

checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_postPlace.rpt
report_timing > ./reports/timing_postPlace.rpt
report_area   > ./reports/area_postPlace.rpt
saveDesign ./saved/${TOP}_postPlace.enc

if {[env_flag INNOVUS_STOP_AFTER_PLACE 0]} {
    puts "============================================================"
    puts "FLOW STOPPED AFTER PLACEMENT AND POST-PLACE PG"
    puts "Inspect:"
    puts " - saved/${TOP}_postPlace.enc"
    puts " - verify_rpt/connectivity_after_postplace_pg.rpt"
    puts " - verify_rpt/drc_after_postplace_pg.rpt"
    puts "Continue in the same Innovus session by pasting the next PnR section."
    puts "============================================================"
    return
}

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

refinePlace
checkPlace ./verify_rpt/checkPlace_before_cts.rpt
setDesignMode \
    -bottomRoutingLayer 2 \
    -topRoutingLayer 7

# PODv2 place-opt databases must use clock_opt_design.  ccopt_design exits with
# IMPCCOPT-2440 in this Innovus version.
clock_opt_design -prefix postCTS

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

setHierMode -optStage postCTS
optDesign -prefix postCTS -postCTS -setup -hold

report_timing > ./reports/timing_postCTS.rpt
report_area   > ./reports/area_postCTS.rpt
saveDesign ./saved/${TOP}_postCTS.enc

if {[env_flag INNOVUS_STOP_AFTER_CTS 0]} {
    puts "============================================================"
    puts "FLOW STOPPED AFTER CTS"
    puts "Inspect:"
    puts " - saved/${TOP}_postCTS.enc"
    puts " - reports/timing_postCTS.rpt"
    puts "Continue in the same Innovus session by pasting the next PnR section."
    puts "============================================================"
    return
}

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
setDesignMode \
    -bottomRoutingLayer 2 \
    -topRoutingLayer 7
setNanoRouteMode -quiet \
    -route_strict_honor_route_rule true \
    -route_strictly_honor_1d_routing true \
    -route_detail_no_taper_in_layers "2:7" \
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
verify_antenna_if_enabled ./verify_rpt/antenna_after_route.rpt
assert_clean_drc_report ./verify_rpt/drc_after_route.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_after_route.rpt

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
verify_antenna_if_enabled ./verify_rpt/antenna_postRoute_final.rpt
assert_clean_drc_report ./verify_rpt/drc_postRoute_final.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_postRoute_final.rpt

if {[env_flag INNOVUS_STOP_AFTER_ROUTE 0]} {
    puts "============================================================"
    puts "FLOW STOPPED AFTER ROUTE AND FINAL ROUTE CHECKS"
    puts "Inspect:"
    puts " - saved/${TOP}_postRoute.enc"
    puts " - verify_rpt/drc_postRoute_final.rpt"
    puts " - verify_rpt/connectivity_postRoute_final.rpt"
    puts "Continue in the same Innovus session by pasting the export section."
    puts "============================================================"
    return
}

set RUN_LEGACY_METAL_FILL [env_flag INNOVUS_RUN_LEGACY_METAL_FILL 0]

if {$RUN_LEGACY_METAL_FILL} {
    # The legacy in-design fill command produces WIDTH table violations with
    # this ASAP7 educational LEF.  Keep it opt-in for experiments only.
    addMetalFill -snap -squareShape

    verify_drc -report ./verify_rpt/drc_after_metal_fill.rpt
    verifyConnectivity -type all -error 1000 -warning 100 \
        -report ./verify_rpt/connectivity_after_metal_fill.rpt
    assert_clean_drc_report ./verify_rpt/drc_after_metal_fill.rpt
    assert_clean_connectivity_report ./verify_rpt/connectivity_after_metal_fill.rpt
} else {
    write_skipped_report ./verify_rpt/drc_after_metal_fill.rpt \
        "Legacy addMetalFill skipped. Set INNOVUS_RUN_LEGACY_METAL_FILL=1 only for fill experiments, or use Pegasus/signoff fill."
    write_skipped_report ./verify_rpt/connectivity_after_metal_fill.rpt \
        "Skipped because legacy metal fill was not run."
    puts "INFO: Legacy addMetalFill skipped; routed DRC/connectivity remain the signoff gate for this run."
}

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

if {[info exists ::INNOVUS_KEEP_OPEN] && $::INNOVUS_KEEP_OPEN} {
    return
}
if {!$reuse_active_design} {
    exit
}
