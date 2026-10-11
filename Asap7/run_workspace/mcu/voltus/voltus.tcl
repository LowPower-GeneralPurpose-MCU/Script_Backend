############################################################
## Voltus: cong suat tinh + sut ap luoi nguon cho top_soc
##
## Chay tu thu muc mcu/voltus:   make all
##
##   vao : ../innovus/outputs/top_soc_pnr.{v,sdc,def}   KHOI 16 (DEF da co chan
##                                                      PG VDD/VSS tren ring M8)
##         ../quantus/outputs/top_soc_quantus_rc_typ.spef
##   ra  : reports/voltus_summary.rpt    dong dau DONE / FAIL
##         reports/power_static.rpt
##         outputs/power/, outputs/rail_VDD/, outputs/rail_VSS/
##
## Viet theo mau Asap7/Script/voltus/run_voltus.tcl (Mul32): read_lib -lef,
## read_lib, read_verilog, set_top_module, read_def, read_sdc, read_spef,
## report_power (static), set_rail_analysis_mode era_static, set_pg_nets,
## set_power_pads, analyze_rail -type net.  Mot goc TT 0.7 V / 25 C nhu
## reports/power_final.rpt cua Innovus (view_tt).  Chua co VCD: activity mac
## dinh cua tool, nen cong suat la CAN TREN.
##
## Khac mau:
##   - don vi 1ns / 1pf (xem buoc 1) - thieu thi tan so clock sai 1000 lan
##   - -enable_xp mac dinh TAT, 1 CPU: may nay treo o moi che do nhieu tien trinh
##   - diem cap nguon lay tu chan PG trong DEF, roi moi den cach cua mau
##   - thu truyen file ghep lop LEF/QRC (asap7_lefdef.layermap)
## CHUA chay tren tool: lenh nao Voltus khong nhan thi ly do nam trong
## reports/voltus_summary.rpt.
############################################################

proc voltus_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc voltus_env_flag {name default_value} {
    set value [voltus_env $name $default_value]
    if {$value ne "0" && $value ne "1"} {
        error "$name phai la 0 hoac 1, dang la '$value'"
    }
    return $value
}

set VOLTUS_WARNINGS {}
proc voltus_warn {msg} {
    lappend ::VOLTUS_WARNINGS $msg
    puts "WARNING: $msg"
}

# 'puts' khong vao file log cua tool (da gap o mcu/quantus), nen ket luan va
# ly do loi deu ghi ra file tom tat.
proc voltus_write_summary {path verdict lines} {
    set fp [open $path w]
    puts $fp $verdict
    foreach line $lines {
        puts $fp $line
    }
    foreach msg $::VOLTUS_WARNINGS {
        puts $fp "  WARNING: $msg"
    }
    close $fp
}

# Cac dong "Total ... Power:" cua mot file report_power, da cat khoang trang.
proc voltus_power_totals {rpt} {
    set out {}
    if {![file isfile $rpt]} {
        return $out
    }
    set fp [open $rpt r]
    while {[gets $fp line] >= 0} {
        if {[regexp {^Total (Internal |Switching |Leakage )?Power:\s+\S+} $line]} {
            lappend out [regsub -all {\s+} [string trim $line] " "]
        }
    }
    close $fp
    return $out
}

# Moi file (khong phai thu muc) duoi dir, sau toi da 'depth' cap.
proc voltus_files_under {dir depth} {
    set out {}
    foreach path [lsort [glob -nocomplain -directory $dir *]] {
        if {[file isdirectory $path]} {
            if {$depth > 0} {
                foreach sub [voltus_files_under $path [expr {$depth - 1}]] {
                    lappend out $sub
                }
            }
        } else {
            lappend out $path
        }
    }
    return $out
}

# Diem cap nguon.  defpin = chan PG VDD/VSS ma KHOI 16 dat tren ring M8
# (soc_add_pg_pins truoc defOut); auto = cach cua mau Mul32.
proc voltus_power_pads {how} {
    foreach net {VDD VSS} {
        if {$how eq "defpin"} {
            set_power_pads -net $net -format defpin
        } else {
            set_power_pads -net $net -auto_voltage_source_creation true
        }
    }
}

# Mot lan phan tich luoi nguon.  layer_map rong = khong truyen file ghep lop.
# analyze_rail co the in loi ma khong nem loi Tcl (extractRC cua Innovus da
# tung nhu vay), nen kiem ca viec thu muc ket qua co file hay khong.
proc voltus_rail {layer_map pads} {
    set mode_cmd [list set_rail_analysis_mode \
        -method era_static \
        -accuracy hd \
        -enable_xp [expr {$::VOLTUS_XP ? "true" : "false"}] \
        -em_temperature 110 \
        -extraction_tech_file $::QRC_FILE]
    if {$layer_map ne ""} {
        lappend mode_cmd -lef_layermap $layer_map
    }
    {*}$mode_cmd

    set_pg_nets -net VDD -voltage $::VOLTUS_VDD -threshold $::VOLTUS_VDD_MIN
    set_pg_nets -net VSS -voltage 0.0 -threshold $::VOLTUS_VSS_MAX
    voltus_power_pads $pads

    foreach net {VDD VSS} {
        set out [file join $::VOLTUS_DIR outputs "rail_$net"]
        file delete -force $out
        analyze_rail -type net -output $out $net
        if {[llength [voltus_files_under $out 4]] == 0} {
            error "analyze_rail $net khong ghi gi vao $out"
        }
    }
}

set VOLTUS_DIR [file normalize [pwd]]
set VOLTUS_SUMMARY [file join $VOLTUS_DIR reports voltus_summary.rpt]

# Voltus chay -nowin: loi Tcl giua chung se dung o dau nhac va treo make.
# Boc ca flow trong catch de luon thoat voi ket luan ro rang.
if {[catch {
    foreach dir {logs reports outputs} {
        file mkdir [file join $VOLTUS_DIR $dir]
    }
    # Ket luan cua lan chay truoc khong duoc song sot qua mot lan chay hong.
    file delete -force $VOLTUS_SUMMARY

    # --------------------------------------------------------------------
    # 0. CAU HINH - dung chung project_config.tcl voi Genus va Innovus
    # --------------------------------------------------------------------
    set FLOW_ROOT [file dirname $VOLTUS_DIR]
    set mcu_config [file join $FLOW_ROOT genus rtl flow project_config.tcl]
    if {![file isfile $mcu_config]} {
        error "Khong thay $mcu_config - phai chay tu thu muc mcu/voltus (make all)"
    }
    source $mcu_config

    set VOLTUS_NETLIST [file join $FLOW_ROOT innovus outputs "${TOP}_pnr.v"]
    set VOLTUS_SDC     [file join $FLOW_ROOT innovus outputs "${TOP}_pnr.sdc"]
    set VOLTUS_DEF     [file join $FLOW_ROOT innovus outputs "${TOP}_pnr.def"]

    set VOLTUS_SPEF_SRC [voltus_env VOLTUS_SPEF quantus]
    switch -- $VOLTUS_SPEF_SRC {
        quantus {
            set VOLTUS_SPEF_FILE [file join $FLOW_ROOT quantus outputs "${TOP}_quantus_rc_typ.spef"]
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
            set VOLTUS_SPEF_FILE [file join $FLOW_ROOT innovus outputs "${TOP}_pnr_rc_typ.spef"]
            voltus_warn "VOLTUS_SPEF=pnr: SPEF tQuantus cua KHOI 16 duoc trich khi lop\
 LEF/QRC con ghep lech bac"
        }
        default {
            error "VOLTUS_SPEF phai la quantus hoac pnr, dang la '$VOLTUS_SPEF_SRC'"
        }
    }

    # Cung bo LEF Innovus da doc (tech .fixed, RVT, LVT, hai SRAM .fixed).
    set VOLTUS_LEFS [concat [list $TECH_LEF] $CELL_LEFS [list $SRAM_LEF $SRAM_TAG_LEF]]
    foreach path [concat $VOLTUS_LEFS $ALL_TIMING_LIBS \
            [list $VOLTUS_NETLIST $VOLTUS_SDC $VOLTUS_DEF $VOLTUS_SPEF_FILE $QRC_FILE]] {
        if {![file isfile $path]} {
            error "Thieu file dau vao: $path"
        }
    }

    set VOLTUS_RAIL [voltus_env_flag VOLTUS_RAIL 1]
    # MAC DINH TAT -enable_xp va 1 CPU: XP chia viec cho nhieu tien trinh, ma
    # tren may nay Genus (super-thread), Conformal (thread) va IQuantus (8 tien
    # trinh) deu treo o che do do.  Mau Mul32 bat XP voi 2 CPU.
    set VOLTUS_XP [voltus_env_flag VOLTUS_XP 0]
    set voltus_cpus [voltus_env VOLTUS_CPUS 1]
    if {![string is integer -strict $voltus_cpus] || $voltus_cpus < 1} {
        error "VOLTUS_CPUS phai la so nguyen >= 1, dang la '$voltus_cpus'"
    }
    # Nguong cua mau Mul32: VDD duoc sut toi 0.65 V, VSS duoc nay toi 0.05 V.
    set VOLTUS_VDD     0.7
    set VOLTUS_VDD_MIN 0.65
    set VOLTUS_VSS_MAX 0.05

    # File ghep lop cho phan trich luoi nguon.  LEF co M1..M9 + Pad, QRC co
    # LISD M1..M9: khong co file nay thi Innovus/IQuantus ghep theo vi tri
    # (M8 -> m7, M9 -> m8), va luoi nguon nam chinh tren M8/M9.  Dinh dang
    # "metal <QRC> lefdef <LEF>" va ten option -lef_layermap CHUA duoc kiem tren
    # tool, nen hong thi voltus.tcl tu chay lai khong co no va ghi WARNING.
    set VOLTUS_LAYER_MAP ""
    if {[voltus_env_flag VOLTUS_LAYERMAP 1]} {
        set VOLTUS_LAYER_MAP [file join $VOLTUS_DIR asap7_lefdef.layermap]
        if {![file isfile $VOLTUS_LAYER_MAP]} {
            error "Khong co file ghep lop $VOLTUS_LAYER_MAP"
        }
    }

    set voltus_t0 [clock seconds]
    set_multi_cpu_usage -localCpu $voltus_cpus

    # --------------------------------------------------------------------
    # 1. DOC THIET KE
    # --------------------------------------------------------------------
    # DON VI: .lib ASAP7 la 1ps / 1fF con SDC cua writeTimingCon khong co
    # set_units va viet theo 1ns / 1pf (create_clock -period 4.000000) - do la
    # don vi Innovus dat bang 'setLibraryUnit -time 1ns -cap 1pf'.  Thieu dong
    # nay thi clock 250 MHz bi doc thanh 250 GHz va cong suat dong sai 1000 lan.
    if {[catch {set_library_unit -time 1ns -cap 1pf} unit_err1] &&
        [catch {setLibraryUnit -time 1ns -cap 1pf} unit_err2]} {
        error "Khong dat duoc don vi 1ns/1pf: set_library_unit: $unit_err1 ;\
 setLibraryUnit: $unit_err2"
    }
    read_lib -lef $VOLTUS_LEFS
    read_lib $ALL_TIMING_LIBS
    read_verilog $VOLTUS_NETLIST
    set_top_module $TOP
    read_def $VOLTUS_DEF
    read_sdc $VOLTUS_SDC
    read_spef $VOLTUS_SPEF_FILE

    # --------------------------------------------------------------------
    # 2. CONG SUAT TINH
    # --------------------------------------------------------------------
    set VOLTUS_POWER_RPT [file join $VOLTUS_DIR reports power_static.rpt]
    file delete -force $VOLTUS_POWER_RPT
    set_power_analysis_mode -method static -corner max -create_binary_db true
    set_power_output_dir [file join $VOLTUS_DIR outputs power]
    report_power -outfile $VOLTUS_POWER_RPT
    set power_totals [voltus_power_totals $VOLTUS_POWER_RPT]
    if {[llength $power_totals] == 0} {
        error "report_power khong ghi dong 'Total Power:' nao vao $VOLTUS_POWER_RPT"
    }

    # --------------------------------------------------------------------
    # 3. LUOI NGUON (early rail analysis, khong can thu vien PGV)
    # --------------------------------------------------------------------
    # Thu lan luot; lan dau chay het thi dung.  Moi lan hong de lai mot WARNING
    # noi ro hong vi dau.
    set rail_note "bo qua (VOLTUS_RAIL=0)"
    set rail_ok 1
    if {$VOLTUS_RAIL} {
        set attempts {}
        foreach map [lsort -unique -decreasing [list $VOLTUS_LAYER_MAP ""]] {
            foreach pads {defpin auto} {
                lappend attempts [list $map $pads]
            }
        }
        set rail_note ""
        foreach attempt $attempts {
            foreach {map pads} $attempt break
            set label "ghep lop [expr {$map eq "" ? "THEO VI TRI" : [file tail $map]}],\
 diem cap nguon $pads"
            if {[catch {voltus_rail $map $pads} rail_err]} {
                voltus_warn "analyze_rail ($label) hong: $rail_err"
                continue
            }
            set rail_note $label
            break
        }
        # Khong 'error' o day: cong suat da tinh xong van phai vao file tom tat.
        if {$rail_note eq ""} {
            set rail_ok 0
            set rail_note "HONG o ca [llength $attempts] cach thu - xem cac WARNING"
        }
    }

    # --------------------------------------------------------------------
    # 4. TOM TAT
    # --------------------------------------------------------------------
    set lines {}
    lappend lines "Voltus $TOP: goc TT 0.7 V / 25 C, static, activity mac dinh (chua co VCD = can tren),\
 SPEF $VOLTUS_SPEF_SRC ([file tail $VOLTUS_SPEF_FILE]), $voltus_cpus CPU"
    lappend lines "  thoi gian [expr {[clock seconds] - $voltus_t0}] s; don vi 1ns / 1pf"
    lappend lines "  cong suat (reports/power_static.rpt):"
    foreach line $power_totals {
        lappend lines "    $line"
    }
    set innovus_totals [voltus_power_totals [file join $FLOW_ROOT innovus reports power_final.rpt]]
    if {[llength $innovus_totals] > 0} {
        lappend lines "  doi chieu Innovus KHOI 15 (innovus/reports/power_final.rpt, RC tQuantus):"
        foreach line $innovus_totals {
            lappend lines "    $line"
        }
    }
    lappend lines "  luoi nguon: $rail_note"
    if {$VOLTUS_RAIL && $rail_ok} {
        lappend lines "    nguong: VDD >= $VOLTUS_VDD_MIN V (danh dinh $VOLTUS_VDD V), VSS <= $VOLTUS_VSS_MAX V;\
 -enable_xp [expr {$VOLTUS_XP ? "bat" : "tat"}]"
        foreach net {VDD VSS} {
            set out [file join $VOLTUS_DIR outputs "rail_$net"]
            set rpts {}
            foreach path [voltus_files_under $out 4] {
                if {[string match *.rpt $path]} {
                    lappend rpts $path
                }
            }
            lappend lines "    $net: outputs/rail_$net ([llength [voltus_files_under $out 4]] file,\
 [llength $rpts] file .rpt)"
            # Khong biet truoc dinh dang bao cao cua Voltus: chep nguyen van cac
            # dong co ve la con so sut ap, toi da 12 dong moi net.
            set shown 0
            foreach rpt $rpts {
                set fp [open $rpt r]
                while {$shown < 12 && [gets $fp line] >= 0} {
                    if {[regexp -nocase {(min|max|avg|average|worst).*(volt|drop)|(volt|drop).*(min|max|avg|average|worst)} $line]} {
                        lappend lines "      [file tail $rpt]: [string trim $line]"
                        incr shown
                    }
                }
                close $fp
            }
        }
    }
    voltus_write_summary $VOLTUS_SUMMARY [expr {$rail_ok ? "DONE" : "FAIL"}] $lines

    set fp [open $VOLTUS_SUMMARY r]
    puts "============================================================"
    puts -nonewline [read $fp]
    puts "============================================================"
    close $fp
} voltus_err]} {
    set voltus_trace $::errorInfo
    puts "ERROR: voltus.tcl: $voltus_err"
    puts $voltus_trace
    catch {
        file mkdir [file dirname $VOLTUS_SUMMARY]
        voltus_write_summary $VOLTUS_SUMMARY FAIL [list "voltus.tcl: $voltus_err"]
    }
    exit 1
}
exit 0
