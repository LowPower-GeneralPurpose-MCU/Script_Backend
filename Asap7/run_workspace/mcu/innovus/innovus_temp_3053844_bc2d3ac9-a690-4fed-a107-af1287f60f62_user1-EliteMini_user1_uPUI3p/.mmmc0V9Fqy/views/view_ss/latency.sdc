set_clock_latency -source -early -min  0.1 [get_clocks {CLK_SYS}]
set_clock_latency -source -early -max  0.1 [get_clocks {CLK_SYS}]
set_clock_latency -source -late -min  0.15 [get_clocks {CLK_SYS}]
set_clock_latency -source -late -max  0.15 [get_clocks {CLK_SYS}]
set_clock_latency -source -early -min  0.1 [get_clocks {CLK_SDRAM_OUT}]
set_clock_latency -source -early -max  0.1 [get_clocks {CLK_SDRAM_OUT}]
set_clock_latency -source -late -min  0.15 [get_clocks {CLK_SDRAM_OUT}]
set_clock_latency -source -late -max  0.15 [get_clocks {CLK_SDRAM_OUT}]
set_clock_latency -source -early -min  0.1 [get_clocks {CLK_TCK}]
set_clock_latency -source -early -max  0.1 [get_clocks {CLK_TCK}]
set_clock_latency -source -late -min  0.15 [get_clocks {CLK_TCK}]
set_clock_latency -source -late -max  0.15 [get_clocks {CLK_TCK}]
set_clock_latency -source -early -max -rise  -0.129441 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -max -fall  -0.140273 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -max -rise  -0.0794412 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -max -fall  -0.090273 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -max -rise  -0.550256 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -early -max -fall  -0.613011 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -max -rise  -0.500256 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -max -fall  -0.563011 [get_ports {clk}] -clock CLK_SYS 
