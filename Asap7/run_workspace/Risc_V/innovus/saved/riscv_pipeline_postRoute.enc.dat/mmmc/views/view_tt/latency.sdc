set_clock_latency -source -early -min  100 [get_clocks {CLK}]
set_clock_latency -source -early -max  100 [get_clocks {CLK}]
set_clock_latency -source -late -min  150 [get_clocks {CLK}]
set_clock_latency -source -late -max  150 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  -3.67979 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  -4.28518 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  46.3202 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  45.7148 [get_ports {clk}] -clock CLK 
