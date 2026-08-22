############################################################
## AXI RAM timing constraints
## Unit: ps / fF
############################################################

puts "INFO: BEGIN constraint.sdc"

# ------------------------------------------------------------------------
# 1. UNITS AND VARIABLES
# ------------------------------------------------------------------------

set_units \
    -time 1.0ps \
    -capacitance 1.0fF

set CLK_PORT   "clk"
set RESET_PORT "rst_n"
set CLK_NAME   "CLK"

set CLK_PERIOD 1000.0
set CLK_HALF   [expr {$CLK_PERIOD / 2.0}]

set IN_DELAY_MAX  [expr {0.25 * $CLK_PERIOD}]
set IN_DELAY_MIN  [expr {0.10 * $CLK_PERIOD}]
set OUT_DELAY_MAX [expr {0.30 * $CLK_PERIOD}]
set OUT_DELAY_MIN [expr {0.15 * $CLK_PERIOD}]

set RESET_DELAY_MAX [expr {0.10 * $CLK_PERIOD}]
set RESET_DELAY_MIN 0.0
# ------------------------------------------------------------------------
# 2. CHECK TOP PORTS
# ------------------------------------------------------------------------

set CLK_PORT_OBJ   [get_ports $CLK_PORT]
set RESET_PORT_OBJ [get_ports $RESET_PORT]

if {[llength $CLK_PORT_OBJ] == 0} {
    error "SDC: Clock port '$CLK_PORT' was not found."
}

if {[llength $RESET_PORT_OBJ] == 0} {
    error "SDC: Reset port '$RESET_PORT' was not found."
}

set NON_DATA_INPUTS \
    [get_ports [list $CLK_PORT $RESET_PORT]]

set AXI_INPUTS \
    [remove_from_collection [all_inputs] $NON_DATA_INPUTS]

set AXI_OUTPUTS [all_outputs]

# ------------------------------------------------------------------------
# 3. CLOCK
# ------------------------------------------------------------------------

create_clock \
    -name $CLK_NAME \
    -period $CLK_PERIOD \
    -waveform [list 0 $CLK_HALF] \
    $CLK_PORT_OBJ

set CLK_OBJ [get_clocks $CLK_NAME]

if {[llength $CLK_OBJ] == 0} {
    error "SDC: Clock '$CLK_NAME' was not created."
}

puts "INFO: Clock $CLK_NAME created on $CLK_PORT"

set_clock_transition -min 10 $CLK_OBJ
set_clock_transition -max 40 $CLK_OBJ

set_clock_uncertainty 50 $CLK_OBJ

set_clock_latency \
    -source \
    -early 100 \
    $CLK_OBJ

set_clock_latency \
    -source \
    -late 150 \
    $CLK_OBJ

# ------------------------------------------------------------------------
# 4. INPUTS
# ------------------------------------------------------------------------

if {[llength $AXI_INPUTS] > 0} {
    set_input_transition -min 10 $AXI_INPUTS
    set_input_transition -max 40 $AXI_INPUTS

    set_input_delay \
        -clock $CLK_OBJ \
        -max $IN_DELAY_MAX \
        $AXI_INPUTS

    set_input_delay \
        -clock $CLK_OBJ \
        -min $IN_DELAY_MIN \
        $AXI_INPUTS
}

# Asynchronous reset is excluded from normal data timing.
set_input_transition -min 10 $RESET_PORT_OBJ
set_input_transition -max 40 $RESET_PORT_OBJ

set_input_delay \
    -clock $CLK_OBJ \
    -max $RESET_DELAY_MAX \
    $RESET_PORT_OBJ
    
set_input_delay \
    -clock $CLK_OBJ \
    -min $RESET_DELAY_MIN \
    $RESET_PORT_OBJ

# ------------------------------------------------------------------------
# 5. OUTPUTS
# ------------------------------------------------------------------------

if {[llength $AXI_OUTPUTS] > 0} {
    set_output_delay \
        -clock $CLK_OBJ \
        -max $OUT_DELAY_MAX \
        $AXI_OUTPUTS

    set_output_delay \
        -clock $CLK_OBJ \
        -min $OUT_DELAY_MIN \
        $AXI_OUTPUTS

    set_load \
        10.0 \
        -pin_load \
        $AXI_OUTPUTS
}

# ------------------------------------------------------------------------
# 6. DESIGN RULES
# ------------------------------------------------------------------------

set_max_fanout 20 [current_design]
# The SRAM input pins have a 320 ps Liberty limit.  Keep 20 ps of margin so
# synthesis and physical optimization do not wait for routed RC to violate it.
set_max_transition 300 [current_design]

puts "INFO: END constraint.sdc"

