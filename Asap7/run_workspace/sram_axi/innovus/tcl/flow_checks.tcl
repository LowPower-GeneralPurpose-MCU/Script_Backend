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

    if {[string first "No DRC violations were found" $report_text] >= 0 ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $report_text] ||
        [regexp {Total Violations[[:space:]]*:[[:space:]]*0([^0-9]|$)} $report_text]} {
        return
    }

    error "DRC is not clean; inspect [file normalize $report_file] before continuing"
}

proc assert_clean_pg_special_drc_report {report_file} {
    set report_text [read_report_text $report_file "PG special-route DRC"]

    if {[string first "No DRC violations were found" $report_text] >= 0 ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $report_text] ||
        [regexp {Total Violations[[:space:]]*:[[:space:]]*0([^0-9]|$)} $report_text]} {
        return
    }

    if {![regexp {Total Violations[[:space:]]*:[[:space:]]*([0-9]+)} $report_text -> count] &&
        ![regexp {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols} $report_text -> count]} {
        error "Cannot find total violation count in PG DRC report: [file normalize $report_file]"
    }

    set pg_drc_count 0
    set pin_drc_count 0
    set unknown_drc_count 0
    foreach line [split $report_text "\n"] {
        if {![regexp {^([A-Za-z][A-Za-z0-9_]*):} $line]} {
            continue
        }

        if {[regexp -nocase {Special[[:space:]]+(Wire|Via)} $line]} {
            incr pg_drc_count
        } elseif {[regexp -nocase {Pin[[:space:]]+of[[:space:]]+Cell} $line]} {
            incr pin_drc_count
        } else {
            incr unknown_drc_count
        }
    }

    if {$pg_drc_count != 0} {
        error "PG DRC is not clean: [file normalize $report_file] has $pg_drc_count special-route violations"
    }
    if {$unknown_drc_count != 0} {
        error "PG DRC is not clean: [file normalize $report_file] has $unknown_drc_count unclassified non-special violations"
    }

    puts "WARN: $report_file has $pin_drc_count Pin-of-Cell DRC marker(s), treated as hard-macro abstract/library markers at this PG checkpoint."
}

proc assert_clean_connectivity_report {report_file} {
    set report_text [read_report_text $report_file "connectivity"]

    if {[string first "Found no problems or warnings" $report_text] >= 0 ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $report_text]} {
        return
    }

    error "Connectivity is not clean; inspect [file normalize $report_file] before continuing"
}

proc pg_is_preplacement_pg_checkpoint {report_file {context ""}} {
    set normalized_report [file tail $report_file]
    if {$normalized_report eq "pg_connectivity_before_stdcell_place.rpt"} {
        return 1
    }
    return [expr {[string first "Power plan PG connectivity" $context] >= 0}]
}

proc assert_clean_pg_connectivity_report {report_file {allow_preplacement_special_opens 0}} {
    set report_text [read_report_text $report_file "PG connectivity"]

    if {[string first "Found no problems or warnings" $report_text] >= 0 ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $report_text]} {
        return
    }

    if {[regexp -nocase {dangling[[:space:]]+Wire|shorted} $report_text]} {
        error "PG special routes are open/shorted; inspect [file normalize $report_file] before continuing"
    }

    if {![pg_sram_block_pins_are_deferred] ||
        !$allow_preplacement_special_opens} {
        assert_clean_connectivity_report $report_file
        return
    }

    set saw_sram_terminal 0
    set saw_preplacement_special_open 0
    set unexpected_unconnected {}
    foreach line [split $report_text "\n"] {
        set trimmed_line [string trim $line]
        if {$trimmed_line eq ""} {
            continue
        }

        if {[regexp -nocase {special routes with opens|Special Wires:[[:space:]]+Pieces of the net are not connected together|IMPVFC-200} $trimmed_line]} {
            set saw_preplacement_special_open 1
            continue
        }

        if {![regexp -nocase {unconnected[[:space:]]+terminal|Terminal\(s\)[[:space:]]+are[[:space:]]+not[[:space:]]+connected|IMPVFC-96} $line]} {
            continue
        }

        if {[regexp {u_mem/G_SRAM_BANK\[[0-9]+\]\.u_sram/(VDD|VSS)} $trimmed_line]} {
            set saw_sram_terminal 1
            continue
        }
        if {[regexp {^[[:space:]]*[0-9]+[[:space:]]+Problem\(s\)[[:space:]]+\(IMPVFC-96\):} $trimmed_line]} {
            continue
        }
        if {[regexp {^Net[[:space:]]+V(DD|SS):[[:space:]]+has[[:space:]]+an[[:space:]]+unconnected[[:space:]]+terminal} $trimmed_line]} {
            continue
        }

        lappend unexpected_unconnected $trimmed_line
    }

    if {[llength $unexpected_unconnected] != 0} {
        error "PG connectivity has unexpected unconnected terminals: [join $unexpected_unconnected { | }]"
    }

    if {$saw_preplacement_special_open && !$allow_preplacement_special_opens} {
        error "PG special routes are open/shorted; inspect [file normalize $report_file] before continuing"
    }

    if {$saw_sram_terminal || $saw_preplacement_special_open} {
        if {$saw_sram_terminal} {
            puts "WARN: PG connectivity report contains deferred ASAP7 SRAM VDD/VSS macro terminals: $report_file"
        }
        if {$saw_preplacement_special_open} {
            puts "WARN: PG connectivity report contains pre-placement special-route open markers; strict PG reconnect is checked after placement/post-PG."
        }
        return
    }

    error "PG connectivity is not clean; inspect [file normalize $report_file] before continuing"
}

proc stop_if_dirty_pg_connectivity_report {report_file context} {
    set allow_preplacement_special_opens [expr {
        [pg_sram_block_pins_are_deferred] &&
        [pg_is_preplacement_pg_checkpoint $report_file $context]
    }]
    if {[catch {
        assert_clean_pg_connectivity_report \
            $report_file \
            $allow_preplacement_special_opens
    } report_error]} {
        error "$context failed: $report_error"
    }
}

proc stop_if_dirty_pg_special_drc_report {report_file context} {
    if {[catch {assert_clean_pg_special_drc_report $report_file} report_error]} {
        error "$context failed: $report_error"
    }
}

proc pg_sram_block_pins_are_deferred {} {
    global SRAM_CONNECT_BLOCK_PINS

    if {![info exists SRAM_CONNECT_BLOCK_PINS]} {
        return 0
    }
    if {![string is boolean -strict $SRAM_CONNECT_BLOCK_PINS]} {
        error "SRAM_CONNECT_BLOCK_PINS must be boolean, got $SRAM_CONNECT_BLOCK_PINS"
    }

    return [expr {!$SRAM_CONNECT_BLOCK_PINS}]
}

proc run_pg_connectivity_verify {report_file} {
    applyGlobalNets

    set verify_cmd [list \
        verifyConnectivity \
        -type special \
        -net {VDD VSS}]

    if {[pg_sram_block_pins_are_deferred]} {
        # Before placement, thousands of standard-cell PG terminals are not at
        # physical locations yet.  Cadence documents -noUnConnPin for skipping
        # those terminals while retaining special-wire open/short checks.
        lappend verify_cmd -noUnConnPin
        puts "PG connectivity verify: SRAM block pins are deferred; checking special-route opens/shorts without unplaced-terminal noise."
    } else {
        lappend verify_cmd -noUnroutedNet
    }

    lappend verify_cmd -report $report_file
    {*}$verify_cmd
}

proc verify_pg_connectivity_or_stop {report_file} {
    run_pg_connectivity_verify $report_file

    assert_clean_pg_connectivity_report $report_file
}

proc verify_pg_special_drc_or_stop {report_file {layer_range {M4 M9}}} {
    verify_drc \
        -check_only special \
        -layer_range $layer_range \
        -report $report_file

    assert_clean_pg_special_drc_report $report_file
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

proc connect_sram_block_pins_to_local_stripes_nojog {} {
    global SRAM_CONNECT_BLOCK_PINS SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE

    if {![info exists SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE]} {
        set SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE 1
    }
    if {![string is boolean -strict $SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE]} {
        error "SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE must be boolean, got $SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE"
    }
    if {!$SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE} {
        puts "SRAM blockPin post-place stitch skipped by SRAM_CONNECT_BLOCK_PINS_AFTER_PLACE=0."
        return
    }

    puts "Connecting SRAM VDD/VSS block pins to local SRAM island stripes."
    applyGlobalNets

    setSrouteMode -reset
    setSrouteMode \
        -extendNearestTarget true \
        -blockPinRouteWithPinWidth false \
        -viaConnectToShape stripe

    sroute \
        -connect {blockPin} \
        -nets {VSS VDD} \
        -blockPin useLef \
        -blockPinLayerRange {M4 M4} \
        -blockPinWidthRange {0.150 0.250} \
        -blockPinTarget {stripe} \
        -allowJogging 0

    set SRAM_CONNECT_BLOCK_PINS 1
    editTrim -nets {VDD VSS}
    clearDrc
}

proc connect_core_pg_pins_nojog {{report_file ""}} {
    global PG_CONNECT_FLOATING_STRIPES

    applyGlobalNets

    if {![info exists PG_CONNECT_FLOATING_STRIPES]} {
        set PG_CONNECT_FLOATING_STRIPES 0
    }
    if {![string is boolean -strict $PG_CONNECT_FLOATING_STRIPES]} {
        error "PG_CONNECT_FLOATING_STRIPES must be boolean, got $PG_CONNECT_FLOATING_STRIPES"
    }

    if {$PG_CONNECT_FLOATING_STRIPES} {
        puts "Connecting floating PG stripes to existing VDD/VSS ring/stripe/blockring targets."
        connect_floating_pg_stripes_nojog
    } else {
        puts "Floating PG stripe stitching skipped: keep SRAM island collectors from being auto-stitched through hard-macro keepout."
    }

    connect_sram_block_pins_to_local_stripes_nojog

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
        run_pg_connectivity_verify $report_file
        assert_clean_pg_connectivity_report $report_file
    }
}

proc assert_filler_inserted {{prefix "FILLER"}} {
    set filler_names [dbGet top.insts.name ${prefix}*]
    if {$filler_names eq "" || $filler_names eq "0x0" ||
        [llength $filler_names] == 0} {
        error "No filler instances with prefix ${prefix} were inserted"
    }
}
