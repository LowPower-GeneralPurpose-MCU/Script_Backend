#######################################################
#                                                     
#  Voltus IC Power Integrity Solution Command Logging File                     
#  Created on Sun Oct 11 12:53:50 2026                
#                                                     
#######################################################

#@(#)CDS: Voltus IC Power Integrity Solution v23.15-s108_1 (64bit) 07/22/2025 11:26 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 23.15-s108_1 NR250707-2219/23_15-UB (database version 18.20.674) {superthreading v2.20}
#@(#)CDS: AAE 23.15-s032 (64bit) 07/22/2025 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 23.15-s037_1 () Jul 16 2025 02:46:10 ( )
#@(#)CDS: SYNTECH 23.15-s011_1 () Jun 23 2025 00:02:58 ( )
#@(#)CDS: CPE v23.15-s090

set_multi_cpu_usage -localCpu 1
set_library_unit -time 1ns -cap 1pf
read_lib -lef {/home/user1/Desktop/Script_Backend/Asap7/asap7/asap7sc7p5t_28/techlef_misc/asap7_tech_1x_201209.fixed.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/asap7sc7p5t_28_R_1x_220121a.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/asap7sc7p5t_28_L_1x_220121a.lef /home/user1/Desktop/Script_Backend/Asap7/asap7/asap7sc7p5t_28/techlef_misc/srambank_256x4x32_6t122.fixed.lef /home/user1/Desktop/Script_Backend/Asap7/asap7/asap7sc7p5t_28/techlef_misc/srambank_128x4x20_6t122.fixed.lef}
read_lib {/home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LIB/srambank_256x4x32_6t122.lib /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LIB/srambank_128x4x20_6t122.lib}
read_verilog /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/innovus/outputs/top_soc_pnr.v
set_top_module top_soc
read_def /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/innovus/outputs/top_soc_pnr.def
read_sdc /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/innovus/outputs/top_soc_pnr.sdc
read_spef /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/quantus/outputs/top_soc_quantus_rc_typ.spef
set_power_analysis_mode -method static -corner max -create_binary_db true
set_power_output_dir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/voltus/outputs/power
report_power -outfile /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/voltus/reports/power_static.rpt
set_rail_analysis_mode -method era_static -accuracy hd -enable_xp false -em_temperature 110 -extraction_tech_file /home/user1/Desktop/asap7/asap7sc7p5t_28/qrc/qrcTechFile_typ03_unscaledV02 -lef_layermap /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/voltus/asap7_lefdef.layermap
set_rail_analysis_mode -method era_static -accuracy hd -enable_xp false -em_temperature 110 -extraction_tech_file /home/user1/Desktop/asap7/asap7sc7p5t_28/qrc/qrcTechFile_typ03_unscaledV02 -lef_layermap /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/voltus/asap7_lefdef.layermap
set_rail_analysis_mode -method era_static -accuracy hd -enable_xp false -em_temperature 110 -extraction_tech_file /home/user1/Desktop/asap7/asap7sc7p5t_28/qrc/qrcTechFile_typ03_unscaledV02
set_pg_nets -net VDD -voltage 0.7 -threshold 0.65
set_pg_nets -net VSS -voltage 0.0 -threshold 0.05
set_power_pads -net VDD -format defpin
set_power_pads -net VSS -format defpin
analyze_rail -type net -output /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/voltus/outputs/rail_VDD VDD
analyze_rail -type net -output /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/voltus/outputs/rail_VSS VSS
exit 0
