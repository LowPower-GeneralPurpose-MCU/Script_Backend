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

cd "$mcu_dir"
shopt -s globstar nullglob
rtl=(**/*.v)

if [[ "${#rtl[@]}" -ne 53 ]]; then
    echo "Expected 53 synthesizable Verilog files, found ${#rtl[@]}" >&2
    exit 1
fi

verilator \
    --lint-only \
    --timing \
    --top-module top_soc \
    -Wall \
    -Wno-DECLFILENAME \
    -Wno-PINMISSING \
    -Wno-PINCONNECTEMPTY \
    -Wno-TIMESCALEMOD \
    -Wno-WIDTH \
    -Wno-UNUSEDSIGNAL \
    -Wno-UNUSEDPARAM \
    -Wno-CASEINCOMPLETE \
    -Wno-CASEOVERLAP \
    -Wno-LATCH \
    -Wno-EOFNEWLINE \
    -Wno-GENUNNAMED \
    -Wno-ASCRANGE \
    -Wno-UNSIGNED \
    -Wno-BLKSEQ \
    -Wno-SYNCASYNCNET \
    -I. \
    -Iinterrupt/CLINT \
    -Iinterrupt/dma \
    -Iinterrupt/plic \
    "$macro_model" \
    "${rtl[@]}"

echo "MCU_RTL_LINT_PASS (${#rtl[@]} RTL files)"

