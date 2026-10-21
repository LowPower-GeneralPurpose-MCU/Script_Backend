############################################################
## v2lvs cho top_soc, khung pv/scripts/v2lvs.tcl cua thay.  Chay trong run_lvs/.
##   1. dem master ma netlist co nguon dung.  Master khong co trong CDL (SRAM,
##      FILLER*, TAPCELL*) -> .SUBCKT rong, chan theo thu tu LEF:
##      top_soc.stub.cdl.  Master khong co ca trong LEF -> dung.
##   2. hcell.list    = top + moi std cell co CDL ma netlist dung
##   3. lvs_box.list  = SRAM (+ filler/tap khi LVS_BOX_PHYS=1), run_lvs.sh doc
##   4. cell_usage.rpt: master / so instance / nguon / vai tro
##   5. v2lvs -> top_soc.v2lvs.net; top_soc.source.net = .INCLUDE moi CDL ma
##      v2lvs chua tu ghi + top_soc.v2lvs.net (SOURCE PATH cua run_lvs.sh)
## Lenh v2lvs thu hai cua thay (-i -sl, netlist mo phong .src.net) bo: LVS
## khong dung.
############################################################

source ../project_setup.tcl

set DESIGN       $HGVAR_DESIGN
set NETLIST      $HGVAR_SIGNOFF_NETLIST_PWR
set STUB_CDL     ${DESIGN}.stub.cdl
set V2LVS_NET    ${DESIGN}.v2lvs.net
set SOURCE_NET   ${DESIGN}.source.net

proc die {msg} {
    puts "ERROR: $msg"
    exit 1
}

# ---- 1. master trong netlist -------------------------------------------------
# Dong instance cua saveNetlist:  "   <master> <ten> (.A(x)," hoac ten escape
# "\G_SRAM_BANK[0].u_sram  (".  Module con cua chinh netlist (clock_gate ...)
# khong tinh la master.
puts "INFO: doc $NETLIST"
set t0 [clock seconds]
set keywords {module endmodule input output inout wire assign supply0 supply1 tri reg}
array set use_count {}
array set modules {}
set f [open $NETLIST r]
fconfigure $f -buffersize 4194304
while {[gets $f line] >= 0} {
    set c [string index [string trimleft $line] 0]
    if {$c eq "." || $c eq "" || $c eq ")" || $c eq "/"} {
        continue
    }
    if {[regexp {^\s*module\s+([^\s(]+)} $line -> m]} {
        set modules($m) 1
        continue
    }
    if {[regexp {^\s*([A-Za-z_][A-Za-z0-9_$]*)\s+(?:\\\S+|[A-Za-z_][A-Za-z0-9_$]*)\s*\(} $line -> m] &&
        [lsearch -exact $keywords $m] < 0} {
        incr use_count($m)
    }
}
close $f
foreach m [array names modules] {
    unset -nocomplain use_count($m)
}
if {![info exists modules($DESIGN)]} {
    die "netlist khong co module $DESIGN: $NETLIST"
}
puts "INFO: [array size use_count] master, [array size modules] module,\
 [expr {[clock seconds] - $t0}] s"

# ---- CDL va LEF ---------------------------------------------------------------
array set in_cdl {}
foreach cdl [concat $HGVAR_STDCELL_CDL $HGVAR_SRAM_CDL $HGVAR_FLASH_CDL] {
    set f [open $cdl r]
    while {[gets $f line] >= 0} {
        if {[regexp -nocase {^\s*\.SUBCKT\s+(\S+)} $line -> name]} {
            set in_cdl($name) $cdl
        }
    }
    close $f
}

array set lef_pins {}
array set lef_class {}
foreach lef $HGVAR_STUB_LEFS {
    set f [open $lef r]
    set cur ""
    set in_prop 0
    while {[gets $f line] >= 0} {
        # LEF SRAM co "MACRO CatenaDesignType STRING ;" trong PROPERTYDEFINITIONS
        if {[regexp {^\s*(END\s+)?PROPERTYDEFINITIONS} $line -> end_prop]} {
            set in_prop [expr {$end_prop eq ""}]
            continue
        }
        if {$in_prop} {
            continue
        }
        if {$cur eq ""} {
            if {[regexp {^\s*MACRO\s+(\S+)\s*$} $line -> cur]} {
                set lef_pins($cur) {}
                set lef_class($cur) ""
            }
            continue
        }
        if {[regexp {^\s*END\s+(\S+)\s*$} $line -> e] && $e eq $cur} {
            set cur ""
        } elseif {$lef_class($cur) eq "" && [regexp {^\s*CLASS\s+([^;]+);} $line -> c]} {
            set lef_class($cur) [string trim $c]
        } elseif {[regexp {^\s*PIN\s+(\S+)} $line -> p] &&
                  [lsearch -exact $lef_pins($cur) $p] < 0} {
            lappend lef_pins($cur) $p
        }
    }
    close $f
}

# ---- 2/3/4. stub, hcell, box, bang dung cell ----------------------------------
set box [list {*}$HGVAR_LVS_BOX]
set hcells {}
set stubs {}
set missing {}
foreach m [lsort [array names use_count]] {
    if {[info exists in_cdl($m)]} {
        lappend hcells $m
    } elseif {[info exists lef_pins($m)]} {
        lappend stubs $m
        if {$HGVAR_LVS_BOX_PHYS && [regexp {^CORE\s+(SPACER|WELLTAP)} $lef_class($m)] &&
            [lsearch -exact $box $m] < 0} {
            lappend box $m
        }
    } else {
        lappend missing $m
    }
}
if {[llength $missing]} {
    die "master khong co trong CDL lan LEF: $missing"
}
foreach m $HGVAR_LVS_BOX {
    if {[lsearch -exact $stubs $m] < 0} {
        die "LVS BOX $m nhung netlist khong dung master nay"
    }
}

set f [open $STUB_CDL w]
puts $f "* .SUBCKT rong cho master khong co CDL, chan theo thu tu LEF."
puts $f "* Sinh boi calibre/scripts/v2lvs.tcl - dung sua tay."
foreach m $stubs {
    puts $f "* $m: LEF CLASS $lef_class($m)"
    set pins $lef_pins($m)
    puts $f ".SUBCKT $m [join [lrange $pins 0 9] { }]"
    for {set i 10} {$i < [llength $pins]} {incr i 10} {
        puts $f "+ [join [lrange $pins $i [expr {$i + 9}]] { }]"
    }
    puts $f ".ENDS"
}
close $f

set f [open $HGVAR_HCELL_LIST_FILE w]
puts $f "$DESIGN $DESIGN"
foreach m [concat $hcells $HGVAR_LVS_HCELL_LIST_APPEND] {
    puts $f "$m $m"
}
foreach hfile $HGVAR_LVS_HCELL_LIST_FILES {
    set IF [open $hfile r]
    while {[gets $IF line] >= 0} {
        if {[string trim $line] ne ""} {
            puts $f "$line $line"
        }
    }
    close $IF
}
close $f

set f [open lvs_box.list w]
puts $f [join $box "\n"]
close $f

set n_inst 0
foreach m [array names use_count] {
    incr n_inst $use_count($m)
}
set f [open cell_usage.rpt w]
puts $f "# netlist $NETLIST"
puts $f "# [array size use_count] master, $n_inst instance:\
 [llength $hcells] master co CDL (hcell), [llength $stubs] master stub rong,\
 [llength $box] master LVS BOX"
puts $f [format "# %-34s %9s  %-24s %s" master instance nguon "vai tro"]
foreach m [lsort [array names use_count]] {
    if {[info exists in_cdl($m)]} {
        set src "cdl [file tail $in_cdl($m)]"
        set role hcell
    } else {
        set src "stub (LEF $lef_class($m))"
        set role [expr {[lsearch -exact $box $m] >= 0 ? "LVS BOX" : "flatten (khong co thiet bi)"}]
    }
    puts $f [format "  %-34s %9d  %-24s %s" $m $use_count($m) $src $role]
}
close $f
puts "INFO: [llength $stubs] master stub: $stubs"
puts "INFO: LVS BOX: $box"

# ---- 5. v2lvs -----------------------------------------------------------------
set cdls [concat $HGVAR_STDCELL_CDL $HGVAR_SRAM_CDL $HGVAR_FLASH_CDL [list [file normalize $STUB_CDL]]]
# Wrapper v2lvs cua Calibre la script sh viet cho bash (RHEL).  Ubuntu tro
# /bin/sh sang dash nen lan chay 2026-10-21 chet ngay sau 0 s: "v2lvs: 113:
# .../set_shared_library_path: Syntax error: redirection unexpected".  Script
# "#!/bin/sh" (hoac khong co #!, execvp cung roi ve /bin/sh) thi goi qua bash.
set v2lvs [lindex [auto_execok $HGVAR_V2LVS] 0]
if {$v2lvs eq ""} {
    die "khong thay lenh '$HGVAR_V2LVS' trong PATH"
}
set f [open $v2lvs r]
fconfigure $f -translation binary
set magic [read $f 64]
close $f
set cmd [list $v2lvs {*}$HGVAR_V2LVS_OPTS]
if {[string range $magic 0 3] ne "\x7fELF" &&
    ([string range $magic 0 1] ne "#!" ||
     [regexp {^#!\s*(/usr)?/bin/(env\s+)?sh\M} $magic])} {
    set bash [lindex [auto_execok bash] 0]
    if {$bash eq ""} {
        die "$v2lvs la script sh nhung khong thay bash"
    }
    puts "INFO: $v2lvs la script sh -> chay qua $bash (/bin/sh co the la dash)"
    set cmd [list $bash {*}$cmd]
}
foreach cdl $cdls {
    lappend cmd -s $cdl
}
lappend cmd -o $V2LVS_NET -v $NETLIST
puts "V2LVS_CMD is: $cmd"
set t0 [clock seconds]
set rc [catch {exec {*}$cmd >@ stdout 2>@ stderr} result]
puts "INFO: v2lvs ket thuc sau [expr {[clock seconds] - $t0}] s[expr {$rc ? " - loi: $result" : ""}]"
if {![file isfile $V2LVS_NET] || [file size $V2LVS_NET] == 0} {
    die "v2lvs khong ghi $V2LVS_NET"
}

# v2lvs -s co the da ghi .INCLUDE cho thu vien; them cai con thieu.
set included {}
set f [open $V2LVS_NET r]
for {set i 0} {$i < 5000 && [gets $f line] >= 0} {incr i} {
    if {[regexp -nocase {^\s*\.INCLUDE\s+"?([^"\s]+)"?} $line -> inc]} {
        lappend included [file tail $inc]
    }
}
close $f
set f [open $SOURCE_NET w]
puts $f "* SOURCE PATH cua LVS: thu vien con thieu + netlist cua v2lvs."
foreach cdl $cdls {
    if {[lsearch -exact $included [file tail $cdl]] < 0} {
        puts $f ".INCLUDE \"$cdl\""
    }
}
puts $f ".INCLUDE \"[file normalize $V2LVS_NET]\""
close $f
puts "INFO: v2lvs da ghi .INCLUDE: [expr {[llength $included] ? $included : {khong co}}]"
puts "INFO: ghi $SOURCE_NET"
exit 0
