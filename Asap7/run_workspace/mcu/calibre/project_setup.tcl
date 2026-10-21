############################################################
## Bien cho buoc Calibre DRC / LVS cua top_soc.
## Cung khung voi pv/project_setup.tcl cua thay (bien HGVAR_*): scripts/gen_env.tcl
## doi chung thanh scripts/sourceme cho run_drc.sh / run_lvs.sh, scripts/v2lvs.tcl
## source thang file nay.
##
## Duong dan thu vien lay tu chinh innovus/tcl/project_config.tcl nen trung voi
## file Genus/Innovus da dung (ASAP7_ROOT, ASAP7_STDCELL_ROOT ... van ghi de duoc
## nhu o flow chinh).  Moi bien CAL_* / LVS_* / DRC_* duoi day ghi de duoc tu
## dong lenh make (xem Makefile).
############################################################

set CAL_DIR [file dirname [file normalize [info script]]]
set MCU_DIR [file dirname $CAL_DIR]

source [file join $MCU_DIR innovus tcl project_config.tcl]

proc cal_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set HGVAR_DESIGN $TOP
set HGVAR_CORES  [cal_env CAL_CORES 4]
# -hyper can license hyperscaling; CAL_HYPER=0 de bo.
set HGVAR_HYPER  [expr {[cal_env CAL_HYPER 1] ? "-hyper" : ""}]
set HGVAR_CALIBRE [cal_env CALIBRE calibre]
set HGVAR_V2LVS   [cal_env V2LVS v2lvs]
set HGVAR_V2LVS_OPTS [cal_env V2LVS_OPTS "-64 -sn"]

# Dau ra cua KHOI 16 (eco/make finish chay lai nguyen khoi do): GDS, netlist co
# VDD/VSS + filler/tap (saveNetlist -includePowerGround -includePhysicalInst),
# DEF (chi lay TRACKS cho offset luat track cua deck DRC).
set CAL_OUTPUTS [file join $MCU_DIR innovus outputs]
set HGVAR_SIGNOFF_GDS \
    [file normalize [cal_env CAL_GDS [file join $CAL_OUTPUTS ${TOP}.gds]]]
set HGVAR_SIGNOFF_NETLIST_PWR \
    [file normalize [cal_env CAL_NETLIST [file join $CAL_OUTPUTS ${TOP}_pnr_pg.v]]]
set HGVAR_SIGNOFF_DEF \
    [file normalize [cal_env CAL_DEF [file join $CAL_OUTPUTS ${TOP}_pnr.def]]]

# Deck lay ban trong repo: repo asap7sc7p5t_28 goc da bo file .rul (EULA SVRF).
set CAL_RUL_DIR [file normalize [file join $MCU_DIR .. .. asap7 asap7sc7p5t_28 rul]]
set HGVAR_DRC_RULE_FILE \
    [file normalize [cal_env CAL_DRC_DECK [file join $CAL_RUL_DIR calibreDRC.rul]]]
set HGVAR_LVS_RULE_FILE \
    [file normalize [cal_env CAL_LVS_DECK [file join $CAL_RUL_DIR calibreLVS.rul]]]
set HGVAR_DRC_MAX_RESULTS [cal_env DRC_MAX_RESULTS 1000]

# CDL std cell: netlist dung ca RVT (_R) lan LVT (_L).  SRAM, filler va tap
# khong co CDL: v2lvs.tcl sinh .SUBCKT rong cho chung tu cac LEF ben duoi
# (dung LEF Innovus da doc).
set CAL_CDL_DIR [cal_env CAL_CDL_DIR [file join $STDCELL_ROOT CDL LVS]]
set HGVAR_STDCELL_CDL [list \
    [file normalize [file join $CAL_CDL_DIR asap7sc7p5t_28_R.cdl]] \
    [file normalize [file join $CAL_CDL_DIR asap7sc7p5t_28_L.cdl]]]
set HGVAR_SRAM_CDL  {}
set HGVAR_FLASH_CDL {}
set HGVAR_STUB_LEFS [concat $CELL_LEFS [list $SRAM_LEF $SRAM_TAG_LEF]]

# LVS BOX: GDS cua 2 master SRAM chi la hop den (pin + BOUNDARY, ve tu LEF).
# Thay box ca filler/tap; o day mac dinh KHONG box chung: TAPCELL la noi duy
# nhat noi well/substrate vao VDD/VSS, box mat phan do thi bulk moi transistor
# lech.  LVS_BOX_PHYS=1 box them moi master filler/tap (LEF CLASS CORE SPACER /
# WELLTAP) khong co CDL - v2lvs.tcl ghi danh sach cuoi vao run_lvs/lvs_box.list.
set HGVAR_LVS_BOX [list $SRAM_MASTER $SRAM_TAG_MASTER]
set HGVAR_LVS_BOX_PHYS [cal_env LVS_BOX_PHYS 0]

# hcell: top + moi std cell co CDL ma netlist dung (v2lvs.tcl tu dem).
set HGVAR_HCELL_LIST_FILE       hcell.list
set HGVAR_LVS_HCELL_LIST_APPEND {}
set HGVAR_LVS_HCELL_LIST_FILES  {}
