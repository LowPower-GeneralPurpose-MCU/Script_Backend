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
## Them SRAM 1x goc cua ASU vao LEF de xem so loi lech grid (IMPLF-82):
##   export SMOKE_1X_SRAM=1
## Session moi cho moi lan chay (xem init_common.tcl ve IMPSYT-7329).
############################################################
source ./tcl/project_config.tcl

set smoke_tech [file join $STDCELL_ROOT techlef_misc asap7_tech_1x_201209.lef]
set smoke_cell [file join $STDCELL_ROOT LEF asap7sc7p5t_28_R_1x_220121a.lef]
set smoke_lefs [list $smoke_tech $smoke_cell]
if {[info exists ::env(SMOKE_1X_SRAM)] && $::env(SMOKE_1X_SRAM)} {
    lappend smoke_lefs [file join $SRAM_ROOT generated LEF "$SRAM_MASTER.lef"] \
                       [file join $SRAM_ROOT generated LEF "$SRAM_TAG_MASTER.lef"]
}
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
