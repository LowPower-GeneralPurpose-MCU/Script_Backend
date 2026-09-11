#!/usr/bin/env bash
# Chay hai testbench muc SoC bang Vivado XSim.
#
#   ./run_soc_sim.sh apb    - SoC_testbench.sv : quet thanh ghi APB cua ngoai vi
#   ./run_soc_sim.sh fw     - tb_top_soc.v     : chay firmware that qua CPU
#   ./run_soc_sim.sh mem    - tb_mem_paths.sv  : RAM hi / TCM / DMA / store MMIO
#   ./run_soc_sim.sh ascon  - tb_ascon_apb.sv  : KAT ASCON-128 / ASCON-Hash qua APB
#   ./run_soc_sim.sh core   - tb_core_jalr.sv  : R13/R14 bang CPU that (anh ROM
#                             tests/core_jalr.mem, viet tay)
#   ./run_soc_sim.sh sys    - tb_sys_ctrl.sv   : WFI + haltreq, RST_CAUSE,
#                             SW_RESET, RESET_VECTOR giu lai, khoa debug (anh ROM
#                             tests/sys_ctrl.mem, sinh boi gen_sys_ctrl_mem.py)
#   ./run_soc_sim.sh irq    - tb_irq_pmp.sv    : PMP + CLIC bang CPU that (anh ROM
#                             tests/irq_pmp.mem, sinh boi gen_irq_pmp_mem.py)
#   ./run_soc_sim.sh per    - tb_periph.sv     : pinmux, UART1, TIM0/TIM1, ID CLIC
#   ./run_soc_sim.sh all    - tat ca (mac dinh)
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
ASCON_TB="$HERE/tb_ascon_apb.sv"
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
echo "$RTL/tests/models/srambank_128x4x20_6t122.v" >> rtl_files.f   # tag cache

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
    # R13 - monitor trong core/riscv_pipeline.v: moi lenh duong sai sau JALR ma
    # ban R2 cu da de chay. [R13][FAIL] nghia la flush_ex_mem lai thieu term.
    # Monitor in 32 lan dau roi chi in o #64, #128, ... nen dong cuoi mang so dem.
    { grep -E '^\[R13\]' xsim_fw.log || true; } | head -n 8
    printf 'R13 (dong cuoi): '; { grep -E '^\[R13\]' xsim_fw.log || echo 'khong co'; } | tail -n 1
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

run_core() {
    echo "=== core testbench: R13 / R14 (ROM = tests/core_jalr.mem) ==="
    # Cung co che voi run_fw: anh ROM la bang case, bake truoc vao mot thu muc
    # include rieng dat TRUOC rtl/.
    python "$HERE/gen_boot_rom.py" "$HERE/core_jalr.mem" "$OUT_DIR/core_inc"
    xvlog.bat -sv -work core -i "$OUT_DIR/core_inc" "${INC[@]}" -f rtl_files.f "$HERE/tb_core_jalr.sv" > xvlog_core.log
    xelab.bat -relax -s core_sim -timescale 1ns/1ps core.tb_core_jalr -L core > xelab_core.log
    printf 'run all\nquit\n' > run.tcl
    xsim.bat core_sim -tclbatch run.tcl > xsim_core.log
    grep -E '\[TB\]|^\[R13\]|PASS COUNT|RESULT' xsim_core.log || true
}

run_ascon() {
    echo "=== ASCON KAT testbench ==="
    xvlog.bat -sv -work asc "${INC[@]}" -f rtl_files.f "$ASCON_TB" > xvlog_ascon.log
    xelab.bat -relax -s ascon_sim -timescale 1ns/1ps asc.tb_ascon_apb -L asc > xelab_ascon.log
    printf 'run all
quit
' > run.tcl
    xsim.bat ascon_sim -tclbatch run.tcl > xsim_ascon.log
    grep -E '^\[TB\]\[FAIL\]|PASS COUNT|FAIL COUNT|RESULT' xsim_ascon.log || true
}

run_sys() {
    echo "=== sys testbench: SYSCON / Debug Module / WFI (ROM = tests/sys_ctrl.mem) ==="
    python "$HERE/gen_sys_ctrl_mem.py" > /dev/null
    python "$HERE/gen_boot_rom.py" "$HERE/sys_ctrl.mem" "$OUT_DIR/sys_inc"
    xvlog.bat -sv -work sys -i "$OUT_DIR/sys_inc" "${INC[@]}" -f rtl_files.f "$HERE/tb_sys_ctrl.sv" > xvlog_sys.log
    xelab.bat -relax -s sys_sim -timescale 1ns/1ps sys.tb_sys_ctrl -L sys > xelab_sys.log
    printf 'run all
quit
' > run.tcl
    xsim.bat sys_sim -tclbatch run.tcl > xsim_sys.log
    grep -E '\[TB\]|PASS COUNT|RESULT' xsim_sys.log || true
}

run_irq() {
    echo "=== irq testbench: PMP + CLIC (ROM = tests/irq_pmp.mem) ==="
    python "$HERE/gen_irq_pmp_mem.py" > /dev/null
    python "$HERE/gen_boot_rom.py" "$HERE/irq_pmp.mem" "$OUT_DIR/irq_inc"
    xvlog.bat -sv -work irq -i "$OUT_DIR/irq_inc" "${INC[@]}" -f rtl_files.f "$HERE/tb_irq_pmp.sv" > xvlog_irq.log
    xelab.bat -relax -s irq_sim -timescale 1ns/1ps irq.tb_irq_pmp -L irq > xelab_irq.log
    printf 'run all\nquit\n' > run.tcl
    xsim.bat irq_sim -tclbatch run.tcl > xsim_irq.log
    grep -E '\[TB\]|PASS COUNT|RESULT' xsim_irq.log || true
}

run_per() {
    echo "=== peripheral testbench: pinmux / UART1 / TIM0-1 / CLIC ID ==="
    xvlog.bat -sv -work per "${INC[@]}" -f rtl_files.f "$HERE/tb_periph.sv" > xvlog_per.log
    xelab.bat -relax -s per_sim -timescale 1ns/1ps per.tb_periph -L per > xelab_per.log
    printf 'run all\nquit\n' > run.tcl
    xsim.bat per_sim -tclbatch run.tcl > xsim_per.log
    grep -E '\[TB\]|PASS COUNT|RESULT' xsim_per.log || true
}

case "$MODE" in
    apb)   run_apb ;;
    fw)    run_fw ;;
    mem)   run_mem ;;
    ascon) run_ascon ;;
    core)  run_core ;;
    sys)   run_sys ;;
    irq)   run_irq ;;
    per)   run_per ;;
    all)   run_apb; run_fw; run_mem; run_ascon; run_core; run_sys; run_irq; run_per ;;
    *)     echo "cach dung: $0 [apb|fw|mem|ascon|core|sys|irq|per|all]"; exit 1 ;;
esac
