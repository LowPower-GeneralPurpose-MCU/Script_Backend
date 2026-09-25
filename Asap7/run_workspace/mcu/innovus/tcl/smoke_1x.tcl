############################################################
## Thu Innovus voi thu vien ASAP7 1x (khong scale) - KHONG dung flow chinh.
##
## Muc dich: truoc khi chuyen ca flow sang 1x, biet chac ban quyen Innovus
## chap nhan hinh hoc 7 nm that (M1 pitch 0.036) hay khong.  Thiet ke thu la
## 64 inverter noi chuoi: init_design -> floorPlan -> place -> route -> DRC.
##
##   cd run_workspace/mcu/innovus
##   innovus -no_gui -files ./tcl/smoke_1x.tcl -log ./logs/smoke_1x.log
##
## Them 2 LEF SRAM 1x (.fixed.lef, phai 0 IMPLF-82) - export TRUOC khi goi innovus:
##   export SMOKE_1X_SRAM=1
## Session moi cho moi lan chay (xem init_common.tcl ve IMPSYT-7329).
############################################################
source ./tcl/project_config.tcl

# Dung DUNG file flow chinh dung (project_config.tcl, MCU_SCALE=1): tech LEF
# 1x da sua trong repo (asap7_tech_1x_201209.fixed.lef) va LEF SRAM 1x
# <m>.fixed.lef.  Lan chay 2026-09-25 dung tech 1x goc -> IMPTR-2101 o Pad
# ("M10"); lan nay phai het.
# Luu y: log smoke_1x_sram.log 2026-09-25 KHONG nap LEF SRAM nao (khong co dong
# "Loading LEF file ...srambank") - bien SMOKE_1X_SRAM chua duoc export.
if {$MCU_SCALE != 1} {
    error "smoke_1x: MCU_SCALE=$MCU_SCALE - bo 'export MCU_SCALE' roi chay lai"
}
set smoke_lefs [list $TECH_LEF $RVT_CELL_LEF]
if {[info exists ::env(SMOKE_1X_SRAM)] && $::env(SMOKE_1X_SRAM)} {
    lappend smoke_lefs $SRAM_LEF $SRAM_TAG_LEF
}
puts "SMOKE_1X: LEF = $smoke_lefs"
foreach f $smoke_lefs {
    if {![file isfile $f]} {
        error "smoke_1x: khong co $f - kiem ASAP7_STDCELL_ROOT / ASAP7_SRAM_ROOT"
    }
}

file mkdir ./smoke_1x
set fh [open ./smoke_1x/smoke.v w]
puts $fh "module smoke (input a, output y);"
puts $fh "  wire \[64:0\] n;"
puts $fh "  assign n\[0\] = a;"
for {set i 0} {$i < 64} {incr i} {
    puts $fh "  INVx1_ASAP7_75t_R u$i (.A(n\[$i\]), .Y(n\[[expr {$i + 1}]\]));"
}
puts $fh "  assign y = n\[64\];"
puts $fh "endmodule"
close $fh

set init_lef_file  $smoke_lefs
set init_verilog   ./smoke_1x/smoke.v
set init_top_cell  smoke
set init_pwr_net   VDD
set init_gnd_net   VSS
init_design

globalNetConnect VDD -type pgpin -pin VDD -all
globalNetConnect VSS -type pgpin -pin VSS -all
# Loi 6 x 6 um, le 1 um: du cho 64 INVx1 (~0.04 um^2 moi cell o 1x).
floorPlan -site asap7sc7p5t -s 6.0 6.0 1.0 1.0 1.0 1.0
placeDesign
routeDesign
verify_drc -report ./smoke_1x/drc.rpt
checkPlace ./smoke_1x/place.rpt

puts "SMOKE_1X: core = [dbGet top.fPlan.coreBox]  (phai ~ {1 1 7 7}, KHONG phai x4)"
puts "SMOKE_1X: M1 pitch = [dbGet [dbGetLayerByName M1].pitchX]  (1x = 0.036)"
puts "SMOKE_1X: xong - doc log tim ERROR/license, va ./smoke_1x/drc.rpt"
