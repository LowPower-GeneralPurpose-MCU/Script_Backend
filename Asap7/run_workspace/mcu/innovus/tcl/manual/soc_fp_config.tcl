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
# Notch (10_Macro Priority 7): vung con row kep giua hai cum SRAM (hoac cum va
# mep loi), hep hon nguong nay -> KHOI 9 dat placement blockage MEM (soft):
# placer khong dat logic vao, CTS/optDesign van dat buffer/inverter.  Khong dung
# blockage cung: run 2026-09-17 CTS dat buffer clk SRAM trong hoc tren TAG
# (837,260) (916,260) (947,264) va khe RAM_LO|dcache (545,97).
# Vi tri hien tai: hoc tren TAG 145.37, khe RAM_LO|dcache 11.45, dtcm|icache
# 5.83, itcm|RAM_HI 3.67, 4 kenh buffer trong tuong RAM 8.64.
set SOC_NOTCH_MAX_W 160.0
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

# Chan PG VDD/VSS cua top (09_PnR tr.21 createPGPin): nam tren doan ring loi
# phia tren (M8) cua tung net - DEF/GDS/LEF abstract co chan nguon cho LVS.
# Tao o KHOI 16 (sau moi editTrim): tao som o KHOI 2 thi mat doan ring M8.
set SOC_PG_PIN_LAYER M8

# ---- Tap cell (10_Macro tr.21 latch-up) -----------------------------------
# Deck calibreDRC.rul ACTIVE.LUP.1: PMOS cach tap N-well <= 30 um (1x) = 120 um
# tren LEF 4x.  Cell va khoang cach theo techlef_misc/example_innovus.tcl cua
# asap7sc7p5t_28 (-cellInterval 50).  Offset 1.08 thay 10.564 cua vi du: row sau
# cutRow co doan hep 3.67-8.64 um (kenh buffer, khe notch) van phai co tap.
set SOC_TAP_CELL     TAPCELL_ASAP7_75t_R
set SOC_TAP_INTERVAL 50.0
set SOC_TAP_OFFSET   1.08
set SOC_TAP_RULE     120.0

# ---- Filler cell ----------------------------------------------------------
# Run 2026-09-18 liet ke ca 4 cell (R truoc, L sau) va Innovus dat 100% ban _L:
# 2044453 FILLER_ASAP7_75t_L + 76331 FILLERxp5_ASAP7_75t_L, 0 cell _R.  Hai ban
# rong bang nhau nen addFiller pha the theo thu tu nap LEF (LEF _L nap sau).
# Logic that lai ~126 k cell RVT / ~23 k LVT, nen filler nen la _R cho khop lop
# implant LVT o bien cell.  Deck calibreDRC.rul cua ASAP7 khong kiem implant nen
# day khong phai loi DRC - doi de dung ban dai dien hon.
# Neu addFiller bao khong dat duoc cell nao (kiem trong log: "Added 0 filler
# inst" cho CA hai cell) thi tra lai danh sach 4 cell o dong duoi.
set SOC_FILLER_CELLS {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R}
#   ca hai Vt: {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L}

# ---- Metal fill (09_PnR tr.26) --------------------------------------------
# Tech LEF asap7_tech_4x_201209.lef chi co luat mat do o M5 (MINIMUMDENSITY 15,
# MAXIMUMDENSITY 90, DENSITYCHECKWINDOW 80 80, STEP 40) va Pad (khong dung);
# deck calibreDRC.rul khong co luat mat do.  -> mac dinh chi fill M5.  M2-M7 co
# RIGHTWAYONGRIDONLY + RECTONLY + WIDTHTABLE (SADP): fill them layer la them rui
# ro DRC ma khong co luat nao doi.
#
# LUAT ON-TRACK - LY THUYET CU DA BI BAC BO 2026-09-20.
#
# calibreDRC.rul co luat that cho M5 (nen cau "off-track khong phai luat foundry
# nao" o phan waiver cu la SAI):
#   M5.AUX.1  "M5 vertical edges must be at a grid of 24 nm"
#             VAR_M5_1X_DBU 240 = 0.024 o 1x = 0.096 o LEF 4x
#   M5.AUX.2  "Minimum width M5 tracks must lie along the vertical routing
#             tracks"
# Diem mau chot: M5.AUX.2 chi ap cho M5 DUNG MIN WIDTH.
#
# So cu ep -minWidth = -maxWidth = 0.096 nen MOI mieng fill deu la min width,
# tuc moi mieng deu buoc phai nam tren track -> run 2026-09-19 23:40 ra 279674
# OFFGRID M5 tren _FILLS_RESERVED.  Do lai CA 38 MB drc_fill.rpt (khong phai
# lay mau): tam cac mieng trai ra 8+ bucket mod 0.192 - 0.096 (45.4%), 0+0.192
# (11.9%), 0.048 (9.8%), 0.144 (9.0%), 0.168 (7.4%), 0.120 (5.8%), 0.024
# (5.1%), 0.072 (4.6%), con 1.1% lech ca luoi 0.024.  Tuc la KHONG phai lech
# hang so, khong co phep dich nao sua duoc.
#
# Bo so duoi day COPY tu run_workspace/sram_axi/innovus/tcl/add_fill_and_verify
# .tcl - cung ASAP7, cung Innovus 23.14-s088_1, cung duong legacy in-design ->
# verify_rpt/drc_after_fill.rpt = "No DRC violations were found", va fill co
# chay that (axi_ram.metalfill.rpt: M5 285 window, keo 285 -> 201 window duoi
# min).  Cho width chay 0.096 -> 1.248 voi decrement 0.384 (Innovus thu 1.248,
# 0.864, 0.480 roi moi toi 0.096), nen da so mieng RONG HON min width va khong
# dinh M5.AUX.2.
#
# Bo so nay CO CHU Y pham dieu kien cu "gap + width chia het pitch"
# (0.192 + 0.096 = 0.288 = 1.5 pitch).  Chinh sram_axi bac bo dieu kien do bang
# thuc nghiem, nen soc_fill_check_track khong con bao error nua - xem ghi chu o
# do.
#   layer wmin  wmax  decr  lmin  lmax gap   active minD maxD prefD
set SOC_FILL_LAYERS {
    M5    0.096 1.248 0.384 0.384 5.0  0.192 0.192  15   90   25
}
# Muon fill them cho giong slide (khong co luat LEF, tu chiu DRC).  Lay nguyen
# cac dong tuong ung cua sram_axi, dung thu tu cot o tren:
#   M4    0.096 1.248 0.384 0.384 5.0  0.192 0.192  10   35   25
#   M6    0.128 1.664 0.512 0.512 5.0  0.300 0.300  25   55   40
#   M7    0.128 1.664 0.512 0.512 5.0  0.300 0.300  25   55   40
# Layer co MINIMUMDENSITY that trong tech LEF -> chi kiem tra mat do o do.
# Cac layer khac Innovus ap mac dinh 20%: run 2026-09-18 co 8863 vi pham mat do,
# 7719 trong so do la cua luat KHONG ton tai trong PDK nay (M1-M4, M6-M9).
set SOC_DENSITY_LAYERS {M5}

# ---- Waive DRC (chi dung khi da chung minh khong phai luat foundry) --------
# Net trong danh sach nay van bi verify_drc bat va van hien trong bao cao, chi
# khong tinh vao so vi pham lam dung flow.  soc_verify_drc in ra so bo qua moi
# lan chay nen khong bao gio im lang.
#
# u_itcm/u_mem/FE_OFN19657_n_271: 1 OFFGRID M4, bounds
# (1520.116 333.212) (1528.128 333.308), doan router chay tren cao do chan
# wd[26] cua u_itcm/u_mem/G_SRAM_BANK[1].u_sram.  Ly do waive:
#   1. Ca 4 toa do chia het MANUFACTURINGGRID 0.004 -> khong vi pham luat
#      foundry nao; deck calibreDRC.rul cua ASAP7 khong co luat off-track.
#      Day la luat routing-grid rieng cua Innovus.
#   2. 78/78 chan signal M4 cua srambank_256x4x32 lech track M4 o MOI vi tri
#      dat macro (5 gia tri mod 0.192 khac nhau) -> khong sua duoc bang
#      floorplan.  Xem ghi chu day du o KHOI 13 trong innovus.tcl.
#   3. ecoRoute -fix_drc va setNanoRouteMode -drouteOnGridOnly wire deu da thu
#      va deu khong go duoc (run 2026-09-18 22:00 va 2026-09-19 03:20).
# Ten net do Genus sinh: chay lai synthesis thi ten doi, waiver het khop va
# flow error tro lai - fail-safe, khong im lang bo qua loi moi.
set SOC_DRC_WAIVE_NETS {u_itcm/u_mem/FE_OFN19657_n_271}

# Loai vi pham duoc waive.  Chi OFFGRID - ca hai ca duoi deu la "hinh nam dung
# tren MANUFACTURINGGRID 0.004 nhung khong roi track cua Innovus".  SHORT,
# SPACING, EndOfLine... van chan flow nhu cu, ke ca tren chinh nhung net nay.
set SOC_DRC_WAIVE_TYPES {OFFGRID}

# BO WAIVE CHO METAL FILL - 2026-09-20.
#
# Truoc day dong nay them {_FILLS_RESERVED} de nuot 279674 OFFGRID M5 cua fill.
# Ly do ghi kem ("fill la kim loai tro, off-track khong phai luat foundry nao")
# la SAI: calibreDRC.rul co M5.AUX.1 va M5.AUX.2, va M5.AUX.2 noi nguyen van
# "Minimum width M5 tracks must lie along the vertical routing tracks" - ap
# dung len tung mieng fill vi fill cu rong dung min width.
#
# Nguyen nhan that nam o tham so fill chu khong o cho verify_drc: xem khoi ghi
# chu SOC_FILL_LAYERS o tren.  Da doi sang bo so cua sram_axi (co maxWidth
# 1.248 + decrement 0.384) nen phan lon mieng fill rong hon min width va khong
# con dinh M5.AUX.2.  Neu van con OFFGRID tren _FILLS_RESERVED thi la fill VAN
# sai - phai dung flow lai chu khong waive.
#
# Ten bien giu nguyen de innovus.tcl (:664, :734) khong phai sua.  Gio no chi
# con dung mot net SRAM trong SOC_DRC_WAIVE_NETS.
set SOC_DRC_WAIVE_FILL_NETS $SOC_DRC_WAIVE_NETS

# ---- GDS (09_PnR tr.28) ---------------------------------------------------
# So layer lay tu calibreDRC.rul; text chan = datatype 251 (calibreLVS.rul
# LAYER MAP <n> TEXTTYPE == 251).
set SOC_GDS_LAYERS {
    M1 19 V1 21 M2 20 V2 25 M3 30 V3 35 M4 40 V4 45 M5 50
    V5 55 M6 60 V6 65 M7 70 V7 75 M8 80 V8 85 M9 90 V9 95 Pad 96
}
set SOC_GDS_PIN_TEXT 251
# LEF 4x, GDS std cell 1x o 4000 dbu/um: TAPCELL LEF 0.432 um = 432 dbu trong
# GDS -> ghi 1000 dbu/um thi so dbu cua cell va cua layout khop nhau; deck
# Calibre ep LAYOUT PRECISION 4000 nen doc lai dung ti le 1x.
set SOC_GDS_UNITS 1000

# Stripe M5 doc de noi rail M1 cua std cell (Risc_V: pitch 25.92).
set SOC_M5_W      0.096
set SOC_M5_S      0.288
set SOC_M5_PITCH 25.920
set SOC_M5_OFFSET 12.960
