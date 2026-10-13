############################################################
## Voltus: cong suat tinh + sut ap luoi nguon cho top_soc
##
## Chay tu thu muc mcu/voltus:   make all
##
##   vao : ../innovus/outputs/top_soc_pnr.{v,sdc,def}   KHOI 16 (DEF da co chan
##                                                      PG VDD/VSS tren ring
##                                                      M8/M9, 4 canh)
##         ../innovus/outputs/top_soc.lef               hinh chan PG -> vi tri
##                                                      nguon ap (VOLTUS_PADS=pin)
##         ../quantus/outputs/top_soc_quantus_rc_typ.spef
##   ra  : reports/voltus_summary.rpt    dong dau DONE / FAIL
##         reports/power_static.rpt
##         reports/rail_VDD/, rail_VSS/  400 dong dau moi bao cao + anh sut ap
##         outputs/power/, outputs/rail_VDD/, outputs/rail_VSS/
##         work/                         luoi dien tro da trich; XOA dau moi lan
##                                       chay (xem voltus_rail)
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
##   - them set_power_data (file dong .ptiavg cua report_power): mau khong co
##   - set_design_mode -process 7 nhu Innovus va Tempus (them 2026-10-13, CHUA
##     chay tren Voltus: dong 'process:' cua file tom tat doc lai tool log)
## Run dau 2026-10-11: cong suat chay, luoi nguon hong (thieu set_power_data,
## sai ten option ghep lop).  Ban nay CHUA chay lai tren tool: lenh nao Voltus
## khong nhan thi ly do nam trong reports/voltus_summary.rpt.
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

# Diem cap nguon.
#   pin    = nhieu nguon ap rai doc theo cac hinh chan PG VDD/VSS trong LEF cua
#            top.  Tu 2026-10-13 soc_add_pg_pins lay MOI doan ring loi lam hinh
#            chan (M8 tren + duoi, M9 trai + phai) -> nguon cap tu 4 canh.
#            Run 2026-10-13 14:26 dung defpin: Voltus chi dat MOT nguon ap cho
#            ca chan, rieng lop M8 da sut 3.9 V.
#   ring   = nhu pin nhung hinh lay tu innovus/outputs/<top>_pg_ring.txt (cac
#            doan ring ma soc_add_pg_pins ghi ra).  Dung khi createPGPin khong
#            nhan du 4 hinh: ring van co that trong DEF, chi thieu khai bao chan.
#   defpin = mot nguon ap moi chan DEF;  auto = cach cua mau Mul32.
proc voltus_power_pads {how} {
    foreach net {VDD VSS} {
        switch -- $how {
            pin - ring { set_power_pads -net $net -format xy -file $::VOLTUS_PAD_FILE($net) }
            defpin     { set_power_pads -net $net -format defpin }
            default    { set_power_pads -net $net -auto_voltage_source_creation true }
        }
    }
}

# Cac doan ring cua <net> trong file soc_add_pg_pins ghi ("net layer x0 y0 x1
# y1" moi dong, '#' la ghi chu): danh sach {layer x0 y0 x1 y1}.
proc voltus_ring_rects {path net} {
    set fp [open $path r]
    set rects {}
    while {[gets $fp line] >= 0} {
        set words [regexp -all -inline {\S+} $line]
        if {[llength $words] == 6 && [lindex $words 0] eq $net} {
            lappend rects [lrange $words 1 end]
        }
    }
    close $fp
    return $rects
}

# Cac hinh chu nhat cua chan <net> trong LEF top: danh sach {layer x0 y0 x1 y1}.
proc voltus_lef_pin_rects {lef net} {
    set fp [open $lef r]
    set rects {}
    set in_pin 0
    set layer ""
    while {[gets $fp line] >= 0} {
        set words [regexp -all -inline {\S+} $line]
        set key [lindex $words 0]
        if {!$in_pin} {
            if {$key eq "PIN" && [lindex $words 1] eq $net} {
                set in_pin 1
            }
            continue
        }
        if {$key eq "END" && [lindex $words 1] eq $net} {
            break
        }
        if {$key eq "LAYER"} {
            set layer [lindex $words 1]
        }
        if {$key eq "RECT"} {
            # "RECT MASK n x0 y0 x1 y1 ;" - bon so cuoi la toa do.
            set nums {}
            foreach word [lrange $words 1 end] {
                if {[string is double -strict $word]} {
                    lappend nums $word
                }
            }
            if {[llength $nums] >= 4} {
                lappend rects [list $layer {*}[lrange $nums end-3 end]]
            }
        }
    }
    close $fp
    return $rects
}

# Rai nguon ap doc theo truc dai cua tung hinh {layer x0 y0 x1 y1}, cach nhau
# khoang <pitch> um.  Moi phan tu: {ten x y layer}.
proc voltus_rect_sources {rects net pitch} {
    set sources {}
    foreach rect $rects {
        lassign $rect layer x0 y0 x1 y1
        set horizontal [expr {($x1 - $x0) >= ($y1 - $y0)}]
        set length [expr {$horizontal ? $x1 - $x0 : $y1 - $y0}]
        set count [expr {max(1, int(floor($length / $pitch)))}]
        set step [expr {$length / double($count)}]
        for {set i 0} {$i < $count} {incr i} {
            set along [expr {($i + 0.5) * $step}]
            if {$horizontal} {
                set x [expr {$x0 + $along}]
                set y [expr {($y0 + $y1) / 2.0}]
            } else {
                set x [expr {($x0 + $x1) / 2.0}]
                set y [expr {$y0 + $along}]
            }
            lappend sources [list "${net}_[llength $sources]" [format %.4f $x] [format %.4f $y] $layer]
        }
    }
    return $sources
}

proc voltus_write_pad_file {path sources} {
    set fp [open $path w]
    puts $fp "*vsrc_name x y layer_name"
    foreach source $sources {
        puts $fp [join $source " "]
    }
    close $fp
}

# "-7.808V" / "1.271nV" / "0.700V," -> so thuc (V); khong doc duoc thi tra "".
proc voltus_value {token} {
    if {![regexp {^(-?[0-9.]+(?:[eE][-+]?[0-9]+)?)([fpnum]?)[VA],?$} $token -> num prefix]} {
        return ""
    }
    return [expr {$num * [dict get {{} 1.0 f 1e-15 p 1e-12 n 1e-9 u 1e-6 m 1e-3} $prefix]}]
}

# Dong "Minimum, Average, Maximum IR drop: a b c" cua <net>.main.rpt -> {a b c}
# theo V; dong khac tra {}.  Voi VDD ba so la DIEN AP NUT (lon nhat = danh
# dinh), voi VSS la do nay so voi 0 V.
proc voltus_ir_values {line} {
    if {![regexp -nocase {Minimum, Average, Maximum IR drop:\s*(\S+)\s+(\S+)\s+(\S+)} $line -> a b c]} {
        return {}
    }
    set values {}
    foreach token [list $a $b $c] {
        set value [voltus_value $token]
        if {$value eq ""} {
            return {}
        }
        lappend values $value
    }
    return $values
}

# analyze_rail KHONG nem loi Tcl khi hong va van de lai era_work/ (thu vien PGV)
# trong thu muc ket qua: run 2026-10-11 dung o VOLTUS_RAIL-1152 ma tom tat van
# ghi DONE.  Run 2026-10-11 13:18 lai DONE gia lan nua: analyze_rail hong o buoc
# ghep luoi (VOLTUS_RAIL_SMG-0048) nhung khong co voltus_rail.log o thu muc chay
# va thu muc ket qua van co 60 file.  Nen kiem ba noi:
#   - tool log (logs/voltus.log*): VOLTUS-1055 / "Rail Analysis is unsuccessful"
#     xuat hien THEM sau lenh analyze_rail (voltus_rail_failures_logged);
#   - moi file *.log trong thu muc ket qua va voltus_rail.log o thu muc chay;
#   - thu muc ket qua khong co gi ngoai era_work/.
# Log cua lan hong duoc chep vao logs/ de con doc duoc sau khi commit (outputs/
# bi .gitignore chan).
# Run 2026-10-13 13:43 (VOLTUS_XP=1) DONE gia lan thu ba: voltus_xp.flower chet
# ngay ("No 'xp_launcher.py' in manifest"), analyze_rail tra ve sau 1 giay,
# khong co VOLTUS-1055, khong co file *.log nao, thu muc ket qua van co 16 file.
# Khong thay loi KHONG phai la bang chung da chay: can them dau hieu duong -
# "Finished Rail Analysis" moi trong tool log hoac file .rpt trong ket qua.
proc voltus_tool_log_text {} {
    set newest ""
    set newest_time -1
    foreach path [glob -nocomplain -directory [file join $::VOLTUS_DIR logs] voltus.log*] {
        if {[regexp {voltus\.log\d*$} $path] && [file mtime $path] > $newest_time} {
            set newest $path
            set newest_time [file mtime $path]
        }
    }
    if {$newest eq ""} {
        return ""
    }
    set fp [open $newest r]
    set text [read $fp]
    close $fp
    return $text
}

proc voltus_tool_log_count {pattern} {
    return [regexp -all $pattern [voltus_tool_log_text]]
}

# Khoi bao cao cua <net> trong tool log (tu dong "Net <net>:" CUOI CUNG toi
# "Finished Rail Analysis"): Voltus bo bao nhieu nguon dong / nut / doan day vi
# coi la KHONG NOI, va sut ap lon nhat tung lop.  Tra dict rong khi khong thay
# khoi do.  Cac so nay chi co trong tool log va outputs/ (khong vao git).
# Run 2026-10-13 22:00: VDD 15543, VSS 26192 nguon dong bi bo ma file tom tat
# khong noi gi, va 0.102 V cua VSS nam dung tren phan luoi bi bo do (lop M1-M4;
# M5-M9 chi 5-15 mV) - xem voltus_rail ve nguyen nhan.
proc voltus_rail_integrity {net} {
    set text [voltus_tool_log_text]
    set start [string last "\nNet $net:" $text]
    if {$start < 0} {
        return {}
    }
    set block [string range $text $start end]
    set stop [string first "Finished Rail Analysis" $block]
    if {$stop >= 0} {
        set block [string range $block 0 $stop]
    }
    # Dong 'Note: N current sources' dung ngay sau bang "Circuit profile"; chua
    # thay bang do = log chua ghi toi (khong duoc coi la 0 nguon dong bi bo).
    if {[string first "Circuit total" $block] < 0} {
        return {}
    }
    set out [dict create sources 0 nodes 0 segments ? weak ? layers {}]
    foreach {key pattern} {
        sources  {Note: (\d+) current sources are disconnected}
        nodes    {Note : (\d+) disconnected nodes are excluded}
        segments {# Disconnected Wire Segments: (\d+)}
        weak     {# Weakly Connected Metal Segments: (\d+)}
    } {
        if {[regexp $pattern $block -> count]} {
            dict set out $key $count
        }
    }
    # "      M9: 0.0051397 [0 - 0.0051397]" ngay duoi "Layer with maximum IR Drop".
    set at [string first "Layer with maximum IR Drop" $block]
    if {$at >= 0} {
        set layers {}
        foreach line [lrange [split [string range $block $at end] "\n"] 1 end] {
            if {![regexp {^\s+(\S+): ([0-9.eE+-]+) \[} $line -> layer drop]} {
                break
            }
            lappend layers [format "%s %.1f" $layer [expr {$drop * 1000.0}]]
        }
        dict set out layers $layers
    }
    return $out
}

# outputs/ khong vao git, nen sau khi commit khong con biet DIEM XAU NHAT NAM O
# DAU (run 2026-10-13 22:00: chi con dong "0.102V" trong file tom tat).  Chep
# 400 dong dau cua moi bao cao .rpt va hai anh ban do sut ap sang
# reports/rail_<net>/.  Tra ve so file da chep.
proc voltus_keep_reports {net out} {
    set dest [file join $::VOLTUS_DIR reports "rail_$net"]
    file delete -force $dest
    file mkdir $dest
    set kept 0
    foreach path [voltus_files_under $out 5] {
        set name [file tail $path]
        if {[string match *.rpt $name]} {
            set in [open $path r]
            set fp [open [file join $dest $name] w]
            set count 0
            while {$count < 400 && [gets $in line] >= 0} {
                puts $fp $line
                incr count
            }
            close $in
            close $fp
            incr kept
        } elseif {$name in {ir_limit.gif ir_linear.gif} && [file size $path] < 5000000} {
            file copy -force $path [file join $dest $name]
            incr kept
        }
    }
    return $kept
}

proc voltus_rail_failures_logged {} {
    return [voltus_tool_log_count {VOLTUS-1055|Rail Analysis is unsuccessful|\[voltus_xp\.flower\] ERROR}]
}

proc voltus_rail_finished_logged {} {
    return [voltus_tool_log_count {Finished Rail Analysis}]
}

proc voltus_rail_check {net out failures_before finished_before} {
    set why {}
    if {[voltus_rail_failures_logged] > $failures_before} {
        lappend why "tool log ghi VOLTUS-1055 / Rail Analysis is unsuccessful / \[voltus_xp.flower\] ERROR"
    }
    set logs {}
    set cwd_log [file join $::VOLTUS_DIR voltus_rail.log]
    if {[file isfile $cwd_log]} {
        lappend logs $cwd_log
    }
    foreach path [voltus_files_under $out 4] {
        if {[string match *.log $path]} {
            lappend logs $path
        }
    }
    foreach log $logs {
        if {[file size $log] > 5000000} {
            continue
        }
        set fp [open $log r]
        set text [read $fp]
        close $fp
        if {[regexp {Rail Analysis is unsuccessful|exited unsuccessfully|\mERROR\M} $text]} {
            # Lan VSS ghi de lan VDD: giu moi net mot ban.
            file copy -force $log [file join $::VOLTUS_DIR logs "voltus_rail_${net}_[file tail $log]"]
            foreach line [split $text "\n"] {
                if {[regexp {ERROR} $line] && [llength $why] < 6} {
                    lappend why "[file tail $log]: [string trim $line]"
                }
            }
        }
    }
    set results {}
    foreach path [glob -nocomplain -directory $out *] {
        if {[file tail $path] ne "era_work"} {
            lappend results $path
        }
    }
    if {[llength $why] == 0 && [llength $results] == 0} {
        lappend why "khong co ket qua nao trong $out ngoai era_work"
    }
    set rpts 0
    foreach path [voltus_files_under $out 4] {
        if {[string match *.rpt $path]} {
            incr rpts
        }
    }
    if {[llength $why] == 0 && $rpts == 0 &&
        [voltus_rail_finished_logged] <= $finished_before} {
        lappend why "khong co dau hieu analyze_rail da chay: tool log khong co\
 'Finished Rail Analysis' moi va $out khong co file .rpt"
    }
    if {[llength $why] > 0} {
        error "analyze_rail $net: [join $why { | }]"
    }
}

# Mot lan phan tich luoi nguon.  layer_map rong = khong truyen file ghep lop.
proc voltus_rail {layer_map pads} {
    # XOA work/ TRUOC KHI TRICH (truoc ca set_rail_analysis_mode, de khong xoa
    # thu gi lenh do tao ra).  Voltus khong don thu muc nay giua hai lan chay.
    # Run 2026-10-13 22:00, lan dau tren luoi nguon moi:
    #   - 37 / 41 file <net>_part_N.floattxt trong work/ la cua run 14:26 / 15:49
    #     tren thiet ke CU (git log tung file); lan trich moi chi ghi lai 4 file.
    #     Moi file la danh sach nut / dien tro "noi" theo SO THU TU.
    #   - Voltus bo 26192 nguon dong VSS / 15543 VDD va mach sau khi ghep thieu
    #     3448 / 1347 via V2, chi o M3-M5 va via V2-V4 - dung cac lop ma so thu
    #     tu trong file cu tro vao; M6-M9, M1, M2 khop tung phan tu voi work/.
    #   - VSS nay 0.102 V tren M3/M4, 0.072 V tren M1.  Giai lai chinh luoi dien
    #     tro trong work/ (23 partition, khong bo gi): 16 mV; M5-M9 khop Voltus
    #     trong 2 mV.
    # Suy ra (chua thay dong log nao cua tool noi thang): buoc ghep luoi doc ca
    # file floattxt cu.  Kiem bang lan chay sau: dong 'KHONG NOI' cua file tom
    # tat phai ve gan 0.
    set work [file join $::VOLTUS_DIR work]
    file delete -force $work

    set mode_cmd [list set_rail_analysis_mode \
        -method era_static \
        -accuracy hd \
        -enable_xp [expr {$::VOLTUS_XP ? "true" : "false"}] \
        -em_temperature 110 \
        -extraction_tech_file $::QRC_FILE]
    if {$layer_map ne ""} {
        # -lef_layermap bi tu choi (IMPTCM-48, run 2026-10-11); usage cua lenh
        # co -era_lef_layermap.
        lappend mode_cmd -era_lef_layermap $layer_map
    }
    # Option thu them tu dong lenh, vi du VOLTUS_RAIL_OPTS="-enable_scheduler false".
    lappend mode_cmd {*}$::VOLTUS_RAIL_OPTS
    {*}$mode_cmd

    set_pg_nets -net VDD -voltage $::VOLTUS_VDD -threshold $::VOLTUS_VDD_MIN
    set_pg_nets -net VSS -voltage 0.0 -threshold $::VOLTUS_VSS_MAX
    voltus_power_pads $pads
    # Dong cua tung instance tu report_power.  Thieu lenh nay thi analyze_rail
    # dung o VOLTUS_RAIL-1152 (che do khong XP khong tu lay).
    catch {set_power_data -reset}
    set_power_data -format current -scale 1 $::VOLTUS_POWER_DATA

    foreach net {VDD VSS} {
        set out [file join $::VOLTUS_DIR outputs "rail_$net"]
        file delete -force $out
        file delete -force [file join $::VOLTUS_DIR voltus_rail.log]
        # Lan VSS chay sau lan VDD trong cung work/: bo file trung ten cua lan
        # thu truoc (TopLevelPGDB_* la ten chung cua ca hai net khi scheduler bat).
        foreach stale [glob -nocomplain -directory $work "${net}_part_*" "TopLevelPGDB_part_*"] {
            file delete -force $stale
        }
        set failures_before [voltus_rail_failures_logged]
        set finished_before [voltus_rail_finished_logged]
        analyze_rail -type net -output $out $net
        voltus_rail_check $net $out $failures_before $finished_before
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
    # Option noi them vao set_rail_analysis_mode (danh sach Tcl).  Mac dinh
    # "-enable_scheduler false": run 2026-10-13 14:26 la lan dau analyze_rail
    # chay het voi no; de scheduler bat thi buoc ghep luoi (SMG) tim
    # VDD_part_N.mhdr trong khi buoc trich ghi TopLevelPGDB_part_N.*
    # (VOLTUS_RAIL_SMG-0048).  VOLTUS_RAIL_OPTS=none = khong noi gi.
    set VOLTUS_RAIL_OPTS [voltus_env VOLTUS_RAIL_OPTS "-enable_scheduler false"]
    if {$VOLTUS_RAIL_OPTS eq "none"} {
        set VOLTUS_RAIL_OPTS ""
    }
    # Diem cap nguon (xem voltus_power_pads) va buoc rai nguon ap cua kieu pin / ring.
    set VOLTUS_PADS [voltus_env VOLTUS_PADS pin]
    if {$VOLTUS_PADS ni {pin ring defpin auto}} {
        error "VOLTUS_PADS phai la pin, ring, defpin hoac auto, dang la '$VOLTUS_PADS'"
    }
    set VOLTUS_PAD_PITCH [voltus_env VOLTUS_PAD_PITCH 10.0]
    if {![string is double -strict $VOLTUS_PAD_PITCH] || $VOLTUS_PAD_PITCH <= 0} {
        error "VOLTUS_PAD_PITCH phai la so duong (um), dang la '$VOLTUS_PAD_PITCH'"
    }
    set voltus_cpus [voltus_env VOLTUS_CPUS 1]
    if {![string is integer -strict $voltus_cpus] || $voltus_cpus < 1} {
        error "VOLTUS_CPUS phai la so nguyen >= 1, dang la '$voltus_cpus'"
    }
    # Nguong cua mau Mul32: VDD duoc sut toi 0.65 V, VSS duoc nay toi 0.05 V.
    set VOLTUS_VDD     0.7
    set VOLTUS_VDD_MIN 0.65
    set VOLTUS_VSS_MAX 0.05
    # So nguon dong (trong ~1.4 trieu) Voltus duoc phep coi la khong noi ma ket
    # qua van tinh la hop le.  Luoi dung chi con vai manh chan M3 roi cua macro
    # TAG (16 tap VDD, dem tu work/ cua run 2026-10-13 22:00); run do bo 15543 /
    # 26192 vi work/ cu (xem voltus_rail).
    set VOLTUS_MAX_DISCONNECTED [voltus_env VOLTUS_MAX_DISCONNECTED 100]
    if {![string is integer -strict $VOLTUS_MAX_DISCONNECTED] || $VOLTUS_MAX_DISCONNECTED < 0} {
        error "VOLTUS_MAX_DISCONNECTED phai la so nguyen >= 0, dang la '$VOLTUS_MAX_DISCONNECTED'"
    }

    # File ghep lop cho phan trich luoi nguon.  LEF co M1..M9 + Pad, QRC co
    # LISD M1..M9: khong co file nay thi Innovus/IQuantus ghep theo vi tri
    # (M8 -> m7, M9 -> m8), va luoi nguon nam chinh tren M8/M9.  Run 2026-10-11
    # chay khong co file nay va Voltus tu ghep dung nhu vay (VOLTUS_LGEN-4286).
    # Dinh dang "metal <QRC> lefdef <LEF>" va option -era_lef_layermap CHUA duoc
    # kiem tren tool, nen hong thi voltus.tcl tu chay lai khong co no va ghi
    # WARNING; con dong VOLTUS_LGEN-3611 trong log = file chua duoc dung.
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
    # Innovus chay 'setDesignMode -process 7' (init_common.tcl) va Tempus da
    # dat dong nay tu 2026-10-11 (log Tempus: "Design Mode: 7nm").  Voltus toi
    # run 2026-10-13 15:49 van ghi "Both design process and tech node are not
    # set" / "Design Mode: 65nm".  Dat sau set_top_module nhu tempus.tcl.
    # VOLTUS_PROCESS=none bo lenh nay (quay ve 65nm): run 2026-10-13 22:00 la lan
    # dau chay 7nm va cung la lan dau Voltus bo nham mot phan luoi.  Nguyen nhan
    # tim duoc la work/ cu (voltus_rail), khong phai dong nay; cong tac de tach
    # hai thu neu xoa work/ roi ma van con nguon dong 'KHONG NOI'.
    set VOLTUS_PROCESS [voltus_env VOLTUS_PROCESS 7]
    if {$VOLTUS_PROCESS eq "none"} {
        set VOLTUS_PROCESS_NOTE "KHONG dat set_design_mode (VOLTUS_PROCESS=none)"
    } else {
        set VOLTUS_PROCESS_NOTE "set_design_mode -process $VOLTUS_PROCESS"
        if {[catch {set_design_mode -process $VOLTUS_PROCESS} mode_err]} {
            voltus_warn "set_design_mode -process $VOLTUS_PROCESS: $mode_err - van tinh o mac dinh 65nm"
            set VOLTUS_PROCESS_NOTE "set_design_mode -process $VOLTUS_PROCESS BI TU CHOI"
        }
    }
    read_def $VOLTUS_DEF
    read_sdc $VOLTUS_SDC
    read_spef $VOLTUS_SPEF_FILE

    # --------------------------------------------------------------------
    # 2. CONG SUAT TINH
    # --------------------------------------------------------------------
    set VOLTUS_POWER_RPT [file join $VOLTUS_DIR reports power_static.rpt]
    file delete -force $VOLTUS_POWER_RPT
    # -write_static_currents: file dong static_<net>.ptiavg cho analyze_rail.
    # Run 2026-10-11 chi bat -create_binary_db nen outputs/power chi co
    # power.db, khong co file .ptiavg nao.
    set VOLTUS_POWER_DIR [file join $VOLTUS_DIR outputs power]
    file delete -force $VOLTUS_POWER_DIR
    if {[catch {set_power_analysis_mode -method static -corner max \
            -create_binary_db true -write_static_currents true} mode_err]} {
        voltus_warn "set_power_analysis_mode -write_static_currents bi tu choi: $mode_err"
        set_power_analysis_mode -method static -corner max -create_binary_db true
    }
    set_power_output_dir $VOLTUS_POWER_DIR
    report_power -outfile $VOLTUS_POWER_RPT
    set power_totals [voltus_power_totals $VOLTUS_POWER_RPT]
    if {[llength $power_totals] == 0} {
        error "report_power khong ghi dong 'Total Power:' nao vao $VOLTUS_POWER_RPT"
    }
    # report_power in "# Design Mode: <node>" vao tool log: doc lai de biet
    # set_design_mode co hieu luc that khong ('puts' khong vao log, va lenh co
    # the duoc nhan ma khong doi gi).
    set mode_7nm  [voltus_tool_log_count {# Design Mode: 7nm}]
    set mode_65nm [voltus_tool_log_count {# Design Mode: 65nm}]
    append VOLTUS_PROCESS_NOTE "; tool log ghi 'Design Mode: 7nm' $mode_7nm lan, '65nm' $mode_65nm lan"
    if {$mode_65nm > 0 || $mode_7nm == 0} {
        voltus_warn "tool log khong xac nhan 'Design Mode: 7nm' (7nm $mode_7nm lan, 65nm $mode_65nm lan) -\
 cong suat / luoi nguon co the van tinh o mac dinh 65nm"
    }
    # Run 2026-10-11 13:18: static_VDD.ptiavg / static_VSS.ptiavg duoc ghi CANH
    # file -outfile (reports/), khong phai trong set_power_output_dir.
    set VOLTUS_POWER_DATA [lsort [concat \
        [glob -nocomplain -directory $VOLTUS_POWER_DIR *.ptiavg] \
        [glob -nocomplain -directory [file dirname $VOLTUS_POWER_RPT] *.ptiavg]]]
    if {[llength $VOLTUS_POWER_DATA] == 0} {
        # Cach trao power.db cho set_power_data CHUA duoc kiem tren tool.
        set power_db [file join $VOLTUS_POWER_DIR power.db]
        if {[file isfile $power_db]} {
            voltus_warn "report_power khong ghi file .ptiavg nao vao $VOLTUS_POWER_DIR - thu power.db"
            set VOLTUS_POWER_DATA [list $power_db]
        }
    }

    # --------------------------------------------------------------------
    # 3. LUOI NGUON (early rail analysis, khong can thu vien PGV)
    # --------------------------------------------------------------------
    # Thu lan luot; lan dau chay het thi dung.  Moi lan hong de lai mot WARNING
    # noi ro hong vi dau.
    set rail_note "bo qua (VOLTUS_RAIL=0)"
    set rail_ok 1
    if {$VOLTUS_RAIL} {
        set pad_label(defpin) "defpin (MOT nguon ap moi net)"
        set pad_label(auto)   "auto_voltage_source_creation"
        set pad_choices [list $VOLTUS_PADS]
        if {$VOLTUS_PADS in {pin ring}} {
            # pin: hinh chan PG trong LEF abstract cua top; ring: cac doan ring
            # soc_add_pg_pins ghi ra.  Ca hai do KHOI 16 ghi cung luc voi DEF.
            if {$VOLTUS_PADS eq "pin"} {
                set pad_src [file join $FLOW_ROOT innovus outputs "${TOP}.lef"]
            } else {
                set pad_src [file join $FLOW_ROOT innovus outputs "${TOP}_pg_ring.txt"]
            }
            set pad_counts {}
            set pad_rects {}
            if {[catch {
                foreach net {VDD VSS} {
                    if {$VOLTUS_PADS eq "pin"} {
                        set rects [voltus_lef_pin_rects $pad_src $net]
                    } else {
                        set rects [voltus_ring_rects $pad_src $net]
                    }
                    set sources [voltus_rect_sources $rects $net $VOLTUS_PAD_PITCH]
                    if {[llength $sources] == 0} {
                        error "khong co hinh $net nao trong $pad_src"
                    }
                    set VOLTUS_PAD_FILE($net) [file join $VOLTUS_DIR outputs "vsrc_$net.pp"]
                    voltus_write_pad_file $VOLTUS_PAD_FILE($net) $sources
                    lappend pad_counts "$net [llength $sources]"
                    lappend pad_rects [llength $rects]
                }
            } pad_err]} {
                voltus_warn "khong tao duoc file nguon ap kieu $VOLTUS_PADS ($pad_err) - dung defpin"
                set pad_choices {}
            } else {
                set pad_label($VOLTUS_PADS) "$VOLTUS_PADS ([join $pad_counts {, }] nguon ap rai doc\
 [join $pad_rects { / }] hinh [expr {$VOLTUS_PADS eq "pin" ? "chan PG" : "ring"}] trong\
 [file tail $pad_src], buoc $VOLTUS_PAD_PITCH um; chi cap tu canh co hinh)"
                if {[file mtime $pad_src] < [file mtime $VOLTUS_DEF] - 3600} {
                    voltus_warn "[file tail $pad_src] cu hon DEF hon 1 gio - toa do diem cap nguon co the khong khop"
                }
                # Luoi M8/M9 duoc thiet ke cho nguon cap tu ca 4 canh ring
                # (innovus/tcl/manual/soc_fp_config.tcl): uoc luong sut ap tren
                # M8/M9 la ~6 mV voi 4 canh, ~50 mV neu chi canh tren.
                if {[tcl::mathfunc::min {*}$pad_rects] < 4} {
                    set pad_hint [expr {$VOLTUS_PADS eq "pin" ?
                        "createPGPin khong nhan du hinh (xem WARNING cuoi KHOI 16); chay lai bang\
 'make all VOLTUS_PADS=ring'" : "ring loi thieu doan - xem KHOI 2"}]
                    voltus_warn "diem cap nguon chi co [join $pad_rects { / }] hinh (VDD / VSS), khong\
 du 4 canh ring - sut ap se cao hon thiet ke; $pad_hint"
                }
                if {$VOLTUS_PADS eq "ring"} {
                    voltus_warn "VOLTUS_PADS=ring: nguon ap dat theo hinh ring loi, khong theo chan PG\
 khai bao trong LEF/DEF"
                }
            }
        }
        # Kieu da chon bi Tcl tu choi (sai cu phap) thi con defpin de van co so.
        if {"defpin" ni $pad_choices} {
            lappend pad_choices defpin
        }
        set attempts {}
        foreach map [lsort -unique -decreasing [list $VOLTUS_LAYER_MAP ""]] {
            foreach pads $pad_choices {
                lappend attempts [list $map $pads]
            }
        }
        set rail_note ""
        if {[llength $VOLTUS_POWER_DATA] == 0} {
            voltus_warn "khong co file dong (.ptiavg / power.db) trong $VOLTUS_POWER_DIR - bo analyze_rail"
            set attempts {}
        }
        foreach attempt $attempts {
            foreach {map pads} $attempt break
            set label "ghep lop [expr {$map eq "" ? "THEO VI TRI" : [file tail $map]}],\
 diem cap nguon $pad_label($pads)"
            if {[catch {voltus_rail $map $pads} rail_err]} {
                # Option bi tu choi (IMPTCM-48) nem loi Tcl KHONG co noi dung.
                if {[string trim $rail_err] eq ""} {
                    set rail_err "lenh bi tu choi, Tcl khong tra noi dung - xem logs/voltus.log"
                }
                voltus_warn "analyze_rail ($label) hong: $rail_err"
                # Cac cach thu con lai chi khac option.  analyze_rail da chay
                # (~6 phut moi net) roi moi hong thi doi option khong cuu duoc.
                if {[string match "analyze_rail *" $rail_err]} {
                    break
                }
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
    lappend lines "  process: $VOLTUS_PROCESS_NOTE"
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
    set power_data_names {}
    foreach path $VOLTUS_POWER_DATA {
        lappend power_data_names [file tail $path]
    }
    lappend lines "  file dong cho luoi nguon: [expr {[llength $power_data_names] ? [join $power_data_names { }] : "KHONG CO"}]"
    lappend lines "  luoi nguon: $rail_note"
    # DONE can ca hai: analyze_rail chay het VA sut ap dat nguong.  Run
    # 2026-10-13 14:26 ghi DONE trong khi VDD thap nhat -7.8 V.
    set ir_ok 1
    set integrity_ok 1
    if {$VOLTUS_RAIL && $rail_ok} {
        lappend lines "    nguong: VDD >= $VOLTUS_VDD_MIN V (danh dinh $VOLTUS_VDD V), VSS <= $VOLTUS_VSS_MAX V;\
 -enable_xp [expr {$VOLTUS_XP ? "bat" : "tat"}][expr {$VOLTUS_RAIL_OPTS ne "" ? "; option them: $VOLTUS_RAIL_OPTS" : ""}]"
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
            set ir {}
            foreach rpt $rpts {
                if {[file tail $rpt] ne "$net.main.rpt"} {
                    continue
                }
                set fp [open $rpt r]
                while {[llength $ir] == 0 && [gets $fp line] >= 0} {
                    set ir [voltus_ir_values $line]
                }
                close $fp
            }
            if {[llength $ir] != 3} {
                set ir_ok 0
                lappend lines "    $net: KHONG doc duoc dong 'Minimum, Average, Maximum IR drop' trong\
 $net.main.rpt - khong ket luan duoc sut ap"
            } elseif {$net eq "VDD"} {
                set worst [lindex [lsort -real $ir] 0]
                set met [expr {$worst >= $VOLTUS_VDD_MIN}]
                lappend lines [format "    VDD: dien ap nut thap nhat %.4f V, trung binh %.4f V; nguong >= %s V -> %s" \
                    $worst [lindex $ir 1] $VOLTUS_VDD_MIN [expr {$met ? "DAT" : "KHONG DAT"}]]
                set ir_ok [expr {$ir_ok && $met}]
            } else {
                set worst [lindex [lsort -real $ir] end]
                set met [expr {$worst <= $VOLTUS_VSS_MAX}]
                lappend lines [format "    VSS: do nay cao nhat %.4f V, trung binh %.4f V; nguong <= %s V -> %s" \
                    $worst [lindex $ir 1] $VOLTUS_VSS_MAX [expr {$met ? "DAT" : "KHONG DAT"}]]
                set ir_ok [expr {$ir_ok && $met}]
            }
            # Con so o tren chi tinh tren phan luoi Voltus coi la CON NOI.  Bo
            # qua nhieu nguon dong thi no khong con la sut ap cua thiet ke.
            set integ [voltus_rail_integrity $net]
            if {[dict size $integ] == 0} {
                voltus_warn "$net: tool log khong co bang 'Circuit profile' cua 'Net $net:' - KHONG biet Voltus\
 co bo nguon dong nao khong; tim 'current sources are disconnected' trong logs/voltus.log"
            } else {
                set dropped [dict get $integ sources]
                lappend lines "    $net: Voltus coi la KHONG NOI: $dropped nguon dong, [dict get $integ nodes] nut,\
 [dict get $integ segments] doan day; noi yeu [dict get $integ weak] doan"
                if {[llength [dict get $integ layers]] > 0} {
                    lappend lines "    $net: sut lon nhat tung lop (mV): [join [dict get $integ layers] {, }]"
                }
                if {$dropped > $VOLTUS_MAX_DISCONNECTED} {
                    set ir_ok 0
                    set integrity_ok 0
                    lappend lines "    $net: $dropped nguon dong bi bo > $VOLTUS_MAX_DISCONNECTED (VOLTUS_MAX_DISCONNECTED) -\
 con so sut ap o tren KHONG HOP LE, ke ca khi no dat nguong"
                }
            }
            if {[catch {voltus_keep_reports $net $out} kept]} {
                lappend lines "    $net: khong chep duoc bao cao sang reports/rail_$net ($kept)"
            } else {
                lappend lines "    $net: $kept file -> reports/rail_$net/ (400 dong dau moi .rpt, ir_limit.gif, ir_linear.gif)"
            }
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
    if {$rail_ok && !$integrity_ok} {
        lappend lines "  KET LUAN: analyze_rail chay het nhung Voltus BO mot phan luoi (dong 'KHONG NOI' o tren) -\
 kiem verifyConnectivity cua Innovus va work/ cu truoc khi doc con so sut ap"
    } elseif {$rail_ok && !$ir_ok} {
        lappend lines "  KET LUAN: analyze_rail chay het nhung sut ap KHONG DAT nguong (dong VDD / VSS o tren)"
    }
    voltus_write_summary $VOLTUS_SUMMARY [expr {$rail_ok && $ir_ok ? "DONE" : "FAIL"}] $lines

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
