# Conformal LEC cho top_soc: netlist Genus (golden) vs netlist Innovus (revised).
# Chay sau KHOI 16 cua innovus/tcl/innovus.tcl:
#     cd Asap7/run_workspace/mcu/conformal && make all
#
# Bien doi duoc tu dong lenh:
#     make all LEC=lec_64            ten lenh Conformal tren may
#     make all LEC_MODE=flat         so phang thay cho so phan cap
#     make all LEC_THREADS=4         so thread (mac dinh 1: nhieu thread lam
#                                    lec treo tren may nay, xem conformal.tcl)

LEC     ?= lec
GOLDEN  ?= ../genus/outputs/top_soc_syn.v
REVISED ?= ../innovus/outputs/top_soc_pnr.v
VERDICT := reports/lec_verdict.txt

export LEC_GOLDEN  := $(abspath $(GOLDEN))
export LEC_REVISED := $(abspath $(REVISED))
export LEC_MODE
export LEC_THREADS

.PHONY: all clean

# Ma thoat cua lec khong dung lam ket luan (bo qua bang dau '-'); ket luan la
# dong dau cua $(VERDICT) do conformal.tcl ghi.  Thieu file = lec chet giua chung.
all: $(GOLDEN) $(REVISED)
	mkdir -p logs reports
	rm -f $(VERDICT)
	-$(LEC) -xl -LOGfile logs/conformal.log -NOGui -Dofile conformal.tcl -TclMode
	@test -f $(VERDICT) || { echo "LEC khong ghi $(VERDICT) - doc logs/conformal.log"; exit 1; }
	@head -n 1 $(VERDICT) | grep -qx PASS || { echo "LEC KHONG DAT - xem $(VERDICT) va reports/"; exit 1; }

# LEC.tmp.<pid> la thu muc tam cua lec; chi xoa khi tien trinh do da thoat.
clean:
	rm -rf logs reports hier.do LEC.tmp.* *~
