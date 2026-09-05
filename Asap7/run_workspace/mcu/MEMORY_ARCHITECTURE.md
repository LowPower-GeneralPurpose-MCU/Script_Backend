# Kiến trúc bộ nhớ MCU — quyết định và lý do

Tài liệu này ghi lại *vì sao* hệ thống bộ nhớ có hình dạng hiện tại. Số liệu
sống ở `genus/rtl/flow/project_config.tcl`; ở đây chỉ giải thích.

Toàn bộ bộ nhớ on-chip dựng từ một loại macro duy nhất mà thư viện ASAP7 cung
cấp: `srambank_256x4x32_6t122`, 1024 word × 32 bit = 4 KiB, **single-port 1RW**,
**đọc đồng bộ** (dataout có register), **không có byte-write mask**. Ba tính
chất này quyết định gần như mọi thứ bên dưới.

> Tài liệu này ghi các quyết định **đã chốt**. Những gì còn sai, còn thiếu, và
> kế hoạch sửa theo từng phase nằm ở [MEMORY_FIX_PLAN.md](MEMORY_FIX_PLAN.md).
> Đáng chú ý: mục 2 (tách system RAM) và mục 3 (TCM) dưới đây đều đã được bổ
> sung ở đó — nửa RAM `hi` nay là vùng **uncached** dành cho DMA buffer, và
> TCM có hai giới hạn kiến trúc (DMA và debugger không với tới được) cần biết
> trước khi dựa vào nó.

## 1. Cache: 32 KiB → 16 KiB

| | Trước | Sau |
|---|---|---|
| I-cache | 32 KiB, 2-way, 1024 set | 16 KiB, 2-way, 512 set |
| D-cache | 32 KiB, 4-way, 512 set | 16 KiB, 4-way, 256 set |
| Macro | 10 + 12 = 22 | 6 + 8 = 14 |

Với workload IoT (RTOS kernel + vòng lặp DSP/CNN), 16 KiB thêm cho mỗi cache chỉ
đổi lấy khoảng 1–2 % hit rate, trong khi tốn 8 macro diện tích cộng leakage của
mảng tag. Đây là đánh đổi rõ ràng nghiêng về phía cắt.

Hình học suy ra từ tham số, không hardcode — `genus.tcl` ghim lại kích thước
instantiate trong `top_soc.v` để một lần sửa RTL không thể lệch khỏi macro budget
mà floorplan đang giả định.

Mảng tag bị dùng phí (19/20 bit tag trên macro 32 bit; 512/256 hàng trên macro
1024 hàng) vì generator không có biến thể hẹp hơn hay nông hơn. Mỗi way phải có
macro riêng để một lần lookup đọc được tất cả các way trong cùng chu kỳ.

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

## Bất biến mà flow tự kiểm tra

`genus_run_static_checks` trong `genus/tcl/genus.tcl` sẽ dừng flow nếu:

* số file RTL trong filelist khác 55;
* `top_soc.v` không instantiate cache 16 KiB, hoặc thiếu một trong hai nửa RAM;
* `SLV_AMT` không phải 7;
* thiếu `u_itcm` / `u_dtcm` hoặc macro decode `SOC_IS_ITCM` / `SOC_IS_DTCM`;
* macro budget trong `project_config.tcl` không khớp 256 KiB RAM + 14 cache + 8 TCM;
* netlist sau map không có đúng `SRAM_EXPECTED_COUNT` macro.

Các con số này từng lệch nhau âm thầm giữa `project_config.tcl` và `genus.tcl`,
nên giờ chúng được suy ra từ một nguồn thay vì chép lại.
