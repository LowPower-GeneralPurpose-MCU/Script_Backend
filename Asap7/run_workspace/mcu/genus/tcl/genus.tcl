############################################################
## Cadence Genus synthesis flow for MCU top_soc
## ASAP7 RVT + LVT, TT 0.7 V 25 C, 32 SRAM hard macros
############################################################

set GENUS_TCL_DIR [file dirname [file normalize [info script]]]
set GENUS_DIR [file dirname $GENUS_TCL_DIR]
set FLOW_ROOT [file dirname $GENUS_DIR]
set RTL_ROOT [file join $GENUS_DIR rtl]
set SDC_FILE [file join $GENUS_TCL_DIR constraint.sdc]
cd $GENUS_DIR

source [file join $RTL_ROOT flow project_config.tcl]
source [file join $GENUS_TCL_DIR rtl_filelist.tcl]

proc genus_env_value {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc genus_env_flag {name default_value} {
    set value [string tolower [genus_env_value $name $default_value]]
    switch -- $value {
        1 - true - yes - on  { return 1 }
        0 - false - no - off { return 0 }
        default { error "$name must be 0/1, false/true, no/yes or off/on" }
    }
}

proc genus_host_cpu_count {cap} {
    set count 0
    if {![catch {open /proc/cpuinfo r} cpu_file]} {
        set count [regexp -all -line {^processor\s} [read $cpu_file]]
        close $cpu_file
    }
    if {$count < 1} {
        set count 1
    }
    if {$count > $cap} {
        set count $cap
    }
    return $count
}

proc genus_try_set_root_attribute {name value} {
    if {[catch {set_db / .$name $value} message]} {
        puts "WARNING: cannot set Genus attribute $name=$value: $message"
        return 0
    }
    return 1
}

proc genus_require_file {label path} {
    if {[file isfile $path]} {
        return
    }
    if {[file isfile "$path.7z"]} {
        error "$label is compressed, extract before running Genus: [file normalize $path.7z]"
    }
    error "Missing $label: [file normalize $path]"
}

proc genus_read_file {path} {
    set fp [open $path r]
    set text [read $fp]
    close $fp
    return $text
}

proc genus_read_prefix {path byte_count} {
    set fp [open $path r]
    set text [read $fp $byte_count]
    close $fp
    return $text
}

proc genus_require_liberty {path {required_cell ""}} {
    genus_require_file "timing Liberty" $path
    if {[file size $path] < 1024} {
        error "Timing Liberty is too small to be valid: [file normalize $path]"
    }
    if {![regexp {library[ \t\r\n]*\(} [genus_read_prefix $path 16384]]} {
        error "Timing Liberty does not start like a Liberty file: [file normalize $path]"
    }
    if {$required_cell ne ""} {
        set liberty_text [genus_read_file $path]
        set cell_pattern [format {cell[ \t\r\n]*\([ \t\r\n]*%s[ \t\r\n]*\)} $required_cell]
        if {![regexp -- $cell_pattern $liberty_text]} {
            error "SRAM Liberty does not contain cell $required_cell: [file normalize $path]"
        }
    }
}

proc genus_require_text {label path pattern} {
    set text [genus_read_file $path]
    if {![regexp -- $pattern $text]} {
        error "$label check failed in [file normalize $path]"
    }
}

proc genus_generate_boot_rom_include {mem_path include_path depth} {
    set address 0
    set word_count 0
    set entries {}
    set seen [dict create]

    foreach raw_line [split [genus_read_file $mem_path] "\n"] {
        set line $raw_line
        regsub {//.*$} $line "" line
        regsub {#.*$} $line "" line
        set line [string trim $line]
        if {$line eq ""} {
            continue
        }

        foreach token [regexp -all -inline {\S+} $line] {
            if {[regexp {^@([0-9A-Fa-f]+)$} $token -> address_text]} {
                scan $address_text %x address
                continue
            }

            regsub -all {_} $token "" word
            if {![regexp {^[0-9A-Fa-f]{1,8}$} $word]} {
                error "Invalid 32-bit boot ROM word '$token' in [file normalize $mem_path]"
            }
            if {$address < 0 || $address >= $depth} {
                error "Boot ROM address $address is outside depth $depth"
            }
            if {[dict exists $seen $address]} {
                error "Duplicate boot ROM address $address in [file normalize $mem_path]"
            }

            dict set seen $address 1
            lappend entries [format "                %d: rom_lookup = 32'h%s;" $address $word]
            incr address
            incr word_count
        }
    }

    if {$word_count == 0} {
        error "Boot ROM image contains no data words: [file normalize $mem_path]"
    }

    set temp_path "$include_path.tmp"
    set fp [open $temp_path w]
    puts $fp "// Generated from boot.mem by tcl/genus.tcl. Do not edit by hand."
    foreach entry $entries {
        puts $fp $entry
    }
    close $fp
    file rename -force $temp_path $include_path
    puts "Generated synthesizable boot ROM table: $word_count words"
    return $word_count
}

proc genus_run_static_checks {} {
    global RTL_FILES RTL_ROOT SDC_FILE SRAM_MASTER SRAM_EXPECTED_COUNT SRAM_CAPACITY_BYTES

    if {[llength $RTL_FILES] != 53} {
        error "Expected exactly 53 RTL files, found [llength $RTL_FILES]"
    }

    set seen [dict create]
    foreach rtl_file $RTL_FILES {
        set normalized_rtl [file normalize $rtl_file]
        if {[dict exists $seen $normalized_rtl]} {
            error "Duplicate RTL file in filelist: $normalized_rtl"
        }
        dict set seen $normalized_rtl 1

        if {[file tail $normalized_rtl] eq "$SRAM_MASTER.v"} {
            error "Do not synthesize the behavioral SRAM model: $normalized_rtl"
        }
    }

    genus_require_file "SDC file" $SDC_FILE
    if {![info complete [genus_read_file $SDC_FILE]]} {
        error "SDC Tcl syntax is incomplete: [file normalize $SDC_FILE]"
    }

    set boot_mem [file join $RTL_ROOT memory boot.mem]
    genus_require_file "boot ROM image" $boot_mem
    if {[file size $boot_mem] == 0} {
        error "Boot ROM image is empty: [file normalize $boot_mem]"
    }
    set boot_include [file join $RTL_ROOT memory boot_rom_image.vh]
    genus_generate_boot_rom_include $boot_mem $boot_include 16384

    set top_file [file join $RTL_ROOT top_soc.v]
    genus_require_text "Boot ROM INIT_FILE" \
        $top_file {\.INIT_FILE[ \t\r\n]*\([ \t\r\n]*"rtl/memory/boot\.mem"[ \t\r\n]*\)}
    genus_require_text "Top-level AXI RAM depth" \
        $top_file {\.MEM_DEPTH[ \t\r\n]*\([ \t\r\n]*32768[ \t\r\n]*\)}

    set axi_rom_file [file join $RTL_ROOT memory axi_rom.v]
    genus_require_text "Synthesizable boot ROM table" \
        $axi_rom_file {`include[ \t]+"memory/boot_rom_image\.vh"}

    set axi_ram_file [file join $RTL_ROOT memory axi_ram.v]
    genus_require_text "AXI RAM default depth" \
        $axi_ram_file {parameter[ \t\r\n]+MEM_DEPTH[ \t\r\n]*=[ \t\r\n]*32768}
    genus_require_text "AXI RAM hard macro wrapper" \
        $axi_ram_file {asap7_sram_128k_1rw[ \t\r\n]+[A-Za-z_][A-Za-z0-9_$]*[ \t\r\n]*\(}

    set sram_wrapper_file [file join $RTL_ROOT memory asap7_sram_128k_1rw.v]
    genus_require_text "SRAM bank address decode" \
        $sram_wrapper_file {addr\[16:12\]}
    genus_require_text "SRAM row address decode" \
        $sram_wrapper_file {addr\[11:2\]}
    genus_require_text "SRAM generated bank count" \
        $sram_wrapper_file {for[ \t\r\n]*\([ \t\r\n]*i[ \t\r\n]*=[ \t\r\n]*0[ \t\r\n]*;[ \t\r\n]*i[ \t\r\n]*<[ \t\r\n]*32}
    genus_require_text "SRAM hard macro instance" \
        $sram_wrapper_file $SRAM_MASTER

    if {$SRAM_EXPECTED_COUNT != 32 || $SRAM_CAPACITY_BYTES != 131072} {
        error "SRAM config must describe 32 macros and 128 KiB"
    }

    foreach clint_file [glob -nocomplain [file join $RTL_ROOT interrupt CLINT *.v]] {
        set clint_text [genus_read_file $clint_file]
        if {[regexp {`include[ \t]+"[^"]*CLINT[^"]*"} $clint_text]} {
            error "CLINT include paths must stay lowercase for Linux: [file normalize $clint_file]"
        }
    }

    puts "MCU static checks passed: 53 RTL files, boot image, SRAM wrapper and SDC"
}

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

genus_run_static_checks
foreach timing_lib $STD_LIBS {
    genus_require_liberty $timing_lib
}
genus_require_liberty $SRAM_LIB $SRAM_MASTER

foreach dir {outputs reports logs} {
    file mkdir $dir
}
foreach pattern {./outputs/* ./reports/* ./logs/*} {
    foreach stale [glob -nocomplain $pattern] {
        file delete -force $stale
    }
}

set_db / .init_lib_search_path [list $STD_LIB_DIR [file dirname $SRAM_LIB]]
set_db / .script_search_path [list $GENUS_TCL_DIR]
set_db / .init_hdl_search_path \
    [concat [list $RTL_ROOT] $RTL_INCLUDE_DIRS]

# Stable default for workstation and license-limited runs.  Enable distributed
# processing only when the Cadence installation and license are configured.
genus_try_set_root_attribute auto_super_thread false
if {[genus_env_flag GENUS_ENABLE_SUPER_THREAD 0]} {
    set GENUS_CPUS [genus_env_value GENUS_CPUS 4]
    if {![string is integer -strict $GENUS_CPUS] || $GENUS_CPUS < 1} {
        error "GENUS_CPUS must be a positive integer"
    }
    set GENUS_SERVERS [genus_env_value GENUS_SUPER_THREAD_SERVERS localhost]
    genus_try_set_root_attribute super_thread_servers $GENUS_SERVERS
    genus_try_set_root_attribute max_cpus_per_server $GENUS_CPUS
    if {[catch {test_super_thread_servers} message]} {
        error "Genus super-thread server check failed: $message"
    }
    puts "Genus execution: super-thread, servers=$GENUS_SERVERS, CPUs=$GENUS_CPUS"
} else {
    catch {reset_db super_thread_servers}
    # max_cpus_per_server 0 switches multi-threading OFF.  The last run
    # logged "Number of threads: 0 * 1" and 100.8% CPU on a 12-CPU host,
    # and Genus had already warned PBS-2 ("should be run with a minimum of
    # 8 threads").  The attribute default is 8.
    #
    # This is local MULTI-threading, not super-threading: no extra servers,
    # no extra licence, and one process image so memory does not multiply
    # (peak was 4.4 GB of 12.9 GB with only 0.7 GB free).
    set GENUS_CPUS [genus_env_value GENUS_CPUS [genus_host_cpu_count 8]]
    if {![string is integer -strict $GENUS_CPUS] || $GENUS_CPUS < 1} {
        error "GENUS_CPUS must be a positive integer"
    }
    genus_try_set_root_attribute max_cpus_per_server $GENUS_CPUS
    puts "Genus execution: single process, $GENUS_CPUS threads"
}

set_db / .hdl_unconnected_value 0
set_db / .hdl_track_filename_row_col true

# hdl_index_mux_threshold defaults to 0, i.e. a variable index read such as
# ram[index] is NEVER built as a binary mux - it is expanded into AND/OR
# logic and blasted.  That is where the 92583 AOI22xp33 cells of the last
# completed run came from (icache/dcache generic_data_ram, ROB beat_mem_q),
# and it is what the repeated "Running post blast mux optimization" lines
# in genus.log are chewing through.  Building proper mux components for
# wide indexed reads usually cuts both area and elaborate/generic runtime.
#
# This changes netlist structure.  Set MCU_INDEX_MUX_THRESHOLD=0 to restore
# the previous behaviour if LEC or QoR regresses.
set INDEX_MUX_THRESHOLD [genus_env_value MCU_INDEX_MUX_THRESHOLD 8]
if {![string is integer -strict $INDEX_MUX_THRESHOLD] ||
    $INDEX_MUX_THRESHOLD < 0} {
    error "MCU_INDEX_MUX_THRESHOLD must be a non-negative integer"
}
genus_try_set_root_attribute hdl_index_mux_threshold $INDEX_MUX_THRESHOLD
set_db / .auto_ungroup both
set_db / .lp_insert_clock_gating false
set_db / .library $ALL_TIMING_LIBS

# ------------------------------------------------------------------------
# Physical-aware synthesis.
#
# Without LEF + PLE, Genus ran in wireload mode with no wireload model at
# all: reports/qor_syn.rpt showed 'Wireload mode: enclosed', wireload
# '<none>' and 'Net Area 0.000', i.e. ZERO interconnect delay.  Every clock
# then met with large positive slack, which for a ~260k-instance 7 nm design
# says nothing about whether the netlist can close after routing.  The
# 4x-scaled tech LEF pairs with the 4x-scaled QRC tech file, so wire lengths
# and per-unit RC compensate each other.
#
# The LEF and QRC files are handed over as root attributes, NOT with the
# read_physical command.  read_physical is an init-flow command that requires
# the state machine to already be at 'timing_initialized'; at this point in
# the script Genus is still 'uninitialized' (setting the .library attribute
# does not advance the state machine) and it aborts with TUI-340.  The
# lef_library / qrc_tech_file attributes are consumed by init_design, exactly
# like the .library attribute set above.
#
# Set MCU_GENUS_PHYSICAL=0 to fall back to the old wireload behaviour.
# ------------------------------------------------------------------------
set GENUS_PHYSICAL [genus_env_flag MCU_GENUS_PHYSICAL 1]
if {$GENUS_PHYSICAL} {
    set PHYSICAL_LEFS [concat [list $TECH_LEF] $CELL_LEFS [list $SRAM_LEF]]
    foreach lef_file $PHYSICAL_LEFS {
        genus_require_file "physical LEF" $lef_file
    }
    if {[genus_try_set_root_attribute lef_library $PHYSICAL_LEFS]} {
        puts "Genus physical: registered [llength $PHYSICAL_LEFS] LEF files"
        # Map LEF layer names onto QRC layer names before the QRC file is
        # read.  Without it Genus matches the two stacks by position and
        # every layer inherits the parasitics of the layer below (PHYS-25).
        set QRC_LAYER_MAP \
            [file join $GENUS_TCL_DIR asap7_lef_to_qrc_layers.map]
        if {[file isfile $QRC_LAYER_MAP]} {
            genus_try_set_root_attribute \
                extract_rc_lef_tech_file_map $QRC_LAYER_MAP
        } else {
            puts "WARNING: LEF-to-QRC layer map missing; layer parasitics"
            puts "         will be mis-assigned: [file normalize $QRC_LAYER_MAP]"
        }
        if {[file isfile $QRC_FILE]} {
            genus_try_set_root_attribute qrc_tech_file $QRC_FILE
        } else {
            puts "WARNING: QRC tech file missing, PLE falls back to LEF cap"
            puts "         tables: [file normalize $QRC_FILE]"
        }
    } else {
        set GENUS_PHYSICAL 0
        puts "WARNING: this Genus version rejected the lef_library attribute;"
        puts "         synthesis timing will contain NO wire delay"
    }
} else {
    puts "WARNING: Genus physical mode disabled by MCU_GENUS_PHYSICAL=0;"
    puts "         synthesis timing will contain NO wire delay"
}

create_library_set -name libset_tt -timing $ALL_TIMING_LIBS
create_rc_corner \
    -name rc_typ \
    -pre_route_res 1.0 \
    -post_route_res 1.0 \
    -pre_route_cap 1.0 \
    -post_route_cap 1.0 \
    -post_route_cross_cap 1.0 \
    -pre_route_clock_res 0.0 \
    -pre_route_clock_cap 0.0 \
    -temperature 25
create_opcond \
    -name opcond_tt_0p7v_25c \
    -process 1.0 \
    -voltage 0.7 \
    -temperature 25
create_timing_condition \
    -name tc_tt \
    -library_sets libset_tt \
    -opcond opcond_tt_0p7v_25c
create_delay_corner \
    -name dc_tt \
    -timing_condition tc_tt \
    -rc_corner rc_typ
create_constraint_mode \
    -name mode_func \
    -sdc_files $SDC_FILE
create_analysis_view \
    -name view_tt \
    -constraint_mode mode_func \
    -delay_corner dc_tt
set_analysis_view -setup {view_tt} -hold {view_tt}

foreach rtl $RTL_FILES {
    puts "Reading RTL: [file normalize $rtl]"
    read_hdl $rtl
}

elaborate $TOP
uniquify $TOP
check_design -unresolved > ./reports/check_design_unresolved.rpt

# Keep the controller/wrapper boundary and the hard-macro array visible for
# physical planning and for the post-map 32-instance invariant.
foreach module_pattern {
    axi_ram
    asap7_sram_128k_1rw
    riscv_pipeline
    instruction_cache
    data_cache
    axi_interconnect
} {
    foreach module_obj [get_db modules $module_pattern] {
        set_db $module_obj .ungroup_ok false
    }
}

init_design
set_interactive_constraint_modes mode_func

if {[sizeof_collection [get_clocks *]] != 18} {
    error "Expected 18 clocks (9 primary + 1 forwarded + 8 gated); inspect the SDC"
}

if {[info exists ::dc::sdc_failed_commands] &&
    [llength $::dc::sdc_failed_commands] > 0} {
    set fp [open ./reports/failed_sdc_commands.rpt w]
    foreach failed $::dc::sdc_failed_commands {
        puts $fp $failed
    }
    close $fp
    error "SDC contains failed commands; see reports/failed_sdc_commands.rpt"
}

check_sram_library_cell $SRAM_MASTER

if {![catch {
    set sram_outputs \
        [get_lib_pins "*/$SRAM_MASTER/*" -filter "@direction == out"]
    if {[sizeof_collection $sram_outputs] > 0} {
        set_max_fanout 1 $sram_outputs
    }
} sram_pin_error]} {
    puts "Applied the SRAM output fanout guard"
} else {
    puts "WARNING: SRAM output fanout guard was not applied: $sram_pin_error"
}

report_hierarchy > ./reports/hierarchy_elaborated.rpt
report_area > ./reports/area_elaborated.rpt
check_timing_intent -verbose > ./reports/timing_intent_pre_syn.rpt
catch {report_timing -lint > ./reports/timing_lint_pre_syn.rpt}

set SYN_EFFORT [string tolower [genus_env_value GENUS_SYN_EFFORT high]]
if {[lsearch -exact {low medium high} $SYN_EFFORT] < 0} {
    error "GENUS_SYN_EFFORT must be low, medium or high"
}
puts "Genus synthesis effort: $SYN_EFFORT"

if {$GENUS_PHYSICAL} {
    if {[genus_try_set_root_attribute interconnect_mode ple]} {
        puts "Genus interconnect mode: ple (physical layout estimation)"
    } else {
        puts "WARNING: PLE could not be enabled; synthesis timing will"
        puts "         contain NO wire delay"
    }
}
puts "Genus interconnect mode in effect: [get_db / .interconnect_mode]"

set_db / .syn_generic_effort $SYN_EFFORT
syn_generic
set_db / .syn_map_effort $SYN_EFFORT
syn_map
set_db / .syn_opt_effort $SYN_EFFORT
syn_opt

report_area > ./reports/area_syn.rpt
report_area -depth 5 > ./reports/area_hierarchy_syn.rpt
report_timing -max_paths 100 > ./reports/timing_syn.rpt
report_power > ./reports/power_syn.rpt
report_gates > ./reports/gates_syn.rpt
catch {report sequential -deleted > ./reports/deleted_sequential_syn.rpt}
report_qor > ./reports/qor_syn.rpt
report_hierarchy > ./reports/hierarchy_syn.rpt
check_timing_intent -verbose > ./reports/timing_intent_post_syn.rpt
catch {report_timing -lint > ./reports/timing_lint_post_syn.rpt}
report_metric -format html -file ./reports/metric_syn.html

set MAPPED_NETLIST [file join $GENUS_DIR outputs [format "%s_syn.v" $TOP]]
set MAPPED_SDC     [file join $GENUS_DIR outputs [format "%s_syn.sdc" $TOP]]

write_hdl > $MAPPED_NETLIST
write_sdc -view view_tt > $MAPPED_SDC
write_do_lec \
    -revised_design $MAPPED_NETLIST \
    -logfile ./logs/lec_genus.log \
    > ./outputs/genus_mapping_hints.do

check_sram_mapped_netlist \
    $MAPPED_NETLIST $SRAM_MASTER $SRAM_EXPECTED_COUNT

report_messages -all > ./reports/messages_all.rpt

puts "============================================================"
puts "GENUS MCU SYNTHESIS COMPLETED"
puts " - Netlist : [file normalize $MAPPED_NETLIST]"
puts " - SDC     : [file normalize $MAPPED_SDC]"
puts " - SRAM    : $SRAM_EXPECTED_COUNT x $SRAM_MASTER"
puts "============================================================"
