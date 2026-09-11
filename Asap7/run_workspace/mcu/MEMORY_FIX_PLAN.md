# Kế hoạch sửa memory subsystem

**Ngày:** 2026-09-05 · **Cập nhật:** 2026-09-11 (sau merge P2c + R1/R2/ASCON)

**Trạng thái:** Phase 0 xong · P6 xong · Phase 1 (store buffer) xong · P2b
(D-cache 2-way, tag sang macro hẹp) xong · **P2c (`fence` xả buffer) xong ở RTL,
chưa chạy lại sim** · R11 (AMO trượt cache) xong · **R12 (AMO uncached bị bỏ) mở**
· Phase 2–4 chưa làm · **Boot ROM 8 KiB mask ROM + mã boot tầng 1 xong ở RTL
(B1), rà soát vùng nhớ toàn SoC ở mục 8**. Genus đã chạy lại (2026-09-09,
2026-09-10), xem [GENUS_REVIEW_2026-09-09.md](GENUS_REVIEW_2026-09-09.md).

Tài liệu chị em với [MEMORY_ARCHITECTURE.md](MEMORY_ARCHITECTURE.md). File đó ghi
**lý do của các quyết định đã chốt**; file này ghi **những gì còn sai hoặc còn
thiếu**, cái nào đã sửa, cái nào chưa và **tại sao chưa**, kèm thiết kế cụ thể để
thực thi khi có công cụ synthesis.

---

## 1. Hiện trạng

### 1.1 Bản đồ địa chỉ

| Vùng | Địa chỉ | Kích thước | Đường đi | Thuộc tính |
|---|---|---|---|---|
| Boot ROM (s0) | `0x0001_0000` | **8 KiB** mask ROM (logic) ← mục 8 | AXI | cacheable |
| *(không map)* | `0x0001_2000` | 56 KiB | — | DECERR, trước đây là alias của ROM |
| ITCM | `0x0002_0000` | 16 KiB | **thẳng vào core** | ngoài cache & ngoài AXI |
| DTCM | `0x0002_4000` | 16 KiB | **thẳng vào core** | ngoài cache & ngoài AXI |
| CLINT (s5) | `0x0200_0000` | 64 KiB | AXI | **uncached** |
| RAM lo (s1) | `0x2000_0000` | 128 KiB | AXI | cacheable |
| RAM hi (s6) | `0x2002_0000` | 128 KiB | AXI | **uncached** ← Phase 0 |
| SPI flash (s2) | `0x3000_0000` | 16 MiB | AXI | cacheable |
| APB window (s4) | `0x4000_0000` | 128 MiB | AXI→APB | **uncached** |
| SDRAM (s3) | `0x8000_0000` | 64 MiB | AXI | cacheable |

Master trên interconnect: `0` I-cache · `1` D-cache · `2` DTM (debug) · `3` DMA.
Slave: 7. Domain: `clk_cpu` 400 MHz (gated) / `clk_axi` 200 MHz / `clk_apb` 100 MHz.

### 1.2 Ngân sách SRAM macro

| Khối | 256x4x32 (4 KiB) | 128x4x20 (tag) | Silicon SRAM |
|---|---|---|---|
| System RAM (2 x 128 KiB) | 64 | — | 256 KiB |
| I-cache 16 KiB, 2-way | 4 | 2 | 16 KiB + 2.5 KiB |
| D-cache 16 KiB, 2-way | 4 | 2 | 16 KiB + 2.5 KiB |
| ITCM | 4 | — | 16 KiB |
| DTCM | 4 | — | 16 KiB |
| **Tổng** | **80** | **4** | **≈ 325 KiB** |

System RAM chiếm **76 %** số macro. Ở lần tổng hợp 2026-09-10 — khi tag còn
nằm trên 84 × `256x4x32` — SRAM chiếm **83 %** cell area; con số cho cấu hình
80 + 4 chờ lần chạy Genus đang làm. Đây là khối chi phối diện tích die.

D-cache từng là 4-way / 8 macro. Macro `1024 x 32` giữ trọn **một** way, nên
4-way cần 4 macro tag mà mỗi macro chỉ dùng `256 x 20` bit — 16 KiB silicon cho
640 byte tag thật. Hạ xuống 2-way gấp đôi số set, tag vừa 2 macro thay vì 4; số
macro data không đổi. Giá phải trả là chênh lệch conflict miss giữa 2-way và
4-way ở 16 KiB, cỡ 1–3 % trên workload nhúng. Sau đó cả 4 macro tag chuyển sang
`srambank_128x4x20_6t122` (512 × 20 bit, dùng 95 % thay vì 29.7 %), bớt khoảng
52 900 µm².

### 1.3 Đặc tính cache

- **D-cache**: 16 KiB, 2-way, block 16 B, **write-through, no write-allocate**,
  không dirty bit, **store buffer 4 entry** (Phase 1, xong), **không có cổng
  invalidate/flush/CMO**. `fence` chờ tới khi buffer rỗng (P2c). Payload W của
  đường uncached được chốt vào `fsm_wdata_q`/`fsm_wstrb_q` (R1a).
- **Lệnh nguyên tử** qua D-cache: bắt tay hai chu kỳ `dcache_amo_req` /
  `dcache_amo_capture` (R1b) — AMO hit tốn 3 chu kỳ thay vì 2; AMO trượt chạy
  lại vòng tra cứu sau refill (R11). **AMO vào vùng uncached bị bỏ âm thầm (R12,
  chưa sửa)** — chỉ phần đọc chạy, bộ nhớ không được ghi.
- **I-cache**: 16 KiB, 2-way, block 16 B.
- **TCM**: đọc 2 chu kỳ · ghi word 2 chu kỳ · ghi byte/halfword **3 chu kỳ**
  (read-modify-write, vì macro không có byte-write mask). Port D thắng, **trừ khi**
  fetch đã thua ở chu kỳ trước (`f_starved`, chỉ ITCM có — DTCM không có port F).

---

## 2. Danh sách vấn đề

| ID | Vấn đề | Mức | Phase |
|---|---|---|---|
| **P0** | DMA ghi thì CPU đọc ra dữ liệu cũ (không có coherency, không có vùng uncached cho RAM) | Chặn chức năng | **0 — xong** |
| **P1** | Nửa RAM `hi` và cả ITCM/DTCM không có trong linker, 40/86 macro (ngân sách lúc đó) là silicon chết | Lãng phí | **0 — xong (cơ chế)** |
| **P2** | D-cache không có store buffer, mỗi store stall core trọn một vòng AXI qua CDC 400 sang 200 | Hiệu năng | **1 — xong (35 → 1 chu kỳ)** |
| **P2c** | `fence` là NOP nên không gì ép store buffer xả cho debugger | Đúng đắn (debug) | **1 — xong ở RTL, chờ sim** |
| **P3** | DMA và debugger không với tới được TCM | Giới hạn kiến trúc | 2 |
| **P4** | Không có clock gating riêng cho RAM `hi`; 64 macro toggle clock vô điều kiện | Ngược mục tiêu LowPower | 3 |
| **P5** | Không có ECC/parity trên ≈ 325 KiB SRAM | Chấp nhận có ý thức | 4 |
| **P6** | `sb`/`sh` và `lb`/`lh` uncached bị slave từ chối im lặng — dữ liệu mất | Chặn chức năng | **0 — xong** |
| **R12** | AMO vào vùng uncached (DMAPOOL, MMIO) chỉ đọc, không ghi — im lặng | Chặn chức năng (atomics) | **Mở** — GENUS_REVIEW §15.4, khuyến nghị trap |

---

## 3. Phase 0 — ĐÃ SỬA VÀ VERIFY

### 3.1 P0 — Đóng lỗ hổng coherency bằng thuộc tính bộ nhớ

**Triệu chứng.** DMA ghi buffer vào system RAM. D-cache còn giữ line cũ ở trạng
thái clean/hợp lệ. CPU đọc ra giá trị cũ **vĩnh viễn** cho tới khi line bị evict
ngẫu nhiên. Không thể vòng tránh bằng phần mềm vì RAM không hề có bí danh uncached
và D-cache không có lệnh invalidate.

Chiều ngược lại (CPU ghi, DMA đọc) vốn đã an toàn nhờ write-through.

**Cách sửa đã chọn.** Không thêm snoop, không thêm dirty bit, không thêm CMO — mà
cho hai nửa system RAM **hai thuộc tính khác nhau**:

```verilog
// rtl/top_soc.v
`define SOC_IS_UNCACHED(a) ( ((a) & 32'hF800_0000) == 32'h4000_0000 ||   // APB
                             ((a) & 32'hFFFF_0000) == 32'h0200_0000 ||   // CLINT
                             ((a) & 32'hFFFE_0000) == 32'h2002_0000 )    // RAM hi
```

**Vì sao chọn cách này.**

| Phương án | Chi phí | Đánh giá |
|---|---|---|
| Vùng uncached cho DMA buffer | 1 dòng decode | Đã chọn |
| Thêm cổng invalidate + FENCE | FSM mới trong dcache + ISA plumbing | Đắt, cần verify riêng |
| Snoop / ACE-Lite | Rất lớn | Quá tầm cho MCU IoT |

Đây là mô hình chuẩn của MCU không coherent: vùng `NOCACHE` của STM32H7, `.sram2`
của NXP. Nó cũng **làm cho quyết định tách RAM ở mục 2 của MEMORY_ARCHITECTURE.md
có ý nghĩa thật**: trước đây tách ra chỉ để có băng thông song song, giờ hai nửa
khác nhau về vai trò.

**Rủi ro timing: không.** Chỉ là logic decode tổ hợp trên đường `uncache_en_i` vốn
đã tồn tại và đã được chứng minh chạy đúng (firmware ghi UART qua đúng đường này
và testbench firmware pass).

**Đánh đổi.** CPU truy cập nửa `hi` chậm hơn vì không được cache. Đúng như thiết
kế — đó là vùng cho DMA, không phải vùng CPU tính toán.

### 3.2 P1 — Cho firmware đường vào RAM `hi` và TCM

`Driver/ld/soc.ld` trước đây chỉ khai `RAM 128K @ 0x20000000`. Nửa `hi` và cả
ITCM/DTCM không tồn tại với phần mềm. Đã thêm:

```
ITCM (rx)    : ORIGIN = 0x00020000, LENGTH = 16K
DTCM (rw)    : ORIGIN = 0x00024000, LENGTH = 16K
RAM (rwx)    : ORIGIN = 0x20000000, LENGTH = 128K   /* CACHEABLE */
DMAPOOL (rw) : ORIGIN = 0x20020000, LENGTH = 128K   /* UNCACHED  */
```

kèm ba section mới: `.dmabuf` (NOLOAD, vào DMAPOOL), `.itcm_text` (lưu ở ROM, có
`_sitcm_load` / `_sitcm` / `_eitcm` để crt0 copy) và `.dtcm_data` (NOLOAD).

Cũng sửa `ROM LENGTH` từ 16K lên **64K** cho khớp cửa sổ decode thật
(`axi_rom MEM_DEPTH = 16384` words = 64 KiB, mask `0xFFFF_0000`).

> **2026-09-11: cửa sổ ROM nay chỉ còn 8 KiB** (mask `0xFFFF_E000`, mục 8). Phải
> sửa lại `ROM LENGTH = 8K` trong `Driver/ld/soc.ld` (ngoài repo này).

Cách dùng trong C:

```c
__attribute__((section(".dmabuf"), aligned(16))) static uint8_t rx_ring[512];
__attribute__((section(".itcm_text"), noinline)) void isr_fast(void) { }
__attribute__((section(".dtcm_data")))           static int32_t fir_taps[64];
```

### 3.3 Cảnh báo đã đưa vào RTL và linker

- **ITCM là X lúc power-up.** Macro SRAM không có reset và ITCM không có valid bit.
  **Phải copy code vào ITCM xong rồi mới được nhảy vào đó.** Không có phần cứng
  nào chặn việc này — đây là ràng buộc thứ tự boot của firmware.
- **Đừng đặt stack ở DTCM** nếu còn muốn xem backtrace bằng GDB (xem P3).

### 3.4 Kết quả verify Phase 0

```
=== APB peripheral testbench ===  PASS COUNT = 256  FAIL COUNT = 0  RESULT: PASS
=== firmware testbench ===        [TB][PASS] UART message matched and CPU reached WFI
                                  UART: HELLO RISC-V UART TEST!
=== memory-path testbench ===     PASS COUNT = 99   FAIL COUNT = 0  RESULT: PASS
```

Chạy lại bằng: `genus/rtl/tests/run_soc_sim.sh all`

> Đây là kết quả **lúc đóng Phase 0** (2026-09-05), giữ lại làm mốc. Kết quả
> hiện hành nằm ở mục 5 và bảng theo dõi mục 7.

Lỗ hổng verify nêu ở đây trước đây — *chưa testcase nào thực sự đọc/ghi nửa
`hi` hay TCM* — nay đã đóng bằng `tests/tb_mem_paths.sv`. Xem mục 5.

### 3.5 P6 — Store dưới 32 bit bị mã hoá sai trên AXI

Lỗi này **không nằm trong kế hoạch ban đầu**. Nó lộ ra ngay lần đầu chạy
`tb_mem_paths.sv` (mục 5), và đó chính là lý do phải trả nợ verification trước
khi làm tiếp: nó nằm đúng trên đường mà Phase 0 vừa mở ra.

**Triệu chứng.** Mọi `sb`/`sh` vào DMAPOOL biến mất. Mọi `lb`/`lh` từ DMAPOOL
trả về 0. Ghi byte/halfword từ debugger cũng vậy.

**Nguyên nhân.** Trên bus 32 bit, một transfer dưới 32 bit được diễn đạt bằng
**WSTRB** — địa chỉ căn word, `AxSIZE` bằng bề rộng *bus*, byte nằm ở **lane**
ứng với địa chỉ. Cả `dcache.v` lẫn `dtm_axi_master.v` đều nói ngược lại cả ba
điểm:

| | Trước | Đúng |
|---|---|---|
| `AWSIZE` | `mem_size` (0 với `sb`) | bề rộng bus = `3'd2` |
| `AWADDR` / `ARADDR` uncached | mang cả 2 bit thấp | căn word |
| `WDATA` | giá trị căn phải (`[7:0]`) | nhân ra lane |

`axi_ram` chỉ nhận `AxSIZE = 3'd2` và địa chỉ căn word, nên nó trả `SLVERR` và
**không ghi gì**. Không master nào kiểm tra `BRESP`/`RRESP`, nên lỗi hoàn toàn
im lặng.

**Vì sao không ai thấy trước đó.** Trước Phase 0, vùng uncached chỉ có APB và
CLINT — toàn thanh ghi truy cập bằng `sw`/`lw`. Còn trên vùng **cacheable**,
D-cache che mất: một write hit vẫn trộn và ghi vào mảng SRAM của cache, nên CPU
đọc lại thấy đúng, trong khi RAM thật không bao giờ nhận được byte đó — dữ liệu
chỉ mất khi line bị evict. Firmware TB không bắt được vì nó chỉ ghi UART bằng
`sw`.

`tb_mem_paths.sv` bắt được vì nó đọc lại RAM lo **bằng DMA** — một master khác,
không đi qua cache, nên nó nhìn thấy nội dung thật của RAM.

**Rủi ro timing: âm.** Cả ba sửa đều *bỏ bớt* logic: `AWSIZE` thành hằng số, hai
bit thấp của địa chỉ thành hằng số, và `lane_align_wdata` chỉ là mux chọn giữa
ba cách nối dây. Không thêm tầng nào vào đường tới hạn.

**File:** `genus/rtl/memory/dcache.v`, `genus/rtl/debug/dtm_axi_master.v`.

**Chưa sửa (có ý thức):** `rv_debug_module_sba` trả về nguyên word cho một lệnh
đọc `sbaccess = 8/16`, thay vì trích byte/halfword như đặc tả RISC-V Debug mô
tả. Testbench chỉ khẳng định `RRESP = OKAY`. Đây là ngữ nghĩa của debug module,
không phải của hệ thống bộ nhớ, và sửa nó cần một testcase JTAG thật.

---

## 4. Phase 1 — XONG · Phase 2–4 — CHƯA SỬA, kèm thiết kế

> **Điều kiện tiên quyết: Genus — đã đáp ứng một phần.**
> Genus đã chạy lại trên RTL sau rework (2026-09-09 và 2026-09-10, máy Linux có
> license; máy Windows vẫn không có). Lần chạy 2026-09-10 (tag còn ở
> `256x4x32`, chưa có P2c) là đa góc: CLK_CPU
> **+812.6 ps ở TT nhưng +1.3 ps ở SS**, CLK_AXI **+1.1 ps ở SS** — tức vẫn
> **không còn dư địa ở góc chậm** cho cả miền CPU lẫn miền AXI, và đó vẫn là con
> số trước CTS. Phase 2 (thêm cổng crossbar) và 3b (ICG trong clock tree) đụng
> đúng hai miền đó, nên vẫn phải có Genus + CTS/STA xác nhận trước khi làm.
> Chi tiết: GENUS_REVIEW_2026-09-09.md §17.

### Phase 1 — Store buffer cho D-cache (P2) — ĐÃ SỬA VÀ VERIFY

**Kết quả đo, 2026-09-08.** Store cacheable: **35 → 1 chu kỳ** `clk_cpu`.
Đổi lại, một read miss ngay sau chuỗi store phải chờ buffer xả nên đi từ 57 lên
~90 chu kỳ — đúng phần đánh đổi của quy tắc 2 dưới đây. Testbench `mem` lên
**109/109 PASS**, thêm nhóm `TS` đo trực tiếp ba tính chất của buffer.

**End-to-end (`fw`, A/B trên cùng một firmware, chỉ đảo `dcache.v` + `top_soc.v`):
2 831 456 000 → 1 528 046 000 ns, nhanh hơn 1.85×.** Đây là bài test MMIO
ordering thật (driver UART) mà mục "verify bắt buộc" số 4 dưới đây yêu cầu —
nó vừa chứng minh thứ tự đúng, vừa cho con số hiệu năng. `apb` giữ 256/256.

**Sai lệch so với thiết kế gốc dưới đây:** entry KHÔNG mang cờ `is_device`.
Store uncached đơn giản là *không bao giờ* vào buffer — nó giữ nguyên đường
`AW_REQ/W_REQ/B_WAIT` cũ và vẫn báo lỗi **chính xác** qua `dcache_error`. Nhờ
vậy quy tắc "write-through nghiêm ngặt cho thiết bị" thành đúng theo cấu trúc
thay vì phải cưỡng chế bằng logic, và hai FSM không bao giờ cùng lái kênh ghi
nên không cần trọng tài.

**Hệ quả PHẢI biết — lỗi bus của store cacheable trở thành imprecise.** Store đã
retire trước khi BRESP về, nên `mepc` không còn trỏ vào nó được. Nó được báo
bằng **PLIC nguồn 7** (`dcache_sb_error`, xem `top_soc.v`) thay vì exception
đồng bộ. Store uncached — MMIO, CLINT, DMA pool — không đổi: vẫn precise.

**`FENCE` đã xả buffer — P2c, xong.** Trước đó `control_unit.v` decode `fence`
thành NOP với lý do "một hart, bộ nhớ không đặt lại thứ tự" — lý do đó SAI đối với
master ngoài. Thứ tự với DMA vẫn an toàn theo cấu trúc (khởi động DMA là ghi
MMIO ⇒ uncached ⇒ ép xả buffer trước); chỗ hở là **debugger ghi bộ nhớ trong lúc
core đang chạy**, master duy nhất vào thẳng AXI mà không qua CPU.

Bit điều khiển chạy suốt: `fence_op` (control_unit) → `id_ex_fence_op` →
`ex_mem_fence_op` → `dcache_fence` (chặn bằng `commit_kill` như
`dcache_write_req`) → `cpu_fence` của `data_cache`, nơi nó giữ `dcache_stall` cao
cho tới khi `sb_drained`. Đây là **quy tắc 5** trong khối chú thích store buffer
của `dcache.v`.

Ba điểm cần biết:

- **`fence` không có địa chỉ.** `cpu_data_addr` lúc đó là kết quả ALU rác. Nếu nó
  rơi vào dải TCM thì mux trả lời cũ sẽ lấy `hit` của TCM và fence thành NOP —
  ngẫu nhiên. `top_soc.v` vì vậy có `ls_sel_*_rsp = ls_sel_* & ~cpu_data_fence`:
  khi fence bật, câu trả lời luôn đến từ D-cache. TCM không cần xả (SRAM nối
  thẳng core, không store buffer, không qua bus).
- **Trap trong lúc fence đang chờ là an toàn.** `commit_kill` hạ `dcache_fence`
  tổ hợp ngay trong chu kỳ nhận trap, nên trap không bị trễ thêm; fence chưa
  retire nên `mepc` trỏ vào chính nó và `mret` chạy lại.
- **`FENCE.I` (funct3 = 001) vẫn là illegal-instruction** — SoC này chưa có
  đường invalidate I-cache. `pred/succ` bị bỏ qua có ý: xả tất cả mạnh hơn đặc
  tả yêu cầu.

Nhóm test `TF` trong `tb_mem_paths.sv` đo trực tiếp hai chiều (buffer đầy → fence
phải chờ và sau đó buffer rỗng; buffer rỗng → fence không được chờ), và T9 thay
đoạn "fence thủ công" `lw(ADDR_SYSCON + 0)` bằng `fence_()` thật. T10b (AMO trượt
cache rồi đọc lại bằng SBA) cũng đổi từ chờ cứng `repeat (200)` sang `fence_()`.
TF thêm 7 check → `mem` mong đợi **128**. **Chưa chạy lại sau merge** — máy
Windows không có XSim; chạy `run_soc_sim.sh mem` hoặc `vivado_sim_mem.tcl`.

Nhóm `TS` vẫn cố ý xả buffer bằng `lw(ADDR_SYSCON + 0)` (quy tắc 2) trước khi
đo, chứ không dùng `fence`: TS chạy trước TF, nên nó không được phụ thuộc vào
tính năng mà TF chưa kiểm.

**Nợ ngoài repo:** `pipeline_stage.v`, `pipeline_register.v`, `control_unit.v`,
`riscv_pipeline.v` dùng chung với `integrated-matrix-extension/core/`. P2c (cùng
R2) phải vá song song sang cây đó, nếu không hai bản core lệch nhau.

**Vấn đề (ghi lại nguyên văn thiết kế gốc).** FSM hiện tại: `IDLE -> LOOKUP -> AW_REQ -> W -> B_WAIT -> IDLE`, và
`dcache_stall = 1` suốt đoạn đó. Mỗi lệnh `sw` đều stall core trọn một vòng AXI
round-trip **qua cầu bất đồng bộ 400 sang 200 MHz**. Vòng lặp ghi mảng chạy ở tốc
độ `clk_axi`, không phải `clk_cpu` — 400 MHz gần như vô nghĩa với code store-heavy.

**Thiết kế đề xuất.** FIFO 2–4 entry `{addr, data, strb, size, is_device}` đặt giữa
LOOKUP và kênh AW/W:

- Write **hit** trên vùng cacheable: cập nhật mảng SRAM (đã làm), đẩy vào FIFO,
  `dcache_hit = 1` ngay để core đi tiếp. Chỉ stall khi FIFO đầy.
- Write **miss** (no write-allocate): đẩy thẳng vào FIFO, không đụng mảng.
- Load: với vùng cacheable, mảng SRAM đã được cập nhật nên load hit đọc đúng giá
  trị mới, **không cần forwarding**. Chỉ cần chặn trường hợp load *miss* trùng địa
  chỉ với entry đang chờ — đơn giản nhất là **stall load cho tới khi FIFO rỗng**
  khi có miss.

**Điểm nguy hiểm nhất — thứ tự với MMIO.** Store vào vùng uncached (APB, CLINT, và
giờ cả RAM `hi`) **không được đệm** một cách vô tư: ghi thanh ghi thiết bị phải
hoàn tất theo đúng thứ tự và phải nhìn thấy được trước khi đọc thanh ghi kế tiếp.
Quy tắc bắt buộc:

> `is_device = uncache_en_i` thì FIFO chạy chế độ **write-through nghiêm ngặt**:
> không nhận entry mới cho tới khi B response của entry device về.

Bỏ qua điều này thì driver UART/SPI/I2C sẽ hỏng theo kiểu rất khó lần ra.

**Rủi ro.** Thay đổi khoảng 200 dòng vào một FSM đang chạy đúng, có nguy cơ deadlock
thật. Testbench hiện tại **không có một phép thử nào về thứ tự store** — nên nếu
làm hỏng, không có gì bắt được.

**Verify bắt buộc trước khi merge.**

1. Directed test: chuỗi `sw` liên tiếp vào RAM lo, đọc lại, so khớp.
2. Directed test: `sw` vào thanh ghi APB rồi `lw` ngay thanh ghi đó, kiểm tra không
   bị vượt thứ tự.
3. Test FIFO đầy, stall, drain.
4. Chạy lại firmware TB (đường UART là bài test MMIO ordering thật).

**Lợi ích ước tính.** Đây là cải thiện hiệu năng lớn nhất trên toàn chip, hơn hẳn
mọi mục còn lại cộng lại.

### Phase 2 — Đường DMA và debug vào TCM (P3)

**Vấn đề.** TCM nằm hoàn toàn ngoài AXI: `0x0002_xxxx` không có trong
`SLV_BASE_ADDR`, nên mọi AXI master nhắm vào đó nhận DECERR. Hệ quả:

- **DMA không nạp được dữ liệu vào DTCM.** Phải copy bằng CPU từng word qua cổng
  load/store. Điều này **triệt tiêu use case chính** ghi trong comment của chính
  `tcm.v` ("DSP/CNN inner loops"): mô hình chuẩn là DMA đổ tile vào TCM trong khi
  CPU tính trên tile trước (double buffering). Kiến trúc hiện tại không cho phép.
- **Debugger không đọc được TCM.** DTM/SBA là AXI master nên cũng DECERR. Nếu đặt
  stack ở DTCM thì GDB không hiện được backtrace, không xem được biến local.

**Ba phương án.**

| # | Cách làm | Chi phí | Ghi chú |
|---|---|---|---|
| A | Thêm slave port AXI thứ 3 cho TCM (`SLV_AMT` 7 lên 8), arbiter 3 cổng trong `tcm.v` | Crossbar rộng thêm, `SLV_ID_WIDTH` tăng, thêm CDC 400/200 | Đầy đủ nhất, đắt nhất |
| B | Chỉ mở cho **DMA**, qua cổng riêng không qua crossbar | Vừa | Được use case DSP, vẫn không debug được |
| C | Giữ nguyên, chuyển hẳn sang dùng **DMAPOOL uncached** cho streaming | 0 | Bỏ TCM khỏi luồng dữ liệu, TCM chỉ còn cho code |

**Khuyến nghị: cân nhắc nghiêm túc phương án C trước.** Sau Phase 0, `DMAPOOL`
128 KiB uncached đã giải quyết được phần lớn nhu cầu streaming của DMA mà **không
tốn thêm một cổng crossbar nào**. TCM khi đó giữ đúng vai trò nó làm tốt nhất:
chứa **code** ISR/inner-loop có latency tất định (`.itcm_text`) và biến trạng thái
nhỏ, nóng (`.dtcm_data`).

Nếu vẫn chọn A hoặc B thì phải trả lời trước: `SLV_AMT` 7 lên 8 làm rộng arbiter,
decoder, ROB và toàn bộ mux phía slave — **còn đủ slack không?** Chỉ Genus trả lời
được.

**Nếu không làm Phase 2:** phải ghi rõ vào tài liệu firmware rằng TCM là bộ nhớ
riêng của CPU, và **stack phải nằm ở RAM** (như firmware hiện tại đang làm) để
debug được.

### Phase 3 — Clock/power gating cho bộ nhớ (P4)

Dự án tên là *LowPower* nhưng bộ nhớ — khối chiếm 74% diện tích — chưa có biện
pháp tiết kiệm nào.

**3a. Gate `clk_axi` cho RAM `hi`.**

Sau Phase 0, nửa `hi` là pool DMA. Khi không có DMA chạy thì nó hoàn toàn nhàn rỗi
và có thể tắt clock.

**CẢNH BÁO: đây chính xác là loại thay đổi đã gây ra hai bug đã sửa trong dự án
này** (GPIO/CORDIC treo vì clock bị cắt giữa chừng). Nếu cắt clock của một AXI
slave khi còn transaction đang bay thì **treo cả system bus**. Bắt buộc dùng đúng
pattern đã kiểm chứng ở CORDIC:

```verilog
// axi_ram phải xuất ra o_busy = (state != S_IDLE)
assign ram_hi_clk_req = s6_selected | ram_hi_busy;
clock_gate cg_ram_hi (.clk_in(clk_axi),
                      .en(clk_en_ram_hi | ram_hi_clk_req), ...);
```

`clk_gate_reg` trong `apb_syscon` hiện dùng **hết cả 8 bit** `[7:0]`
(0 pwm, 1 uart, 2 spi, 3 i2c, 4 gpio, 5 acc, 6 dbg, **7 ascon** — thêm
2026-09-10, reset vẫn `0x43`). RAM `hi` sẽ cần bit 8: nới thanh ghi lên 9 bit,
giữ reset value, và cập nhật cả tài liệu thanh ghi lẫn `Driver/inc/syscon.h`.
Thêm clock gate mới cũng phải thêm một `make_gated_clock` trong
`tcl/constraint.sdc` và tăng `EXPECTED_CLOCKS` trong `tcl/genus.tcl` — ASCON
từng quên bước này (đã sửa 2026-09-11).

**3b. ICG per-bank trong `asap7_sram_1rw`.**

Hiện tại chân `clk` đi tới **cả 64 macro không điều kiện**; `banksel` chỉ chặn hoạt
động bên trong chứ không chặn clock pin. 64 macro toggle ở 200 MHz là clock power
thật và có thể cắt bằng một ICG mỗi bank lấy `banksel` làm enable.

**CẢNH BÁO:** đây là thay đổi **nhạy với physical design** — thêm 64 ICG vào clock
tree, và `banksel` là decode tổ hợp từ địa chỉ nên phải kiểm tra nó ổn định trước
cạnh lên. **Không được làm nếu chưa chạy lại được CTS và STA.**

### Phase 4 — ECC/parity (P5)

344 KiB SRAM ở node 7 nm, không có ECC cũng không có parity. Với dự án học
thuật/IoT thì đây là đánh đổi chấp nhận được, **nhưng phải là đánh đổi có ý thức và
được ghi lại**, không phải bỏ sót. Nếu sau này hướng tới sản phẩm thật:

- Tối thiểu: parity trên I-cache và tag array (lỗi thì invalidate + refetch, rẻ).
- Đầy đủ: SECDED trên system RAM (thêm khoảng 12.5% macro cho dữ liệu 32-bit).

---

## 5. Nợ verification — ĐÃ TRẢ

`genus/rtl/tests/tb_mem_paths.sv` (chạy bằng `run_soc_sim.sh mem`) phủ toàn bộ
danh sách nợ. Số check tăng theo từng phase:

| Mốc | Check | Thêm gì |
|---|---|---|
| Đóng Phase 0 (2026-09-05) | 99 / 99 | T0–T9, TP |
| Phase 1 store buffer (2026-09-08) | 109 / 109 | TS |
| R1b/R11 AMO (2026-09-10) | 121 / 121 | T10a–d |
| P2c `fence` (2026-09-11) | **128 mong đợi — chưa chạy** | TF |

| Cần thêm | Nhóm | Trạng thái |
|---|---|---|
| Directed test đọc/ghi `0x2002_0000` (RAM hi) | T1, T2 | Xong |
| Directed test ghi rồi đọc ITCM/DTCM | T3, T4 | Xong |
| DMA ghi DMAPOOL rồi CPU đọc lại | T6 | Xong |
| Store ordering vào MMIO | T7 | Xong |
| Fetch từ ITCM sau khi copy code | T4 | Xong |
| Trọng tài port F/D của TCM (`f_starved`) | T5 | Xong |
| Đường ghi/đọc của debugger (DTM/SBA) | T9 | Xong |
| D-cache có thật sự hit không (đo độ trễ) | TP | Xong |
| Store buffer: retire 1 chu kỳ, không mất entry, dữ liệu tới RAM | TS | Xong |
| `fence` chờ khi buffer có dữ liệu, không chờ khi rỗng | TF | Viết xong, chờ sim |
| AMO hit / miss (R1b, R11), bằng chứng qua SBA | T10a–d | Xong (có negative control) |
| AMO vào vùng uncached | T10e | Chỉ quan sát — lộ ra R12 |

### 5.1 Testbench này làm việc thế nào

Không cần firmware, nên không cần toolchain RISC-V (máy này không có). Testbench
`force` thẳng các chân core-side của `top_soc` và **đóng vai CPU**:

```
cpu_inst_req / cpu_inst_addr             -> port fetch
cpu_data_rd_req / cpu_data_wr_req / ...  -> port load/store
cpu_data_fence                           -> fence (P2c)
cpu_data_amo_req + mux wdata             -> tầng MEM của lệnh nguyên tử (R1b)
sba_req / sba_op / sba_size / sba_addr   -> System Bus Access của Debug Module
```

Mỗi transaction là một lệnh RISC-V đơn lẻ do testbench chọn, nhưng nó đi qua
đúng decode `SOC_IS_UNCACHED` / `SOC_IS_ITCM` / `SOC_IS_DTCM` thật, qua D-cache
thật, qua AXI interconnect thật. DMA được cấu hình bằng chính đường store
uncached đó (`0x4000_8000`), nên không có mô hình giả nào trong vòng lặp.

### 5.2 Hai điều chỉ đo độ trễ mới thấy

**D-cache có hit không.** Không bài test chức năng nào phân biệt được hit với
miss: cả hai đều trả về đúng giá trị, chỉ khác tốc độ. Một cache không bao giờ
allocate vẫn "chạy đúng" và vẫn im lặng làm chip chậm hàng chục lần. Nhóm TP đếm
số sườn lên `clk_cpu` từ lúc phát request tới lúc thấy `hit` — tức đúng bằng số
chu kỳ trừ một, vì request được đặt ở sườn xuống trước đó:

| | Số đo | Tổng chu kỳ |
|---|---|---|
| Hit | 1 | 2 (IDLE + LOOKUP, khớp mục 3 của MEMORY_ARCHITECTURE.md) |
| Miss | 57 | 58 (một vòng AXI qua CDC 400/200 cộng burst 4 beat) |

Ngưỡng trong testbench để rộng (hit ≤ 3, miss ≥ 10) nên nó bắt lỗi "không bao giờ
allocate" mà không vỡ khi số chu kỳ đổi vài đơn vị. Nó cũng kiểm tra `valid_arr`
của set liên quan phải khác 0.

Chính phép đo này bắt được một lỗi *của testbench* đáng ghi lại: bản đầu tiên hạ
`cpu_data_rd_req` ở sườn xuống ngay sau khi thấy `hit`. Lõi CPU thật có tín hiệu
đó là **đầu ra chốt** — nó chỉ hạ ở sườn lên kế tiếp, nên ở chính sườn đó các
flop trong dcache vẫn thấy request còn cao. Cập nhật `valid`/`tag` của một read
miss xảy ra đúng ở sườn ấy (`state == DONE && cpu_read_req`). Hạ sớm nửa chu kỳ
thì **không line nào được allocate** và mọi lần đọc đều miss. Bất kỳ testbench
nào sau này cưỡng bức cổng core đều phải giữ request qua trọn một sườn lên nữa.

**Hazard coherency có thật.** Nhóm T8 giữ một line cacheable trong D-cache, cho
DMA ghi đè địa chỉ đó trong RAM, rồi đọc lại: CPU vẫn đọc `1111_1111` trong khi
RAM đã là `2222_2222`. Đây là bằng chứng chạy được cho P0 — không phải suy luận —
và là lý do `.dmabuf` bắt buộc nằm ở DMAPOOL uncached.

### 5.3 Còn lại

- **P1b vẫn chưa làm:** firmware chưa có `.itcm_text` và `.dmabuf` thật. Máy này
  không có toolchain RISC-V (`riscv-none-elf-gcc`) nên không build lại được
  firmware. `tb_mem_paths.sv` đã chạy hai đường đó ở mức RTL, nhưng chuỗi
  crt0 → copy ITCM → nhảy vào ITCM thì chưa từng chạy thật.
- **Lint chưa chạy được:** máy không có `verilator`. Đã sửa `run_rtl_lint.sh`:
  nó đếm `**/*.v` gồm cả model hành vi trong `tests/models/` nên bất biến số
  file **không bao giờ khớp** và model sẽ bị nạp hai lần. Nay `tests/` bị loại,
  khớp đúng với filelist mà `run_soc_sim.sh` và Genus dùng. Con số là **58** từ
  khi thêm 3 file `apb_ascon/` (lint từng bị bỏ quên ở 55 — sửa 2026-09-11).

---

## 6. Chiến lược thực thi

```
Phase 0  --- XONG -----------------------------------  không cần Genus
   |         decode + linker, 0 rủi ro timing
   v
P6       --- XONG -----------------------------------  không cần Genus
   |         mã hoá store dưới 32 bit trên AXI; chỉ BỚT logic
   v
V1       --- XONG -----------------------------------  không cần Genus
   |         tb_mem_paths.sv, 99 check. Chính nó tìm ra P6.
   v
Phase 1  --- XONG (store buffer, P2b, P2c) ----------  lợi ích lớn nhất
   |         35 -> 1 chu kỳ/store, fw nhanh 1.85x. P2c chờ chạy lại sim.
   v
[GATE] Genus — ĐÃ CHẠY 2026-09-09 / 09-10 (tag cũ); đang chạy lại cho tag 128x4x20.
   |    TT dư +812 ps nhưng SS chỉ +1.3 ps (CPU) / +1.1 ps (AXI), trước CTS.
   |    Góc chậm vẫn bằng 0 -> xử lý timing trước khi thêm logic vào CPU/AXI.
   v
R12      --- AMO uncached -> trap -------------------  chặn chức năng, rẻ
   v
Phase 3a --- Gate clock RAM hi ----------------------  dùng pattern CORDIC/ASCON
   |         Cần test DMA vào RAM hi để chứng minh không treo bus.
   v
[QUYẾT ĐỊNH] Phase 2: chọn A / B / C.
   |    Mặc định nên là C (giữ nguyên, dùng DMAPOOL) trừ khi đo được rằng
   |    DMAPOOL uncached không đủ băng thông cho use case DSP.
   v
Phase 3b --- ICG per-bank ---------------------------  chỉ khi CTS/STA chạy được
   v
Phase 4  --- ECC ------------------------------------  chỉ nếu hướng sản phẩm
```

**Nguyên tắc xuyên suốt:**

1. **Không sửa RTL mà không chạy lại được synthesis.** Slack ở góc SS còn
   +1.3 ps (CPU) / +1.1 ps (AXI) nghĩa là không còn dư địa cho thay đổi mù.
2. **Test trước, sửa sau** với Phase 1 — vì đường store hiện đang đúng, và không có
   gì bắt được nếu nó thành sai.
3. **Mọi thay đổi clock gating phải dùng pattern `*_clk_req` đã kiểm chứng.** Dự án
   đã mất hai lần vì bài học này.
4. **Ưu tiên giải pháp bằng thuộc tính bộ nhớ hơn là bằng phần cứng thêm.** Phase 0
   sửa một lỗi chặn chức năng bằng đúng một dòng decode — đó là tỉ lệ lợi ích/rủi ro
   nên tìm trước tiên.

---

## 7. Bảng theo dõi

| ID | Việc | Phase | Trạng thái | File |
|---|---|---|---|---|
| P0 | RAM hi = uncached | 0 | Xong, đã verify (T1/T2/T6/T8) | `genus/rtl/top_soc.v` |
| P1 | Linker: DMAPOOL + ITCM/DTCM + sections | 0 | Xong | `Driver/ld/soc.ld` |
| P1b | Firmware dùng thật `.dmabuf` / `.itcm_text` | 0 | Chưa — máy không có toolchain RISC-V | `Driver/src/` |
| P6 | AWSIZE / căn địa chỉ / lane WDATA cho store dưới 32 bit | 0 | Xong, đã verify (T2/T6/T9) | `memory/dcache.v`, `debug/dtm_axi_master.v` |
| P2 | Store buffer D-cache | 1 | **Xong, đã verify (TS/T7/T9)** | `genus/rtl/memory/dcache.v`, `top_soc.v` |
| P2b | D-cache 4-way → 2-way, thu hồi 2 macro tag | 1 | **Xong, đã verify (TP)** | `top_soc.v`, `flow/project_config.tcl`, `tcl/genus.tcl` |
| P2c | `FENCE` xả store buffer | 1 | **Xong ở RTL (TF/T9/T10b viết xong) — chờ chạy lại `mem`, mong đợi 128/128** | `core/block_unit/control_unit.v`, `core/pipeline_register/`, `core/pipeline_stage/`, `core/riscv_pipeline.v`, `top_soc.v`, `memory/dcache.v` |
| R1a | Chốt payload W đường uncached | 1 | Xong, đã verify (T2/T6) | `memory/dcache.v` |
| R11 | AMO trượt cache retire mà không ghi | 1 | Xong, đã verify (T10b + negative control) | `memory/dcache.v` |
| R12 | AMO vào vùng uncached bị bỏ âm thầm | 1 | **Mở — cần quyết định A/B/C**, khuyến nghị B (trap) | `memory/dcache.v` |
| P3 | Đường DMA/debug vào TCM | 2 | Chờ quyết định A/B/C | `genus/rtl/memory/tcm.v`, `top_soc.v` |
| P4a | Gate clock RAM hi | 3 | Chưa — cần bit 8 của `CLK_GATE_CTRL` + clock SDC mới | `top_soc.v`, `peripheral/apb_syscon.v`, `tcl/constraint.sdc` |
| P4b | ICG per-bank | 3 | Chưa | `genus/rtl/memory/asap7_sram_1rw.v` |
| P5 | ECC/parity | 4 | Quyết định có ý thức: bỏ qua | — |
| V1 | Test RAM hi / TCM / DMA coherency / store ordering / AMO | mọi phase | **121/121 PASS (2026-09-10)**; +TF = 128 chờ chạy | `genus/rtl/tests/tb_mem_paths.sv` |
| V2 | Đếm file trong lint khớp filelist tổng hợp | — | Xong — **58** (sửa 2026-09-11) | `genus/rtl/tests/run_rtl_lint.sh` |
| — | Chạy `verilator` lint | — | Chưa chạy được — máy không có verilator | máy có verilator |
| — | Chạy Genus | GATE | **Đã chạy 2026-09-09, 2026-09-10** (cả hai với tag trên `256x4x32`). **Đang chạy lại** cho tag `128x4x20`. Lần sau cần thêm P2c + `CLK_ASCON` (19 clock) | máy có license |
| — | Innovus đến floorplan | GATE | Chưa chạy trên netlist mới | máy có license |
| B1 | Boot ROM 8 KiB mask ROM + mã boot tầng 1 | 8 | **Xong ở RTL (2026-09-11)** — mã ROM kiểm trên ISS Python, chưa chạy XSim | `memory/axi_rom.v`, `memory/boot.mem`, `top_soc.v`, `tcl/genus.tcl`, `memory/axi_spi_flash.v` |
| B2 | Firmware `fw` ≤ 8 KiB, hoặc link lại để XIP | 8 | **Chưa biết kích thước ảnh** — `gen_boot_rom.py` sẽ báo nếu vượt | `Driver/ld/soc.ld`, `Driver/tb_top_soc.v` |
| B3 | QSPI quad I/O + continuous read cho XIP | 8 | Chưa | `memory/axi_spi_flash.v` |
| B4 | Đường ghi/xoá flash (cập nhật firmware) | 8 | Chưa | `memory/axi_spi_flash.v` |
| B5 | Secure boot: ASCON-Hash ảnh + khoá/hash bất biến | 8 | Chưa — cần vùng "fuse" | `memory/boot.mem`, mới |
| R15 | Debug resume không đánh thức core đang ngủ WFI | 8 | Mở — ROM né bằng `j .` | `core/block_unit/pipeline_control_unit.v` |
| C10 | I-cache không invalidate được (`fence.i` illegal) | 8 | Mở | `memory/icache.v`, core |
| M1 | Bit valid của cache vào bit thừa của macro tag | 8 | Tuỳ chọn (~3 k flop) | `memory/icache.v`, `memory/dcache.v` |

---

## 8. Rà soát vùng nhớ toàn SoC (2026-09-11)

Câu hỏi: ngoài boot ROM, SoC còn chỗ nào **thiếu vùng nhớ**, hoặc có bộ nhớ nên
chuyển sang macro? Kết luận ngắn: **không còn khối nào nên thêm macro SRAM**. Thứ
còn thiếu là vài vùng *chức năng* mà một MCU thật có còn SoC này chưa có.

### 8.1 Boot ROM — đã sửa (B1)

Trước đây ROM là cửa sổ 64 KiB chỉ có 4 lệnh NOP. Sau đó CPU chạy vào `0x0000_0000`
(lệnh illegal), trap về `mtvec = 0`, rồi lặp access fault mãi, nên chip không tự boot
được. 56 KiB còn lại của cửa sổ alias lại ảnh ROM. Nay ROM là mask ROM 8 KiB chứa
mã boot tầng 1, phần còn lại của cửa sổ trả DECERR. Thiết kế, định dạng header
flash và lý do không dùng macro SRAM ở MEMORY_ARCHITECTURE.md mục 6.

### 8.2 Bộ nhớ đang là flop — có nên thành macro không?

Macro nhỏ nhất của generator là 64 hàng × 4 = 256 word, đều **1RW**, không reset
được, không có byte mask. Duyệt mọi mảng `reg [..] x [..]` trong RTL:

| Khối | Kích thước | Macro được không | Lý do |
|---|---|---|---|
| Register file | 32 × 32, 2R1W | Không | cần 2 cổng đọc + 1 ghi mỗi chu kỳ |
| FIFO CDC, FIFO W/ROB của interconnect | sâu 2–16 | Không | cần đọc + ghi cùng chu kỳ; dùng < 10 % macro nhỏ nhất |
| FIFO UART/SPI/I2C/DMA | 16 × ≤ 32 | Không | như trên |
| BTB/BHT | 16 entry | Không | đọc tổ hợp ngay trong chu kỳ fetch |
| Store buffer D-cache | 4 entry | Không | so địa chỉ song song trên mọi entry |
| **Valid + `rr_ptr` của hai cache** | 2 × (512×2 + 512) = **3 072 flop** | **Một phần (M1)** | xem dưới |

**M1.** Tag dài 19 bit nằm trong macro 20 bit, nên mỗi way còn đúng **1 bit thừa**,
đủ chứa bit valid. Đổi lại cần một vòng quét xoá 512 set sau reset (1.3 µs ở
400 MHz, cache stall trong lúc đó), vì macro không reset được. `rr_ptr` là trạng
thái chung của cả set nên không có chỗ; phải thay round-robin theo set bằng một
bộ đếm/LFSR toàn cục. Lợi: bớt tới ~3 000 flop (2 048 valid + 1 024 `rr_ptr`, ~7–8 %
số flop của netlist), có ích cho DFT và power. Không bắt buộc, chỉ nên làm cùng Phase G khi đằng nào cũng mở FSM cache.

### 8.3 Vùng chức năng còn thiếu

| ID | Thiếu | Hậu quả | Hướng |
|---|---|---|---|
| B2 | Firmware `fw` phải ≤ 8 KiB | Suite `fw` bake cả firmware vào ROM; ảnh lớn hơn thì `gen_boot_rom.py` dừng | Link firmware để XIP ở `0x3000_0000` với header mục 6; thêm model SPI flash vào `tb_top_soc` |
| B3 | XIP nhanh | Fast Read `0x0B` 1 bit ở 50 MHz: I-cache miss 16 B tốn cỡ 700 chu kỳ `clk_axi` | Quad I/O `0xEB` + continuous read; cân nhắc SPI 100 MHz |
| B4 | Ghi/xoá flash | Kênh ghi của `axi_spi_flash` chỉ trả SLVERR, APB SPI dùng chân riêng. Không cập nhật firmware được khi đã ra board | Thêm chế độ lệnh trực tiếp (thanh ghi APB) cho `axi_spi_flash`, như SSI direct mode của RP2040 |
| B5 | Vùng bất biến cho root of trust | Không có chỗ lưu khoá/hash để ROM kiểm ảnh (ASCON-Hash có sẵn). ASAP7 không có OTP/eFuse | Một khối "fuse" mask-programmed như ROM (hash công khai của khoá ký), đọc được qua APB |
| C10 | Invalidate I-cache | `fence.i` illegal. Chép code vào RAM **lần thứ hai** (overlay, OTA vào RAM) rồi chạy thì I-cache có thể trả code cũ. Lần chép đầu của ROM an toàn vì I-cache còn lạnh | Cổng invalidate toàn bộ I-cache + hiện thực `fence.i` |
| — | RAM giữ dữ liệu khi ngủ sâu | Chưa có power domain (UPF). Nếu sau này tắt nguồn SRAM khi ngủ thì không còn gì giữ lại | Vài trăm byte flop trong miền RTC/AON (backup registers kiểu STM32), chỉ có nghĩa khi đã có power intent |
| P3 | DMA/debugger vào TCM | Đã có ở Phase 2 | — |

### 8.4 Ghi chú phụ tìm được khi rà (không phải vùng nhớ)

**R15 — debug resume không đánh thức core đang ngủ WFI.** `sleeping_reg` trong
`pipeline_control_unit.v` chỉ xoá bằng ngắt đã bật (`wake_interrupt`). OpenOCD
`halt` một core đang ngủ, nạp chương trình, rồi `resume`, thì core vẫn ngủ
(`fetch_enable = 0`) và không chạy code ở `dpc`. Firmware `fw` kết thúc bằng WFI nên
gặp đúng trường hợp này. Sửa đề xuất: xoá `sleeping_reg` khi `dbg_halted_reg`
(đặc tả cho phép WFI kết thúc sớm vì bất kỳ lý do gì). Chưa sửa, chưa có test.
