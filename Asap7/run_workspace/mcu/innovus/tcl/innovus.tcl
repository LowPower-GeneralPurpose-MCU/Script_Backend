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
## THU TU POWER (giong slide):
##   - Ring loi M8/M9 chi bam mep loi -> lam truoc khi dat SRAM (KHOI 2).
##   - Luoi M4/M5 rieng tung cum SRAM + luoi M6/M7 toan chip
##     -> chi lam SAU khi SRAM da FIXED (KHOI 5, 6).
##   - Slide trang 32 cung chi ve ring + stripe TAM de tao PG model roi xoa
##     (editDelete -shape {STRIPE BLOCKRING}) truoc khi dat macro.
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
# KHOI 1 - Kich thuoc loi   (Hierarchy trang 24)
# ==========================================================================
# Khong chia vung (guide) cho module: SoC nho, de placer tu keo std cell lai
# gan SRAM.  Loi = cho cho 4 cum SRAM + vung logic giua (MCU_TARGET_STD_UTIL).
soc_block "KHOI 1: floorPlan" {
    set SOC_LAYOUT [soc_layout $SOC_STD_TOTAL]
    floorPlan -s [dict get $SOC_LAYOUT core_w] [dict get $SOC_LAYOUT core_h] \
        $SOC_CORE_MARGIN $SOC_CORE_MARGIN $SOC_CORE_MARGIN $SOC_CORE_MARGIN
    foreach g {RAM_LO RAM_HI CACHE TAG} {
        lassign [dict get $SOC_LAYOUT $g] x y w h
        puts [format "Cho danh cho SRAM %-6s %7.1f x %-7.1f tai (%.1f, %.1f)" $g $w $h \
            [expr {[dbGet top.fPlan.coreBox_llx] + $x}] [expr {[dbGet top.fPlan.coreBox_lly] + $y}]]
    }
    saveFPlan ./outputs/FloorPlan.fp
    checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_FP.rpt
}
# Doi kich thuoc loi: dat MCU_CORE_WIDTH_UM / MCU_CORE_HEIGHT_UM truoc khi mo
# innovus, hoac 'set MCU_CORE_WIDTH_OVERRIDE <w>' roi paste lai KHOI 1.


# ==========================================================================
# KHOI 2 - Ring loi M8 ngang / M9 doc   (so cua flow Risc_V)
# ==========================================================================
# Ring chi bam mep loi, khong phu thuoc SRAM -> lam truoc khi dat SRAM.
# Neu sau nay doi kich thuoc loi (floorPlan) thi phai paste lai khoi nay.
soc_block "KHOI 2: core ring" {
    deleteAllPowerPreroutes
    # Le loi->die that (floorPlan co the snap) = canh ngan nhat trong 4 canh
    lassign [lindex [dbGet top.fPlan.box] 0] dx0 dy0 dx1 dy1
    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx0 cy0 cx1 cy1
    set margin [expr {min($cx0 - $dx0, $cy0 - $dy0, $dx1 - $cx1, $dy1 - $cy1)}]
    # -offset = mep loi -> canh trong cua vong.  VSS ngoai (cach mep die 1 khoang S),
    # VDD vao trong.  Lam tron xuong manufacturing grid de Innovus khong tu snap ra ngoai.
    set g $SOC_MFG_GRID
    set vss_ring_offset [expr {floor(($margin - $SOC_CORE_RING_S - $SOC_CORE_RING_W) / $g + 1e-6) * $g}]
    set SOC_CORE_RING_OFFSET [expr {$vss_ring_offset - $SOC_CORE_RING_S - $SOC_CORE_RING_W}]
    puts [format "Ring loi: le %.3f | trong %.3f | VSS %.3f | trong %.3f | VDD %.3f | trong %.3f -> loi" \
        $margin [expr {$margin - $vss_ring_offset - $SOC_CORE_RING_W}] \
        $SOC_CORE_RING_W $SOC_CORE_RING_S $SOC_CORE_RING_W $SOC_CORE_RING_OFFSET]
    if {$SOC_CORE_RING_OFFSET < $SOC_MACRO_GAP} {
        error [format "Khoang trong trong cung %.3f < %.2f (cap VSS/VDD mep cum SRAM) - tang SOC_CORE_MARGIN" \
            $SOC_CORE_RING_OFFSET $SOC_MACRO_GAP]
    }
    setAddStripeMode -reset
    foreach {net offset} [list VDD $SOC_CORE_RING_OFFSET VSS $vss_ring_offset] {
        addRing -nets [list $net] \
            -type core_rings -follow core \
            -layer {top M8 bottom M8 left M9 right M9} \
            -width $SOC_CORE_RING_W -spacing $SOC_CORE_RING_S -offset $offset \
            -snap_wire_center_to_grid Grid
    }
    # addRing hong thuong chi in WARNING -> dem that so doan ring M8/M9 cua tung net
    foreach net {VDD VSS} {
        set rings [dbGet -e -p [dbGet -p top.nets.name $net].sWires.shape ring]
        set layers [expr {[llength $rings] ? [dbGet $rings.layer.name] : {}}]
        set n8 [llength [lsearch -all -exact $layers M8]]
        set n9 [llength [lsearch -all -exact $layers M9]]
        puts "Ring loi $net: $n8 doan M8, $n9 doan M9"
        if {$n8 < 2 || $n9 < 2} {
            error "Ring loi $net khong duoc tao du (M8=$n8 M9=$n9) - xem addRing trong innovus.log"
        }
    }
    # Ring rong 0.544 um tren loi ~2000 um: zoom-all se khong thay, zoom vao goc loi de xem.
}

# --------------------------------------------------------------------------
# [XEM TRUOC - tuy chon] Luoi M7/M6 de canh cum SRAM, xem xong XOA
# --------------------------------------------------------------------------
# Stripe ve bay gio se chay xuyen qua cho sau nay dat SRAM, nen chi de nhin.
#   soc_add_mesh                     ;# ve luoi tam
#   (GUI) bat/tat layer M6, M7 o panel Layer de nhin
#   editDelete -shape STRIPE         ;# BAT BUOC xoa truoc KHOI 3


# ==========================================================================
# KHOI 3 - Dua SRAM vao, dat mam theo cum   (Hierarchy trang 31-32)
# ==========================================================================
soc_block "KHOI 3: dat mam 84 SRAM" {
    set stripes [dbGet -e top.nets.sWires.shape stripe]
    if {[llength $stripes] > 0} {
        error "Con [llength $stripes] stripe tam - chay 'editDelete -shape STRIPE' truoc"
    }
    if {[file isfile $SOC_SRAM_PLACE_FILE]} {
        # Da xep tay truoc do (KHOI 4 / soc_save_sram_place da luu) -> nap lai.
        puts "Nap [soc_load_sram_place] SRAM tu $SOC_SRAM_PLACE_FILE (xoa file de xep mam lai)"
    } else {
        # Tinh lai bo cuc tren loi hien tai (neu ban da doi loi o KHOI 1).
        set MCU_CORE_WIDTH_OVERRIDE  [dbGet top.fPlan.coreBox_sizex]
        set MCU_CORE_HEIGHT_OVERRIDE [dbGet top.fPlan.coreBox_sizey]
        set SOC_LAYOUT [soc_layout 0.0]
        foreach g {RAM_LO RAM_HI CACHE TAG} {
            lassign [dict get $SOC_LAYOUT $g] x y
            puts "Cum $g: [soc_place_group $g $x $y placed] macro"
        }
    }
    # Halo 2 row moi phia: hai SRAM cach 4 row thi hai halo vua kin khe.
    addHaloToBlock -allBlock $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO
    set errors [soc_check_macros ./reports/sram_macro_check.rpt]
    puts "Kiem tra mam: [llength $errors] loi"
}

# --------------------------------------------------------------------------
# [LAM TAY 1] Xep lai SRAM   (Hierarchy trang 33-35, 10_Macro trang 7-14)
# --------------------------------------------------------------------------
# GUI:
#   - Floorplan View, mo Toolbox.
#   - Toolbox > Space: nhap 4.32 (slide ROHM 20.16 = 4 row; ASAP7 4 row = 4.32).
#   - Chon nhieu SRAM (Shift+click hoac keo khung) roi Space / Align.
#   - Chon 1 SRAM, nhan Q: sua Location / Orientation trong Attribute Editor.
#   - Flip/Rotate: chi Flip (MY/MX). KHONG xoay 90/270 do.
#   - SRAM dang o status placed nen keo duoc; KHOI 4 moi set FIXED.
# Lenh tuong duong:
#   soc_group_records CACHE                          ;# liet ke SRAM mot cum
#   soc_place_group RAM_LO 10 10 placed              ;# xep ca cum tai (x,y) tuong doi goc loi
#   placeInstance <ten_instance> <x> <y> MY          ;# dat 1 SRAM
#   selectInst <ten>; flipOrRotateObject -flip MY    ;# lat SRAM dang chon
#   deselectAll
#   dbGet [dbGet -p top.insts.name <ten>].pt         ;# xem toa do goc
# Kiem tra bat ky luc nao (huong, nam trong loi, khe >= 4.32):
#   soc_check_macros ./reports/sram_macro_check.rpt
# Luu vi tri dang xep bat ky luc nao (KHOI 3 lan sau tu nap lai; KHOI 4 cung tu luu):
#   soc_save_sram_place                              ;# -> tcl/manual/soc_sram_place.tcl
#   file delete tcl/manual/soc_sram_place.tcl        ;# bo ban luu, KHOI 3 xep mam lai
# Quy tac:
#   - SRAM cung module nam cung cum; cum sat canh/goc; khong de notch
#   - chan SRAM hai cot ke nhau quay vao nhau (mam: cot chan R0, cot le MY)
#   - cum CACHE/TAG sat vung logic giua (placer keo u_core/u_icache/u_dcache lai gan)


# ==========================================================================
# KHOI 4 - Chot SRAM: snap, kiem tra, FIXED   (Hierarchy trang 36, Macro trang 14)
# ==========================================================================
soc_block "KHOI 4: snap + FIXED + luu FloorPlan_withMacro.fp" {
    # Snap goc SRAM ve luoi site/row (thay refine_macro_place cua slide, lenh
    # do co the dich macro vua xep tay).
    foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
        foreach snapped [soc_snap_group $group] {
            lassign $snapped name ptr x y sx sy
            if {abs($sx - $x) > 1e-4 || abs($sy - $y) > 1e-4} {
                set orient [dbGet $ptr.orient]
                dbSet $ptr.pStatus unplaced
                placeInstance $name $sx $sy $orient
            }
        }
    }
    snapFPlan -block
    # Luu truoc khi kiem tra: check loi thi cong xep tay van con, sua roi chay lai.
    soc_save_sram_place

    set errors [soc_check_macros ./reports/sram_macro_check_final.rpt]
    if {[llength $errors] > 0} {
        foreach e [lrange $errors 0 19] {
            puts "ERROR: $e"
        }
        error "[llength $errors] loi vi tri SRAM - quay lai LAM TAY 1"
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
# KHOI 5 - Luoi nguon rieng TUNG cum SRAM   (Hierarchy trang 37-40)
# ==========================================================================
# Slide dung 'addRing -type block_rings -around shared_cluster' voi cum dang
# chon.  O day lenh do bao ca 84 SRAM va chi ra canh doc, nen thay bang
# addStripe theo vung (cach sram_axi da route sach), tinh tu toa do that cua
# tung cum - khong phu thuoc selection:
#   M4 ngang: mep duoi, moi khe giua hai hang, mep tren
#   M5 doc  : mep trai, moi khe giua hai cot, mep phai
#   M5 tap  : moi SRAM 1 cap o canh phai, noi chan PG M4 cua SRAM xuong khe
# Chi lam SAU KHOI 4 (SRAM da FIXED).
soc_block "KHOI 5: luoi nguon M4/M5 cho tung cum SRAM" {
    set unfixed 0
    foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
        foreach record [soc_group_records $group] {
            if {[dbGet [lindex $record 1].pStatus] ne "fixed"} {
                incr unfixed
            }
        }
    }
    if {$unfixed > 0} {
        error "$unfixed SRAM chua FIXED - chay KHOI 4 truoc"
    }
    # Xoa ket qua lan truoc (block ring cu + stripe M4/M5); ring loi M8/M9 van con.
    editDelete -shape BLOCKRING
    editDelete -layer M4 -shape STRIPE
    editDelete -layer M5 -shape STRIPE
    # Cum = cac SRAM nam sat nhau tren layout (< 2 khe), khong theo ten nhom
    set SOC_SRAM_BOXES [soc_sram_boxes]
    set SOC_ISLANDS [soc_sram_islands $SOC_SRAM_BOXES]
    puts "[llength $SOC_SRAM_BOXES] SRAM -> [llength $SOC_ISLANDS] cum"
    foreach island $SOC_ISLANDS {
        soc_island_pg $island $SOC_SRAM_BOXES
    }
    editTrim -nets {VSS VDD}
}

# --------------------------------------------------------------------------
# [LAM TAY 2 - tuy chon] Xem luoi nguon cum SRAM   (Hierarchy trang 39-40)
# --------------------------------------------------------------------------
# GUI:
#   - Panel Layer: chi bat M4, M5 (va Instance) de nhin.
#   - Zoom vao khe giua hai SRAM: phai thay 1 cap VSS/VDD - khe ngang la M4,
#     khe doc la M5; bon mep moi cum cung co 1 cap; giua hai cum KHONG co day.
#   - Canh phai moi SRAM co 1 cap M5 ngan (tap) chui tu khe ben duoi len.
# Neu da doi vi tri SRAM: paste lai KHOI 4 roi KHOI 5 (khoi 5 tu xoa M4/M5 cu).
# Hai SRAM cach nhau < 8.64 um (2 khe) duoc tinh chung mot cum; muon tach cum
# thi keo xa hon 8.64 um.


# ==========================================================================
# KHOI 6 - Luoi nguon toan chip M7/M6   (Hierarchy trang 41)
# ==========================================================================
# Chan PG cua SRAM da duoc tap M5 o KHOI 5 noi vao luoi cum, nen khong con
# 'sroute -connect blockPin' (sram_axi: nearestTarget noi bua thanh M4 va de ho
# hang duoi).  M6 ngang via xuong M5 cua cum SRAM; M7 doc via len ring M8.
# Neu paste lai KHOI 5 thi phai paste lai khoi nay.
soc_block "KHOI 6: luoi M7/M6" {
    editDelete -layer M6 -shape STRIPE
    editDelete -layer M7 -shape STRIPE
    soc_add_mesh
    editTrim -nets {VDD VSS}
}
# GUI: panel Layer, bat/tat M6, M7 de nhin luoi.


# ==========================================================================
# KHOI 7 - Placement blockage quanh SRAM + pin   (Hierarchy trang 38, 9-10)
# ==========================================================================
soc_block "KHOI 7: blockage + pin" {
    # Rong hon halo 1 row de phu ca canh ngoai cua block ring.
    set blk [expr {($SOC_HALO_ROWS + 1) * $SOC_ROW_H}]
    createPlaceBlockage -allMacro -snapToSite -outerRingBySide [list $blk $blk $blk $blk]

    setPinConstraint -cell $TOP -corner_to_pin_distance 8
    source ./tcl/manual/soc_pins.tcl
}
# [LAM TAY - tuy chon] Doi canh pin: sua 4 danh sach trong tcl/manual/soc_pins.tcl
# roi paste lai 'source ./tcl/manual/soc_pins.tcl'.  GUI: Edit > Pin Editor.


# ==========================================================================
# KHOI 8 - Kiem tra + luu (truoc placement)
# ==========================================================================
soc_block "KHOI 8: verify + saveDesign" {
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
# Luon paste KHOI 0 truoc.  saveFPlan khong giu ring/stripe, nen sau
# loadFPlan phai paste lai KHOI 2 (ring loi).
#
# a) Da co loi (sau KHOI 1), lam lai SRAM:
#   loadFPlan ./outputs/FloorPlan.fp
#   -> paste KHOI 2, KHOI 3, LAM TAY 1, KHOI 4 ...
#   Neu co tcl/manual/soc_sram_place.tcl thi KHOI 3 nap vi tri da xep tay,
#   khong can LAM TAY 1 nua: KHOI 0 -> 1 -> 2 -> 3 -> 4.
#
# b) SRAM da FIXED (sau KHOI 4), lam lai power grid:
#   loadFPlan ./outputs/FloorPlan_withMacro.fp
#   -> paste KHOI 2, 5, 6, 7, 8
#
# c) Chi mo lai ket qua da luu de xem:
#   restoreDesign ./saved/top_soc_powerplan.enc.dat top_soc
