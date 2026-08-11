############################################################
## Genus synthesis: RV32IM pipeline
## Based on the user's working SRAM Genus flow
## Hierarchy-aware single-corner TT flow
## Standard cells: ASAP7 RVT + LVT
############################################################

# ------------------------------------------------------------------------
# 1. GLOBAL VARIABLES
# ------------------------------------------------------------------------

if {[info exists ::env(ASAP7_HOME)]} {
    set ASAP7 [file normalize $::env(ASAP7_HOME)]
} else {
    set ASAP7 "/home/user1/Desktop/asap7"
}

set LIB      "${ASAP7}/asap7sc7p5t_28/LIB/CCS"
set TOP      "riscv_pipeline"
set SDC_FILE "./tcl/constraint.sdc"

proc env_or_default {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }

    return $default_value
}

proc env_flag_is_true {name} {
    if {![info exists ::env($name)]} {
        return 0
    }

    set value [string tolower $::env($name)]
    return [expr {$value eq "1" || $value eq "true" || $value eq "yes" || $value eq "on"}]
}

proc try_set_root_attr {name value} {
    if {[catch {set_db / .$name $value} set_error]} {
        puts "WARNING: Unable to set $name to '$value': $set_error"
        return 0
    }

    return 1
}

proc try_reset_root_attr {name} {
    if {[catch {reset_db $name} reset_error]} {
        puts "WARNING: Unable to reset $name: $reset_error"
        return 0
    }

    return 1
}

proc print_root_attr {name} {
    if {[catch {get_db / .$name} attr_value]} {
        puts "Genus root attribute $name: unavailable ($attr_value)"
    } else {
        puts "Genus root attribute $name = '$attr_value'"
    }
}

source ./tcl/rtl_filelist.tcl

foreach dir {outputs reports logs} {
    if {![file exists $dir]} {
        file mkdir $dir
    }
}

# Never mix a failed run with reports/netlists from an older successful run.
foreach pattern {./outputs/* ./reports/* ./logs/*} {
    foreach stale_file [glob -nocomplain $pattern] {
        file delete -force $stale_file
    }
}

# ------------------------------------------------------------------------
# 2. DATABASE SETTINGS
# ------------------------------------------------------------------------

set_db / .init_lib_search_path [list $LIB]
set_db / .script_search_path   {./tcl}
set_db / .init_hdl_search_path {./rtl}

# Keep the default run in a single Genus process. Any positive
# max_cpus_per_server value can launch a super-thread server in Genus 23.14.
try_set_root_attr auto_super_thread false
try_set_root_attr st_launch_wait_time [env_or_default GENUS_ST_LAUNCH_WAIT 1]

if {[env_flag_is_true GENUS_ENABLE_SUPER_THREAD]} {
    set CORES [env_or_default GENUS_CPUS 4]
    if {![string is integer -strict $CORES] || $CORES < 1} {
        error "GENUS_CPUS must be a positive integer, got '$CORES'"
    }

    set ST_SERVERS [env_or_default GENUS_SUPER_THREAD_SERVERS localhost]
    set ST_RSH [env_or_default GENUS_SUPER_THREAD_RSH ""]

    try_set_root_attr super_thread_servers $ST_SERVERS
    if {$ST_RSH ne ""} {
        try_set_root_attr super_thread_rsh_command $ST_RSH
    }
    try_set_root_attr max_cpus_per_server $CORES

    puts "Genus CPU configuration: super-thread enabled, servers=$ST_SERVERS, cpus/server=$CORES"
    if {[catch {test_super_thread_servers} st_error]} {
        error "Super-thread server test failed before synthesis: $st_error"
    }
} else {
    try_reset_root_attr super_thread_servers
    try_set_root_attr max_cpus_per_server 0
    puts "Genus CPU configuration: single-process debug mode; do not start Genus with -cpu unless GENUS_ENABLE_SUPER_THREAD=1 is also set."
}

foreach st_attr {auto_super_thread super_thread_servers max_cpus_per_server st_launch_wait_time} {
    print_root_attr $st_attr
}

set_db / .hdl_unconnected_value 0
set_db / .hdl_track_filename_row_col true
set_db / .auto_ungroup both
set_db / .lp_insert_clock_gating false

# ------------------------------------------------------------------------
# 3. LIBRARIES
# ------------------------------------------------------------------------

set STD_LIBS [list \
    "${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib" \
    "${LIB}/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib" \
    "${LIB}/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib" \
    "${LIB}/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib"]

foreach lib $STD_LIBS {
    if {![file exists $lib]} {
        error "Missing Liberty file: [file normalize $lib]"
    }
}

if {![file exists $SDC_FILE]} {
    error "Missing SDC file: [file normalize $SDC_FILE]"
}

set_db / .library $STD_LIBS

# ------------------------------------------------------------------------
# 4. MMMC CORNER: TT, 0.7 V, 25 C
# ------------------------------------------------------------------------

create_library_set \
    -name libset \
    -timing $STD_LIBS

create_rc_corner \
    -name rccorner \
    -pre_route_res 1.0 \
    -post_route_res 1.0 \
    -pre_route_cap 1.0 \
    -post_route_cap 1.0 \
    -post_route_cross_cap 1.0 \
    -pre_route_clock_res 0.0 \
    -pre_route_clock_cap 0.0 \
    -temperature 25

create_opcond \
    -name opcond \
    -process 1 \
    -voltage 0.7 \
    -temperature 25

create_timing_condition \
    -name timecond \
    -library_sets libset \
    -opcond opcond

create_delay_corner \
    -name corner \
    -timing_condition timecond \
    -rc_corner rccorner

create_constraint_mode \
    -name mode_normal \
    -sdc_files $SDC_FILE

create_analysis_view \
    -name tt \
    -constraint_mode mode_normal \
    -delay_corner corner

set_analysis_view \
    -setup {tt} \
    -hold  {tt}

# ------------------------------------------------------------------------
# 5. READ AND ELABORATE RTL
# ------------------------------------------------------------------------

foreach rtl $RTL_FILES {
    if {![file exists $rtl]} {
        error "Missing RTL file: [file normalize $rtl]"
    }

    puts "Reading RTL: $rtl"
    read_hdl $rtl
}

elaborate $TOP
uniquify $TOP
check_design -unresolved > reports/check_design_unresolved.rpt

init_design
set_interactive_constraint_modes mode_normal

# ------------------------------------------------------------------------
# 6. SELECT PHYSICAL HIERARCHY
# ------------------------------------------------------------------------
# Keep only meaningful RISC-V blocks for the hierarchy-floorplan flow.

set HIER_MODULE_PATTERNS [list \
    "*execute*" \
    "register_file" \
    "csr_register_file" \
    "branch_prediction_unit"]

set PRESERVED_HIER_MODULES {}

foreach module_pattern $HIER_MODULE_PATTERNS {
    set matched_modules [get_db modules $module_pattern]

    if {[llength $matched_modules] == 0} {
        puts "WARNING: no hierarchy module matched '$module_pattern'"
        continue
    }

    foreach module_obj $matched_modules {
        set_db $module_obj .ungroup_ok false
        lappend PRESERVED_HIER_MODULES $module_obj
        puts "Preserve physical hierarchy: [get_db $module_obj .name]"
    }
}

if {[llength $PRESERVED_HIER_MODULES] == 0} {
    puts "WARNING: no RISC-V hierarchy module was protected."
    puts "         Inspect reports/area_hierarchy_elaborated.rpt."
}

set CLK_PORT_OBJ [get_ports clk]

if {[sizeof_collection $CLK_PORT_OBJ] == 0} {
    error "Top design '$TOP' does not contain port 'clk'."
}

report_hierarchy      > reports/hierarchy_elaborated.rpt
report_area -depth 3  > reports/area_hierarchy_elaborated.rpt
report_metric -format html -file reports/elaborated_metric.html

# ------------------------------------------------------------------------
# 7. VERIFY THE SDC ATTACHED TO THE CONSTRAINT MODE
# ------------------------------------------------------------------------

puts "===================================================="
puts "VERIFYING MMMC SDC"
puts " - File: [file normalize $SDC_FILE]"
puts "===================================================="

# The SDC is already attached by create_constraint_mode.  Do not read it a
# second time because that would duplicate clocks and timing constraints.
if {[info exists ::dc::sdc_failed_commands]} {
    set FAILED_SDC $::dc::sdc_failed_commands

    if {[llength $FAILED_SDC] > 0} {
        set failed_fd [open reports/failed_sdc_commands.rpt w]

        foreach failed_cmd $FAILED_SDC {
            puts $failed_fd $failed_cmd
        }

        close $failed_fd
        error "SDC contains failed commands. See reports/failed_sdc_commands.rpt"
    }
}

set DEFINED_CLOCKS [get_clocks CLK]

if {[sizeof_collection $DEFINED_CLOCKS] == 0} {
    error "Clock 'CLK' was not created by $SDC_FILE"
}

puts "===================================================="
puts "SDC CHECK PASSED"
puts " - Clock port   : $CLK_PORT_OBJ"
puts " - Clock object : $DEFINED_CLOCKS"
puts "===================================================="

check_timing_intent -verbose \
    > reports/timing_intent_pre_syn.rpt

if {[catch {
    report_timing -lint > reports/timing_lint_pre_syn.rpt
} timing_lint_error]} {
    puts "WARNING: report_timing -lint failed: $timing_lint_error"
}

# ------------------------------------------------------------------------
# 8. COST GROUPS
# ------------------------------------------------------------------------

set ALL_SEQS [all::all_seqs]
set ASYNC_INPUT_NAMES [list meip_i msip_i mtip_i dbg_halt_req dbg_resume_req]
set NON_DATA_INPUTS [get_ports [concat [list clk reset_n] $ASYNC_INPUT_NAMES]]
set DATA_INPUTS [remove_from_collection [all_inputs] $NON_DATA_INPUTS]

if {[sizeof_collection $ALL_SEQS] > 0} {
    define_cost_group -name I2C -design $TOP
    define_cost_group -name C2O -design $TOP
    define_cost_group -name C2C -design $TOP
    define_cost_group -name I2O -design $TOP

    # Register-to-register paths
    path_group \
        -from  $ALL_SEQS \
        -to    $ALL_SEQS \
        -view  tt \
        -group C2C \
        -name  C2C

    # Register-to-output paths
    path_group \
        -from  $ALL_SEQS \
        -to    [all_outputs] \
        -view  tt \
        -group C2O \
        -name  C2O

    # Input-to-register and input-to-output paths
    if {[sizeof_collection $DATA_INPUTS] > 0} {
        path_group \
            -from  $DATA_INPUTS \
            -to    $ALL_SEQS \
            -view  tt \
            -group I2C \
            -name  I2C

        path_group \
            -from  $DATA_INPUTS \
            -to    [all_outputs] \
            -view  tt \
            -group I2O \
            -name  I2O
    }

    puts "===================================================="
    puts "COST GROUPS CREATED"
    puts " - C2C : register -> register"
    puts " - C2O : register -> output"
    puts " - I2C : input    -> register"
    puts " - I2O : input    -> output"
    puts " - View: tt"
    puts "===================================================="
} else {
    puts "WARNING: No sequential instances found; cost groups skipped."
}

# ------------------------------------------------------------------------
# 9. SYNTHESIS
# ------------------------------------------------------------------------

# Conservative default for debugging convergence. Re-enable datapath transforms
# only after the script completes cleanly in the local run mode.
if {[env_flag_is_true GENUS_ENABLE_DATAPATH_OPT]} {
    puts "Genus datapath mode: optimized"
} else {
    puts "Genus datapath mode: debug-safe; datapath sharing/speculation disabled"
    set_db / .dp_analytical_opt off
    set_db / .dp_sharing none
    set_db / .dp_speculation none
}

set SYN_EFFORT [env_or_default GENUS_SYN_EFFORT low]
puts "Genus synthesis effort: $SYN_EFFORT"

set_db / .syn_generic_effort $SYN_EFFORT
syn_generic
report_area -depth 3 > reports/area_after_generic_depth3.rpt

set_db / .syn_map_effort $SYN_EFFORT
syn_map
report_area -depth 3 > reports/area_after_map_depth3.rpt

set_db / .syn_opt_effort $SYN_EFFORT
syn_opt

# ------------------------------------------------------------------------
# 10. REPORTS
# ------------------------------------------------------------------------

report_area              > reports/area_syn.rpt
report_area -depth 3     > reports/area_hierarchy_syn.rpt
report_timing -max_paths 50 > reports/timing_syn.rpt

foreach cg [vfind / -cost_group *] {
    set cg_name [file tail $cg]

    report_timing \
        -cost_group [list $cg] \
        -max_paths 20 \
        > "reports/timing_${cg_name}_syn.rpt"
}

report_power      > reports/power_syn.rpt
report_gates      > reports/gates_syn.rpt
report_dp         > reports/datapath_syn.rpt
report_qor        > reports/qor_syn.rpt
report_hierarchy  > reports/hierarchy_syn.rpt

report_metric \
    -format html \
    -file reports/metric_syn.html

report sequential -deleted \
    > reports/deleted_sequential_syn.rpt

check_timing_intent -verbose \
    > reports/timing_intent_post_syn.rpt

if {[catch {
    report_timing -lint > reports/timing_lint_post_syn.rpt
} timing_lint_error]} {
    puts "WARNING: report_timing -lint failed: $timing_lint_error"
}

# ------------------------------------------------------------------------
# 11. OUTPUTS
# ------------------------------------------------------------------------

set MAPPED_NETLIST "./outputs/${TOP}_syn.v"
set MAPPED_SDC     "./outputs/${TOP}_syn.sdc"
set MAPPED_SPEF    "./outputs/${TOP}_syn.spef"

write_hdl > $MAPPED_NETLIST
write_sdc -view tt > $MAPPED_SDC

set SPEF_GENERATED 1

if {[catch {
    write_parasitics > $MAPPED_SPEF
} parasitic_error]} {
    set SPEF_GENERATED 0
    puts "WARNING: write_parasitics failed: $parasitic_error"
}

write_do_lec \
    -revised_design $MAPPED_NETLIST \
    -logfile ./logs/lec_genus.log \
    > ./outputs/genus_mapping_hints.do

report_messages -all > reports/messages_all.rpt

puts "===================================================="
puts "GENUS RV32IM HIERARCHY SYNTHESIS COMPLETED"
puts " - Std cells: RVT + LVT"
puts " - PVT      : TT, 0.7 V, 25 C"
puts " - Netlist  : $MAPPED_NETLIST"
puts " - SDC      : $MAPPED_SDC"

if {$SPEF_GENERATED} {
    puts " - SPEF     : $MAPPED_SPEF (estimated)"
} else {
    puts " - SPEF     : not generated"
}

puts " - Hierarchy: $PRESERVED_HIER_MODULES"
puts "===================================================="

