############################################################
## Proc dung chung cho tcl/manual/innovus_soc.tcl
## Can soc_fp_config.tcl va project_config.tcl da source.
############################################################

proc soc_banner {text} {
    puts "============================================================"
    puts $text
    puts "============================================================"
}

# Chay mot khoi lenh o muc global.  Lenh nao loi thi ca khoi dung ngay, ke ca
# khi khoi duoc paste vao console (paste tung dong thi lenh sau van chay).
proc soc_block {title body} {
    soc_banner ">>> $title"
    uplevel #0 $body
    puts ">>> XONG: $title"
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

# Kich thuoc mot cum khi xep cols x rows voi khe SOC_MACRO_GAP.
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
            [expr {$used_cols * $w + ($used_cols - 1) * $gap}] \
            [expr {$used_rows * $h + ($used_rows - 1) * $gap}] \
            $w $h $used_rows]
    }
    error "Khong co nhom SRAM '$group'"
}

# Dien tich std cell (khong tinh macro) theo instance cap 1.
proc soc_std_area_by_top_inst {} {
    set ptrs [dbGet -p2 top.insts.cell.baseClass core]
    set areas [dict create]
    # libCell khong co thuoc tinh 'area' (IMPDBTCL-204) -> size_x * size_y
    foreach inst [dbGet $ptrs.name] sx [dbGet $ptrs.cell.size_x] sy [dbGet $ptrs.cell.size_y] {
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

# Xep mot cum theo cot: cot chan R0, cot le MY, de chan SRAM hai cot ke nhau
# quay vao nhau (Hierarchy trang 35).  status: placed (keo duoc) | fixed.
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
        set x [soc_snap_near [expr {$core_llx + $x0 + $col * ($w + $gap)}] $core_llx $::SOC_SITE_W]
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
            error "Ring loi $net thieu (M8=$n8 M9=$n9) - chua chay KHOI 2 hoac addRing loi (xem innovus.log)"
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

# Nap file cua soc_save_sram_place; loi neu loi (core) khac luc luu.
proc soc_load_sram_place {{file ""}} {
    if {$file eq ""} {
        set file $::SOC_SRAM_PLACE_FILE
    }
    uplevel #0 [list source $file]
    set saved $::SOC_SRAM_PLACE_CORE
    set now [lindex [dbGet top.fPlan.coreBox] 0]
    foreach a $saved b $now {
        if {abs($a - $b) > 1e-3} {
            error "Loi hien tai {$now} khac loi luc luu {$saved} - xoa $file de xep mam lai"
        }
    }
    set expected [expr {$::SRAM_EXPECTED_COUNT + $::SRAM_TAG_EXPECTED_COUNT}]
    if {[llength $::SOC_SRAM_PLACE] != $expected} {
        error "$file co [llength $::SOC_SRAM_PLACE] SRAM, netlist co $expected"
    }
    foreach entry $::SOC_SRAM_PLACE {
        lassign $entry name x y orient
        set ptr [dbGet -e -p top.insts.name $name]
        if {$ptr eq ""} {
            error "$file: khong co instance $name"
        }
        dbSet $ptr.pStatus unplaced
        placeInstance $name $x $y $orient
        dbSet $ptr.pStatus placed
    }
    return [llength $::SOC_SRAM_PLACE]
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
    if {$extra} {
        foreach k $keepouts {
            lassign $k kx0 ky0 kx1 ky1
            lassign [expr {$dir eq "vertical" ? [list $kx0 $kx1] : [list $ky0 $ky1]}] a0 a1
            foreach p [list [expr {$a0 - 2.0 * $E - $pair}] [expr {$a1 + 2.0 * $E}]] {
                if {$p < $c0 || $p + $pair > $c1} {
                    continue
                }
                set near 0
                foreach q $edge_pos {
                    if {abs($p - $q) < $pair + $S} {
                        set near 1
                    }
                }
                if {!$near} {
                    lappend edge_pos $p
                }
            }
        }
    }
    set positions $edge_pos
    for {set pos [expr {$c0 + $offset}]} {$pos + $pair <= $c1 + 1e-6} \
        {set pos [expr {$pos + $pitch}]} {
        set near 0
        foreach q $edge_pos {
            if {abs($pos - $q) < $pair + $S} {
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
        set free {}
        foreach iv [soc_free_intervals $s0 $s1 $blocked] {
            if {[lindex $iv 1] - [lindex $iv 0] >= $min_len} {
                lappend free $iv
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

# Rail M1 + stripe M5 cho std cell.  Flow Risc_V/sram_axi lam SAU placement;
# lam truoc placement voi strap thap da gay short VDD/VSS o flow Risc_V.
#   1. sroute followpin M1 theo row (row trong vung SRAM da cutRow o KHOI 9)
#   2. M5 doc pitch 25.92, KHONG di vao cum SRAM + khe mep cum; them 1 cap sat
#      moi canh cum de kenh hep giua hai cum van duoc noi.  Via M1->M6 tai
#      giao diem voi rail M1 va luoi M6 (KHOI 6).
proc soc_stdcell_rails {} {
    setSrouteMode -reset
    setSrouteMode -viaConnectToShape {ring stripe blockring}
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
    set keepouts [soc_sram_no_std_boxes]
    set n5 [soc_mesh_layer M5 vertical $keepouts \
        [list $::SOC_M5_W $::SOC_M5_S $::SOC_M5_PITCH $::SOC_M5_OFFSET] 1]
    puts "Stripe M5 std cell: $n5 vung (tranh [llength $keepouts] cum SRAM + khe)"
    editTrim -nets {VDD VSS}
}
