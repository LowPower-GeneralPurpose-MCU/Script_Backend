set_clock_latency -source -early -min  0.1 [get_clocks {CLK}]
set_clock_latency -source -early -max  0.1 [get_clocks {CLK}]
set_clock_latency -source -late -min  0.15 [get_clocks {CLK}]
set_clock_latency -source -late -max  0.15 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  -0.0709189 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  -0.078772 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  -0.0209188 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  -0.028772 [get_ports {clk}] -clock CLK 
