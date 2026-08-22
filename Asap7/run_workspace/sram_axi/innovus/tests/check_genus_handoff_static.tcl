############################################################
## Unit checks for the Genus-to-Innovus handoff guard.
############################################################

source ./tcl/prepare_innovus_sdc.tcl
source ./tcl/sync_genus_handoff.tcl

set tmp_dir ./reports/__tmp_genus_handoff
set genus_netlist $tmp_dir/genus/axi_ram_syn.v
set genus_sdc $tmp_dir/genus/axi_ram_syn.sdc
set innovus_netlist $tmp_dir/innovus/axi_ram_syn.v
set innovus_sdc $tmp_dir/innovus/axi_ram_syn.sdc

file delete -force $tmp_dir
file mkdir [file dirname $genus_netlist]

proc write_text_file {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

write_text_file $genus_netlist "module axi_ram; endmodule\n"
write_text_file $genus_sdc {
set_units -time ps
set_max_transition 300.0 [current_design]
}

sync_genus_handoff \
    $genus_netlist $genus_sdc \
    $innovus_netlist $innovus_sdc \
    0.300

if {![file exists $innovus_netlist] || ![file exists $innovus_sdc]} {
    error "Validated Genus artifacts were not copied into the Innovus handoff"
}

write_text_file $genus_sdc {
set_units -time ps
set_max_transition 500.0 [current_design]
}
if {![catch {
    sync_genus_handoff \
        $genus_netlist $genus_sdc \
        $innovus_netlist $innovus_sdc \
        0.300
} stale_error]} {
    error "A stale 500ps Genus handoff was accepted"
}
if {[string first {Rerun Genus before Innovus} $stale_error] < 0} {
    error "Stale Genus handoff error is not actionable: $stale_error"
}

file delete -force $tmp_dir
puts "PASS: Genus handoff is synchronized only after the 300ps constraint is present"
