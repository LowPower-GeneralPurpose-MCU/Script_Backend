############################################################
## Re-run after every post-route ECO repair
## Intended for the active routed Innovus session.
############################################################

set ROUTE_REPORTS_CLEAN 0

setSIMode \
    -enable_delay_report true \
    -enable_glitch_report true

setNanoRouteMode -quiet \
    -route_with_timing_driven true \
    -route_with_si_driven true

ecoRoute -fix_drc

verify_pg_connectivity_or_stop ./verify_rpt/pg_connectivity_after_verify_route_pg.rpt

verify_drc \
    -report ./verify_rpt/drc_postroute.rpt

verify_antenna_if_enabled ./verify_rpt/antenna_postroute.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_postroute.rpt

timeDesign \
    -postRoute \
    -outDir ./reports/timing_postRoute_recheck

timeDesign \
    -postRoute \
    -hold \
    -outDir ./reports/timing_postRoute_hold_recheck

set postroute_recheck_si_report \
    ./reports/timing_postRoute_recheck/axi_ram_postRoute.SI_Glitches.rpt.gz
publish_si_glitch_report \
    $postroute_recheck_si_report \
    ./reports/si_glitch_postRoute_recheck.rpt

report_noise -bumpy_waveform -threshold 0 \
    > ./reports/bumpy_transition_postRoute_recheck.rpt

if {[catch {
    assert_clean_drc_report ./verify_rpt/drc_postroute.rpt
    assert_clean_connectivity_report ./verify_rpt/connectivity_postroute.rpt
    assert_clean_timing_summary \
        ./reports/timing_postRoute_recheck/axi_ram_postRoute.summary.gz setup 1
    assert_clean_timing_summary \
        ./reports/timing_postRoute_hold_recheck/axi_ram_postRoute_hold.summary.gz hold
    assert_si_glitch_policy $postroute_recheck_si_report route-recheck
    set ROUTE_REPORTS_CLEAN 1
} route_verify_error]} {
    puts stderr "Route recheck is not clean: $route_verify_error"
    puts stderr "Do not add metal fill yet."
}

saveDesign ./saved/axi_ram_routed.enc

puts "Inspect DRC, antenna, connectivity, setup, hold, DRV and SI glitch reports."
if {$ROUTE_REPORTS_CLEAN} {
    puts "Route recheck is clean enough to enable ROUTE_VERIFY_CLEAN."
} else {
    puts "Route recheck failed; ROUTE_VERIFY_CLEAN must remain disabled."
}
