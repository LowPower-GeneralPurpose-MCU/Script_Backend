# Kiến trúc bộ nhớ MCU — quyết định và lý do

Tài liệu này ghi lại *vì sao* hệ thống bộ nhớ có hình dạng hiện tại. Số liệu
sống ở `genus/rtl/flow/project_config.tcl`; ở đây chỉ giải thích.

Toàn bộ bộ nhớ on-chip dựng từ hai macro mà generator `asap7_sram_0p0` sinh ra,
cùng một họ chân và cùng ba tính chất: **single-port 1RW**, **đọc đồng bộ**
(dataout có register), **không có byte-write mask**. Ba tính chất này quyết định
gần như mọi thứ bên dưới.

| Macro | Hình học | Dùng cho | Số lượng |
|---|---|---|---|
| `srambank_256x4x32_6t122` | 1024 × 32 bit = 4 KiB | RAM, data cache, TCM | 80 |
| `srambank_128x4x20_6t122` | 512 × 20 bit | tag cache | 4 |

> Tài liệu này ghi các quyết định **đã chốt**. Những gì còn sai, còn thiếu, và
> kế hoạch sửa theo từng phase nằm ở [MEMORY_FIX_PLAN.md](MEMORY_FIX_PLAN.md).
> Đáng chú ý: mục 2 (tách system RAM) và mục 3 (TCM) dưới đây đều đã được bổ
> sung ở đó — nửa RAM `hi` nay là vùng **uncached** dành cho DMA buffer, và
> TCM có hai giới hạn kiến trúc (DMA và debugger không với tới được) cần biết
> trước khi dựa vào nó.

## 1. Cache: 32 KiB → 16 KiB, rồi D-cache 4-way → 2-way, rồi tag sang macro hẹp

| | Ban đầu | Bước 1 (cắt dung lượng) | Hiện tại |
|---|---|---|---|
| I-cache | 32 KiB, 2-way, 1024 set | 16 KiB, 2-way, 512 set | 16 KiB, 2-way, 512 set |
| D-cache | 32 KiB, 4-way, 512 set | 16 KiB, 4-way, 256 set | 16 KiB, **2-way, 512 set** |
| Macro data (256x4x32) | 4 + 8 = 12 | 4 + 4 = 8 | 4 + 4 = 8 |
| Macro tag | 6 + 4 = 10 (256x4x32) | 2 + 4 = 6 (256x4x32) | 2 + 2 = **4 (128x4x20)** |

Với workload IoT (RTOS kernel + vòng lặp DSP/CNN), 16 KiB thêm cho mỗi cache chỉ
đổi lấy khoảng 1–2 % hit rate, trong khi tốn 8 macro diện tích cộng leakage của
mảng tag. Đây là đánh đổi rõ ràng nghiêng về phía cắt.

**D-cache 4-way → 2-way (P2b).** Mỗi way cần macro tag riêng để một lần lookup
đọc được mọi way trong cùng chu kỳ, nên 4-way tốn 4 macro tag mà mỗi macro chỉ
chứa `256 × 20` bit. Hạ xuống 2-way gấp đôi số set, tag vừa 2 macro; số macro
data không đổi. Giá phải trả là chênh conflict miss 2-way/4-way ở 16 KiB, cỡ
1–3 % trên workload nhúng. Đo A/B cùng firmware cho thấy đánh đổi này bị che
hoàn toàn bởi store buffer làm cùng lúc (xem CORE_FIX_PLAN.md §8).

**Tag sang `srambank_128x4x20`.** Trên macro 1024 × 32, mảng tag `512 × 19` chỉ
dùng 29.7 %. Macro 512 × 20 chứa nó ở 95 % và nhỏ hơn khoảng 2.7 lần
(7 741 µm² thay vì 20 976), tức bớt khoảng 52 900 µm² trên 4 macro tag.
`cache_sram_array.v` tự chọn macro tag khi `ADDR_W <= 9` và `TAG_W <= 20`.

Hình học suy ra từ tham số, không hardcode — `genus.tcl` ghim lại kích thước
instantiate trong `top_soc.v` (16 KiB, D-cache 2-way, store buffer 4 entry) để
một lần sửa RTL không thể lệch khỏi macro budget mà floorplan đang giả định.

## 2. System RAM: một slave 256 KiB → hai slave 128 KiB

Đây là thay đổi quan trọng nhất, và là chỗ dễ hiểu sai nhất.

**Chia bank bằng address decode không giảm contention.** `asap7_sram_1rw` đã
decode địa chỉ thành các macro 4 KiB từ trước, nhưng tất cả nằm sau **một** AXI
slave front-end, và front-end đó tuần tự hóa mọi truy cập (macro là 1RW: mỗi chu
kỳ chỉ phục vụ được một request). CPU đánh bank 0 và DMA đánh bank 40 vẫn xếp
hàng sau nhau. Chia dải địa chỉ chỉ giúp linker script gọn, không giúp băng
thông.

Thứ thực sự tạo song song là **nhiều slave port**, vì `axi_interconnect` cấp cho
mỗi slave port một arbiter riêng. Nên 256 KiB được chia đôi:

```
0x2000_0000 - 0x2001_FFFF   slave 1   axi_ram #(.MEM_DEPTH(32768))  u_axi_ram_lo
0x2002_0000 - 0x2003_FFFF   slave 6   axi_ram #(.MEM_DEPTH(32768))  u_axi_ram_hi
```

Phân công phần mềm dự kiến:

* **lo** — RTOS stack, heap, biến static, dữ liệu chung của CPU.
* **hi** — buffer DMA: Wi-Fi/BLE RX/TX, ADC/sensor, framebuffer.

Linker script đặt đúng section vào đúng nửa thì xác suất đụng độ CPU↔DMA về gần
0. Đặt sai thì quay lại đúng tình trạng cũ — đây là hợp đồng phần mềm phải giữ,
phần cứng không ép được.

Không chọn **fine-grained interleaving** (xen kẽ word/line qua các bank) vì burst
DMA dài sẽ quét qua mọi bank nên *luôn* đụng CPU, và burst INCR bị xé nhỏ làm mất
throughput 1 beat/chu kỳ. Interleaving hợp với multi-core cache-line-interleaved,
không hợp MCU có DMA burst.

`SLV_AMT` do đó là 7. Bản đồ địa chỉ đầy đủ nằm ngay trên khối
`axi_interconnect` trong `top_soc.v`.

## 3. TCM: nối thẳng core, ngoài bus

```
0x0002_0000 - 0x0002_3FFF   ITCM 16 KiB   ISR, vòng lặp DSP/1D-CNN
0x0002_4000 - 0x0002_7FFF   DTCM 16 KiB   core stack, biến thời gian thực
```

TCM (`genus/rtl/memory/tcm.v`) gắn vào core port, **trước** cache và **ngoài**
AXI interconnect. Không slave nào của interconnect nhận hai dải này, nên một
truy cập DMA vào đó decode ra không slave nào và bị báo lỗi thay vì âm thầm rơi
chỗ khác.

**TCM ở đây không phải 0-wait-state.** Macro đọc đồng bộ: sớm nhất là chu kỳ sau
khi đặt địa chỉ. Latency thực tế:

| Thao tác | Chu kỳ |
|---|---|
| Đọc | 2 |
| Ghi đủ 32 bit | 2 |
| Ghi byte / halfword | 3 (read-modify-write) |

Cache hit cũng tốn đúng 2 chu kỳ (IDLE + LOOKUP). Cái TCM loại bỏ là **trường
hợp miss** và **tranh chấp bus**, tức là *jitter*, không phải chu kỳ pipeline.
Giá trị nằm ở tính tất định cho ISR và phân tích WCET. Muốn xuống 1 chu kỳ thì
core phải phát địa chỉ sớm hơn một nhịp — đó là thay đổi trong
`riscv_pipeline.v`, không phải trong `tcm.v`.

ITCM có hai port: fetch (đọc) và load/store. Port load/store là cách phần mềm
**copy code vào ITCM** lúc boot; không có nó thì ITCM không nạp được gì. DTCM chỉ
cần port load/store nên tie-off port fetch (`HAS_FETCH_PORT = 0`).

Trọng tài giữa hai port: port load/store thắng, **trừ khi** một fetch đã thua ở
chu kỳ trước (bit `f_starved`). Không có luật này thì một chuỗi load/store liên
tiếp có thể giữ fetch lại vô hạn. Tranh chấp chỉ xảy ra trong lúc copy code vào
ITCM, tức là hoạt động boot-time; steady-state fetch không bao giờ stall.

## 4. Read-modify-write cho ghi dưới 32 bit

Macro không có byte-write mask, nên ghi byte/halfword phải đọc word cũ, trộn byte
lane, rồi ghi lại.

**Ai trả giá này:** chỉ đường CPU write-through. `dma_axi_master.v` luôn phát
`WSTRB = 4'b1111`, nên **DMA không bao giờ read-modify-write**. Chi phí rơi vào
`sb`/`sh` do D-cache write-through chuyển tiếp, và vào ghi từ debug module.

> Cả hai đường đó **thật sự không chạy** cho tới 2026-09-05: `dcache.v` và
> `dtm_axi_master.v` diễn đạt store dưới 32 bit bằng `AWSIZE` nhỏ và địa chỉ lẻ
> thay vì bằng `WSTRB`, nên `axi_ram` trả `SLVERR` và bỏ qua. Không master nào
> kiểm tra `BRESP`, nên lỗi im lặng. Xem P6 trong
> [MEMORY_FIX_PLAN.md](MEMORY_FIX_PLAN.md). Bất biến này nay được chốt bằng
> `genus/rtl/tests/tb_mem_paths.sv` — nó đọc lại RAM **bằng DMA**, tức bằng một
> master không đi qua cache, nên cache không che được nữa.

FSM ghi của `axi_ram` trước đây đi qua một state chờ thuần túy giữa lần đọc và
lần ghi trộn. Macro đã register dataout ngay ở cạnh clock của state đọc, nên dữ
liệu đã sẵn sàng ở state ghi và state chờ đó không làm gì. Bỏ nó đưa penalty từ
3 chu kỳ phụ xuống 2, và không kéo dài đường tổ hợp nào: đường
`dataout → merge → din` vốn đã nằm trọn trong state ghi.

Muốn giảm thêm thì hai hướng còn lại là (a) buffer write-combining gộp các store
dưới 32 bit liên tiếp vào cùng một word, và (b) tránh `sb`/`sh` trong vòng lặp
nóng ở phía phần mềm. Cả hai đều chưa làm.

## 5. D-cache: write-through + store buffer + `fence`

D-cache là **write-through, no write-allocate**, không dirty bit, không có cổng
invalidate/flush/CMO. Từ 2026-09-08 nó có **store buffer 4 entry**: store
cacheable retire sau 1 chu kỳ thay vì chờ trọn một vòng AXI qua CDC 400/200.

Ba hệ quả kiến trúc phải biết, chi tiết ở MEMORY_FIX_PLAN.md § Phase 1:

* **Store uncached không bao giờ vào buffer**, và mọi truy cập uncached ép buffer
  xả trước. Thứ tự MMIO vì thế đúng theo cấu trúc, và DMA an toàn vì khởi động
  DMA là một ghi MMIO.
* **Lỗi bus của store cacheable là imprecise** — báo qua PLIC nguồn 7
  (`dcache_sb_error`), không phải exception đồng bộ. Store uncached vẫn precise.
* **`fence` xả buffer (P2c).** Đây là cách duy nhất ép xả cho một master vào
  thẳng AXI mà không qua CPU — debugger qua SBA. `fence.i` vẫn là illegal
  instruction vì chưa có đường invalidate I-cache.

Lệnh nguyên tử (RV32A) đi qua D-cache bằng bắt tay hai chu kỳ
(`dcache_amo_req` / `dcache_amo_capture`, R1b). AMO vào vùng **uncached** hiện bị
bỏ âm thầm (R12, chưa sửa) — không đặt spinlock/refcount trong `.dmabuf`.

## 6. Boot ROM: mask ROM 32 KiB + XIP từ QSPI flash

```
0x0001_0000 - 0x0001_7FFF   boot ROM 32 KiB  mask ROM (logic), slave 0
0x0001_8000 - 0x0001_FFFF   không map        DECERR (trước đây: alias của ROM)
0x3000_0000 - 0x30FF_FFFF   QSPI flash       XIP, cacheable, slave 2
```

**Vì sao 32 KiB.** Đó là cỡ ROM của các MCU IoT phổ biến: RP2040 có 16 KB,
vùng "system memory" chứa bootloader của STM32F4 khoảng 30 KB, còn chip có
Wi-Fi/BLE như ESP32-C3 thì lên tới hàng trăm KB. 32 KiB đủ chỗ cho những gì một
bootloader tầng 1 công nghiệp thường có ngoài phần đang làm: nạp qua UART khi
flash hỏng, kiểm ảnh bằng ASCON-Hash, chọn giữa hai ảnh A/B.
Với ROM logic, **diện tích tỉ lệ với số word thật sự dùng, không phải với cửa sổ**:
word không có trong `boot.mem` rơi vào nhánh `default` của bảng `case` và bị tổng
hợp thành hằng 0. Hiện tại 26 word gần như không tốn gì. Còn nếu lấp đầy 32 KiB
thì đó là ~262 kbit logic ngẫu nhiên, phải xem `area_syn.rpt` (`axi_rom` được giữ
hierarchy riêng để tách được con số này).

**Vì sao không dùng macro SRAM cho boot ROM.** Macro của `asap7_sram_0p0` là X
lúc cấp nguồn, và ASAP7 không có ROM compiler. Mã đầu tiên CPU chạy vì vậy phải
nằm trong logic. Ngày 2026-09-11 đã thử phương án "shadow ROM": 2 ×
`srambank_256x4x32` và một FSM phần cứng chép 8 KiB đầu flash vào đó rồi mới nhả
reset core. Phương án đó đã được **hoàn tác trước khi merge**, vì nó không giống
MCU thật ở ba điểm:

1. **Không có root of trust.** Lệnh đầu tiên đến từ flash ngoài, chưa được kiểm
   tra, nên không thể làm secure boot, dù chip có sẵn ASCON-Hash.
2. **Không có đường cứu.** Flash trống hoặc hỏng thì chỉ còn JTAG.
3. **Tốn 2 macro và một loader** để chép thứ mà I-cache vốn đã XIP được.

MCU thương mại (RP2040, ESP32, i.MX RT, SiFive FE310) đều dùng **mask ROM nhỏ
chứa bootloader tầng 1 + firmware trong flash**. Ở đây làm đúng như vậy.
`axi_rom.v` vẫn là bảng `case` do `genus.tcl` sinh từ `rtl/memory/boot.mem`, cửa sổ
thu từ 64 KiB về 32 KiB. Macro budget giữ nguyên 80 + 4.

**Mã boot tầng 1** (`boot.mem`, 26 lệnh, viết tay vì máy build không có toolchain
RISC-V; mã hoá và bốn kịch bản bên dưới đã chạy trên một ISS Python):

1. `mtvec` ← handler trong ROM. Trước đây `mtvec` reset về 0, mà địa chỉ 0 không
   thuộc slave nào. Một trap trước khi firmware đặt `mtvec` sẽ fetch 0 → DECERR →
   access fault → lại trap về 0, lặp mãi không để lại dấu vết. Nay handler ROM
   dừng ở vòng `j .` với `t4 = mcause`, `t5 = mepc`, `t6 = mtval` cho debugger.
2. Đọc header ở `0x3000_0000`. Không có magic → vòng `park` (`j .`), chờ debugger.
3. `length ≠ 0` → chép payload tới `load` (ITCM, RAM lo…) rồi `fence` để xả store
   buffer trước khi I-cache đọc vùng vừa chép. `length = 0` → chạy XIP tại chỗ.
4. Nhảy tới `entry`.

| Offset | Trường | Ý nghĩa |
|---|---|---|
| `+0x00` | magic | `0x4255434D` (`"MCUB"`, little-endian) |
| `+0x04` | entry | địa chỉ nhảy tới |
| `+0x08` | load | đích chép, bỏ qua khi `length = 0` |
| `+0x0C` | length | số byte chép, bội số của 4; `0` = XIP |
| `+0x10` | payload | |

Kịch bản đã kiểm trên ISS: flash trống → `park`; ảnh XIP → nhảy vào flash; ảnh
chép vào ITCM → ITCM khớp payload rồi chạy ở đó; `entry` không map → trap handler
ROM với `mcause = 1`.

**Vòng chờ dùng `j .`, cố ý không dùng `wfi`.** `sleeping_reg` trong
`pipeline_control_unit.v` chỉ được xoá bằng ngắt đã bật. Debugger halt rồi resume
một core đang ngủ WFI thì core vẫn ngủ và không chạy code ở `dpc`. Đó là lỗi riêng
của core (ghi ở MEMORY_FIX_PLAN.md mục 8); ROM chỉ né nó.

**Hệ quả với firmware và mô phỏng.**

* Suite `fw` vẫn bake **toàn bộ** firmware vào ROM thay cho `boot.mem`, nên ảnh
  phải ≤ 32 KiB. `gen_boot_rom.py` dừng hẳn nếu vượt, thay vì cắt bớt. Firmware
  lớn hơn phải link chạy XIP ở `0x3000_0000` với header trên, và `tb_top_soc` phải
  có model SPI flash. `Driver/ld/soc.ld` (ngoài repo) phải sửa `ROM LENGTH` 64K →
  32K.
* Testbench không có model flash thì chân MISO thả nổi. `axi_spi_flash.v` có một
  nhánh `ifndef SYNTHESIS` coi Z/X là 1 (điện trở kéo lên của board), nên ROM đọc
  ra `0xFFFF_FFFF` và vào `park` một cách tất định.
* **XIP hiện rất chậm:** `axi_spi_flash` chỉ có Fast Read `0x0B` một bit ở
  SPI 50 MHz. Mỗi lần I-cache miss 16 B tốn cỡ 600–700 chu kỳ `clk_axi`. Muốn
  firmware chạy XIP được thì cần quad I/O (`0xEB`) + continuous read. Đó là việc
  tiếp theo đáng làm cho đường boot này.

## Bất biến mà flow tự kiểm tra

Khối pre-check đầu `genus/tcl/genus.tcl` sẽ dừng flow nếu:

* số file RTL trong filelist khác `EXPECTED_RTL` = **58**;
* `top_soc.v` không instantiate I-cache/D-cache 16 KiB, D-cache khác 2-way hoặc
  store buffer khác 4 entry, hoặc thiếu một trong hai nửa RAM;
* boot ROM trong `top_soc.v` khác `MEM_DEPTH(8192)` (32 KiB), hoặc `boot.mem` có
  word nào nằm ngoài 8192 word đó;
* `SLV_AMT` không phải 7;
* thiếu `u_itcm` / `u_dtcm` hoặc macro decode `SOC_IS_ITCM` / `SOC_IS_DTCM`;
* macro budget trong `project_config.tcl` không còn là 64 RAM + 4 + 4 cache data
  + 4 + 4 TCM = **80** `256x4x32` và 2 + 2 = **4** `128x4x20`;
* `cache_sram_array.v` không còn chọn macro tag theo `ADDR_W <= 9 && TAG_W <= 20`;
* số clock trong SDC khác `EXPECTED_CLOCKS` = **19**;
* netlist sau map không có đúng số macro của từng loại.

`genus/rtl/tests/run_rtl_lint.sh` giữ cùng con số 58 cho verilator.

Các con số này từng lệch nhau âm thầm giữa `project_config.tcl` và `genus.tcl`,
nên giờ chúng được suy ra từ một nguồn thay vì chép lại.
