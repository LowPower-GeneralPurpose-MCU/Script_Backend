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

set TECH_LEF [mcu_resolve_path TECH_LEF \
    {ASAP7_TECH_LEF_FILE} \
    [file join $STDCELL_ROOT techlef_misc asap7_tech_4x_201209.lef]]
set RVT_CELL_LEF [mcu_resolve_path RVT_CELL_LEF \
    {ASAP7_RVT_LEF_FILE} \
    [file join $STDCELL_ROOT LEF scaled asap7sc7p5t_28_R_4x_220121a.lef]]
set LVT_CELL_LEF [mcu_resolve_path LVT_CELL_LEF \
    {ASAP7_LVT_LEF_FILE} \
    [file join $STDCELL_ROOT LEF scaled asap7sc7p5t_28_L_4x_220121a.lef]]
set CELL_LEFS [list \
    $RVT_CELL_LEF \
    $LVT_CELL_LEF]
set QRC_FILE [mcu_resolve_path QRC_FILE \
    {ASAP7_QRC_FILE} \
    [file join $STDCELL_ROOT qrc qrcTechFile_typ03_scaled4xV06]]

# One generated 256x4x32 block contains 1024 words x 32 bits = 4 KiB.
# The MCU address map exposes 128 KiB, hence 32 physical macro instances.
set SRAM_MASTER         "srambank_256x4x32_6t122"
set SRAM_ROWS           4
set SRAM_COLS           8
set SRAM_EXPECTED_COUNT [expr {$SRAM_ROWS * $SRAM_COLS}]
set SRAM_CAPACITY_BYTES [expr {$SRAM_EXPECTED_COUNT * 1024 * 4}]

set SRAM_LIB [mcu_resolve_path SRAM_LIB \
    {ASAP7_SRAM_LIB_FILE ASAP7_SRAM_LIB} \
    [file join $SRAM_ROOT generated LIB "$SRAM_MASTER.lib"]]
set SRAM_LEF [mcu_resolve_path SRAM_LEF \
    {ASAP7_SRAM_LEF_FILE ASAP7_SRAM_LEF} \
    [file join $SRAM_ROOT generated LEF 4xLEF \
        "$SRAM_MASTER.lef.4x.lef"]]
set SRAM_GDS [mcu_resolve_path SRAM_GDS \
    {ASAP7_SRAM_GDS_FILE ASAP7_SRAM_GDS} \
    [file join $SRAM_ROOT gds srambank_32b.gds]]
set SRAM_SIM_VERILOG [mcu_resolve_path SRAM_SIM_VERILOG \
    {ASAP7_SRAM_VERILOG_FILE ASAP7_SRAM_VERILOG} \
    [file join $SRAM_ROOT generated verilog "$SRAM_MASTER.v"]]

set ALL_TIMING_LIBS [concat $STD_LIBS [list $SRAM_LIB]]

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
