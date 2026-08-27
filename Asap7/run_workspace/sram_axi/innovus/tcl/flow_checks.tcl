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

    set fp [open $report_file rb]
    fconfigure $fp -translation binary
    set report_text [read $fp]
    close $fp

    if {[string equal -nocase [file extension $report_file] ".gz"]} {
        if {[catch {set report_text [zlib gunzip $report_text]} gzip_error]} {
            error "Cannot decompress $report_label report [file normalize $report_file]: $gzip_error"
        }
    }
    return $report_text
}

proc si_glitch_violation_count {report_file} {
    set report_text [read_report_text $report_file "SI glitch"]
    if {![regexp -nocase \
        {Total number of glitch violations:[[:space:]]*([0-9]+)} \
        $report_text -> violation_count]} {
        error "Cannot find SI glitch count in [file normalize $report_file]"
    }
    return $violation_count
}

proc publish_si_glitch_report {source_report output_report} {
    set report_text [read_report_text $source_report "SI glitch"]
    set violation_count [si_glitch_violation_count $source_report]

    file mkdir [file dirname $output_report]
    set fp [open $output_report w]
    puts -nonewline $fp $report_text
    close $fp

    puts "SI glitch report: $violation_count violation(s) -> [file normalize $output_report]"
    return $violation_count
}

proc assert_clean_si_glitch_report {report_file} {
    set violation_count [si_glitch_violation_count $report_file]
    if {$violation_count != 0} {
        error "SI analysis has $violation_count glitch violation(s); inspect [file normalize $report_file]"
    }
}

proc require_zero_si_glitches {} {
    if {[info exists ::env(INNOVUS_REQUIRE_ZERO_SI)]} {
        switch -nocase -- $::env(INNOVUS_REQUIRE_ZERO_SI) {
            1 - true - yes - on  { return 1 }
            0 - false - no - off { return 0 }
            default {
                error "INNOVUS_REQUIRE_ZERO_SI must be 0/1, false/true, no/yes or off/on"
            }
        }
    }

    if {[info exists ::SI_SIGNOFF_MODEL_COMPLETE]} {
        return [expr {$::SI_SIGNOFF_MODEL_COMPLETE ? 1 : 0}]
    }
    return 0
}

proc assert_si_glitch_policy {report_file stage_label} {
    set violation_count [si_glitch_violation_count $report_file]
    set ::SI_LAST_VIOLATION_COUNT $violation_count

    if {$violation_count == 0} {
        set ::SI_GATE_STATUS "CLEAN"
        return
    }

    if {[require_zero_si_glitches]} {
        set ::SI_GATE_STATUS "STRICT_FAIL_${violation_count}_VIOLATIONS"
        error "$stage_label SI analysis has $violation_count glitch violation(s); inspect [file normalize $report_file]"
    }

    set ::SI_GATE_STATUS "REPORT_ONLY_${violation_count}_VIOLATIONS"
    puts stderr "SI DIAGNOSTIC: $stage_label has $violation_count glitch violation(s)."
    puts stderr "The loaded library set has incomplete noise characterization, so SI does not block metal fill."
    puts stderr "Inspect [file normalize $report_file]; use INNOVUS_REQUIRE_ZERO_SI=1 only with complete noise models."
}

proc si_glitch_victim_nets {report_file} {
    set report_text [read_report_text $report_file "SI glitch"]
    set victim_nets {}

    foreach line [split $report_text "\n"] {
        set line [string trim $line]
        if {$line eq "" || [string match "#*" $line] ||
            [string match -nocase "NetName*" $line] ||
            [string match -nocase "Total number of glitch violations:*" $line]} {
            continue
        }

        set fields [regexp -all -inline {\S+} $line]
        if {[llength $fields] >= 5} {
            lappend victim_nets [lindex $fields 0]
        }
    }

    return [lsort -unique $victim_nets]
}

proc repair_si_glitches_after_hold {design report_dir plain_report} {
    file mkdir $report_dir
    timeDesign -postRoute -outDir $report_dir

    set si_report "${report_dir}/${design}_postRoute.SI_Glitches.rpt.gz"
    set violation_count [publish_si_glitch_report $si_report $plain_report]
    if {$violation_count == 0} {
        puts "Post-hold SI recovery is not required."
        return 0
    }

    set victim_nets [si_glitch_victim_nets $si_report]
    if {[llength $victim_nets] == 0} {
        error "SI report contains $violation_count violation(s), but no victim nets could be parsed"
    }

    # Hold ECO routing can recreate coupling after the normal post-route glitch
    # phase. Start with two tracks of extra spacing, then give any remaining
    # victims a final three-track routing-only pass.
    foreach victim_net $victim_nets {
        setAttribute -net $victim_net -preferred_extra_space 2
    }
    puts "Applied extra SI spacing to [llength $victim_nets] post-hold victim net(s)."

    setNanoRouteMode -quiet \
        -route_with_timing_driven true \
        -route_with_si_driven true \
        -route_detail_post_route_spread_wire true
    routeDesign -wireOpt
    setNanoRouteMode -quiet -route_detail_post_route_spread_wire auto

    setOptMode \
        -fixGlitch true \
        -reclaimArea false
    optDesign -postRoute -drv

    set remaining_report_dir "${report_dir}_remaining"
    file mkdir $remaining_report_dir
    timeDesign -postRoute -outDir $remaining_report_dir
    set remaining_report \
        "${remaining_report_dir}/${design}_postRoute.SI_Glitches.rpt.gz"
    set remaining_count [si_glitch_violation_count $remaining_report]
    if {$remaining_count != 0} {
        set remaining_victims [si_glitch_victim_nets $remaining_report]
        foreach victim_net $remaining_victims {
            setAttribute -net $victim_net -preferred_extra_space 3
        }
        puts "Applied final SI spacing to [llength $remaining_victims] remaining victim net(s)."
        setNanoRouteMode -quiet \
            -route_with_timing_driven true \
            -route_with_si_driven true \
            -route_detail_post_route_spread_wire true
        routeDesign -wireOpt
        setNanoRouteMode -quiet -route_detail_post_route_spread_wire auto
    }

    return $violation_count
}

proc publish_metal_fill_density_status {report_file status_file} {
    set report_text [read_report_text $report_file "metal-fill density"]
    set in_after_fill_section 0
    set layer_rows {}
    set total_under 0
    set total_over 0

    foreach line [split $report_text "\n"] {
        if {[string first "After filling" $line] >= 0} {
            set in_after_fill_section 1
            continue
        }
        if {!$in_after_fill_section} {
            continue
        }

        if {[regexp {^Layer ([^ ]+) - Number of windows under minimum density \(([^)]+)\): ([0-9]+) out of total ([0-9]+)} \
            $line -> layer threshold under_count window_count]} {
            dict set layer_rows $layer under $under_count
            dict set layer_rows $layer total $window_count
            dict set layer_rows $layer minimum $threshold
            incr total_under $under_count
        } elseif {[regexp {^Layer ([^ ]+) - Number of windows over maximum density[[:space:]]+\(([^)]+)\): ([0-9]+) out of total ([0-9]+)} \
            $line -> layer threshold over_count window_count]} {
            dict set layer_rows $layer over $over_count
            dict set layer_rows $layer maximum $threshold
            incr total_over $over_count
        }
    }

    if {[dict size $layer_rows] == 0} {
        error "Cannot parse after-fill density rows in [file normalize $report_file]"
    }

    file mkdir [file dirname $status_file]
    set fp [open $status_file w]
    puts $fp "# Innovus abstract-view metal density status"
    puts $fp "# Status: PENDING_MERGED_GDS_SIGNOFF"
    puts $fp "# Source: [file normalize $report_file]"
    puts $fp "# The SRAM LEF OBS blocks fill but does not provide the SRAM GDS internal metal."
    puts $fp "# Run density signoff on the top-level GDS merged with all SRAM and standard-cell GDS views."
    puts $fp "# Total under-minimum windows in abstract view: $total_under"
    puts $fp "# Total over-maximum windows in abstract view: $total_over"
    foreach layer [lsort -dictionary [dict keys $layer_rows]] {
        set row [dict get $layer_rows $layer]
        puts $fp [format \
            "%-4s under=%-5s total=%-5s min=%-5s over=%-5s max=%s" \
            $layer \
            [dict get $row under] \
            [dict get $row total] \
            [dict get $row minimum] \
            [dict get $row over] \
            [dict get $row maximum]]
    }
    close $fp

    puts "Metal density status: under=$total_under over=$total_over -> [file normalize $status_file]"
    return [dict create under $total_under over $total_over]
}

proc assert_clean_timing_summary {report_file analysis_label {check_drvs 0}} {
    set report_text [read_report_text $report_file "$analysis_label timing"]

    if {![regexp {\|[[:space:]]*Violating Paths:[[:space:]]*\|[[:space:]]*([0-9]+)} \
        $report_text -> violating_paths]} {
        error "Cannot find violating-path count in $analysis_label timing report: [file normalize $report_file]"
    }
    if {$violating_paths != 0} {
        error "$analysis_label timing has $violating_paths violating path(s); inspect [file normalize $report_file]"
    }

    if {!$check_drvs} {
        return
    }

    set real_drv_violations {}
    foreach drv_type {max_cap max_tran max_fanout max_length} {
        set drv_pattern [format {\|[[:space:]]*%s[[:space:]]*\|[[:space:]]*([0-9]+)[[:space:]]*\(} $drv_type]
        if {![regexp $drv_pattern $report_text -> real_net_count]} {
            error "Cannot find real $drv_type count in timing report: [file normalize $report_file]"
        }
        if {$real_net_count != 0} {
            lappend real_drv_violations "$drv_type=$real_net_count"
        }
    }

    if {[llength $real_drv_violations] != 0} {
        error "$analysis_label timing has real DRV violations ([join $real_drv_violations {, }]); inspect [file normalize $report_file] and the matching .cap/.tran/.fanout report"
    }
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

proc assert_expected_unfilled_pg_connectivity_report {report_file {max_violations 500}} {
    set report_text [read_report_text $report_file "pre-filler PG connectivity"]

    if {[string first "Found no problems or warnings" $report_text] >= 0 ||
        [regexp {Verification Complete[[:space:]]*:[[:space:]]*0[[:space:]]+Viols} $report_text]} {
        return
    }
    if {![string is integer -strict $max_violations] || $max_violations <= 0} {
        error "max_violations must be a positive integer, got $max_violations"
    }
    if {![regexp {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viols} \
        $report_text -> violation_count]} {
        set violation_count 0
        set saw_problem_summary 0
        foreach line [split $report_text "\n"] {
            if {[regexp {^[[:space:]]*([0-9]+)[[:space:]]+Problem\(s\)[[:space:]]+\(IMPVFC-[0-9]+\):} \
                $line -> problem_count]} {
                incr violation_count $problem_count
                set saw_problem_summary 1
            }
        }
        if {!$saw_problem_summary} {
            error "Cannot find violation count in pre-filler PG report: [file normalize $report_file]"
        }
    }
    if {$violation_count > $max_violations} {
        error "Pre-filler PG connectivity exceeded the expected gap limit: $violation_count > $max_violations in [file normalize $report_file]"
    }
    if {[regexp -nocase {shorted} $report_text]} {
        error "Pre-filler PG connectivity contains a short: [file normalize $report_file]"
    }

    set allowed_problem_codes {92 94 96 200}
    foreach line [split $report_text "\n"] {
        set trimmed_line [string trim $line]
        if {[regexp {^Net[[:space:]]+([^,[:space:]:]+)} $trimmed_line -> net_name] &&
            [lsearch -exact {VDD VSS} $net_name] < 0} {
            error "Unexpected net $net_name in pre-filler PG report: [file normalize $report_file]"
        }
        if {[regexp {^Net[[:space:]]} $trimmed_line] &&
            [regexp -nocase {dangling[[:space:]]+Wire} $trimmed_line] &&
            ![regexp -nocase {on[[:space:]]+layer:[[:space:]]+M1([[:space:]]|$)} $trimmed_line]} {
            error "Pre-filler PG report contains a dangling wire above M1: $trimmed_line"
        }
        if {[regexp {Problem\(s\).+\(IMPVFC-([0-9]+)\)} $trimmed_line -> problem_code] &&
            [lsearch -exact $allowed_problem_codes $problem_code] < 0} {
            error "Unexpected IMPVFC-$problem_code in pre-filler PG report: [file normalize $report_file]"
        }
    }

    puts "INFO: $report_file has $violation_count expected pre-filler M1 rail-gap marker(s); strict PG connectivity is deferred until filler insertion."
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

    # The deterministic SRAM taps may already be complete while the standard-
    # cell M1/M5 and upper M6-M9 handoff is still intentionally deferred until
    # after placement.  At that one checkpoint, classify IMPVFC-200 open pieces
    # below instead of treating the completed SRAM stitch as proof that the
    # whole PG network must already be final.
    if {!$allow_preplacement_special_opens} {
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

proc defer_preroute_pg_drc_check {report_file stage \
    {baseline_report "./verify_rpt/pg_drc_after_trim_full.rpt"}} {
    # PG geometry is read-only after the clean post-placement baseline.  Before
    # routeDesign, Innovus verify_drc also reports temporary regular trial-route
    # interactions with special PG, so those markers are not a PG signoff gate.
    assert_clean_pg_special_drc_report $baseline_report

    file mkdir [file dirname $report_file]
    set fp [open $report_file w]
    puts $fp "# Deferred pre-route PG/signal interaction DRC"
    puts $fp "# Stage: $stage"
    puts $fp "# Status: NOT_RUN_BEFORE_DETAILED_ROUTE"
    puts $fp "# Clean intrinsic PG baseline: [file normalize $baseline_report]"
    puts $fp "# Reason: verify_drc -check_only special includes regular trial-route versus special-PG interactions before routeDesign can legalize signal routing."
    puts $fp "# Final gate: drc_postroute.rpt and connectivity_postroute.rpt after routeDesign/ecoRoute."
    close $fp

    puts "INFO: Deferred $stage PG/signal interaction DRC until after detailed routing; intrinsic PG baseline remains clean."
}

proc verify_antenna_if_enabled {report_file} {
    global ANTENNA_CHECK_STATUS

    if {![info exists ::env(INNOVUS_RUN_ANTENNA_CHECK)] ||
        ![string is true -strict $::env(INNOVUS_RUN_ANTENNA_CHECK)]} {
        set ANTENNA_CHECK_STATUS "SKIPPED_NO_RULES"
        write_skipped_report $report_file \
            "INNOVUS_RUN_ANTENNA_CHECK is not enabled. ASAP7 educational LEFs used by this flow do not provide process antenna keywords, and Innovus TCR says verify_antenna requires those rules."
        puts "Antenna check skipped: set INNOVUS_RUN_ANTENNA_CHECK=1 only when antenna rules are loaded."
        return 0
    }

    if {[catch {verify_antenna -report $report_file} antenna_error]} {
        if {[string first "no process antenna information" $antenna_error] >= 0 ||
            [string first "IMPVPA-22" $antenna_error] >= 0} {
            set ANTENNA_CHECK_STATUS "SKIPPED_NO_RULES"
            write_skipped_report $report_file \
                "Skipped because Innovus reported no process antenna information for this design."
            puts "Antenna check skipped: no process antenna information is loaded."
            return 0
        }
        return -code error $antenna_error
    }

    set ANTENNA_CHECK_STATUS "CHECKED_REVIEW_REPORT"
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

proc connect_core_pg_pins_nojog {{report_file ""} {post_insertion_checkpoint 0} \
    {allow_unfilled_row_gaps 0}} {
    global STDCELL_CORE_PG_BUILT

    applyGlobalNets
    puts "Floating PG stripe stitching is disabled by construction."

    connect_sram_block_pins_to_local_stripes_nojog

    if {![string is boolean -strict $post_insertion_checkpoint]} {
        error "post_insertion_checkpoint must be boolean, got $post_insertion_checkpoint"
    }
    if {![string is boolean -strict $allow_unfilled_row_gaps]} {
        error "allow_unfilled_row_gaps must be boolean, got $allow_unfilled_row_gaps"
    }
    if {$allow_unfilled_row_gaps && !$post_insertion_checkpoint} {
        error "allow_unfilled_row_gaps is valid only at a post-insertion checkpoint"
    }

    if {[info exists STDCELL_CORE_PG_BUILT] &&
        ![string is boolean -strict $STDCELL_CORE_PG_BUILT]} {
        error "STDCELL_CORE_PG_BUILT must be boolean, got $STDCELL_CORE_PG_BUILT"
    }
    set core_pg_is_built [expr {
        [info exists STDCELL_CORE_PG_BUILT] && $STDCELL_CORE_PG_BUILT
    }]
    if {$post_insertion_checkpoint && !$core_pg_is_built} {
        error "Cannot run a post-insertion PG checkpoint before the lower core PG is built"
    }
    set trim_pg_geometry [expr {
        !$core_pg_is_built || !$post_insertion_checkpoint
    }]
    if {$core_pg_is_built} {
        # Standard-cell, CTS, ECO, and filler PG pins connect by overlap to the
        # continuous M1 followpins already owned by core_lower_pg_nojog.tcl.
        # Re-running corePin sroute after the M1-to-M9 mesh exists lets ViaGen
        # stitch followpins to unrelated upper stripes.  In the failing run it
        # created 54 V1-V5 stacks plus 757 V6 cuts, leaving M4 off-grid patches
        # and dangling M6 shapes.  A post-build refresh must therefore remain
        # read-only even when new physical-only cells were inserted.
        if {$post_insertion_checkpoint} {
            puts "CorePin sroute refresh skipped: inserted cells inherit the existing continuous M1 followpins by overlap."
        } else {
            puts "CorePin reconnect skipped: M1 followpins and M1-to-M5 stacks already belong to core_lower_pg_nojog.tcl."
        }
    } else {
        puts "Building same-layer M1 corePin rails before lower core PG ownership is established."
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

    if {$trim_pg_geometry} {
        editTrim -nets {VDD VSS}
    } else {
        puts "Post-insertion PG checkpoint is read-only: editTrim skipped."
    }
    clearDrc

    if {$report_file ne ""} {
        run_pg_connectivity_verify $report_file
        if {$allow_unfilled_row_gaps} {
            assert_expected_unfilled_pg_connectivity_report $report_file
        } else {
            assert_clean_pg_connectivity_report $report_file
        }
    }
}

proc verify_core_pg_after_filler_nojog {{report_file ""}} {
    global STDCELL_CORE_PG_BUILT

    if {![info exists STDCELL_CORE_PG_BUILT] || !$STDCELL_CORE_PG_BUILT} {
        error "Cannot verify post-filler PG before the lower core PG is built"
    }

    # Filler cells inherit the continuous M1 followpins by overlap.  Reapply
    # global-net rules and verify without creating or trimming special-route
    # geometry.  The SRAM M4/M5 deterministic edge taps remain geometry-owned
    # by sram_island_power.tcl.
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

############################################################
## Merged-GDS master checks
##
## streamOut -merge matches merged structures to design masters by exact
## name and has no cell-name remapping parameter.  A name mismatch is
## reported only as IMPOGDS-217/218, which does not stop the run, so the
## exported top-level GDS silently loses the macro geometry.  These procs
## turn that warning into a hard stop before stream-out.
############################################################

# Pad a GDS ASCII name to an even byte count, as the format requires.
proc gds_pad_name {name} {
    if {[string length $name] % 2} {
        return "${name}\x00"
    }
    return $name
}

# Every structure name defined in a GDS file, in definition order.
# Walks record headers and seeks over payloads, so cost scales with the
# record count rather than the file size.
proc gds_structure_names {gds_file} {
    if {![file exists $gds_file]} {
        error "Cannot read structure names: missing GDS file $gds_file"
    }
    set fh [open $gds_file rb]
    fconfigure $fh -translation binary
    set names {}
    while {1} {
        set head [read $fh 4]
        if {[string length $head] < 4} {
            break
        }
        binary scan $head Sucucu reclen rtype rdtype
        if {$reclen < 4} {
            break
        }
        set payload [expr {$reclen - 4}]
        if {$rtype == 6 && $rdtype == 6} {
            set raw ""
            if {$payload > 0} {
                set raw [read $fh $payload]
            }
            lappend names [string trimright $raw "\x00"]
        } else {
            if {$payload > 0} {
                seek $fh $payload current
            }
            # ENDLIB
            if {$rtype == 4 && $rdtype == 0} {
                break
            }
        }
    }
    close $fh
    return $names
}

# Fast membership test: look for the exact STRNAME record bytes for this
# name instead of walking every record.
proc gds_has_structure {gds_file structure_name} {
    if {![file exists $gds_file]} {
        error "Cannot search structures: missing GDS file $gds_file"
    }
    set padded [gds_pad_name $structure_name]
    set pattern [binary format Scc [expr {4 + [string length $padded]}] 6 6]
    append pattern $padded
    set pattern_length [string length $pattern]

    set fh [open $gds_file rb]
    fconfigure $fh -translation binary
    set chunk_size [expr {8 * 1024 * 1024}]
    set carry ""
    set found 0
    while {![eof $fh]} {
        set chunk [read $fh $chunk_size]
        if {$chunk eq ""} {
            break
        }
        if {[string first $pattern "${carry}${chunk}"] >= 0} {
            set found 1
            break
        }
        set carry [string range $chunk end-[expr {$pattern_length - 2}] end]
    }
    close $fh
    return $found
}

# Report the structure names a GDS actually defines.  Never called from
# anywhere reachable by init_design: viewDefinition.tcl is evaluated inside
# init_design, and an error raised there aborts it with no design in memory.
proc report_gds_missing_structure {gds_file structure_name {context ""}} {
    set label $gds_file
    if {$context ne ""} {
        set label "$context ($gds_file)"
    }
    set present [gds_structure_names $gds_file]
    set shown $present
    if {[llength $present] > 20} {
        set shown [concat [lrange $present 0 19] \
            [list "... and [expr {[llength $present] - 20}] more"]]
    }
    puts "GDS $label does not define structure '$structure_name'."
    puts "  Structures found: [join $shown {, }]"
    puts "  Inspect the file with:"
    puts "    python3 ./scripts/gds_structure_tool.py list $gds_file"
    return $present
}

# Which hard-macro masters are absent from the merge list.  Returns a list of
# master names; empty means the merged stream-out is complete.
proc merge_gds_missing_masters {merge_gds_files} {
    set macro_masters {}
    foreach inst_ptr [dbGet -p -e top.insts.cell.isBlock 1] {
        set master [lindex [dbGet $inst_ptr.cell.name] 0]
        if {$master ne "" && [lsearch -exact $macro_masters $master] < 0} {
            lappend macro_masters $master
        }
    }
    if {[llength $macro_masters] == 0} {
        return {}
    }

    set missing {}
    foreach master $macro_masters {
        set found 0
        foreach gds_file $merge_gds_files {
            if {[file exists $gds_file] && [gds_has_structure $gds_file $master]} {
                set found 1
                break
            }
        }
        if {!$found} {
            lappend missing $master
        }
    }
    return $missing
}

# Stream-out gate.  Warns by default and returns the missing masters so the
# caller can record them in the handoff report; a hollow GDS is a real
# problem, but refusing to export removes the only artifact the run produced.
# Set ASAP7_REQUIRE_MERGED_MACRO_GDS=1 to make it fatal instead.
proc check_merge_gds_masters {merge_gds_files} {
    set missing [merge_gds_missing_masters $merge_gds_files]
    if {[llength $missing] == 0} {
        puts "Merged-GDS master check passed; every hard macro is defined in the merge files."
        return {}
    }

    set summary "Merged stream-out will drop [llength $missing] macro master(s): [join $missing {, }].\
This is the IMPOGDS-217/218 failure mode: the merge files are readable but none\
defines a structure with the master's exact name, so the exported GDS carries\
empty outlines where the macros belong."

    set strict 0
    if {[info exists ::env(ASAP7_REQUIRE_MERGED_MACRO_GDS)]} {
        switch -nocase -- $::env(ASAP7_REQUIRE_MERGED_MACRO_GDS) {
            1 - true - yes - on { set strict 1 }
        }
    }
    if {$strict} {
        error $summary
    }

    puts "WARNING: $summary"
    foreach gds_file $merge_gds_files {
        if {![file exists $gds_file]} {
            continue
        }
        foreach master $missing {
            if {![gds_has_structure $gds_file $master]} {
                puts "  $gds_file has no '$master'"
            }
        }
    }
    puts "  List what a merge file really contains:"
    puts "    python3 ./scripts/gds_structure_tool.py list <file.gds>"
    puts "  Set ASAP7_REQUIRE_MERGED_MACRO_GDS=1 to make this fatal."
    return $missing
}

############################################################
## SRAM clock leaf routing
##
## Every CTS leaf net that ends on an SRAM clock pin has to cross the hard
## place blockage that covers the whole macro island, so its driver sits on
## the island boundary and the branch can run several hundred microns.  On
## the M2/M3 leaf route type that length produced 0.104-0.115 ns slew at
## pins whose Liberty max_transition is 0.046 ns (IMPCCOPT-1007).  Promote
## exactly those nets to M6/M7, which the SRAM LEF leaves unobstructed.
############################################################
proc constrain_sram_clock_leaf_routing {sram_ptrs {clock_pin "clk"}
                                        {bottom_layer 6} {top_layer 7}
                                        {report_file ""}} {
    if {[llength $sram_ptrs] == 0} {
        error "Cannot constrain SRAM clock routing without SRAM instances"
    }
    if {![string is integer -strict $bottom_layer] ||
        ![string is integer -strict $top_layer] ||
        $bottom_layer < 2 || $top_layer < $bottom_layer} {
        error "Invalid SRAM clock routing-layer range: ${bottom_layer}:${top_layer}"
    }

    set rows {}
    set seen {}
    foreach inst_ptr $sram_ptrs {
        set inst_name [lindex [dbGet $inst_ptr.name] 0]
        set clock_term_name ""
        set clock_net_name ""

        foreach inst_term_ptr [dbGet -e $inst_ptr.instTerms] {
            set term_name [lindex [dbGet $inst_term_ptr.name] 0]
            if {![regexp "(^|/)${clock_pin}\$" $term_name]} {
                continue
            }
            set net_name [lindex [dbGet $inst_term_ptr.net.name] 0]
            if {$net_name eq "" || $net_name eq "0x0"} {
                error "SRAM clock pin $term_name is not connected to a net"
            }
            set clock_term_name $term_name
            set clock_net_name $net_name
            break
        }

        if {$clock_net_name eq ""} {
            error "No ${clock_pin} instTerm found on SRAM instance $inst_name"
        }
        if {[lsearch -exact $seen $clock_net_name] >= 0} {
            continue
        }
        lappend seen $clock_net_name

        if {[catch {
            setAttribute \
                -net $clock_net_name \
                -bottom_preferred_routing_layer $bottom_layer \
                -top_preferred_routing_layer $top_layer \
                -preferred_routing_layer_effort high
        } attribute_error]} {
            error "Cannot set clock routing policy on net $clock_net_name: $attribute_error"
        }
        lappend rows [list $clock_net_name $clock_term_name]
    }

    if {$report_file ne ""} {
        file mkdir [file dirname $report_file]
        set fh [open $report_file w]
        puts $fh "clock_pin $clock_pin"
        puts $fh "preferred_layers M${bottom_layer}:M${top_layer}"
        puts $fh "preferred_effort high"
        puts $fh "constrained_net_count [llength $rows]"
        puts $fh "net sram_clock_term"
        foreach row $rows {
            puts $fh [list [lindex $row 0] [lindex $row 1]]
        }
        close $fh
        puts "SRAM clock leaf route report: $report_file"
    }

    puts "Constrained [llength $rows] SRAM clock leaf net(s) to M${bottom_layer}:M${top_layer}."
    return [llength $rows]
}

############################################################
## Signoff metal fill
##
## setMetalFill / addMetalFill / fill_setting_save are obsolete
## (IMPMF-5050 / IMPMF-5045 / IMPMF-5054) and Cadence replaces them with
## the Pegasus-backed add_metal_fill_signoff flow.  That flow needs a
## Pegasus/PVS fill rule deck or a named PVS technology; the ASAP7
## educational PDK ships neither, so the selection below stays automatic
## and reports which engine actually ran instead of failing the flow.
############################################################

# Path to a Pegasus/PVS fill rule deck, or "" when none is configured.
proc metal_fill_signoff_rule_file {} {
    if {[info exists ::env(ASAP7_PEGASUS_FILL_RULE_FILE)] &&
        $::env(ASAP7_PEGASUS_FILL_RULE_FILE) ne ""} {
        return $::env(ASAP7_PEGASUS_FILL_RULE_FILE)
    }
    return ""
}

# Named PVS technology, an alternative to a rule deck.
proc metal_fill_signoff_technology {} {
    if {[info exists ::env(ASAP7_PEGASUS_FILL_TECHNOLOGY)] &&
        $::env(ASAP7_PEGASUS_FILL_TECHNOLOGY) ne ""} {
        return $::env(ASAP7_PEGASUS_FILL_TECHNOLOGY)
    }
    return ""
}

# Why the signoff engine can or cannot run, as a human-readable reason.
proc metal_fill_signoff_readiness {} {
    set rule_file [metal_fill_signoff_rule_file]
    set technology [metal_fill_signoff_technology]

    if {$rule_file eq "" && $technology eq ""} {
        return [list 0 "no ASAP7_PEGASUS_FILL_RULE_FILE and no ASAP7_PEGASUS_FILL_TECHNOLOGY"]
    }
    if {$rule_file ne "" && ![file exists $rule_file]} {
        return [list 0 "rule file does not exist: [file normalize $rule_file]"]
    }
    if {[info commands add_metal_fill_signoff] eq ""} {
        return [list 0 "add_metal_fill_signoff is not available in this Innovus installation"]
    }
    if {$rule_file ne ""} {
        return [list 1 "rule file [file normalize $rule_file]"]
    }
    return [list 1 "PVS technology $technology"]
}

# Resolve the requested engine.  Returns "signoff", "legacy" or "skip".
proc metal_fill_engine {} {
    set mode auto
    if {[info exists ::env(INNOVUS_METAL_FILL_MODE)] &&
        $::env(INNOVUS_METAL_FILL_MODE) ne ""} {
        set mode [string tolower $::env(INNOVUS_METAL_FILL_MODE)]
    }
    if {[lsearch -exact {auto signoff legacy skip} $mode] < 0} {
        error "INNOVUS_METAL_FILL_MODE must be auto, signoff, legacy or skip"
    }

    # Back-compatible override: INNOVUS_RUN_LEGACY_METAL_FILL=0 means an
    # external flow owns fill, so skip it here.
    if {$mode eq "auto" && [info exists ::env(INNOVUS_RUN_LEGACY_METAL_FILL)]} {
        switch -nocase -- $::env(INNOVUS_RUN_LEGACY_METAL_FILL) {
            0 - false - no - off { return "skip" }
            1 - true - yes - on  { }
            default {
                error "INNOVUS_RUN_LEGACY_METAL_FILL must be 0/1, false/true, no/yes or off/on"
            }
        }
    }

    lassign [metal_fill_signoff_readiness] ready reason

    switch -- $mode {
        skip    { return "skip" }
        legacy  { return "legacy" }
        signoff {
            if {!$ready} {
                error "INNOVUS_METAL_FILL_MODE=signoff but the signoff fill engine is unusable: $reason"
            }
            return "signoff"
        }
        auto {
            if {$ready} {
                puts "Metal fill: using the signoff engine ($reason)."
                return "signoff"
            }
            puts "Metal fill: falling back to the obsolete in-design engine because $reason."
            puts "Metal fill: set ASAP7_PEGASUS_FILL_RULE_FILE or ASAP7_PEGASUS_FILL_TECHNOLOGY to use add_metal_fill_signoff."
            return "legacy"
        }
    }
}

# Run the Pegasus-backed fill and load the result into the design.
proc run_metal_fill_signoff {layer_map_file report_file {work_dir ./pegasus_fill}} {
    lassign [metal_fill_signoff_readiness] ready reason
    if {!$ready} {
        error "Cannot run signoff metal fill: $reason"
    }
    if {![file exists $layer_map_file]} {
        error "Cannot run signoff metal fill: missing layer map $layer_map_file"
    }

    set rule_file [metal_fill_signoff_rule_file]
    set technology [metal_fill_signoff_technology]

    file mkdir $work_dir
    file mkdir [file dirname $report_file]

    set_metal_fill_signoff_mode -reset all

    # Density floors mirror MINIMUMDENSITY in the project tech LEF.  Window
    # size and step stay with the rule deck, which is the only place per-layer
    # windows can be expressed.
    set_metal_fill_signoff_mode \
        -layer_map_file $layer_map_file \
        -min_density {25 {M1 M2 M3} 10 M4 15 M5 25 {M6 M7 M8 M9} 20 Pad} \
        -temp_working_dir $work_dir \
        -report_file $report_file

    set fill_args [list -fill -fill_output_mode gdsii]
    if {$rule_file ne ""} {
        lappend fill_args -rule_file $rule_file
    } else {
        lappend fill_args -technology $technology
    }

    eval add_metal_fill_signoff $fill_args

    # Bring the hierarchical fill database back into the Innovus design so
    # extraction, timing and verify_drc see the same shapes signoff will.
    add_metal_fill_signoff -auto_load_fills

    puts "Signoff metal fill completed using $reason."
    return $report_file
}
