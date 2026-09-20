############################################################
## Phan init dung chung cho moi session Innovus cua MCU
##   - tcl/innovus.tcl         (floorplan tu dong)
##   - tcl/manual/*.tcl        (floorplan bang tay theo slide)
## Goi tu thu muc mcu/innovus, sau khi da cd vao do.
############################################################

foreach dir {outputs reports verify_rpt saved logs} {
    file mkdir $dir
}

source ./preflight.tcl
source ./tcl/innovus.globals

set init_design_uniquify 1
init_design
setDesignMode -process 7
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7

# ------------------------------------------------------------------------
# CHE DO PHAN TICH - dat NGAY O DAY, khong doi den KHOI 13
# ------------------------------------------------------------------------
# Truoc 2026-09-20 dong nay nam trong KHOI 13 (routeDesign).  Doc innovus.log
# cua run 2026-09-20: moi header timing truoc dong '<CMD> setAnalysisMode'
# (line 97801) deu ghi "Analysis Mode: MMMC Non-OCV", tuc la
# place_opt_design, clock_opt_design VA optDesign -postCTS -setup -hold deu
# chay khong OCV, khong CPPR.  Hai hau qua:
#   - hold-fix sau CTS khong duoc tru phan clock dung chung (CPPR).  Duong
#     hold xau nhat cua run nay co CPPR Adjustment 0.400 ns o postRoute; o
#     postCTS khoan do bi tinh thanh thieu -> optDesign chen buffer thua.
#   - con so postCTS va postRoute khac he quy chieu nen khong so sanh duoc.
# Dat truoc placement thi ca flow dung mot che do.
setAnalysisMode -analysisType onChipVariation -cppr both

# Glitch: run 2026-09-20 bao IMPOPT-7320 "Glitch fixing has been disabled since
# glitch reporting is disabled".  Bat bao cao thi optDesign moi duoc phep sua,
# va co so lieu de doc.
if {[catch {setSIMode -enable_glitch_report true} si_err]} {
    puts "WARNING: setSIMode -enable_glitch_report: $si_err"
}

# License hien tai cho toi da 8 CPU (log Risc_V).
set MCU_CPUS 1
if {![catch {open "/proc/cpuinfo" r} cpu_fp]} {
    set MCU_CPUS [regexp -all -line {^processor\s*:} [read $cpu_fp]]
    close $cpu_fp
}
if {[info exists ::env(INNOVUS_CPUS)] && $::env(INNOVUS_CPUS) ne ""} {
    set MCU_CPUS $::env(INNOVUS_CPUS)
}
if {![string is integer -strict $MCU_CPUS] || $MCU_CPUS < 1} {
    set MCU_CPUS 1
}
if {$MCU_CPUS > 8} {
    set MCU_CPUS 8
}
setMultiCpuUsage -acquireLicense $MCU_CPUS -localCpu $MCU_CPUS
setDistributeHost -local

globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose
globalNetConnect VDD -type tiehi -inst * -verbose
globalNetConnect VSS -type tielo -inst * -verbose

# ------------------------------------------------------------------------
# DERATE CHO MACRO SRAM - phai khop khoi 9c cua Genus
# ------------------------------------------------------------------------
# Ca ba library_set tro toi cung hai file .lib SRAM (xem project_config.tcl),
# nen 84 macro co dung mot bo so tre o ca ba goc.  O SS setup lac quan, o FF
# hold lac quan.  Genus da derate luc tong hop; neu Innovus khong lam lai thi
# tu sau init_design moi phan tich deu quay ve lac quan - va hold sau CTS la
# cho dieu do nguy hiem nhat.
#
# SRAM_DERATE_SS / SRAM_DERATE_FF den tu genus/rtl/flow/project_config.tcl,
# cung mot nguon voi Genus, de hai ben khong troi ra khac nhau.

set SRAM_DERATE_INSTS [get_cells -hierarchical -filter \
    "ref_name =~ ${SRAM_MASTER}* || ref_name =~ ${SRAM_TAG_MASTER}*"]
set sram_derate_count    [sizeof_collection $SRAM_DERATE_INSTS]
set sram_derate_expected [expr {$SRAM_EXPECTED_COUNT + $SRAM_TAG_EXPECTED_COUNT}]

if {$sram_derate_count != $sram_derate_expected} {
    error "Derate SRAM: tim thay $sram_derate_count macro, doi $sram_derate_expected"
}

if {[lsearch -exact $MCU_SETUP_VIEWS view_ss] >= 0} {
    set_timing_derate -delay_corner dc_ss -late -cell_delay -cell_check \
        $SRAM_DERATE_SS $SRAM_DERATE_INSTS
    puts "Derate SRAM: $sram_derate_count macro, dc_ss late x$SRAM_DERATE_SS"
} else {
    puts "WARNING: khong co view_ss - bo derate setup cho macro SRAM"
}

if {[lsearch -exact $MCU_HOLD_VIEWS view_ff] >= 0} {
    set_timing_derate -delay_corner dc_ff -early -cell_delay -cell_check \
        $SRAM_DERATE_FF $SRAM_DERATE_INSTS
    puts "Derate SRAM: $sram_derate_count macro, dc_ff early x$SRAM_DERATE_FF"
} else {
    puts "WARNING: ===================================================="
    puts "WARNING: khong co view_ff - hold se chay voi min delay cua goc"
    puts "WARNING: danh dinh cho ca 84 macro SRAM.  Khong dung de sign-off."
    puts "WARNING: ===================================================="
}

# ------------------------------------------------------------------------
# DERATE CHUNG (OCV) CHO STD CELL - MAC DINH TAT
# ------------------------------------------------------------------------
# Doc reports/sram_derate.rpt cua run 2026-09-20: file chi co muc "Cell (leaf)"
# cua 84 macro SRAM, KHONG co dong derate mac dinh nao.  Tuc la
# setAnalysisMode -analysisType onChipVariation dang bat nhung bien thien
# tren chip cua std cell bang 0: OCV o day chi con nghia la "duoc tru CPPR",
# va CPPR tru di mot khoan bi quan CHUA TUNG duoc cong vao.
# Duong hold xau nhat cua run 2026-09-20 duoc tru CPPR 0.400 ns va con lai
# +0.021 ns - tuc gan het margin den tu chinh khoan tru do.
#
# Vi sao mac dinh de 1.0 (tat): bat len la moi con so timing doi, va hold chi
# con 21 ps nen gan nhu chac chan se am tro lai -> phai chay lai ca luot
# optDesign.  Do la viec phai lam CO CHU DICH, khong phai thu lang le doi.
#
# Khi nao bat: truoc khi goi ket qua nay la "signoff".  So thuong dung cho 7nm
# khong co bang AOCV la +/-5%:
#     export MCU_OCV_DERATE_LATE=1.05  MCU_OCV_DERATE_EARLY=0.95
# Va khi bat thi phai them DUNG bo so do vao genus/tcl/genus.tcl - Genus hien
# cung khong co derate chung (grep 'set_timing_derate' chi ra 2 dong SRAM).
set MCU_OCV_DERATE_LATE  1.0
set MCU_OCV_DERATE_EARLY 1.0
foreach {ocv_var ocv_name} {MCU_OCV_DERATE_LATE late MCU_OCV_DERATE_EARLY early} {
    if {[info exists ::env($ocv_var)] && $::env($ocv_var) ne ""} {
        if {![string is double -strict $::env($ocv_var)] || $::env($ocv_var) <= 0} {
            error "$ocv_var phai la so duong, dang la '$::env($ocv_var)'"
        }
        set $ocv_var [expr {double($::env($ocv_var))}]
    }
}
if {$MCU_OCV_DERATE_LATE != 1.0 || $MCU_OCV_DERATE_EARLY != 1.0} {
    set_timing_derate -late  -cell_delay -net_delay -cell_check $MCU_OCV_DERATE_LATE
    set_timing_derate -early -cell_delay -net_delay -cell_check $MCU_OCV_DERATE_EARLY
    puts "Derate OCV chung: late x$MCU_OCV_DERATE_LATE / early x$MCU_OCV_DERATE_EARLY"
    puts "  -> nho dat CUNG bo so nay ben Genus truoc khi so sanh hai ben."
} else {
    puts "WARNING: ===================================================="
    puts "WARNING: KHONG co derate OCV chung cho std cell (dang de 1.0)."
    puts "WARNING: setAnalysisMode dang o che do onChipVariation nhung bien"
    puts "WARNING: thien tren chip bang 0, trong khi CPPR VAN duoc tru."
    puts "WARNING: Ket qua timing la LAC QUAN - khong dung de sign-off."
    puts "WARNING: Bat: export MCU_OCV_DERATE_LATE=1.05 MCU_OCV_DERATE_EARLY=0.95"
    puts "WARNING: ===================================================="
}

if {[catch {report_timing_derate > ./reports/sram_derate.rpt} derate_err]} {
    puts "WARNING: report_timing_derate that bai: $derate_err"
}

set_interactive_constraint_modes [all_constraint_modes]
# Slide 36: output SRAM chi keo 1 tai, de buffer nam sat macro.
set_max_fanout 1 [get_pins -of_objects $SRAM_DERATE_INSTS -filter "direction == out"]

# genus.tcl EXPECTED_CLOCKS = 15 tu 2026-09-11 (CLK_SYS, CLK_TCK,
# CLK_SDRAM_OUT + 12 gated).  Nguong cu 18 thuoc netlist nhieu clock truoc do.
if {[sizeof_collection [all_clocks]] < 15} {
    error "Incomplete multi-clock SDC handoff; fewer than 15 clocks are active"
}
set_interactive_constraint_modes {}

# ------------------------------------------------------------------------
# TRNG ring oscillator: 6 INVx1 + 1 NAND2x1 la vong to hop co chu y.
# Genus da preserve; Innovus can dont_touch rieng, neu khong optDesign co the
# resize/buffer vong va doi tan so (hoac pha vong).
# ------------------------------------------------------------------------
set MCU_RO_PTRS [dbGet -p top.insts.name u_apb_ascon_u_trng_ro/*]
if {$MCU_RO_PTRS eq "0x0"} {
    set MCU_RO_PTRS {}
}
if {[llength $MCU_RO_PTRS] != 7} {
    error "TRNG ring oscillator: tim thay [llength $MCU_RO_PTRS] cell, doi 7"
}
foreach ro_ptr $MCU_RO_PTRS {
    set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
}
puts "TRNG RO: dont_touch tren [llength $MCU_RO_PTRS] cell"
