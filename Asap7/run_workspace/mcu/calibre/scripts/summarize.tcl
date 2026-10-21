############################################################
## Doc ket qua Calibre trong run_<buoc>/, ghi reports/<buoc>_summary.rpt
## (dong dau PASS / FAIL) va chep bao cao + log sang reports/ va logs/ de dua
## len git (run_*/ khong vao git; file > 5 MB chi giu dau + duoi).
##     tclsh scripts/summarize.tcl drc|lvs
############################################################

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set CAL_ROOT   [file dirname $SCRIPT_DIR]
set STEP       [lindex $argv 0]
cd $CAL_ROOT
file mkdir reports logs

array set CFG {}
set OFFSET_NOTES {}
if {[file isfile scripts/sourceme]} {
    set f [open scripts/sourceme r]
    while {[gets $f line] >= 0} {
        if {[regexp {^export (\w+)='(.*)'$} $line -> k v]} {
            set CFG($k) $v
        } elseif {[regexp {^# (VAR_M\d_[XY]OFFSET=.*)} $line -> note]} {
            lappend OFFSET_NOTES $note
        }
    }
    close $f
}
set DESIGN [expr {[info exists CFG(DESIGN)] ? $CFG(DESIGN) : "top_soc"}]

proc stamp {path} {
    if {![file exists $path]} {
        return "$path (KHONG CO)"
    }
    return "$path ([clock format [file mtime $path] -format {%Y-%m-%d %H:%M}])"
}

proc copy_capped {src dst {max_bytes 5000000} {keep 3000}} {
    if {![file isfile $src]} {
        return
    }
    if {[file size $src] <= $max_bytes} {
        file copy -force $src $dst
        return
    }
    set in [open $src r]
    set out [open $dst w]
    set n 0
    set tail {}
    while {[gets $in line] >= 0} {
        incr n
        if {$n <= $keep} {
            puts $out $line
            continue
        }
        lappend tail $line
        if {[llength $tail] > 2 * $keep} {
            set tail [lrange $tail end-[expr {$keep - 1}] end]
        }
    }
    close $in
    set tail [lrange $tail end-[expr {$keep - 1}] end]
    puts $out "... \[summarize.tcl: bo [expr {$n - $keep - [llength $tail]}] dong giua,\
 ban day du o $src\] ..."
    foreach line $tail {
        puts $out $line
    }
    close $out
}

proc grep_lines {path pattern {limit 20}} {
    set hits {}
    if {![file isfile $path]} {
        return $hits
    }
    set f [open $path r]
    while {[gets $f line] >= 0 && [llength $hits] < $limit} {
        if {[regexp -- $pattern $line]} {
            lappend hits [string trimright $line]
        }
    }
    close $f
    return $hits
}

proc write_summary {verdict lines} {
    global STEP
    set f [open reports/${STEP}_summary.rpt w]
    puts $f $verdict
    foreach line $lines {
        puts $f $line
    }
    close $f
    puts "$verdict - reports/${STEP}_summary.rpt"
}

# =============================================================================
proc summarize_drc {} {
    global DESIGN CFG OFFSET_NOTES
    set run run_drc
    set sum  $run/$DESIGN.drc.sum
    set log  $run/calibre_drc.log
    copy_capped $log logs/calibre_drc.log
    copy_capped $sum reports/$DESIGN.drc.sum

    set out [list "Calibre DRC $DESIGN - [clock format [clock seconds] -format {%Y-%m-%d %H:%M}]"]
    lappend out "  GDS     : [stamp [expr {[info exists CFG(GDS_FILE)] ? $CFG(GDS_FILE) : {?}}]]"
    lappend out "  deck    : [expr {[info exists CFG(DRC_DECK)] ? $CFG(DRC_DECK) : {?}}]\
 (run_drc/asap7_drc.rul: 5 lenh dac ta da comment)"
    foreach note $OFFSET_NOTES {
        lappend out "  offset  : $note"
    }
    set errors [grep_lines $log {(?i)^\s*(ERROR|\*\*\* ?ERROR|.*license.*(fail|denied|not available))} 15]

    if {![file isfile $sum]} {
        lappend out "  Calibre khong ghi $sum - doc logs/calibre_drc.log"
        foreach e $errors {
            lappend out "    $e"
        }
        write_summary FAIL $out
        return
    }

    # Muc cua summary HIER: "--- RULECHECK RESULTS STATISTICS (BY CELL)" (dong
    # CELL ... roi RULECHECK cua cell do), "--- RULECHECK RESULTS STATISTICS"
    # (tong), "--- SUMMARY" (TOTAL ...).  Dem "= H (F)": H theo phan cap, F phang.
    set rc_re {^\s*RULECHECK\s+(\S+)\s+\.+\s+TOTAL Result Count\s*=\s*(\d+)(?:\s*\((\d+)\))?}
    set section ""
    set cell ""
    array set rule_h {}
    array set rule_f {}
    array set cell_rule {}
    array set cell_tot {}
    set layers {}
    set warnings {}
    set total_h ""
    set total_f ""
    set executed ""
    set f [open $sum r]
    while {[gets $f line] >= 0} {
        if {[regexp {^\s*---\s+(.*\S)\s*$} $line -> hdr]} {
            set section $hdr
            continue
        }
        if {[regexp {TOTAL DRC Results Generated:\s+(\d+)(?:\s*\((\d+)\))?} $line -> total_h total_f]} {
            continue
        }
        if {[regexp {TOTAL DRC RuleChecks Executed:\s+(\d+)} $line -> executed]} {
            continue
        }
        if {[string match "RUNTIME WARNINGS*" $section] && ![regexp {^[-=\s]*$} $line] &&
            [llength $warnings] < 20} {
            lappend warnings [string trim $line]
        } elseif {[string match "ORIGINAL LAYER STATISTICS*" $section] &&
                  [regexp {LAYER\s+(\S+)\s+\.+\s+TOTAL Original Geometry Count\s*=\s*(\d+)(?:\s*\((\d+)\))?} \
                      $line -> l h fl]} {
            lappend layers "$l [expr {$fl ne "" ? $fl : $h}]"
        } elseif {[string match "*BY CELL*" $section]} {
            if {[regexp {^\s*CELL\s+(\S+)\s+\.+\s+TOTAL Result Count\s*=\s*(\d+)} $line -> cell h]} {
                set cell_tot($cell) $h
            } elseif {$cell ne "" && [regexp $rc_re $line -> r h fl] && $h > 0} {
                lappend cell_rule($cell) "$r $h"
            }
        } elseif {[string match "RULECHECK RESULTS STATISTICS*" $section] &&
                  [regexp $rc_re $line -> r h fl]} {
            set rule_h($r) $h
            set rule_f($r) [expr {$fl ne "" ? $fl : $h}]
        }
    }
    close $f

    set fallback ""
    if {[array size rule_h] == 0} {
        # khong thay muc tong: cong tu muc theo cell (chi co so phan cap)
        set fallback " (KHONG thay muc RULECHECK RESULTS STATISTICS - so cong tu muc BY CELL)"
        foreach c [array names cell_rule] {
            foreach item $cell_rule($c) {
                lassign $item r h
                set rule_h($r) [expr {[info exists rule_h($r)] ? $rule_h($r) + $h : $h}]
                set rule_f($r) $rule_h($r)
            }
        }
    }

    # Mo ta luat: dong "@" dau tien sau dong mo khoi luat trong deck.
    array set desc {}
    if {[info exists CFG(DRC_DECK)] && [file isfile $CFG(DRC_DECK)]} {
        set f [open $CFG(DRC_DECK) r]
        set cur ""
        while {[gets $f line] >= 0} {
            if {[regexp {^\s*([A-Za-z0-9_.]+)\s*\{\s*$} $line -> cur]} {
                continue
            }
            if {$cur ne "" && [regexp {^\s*@\s*(.*\S)} $line -> d]} {
                if {$d ne $cur} {
                    set desc($cur) $d
                    set cur ""
                }
            }
        }
        close $f
    }

    set max_res [expr {[info exists CFG(DRC_MAX_RESULTS)] ? $CFG(DRC_MAX_RESULTS) : 1000}]
    set bad {}
    array set group {}
    foreach r [array names rule_h] {
        if {$rule_h($r) == 0 && $rule_f($r) == 0} {
            continue
        }
        lappend bad [list $r $rule_h($r) $rule_f($r)]
        set g [lindex [split $r .] 0]
        set group($g) [expr {[info exists group($g)] ? $group($g) + $rule_f($r) : $rule_f($r)}]
    }
    set bad [lsort -integer -decreasing -index 2 $bad]

    if {$total_h eq ""} {
        lappend out "  Calibre CHUA CHAY XONG: $sum khong co dong TOTAL DRC Results Generated"
        foreach e $errors {
            lappend out "    $e"
        }
        write_summary FAIL $out
        return
    }
    if {$total_f eq ""} {
        set total_f $total_h
    }
    set verdict [expr {$total_f == 0 ? "PASS" : "FAIL"}]
    lappend out "  ket qua : $total_h vi pham theo phan cap ($total_f phang), [llength $bad] rule co vi pham\
 / [expr {$executed ne "" ? $executed : [array size rule_h]}] rule da chay$fallback"
    lappend out "  chi tiet: reports/$DESIGN.drc.sum, run_drc/$DESIGN.drc.db (mo bang Calibre RVE),\
 log logs/calibre_drc.log"
    lappend out "  (*) = cham DRC MAXIMUM RESULTS $max_res: so that co the lon hon"
    if {[llength $errors]} {
        lappend out ""
        lappend out "Dong ERROR trong log:"
        foreach e $errors {
            lappend out "  $e"
        }
    }
    if {[llength $bad]} {
        lappend out ""
        lappend out "Theo lop / nhom luat (so phang):"
        foreach g [lsort [array names group]] {
            lappend out [format "  %-10s %10d" $g $group($g)]
        }
        lappend out ""
        lappend out "Rule co vi pham, giam dan theo so phang (phan cap / phang):"
        foreach item $bad {
            lassign $item r h fl
            set mark [expr {$h >= $max_res ? "*" : " "}]
            set d [expr {[info exists desc($r)] ? $desc($r) : ""}]
            lappend out [format "  %-22s %8d%s %10d   %s" $r $h $mark $fl $d]
        }
        lappend out ""
        lappend out "Cell co vi pham (10 cell nhieu nhat, so phan cap; top_soc = hinh o muc top):"
        set cells {}
        foreach c [array names cell_tot] {
            if {$cell_tot($c) > 0} {
                lappend cells [list $c $cell_tot($c)]
            }
        }
        foreach item [lrange [lsort -integer -decreasing -index 1 $cells] 0 9] {
            lassign $item c n
            set rules {}
            if {[info exists cell_rule($c)]} {
                foreach rr [lrange [lsort -integer -decreasing -index 1 $cell_rule($c)] 0 5] {
                    lappend rules "[lindex $rr 0]=[lindex $rr 1]"
                }
            }
            lappend out [format "  %-34s %8d   %s" $c $n [join $rules {, }]]
        }
    }
    if {[llength $warnings]} {
        lappend out ""
        lappend out "RUNTIME WARNINGS (20 dong dau):"
        foreach w $warnings {
            lappend out "  $w"
        }
    }
    if {[llength $layers]} {
        lappend out ""
        lappend out "So hinh goc theo lop (phang): [join $layers {, }]"
    }
    write_summary $verdict $out
}

# =============================================================================
proc summarize_lvs {} {
    global DESIGN CFG
    set run run_lvs
    set rep  $run/$DESIGN.lvs.report
    set ext  $run/$DESIGN.lvs.report.ext
    set erc  $run/$DESIGN.lvs.summary
    set vlog $run/calibre_v2lvs.log
    set log  $run/calibre_lvs.log
    copy_capped $vlog logs/calibre_v2lvs.log
    copy_capped $log  logs/calibre_lvs.log
    copy_capped $rep  reports/$DESIGN.lvs.report
    copy_capped $ext  reports/$DESIGN.lvs.report.ext
    copy_capped $erc  reports/$DESIGN.lvs.summary
    copy_capped $run/cell_usage.rpt reports/lvs_cell_usage.rpt

    set out [list "Calibre LVS $DESIGN - [clock format [clock seconds] -format {%Y-%m-%d %H:%M}]"]
    lappend out "  GDS     : [stamp [expr {[info exists CFG(GDS_FILE)] ? $CFG(GDS_FILE) : {?}}]]"
    lappend out "  netlist : [stamp [expr {[info exists CFG(NETLIST_PWR)] ? $CFG(NETLIST_PWR) : {?}}]]"
    lappend out "  deck    : [expr {[info exists CFG(LVS_DECK)] ? $CFG(LVS_DECK) : {?}}]\
 (run_lvs/asap7_lvs.rul: LVS REPORT / POWER NAME / GROUND NAME da comment)"
    if {[file isfile $run/lvs_box.list]} {
        set f [open $run/lvs_box.list r]
        lappend out "  LVS BOX : [string trim [string map {"\n" " "} [read $f]]]"
        close $f
    }
    foreach line [grep_lines $run/cell_usage.rpt {^# [0-9]} 1] {
        lappend out "  cell    : [string range $line 2 end] (reports/lvs_cell_usage.rpt)"
    }
    set verrors [grep_lines $vlog {(?i)error} 15]
    set errors  [grep_lines $log {(?i)^\s*(ERROR|\*\*\* ?ERROR|.*license.*(fail|denied|not available))} 15]

    if {![file isfile $rep]} {
        lappend out "  Calibre khong ghi $rep - doc logs/calibre_v2lvs.log va logs/calibre_lvs.log"
        foreach e [concat $verrors $errors] {
            lappend out "    $e"
        }
        write_summary FAIL $out
        return
    }

    set overall ""
    set overall_notes {}
    set notes {}
    set cells {}
    array set cell_status {}
    set tables {}
    set section ""
    set grab 0
    set f [open $rep r]
    while {[gets $f line] >= 0} {
        if {$overall eq "" && [regexp {#\s+(CORRECT|INCORRECT|NOT COMPARED)\s+#} $line -> overall]} {
            set section overall
            continue
        }
        if {[regexp {^\s*CELL\s+SUMMARY} $line]} {
            set section cells
            continue
        }
        if {[regexp {^\s*(INITIAL NUMBERS OF OBJECTS|NUMBERS OF OBJECTS AFTER TRANSFORMATION)} $line -> t] &&
            [lsearch -exact $tables $t] < 0} {
            lappend tables $t
            lappend notes "" "$t (cell dau tien trong report):"
            set grab 14
            continue
        }
        if {$grab > 0} {
            incr grab -1
            if {[string trim $line] ne ""} {
                lappend notes "  [string trimright $line]"
            }
            continue
        }
        if {$section eq "overall" && [regexp {^\s*(Error|Warning):} $line] &&
            [llength $overall_notes] < 30} {
            lappend overall_notes "  [string trim $line]"
        } elseif {$section eq "cells" &&
                  [regexp {^\s*(CORRECT|INCORRECT|NOT COMPARED)\s+(\S+)\s+(\S+)} $line -> st lc sc]} {
            incr cell_status($st)
            if {$st ne "CORRECT" && [llength $cells] < 30} {
                lappend cells "  $st  $lc  $sc"
            }
        } elseif {$section eq "cells" && [regexp {^\s*\*{10,}} $line] && [array size cell_status]} {
            set section ""
        }
    }
    close $f

    set verdict [expr {$overall eq "CORRECT" ? "PASS" : "FAIL"}]
    lappend out "  ket qua : [expr {$overall ne "" ? $overall : "khong doc duoc OVERALL COMPARISON RESULTS"}]"
    set st {}
    foreach k [lsort [array names cell_status]] {
        lappend st "$k $cell_status($k)"
    }
    lappend out "  cell    : [expr {[llength $st] ? [join $st {, }] : {?}}] (CELL SUMMARY)"
    lappend out "  chi tiet: reports/$DESIGN.lvs.report, reports/$DESIGN.lvs.report.ext,\
 run_lvs/svdb (Calibre RVE), log logs/calibre_lvs.log"
    if {[llength $verrors] || [llength $errors]} {
        lappend out ""
        lappend out "Dong ERROR trong log v2lvs / Calibre:"
        foreach e [concat $verrors $errors] {
            lappend out "  $e"
        }
    }
    if {[llength $overall_notes]} {
        lappend out ""
        lappend out "Error / Warning cua OVERALL COMPARISON RESULTS:"
        lappend out {*}$overall_notes
    }
    if {[llength $cells]} {
        lappend out ""
        lappend out "Cell khong CORRECT (layout / source):"
        lappend out {*}$cells
    }
    foreach line $notes {
        lappend out $line
    }
    set ext_hits [grep_lines $ext {(?i)(error|warning|short|open|stamp|malform|conflict)} 40]
    if {[llength $ext_hits]} {
        lappend out ""
        lappend out "Bao cao trich xuat (reports/$DESIGN.lvs.report.ext, 40 dong dau khop):"
        foreach e $ext_hits {
            lappend out "  $e"
        }
    }
    write_summary $verdict $out
}

switch -- $STEP {
    drc     { summarize_drc }
    lvs     { summarize_lvs }
    default { puts "dung: tclsh scripts/summarize.tcl drc|lvs"; exit 2 }
}
exit 0
