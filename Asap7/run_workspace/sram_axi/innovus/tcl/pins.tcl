############################################################
## AXI pin planning on the unobstructed core edges
##
## Macro-slide rules:
##   - favor Macro-to-Port connectivity
##   - keep signal escape directed toward the core
##   - do not force top-level ports through SRAM macro obstructions
############################################################

set PIN_PLAN_REVISION "sram_top_right_uniform_v4"
puts "PIN PLAN REVISION: $PIN_PLAN_REVISION ([file normalize [info script]])"

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

# The legal bottom segment is only about 104 um wide.  Compressing all read
# response pins there produced a visibly dense row and poor escape into the
# same right-side logic channel.  Continue the clockwise AXI ordering on the
# unobstructed RIGHT edge instead.
set RIGHT_PINS [concat $RIGHT_PINS $BOTTOM_PINS]
set BOTTOM_PINS {}

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

setPinAssignMode -pinEditInBatch false

checkPinAssignment \
    -outFile ./verify_rpt/checkPinAssignment_after_pin.rpt

set pin_geometry_report [open ./reports/top_level_pin_geometry.rpt w]
set top_pin_pitch 0.0
if {[llength $TOP_PINS] > 1} {
    set top_pin_pitch [expr {
        ([lindex $top_end 0] - [lindex $top_start 0]) /
        double([llength $TOP_PINS] - 1)
    }]
}
puts $pin_geometry_report "revision $PIN_PLAN_REVISION"
puts $pin_geometry_report "top_side TOP"
puts $pin_geometry_report "top_layer M7"
puts $pin_geometry_report "top_y [lindex $top_start 1]"
puts $pin_geometry_report "top_range $top_start $top_end"
puts $pin_geometry_report "top_count [llength $TOP_PINS]"
puts $pin_geometry_report "top_requested_uniform_pitch $top_pin_pitch"
puts $pin_geometry_report "right_range $right_start $right_end"
puts $pin_geometry_report "right_count [llength $RIGHT_PINS]"
puts $pin_geometry_report "left_side unused_sram_obstruction"
puts $pin_geometry_report "bottom_side unused_sram_obstruction"
close $pin_geometry_report

puts "===================================================="
puts "SEGMENTED AXI PIN ASSIGNMENT COMPLETED"
puts " - TOP    / M7 : [llength $TOP_PINS] pins"
puts "                   requested pitch $top_pin_pitch um on y=[lindex $top_start 1]"
puts " - RIGHT  / M6 : [llength $RIGHT_PINS] pins, uniformly spread"
puts " - LEFT        : unused; SRAM macro/OBS priority"
puts " - BOTTOM      : unused; SRAM macro/OBS priority"
puts "===================================================="
