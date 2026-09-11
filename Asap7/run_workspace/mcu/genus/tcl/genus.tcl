############################################################
## Genus synthesis: MCU top_soc tren ASAP7
## MMMC 3 goc (SS/TT/FF), RVT + LVT, physical-aware (PLE)
## 80 x srambank_256x4x32_6t122 + 4 x srambank_128x4x20_6t122 (tag cache)
############################################################

# ------------------------------------------------------------------------
# 1. GLOBAL VARIABLES
# ------------------------------------------------------------------------

set GENUS_TCL_DIR [file dirname [file normalize [info script]]]
set GENUS_DIR     [file dirname $GENUS_TCL_DIR]
set FLOW_ROOT     [file dirname $GENUS_DIR]
set RTL_ROOT      [file join $GENUS_DIR rtl]
set SDC_FILE      [file join $GENUS_TCL_DIR constraint.sdc]
set QRC_LAYER_MAP [file join $GENUS_TCL_DIR asap7_lef_to_qrc_layers.map]
cd $GENUS_DIR

# TOP, thu vien, LEF/QRC va macro budget (SRAM_*) nam trong project_config.tcl.
source [file join $RTL_ROOT flow project_config.tcl]
source [file join $GENUS_TCL_DIR rtl_filelist.tcl]

set SYN_EFFORT        high   ;# low | medium | high
set MULTI_CORNER      1      ;# 0 = chi phan tich goc TT
set MULTI_VT          1      ;# 1 = cam LVT o syn_generic/syn_map, mo lai o syn_opt
set GENUS_PHYSICAL    1      ;# 1 = LEF + QRC + PLE (co tre day uoc luong)
set EXPECTED_RTL      58
set EXPECTED_CLOCKS   19     ;# 9 goc + 1 forwarded + 9 gated (CLK_ASCON tu 2026-09-11)
set RO_EXPECTED_CELLS 7      ;# RingOscillator: 6 INVx1 + 1 NAND2x1

# Phai khop CLOCK_PORTS / RESET_PORTS trong constraint.sdc.
set NON_DATA_PORTS {
    clk_core clk_axi clk_apb clk_sdram_ext
    uart_clk spi_clk i2c_clk rtc_clk tck
    rst_n trst_n
}

# ------------------------------------------------------------------------
# 2. PRE-CHECKS - dung truoc khi ton 76 phut tong hop
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

# Macro budget: 256x4x32 = RAM 64 + cache data 4 + 4 + ITCM/DTCM 4 + 4 = 80,
#               128x4x20 = tag I-cache 2 + D-cache 2 = 4.
if {$SRAM_RAM_COUNT * $SRAM_MACRO_BYTES != 256 * 1024 ||
    $SRAM_ICACHE_COUNT != 4 || $SRAM_DCACHE_COUNT != 4 ||
    $SRAM_ITCM_COUNT != 4 || $SRAM_DTCM_COUNT != 4 ||
    $SRAM_ICACHE_TAG_COUNT != 2 || $SRAM_DCACHE_TAG_COUNT != 2 ||
    $SRAM_EXPECTED_COUNT != 80 || $SRAM_TAG_EXPECTED_COUNT != 4} {
    error "Macro budget trong project_config.tcl khong con la 80 x $SRAM_MASTER + 4 x $SRAM_TAG_MASTER"
}
set SRAM_MASTERS [list $SRAM_MASTER $SRAM_EXPECTED_COUNT $SRAM_TAG_MASTER $SRAM_TAG_EXPECTED_COUNT]

# RTL phai khop macro budget o tren; tung lech am tham giua RTL va floorplan.
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

# Boot ROM: sinh bang case tu boot.mem cho axi_rom.v (`include boot_rom_image.vh).
# Day la MASK ROM that (logic chuan, noi dung chot luc tong hop - ASAP7 khong co
# ROM compiler): boot.mem la ma boot tang 1, xem MEMORY_ARCHITECTURE.md muc 6.
# 8192 word = cua so 32 KiB cua slave 0; phai khop MEM_DEPTH trong top_soc.v.
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
puts "Pre-checks passed: $EXPECTED_RTL RTL files, macro budget 80 + 4, boot ROM [llength $boot_entries] words"

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

# Mot process, khong super-thread: on dinh tren may va license hien tai.
set_db / .auto_super_thread    false
set_db / .super_thread_servers {}
set_db / .max_cpus_per_server  0

set_db / .hdl_unconnected_value      0
set_db / .hdl_track_filename_row_col true
set_db / .hdl_index_mux_threshold    8
set_db / .auto_ungroup               both
set_db / .lp_insert_clock_gating     false

if {$GENUS_PHYSICAL} {
    set PHYSICAL_LEFS [concat [list $TECH_LEF] $CELL_LEFS [list $SRAM_LEF $SRAM_TAG_LEF]]
    foreach required [concat $PHYSICAL_LEFS [list $QRC_LAYER_MAP $QRC_FILE]] {
        if {![file isfile $required]} {
            error "Missing physical file: [file normalize $required]"
        }
    }
    set_db / .lef_library $PHYSICAL_LEFS
    # Map ten layer LEF -> QRC TRUOC khi doc QRC; thieu map thi moi layer
    # an ky sinh cua layer ben duoi (PHYS-25).
    set_db / .extract_rc_lef_tech_file_map $QRC_LAYER_MAP
    set_db / .qrc_tech_file                $QRC_FILE
}

# ------------------------------------------------------------------------
# 4. MMMC CORNERS
# ------------------------------------------------------------------------
# KHONG dat `.library`: thu vien chi den tu create_library_set cua tung goc.
# Dat `.library` thi Genus bo qua cac library_set va ca 3 view deu la TT.
# Macro SRAM chi co .lib o TT, nen ca 3 goc dung chung file do.

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
    puts "Corner $corner: [llength $libs] Liberty, vd [file tail [lindex $libs 0]]"

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
set_analysis_view -setup $SETUP_VIEWS -hold $HOLD_VIEWS
puts "Analysis views: setup = $SETUP_VIEWS ; hold = $HOLD_VIEWS"

# ------------------------------------------------------------------------
# 5. MULTI-Vt - chan LVT TRUOC khi doc RTL
# ------------------------------------------------------------------------

set LVT_CELLS {}
if {$MULTI_VT} {
    foreach cell_obj [get_db lib_cells] {
        if {[string match "*_ASAP7_75t_L" [get_db $cell_obj .name]]} {
            lappend LVT_CELLS $cell_obj
        }
    }
    foreach cell_obj $LVT_CELLS {
        set_db $cell_obj .dont_use true
    }
    puts "Multi-Vt: chan [llength $LVT_CELLS] cell LVT cho syn_generic/syn_map"
}

# ------------------------------------------------------------------------
# 6. READ AND ELABORATE RTL
# ------------------------------------------------------------------------
# `ASAP7` bat nhanh instantiate THANG cell chuan cua ring oscillator
# trong rtl/apb_ascon/trng_128b.v.
# `SYNTHESIS` loai cac khoi `ifndef SYNTHESIS` chi de mo phong (monitor R13 trong
# core/riscv_pipeline.v). Dat tuong minh thay vi dua vao macro mac dinh cua tool.

foreach rtl $RTL_FILES {
    puts "Reading RTL: [file normalize $rtl]"
    read_hdl -define {ASAP7 SYNTHESIS} $rtl
}

elaborate $TOP
uniquify $TOP
check_design -unresolved > ./reports/check_design_unresolved.rpt

# ------------------------------------------------------------------------
# 7. PRESERVE PHYSICAL HIERARCHY
# ------------------------------------------------------------------------
# Khop ten sau uniquify (vd axi_ram_ID_WIDTH9_...) bang string match; get_db
# modules <pattern> tung khong khop gi va am tham bo qua 6/7 module.

# axi_rom giu rieng de area_syn.rpt tach duoc gia cua mask ROM logic.
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
            puts "Preserve hierarchy: $module_name"
            incr matched
        }
    }
    if {$matched == 0} {
        error "preserve-hierarchy: khong module nao khop '$module_pattern' - xem reports/hierarchy_elaborated.rpt"
    }
}

# ------------------------------------------------------------------------
# 8. RING OSCILLATOR CUA TRNG - CAM TOI UU
# ------------------------------------------------------------------------
# DONT_TOUCH/KEEP_HIERARCHY trong RTL la cu phap Vivado, Genus bo qua. Khoa
# tung cell bang .preserve; thieu cell nao la da bi toi uu mat -> dung flow.

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
    error "ring oscillator: can $RO_EXPECTED_CELLS cell (6 INVx1 + 1 NAND2x1), tim thay [llength $RO_INSTS] - kiem tra define ASAP7 va reports/hierarchy_elaborated.rpt"
}
foreach inst_obj $RO_INSTS {
    set_db $inst_obj .preserve true
    puts "Ring oscillator: preserve [get_db $inst_obj .name]"
}

init_design
set_interactive_constraint_modes mode_func

# ------------------------------------------------------------------------
# 9. VERIFY SDC, RING TIMING, SRAM
# ------------------------------------------------------------------------
# SDC da gan qua create_constraint_mode; KHONG read_sdc lai (nhan doi clock).

if {[sizeof_collection [get_clocks *]] != $EXPECTED_CLOCKS} {
    error "Expected $EXPECTED_CLOCKS clocks (9 primary + 1 forwarded + 9 gated); inspect the SDC"
}
if {[info exists ::dc::sdc_failed_commands] && [llength $::dc::sdc_failed_commands] > 0} {
    set fp [open ./reports/failed_sdc_commands.rpt w]
    foreach failed $::dc::sdc_failed_commands {
        puts $fp $failed
    }
    close $fp
    error "SDC contains failed commands; see reports/failed_sdc_commands.rpt"
}

# Cat vong cho STA o arc B->Y cua NAND (giu arc enable A->Y). Tap RO -> LFSR la
# duong bat dong bo co chu y: dung -through, vi -from tren chan ra cua cell to
# hop khong phai startpoint va bi Genus bo qua (TIM-316).
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
if {[catch {set_false_path -through $RO_TAP_PINS} ro_err]} {
    puts "WARNING: ring oscillator false path khong ap duoc: $ro_err"
} else {
    puts "Ring oscillator: cat vong o NAND B->Y, false path qua [llength $RO_TAP_PINS] tap"
}

# Voi MMMC, .name cua lib_cell la "libset_tt/<library>/<cell>": so sanh ten la.
foreach {master expected} $SRAM_MASTERS {
    set sram_cells {}
    set sram_copies 0
    foreach cell_obj [get_db lib_cells] {
        set leaf [file tail [get_db $cell_obj .name]]
        if {[string match "*$master*" $leaf]} {
            incr sram_copies
            if {$leaf ni $sram_cells} {
                lappend sram_cells $leaf
            }
        }
    }
    if {[llength $sram_cells] != 1} {
        error "Can dung 1 loai macro SRAM '$master', thay: $sram_cells"
    }
    puts "SRAM library cell: $sram_cells ($sram_copies ban - mot cho moi library_set)"

    if {[catch {
        set_max_fanout 1 [get_lib_pins "*/$master/*" -filter "@direction == out"]
    } sram_err]} {
        puts "WARNING: SRAM output fanout guard khong ap duoc cho $master: $sram_err"
    }
}

report_hierarchy > ./reports/hierarchy_elaborated.rpt
report_area      > ./reports/area_elaborated.rpt
check_timing_intent -verbose > ./reports/timing_intent_pre_syn.rpt
catch {report_timing -lint > ./reports/timing_lint_pre_syn.rpt}

# ------------------------------------------------------------------------
# 10. COST GROUPS
# ------------------------------------------------------------------------
# Tach duong I/O ra nhom rieng de co bao cao va dong QoR rieng.  KHONG tao
# C2C nhu flow sram_axi: MCU co 19 clock, gop moi reg2reg vao mot nhom se mat
# dong QoR theo tung clock (CLK_CPU, CLK_AXI...). Reg2reg o lai nhom theo clock.

set DATA_INPUTS  [remove_from_collection [all_inputs] [get_ports $NON_DATA_PORTS]]
set DATA_OUTPUTS [all_outputs]
set ALL_SEQS     [all::all_seqs]

define_cost_group -name I2C -design $TOP
define_cost_group -name C2O -design $TOP
define_cost_group -name I2O -design $TOP
foreach view $SETUP_VIEWS {
    if {[catch {path_group -from $DATA_INPUTS -to $ALL_SEQS -view $view -group I2C -name I2C_$view} cg_err]} {
        puts "WARNING: path_group I2C ($view): $cg_err"
    }
    if {[catch {path_group -from $ALL_SEQS -to $DATA_OUTPUTS -view $view -group C2O -name C2O_$view} cg_err]} {
        puts "WARNING: path_group C2O ($view): $cg_err"
    }
    if {[catch {path_group -from $DATA_INPUTS -to $DATA_OUTPUTS -view $view -group I2O -name I2O_$view} cg_err]} {
        puts "WARNING: path_group I2O ($view): $cg_err"
    }
}
puts "Cost groups: I2C (input->reg), C2O (reg->output), I2O (input->output); reg2reg giu theo clock"

# ------------------------------------------------------------------------
# 11. SYNTHESIS
# ------------------------------------------------------------------------

if {$GENUS_PHYSICAL} {
    set_db / .interconnect_mode ple
}
puts "Genus interconnect mode: [get_db / .interconnect_mode], effort: $SYN_EFFORT"

set_db / .syn_generic_effort $SYN_EFFORT
syn_generic

set_db / .syn_map_effort $SYN_EFFORT
syn_map

if {[llength $LVT_CELLS] > 0} {
    foreach cell_obj $LVT_CELLS {
        set_db $cell_obj .dont_use false
    }
    # LVT mo lai cho syn_opt; leakage effort cao day nhung duong con du margin
    # ve lai RVT.
    set_db / .leakage_power_effort high
    puts "Multi-Vt: mo lai LVT cho syn_opt"
}

set_db / .syn_opt_effort $SYN_EFFORT
syn_opt

# ------------------------------------------------------------------------
# 12. OUTPUTS - ghi TRUOC bao cao, de mot bao cao loi khong lam mat netlist
# ------------------------------------------------------------------------

set MAPPED_NETLIST [file join $GENUS_DIR outputs ${TOP}_syn.v]
set MAPPED_SDC     [file join $GENUS_DIR outputs ${TOP}_syn.sdc]

write_hdl > $MAPPED_NETLIST
write_sdc -view view_tt > $MAPPED_SDC

# ------------------------------------------------------------------------
# 13. REPORTS - loi o mot bao cao chi in WARNING, flow van chay tiep
# ------------------------------------------------------------------------
# Power chi co nghia khi co SAIF (MCU_SAIF=<file>); khong co thi SRAM ("bbox")
# dung toggle rate mac dinh. Hold khong bao cao o Genus (TUI-745): dong o Innovus.

if {[info exists ::env(MCU_SAIF)] && [file isfile $::env(MCU_SAIF)]} {
    if {[catch {read_saif -instance $TOP $::env(MCU_SAIF)} saif_err]} {
        puts "WARNING: read_saif that bai, power KHONG duoc annotate: $saif_err"
    } else {
        puts "Power: annotate activity tu $::env(MCU_SAIF)"
    }
}

set REPORTS {
    area_syn.rpt                 {report_area}
    area_hierarchy_syn.rpt       {report_area -depth 5}
    timing_syn.rpt               {report_timing -max_paths 100}
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
if {[catch {report_metric -format html -file ./reports/metric_syn.html} rpt_err]} {
    puts "WARNING: bao cao metric_syn.html that bai: $rpt_err"
}

# Moi cost group mot file: CLK_* (reg2reg theo clock), I2C, C2O, I2O, default.
if {[catch {
    foreach cg [vfind / -cost_group *] {
        set cg_name [file tail $cg]
        report_timing -cost_group [list $cg] -max_paths 20 > ./reports/timing_${cg_name}_syn.rpt
    }
} cg_err]} {
    puts "WARNING: bao cao timing theo cost group that bai: $cg_err"
}

write_do_lec -revised_design $MAPPED_NETLIST -logfile ./logs/lec_genus.log > ./outputs/genus_mapping_hints.do

# ------------------------------------------------------------------------
# 14. CHECK MAPPED SRAM COUNT
# ------------------------------------------------------------------------
# Dem theo cau lenh (tach ';'), khong theo dong: ten instance co the xuong dong.

set fp [open $MAPPED_NETLIST r]
regsub -all {[ \t\r\n]+} [read $fp] " " netlist_flat
close $fp
set sram_summary {}
foreach {master expected} $SRAM_MASTERS {
    set sram_mapped 0
    foreach stmt [split $netlist_flat ";"] {
        if {[regexp -- "^ ?$master\[ \t\]" $stmt]} {
            incr sram_mapped
        }
    }
    puts "Mapped SRAM instances: $sram_mapped x $master (expected $expected)"
    if {$sram_mapped != $expected} {
        error "Mapped SRAM count mismatch for $master"
    }
    lappend sram_summary "$sram_mapped x $master"
}

puts "============================================================"
puts "GENUS MCU SYNTHESIS COMPLETED"
puts " - Views   : setup $SETUP_VIEWS, hold $HOLD_VIEWS"
puts " - Netlist : [file normalize $MAPPED_NETLIST]"
puts " - SDC     : [file normalize $MAPPED_SDC]"
puts " - SRAM    : [join $sram_summary { + }]"
puts "============================================================"
