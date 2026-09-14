############################################################
## Ket thuc buoc 1 (slide Hierarchy trang 29): snap guide, luu FloorPlan.fp
## Go trong console Innovus cua session 01_hierFP.tcl.
############################################################

set bad [soc_report_guides $SOC_STD_AREAS ./reports/guide_util_hierFP_final.rpt]
if {$bad > 0} {
    error "$bad guide co mat do >= [expr {int($SOC_GUIDE_MAX_UTIL * 100)}]% - noi rong roi source lai"
}

snapFPlan -guide
saveFPlan ./outputs/FloorPlan.fp
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_final.rpt
saveDesign ./saved/${TOP}_hierFP.enc

soc_banner "BUOC 1 HOAN TAT
 - outputs/FloorPlan.fp
 - saved/${TOP}_hierFP.enc
Tiep theo (session moi): innovus -files tcl/manual/02_planning.tcl"
