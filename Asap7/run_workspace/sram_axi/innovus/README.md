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

Slew at the 16 SRAM clock pins is 0.104 ns against a 0.046 ns Liberty
`max_transition` — ten `IMPCCOPT-1007` warnings that every "real DRV" gate
classifies as unfixable clock-net violations.

### Measured, not assumed

Parsing `outputs/axi_ram_pnr.def` and sampling 50 points per wire segment:

| Layer | On macro body | In island gaps | Outside island | LEF OBS |
| --- | --- | --- | --- | --- |
| M2 | **0.0 µm** | 0.0 | 316.8 | blocked |
| M3 | **0.0 µm** | 0.0 | 310.8 | free |
| M4 | **0.0 µm** | 2243.6 | 286.6 | blocked |
| M5 | **0.0 µm** | 527.9 | 752.2 | blocked |
| M6 | **0.0 µm** | 508.1 | 677.0 | free |
| M7 | **0.0 µm** | 100.8 | 1243.6 | free |

Two things follow.

**The macro OBS is respected exactly.** Not one micron of clock wire sits over
a macro body, and `verify_drc` returns 0 — the independent confirmation.
`createPlaceBlockage` blocks *placement only*; the DEF carries a single
blockage and its type is `PLACEMENT`. What keeps routing off the macro is the
SRAM LEF obstruction, which is why `sram_route_guard.tcl` is deliberately
`enabled 0` (see `reports/sram_route_guard.rpt`).

**Layer is not the problem — distance is.** The longest branches, `u_mem/CTS_9`
to `BANK[0]/clk` and `u_mem/CTS_3` to `BANK[7]/clk`, are ~452 µm of which
**~447 µm is already on M4**. M2 and M3 never enter the island at all: the
router escapes upward and crosses through the 4.32 µm inter-macro channels.

### What does not work

- **Raising `leaf_rule` above M2/M3.** The router already reaches M4 on its
  own for these nets. Changing the CTS route type moves nothing.
- **`setAttribute -net ... -top_preferred_routing_layer` after
  `clock_opt_design`.** Measured on 2026-08-27: applied to all 16 nets, and
  postRoute slew was byte-identical. `clock_opt_design` leaves every clock net
  marked **fixed** (`Clock: 43 (... routed=0, fixed=43)`), so `routeDesign`
  never re-routes them.

### What would work

Give CTS somewhere to put a buffer inside the island. Today the hard place
blockage covers the whole array plus its 2.16 µm border, so nine of the ten
violating buffers sit at x = 506.952 or y = 708.480 — right on the boundary,
~450 µm from the pin they drive. Keeping a few standard-cell rows inside the
4.32 µm channels, or switching that blockage from `hard` to `soft`, shortens
the branch at its source.

`SRAM_CTS_LEAF_BOTTOM_LAYER` / `SRAM_CTS_LEAF_TOP_LAYER` still exist and still
default to the original M2/M3, but the measurement above says they are not the
lever to pull.

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

## Repository hygiene

A completed `sram_axi` run leaves about 180 MB behind:

| Path | Size | Tracked? |
| --- | --- | --- |
| `outputs/axi_ram_pnr.gds` | ~60 MB | no — past GitHub's 50 MB file limit |
| `outputs/axi_ram_pnr.def` | ~60 MB | no |
| `saved/*.enc.dat` | ~60 MB | no |
| `innovus.log` / `innovus.logv` | ~6 MB | no |
| `reports/` + `verify_rpt/` | ~2 MB | **yes** — the record of what a run produced |
| `tcl/` + `scripts/` | small | **yes** |

The repository-root `.gitignore` covers all of the above. Everything it ignores
is regenerated by rerunning the flow.

Files committed before that `.gitignore` existed stay tracked; drop them from
the index without deleting them on disk:

```sh
git rm -r --cached Asap7/run_workspace/sram_axi/innovus/saved
git rm --cached Asap7/run_workspace/sram_axi/innovus/outputs/axi_ram_pnr.gds \
                Asap7/run_workspace/sram_axi/innovus/outputs/axi_ram_pnr.def \
                Asap7/run_workspace/sram_axi/innovus/innovus.log \
                Asap7/run_workspace/sram_axi/innovus/innovus.logv
git commit -m "Stop tracking Innovus run artifacts"
```

If any of them is already in a pushed commit, GitHub still rejects the push
because the blob lives in history — rewrite it with `git filter-repo` or start
a fresh branch from a clean tree.

## Dead code removed (2026-08-27)

After the first fully clean run, a static pass removed only what could be
proven unreachable — 7200 lines down to 7073:

- **6 procs** nothing called: `assert_clean_si_glitch_report`,
  `verify_pg_special_drc_or_stop`, `pg_upper_positive_mod`,
  `report_gds_missing_structure`, and then `gds_structure_names` and
  `write_pg_drc_scope_report`, which were left unreachable once their only
  callers went.
- **7 variables** assigned and never read: `POWER_NETS`, `SRAM_SIM_VERILOG`
  (kept as a comment, since the path is worth knowing), `SRAM_PIN_TAPS_BUILT`,
  `IN_DESIGN_REPORTS_CLEAN`, `density_status`, `row_height`, `site_width`.
- **3 Innovus globals** that only restated the documented default:
  `defHierChar {/}`, `init_abstract_view {abstract}`, `init_design_settop 1`.
- **4 duplicate** `set init_design_uniquify 1` lines, now set once in
  `innovus.globals`.

The remaining globals in `innovus.globals` are **not** dead: Innovus reads
`init_verilog`, `init_mmmc_file`, `init_top_cell`, `init_gnd_net`,
`init_pwr_net`, `init_layout_view` and `auto_file_dir` itself, and the Cadence
boilerplate block has either a non-default or an undocumented default. The file
is now split into "design inputs" and "session boilerplate" so the difference is
visible at a glance.

`innovus.tcl` (806 lines) and `innovus_pnr.tcl` (652) still overlap heavily, but
they diverge in scattered places rather than sharing a clean prefix, so merging
them is a real refactor and was left alone.


## Adopted from the reference ROHM180 flow (2026-08-27)

Two changes kept, one experiment measured and reverted, one bug found.

### Kept: `-cppr both`

`setAnalysisMode -analysisType onChipVariation -cppr both`. Without CPPR the
clock path shared by launch and capture is de-rated twice. One clock tree feeds
175 sinks here, so the shared portion is long and the recovered margin is real.

### Kept: bounded post-route DRC repair

`repair_postroute_drc` runs `verify_drc`; only if it is dirty does it run
`ecoRoute -fix_drc` + `optDesign -postRoute -drv`, then re-check, up to two
passes. A clean run does exactly one `verify_drc`, as before, and the existing
`assert_clean_drc_report` gate still has the final say. This mirrors the
reference flow's "these two steps can be repeated until done" loop. Confirmed
firing in the 19:16 run (`drvFix1`, `drvFix2`).

### Fixed: `set_max_fanout` was silently dropped

`SRAM_OUTPUT_MAX_FANOUT` (default 1) applies the reference flow's
`set_max_fanout 1` to this project's SRAM outputs. The first attempt produced

```
**ERROR: (TCLCMD-1048): constraints are specified but no constraint mode is
enabled interactively.
```

`set_max_fanout` is an SDC command: outside an interactive constraint mode
Innovus prints that and **drops the constraint without raising a Tcl error**, so
the surrounding `catch` never saw it. It is now bracketed by
`set_interactive_constraint_modes [all_constraint_modes -active]` … `{}`, the
same pattern the flow already uses for `set_propagated_clock`.

### Measured and reverted: opening the inter-macro channels

The clock-slew defect is geometric. With a 2-row halo on each side of a 4-row
channel the halos meet exactly, so the channel holds zero legal sites — the
original comment in `sram_macro_setup.tcl` said so — and CTS had to place every
clock buffer outside the island.

The 19:16 run tried `SRAM_HALO_ROWS 1` + `SRAM_ISLAND_BLOCKAGE_TYPE soft` +
`SRAM_ISLAND_CUT_ROWS_UNDER_MACROS_ONLY 1`. It did exactly what it was meant to
— and broke power.

| | Baseline | Channels open |
| --- | --- | --- |
| `IMPCCOPT-1007` (SRAM clk slew) | 10 | **0** |
| postRoute `max_tran` violations | 4 | **0** |
| CTS buffer location | island edge (x 506.952) | **inside channel, y 177.12** |
| CTS skew (target 0.040 ns) | 0.039 | **0.096** |
| PG DRC after filler | 0 | **27** (22× V4 CUTSPACING at x≈251.3) |
| PG connectivity after filler | clean | **999 opens** (IMPVFC-92) |
| Placed instances | 257,074 | 276,732 |
| Flow | reached GDS | **stopped before metal fill** |

Root cause of the breakage: the channels already carry the island PG — an M5
stripe runs the full height of every gap column (`reports/sram_island_pg_edges.rpt`).
Cells placed there collide with those stripes on V4, and their M1 rails form
isolated segments that no filler can bridge across a macro, so they never reach
the mesh. Fillers also filled the newly exposed channel rows, which is most of
the +19,658 instances.

**Opening the channels is not a floorplan knob on its own — it needs channel PG
straps designed first.** All three defaults are back to the configuration that
runs clean end to end. The knobs remain so the experiment is one line to repeat:

```tcl
set SRAM_HALO_ROWS 1
set SRAM_ISLAND_BLOCKAGE_TYPE soft
set SRAM_ISLAND_CUT_ROWS_UNDER_MACROS_ONLY 1
```

`reports/sram_island_blockage_geometry.rpt` now prints `halo_rows`,
`free_channel_rows`, `place_blockage_type` and `cut_rows_under_macros_only`, so
which configuration produced a run is visible from the report alone.

### Deliberately not adopted

- **`setRouteMode -earlyGlobalReverseDirection` over the macros.** The mechanism
  already exists in `sram_route_guard.tcl`. It only alters the eGR congestion
  estimate on the named layer inside the named box, and the ASAP7 SRAM abstract
  already blocks M1/M2/M4/V4/M5 over the macro body — the DEF measurement found
  **0 µm** of any net over a macro body. There is no capacity left there to
  discourage. Enabling the guard would also switch on its
  `createRouteBlk -layer {M6 M7}`, blocking the only free layers.
- **Tie cells (`addTieHiLo`).** This flow ties through
  `globalNetConnect -type tiehi/tielo` to the rails. Whether ASAP7 ships
  TIEHI/TIELO cells could not be verified here, so nothing was changed.
- **Filler before routing.** A trade-off, not an improvement: it avoids
  `IMPSP-5217` but freezes cell sites before `optDesign -postRoute`.
