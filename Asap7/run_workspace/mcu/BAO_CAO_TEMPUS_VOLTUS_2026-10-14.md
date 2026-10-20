# Báo cáo kết quả signoff: Tempus (STA) và Voltus (công suất, sụt áp)

Thiết kế `top_soc` (MCU RISC-V), thư viện ASAP7 7 nm, tỉ lệ 1x, clock hệ thống 250 MHz (4 ns).
Số liệu lấy từ lần chạy đêm 2026-10-14, trên netlist **sau ECO**.

> Bản nháp. Mọi con số có ghi file nguồn ở Phụ lục A. Phần "Cần xác nhận" ở mục 5 phải kiểm trước khi trình bày.

---

## 0. Tóm tắt

| Hạng mục | Kết quả | Kết luận |
|---|---|---|
| Setup (view_ss / view_tt) | WNS +0,248 / +0,378 ns, 0 vi phạm | Đạt |
| Hold (view_ff / view_tt) | WNS +0,015 / +0,037 ns, 0 vi phạm | Đạt, biên ở FF mỏng |
| Ký sinh | 146 551 / 146 551 net thật có RC | Đạt |
| max_transition | 1 net (2 chân), 0,283 ns > 0,150 ns | **Còn 1 vi phạm** |
| max_capacitance | 0 | Đạt |
| Nhiễu glitch (SI) | 54 / 62 / 290 vi phạm DC tolerance (ss / tt / ff) | **Chưa xử lý** |
| Công suất (TT, vectorless) | 87,92 mW, SRAM chiếm 93,9 % | Cận trên |
| Sụt áp tĩnh VDD | thấp nhất 0,684 V (sụt 16,0 mV = 2,3 %) | Đạt (ngưỡng 50 mV) |
| Nảy đất VSS | cao nhất 15,8 mV (2,3 %) | Đạt (ngưỡng 50 mV) |
| Lưới nguồn | 0 nguồn dòng / nút / đoạn dây bị hở | Đạt |

---

## 1. Bối cảnh và đầu vào

Thứ tự chuỗi signoff, mỗi bước dùng đầu ra của bước trước:

```
Innovus (PnR) -> ECO (sửa DRV) -> Conformal LEC -> Quantus (trích RC) -> Tempus -> Voltus
```

| Đầu vào | File | Thời điểm |
|---|---|---|
| Netlist sau ECO | `innovus/outputs/top_soc_pnr.v` | 10-14 01:18 |
| DEF | `innovus/outputs/top_soc_pnr.def` | sau ECO |
| SPEF (3 góc RC) | `quantus/outputs/top_soc_quantus_rc_{ss,typ,ff}.spef` | 10-14 01:35 |
| SDC | xuất từ Innovus, bỏ 4 dòng source latency trên clock sinh `CLK_SDRAM_OUT` | — |

SPEF mới hơn netlist, nên RC khớp với netlist đang phân tích (Tempus có cổng kiểm việc này).

---

## 2. Tempus — phân tích thời gian tĩnh

Cadence Tempus 23.15-s108_1, 1 CPU, `update_timing` + báo cáo 167 s, chạy 10-14 01:37 – 01:41.

### 2.1 Thiết lập

| View | Thư viện / điện áp | Góc RC / nhiệt độ | Dùng cho |
|---|---|---|---|
| `view_ss` | SS, 0,63 V | rc_ss, 100 °C | setup |
| `view_tt` | TT, 0,70 V | rc_typ, 25 °C | setup + hold |
| `view_ff` | FF, 0,77 V | rc_ff, 0 °C | hold |

- Tính trễ có SI (`set_delay_cal_mode -siAware true`), bật báo cáo glitch.
- OCV + CPPR. Derate OCV chung cho std cell = 1,0 (late) / 1,0 (early).
- Derate riêng: SRAM (84 macro) ×1,30 late ở SS, ×0,75 early ở FF; 56 cell của lib FF `SIMPLE_RVT` ×0,85 early (xem mục 4).

### 2.2 Kết quả timing

| Kiểm tra | View | WNS (ns) | TNS (ns) | Số endpoint vi phạm |
|---|---|---|---|---|
| Setup | view_ss | **+0,248** | 0 | 0 |
| Setup | view_tt | +0,378 | 0 | 0 |
| Hold | view_ff | **+0,015** | 0 | 0 |
| Hold | view_tt | +0,037 | 0 | 0 |

Đường xấu nhất:

| | Đường | Clock |
|---|---|---|
| Setup SS | `u_core/pc_reg_reg[2]` → `u_core/pc_reg_reg[20]`; đến 3,729 ns, yêu cầu 3,977 ns (uncertainty 0,150, CPPR +0,050) | CLK_CPU |
| Setup TT | `u_axi_sdram_cmd_reg_reg[0]` → cổng ra `sdram_we_n` (external delay) | CLK_SDRAM_OUT |
| Hold FF | `u_axi_to_apb_r_addr_reg_reg[15]` → `u_axi_to_apb_u_cmd_fifo_mem_reg[0][54]` | CLK_SYS |

Trong 100 đường setup SS xấu nhất: 63 thuộc CLK_CPU (đường tính PC của lõi), 37 thuộc CLK_SDRAM_OUT (giao tiếp SDRAM).
Biên setup SS 248 ps là 6,2 % chu kỳ.

### 2.3 Ký sinh

| Loại net | Số lượng | Có RC |
|---|---|---|
| Net thật (đầy đủ) | 146 551 | 146 551 (100 %) |
| Net thật bị đứt | 0 | — |
| Net 0 chân (floating) | 14 871 | 0 — không bao giờ được tính timing |
| Net 1 chân (không tải) | 434 | 0 — không bao giờ được tính timing |

Tổng C 152,86 pF, C ghép 38,94 pF.

### 2.4 Luật thiết kế (DRV)

| Kiểm tra | Số vi phạm | Chi tiết |
|---|---|---|
| max_transition | 2 chân trên 1 net | `cg_cpu/g16__6260/B` và chân lái `cg_cpu/FE_ECOC31901_CTS_1/Y`: 0,283 ns > 0,150 ns (−0,133 ns), view_ss. Nằm trên đường clock của cổng clock-gating CPU |
| max_capacitance | 0 | |
| pulse_width, min_period | 0 | |
| max_fanout | 619 chân | Giới hạn `set_max_fanout 20` cho cả thiết kế (SDC); chủ yếu là buffer CTS, ví dụ `u_icache/CTS_ccl_a_buf_00711` fanout 53. Không phải ràng buộc vật lý; transition và tải của các chân này đều đạt |

### 2.5 Nhiễu ghép (glitch)

Ngưỡng báo cáo 10 % VDD.

| View | VDD | Vi phạm DC tolerance | Net có vấn đề | Đỉnh lớn nhất |
|---|---|---|---|---|
| ss | 0,63 V | 54 | 48 | 377,6 mV |
| tt | 0,70 V | 62 | 62 | 440,1 mV |
| ff | 0,77 V | 290 | 290 | 514,9 mV |

Net nạn nhân xấu nhất ở cả ba góc là `u_dcache/tag_out_bus[8]` (đầu ra SRAM tag của D-cache). Net xấu thứ hai ở FF là `u_itcm/u_mem/bank_rdata[0][4]` (đầu ra SRAM ITCM).
Không có vi phạm "receiver output peak", tức chưa thấy glitch lan qua cổng nhận.
Flow hiện chưa dùng glitch làm điều kiện PASS/FAIL.

### 2.6 Độ phủ kiểm tra

| Loại kiểm tra | Tổng | Đạt | Không kiểm |
|---|---|---|---|
| Setup | 37 918 | 37 909 | 9 |
| Hold | 37 930 | 37 816 | 114 |
| Clock gating setup / hold | 12 / 12 | 12 / 12 | 0 |
| Recovery / Removal | 27 834 | 13 806 | 14 028 |
| Library clock gating (ICG) | 3 246 | 1 623 | 1 623 |

`check_timing`: 47 112 cảnh báo `uncons_endpoint` cộng trên 3 view. Mỗi view gồm 13 533 chân `RESETN` + 495 chân `SETN` + 1 623 chân `SE` của ICG, còn lại khoảng 20 chân. 13 533 + 495 = 14 028, bằng đúng số recovery/removal không kiểm.
SDC có `set_false_path -from [get_ports {rst_n trst_n}]`.

---

## 3. Voltus — công suất và sụt áp

Cadence Voltus 23.15-s108_1, 1 CPU, 955 s, chạy 10-14 01:56 – 02:13. `set_design_mode -process 7` (log ghi `Design Mode: 7nm`).

### 3.1 Thiết lập

- Góc TT, 0,7 V, 25 °C; SPEF `rc_typ`.
- Phân tích tĩnh, không có VCD: activity mặc định, chân vào 0,2, clock 250 MHz. Kết quả là **cận trên**.
- Cấp nguồn từ chân PG trên cả 4 cạnh ring: 182 nguồn áp mỗi net, bước 10 µm.
- Ngưỡng: VDD ≥ 0,65 V, VSS ≤ 0,05 V (50 mV mỗi net, khoảng 7 % VDD).

### 3.2 Công suất

| Nhóm | Internal | Switching | Leakage | Tổng (mW) | % |
|---|---|---|---|---|---|
| Macro (84 SRAM) | 82,41 | 0,115 | 0 | **82,53** | **93,9** |
| Clock (tổ hợp) | 0,840 | 1,164 | 0,001 | 2,005 | 2,3 |
| Clock (tuần tự) | 0,239 | 0,094 | 0,005 | 0,338 | 0,4 |
| Tuần tự | 1,784 | 0,092 | 0,011 | 1,887 | 2,1 |
| Tổ hợp | 0,355 | 0,783 | 0,024 | 1,162 | 1,3 |
| **Tổng** | 85,63 | 2,249 | 0,041 | **87,92** | 100 |

- 143 735 instance, mọi instance đều có công suất và activity.
- Clock lớn nhất: CLK_SYS 1,78 mW, CLK_CPU 0,24 mW.
- Instance tiêu thụ nhiều nhất là một SRAM tag của I-cache: 1,074 mW. Con số này bằng 4,29 pJ × 250 MHz, tức `.lib` SRAM tính như macro được đọc ở **mọi** chu kỳ, kể cả khi không được chọn (mục 4).
- Đối chiếu Innovus (`power_final.rpt`): 92,19 mW, chênh 4,6 %, phần lớn ở switching (4,49 so với 2,25 mW).

### 3.3 Sụt áp tĩnh

| Net | Xấu nhất | Trung bình | Ngưỡng | Kết luận |
|---|---|---|---|---|
| VDD | 0,684 V (sụt 16,0 mV = 2,3 %) | 0,696 V | ≥ 0,65 V | Đạt |
| VSS | 15,8 mV (2,3 %) | 3,7 mV | ≤ 50 mV | Đạt |

Tổng dòng 125,6 mA; mỗi nguồn áp cấp từ 0,15 tới 1,30 mA. Số nút vi phạm: 0.

Sụt lớn nhất theo lớp (mV):

| Lớp | M9 | M8 | M7 | M6 | M5 | M4 | M3 | M2 | M1 |
|---|---|---|---|---|---|---|---|---|---|
| VDD | 5,1 | 5,1 | 5,2 | 6,4 | 15,2 | 15,5 | 15,5 | 5,8 | 6,0 |
| VSS | 5,2 | 5,2 | 5,2 | 6,2 | 10,6 | 15,4 | 15,4 | 5,8 | 6,0 |

Sụt lớn nhất nằm ở M3–M5 chứ không ở M1. Chân nguồn của SRAM nằm trên M4, và SRAM là tải chính, nên điểm xấu nhất là ở chân nguồn SRAM chứ không phải ở hàng std cell.

### 3.4 Lưới nguồn: trước và sau khi thiết kế lại

| | Lưới cũ (Voltus 10-13 15:49) | Lưới mới (Voltus 10-14 01:58) |
|---|---|---|
| Ring M8/M9 | 0,136 µm | 0,48 µm |
| Lưới M8/M9 | không có | 0,48 µm, bước 2,16 µm, phủ cả die |
| M6/M7 trên SRAM | dừng ở mép cụm SRAM | phủ cả thân SRAM |
| M5 trên thân SRAM | 1 tap, 1–2 via V4 mỗi net | 7 cặp mỗi SRAM lớn, 224 via V4 mỗi net |
| Chân PG | một đoạn M8 cạnh trên | cả 4 cạnh ring |
| Nguồn áp mỗi net | 56 | 182 |
| VDD thấp nhất | −6,35 V (vô nghĩa vật lý: lưới thiếu nhiều lần) | **0,684 V** |
| Kết luận | FAIL | Đạt |

Mô hình mạng điện trở tính trước khi chạy dự đoán khoảng 6 mV trên M8/M9; Voltus cho 5,1 mV. Ở M3–M5 Voltus cho 15 mV, cao hơn mức "thêm khoảng 2 mV" của mô hình.

Tính liên thông: 0 nguồn dòng, 0 nút, 0 đoạn dây bị Voltus coi là hở. Đoạn nối yếu: VDD 10, VSS 252, đều là M4/M5 quanh SRAM.

---

## 4. Giả định và giới hạn

1. **`.lib` SRAM chỉ có góc TT.** Bù bằng derate ×1,30 (SS, late) và ×0,75 (FF, early). Chưa có số đo để kiểm hệ số này.
2. **Lib FF `asap7sc7p5t_SIMPLE_RVT_FF` khai báo 0,7 V**, các lib FF khác 0,77 V. Bù tạm bằng derate ×0,85 trên trễ early của 56 cell.
3. **Không có derate OCV chung** (1,0 / 1,0) nhưng CPPR vẫn được trừ, giống cấu hình Innovus. Bật bằng `MCU_OCV_DERATE_LATE=1.05 MCU_OCV_DERATE_EARLY=0.95`.
4. **Ba góc RC dùng chung một `qrcTechFile` typical**, chỉ khác nhiệt độ.
5. **Công suất là cận trên.** Không có VCD. Mô hình công suất trong `.lib` SRAM tính 4,29 pJ mỗi chu kỳ cho mọi macro, không phụ thuộc chọn bank hay đọc/ghi, và hai loại macro có số giống hệt. Vì vậy VCD cũng không làm giảm phần SRAM.
6. **Chỉ có sụt áp tĩnh.** Chưa chạy sụt áp động (dynamic IR) và chưa kiểm điện di (EM): mục J/Jmax trong `VDD.main.rpt` để trống.
7. Voltus chỉ chạy góc TT.

---

## 5. Việc còn mở

| # | Việc | Trạng thái |
|---|---|---|
| 1 | max_transition `cg_cpu` (0,283 ns) | Đã viết bản sửa (cặp HB4 + BUFx4 trong `soc_fix_cg_hold`), chạy thử bằng `tclsh`, **chưa chạy Innovus** |
| 2 | Glitch 54 / 62 / 290 vi phạm | Chưa xử lý. **Cần xác nhận:** các net xấu nhất đều là đầu ra SRAM; kiểm `.lib` SRAM có mô hình nhiễu (`ccsn_*`) không |
| 3 | Hold FF chỉ +15 ps | Đạt nhưng mỏng; chạy lại với derate OCV 0,95 early để xem còn đạt không |
| 4 | 14 028 recovery/removal không kiểm | **Cần xác nhận:** đường reset từ `u_sys_rst_sync` có được kiểm không (`report_timing -to <flop>/RESETN`) |
| 5 | 619 max_fanout | Nới `set_max_fanout` trong SDC hoặc ghi rõ là không áp cho cây clock |
| 6 | Công suất thật | VCD từ mô phỏng firmware và mô hình công suất SRAM có điều kiện theo bank |
| 7 | Dynamic IR, EM | Chưa chạy |

---

## Phụ lục A. Nguồn số liệu

| Số liệu | File (từ `Asap7/run_workspace/mcu/`) |
|---|---|
| WNS / TNS, derate, tình trạng ký sinh | `tempus/reports/tempus_summary.rpt` |
| Đường xấu nhất | `tempus/reports/setup_view_ss.rpt`, `setup_view_tt.rpt`, `hold_view_ff.rpt`, `hold_view_tt.rpt` |
| max_transition, max_fanout | `tempus/reports/all_violators.rpt` |
| Ký sinh | `tempus/reports/annotated_parasitics.rpt` |
| Glitch | `tempus/reports/glitch.rpt_view_{ss,tt,ff}` (phần `Glitch Violations Summary`) |
| Độ phủ | `tempus/reports/analysis_coverage.rpt`, `check_timing.rpt` |
| Công suất | `voltus/reports/power_static.rpt` |
| Sụt áp | `voltus/reports/voltus_summary.rpt`, `rail_VDD/VDD.main.rpt`, `rail_VDD/VDD.layerbased_ir.rpt` (tương tự VSS) |
| Đoạn nối yếu | `voltus/reports/rail_{VDD,VSS}/grid_weak_conn.rpt` |
| Lưới cũ | `HANDOFF_2026-10-13.md` mục 3 và 6.2 |

## Phụ lục B. Hình cần chụp trên máy Linux

Ảnh bản đồ sụt áp trong `voltus/reports/rail_*/` chỉ là symlink, không có ảnh thật trong git.

1. `voltus/outputs/rail_VDD/VDD_25C_avg_1/Reports/VDD/ir_linear.gif` và bản VSS: bản đồ sụt áp.
2. Ảnh layout trong Innovus có lưới nguồn mới (M8/M9 phủ die, M5 trên SRAM).
3. Đường setup xấu nhất trong Tempus GUI hoặc đoạn text `Path 1` của `setup_view_ss.rpt`.
4. Biểu đồ tròn công suất theo nhóm (vẽ từ bảng 3.2).
