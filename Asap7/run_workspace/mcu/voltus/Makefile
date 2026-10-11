# Voltus: cong suat tinh + sut ap luoi nguon (IR drop) cho top_soc, chay sau
# mcu/quantus (dung SPEF rc_typ cua no).
#     cd Asap7/run_workspace/mcu/voltus && make all
#
# Bien doi duoc tu dong lenh:
#     make all VOLTUS=/duong/dan/voltus
#     make all VOLTUS_SPEF=pnr      SPEF tQuantus cua Innovus KHOI 16
#     make all VOLTUS_RAIL=0        chi tinh cong suat, bo analyze_rail
#     make all VOLTUS_XP=1          bat -enable_xp nhu mau Mul32 (mac dinh tat:
#                                   xem voltus.tcl)
#     make all VOLTUS_LAYERMAP=0    khong truyen file ghep lop LEF/QRC
#     make all VOLTUS_CPUS=4        mac dinh 1

VOLTUS  ?= voltus
NETLIST := ../innovus/outputs/top_soc_pnr.v
SDC     := ../innovus/outputs/top_soc_pnr.sdc
DEF     := ../innovus/outputs/top_soc_pnr.def
SUMMARY := reports/voltus_summary.rpt

export VOLTUS_SPEF
export VOLTUS_RAIL
export VOLTUS_XP
export VOLTUS_LAYERMAP
export VOLTUS_CPUS

.PHONY: all clean

# Ket luan la dong dau cua $(SUMMARY) do voltus.tcl ghi (DONE = chay het, KHONG
# phai "IR drop dat": nguong xem trong file tom tat).  Thieu file = voltus chet
# giua chung.
all: $(NETLIST) $(SDC) $(DEF)
	mkdir -p logs reports outputs
	rm -f $(SUMMARY)
	-$(VOLTUS) -nowin -init voltus.tcl -log logs/voltus
	@test -f $(SUMMARY) || { echo "Voltus khong ghi $(SUMMARY) - doc logs/voltus.log"; exit 1; }
	@head -n 1 $(SUMMARY) | grep -qx DONE || { echo "Voltus KHONG XONG - xem $(SUMMARY)"; exit 1; }

clean:
	rm -rf logs reports outputs *~
