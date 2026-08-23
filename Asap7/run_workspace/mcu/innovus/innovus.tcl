############################################################
## Backward-compatible wrapper.
##
## Preferred launch point:
##   cd Asap7/run_workspace/mcu/innovus
##   innovus -files tcl/innovus.tcl
############################################################

set INNOVUS_DIR [file dirname [file normalize [info script]]]
source [file join $INNOVUS_DIR tcl innovus.tcl]
