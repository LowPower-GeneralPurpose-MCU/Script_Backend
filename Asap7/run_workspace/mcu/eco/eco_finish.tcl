############################################################
## Sau ECO: chay lai KHOI 15 (filler + metal fill + verify) va KHOI 16 (xuat
## netlist / SDC / DEF / SPEF / GDS) tren checkpoint cua eco_drv.tcl.
##
##     cd Asap7/run_workspace/mcu/eco && make finish       (sau 'make fillfix')
##
##   vao : checkpoint ghi o dong 'checkpoint ...' cua
##         reports/eco_fillfix_summary.rpt (make fillfix): top_soc_postRoute_ecofill
##         neu buoc do co sua, khong thi top_soc_postRoute_eco cua make all.
##         ECO_FINISH_IN=./saved/<ten>.enc.dat chi dinh thang, bo qua fillfix.
##   ra  : ../innovus/saved/top_soc_prefill.enc.dat, top_soc_final.enc.dat,
##         ../innovus/outputs/top_soc_pnr.* , top_soc.gds   - GHI DE ban truoc ECO
##         reports/eco_finish_summary.rpt   dong dau DONE / FAIL
##
## Hai khoi duoc lay NGUYEN VAN tu innovus/tcl/innovus.tcl (eco_flow_block),
## khong chep lai o day, nen sua flow chinh la buoc nay doi theo.
##
## KHOI 15 khong chay lai duoc tren cung mot database (addFiller / addMetalFill
## lan hai).  Buoc nay hong giua chung thi sua nguyen nhan roi 'make finish'
## lai: no luon mo lai tu checkpoint ECO, khong tu database dang do.
############################################################

set ECO_DIR [file dirname [file normalize [info script]]]
source [file join $ECO_DIR eco_common.tcl]
eco_require_no_design eco_finish.tcl

set ECO_FINISH_SUMMARY [file join $ECO_DIR reports eco_finish_summary.rpt]

if {[catch {
    if {![file isfile ./tcl/project_config.tcl]} {
        error "Khong thay ./tcl/project_config.tcl - phai chay tu thu muc mcu/innovus\
 (cd mcu/eco && make finish)"
    }
    source ./tcl/project_config.tcl
    foreach dir {logs reports} {
        file mkdir [file join $ECO_DIR $dir]
    }
    file delete -force $ECO_FINISH_SUMMARY

    set ECO_CPUS [eco_env ECO_CPUS 1]
    if {![string is integer -strict $ECO_CPUS] || $ECO_CPUS < 1} {
        error "ECO_CPUS phai la so nguyen >= 1, dang la '$ECO_CPUS'"
    }
    # Chi di tiep tren mot ECO da PASS: KHOI 16 ghi de outputs/ cua ban truoc.
    set eco_rpt [file join $ECO_DIR reports eco_summary.rpt]
    if {[eco_summary_verdict $eco_rpt] ne "PASS"} {
        error "$eco_rpt bao '[eco_summary_verdict $eco_rpt]' - chi chay KHOI 15/16 tren ECO da PASS"
    }
    # Checkpoint dau vao la cua 'make fillfix' (dong 'checkpoint ...' trong file
    # tom tat cua no): buoc do do DRV khi da co metal fill va sua truoc.  Run
    # 2026-10-12 chay thang tu checkpoint cua 'make all' va dung o cong timing
    # sau fill hai lan lien (47 roi 64 net max_tran).  ECO_FINISH_IN=<checkpoint>
    # bo qua buoc do co chu dich.
    set fill_rpt [file join $ECO_DIR reports eco_fillfix_summary.rpt]
    set ECO_OUT  [eco_env ECO_FINISH_IN ""]
    if {$ECO_OUT ne ""} {
        eco_warn "ECO_FINISH_IN=$ECO_OUT - khong dung ket luan cua 'make fillfix'"
    } else {
        if {[eco_summary_verdict $fill_rpt] ne "PASS"} {
            error "$fill_rpt bao '[eco_summary_verdict $fill_rpt]' - chay 'make fillfix'\
 truoc (do va sua max_transition khi da co metal fill), PASS roi moi 'make finish'"
        }
        set fp [open $fill_rpt r]
        while {[gets $fp line] >= 0} {
            if {[regexp {^checkpoint\s+(\S+)\s*$} $line -> ECO_OUT]} {
                break
            }
        }
        close $fp
        if {$ECO_OUT eq ""} {
            error "$fill_rpt khong co dong 'checkpoint <duong dan>'"
        }
    }
    if {![file isdirectory $ECO_OUT]} {
        error "Khong co $ECO_OUT - chay 'make all' roi 'make fillfix' truoc"
    }
    # Buoc nay GHI DE outputs/ cua Innovus: checkpoint dau vao phai duoc ghi sau
    # checkpoint cuoi KHOI 14 cua lan P&R hien tai (eco_require_fresh).
    eco_require_fresh "checkpoint dau vao" $ECO_OUT "checkpoint cuoi KHOI 14" \
        [format "./saved/%s_postRoute.enc.dat" $TOP] \
        "Innovus da chay lai sau lan ECO do: 'make finish' se ghi de outputs/ bang thiet ke cu.
  Chay lai 'make all' -> 'make fillfix' tren ket qua Innovus moi."

    # Lay hai khoi TRUOC khi mo checkpoint: innovus.tcl hong thi dung ngay.
    set flow_file ./tcl/innovus.tcl
    set block15 [eco_flow_block $flow_file "KHOI 15"]
    set block16 [eco_flow_block $flow_file "KHOI 16"]

    # KHOI 16 (soc_require_sram_lef_clean) can ::MFG_GRID, ::KNOWN_SITES va cac
    # proc doc LEF cua tcl/check_handoff.tcl.  O flow chinh chung do preflight.tcl
    # (KHOI 0) dat; buoc nay khong chay KHOI 0 nen run 2026-10-13 di het KHOI 15
    # roi moi dung o "thieu ::MFG_GRID".  Dat lai dung cach preflight.tcl dat
    # (dong 35-50), KHONG source ca file do: no con ghi de outputs/*.innovus.sdc.
    source ./tcl/check_handoff.tcl
    set tech_lef_text [read_binary_file $TECH_LEF "tech LEF"]
    if {![regexp {MANUFACTURINGGRID[ \t]+([0-9.]+)} $tech_lef_text -> MFG_GRID]} {
        error "Tech LEF khong khai MANUFACTURINGGRID: [file normalize $TECH_LEF]"
    }
    set KNOWN_SITES [lef_defined_sites $tech_lef_text]
    foreach cell_lef $CELL_LEFS {
        set KNOWN_SITES [concat $KNOWN_SITES \
            [lef_defined_sites [read_binary_file $cell_lef "cell LEF"]]]
    }
    set KNOWN_SITES [lsort -unique $KNOWN_SITES]
    if {[llength $KNOWN_SITES] == 0} {
        error "Khong tim thay dinh nghia SITE nao trong tech LEF hay CELL_LEFS"
    }
    unset tech_lef_text

    set eco_t0 [clock seconds]
    set eco_stage "mo checkpoint"
    restoreDesign $ECO_OUT $TOP
    source ./tcl/manual/soc_fp_config.tcl
    source ./tcl/manual/soc_fp_procs.tcl
    setMultiCpuUsage -acquireLicense $ECO_CPUS -localCpu $ECO_CPUS
    setDistributeHost -local
    eco_session_constraints
    # Cong LEF SRAM cua KHOI 16 chi doc file: goi luon o day de hong thi hong
    # trong phut dau, khong phai sau 17 phut filler + metal fill.
    set eco_stage "kiem LEF SRAM (cong cua KHOI 16, goi som)"
    soc_require_sram_lef_clean

    # soc_block nem loi khi mot lenh trong khoi hong -> roi vao catch ben ngoai.
    set eco_stage "KHOI 15"
    uplevel #0 $block15
    set eco_stage "KHOI 16"
    uplevel #0 $block16
    set eco_stage "tom tat"

    set lines [list \
        "ECO finish $TOP: $ECO_OUT -> KHOI 15 + KHOI 16, [expr {[clock seconds] - $eco_t0}] s, $ECO_CPUS CPU"]
    foreach {label dir mode} [list setup ./reports/timing_final setup hold ./reports/timing_final_hold hold] {
        set sum [soc_timing_summary $dir final $mode]
        set drv {}
        foreach key [lsort [dict keys $sum drv_*]] {
            lappend drv "[string range $key 4 end] Real [dict get $sum $key]"
        }
        lappend lines [format "  final %-5s: WNS %s ns, TNS %s ns, %s duong vi pham   %s" $label \
            [expr {[dict exists $sum wns]  ? [dict get $sum wns]  : "?"}] \
            [expr {[dict exists $sum tns]  ? [dict get $sum tns]  : "?"}] \
            [expr {[dict exists $sum viol] ? [dict get $sum viol] : "?"}] \
            [join $drv {, }]]
    }
    lappend lines \
        "  da ghi de: saved/${TOP}_prefill.enc.dat, saved/${TOP}_final.enc.dat, outputs/${TOP}_pnr.{v,sdc,def}, outputs/${TOP}.gds" \
        "  tiep theo (netlist da doi, moi ket qua sau PnR cu deu het han):" \
        "    cd ../conformal && make all     LEC syn vs PnR" \
        "    cd ../quantus   && make all QUANTUS_EFFORT=high" \
        "    cd ../tempus    && make all     max_transition trong all_violators.rpt phai het" \
        "    cd ../voltus    && make all"
    eco_write_summary $ECO_FINISH_SUMMARY DONE $lines

    set fp [open $ECO_FINISH_SUMMARY r]
    puts "============================================================"
    puts -nonewline [read $fp]
    puts "============================================================"
    close $fp
} eco_err]} {
    set eco_trace $::errorInfo
    puts "ERROR: eco_finish.tcl: $eco_err"
    puts $eco_trace
    # Noi ro DUNG O DAU.  Truoc day moi loi deu kem cau "KHOI 15 khong chay lai
    # duoc..." nen run 2026-10-12 doc nhu KHOI 15 hong, trong khi filler, metal
    # fill, DRC va mat do deu qua: thu chan la cong timing dau KHOI 16, doc
    # bang timeDesign do SAU fill.
    if {![info exists eco_stage]} {
        set eco_stage "kiem tra dau vao"
    }
    set eco_fail [list "eco_finish.tcl, dung o '$eco_stage': $eco_err"]
    switch -- $eco_stage {
        "KHOI 15" {
            lappend eco_fail \
                "  KHOI 15 khong chay lai duoc tren database dang do: sua nguyen nhan roi 'make finish' lai (no luon mo lai tu checkpoint)." \
                "  saved/*_prefill.enc.dat / *_final.enc.dat co the da bi ghi de boi lan chay hong nay."
        }
        "KHOI 16" {
            lappend eco_fail \
                "  KHOI 15 (filler, metal fill, DRC, mat do) DA XONG; thu chan la cong cua KHOI 16." \
                "  Neu dong tren la DRV / WNS cua 'final': do la timing SAU metal fill -> 'make fillfix' roi 'make finish' lai." \
                "  saved/*_final.enc.dat gio la thiet ke KHONG DAT nay; innovus/outputs/ chua chac da duoc ghi lai - dung chay conformal/quantus/tempus."
        }
    }
    catch {eco_write_summary $ECO_FINISH_SUMMARY FAIL $eco_fail}
    exit 1
}
exit 0
