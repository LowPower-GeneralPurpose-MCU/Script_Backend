############################################################
## Buoc 2 - Dua SRAM vao (Hierarchy trang 31-36, 10_Macro trang 7-14)
##
##   innovus -files tcl/manual/02_planning.tcl
##
## Session KHONG thoat.  Chinh SRAM trong GUI roi go:
##   source tcl/manual/02_finish_planning.tcl
##
## MCU_REUSE_MACRO_FP=1: nap lai outputs/FloorPlan_withMacro.fp da duyet
## thay vi dat mam moi (giong nhanh 'if exists FloorPlan_withMacro.fp' cua slide).
############################################################

set INNOVUS_DIR [file dirname [file dirname [file dirname [file normalize [info script]]]]]
cd $INNOVUS_DIR

source ./tcl/init_common.tcl
source ./tcl/manual/soc_fp_config.tcl
source ./tcl/manual/soc_fp_procs.tcl

soc_check_groups
set SOC_STD_AREAS [soc_std_area_by_top_inst]

set reuse [expr {[info exists ::env(MCU_REUSE_MACRO_FP)] && $::env(MCU_REUSE_MACRO_FP) eq "1"}]
if {$reuse} {
    set fp_file ./outputs/FloorPlan_withMacro.fp
} else {
    set fp_file ./outputs/FloorPlan.fp
}
if {![file isfile $fp_file]} {
    error "Thieu $fp_file - chay buoc truoc"
}
loadFPlan $fp_file

if {!$reuse} {
    # Bo cuc mam tinh tren loi da nap (co the ban da doi kich thuoc o buoc 1).
    set MCU_CORE_WIDTH_OVERRIDE  [dbGet top.fPlan.coreBox_sizex]
    set MCU_CORE_HEIGHT_OVERRIDE [dbGet top.fPlan.coreBox_sizey]
    set SOC_LAYOUT [soc_layout 0.0]

    set placed 0
    foreach g {RAM_LO RAM_HI CACHE TAG} {
        lassign [dict get $SOC_LAYOUT $g] x y
        incr placed [soc_place_group $g $x $y placed]
    }
    puts "Da dat mam $placed macro (status placed - con keo duoc)"

    # Halo 2 row moi phia: hai SRAM cach 4 row thi hai halo vua kin khe.
    addHaloToBlock -allBlock $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO
}

set errors [soc_check_macros ./reports/sram_macro_check.rpt]
puts "Kiem tra mam: [llength $errors] loi (reports/sram_macro_check.rpt)"

soc_banner "BUOC 2 - SRAM DA VAO, CHINH BANG TAY (Hierarchy trang 33-35)

  1. Chuyen sang floorplan view (nut o slide trang 33), mo Toolbox
  2. Space = [format %.2f $SOC_MACRO_GAP] um  (slide ROHM 20.16 = 4 row; ASAP7 4 row = 4.32)
  3. Quy tac:
       - SRAM cung module nam cung mot cum (RAM_LO, RAM_HI, CACHE, TAG)
       - cum sat canh/goc loi, khong tao notch (10_Macro trang 13)
       - chan SRAM hai cot ke nhau quay vao nhau; chi Flip, KHONG xoay 90
       - cum CACHE/TAG gan guide u_core/u_icache/u_dcache
  4. Kiem tra bat ky luc nao:
       soc_check_macros ./reports/sram_macro_check.rpt
  5. Xong: source tcl/manual/02_finish_planning.tcl"
