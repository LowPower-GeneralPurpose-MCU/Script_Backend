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
set_clock_latency -source -early -min -rise  -0.0349294 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -min -fall  -0.0390404 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -min -rise  0.0150706 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -min -fall  0.0109596 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -min -rise  -0.254398 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -early -min -fall  -0.266334 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -min -rise  -0.204398 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -min -fall  -0.216334 [get_ports {clk}] -clock CLK_SYS 
