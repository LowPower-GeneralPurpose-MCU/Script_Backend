VPATH=make

setup:
	@tclsh scripts/gen_env.tcl
	@/bin/mkdir -p $(VPATH)
	@touch $(VPATH)/$@

ant: setup
	@/bin/echo "INFO: Running Calibre Antenna"
	@/bin/mkdir -p run_$@
	cd run_$@ && /bin/bash ../scripts/run_ant.sh | tee calibre_$@.log
	@touch $(VPATH)/$@

drc: setup
	@/bin/echo "INFO: Running Calibre DRC"
	@/bin/mkdir -p run_$@
	cd run_$@ && /bin/bash ../scripts/run_drc.sh | tee calibre_$@.log
	@touch $(VPATH)/$@

lvs: setup
	@/bin/echo "INFO: Running Calibre V2LVS và LVS"
	@/bin/mkdir -p run_$@
	@/bin/echo "INFO: Bien doi Verilog sang SPICE netlist..."
	cd run_$@ && tclsh ../scripts/v2lvs.tcl | tee calibre_v2lvs.log
	@/bin/echo "INFO: Thuc thi Calibre LVS so sanh..."
	cd run_$@ && /bin/bash ../scripts/run_lvs.sh | tee calibre_$@.log
	@touch $(VPATH)/$@

all: ant drc lvs

clean_%:
	/bin/rm -rf run_$* $(VPATH)/$*

clean: clean_ant clean_drc clean_lvs
	/bin/rm -rf $(VPATH)