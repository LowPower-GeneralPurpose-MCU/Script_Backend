############################################################
## Buoc 3 - Power grid + pin (Hierarchy trang 37-41, 9-10)
##
##   innovus -files tcl/manual/03_powerGrid.tcl
##
## Dung giua chung de xem trong GUI:
##   MCU_STOP_AFTER_RINGS=1  dung sau ring loi + block ring SRAM
## Thu tu giong powerGrid.tcl cua slide, doi layer theo ASAP7:
##   ring loi M8/M9 -> block ring moi cum SRAM M4/M5 -> sroute blockPin
##   -> luoi M7 doc / M6 ngang -> blockage quanh SRAM -> pin
## Rail M1 + stripe M5 cho std cell de sau placement (soc_stdcell_rails);
## dat MCU_RAILS_BEFORE_PLACE=1 neu muon lam ngay nhu slide.
############################################################

set INNOVUS_DIR [file dirname [file dirname [file dirname [file normalize [info script]]]]]
cd $INNOVUS_DIR

source ./tcl/init_common.tcl
source ./tcl/manual/soc_fp_config.tcl
source ./tcl/manual/soc_fp_procs.tcl

soc_check_groups

if {![file isfile ./outputs/FloorPlan_withMacro.fp]} {
    error "Thieu outputs/FloorPlan_withMacro.fp - chay buoc 2"
}
loadFPlan ./outputs/FloorPlan_withMacro.fp

set unfixed 0
foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
    foreach record [soc_group_records $group] {
        if {[dbGet [lindex $record 1].pStatus] ne "fixed"} {
            incr unfixed
        }
    }
}
if {$unfixed > 0} {
    error "$unfixed SRAM chua FIXED sau loadFPlan - chay lai 02_finish_planning.tcl"
}
set errors [soc_check_macros ./reports/sram_macro_check_powerplan.rpt]
if {[llength $errors] > 0} {
    error "[llength $errors] loi vi tri SRAM sau loadFPlan - xem reports/sram_macro_check_powerplan.rpt"
}

deleteAllPowerPreroutes

# ---- 1. Ring loi M8 ngang / M9 doc (so cua Risc_V) -------------------------
set vss_ring_offset [expr {$SOC_CORE_RING_OFFSET + $SOC_CORE_RING_W + $SOC_CORE_RING_S}]
set ring_reach [expr {$vss_ring_offset + $SOC_CORE_RING_W + 0.160}]
if {$ring_reach > $SOC_CORE_MARGIN} {
    error "Ring loi can $ring_reach um nhung SOC_CORE_MARGIN = $SOC_CORE_MARGIN"
}
setAddStripeMode -reset
foreach {net offset} [list VDD $SOC_CORE_RING_OFFSET VSS $vss_ring_offset] {
    addRing -nets [list $net] \
        -type core_rings -follow core \
        -layer {top M8 bottom M8 left M9 right M9} \
        -width $SOC_CORE_RING_W -spacing $SOC_CORE_RING_S -offset $offset \
        -snap_wire_center_to_grid Grid
}

# ---- 2. Block ring cho TUNG cum SRAM (slide: lap lai cho moi cluster) -----
# Tu dong chon macro cua tung nhom roi addRing -around shared_cluster.
# Lam tay nhu slide: chon cum trong GUI roi go 'soc_ring_selected'.
proc soc_ring_selected {} {
    addRing -nets {VSS VDD} \
        -type block_rings -around shared_cluster \
        -layer $::SOC_BLOCK_RING_LAYERS \
        -width $::SOC_BLOCK_RING_W \
        -spacing $::SOC_BLOCK_RING_S \
        -offset $::SOC_BLOCK_RING_OFFSET
}
foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
    deselectAll
    foreach record [soc_group_records $group] {
        selectInst [lindex $record 0]
    }
    puts "Block ring cho cum $group ([llength [dbGet selected]] macro)"
    soc_ring_selected
}
deselectAll

if {[info exists ::env(MCU_STOP_AFTER_RINGS)] && $::env(MCU_STOP_AFTER_RINGS) eq "1"} {
    soc_banner "DUNG SAU RING - zoom vao khe giua cac SRAM (slide trang 39)
Lam lai mot cum: xoa ring cua cum do, chon cum trong GUI, go soc_ring_selected
Chay tiep: source tcl/manual/03_powerGrid_rest.tcl"
    return
}

source ./tcl/manual/03_powerGrid_rest.tcl
