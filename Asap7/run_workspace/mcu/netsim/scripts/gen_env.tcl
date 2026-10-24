############################################################
## Sinh run_<che do>/ cho mot lan netsim:
##   netsim.f    option + danh sach file cho xrun (chay tay: cd run_x && xrun -f netsim.f)
##   sdf.cmd     lenh annotate SDF (chi sdf_max / sdf_min)
##   run.sh      xmsdfc (neu co SDF) roi xrun
##   flash.hex   ban sao NS_FLASH_IMAGE (plusarg ngan, khong vuot reg cua tb)
##   inputs.txt  dau vao + thoi diem sua, summarize.tcl in lai
## Thieu dau vao -> ghi FAIL vao reports/<che do>_summary.rpt va thoat 1.
##     tclsh scripts/gen_env.tcl rtl|syn|func|sdf_max|sdf_min
##
## Che do:  rtl      RTL + define cua Genus, khong delay
##          syn      netlist Genus, unit delay, khong kiem timing
##          func     netlist PnR + SDF SS (MAXIMUM), khong kiem timing
##          sdf_max  netlist PnR + SDF SS (MAXIMUM) + kiem setup/hold
##          sdf_min  netlist PnR + SDF FF (MINIMUM) + kiem setup/hold
## Netlist PnR khong chay unit delay: moi buffer CTS tinh 1 don vi nen nhanh
## clock sau hon nhanh du lieu (DFF ra Q sau 2 don vi) -> race gia.
############################################################

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set NS_ROOT    [file dirname $SCRIPT_DIR]
set MODE       [lindex $argv 0]
if {$MODE ni {rtl syn func sdf_max sdf_min}} {
    puts stderr "cach dung: tclsh scripts/gen_env.tcl rtl|syn|func|sdf_max|sdf_min"
    exit 2
}
cd $NS_ROOT
file mkdir reports logs

proc die {msg} {
    global MODE
    set f [open reports/${MODE}_summary.rpt w]
    puts $f FAIL
    puts $f "gen_env.tcl: $msg"
    close $f
    puts stderr "FAIL - gen_env.tcl: $msg"
    exit 1
}

if {[catch {source [file join $NS_ROOT project_setup.tcl]} err]} {
    die "project_setup.tcl: $err"
}

proc need_file {path what} {
    if {![file isfile $path]} {
        die "khong co $what: $path"
    }
    return $path
}

proc stamp {path} {
    return [clock format [file mtime $path] -format {%Y-%m-%d %H:%M}]
}

# LF ca khi tclsh chay tren Windows: bash / xrun doc "\r" cuoi dong thanh ten file.
proc write_lf {path lines} {
    set f [open $path w]
    fconfigure $f -translation lf
    puts $f [join $lines \n]
    close $f
}

set NETLIST_MODE [expr {$MODE ne "rtl"}]
set SDF_MODE     [expr {$MODE in {func sdf_max sdf_min}}]
set netlist      [expr {$MODE eq "syn" ? $NS_SYN_NETLIST : $NS_NETLIST}]
set inputs {}

# --- Netlist + model std cell ----------------------------------------------
set cell_models {}
if {$NETLIST_MODE} {
    need_file $netlist "netlist ([expr {$MODE eq "syn" ? "NS_SYN_NETLIST" : "NS_NETLIST"}])"
    lappend inputs [list netlist $netlist]
    foreach vt $NS_VT_LIST {
        foreach fam $NS_CELL_FAMILIES {
            set hits [glob -nocomplain -directory $NS_CELL_VERILOG_DIR \
                asap7sc7p5t_${fam}_${vt}_TT_*.v]
            if {[llength $hits] != 1} {
                die "can dung 1 file asap7sc7p5t_${fam}_${vt}_TT_*.v trong\
 $NS_CELL_VERILOG_DIR, thay [llength $hits] (dat NS_CELL_VERILOG_DIR)"
            }
            lappend cell_models [lindex $hits 0]
        }
    }
}

# --- SDF -------------------------------------------------------------------
if {$SDF_MODE} {
    if {$MODE eq "sdf_min"} {
        set sdf $NS_SDF_MIN
        set mtm MINIMUM
    } else {
        set sdf $NS_SDF_MAX
        set mtm MAXIMUM
    }
    need_file $sdf "SDF ($MODE)"
    lappend inputs [list sdf $sdf]
    # KHOI 16 ghi SDF ngay truoc saveNetlist.  Lech qua mot gio la SDF cua lan
    # chay khac (vd. truoc ECO): annotate van "chay" nhung bo sot instance moi.
    set age [expr {abs([file mtime $sdf] - [file mtime $netlist])}]
    if {$age > $NS_SDF_MAX_AGE && !$NS_ALLOW_STALE_SDF} {
        die "SDF va netlist lech [expr {$age / 60}] phut ([stamp $sdf] vs [stamp $netlist]):\
 khong cung mot lan KHOI 16.  Chay lai eco/make finish, hoac NS_ALLOW_STALE_SDF=1."
    }
}

# --- RTL (make rtl): dung danh sach + define Genus doc ------------------------
set rtl_files {}
set rtl_incdirs {}
if {!$NETLIST_MODE} {
    set RTL_ROOT $NS_RTL_ROOT
    if {[catch {source [file join $MCU_DIR genus tcl rtl_filelist.tcl]} err]} {
        die "genus/tcl/rtl_filelist.tcl: $err"
    }
    set rtl_files $RTL_FILES
    set rtl_incdirs $RTL_INCLUDE_DIRS
    lappend inputs [list rtl "$RTL_ROOT ([llength $rtl_files] file)"]
}

foreach f $NS_SRAM_MODELS {
    need_file $f "model SRAM"
}
foreach f $NS_TB_FILES {
    need_file $f "testbench"
}
need_file $NS_FLASH_IMAGE "anh flash (make image)"
lappend inputs [list flash $NS_FLASH_IMAGE]

# --- run_<che do>/ ----------------------------------------------------------
set run_dir [file join $NS_ROOT run_$MODE]
file mkdir $run_dir
file copy -force $NS_FLASH_IMAGE [file join $run_dir flash.hex]

set L {}
lappend L "// Sinh boi scripts/gen_env.tcl $MODE - [clock format [clock seconds] -format {%Y-%m-%d %H:%M}]"
lappend L "// Chay tay: cd run_$MODE && $NS_XRUN -f netsim.f"
lappend L "-64bit"
lappend L "-timescale 1ns/1ps"
if {$NETLIST_MODE} {
    lappend L "// Model ASAP7 khai `timescale 1ns/10ps: khong ep thi tre SDF bi lam tron 10 ps"
    lappend L "-override_timescale"
}
switch -- $MODE {
    rtl {
        lappend L "// Cung define Genus dung khi read_hdl (genus/tcl/genus.tcl)"
        lappend L "+define+ASAP7+SYNTHESIS"
        foreach d $rtl_incdirs {
            lappend L "-incdir [file normalize $d]"
        }
    }
    syn {
        lappend L "// Netlist Genus (chua co CTS): moi cong tre 1 don vi, khong kiem timing"
        lappend L "-delay_mode unit"
        lappend L "-notimingchecks"
    }
    func {
        lappend L "// Tre that tu SDF $mtm ([file tail $sdf]) nhung khong kiem timing:"
        lappend L "// tach loi chuc nang khoi vi pham setup/hold cua sdf_max / sdf_min"
        lappend L "-sdf_cmd_file sdf.cmd"
        lappend L "-notimingchecks"
    }
    default {
        lappend L "// SDF $mtm tu [file tail $sdf]; +neg_tchk giu setup/hold am cua flop"
        lappend L "-sdf_cmd_file sdf.cmd"
        lappend L "+neg_tchk"
    }
}
if {$NS_WAVES} {
    lappend L "-access +r"
    lappend L "+define+NS_WAVES"
}
lappend L "+FLASH_IMAGE=flash.hex"
lappend L "+TIMEOUT_US=$NS_TIMEOUT_US"
lappend L "-top $NS_TB_TOP"
if {$NETLIST_MODE} {
    lappend L "// Model std cell (-v: chi lay module netlist can; UDP altos_* co trong ca RVT va LVT)"
    foreach f $cell_models {
        lappend L "-v $f"
    }
}
lappend L "// Model hanh vi SRAM"
foreach f $NS_SRAM_MODELS {
    lappend L "-v [file normalize $f]"
}
if {$NETLIST_MODE} {
    lappend L $netlist
} else {
    foreach f $rtl_files {
        lappend L [file normalize $f]
    }
}
foreach f $NS_TB_FILES {
    lappend L $f
}
write_lf [file join $run_dir netsim.f] $L

set R {}
lappend R "#!/bin/bash"
lappend R "# Sinh boi scripts/gen_env.tcl $MODE - chay trong run_$MODE/"
if {$SDF_MODE} {
    set sdf_x [file tail $sdf].X
    lappend R "$NS_XMSDFC '$sdf' -output '$sdf_x' || exit 1"
    write_lf [file join $run_dir sdf.cmd] [list \
        "COMPILED_SDF_FILE = \"$sdf_x\"," \
        "SCOPE = $NS_DUT_SCOPE," \
        "MTM_CONTROL = \"$mtm\"," \
        "LOG_FILE = \"sdf.log\";"]
}
lappend R "exec $NS_XRUN -f netsim.f -l xrun_$MODE.log $NS_XRUN_OPTS"
write_lf [file join $run_dir run.sh] $R

set I {}
foreach item $inputs {
    lassign $item name path
    set p [lindex $path 0]
    set t [expr {[file exists $p] ? [stamp $p] : "-"}]
    lappend I "$name\t$path\t$t"
}
write_lf [file join $run_dir inputs.txt] $I

puts "gen_env.tcl $MODE: run_$MODE/netsim.f ([llength $cell_models] model cell,\
 [expr {$NETLIST_MODE ? [file tail $netlist] : "[llength $rtl_files] file RTL"}])"
