############################################################
## SRAM macro-body route reservation for placement, eGR, CTS, and route
##
## Intent:
##   - Match the teacher reference style: reserve a preferred-direction
##     early-global route layer over each SRAM macro body.
##   - Do not create hard routing blockages over the SRAM body.  The generated
##     ASAP7 SRAM abstract has internal signal pins/OBS on M3/M4/M5/V3/V4;
##     adding extra route blockages over those layers makes NanoRoute fight
##     its own pin-access problem and shows up as "Regular Wire & Routing
##     Blockage" DRC.
##   - Standard-cell keepout around the SRAM island is a placement problem and
##     is handled by createPlaceBlockage in finish_macroFP.tcl.
############################################################

foreach required_variable {
    SRAM_MASTER
    SRAM_COUNT
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable before SRAM route guard setup"
    }
}

if {![info exists SRAM_ROUTE_GUARD_EGR_LAYER]} {
    set SRAM_ROUTE_GUARD_EGR_LAYER M5
}
if {![info exists sram_route_guard_report]} {
    set sram_route_guard_report ./reports/sram_route_guard.rpt
}

set SRAM_ROUTE_GUARD_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {$SRAM_ROUTE_GUARD_PTRS eq "" || $SRAM_ROUTE_GUARD_PTRS eq "0x0"} {
    error "No SRAM instances found before SRAM route guard setup"
}
if {[llength $SRAM_ROUTE_GUARD_PTRS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros before route guard setup; found [llength $SRAM_ROUTE_GUARD_PTRS]"
}

file mkdir [file dirname $sram_route_guard_report]
file delete -force $sram_route_guard_report

set guard_report_fh [open $sram_route_guard_report w]
puts $guard_report_fh "index instance llx lly urx ury route_blockage_created egr_reverse_layer status"

set guard_index 0
set sram_egr_reverse_regions ""
foreach ptr $SRAM_ROUTE_GUARD_PTRS {
    set macro_name [lindex [dbGet $ptr.name] 0]
    set macro_status [lindex [dbGet $ptr.pStatus] 0]
    set macro_box [join [dbGet $ptr.box]]
    if {[llength $macro_box] != 4} {
        close $guard_report_fh
        error "Cannot decode SRAM route-guard box for $macro_name: [dbGet $ptr.box]"
    }

    lassign $macro_box llx lly urx ury
    foreach coordinate [list $llx $lly $urx $ury] {
        if {![string is double -strict $coordinate]} {
            close $guard_report_fh
            error "Non-numeric SRAM route-guard box for $macro_name: $macro_box"
        }
    }
    if {$urx <= $llx || $ury <= $lly} {
        close $guard_report_fh
        error "Invalid SRAM route-guard box for $macro_name: $macro_box"
    }

    if {$macro_status ne "fixed"} {
        close $guard_report_fh
        error "$macro_name must be FIXED before SRAM route guard setup; current status is $macro_status"
    }

    append sram_egr_reverse_regions [format \
        "(%.6f %.6f %.6f %.6f) %s:%s " \
        $llx $lly $urx $ury \
        $SRAM_ROUTE_GUARD_EGR_LAYER $SRAM_ROUTE_GUARD_EGR_LAYER]

    puts $guard_report_fh [format "%02d %s %.6f %.6f %.6f %.6f %s %s %s" \
        $guard_index $macro_name \
        $llx $lly $urx $ury \
        no $SRAM_ROUTE_GUARD_EGR_LAYER $macro_status]
    incr guard_index
}
close $guard_report_fh

set sram_egr_reverse_regions [string trim $sram_egr_reverse_regions]
if {$sram_egr_reverse_regions ne ""} {
    setRouteMode \
        -earlyGlobalReverseDirection $sram_egr_reverse_regions
}

puts "SRAM route guard report: $sram_route_guard_report"
puts "SRAM route blockages are not created; using M5 early-global reverse-direction reservation only."
