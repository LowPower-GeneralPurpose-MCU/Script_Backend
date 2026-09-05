# Kế hoạch sửa memory subsystem

**Ngày:** 2026-09-05 · **Trạng thái:** Phase 0 xong · nợ verification đã trả ·
P6 (mã hoá store dưới 32 bit trên AXI) tìm ra và sửa · Phase 1–4 vẫn chờ Genus

Tài liệu chị em với [MEMORY_ARCHITECTURE.md](MEMORY_ARCHITECTURE.md). File đó ghi
**lý do của các quyết định đã chốt**; file này ghi **những gì còn sai hoặc còn
thiếu**, cái nào đã sửa, cái nào chưa và **tại sao chưa**, kèm thiết kế cụ thể để
thực thi khi có công cụ synthesis.

---

## 1. Hiện trạng

### 1.1 Bản đồ địa chỉ

| Vùng | Địa chỉ | Kích thước | Đường đi | Thuộc tính |
|---|---|---|---|---|
| Boot ROM (s0) | `0x0001_0000` | 64 KiB | AXI | cacheable |
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

| Khối | Macro | Dung lượng |
|---|---|---|
| System RAM (2 x 128 KiB) | 64 | 256 KiB |
| I-cache 16 KiB, 2-way | 6 | 24 KiB |
| D-cache 16 KiB, 4-way | 8 | 32 KiB |
| ITCM | 4 | 16 KiB |
| DTCM | 4 | 16 KiB |
| **Tổng** | **86** | **344 KiB** |

System RAM chiếm **74%** số macro. Đây là khối chi phối diện tích die.

### 1.3 Đặc tính cache

- **D-cache**: 16 KiB, 4-way, block 16 B, **write-through, no write-allocate**,
  không dirty bit, **không có store buffer**, **không có cổng invalidate/flush/CMO**.
- **I-cache**: 16 KiB, 2-way, block 16 B.
- **TCM**: đọc 2 chu kỳ · ghi word 2 chu kỳ · ghi byte/halfword **3 chu kỳ**
  (read-modify-write, vì macro không có byte-write mask). Ưu tiên cố định D > F.

---

## 2. Danh sách vấn đề

| ID | Vấn đề | Mức | Phase |
|---|---|---|---|
| **P0** | DMA ghi thì CPU đọc ra dữ liệu cũ (không có coherency, không có vùng uncached cho RAM) | Chặn chức năng | **0 — xong** |
| **P1** | Nửa RAM `hi` và cả ITCM/DTCM không có trong linker, 40/86 macro là silicon chết | Lãng phí | **0 — xong (cơ chế)** |
| **P2** | D-cache không có store buffer, mỗi store stall core trọn một vòng AXI qua CDC 400 sang 200 | Hiệu năng | 1 |
| **P3** | DMA và debugger không với tới được TCM | Giới hạn kiến trúc | 2 |
| **P4** | Không có clock gating riêng cho RAM `hi`; 64 macro toggle clock vô điều kiện | Ngược mục tiêu LowPower | 3 |
| **P5** | Không có ECC/parity trên 344 KiB SRAM | Chấp nhận có ý thức | 4 |
| **P6** | `sb`/`sh` và `lb`/`lh` uncached bị slave từ chối im lặng — dữ liệu mất | Chặn chức năng | **0 — xong** |

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

## 4. Phase 1–4 — CHƯA SỬA, kèm thiết kế

> **Điều kiện tiên quyết chung: phải chạy lại Genus.**
> Netlist hiện tại (`genus/outputs/top_soc_syn.v`) có trước cả đợt rework
> cache/SRAM, và slack `CLK_CPU` lần đo cuối chỉ **+5.5 ps** ở 400 MHz — tức bằng
> không. Mọi thay đổi dưới đây đều đụng vào đường tới hạn hoặc vào crossbar. Sửa
> mù mà không biết còn bao nhiêu slack là đánh bạc với tape-out. Máy đang dùng
> **không có Cadence Genus**, nên các phase này phải làm trên máy có license.

### Phase 1 — Store buffer cho D-cache (P2)

**Vấn đề.** FSM hiện tại: `IDLE -> LOOKUP -> AW_REQ -> W -> B_WAIT -> IDLE`, và
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

`clk_gate_reg` trong `apb_syscon` hiện dùng **hết cả 7 bit** `[6:0]`
(0 pwm, 1 uart, 2 spi, 3 i2c, 4 gpio, 5 acc, 6 dbg) nên phải nới lên 8 bit và cập
nhật cả tài liệu thanh ghi lẫn driver.

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
danh sách nợ. 99 check, tất cả PASS.

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

### 5.1 Testbench này làm việc thế nào

Không cần firmware, nên không cần toolchain RISC-V (máy này không có). Testbench
`force` thẳng các chân core-side của `top_soc` và **đóng vai CPU**:

```
cpu_inst_req / cpu_inst_addr             -> port fetch
cpu_data_rd_req / cpu_data_wr_req / ...  -> port load/store
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
  nó đếm `**/*.v` gồm cả model hành vi trong `tests/models/` nên bất biến "55
  file" **không bao giờ khớp** (đếm ra 56) và model sẽ bị nạp hai lần. Nay
  `tests/` bị loại, khớp đúng với filelist mà `run_soc_sim.sh` và Genus dùng.

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
[GATE] Chạy lại Genus. Ghi lại slack CLK_CPU và số macro.
   |    Nếu slack đã âm thì DỪNG, xử lý timing trước, đừng thêm tính năng.
   v
Phase 1  --- Store buffer ---------------------------  lợi ích lớn nhất
   |         Viết test store-ordering TRƯỚC khi sửa RTL.
   v
Phase 3a --- Gate clock RAM hi ----------------------  dùng pattern CORDIC
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

1. **Không sửa RTL mà không chạy lại được synthesis.** Slack +5.5 ps nghĩa là
   không còn dư địa cho thay đổi mù.
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
| P2 | Store buffer D-cache | 1 | Chưa | `genus/rtl/memory/dcache.v` |
| P3 | Đường DMA/debug vào TCM | 2 | Chờ quyết định A/B/C | `genus/rtl/memory/tcm.v`, `top_soc.v` |
| P4a | Gate clock RAM hi | 3 | Chưa | `top_soc.v`, `peripheral/apb_syscon.v` |
| P4b | ICG per-bank | 3 | Chưa | `genus/rtl/memory/asap7_sram_1rw.v` |
| P5 | ECC/parity | 4 | Quyết định có ý thức: bỏ qua | — |
| V1 | Test RAM hi / TCM / DMA coherency / store ordering | mọi phase | **Xong, 99/99 PASS** | `genus/rtl/tests/tb_mem_paths.sv` |
| V2 | Đếm file trong lint khớp filelist tổng hợp | — | Xong | `genus/rtl/tests/run_rtl_lint.sh` |
| — | Chạy `verilator` lint | — | Chưa chạy được — máy không có verilator | máy có verilator |
| — | **Chạy lại Genus** | GATE | **Chặn mọi phase sau** | máy có license |
