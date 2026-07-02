set HGVAR_DESIGN "Mul32"
set HGVAR_HCELL_LIST_FILE "hcell.list"
set HGVAR_LVS_HCELL_LIST_APPEND [list]
set HGVAR_LVS_HCELL_LIST_FILES [list]

# C?p nh?t du?ng d?n d?n file netlist xu?t t? Innovus (lùi 3 c?p ra home r?i vào outputs)
set HGVAR_SIGNOFF_NETLIST_PWR "../../../outputs/Mul32_pnr_sta.v"

# C?p nh?t du?ng d?n d?n file CDL c?a thu vi?n cell g?c (lùi 3 c?p ra home r?i vào tkvm)
set HGVAR_STDCELL_CDL "../../../../tkvm/asap7/asap7sc7p5t_28/CDL/LVS/asap7sc7p5t_28_L.cdl ../../../../tkvm/asap7/asap7sc7p5t_28/CDL/LVS/asap7sc7p5t_28_R.cdl" 
set HGVAR_SRAM_CDL    ""
set HGVAR_FLASH_CDL   ""

#### hcell.list ####
set f $HGVAR_HCELL_LIST_FILE
if {[file exists $f]} {
  file delete -force $f
}
set OF [open $f w]
puts $OF "$HGVAR_DESIGN $HGVAR_DESIGN"
foreach i ${HGVAR_LVS_HCELL_LIST_APPEND} {
  puts $OF "$i $i"
}
foreach i ${HGVAR_LVS_HCELL_LIST_FILES} {
  if {[file exists $i]} {
    set IF [open $i r]
    while {[gets $IF line] >= 0} {
      puts $OF "$line $line"
    }
    close $IF
  }
}
close $OF

#### prepare v2lvs commands ####
puts "V2LVS Wrapper"
set V2LVS_CMD          "v2lvs -64 -sn"
set V2LVS_CMD_SPICESIM "v2lvs -64 -sn -i -sl"

foreach lib_ckt [concat ${HGVAR_STDCELL_CDL} ${HGVAR_SRAM_CDL} ${HGVAR_FLASH_CDL}] {
  if {$lib_ckt ne "" && [file exists $lib_ckt]} {
    puts "INFO: including $lib_ckt"
    set V2LVS_CMD          "$V2LVS_CMD -s $lib_ckt"
    set V2LVS_CMD_SPICESIM "$V2LVS_CMD_SPICESIM -lsr $lib_ckt -s $lib_ckt"
  } else {
    if {$lib_ckt ne ""} { puts "WARNING: $lib_ckt does not exist!" }
  }
}

set V2LVS_CMD          "$V2LVS_CMD -o ${HGVAR_DESIGN}.v2lvs.net -v ${HGVAR_SIGNOFF_NETLIST_PWR}"
set V2LVS_CMD_SPICESIM "$V2LVS_CMD_SPICESIM -o ${HGVAR_DESIGN}.src.net -v ${HGVAR_SIGNOFF_NETLIST_PWR}"

#### execute v2lvs ####
puts "V2LVS_CMD is:      $V2LVS_CMD"
puts "Executing"
catch { eval exec $V2LVS_CMD }

puts "V2LVS_CMD_SPICESIM is:      $V2LVS_CMD_SPICESIM"
puts "Executing"
catch { exec bash -c $V2LVS_CMD_SPICESIM }

exit