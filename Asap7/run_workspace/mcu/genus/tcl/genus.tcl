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
set EXPECTED_RTL      54     ;# 2026-09-11: -PLIC(3) +pmp/clic/timer/pinmux (xem rtl_filelist.tcl)
set EXPECTED_CLOCKS   15     ;# 2 goc (CLK_SYS, CLK_TCK) + 1 forwarded + 12 gated
set RO_EXPECTED_CELLS 7      ;# RingOscillator: 6 INVx1 + 1 NAND2x1

# --- 2026-09-12: cac muc sua sau khi doc run 05:50 ------------------------
# Run do MET nhung WNS o SS = 0.4 ps (CLK_SYS) / 1.5 ps (CLK_CPU), khong co
# bao cao hold nao, 0 ICG cell va report_dp bao 0% datapath.  Nam bien duoi
# day dieu khien cac sua tuong ung; dat ve gia tri trong ngoac de quay lai
# dung hanh vi cua run 2026-09-12 05:50.

set CLOCK_GATING      1      ;# (0) Genus chen ICG.  Can ICG LVT duoc mo o MULTI_VT
set MIN_ICG_CELLS     200    ;# duoi nguong nay = clock gating im lang that bai
set DATAPATH_OPT      1      ;# (0) bat lai cac attribute datapath (RTLOPT-55)

# KHONG co bien so luong CPU o day, va do la co y: xem khoi 3.  Genus chay
# mot process mot CPU.  PBS-2 ("should be run with a minimum of 8 threads")
# la goi y ve runtime, khong phai loi - dung sua theo no.

# SRAM_DERATE_SS / SRAM_DERATE_FF bu goc .lib con thieu cua 84 macro SRAM.
# Chung nam trong rtl/flow/project_config.tcl chu KHONG o day, vi Innovus phai
# dung dung hai con so do sau CTS; de hai ban sao thi chung se troi ra khac
# nhau va hold o FF am tham thanh lac quan.  Ap dung o khoi 9c.
if {![info exists SRAM_DERATE_SS] || ![info exists SRAM_DERATE_FF]} {
    error "SRAM_DERATE_SS/FF thieu - phai den tu rtl/flow/project_config.tcl"
}

# Phai khop CLOCK_PORTS / RESET_PORTS trong constraint.sdc. rtc_clk KHONG con
# nam day: tu 2026-09-11 no la chan du lieu duoc lay mau, co input delay.
set NON_DATA_PORTS {
    clk tck
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
# 2b. HELPER - chay mot lenh tuy chon ma khong giet flow
# ------------------------------------------------------------------------
# Mot so attribute/option duoi day chi co o rieng ban Genus dang chay (23.14).
# Neu ten sai thi `set_db` nem loi va ta mat ca 75 phut.  mcu_try nuot loi,
# in ro cai gi khong ap duoc, va ghi lai de in bang tong ket o cuoi flow.
# Dung mcu_try CHI cho thu khong bat buoc; cai gi bat buoc thi de no nem loi.

set MCU_TRY_OK   {}
set MCU_TRY_FAIL {}
proc mcu_try {label body} {
    global MCU_TRY_OK MCU_TRY_FAIL
    if {[catch {uplevel 1 $body} err]} {
        lappend MCU_TRY_FAIL [list $label $err]
        puts "WARNING: khong ap duoc '$label': $err"
        return 0
    }
    lappend MCU_TRY_OK $label
    puts "OK: $label"
    return 1
}

# Thu lan luot nhieu cu phap cho cung mot viec, lay cai dau tien chay duoc.
# report_timing -early khong ton tai o Genus (TUI-745), nhung ten thay the
# doi theo ban, nen ta do thay vi doan.
proc mcu_try_first {label variants} {
    global MCU_TRY_OK MCU_TRY_FAIL
    set errors {}
    foreach variant $variants {
        if {![catch {uplevel 1 $variant} err]} {
            puts "OK: $label  (dung: $variant)"
            lappend MCU_TRY_OK "$label -> $variant"
            return $variant
        }
        lappend errors "$variant => $err"
    }
    lappend MCU_TRY_FAIL [list $label [join $errors "; "]]
    puts "WARNING: khong cu phap nao chay duoc cho '$label':"
    foreach e $errors {
        puts "         $e"
    }
    return ""
}

# ------------------------------------------------------------------------
# 3. DATABASE SETTINGS
# ------------------------------------------------------------------------

set_db / .init_lib_search_path [list $STD_LIB_DIR [file dirname $SRAM_LIB]]
set_db / .script_search_path   [list $GENUS_TCL_DIR]
set_db / .init_hdl_search_path [concat [list $RTL_ROOT] $RTL_INCLUDE_DIRS]

# MOT PROCESS, MOT CPU.  KHONG dung lai .max_cpus_per_server - da thu, da hong.
#
# 2026-09-12 12:30: run bi giet boi dung dong do.  Ly luan sai luc ay la
# "PBS-2 doi toi thieu 8 luong, ma .max_cpus_per_server la luong local trong
# cung mot process nen khong ton license".  Genus khong hieu nhu the.  Dat no
# > 0 la BAT LUON super-threading, ke ca khi auto_super_thread = false va
# super_thread_servers rong:
#
#   Info    : Attempting to launch a super-threading server. [ST-120]
#           : Attempting to Launch server 1 of 8.        <- 8 = SYN_THREADS
#   Warning : Executing jobs using the foreground process until a background
#             server becomes available. [ST-115]
#   Warning : Failed to establish connection with super-threading server.
#             [ST-111]
#   CURRENT RESOURCES: RT {elapsed: 5878s, ST: 1411s, FG: 1411s, CPU: 0.8%}
#   Abnormal exit.
#
# Genus cho server con, server con khong bao gio ket noi duoc, CPU tut ve
# 0.8%, treo o 5878 s dong ho cho 1411 s cong viec that, phai Ctrl-C.  Ket qua
# ra ve TAY TRANG: khong netlist, khong mot bao cao nao.
#
# Comment goc o day ("on dinh tren may va license hien tai") la DUNG.  PBS-2
# chi la goi y ve thoi gian chay, khong phai loi: 4469 s don luong ma xong van
# hon 5878 s roi chet.  Dung dong vao ba dong duoi nua.
set_db / .auto_super_thread    false
set_db / .super_thread_servers {}
set_db / .max_cpus_per_server  0

set_db / .hdl_unconnected_value      0
set_db / .hdl_track_filename_row_col true
set_db / .hdl_index_mux_threshold    8
set_db / .auto_ungroup               both

# ---- Clock gating ------------------------------------------------------
# Run 2026-09-12 05:50 co .lp_insert_clock_gating false -> netlist 0 ICG cell.
# Hau qua do duoc trong gates_syn.rpt: 8258 SDFHx1 + 31 SDFHx2, tuc 8289 flop
# enable duoc lam bang mux hoi tiep, moi cai van an clock 250 MHz.  12 module
# clock_gate_* viet tay o top chi gate o muc BLOCK (12 DLLx1), khong gate o
# muc register.  Voi mot MCU low-power thi day la mau thuan voi muc tieu.
#
# CAI BAY: ASAP7 co 10 bien the ICG nhung CHI o LVT.  Khoi 5 duoi day cam moi
# cell *_ASAP7_75t_L truoc syn_generic, nen neu khong tha ICG ra thi bat co
# bat gating Genus van KHONG chen duoc gi va im lang bo qua.  Khoi 5 da duoc
# sua de giu lai ICG; khoi 11b dem lai ICG va bao loi neu van bang 0.
set_db / .lp_insert_clock_gating $CLOCK_GATING
if {$CLOCK_GATING} {
    # Chi con attribute da duoc log 12:30 xac nhan la CO that.  Ba cai bo di
    # vi Genus 23.14 khong biet chung (moi cai mot dong "WARNING: khong ap
    # duoc ..." trong log, vo hai nhung vo ich):
    #   .lp_clock_gating_min_flops           .lp_insert_clock_gating_incremental
    #   .lp_clock_gating_cells
    # Be rong bank toi thieu do Genus tu quyet; run 12:30 da chen gating that
    # ("[Clock Gating] Clock gating design done. (19 s.)") ma khong can chung.
    mcu_try "giu ten tin hieu enable tren ICG" {
        set_db / .lp_clock_gating_prefix "cg_icg_"
    }
}

# ---- Datapath (RTLOPT-55) ----------------------------------------------
# report_dp cua run truoc: datapath modules 0.00, external muxes 0.00,
# others 100%.  Kem theo RTLOPT-55 x20 "Inferred datapath logic has changed
# and cannot be considered for datapath optimizations".  Ket qua thay duoc
# tren timing: ba duong te nhat trong core deu la cong 32-bit ripple
# (ID_EX_id_ex_jal_target_reg[31] 2 ps, EX_MEM_ex_mem_jalr_target_reg[31]
# 4 ps, dma_engine gen_ch[*].u_ch_wr_addr_reg[31] 1 ps).
#
# Nghi can nhat la .auto_ungroup both: no pha hierarchy ma DPOPT vua dung de
# suy ra datapath, dung giua luc infer va optimize - dung nghia cua RTLOPT-55.
# Nen giu hierarchy datapath rieng.  Ten attribute khac nhau theo ban Genus,
# vi vay tat ca deu di qua mcu_try.
# Log 12:30 da do xong danh sach: trong sau attribute thu, Genus 23.14 chi
# biet DUY NHAT .dp_area_mode.  Nam cai kia khong ton tai va chi de lai
# "WARNING: khong ap duoc ..." - da bo:
#   .dp_ungroup  .dp_csa  .dp_sharing  .dp_rewriting  .hdl_resource_sharing
# Nen RTLOPT-55 van CHUA co cach nao chac chan de dong.  Lan sau muon do tiep
# thi lay ten tu `get_db -h dp_*` tren chinh ban Genus nay, dung doan nua.
if {$DATAPATH_OPT} {
    mcu_try "uu tien timing hon area trong datapath" {
        set_db / .dp_area_mode false
    }
}

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

    # --------------------------------------------------------------------
    # 3b. KIEM TRA COLLATERAL VAT LY - vai giay, truoc khi ton 75 phut
    # --------------------------------------------------------------------
    # Run 2026-09-12 05:50 de lai ba nhom canh bao vat ly chua ai dong:
    #   PHYS-129 x9  "Via with no resistance will have a value of '0.0'"
    #   PHYS-24  x1  "LEF has more layers than cap table"
    #   PHYS-2040 x1 "Macro references undefined site"
    # Chin cai PHYS-129 la dung chin lop via V1..V9: file .map cu chi anh xa
    # M1..M9 va co y bo via lai vi "khong nhin thay ten via trong PHYS-25".
    # Gio .map da them V1..V9; khoi nay XAC NHAN ten do co that trong QRC
    # thay vi doan, va chi ra chinh xac macro nao tham chieu site khong ton tai.

    # (1) Moi dich cua .map phai la mot ten co that trong QRC tech file.
    set fp [open $QRC_LAYER_MAP r]
    set map_text [read $fp]
    close $fp
    set map_targets {}
    foreach line [split $map_text "\n"] {
        regsub {#.*$} $line "" line
        set line [string map [list "\\" " " "\r" " "] $line]
        set fields [regexp -all -inline {\S+} $line]
        if {[llength $fields] >= 2} {
            lappend map_targets [lindex $fields 1]
        }
    }
    if {[llength $map_targets] == 0} {
        error "QRC layer map khong co dong anh xa nao: [file normalize $QRC_LAYER_MAP]"
    }

    set fp [open $QRC_FILE r]
    set qrc_text [read $fp]
    close $fp
    set qrc_missing {}
    foreach target [lsort -unique $map_targets] {
        if {![regexp -- "(^|\[^A-Za-z0-9_\])[string map {. \\.} $target](\[^A-Za-z0-9_\]|$)" $qrc_text]} {
            lappend qrc_missing $target
        }
    }
    if {[llength $qrc_missing] > 0} {
        error "QRC layer map tro toi lop KHONG co trong [file tail $QRC_FILE]: $qrc_missing\n\
               Sua ve ten that trong [file normalize $QRC_FILE] roi chay lai\n\
               (day la cho da sinh ra PHYS-25 truoc kia va PHYS-129 hien tai)."
    }
    puts "QRC layer map: [llength [lsort -unique $map_targets]] lop/via deu co trong [file tail $QRC_FILE]"

    # (2) Moi SITE ma mot MACRO tham chieu phai duoc dinh nghia o mot LEF nao do.
    # Quet theo DONG, khong regex tren ca file: LEF cell cua ASAP7 vai MB va
    # mot regex co lookahead se backtrack rat lau.  Phan biet dinh nghia voi
    # tham chieu bang dau ';':
    #   "SITE asap7sc7p5t"    <- dinh nghia (mo mot block SITE ... END)
    #   "SITE asap7sc7p5t ;"  <- tham chieu, nam trong mot MACRO
    set lef_sites_defined {}
    set lef_site_refs     {}
    foreach lef $PHYSICAL_LEFS {
        set fp [open $lef r]
        set current_macro ""
        while {[gets $fp line] >= 0} {
            if {[regexp {^\s*MACRO\s+(\S+)} $line -> macro_name]} {
                set current_macro $macro_name
            } elseif {[regexp {^\s*SITE\s+([^\s;]+)\s*;} $line -> site_name]} {
                lappend lef_site_refs [list $current_macro $site_name [file tail $lef]]
            } elseif {[regexp {^\s*SITE\s+(\S+)\s*$} $line -> site_name]} {
                lappend lef_sites_defined $site_name
            }
        }
        close $fp
    }
    set lef_sites_defined [lsort -unique $lef_sites_defined]
    set site_problems {}
    foreach ref $lef_site_refs {
        lassign $ref macro_name site_name lef_tail
        if {$site_name ni $lef_sites_defined} {
            lappend site_problems "MACRO $macro_name ($lef_tail) -> SITE $site_name"
        }
    }
    if {[llength $site_problems] > 0} {
        puts "WARNING: PHYS-2040 se lap lai - site duoc tham chieu nhung khong duoc dinh nghia:"
        foreach problem $site_problems {
            puts "         $problem"
        }
        puts "         SITE co san: $lef_sites_defined"
        puts "         Cach sua: them LEF co dinh nghia site do vao PHYSICAL_LEFS,"
        puts "         hoac sua SITE trong LEF cua macro ve mot ten o tren."
    } else {
        puts "LEF site: [llength $lef_site_refs] macro, tat ca tro toi site da dinh nghia ($lef_sites_defined)"
    }
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
# POPT-595 x2 o run truoc: "Power optimization is enabled but no power view is
# specified".  Toi uu cong suat dang bat nhung MMMC khong co view nao duoc gan
# cho leakage/dynamic, nen Genus khong biet phan tich cong suat o goc nao - va
# power_syn.rpt tro thanh con so khong dung duoc.  Gan view_tt (goc danh dinh)
# cho ca hai.  Ban Genus nao khong nhan -leakage/-dynamic thi roi ve dang cu.
set POWER_VIEW view_tt
if {[mcu_try "power view = $POWER_VIEW (POPT-595)" {
        set_analysis_view -setup $SETUP_VIEWS -hold $HOLD_VIEWS \
                          -leakage $POWER_VIEW -dynamic $POWER_VIEW
    }] == 0} {
    set_analysis_view -setup $SETUP_VIEWS -hold $HOLD_VIEWS
    puts "WARNING: POPT-595 se lap lai - power_syn.rpt chi doc duoc phan leakage"
}
puts "Analysis views: setup = $SETUP_VIEWS ; hold = $HOLD_VIEWS ; power = $POWER_VIEW"

# ------------------------------------------------------------------------
# 5. MULTI-Vt - chan LVT TRUOC khi doc RTL
# ------------------------------------------------------------------------

# ASAP7 chi phat hanh ICG o LVT.  Cam tron goi "*_ASAP7_75t_L" nhu truoc thi
# cam luon ca 10 bien the ICG, va do la ly do that su khien run 2026-09-12
# 05:50 ra 0 ICG cell: khong phai vi .lp_insert_clock_gating false mot minh,
# ma vi ke ca bat len thi cung khong con cell nao de chen.  Hai thu phai sua
# CUNG luc.  ICG duoi day duoc mien tru khoi dont_use.

set LVT_CELLS {}
set ICG_LIB_CELLS {}
if {$MULTI_VT} {
    foreach cell_obj [get_db lib_cells] {
        set cell_name [get_db $cell_obj .name]
        set leaf [file tail $cell_name]
        if {![string match "*_ASAP7_75t_L" $cell_name]} {
            continue
        }

        # Nhan dien ICG bang thuoc tinh cua Liberty truoc (chac chan nhat), roi
        # moi den ten cell.  Ban Genus nao khong co thuoc tinh do thi catch va
        # roi ve so khop ten - ASAP7 dat ten ICG la ICGx*_ASAP7_75t_L.
        set is_icg 0
        catch {
            if {[get_db $cell_obj .is_integrated_clock_gating_cell]} {
                set is_icg 1
            }
        }
        if {!$is_icg && [string match "ICG*" $leaf]} {
            set is_icg 1
        }

        if {$is_icg && $CLOCK_GATING} {
            lappend ICG_LIB_CELLS $cell_obj
        } else {
            lappend LVT_CELLS $cell_obj
        }
    }
    foreach cell_obj $LVT_CELLS {
        set_db $cell_obj .dont_use true
    }
    puts "Multi-Vt: chan [llength $LVT_CELLS] cell LVT cho syn_generic/syn_map"
}

if {$CLOCK_GATING} {
    if {[llength $ICG_LIB_CELLS] == 0} {
        error "Clock gating bat nhung khong tim thay ICG lib cell nao.\n\
               ASAP7 chi co ICG o LVT (ICGx*_ASAP7_75t_L) va chung den tu\n\
               asap7sc7p5t_SEQ_LVT_*.lib - kiem tra STD_LIBS trong\n\
               rtl/flow/project_config.tcl, hoac dat CLOCK_GATING 0."
    }
    set icg_names {}
    foreach cell_obj $ICG_LIB_CELLS {
        set leaf [file tail [get_db $cell_obj .name]]
        if {$leaf ni $icg_names} {
            lappend icg_names $leaf
        }
        set_db $cell_obj .dont_use false
    }
    # Run 12:30 in ra dung 10 bien the, khop danh sach trong memory ASAP7:
    #   ICGx1 ICGx2 ICGx2p67DC ICGx3 ICGx4 ICGx4DC ICGx5 ICGx5p33DC
    #   ICGx6p67DC ICGx8DC  (tat ca deu _ASAP7_75t_L)
    # Chi can bo dont_use la du - `.lp_clock_gating_cells` khong ton tai o
    # Genus 23.14 (log 12:30 dong 1115) nen da bo.
    puts "Clock gating: [llength $icg_names] bien the ICG duoc mo ([join [lsort $icg_names] { }])"
    if {[llength $icg_names] != 10} {
        puts "WARNING: doi 10 bien the ICG cua ASAP7, thay [llength $icg_names]"
    }
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
    error "Expected $EXPECTED_CLOCKS clocks (2 primary + 1 forwarded + 9 gated); inspect the SDC"
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

# ------------------------------------------------------------------------
# 9c. DERATE CHO MACRO SRAM - bu goc .lib con thieu
# ------------------------------------------------------------------------
# project_config.tcl noi ro: ca hai .lib SRAM chi duoc sinh o MOT goc va ca ba
# library_set deu tro toi cung hai file do.  Nghia la 84 macro co DUNG mot bo
# so tre o view_ss, view_tt va view_ff.
#
# O view_ss dieu do lac quan, va no roi trung vao dung cho dang cang nhat: bon
# duong te thu 4..7 cua run truoc (4 ps) chay tu EX_MEM_ex_mem_instr_reg[6]
# toi u_dtcm/u_mem/G_SRAM_BANK[*].u_sram/wd[31], tuc ket thuc o chan du lieu
# cua macro, va dang duoc kiem voi setup time cua goc danh dinh.  4 ps do khong
# that.  O view_ff thi nguoc lai, macro qua cham -> hold qua lac quan.
#
# Derate chi ap cho 84 macro, khong dung toi standard cell (chung da co .lib
# rieng tung goc nen derate them la phat hai lan).

set SRAM_MACRO_INSTS {}
foreach inst_obj [get_db insts] {
    set cell_name ""
    catch {set cell_name [get_db [get_db $inst_obj .base_cell] .name]}
    if {$cell_name eq ""} {
        continue
    }
    set leaf [file tail $cell_name]
    foreach {master expected} $SRAM_MASTERS {
        if {[string match "*$master*" $leaf]} {
            lappend SRAM_MACRO_INSTS $inst_obj
            break
        }
    }
}
if {[llength $SRAM_MACRO_INSTS] != \
        [expr {$SRAM_EXPECTED_COUNT + $SRAM_TAG_EXPECTED_COUNT}]} {
    error "Derate SRAM: tim thay [llength $SRAM_MACRO_INSTS] macro,\
           doi [expr {$SRAM_EXPECTED_COUNT + $SRAM_TAG_EXPECTED_COUNT}]"
}

if {$MULTI_CORNER} {
    # -delay_corner khong chac co o moi ban Genus; do lan luot, va neu khong
    # cu phap nao nhan pham vi theo goc thi CHI ap derate late toan cuc.  Late
    # toan cuc chi lam TT bi quan them (TT dang du 1.3 ns), van an toan.  Tuyet
    # doi KHONG ha early toan cuc: the la lam hold lac quan o moi goc.
    set derate_ss [mcu_try_first "derate SRAM late x$SRAM_DERATE_SS o SS" [list \
        [list set_timing_derate -delay_corner dc_ss -late -cell_delay -cell_check \
              $SRAM_DERATE_SS $SRAM_MACRO_INSTS] \
        [list set_timing_derate -view view_ss -late -cell_delay -cell_check \
              $SRAM_DERATE_SS $SRAM_MACRO_INSTS] \
        [list set_timing_derate -delay_corner dc_ss -late -cell_delay \
              $SRAM_DERATE_SS $SRAM_MACRO_INSTS] \
    ]]
    if {$derate_ss eq ""} {
        puts "WARNING: khong scope duoc derate theo goc; ap late toan cuc (bi quan ca o TT)"
        mcu_try "derate SRAM late x$SRAM_DERATE_SS toan cuc" {
            set_timing_derate -late -cell_delay -cell_check \
                $SRAM_DERATE_SS $SRAM_MACRO_INSTS
        }
    } else {
        mcu_try_first "derate SRAM early x$SRAM_DERATE_FF o FF" [list \
            [list set_timing_derate -delay_corner dc_ff -early -cell_delay -cell_check \
                  $SRAM_DERATE_FF $SRAM_MACRO_INSTS] \
            [list set_timing_derate -view view_ff -early -cell_delay -cell_check \
                  $SRAM_DERATE_FF $SRAM_MACRO_INSTS] \
            [list set_timing_derate -delay_corner dc_ff -early -cell_delay \
                  $SRAM_DERATE_FF $SRAM_MACRO_INSTS] \
        ]
    }
    puts "Derate SRAM: [llength $SRAM_MACRO_INSTS] macro, SS late x$SRAM_DERATE_SS, FF early x$SRAM_DERATE_FF"
} else {
    puts "Derate SRAM: bo qua (MULTI_CORNER = 0, chi co goc TT = goc cua .lib)"
}

report_hierarchy > ./reports/hierarchy_elaborated.rpt
report_area      > ./reports/area_elaborated.rpt
check_timing_intent -verbose > ./reports/timing_intent_pre_syn.rpt
catch {report_timing -lint > ./reports/timing_lint_pre_syn.rpt}

# ------------------------------------------------------------------------
# 10. COST GROUPS
# ------------------------------------------------------------------------
# Tach duong I/O ra nhom rieng de co bao cao va dong QoR rieng.  KHONG tao
# C2C nhu flow sram_axi: MCU co 12 clock (CLK_SYS + 9 nhanh gated + TCK +
# SDRAM_OUT), gop moi reg2reg vao mot nhom se mat dong QoR theo tung khoi
# (CLK_CPU, CLK_SYS...). Reg2reg o lai nhom theo clock.

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
# 11b. XAC NHAN CLOCK GATING DA THAT SU XAY RA
# ------------------------------------------------------------------------
# Genus khong bao loi khi khong chen duoc ICG - no chi im lang, va do dung la
# cach run 2026-09-12 05:50 ra netlist 0 ICG.  Dem lai o day de lan sau that
# bai thi phat hien ngay chu khong phai doc gates_syn.rpt moi biet.
#
# Dem luon SDFH (flop enable kieu mux hoi tiep): moi SDFH la mot cho le ra ICG
# co the thay the.  Truoc khi sua: 8258 SDFHx1 + 31 SDFHx2, 0 ICG.

set icg_count  0
set sdfh_count 0
foreach inst_obj [get_db insts] {
    set cell_name ""
    catch {set cell_name [get_db [get_db $inst_obj .base_cell] .name]}
    if {$cell_name eq ""} {
        continue
    }
    set leaf [file tail $cell_name]
    if {[string match "ICG*" $leaf]} {
        incr icg_count
    } elseif {[string match "SDFH*" $leaf]} {
        incr sdfh_count
    }
}
puts "Clock gating sau syn_opt: $icg_count ICG, $sdfh_count flop enable con lai (SDFH*)"
if {$CLOCK_GATING && $icg_count < $MIN_ICG_CELLS} {
    puts "WARNING: chi chen duoc $icg_count ICG (nguong MIN_ICG_CELLS = $MIN_ICG_CELLS)."
    puts "         Kiem tra theo thu tu:"
    puts "         1. ICG co bi dont_use khong  - xem dong 'Clock gating: N bien the ICG duoc mo'"
    puts "         2. .lp_insert_clock_gating   - [get_db / .lp_insert_clock_gating]"
    puts "         3. cac dong '\[Clock Gating\]' trong log - co chay khong, bao nhieu giay"
    puts "         4. cac dong 'WARNING: khong ap duoc ...' o dau log"
}

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
# dung toggle rate mac dinh - do la ly do power_syn.rpt cua run 2026-09-12
# 05:50 quy 82.86% cong suat cho "bbox": Joules gia dinh 84 macro doc/ghi moi
# chu ky 250 MHz.  Khoi 13b duoi day bien viec thieu SAIF thanh canh bao to
# thay vi de con so 100.9 mW troi qua nhu that.

# -instance la duong dan TRONG FILE SAIF toi top_soc, khong phai ten design.
# XSim (run_soc_sim.sh SAIF=1) ghi tu testbench xuong: tb_top_soc/uut. Dung
# `-instance top_soc` thi khong khop gi ca. Ghi de bang MCU_SAIF_INST neu SAIF
# den tu testbench khac.
set SAIF_INST "tb_top_soc/uut"
if {[info exists ::env(MCU_SAIF_INST)] && $::env(MCU_SAIF_INST) ne ""} {
    set SAIF_INST $::env(MCU_SAIF_INST)
}
set SAIF_ANNOTATED 0
if {[info exists ::env(MCU_SAIF)] && [file isfile $::env(MCU_SAIF)]} {
    if {[catch {read_saif -instance $SAIF_INST $::env(MCU_SAIF)} saif_err]} {
        puts "WARNING: read_saif that bai, power KHONG duoc annotate: $saif_err"
    } else {
        set SAIF_ANNOTATED 1
        puts "Power: annotate activity tu $::env(MCU_SAIF)"
    }
}
if {!$SAIF_ANNOTATED} {
    puts "############################################################"
    puts "## CANH BAO: power_syn.rpt KHONG co SAIF                  ##"
    puts "############################################################"
    puts "## Dynamic power se dung toggle rate mac dinh cho ca 84   ##"
    puts "## macro SRAM -> phan 'bbox' chiem >80% va tong so KHONG   ##"
    puts "## dung de bao cao duoc.  Chi leakage la doc duoc.         ##"
    puts "##                                                        ##"
    puts "## Sinh SAIF roi chay lai:                                ##"
    puts "##   rtl/tests/run_soc_sim.sh SAIF=1                      ##"
    puts "##   MCU_SAIF=<duong_dan>.saif genus -f tcl/genus.tcl     ##"
    puts "############################################################"
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

# ------------------------------------------------------------------------
# 13b. HOLD - tai sao o day KHONG co bao cao hold
# ------------------------------------------------------------------------
# Doc reports/qor_syn.rpt xong rat de hoi "the hold dau?".  Cau tra loi phai
# nam ngay trong thu muc reports/, khong phai trong dau ai do.
#
# Genus 23.14-s090_1 KHONG tao duoc bao cao hold.  Da thu va that bai:
#   report_timing -early        -> TUI-204, khong co option do (Innovus/Tempus)
#   report_timing -late/-hold   -> nt
#   report_timing -check_type   -> nt, option list khong he co
#   report_timing -views view_ff-> TUI-745 "not active for setup"
# Trong Genus kieu kiem di theo ANALYSIS VIEW chu khong phai switch, va
# report_timing chi phan tich view dang active cho SETUP.  Chuyen view_ff sang
# ve setup thi chi duoc mot bao cao SETUP o goc FF - khong phai hold.
#
# 2026-09-10 mot lan them `-early` vao day da giet ca run: luc do write_hdl con
# nam SAU khoi bao cao nen mat sach netlist sau mot gio CPU.  Day la ly do muc
# 12 gio ghi netlist truoc va moi bao cao deu boc catch.
#
# Truoc CTS hold cung gan nhu vo nghia: skew clock con bang 0, hold slack chi
# phan anh uncertainty cong min delay cua thu vien.  Hold dong o Innovus sau
# CTS - xem ../innovus/tcl/innovus.tcl.

set HOLD_NOTE ./reports/timing_hold_syn.rpt
set fp [open $HOLD_NOTE w]
puts $fp "============================================================"
puts $fp " HOLD KHONG DUOC PHAN TICH O GENUS - DAY KHONG PHAI LOI"
puts $fp "============================================================"
puts $fp ""
puts $fp "Genus 23.14-s090_1 khong co bat ky cach nao de in bao cao hold:"
puts $fp "  report_timing -early / -late / -hold / -check_type  -> TUI-204"
puts $fp "  report_timing -views view_ff                        -> TUI-745"
puts $fp "Kieu kiem di theo analysis view, va report_timing chi phan tich"
puts $fp "view dang active cho SETUP.  Khong to hop nao ra duoc hold."
puts $fp ""
puts $fp "Cau hinh view cua run nay:"
puts $fp "  setup : $SETUP_VIEWS"
puts $fp "  hold  : $HOLD_VIEWS"
puts $fp "view_tt nam o ca hai ben nen luon duoc bao cao nhu setup."
puts $fp ""
puts $fp "Va truoc CTS hold cung chua co nghia: skew clock con bang 0, hold"
puts $fp "slack chi phan anh uncertainty cong min delay cua thu vien."
puts $fp ""
puts $fp "HOLD DONG O DAU:"
puts $fp "  Innovus, sau CTS, tren cac view hold o tren."
puts $fp ""
puts $fp "  TINH TRANG 2026-09-12: flow Innovus (../innovus/tcl/innovus.tcl)"
puts $fp "  moi chay toi CHECKPOINT FLOORPLAN - init_design, macro floorplan,"
puts $fp "  checkFPlan, saveDesign - CHUA co place, CHUA co CTS, CHUA co route."
puts $fp "  Nghia la hien tai hold CHUA duoc kiem o BAT KY dau trong ca du an."
puts $fp "  Day khong phai loi cua genus.tcl, nhung dung coi setup MET la du."
puts $fp ""
puts $fp "CANH BAO KEM THEO: .lib cua 84 macro SRAM chi co o MOT goc, nen hold"
puts $fp "o view_ff dung min delay cua goc danh dinh.  genus.tcl bu bang"
puts $fp "set_timing_derate -early x$SRAM_DERATE_FF (khoi 9c); Innovus phai"
puts $fp "dat lai derate tuong duong, neu khong hold o FF se lac quan."
close $fp
puts "Hold: Genus khong phan tich hold; da ghi giai thich vao $HOLD_NOTE"

# ------------------------------------------------------------------------
# 13c. TOM TAT FLOP BI XOA - theo khoi, khong phai 1.8 MB
# ------------------------------------------------------------------------
# deleted_sequential_syn.rpt cua run 2026-09-12 05:50 nang 1.8 MB va liet ke
# 15167 flop bi xoa (~31% so flop suy ra tu RTL):
#   constant 0  10133   constant 1  1003   unloaded  3734   merged  295
# 9693 trong so 10133 cai constant-0 nam TRONG MOT KHOI: u_axi_interconnect
# (SA_GEN[0..6].slave_arbitration va DSP_GEN[0..3].dispatcher).  Nguyen nhan
# doc duoc ngay tren ten module sau uniquify:
#   AXI_SIDEBAND_EN0 AXI_LOCK_CONST0 AXI_CACHE_CONST3 AXI_QOS_CONST0
#   AXI_REGION_CONST0
# Skid buffer van register day du AxLEN/AxSIZE/AxBURST/AxCACHE/QOS/REGION/LOCK
# roi Genus moi cat.  Silicon khong ton gi - nhung LEC lau hon, bao cao kho
# doc, va neu sau nay doi param thi area no ra ma khong ai kip nhan.
#
# Sua that phai gate bang `generate` theo param TRONG axi_interconnect, la mot
# refactor cua khoi nhay cam nhat (co 3 dieu kien khong-deadlock phai giu).
# Chua lam.  Toi thieu: dem theo khoi moi run de con so nay khong am tham troi.

set DELETED_RPT ./reports/deleted_sequential_syn.rpt
set DELETED_SUMMARY ./reports/deleted_sequential_by_block.rpt
if {[file isfile $DELETED_RPT]} {
    # Hai cho de sai, ca hai da bi bat bang cach chay thu tren chinh report
    # cua run 2026-09-12 05:50 truoc khi dua vao day:
    #  - File mo dau bang mot bang TOM TAT co dung dang "constant 0   10133".
    #    Neu khong bo qua no thi moi ly do bi cong them 1.  Vi vay chi bat dau
    #    dem sau dong tieu de "Reason      Instance Name".
    #  - Dong "merged" co dang "<inst> merged with <inst>", tuc con chu sau ten
    #    instance.  Neu neo regex bang $ thi mat sach 295 dong merged.
    set reason_count [dict create]
    set block_count  [dict create]
    set in_detail 0
    set fp [open $DELETED_RPT r]
    while {[gets $fp line] >= 0} {
        if {!$in_detail} {
            if {[regexp {^\s*Reason\s+Instance Name\s*$} $line]} {
                set in_detail 1
            }
            continue
        }
        if {![regexp {^(constant 0|constant 1|unloaded|merged|inv merged)\s+(\S+)} \
                     $line -> reason inst]} {
            continue
        }
        dict incr reason_count $reason
        set block [lindex [split $inst "/"] 0]
        dict incr block_count $block
    }
    close $fp

    set total 0
    dict for {- n} $reason_count { incr total $n }

    set fp [open $DELETED_SUMMARY w]
    puts $fp "Flop bi xoa khi tong hop - tom tat (chi tiet: [file tail $DELETED_RPT])"
    puts $fp "============================================================"
    puts $fp ""
    puts $fp "Theo ly do:"
    foreach reason [lsort [dict keys $reason_count]] {
        puts $fp [format "  %-12s %8d" $reason [dict get $reason_count $reason]]
    }
    puts $fp [format "  %-12s %8d" TONG $total]
    puts $fp ""
    puts $fp "Theo khoi cap 1 (giam dan):"
    # lsort -command voi apply khong thay duoc bien cua scope nay (upvar 2 ->
    # "bad level"), nen sap xep tren danh sach cap {so ten} cho gon va chac.
    set block_pairs {}
    dict for {block n} $block_count {
        lappend block_pairs [list $n $block]
    }
    foreach pair [lsort -integer -index 0 -decreasing $block_pairs] {
        puts $fp [format "  %-28s %8d" [lindex $pair 1] [lindex $pair 0]]
    }
    puts $fp ""
    puts $fp "Tham chieu run 2026-09-12 05:50 (da doi chieu dung bang tom tat"
    puts $fp "cua chinh report do):"
    puts $fp "  tong 15167 = constant 0 10133 + constant 1 1003 + unloaded 3734"
    puts $fp "             + merged 295 + inv merged 2"
    puts $fp "  u_axi_interconnect 14126  (93%)"
    puts $fp "  u_core                423"
    puts $fp "  u_axi_apb_dma         242"
    puts $fp ""
    puts $fp "Con so interconnect tang manh = mot param sideband da doi; xem khoi"
    puts $fp "13c trong tcl/genus.tcl."
    close $fp
    puts "Flop bi xoa: $total tong, tom tat theo khoi o $DELETED_SUMMARY"
} else {
    puts "WARNING: khong co $DELETED_RPT de tom tat"
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
puts " - Views   : setup $SETUP_VIEWS, hold $HOLD_VIEWS, power $POWER_VIEW"
puts " - Netlist : [file normalize $MAPPED_NETLIST]"
puts " - SDC     : [file normalize $MAPPED_SDC]"
puts " - SRAM    : [join $sram_summary { + }]"
puts " - Derate  : SRAM SS late x$SRAM_DERATE_SS, FF early x$SRAM_DERATE_FF"
puts " - Gating  : $icg_count ICG, $sdfh_count flop enable con lai"
puts " - SAIF    : [expr {$SAIF_ANNOTATED ? "co" : "KHONG - dynamic power khong dung duoc"}]"
puts "============================================================"

# Cai gi khong ap duoc thi lap tuc doc duoc o day, khong phai loi 140k dong log.
if {[llength $MCU_TRY_FAIL] > 0} {
    puts ""
    puts "[llength $MCU_TRY_FAIL] tuy chon KHONG ap duoc tren ban Genus nay:"
    foreach entry $MCU_TRY_FAIL {
        lassign $entry label err
        puts "  - $label"
        puts "      $err"
    }
    puts ""
    puts "Moi cai o tren deu la tuy chon; netlist van hop le.  Neu mot cai lien"
    puts "quan toi clock gating hay derate thi doc ky truoc khi tin bao cao."
    puts "============================================================"
}
