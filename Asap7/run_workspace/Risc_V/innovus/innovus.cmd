#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Wed Aug 12 13:00:00 2026                
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
set enc_source_continue_on_error false
set auto_file_dir /tmp/user1/innovus_riscv_1441532
setDesignMode -process 7
setMultiCpuUsage -acquireLicense 8
setMultiCpuUsage -localCpu 8
setDistributeHost -local
suppressMessage IMPPP-133
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
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
floorPlan -s 360.192 360.192 3.840 3.840 3.840 3.840
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP.rpt
saveFPlan ./outputs/riscv_pipeline_hierFP.fp
saveDesign ./saved/riscv_pipeline_hierFP.enc
report_area > ./reports/area_hierFP.rpt
report_timing > ./reports/timing_hierFP.rpt
setMultiColorsHier
all_constraint_modes
set_interactive_constraint_modes [all_constraint_modes]
setAddStripeMode -reset
setAddStripeMode -allow_jog none
setAddStripeMode -trim_antenna_back_to_shape core_ring
setAddStripeMode -split_vias true
setAddStripeMode -via_using_exact_crossover_size false
clearGlobalNets
deleteAllPowerPreroutes
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets
addRing -nets VDD -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 0.192 -snap_wire_center_to_grid Grid
addRing -nets VSS -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 1.152 -snap_wire_center_to_grid Grid
deletePGPin -net VDD
deletePGPin -net VSS
createPGPin VDD -geom M9 3.144 183.000 3.624 184.920 -net VDD
createPGPin VSS -geom M9 2.064 183.000 2.544 184.920 -net VSS
setAddStripeMode -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.288 -set_to_set_distance 34.560 -start_from left -start_offset 17.280 -snap_wire_center_to_grid grid
setAddStripeMode -reset
setAddStripeMode -allow_jog none -split_vias true -via_using_exact_crossover_size false -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.288 -set_to_set_distance 34.560 -start_from bottom -start_offset 17.280 -snap_wire_center_to_grid grid
editTrim -nets {VDD VSS}
clearDrc
setPinConstraint -cell riscv_pipeline -corner_to_pin_distance 8
setPinAssignMode -pinEditInBatch true
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side -spreadDirection counterclockwise -side BOTTOM -layer M7 -honorConstraint 1 -pin {clk reset_n riscv_start {reset_vector_in[31]} {reset_vector_in[30]} {reset_vector_in[29]} {reset_vector_in[28]} {reset_vector_in[27]} {reset_vector_in[26]} {reset_vector_in[25]} {reset_vector_in[24]} {reset_vector_in[23]} {reset_vector_in[22]} {reset_vector_in[21]} {reset_vector_in[20]} {reset_vector_in[19]} {reset_vector_in[18]} {reset_vector_in[17]} {reset_vector_in[16]} {reset_vector_in[15]} {reset_vector_in[14]} {reset_vector_in[13]} {reset_vector_in[12]} {reset_vector_in[11]} {reset_vector_in[10]} {reset_vector_in[9]} {reset_vector_in[8]} {reset_vector_in[7]} {reset_vector_in[6]} {reset_vector_in[5]} {reset_vector_in[4]} {reset_vector_in[3]} {reset_vector_in[2]} {reset_vector_in[1]} {reset_vector_in[0]}}
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side -spreadDirection counterclockwise -side LEFT -layer M6 -honorConstraint 1 -pin {icache_read_req {icache_addr[31]} {icache_addr[30]} {icache_addr[29]} {icache_addr[28]} {icache_addr[27]} {icache_addr[26]} {icache_addr[25]} {icache_addr[24]} {icache_addr[23]} {icache_addr[22]} {icache_addr[21]} {icache_addr[20]} {icache_addr[19]} {icache_addr[18]} {icache_addr[17]} {icache_addr[16]} {icache_addr[15]} {icache_addr[14]} {icache_addr[13]} {icache_addr[12]} {icache_addr[11]} {icache_addr[10]} {icache_addr[9]} {icache_addr[8]} {icache_addr[7]} {icache_addr[6]} {icache_addr[5]} {icache_addr[4]} {icache_addr[3]} {icache_addr[2]} {icache_addr[1]} {icache_addr[0]} {icache_read_data[31]} {icache_read_data[30]} {icache_read_data[29]} {icache_read_data[28]} {icache_read_data[27]} {icache_read_data[26]} {icache_read_data[25]} {icache_read_data[24]} {icache_read_data[23]} {icache_read_data[22]} {icache_read_data[21]} {icache_read_data[20]} {icache_read_data[19]} {icache_read_data[18]} {icache_read_data[17]} {icache_read_data[16]} {icache_read_data[15]} {icache_read_data[14]} {icache_read_data[13]} {icache_read_data[12]} {icache_read_data[11]} {icache_read_data[10]} {icache_read_data[9]} {icache_read_data[8]} {icache_read_data[7]} {icache_read_data[6]} {icache_read_data[5]} {icache_read_data[4]} {icache_read_data[3]} {icache_read_data[2]} {icache_read_data[1]} {icache_read_data[0]} icache_hit icache_stall}
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side -spreadDirection counterclockwise -side RIGHT -layer M6 -honorConstraint 1 -pin {dcache_read_req dcache_write_req {dcache_addr[31]} {dcache_addr[30]} {dcache_addr[29]} {dcache_addr[28]} {dcache_addr[27]} {dcache_addr[26]} {dcache_addr[25]} {dcache_addr[24]} {dcache_addr[23]} {dcache_addr[22]} {dcache_addr[21]} {dcache_addr[20]} {dcache_addr[19]} {dcache_addr[18]} {dcache_addr[17]} {dcache_addr[16]} {dcache_addr[15]} {dcache_addr[14]} {dcache_addr[13]} {dcache_addr[12]} {dcache_addr[11]} {dcache_addr[10]} {dcache_addr[9]} {dcache_addr[8]} {dcache_addr[7]} {dcache_addr[6]} {dcache_addr[5]} {dcache_addr[4]} {dcache_addr[3]} {dcache_addr[2]} {dcache_addr[1]} {dcache_addr[0]} {dcache_write_data[31]} {dcache_write_data[30]} {dcache_write_data[29]} {dcache_write_data[28]} {dcache_write_data[27]} {dcache_write_data[26]} {dcache_write_data[25]} {dcache_write_data[24]} {dcache_write_data[23]} {dcache_write_data[22]} {dcache_write_data[21]} {dcache_write_data[20]} {dcache_write_data[19]} {dcache_write_data[18]} {dcache_write_data[17]} {dcache_write_data[16]} {dcache_write_data[15]} {dcache_write_data[14]} {dcache_write_data[13]} {dcache_write_data[12]} {dcache_write_data[11]} {dcache_write_data[10]} {dcache_write_data[9]} {dcache_write_data[8]} {dcache_write_data[7]} {dcache_write_data[6]} {dcache_write_data[5]} {dcache_write_data[4]} {dcache_write_data[3]} {dcache_write_data[2]} {dcache_write_data[1]} {dcache_write_data[0]} {dcache_read_data[31]} {dcache_read_data[30]} {dcache_read_data[29]} {dcache_read_data[28]} {dcache_read_data[27]} {dcache_read_data[26]} {dcache_read_data[25]} {dcache_read_data[24]} {dcache_read_data[23]} {dcache_read_data[22]} {dcache_read_data[21]} {dcache_read_data[20]} {dcache_read_data[19]} {dcache_read_data[18]} {dcache_read_data[17]} {dcache_read_data[16]} {dcache_read_data[15]} {dcache_read_data[14]} {dcache_read_data[13]} {dcache_read_data[12]} {dcache_read_data[11]} {dcache_read_data[10]} {dcache_read_data[9]} {dcache_read_data[8]} {dcache_read_data[7]} {dcache_read_data[6]} {dcache_read_data[5]} {dcache_read_data[4]} {dcache_read_data[3]} {dcache_read_data[2]} {dcache_read_data[1]} {dcache_read_data[0]} dcache_hit dcache_stall {mem_size_top[1]} {mem_size_top[0]} mem_unsigned_top}
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side -spreadDirection counterclockwise -side TOP -layer M7 -honorConstraint 1 -pin {meip_i msip_i mtip_i riscv_done wfi_sleep_out dbg_halt_req dbg_resume_req dbg_halted {dbg_reg_read_addr[15]} {dbg_reg_read_addr[14]} {dbg_reg_read_addr[13]} {dbg_reg_read_addr[12]} {dbg_reg_read_addr[11]} {dbg_reg_read_addr[10]} {dbg_reg_read_addr[9]} {dbg_reg_read_addr[8]} {dbg_reg_read_addr[7]} {dbg_reg_read_addr[6]} {dbg_reg_read_addr[5]} {dbg_reg_read_addr[4]} {dbg_reg_read_addr[3]} {dbg_reg_read_addr[2]} {dbg_reg_read_addr[1]} {dbg_reg_read_addr[0]} {dbg_reg_read_data[31]} {dbg_reg_read_data[30]} {dbg_reg_read_data[29]} {dbg_reg_read_data[28]} {dbg_reg_read_data[27]} {dbg_reg_read_data[26]} {dbg_reg_read_data[25]} {dbg_reg_read_data[24]} {dbg_reg_read_data[23]} {dbg_reg_read_data[22]} {dbg_reg_read_data[21]} {dbg_reg_read_data[20]} {dbg_reg_read_data[19]} {dbg_reg_read_data[18]} {dbg_reg_read_data[17]} {dbg_reg_read_data[16]} {dbg_reg_read_data[15]} {dbg_reg_read_data[14]} {dbg_reg_read_data[13]} {dbg_reg_read_data[12]} {dbg_reg_read_data[11]} {dbg_reg_read_data[10]} {dbg_reg_read_data[9]} {dbg_reg_read_data[8]} {dbg_reg_read_data[7]} {dbg_reg_read_data[6]} {dbg_reg_read_data[5]} {dbg_reg_read_data[4]} {dbg_reg_read_data[3]} {dbg_reg_read_data[2]} {dbg_reg_read_data[1]} {dbg_reg_read_data[0]} dbg_reg_write_en {dbg_reg_write_addr[15]} {dbg_reg_write_addr[14]} {dbg_reg_write_addr[13]} {dbg_reg_write_addr[12]} {dbg_reg_write_addr[11]} {dbg_reg_write_addr[10]} {dbg_reg_write_addr[9]} {dbg_reg_write_addr[8]} {dbg_reg_write_addr[7]} {dbg_reg_write_addr[6]} {dbg_reg_write_addr[5]} {dbg_reg_write_addr[4]} {dbg_reg_write_addr[3]} {dbg_reg_write_addr[2]} {dbg_reg_write_addr[1]} {dbg_reg_write_addr[0]} {dbg_reg_write_data[31]} {dbg_reg_write_data[30]} {dbg_reg_write_data[29]} {dbg_reg_write_data[28]} {dbg_reg_write_data[27]} {dbg_reg_write_data[26]} {dbg_reg_write_data[25]} {dbg_reg_write_data[24]} {dbg_reg_write_data[23]} {dbg_reg_write_data[22]} {dbg_reg_write_data[21]} {dbg_reg_write_data[20]} {dbg_reg_write_data[19]} {dbg_reg_write_data[18]} {dbg_reg_write_data[17]} {dbg_reg_write_data[16]} {dbg_reg_write_data[15]} {dbg_reg_write_data[14]} {dbg_reg_write_data[13]} {dbg_reg_write_data[12]} {dbg_reg_write_data[11]} {dbg_reg_write_data[10]} {dbg_reg_write_data[9]} {dbg_reg_write_data[8]} {dbg_reg_write_data[7]} {dbg_reg_write_data[6]} {dbg_reg_write_data[5]} {dbg_reg_write_data[4]} {dbg_reg_write_data[3]} {dbg_reg_write_data[2]} {dbg_reg_write_data[1]} {dbg_reg_write_data[0]}}
setPinAssignMode -pinEditInBatch false
verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet -error 1000 -warning 100 -report ./verify_rpt/connectivity_after_pg.rpt
verify_drc -report ./verify_rpt/drc_after_pg.rpt
saveDesign ./saved/riscv_pipeline_powerplan.enc
setDelayCalMode -SIAware false -equivalent_waveform_model none
setHierMode -optStage preCTS
setPlaceMode -reset
setPlaceMode -place_global_uniform_density true -place_global_module_aware_spare true -place_global_auto_blockage_in_channel soft -place_detail_preroute_as_obs {2 3} -place_global_cong_effort high -place_design_refine_macro false
place_design
refinePlace
setAddStripeMode -reset
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M1 -stacked_via_top_layer M6
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -set_to_set_distance 25.920 -start_from left -start_offset 12.960 -create_pins 0 -area {3.888 0.0 364.032 367.92} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setSrouteMode -reset
setSrouteMode -viaConnectToShape stripe
sroute -nets {VDD VSS} -connect corePin -corePinTarget stripe -corePinCheckStdcellGeoms -allowJogging 0 -allowLayerChange 0
editTrim -nets {VDD VSS}
clearDrc
verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet -error 1000 -warning 100 -report ./verify_rpt/connectivity_after_postplace_pg.rpt
verify_drc -report ./verify_rpt/drc_after_postplace_pg.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_postPlace.rpt
report_timing > ./reports/timing_postPlace.rpt
report_area > ./reports/area_postPlace.rpt
saveDesign ./saved/riscv_pipeline_postPlace.enc
create_route_type -name leaf_rule -bottom_preferred_layer M2 -top_preferred_layer M3
create_route_type -name trunk_rule -bottom_preferred_layer M4 -top_preferred_layer M5
create_route_type -name top_rule -bottom_preferred_layer M6 -top_preferred_layer M7
set_ccopt_property -net_type leaf route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top route_type top_rule
set_ccopt_property routing_top_min_fanout 100
set_ccopt_property target_max_trans 0.300ns
set_ccopt_property buffer_cells {BUFx4_ASAP7_75t_R BUFx8_ASAP7_75t_R BUFx12_ASAP7_75t_R BUFx4_ASAP7_75t_L BUFx8_ASAP7_75t_L BUFx12_ASAP7_75t_L}
set_ccopt_property inverter_cells {CKINVDCx8_ASAP7_75t_R CKINVDCx12_ASAP7_75t_R CKINVDCx16_ASAP7_75t_R CKINVDCx8_ASAP7_75t_L CKINVDCx12_ASAP7_75t_L CKINVDCx16_ASAP7_75t_L}
set_ccopt_property use_inverters auto
setOptMode -reclaimArea true -leakageToDynamicRatio 0.5 -powerEffort high -fixFanoutLoad true
optDesign -prefix preCTS -preCTS
report_timing > ./reports/timing_preCTS.rpt
refinePlace
checkPlace ./verify_rpt/checkPlace_before_cts.rpt
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
clock_opt_design -prefix postCTS
all_constraint_modes -active
set_interactive_constraint_modes $active_constraint_modes
set_propagated_clock [all_clocks]
set_interactive_constraint_modes {}
setHierMode -optStage postCTS
optDesign -prefix postCTS -postCTS -setup -hold
report_timing > ./reports/timing_postCTS.rpt
report_area > ./reports/area_postCTS.rpt
saveDesign ./saved/riscv_pipeline_postCTS.enc
setFillerMode -core {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -preserveUserOrder true -honorPrerouteAsObs true -diffCellViol true
addFiller -cell {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -prefix FILLER -honorPrerouteAsObs true -diffCellViol true
setNanoRouteMode -reset
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
setNanoRouteMode -quiet -route_strict_honor_route_rule true -route_strictly_honor_1d_routing true -route_detail_no_taper_in_layers 2:7 -route_detail_no_taper_on_output_pin true -route_use_auto_via false -route_with_via_only_for_stdcell_pin true -route_detail_use_multi_cut_via_effort low -route_with_timing_driven true -route_with_si_driven false -route_detail_fix_antenna true -route_detail_merge_abutting_cut true -route_detail_end_iteration 20
routeDesign -globalDetail
routeDesign -viaOpt -wireOpt -trackOpt
setNanoRouteMode -quiet -route_with_timing_driven false -route_with_si_driven false
ecoRoute -fix_drc
verify_drc -report ./verify_rpt/drc_after_initial_route.rpt
verifyConnectivity -type all -error 1000 -warning 100 -report ./verify_rpt/connectivity_after_initial_route.rpt
saveDesign ./saved/riscv_pipeline_routed_initial.enc
setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -SIAware true -equivalent_waveform_model propagation
setExtractRCMode -engine postRoute -effortLevel medium
optDesign -prefix postRoute -postRoute -setup -hold
optDesign -prefix postRouteDRV -postRoute -drv
setNanoRouteMode -quiet -route_with_timing_driven false -route_with_si_driven false
ecoRoute -fix_drc
report_timing > ./reports/timing_postRoute.rpt
report_area > ./reports/area_postRoute.rpt
report_power > ./reports/power_postRoute.rpt
saveDesign ./saved/riscv_pipeline_postRoute.enc
verify_drc -report ./verify_rpt/drc_after_route.rpt
verifyConnectivity -type all -error 1000 -warning 100 -report ./verify_rpt/connectivity_after_route.rpt
extractRC
rcOut -spef ./outputs/riscv_pipeline_pnr.spef -rc_corner rc_typ
writeTimingCon ./outputs/riscv_pipeline_pnr.sdc
saveNetlist ./outputs/riscv_pipeline_pnr_lec.v -excludeLeafCell -removePowerGround
saveNetlist ./outputs/riscv_pipeline_pnr_sta.v -excludeLeafCell
saveNetlist ./outputs/riscv_pipeline_pnr_pg.v -excludeLeafCell -includePowerGround -includePhysicalInst
setStreamOutMode -labelAllPinShape true -pinTextOrientation automatic -virtualConnection false -textSize 1
streamOut ./outputs/riscv_pipeline.gds -mapFile ./tcl/streamOut.map -merge {/home/user1/Desktop/asap7/asap7sc7p5t_28/GDS/asap7sc7p5t_28_R_220121a.gds /home/user1/Desktop/asap7/asap7sc7p5t_28/GDS/asap7sc7p5t_28_L_220121a.gds} -units 4000 -dieAreaAsBoundary -outputMacros
write_lef_abstract -noCutObs ./outputs/riscv_pipeline.lef
defOut -floorplan -netlist -routing ./outputs/riscv_pipeline_pnr.def
report_area > ./reports/area_pnr.rpt
report_power > ./reports/power_pnr.rpt
report_timing > ./reports/timing_pnr.rpt
saveDesign ./saved/riscv_pipeline_final.enc
