############################################################
## Tempus: STA signoff cho top_soc - buoc tiep theo sau mcu/quantus
##
## Chay tu thu muc mcu/tempus:   make all
##
##   vao : ../innovus/outputs/top_soc_pnr.v      saveNetlist o KHOI 16
##         ../innovus/outputs/top_soc_pnr.sdc    writeTimingCon o KHOI 16
##         ../quantus/outputs/top_soc_quantus_{rc_ss,rc_typ,rc_ff}.spef
##   ra  : reports/tempus_summary.rpt   dong dau PASS / FAIL
##         reports/setup_view_*.rpt, hold_view_*.rpt, all_violators.rpt, ...
##
## Vi sao can buoc nay: moi con so timing cua Innovus (KHOI 13-16) tinh tren RC
## tQuantus trich khi lop LEF/QRC con ghep lech mot bac.  SPEF cua mcu/quantus
## (run 2026-10-11 12:03, lop ghep dung ten) co C x1.084 va R x0.957 so voi RC
## do, trong khi hold cuoi cua Innovus chi du +16 ps.
##
## Viet theo mau Asap7/Script/tempus/run_tempus.tcl (Mul32): read_lib,
## read_verilog, set_top_module, read_sdc, read_spef, update_timing,
## report_timing.  Phan them cho MCU - deu la guong cua flow Innovus:
##   - 3 view nhu innovus/tcl/viewDefinition.tcl: setup = view_ss + view_tt,
##     hold = view_ff + view_tt, moi goc RC mot SPEF rieng
##   - don vi 1ns / 1pf (xem tempus_views.tcl ben duoi)
##   - OCV + CPPR, SI, derate SRAM 1.30 / 0.75 nhu innovus/tcl/init_common.tcl
## CHUA chay tren tool: lenh nao Tempus khong nhan thi ly do nam trong
## reports/tempus_summary.rpt.
############################################################

proc tempus_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set TEMPUS_WARNINGS {}
proc tempus_warn {msg} {
    lappend ::TEMPUS_WARNINGS $msg
    puts "WARNING: $msg"
}

# 'puts' khong vao file log cua tool (da gap o mcu/quantus), nen ket luan va
# ly do loi deu ghi ra file tom tat.
proc tempus_write_summary {path verdict lines} {
    set fp [open $path w]
    puts $fp $verdict
    foreach line $lines {
        puts $fp $line
    }
    foreach msg $::TEMPUS_WARNINGS {
        puts $fp "  WARNING: $msg"
    }
    close $fp
}

# 84 macro SRAM.  Innovus loc bang ref_name (init_common.tcl); ref_lib_cell_name
# la ten thuoc tinh trong tai lieu Tempus - thu ca hai.
proc tempus_sram_cells {} {
    foreach prop {ref_name ref_lib_cell_name} {
        set filter "$prop =~ ${::SRAM_MASTER}* || $prop =~ ${::SRAM_TAG_MASTER}*"
        if {![catch {get_cells -hierarchical -filter $filter} cells] &&
            [sizeof_collection $cells] > 0} {
            return $cells
        }
    }
    error "Khong loc duoc macro SRAM bang ref_name / ref_lib_cell_name"
}

# {wns tns so_endpoint_vi_pham} cua mot view.  kind = late (setup) | early (hold).
proc tempus_slack_stats {kind view} {
    set worst [report_timing -$kind -view $view -max_paths 1 -collection]
    set wns ""
    foreach_in_collection path $worst {
        set wns [get_property $path slack]
    }
    if {![string is double -strict $wns]} {
        error "view $view ($kind): khong lay duoc slack (duoc '$wns')"
    }
    set tns 0.0
    set nvp 0
    if {$wns < 0} {
        # -nworst 1: moi endpoint mot duong, nen so duong = so endpoint vi pham.
        set viol [report_timing -$kind -view $view -max_slack 0 -nworst 1 \
            -max_paths $::TEMPUS_MAX_VIOL -collection]
        foreach_in_collection path $viol {
            set slack [get_property $path slack]
            if {[string is double -strict $slack] && $slack < 0} {
                set tns [expr {$tns + $slack}]
                incr nvp
            }
        }
    }
    return [list $wns $tns $nvp]
}

# Du phong khi 'report_timing -collection' khong dung duoc: doc chinh file
# report_timing da ghi.  Tra ve {wns so_duong_VIOLATED so_duong}; rong neu
# file khong co dong '= Slack Time'.
proc tempus_slack_from_report {rpt} {
    if {![file isfile $rpt]} {
        return {}
    }
    set wns ""
    set violated 0
    set paths 0
    set fp [open $rpt r]
    while {[gets $fp line] >= 0} {
        if {[regexp {^Path \d+: (\S+)} $line -> status]} {
            incr paths
            if {$status eq "VIOLATED"} {
                incr violated
            }
        } elseif {[regexp {^=\s*Slack Time\s+(-?[0-9.]+)} $line -> slack]} {
            if {$wns eq "" || $slack < $wns} {
                set wns $slack
            }
        }
    }
    close $fp
    if {$wns eq ""} {
        return {}
    }
    return [list $wns $violated $paths]
}

set TEMPUS_DIR [file normalize [pwd]]
set TEMPUS_SUMMARY [file join $TEMPUS_DIR reports tempus_summary.rpt]

# Tempus chay -nowin: loi Tcl giua chung se dung o dau nhac va treo make.
# Boc ca flow trong catch de luon thoat voi ket luan ro rang.
if {[catch {
    foreach dir {logs reports} {
        file mkdir [file join $TEMPUS_DIR $dir]
    }
    # Ket luan cua lan chay truoc khong duoc song sot qua mot lan chay hong.
    file delete -force $TEMPUS_SUMMARY

    # --------------------------------------------------------------------
    # 0. CAU HINH - dung chung project_config.tcl voi Genus va Innovus
    # --------------------------------------------------------------------
    set FLOW_ROOT [file dirname $TEMPUS_DIR]
    set mcu_config [file join $FLOW_ROOT genus rtl flow project_config.tcl]
    if {![file isfile $mcu_config]} {
        error "Khong thay $mcu_config - phai chay tu thu muc mcu/tempus (make all)"
    }
    source $mcu_config

    set TEMPUS_NETLIST [file join $FLOW_ROOT innovus outputs "${TOP}_pnr.v"]
    set TEMPUS_SDC     [file join $FLOW_ROOT innovus outputs "${TOP}_pnr.sdc"]

    # quantus = SPEF cua mcu/quantus (mac dinh).  pnr = SPEF tQuantus cua KHOI
    # 16, chi de doi chieu: no duoc trich khi lop con ghep lech bac.
    set TEMPUS_SPEF [tempus_env TEMPUS_SPEF quantus]
    switch -- $TEMPUS_SPEF {
        quantus {
            set spef_fmt [file join $FLOW_ROOT quantus outputs "${TOP}_quantus_%s.spef"]
            # SPEF cu cua mot lan Quantus FAIL van nam do neu ai do xoa tay
            # file tom tat; chi tin SPEF khi lan chay Quantus gan nhat DONE.
            set quantus_rpt [file join $FLOW_ROOT quantus reports quantus_summary.rpt]
            if {![file isfile $quantus_rpt]} {
                error "Khong co $quantus_rpt - chay mcu/quantus truoc (make all)"
            }
            set fp [open $quantus_rpt r]
            gets $fp quantus_verdict
            close $fp
            if {[string trim $quantus_verdict] ne "DONE"} {
                error "$quantus_rpt bao '$quantus_verdict' - SPEF Quantus khong dung duoc"
            }
        }
        pnr {
            set spef_fmt [file join $FLOW_ROOT innovus outputs "${TOP}_pnr_%s.spef"]
            tempus_warn "TEMPUS_SPEF=pnr: SPEF tQuantus cua KHOI 16 duoc trich khi lop\
 LEF/QRC con ghep lech bac - chi de doi chieu, khong phai signoff"
        }
        default {
            error "TEMPUS_SPEF phai la quantus hoac pnr, dang la '$TEMPUS_SPEF'"
        }
    }

    # Ten goc / view GIONG HET innovus/tcl/viewDefinition.tcl.
    #         duoi  goc RC  nhiet do  thu vien
    set corners [list \
        [list ss rc_ss  100 $ALL_TIMING_LIBS_SS] \
        [list tt rc_typ 25  $ALL_TIMING_LIBS] \
        [list ff rc_ff  0   $ALL_TIMING_LIBS_FF]]
    set TEMPUS_SETUP_VIEWS {view_ss view_tt}
    set TEMPUS_HOLD_VIEWS  {view_ff view_tt}

    set required [list $TEMPUS_NETLIST $TEMPUS_SDC]
    foreach corner $corners {
        foreach {tag rc temp libs} $corner break
        lappend required [format $spef_fmt $rc]
        foreach lib $libs {
            lappend required $lib
        }
    }
    foreach path $required {
        if {![file isfile $path]} {
            error "Thieu file dau vao: $path"
        }
    }

    # MAC DINH 1 CPU.  Tren may nay Genus (super-thread), Conformal (thread) va
    # IQuantus (8 tien trinh) deu treo khi chay song song; Tempus chua thu.
    set tempus_cpus [tempus_env TEMPUS_CPUS 1]
    if {![string is integer -strict $tempus_cpus] || $tempus_cpus < 1} {
        error "TEMPUS_CPUS phai la so nguyen >= 1, dang la '$tempus_cpus'"
    }
    set_multi_cpu_usage -localCpu $tempus_cpus

    # --------------------------------------------------------------------
    # 1. MMMC - ghi ra file roi read_view_definition, de con mo ra doc duoc
    # --------------------------------------------------------------------
    # DON VI: .lib ASAP7 la 1ps / 1fF con SDC cua writeTimingCon khong co
    # set_units va viet theo 1ns / 1pf (create_clock -period 4.000000) - do la
    # don vi Innovus dat bang 'setLibraryUnit -time 1ns -cap 1pf' trong
    # viewDefinition.tcl.  Thieu dong nay thi chu ky 4 ns bi doc thanh 4 ps.
    set TEMPUS_VIEW_FILE [file join $TEMPUS_DIR logs tempus_views.tcl]
    set fp [open $TEMPUS_VIEW_FILE w]
    puts $fp "# Sinh boi tempus.tcl - khong sua tay."
    puts $fp "if {\[catch {set_library_unit -time 1ns -cap 1pf}\]} {"
    puts $fp "    setLibraryUnit -time 1ns -cap 1pf"
    puts $fp "}"
    puts $fp "create_constraint_mode -name mode_func -sdc_files [list [list $TEMPUS_SDC]]"
    foreach corner $corners {
        foreach {tag rc temp libs} $corner break
        puts $fp "create_library_set -name libset_$tag -timing [list $libs]"
        puts $fp "create_rc_corner -name $rc -T $temp"
        puts $fp "create_delay_corner -name dc_$tag -library_set libset_$tag -rc_corner $rc"
        puts $fp "create_analysis_view -name view_$tag -constraint_mode mode_func -delay_corner dc_$tag"
    }
    puts $fp "set_analysis_view -setup [list $TEMPUS_SETUP_VIEWS] -hold [list $TEMPUS_HOLD_VIEWS]"
    close $fp

    # --------------------------------------------------------------------
    # 2. DOC THIET KE + KY SINH
    # --------------------------------------------------------------------
    read_view_definition $TEMPUS_VIEW_FILE
    read_verilog $TEMPUS_NETLIST
    # KHONG dung -ignore_undefined_cell cua mau Mul32: netlist _pnr.v khong co
    # cell vat ly, cell nao thieu .lib la loi that.
    set_top_module $TOP
    foreach corner $corners {
        foreach {tag rc temp libs} $corner break
        read_spef -rc_corner $rc [format $spef_fmt $rc]
    }

    # --------------------------------------------------------------------
    # 3. CHE DO PHAN TICH - guong cua innovus/tcl/init_common.tcl
    # --------------------------------------------------------------------
    set_analysis_mode -analysisType onChipVariation -cppr both

    set TEMPUS_SI [tempus_env TEMPUS_SI 1]
    if {$TEMPUS_SI ne "0" && $TEMPUS_SI ne "1"} {
        error "TEMPUS_SI phai la 0 hoac 1, dang la '$TEMPUS_SI'"
    }
    if {$TEMPUS_SI} {
        # Innovus postRoute: setDelayCalMode -SIAware true + glitch report.
        set_delay_cal_mode -siAware true
        if {[catch {set_si_mode -enable_glitch_report true} si_err]} {
            tempus_warn "set_si_mode -enable_glitch_report: $si_err"
        }
    } else {
        set_delay_cal_mode -siAware false
        tempus_warn "TEMPUS_SI=0: khong tinh delta delay / glitch do tu ghep"
    }

    # Derate cho 84 macro SRAM (mot .lib cho ca 3 goc) - cung hai con so voi
    # Genus va Innovus, lay tu project_config.tcl.
    set sram_cells [tempus_sram_cells]
    set sram_count [sizeof_collection $sram_cells]
    set sram_expected [expr {$SRAM_EXPECTED_COUNT + $SRAM_TAG_EXPECTED_COUNT}]
    if {$sram_count != $sram_expected} {
        error "Derate SRAM: tim thay $sram_count macro, doi $sram_expected"
    }
    set_timing_derate -delay_corner dc_ss -late  -cell_delay -cell_check \
        $SRAM_DERATE_SS $sram_cells
    set_timing_derate -delay_corner dc_ff -early -cell_delay -cell_check \
        $SRAM_DERATE_FF $sram_cells

    # Derate OCV chung cho std cell: cung ten bien va mac dinh (tat) voi
    # Innovus, de hai ben khong troi ra khac nhau.
    set ocv_late  [tempus_env MCU_OCV_DERATE_LATE  1.0]
    set ocv_early [tempus_env MCU_OCV_DERATE_EARLY 1.0]
    foreach {ocv_name ocv_value} [list MCU_OCV_DERATE_LATE $ocv_late MCU_OCV_DERATE_EARLY $ocv_early] {
        if {![string is double -strict $ocv_value] || $ocv_value <= 0} {
            error "$ocv_name phai la so duong, dang la '$ocv_value'"
        }
    }
    if {$ocv_late != 1.0 || $ocv_early != 1.0} {
        set_timing_derate -late  -cell_delay -net_delay -cell_check $ocv_late
        set_timing_derate -early -cell_delay -net_delay -cell_check $ocv_early
    } else {
        tempus_warn "khong co derate OCV chung cho std cell (1.0) trong khi CPPR van\
 duoc tru - giong Innovus; bat: MCU_OCV_DERATE_LATE=1.05 MCU_OCV_DERATE_EARLY=0.95"
    }
    tempus_warn "ba goc RC dung chung mot qrcTechFile typical (chi khac nhiet do) va\
 .lib SRAM chi co goc TT (bu bang derate x$SRAM_DERATE_SS / x$SRAM_DERATE_FF)"

    # --------------------------------------------------------------------
    # 4. TINH TIMING + BAO CAO
    # --------------------------------------------------------------------
    set tempus_t0 [clock seconds]
    update_timing -full

    # Bao cao phu: hong mot cai khong duoc lam mat ket luan.
    foreach {rpt_name rpt_cmd} {
        check_timing.rpt          {check_timing -verbose}
        annotated_parasitics.rpt  {report_annotated_parasitics}
        analysis_coverage.rpt     {report_analysis_coverage}
        all_violators.rpt         {report_constraint -all_violators}
        timing_derate.rpt         {report_timing_derate}
    } {
        set rpt [file join $TEMPUS_DIR reports $rpt_name]
        if {[catch {eval $rpt_cmd > $rpt} rpt_err]} {
            tempus_warn "$rpt_cmd hong: $rpt_err"
        }
    }
    if {$TEMPUS_SI} {
        set rpt [file join $TEMPUS_DIR reports glitch.rpt]
        if {[catch {report_noise -txtfile $rpt} rpt_err]} {
            tempus_warn "report_noise hong: $rpt_err"
        }
    }

    # Con so ket luan: WNS / TNS / so endpoint vi pham cua tung view.
    set TEMPUS_MAX_VIOL 100000
    set summary {}
    set failed {}
    foreach {kind label views} [list \
            late  setup $TEMPUS_SETUP_VIEWS \
            early hold  $TEMPUS_HOLD_VIEWS] {
        foreach view $views {
            set rpt [file join $TEMPUS_DIR reports "${label}_${view}.rpt"]
            report_timing -$kind -view $view -max_paths 100 -nworst 1 \
                -path_type full_clock > $rpt
            if {![catch {tempus_slack_stats $kind $view} stats]} {
                foreach {wns tns nvp} $stats break
                lappend summary [format "%-5s %-8s WNS %9.4f ns   TNS %12.4f ns   %6d endpoint vi pham   %s" \
                    $label $view $wns $tns $nvp [file tail $rpt]]
            } else {
                tempus_warn "$label $view: $stats - doc so tu [file tail $rpt]"
                set parsed [tempus_slack_from_report $rpt]
                if {[llength $parsed] == 0} {
                    lappend summary [format "%-5s %-8s KHONG DOC DUOC slack   %s" \
                        $label $view [file tail $rpt]]
                    lappend failed "$label/$view: khong doc duoc slack"
                    continue
                }
                foreach {wns nvp paths} $parsed break
                lappend summary [format "%-5s %-8s WNS %9.4f ns   %d/%d duong da in VIOLATED (khong co TNS)   %s" \
                    $label $view $wns $nvp $paths [file tail $rpt]]
            }
            if {$wns < 0} {
                lappend failed [format "%s/%s WNS %.4f ns" $label $view $wns]
            }
        }
    }

    set lines {}
    lappend lines "Tempus $TOP: SPEF $TEMPUS_SPEF ([file tail [format $spef_fmt rc_*]]), OCV + CPPR,\
 SI [expr {$TEMPUS_SI ? "bat" : "tat"}], $tempus_cpus CPU"
    lappend lines "  update_timing + bao cao [expr {[clock seconds] - $tempus_t0}] s; don vi 1ns / 1pf"
    lappend lines "  derate SRAM: $sram_count macro, dc_ss late x$SRAM_DERATE_SS, dc_ff early x$SRAM_DERATE_FF;\
 OCV chung late x$ocv_late / early x$ocv_early"
    foreach line $summary {
        lappend lines "  $line"
    }
    lappend lines "  max_transition / max_capacitance : reports/all_violators.rpt"
    lappend lines "  net chua gan ky sinh             : reports/annotated_parasitics.rpt"
    lappend lines "  duong khong rang buoc            : reports/check_timing.rpt, analysis_coverage.rpt"
    if {$TEMPUS_SI} {
        lappend lines "  glitch                           : reports/glitch.rpt"
    }
    if {[llength $failed] > 0} {
        lappend lines "  VI PHAM: [join $failed {; }]"
        tempus_write_summary $TEMPUS_SUMMARY FAIL $lines
    } else {
        tempus_write_summary $TEMPUS_SUMMARY PASS $lines
    }

    set fp [open $TEMPUS_SUMMARY r]
    puts "============================================================"
    puts -nonewline [read $fp]
    puts "============================================================"
    close $fp
} tempus_err]} {
    set tempus_trace $::errorInfo
    puts "ERROR: tempus.tcl: $tempus_err"
    puts $tempus_trace
    catch {
        file mkdir [file dirname $TEMPUS_SUMMARY]
        tempus_write_summary $TEMPUS_SUMMARY FAIL [list "tempus.tcl: $tempus_err"]
    }
    exit 1
}
exit 0
