# Quantus: trich RC signoff cho top_soc, chay sau Conformal LEC.
#     cd Asap7/run_workspace/mcu/quantus && make all
#
# Bien doi duoc tu dong lenh:
#     make all QUANTUS_EFFORT=high   IQuantus tich hop (may khong co lenh qrc)
#     make all QRC_BIN=/duong/dan/qrc
#     make all QUANTUS_CPUS=8        mac dinh 1: nhieu tien trinh lam extractRC
#                                    treo tren may nay (xem quantus.tcl)

INNOVUS    ?= innovus
RUN_DIR    := ../innovus
CHECKPOINT := $(RUN_DIR)/saved/top_soc_final.enc.dat
SUMMARY    := reports/quantus_summary.rpt

export QUANTUS_EFFORT
export QUANTUS_CPUS
export QRC_BIN

.PHONY: all clean

# Innovus phai chay trong mcu/innovus: checkpoint va tcl/project_config.tcl
# deu duoc tim theo duong dan tuong doi tu do.  Ket luan la dong dau cua
# $(SUMMARY) do quantus.tcl ghi; thieu file = innovus chet giua chung.
all: $(CHECKPOINT)
	mkdir -p logs reports outputs
	rm -f $(SUMMARY)
	-cd $(RUN_DIR) && $(INNOVUS) -no_gui -files ../quantus/quantus.tcl -log ../quantus/logs/quantus
	@test -f $(SUMMARY) || { echo "Quantus khong ghi $(SUMMARY) - doc logs/quantus.log"; exit 1; }
	@head -n 1 $(SUMMARY) | grep -qx DONE || { echo "Quantus KHONG XONG - xem $(SUMMARY)"; exit 1; }

clean:
	rm -rf logs reports outputs *~
