# ECO sua DRV ma Tempus bao (max_transition), chay sau mcu/tempus.
#     cd Asap7/run_workspace/mcu/eco
#     make all       toi uu lai tu checkpoint cuoi KHOI 14 -> top_soc_postRoute_eco
#     make finish    KHOI 15 + 16 tren checkpoint do (GHI DE outputs/ cua Innovus)
# Sau do: mcu/conformal, mcu/quantus, mcu/tempus (xem reports/eco_finish_summary.rpt).
#
# Bien doi duoc tu dong lenh (y nghia: dau file eco_drv.tcl):
#     make all ECO_DRV_MARGIN=0.10
#     make all ECO_EXTRACT=flow ECO_DRV_MARGIN=0.20
#     make all ECO_CPUS=8            mac dinh 1: IQuantus nhieu tien trinh da
#                                    treo tren may nay
#     make all ECO_CHECKPOINT=./saved/<ten>.enc.dat   (tinh tu mcu/innovus)
#     make all ECO_ALLOW_BAD_LIB=1   khong can cho SIMPLE_RVT_FF 0.7 V khi
#                                    STD_FF_LOWV_DERATE (project_config.tcl) bat

INNOVUS    ?= innovus
RUN_DIR    := ../innovus
CHECKPOINT := $(RUN_DIR)/saved/top_soc_postRoute.enc.dat
ECO_OUT    := $(RUN_DIR)/saved/top_soc_postRoute_eco.enc.dat
VIOLATORS  := ../tempus/reports/all_violators.rpt
SUMMARY    := reports/eco_summary.rpt
FINISH     := reports/eco_finish_summary.rpt

export ECO_EXTRACT
export ECO_DRV_MARGIN
export ECO_CPUS
export ECO_CHECKPOINT
export ECO_ALLOW_BAD_LIB

.PHONY: all finish clean

# Innovus phai chay trong mcu/innovus: checkpoint va tcl/ deu duoc tim theo
# duong dan tuong doi tu do.  Ket luan la dong dau cua file tom tat do script
# ghi; thieu file = innovus chet giua chung.
all: $(VIOLATORS)
	@test -n "$(ECO_CHECKPOINT)" || test -d $(CHECKPOINT) || { echo "Khong co $(CHECKPOINT) - can ket qua KHOI 14"; exit 1; }
	mkdir -p logs reports
	rm -f $(SUMMARY)
	-cd $(RUN_DIR) && $(INNOVUS) -no_gui -files ../eco/eco_drv.tcl -log ../eco/logs/eco_drv
	@test -f $(SUMMARY) || { echo "ECO khong ghi $(SUMMARY) - doc logs/eco_drv.log"; exit 1; }
	@cat $(SUMMARY)
	@head -n 1 $(SUMMARY) | grep -qx PASS || { echo "ECO KHONG DAT - xem $(SUMMARY)"; exit 1; }

finish:
	@test -d $(ECO_OUT) || { echo "Khong co $(ECO_OUT) - chay 'make all' truoc"; exit 1; }
	mkdir -p logs reports
	rm -f $(FINISH)
	-cd $(RUN_DIR) && $(INNOVUS) -no_gui -files ../eco/eco_finish.tcl -log ../eco/logs/eco_finish
	@test -f $(FINISH) || { echo "Innovus khong ghi $(FINISH) - doc logs/eco_finish.log"; exit 1; }
	@cat $(FINISH)
	@head -n 1 $(FINISH) | grep -qx DONE || { echo "KHOI 15/16 KHONG XONG - xem $(FINISH)"; exit 1; }

clean:
	rm -rf logs reports *~
