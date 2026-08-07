set_clock_latency -source -early -min  100 [get_clocks {CLK}]
set_clock_latency -source -early -max  100 [get_clocks {CLK}]
set_clock_latency -source -late -min  150 [get_clocks {CLK}]
set_clock_latency -source -late -max  150 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  99.7696 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  99.7615 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  149.77 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  149.761 [get_ports {clk}] -clock CLK 
