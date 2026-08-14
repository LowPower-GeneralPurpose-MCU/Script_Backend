if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name libset\
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
    ${::IMEX::libVar}/mmmc/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib\
    ${::IMEX::libVar}/mmmc/srambank_256x4x32_6t122.lib]
create_op_cond -name opcond -library_file ${::IMEX::libVar}/mmmc/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib -P 1 -V 0.7 -T 25
create_rc_corner -name rccorner\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -T 25\
   -qx_tech_file ${::IMEX::libVar}/mmmc/rccorner/qrcTechFile_typ03_scaled4xV06
create_delay_corner -name corner\
   -library_set libset\
   -opcond_library opcond\
   -rc_corner rccorner
create_constraint_mode -name mode_normal\
   -sdc_files\
    [list ${::IMEX::libVar}/mmmc/axi_ram_syn.innovus.sdc]
create_analysis_view -name tt -constraint_mode mode_normal -delay_corner corner
set_analysis_view -setup [list tt] -hold [list tt]
