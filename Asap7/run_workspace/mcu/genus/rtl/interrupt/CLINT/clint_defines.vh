// ============================================================
//  clint_defines.vh - shared synthesizable Verilog constants
// ============================================================
`ifndef CLINT_DEFINES_VH
`define CLINT_DEFINES_VH

`define CLINT_DATA_W    32
`define CLINT_STRB_W     4

`define CLINT_MSIP_BASE      26'h000000
`define CLINT_MTIMECMP_BASE  26'h004000
`define CLINT_MTIME_LO       26'h00BFF8
`define CLINT_MTIME_HI       26'h00BFFC
`define CLINT_ADDR_MAX       26'h00BFFF

`define AXI_OKAY    2'b00
`define AXI_EXOKAY  2'b01
`define AXI_SLVERR  2'b10
`define AXI_DECERR  2'b11

`define AXI_BURST_FIXED  2'b00
`define AXI_BURST_INCR   2'b01
`define AXI_BURST_WRAP   2'b10

`define CLINT_MTIMECMP_RST  64'hFFFF_FFFF_FFFF_FFFF

`endif
