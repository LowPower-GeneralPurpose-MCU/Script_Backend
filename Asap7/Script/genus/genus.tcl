# Global variables
set ASAP7 "../tkvm/asap7"
set LIB "${ASAP7}/asap7sc7p5t_28/LIB/CCS"
set TOP Mul32
set SYNFILE "Mul32.v"

if {![file exists ./outputs]} { file mkdir outputs }
if {![file exists ./reports]} { file mkdir reports }

set_db / .init_lib_search_path ${LIB}
set_db / .script_search_path {./tcl}
set_db / .init_hdl_search_path {./rtl}

if {![catch {open "/proc/cpuinfo"} f]} {
    set CORES [regexp -all -line {^processor\s} [read $f]]; close $f
}
set_db / .max_cpus_per_server ${CORES}

#Default undriven/unconnected setting is 'none'
#               available options: 0 | 1 | x | none
set_db / .hdl_unconnected_value 0
set_db / .hdl_track_filename_row_col true
set_db / .auto_ungroup none

#set_db / .wireload_mode <value>
#set_db / .information_level 7

# Library setup
set_db / .library { asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib asap7sc7p5t_AO_RVT_TT_ccs_211120.lib asap7sc7p5t_OA_RVT_TT_ccs_211120.lib asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib asap7sc7p5t_AO_LVT_TT_ccs_211120.lib asap7sc7p5t_OA_LVT_TT_ccs_211120.lib asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib }

create_library_set -name libset -timing { asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib asap7sc7p5t_AO_RVT_TT_ccs_211120.lib asap7sc7p5t_OA_RVT_TT_ccs_211120.lib asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib asap7sc7p5t_AO_LVT_TT_ccs_211120.lib asap7sc7p5t_OA_LVT_TT_ccs_211120.lib asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib }

# Read hdl
read_hdl Mul32.v
elaborate Mul32
check_design -unresolved


# SDC and operating conditions
create_rc_corner -name rccorner -pre_route_res 1 -post_route_res 1 \
-pre_route_cap 1 -post_route_cap 1 -post_route_cross_cap 1 \
-pre_route_clock_res 0 -pre_route_clock_cap 0 -temperature 25

create_opcond -name opcond -process 1 -voltage 0.7 -temperature 25
create_timing_condition -name timecond -library_sets libset -opcond opcond
create_delay_corner -name corner -timing_condition timecond -rc_corner rccorner

create_constraint_mode -name mode_normal -sdc_files ./tcl/constraint.sdc

create_analysis_view -name tt -constraint_mode mode_normal -delay_corner corner
set_analysis_view -setup {tt} -hold {tt}

init_design

# Synthesis
syn_generic
syn_map
# ungroup -all
syn_opt

# Reports
report_area > reports/area_syn.rpt
report_timing -max_paths 50 > reports/timing_syn.rpt
report_power > reports/power_syn.rpt
report_gates > reports/gates_syn.rpt
report_dp > reports/datapath_syn.rpt
report_qor > reports/qor_syn.rpt
report_hierarchy > reports/hier_syn.hier
report_metric -format html -file reports/metric_syn.html

# Outputs
write_hdl > outputs/Mul32_syn.v
write_sdc -view tt > outputs/Mul32_syn.sdc
write_parasitics > outputs/Mul32_syn.spef
write_do_lec -revised_design ./outputs/Mul32_syn.v -logfile lec_genus.log > genus_mapping_hints.do
