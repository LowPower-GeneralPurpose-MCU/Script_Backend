############################################################
## ECO sua DRV (max_transition) ma Tempus bao tren SPEF Quantus
##
## Chay bang Innovus, tu thu muc mcu/innovus (Makefile lo viec cd):
##     cd Asap7/run_workspace/mcu/eco && make all
##
##   vao : ../innovus/saved/top_soc_postRoute.enc.dat   (cuoi KHOI 14: chua co
##                                                       filler / metal fill)
##         ../tempus/reports/all_violators.rpt          (danh sach chan vi pham)
##   ra  : ../innovus/saved/top_soc_postRoute_eco.enc.dat
##         reports/eco_summary.rpt     dong dau PASS / FAIL
##         reports/timing_pre/, timing_eco/, timing_eco_hold/
##
## Vi sao can buoc nay.  Tempus run 2026-10-11 bao 220 chan max_transition
## (gioi han 150 ps, xau nhat 177 ps, trung vi lech 3 ps) trong khi bang DRV
## cua Innovus ghi "max_tran Real 0".  Hai ben khong nhin cung mot RC: ca flow
## Innovus trich bang tQuantus effortLevel medium voi lop LEF/QRC ghep lech mot
## bac, con Tempus doc SPEF cua mcu/quantus (IQuantus high, lop ghep dung ten):
## C x1.084.  optDesign khong sua thu no khong thay, nen goi lai KHOI 14 y
## nguyen thi khong doi gi.
##
## Cach lam: mo lai checkpoint cuoi KHOI 14, cho Innovus trich RC BANG DUNG
## ENGINE DA SINH RA SPEF SIGNOFF (ECO_EXTRACT=high + file ghep lop), roi chay
## lai dung luot toi uu cua KHOI 14 (-setup -hold -drv, soc_fix_cg_hold,
## ecoRoute, soc_fix_drv) voi gioi han DRV siet them ECO_DRV_MARGIN.  Hold cung
## duoc sua lai tren RC do - Tempus chi con +10 ps.
##
## Bien moi truong (dat tren dong lenh make):
##   ECO_EXTRACT=high|flow   high (mac dinh) = IQuantus + file ghep lop;
##                           flow = giu che do trich cua checkpoint (tQuantus,
##                           Innovus se KHONG thay vi pham - khi do can
##                           ECO_DRV_MARGIN=0.20 de bu ca khoang lech 27 ps)
##   ECO_DRV_MARGIN=0.05     setOptMode -drcMargin: gioi han dung khi sua =
##                           gioi han that x (1 - margin).  CHUA chay thu tren
##                           Innovus 23.14; bi tu choi thi chay khong margin va
##                           ghi WARNING.
##   ECO_CPUS=1              mac dinh 1: IQuantus nhieu tien trinh da treo tren
##                           may nay (quantus.tcl, run 2026-10-09 23:33)
##   ECO_CHECKPOINT=...      checkpoint khac top_soc_postRoute.enc.dat
##   ECO_ALLOW_BAD_LIB=1     van chay khi checkpoint con .lib sai dien ap
##
## Script KHONG ghi de checkpoint goc va KHONG dung vao reports/ cua flow
## chinh.  Sau khi PASS: make finish (KHOI 15 + 16), roi LEC, Quantus, Tempus.
############################################################

set ECO_DIR [file dirname [file normalize [info script]]]
source [file join $ECO_DIR eco_common.tcl]
eco_require_no_design eco_drv.tcl

set ECO_SUMMARY [file join $ECO_DIR reports eco_summary.rpt]

# Innovus chay -no_gui: loi Tcl giua chung se dung o dau nhac va treo make.
# Boc ca flow trong catch de luon thoat voi ket luan ro rang.
if {[catch {
    if {![file isfile ./tcl/project_config.tcl]} {
        error "Khong thay ./tcl/project_config.tcl - phai chay tu thu muc mcu/innovus\
 (cd mcu/eco && make all)"
    }
    source ./tcl/project_config.tcl
    foreach dir {logs reports} {
        file mkdir [file join $ECO_DIR $dir]
    }
    file delete -force $ECO_SUMMARY

    # --------------------------------------------------------------------
    # 0. THAM SO
    # --------------------------------------------------------------------
    set ECO_CHECKPOINT [eco_env ECO_CHECKPOINT [format "./saved/%s_postRoute.enc.dat" $TOP]]
    set ECO_OUT        [format "./saved/%s_postRoute_eco.enc" $TOP]
    set ECO_EXTRACT    [eco_env ECO_EXTRACT high]
    set ECO_DRV_MARGIN [eco_env ECO_DRV_MARGIN 0.05]
    set ECO_CPUS       [eco_env ECO_CPUS 1]
    set ECO_TEMPUS_RPT [file join $FLOW_ROOT tempus reports all_violators.rpt]
    set ECO_LAYER_MAP  [file normalize ./tcl/asap7_lef_to_qrc_layers.map]

    if {$ECO_EXTRACT ne "high" && $ECO_EXTRACT ne "flow"} {
        error "ECO_EXTRACT phai la high hoac flow, dang la '$ECO_EXTRACT'"
    }
    if {![string is double -strict $ECO_DRV_MARGIN] ||
        $ECO_DRV_MARGIN < 0.0 || $ECO_DRV_MARGIN > 0.5} {
        error "ECO_DRV_MARGIN phai nam trong 0 .. 0.5, dang la '$ECO_DRV_MARGIN'"
    }
    if {![string is integer -strict $ECO_CPUS] || $ECO_CPUS < 1} {
        error "ECO_CPUS phai la so nguyen >= 1, dang la '$ECO_CPUS'"
    }
    if {![file isdirectory $ECO_CHECKPOINT]} {
        error "Khong co checkpoint $ECO_CHECKPOINT - can ket qua KHOI 14 cua Innovus"
    }
    if {![file isfile $ECO_TEMPUS_RPT]} {
        error "Khong co $ECO_TEMPUS_RPT - chay mcu/tempus truoc (make all)"
    }
    if {$ECO_EXTRACT eq "high" && ![file isfile $ECO_LAYER_MAP]} {
        error "Khong co file ghep lop $ECO_LAYER_MAP"
    }

    # --------------------------------------------------------------------
    # 1. DANH SACH CUA TEMPUS
    # --------------------------------------------------------------------
    set tempus_viol [eco_tempus_max_tran $ECO_TEMPUS_RPT]
    if {[llength $tempus_viol] == 0} {
        eco_write_summary $ECO_SUMMARY PASS [list \
            "ECO DRV $TOP: $ECO_TEMPUS_RPT khong co vi pham max_transition nao -\
 khong co gi de sua, khong mo checkpoint, khong ghi $ECO_OUT.dat"]
        puts "ECO DRV: Tempus khong bao max_transition nao - khong lam gi."
        exit 0
    }
    set tempus_worst 0.0
    set tempus_limits {}
    foreach item $tempus_viol {
        lassign $item pin req act slack view
        if {$slack < $tempus_worst} {
            set tempus_worst $slack
        }
        lappend tempus_limits $req
    }
    set tempus_limits [lsort -unique -real $tempus_limits]
    puts "ECO DRV: Tempus bao [llength $tempus_viol] chan max_transition,\
 xau nhat [format %.3f $tempus_worst] ns, gioi han $tempus_limits ns"

    # --------------------------------------------------------------------
    # 2. THU VIEN CUA CHECKPOINT
    # --------------------------------------------------------------------
    # Luot toi uu duoi day sua ca hold.  Hold tinh tren lib FF sai dien ap
    # (SIMPLE_RVT_FF 0.7 V thay vi 0.77 V, Tempus 2026-10-11) la sua nham
    # dich: cell cham hon thuc te nen thieu buffer hold.
    set lib_problems [eco_checkpoint_lib_problems $ECO_CHECKPOINT]
    if {[llength $lib_problems] > 0} {
        set lib_msg "Checkpoint $ECO_CHECKPOINT con .lib sai dien ap:
    [join $lib_problems "\n    "]
  restoreDesign nap ban sao trong <checkpoint>/libs/mmmc/, khong phai file cua PDK.
  Sua: python3 scripts/fix_ff_lib.py --apply   (thay ca PDK lan ban sao)"
        if {[eco_env ECO_ALLOW_BAD_LIB 0] eq "1"} {
            eco_warn "ECO_ALLOW_BAD_LIB=1 - $lib_msg"
        } else {
            error "$lib_msg
  Hoac bo qua co chu dich: make all ECO_ALLOW_BAD_LIB=1"
        }
    }

    # --------------------------------------------------------------------
    # 3. MO CHECKPOINT - theo muc (e) "CHAY LAI TU GIUA" cua innovus.tcl
    # --------------------------------------------------------------------
    set eco_t0 [clock seconds]
    restoreDesign $ECO_CHECKPOINT $TOP
    source ./tcl/manual/soc_fp_config.tcl
    source ./tcl/manual/soc_fp_procs.tcl
    setMultiCpuUsage -acquireLicense $ECO_CPUS -localCpu $ECO_CPUS
    setDistributeHost -local

    # Checkpoint phai la netlist ma Tempus da phan tich: ten cell FE_* do
    # Innovus sinh theo tung run, nen chan cua Tempus ma khong co trong
    # database nghia la checkpoint va tempus/reports khong cung mot run.
    set missing {}
    set tempus_nets [dict create]
    foreach item $tempus_viol {
        set pin [lindex $item 0]
        if {[string first / $pin] >= 0} {
            set obj [get_pins -quiet $pin]
        } else {
            set obj [get_ports -quiet $pin]
        }
        if {[sizeof_collection $obj] == 0} {
            lappend missing $pin
            continue
        }
        if {![catch {get_object_name [get_nets -quiet -of_objects $obj]} net] && $net ne ""} {
            dict set tempus_nets [lindex $net 0] 1
        }
    }
    if {[llength $missing] > 0} {
        error "[llength $missing] / [llength $tempus_viol] chan cua Tempus khong co trong\
 $ECO_CHECKPOINT (vd [join [lrange $missing 0 2] {, }]) - checkpoint va\
 tempus/reports khong cung mot run.  Chay lai Quantus + Tempus tren ket qua PnR\
 hien tai, hoac chi dung checkpoint bang ECO_CHECKPOINT."
    }
    set inst_before [llength [dbGet top.insts]]

    # Derate SRAM va dont_touch TRNG dat o KHOI 0 (init_common.tcl).  Dat lai
    # o day - cung gia tri nen vo hai neu checkpoint con giu - de luot optDesign
    # nay khong bao gio chay thieu chung (innovus.tcl, muc (e), dong "Luu y").
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
    catch {report_timing_derate > [file join $ECO_DIR reports timing_derate.rpt]}
    set ro_ptrs [dbGet -e -p top.insts.name u_apb_ascon_u_trng_ro/*]
    if {[llength $ro_ptrs] != 7} {
        error "TRNG ring oscillator: tim thay [llength $ro_ptrs] cell, doi 7"
    }
    foreach ro_ptr $ro_ptrs {
        set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
    }

    # --------------------------------------------------------------------
    # 4. TRICH RC NHU SIGNOFF
    # --------------------------------------------------------------------
    # Cung bo lenh voi quantus.tcl (QUANTUS_EFFORT=high), la engine da sinh ra
    # SPEF ma Tempus doc.  File ghep lop: khong co no Innovus ghep theo vi tri
    # (M1 -> lisd, M2 -> m1, ...).  O checkpoint nay chua co metal fill nen
    # khong can deleteMetalFill -layer Pad nhu quantus.tcl.
    if {$ECO_EXTRACT eq "high"} {
        setExtractRCMode -engine postRoute -effortLevel high -coupled true
        setExtractRCMode -lefTechFileMap $ECO_LAYER_MAP
        set extract_note "IQuantus effortLevel high + [file tail $ECO_LAYER_MAP]\
 (nhu SPEF cua mcu/quantus)"
    } else {
        set extract_note "che do trich cua checkpoint (tQuantus medium, lop ghep theo vi tri)"
        eco_warn "ECO_EXTRACT=flow: Innovus trich RC nhu flow cu nen khong thay vi pham\
 cua Tempus; chi con ECO_DRV_MARGIN ($ECO_DRV_MARGIN) keo no sua"
    }

    # --------------------------------------------------------------------
    # 5. INNOVUS THAY GI TRUOC KHI SUA
    # --------------------------------------------------------------------
    set rpt_pre [file join $ECO_DIR reports timing_pre]
    timeDesign -postRoute -outDir $rpt_pre -prefix pre
    set sum_pre [soc_timing_summary $rpt_pre pre setup]
    set pre_nets [dict create]
    foreach item [soc_drv_violators $rpt_pre pre max_tran] {
        dict set pre_nets [lindex $item 0] 1
    }
    set common 0
    dict for {net _} $tempus_nets {
        if {[dict exists $pre_nets $net]} {
            incr common
        }
    }
    set pre_note [format "truoc ECO, Innovus (%s): setup WNS %s ns, max_tran Real %s net;\
 %d / %d net cua Tempus nam trong so do" \
        $ECO_EXTRACT \
        [expr {[dict exists $sum_pre wns] ? [dict get $sum_pre wns] : "?"}] \
        [expr {[dict exists $sum_pre drv_max_tran] ? [dict get $sum_pre drv_max_tran] : "?"}] \
        $common [dict size $tempus_nets]]
    puts "ECO DRV: $pre_note"
    if {[dict size $pre_nets] == 0} {
        eco_warn "Innovus khong thay net max_tran nao truoc ECO du Tempus bao\
 [llength $tempus_viol] chan - viec sua chi con dua vao ECO_DRV_MARGIN\
 ($ECO_DRV_MARGIN); neu Tempus sau ECO van con vi pham thi tang margin"
    }

    # --------------------------------------------------------------------
    # 6. SUA - dung luot toi uu cua KHOI 14, gioi han DRV siet them margin
    # --------------------------------------------------------------------
    setOptMode -fixCap true -fixTran true -fixFanoutLoad true \
        -setupTargetSlack 0.020 -holdTargetSlack 0.020
    set margin_note "khong margin"
    if {$ECO_DRV_MARGIN > 0.0} {
        if {[catch {setOptMode -drcMargin $ECO_DRV_MARGIN} margin_err]} {
            eco_warn "setOptMode -drcMargin $ECO_DRV_MARGIN bi tu choi ($margin_err) -\
 sua voi gioi han that, khong co khoang du"
        } else {
            set margin_note "drcMargin $ECO_DRV_MARGIN"
        }
    }
    # '-setup -hold -drv' roi soc_fix_cg_hold, KHONG phai '-drv' mot minh: xem
    # ghi chu cua soc_fix_drv (run 2026-09-22 00:31, luot -drv lam hong hold
    # reg2cgate ma khong con buoc nao sua).
    optDesign -postRoute -setup -hold -drv -prefix eco
    soc_fix_cg_hold 0.020
    ecoRoute
    ecoRoute -fix_drc
    # Tra margin ve 0 TRUOC khi do va truoc khi luu: bang DRV va checkpoint
    # phai noi theo gioi han that, va KHOI 15/16 khong duoc thua huong margin.
    if {$margin_note ne "khong margin"} {
        setOptMode -drcMargin 0.0
    }

    # --------------------------------------------------------------------
    # 7. DO LAI, DON DRV CON SOT, KIEM DRC, LUU
    # --------------------------------------------------------------------
    set rpt_eco      [file join $ECO_DIR reports timing_eco]
    set rpt_eco_hold [file join $ECO_DIR reports timing_eco_hold]
    timeDesign -postRoute -outDir $rpt_eco -prefix eco
    soc_fix_drv $rpt_eco eco
    timeDesign -postRoute -hold -outDir $rpt_eco_hold -prefix eco
    soc_reconnect_stdcell_pg eco
    set eco_drc [soc_verify_drc ./verify_rpt/drc_eco.rpt -limit 500000 \
        -allow-nets $SOC_DRC_WAIVE_NETS -allow-types $SOC_DRC_WAIVE_TYPES]
    verifyConnectivity -type all -error 100000 -warning 1000 \
        -report ./verify_rpt/connectivity_eco.rpt

    # LUU TRUOC, KET LUAN SAU (nhu KHOI 14): cong o duoi co the FAIL, nhung
    # trang thai vua toi uu xong van phai con de mo ra xem.
    saveDesign $ECO_OUT

    set sum_eco  [soc_timing_summary $rpt_eco eco setup]
    set sum_hold [soc_timing_summary $rpt_eco_hold eco hold]
    if {[llength $sum_eco] == 0 || [llength $sum_hold] == 0} {
        error "Khong doc duoc bang tom tat timeDesign trong $rpt_eco / $rpt_eco_hold"
    }
    set post_nets [dict create]
    foreach item [soc_drv_violators $rpt_eco eco max_tran] {
        dict set post_nets [lindex $item 0] 1
    }
    set left 0
    dict for {net _} $tempus_nets {
        if {[dict exists $post_nets $net]} {
            incr left
        }
    }
    set inst_after [llength [dbGet top.insts]]

    set bad {}
    foreach {label sum} [list setup $sum_eco hold $sum_hold] {
        if {![dict exists $sum wns]} {
            lappend bad "$label: khong doc duoc WNS"
        } elseif {[dict get $sum wns] < 0} {
            lappend bad "$label WNS [dict get $sum wns] ns"
        }
    }
    foreach key [lsort [dict keys $sum_eco drv_*]] {
        if {[dict get $sum_eco $key] > 0} {
            lappend bad "[string range $key 4 end] Real [dict get $sum_eco $key] net"
        }
    }
    if {$eco_drc > 0} {
        lappend bad "$eco_drc vi pham DRC (verify_rpt/drc_eco.rpt)"
    }

    set lines [list \
        "ECO DRV $TOP: $ECO_CHECKPOINT -> $ECO_OUT.dat, [expr {[clock seconds] - $eco_t0}] s, $ECO_CPUS CPU" \
        "  trich RC : $extract_note" \
        "  Tempus   : [llength $tempus_viol] chan max_transition tren [dict size $tempus_nets] net,\
 xau nhat [format %.3f $tempus_worst] ns, gioi han $tempus_limits ns   ([file tail $ECO_TEMPUS_RPT])" \
        "  $pre_note" \
        "  sua      : optDesign -postRoute -setup -hold -drv ($margin_note) + soc_fix_cg_hold + ecoRoute + soc_fix_drv" \
        [format "  sau ECO, Innovus: setup WNS %s ns, hold WNS %s ns, max_tran Real %s net (%d net cua Tempus con trong do), DRC %d" \
            [expr {[dict exists $sum_eco wns] ? [dict get $sum_eco wns] : "?"}] \
            [expr {[dict exists $sum_hold wns] ? [dict get $sum_hold wns] : "?"}] \
            [expr {[dict exists $sum_eco drv_max_tran] ? [dict get $sum_eco drv_max_tran] : "?"}] \
            $left $eco_drc] \
        "  instance : $inst_before -> $inst_after ([format %+d [expr {$inst_after - $inst_before}]])" \
        "  bao cao  : eco/reports/timing_eco/, timing_eco_hold/, innovus/verify_rpt/drc_eco.rpt, connectivity_eco.rpt"]
    if {[llength $bad] > 0} {
        lappend lines "  KHONG DAT: [join $bad {; }]"
        eco_write_summary $ECO_SUMMARY FAIL $lines
    } else {
        lappend lines \
            "  PASS o day = Innovus sach tren RC nhu signoff.  Ket luan DRV la cua Tempus:" \
            "  tiep theo: make finish (KHOI 15 + 16) -> mcu/conformal -> mcu/quantus -> mcu/tempus"
        eco_write_summary $ECO_SUMMARY PASS $lines
    }

    set fp [open $ECO_SUMMARY r]
    puts "============================================================"
    puts -nonewline [read $fp]
    puts "============================================================"
    close $fp
    if {[llength $bad] > 0} {
        exit 1
    }
} eco_err]} {
    set eco_trace $::errorInfo
    puts "ERROR: eco_drv.tcl: $eco_err"
    puts $eco_trace
    catch {eco_write_summary $ECO_SUMMARY FAIL [list "eco_drv.tcl: $eco_err"]}
    exit 1
}
exit 0
