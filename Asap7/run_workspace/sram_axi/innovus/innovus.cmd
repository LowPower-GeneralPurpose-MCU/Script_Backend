#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Aug  6 18:29:25 2026                
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
addRing -nets {VDD VSS} -type block_rings -around shared_cluster -layer {top M4 bottom M4 left M5 right M5} -width 0.096 -spacing 0.288 -offset 1.080 -snap_wire_center_to_grid Grid
deselectAll
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.056000 -number_of_sets 1 -area {123.552 2.16 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.040000 -number_of_sets 1 -area {249.264 2.16 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.024000 -number_of_sets 1 -area {374.976 2.16 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.104000 -number_of_sets 1 -area {2.16 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.136000 -number_of_sets 1 -area {2.16 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.168000 -number_of_sets 1 -area {2.16 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
applyGlobalNets
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -area {2.16 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.932000 -number_of_sets 1 -area {2.16 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -area {2.16 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 0.780000 -number_of_sets 1 -area {2.16 706.32 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.968000 -number_of_sets 1 -area {123.552 2.16 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.824000 -number_of_sets 1 -area {249.264 2.16 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.872000 -number_of_sets 1 -area {374.976 2.16 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -area {500.688 2.16 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setSrouteMode -extendNearestTarget true -blockPinRouteWithPinWidth true -viaConnectToShape blockring
sroute -connect blockPin -nets {VDD VSS} -blockPin useLef -blockPinTarget nearestTarget
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from left -start_offset 3.456000 -area {502.848 2.16 1103.04 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from left -start_offset 12.880000 -area {2.16 708.48 502.848 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from bottom -start_offset 4.672000 -area {2.16 708.48 1103.04 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -set_to_set_distance 25.856 -start_from bottom -start_offset 12.880000 -area {502.848 2.16 1103.04 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M6 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.104000 -number_of_sets 1 -area {502.848 174.96 1103.04 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.136000 -number_of_sets 1 -area {502.848 352.08 1103.04 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.640 -spacing 0.896 -start_from bottom -start_offset 1.168000 -number_of_sets 1 -area {502.848 529.2 1103.04 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M6 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.056000 -number_of_sets 1 -area {123.552 708.48 127.872 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.040000 -number_of_sets 1 -area {249.264 708.48 253.584 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.640 -spacing 0.896 -start_from left -start_offset 1.024000 -number_of_sets 1 -area {374.976 708.48 379.296 968.688} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M7 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 2.080000 -area {0.0 708.48 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 19.360000 -area {502.848 0.0 1105.2 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M8 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 0.352000 -area {502.848 0.0 1105.2 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 19.360000 -area {0.0 708.48 502.848 970.848} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
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
zoomBox 15.44750 130.08150 631.95550 681.98775
zoomBox 111.46700 296.88475 490.08000 635.82425
zoomBox 166.24200 373.13525 439.79000 618.01900
zoomBox 177.97300 402.17075 410.48900 610.32225
zoomBox 196.83725 447.99625 364.83050 598.38600
zoomBox 211.91425 481.52725 333.28950 590.18400
zoomBox 223.33025 505.62300 311.02375 584.12750
zoomBox 234.79925 529.74350 288.65425 577.95525
zoomBox 240.84800 544.01875 273.92175 573.62675
zoomBox 242.29200 547.42650 270.40475 572.59350
zoomBox 243.53025 550.32325 267.42625 571.71525
zoomBox 245.73025 554.87850 262.99525 570.33425
zoomBox 247.46550 558.11975 259.93950 569.28675
zoomBox 249.17750 561.22700 256.83825 568.08500
pan 0.06925 313.60550
zoomBox 248.77100 561.97850 257.78375 570.04675
zoomBox 248.21125 561.03175 258.81450 570.52400
zoomBox 245.84925 556.98075 263.11525 572.43750
zoomBox 243.49850 552.93975 267.39625 574.33325
fit
zoomBox -274.43675 162.66150 949.66050 818.50600
zoomBox -160.99750 303.14075 590.75150 705.91150
zoomBox -60.56425 427.51375 272.99125 606.22550
zoomBox -50.69650 442.79675 232.82575 594.70175
zoomBox -30.92925 476.94875 143.18875 570.23725
zoomBox -22.17925 492.05175 103.62100 559.45275
zoomBox -18.71925 497.96750 88.21100 555.25850
zoomBox -12.70825 507.13750 64.54950 548.53050
zoomBox -5.22675 518.54950 35.10250 540.15700
zoomBox -0.68175 525.48250 17.21300 535.07000
zoomBox -0.19850 526.30275 15.01200 534.45225
pan -0.63900 527.27700
zoomBox -3.62075 523.67575 21.14750 536.94600
zoomBox -7.34425 518.92200 32.98650 540.53025
zoomBox -13.30550 509.18675 52.36650 544.37225
zoomBox -27.80125 485.06275 98.00550 552.46725
zoomBox -39.66525 465.07325 134.46175 558.36675
pan 3.11500 545.23325
pan 3.58225 575.91575
pan -0.23350 610.49200
pan 0.54525 651.06450
zoomBox -23.27750 641.07225 102.52925 708.47675
pan -1.91300 688.93725
zoomBox -15.16025 680.66175 62.10100 722.05675
zoomBox -9.00100 689.87500 38.44775 715.29700
zoomBox -6.18075 694.36800 28.10125 712.73550
pan 0.07650 705.30150
zoomBox -11.21025 692.90700 44.61275 722.81575
zoomBox -13.49250 689.42200 52.18175 724.60875
zoomBox -9.44175 697.52350 38.00800 722.94600
zoomBox -4.36000 707.63650 20.40900 720.90725
zoomBox -2.20600 711.66325 13.00575 719.81325
zoomBox -4.39925 707.70875 20.37075 720.98000
zoomBox -9.60350 698.32550 37.84900 723.74950
zoomBox -19.57300 680.34975 71.33175 729.05450
zoomBox -33.03525 656.54175 114.98800 735.84950
pan -2.64800 718.63900
fit
zoomBox -375.02200 98.54350 1319.22950 1006.28650
zoomBox -315.46550 217.99725 1124.64825 989.57875
zoomBox -191.20275 464.78350 693.20725 938.63100
zoomBox -161.95325 520.13800 589.79525 922.90850
zoomBox -99.55225 637.15625 362.11550 884.50775
zoomBox -60.67300 709.17950 222.84925 861.08450
zoomBox -36.84500 753.36200 137.27325 846.65075
zoomBox -18.71825 786.97300 72.17300 835.67050
zoomBox -9.25600 804.51800 38.19000 829.93850
zoomBox -3.50750 815.17675 17.54500 826.45625
zoomBox -1.31625 819.24050 9.67375 825.12875
selectPhyPin 1.2960 2.1600 1.7760 968.6880 9 VDD
deselectAll
selectWire 0.9840 1.1360 1.4640 968.7520 9 VDD
deselectAll
selectPhyPin 0.3360 2.1600 0.8160 968.6880 9 VSS
zoomBox -3.28375 817.69625 14.61225 827.28450
pan -0.14400 818.77100
zoomBox -9.65700 813.17150 24.62575 831.53950
zoomBox -17.81725 810.15575 38.00725 840.06525
pan -0.32475 819.01025
pan -0.24975 809.82300
pan 0.34950 799.61175
pan 0.39950 791.74750
pan -0.14975 782.46000
pan 0.09975 778.11600
pan 0.32450 771.62500
zoomBox -21.24525 751.29300 44.43050 786.48075
pan -1.14550 759.17425
pan -0.11750 752.47725
zoomBox -33.01175 723.92650 57.88975 772.62950
zoomBox -67.66925 703.60100 106.46975 796.90100
zoomBox -134.06225 664.66375 199.53375 843.39725
zoomBox -95.51800 676.04900 145.50525 805.18400
zoomBox -39.69150 692.53925 67.25200 749.83725
zoomBox -33.01950 694.51225 57.88250 743.21550
zoomBox -19.82650 700.15950 35.99875 730.06950
zoomBox -14.00675 702.65375 26.32700 724.26375
