#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Aug  6 22:17:54 2026                
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
deletePGPin -net VDD
deletePGPin -net VSS
deleteAllPowerPreroutes
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets
addRing -nets {VSS VDD} -type core_rings -follow core -layer {top M4 bottom M4 left M5 right M5} -width 0.288 -spacing 0.288 -offset 0.384 -snap_wire_center_to_grid Grid
deletePGPin -net VDD
deletePGPin -net VSS
createPGPin VSS -geom M5 1.584000 484.848000 1.872000 486.000000 -net VSS
createPGPin VDD -geom M5 1.008000 484.848000 1.296000 486.000000 -net VDD
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
addRing -nets {VSS VDD} -type block_rings -around shared_cluster -layer {top M4 bottom M4 left M5 right M5} -width {top 0.288 bottom 0.288 left 0.288 right 0.288} -spacing {top 0.288 bottom 0.288 left 0.288 right 0.288} -offset {top 0.384 bottom 0.384 left 0.384 right 0.384} -snap_wire_center_to_grid Grid
setSrouteMode -extendNearestTarget true -blockPinRouteWithPinWidth true -viaConnectToShape blockring
sroute -connect blockPin -nets {VSS VDD} -blockPin useLef -blockPinTarget nearestTarget
setAddStripeMode -allow_jog none -break_at block_ring -extend_to_closest_target ring -max_extension_distance 1.632 -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.288 -spacing 0.288 -start_from bottom -start_offset 1.740000 -number_of_sets 1 -create_pins 0 -area {2.16 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.288 -spacing 0.288 -start_from bottom -start_offset 1.644000 -number_of_sets 1 -create_pins 0 -area {2.16 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.288 -spacing 0.288 -start_from bottom -start_offset 1.740000 -number_of_sets 1 -create_pins 0 -area {2.16 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -break_at block_ring -extend_to_closest_target ring -max_extension_distance 1.632 -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.288 -spacing 0.288 -start_from left -start_offset 1.680000 -number_of_sets 1 -create_pins 0 -area {123.552 2.16 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.288 -spacing 0.288 -start_from left -start_offset 1.728000 -number_of_sets 1 -create_pins 0 -area {249.264 2.16 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.288 -spacing 0.288 -start_from left -start_offset 1.776000 -number_of_sets 1 -create_pins 0 -area {374.976 2.16 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
editTrim -nets {VSS VDD}
clearDrc
deselectAll
editTrim -nets {VDD VSS}
verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet -report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt
verify_drc -report ./verify_rpt/pg_drc_before_stdcell_place.rpt
setPinConstraint -corner_to_pin_distance 8
setPinAssignMode -pinEditInBatch true
editPin -pin {clk rst_n {s_axi_awid[4]} {s_axi_awid[3]} {s_axi_awid[2]} {s_axi_awid[1]} {s_axi_awid[0]} {s_axi_awaddr[31]} {s_axi_awaddr[30]} {s_axi_awaddr[29]} {s_axi_awaddr[28]} {s_axi_awaddr[27]} {s_axi_awaddr[26]} {s_axi_awaddr[25]} {s_axi_awaddr[24]} {s_axi_awaddr[23]} {s_axi_awaddr[22]} {s_axi_awaddr[21]} {s_axi_awaddr[20]} {s_axi_awaddr[19]} {s_axi_awaddr[18]} {s_axi_awaddr[17]} {s_axi_awaddr[16]} {s_axi_awaddr[15]} {s_axi_awaddr[14]} {s_axi_awaddr[13]} {s_axi_awaddr[12]} {s_axi_awaddr[11]} {s_axi_awaddr[10]} {s_axi_awaddr[9]} {s_axi_awaddr[8]} {s_axi_awaddr[7]} {s_axi_awaddr[6]} {s_axi_awaddr[5]} {s_axi_awaddr[4]} {s_axi_awaddr[3]} {s_axi_awaddr[2]} {s_axi_awaddr[1]} {s_axi_awaddr[0]} {s_axi_awlen[7]} {s_axi_awlen[6]} {s_axi_awlen[5]} {s_axi_awlen[4]} {s_axi_awlen[3]} {s_axi_awlen[2]} {s_axi_awlen[1]} {s_axi_awlen[0]} {s_axi_awsize[2]} {s_axi_awsize[1]} {s_axi_awsize[0]} {s_axi_awburst[1]} {s_axi_awburst[0]} s_axi_awlock {s_axi_awcache[3]} {s_axi_awcache[2]} {s_axi_awcache[1]} {s_axi_awcache[0]} {s_axi_awprot[2]} {s_axi_awprot[1]} {s_axi_awprot[0]} {s_axi_awqos[3]} {s_axi_awqos[2]} {s_axi_awqos[1]} {s_axi_awqos[0]} {s_axi_awregion[3]} {s_axi_awregion[2]} {s_axi_awregion[1]} {s_axi_awregion[0]} s_axi_awvalid s_axi_awready} -side TOP -layer M7 -spreadType range -start {10.16 968.688} -end {1095.04 968.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_wdata[31]} {s_axi_wdata[30]} {s_axi_wdata[29]} {s_axi_wdata[28]} {s_axi_wdata[27]} {s_axi_wdata[26]} {s_axi_wdata[25]} {s_axi_wdata[24]} {s_axi_wdata[23]} {s_axi_wdata[22]} {s_axi_wdata[21]} {s_axi_wdata[20]} {s_axi_wdata[19]} {s_axi_wdata[18]} {s_axi_wdata[17]} {s_axi_wdata[16]} {s_axi_wdata[15]} {s_axi_wdata[14]} {s_axi_wdata[13]} {s_axi_wdata[12]} {s_axi_wdata[11]} {s_axi_wdata[10]} {s_axi_wdata[9]} {s_axi_wdata[8]} {s_axi_wdata[7]} {s_axi_wdata[6]} {s_axi_wdata[5]} {s_axi_wdata[4]} {s_axi_wdata[3]} {s_axi_wdata[2]} {s_axi_wdata[1]} {s_axi_wdata[0]} {s_axi_wstrb[3]} {s_axi_wstrb[2]} {s_axi_wstrb[1]} {s_axi_wstrb[0]} s_axi_wlast s_axi_wvalid s_axi_wready {s_axi_bid[4]} {s_axi_bid[3]} {s_axi_bid[2]} {s_axi_bid[1]} {s_axi_bid[0]} {s_axi_bresp[1]} {s_axi_bresp[0]} s_axi_bvalid s_axi_bready} -side RIGHT -layer M6 -spreadType range -start {1103.04 10.16} -end {1103.04 960.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_arid[4]} {s_axi_arid[3]} {s_axi_arid[2]} {s_axi_arid[1]} {s_axi_arid[0]} {s_axi_araddr[31]} {s_axi_araddr[30]} {s_axi_araddr[29]} {s_axi_araddr[28]} {s_axi_araddr[27]} {s_axi_araddr[26]} {s_axi_araddr[25]} {s_axi_araddr[24]} {s_axi_araddr[23]} {s_axi_araddr[22]} {s_axi_araddr[21]} {s_axi_araddr[20]} {s_axi_araddr[19]} {s_axi_araddr[18]} {s_axi_araddr[17]} {s_axi_araddr[16]} {s_axi_araddr[15]} {s_axi_araddr[14]} {s_axi_araddr[13]} {s_axi_araddr[12]} {s_axi_araddr[11]} {s_axi_araddr[10]} {s_axi_araddr[9]} {s_axi_araddr[8]} {s_axi_araddr[7]} {s_axi_araddr[6]} {s_axi_araddr[5]} {s_axi_araddr[4]} {s_axi_araddr[3]} {s_axi_araddr[2]} {s_axi_araddr[1]} {s_axi_araddr[0]} {s_axi_arlen[7]} {s_axi_arlen[6]} {s_axi_arlen[5]} {s_axi_arlen[4]} {s_axi_arlen[3]} {s_axi_arlen[2]} {s_axi_arlen[1]} {s_axi_arlen[0]} {s_axi_arsize[2]} {s_axi_arsize[1]} {s_axi_arsize[0]} {s_axi_arburst[1]} {s_axi_arburst[0]} s_axi_arlock {s_axi_arcache[3]} {s_axi_arcache[2]} {s_axi_arcache[1]} {s_axi_arcache[0]} {s_axi_arprot[2]} {s_axi_arprot[1]} {s_axi_arprot[0]} {s_axi_arqos[3]} {s_axi_arqos[2]} {s_axi_arqos[1]} {s_axi_arqos[0]} {s_axi_arregion[3]} {s_axi_arregion[2]} {s_axi_arregion[1]} {s_axi_arregion[0]} s_axi_arvalid s_axi_arready} -side LEFT -layer M6 -spreadType range -start {2.16 10.16} -end {2.16 960.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_rid[4]} {s_axi_rid[3]} {s_axi_rid[2]} {s_axi_rid[1]} {s_axi_rid[0]} {s_axi_rdata[31]} {s_axi_rdata[30]} {s_axi_rdata[29]} {s_axi_rdata[28]} {s_axi_rdata[27]} {s_axi_rdata[26]} {s_axi_rdata[25]} {s_axi_rdata[24]} {s_axi_rdata[23]} {s_axi_rdata[22]} {s_axi_rdata[21]} {s_axi_rdata[20]} {s_axi_rdata[19]} {s_axi_rdata[18]} {s_axi_rdata[17]} {s_axi_rdata[16]} {s_axi_rdata[15]} {s_axi_rdata[14]} {s_axi_rdata[13]} {s_axi_rdata[12]} {s_axi_rdata[11]} {s_axi_rdata[10]} {s_axi_rdata[9]} {s_axi_rdata[8]} {s_axi_rdata[7]} {s_axi_rdata[6]} {s_axi_rdata[5]} {s_axi_rdata[4]} {s_axi_rdata[3]} {s_axi_rdata[2]} {s_axi_rdata[1]} {s_axi_rdata[0]} {s_axi_rresp[1]} {s_axi_rresp[0]} s_axi_rlast s_axi_rvalid s_axi_rready} -side BOTTOM -layer M7 -spreadType range -start {10.16 2.16} -end {1095.04 2.16} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
setPinAssignMode -pinEditInBatch false
saveDesign ./saved/axi_ram_floorplan_power_pins.enc
zoomBox -227.17675 -236.11325 953.85900 821.16575
zoomBox -562.21850 -692.11575 1360.90100 1029.48675
fit
zoomBox 47.73800 95.32000 926.09600 881.63800
zoomBox 151.21650 250.09950 690.63825 732.99700
zoomBox 229.93600 367.84525 511.51775 619.92100
zoomBox 255.40950 404.33675 458.85250 586.46175
zoomBox 267.56850 419.25950 440.49525 574.06575
zoomBox 285.15200 434.96375 432.13975 566.54925
zoomBox 299.44175 449.96675 424.38150 561.81450
zoomBox 321.64325 473.55875 411.91250 554.36900
zoomBox 342.64175 496.94550 398.07875 546.57350
zoomBox 358.61600 514.73675 387.55475 540.64300
zoomBox 366.95425 524.02350 382.06100 537.54725
zoomBox 360.35975 518.38675 384.95900 540.40825
zoomBox 338.93400 500.07350 394.37475 549.70475
zoomBox 303.66675 469.92900 409.87375 565.00700
zoomBox 181.81800 365.77900 463.42325 617.87575
zoomBox 2.68150 212.99600 542.14950 695.93500
zoomBox -340.48700 -79.68775 692.96475 845.47225
zoomBox -214.09400 140.59725 420.57475 708.76125
zoomBox -122.53300 328.15525 267.23325 677.07925
zoomBox -41.46975 494.20950 131.47225 649.02950
zoomBox -14.41375 557.09050 75.86300 637.90750
zoomBox -3.86300 587.68175 43.26225 629.86900
pan -5.91375 601.17700
pan -0.36575 634.28075
pan -2.74350 642.81575
pan -2.07275 654.21600
zoomBox -24.68900 616.62250 52.04725 685.31775
zoomBox -40.53250 579.32175 84.42000 691.18100
pan -7.27425 669.15625
zoomBox -27.41025 666.54800 49.32625 735.24350
zoomBox -12.84275 695.39825 27.21400 731.25750
zoomBox -6.13025 710.48250 14.77975 729.20150
zoomBox -2.80775 718.30500 8.10775 728.07675
zoomBox -0.79675 722.92400 4.04650 727.25975
fit
zoomBox -46.15700 289.60675 700.44725 957.97700
zoomBox -25.28575 515.08925 433.22250 925.55200
zoomBox -8.27450 682.36825 231.07000 896.63275
zoomBox 2.74850 773.14175 108.94750 868.21250
zoomBox 4.31150 792.31850 81.04025 861.00700
pan -60.54925 793.06950
zoomBox -46.03875 804.27475 19.18075 862.66000
zoomBox -32.43575 815.06825 14.68525 857.25150
zoomBox -17.25500 828.58800 7.34275 850.60825
zoomBox -9.33075 835.64550 3.50975 847.14050
setLayerPreference node_layer -isVisible 0
setLayerPreference V9 -isVisible 1
setLayerPreference M9 -isVisible 1
setLayerPreference V8 -isVisible 1
zoomBox -21.07375 831.87275 3.52500 853.89400
zoomBox -35.15100 824.93150 4.90450 860.78975
pan 18.65475 863.29525
fit
zoomBox -214.92800 204.62700 1009.16900 860.47150
zoomBox -185.20150 273.52350 855.28100 830.99125
zoomBox -104.68325 460.13850 438.45525 751.14025
zoomBox -65.03500 537.93550 268.52000 716.64700
zoomBox -34.30250 596.97575 139.81525 690.26425
zoomBox -20.33025 621.94550 86.60000 679.23650
setLayerPreference node_layer -isVisible 1
pan -6.74300 658.29650
zoomBox -39.38000 622.26175 108.62075 701.55725
zoomBox -67.32825 585.78775 173.66650 714.90750
pan -7.65250 677.79750
zoomBox -45.57725 651.31000 102.42375 730.60575
zoomBox -27.49475 676.36575 63.39700 725.06350
zoomBox -16.37400 690.71800 39.44500 720.62450
zoomBox -7.91400 701.63600 21.22400 717.24750
zoomBox -12.34375 698.25750 27.98600 719.86525
zoomBox -22.45325 690.60750 43.21775 725.79250
zoomBox -15.94125 696.93200 31.50600 722.35325
zoomBox -22.73850 689.71925 42.93250 724.90425
zoomBox -27.13875 685.35525 50.12125 726.74950
zoomBox -54.06400 658.96800 93.94200 738.26650
zoomBox -105.03875 604.72050 178.49500 756.63175
pan -3.04325 746.02525
pan -2.66275 807.39850
zoomBox -93.39825 719.70650 147.60575 848.83125
zoomBox -131.15350 675.45225 202.41650 854.17175
zoomBox -216.54725 575.90450 326.61675 866.92000
pan 111.49925 780.30625
zoomBox -240.14775 499.56775 511.63675 902.35750
pan 148.27225 697.35200
pan 234.00825 557.82150
zoomBox -191.86500 300.32025 1032.29075 956.19625
zoomBox -1007.00525 -80.17875 1338.09350 1176.27400
pan 438.39500 1011.77875
zoomBox -100.90975 257.68700 1593.42450 1165.47425
zoomBox 81.74625 356.46000 1521.93050 1128.07925
zoomBox 473.19325 583.37500 1357.64700 1057.24600
zoomBox 566.93875 637.90175 1318.72475 1040.69225
zoomBox 775.94750 757.90975 1237.63825 1005.27350
zoomBox 934.94725 849.20375 1175.95300 978.32925
zoomBox 1031.54250 904.66650 1138.47825 961.96025
zoomBox 1060.34950 923.10225 1126.02150 958.28775
pan -0.23475 -117.06975
zoomBox 1076.40075 953.63825 1116.73150 975.24650
zoomBox 1088.79000 961.51800 1109.84325 972.79775
fit
