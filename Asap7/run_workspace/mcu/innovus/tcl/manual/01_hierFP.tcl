############################################################
## Buoc 1 - Hierarchy floorplan (x_Hierarchy Layout.pdf trang 24-29)
##
##   cd Asap7/run_workspace/mcu/innovus
##   innovus -files tcl/manual/01_hierFP.tcl
##
## Session nay KHONG thoat.  Sua guide trong GUI (Floorplan toolbox), roi go
## trong console Innovus:
##   source tcl/manual/01_finish_hierFP.tcl
##
## Khac slide: proto_design can license invs_ehfs, may nay khong co
## (IMPLIC-90 o flow Risc_V).  Script tu tao guide mam tu dien tich module;
## dat MCU_RUN_PROTO_DESIGN=1 neu co license de dung proto_design nhu slide.
############################################################

set INNOVUS_DIR [file dirname [file dirname [file dirname [file normalize [info script]]]]]
cd $INNOVUS_DIR

source ./tcl/init_common.tcl
source ./tcl/manual/soc_fp_config.tcl
source ./tcl/manual/soc_fp_procs.tcl

soc_check_groups

set SOC_STD_AREAS [soc_std_area_by_top_inst]
set SOC_STD_TOTAL 0.0
dict for {top area} $SOC_STD_AREAS {
    set SOC_STD_TOTAL [expr {$SOC_STD_TOTAL + $area}]
}
set SOC_LAYOUT [soc_layout $SOC_STD_TOTAL]

floorPlan -s [dict get $SOC_LAYOUT core_w] [dict get $SOC_LAYOUT core_h] \
    $SOC_CORE_MARGIN $SOC_CORE_MARGIN $SOC_CORE_MARGIN $SOC_CORE_MARGIN

if {[info exists ::env(MCU_RUN_PROTO_DESIGN)] && $::env(MCU_RUN_PROTO_DESIGN) eq "1"} {
    timeDesign -proto -prePlace -outDir ./reports/hierFP_proto_timing
    set_proto_design_mode -timing_aware true -congestion_aware true
    proto_design
} else {
    soc_create_guides $SOC_LAYOUT $SOC_STD_AREAS
}

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
foreach g {RAM_LO RAM_HI CACHE TAG} {
    lassign [dict get $SOC_LAYOUT $g] x y w h
    puts [format "Vung danh cho SRAM %-6s %7.1f x %-7.1f tai (%.1f, %.1f)" $g $w $h \
        [expr {$core_llx + $x}] [expr {$core_lly + $y}]]
}

soc_report_guides $SOC_STD_AREAS ./reports/guide_util_hierFP.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP.rpt

puts "Dien tich std cell: [format %.1f $SOC_STD_TOTAL] um^2, glue top-level:\
 [format %.1f [dict get $SOC_STD_AREAS __top_glue__]] um^2"
soc_banner "BUOC 1 - PHAN TU DONG XONG, loi [dict get $SOC_LAYOUT core_w] x [dict get $SOC_LAYOUT core_h] um

Viec cua ban trong GUI (slide Hierarchy trang 28):
  1. Moi guide < 80% (tot nhat ~75%) - reports/guide_util_hierFP.rpt
  2. Module noi nhieu voi nhau dat sat nhau:
       u_core <-> u_icache/u_dcache <-> cum CACHE/TAG (mep duoi)
       u_axi_interconnect o giua, DMA canh interconnect
  3. Module co SRAM de o canh/goc; chua quan tam vi tri tung SRAM
  4. Keo guide bang Floorplan toolbox (slide trang 27).  Kiem lai mat do:
       soc_report_guides \$SOC_STD_AREAS ./reports/guide_util_hierFP.rpt
  5. Xong: source tcl/manual/01_finish_hierFP.tcl"
