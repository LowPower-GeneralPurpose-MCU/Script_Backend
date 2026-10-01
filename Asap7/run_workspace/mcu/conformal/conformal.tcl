############################################################
## Conformal LEC cho top_soc - buoc tiep theo sau Innovus KHOI 16
##
##   golden  = ../genus/outputs/top_soc_syn.v     netlist Genus (dung file
##                                                init_verilog cua Innovus)
##   revised = ../innovus/outputs/top_soc_pnr.v   saveNetlist o KHOI 16
##
## Chung minh P&R (CTS, buffer hold, resize, doi Vt, tie cell, ecoRoute) khong
## doi chuc nang cua netlist tong hop.  RTL -> netlist tong hop la buoc rieng:
## genus/outputs/genus_mapping_hints.do do Genus tu sinh.
##
## Chay tu thu muc mcu/conformal:   make all
## Viet theo mau src/conformal/conformal (Makefile + conformal.tcl) cua mon
## hoc: doc liberty, doc golden/revised, write_hier_compare_dofile,
## run_hier_compare.  Phan them cho MCU: SRAM + ring oscillator la hop den,
## cong kiem cap netlist, va file ket luan de Makefile doc.
############################################################

# Loi giua chung thi thoat han, khong dung o dau nhac (-nogui se treo make).
set_dofile_abort exit

foreach dir {logs reports} {
    file mkdir $dir
}
# Ket luan cua lan chay truoc khong duoc song sot qua mot lan chay hong.
set VERDICT_FILE ./reports/lec_verdict.txt
file delete -force $VERDICT_FILE

proc lec_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set LEC_WARNINGS {}
proc lec_warn {msg} {
    lappend ::LEC_WARNINGS $msg
    puts "WARNING: $msg"
}

# Chay lenh bao cao cua LEC, in ra log, ghi ra file va tra ve noi dung.
proc lec_capture {rpt_file lec_cmd} {
    redirect -variable lec_out $lec_cmd
    puts $lec_out
    set fp [open $rpt_file w]
    puts $fp $lec_out
    close $fp
    return $lec_out
}

# ------------------------------------------------------------------------
# 0. CAU HINH - dung chung project_config.tcl voi Genus va Innovus
# ------------------------------------------------------------------------
set FLOW_ROOT [file dirname [file normalize [pwd]]]
set mcu_config [file join $FLOW_ROOT genus rtl flow project_config.tcl]
if {![file isfile $mcu_config]} {
    error "Khong thay $mcu_config - phai chay tu thu muc mcu/conformal (make all)"
}
source $mcu_config

set GOLDEN_NETLIST  [lec_env LEC_GOLDEN \
    [file join $FLOW_ROOT genus outputs [format "%s_syn.v" $TOP]]]
set REVISED_NETLIST [lec_env LEC_REVISED \
    [file join $FLOW_ROOT innovus outputs [format "%s_pnr.v" $TOP]]]
# hier = so tung module roi di len (nhu mau); flat = so phang ca thiet ke
# (khoi lenh bi comment trong mau).  Dung flat khi hier bao khac nhau ma nghi
# la do bien module.
set LEC_MODE [lec_env LEC_MODE hier]
if {$LEC_MODE ne "hier" && $LEC_MODE ne "flat"} {
    error "LEC_MODE phai la hier hoac flat, dang la '$LEC_MODE'"
}
set HIER_DOFILE ./hier.do
set RO_MODULE   RingOscillator

# ------------------------------------------------------------------------
# 1. KIEM DAU VAO
# ------------------------------------------------------------------------
# Dung top_soc_pnr.v, KHONG dung top_soc_pnr_pg.v: ban _pg co chan VDD/VSS va
# filler/tap (cho LVS), golden khong co nhung thu do.
foreach {label netlist} [list golden $GOLDEN_NETLIST revised $REVISED_NETLIST] {
    if {![file isfile $netlist] || [file size $netlist] == 0} {
        error "Khong co netlist $label: $netlist"
    }
}

# saveNetlist giu nguyen dong "// Generated on: ..." cua Genus trong netlist
# P&R.  Hai dong khac nhau = Innovus da chay tren mot netlist Genus KHAC ban
# dang dem ra lam golden -> ket qua LEC vo nghia.  (innovus/outputs/ con mot
# ban top_soc_syn.v cu tu 2026-09-14; golden dung la genus/outputs/.)
proc lec_genus_stamp {netlist} {
    set fp [open $netlist r]
    set head [read $fp 4096]
    close $fp
    if {[regexp -line {^// Generated on: (.*)$} $head -> stamp]} {
        return [string trim $stamp]
    }
    return ""
}
set golden_stamp  [lec_genus_stamp $GOLDEN_NETLIST]
set revised_stamp [lec_genus_stamp $REVISED_NETLIST]
if {$golden_stamp eq "" || $revised_stamp eq ""} {
    lec_warn "khong doc duoc dau thoi gian Genus trong netlist - khong kiem duoc golden/revised co cung mot lan tong hop"
} elseif {$golden_stamp ne $revised_stamp} {
    error "Golden va revised khong cung mot lan tong hop:
  golden  : $golden_stamp  ($GOLDEN_NETLIST)
  revised : $revised_stamp  ($REVISED_NETLIST)
  Chay lai Innovus tren netlist Genus hien tai, hoac dat LEC_GOLDEN dung file."
}

foreach lib $ALL_TIMING_LIBS {
    if {![file isfile $lib]} {
        error "Khong co Liberty $lib - dat ASAP7_ROOT / ASAP7_STD_LIB_DIR"
    }
}

# ------------------------------------------------------------------------
# 2. RING OSCILLATOR CUA TRNG - so cau truc bang Tcl
# ------------------------------------------------------------------------
# RingOscillator la vong to hop co chu y (6 INVx1 + 1 NAND2x1).  LEC phai cat
# vong, va diem cat o golden va revised khong chac trung nhau -> khac nhau gia.
# Nen module nay la hop den o ca hai ben (muc 3), LEC chi so day noi vao no.
# Ben trong hop den thi so o day: moi module tu RingOscillator tro xuong phai
# co cung port, cung cell, cung day noi o hai netlist.  Innovus da dont_touch
# 7 cell nay (init_common.tcl) nen khac di la loi that.
proc lec_read_file {path} {
    set fp [open $path r]
    fconfigure $fp -translation binary
    set text [read $fp]
    close $fp
    return $text
}

proc lec_module_body {text name} {
    if {![regexp {^\w+$} $name]} {
        return ""
    }
    set re [format {(?n)^[ \t]*module[ \t]+%s[ \t]*\(} $name]
    if {![regexp -indices -- $re $text hit]} {
        return ""
    }
    set from [expr {[lindex $hit 1] + 1}]
    set to [string first "endmodule" $text $from]
    if {$to < 0} {
        return ""
    }
    return [string range $text $from [expr {$to - 1}]]
}

# Dang chuan cua mot module: port + instance (chan sap theo ten), bo khai bao
# wire va moi khoang trang, de ban Genus va ban Innovus so duoc tung dong.
proc lec_module_canon {body children_var} {
    upvar 1 $children_var children
    set canon {}
    set first 1
    foreach stmt [split $body ";"] {
        if {$first} {
            set first 0
            continue
        }
        regsub -all {\s+} $stmt " " stmt
        set stmt [string trim $stmt]
        if {$stmt eq ""} {
            continue
        }
        if {[regexp {^(input|output|inout) ?(\[[^\]]*\])? ?(.*)$} $stmt -> dir range names]} {
            foreach port [split $names ","] {
                lappend canon "P $dir [string map {{ } {}} $range] [string trim $port]"
            }
            continue
        }
        if {[regexp {^(wire|tri|supply0|supply1) } $stmt]} {
            continue
        }
        if {![regexp {^(\S+) ([^\s(]+) ?\((.*)\)$} $stmt -> type inst pins]} {
            lappend canon "? $stmt"
            continue
        }
        set conn {}
        foreach {all pin net} [regexp -all -inline {\.(\w+) ?\(([^()]*)\)} $pins] {
            lappend conn "$pin=[string map {{ } {}} $net]"
        }
        lappend canon "I $type $inst [join [lsort $conn] ,]"
        lappend children $type
    }
    return [lsort $canon]
}

proc lec_subtree_canon {text root} {
    array set seen {}
    set todo [list $root]
    while {[llength $todo] > 0} {
        set name [lindex $todo 0]
        set todo [lrange $todo 1 end]
        if {[info exists seen($name)]} {
            continue
        }
        set body [lec_module_body $text $name]
        if {$body eq ""} {
            continue
        }
        set children {}
        set seen($name) [lec_module_canon $body children]
        foreach child $children {
            lappend todo $child
        }
    }
    return [array get seen]
}

array set ro_golden  [lec_subtree_canon [lec_read_file $GOLDEN_NETLIST]  $RO_MODULE]
array set ro_revised [lec_subtree_canon [lec_read_file $REVISED_NETLIST] $RO_MODULE]
if {![info exists ro_golden($RO_MODULE)] || ![info exists ro_revised($RO_MODULE)]} {
    error "Khong thay module $RO_MODULE trong golden hoac revised - TRNG da bi toi uu mat?"
}
if {[lsort [array names ro_golden]] ne [lsort [array names ro_revised]]} {
    error "$RO_MODULE: cay module khac nhau
  golden  : [lsort [array names ro_golden]]
  revised : [lsort [array names ro_revised]]"
}
foreach ro_name [lsort [array names ro_golden]] {
    if {$ro_golden($ro_name) ne $ro_revised($ro_name)} {
        error "$RO_MODULE: module $ro_name khac nhau giua golden va revised
  golden  : [join $ro_golden($ro_name) "\n            "]
  revised : [join $ro_revised($ro_name) "\n            "]"
    }
}
puts "Ring oscillator: [array size ro_golden] module duoi $RO_MODULE giong het o golden va revised"

# ------------------------------------------------------------------------
# 3. THU VIEN + HOP DEN
# ------------------------------------------------------------------------
# So luong thread: nhu mau (dem /proc/cpuinfo), nhung tran 4 - dung muc Genus
# tu ghi trong genus_mapping_hints.do cho license nay.  Doi bang LEC_THREADS.
set CORES 1
if {![catch {open "/proc/cpuinfo"} f]} {
    set CORES [regexp -all -line {^processor\s} [read $f]]
    close $f
}
set LEC_THREADS [lec_env LEC_THREADS 4]
if {![string is integer -strict $LEC_THREADS] || $LEC_THREADS < 1} {
    error "LEC_THREADS phai la so nguyen >= 1, dang la '$LEC_THREADS'"
}
if {$CORES > $LEC_THREADS} {
    set CORES $LEC_THREADS
}
if {$CORES < 1} {
    set CORES 1
}
set_parallel_option -threads $CORES -norelease_license

set_mapping_method -sensitive

# Hop den phai khai TRUOC khi doc thu vien / thiet ke.
#   - 2 master SRAM: .lib chi co timing, khong co function (nhu Genus da lam).
#   - RingOscillator: xem muc 2.
# Mau dung -BBOXUNResolve (module nao thieu cung thanh hop den).  O day KHONG
# dung: cell thieu dinh nghia phai la loi, neu khong LEC "dat" tren hop den.
add_notranslate_modules -library -both $SRAM_MASTER $SRAM_TAG_MASTER
add_notranslate_modules -both $RO_MODULE

# Goc TT la du: LEC chi doc function, ten cell giong nhau o ca ba goc.
eval read_library -liberty -replace -both $ALL_TIMING_LIBS

# ------------------------------------------------------------------------
# 4. DOC THIET KE
# ------------------------------------------------------------------------
read_design -verilog -sensitive -golden -noelab $GOLDEN_NETLIST
elaborate_design -golden -root $TOP

read_design -verilog -sensitive -revised -noelab $REVISED_NETLIST
elaborate_design -revised -root $TOP

report_design_data

# Hop den mong doi: 2 master SRAM + RingOscillator, co o ca golden lan revised.
# Cell thu vien khong co function (LEC khong mo hinh duoc) cung hien o day; hai
# ben van duoc so chan-voi-chan nen chi canh bao, khong chan.
set bbox_rpt [lec_capture ./reports/lec_black_box.rpt {report_black_box}]
set bbox_expected [list $SRAM_MASTER $SRAM_TAG_MASTER $RO_MODULE]
set bbox_seen {}
foreach line [split $bbox_rpt "\n"] {
    if {[regexp {^\s*(SYSTEM|USER)\s*:\s*\(([GR ]+)\)\s+(\S+)} $line -> kind sides name]} {
        lappend bbox_seen $name
        if {[lsearch -exact $bbox_expected $name] < 0} {
            lec_warn "hop den ngoai du kien: $name ($kind, [string trim $sides]) - xem reports/lec_black_box.rpt"
        } elseif {![string match "*G*" $sides] || ![string match "*R*" $sides]} {
            lec_warn "hop den $name chi co o mot ben ([string trim $sides])"
        }
    }
}
if {[llength $bbox_seen] == 0} {
    lec_warn "khong doc duoc dinh dang report_black_box - tu kiem reports/lec_black_box.rpt: chi duoc co $bbox_expected"
} else {
    foreach name $bbox_expected {
        if {[lsearch -exact $bbox_seen $name] < 0} {
            lec_warn "$name khong nam trong danh sach hop den - xem reports/lec_black_box.rpt"
        }
    }
}

# ------------------------------------------------------------------------
# 5. MO HINH
# ------------------------------------------------------------------------
# CTS co the nhan ban / gop ICG; -gated_clock de latch cua ICG khong thanh diem
# so sanh le doi.  Khong bat -seq_constant: Innovus khong xoa flop, bat len chi
# lam phep so long hon.
set_flatten_model -gated_clock
set_analyze_option -auto

# ------------------------------------------------------------------------
# 6. SO SANH
# ------------------------------------------------------------------------
if {$LEC_MODE eq "hier"} {
    # Tham so nhu mau.  -noexact_pin_match: optDesign them port FE_OFN/FE_PHN
    # xuyen module.  -dynamic_hierarchy: module nao so khong xong thi gop vao
    # module cha roi so lai, thay vi bao khac nhau gia o bien module.
    write_hier_compare_dofile $HIER_DOFILE -replace -usage -verbose -noexact_pin_match \
        -constraint -threshold 50 -balanced_extraction -input_output_pin_equivalence

    run_hier_compare $HIER_DOFILE -dynamic_hierarchy

    lec_capture ./reports/lec_hier_result.rpt {report_hier_compare_result -all -usage}
    set verification_rpt [lec_capture ./reports/lec_verification.rpt \
        {report_verification -hier -verbose}]
    set_system_mode lec
} else {
    set_system_mode lec
    add_compared_points -all
    compare
    set verification_rpt [lec_capture ./reports/lec_verification.rpt \
        {report_verification -verbose}]
}

# O che do hier ba bao cao nay chi con noi ve module top (cac module con da
# duoc so rieng, xem lec_hier_result.rpt); o che do flat la ca thiet ke.
lec_capture ./reports/lec_unmapped.rpt {report_unmapped_points -summary}
lec_capture ./reports/lec_noneq.rpt \
    {report_compare_data -class nonequivalent -class abort -class notcompared}
report_statistics

# ------------------------------------------------------------------------
# 7. KET LUAN
# ------------------------------------------------------------------------
set n_total   [get_compare_points -count]
set n_noneq   [get_compare_points -NONequivalent -count]
set n_abort   [get_compare_points -abort -count]
set n_unknown [get_compare_points -unknown -count]
set lec_pass  [regexp {Compare Results:\s+PASS} $verification_rpt]

# Chi PASS khi bao cao cua LEC ghi PASS VA khong con diem khac/abort.  Bat ky
# truong hop nao khac deu khong duoc coi la dat - ke ca khi khong doc duoc
# dinh dang bao cao (UNKNOWN).
if {$n_noneq > 0 || $n_abort > 0} {
    set verdict FAIL
} elseif {$LEC_MODE eq "flat" && ($n_unknown > 0 || $n_total == 0)} {
    set verdict FAIL
} elseif {$lec_pass} {
    set verdict PASS
} elseif {[regexp {Compare Results:\s+(\S+)} $verification_rpt -> lec_result]} {
    set verdict FAIL
} else {
    set verdict UNKNOWN
}

set fp [open $VERDICT_FILE w]
puts $fp $verdict
puts $fp "LEC $TOP: netlist tong hop vs netlist sau P&R (che do $LEC_MODE)"
puts $fp "  golden  : $GOLDEN_NETLIST"
puts $fp "  revised : $REVISED_NETLIST"
puts $fp "  Genus   : $golden_stamp"
puts $fp "  diem so sanh $n_total, khac $n_noneq, abort $n_abort, chua so $n_unknown"
if {$LEC_MODE eq "hier"} {
    puts $fp "  (so diem la cua module top; tung module: reports/lec_hier_result.rpt)"
}
if {$verdict eq "UNKNOWN"} {
    puts $fp "  Khong thay dong 'Compare Results' trong reports/lec_verification.rpt - doc tay."
}
foreach msg $LEC_WARNINGS {
    puts $fp "  WARNING: $msg"
}
close $fp

set fp [open $VERDICT_FILE r]
puts "============================================================"
puts -nonewline [read $fp]
puts "============================================================"
close $fp

vpxmode
exit -f
