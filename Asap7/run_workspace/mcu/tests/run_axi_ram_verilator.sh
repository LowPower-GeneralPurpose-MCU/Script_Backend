#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mcu_dir="$(cd "$script_dir/.." && pwd)"

if [[ -n "${ASAP7_ROOT:-}" && \
      -f "$ASAP7_ROOT/asap7_sram_0p0/generated/verilog/srambank_256x4x32_6t122.v" ]]; then
    macro_model="$ASAP7_ROOT/asap7_sram_0p0/generated/verilog/srambank_256x4x32_6t122.v"
else
    macro_model="$mcu_dir/../sram_axi/genus/rtl/srambank_256x4x32_6t122.v"
fi

if [[ ! -f "$macro_model" ]]; then
    echo "Missing SRAM simulation model: $macro_model" >&2
    exit 1
fi

work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT

verilator \
    --binary \
    --timing \
    --top-module tb_axi_ram \
    -Wno-fatal \
    -Wno-TIMESCALEMOD \
    --Mdir "$work_dir/obj" \
    "$macro_model" \
    "$mcu_dir/memory/asap7_sram_128k_1rw.v" \
    "$mcu_dir/memory/axi_ram.v" \
    "$script_dir/tb_axi_ram.sv"

"$work_dir/obj/Vtb_axi_ram"
