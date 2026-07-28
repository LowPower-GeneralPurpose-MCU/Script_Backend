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
set SRAM_GDS "${SRAM_ROOT}/gds/srambank_32b.gds"

# Simulation-only model. Do not synthesize this reg-array model.
set SRAM_SIM_VERILOG \
    "${SRAM_ROOT}/generated/verilog/${SRAM_MASTER}.v"

# ------------------------------------------------------------------
# 4x Innovus database dimensions.
# These placement values are routability heuristics, not direct DRM
# macro-to-macro minimum rules. Signoff remains Calibre DRC/LVS.
# ------------------------------------------------------------------
set FLOORPLAN_GRID 0.384

# ASAP7 7.5-track standard-cell row is 0.270 um in native coordinates and
# 1.080 um in the 4x Innovus database.  The run log confirms this site height:
# the old database-derived two-row halo was 2.160 um.
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

# The die-to-core margin is also two rows.  With the SRAM array placed directly
# on the lower-left core boundary, the outer hard blockage can extend to the
# die boundary while retaining exactly two rows around the physical SRAM bbox.
set margin_dist $SRAM_BLOCKAGE_BORDER

# Place the rectangular island directly against the lower-left core boundary.
# The two-row protection area is supplied by the die-to-core margin and the
# group hard placement blockage, not by an additional edge gap.
set SRAM_EDGE_GAP_X 0.000
set SRAM_EDGE_GAP_Y 0.000

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
# With the current macro size this gives a core close to the reference
# corner-island floorplan aspect ratio.
set LOGIC_REGION_WIDTH  600.000
set LOGIC_REGION_HEIGHT 260.000

# The generated SRAM has the main signal pins near its local BOTTOM edge.
# R180 moves those pins to physical TOP, generally toward the core area.
# Only R0/R180 are legal; no R90/R270 is used.
set SRAM_ISLAND_ORIENT R180

# Always convert the raw concurrent-macro result into a complete deterministic
# 4x4 array before finish_macroFP.tcl.  Set this to 0 only for an intentional
# manual study of the raw GigaPlace result.
set SRAM_AUTO_PACK_4X4 1

# ------------------------------------------------------------------
# Temporary PG resource model used by concurrent macro placement.
#
# This follows the hierarchy-layout slide:
#   temporary M4/M5 rings and stripes
#   -> create_pg_model_for_macro_place
#   -> source the generated model
#   -> delete the temporary PG shapes
#
# These values model routing-resource consumption only.  The final PG
# topology is still created later by power_plan.tcl.
# ------------------------------------------------------------------
set SRAM_PG_MODEL_FILE \
    "./outputs/golden_mimic_sram_power_mesh.tcl"

set SRAM_PG_MODEL_RING_W       0.096
set SRAM_PG_MODEL_RING_S       0.288
set SRAM_PG_MODEL_STRIPE_W     0.096
set SRAM_PG_MODEL_STRIPE_S     0.288
set SRAM_PG_MODEL_STRIPE_PITCH 25.920

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
