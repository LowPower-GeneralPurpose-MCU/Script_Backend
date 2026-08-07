############################################################
## Static checks for Innovus SDC unit handling and CTS guards.
############################################################

proc read_file {path} {
    set fp [open $path r]
    set text [read $fp]
    close $fp
    return $text
}

proc require_contains {text pattern label} {
    if {[string first $pattern $text] < 0} {
        error "Missing $label: $pattern"
    }
}

proc require_not_contains {text pattern label} {
    if {[string first $pattern $text] >= 0} {
        error "Unexpected $label: $pattern"
    }
}

source ./tcl/prepare_innovus_sdc.tcl

set tmp_sdc ./reports/__tmp_innovus_unit_check.sdc
set tmp_groups ./reports/__tmp_innovus_groups_check.tcl
prepare_innovus_sdc ./outputs/axi_ram_syn.sdc $tmp_sdc $tmp_groups

set generated_sdc [read_file $tmp_sdc]
set generated_groups [read_file $tmp_groups]

require_contains $generated_sdc {create_clock -name "CLK" -period 1.0 -waveform {0.0 0.5}} "1ns clock"
require_contains $generated_sdc {set_clock_transition -max 0.04} "40ps clock transition in ns"
require_contains $generated_sdc {set_input_delay -clock [get_clocks CLK] -add_delay -max 0.25} "250ps input delay in ns"
require_contains $generated_sdc {set_load -pin_load 0.01} "10fF load in pF"
require_contains $generated_sdc {set_clock_uncertainty -setup 0.05} "50ps setup uncertainty in ns"
require_not_contains $generated_sdc {set_units} "unsupported set_units"
require_not_contains $generated_sdc {group_path} "mode-local group_path"
require_contains $generated_groups {group_path -name C2C} "global C2C path group"

file delete -force $tmp_sdc $tmp_groups

set innovus_master [read_file ./tcl/innovus.tcl]
set innovus_pnr [read_file ./tcl/innovus_pnr.tcl]
set view_definition [read_file ./tcl/viewDefinition.tcl]
set globals [read_file ./tcl/innovus.globals]

foreach flow [list $innovus_master $innovus_pnr] {
    require_contains $flow {prepare_innovus_sdc $SYN_SDC_FILE $INNOVUS_SDC_FILE $INNOVUS_GROUP_PATH_FILE} "generated Innovus SDC before init_design"
    require_contains $flow {source $INNOVUS_GROUP_PATH_FILE} "global group_path source after init_design"
    require_contains $flow {-place_global_reorder_scan false} "scan reorder disabled without scan DEF"
    require_contains $flow {assert_clean_check_place ./verify_rpt/checkPlace_after_place.rpt} "post-place checkPlace guard"
    require_contains $flow {assert_clean_check_place ./verify_rpt/checkPlace_before_cts.rpt} "pre-CTS checkPlace guard"
    require_contains $flow {-routeBottomRoutingLayer 1} "NanoRoute bottom layer"
    require_contains $flow {-routeTopRoutingLayer 9} "NanoRoute top layer"
    require_contains $flow {set_ccopt_property -net_type leaf  target_max_trans 40ps} "leaf CTS transition target"
    require_contains $flow {set_ccopt_property target_skew 50ps} "CTS skew target"
    require_contains $flow {BUFx24_ASAP7_75t_R} "strong RVT CTS buffer for SRAM clock sinks"
    require_contains $flow {-ewm_type moments} "moment EWM pre-route"
}

require_contains $view_definition {-sdc_files $INNOVUS_SDC_FILE} "MMMC uses normalized SDC"
require_contains $view_definition {setLibraryUnit -time 1ns -cap 1pf} "MMMC library units"
require_contains $globals {setLibraryUnit -time 1ns -cap 1pf} "global library units"

puts "PASS: Innovus CTS/static unit checks"
