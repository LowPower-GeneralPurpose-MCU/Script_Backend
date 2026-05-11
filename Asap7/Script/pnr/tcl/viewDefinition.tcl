set ASAP7 "../tkvm/asap7"
set LIB "${ASAP7}/asap7sc7p5t_28/LIB/CCS"
set QRC "${ASAP7}/asap7sc7p5t_28/qrc/qrcTechFile_typ03_scaled4xV06"

set LIB_LIST [list ${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib ${LIB}/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib ${LIB}/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib ${LIB}/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib]

create_library_set -name libset -timing $LIB_LIST

create_rc_corner -name rccorner -preRoute_res 1 -postRoute_res 1 -preRoute_cap 1 -postRoute_cap 1 -postRoute_xcap 1 -preRoute_clkres 0 -preRoute_clkcap 0 -T 25 -qx_tech_file $QRC

create_op_cond -name opcond -library_file ${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib -P 1 -V 0.7 -T 25

create_delay_corner -name corner -library_set libset -opcond_library opcond -rc_corner rccorner

create_constraint_mode -name mode_normal -sdc_files ./outputs/Mul32_final.sdc

create_analysis_view -name tt -constraint_mode mode_normal -delay_corner corner

set_analysis_view -setup {tt} -hold {tt}