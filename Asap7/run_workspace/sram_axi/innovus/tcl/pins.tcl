############################################################
## AXI pin planning around a lower-left SRAM macro island
##
## Macro-slide rules:
##   - favor Macro-to-Port connectivity
##   - keep signal escape directed toward the core
##   - do not place top-level pins beside/under the macro island
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

# Do not assign one port to more than one edge.
set assigned_ports {}
foreach pin [concat $TOP_PINS $RIGHT_PINS $LEFT_PINS $BOTTOM_PINS] {
    if {[lsearch -exact $assigned_ports $pin] >= 0} {
        error "Top-level pin $pin is assigned to more than one side"
    }
    lappend assigned_ports $pin
}

set pin_die_box [join [dbGet top.fPlan.box]]
if {[llength $pin_die_box] != 4} {
    error "Cannot decode die box for pin placement: [dbGet top.fPlan.box]"
}
lassign $pin_die_box die_llx die_lly die_urx die_ury

set PIN_WIDTH 0.128
set PIN_DEPTH 0.288
set PIN_EDGE_CLEARANCE 8.000
set PIN_ISLAND_CLEARANCE 8.000

set top_start [list \
    [expr {$die_llx + $PIN_EDGE_CLEARANCE}] $die_ury]
set top_end [list \
    [expr {$die_urx - $PIN_EDGE_CLEARANCE}] $die_ury]

set right_start [list \
    $die_urx [expr {$die_lly + $PIN_EDGE_CLEARANCE}]]
set right_end [list \
    $die_urx [expr {$die_ury - $PIN_EDGE_CLEARANCE}]]

# LEFT pins occupy only the segment above the SRAM island.
set left_start_y [expr {
    $SRAM_ISLAND_CUT_URY + $PIN_ISLAND_CLEARANCE
}]
set left_end_y [expr {$die_ury - $PIN_EDGE_CLEARANCE}]
if {$left_start_y >= $left_end_y} {
    error "No legal LEFT pin range remains above the SRAM island"
}
set left_start [list $die_llx $left_start_y]
set left_end   [list $die_llx $left_end_y]

# BOTTOM pins occupy only the segment to the right of the SRAM island.
set bottom_start_x [expr {
    $SRAM_ISLAND_CUT_URX + $PIN_ISLAND_CLEARANCE
}]
set bottom_end_x [expr {$die_urx - $PIN_EDGE_CLEARANCE}]
if {$bottom_start_x >= $bottom_end_x} {
    error "No legal BOTTOM pin range remains right of the SRAM island"
}
set bottom_start [list $bottom_start_x $die_lly]
set bottom_end   [list $bottom_end_x $die_lly]

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
    -pin $LEFT_PINS \
    -side LEFT \
    -layer M6 \
    -spreadType range \
    -start $left_start \
    -end $left_end \
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
puts " - LEFT   / M6 : [llength $LEFT_PINS] pins above island"
puts " - BOTTOM / M7 : [llength $BOTTOM_PINS] pins right of island"
puts "===================================================="
