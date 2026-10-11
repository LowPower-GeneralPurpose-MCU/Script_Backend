# Tempus: STA signoff cho top_soc tren SPEF cua Quantus, chay sau mcu/quantus.
#     cd Asap7/run_workspace/mcu/tempus && make all
#
# Bien doi duoc tu dong lenh:
#     make all TEMPUS=/duong/dan/tempus
#     make all TEMPUS_SPEF=pnr     dung SPEF tQuantus cua Innovus KHOI 16 thay
#                                  cho SPEF Quantus (chi de doi chieu)
#     make all TEMPUS_SI=0         tat SI (khong co license SI / de so voi so
#                                  khong SI)
#     make all TEMPUS_CPUS=4       mac dinh 1 (xem tempus.tcl)
#     make all TEMPUS_SDC_PATCH=0  doc SDC goc cua writeTimingCon thay cho ban
#                                  va logs/top_soc_pnr.tempus.sdc (de doi chieu)
#     MCU_OCV_DERATE_LATE / MCU_OCV_DERATE_EARLY: cung ten bien voi Innovus.

TEMPUS  ?= tempus
NETLIST := ../innovus/outputs/top_soc_pnr.v
SDC     := ../innovus/outputs/top_soc_pnr.sdc
SUMMARY := reports/tempus_summary.rpt

export TEMPUS_SPEF
export TEMPUS_SI
export TEMPUS_CPUS
export TEMPUS_SDC_PATCH

.PHONY: all clean

# Ma thoat cua tempus khong dung lam ket luan (bo qua bang dau '-'); ket luan
# la dong dau cua $(SUMMARY) do tempus.tcl ghi.  Thieu file = tempus chet giua
# chung.
all: $(NETLIST) $(SDC)
	mkdir -p logs reports
	rm -f $(SUMMARY)
	-$(TEMPUS) -nowin -init tempus.tcl -log logs/tempus
	@test -f $(SUMMARY) || { echo "Tempus khong ghi $(SUMMARY) - doc logs/tempus.log"; exit 1; }
	@head -n 1 $(SUMMARY) | grep -qx PASS || { echo "STA KHONG DAT - xem $(SUMMARY) va reports/"; exit 1; }

clean:
	rm -rf logs reports *~
