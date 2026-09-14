############################################################
## Buoc 3 (tiep) - noi SRAM, luoi M6/M7, blockage, pin, kiem tra
## Duoc 03_powerGrid.tcl source, hoac go tay sau MCU_STOP_AFTER_RINGS=1.
############################################################

# ---- 3. Noi chan PG cua SRAM vao block ring (Hierarchy trang 38) ----------
setSrouteMode -reset
setSrouteMode \
    -extendNearestTarget true \
    -blockPinRouteWithPinWidth true \
    -viaConnectToShape {blockring}
sroute -connect {blockPin} \
    -blockPinTarget [list $SOC_BLOCKPIN_TARGET] \
    -nets {VSS VDD}

# ---- 4. Luoi toan chip: M7 doc (via len ring M8) va M6 ngang --------------
# M6 cho via xuong M5 de an vao canh doc cua block ring SRAM.
setAddStripeMode -reset
setAddStripeMode \
    -allow_jog none \
    -break_at {block_ring} \
    -split_vias true \
    -via_using_exact_crossover_size false \
    -stacked_via_bottom_layer M7 \
    -stacked_via_top_layer M8
addStripe -nets {VDD VSS} \
    -layer M7 -direction vertical \
    -width $SOC_MESH_W -spacing $SOC_MESH_S \
    -set_to_set_distance $SOC_MESH_PITCH \
    -start_from left -start_offset $SOC_MESH_OFFSET \
    -snap_wire_center_to_grid Grid

setAddStripeMode -reset
setAddStripeMode \
    -allow_jog none \
    -break_at {block_ring} \
    -split_vias true \
    -via_using_exact_crossover_size false \
    -stacked_via_bottom_layer M5 \
    -stacked_via_top_layer M7
addStripe -nets {VDD VSS} \
    -layer M6 -direction horizontal \
    -width $SOC_MESH_W -spacing $SOC_MESH_S \
    -set_to_set_distance $SOC_MESH_PITCH \
    -start_from bottom -start_offset $SOC_MESH_OFFSET \
    -snap_wire_center_to_grid Grid

editTrim -nets {VDD VSS}

# ---- 5. Placement blockage quanh moi SRAM (Hierarchy trang 38) ------------
# Rong hon halo 1 row de phu ca canh ngoai cua block ring.
set blk [expr {($SOC_HALO_ROWS + 1) * $SOC_ROW_H}]
createPlaceBlockage -allMacro -snapToSite -outerRingBySide [list $blk $blk $blk $blk]

# ---- 6. Rail std cell (tuy chon, mac dinh de sau placement) ---------------
if {[info exists ::env(MCU_RAILS_BEFORE_PLACE)] && $::env(MCU_RAILS_BEFORE_PLACE) eq "1"} {
    soc_stdcell_rails
}

# ---- 7. Pin top-level (Hierarchy trang 9-10) -------------------------------
setPinConstraint -cell $TOP -corner_to_pin_distance 8
source ./tcl/manual/soc_pins.tcl

clearDrc

# ---- 8. Kiem tra ----------------------------------------------------------
verifyConnectivity -type special -net {VDD VSS} -noUnroutedNet \
    -error 100000 -warning 1000 \
    -report ./verify_rpt/connectivity_powerplan.rpt
verify_drc -limit 100000 -report ./verify_rpt/drc_powerplan.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_powerplan.rpt

saveDesign ./saved/${TOP}_powerplan.enc

soc_banner "BUOC 3 HOAN TAT - saved/${TOP}_powerplan.enc

Kiem tra truoc khi placement:
  verify_rpt/connectivity_powerplan.rpt : moi SRAM phai co VDD/VSS noi
     (open o chan std cell la binh thuong: rail M1 chua lam)
  verify_rpt/drc_powerplan.rpt          : phai 0 vi pham PG
  GUI: zoom khe giua 2 SRAM phai thay 1 cap VDD/VSS (slide trang 39)
Rail M1 + stripe M5: goi soc_stdcell_rails sau place_design"
