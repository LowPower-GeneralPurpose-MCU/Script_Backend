############################################################
## Static/mock checks for the targeted SRAM wdata transition ECO.
############################################################

set SRAM_MASTER srambank_256x4x32_6t122
set SRAM_COUNT 16
set SRAM_ISLAND_LLX 2.16
set SRAM_ISLAND_URX 500.688
set SRAM_ISLAND_BLOCKAGE_URY 706.86
set ASAP7_ROW_HEIGHT 0.27
set core_ury 770.832
set SRAM_WDATA_TRANSITION_ECO_ENABLE 1
set SRAM_WDATA_TRANSITION_ECO_REPORT ./reports/__tmp_wdata_transition_eco.rpt
set MOCK_PARTITIONED 0
set MOCK_ECO_CALL_COUNT 0
set MOCK_ECO_ARGS {}

proc dbGet {args} {
    global MOCK_PARTITIONED

    if {[lindex $args 0] eq "-p2"} {
        set result {}
        for {set index 0} {$index < 16} {incr index} {
            lappend result "inst$index"
        }
        return $result
    }
    if {[lindex $args 0] eq "-e"} {
        regexp {inst([0-9]+)\.instTerms} [lindex $args 1] -> index
        return "term$index"
    }

    set query [lindex $args 0]
    if {[regexp {^inst([0-9]+)\.name$} $query -> index]} {
        return "u_mem/G_SRAM_BANK\[$index\].u_sram"
    }
    if {[regexp {^term([0-9]+)\.name$} $query -> index]} {
        return "u_mem/G_SRAM_BANK\[$index\].u_sram/wd\[11\]"
    }
    if {[regexp {^term([0-9]+)\.net\.name$} $query -> index]} {
        if {$index < 8} {
            return "u_mem/lower_wdata11_$index"
        }
        if {$MOCK_PARTITIONED && $index >= 12} {
            return u_mem/already_partitioned_wdata11
        }
        return u_mem/FE_OFN163_mem_wdata_11
    }

    error "Unexpected dbGet query: $args"
}

proc ecoAddRepeater {args} {
    global MOCK_ECO_CALL_COUNT MOCK_ECO_ARGS
    incr MOCK_ECO_CALL_COUNT
    set MOCK_ECO_ARGS $args
}

proc read_mock_report {path} {
    set fp [open $path r]
    set text [read $fp]
    close $fp
    return $text
}

source ./tcl/sram_wdata_transition_eco.tcl

if {$MOCK_ECO_CALL_COUNT != 1} {
    error "Expected one targeted ecoAddRepeater call, got $MOCK_ECO_CALL_COUNT"
}
foreach expected {
    -term
    -loc
    -radius
    -cell
    BUFx24_ASAP7_75t_L
} {
    if {[lsearch -exact $MOCK_ECO_ARGS $expected] < 0} {
        error "Missing '$expected' in ecoAddRepeater arguments: $MOCK_ECO_ARGS"
    }
}
set loc_index [expr {[lsearch -exact $MOCK_ECO_ARGS -loc] + 1}]
if {[lindex $MOCK_ECO_ARGS $loc_index] ne {251.424 707.13}} {
    error "Targeted ECO location is not in the legal top strip: $MOCK_ECO_ARGS"
}
set report_text [read_mock_report $SRAM_WDATA_TRANSITION_ECO_REPORT]
if {[string first {status applied} $report_text] < 0} {
    error "Targeted ECO report does not record an applied repair"
}

set MOCK_PARTITIONED 1
source ./tcl/sram_wdata_transition_eco.tcl
if {$MOCK_ECO_CALL_COUNT != 1} {
    error "Already-partitioned SRAM branch must not receive another repeater"
}
set report_text [read_mock_report $SRAM_WDATA_TRANSITION_ECO_REPORT]
if {[string first {status skipped_already_partitioned} $report_text] < 0} {
    error "Targeted ECO report does not record the idempotent skip"
}

file delete -force $SRAM_WDATA_TRANSITION_ECO_REPORT
puts "PASS: SRAM write-data transition ECO targets the legal top strip and is idempotent"
