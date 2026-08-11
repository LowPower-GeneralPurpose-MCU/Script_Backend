# Convenience wrapper. Run from Asap7/run_workspace/Risc_V/innovus with:
#   innovus -stylus -files innovus.tcl

set wrapper_file [file normalize [info script]]
set wrapper_dir  [file dirname $wrapper_file]
cd $wrapper_dir

source ./tcl/innovus.tcl
