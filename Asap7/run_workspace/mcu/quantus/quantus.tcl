############################################################
## Quantus: trich RC signoff cho top_soc - buoc tiep theo sau Conformal LEC
##
## Chay bang Innovus, tu thu muc mcu/innovus (Makefile lo viec cd):
##     cd Asap7/run_workspace/mcu/quantus && make all
##
##   vao : ../innovus/saved/top_soc_final.enc.dat   (KHOI 15: da co filler +
##                                                   metal fill, DRC sach)
##   ra  : outputs/top_soc_quantus_{rc_typ,rc_ss,rc_ff}.spef   cho Tempus
##         reports/quantus_summary.rpt
##
## Vi sao can buoc nay: ca flow Innovus (KHOI 13-16) trich RC bang tQuantus
## (setExtractRCMode -effortLevel medium), ke ca SPEF ma KHOI 16 xuat ra.  Moi
## con so timing dang co deu dung tren RC do.  O day trich lai bang Quantus QRC
## (effortLevel signoff, co tu ghep) de STA signoff co RC doc lap voi cong cu
## da toi uu thiet ke.
##
## Viet theo mau Asap7/Script/quantus/quantus.tcl (Mul32): restoreDesign,
## deleteMetalFill -layer Pad, setExtractRCMode signoff, extractRC, rcOut.
## Script nay KHONG saveDesign: moi thay doi (xoa fill Pad) chi nam trong RAM.
############################################################

# Chan TRUOC khoi catch (khong goi exit): neu ai do source file nay trong mot
# session Innovus dang mo thi chi bao loi, khong giet session cua ho.
set quantus_in_mem ""
catch {set quantus_in_mem [dbGet -e top.name]}
if {$quantus_in_mem ne "" && $quantus_in_mem ne "0x0" && $quantus_in_mem ne "0"} {
    error "Da co thiet ke '$quantus_in_mem' trong RAM - quantus.tcl phai chay\
 trong session Innovus moi (make all), no restoreDesign roi exit."
}

set QUANTUS_DIR [file dirname [file normalize [info script]]]

proc quantus_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

# Dem net, cong tong dien dung va tong dien tro cua mot file SPEF.
# Tra ve {so_net tong_fF tong_ohm}.  Can ca R: ba goc RC dung chung mot QRC
# tech file, chi khac nhiet do, nen C giong het nhau va chi R moi cho thay ba
# goc co khac nhau that hay khong.
proc quantus_spef_stats {path} {
    set fp [open $path r]
    fconfigure $fp -translation binary -buffersize 1048576
    set nets 0
    set cap 0.0
    set res 0.0
    set to_ff 1.0
    set to_ohm 1.0
    set in_res 0
    while {[gets $fp line] >= 0} {
        if {[string index $line 0] ne "*"} {
            # Trong muc *RES moi dong la "<so> <nut> <nut> <R>".
            if {$in_res} {
                set r [lindex [split [string trimright $line]] end]
                if {[string is double -strict $r]} {
                    set res [expr {$res + $r}]
                }
            }
            continue
        }
        set in_res 0
        if {[string range $line 0 6] eq "*D_NET "} {
            if {[regexp {^\*D_NET\s+\S+\s+(\S+)} $line -> net_cap] &&
                [string is double -strict $net_cap]} {
                incr nets
                set cap [expr {$cap + $net_cap}]
            }
        } elseif {[string range $line 0 3] eq "*RES"} {
            set in_res 1
        } elseif {[regexp {^\*C_UNIT\s+(\S+)\s+(\S+)} $line -> scale unit]} {
            switch -- [string toupper $unit] {
                PF      { set to_ff [expr {$scale * 1000.0}] }
                FF      { set to_ff [expr {$scale * 1.0}] }
                default { error "$path: *C_UNIT la '$unit' - chi biet PF va FF" }
            }
        } elseif {[regexp {^\*R_UNIT\s+(\S+)\s+(\S+)} $line -> scale unit]} {
            switch -- [string toupper $unit] {
                OHM     { set to_ohm [expr {$scale * 1.0}] }
                KOHM    { set to_ohm [expr {$scale * 1000.0}] }
                default { error "$path: *R_UNIT la '$unit' - chi biet OHM va KOHM" }
            }
        }
    }
    close $fp
    return [list $nets [expr {$cap * $to_ff}] [expr {$res * $to_ohm}]]
}

# Bang ghep lop ma IQuantus in ra log cua chinh phien nay:
#     db Layer M2 with id 2 --> m1  4
# Tra ve dict {lop_LEF lop_QRC}; rong neu engine khong in bang nay.
proc quantus_layer_pairs {log_file} {
    set pairs [dict create]
    if {![file isfile $log_file]} {
        return $pairs
    }
    set fp [open $log_file r]
    while {[gets $fp line] >= 0} {
        if {[regexp {^db Layer (\S+) with id \d+ --> (\S+)} $line -> lef tech]} {
            dict set pairs $lef $tech
        }
    }
    close $fp
    return $pairs
}

# Cac cap ghep sai trong bang tren: M1..M9 va V1..V8 phai ghep dung ten.
proc quantus_layer_mismatches {pairs} {
    set bad {}
    dict for {lef tech} $pairs {
        if {[regexp {^(M[1-9]|V[1-8])$} $lef] &&
            [string tolower $lef] ne [string tolower $tech]} {
            lappend bad "$lef->$tech"
        }
    }
    return $bad
}

# Innovus chay -no_gui: loi Tcl giua chung se dung o dau nhac va treo make.
# Boc ca flow trong catch de luon thoat voi ma loi ro rang.
if {[catch {
    if {![file isfile ./tcl/project_config.tcl]} {
        error "Khong thay ./tcl/project_config.tcl - phai chay tu thu muc mcu/innovus\
 (cd mcu/quantus && make all)"
    }
    source ./tcl/project_config.tcl

    foreach dir {outputs reports logs} {
        file mkdir [file join $QUANTUS_DIR $dir]
    }
    set QUANTUS_SUMMARY [file join $QUANTUS_DIR reports quantus_summary.rpt]
    file delete -force $QUANTUS_SUMMARY

    set QUANTUS_CHECKPOINT [quantus_env QUANTUS_CHECKPOINT \
        [format "./saved/%s_final.enc.dat" $TOP]]
    if {![file isdirectory $QUANTUS_CHECKPOINT]} {
        error "Khong co checkpoint $QUANTUS_CHECKPOINT - chay Innovus den het KHOI 15"
    }
    if {![file isfile $QRC_FILE]} {
        error "Khong co QRC tech file $QRC_FILE"
    }
    # Ghep lop LEF <-> QRC theo TEN.  Run 2026-10-10 00:48 khong co file nay:
    # Innovus ghep theo vi tri (M1 --> lisd, M2 --> m1, ... Pad --> m9), SPEF
    # ra van bao DONE nhung moi lop duoc trich bang thong so cua lop ben duoi.
    #   LEF : M1 M2 M3 M4 M5 M6 M7 M8 M9 Pad
    #   QRC : LISD M1 M2 M3 M4 M5 M6 M7 M8 M9
    # Flow Innovus chinh cung lech nhu vay (innovus.log: "#LISD -> M1 (1)").
    # File map phai la cu phap CCL cua Quantus (extraction_setup
    # -technology_layer_map "LEF" "QRC" ...): run 16:43 dung dinh dang 3 cot
    # "metal M1 M1" va bi IMPEXT-1438 "Only CCL style syntax ... is supported",
    # Innovus quay ve ghep tu dong.  File map KHONG co dong chu thich nao vi
    # chua biet CCL nhan ky tu chu thich nao.  Pad va V9 khong co lop tuong
    # ung trong QRC tech file nen khong nam trong map.
    set QUANTUS_LAYER_MAP [file normalize ./tcl/asap7_lef_to_qrc_layers.map]
    if {![file isfile $QUANTUS_LAYER_MAP]} {
        error "Khong co file ghep lop $QUANTUS_LAYER_MAP"
    }
    # Log cua chinh phien nay (Makefile: -log ../quantus/logs/quantus).
    set QUANTUS_LOG [file join $QUANTUS_DIR logs quantus.log]
    set quantus_warn {}

    # signoff = Quantus QRC rieng (can lenh 'qrc' + license Quantus).
    # high    = IQuantus tich hop trong Innovus: dung khi may khong co qrc.
    set QUANTUS_EFFORT [quantus_env QUANTUS_EFFORT signoff]
    if {$QUANTUS_EFFORT ne "signoff" && $QUANTUS_EFFORT ne "high"} {
        error "QUANTUS_EFFORT phai la signoff hoac high, dang la '$QUANTUS_EFFORT'"
    }
    if {$QUANTUS_EFFORT eq "signoff"} {
        # Innovus goi 'qrc' qua PATH.  QRC_BIN = duong dan day du toi lenh qrc
        # neu no khong nam san trong PATH.
        set qrc_bin [quantus_env QRC_BIN ""]
        if {$qrc_bin ne ""} {
            if {![file executable $qrc_bin]} {
                error "QRC_BIN=$qrc_bin khong phai file chay duoc"
            }
            set ::env(PATH) "[file dirname [file normalize $qrc_bin]]:$::env(PATH)"
        }
        if {[auto_execok qrc] eq ""} {
            error "Khong thay lenh 'qrc' trong PATH - can Quantus cho effortLevel signoff.
  Dat QRC_BIN=<duong dan toi qrc>, hoac chay 'make all QUANTUS_EFFORT=high'
  de dung IQuantus tich hop (khong can qrc)."
        }
        puts "Quantus: dung [auto_execok qrc]"
    }

    set rc_corners {rc_typ rc_ss rc_ff}
    set quantus_spef {}
    foreach rc $rc_corners {
        set spef [file join $QUANTUS_DIR outputs [format "%s_quantus_%s.spef" $TOP $rc]]
        file delete -force $spef
        lappend quantus_spef $rc $spef
    }

    set quantus_t0 [clock seconds]
    restoreDesign $QUANTUS_CHECKPOINT $TOP

    # MAC DINH 1 TIEN TRINH.  Run 2026-10-09 23:33 (effortLevel high, 8 CPU):
    #     Creating 8 parallel subjobs for IQuantus extraction...
    #     num of slaves (8) totalRss(0.000000) ... totalCpuTime (0.000000)
    # lap lai 45 phut (23:37 -> 00:22), Innovus chi dung them 7 s CPU: 8 tien
    # trinh con khong he chay.  Chung duoc goi bang script '#!/bin/csh'
    # (.user1_launch_<pid>_<n>).  Genus va Conformal tren may nay cung treo o
    # che do nhieu tien trinh.  Thu lai: make all QUANTUS_CPUS=8.
    set quantus_cpus [quantus_env QUANTUS_CPUS 1]
    if {![string is integer -strict $quantus_cpus] || $quantus_cpus < 1} {
        error "QUANTUS_CPUS phai la so nguyen >= 1, dang la '$quantus_cpus'"
    }
    setMultiCpuUsage -acquireLicense $quantus_cpus -localCpu $quantus_cpus
    setDistributeHost -local

    # QRC tech file cua ASAP7 co LISD M1..M9, KHONG co Pad; LEF co M1..M9 + Pad.
    # Hinh duy nhat tren Pad la metal fill (KHOI 15).  Xoa no trong RAM de
    # Quantus khong gap lop khong co trong tech file - dung nhu mau Mul32.
    # Khong net tin hieu nao di tren M8/M9/Pad nen RC cua chung khong doi.
    if {[catch {deleteMetalFill -layer Pad} pad_err]} {
        puts "WARNING: deleteMetalFill -layer Pad: $pad_err"
    }

    setExtractRCMode -engine postRoute -effortLevel $QUANTUS_EFFORT -coupled true
    if {$QUANTUS_EFFORT eq "signoff"} {
        setExtractRCMode -qrcCmdType auto
        # Mau Mul32 (Asap7/Script/quantus/quantus.tcl, da chay duoc tren may
        # DDI221) chi ro file chay qrc cho Innovus.  Ban dau bo dong nay vi
        # tuong khong phai option hop le; run 2026-10-09 21:32 khong co no thi
        # qrc dung 2 tieng voi 5 s CPU.  Chua biet no co phai nguyen nhan
        # khong, nen option bi tu choi thi chi canh bao.
        set quantus_qrc_exe [lindex [auto_execok qrc] 0]
        if {[catch {setExtractRCMode -extract_rc_quantus_executable $quantus_qrc_exe} exe_err]} {
            lappend quantus_warn "setExtractRCMode -extract_rc_quantus_executable\
 $quantus_qrc_exe bi tu choi: $exe_err"
        }
    }
    setExtractRCMode -lefTechFileMap $QUANTUS_LAYER_MAP
    extractRC

    # CONG GHEP LOP - truoc rcOut, de ghep sai thi khong co SPEF nao duoc ghi.
    # File map chua tung chay tren tool; neu Innovus bo qua no hoac hieu sai
    # dinh dang thi bang 'db Layer ... -->' trong log van lech bac nhu cu.
    set layer_pairs [quantus_layer_pairs $QUANTUS_LOG]
    set layer_bad [quantus_layer_mismatches $layer_pairs]
    if {[llength $layer_bad] > 0} {
        error "Ghep lop LEF/QRC sai: $layer_bad
  File map $QUANTUS_LAYER_MAP khong duoc ap dung hoac sai dinh dang.
  Xem bang 'db Layer ... -->' trong $QUANTUS_LOG.  Khong ghi SPEF."
    }
    if {[dict size $layer_pairs] == 0} {
        set layer_note "KHONG KIEM DUOC - log khong co bang 'db Layer ... -->'"
        lappend quantus_warn "khong doc duoc bang ghep lop trong $QUANTUS_LOG -\
 tu kiem truoc khi dung SPEF"
    } else {
        set layer_note {}
        dict for {lef tech} $layer_pairs {
            lappend layer_note "$lef->$tech"
        }
        set layer_note [join $layer_note " "]
    }

    # Mot goc hong khong duoc lam mat SPEF cua hai goc con lai.
    set rc_failed {}
    foreach {rc spef} $quantus_spef {
        if {[catch {rcOut -spef $spef -rc_corner $rc} rc_err]} {
            puts "ERROR: rcOut $rc: $rc_err"
            lappend rc_failed $rc
        } elseif {![file isfile $spef] || [file size $spef] == 0} {
            puts "ERROR: rcOut $rc khong ghi ra $spef"
            lappend rc_failed $rc
        }
    }
    if {[llength $rc_failed] > 0} {
        error "rcOut hong o goc: $rc_failed"
    }

    # --------------------------------------------------------------------
    # Tom tat + doi chieu voi SPEF tQuantus cua KHOI 16 (cung netlist, nen so
    # net phai bang nhau; tong C lech bao nhieu la muc Innovus da toi uu tren
    # RC khac voi RC signoff).
    # --------------------------------------------------------------------
    set summary {}
    set corner_res {}
    foreach {rc spef} $quantus_spef {
        foreach {nets cap res} [quantus_spef_stats $spef] break
        if {$nets == 0} {
            error "$spef khong co dong *D_NET nao"
        }
        lappend corner_res [format "%.1f" $res]
        set line [format "%-7s %8d net  %14.1f fF  %12.1f kOhm" \
            $rc $nets $cap [expr {$res / 1000.0}]]
        set ref [format "./outputs/%s_pnr_%s.spef" $TOP $rc]
        if {[file isfile $ref]} {
            foreach {ref_nets ref_cap ref_res} [quantus_spef_stats $ref] break
            if {$ref_cap > 0 && $ref_res > 0} {
                append line [format "   tQuantus KHOI 16: %8d net  %14.1f fF  %12.1f kOhm   ti le C %.3f R %.3f" \
                    $ref_nets $ref_cap [expr {$ref_res / 1000.0}] \
                    [expr {$cap / $ref_cap}] [expr {$res / $ref_res}]]
            }
            if {$ref_nets != $nets} {
                lappend quantus_warn "$rc: $nets net, SPEF KHOI 16 co $ref_nets net -\
 checkpoint va outputs/ khong cung mot run?"
            }
        } else {
            append line "   (khong co $ref de doi chieu)"
        }
        append line "   [file tail $spef]"
        lappend summary $line
    }

    # Ba goc dung chung mot QRC tech file (chi khac nhiet do): C bang nhau la
    # dung, nhung R ma cung bang nhau thi ba goc thuc ra la mot.
    if {[llength [lsort -unique $corner_res]] < [llength $corner_res]} {
        lappend quantus_warn "tong R cua cac goc trung nhau ($corner_res ohm) -\
 nhiet do goc RC khong co tac dung?"
    }

    set quantus_engine [expr {$QUANTUS_EFFORT eq "signoff" ?
        "Quantus QRC (lenh qrc)" : "IQuantus tich hop trong Innovus - CHUA phai signoff"}]
    set fp [open $QUANTUS_SUMMARY w]
    puts $fp "DONE"
    puts $fp "Quantus $TOP: effortLevel $QUANTUS_EFFORT = $quantus_engine, coupled, checkpoint $QUANTUS_CHECKPOINT"
    puts $fp "  thoi gian [expr {[clock seconds] - $quantus_t0}] s, QRC tech [file tail $QRC_FILE]"
    puts $fp "  ghep lop: $layer_note"
    puts $fp "  (SPEF KHOI 16 de doi chieu duoc trich khi lop con ghep lech bac -\
 ti le gom ca khac engine lan khac lop)"
    foreach line $summary {
        puts $fp "  $line"
    }
    foreach msg $quantus_warn {
        puts $fp "  WARNING: $msg"
    }
    close $fp

    set fp [open $QUANTUS_SUMMARY r]
    puts "============================================================"
    puts -nonewline [read $fp]
    puts "============================================================"
    close $fp
} quantus_err]} {
    set quantus_trace $::errorInfo
    puts "ERROR: quantus.tcl: $quantus_err"
    puts $quantus_trace
    # 'puts' khong vao file log cua Innovus (run 16:43: cong ghep lop dung
    # flow nhung log khong co dong nao noi vi sao).  Ghi ly do ra file tom tat.
    if {[info exists QUANTUS_SUMMARY]} {
        catch {
            set fp [open $QUANTUS_SUMMARY w]
            puts $fp "FAIL"
            puts $fp "quantus.tcl: $quantus_err"
            close $fp
        }
    }
    exit 1
}
exit 0
