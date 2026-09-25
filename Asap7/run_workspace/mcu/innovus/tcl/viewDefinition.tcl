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

# -----------------------------------------------------------------------------
# GOC RC - MAC DINH KHONG CO BIEN THIEN (he so 1.0)
#
# ASAP7 chi ship MOT GOC qrcTechFile (typ03), o hai ti le: unscaledV02 (1x,
# MCU_SCALE=1, mac dinh) va scaled4xV06 (4x) - QRC_FILE trong project_config.tcl
# chon theo MCU_SCALE.  Ca rc_typ,
# rc_ss va rc_ff deu tro toi no.  Doc reports/analysis_views.rpt cua run
# 2026-09-20: ba rc_corner chi khac nhau o nhiet do (100 / 25 / 0), con
# preRoute_res / postRoute_res / preRoute_cap / postRoute_cap / postRoute_xcap
# deu = 1.  Tuc la:
#   - view_ss (setup) dung RC DANH DINH -> setup lac quan
#   - view_ff (hold)  dung RC DANH DINH -> hold  lac quan
# Day dung la lo hong ma SRAM_DERATE_SS/FF da bit cho .lib, nhung chua ai bit
# cho RC.  Khong co file QRC khac thi cach duy nhat la nhan he so.
#
# Mac dinh de 1.0 (khong doi hanh vi cua run hien tai).  Bat khi can signoff:
#   export MCU_RC_CMAX=1.15   MCU_RC_CMIN=0.85
# Luu y truoc khi bat: hold cuoi cung cua run 2026-09-20 chi con +0.021 ns nen
# rat co the am tro lai va phai chay lai optDesign -postRoute -hold.
# -----------------------------------------------------------------------------
set MCU_RC_CMAX 1.0
set MCU_RC_CMIN 1.0
foreach rc_var {MCU_RC_CMAX MCU_RC_CMIN} {
    if {[info exists ::env($rc_var)] && $::env($rc_var) ne ""} {
        if {![string is double -strict $::env($rc_var)] || $::env($rc_var) <= 0} {
            error "$rc_var phai la so duong, dang la '$::env($rc_var)'"
        }
        set $rc_var [expr {double($::env($rc_var))}]
    }
}

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
        create_rc_corner -name rc_ss \
            -preRoute_res $MCU_RC_CMAX -postRoute_res $MCU_RC_CMAX \
            -preRoute_cap $MCU_RC_CMAX -postRoute_cap $MCU_RC_CMAX \
            -postRoute_xcap $MCU_RC_CMAX \
            -preRoute_clkres 0.0 -preRoute_clkcap 0.0 -T 100 -qx_tech_file $QRC_FILE
        create_rc_corner -name rc_ff \
            -preRoute_res $MCU_RC_CMIN -postRoute_res $MCU_RC_CMIN \
            -preRoute_cap $MCU_RC_CMIN -postRoute_cap $MCU_RC_CMIN \
            -postRoute_xcap $MCU_RC_CMIN \
            -preRoute_clkres 0.0 -preRoute_clkcap 0.0 -T 0 -qx_tech_file $QRC_FILE
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
puts "Goc RC: rc_ss x$MCU_RC_CMAX (setup) ; rc_ff x$MCU_RC_CMIN (hold) ;\
 rc_typ x1.0 - deu tu [file tail $QRC_FILE]"
if {$MCU_RC_CMAX == 1.0 && $MCU_RC_CMIN == 1.0} {
    puts "WARNING: ===================================================="
    puts "WARNING: ba goc RC dung CUNG mot qrcTechFile voi he so 1.0, chi"
    puts "WARNING: khac nhiet do -> setup o SS va hold o FF deu tinh tren RC"
    puts "WARNING: danh dinh.  Khong dung de sign-off."
    puts "WARNING: Bat: export MCU_RC_CMAX=1.15 MCU_RC_CMIN=0.85"
    puts "WARNING: ===================================================="
}

