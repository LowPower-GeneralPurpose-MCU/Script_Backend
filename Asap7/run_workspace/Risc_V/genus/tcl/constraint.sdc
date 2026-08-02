# =============================================================================
# Functional timing constraints for riscv_pipeline
# Numeric values follow the ASAP7 standard-cell Liberty units: ps and fF.
# This file is intentionally valid in both Genus and Innovus.
# =============================================================================

set CLK_PORT   clk
set RESET_PORT reset_n
set CLK_NAME   CLK

# 1000 ps = 1 ns = 1 GHz.  Change only CLK_PERIOD when exploring frequency.
set CLK_PERIOD 1000.0
set CLK_HALF   [expr {$CLK_PERIOD / 2.0}]

set IN_DELAY_MAX  [expr {0.25 * $CLK_PERIOD}]
set IN_DELAY_MIN  [expr {0.10 * $CLK_PERIOD}]
set OUT_DELAY_MAX [expr {0.30 * $CLK_PERIOD}]
set OUT_DELAY_MIN [expr {0.15 * $CLK_PERIOD}]

set CLOCK_PORT [get_ports $CLK_PORT]
set RESET_PORT_OBJ [get_ports $RESET_PORT]
set NON_DATA_INPUTS [get_ports [list $CLK_PORT $RESET_PORT]]
set DATA_INPUTS [remove_from_collection [all_inputs] $NON_DATA_INPUTS]

create_clock -name $CLK_NAME \
    -period $CLK_PERIOD \
    -waveform [list 0.0 $CLK_HALF] \
    $CLOCK_PORT

# Pre-CTS source assumptions.  The clock becomes propagated only after CTS in
# innovus_PnR.tcl.
set_clock_transition -min 10.0 [get_clocks $CLK_NAME]
set_clock_transition -max 40.0 [get_clocks $CLK_NAME]
set_clock_uncertainty 50.0 [get_clocks $CLK_NAME]
set_clock_latency -source -early 100.0 [get_clocks $CLK_NAME]
set_clock_latency -source -late  150.0 [get_clocks $CLK_NAME]

# All non-reset external interfaces are assumed synchronous to CLK.  If any
# interrupt/debug/cache response is asynchronous in the real SoC wrapper, add
# synchronizers in RTL and constrain the wrapper, not this core, accordingly.
set_input_transition -min 10.0 $DATA_INPUTS
set_input_transition -max 40.0 $DATA_INPUTS
set_input_delay -clock $CLK_NAME -max $IN_DELAY_MAX $DATA_INPUTS
set_input_delay -clock $CLK_NAME -min $IN_DELAY_MIN $DATA_INPUTS

set_output_delay -clock $CLK_NAME -max $OUT_DELAY_MAX [all_outputs]
set_output_delay -clock $CLK_NAME -min $OUT_DELAY_MIN [all_outputs]

# Capacitance unit is fF for the ASAP7 standard-cell Liberty set.
set_load 10.0 -pin_load [all_outputs]

# reset_n is an asynchronous active-low reset.  It is excluded from ordinary
# synchronous input timing; recovery/removal should be checked at chip-level
# with a reset synchronizer and a realistic reset-release model.
set_false_path -from $RESET_PORT_OBJ
set_ideal_network $RESET_PORT_OBJ

set_max_fanout 20 [current_design]
set_max_transition 500.0 [current_design]

# Prevent accidental unconstrained clock creation failures from going unnoticed.
if {[sizeof_collection [get_clocks $CLK_NAME]] == 0} {
    error "Clock $CLK_NAME was not created on port $CLK_PORT"
}
