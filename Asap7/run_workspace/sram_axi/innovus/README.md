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

## Merged-GDS master name (IMPOGDS-217 / IMPOGDS-218)

`streamOut -merge` matches merged structures to design masters by **exact
name** and has no cell-name remapping parameter. When no merge file defines a
structure called `$SRAM_MASTER`, Innovus reports only

```
**WARN: (IMPOGDS-217): Master cell: srambank_256x4x32_6t122 not found in merged file(s) ...
**WARN: (IMPOGDS-218): Number of master cells not found after merging: 1
```

and exports a top-level GDS with empty outlines where the macros should be.
Neither warning stops the run, so this used to reach `signoff_handoff.rpt` as
an unqualified `SIGNOFF_CANDIDATE_EXPORTED`.

### What the shipped file actually is

`asap7_sram_0p0/gds/srambank_32b.gds` defines 108 structures, and they are the
SRAM **primitive library**, not an assembled bank:

```
sram_cell_6t_122      tapcell_sram_6t122     sramcol_x32_sram_6t122
array_x32x4_sram_6t122  senseamp_sram_6t122  srlatch_sram_6t122
iocolgrp_sram_6t122_v2  FILLER_BLANK_6t122   dummy_sram_6t122   ...
```

There is no `srambank_256x4x32_6t122` here, and renaming one of these to the
bank name would put the wrong geometry under every macro instance. The macro's
own layout belongs with its other generated views, next to
`generated/LIB/srambank_256x4x32_6t122.lib` and
`generated/LEF/4xLEF/srambank_256x4x32_6t122.lef.4x.lef`.

### Diagnose

```sh
# What does a candidate file contain?  TOP marks structures nothing references.
python3 ./scripts/gds_structure_tool.py list <candidate.gds>

# Where is the generated macro layout?
find /home/user1/Desktop/asap7/asap7_sram_0p0 \
     \( -name '*.gds' -o -name '*.gds.gz' -o -name '*.oas' \) -print
```

Once the right file is found:

```sh
export ASAP7_SRAM_GDS=/absolute/path/to/srambank_256x4x32_6t122.gds
```

`gds_structure_tool.py rename` exists for the narrower case where a file does
hold the macro layout under a different name. It rewrites the `STRNAME`
definition and every `SNAME` reference and is a no-op when the target name
already exists. It is not a way to substitute a primitive for a macro.

### Guard

`check_merge_gds_masters` runs in `export_gds.tcl` immediately before
`streamOut` and checks **every** hard-macro master against the full `-merge`
list. By default it **warns and continues**, records the missing masters in
`signoff_handoff.rpt` under `# Macro GDS:`, and repeats them in the closing
banner. Set `ASAP7_REQUIRE_MERGED_MACRO_GDS=1` to make it refuse to export.

Macro instances are found with `dbGet -p2 -e top.insts.cell.baseClass block`.
`isBlock` is **not** a dbGet attribute in Innovus 23.14 — using it raised
`IMPDBTCL-206` and aborted `export_gds.tcl` after a complete 12-minute run, so
both the query and the call site now degrade to a warning instead of throwing.
When the query yields nothing the check reports `NOT VERIFIED`, never `passed`.

> **Do not move this check earlier.** `viewDefinition.tcl` sources
> `sram_macro_setup.tcl`, and `viewDefinition.tcl` is evaluated *inside*
> `init_design`. An error raised from there aborts `init_design`, leaves no
> design in memory, and every later command fails with
> `Design must be in memory` — one bad assertion produced 979 errors that way.

## SRAM clock leaf routing

Every CTS leaf net ending on an SRAM clock pin has to cross the hard place
blockage that covers the macro island, so its driver lands on the island
boundary and the branch can run several hundred microns. On the M2/M3
`leaf_rule` that produces 0.104 ns slew at pins whose Liberty
`max_transition` is 0.046 ns — ten `IMPCCOPT-1007` warnings that every
"real DRV" gate classifies as unfixable clock-net violations.

### What does not work

Promoting those 16 nets with `setAttribute -net ... -top_preferred_routing_layer`
after `clock_opt_design`. Measured on 2026-08-27: the constraint applied to all
16 nets, and the postRoute slew was **byte-identical** to the run without it.
The reason is in the log:

```
Net route status summary:
  Clock: 43 (unrouted=0, trialRouted=0, noStatus=0, routed=0, fixed=43)
```

`clock_opt_design` marks every clock net **fixed**, so `routeDesign` never
re-routes them and a post-CTS layer preference is silently ignored.

### The only lever that reaches them

The leaf `route_type` used *by* CTS, exposed as

```tcl
set SRAM_CTS_LEAF_BOTTOM_LAYER 2   ;# default
set SRAM_CTS_LEAF_TOP_LAYER    3   ;# default
```

Both default to the original values, so the flow behaves exactly as before.
Raising the top layer affects all 175 clock sinks, not just the 16 macro pins,
which is why it is opt-in. After any change, compare
`reports/timing_postRoute/axi_ram_postRoute.tran.gz` and the `IMPCCOPT-1007`
count against the baseline before keeping it.

Do **not** relax `target_max_trans` to silence the warning: 46 ps is a Liberty
limit on the macro pin, not a project target.

## Metal fill engine

`setMetalFill` / `addMetalFill` / `fill_setting_save` are obsolete
(`IMPMF-5050` / `IMPMF-5045` / `IMPMF-5054`). `add_fill_and_verify.tcl` now
selects an engine through `metal_fill_engine`:

| `INNOVUS_METAL_FILL_MODE` | Behaviour |
| --- | --- |
| `auto` (default) | Use `add_metal_fill_signoff` when a Pegasus rule deck or PVS technology is configured, otherwise fall back to the obsolete commands and say so. |
| `signoff` | Require the signoff engine; error out with the reason if it is unusable. |
| `legacy` | Force the obsolete in-design commands. |
| `skip` | Skip fill entirely; an external flow owns density closure. |

Point the signoff engine at a rule deck with either

```sh
export ASAP7_PEGASUS_FILL_RULE_FILE=/path/to/fill.rul
# or
export ASAP7_PEGASUS_FILL_TECHNOLOGY=<pvs_technology>
```

The ASAP7 educational PDK ships neither, so `auto` resolves to `legacy` on a
stock install. `INNOVUS_RUN_LEGACY_METAL_FILL=0` still means `skip`.

Per-layer density windows (M5 is 80×80 with a 40 µm step, Pad is 400×400) can
only be expressed in the rule deck, not through
`set_metal_fill_signoff_mode -window_size`, which takes a single scalar.
