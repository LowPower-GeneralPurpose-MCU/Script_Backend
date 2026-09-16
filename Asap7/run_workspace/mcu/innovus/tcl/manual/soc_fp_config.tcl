############################################################
## Thong so floorplan bang tay cho top_soc (ASAP7, LEF 4x)
## Day la file ban sua.  Cac script 01/02/03 chi doc tu day.
##
## Doi chieu slide thay (ROHM 180 nm) -> ASAP7:
##   gap giua SRAM 20.16 um = 4 row ROHM  -> 4 row ASAP7 = 4.32 um
##   ring SRAM M5/M4 rong 1.92            -> M4 (ngang) / M5 (doc) rong 0.096
##   stripe M4/M5 rong 1.92               -> luoi M6 (ngang) / M7 (doc) 0.64
##   ring loi                              -> M8 (ngang) / M9 (doc)
## Cac so ASAP7 lay tu flow Risc_V va sram_axi da route sach.
############################################################

# ---- Luoi ASAP7 -----------------------------------------------------------
set SOC_SITE_W   0.216
set SOC_ROW_H    1.080

# ---- Kich thuoc loi --------------------------------------------------------
# Mac dinh tu tinh tu nhom SRAM + dien tich std cell.  Dat
# MCU_CORE_WIDTH_UM / MCU_CORE_HEIGHT_UM (xem project_config.tcl) de ep kich thuoc.
set SOC_CORE_MARGIN 10.0          ;# loi -> die, du cho ring M8/M9
set SOC_EDGE_GAP    10.0          ;# macro -> mep loi
set SOC_GROUP_GAP   20.0          ;# giua hai nhom macro / nhom macro va logic

# ---- SRAM (10_Macro trang 11-14, Hierarchy trang 34-35) -------------------
set SOC_MACRO_GAP_ROWS 4          ;# khe giua hai SRAM, du 1 cap VDD/VSS
set SOC_HALO_ROWS      2          ;# halo quanh moi SRAM
set SOC_MACRO_GAP  [expr {$SOC_MACRO_GAP_ROWS * $SOC_ROW_H}]
set SOC_MACRO_HALO [expr {$SOC_HALO_ROWS * $SOC_ROW_H}]

# Nhom SRAM = cac macro cung module, dat thanh mot cum va dung chung mot
# block ring (addRing -around shared_cluster).
#   ten    master(big|tag)  cot  hang  tien to instance
# big = SRAM_MASTER (256x4x32), tag = SRAM_TAG_MASTER (128x4x20).
set SOC_SRAM_GROUPS {
    RAM_LO  big 4 8 {u_axi_ram_lo/}
    RAM_HI  big 4 8 {u_axi_ram_hi/}
    CACHE   big 8 2 {u_icache/ u_dcache/ u_itcm/ u_dtcm/}
    TAG     tag 2 2 {u_icache/ u_dcache/}
}
# Vi tri mam do KHOI 3 cua tcl/innovus.tcl dat (sau do ban keo lai trong GUI):
#   RAM_LO sat mep trai, RAM_HI sat mep phai, CACHE giua sat mep duoi,
#   TAG ben phai CACHE.  Muon doi thi sua proc soc_layout (soc_fp_procs.tcl).

# ---- Power (Hierarchy trang 37-41) ----------------------------------------
# Ring loi M8/M9 va luoi M6/M7: so cua Risc_V.
set SOC_CORE_RING_W      0.480
set SOC_CORE_RING_S      0.480
set SOC_CORE_RING_OFFSET 0.192
set SOC_MESH_W           0.640
set SOC_MESH_S           0.288
set SOC_MESH_PITCH      34.560
set SOC_MESH_OFFSET     17.280

# Block ring quanh cum SRAM: M4 tren/duoi, M5 trai/phai, rong 1 track (0.096,
# nhu sram_axi).  Offset dat canh chung cua hai macro ke nhau vao giua khe.
set SOC_BLOCK_RING_LAYERS {top M4 bottom M4 left M5 right M5}
set SOC_BLOCK_RING_W 0.096
set SOC_BLOCK_RING_S 0.288
set SOC_BLOCK_RING_OFFSET [expr {
    ($SOC_MACRO_GAP - (2.0 * $SOC_BLOCK_RING_W + $SOC_BLOCK_RING_S)) / 2.0
}]

# Stripe M5 doc de noi rail M1 cua std cell (Risc_V: pitch 25.92).
set SOC_M5_W      0.096
set SOC_M5_S      0.288
set SOC_M5_PITCH 25.920
set SOC_M5_OFFSET 12.960

# Dich cua 'sroute -connect blockPin'.  Slide dung nearestTarget; flow
# sram_axi da phai tat nearestTarget.  Mac dinh noi vao block ring.
set SOC_BLOCKPIN_TARGET blockring
