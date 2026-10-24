############################################################
## Doc ket qua Calibre trong run_<buoc>/, ghi reports/<buoc>_summary.rpt
## (dong dau PASS / FAIL) va chep bao cao + log sang reports/ va logs/ de dua
## len git (run_*/ khong vao git; file > 2 MB chi giu 2000 dong dau + 2000
## dong cuoi; dong ERROR van grep tu ban day du trong run_*/).
##     tclsh scripts/summarize.tcl drc|lvs
############################################################

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set CAL_ROOT   [file dirname $SCRIPT_DIR]
set STEP       [lindex $argv 0]
cd $CAL_ROOT
file mkdir reports logs

array set CFG {}
set OFFSET_NOTES {}
set PRECISION_NOTE ""
if {[file isfile scripts/sourceme]} {
    set f [open scripts/sourceme r]
    while {[gets $f line] >= 0} {
        if {[regexp {^export (\w+)='(.*)'$} $line -> k v]} {
            set CFG($k) $v
        } elseif {[regexp {^# (VAR_M\d_[XY]OFFSET=.*)} $line -> note]} {
            lappend OFFSET_NOTES $note
        } elseif {[regexp {^# GDS_PRECISION=(.*)} $line -> note]} {
            set PRECISION_NOTE $note
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

proc copy_capped {src dst {max_bytes 2000000} {keep 2000}} {
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

# He so phong GDS -> luoi deck ma Calibre that su dung.  LVS 2026-10-21 19:22
# chay het voi "MAGNIFICATION: 1" (moi hinh 1/2) ma tom tat khong ghi gi.
proc magnify_note {log} {
    set vals {}
    foreach line [grep_lines $log {^(--- LAYOUT MAGNIFICATION|MAGNIFICATION:)} 2] {
        regexp {[=:]\s*(\S+)\s*$} $line -> v
        lappend vals $v
    }
    if {![llength $vals]} {
        return "? (log khong co dong MAGNIFICATION)"
    }
    return "[join $vals { -> }] (dong '--- LAYOUT MAGNIFICATION' -> 'MAGNIFICATION:' cua log)"
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
# DRC chay theo nhom rule (run_drc.sh): moi nhom mot lan Calibre voi
# run_drc/$DESIGN.<nhom>.drc.sum va run_drc/calibre_drc_<nhom>.log;
# run_drc/groups.list liet ke moi nhom va so rule.

proc fmt_secs {s} {
    if {$s eq ""} {
        return "?"
    }
    return [format "%dh%02dm" [expr {$s / 3600}] [expr {$s % 3600 / 60}]]
}

# File summary HIER: "--- RULECHECK RESULTS STATISTICS (BY CELL)" (dong CELL ...
# roi RULECHECK cua cell do), "--- RULECHECK RESULTS STATISTICS" (tong),
# "--- SUMMARY" (TOTAL ...).  Dem "= H (F)": H theo phan cap, F phang.
# Tra dict: done (co dong TOTAL DRC Results Generated), rules {r {h f}},
# cells {c n}, cell_rule {c {{r h} ...}}, warnings, layers {l n}.
proc drc_read_sum {sum} {
    set rc_re {^\s*RULECHECK\s+(\S+)\s+\.+\s+TOTAL Result Count\s*=\s*(\d+)(?:\s*\((\d+)\))?}
    set S [dict create done 0 rules {} cells {} cell_rule {} warnings {} layers {}]
    set section ""
    set cell ""
    set f [open $sum r]
    while {[gets $f line] >= 0} {
        if {[regexp {^\s*---\s+(.*\S)\s*$} $line -> hdr]} {
            set section $hdr
            continue
        }
        if {[regexp {TOTAL DRC Results Generated:} $line]} {
            dict set S done 1
            continue
        }
        if {[string match "RUNTIME WARNINGS*" $section] && ![regexp {^[-=\s]*$} $line] &&
            [llength [dict get $S warnings]] < 20} {
            dict lappend S warnings [string trim $line]
        } elseif {[string match "ORIGINAL LAYER STATISTICS*" $section] &&
                  [regexp {LAYER\s+(\S+)\s+\.+\s+TOTAL Original Geometry Count\s*=\s*(\d+)(?:\s*\((\d+)\))?} \
                      $line -> l h fl]} {
            dict set S layers $l [expr {$fl ne "" ? $fl : $h}]
        } elseif {[string match "*BY CELL*" $section]} {
            if {[regexp {^\s*CELL\s+(\S+)\s+\.+\s+TOTAL Result Count\s*=\s*(\d+)} $line -> cell h]} {
                dict set S cells $cell $h
            } elseif {$cell ne "" && [regexp $rc_re $line -> r h fl] && $h > 0} {
                set items [expr {[dict exists $S cell_rule $cell] ? [dict get $S cell_rule $cell] : {}}]
                lappend items [list $r $h]
                dict set S cell_rule $cell $items
            }
        } elseif {[string match "RULECHECK RESULTS STATISTICS*" $section] &&
                  [regexp $rc_re $line -> r h fl]} {
            dict set S rules $r [list $h [expr {$fl ne "" ? $fl : $h}]]
        }
    }
    close $f
    if {[dict size [dict get $S rules]] == 0} {
        # khong thay muc tong: cong tu muc theo cell (chi co so phan cap)
        foreach {c items} [dict get $S cell_rule] {
            foreach item $items {
                lassign $item r h
                set old [expr {[dict exists $S rules $r] ? [lindex [dict get $S rules $r] 0] : 0}]
                dict set S rules $r [list [expr {$old + $h}] [expr {$old + $h}]]
            }
        }
    }
    return $S
}

# Log Calibre: "DRC RuleCheck X COMPLETED. Number of Results = H (F)" sau moi
# rule, "OPS COMPLETE = n OF m  ELAPSED TIME = s" sau moi lenh.  Con doc duoc
# khi Calibre bi giet giua chung (lan 2026-10-22: khong co file .sum).
proc drc_read_log {log} {
    set L [dict create rules {} ops ? elapsed ""]
    set f [open $log r]
    while {[gets $f line] >= 0} {
        if {[regexp {^\s*DRC RuleCheck\s+(\S+)\s+COMPLETED\.\s+Number of Results\s*=\s*(\d+)(?:\s*\((\d+)\))?} \
                $line -> r h fl]} {
            dict set L rules $r [list $h [expr {$fl ne "" ? $fl : $h}]]
        } elseif {[regexp {OPS COMPLETE\s*=\s*(\d+\s+OF\s+\d+)\s+ELAPSED TIME\s*=\s*(\d+)} $line -> ops s]} {
            dict set L ops $ops
            dict set L elapsed $s
        }
    }
    close $f
    return $L
}

# Mo ta luat: dong "@" dau tien khac ten luat sau dong mo khoi "TEN {" (dau {
# co the o dong sau ten) trong deck.
proc drc_rule_desc {deck} {
    set desc [dict create]
    if {![file isfile $deck]} {
        return $desc
    }
    set f [open $deck r]
    set cur ""
    set prev ""
    while {[gets $f line] >= 0} {
        if {[regexp {^\s*([A-Za-z0-9_.]+)\s*\{\s*$} $line -> cur]} {
            set prev ""
            continue
        }
        if {[regexp {^\s*\{\s*$} $line] && $prev ne ""} {
            set cur $prev
            set prev ""
            continue
        }
        if {$cur ne "" && [regexp {^\s*@\s*(.*\S)} $line -> d] && $d ne $cur} {
            dict set desc $cur $d
            set cur ""
        }
        set t [string trim $line]
        if {$t ne ""} {
            set prev [expr {[regexp {^[A-Za-z0-9_.]+$} $t] ? $t : ""}]
        }
    }
    close $f
    return $desc
}

proc summarize_drc {} {
    global DESIGN CFG OFFSET_NOTES PRECISION_NOTE
    set run run_drc
    # ban chep cua lan truoc (ca log / sum mot khoi truoc khi chia nhom)
    foreach p [concat [glob -nocomplain logs/calibre_drc*.log] [glob -nocomplain reports/$DESIGN*.drc.sum]] {
        file delete $p
    }
    set gds [expr {[info exists CFG(GDS_FILE)] ? $CFG(GDS_FILE) : {?}}]
    set max_res [expr {[info exists CFG(DRC_MAX_RESULTS)] ? $CFG(DRC_MAX_RESULTS) : 1000}]
    # Calibre ghi loi license dang "//  ERROR: ... could not be licensed"
    set err_re {(?i)^\s*(//\s*)?(ERROR|\*\*\* ?ERROR)|license.*(fail|denied|not available)|could not be licensed}

    set out [list "Calibre DRC $DESIGN - [clock format [clock seconds] -format {%Y-%m-%d %H:%M}]"]
    lappend out "  GDS     : [stamp $gds]"
    lappend out "  deck    : [expr {[info exists CFG(DRC_DECK)] ? $CFG(DRC_DECK) : {?}}]\
 (run_drc/asap7_drc.rul: 6 lenh dac ta da comment)"
    if {$PRECISION_NOTE ne ""} {
        lappend out "  dbu     : $PRECISION_NOTE"
    }
    foreach note $OFFSET_NOTES {
        lappend out "  offset  : $note"
    }

    if {![file isfile $run/groups.list]} {
        lappend out "  run_drc.sh dung truoc khi chia nhom rule - doc logs/calibre_drc.log"
        foreach e [grep_lines $run/calibre_drc.log $err_re 15] {
            lappend out "    $e"
        }
        copy_capped $run/calibre_drc.log logs/calibre_drc.log
        write_summary FAIL $out
        return
    }
    set f [open $run/groups.list r]
    set groups [read $f]
    close $f

    set rules [dict create]
    set cell_rule [dict create]
    set warnings {}
    set layers [dict create]
    set errors {}
    set status {}
    set magnify ""
    set complete 1
    set n_all 0
    foreach {g n} $groups {
        incr n_all $n
        set sum $run/$DESIGN.$g.drc.sum
        set log $run/calibre_drc_$g.log
        set head [format "    %-6s %4d rule  " $g $n]
        if {![file isfile $log]} {
            lappend status "${head}CHUA CHAY (make drc DRC_GROUPS=$g)"
            set complete 0
            continue
        }
        copy_capped $log logs/calibre_drc_$g.log
        if {$magnify eq ""} {
            set magnify [magnify_note $log]
        }
        foreach e [grep_lines $log $err_re 5] {
            lappend errors "$g: $e"
        }
        set L [drc_read_log $log]
        set S [dict create done 0]
        if {[file isfile $sum]} {
            copy_capped $sum reports/$DESIGN.$g.drc.sum
            set S [drc_read_sum $sum]
        }
        if {[dict get $S done]} {
            set R [dict get $S rules]
            foreach {c items} [dict get $S cell_rule] {
                dict lappend cell_rule $c {*}$items
            }
            set layers [dict merge $layers [dict get $S layers]]
            set warnings [concat $warnings [dict get $S warnings]]
            set st "xong sau [fmt_secs [dict get $L elapsed]]"
        } else {
            set R [dict get $L rules]
            set complete 0
            set st "KHONG XONG (OPS COMPLETE = [dict get $L ops] sau [fmt_secs [dict get $L elapsed]],\
 [dict size $R] rule da ra ket qua, so lay tu log)"
        }
        set h 0
        set fl 0
        foreach {r c} $R {
            dict set rules $r $c
            incr h [lindex $c 0]
            incr fl [lindex $c 1]
        }
        if {[file isfile $gds] && [file mtime $log] < [file mtime $gds]} {
            set complete 0
            append st " - CU HON GDS, chay lai nhom nay"
        }
        lappend status "$head$st: $h vi pham ($fl phang)"
    }

    set total_h 0
    set total_f 0
    set bad {}
    array set group {}
    foreach {r c} $rules {
        lassign $c h fl
        incr total_h $h
        incr total_f $fl
        if {$h == 0 && $fl == 0} {
            continue
        }
        lappend bad [list $r $h $fl]
        set g [lindex [split $r .] 0]
        set group($g) [expr {[info exists group($g)] ? $group($g) + $fl : $fl}]
    }
    set bad [lsort -integer -decreasing -index 2 $bad]
    set verdict [expr {$complete && $total_f == 0 ? "PASS" : "FAIL"}]

    lappend out "  magnify : [expr {$magnify ne "" ? $magnify : "?"}]"
    lappend out "  nhom    : (run_drc/groups.list; chay lai mot nhom: make drc DRC_GROUPS=<nhom>)"
    lappend out {*}$status
    lappend out "  ket qua : $total_h vi pham theo phan cap ($total_f phang), [llength $bad] rule co vi pham\
 / [dict size $rules] rule co ket qua / $n_all rule[expr {$complete ? "" : " - CO NHOM CHUA XONG / CU, KHONG KET LUAN DUOC"}]"
    lappend out "  chi tiet: reports/$DESIGN.<nhom>.drc.sum, run_drc/$DESIGN.<nhom>.drc.db (Calibre RVE),\
 logs/calibre_drc_<nhom>.log"
    lappend out "  (*) = cham DRC MAXIMUM RESULTS $max_res: so that co the lon hon"
    if {[llength $errors]} {
        lappend out ""
        lappend out "Dong ERROR trong log:"
        foreach e $errors {
            lappend out "  $e"
        }
    }
    if {[llength $bad]} {
        set desc [drc_rule_desc [expr {[info exists CFG(DRC_DECK)] ? $CFG(DRC_DECK) : ""}]]
        lappend out ""
        lappend out "Theo lop / nhom luat (so phang):"
        foreach g [lsort [array names group]] {
            lappend out [format "  %-10s %10d" $g $group($g)]
        }
        lappend out ""
        lappend out "Rule co vi pham, giam dan theo so phang (phan cap / phang):"
        foreach item $bad {
            lassign $item r h fl
            set mark [expr {[string is integer -strict $max_res] && $h >= $max_res ? "*" : " "}]
            set d [expr {[dict exists $desc $r] ? [dict get $desc $r] : ""}]
            lappend out [format "  %-22s %8d%s %10d   %s" $r $h $mark $fl $d]
        }
        set cell_n {}
        foreach {c items} $cell_rule {
            set n 0
            foreach item $items {
                incr n [lindex $item 1]
            }
            lappend cell_n [list $c $n]
        }
        if {[llength $cell_n]} {
            lappend out ""
            lappend out "Cell co vi pham (10 cell nhieu nhat, so phan cap, chi nhom da xong;\
 top_soc = hinh o muc top):"
            foreach item [lrange [lsort -integer -decreasing -index 1 $cell_n] 0 9] {
                lassign $item c n
                set rr {}
                foreach x [lrange [lsort -integer -decreasing -index 1 [dict get $cell_rule $c]] 0 5] {
                    lappend rr "[lindex $x 0]=[lindex $x 1]"
                }
                lappend out [format "  %-34s %8d   %s" $c $n [join $rr {, }]]
            }
        }
    }
    if {[llength $warnings]} {
        lappend out ""
        lappend out "RUNTIME WARNINGS (20 dong dau moi nhom):"
        foreach w $warnings {
            lappend out "  $w"
        }
    }
    if {[dict size $layers]} {
        set ll {}
        foreach {l n} $layers {
            lappend ll "$l $n"
        }
        lappend out ""
        lappend out "So hinh goc theo lop (phang): [join $ll {, }]"
    }
    write_summary $verdict $out
}

# =============================================================================
proc summarize_lvs {} {
    global DESIGN CFG PRECISION_NOTE
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
 (run_lvs/asap7_lvs.rul: LVS REPORT / POWER NAME / GROUND NAME / RECOGNIZE GATES da comment)"
    if {$PRECISION_NOTE ne ""} {
        lappend out "  dbu     : $PRECISION_NOTE"
    }
    if {[file isfile $run/lvs_box.list]} {
        set f [open $run/lvs_box.list r]
        lappend out "  LVS BOX : [string trim [string map {"\n" " "} [read $f]]]"
        close $f
    }
    lappend out "  magnify : [magnify_note $log]"
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
