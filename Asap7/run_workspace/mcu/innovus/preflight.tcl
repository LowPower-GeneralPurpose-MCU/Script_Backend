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
        $SYN_NETLIST $SYN_SDC]]

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

check_mapped_sram_count \
    $SYN_NETLIST $SRAM_MASTER $SRAM_EXPECTED_COUNT

set sram_lib_text [read_binary_file $SRAM_LIB "SRAM Liberty"]
if {![regexp [format {cell[ \t\r\n]*\([ \t\r\n]*%s[ \t\r\n]*\)} \
    $SRAM_MASTER] $sram_lib_text]} {
    error "SRAM Liberty does not contain cell $SRAM_MASTER"
}

set sram_lef_text [read_binary_file $SRAM_LEF "SRAM 4x LEF"]
if {![regexp [format {MACRO[ \t]+%s} $SRAM_MASTER] $sram_lef_text] ||
    ![regexp {SIZE[ \t]+121\.392[ \t]+BY[ \t]+172\.8} $sram_lef_text]} {
    error "SRAM 4x LEF master or geometry is unexpected"
}
if {[file size $SRAM_GDS] == 0} {
    error "SRAM GDS is empty: [file normalize $SRAM_GDS]"
}

prepare_innovus_sdc \
    $SYN_SDC \
    $INNOVUS_SDC \
    $INNOVUS_PATH_GROUPS \
    $SIGNAL_MAX_TRANSITION_NS

puts "============================================================"
puts "INNOVUS PRECHECK PASSED"
puts " - Netlist : [file normalize $SYN_NETLIST]"
puts " - SDC     : [file normalize $INNOVUS_SDC]"
puts " - Macro   : $SRAM_EXPECTED_COUNT x $SRAM_MASTER"
puts "============================================================"
