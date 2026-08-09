set_clock_latency -source -early -min  0.1 [get_clocks {CLK}]
set_clock_latency -source -early -max  0.1 [get_clocks {CLK}]
set_clock_latency -source -late -min  0.15 [get_clocks {CLK}]
set_clock_latency -source -late -max  0.15 [get_clocks {CLK}]
