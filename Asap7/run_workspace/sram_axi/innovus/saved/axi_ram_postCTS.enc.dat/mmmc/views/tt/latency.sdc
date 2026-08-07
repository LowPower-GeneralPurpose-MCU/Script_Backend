set_clock_latency -source -early -min  100 [get_clocks {CLK}]
set_clock_latency -source -early -max  100 [get_clocks {CLK}]
set_clock_latency -source -late -min  150 [get_clocks {CLK}]
set_clock_latency -source -late -max  150 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  99.7572 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  99.7492 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  149.757 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  149.749 [get_ports {clk}] -clock CLK 
