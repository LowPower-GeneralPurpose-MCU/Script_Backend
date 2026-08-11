# ASAP7 RISC-V Innovus Flow

This directory contains the Innovus backend flow for the Genus-mapped
`riscv_pipeline` design.

## Required Genus Outputs

Run Genus first from `../genus`. Innovus reads these files directly:

- `../genus/outputs/riscv_pipeline_syn.v`
- `../genus/outputs/riscv_pipeline_syn.sdc`
- `../genus/outputs/riscv_pipeline_syn.spef` is kept as a reference only

## Main Scripts

- `innovus.tcl`: top-level wrapper for convenient launch from this directory
- `tcl/innovus.tcl`: stage driver
- `tcl/config.tcl`: top name, ASAP7 paths, LEF/Lib/GDS lists, floorplan constants
- `tcl/innovus.globals`: `init_design` inputs
- `tcl/viewDefinition.tcl`: TT 0.7 V 25 C MMMC view
- `tcl/innovus_hierFP.tcl`: hierarchy-aware floorplan stage
- `tcl/innovus_PnR.tcl`: power plan, placement, CTS, route, extraction, export
- `tcl/pins.tcl`: top-level RISC-V pin assignment
- `tcl/streamOut.map`: ASAP7 GDS layer map

## Running

From `Asap7/run_workspace/Risc_V/innovus`:

```bash
innovus -stylus -files innovus.tcl
```

For manual hierarchy-floorplan review:

```bash
INNOVUS_STAGE=hierfp innovus -stylus -files innovus.tcl
INNOVUS_STAGE=pnr    innovus -stylus -files innovus.tcl
```

`INNOVUS_STAGE=all` is the default and runs both stages in one session.

## Expected Outputs

- `saved/riscv_pipeline_hierFP.enc`
- `saved/riscv_pipeline_final.enc`
- `outputs/riscv_pipeline.gds`
- `outputs/riscv_pipeline.lef`
- `outputs/riscv_pipeline_pnr.def`
- `outputs/riscv_pipeline_pnr.sdc`
- `outputs/riscv_pipeline_pnr.spef`
- `outputs/riscv_pipeline_pnr_sta.v`
- `outputs/riscv_pipeline_pnr_pg.v`

## Notes

The current Genus result maps BPU, BTB/BHT, and the register file into
standard cells. This Innovus flow therefore does not load SRAM macro LEF/Lib/GDS
collateral. If those blocks are later changed to hard SRAM macros, add their
LEF/Lib/GDS files in `tcl/config.tcl` and add macro floorplanning before power
planning.
