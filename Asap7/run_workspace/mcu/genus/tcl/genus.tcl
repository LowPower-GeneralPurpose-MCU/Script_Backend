############################################################
## Genus synthesis: MCU top_soc tren ASAP7
## MMMC SS/TT/FF, RVT + LVT, physical-aware (PLE)
## 80 x srambank_256x4x32_6t122 + 4 x srambank_128x4x20_6t122
############################################################

# ------------------------------------------------------------------------
# 1. BIEN TOAN CUC
# ------------------------------------------------------------------------

set GENUS_TCL_DIR [file dirname [file normalize [info script]]]
set GENUS_DIR     [file dirname $GENUS_TCL_DIR]
set FLOW_ROOT     [file dirname $GENUS_DIR]
set RTL_ROOT      [file join $GENUS_DIR rtl]
set SDC_FILE      [file join $GENUS_TCL_DIR constraint.sdc]
set QRC_LAYER_MAP [file join $GENUS_TCL_DIR asap7_lef_to_qrc_layers.map]
cd $GENUS_DIR

# TOP, thu vien, LEF/QRC, SRAM_* va SRAM_DERATE_SS/FF (dung chung voi Innovus).
source [file join $RTL_ROOT flow project_config.tcl]
source [file join $GENUS_TCL_DIR rtl_filelist.tcl]

set SYN_EFFORT        high
set MULTI_CORNER      1      ;# 0 = chi goc TT
set MULTI_VT          1      ;# cam LVT o syn_generic/syn_map, mo lai o syn_opt
set GENUS_PHYSICAL    1      ;# LEF + QRC + PLE
set CLOCK_GATING      1
set MIN_ICG_CELLS     200
set EXPECTED_RTL      54
set EXPECTED_CLOCKS   15     ;# CLK_SYS, CLK_TCK, CLK_SDRAM_OUT + 12 gated
set RO_EXPECTED_CELLS 7      ;# ring oscillator TRNG: 6 INVx1 + 1 NAND2x1

# Margin chi dung trong luc toi uu, go truoc write_sdc va bao cao.
set SYN_MARGIN_PS 100.0
if {[info exists ::env(MCU_SYN_MARGIN_PS)] && $::env(MCU_SYN_MARGIN_PS) ne ""} {
    set SYN_MARGIN_PS $::env(MCU_SYN_MARGIN_PS)
}
set SYN_MARGIN_CLOCKS {CLK_CPU CLK_SYS CLK_CORDIC CLK_DBG}

set NON_DATA_PORTS {clk tck rst_n trst_n}

if {![info exists SRAM_DERATE_SS] || ![info exists SRAM_DERATE_FF]} {
    error "SRAM_DERATE_SS/FF thieu - phai den tu rtl/flow/project_config.tcl"
}

# ------------------------------------------------------------------------
# 2. KIEM TRA TRUOC KHI TONG HOP
# ------------------------------------------------------------------------

if {[llength $RTL_FILES] != $EXPECTED_RTL} {
    error "Expected $EXPECTED_RTL RTL files, found [llength $RTL_FILES]"
}
set seen_rtl [dict create]
foreach rtl $RTL_FILES {
    set rtl [file normalize $rtl]
    if {[dict exists $seen_rtl $rtl]} {
        error "Duplicate RTL file in rtl_filelist.tcl: $rtl"
    }
    dict set seen_rtl $rtl 1
    if {[file tail $rtl] in [list "$SRAM_MASTER.v" "$SRAM_TAG_MASTER.v"]} {
        error "Do not synthesize the behavioral SRAM model: $rtl"
    }
}

foreach required [concat $ALL_TIMING_LIBS [list $SDC_FILE]] {
    if {![file isfile $required]} {
        error "Missing file: [file normalize $required]"
    }
}

set fp [open $SDC_FILE r]
set sdc_text [read $fp]
close $fp
if {![info complete $sdc_text]} {
    error "SDC Tcl syntax is incomplete: [file normalize $SDC_FILE]"
}

# 256x4x32: RAM 64 + cache 4 + 4 + ITCM 4 + DTCM 4 = 80; 128x4x20: tag 2 + 2 = 4.
if {$SRAM_RAM_COUNT * $SRAM_MACRO_BYTES != 256 * 1024 ||
    $SRAM_ICACHE_COUNT != 4 || $SRAM_DCACHE_COUNT != 4 ||
    $SRAM_ITCM_COUNT != 4 || $SRAM_DTCM_COUNT != 4 ||
    $SRAM_ICACHE_TAG_COUNT != 2 || $SRAM_DCACHE_TAG_COUNT != 2 ||
    $SRAM_EXPECTED_COUNT != 80 || $SRAM_TAG_EXPECTED_COUNT != 4} {
    error "Macro budget trong project_config.tcl khong con la 80 x $SRAM_MASTER + 4 x $SRAM_TAG_MASTER"
}
set SRAM_MASTERS [list $SRAM_MASTER $SRAM_EXPECTED_COUNT $SRAM_TAG_MASTER $SRAM_TAG_EXPECTED_COUNT]

set RTL_INVARIANTS [list \
    top_soc.v "boot ROM INIT_FILE"   {\.INIT_FILE\s*\(\s*"rtl/memory/boot\.mem"\s*\)} \
    top_soc.v "boot ROM 32 KiB"      {axi_rom\s+#\(.*?\.MEM_DEPTH\s*\(\s*8192\s*\)} \
    top_soc.v "RAM 2 x 32768 word"   {\.MEM_DEPTH\s*\(\s*32768\s*\)} \
    top_soc.v "RAM lo"               {u_axi_ram_lo} \
    top_soc.v "RAM hi"               {u_axi_ram_hi} \
    top_soc.v "7 AXI slave"          {localparam\s+SLV_AMT\s*=\s*7\s*;} \
    top_soc.v "ITCM"                 {u_itcm} \
    top_soc.v "DTCM"                 {u_dtcm} \
    top_soc.v "ITCM decode"          {SOC_IS_ITCM} \
    top_soc.v "DTCM decode"          {SOC_IS_DTCM} \
    top_soc.v "I-cache 16 KiB"       {instruction_cache\s+#\([^)]*C_CACHE_SIZE\s*\(\s*16384} \
    top_soc.v "D-cache 16 KiB"       {data_cache\s+#\([^)]*C_CACHE_SIZE\s*\(\s*16384} \
    top_soc.v "D-cache 2-way"        {data_cache\s+#\(.*?C_WAYS\s*\(\s*2\s*\)} \
    top_soc.v "D-cache store buffer" {data_cache\s+#\(.*?STORE_BUF_DEPTH\s*\(\s*4\s*\)} \
    memory/axi_rom.v "boot ROM table include" {`include\s+"memory/boot_rom_image\.vh"} \
    memory/axi_ram.v "MEM_DEPTH mac dinh"     {parameter\s+MEM_DEPTH\s*=\s*32768} \
    memory/axi_ram.v "SRAM wrapper"           {asap7_sram_1rw\s+#\([^)]*ADDR_W} \
    memory/asap7_sram_1rw.v "ROW_ADDR_W 10"   {localparam\s+ROW_ADDR_W\s*=\s*10} \
    memory/asap7_sram_1rw.v "bank decode"     {addr\[ADDR_W-1:ROW_ADDR_W\]} \
    memory/asap7_sram_1rw.v "row decode"      {addr\[ROW_ADDR_W-1:0\]} \
    memory/asap7_sram_1rw.v "macro instance"  $SRAM_MASTER \
    memory/cache_sram_array.v "tag macro instance" $SRAM_TAG_MASTER \
    memory/cache_sram_array.v "tag macro select"   {USE_TAG_MACRO\s*=\s*\(ADDR_W\s*<=\s*9\)\s*&&\s*\(TAG_W\s*<=\s*20\)} \
]
foreach {rel label pattern} $RTL_INVARIANTS {
    set fp [open [file join $RTL_ROOT $rel] r]
    set text [read $fp]
    close $fp
    if {![regexp -- $pattern $text]} {
        error "RTL check failed ($label) in [file normalize [file join $RTL_ROOT $rel]]"
    }
}

# Boot ROM: boot.mem -> bang case boot_rom_image.vh cho axi_rom.v (8192 word).
set BOOT_MEM     [file join $RTL_ROOT memory boot.mem]
set BOOT_INCLUDE [file join $RTL_ROOT memory boot_rom_image.vh]
set BOOT_DEPTH   8192
set fp [open $BOOT_MEM r]
set boot_text [read $fp]
close $fp
set boot_address 0
set boot_entries {}
set boot_seen [dict create]
foreach line [split $boot_text "\n"] {
    regsub {//.*$} $line "" line
    regsub {#.*$} $line "" line
    foreach token [regexp -all -inline {\S+} $line] {
        if {[regexp {^@([0-9A-Fa-f]+)$} $token -> address_text]} {
            scan $address_text %x boot_address
            continue
        }
        regsub -all {_} $token "" word
        if {![regexp {^[0-9A-Fa-f]{1,8}$} $word]} {
            error "Invalid 32-bit boot ROM word '$token' in [file normalize $BOOT_MEM]"
        }
        if {$boot_address < 0 || $boot_address >= $BOOT_DEPTH} {
            error "Boot ROM address $boot_address is outside depth $BOOT_DEPTH"
        }
        if {[dict exists $boot_seen $boot_address]} {
            error "Duplicate boot ROM address $boot_address in [file normalize $BOOT_MEM]"
        }
        dict set boot_seen $boot_address 1
        lappend boot_entries [format "                %d: rom_lookup = 32'h%s;" $boot_address $word]
        incr boot_address
    }
}
if {[llength $boot_entries] == 0} {
    error "Boot ROM image contains no data words: [file normalize $BOOT_MEM]"
}
set fp [open "$BOOT_INCLUDE.tmp" w]
puts $fp "// Generated from boot.mem by tcl/genus.tcl. Do not edit by hand."
foreach entry $boot_entries {
    puts $fp $entry
}
close $fp
file rename -force "$BOOT_INCLUDE.tmp" $BOOT_INCLUDE

foreach dir {outputs reports logs} {
    file mkdir $dir
}
foreach stale [glob -nocomplain ./outputs/* ./reports/* ./logs/*] {
    file delete -force $stale
}

# ------------------------------------------------------------------------
# 3. DATABASE SETTINGS
# ------------------------------------------------------------------------

set_db / .init_lib_search_path [list $STD_LIB_DIR [file dirname $SRAM_LIB]]
set_db / .script_search_path   [list $GENUS_TCL_DIR]
set_db / .init_hdl_search_path [concat [list $RTL_ROOT] $RTL_INCLUDE_DIRS]

# Mot process. max_cpus_per_server > 0 bat super-threading va run 2026-09-12
# 12:30 chet vi server khong ket noi duoc. PBS-2 chi la goi y runtime.
set_db / .auto_super_thread    false
set_db / .super_thread_servers {}
set_db / .max_cpus_per_server  0

set_db / .hdl_unconnected_value      0
set_db / .hdl_track_filename_row_col true
set_db / .hdl_index_mux_threshold    8
set_db / .auto_ungroup               both

set_db / .lp_insert_clock_gating $CLOCK_GATING
if {$CLOCK_GATING} {
    set_db / .lp_clock_gating_prefix "cg_icg_"
}
set_db / .dp_area_mode false

if {$GENUS_PHYSICAL} {
    set PHYSICAL_LEFS [concat [list $TECH_LEF] $CELL_LEFS [list $SRAM_LEF $SRAM_TAG_LEF]]
    foreach required [concat $PHYSICAL_LEFS [list $QRC_LAYER_MAP $QRC_FILE]] {
        if {![file isfile $required]} {
            error "Missing physical file: [file normalize $required]"
        }
    }
    set_db / .lef_library $PHYSICAL_LEFS
    # Map layer LEF -> QRC phai dat TRUOC khi doc QRC (PHYS-25).
    set_db / .extract_rc_lef_tech_file_map $QRC_LAYER_MAP
    set_db / .qrc_tech_file                $QRC_FILE

    # Moi dich cua .map phai co that trong QRC tech file (PHYS-129).
    set fp [open $QRC_LAYER_MAP r]
    set map_text [read $fp]
    close $fp
    set fp [open $QRC_FILE r]
    set qrc_text [read $fp]
    close $fp
    set map_targets {}
    foreach line [split $map_text "\n"] {
        regsub {#.*$} $line "" line
        set fields [regexp -all -inline {\S+} [string map [list "\\" " " "\r" " "] $line]]
        if {[llength $fields] >= 2} {
            lappend map_targets [lindex $fields 1]
        }
    }
    if {[llength $map_targets] == 0} {
        error "QRC layer map khong co dong anh xa nao: [file normalize $QRC_LAYER_MAP]"
    }
    set qrc_missing {}
    foreach target [lsort -unique $map_targets] {
        if {![regexp -- "(^|\[^A-Za-z0-9_\])[string map {. \\.} $target](\[^A-Za-z0-9_\]|$)" $qrc_text]} {
            lappend qrc_missing $target
        }
    }
    if {[llength $qrc_missing] > 0} {
        error "QRC layer map tro toi lop khong co trong [file tail $QRC_FILE]: $qrc_missing"
    }
}

# ------------------------------------------------------------------------
# 4. MMMC
# ------------------------------------------------------------------------
# KHONG dat `.library`: khi co no Genus bo qua library_set, moi view thanh TT.
# SRAM .lib chi co mot goc nen ca 3 library_set dung chung (bu o khoi 9).

create_constraint_mode -name mode_func -sdc_files $SDC_FILE

set CORNERS [list tt $ALL_TIMING_LIBS 25]
if {$MULTI_CORNER} {
    lappend CORNERS ss $ALL_TIMING_LIBS_SS 100 ff $ALL_TIMING_LIBS_FF 0
}
foreach {corner libs temperature} $CORNERS {
    foreach lib $libs {
        if {![file isfile $lib]} {
            error "Missing $corner Liberty: [file normalize $lib]"
        }
    }
    create_library_set -name libset_$corner -timing $libs
    create_rc_corner \
        -name rc_$corner \
        -pre_route_res 1.0 -post_route_res 1.0 \
        -pre_route_cap 1.0 -post_route_cap 1.0 -post_route_cross_cap 1.0 \
        -pre_route_clock_res 0.0 -pre_route_clock_cap 0.0 \
        -temperature $temperature
    create_timing_condition -name tc_$corner -library_sets libset_$corner
    create_delay_corner -name dc_$corner -timing_condition tc_$corner -rc_corner rc_$corner
    create_analysis_view -name view_$corner -constraint_mode mode_func -delay_corner dc_$corner
}

if {$MULTI_CORNER} {
    set SETUP_VIEWS {view_ss view_tt}
    set HOLD_VIEWS  {view_ff view_tt}
} else {
    set SETUP_VIEWS {view_tt}
    set HOLD_VIEWS  {view_tt}
}
set POWER_VIEW view_tt
set_analysis_view -setup $SETUP_VIEWS -hold $HOLD_VIEWS \
                  -leakage $POWER_VIEW -dynamic $POWER_VIEW

# ------------------------------------------------------------------------
# 5. MULTI-Vt - cam LVT truoc khi doc RTL (tru ICG)
# ------------------------------------------------------------------------

set LVT_CELLS {}
if {$MULTI_VT} {
    foreach cell_obj [get_db lib_cells] {
        set leaf [file tail [get_db $cell_obj .name]]
        if {[string match "*_ASAP7_75t_L" $leaf] &&
            !($CLOCK_GATING && [string match "ICG*" $leaf])} {
            lappend LVT_CELLS $cell_obj
            set_db $cell_obj .dont_use true
        }
    }
}

# ------------------------------------------------------------------------
# 6. READ AND ELABORATE
# ------------------------------------------------------------------------
# ASAP7: RingOscillator instantiate thang cell chuan. SYNTHESIS: bo monitor mo phong.

foreach rtl $RTL_FILES {
    read_hdl -define {ASAP7 SYNTHESIS} $rtl
}
elaborate $TOP
uniquify $TOP
check_design -unresolved > ./reports/check_design_unresolved.rpt

# ------------------------------------------------------------------------
# 7. PRESERVE HIERARCHY (khop ten sau uniquify bang string match)
# ------------------------------------------------------------------------

set PRESERVE_MODULES {
    axi_ram axi_rom asap7_sram_1rw asap7_sram_tag_512x20 tcm riscv_pipeline
    instruction_cache data_cache axi_interconnect
    RingOscillator xilinx_not xilinx_nand
    xilinx_primitive_not xilinx_primitive_nand
}
set ALL_MODULES [get_db modules]
foreach module_pattern $PRESERVE_MODULES {
    set matched 0
    foreach module_obj $ALL_MODULES {
        set module_name [get_db $module_obj .name]
        if {$module_name eq $module_pattern || [string match "${module_pattern}_*" $module_name]} {
            set_db $module_obj .ungroup_ok false
            incr matched
        }
    }
    if {$matched == 0} {
        error "preserve-hierarchy: khong module nao khop '$module_pattern'"
    }
}

# ------------------------------------------------------------------------
# 8. RING OSCILLATOR TRNG - Genus bo qua DONT_TOUCH cua Vivado, dung .preserve
# ------------------------------------------------------------------------

set RO_INSTS {}
set RO_NANDS {}
foreach inst_obj [get_db insts] {
    set cell_name ""
    catch {set cell_name [get_db [get_db $inst_obj .base_cell] .name]}
    if {[string match "*INVx1_ASAP7_75t_R*" $cell_name]} {
        lappend RO_INSTS $inst_obj
    } elseif {[string match "*NAND2x1_ASAP7_75t_R*" $cell_name]} {
        lappend RO_INSTS $inst_obj
        lappend RO_NANDS $inst_obj
    }
}
if {[llength $RO_INSTS] != $RO_EXPECTED_CELLS || [llength $RO_NANDS] != 1} {
    error "ring oscillator: can $RO_EXPECTED_CELLS cell (6 INVx1 + 1 NAND2x1), tim thay [llength $RO_INSTS]"
}
foreach inst_obj $RO_INSTS {
    set_db $inst_obj .preserve true
}

init_design
set_interactive_constraint_modes mode_func

# ------------------------------------------------------------------------
# 9. SDC, RING TIMING, SRAM
# ------------------------------------------------------------------------

if {[sizeof_collection [get_clocks *]] != $EXPECTED_CLOCKS} {
    error "Expected $EXPECTED_CLOCKS clocks; inspect the SDC"
}
if {[info exists ::dc::sdc_failed_commands] && [llength $::dc::sdc_failed_commands] > 0} {
    set fp [open ./reports/failed_sdc_commands.rpt w]
    foreach failed $::dc::sdc_failed_commands {
        puts $fp $failed
    }
    close $fp
    error "SDC contains failed commands; see reports/failed_sdc_commands.rpt"
}

# Cat vong o NAND B->Y; tap RO -> LFSR la bat dong bo (-through, TIM-316).
foreach nand_obj $RO_NANDS {
    set_disable_timing -from B -to Y $nand_obj
}
set RO_TAP_PINS {}
foreach inst_obj $RO_INSTS {
    foreach pin_obj [get_db $inst_obj .pins] {
        if {[get_db $pin_obj .direction] in {out output}} {
            lappend RO_TAP_PINS $pin_obj
        }
    }
}
set_false_path -through $RO_TAP_PINS

# Duoi MMMC .name cua lib_cell la "libset_x/<lib>/<cell>": so ten la.
foreach {master expected} $SRAM_MASTERS {
    set sram_cells {}
    foreach cell_obj [get_db lib_cells] {
        set leaf [file tail [get_db $cell_obj .name]]
        if {[string match "*$master*" $leaf] && $leaf ni $sram_cells} {
            lappend sram_cells $leaf
        }
    }
    if {[llength $sram_cells] != 1} {
        error "Can dung 1 loai macro SRAM '$master', thay: $sram_cells"
    }
    set_max_fanout 1 [get_lib_pins "*/$master/*" -filter "@direction == out"]
}

# Derate chi cho 84 macro SRAM (.lib mot goc): SS late, FF early.
set SRAM_MACRO_INSTS {}
foreach inst_obj [get_db insts] {
    set cell_name ""
    catch {set cell_name [get_db [get_db $inst_obj .base_cell] .name]}
    set leaf [file tail $cell_name]
    foreach {master expected} $SRAM_MASTERS {
        if {$leaf ne "" && [string match "*$master*" $leaf]} {
            lappend SRAM_MACRO_INSTS $inst_obj
            break
        }
    }
}
if {[llength $SRAM_MACRO_INSTS] != $SRAM_EXPECTED_COUNT + $SRAM_TAG_EXPECTED_COUNT} {
    error "Derate SRAM: tim thay [llength $SRAM_MACRO_INSTS] macro"
}
if {$MULTI_CORNER} {
    set_timing_derate -delay_corner dc_ss -late  -cell_delay -cell_check $SRAM_DERATE_SS $SRAM_MACRO_INSTS
    set_timing_derate -delay_corner dc_ff -early -cell_delay -cell_check $SRAM_DERATE_FF $SRAM_MACRO_INSTS
}

report_hierarchy > ./reports/hierarchy_elaborated.rpt
report_area      > ./reports/area_elaborated.rpt
check_timing_intent -verbose > ./reports/timing_intent_pre_syn.rpt
catch {report_timing -lint > ./reports/timing_lint_pre_syn.rpt}

# ------------------------------------------------------------------------
# 10. COST GROUPS (reg2reg giu theo clock)
# ------------------------------------------------------------------------

set DATA_INPUTS  [remove_from_collection [all_inputs] [get_ports $NON_DATA_PORTS]]
set DATA_OUTPUTS [all_outputs]
set ALL_SEQS     [all::all_seqs]

define_cost_group -name I2C -design $TOP
define_cost_group -name C2O -design $TOP
define_cost_group -name I2O -design $TOP
foreach view $SETUP_VIEWS {
    path_group -from $DATA_INPUTS -to $ALL_SEQS     -view $view -group I2C -name I2C_$view
    path_group -from $ALL_SEQS    -to $DATA_OUTPUTS -view $view -group C2O -name C2O_$view
    path_group -from $DATA_INPUTS -to $DATA_OUTPUTS -view $view -group I2O -name I2O_$view
}

# Margin tong hop: path_adjust am = rang buoc chat hon. Thu -view truoc.
set SYN_MARGIN_EXCEPTIONS {}
if {$SYN_MARGIN_PS > 0} {
    set delay [expr {-1.0 * $SYN_MARGIN_PS}]
    foreach clk_name $SYN_MARGIN_CLOCKS {
        set clk_objs [get_db clocks -if ".base_name == $clk_name"]
        set made {}
        if {[catch {
            foreach view $SETUP_VIEWS {
                set view_clks [lsearch -all -inline $clk_objs "*/$view/*"]
                if {[llength $view_clks] == 0} {
                    set view_clks $clk_objs
                }
                lappend made [path_adjust -delay $delay -to $view_clks -view $view \
                                  -name syn_margin_${clk_name}_$view]
            }
        }]} {
            foreach e $made {
                catch {delete_obj $e}
            }
            set made {}
            if {[catch {lappend made [path_adjust -delay $delay -to $clk_objs -name syn_margin_$clk_name]} err]} {
                puts "WARNING: margin $clk_name khong ap duoc: $err"
            }
        }
        set SYN_MARGIN_EXCEPTIONS [concat $SYN_MARGIN_EXCEPTIONS $made]
    }
}

# ------------------------------------------------------------------------
# 11. SYNTHESIS
# ------------------------------------------------------------------------

if {$GENUS_PHYSICAL} {
    set_db / .interconnect_mode ple
}

set_db / .syn_generic_effort $SYN_EFFORT
syn_generic

set_db / .syn_map_effort $SYN_EFFORT
syn_map

if {[llength $LVT_CELLS] > 0} {
    foreach cell_obj $LVT_CELLS {
        set_db $cell_obj .dont_use false
    }
    # TUI-32: leakage_power_effort bi bo, thay bang design_power_effort.
    set_db / .design_power_effort high
}

set_db / .syn_opt_effort $SYN_EFFORT
# SYNTH-33 (syn_opt tron se bi bo) chap nhan: 'syn_opt -logical' can license
# GEN_ENG100, may nay khong co (LIC-5, run 2026-09-14).
syn_opt

# Xoa margin sau syn_opt. Genus gop 8 path_adjust thanh 'zipped_path_adjust_N'
# (run 2026-09-14: ten syn_margin_* bien mat, report van con -100 ps), nen bat
# ca hai dang ten; flow khong tao path_adjust nao khac. Query lai moi vong.
set margin_guard 0
while {1} {
    set margin_left {}
    foreach ex [get_db exceptions] {
        set ex_name [get_db $ex .base_name]
        if {[string match syn_margin_* $ex_name] ||
            [string match zipped_path_adjust_* $ex_name]} {
            lappend margin_left $ex
        }
    }
    if {[llength $margin_left] == 0} {
        break
    }
    if {[incr margin_guard] > 64} {
        error "Khong xoa duoc margin: [get_db $margin_left .base_name]"
    }
    delete_obj [lindex $margin_left 0]
}
set margin_residual 0
if {$SYN_MARGIN_PS > 0} {
    report_timing -max_paths 50 > ./reports/margin_check_syn.rpt
    set fp [open ./reports/margin_check_syn.rpt r]
    set margin_residual [regexp -all -- {path_adjust} [read $fp]]
    close $fp
    if {$margin_residual > 0} {
        puts "WARNING: margin chua xoa het ($margin_residual path con path_adjust) - slack trong report bi tru them $SYN_MARGIN_PS ps"
    }
}

set icg_count  0
set sdfh_count 0
foreach inst_obj [get_db insts] {
    set leaf ""
    catch {set leaf [file tail [get_db [get_db $inst_obj .base_cell] .name]]}
    if {[string match "ICG*" $leaf]} {
        incr icg_count
    } elseif {[string match "SDFH*" $leaf]} {
        incr sdfh_count
    }
}
if {$CLOCK_GATING && $icg_count < $MIN_ICG_CELLS} {
    puts "WARNING: chi chen duoc $icg_count ICG (nguong $MIN_ICG_CELLS)"
}

# ------------------------------------------------------------------------
# 12. OUTPUTS - ghi truoc bao cao
# ------------------------------------------------------------------------

set MAPPED_NETLIST [file join $GENUS_DIR outputs ${TOP}_syn.v]
set MAPPED_SDC     [file join $GENUS_DIR outputs ${TOP}_syn.sdc]
write_hdl > $MAPPED_NETLIST
write_sdc -view view_tt > $MAPPED_SDC

# ------------------------------------------------------------------------
# 13. REPORTS - loi o mot bao cao khong dung flow
# ------------------------------------------------------------------------
# Genus 23.14 khong in duoc hold (TUI-204/745); hold dong o Innovus sau CTS.
# SAIF: -instance la duong dan trong file SAIF (XSim: tb_top_soc/uut).

set SAIF_INST "tb_top_soc/uut"
if {[info exists ::env(MCU_SAIF_INST)] && $::env(MCU_SAIF_INST) ne ""} {
    set SAIF_INST $::env(MCU_SAIF_INST)
}
set SAIF_ANNOTATED 0
if {[info exists ::env(MCU_SAIF)] && [file isfile $::env(MCU_SAIF)]} {
    if {[catch {read_saif -instance $SAIF_INST $::env(MCU_SAIF)} saif_err]} {
        puts "WARNING: read_saif that bai: $saif_err"
    } else {
        set SAIF_ANNOTATED 1
    }
}

set REPORTS {
    area_syn.rpt                 {report_area}
    area_hierarchy_syn.rpt       {report_area -depth 5}
    timing_syn.rpt               {report_timing -max_paths 100}
    drc_syn.rpt                  {report_design_rules}
    power_syn.rpt                {report_power}
    gates_syn.rpt                {report_gates}
    datapath_syn.rpt             {report_dp}
    qor_syn.rpt                  {report_qor}
    hierarchy_syn.rpt            {report_hierarchy}
    deleted_sequential_syn.rpt   {report sequential -deleted}
    timing_intent_post_syn.rpt   {check_timing_intent -verbose}
    timing_lint_post_syn.rpt     {report_timing -lint}
    messages_all.rpt             {report_messages -all}
}
foreach {rpt cmd} $REPORTS {
    if {[catch {eval "$cmd > ./reports/$rpt"} rpt_err]} {
        puts "WARNING: bao cao $rpt that bai: $rpt_err"
    }
}
catch {report_metric -format html -file ./reports/metric_syn.html}
catch {
    foreach cg [vfind / -cost_group *] {
        report_timing -cost_group [list $cg] -max_paths 20 > ./reports/timing_[file tail $cg]_syn.rpt
    }
}

# Tom tat flop bi xoa theo ly do va theo khoi cap 1 (bo qua bang tong ket dau file).
set DELETED_RPT ./reports/deleted_sequential_syn.rpt
if {[file isfile $DELETED_RPT]} {
    set reason_count [dict create]
    set block_count  [dict create]
    set in_detail 0
    set fp [open $DELETED_RPT r]
    while {[gets $fp line] >= 0} {
        if {!$in_detail} {
            set in_detail [regexp {^\s*Reason\s+Instance Name\s*$} $line]
            continue
        }
        if {[regexp {^(constant 0|constant 1|unloaded|merged|inv merged)\s+(\S+)} $line -> reason inst]} {
            dict incr reason_count $reason
            dict incr block_count [lindex [split $inst "/"] 0]
        }
    }
    close $fp

    set total 0
    set fp [open ./reports/deleted_sequential_by_block.rpt w]
    foreach reason [lsort [dict keys $reason_count]] {
        set n [dict get $reason_count $reason]
        incr total $n
        puts $fp [format "%-28s %8d" $reason $n]
    }
    puts $fp [format "%-28s %8d\n" TOTAL $total]
    set block_pairs {}
    dict for {block n} $block_count {
        lappend block_pairs [list $n $block]
    }
    foreach pair [lsort -integer -index 0 -decreasing $block_pairs] {
        puts $fp [format "%-28s %8d" [lindex $pair 1] [lindex $pair 0]]
    }
    close $fp
}

# report_qor khong in DRC; run 2026-09-14 incr_tns day Max Trans 0 -> 30308 ma khong ai sua.
set drc_summary [list "khong doc duoc drc_syn.rpt"]
if {[file isfile ./reports/drc_syn.rpt]} {
    set fp [open ./reports/drc_syn.rpt r]
    set drc_text [read $fp]
    close $fp
    set drc_summary {}
    foreach {-> rule total} [regexp -all -inline -nocase -- {(\S+) design rule \(violation total = ([-0-9.eE+]+)\)} $drc_text] {
        lappend drc_summary "$rule=$total"
    }
    if {[llength $drc_summary] == 0} {
        set drc_summary [list "khong thay 'violation total' - xem drc_syn.rpt"]
    }
}

write_do_lec -revised_design $MAPPED_NETLIST -logfile ./logs/lec_genus.log > ./outputs/genus_mapping_hints.do

# ------------------------------------------------------------------------
# 14. KIEM SO MACRO SRAM TRONG NETLIST (dem theo cau lenh, khong theo dong)
# ------------------------------------------------------------------------

set fp [open $MAPPED_NETLIST r]
regsub -all {[ \t\r\n]+} [read $fp] " " netlist_flat
close $fp
set sram_summary {}
foreach {master expected} $SRAM_MASTERS {
    set sram_mapped [llength [regexp -all -inline -- "; ?$master " $netlist_flat]]
    if {$sram_mapped != $expected} {
        error "Mapped SRAM count mismatch for $master: $sram_mapped (expected $expected)"
    }
    lappend sram_summary "$sram_mapped x $master"
}

puts "============================================================"
puts "GENUS MCU SYNTHESIS COMPLETED"
puts " - Netlist : [file normalize $MAPPED_NETLIST]"
puts " - SRAM    : [join $sram_summary { + }]"
puts " - Gating  : $icg_count ICG, $sdfh_count SDFH"
puts " - DRC     : [join $drc_summary {, }]"
puts " - Margin  : [llength $SYN_MARGIN_EXCEPTIONS] path_adjust -$SYN_MARGIN_PS ps, con sot trong report: $margin_residual"
puts " - SAIF    : [expr {$SAIF_ANNOTATED ? "co" : "khong (dynamic power khong dung duoc)"}]"
puts "============================================================"
