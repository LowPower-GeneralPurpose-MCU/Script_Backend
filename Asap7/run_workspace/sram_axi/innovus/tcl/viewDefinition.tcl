############################################################
## MMMC definition for ASAP7 RVT + LVT TT + SRAM macro
## Style follows the teacher's original viewDefinition.tcl.
############################################################

source ./tcl/project_config.tcl

set LIB   "${ASAP7}/asap7sc7p5t_28/LIB/CCS"
set QRC   "${ASAP7}/asap7sc7p5t_28/qrc/qrcTechFile_typ03_scaled4xV06"

source ./tcl/sram_macro_setup.tcl

# Keep the MMMC reader in the same ns/pF unit system as the generated
# Innovus SDC.  This removes the IMPTS-16/17 unit fallback.
setLibraryUnit -time 1ns -cap 1pf

# RVT and LVT standard-cell timing libraries.  This list must match the
# libraries used by Genus so every mapped cell has an Innovus timing model.
set STD_LIB_LIST [list \
    "${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib" \
    "${LIB}/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib" \
    "${LIB}/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib" \
    "${LIB}/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib" \
    "${LIB}/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib" \
]

# SRAM Liberty must be in the same library set so that:
#   - clk setup/hold is visible
#   - clk-to-dataout delay is visible
#   - input capacitances are visible
set LIB_LIST [concat $STD_LIB_LIST [list $SRAM_LIB]]

foreach lib $LIB_LIST {
    if {![file exists $lib]} {
        error "Missing timing library: [file normalize $lib]"
    }
}

create_library_set \
    -name libset \
    -timing $LIB_LIST

create_rc_corner \
    -name rccorner \
    -preRoute_res 1 \
    -postRoute_res 1 \
    -preRoute_cap 1 \
    -postRoute_cap 1 \
    -postRoute_xcap 1 \
    -preRoute_clkres 0 \
    -preRoute_clkcap 0 \
    -T 25 \
    -qx_tech_file $QRC

# RVT is used only as the reference library for the common TT operating
# condition.  Both RVT and LVT remain in libset.
create_op_cond \
    -name opcond \
    -library_file "${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib" \
    -P 1 \
    -V 0.7 \
    -T 25

create_delay_corner \
    -name corner \
    -library_set libset \
    -opcond_library opcond \
    -rc_corner rccorner

if {![file exists $INNOVUS_SDC_FILE]} {
    if {![file exists ./tcl/prepare_innovus_sdc.tcl]} {
        error "Missing $INNOVUS_SDC_FILE and ./tcl/prepare_innovus_sdc.tcl"
    }

    source ./tcl/prepare_innovus_sdc.tcl
    prepare_innovus_sdc $SYN_SDC_FILE $INNOVUS_SDC_FILE $INNOVUS_GROUP_PATH_FILE
}

create_constraint_mode \
    -name mode_normal \
    -sdc_files $INNOVUS_SDC_FILE

create_analysis_view \
    -name tt \
    -constraint_mode mode_normal \
    -delay_corner corner

set_analysis_view \
    -setup {tt} \
    -hold  {tt}
