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
        [pg_core_handoff_is_deferred] &&
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

proc pg_core_handoff_is_deferred {} {
    global STDCELL_CORE_PG_BUILT

    if {![info exists STDCELL_CORE_PG_BUILT]} {
        return 1
    }
    if {![string is boolean -strict $STDCELL_CORE_PG_BUILT]} {
        error "STDCELL_CORE_PG_BUILT must be boolean, got $STDCELL_CORE_PG_BUILT"
    }

    return [expr {!$STDCELL_CORE_PG_BUILT}]
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
        # Cadence verifyConnectivity documents -allPGPinPort as the mode that
        # verifies every PG port.  -noUnroutedNet alone allowed sroute's
        # "32 ports open due to poor power planning" result to look clean.
        lappend verify_cmd -allPGPinPort -noUnroutedNet
    }

    lappend verify_cmd -report $report_file
    {*}$verify_cmd
}

proc verify_pg_connectivity_or_stop {report_file} {
    run_pg_connectivity_verify $report_file

    assert_clean_pg_connectivity_report $report_file
}

proc verify_pg_special_drc_or_stop {report_file {layer_range {M4 M9}}} {
    set verify_cmd [list \
        verify_drc \
        -check_only special \
        -layer_range $layer_range]

    set owned_areas [pg_top_level_owned_drc_areas]
    if {[llength $owned_areas] != 0} {
        lappend verify_cmd -area $owned_areas
        write_pg_drc_scope_report \
            ./verify_rpt/sram_macro_abstract_drc_scope.rpt \
            $owned_areas
        puts "PG DRC scope: checking top-level logic, island borders, and inter-macro PG gaps; SRAM macro-internal LEF pin shapes remain an IP-level signoff responsibility."
    }

    lappend verify_cmd -report $report_file
    {*}$verify_cmd

    assert_clean_pg_special_drc_report $report_file
}

proc pg_append_unique_drc_box {box boxes_var} {
    upvar 1 $boxes_var boxes

    if {[llength $box] != 4} {
        error "Invalid PG DRC area: $box"
    }
    lassign $box llx lly urx ury
    if {$urx <= $llx || $ury <= $lly} {
        return
    }
    if {[lsearch -exact $boxes $box] < 0} {
        lappend boxes $box
    }
}

proc pg_top_level_owned_drc_areas {} {
    global SRAM_DIE_BOX SRAM_ISLAND_LLX SRAM_ISLAND_LLY
    global SRAM_ISLAND_URX SRAM_ISLAND_URY SRAM_MACRO_BOXES
    global SRAM_MACRO_GAP_X SRAM_MACRO_GAP_Y
    global SRAM_PIN_TAP_AREAS

    foreach required_var {
        SRAM_DIE_BOX
        SRAM_ISLAND_LLX SRAM_ISLAND_LLY
        SRAM_ISLAND_URX SRAM_ISLAND_URY
        SRAM_MACRO_BOXES
        SRAM_MACRO_GAP_X SRAM_MACRO_GAP_Y
    } {
        if {![info exists $required_var]} {
            return {}
        }
    }

    lassign $SRAM_DIE_BOX die_llx die_lly die_urx die_ury
    set areas {}

    # Top-level owns the logic channel and the four collectors around the
    # island.  Macro interiors are pre-verified hard-IP geometry.
    pg_append_unique_drc_box \
        [list $SRAM_ISLAND_URX $die_lly $die_urx $die_ury] areas
    pg_append_unique_drc_box \
        [list $die_llx $SRAM_ISLAND_URY $SRAM_ISLAND_URX $die_ury] areas
    pg_append_unique_drc_box \
        [list $die_llx $die_lly $SRAM_ISLAND_LLX $SRAM_ISLAND_URY] areas
    pg_append_unique_drc_box \
        [list $SRAM_ISLAND_LLX $die_lly $SRAM_ISLAND_URX $SRAM_ISLAND_LLY] areas

    # Check every four-row channel between adjacent SRAMs.  These are exactly
    # the regions where the local M4/M5 island collectors are top-level owned.
    for {set i 0} {$i < [llength $SRAM_MACRO_BOXES]} {incr i} {
        set a [lindex $SRAM_MACRO_BOXES $i]
        lassign [lrange $a 1 4] a_llx a_lly a_urx a_ury

        for {set j [expr {$i + 1}]} \
            {$j < [llength $SRAM_MACRO_BOXES]} \
            {incr j} {
            set b [lindex $SRAM_MACRO_BOXES $j]
            lassign [lrange $b 1 4] b_llx b_lly b_urx b_ury

            set overlap_lly [expr {max($a_lly, $b_lly)}]
            set overlap_ury [expr {min($a_ury, $b_ury)}]
            if {$overlap_ury > $overlap_lly} {
                if {$a_urx <= $b_llx} {
                    set gap [expr {$b_llx - $a_urx}]
                    if {abs($gap - $SRAM_MACRO_GAP_X) <= 0.001} {
                        pg_append_unique_drc_box \
                            [list $a_urx $overlap_lly $b_llx $overlap_ury] areas
                    }
                } elseif {$b_urx <= $a_llx} {
                    set gap [expr {$a_llx - $b_urx}]
                    if {abs($gap - $SRAM_MACRO_GAP_X) <= 0.001} {
                        pg_append_unique_drc_box \
                            [list $b_urx $overlap_lly $a_llx $overlap_ury] areas
                    }
                }
            }

            set overlap_llx [expr {max($a_llx, $b_llx)}]
            set overlap_urx [expr {min($a_urx, $b_urx)}]
            if {$overlap_urx > $overlap_llx} {
                if {$a_ury <= $b_lly} {
                    set gap [expr {$b_lly - $a_ury}]
                    if {abs($gap - $SRAM_MACRO_GAP_Y) <= 0.001} {
                        pg_append_unique_drc_box \
                            [list $overlap_llx $a_ury $overlap_urx $b_lly] areas
                    }
                } elseif {$b_ury <= $a_lly} {
                    set gap [expr {$a_lly - $b_ury}]
                    if {abs($gap - $SRAM_MACRO_GAP_Y) <= 0.001} {
                        pg_append_unique_drc_box \
                            [list $overlap_llx $b_ury $overlap_urx $a_lly] areas
                    }
                }
            }
        }
    }

    # Deterministic M5 access pairs are top-level geometry even though each
    # pair overlaps a short edge corridor of its hard macro.  Include those
    # corridors so M4/M5 interface and V4 via DRC are not hidden by the normal
    # exclusion of macro-internal LEF shapes.
    if {[info exists SRAM_PIN_TAP_AREAS]} {
        foreach tap_record $SRAM_PIN_TAP_AREAS {
            if {[llength $tap_record] != 3} {
                error "Invalid SRAM pin-tap DRC record: $tap_record"
            }
            pg_append_unique_drc_box [lindex $tap_record 2] areas
        }
    }

    return $areas
}

proc write_pg_drc_scope_report {report_file owned_areas} {
    global SRAM_MACRO_BOXES

    set fp [open $report_file w]
    puts $fp "check_scope top_level_owned_pg"
    puts $fp "reason SRAM macro-internal pin geometry belongs to hard-IP signoff; top-level verifies logic regions, island borders, inter-macro collectors, and deterministic M5 tap corridors"
    puts $fp "top_level_area_count [llength $owned_areas]"
    foreach area $owned_areas {
        puts $fp "top_level_area $area"
    }
    puts $fp "excluded_hard_macro_count [llength $SRAM_MACRO_BOXES]"
    foreach macro $SRAM_MACRO_BOXES {
        puts $fp "hard_macro $macro"
    }
    close $fp
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

proc connect_sram_block_pins_to_local_stripes_nojog {} {
    global SRAM_CONNECT_BLOCK_PINS SRAM_BLOCKPIN_STITCH_DONE

    if {![info exists SRAM_BLOCKPIN_STITCH_DONE] ||
        ![string is boolean -strict $SRAM_BLOCKPIN_STITCH_DONE] ||
        !$SRAM_BLOCKPIN_STITCH_DONE} {
        error "Deterministic SRAM M5 edge taps were not built by sram_island_power.tcl"
    }

    # This procedure intentionally draws no geometry.  The local power script
    # is the single owner of macro access, so post-placement verification can
    # never invoke a broad blockPin/floatingStripe search as a repair step.
    set SRAM_CONNECT_BLOCK_PINS 1
    puts "SRAM block-pin access preserved: deterministic M5 edge taps are the only owner."
}

proc connect_core_pg_pins_nojog {{report_file ""} {refresh_stdcell_core_pins 0}} {
    global STDCELL_CORE_PG_BUILT

    applyGlobalNets
    puts "Floating PG stripe stitching is disabled by construction."

    connect_sram_block_pins_to_local_stripes_nojog

    if {![string is boolean -strict $refresh_stdcell_core_pins]} {
        error "refresh_stdcell_core_pins must be boolean, got $refresh_stdcell_core_pins"
    }

    if {[info exists STDCELL_CORE_PG_BUILT] &&
        ![string is boolean -strict $STDCELL_CORE_PG_BUILT]} {
        error "STDCELL_CORE_PG_BUILT must be boolean, got $STDCELL_CORE_PG_BUILT"
    }
    set core_pg_is_built [expr {
        [info exists STDCELL_CORE_PG_BUILT] && $STDCELL_CORE_PG_BUILT
    }]
    if {$core_pg_is_built && !$refresh_stdcell_core_pins} {
        puts "CorePin reconnect skipped: M1 followpins and M1-to-M5 stacks already belong to core_lower_pg_nojog.tcl."
    } else {
        if {$refresh_stdcell_core_pins} {
            puts "Refreshing same-layer M1 corePin rails after standard-cell insertion or movement."
        } else {
            puts "Building same-layer M1 corePin rails before lower core PG ownership is established."
        }
        setSrouteMode -reset
        setSrouteMode \
            -viaConnectToShape {ring stripe blockring}

        sroute \
            -connect {corePin} \
            -nets {VDD VSS} \
            -corePinCheckStdcellGeoms \
            -corePinLayer M1 \
            -allowJogging 0 \
            -allowLayerChange 0
    }

    editTrim -nets {VDD VSS}
    clearDrc

    if {$report_file ne ""} {
        run_pg_connectivity_verify $report_file
        assert_clean_pg_connectivity_report $report_file
    }
}

proc verify_core_pg_after_filler_nojog {{report_file ""}} {
    global STDCELL_CORE_PG_BUILT

    if {![info exists STDCELL_CORE_PG_BUILT] || !$STDCELL_CORE_PG_BUILT} {
        error "Cannot verify post-filler PG before the lower core PG is built"
    }

    # Filler cells introduce new M1 VDD/VSS pins after the prior PG stitch.
    # Refresh only M1 core-pin rails and trim redundant PG shapes, using the
    # same restricted sequence that is clean after post-CTS ECO insertion.
    # The SRAM M4/M5 deterministic edge taps remain geometry-owned by
    # sram_island_power.tcl; this procedure never invokes blockPin routing,
    # floatingStripe routing, jogging, or layer changes.
    connect_core_pg_pins_nojog $report_file 1
}

proc configure_sram_clock_top_routing {sram_ptrs {clock_pin "clk"}} {
    if {[llength $sram_ptrs] == 0} {
        error "Cannot configure SRAM clock routing without SRAM instances"
    }
    set configured_pins 0
    foreach sram_ptr $sram_ptrs {
        set sram_name [lindex [dbGet $sram_ptr.name] 0]
        set clock_pin_name "${sram_name}/${clock_pin}"
        set clock_pin_collection [get_pins -quiet $clock_pin_name]

        if {[sizeof_collection $clock_pin_collection] != 1} {
            error "Expected one SRAM clock pin named $clock_pin_name"
        }

        incr configured_pins
    }

    # SRAM macro clock ports are stop pins in this design, not clock-tree sink
    # pins.  Applying routing_top_fanout_count to them produces IMPCCOPT-4395
    # and has no effect.  The global routing_top_min_fanout setting in the
    # master flow controls the shared macro clock trunk instead.
    puts "Validated $configured_pins SRAM clock pins; top-layer CTS routing uses the global fanout threshold."
}

proc assert_filler_inserted {{prefix "FILLER"}} {
    set filler_names [dbGet top.insts.name ${prefix}*]
    if {$filler_names eq "" || $filler_names eq "0x0" ||
        [llength $filler_names] == 0} {
        error "No filler instances with prefix ${prefix} were inserted"
    }
}
