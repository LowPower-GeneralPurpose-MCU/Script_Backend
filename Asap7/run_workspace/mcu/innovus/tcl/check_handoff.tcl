proc read_binary_file {path label} {
    if {![file isfile $path]} {
        error "Missing $label: [file normalize $path]"
    }
    set fp [open $path rb]
    fconfigure $fp -translation binary
    set data [read $fp]
    close $fp
    return $data
}

proc check_mapped_sram_count {netlist master expected} {
    set text [read_binary_file $netlist "Genus netlist"]
    # write_hdl xuong dong truoc ten instance khi ten escaped qua dai, nen
    # '(' khong chac nam cung dong voi ten module.  Pattern doi '(' cung dong
    # bo qua dung 12 macro cache trong generate block -> 72/84 gia.  Xem
    # check_sram_mapped_netlist trong genus/tcl/genus.tcl.
    regsub -all {[ \t\r\n]+} $text " " flat
    set escaped_master [string map {. \\.} $master]
    set count 0
    foreach stmt [split $flat ";"] {
        if {[regexp -- "^ ?$escaped_master\[ \t\]" $stmt]} {
            incr count
        }
    }
    if {$count != $expected} {
        error "Genus handoff has $count instances of $master; expected $expected"
    }
    puts "Validated Genus handoff SRAM count: $count"
}

proc verilog_identifier_pattern {name} {
    return [format {(^|[^A-Za-z0-9_$])%s([^A-Za-z0-9_$]|$)} $name]
}

proc check_text_has_identifiers {label text names} {
    foreach name $names {
        if {![regexp -- [verilog_identifier_pattern $name] $text]} {
            error "$label is missing required identifier '$name'"
        }
    }
}

proc check_text_lacks_identifiers {label text names} {
    foreach name $names {
        if {[regexp -- [verilog_identifier_pattern $name] $text]} {
            error "$label still contains obsolete identifier '$name'"
        }
    }
}

proc check_top_io_handoff {netlist sdc} {
    set netlist_text [read_binary_file $netlist "Genus netlist"]
    set sdc_text     [read_binary_file $sdc "Genus SDC"]

    # 2026-09-11: I2C/UART/SPI/PWM/GPIO di qua 32 pad cua apb_pinmux, nen
    # bo ba chan chia se duy nhat cua nhom do la pad_in/pad_out/pad_oe.
    # (Khong them uart_tx, i2c_scl_i... vao obsolete: ten do van con la net
    # noi bo cua top_soc trong netlist phang.)
    set required_ports {
        pad_in pad_out pad_oe
        flash_io_i flash_io_o flash_io_oe
        sdram_dq_i sdram_dq_o sdram_dq_oe
    }
    set obsolete_ports {
        i2c_scl i2c_sda flash_io sdram_dq
    }

    check_text_has_identifiers "Genus netlist" $netlist_text $required_ports
    check_text_lacks_identifiers "Genus netlist" $netlist_text $obsolete_ports
    check_text_has_identifiers "Genus SDC" $sdc_text $required_ports
    check_text_lacks_identifiers "Genus SDC" $sdc_text $obsolete_ports

    if {[regexp {(^|\n)[ \t]*inout[ \t]} $netlist_text]} {
        error "Genus netlist still contains an inout declaration; Innovus flow expects split I/O signals"
    }

    puts "Validated split top-level I/O handoff"
}
