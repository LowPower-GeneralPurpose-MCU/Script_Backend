############################################################
## Doc ket qua netsim trong run_<che do>/, ghi reports/<che do>_summary.rpt
## (dong dau PASS / FAIL) va chep log sang logs/ de dua len git (run_*/ khong
## vao git; file > 2 MB chi giu 2000 dong dau + 2000 dong cuoi).
##     tclsh scripts/summarize.tcl rtl|syn|func|sdf_max|sdf_min
##
## PASS khi: tb in "[NETSIM][RESULT] PASS", log khong co *E / *F cua Xcelium,
## func / sdf_max / sdf_min co dong annotate SDF, sdf_max / sdf_min them
## 0 "Timing violation".
############################################################

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set NS_ROOT    [file dirname $SCRIPT_DIR]
set MODE       [lindex $argv 0]
cd $NS_ROOT
file mkdir reports logs

set RUN    run_$MODE
set LOG    $RUN/netsim_$MODE.log
set SDFLOG $RUN/sdf.log

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

proc write_summary {verdict lines} {
    global MODE
    set f [open reports/${MODE}_summary.rpt w]
    puts $f $verdict
    foreach line $lines {
        puts $f $line
    }
    close $f
    puts "$verdict - reports/${MODE}_summary.rpt"
}

# Dem ma canh bao/loi Xcelium ("*W,SDFNEP" ...) -> {{ma so_lan} ...} giam dan.
proc count_codes {path sev} {
    array set n {}
    if {![file isfile $path]} {
        return {}
    }
    set f [open $path r]
    while {[gets $f line] >= 0} {
        foreach {all code} [regexp -all -inline "\\*${sev},(\[A-Z0-9_]+)" $line] {
            incr n($code)
        }
    }
    close $f
    set out {}
    foreach code [array names n] {
        lappend out [list $code $n($code)]
    }
    return [lsort -integer -decreasing -index 1 $out]
}

if {![file isfile $LOG]} {
    write_summary FAIL [list "Khong co $LOG - xrun/xmsdfc khong chay (xem output cua make)."]
    exit 0
}

set result ""
set uart_bytes 0
set flash_reads {}
set errors {}
set viol 0
set viol_hits {}
set sdf_lines {}
set pending_check ""
set f [open $LOG r]
while {[gets $f line] >= 0} {
    if {[regexp {^\[NETSIM\]\[RESULT\] (.*)$} $line -> r]} {
        set result $r
    } elseif {[regexp {^\[NETSIM\]\[UART\]} $line]} {
        incr uart_bytes
    } elseif {[regexp {^\[FLASH\] t=\S+ Fast Read (@\S+)} $line -> a]} {
        lappend flash_reads $a
    }
    if {[regexp {\*[EF],[A-Z0-9_]+} $line] && [llength $errors] < 20} {
        lappend errors [string trim $line]
    }
    # Xcelium: "Warning!  Timing violation" / dong $setuphold<...>( ... ) / Scope: ...
    if {[regexp {Timing violation} $line]} {
        incr viol
        set pending_check "?"
    } elseif {$pending_check ne "" && [regexp {^\s*\$\w+} $line]} {
        set pending_check [string trim $line]
    } elseif {$pending_check ne "" && [regexp {^\s*Scope:\s*(\S+)} $line -> scope]} {
        if {[llength $viol_hits] < 10} {
            lappend viol_hits "$scope  $pending_check"
        }
        set pending_check ""
    }
    if {[regexp -nocase {annotation completed|SDF statistics} $line]} {
        lappend sdf_lines [string trim $line]
    }
}
close $f

set reasons {}
if {$result eq ""} {
    lappend reasons "tb khong in \[NETSIM\]\[RESULT\]: elaborate/mo phong dung giua chung"
} elseif {![string match "PASS*" $result]} {
    lappend reasons "tb: $result"
}
if {[llength $errors]} {
    lappend reasons "[llength $errors] dong *E/*F cua Xcelium (toi da 20 dong duoc dem)"
}
set SDF_MODE [expr {$MODE in {func sdf_max sdf_min}}]
if {$SDF_MODE && ![llength $sdf_lines]} {
    lappend reasons "khong thay dong annotate SDF (Annotation completed / SDF statistics) trong log"
}
if {$MODE in {sdf_max sdf_min} && $viol > 0} {
    lappend reasons "$viol Timing violation"
}

set lines {}
lappend lines "che do   : $MODE"
if {[file isfile $RUN/inputs.txt]} {
    set fi [open $RUN/inputs.txt r]
    while {[gets $fi l] >= 0} {
        lassign [split $l \t] name path t
        lappend lines [format "%-9s: %s (%s)" $name $path $t]
    }
    close $fi
}
lappend lines "ket qua  : [expr {$result eq "" ? "(khong co)" : $result}]"
lappend lines "UART     : $uart_bytes byte nhan tren PA0"
set more [expr {[llength $flash_reads] > 8 ? " ..." : ""}]
lappend lines "flash    : [llength $flash_reads] lenh doc da log [lrange $flash_reads 0 7]$more"
if {$SDF_MODE} {
    lappend lines "SDF      : [expr {[llength $sdf_lines] ? [join $sdf_lines {; }] : "(khong co dong annotate)"}]"
    if {$MODE eq "func"} {
        lappend lines "timing   : tat (-notimingchecks)"
    } else {
        lappend lines "timing   : $viol Timing violation"
    }
    foreach h $viol_hits {
        lappend lines "    $h"
    }
    set sdfw [count_codes $SDFLOG W]
    if {[llength $sdfw]} {
        lappend lines "canh bao SDF ($SDFLOG, top 10):"
        foreach c [lrange $sdfw 0 9] {
            lappend lines [format "    *W,%-10s %d" [lindex $c 0] [lindex $c 1]]
        }
        lappend lines "    (macro SRAM khong co specify -> canh bao o 84 instance SRAM la binh thuong)"
    }
}
if {[llength $errors]} {
    lappend lines "loi Xcelium (toi da 20):"
    foreach e $errors {
        lappend lines "    $e"
    }
}
set logw [count_codes $LOG W]
if {[llength $logw]} {
    set top {}
    foreach c [lrange $logw 0 9] {
        lappend top "*W,[lindex $c 0]=[lindex $c 1]"
    }
    lappend lines "canh bao log (top 10): [join $top {, }]"
}
foreach r $reasons {
    lappend lines "KHONG DAT: $r"
}
if {$MODE eq "syn" && [llength $reasons]} {
    lappend lines "LUU Y: syn chay unit delay; ICG long nhau lam canh clock trung luc Q doi (race)."
    lappend lines "       func PASS ma syn FAIL thuong la race do, khong phai loi netlist."
}

copy_capped $LOG logs/netsim_$MODE.log
copy_capped $SDFLOG logs/sdf_$MODE.log

write_summary [expr {[llength $reasons] ? "FAIL" : "PASS"}] $lines
