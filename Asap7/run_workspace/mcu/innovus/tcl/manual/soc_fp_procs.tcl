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
    if {$::MCU_CORE_WIDTH_OVERRIDE > 0.0} {
        set core_w $::MCU_CORE_WIDTH_OVERRIDE
    }
    if {$::MCU_CORE_HEIGHT_OVERRIDE > 0.0} {
        set core_h $::MCU_CORE_HEIGHT_OVERRIDE
    }
    set core_w [soc_snap_up $core_w $::SOC_SITE_W]
    set core_h [soc_snap_up $core_h $::SOC_ROW_H]

    set L [dict create core_w $core_w core_h $core_h]
    dict set L RAM_LO [list $E $E $W(RAM_LO) $H(RAM_LO)]
    dict set L RAM_HI [list [expr {$core_w - $E - $W(RAM_HI)}] $E $W(RAM_HI) $H(RAM_HI)]
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
    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx0 cy0 cx1 cy1
    if {$x0 < $cx0 - $eps || $y0 < $cy0 - $eps || $x1 > $cx1 + $eps || $y1 > $cy1 + $eps} {
        error [format "Cum %s {%.3f %.3f %.3f %.3f} phai cach mep loi >= %.2f um de co cho cap VSS/VDD - keo vao trong (LAM TAY 1) roi paste lai KHOI 4" \
            $label [expr {$x0 + $G}] $ymin [expr {$x1 - $G}] $ymax $G]
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

# Luoi toan chip: M7 doc (via len ring M8), M6 ngang (via xuong M5 de an vao
# canh doc cua block ring SRAM).  Stripe dung o block ring.
proc soc_add_mesh {} {
    setAddStripeMode -reset
    setAddStripeMode -allow_jog none -break_at {block_ring} -split_vias true \
        -via_using_exact_crossover_size false \
        -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
    addStripe -nets {VDD VSS} -layer M7 -direction vertical \
        -width $::SOC_MESH_W -spacing $::SOC_MESH_S \
        -set_to_set_distance $::SOC_MESH_PITCH \
        -start_from left -start_offset $::SOC_MESH_OFFSET \
        -snap_wire_center_to_grid Grid

    setAddStripeMode -reset
    setAddStripeMode -allow_jog none -break_at {block_ring} -split_vias true \
        -via_using_exact_crossover_size false \
        -stacked_via_bottom_layer M5 -stacked_via_top_layer M7
    addStripe -nets {VDD VSS} -layer M6 -direction horizontal \
        -width $::SOC_MESH_W -spacing $::SOC_MESH_S \
        -set_to_set_distance $::SOC_MESH_PITCH \
        -start_from bottom -start_offset $::SOC_MESH_OFFSET \
        -snap_wire_center_to_grid Grid
}

# Rail M1 + stripe M5 cho std cell.  Flow Risc_V lam buoc nay SAU placement;
# lam truoc placement voi strap thap da gay short VDD/VSS o flow do.
proc soc_stdcell_rails {} {
    set die  [lindex [dbGet top.fPlan.box] 0]
    set core [lindex [dbGet top.fPlan.coreBox] 0]
    setAddStripeMode -reset
    setAddStripeMode \
        -allow_jog none \
        -allow_nonpreferred_dir none \
        -break_at {block_ring} \
        -extend_to_closest_target area_boundary \
        -stacked_via_bottom_layer M1 \
        -stacked_via_top_layer M6
    addStripe -nets {VDD VSS} \
        -layer M5 -direction vertical \
        -width $::SOC_M5_W -spacing $::SOC_M5_S \
        -set_to_set_distance $::SOC_M5_PITCH \
        -start_from left -start_offset $::SOC_M5_OFFSET \
        -create_pins 0 \
        -area [list [lindex $core 0] [lindex $die 1] [lindex $core 2] [lindex $die 3]] \
        -snap_wire_center_to_grid Grid \
        -allow_snapping_override_custom_spacing 1

    setSrouteMode -reset
    setSrouteMode -viaConnectToShape {stripe blockring}
    sroute -nets {VDD VSS} \
        -connect {corePin} \
        -corePinTarget {stripe} \
        -corePinCheckStdcellGeoms \
        -allowJogging 0 \
        -allowLayerChange 0
    editTrim -nets {VDD VSS}
}
