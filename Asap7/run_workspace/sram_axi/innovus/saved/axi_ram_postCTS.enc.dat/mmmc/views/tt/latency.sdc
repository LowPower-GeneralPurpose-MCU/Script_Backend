set_clock_latency -source -early -min  0.1 [get_clocks {CLK}]
set_clock_latency -source -early -max  0.1 [get_clocks {CLK}]
set_clock_latency -source -late -min  0.15 [get_clocks {CLK}]
set_clock_latency -source -late -max  0.15 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  -0.0434354 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  -0.0502229 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  0.00656457 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  -0.000222906 [get_ports {clk}] -clock CLK 
