#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Aug  6 18:00:22 2026                
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
set auto_file_dir /tmp/user1/innovus_master
set init_design_uniquify 1
set init_lef_file {/home/user1/Desktop/asap7/asap7sc7p5t_28/techlef_misc/asap7_tech_4x_201209.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_L_4x_220121a.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_R_4x_220121a.lef /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LEF/4xLEF/srambank_256x4x32_6t122.lef.4x.lef}
set ::TimeLib::tsgMarkCellLatchConstructFlag 1
set conf_qxconf_file NULL
set conf_qxlib_file NULL
set defHierChar /
set distributed_client_message_echo 1
set distributed_mmmc_disable_reports_auto_redirection 0
set init_abstract_view abstract
set init_layout_view layout
set init_design_settop 1
set init_top_cell axi_ram
set init_gnd_net VSS
set init_pwr_net VDD
set init_mmmc_file ./tcl/viewDefinition.tcl
set init_verilog ./outputs/axi_ram_syn.v
get_message -id GLOBAL-100 -suppress
get_message -id GLOBAL-100 -suppress
set latch_time_borrow_mode max_borrow
set pegDefaultResScaleFactor 1
set pegDetailResScaleFactor 1
get_message -id GLOBAL-100 -suppress
get_message -id GLOBAL-100 -suppress
set report_inactive_arcs_format {from to when arc_type sense reason}
set tso_post_client_restore_command {update_timing ; write_eco_opt_db ;}
init_design
setDesignMode -process 7
setMultiCpuUsage -acquireLicense 12
setMultiCpuUsage -localCpu 12
setDistributeHost -local
floorPlan -s 1100.928 966.528 2.16 2.16 2.16 2.16
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_proto.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_final.rpt
saveFPlan ./outputs/FloorPlan.fp
saveDesign ./saved/axi_ram_hierFP.enc
placeInstance {u_mem/G_SRAM_BANK[0].u_sram} 2.160000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[1].u_sram} 127.872000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[2].u_sram} 253.584000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[3].u_sram} 379.296000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[4].u_sram} 379.296000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[5].u_sram} 253.584000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[6].u_sram} 127.872000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[7].u_sram} 2.160000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[8].u_sram} 2.160000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[9].u_sram} 127.872000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[10].u_sram} 253.584000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[11].u_sram} 379.296000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[12].u_sram} 379.296000 533.520000 R180
placeInstance {u_mem/G_SRAM_BANK[13].u_sram} 253.584000 533.520000 R180
placeInstance {u_mem/G_SRAM_BANK[14].u_sram} 127.872000 533.520000 R180
placeInstance {u_mem/G_SRAM_BANK[15].u_sram} 2.160000 533.520000 R180
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
applyGlobalNets
addRing -nets {VSS VDD} -type block_rings -around each_block -layer {top M4 bottom M4 left M5 right M5} -width {top 0.096 bottom 0.096 left 0.096 right 0.096} -spacing {top 0.288 bottom 0.288 left 0.288 right 0.288} -offset {top 1.080 bottom 1.080 left 1.080 right 1.080}
setAddStripeMode -allow_jog none -break_at block_ring
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -set_to_set_distance 25.920 -extend_to design_boundary -start_from bottom -start_offset 24.3
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -set_to_set_distance 25.920 -extend_to design_boundary -start_from left -start_offset 24.3
editTrim -nets {VSS VDD}
create_pg_model_for_macro_place -file ./outputs/golden_mimic_sram_power_mesh.tcl
set_macro_place_constraint -pg_resource_model {M4 0.024591 M5 0.025831 }
set_macro_place_constraint -cells srambank_256x4x32_6t122 -track_adjustment {{M4 1.0246} {M5 1.0258} }
editDelete -shape {STRIPE BLOCKRING}
clearDrc
createInstGroup SRAM_ISLAND_GROUP -fence 2.16 2.16 505.008 710.64
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[0].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[1].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[2].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[3].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[4].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[5].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[6].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[7].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[8].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[9].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[10].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[11].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[12].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[13].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[14].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[15].u_sram}
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
unplaceAllBlocks
setHierMode -optStage preCTS
place_design -concurrent_macros
place_design -concurrent_macros -incremental
unplaceAllInsts
placeInstance {u_mem/G_SRAM_BANK[9].u_sram} 2.160000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[14].u_sram} 127.872000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[15].u_sram} 253.584000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[12].u_sram} 379.296000 2.160000 R180
placeInstance {u_mem/G_SRAM_BANK[8].u_sram} 2.160000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[10].u_sram} 127.872000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[11].u_sram} 253.584000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[13].u_sram} 379.296000 179.280000 R180
placeInstance {u_mem/G_SRAM_BANK[5].u_sram} 2.160000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[0].u_sram} 127.872000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[6].u_sram} 253.584000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[2].u_sram} 379.296000 356.400000 R180
placeInstance {u_mem/G_SRAM_BANK[4].u_sram} 2.160000 533.520000 R180
placeInstance {u_mem/G_SRAM_BANK[1].u_sram} 127.872000 533.520000 R180
placeInstance {u_mem/G_SRAM_BANK[7].u_sram} 253.584000 533.520000 R180
placeInstance {u_mem/G_SRAM_BANK[3].u_sram} 379.296000 533.520000 R180
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
snapFPlan -block
cutRow -area {2.16 2.16 502.848 708.48}
createPlaceBlockage -name SRAM_ISLAND_GROUP_BLOCKAGE -type hard -noCutByCore -box {0.0 0.0 502.848 708.48}
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_after_macroFP.rpt
saveFPlan ./outputs/FloorPlan_withMacro.fp
saveDesign ./saved/axi_ram_macroFP.enc
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_before_pnr.rpt
setAddStripeMode -allow_jog none
clearGlobalNets
deleteAllPowerPreroutes
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets
addRing -nets {VDD VSS} -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 0.384 -snap_wire_center_to_grid Grid
createPGPin VDD -geom M9 1.296 1.296 1.776 1.776 -net VDD
createPGPin VSS -geom M9 0.336 0.336 0.816 0.816 -net VSS
deselectAll
selectInst {u_mem/G_SRAM_BANK[0].u_sram}
selectInst {u_mem/G_SRAM_BANK[1].u_sram}
selectInst {u_mem/G_SRAM_BANK[2].u_sram}
selectInst {u_mem/G_SRAM_BANK[3].u_sram}
selectInst {u_mem/G_SRAM_BANK[4].u_sram}
selectInst {u_mem/G_SRAM_BANK[5].u_sram}
selectInst {u_mem/G_SRAM_BANK[6].u_sram}
selectInst {u_mem/G_SRAM_BANK[7].u_sram}
selectInst {u_mem/G_SRAM_BANK[8].u_sram}
selectInst {u_mem/G_SRAM_BANK[9].u_sram}
selectInst {u_mem/G_SRAM_BANK[10].u_sram}
selectInst {u_mem/G_SRAM_BANK[11].u_sram}
selectInst {u_mem/G_SRAM_BANK[12].u_sram}
selectInst {u_mem/G_SRAM_BANK[13].u_sram}
selectInst {u_mem/G_SRAM_BANK[14].u_sram}
selectInst {u_mem/G_SRAM_BANK[15].u_sram}
addRing -nets {VDD VSS} -type block_rings -around shared_cluster -layer {top M4 bottom M4 left M5 right M5} -width 0.096 -spacing 0.288 -offset 1.080 -snap_wire_center_to_grid Grid
deselectAll
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.056000 -number_of_sets 1 -area {123.552 2.16 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.040000 -number_of_sets 1 -area {249.264 2.16 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.024000 -number_of_sets 1 -area {374.976 2.16 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.104000 -number_of_sets 1 -area {2.16 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.136000 -number_of_sets 1 -area {2.16 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.168000 -number_of_sets 1 -area {2.16 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
applyGlobalNets
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -area {2.16 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.932000 -number_of_sets 1 -area {2.16 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -area {2.16 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 0.780000 -number_of_sets 1 -area {2.16 706.32 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M4 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.968000 -number_of_sets 1 -area {123.552 2.16 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.824000 -number_of_sets 1 -area {249.264 2.16 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.872000 -number_of_sets 1 -area {374.976 2.16 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -area {500.688 2.16 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setSrouteMode -extendNearestTarget true -blockPinRouteWithPinWidth true -viaConnectToShape {stripe blockring ring}
sroute -connect blockPin -nets {VDD VSS} -blockPin useLef -blockPinTarget nearestTarget -allowJogging 0 -allowLayerChange 0
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from left -start_offset 3.456000 -area {502.848 2.16 1103.04 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from left -start_offset 12.880000 -area {2.16 708.48 502.848 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from bottom -start_offset 4.672000 -area {2.16 708.48 1103.04 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from bottom -start_offset 12.880000 -area {502.848 2.16 1103.04 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.104000 -number_of_sets 1 -area {502.848 174.96 1103.04 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.136000 -number_of_sets 1 -area {502.848 352.08 1103.04 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.168000 -number_of_sets 1 -area {502.848 529.2 1103.04 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.056000 -number_of_sets 1 -area {123.552 708.48 127.872 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.040000 -number_of_sets 1 -area {249.264 708.48 253.584 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.024000 -number_of_sets 1 -area {374.976 708.48 379.296 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M7 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 2.080000 -area {0.0 708.48 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 19.360000 -area {502.848 0.0 1105.2 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M8 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 0.352000 -area {502.848 0.0 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 19.360000 -area {0.0 708.48 502.848 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
verifyConnectivity -type special -noUnroutedNet -report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt
verify_drc -report ./verify_rpt/pg_drc_before_stdcell_place.rpt
setPinConstraint -corner_to_pin_distance 8
setPinAssignMode -pinEditInBatch true
editPin -pin {clk rst_n {s_axi_awid[4]} {s_axi_awid[3]} {s_axi_awid[2]} {s_axi_awid[1]} {s_axi_awid[0]} {s_axi_awaddr[31]} {s_axi_awaddr[30]} {s_axi_awaddr[29]} {s_axi_awaddr[28]} {s_axi_awaddr[27]} {s_axi_awaddr[26]} {s_axi_awaddr[25]} {s_axi_awaddr[24]} {s_axi_awaddr[23]} {s_axi_awaddr[22]} {s_axi_awaddr[21]} {s_axi_awaddr[20]} {s_axi_awaddr[19]} {s_axi_awaddr[18]} {s_axi_awaddr[17]} {s_axi_awaddr[16]} {s_axi_awaddr[15]} {s_axi_awaddr[14]} {s_axi_awaddr[13]} {s_axi_awaddr[12]} {s_axi_awaddr[11]} {s_axi_awaddr[10]} {s_axi_awaddr[9]} {s_axi_awaddr[8]} {s_axi_awaddr[7]} {s_axi_awaddr[6]} {s_axi_awaddr[5]} {s_axi_awaddr[4]} {s_axi_awaddr[3]} {s_axi_awaddr[2]} {s_axi_awaddr[1]} {s_axi_awaddr[0]} {s_axi_awlen[7]} {s_axi_awlen[6]} {s_axi_awlen[5]} {s_axi_awlen[4]} {s_axi_awlen[3]} {s_axi_awlen[2]} {s_axi_awlen[1]} {s_axi_awlen[0]} {s_axi_awsize[2]} {s_axi_awsize[1]} {s_axi_awsize[0]} {s_axi_awburst[1]} {s_axi_awburst[0]} s_axi_awlock {s_axi_awcache[3]} {s_axi_awcache[2]} {s_axi_awcache[1]} {s_axi_awcache[0]} {s_axi_awprot[2]} {s_axi_awprot[1]} {s_axi_awprot[0]} {s_axi_awqos[3]} {s_axi_awqos[2]} {s_axi_awqos[1]} {s_axi_awqos[0]} {s_axi_awregion[3]} {s_axi_awregion[2]} {s_axi_awregion[1]} {s_axi_awregion[0]} s_axi_awvalid s_axi_awready} -side TOP -layer M7 -spreadType range -start {8.0 970.848} -end {1097.2 970.848} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_wdata[31]} {s_axi_wdata[30]} {s_axi_wdata[29]} {s_axi_wdata[28]} {s_axi_wdata[27]} {s_axi_wdata[26]} {s_axi_wdata[25]} {s_axi_wdata[24]} {s_axi_wdata[23]} {s_axi_wdata[22]} {s_axi_wdata[21]} {s_axi_wdata[20]} {s_axi_wdata[19]} {s_axi_wdata[18]} {s_axi_wdata[17]} {s_axi_wdata[16]} {s_axi_wdata[15]} {s_axi_wdata[14]} {s_axi_wdata[13]} {s_axi_wdata[12]} {s_axi_wdata[11]} {s_axi_wdata[10]} {s_axi_wdata[9]} {s_axi_wdata[8]} {s_axi_wdata[7]} {s_axi_wdata[6]} {s_axi_wdata[5]} {s_axi_wdata[4]} {s_axi_wdata[3]} {s_axi_wdata[2]} {s_axi_wdata[1]} {s_axi_wdata[0]} {s_axi_wstrb[3]} {s_axi_wstrb[2]} {s_axi_wstrb[1]} {s_axi_wstrb[0]} s_axi_wlast s_axi_wvalid s_axi_wready {s_axi_bid[4]} {s_axi_bid[3]} {s_axi_bid[2]} {s_axi_bid[1]} {s_axi_bid[0]} {s_axi_bresp[1]} {s_axi_bresp[0]} s_axi_bvalid s_axi_bready} -side RIGHT -layer M6 -spreadType range -start {1105.2 8.0} -end {1105.2 962.848} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
saveDesign ./saved/axi_ram_floorplan_power_pins.enc
zoomBox -190.82875 -127.44775 813.05150 771.23925
zoomBox -485.12150 -367.37125 904.33200 876.48625
zoomBox -1151.47800 -910.62100 1111.01525 1114.79350
zoomBox -881.91050 -681.88375 1041.20875 1039.71850
zoomBox -458.01575 -322.19475 931.43800 921.66300
zoomBox -292.46775 -181.72150 888.56800 875.55750
zoomBox 69.52375 125.44050 794.82750 774.74225
zoomBox 168.98775 241.04800 693.01975 710.16850
zoomBox 227.68200 328.33700 606.29500 667.27650
zoomBox 280.97975 414.52100 513.49575 622.67250
zoomBox 294.51525 435.32100 492.15425 612.25000
zoomBox 306.13575 453.03925 474.12900 603.42900
zoomBox 326.03725 481.20300 447.41250 589.85975
zoomBox 346.09225 509.49800 420.63200 576.22700
zoomBox 361.34850 531.02300 400.25900 565.85625
zoomBox 367.77750 540.09375 391.67375 561.48600
zoomBox 371.72575 545.66450 386.40125 558.80225
zoomBox 372.66825 546.99450 385.14250 558.16150
zoomBox 373.40650 548.08600 384.00975 557.57825
zoomBox 373.87750 549.00575 382.89050 557.07425
zoomBox 372.54300 546.88275 385.01800 558.05050
zoomBox 369.49075 542.07600 389.80425 560.26100
zoomBox 364.50375 534.24875 397.58150 563.86050
zoomBox 356.35650 521.50400 410.21850 569.72200
pan -3.90200 188.07200
pan 0.13950 217.19800
pan 0.90575 229.94900
pan -0.97550 249.25000
pan -1.88125 274.54350
pan 1.67225 292.24200
pan -0.06975 318.79000
pan -0.13925 323.45850
zoomBox 358.79625 683.18675 397.71175 718.02450
zoomBox 361.44675 686.14700 394.52500 715.75900
zoomBox 365.82850 691.14625 389.72750 712.54100
zoomBox 358.66025 682.96775 397.57575 717.80550
zoomBox 346.41825 670.40925 409.78600 727.13700
zoomBox 355.22175 679.41775 401.00500 720.40350
zoomBox 363.42650 687.64525 391.54325 712.81575
zoomBox 369.66800 693.90400 384.34525 707.04325
zoomBox 372.92625 697.17100 380.58800 704.03000
zoomBox 373.45975 697.70625 379.97250 703.53650
zoomBox 373.45975 697.12325 379.97250 702.95350
zoomBox 372.42725 695.61825 381.44150 703.68800
zoomBox 369.02050 690.65225 386.28975 706.11200
pan -9.04800 321.72100
zoomBox 359.97250 689.19550 377.24175 704.65525
zoomBox 354.67775 685.42850 378.58025 706.82625
zoomBox 342.69000 676.89900 381.61125 711.74175
zoomBox 314.24275 656.65850 388.80375 723.40650
pan -15.81875 325.72875
zoomBox 298.42400 633.29675 372.98500 700.04475
fit
zoomBox -192.62150 225.86425 847.86125 783.33225
zoomBox -40.67025 392.57100 420.99800 639.92275
zoomBox -1.55150 443.08275 281.97075 594.98775
zoomBox 45.61550 478.60475 219.73375 571.89350
zoomBox 85.07000 505.99925 175.96175 554.69700
zoomBox 102.19825 517.32400 158.01750 547.23075
zoomBox 112.48575 523.46025 146.76600 541.82675
pan 0.03075 415.26700
zoomBox 114.99075 529.49575 144.12925 545.10750
zoomBox 109.60025 525.69675 149.93025 547.30475
pan -0.10825 426.32325
pan 0.79375 439.97700
pan -0.37875 443.27775
zoomBox 109.90700 551.40275 150.23700 573.01075
zoomBox 97.75725 545.87200 163.42900 581.05750
zoomBox 68.92650 532.74750 194.73375 600.15225
zoomBox 13.69575 507.60525 254.70375 636.73200
pan -68.98275 484.10100
zoomBox -46.60500 503.60075 158.25200 613.35875
zoomBox -32.95325 512.72775 115.05675 592.02825
zoomBox -19.23675 521.89775 71.65975 570.59800
zoomBox -10.97875 525.18150 36.47000 550.60350
zoomBox -8.99250 526.15225 31.33900 547.76100
zoomBox -7.30450 526.97750 26.97750 545.34500
zoomBox -5.86950 527.67875 23.27025 543.29125
zoomBox -4.64975 528.27500 20.11900 541.54550
zoomBox -7.52175 526.76850 26.76075 545.13625
zoomBox -9.34800 525.81050 30.98425 547.41975
zoomBox -14.56550 523.28850 41.25850 553.19775
zoomBox -31.78025 514.96700 75.16150 572.26400
zoomBox -53.92825 500.33200 120.20875 593.63075
pan 3.19300 584.16575
pan -2.33625 612.66925
pan -2.49225 662.82300
zoomBox -95.39600 563.80250 188.15700 715.72400
zoomBox -135.48175 518.11575 256.97925 728.38775
zoomBox -114.94600 546.47075 218.64575 725.20200
zoomBox -71.94225 609.16350 132.92525 718.92700
zoomBox -52.41550 636.90250 95.60100 716.20650
zoomBox -37.42600 656.88850 69.51600 714.18575
zoomBox -18.06300 681.96700 37.76200 711.87675
pan -0.54925 711.23975
zoomBox -31.89950 679.60725 59.00250 728.31050
zoomBox -75.07050 635.51825 129.79925 745.28300
pan -5.40575 751.91075
pan -1.46600 795.06525
pan 0.36650 838.40325
pan -0.64150 880.82475
pan -0.09175 920.03975
pan -3.39000 963.56075
pan -2.84025 991.41425
zoomBox -64.02900 923.38600 83.98925 1002.69100
zoomBox -46.00850 935.73050 60.93500 993.02850
zoomBox -38.97075 940.55150 51.93150 989.25500
zoomBox -19.88875 953.64875 27.56325 979.07250
zoomBox -8.29575 961.60550 12.75925 972.88625
