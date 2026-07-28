############################################################
## Temporary PG model for SRAM concurrent macro placement
##
## Adapted from x_Hierarchy Layout.pdf, page 32:
##   1. Create a temporary M4/M5 ring around each macro.
##   2. Add no-jog M4/M5 stripes over the floorplan.
##   3. Extract and source the macro-placement PG model.
##   4. Delete all temporary STRIPE/BLOCKRING shapes.
##
## This is not the final SRAM/core PG network.
############################################################

foreach required_variable {
    SRAM_PTRS
    SRAM_PG_MODEL_FILE
    SRAM_PG_MODEL_RING_W
    SRAM_PG_MODEL_RING_S
    SRAM_PG_MODEL_STRIPE_W
    SRAM_PG_MODEL_STRIPE_S
    SRAM_PG_MODEL_STRIPE_PITCH
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable before SRAM PG-model creation"
    }
}

set Core_area [dbGet top.fPlan.area]
set CoreSize  [dbGet top.fPlan.coreBox_size]
set FPsize    [dbGet top.fPlan.box_size]
set FPx       [dbGet top.fPlan.box_sizex]
set FPy       [dbGet top.fPlan.box_sizey]

# Do not infer the standard-cell row from the minimum site height.  This
# design contains several sites; use the project-defined ASAP7 7.5T row
# explicitly so the ring offset, halo, gap and blockage use one definition.
set SRAM_MODEL_ROW $ASAP7_ROW_HEIGHT
set SRAM_MODEL_ROW_X2 [expr {2.0 * $SRAM_MODEL_ROW}]

puts "===================================================="
puts "CREATE TEMPORARY SRAM PG RESOURCE MODEL"
puts " - Floorplan : $FPx x $FPy um"
puts " - Core      : $CoreSize"
puts " - Ring      : M4/M5, width $SRAM_PG_MODEL_RING_W"
puts " - Stripe    : M4/M5, pitch $SRAM_PG_MODEL_STRIPE_PITCH"
puts "===================================================="

globalNetConnect VDD \
    -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS \
    -type pgpin -pin VSS -inst * -module {} -override
applyGlobalNets

# Match the slide's topology with ASAP7 preferred directions:
#   top/bottom: M4 horizontal
#   left/right: M5 vertical
addRing \
    -nets {VSS VDD} \
    -type block_rings \
    -around each_block \
    -layer {top M4 bottom M4 left M5 right M5} \
    -width [list \
        top $SRAM_PG_MODEL_RING_W \
        bottom $SRAM_PG_MODEL_RING_W \
        left $SRAM_PG_MODEL_RING_W \
        right $SRAM_PG_MODEL_RING_W] \
    -spacing [list \
        top $SRAM_PG_MODEL_RING_S \
        bottom $SRAM_PG_MODEL_RING_S \
        left $SRAM_PG_MODEL_RING_S \
        right $SRAM_PG_MODEL_RING_S] \
    -offset [list \
        top $SRAM_MODEL_ROW \
        bottom $SRAM_MODEL_ROW \
        left $SRAM_MODEL_ROW \
        right $SRAM_MODEL_ROW]

# No stripe is allowed to jog around a macro.  It terminates at a block ring.
setAddStripeMode \
    -allow_jog none \
    -break_at block_ring

if {$FPy > [expr {1.5 * $SRAM_PG_MODEL_STRIPE_PITCH}]} {
    addStripe \
        -nets {VSS VDD} \
        -layer M4 \
        -direction horizontal \
        -width $SRAM_PG_MODEL_STRIPE_W \
        -spacing $SRAM_PG_MODEL_STRIPE_S \
        -set_to_set_distance $SRAM_PG_MODEL_STRIPE_PITCH \
        -extend_to design_boundary \
        -start_from bottom \
        -start_offset [expr {
            $SRAM_PG_MODEL_STRIPE_PITCH -
            1.5 * $SRAM_MODEL_ROW
        }]
}

if {$FPx > [expr {1.5 * $SRAM_PG_MODEL_STRIPE_PITCH}]} {
    addStripe \
        -nets {VSS VDD} \
        -layer M5 \
        -direction vertical \
        -width $SRAM_PG_MODEL_STRIPE_W \
        -spacing $SRAM_PG_MODEL_STRIPE_S \
        -set_to_set_distance $SRAM_PG_MODEL_STRIPE_PITCH \
        -extend_to design_boundary \
        -start_from left \
        -start_offset [expr {
            $SRAM_PG_MODEL_STRIPE_PITCH -
            1.5 * $SRAM_MODEL_ROW
        }]
}

editTrim -nets {VSS VDD}

# The PG shapes above are a temporary reference.  The generated Tcl stores
# the per-layer routing-resource model used by concurrent macro placement.
if {[file exists $SRAM_PG_MODEL_FILE]} {
    file delete -force $SRAM_PG_MODEL_FILE
}

set pg_model_status [catch {
    create_pg_model_for_macro_place \
        -file $SRAM_PG_MODEL_FILE

    if {![file exists $SRAM_PG_MODEL_FILE]} {
        error "PG model was not generated: $SRAM_PG_MODEL_FILE"
    }

    source $SRAM_PG_MODEL_FILE
} pg_model_message pg_model_options]

# Exactly as in the slide: remove temporary rings and stripes after the
# resource model has been loaded.  No final PG exists at this stage.
editDelete -shape {STRIPE BLOCKRING}
clearDrc

if {$pg_model_status} {
    return -options $pg_model_options $pg_model_message
}

set SRAM_PG_MODEL_CREATED 1

puts "===================================================="
puts "SRAM PG RESOURCE MODEL LOADED"
puts " - Model: $SRAM_PG_MODEL_FILE"
puts " - Temporary STRIPE/BLOCKRING shapes deleted"
puts "===================================================="
