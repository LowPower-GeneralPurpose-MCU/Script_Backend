############################################################
## Project configuration shared by every Innovus session
############################################################

set DESIGN "axi_ram"

if {[info exists ::env(ASAP7_ROOT)] && $::env(ASAP7_ROOT) ne ""} {
    set ASAP7 $::env(ASAP7_ROOT)
} else {
    set ASAP7 "/home/user1/Desktop/asap7"
}

# A foundry/PDK stream-out mapping file is mandatory for final GDS export.
# Set it without editing the flow:
#   export ASAP7_GDS_MAP_FILE=/absolute/path/to/mapfile
if {[info exists ::env(ASAP7_GDS_MAP_FILE)] &&
    $::env(ASAP7_GDS_MAP_FILE) ne ""} {
    set GDS_MAP_FILE $::env(ASAP7_GDS_MAP_FILE)
} else {
    set GDS_MAP_FILE ""
}

set STREAMOUT_UNITS 4000
set POWER_NETS {VDD VSS}

# The SRAM data/control input pins have a 0.320 ns Liberty max-transition
# limit.  Use a tighter design rule to reserve margin for routed RC and SI.
set SIGNAL_MAX_TRANSITION_NS 0.300

set SYN_SDC_FILE "./outputs/${DESIGN}_syn.sdc"
set INNOVUS_SDC_FILE "./outputs/${DESIGN}_syn.innovus.sdc"
set INNOVUS_GROUP_PATH_FILE "./outputs/${DESIGN}_syn.innovus_groups.tcl"

# proto_design requires the separate invs_ehfs capability.  The provided
# Innovus license does not contain it (IMPLIC-90 / IMPFM-801 in the log), so
# use the deterministic hierarchy floorplan by default.  Enable proto only on
# a machine where that license is available:
#   export INNOVUS_RUN_PROTO_DESIGN=1
set RUN_PROTO_DESIGN 0
if {[info exists ::env(INNOVUS_RUN_PROTO_DESIGN)]} {
    switch -nocase -- $::env(INNOVUS_RUN_PROTO_DESIGN) {
        1 - true - yes - on  { set RUN_PROTO_DESIGN 1 }
        0 - false - no - off { set RUN_PROTO_DESIGN 0 }
        default {
            error "INNOVUS_RUN_PROTO_DESIGN must be 0/1, false/true, no/yes or off/on"
        }
    }
}

puts "===================================================="
puts "INNOVUS PROJECT CONFIGURATION"
puts " - Design     : $DESIGN"
puts " - ASAP7 root : $ASAP7"
puts " - Std cells  : RVT + LVT"
puts " - Corner     : TT, 0.7 V, 25 C"
puts " - proto_design: $RUN_PROTO_DESIGN"
puts "===================================================="
