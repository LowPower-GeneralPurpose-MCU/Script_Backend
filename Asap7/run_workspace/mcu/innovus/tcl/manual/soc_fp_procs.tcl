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

# Guide mam theo hang (0 duoi -> 2 tren) trong vung logic.  Ban se sua trong GUI.
proc soc_create_guides {L areas} {
    lassign [dict get $L logic] lx0 ly0 lx1 ly1
    set core_llx [dbGet top.fPlan.coreBox_llx]
    set core_lly [dbGet top.fPlan.coreBox_lly]
    set region_w [expr {$lx1 - $lx0}]
    set y $ly0
    foreach row {0 1 2} {
        set members {}
        set row_area 0.0
        set side 0.0
        foreach {hinst r} $::SOC_GUIDES {
            if {$r != $row} {
                continue
            }
            if {![dict exists $areas $hinst]} {
                error "Guide $hinst: khong co std cell nao ten '$hinst/...'"
            }
            set a [expr {[dict get $areas $hinst] / $::SOC_GUIDE_TARGET_UTIL}]
            lappend members $hinst $a
            set row_area [expr {$row_area + $a}]
            set side [expr {max($side, sqrt($a))}]
        }
        if {[llength $members] == 0} {
            continue
        }
        set row_h [expr {max($side, $row_area / $region_w)}]
        set row_w [expr {$row_area / $row_h}]
        set x [expr {$lx0 + ($region_w - $row_w) / 2.0}]
        foreach {hinst a} $members {
            set w [expr {$a / $row_h}]
            set box [list [expr {$core_llx + $x}] [expr {$core_lly + $y}] \
                [expr {$core_llx + $x + $w}] [expr {$core_lly + $y + $row_h}]]
            createGuide $hinst {*}$box
            puts [format "Guide %-28s %8.1f x %-8.1f tai (%.1f, %.1f)" \
                $hinst $w $row_h [lindex $box 0] [lindex $box 1]]
            set x [expr {$x + $w}]
        }
        set y [expr {$y + $row_h + $::SOC_GROUP_GAP / 2.0}]
    }
    if {$y > $ly1} {
        puts "WARNING: guide vuot vung logic ([format %.1f $y] > $ly1) - tang chieu cao loi hoac sap lai"
    }
}

# Mat do guide = std cell cua module / dien tich guide (Hierarchy trang 28).
# Tra ve so guide >= SOC_GUIDE_MAX_UTIL.
proc soc_report_guides {areas report} {
    set bad 0
    set fp [open $report w]
    puts $fp [format "%-30s %12s %12s %7s" guide std_area guide_area util]
    set guides [dbGet -p top.fPlan.guides]
    if {$guides eq "0x0"} {
        set guides {}
    }
    foreach guide_ptr $guides {
        set name [lindex [dbGet $guide_ptr.name] 0]
        lassign [lindex [dbGet $guide_ptr.box] 0] x0 y0 x1 y1
        set garea [expr {($x1 - $x0) * ($y1 - $y0)}]
        if {![dict exists $areas $name]} {
            set line [format "%-30s %12s %12.1f %7s  (khong khop ten instance cap 1)" $name ? $garea ?]
        } else {
            set sarea [dict get $areas $name]
            set util [expr {$garea > 0 ? $sarea / $garea : 0.0}]
            set flag ""
            if {$util >= $::SOC_GUIDE_MAX_UTIL} {
                set flag "  <-- qua [expr {int($::SOC_GUIDE_MAX_UTIL * 100)}]%"
                incr bad
            }
            set line [format "%-30s %12.1f %12.1f %6.1f%%%s" $name $sarea $garea [expr {100 * $util}] $flag]
        }
        puts $fp $line
        puts $line
    }
    close $fp
    return $bad
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
