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
    # floorPlan -s ve lai row/track.  Tren thiet ke da place/route thi no pha
    # nat hinh hoc (run 2026-09-21: drc_powerplan 0 -> 500000).
    soc_require_fresh_design "KHOI 1 (floorPlan)"
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
    # Ring phai co TRUOC luoi M6/M7 (KHOI 6 tao via M7-M8 luc addStripe).
    # Khong dung deleteAllPowerPreroutes: paste lai khoi nay sau KHOI 5/6 se
    # xoa sach luoi ma khong bao gi.
    set stripes [dbGet -e top.nets.sWires.shape stripe]
    if {[llength $stripes] > 0} {
        error "Da co [llength $stripes] stripe - ring phai lam truoc KHOI 5/6.  Chay lai tu KHOI 0 theo thu tu 0-1-2-3-4-5-6-7-8"
    }
    editDelete -shape RING
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
    soc_check_core_ring
    # Chan PG VDD/VSS (createPGPin) KHONG tao o day ma o KHOI 16: run 2026-09-17
    # 21:42 tao chan phu doan ring M8 tren o khoi nay, editTrim cua KHOI 5 xoa
    # mat doan ring do (KHOI 8: "Ring loi VDD thieu (M8=1 M9=2)").
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
#     RIENG tuong RAM_LO/RAM_HI: khe cot 0|1 va cot 2|3 la kenh buffer 17.28
#     (SOC_WALL_CHANNEL) - khong keo sat lai 4.32, CTS can row trong kenh de
#     dat buffer cho chan clk SRAM (run 2026-09-17: slew 172 ps khi khong co kenh).
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
    soc_check_core_ring
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
    soc_check_core_ring
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
    # verifyConnectivity van sach khi thieu ring (M6/M7 tu noi voi nhau) -> dem rieng.
    soc_check_core_ring
    clearDrc
    verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
        -error 100000 -warning 1000 \
        -report ./verify_rpt/connectivity_powerplan.rpt
    set soc_drc_pg [soc_verify_drc ./verify_rpt/drc_powerplan.rpt -limit 500000]
    checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_powerplan.rpt
    report_clocks > ./reports/clocks_floorplan.rpt
    report_analysis_views > ./reports/analysis_views.rpt
    # CONG: 0 vi pham.  Truoc 2026-09-21 cho nay chi IN ra con so roi di tiep,
    # dung nhu banner ngay duoi viet "phai 0 vi pham PG" nhung khong ai chan.
    # Run 03:42 co 357126 vi pham NGAY O DAY va van sang KHOI 9-13, chay them
    # 3 tieng; run 06:27 cham tran 500000.  Luoi nguon la hinh hoc thuan: con
    # vi pham la floorplan/stripe sai, khong co gi o sau don duoc.
    # Chan TRUOC saveDesign de khong ghi de checkpoint powerplan tot bang mot
    # cai hong; bao cao o tren van duoc viet ra de con doc nguyen nhan.
    if {$soc_drc_pg > 0} {
        error "$soc_drc_pg vi pham DRC o luoi nguon - xem verify_rpt/drc_powerplan.rpt.
  KHONG chay KHOI 9: placement, CTS va route deu se chay tren hinh hoc sai."
    }
    saveDesign ./saved/${TOP}_powerplan.enc

    soc_banner "FLOORPLAN + POWER GRID XONG - saved/${TOP}_powerplan.enc
  verify_rpt/connectivity_powerplan.rpt : moi SRAM phai noi VDD/VSS
      (open o chan std cell la binh thuong - rail M1 chua lam)
  verify_rpt/drc_powerplan.rpt          : phai 0 vi pham PG
  GUI: Tools > Violation Browser de xem tung loi
Tiep theo: KHOI 9 (placement), KHOI 10 (rail M1 + stripe M5 std cell)"
}


# ==========================================================================
# KHOI 9 - Placement std cell   (theo sram_axi/innovus_pnr.tcl da chay sach)
# ==========================================================================
# - Cat row trong cum SRAM + khe 4.32 quanh cum: khong std cell nao nam o noi
#   stripe M5 cua std cell khong toi duoc (luoi M4/M5 rieng cua cum nam trong khe).
# - Notch con row giua cac cum (hoc tren TAG, khe hep giua cum): blockage mem.
# - Path group cua Genus: Innovus khong doc group_path trong SDC cua constraint mode.
# - place_opt_design = place + toi uu preCTS; SRAM FIXED, khong refine macro.
soc_block "KHOI 9: placement" {
    soc_check_core_ring
    if {[llength [dbGet -e top.nets.sWires.shape stripe]] == 0} {
        error "Chua co luoi nguon - chay KHOI 5-8 truoc"
    }
    foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
        foreach record [soc_group_records $group] {
            if {[dbGet [lindex $record 1].pStatus] ne "fixed"} {
                error "[lindex $record 0] chua FIXED - chay KHOI 4 truoc"
            }
        }
    }

    if {[llength [dbGet -e top.insts.cell.name $SOC_TAP_CELL]] > 0} {
        error "Da co tap cell - KHOI 9 da chay.  restoreDesign ./saved/${TOP}_powerplan.enc.dat $TOP roi chay lai"
    }

    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx0 cy0 cx1 cy1
    foreach box [soc_sram_no_std_boxes] {
        lassign $box x0 y0 x1 y1
        # cutRow chi co nghia trong loi
        cutRow -area [list [expr {max($x0, $cx0)}] [expr {max($y0, $cy0)}] \
            [expr {min($x1, $cx1)}] [expr {min($y1, $cy1)}]]
    }
    # Tap cell (10_Macro tr.21, deck ACTIVE.LUP.1) - sau cutRow de moi doan row
    # con lai deu co tap, truoc blockage notch de tap vao ca kenh hep.
    addWellTap -cell $SOC_TAP_CELL -cellInterval $SOC_TAP_INTERVAL \
        -inRowOffset $SOC_TAP_OFFSET -prefix WELLTAP
    soc_global_pg_connect
    puts "Tap cell: [llength [dbGet -e top.insts.cell.name $SOC_TAP_CELL]] $SOC_TAP_CELL"
    # Notch giua cac cum SRAM (10_Macro Priority 7): blockage MEM, placer khong
    # dat logic vao nhung CTS/optDesign van dat buffer (xem SOC_NOTCH_MAX_W).
    foreach box [soc_notch_boxes] {
        lassign $box x0 y0 x1 y1
        puts [format "Notch %8.3f %8.3f %8.3f %8.3f  (%.2f x %.2f um)" \
            $x0 $y0 $x1 $y1 [expr {$x1 - $x0}] [expr {$y1 - $y0}]]
        createPlaceBlockage -type soft -box $box -name soc_notch
    }

    # LUU Y khi doc bang tom tat sau nay: nhom nay CHI con paths o buoc preCTS.
    # Tu optDesign -postCTS tro di Innovus tu tao nhom co ban reg2reg /
    # reg2cgate va chung uu tien hon, nen 14 cot cg_enable_group_CLK_* trong
    # postCTS.summary / final.summary deu la N/A.  Khong mat duong nao: run
    # 2026-09-20 preCTS co 1623 duong trong 14 nhom do, postRoute co dung 1635
    # duong trong reg2cgate (1623 ICG + 12 cg_* roi).  N/A o day nghia la
    # "nhom rong", khong phai "khong co du lieu".
    if {[file isfile $INNOVUS_PATH_GROUPS]} {
        puts "Doc path group: $INNOVUS_PATH_GROUPS"
        source $INNOVUS_PATH_GROUPS
    } else {
        puts "WARNING: khong co $INNOVUS_PATH_GROUPS - chay khong path group cua Genus"
    }

    setDelayCalMode -SIAware false -equivalent_waveform_model none
    # Mac dinh optDesign KHONG sua max_fanout: run 2026-09-17 con 1684 net > 20
    # (ke ca buffer FE_OFN* do chinh place_opt chen vao, fanout 65-75).
    setOptMode -fixFanoutLoad true
    setPlaceMode -reset
    setPlaceMode \
        -place_global_uniform_density false \
        -place_global_module_aware_spare true \
        -place_global_auto_blockage_in_channel soft \
        -place_detail_preroute_as_obs {2 3} \
        -place_global_cong_effort high \
        -place_global_reorder_scan false \
        -place_design_refine_macro false

    place_opt_design
    # Hang so 1'b0/1'b1 trong netlist -> cell TIE sat chan dung no
    setTieHiLoMode -reset
    setTieHiLoMode -cell {TIEHIx1_ASAP7_75t_R TIELOx1_ASAP7_75t_R} -maxFanout 8
    addTieHiLo
    refinePlace

    checkPlace ./verify_rpt/checkPlace_place.rpt
    checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_place.rpt
    # Mat do THAT dat duoc so voi MCU_TARGET_STD_UTIL.  Truoc 2026-09-20 bien do
    # chi dung de TINH kich thuoc loi (soc_fp_procs.tcl, nhanh logic cua
    # max(...)) roi khong ai so lai: run 2026-09-20 dat 0.239 trong khi target
    # la 0.55 - hai tuong RAM cao 1412.6 um thang nhanh logic (~465 um) nen
    # vung logic duoc cap gap ~2.3 lan dien tich no can.  Hierarchy tr.28 dat
    # nguong "<80%, ~75% la tot nhat"; script mau cua thay dat Density 0.70.
    # Mat do thap khong chan flow (thiet ke van chay dung) nhung no la goc cua
    # day dai hau qua: day dai, 6 chan clk SRAM vuot slew, va metal fill phai
    # ganh gan nhu toan bo die.  CHI CANH BAO - sua la viec cua floorplan.
    if {[catch {
        set fp [open ./verify_rpt/reportUtil_place.rpt r]
        set rpt [read $fp]
        close $fp
        # [0-9.]+ an ca DAU CHAM KET CAU o cuoi cau: reportUtil in ra
        # "Density for the design = 0.239." nen bat duoc "0.239." va format
        # %.3f nem loi - run 2026-09-21 17:28 mat luon canh bao mat do thap
        # ("khong doc duoc mat do tu reportUtil_place.rpt: expected
        # floating-point number but got 0.239.").  Khong lay dau cham cuoi.
        if {[regexp {Density for the design\s*=\s*([0-9]*\.?[0-9]+)} $rpt -> soc_util]} {
            set soc_want $::MCU_TARGET_STD_UTIL
            puts [format "Mat do std cell dat duoc: %.3f (target MCU_TARGET_STD_UTIL %.3f)" \
                $soc_util $soc_want]
            if {$soc_util < 0.8 * $soc_want} {
                puts [format "WARNING: mat do %.3f chi bang %.0f%% target %.3f - loi\
 dang bi keo cao qua muc (tuong SRAM quyet dinh chieu cao, khong phai logic).\
 Xem soc_layout trong soc_fp_procs.tcl." \
                    $soc_util [expr {100.0 * $soc_util / $soc_want}] $soc_want]
            }
        }
    } soc_util_err]} {
        puts "WARNING: khong doc duoc mat do tu reportUtil_place.rpt: $soc_util_err"
    }
    timeDesign -preCTS -outDir ./reports/timing_preCTS -prefix place
    # Truoc CTS clock con ly tuong nen chi canh bao: WNS am o day thuong la
    # thieu cho chu khong phai loi that.  DRV max_tran con lai se do CTS +
    # optDesign postCTS don.
    soc_check_timing ./reports/timing_preCTS place -warn-only
    report_area > ./reports/area_place.rpt
    saveDesign ./saved/${TOP}_placed.enc
}
# GUI: bat Instance, tat cac layer PG de nhin phan bo std cell; Place > Display >
# Density Map / Route > Congestion de xem vung ket.
# Xem: verify_rpt/checkPlace_place.rpt (phai 0 overlap / 0 unplaced),
#      reports/timing_preCTS/place*.summary (WNS/TNS setup truoc CTS).


# ==========================================================================
# KHOI 10 - Rail M1 + stripe M5 cho std cell   (sau placement, nhu Risc_V)
# ==========================================================================
# Chi chay MOT lan tren design vua place: stripe M5 cua std cell va cua cum SRAM
# cung shape STRIPE nen khong xoa rieng duoc.  Chay lai thi restoreDesign
# saved/top_soc_placed.enc.dat roi paste lai khoi nay.
soc_block "KHOI 10: rail M1 + stripe M5 std cell" {
    if {[llength [dbGet -e top.nets.sWires.shape followpin]] > 0} {
        error "Da co followpin - KHOI 10 da chay.  restoreDesign ./saved/${TOP}_placed.enc.dat $TOP roi chay lai"
    }
    soc_stdcell_rails

    clearDrc
    verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
        -error 100000 -warning 1000 \
        -report ./verify_rpt/connectivity_place.rpt
    set soc_drc_place [soc_verify_drc ./verify_rpt/drc_place.rpt -limit 500000]
    checkPlace ./verify_rpt/checkPlace_place_pg.rpt
    # Rail ho thi dung o day, khong luu placed_pg.  Run 2026-09-17 22:13: tech LEF
    # bat LEF58_ENCLOSURE o V3/V4 -> via M1->M5 chi con 3/8 (moi rail VSS + rail VDD
    # y = 9.936 + 8.64k khong via) -> 4562 loi ma van luu checkpoint va sang CTS.
    set opens [soc_connectivity_problems ./verify_rpt/connectivity_place.rpt]
    if {$opens > 0} {
        error "$opens loi VDD/VSS trong verify_rpt/connectivity_place.rpt (rail M1 khong noi stripe M5) - kiem tra LEF58_ENCLOSURE V3/V4 trong tech LEF.  Sua xong: restoreDesign ./saved/${TOP}_placed.enc.dat $TOP, source 3 file, paste lai KHOI 10"
    }
    # Cong DRC, cung ly do voi KHOI 8: run 2026-09-21 03:42 co 415202 vi pham
    # o day va van chay tiep CTS + route.
    if {$soc_drc_place > 0} {
        error "$soc_drc_place vi pham DRC sau rail M1 + stripe M5 - xem\
 verify_rpt/drc_place.rpt.  Sua xong: restoreDesign\
 ./saved/${TOP}_placed.enc.dat $TOP, source 3 file, paste lai KHOI 10."
    }
    saveDesign ./saved/${TOP}_placed_pg.enc

    soc_banner "PLACEMENT XONG - saved/${TOP}_placed_pg.enc
  verify_rpt/connectivity_place.rpt : phai 'Found no problems' (moi rail M1 co stripe M5)
  verify_rpt/drc_place.rpt          : phai 0 vi pham
  reports/timing_preCTS/            : WNS/TNS truoc CTS
Tiep theo: KHOI 11 (CTS)"
}


# ==========================================================================
# KHOI 11 - Clock tree synthesis   (theo sram_axi/innovus_pnr.tcl muc 3)
# ==========================================================================
# 15 clock (CLK_SYS, CLK_TCK, CLK_SDRAM_OUT + 12 clock gate) va ~1600 ICG.
# Chan clk cua SRAM gioi han transition 46 ps (Liberty) -> leaf 35 ps.
# Tren than SRAM khong dat duoc buffer: run 2026-09-17 tuong 4 cot khong kenh ->
# leaf dai ~440 um, 45 chan clk SRAM 57-172 ps.  Nay tuong co kenh buffer 17.28 um
# o khe cot 0|1, 2|3 (SOC_WALL_CHANNEL) -> chan clk cach row <= 65 um.
# Leaf cho len M5 (sram_axi: leaf M2/M3 -> 104 ps o chan clk SRAM).
soc_block "KHOI 11: CTS" {
    if {[llength [dbGet -e top.nets.sWires.shape followpin]] == 0} {
        error "Chua co rail M1 - chay KHOI 10 truoc"
    }
    foreach {rt bot top} {soc_leaf M3 M5 soc_trunk M5 M7 soc_top M6 M7} {
        # Paste lai khoi nay: route type da ton tai thi bo qua
        if {[catch {create_route_type -name $rt \
                -bottom_preferred_layer $bot -top_preferred_layer $top} err]} {
            puts "route_type $rt: $err"
        }
    }
    set_ccopt_property -net_type leaf  route_type soc_leaf
    set_ccopt_property -net_type trunk route_type soc_trunk
    set_ccopt_property -net_type top   route_type soc_top
    set_ccopt_property buffer_cells {
        BUFx4_ASAP7_75t_R BUFx8_ASAP7_75t_R BUFx10_ASAP7_75t_R BUFx12_ASAP7_75t_R
        BUFx12f_ASAP7_75t_R BUFx16f_ASAP7_75t_R BUFx24_ASAP7_75t_R
    }
    set_ccopt_property inverter_cells {
        CKINVDCx8_ASAP7_75t_R CKINVDCx12_ASAP7_75t_R CKINVDCx16_ASAP7_75t_R
    }
    set_ccopt_property use_inverters auto
    set_ccopt_property -net_type leaf  target_max_trans 35ps
    set_ccopt_property -net_type trunk target_max_trans 40ps
    set_ccopt_property -net_type top   target_max_trans 40ps
    set_ccopt_property target_skew 50ps

    # sram_axi: dung clock_opt_design, KHONG source ccopt.spec (IMPCCOPT-2048)
    clock_opt_design
    refinePlace
    checkPlace ./verify_rpt/checkPlace_cts.rpt

    # Sau CTS moi dung clock that (propagated)
    set_interactive_constraint_modes [all_constraint_modes -active]
    set_propagated_clock [all_clocks]
    set_interactive_constraint_modes {}

    report_ccopt_clock_trees -file ./reports/cts_clock_trees.rpt
    report_ccopt_skew_groups -file ./reports/cts_skew_groups.rpt
    timeDesign -postCTS -outDir ./reports/timing_postCTS_raw -prefix cts
    saveDesign ./saved/${TOP}_cts.enc
}
# Xem: reports/cts_skew_groups.rpt (skew tung clock), timing_postCTS_raw/cts.summary
# (max_tran o chan clk SRAM phai het).  GUI: Clock > CCOpt Clock Tree Debugger.


# ==========================================================================
# KHOI 12 - Toi uu sau CTS: setup + hold
# ==========================================================================
soc_block "KHOI 12: optDesign postCTS" {
    setOptMode -fixFanoutLoad true -fixTran true -fixCap true
    # -drv: KHONG bo di.  Ban cu chi ghi '-setup -hold', tuc noi voi optDesign
    # rang CHI lam hai viec do; setOptMode -fixTran/-fixCap o tren mo ra co che
    # sua DRV nhung khong duoc goi.  Run 2026-09-20 15:02 vi vay ma net n_21581
    # (INVx1 keo 16 chan D cua FIFO RX UART, tran 0.151 / gioi han 0.150 ns)
    # xuat hien ngay o postCTS roi di thang toi cuoi run ma khong ai sua.
    optDesign -postCTS -setup -hold -drv -prefix postCTS
    # 12 clock gate roi cg_* (latch + AND2): net latch->AND la clock net,
    # optDesign khong sua hold o do (run 2026-09-17: -120 ps postCTS)
    soc_fix_cg_hold 0.020
    checkPlace ./verify_rpt/checkPlace_postCTS.rpt
    timeDesign -postCTS       -outDir ./reports/timing_postCTS      -prefix postCTS
    timeDesign -postCTS -hold -outDir ./reports/timing_postCTS_hold -prefix postCTS
    # Doc lai chinh hai bang vua ghi.  Chi WARNING, khong chan: postRoute con
    # mot luot setup+hold+DRV nua.  Nhung phai IN RA - run 2026-09-20 den day
    # co hold WNS -0.001 / TNS -0.011 / 108 duong vi pham va DRV max_tran Real
    # 5 net, khong ai biet, KHOI 13 route thang.
    soc_check_timing ./reports/timing_postCTS      postCTS -drv   -warn-only
    soc_check_timing ./reports/timing_postCTS_hold postCTS -hold  -warn-only
    saveDesign ./saved/${TOP}_postCTS.enc
}
# Xem: timing_postCTS/postCTS.summary.gz va timing_postCTS_hold/postCTS_hold.summary.gz
# - WNS setup va hold phai >= 0, DRV "Real" = 0 truoc khi route.
# soc_check_timing o tren doc dung hai bang do va in ket luan ra console +
# logs/soc_flow.log.  Con WARNING thi van route duoc, nhung phai theo doi: neu
# postRoute khong don het thi KHOI 14/15 se DUNG han.


# ==========================================================================
# KHOI 13 - Route tin hieu   (M2-M7; M8/M9 danh cho ring)
# ==========================================================================
soc_block "KHOI 13: routeDesign" {
    # setAnalysisMode da chuyen len KHOI 0 (init_common.tcl) tu 2026-09-20:
    # dat o day thi CTS va ca optDesign -postCTS -hold chay trong "MMMC
    # Non-OCV" (doc innovus.log run 2026-09-20: moi header truoc dong
    # 'setAnalysisMode' o line 97801 deu ghi Non-OCV).  Khong co CPPR thi
    # duong hold bi tinh du phan clock dung chung -> hold-fix postCTS chen
    # thua buffer, va con so postCTS khong so sanh duoc voi postRoute.
    # Goi lai o day de paste rieng KHOI 13 van dung che do (lenh nay idempotent).
    setAnalysisMode -analysisType onChipVariation -cppr both
    setDelayCalMode -SIAware true -equivalent_waveform_model propagation
    setExtractRCMode -engine postRoute -effortLevel medium
    setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
    # Chan M3 tren than SRAM: tranh via V3 vao vung cam cua SRAM (run 2026-09-17:
    # 14 loi Cut Short V3 con lai sau ecoRoute -fix_drc).  Paste lai khoi nay:
    # xoa blockage cu truoc.
    catch {deleteRouteBlk -name soc_sram_m3}
    soc_sram_route_blk
    setNanoRouteMode -reset
    setNanoRouteMode \
        -route_with_timing_driven true \
        -route_with_si_driven true \
        -route_with_via_only_for_stdcell_pin true \
        -route_detail_fix_antenna true \
        -route_detail_end_iteration 20
    # Chan M4 cua SRAM lech track M4 (pitch 0.192, offset 0.012): 78/78 chan
    # signal cua srambank_256x4x32 co tam M4 mod 0.192 roi vao
    # {0.032 0.072 0.092 0.128 0.188}, khong cai nao = 0.012 -> KHONG vi tri dat
    # macro nao dua duoc chan len track.  Router vao chan bang V4 tu M5 thi
    # khong sao (verify_drc chi bat "Regular Wire", khong bat via), nhung neu no
    # chay them mot doan M4 tren dung cao do cua chan thi thanh OFFGRID.  Run
    # 2026-09-18 22:00 dinh dung mot ca: net u_itcm/u_mem/FE_OFN19657_n_271,
    # day M4 8.012 um o y 333.26 vao chan wd[26] cua
    # u_itcm/u_mem/G_SRAM_BANK[1].u_sram (track gan nhat 333.132 / 333.324).
    #
    # SUA LAI KET LUAN 2026-09-21.  Cho nay truoc ghi "ecoRoute -fix_drc khong
    # go duoc: ca 3 lan verify (route, postRoute, final) deu con dung mot loi
    # do".  Dung voi run 2026-09-18, KHONG con dung nua: run 2026-09-21
    # drc_route.rpt co 4 OFFGRID M4 (FE_OFN19666_n_276, FE_OFN19664_n_275,
    # FE_OFN34100_n, FE_OFN32560_n) nhung sau ecoRoute -fix_drc o KHOI 14 thi
    # drc_postRoute / drc_final / drc_fill deu "No DRC violations were found".
    # Vi the SOC_DRC_WAIVE_NETS da duoc de RONG (soc_fp_config.tcl): OFFGRID o
    # buoc nay la trang thai trung gian, khong phai thu can waive.
    #
    # DA THU, KHONG AN THUA (run 2026-09-19 03:20): setNanoRouteMode
    # -drouteOnGridOnly wire dat ngay day.  Innovus 23.14 NHAN option (khong bao
    # loi cu phap), route xong khong ho mach net tin hieu nao (connectivity chi
    # con 423 dangling M1 cua VDD/VSS, muc info), NHUNG doan day OFFGRID ra
    # GIONG HET tung chu so: cung net, cung bounds.  NanoRoute khong coi doan
    # vao chan macro la "day" nen knob do khong quan.  Dung dat lai.
    # -> Cach con lai: va tay tren checkpoint routed (xoa doan M4 + createRouteBlk
    #    M4 cuc bo -> ep router ha V4 tu M5 thang xuong chan), hoac waive vi ca 4
    #    toa do deu chia het MANUFACTURINGGRID 0.004 nen Calibre khong bat.
    routeDesign -globalDetail
    # DA THU VA DA GO 2026-09-21: them '-trackOpt' theo ban mau cua mon hoc.
    # Cung voi setGenerateViaMode -auto, run 09-21 02:21 ra 3 vi pham DRC o
    # postRoute (truoc do 0) -> KHOI 14/15 tat, metal fill khong chay.
    # Xem ghi chu trong init_common.tcl.
    routeDesign -viaOpt -wireOpt
    soc_verify_drc ./verify_rpt/drc_route.rpt -limit 500000
    # Bat ho mach ngay day, truoc khi optDesign/ecoRoute lam nhoe nguyen nhan:
    # sau route la luc duy nhat phan biet duoc "router bo net" voi "optDesign
    # doi netlist".
    # CACH DOC: chi quan tam net TIN HIEU.  Dangling wire tren VDD/VSS o layer
    # M1 la BINH THUONG o buoc nay - rail nguon cua hang std cell con ho o cho
    # chua co filler.  Run 2026-09-19 16:20: 423 dangling, 230 VDD + 193 VSS,
    # khong mot net tin hieu nao; deu la muc info (IMPVFC-94), khong phai
    # error/warning.  addFiller + soc_global_pg_connect o KHOI 15 noi chung lai:
    # connectivity_final.rpt cung lenh nay ra "Found no problems or warnings".
    # -> Chi dung flow khi co net tin hieu trong bao cao.
    verifyConnectivity -type all -error 1000 -warning 1000 \
        -report ./verify_rpt/connectivity_route.rpt
    saveDesign ./saved/${TOP}_routed.enc
}
# Xem: verify_rpt/drc_route.rpt va verify_rpt/connectivity_route.rpt.
#   con DRC        -> ecoRoute -fix_drc o KHOI 14 roi verify_drc lai.
#   con OFFGRID    -> binh thuong o buoc nay (chan M4 SRAM lech track, xem ghi
#                     chu o tren): ecoRoute -fix_drc o KHOI 14 go het.  Chi khi
#                     drc_postRoute.rpt VAN con thi moi la loi that.
#   dangling VDD/VSS tren M1 la muc info (IMPVFC-94), khong chan flow.


# ==========================================================================
# KHOI 14 - Toi uu sau route: setup + hold + DRV
# ==========================================================================
soc_block "KHOI 14: optDesign postRoute" {
    setOptMode -fixCap true -fixTran true -fixFanoutLoad true \
        -setupTargetSlack 0.020 -holdTargetSlack 0.020
    # Xoa doan day treo sau route (09_PnR tr.25) truoc khi toi uu
    deleteDanglingNet
    # Run 2026-09-20: "dangling nets: 5878 / Removed: 8" - 5870 net con lai
    # KHONG xoa duoc va log khong noi vi sao.  Chinh Innovus goi y lenh duoi
    # day; ghi ra file de con doc lai (phan lon la net cua macro/PG, nhung
    # phai nhin moi biet chac).
    if {[catch {reportDanglingNet -outfile ./reports/dangling_net.rpt} dn_err]} {
        puts "WARNING: reportDanglingNet: $dn_err"
    } else {
        puts "Net treo con lai: xem reports/dangling_net.rpt"
    }
    # -drv nhu KHOI 12: day la luot toi uu CUOI CUNG cua ca flow, KHOI 15 chi
    # them filler + metal fill chu khong sua duoc DRV nua.  Thieu -drv thi 1 net
    # max_tran cua postCTS di nguyen sang GDS (run 2026-09-20: n_21581, -1 ps).
    optDesign -postRoute -setup -hold -drv -prefix postRoute
    # Hold clock gate roi cg_* (xem KHOI 12) tinh lai voi RC that; buffer moi
    # chua co day -> ecoRoute
    soc_fix_cg_hold 0.020
    ecoRoute
    ecoRoute -fix_drc
    # DO TIMING TRUOC, VERIFY DRC SAU (doi thu tu 2026-09-21).  optDesign o
    # tren chay TRUOC soc_fix_cg_hold/ecoRoute, nen so DRV trong bang tom tat
    # duoi day la so CHUA TUNG duoc toi uu - va truoc day khong con luot nao
    # de sua no.  Run 2026-09-21 18:09 dung dung o cho do:
    #     max_tran Real 1 net: u_apb_cordic_state[0] (-0.001 ns)
    # phai go tay roi paste lai ca khoi moi qua.
    timeDesign -postRoute       -outDir ./reports/timing_postRoute      -prefix postRoute
    # Vong tu sua DRV: con vi pham THAT thi chay them optDesign -postRoute -drv
    # + ecoRoute roi do lai, toi da 2 vong (xem soc_fix_drv).  Sach san thi
    # khong ton mot lenh nao.  Hong o bat cu buoc nao cung chi in WARNING: cong
    # soc_check_timing -drv o cuoi khoi van chan y nhu cu, nen truong hop xau
    # nhat bang dung hien trang chu khong te hon.
    soc_fix_drv ./reports/timing_postRoute postRoute
    timeDesign -postRoute -hold -outDir ./reports/timing_postRoute_hold -prefix postRoute
    # optDesign/ecoRoute doi day va chen cell -> phai kiem tra lai DRC o day.
    # PHAI nam SAU soc_fix_drv: no cung chay optDesign + ecoRoute, verify truoc
    # no thi bao cao DRC khong con ta trang thai cuoi cung cua khoi.
    # Truoc 2026-09-18 khoi nay khong verify: DRC ke tiep la drc_final (sau metal
    # fill), va fill lech track da nhan chim bao cao do.  Day moi la so DRC that
    # cua design.
    set soc_drc_postroute [soc_verify_drc ./verify_rpt/drc_postRoute.rpt -limit 500000 -allow-nets $SOC_DRC_WAIVE_NETS -allow-types $SOC_DRC_WAIVE_TYPES]
    if {$soc_drc_postroute > 0} {
        error "Con $soc_drc_postroute vi pham DRC sau ecoRoute - xem verify_rpt/drc_postRoute.rpt truoc khi sang KHOI 15"
    }
    # LUU TRUOC, CHAN SAU.  Cong o duoi co the dung khoi, va soc_block chet la
    # chet ca khoi - de saveDesign phia sau thi mat luon checkpoint cua chinh
    # trang thai vua mat 10 phut toi uu, phai chay lai tu top_soc_routed.
    saveDesign ./saved/${TOP}_postRoute.enc
    # Day la buoc toi uu CUOI (KHOI 15 chi them filler + metal fill) nen o day
    # van chan cung: dung truoc KHOI 15 thi con sua duoc, de lot qua thi KHOI 15
    # da do filler + metal fill len roi, muon sua phai restore.
    # Khac voi KHOI 15: paste lai KHOI 14 vo hai (optDesign chay lai duoc).
    soc_check_timing ./reports/timing_postRoute      postRoute -drv
    soc_check_timing ./reports/timing_postRoute_hold postRoute -hold
}


# ==========================================================================
# KHOI 15 - Filler + kiem tra cuoi
# ==========================================================================
# Filler them SAU moi buoc toi uu (sram_axi: filler som lam row day 100%, het
# cho chen buffer sua hold).
#
# THU TU (doi 2026-09-18).  Truoc day: filler -> metal fill -> verify_drc.  Metal
# fill lech track sinh 100000 OFFGRID, verify_drc cham -limit va dung giua chung
# (IMPVFG-1103) -> bao cao DRC cuoi cung vo nghia, khong biet co DRC that bi che.
# Nay tach lam hai lan do:
#   drc_final.rpt : design THAT (filler, chua co metal fill) - phai 0
#   drc_fill.rpt  : sau metal fill - phai 0 ke ca tren net _FILLS_RESERVED
# Checkpoint _prefill.enc luu truoc metal fill: chinh so fill trong
# soc_fp_config.tcl roi restore tu day, khong phai chay lai ca run 14 tieng.
soc_block "KHOI 15: filler + verify" {
    set fillers $SOC_FILLER_CELLS
    puts "Filler cell: $fillers"
    setFillerMode -reset
    setFillerMode -core $fillers -add_fillers_with_drc false -fitGap true \
        -honorPrerouteAsObs true -diffCellViol true
    addFiller -cell $fillers -prefix FILLER -honorPrerouteAsObs true -diffCellViol true
    # Filler/buffer moi chen (CTS, optDesign, filler) phai noi chan VDD/VSS vao net
    soc_global_pg_connect
    checkPlace ./verify_rpt/checkPlace_final.rpt
    saveDesign ./saved/${TOP}_prefill.enc

    # --- 1. DRC cua design that (chua co metal fill) -----------------------
    set soc_drc_real [soc_verify_drc ./verify_rpt/drc_final.rpt -limit 500000 -allow-nets $SOC_DRC_WAIVE_NETS -allow-types $SOC_DRC_WAIVE_TYPES]
    if {$soc_drc_real > 0} {
        error "Con $soc_drc_real vi pham DRC that - xem verify_rpt/drc_final.rpt"
    }
    verifyConnectivity -type all -error 1000 -warning 1000 \
        -report ./verify_rpt/connectivity_final.rpt
    # Moi std cell cach tap <= SOC_TAP_RULE (deck ACTIVE.LUP.1, LEF 4x).  Chua
    # chay thu tren Innovus 23.14: loi cu phap thi chi bao, khong dung khoi.
    if {[catch {verifyWellTap -cell $SOC_TAP_CELL -rule $SOC_TAP_RULE \
            -report ./verify_rpt/welltap_final.rpt} err]} {
        puts "WARNING: verifyWellTap: $err"
    }

    # --- 2. Metal fill roi DRC lai ----------------------------------------
    # soc_metal_fill chi IN bao cao on-track, khong chan nua (2026-09-20): dieu
    # kien boi-pitch cu vua khong du vua khong can - xem soc_fill_check_track.
    soc_metal_fill
    # Doc lai bao cao cua chinh addMetalFill.  Truoc 2026-09-20 khong ai doc
    # file nay, nen M2 118 / M4 38 / M6 8 window duoi nguong va M3 297 window
    # vuot tran KHONG BAO GIO ra man hinh: flow ket luan sach trong khi anh
    # chup layout thi khong.  Canh bao, khong chan - xem soc_fill_report.
    soc_fill_report ./${TOP}.metalfill.rpt ./verify_rpt/fill_summary.rpt
    # 2026-09-20: OFFGRID cua _FILLS_RESERVED KHONG con duoc waive.  Bo so fill
    # moi (maxWidth 1.248 + decrement 0.384, theo sram_axi) khien da so mieng
    # rong hon min width nen khong dinh M5.AUX.2.  Con OFFGRID tren fill nghia
    # la fill VAN sai -> phai dung lai chu khong waive.
    set soc_drc_fill [soc_verify_drc ./verify_rpt/drc_fill.rpt -limit 500000 -allow-nets $SOC_DRC_WAIVE_FILL_NETS -allow-types $SOC_DRC_WAIVE_TYPES]
    if {$soc_drc_fill > 0} {
        error "Metal fill sinh $soc_drc_fill vi pham DRC - xem\
verify_rpt/drc_fill.rpt.  Sua so trong SOC_FILL_LAYERS roi restore\
saved/${TOP}_prefill.enc.dat, khong can chay lai tu dau."
    }
    # Luat mat do chi co o layer trong SOC_DENSITY_LAYERS: tech LEF khai
    # MINIMUMDENSITY o M5 (15%) va Pad (20%), khong co layer nao khac.  Layer
    # con lai Innovus ap mac dinh 20% - run 2026-09-18 co 8863 vi pham mat do,
    # 7719 trong so do la cua luat KHONG ton tai trong PDK nay.
    # Chua thu -layer tren Innovus 23.14: loi thi chay ban day du.
    if {[catch {verifyMetalDensity -layer $SOC_DENSITY_LAYERS \
            -report ./verify_rpt/density_final.rpt} err]} {
        puts "verifyMetalDensity -layer: $err"
        if {[catch {verifyMetalDensity \
                -report ./verify_rpt/density_final.rpt} err2]} {
            puts "WARNING: verifyMetalDensity: $err2"
        } else {
            puts "WARNING: density_final.rpt gom ca layer khong co\
MINIMUMDENSITY trong tech LEF - chi doc phan $SOC_DENSITY_LAYERS."
        }
    }
    # Doc lai bao cao: bo layer khong co luat, va tach window de len macro SRAM
    # (metal fill khong vao duoc do) khoi window vung logic - chi nhom sau moi
    # la loi cua metal fill.  Run 2026-09-18: 1144 tren macro, 0 vung logic.
    # 2026-09-20: gate that su, thay vi chi in ra man hinh.  CHI nhom "vung
    # logic" moi chan flow - do la phan metal fill dat duoc.  Nhom de len macro
    # SRAM khong ket luan duoc tu abstract (xem soc_density_report) nen chi ghi
    # trang thai PENDING_MERGED_GDS_SIGNOFF, giong sram_axi.
    set soc_density_logic [soc_density_report ./verify_rpt/density_final.rpt]
    if {$soc_density_logic > 0} {
        error "Metal fill de lai $soc_density_logic window vung logic duoi nguong\
 mat do - xem verify_rpt/density_summary.rpt.  Sua SOC_FILL_LAYERS roi restore\
 saved/${TOP}_prefill.enc.dat, khong can chay lai tu dau."
    }
    puts "  density signoff: $::SOC_DENSITY_SIGNOFF_STATUS"

    # --- 2b. Mat do TREN MOI LAYER DUOC FILL (bao cao, khong chan) ---------
    # verifyMetalDensity o tren chi chay tren SOC_DENSITY_LAYERS (M5) vi chi M5
    # va Pad co MINIMUMDENSITY that.  Nhung nhu vay khong co CACH NAO tra loi
    # "layer nao con thieu fill va thieu o dau": bao cao cua addMetalFill dem
    # duoc so window nhung khong co toa do, nen khong tach duoc window thap vi
    # de len macro SRAM (P&R khong sua duoc) khoi window thap that trong vung
    # logic.  Lan chay nay lam dung viec do cho ca SOC_DENSITY_REPORT_LAYERS.
    # Nguong cua layer ngoai M5/Pad la so tu dat trong SOC_FILL_LAYERS chu
    # khong phai luat foundry -> KHONG chan flow, chi de doc.
    if {[catch {verifyMetalDensity -layer $SOC_DENSITY_REPORT_LAYERS \
            -report ./verify_rpt/density_all.rpt} err]} {
        puts "WARNING: verifyMetalDensity -layer $SOC_DENSITY_REPORT_LAYERS: $err"
    } else {
        soc_density_report ./verify_rpt/density_all.rpt \
            -layers $SOC_DENSITY_REPORT_LAYERS -status 0 \
            -out ./verify_rpt/density_all_summary.rpt
    }
    saveDesign ./saved/${TOP}_final.enc

    # --- 3. Timing / power sau khi da co fill (fill lam tang C ghep) -------
    # Khong kiem tra antenna: tech LEF ASAP7 khong co luat antenna
    # (run 2026-09-17: verifyProcessAntenna -> ERROR IMPVPA-22).
    timeDesign -postRoute       -outDir ./reports/timing_final      -prefix final
    timeDesign -postRoute -hold -outDir ./reports/timing_final_hold -prefix final
    # CHI CANH BAO o day - cong CUNG nam o KHOI 16, canh soc_require_drc_clean.
    #
    # Ban dau hai dong nay la error.  Run 2026-09-20 15:27 dung dung o day vi 1
    # net max_tran lech 1 ps, va vi soc_block chet la chet ca khoi nen:
    #   - report_power / report_area / gateCount / summaryReport khong duoc sinh
    #   - banner khong in -> tren console loi hien ngay sau output cua metal
    #     fill, doc y nhu metal fill hong
    #   - ma KHOI 15 KHONG chay lai duoc: paste lai se addFiller lan hai va
    #     addMetalFill de len fill da co -> DRC/short that o metal fill
    # Cho nen: o day bao cao that day du, con viec CHAN xuat GDS de KHOI 16 lam,
    # dung cho ma DRC dang bi chan.  KHOI 16 chi doc file, paste lai vo hai.
    soc_check_timing ./reports/timing_final      final -drv  -warn-only
    soc_check_timing ./reports/timing_final_hold final -hold -warn-only
    # Slew chan clk SRAM nam o cot "Total" (remark C) nen cong o tren khong
    # bat; in rieng - day la cau hoi ma banner cuoi KHOI 15 van hoi bang tay.
    soc_sram_clk_slew ./reports/timing_final final
    # Mac dinh report_power lay view setup dau tien (view_ss 0.63 V); cong suat
    # danh nghia tinh o TT.  Chua co VCD: activity mac dinh 0.2.
    set_power_analysis_mode -analysis_view view_tt
    report_power -outfile ./reports/power_final.rpt
    soc_power_note ./reports/power_final.rpt
    report_area > ./reports/area_final.rpt
    reportGateCount -limit 0 -level 2 -outfile ./reports/gateCount.rpt
    summaryReport -noHtml -outfile ./reports/summary_final.rpt

    soc_banner "PNR XONG - saved/${TOP}_final.enc
  verify_rpt/drc_final.rpt           : DRC design that, phai 0
  verify_rpt/drc_fill.rpt            : DRC sau metal fill, phai 0
  verify_rpt/connectivity_final.rpt  : 0 open/short
  verify_rpt/welltap_final.rpt       : 0 cell xa tap qua ${SOC_TAP_RULE} um
  verify_rpt/density_final.rpt       : chi layer $SOC_DENSITY_LAYERS co luat
  verify_rpt/fill_summary.rpt        : so window duoi min / vuot max CUA
                                       TUNG layer sau addMetalFill
  verify_rpt/density_all_summary.rpt : cung so do nhung da tach macro SRAM
                                       / vung logic - vung logic phai 0
  reports/timing_final*/             : WNS setup/hold >= 0, DRV Real = 0
                                       (soc_check_timing o tren moi CANH BAO;
                                        KHOI 16 moi chan xuat GDS)
  reports/timing_final/final.tran.gz : slew chan clk SRAM - soc_sram_clk_slew
                                       da in so o tren, khong phai mo file
  reports/power_final.rpt            : can tren (chua co VCD), xem ghi chu
  logs/soc_flow.log                  : toan bo ket luan cua cac cong kiem tra
Tiep theo: KHOI 16 (xuat file)"
}


# ==========================================================================
# KHOI 16 - Xuat file cho STA / LEC / ve so do
# ==========================================================================
# (09_PnR tr.28) GDS: std cell merge tu GDS cua asap7sc7p5t_28 (STD_GDS_FILES);
# SRAM khong co GDS rieng tung macro -> -outputMacros ghi hinh chan tu LEF
# (LVS phai coi SRAM la hop den).
soc_block "KHOI 16: xuat netlist, SDF, SPEF, DEF, SDC, GDS, LEF" {
    foreach gds $STD_GDS_FILES {
        if {![file isfile $gds]} {
            error "Khong co GDS std cell $gds - dat ASAP7_RVT_GDS_FILE / ASAP7_LVT_GDS_FILE"
        }
    }
    # streamOut day het hinh hien co vao GDS, ke ca metal fill lech track.  Run
    # 2026-09-18 vao KHOI 16 voi 100000 OFFGRID chua ai doc -> chan o day.
    # Cung bo waiver voi KHOI 15 (soc_verify_drc).  Tu 2026-09-21 bo do RONG
    # (SOC_DRC_WAIVE_NETS = {}) nen MOI vi pham deu chan xuat GDS.  Hai tham so
    # van truyen vao de lan sau can waive thi chi sua soc_fp_config.tcl.
    soc_require_drc_clean -allow-nets $SOC_DRC_WAIVE_FILL_NETS \
        -allow-types $SOC_DRC_WAIVE_TYPES \
        ./verify_rpt/drc_final.rpt ./verify_rpt/drc_fill.rpt
    # CONG TIMING CUNG - chuyen tu cuoi KHOI 15 xuong day 2026-09-20.
    # Cung ly do voi soc_require_drc_clean: thu gi di vao GDS thi chan o cho
    # xuat GDS.  Hai lenh nay chi DOC bang tom tat cua timeDesign trong KHOI 15
    # (khong tinh lai gi) nen paste lai KHOI 16 bao nhieu lan cung vo hai - khac
    # han KHOI 15, noi addFiller/addMetalFill khong chay lai duoc.
    # Con vi pham -> sua roi chay lai tu saved/top_soc_prefill.enc.dat, DUNG
    # paste lai KHOI 15 tren database hien tai.
    soc_check_timing ./reports/timing_final      final -drv
    soc_check_timing ./reports/timing_final_hold final -hold
    # LEF SRAM lech manufacturing grid / SITE khong ton tai di thang vao GDS vi
    # -outputMacros lay hinh macro tu LEF (khong co GDS rieng cho SRAM).
    soc_require_sram_lef_clean
    soc_report_escaped_names ./reports/escaped_names.rpt
    extractRC
    foreach rc {rc_typ rc_ss rc_ff} {
        rcOut -spef ./outputs/${TOP}_pnr_${rc}.spef -rc_corner $rc
    }
    write_sdf -view view_ss ./outputs/${TOP}_pnr_ss.sdf
    write_sdf -view view_ff ./outputs/${TOP}_pnr_ff.sdf
    writeTimingCon ./outputs/${TOP}_pnr.sdc
    # Netlist mo phong / LEC; ban _pg co VDD/VSS + tap/filler cho LVS
    saveNetlist ./outputs/${TOP}_pnr.v -excludeLeafCell
    saveNetlist ./outputs/${TOP}_pnr_pg.v -includePowerGround -includePhysicalInst -excludeLeafCell
    # Chan PG VDD/VSS tren ring M8 (09_PnR tr.21) - sau moi lenh editTrim/sroute
    soc_add_pg_pins
    defOut -floorplan -netlist -routing ./outputs/${TOP}_pnr.def

    soc_write_gds_map ./outputs/${TOP}_gds.map
    setStreamOutMode -labelAllPinShape true -pinTextOrientation automatic \
        -virtualConnection false -textSize 1
    streamOut ./outputs/${TOP}.gds -mapFile ./outputs/${TOP}_gds.map \
        -merge $STD_GDS_FILES -units $SOC_GDS_UNITS \
        -dieAreaAsBoundary -outputMacros
    write_lef_abstract -noCutObs ./outputs/${TOP}.lef
}
# Kiem tra GDS (ngoai Innovus): mo outputs/top_soc.gds, do 1 WELLTAP_* phai
# rong 432 dbu va trung khit o dat trong DEF; log streamOut khong duoc bao
# cell nao thieu trong GDS merge ngoai 2 master SRAM.


# ==========================================================================
# CHAY LAI TU GIUA (session moi) - copy phan can dung, bo dau '#'
# ==========================================================================
# Luon paste KHOI 0 truoc.  saveFPlan khong giu ring/stripe, nen sau
# loadFPlan phai paste lai KHOI 2 (ring loi).
# Checkpoint luu truoc 2026-09-17 toi chua co tap cell (KHOI 9, phai co truoc
# placement): restore top_soc_powerplan.enc.dat roi KHOI 9-16; hoac tu KHOI 0.
# Checkpoint cua run 21:42 (co chan PG tao o KHOI 2) da mat ring M8 -> KHOI 0.
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
#
# d) Da co power grid (sau KHOI 8), chay placement:
#   restoreDesign ./saved/top_soc_powerplan.enc.dat top_soc
#   source ./tcl/project_config.tcl
#   source ./tcl/manual/soc_fp_config.tcl
#   source ./tcl/manual/soc_fp_procs.tcl
#   -> paste KHOI 9, 10
#   (KHOI 10 hong: restoreDesign ./saved/top_soc_placed.enc.dat top_soc, source 3 file tren, paste KHOI 10)
#
# e) Tiep tu checkpoint sau placement tro di (moi lan: restoreDesign + source 3 file tren):
#   saved/top_soc_placed_pg.enc.dat -> KHOI 11
#   saved/top_soc_cts.enc.dat       -> KHOI 12
#   saved/top_soc_postCTS.enc.dat   -> KHOI 13
#   saved/top_soc_routed.enc.dat    -> KHOI 14
#   saved/top_soc_postRoute.enc.dat -> KHOI 15, 16
#   saved/top_soc_prefill.enc.dat   -> chi chay lai metal fill + verify cuoi
#     (filler da co, chua co metal fill): sua SOC_FILL_LAYERS roi paste
#     phan tu 'soc_metal_fill' den het KHOI 15.
#   Luu y: derate SRAM, set_max_fanout SRAM, dont_touch TRNG dat o KHOI 0; neu
#   report_timing_derate sau restore khong con x1.30/x0.75 thi source lai
#   ./tcl/init_common.tcl KHONG duoc (no goi init_design) - chay lai tu KHOI 0.
