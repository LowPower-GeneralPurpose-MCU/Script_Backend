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
    soc_verify_drc ./verify_rpt/drc_powerplan.rpt -limit 500000
    checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_powerplan.rpt
    report_clocks > ./reports/clocks_floorplan.rpt
    report_analysis_views > ./reports/analysis_views.rpt
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
    timeDesign -preCTS -outDir ./reports/timing_preCTS -prefix place
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
    soc_verify_drc ./verify_rpt/drc_place.rpt -limit 500000
    checkPlace ./verify_rpt/checkPlace_place_pg.rpt
    # Rail ho thi dung o day, khong luu placed_pg.  Run 2026-09-17 22:13: tech LEF
    # bat LEF58_ENCLOSURE o V3/V4 -> via M1->M5 chi con 3/8 (moi rail VSS + rail VDD
    # y = 9.936 + 8.64k khong via) -> 4562 loi ma van luu checkpoint va sang CTS.
    set opens [soc_connectivity_problems ./verify_rpt/connectivity_place.rpt]
    if {$opens > 0} {
        error "$opens loi VDD/VSS trong verify_rpt/connectivity_place.rpt (rail M1 khong noi stripe M5) - kiem tra LEF58_ENCLOSURE V3/V4 trong tech LEF.  Sua xong: restoreDesign ./saved/${TOP}_placed.enc.dat $TOP, source 3 file, paste lai KHOI 10"
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
    optDesign -postCTS -setup -hold -prefix postCTS
    # 12 clock gate roi cg_* (latch + AND2): net latch->AND la clock net,
    # optDesign khong sua hold o do (run 2026-09-17: -120 ps postCTS)
    soc_fix_cg_hold 0.020
    checkPlace ./verify_rpt/checkPlace_postCTS.rpt
    timeDesign -postCTS       -outDir ./reports/timing_postCTS      -prefix postCTS
    timeDesign -postCTS -hold -outDir ./reports/timing_postCTS_hold -prefix postCTS
    saveDesign ./saved/${TOP}_postCTS.enc
}
# Xem: timing_postCTS/postCTS.summary.gz va timing_postCTS_hold/postCTS_hold.summary.gz
# - WNS setup va hold phai >= 0, DRV "Real" = 0 truoc khi route.


# ==========================================================================
# KHOI 13 - Route tin hieu   (M2-M7; M8/M9 danh cho ring)
# ==========================================================================
soc_block "KHOI 13: routeDesign" {
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
    # ecoRoute -fix_drc khong go duoc: ca 3 lan verify (route, postRoute, final)
    # deu con dung mot loi do.
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
#   con OFFGRID    -> khong tu het duoc, xem ghi chu chan M4 SRAM o tren.
#   dangling VDD/VSS tren M1 la muc info (IMPVFC-94), khong chan flow.


# ==========================================================================
# KHOI 14 - Toi uu sau route: setup + hold + DRV
# ==========================================================================
soc_block "KHOI 14: optDesign postRoute" {
    setOptMode -fixCap true -fixTran true -fixFanoutLoad true \
        -setupTargetSlack 0.020 -holdTargetSlack 0.020
    # Xoa doan day treo sau route (09_PnR tr.25) truoc khi toi uu
    deleteDanglingNet
    optDesign -postRoute -setup -hold -prefix postRoute
    # Hold clock gate roi cg_* (xem KHOI 12) tinh lai voi RC that; buffer moi
    # chua co day -> ecoRoute
    soc_fix_cg_hold 0.020
    ecoRoute
    ecoRoute -fix_drc
    # optDesign/ecoRoute doi day va chen cell -> phai kiem tra lai DRC o day.
    # Truoc 2026-09-18 khoi nay khong verify: DRC ke tiep la drc_final (sau metal
    # fill), va fill lech track da nhan chim bao cao do.  Day moi la so DRC that
    # cua design.
    set soc_drc_postroute [soc_verify_drc ./verify_rpt/drc_postRoute.rpt -limit 500000 -allow-nets $SOC_DRC_WAIVE_NETS -allow-types $SOC_DRC_WAIVE_TYPES]
    if {$soc_drc_postroute > 0} {
        error "Con $soc_drc_postroute vi pham DRC sau ecoRoute - xem verify_rpt/drc_postRoute.rpt truoc khi sang KHOI 15"
    }
    timeDesign -postRoute       -outDir ./reports/timing_postRoute      -prefix postRoute
    timeDesign -postRoute -hold -outDir ./reports/timing_postRoute_hold -prefix postRoute
    saveDesign ./saved/${TOP}_postRoute.enc
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
    soc_density_report ./verify_rpt/density_final.rpt
    saveDesign ./saved/${TOP}_final.enc

    # --- 3. Timing / power sau khi da co fill (fill lam tang C ghep) -------
    # Khong kiem tra antenna: tech LEF ASAP7 khong co luat antenna
    # (run 2026-09-17: verifyProcessAntenna -> ERROR IMPVPA-22).
    timeDesign -postRoute       -outDir ./reports/timing_final      -prefix final
    timeDesign -postRoute -hold -outDir ./reports/timing_final_hold -prefix final
    # Mac dinh report_power lay view setup dau tien (view_ss 0.63 V); cong suat
    # danh nghia tinh o TT.  Chua co VCD: activity mac dinh 0.2.
    set_power_analysis_mode -analysis_view view_tt
    report_power -outfile ./reports/power_final.rpt
    report_area > ./reports/area_final.rpt
    reportGateCount -limit 0 -level 2 -outfile ./reports/gateCount.rpt
    summaryReport -noHtml -outfile ./reports/summary_final.rpt

    soc_banner "PNR XONG - saved/${TOP}_final.enc
  verify_rpt/drc_final.rpt           : DRC design that, phai 0
  verify_rpt/drc_fill.rpt            : DRC sau metal fill, phai 0
  verify_rpt/connectivity_final.rpt  : 0 open/short
  verify_rpt/welltap_final.rpt       : 0 cell xa tap qua ${SOC_TAP_RULE} um
  verify_rpt/density_final.rpt       : chi layer $SOC_DENSITY_LAYERS co luat
  reports/timing_final*/             : WNS setup/hold >= 0, DRV Real = 0
  reports/timing_final/final.tran.gz : con bao nhieu chan clk SRAM > 46 ps?
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
    # Cung bo waiver voi KHOI 15 (soc_verify_drc): OFFGRID cua _FILLS_RESERVED
    # va cua net SRAM trong SOC_DRC_WAIVE_NETS.  Moi loai khac - va moi net
    # khac - van chan xuat GDS.
    soc_require_drc_clean -allow-nets $SOC_DRC_WAIVE_FILL_NETS \
        -allow-types $SOC_DRC_WAIVE_TYPES \
        ./verify_rpt/drc_final.rpt ./verify_rpt/drc_fill.rpt
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
