# =============================================================================
# Step 04: standard-cell placement and post-place PG.
#
# Paste after 03_power_pins:
#   source ./tcl/steps/04_place.tcl
# =============================================================================

riscv_step_banner "STEP 04: placement and post-place PG"

setDelayCalMode -SIAware false -equivalent_waveform_model none
setHierMode -optStage preCTS

setPlaceMode -reset
setPlaceMode \
    -place_global_uniform_density true \
    -place_global_module_aware_spare true \
    -place_global_auto_blockage_in_channel soft \
    -place_detail_preroute_as_obs {2 3} \
    -place_global_cong_effort high \
    -place_design_refine_macro false

place_design
refinePlace

setAddStripeMode -reset
setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M1 \
    -stacked_via_top_layer M6

set lower_pg_area [list $core_llx $power_die_lly $core_urx $power_die_ury]
addStripe -nets {VDD VSS} \
    -layer M5 -direction vertical \
    -width $M45_WIDTH -spacing $M45_SPACING \
    -set_to_set_distance $M45_SET_PITCH \
    -start_from left -start_offset $M45_OFFSET \
    -create_pins 0 \
    -area $lower_pg_area \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1

setSrouteMode -reset
setSrouteMode -viaConnectToShape {stripe}
sroute -nets {VDD VSS} \
    -connect {corePin} \
    -corePinTarget {stripe} \
    -corePinCheckStdcellGeoms \
    -allowJogging 0 \
    -allowLayerChange 0

editTrim -nets {VDD VSS}
clearDrc

verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
    -error 1000 -warning 100 \
    -report ./verify_rpt/connectivity_after_postplace_pg.rpt
verify_drc -report ./verify_rpt/drc_after_postplace_pg.rpt
assert_clean_connectivity_report ./verify_rpt/connectivity_after_postplace_pg.rpt
assert_clean_drc_report ./verify_rpt/drc_after_postplace_pg.rpt

checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_postPlace.rpt
report_timing > ./reports/timing_postPlace.rpt
report_area   > ./reports/area_postPlace.rpt
saveDesign ./saved/${TOP}_postPlace.enc

riscv_step_banner "STEP 04 DONE: saved/${TOP}_postPlace.enc"

