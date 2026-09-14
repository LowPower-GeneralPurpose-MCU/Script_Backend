# Floorplan bằng tay cho `top_soc` (theo slide Hierarchy Layout + 10_Macro)

Flow này đi theo đúng các bước trong slide của thầy (ROHM 180 nm), nhưng lệnh và layer đã đổi sang ASAP7. Các con số lấy từ hai flow đã route sạch trong repo: `Risc_V/innovus` và `sram_axi/innovus`.

Flow tự động cũ (`tcl/innovus.tcl` + `macro_floorplan.tcl`) vẫn giữ nguyên. Cả hai flow dùng chung `tcl/init_common.tcl`.

## Chạy

Mọi lệnh chạy trong thư mục `Asap7/run_workspace/mcu/innovus`, trên máy Linux có license.

| Bước | Slide | Mở session | Sau khi chỉnh GUI, gõ trong console Innovus |
|---|---|---|---|
| 1. Hierarchy FP | Hierarchy tr. 24–29 | `innovus -files tcl/manual/01_hierFP.tcl` | `source tcl/manual/01_finish_hierFP.tcl` |
| 2. Đặt SRAM | Hierarchy tr. 31–36, Macro tr. 7–14 | `innovus -files tcl/manual/02_planning.tcl` | `source tcl/manual/02_finish_planning.tcl` |
| 3. Power grid + pin | Hierarchy tr. 37–41, 9–10 | `innovus -files tcl/manual/03_powerGrid.tcl` | tự chạy hết; muốn dừng sau ring thì đặt `MCU_STOP_AFTER_RINGS=1` |

Mỗi bước sinh ra các file sau:

- **Bước 1:** `outputs/FloorPlan.fp`, `saved/top_soc_hierFP.enc`, `reports/guide_util_hierFP*.rpt`
- **Bước 2:** `outputs/FloorPlan_withMacro.fp`, `saved/top_soc_macroFP.enc`, `reports/sram_macro_check*.rpt`
- **Bước 3:** `saved/top_soc_powerplan.enc`, `verify_rpt/connectivity_powerplan.rpt`, `verify_rpt/drc_powerplan.rpt`

Các biến môi trường điều khiển flow:

- **`MCU_CORE_WIDTH_UM` / `MCU_CORE_HEIGHT_UM`:** ép kích thước lõi.
- **`MCU_TARGET_STD_UTIL`:** mặc định 0.55.
- **`MCU_RUN_PROTO_DESIGN=1`:** dùng `proto_design` như slide. Cần license `invs_ehfs`, flow Risc_V báo không có.
- **`MCU_REUSE_MACRO_FP=1`:** ở bước 2, nạp lại `FloorPlan_withMacro.fp` đã duyệt thay vì đặt mầm mới.
- **`MCU_RAILS_BEFORE_PLACE=1`:** làm rail M1 và stripe M5 ngay ở bước 3, như slide.

Muốn đổi nhóm SRAM, guide, khe, halo hay layer ring thì chỉ sửa `tcl/manual/soc_fp_config.tcl`.

## Slide ROHM → ASAP7

| Slide | Ở đây | Lý do |
|---|---|---|
| Gap SRAM 20.16 um (4 row) | 4.32 um (4 row × 1.08) | Cùng quy tắc 4 row |
| `addRing -around shared_cluster`, M5/M4 rộng 1.92 | Cùng lệnh, M4 ngang / M5 dọc, rộng 0.096 | Đây là độ rộng một track hợp lệ trên M4/M5. Strap thấp rộng hơn đã gây short ở Risc_V |
| Stripe M4/M5 1.92 | Lưới M7 dọc / M6 ngang, 0.64, pitch 34.56 | Lấy từ Risc_V |
| Không có ring lõi riêng | Ring lõi M8/M9 0.48 | Lấy từ Risc_V |
| `sroute -blockPinTarget nearestTarget` | `blockring` (biến `SOC_BLOCKPIN_TARGET`) | sram_axi đã phải tắt `nearestTarget` |
| `refine_macro_place` | Snap tọa độ về lưới site/row | `refine` có thể dời macro vừa xếp bằng tay |
| `sroute -connect corePin` trước placement | Để sau placement (`soc_stdcell_rails`) | Risc_V bị short VDD/VSS khi làm trước |
| `proto_design` | Guide mầm tính từ diện tích module | Không có license EHFS |
| Pin `-layer 2/3` | M6 (trái/phải), M7 (trên/dưới), 0.128 × 0.288 | Lấy từ Risc_V |

## Những việc SoC này cần mà ví dụ RISC-V trong slide không có

1. **Hai loại SRAM** (80 × 256x4x32 và 4 × 128x4x20) chia thành 4 cụm: RAM_LO, RAM_HI, CACHE (cache + TCM) và TAG.
   - `soc_check_groups` bắt lỗi khi một macro thiếu nhóm hoặc nằm ở hai nhóm.
   - Mỗi cụm có block ring riêng.
2. **Derate SRAM** (`set_timing_derate` SS/FF) phải khớp với Genus. Phần này nằm trong `init_common.tcl`.
3. **`set_max_fanout 1` trên output SRAM** (slide Hierarchy trang 36). Phần này cũng nằm trong `init_common.tcl`.
4. **15 clock** (CLK_SYS, TCK, SDRAM_OUT + 12 gated). Script kiểm tra đủ 15; flow cũ đòi ≥ 18 nên sẽ báo lỗi với netlist hiện tại.
5. **TRNG ring oscillator** (7 cell) cần `set_dont_touch` trong Innovus. Nếu thiếu, optDesign có thể resize hoặc chèn buffer vào vòng. Nên đặt 7 cell này sát nhau, cạnh `u_apb_ascon_u_ascon`.
6. **174 pin top-level:** trái 22 (clock, reset, JTAG, flash), trên 96 (GPIO), phải 56 (SDRAM), dưới để trống vì cụm CACHE/TAG nằm sát mép dưới. `soc_pins.tcl` báo lỗi nếu netlist và danh sách pin lệch nhau.

## Bố cục mầm (chỉ là điểm xuất phát)

```
+----------------------------------------------------------------+
| RAM_LO |               DMA guide                      | RAM_HI |
| 4 x 8  |         u_axi_interconnect guide             | 4 x 8  |
|        |    u_icache | u_core | u_dcache   (guide)     |        |
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
  - Thuộc tính `top.fPlan.guides` (.name có phải tên instance không).
  - `sroute -blockPinTarget blockring`.
  - `createPlaceBlockage -allMacro -outerRingBySide`.
  - DRC của block ring M4/M5 trong khe 4.32 um.
  - Kết nối SRAM trong `verify_rpt/connectivity_powerplan.rpt`.
