############################################################
## SRAM macro verification helpers
############################################################

proc check_sram_library_cell {master} {
    puts "===================================================="
    puts "CHECK SRAM LIBRARY CELL"
    puts "===================================================="

    set matches {}

    foreach cell_obj [get_db lib_cells] {
        set cell_name [get_db $cell_obj .name]

        if {[string match "*${master}*" $cell_name]} {
            lappend matches $cell_obj

            puts "Found SRAM library cell:"
            puts " - object : $cell_obj"
            puts " - name   : $cell_name"

            if {![catch {set area [get_db $cell_obj .area]}]} {
                puts " - area   : $area"
            }

            if {![catch {set dont_use [get_db $cell_obj .dont_use]}]} {
                puts " - dont_use : $dont_use"
            }
        }
    }

    if {[llength $matches] == 0} {
        error "No loaded library cell matches SRAM master: $master"
    }

    puts "SRAM library match count: [llength $matches]"
    puts "===================================================="

    return $matches
}

proc check_sram_mapped_netlist {netlist master expected} {
    if {![file exists $netlist]} {
        error "Mapped netlist does not exist: $netlist"
    }

    set fd [open $netlist r]
    set text [read $fd]
    close $fd

    # Count lines beginning with the SRAM master followed by an instance name.
    # This excludes a possible 'module <master>' declaration.
    set pattern [format {(^|\n)[ \t]*%s[ \t]+[^;\n]*\(} $master]
    set count [regexp -all -- $pattern $text]

    puts "===================================================="
    puts "CHECK MAPPED SRAM INSTANCES"
    puts " - Netlist  : $netlist"
    puts " - Master   : $master"
    puts " - Found    : $count"
    puts " - Expected : $expected"
    puts "===================================================="

    if {$count != $expected} {
        error "Mapped SRAM count mismatch: found $count, expected $expected"
    }
}
