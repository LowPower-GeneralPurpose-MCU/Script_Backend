#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Tue Aug 11 23:56:11 2026                
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
set auto_file_dir /tmp/user1/innovus_riscv_1729083
setDesignMode -process 7
setMultiCpuUsage -acquireLicense 8
setMultiCpuUsage -localCpu 8
setDistributeHost -local
set init_design_uniquify 1
set init_lef_file {/home/user1/Desktop/asap7/asap7sc7p5t_28/techlef_misc/asap7_tech_4x_201209.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_R_4x_220121a.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_L_4x_220121a.lef}
set ::TimeLib::tsgMarkCellLatchConstructFlag 1
set conf_qxconf_file NULL
set conf_qxlib_file NULL
set defHierChar /
set distributed_client_message_echo 1
set distributed_mmmc_disable_reports_auto_redirection 0
set init_abstract_view abstract
set init_layout_view layout
set init_design_settop 1
set init_top_cell riscv_pipeline
set init_gnd_net VSS
set init_pwr_net VDD
set init_mmmc_file ./tcl/viewDefinition.tcl
set init_verilog ../genus/outputs/riscv_pipeline_syn.v
get_message -id GLOBAL-100 -suppress
get_message -id GLOBAL-100 -suppress
set latch_time_borrow_mode max_borrow
set pegDefaultResScaleFactor 1
set pegDetailResScaleFactor 1
get_message -id GLOBAL-100 -suppress
get_message -id GLOBAL-100 -suppress
set report_inactive_arcs_format {from to when arc_type sense reason}
set tso_post_client_restore_command {update_timing ; write_eco_opt_db ;}
setGenerateViaMode -auto false
init_design
floorPlan -r 1.00 0.72 3.840 3.840 3.840 3.840
timeDesign -proto -prePlace
set_proto_design_mode -timing_aware true -congestion_aware true
proto_design
snapFPlan -guide
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP.rpt
saveFPlan ./outputs/riscv_pipeline_hierFP.fp
saveDesign ./saved/riscv_pipeline_hierFP.enc
report_area > ./reports/area_hierFP.rpt
report_timing > ./reports/timing_hierFP.rpt
setMultiColorsHier
all_constraint_modes
set_interactive_constraint_modes [all_constraint_modes]
setAddStripeMode -trim_antenna_back_to_shape core_ring
setAddStripeMode -split_vias true
setAddStripeMode -via_using_exact_crossover_size false
clearGlobalNets
deleteAllPowerPreroutes
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {}
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {}
globalNetConnect VDD -type tiehi -inst * -module {}
globalNetConnect VSS -type tielo -inst * -module {}
applyGlobalNets
addRing -nets {VDD VSS} -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.640 -spacing 0.320 -offset 0.320
win
