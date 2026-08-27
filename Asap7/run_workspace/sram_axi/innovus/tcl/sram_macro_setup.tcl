############################################################
## ASAP7 SRAM hard-macro setup — 4x4 corner island
##
## Macro:
##   srambank_256x4x32_6t122
## Capacity:
##   1024 words x 32 bits = 4 KiB per macro
##   16 macros             = 64 KiB
############################################################

set DESIGN      "axi_ram"
set SRAM_MASTER "srambank_256x4x32_6t122"

# One rectangular SRAM island at the lower-left core boundary.
set SRAM_ROWS 4
set SRAM_COLS 4
set SRAM_COUNT [expr {$SRAM_ROWS * $SRAM_COLS}]

# Keep the same ASAP7 root convention used by the teacher's scripts.
set SRAM_ROOT "${ASAP7}/asap7_sram_0p0"

set SRAM_LIB "${SRAM_ROOT}/generated/LIB/${SRAM_MASTER}.lib"
set SRAM_LEF "${SRAM_ROOT}/generated/LEF/4xLEF/${SRAM_MASTER}.lef.4x.lef"
# streamOut -merge matches merged structures to design masters by exact name
# and has no remapping parameter, so a file that does not define a structure
# called $SRAM_MASTER is reported only as IMPOGDS-217/218 and exports hollow
# macro outlines.
#
# gds/srambank_32b.gds is the SRAM *primitive library* (bitcell, column,
# sense amp, tap, filler...), not the assembled bank, so it cannot satisfy
# the merge on its own.  Point this at the generated per-macro GDS instead:
#   python3 ./scripts/gds_structure_tool.py list <candidate.gds>
#   export ASAP7_SRAM_GDS=/absolute/path/to/srambank_256x4x32_6t122.gds
if {[info exists ::env(ASAP7_SRAM_GDS)] && $::env(ASAP7_SRAM_GDS) ne ""} {
    set SRAM_GDS $::env(ASAP7_SRAM_GDS)
} else {
    set SRAM_GDS "${SRAM_ROOT}/gds/srambank_32b.gds"
}

# Simulation-only reg-array model, for reference; never read by this flow
# and never synthesized:
#   ${SRAM_ROOT}/generated/verilog/${SRAM_MASTER}.v

# ------------------------------------------------------------------
# 4x Innovus database dimensions.
# These placement values are routability heuristics, not direct DRM
# macro-to-macro minimum rules. Signoff remains Calibre DRC/LVS.
# ------------------------------------------------------------------
set FLOORPLAN_GRID 0.384

# ASAP7 7.5-track standard-cell row is 0.270 um in native coordinates and
# 1.080 um in the 4x Innovus database.  The run log confirms this site height:
# the old database-derived two-row halo was 2.160 um.
set ASAP7_SITE_WIDTH		 0.216
set ASAP7_ROW_HEIGHT             1.080
set SRAM_MACRO_GAP_ROWS          4
set SRAM_BLOCKAGE_BORDER_ROWS    2

set SRAM_MACRO_GAP_X [expr {
	$SRAM_MACRO_GAP_ROWS * $ASAP7_ROW_HEIGHT
}]
set SRAM_MACRO_GAP_Y [expr {
	$SRAM_MACRO_GAP_ROWS * $ASAP7_ROW_HEIGHT
}]
set SRAM_BLOCKAGE_BORDER [expr {
	$SRAM_BLOCKAGE_BORDER_ROWS * $ASAP7_ROW_HEIGHT
}]

set margin_dist $SRAM_BLOCKAGE_BORDER
set SRAM_EDGE_GAP_X 0.0
set SRAM_EDGE_GAP_Y 0.0
# Individual two-row halos exactly meet inside every four-row inter-macro gap.
# The group hard blockage additionally covers all macro bodies and all gaps.
set SRAM_HALO_L $SRAM_BLOCKAGE_BORDER
set SRAM_HALO_B $SRAM_BLOCKAGE_BORDER
set SRAM_HALO_R $SRAM_BLOCKAGE_BORDER
set SRAM_HALO_T $SRAM_BLOCKAGE_BORDER

# The top/right edges of the rectangular group blockage are also two rows from
# the physical SRAM bbox.
set SRAM_ISLAND_ESCAPE_TOP   $SRAM_BLOCKAGE_BORDER
set SRAM_ISLAND_ESCAPE_RIGHT $SRAM_BLOCKAGE_BORDER

# Standard-cell/controller area retained to the right and above island.
# The latest full Innovus run reported pure std-cell density around 0.3%
# because the old 600 x 260 um reserve left a huge amount of unused row area.
# Keep enough right/top routing channel for the AXI wrapper, but do not fill
# the die with empty rows.  Override these from the shell if a larger design or
# route-congestion study needs more room.
proc sram_env_double_or_default {env_name default min_value} {
    if {![info exists ::env($env_name)] || $::env($env_name) eq ""} {
        return $default
    }
    if {![string is double -strict $::env($env_name)]} {
        error "$env_name must be a numeric value in microns"
    }

    set value [expr {double($::env($env_name))}]
    if {$value < $min_value} {
        error "$env_name=$value is too small; minimum allowed is $min_value um"
    }
    return [format %.3f $value]
}

set LOGIC_REGION_WIDTH  [sram_env_double_or_default SRAM_LOGIC_REGION_WIDTH  120.000 80.000]
set LOGIC_REGION_HEIGHT [sram_env_double_or_default SRAM_LOGIC_REGION_HEIGHT  60.000 40.000]

# Use a horizontal mirror pair in every SRAM row.  R0/MY is the orientation
# convention requested for this macro island: MY mirrors the macro around the
# Y axis, so adjacent SRAMs present a symmetric physical interface across the
# four-row gap while keeping the macro width/height unchanged.
#
# The value is a placement pattern, not one orientation for every instance.
# sram_macro_floorplan.tcl derives the orientation from the column index.
set SRAM_ISLAND_ORIENT "R0"
set SRAM_MIRROR_ORIENT "MY"

proc sram_orientation_for_column {column} {
    global SRAM_ISLAND_ORIENT SRAM_MIRROR_ORIENT

    if {![string is integer -strict $column] || $column < 0} {
        error "SRAM column must be a non-negative integer, got $column"
    }
    if {[expr {$column % 2}] == 0} {
        return $SRAM_ISLAND_ORIENT
    }
    return $SRAM_MIRROR_ORIENT
}

# Preferred layers for the CTS leaf route_type.  These are the ONLY knob that
# reaches the leaf nets ending on SRAM clock pins, because clock_opt_design
# marks every clock net fixed and routeDesign then ignores per-net layer
# preferences set afterwards.
#
# Defaults reproduce the original M2/M3 exactly.  Raising the top layer trades
# upper-layer resource across all 175 clock sinks for shorter effective RC on
# the 16 long macro branches; measure IMPCCOPT-1007 and the postRoute
# .tran report before keeping any change.
if {![info exists SRAM_CTS_LEAF_BOTTOM_LAYER]} {
    set SRAM_CTS_LEAF_BOTTOM_LAYER 2
}
if {![info exists SRAM_CTS_LEAF_TOP_LAYER]} {
    set SRAM_CTS_LEAF_TOP_LAYER 3
}

# Always keep SRAM placement as a complete deterministic 4x4 array before
# finish_macroFP.tcl.  Set this to 0 only for an intentional manual GUI study
# of the seed placement.
set SRAM_AUTO_PACK_4X4 1

foreach f [list $SRAM_LIB $SRAM_LEF $SRAM_GDS] {
    if {![file exists $f]} {
        error "Missing ASAP7 SRAM macro view: [file normalize $f]"
    }
}

puts "===================================================="
puts "ASAP7 SRAM CORNER-ISLAND SETUP"
puts " - Design       : $DESIGN"
puts " - Master       : $SRAM_MASTER"
puts " - Array        : ${SRAM_ROWS} rows x ${SRAM_COLS} columns"
puts " - Macro count  : $SRAM_COUNT"
puts " - Liberty      : [file normalize $SRAM_LIB]"
puts " - 4x LEF       : [file normalize $SRAM_LEF]"
puts " - GDS          : [file normalize $SRAM_GDS]"
puts "===================================================="
