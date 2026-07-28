# ASAP7 AXI SRAM macro integration — teacher-style Innovus Tcl

This package follows the file separation used in:

- `innovus.globals`
- `viewDefinition.tcl`
- `pins.tcl`
- `innovus.tcl`

## Files

### `tcl/innovus.globals`

Contains only Innovus initialization inputs:

- ASAP7 tech LEF
- standard-cell LEFs
- generated SRAM 4x LEF
- mapped Verilog netlist
- MMMC file
- VDD/VSS names
- top-cell name

The generated hard SRAM LEF is separate from
`asap7sc7p5t_28_SRAM_4x_220121a.lef`.

### `tcl/viewDefinition.tcl`

Contains only MMMC objects:

- RVT TT standard-cell Liberty files
- SRAM Liberty
- QRC corner
- operating condition
- delay corner
- constraint mode
- analysis view

### `tcl/pins.tcl`

Uses the teacher's `setPinAssignMode` + `editPin` style.

Because the SRAM macros occupy the TOP and BOTTOM core boundaries:

- AXI write interface is placed on LEFT/M6
- AXI read interface is placed on RIGHT/M6
- TOP/BOTTOM are kept mostly free for SRAM signal escape and PG routing

### `tcl/sram_macro_floorplan.tcl`

Creates an explicit macro-aware floorplan:

- 8 SRAMs at the bottom boundary
- 8 SRAMs at the top boundary
- bottom row orientation `R180`
- top row orientation `R0`
- halo around every macro
- macro status `fixed`
- straight rows, so no notches

The selected macro's data pins are close to its local bottom edge.
Therefore:

- bottom row uses `R180` so data pins face upward/inward
- top row uses `R0` so data pins face downward/inward

### `tcl/sram_gap_stripes.tcl`

Creates one M7 VDD/VSS pair in every macro gap.

This script replaces the original ordinary M7 stripe command.
M6 horizontal and M5 vertical grids remain in the teacher's flow.

### `tcl/sram_macro_power.tcl`

Adds `sroute -connect {blockPin}`.

The teacher's original:

```tcl
sroute -connect {corePin}
```

only handles standard-cell rails. SRAM VDD/VSS are hard-macro block pins.

### `innovus.tcl`

A full patched version of the teacher's Innovus script.

Main changes:

1. explicit macro-aware floorplan
2. macro placement before power planning
3. dedicated M7 VDD/VSS pairs in macro gaps
4. SRAM block-pin power connection
5. `place_design_refine_macro false`
6. output names changed from `Mul32` to `axi_ram`
7. SRAM GDS merged during stream-out

## Required collateral

Expected directory structure:

```text
../tkvm/asap7/
├── asap7sc7p5t_28/
└── asap7_sram_0p0/
    ├── generated/LIB/srambank_256x4x32_6t122.lib
    ├── generated/LEF/4xLEF/srambank_256x4x32_6t122.lef.4x.lef
    └── gds/srambank_32b.gds
```

## Required synthesis result

`outputs/axi_ram_syn.v` must still contain 16 instances of:

```text
srambank_256x4x32_6t122
```

The hard macro must not be replaced by flip-flops.

## Running

From the design run directory:

```tcl
innovus -stylus -files innovus.tcl
```

or use the command appropriate for the installed Innovus release.

## First checks after `init_design`

In the Innovus console:

```tcl
dbGet [dbGet -p2 top.insts.cell.name srambank_256x4x32_6t122].name
```

Expected: 16 instances.

After floorplan:

```tcl
dbGet [dbGet -p2 top.insts.cell.name srambank_256x4x32_6t122].pStatus
```

Expected: every instance is `fixed`.

After power planning:

```tcl
verifyConnectivity -type special -noUnroutedNet
```
