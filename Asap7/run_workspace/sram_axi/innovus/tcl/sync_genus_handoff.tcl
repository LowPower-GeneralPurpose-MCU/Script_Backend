############################################################
## Validate and synchronize the Genus-to-Innovus handoff.
############################################################

proc read_binary_file {path label} {
    if {![file exists $path]} {
        error "Missing $label: [file normalize $path]"
    }

    set fp [open $path rb]
    fconfigure $fp -translation binary
    set data [read $fp]
    close $fp
    return $data
}

proc copy_file_if_different {src dst label} {
    set src_data [read_binary_file $src $label]
    set needs_copy 1

    if {[file exists $dst]} {
        set dst_data [read_binary_file $dst "local $label"]
        set needs_copy [expr {$src_data ne $dst_data}]
    }

    if {$needs_copy} {
        file mkdir [file dirname $dst]
        file copy -force $src $dst
        puts "Synchronized $label: [file normalize $src] -> [file normalize $dst]"
    } else {
        puts "Genus handoff $label is already synchronized: [file normalize $dst]"
    }
}

proc assert_genus_transition_handoff {genus_sdc expected_max_transition_ns} {
    if {[llength [info commands innovus_sdc_time_scale_from_unit]] == 0} {
        error "Source prepare_innovus_sdc.tcl before validating the Genus handoff"
    }
    if {![string is double -strict $expected_max_transition_ns] ||
        $expected_max_transition_ns <= 0.0} {
        error "Expected max transition must be positive, got '$expected_max_transition_ns'"
    }

    set sdc_text [read_binary_file $genus_sdc "Genus SDC"]
    if {![regexp {set_units[ \t\r\n]+-time[ \t\r\n]+([^ \t\r\n]+)} \
        $sdc_text -> source_time_unit]} {
        error "Cannot find the time unit in Genus SDC: [file normalize $genus_sdc]"
    }
    if {![regexp {set_max_transition[ \t\r\n]+([-+0-9.eE]+)[ \t\r\n]+\[current_design\]} \
        $sdc_text -> source_max_transition]} {
        error "Cannot find the design max-transition constraint in Genus SDC: [file normalize $genus_sdc]"
    }
    if {![string is double -strict $source_max_transition]} {
        error "Invalid max-transition value '$source_max_transition' in [file normalize $genus_sdc]"
    }

    set time_scale [innovus_sdc_time_scale_from_unit $source_time_unit]
    set actual_max_transition_ns [expr {double($source_max_transition) * $time_scale}]
    if {abs($actual_max_transition_ns - $expected_max_transition_ns) > 0.0000001} {
        error "Stale Genus handoff: [file normalize $genus_sdc] contains [innovus_sdc_format_number $actual_max_transition_ns] ns max transition, expected [innovus_sdc_format_number $expected_max_transition_ns] ns. Rerun Genus before Innovus."
    }

    puts "Validated Genus max-transition handoff: [innovus_sdc_format_number $actual_max_transition_ns] ns"
}

proc sync_genus_handoff {
    genus_netlist genus_sdc innovus_netlist innovus_sdc expected_max_transition_ns
} {
    assert_genus_transition_handoff $genus_sdc $expected_max_transition_ns
    copy_file_if_different $genus_netlist $innovus_netlist "Genus netlist"
    copy_file_if_different $genus_sdc $innovus_sdc "Genus SDC"
}
