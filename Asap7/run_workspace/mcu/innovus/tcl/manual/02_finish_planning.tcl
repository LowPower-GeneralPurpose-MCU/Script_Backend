############################################################
## Ket thuc buoc 2 (Hierarchy trang 36, 10_Macro trang 14)
## Go trong console Innovus cua session 02_planning.tcl.
############################################################

# Snap goc moi SRAM ve luoi site/row (thay cho refine_macro_place cua slide,
# lenh do co the doi cho macro ma ban vua xep).
set core_llx [dbGet top.fPlan.coreBox_llx]
set core_lly [dbGet top.fPlan.coreBox_lly]
foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
    foreach record [soc_group_records $group] {
        lassign $record name ptr
        lassign [lindex [dbGet $ptr.pt] 0] x y
        set sx [soc_snap_near $x $core_llx $SOC_SITE_W]
        set sy [soc_snap_near $y $core_lly $SOC_ROW_H]
        if {abs($sx - $x) > 1e-4 || abs($sy - $y) > 1e-4} {
            set orient [dbGet $ptr.orient]
            dbSet $ptr.pStatus unplaced
            placeInstance $name $sx $sy $orient
        }
    }
}

# snapFPlan cua slide chay TRUOC kiem tra, vi no co the dich macro them.
snapFPlan -block

set errors [soc_check_macros ./reports/sram_macro_check_final.rpt]
if {[llength $errors] > 0} {
    foreach e [lrange $errors 0 19] {
        puts "ERROR: $e"
    }
    error "[llength $errors] loi vi tri SRAM - xem reports/sram_macro_check_final.rpt"
}

# Slide trang 14: sau khi chinh tay phai FIXED de place/opt khong dich macro.
foreach {group kind cols rows prefixes} $SOC_SRAM_GROUPS {
    foreach record [soc_group_records $group] {
        dbSet [lindex $record 1].pStatus fixed
    }
}

# Dat lai halo phong khi macro vua bi unplace/place lai.
addHaloToBlock -allBlock $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO $SOC_MACRO_HALO

saveFPlan ./outputs/FloorPlan_withMacro.fp
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_macroFP.rpt
saveDesign ./saved/${TOP}_macroFP.enc

soc_banner "BUOC 2 HOAN TAT - 84 SRAM FIXED
 - outputs/FloorPlan_withMacro.fp
 - saved/${TOP}_macroFP.enc
Tiep theo (session moi): innovus -files tcl/manual/03_powerGrid.tcl"
