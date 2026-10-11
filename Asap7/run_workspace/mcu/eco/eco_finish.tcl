############################################################
## Sau ECO: chay lai KHOI 15 (filler + metal fill + verify) va KHOI 16 (xuat
## netlist / SDC / DEF / SPEF / GDS) tren checkpoint cua eco_drv.tcl.
##
##     cd Asap7/run_workspace/mcu/eco && make finish
##
##   vao : ../innovus/saved/top_soc_postRoute_eco.enc.dat   (make all)
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

    set ECO_OUT  [format "./saved/%s_postRoute_eco.enc.dat" $TOP]
    set ECO_CPUS [eco_env ECO_CPUS 1]
    if {![string is integer -strict $ECO_CPUS] || $ECO_CPUS < 1} {
        error "ECO_CPUS phai la so nguyen >= 1, dang la '$ECO_CPUS'"
    }
    if {![file isdirectory $ECO_OUT]} {
        error "Khong co $ECO_OUT - chay 'make all' truoc"
    }
    # Chi di tiep tren mot ECO da PASS: KHOI 16 ghi de outputs/ cua ban truoc.
    set eco_rpt [file join $ECO_DIR reports eco_summary.rpt]
    set eco_verdict ""
    if {[file isfile $eco_rpt]} {
        set fp [open $eco_rpt r]
        gets $fp eco_verdict
        close $fp
    }
    if {[string trim $eco_verdict] ne "PASS"} {
        error "$eco_rpt bao '[string trim $eco_verdict]' - chi chay KHOI 15/16 tren ECO da PASS"
    }

    # Lay hai khoi TRUOC khi mo checkpoint: innovus.tcl hong thi dung ngay.
    set flow_file ./tcl/innovus.tcl
    set block15 [eco_flow_block $flow_file "KHOI 15"]
    set block16 [eco_flow_block $flow_file "KHOI 16"]

    set eco_t0 [clock seconds]
    restoreDesign $ECO_OUT $TOP
    source ./tcl/manual/soc_fp_config.tcl
    source ./tcl/manual/soc_fp_procs.tcl
    setMultiCpuUsage -acquireLicense $ECO_CPUS -localCpu $ECO_CPUS
    setDistributeHost -local

    # soc_block nem loi khi mot lenh trong khoi hong -> roi vao catch ben ngoai.
    uplevel #0 $block15
    uplevel #0 $block16

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
    catch {eco_write_summary $ECO_FINISH_SUMMARY FAIL [list "eco_finish.tcl: $eco_err" \
        "  KHOI 15 khong chay lai duoc tren database dang do: sua nguyen nhan roi 'make finish' lai."]}
    exit 1
}
exit 0
