############################################################
## Targeted SRAM write-data transition ECO
##
## Routed RC leaves one repeatable real max-transition violation on the
## wdata[11] branch feeding banks 8-15.  Split the upper macro row from that
## branch before filler insertion, when Innovus can still place the repeater
## without a filler-cell conflict.
############################################################

foreach required_variable {
    SRAM_MASTER SRAM_COUNT
    SRAM_ISLAND_LLX SRAM_ISLAND_URX SRAM_ISLAND_BLOCKAGE_URY
    ASAP7_ROW_HEIGHT core_ury
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable before SRAM write-data ECO"
    }
}

if {![info exists SRAM_WDATA_TRANSITION_ECO_ENABLE]} {
    set SRAM_WDATA_TRANSITION_ECO_ENABLE 1
}
if {![info exists SRAM_WDATA_TRANSITION_ECO_BIT]} {
    set SRAM_WDATA_TRANSITION_ECO_BIT 11
}
if {![info exists SRAM_WDATA_TRANSITION_ECO_SOURCE_BANKS]} {
    set SRAM_WDATA_TRANSITION_ECO_SOURCE_BANKS {8 9 10 11 12 13 14 15}
}
if {![info exists SRAM_WDATA_TRANSITION_ECO_SINK_BANKS]} {
    set SRAM_WDATA_TRANSITION_ECO_SINK_BANKS {12 13 14 15}
}
if {![info exists SRAM_WDATA_TRANSITION_ECO_CELL]} {
    set SRAM_WDATA_TRANSITION_ECO_CELL BUFx24_ASAP7_75t_L
}
if {![info exists SRAM_WDATA_TRANSITION_ECO_PLACE_RADIUS]} {
    set SRAM_WDATA_TRANSITION_ECO_PLACE_RADIUS 24.0
}
if {![info exists SRAM_WDATA_TRANSITION_ECO_REPORT]} {
    set SRAM_WDATA_TRANSITION_ECO_REPORT ./reports/sram_wdata_transition_eco.rpt
}

if {![string is boolean -strict $SRAM_WDATA_TRANSITION_ECO_ENABLE]} {
    error "SRAM_WDATA_TRANSITION_ECO_ENABLE must be boolean"
}
if {![string is integer -strict $SRAM_WDATA_TRANSITION_ECO_BIT] ||
    $SRAM_WDATA_TRANSITION_ECO_BIT < 0 || $SRAM_WDATA_TRANSITION_ECO_BIT > 31} {
    error "SRAM_WDATA_TRANSITION_ECO_BIT must be in the range 0..31"
}
if {![string is double -strict $SRAM_WDATA_TRANSITION_ECO_PLACE_RADIUS] ||
    $SRAM_WDATA_TRANSITION_ECO_PLACE_RADIUS <= 0.0} {
    error "SRAM_WDATA_TRANSITION_ECO_PLACE_RADIUS must be positive"
}

# The hard SRAM-island placement blockage extends through the inter-macro
# channels.  Put the ECO search point one row into the legal top logic strip,
# centered over the four upper-row sinks, and let Innovus legalize nearby.
set sram_wdata_eco_x [expr {0.5 * ($SRAM_ISLAND_LLX + $SRAM_ISLAND_URX)}]
set sram_wdata_eco_y [expr {$SRAM_ISLAND_BLOCKAGE_URY + $ASAP7_ROW_HEIGHT}]
if {$sram_wdata_eco_y >= $core_ury} {
    error "No legal top-strip row is available for the SRAM write-data ECO"
}
set sram_wdata_eco_location [list $sram_wdata_eco_x $sram_wdata_eco_y]

set sram_wdata_eco_ptrs [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {$sram_wdata_eco_ptrs eq "" || $sram_wdata_eco_ptrs eq "0x0"} {
    error "No SRAM instances found before SRAM write-data ECO"
}
if {[llength $sram_wdata_eco_ptrs] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros before SRAM write-data ECO; found [llength $sram_wdata_eco_ptrs]"
}

array set sram_wdata_eco_net_by_bank {}
array set sram_wdata_eco_term_by_bank {}
set sram_wdata_eco_term_pattern [format {(^|/)wd\[%d\]$} $SRAM_WDATA_TRANSITION_ECO_BIT]

foreach inst_ptr $sram_wdata_eco_ptrs {
    set inst_name [lindex [dbGet $inst_ptr.name] 0]
    if {![regexp {G_SRAM_BANK\[([0-9]+)\]\.u_sram$} $inst_name -> bank_index]} {
        continue
    }

    foreach inst_term_ptr [dbGet -e $inst_ptr.instTerms] {
        set term_name [lindex [dbGet $inst_term_ptr.name] 0]
        if {![regexp $sram_wdata_eco_term_pattern $term_name]} {
            continue
        }

        set net_name [lindex [dbGet $inst_term_ptr.net.name] 0]
        if {$net_name eq "" || $net_name eq "0x0"} {
            error "SRAM bank $bank_index wd\[$SRAM_WDATA_TRANSITION_ECO_BIT\] is unconnected"
        }
        if {[string first "$inst_name/" $term_name] != 0} {
            set term_name "$inst_name/$term_name"
        }

        set sram_wdata_eco_net_by_bank($bank_index) $net_name
        set sram_wdata_eco_term_by_bank($bank_index) $term_name
        break
    }
}

foreach bank_index $SRAM_WDATA_TRANSITION_ECO_SOURCE_BANKS {
    if {![info exists sram_wdata_eco_net_by_bank($bank_index)]} {
        error "Cannot find bank $bank_index wd\[$SRAM_WDATA_TRANSITION_ECO_BIT\] for SRAM transition ECO"
    }
}

set sram_wdata_eco_source_net $sram_wdata_eco_net_by_bank([lindex $SRAM_WDATA_TRANSITION_ECO_SOURCE_BANKS 0])
set sram_wdata_eco_same_branch 1
foreach bank_index $SRAM_WDATA_TRANSITION_ECO_SOURCE_BANKS {
    if {$sram_wdata_eco_net_by_bank($bank_index) ne $sram_wdata_eco_source_net} {
        set sram_wdata_eco_same_branch 0
        break
    }
}

file mkdir [file dirname $SRAM_WDATA_TRANSITION_ECO_REPORT]
set sram_wdata_eco_fh [open $SRAM_WDATA_TRANSITION_ECO_REPORT w]
puts $sram_wdata_eco_fh "enabled $SRAM_WDATA_TRANSITION_ECO_ENABLE"
puts $sram_wdata_eco_fh "bit $SRAM_WDATA_TRANSITION_ECO_BIT"
puts $sram_wdata_eco_fh "source_banks $SRAM_WDATA_TRANSITION_ECO_SOURCE_BANKS"
puts $sram_wdata_eco_fh "sink_banks $SRAM_WDATA_TRANSITION_ECO_SINK_BANKS"
puts $sram_wdata_eco_fh "source_net $sram_wdata_eco_source_net"

if {!$SRAM_WDATA_TRANSITION_ECO_ENABLE} {
    puts $sram_wdata_eco_fh "status disabled"
    close $sram_wdata_eco_fh
    puts "SRAM write-data transition ECO is disabled."
} elseif {!$sram_wdata_eco_same_branch} {
    puts $sram_wdata_eco_fh "status skipped_already_partitioned"
    close $sram_wdata_eco_fh
    puts "SRAM wd\[$SRAM_WDATA_TRANSITION_ECO_BIT\] banks are already partitioned; targeted repeater skipped."
} else {
    set sram_wdata_eco_sink_terms {}
    foreach bank_index $SRAM_WDATA_TRANSITION_ECO_SINK_BANKS {
        if {[lsearch -exact $SRAM_WDATA_TRANSITION_ECO_SOURCE_BANKS $bank_index] < 0} {
            close $sram_wdata_eco_fh
            error "ECO sink bank $bank_index is not in the source-bank set"
        }
        lappend sram_wdata_eco_sink_terms $sram_wdata_eco_term_by_bank($bank_index)
    }

    puts $sram_wdata_eco_fh "sink_terms $sram_wdata_eco_sink_terms"
    puts $sram_wdata_eco_fh "cell $SRAM_WDATA_TRANSITION_ECO_CELL"
    puts $sram_wdata_eco_fh "location $sram_wdata_eco_location"
    puts $sram_wdata_eco_fh "place_radius $SRAM_WDATA_TRANSITION_ECO_PLACE_RADIUS"

    if {[catch {
        ecoAddRepeater \
            -term $sram_wdata_eco_sink_terms \
            -loc $sram_wdata_eco_location \
            -radius $SRAM_WDATA_TRANSITION_ECO_PLACE_RADIUS \
            -cell $SRAM_WDATA_TRANSITION_ECO_CELL
    } sram_wdata_eco_error]} {
        puts $sram_wdata_eco_fh "status failed"
        puts $sram_wdata_eco_fh "error $sram_wdata_eco_error"
        close $sram_wdata_eco_fh
        error "SRAM write-data transition ECO failed: $sram_wdata_eco_error"
    }

    puts $sram_wdata_eco_fh "status applied"
    close $sram_wdata_eco_fh
    puts "Inserted $SRAM_WDATA_TRANSITION_ECO_CELL on $sram_wdata_eco_source_net for SRAM banks $SRAM_WDATA_TRANSITION_ECO_SINK_BANKS."
}
