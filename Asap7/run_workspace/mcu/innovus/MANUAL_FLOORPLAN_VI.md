# Floorplan bằng tay cho `top_soc` (theo slide Hierarchy Layout + 10_Macro)

Flow này đi theo đúng các bước trong slide của thầy (ROHM 180 nm), nhưng lệnh và layer đã đổi sang ASAP7. Các con số lấy từ hai flow đã route sạch trong repo: `Risc_V/innovus` và `sram_axi/innovus`.

Mọi bước nằm trong **một file `tcl/innovus.tcl`**, chia thành KHỐI 0–8. Ở các chỗ `[LAM TAY]`, comment trong file ghi thao tác GUI kèm lệnh tương đương. File cũ `macro_floorplan.tcl` (xếp SRAM tự động) không còn được gọi.

## Chạy

Chạy trong thư mục `Asap7/run_workspace/mcu/innovus`, trên máy Linux có license.

**Cách 1 – làm tay, giống slide:** chạy `innovus`, rồi copy từng khối trong `tcl/innovus.tcl` paste vào console.

| Khối | Việc | Slide | Sau khối này |
|---|---|---|---|
| 0 | Nạp thiết kế, derate, dont_touch TRNG | | |
| 1 | `floorPlan` (kích thước lõi), `FloorPlan.fp`. Không chia vùng guide | Hierarchy tr. 24 | |
| 2 | **Ring lõi M8/M9** (chỉ bám mép lõi nên làm trước SRAM) | | tùy chọn: `soc_add_mesh` xem lưới rồi `editDelete -shape STRIPE` |
| 3 | Đặt sẵn 84 SRAM + halo (báo lỗi nếu còn stripe tạm) | tr. 31–32 | **LÀM TAY 1:** xếp SRAM, Space 4.32 |
| 4 | snap, kiểm tra, FIXED, `FloorPlan_withMacro.fp` | tr. 36 | |
| 5 | Lưới M4 ngang/M5 dọc riêng từng cụm SRAM + tap M5 mỗi SRAM (cụm tính theo vị trí thật) | tr. 37–40 | **LÀM TAY 2 (tùy chọn):** xem lưới |
| 6 | Lưới M7/M6 toàn chip | tr. 41 | |
| 7 | Blockage + pin | tr. 38, 9–10 | tùy chọn: đổi cạnh pin |
| 8 | verify + `saved/top_soc_powerplan.enc` | | |

Thứ tự power theo slide: ring lõi làm trước; block ring và stripe chỉ làm sau khi SRAM đã FIXED. Slide trang 32 cũng chỉ vẽ ring + stripe tạm để tạo PG model, rồi xóa đi trước khi đặt macro.

Mỗi khối (trừ khối 0) được bọc trong `soc_block`: một lệnh lỗi thì cả khối dừng, không chạy tiếp các lệnh phía sau. Cuối file có hướng dẫn chạy lại từ giữa trong session mới, bằng `loadFPlan FloorPlan.fp` hoặc `FloorPlan_withMacro.fp`.

### Một session Innovus = một lần chạy

**Không bao giờ paste lại KHỐI 0 (hoặc KHỐI 1) vào session đang giữ thiết kế cũ.**
`init_design` khi đã có thiết kế trong RAM chỉ in ra
`**ERROR: (IMPSYT-7329): ... This command is skipped.` — đó là message của Innovus,
không phải lỗi Tcl, nên script vẫn chạy tiếp và đổ cả flow lên thiết kế cũ.
Đúng lỗi này đã làm hai lần chạy ngày 2026-09-21 ra 407 181 và 500 000 vi phạm DRC:
diện tích std cell bị đếm cả buffer CTS + filler của lần trước
(300 143 → 1 325 493 → 3 675 242 um²) nên lõi cao 1412.6 → 2459.2 → 6162.5 um, rồi
`floorPlan -s` vẽ lại row/track ngay dưới dây đã route.

Từ 2026-09-21 có ba lớp chặn:

- `tcl/init_common.tcl` dừng ngay nếu `dbGet top.name` đã có thiết kế, và kiểm lại
  sau `init_design` xem còn cell `CTS_`/`FILLER`/`WELLTAP`, stripe, rail hay cell đã đặt không.
- `soc_require_fresh_design` chặn KHỐI 1 nếu thiết kế đã P&R.
- KHỐI 8 và KHỐI 10 nay **chặn** khi `drc_powerplan.rpt` / `drc_place.rpt` còn vi phạm
  (trước đây chỉ in ra con số rồi chạy tiếp).

Chạy lại đúng cách:

- Từ đầu: `exit` Innovus, mở lại, paste KHỐI 0.
- Từ giữa: `restoreDesign ./saved/<checkpoint>.enc.dat top_soc`, rồi
  `source ./tcl/manual/soc_fp_config.tcl` và `source ./tcl/manual/soc_fp_procs.tcl`,
  rồi paste đúng khối cần chạy (**không** paste KHỐI 0/1).

### Cờ "flow đang hỏng"

Một khối lỗi sẽ đặt cờ `SOC_FLOW_BROKEN`; mọi khối sau đó từ chối chạy cho đến khi gõ
`soc_flow_ok`. Trước đây `soc_block` chỉ dừng được khối đang chạy: ngày 2026-09-21
KHỐI 10 lỗi 1826 VDD/VSS nhưng KHỐI 11–15 vẫn được paste tiếp và chạy thêm 3 tiếng
trên thiết kế đã hỏng.

**Cách 2 – chạy một mạch** (không chỉnh tay, dùng vị trí mầm): `innovus -files tcl/innovus.tcl`

Các biến môi trường điều khiển flow:

- **`MCU_CORE_WIDTH_UM` / `MCU_CORE_HEIGHT_UM`:** ép kích thước lõi.
- **`MCU_TARGET_STD_UTIL`:** mặc định 0.55.

Muốn đổi nhóm SRAM, khe, halo hay layer ring thì sửa `tcl/manual/soc_fp_config.tcl`. Đổi cạnh pin thì sửa `tcl/manual/soc_pins.tcl`.

## Slide ROHM → ASAP7

| Slide | Ở đây | Lý do |
|---|---|---|
| Gap SRAM 20.16 um (4 row) | 4.32 um (4 row × 1.08) | Cùng quy tắc 4 row |
| `addRing -around shared_cluster`, M5/M4 rộng 1.92 | `addStripe -area` từng kênh: M4 ngang ở mép và khe giữa hàng, M5 dọc ở mép và khe giữa cột, rộng 0.096 (`soc_island_pg`) | addRing bao cả 84 SRAM và chỉ ra cạnh dọc (2026-09-16). Cách addStripe lấy từ sram_axi đã route sạch |
| Stripe M4/M5 1.92 | Lưới M7 dọc / M6 ngang, 0.64, pitch 34.56 | Lấy từ Risc_V |
| Không có ring lõi riêng | Ring lõi M8/M9 0.48 | Lấy từ Risc_V |
| `sroute -connect blockPin` | Tap M5 ở cạnh phải mỗi SRAM, nối chân M4 xuống khe | sram_axi: nearestTarget nối bừa và để hở hàng dưới |
| `refine_macro_place` | Snap tọa độ về lưới site/row | `refine` có thể dời macro vừa xếp bằng tay |
| `sroute -connect corePin` trước placement | Để sau placement (`soc_stdcell_rails`) | Risc_V bị short VDD/VSS khi làm trước |
| `createGuide` / `proto_design` (chia vùng module) | Bỏ, placer tự kéo std cell lại gần SRAM | SoC nhỏ; guide mầm đã quá dày (cache ~190%) |
| Pin `-layer 2/3` | M6 (trái/phải), M7 (trên/dưới), 0.128 × 0.288 | Lấy từ Risc_V |

## Những việc SoC này cần mà ví dụ RISC-V trong slide không có

1. **Hai loại SRAM** (80 × 256x4x32 và 4 × 128x4x20) chia thành 4 cụm: RAM_LO, RAM_HI, CACHE (cache + TCM) và TAG.
   - `soc_check_groups` bắt lỗi khi một macro thiếu nhóm hoặc nằm ở hai nhóm.
   - Mỗi cụm có block ring riêng.
2. **Derate SRAM** (`set_timing_derate` SS/FF) phải khớp với Genus. Phần này nằm trong `tcl/init_common.tcl` (KHỐI 0).
3. **`set_max_fanout 1` trên output SRAM** (slide Hierarchy trang 36). Phần này cũng nằm trong `init_common.tcl`.
4. **15 clock** (CLK_SYS, TCK, SDRAM_OUT + 12 gated). Script kiểm tra đủ 15; flow cũ đòi ≥ 18 nên sẽ báo lỗi với netlist hiện tại.
5. **TRNG ring oscillator** (7 cell) cần `set_dont_touch` trong Innovus. Nếu thiếu, optDesign có thể resize hoặc chèn buffer vào vòng. Nên đặt 7 cell này sát nhau, cạnh `u_apb_ascon_u_ascon`.
6. **174 pin top-level:** trái 22 (clock, reset, JTAG, flash), trên 96 (GPIO), phải 56 (SDRAM), dưới để trống vì cụm CACHE/TAG nằm sát mép dưới. `soc_pins.tcl` báo lỗi nếu netlist và danh sách pin lệch nhau.

## Bố cục mầm (chỉ là điểm xuất phát)

```
+----------------------------------------------------------------+
| RAM_LO |                                              | RAM_HI |
| 4 x 8  |      vùng logic (placer tự đặt std cell)     | 4 x 8  |
|        |                                              |        |
|        |  CACHE 8 x 2 (icache/dcache/itcm/dtcm) | TAG |        |
+----------------------------------------------------------------+
lõi khoảng 2211 x 1433 um (tính với 300k um² std cell, util 0.55)
```

Mật độ tổng thể thấp vì hai bức tường RAM cao 1413 um quyết định chiều cao lõi. Đây là chỗ đáng tự tối ưu nhất, ví dụ đổi RAM thành 8 cột × 4 hàng hoặc xếp lại các cụm.

## Kiểm tra đã làm / chưa làm

- **Đã làm** (bằng `tclsh` trên Windows):
  - Tất cả file đúng cú pháp.
  - Danh sách pin khớp 174 port của `top_soc_syn.v`.
  - Trên DB giả lập với kích thước LEF thật, mầm đặt đủ 84 macro, 0 lỗi.
  - Negative control: SRAM đặt cách nhau 0.82 um bị báo lỗi, xoay R90 bị báo lỗi.
- **Chưa chạy trên Innovus.** Các điểm cần xem kỹ ở lần chạy đầu:
  - `sroute -blockPinTarget blockring`.
  - `createPlaceBlockage -allMacro -outerRingBySide`.
  - DRC của block ring M4/M5 trong khe 4.32 um.
  - Kết nối SRAM trong `verify_rpt/connectivity_powerplan.rpt`.
