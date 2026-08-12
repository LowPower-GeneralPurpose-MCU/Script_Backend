set_clock_latency -source -early -min  100 [get_clocks {CLK}]
set_clock_latency -source -early -max  100 [get_clocks {CLK}]
set_clock_latency -source -late -min  150 [get_clocks {CLK}]
set_clock_latency -source -late -max  150 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  4.06925 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  4.3688 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  54.0693 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  54.3688 [get_ports {clk}] -clock CLK 
