############################################################
## Proc dung chung cua mcu/eco (eco_drv.tcl, eco_finish.tcl).
## Chi co Tcl thuan, khong lenh Innovus nao - thu duoc bang tclsh.
############################################################

proc eco_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set ECO_WARNINGS {}
proc eco_warn {msg} {
    lappend ::ECO_WARNINGS $msg
    puts "WARNING: $msg"
}

# 'puts' khong vao file log cua Innovus (da gap o mcu/quantus), nen ket luan
# va ly do loi deu ghi ra file tom tat; Makefile doc dong dau cua file nay.
proc eco_write_summary {path verdict lines} {
    file mkdir [file dirname $path]
    set fp [open $path w]
    puts $fp $verdict
    foreach line $lines {
        puts $fp $line
    }
    foreach msg $::ECO_WARNINGS {
        puts $fp "  WARNING: $msg"
    }
    close $fp
}

# Chan khi da co thiet ke trong RAM: hai script nay restoreDesign roi exit,
# source chung trong mot session dang mo la giet session do.
proc eco_require_no_design {script} {
    set in_mem ""
    catch {set in_mem [dbGet -e top.name]}
    if {$in_mem ne "" && $in_mem ne "0x0" && $in_mem ne "0"} {
        error "Da co thiet ke '$in_mem' trong RAM - $script phai chay trong session\
 Innovus moi (cd mcu/eco && make ...), no restoreDesign roi exit."
    }
}

# Muc 'Check type : max_transition' cua report_constraint -all_violators
# (tempus/reports/all_violators.rpt).  Tra ve {{chan required actual slack view} ...}.
# Ten chan dai thi Tempus xuong dong: ten nam rieng mot dong, 4 cot so o dong sau.
proc eco_tempus_max_tran {rpt} {
    set fp [open $rpt r]
    set in_section 0
    set pending ""
    set out {}
    while {[gets $fp line] >= 0} {
        if {[regexp {^\s*Check type\s*:\s*(\S+)} $line -> type]} {
            set in_section [expr {$type eq "max_transition"}]
            set pending ""
            continue
        }
        if {!$in_section} {
            continue
        }
        set f [regexp -all -inline {\S+} $line]
        set n [llength $f]
        if {$n == 4 || $n == 5} {
            lassign [lrange $f end-3 end] req act slack view
            if {[string is double -strict $req] && [string is double -strict $act] &&
                [string is double -strict $slack] && ![string is double -strict $view]} {
                set pin [expr {$n == 5 ? [lindex $f 0] : $pending}]
                set pending ""
                if {$pin ne ""} {
                    lappend out [list $pin $req $act $slack $view]
                }
                continue
            }
        }
        if {$n == 1 && [string index [lindex $f 0] 0] ne "-"} {
            set pending [lindex $f 0]
        } else {
            set pending ""
        }
    }
    close $fp
    return $out
}

# Dien ap mot .lib khai bao, doc tu dau file toi cell dau tien.  Cung cach doc
# voi tempus_lib_voltage (tempus.tcl) va scripts/fix_ff_lib.py.
proc eco_lib_voltage {lib} {
    set found {}
    set fp [open $lib r]
    set count 0
    while {[gets $fp line] >= 0 && [incr count] <= 20000} {
        if {[regexp {^\s*cell\s*\(} $line]} {
            break
        }
        if {[regexp {^\s*(?:nom_)?voltage\s*:\s*([0-9.]+)} $line -> volt] ||
            [regexp {voltage_map\s*\(\s*"?VDD"?\s*,\s*([0-9.]+)} $line -> volt]} {
            if {[string is double -strict $volt]} {
                lappend found [format %g $volt]
            }
        }
    }
    close $fp
    if {[llength $found] == 0} {
        return "?"
    }
    return [join [lsort -unique $found] /]
}

# Cac .lib std cell ma mot lan restoreDesign se nap: saveDesign chep .lib vao
# <checkpoint>/libs/mmmc/ va viewDefinition.tcl cua checkpoint tro vao do, nen
# sua file trong PDK KHONG doi duoc thu vien cua checkpoint.  Tra ve danh sach
# cau mo ta cac file khai bao dien ap khac so dong cua goc no; rong = on.
proc eco_checkpoint_lib_problems {checkpoint} {
    set problems {}
    foreach corner {SS TT FF} {
        set libs [glob -nocomplain -directory [file join $checkpoint libs mmmc] \
            "asap7sc7p5t_*_${corner}_*.lib"]
        if {[llength $libs] == 0} {
            continue
        }
        array unset group
        foreach lib $libs {
            lappend group([eco_lib_voltage $lib]) [file tail $lib]
        }
        set major ""
        foreach volt [array names group] {
            if {$major eq "" || [llength $group($volt)] > [llength $group($major)]} {
                set major $volt
            }
        }
        foreach volt [lsort [array names group]] {
            if {$volt ne $major} {
                lappend problems "goc $corner: [join $group($volt) {, }] khai bao $volt V,\
 cac lib con lai $major V"
            }
        }
    }
    return $problems
}

# Lay nguyen van mot khoi 'soc_block "<prefix>..." { ... }' tu innovus.tcl.
# Flow chinh la file de paste tung khoi; eco_finish.tcl chay lai dung KHOI 15
# va 16 tu chinh file do de hai noi khong bao gio troi ra khac nhau.
proc eco_flow_block {file prefix} {
    set fp [open $file r]
    set lines [split [read $fp] "\n"]
    close $fp
    set cmd ""
    set found 0
    foreach line $lines {
        if {!$found} {
            if {[string first "soc_block \"$prefix" $line] != 0} {
                continue
            }
            set found 1
        }
        append cmd $line "\n"
        if {[info complete $cmd]} {
            return $cmd
        }
    }
    if {!$found} {
        error "Khong tim thay khoi 'soc_block \"$prefix...' trong $file"
    }
    error "Khoi '$prefix' trong $file khong dong ngoac"
}
