#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Aug  6 21:18:22 2026                
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
deletePGPin -net VDD
deletePGPin -net VSS
createPGPin VDD -geom M8 2.160000 1.296000 1103.040000 1.776000 -net VDD
createPGPin VSS -geom M8 2.160000 0.336000 1103.040000 0.816000 -net VSS
createPGPin VDD -geom M8 2.160000 969.072000 1103.040000 969.552000 -net VDD
createPGPin VSS -geom M8 2.160000 970.032000 1103.040000 970.512000 -net VSS
createPGPin VDD -geom M9 1.296000 2.160000 1.776000 968.688000 -net VDD
createPGPin VSS -geom M9 0.336000 2.160000 0.816000 968.688000 -net VSS
createPGPin VDD -geom M9 1103.424000 2.160000 1103.904000 968.688000 -net VDD
createPGPin VSS -geom M9 1104.384000 2.160000 1104.864000 968.688000 -net VSS
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
addRing -nets {VSS VDD} -type block_rings -around shared_cluster -layer {top M4 bottom M4 left M5 right M5} -width {top 0.096 bottom 0.096 left 0.096 right 0.096} -spacing {top 0.288 bottom 0.288 left 0.288 right 0.288} -offset {top 1.080 bottom 1.080 left 1.080 right 1.080} -snap_wire_center_to_grid Grid
setSrouteMode -extendNearestTarget true -blockPinRouteWithPinWidth true -viaConnectToShape blockring
sroute -connect blockPin -nets {VSS VDD} -blockPin useLef -blockPinTarget nearestTarget
setAddStripeMode -allow_jog none -break_at block_ring -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M9
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -create_pins 0 -area {0.336 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.932000 -number_of_sets 1 -create_pins 0 -area {0.336 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -create_pins 0 -area {0.336 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -break_at block_ring -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M9
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.968000 -number_of_sets 1 -create_pins 0 -area {123.552 0.336 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.824000 -number_of_sets 1 -create_pins 0 -area {249.264 0.336 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.872000 -number_of_sets 1 -create_pins 0 -area {374.976 0.336 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
editTrim -nets {VSS VDD}
clearDrc
deselectAll
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M7 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 2.080000 -create_pins 0 -area {0.0 708.48 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 19.360000 -create_pins 0 -area {502.848 0.0 1105.2 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M8 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 0.352000 -create_pins 0 -area {502.848 0.0 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 19.360000 -create_pins 0 -area {0.0 708.48 502.848 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
editTrim -nets {VDD VSS}
verifyConnectivity -type special -noUnroutedNet -report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt
verify_drc -report ./verify_rpt/pg_drc_before_stdcell_place.rpt
setPinConstraint -corner_to_pin_distance 8
setPinAssignMode -pinEditInBatch true
editPin -pin {clk rst_n {s_axi_awid[4]} {s_axi_awid[3]} {s_axi_awid[2]} {s_axi_awid[1]} {s_axi_awid[0]} {s_axi_awaddr[31]} {s_axi_awaddr[30]} {s_axi_awaddr[29]} {s_axi_awaddr[28]} {s_axi_awaddr[27]} {s_axi_awaddr[26]} {s_axi_awaddr[25]} {s_axi_awaddr[24]} {s_axi_awaddr[23]} {s_axi_awaddr[22]} {s_axi_awaddr[21]} {s_axi_awaddr[20]} {s_axi_awaddr[19]} {s_axi_awaddr[18]} {s_axi_awaddr[17]} {s_axi_awaddr[16]} {s_axi_awaddr[15]} {s_axi_awaddr[14]} {s_axi_awaddr[13]} {s_axi_awaddr[12]} {s_axi_awaddr[11]} {s_axi_awaddr[10]} {s_axi_awaddr[9]} {s_axi_awaddr[8]} {s_axi_awaddr[7]} {s_axi_awaddr[6]} {s_axi_awaddr[5]} {s_axi_awaddr[4]} {s_axi_awaddr[3]} {s_axi_awaddr[2]} {s_axi_awaddr[1]} {s_axi_awaddr[0]} {s_axi_awlen[7]} {s_axi_awlen[6]} {s_axi_awlen[5]} {s_axi_awlen[4]} {s_axi_awlen[3]} {s_axi_awlen[2]} {s_axi_awlen[1]} {s_axi_awlen[0]} {s_axi_awsize[2]} {s_axi_awsize[1]} {s_axi_awsize[0]} {s_axi_awburst[1]} {s_axi_awburst[0]} s_axi_awlock {s_axi_awcache[3]} {s_axi_awcache[2]} {s_axi_awcache[1]} {s_axi_awcache[0]} {s_axi_awprot[2]} {s_axi_awprot[1]} {s_axi_awprot[0]} {s_axi_awqos[3]} {s_axi_awqos[2]} {s_axi_awqos[1]} {s_axi_awqos[0]} {s_axi_awregion[3]} {s_axi_awregion[2]} {s_axi_awregion[1]} {s_axi_awregion[0]} s_axi_awvalid s_axi_awready} -side TOP -layer M7 -spreadType range -start {10.16 968.688} -end {1095.04 968.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_wdata[31]} {s_axi_wdata[30]} {s_axi_wdata[29]} {s_axi_wdata[28]} {s_axi_wdata[27]} {s_axi_wdata[26]} {s_axi_wdata[25]} {s_axi_wdata[24]} {s_axi_wdata[23]} {s_axi_wdata[22]} {s_axi_wdata[21]} {s_axi_wdata[20]} {s_axi_wdata[19]} {s_axi_wdata[18]} {s_axi_wdata[17]} {s_axi_wdata[16]} {s_axi_wdata[15]} {s_axi_wdata[14]} {s_axi_wdata[13]} {s_axi_wdata[12]} {s_axi_wdata[11]} {s_axi_wdata[10]} {s_axi_wdata[9]} {s_axi_wdata[8]} {s_axi_wdata[7]} {s_axi_wdata[6]} {s_axi_wdata[5]} {s_axi_wdata[4]} {s_axi_wdata[3]} {s_axi_wdata[2]} {s_axi_wdata[1]} {s_axi_wdata[0]} {s_axi_wstrb[3]} {s_axi_wstrb[2]} {s_axi_wstrb[1]} {s_axi_wstrb[0]} s_axi_wlast s_axi_wvalid s_axi_wready {s_axi_bid[4]} {s_axi_bid[3]} {s_axi_bid[2]} {s_axi_bid[1]} {s_axi_bid[0]} {s_axi_bresp[1]} {s_axi_bresp[0]} s_axi_bvalid s_axi_bready} -side RIGHT -layer M6 -spreadType range -start {1103.04 10.16} -end {1103.04 960.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_arid[4]} {s_axi_arid[3]} {s_axi_arid[2]} {s_axi_arid[1]} {s_axi_arid[0]} {s_axi_araddr[31]} {s_axi_araddr[30]} {s_axi_araddr[29]} {s_axi_araddr[28]} {s_axi_araddr[27]} {s_axi_araddr[26]} {s_axi_araddr[25]} {s_axi_araddr[24]} {s_axi_araddr[23]} {s_axi_araddr[22]} {s_axi_araddr[21]} {s_axi_araddr[20]} {s_axi_araddr[19]} {s_axi_araddr[18]} {s_axi_araddr[17]} {s_axi_araddr[16]} {s_axi_araddr[15]} {s_axi_araddr[14]} {s_axi_araddr[13]} {s_axi_araddr[12]} {s_axi_araddr[11]} {s_axi_araddr[10]} {s_axi_araddr[9]} {s_axi_araddr[8]} {s_axi_araddr[7]} {s_axi_araddr[6]} {s_axi_araddr[5]} {s_axi_araddr[4]} {s_axi_araddr[3]} {s_axi_araddr[2]} {s_axi_araddr[1]} {s_axi_araddr[0]} {s_axi_arlen[7]} {s_axi_arlen[6]} {s_axi_arlen[5]} {s_axi_arlen[4]} {s_axi_arlen[3]} {s_axi_arlen[2]} {s_axi_arlen[1]} {s_axi_arlen[0]} {s_axi_arsize[2]} {s_axi_arsize[1]} {s_axi_arsize[0]} {s_axi_arburst[1]} {s_axi_arburst[0]} s_axi_arlock {s_axi_arcache[3]} {s_axi_arcache[2]} {s_axi_arcache[1]} {s_axi_arcache[0]} {s_axi_arprot[2]} {s_axi_arprot[1]} {s_axi_arprot[0]} {s_axi_arqos[3]} {s_axi_arqos[2]} {s_axi_arqos[1]} {s_axi_arqos[0]} {s_axi_arregion[3]} {s_axi_arregion[2]} {s_axi_arregion[1]} {s_axi_arregion[0]} s_axi_arvalid s_axi_arready} -side LEFT -layer M6 -spreadType range -start {2.16 10.16} -end {2.16 960.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_rid[4]} {s_axi_rid[3]} {s_axi_rid[2]} {s_axi_rid[1]} {s_axi_rid[0]} {s_axi_rdata[31]} {s_axi_rdata[30]} {s_axi_rdata[29]} {s_axi_rdata[28]} {s_axi_rdata[27]} {s_axi_rdata[26]} {s_axi_rdata[25]} {s_axi_rdata[24]} {s_axi_rdata[23]} {s_axi_rdata[22]} {s_axi_rdata[21]} {s_axi_rdata[20]} {s_axi_rdata[19]} {s_axi_rdata[18]} {s_axi_rdata[17]} {s_axi_rdata[16]} {s_axi_rdata[15]} {s_axi_rdata[14]} {s_axi_rdata[13]} {s_axi_rdata[12]} {s_axi_rdata[11]} {s_axi_rdata[10]} {s_axi_rdata[9]} {s_axi_rdata[8]} {s_axi_rdata[7]} {s_axi_rdata[6]} {s_axi_rdata[5]} {s_axi_rdata[4]} {s_axi_rdata[3]} {s_axi_rdata[2]} {s_axi_rdata[1]} {s_axi_rdata[0]} {s_axi_rresp[1]} {s_axi_rresp[0]} s_axi_rlast s_axi_rvalid s_axi_rready} -side BOTTOM -layer M7 -spreadType range -start {10.16 2.16} -end {1095.04 2.16} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
setPinAssignMode -pinEditInBatch false
saveDesign ./saved/axi_ram_floorplan_power_pins.enc
fit
zoomBox -233.50550 106.06450 1206.60850 877.64625
zoomBox -170.59425 261.02000 869.88850 818.48800
zoomBox -79.47550 485.45300 382.19275 732.80475
zoomBox -68.57375 512.30450 323.84425 722.55350
zoomBox -33.67675 588.13925 171.16825 697.89075
zoomBox -15.46075 627.72525 91.47025 685.01650
zoomBox -10.28575 639.65550 66.97250 681.04875
zoomBox -6.00600 651.34825 41.44050 676.76900
zoomBox -2.75000 660.24325 22.01725 673.51300
pan -0.13300 667.76750
pan -0.15500 671.40075
pan 0.07750 676.73950
pan -0.07750 681.82375
pan -0.26575 687.05175
pan -0.22150 692.16900
pan -0.18825 698.20575
pan -0.21050 701.41800
zoomBox -2.01375 701.48700 13.19675 709.63650
zoomBox -5.82650 693.93850 28.45475 712.30575
zoomBox -10.13300 685.38400 45.68875 715.29200
pan 0.39950 704.22975
pan -1.07350 712.11850
pan 0.22475 719.48325
pan 0.37450 727.39700
pan -1.19825 734.81175
zoomBox -9.42125 728.34875 38.02725 753.77050
zoomBox -19.71975 708.91750 71.17675 757.61775
zoomBox -33.25725 683.37475 114.75250 762.67525
pan 2.51525 747.54500
pan -3.04500 772.30150
pan 1.19150 811.42225
pan 1.12525 841.93775
pan -1.19150 874.43900
zoomBox -19.84000 869.32825 71.05725 918.02900
zoomBox -10.08575 889.38100 37.36350 914.80325
zoomBox -5.87700 897.83150 23.26300 913.44400
zoomBox -3.99675 901.55975 17.05725 912.84000
zoomBox -3.26250 903.01600 14.63350 912.60425
selectMarker 0.3360 0.3360 1104.8640 970.5120 -1 3 7
deselectAll
selectPhyPin 1.2960 2.1600 1.7760 968.6880 9 VDD
deselectAll
selectPhyPin 0.3360 2.1600 0.8160 968.6880 9 VSS
deselectAll
selectPhyPin 1.2960 2.1600 1.7760 968.6880 9 VDD
zoomBox -3.26250 901.09850 14.63350 910.68675
zoomBox -1.98775 903.27725 10.94225 910.20475
zoomBox -0.39875 905.72600 6.35100 909.34225
zoomBox 0.56675 907.21375 3.56200 908.81850
zoomBox -0.39900 905.72575 6.35150 909.34250
zoomBox -2.57550 902.37225 12.63850 910.52350
zoomBox -4.07825 900.05675 16.97950 911.33900
zoomBox -7.48075 894.81400 26.80825 913.18525
pan -0.49075 910.56025
fit
zoomBox -269.96500 319.51650 954.13225 975.36100
zoomBox -198.86775 476.59875 685.54275 950.44650
zoomBox -124.69150 637.31400 418.44700 928.31575
zoomBox -106.98375 675.68100 354.68400 923.03250
zoomBox -78.79450 735.89850 254.76050 914.61000
zoomBox -67.78550 759.41600 215.73625 911.32075
zoomBox -57.76200 780.62300 183.23150 909.74200
zoomBox -30.50650 838.10050 95.29425 905.50175
zoomBox -22.20050 855.52400 68.69050 904.22150
zoomBox -15.92925 867.95450 49.74000 903.13875
pan -1.58575 902.23975
pan -1.14525 919.18550
pan -0.20550 935.48525
pan 0.20550 948.46625
pan 0.70475 963.47400
zoomBox -12.88650 950.81975 34.55975 976.24050
zoomBox -10.66850 953.34375 29.66125 974.95150
zoomBox -8.78275 955.48925 25.49750 973.85575
zoomBox -17.39175 952.58625 30.05500 978.00725
zoomBox -45.79925 943.00700 45.09425 991.70575
pan 10.85350 985.35100
zoomBox -57.28775 930.23075 68.51625 997.63375
zoomBox -158.23025 888.11825 125.30075 1040.02800
zoomBox -324.38600 818.79950 218.77075 1109.81100
zoomBox -568.29075 750.57325 316.14950 1224.43700
pan 204.10175 1203.76025
pan 170.08475 918.17625
pan 223.48350 721.19450
pan 208.84825 472.00050
zoomBox -9.40600 412.35325 1214.73275 1068.22000
pan -8.21200 142.55050
zoomBox 125.61250 259.89675 877.38675 662.68100
zoomBox 188.96275 316.06275 732.12000 607.07450
zoomBox 214.94250 339.49175 676.62625 586.85175
zoomBox 274.53850 392.39550 558.07050 544.30575
zoomBox 319.87550 432.64100 467.88125 511.93925
zoomBox 327.60000 439.36275 453.40500 506.76625
zoomBox 320.68950 431.51875 468.69550 510.81725
pan -57.98450 111.82250
panCenter 262.70475 511.81025
pan -77.04800 290.07850
pan -22.57175 367.72225
zoomBox 91.73300 487.33900 217.53825 554.74275
pan -42.53525 395.71850
gui_select -rect {68.38375 534.20650 114.18225 532.80000}
deselectAll
pan -56.93875 437.57850
pan -31.67625 494.68600
zoomBox -28.44150 499.57600 62.45300 548.27525
zoomBox -16.52025 512.17175 39.30050 542.07925
zoomBox -7.45125 521.75350 21.68750 537.36550
zoomBox -3.88650 525.71575 14.00875 535.30375
pan -1.40850 529.65050
zoomBox -3.67850 527.28275 9.25125 534.21025
zoomBox -1.66675 529.17325 5.08325 532.78975
zoomBox -1.05700 529.74625 3.82000 532.35925
pan 0.01100 531.21100
zoomBox -1.46200 529.90725 4.27600 532.98150
zoomBox -4.00025 528.40075 6.99275 534.29050
zoomBox -5.93400 526.93150 9.28125 535.08350
pan -0.53075 536.74400
pan -0.02050 540.34350
pan -0.34700 543.99075
zoomBox -6.83225 536.69025 8.38300 544.84225
pan -0.38100 545.06725
pan -0.21100 548.10200
pan -0.06125 551.04850
pan -0.11575 554.32150
pan -0.04100 556.66925
zoomBox -12.73475 545.54900 12.04100 558.82325
zoomBox -21.02675 539.81925 19.31650 561.43425
zoomBox -40.70400 526.22175 36.58150 567.62975
pan 1.90100 581.51200
pan -1.27875 588.80525
pan -1.14075 612.17050
pan 2.59225 624.89050
pan 4.32050 640.40975
zoomBox -56.87500 582.42825 68.97225 649.85450
zoomBox -79.09750 561.50300 95.08575 654.82650
zoomBox -129.95350 512.21325 153.67550 664.17550
zoomBox -250.63575 395.24825 292.70950 686.36075
zoomBox -481.82450 171.17950 559.05475 728.86000
pan -17.68925 784.27800
zoomBox -307.67075 457.83200 331.55925 800.31750
zoomBox -189.52425 553.36425 203.04300 763.69325
zoomBox -98.72350 626.37425 106.19950 736.16750
zoomBox -59.85825 657.63625 65.99025 725.06325
zoomBox -25.44925 685.31400 30.39100 715.23200
zoomBox -8.35500 699.06425 12.70550 710.34800
pan -0.32025 709.39725
