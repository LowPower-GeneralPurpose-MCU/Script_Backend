############################################################
## RTL file list
##
## Read order:
##   1. SRAM black-box interface
##   2. 16-bank SRAM wrapper
##   3. AXI controller top
############################################################

set RTL_FILES [list \
    "./rtl/asap7_sram_64k_1rw.v" \
    "./rtl/axi_ram.v" \
]

foreach rtl $RTL_FILES {
    if {![file exists $rtl]} {
        error "Missing RTL source: [file normalize $rtl]"
    }
}
