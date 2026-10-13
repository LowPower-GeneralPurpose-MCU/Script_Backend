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
#     make all VOLTUS_RAIL_OPTS="..."   option noi them vao set_rail_analysis_mode
#                                   (mac dinh "-enable_scheduler false"; none =
#                                   khong noi gi)
#     make all VOLTUS_PADS=defpin   diem cap nguon: pin (mac dinh, nhieu nguon ap
#                                   rai doc cac hinh chan PG cua top trong
#                                   innovus/outputs/top_soc.lef - 4 canh ring),
#                                   ring (nhu pin, hinh lay tu
#                                   innovus/outputs/top_soc_pg_ring.txt: dung
#                                   khi LEF khong du 4 hinh chan), defpin (mot
#                                   nguon moi net), auto
#     make all VOLTUS_PAD_PITCH=5   buoc rai nguon ap cua kieu pin / ring, um
#                                   (mac dinh 10)

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
export VOLTUS_RAIL_OPTS
export VOLTUS_PADS
export VOLTUS_PAD_PITCH

.PHONY: all clean

# Ket luan la dong dau cua $(SUMMARY) do voltus.tcl ghi (DONE = analyze_rail
# chay het VA sut ap VDD / VSS dat nguong ghi trong file tom tat).  Thieu file
# = voltus chet giua chung.
all: $(NETLIST) $(SDC) $(DEF)
	mkdir -p logs reports outputs
	rm -f $(SUMMARY)
	-$(VOLTUS) -nowin -init voltus.tcl -log logs/voltus
	@test -f $(SUMMARY) || { echo "Voltus khong ghi $(SUMMARY) - doc logs/voltus.log"; exit 1; }
	@head -n 1 $(SUMMARY) | grep -qx DONE || { echo "Voltus KHONG XONG hoac sut ap KHONG DAT - xem $(SUMMARY)"; exit 1; }

clean:
	rm -rf logs reports outputs *~
