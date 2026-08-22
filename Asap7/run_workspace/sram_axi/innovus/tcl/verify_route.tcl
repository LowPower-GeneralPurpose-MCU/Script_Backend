############################################################
## Re-run after every post-route ECO repair
## Intended for the active routed Innovus session.
############################################################

set_si_mode -enable_delay_report true

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

report_noise -bumpy_waveform -threshold 0 \
    > ./reports/bumpy_transition_postRoute_recheck.rpt

set ROUTE_REPORTS_CLEAN 0
if {[catch {
    assert_clean_drc_report ./verify_rpt/drc_postroute.rpt
    assert_clean_connectivity_report ./verify_rpt/connectivity_postroute.rpt
    assert_clean_timing_summary \
        ./reports/timing_postRoute_recheck/axi_ram_postRoute.summary.gz setup 1
    assert_clean_timing_summary \
        ./reports/timing_postRoute_hold_recheck/axi_ram_postRoute_hold.summary.gz hold
    set ROUTE_REPORTS_CLEAN 1
} route_verify_error]} {
    puts stderr "Route recheck is not clean: $route_verify_error"
    puts stderr "Do not add metal fill yet."
    error $route_verify_error
}

saveDesign ./saved/axi_ram_routed.enc

puts "Inspect DRC, antenna, connectivity, setup, hold and DRV reports."
puts "Route recheck is clean enough to enable ROUTE_VERIFY_CLEAN."
