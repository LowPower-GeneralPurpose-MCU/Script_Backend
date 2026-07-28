############################################################
## Re-run after every post-route ECO repair
## Intended for the active routed Innovus session.
############################################################

ecoRoute -fix_drc

verify_drc \
    -report ./verify_rpt/drc_postroute.rpt

verifyProcessAntenna \
    -report ./verify_rpt/antenna_postroute.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_postroute.rpt

timeDesign \
    -postRoute \
    -outDir ./reports/timing_postRoute_recheck

saveDesign ./saved/axi_ram_routed.enc

puts "Inspect DRC, antenna and connectivity reports."
puts "Do not add metal fill until every violation is resolved."
