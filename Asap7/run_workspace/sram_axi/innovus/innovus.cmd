#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Fri Aug  7 10:22:06 2026                
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
createPlaceBlockage -name SRAM_ISLAND_GROUP_BLOCKAGE -type hard -noCutByCore -box {2.16 2.16 502.848 708.48}
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_after_macroFP.rpt
saveFPlan ./outputs/FloorPlan_withMacro.fp
saveDesign ./saved/axi_ram_macroFP.enc
deleteRouteBlk -name SRAM_ROUTE_GUARD_*
createRouteBlk -name SRAM_ROUTE_GUARD_00 -box {127.872 356.4 249.264 529.2} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_01 -box {127.872 533.52 249.264 706.32} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_02 -box {379.296 356.4 500.688 529.2} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_03 -box {379.296 533.52 500.688 706.32} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_04 -box {2.16 533.52 123.552 706.32} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_05 -box {2.16 356.4 123.552 529.2} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_06 -box {253.584 356.4 374.976 529.2} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_07 -box {253.584 533.52 374.976 706.32} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_08 -box {2.16 179.28 123.552 352.08} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_09 -box {2.16 2.16 123.552 174.96} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_10 -box {127.872 179.28 249.264 352.08} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_11 -box {253.584 179.28 374.976 352.08} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_12 -box {379.296 2.16 500.688 174.96} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_13 -box {379.296 179.28 500.688 352.08} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_14 -box {127.872 2.16 249.264 174.96} -layer {M4 M5} -exceptpgnet
createRouteBlk -name SRAM_ROUTE_GUARD_15 -box {253.584 2.16 374.976 174.96} -layer {M4 M5} -exceptpgnet
setRouteMode -earlyGlobalReverseDirection {(127.872000 356.400000 249.264000 529.200000) M5:M5 (127.872000 533.520000 249.264000 706.320000) M5:M5 (379.296000 356.400000 500.688000 529.200000) M5:M5 (379.296000 533.520000 500.688000 706.320000) M5:M5 (2.160000 533.520000 123.552000 706.320000) M5:M5 (2.160000 356.400000 123.552000 529.200000) M5:M5 (253.584000 356.400000 374.976000 529.200000) M5:M5 (253.584000 533.520000 374.976000 706.320000) M5:M5 (2.160000 179.280000 123.552000 352.080000) M5:M5 (2.160000 2.160000 123.552000 174.960000) M5:M5 (127.872000 179.280000 249.264000 352.080000) M5:M5 (253.584000 179.280000 374.976000 352.080000) M5:M5 (379.296000 2.160000 500.688000 174.960000) M5:M5 (379.296000 179.280000 500.688000 352.080000) M5:M5 (127.872000 2.160000 249.264000 174.960000) M5:M5 (253.584000 2.160000 374.976000 174.960000) M5:M5}
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_before_pnr.rpt
setAddStripeMode -reset
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
addRing -nets VDD -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 0.192 -snap_wire_center_to_grid Grid
addRing -nets VSS -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 1.152 -snap_wire_center_to_grid Grid
deselectAll
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M8
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.912000 -number_of_sets 1 -create_pins 0 -area {0.0 0.0 2.16 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 0.780000 -number_of_sets 1 -create_pins 0 -area {0.0 706.32 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -create_pins 0 -area {0.0 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.932000 -number_of_sets 1 -create_pins 0 -area {0.0 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -create_pins 0 -area {0.0 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M8
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -create_pins 0 -area {500.688 0.0 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.968000 -number_of_sets 1 -create_pins 0 -area {123.552 0.0 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.824000 -number_of_sets 1 -create_pins 0 -area {249.264 0.0 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.872000 -number_of_sets 1 -create_pins 0 -area {374.976 0.0 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setSrouteMode -reset
setSrouteMode -extendNearestTarget true -blockPinRouteWithPinWidth true -viaConnectToShape stripe
sroute -connect blockPin -nets {VSS VDD} -blockPin useLef -blockPinTarget stripe
editTrim -nets {VSS VDD}
setPinConstraint -corner_to_pin_distance 8
setPinAssignMode -pinEditInBatch true
editPin -pin {clk rst_n {s_axi_awid[4]} {s_axi_awid[3]} {s_axi_awid[2]} {s_axi_awid[1]} {s_axi_awid[0]} {s_axi_awaddr[31]} {s_axi_awaddr[30]} {s_axi_awaddr[29]} {s_axi_awaddr[28]} {s_axi_awaddr[27]} {s_axi_awaddr[26]} {s_axi_awaddr[25]} {s_axi_awaddr[24]} {s_axi_awaddr[23]} {s_axi_awaddr[22]} {s_axi_awaddr[21]} {s_axi_awaddr[20]} {s_axi_awaddr[19]} {s_axi_awaddr[18]} {s_axi_awaddr[17]} {s_axi_awaddr[16]} {s_axi_awaddr[15]} {s_axi_awaddr[14]} {s_axi_awaddr[13]} {s_axi_awaddr[12]} {s_axi_awaddr[11]} {s_axi_awaddr[10]} {s_axi_awaddr[9]} {s_axi_awaddr[8]} {s_axi_awaddr[7]} {s_axi_awaddr[6]} {s_axi_awaddr[5]} {s_axi_awaddr[4]} {s_axi_awaddr[3]} {s_axi_awaddr[2]} {s_axi_awaddr[1]} {s_axi_awaddr[0]} {s_axi_awlen[7]} {s_axi_awlen[6]} {s_axi_awlen[5]} {s_axi_awlen[4]} {s_axi_awlen[3]} {s_axi_awlen[2]} {s_axi_awlen[1]} {s_axi_awlen[0]} {s_axi_awsize[2]} {s_axi_awsize[1]} {s_axi_awsize[0]} {s_axi_awburst[1]} {s_axi_awburst[0]} s_axi_awlock {s_axi_awcache[3]} {s_axi_awcache[2]} {s_axi_awcache[1]} {s_axi_awcache[0]} {s_axi_awprot[2]} {s_axi_awprot[1]} {s_axi_awprot[0]} {s_axi_awqos[3]} {s_axi_awqos[2]} {s_axi_awqos[1]} {s_axi_awqos[0]} {s_axi_awregion[3]} {s_axi_awregion[2]} {s_axi_awregion[1]} {s_axi_awregion[0]} s_axi_awvalid s_axi_awready} -side TOP -layer M7 -spreadType range -start {10.16 968.688} -end {1095.04 968.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_wdata[31]} {s_axi_wdata[30]} {s_axi_wdata[29]} {s_axi_wdata[28]} {s_axi_wdata[27]} {s_axi_wdata[26]} {s_axi_wdata[25]} {s_axi_wdata[24]} {s_axi_wdata[23]} {s_axi_wdata[22]} {s_axi_wdata[21]} {s_axi_wdata[20]} {s_axi_wdata[19]} {s_axi_wdata[18]} {s_axi_wdata[17]} {s_axi_wdata[16]} {s_axi_wdata[15]} {s_axi_wdata[14]} {s_axi_wdata[13]} {s_axi_wdata[12]} {s_axi_wdata[11]} {s_axi_wdata[10]} {s_axi_wdata[9]} {s_axi_wdata[8]} {s_axi_wdata[7]} {s_axi_wdata[6]} {s_axi_wdata[5]} {s_axi_wdata[4]} {s_axi_wdata[3]} {s_axi_wdata[2]} {s_axi_wdata[1]} {s_axi_wdata[0]} {s_axi_wstrb[3]} {s_axi_wstrb[2]} {s_axi_wstrb[1]} {s_axi_wstrb[0]} s_axi_wlast s_axi_wvalid s_axi_wready {s_axi_bid[4]} {s_axi_bid[3]} {s_axi_bid[2]} {s_axi_bid[1]} {s_axi_bid[0]} {s_axi_bresp[1]} {s_axi_bresp[0]} s_axi_bvalid s_axi_bready} -side RIGHT -layer M6 -spreadType range -start {1103.04 960.688} -end {1103.04 10.16} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_arid[4]} {s_axi_arid[3]} {s_axi_arid[2]} {s_axi_arid[1]} {s_axi_arid[0]} {s_axi_araddr[31]} {s_axi_araddr[30]} {s_axi_araddr[29]} {s_axi_araddr[28]} {s_axi_araddr[27]} {s_axi_araddr[26]} {s_axi_araddr[25]} {s_axi_araddr[24]} {s_axi_araddr[23]} {s_axi_araddr[22]} {s_axi_araddr[21]} {s_axi_araddr[20]} {s_axi_araddr[19]} {s_axi_araddr[18]} {s_axi_araddr[17]} {s_axi_araddr[16]} {s_axi_araddr[15]} {s_axi_araddr[14]} {s_axi_araddr[13]} {s_axi_araddr[12]} {s_axi_araddr[11]} {s_axi_araddr[10]} {s_axi_araddr[9]} {s_axi_araddr[8]} {s_axi_araddr[7]} {s_axi_araddr[6]} {s_axi_araddr[5]} {s_axi_araddr[4]} {s_axi_araddr[3]} {s_axi_araddr[2]} {s_axi_araddr[1]} {s_axi_araddr[0]} {s_axi_arlen[7]} {s_axi_arlen[6]} {s_axi_arlen[5]} {s_axi_arlen[4]} {s_axi_arlen[3]} {s_axi_arlen[2]} {s_axi_arlen[1]} {s_axi_arlen[0]} {s_axi_arsize[2]} {s_axi_arsize[1]} {s_axi_arsize[0]} {s_axi_arburst[1]} {s_axi_arburst[0]} s_axi_arlock {s_axi_arcache[3]} {s_axi_arcache[2]} {s_axi_arcache[1]} {s_axi_arcache[0]} {s_axi_arprot[2]} {s_axi_arprot[1]} {s_axi_arprot[0]} {s_axi_arqos[3]} {s_axi_arqos[2]} {s_axi_arqos[1]} {s_axi_arqos[0]} {s_axi_arregion[3]} {s_axi_arregion[2]} {s_axi_arregion[1]} {s_axi_arregion[0]} s_axi_arvalid s_axi_arready} -side LEFT -layer M6 -spreadType range -start {2.16 10.16} -end {2.16 960.688} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_rid[4]} {s_axi_rid[3]} {s_axi_rid[2]} {s_axi_rid[1]} {s_axi_rid[0]} {s_axi_rdata[31]} {s_axi_rdata[30]} {s_axi_rdata[29]} {s_axi_rdata[28]} {s_axi_rdata[27]} {s_axi_rdata[26]} {s_axi_rdata[25]} {s_axi_rdata[24]} {s_axi_rdata[23]} {s_axi_rdata[22]} {s_axi_rdata[21]} {s_axi_rdata[20]} {s_axi_rdata[19]} {s_axi_rdata[18]} {s_axi_rdata[17]} {s_axi_rdata[16]} {s_axi_rdata[15]} {s_axi_rdata[14]} {s_axi_rdata[13]} {s_axi_rdata[12]} {s_axi_rdata[11]} {s_axi_rdata[10]} {s_axi_rdata[9]} {s_axi_rdata[8]} {s_axi_rdata[7]} {s_axi_rdata[6]} {s_axi_rdata[5]} {s_axi_rdata[4]} {s_axi_rdata[3]} {s_axi_rdata[2]} {s_axi_rdata[1]} {s_axi_rdata[0]} {s_axi_rresp[1]} {s_axi_rresp[0]} s_axi_rlast s_axi_rvalid s_axi_rready} -side BOTTOM -layer M7 -spreadType range -start {1095.04 2.16} -end {10.16 2.16} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
setPinAssignMode -pinEditInBatch false
saveDesign ./saved/axi_ram_floorplan_power_pins.enc
selectRouteBlk -box 2.16 2.16 123.552 174.96 SRAM_ROUTE_GUARD_09 -layer M5
deselectAll
selectRouteBlk -box 379.296 356.4 500.688 529.2 SRAM_ROUTE_GUARD_02 -layer M5
deselectAll
selectRouteBlk -box 253.584 533.52 374.976 706.32 SRAM_ROUTE_GUARD_07 -layer M5
fit
zoomBox -208.02625 149.60200 1232.08775 921.18375
zoomBox -78.45025 299.73175 962.03250 857.19975
zoomBox 23.94925 411.81625 775.69825 814.58700
zoomBox 61.92325 454.22800 700.91000 796.58325
zoomBox 94.20100 490.27825 637.34000 781.28025
zoomBox 141.65500 547.84325 534.07300 758.09225
pan 121.44600 424.44025
zoomBox 331.18525 606.03025 614.70750 757.93525
zoomBox 378.86300 631.47000 583.70800 741.22150
zoomBox 413.64075 650.07925 561.64125 729.37475
zoomBox 427.22300 657.97250 553.02325 725.37350
zoomBox 448.53400 671.25850 539.42475 719.95575
zoomBox 469.92875 684.60650 525.74725 714.51275
pan 1.04850 216.07575
zoomBox 458.99200 678.74600 536.24975 720.13900
zoomBox 419.44350 654.79550 567.44550 734.09175
zoomBox 343.68100 608.91375 627.20700 760.82075
zoomBox 198.54375 521.01875 741.69075 812.02500
zoomBox -79.49375 352.63925 961.00650 910.11650
setDelayCalMode -SIAware false -equivalent_waveform_model none
setPlaceMode -reset
setPlaceMode -place_global_uniform_density true -place_global_module_aware_spare true -place_global_auto_blockage_in_channel soft -place_detail_preroute_as_obs {2 3} -place_global_cong_effort high -place_design_refine_macro false
place_opt_design
refinePlace
checkPlace ./verify_rpt/checkPlace_after_place.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_after_place.rpt
timeDesign -preCTS -outDir ./reports/timing_preCTS
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M7 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 2.080000 -create_pins 0 -area {0.0 708.48 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 19.360000 -create_pins 0 -area {502.848 0.0 1105.2 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M8 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 0.352000 -create_pins 0 -area {502.848 0.0 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 19.360000 -create_pins 0 -area {0.0 708.48 502.848 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setSrouteMode -viaConnectToShape {stripe ring}
sroute -connect corePin -nets {VDD VSS} -allowJogging 0 -allowLayerChange 0
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M1 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -set_to_set_distance 25.920 -start_from left -start_offset 1.872000 -number_of_sets 1 -create_pins 0 -area {502.848 0.0 507.168 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -set_to_set_distance 25.920 -start_from left -start_offset 11.760000 -create_pins 0 -area {507.168 0.0 1103.04 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -set_to_set_distance 25.920 -start_from left -start_offset 24.288000 -create_pins 0 -area {2.16 708.48 502.848 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet -report ./verify_rpt/pg_connectivity_before_trim.rpt
editTrim -nets {VDD VSS}
clearDrc
verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_trim.rpt
saveDesign ./saved/axi_ram_placed.enc
zoomBox -328.64250 252.90825 1111.49650 1024.50325
zoomBox -675.71150 110.41925 1317.56075 1178.37100
zoomBox -199.63450 277.25275 1024.48425 933.10875
zoomBox 149.97250 438.44875 788.97025 780.80975
zoomBox 362.36450 536.37800 645.89125 688.28550
zoomBox 443.33925 573.71375 591.34225 653.01050
zoomBox 456.60400 579.82975 582.40650 647.23200
zoomBox 492.53275 596.39550 558.20275 631.58000
zoomBox 498.41825 599.10900 554.23800 629.01600
zoomBox 467.87825 585.02775 574.81150 642.32025
zoomBox 427.37225 565.85650 601.49525 659.14775
zoomBox 331.25050 520.07750 664.81550 698.79425
zoomBox 147.52100 432.65225 786.52750 775.01800
create_route_type -name leaf_rule -bottom_preferred_layer M2 -top_preferred_layer M3
create_route_type -name trunk_rule -shield_net VSS -bottom_preferred_layer M4 -top_preferred_layer M5
create_route_type -name top_rule -shield_net VSS -bottom_preferred_layer M6 -top_preferred_layer M7
set_ccopt_property -net_type leaf route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top route_type top_rule
set_ccopt_property routing_top_min_fanout 100
set_ccopt_property target_max_trans 0.3ns
set_ccopt_property buffer_cells {
    BUFx4_ASAP7_75t_R
    BUFx8_ASAP7_75t_R
    BUFx12_ASAP7_75t_R
}
set_ccopt_property inverter_cells {
    CKINVDCx8_ASAP7_75t_R
    CKINVDCx12_ASAP7_75t_R
    CKINVDCx16_ASAP7_75t_R
}
set_ccopt_property use_inverters auto
setOptMode -reclaimArea true -leakageToDynamicRatio 0.5 -powerEffort high -fixFanoutLoad true
optDesign -prefix preCTS -preCTS
clock_opt_design
all_constraint_modes -active
set_interactive_constraint_modes $active_constraint_modes
set_propagated_clock [all_clocks]
set_interactive_constraint_modes {}
optDesign -prefix postCTS -postCTS -setup -hold
timeDesign -postCTS -outDir ./reports/timing_postCTS
selectRouteBlk -box 127.872 533.52 249.264 706.32 SRAM_ROUTE_GUARD_01 -layer M4
zoomBox -105.12850 295.82300 935.38750 853.30875
zoomBox -516.52525 73.01950 1177.78125 980.79200
zoomBox -1492.77550 -455.69575 1752.98450 1283.31150
zoomBox -1194.90875 -303.93200 1563.98725 1174.22425
zoomBox -660.23400 -55.87750 1034.07350 851.89550
zoomBox -532.59275 3.34000 907.56875 774.94700
zoomBox -264.67325 127.60675 619.76650 601.47025
zoomBox -194.89900 160.47650 556.87475 563.26050
zoomBox -90.59050 214.49675 452.56625 505.50825
zoomBox -265.35350 123.37575 619.08725 597.23975
zoomBox -137.14350 250.21225 406.01400 541.22425
deselectAll
selectRouteBlk -box 2.16 356.4 123.552 529.2 SRAM_ROUTE_GUARD_05 -layer M4
deselectAll
selectRouteBlk -box 2.16 356.4 123.552 529.2 SRAM_ROUTE_GUARD_05 -layer M4
deselectAll
selectWire 54.2240 278.8640 54.3520 711.5680 7 u_mem/FE_OFN939_n
zoomBox -259.85925 181.83325 624.58225 655.69775
zoomBox -460.92450 66.76150 979.24150 838.37100
zoomBox -797.63275 -135.99225 1547.43725 1120.44500
fit
fit
fit
zoomBox -327.50700 114.47550 1112.60725 886.05725
zoomBox -275.24175 176.20850 948.85550 832.05300
zoomBox -133.67475 343.42000 505.31225 685.77525
zoomBox -91.80350 393.14200 369.86475 640.49375
zoomBox -76.93750 411.84825 315.48050 622.09725
zoomBox -45.24425 452.14225 195.74975 581.26150
zoomBox -26.23800 476.63825 121.76250 555.93375
zoomBox -11.78000 495.27300 65.47775 536.66600
zoomBox -6.52750 502.83250 40.91900 528.25325
zoomBox -5.30550 504.62125 35.02425 526.22900
zoomBox -4.26650 506.14175 30.01375 524.50825
pan -0.41375 513.16775
zoomBox -7.09450 505.53875 40.35225 530.95975
zoomBox -15.06150 494.44375 75.83300 543.14300
zoomBox -30.32350 473.18900 143.80225 566.48175
zoomBox -70.35375 417.43950 322.08250 627.69825
zoomBox -136.24525 325.67375 615.53975 728.46375
zoomBox -173.20975 285.20875 711.24350 759.07950
fit
zoomBox -671.36125 -65.31925 2087.44475 1412.78875
zoomBox -815.93500 -75.98800 2429.71900 1662.96250
saveDesign ./saved/axi_ram_postCTS.enc
