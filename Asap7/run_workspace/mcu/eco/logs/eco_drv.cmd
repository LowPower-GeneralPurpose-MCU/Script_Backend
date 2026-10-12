#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Mon Oct 12 20:17:12 2026                
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
restoreDesign ./saved/top_soc_postRoute.enc.dat top_soc
setMultiCpuUsage -acquireLicense 1 -localCpu 1
setDistributeHost -local
set_timing_derate -delay_corner $corner $side -cell_delay -cell_check  $factor $sram_insts
set_timing_derate -delay_corner $corner $side -cell_delay -cell_check  $factor $sram_insts
set_timing_derate -delay_corner dc_ff -early -cell_delay  $factor $lib_cells
report_timing_derate > $derate_rpt
report_timing_derate -delay_corner dc_ff >> $derate_rpt
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
setExtractRCMode -engine postRoute -effortLevel high -coupled true
setExtractRCMode -lefTechFileMap /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/innovus/tcl/asap7_lef_to_qrc_layers.map
timeDesign -postRoute -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_pre -prefix pre
setOptMode -fixCap true -fixTran true -fixFanoutLoad true -setupTargetSlack 0.020 -holdTargetSlack 0.020
setOptMode -drcMargin 0.25
optDesign -postRoute -setup -hold -drv -prefix eco
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
setEcoMode -batchMode true -refinePlace false -updateTiming false -honorFixedNetWire false
ecoAddRepeater -term cg_cpu/g16__6260/B -cell HB4xp67_ASAP7_75t_R
ecoAddRepeater -term cg_dbg/g15__4319/B -cell HB4xp67_ASAP7_75t_R
ecoAddRepeater -term cg_ascon/g15__2398/B -cell HB4xp67_ASAP7_75t_R
ecoAddRepeater -term cg_cordic/g15__5107/B -cell HB4xp67_ASAP7_75t_R
setEcoMode -batchMode false -refinePlace true -updateTiming true -honorFixedNetWire true
refinePlace
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
report_timing -early -through $latch/Q  -max_paths 1 -collection
ecoRoute
ecoRoute -fix_drc
setOptMode -drcMargin 0.0
timeDesign -postRoute -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_eco -prefix eco
timeDesign -postRoute -hold -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_eco_hold -prefix eco
clearDrc
verifyConnectivity -net {VDD VSS} -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_eco_pg.rpt
clearDrc
verify_drc -limit 500000 -report ./verify_rpt/drc_eco.rpt
verifyConnectivity -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_eco.rpt
saveDesign ./saved/top_soc_postRoute_eco.enc
