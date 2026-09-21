############################################################
## Proc dung chung cho tcl/manual/innovus_soc.tcl
## Can soc_fp_config.tcl va project_config.tcl da source.
############################################################

# ==========================================================================
# GHI LAI MOI DONG SCRIPT IN RA          (them 2026-09-20)
# ==========================================================================
# innovus.log cua run 2026-09-20 (9 MB) KHONG chua mot dong nao do cac proc
# trong file nay in ra.  Da do thu: "Derate SRAM", "Tap cell", "Filler cell",
# "Analysis views", "Notch", "soc_fix_cg_hold", so vi pham DRC da waive, trang
# thai density signoff -> dem duoc 0 lan xuat hien.
#
# Ly do: cac khoi duoc paste vao console GUI.  Innovus ghi vao innovus.log cac
# dong <CMD> va message cua chinh no, con 'puts' cua Tcl di thang ra widget
# console va bien mat khi dong session.
#
# Hau qua that: TOAN BO ket luan cua cac cong kiem tra (soc_verify_drc dem bao
# nhieu vi pham da waive, soc_density_report ket luan PENDING hay FAIL,
# soc_fix_cg_hold con latch nao chua sua) khong con dau vet nao de doc lai.
# Do dung la thu can nhat khi doc log sau mot run 14 tieng.
#
# Boc lai 'puts': van in ra console y nhu cu, dong thoi noi them vao
# logs/soc_flow.log kem dau thoi gian.
#   - Chi boc MOT lan: soc_block goi soc_reload moi khoi nen file nay duoc
#     source lai rat nhieu lan, boc chong len nhau se lam log nhan doi.
#   - Chi tee dang 'puts <text>' (mot doi so).  'puts $fh <text>' cua chinh cac
#     proc o duoi la ghi BAO CAO ra file rieng, phai di nguyen ven.
#   - Moi thao tac file boc trong catch: log hong khong duoc phep lam hong run.
# ==========================================================================
set ::SOC_FLOW_LOG ./logs/soc_flow.log

proc soc_flow_log_write {text} {
    if {![info exists ::SOC_FLOW_LOG] || $::SOC_FLOW_LOG eq ""} {
        return
    }
    catch {
        file mkdir [file dirname $::SOC_FLOW_LOG]
        set fh [open $::SOC_FLOW_LOG a]
        # 2 doi so -> khong tee lai -> khong de quy
        puts -nonewline $fh $text
        close $fh
    }
}

# 'info commands' chu KHONG phai 'info procs': puts la lenh dung san cua Tcl,
# sau rename thi ::soc_puts_orig van khong phai proc nen 'info procs' luon tra
# ve rong -> lan source thu hai se rename de len va Tcl bao
# "can't rename to ::soc_puts_orig: command already exists" (thu 2026-09-20).
if {[llength [info commands ::soc_puts_orig]] == 0} {
    rename ::puts ::soc_puts_orig
    proc ::puts {args} {
        set argv $args
        set eol "\n"
        if {[lindex $argv 0] eq "-nonewline"} {
            set eol ""
            set argv [lrange $argv 1 end]
        }
        if {[llength $argv] == 1} {
            soc_flow_log_write "[clock format [clock seconds] -format {%m-%d %H:%M:%S}]\
 [lindex $argv 0]$eol"
        }
        eval [linsert $args 0 ::soc_puts_orig]
    }
    ::soc_puts_orig "soc_flow_log: moi dong script in ra duoc ghi them vao\
 $::SOC_FLOW_LOG"
}

proc soc_banner {text} {
    puts "============================================================"
    puts $text
    puts "============================================================"
}

# Chay mot khoi lenh o muc global.  Lenh nao loi thi ca khoi dung ngay, ke ca
# khi khoi duoc paste vao console (paste tung dong thi lenh sau van chay).
# Session Innovus chi source config/procs MOT LAN, o KHOI 0; moi khoi sau do
# chay ban da nam trong RAM.  Run 2026-09-18 mat ca run 14 tieng vi dieu nay: so
# metal fill duoc sua luc 14:02, KHOI 15 paste luc 15:05 van dung so cu ->
# 100000 OFFGRID.  Moi soc_block nap lai hai file truoc khi chay, nen sua file la
# co hieu luc ngay o khoi ke tiep.  Hai file nay chi co proc va set, khong co
# lenh Innovus nao, nen nap lai giua chung la an toan; cac bien duoc tinh luc
# chay (SOC_LAYOUT, SOC_CORE_RING_OFFSET, SOC_SRAM_BOXES, SOC_ISLANDS,
# SOC_STD_*) khong nam trong soc_fp_config.tcl nen khong bi ghi de.
proc soc_reload {} {
    foreach f {./tcl/manual/soc_fp_config.tcl ./tcl/manual/soc_fp_procs.tcl} {
        if {![file isfile $f]} {
            error "soc_reload: khong thay $f - phai cd vao .../mcu/innovus (dang o [pwd])"
        }
        uplevel #0 [list source $f]
    }
}

# Doc db an toan: tra ve "" khi khong khop, khong in message, khong nem loi.
# dbGet tra "0x0" khi khong co doi tuong nao khop - viet thanh "" cho de kiem.
proc soc_db_match {args} {
    set out ""
    catch {set out [eval [linsert $args 0 dbGet -e]]}
    if {$out eq "0x0" || $out eq "0"} {
        set out ""
    }
    return $out
}

# ==========================================================================
# CO "FLOW DANG HONG"                                  (them 2026-09-21)
# ==========================================================================
# soc_block chi dung duoc KHOI DANG chay; no khong ngan duoc lan paste ke
# tiep.  Run 2026-09-21 03:42: KHOI 10 dung vi 1826 loi VDD/VSS (dong error
# nam o innovus.log line 149795) nhung KHOI 11, 12, 13, 14, 15 van duoc paste
# tiep va chay them 3 tieng tren mot thiet ke da hong - ket qua la 407181 vi
# pham DRC o drc_final.
# Mot khoi loi -> dat co; moi khoi sau do tu choi chay cho den khi nguoi chay
# goi 'soc_flow_ok' (tuc la da doc loi va da xu ly).
# Khoi tao PHAI co dieu kien: soc_reload source lai file nay o dau moi khoi,
# 'set ::SOC_FLOW_BROKEN ""' vo dieu kien la tu xoa co ngay truoc khi kiem tra.
if {![info exists ::SOC_FLOW_BROKEN]} {
    set ::SOC_FLOW_BROKEN ""
}

proc soc_flow_ok {} {
    if {$::SOC_FLOW_BROKEN eq ""} {
        puts "soc_flow_ok: khong co co loi nao dang bat"
        return
    }
    puts "soc_flow_ok: go co loi \"$::SOC_FLOW_BROKEN\" - paste khoi tiep theo duoc"
    set ::SOC_FLOW_BROKEN ""
}

proc soc_block {title body} {
    # File loi cu phap thi dung o day, TRUOC khi chay lenh Innovus nao.
    soc_reload
    if {$::SOC_FLOW_BROKEN ne ""} {
        error "KHOI TRUOC DA LOI nen khong chay \"$title\".
  Loi do: $::SOC_FLOW_BROKEN
  Sua nguyen nhan (hoac restoreDesign checkpoint gan nhat) roi go co: soc_flow_ok"
    }
    soc_banner ">>> $title"
    set soc_rc [catch {uplevel #0 $body} soc_err soc_opts]
    if {$soc_rc} {
        set ::SOC_FLOW_BROKEN "$title: $soc_err"
        puts ">>> LOI: $title: $soc_err"
        return -options $soc_opts $soc_err
    }
    puts ">>> XONG: $title"
}

# ==========================================================================
# CHAN CHAY FLOORPLAN DE LEN MOT THIET KE DA P&R       (them 2026-09-21)
# ==========================================================================
# floorPlan -s ve lai die/core/row/track.  Tren netlist vua nap thi vo hai;
# tren thiet ke da place + CTS + route thi Innovus GIU nguyen cell va day roi
# ep chung vao he row moi - innovus.log run 2026-09-21 06:27 in hang chuc
# nghin dong "Flip instance ... to match row orient".  Day cu thanh lech
# track, SRAM duoc dat lai cho khac trong khi day cu van nam do, addStripe
# chong len luoi nguon cu:
#     loi cao       1412.64 -> 2459.16 -> 6162.48 um
#     drc_powerplan       0 -> 357126  -> 500000 (cham tran -limit)
#     drc_final           0 -> 407181
# init_common.tcl da chan tu KHOI 0; day la chan thu hai cho truong hop chi
# paste rieng KHOI 1 vao mot session dang co thiet ke.
proc soc_require_fresh_design {what} {
    set found {}
    foreach {label query} [list \
            "cell CTS"     {-p top.insts.name CTS_*} \
            "filler"       {-p top.insts.name FILLER*} \
            "tap cell"     {-p top.insts.name WELLTAP*} \
            "stripe nguon" {top.nets.sWires.shape stripe} \
            "rail M1"      {top.nets.sWires.shape followpin} \
            "cell da dat"  {-p top.insts.pStatus placed}] {
        set hit [eval [linsert $query 0 soc_db_match]]
        if {$hit ne ""} {
            lappend found "[llength $hit] $label"
        }
    }
    if {[llength $found] == 0} {
        return
    }
    error "$what tren mot thiet ke DA P&R ([join $found {, }]).
  Lam vay la ve lai row/track duoi day da route -> OFFGRID + SHORT hang tram
  nghin (run 2026-09-21: drc_powerplan tu 0 len 500000).
  Thoat Innovus roi mo lai de chay tu dau, hoac
  restoreDesign ./saved/<checkpoint>.enc.dat top_soc dung buoc muon chay tiep."
}

proc soc_snap_up {value grid} {
    return [expr {ceil(double($value) / $grid - 1e-9) * $grid}]
}

proc soc_snap_down {value grid} {
    return [expr {floor(double($value) / $grid + 1e-9) * $grid}]
}

proc soc_snap_near {value origin grid} {
    return [expr {$origin + round((double($value) - $origin) / $grid) * $grid}]
}

proc soc_master_name {kind} {
    switch -- $kind {
        big { return $::SRAM_MASTER }
        tag { return $::SRAM_TAG_MASTER }
    }
    error "Master '$kind' khong hop le (big|tag)"
}

# {name ptr} cua moi macro trong nhom, sap -dictionary de [10] sau [9].
proc soc_group_records {group} {
    foreach {name kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        if {$name ne $group} {
            continue
        }
        set records {}
        foreach ptr [dbGet -p2 top.insts.cell.name [soc_master_name $kind]] {
            # dbGet tra ve list: ten co [0] bi boc {...} neu khong lindex
            set inst [lindex [dbGet $ptr.name] 0]
            foreach prefix $prefixes {
                if {[string first $prefix $inst] == 0} {
                    lappend records [list $inst $ptr]
                    break
                }
            }
        }
        return [lsort -dictionary -index 0 $records]
    }
    error "Khong co nhom SRAM '$group' trong SOC_SRAM_GROUPS"
}

# Moi macro phai thuoc dung mot nhom, va tong phai du 80 + 4.
proc soc_check_groups {} {
    set seen [dict create]
    set total 0
    foreach {name kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        set records [soc_group_records $name]
        if {[llength $records] == 0} {
            error "Nhom $name khong co macro nao"
        }
        if {$cols * $rows < [llength $records]} {
            error "Nhom $name: luoi $cols x $rows khong du cho [llength $records] macro"
        }
        foreach record $records {
            set inst [lindex $record 0]
            if {[dict exists $seen $inst]} {
                error "Macro $inst nam trong ca [dict get $seen $inst] va $name"
            }
            dict set seen $inst $name
        }
        incr total [llength $records]
    }
    set expected [expr {$::SRAM_EXPECTED_COUNT + $::SRAM_TAG_EXPECTED_COUNT}]
    if {$total != $expected} {
        error "SOC_SRAM_GROUPS phu $total macro, netlist co $expected"
    }
}

proc soc_macro_size {kind} {
    set ptr [lindex [dbGet -p head.libCells.name [soc_master_name $kind]] 0]
    return [list [expr {double([dbGet $ptr.size_x])}] [expr {double([dbGet $ptr.size_y])}]]
}

# Khe giua cot col va col+1 cua nhom: kenh buffer SOC_WALL_CHANNEL o khe cot
# 0|1, 2|3... cua cac nhom trong SOC_WALL_CHANNEL_GROUPS, con lai SOC_MACRO_GAP.
proc soc_col_gap {group col} {
    if {$group in $::SOC_WALL_CHANNEL_GROUPS && $col % 2 == 0} {
        return $::SOC_WALL_CHANNEL
    }
    return $::SOC_MACRO_GAP
}

# Toa do x cot col so voi mep trai nhom (macro rong w).
proc soc_col_x {group col w} {
    set x 0.0
    for {set i 0} {$i < $col} {incr i} {
        set x [expr {$x + $w + [soc_col_gap $group $i]}]
    }
    return $x
}

# Kich thuoc mot cum khi xep cols x rows (khe SOC_MACRO_GAP, kenh soc_col_gap).
# Tra ve {cum_w cum_h macro_w macro_h so_hang}.
proc soc_group_dims {group} {
    foreach {name kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        if {$name ne $group} {
            continue
        }
        set count [llength [soc_group_records $name]]
        set used_rows [expr {min($rows, $count)}]
        set used_cols [expr {int(ceil(double($count) / $used_rows))}]
        lassign [soc_macro_size $kind] w h
        set gap $::SOC_MACRO_GAP
        return [list \
            [expr {[soc_col_x $name [expr {$used_cols - 1}] $w] + $w}] \
            [expr {$used_rows * $h + ($used_rows - 1) * $gap}] \
            $w $h $used_rows]
    }
    error "Khong co nhom SRAM '$group'"
}

# Dien tich std cell (khong tinh macro) theo instance cap 1.
# Cell do chinh P&R sinh ra, KHONG thuoc netlist tong hop.  Neu de chung vao
# tong dien tich thi soc_layout tinh ra mot loi to hon thuc te: run 2026-09-21
# 03:42 ra 1325493.2 um^2 va 06:27 ra 3675242.4 um^2 trong khi netlist chi co
# 300143.6 um^2 (logs/soc_flow.log) - phan chenh la buffer CTS, filler va
# buffer cua optDesign con lai tu run truoc.
set ::SOC_PNR_INST_PREFIXES {CTS_* FILLER* WELLTAP* postCTS_* postRoute_*}

proc soc_std_area_by_top_inst {} {
    set ptrs [dbGet -p2 top.insts.cell.baseClass core]
    set areas [dict create]
    set skipped 0
    # libCell khong co thuoc tinh 'area' (IMPDBTCL-204) -> size_x * size_y
    foreach inst [dbGet $ptrs.name] sx [dbGet $ptrs.cell.size_x] sy [dbGet $ptrs.cell.size_y] {
        set leaf [lindex [split $inst /] end]
        set is_pnr 0
        foreach pat $::SOC_PNR_INST_PREFIXES {
            if {[string match $pat $leaf]} {
                set is_pnr 1
                break
            }
        }
        if {$is_pnr} {
            incr skipped
            continue
        }
        set area [expr {double($sx) * double($sy)}]
        set top [lindex [split $inst /] 0]
        if {$top eq $inst} {
            set top __top_glue__
        }
        if {![dict exists $areas $top]} {
            dict set areas $top 0.0
        }
        dict set areas $top [expr {[dict get $areas $top] + double($area)}]
    }
    if {$skipped > 0} {
        puts "WARNING: soc_std_area_by_top_inst bo qua $skipped cell do P&R\
 tao ($::SOC_PNR_INST_PREFIXES) - thiet ke trong RAM KHONG phai netlist vua nap."
    }
    return $areas
}

# Bo cuc mam, toa do tuong doi goc duoi-trai cua loi.
# Tra ve dict: core_w, core_h, <nhom> {x y w h}, logic {x0 y0 x1 y1}.
proc soc_layout {std_area_total} {
    set E $::SOC_EDGE_GAP
    set G $::SOC_GROUP_GAP
    foreach g {RAM_LO RAM_HI CACHE TAG} {
        lassign [soc_group_dims $g] W($g) H($g)
    }
    set band_h [expr {max($H(CACHE), $H(TAG))}]
    set mid_w  [expr {$W(CACHE) + $G + $W(TAG)}]
    set logic_area [expr {$std_area_total / $::MCU_TARGET_STD_UTIL}]

    set core_w [expr {2 * $E + $W(RAM_LO) + $G + $mid_w + $G + $W(RAM_HI)}]
    set core_h [expr {2 * $E + max($H(RAM_LO), $H(RAM_HI), \
        $band_h + $G + $logic_area / $mid_w)}]
    set core_w [soc_snap_up $core_w $::SOC_SITE_W]
    set core_h [soc_snap_up $core_h $::SOC_ROW_H]
    # Override (KHOI 3 lay tu coreBox that) KHONG duoc snap len: floorPlan snap
    # be rong loi theo PlacementGrid, khong phai site 0.216 (2190.816 khong chia
    # het 0.216) -> snap len thanh 2190.888 thi RAM_HI lo ra ngoai loi 72 nm.
    if {$::MCU_CORE_WIDTH_OVERRIDE > 0.0} {
        set core_w [expr {double($::MCU_CORE_WIDTH_OVERRIDE)}]
    }
    if {$::MCU_CORE_HEIGHT_OVERRIDE > 0.0} {
        set core_h [expr {double($::MCU_CORE_HEIGHT_OVERRIDE)}]
    }

    set L [dict create core_w $core_w core_h $core_h]
    dict set L RAM_LO [list $E $E $W(RAM_LO) $H(RAM_LO)]
    # Cum sat mep phai: lam tron XUONG luoi site, soc_place_group snap_near se
    # giu nguyen (lam tron len la vuot mep loi).
    dict set L RAM_HI [list [soc_snap_down [expr {$core_w - $E - $W(RAM_HI)}] $::SOC_SITE_W] \
        $E $W(RAM_HI) $H(RAM_HI)]
    set x_cache [expr {$E + $W(RAM_LO) + $G}]
    dict set L CACHE [list $x_cache $E $W(CACHE) $H(CACHE)]
    dict set L TAG [list [expr {$x_cache + $W(CACHE) + $G}] $E $W(TAG) $H(TAG)]
    dict set L logic [list $x_cache [expr {$E + $band_h + $G}] \
        [expr {$core_w - $E - $W(RAM_HI) - $G}] [expr {$core_h - $E}]]

    foreach g {RAM_LO RAM_HI CACHE TAG} {
        lassign [dict get $L $g] x y w h
        if {$x < 0 || $y < 0 || $x + $w > $core_w + 1e-6 || $y + $h > $core_h + 1e-6} {
            error "Nhom $g ($w x $h) khong lot vao loi $core_w x $core_h"
        }
    }
    if {[dict get $L TAG] ne "" &&
        [lindex [dict get $L TAG] 0] + $W(TAG) > [lindex [dict get $L RAM_HI] 0] - $G + 1e-6} {
        error "CACHE + TAG de len RAM_HI - loi qua hep"
    }
    return $L
}

# Xep mot cum theo cot: cot chan R0, cot le MY.  status: placed (keo duoc) |
# fixed.
#
# SUA GHI CHU 2026-09-20: ban cu viet "de chan SRAM hai cot ke nhau quay vao
# nhau (Hierarchy trang 35)".  Do la SAI voi macro nay.  Do lai LEF
# srambank_256x4x32: 78 chan signal nam o x 55.636..70.940 tren macro rong
# 121.392 - tuc GIUA THAN macro, tren stack M3 -> V3 -> M4 (14 chan len M5),
# trai gan het chieu cao.  MY lat chung thanh 50.452..65.756: van o giua.  Chan
# khong bao gio quay ra canh nao, nen R0/MY KHONG doi gi ve tiep can chan.
# Router vao chan tu tren bang V4/V5 (OBS cua macro chan kin M1-M3 nhung M4 chi
# 0.6% va M5 chi 0.4%), khong di qua khe giua hai macro.
# Van giu R0/MY vi ca hai deu thoa 10_Macro Priority 8 (chi 0/180 do) va giu
# rail M1 VDD/VSS cua macro nam ngang; chi bo loi khang dinh ve huong chan.
proc soc_place_group {group x0 y0 status} {
    lassign [soc_group_dims $group] gw gh w h rows
    set core_llx [dbGet top.fPlan.coreBox_llx]
    set core_lly [dbGet top.fPlan.coreBox_lly]
    set gap $::SOC_MACRO_GAP
    set index 0
    foreach record [soc_group_records $group] {
        lassign $record name ptr
        set col [expr {$index / $rows}]
        set row [expr {$index % $rows}]
        set x [soc_snap_near [expr {$core_llx + $x0 + [soc_col_x $group $col $w]}] $core_llx $::SOC_SITE_W]
        set y [soc_snap_near [expr {$core_lly + $y0 + $row * ($h + $gap)}] $core_lly $::SOC_ROW_H]
        set orient [expr {$col % 2 == 0 ? "R0" : "MY"}]
        dbSet $ptr.pStatus unplaced
        placeInstance $name $x $y $orient
        dbSet $ptr.pStatus $status
        incr index
    }
    return $index
}

# Snap goc moi SRAM trong nhom ve luoi site/row, roi dich CA NHOM vao trong
# loi neu lo mep (be rong loi khong chia het site: keo sat mep phai bang
# move_obj -to core_box, lam tron len la ra ngoai 72 nm).  Dich ca nhom de
# khe giua cac SRAM khong doi.  Tra ve list {name ptr x y sx sy}.
proc soc_snap_group {group} {
    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx0 cy0 cx1 cy1
    foreach {name kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        if {$name eq $group} {
            lassign [soc_macro_size $kind] w h
        }
    }
    set out {}
    set over_x 0.0
    set over_y 0.0
    set under_x 0.0
    set under_y 0.0
    foreach record [soc_group_records $group] {
        lassign $record name ptr
        lassign [lindex [dbGet $ptr.pt] 0] x y
        set sx [soc_snap_near $x $cx0 $::SOC_SITE_W]
        set sy [soc_snap_near $y $cy0 $::SOC_ROW_H]
        set over_x  [expr {max($over_x, $sx + $w - $cx1)}]
        set over_y  [expr {max($over_y, $sy + $h - $cy1)}]
        set under_x [expr {max($under_x, $cx0 - $sx)}]
        set under_y [expr {max($under_y, $cy0 - $sy)}]
        lappend out [list $name $ptr $x $y $sx $sy]
    }
    set dx [expr {[soc_snap_up $under_x $::SOC_SITE_W] - [soc_snap_up $over_x $::SOC_SITE_W]}]
    set dy [expr {[soc_snap_up $under_y $::SOC_ROW_H] - [soc_snap_up $over_y $::SOC_ROW_H]}]
    if {$dx == 0.0 && $dy == 0.0} {
        return $out
    }
    puts [format "Nhom %s lo mep loi -> dich ca nhom dx=%.3f dy=%.3f" $group $dx $dy]
    set moved {}
    foreach item $out {
        lassign $item name ptr x y sx sy
        lappend moved [list $name $ptr $x $y [expr {$sx + $dx}] [expr {$sy + $dy}]]
    }
    return $moved
}

# Ring loi M8/M9 (KHOI 2) phai du 2 doan M8 + 2 doan M9 cho moi net.
proc soc_check_core_ring {} {
    foreach net {VDD VSS} {
        set rings [dbGet -e -p [dbGet -p top.nets.name $net].sWires.shape ring]
        set layers [expr {[llength $rings] ? [dbGet $rings.layer.name] : {}}]
        set n8 [llength [lsearch -all -exact $layers M8]]
        set n9 [llength [lsearch -all -exact $layers M9]]
        puts "Ring loi $net: $n8 doan M8, $n9 doan M9"
        if {$n8 < 2 || $n9 < 2} {
            error "Ring loi $net thieu (M8=$n8 M9=$n9) - chua chay KHOI 2, addRing loi, hoac doan ring bi xoa sau KHOI 2 (editDelete/editTrim) - chay lai tu KHOI 0"
        }
    }
}

# Luu vi tri 84 SRAM (sau khi xep tay) ra file Tcl de lan sau KHOI 3 nap lai.
proc soc_save_sram_place {{file ""}} {
    if {$file eq ""} {
        set file $::SOC_SRAM_PLACE_FILE
    }
    set lines {}
    foreach {group kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        foreach record [soc_group_records $group] {
            lassign $record name ptr
            if {[dbGet $ptr.pStatus] eq "unplaced"} {
                error "$name chua dat - khong luu"
            }
            lassign [lindex [dbGet $ptr.pt] 0] x y
            lappend lines [format "    {%s %.4f %.4f %s}" [list $name] $x $y [dbGet $ptr.orient]]
        }
    }
    set fp [open $file w]
    puts $fp "# Vi tri SRAM luu boi soc_save_sram_place - KHOI 3 nap lai file nay."
    puts $fp "# Xoa file de KHOI 3 xep lai vi tri mam."
    puts $fp "set SOC_SRAM_PLACE_CORE {[lindex [dbGet top.fPlan.coreBox] 0]}"
    puts $fp "set SOC_SRAM_PLACE {"
    puts $fp [join $lines \n]
    puts $fp "}"
    close $fp
    puts "Da luu [llength $lines] SRAM vao $file"
    return [llength $lines]
}

# Nhom config cua mot SRAM: dung ca master lan tien to (TAG va CACHE chung tien to).
proc soc_inst_group {name ptr} {
    set master [dbGet $ptr.cell.name]
    foreach {group kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        if {$master ne [soc_master_name $kind]} {
            continue
        }
        foreach prefix $prefixes {
            if {[string first $prefix $name] == 0} {
                return $group
            }
        }
    }
    error "$name ($master) khong thuoc nhom nao trong SOC_SRAM_GROUPS"
}

# Nap file cua soc_save_sram_place; loi neu loi (core) khac luc luu.  Rieng mep
# phai duoc lech <= SOC_CORE_SNAP_TOL (floorPlan lam tron be rong loi): nhom nao
# sat mep phai luc luu (RAM_HI) duoc dich ca nhom theo, lam tron XUONG luoi site.
proc soc_load_sram_place {{file ""}} {
    if {$file eq ""} {
        set file $::SOC_SRAM_PLACE_FILE
    }
    uplevel #0 [list source $file]
    set saved $::SOC_SRAM_PLACE_CORE
    set now [lindex [dbGet top.fPlan.coreBox] 0]
    # Chua co design trong bo nho thi dbGet tra 0x0; 'expr' doc 0x0 la so 0 nen
    # so sanh ben duoi bao "loi khac nhau" va XUI XOA file vi tri SRAM - mat
    # het cong xep tay.  Run 2026-09-18 16:59 dinh dung cai bay nay sau khi
    # KHOI 0 that bai o preflight.
    if {[llength $now] != 4} {
        error "soc_load_sram_place: chua co floorplan trong bo nho (dbGet coreBox = '$now').  Chay KHOI 0 (init_design) va KHOI 1 (floorPlan) truoc. KHONG xoa $file - vi tri SRAM trong do van dung."
    }
    set dx 0.0
    foreach a $saved b $now i {0 1 2 3} {
        set d [expr {$b - $a}]
        if {abs($d) <= 1e-3} {
            continue
        }
        if {$i != 2 || abs($d) > $::SOC_CORE_SNAP_TOL + 1e-6} {
            error "Loi hien tai {$now} khac loi luc luu {$saved} - xoa $file de xep mam lai"
        }
        set dx [soc_snap_down $d $::SOC_SITE_W]
    }
    set expected [expr {$::SRAM_EXPECTED_COUNT + $::SRAM_TAG_EXPECTED_COUNT}]
    if {[llength $::SOC_SRAM_PLACE] != $expected} {
        error "$file co [llength $::SOC_SRAM_PLACE] SRAM, netlist co $expected"
    }
    set entries {}
    array set right {}
    foreach entry $::SOC_SRAM_PLACE {
        lassign $entry name x y orient
        set ptr [dbGet -e -p top.insts.name $name]
        if {$ptr eq ""} {
            error "$file: khong co instance $name"
        }
        set group [soc_inst_group $name $ptr]
        set x1 [expr {$x + [dbGet $ptr.cell.size_x]}]
        if {![info exists right($group)] || $x1 > $right($group)} {
            set right($group) $x1
        }
        lappend entries [list $name $ptr $group $x $y $orient]
    }
    set shifted {}
    foreach item $entries {
        lassign $item name ptr group x y orient
        if {$dx != 0.0 && $right($group) > [lindex $saved 2] - 1.0} {
            set x [expr {$x + $dx}]
            if {$group ni $shifted} {
                lappend shifted $group
            }
        }
        dbSet $ptr.pStatus unplaced
        placeInstance $name $x $y $orient
        dbSet $ptr.pStatus placed
    }
    if {[llength $shifted] > 0} {
        puts [format "Loi lech %.3f um o mep phai -> dich nhom %s %.3f um" \
            [expr {[lindex $now 2] - [lindex $saved 2]}] $shifted $dx]
    }
    return [llength $entries]
}

# Kiem tra SRAM sau khi chinh tay: huong, nam trong loi, khe >= SOC_MACRO_GAP.
# Dung goc dat + kich thuoc LEF, khong dung .box (OBS V3 lo ra ~0.02 um).
proc soc_check_macros {report} {
    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx0 cy0 cx1 cy1
    set boxes {}
    set errors {}
    foreach {group kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        lassign [soc_macro_size $kind] w h
        foreach record [soc_group_records $group] {
            lassign $record name ptr
            if {[dbGet $ptr.pStatus] eq "unplaced"} {
                lappend errors "$name chua dat"
                continue
            }
            set orient [dbGet $ptr.orient]
            if {$orient ni {R0 MY MX R180}} {
                lappend errors "$name huong $orient (10_Macro trang 14: chi quay 0/180 do)"
            }
            lassign [lindex [dbGet $ptr.pt] 0] x y
            set box [list $x $y [expr {$x + $w}] [expr {$y + $h}]]
            if {$x < $cx0 - 1e-3 || $y < $cy0 - 1e-3 ||
                [lindex $box 2] > $cx1 + 1e-3 || [lindex $box 3] > $cy1 + 1e-3} {
                lappend errors "$name ra ngoai loi: $box"
            }
            lappend boxes [list $name $group $box]
        }
    }
    set n [llength $boxes]
    for {set i 0} {$i < $n} {incr i} {
        lassign [lindex $boxes $i] ni gi bi
        lassign $bi ax0 ay0 ax1 ay1
        for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
            lassign [lindex $boxes $j] nj gj bj
            lassign $bj bx0 by0 bx1 by1
            set sep [expr {max(max($bx0 - $ax1, $ax0 - $bx1), max($by0 - $ay1, $ay0 - $by1))}]
            if {$sep < -1e-3} {
                lappend errors "$ni chong len $nj"
            } elseif {$sep < $::SOC_MACRO_GAP - 1e-3} {
                lappend errors [format "%s - %s cach %.3f um < %.3f" $ni $nj $sep $::SOC_MACRO_GAP]
            }
        }
    }
    set fp [open $report w]
    foreach b $boxes {
        puts $fp $b
    }
    foreach e $errors {
        puts $fp "ERROR $e"
    }
    close $fp
    return $errors
}

# Canh duoi/trai cua cap VSS/VDD dat giua kenh lo..hi, tam day tren track.
# Chep y tu pg_track_aligned_pair_offset cua sram_axi.
proc soc_pg_pair_edge {layer lo hi} {
    set w $::SOC_ISLAND_PG_W
    set pitch $::SOC_PG_PITCH($layer)
    set off $::SOC_PG_OFFSET($layer)
    set pair [expr {2.0 * $w + $::SOC_ISLAND_PG_S}]
    if {$hi - $lo <= $pair} {
        error "$layer: kenh [format %.3f $lo]..[format %.3f $hi] hep hon mot cap VSS/VDD"
    }
    set nominal [expr {$lo + ($hi - $lo - $pair) / 2.0 + $w / 2.0}]
    set edge [expr {$off + round(($nominal - $off) / $pitch) * $pitch - $w / 2.0}]
    while {$edge < $lo - 1e-6} {
        set edge [expr {$edge + $pitch}]
    }
    while {$edge > $hi - $pair + 1e-6} {
        set edge [expr {$edge - $pitch}]
    }
    if {$edge < $lo - 1e-6} {
        error "$layer: khong co track nao dat vua cap VSS/VDD trong $lo..$hi"
    }
    return $edge
}

# Mot cap VSS/VDD: M4 ngang hoac M5 doc, nam gon trong 'area'.
proc soc_pg_pair {layer dir area} {
    lassign $area ax0 ay0 ax1 ay1
    if {$dir eq "horizontal"} {
        lassign [list $ay0 $ay1 bottom] lo hi from
    } else {
        lassign [list $ax0 $ax1 left] lo hi from
    }
    set edge [soc_pg_pair_edge $layer $lo $hi]
    addStripe -nets {VSS VDD} -layer $layer -direction $dir \
        -width $::SOC_ISLAND_PG_W -spacing $::SOC_ISLAND_PG_S \
        -start_from $from -start_offset [format %.6f [expr {$edge - $lo}]] \
        -number_of_sets 1 -create_pins 0 -area $area \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1
}

# So doan stripe VDD+VSS tren mot layer.
proc soc_stripe_count {layer} {
    set n 0
    foreach net {VDD VSS} {
        set ptrs [dbGet -e -p [dbGet -p top.nets.name $net].sWires.shape stripe]
        if {[llength $ptrs] > 0} {
            incr n [llength [lsearch -all -exact [dbGet $ptrs.layer.name] $layer]]
        }
    }
    return $n
}

# Gop cac doan {lo hi} chong/cham nhau, sap tang dan.
proc soc_merge_intervals {ivs} {
    set out {}
    foreach iv [lsort -real -index 0 $ivs] {
        lassign $iv lo hi
        if {[llength $out] > 0 && $lo <= [lindex $out end 1] + 1e-3} {
            lset out end 1 [expr {max([lindex $out end 1], $hi)}]
        } else {
            lappend out [list $lo $hi]
        }
    }
    return $out
}

# Moi SRAM: {ten nhom x0 y0 x1 y1} theo vi tri that (goc + kich thuoc LEF).
proc soc_sram_boxes {} {
    set boxes {}
    foreach {group kind cols rows prefixes} $::SOC_SRAM_GROUPS {
        lassign [soc_macro_size $kind] w h
        foreach record [soc_group_records $group] {
            lassign $record name ptr
            lassign [lindex [dbGet $ptr.pt] 0] x y
            lappend boxes [list $name $group $x $y [expr {$x + $w}] [expr {$y + $h}]]
        }
    }
    return $boxes
}

# Chia SRAM thanh cum theo VI TRI (khong theo nhom config): hai SRAM cach nhau
# < 2 khe (khong du cho 2 cap VSS/VDD rieng) thi chung mot cum.  Nhu vay TAG xep
# chen giua cac cot CACHE van dung, va hai cum xa nhau khong dung chung day.
proc soc_sram_islands {boxes} {
    set n [llength $boxes]
    set limit [expr {2.0 * $::SOC_MACRO_GAP - 1e-3}]
    set label [lrepeat $n -1]
    set islands {}
    for {set i 0} {$i < $n} {incr i} {
        if {[lindex $label $i] >= 0} {
            continue
        }
        set id [llength $islands]
        lset label $i $id
        set queue [list $i]
        set members {}
        while {[llength $queue] > 0} {
            set k [lindex $queue 0]
            set queue [lrange $queue 1 end]
            lappend members [lindex $boxes $k]
            lassign [lrange [lindex $boxes $k] 2 5] ax0 ay0 ax1 ay1
            for {set j 0} {$j < $n} {incr j} {
                if {[lindex $label $j] >= 0} {
                    continue
                }
                lassign [lrange [lindex $boxes $j] 2 5] bx0 by0 bx1 by1
                if {max($bx0 - $ax1, $ax0 - $bx1, $by0 - $ay1, $ay0 - $by1) < $limit} {
                    lset label $j $id
                    lappend queue $j
                }
            }
        }
        lappend islands $members
    }
    return $islands
}

# Luoi nguon rieng cho MOT cum (tu soc_sram_islands).  Cum khong can deu:
#   M5 doc  : moi kenh doc suot chieu cao cum - mep trai, khe giua cac cot, mep phai
#   M4 ngang: trong tung cot - mep duoi, moi khe giua hai SRAM, mep tren - keo
#             sang hai kenh doc ke ben de cat qua cap M5 (co via M4-M5)
#   M5 tap  : moi SRAM mot cap o canh phai, tu khe ben duoi an len chan PG M4
# Moi dai deu nam ngoai than SRAM (tru phan tap trong than SRAM cua chinh no).
proc soc_island_pg {members all_boxes} {
    set G $::SOC_MACRO_GAP
    set E $::SOC_PG_EPS
    set eps 1e-3
    set pair [expr {2.0 * $::SOC_ISLAND_PG_W + $::SOC_ISLAND_PG_S}]

    set groups {}
    set xivs {}
    set ys0 {}
    set ys1 {}
    foreach m $members {
        lassign $m name group mx0 my0 mx1 my1
        if {$group ni $groups} {
            lappend groups $group
        }
        lappend xivs [list $mx0 $mx1]
        lappend ys0 $my0
        lappend ys1 $my1
    }
    set label "[join $groups +]([llength $members])"
    set ymin [tcl::mathfunc::min {*}$ys0]
    set ymax [tcl::mathfunc::max {*}$ys1]
    set spans [soc_merge_intervals $xivs]
    set x0 [expr {[lindex $spans 0 0] - $G}]
    set x1 [expr {[lindex $spans end 1] + $G}]
    set y0 [expr {$ymin - $G}]
    set y1 [expr {$ymax + $G}]
    # Cum duoc dat sat mep loi: khe mep ngoai (G) khi do nam trong le loi->die
    # (SOC_CORE_MARGIN = 10 um), duoi ring loi M8/M9 - khac layer nen khong dung.
    lassign [lindex [dbGet top.fPlan.box] 0] dx0 dy0 dx1 dy1
    if {$x0 < $dx0 + $E - $eps || $y0 < $dy0 + $E - $eps ||
        $x1 > $dx1 - $E + $eps || $y1 > $dy1 - $E + $eps} {
        error [format "Cum %s {%.3f %.3f %.3f %.3f}: khe mep ngoai %.2f um ra ngoai die - SRAM khong duoc vuot mep loi (SOC_CORE_MARGIN phai >= %.2f)" \
            $label [expr {$x0 + $G}] $ymin [expr {$x1 - $G}] $ymax $G [expr {$G + $E}]]
    }

    # Kenh doc: mep trai, giua cac cot (suot chieu cao khong co SRAM), mep phai
    set vchans [list [list $x0 [lindex $spans 0 0]]]
    foreach a [lrange $spans 0 end-1] b [lrange $spans 1 end] {
        if {[lindex $b 0] - [lindex $a 1] < $G - $eps} {
            error [format "Cum %s: hai cot SRAM x=%.3f va x=%.3f cach %.3f < %.2f" \
                $label [lindex $a 1] [lindex $b 0] [expr {[lindex $b 0] - [lindex $a 1]}] $G]
        }
        lappend vchans [list [lindex $a 1] [lindex $b 0]]
    }
    lappend vchans [list [lindex $spans end 1] $x1]

    set areas {}
    foreach c $vchans {
        lappend areas [list M5 vertical [list [lindex $c 0] $y0 [lindex $c 1] $y1]]
    }
    # Kenh ngang trong tung cot, keo sang hai kenh doc ke ben (cach than SRAM E)
    set nh 0
    set last [expr {[llength $spans] - 1}]
    for {set i 0} {$i <= $last} {incr i} {
        lassign [lindex $spans $i] sx0 sx1
        set ax0 [lindex $vchans $i 0]
        set ax1 [lindex $vchans [expr {$i + 1}] 1]
        if {$i > 0} {
            set ax0 [expr {$ax0 + $E}]
        }
        if {$i < $last} {
            set ax1 [expr {$ax1 - $E}]
        }
        set yivs {}
        foreach m $members {
            lassign $m name group mx0 my0 mx1 my1
            if {$mx0 < $sx1 - $eps && $mx1 > $sx0 + $eps} {
                lappend yivs [list $my0 $my1]
            }
        }
        set rows [soc_merge_intervals $yivs]
        set hchans [list [list [expr {[lindex $rows 0 0] - $G}] [lindex $rows 0 0]]]
        foreach a [lrange $rows 0 end-1] b [lrange $rows 1 end] {
            if {[lindex $b 0] - [lindex $a 1] < $G - $eps} {
                error [format "Cum %s: hai SRAM y=%.3f va y=%.3f (cot x=%.1f) cach %.3f < %.2f" \
                    $label [lindex $a 1] [lindex $b 0] $sx0 [expr {[lindex $b 0] - [lindex $a 1]}] $G]
            }
            lappend hchans [list [lindex $a 1] [lindex $b 0]]
        }
        lappend hchans [list [lindex $rows end 1] [expr {[lindex $rows end 1] + $G}]]
        foreach c $hchans {
            lappend areas [list M4 horizontal [list $ax0 [lindex $c 0] $ax1 [lindex $c 1]]]
            incr nh
        }
    }

    # Khong dai nao de len than SRAM (cua bat ky cum nao)
    foreach item $areas {
        lassign [lindex $item 2] ax0 ay0 ax1 ay1
        foreach body $all_boxes {
            lassign $body bname bgroup bx0 by0 bx1 by1
            if {min($ax1, $bx1) - max($ax0, $bx0) > $eps && min($ay1, $by1) - max($ay0, $by0) > $eps} {
                error [format "Cum %s: dai %s {%.3f %.3f %.3f %.3f} de len %s" \
                    $label [lindex $item 0] $ax0 $ay0 $ax1 $ay1 $bname]
            }
        }
    }
    # Cap M4 cua hai cot ke nhau gap nhau trong kenh doc: phai trung nhau hoan toan
    # hoac cach du xa, neu khong VSS cot nay de len VDD cot kia.
    set m4 {}
    foreach item $areas {
        if {[lindex $item 0] eq "M4"} {
            lassign [lindex $item 2] ax0 ay0 ax1 ay1
            lappend m4 [list $ax0 $ax1 [soc_pg_pair_edge M4 $ay0 $ay1]]
        }
    }
    foreach a $m4 {
        foreach b $m4 {
            lassign $a a0 a1 ea
            lassign $b b0 b1 eb
            set d [expr {abs($ea - $eb)}]
            if {min($a1, $b1) - max($a0, $b0) > $eps && $d > 1e-6 && $d < $pair + $::SOC_ISLAND_PG_S - 1e-6} {
                error [format "Cum %s: cap M4 y=%.3f va y=%.3f cua hai cot ke nhau lech %.3f um - cho khe ngang hai cot thang hang hoac lech xa hon" \
                    $label $ea $eb $d]
            }
        }
    }
    # Tap: phan nam trong khe ben duoi SRAM khong duoc cham SRAM khac
    set taps {}
    foreach m $members {
        lassign $m name group mx0 my0 mx1 my1
        set tap [list [expr {$mx1 - $::SOC_PIN_TAP_BORDER}] [expr {$my0 - $G}] \
            [expr {$mx1 - $E}] [expr {$my0 + $::SOC_PIN_TAP_DEPTH}]]
        lassign $tap tx0 ty0 tx1 ty1
        foreach body $all_boxes {
            lassign $body bname bgroup bx0 by0 bx1 by1
            if {$bname ne $name && min($tx1, $bx1) - max($tx0, $bx0) > $eps && min($ty1, $by1) - max($ty0, $by0) > $eps} {
                error "Cum $label: tap cua $name de len $bname"
            }
        }
        lappend taps $tap
    }

    set n4 [soc_stripe_count M4]
    set n5 [soc_stripe_count M5]
    setAddStripeMode -reset
    setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none \
        -extend_to_closest_target area_boundary \
        -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
    foreach item $areas {
        soc_pg_pair {*}$item
    }
    foreach tap $taps {
        soc_pg_pair M5 vertical $tap
    }
    set add4 [expr {[soc_stripe_count M4] - $n4}]
    set add5 [expr {[soc_stripe_count M5] - $n5}]
    set want4 [expr {2 * $nh}]
    set want5 [expr {2 * ([llength $vchans] + [llength $taps])}]
    puts [format "Cum %-16s %2d cot: M4 ngang %3d/%-3d doan, M5 doc %3d/%-3d doan" \
        $label [llength $spans] $add4 $want4 $add5 $want5]
    if {$add4 < $want4 || $add5 < $want5} {
        error "Cum $label thieu stripe (M4 $add4/$want4, M5 $add5/$want5) - xem addStripe trong innovus.log"
    }
    return $label
}

# Cac doan tu do trong lo..hi sau khi bo cac doan cam {a b}.
proc soc_free_intervals {lo hi blocked} {
    set out {}
    set cur $lo
    foreach b [soc_merge_intervals $blocked] {
        lassign $b a z
        if {$z <= $cur} {
            continue
        }
        if {$a >= $hi} {
            break
        }
        if {$a > $cur} {
            lappend out [list $cur $a]
        }
        set cur $z
    }
    if {$hi > $cur} {
        lappend out [list $cur $hi]
    }
    return $out
}

# Mot layer luoi toan chip, bo qua moi vung trong 'keepouts' {x0 y0 x1 y1}.
# Vi tri cap VDD/VSS van theo luoi chung (goc loi + OFFSET + k*PITCH); cac vi tri
# lien tiep co cung doan tu do gop vao mot lenh addStripe -area.
# Doan tu do chay tu mep die den mep die (cat qua ring loi), editTrim cat phan thua.
# shape = {rong trong pitch offset} (mac dinh luoi SOC_MESH_*).  extra = them vi
# tri cap o sat canh trai/phai (hoac duoi/tren) cua moi keepout, de kenh hep giua
# hai cum van co 1 cap; vi tri luoi qua gan vi tri extra thi bo.
# Cap extra chi chay doc theo canh keepout sinh ra no (+ min_len moi dau): row bi
# cat chi nam canh keepout, phia tren/duoi keepout row lien tuc da co cap luoi.
# Run 2026-09-17 cap extra chay het chieu cao loi: cap mep phai TAG va mep trai
# DTCM (hai keepout cach 0.152 um) thanh 2 cap cach 1.1 um suot 1170 um, chong
# via M1-M5 chiem het track M3/M4 -> 23/35 loi DRC final nam o x~925.
proc soc_mesh_layer {layer dir keepouts {shape {}} {extra 0}} {
    set snap_opts {}
    if {[llength $shape] == 0} {
        set shape [list $::SOC_MESH_W $::SOC_MESH_S $::SOC_MESH_PITCH $::SOC_MESH_OFFSET]
    } else {
        # Day mong 0.096/0.288: snap vao track co the lam lech spacing (nhu sram_axi)
        set snap_opts {-allow_snapping_override_custom_spacing 1}
    }
    lassign $shape W S pitch offset
    set pair [expr {2.0 * $W + $S}]
    set E $::SOC_PG_EPS
    set min_len [expr {2.0 * $::SOC_MACRO_GAP}]
    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx0 cy0 cx1 cy1
    lassign [lindex [dbGet top.fPlan.box] 0] dx0 dy0 dx1 dy1
    if {$dir eq "vertical"} {
        lassign [list $cx0 $cx1 [expr {$dy0 + $E}] [expr {$dy1 - $E}] left] c0 c1 s0 s1 from
    } else {
        lassign [list $cy0 $cy1 [expr {$dx0 + $E}] [expr {$dx1 - $E}] bottom] c0 c1 s0 s1 from
    }
    set edge_pos {}
    array set edge_span {}
    if {$extra} {
        foreach k $keepouts {
            lassign $k kx0 ky0 kx1 ky1
            if {$dir eq "vertical"} {
                lassign [list $kx0 $kx1 $ky0 $ky1] a0 a1 b0 b1
            } else {
                lassign [list $ky0 $ky1 $kx0 $kx1] a0 a1 b0 b1
            }
            set span [list [expr {$b0 - $min_len}] [expr {$b1 + $min_len}]]
            foreach p [list [expr {$a0 - 2.0 * $E - $pair}] [expr {$a1 + 2.0 * $E}]] {
                if {$p < $c0 || $p + $pair > $c1} {
                    continue
                }
                set near ""
                foreach q $edge_pos {
                    if {abs($p - $q) < $pair + $S} {
                        set near $q
                    }
                }
                if {$near eq ""} {
                    lappend edge_pos $p
                    set edge_span($p) $span
                } else {
                    # Hai keepout cung mot vi tri cap: cap phu ca hai canh
                    lassign $edge_span($near) lo hi
                    set edge_span($near) [list [expr {min($lo, [lindex $span 0])}] \
                        [expr {max($hi, [lindex $span 1])}]]
                }
            }
        }
    }
    set positions $edge_pos
    for {set pos [expr {$c0 + $offset}]} {$pos + $pair <= $c1 + 1e-6} \
        {set pos [expr {$pos + $pitch}]} {
        set near 0
        foreach q $edge_pos {
            lassign $edge_span($q) lo hi
            # Cap extra chay suot (canh tuong SRAM, kenh buffer 8.64 um) da thay
            # cap luoi trong vong 1 khe: kenh RAM_HI cot 2|3 tung co 3 cap/8.64 um.
            if {abs($pos - $q) < $pair + $S ||
                (abs($pos - $q) < $::SOC_MACRO_GAP && $lo <= $s0 && $hi >= $s1)} {
                set near 1
            }
        }
        if {!$near} {
            lappend positions $pos
        }
    }
    set groups {}
    foreach pos [lsort -real $positions] {
        set blocked {}
        foreach k $keepouts {
            lassign $k kx0 ky0 kx1 ky1
            if {$dir eq "vertical"} {
                lassign [list $kx0 $kx1 $ky0 $ky1] a0 a1 b0 b1
            } else {
                lassign [list $ky0 $ky1 $kx0 $kx1] a0 a1 b0 b1
            }
            if {$pos < $a1 + $E && $pos + $pair > $a0 - $E} {
                lappend blocked [list [expr {$b0 - $E}] [expr {$b1 + $E}]]
            }
        }
        lassign [list $s0 $s1] lo hi
        if {[info exists edge_span($pos)]} {
            lassign $edge_span($pos) lo hi
            set lo [expr {max($lo, $s0)}]
            set hi [expr {min($hi, $s1)}]
        }
        set free {}
        if {$hi > $lo} {
            foreach iv [soc_free_intervals $lo $hi $blocked] {
                if {[lindex $iv 1] - [lindex $iv 0] >= $min_len} {
                    lappend free $iv
                }
            }
        }
        # Chi gop khi dung buoc pitch: addStripe -set_to_set_distance dat lai tung cap.
        if {[llength $groups] > 0 && [lindex $groups end 2] eq $free &&
            abs($pos - [lindex $groups end 1] - $pitch) < 1e-6} {
            lset groups end 1 $pos
        } else {
            lappend groups [list $pos $pos $free]
        }
    }
    set n 0
    foreach g $groups {
        lassign $g first last free
        set p0 [expr {$first - $E}]
        set p1 [expr {$last + $pair + $E}]
        foreach iv $free {
            lassign $iv b0 b1
            if {$dir eq "vertical"} {
                set area [list $p0 $b0 $p1 $b1]
            } else {
                set area [list $b0 $p0 $b1 $p1]
            }
            addStripe -nets {VDD VSS} -layer $layer -direction $dir \
                -width $W -spacing $S \
                -set_to_set_distance $pitch \
                -start_from $from -start_offset $E -area $area \
                -snap_wire_center_to_grid Grid {*}$snap_opts
            incr n
        }
    }
    return $n
}

# Luoi toan chip M7 doc / M6 ngang, KHONG di len vung cum SRAM (than + khe giua
# cac SRAM).  Noi vao luoi M4/M5 cua cum o mep cum:
#   M6 ngang dung sat than cum -> cat cap M5 mep trai/phai cum, via M5-M6
#   M7 doc  dung sat than cum -> cat cap M4 mep tren/duoi cum, via M4..M7
# Hop bao moi cum SRAM (soc_sram_islands), noi rong moi phia 'grow' um.
proc soc_island_keepouts {{grow 0.0}} {
    set keepouts {}
    foreach island [soc_sram_islands [soc_sram_boxes]] {
        set xs0 {}; set ys0 {}; set xs1 {}; set ys1 {}
        foreach m $island {
            lassign $m name group mx0 my0 mx1 my1
            lappend xs0 $mx0; lappend ys0 $my0; lappend xs1 $mx1; lappend ys1 $my1
        }
        lappend keepouts [list \
            [expr {[tcl::mathfunc::min {*}$xs0] - $grow}] [expr {[tcl::mathfunc::min {*}$ys0] - $grow}] \
            [expr {[tcl::mathfunc::max {*}$xs1] + $grow}] [expr {[tcl::mathfunc::max {*}$ys1] + $grow}]]
    }
    return $keepouts
}

proc soc_add_mesh {} {
    set keepouts [soc_island_keepouts]

    setAddStripeMode -reset
    setAddStripeMode -allow_jog none -break_at none -split_vias true \
        -via_using_exact_crossover_size false \
        -stacked_via_bottom_layer M4 -stacked_via_top_layer M8
    set n7 [soc_mesh_layer M7 vertical $keepouts]

    setAddStripeMode -reset
    setAddStripeMode -allow_jog none -break_at none -split_vias true \
        -via_using_exact_crossover_size false \
        -stacked_via_bottom_layer M5 -stacked_via_top_layer M7
    set n6 [soc_mesh_layer M6 horizontal $keepouts]
    puts "Luoi M7: $n7 vung, M6: $n6 vung (tranh [llength $keepouts] cum SRAM)"
}

# Vung cum SRAM + khe mep cum (cap M4/M5 rieng cua cum nam trong khe 4.32):
# khong co row, khong co std cell, khong co stripe M5 cua std cell.
proc soc_sram_no_std_boxes {} {
    return [soc_island_keepouts $::SOC_MACRO_GAP]
}

# Notch giua cac cum SRAM (10_Macro Priority 7).  Hai vung khong std cell a, b
# (soc_sram_no_std_boxes; mep loi cung tinh) doi mat nhau cach d
# (1 site/row <= d <= SOC_NOTCH_MAX_W) tren doan chung s0..s1:
#   - vung c nam giua va chan suot s0..s1 -> a, b khong doi mat, bo qua
#   - vung c phu ca khe (sai lech < 1 site) -> bo doan cua c khoi s0..s1
#     (hoc tren TAG: bo phan TAG, con 145.37 x 103.68)
# Tra ve {x0 y0 x1 y1}, da cat theo loi.
proc soc_notch_boxes {} {
    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx0 cy0 cx1 cy1
    set core [list $cx0 $cy0 $cx1 $cy1]
    set eps 1e-3
    set boxes [soc_sram_no_std_boxes]
    lappend boxes [list [expr {$cx0 - 1}] $cy0 $cx0 $cy1] [list $cx1 $cy0 [expr {$cx1 + 1}] $cy1] \
        [list $cx0 [expr {$cy0 - 1}] $cx1 $cy0] [list $cx0 $cy1 $cx1 [expr {$cy1 + 1}]]
    set out {}
    # k = 0: khe doc (a ben trai b), k = 1: khe ngang (a ben duoi b); o = truc con lai
    foreach k {0 1} o {1 0} step [list $::SOC_SITE_W $::SOC_ROW_H] ostep [list $::SOC_ROW_H $::SOC_SITE_W] {
        foreach a $boxes {
            foreach b $boxes {
                set g0 [expr {max([lindex $a [expr {$k + 2}]], [lindex $core $k])}]
                set g1 [expr {min([lindex $b $k], [lindex $core [expr {$k + 2}]])}]
                set s0 [expr {max([lindex $a $o], [lindex $b $o], [lindex $core $o])}]
                set s1 [expr {min([lindex $a [expr {$o + 2}]], [lindex $b [expr {$o + 2}]], \
                    [lindex $core [expr {$o + 2}]])}]
                if {$g1 - $g0 < $step - $eps || $g1 - $g0 > $::SOC_NOTCH_MAX_W || $s1 - $s0 < $ostep - $eps} {
                    continue
                }
                set covered {}
                set facing 1
                foreach c $boxes {
                    lassign [list [lindex $c $k] [lindex $c [expr {$k + 2}]] \
                        [lindex $c $o] [lindex $c [expr {$o + 2}]]] c0 c1 d0 d1
                    if {$c0 >= $g1 - $eps || $c1 <= $g0 + $eps || $d1 <= $s0 + $eps || $d0 >= $s1 - $eps} {
                        continue
                    }
                    if {$d0 <= $s0 + $eps && $d1 >= $s1 - $eps} {
                        set facing 0
                        break
                    }
                    if {$c0 < $g0 + $step && $c1 > $g1 - $step} {
                        lappend covered [list $d0 $d1]
                    }
                }
                if {!$facing} {
                    continue
                }
                foreach iv [soc_free_intervals $s0 $s1 $covered] {
                    lassign $iv f0 f1
                    if {$f1 - $f0 < $ostep - $eps} {
                        continue
                    }
                    lappend out [expr {$k == 0 ? [list $g0 $f0 $g1 $f1] : [list $f0 $g0 $f1 $g1]}]
                }
            }
        }
    }
    # Mot hoc co the tim ra tu 2 cap (vd hoc sat mep loi: cap trai-phai va cap
    # mep loi-cum ben tren) -> bo hop nam trong hop lon hon da giu.
    set sized {}
    foreach b $out {
        lassign $b x0 y0 x1 y1
        lappend sized [list [expr {($x1 - $x0) * ($y1 - $y0)}] $b]
    }
    set kept {}
    foreach item [lsort -real -decreasing -index 0 $sized] {
        set b [lindex $item 1]
        lassign $b x0 y0 x1 y1
        set inside 0
        foreach c $kept {
            lassign $c u0 v0 u1 v1
            if {$u0 <= $x0 + $eps && $v0 <= $y0 + $eps && $u1 >= $x1 - $eps && $v1 >= $y1 - $eps} {
                set inside 1
                break
            }
        }
        if {!$inside} {
            lappend kept $b
        }
    }
    return $kept
}

# Rail M1 + stripe M5 cho std cell.  Flow Risc_V/sram_axi lam SAU placement;
# lam truoc placement voi strap thap da gay short VDD/VSS o flow Risc_V.
#   1. sroute followpin M1 theo row (row trong vung SRAM da cutRow o KHOI 9)
#   2. M5 doc pitch 25.92, KHONG di vao cum SRAM + khe mep cum; them 1 cap sat
#      moi canh cum de kenh hep giua hai cum van duoc noi.  Via M1->M6 tai
#      giao diem voi rail M1 va luoi M6 (KHOI 6).
proc soc_stdcell_rails {} {
    # Chi ve followpin, KHONG tu via len stripe: sroute ha via M1->M7 roi thieu
    # VIARULE M6-M7 cho rail 0.072 (IMPPP-610, run 2026-09-17).  Via M1->M6 do
    # addStripe M5 ben duoi tao.
    setSrouteMode -reset
    setSrouteMode -viaConnectToShape {noshape}
    sroute -nets {VDD VSS} \
        -connect {corePin} \
        -corePinCheckStdcellGeoms \
        -allowJogging 0 \
        -allowLayerChange 0

    setAddStripeMode -reset
    setAddStripeMode \
        -allow_jog none \
        -allow_nonpreferred_dir none \
        -break_at none \
        -extend_to_closest_target area_boundary \
        -stacked_via_bottom_layer M1 \
        -stacked_via_top_layer M6
    # Row sat mep tren/duoi vung cat row co rail nam dung tren mep keepout; neu
    # stripe dung cach mep EPS thi khong cat qua rail do -> rail ho (khoang tren
    # cum TAG: VDD open 779.976..925.344 @ y 260.496).  Thu keepout theo chieu
    # doc nua row de stripe an qua rail mep; van cach cap M4 mep cum (giua khe 4.32).
    set R [expr {$::SOC_PG_EPS + 0.5 * $::SOC_ROW_H}]
    set keepouts {}
    foreach k [soc_sram_no_std_boxes] {
        lassign $k x0 y0 x1 y1
        lappend keepouts [list $x0 [expr {$y0 + $R}] $x1 [expr {$y1 - $R}]]
    }
    set n5 [soc_mesh_layer M5 vertical $keepouts \
        [list $::SOC_M5_W $::SOC_M5_S $::SOC_M5_PITCH $::SOC_M5_OFFSET] 1]
    puts "Stripe M5 std cell: $n5 vung (tranh [llength $keepouts] cum SRAM + khe)"
    editTrim -nets {VDD VSS}
}

# Tong so loi trong report verifyConnectivity (cac dong "N Problem(s)" o Summary);
# report sach ("Found no problems or warnings") -> 0.
proc soc_connectivity_problems {report} {
    set fh [open $report r]
    set text [read $fh]
    close $fh
    set n 0
    foreach {line count} [regexp -all -inline {(\d+) Problem\(s\)} $text] {
        incr n $count
    }
    return $n
}

# ==========================================================================
# CONG KIEM TRA TIMING SAU timeDesign        (them 2026-09-20)
# ==========================================================================
# Run 2026-09-20 di qua ca hai cho nay ma khong ai biet:
#   reports/timing_postCTS_hold/postCTS_hold.summary.gz
#       Hold  WNS -0.001 | TNS -0.011 | Violating Paths 108
#   reports/timing_postCTS/postCTS.summary.gz
#       DRV   max_tran Real 5 (78)
# Chu thich ngay duoi KHOI 12 viet "WNS setup va hold phai >= 0, DRV 'Real' = 0
# truoc khi route" - nhung khong co mot dong lenh nao kiem dieu do, nen KHOI 13
# van route binh thuong.  Lan nay postRoute sua het, ket qua cuoi sach; do la
# may man chu khong phai ket qua cua mot cong kiem tra.
#
# Doc thang bang tom tat cua timeDesign (file .summary hoac .summary.gz) - dung
# bang ma nguoi doc nhin - roi lay cot 'all'.
# ==========================================================================

# Doc file text, tu giai nen neu chi co ban .gz.  Tra ve "" neu khong co file.
proc soc_read_text_or_gz {file} {
    foreach candidate [list $file ${file}.gz] {
        if {![file isfile $candidate]} {
            continue
        }
        set fh [open $candidate rb]
        set raw [read $fh]
        close $fh
        if {[string match *.gz $candidate]} {
            # Tcl 8.6 cua Innovus co lenh zlib; neu ban Tcl khong co thi goi gzip.
            if {[catch {set raw [zlib gunzip $raw]}]} {
                if {[catch {set raw [exec gzip -dc $candidate]} err]} {
                    error "khong giai nen duoc $candidate: $err"
                }
            }
        }
        return $raw
    }
    return ""
}

# Doc mot bang tom tat timeDesign.  Tra ve dict:
#   wns / tns / viol : cot 'all' cua bang "Setup mode" (hoac "Hold mode")
#   drv_<ten>        : so net trong cot Real cua bang DRV (chi co o ban setup)
# Thieu gia tri nao thi khoa do khong co trong dict.
proc soc_timing_summary {dir prefix {mode setup}} {
    set file [file join $dir $prefix]
    if {$mode eq "hold"} {
        append file _hold.summary
    } else {
        append file .summary
    }
    set text [soc_read_text_or_gz $file]
    if {$text eq ""} {
        return {}
    }
    set out [dict create file $file]
    foreach line [split $text \n] {
        # |           WNS (ns):|  0.339  |  1.077  | ...   -> cot dau tien = 'all'
        if {[regexp {^\|\s*(WNS|TNS)\s*\(ns\)\s*:\|([^|]*)\|} $line -> key val]} {
            set val [string trim $val]
            if {[string is double -strict $val]} {
                dict set out [string tolower $key] $val
            }
        } elseif {[regexp {^\|\s*Violating Paths\s*:\|([^|]*)\|} $line -> val]} {
            set val [string trim $val]
            if {[string is integer -strict $val]} {
                dict set out viol $val
            }
        } elseif {[regexp {^\|\s*(max_\w+)\s*\|\s*([0-9]+)\s*\(} $line -> drv n]} {
            # Cot dau cua bang DRV la "Real" - cot "Total" gom ca vi pham tren
            # clock net do CCOpt tao ra (423 max_fanout, 6 max_tran o run
            # 2026-09-20), khong phai loi cua design.
            dict set out drv_$drv $n
        }
    }
    return $out
}

# Ten file bao cao DRV ma timeDesign xuat ra, theo tung loai vi pham.
set ::SOC_DRV_REPORT_SUFFIX {
    max_tran    tran
    max_cap     cap
    max_fanout  fanout
    max_length  length
}

# Doc bao cao DRV cua timeDesign, tra ve {{net slack pin cell/port} ...} cua
# nhung vi pham THAT (remark R), xep tu xau nhat.  Remark C la chan clock do
# CCOpt tao ra - chinh bao cao ghi "may not be fixable" - nen khong dem o day.
#
# Vi sao can: run 2026-09-21 12:40 KHOI 14 dung voi dong
#     postRoute SETUP: WNS 0.342 TNS 0.0, 0 duong vi pham
#       -> max_tran Real 1 net
# Doc nguyen van thi thay mau thuan (setup sach ma van loi) va khong biet net
# nao.  Phai zcat postRoute.tran.gz bang tay moi ra u_apb_cordic_state[0],
# lech dung 1 ps (0.151 so voi 0.150 ns), driver HB2xp67 keo 12 chan.
proc soc_drv_violators {dir prefix kind} {
    if {![dict exists $::SOC_DRV_REPORT_SUFFIX $kind]} {
        return {}
    }
    set file [file join $dir "$prefix.[dict get $::SOC_DRV_REPORT_SUFFIX $kind]"]
    set text [soc_read_text_or_gz $file]
    if {$text eq ""} {
        return {}
    }
    set net   ""
    set worst [dict create]
    foreach line [split $text \n] {
        if {[string index $line 0] eq "#" || [string trim $line] eq ""} {
            continue
        }
        # Dong ten net bat dau o cot 0; dong chan thi thut vao.
        if {[string index $line 0] ni [list " " "\t"]} {
            set net [string trim $line]
            continue
        }
        if {$net eq ""} {
            continue
        }
        set f [regexp -all -inline {\S+} $line]
        if {[lindex $f end] ne "R"} {
            continue
        }
        # Cot slack la truong <so>r/<so>f CUOI CUNG (truoc no la MaxTran, Tran).
        set slack 0.0
        foreach tok $f {
            if {[regexp {^(-?[0-9.]+)r/(-?[0-9.]+)f$} $tok -> sr sf]} {
                set slack [expr {min(double($sr), double($sf))}]
            }
        }
        # Giu them ten chan va cell/port.  Doc bao cao xong la co ngay dong
        # ecoChangeCell de dan (soc_drv_report in ra), khong phai zcat file
        # .tran.gz roi do bang tay nhu run 2026-09-21 18:09.
        if {![dict exists $worst $net] ||
            $slack < [lindex [dict get $worst $net] 0]} {
            dict set worst $net [list $slack [lindex $f 0] [lindex $f end-1]]
        }
    }
    # Moi phan tu: {net slack pin cell/port}.  Hai truong dau GIU NGUYEN vi tri
    # cu nen soc_check_timing (lindex 0 / lindex 1) khong phai sua theo.
    set out {}
    dict for {n info} $worst {
        lappend out [linsert $info 0 $n]
    }
    return [lsort -real -index 1 $out]
}

# Kiem tra va bao cao.  Tra ve so van de tim duoc.
#   -hold        doc bang Hold mode
#   -drv         bat cot Real cua bang DRV phai = 0
#   -wns <ns>    nguong WNS (mac dinh 0.0)
#   -warn-only   chi in WARNING, khong error (dung cho checkpoint giua chung)
proc soc_check_timing {dir prefix args} {
    set mode      setup
    set check_drv 0
    set min_wns   0.0
    set warn_only 0
    for {set i 0} {$i < [llength $args]} {incr i} {
        switch -- [lindex $args $i] {
            -hold      { set mode hold }
            -drv       { set check_drv 1 }
            -warn-only { set warn_only 1 }
            -wns       { incr i ; set min_wns [lindex $args $i] }
            default    { error "soc_check_timing: tuy chon la '[lindex $args $i]'" }
        }
    }
    set sum [soc_timing_summary $dir $prefix $mode]
    if {[llength $sum] == 0} {
        puts "WARNING: soc_check_timing: khong doc duoc bang tom tat cua\
 $prefix ($mode) trong $dir - KHONG ket luan duoc timing"
        return -1
    }
    set label [string toupper $mode]
    set bad {}
    if {[dict exists $sum wns] && [dict get $sum wns] < $min_wns} {
        lappend bad "WNS [dict get $sum wns] ns < $min_wns"
    }
    if {[dict exists $sum tns] && [dict get $sum tns] < 0} {
        lappend bad "TNS [dict get $sum tns] ns"
    }
    if {[dict exists $sum viol] && [dict get $sum viol] > 0} {
        lappend bad "[dict get $sum viol] duong vi pham"
    }
    # DRV dem RIENG voi timing.  Run 2026-09-21 12:40: setup hoan toan sach
    # (WNS +0.342, TNS 0.0, 0 duong) ma khoi van dung vi mot net max_tran -
    # gop chung mot dong lam thong bao doc nhu tu mau thuan.
    set bad_drv {}
    if {$check_drv} {
        foreach key [lsort [dict keys $sum drv_*]] {
            if {[dict get $sum $key] <= 0} {
                continue
            }
            set kind  [string range $key 4 end]
            set who   [soc_drv_violators $dir $prefix $kind]
            set names {}
            foreach item [lrange $who 0 4] {
                lappend names [format "%s (%+.3f ns)" [lindex $item 0] [lindex $item 1]]
            }
            set tail ""
            if {[llength $names] > 0} {
                set tail ": [join $names {, }]"
                if {[llength $who] > 5} {
                    append tail " ... con [expr {[llength $who] - 5}] net"
                }
            }
            lappend bad_drv "$kind Real [dict get $sum $key] net$tail"
        }
    }
    set head [format "%s %s: WNS %s TNS %s, %s duong vi pham" \
        $prefix $label \
        [expr {[dict exists $sum wns] ? [dict get $sum wns] : "?"}] \
        [expr {[dict exists $sum tns] ? [dict get $sum tns] : "?"}] \
        [expr {[dict exists $sum viol] ? [dict get $sum viol] : "?"}]]
    if {[llength $bad] == 0 && [llength $bad_drv] == 0} {
        puts "  $head -> DAT"
        return 0
    }
    set msg $head
    if {[llength $bad] == 0} {
        append msg "\n  -> TIMING DAT"
    } else {
        append msg "\n  -> TIMING: [join $bad {; }]"
    }
    if {[llength $bad_drv] > 0} {
        append msg "\n  -> DRV  : [join $bad_drv {; }]"
    }
    append msg "\n  Xem [dict get $sum file](.gz)"
    if {$warn_only} {
        puts "WARNING: $msg"
        puts "WARNING: buoc nay chua phai buoc cuoi nen flow chay tiep, nhung\
 con so tren phai ve 0 truoc khi ket luan."
        return [expr {[llength $bad] + [llength $bad_drv]}]
    }
    error $msg
}


# Doc lai report_power va noi ro con so do co nghia gi.
#
# Run 2026-09-20 ra 92.05 mW, trong do Macro internal 82.21 mW = 89.5%.  Khong
# co VCD nen report_power dung activity mac dinh 0.2 cho MOI chan - tuc coi ca
# 84 macro SRAM deu duoc truy cap 0.2 lan moi chu ky, cung luc.  RTL chi bat
# mot bank moi lan doc/ghi, nen day KHONG phai cong suat cua thiet ke; no la
# can tren cua truong hop khong bao gio xay ra.
# In thang ra thay vi de nguoi doc tu suy - de mot so nhu the trong bao cao ma
# khong ghi chu la cho de hieu sai nhat cua ca flow.
proc soc_power_note {report} {
    if {![file isfile $report]} {
        puts "WARNING: chua co $report"
        return -1
    }
    set fp [open $report r]
    set text [read $fp]
    close $fp
    set total 0.0
    set macro 0.0
    set has_vcd 0
    foreach line [split $text \n] {
        if {[regexp {^Total Power:\s+([0-9.eE+-]+)} $line -> v]} {
            set total $v
        } elseif {[regexp {^Macro\s+([0-9.eE+-]+)\s+([0-9.eE+-]+)\s+([0-9.eE+-]+)\s+([0-9.eE+-]+)} \
                $line -> mi msw ml mt]} {
            set macro $mt
        } elseif {[regexp {Activity File:\s*(\S+)} $line -> af] && $af ne "N.A."} {
            set has_vcd 1
        }
    }
    if {$total <= 0} {
        puts "WARNING: khong doc duoc Total Power tu $report"
        return -1
    }
    puts [format "  Cong suat: %.2f mW, trong do macro SRAM %.2f mW (%.1f%%)" \
        $total $macro [expr {100.0 * $macro / $total}]]
    if {!$has_vcd} {
        puts "  -> CHUA co VCD/TCF: activity mac dinh 0.2 cho moi chan, tuc coi"
        puts "     ca 84 macro SRAM deu bi truy cap cung luc.  RTL chi bat mot"
        puts "     bank moi lan doc/ghi -> con so tren la CAN TREN, khong phai"
        puts "     cong suat cua thiet ke.  Muon so that: chay mo phong lay VCD"
        puts "     roi read_activity_file truoc report_power."
    }
    return 0
}

# Slew tai chan cua macro SRAM.
#
# timeDesign danh dau cac vi pham nay remark 'C' (clock net) nen chung nam o
# cot "Total" chu khong phai "Real": soc_check_timing -drv KHONG bat duoc.
# Nhung Liberty cua srambank gioi han max_transition 46 ps o chan clk, va run
# 2026-09-20 con 6 chan 48-69 ps (xau nhat u_dcache/DATA_RAM_G_DATA_WAY[1]
# -23 ps).  Do la dieu kien ghi/doc RAM dung, khong phai con so trang tri ->
# in ra man hinh + logs/soc_flow.log thay vi de nam trong file .gz.
#
# Tra ve so chan vuot gioi han.
proc soc_sram_clk_slew {dir prefix} {
    set text [soc_read_text_or_gz [file join $dir ${prefix}.tran]]
    if {$text eq ""} {
        puts "WARNING: khong doc duoc ${prefix}.tran trong $dir"
        return -1
    }
    set rows {}
    foreach line [split $text \n] {
        if {![string match *srambank_* $line]} {
            continue
        }
        set w [regexp -inline -all {\S+} $line]
        if {[llength $w] < 4} {
            continue
        }
        lassign $w pin lim tran
        if {![regexp {^([0-9.]+)r/([0-9.]+)f$} $lim  -> lr lf]} { continue }
        if {![regexp {^([0-9.]+)r/([0-9.]+)f$} $tran -> tr tf]} { continue }
        lappend rows [list $pin [expr {max($lr, $lf)}] [expr {max($tr, $tf)}]]
    }
    if {[llength $rows] == 0} {
        puts "  Slew chan macro SRAM: khong chan nao vuot gioi han Liberty"
        return 0
    }
    set rows [lsort -real -decreasing -index 2 $rows]
    puts [format "  Slew chan macro SRAM: %d chan vuot gioi han Liberty" \
        [llength $rows]]
    foreach r [lrange $rows 0 9] {
        lassign $r p l t
        puts [format "    %6.1f ps (gioi han %.1f ps)  %s" \
            [expr {$t * 1000.0}] [expr {$l * 1000.0}] $p]
    }
    if {[llength $rows] > 10} {
        puts "    ... con [expr {[llength $rows] - 10}] chan nua"
    }
    puts "  -> CCOpt khong ha them duoc neu chan clk con xa row dat buffer;\
 xem SOC_WALL_CHANNEL trong soc_fp_config.tcl."
    return [llength $rows]
}


# Hold o clock gate roi cg_* (RTL utils/clock_gate.v = latch en_latch_reg + AND2).
# CCOpt coi en_latch_reg la generator (cay CLK_SYS_generator_for_CLK_*), net
# latch Q -> AND.B thanh clock net nam trong "4063 clock nets excluded from IPO"
# nen optDesign -hold khong chen buffer: run 2026-09-17 con 12 duong reg2cgate
# -72 ps (view_ff) sau optDesign -postRoute.  Proc chen hold buffer ngay truoc
# chan AND.B cho toi khi slack hold >= target.  Sau route phai ecoRoute.
# Chay theo VONG: do slack ca 12 latch (1 lan tinh tre), chen 1 buffer cho moi
# latch con vi pham o che do ECO batch, refinePlace 1 lan.  Ban cu chen tung
# buffer: moi buffer 2 lan full delay calc + refinePlace (~3.7 phut CPU); run
# 2026-09-17 20:00 KHOI 12 can 12 latch x 4 buffer = 48 lan, trong nhu lap mai.
proc soc_fix_cg_hold {{target 0.020} {cell HB4xp67_ASAP7_75t_R} {max_buf 8}} {
    set latches [dbGet -e top.insts.name cg_*/en_latch_reg]
    set nbuf [dict create]
    set final [dict create]
    foreach latch $latches {
        dict set nbuf $latch 0
    }
    set added 0
    set t0 [clock seconds]
    for {set round 1} {1} {incr round} {
        # Lenh report_timing dau tien sau vong truoc tu tinh lai tre (1 lan/vong)
        set todo {}
        foreach latch $latches {
            set slack ""
            set pin ""
            foreach_in_collection p [report_timing -early -through $latch/Q \
                    -max_paths 1 -collection] {
                set slack [get_property $p slack]
                set pin [get_object_name [get_property $p capturing_point]]
            }
            dict set final $latch [list $slack $pin]
            if {![string is double -strict $slack] || $slack >= $target ||
                [dict get $nbuf $latch] >= $max_buf || ![string match cg_* $pin]} {
                continue
            }
            lappend todo [list $latch $pin $slack]
        }
        puts [format "soc_fix_cg_hold vong %d (%d s): %d latch hold < %.3f" \
            $round [expr {[clock seconds] - $t0}] [llength $todo] $target]
        if {[llength $todo] == 0} {
            break
        }
        # -honorFixedNetWire false: day cua net clock do CCOpt route deu bi danh
        # dau FIXED, ecoAddRepeater tu choi voi IMPOPT-6228.  Chinh dong message
        # cua Innovus chi ra cach xu ly la tat co nay.
        #
        # Ban cu bat loi roi 'editDelete -net' ca net rui chen lai.  Run
        # 2026-09-20 cho thay day la cach xau:
        #   - 12 dong **ERROR trong innovus.log (dung 12 error cua ca run)
        #   - o KHOI 14 (SAU route) no xoa TOAN BO day cua 12 net clock da
        #     duoc CCOpt route va toi uu, roi de ecoRoute ve lai - ecoRoute
        #     khong biet gi ve skew/slew target cua CCOpt
        #   - keo theo 48 canh bao IMPOPT-3706 "RC data ... has been disabled"
        # Tat co FIXED thi ecoAddRepeater chi sua doan day quanh cho chen, phan
        # con lai cua cay clock giu nguyen.
        setEcoMode -batchMode true -refinePlace false -updateTiming false \
            -honorFixedNetWire false
        set failed [catch {
            foreach item $todo {
                lassign $item latch pin slack
                puts "  $latch slack $slack -> buffer thu [expr {[dict get $nbuf $latch] + 1}] truoc $pin"
                if {[catch {ecoAddRepeater -term [list $pin] -cell $cell} eco_err]} {
                    # Van hong (ban Innovus khong nhan -honorFixedNetWire, hoac
                    # day bi khoa vi ly do khac): quay ve cach cu - xoa day roi
                    # chen.  routeDesign / ecoRoute se route lai net do.
                    set net [get_object_name [get_nets -of_objects [get_pins $pin]]]
                    puts "  ecoAddRepeater hong ($eco_err)"
                    puts "  -> xoa day FIXED cua $net roi chen lai (day clock nay\
 se do ecoRoute ve lai, KHONG phai CCOpt)"
                    editDelete -net $net
                    ecoAddRepeater -term [list $pin] -cell $cell
                }
                dict incr nbuf $latch
                incr added
            }
        } msg opts]
        setEcoMode -batchMode false -refinePlace true -updateTiming true \
            -honorFixedNetWire true
        if {$failed} {
            return -options $opts $msg
        }
        refinePlace
    }
    puts "soc_fix_cg_hold: them $added $cell sau [expr {[clock seconds] - $t0}] s"
    foreach latch $latches {
        lassign [dict get $final $latch] slack pin
        puts [format "  %-28s hold slack %s sau %d buffer" $latch $slack [dict get $nbuf $latch]]
        if {[string is double -strict $slack] && $slack < $target} {
            puts "WARNING: chua sua duoc hold $latch -> $pin ($slack)"
        }
    }
    return $added
}

# In ra AI dang vi pham DRV, kem dong lenh va tay neu muon sua tung net.
#
# soc_drv_violators tra ve ca ten chan va cell/port nen o day suy nguoc duoc
# ten instance (cat phan sau dau '/' cuoi cung).  Truoc 2026-09-21 bao cao chi
# co so luong: 18:09 KHOI 14 dung voi "max_tran Real 1 net" va phai zcat
# reports/timing_postRoute/postRoute.tran.gz bang tay moi biet la net nao.
# detail 0 = chi so luong, 1 = liet ke net, 2 = liet ke kem dong lenh va tay.
# Vong lap goi 1 o lan phat hien dau va 2 o lan bo cuoc; cac vong giua chi can
# 0, neu khong log KHOI 14 lap lai y nguyen mot khoi ba lan lien.
proc soc_drv_report {dir prefix kinds {detail 1}} {
    set total 0
    foreach kind $kinds {
        set who [soc_drv_violators $dir $prefix $kind]
        incr total [llength $who]
        puts "  $kind: [llength $who] net vi pham that (remark R)"
        if {$detail < 1} {
            continue
        }
        foreach item [lrange $who 0 4] {
            lassign $item net slack pin cellport
            puts [format "    %-44s %+.3f ns" $net $slack]
            if {$pin eq ""} {
                continue
            }
            puts "      chan $pin ($cellport)"
            # KHONG dung 'file dirname': ten chan la duong dan cua Innovus chu
            # khong phai cua he dieu hanh.  Cat thu cong cho chac.
            set cut [string last / $pin]
            if {$detail >= 2 && $cut > 0} {
                puts "      va tay: ecoChangeCell -inst [string range $pin 0 [expr {$cut - 1}]]\
 -cell <ban drive lon hon>  ;# roi ecoRoute"
            }
        }
        if {[llength $who] > 5} {
            puts "    ... con [expr {[llength $who] - 5}] net"
        }
    }
    return $total
}

# Vong tu sua DRV that con lai sau route - cung khuon voi soc_fix_cg_hold:
# doc bao cao -> sua -> lap -> de cong kiem tra o cuoi khoi ket luan.
#
# VI SAO CAN.  KHOI 14 chay optDesign -postRoute -setup -hold -drv MOT lan,
# roi soc_fix_cg_hold + ecoRoute con chen them buffer va ve lai day.  So DRV ma
# timeDesign do SAU do la so chua tung duoc toi uu, va khong con luot nao nua.
# Run 2026-09-21 18:09 khoi dung o dung cho do:
#     max_tran Real 1 net: u_apb_cordic_state[0] (-0.001 ns)
#
# VI SAO CHI GOI LAI optDesign, KHONG DOI CELL.  Hom do da go tay
#     ecoChangeCell -inst FE_PHC26642_u_apb_cordic_state_0 -cell HB4xp67...
# roi paste lai ca KHOI 14 va het loi.  Nhung netlist xuat o KHOI 16 cho thay
# lenh do KHONG phai thu da sua: khong co instance nao ten FE_PHC26642_*
# cordic (FE_PHC26642_valid_arr_474_0 thi co, va van la HB1xp67), con net
# u_apb_cordic_state[0] gio chi con DUNG 1 chan tai la
# FE_PHC20086_u_apb_cordic_state_0 - VAN la HB2xp67, khong doi.  Thu that su
# sua duoc la LUOT optDesign -postRoute thu hai do paste lai khoi mang lai.
# Nen vong nay chi lam dung dieu do, khong doan cell nao thay cell nao.
#
# Them nua: ten instance kieu FE_PHC26642_* do Innovus sinh theo tung run, lan
# sau chay lai se khac - y het bai hoc cua SOC_DRC_WAIVE_NETS (xem
# soc_fp_config.tcl).  Mot dong ecoChangeCell go cung ten trong script se chet
# ngay lan chay ke tiep, nen no khong phai cach sua.
#
# KHONG BAO GIO LAM RUN XAU DI: moi buoc nam trong catch: hong thi in WARNING
# roi tra ve, de soc_check_timing -drv o cuoi KHOI 14 chan y nhu bay gio.
# Truong hop xau nhat bang dung hien trang (khoi dung, sua tay), khong te hon.
#
# LUU Y phien song: proc nay chi vao bo nho khi source soc_fp_procs.tcl (KHOI
# 0).  Paste KHOI 14 vao mot phien Innovus mo tu truoc ma chua re-source thi
# bao "invalid command name soc_fix_drv".
proc soc_fix_drv {dir prefix {max_round 2}} {
    set t0 [clock seconds]
    for {set round 0} {1} {incr round} {
        set sum [soc_timing_summary $dir $prefix setup]
        if {[llength $sum] == 0} {
            puts "WARNING: soc_fix_drv: khong doc duoc bang tom tat cua $prefix\
 trong $dir - bo qua, de soc_check_timing ket luan"
            return -1
        }
        set kinds {}
        foreach key [lsort [dict keys $sum drv_*]] {
            if {[dict get $sum $key] > 0} {
                lappend kinds [string range $key 4 end]
            }
        }
        if {[llength $kinds] == 0} {
            if {$round > 0} {
                puts "soc_fix_drv: het DRV that sau $round vong\
 ([expr {[clock seconds] - $t0}] s)"
            }
            return 0
        }
        if {$round >= $max_round} {
            puts "WARNING: soc_fix_drv: van con DRV that sau $max_round\
 vong toi uu - KHONG sua them:"
            set left [soc_drv_report $dir $prefix $kinds 2]
            puts "WARNING: soc_check_timing -drv o cuoi khoi se dung flow.\
  Sua theo dong 'va tay' o tren roi paste lai KHOI 14."
            return $left
        }
        if {$round == 0} {
            puts "soc_fix_drv: optDesign/ecoRoute cua khoi con de lai DRV that:"
            soc_drv_report $dir $prefix $kinds 1
        } else {
            soc_drv_report $dir $prefix $kinds 0
        }
        puts "soc_fix_drv: chay them optDesign -postRoute -drv (vong\
 [expr {$round + 1}]/$max_round) cho [join $kinds {, }]"
        if {[catch {
            optDesign -postRoute -drv -prefix ${prefix}_drv[expr {$round + 1}]
            # Cell moi/doi kich thuoc thi chua co day -> ecoRoute, roi don DRC
            # ma chinh no vua sinh ra.  Giong het doan sau soc_fix_cg_hold.
            ecoRoute
            ecoRoute -fix_drc
        } err]} {
            puts "WARNING: soc_fix_drv: optDesign/ecoRoute hong ($err) - giu\
 nguyen thiet ke, de soc_check_timing ket luan"
            return -1
        }
        # Do lai: soc_check_timing o cuoi khoi doc DUNG file nay, nen bang tom
        # tat bat buoc phai ta trang thai sau cung.
        if {[catch {timeDesign -postRoute -outDir $dir -prefix $prefix} err]} {
            puts "WARNING: soc_fix_drv: timeDesign hong ($err) - bao cao trong\
 $dir gio la cua trang thai CU, dung tin no"
            return -1
        }
    }
}

# Layer cua tung chan trong file LEF macro: dict {ten_chan {layer ...}}.
# Doc thang file LEF (khong qua dbGet libTerm) de biet chan vao duoc tu layer nao.
proc soc_lef_pin_layers {file} {
    set fp [open $file]
    set text [read $fp]
    close $fp
    set pins [dict create]
    set pin ""
    foreach line [split $text \n] {
        set w [regexp -inline -all {\S+} $line]
        switch -- [lindex $w 0] {
            PIN   { set pin [lindex $w 1] }
            OBS   { set pin "" }
            END   { if {[lindex $w 1] eq $pin} { set pin "" } }
            LAYER { if {$pin ne ""} { dict lappend pins $pin [lindex $w 1] } }
        }
    }
    return [dict map {name layers} $pins { lsort -unique $layers }]
}

# Chan M3 tren than SRAM truoc routeDesign.  Run 2026-09-17 (ca 2 lan): 14-31 loi
# "Cut Short V3 - Blockage of Cell <SRAM>" o giua than SRAM (chan rdata/wdata):
# LEF SRAM chan cut V3 nhung khong chan M3, NanoRoute di M3 tren SRAM roi ha via
# V3 vao chan -> ecoRoute -fix_drc khong go duoc.  Chan M3 thi phai vao chan tu
# M4/M5.
# Ban cu bo qua khi chan SRAM co hinh tren M3 -> run 2026-09-17 20:24 khong tao
# blockage nao (log: deleteRouteBlk IMPFP-6001, khong co createRouteBlk), van 25
# loi V3.  LEF 4x (asap7_sram_0p0 @ 522eecc) chan dataout[20]: stub M3 bi OBS M3
# bao kin, thanh M4 59.444-62.036, OBS V3 phu ca thanh tru via rieng o x 61.8.
# NanoRoute bo qua OBS nam trong hinh chan, ha V3 tu track M3 x 59.76 xuong thanh
# M4 -> verify_drc bao Cut Short.  Chan co hinh M4 vao duoc bang M4 / V4 tu M5
# nen chan M3 an toan.  LEF 256x4x32 co 64 chan CHI tren M3 (dataout[32..63],
# wd[32..63]) - SRAM 32 bit nen chung khong noi; chi bo chan M3 neu mot chan
# chi-M3 nao do co net that.
proc soc_sram_route_blk {} {
    set used {}
    foreach lef [list $::SRAM_LEF $::SRAM_TAG_LEF] master [list $::SRAM_MASTER $::SRAM_TAG_MASTER] {
        set m3_only {}
        dict for {pin layers} [soc_lef_pin_layers $lef] {
            if {[lsearch -regexp $layers {^M[4-9]$}] < 0} {
                lappend m3_only $pin
            }
        }
        puts "[file tail $lef]: [llength $m3_only] chan chi co tren M1-M3"
        foreach ptr [dbGet -e -p2 top.insts.cell.name $master] {
            set inst [lindex [dbGet $ptr.name] 0]
            foreach pin $m3_only {
                set p [get_pins -quiet [list $inst/$pin]]
                if {[sizeof_collection $p] > 0 &&
                    [sizeof_collection [get_nets -quiet -of_objects $p]] > 0} {
                    lappend used $inst/$pin
                }
            }
            if {[llength $used] > 0} {
                break
            }
        }
    }
    if {[llength $used] > 0} {
        puts "WARNING: chan SRAM chi-M3 co net ([lrange $used 0 4]) - KHONG chan M3"
        return 0
    }
    # Thu vao moi canh 0.288 (4 x M3 min width): route 2026-09-17 23:55 blockage
    # bang dung than SRAM -> 21 loi Metal Short M3 cao 0.056 ngay mep duoi SRAM
    # (dau day M3 qua via), NanoRoute khong go duoc.
    set d 0.288
    set n 0
    foreach b [soc_sram_boxes] {
        lassign $b name group x0 y0 x1 y1
        createRouteBlk -box [list [expr {$x0 + $d}] [expr {$y0 + $d}] \
            [expr {$x1 - $d}] [expr {$y1 - $d}]] -layer M3 -name soc_sram_m3
        incr n
    }
    puts "Chan M3 tren $n SRAM"
    return $n
}

# Chan PG cua top (09_PnR tr.21): moi net mot chan phu doan ring loi
# SOC_PG_PIN_LAYER nam tren cung.  Paste lai KHOI 2: chan da co thi giu nguyen.
proc soc_add_pg_pins {} {
    foreach net {VDD VSS} {
        if {![catch {dbGet -e top.pgTerms.name $net} have] && $have ne ""} {
            puts "Chan PG $net da co - bo qua"
            continue
        }
        set best {}
        foreach w [dbGet -e -p [dbGet -p top.nets.name $net].sWires.shape ring] {
            if {[dbGet $w.layer.name] ne $::SOC_PG_PIN_LAYER} {
                continue
            }
            set box [lindex [dbGet $w.box] 0]
            if {[llength $best] == 0 || [lindex $box 1] > [lindex $best 1]} {
                set best $box
            }
        }
        if {[llength $best] == 0} {
            error "Ring $net khong co doan $::SOC_PG_PIN_LAYER - chay lai KHOI 2"
        }
        createPGPin $net -geom $::SOC_PG_PIN_LAYER {*}$best
        puts [format "Chan PG %s: %s {%.3f %.3f %.3f %.3f}" $net $::SOC_PG_PIN_LAYER {*}$best]
    }
}

# Noi chan VDD/VSS, TIEHI/TIELO cua moi instance vao net.  Goi sau moi buoc
# them cell (tap KHOI 9, filler KHOI 15; CTS/optDesign chen buffer o giua).
proc soc_global_pg_connect {} {
    globalNetConnect VDD -type pgpin -pin VDD -inst * -override
    globalNetConnect VSS -type pgpin -pin VSS -inst * -override
    globalNetConnect VDD -type tiehi -inst * -override
    globalNetConnect VSS -type tielo -inst * -override
    applyGlobalNets
}

# Pitch track cua mot layer (um), doc tu LEF da nap.  Ten thuoc tinh dbGet doi
# giua cac ban Innovus nen thu lan luot; khong doc duoc thi tra 0.
proc soc_layer_pitch {layer} {
    if {[catch {dbGetLayerByName $layer} ptr] || $ptr eq "" || $ptr eq "0x0"} {
        return 0
    }
    foreach attr {pitchX pitch} {
        if {[catch {dbGet $ptr.$attr} v]} {
            continue
        }
        set v [lindex $v 0]
        if {[string is double -strict $v] && $v > 0} {
            return $v
        }
    }
    return 0
}

# CHI BAO CAO, KHONG CON CHAN - 2026-09-20.
#
# Ban cu bao error khi (gap + width) hoac (activeSpacing + width) khong chia
# het cho pitch, voi ly thuyet "buoc fill phai la boi cua pitch thi moi
# on-track".  Ly thuyet do da bi bac bo bang thuc nghiem:
#   - run 2026-09-19 dung 0.288/0.288 (chia het DUNG 2 pitch, guard PASS) van
#     ra 279674 OFFGRID -> dieu kien nay KHONG DU.
#   - run_workspace/sram_axi dung 0.192/0.192 (= 1.5 pitch, guard se BAO LOI)
#     lai cho drc_after_fill.rpt = "No DRC violations were found" -> dieu kien
#     nay cung KHONG CAN.
# Tuc guard dang chan dung bo so chay duoc.  Giu phan in so vi van huu ich khi
# doi chieu log, nhung bo error di.
#
# Cach thuc su tranh OFFGRID nam o -maxWidth / -decrement: M5.AUX.2 cua
# calibreDRC.rul chi ap cho M5 DUNG min width.  Xem soc_fp_config.tcl.
proc soc_fill_check_track {layer w gap active} {
    set pitch [soc_layer_pitch $layer]
    if {$pitch <= 0} {
        puts "  $layer: khong doc duoc pitch tu LEF - bo qua bao cao on-track"
        return
    }
    puts [format {  %s: pitch %.4f | buoc fill %.4f (%.2f track) | cach day that %.4f (%.2f track) | mat do toi da %.1f%%} \
        $layer $pitch \
        [expr {$gap + $w}]    [expr {($gap + $w) / $pitch}] \
        [expr {$active + $w}] [expr {($active + $w) / $pitch}] \
        [expr {100.0 * $w / ($gap + $w)}]]
}

# verify_drc + doc lai bao cao va phan loai.
#   soc_verify_drc <file> ?-limit N? ?-allow-nets {pattern ...}? ?-allow-types {pattern ...}?
# verify_drc DUNG GIUA CHUNG khi so vi pham cham -limit va chi ghi mot dong
# WARN IMPVFG-1103 o cuoi log - rat de bo sot.  Run 2026-09-18 dinh dung loi do:
# 100000 OFFGRID cua metal fill nuot het bao cao, khong biet con DRC that nao bi
# che.  Proc nay bien truong hop do thanh loi dung khoi.
# -allow-nets: net khop pattern (vd _FILLS_RESERVED) dem rieng, khong tinh vao
# so vi pham that -> tra ve so vi pham THAT de cho goi tu quyet dinh.
proc soc_verify_drc {report args} {
    set limit 1000000
    set allow {}
    set allow_types {}
    foreach {opt val} $args {
        switch -- $opt {
            -limit      { set limit $val }
            -allow-nets  { set allow $val }
            -allow-types { set allow_types $val }
            default     { error "soc_verify_drc: tuy chon la '$opt'" }
        }
    }
    clearDrc
    verify_drc -limit $limit -report $report

    set total 0
    set real  0
    set truncated 0
    array set bytype {}
    array set bynet  {}
    set fp [open $report r]
    while {[gets $fp line] >= 0} {
        if {[regexp {^\s*Total Violations\s*:\s*([0-9]+)} $line -> n]} {
            if {$n >= $limit} {
                set truncated $n
            }
            continue
        }
        if {![regexp {^([A-Z][A-Za-z_ ]*?)\s*:\s*(.*)$} $line -> type rest]} {
            continue
        }
        if {$type eq "Bounds"} {
            continue
        }
        incr total
        incr bytype($type)
        set net "-"
        regexp {of Net (\S+)} $rest -> net
        incr bynet($net)
        set skip 0
        foreach pat $allow {
            if {[string match $pat $net]} {
                set skip 1
                break
            }
        }
        # -allow-types thu hep waiver: phai khop CA net LAN loai vi pham moi bo
        # qua.  Run 2026-09-19 14:51: 279674 OFFGRID cua _FILLS_RESERVED.  Neu
        # waive ca net thi lan sau fill SHORT vao net that cung bi nuot theo -
        # dung cai nguy hiem that su.  Co -allow-types thi fill lech track duoc
        # bo qua con fill short / spacing van chan flow.
        if {$skip && [llength $allow_types] > 0} {
            set type_ok 0
            foreach tpat $allow_types {
                if {[string match $tpat $type]} {
                    set type_ok 1
                    break
                }
            }
            set skip $type_ok
        }
        if {!$skip} {
            incr real
        }
    }
    close $fp

    puts "--- $report"
    if {$total == 0} {
        puts "  0 vi pham"
    } else {
        foreach t [lsort [array names bytype]] {
            puts [format "  loai %-24s %8d" $t $bytype($t)]
        }
        set nets {}
        foreach n [array names bynet] {
            lappend nets [list $n $bynet($n)]
        }
        set nets [lsort -integer -decreasing -index 1 $nets]
        foreach item [lrange $nets 0 9] {
            puts [format "  net  %-24s %8d" [lindex $item 0] [lindex $item 1]]
        }
        if {[llength $nets] > 10} {
            puts "  ... con [expr {[llength $nets] - 10}] net nua"
        }
        set soc_waived [expr {$total - $real}]
        set soc_tdesc [expr {[llength $allow_types] ? $allow_types : {moi loai}}]
        puts "  -> $real vi pham that ($soc_waived bo qua: net {$allow}, loai {$soc_tdesc})"
    }
    if {$truncated} {
        error "verify_drc bi cat o -limit $limit (IMPVFG-1103): $report khong day\
du, KHONG ket luan duoc design sach DRC. Nang -limit, hoac xoa metal fill\
(deleteMetalFill) roi chay lai."
    }
    return $real
}

# Metal fill (09_PnR tr.26) tren cac layer SOC_FILL_LAYERS.  Bo so lay nguyen
# tu run_workspace/sram_axi - bo duy nhat trong repo nay cho drc sach sau fill.
# Giai thich day du o soc_fp_config.tcl.  Goi sau filler, truoc timing cuoi
# (fill lam tang C ghep) va SAU khi da verify_drc design that - fill sai co the
# nhan chim bao cao DRC.
#
# -maxWidth va -decrement la hai tham so quyet dinh, DUNG BO DI: chung cho
# Innovus thu cac be rong lon truoc (wmax, wmax-decr, ... ) roi moi ha xuong
# min width, nen da so mieng fill KHONG phai min width.  M5.AUX.2 cua
# calibreDRC.rul ("minimum width M5 tracks must lie along the vertical routing
# tracks") chi ap cho mieng dung min width, nen cach nay tranh duoc no.  Ban cu
# ep minWidth = maxWidth = 0.096 -> moi mieng deu min width -> 279674 OFFGRID.
proc soc_metal_fill {} {
    set layers {}
    # In ra so THUC SU dang dung: run 2026-09-18 chay so cu con trong RAM trong
    # khi file da sua, va tu log khong co cach nao biet dieu do.
    puts "soc_metal_fill: SOC_FILL_LAYERS = $::SOC_FILL_LAYERS"
    puts "soc_metal_fill: bao cao on-track (tham khao, khong con chan)"
    foreach {layer wmin wmax decr lmin lmax gap active dmin dmax dpref} \
            $::SOC_FILL_LAYERS {
        soc_fill_check_track $layer $wmin $gap $active
    }
    # setMetalFill giu thiet lap trong SESSION, khong phai trong file.  Luong
    # lam viec o day la paste tung KHOI vao mot phien Innovus dang chay: run
    # 2026-09-20 chay KHOI 15 luc 15:23 voi danh sach CHI M5, roi chay lai luc
    # 16:41 voi M1-M9 trong CUNG phien ("innovus 179>" -> "185>").  Khong reset
    # thi so cua lan paste truoc song sot o nhung layer lan nay khong dat lai -
    # dung loai bay da dinh voi soc_fp_config/soc_fp_procs (MEMORY: live
    # Innovus session keeps old tcl).  setFillerMode ngay tren da -reset, cho
    # nay thi chua.
    if {[catch {setMetalFill -reset} err]} {
        puts "WARNING: setMetalFill -reset: $err"
    }
    foreach {layer wmin wmax decr lmin lmax gap active dmin dmax dpref} \
            $::SOC_FILL_LAYERS {
        setMetalFill -layer $layer \
            -minWidth $wmin -maxWidth $wmax -decrement $decr \
            -minLength $lmin -maxLength $lmax \
            -activeSpacing $active -gapSpacing $gap \
            -minDensity $dmin -maxDensity $dmax -preferredDensity $dpref
        lappend layers $layer
    }
    addMetalFill -layer $layers -snap -squareShape
}

# addMetalFill tu ghi <design>.metalfill.rpt: so window duoi min / vuot max cua
# TUNG layer, truoc va sau khi fill.  Do la nguon so lieu DUY NHAT cho
# M1-M4/M6-M9, vi verifyMetalDensity chi chay tren SOC_DENSITY_LAYERS.
#
# Run 2026-09-20 16:41 khong co doan nao doc file nay, nen flow in "0 vi pham /
# PENDING" va ket luan sach, trong khi chinh file do ghi: M2 con 118 window
# duoi nguong, M4 38, M6 8, va M3 297 window VUOT tran (truoc fill 253 - tuc
# fill de THEM vao 44 window von da qua tran).  Anh chup layout thay thieu fill
# la dung; bao cao im lang moi la cai sai.
#
# Tra ve so layer con van de.  CHI canh bao, KHONG chan flow: bao cao nay khong
# co toa do window nen khong tach duoc "thap vi de len macro SRAM" (dung -
# addMetalFill khong dat duoc mieng nao len block instance) khoi "thap vi fill
# hong".  Viec tach do la cua soc_density_report tren density_all.rpt.
proc soc_fill_report {report {outfile ./verify_rpt/fill_summary.rpt}} {
    if {![file isfile $report]} {
        puts "WARNING: chua co $report - khong doc duoc ket qua addMetalFill"
        return -1
    }
    set fp [open $report r]
    set text [read $fp]
    close $fp

    # File co HAI khoi cung dinh dang: "Before filling" roi "After filling".
    set phase ""
    array set nunder {}
    array set nover  {}
    array set thr    {}
    foreach line [split $text "\n"] {
        if {[string match "*Before filling*" $line]} { set phase before ; continue }
        if {[string match "*After filling*"  $line]} { set phase after  ; continue }
        if {$phase eq ""} { continue }
        if {[regexp {^Layer\s+(\S+)\s+-\s+Number of windows under minimum density\s+\(([0-9]+)%\):\s+([0-9]+) out of total ([0-9]+)} \
                $line -> layer pct n total]} {
            set nunder($layer,$phase) $n
            set thr($layer,min)   $pct
            set thr($layer,total) $total
            continue
        }
        if {[regexp {^Layer\s+(\S+)\s+-\s+Number of windows over maximum density\s+\(([0-9]+)%\):\s+([0-9]+) out of total} \
                $line -> layer pct n]} {
            set nover($layer,$phase) $n
            set thr($layer,max) $pct
            continue
        }
    }

    set out {}
    lappend out "# soc_fill_report doc lai $report"
    lappend out "Ket qua addMetalFill theo tung layer.  Nguong cua layer ngoai\
 M5/Pad la so TU DAT trong SOC_FILL_LAYERS, khong phai luat foundry."
    lappend out "  layer   duoi min (truoc -> sau)      vuot max (truoc -> sau)"
    set bad 0
    foreach {layer wmin wmax decr lmin lmax gap active dmin dmax dpref} \
            $::SOC_FILL_LAYERS {
        # addMetalFill goi layer Pad la "M10" trong bao cao (chi so routing
        # layer), trong khi verifyMetalDensity lai goi dung ten "Pad".  Hai
        # lenh dat ten khac nhau cho CUNG mot layer.  Khong doi ten o day thi
        # bao cao ket luan sai "Pad chua duoc fill" trong khi no da fill sach
        # (run 18:27: M10 0/77 window duoi nguong 20%).
        set rl $layer
        if {$layer eq "Pad" && ![info exists thr($layer,total)]                 && [info exists thr(M10,total)]} {
            set rl M10
        }
        if {![info exists thr($rl,total)]} {
            lappend out [format {  %-5s KHONG co trong bao cao - layer nay chua duoc fill} $layer]
            incr bad
            continue
        }
        set bu [expr {[info exists nunder($rl,before)] ? $nunder($rl,before) : -1}]
        set au [expr {[info exists nunder($rl,after)]  ? $nunder($rl,after)  : -1}]
        set bo [expr {[info exists nover($rl,before)]  ? $nover($rl,before)  : -1}]
        set ao [expr {[info exists nover($rl,after)]   ? $nover($rl,after)   : -1}]
        set note ""
        if {$au > 0 || $ao > 0} { incr bad }
        if {$ao > $bo} { set note "   <- fill LAM TANG so window vuot tran" }
        lappend out [format {  %-5s %6d -> %-6d (min %2d%%)   %6d -> %-6d (max %2d%%)   /%d window%s} \
            $layer $bu $au $thr($rl,min) $bo $ao $thr($rl,max) $thr($rl,total) $note]
    }
    if {$bad > 0} {
        lappend out "WARNING: $bad layer chua dat nguong sau fill.  Doc tiep\
 verify_rpt/density_summary.rpt: o do window duoi nguong da duoc tach thanh\
 'de len macro SRAM' (P&R khong sua duoc) va 'trong vung logic' (moi la loi\
 cua metal fill)."
    } else {
        lappend out "  moi layer dat nguong sau fill"
    }
    foreach line $out { puts $line }
    if {[catch {
        set fp [open $outfile w]
        foreach line $out { puts $fp $line }
        close $fp
    } err]} {
        puts "WARNING: khong ghi duoc $outfile: $err"
    } else {
        puts "  da ghi $outfile"
    }
    return $bad
}

# Bao cao DRC phai ton tai va sach truoc khi xuat GDS.  Goi dau KHOI 16.
#
# KHONG tin dong "Total Violations" cua verify_drc: no dem CA nhung vi pham da
# duoc waive co chu dich trong soc_fp_config.tcl (SOC_DRC_WAIVE_*).  Truoc day
# cong nay doc thang con so do, nen KHOI 15 bao sach ma KHOI 16 van chan
# (run 2026-09-19 18:14: drc_final.rpt "Total Violations : 1" = dung cai
# OFFGRID M4 cua u_itcm/u_mem da nam trong SOC_DRC_WAIVE_NETS).
# Tu 2026-09-21 danh sach waive de RONG nen hai con so bang nhau; doan loc van
# giu vi day la cong cuoi cung truoc GDS.
# Phai dem lai tung dong theo DUNG cach soc_verify_drc dang loc -> doan parse
# duoi day lap lai soc_verify_drc (dong ~1331): SUA MOT BEN THI SUA CA HAI.
# Hai kiem tra cu van giu: file phai ton tai, va report phai co dong ket luan
# (chan report cut vi verify_drc chet giua chung).
proc soc_require_drc_clean {args} {
    set allow       {}
    set allow_types {}
    set reports     {}
    for {set i 0} {$i < [llength $args]} {incr i} {
        switch -- [lindex $args $i] {
            -allow-nets  { incr i ; set allow       [lindex $args $i] }
            -allow-types { incr i ; set allow_types [lindex $args $i] }
            default      { lappend reports [lindex $args $i] }
        }
    }
    foreach report $reports {
        if {![file isfile $report]} {
            error "Chua co $report - chay KHOI 15 truoc khi xuat file"
        }
        set verdict 0
        set real    0
        set waived  0
        set fp [open $report r]
        while {[gets $fp line] >= 0} {
            if {[regexp {^\s*Total Violations\s*:\s*[0-9]+} $line] ||
                [regexp {No DRC violations were found} $line]} {
                set verdict 1
                continue
            }
            if {![regexp {^([A-Z][A-Za-z_ ]*?)\s*:\s*(.*)$} $line -> type rest]} {
                continue
            }
            if {$type eq "Bounds"} {
                continue
            }
            set net "-"
            regexp {of Net (\S+)} $rest -> net
            set skip 0
            foreach pat $allow {
                if {[string match $pat $net]} { set skip 1 ; break }
            }
            # Giong soc_verify_drc: -allow-types thu hep waiver, phai khop CA
            # net LAN loai vi pham.  SHORT/SPACING tren chinh net duoc waive
            # van chan xuat GDS.
            if {$skip && [llength $allow_types] > 0} {
                set type_ok 0
                foreach tpat $allow_types {
                    if {[string match $tpat $type]} { set type_ok 1 ; break }
                }
                set skip $type_ok
            }
            if {$skip} { incr waived } else { incr real }
        # (soc_require_drc_clean dung chung logic loc voi soc_verify_drc)
        }
        close $fp
        if {!$verdict} {
            error "$report khong co dong ket luan nao (bao cao hong hoac verify_drc chua chay xong) - khong xuat GDS"
        }
        if {$real > 0} {
            error "$report con $real vi pham that (ngoai $waived da waive) - khong xuat GDS"
        }
        puts "  $report: sach ($waived vi pham waive theo SOC_DRC_WAIVE_* trong soc_fp_config.tcl)"
    }
}


# verifyMetalDensity kiem CA layer khong khai MINIMUMDENSITY trong tech LEF
# (Innovus ap mac dinh 20%).  Run 2026-09-18: 8863 "vi pham", 7719 la cua luat
# KHONG TON TAI trong PDK nay - chi M5 (15%) va Pad (20%) co luat that.
#
# 1144 window M5 con lai duoi 15% la that, nhung do voi 84 hop SRAM thi CA 1144
# deu de len macro (991 bi che >=75%, 150 che 50-75%, 3 che 25-50%, va KHONG
# window nao nam trong vung std cell thuan): addMetalFill khong dat mot mieng
# fill nao len tren macro.  Do tren LEF 4x that (2026-09-18): OBS cua SRAM phu
# kin M1/M2/M3/V1/V2/V3 nhung M5 CHI 0.9% dien tich macro o tag (bbox 27.6-44.1
# x 41.6-78.2) va 0.4% o ban 256x4x32 - nghia la M5 tren than SRAM gan nhu trong
# va OBS khong phai ly do.  addMetalFill tu coi ranh gioi block instance la vung
# cam.  Doi gapSpacing/activeSpacing khong lam giam con so nay.
# -> tach hai nhom.  Chi nhom "vung logic" moi la loi cua metal fill.
# Tham so: soc_density_report <report> ?-overlap f? ?-out file?
#                             ?-layers {M5 ...}? ?-status 0|1?
#   -layers  layer duoc doc tu <report> (mac dinh SOC_DENSITY_LAYERS).  Lan goi
#            bao cao (SOC_DENSITY_REPORT_LAYERS) dung danh sach rong hon.
#   -status  1 thi dat ::SOC_DENSITY_SIGNOFF_STATUS.  Lan goi bao cao dat 0 de
#            khong de len ket luan signoff cua lan goi chan (M5).
proc soc_density_report {report args} {
    set macro_overlap 0.25
    set outfile ./verify_rpt/density_summary.rpt
    set layers  $::SOC_DENSITY_LAYERS
    set status  1
    foreach {opt val} $args {
        switch -- $opt {
            -overlap { set macro_overlap $val }
            -out     { set outfile       $val }
            -layers  { set layers        $val }
            -status  { set status        $val }
            default  { error "soc_density_report: tuy chon la '$opt'" }
        }
    }
    if {![file isfile $report]} {
        puts "WARNING: chua co $report - bo qua doc mat do"
        return -1
    }
    set fp [open $report r]
    set text [read $fp]
    close $fp

    set boxes {}
    foreach b [soc_sram_boxes] {
        lassign $b name group x0 y0 x1 y1
        lappend boxes [list $x0 $y0 $x1 $y1]
    }

    # Nguong nam o phan header cua bao cao:
    #   # Layer       M5 - Min Density      : 15%
    # Phai doc chung de tach "duoi min" khoi "vuot max".  verifyMetalDensity
    # liet ke CA HAI loai trong cung mot bang, va truoc 2026-09-20 doan nay dem
    # gop roi gan nhan "duoi nguong" cho tat ca -> 297 window M3 VUOT tran 60%
    # bi bao thanh "duoi nguong tren macro SRAM" (density_all_summary.rpt cua
    # run 18:27).  Hai loai nay nguyen nhan khac han nhau:
    #   duoi min : fill chua voi toi - dung de hoi "fill du chua"
    #   vuot max : fill do them vao window von da qua tran (cua so chong nhau
    #              50% nen fill o window ke van roi vao day) - khong lien quan
    #              gi den phep chia macro/logic, nen khong dua vao phep do.
    array set thr_max {}
    foreach line [split $text "\n"] {
        if {[regexp {^#\s*Layer\s+(\S+)\s+-\s+Max Density\s*:\s*([0-9.]+)%} \
                $line -> l v]} {
            set thr_max($l) $v
        }
    }

    set skipped 0
    array set n_macro {}
    array set n_logic {}
    array set n_over  {}
    array set worst  {}
    foreach line [split $text "\n"] {
        if {![regexp {^\s*(\S+)\s+([0-9.]+)\s+\(([-0-9.]+)\s+([-0-9.]+)\)\s+\(([-0-9.]+)\s+([-0-9.]+)\)} \
                $line -> layer dens wx0 wy0 wx1 wy1]} {
            continue
        }
        if {[lsearch -exact $layers $layer] < 0} {
            incr skipped
            continue
        }
        if {[info exists thr_max($layer)] && $dens > $thr_max($layer)} {
            incr n_over($layer)
            continue
        }
        set area [expr {($wx1 - $wx0) * ($wy1 - $wy0)}]
        set cover 0.0
        foreach box $boxes {
            lassign $box bx0 by0 bx1 by1
            set ix [expr {min($wx1, $bx1) - max($wx0, $bx0)}]
            set iy [expr {min($wy1, $by1) - max($wy0, $by0)}]
            if {$ix > 0 && $iy > 0} {
                set cover [expr {$cover + $ix * $iy}]
            }
        }
        if {$area > 0 && $cover / $area >= $macro_overlap} {
            incr n_macro($layer)
        } else {
            incr n_logic($layer)
            if {![info exists worst($layer)] || $dens < $worst($layer)} {
                set worst($layer) $dens
            }
        }
    }
    # Ket qua di ca ra man hinh LAN ra file.  puts cua proc KHONG vao
    # innovus.log, nen truoc day chay xong roi khong co cach nao doc lai phan
    # loai macro/logic tu log (run 2026-09-19).
    set total_logic 0
    set total_macro 0
    set out {}
    lappend out "Mat do - layer doc: $layers"
    set total_over 0
    foreach layer $layers {
        set m [expr {[info exists n_macro($layer)] ? $n_macro($layer) : 0}]
        set l [expr {[info exists n_logic($layer)] ? $n_logic($layer) : 0}]
        set o [expr {[info exists n_over($layer)]  ? $n_over($layer)  : 0}]
        incr total_logic $l
        incr total_macro $m
        incr total_over  $o
        set tail ""
        if {$l > 0} {
            set tail [format " (thap nhat %.2f%%)" $worst($layer)]
        }
        if {$o > 0} {
            set tail "$tail | $o window VUOT tran"
        }
        lappend out [format {  %-4s duoi min: %d tren macro SRAM + %d trong vung logic%s} \
            $layer $m $l $tail]
    }
    if {$total_over > 0} {
        lappend out "  $total_over window vuot tran mat do: fill do them vao window\
 von da qua tran (cua so chong nhau 50%).  Chi cac layer co MAXIMUMDENSITY that\
 trong tech LEF moi dang lo - ASAP7 chi co M5 (90%) va Pad (80%)."
    }
    if {$skipped > 0} {
        lappend out "  bo qua $skipped window cua layer khong co luat mat do trong tech LEF"
    }
    if {$total_logic > 0} {
        lappend out "WARNING: $total_logic window vung logic duoi nguong - metal fill\
 chua du, xem lai SOC_FILL_LAYERS (nhat la -maxWidth / -decrement)"
    } else {
        lappend out "  vung logic: dat nguong o moi window"
    }
    # Window de len macro KHONG ket luan duoc tu day.  ASAP7 khong ship GDS cho
    # SRAM, Innovus chi thay OBS trong LEF (M5 phu ~0.9% dien tich macro) chu
    # khong thay metal that ben trong; va addMetalFill khong dat duoc gi len
    # block instance.  Nen nhom nay luon doc ra thap du fill co tot den dau.
    # Giong sram_axi/innovus/tcl/add_fill_and_verify.tcl: danh dau tam, de
    # signoff tren GDS da merge (Calibre/Pegasus) phan xu.
    if {$total_macro > 0} {
        if {$status} { set ::SOC_DENSITY_SIGNOFF_STATUS PENDING_MERGED_GDS_SIGNOFF }
        lappend out "  $total_macro window de len macro SRAM:\
 PENDING_MERGED_GDS_SIGNOFF (abstract khong co metal trong macro)"
    } elseif {$status} {
        set ::SOC_DENSITY_SIGNOFF_STATUS OK
    }
    foreach line $out { puts $line }
    # File nay di kem handoff.  Nguoi doc sau phai hieu duoc con so PENDING ma
    # khong can mo lai ca flow, nen ghi luon ly do va dieu kien dong.
    set why {}
    if {$total_macro > 0} {
        lappend why ""
        lappend why "# Vi sao nhom tren macro khong ket luan duoc o day"
        lappend why "#   - Density la luat CMP tren WAFER, phai signoff tren GDS da merge"
        lappend why "#     (GDS macro + GDS top) bang Calibre/Pegasus, khong phai tren view"
        lappend why "#     abstract cua P&R."
        lappend why "#   - Innovus chi thay LEF cua SRAM: OBS chan kin M1-M3/V1-V3 nhung M4"
        lappend why "#     chi 0.6% va M5 chi 0.4% dien tich macro.  Ruot macro khong co hinh"
        lappend why "#     nen mat do doc ra luon thap, du fill co tot den dau."
        lappend why "#   - ASAP7 KHONG ship GDS cho SRAM, nen lan signoff do hien chua chay"
        lappend why "#     duoc.  Trang thai trung thuc la PENDING, khong phai PASS/FAIL."
        lappend why "#   - KHONG nhoi fill len macro de lam xanh con so: do la PASS gia, no"
        lappend why "#     xoa mat co bao con viec chua kiem, va dat 25% kim loai len mang"
        lappend why "#     nho la rui ro coupling doi lay mot con so khong kiem chung duoc."
        lappend why "#     OBS trong tren M4/M5 la giay phep ROUTE qua, khong phai giay phep FILL."
        lappend why "#   - Ty le window hong bam sat ty le dien tich macro tren die:"
        lappend why "#     mcu 53.9% macro -> 56.9% window; sram_axi 70.5% macro -> 70.5% window."
        lappend why "#     Do la dac tinh cua floorplan nhieu macro, khong phai loi cua fill."
        lappend why "# Dieu kien DONG: co GDS that cua SRAM -> merge -> chay density tren do."
        lappend why "# Chi so co nghia o buoc nay la vung logic (phan minh dat duoc fill):"
        lappend why "#   $total_logic window duoi nguong -> phai bang 0 thi flow moi di tiep."
    }
    if {[catch {
        set fp [open $outfile w]
        puts $fp "# soc_density_report doc lai $report"
        foreach line $out { puts $fp $line }
        foreach line $why { puts $fp $line }
        close $fp
    } err]} {
        puts "WARNING: khong ghi duoc $outfile: $err"
    } else {
        puts "  da ghi $outfile"
    }
    return $total_logic
}

# LEF SRAM lech grid / SITE khong ton tai di THANG vao GDS (streamOut
# -outputMacros lay hinh macro tu LEF vi asap7_sram_0p0 khong co GDS rieng).
# preflight.tcl chi canh bao; cho nay chan.  Goi dau KHOI 16.
proc soc_require_sram_lef_clean {} {
    foreach v {MFG_GRID KNOWN_SITES} {
        if {![info exists ::$v]} {
            error "soc_require_sram_lef_clean: thieu ::$v - preflight.tcl chua chay (KHOI 0)"
        }
    }
    foreach lef [list $::SRAM_LEF $::SRAM_TAG_LEF] {
        lassign [check_lef_grid_site [read_binary_file $lef "SRAM 4x LEF"] \
            $::MFG_GRID $::KNOWN_SITES] offgrid bad_sites
        if {$offgrid > 0 || [llength $bad_sites] > 0} {
            error "[file tail $lef]: $offgrid toa do lech manufacturing grid\
 $::MFG_GRID, SITE khong dinh nghia ([join $bad_sites {, }]) - hinh nay se di\
 thang vao GDS.  Chay scripts/fix_sram_lef.py --fix, tro\
 ASAP7_SRAM_TAG_LEF_FILE / ASAP7_SRAM_LEF_FILE sang ban da sua, roi chay lai tu KHOI 0."
        }
        puts "  [file tail $lef]: toa do tren grid, SITE hop le"
    }
}
# Ten LEF/DEF co ky tu sau bus-bit (vd 'G_SRAM_BANK[31].u_sram' tu generate
# block) khong phai ten Verilog hop le: saveNetlist ghi thanh escaped name
# '\G_SRAM_BANK[31].u_sram ' (co dau cach cuoi).  Innovus bao IMPDB-2125, run
# 2026-09-18 bi vuot muc hien thi 20 message nen so that lon hon nhieu.
# Khong phai loi, nhung deck LVS/LEC phai biet truoc -> ghi ra file.
proc soc_report_escaped_names {file} {
    set fp [open $file w]
    set total 0
    foreach kind {insts nets} {
        foreach name [dbGet -e top.$kind.name] {
            if {[regexp {\[[0-9]+\][^ ]} $name]} {
                puts $fp "$kind $name"
                incr total
            }
        }
    }
    close $fp
    puts "Ten se bi escape khi ghi netlist: $total (xem $file)"
    if {$total > 0} {
        puts "  -> ten trong .v bi escape (them backslash o dau, them mot dau"
        puts "     cach o cuoi) nen khong khop truc tiep ten trong DEF/GDS."
        puts "     Khai bao cho LVS / Conformal truoc khi so netlist."
    }
    return $total
}

# File map layer cho streamOut (09_PnR tr.11 A2GDS.map), so lay tu SOC_GDS_LAYERS.
# Khong ghi LEFOBS: vung cam trong LEF abstract SRAM (-outputMacros) khong phai
# kim loai that, ghi ra thanh short gia khi DRC/LVS.
proc soc_write_gds_map {file} {
    set fp [open $file w]
    foreach {layer num} $::SOC_GDS_LAYERS {
        if {[string match {V[0-9]} $layer]} {
            set types {VIA VIAFILL}
        } else {
            set types {NET SPNET PIN LEFPIN FILL VIA VIAFILL}
        }
        foreach t $types {
            puts $fp "$layer $t $num 0"
        }
        if {![string match {V[0-9]} $layer]} {
            puts $fp "NAME $layer/PIN $num $::SOC_GDS_PIN_TEXT"
        }
    }
    close $fp
}
