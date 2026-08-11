#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Wed Aug 12 01:29:43 2026                
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
win
set enc_source_continue_on_error false
set auto_file_dir /tmp/user1/innovus_riscv_2208394
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
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
floorPlan -s 309.120 308.352 3.840 3.840 3.840 3.840
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
createPGPin VDD -geom M9 3.216 157.08 3.696 159.0 -net VDD
createPGPin VSS -geom M9 2.256 157.08 2.736 159.0 -net VSS
setAddStripeMode -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.288 -set_to_set_distance 25.600 -start_from left -start_offset 12.800 -snap_wire_center_to_grid grid
setAddStripeMode -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.288 -set_to_set_distance 25.600 -start_from bottom -start_offset 12.800 -snap_wire_center_to_grid grid
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
zoomBox -10.08825 25.54925 315.90350 317.38150
zoomBox -0.49225 96.35100 235.03700 307.20000
pan -55.45450 118.17175
zoomBox -40.22025 151.75425 129.94975 304.09275
zoomBox -33.74800 164.63250 110.89650 294.12025
zoomBox -16.21775 199.51500 59.28800 267.10875
zoomBox -8.83025 214.21450 37.54000 255.72575
zoomBox -4.29350 223.24200 24.18375 248.73525
zoomBox -7.06675 217.72350 32.34825 253.00825
zoomBox -13.34650 205.22800 50.83475 262.68400
zoomBox -23.57175 184.88175 80.93675 278.43925
zoomBox -19.86050 193.37900 68.97175 272.90275
zoomBox -11.74550 211.95900 42.80875 260.79675
zoomBox -6.76225 223.36950 26.74125 253.36225
