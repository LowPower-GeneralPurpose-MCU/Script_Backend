set INNOVUS_DIR [file dirname [file dirname [file normalize [info script]]]]
set FLOW_ROOT [file dirname $INNOVUS_DIR]

source [file join $FLOW_ROOT genus rtl flow project_config.tcl]

set SYN_NETLIST [file join $FLOW_ROOT genus outputs [format "%s_syn.v" $TOP]]
set SYN_SDC     [file join $FLOW_ROOT genus outputs [format "%s_syn.sdc" $TOP]]

# GDS std cell cho streamOut -merge (KHOI 16): netlist dung ca RVT lan LVT.
# Repo asap7sc7p5t_28 @ f970bd3: GDS 1x, 4000 dbu/um (TAPCELL rong 432 dbu).
set STD_GDS_FILES [list \
    [mcu_resolve_path RVT_CELL_GDS {ASAP7_RVT_GDS_FILE} \
        [file join $STDCELL_ROOT GDS asap7sc7p5t_28_R_220121a.gds]] \
    [mcu_resolve_path LVT_CELL_GDS {ASAP7_LVT_GDS_FILE} \
        [file join $STDCELL_ROOT GDS asap7sc7p5t_28_L_220121a.gds]]]

set INNOVUS_SDC [file join $INNOVUS_DIR outputs \
    [format "%s_syn.innovus.sdc" $TOP]]
set INNOVUS_PATH_GROUPS \
    [file join $INNOVUS_DIR outputs \
        [format "%s_syn.innovus_groups.tcl" $TOP]]

proc mcu_env_double {name default_value minimum} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        return $default_value
    }
    if {![string is double -strict $::env($name)] ||
        $::env($name) < $minimum} {
        error "$name must be a number >= $minimum"
    }
    return [expr {double($::env($name))}]
}

set MCU_TARGET_STD_UTIL [mcu_env_double MCU_TARGET_STD_UTIL 0.55 0.20]
if {$MCU_TARGET_STD_UTIL > 0.75} {
    error "MCU_TARGET_STD_UTIL must not exceed 0.75 before routability review"
}

set MCU_CORE_WIDTH_OVERRIDE  [mcu_env_double MCU_CORE_WIDTH_UM  0.0 0.0]
set MCU_CORE_HEIGHT_OVERRIDE [mcu_env_double MCU_CORE_HEIGHT_UM 0.0 0.0]
