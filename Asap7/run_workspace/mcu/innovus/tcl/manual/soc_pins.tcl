############################################################
## Pin top_soc (Hierarchy trang 9-10: khai bao het pin, thu tu nguoc chieu
## kim dong ho).  Layer/kich thuoc cua Risc_V: canh tren/duoi M7 doc,
## canh trai/phai M6 ngang, 0.032 x 0.072 um (1x; 0.128 x 0.288 o 4x).
##
## Bon danh sach duoi day giu theo nhom chuc nang; khi dat, moi pin chi nam
## tren canh tren/duoi trong khoang x vung logic (xem ghi chu cuoi file).
## Tren than SRAM khong dat duoc buffer nen pin khong duoc nam doi dien SRAM.
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

# Run 2026-09-17: RAM_LO/RAM_HI la hai tuong SRAM cao het loi o canh trai/phai
# (row da cat), nen net tu pin canh trai/phai (va doan canh tren/duoi nam tren
# SRAM) dai ~500 um khong co cho dat buffer -> 90/101 vi pham max_tran la port.
# Vi vay moi pin chi nam tren canh TREN/DUOI, trong khoang x cua vung logic
# giua hai tuong SRAM.  Canh duoi con cum CACHE cao ~360 um nen chi de pin VAO.
#   Tren (nguoc chieu kim dong ho, phai -> trai): SDRAM | pad_out | flash + pad_oe
#   Duoi (trai -> phai): clock/reset/JTAG + pad_in
set top_side_pins [concat $right_pins $top_pins $left_pins]
set bottom_side_pins $bottom_pins

lassign [lindex [dbGet top.fPlan.box] 0] die_x0 die_y0 die_x1 die_y1
lassign [lindex [dbGet top.fPlan.coreBox] 0] core_x0 core_y0 core_x1 core_y1
set logic_x0 $core_x0
set logic_x1 $core_x1
set core_xm [expr {($core_x0 + $core_x1) / 2.0}]
foreach k [soc_sram_no_std_boxes] {
    lassign $k kx0 ky0 kx1 ky1
    # Keepout cham ca mep duoi lan mep tren loi = mot cum cua tuong SRAM.  Tu khi
    # co kenh buffer (SOC_WALL_CHANNEL) moi tuong la 3 cum, cum trong khong cham
    # mep loi -> xet theo nua loi, khong theo mep.
    if {$ky0 <= $core_y0 + [soc_len 0.25] && $ky1 >= $core_y1 - [soc_len 0.25]} {
        if {($kx0 + $kx1) / 2.0 < $core_xm} {
            set logic_x0 [expr {max($logic_x0, $kx1)}]
        } else {
            set logic_x1 [expr {min($logic_x1, $kx0)}]
        }
    }
}
set pin_margin [soc_len 5.0]
set pin_x0 [expr {$logic_x0 + $pin_margin}]
set pin_x1 [expr {$logic_x1 - $pin_margin}]
set need [expr {max([llength $top_side_pins], [llength $bottom_side_pins]) * [soc_len 0.5]}]
if {$pin_x1 - $pin_x0 < $need} {
    error [format "soc_pins.tcl: vung logic %.1f..%.1f qua hep cho %d pin" \
        $pin_x0 $pin_x1 [llength $top_side_pins]]
}

setPinAssignMode -pinEditInBatch true
editPin -pinWidth [soc_len 0.032] -pinDepth [soc_len 0.072] -fixOverlap 1 \
    -spreadType range -spreadDirection counterclockwise \
    -start [list $pin_x1 $die_y1] -end [list $pin_x0 $die_y1] \
    -side TOP -layer M7 -honorConstraint 1 -pin $top_side_pins
editPin -pinWidth [soc_len 0.032] -pinDepth [soc_len 0.072] -fixOverlap 1 \
    -spreadType range -spreadDirection counterclockwise \
    -start [list $pin_x0 $die_y0] -end [list $pin_x1 $die_y0] \
    -side BOTTOM -layer M7 -honorConstraint 1 -pin $bottom_side_pins
setPinAssignMode -pinEditInBatch false

puts [format "INFO: da gan %d pin top_soc: tren %d, duoi %d, x %.1f..%.1f" \
    [llength $assigned] [llength $top_side_pins] [llength $bottom_side_pins] $pin_x0 $pin_x1]
