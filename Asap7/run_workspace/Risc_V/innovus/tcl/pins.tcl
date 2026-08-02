# =============================================================================
# RISC-V top-level pin assignment.
# Teacher rule: declare all pins and spread them over all four sides.
# ASAP7 preferred directions: M6 horizontal, M7 vertical.
# =============================================================================

set bottom_pins {clk reset_n riscv_start}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend bottom_pins [format {reset_vector_in[%d]} $i]
}

set left_pins {icache_read_req}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend left_pins [format {icache_addr[%d]} $i]
}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend left_pins [format {icache_read_data[%d]} $i]
}
lappend left_pins icache_hit icache_stall icache_read_req_lane1
for {set i 31} {$i >= 0} {incr i -1} {
    lappend left_pins [format {icache_addr_lane1[%d]} $i]
}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend left_pins [format {icache_read_data_lane1[%d]} $i]
}
lappend left_pins icache_hit_lane1 icache_stall_lane1

set right_pins {dcache_read_req dcache_write_req}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend right_pins [format {dcache_addr[%d]} $i]
}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend right_pins [format {dcache_write_data[%d]} $i]
}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend right_pins [format {dcache_read_data[%d]} $i]
}
lappend right_pins dcache_hit dcache_stall {mem_size_top[1]} {mem_size_top[0]} mem_unsigned_top

set top_pins {meip_i msip_i mtip_i riscv_done wfi_sleep_out dbg_halt_req dbg_resume_req dbg_halted}
for {set i 15} {$i >= 0} {incr i -1} {
    lappend top_pins [format {dbg_reg_read_addr[%d]} $i]
}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend top_pins [format {dbg_reg_read_data[%d]} $i]
}
lappend top_pins dbg_reg_write_en
for {set i 15} {$i >= 0} {incr i -1} {
    lappend top_pins [format {dbg_reg_write_addr[%d]} $i]
}
for {set i 31} {$i >= 0} {incr i -1} {
    lappend top_pins [format {dbg_reg_write_data[%d]} $i]
}

# Fail before editPin if RTL/netlist and pin script no longer agree.
set assigned_pins [concat $bottom_pins $left_pins $right_pins $top_pins]
set design_pin_names [dbGet top.terms.name]

foreach pin_name $assigned_pins {
    if {[lsearch -exact $design_pin_names $pin_name] < 0} {
        error "pins.tcl references a non-existent top pin: $pin_name"
    }
}

foreach design_pin $design_pin_names {
    if {[lsearch -exact $assigned_pins $design_pin] < 0} {
        error "Top pin is not assigned to any side in pins.tcl: $design_pin"
    }
}

setPinAssignMode -pinEditInBatch true

# Bottom/top use vertical M7 shapes.  Left/right use horizontal M6 shapes.
# 0.128 x 0.288 um is on-grid and satisfies the scaled minimum area/length.
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 \
    -spreadType side -spreadDirection counterclockwise \
    -side BOTTOM -layer M7 -honorConstraint 1 -pin $bottom_pins

editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 \
    -spreadType side -spreadDirection counterclockwise \
    -side LEFT -layer M6 -honorConstraint 1 -pin $left_pins

editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 \
    -spreadType side -spreadDirection counterclockwise \
    -side RIGHT -layer M6 -honorConstraint 1 -pin $right_pins

editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 \
    -spreadType side -spreadDirection counterclockwise \
    -side TOP -layer M7 -honorConstraint 1 -pin $top_pins

setPinAssignMode -pinEditInBatch false

puts "INFO: assigned [llength $assigned_pins] RISC-V top-level pins"
