set_clock_latency -source -early -min  100 [get_clocks {CLK}]
set_clock_latency -source -early -max  100 [get_clocks {CLK}]
set_clock_latency -source -late -min  150 [get_clocks {CLK}]
set_clock_latency -source -late -max  150 [get_clocks {CLK}]
set_clock_latency -source -early -max -rise  3.39995 [get_ports {clk}] -clock CLK 
set_clock_latency -source -early -max -fall  3.65466 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -rise  53.3999 [get_ports {clk}] -clock CLK 
set_clock_latency -source -late -max -fall  53.6547 [get_ports {clk}] -clock CLK 
