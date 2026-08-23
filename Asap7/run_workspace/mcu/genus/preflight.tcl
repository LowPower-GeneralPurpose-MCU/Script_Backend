############################################################
## Plain-Tcl collateral and RTL preflight
## Run with: tclsh preflight.tcl
############################################################

set GENUS_DIR [file dirname [file normalize [info script]]]
cd $GENUS_DIR

source [file join $GENUS_DIR tcl project_config.tcl]
source [file join $GENUS_DIR tcl rtl_filelist.tcl]

proc read_text_file {path} {
    set fp [open $path r]
    set text [read $fp]
    close $fp
    return $text
}

set required_files [concat \
    $STD_LIBS \
    [list $SRAM_LIB $SDC_FILE]]

set missing {}
foreach required $required_files {
    if {![file isfile $required]} {
        lappend missing $required
    }
}

if {[llength $missing] > 0} {
    puts stderr "PRECHECK FAILED: missing ASAP7 collateral:"
    foreach path $missing {
        puts stderr " - [file normalize $path]"
        if {[file isfile "$path.7z"]} {
            puts stderr "   Found compressed archive $path.7z; extract it first."
        }
    }
    puts stderr "Set ASAP7_ROOT to a directory containing both pinned repositories."
    error "Missing [llength $missing] required collateral files"
}

set clint_header [file join $RTL_ROOT interrupt CLINT clint_defines.vh]
if {![file isfile $clint_header]} {
    error "Linux case-sensitive include is missing: $clint_header"
}

if {[lsearch -exact $RTL_FILES $SRAM_SIM_VERILOG] >= 0} {
    error "The behavioral SRAM reg-array model must not be synthesized"
}

set wrapper_file [file join $RTL_ROOT memory asap7_sram_128k_1rw.v]
set wrapper_text [read_text_file $wrapper_file]
if {![regexp {module[ \t\r\n]+asap7_sram_128k_1rw} $wrapper_text] ||
    ![regexp {i[ \t]*<[ \t]*32} $wrapper_text] ||
    ![regexp $SRAM_MASTER $wrapper_text]} {
    error "128-KiB SRAM wrapper contract is inconsistent"
}

set axi_ram_text [read_text_file [file join $RTL_ROOT memory axi_ram.v]]
if {![regexp {asap7_sram_128k_1rw[ \t\r\n]+u_mem} $axi_ram_text]} {
    error "axi_ram is not connected to the 128-KiB hard-macro wrapper"
}

set top_text [read_text_file [file join $RTL_ROOT top_soc.v]]
if {![regexp {ADDR_MASK[ \t\r\n]*\([ \t\r\n]*32'h0001_FFFF} $top_text] ||
    ![regexp {MEM_DEPTH[ \t\r\n]*\([ \t\r\n]*32768} $top_text]} {
    error "top_soc no longer exposes the intended 128-KiB AXI RAM"
}

set sram_lib_text [read_text_file $SRAM_LIB]
if {![regexp [format {cell[ \t\r\n]*\([ \t\r\n]*%s[ \t\r\n]*\)} $SRAM_MASTER] \
    $sram_lib_text]} {
    error "SRAM Liberty does not contain cell $SRAM_MASTER"
}

puts "============================================================"
puts "MCU PRECHECK PASSED"
puts " - Top                 : $TOP"
puts " - Standard-cell rev   : $ASAP7_STDCELL_REVISION"
puts " - SRAM rev            : $ASAP7_SRAM_REVISION"
puts " - SRAM master/count   : $SRAM_MASTER / $SRAM_EXPECTED_COUNT"
puts " - SRAM capacity       : $SRAM_CAPACITY_BYTES bytes"
puts " - RTL files           : [llength $RTL_FILES]"
puts "============================================================"

set missing_physical {}
foreach physical_view [concat \
    $CELL_LEFS \
    [list $TECH_LEF $QRC_FILE $SRAM_LEF $SRAM_GDS]] {
    if {![file isfile $physical_view]} {
        lappend missing_physical $physical_view
    }
}
if {[llength $missing_physical] > 0} {
    puts "NOTICE: Genus can run, but Innovus collateral is incomplete:"
    foreach path $missing_physical {
        puts " - [file normalize $path]"
    }
    puts "Run innovus/preflight.tcl after the physical views are installed."
}
