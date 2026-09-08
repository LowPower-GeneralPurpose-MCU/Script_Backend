#!/usr/bin/env bash
# Chay hai testbench muc SoC bang Vivado XSim.
#
#   ./run_soc_sim.sh apb    - SoC_testbench.sv : quet thanh ghi APB cua ngoai vi
#   ./run_soc_sim.sh fw     - tb_top_soc.v     : chay firmware that qua CPU
#   ./run_soc_sim.sh mem    - tb_mem_paths.sv  : RAM hi / TCM / DMA / store MMIO
#   ./run_soc_sim.sh all    - ca ba (mac dinh)
#
# Bien moi truong ghi de duoc:
#   XSIM_BIN   thu muc bin cua Vivado  (mac dinh: /d/Xilinx/Vivado/2024.1/bin)
#   FW_MEM     anh firmware cho che do fw
#   OUT_DIR    thu muc lam viec        (mac dinh: ./sim_work)
#   SAIF=1     che do fw ghi them sim_work/fw.saif de Genus annotate power
#              (chay Genus voi MCU_SAIF=<duong dan toi file do>).  Mac dinh tat
#              vi no lam cham lan chay dang ke.
set -euo pipefail

# Cac binary cua Vivado la chuong trinh Windows: chung khong hieu duong dan kieu
# MSYS (/d/...).  `winpath` doi sang dang o dia khi dang chay duoi Git Bash, va
# la ham dong nhat o moi noi khac.
if command -v cygpath >/dev/null 2>&1; then
    winpath() { cygpath -m "$1"; }
else
    winpath() { printf '%s' "$1"; }
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL="$(winpath "$(cd "$HERE/.." && pwd)")"
REPO="$(winpath "$(cd "$HERE/../../../../../../.." && pwd)")"   # .../MCU_LowPower_GeneralPurpose
HERE="$(winpath "$HERE")"

XSIM_BIN="${XSIM_BIN:-/d/Xilinx/Vivado/2024.1/bin}"
OUT_DIR="$(winpath "${OUT_DIR:-$HERE/sim_work}")"
FW_MEM="$(winpath "${FW_MEM:-$REPO/Driver/my_soc_firmware_word.mem}")"
APB_TB="$REPO/Test_bench/SoC_testbench.sv"
MEM_TB="$HERE/tb_mem_paths.sv"
FW_TB="$REPO/Driver/tb_top_soc.v"
MODE="${1:-all}"
SAIF="${SAIF:-0}"

export PATH="$XSIM_BIN:$PATH"
command -v xvlog.bat >/dev/null 2>&1 || { echo "khong tim thay xvlog trong $XSIM_BIN"; exit 1; }

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# Danh sach RTL: moi .v duoi rtl/ TRU cac ban sao luu, cong them mo hinh hanh vi
# cua macro SRAM (trong luong that no la hard macro doc tu .lib/.lef).
find "$RTL" -name '*.v' ! -path '*/core.bak*' ! -path '*/tests/*' | sort > rtl_files.f
echo "$RTL/tests/models/srambank_256x4x32_6t122.v" >> rtl_files.f

INC=(-i "$RTL" -i "$RTL/interrupt/CLINT" -i "$RTL/interrupt/dma" -i "$RTL/interrupt/plic" -i "$RTL/memory")

run_apb() {
    echo "=== APB peripheral testbench ==="
    xvlog.bat -sv -work apb "${INC[@]}" -f rtl_files.f "$APB_TB" > xvlog_apb.log
    xelab.bat -relax -s apb_sim -timescale 1ns/1ps apb.SoC_testbench -L apb > xelab_apb.log
    printf 'run all\nquit\n' > run.tcl
    xsim.bat apb_sim -tclbatch run.tcl | tee xsim_apb.log
    grep -E 'PASS COUNT|FAIL COUNT|RESULT' xsim_apb.log || true
}

run_fw() {
    echo "=== firmware testbench (ROM = $FW_MEM) ==="
    # ROM la bang case tong hop duoc, khong nap duoc luc chay -> bake truoc va
    # cho thu muc nay len TRUOC rtl/ tren duong dan include.
    python "$HERE/gen_boot_rom.py" "$FW_MEM" "$OUT_DIR/fw_inc"
    xvlog.bat -sv -work fw -i "$OUT_DIR/fw_inc" "${INC[@]}" -f rtl_files.f "$FW_TB" > xvlog_fw.log
    # log_saif doi netlist co thong tin trace, nen SAIF=1 phai elaborate voi
    # -debug typical.  Chay cham hon nhieu - do la ly do no khong bat mac dinh.
    XELAB_DEBUG=""
    if [ "$SAIF" = "1" ]; then XELAB_DEBUG="-debug typical"; fi
    xelab.bat -relax $XELAB_DEBUG -s fw_sim -timescale 1ns/1ps fw.tb_top_soc -L fw > xelab_fw.log
    if [ "$SAIF" = "1" ]; then
        # Toggle count cho Genus: khong co no thi report_power ap toggle rate
        # mac dinh len ca 84 macro SRAM cung luc, ra con so cao gap hang chuc lan.
        printf 'open_saif "fw.saif"\nlog_saif [get_objects -r /tb_top_soc/*]\nrun all\nclose_saif\nquit\n' > run.tcl
    else
        printf 'run all\nquit\n' > run.tcl
    fi
    xsim.bat fw_sim -tclbatch run.tcl > xsim_fw.log
    if [ "$SAIF" = "1" ]; then
        if [ -s fw.saif ]; then
            echo "SAIF: $OUT_DIR/fw.saif ($(wc -c < fw.saif) byte) -> chay Genus voi MCU_SAIF tro toi file nay"
        else
            echo "SAIF: KHONG sinh duoc fw.saif, xem xsim_fw.log"
        fi
    fi
    grep -E '\[TB\]\[PASS\]|\[TB\]\[FAIL\]|SIMULATION' xsim_fw.log || true
    # `|| true` la BAT BUOC: voi set -euo pipefail, mot lan chay khong in duoc
    # ky tu UART nao lam grep tra 1 -> ca script THOAT, va run_mem khong bao gio
    # chay. Tuc la mot regression o fw se GIAU luon ket qua cua mem.
    printf 'UART: '; { grep -o 'char=.' xsim_fw.log || true; } | sed 's/char=//' | tr -d '\n'; echo
}

run_mem() {
    echo "=== memory-path testbench ==="
    xvlog.bat -sv -work mem "${INC[@]}" -f rtl_files.f "$MEM_TB" > xvlog_mem.log
    xelab.bat -relax -s mem_sim -timescale 1ns/1ps mem.tb_mem_paths -L mem > xelab_mem.log
    printf 'run all
quit
' > run.tcl
    xsim.bat mem_sim -tclbatch run.tcl > xsim_mem.log
    grep -E '^\[FAIL\]|^\[INFO\]|PASS COUNT|FAIL COUNT|TIMEOUTS|RESULT' xsim_mem.log || true
}

case "$MODE" in
    apb) run_apb ;;
    fw)  run_fw ;;
    mem) run_mem ;;
    all) run_apb; run_fw; run_mem ;;
    *)   echo "cach dung: $0 [apb|fw|mem|all]"; exit 1 ;;
esac
