#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rtl_dir="$(cd "$script_dir/.." && pwd)"
run_workspace_dir="$(cd "$rtl_dir/../../.." && pwd)"

if [[ -n "${ASAP7_ROOT:-}" && \
      -f "$ASAP7_ROOT/asap7_sram_0p0/generated/verilog/srambank_256x4x32_6t122.v" ]]; then
    macro_model="$ASAP7_ROOT/asap7_sram_0p0/generated/verilog/srambank_256x4x32_6t122.v"
else
    macro_model="$run_workspace_dir/sram_axi/genus/rtl/srambank_256x4x32_6t122.v"
fi

# Tag cache dung macro thu hai (512 x 20).  Ban sao nguyen van cua repo nam
# trong tests/models/, giong cach run_soc_sim.sh nap no.
tag_macro_model="$rtl_dir/tests/models/srambank_128x4x20_6t122.v"

for model in "$macro_model" "$tag_macro_model"; do
    if [[ ! -f "$model" ]]; then
        echo "Missing SRAM simulation model: $model" >&2
        exit 1
    fi
done

cd "$rtl_dir"
shopt -s globstar nullglob
# tests/ khong nam trong filelist tong hop: no chua model hanh vi cua hard macro
# (duoc truyen rieng qua $macro_model) va cac testbench.  Bo qua no o day de con
# so khop dung voi `find ... ! -path '*/tests/*'` ma run_soc_sim.sh va filelist
# cua Genus dung - neu khong, model bi nap hai lan va con so 55 khong bao gio
# dung.
rtl=()
for f in **/*.v; do
    case "$f" in
        tests/*) continue ;;
    esac
    rtl+=("$f")
done

if [[ "${#rtl[@]}" -ne 55 ]]; then
    echo "Expected 55 synthesizable Verilog files, found ${#rtl[@]}" >&2
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
    "$tag_macro_model" \
    "${rtl[@]}"

echo "MCU_RTL_LINT_PASS (${#rtl[@]} RTL files)"
