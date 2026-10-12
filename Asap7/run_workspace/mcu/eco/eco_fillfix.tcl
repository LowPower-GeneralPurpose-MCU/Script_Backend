############################################################
## Sua DRV (max_transition) do METAL FILL sinh ra, truoc khi chay KHOI 15.
##
##     cd Asap7/run_workspace/mcu/eco && make fillfix      (sau 'make all')
##
##   vao : ../innovus/saved/top_soc_postRoute_eco.enc.dat      (make all)
##   ra  : ../innovus/saved/top_soc_postRoute_ecofill.enc.dat  (chi khi co sua)
##         reports/eco_fillfix_summary.rpt   dong dau PASS / FAIL, va dong
##                                           'checkpoint <...>' cho make finish
##         reports/fillfix_nets.rpt          tung net da xu ly o tung vong
##         reports/timing_fillfix/, timing_fillfix_hold/
##
## Vi sao can buoc nay.  Run 2026-10-12: 'make all' PASS (max_tran Real 0 net,
## ca voi ECO_DRV_MARGIN=0.25) roi 'make finish' dung o cong timing sau KHOI 15:
##     max_tran Real 64 net / 198 chan, xau nhat -0.025 ns
## 63 / 64 net do khong vi pham truoc ECO va cung khong vi pham sau ECO; chung
## chi vuot 150 ps khi metal fill da nam canh day.  eco_drv.tcl toi uu tren RC
## KHONG co fill nen khong bao gio thay chung, va margin khong cuu duoc: chinh
## log do ghi optDesign bo lai 126 net "can't be fixed by DRV optimization"
## (84 "instance couldn't be resized", 42 "no move is found").  21 / 64 net la
## DFFASRHQNx1 - chi co ban x1 - keo dung mot tai, 13 net la hold buffer
## HB1xp67: driver yeu, day dai, fill them C la vuot.
##
## Cach lam, trong MOT session, tren database CHUA co filler:
##   1. do fill thu (soc_metal_fill - dung bo so cua KHOI 15), timeDesign
##   2. net nao vuot gioi han thi xoa fill, chen mot buffer sat driver
##      (eco_buffer_nets), ecoRoute, kiem DRC + connectivity, saveDesign
##   3. do fill lai va do lai; lap toi da ECO_FILL_ROUNDS vong sua
## Checkpoint luon duoc luu TRUOC khi do fill thu nen khong bao gio chua fill;
## KHOI 15 cua 'make finish' tu chen filler va fill that.
##
## Bien moi truong:
##   ECO_FILL_GUARD=0.010   ns.  Khi do, gioi han max_transition theo clock bi
##                          siet them chung nay de bat ca net sat gioi han:
##                          fill that o KHOI 15 khong trung khit fill thu, va
##                          Tempus lech Innovus toi +-8 ps (run 2026-10-12).
##                          Rang buoc duoc tra ve gia tri goc ngay sau khi do.
##                          0 = do dung gioi han that, khong dung vao SDC.
##   ECO_FILL_ROUNDS=3      so vong sua toi da
##   ECO_FILL_BUF=BUFx4_ASAP7_75t_R
##   ECO_FILL_DIST=0.9      ecoAddRepeater -relativeDistToSink (1 = sat driver)
##   ECO_FILL_MAX_NETS=400  so net sua toi da moi vong (xau nhat truoc)
##   ECO_CPUS=1
##
## CHUA chay thu tren Innovus 23.14: 'ecoAddRepeater -net ... -relativeDistToSink'
## (co duong lui, xem eco_buffer_nets), 'set_max_transition' trong
## set_interactive_constraint_modes (bi tu choi thi do khong guard va ghi
## WARNING), addMetalFill tren database chua co filler.
############################################################

set ECO_DIR [file dirname [file normalize [info script]]]
source [file join $ECO_DIR eco_common.tcl]
eco_require_no_design eco_fillfix.tcl

set ECO_FILLFIX_SUMMARY [file join $ECO_DIR reports eco_fillfix_summary.rpt]

if {[catch {
    if {![file isfile ./tcl/project_config.tcl]} {
        error "Khong thay ./tcl/project_config.tcl - phai chay tu thu muc mcu/innovus\
 (cd mcu/eco && make fillfix)"
    }
    source ./tcl/project_config.tcl
    foreach dir {logs reports} {
        file mkdir [file join $ECO_DIR $dir]
    }
    file delete -force $ECO_FILLFIX_SUMMARY

    # --------------------------------------------------------------------
    # 0. THAM SO
    # --------------------------------------------------------------------
    set ECO_IN            [format "./saved/%s_postRoute_eco.enc.dat" $TOP]
    set ECO_FILL_OUT      [format "./saved/%s_postRoute_ecofill.enc" $TOP]
    set ECO_FILL_GUARD    [eco_env ECO_FILL_GUARD 0.010]
    set ECO_FILL_ROUNDS   [eco_env ECO_FILL_ROUNDS 3]
    set ECO_FILL_BUF      [eco_env ECO_FILL_BUF BUFx4_ASAP7_75t_R]
    set ECO_FILL_DIST     [eco_env ECO_FILL_DIST 0.9]
    set ECO_FILL_MAX_NETS [eco_env ECO_FILL_MAX_NETS 400]
    set ECO_CPUS          [eco_env ECO_CPUS 1]

    if {![string is double -strict $ECO_FILL_GUARD] ||
        $ECO_FILL_GUARD < 0.0 || $ECO_FILL_GUARD > 0.050} {
        error "ECO_FILL_GUARD phai nam trong 0 .. 0.050 ns, dang la '$ECO_FILL_GUARD'"
    }
    if {![string is double -strict $ECO_FILL_DIST] ||
        $ECO_FILL_DIST < 0.0 || $ECO_FILL_DIST > 1.0} {
        error "ECO_FILL_DIST phai nam trong 0 .. 1, dang la '$ECO_FILL_DIST'"
    }
    foreach name {ECO_FILL_ROUNDS ECO_FILL_MAX_NETS ECO_CPUS} {
        if {![string is integer -strict [set $name]] || [set $name] < 1} {
            error "$name phai la so nguyen >= 1, dang la '[set $name]'"
        }
    }
    if {![file isdirectory $ECO_IN]} {
        error "Khong co $ECO_IN - chay 'make all' truoc"
    }
    set eco_rpt [file join $ECO_DIR reports eco_summary.rpt]
    if {[eco_summary_verdict $eco_rpt] ne "PASS"} {
        error "$eco_rpt bao '[eco_summary_verdict $eco_rpt]' - chi chay tren ECO da PASS"
    }

    # Gioi han 150 ps la 'set_max_transition' dat tren clock: lay tu SDC cua
    # chinh checkpoint; khong co thi lay ban Innovus da nap o KHOI 0.
    set sdc_files [glob -nocomplain -directory [file join $ECO_IN mmmc modes] */*.sdc]
    set clock_limits [eco_sdc_clock_max_tran $sdc_files]
    if {[llength $clock_limits] == 0} {
        set clock_limits [eco_sdc_clock_max_tran \
            [list [format "./outputs/%s_syn.innovus.sdc" $TOP]]]
    }
    set guard $ECO_FILL_GUARD
    set tight_limits {}
    foreach item $clock_limits {
        lassign $item flags value clocks
        if {$value - $guard <= 0.0} {
            error "ECO_FILL_GUARD $guard ns >= gioi han $value ns cua clock $clocks"
        }
        lappend tight_limits [format %.3f [expr {$value - $guard}]]
    }
    if {$guard > 0.0 && [llength $clock_limits] == 0} {
        eco_warn "khong doc duoc dong 'set_max_transition ... \[get_clocks ...\]' nao\
 trong SDC cua $ECO_IN - do o gioi han that, khong co khoang du"
        set guard 0.0
    }

    # --------------------------------------------------------------------
    # 1. MO CHECKPOINT
    # --------------------------------------------------------------------
    set eco_t0 [clock seconds]
    restoreDesign $ECO_IN $TOP
    source ./tcl/manual/soc_fp_config.tcl
    source ./tcl/manual/soc_fp_procs.tcl
    setMultiCpuUsage -acquireLicense $ECO_CPUS -localCpu $ECO_CPUS
    setDistributeHost -local
    set derate_note [eco_session_constraints]

    if {[llength [dbGet -e head.libCells.name $ECO_FILL_BUF]] == 0} {
        error "Khong co lib cell '$ECO_FILL_BUF' - dat ECO_FILL_BUF"
    }
    set inst_before [llength [dbGet top.insts]]

    set rpt_dir  [file join $ECO_DIR reports timing_fillfix]
    set rpt_hold [file join $ECO_DIR reports timing_fillfix_hold]
    set net_rpt  [file join $ECO_DIR reports fillfix_nets.rpt]
    set net_fp   [open $net_rpt w]
    puts $net_fp "# eco_fillfix.tcl: net max_transition khi da co metal fill.\
  Slack tinh theo gioi han THAT."
    puts $net_fp "# vong  slack(ns)  net  chan_xau_nhat  cell/port  xu_ly"

    # --------------------------------------------------------------------
    # 2. VONG: fill thu -> do -> sua
    # --------------------------------------------------------------------
    set round_notes {}
    set saved 0
    set added 0
    set viol {}
    set near {}
    set wns "?"
    set viol_below 0.0005
    for {set round 0} {1} {incr round} {
        soc_metal_fill

        # Siet gioi han chi trong luc do.  Tra ve gia tri goc NGAY, ke ca khi
        # timeDesign hong: saveDesign va KHOI 15/16 phai thay gioi han that.
        if {$guard > 0.0} {
            if {[catch {eco_set_clock_max_tran $clock_limits $guard} tight_err]} {
                eco_warn "khong siet duoc max_transition ($tight_err) - do o gioi\
 han that, khong co khoang du $guard ns"
                # Dong nao da siet duoc thi duoc tra ve o day; dong vua hong thi
                # chua tung doi nen hong lan nua cung khong sao.
                catch {eco_set_clock_max_tran $clock_limits 0.0}
                set guard 0.0
            }
        }
        set failed [catch {timeDesign -postRoute -outDir $rpt_dir -prefix r$round} time_err]
        if {$guard > 0.0} {
            eco_set_clock_max_tran $clock_limits 0.0
        }
        if {$failed} {
            error "timeDesign vong $round hong: $time_err"
        }

        set text [soc_read_text_or_gz [file join $rpt_dir r$round.tran]]
        if {$text eq ""} {
            error "Khong co [file join $rpt_dir r$round.tran](.gz) - timeDesign khong xuat bao cao DRV"
        }
        set sum [soc_timing_summary $rpt_dir r$round setup]
        set wns [expr {[dict exists $sum wns] ? [dict get $sum wns] : "?"}]
        set rows {}
        set viol {}
        set near {}
        foreach row [eco_tran_report $text] {
            lassign $row net slack pin cellport limit loads
            set real [eco_real_slack $slack $limit $tight_limits $guard]
            set row [list $net $real $pin $cellport $limit $loads]
            lappend rows $row
            # Bao cao lam tron toi 1 ps: "-0.000" van la vi pham va van duoc
            # bang DRV cua timeDesign dem (cong cua KHOI 16 doc bang do).
            if {$real < $viol_below} {
                lappend viol $row
            } else {
                lappend near $row
            }
        }
        set note [format "vong %d: co fill, setup WNS %s ns, max_tran vuot gioi han %d net" \
            $round $wns [llength $viol]]
        if {[llength $viol] > 0} {
            append note [format " (xau nhat %s %+.3f ns)" \
                [lindex $viol 0 0] [lindex $viol 0 1]]
        }
        if {$guard > 0.0} {
            append note [format ", trong khoang du %.3f ns: %d net" $guard [llength $near]]
        }

        if {[llength $rows] == 0 || $round >= $ECO_FILL_ROUNDS} {
            foreach row $rows {
                lassign $row net real pin cellport
                puts $net_fp [format "%d  %+.3f  %s  %s  %s  %s" $round $real $net $pin \
                    [expr {$cellport eq "" ? "-" : $cellport}] \
                    [expr {$real < $viol_below ? "CON_VI_PHAM" : "con_trong_khoang_du"}]]
            }
            lappend round_notes $note
            puts "ECO FILLFIX: $note"
            break
        }

        # --- sua -----------------------------------------------------------
        set todo [lrange $rows 0 [expr {$ECO_FILL_MAX_NETS - 1}]]
        if {[llength $rows] > [llength $todo]} {
            eco_warn "vong $round: [llength $rows] net can sua, chi sua\
 [llength $todo] net xau nhat (ECO_FILL_MAX_NETS)"
        }
        eco_delete_metal_fill
        set results [eco_buffer_nets $todo $ECO_FILL_BUF $ECO_FILL_DIST]
        array unset form_count
        array set form_count {dist 0 net 0 term 0 fail 0}
        foreach row $todo result $results {
            lassign $row net real pin cellport
            lassign $result rnet form why
            if {$form eq ""} {
                incr form_count(fail)
                set action "KHONG_CHEN_DUOC: $why"
            } else {
                incr form_count($form)
                incr added
                set action "buffer($form)"
            }
            puts $net_fp [format "%d  %+.3f  %s  %s  %s  %s" $round $real $net $pin \
                [expr {$cellport eq "" ? "-" : $cellport}] $action]
        }
        flush $net_fp
        set done [expr {$form_count(dist) + $form_count(net) + $form_count(term)}]
        append note [format " -> chen %d %s (sat driver %d, -net %d, -term %d, khong chen duoc %d)" \
            $done $ECO_FILL_BUF $form_count(dist) $form_count(net) \
            $form_count(term) $form_count(fail)]
        lappend round_notes $note
        puts "ECO FILLFIX: $note"
        if {$done == 0} {
            error "vong $round: khong chen duoc buffer nao trong [llength $todo] net -\
 xem cot xu_ly trong $net_rpt"
        }
        if {$form_count(dist) == 0} {
            eco_warn "vong $round: Innovus tu choi 'ecoAddRepeater -relativeDistToSink';\
 buffer duoc chen bang dang -net/-term, vi tri do Innovus chon - neu vong sau net do\
 van vi pham thi buffer da nam xa driver"
        }

        # Buffer moi chua co day; cell moi chua noi rail.  Cung chuoi lenh voi
        # sau soc_fix_cg_hold o KHOI 14.
        ecoRoute
        ecoRoute -fix_drc
        soc_reconnect_stdcell_pg fillfix
        set fill_drc [soc_verify_drc ./verify_rpt/drc_fillfix.rpt -limit 500000 \
            -allow-nets $SOC_DRC_WAIVE_NETS -allow-types $SOC_DRC_WAIVE_TYPES]
        if {$fill_drc > 0} {
            error "vong $round: $fill_drc vi pham DRC sau khi chen buffer + ecoRoute -\
 xem verify_rpt/drc_fillfix.rpt.  Neu la short voi net _FILLS_RESERVED thi\
 deleteMetalFill chua xoa het fill thu."
        }
        verifyConnectivity -type all -error 100000 -warning 1000 \
            -report ./verify_rpt/connectivity_fillfix.rpt
        set fill_open [soc_connectivity_problems ./verify_rpt/connectivity_fillfix.rpt]
        if {$fill_open > 0} {
            error "vong $round: $fill_open loi connectivity sau ecoRoute - xem\
 verify_rpt/connectivity_fillfix.rpt"
        }
        # LUU TRUOC khi do fill thu cua vong sau: checkpoint khong bao gio chua
        # fill, va luon la dung database ma phep do ke tiep ket luan.
        saveDesign $ECO_FILL_OUT
        set saved 1
    }
    close $net_fp

    # --------------------------------------------------------------------
    # 3. HOLD KHI CO FILL, KET LUAN
    # --------------------------------------------------------------------
    timeDesign -postRoute -hold -outDir $rpt_hold -prefix final
    set sum_hold [soc_timing_summary $rpt_hold final hold]
    set hold_wns [expr {[dict exists $sum_hold wns] ? [dict get $sum_hold wns] : "?"}]
    set inst_after [llength [dbGet top.insts]]

    set bad {}
    if {[llength $viol] > 0} {
        set names {}
        foreach row [lrange $viol 0 4] {
            lappend names [format "%s (%+.3f ns)" [lindex $row 0] [lindex $row 1]]
        }
        lappend bad "max_tran khi co fill: [llength $viol] net sau $round vong sua -\
 [join $names {, }]"
    }
    foreach {label value} [list setup $wns hold $hold_wns] {
        if {![string is double -strict $value]} {
            lappend bad "$label: khong doc duoc WNS"
        } elseif {$value < 0.0} {
            lappend bad "$label WNS $value ns khi co fill"
        }
    }
    if {[llength $near] > 0 && [llength $viol] == 0} {
        eco_warn "[llength $near] net con cach gioi han duoi $guard ns khi co fill\
 (reports/fillfix_nets.rpt) - Innovus dat, Tempus co the van bao vai net"
    }

    set use_ckpt [expr {$saved ? "$ECO_FILL_OUT.dat" : $ECO_IN}]
    set lines [list \
        "checkpoint $use_ckpt" \
        "ECO fillfix $TOP: $ECO_IN, [expr {[clock seconds] - $eco_t0}] s, $ECO_CPUS CPU" \
        "  cach do  : metal fill thu (bo so KHOI 15) tren database chua co filler;\
 khoang du [format %.3f $guard] ns duoi gioi han max_transition theo clock" \
        "  derate   : $derate_note"]
    foreach note $round_notes {
        lappend lines "  $note"
    }
    lappend lines \
        [format "  cuoi     : setup WNS %s ns, hold WNS %s ns (ca hai khi co fill), max_tran vuot gioi han %d net" \
            $wns $hold_wns [llength $viol]] \
        "  instance : $inst_before -> $inst_after ([format %+d [expr {$inst_after - $inst_before}]]), $added buffer $ECO_FILL_BUF" \
        "  bao cao  : eco/reports/fillfix_nets.rpt, timing_fillfix/, timing_fillfix_hold/"
    if {!$saved} {
        lappend lines "  khong sua gi: make finish dung thang checkpoint cua make all"
    }
    if {[llength $bad] > 0} {
        lappend lines "  KHONG DAT: [join $bad {; }]"
        eco_write_summary $ECO_FILLFIX_SUMMARY FAIL $lines
    } else {
        lappend lines "  tiep theo: make finish (KHOI 15 + 16 tren checkpoint o dong 2)"
        eco_write_summary $ECO_FILLFIX_SUMMARY PASS $lines
    }

    set fp [open $ECO_FILLFIX_SUMMARY r]
    puts "============================================================"
    puts -nonewline [read $fp]
    puts "============================================================"
    close $fp
    if {[llength $bad] > 0} {
        exit 1
    }
} eco_err]} {
    set eco_trace $::errorInfo
    puts "ERROR: eco_fillfix.tcl: $eco_err"
    puts $eco_trace
    catch {close $net_fp}
    catch {eco_write_summary $ECO_FILLFIX_SUMMARY FAIL [list "eco_fillfix.tcl: $eco_err"]}
    exit 1
}
exit 0
