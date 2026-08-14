set_clock_latency -source -early -min  0.1 [get_clocks {CLK}]
set_clock_latency -source -early -max  0.1 [get_clocks {CLK}]
set_clock_latency -source -late -min  0.15 [get_clocks {CLK}]
set_clock_latency -source -late -max  0.15 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  -0.079864 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  -0.0841463 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  -0.029864 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  -0.0341463 [get_ports {clk}] -clock CLK 
