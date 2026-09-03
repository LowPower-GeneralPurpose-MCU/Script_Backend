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
check_top_io_handoff $SYN_NETLIST $SYN_SDC

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
if {![regexp {SYMMETRY[ \t]+[^;\n]*Y} $sram_lef_text]} {
    error "SRAM 4x LEF does not advertise Y symmetry; macro floorplan uses MY orientation"
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
puts " - Macro   : $SRAM_EXPECTED_COUNT x $SRAM_MASTER"
puts "============================================================"
