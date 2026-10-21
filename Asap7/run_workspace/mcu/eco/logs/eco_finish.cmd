#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Wed Oct 21 01:07:56 2026                
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
restoreDesign ./saved/top_soc_postRoute_ecofill.enc.dat top_soc
setMultiCpuUsage -acquireLicense 1 -localCpu 1
setDistributeHost -local
set_timing_derate -delay_corner $corner $side -cell_delay -cell_check  $factor $sram_insts
set_timing_derate -delay_corner $corner $side -cell_delay -cell_check  $factor $sram_insts
set_timing_derate -delay_corner dc_ff -early -cell_delay  $factor $lib_cells
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
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
extractRC
rcOut -spef ./outputs/top_soc_pnr_rc_typ.spef -rc_corner rc_typ
rcOut -spef ./outputs/top_soc_pnr_rc_ss.spef -rc_corner rc_ss
rcOut -spef ./outputs/top_soc_pnr_rc_ff.spef -rc_corner rc_ff
write_sdf -view view_ss ./outputs/${TOP}_pnr_ss.sdf
write_sdf -view view_ff ./outputs/${TOP}_pnr_ff.sdf
writeTimingCon ./outputs/top_soc_pnr.sdc
saveNetlist ./outputs/top_soc_pnr.v -excludeLeafCell
saveNetlist ./outputs/top_soc_pnr_pg.v -includePowerGround -includePhysicalInst -excludeLeafCell
createPGPin VDD -geom M8 0.862 356.836 564.73 357.316 -geom M9 0.836 0.842 1.316 357.31 -geom M9 564.276 0.842 564.756 357.31 -geom M8 0.862 0.836 564.73 1.316
createPGPin VDD -geom M8 0.862 356.836 564.73 357.316
createPGPin VDD -geom M9 0.836 0.842 1.316 357.31
createPGPin VDD -geom M9 564.276 0.842 564.756 357.31
createPGPin VDD -geom M8 0.862 0.836 564.73 1.316
createPGPin VSS -geom M8 0.222 357.476 565.37 357.956 -geom M9 0.196 0.202 0.676 357.95 -geom M9 564.916 0.202 565.396 357.95 -geom M8 0.222 0.196 565.37 0.676
createPGPin VSS -geom M8 0.222 357.476 565.37 357.956
createPGPin VSS -geom M9 0.196 0.202 0.676 357.95
createPGPin VSS -geom M9 564.916 0.202 565.396 357.95
createPGPin VSS -geom M8 0.222 0.196 565.37 0.676
defOut -floorplan -netlist -routing ./outputs/top_soc_pnr.def
setStreamOutMode -labelAllPinShape true -pinTextOrientation automatic -virtualConnection false -textSize 1
streamOut ./outputs/top_soc.gds -mapFile ./outputs/top_soc_gds.map -merge {/home/user1/Desktop/asap7/asap7sc7p5t_28/GDS/asap7sc7p5t_28_R_220121a.gds /home/user1/Desktop/asap7/asap7sc7p5t_28/GDS/asap7sc7p5t_28_L_220121a.gds /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/innovus/sram_gds/srambank_256x4x32_6t122.gds /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/innovus/sram_gds/srambank_128x4x20_6t122.gds} -units 2000 -dieAreaAsBoundary
write_lef_abstract -noCutObs ./outputs/top_soc.lef
