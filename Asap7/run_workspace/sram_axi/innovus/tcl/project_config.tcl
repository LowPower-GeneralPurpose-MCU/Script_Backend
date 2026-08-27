############################################################
## Project configuration shared by every Innovus session
############################################################

set DESIGN "axi_ram"

set INNOVUS_PROJECT_ROOT [file normalize [file join [file dirname [info script]] ..]]

if {[info exists ::env(ASAP7_ROOT)] && $::env(ASAP7_ROOT) ne ""} {
    set ASAP7 $::env(ASAP7_ROOT)
} else {
    set ASAP7 "/home/user1/Desktop/asap7"
}

# Use the project-owned density-corrected tech LEF by default.  Geometry stays
# at 4x; only the dimensionless M5/Pad percentages are inherited from 1x.
set project_tech_lef [file normalize [file join \
    $INNOVUS_PROJECT_ROOT .. .. .. asap7 asap7sc7p5t_28 \
    techlef_misc asap7_tech_4x_201209.lef]]
if {[info exists ::env(ASAP7_TECH_LEF_FILE)] &&
    $::env(ASAP7_TECH_LEF_FILE) ne ""} {
    set TECH_LEF_FILE $::env(ASAP7_TECH_LEF_FILE)
} elseif {[file exists $project_tech_lef]} {
    set TECH_LEF_FILE $project_tech_lef
} else {
    set TECH_LEF_FILE \
        "${ASAP7}/asap7sc7p5t_28/techlef_misc/asap7_tech_4x_201209.lef"
}

# A stream-out map is mandatory.  The project map includes routed, PG, pin,
# blockage and metal-fill objects through Pad/M10.
# Override it without editing the flow:
#   export ASAP7_GDS_MAP_FILE=/absolute/path/to/mapfile
if {[info exists ::env(ASAP7_GDS_MAP_FILE)] &&
    $::env(ASAP7_GDS_MAP_FILE) ne ""} {
    set GDS_MAP_FILE $::env(ASAP7_GDS_MAP_FILE)
} else {
    set GDS_MAP_FILE [file normalize \
        [file join $INNOVUS_PROJECT_ROOT tcl streamOut.map]]
}

# Full standard-cell GDS is required for a signoff candidate.  LEF abstracts
# are not a replacement for transistor-level macro geometry during stream-out.
if {[info exists ::env(ASAP7_STDCELL_GDS_FILES)] &&
    $::env(ASAP7_STDCELL_GDS_FILES) ne ""} {
    set STDCELL_GDS_FILES $::env(ASAP7_STDCELL_GDS_FILES)
} else {
    set STDCELL_GDS_FILES [list \
        "${ASAP7}/asap7sc7p5t_28/GDS/asap7sc7p5t_28_L_220121a.gds" \
        "${ASAP7}/asap7sc7p5t_28/GDS/asap7sc7p5t_28_R_220121a.gds" \
    ]
}

# ASAP7 educational LEFs contain neither process antenna rules nor a qualified
# antenna diode.  Enable both route repair and verify_antenna only after a rule
# deck with usable antenna data has been loaded.
set ROUTE_FIX_ANTENNA false
if {[info exists ::env(INNOVUS_RUN_ANTENNA_CHECK)] &&
    [string is true -strict $::env(INNOVUS_RUN_ANTENNA_CHECK)]} {
    set ROUTE_FIX_ANTENNA true
}

set STREAMOUT_UNITS 4000

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
puts " - Tech LEF   : $TECH_LEF_FILE"
puts " - GDS map    : $GDS_MAP_FILE"
puts " - Std cells  : RVT + LVT"
puts " - Corner     : TT, 0.7 V, 25 C"
puts " - proto_design: $RUN_PROTO_DESIGN"
puts "===================================================="
