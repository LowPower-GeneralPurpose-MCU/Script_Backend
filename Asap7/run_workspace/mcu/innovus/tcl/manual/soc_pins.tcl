############################################################
## Pin top_soc (Hierarchy trang 9-10: khai bao het pin, thu tu nguoc chieu
## kim dong ho).  Layer/kich thuoc cua Risc_V: canh tren/duoi M7 doc,
## canh trai/phai M6 ngang, 0.128 x 0.288 um.
##
## Pin trai du 4 canh.  SRAM ASAP7 chi chan cac layer thap (chan PG tren M4),
## nen pin M6/M7 di duoc qua tren SRAM.  Nhung tren than SRAM khong dat
## duoc buffer, nen clock/reset/JTAG de o canh co logic (duoi); pin GPIO
## cham thi de canh nao cung duoc.  Doi canh: chi sua bon danh sach duoi day.
############################################################

proc soc_bus {name msb lsb} {
    set pins {}
    for {set i $msb} {$i >= $lsb} {incr i -1} {
        lappend pins "${name}\[$i\]"
    }
    return $pins
}

# Duoi (40): clock, reset, JTAG + GPIO vao.
set bottom_pins [concat \
    {clk rtc_clk rst_n tck trst_n tms tdi tdo} \
    [soc_bus pad_in 31 0]]

# Phai (56): SDRAM.
set right_pins [concat \
    {sdram_clk sdram_cke sdram_cs_n sdram_ras_n sdram_cas_n sdram_we_n sdram_dq_oe} \
    [soc_bus sdram_ba 1 0] [soc_bus sdram_dqm 1 0] [soc_bus sdram_addr 12 0] \
    [soc_bus sdram_dq_i 15 0] [soc_bus sdram_dq_o 15 0]]

# Tren (32): GPIO ra.
set top_pins [soc_bus pad_out 31 0]

# Trai (46): SPI flash + GPIO output enable.
set left_pins [concat \
    {flash_sck flash_cs_n} \
    [soc_bus flash_io_i 3 0] [soc_bus flash_io_o 3 0] [soc_bus flash_io_oe 3 0] \
    [soc_bus pad_oe 31 0]]

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
