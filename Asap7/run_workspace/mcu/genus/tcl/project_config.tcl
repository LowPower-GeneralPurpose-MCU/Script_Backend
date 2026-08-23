set GENUS_DIR [file dirname [file dirname [file normalize [info script]]]]
set FLOW_ROOT [file dirname $GENUS_DIR]

source [file join $FLOW_ROOT flow project_config.tcl]

set RTL_ROOT $FLOW_ROOT
set SDC_FILE [file join $GENUS_DIR tcl constraint.sdc]

