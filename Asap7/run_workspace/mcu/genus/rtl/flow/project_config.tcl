############################################################
## Shared MCU / ASAP7 project configuration
############################################################

if {![info exists FLOW_ROOT]} {
    set FLOW_ROOT [file dirname [file dirname [file normalize [info script]]]]
}

set TOP "top_soc"

proc mcu_resolve_path {variable_name environment_names fallback} {
    foreach environment_name $environment_names {
        if {[info exists ::env($environment_name)] &&
            $::env($environment_name) ne ""} {
            return [file normalize $::env($environment_name)]
        }
    }

    upvar #0 $variable_name configured_value
    if {[info exists configured_value] && $configured_value ne ""} {
        return [file normalize $configured_value]
    }

    return [file normalize $fallback]
}

proc mcu_genus_collateral_root_is_complete {root} {
    return [expr {
        [file isfile [file join $root asap7sc7p5t_28 LIB CCS \
            asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib]] &&
        [file isfile [file join $root asap7_sram_0p0 generated LIB \
            srambank_256x4x32_6t122.lib]]
    }]
}

# These revisions are the collateral baseline used to build this flow.
set ASAP7_STDCELL_REVISION "f970bd3c3292b79ae4d022a3ec80533534614066"
set ASAP7_SRAM_REVISION    "522eeccbccefcd66e61893fa1059df24d95e9f86"

set ASAP7_ROOT_SOURCE ""
if {[info exists ::env(ASAP7_ROOT)] && $::env(ASAP7_ROOT) ne ""} {
    set ASAP7_ROOT [file normalize $::env(ASAP7_ROOT)]
    set ASAP7_ROOT_SOURCE "environment ASAP7_ROOT"
} elseif {[info exists ::env(ASAP7_HOME)] && $::env(ASAP7_HOME) ne ""} {
    set ASAP7_ROOT [file normalize $::env(ASAP7_HOME)]
    set ASAP7_ROOT_SOURCE "environment ASAP7_HOME"
} elseif {[info exists ASAP7_ROOT] && $ASAP7_ROOT ne ""} {
    set ASAP7_ROOT [file normalize $ASAP7_ROOT]
    set ASAP7_ROOT_SOURCE "Tcl variable ASAP7_ROOT"
} else {
    set repository_asap7_root \
        [file normalize [file join $FLOW_ROOT .. .. asap7]]
    set root_candidates [list \
        $repository_asap7_root \
        /home/user1/Desktop/asap7]

    set ASAP7_ROOT ""
    foreach candidate $root_candidates {
        if {[mcu_genus_collateral_root_is_complete $candidate]} {
            set ASAP7_ROOT [file normalize $candidate]
            set ASAP7_ROOT_SOURCE "auto-detected complete collateral"
            break
        }
    }

    if {$ASAP7_ROOT eq ""} {
        foreach candidate $root_candidates {
            if {[file isdirectory $candidate]} {
                set ASAP7_ROOT [file normalize $candidate]
                set ASAP7_ROOT_SOURCE "auto-detected incomplete collateral"
                break
            }
        }
    }

    if {$ASAP7_ROOT eq ""} {
        set ASAP7_ROOT [file normalize /home/user1/Desktop/asap7]
        set ASAP7_ROOT_SOURCE "legacy fallback"
    }
}

set STDCELL_ROOT [mcu_resolve_path STDCELL_ROOT \
    {ASAP7_STDCELL_ROOT} \
    [file join $ASAP7_ROOT asap7sc7p5t_28]]
set SRAM_ROOT [mcu_resolve_path SRAM_ROOT \
    {ASAP7_SRAM_ROOT} \
    [file join $ASAP7_ROOT asap7_sram_0p0]]

set STD_LIB_DIR [mcu_resolve_path STD_LIB_DIR \
    {ASAP7_STD_LIB_DIR} \
    [file join $STDCELL_ROOT LIB CCS]]
set STD_LIBS [list \
    [file join $STD_LIB_DIR asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_AO_RVT_TT_ccs_211120.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_OA_RVT_TT_ccs_211120.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_AO_LVT_TT_ccs_211120.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_OA_LVT_TT_ccs_211120.lib] \
    [file join $STD_LIB_DIR asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib]]

# -----------------------------------------------------------------------------
# F2 - danh sach thu vien cho hai goc con lai.
#
# ASAP7 phat hanh cung mot bo file cho ca ba goc, ten chi khac hai chu:
#   asap7sc7p5t_AO_RVT_TT_ccs_211120.lib
#   asap7sc7p5t_AO_RVT_SS_ccs_211120.lib
#   asap7sc7p5t_AO_RVT_FF_ccs_211120.lib
# nen suy ra bang thay chuoi thay vi liet ke lai hai lan muoi dong. Neu ban PDK
# tren may khong co du SS/FF thi genus.tcl phat hien va quay ve mot goc, khong
# gay flow - xem khoi F2 trong tcl/genus.tcl.
#
# CANH BAO: `srambank_256x4x32_6t122.lib` va `srambank_128x4x20_6t122.lib` chi
# duoc sinh o MOT goc. Ca ba library_set deu tro toi cung hai file do, nen do
# tre cua 84 macro KHONG doi theo goc. Day la gioi han cua PDK, khong phai loi cau hinh - phai nho dieu nay khi
# doc ket qua hold o goc FF.
# -----------------------------------------------------------------------------
proc mcu_corner_lib_list {libs corner} {
    set out {}
    foreach lib $libs {
        lappend out [string map [list "_TT_ccs_" "_${corner}_ccs_"] $lib]
    }
    return $out
}
set STD_LIBS_SS [mcu_corner_lib_list $STD_LIBS SS]
set STD_LIBS_FF [mcu_corner_lib_list $STD_LIBS FF]

# -----------------------------------------------------------------------------
# Ti le hinh hoc: 1 = kich thuoc that 7 nm (mac dinh), 4 = ban phong to 4x.
#
# ASAP7 ship CA HAI bo: tech LEF, LEF cell, LEF SRAM va QRC deu co ban 1x va
# ban 4x.  Ban 4x co de cong cu APR ban quyen hoc thuat chay duoc; server nay
# co license invs_7nm (Innovus_7nm_Opt, smoke_1x.tcl 2026-09-25 lay duoc) nen
# chay thang 1x.  Giu 4 lam moc doi chieu voi cac run 4x cu (2026-09-17..22).
#
# Tech LEF 1x la 1000 dbu/um (1 dbu = 1 nm = MANUFACTURINGGRID), 4x la 4000.
# Doi bien nay phai chay lai tu Genus: moi so hinh hoc cua floorplan nhan theo.
#   export MCU_SCALE=4
# -----------------------------------------------------------------------------
set MCU_SCALE 1
if {[info exists ::env(MCU_SCALE)] && $::env(MCU_SCALE) ne ""} {
    set MCU_SCALE $::env(MCU_SCALE)
}
if {$MCU_SCALE ne "1" && $MCU_SCALE ne "4"} {
    error "MCU_SCALE phai la 1 hoac 4, dang la '$MCU_SCALE'"
}
if {$MCU_SCALE == 1} {
    set mcu_tech_lef_name asap7_tech_1x_201209.lef
    set mcu_cell_lef_dir  [file join $STDCELL_ROOT LEF]
    set mcu_cell_lef_tag  1x
    set mcu_qrc_name      qrcTechFile_typ03_unscaledV02
} else {
    set mcu_tech_lef_name asap7_tech_4x_201209.lef
    set mcu_cell_lef_dir  [file join $STDCELL_ROOT LEF scaled]
    set mcu_cell_lef_tag  4x
    set mcu_qrc_name      qrcTechFile_typ03_scaled4xV06
}

set TECH_LEF [mcu_resolve_path TECH_LEF \
    {ASAP7_TECH_LEF_FILE} \
    [file join $STDCELL_ROOT techlef_misc $mcu_tech_lef_name]]
set RVT_CELL_LEF [mcu_resolve_path RVT_CELL_LEF \
    {ASAP7_RVT_LEF_FILE} \
    [file join $mcu_cell_lef_dir "asap7sc7p5t_28_R_${mcu_cell_lef_tag}_220121a.lef"]]
set LVT_CELL_LEF [mcu_resolve_path LVT_CELL_LEF \
    {ASAP7_LVT_LEF_FILE} \
    [file join $mcu_cell_lef_dir "asap7sc7p5t_28_L_${mcu_cell_lef_tag}_220121a.lef"]]
set CELL_LEFS [list \
    $RVT_CELL_LEF \
    $LVT_CELL_LEF]
# QRC 1x la V02, 4x la V06 - hai phien ban khac nhau, khong chi khac ti le.
set QRC_FILE [mcu_resolve_path QRC_FILE \
    {ASAP7_QRC_FILE} \
    [file join $STDCELL_ROOT qrc $mcu_qrc_name]]

# Two generated SRAM masters (asap7_sram_0p0 @522eecc ships 36 variants,
# 64/128/256 rows x 4 x 16..80 bits, all with the same pins):
#   srambank_256x4x32_6t122 : 1024 words x 32 bits = 4 KiB, LEF 30.348 x 43.2 (1x)
#   srambank_128x4x20_6t122 :  512 words x 20 bits,         LEF 16.000 x 30.24 (1x)
# Ban 4x lon gap 4.  preflight.tcl so SIZE trong LEF voi so nay x MCU_SCALE.
set SRAM_SIZE_1X     {30.348 43.2}
set SRAM_TAG_SIZE_1X {16.0 30.24}
#
# Macro budget, 256x4x32 (SRAM_MASTER) = 80:
#   main AXI RAM 256 KiB : 64, as 2 x 128 KiB slave ports of 32
#   I-cache data 16 KiB  : 2 ways x 2 = 4
#   D-cache data 16 KiB  : 2 ways x 2 = 4
#   ITCM / DTCM 16 KiB   : 4 + 4
# Macro budget, 128x4x20 (SRAM_TAG_MASTER) = 4:
#   I-cache tag : 2 ways x 1 (512 sets x 19 bits)
#   D-cache tag : 2 ways x 1
#
# The tags used to sit in 256x4x32 as well, at 29.7% use (512 x 19 of
# 1024 x 32).  128x4x20 holds them at 95% and is 7741 um^2 instead of 20976,
# about 52900 um^2 less over the 4 tag macros.  Every way still needs its own
# macro so a lookup can read all ways in one cycle.
#
# The caches were 32 KiB (10 + 12 = 22 macros).  For an IoT-class workload the
# extra 16 KiB per cache buys roughly 1-2 % hit rate while costing 8 macros of
# area and the leakage of their tag arrays, so both were halved.
set SRAM_MASTER         "srambank_256x4x32_6t122"
set SRAM_TAG_MASTER     "srambank_128x4x20_6t122"
set SRAM_MACRO_BYTES    [expr {1024 * 4}]

set SRAM_RAM_COUNT        64
set SRAM_ICACHE_COUNT     4
set SRAM_DCACHE_COUNT     4
set SRAM_ITCM_COUNT       4
set SRAM_DTCM_COUNT       4
set SRAM_ICACHE_TAG_COUNT 2
set SRAM_DCACHE_TAG_COUNT 2
set SRAM_CACHE_COUNT    [expr {$SRAM_ICACHE_COUNT + $SRAM_DCACHE_COUNT}]
set SRAM_TCM_COUNT      [expr {$SRAM_ITCM_COUNT + $SRAM_DTCM_COUNT}]
set SRAM_EXPECTED_COUNT [expr {$SRAM_RAM_COUNT + $SRAM_CACHE_COUNT + $SRAM_TCM_COUNT}]
set SRAM_TAG_EXPECTED_COUNT [expr {$SRAM_ICACHE_TAG_COUNT + $SRAM_DCACHE_TAG_COUNT}]
set SRAM_CAPACITY_BYTES [expr {$SRAM_RAM_COUNT * $SRAM_MACRO_BYTES}]

# Floorplan grids, left to right: RAM island at the core edge, then the cache
# island (cache data + TCM, the 400 MHz macros), then one column of tag macros
# next to the logic block, since the tag compare is on the cache hit path.
#   RAM   : 8 x 8 = 64 x 256x4x32
#   cache : 8 x 2 = 16 x 256x4x32 (4 I-data + 4 D-data + 4 ITCM + 4 DTCM)
#   tag   : 4 x 1 =  4 x 128x4x20
# The old cache grid was 8 x 3 for 20 macros (12 cache incl. tags + 8 TCM).
set SRAM_RAM_ROWS       8
set SRAM_RAM_COLS       8
set SRAM_CACHE_ROWS     8
set SRAM_CACHE_COLS     2
set SRAM_TAG_ROWS       4
set SRAM_TAG_COLS       1

# LEF SRAM goc cua ASAP7 co toa do lech manufacturing grid 0.004 va khong khai
# SITE.  LEF la nguon DUY NHAT cua hinh SRAM khi streamOut -outputMacros (ASAP7
# khong ship GDS cho SRAM), nen hinh sai di thang vao GDS -
# soc_require_sram_lef_clean o KHOI 16 chan lai.  scripts/fix_sram_lef.py --fix
# xuat ban da sua ra "<ten>.fixed.lef".
#
# Vi sao doi mac dinh (2026-09-21): run 18:45 dung o KHOI 16 voi
#   "srambank_128x4x20_6t122.lef.4x.lef: 3907 toa do lech manufacturing grid
#    0.004, SITE khong dinh nghia (coreSite)"
# sau khi da chay sach het KHOI 0-15 (~1.5 tieng).  Lan chay sach 02:34 cung
# ngay dung ban .fixed.lef - khac biet duy nhat la shell hom do co export
# ASAP7_SRAM_TAG_LEF_FILE.  Mot bien moi truong phai nho set moi dung thi som
# muon cung quen; de ban da sua lam MAC DINH khi no ton tai.
# Bien moi truong van thang, de con ep ve ban goc khi can so sanh.
proc mcu_prefer_fixed_lef {path} {
    set fixed "[file rootname $path].fixed[file extension $path]"
    if {[file isfile $fixed]} {
        return $fixed
    }
    return $path
}

# 1x: generated/LEF/<m>.lef, 4x: generated/LEF/4xLEF/<m>.lef.4x.lef.  Ban 1x goc
# lech luoi CA HAI macro (256x4x32: 11213, 128x4x20: 3908 toa do nua nm) va
# tech LEF 1x la 1000 dbu/um nen nua nm khong bieu dien duoc - phai co
# <m>.fixed.lef (fix_sram_lef.py --grid 0.001).  Ban tag 1x da sua, nhan 4,
# trung khit ban 4x .fixed.lef da chay sach DRC (5014/5014 dong, 2026-09-25).
proc mcu_sram_lef_path {sram_root master} {
    if {$::MCU_SCALE == 1} {
        return [file join $sram_root generated LEF "$master.lef"]
    }
    return [file join $sram_root generated LEF 4xLEF "$master.lef.4x.lef"]
}

set SRAM_LIB [mcu_resolve_path SRAM_LIB \
    {ASAP7_SRAM_LIB_FILE ASAP7_SRAM_LIB} \
    [file join $SRAM_ROOT generated LIB "$SRAM_MASTER.lib"]]
set SRAM_LEF [mcu_resolve_path SRAM_LEF \
    {ASAP7_SRAM_LEF_FILE ASAP7_SRAM_LEF} \
    [mcu_prefer_fixed_lef [mcu_sram_lef_path $SRAM_ROOT $SRAM_MASTER]]]
set SRAM_GDS [mcu_resolve_path SRAM_GDS \
    {ASAP7_SRAM_GDS_FILE ASAP7_SRAM_GDS} \
    [file join $SRAM_ROOT gds srambank_32b.gds]]
set SRAM_SIM_VERILOG [mcu_resolve_path SRAM_SIM_VERILOG \
    {ASAP7_SRAM_VERILOG_FILE ASAP7_SRAM_VERILOG} \
    [file join $SRAM_ROOT generated verilog "$SRAM_MASTER.v"]]

set SRAM_TAG_LIB [mcu_resolve_path SRAM_TAG_LIB \
    {ASAP7_SRAM_TAG_LIB_FILE} \
    [file join $SRAM_ROOT generated LIB "$SRAM_TAG_MASTER.lib"]]
set SRAM_TAG_LEF [mcu_resolve_path SRAM_TAG_LEF \
    {ASAP7_SRAM_TAG_LEF_FILE} \
    [mcu_prefer_fixed_lef [mcu_sram_lef_path $SRAM_ROOT $SRAM_TAG_MASTER]]]
set SRAM_TAG_SIM_VERILOG [mcu_resolve_path SRAM_TAG_SIM_VERILOG \
    {ASAP7_SRAM_TAG_VERILOG_FILE} \
    [file join $SRAM_ROOT generated verilog "$SRAM_TAG_MASTER.v"]]

# Ca hai .lib SRAM chi co o goc TT; ca ba library_set dung chung.
set ALL_TIMING_LIBS    [concat $STD_LIBS    [list $SRAM_LIB $SRAM_TAG_LIB]]
set ALL_TIMING_LIBS_SS [concat $STD_LIBS_SS [list $SRAM_LIB $SRAM_TAG_LIB]]
set ALL_TIMING_LIBS_FF [concat $STD_LIBS_FF [list $SRAM_LIB $SRAM_TAG_LIB]]

# -----------------------------------------------------------------------------
# Derate bu cho goc .lib con thieu cua 84 macro SRAM.
#
# Ba library_set o tren deu tro toi CUNG hai file .lib, nen 84 macro co dung
# mot bo so tre o view_ss, view_tt va view_ff.  Hau qua:
#   - o SS : macro qua NHANH -> setup lac quan.  Run 2026-09-12 05:50 co bon
#            duong te thu 4..7 (4 ps) ket thuc tai u_dtcm/.../u_sram/wd[31],
#            tuc dung o chan du lieu macro; 4 ps do khong that.
#   - o FF : macro qua CHAM -> hold lac quan sau CTS.
#
# Derate duoi day chi ap cho macro, khong dung toi standard cell (chung da co
# .lib rieng tung goc nen derate them la phat hai lan).  Huong luon BI QUAN nen
# no khong bao gio giau duoc mot vi pham - cung lam, la bao thua.
#
# Con so: ASAP7 TT = 0.70 V / 25 C, SS = 0.63 V / 100 C, FF = 0.77 V / 0 C.
# 1.30 / 0.75 la muc thuong dung cho macro thieu goc o muc chenh PVT nay.
# KHI NAO PDK sinh du .lib SRAM cho SS/FF: dat ca hai ve 1.0, roi xoa khoi 9c
# trong genus/tcl/genus.tcl va khoi derate trong innovus/tcl/innovus.tcl.
#
# Genus va Innovus PHAI dung cung hai con so nay, neu khong hold o FF sau CTS
# se lac quan hon setup o SS ma khong ai nhan ra.  Do la ly do chung nam o day
# chu khong nam trong tung flow.
set SRAM_DERATE_SS 1.30
set SRAM_DERATE_FF 0.75

# The macro data/control pins have a 0.320 ns Liberty max-transition.
set SIGNAL_MAX_TRANSITION_PS 300.0
set SIGNAL_MAX_TRANSITION_NS 0.300

puts "============================================================"
puts "MCU ASAP7 CONFIGURATION"
puts " - Root source  : $ASAP7_ROOT_SOURCE"
puts " - ASAP7 root   : $ASAP7_ROOT"
puts " - Stdcell root : $STDCELL_ROOT"
puts " - SRAM root    : $SRAM_ROOT"
puts " - Top          : $TOP"
puts "============================================================"
