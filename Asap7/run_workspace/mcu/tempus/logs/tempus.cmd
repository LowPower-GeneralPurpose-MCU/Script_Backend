#######################################################
#                                                     
#  Tempus Timing Solution Command Logging File                     
#  Created on Sun Oct 11 12:35:16 2026                
#                                                     
#######################################################

#@(#)CDS: Tempus Timing Solution v23.15-s108_1 (64bit) 07/22/2025 11:26 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 23.15-s108_1 NR250707-2219/23_15-UB (database version 18.20.674) {superthreading v2.20}
#@(#)CDS: AAE 23.15-s032 (64bit) 07/22/2025 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 23.15-s037_1 () Jul 16 2025 02:46:10 ( )
#@(#)CDS: SYNTECH 23.15-s011_1 () Jun 23 2025 00:02:58 ( )
#@(#)CDS: CPE v23.15-s090

set_multi_cpu_usage -localCpu 1
read_view_definition /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/tempus/logs/tempus_views.tcl
read_verilog /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/innovus/outputs/top_soc_pnr.v
set_top_module top_soc
read_spef -rc_corner rc_ss /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/quantus/outputs/top_soc_quantus_rc_ss.spef
read_spef -rc_corner rc_typ /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/quantus/outputs/top_soc_quantus_rc_typ.spef
read_spef -rc_corner rc_ff /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/quantus/outputs/top_soc_quantus_rc_ff.spef
set_analysis_mode -analysisType onChipVariation -cppr both
set_delay_cal_mode -siAware true
set_si_mode -enable_glitch_report true
set_timing_derate -delay_corner dc_ss -late  -cell_delay -cell_check  $SRAM_DERATE_SS $sram_cells
set_timing_derate -delay_corner dc_ff -early -cell_delay -cell_check  $SRAM_DERATE_FF $sram_cells
update_timing -full
check_timing -verbose > /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/tempus/reports/check_timing.rpt
report_annotated_parasitics > /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/tempus/reports/annotated_parasitics.rpt
report_analysis_coverage > /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/tempus/reports/analysis_coverage.rpt
report_constraint -all_violators > /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/tempus/reports/all_violators.rpt
report_timing_derate > /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/tempus/reports/timing_derate.rpt
report_noise -txtfile /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/tempus/reports/glitch.rpt
report_timing -$kind -view $view -max_paths 100 -nworst 1  -path_type full_clock > $rpt
report_timing -$kind -view $view -max_paths 1 -collection
report_timing -$kind -view $view -max_paths 100 -nworst 1  -path_type full_clock > $rpt
report_timing -$kind -view $view -max_paths 1 -collection
report_timing -$kind -view $view -max_paths 100 -nworst 1  -path_type full_clock > $rpt
report_timing -$kind -view $view -max_paths 1 -collection
report_timing -$kind -view $view -max_paths 100 -nworst 1  -path_type full_clock > $rpt
report_timing -$kind -view $view -max_paths 1 -collection
exit 0
