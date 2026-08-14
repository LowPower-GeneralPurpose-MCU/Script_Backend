############################################################
## AXI pin planning on the four core edges
##
## Macro-slide rules:
##   - favor Macro-to-Port connectivity
##   - keep signal escape directed toward the core
##   - do not force top-level ports through SRAM macro obstructions
############################################################

proc make_bus_pins {base msb lsb} {
    set result {}
    for {set index $msb} {$index >= $lsb} {incr index -1} {
        lappend result [format {%s[%d]} $base $index]
    }
    return $result
}

proc keep_existing_ports {pin_list} {
    set result {}
    foreach pin $pin_list {
        if {[llength [get_ports -quiet $pin]] > 0} {
            lappend result $pin
        } else {
            puts "WARNING: top-level port not found; skip pin $pin"
        }
    }
    return $result
}

set TOP_PINS [concat \
    [list clk rst_n] \
    [make_bus_pins s_axi_awid      4 0] \
    [make_bus_pins s_axi_awaddr   31 0] \
    [make_bus_pins s_axi_awlen     7 0] \
    [make_bus_pins s_axi_awsize    2 0] \
    [make_bus_pins s_axi_awburst   1 0] \
    [list s_axi_awlock] \
    [make_bus_pins s_axi_awcache   3 0] \
    [make_bus_pins s_axi_awprot    2 0] \
    [make_bus_pins s_axi_awqos     3 0] \
    [make_bus_pins s_axi_awregion  3 0] \
    [list s_axi_awvalid s_axi_awready] \
]

set RIGHT_PINS [concat \
    [make_bus_pins s_axi_wdata    31 0] \
    [make_bus_pins s_axi_wstrb     3 0] \
    [list s_axi_wlast s_axi_wvalid s_axi_wready] \
    [make_bus_pins s_axi_bid       4 0] \
    [make_bus_pins s_axi_bresp     1 0] \
    [list s_axi_bvalid s_axi_bready] \
]

set LEFT_PINS [concat \
    [make_bus_pins s_axi_arid      4 0] \
    [make_bus_pins s_axi_araddr   31 0] \
    [make_bus_pins s_axi_arlen     7 0] \
    [make_bus_pins s_axi_arsize    2 0] \
    [make_bus_pins s_axi_arburst   1 0] \
    [list s_axi_arlock] \
    [make_bus_pins s_axi_arcache   3 0] \
    [make_bus_pins s_axi_arprot    2 0] \
    [make_bus_pins s_axi_arqos     3 0] \
    [make_bus_pins s_axi_arregion  3 0] \
    [list s_axi_arvalid s_axi_arready] \
]

set BOTTOM_PINS [concat \
    [make_bus_pins s_axi_rid       4 0] \
    [make_bus_pins s_axi_rdata    31 0] \
    [make_bus_pins s_axi_rresp     1 0] \
    [list s_axi_rlast s_axi_rvalid s_axi_rready] \
]

set TOP_PINS    [keep_existing_ports $TOP_PINS]
set RIGHT_PINS  [keep_existing_ports $RIGHT_PINS]
set LEFT_PINS   [keep_existing_ports $LEFT_PINS]
set BOTTOM_PINS [keep_existing_ports $BOTTOM_PINS]

# The SRAM island occupies the complete left edge on M6/M7.  Cadence editPin
# honors macro OBS/routing blockages when -fixOverlap is enabled, so requesting
# LEFT pins there only relocates them into the three SRAM row gaps and the
# short channel above the island.  Put the AR address/control group on TOP,
# where it has direct legal access to the logic channel above the SRAMs.
set TOP_PINS [concat $TOP_PINS $LEFT_PINS]
set LEFT_PINS {}

# Do not assign one port to more than one edge.
set assigned_ports {}
foreach pin [concat $TOP_PINS $RIGHT_PINS $LEFT_PINS $BOTTOM_PINS] {
    if {[lsearch -exact $assigned_ports $pin] >= 0} {
        error "Top-level pin $pin is assigned to more than one side"
    }
    lappend assigned_ports $pin
}

set pin_core_llx [dbGet top.fPlan.coreBox_llx]
set pin_core_lly [dbGet top.fPlan.coreBox_lly]
set pin_core_urx [dbGet top.fPlan.coreBox_urx]
set pin_core_ury [dbGet top.fPlan.coreBox_ury]

set PIN_WIDTH 0.128
set PIN_DEPTH 0.288
set PIN_EDGE_CLEARANCE 8.000

if {![info exists SRAM_NO_MESH_URX]} {
    error "Missing SRAM_NO_MESH_URX before top-level pin assignment"
}

if {[expr {$pin_core_urx - $pin_core_llx}] <= 2.0 * $PIN_EDGE_CLEARANCE} {
    error "Core width is too small for the requested pin edge clearance"
}
if {[expr {$pin_core_ury - $pin_core_lly}] <= 2.0 * $PIN_EDGE_CLEARANCE} {
    error "Core height is too small for the requested pin edge clearance"
}

set top_start [list \
    [expr {$pin_core_llx + $PIN_EDGE_CLEARANCE}] $pin_core_ury]
set top_end [list \
    [expr {$pin_core_urx - $PIN_EDGE_CLEARANCE}] $pin_core_ury]

set right_start [list \
    $pin_core_urx [expr {$pin_core_ury - $PIN_EDGE_CLEARANCE}]]
set right_end [list \
    $pin_core_urx [expr {$pin_core_lly + $PIN_EDGE_CLEARANCE}]]

set bottom_start [list \
    [expr {$pin_core_urx - $PIN_EDGE_CLEARANCE}] $pin_core_lly]
set bottom_end [list \
    [expr {$SRAM_NO_MESH_URX + $PIN_EDGE_CLEARANCE}] $pin_core_lly]

if {[lindex $bottom_end 0] >= [lindex $bottom_start 0]} {
    error "No legal bottom-edge pin range remains to the right of the SRAM island"
}

setPinAssignMode -pinEditInBatch true

editPin \
    -pin $TOP_PINS \
    -side TOP \
    -layer M7 \
    -spreadType range \
    -start $top_start \
    -end $top_end \
    -spreadDirection clockwise \
    -pinWidth $PIN_WIDTH \
    -pinDepth $PIN_DEPTH \
    -fixOverlap 1 \
    -honorConstraint 1 \
    -fixedPin 1

editPin \
    -pin $RIGHT_PINS \
    -side RIGHT \
    -layer M6 \
    -spreadType range \
    -start $right_start \
    -end $right_end \
    -spreadDirection clockwise \
    -pinWidth $PIN_WIDTH \
    -pinDepth $PIN_DEPTH \
    -fixOverlap 1 \
    -honorConstraint 1 \
    -fixedPin 1

editPin \
    -pin $BOTTOM_PINS \
    -side BOTTOM \
    -layer M7 \
    -spreadType range \
    -start $bottom_start \
    -end $bottom_end \
    -spreadDirection clockwise \
    -pinWidth $PIN_WIDTH \
    -pinDepth $PIN_DEPTH \
    -fixOverlap 1 \
    -honorConstraint 1 \
    -fixedPin 1

setPinAssignMode -pinEditInBatch false

puts "===================================================="
puts "SEGMENTED AXI PIN ASSIGNMENT COMPLETED"
puts " - TOP    / M7 : [llength $TOP_PINS] pins"
puts " - RIGHT  / M6 : [llength $RIGHT_PINS] pins"
puts " - LEFT        : unused; SRAM macro/OBS priority"
puts " - BOTTOM / M7 : [llength $BOTTOM_PINS] pins, right of SRAM island"
puts "===================================================="
