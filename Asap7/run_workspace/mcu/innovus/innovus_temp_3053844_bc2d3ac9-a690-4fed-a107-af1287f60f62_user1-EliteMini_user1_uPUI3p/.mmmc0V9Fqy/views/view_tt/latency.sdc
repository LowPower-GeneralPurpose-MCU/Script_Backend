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
set_clock_latency -source -early -min -rise  -0.0674669 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -min -fall  -0.0732855 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -max -rise  -0.0691338 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -max -fall  -0.0742938 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -min -rise  -0.0174669 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -min -fall  -0.0232855 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -max -rise  -0.0191338 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -late -max -fall  -0.0242938 [get_ports {tck}] -clock CLK_TCK 
set_clock_latency -source -early -min -rise  -0.35828 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -early -min -fall  -0.385436 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -early -max -rise  -0.360826 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -early -max -fall  -0.38744 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -min -rise  -0.30828 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -min -fall  -0.335436 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -max -rise  -0.310826 [get_ports {clk}] -clock CLK_SYS 
set_clock_latency -source -late -max -fall  -0.33744 [get_ports {clk}] -clock CLK_SYS 
