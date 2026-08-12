# =============================================================================
# Step 05: pre-CTS opt, CTS, and post-CTS opt.
#
# Paste after 04_place:
#   source ./tcl/steps/05_cts.tcl
# =============================================================================

riscv_step_banner "STEP 05: CTS"

create_route_type -name leaf_rule \
    -bottom_preferred_layer M2 -top_preferred_layer M3
create_route_type -name trunk_rule \
    -bottom_preferred_layer M4 -top_preferred_layer M5
create_route_type -name top_rule \
    -bottom_preferred_layer M6 -top_preferred_layer M7

set_ccopt_property -net_type leaf  route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top   route_type top_rule
set_ccopt_property routing_top_min_fanout 100
set_ccopt_property target_max_trans 0.300ns
set_ccopt_property buffer_cells $CTS_BUF_CELLS
set_ccopt_property inverter_cells $CTS_INV_CELLS
set_ccopt_property use_inverters auto

setOptMode -reclaimArea true -leakageToDynamicRatio 0.5 \
    -powerEffort high -fixFanoutLoad true

optDesign -prefix preCTS -preCTS
report_timing > ./reports/timing_preCTS.rpt

refinePlace
checkPlace ./verify_rpt/checkPlace_before_cts.rpt
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7

clock_opt_design -prefix postCTS

proc apply_post_cts_propagated_clocks {} {
    set active_constraint_modes [all_constraint_modes -active]

    if {[catch {
        set_interactive_constraint_modes $active_constraint_modes
        set_propagated_clock [all_clocks]
    } propagated_clock_setup_error]} {
        catch {set_interactive_constraint_modes {}}
        return -code error $propagated_clock_setup_error
    }

    set_interactive_constraint_modes {}
}

if {[catch {apply_post_cts_propagated_clocks} propagated_clock_error]} {
    puts stderr "Post-CTS propagated-clock setup failed: $propagated_clock_error"
    error $propagated_clock_error
}

setHierMode -optStage postCTS
optDesign -prefix postCTS -postCTS -setup -hold

report_timing > ./reports/timing_postCTS.rpt
report_area   > ./reports/area_postCTS.rpt
saveDesign ./saved/${TOP}_postCTS.enc

riscv_step_banner "STEP 05 DONE: saved/${TOP}_postCTS.enc"

