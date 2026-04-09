set ASAP7_DIR "../../Asap7/asap7"
set LIB_PATH "${ASAP7_DIR}/asap7sc7p5t_28/LIB/CCS"
set LEF_PATH "${ASAP7_DIR}/asap7sc7p5t_28/LEF/scaled"
set TOP Multiplier32
set SYNFILE "Multiplier32.v"

if {![file exists ./outputs]} { file mkdir outputs }
if {![file exists ./reports]} { file mkdir reports }

set_db / .init_lib_search_path ${LIB_PATH}
set_db / .script_search_path {./tcl}
set_db / .init_hdl_search_path {./rtl}

set_db / .hdl_unconnected_value 0

set MY_LIB [glob ${LIB_PATH}/*_TT_ccs_*.lib]
set_db library $MY_LIB
create_library_set -name libset -timing $MY_LIB

create_rc_corner -name rccorner -pre_route_res 1 -post_route_res 1 \
-pre_route_cap 1 -post_route_cap 1 -post_route_cross_cap 1 \
-pre_route_clock_res 0 -pre_route_clock_cap 0 -temperature 25

create_opcond -name opcond -process 1.0 -voltage 0.7 -temperature 25
create_timing_condition -name timecond -library_sets libset -opcond opcond
create_delay_corner -name corner -timing_condition timecond -rc_corner rccorner
create_constraint_mode -name mode_normal -sdc_files ./tcl/constraint.sdc
create_analysis_view -name tt -constraint_mode mode_normal -delay_corner corner
set_analysis_view -setup {tt} -hold {tt}

set_db / .hdl_track_filename_row_col true
set_db / .lp_insert_clock_gating false

####################################################################
## Load Design
####################################################################
read_hdl ${SYNFILE}
elaborate ${TOP}
uniquify ${TOP}

check_design -unresolved
report_metric -format html -file reports/sequencer.html

init_design
############################################################################
## Define cost groups (clock-clock, clock-output, input-clock, input-output)
############################################################################

if {[llength [all::all_seqs]] > 0} { 
  define_cost_group -name I2C -design ${TOP}
  define_cost_group -name C2O -design ${TOP}
  define_cost_group -name C2C -design ${TOP}
  
  path_group -from [all::all_seqs] -to [all::all_seqs] -group C2C -name C2C -view tt
  path_group -from [all::all_seqs] -to [all_outputs] -group C2O -name C2O -view tt
  path_group -from [all_inputs]  -to [all::all_seqs] -group I2C -name I2C -view tt 
}
define_cost_group -name I2O -design ${TOP}
path_group -from [all_inputs]  -to [all_outputs] -group I2O -name I2O -view tt
foreach cg [vfind / -cost_group *] {
  report_timing -cost_group [list $cg] >> reports/synthesis_pretim.rpt }

###########################################################
## Synthesizing 
###########################################################
# generic
set_db / .syn_generic_effort high
syn_generic
write_hdl > outputs/synthesis_generic.v

# map to gates
set_db / .syn_map_effort high
syn_map
write_hdl > outputs/synthesis_map.v

# flatten the design
ungroup -all

set_db / .syn_opt_effort extreme
syn_opt
write_hdl > outputs/synthesis_net.v

###############################################################
## write backend file set (verilog, SDC, config, etc.)
###############################################################
report_dp > reports/synthesis_datapath_incr.rpt
report_messages > reports/synthesis_messages.rpt
write_sdc -view tt > outputs/synthesis.sdc
write_parasitics > outputs/synthesis.spef

report_qor > reports/synthesis_qor.rpt
report_area > reports/synthesis_area.rpt
report_gate > reports/synthesis_gate.rpt
report_module > reports/synthesis_module.rpt
#report_clock_gating -ungated_ff > reports/synthesis_CG.rpt
report_power > reports/synthesis_power.rpt
report_timing > reports/synthesis_timing.rpt
report_metric -format html -file reports/synthesis.html
report_hierarchy > outputs/synthesis.hier
puts "Final Runtime & Memory."
time_info FINAL
puts "============================"
puts "Synthesis Finished ........."
puts "============================"

file copy -force [get_db / .stdout_log] .

quit

