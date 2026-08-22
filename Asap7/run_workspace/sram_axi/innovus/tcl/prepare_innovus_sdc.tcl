############################################################
## Convert Genus SDC units into Innovus-readable ns/pF SDC.
##
## Genus writes set_units in the SDC, but Innovus 23.14 skips that
## command when the file is attached to create_constraint_mode.  Keep the
## synthesis SDC untouched and generate an Innovus-local copy instead.
############################################################

proc innovus_sdc_time_scale_from_unit {unit} {
    set normalized [string tolower [string trim $unit]]

    switch -regexp -- $normalized {
        {^1?fs$}     { return 0.000001 }
        {^10fs$}     { return 0.00001 }
        {^100fs$}    { return 0.0001 }
        {^1?ps$}     { return 0.001 }
        {^10ps$}     { return 0.01 }
        {^100ps$}    { return 0.1 }
        {^1?ns$}     { return 1.0 }
        {^10ns$}     { return 10.0 }
        {^100ns$}    { return 100.0 }
        default {
            error "Unsupported SDC time unit '$unit'; add conversion in prepare_innovus_sdc.tcl"
        }
    }
}

proc innovus_sdc_cap_scale_from_unit {unit} {
    set normalized [string tolower [string trim $unit]]

    switch -regexp -- $normalized {
        {^1?ff$}     { return 0.001 }
        {^10ff$}     { return 0.01 }
        {^100ff$}    { return 0.1 }
        {^1?pf$}     { return 1.0 }
        {^10pf$}     { return 10.0 }
        {^100pf$}    { return 100.0 }
        default {
            error "Unsupported SDC capacitance unit '$unit'; add conversion in prepare_innovus_sdc.tcl"
        }
    }
}

proc innovus_sdc_number_re {} {
    return {[-+]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][-+]?[0-9]+)?}
}

proc innovus_sdc_format_number {value} {
    set text [format %.12g $value]
    if {![string match *.* $text] && ![string match *e* $text] && ![string match *E* $text]} {
        append text ".0"
    }
    return $text
}

proc innovus_sdc_escape_regexp {text} {
    return $text
}

proc innovus_sdc_scale_option_numbers {cmd options scale} {
    set number [innovus_sdc_number_re]
    set ws {[ \t\r\n]}

    foreach opt $options {
        set escaped_opt [innovus_sdc_escape_regexp $opt]
        set pattern "(^|$ws)($escaped_opt)(${ws}+)($number)"
        set out ""
        set start 0

        while {[regexp -indices -start $start -- $pattern $cmd match prefix opt_idx space_idx num_idx]} {
            lassign $num_idx num_start num_end

            append out [string range $cmd $start [expr {$num_start - 1}]]
            set old_value [string range $cmd $num_start $num_end]
            append out [innovus_sdc_format_number [expr {double($old_value) * $scale}]]
            set start [expr {$num_end + 1}]
        }

        append out [string range $cmd $start end]
        set cmd $out
    }

    return $cmd
}

proc innovus_sdc_scale_first_number {cmd scale} {
    set number [innovus_sdc_number_re]
    set ws {[ \t\r\n]}
    set pattern "(^|$ws)($number)"

    if {![regexp -indices -- $pattern $cmd match prefix num_idx]} {
        return $cmd
    }

    lassign $num_idx num_start num_end
    set old_value [string range $cmd $num_start $num_end]

    return "[string range $cmd 0 [expr {$num_start - 1}]][innovus_sdc_format_number [expr {double($old_value) * $scale}]][string range $cmd [expr {$num_end + 1}] end]"
}

proc innovus_sdc_replace_first_number {cmd value} {
    set number [innovus_sdc_number_re]
    set ws {[ \t\r\n]}
    set pattern "(^|$ws)($number)"

    if {![regexp -indices -- $pattern $cmd match prefix num_idx]} {
        error "Cannot find a numeric value in SDC command: [string trim $cmd]"
    }

    lassign $num_idx num_start num_end
    set formatted_value [innovus_sdc_format_number $value]
    return "[string range $cmd 0 [expr {$num_start - 1}]]${formatted_value}[string range $cmd [expr {$num_end + 1}] end]"
}

proc innovus_sdc_scale_waveform {cmd scale} {
    set pattern {(-waveform[ \t\r\n]+\{)([^\}]*)\}}
    set out ""
    set start 0

    while {[regexp -indices -start $start -- $pattern $cmd match head_idx body_idx]} {
        lassign $body_idx body_start body_end

        append out [string range $cmd $start [expr {$body_start - 1}]]

        set scaled_values {}
        foreach value [split [string range $cmd $body_start $body_end]] {
            if {[regexp -- "^[innovus_sdc_number_re]$" $value]} {
                lappend scaled_values [innovus_sdc_format_number [expr {double($value) * $scale}]]
            } else {
                lappend scaled_values $value
            }
        }
        append out [join $scaled_values " "]

        lassign $match match_start match_end
        set start [expr {$body_end + 1}]
    }

    append out [string range $cmd $start end]
    return $out
}

proc innovus_sdc_normalize_command {cmd time_scale cap_scale {max_transition_ns ""}} {
    set trimmed [string trim $cmd]
    if {$trimmed eq ""} {
        return $cmd
    }
    if {[string index $trimmed 0] eq "#"} {
        return $cmd
    }

    if {![regexp {^([^ \t\r\n]+)} $trimmed -> command_name]} {
        return $cmd
    }

    switch -- $command_name {
        create_clock {
            set cmd [innovus_sdc_scale_option_numbers $cmd {-period} $time_scale]
            set cmd [innovus_sdc_scale_waveform $cmd $time_scale]
        }
        set_clock_transition -
        set_input_transition -
        set_input_delay -
        set_output_delay -
        set_clock_latency -
        set_clock_uncertainty -
        set_clock_gating_check {
            set before $cmd
            set cmd [innovus_sdc_scale_option_numbers $cmd {-min -max -early -late -setup -hold} $time_scale]
            if {$cmd eq $before &&
                ($command_name eq "set_clock_transition" ||
                 $command_name eq "set_input_transition" ||
                 $command_name eq "set_clock_uncertainty")} {
                set cmd [innovus_sdc_scale_first_number $cmd $time_scale]
            }
        }
        set_max_transition -
        set_min_pulse_width {
            set before $cmd
            set cmd [innovus_sdc_scale_option_numbers $cmd {-min -max -high -low} $time_scale]
            if {$cmd eq $before} {
                set cmd [innovus_sdc_scale_first_number $cmd $time_scale]
            }
            if {$command_name eq "set_max_transition" && $max_transition_ns ne ""} {
                set cmd [innovus_sdc_replace_first_number $cmd $max_transition_ns]
            }
        }
        set_load {
            set before $cmd
            set cmd [innovus_sdc_scale_option_numbers $cmd {-pin_load -wire_load} $cap_scale]
            if {$cmd eq $before} {
                set cmd [innovus_sdc_scale_first_number $cmd $cap_scale]
            }
        }
        set_max_capacitance {
            set before $cmd
            set cmd [innovus_sdc_scale_option_numbers $cmd {-min -max} $cap_scale]
            if {$cmd eq $before} {
                set cmd [innovus_sdc_scale_first_number $cmd $cap_scale]
            }
        }
    }

    return $cmd
}

proc prepare_innovus_sdc {src_sdc out_sdc group_path_file {max_transition_ns ""}} {
    if {![file exists $src_sdc]} {
        error "Missing source SDC: [file normalize $src_sdc]"
    }
    if {$max_transition_ns ne "" &&
        (![string is double -strict $max_transition_ns] || $max_transition_ns <= 0.0)} {
        error "max_transition_ns must be a positive number, got '$max_transition_ns'"
    }

    set input_file [open $src_sdc r]
    set raw_data [read $input_file]
    close $input_file

    set time_scale 1.0
    set cap_scale 1.0
    set output_commands {}
    set group_commands {}
    set command_buffer ""

    foreach line [split $raw_data "\n"] {
        append command_buffer [string trimright $line "\r"] "\n"

        if {![info complete $command_buffer]} {
            continue
        }

        set trimmed [string trim $command_buffer]

        if {[regexp {^set_units[ \t\r\n]+-time[ \t\r\n]+([^ \t\r\n]+)} $trimmed -> unit]} {
            set time_scale [innovus_sdc_time_scale_from_unit $unit]
        } elseif {[regexp {^set_units[ \t\r\n]+-capacitance[ \t\r\n]+([^ \t\r\n]+)} $trimmed -> unit]} {
            set cap_scale [innovus_sdc_cap_scale_from_unit $unit]
        } elseif {[regexp {^group_path(?:[ \t\r\n]|$)} $trimmed]} {
            lappend group_commands $command_buffer
        } else {
            lappend output_commands [innovus_sdc_normalize_command \
                $command_buffer $time_scale $cap_scale $max_transition_ns]
        }

        set command_buffer ""
    }

    if {[string trim $command_buffer] ne ""} {
        error "Incomplete Tcl command at end of $src_sdc"
    }

    file mkdir [file dirname $out_sdc]
    set out_file [open $out_sdc w]
    puts $out_file "# Generated from $src_sdc for Innovus."
    puts $out_file "# Numeric timing values are in ns; capacitance values are in pF."
    if {$max_transition_ns ne ""} {
        puts $out_file "# Project max-transition override: [innovus_sdc_format_number $max_transition_ns] ns."
    }
    puts $out_file "# Do not edit by hand; rerun prepare_innovus_sdc.tcl."
    foreach command $output_commands {
        puts -nonewline $out_file $command
        if {![string match *\n $command]} {
            puts $out_file ""
        }
    }
    close $out_file

    file mkdir [file dirname $group_path_file]
    set group_file [open $group_path_file w]
    puts $group_file "# Generated global path groups from $src_sdc."
    puts $group_file "# Innovus does not honor group_path inside create_constraint_mode SDC files."
    foreach command $group_commands {
        puts -nonewline $group_file $command
        if {![string match *\n $command]} {
            puts $group_file ""
        }
    }
    close $group_file

    puts "Generated Innovus SDC: $out_sdc (time scale $time_scale ns/source-unit, cap scale $cap_scale pF/source-unit)"
    if {$max_transition_ns ne ""} {
        puts "Applied project max-transition override: [innovus_sdc_format_number $max_transition_ns] ns"
    }
    puts "Generated global path groups: $group_path_file ([llength $group_commands] commands)"
}
