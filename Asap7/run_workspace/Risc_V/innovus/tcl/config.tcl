# =============================================================================
# Central configuration for the RISC-V ASAP7 Innovus flow.
# Run directory: Asap7/run_workspace/Risc_V/innovus
# =============================================================================

set TOP riscv_pipeline

if {[info exists ::env(ASAP7_HOME)]} {
    set ASAP7 [file normalize $::env(ASAP7_HOME)]
} else {
    set ASAP7 "/home/user1/Desktop/asap7"
}

set PDK_ROOT     [file join $ASAP7 asap7sc7p5t_28]
set TECH_LEF_DIR [file join $PDK_ROOT techlef_misc]
set CELL_LEF_DIR [file join $PDK_ROOT LEF scaled]
set LIB_DIR      [file join $PDK_ROOT LIB CCS]
set GDS_DIR      [file join $PDK_ROOT GDS]
set QRC_FILE     [file join $PDK_ROOT qrc qrcTechFile_typ03_scaled4xV06]

set TECH_LEF [file join $TECH_LEF_DIR asap7_tech_4x_201209.lef]
set CELL_LEFS [list \
    [file join $CELL_LEF_DIR asap7sc7p5t_28_R_4x_220121a.lef] \
    [file join $CELL_LEF_DIR asap7sc7p5t_28_L_4x_220121a.lef]]

set RVT_LIBS [list \
    [file join $LIB_DIR asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib] \
    [file join $LIB_DIR asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib] \
    [file join $LIB_DIR asap7sc7p5t_AO_RVT_TT_ccs_211120.lib] \
    [file join $LIB_DIR asap7sc7p5t_OA_RVT_TT_ccs_211120.lib] \
    [file join $LIB_DIR asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib]]

set LVT_LIBS [list \
    [file join $LIB_DIR asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib] \
    [file join $LIB_DIR asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib] \
    [file join $LIB_DIR asap7sc7p5t_AO_LVT_TT_ccs_211120.lib] \
    [file join $LIB_DIR asap7sc7p5t_OA_LVT_TT_ccs_211120.lib] \
    [file join $LIB_DIR asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib]]

set TIMING_LIBS [concat $RVT_LIBS $LVT_LIBS]

set GDS_MERGE [list \
    [file join $GDS_DIR asap7sc7p5t_28_R_220121a.gds] \
    [file join $GDS_DIR asap7sc7p5t_28_L_220121a.gds]]

set GENUS_OUTPUT_DIR ../genus/outputs
set SYN_NETLIST [file join $GENUS_OUTPUT_DIR ${TOP}_syn.v]
set SYN_SDC     [file join $GENUS_OUTPUT_DIR ${TOP}_syn.sdc]
set SYN_SPEF    [file join $GENUS_OUTPUT_DIR ${TOP}_syn.spef]
set FUNC_SDC    $SYN_SDC
set STREAM_MAP  ./tcl/streamOut.map

# Slide recommendation: module density below 80%, approximately 75% preferred.
# 72% is selected to leave routing headroom for this control-heavy CPU.
set CORE_UTIL   0.72
set CORE_ASPECT 1.00
set FLOORPLAN_GRID 0.384
set CORE_WIDTH  309.120
set CORE_HEIGHT 308.352

# proto_design requires the optional invs_ehfs license. The available license
# reports IMPLIC-90/IMPFM-801, so keep it disabled unless explicitly requested.
set RUN_PROTO_DESIGN 0
if {[info exists ::env(INNOVUS_RUN_PROTO_DESIGN)]} {
    switch -nocase -- $::env(INNOVUS_RUN_PROTO_DESIGN) {
        1 - true - yes - on  { set RUN_PROTO_DESIGN 1 }
        0 - false - no - off { set RUN_PROTO_DESIGN 0 }
        default {
            error "INNOVUS_RUN_PROTO_DESIGN must be 0/1, false/true, no/yes or off/on"
        }
    }
}

# M8/M9 ring geometry.  All values are multiples of the 0.320 um M8/M9
# pitch in the scaled 4x tech LEF.  Width 0.640 um also satisfies the scaled
# long-wire width requirement from the ASAP7 DRM.
set RING_WIDTH   0.640
set RING_SPACING 0.320
set RING_OFFSET  0.320
set CORE_MARGIN  3.840

# Legal values from ASAP7 4x LEF WIDTHTABLE and routing pitches.
set M45_WIDTH       0.480
set M45_SPACING     0.288
set M45_SET_PITCH  12.288
set M45_OFFSET      6.144

set M67_WIDTH       0.640
set M67_SPACING     0.288
set M67_SET_PITCH  25.600
set M67_OFFSET     12.800

set CTS_BUF_CELLS [list \
    BUFx4_ASAP7_75t_R BUFx8_ASAP7_75t_R BUFx12_ASAP7_75t_R \
    BUFx4_ASAP7_75t_L BUFx8_ASAP7_75t_L BUFx12_ASAP7_75t_L]

set CTS_INV_CELLS [list \
    CKINVDCx8_ASAP7_75t_R CKINVDCx12_ASAP7_75t_R CKINVDCx16_ASAP7_75t_R \
    CKINVDCx8_ASAP7_75t_L CKINVDCx12_ASAP7_75t_L CKINVDCx16_ASAP7_75t_L]

set FILLER_CELLS [list \
    FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R \
    FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L]
