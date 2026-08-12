# =============================================================================
# Step 03: power plan and top-level pin assignment.
#
# Paste after 02_pnr_context:
#   source ./tcl/steps/03_power_pins.tcl
# =============================================================================

riscv_step_banner "STEP 03: power plan and pins"

setAddStripeMode -reset
setAddStripeMode -allow_jog none
setAddStripeMode -trim_antenna_back_to_shape core_ring
setAddStripeMode -split_vias true
setAddStripeMode -via_using_exact_crossover_size false

clearGlobalNets
deleteAllPowerPreroutes

globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets

set vss_ring_offset [expr {$RING_OFFSET + $RING_WIDTH + $RING_SPACING}]
set ring_guard_span [expr {$vss_ring_offset + $RING_WIDTH + 0.160}]

set die_core_margin_left [expr {$core_llx - $power_die_llx}]
set die_core_margin_bottom [expr {$core_lly - $power_die_lly}]
set die_core_margin_right [expr {$power_die_urx - $core_urx}]
set die_core_margin_top [expr {$power_die_ury - $core_ury}]
foreach {side margin} [list \
    left $die_core_margin_left \
    bottom $die_core_margin_bottom \
    right $die_core_margin_right \
    top $die_core_margin_top] {
    if {$ring_guard_span > $margin} {
        error "M8/M9 core-ring guarded reach $ring_guard_span exceeds $side die-to-core margin $margin"
    }
}

addRing -nets {VDD} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $RING_WIDTH \
    -spacing $RING_SPACING \
    -offset $RING_OFFSET \
    -snap_wire_center_to_grid Grid

addRing -nets {VSS} \
    -type core_rings \
    -follow core \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width $RING_WIDTH \
    -spacing $RING_SPACING \
    -offset $vss_ring_offset \
    -snap_wire_center_to_grid Grid

create_left_m9_ring_pg_pins $core_llx $core_lly $core_ury

setAddStripeMode -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} \
    -layer M7 -direction vertical \
    -width $M67_WIDTH -spacing $M67_SPACING \
    -set_to_set_distance $M67_SET_PITCH \
    -start_from left -start_offset $M67_OFFSET \
    -snap_wire_center_to_grid grid

setAddStripeMode -reset
setAddStripeMode \
    -allow_jog none \
    -split_vias true \
    -via_using_exact_crossover_size false \
    -stacked_via_bottom_layer M6 \
    -stacked_via_top_layer M7
addStripe -nets {VDD VSS} \
    -layer M6 -direction horizontal \
    -width $M67_WIDTH -spacing $M67_SPACING \
    -set_to_set_distance $M67_SET_PITCH \
    -start_from bottom -start_offset $M67_OFFSET \
    -snap_wire_center_to_grid grid

editTrim -nets {VDD VSS}
clearDrc

setPinConstraint -cell $TOP -corner_to_pin_distance 8
source ./tcl/pins.tcl

verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
    -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_pg.rpt
verify_drc -report ./verify_rpt/drc_after_pg.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_after_pg.rpt
assert_clean_drc_report ./verify_rpt/drc_after_pg.rpt

saveDesign ./saved/${TOP}_powerplan.enc

riscv_step_banner "STEP 03 DONE: saved/${TOP}_powerplan.enc"

