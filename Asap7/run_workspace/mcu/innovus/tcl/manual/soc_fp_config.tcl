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
set SOC_EDGE_GAP    0.0           ;# macro -> mep loi (10_Macro Priority 3: sat bien block;
                                  ;#  cap VSS/VDD mep cum nam trong le loi->die)
set SOC_GROUP_GAP   20.0          ;# giua hai nhom macro / nhom macro va logic

# ---- SRAM (10_Macro trang 11-14, Hierarchy trang 34-35) -------------------
set SOC_MACRO_GAP_ROWS 4          ;# khe giua hai SRAM, du 1 cap VDD/VSS
set SOC_HALO_ROWS      2          ;# halo quanh moi SRAM
set SOC_MACRO_GAP  [expr {$SOC_MACRO_GAP_ROWS * $SOC_ROW_H}]
set SOC_MACRO_HALO [expr {$SOC_HALO_ROWS * $SOC_ROW_H}]

# Kenh dat buffer trong tuong SRAM RAM_LO/RAM_HI (4 cot, cao het loi), o khe
# cot 0|1 va cot 2|3.  Run 2026-09-17 khe nao cung 4.32 (row bi cat) -> CTS
# khong dat duoc buffer trong tuong, chan clk SRAM cach mep tuong 190-440 um:
# 45 chan clk slew 57-172 ps > 46 ps (Liberty).  Cot sat mep tuong (~65 um) OK.
# Kenh = 4.32 cap VSS/VDD cum trai + 8.64 row + 4.32 cap VSS/VDD cum phai;
# phai >= 2 khe de soc_sram_islands tach cum, boi so site 0.216.
set SOC_WALL_CHANNEL        17.28
set SOC_WALL_CHANNEL_GROUPS {RAM_LO RAM_HI}
# floorPlan lam tron be rong loi (2190.888 -> 2190.816): KHOI 3 nap file vi tri
# SRAM van chap nhan loi lech toi nay o mep phai, dich cum sat mep phai theo.
set SOC_CORE_SNAP_TOL 0.432

# Nhom SRAM = cac macro cung module, dat thanh mot cum va co luoi nguon
# M4/M5 rieng (soc_island_pg).
#   ten    master(big|tag)  cot  hang  tien to instance
# big = SRAM_MASTER (256x4x32), tag = SRAM_TAG_MASTER (128x4x20).
set SOC_SRAM_GROUPS {
    RAM_LO  big 4 8 {u_axi_ram_lo/}
    RAM_HI  big 4 8 {u_axi_ram_hi/}
    CACHE   big 8 2 {u_icache/ u_dcache/ u_itcm/ u_dtcm/}
    TAG     tag 2 2 {u_icache/ u_dcache/}
}
# Vi tri SRAM da xep tay (soc_save_sram_place ghi, KHOI 3 nap neu file ton tai).
set SOC_SRAM_PLACE_FILE ./tcl/manual/soc_sram_place.tcl
# Vi tri mam do KHOI 3 cua tcl/innovus.tcl dat (sau do ban keo lai trong GUI):
#   RAM_LO sat mep trai, RAM_HI sat mep phai, CACHE giua sat mep duoi,
#   TAG ben phai CACHE.  Muon doi thi sua proc soc_layout (soc_fp_procs.tcl).

# ---- Power (Hierarchy trang 37-41) ----------------------------------------
# Ring loi M8/M9 va luoi M6/M7: so cua Risc_V.
# Ring loi 2 vong trong le loi->die (tu ngoai vao):
#   mep die | trong S | VSS rong W | trong S | VDD rong W | trong | mep loi
# Khoang trong trong cung (con lai) phai >= SOC_MACRO_GAP de chua cap M4/M5 mep cum SRAM.
# W/S phai la boi CHAN cua manufacturing grid 0.004 (tam day nam tren grid):
# 0.54 = 135*0.004 le -> Innovus tu nang len 0.544 (IMPPP-152), vong VSS sat
# mep die lo ra ngoai 4 nm va bi bo (IMPPP-220).
set SOC_MFG_GRID    0.004
set SOC_CORE_RING_W 0.544         ;# ~0.5 row, 136*0.004
set SOC_CORE_RING_S 0.544         ;# khoang trong giua 2 vong va giua VSS - mep die
set SOC_MESH_W           0.640
set SOC_MESH_S           0.288
set SOC_MESH_PITCH      34.560
set SOC_MESH_OFFSET     17.280

# Luoi nguon rieng cho tung cum SRAM (thay addRing -around shared_cluster, xem
# soc_island_pg): 1 cap VSS/VDD o moi mep cum va moi khe 4.32 giua SRAM.
#   M4 ngang: mep duoi, mep tren, moi khe giua hai hang
#   M5 doc  : mep trai, mep phai, moi khe giua hai cot
#   M5 tap  : moi SRAM mot cap o canh phai, tu khe ben duoi an len chan M4
# So lay tu sram_axi/innovus/tcl/sram_island_power.tcl (da route sach).
set SOC_ISLAND_PG_W 0.096
set SOC_ISLAND_PG_S 0.288
set SOC_PIN_TAP_DEPTH  [expr {8 * $SOC_ROW_H}]     ;# tap an vao than SRAM
set SOC_PIN_TAP_BORDER [expr {2 * $SOC_ROW_H}]     ;# tap nam trong 2 row sat canh phai
set SOC_PG_EPS 0.192
array set SOC_PG_PITCH  {M4 0.192 M5 0.192}
array set SOC_PG_OFFSET {M4 0.012 M5 0.000}

# Stripe M5 doc de noi rail M1 cua std cell (Risc_V: pitch 25.92).
set SOC_M5_W      0.096
set SOC_M5_S      0.288
set SOC_M5_PITCH 25.920
set SOC_M5_OFFSET 12.960
