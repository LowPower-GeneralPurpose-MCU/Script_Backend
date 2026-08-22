############################################################
## SRAM signal-net routing policy
##
## The generated ASAP7 SRAM abstract exposes signal pins on M3/M4 and V3.
## A normal M3-to-M4 pin-access via may be placed anywhere on the wide M4
## pin shape, including locations covered by the macro's V3 OBS.  Prefer
## M4-M7 for every SRAM signal net so NanoRoute reaches the macro on M4 and
## does not create an extra V3 cut over the SRAM body.
############################################################

foreach required_variable {
    SRAM_MASTER
    SRAM_COUNT
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable before SRAM signal-route setup"
    }
}

if {![info exists SRAM_SIGNAL_ROUTE_ENABLE]} {
    set SRAM_SIGNAL_ROUTE_ENABLE 1
}
if {![info exists SRAM_SIGNAL_ROUTE_BOTTOM_LAYER]} {
    set SRAM_SIGNAL_ROUTE_BOTTOM_LAYER 4
}
if {![info exists SRAM_SIGNAL_ROUTE_TOP_LAYER]} {
    set SRAM_SIGNAL_ROUTE_TOP_LAYER 7
}
if {![info exists SRAM_SIGNAL_ROUTE_EFFORT]} {
    set SRAM_SIGNAL_ROUTE_EFFORT high
}
if {![info exists sram_signal_route_report]} {
    set sram_signal_route_report ./reports/sram_signal_route_constraints.rpt
}

if {![string is integer -strict $SRAM_SIGNAL_ROUTE_BOTTOM_LAYER] ||
    ![string is integer -strict $SRAM_SIGNAL_ROUTE_TOP_LAYER] ||
    $SRAM_SIGNAL_ROUTE_BOTTOM_LAYER < 2 ||
    $SRAM_SIGNAL_ROUTE_TOP_LAYER < $SRAM_SIGNAL_ROUTE_BOTTOM_LAYER} {
    error "Invalid SRAM preferred routing-layer range: $SRAM_SIGNAL_ROUTE_BOTTOM_LAYER:$SRAM_SIGNAL_ROUTE_TOP_LAYER"
}
if {[lsearch -exact {low medium high} $SRAM_SIGNAL_ROUTE_EFFORT] < 0} {
    error "SRAM_SIGNAL_ROUTE_EFFORT must be low, medium or high"
}

set sram_signal_route_ptrs [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {$sram_signal_route_ptrs eq "" || $sram_signal_route_ptrs eq "0x0"} {
    error "No SRAM instances found before SRAM signal-route setup"
}
if {[llength $sram_signal_route_ptrs] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros before SRAM signal-route setup; found [llength $sram_signal_route_ptrs]"
}

array set sram_signal_route_seen {}
array set sram_signal_route_origin {}
set sram_signal_route_nets {}
set sram_signal_route_skipped_terms 0

foreach inst_ptr $sram_signal_route_ptrs {
    set inst_name [lindex [dbGet $inst_ptr.name] 0]
    set inst_term_ptrs [dbGet -e $inst_ptr.instTerms]

    foreach inst_term_ptr $inst_term_ptrs {
        set term_name [lindex [dbGet $inst_term_ptr.name] 0]
        set net_name [lindex [dbGet $inst_term_ptr.net.name] 0]

        if {$net_name eq "" || $net_name eq "0x0"} {
            incr sram_signal_route_skipped_terms
            continue
        }
        if {[regexp -nocase {(^|/)(VDD|VSS|clk)$} $term_name] ||
            [lsearch -exact {VDD VSS} $net_name] >= 0} {
            incr sram_signal_route_skipped_terms
            continue
        }
        if {[info exists sram_signal_route_seen($net_name)]} {
            continue
        }

        set sram_signal_route_seen($net_name) 1
        set sram_signal_route_origin($net_name) "$inst_name/$term_name"
        lappend sram_signal_route_nets $net_name
    }
}

set sram_signal_route_nets [lsort -dictionary $sram_signal_route_nets]
if {[llength $sram_signal_route_nets] == 0} {
    error "No connected SRAM signal nets found before routing"
}

file mkdir [file dirname $sram_signal_route_report]
file delete -force $sram_signal_route_report
set sram_signal_route_fh [open $sram_signal_route_report w]
puts $sram_signal_route_fh "enabled $SRAM_SIGNAL_ROUTE_ENABLE"
puts $sram_signal_route_fh "preferred_layers M${SRAM_SIGNAL_ROUTE_BOTTOM_LAYER}:M${SRAM_SIGNAL_ROUTE_TOP_LAYER}"
puts $sram_signal_route_fh "preferred_effort $SRAM_SIGNAL_ROUTE_EFFORT"
puts $sram_signal_route_fh "signal_net_count [llength $sram_signal_route_nets]"
puts $sram_signal_route_fh "skipped_pg_clock_or_open_terms $sram_signal_route_skipped_terms"
puts $sram_signal_route_fh "net bottom_layer top_layer effort first_sram_term status"

foreach net_name $sram_signal_route_nets {
    set status disabled
    if {$SRAM_SIGNAL_ROUTE_ENABLE} {
        if {[catch {
            setAttribute \
                -net $net_name \
                -bottom_preferred_routing_layer $SRAM_SIGNAL_ROUTE_BOTTOM_LAYER \
                -top_preferred_routing_layer $SRAM_SIGNAL_ROUTE_TOP_LAYER \
                -preferred_routing_layer_effort $SRAM_SIGNAL_ROUTE_EFFORT
        } attribute_error]} {
            close $sram_signal_route_fh
            error "Cannot set SRAM routing policy on net $net_name: $attribute_error"
        }
        set status constrained
    }

    puts $sram_signal_route_fh [list \
        $net_name \
        M$SRAM_SIGNAL_ROUTE_BOTTOM_LAYER \
        M$SRAM_SIGNAL_ROUTE_TOP_LAYER \
        $SRAM_SIGNAL_ROUTE_EFFORT \
        $sram_signal_route_origin($net_name) \
        $status]
}
close $sram_signal_route_fh

puts "SRAM signal route report: $sram_signal_route_report"
if {$SRAM_SIGNAL_ROUTE_ENABLE} {
    puts "Applied M${SRAM_SIGNAL_ROUTE_BOTTOM_LAYER}-M${SRAM_SIGNAL_ROUTE_TOP_LAYER} preferred routing to [llength $sram_signal_route_nets] SRAM signal nets."
} else {
    puts "SRAM signal preferred-routing policy is disabled."
}
