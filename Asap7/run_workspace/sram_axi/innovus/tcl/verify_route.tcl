############################################################
## Re-run after every post-route ECO repair
## Intended for the active routed Innovus session.
############################################################

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

set ROUTE_REPORTS_CLEAN 0
if {[catch {
    assert_clean_drc_report ./verify_rpt/drc_postroute.rpt
    assert_clean_connectivity_report ./verify_rpt/connectivity_postroute.rpt
    set ROUTE_REPORTS_CLEAN 1
} route_verify_error]} {
    puts stderr "Route recheck is not clean: $route_verify_error"
    puts stderr "Do not add metal fill yet."
    error $route_verify_error
}

timeDesign \
    -postRoute \
    -outDir ./reports/timing_postRoute_recheck

saveDesign ./saved/axi_ram_routed.enc

puts "Inspect DRC, antenna and connectivity reports."
puts "Route recheck is clean enough to enable ROUTE_VERIFY_CLEAN."
