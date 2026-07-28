

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set PV_DIR     [file normalize [file join $SCRIPT_DIR ..]]
set SETUP_FILE [file join $PV_DIR project_setup.tcl]

if {![file exists $SETUP_FILE]} {
    puts "ERROR: project_setup.tcl not found:"
    puts "       $SETUP_FILE"
    exit 1
}

source $SETUP_FILE

foreach var {
    HGVAR_DESIGN
    HGVAR_SIGNOFF_NETLIST_PWR
    HGVAR_STDCELL_CDL
    HGVAR_SRAM_CDL
    HGVAR_FLASH_CDL
    HGVAR_HCELL_LIST_FILE
    HGVAR_LVS_HCELL_LIST_APPEND
    HGVAR_LVS_HCELL_LIST_FILES
} {
    if {![info exists $var]} {
        puts "ERROR: Required variable $var is not defined in project_setup.tcl"
        exit 1
    }
}

set DESIGN          $HGVAR_DESIGN
set INPUT_NETLIST   $HGVAR_SIGNOFF_NETLIST_PWR
set OUT_LVS_NETLIST "${DESIGN}.v2lvs.net"
set OUT_SRC_NETLIST "${DESIGN}.src.net"
set HCELL_FILE      $HGVAR_HCELL_LIST_FILE

if {![file exists $INPUT_NETLIST]} {
    puts "ERROR: Input post-PnR netlist not found:"
    puts "       $INPUT_NETLIST"
    exit 1
}

# ----------------------------
# Collect CDL files
# ----------------------------
set CDL_LIST [list]

foreach lib_ckt [concat $HGVAR_STDCELL_CDL $HGVAR_SRAM_CDL $HGVAR_FLASH_CDL] {
    if {$lib_ckt ne ""} {
        if {[file exists $lib_ckt]} {
            puts "INFO: CDL found: $lib_ckt"
            lappend CDL_LIST $lib_ckt
        } else {
            puts "ERROR: CDL file does not exist:"
            puts "       $lib_ckt"
            exit 1
        }
    }
}

if {[llength $CDL_LIST] == 0} {
    puts "ERROR: No CDL file found. LVS needs standard-cell CDL."
    exit 1
}

# ============================================================
# Generate hcell.list
# ============================================================
puts "============================================================"
puts "Generating hcell.list: $HCELL_FILE"
puts "============================================================"

if {[file exists $HCELL_FILE]} {
    file delete -force $HCELL_FILE
}

set OF [open $HCELL_FILE w]
array set seen {}

proc add_hcell_pair {OF layout_cell source_cell} {
    upvar seen seen

    set layout_cell [string trim $layout_cell]
    set source_cell [string trim $source_cell]

    if {$layout_cell eq "" || $source_cell eq ""} {
        return
    }

    if {[string match "#*" $layout_cell]} {
        return
    }

    set key "$layout_cell|$source_cell"

    if {![info exists seen($key)]} {
        puts $OF "$layout_cell $source_cell"
        set seen($key) 1
    }
}

proc add_hcell_line {OF line} {
    set line [string trim $line]

    if {$line eq ""} {
        return
    }

    if {[string match "#*" $line]} {
        return
    }

    set toks [regexp -all -inline {\S+} $line]

    if {[llength $toks] >= 2} {
        add_hcell_pair $OF [lindex $toks 0] [lindex $toks 1]
    } elseif {[llength $toks] == 1} {
        set cell [lindex $toks 0]
        add_hcell_pair $OF $cell $cell
    }
}

# Top hcell
add_hcell_pair $OF $DESIGN $DESIGN

# Manually appended hcells
foreach cell $HGVAR_LVS_HCELL_LIST_APPEND {
    add_hcell_pair $OF $cell $cell
}

# Additional hcell files
foreach hfile $HGVAR_LVS_HCELL_LIST_FILES {
    if {[file exists $hfile]} {
        puts "INFO: Reading hcell file: $hfile"
        set IF [open $hfile r]
        while {[gets $IF line] >= 0} {
            add_hcell_line $OF $line
        }
        close $IF
    } else {
        puts "WARNING: hcell file not found, skipped:"
        puts "         $hfile"
    }
}

close $OF

puts "INFO: Generated $HCELL_FILE"

# ============================================================
# Build v2lvs commands
# ============================================================
set V2LVS_CMD          [list v2lvs -64 -sn]
set V2LVS_CMD_SPICESIM [list v2lvs -64 -sn -i -sl]

foreach cdl $CDL_LIST {
    lappend V2LVS_CMD -s $cdl

    lappend V2LVS_CMD_SPICESIM -lsr $cdl
    lappend V2LVS_CMD_SPICESIM -s $cdl
}

lappend V2LVS_CMD -o $OUT_LVS_NETLIST
lappend V2LVS_CMD -v $INPUT_NETLIST

lappend V2LVS_CMD_SPICESIM -o $OUT_SRC_NETLIST
lappend V2LVS_CMD_SPICESIM -v $INPUT_NETLIST

puts "============================================================"
puts "V2LVS command:"
puts "$V2LVS_CMD"
puts "============================================================"

if {[catch {exec {*}$V2LVS_CMD} result]} {
    puts "ERROR: v2lvs failed while generating $OUT_LVS_NETLIST"
    puts $result
    exit 1
} else {
    puts $result
}

puts "============================================================"
puts "V2LVS SPICESIM command:"
puts "$V2LVS_CMD_SPICESIM"
puts "============================================================"

if {[catch {exec {*}$V2LVS_CMD_SPICESIM} result]} {
    puts "ERROR: v2lvs failed while generating $OUT_SRC_NETLIST"
    puts $result
    exit 1
} else {
    puts $result
}

if {![file exists $OUT_LVS_NETLIST]} {
    puts "ERROR: Output LVS netlist was not generated:"
    puts "       $OUT_LVS_NETLIST"
    exit 1
}

if {![file exists $OUT_SRC_NETLIST]} {
    puts "ERROR: Output source netlist was not generated:"
    puts "       $OUT_SRC_NETLIST"
    exit 1
}

puts "============================================================"
puts "V2LVS completed successfully"
puts "Generated:"
puts "  $OUT_LVS_NETLIST"
puts "  $OUT_SRC_NETLIST"
puts "  $HCELL_FILE"
puts "============================================================"

exit 0
