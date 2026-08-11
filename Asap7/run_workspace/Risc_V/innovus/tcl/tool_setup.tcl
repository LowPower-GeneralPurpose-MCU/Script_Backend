# Common non-design setup for both hierarchy-floorplan and PnR sessions.
source ./tcl/config.tcl

foreach out_dir {outputs reports verify_rpt saved logs} {
    if {![file isdirectory $out_dir]} {
        file mkdir $out_dir
    }
}

if {[info exists ::env(USER)]} {
    set RUN_USER $::env(USER)
} else {
    set RUN_USER user
}
set auto_file_dir [file join /tmp $RUN_USER [format "innovus_riscv_%d" [pid]]]
file mkdir $auto_file_dir

set CORES 1
if {![catch {open "/proc/cpuinfo" r} cpu_file]} {
    set detected_cores [regexp -all -line {^processor\s*:} [read $cpu_file]]
    close $cpu_file
    if {$detected_cores > 0} {
        set CORES $detected_cores
    }
}

if {[info exists ::env(INNOVUS_CPUS)] && $::env(INNOVUS_CPUS) ne ""} {
    set CORES $::env(INNOVUS_CPUS)
    if {![string is integer -strict $CORES] || $CORES < 1} {
        error "INNOVUS_CPUS must be a positive integer, got '$CORES'"
    }
}

# The available Innovus license in the reference log permits eight CPU jobs.
if {$CORES > 8} {
    set CORES 8
}

setDesignMode -process 7
setDesignMode \
    -bottomRoutingLayer 2 \
    -topRoutingLayer 7
setMultiCpuUsage -acquireLicense $CORES
setMultiCpuUsage -localCpu $CORES
setDistributeHost -local

puts "INFO: Innovus CPUs=$CORES, auto_file_dir=$auto_file_dir"
