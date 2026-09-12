############################################################
## Innovus initialization and reviewed macro-floorplan checkpoint
##
## Canonical launch point:
##   cd Asap7/run_workspace/mcu/innovus
##   innovus -files tcl/innovus.tcl
############################################################

set INNOVUS_TCL_DIR [file dirname [file normalize [info script]]]
set INNOVUS_DIR [file dirname $INNOVUS_TCL_DIR]
cd $INNOVUS_DIR

foreach dir {outputs reports verify_rpt saved logs} {
    file mkdir $dir
}

source ./preflight.tcl
source ./tcl/innovus.globals

set init_design_uniquify 1
init_design
setDesignMode -process 7
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7

globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose

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

if {[catch {report_timing_derate > ./reports/sram_derate.rpt} derate_err]} {
    puts "WARNING: report_timing_derate that bai: $derate_err"
}

set_interactive_constraint_modes [all_constraint_modes]
# Can duoi, khong phai so chinh xac: netlist tong hop truoc 2026-09-11 co 18
# clock (8 gated), ban moi co 19 (them CLK_ASCON).  So chinh xac do genus.tcl
# (EXPECTED_CLOCKS) kiem luc tong hop.
if {[sizeof_collection [all_clocks]] < 18} {
    error "Incomplete multi-clock SDC handoff; fewer than 18 clocks are active"
}
set_interactive_constraint_modes {}

source ./tcl/macro_floorplan.tcl

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_floorplan.rpt
report_clocks > ./reports/clocks_floorplan.rpt
report_analysis_views > ./reports/analysis_views.rpt

set FLOORPLAN_DB [file join $INNOVUS_DIR saved \
    [format "%s_floorplan.enc" $TOP]]
saveDesign $FLOORPLAN_DB

puts "============================================================"
puts "INNOVUS MCU PREPARATION CHECKPOINT COMPLETED"
puts " - Database : [file normalize $FLOORPLAN_DB]"
puts " - Macro map: [file normalize ./reports/sram_macro_map.rpt]"
puts "Review macro connectivity, pin access, congestion and PG strategy"
puts "before placement/CTS/route."
puts "============================================================"
