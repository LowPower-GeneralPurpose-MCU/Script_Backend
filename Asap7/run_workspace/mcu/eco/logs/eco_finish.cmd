#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Mon Oct 12 21:39:33 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v23.14-s088_1 (64bit) 02/28/2025 12:25 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 23.14-s088_1 NR250219-0822/23_14-UB (database version 18.20.661) {superthreading v2.20}
#@(#)CDS: AAE 23.14-s018 (64bit) 02/28/2025 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 23.14-s036_1 () Feb 22 2025 01:17:26 ( )
#@(#)CDS: SYNTECH 23.14-s010_1 () Feb 19 2025 23:56:49 ( )
#@(#)CDS: CPE v23.14-s082
#@(#)CDS: IQuantus/TQuantus 23.1.1-s336 (64bit) Mon Jan 20 22:11:00 PST 2025 (Linux 3.10.0-693.el7.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
getVersion
getVersion
restoreDesign ./saved/top_soc_postRoute_eco.enc.dat top_soc
setMultiCpuUsage -acquireLicense 1 -localCpu 1
setDistributeHost -local
setFillerMode -reset
setFillerMode -core {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R} -add_fillers_with_drc false -fitGap true -honorPrerouteAsObs true -diffCellViol true
addFiller -cell {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R} -prefix FILLER -honorPrerouteAsObs true -diffCellViol true
globalNetConnect VDD -type pgpin -pin VDD -inst * -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -override
globalNetConnect VDD -type tiehi -inst * -override
globalNetConnect VSS -type tielo -inst * -override
applyGlobalNets
checkPlace ./verify_rpt/checkPlace_final.rpt
saveDesign ./saved/top_soc_prefill.enc
clearDrc
verify_drc -limit 500000 -report ./verify_rpt/drc_final.rpt
verifyConnectivity -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_final.rpt
verifyWellTap -cell TAPCELL_ASAP7_75t_R -rule 30.0 -report ./verify_rpt/welltap_final.rpt
clearDrc
verify_drc -limit 500000 -report ./verify_rpt/drc_fill.rpt
verifyMetalDensity -layer M5 -report ./verify_rpt/density_final.rpt
verifyMetalDensity -layer {M1 M2 M3 M4 M5 M6 M7 M8 M9 Pad} -report ./verify_rpt/density_all.rpt
saveDesign ./saved/top_soc_final.enc
timeDesign -postRoute -outDir ./reports/timing_final -prefix final
timeDesign -postRoute -hold -outDir ./reports/timing_final_hold -prefix final
set_power_analysis_mode -analysis_view view_tt
report_power -outfile ./reports/power_final.rpt
report_area > ./reports/area_final.rpt
reportGateCount -limit 0 -level 2 -outfile ./reports/gateCount.rpt
summaryReport -noHtml -outfile ./reports/summary_final.rpt
