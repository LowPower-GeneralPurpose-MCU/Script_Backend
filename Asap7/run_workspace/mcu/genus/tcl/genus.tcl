############################################################
## Cadence Genus synthesis flow for MCU top_soc
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

proc genus_try_set_root_attribute {name value} {
    if {[catch {set_db / .$name $value} message]} {
        puts "WARNING: cannot set Genus attribute $name=$value: $message"
        return 0
    }
    return 1
}

# -----------------------------------------------------------------------------
# T2 - Multi-Vt: RVT la mac dinh, LVT chi de va critical path.
# -----------------------------------------------------------------------------
proc mcu_lvt_lib_cells {} {
    set lvt {}
    foreach cell_obj [get_db lib_cells] {
        set cell_name [get_db $cell_obj .name]
        # Cell LVT cua ASAP7 ket thuc bang _L, ban RVT bang _R.
        if {[string match "*_ASAP7_75t_L" $cell_name]} {
            lappend lvt $cell_obj
        }
    }
    return $lvt
}

proc mcu_set_lvt_dont_use {cells value} {
    set n 0
    foreach cell_obj $cells {
        if {[catch {set_db $cell_obj .dont_use $value}]} {
            continue
        }
        incr n
    }
    return $n
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
    global SRAM_RAM_COUNT SRAM_ICACHE_COUNT SRAM_DCACHE_COUNT SRAM_MACRO_BYTES
    global SRAM_ITCM_COUNT SRAM_DTCM_COUNT

    if {[llength $RTL_FILES] != 58} {
        error "Expected exactly 58 RTL files, found [llength $RTL_FILES]"
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
    # System RAM is two 128 KiB slave ports, not one 256 KiB port.  Both halves
    # must exist or DMA silently shares an arbiter with the CPU again.
    genus_require_text "AXI RAM half depth" \
        $top_file {\.MEM_DEPTH[ \t\r\n]*\([ \t\r\n]*32768[ \t\r\n]*\)}
    genus_require_text "AXI RAM lo half" $top_file {u_axi_ram_lo}
    genus_require_text "AXI RAM hi half" $top_file {u_axi_ram_hi}
    genus_require_text "Seven interconnect slaves" \
        $top_file {localparam[ \t\r\n]+SLV_AMT[ \t\r\n]*=[ \t\r\n]*7[ \t\r\n]*;}

    # The TCMs must stay off the bus: they are selected by address on the core
    # ports, never instantiated as interconnect slaves.
    genus_require_text "ITCM instance" $top_file {u_itcm}
    genus_require_text "DTCM instance" $top_file {u_dtcm}
    genus_require_text "ITCM decode" $top_file {SOC_IS_ITCM}
    genus_require_text "DTCM decode" $top_file {SOC_IS_DTCM}

    # Cache geometry drives SRAM_ICACHE_COUNT / SRAM_DCACHE_COUNT below.  Pin the
    # instantiated sizes so an RTL edit cannot silently desynchronise the macro
    # budget from the floorplan.
    genus_require_text "I-cache size 16 KiB" \
        $top_file {instruction_cache[ \t\r\n]+#\([^)]*C_CACHE_SIZE[ \t\r\n]*\([ \t\r\n]*16384}
    genus_require_text "D-cache size 16 KiB" \
        $top_file {data_cache[ \t\r\n]+#\([^)]*C_CACHE_SIZE[ \t\r\n]*\([ \t\r\n]*16384}
    # Associativity is what sets the tag-macro count, so pin it too: an edit
    # back to 4-way would need 8 macros and silently break the floorplan.
    genus_require_text "D-cache 2-way" \
        $top_file {data_cache[ \t\r\n]+#\(.*?C_WAYS[ \t\r\n]*\([ \t\r\n]*2[ \t\r\n]*\)}
    genus_require_text "D-cache store buffer" \
        $top_file {data_cache[ \t\r\n]+#\(.*?STORE_BUF_DEPTH[ \t\r\n]*\([ \t\r\n]*4[ \t\r\n]*\)}

    set axi_rom_file [file join $RTL_ROOT memory axi_rom.v]
    genus_require_text "Synthesizable boot ROM table" \
        $axi_rom_file {`include[ \t]+"memory/boot_rom_image\.vh"}

    set axi_ram_file [file join $RTL_ROOT memory axi_ram.v]
    genus_require_text "AXI RAM default depth" \
        $axi_ram_file {parameter[ \t\r\n]+MEM_DEPTH[ \t\r\n]*=[ \t\r\n]*32768}
    genus_require_text "AXI RAM hard macro wrapper" \
        $axi_ram_file {asap7_sram_1rw[ \t\r\n]+#\([^)]*ADDR_W}

    # The 256 KiB shim is gone: axi_ram sizes asap7_sram_1rw directly, so the
    # generic bank array is what has to stay intact.
    set sram_wrapper_file [file join $RTL_ROOT memory asap7_sram_1rw.v]
    genus_require_text "SRAM row address width" \
        $sram_wrapper_file {localparam[ \t\r\n]+ROW_ADDR_W[ \t\r\n]*=[ \t\r\n]*10}
    genus_require_text "SRAM bank address decode" \
        $sram_wrapper_file {addr\[ADDR_W-1:ROW_ADDR_W\]}
    genus_require_text "SRAM row address decode" \
        $sram_wrapper_file {addr\[ROW_ADDR_W-1:0\]}
    genus_require_text "SRAM hard macro instance" \
        $sram_wrapper_file $SRAM_MASTER

    # Derive the expectation from project_config.tcl rather than repeating the
    # numbers here: the two drifted apart once already.
    set expected_ram_bytes [expr {256 * 1024}]
    if {$SRAM_CAPACITY_BYTES != $expected_ram_bytes} {
        error "Main RAM must be 256 KiB, config describes $SRAM_CAPACITY_BYTES bytes"
    }
    if {$SRAM_RAM_COUNT != [expr {$expected_ram_bytes / $SRAM_MACRO_BYTES}]} {
        error "SRAM_RAM_COUNT does not match 256 KiB of $SRAM_MACRO_BYTES-byte macros"
    }
    # Both caches are 16 KiB / 2-way: 2 ways x (2 data + 1 tag) = 6 macros each.
    # The D-cache was 4-way (8 macros); halving the ways doubled the sets, which
    # halved the tag macros without changing the data macros.
    if {$SRAM_ICACHE_COUNT != 6 || $SRAM_DCACHE_COUNT != 6} {
        error "Cache macro budget must be 6 (I) + 6 (D) for 16 KiB 2-way caches"
    }
    # 16 KiB per TCM = 4 macros each.
    if {$SRAM_ITCM_COUNT != 4 || $SRAM_DTCM_COUNT != 4} {
        error "TCM macro budget must be 4 (I) + 4 (D) for 16 KiB TCMs"
    }
    set derived_total [expr {$SRAM_RAM_COUNT + $SRAM_ICACHE_COUNT + $SRAM_DCACHE_COUNT
                             + $SRAM_ITCM_COUNT + $SRAM_DTCM_COUNT}]
    if {$SRAM_EXPECTED_COUNT != $derived_total} {
        error "SRAM_EXPECTED_COUNT ($SRAM_EXPECTED_COUNT) != RAM + cache ($derived_total)"
    }

    foreach clint_file [glob -nocomplain [file join $RTL_ROOT interrupt CLINT *.v]] {
        set clint_text [genus_read_file $clint_file]
        if {[regexp {`include[ \t]+"[^"]*CLINT[^"]*"} $clint_text]} {
            error "CLINT include paths must stay lowercase for Linux: [file normalize $clint_file]"
        }
    }

    puts "MCU static checks passed: 58 RTL files, boot image, SRAM wrapper and SDC"
}

# Voi MMMC, `.name` cua lib_cell la DUONG DAN "libset_tt/<library>/<cell>",
# khong phai ten cell - run 17:13 ngay 2026-09-10 dung lai vi so sanh ten do.
proc mcu_lib_cell_leaf_name {cell_obj} {
    set leaf ""
    catch {set leaf [get_db $cell_obj .base_name]}
    if {$leaf eq ""} {
        set leaf [file tail [get_db $cell_obj .name]]
    }
    return $leaf
}

proc check_sram_library_cell {master} {
    set matches {}
    set names {}
    set containers {}
    foreach cell_obj [get_db lib_cells] {
        set cell_name [mcu_lib_cell_leaf_name $cell_obj]
        if {![string match "*$master*" $cell_name]} {
            continue
        }
        lappend matches $cell_obj
        if {[lsearch -exact $names $cell_name] < 0} {
            lappend names $cell_name
        }
        lappend containers [file dirname [get_db $cell_obj .name]]
    }
    # Voi MMMC, cung mot macro duoc nap mot lan cho MOI library_set, nen dem
    # object se ra 2-3. Dieu can rang buoc la chi co MOT LOAI macro SRAM.
    if {[llength $names] == 0} {
        error "Khong nap duoc lib cell nao cho $master"
    }
    if {[llength $names] > 1} {
        error "Nap nhieu loai macro SRAM khac nhau cho $master: $names"
    }
    puts "Loaded SRAM library cell: [lindex $names 0] ([llength $matches] ban: $containers)"
}

proc check_sram_mapped_netlist {netlist master expected} {
    if {![file isfile $netlist]} {
        error "Mapped netlist does not exist: $netlist"
    }
    set fp [open $netlist r]
    set text [read $fp]
    close $fp

    regsub -all {[ \t\r\n]+} $text " " flat
    set escaped_master [string map {. \\.} $master]
    set count 0
    foreach stmt [split $flat ";"] {
        if {[regexp -- "^ ?$escaped_master\[ \t\]" $stmt]} {
            incr count
        }
    }
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
    # The default remote-shell command is 'rsh', which modern Linux
    # distributions do not ship.  ssh to localhost works once key-based
    # login is set up; override with GENUS_SUPER_THREAD_RSH if needed.
    genus_try_set_root_attribute super_thread_rsh_command \
        [genus_env_value GENUS_SUPER_THREAD_RSH ssh]
    # Each server is a separate process.  Size GENUS_CPUS against free RAM,
    # not against the core count: the last run peaked at 4.4 GB on a host
    # with 12.9 GB total.
    if {[catch {test_super_thread_servers} message]} {
        error "Genus super-thread server check failed: $message"
    }
    puts "Genus execution: super-thread, servers=$GENUS_SERVERS, CPUs=$GENUS_CPUS"
} else {
    genus_try_set_root_attribute super_thread_servers {}
    genus_try_set_root_attribute max_cpus_per_server 0
    puts "Genus execution: single process (set GENUS_ENABLE_SUPER_THREAD=1"
    puts "                 to distribute, see the branch above)"
}

set_db / .hdl_unconnected_value 0
set_db / .hdl_track_filename_row_col true

set INDEX_MUX_THRESHOLD [genus_env_value MCU_INDEX_MUX_THRESHOLD 8]
if {![string is integer -strict $INDEX_MUX_THRESHOLD] ||
    $INDEX_MUX_THRESHOLD < 0} {
    error "MCU_INDEX_MUX_THRESHOLD must be a non-negative integer"
}
genus_try_set_root_attribute hdl_index_mux_threshold $INDEX_MUX_THRESHOLD
set_db / .auto_ungroup both
set_db / .lp_insert_clock_gating false
set MCU_LEGACY_LIBRARY_ATTR [genus_env_flag MCU_LEGACY_LIBRARY_ATTR 0]
if {$MCU_LEGACY_LIBRARY_ATTR} {
    set_db / .library $ALL_TIMING_LIBS
    puts "Library: dat `.library` = goc TT (che do cu, MMMC co the bi bo qua)"
} else {
    puts "Library: KHONG dat `.library` - thu vien den tu create_library_set cua tung goc"
}

# ------------------------------------------------------------------------
# Physical-aware synthesis.
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

# -----------------------------------------------------------------------------
# F2 - ba goc, va hold TACH KHOI setup.
# -----------------------------------------------------------------------------
proc mcu_libs_present {libs} {
    foreach lib $libs {
        if {![file isfile $lib]} {
            return 0
        }
    }
    return 1
}

set MCU_MULTI_CORNER [genus_env_flag MCU_MULTI_CORNER 1]

# -----------------------------------------------------------------------------
# MMMC - ba goc dung nghia
# -----------------------------------------------------------------------------

proc mcu_make_corner {corner libs temperature} {
    create_library_set -name libset_$corner -timing $libs
    create_rc_corner \
        -name rc_$corner \
        -pre_route_res 1.0 \
        -post_route_res 1.0 \
        -pre_route_cap 1.0 \
        -post_route_cap 1.0 \
        -post_route_cross_cap 1.0 \
        -pre_route_clock_res 0.0 \
        -pre_route_clock_cap 0.0 \
        -temperature $temperature
    create_timing_condition -name tc_$corner -library_sets libset_$corner
    create_delay_corner \
        -name dc_$corner \
        -timing_condition tc_$corner \
        -rc_corner rc_$corner
}

# Run 2026-09-10 14:01 khong in ra MOT ten file SS/FF nao trong ca 16 MB log,
# nen khong the biet Genus da nap gi. In thang danh sach da phan giai ra day.
proc mcu_report_corner_libs {corner libs} {
    puts "Corner $corner - [llength $libs] file:"
    foreach lib $libs {
        if {[file isfile $lib]} {
            set mark " OK  "
        } else {
            set mark "THIEU"
        }
        puts "  $mark [file tail $lib]"
    }
}

create_constraint_mode \
    -name mode_func \
    -sdc_files $SDC_FILE

mcu_report_corner_libs TT $ALL_TIMING_LIBS
mcu_make_corner tt $ALL_TIMING_LIBS 25
create_analysis_view -name view_tt -constraint_mode mode_func -delay_corner dc_tt
set MCU_SETUP_VIEWS {view_tt}
set MCU_HOLD_VIEWS  {view_tt}

if {$MCU_MULTI_CORNER} {
    set corner_missing {}
    if {![mcu_libs_present $STD_LIBS_SS]} { lappend corner_missing SS }
    if {![mcu_libs_present $STD_LIBS_FF]} { lappend corner_missing FF }

    if {[llength $corner_missing] > 0} {
        mcu_report_corner_libs SS $ALL_TIMING_LIBS_SS
        mcu_report_corner_libs FF $ALL_TIMING_LIBS_FF
        puts "WARNING: ===================================================="
        puts "WARNING: khong tim thay du thu vien cho goc: $corner_missing"
        puts "WARNING: da tim trong $STD_LIB_DIR theo ten ..._<goc>_ccs_..."
        puts "WARNING: -> quay ve MOT goc TT.  KHONG co phan tich hold that,"
        puts "WARNING:    va setup chua he duoc kiem o goc cham."
        puts "WARNING: ===================================================="
    } else {
        # Neu doi ten goc that bai am tham thi ba danh sach se trung nhau va ba
        # view lai cho ra cung mot ket qua - dung cai bay da sap mot lan.
        if {$ALL_TIMING_LIBS_SS eq $ALL_TIMING_LIBS ||
            $ALL_TIMING_LIBS_FF eq $ALL_TIMING_LIBS ||
            $ALL_TIMING_LIBS_SS eq $ALL_TIMING_LIBS_FF} {
            error "MMMC: danh sach thu vien cua cac goc TRUNG nhau - mcu_corner_lib_list khong doi duoc \"_TT_ccs_\". Kiem ten file trong $STD_LIB_DIR."
        }

        mcu_report_corner_libs SS $ALL_TIMING_LIBS_SS
        mcu_report_corner_libs FF $ALL_TIMING_LIBS_FF
        mcu_make_corner ss $ALL_TIMING_LIBS_SS 100
        mcu_make_corner ff $ALL_TIMING_LIBS_FF 0
        create_analysis_view -name view_ss -constraint_mode mode_func -delay_corner dc_ss
        create_analysis_view -name view_ff -constraint_mode mode_func -delay_corner dc_ff
        set MCU_SETUP_VIEWS {view_ss view_tt}
        set MCU_HOLD_VIEWS  {view_ff view_tt}
    }
} else {
    puts "Multi-corner: TAT boi MCU_MULTI_CORNER=0 - chi con view_tt"
}

set_analysis_view -setup $MCU_SETUP_VIEWS -hold $MCU_HOLD_VIEWS
puts "Analysis views: setup = $MCU_SETUP_VIEWS ; hold = $MCU_HOLD_VIEWS"

# -----------------------------------------------------------------------------
# MULTI-Vt: CHAN LVT NGAY SAU KHI NAP THU VIEN, TRUOC KHI ELABORATE
# -----------------------------------------------------------------------------
if {![info exists MCU_MULTI_VT]} {
    set MCU_MULTI_VT [expr {[info exists ::env(MCU_MULTI_VT)] ? $::env(MCU_MULTI_VT) : 1}]
}
set MCU_LVT_CELLS {}
if {$MCU_MULTI_VT} {
    set MCU_LVT_CELLS [mcu_lvt_lib_cells]
    if {[llength $MCU_LVT_CELLS] == 0} {
        puts "WARNING: multi-Vt requested but no LVT library cell matched *_ASAP7_75t_L"
    } else {
        set blocked [mcu_set_lvt_dont_use $MCU_LVT_CELLS true]
        puts "Multi-Vt: LVT blocked TRUOC elaborate ($blocked of [llength $MCU_LVT_CELLS] cells)"
    }
}

# -----------------------------------------------------------------------------
# `ASAP7` bat nhanh instantiate THANG cell chuan trong rtl/apb_ascon/trng_128b.v.
# -----------------------------------------------------------------------------
foreach rtl $RTL_FILES {
    puts "Reading RTL: [file normalize $rtl]"
    if {[catch {read_hdl -define {ASAP7} $rtl} rd_err]} {
        error "read_hdl -define ASAP7 that bai tren $rtl: $rd_err"
    }
}

elaborate $TOP
uniquify $TOP
check_design -unresolved > ./reports/check_design_unresolved.rpt

set MCU_PRESERVE_MODULES {
    axi_ram
    asap7_sram_1rw
    tcm
    riscv_pipeline
    instruction_cache
    data_cache
    axi_interconnect
    RingOscillator
    xilinx_not
    xilinx_nand
    xilinx_primitive_not
    xilinx_primitive_nand
}
set MCU_ALL_MODULES [get_db modules]
foreach module_pattern $MCU_PRESERVE_MODULES {
    set matched {}
    foreach module_obj $MCU_ALL_MODULES {
        set module_name [get_db $module_obj .name]
        if {$module_name eq $module_pattern ||
            [string match "${module_pattern}_*" $module_name]} {
            lappend matched $module_obj
        }
    }
    if {[llength $matched] == 0} {
        error "preserve-hierarchy: khong module nao khop '$module_pattern' - kiem tra hau to uniquify trong reports/hierarchy_elaborated.rpt"
    }
    foreach module_obj $matched {
        set_db $module_obj .ungroup_ok false
        puts "Preserve hierarchy: [get_db $module_obj .name]"
    }
}

# -----------------------------------------------------------------------------
# Ring oscillator cua TRNG - CAM MOI TOI UU
# -----------------------------------------------------------------------------
set MCU_RO_CELL_PATTERNS  {*INVx1_ASAP7_75t_R* *NAND2x1_ASAP7_75t_R*}
set MCU_RO_NAND_PATTERNS  {*NAND2x1_ASAP7_75t_R*}

# RingOscillator = 6 tang INVx1 (ro_invs_not_gate_0..5) + 1 NAND2x1 enable.
# Ep dung con so: neu chi tim thay it hon thi hoac bo loc sai, hoac da co cell
# bi toi uu an mat - ca hai deu phai dung script chu khong duoc chay tiep.
set MCU_RO_EXPECTED_CELLS 7

proc mcu_inst_base_cell_name {inst_obj} {
    set base_cell ""
    catch {set base_cell [get_db $inst_obj .base_cell]}
    if {$base_cell eq ""} {
        return ""
    }
    set cell_name ""
    catch {set cell_name [get_db $base_cell .name]}
    return $cell_name
}

proc mcu_insts_by_base_cell {patterns} {
    set matched {}
    foreach inst_obj [get_db insts] {
        set cell_name [mcu_inst_base_cell_name $inst_obj]
        if {$cell_name eq ""} {
            continue
        }
        foreach pattern $patterns {
            if {[string match $pattern $cell_name]} {
                lappend matched $inst_obj
                break
            }
        }
    }
    return $matched
}

proc mcu_insts_by_name {patterns} {
    set matched {}
    foreach inst_obj [get_db insts] {
        set inst_name ""
        catch {set inst_name [get_db $inst_obj .name]}
        if {$inst_name eq ""} {
            continue
        }
        foreach pattern $patterns {
            if {[string match $pattern $inst_name]} {
                lappend matched $inst_obj
                break
            }
        }
    }
    return $matched
}

set MCU_RO_INSTS [mcu_insts_by_base_cell $MCU_RO_CELL_PATTERNS]
if {[llength $MCU_RO_INSTS] == $MCU_RO_EXPECTED_CELLS} {
    puts "Ring oscillator: khop $MCU_RO_EXPECTED_CELLS cell theo base cell"
} elseif {[llength $MCU_RO_INSTS] > 0} {
    error "ring oscillator: cho $MCU_RO_EXPECTED_CELLS cell ASAP7 da instantiate (6 INVx1 + 1 NAND2x1), tim thay [llength $MCU_RO_INSTS] - co cell da bi toi uu mat, kiem tra reports/hierarchy_elaborated.rpt"
} else {
    set MCU_RO_INSTS [mcu_insts_by_name {*ro_invs_not_gate* *ro_nand_nand_gate*}]
    if {[llength $MCU_RO_INSTS] == 0} {
        error "ring oscillator: khong khop instance nao theo base cell LAN theo ten - kiem tra define ASAP7 khi read_hdl va reports/hierarchy_elaborated.rpt"
    }
    puts "Ring oscillator: base cell chua san sang truoc init_design, lui ve loc theo ten - khop [llength $MCU_RO_INSTS] instance"
}
foreach inst_obj $MCU_RO_INSTS {
    set_db $inst_obj .preserve true
    puts "Ring oscillator: preserve [get_db $inst_obj .name] ([mcu_inst_base_cell_name $inst_obj])"
}
puts "Ring oscillator: da dat .preserve true cho [llength $MCU_RO_INSTS] instance"

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

# -----------------------------------------------------------------------------
# Ring oscillator - CAT VONG LAP CHO STA
# -----------------------------------------------------------------------------
set MCU_RO_NAND_INSTS [mcu_insts_by_base_cell $MCU_RO_NAND_PATTERNS]
if {[llength $MCU_RO_NAND_INSTS] == 0} {
    error "ring oscillator: khong tim thay cell NAND cua RO de cat vong timing"
}
foreach nand_obj $MCU_RO_NAND_INSTS {
    if {[catch {set_disable_timing -from B -to Y $nand_obj} dis_err]} {
        error "ring oscillator: set_disable_timing that bai tren [get_db $nand_obj .name]: $dis_err"
    }
}
puts "Ring oscillator: da cat vong timing tren [llength $MCU_RO_NAND_INSTS] cell NAND"

# Tap sang RingGenerator = chan ra cua chinh cac cell RO.  Lay qua `.pins` cua
# instance thay vi mot mau ten `*/*/Y`: mau do vua la bieu thuc -if nhieu dong
# (TUI-180) vua gia dinh do sau phan cap co dinh.
set MCU_RO_TAP_PINS {}
foreach inst_obj [mcu_insts_by_base_cell $MCU_RO_CELL_PATTERNS] {
    set inst_pins {}
    catch {set inst_pins [get_db $inst_obj .pins]}
    foreach pin_obj $inst_pins {
        set pin_dir ""
        catch {set pin_dir [get_db $pin_obj .direction]}
        if {$pin_dir eq "out" || $pin_dir eq "output"} {
            lappend MCU_RO_TAP_PINS $pin_obj
        }
    }
}
if {[llength $MCU_RO_TAP_PINS] > 0} {
    catch {set_false_path -from $MCU_RO_TAP_PINS}
    puts "Ring oscillator: false path tu [llength $MCU_RO_TAP_PINS] tap sang RingGenerator"
} else {
    puts "WARNING: ring oscillator - khong khop tap pin nao cho false path"
}

check_sram_library_cell $SRAM_MASTER

# Buoc multi-Vt truoc elaborate bao "212 of 212" - dung bang so cell LVT cua
# MOT goc - trong khi sau init_design SRAM co mat o 2 library_set.  Kiem xem
# LVT cua MOI library_set co that su bi dont_use khong.  Chi DOC: doi dont_use
# sau elaborate se gay RTLOPT-55.
if {[llength $MCU_LVT_CELLS] > 0} {
    set lvt_by_set [dict create]
    foreach cell_obj [get_db lib_cells] {
        if {![string match "*_ASAP7_75t_L" [mcu_lib_cell_leaf_name $cell_obj]]} {
            continue
        }
        set libset [lindex [split [get_db $cell_obj .name] /] 0]
        set blocked 0
        catch {set blocked [string is true -strict [get_db $cell_obj .dont_use]]}
        if {![dict exists $lvt_by_set $libset]} {
            dict set lvt_by_set $libset {0 0}
        }
        lassign [dict get $lvt_by_set $libset] total n_blocked
        dict set lvt_by_set $libset [list [incr total] [incr n_blocked $blocked]]
    }
    dict for {libset counts} $lvt_by_set {
        lassign $counts total n_blocked
        if {$n_blocked < $total} {
            puts "WARNING: Multi-Vt: $libset co $total cell LVT nhung chi $n_blocked bi dont_use"
        } else {
            puts "Multi-Vt: $libset - $n_blocked/$total cell LVT bi dont_use"
        }
    }
}

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

if {[llength $MCU_LVT_CELLS] > 0} {
    mcu_set_lvt_dont_use $MCU_LVT_CELLS false
    puts "Multi-Vt: LVT released for syn_opt"
    # Chi co y nghia khi LVT da duoc mo lai: bao syn_opt uu tien ha leakage o
    # nhung duong con du margin, tuc day nguoc ve RVT cho nhung cho khong can.
    genus_try_set_root_attribute leakage_power_effort high
}

set_db / .syn_opt_effort $SYN_EFFORT
syn_opt

# -----------------------------------------------------------------------------
# DELIVERABLE TRUOC, BAO CAO SAU
# -----------------------------------------------------------------------------
set MAPPED_NETLIST [file join $GENUS_DIR outputs [format "%s_syn.v" $TOP]]
set MAPPED_SDC     [file join $GENUS_DIR outputs [format "%s_syn.sdc" $TOP]]

write_hdl > $MAPPED_NETLIST
write_sdc -view view_tt > $MAPPED_SDC
puts "Netlist + SDC da ghi TRUOC khi bao cao:"
puts "  - [file normalize $MAPPED_NETLIST]"
puts "  - [file normalize $MAPPED_SDC]"

proc mcu_report {label script} {
    if {[catch {uplevel 1 $script} report_err]} {
        puts "WARNING: bao cao '$label' that bai, flow van chay tiep: $report_err"
        return 0
    }
    return 1
}

mcu_report "area"           {report_area > ./reports/area_syn.rpt}
mcu_report "area hierarchy" {report_area -depth 5 > ./reports/area_hierarchy_syn.rpt}
mcu_report "timing setup"   {report_timing -max_paths 100 > ./reports/timing_syn.rpt}

puts "Hold: Genus 23.14 khong bao cao duoc hold (TUI-745 - report_timing chi chay tren view active cho setup)."
puts "Hold: dong hold o Innovus sau CTS; truoc CTS clock skew = 0 nen so lieu hold o day khong co nghia."
# -----------------------------------------------------------------------------
# T5 - power chi co nghia khi co activity annotation.
# -----------------------------------------------------------------------------
if {[info exists ::env(MCU_SAIF)] && [file isfile $::env(MCU_SAIF)]} {
    if {[catch {read_saif -instance top_soc $::env(MCU_SAIF)} saif_msg]} {
        puts "WARNING: read_saif that bai, power se KHONG duoc annotate: $saif_msg"
    } else {
        puts "Power: da annotate activity tu $::env(MCU_SAIF)"
    }
} else {
    puts "Power: KHONG co SAIF - dong 'bbox' trong power_syn.rpt la toggle rate mac dinh, dung tin con so tuyet doi"
}
mcu_report "power"          {report_power > ./reports/power_syn.rpt}
mcu_report "gates"          {report_gates > ./reports/gates_syn.rpt}
mcu_report "deleted seq"    {report sequential -deleted > ./reports/deleted_sequential_syn.rpt}
mcu_report "qor"            {report_qor > ./reports/qor_syn.rpt}
mcu_report "hierarchy"      {report_hierarchy > ./reports/hierarchy_syn.rpt}
mcu_report "timing intent"  {check_timing_intent -verbose > ./reports/timing_intent_post_syn.rpt}
mcu_report "timing lint"    {report_timing -lint > ./reports/timing_lint_post_syn.rpt}
mcu_report "metric html"    {report_metric -format html -file ./reports/metric_syn.html}

write_do_lec     -revised_design $MAPPED_NETLIST     -logfile ./logs/lec_genus.log     > ./outputs/genus_mapping_hints.do

check_sram_mapped_netlist     $MAPPED_NETLIST $SRAM_MASTER $SRAM_EXPECTED_COUNT

# -----------------------------------------------------------------------------
# KIEM TRA MULTI-CORNER CO THAT KHONG
# -----------------------------------------------------------------------------
proc mcu_qor_view_slacks {qor_path} {
    set slacks [dict create]
    if {![file isfile $qor_path]} {
        return $slacks
    }
    set fh [open $qor_path r]
    set body [read $fh]
    close $fh
    set current_view ""
    foreach line [split $body "
"] {
        if {[regexp {^(view_[A-Za-z0-9_]+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$}                 $line -> view_name group slack tns violating]} {
            set current_view $view_name
            dict set slacks $current_view [list "$group=$slack"]
        } elseif {$current_view ne "" &&
                  [regexp {^\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$}                       $line -> group slack tns violating]} {
            dict lappend slacks $current_view "$group=$slack"
        } elseif {[string match "Total*" [string trim $line]]} {
            set current_view ""
        }
    }
    return $slacks
}

if {[llength $MCU_SETUP_VIEWS] > 1} {
    set qor_slacks [mcu_qor_view_slacks ./reports/qor_syn.rpt]
    set view_names [lsort [dict keys $qor_slacks]]
    set identical_pairs {}
    foreach view_a $view_names {
        foreach view_b $view_names {
            if {[string compare $view_a $view_b] >= 0} {
                continue
            }
            if {[dict get $qor_slacks $view_a] eq [dict get $qor_slacks $view_b] &&
                [llength [dict get $qor_slacks $view_a]] > 1} {
                lappend identical_pairs "$view_a/$view_b"
            }
        }
    }
    if {[llength $identical_pairs] > 0} {
        puts "WARNING: ===================================================="
        puts "WARNING: MULTI-CORNER KHONG THAT: $identical_pairs cho so lieu"
        puts "WARNING: slack GIONG HET NHAU tren moi cost group."
        puts "WARNING: -> Cac view dang dung chung mot bo du lieu thu vien."
        puts "WARNING:    Hai nguyen nhan da xu ly: `.library` khong con duoc"
        puts "WARNING:    dat (MCU_LEGACY_LIBRARY_ATTR=0) va -opcond da bo han."
        puts "WARNING:    Neu VAN trung, doi chieu danh sach file cua tung goc"
        puts "WARNING:    da in o dau log ('Corner SS/TT/FF - N file')."
        puts "WARNING: -> KHONG duoc coi ket qua nay la da ky o goc cham."
        puts "WARNING: ===================================================="
    } else {
        puts "Multi-corner: cac view cho so lieu khac nhau - goc phan tich la that"
    }
}

mcu_report "messages"       {report_messages -all > ./reports/messages_all.rpt}

# -----------------------------------------------------------------------------
# DATAPATH CO CON NGUYEN KHONG
# -----------------------------------------------------------------------------
proc mcu_message_count {messages_path msg_id} {
    if {![file isfile $messages_path]} {
        return -1
    }
    set fh [open $messages_path r]
    set body [read $fh]
    close $fh
    # Tach theo dau "|" thay vi regex: bang cua Genus co dinh dang cot co dinh,
    # va mot regex nhieu backslash rat de hong AM THAM luc ghi file - da hong
    # dung nhu vay mot lan o chinh cho nay.
    foreach line [split $body "\n"] {
        if {[string index $line 0] ne "|"} {
            continue
        }
        set fields [split $line "|"]
        if {[llength $fields] < 4} {
            continue
        }
        if {[string trim [lindex $fields 1]] ne $msg_id} {
            continue
        }
        set count [string trim [lindex $fields 3]]
        if {[string is integer -strict $count]} {
            return $count
        }
    }
    return 0
}

set MCU_DP_INVALIDATED [mcu_message_count ./reports/messages_all.rpt RTLOPT-55]
if {$MCU_DP_INVALIDATED > 0} {
    puts "WARNING: ===================================================="
    puts "WARNING: RTLOPT-55 xuat hien $MCU_DP_INVALIDATED lan."
    puts "WARNING: Vung datapath bi vo hieu -> Genus KHONG chon duoc"
    puts "WARNING: kien truc cong nhanh, bo cong tren duong toi han se la"
    puts "WARNING: RIPPLE CARRY."
    puts "WARNING: -> Tim lenh nao doi thu vien hoac thuoc tinh SAU khi RTL"
    puts "WARNING:    da duoc doc: dont_use, preserve, ungroup_ok."
    puts "WARNING: -> Doi chieu reports/timing_syn.rpt: chuoi MAJIxp5/MAJx2"
    puts "WARNING:    lap lai chinh la dau hieu cua ripple."
    puts "WARNING: ===================================================="
} elseif {$MCU_DP_INVALIDATED == 0} {
    puts "Datapath: khong co RTLOPT-55 - cac vung datapath con nguyen ven"
} else {
    puts "WARNING: khong doc duoc reports/messages_all.rpt de kiem RTLOPT-55"
}

puts "============================================================"
puts "GENUS MCU SYNTHESIS COMPLETED"
puts " - Netlist : [file normalize $MAPPED_NETLIST]"
puts " - SDC     : [file normalize $MAPPED_SDC]"
puts " - SRAM    : $SRAM_EXPECTED_COUNT x $SRAM_MASTER"
puts "============================================================"
