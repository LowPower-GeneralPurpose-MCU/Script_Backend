############################################################
## Add metal fill only after routed DRC/antenna/connectivity are clean
############################################################

if {![info exists ROUTE_VERIFY_CLEAN] || !$ROUTE_VERIFY_CLEAN} {
    error "Set ROUTE_VERIFY_CLEAN 1 only after reviewing clean post-route reports"
}

# M1-M3
setMetalFill \
    -layer {M1 M2 M3} \
    -maxWidth 0.936 \
    -minWidth 0.072 \
    -maxLength 5.0 \
    -minLength 0.148 \
    -decrement 0.288 \
    -activeSpacing 0.144 \
    -gapSpacing 0.144 \
    -maxDensity 60 \
    -minDensity 25 \
    -preferredDensity 40

# M4-M5
setMetalFill \
    -layer {M4 M5} \
    -maxWidth 1.248 \
    -minWidth 0.096 \
    -maxLength 5.0 \
    -minLength 0.384 \
    -decrement 0.384 \
    -activeSpacing 0.192 \
    -gapSpacing 0.192 \
    -maxDensity 35 \
    -minDensity 10 \
    -preferredDensity 25

# M6-M7
setMetalFill \
    -layer {M6 M7} \
    -maxWidth 1.664 \
    -minWidth 0.128 \
    -maxLength 5.0 \
    -minLength 0.512 \
    -decrement 0.512 \
    -activeSpacing 0.300 \
    -gapSpacing 0.300 \
    -maxDensity 55 \
    -minDensity 25 \
    -preferredDensity 40

# M8-M9
setMetalFill \
    -layer {M8 M9} \
    -maxWidth 2.500 \
    -minWidth 0.160 \
    -maxLength 5.0 \
    -minLength 0.960 \
    -decrement 0.160 \
    -activeSpacing 0.640 \
    -gapSpacing 0.640 \
    -maxDensity 55 \
    -minDensity 25 \
    -preferredDensity 40

setMetalFill \
    -layer {Pad} \
    -maxWidth 8.0 \
    -minWidth 0.8 \
    -maxLength 8.96 \
    -minLength 8.96 \
    -decrement 0.160 \
    -activeSpacing 8.16 \
    -gapSpacing 8.16 \
    -maxDensity 30 \
    -minDensity 10 \
    -preferredDensity 25

# Keep the project-required fill command unchanged.
addMetalFill -snap -squareShape

verify_drc \
    -report ./verify_rpt/drc_after_fill.rpt

verifyProcessAntenna \
    -report ./verify_rpt/antenna_after_fill.rpt

verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_after_fill.rpt

saveDesign ./saved/axi_ram_filled.enc

puts "===================================================="
puts "METAL FILL ADDED"
puts "Review the new DRC, antenna and connectivity reports."
puts "Also run Calibre density/DRC signoff before export approval."
puts ""
puts "When clean:"
puts "  set FINAL_VERIFY_CLEAN 1"
puts "  source ./tcl/export_gds.tcl"
puts "===================================================="
