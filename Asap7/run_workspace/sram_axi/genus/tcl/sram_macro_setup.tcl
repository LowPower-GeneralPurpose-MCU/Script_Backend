############################################################
## ASAP7 SRAM hard-macro setup for Genus
############################################################

# The parent genus.tcl defines ASAP7 first.
if {![info exists ASAP7]} {
    set ASAP7 "/home/user1/Desktop/asap7"
}

set SRAM_ROOT           "${ASAP7}/asap7_sram_0p0"
set SRAM_MASTER         "srambank_256x4x32_6t122"
set SRAM_EXPECTED_COUNT 16

# Genus needs the Liberty timing/area model.
set SRAM_LIB \
    "${SRAM_ROOT}/generated/LIB/${SRAM_MASTER}.lib"

# These are not read by Genus, but keeping their paths here makes
# the Genus and Innovus configurations use exactly the same master.
set SRAM_LEF \
    "${SRAM_ROOT}/generated/LEF/4xLEF/${SRAM_MASTER}.lef.4x.lef"

set SRAM_GDS \
    "${SRAM_ROOT}/gds/srambank_32b.gds"

# Simulation-only functional model. Do not read it in genus.tcl.
set SRAM_SIM_VERILOG \
    "${SRAM_ROOT}/generated/verilog/${SRAM_MASTER}.v"

if {![file exists $SRAM_LIB]} {
    error "Missing SRAM Liberty: [file normalize $SRAM_LIB]"
}

puts "===================================================="
puts "GENUS SRAM MACRO SETUP"
puts " - Master         : $SRAM_MASTER"
puts " - Expected count : $SRAM_EXPECTED_COUNT"
puts " - Liberty        : [file normalize $SRAM_LIB]"
puts "===================================================="
