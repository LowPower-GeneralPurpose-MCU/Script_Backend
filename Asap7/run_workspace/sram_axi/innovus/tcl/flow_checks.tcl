############################################################
## Shared report guards for one-command Innovus runs.
############################################################

proc assert_clean_check_place {report_file} {
    if {![file exists $report_file]} {
        error "Missing checkPlace report: [file normalize $report_file]"
    }

    set fp [open $report_file r]
    set report_text [read $fp]
    close $fp

    if {[string first "## No violations found ##" $report_text] < 0} {
        error "Placement is not clean; inspect [file normalize $report_file] before continuing to CTS"
    }
}

proc read_report_text {report_file report_label} {
    if {![file exists $report_file]} {
        error "Missing $report_label report: [file normalize $report_file]"
    }

    set fp [open $report_file r]
    set report_text [read $fp]
    close $fp
    return $report_text
}

proc assert_clean_drc_report {report_file} {
    set report_text [read_report_text $report_file "DRC"]

    if {[regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $report_text] ||
        [regexp {Total Violations[[:space:]]*:[[:space:]]*0([^0-9]|$)} $report_text]} {
        return
    }

    error "DRC is not clean; inspect [file normalize $report_file] before continuing"
}

proc assert_clean_connectivity_report {report_file} {
    set report_text [read_report_text $report_file "connectivity"]

    if {[string first "Found no problems or warnings" $report_text] >= 0 ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $report_text]} {
        return
    }

    error "Connectivity is not clean; inspect [file normalize $report_file] before continuing"
}

proc verify_pg_connectivity_or_stop {report_file} {
    applyGlobalNets

    verifyConnectivity \
        -type special \
        -net {VDD VSS} \
        -noUnroutedNet \
        -report $report_file

    assert_clean_connectivity_report $report_file
}

proc write_skipped_report {report_file reason} {
    file mkdir [file dirname $report_file]
    set fp [open $report_file w]
    puts $fp "# Skipped"
    puts $fp $reason
    close $fp
}

proc verify_antenna_if_enabled {report_file} {
    if {![info exists ::env(INNOVUS_RUN_ANTENNA_CHECK)] ||
        ![string is true -strict $::env(INNOVUS_RUN_ANTENNA_CHECK)]} {
        write_skipped_report $report_file \
            "INNOVUS_RUN_ANTENNA_CHECK is not enabled. ASAP7 educational LEFs used by this flow do not provide process antenna keywords, and Innovus TCR says verify_antenna requires those rules."
        puts "Antenna check skipped: set INNOVUS_RUN_ANTENNA_CHECK=1 only when antenna rules are loaded."
        return 0
    }

    if {[catch {verify_antenna -report $report_file} antenna_error]} {
        if {[string first "no process antenna information" $antenna_error] >= 0 ||
            [string first "IMPVPA-22" $antenna_error] >= 0} {
            write_skipped_report $report_file \
                "Skipped because Innovus reported no process antenna information for this design."
            puts "Antenna check skipped: no process antenna information is loaded."
            return 0
        }
        return -code error $antenna_error
    }

    return 1
}

proc connect_floating_pg_stripes_nojog {} {
    applyGlobalNets

    setSrouteMode -reset
    setSrouteMode \
        -viaConnectToShape {ring stripe blockring}

    sroute \
        -connect {floatingStripe} \
        -nets {VDD VSS} \
        -floatingStripeTarget {ring stripe blockring} \
        -allowJogging 0 \
        -allowLayerChange 0
}

proc connect_core_pg_pins_nojog {{report_file ""}} {
    applyGlobalNets

    connect_floating_pg_stripes_nojog

    setSrouteMode -reset
    setSrouteMode \
        -viaConnectToShape {ring stripe blockring}

    sroute \
        -connect {corePin} \
        -nets {VDD VSS} \
        -corePinCheckStdcellGeoms \
        -allowJogging 0 \
        -allowLayerChange 0

    editTrim -nets {VDD VSS}
    clearDrc

    if {$report_file ne ""} {
        verifyConnectivity \
            -type special \
            -net {VDD VSS} \
            -noUnroutedNet \
            -report $report_file
        assert_clean_connectivity_report $report_file
    }
}

proc assert_filler_inserted {{prefix "FILLER"}} {
    set filler_names [dbGet top.insts.name ${prefix}*]
    if {$filler_names eq "" || $filler_names eq "0x0" ||
        [llength $filler_names] == 0} {
        error "No filler instances with prefix ${prefix} were inserted"
    }
}
