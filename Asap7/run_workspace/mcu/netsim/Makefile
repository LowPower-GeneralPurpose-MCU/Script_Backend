# Netsim (mo phong netlist) cho top_soc bang Cadence Xcelium, chay sau
# eco/make finish (KHOI 16 cua innovus/tcl/innovus.tcl ghi netlist + SDF).
# Khung giong mcu/calibre: gen_env.tcl sinh run_<che do>/{netsim.f, sdf.cmd,
# run.sh}, summarize.tcl ghi reports/<che do>_summary.rpt (dong dau PASS/FAIL).
#     cd Asap7/run_workspace/mcu/netsim && make rtl       # tb tren RTL - chay truoc
#     make syn                                             # netlist Genus, unit delay
#     make func                                            # netlist PnR + SDF SS, khong kiem timing
#     make sdf_max                                         # netlist PnR + SDF SS + kiem timing (setup)
#     make sdf_min                                         # netlist PnR + SDF FF + kiem timing (hold)
#     make -k all                                          # ca nam, khong dung khi FAIL
# Netlist PnR khong chay unit delay (race gia qua cay CTS) - xem gen_env.tcl.
#
# Kich ban (tb/tb_netsim.sv): boot ROM trong netlist doc anh flash
# tb/netsim_flash.hex, chep chuong trinh vao ITCM, chuong trinh gui
# "NETSIM OK\n" qua RAM hi (SRAM) ra UART0/PA0.  make image sinh lai anh.
#
# Bien doi duoc tu dong lenh:
#     make func NS_NETLIST=...          netlist PnR khac (mac dinh innovus/outputs/top_soc_pnr.v)
#     make syn NS_SYN_NETLIST=...       netlist Genus khac (mac dinh genus/outputs/top_soc_syn.v)
#     make sdf_max NS_SDF_MAX=...       SDF khac (mac dinh innovus/outputs/top_soc_pnr_{ss,ff}.sdf)
#     make sdf_max NS_ALLOW_STALE_SDF=1 bo chan SDF/netlist lech > 1 gio
#     make func NS_CELL_VERILOG_DIR=... thu muc model Verilog ASAP7 (mac dinh $STDCELL_ROOT/Verilog)
#     make func NS_TIMEOUT_US=1000      gioi han thoi gian mo phong (mac dinh 400 us)
#     make func NS_WAVES=1              ghi song cac cong top_soc vao run_func/waves.shm
#     make func NS_XRUN_OPTS="-gui"     them option cho xrun
#     make func XRUN=irun XMSDFC=ncsdfc Incisive thay cho Xcelium

MODES := rtl syn func sdf_max sdf_min

export XRUN XMSDFC NS_NETLIST NS_SYN_NETLIST NS_SDF_MAX NS_SDF_MIN NS_SDF_MAX_AGE NS_ALLOW_STALE_SDF
export NS_CELL_VERILOG_DIR NS_VT_LIST NS_SRAM_MODELS NS_FLASH_IMAGE NS_TIMEOUT_US NS_WAVES NS_XRUN_OPTS

# clean_<che do> KHONG khai .PHONY: make bo qua pattern rule clean_% cho target .PHONY.
.PHONY: $(MODES) all image clean

# Ma thoat cua xrun khong dung lam ket luan (bo qua bang dau '-'); ket luan la
# dong dau cua reports/<che do>_summary.rpt do summarize.tcl ghi.  gen_env.tcl
# thieu dau vao thi tu ghi FAIL vao file do va dung make.
$(MODES):
	@/bin/echo "INFO: netsim $@"
	@/bin/mkdir -p logs reports
	/bin/rm -rf run_$@ reports/$@_summary.rpt
	tclsh scripts/gen_env.tcl $@
	-cd run_$@ && /bin/bash run.sh 2>&1 | tee netsim_$@.log
	tclsh scripts/summarize.tcl $@
	@head -n 1 reports/$@_summary.rpt | grep -qx PASS || { echo "NETSIM $@ KHONG DAT - xem reports/$@_summary.rpt"; exit 1; }

# make -k all: chay tiep ca khi mot che do khong dat.
all: $(MODES)

image:
	python3 scripts/gen_flash_image.py

clean_%:
	/bin/rm -rf run_$*

clean: $(addprefix clean_,$(MODES))
	/bin/rm -rf logs reports
