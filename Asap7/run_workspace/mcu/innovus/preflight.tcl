############################################################
## Plain-Tcl Genus-to-Innovus handoff preflight
## Run with: tclsh preflight.tcl
############################################################

set INNOVUS_DIR [file dirname [file normalize [info script]]]
cd $INNOVUS_DIR

source ./tcl/project_config.tcl
source ./tcl/check_handoff.tcl
source ./tcl/prepare_innovus_sdc.tcl

set required_files [concat \
    $STD_LIBS \
    $CELL_LEFS \
    [list $TECH_LEF $QRC_FILE $SRAM_LIB $SRAM_LEF $SRAM_GDS \
        $SRAM_TAG_LIB $SRAM_TAG_LEF $SYN_NETLIST $SYN_SDC]]

set missing {}
foreach required $required_files {
    if {![file isfile $required]} {
        lappend missing $required
    }
}
if {[llength $missing] > 0} {
    puts stderr "INNOVUS PRECHECK FAILED: missing inputs:"
    foreach path $missing {
        puts stderr " - [file normalize $path]"
    }
    error "Run Genus first and verify ASAP7_ROOT"
}

check_top_io_handoff $SYN_NETLIST $SYN_SDC

# MANUFACTURINGGRID va danh sach SITE hop le, doc thang tu LEF dang dung - de
# check khong troi ra khi doi PDK.  Tech LEF ASAP7 khong dinh nghia SITE nao,
# site 'asap7sc7p5t' nam trong LEF cell.
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
puts "Manufacturing grid $MFG_GRID um | SITE: $KNOWN_SITES"

# Hai master SRAM: 80 x 256x4x32 (RAM, cache data, TCM) + 4 x 128x4x20 (tag).
# Kich thuoc LEF duoc ghim vi floorplan (tcl/manual/soc_fp_procs.tcl) tinh luoi tu chung.
foreach {master expected lib lef size_pattern size_text} [list \
    $SRAM_MASTER     $SRAM_EXPECTED_COUNT     $SRAM_LIB     $SRAM_LEF \
        {SIZE[ \t]+121\.392[ \t]+BY[ \t]+172\.8} {121.392 BY 172.8} \
    $SRAM_TAG_MASTER $SRAM_TAG_EXPECTED_COUNT $SRAM_TAG_LIB $SRAM_TAG_LEF \
        {SIZE[ \t]+64[ \t]+BY[ \t]+120\.96} {64 BY 120.96}] {
    check_mapped_sram_count $SYN_NETLIST $master $expected

    set lib_text [read_binary_file $lib "SRAM Liberty"]
    if {![regexp [format {cell[ \t\r\n]*\([ \t\r\n]*%s[ \t\r\n]*\)} $master] $lib_text]} {
        error "SRAM Liberty does not contain cell $master"
    }

    set lef_text [read_binary_file $lef "SRAM 4x LEF"]
    # Bao loi phai noi RO file nao va doc duoc gi.  Run 2026-09-18 16:59 chet o
    # day voi moi mot dong "master or geometry is unexpected" - khong biet la
    # sai ten macro, sai duong dan, hay tro nham ban 1x.
    if {![regexp [format {MACRO[ \t]+%s} $master] $lef_text]} {
        set macros {}
        foreach m [regexp -all -inline -line {^MACRO[ \t]+(\S+)} $lef_text] {
            if {![string match "MACRO*" $m]} {
                lappend macros $m
            }
        }
        error "LEF [file normalize $lef] khong chua MACRO $master.\
 MACRO co trong file: [expr {[llength $macros] ? $macros : {(khong co)}}].\
 Kiem tra ASAP7_SRAM_LEF_FILE / ASAP7_SRAM_TAG_LEF_FILE."
    }
    if {![regexp $size_pattern $lef_text]} {
        set found {}
        foreach m [regexp -all -inline -line {^[ \t]*SIZE[ \t]+[^;]*} $lef_text] {
            lappend found [string trim $m]
        }
        error "LEF [file normalize $lef]: kich thuoc macro khac voi floorplan.\
 Doi 'SIZE $size_text', doc duoc: [expr {[llength $found] ? [join [lrange $found 0 2] { | }] : {(khong co dong SIZE nao)}}].\
 Thuong la tro nham ban 1x (SIZE nho di 4 lan) thay vi thu muc 4xLEF, hoac\
 nham file macro khac."
    }
    if {![regexp {SYMMETRY[ \t]+[^;\n]*Y} $lef_text]} {
        error "SRAM 4x LEF of $master does not advertise Y symmetry; macro floorplan uses MY orientation"
    }

    # Toa do lech grid / SITE khong ton tai: CANH BAO o day (van chay duoc het
    # PnR), CHAN o KHOI 16 - LEF la nguon hinh SRAM duy nhat cho streamOut.
    lassign [check_lef_grid_site $lef_text $MFG_GRID $KNOWN_SITES] \
        lef_offgrid lef_bad_sites
    if {$lef_offgrid > 0 || [llength $lef_bad_sites] > 0} {
        puts "WARNING: ===================================================="
        puts "WARNING: [file tail $lef]"
        if {$lef_offgrid > 0} {
            puts "WARNING:   $lef_offgrid toa do KHONG tren manufacturing grid $MFG_GRID"
            puts "WARNING:   -> init_design se bao IMPLF-82, sroute bao IMPSR-552"
        }
        if {[llength $lef_bad_sites] > 0} {
            puts "WARNING:   tham chieu SITE khong duoc dinh nghia: $lef_bad_sites"
            puts "WARNING:   -> init_design se bao IMPLF-40"
        }
        puts "WARNING: Sua truoc khi xuat GDS:"
        puts "WARNING:   python3 scripts/fix_sram_lef.py [file normalize $lef] \\"
        puts "WARNING:       --fix -o <file>.fixed.lef --site [lindex $lef_bad_sites 0]=[lindex $KNOWN_SITES 0]"
        puts "WARNING:   roi export ASAP7_SRAM_TAG_LEF_FILE=<file>.fixed.lef (hoac"
        puts "WARNING:   ASAP7_SRAM_LEF_FILE) va chay lai tu KHOI 0."
        puts "WARNING: ===================================================="
    } else {
        puts "[file tail $lef]: toa do tren grid, SITE hop le"
    }
}
if {[file size $SRAM_GDS] == 0} {
    error "SRAM GDS is empty: [file normalize $SRAM_GDS]"
}

# No max-transition override.  prepare_innovus_sdc rewrites the first number
# of EVERY set_max_transition command it sees, which would flatten the
# per-domain values the SDC now sets (100 ps on CLK_CORE/CLK_CPU, 150 ps on
# the AXI group, 250 ps on the peripheral domains) back to a single 300 ps.
# The unit converter already scales the SDC ps values into ns correctly, so
# the override is redundant as well as harmful.  SIGNAL_MAX_TRANSITION_NS in
# project_config.tcl still documents the 320 ps SRAM macro pin limit.
prepare_innovus_sdc \
    $SYN_SDC \
    $INNOVUS_SDC \
    $INNOVUS_PATH_GROUPS

puts "============================================================"
puts "INNOVUS PRECHECK PASSED"
puts " - Netlist : [file normalize $SYN_NETLIST]"
puts " - SDC     : [file normalize $INNOVUS_SDC]"
puts " - Macro   : $SRAM_EXPECTED_COUNT x $SRAM_MASTER + $SRAM_TAG_EXPECTED_COUNT x $SRAM_TAG_MASTER"
puts "============================================================"
