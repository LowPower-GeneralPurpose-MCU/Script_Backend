# ------------------------------------------------------------------------
# 1. UNIT DEFINITIONS AND GLOBAL VARIABLES
# ------------------------------------------------------------------------
set_units -time 1.0ps -capacitance 1.0fF

set CLK_PORT "iclk"
set CLK_NAME "CLK"
set CLK_PERIOD 1000.0    ;# Clock period 1ns = 1000ps

# Define Delay as a percentage of clock period
# Input: Max is used for Setup (slowest), Min is used for Hold (fastest)
set IN_DELAY_MAX  [expr 0.25 * $CLK_PERIOD] ;# Max delay 250ps
set IN_DELAY_MIN  [expr 0.10 * $CLK_PERIOD] ;# Min delay 100ps

# Output delays: Similar to Input
set OUT_DELAY_MAX [expr 0.30 * $CLK_PERIOD] ;# Max delay 300ps
set OUT_DELAY_MIN [expr 0.15 * $CLK_PERIOD] ;# Min delay 150ps

# Create a variable grouping all inputs (excluding Clock) for cleaner code
set NON_CLK_INPUTS [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]


# ------------------------------------------------------------------------
# 2. CLOCK CONSTRAINTS
# ------------------------------------------------------------------------
create_clock -name $CLK_NAME -period $CLK_PERIOD -waveform {0 500} [get_ports $CLK_PORT]

# Transition: Clock rise/fall time (Realistic bounds)
set_clock_transition -min 10 [all_clocks]
set_clock_transition -max 40 [all_clocks]

# Uncertainty: Margin for jitter. Should generally be 5% - 10% of clock period
set_clock_uncertainty 50 [all_clocks]

# Latency: Delay from the clock source to the clock pin inside the chip. 
# Kept a skew margin of 50ps to simulate a slight clock mismatch.
set_clock_latency -source -early 100 [all_clocks]
set_clock_latency -source -late  150 [all_clocks]


# ------------------------------------------------------------------------
# 3. INPUT CONSTRAINTS
# ------------------------------------------------------------------------
# Input slew: Incoming signals are never perfectly square
set_input_transition -min 10 $NON_CLK_INPUTS
set_input_transition -max 40 $NON_CLK_INPUTS

# Input Delay: Separate min/max for accurate Setup and Hold analysis (OCV)
set_input_delay -clock $CLK_NAME -max $IN_DELAY_MAX $NON_CLK_INPUTS
set_input_delay -clock $CLK_NAME -min $IN_DELAY_MIN $NON_CLK_INPUTS


# ------------------------------------------------------------------------
# 4. OUTPUT CONSTRAINTS
# ------------------------------------------------------------------------
# Output Delay: Time required for external circuitry to process the chip's signals
set_output_delay -clock $CLK_NAME -max $OUT_DELAY_MAX [all_outputs]
set_output_delay -clock $CLK_NAME -min $OUT_DELAY_MIN [all_outputs]

# Output load: Force output ports to drive a 10fF external load
set_load 10.0 -pin_load [all_outputs]


# ------------------------------------------------------------------------
# 5. DESIGN RULE CONSTRAINTS (DRC)
# ------------------------------------------------------------------------
# Prevent a single logic gate from driving too many branches (avoid signal degradation)
set_max_fanout 20 [current_design]

# Prevent signal edges from transitioning too slowly (avoid timing and power violations)
set_max_transition 500 [current_design]