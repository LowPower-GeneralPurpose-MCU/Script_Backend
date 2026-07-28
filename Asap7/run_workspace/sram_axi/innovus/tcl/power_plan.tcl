############################################################
## Hierarchical power planning for one 4x4 SRAM group
##
## Layer roles:
##   M4/M5 : SRAM shared-cluster ring and local straps/feeders
##   M6/M7 : SRAM-gap grid and regular core mesh
##   M8/M9 : global backbone and core ring
##
## Project restriction:
##   - addStripe is not allowed to jog
##   - sroute is not allowed to jog or change layer
##   - planned layer transitions are made only by stacked ViaGen
############################################################

foreach required_file {
    ./outputs/sram_macro_geometry.tcl
    ./tcl/sram_gap_stripes.tcl
    ./tcl/sram_macro_power.tcl
    ./tcl/core_pg_outside_island.tcl
    ./tcl/stitch_island_to_core.tcl
    ./tcl/global_upper_pg_to_ring.tcl
} {
    if {![file exists $required_file]} {
        error "Missing power-planning prerequisite: [file normalize $required_file]"
    }
}

source ./outputs/sram_macro_geometry.tcl

set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
set core_urx [dbGet top.fPlan.coreBox_urx]
set core_ury [dbGet top.fPlan.coreBox_ury]

setAddStripeMode -allow_jog none

clearGlobalNets
deleteAllPowerPreroutes

globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets

# ------------------------------------------------------------------------
# 1. GLOBAL M8/M9 CORE RING
# ------------------------------------------------------------------------

# ASAP7 4x: 0.480 um corresponds to the 120 nm native long-wire
# minimum for M8/M9.  The complete two-net ring occupies 1.824 um
# including offset, leaving 0.336 um to the die edge inside the
# two-row (2.160 um) die-to-core margin.
set ring_m89_w 0.480
set ring_m89_s 0.480
set ring_m89_o 0.384
set ring_m89_span [expr {
    $ring_m89_o + 2.0 * $ring_m89_w + $ring_m89_s
}]

# Decode the complete die box once.  This avoids depending on release-specific
# scalar aliases such as top.fPlan.box_llx and also removes the nested command
# expression at the location where the failing run reported
# "missing close-bracket".
set power_die_box [join [dbGet top.fPlan.box]]
if {[llength $power_die_box] != 4} {
    error "Cannot decode die box for power planning: [dbGet top.fPlan.box]"
}
lassign $power_die_box \
    power_die_llx power_die_lly power_die_urx power_die_ury

set die_core_margin_left [expr {$core_llx - $power_die_llx}]
set die_core_margin_bottom [expr {$core_lly - $power_die_lly}]
if {$ring_m89_span > $die_core_margin_left ||
    $ring_m89_span > $die_core_margin_bottom} {
    error "M8/M9 core-ring span $ring_m89_span exceeds the lower-left die-to-core margin"
}

addRing \
    -nets {VDD VSS} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $ring_m89_w \
    -spacing $ring_m89_s \
    -offset $ring_m89_o

# PG pins overlap the lower-left ring intersection.
set vdd_m9_right [expr {$core_llx - $ring_m89_o}]
set vdd_m9_left  [expr {$vdd_m9_right - $ring_m89_w}]
set vss_m9_right [expr {$vdd_m9_left - $ring_m89_s}]
set vss_m9_left  [expr {$vss_m9_right - $ring_m89_w}]

set vdd_m8_top    [expr {$core_lly - $ring_m89_o}]
set vdd_m8_bottom [expr {$vdd_m8_top - $ring_m89_w}]
set vss_m8_top    [expr {$vdd_m8_bottom - $ring_m89_s}]
set vss_m8_bottom [expr {$vss_m8_top - $ring_m89_w}]

createPGPin VDD \
    -geom M9 \
    $vdd_m9_left $vdd_m8_bottom \
    $vdd_m9_right $vdd_m8_top \
    -net VDD

createPGPin VSS \
    -geom M9 \
    $vss_m9_left $vss_m8_bottom \
    $vss_m9_right $vss_m8_top \
    -net VSS

# ------------------------------------------------------------------------
# 2. ONE M4/M5 BLOCK RING AROUND THE SRAM HIERARCHY GROUP
# ------------------------------------------------------------------------

set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
if {[llength $SRAM_PTRS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros before group-ring creation"
}

deselectAll
foreach ptr $SRAM_PTRS {
    selectInst [lindex [dbGet $ptr.name] 0]
}

# Follow the hierarchy-layout slide's shared-cluster topology, but map it
# to ASAP7 preferred directions:
#   top/bottom: M4 horizontal
#   left/right: M5 vertical
#
# The full radial span is:
#   1.080 + 0.096 + 0.288 + 0.096 = 1.560 um
# which fits completely inside the two-row (2.160 um) blockage border.
set sram_ring_w 0.096
set sram_ring_s 0.288
set sram_ring_o $ASAP7_ROW_HEIGHT
set sram_ring_span [expr {
    $sram_ring_o + 2.0 * $sram_ring_w + $sram_ring_s
}]
if {$sram_ring_span > $SRAM_BLOCKAGE_BORDER} {
    error "SRAM shared-cluster ring span $sram_ring_span exceeds blockage border $SRAM_BLOCKAGE_BORDER"
}

addRing \
    -nets {VDD VSS} \
    -type block_rings \
    -around shared_cluster \
    -layer {top M4 bottom M4 left M5 right M5} \
    -width $sram_ring_w \
    -spacing $sram_ring_s \
    -offset $sram_ring_o

deselectAll

# ------------------------------------------------------------------------
# 3. LOCAL ISLAND AND EXTERNAL CORE POWER
# ------------------------------------------------------------------------

set stripe_m45_pitch 17.280
set stripe_m67_pitch 25.920

set stripe_m5_w 0.096
set stripe_m5_s 0.288
set stripe_m5_offset 8.640

set stripe_m6_w 0.640
set stripe_m6_s 0.896
set stripe_m6_offset 12.800

set stripe_m7_w 0.640
set stripe_m7_s 0.896
set stripe_m7_offset 12.800

# Every X/Y macro gap receives at least one VDD/VSS pair.
source ./tcl/sram_gap_stripes.tcl

# SRAM M4 pins connect straight to explicit local M4/M5 structures.
source ./tcl/sram_macro_power.tcl

# L-shaped regular core grid; no stripe crosses the rectangular island.
source ./tcl/core_pg_outside_island.tcl

# Straight M6/M7 bridges from island to the external grid.
source ./tcl/stitch_island_to_core.tcl

# M8/M9 backbone extends to the die margin and connects the core ring.
source ./tcl/global_upper_pg_to_ring.tcl

verifyConnectivity \
    -type special \
    -noUnroutedNet \
    -report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt

verify_drc \
    -report ./verify_rpt/pg_drc_before_stdcell_place.rpt

saveDesign ./saved/axi_ram_powerplan.enc

puts "===================================================="
puts "HIERARCHICAL POWER PLAN COMPLETED"
puts " - SRAM group ring : M4/M5, shared_cluster"
puts " - Core ring       : M8/M9"
puts " - addStripe jog   : none"
puts " - sroute jog      : 0"
puts " - sroute layerchange: 0"
puts " - PG connectivity : ./verify_rpt/pg_connectivity_before_stdcell_place.rpt"
puts " - PG DRC          : ./verify_rpt/pg_drc_before_stdcell_place.rpt"
puts "===================================================="
