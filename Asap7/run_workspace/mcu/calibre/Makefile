# Calibre DRC / LVS cho top_soc tren GDS cuoi, chay sau eco/make finish
# (hoac KHOI 16 cua innovus/tcl/innovus.tcl).  Khung theo pv/ cua thay:
# setup sinh scripts/sourceme tu project_setup.tcl, moi buoc chay trong
# run_<buoc>/ voi header run.<buoc>.cal + INCLUDE deck.
#     cd Asap7/run_workspace/mcu/calibre && make drc
#     cd Asap7/run_workspace/mcu/calibre && make lvs
#
# Bien doi duoc tu dong lenh:
#     make drc CAL_CORES=8          so CPU cho -turbo (mac dinh 4)
#     make drc CAL_HYPER=0          bo -hyper (khong co license hyperscaling)
#     make drc DRC_MAX_RESULTS=ALL  so ket qua toi da / rule trong DB (mac dinh 1000)
#     make drc VAR_M4_YOFFSET=-90   ghi de offset luat track (0.1 nm); mac dinh
#                                   tinh tu TRACKS cua innovus/outputs/top_soc_pnr.def
#                                   (cung VAR_M5_XOFFSET, VAR_M6_YOFFSET, VAR_M7_XOFFSET)
#     make lvs LVS_BOX_PHYS=1       box ca filler/tap nhu thay (mac dinh chi box SRAM,
#                                   xem project_setup.tcl)
#     make lvs V2LVS_OPTS="-64 -sn" option v2lvs (mac dinh nhu thay)
#     make drc CAL_GDS=... CAL_DEF=...  /  make lvs CAL_NETLIST=...
#     make drc CALIBRE=/duong/dan/calibre   /   make lvs V2LVS=/duong/dan/v2lvs
#
# Antenna (target ant cua thay): deck ASAP7 khong co luat antenna nen bo.

SUMMARY_DRC := reports/drc_summary.rpt
SUMMARY_LVS := reports/lvs_summary.rpt

export CAL_CORES CAL_HYPER CALIBRE V2LVS V2LVS_OPTS DRC_MAX_RESULTS LVS_BOX_PHYS
export CAL_GDS CAL_NETLIST CAL_DEF CAL_DRC_DECK CAL_LVS_DECK CAL_CDL_DIR
export VAR_M4_YOFFSET VAR_M5_XOFFSET VAR_M6_YOFFSET VAR_M7_XOFFSET

# clean_drc / clean_lvs KHONG khai .PHONY: make bo qua pattern rule clean_%
# cho target .PHONY.
.PHONY: setup drc lvs all clean

setup:
	@tclsh scripts/gen_env.tcl

# Ma thoat cua calibre khong dung lam ket luan (bo qua bang dau '-'); ket luan
# la dong dau cua file tom tat do summarize.tcl ghi tu bao cao Calibre.
# gen_env.tcl hong (thieu dau vao) thi tu ghi FAIL vao file tom tat.
drc:
	@/bin/echo "INFO: Running Calibre DRC"
	@/bin/mkdir -p logs reports
	/bin/rm -rf run_$@ $(SUMMARY_DRC)
	tclsh scripts/gen_env.tcl $@
	/bin/mkdir -p run_$@
	-cd run_$@ && /bin/bash ../scripts/run_drc.sh 2>&1 | tee calibre_$@.log
	tclsh scripts/summarize.tcl $@
	@head -n 1 $(SUMMARY_DRC) | grep -qx PASS || { echo "DRC KHONG DAT - xem $(SUMMARY_DRC)"; exit 1; }

lvs:
	@/bin/echo "INFO: Running Calibre V2LVS + LVS"
	@/bin/mkdir -p logs reports
	/bin/rm -rf run_$@ $(SUMMARY_LVS)
	tclsh scripts/gen_env.tcl $@
	/bin/mkdir -p run_$@
	-cd run_$@ && tclsh ../scripts/v2lvs.tcl 2>&1 | tee calibre_v2lvs.log
	-cd run_$@ && /bin/bash ../scripts/run_lvs.sh 2>&1 | tee calibre_$@.log
	tclsh scripts/summarize.tcl $@
	@head -n 1 $(SUMMARY_LVS) | grep -qx PASS || { echo "LVS KHONG DAT - xem $(SUMMARY_LVS)"; exit 1; }

# make -k all: chay LVS ca khi DRC khong dat.
all: drc lvs

clean_%:
	/bin/rm -rf run_$*

clean: clean_drc clean_lvs
	/bin/rm -rf logs reports scripts/sourceme
