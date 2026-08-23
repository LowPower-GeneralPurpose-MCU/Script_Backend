source ./tcl/project_config.tcl

setLibraryUnit -time 1ns -cap 1pf

create_library_set -name libset_tt -timing $ALL_TIMING_LIBS
create_op_cond \
    -name opcond_tt_0p7v_25c \
    -library_file [lindex $STD_LIBS 0] \
    -P 1.0 \
    -V 0.7 \
    -T 25
create_rc_corner \
    -name rc_typ \
    -preRoute_res 1.0 \
    -postRoute_res 1.0 \
    -preRoute_cap 1.0 \
    -postRoute_cap 1.0 \
    -postRoute_xcap 1.0 \
    -preRoute_clkres 0.0 \
    -preRoute_clkcap 0.0 \
    -T 25 \
    -qx_tech_file $QRC_FILE
create_delay_corner \
    -name dc_tt \
    -library_set libset_tt \
    -opcond_library opcond_tt_0p7v_25c \
    -rc_corner rc_typ
create_constraint_mode \
    -name mode_func \
    -sdc_files $INNOVUS_SDC
create_analysis_view \
    -name view_tt \
    -constraint_mode mode_func \
    -delay_corner dc_tt
set_analysis_view -setup {view_tt} -hold {view_tt}

