#!/usr/bin/env bash
# Trich phan cong suat cua hai file .lib SRAM ra reports/sram_lib_power.txt de
# commit len repo (file .lib that chi co tren may Linux).
#     cd Asap7/run_workspace/mcu/voltus && bash dump_sram_lib_power.sh
# Doi thu muc .lib:  SRAM_LIB_DIR=/duong/dan bash dump_sram_lib_power.sh
#
# Can biet: internal_power gan vao chan nao, co dieu kien 'when' theo
# ce / we / banksel khong, va hai kich thuoc macro co cung bang so khong.
set -u

lib_dir=${SRAM_LIB_DIR:-/home/user1/Desktop/asap7/asap7_sram_0p0/generated/LIB}
out_dir=$(cd "$(dirname "$0")" && pwd)/reports
out=$out_dir/sram_lib_power.txt
mkdir -p "$out_dir"

status=0
{
    for macro in 256x4x32 128x4x20; do
        lib=$lib_dir/srambank_${macro}_6t122.lib
        echo "##### $lib"
        if [ ! -s "$lib" ]; then
            echo "KHONG CO FILE (hoac file rong)"
            status=1
            continue
        fi
        echo "so dong: $(wc -l < "$lib")   kich thuoc: $(wc -c < "$lib") byte"

        echo "--- don vi, dien ap, leakage, ten cell"
        grep -n -E 'time_unit|voltage_unit|current_unit|leakage_power_unit|capacitive_load_unit|pulling_resistance_unit|nom_voltage|nom_temperature|cell_leakage_power|^[[:space:]]*cell[[:space:]]*\(|^[[:space:]]*area[[:space:]]*:|pg_pin|voltage_name' "$lib" | cut -c1-200 | head -40

        echo "--- so lan xuat hien"
        for key in internal_power leakage_power 'when[[:space:]]*:' related_pin related_pg_pin rise_power fall_power 'power[[:space:]]*\('; do
            printf '%-28s %s\n' "$key" "$(grep -c -E "$key" "$lib")"
        done

        echo "--- cac chan / bus"
        grep -n -E '^[[:space:]]*(pin|bus)[[:space:]]*\(' "$lib" | cut -c1-120 | head -60

        echo "--- cac dong when / related_pin / clock"
        grep -n -E 'when[[:space:]]*:|related_pin|related_pg_pin|clock[[:space:]]*:' "$lib" | cut -c1-200 | head -80

        echo "--- 12 khoi internal_power dau tien (moi khoi toi da 30 dong)"
        awk '
            /internal_power[[:space:]]*\(/ && !inside {
                if (++blocks > 12) exit
                inside = 1; depth = 0; shown = 0
                print "  [khoi " blocks ", dong " NR "]"
            }
            inside {
                if (shown++ < 30) print "  " substr($0, 1, 200)
                opened = gsub(/\{/, "{"); closed = gsub(/\}/, "}")
                depth += opened - closed
                if (depth <= 0 && (opened || closed)) inside = 0
            }
        ' "$lib"
        echo
    done
} > "$out"

echo "Da ghi $out ($(wc -l < "$out") dong)"
exit $status
