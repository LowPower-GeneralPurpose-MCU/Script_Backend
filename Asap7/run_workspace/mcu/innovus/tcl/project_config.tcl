set INNOVUS_DIR [file dirname [file dirname [file normalize [info script]]]]
set FLOW_ROOT [file dirname $INNOVUS_DIR]

source [file join $FLOW_ROOT flow project_config.tcl]

set SYN_NETLIST [file join $FLOW_ROOT genus outputs [format "%s_syn.v" $TOP]]
set SYN_SDC     [file join $FLOW_ROOT genus outputs [format "%s_syn.sdc" $TOP]]

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
