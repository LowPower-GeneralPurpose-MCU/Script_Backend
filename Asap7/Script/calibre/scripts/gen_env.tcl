set f ./scripts/sourceme
if {[file exists $f]} {
  file delete -force $f
}
set OF [open $f w]
puts $OF "export CORES=24"
puts $OF "export DESIGN=Mul32"

# Ði ra 3 c?p (pv -> tcl -> layout_asap7 -> home) r?i di vào outputs/
puts $OF "export GDS_FILE=../../../outputs/Mul32_pnr.gds"

# Ði ra 3 c?p (home) r?i di vào tkvm/.../rul/
puts $OF "export ANT_DECK=../../../../tkvm/asap7/asap7sc7p5t_28/rul/calibreDRC.rul"
puts $OF "export DRC_DECK=../../../../tkvm/asap7/asap7sc7p5t_28/rul/calibreDRC.rul"
puts $OF "export LVS_DECK=../../../../tkvm/asap7/asap7sc7p5t_28/rul/calibreLVS.rul"

puts $OF "export LVS_BOX=\"\""

for {set i 1} {$i <= 10} {incr i} {
    puts $OF "export VAR_M${i}_XOFFSET=0"
    puts $OF "export VAR_M${i}_YOFFSET=0"
}
close $OF