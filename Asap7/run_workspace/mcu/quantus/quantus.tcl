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

# Dem net va cong tong dien dung cua mot file SPEF.  Tra ve {so_net tong_fF}.
proc quantus_spef_stats {path} {
    set fp [open $path r]
    fconfigure $fp -translation binary -buffersize 1048576
    set nets 0
    set cap 0.0
    set to_ff 1.0
    while {[gets $fp line] >= 0} {
        if {[string index $line 0] ne "*"} {
            continue
        }
        if {[string range $line 0 6] eq "*D_NET "} {
            if {[regexp {^\*D_NET\s+\S+\s+(\S+)} $line -> net_cap] &&
                [string is double -strict $net_cap]} {
                incr nets
                set cap [expr {$cap + $net_cap}]
            }
        } elseif {[regexp {^\*C_UNIT\s+(\S+)\s+(\S+)} $line -> scale unit]} {
            switch -- [string toupper $unit] {
                PF      { set to_ff [expr {$scale * 1000.0}] }
                FF      { set to_ff [expr {$scale * 1.0}] }
                default { error "$path: *C_UNIT la '$unit' - chi biet PF va FF" }
            }
        }
    }
    close $fp
    return [list $nets [expr {$cap * $to_ff}]]
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
    }
    extractRC

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
    set quantus_warn {}
    foreach {rc spef} $quantus_spef {
        foreach {nets cap} [quantus_spef_stats $spef] break
        if {$nets == 0} {
            error "$spef khong co dong *D_NET nao"
        }
        set line [format "%-7s %8d net  %14.1f fF" $rc $nets $cap]
        set ref [format "./outputs/%s_pnr_%s.spef" $TOP $rc]
        if {[file isfile $ref]} {
            foreach {ref_nets ref_cap} [quantus_spef_stats $ref] break
            if {$ref_cap > 0} {
                append line [format "   tQuantus KHOI 16: %8d net  %14.1f fF   ti le %.3f" \
                    $ref_nets $ref_cap [expr {$cap / $ref_cap}]]
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

    set fp [open $QUANTUS_SUMMARY w]
    puts $fp "DONE"
    puts $fp "Quantus $TOP: effortLevel $QUANTUS_EFFORT, coupled, checkpoint $QUANTUS_CHECKPOINT"
    puts $fp "  thoi gian [expr {[clock seconds] - $quantus_t0}] s, QRC tech [file tail $QRC_FILE]"
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
    puts "ERROR: quantus.tcl: $quantus_err"
    puts $::errorInfo
    exit 1
}
exit 0
