############################################################
## Static checks for Innovus SDC unit handling and CTS guards.
############################################################

proc read_file {path} {
    set fp [open $path r]
    set text [read $fp]
    close $fp
    return $text
}

proc require_contains {text pattern label} {
    if {[string first $pattern $text] < 0} {
        error "Missing $label: $pattern"
    }
}

proc require_not_contains {text pattern label} {
    if {[string first $pattern $text] >= 0} {
        error "Unexpected $label: $pattern"
    }
}

proc require_order {text first_pattern second_pattern label} {
    set first_index [string first $first_pattern $text]
    set second_index [string first $second_pattern $text]
    if {$first_index < 0 || $second_index < 0 || $first_index >= $second_index} {
        error "Invalid order for $label"
    }
}

source ./tcl/prepare_innovus_sdc.tcl

set tmp_sdc ./reports/__tmp_innovus_unit_check.sdc
set tmp_groups ./reports/__tmp_innovus_groups_check.tcl
prepare_innovus_sdc ./outputs/axi_ram_syn.sdc $tmp_sdc $tmp_groups

set generated_sdc [read_file $tmp_sdc]
set generated_groups [read_file $tmp_groups]

require_contains $generated_sdc {create_clock -name "CLK" -period 1.0 -waveform {0.0 0.5}} "1ns clock"
require_contains $generated_sdc {set_clock_transition -max 0.04} "40ps clock transition in ns"
require_contains $generated_sdc {set_input_delay -clock [get_clocks CLK] -add_delay -max 0.25} "250ps input delay in ns"
require_contains $generated_sdc {set_load -pin_load 0.01} "10fF load in pF"
require_contains $generated_sdc {set_clock_uncertainty -setup 0.05} "50ps setup uncertainty in ns"
require_not_contains $generated_sdc {set_units} "unsupported set_units"
require_not_contains $generated_sdc {group_path} "mode-local group_path"
require_contains $generated_groups {group_path -name C2C} "global C2C path group"

file delete -force $tmp_sdc $tmp_groups

set innovus_master [read_file ./tcl/innovus.tcl]
set innovus_pnr [read_file ./tcl/innovus_pnr.tcl]
set view_definition [read_file ./tcl/viewDefinition.tcl]
set globals [read_file ./tcl/innovus.globals]
set sram_route_guard [read_file ./tcl/sram_route_guard.tcl]
set core_lower_pg [read_file ./tcl/core_lower_pg_nojog.tcl]
set flow_checks [read_file ./tcl/flow_checks.tcl]
set core_pg_outside [read_file ./tcl/core_pg_outside_island.tcl]
set global_upper_pg [read_file ./tcl/global_upper_pg_to_ring.tcl]

foreach flow [list $innovus_master $innovus_pnr] {
    require_contains $flow {FLOW SOURCE REVISION:} "flow source revision marker"
    require_contains $flow {set STDCELL_CORE_PG_BUILT 0} "lower-PG ownership reset"
    require_contains $flow {set SRAM_BLOCKPIN_STITCH_DONE 0} "SRAM blockPin ownership reset"
    require_contains $flow {set enc_source_continue_on_error false} "source stops on Tcl errors"
    require_contains $flow {prepare_innovus_sdc $SYN_SDC_FILE $INNOVUS_SDC_FILE $INNOVUS_GROUP_PATH_FILE} "generated Innovus SDC before init_design"
    require_contains $flow {source $INNOVUS_GROUP_PATH_FILE} "global group_path source after init_design"
    require_contains $flow {-place_global_reorder_scan false} "scan reorder disabled without scan DEF"
    require_contains $flow {place_opt_design
refinePlace} "explicit legalization immediately after placement optimization"
    require_contains $flow {assert_clean_check_place ./verify_rpt/checkPlace_after_place.rpt} "post-place checkPlace guard"
    require_contains $flow {assert_clean_check_place ./verify_rpt/checkPlace_before_cts.rpt} "pre-CTS checkPlace guard"
    require_contains $flow {assert_clean_check_place ./verify_rpt/checkPlace_after_postcts.rpt} "post-CTS legalization guard"
    require_contains $flow {-bottomRoutingLayer 2} "DesignMode bottom routing layer"
    require_contains $flow {-topRoutingLayer 7} "DesignMode top routing layer"
    require_not_contains $flow {-routeBottomRoutingLayer} "obsolete NanoRoute bottom layer option"
    require_not_contains $flow {-routeTopRoutingLayer} "obsolete NanoRoute top layer option"
    require_contains $flow {set_ccopt_property -net_type leaf  target_max_trans 35ps} "SRAM-aware leaf CTS transition target"
    require_contains $flow {set_ccopt_property -net_type trunk target_max_trans 40ps} "trunk CTS transition target"
    require_contains $flow {set_ccopt_property -net_type top   target_max_trans 40ps} "top CTS transition target"
    require_contains $flow {set_ccopt_property target_skew 40ps} "CTS skew target"
    require_contains $flow {set_ccopt_property routing_top_min_fanout 16} "shared SRAM clock trunk uses the top routing threshold"
    require_contains $flow {configure_sram_clock_top_routing $SRAM_PTRS clk} "SRAM macro clock-pin validation"
    require_contains $flow {BUFx24_ASAP7_75t_R} "strong RVT CTS buffer for SRAM clock sinks"
    require_contains $flow {BUFx24_ASAP7_75t_L} "strong LVT CTS buffer for SRAM clock slew recovery"
    require_contains $flow {-ewm_type moments} "moment EWM pre-route"
    require_contains $flow {./verify_rpt/pg_connectivity_after_cts_preopt.rpt 1} "read-only PG check before postCTS optimization"
    require_contains $flow {./verify_rpt/pg_connectivity_after_postcts.rpt 1} "read-only PG check after postCTS optimization"
    require_contains $flow {verify_core_pg_after_filler_nojog} "post-filler PG verification without broad reconnect"
    require_contains $flow {./verify_rpt/pg_connectivity_after_filler.rpt} "post-filler PG connectivity report"
    require_contains $flow {./verify_rpt/pg_connectivity_after_postroute_opt.rpt 1} "read-only post-route-opt PG guard"
    require_contains $flow {addFiller} "explicit filler insertion"
    require_contains $flow {-cell $FILLERCells} "explicit filler cell list"
    require_contains $flow {setFillerMode -reset} "idempotent filler-mode reset"
    require_contains $flow {-add_fillers_with_drc false} "filler insertion cannot force DRC-violating cells"
    require_not_contains $flow {-preserveUserOrder true} "fitGap-incompatible filler order setting"
    require_not_contains $flow {-fixDRC} "repair-only option on initial filler insertion"
    require_contains $flow {assert_filler_inserted FILLER} "filler insertion guard"
    require_contains $flow {checkFiller -file ./verify_rpt/checkFiller_after_filler.rpt} "post-insertion filler gap report"
    require_contains $flow {assert_clean_check_place ./verify_rpt/checkPlace_after_filler.rpt} "post-filler placement guard"
    require_contains $flow {verify_antenna_if_enabled ./verify_rpt/antenna_postroute.rpt} "modern optional antenna check"
    require_contains $flow {source ./tcl/core_lower_pg_nojog.tcl} "lower PG source"
    require_contains $flow {source ./tcl/core_pg_outside_island.tcl} "outside-island M6/M7 PG source"
    require_contains $flow {source ./tcl/global_upper_pg_to_ring.tcl} "upper PG source"
    require_contains $flow {-layer_range {M4 M5}} "SRAM M4/M5 pin-tap interface DRC range"
    require_contains $flow {-layer_range {M6 M9}} "global upper-PG DRC range"
    require_contains $flow {-report ./verify_rpt/sram_m4_interface_drc.rpt} "separate SRAM M4/M5 interface DRC report"
    require_contains $flow {-report ./verify_rpt/pg_drc_after_trim.rpt} "post-place actionable M6-M9 PG DRC report"
    require_contains $flow {-report ./verify_rpt/pg_drc_after_trim_full.rpt} "post-place full M1-M9 PG DRC report"
    require_contains $flow {assert_clean_pg_special_drc_report ./verify_rpt/sram_m4_interface_drc.rpt} "SRAM M4/M5 interface DRC guard"
    require_contains $flow {assert_clean_pg_special_drc_report ./verify_rpt/pg_drc_after_trim.rpt} "M6-M9 PG DRC guard before placed save"
    require_contains $flow {assert_clean_pg_special_drc_report ./verify_rpt/pg_drc_after_trim_full.rpt} "full M1-M9 PG DRC guard before placed save"
    require_not_contains $flow {post_place_pg_drc_error} "obsolete combined DRC catch that suppresses the second report"
    require_contains $flow {-cell $DESIGN} "top-cell name on setPinConstraint"
    require_contains $flow {-place_global_uniform_density false} "compact SRAM-wrapper placement mode"

    set postcts_opt {-prefix postCTS}
    set postcts_check {checkPlace ./verify_rpt/checkPlace_after_postcts.rpt}
    require_order $flow {clock_opt_design} \
        {checkPlace ./verify_rpt/checkPlace_after_cts.rpt} \
        "CTS legalization before the CTS placement check"
    require_order $flow \
        {checkPlace ./verify_rpt/checkPlace_after_cts.rpt} \
        $postcts_opt \
        "CTS placement/PG preparation before postCTS optimization"
    require_order $flow $postcts_opt $postcts_check \
        "postCTS optimization before final placement check"

    set after_cts_check_index [string first {checkPlace ./verify_rpt/checkPlace_after_cts.rpt} $flow]
    set postcts_opt_index [string first $postcts_opt $flow]
    set postcts_check_index [string first $postcts_check $flow]
    set preopt_pg_drc_index [string first {./verify_rpt/pg_drc_after_cts_preopt.rpt} $flow $after_cts_check_index]
    set postcts_pg_drc_index [string first {./verify_rpt/pg_drc_after_postcts.rpt} $flow $postcts_check_index]
    if {$preopt_pg_drc_index < 0 || $preopt_pg_drc_index >= $postcts_opt_index} {
        error "Invalid order for full PG DRC before postCTS optimization"
    }
    if {$postcts_pg_drc_index < 0 || $postcts_pg_drc_index <= $postcts_check_index} {
        error "Invalid order for full PG DRC after postCTS placement"
    }
    set postcts_segment [string range $flow $postcts_opt_index $postcts_check_index]
    require_not_contains $postcts_segment {refinePlace} \
        "timing-destructive legalization after postCTS optimization"
}

require_contains $view_definition {-sdc_files $INNOVUS_SDC_FILE} "MMMC uses normalized SDC"
require_contains $view_definition {setLibraryUnit -time 1ns -cap 1pf} "MMMC library units"
require_contains $globals {setLibraryUnit -time 1ns -cap 1pf} "global library units"
require_contains $sram_route_guard {set SRAM_ROUTE_GUARD_ENABLE 0} "SRAM route guard defaults to LEF OBS instead of M6/M7 signal blockage"
require_contains $sram_route_guard {createRouteBlk} "optional SRAM signal-only macro-body route blockage"
require_contains $sram_route_guard {-exceptpgnet} "optional SRAM route blockage exempts PG special routes"
require_contains $sram_route_guard {set SRAM_ROUTE_GUARD_LAYERS {M6 M7}} "optional SRAM route guard avoids M4/M5 pin-access layers"
require_contains $sram_route_guard {deleteRouteBlk} "SRAM route guard is idempotent when sourced before place and route"
require_contains $sram_route_guard {dbGet -e -p top.fPlan.rBlkgs.name} "route guard avoids an empty-delete IMPFP-6001 warning"
require_contains $sram_route_guard {-earlyGlobalReverseDirection $sram_egr_reverse_regions} "optional SRAM M5 early-global route reservation"
require_contains $core_lower_pg {-stacked_via_top_layer M5} "lower PG stops at M5"
require_contains $core_lower_pg {STDCELL_PG_AREA_OVERHANG} "lower PG expands area boxes for ASAP7 std-cell M1 pin overhang"
require_contains $core_lower_pg {set area_nets {VSS VDD}} "SRAM-edge M5 tap uses the VDD lane that overlaps bottom-row VDD pins"
require_contains $core_lower_pg {setSrouteMode -reset} "lower PG must reset stale blockPin sroute mode"
require_contains $core_lower_pg {set STDCELL_CORE_PG_BUILT 1} "lower PG single-owner marker"
require_not_contains $core_lower_pg {-stacked_via_top_layer M8} "unsafe direct M1-to-M8 stack"
require_contains $innovus_master {connect_core_pg_pins_nojog ./verify_rpt/pg_connectivity_after_trim.rpt} "post-place PG trim/reconnect guard in master flow"
require_contains $innovus_pnr {connect_core_pg_pins_nojog ./verify_rpt/pg_connectivity_after_trim.rpt} "post-place PG trim/reconnect guard in PnR flow"
require_contains $flow_checks {proc connect_core_pg_pins_nojog} "shared post-CTS/filler PG verification proc"
require_contains $flow_checks {proc configure_sram_clock_top_routing} "shared SRAM macro-clock routing policy"
require_not_contains $flow_checks {routing_top_fanout_count $fanout_count} "invalid macro stop-pin top-fanout weighting"
require_contains $flow_checks {global routing_top_min_fanout setting} "shared macro-clock top-routing policy"
require_contains $flow_checks {proc verify_core_pg_after_filler_nojog} "read-only post-filler PG verification"
require_contains $flow_checks {proc verify_pg_special_drc_or_stop} "shared PG special DRC guard proc"
require_contains $flow_checks {-check_only special} "PG DRC guard must check special-route DRC only"
require_contains $flow_checks {No DRC violations were found} "PG DRC guard must accept Innovus clean-report wording"
require_not_contains $flow_checks {-connect {floatingStripe}} "floating PG auto-stitch is forbidden"
require_not_contains $flow_checks {-connect {blockPin}} "fallback SRAM blockPin routing is forbidden"
require_contains $flow_checks {setSrouteMode -reset} "shared PG reconnect must reset stale sroute mode"
require_contains $flow_checks {-corePinLayer M1} "PG refresh is restricted to standard-cell M1 core pins"
require_not_contains $flow_checks {-corePinMaxViaScale} "same-layer M1 refresh must not configure an unused via scale"
require_contains $flow_checks {post_insertion_checkpoint} "read-only post-insertion PG checkpoint control"
require_contains $flow_checks {if {$core_pg_is_built}} "post-build PG verification must bypass corePin sroute"
require_contains $flow_checks {inserted cells inherit the existing continuous M1 followpins by overlap} "CTS/filler PG verification stays read-only"
require_contains $flow_checks {Post-insertion PG checkpoint is read-only: editTrim skipped.} "post-insertion PG verification must not trim existing geometry"
require_contains $flow_checks {pg_core_handoff_is_deferred} "stage-aware pre-placement PG connectivity policy"
require_contains $flow_checks {SRAM_BLOCKPIN_STITCH_DONE} "single-owner SRAM blockPin stitch"
require_contains $flow_checks {-allPGPinPort -noUnroutedNet} "strict final verification checks every SRAM PG port"
require_contains $flow_checks {Deterministic SRAM M5 edge taps were not built} "missing deterministic SRAM access is fatal"
require_contains $flow_checks {pg_top_level_owned_drc_areas} "hierarchical PG DRC scope builder"
require_contains $flow_checks {global SRAM_PIN_TAP_AREAS} "deterministic M5 tap corridors are included in PG DRC scope"
require_contains $flow_checks {CorePin reconnect skipped} "duplicate corePin via prevention"
foreach flow_text [list $innovus_master $innovus_pnr] {
    require_contains $flow_text {./verify_rpt/pg_drc_after_cts_preopt.rpt} "full PG DRC immediately after CTS"
    require_contains $flow_text {./verify_rpt/pg_drc_after_postcts.rpt} "full PG DRC after postCTS optimization"
}
require_contains $core_pg_outside {-stacked_via_bottom_layer M5} "M6 mesh connects down to M5 taps"
require_contains $core_pg_outside {set core_m6_right_llx $SRAM_ISLAND_URX} "M6 mesh handoff begins at the SRAM body edge"
require_contains $global_upper_pg {-stacked_via_bottom_layer M7} "M8 mesh connects down to M7"
require_contains $global_upper_pg {-stacked_via_top_layer M8} "M8 mesh does not create M9-driven M7 patches"

puts "PASS: Innovus CTS/static unit checks"
