proc check_sram_library_cell {master} {
    set matches {}
    foreach cell_obj [get_db lib_cells] {
        set cell_name [get_db $cell_obj .name]
        if {[string match "*$master*" $cell_name]} {
            lappend matches $cell_obj
        }
    }
    if {[llength $matches] != 1} {
        error "Expected one loaded library cell for $master, found [llength $matches]"
    }
    puts "Loaded SRAM library cell: [get_db [lindex $matches 0] .name]"
}

proc check_sram_mapped_netlist {netlist master expected} {
    if {![file isfile $netlist]} {
        error "Mapped netlist does not exist: $netlist"
    }
    set fp [open $netlist r]
    set text [read $fp]
    close $fp

    set pattern [format {(^|\n)[ \t]*%s[ \t]+[^;\n]*\(} $master]
    set count [regexp -all -- $pattern $text]
    puts "Mapped SRAM instances: $count (expected $expected)"
    if {$count != $expected} {
        error "Mapped SRAM count mismatch for $master"
    }
}

