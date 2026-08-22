############################################################
## Unit/static checks for SRAM signal preferred routing.
############################################################

set script_dir [file dirname [file normalize [info script]]]
set innovus_dir [file dirname $script_dir]
set route_script [file join $innovus_dir tcl sram_signal_route_constraints.tcl]
set test_report [file join $script_dir tmp_sram_signal_route_constraints.rpt]

set SRAM_MASTER srambank_test
set SRAM_COUNT 2
set sram_signal_route_report $test_report
set SRAM_SIGNAL_ROUTE_ENABLE 1
set SRAM_SIGNAL_ROUTE_BOTTOM_LAYER 4
set SRAM_SIGNAL_ROUTE_TOP_LAYER 7
set SRAM_SIGNAL_ROUTE_EFFORT high
set captured_attributes {}

array set mock_db {
    I0.name u_mem/bank0
    I1.name u_mem/bank1
    I0.instTerms {T0_WD T0_Q T0_CLK T0_VDD T0_OPEN}
    I1.instTerms {T1_WD T1_ADDR T1_VSS}
    T0_WD.name {wd[0]}
    T0_WD.net.name {u_mem/bank_wdata[0]}
    T0_Q.name {dataout[0]}
    T0_Q.net.name {u_mem/bank_rdata[0][0]}
    T0_CLK.name clk
    T0_CLK.net.name core_clk
    T0_VDD.name VDD
    T0_VDD.net.name VDD
    T0_OPEN.name {ADDRESS[0]}
    T0_OPEN.net.name 0x0
    T1_WD.name {wd[0]}
    T1_WD.net.name {u_mem/bank_wdata[0]}
    T1_ADDR.name {ADDRESS[0]}
    T1_ADDR.net.name {u_mem/bank_address[0]}
    T1_VSS.name VSS
    T1_VSS.net.name VSS
}

proc dbGet {args} {
    global mock_db SRAM_MASTER

    if {[llength $args] == 3 &&
        [lindex $args 0] eq "-p2" &&
        [lindex $args 1] eq "top.insts.cell.name" &&
        [lindex $args 2] eq $SRAM_MASTER} {
        return {I0 I1}
    }
    if {[llength $args] == 2 && [lindex $args 0] eq "-e"} {
        set key [lindex $args 1]
        if {[info exists mock_db($key)]} {
            return $mock_db($key)
        }
    }
    if {[llength $args] == 1} {
        set key [lindex $args 0]
        if {[info exists mock_db($key)]} {
            return $mock_db($key)
        }
    }
    error "Unexpected dbGet call: $args"
}

proc setAttribute {args} {
    global captured_attributes
    lappend captured_attributes $args
}

source $route_script

if {[llength $captured_attributes] != 3} {
    error "Expected three unique SRAM signal-net constraints, got [llength $captured_attributes]"
}

set captured_nets {}
foreach args $captured_attributes {
    set net_index [lsearch -exact $args -net]
    set bottom_index [lsearch -exact $args -bottom_preferred_routing_layer]
    set top_index [lsearch -exact $args -top_preferred_routing_layer]
    set effort_index [lsearch -exact $args -preferred_routing_layer_effort]
    if {$net_index < 0 || $bottom_index < 0 || $top_index < 0 || $effort_index < 0} {
        error "Incomplete setAttribute invocation: $args"
    }
    if {[lindex $args [expr {$bottom_index + 1}]] != 4 ||
        [lindex $args [expr {$top_index + 1}]] != 7 ||
        [lindex $args [expr {$effort_index + 1}]] ne "high"} {
        error "Incorrect SRAM preferred-routing policy: $args"
    }
    lappend captured_nets [lindex $args [expr {$net_index + 1}]]
}

if {[lsort -dictionary $captured_nets] ne {{u_mem/bank_address[0]} {u_mem/bank_rdata[0][0]} {u_mem/bank_wdata[0]}}} {
    error "Unexpected constrained SRAM nets: $captured_nets"
}
if {[lsearch -exact $captured_nets core_clk] >= 0 ||
    [lsearch -exact $captured_nets VDD] >= 0 ||
    [lsearch -exact $captured_nets VSS] >= 0} {
    error "Clock or PG net was incorrectly constrained: $captured_nets"
}

set report_fh [open $test_report r]
set report_text [read $report_fh]
close $report_fh
file delete -force $test_report

foreach expected {
    {preferred_layers M4:M7}
    {preferred_effort high}
    {signal_net_count 3}
    {skipped_pg_clock_or_open_terms 4}
} {
    if {[string first $expected $report_text] < 0} {
        error "Missing route-policy report evidence: $expected"
    }
}

puts "PASS: SRAM signal routing policy is deduplicated, excludes clocks/PG, and prefers M4-M7"
