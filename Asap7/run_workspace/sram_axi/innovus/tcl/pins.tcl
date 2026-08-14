############################################################
## AXI pin planning on all four core edges
##
## Macro-slide rules:
##   - favor Macro-to-Port connectivity
##   - keep signal escape directed toward the core
##   - do not confuse SRAM PG no-mesh with M6/M7 signal pin legality
############################################################

set PIN_PLAN_REVISION "sram_axi_four_side_connectivity_v6"
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

set AW_PINS [concat \
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

set W_PINS [concat \
    [make_bus_pins s_axi_wdata    31 0] \
    [make_bus_pins s_axi_wstrb     3 0] \
    [list s_axi_wlast s_axi_wvalid s_axi_wready] \
]

set B_PINS [concat \
    [make_bus_pins s_axi_bid       4 0] \
    [make_bus_pins s_axi_bresp     1 0] \
    [list s_axi_bvalid s_axi_bready] \
]

set AR_PINS [concat \
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

set R_PINS [concat \
    [make_bus_pins s_axi_rid       4 0] \
    [make_bus_pins s_axi_rdata    31 0] \
    [make_bus_pins s_axi_rresp     1 0] \
    [list s_axi_rlast s_axi_rvalid s_axi_rready] \
]

# Four-side channel placement.  Address/control channels are kept as intact
# AXI groups, write data enters from the SRAM-adjacent bottom side, and read/B
# response outputs leave on the right side near the retained controller rows.
set LEFT_PINS   [concat [list clk rst_n] $AW_PINS]
set BOTTOM_PINS $W_PINS
set TOP_PINS    $AR_PINS
set RIGHT_PINS  [concat $B_PINS $R_PINS]

set TOP_PINS    [keep_existing_ports $TOP_PINS]
set RIGHT_PINS  [keep_existing_ports $RIGHT_PINS]
set LEFT_PINS   [keep_existing_ports $LEFT_PINS]
set BOTTOM_PINS [keep_existing_ports $BOTTOM_PINS]

# Use all four boundary sides for signal pins.  The ASAP7 SRAM LEF provided for
# this design blocks M1/M2/M4/V4/M5 and exposes no M6/M7 OBS, while the DRM
# makes M6/M7 normal routing layers.  SRAM PG no-mesh remains a power-planning
# rule; it should not force AXI signal ports away from the macro side.

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

set bottom_start [list \
    [expr {$pin_core_urx - $PIN_EDGE_CLEARANCE}] $pin_core_lly]
set bottom_end [list \
    [expr {$pin_core_llx + $PIN_EDGE_CLEARANCE}] $pin_core_lly]

set left_start [list \
    $pin_core_llx [expr {$pin_core_ury - $PIN_EDGE_CLEARANCE}]]
set left_end [list \
    $pin_core_llx [expr {$pin_core_lly + $PIN_EDGE_CLEARANCE}]]

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

editPin \
    -pin $LEFT_PINS \
    -side LEFT \
    -layer M6 \
    -spreadType range \
    -start $left_start \
    -end $left_end \
    -spreadDirection counterclockwise \
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
set right_pin_pitch 0.0
set bottom_pin_pitch 0.0
set left_pin_pitch 0.0
if {[llength $TOP_PINS] > 1} {
    set top_pin_pitch [expr {
        ([lindex $top_end 0] - [lindex $top_start 0]) /
        double([llength $TOP_PINS] - 1)
    }]
}
if {[llength $RIGHT_PINS] > 1} {
    set right_pin_pitch [expr {
        ([lindex $right_start 1] - [lindex $right_end 1]) /
        double([llength $RIGHT_PINS] - 1)
    }]
}
if {[llength $BOTTOM_PINS] > 1} {
    set bottom_pin_pitch [expr {
        ([lindex $bottom_start 0] - [lindex $bottom_end 0]) /
        double([llength $BOTTOM_PINS] - 1)
    }]
}
if {[llength $LEFT_PINS] > 1} {
    set left_pin_pitch [expr {
        ([lindex $left_start 1] - [lindex $left_end 1]) /
        double([llength $LEFT_PINS] - 1)
    }]
}
puts $pin_geometry_report "revision $PIN_PLAN_REVISION"
puts $pin_geometry_report "top_side TOP"
puts $pin_geometry_report "top_layer M7"
puts $pin_geometry_report "top_y [lindex $top_start 1]"
puts $pin_geometry_report "top_group AR"
puts $pin_geometry_report "top_range $top_start $top_end"
puts $pin_geometry_report "top_count [llength $TOP_PINS]"
puts $pin_geometry_report "top_requested_uniform_pitch $top_pin_pitch"
puts $pin_geometry_report "right_group B_R"
puts $pin_geometry_report "right_range $right_start $right_end"
puts $pin_geometry_report "right_count [llength $RIGHT_PINS]"
puts $pin_geometry_report "right_requested_uniform_pitch $right_pin_pitch"
puts $pin_geometry_report "bottom_group W"
puts $pin_geometry_report "bottom_range $bottom_start $bottom_end"
puts $pin_geometry_report "bottom_count [llength $BOTTOM_PINS]"
puts $pin_geometry_report "bottom_requested_uniform_pitch $bottom_pin_pitch"
puts $pin_geometry_report "left_group CLK_RST_AW"
puts $pin_geometry_report "left_range $left_start $left_end"
puts $pin_geometry_report "left_count [llength $LEFT_PINS]"
puts $pin_geometry_report "left_requested_uniform_pitch $left_pin_pitch"
close $pin_geometry_report

puts "===================================================="
puts "SEGMENTED AXI PIN ASSIGNMENT COMPLETED"
puts " - TOP    / M7 : [llength $TOP_PINS] pins"
puts "                   AR channel, requested pitch $top_pin_pitch um on y=[lindex $top_start 1]"
puts " - RIGHT  / M6 : [llength $RIGHT_PINS] pins, pitch $right_pin_pitch um"
puts " - BOTTOM / M7 : [llength $BOTTOM_PINS] pins, pitch $bottom_pin_pitch um"
puts " - LEFT   / M6 : [llength $LEFT_PINS] pins, pitch $left_pin_pitch um"
puts " - SRAM bodies : PG mesh is blocked separately; M6/M7 signal pin access is not clipped by the SRAM no-mesh box"
puts "===================================================="
