############################################################
## Bien cho buoc netsim (mo phong netlist bang Xcelium) cua top_soc.
## Cung khung voi mcu/calibre/project_setup.tcl: scripts/gen_env.tcl source file
## nay roi sinh run_<che do>/{netsim.f, sdf.cmd, run.sh}.
##
## Duong dan thu vien lay tu innovus/tcl/project_config.tcl (STDCELL_ROOT,
## TOP ...) nen trung voi file Genus/Innovus da dung.  Moi bien NS_* / XRUN /
## XMSDFC ghi de duoc tu dong lenh make (xem Makefile).
############################################################

set NS_DIR  [file dirname [file normalize [info script]]]
set MCU_DIR [file dirname $NS_DIR]

source [file join $MCU_DIR innovus tcl project_config.tcl]

proc ns_env {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

set NS_DESIGN $TOP
set NS_XRUN   [ns_env XRUN xrun]
set NS_XMSDFC [ns_env XMSDFC xmsdfc]

# Netlist PnR (func / sdf_max / sdf_min): ban saveNetlist cua KHOI 16 (eco/make
# finish chay lai khoi do), KHONG phai _pnr_pg.v (co VDD/VSS + filler/tap cho
# LVS, model ASAP7 khong co chan nguon).  Netlist Genus cho che do syn.
set NS_OUTPUTS     [file join $MCU_DIR innovus outputs]
set NS_NETLIST     [file normalize [ns_env NS_NETLIST [file join $NS_OUTPUTS ${TOP}_pnr.v]]]
set NS_SYN_NETLIST [file normalize [ns_env NS_SYN_NETLIST $SYN_NETLIST]]

# SDF tung view cua KHOI 16 (write_sdf -view): SS cho setup (MAXIMUM, ca func),
# FF cho hold (MINIMUM).  Cung lan KHOI 16 voi netlist; gen_env.tcl chan neu hai
# file lech nhau qua NS_SDF_MAX_AGE giay (NS_ALLOW_STALE_SDF=1 bo qua).
set NS_SDF_MAX [file normalize [ns_env NS_SDF_MAX [file join $NS_OUTPUTS ${TOP}_pnr_ss.sdf]]]
set NS_SDF_MIN [file normalize [ns_env NS_SDF_MIN [file join $NS_OUTPUTS ${TOP}_pnr_ff.sdf]]]
set NS_SDF_MAX_AGE     [ns_env NS_SDF_MAX_AGE 3600]
set NS_ALLOW_STALE_SDF [ns_env NS_ALLOW_STALE_SDF 0]

# Model Verilog std cell: netlist dung ca RVT (_R) lan LVT (_L).  Moi Vt 5 file
# asap7sc7p5t_{AO,INVBUF,OA,SEQ,SIMPLE}_<Vt>_TT_*.v; ten co ngay nen gen_env.tcl
# glob.  Model khai `timescale 1ns/10ps -> netsim.f ep 1ns/1ps (xem gen_env.tcl).
set NS_CELL_VERILOG_DIR [file normalize [ns_env NS_CELL_VERILOG_DIR [file join $STDCELL_ROOT Verilog]]]
set NS_VT_LIST      [ns_env NS_VT_LIST {RVT LVT}]
set NS_CELL_FAMILIES {AO INVBUF OA SEQ SIMPLE}

# Model hanh vi cua 2 master SRAM: cung ban mo phong RTL dang dung
# (genus/rtl/tests/run_soc_sim.sh), khong co specify -> SDF khong annotate SRAM.
set NS_RTL_ROOT [file join $MCU_DIR genus rtl]
set NS_SRAM_MODELS [ns_env NS_SRAM_MODELS [list \
    [file join $NS_RTL_ROOT tests models "$SRAM_MASTER.v"] \
    [file join $NS_RTL_ROOT tests models "$SRAM_TAG_MASTER.v"]]]

set NS_TB_DIR      [file join $NS_DIR tb]
set NS_TB_FILES    [list \
    [file join $NS_TB_DIR spi_flash_model.v] \
    [file join $NS_TB_DIR tb_netsim.sv]]
set NS_TB_TOP      tb_netsim
set NS_DUT_SCOPE   tb_netsim.uut
set NS_FLASH_IMAGE [file normalize [ns_env NS_FLASH_IMAGE [file join $NS_TB_DIR netsim_flash.hex]]]
set NS_TIMEOUT_US  [ns_env NS_TIMEOUT_US 400]
set NS_WAVES       [ns_env NS_WAVES 0]
set NS_XRUN_OPTS   [ns_env NS_XRUN_OPTS ""]
# Go loi X tren netlist (scripts/gen_env.tcl): NS_UDP_INIT 0|1 gan gia tri dau cho
# moi flop/latch khong reset; NS_XWIN 1 hoac <bat dau>:<ket thuc> (ns) dump toan
# bo tin hieu trong cua so do vao run_<che do>/xwin.shm.  Bo trong = tat.
set NS_UDP_INIT    [ns_env NS_UDP_INIT ""]
set NS_XWIN        [ns_env NS_XWIN ""]
