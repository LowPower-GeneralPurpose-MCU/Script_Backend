############################################################
## Innovus hierarchy-floorplan session
## Based on x_Hierarchy Layout.pdf, pages 25-29
##
## Run from the project root:
##   innovus -stylus -files tcl/innovus_hierFP.tcl
##
## This session intentionally does not place/fix SRAM macros.
############################################################

set USER $::env(USER)
if {[catch {file delete -force /tmp/$USER/innovus_hierfp}]} {}
set auto_file_dir "/tmp/$USER/innovus_hierfp"

foreach d {outputs reports verify_rpt saved} {
    file mkdir $d
}

set init_design_uniquify 1
source ./tcl/innovus.globals
init_design

setDesignMode -process 7

if {![catch {open "/proc/cpuinfo"} cpu_file]} {
    set CORES [regexp -all -line {^processor\s} [read $cpu_file]]
    close $cpu_file
} else {
    set CORES 4
}
if {$CORES < 1} {
    set CORES 1
}
if {$CORES > 24} {
    set CORES 24
}

setMultiCpuUsage -acquireLicense $CORES
setMultiCpuUsage -localCpu $CORES
setDistributeHost -local

proc snap_up {value grid} {
    return [expr {ceil($value / $grid) * $grid}]
}

# Determine the required macro-island area, but leave all macros unplaced.
set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {$SRAM_PTRS eq "" || $SRAM_PTRS eq "0x0"} {
    error "No SRAM instances found for master $SRAM_MASTER"
}
if {[llength $SRAM_PTRS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros, found [llength $SRAM_PTRS]"
}

set first_sram_ptr [lindex $SRAM_PTRS 0]
set SRAM_W [dbGet $first_sram_ptr.cell.size_x]
set SRAM_H [dbGet $first_sram_ptr.cell.size_y]

set SRAM_ISLAND_W [expr {
    $SRAM_COLS * $SRAM_W +
    ($SRAM_COLS - 1) * $SRAM_MACRO_GAP_X
}]
set SRAM_ISLAND_H [expr {
    $SRAM_ROWS * $SRAM_H +
    ($SRAM_ROWS - 1) * $SRAM_MACRO_GAP_Y
}]

# Reserve room for the lower-left SRAM module and for logic to its top/right.
# The hierarchy guides created by proto_design are checked and adjusted later.
set CORE_W [snap_up [expr {
    2.0 * $SRAM_EDGE_GAP_X +
    $SRAM_ISLAND_W +
    $SRAM_ISLAND_ESCAPE_RIGHT +
    $LOGIC_REGION_WIDTH
}] $FLOORPLAN_GRID]

set CORE_H [snap_up [expr {
    2.0 * $SRAM_EDGE_GAP_Y +
    $SRAM_ISLAND_H +
    $SRAM_ISLAND_ESCAPE_TOP +
    $LOGIC_REGION_HEIGHT
}] $FLOORPLAN_GRID]

floorPlan \
    -s $CORE_W $CORE_H \
    $margin_dist $margin_dist $margin_dist $margin_dist

puts "===================================================="
puts "HIERARCHY FLOORPLAN BASE"
puts " - Core              : $CORE_W x $CORE_H um"
puts " - Reserved SRAM area: $SRAM_ISLAND_W x $SRAM_ISLAND_H um"
puts " - SRAM macros       : unplaced in this session"
puts "===================================================="

# Keep clocks ideal in the floorplan/pre-CTS stage.  proto_design is optional
# because it requires the separate invs_ehfs license.
if {$RUN_PROTO_DESIGN} {
    timeDesign -proto -prePlace \
        -outDir ./reports/hierFP_proto_timing

    set_proto_design_mode \
        -timing_aware true \
        -congestion_aware true

    proto_design
} else {
    puts "INFO: proto_design skipped; using deterministic floorplan base."
}

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_hierFP_proto.rpt

puts "===================================================="
puts "HIERARCHY FLOORPLAN CREATED"
puts ""
puts "Manual checks required by the slide:"
puts "  1. Every module utilization must be below 80%."
puts "  2. Target approximately 75% where practical."
puts "  3. Move strongly connected module guides close together."
puts "  4. Keep the SRAM-containing module guide at a side/corner."
puts "  5. Do not manually place SRAM macros in this session."
puts ""
puts "After editing guides in the GUI, run:"
puts "  source ./tcl/finish_hierFP.tcl"
puts "===================================================="
