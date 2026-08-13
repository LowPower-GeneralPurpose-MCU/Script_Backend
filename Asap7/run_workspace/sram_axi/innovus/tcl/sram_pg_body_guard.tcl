############################################################
## SRAM top-level PG body-overlap guard
##
## This checker separates hard-macro LEF pin/rail geometry from top-level
## special-route wires.  The regular core/upper PG mesh must stay outside
## every SRAM macro body; local SRAM island collectors are limited to gaps
## and halo channels.
############################################################

foreach required_variable {
    SRAM_MASTER
    SRAM_COUNT
    SRAM_ROWS
    SRAM_COLS
    SRAM_X0
    SRAM_Y0
    SRAM_W
    SRAM_H
    SRAM_MACRO_GAP_X
    SRAM_MACRO_GAP_Y
    SRAM_ISLAND_LLX
    SRAM_ISLAND_LLY
    SRAM_ISLAND_URX
    SRAM_ISLAND_URY
    SRAM_ISLAND_CUT_LLX
    SRAM_ISLAND_CUT_LLY
    SRAM_ISLAND_CUT_URX
    SRAM_ISLAND_CUT_URY
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable before SRAM PG body-overlap guard"
    }
}

proc sram_pg_box_valid {box} {
    if {[llength $box] != 4} {
        return 0
    }
    foreach value $box {
        if {![string is double -strict $value]} {
            return 0
        }
    }
    lassign $box llx lly urx ury
    return [expr {$urx > $llx && $ury > $lly}]
}

proc sram_pg_box_overlap_area {box_a box_b} {
    lassign $box_a a_llx a_lly a_urx a_ury
    lassign $box_b b_llx b_lly b_urx b_ury

    set overlap_llx [expr {max($a_llx, $b_llx)}]
    set overlap_lly [expr {max($a_lly, $b_lly)}]
    set overlap_urx [expr {min($a_urx, $b_urx)}]
    set overlap_ury [expr {min($a_ury, $b_ury)}]

    if {$overlap_urx <= $overlap_llx ||
        $overlap_ury <= $overlap_lly} {
        return 0.0
    }

    return [expr {($overlap_urx - $overlap_llx) *
                  ($overlap_ury - $overlap_lly)}]
}

proc sram_pg_dbget_scalar {query default_value} {
    if {[catch {dbGet $query} value]} {
        return $default_value
    }
    set flat [join $value]
    if {$flat eq "" || $flat eq "0x0"} {
        return $default_value
    }
    return [lindex $flat 0]
}

proc sram_pg_macro_body_boxes {} {
    global SRAM_MASTER SRAM_COUNT

    set ptrs [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
    if {$ptrs eq "" || $ptrs eq "0x0"} {
        error "No SRAM instances found while checking top-level PG body overlap"
    }
    if {[llength $ptrs] != $SRAM_COUNT} {
        error "Expected $SRAM_COUNT SRAM macros in body-overlap guard; found [llength $ptrs]"
    }

    set macro_boxes {}
    foreach ptr $ptrs {
        set macro_name [lindex [dbGet $ptr.name] 0]
        set macro_box [join [dbGet $ptr.box]]
        if {![sram_pg_box_valid $macro_box]} {
            error "Cannot decode SRAM macro body box for $macro_name: $macro_box"
        }
        lappend macro_boxes [list $macro_name $macro_box]
    }

    return $macro_boxes
}

proc sram_pg_collect_body_overlaps {{nets {VDD VSS}} {layers {M1 M2 M3 M4 M5 M6 M7 M8 M9}}} {
    set macro_boxes [sram_pg_macro_body_boxes]
    set overlap_records {}

    foreach net $nets {
        set net_ptr [lindex [dbGet -p top.nets.name $net] 0]
        if {$net_ptr eq "" || $net_ptr eq "0x0"} {
            continue
        }

        foreach layer $layers {
            if {[catch {dbGet -p2 $net_ptr.sWires.layer.name $layer} wire_ptrs]} {
                continue
            }
            if {$wire_ptrs eq "" || $wire_ptrs eq "0x0"} {
                continue
            }

            foreach wire_ptr $wire_ptrs {
                if {$wire_ptr eq "" || $wire_ptr eq "0x0"} {
                    continue
                }

                set wire_box [join [dbGet $wire_ptr.box]]
                if {![sram_pg_box_valid $wire_box]} {
                    continue
                }

                set shape [sram_pg_dbget_scalar $wire_ptr.shape NA]
                set status [sram_pg_dbget_scalar $wire_ptr.status NA]

                foreach macro_record $macro_boxes {
                    lassign $macro_record macro_name macro_box
                    set overlap_area \
                        [sram_pg_box_overlap_area $wire_box $macro_box]
                    if {$overlap_area > 0.0} {
                        lappend overlap_records [list \
                            $net $layer $macro_name $overlap_area \
                            $shape $status $wire_box $macro_box]
                    }
                }
            }
        }
    }

    return $overlap_records
}

proc sram_pg_write_body_overlap_report {report_path overlap_records} {
    file mkdir [file dirname $report_path]

    set fh [open $report_path w]
    puts $fh "# Top-level VDD/VSS special-wire overlap with SRAM macro bodies"
    puts $fh "# LEF pin/OBS geometry inside the hard macro is not scanned here."
    puts $fh "net layer macro overlap_um2 shape status wire_box macro_box"
    foreach record $overlap_records {
        lassign $record net layer macro_name overlap_area shape status \
            wire_box macro_box
        puts $fh [format "%s %s %s %.6f %s %s {%s} {%s}" \
            $net $layer $macro_name $overlap_area $shape $status \
            [join $wire_box { }] [join $macro_box { }]]
    }
    puts $fh [format "SUMMARY total_overlap_records %d" \
        [llength $overlap_records]]
    close $fh
}

proc sram_pg_list_contains {values needle} {
    return [expr {[lsearch -exact $values $needle] >= 0}]
}

proc sram_pg_body_guard_after_post_place {
    report_path
    {strict_layers {M6 M7 M8 M9}}
} {
    set all_layers {M1 M2 M3 M4 M5 M6 M7 M8 M9}
    set records [sram_pg_collect_body_overlaps {VDD VSS} $all_layers]
    sram_pg_write_body_overlap_report $report_path $records

    set strict_records {}
    foreach record $records {
        lassign $record net layer macro_name overlap_area shape status \
            wire_box macro_box
        if {[sram_pg_list_contains $strict_layers $layer]} {
            lappend strict_records $record
        }
    }

    if {[llength $strict_records] != 0} {
        set examples {}
        set max_examples [expr {min(5, [llength $strict_records])}]
        for {set i 0} {$i < $max_examples} {incr i} {
            lassign [lindex $strict_records $i] \
                net layer macro_name overlap_area shape status wire_box macro_box
            lappend examples [format "%s/%s/%s area=%.6f wire={%s}" \
                $net $layer $macro_name $overlap_area [join $wire_box { }]]
        }
        error "Top-level PG special wires overlap SRAM macro bodies on strict layers [join $strict_layers { }]: [llength $strict_records] records. See $report_path. Examples: [join $examples {; }]"
    }

    puts "SRAM top-level PG body-overlap report: $report_path"
    puts "SRAM body-overlap guard clean for regular mesh layers: [join $strict_layers { }]"
    return [llength $records]
}

proc sram_pg_write_region_report {report_path} {
    global SRAM_ROWS SRAM_COLS SRAM_X0 SRAM_Y0 SRAM_W SRAM_H
    global SRAM_MACRO_GAP_X SRAM_MACRO_GAP_Y
    global SRAM_ISLAND_LLX SRAM_ISLAND_LLY SRAM_ISLAND_URX SRAM_ISLAND_URY
    global SRAM_ISLAND_CUT_LLX SRAM_ISLAND_CUT_LLY
    global SRAM_ISLAND_CUT_URX SRAM_ISLAND_CUT_URY
    global power_die_llx power_die_lly power_die_urx power_die_ury
    global PG_BOUNDARY_EPS

    file mkdir [file dirname $report_path]

    if {![info exists PG_BOUNDARY_EPS]} {
        set PG_BOUNDARY_EPS 0.192
    }
    if {![info exists power_die_urx] || ![info exists power_die_ury]} {
        set die_box [join [dbGet top.fPlan.box]]
        if {![sram_pg_box_valid $die_box]} {
            error "Cannot decode die box before SRAM PG region report: $die_box"
        }
        lassign $die_box power_die_llx power_die_lly power_die_urx power_die_ury
    }

    set sram_pg_left [expr {$power_die_llx + $PG_BOUNDARY_EPS}]
    set sram_pg_bottom [expr {$power_die_lly + $PG_BOUNDARY_EPS}]
    set sram_pg_right [expr {min($SRAM_ISLAND_CUT_URX,
                                  $power_die_urx - $PG_BOUNDARY_EPS)}]
    set sram_pg_top [expr {min($SRAM_ISLAND_CUT_URY,
                                $power_die_ury - $PG_BOUNDARY_EPS)}]

    set fh [open $report_path w]
    puts $fh "# SRAM PG region audit"
    puts $fh "# macro_body: no regular top-level mesh is allowed here."
    puts $fh "# island_gap/halo: only local M4/M5 SRAM collectors are intended here."
    puts $fh "# outside_island: regular core/upper mesh region."
    puts $fh "type name layer direction box"
    puts $fh [format "keepout SRAM_ISLAND_BODY all all {%s}" \
        [join [list $SRAM_ISLAND_LLX $SRAM_ISLAND_LLY \
                   $SRAM_ISLAND_URX $SRAM_ISLAND_URY] { }]]
    puts $fh [format "keepout SRAM_ISLAND_CUT all all {%s}" \
        [join [list $SRAM_ISLAND_CUT_LLX $SRAM_ISLAND_CUT_LLY \
                   $SRAM_ISLAND_CUT_URX $SRAM_ISLAND_CUT_URY] { }]]

    foreach macro_record [sram_pg_macro_body_boxes] {
        lassign $macro_record macro_name macro_box
        puts $fh [format "macro_body %s all all {%s}" \
            $macro_name [join $macro_box { }]]
    }

    puts $fh [format "island_halo local_top M4 horizontal {%s}" \
        [join [list $sram_pg_left $SRAM_ISLAND_URY \
                   $sram_pg_right $sram_pg_top] { }]]
    puts $fh [format "island_halo local_left_stitch M5 vertical {%s}" \
        [join [list $sram_pg_left $sram_pg_bottom \
                   $SRAM_X0 $sram_pg_top] { }]]
    puts $fh [format "island_halo local_right M5 vertical {%s}" \
        [join [list $SRAM_ISLAND_URX $sram_pg_bottom \
                   $sram_pg_right $sram_pg_top] { }]]

    for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
        set gap_lly [expr {
            $SRAM_Y0 + ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y
        }]
        set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
        puts $fh [format "island_gap row_gap_%d M4 horizontal {%s}" \
            $r [join [list $sram_pg_left $gap_lly \
                          $sram_pg_right $gap_ury] { }]]
    }

    for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
        set gap_llx [expr {
            $SRAM_X0 + ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X
        }]
        set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
        puts $fh [format "island_gap col_gap_%d M5 vertical {%s}" \
            $c [join [list $gap_llx $sram_pg_bottom \
                          $gap_urx $sram_pg_top] { }]]
    }

    foreach region_var {
        LOGIC_RIGHT_EDGE_TAP_BOX
        LOGIC_RIGHT_FULL_BOX
        LOGIC_TOP_LEFT_BOX
        LOGIC_TOP_FULL_BOX
        LOGIC_RIGHT_LOWER_BOX
        UPPER_TOP_FULL_BOX
        UPPER_RIGHT_LOWER_BOX
        UPPER_RIGHT_FULL_BOX
        UPPER_TOP_LEFT_BOX
    } {
        if {[info exists ::$region_var]} {
            puts $fh [format "outside_island %s mesh all {%s}" \
                $region_var [join [set ::$region_var] { }]]
        }
    }

    close $fh
    puts "SRAM PG region audit report: $report_path"
}
