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
prepare_innovus_sdc ./outputs/axi_ram_syn.sdc $tmp_sdc $tmp_groups 0.300

set generated_sdc [read_file $tmp_sdc]
set generated_groups [read_file $tmp_groups]
set genus_constraints [read_file ../genus/tcl/constraint.sdc]

require_contains $generated_sdc {create_clock -name "CLK" -period 1.0 -waveform {0.0 0.5}} "1ns clock"
require_contains $generated_sdc {set_clock_transition -max 0.04} "40ps clock transition in ns"
require_contains $generated_sdc {set_input_delay -clock [get_clocks CLK] -add_delay -max 0.25} "250ps input delay in ns"
require_contains $generated_sdc {set_load -pin_load 0.01} "10fF load in pF"
require_contains $generated_sdc {set_clock_uncertainty -setup 0.05} "50ps setup uncertainty in ns"
require_contains $generated_sdc {set_max_transition 0.3 [current_design]} "project transition override in MMMC SDC"
require_not_contains $generated_sdc {set_max_transition 0.5 [current_design]} "stale 500ps transition constraint"
require_not_contains $generated_sdc {set_units} "unsupported set_units"
require_not_contains $generated_sdc {group_path} "mode-local group_path"
require_contains $generated_groups {group_path -name C2C} "global C2C path group"
require_contains $genus_constraints {set_max_transition 300 [current_design]} "300ps synthesis transition margin"

file delete -force $tmp_sdc $tmp_groups

set innovus_master [read_file ./tcl/innovus.tcl]
set innovus_pnr [read_file ./tcl/innovus_pnr.tcl]
set view_definition [read_file ./tcl/viewDefinition.tcl]
set globals [read_file ./tcl/innovus.globals]
set sram_route_guard [read_file ./tcl/sram_route_guard.tcl]
set sram_signal_route_constraints [read_file ./tcl/sram_signal_route_constraints.tcl]
set sync_genus_handoff [read_file ./tcl/sync_genus_handoff.tcl]
set verify_route [read_file ./tcl/verify_route.tcl]
set add_fill_and_verify [read_file ./tcl/add_fill_and_verify.tcl]
set core_lower_pg [read_file ./tcl/core_lower_pg_nojog.tcl]
set flow_checks [read_file ./tcl/flow_checks.tcl]
set core_pg_outside [read_file ./tcl/core_pg_outside_island.tcl]
set global_upper_pg [read_file ./tcl/global_upper_pg_to_ring.tcl]

foreach flow [list $innovus_master $innovus_pnr] {
    require_contains $flow {FLOW SOURCE REVISION:} "flow source revision marker"
    require_contains $flow {set STDCELL_CORE_PG_BUILT 0} "lower-PG ownership reset"
    require_contains $flow {set SRAM_BLOCKPIN_STITCH_DONE 0} "SRAM blockPin ownership reset"
    require_contains $flow {set enc_source_continue_on_error false} "source stops on Tcl errors"
    require_contains $flow {prepare_innovus_sdc} "generated Innovus SDC before init_design"
    require_contains $flow {source ./tcl/sync_genus_handoff.tcl} "validated Genus-to-Innovus handoff"
    require_contains $flow {sync_genus_handoff} "automatic Genus netlist and SDC synchronization"
    require_contains $flow {$SIGNAL_MAX_TRANSITION_NS} "generated Innovus SDC receives the project transition limit"
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
    require_contains $flow {sram_clean_handoff_fill_v13} "flow revision for clean synthesis handoff and default metal fill"
    require_not_contains $flow {set_max_transition $SIGNAL_MAX_TRANSITION_NS [current_design]} "invalid post-init MMMC constraint override"
    require_contains $flow {-detailDrvFailureReason true} "detailed post-route DRV diagnostics"
    require_contains $flow {-detailDrvFailureReasonMaxNumNets 100} "bounded detailed DRV diagnostics"
    require_contains $flow {-setupTargetSlack 0.020} "post-route setup safety margin"
    require_contains $flow {-holdTargetSlack 0.020} "post-route hold safety margin"
    require_contains $flow {setSIMode} "legacy-UI SI command"
    require_contains $flow {-enable_delay_report true} "legacy-UI bumpy-transition diagnostics"
    require_contains $flow {-enable_glitch_report true} "legacy-UI SI glitch diagnostics"
    require_contains $flow {report_noise -bumpy_waveform -threshold 0} "post-route bumpy-transition report"
    require_contains $flow {./verify_rpt/pg_connectivity_after_cts_preopt.rpt 1 1} "bounded pre-filler PG diagnostic before postCTS optimization"
    require_contains $flow {./verify_rpt/pg_connectivity_after_postcts.rpt 1 1} "bounded pre-filler PG diagnostic after postCTS optimization"
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
    require_not_contains $flow {sram_wdata_transition_eco.tcl} "obsolete unconditional SRAM data ECO"
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
    set detailed_route_index [string first {routeDesign -globalDetail} $flow]
    if {$detailed_route_index < 0} {
        error "Missing detailed-route checkpoint"
    }
    set preroute_segment [string range $flow 0 [expr {$detailed_route_index - 1}]]
    set sram_route_constraint_index [string first {source ./tcl/sram_signal_route_constraints.tcl} $flow]
    if {$sram_route_constraint_index < 0 || $sram_route_constraint_index >= $detailed_route_index} {
        error "SRAM signal routing policy must be applied before NanoRoute"
    }
    if {![regexp {timeDesign([[:space:]]|\\)+-postRoute([[:space:]]|\\)+-hold([[:space:]]|\\)+-outDir[[:space:]]+\./reports/timing_postRoute_hold} $flow]} {
        error "Missing explicit final post-route hold report"
    }
    require_contains $flow {assert_clean_timing_summary} "post-route setup/hold and real-DRV gate"
    require_not_contains $preroute_segment {verify_pg_special_drc_or_stop} \
        "premature PG/signal interaction DRC gate before detailed routing"
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
require_contains $sram_signal_route_constraints {-bottom_preferred_routing_layer $SRAM_SIGNAL_ROUTE_BOTTOM_LAYER} "SRAM nets avoid new V3 macro-body pin-access cuts"
require_contains $sram_signal_route_constraints {-top_preferred_routing_layer $SRAM_SIGNAL_ROUTE_TOP_LAYER} "SRAM preferred routing stays below the signal top layer"
require_contains $sram_signal_route_constraints {-preferred_routing_layer_effort $SRAM_SIGNAL_ROUTE_EFFORT} "SRAM preferred routing has explicit effort"
require_contains $sram_signal_route_constraints {(^|/)(VDD|VSS|clk)$} "SRAM route policy excludes PG and clock terms"
require_contains $sync_genus_handoff {assert_genus_transition_handoff} "Genus transition-constraint handoff guard"
require_contains $sync_genus_handoff {Rerun Genus before Innovus} "actionable stale-handoff error"
require_contains $sync_genus_handoff {copy_file_if_different} "content-aware Genus artifact synchronization"
require_contains $verify_route {timing_postRoute_hold_recheck} "route recheck regenerates hold timing"
require_contains $verify_route {assert_clean_timing_summary} "route recheck gates timing and real DRVs"
require_contains $verify_route {setSIMode} "route recheck uses the legacy-UI SI command"
require_contains $verify_route {-enable_delay_report true} "route recheck enables bumpy-transition delay diagnostics"
require_contains $verify_route {-enable_glitch_report true} "route recheck enables SI glitch diagnostics"
require_contains $add_fill_and_verify {set RUN_LEGACY_METAL_FILL 1} "in-design metal fill is enabled by default"
require_contains $add_fill_and_verify {assert_clean_drc_report ./verify_rpt/drc_postroute.rpt} "metal fill requires clean routed DRC"
require_contains $add_fill_and_verify {assert_clean_connectivity_report ./verify_rpt/connectivity_postroute.rpt} "metal fill requires clean routed connectivity"
require_contains $add_fill_and_verify {./reports/timing_postFill/axi_ram_postRoute.summary.gz setup 1} "post-fill setup and real-DRV gate"
require_contains $add_fill_and_verify {./reports/timing_postFill_hold/axi_ram_postRoute_hold.summary.gz hold} "post-fill hold gate"
require_contains $add_fill_and_verify {saveDesign ./saved/axi_ram_filled.enc} "filled checkpoint save"
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
require_contains $flow_checks {proc assert_expected_unfilled_pg_connectivity_report} "bounded pre-filler M1 rail-gap classifier"
require_contains $flow_checks {proc defer_preroute_pg_drc_check} "pre-route PG/signal interaction deferral"
require_contains $flow_checks {NOT_RUN_BEFORE_DETAILED_ROUTE} "deferred pre-route DRC report status"
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
    require_contains $flow_text {defer_preroute_pg_drc_check} "pre-route PG/signal interaction DRC must be deferred"
    require_contains $flow_text {./verify_rpt/pg_drc_after_cts_preopt.rpt} "deferred DRC evidence immediately after CTS"
    require_contains $flow_text {./verify_rpt/pg_drc_after_postcts.rpt} "deferred DRC evidence after postCTS optimization"
    require_contains $flow_text {./verify_rpt/pg_drc_after_filler.rpt} "deferred DRC evidence after filler insertion"
    require_contains $flow_text {./verify_rpt/drc_postroute.rpt} "stale post-route DRC cleanup and final signoff report"
    require_contains $flow_text {./verify_rpt/connectivity_postroute.rpt} "stale post-route connectivity cleanup and final signoff report"
}
require_contains $innovus_master {./verify_rpt/drc_after_fill.rpt} "stale post-fill DRC cleanup"
require_contains $innovus_master {./verify_rpt/connectivity_after_fill.rpt} "stale post-fill connectivity cleanup"
require_contains $innovus_master {./saved/axi_ram_filled.enc.dat} "stale filled checkpoint cleanup"
require_contains $core_pg_outside {-stacked_via_bottom_layer M5} "M6 mesh connects down to M5 taps"
require_contains $core_pg_outside {set core_m6_right_llx $SRAM_ISLAND_URX} "M6 mesh handoff begins at the SRAM body edge"
require_contains $global_upper_pg {-stacked_via_bottom_layer M7} "M8 mesh connects down to M7"
require_contains $global_upper_pg {-stacked_via_top_layer M8} "M8 mesh does not create M9-driven M7 patches"

source ./tcl/flow_checks.tcl

proc write_cts_test_report {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

proc write_cts_gzip_test_report {path text} {
    set fp [open $path wb]
    fconfigure $fp -translation binary
    puts -nonewline $fp [zlib gzip $text]
    close $fp
}

set expected_gap_report ./reports/__tmp_expected_pg_gap.rpt
set upper_dangling_report ./reports/__tmp_upper_pg_dangling.rpt
set short_report ./reports/__tmp_pg_short.rpt
set excessive_gap_report ./reports/__tmp_excessive_pg_gap.rpt
set clean_pg_baseline ./reports/__tmp_clean_pg_baseline.rpt
set deferred_drc_report ./reports/__tmp_deferred_pg_drc.rpt
set clean_timing_summary ./reports/__tmp_clean_timing.summary.gz
set drv_timing_summary ./reports/__tmp_drv_timing.summary.gz
set bad_hold_summary ./reports/__tmp_bad_hold.summary.gz

write_cts_test_report $expected_gap_report {
Net VDD, Pin Pin: CTS_BUF/VDD;: has an unconnected terminal at (1.0, 1.0) (2.0, 2.0)
Net VDD: has special routes with opens at (0.0, 0.0) (2.0, 2.0)
Net VDD: dangling Wire at (1.0, 1.0) (1.0, 1.0) on layer: M1
    1 Problem(s) (IMPVFC-96): Terminal(s) are not connected.
    1 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.
    1 Problem(s) (IMPVFC-94): The net has dangling wire(s).
}
assert_expected_unfilled_pg_connectivity_report $expected_gap_report

write_cts_test_report $upper_dangling_report {
Net VSS: dangling Wire at (1.0, 1.0) (1.0, 1.0) on layer: M6
    1 Problem(s) (IMPVFC-94): The net has dangling wire(s).
}
if {![catch {assert_expected_unfilled_pg_connectivity_report $upper_dangling_report}]} {
    error "Pre-filler PG classifier accepted an upper-layer dangling wire"
}

write_cts_test_report $short_report {
Net VDD: shorted to Net VSS at (1.0, 1.0)
    1 Problem(s) (IMPVFC-91): The net is shorted.
}
if {![catch {assert_expected_unfilled_pg_connectivity_report $short_report}]} {
    error "Pre-filler PG classifier accepted a PG short"
}

write_cts_test_report $excessive_gap_report {
Net VDD: dangling Wire at (1.0, 1.0) (1.0, 1.0) on layer: M1
    501 Problem(s) (IMPVFC-94): The net has dangling wire(s).
}
if {![catch {assert_expected_unfilled_pg_connectivity_report $excessive_gap_report}]} {
    error "Pre-filler PG classifier accepted more than 500 gap markers"
}

write_cts_test_report $clean_pg_baseline {No DRC violations were found
}
defer_preroute_pg_drc_check \
    $deferred_drc_report unit-test $clean_pg_baseline
require_contains [read_file $deferred_drc_report] \
    {NOT_RUN_BEFORE_DETAILED_ROUTE} \
    "machine-readable deferred pre-route DRC status"

set clean_timing_text {
|    Violating Paths:|    0    |    0    |
|   max_cap      |      0 (0)       |   0.000    |      0 (0)       |
|   max_tran     |      0 (0)       |   0.000    |      4 (4)       |
|   max_fanout   |      0 (0)       |     0      |      2 (2)       |
|   max_length   |      0 (0)       |     0      |      0 (0)       |
}
write_cts_gzip_test_report $clean_timing_summary $clean_timing_text
assert_clean_timing_summary $clean_timing_summary setup 1

set drv_timing_text [string map {
    {|   max_tran     |      0 (0)}
    {|   max_tran     |      1 (8)}
} $clean_timing_text]
write_cts_gzip_test_report $drv_timing_summary $drv_timing_text
if {![catch {assert_clean_timing_summary $drv_timing_summary setup 1}]} {
    error "Timing guard accepted a real max-transition violation"
}

write_cts_gzip_test_report $bad_hold_summary {
|    Violating Paths:|    1    |    0    |
}
if {![catch {assert_clean_timing_summary $bad_hold_summary hold}]} {
    error "Timing guard accepted a violating hold path"
}

file delete -force \
    $expected_gap_report \
    $upper_dangling_report \
    $short_report \
    $excessive_gap_report \
    $clean_pg_baseline \
    $deferred_drc_report \
    $clean_timing_summary \
    $drv_timing_summary \
    $bad_hold_summary

puts "PASS: Innovus CTS/static unit checks"
