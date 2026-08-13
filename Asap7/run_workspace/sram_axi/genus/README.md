# Genus flow for AXI RAM with 16 ASAP7 1RW SRAM hard macros

## What Genus reads

Genus reads:

```text
ASAP7 RVT standard-cell Liberty files
+
srambank_256x4x32_6t122.lib
+
SRAM black-box Verilog declaration
+
asap7_sram_64k_1rw.v
+
axi_ram.v
```

Genus does **not** read:

```text
SRAM LEF
SRAM GDS
```

Those are Innovus/stream-out views.

Genus must also **not** synthesize the official SRAM behavioral model because it
contains a 1024 x 32 `reg` array.

## File structure

```text
.
├── genus.tcl
├── rtl
│   ├── axi_ram.v
│   ├── asap7_sram_64k_1rw.v
│   └── srambank_256x4x32_6t122_bb.v
└── tcl
    ├── sram_macro_setup.tcl
    ├── rtl_filelist.tcl
    ├── check_sram_macro.tcl
    └── constraint.sdc
```

## Expected SRAM collateral

```text
../tkvm/asap7/asap7_sram_0p0/
└── generated/LIB/srambank_256x4x32_6t122.lib
```

The Innovus flow additionally uses the matching 4x LEF and GDS.

## Run

From this directory:

```bash
genus -f genus.tcl
```

or start Genus and run:

```tcl
source genus.tcl
```

## Required result

The final netlist:

```text
outputs/axi_ram_syn.v
```

must contain exactly 16 instances of:

```text
srambank_256x4x32_6t122
```

The script checks this automatically and stops if the count is not 16.

## Important notes

1. `set_db / .auto_ungroup none` keeps the wrapper hierarchy readable.
2. The SRAM Liberty is added to both `.library` and `create_library_set`.
3. The SRAM black-box declaration provides the HDL interface.
4. SRAM timing, area and capacitance come from the Liberty file.
5. VDD/VSS are Liberty `pg_pin`s and do not need to appear as normal RTL ports.
   Innovus maps them with `globalNetConnect`; physical block-pin stitching is opt-in when clean SRAM edge PG access exists.
6. Change `CLK_PERIOD` in `tcl/constraint.sdc` to the real system target.
