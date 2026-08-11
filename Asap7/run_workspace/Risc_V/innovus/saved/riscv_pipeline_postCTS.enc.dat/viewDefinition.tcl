if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name libset_tt\
   -timing\
    [list ${::IMEX::libVar}/mmmc/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib\
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib]
create_op_cond -name opcond_tt_0p7v_25c -library_file ${::IMEX::libVar}/mmmc/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib -P 1 -V 0.7 -T 25
create_rc_corner -name rc_typ\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -T 25\
   -qx_tech_file ${::IMEX::libVar}/mmmc/rc_typ/qrcTechFile_typ03_scaled4xV06
create_delay_corner -name dc_tt\
   -library_set libset_tt\
   -opcond_library opcond_tt_0p7v_25c\
   -rc_corner rc_typ
create_constraint_mode -name mode_func\
   -sdc_files\
    [list ${::IMEX::dataVar}/mmmc/modes/mode_func/mode_func.sdc]
create_analysis_view -name view_tt -constraint_mode mode_func -delay_corner dc_tt -latency_file ${::IMEX::dataVar}/mmmc/views/view_tt/latency.sdc
set_analysis_view -setup [list view_tt] -hold [list view_tt]
