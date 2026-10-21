############################################################
## Proc dung chung cua mcu/eco (eco_drv.tcl, eco_fillfix.tcl, eco_finish.tcl).
## Nua tren chi co Tcl thuan - thu duoc bang tclsh.  Cac proc goi lenh Innovus
## nam o cuoi file, sau dong "PROC GOI LENH INNOVUS"; source file nay bang tclsh
## van duoc vi than proc chua chay.
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

# Derate OCV chung: cung bien moi truong (MCU_OCV_DERATE_LATE / _EARLY), cung
# mac dinh 1.0 va cung kiem tra voi innovus/tcl/init_common.tcl va tempus.tcl.
# Tra ve {late early}.
proc eco_ocv_derates {} {
    set values {}
    foreach name {MCU_OCV_DERATE_LATE MCU_OCV_DERATE_EARLY} {
        set value [eco_env $name 1.0]
        if {![string is double -strict $value] || $value <= 0} {
            error "$name phai la so duong, dang la '$value'"
        }
        lappend values [expr {double($value)}]
    }
    return $values
}

# Derate OCV ma lan Tempus da ghi <summary> dung: dong "OCV chung late x<a> /
# early x<b>" cua tempus.tcl.  Tra ve {late early}; rong neu khong doc duoc.
proc eco_tempus_ocv {summary} {
    if {![file isfile $summary]} {
        return {}
    }
    set fp [open $summary r]
    set text [read $fp]
    close $fp
    if {[regexp {OCV chung late x(\S+) / early x(\S+)} $text -> late early] &&
        [string is double -strict $late] && [string is double -strict $early]} {
        return [list $late $early]
    }
    return {}
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

# Muc 'max_delay/setup' va 'min_delay/hold' cua cung file: so endpoint
# VIOLATED va slack xau nhat.  Tra ve dict {setup {n wns} hold {n wns}}.  Ten
# endpoint dai thi Tempus xuong dong: slack + VIOLATED nam o dong sau, nen dem
# theo chu VIOLATED chu khong theo ten.
proc eco_tempus_timing_viol {rpt} {
    set out [dict create setup {0 0.0} hold {0 0.0}]
    set fp [open $rpt r]
    set section ""
    while {[gets $fp line] >= 0} {
        if {[regexp {^\s*max_delay/setup\s*$} $line]} {
            set section setup
            continue
        }
        if {[regexp {^\s*min_delay/hold\s*$} $line]} {
            set section hold
            continue
        }
        if {[regexp {^\s*Check type\s*:} $line]} {
            set section ""
            continue
        }
        if {$section eq "" || ![regexp {(\S+)\s+VIOLATED\M} $line -> slack]} {
            continue
        }
        lassign [dict get $out $section] n wns
        incr n
        if {[string is double -strict $slack] && $slack < $wns} {
            set wns $slack
        }
        dict set out $section [list $n $wns]
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
# sua file trong PDK KHONG doi duoc thu vien cua checkpoint.  Tra ve cac file
# khai bao dien ap khac so dong cua goc no, moi file mot muc
# {goc ten_file dien_ap dien_ap_da_so}; rong = on.
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
                foreach name [lsort $group($volt)] {
                    lappend problems [list $corner $name $volt $major]
                }
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

# Thoi diem moi nhat mot checkpoint <ten>.enc.dat duoc ghi: mtime lon nhat cua
# thu muc va cac muc truc tiep ben trong (saveDesign ghi de file ben trong
# khong nhat thiet doi mtime cua chinh thu muc).  File thuong: mtime cua no.
proc eco_checkpoint_mtime {path} {
    set newest [file mtime $path]
    if {[file isdirectory $path]} {
        foreach child [glob -nocomplain -directory $path *] {
            if {[file mtime $child] > $newest} {
                set newest [file mtime $child]
            }
        }
    }
    return $newest
}

# CONG TUOI (them 2026-10-13).  <path> phai duoc ghi SAU <base>; khong thi nem
# loi kem <why>.  Moi buoc ECO doc ket qua cua buoc truoc tu file tren dia, va
# cac file do song sot qua mot lan chay lai Innovus: sau khi luoi nguon doi,
# tempus/reports/all_violators.rpt (0 vi pham, cua thiet ke CU) lam 'make all'
# khong lam gi, roi 'make fillfix' / 'make finish' mo
# top_soc_postRoute_eco*.enc.dat cua lan chay TRUOC va ghi de outputs/ bang
# thiet ke cu - khong lenh nao bao.  ECO_ALLOW_STALE=1 ha xuong WARNING.
proc eco_require_fresh {what path base_what base why} {
    if {![file exists $path] || ![file exists $base]} {
        return
    }
    set t [eco_checkpoint_mtime $path]
    set t_base [eco_checkpoint_mtime $base]
    if {$t >= $t_base} {
        return
    }
    set msg [format "%s (%s) cu hon %s (%s) %.1f gio - %s" $what $path $base_what $base \
        [expr {($t_base - $t) / 3600.0}] $why]
    if {[eco_env ECO_ALLOW_STALE 0] eq "1"} {
        eco_warn "ECO_ALLOW_STALE=1: $msg"
        return
    }
    error "$msg
  Bo qua co chu dich: them ECO_ALLOW_STALE=1 vao lenh make."
}

# Dong dau cua mot file tom tat (PASS / FAIL / DONE); "" neu chua co file.
proc eco_summary_verdict {path} {
    if {![file isfile $path]} {
        return ""
    }
    set fp [open $path r]
    gets $fp line
    close $fp
    return [string trim $line]
}

# Bao cao <prefix>.tran cua timeDesign ->
#   {{net slack pin cellport limit loads drvlim} ...}
# cua vi pham THAT (remark R), xep tu xau nhat.  slack/pin/cellport/limit la cua
# chan xau nhat tren net; loads la moi chan vi pham KHONG phai dau ra cua cell,
# xau nhat truoc (dung cho ecoAddRepeater -term); drvlim = 1 khi chinh chan
# DAU RA cua driver cung nam trong danh sach vi pham.
#
# drvlim la thu phan biet hai loai net (run fillfix 2026-10-12, 511 net):
#   drvlim 1 (452 net) driver yeu: slew da xau ngay tai chan ra cua no.  Chen
#            mot buffer manh hon noi tiep la het - khong net nao quay lai.
#   drvlim 0 (59 net)  driver du manh (vd BUFx10 keo wd[*] cua 11 SRAM), slew
#            chi xau o cuoi day.  Chen BUFx4 noi tiep = thay driver manh bang
#            driver yeu hon: mem_wdata_19 tu +6 ps thanh -94 ps.
#
# Mot dong chan:
#   <chan>  <max>r/<max>f  <tran>r/<tran>f  <slack>r/<slack>f  [cell/port]  R
# Port cua top khong co cot cell/port.
proc eco_tran_report {text} {
    set net ""
    set order {}
    array set worst {}
    array set loads {}
    array set drvlim {}
    foreach line [split $text \n] {
        if {[string index $line 0] eq "#" || [string trim $line] eq ""} {
            continue
        }
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
        set rf {}
        foreach tok $f {
            if {[regexp {^(-?[0-9.]+)r/(-?[0-9.]+)f$} $tok -> r_val f_val]} {
                lappend rf [list $r_val $f_val]
            }
        }
        if {[llength $rf] < 3} {
            continue
        }
        lassign [lindex $rf 0]   lim_r lim_f
        lassign [lindex $rf end] slk_r slk_f
        if {$slk_r <= $slk_f} {
            set slack $slk_r
            set limit $lim_r
        } else {
            set slack $slk_f
            set limit $lim_f
        }
        set pin [lindex $f 0]
        set cellport ""
        if {[llength $f] >= 6} {
            set cellport [lindex $f end-1]
        }
        if {![info exists worst($net)]} {
            lappend order $net
            set loads($net) {}
            set drvlim($net) 0
        }
        if {![info exists worst($net)] || $slack < [lindex $worst($net) 0]} {
            set worst($net) [list $slack $pin $cellport $limit]
        }
        # Ten dau ra cua std cell ASAP7: Y, Q, QN, CON, SN, GCLK; cua SRAM:
        # dataout[N].  Chan con lai cua instance la chan tai.  Port cua top
        # (khong co cot cell/port) khong tinh vao ben nao.
        if {[regexp {/(Y|Q|QN|CON|SN|GCLK|dataout\[[0-9]+\])$} $cellport]} {
            set drvlim($net) 1
        } elseif {$cellport ne ""} {
            lappend loads($net) [list $slack $pin]
        }
    }
    set out {}
    foreach net $order {
        set pins {}
        foreach item [lsort -real -index 0 $loads($net)] {
            lappend pins [lindex $item 1]
        }
        lappend out [concat [list $net] $worst($net) [list $pins $drvlim($net)]]
    }
    return [lsort -real -index 1 $out]
}

# Cac dong 'set_max_transition [co] <gia tri> [get_clocks ...]' trong cac file
# SDC -> {{co gia_tri {clock ...}} ...}, bo dong trung.  Day la gioi han 150 ps
# cua ho CLK_SYS (genus/tcl/constraint.sdc): dat tren CLOCK nen ap cho ca duong
# du lieu cua clock do, con 'set_max_transition 0.3 [current_design]' chi la
# tran chung.  writeTimingCon cua Innovus tach thanh hai dong -clock_path /
# -data_path nen phai giu ca co.
proc eco_sdc_clock_max_tran {files} {
    set out {}
    foreach file $files {
        if {![file isfile $file]} {
            continue
        }
        set fp [open $file r]
        while {[gets $fp line] >= 0} {
            if {![regexp {^\s*set_max_transition\s+((?:-[A-Za-z_]+\s+)*)([0-9.eE+-]+)\s+\[\s*get_clocks\s+\{?\s*([^\]\}]*?)\s*\}?\s*\]\s*$} \
                    $line -> flags value clocks]} {
                continue
            }
            if {![string is double -strict $value] || [llength $clocks] == 0} {
                continue
            }
            set item [list [regexp -all -inline {\S+} $flags] $value $clocks]
            if {[lsearch -exact $out $item] < 0} {
                lappend out $item
            }
        }
        close $fp
    }
    return $out
}

# Slack theo gioi han THAT cua mot dong eco_tran_report do duoc khi gioi han
# dang bi siet 'guard' ns.  Chan khong thuoc clock nao bi siet (chi chiu tran
# chung cua design) thi gioi han in ra khong nam trong 'tight_limits' va slack
# giu nguyen.
proc eco_real_slack {slack limit tight_limits guard} {
    if {$guard > 0.0 && [lsearch -exact $tight_limits [format %.3f $limit]] >= 0} {
        return [expr {$slack + $guard}]
    }
    return $slack
}

# So net ma luot DRV cuoi cung trong log Innovus bo lai vi "can't be fixed by
# DRV optimization", kem cac dong ly do.  Tra ve {so {ly_do ...}}; {-1 {}} neu
# log khong co dong do.  Voi drcMargin > 0 day la cac net nam trong khoang
# (gioi han x (1 - margin), gioi han]: bang DRV van ghi 0 nhung khong con chut
# du nao - run 2026-10-12 chinh nhung net nay vuot gioi han sau metal fill.
proc eco_log_unfixed_drv {log} {
    if {![file isfile $log]} {
        return [list -1 {}]
    }
    set count -1
    set reasons {}
    set fp [open $log r]
    while {[gets $fp line] >= 0} {
        if {[regexp {Total\s+([0-9]+)\s+net\(s\) have violations which can't be fixed} $line -> n]} {
            set count $n
            set reasons {}
        } elseif {$count >= 0 && [regexp {^\*info:\s+([0-9]+ net\(s\): .*\S)\s*$} $line -> why]} {
            lappend reasons $why
        }
    }
    close $fp
    return [list $count $reasons]
}


############################################################
## PROC GOI LENH INNOVUS
############################################################

# Derate OCV chung cho moi cell va net.  Truoc 2026-10-21 cac buoc ECO chi nhan
# MCU_OCV_DERATE_EARLY vao he so lib FF, moi cell khac van x1.0: Tempus OCV
# 1.05 / 0.95 (run 15:04) bao 14 endpoint hold view_ff am toi 5 ps ma luot
# optDesign -hold o day khong thay duong nao.  Goi TRUOC derate SRAM va lib
# FF: derate theo doi tuong thay the derate chung, va lenh khong -delay_corner
# dat sau chung co the doi cach hieu cua chung (TCLCMD-1725).  Dat ca khi bang
# 1.0: checkpoint cua mot lan Innovus co bat OCV co the con giu 1.05 / 0.95,
# trong khi he so lib FF ben duoi tinh theo bien moi truong.  Tra ve ghi chu.
proc eco_apply_ocv_derate {late early} {
    set_timing_derate -late  -cell_delay -net_delay -cell_check $late
    set_timing_derate -early -cell_delay -net_delay -cell_check $early
    if {$late == 1.0 && $early == 1.0} {
        eco_warn "khong co derate OCV chung (1.0): setup / hold sau ECO chua tinh bien\
 thien tren chip, Tempus bat OCV se thay vi pham ma ECO khong sua; bat:\
 MCU_OCV_DERATE_LATE=1.05 MCU_OCV_DERATE_EARLY=0.95 (cung bo so voi mcu/tempus)"
        return "OCV chung tat (1.0)"
    }
    return "OCV chung late x$late / early x$early"
}

# Derate OCV chung, derate SRAM, derate lib FF dien ap thap va dont_touch TRNG
# dat o KHOI 0 (init_common.tcl) va duoc eco_drv.tcl dat lai sau restoreDesign.
# Hai buoc sau (eco_fillfix.tcl, eco_finish.tcl) mo checkpoint do eco_drv.tcl
# luu; dat lai cung gia tri o day de ket luan hold cua chung khong phu thuoc vao
# viec saveDesign co giu derate hay khong.  Tra ve ghi chu mot dong.
proc eco_session_constraints {} {
    global SRAM_MASTER SRAM_TAG_MASTER SRAM_EXPECTED_COUNT SRAM_TAG_EXPECTED_COUNT
    global SRAM_DERATE_SS SRAM_DERATE_FF
    lassign [eco_ocv_derates] ocv_late ocv_early
    set ocv_note [eco_apply_ocv_derate $ocv_late $ocv_early]
    set sram_insts [get_cells -hierarchical -filter \
        "ref_name =~ ${SRAM_MASTER}* || ref_name =~ ${SRAM_TAG_MASTER}*"]
    set sram_expected [expr {$SRAM_EXPECTED_COUNT + $SRAM_TAG_EXPECTED_COUNT}]
    if {[sizeof_collection $sram_insts] != $sram_expected} {
        error "Derate SRAM: tim thay [sizeof_collection $sram_insts] macro, doi $sram_expected"
    }
    foreach {corner side factor} [list dc_ss -late $SRAM_DERATE_SS dc_ff -early $SRAM_DERATE_FF] {
        if {[catch {set_timing_derate -delay_corner $corner $side -cell_delay -cell_check \
                $factor $sram_insts} derate_err]} {
            eco_warn "set_timing_derate $corner $side x$factor cho SRAM bi tu choi: $derate_err"
        }
    }
    set ff_note [mcu_apply_ff_lowv_derate $ocv_early]
    if {$ff_note eq ""} {
        set ff_note "tat (STD_FF_LOWV_DERATE 1.0)"
    }
    set ro_ptrs [dbGet -e -p top.insts.name u_apb_ascon_u_trng_ro/*]
    if {[llength $ro_ptrs] != 7} {
        error "TRNG ring oscillator: tim thay [llength $ro_ptrs] cell, doi 7"
    }
    foreach ro_ptr $ro_ptrs {
        set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
    }
    return "$ocv_note; SRAM dc_ss late x$SRAM_DERATE_SS / dc_ff early x$SRAM_DERATE_FF;\
 lib FF dien ap thap: $ff_note"
}

# Dat gioi han max_transition theo clock = gia tri goc - delta (delta 0 = tra
# ve gia tri goc).  limits: ket qua cua eco_sdc_clock_max_tran.
# Di het MOI dong roi moi bao loi: goi lai voi delta 0 sau mot lan hong thi
# dong nao da siet duoc cung duoc tra ve, khong dung lai o dong hong dau tien.
proc eco_set_clock_max_tran {limits delta} {
    set errors {}
    set_interactive_constraint_modes [all_constraint_modes -active]
    foreach item $limits {
        lassign $item flags value clocks
        if {[catch {set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]] \
                [get_clocks $clocks]} err]} {
            lappend errors "$clocks: $err"
        }
    }
    set_interactive_constraint_modes {}
    if {[llength $errors] > 0} {
        error "set_max_transition hong o [llength $errors] / [llength $limits] dong\
 ([lindex $errors 0])"
    }
}

# Xoa het metal fill.  Dung dang '-layer <mot layer>': dang nay da chay duoc
# tren Innovus 23.14 (quantus.tcl, deleteMetalFill -layer Pad).
proc eco_delete_metal_fill {} {
    foreach {layer wmin wmax decr lmin lmax gap active dmin dmax dpref} $::SOC_FILL_LAYERS {
        deleteMetalFill -layer $layer
    }
}

# Sua tung net bang ecoAddRepeater.
#   items : {{net slack_that pin cellport limit loads drvlim} ...}
#   cell / strong : buffer thuong / buffer manh
#   dist  : -relativeDistToSink cho net MOT tai (1 = sat driver)
#   viol_below : slack_that < gia tri nay = vi pham that, con lai la net chi
#                nam trong khoang du
# Tra ve {{net cach ghi_chu} ...}; cach:
#   dist  net mot tai: buffer doc theo day, sat driver
#   net   net nhieu tai, driver yeu: buffer noi tiep, keo moi tai
#   split net nhieu tai, driver du manh, vi pham that: buffer manh keo NUA so
#         tai xau nhat (-term), driver cu giu nua con lai
#   skip  net nhieu tai, driver du manh, chi nam trong khoang du: KHONG dung
#   ""    khong chen duoc
#
# Vi sao tu chen ma khong goi lai optDesign -drv: run 2026-10-12 optDesign bo
# lai 126 net "can't be fixed" (84 "instance couldn't be resized", 42 "no move
# is found") va cac net vuot gioi han sau metal fill nam trong so do.
#
# Luat duoi day la tu run fillfix 2026-10-12 21:13 (400 net, Innovus 23.14):
#   - -relativeDistToSink chi nhan net MOT tai (IMPOPT-3135): 114 net, khong
#     net nao quay lai.
#   - ecoAddRepeater -net tran chen buffer keo MOI tai.  Voi driver yeu
#     (drvlim 1) khong net nao quay lai.  Voi driver manh (drvlim 0) 5 / 20 net
#     hong: BUFx10 keo wd[19] cua 11 SRAM bi thay bang BUFx4, +6 ps -> -94 ps,
#     va vong sau chen them BUFx4 nua vao dung cho do nen khong bao gio het.
proc eco_buffer_nets {items cell strong dist viol_below} {
    set results {}
    setEcoMode -batchMode true -refinePlace false -updateTiming false
    set failed [catch {
        foreach item $items {
            lassign $item net real pin cellport limit loads drvlim
            # Ten tran, khong boc [list ...]: get_pins -quiet <ten co [N]> cua
            # eco_drv.tcl da tim du 220 chan cua Tempus (run 2026-10-12).
            set obj [get_nets -quiet $net]
            if {[sizeof_collection $obj] != 1} {
                lappend results [list $net "" "khong tim thay net"]
                continue
            }
            set name [get_object_name $obj]
            set note ""
            if {![catch {ecoAddRepeater -net $name -cell $cell \
                    -relativeDistToSink $dist} note]} {
                lappend results [list $net dist ""]
                continue
            }
            # Tu day la net nhieu tai.
            if {$drvlim} {
                if {![catch {ecoAddRepeater -net $name -cell $cell} note]} {
                    lappend results [list $net net ""]
                } else {
                    lappend results [list $net "" [string map [list \n " "] $note]]
                }
                continue
            }
            if {$real >= $viol_below} {
                lappend results [list $net skip ""]
                continue
            }
            if {[llength $loads] == 0} {
                lappend results [list $net "" "driver manh, khong co chan tai nao trong bao cao"]
                continue
            }
            set half [lrange $loads 0 [expr {([llength $loads] + 1) / 2 - 1}]]
            if {![catch {ecoAddRepeater -term $half -cell $strong} note]} {
                lappend results [list $net split "[llength $half] / [llength $loads] chan tai"]
            } elseif {![catch {ecoAddRepeater -term [list [lindex $loads 0]] -cell $strong} note]} {
                lappend results [list $net split "1 / [llength $loads] chan tai"]
            } else {
                lappend results [list $net "" [string map [list \n " "] $note]]
            }
        }
    } msg opts]
    setEcoMode -batchMode false -refinePlace true -updateTiming true
    if {$failed} {
        return -options $opts $msg
    }
    refinePlace
    return $results
}
