############################################################
## Shared MCU / ASAP7 project configuration
############################################################

if {![info exists FLOW_ROOT]} {
    set FLOW_ROOT [file dirname [file dirname [file normalize [info script]]]]
}

set TOP "top_soc"

# These revisions are the collateral baseline used to build this flow.
set ASAP7_STDCELL_REVISION "f970bd3c3292b79ae4d022a3ec80533534614066"
set ASAP7_SRAM_REVISION    "522eeccbccefcd66e61893fa1059df24d95e9f86"

if {[info exists ::env(ASAP7_ROOT)] && $::env(ASAP7_ROOT) ne ""} {
    set ASAP7_ROOT [file normalize $::env(ASAP7_ROOT)]
} else {
    # Compatibility fallback for the existing RISC-V/SRAM workspace.
    set ASAP7_ROOT "/home/user1/Desktop/asap7"
    puts "WARNING: ASAP7_ROOT is not set; using $ASAP7_ROOT"
}

set STDCELL_ROOT [file join $ASAP7_ROOT asap7sc7p5t_28]
set SRAM_ROOT    [file join $ASAP7_ROOT asap7_sram_0p0]

set STD_LIB_DIR [file join $STDCELL_ROOT LIB CCS]
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

set TECH_LEF [file join $STDCELL_ROOT techlef_misc asap7_tech_4x_201209.lef]
set CELL_LEFS [list \
    [file join $STDCELL_ROOT LEF scaled asap7sc7p5t_28_R_4x_220121a.lef] \
    [file join $STDCELL_ROOT LEF scaled asap7sc7p5t_28_L_4x_220121a.lef]]
set QRC_FILE [file join $STDCELL_ROOT qrc qrcTechFile_typ03_scaled4xV06]

# One generated 256x4x32 block contains 1024 words x 32 bits = 4 KiB.
# The MCU address map exposes 128 KiB, hence 32 physical macro instances.
set SRAM_MASTER         "srambank_256x4x32_6t122"
set SRAM_ROWS           4
set SRAM_COLS           8
set SRAM_EXPECTED_COUNT [expr {$SRAM_ROWS * $SRAM_COLS}]
set SRAM_CAPACITY_BYTES [expr {$SRAM_EXPECTED_COUNT * 1024 * 4}]

set SRAM_LIB [file join $SRAM_ROOT generated LIB "$SRAM_MASTER.lib"]
set SRAM_LEF [file join $SRAM_ROOT generated LEF 4xLEF "$SRAM_MASTER.lef.4x.lef"]
set SRAM_GDS [file join $SRAM_ROOT gds srambank_32b.gds]
set SRAM_SIM_VERILOG [file join $SRAM_ROOT generated verilog "$SRAM_MASTER.v"]

set ALL_TIMING_LIBS [concat $STD_LIBS [list $SRAM_LIB]]

# The macro data/control pins have a 0.320 ns Liberty max-transition.
set SIGNAL_MAX_TRANSITION_PS 300.0
set SIGNAL_MAX_TRANSITION_NS 0.300

