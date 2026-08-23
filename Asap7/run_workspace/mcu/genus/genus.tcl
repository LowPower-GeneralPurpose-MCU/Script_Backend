############################################################
## Cadence Genus synthesis flow for MCU top_soc
## ASAP7 RVT + LVT, TT 0.7 V 25 C, 32 SRAM hard macros
############################################################

set GENUS_DIR [file dirname [file normalize [info script]]]
cd $GENUS_DIR

source ./preflight.tcl
source ./tcl/check_sram_macro.tcl

foreach dir {outputs reports logs} {
    file mkdir $dir
}
foreach pattern {./outputs/* ./reports/* ./logs/*} {
    foreach stale [glob -nocomplain $pattern] {
        file delete -force $stale
    }
}

set_db / .init_lib_search_path [list $STD_LIB_DIR [file dirname $SRAM_LIB]]
set_db / .script_search_path [list [file join $GENUS_DIR tcl]]
set_db / .init_hdl_search_path \
    [concat [list $RTL_ROOT] $RTL_INCLUDE_DIRS]

# Stable default for workstation and license-limited runs.
catch {set_db / .auto_super_thread false}
catch {reset_db super_thread_servers}
catch {set_db / .max_cpus_per_server 0}

set_db / .hdl_unconnected_value 0
set_db / .hdl_track_filename_row_col true
set_db / .auto_ungroup both
set_db / .lp_insert_clock_gating false
set_db / .library $ALL_TIMING_LIBS

create_library_set -name libset_tt -timing $ALL_TIMING_LIBS
create_rc_corner \
    -name rc_typ \
    -pre_route_res 1.0 \
    -post_route_res 1.0 \
    -pre_route_cap 1.0 \
    -post_route_cap 1.0 \
    -post_route_cross_cap 1.0 \
    -pre_route_clock_res 0.0 \
    -pre_route_clock_cap 0.0 \
    -temperature 25
create_opcond \
    -name opcond_tt_0p7v_25c \
    -process 1.0 \
    -voltage 0.7 \
    -temperature 25
create_timing_condition \
    -name tc_tt \
    -library_sets libset_tt \
    -opcond opcond_tt_0p7v_25c
create_delay_corner \
    -name dc_tt \
    -timing_condition tc_tt \
    -rc_corner rc_typ
create_constraint_mode \
    -name mode_func \
    -sdc_files $SDC_FILE
create_analysis_view \
    -name view_tt \
    -constraint_mode mode_func \
    -delay_corner dc_tt
set_analysis_view -setup {view_tt} -hold {view_tt}

foreach rtl $RTL_FILES {
    puts "Reading RTL: [file normalize $rtl]"
    read_hdl $rtl
}

elaborate $TOP
uniquify $TOP
check_design -unresolved > ./reports/check_design_unresolved.rpt

# Keep the controller/wrapper boundary and the hard-macro array visible for
# physical planning and for the post-map 32-instance invariant.
foreach module_pattern {
    axi_ram
    asap7_sram_128k_1rw
    riscv_pipeline
    instruction_cache
    data_cache
    axi_interconnect
} {
    foreach module_obj [get_db modules $module_pattern] {
        set_db $module_obj .ungroup_ok false
    }
}

init_design
set_interactive_constraint_modes mode_func

if {[sizeof_collection [get_clocks *]] != 17} {
    error "Expected 17 clocks (9 primary + 8 generated); inspect the SDC"
}

if {[info exists ::dc::sdc_failed_commands] &&
    [llength $::dc::sdc_failed_commands] > 0} {
    set fp [open ./reports/failed_sdc_commands.rpt w]
    foreach failed $::dc::sdc_failed_commands {
        puts $fp $failed
    }
    close $fp
    error "SDC contains failed commands; see reports/failed_sdc_commands.rpt"
}

check_sram_library_cell $SRAM_MASTER

if {![catch {
    set sram_outputs \
        [get_lib_pins "*/$SRAM_MASTER/*" -filter "@direction == out"]
    if {[sizeof_collection $sram_outputs] > 0} {
        set_max_fanout 1 $sram_outputs
    }
} sram_pin_error]} {
    puts "Applied the SRAM output fanout guard"
} else {
    puts "WARNING: SRAM output fanout guard was not applied: $sram_pin_error"
}

report_hierarchy > ./reports/hierarchy_elaborated.rpt
report_area -depth 4 > ./reports/area_hierarchy_elaborated.rpt
check_timing_intent -verbose > ./reports/timing_intent_pre_syn.rpt
catch {report_timing -lint > ./reports/timing_lint_pre_syn.rpt}

set_db / .syn_generic_effort high
syn_generic
set_db / .syn_map_effort high
syn_map
set_db / .syn_opt_effort high
syn_opt

report_area > ./reports/area_syn.rpt
report_area -depth 5 > ./reports/area_hierarchy_syn.rpt
report_timing -max_paths 100 > ./reports/timing_syn.rpt
report_power > ./reports/power_syn.rpt
report_gates > ./reports/gates_syn.rpt
report_qor > ./reports/qor_syn.rpt
report_hierarchy > ./reports/hierarchy_syn.rpt
check_timing_intent -verbose > ./reports/timing_intent_post_syn.rpt
catch {report_timing -lint > ./reports/timing_lint_post_syn.rpt}
report_metric -format html -file ./reports/metric_syn.html

set MAPPED_NETLIST [file join $GENUS_DIR outputs [format "%s_syn.v" $TOP]]
set MAPPED_SDC     [file join $GENUS_DIR outputs [format "%s_syn.sdc" $TOP]]

write_hdl > $MAPPED_NETLIST
write_sdc -view view_tt > $MAPPED_SDC
write_do_lec \
    -revised_design $MAPPED_NETLIST \
    -logfile ./logs/lec_genus.log \
    > ./outputs/genus_mapping_hints.do

check_sram_mapped_netlist \
    $MAPPED_NETLIST $SRAM_MASTER $SRAM_EXPECTED_COUNT

report_messages -all > ./reports/messages_all.rpt

puts "============================================================"
puts "GENUS MCU SYNTHESIS COMPLETED"
puts " - Netlist : [file normalize $MAPPED_NETLIST]"
puts " - SDC     : [file normalize $MAPPED_SDC]"
puts " - SRAM    : $SRAM_EXPECTED_COUNT x $SRAM_MASTER"
puts "============================================================"
