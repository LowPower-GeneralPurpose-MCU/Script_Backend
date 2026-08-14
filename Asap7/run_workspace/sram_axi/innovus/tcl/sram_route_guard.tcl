############################################################
## SRAM macro-body route reservation for placement, eGR, CTS, and route
##
## Intent:
##   - Trust the SRAM LEF obstruction layers by default.  The ASAP7 SRAM used
##     here blocks M1/M2/M4/V4/M5 but does not declare M6/M7 OBS.
##   - Keep the command available for a deliberate debug/signoff experiment
##     where signal/clock routes must be blocked over the macro body.
##   - Use Cadence's documented createRouteBlk -exceptpgnet form so this guard
##     blocks signal routing, while still allowing explicit power/ground special
##     routes if a future SRAM PG stitch needs them.
##   - Do not block the generated ASAP7 SRAM pin-access/abstract layers
##     M3/M4/M5/V3/V4.  Those layers are used by the macro LEF itself and by the
##     local SRAM PG collectors; blocking them can create pin-access DRC instead
##     of fixing floorplan intent.
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
if {![info exists SRAM_ROUTE_GUARD_LAYERS]} {
    set SRAM_ROUTE_GUARD_LAYERS {M6 M7}
}
if {![info exists SRAM_ROUTE_GUARD_ENABLE]} {
    set SRAM_ROUTE_GUARD_ENABLE 0
}
if {![info exists SRAM_ROUTE_GUARD_PREFIX]} {
    set SRAM_ROUTE_GUARD_PREFIX SRAM_BODY_SIGNAL_GUARD
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

# The one-command flow sources this file before placement and again before
# routing.  Query first so the initial source does not emit IMPFP-6001, then
# delete only our own named objects and leave user/manual blockages untouched.
# This also clears stale M6/M7 guards from older experiments when the default
# LEF-trusting mode is used.
set existing_sram_route_guards \
    [dbGet -e -p top.fPlan.rBlkgs.name ${SRAM_ROUTE_GUARD_PREFIX}_*]
if {$existing_sram_route_guards ne "" &&
    $existing_sram_route_guards ne "0x0"} {
    deleteRouteBlk \
        -name ${SRAM_ROUTE_GUARD_PREFIX}_* \
        -type routes
}

set guard_report_fh [open $sram_route_guard_report w]
puts $guard_report_fh "enabled $SRAM_ROUTE_GUARD_ENABLE"
puts $guard_report_fh "default_reason ASAP7_SRAM_LEF_blocks_M1_M2_M4_V4_M5_no_M6_M7_OBS"
puts $guard_report_fh "index instance llx lly urx ury route_blockage_name route_blockage_layers exceptpgnet egr_reverse_layer status"

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

    if {!$SRAM_ROUTE_GUARD_ENABLE} {
        puts $guard_report_fh [format "%02d %s %.6f %.6f %.6f %.6f %s %s %s %s %s" \
            $guard_index $macro_name \
            $llx $lly $urx $ury \
            disabled "{}" no \
            none $macro_status]
        incr guard_index
        continue
    }

    append sram_egr_reverse_regions [format \
        "(%.6f %.6f %.6f %.6f) %s:%s " \
        $llx $lly $urx $ury \
        $SRAM_ROUTE_GUARD_EGR_LAYER $SRAM_ROUTE_GUARD_EGR_LAYER]

    set block_name [format "%s_%02d" $SRAM_ROUTE_GUARD_PREFIX $guard_index]
    createRouteBlk \
        -name $block_name \
        -box [list $llx $lly $urx $ury] \
        -layer $SRAM_ROUTE_GUARD_LAYERS \
        -exceptpgnet

    puts $guard_report_fh [format "%02d %s %.6f %.6f %.6f %.6f %s %s %s %s %s" \
        $guard_index $macro_name \
        $llx $lly $urx $ury \
        $block_name "{$SRAM_ROUTE_GUARD_LAYERS}" yes \
        $SRAM_ROUTE_GUARD_EGR_LAYER $macro_status]
    incr guard_index
}
close $guard_report_fh

set sram_egr_reverse_regions [string trim $sram_egr_reverse_regions]
if {$SRAM_ROUTE_GUARD_ENABLE && $sram_egr_reverse_regions ne ""} {
    setRouteMode \
        -earlyGlobalReverseDirection $sram_egr_reverse_regions
}

puts "SRAM route guard report: $sram_route_guard_report"
if {$SRAM_ROUTE_GUARD_ENABLE} {
    puts "SRAM route guard created signal-only route blockages on {$SRAM_ROUTE_GUARD_LAYERS}; PG special routes are exempt."
    puts "SRAM early-global route reservation remains on $SRAM_ROUTE_GUARD_EGR_LAYER for placement/CTS estimation."
} else {
    puts "SRAM route guard disabled by default: using the SRAM LEF OBS layers and allowing M6/M7 signal escape over the macro body."
    puts "SRAM PG no-mesh is still controlled by the power-plan scripts, not by signal route blockages."
}
