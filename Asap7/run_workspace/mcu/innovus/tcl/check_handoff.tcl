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
    set pattern [format {(^|\n)[ \t]*%s[ \t]+[^;\n]*\(} $master]
    set count [regexp -all -- $pattern $text]
    if {$count != $expected} {
        error "Genus handoff has $count instances of $master; expected $expected"
    }
    puts "Validated Genus handoff SRAM count: $count"
}

