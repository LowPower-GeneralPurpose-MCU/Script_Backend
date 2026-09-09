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
# -----------------------------------------------------------------------------
# F2 - guong lai cau hinh ba goc cua genus.tcl.
#
# Ban cu khai bao `set_analysis_view -setup {view_tt} -hold {view_tt}`: hold
# duoc kiem o CHINH goc dung cho setup, tuc khong kiem gi ca. CTS va hold-fix
# cua Innovus deu dua vao view hold, nen day la cho phai sua truoc khi chay
# placement.
#
# Cung co che fallback nhu ben Genus: thieu thu vien SS/FF thi canh bao va quay
# ve mot goc, khong lam gay flow. Tat han bang MCU_MULTI_CORNER=0.
#
# SS/FF khong khai bao op_cond tuong minh - de Innovus lay operating condition
# danh dinh cua chinh .lib thay vi ta doan P/V/T.
# -----------------------------------------------------------------------------
proc mcu_libs_present {libs} {
    foreach lib $libs {
        if {![file isfile $lib]} {
            return 0
        }
    }
    return 1
}

set MCU_MULTI_CORNER 1
if {[info exists ::env(MCU_MULTI_CORNER)] && $::env(MCU_MULTI_CORNER) ne ""} {
    set MCU_MULTI_CORNER [expr {$::env(MCU_MULTI_CORNER) ? 1 : 0}]
}

set MCU_SETUP_VIEWS {view_tt}
set MCU_HOLD_VIEWS  {view_tt}

if {$MCU_MULTI_CORNER} {
    set corner_missing {}
    if {![mcu_libs_present $STD_LIBS_SS]} { lappend corner_missing SS }
    if {![mcu_libs_present $STD_LIBS_FF]} { lappend corner_missing FF }

    if {[llength $corner_missing] > 0} {
        puts "WARNING: ===================================================="
        puts "WARNING: khong tim thay du thu vien cho goc: $corner_missing"
        puts "WARNING: -> chi con view_tt.  CTS va hold-fix se KHONG duoc"
        puts "WARNING:    kiem o goc nhanh.  Khong dung de sign-off."
        puts "WARNING: ===================================================="
    } else {
        create_library_set -name libset_ss -timing $ALL_TIMING_LIBS_SS
        create_library_set -name libset_ff -timing $ALL_TIMING_LIBS_FF
        create_rc_corner -name rc_ss -preRoute_res 1.0 -postRoute_res 1.0 -preRoute_cap 1.0 -postRoute_cap 1.0 -postRoute_xcap 1.0 -preRoute_clkres 0.0 -preRoute_clkcap 0.0 -T 100 -qx_tech_file $QRC_FILE
        create_rc_corner -name rc_ff -preRoute_res 1.0 -postRoute_res 1.0 -preRoute_cap 1.0 -postRoute_cap 1.0 -postRoute_xcap 1.0 -preRoute_clkres 0.0 -preRoute_clkcap 0.0 -T 0 -qx_tech_file $QRC_FILE
        create_delay_corner -name dc_ss -library_set libset_ss -rc_corner rc_ss
        create_delay_corner -name dc_ff -library_set libset_ff -rc_corner rc_ff
        create_analysis_view -name view_ss -constraint_mode mode_func -delay_corner dc_ss
        create_analysis_view -name view_ff -constraint_mode mode_func -delay_corner dc_ff
        set MCU_SETUP_VIEWS {view_ss view_tt}
        set MCU_HOLD_VIEWS  {view_ff view_tt}
    }
} else {
    puts "Multi-corner: TAT boi MCU_MULTI_CORNER=0 - chi con view_tt"
}

set_analysis_view -setup $MCU_SETUP_VIEWS -hold $MCU_HOLD_VIEWS
puts "Analysis views: setup = $MCU_SETUP_VIEWS ; hold = $MCU_HOLD_VIEWS"

