# =============================================================================
# Step 06: filler, route, post-route optimization, and clean route checks.
#
# Paste after 05_cts:
#   source ./tcl/steps/06_route.tcl
# =============================================================================

riscv_step_banner "STEP 06: route and post-route checks"

setFillerMode -core $FILLER_CELLS \
    -preserveUserOrder true \
    -honorPrerouteAsObs true \
    -diffCellViol true
addFiller \
    -cell $FILLER_CELLS \
    -prefix FILLER \
    -honorPrerouteAsObs true \
    -diffCellViol true

foreach route_report {
    ./verify_rpt/drc_after_initial_route.rpt
    ./verify_rpt/connectivity_after_initial_route.rpt
    ./verify_rpt/drc_after_route.rpt
    ./verify_rpt/connectivity_after_route.rpt
    ./verify_rpt/drc_postRoute_final.rpt
    ./verify_rpt/connectivity_postRoute_final.rpt
} {
    file delete -force $route_report
}

setNanoRouteMode -reset
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
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

verify_drc -report ./verify_rpt/drc_after_initial_route.rpt
verifyConnectivity -type all -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_initial_route.rpt
if {[catch {assert_clean_drc_report ./verify_rpt/drc_after_initial_route.rpt} initial_route_drc]} {
    puts "INFO: Initial route DRC still needs post-route cleanup: $initial_route_drc"
}
assert_clean_connectivity_report ./verify_rpt/connectivity_after_initial_route.rpt
saveDesign ./saved/${TOP}_routed_initial.enc

setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -SIAware true -equivalent_waveform_model propagation
setExtractRCMode -engine postRoute -effortLevel medium

optDesign -prefix postRoute -postRoute -setup -hold
optDesign -prefix postRouteDRV -postRoute -drv
setNanoRouteMode -quiet \
    -route_with_timing_driven false \
    -route_with_si_driven false
ecoRoute -fix_drc

report_timing > ./reports/timing_postRoute.rpt
report_area   > ./reports/area_postRoute.rpt
report_power  > ./reports/power_postRoute.rpt
saveDesign ./saved/${TOP}_postRoute.enc

verify_drc -report ./verify_rpt/drc_after_route.rpt
verifyConnectivity -type all -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_route.rpt
verify_antenna_if_enabled ./verify_rpt/antenna_postRoute_final.rpt
file copy -force ./verify_rpt/drc_after_route.rpt ./verify_rpt/drc_postRoute_final.rpt
file copy -force ./verify_rpt/connectivity_after_route.rpt ./verify_rpt/connectivity_postRoute_final.rpt
assert_clean_drc_report ./verify_rpt/drc_after_route.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_after_route.rpt

riscv_step_banner "STEP 06 DONE: saved/${TOP}_postRoute.enc"

