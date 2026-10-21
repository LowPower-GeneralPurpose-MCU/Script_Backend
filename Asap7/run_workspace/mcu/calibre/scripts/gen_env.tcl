############################################################
## Sinh scripts/sourceme tu project_setup.tcl (nhu pv/scripts/gen_env.tcl cua
## thay) va kiem dau vao truoc khi goi Calibre.
##     tclsh scripts/gen_env.tcl [drc|lvs]
## Co ten buoc thi loi dau vao duoc ghi luon vao reports/<buoc>_summary.rpt
## (dong dau FAIL): file tom tat khong bao gio con ket qua cua lan chay truoc.
############################################################

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set CAL_ROOT   [file dirname $SCRIPT_DIR]
set STEP       [lindex $argv 0]

proc gen_fail {msg} {
    global STEP CAL_ROOT
    puts "ERROR: $msg"
    if {$STEP ne ""} {
        file mkdir [file join $CAL_ROOT reports]
        set f [open [file join $CAL_ROOT reports ${STEP}_summary.rpt] w]
        puts $f FAIL
        puts $f "Calibre [string toupper $STEP] top_soc: dung o buoc chuan bi (scripts/gen_env.tcl),\
 Calibre chua chay."
        puts $f "  $msg"
        close $f
    }
    exit 1
}

proc need_file {path what} {
    if {![file isfile $path] || [file size $path] == 0} {
        gen_fail "khong co $what: $path"
    }
}

proc bash_quote {s} {
    return "'[string map {' '\"'\"'} $s]'"
}

if {[catch {source [file join $CAL_ROOT project_setup.tcl]} err]} {
    gen_fail "project_setup.tcl: $err"
}

foreach tool [list $HGVAR_CALIBRE {*}[expr {$STEP eq "lvs" ? [list $HGVAR_V2LVS] : {}}]] {
    if {[auto_execok $tool] eq ""} {
        gen_fail "khong thay lenh '$tool' trong PATH - nap moi truong Mentor Calibre truoc"
    }
}

need_file $HGVAR_SIGNOFF_GDS "GDS (eco/make finish hoac KHOI 16)"

# ---- Offset luat track M4-M7 cua deck DRC --------------------------------
# calibreDRC.rul dong 841/896/951/1006: VARIABLE VAR_M4_YOFFSET ENVIRONMENT ...
# M4.AUX.1: canh M4 nam tren luoi VAR_M4_1X_DBU (= do rong 24 nm) lech VAR;
# M4.AUX.2: tam day rong toi thieu nam tren luoi 2*DBU (pitch 48 nm) lech
# -(DBU/2 + VAR).  Don vi la PRECISION 10000 cua deck (0.1 nm).  Ban Mul32 cu
# dat 0 het - sai neu track khong bat dau o 0.  Lay track that trong DEF:
#   VAR = (track_dau mod 2*DBU) - DBU/2   (= canh duoi day tren track dau)
# Neu track_dau la boi cua DBU, ca hai cach hieu dau cua OFFSET trong OFFGRID
# cho cung ket qua; neu khong (vd M4 OFFSET 0.003 cua tech LEF) thi khong gia
# tri nao qua duoc ca AUX.1 lan AUX.2 - ghi chu vao sourceme.
proc deck_variable {deck name} {
    set f [open $deck r]
    set value ""
    while {[gets $f line] >= 0} {
        if {[regexp "^\\s*VARIABLE\\s+$name\\s+(\\S+)" $line -> value]} {
            break
        }
    }
    close $f
    return $value
}

proc def_tracks {def} {
    set units ""
    set tracks {}
    set f [open $def r]
    while {[gets $f line] >= 0} {
        if {[regexp {^\s*UNITS\s+DISTANCE\s+MICRONS\s+(\d+)} $line -> units]} {
            continue
        }
        if {[regexp {^\s*TRACKS\s+([XY])\s+(-?\d+)\s+DO\s+(\d+)\s+STEP\s+(\d+).*\sLAYER\s+([^;]+);} \
                $line -> dir start n step layers]} {
            foreach layer $layers {
                lappend tracks [list $layer $dir $start $step]
            }
            continue
        }
        if {[regexp {^\s*(COMPONENTS|PINS|NETS|SPECIALNETS)\s} $line]} {
            break
        }
    }
    close $f
    return [list $units $tracks]
}

set OFFSET_VARS {
    M4 Y VAR_M4_YOFFSET VAR_M4_1X_DBU
    M5 X VAR_M5_XOFFSET VAR_M5_1X_DBU
    M6 Y VAR_M6_YOFFSET VAR_M6_1X_DBU
    M7 X VAR_M7_XOFFSET VAR_M7_1X_DBU
}
set offset_lines {}
set offset_notes {}
set need_def 0
if {$STEP eq "lvs"} {
    # deck LVS khong co luat track
    set OFFSET_VARS {}
}
foreach {layer dir var dbu_var} $OFFSET_VARS {
    if {![info exists ::env($var)] || $::env($var) eq ""} {
        set need_def 1
    }
}
if {$need_def} {
    need_file $HGVAR_SIGNOFF_DEF "DEF (lay TRACKS cho offset luat track; hoac dat VAR_M4_YOFFSET... tu dong lenh)"
    need_file $HGVAR_DRC_RULE_FILE "deck DRC"
    lassign [def_tracks $HGVAR_SIGNOFF_DEF] def_units def_track_list
    if {$def_units eq ""} {
        gen_fail "khong doc duoc UNITS DISTANCE MICRONS trong $HGVAR_SIGNOFF_DEF"
    }
}
foreach {layer dir var dbu_var} $OFFSET_VARS {
    if {[info exists ::env($var)] && $::env($var) ne ""} {
        lappend offset_lines "export $var=[bash_quote $::env($var)]"
        lappend offset_notes "# $var=$::env($var): dat tu dong lenh"
        continue
    }
    set w [deck_variable $HGVAR_DRC_RULE_FILE $dbu_var]
    if {![string is integer -strict $w] || $w <= 0} {
        gen_fail "khong doc duoc VARIABLE $dbu_var trong $HGVAR_DRC_RULE_FILE"
    }
    set first ""
    foreach t $def_track_list {
        lassign $t t_layer t_dir t_start t_step
        if {$t_layer eq $layer && $t_dir eq $dir &&
            ($first eq "" || $t_start < [lindex $first 0])} {
            set first [list $t_start $t_step]
        }
    }
    if {$first eq ""} {
        gen_fail "DEF khong co TRACKS $dir cho $layer: $HGVAR_SIGNOFF_DEF"
    }
    lassign $first start step
    # dbu DEF -> 0.1 nm: start * 10000 / units phai nguyen
    set num [expr {$start * 10000}]
    if {$num % $def_units != 0} {
        gen_fail "TRACKS $dir $start cua $layer khong doi duoc sang 0.1 nm (UNITS $def_units)"
    }
    set t [expr {$num / $def_units}]
    set pitch [expr {2 * $w}]
    set value [expr {($t % $pitch) - $w / 2}]
    lappend offset_lines "export $var=[bash_quote $value]"
    set note "# $var=$value: DEF TRACKS $dir $start STEP $step LAYER $layer\
 (UNITS $def_units) = track dau [format %.4f [expr {$t / 10000.0}]] um, rong day $w x 0.1 nm"
    if {$t % $w != 0} {
        append note " - KHONG la boi cua do rong: $layer.AUX.1 va $layer.AUX.2 khong the cung qua"
    }
    lappend offset_notes $note
}

# ---- LVS: netlist co nguon phai cung lan KHOI 16 voi GDS --------------------
# KHOI 16 ghi _pnr_pg.v truoc soc_add_pg_pins / defOut / streamOut, nen GDS moi
# hon netlist vai phut.  Netlist moi hon GDS = streamOut chua chay lai; cach
# nhau hon 4 gio = hai file tu hai lan chay khac nhau.
if {$STEP eq "lvs"} {
    need_file $HGVAR_SIGNOFF_NETLIST_PWR "netlist co VDD/VSS (KHOI 16: ${TOP}_pnr_pg.v)"
    need_file $HGVAR_LVS_RULE_FILE "deck LVS"
    foreach cdl [concat $HGVAR_STDCELL_CDL $HGVAR_SRAM_CDL $HGVAR_FLASH_CDL] {
        need_file $cdl "CDL"
    }
    foreach lef $HGVAR_STUB_LEFS {
        need_file $lef "LEF (sinh .SUBCKT rong cho cell khong co CDL)"
    }
    set dt [expr {[file mtime $HGVAR_SIGNOFF_GDS] - [file mtime $HGVAR_SIGNOFF_NETLIST_PWR]}]
    if {$dt < -60 || $dt > 4 * 3600} {
        gen_fail "GDS va netlist khong cung mot lan KHOI 16: GDS\
 [clock format [file mtime $HGVAR_SIGNOFF_GDS] -format {%Y-%m-%d %H:%M}], netlist\
 [clock format [file mtime $HGVAR_SIGNOFF_NETLIST_PWR] -format {%Y-%m-%d %H:%M}]\
 (dat CAL_NETLIST / CAL_GDS neu co chu y)"
    }
}
if {$STEP eq "drc"} {
    need_file $HGVAR_DRC_RULE_FILE "deck DRC"
}

# ---- Ghi sourceme -------------------------------------------------------------
set out [file join $SCRIPT_DIR sourceme]
set f [open $out w]
puts $f "# Sinh boi scripts/gen_env.tcl tu project_setup.tcl - dung sua tay."
foreach {name value} [list \
        DESIGN          $HGVAR_DESIGN \
        CORES           $HGVAR_CORES \
        HYPER           $HGVAR_HYPER \
        CALIBRE         $HGVAR_CALIBRE \
        GDS_FILE        $HGVAR_SIGNOFF_GDS \
        NETLIST_PWR     $HGVAR_SIGNOFF_NETLIST_PWR \
        DRC_DECK        $HGVAR_DRC_RULE_FILE \
        LVS_DECK        $HGVAR_LVS_RULE_FILE \
        DRC_MAX_RESULTS $HGVAR_DRC_MAX_RESULTS] {
    puts $f "export $name=[bash_quote $value]"
}
foreach line $offset_notes {
    puts $f $line
}
foreach line $offset_lines {
    puts $f $line
}
close $f

puts "INFO: ghi $out"
foreach line $offset_notes {
    puts "INFO: [string range $line 2 end]"
}
exit 0
