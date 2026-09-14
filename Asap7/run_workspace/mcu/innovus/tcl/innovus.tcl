############################################################
## Innovus top_soc - floorplan + power grid, chay lan luot tung KHOI
## Theo slide x_Hierarchy Layout.pdf + 10_Macro.pdf, doi sang ASAP7.
##
## CACH 1 - lam tay tung buoc (giong slide cua thay):
##   cd Asap7/run_workspace/mcu/innovus
##   innovus
##   -> copy tung khoi duoi day, paste vao console Innovus
##   -> o cac cho [LAM TAY] thi chinh trong GUI roi moi paste khoi sau
##
## CACH 2 - chay mot mach (khong chinh tay, dung vi tri mam):
##   innovus -files tcl/innovus.tcl
##
## Moi khoi (tru KHOI 0) boc trong soc_block: lenh nao loi thi ca khoi dung,
## khong chay tiep lenh phia sau.  Thong so sua o tcl/manual/soc_fp_config.tcl.
############################################################


# ==========================================================================
# KHOI 0 - Nap thiet ke
# (paste nguyen doan; khong boc soc_block vi proc do chua duoc nap)
# ==========================================================================
# init_common.tcl: preflight, init_design, CPU, noi VDD/VSS, derate SRAM,
# set_max_fanout 1 tren output SRAM, kiem 15 clock, dont_touch TRNG RO.
if {[info script] ne ""} {
    cd [file dirname [file dirname [file normalize [info script]]]]
}
if {![file isfile ./tcl/init_common.tcl]} {
    error "Hay cd vao Asap7/run_workspace/mcu/innovus truoc (dang o [pwd])"
}
source ./tcl/init_common.tcl
source ./tcl/manual/soc_fp_config.tcl
source ./tcl/manual/soc_fp_procs.tcl
soc_check_groups
set SOC_STD_AREAS [soc_std_area_by_top_inst]
set SOC_STD_TOTAL 0.0
dict for {top area} $SOC_STD_AREAS {
    set SOC_STD_TOTAL [expr {$SOC_STD_TOTAL + $area}]
}
puts "Std cell: [format %.1f $SOC_STD_TOTAL] um^2 (glue top-level\
 [format %.1f [dict get $SOC_STD_AREAS __top_glue__]] um^2)"


# ==========================================================================
# KHOI 1 - Kich thuoc loi + module guide   (Hierarchy trang 24-26)
# ==========================================================================
soc_block "KHOI 1: floorPlan + guide" {
    set SOC_LAYOUT [soc_layout $SOC_STD_TOTAL]
    floorPlan -s [dict get $SOC_LAYOUT core_w] [dict get $SOC_LAYOUT core_h] \
        $SOC_CORE_MARGIN $SOC_CORE_MARGIN $SOC_CORE_MARGIN $SOC_CORE_MARGIN

    # Slide dung proto_design, can license invs_ehfs (may nay khong co).
    if {[info exists ::env(MCU_RUN_PROTO_DESIGN)] && $::env(MCU_RUN_PROTO_DESIGN) eq "1"} {
        timeDesign -proto -prePlace -outDir ./reports/hierFP_proto_timing
        set_proto_design_mode -timing_aware true -congestion_aware true
        proto_design
    } else {
        soc_create_guides $SOC_LAYOUT $SOC_STD_AREAS
    }
    foreach g {RAM_LO RAM_HI CACHE TAG} {
        lassign [dict get $SOC_LAYOUT $g] x y w h
        puts [format "Cho danh cho SRAM %-6s %7.1f x %-7.1f tai (%.1f, %.1f)" $g $w $h \
            [expr {[dbGet top.fPlan.coreBox_llx] + $x}] [expr {[dbGet top.fPlan.coreBox_lly] + $y}]]
    }
    soc_report_guides $SOC_STD_AREAS ./reports/guide_util_hierFP.rpt
}

# --------------------------------------------------------------------------
# [LAM TAY 1] Chinh guide   (Hierarchy trang 27-28)
# --------------------------------------------------------------------------
# GUI:
#   - Bat Floorplan View (nut tren toolbar, slide trang 33) de thay guide.
#   - Mo Toolbox (slide trang 27: nut 1 -> 2 -> 3).
#   - Click chon guide: keo canh/goc de doi kich thuoc, keo giua de di chuyen,
#     phim Delete de xoa guide.
#   - Toolbox > Align / Space de xep guide thang hang.
# Lenh tuong duong (thay so toa do):
#   setObjFPlanBox Module u_core 900 390 1150 640       ;# doi hop guide
#   createGuide u_apb_ascon_u_ascon 600 1200 700 1300   ;# them guide
# Kiem mat do sau moi lan chinh (phai < 80%, tot nhat ~75%):
#   soc_report_guides $SOC_STD_AREAS ./reports/guide_util_hierFP.rpt
# Quy tac slide trang 28:
#   - module noi nhieu dat sat nhau: u_core <-> u_icache/u_dcache <-> cum CACHE
#   - u_axi_interconnect o giua, DMA canh interconnect
#   - module chua SRAM de o canh/goc; chua can quan tam tung SRAM
# Doi ca kich thuoc loi: dat MCU_CORE_WIDTH_UM / MCU_CORE_HEIGHT_UM truoc khi
# mo innovus, hoac 'set MCU_CORE_WIDTH_OVERRIDE <w>' roi paste lai KHOI 1.


# ==========================================================================
# KHOI 2 - Chot hierarchy floorplan   (Hierarchy trang 29)
# ==========================================================================
soc_block "KHOI 2: snap guide + luu FloorPlan.fp" {
    set bad [soc_report_guides $SOC_STD_AREAS ./reports/guide_util_hierFP_final.rpt]
    if {$bad > 0} {
        error "$bad guide co mat do >= [expr {int($SOC_GUIDE_MAX_UTIL * 100)}]% - quay lai LAM TAY 1"
    }
    snapFPlan -guide
    saveFPlan ./outputs/FloorPlan.fp
    checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP.rpt
    saveDesign ./saved/${TOP}_hierFP.enc
}


# ==========================================================================
# KHOI 3 - Dua SRAM vao, dat mam theo cum   (Hierarchy trang 31-32)
# ==========================================================================
soc_block "KHOI 3: dat mam 84 SRAM" {
    # Tinh lai bo cuc tren loi hien tai (neu o LAM TAY 1 ban da doi loi).
    set MCU_CORE_WIDTH_OVERRIDE  [dbGet top.fPlan.coreBox_sizex]
    set MCU_CORE_HEIGHT_OVERRIDE [dbGet top.fPlan.coreBox_sizey]
    set SOC_LAYOUT [soc_layout 0.0]
    foreach g {RAM_LO RAM_HI CACHE TAG} {
        lassign [dict get $SOC_LAYOUT $g] x y
        puts "Cum $g: [soc_place_group $g $x $y placed] macro"
    }
    # Halo 2 row moi phia: hai SRAM cach 4 row thi hai halo vua kin khe.
    addHaloToBlock -allBlock $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO
    set errors [soc_check_macros ./reports/sram_macro_check.rpt]
    puts "Kiem tra mam: [llength $errors] loi"
}

# --------------------------------------------------------------------------
# [LAM TAY 2] Xep lai SRAM   (Hierarchy trang 33-35, 10_Macro trang 7-14)
# --------------------------------------------------------------------------
# GUI:
#   - Floorplan View, mo Toolbox.
#   - Toolbox > Space: nhap 4.32 (slide ROHM 20.16 = 4 row; ASAP7 4 row = 4.32).
#   - Chon nhieu SRAM (Shift+click hoac keo khung) roi Space / Align.
#   - Flip/Rotate: chi Flip (MY/MX). KHONG xoay 90/270 do.
#   - SRAM dang o status placed nen keo duoc; KHOI 4 moi set FIXED.
# Lenh tuong duong:
#   placeInstance <ten_instance> <x> <y> MY          ;# dat 1 SRAM
#   selectInst <ten>; flipOrRotateObject -flip MY    ;# lat SRAM dang chon
#   deselectAll
#   dbGet [dbGet -p top.insts.name <ten>].pt         ;# xem toa do goc
#   soc_group_records CACHE                          ;# liet ke SRAM mot cum
# Kiem tra bat ky luc nao (huong, nam trong loi, khe >= 4.32):
#   soc_check_macros ./reports/sram_macro_check.rpt
# Quy tac:
#   - SRAM cung module nam cung cum; cum sat canh/goc; khong de notch
#   - chan SRAM hai cot ke nhau quay vao nhau (mam: cot chan R0, cot le MY)
#   - cum CACHE/TAG gan guide u_core/u_icache/u_dcache


# ==========================================================================
# KHOI 4 - Chot SRAM: snap, kiem tra, FIXED   (Hierarchy trang 36, Macro trang 14)
# ==========================================================================
soc_block "KHOI 4: snap + FIXED + luu FloorPlan_withMacro.fp" {
    # Snap goc SRAM ve luoi site/row (thay refine_macro_place cua slide, lenh
    # do co the dich macro vua xep tay).
    set core_llx [dbGet top.fPlan.coreBox_llx]
    set core_lly [dbGet top.fPlan.coreBox_lly]
    foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
        foreach record [soc_group_records $group] {
            lassign $record name ptr
            lassign [lindex [dbGet $ptr.pt] 0] x y
            set sx [soc_snap_near $x $core_llx $SOC_SITE_W]
            set sy [soc_snap_near $y $core_lly $SOC_ROW_H]
            if {abs($sx - $x) > 1e-4 || abs($sy - $y) > 1e-4} {
                set orient [dbGet $ptr.orient]
                dbSet $ptr.pStatus unplaced
                placeInstance $name $sx $sy $orient
            }
        }
    }
    snapFPlan -block

    set errors [soc_check_macros ./reports/sram_macro_check_final.rpt]
    if {[llength $errors] > 0} {
        foreach e [lrange $errors 0 19] {
            puts "ERROR: $e"
        }
        error "[llength $errors] loi vi tri SRAM - quay lai LAM TAY 2"
    }
    foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
        foreach record [soc_group_records $group] {
            dbSet [lindex $record 1].pStatus fixed
        }
    }
    addHaloToBlock -allBlock $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO
    saveFPlan ./outputs/FloorPlan_withMacro.fp
    checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_macroFP.rpt
    saveDesign ./saved/${TOP}_macroFP.enc
}


# ==========================================================================
# KHOI 5 - Ring loi M8 ngang / M9 doc   (so cua flow Risc_V)
# ==========================================================================
soc_block "KHOI 5: core ring" {
    deleteAllPowerPreroutes
    set vss_ring_offset [expr {$SOC_CORE_RING_OFFSET + $SOC_CORE_RING_W + $SOC_CORE_RING_S}]
    if {$vss_ring_offset + $SOC_CORE_RING_W + 0.160 > $SOC_CORE_MARGIN} {
        error "Ring loi khong lot vao SOC_CORE_MARGIN = $SOC_CORE_MARGIN"
    }
    setAddStripeMode -reset
    foreach {net offset} [list VDD $SOC_CORE_RING_OFFSET VSS $vss_ring_offset] {
        addRing -nets [list $net] \
            -type core_rings -follow core \
            -layer {top M8 bottom M8 left M9 right M9} \
            -width $SOC_CORE_RING_W -spacing $SOC_CORE_RING_S -offset $offset \
            -snap_wire_center_to_grid Grid
    }
}


# ==========================================================================
# KHOI 6 - Block ring quanh TUNG cum SRAM   (Hierarchy trang 37-40)
# ==========================================================================
# Slide: chon mot cum SRAM trong GUI roi addRing, lap lai cho moi cum.
# Khoi nay tu chon tung cum theo SOC_SRAM_GROUPS roi goi soc_ring_selected.
soc_block "KHOI 6: block ring cho cac cum SRAM" {
    proc soc_ring_selected {} {
        addRing -nets {VSS VDD} \
            -type block_rings -around shared_cluster \
            -layer $::SOC_BLOCK_RING_LAYERS \
            -width $::SOC_BLOCK_RING_W \
            -spacing $::SOC_BLOCK_RING_S \
            -offset $::SOC_BLOCK_RING_OFFSET
    }
    foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
        deselectAll
        foreach record [soc_group_records $group] {
            selectInst [lindex $record 0]
        }
        puts "Block ring cum $group: [llength [dbGet selected]] macro"
        soc_ring_selected
    }
    deselectAll
}

# --------------------------------------------------------------------------
# [LAM TAY 3 - tuy chon] Xem / lam lai block ring   (Hierarchy trang 39-40)
# --------------------------------------------------------------------------
# GUI:
#   - Zoom vao khe giua hai SRAM: phai thay 1 cap VDD/VSS (M4 ngang, M5 doc).
#   - Click ra ngoai floorplan de bo chon sau khi xem (slide trang 39).
# Lam lai ring kieu slide (chon cum bang tay):
#   editDelete -shape BLOCKRING      ;# xoa het block ring
#   (GUI) chon cac SRAM cua mot cum
#   soc_ring_selected                ;# ring cho cum dang chon
#   deselectAll                      ;# lap lai cho cum khac


# ==========================================================================
# KHOI 7 - Noi chan SRAM + luoi nguon toan chip   (Hierarchy trang 38, 41)
# ==========================================================================
soc_block "KHOI 7: sroute blockPin + luoi M7/M6" {
    # Chan VDD/VSS cua SRAM (tren M4) -> block ring.  Slide dung nearestTarget;
    # flow sram_axi phai tat nearestTarget, nen mac dinh la blockring.
    setSrouteMode -reset
    setSrouteMode \
        -extendNearestTarget true \
        -blockPinRouteWithPinWidth true \
        -viaConnectToShape {blockring}
    sroute -connect {blockPin} \
        -blockPinTarget [list $SOC_BLOCKPIN_TARGET] \
        -nets {VSS VDD}

    # M7 doc, via len ring M8.
    setAddStripeMode -reset
    setAddStripeMode -allow_jog none -break_at {block_ring} -split_vias true \
        -via_using_exact_crossover_size false \
        -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
    addStripe -nets {VDD VSS} -layer M7 -direction vertical \
        -width $SOC_MESH_W -spacing $SOC_MESH_S \
        -set_to_set_distance $SOC_MESH_PITCH \
        -start_from left -start_offset $SOC_MESH_OFFSET \
        -snap_wire_center_to_grid Grid

    # M6 ngang, via xuong M5 de an vao canh doc cua block ring SRAM.
    setAddStripeMode -reset
    setAddStripeMode -allow_jog none -break_at {block_ring} -split_vias true \
        -via_using_exact_crossover_size false \
        -stacked_via_bottom_layer M5 -stacked_via_top_layer M7
    addStripe -nets {VDD VSS} -layer M6 -direction horizontal \
        -width $SOC_MESH_W -spacing $SOC_MESH_S \
        -set_to_set_distance $SOC_MESH_PITCH \
        -start_from bottom -start_offset $SOC_MESH_OFFSET \
        -snap_wire_center_to_grid Grid

    editTrim -nets {VDD VSS}
}
# GUI: panel Layer, bat/tat M6, M7 de nhin luoi.  Neu stripe de len than SRAM
# thi xem lai obstruction cua SRAM truoc khi di tiep.


# ==========================================================================
# KHOI 8 - Placement blockage quanh SRAM + pin   (Hierarchy trang 38, 9-10)
# ==========================================================================
soc_block "KHOI 8: blockage + pin" {
    # Rong hon halo 1 row de phu ca canh ngoai cua block ring.
    set blk [expr {($SOC_HALO_ROWS + 1) * $SOC_ROW_H}]
    createPlaceBlockage -allMacro -snapToSite -outerRingBySide [list $blk $blk $blk $blk]

    setPinConstraint -cell $TOP -corner_to_pin_distance 8
    source ./tcl/manual/soc_pins.tcl
}
# [LAM TAY - tuy chon] Doi canh pin: sua 4 danh sach trong tcl/manual/soc_pins.tcl
# roi paste lai 'source ./tcl/manual/soc_pins.tcl'.  GUI: Edit > Pin Editor.


# ==========================================================================
# KHOI 9 - Kiem tra + luu (truoc placement)
# ==========================================================================
soc_block "KHOI 9: verify + saveDesign" {
    clearDrc
    verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
        -error 100000 -warning 1000 \
        -report ./verify_rpt/connectivity_powerplan.rpt
    verify_drc -limit 100000 -report ./verify_rpt/drc_powerplan.rpt
    checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_powerplan.rpt
    report_clocks > ./reports/clocks_floorplan.rpt
    report_analysis_views > ./reports/analysis_views.rpt
    saveDesign ./saved/${TOP}_powerplan.enc

    soc_banner "FLOORPLAN + POWER GRID XONG - saved/${TOP}_powerplan.enc
  verify_rpt/connectivity_powerplan.rpt : moi SRAM phai noi VDD/VSS
      (open o chan std cell la binh thuong - rail M1 chua lam)
  verify_rpt/drc_powerplan.rpt          : phai 0 vi pham PG
  GUI: Tools > Violation Browser de xem tung loi
Sau place_design: soc_stdcell_rails (rail M1 + stripe M5, Risc_V lam sau placement)"
}


# ==========================================================================
# CHAY LAI TU GIUA (session moi) - copy phan can dung, bo dau '#'
# ==========================================================================
# Luon paste KHOI 0 truoc, sau do:
#
# a) Da co guide (sau KHOI 2), lam lai SRAM:
#   loadFPlan ./outputs/FloorPlan.fp
#   -> paste KHOI 3, LAM TAY 2, KHOI 4 ...
#
# b) SRAM da FIXED (sau KHOI 4), lam lai power grid:
#   loadFPlan ./outputs/FloorPlan_withMacro.fp
#   -> paste KHOI 5 ... KHOI 9
#
# c) Chi mo lai ket qua da luu de xem:
#   restoreDesign ./saved/top_soc_powerplan.enc.dat top_soc
