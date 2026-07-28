#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Mon Jul 27 02:11:10 2026                
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
timeDesign -proto -prePlace -outDir ./reports/hierFP_proto_timing
set_proto_design_mode -timing_aware true -congestion_aware true
proto_design
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_proto.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_final.rpt
saveFPlan ./outputs/FloorPlan.fp
saveDesign ./saved/axi_ram_hierFP.enc
placeInstance {u_mem/G_SRAM_BANK[0].u_sram} 2.16 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[1].u_sram} 127.872 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[2].u_sram} 253.584 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[3].u_sram} 379.296 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[4].u_sram} 379.296 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[5].u_sram} 253.584 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[6].u_sram} 127.872 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[7].u_sram} 2.16 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[8].u_sram} 2.16 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[9].u_sram} 127.872 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[10].u_sram} 253.584 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[11].u_sram} 379.296 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[12].u_sram} 379.296 533.52 R180
placeInstance {u_mem/G_SRAM_BANK[13].u_sram} 253.584 533.52 R180
placeInstance {u_mem/G_SRAM_BANK[14].u_sram} 127.872 533.52 R180
placeInstance {u_mem/G_SRAM_BANK[15].u_sram} 2.16 533.52 R180
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
placeInstance {u_mem/G_SRAM_BANK[10].u_sram} 2.16 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[11].u_sram} 127.872 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[14].u_sram} 253.584 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[15].u_sram} 379.296 2.16 R180
placeInstance {u_mem/G_SRAM_BANK[13].u_sram} 2.16 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[12].u_sram} 127.872 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[8].u_sram} 253.584 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[9].u_sram} 379.296 179.28 R180
placeInstance {u_mem/G_SRAM_BANK[5].u_sram} 2.16 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[4].u_sram} 127.872 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[7].u_sram} 253.584 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[6].u_sram} 379.296 356.4 R180
placeInstance {u_mem/G_SRAM_BANK[1].u_sram} 2.16 533.52 R180
placeInstance {u_mem/G_SRAM_BANK[0].u_sram} 127.872 533.52 R180
placeInstance {u_mem/G_SRAM_BANK[3].u_sram} 253.584 533.52 R180
placeInstance {u_mem/G_SRAM_BANK[2].u_sram} 379.296 533.52 R180
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
snapFPlan -block
cutRow -area {2.16 2.16 502.848 708.48}
createPlaceBlockage -name SRAM_ISLAND_GROUP_BLOCKAGE -type hard -noCutByCore -box {0.0 0.0 502.848 708.48}
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_after_macroFP.rpt
saveFPlan ./outputs/FloorPlan_withMacro.fp
saveDesign ./saved/axi_ram_macroFP.enc
fit
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_before_pnr.rpt
setAddStripeMode -allow_jog none
clearGlobalNets
deleteAllPowerPreroutes
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets
addRing -nets {VDD VSS} -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 0.384
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
addRing -nets {VDD VSS} -type block_rings -around shared_cluster -layer {top M4 bottom M4 left M5 right M5} -width 0.096 -spacing 0.288 -offset 1.080
deselectAll
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.072 -number_of_sets 1 -area {123.552 2.16 127.872 708.48} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.072 -number_of_sets 1 -area {249.264 2.16 253.584 708.48} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.072 -number_of_sets 1 -area {374.976 2.16 379.296 708.48} -snap_wire_center_to_grid grid
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.072 -number_of_sets 1 -area {2.16 174.96 502.848 179.28} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.072 -number_of_sets 1 -area {2.16 352.08 502.848 356.4} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.072 -number_of_sets 1 -area {2.16 529.2 502.848 533.52} -snap_wire_center_to_grid grid
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
applyGlobalNets
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.92 -number_of_sets 1 -area {2.16 174.96 502.848 179.28} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.92 -number_of_sets 1 -area {2.16 352.08 502.848 356.4} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.92 -number_of_sets 1 -area {2.16 529.2 502.848 533.52} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 0.84 -number_of_sets 1 -area {2.16 706.32 502.848 708.48} -snap_wire_center_to_grid grid
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M4 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.92 -number_of_sets 1 -area {123.552 2.16 127.872 708.48} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.92 -number_of_sets 1 -area {249.264 2.16 253.584 708.48} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.92 -number_of_sets 1 -area {374.976 2.16 379.296 708.48} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.84 -number_of_sets 1 -area {500.688 2.16 502.848 708.48} -snap_wire_center_to_grid grid
setSrouteMode -extendNearestTarget true -blockPinRouteWithPinWidth true -viaConnectToShape {stripe blockring ring}
sroute -connect blockPin -nets {VDD VSS} -blockPin useLef -blockPinTarget nearestTarget -allowJogging 0 -allowLayerChange 0
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -set_to_set_distance 25.920 -start_from left -start_offset 4.592 -area {502.848 2.16 1103.04 968.688} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -set_to_set_distance 25.920 -start_from left -start_offset 12.8 -area {2.16 708.48 502.848 968.688} -snap_wire_center_to_grid grid
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -set_to_set_distance 25.920 -start_from bottom -start_offset 6.32 -area {2.16 708.48 1103.04 968.688} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -set_to_set_distance 25.920 -start_from bottom -start_offset 12.8 -area {502.848 2.16 1103.04 708.48} -snap_wire_center_to_grid grid
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.072 -number_of_sets 1 -area {502.848 174.96 1103.04 179.28} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.072 -number_of_sets 1 -area {502.848 352.08 1103.04 356.4} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.072 -number_of_sets 1 -area {502.848 529.2 1103.04 533.52} -snap_wire_center_to_grid grid
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.072 -number_of_sets 1 -area {123.552 708.48 127.872 968.688} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.072 -number_of_sets 1 -area {249.264 708.48 253.584 968.688} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.072 -number_of_sets 1 -area {374.976 708.48 379.296 968.688} -snap_wire_center_to_grid grid
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M7 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 2.16 -area {0.0 708.48 1105.2 970.848} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 19.44 -area {502.848 0.0 1105.2 708.48} -snap_wire_center_to_grid grid
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M8 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 0.432 -area {502.848 0.0 1105.2 970.848} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 19.44 -area {0.0 708.48 502.848 970.848} -snap_wire_center_to_grid grid
verifyConnectivity -type special -noUnroutedNet -report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt
verify_drc -report ./verify_rpt/pg_drc_before_stdcell_place.rpt
saveDesign ./saved/axi_ram_powerplan.enc
zoomBox -351.22125 35.69750 1343.03075 943.44075
zoomBox -205.29675 168.16500 1018.80075 824.00975
zoomBox -99.86625 263.87275 784.54450 737.72075
zoomBox 6.05600 360.02725 549.19500 651.02925
zoomBox 31.34250 382.98175 493.01075 630.33350
zoomBox 52.83600 402.49325 445.25400 612.74225
zoomBox 70.90400 432.20100 354.42625 584.10600
zoomBox 84.38025 454.61475 289.22525 564.36625
zoomBox 90.48150 464.04175 264.59975 557.33050
zoomBox 100.07600 478.86525 225.87650 546.26650
zoomBox 112.01550 497.31325 177.68500 532.49750
zoomBox 117.04700 505.08725 157.37650 526.69500
zoomBox 118.48575 506.71050 152.76625 525.07725
zoomBox 121.57975 510.23025 142.63225 521.50975
zoomBox 122.81550 511.78225 138.02600 519.93175
selectMarker 0.0000 0.0000 1105.2000 970.8480 -1 3 7
deselectAll
selectMarker 125.8560 0.3360 125.9520 707.8800 5 1 12
zoomBox 122.25100 511.05475 140.14600 520.64250
zoomBox 118.80600 506.61325 153.08850 524.98100
zoomBox 114.27775 500.77500 170.10175 530.68425
zoomBox 103.53275 486.92100 210.47450 544.21800
zoomBox 106.93325 491.27550 197.83375 539.97800
pan -6.91100 394.74950
setPinConstraint -corner_to_pin_distance 8
setPinAssignMode -pinEditInBatch true
editPin -pin {clk rst_n {s_axi_awid[4]} {s_axi_awid[3]} {s_axi_awid[2]} {s_axi_awid[1]} {s_axi_awid[0]} {s_axi_awaddr[31]} {s_axi_awaddr[30]} {s_axi_awaddr[29]} {s_axi_awaddr[28]} {s_axi_awaddr[27]} {s_axi_awaddr[26]} {s_axi_awaddr[25]} {s_axi_awaddr[24]} {s_axi_awaddr[23]} {s_axi_awaddr[22]} {s_axi_awaddr[21]} {s_axi_awaddr[20]} {s_axi_awaddr[19]} {s_axi_awaddr[18]} {s_axi_awaddr[17]} {s_axi_awaddr[16]} {s_axi_awaddr[15]} {s_axi_awaddr[14]} {s_axi_awaddr[13]} {s_axi_awaddr[12]} {s_axi_awaddr[11]} {s_axi_awaddr[10]} {s_axi_awaddr[9]} {s_axi_awaddr[8]} {s_axi_awaddr[7]} {s_axi_awaddr[6]} {s_axi_awaddr[5]} {s_axi_awaddr[4]} {s_axi_awaddr[3]} {s_axi_awaddr[2]} {s_axi_awaddr[1]} {s_axi_awaddr[0]} {s_axi_awlen[7]} {s_axi_awlen[6]} {s_axi_awlen[5]} {s_axi_awlen[4]} {s_axi_awlen[3]} {s_axi_awlen[2]} {s_axi_awlen[1]} {s_axi_awlen[0]} {s_axi_awsize[2]} {s_axi_awsize[1]} {s_axi_awsize[0]} {s_axi_awburst[1]} {s_axi_awburst[0]} s_axi_awlock {s_axi_awcache[3]} {s_axi_awcache[2]} {s_axi_awcache[1]} {s_axi_awcache[0]} {s_axi_awprot[2]} {s_axi_awprot[1]} {s_axi_awprot[0]} {s_axi_awqos[3]} {s_axi_awqos[2]} {s_axi_awqos[1]} {s_axi_awqos[0]} {s_axi_awregion[3]} {s_axi_awregion[2]} {s_axi_awregion[1]} {s_axi_awregion[0]} s_axi_awvalid s_axi_awready} -side TOP -layer M7 -spreadType range -start {8.0 970.848} -end {1097.2 970.848} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_wdata[31]} {s_axi_wdata[30]} {s_axi_wdata[29]} {s_axi_wdata[28]} {s_axi_wdata[27]} {s_axi_wdata[26]} {s_axi_wdata[25]} {s_axi_wdata[24]} {s_axi_wdata[23]} {s_axi_wdata[22]} {s_axi_wdata[21]} {s_axi_wdata[20]} {s_axi_wdata[19]} {s_axi_wdata[18]} {s_axi_wdata[17]} {s_axi_wdata[16]} {s_axi_wdata[15]} {s_axi_wdata[14]} {s_axi_wdata[13]} {s_axi_wdata[12]} {s_axi_wdata[11]} {s_axi_wdata[10]} {s_axi_wdata[9]} {s_axi_wdata[8]} {s_axi_wdata[7]} {s_axi_wdata[6]} {s_axi_wdata[5]} {s_axi_wdata[4]} {s_axi_wdata[3]} {s_axi_wdata[2]} {s_axi_wdata[1]} {s_axi_wdata[0]} {s_axi_wstrb[3]} {s_axi_wstrb[2]} {s_axi_wstrb[1]} {s_axi_wstrb[0]} s_axi_wlast s_axi_wvalid s_axi_wready {s_axi_bid[4]} {s_axi_bid[3]} {s_axi_bid[2]} {s_axi_bid[1]} {s_axi_bid[0]} {s_axi_bresp[1]} {s_axi_bresp[0]} s_axi_bvalid s_axi_bready} -side RIGHT -layer M6 -spreadType range -start {1105.2 8.0} -end {1105.2 962.848} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
saveDesign ./saved/axi_ram_floorplan_power_pins.enc
setDelayCalMode -SIAware false -equivalent_waveform_model none
setPlaceMode -reset
setPlaceMode -place_global_uniform_density true -place_global_module_aware_spare true -place_global_auto_blockage_in_channel soft -place_detail_preroute_as_obs {2 3} -place_global_cong_effort high -place_design_refine_macro false
place_opt_design
refinePlace
checkPlace
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_after_place.rpt
timeDesign -preCTS -outDir ./reports/timing_preCTS
setSrouteMode -viaConnectToShape {stripe ring}
sroute -connect corePin -nets {VDD VSS} -allowJogging 0 -allowLayerChange 0
setAddStripeMode -allow_jog none -stacked_via_bottom_layer M1 -stacked_via_top_layer M6
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -set_to_set_distance 17.280 -start_from left -start_offset 9.072 -area {502.848 2.16 1103.04 968.688} -snap_wire_center_to_grid grid
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -set_to_set_distance 17.280 -start_from left -start_offset 8.64 -area {2.16 708.48 502.848 968.688} -snap_wire_center_to_grid grid
verifyConnectivity -type special -noUnroutedNet -report ./verify_rpt/pg_connectivity_before_trim.rpt
editTrim -nets {VDD VSS}
clearDrc
verifyConnectivity -type special -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_trim.rpt
saveDesign ./saved/axi_ram_placed.enc
fit
zoomBox -308.70000 70.46325 1385.55200 978.20650
zoomBox -193.67875 171.61825 1246.43550 943.20000
zoomBox -530.59925 -43.84250 1462.63850 1024.09075
zoomBox -76.54475 256.10850 1147.55250 911.95300
zoomBox 187.51400 432.71075 939.26300 835.48150
zoomBox 250.55175 474.87050 889.53875 817.22575
zoomBox 449.26875 607.77225 732.79075 759.67725
zoomBox 515.69600 658.98650 663.69650 738.28200
zoomBox 543.68875 680.56850 634.58000 729.26600
zoomBox 550.37125 685.72075 627.62900 727.11375
zoomBox 502.89300 649.11550 677.01300 742.40525
zoomBox 424.74125 588.86175 758.30175 767.57625
zoomBox 275.02775 473.43475 914.02550 815.79575
zoomBox -11.77625 252.31300 1212.34325 908.16950
zoomBox -561.20225 -171.28650 1783.82625 1085.12850
zoomBox -148.41800 150.84700 1291.72275 922.44300
zoomBox -49.87525 227.74900 1174.24425 883.60550
zoomBox 217.04025 436.04800 856.03850 778.40925
zoomBox 379.19575 562.59300 662.72300 714.50075
zoomBox 439.68450 611.20250 587.68750 690.49925
zoomBox 470.53225 636.70325 547.79100 678.09675
zoomBox 486.63500 650.01450 526.96475 671.62225
zoomBox 464.58675 631.78800 555.48075 680.48700
zoomBox 414.89550 590.70975 619.74800 700.46525
zoomBox 358.65425 544.13950 692.22275 722.85825
zoomBox 302.67425 497.78550 764.36075 745.14700
zoomBox 399.09950 577.63000 640.10300 706.75450
zoomBox 439.94125 611.40125 587.94825 690.70025
zoomBox 464.66575 632.14150 555.56075 680.84100
zoomBox 486.26175 650.54900 526.59250 672.15725
zoomBox 492.43475 656.19325 517.20350 669.46375
zoomBox 490.67925 654.59400 519.81900 670.20650
zoomBox 483.31725 647.89550 530.76725 673.31825
pan -3.22575 173.40625
zoomBox 463.08825 640.75025 553.98800 689.45225
selectWire 500.1280 670.7320 500.2000 707.4960 3 VDD
zoomBox 473.63600 651.94100 539.31100 687.12825
zoomBox 462.64800 640.82900 553.54775 689.53100
zoomBox 426.39025 604.16175 600.52625 697.46000
zoomBox 397.25600 574.69850 638.27500 703.83125
zoomBox 265.62700 441.58350 808.82450 732.61675
zoomBox 116.95300 291.23050 1001.45950 765.12975
pan -183.15125 152.91650
zoomBox -42.08125 409.38450 501.11675 700.41825
zoomBox -26.33325 494.78325 307.25875 673.51450
zoomBox -14.35275 559.74900 159.78425 653.04775
zoomBox -10.65725 579.41525 115.15675 646.82375
zoomBox -7.16000 593.56175 83.74100 642.26450
zoomBox -2.55500 611.16725 44.89625 636.59050
zoomBox -3.80200 604.23075 61.87450 639.41875
zoomBox -7.91750 581.34200 117.89900 648.75175
pan -6.86475 604.00200
pan -3.54500 631.57350
pan -1.06900 657.51325
pan -0.90025 680.18950
zoomBox -14.06625 673.53475 76.83625 722.23825
zoomBox -9.64400 682.66125 56.03325 717.84975
zoomBox -4.14075 694.01950 30.14350 712.38825
deselectAll
selectObstruct 0 0 502.848 708.48 SRAM_ISLAND_GROUP_BLOCKAGE
deselectAll
selectWire 0.9840 707.4000 501.8640 707.4960 4 VDD
deselectAll
selectWire 0.9840 0.9840 1.0800 707.4960 5 VDD
deselectAll
selectObstruct 0 0 502.848 708.48 SRAM_ISLAND_GROUP_BLOCKAGE
deselectAll
selectWire 2.6080 670.7320 2.6800 707.4960 3 VDD
zoomBox -8.38100 689.44925 39.07150 714.87325
zoomBox -15.00775 682.87125 50.67050 718.06025
zoomBox -12.12625 686.40050 43.70025 716.31100
zoomBox -14.95925 682.97250 50.71900 718.16150
zoomBox -22.31525 673.71000 68.58950 722.41475
deselectAll
zoomBox -31.45000 662.90450 94.36975 730.31600
pan 0.05625 687.26450
zoomBox -50.91000 641.44225 123.23525 734.74550
zoomBox -144.57425 629.45275 138.99275 781.38175
zoomBox -356.62075 599.60850 186.60475 890.65675
pan 43.24425 918.81550
zoomBox -246.50575 576.55275 215.23575 823.94375
pan 33.45350 834.62275
zoomBox -118.21300 608.00150 215.39525 786.74150
zoomBox -81.17450 615.76725 202.39250 767.69625
zoomBox -49.69175 622.36800 191.34025 751.50775
zoomBox -22.93150 627.97875 181.94575 737.74750
zoomBox 19.14900 636.80150 167.17300 716.10950
zoomBox 49.38675 643.41450 156.33450 700.71475
pan 6.40925 616.26875
pan 11.14425 583.55300
zoomBox 57.41925 635.62650 183.24025 703.03875
zoomBox 44.80775 631.40625 192.83275 710.71475
zoomBox -0.01950 618.89600 204.85950 728.66575
zoomBox -101.00225 590.57000 232.60950 769.31200
pan 64.00700 653.37725
pan 103.39600 559.08250
pan 24.02125 429.42725
zoomBox 90.42175 513.70200 424.03375 692.44400
zoomBox 177.70125 520.78325 382.58125 630.55350
zoomBox 216.35000 523.88525 364.37575 603.19425
zoomBox 264.44775 527.74550 341.71875 569.14550
pan 0.48375 254.55475
