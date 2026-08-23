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

- one lower-left 4x4 SRAM island
- all SRAM macros in one physical group
- fixed macro placement
- row/column gaps reserved for local SRAM power straps
- hard placement blockage over the complete island

### `tcl/sram_island_power.tcl`

Creates the SRAM-local power before standard-cell placement:

- M4 horizontal straps in SRAM row gaps and the top island halo
- M5 vertical straps only on the right/left island edge by default
- M5 column-gap straps are opt-in with `SRAM_ENABLE_COLUMN_GAP_PG=1`
- SRAM `blockPin` special routing is opt-in with `SRAM_CONNECT_BLOCK_PINS=1`
- `editTrim` on VDD/VSS

### `innovus.tcl`

A full patched version of the teacher's Innovus script.

Main changes:

1. explicit macro-aware floorplan
2. macro placement before power planning
3. local SRAM M4 row-gap/top PG plus M5 island-edge spines
4. SRAM hard-macro body kept clear of top-level special PG by default
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
innovus -stylus -files tcl/innovus.tcl
```

or use the command appropriate for the installed Innovus release.

The master flow runs in-design metal fill by default after routed DRC,
connectivity, setup, hold and real-DRV checks pass. SI remains a hard gate when
the loaded standard-cell and SRAM libraries contain complete noise models. Set
`INNOVUS_REQUIRE_ZERO_SI=1` to force strict zero-glitch gating, or `0` to keep
SI diagnostic while validating an educational library set. Set
`INNOVUS_RUN_LEGACY_METAL_FILL=0` only when a separate Pegasus flow owns metal
fill and density closure.

After post-route hold optimization, the flow measures SI glitches once, applies
two-track routing space to victim nets, runs DRV/glitch repair, then applies a
final three-track routing-only pass to remaining victims. Area reclaim is
disabled in this phase so it cannot undo the repaired routing.

Physical filler cells are inserted only after setup, hold and SI optimization.
This keeps placement rows available for ECO buffers; inserting fillers earlier
would make row density 100 percent and block post-route repairs.

`viewDefinition.tcl` prefers the ASAP7 CCSN libraries when they are installed
and writes `verify_rpt/si_model_status.rpt`. It falls back to CCS timing models
when CCSN files are unavailable. Because the generated SRAM Liberty normally
lacks noise characterization, residual SRAM glitches are reported but are not
treated as signoff-clean evidence.

The tracked 4x tech LEF keeps geometric values scaled but restores the original
dimensionless density percentages: M5 is 15/90 and Pad is 20/80.  Innovus also
writes a plain-text SI report and `verify_rpt/metal_density_abstract_after_fill.rpt`.
That density report is diagnostic only because the SRAM LEF contains OBS but
not the internal SRAM GDS metal.

When all in-design gates pass, the flow exports `outputs/axi_ram_pnr.gds` as a
signoff candidate.  Stream-out merges the LVT, RVT and SRAM GDS libraries and
writes `verify_rpt/signoff_handoff.rpt`.  The candidate still requires
Calibre/Pegasus density, DRC, LVS and antenna checks on the merged GDS.

To continue from an already open, clean routed session without rerunning PnR:

```tcl
source ./tcl/verify_route.tcl
# Continue only when the recheck reports that ROUTE_VERIFY_CLEAN may be enabled.
set ROUTE_VERIFY_CLEAN 1
source ./tcl/add_fill_and_verify.tcl
```

`add_fill_and_verify.tcl` independently checks the recheck setup, hold, real
DRV, DRC, connectivity and SI reports. Setting the flag alone cannot bypass the
metal-fill gate.

`innovus_pnr.tcl` intentionally stops at `saved/axi_ram_routed.enc`; use the
master `innovus.tcl` for the one-command route, fill and export flow.

To override the project stream-out map or standard-cell GDS list:

```sh
export ASAP7_GDS_MAP_FILE=/absolute/path/to/streamOut.map
export ASAP7_STDCELL_GDS_FILES="/path/to/L.gds /path/to/R.gds"
```

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
