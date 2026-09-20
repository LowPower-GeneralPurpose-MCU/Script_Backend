proc read_binary_file {path label} {
    if {![file isfile $path]} {
        error "Missing $label: [file normalize $path]"
    }
    set fp [open $path rb]
    fconfigure $fp -translation binary
    set data [read $fp]
    close $fp
    return $data
}

proc check_mapped_sram_count {netlist master expected} {
    set text [read_binary_file $netlist "Genus netlist"]
    # write_hdl xuong dong truoc ten instance khi ten escaped qua dai, nen
    # '(' khong chac nam cung dong voi ten module.  Pattern doi '(' cung dong
    # bo qua dung 12 macro cache trong generate block -> 72/84 gia.  Xem
    # check_sram_mapped_netlist trong genus/tcl/genus.tcl.
    regsub -all {[ \t\r\n]+} $text " " flat
    set escaped_master [string map {. \\.} $master]
    set count 0
    foreach stmt [split $flat ";"] {
        if {[regexp -- "^ ?$escaped_master\[ \t\]" $stmt]} {
            incr count
        }
    }
    if {$count != $expected} {
        error "Genus handoff has $count instances of $master; expected $expected"
    }
    puts "Validated Genus handoff SRAM count: $count"
}

proc verilog_identifier_pattern {name} {
    return [format {(^|[^A-Za-z0-9_$])%s([^A-Za-z0-9_$]|$)} $name]
}

proc check_text_has_identifiers {label text names} {
    foreach name $names {
        if {![regexp -- [verilog_identifier_pattern $name] $text]} {
            error "$label is missing required identifier '$name'"
        }
    }
}

proc check_text_lacks_identifiers {label text names} {
    foreach name $names {
        if {[regexp -- [verilog_identifier_pattern $name] $text]} {
            error "$label still contains obsolete identifier '$name'"
        }
    }
}

proc check_top_io_handoff {netlist sdc} {
    set netlist_text [read_binary_file $netlist "Genus netlist"]
    set sdc_text     [read_binary_file $sdc "Genus SDC"]

    # 2026-09-11: I2C/UART/SPI/PWM/GPIO di qua 32 pad cua apb_pinmux, nen
    # bo ba chan chia se duy nhat cua nhom do la pad_in/pad_out/pad_oe.
    # (Khong them uart_tx, i2c_scl_i... vao obsolete: ten do van con la net
    # noi bo cua top_soc trong netlist phang.)
    set required_ports {
        pad_in pad_out pad_oe
        flash_io_i flash_io_o flash_io_oe
        sdram_dq_i sdram_dq_o sdram_dq_oe
    }
    set obsolete_ports {
        i2c_scl i2c_sda flash_io sdram_dq
    }

    check_text_has_identifiers "Genus netlist" $netlist_text $required_ports
    check_text_lacks_identifiers "Genus netlist" $netlist_text $obsolete_ports
    check_text_has_identifiers "Genus SDC" $sdc_text $required_ports
    check_text_lacks_identifiers "Genus SDC" $sdc_text $obsolete_ports

    if {[regexp {(^|\n)[ \t]*inout[ \t]} $netlist_text]} {
        error "Genus netlist still contains an inout declaration; Innovus flow expects split I/O signals"
    }

    puts "Validated split top-level I/O handoff"
}

# LEF cua macro SRAM la nguon DUY NHAT cua hinh SRAM khi streamOut -outputMacros
# (asap7_sram_0p0 khong co GDS rieng tung macro), nen toa do lech manufacturing
# grid o day se di thang vao GDS.  Run 2026-09-18 co 3908 loi ngay o init_design,
# tat ca tu srambank_128x4x20_6t122.lef.4x.lef:
#   IMPLF-82 x3907  toa do lech 0.002 um = nua MANUFACTURINGGRID 0.004
#   IMPLF-40 x1     macro tham chieu SITE 'coreSite' khong duoc dinh nghia o dau
# Keo theo IMPSR-552 luc sroute va IMPPP-133 (OBS V3 ngoai boundary macro).
# Sua bang scripts/fix_sram_lef.py (xem thong bao cua proc nay).
#
# Tra ve {so_toa_do_lech {site_khong_dinh_nghia ...}}.
proc check_lef_grid_site {text grid known_sites} {
    set offgrid 0
    set bad_sites {}
    # Trong LEF, "SITE ten ;" (co dau ;) la macro THAM CHIEU mot site, con
    # "SITE ten" (khong co ;) la dong mo mot dinh nghia site.  Chi tham chieu
    # moi doi hoi site phai da ton tai.
    foreach raw [split $text "\n"] {
        set raw [string trim $raw]
        if {[regexp {^SITE[ \t]+(\S+)[ \t]*;} $raw -> site]} {
            if {[lsearch -exact $known_sites $site] < 0 &&
                [lsearch -exact $bad_sites $site] < 0} {
                lappend bad_sites $site
            }
            continue
        }
        set line [string trim [string map {";" " "} $raw]]
        if {![regexp {^(RECT|POLYGON|PATH|ORIGIN|SIZE|FOREIGN)[ \t]} $line]} {
            continue
        }
        # Chi nhan token la so THUAN: bo qua 'BY', 'MASK', 'ITERATE' va ten macro
        # trong FOREIGN (vd srambank_128x4x20_6t122 co chu so ben trong).
        foreach token [lrange [split $line] 1 end] {
            if {![regexp {^-?[0-9]+(\.[0-9]+)?$} $token]} {
                continue
            }
            set q [expr {double($token) / $grid}]
            if {abs($q - round($q)) > 1.0e-6} {
                incr offgrid
            }
        }
    }
    return [list $offgrid $bad_sites]
}

# USE cua tung chan trong LEF macro: dict {ten_chan USE}.  Chan khong khai USE
# thi khong co trong dict (LEF mac dinh USE SIGNAL).
proc lef_pin_use {text} {
    set uses [dict create]
    set pin ""
    foreach raw [split $text "\n"] {
        set line [string trim $raw]
        set w [regexp -inline -all {\S+} $line]
        switch -- [lindex $w 0] {
            PIN  { set pin [lindex $w 1] }
            OBS  { set pin "" }
            END  { if {[lindex $w 1] eq $pin} { set pin "" } }
            USE  { if {$pin ne ""} {
                       dict set uses $pin [string toupper \
                           [string trimright [lindex $w 1] ";"]]
                   } }
        }
    }
    return $uses
}

# Chan nguon trong LEF phai khai dung USE.  Run 2026-09-20:
#   **WARN: (IMPVL-536): The PG type of pin 'VSS' of cell
#   'srambank_128x4x20_6t122' doesn't match between the timing library and LEF
#   file.  In the timing library the pin is defined as 'ground' pin, but in LEF
#   file it is defined as 'power' pin.
# globalNetConnect noi theo TEN chan nen mach van dung va verifyConnectivity
# van sach, nhung moi cong cu doc LEF theo USE (sroute/addRing khi loc theo
# loai net, deck LVS, ban abstract do write_lef_abstract xuat ra) deu thay VSS
# la chan nguon duong.
#
# Tra ve danh sach {ten_chan use_dang_co use_dung_ra_phai_la}.
proc check_lef_pg_use {text {expected {VDD POWER VSS GROUND}}} {
    set bad {}
    set uses [lef_pin_use $text]
    foreach {name want} $expected {
        if {![dict exists $uses $name]} {
            continue
        }
        set have [dict get $uses $name]
        if {$have ne $want} {
            lappend bad [list $name $have $want]
        }
    }
    return $bad
}

# Ten SITE duoc dinh nghia trong mot LEF (tech hoac cell).
proc lef_defined_sites {text} {
    set sites {}
    foreach line [split $text "\n"] {
        set line [string trim $line]
        # Dong mo dinh nghia site khong co dau ; (tham chieu thi co).
        if {[regexp {^SITE[ \t]+(\S+)$} $line -> site]} {
            lappend sites $site
        }
    }
    return $sites
}
