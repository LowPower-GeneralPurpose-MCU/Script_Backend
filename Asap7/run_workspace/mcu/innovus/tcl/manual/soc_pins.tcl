############################################################
## Pin top_soc (Hierarchy trang 9-10: khai bao het pin, thu tu nguoc chieu
## kim dong ho).  Layer/kich thuoc cua Risc_V: canh tren/duoi M7 doc,
## canh trai/phai M6 ngang, 0.128 x 0.288 um.
##
## Canh duoi de trong vi mam dat cum CACHE/TAG sat mep duoi.  Doi canh thi
## chi sua bon danh sach duoi day.
############################################################

proc soc_bus {name msb lsb} {
    set pins {}
    for {set i $msb} {$i >= $lsb} {incr i -1} {
        lappend pins "${name}\[$i\]"
    }
    return $pins
}

# Trai: clock, reset, JTAG, SPI flash.
set left_pins [concat \
    {clk rtc_clk rst_n tck trst_n tms tdi tdo flash_sck flash_cs_n} \
    [soc_bus flash_io_i 3 0] [soc_bus flash_io_o 3 0] [soc_bus flash_io_oe 3 0]]

# Tren: 32 GPIO pad (vao, ra, output enable).
set top_pins [concat [soc_bus pad_in 31 0] [soc_bus pad_out 31 0] [soc_bus pad_oe 31 0]]

# Phai: SDRAM.
set right_pins [concat \
    {sdram_clk sdram_cke sdram_cs_n sdram_ras_n sdram_cas_n sdram_we_n sdram_dq_oe} \
    [soc_bus sdram_ba 1 0] [soc_bus sdram_dqm 1 0] [soc_bus sdram_addr 12 0] \
    [soc_bus sdram_dq_i 15 0] [soc_bus sdram_dq_o 15 0]]

set bottom_pins {}

# Netlist va danh sach phai khop tung pin.
set assigned [concat $left_pins $top_pins $right_pins $bottom_pins]
set design_pins [dbGet top.terms.name]
foreach pin $assigned {
    if {[lsearch -exact $design_pins $pin] < 0} {
        error "soc_pins.tcl: top_soc khong co pin $pin"
    }
}
foreach pin $design_pins {
    if {[lsearch -exact $assigned $pin] < 0} {
        error "soc_pins.tcl: pin $pin chua duoc gan canh nao"
    }
}
if {[llength $assigned] != [llength [lsort -unique $assigned]]} {
    error "soc_pins.tcl: co pin bi gan hai lan"
}

setPinAssignMode -pinEditInBatch true
foreach {side layer pins} [list \
    LEFT   M6 $left_pins \
    TOP    M7 $top_pins \
    RIGHT  M6 $right_pins \
    BOTTOM M7 $bottom_pins] {
    if {[llength $pins] == 0} {
        continue
    }
    editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 \
        -spreadType side -spreadDirection counterclockwise \
        -side $side -layer $layer -honorConstraint 1 -pin $pins
}
setPinAssignMode -pinEditInBatch false

puts "INFO: da gan [llength $assigned] pin top_soc (trai [llength $left_pins],\
 tren [llength $top_pins], phai [llength $right_pins], duoi [llength $bottom_pins])"
