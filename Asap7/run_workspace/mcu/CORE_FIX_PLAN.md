# Kế hoạch sửa core + hiệu năng

Tài liệu song song với [MEMORY_FIX_PLAN.md](MEMORY_FIX_PLAN.md). Chỗ kia lo hệ
thống bộ nhớ; chỗ này lo **tính đúng đắn của core so với đặc tả RISC-V** và
**hiệu năng**.

Cùng quy ước: ghi rõ cái gì sai, **tại sao** nó sai, sửa thế nào, và verify bằng gì.

---

## 1. Lưới an toàn

Mọi thay đổi trong tài liệu này phải giữ nguyên ba kết quả baseline, đo ngày
2026-09-05 **trước** khi sửa bất cứ thứ gì:

```
bash genus/rtl/tests/run_soc_sim.sh all
```

| Testbench | Baseline |
|---|---|
| `apb` — `Test_bench/SoC_testbench.sv` | **PASS 256 / FAIL 0** |
| `fw` — `Driver/tb_top_soc.v` | **PASS** — UART in `HELLO RISC-V UART TEST!`, CPU tới WFI (2026-09-08 sau Phase F: **t = 1 528 046 000 ns**, trước đó 2 831 456 000) |
| `mem` — `genus/rtl/tests/tb_mem_paths.sv` | **PASS 99 / FAIL 0 / TIMEOUT 0** (2026-09-08: **109/109** sau Phase F) |

Ba bộ này **không** phủ được exception, CSR conformance hay dự đoán nhánh. Mỗi
phase dưới đây vì vậy phải kèm testcase riêng, nếu không thì "không có gì bắt
được khi làm hỏng" — đúng bài học đã ghi ở `MEMORY_FIX_PLAN.md` mục Phase 1.

Một số đo hữu ích lấy từ baseline `mem`:

```
doc lan 1 (miss, nap line): sau 57 chu ky      <- D-cache read miss = 57 chu ky clk_cpu
doc sau khi DMA ghi:        sau 1 chu ky
```

Sau Phase F (store buffer, 2026-09-08) hai số này đổi thành:

```
store cacheable retire:     1 chu ky            <- truoc do 35 chu ky
doc lan 1 (miss, nap line): sau 90 chu ky       <- read miss phai cho buffer xa
```

---

## 2. Danh sách vấn đề

### 2.1. Đúng đắn (mục 3 của bản đánh giá)

| ID | Vấn đề | Mức | Phase |
|---|---|---|---|
| **C1** | Cache **vứt bỏ** `RRESP`/`BRESP` → không có access fault (mcause 1/5/7) | Chặn debug | B |
| **C2** | Không có exception misaligned load/store (mcause 4/6) | Sai đặc tả | B |
| **C3** | `mtvec` không mask bit MODE, không hỗ trợ vectored | Chặn firmware | A |
| **C4** | `time`/`timeh` alias vào `mcycle` → sai hệ số ~12200 lần | Chặn RTOS | A |
| **C5** | Đọc CSR không tồn tại trả 0 im lặng thay vì illegal | Sai đặc tả | A |
| **C6** | CSR debug (`dcsr`/`dpc`/`dscratch0`) truy cập được từ M-mode | Sai đặc tả + bảo mật | A |
| **C7** | Ghi `dpc` bằng lệnh CSR không bị `trap_enter` chặn → commit một nửa | Sai | A |
| **C8** | `SYSCON.RESET_VECTOR` là thanh ghi chết | Gây hiểu nhầm | D |
| **C9** | Không có PMP | Giới hạn kiến trúc | — (ngoài phạm vi) |

### 2.2. Hiệu năng (mục 4 của bản đánh giá)

| ID | Vấn đề | Mức | Phase |
|---|---|---|---|
| **P1** | `pc + (compressed ? 2 : 4)` đặt **mux trước adder**, nguồn là dữ liệu cache → ripple-carry chiếm 58 % đường tới hạn | Timing | C |
| **P2** | BTB 16 entry, BHT 16 entry index `pc[5:2]`, **không có RAS** → mọi `ret` mispredict | IPC | D |
| **P3** | MUL 10 chu kỳ / DIV ~19 chu kỳ | IPC (DSP) | E |
| **P4** | D-cache không có store buffer → mỗi store ~25–35 chu kỳ | IPC | **F — xong (35 → 1)** |
| **P5** | Cache là FSM request/response, 2 chu kỳ/lệnh kể cả hit → **IPC trần 0.5** | IPC | G |

Thứ tự thực thi có chủ đích: **A → B → C → D → E**, rồi mới **F → G**.
F (store buffer) không có tác dụng thật nếu G chưa làm, vì IPC vẫn bị kẹp ở 0.5.
G là rework lớn nhất và phải làm sau cùng, khi mọi thứ khác đã ổn định và đã có
test phủ exception.

---

## 3. Phase A — CSR conformance

Toàn bộ nằm trong `genus/rtl/core/register_file/register_file.v` (module
`csr_register_file`) cộng vài dòng ở `riscv_pipeline.v`.

### A1 — `mtvec` WARL + chế độ vectored (C3)

**Sai ở đâu.** `mtvec <= csr_write_data;` giữ nguyên bit [1:0], và
`instruction_fetch` dùng `pc_out = mtvec_in` thẳng. Firmware ghi
`mtvec = base | 1` (chế độ VECTORED — FreeRTOS và nhiều BSP làm thế) sẽ nhảy
vào `base + 1`.

**Sửa.**

1. Ghi theo WARL: chỉ nhận MODE 0 (direct) và 1 (vectored), ép 2–3 về 0.
   ```verilog
   12'h305: mtvec <= {csr_write_data[31:2], 1'b0, csr_write_data[0]};
   ```
2. `riscv_pipeline` tính địa chỉ vector rồi mới đưa vào IF, nên `instruction_fetch`
   không phải đổi:
   ```verilog
   wire [31:0] mtvec_base = {mtvec_pc[31:2], 2'b00};
   wire        mtvec_vec  = mtvec_pc[0];
   // Chi INTERRUPT moi duoc vector hoa; exception luon vao base (dac ta).
   wire [31:0] trap_vector = (mtvec_vec && trap_cause[31])
                           ? (mtvec_base + {25'b0, trap_cause[4:0], 2'b00})
                           : mtvec_base;
   ```
   Bộ cộng thêm vào nằm ở nhánh `trap_enter` của mux PC — một cone riêng, ngắn,
   không đụng đường tới hạn `seq_pc` (xem P1).

### A2 — `time` / `timeh` (C4)

**Sai ở đâu.** `0xC01`/`0xC81` được alias vào `mcycle`. `time` theo đặc tả là
`mtime` của CLINT (32.768 kHz), không phải bộ đếm chu kỳ 400 MHz.

**Vì sao không nối thẳng CLINT vào core.** `mtime` là bộ đếm **64 bit** ở miền
`clk_axi`, core ở `clk_cpu`. Đưa 64 bit qua CDC cần Gray hoặc handshake; làm ẩu
thì đọc ra giá trị rách nửa trên/nửa dưới — một lớp bug tệ hơn cả bug đang sửa.

**Sửa.** Bỏ `0xC01`/`0xC81` khỏi bảng CSR để chúng rơi vào nhánh "CSR không tồn
tại" (A3) và raise illegal-instruction. Đây là hành vi chuẩn của core không có
Zicntr đầy đủ: firmware bắt trap và đọc `mtime` qua MMIO tại `0x0200_BFF8`.
Phải ghi vào tài liệu firmware.

### A3 — CSR không tồn tại → illegal-instruction (C5)

**Sai ở đâu.** `default: csr_read_value = 32'b0;`. Đặc tả bắt buộc truy cập CSR
không hiện thực phải raise illegal — đây là cách phần mềm dò năng lực phần cứng.
Hiện tại `csrr t0, mcountinhibit` / `pmpcfg0` / `mstatush` trả 0 và firmware
tưởng chúng tồn tại. Mỉa mai là hướng **ghi** đã làm rất kỹ (`csr_illegal_write`)
còn hướng **đọc** thì bỏ ngỏ.

**Sửa.** Thêm function `csr_exists(addr)` và output mới `csr_illegal_addr`:

```verilog
assign csr_illegal_addr = csr_write_en && !csr_exists(csr_write_addr);
```

`csr_write_en` ở đây thực chất là `ex_mem_csr_we`, mà `instruction_decode` định
nghĩa là "**đây là một lệnh CSR**" (đọc hoặc ghi) chứ không phải "lệnh này ghi" —
nên nó phủ đúng cả `csrr`. Tín hiệu đã ở tầng EX/MEM nên `mepc`/`mtval` tự đúng,
giống hệt `csr_illegal_write`.

> **Bất biến phải giữ:** thêm CSR mới = sửa **ba** chỗ — `csr_read_value`, danh
> sách nhạy của always block, và `csr_exists`. Quên chỗ thứ ba = CSR mới bị báo
> illegal.

### A4 — CSR debug chỉ truy cập được trong Debug Mode (C6)

`0x7B0`–`0x7B2` theo đặc tả chỉ tồn tại khi hart đang ở debug mode. Hiện tại
firmware M-mode ghi được `dcsr` — kể cả bit `step`. Cho `csr_exists` trả 0 cho
nhóm này khi `!dbg_halted`. Không ảnh hưởng OpenOCD: nó đi qua cổng
`dbg_reg_write_en` riêng, không qua pipeline.

### A5 — chặn ghi `dpc` khi đang nhận trap (C7)

Nhánh `else if (csr_write_en && csr_op != 0 && csr_write_addr == 12'h7b1)` nằm
**ngoài** chuỗi `if (trap_enter) ... else if (csr_write_en)`, nên một lệnh
`csrw dpc` bị trap vẫn ghi thật rồi chạy lại sau `mret` → ghi hai lần. Đúng cùng
một lớp lỗi với "KHOAN NO C" đã sửa cho `sw` ở `memory_access`. Thêm
`&& !trap_enter`.

### A6 — hệ quả không lường trước: `crt0.S` ghi `fcsr`

A3 bắt được một bug **thật** trong firmware ngay lần chạy đầu.

`Driver/inc/soc_config.h` đặt `CONFIG_HAS_FPU 1`, nên khối được guard trong
`Driver/startup/crt0.S` được biên dịch vào ảnh:

```
10010:  00301073   csrw  fcsr, zero        # CSR 0x003 - thuoc F extension
```

Core này không có F (`ENABLE_FPU = 0`, `ENABLE_F_EXTENSION = 0`, MISA không khai
bit F). Trước A3, lệnh đó rơi vào nhánh `default` của bảng CSR và **im lặng
không làm gì**. Sau A3 nó raise illegal-instruction đúng đặc tả — ở **lệnh thứ
tư của crt0**, tức **trước khi `mtvec` được set**. `mtvec` còn bằng 0 nên CPU
nhảy vào địa chỉ 0 và đi lang thang; log `fw` cho thấy `pc=00004644
inst=00000000` tăng đều 2 byte một.

Đây là **nửa còn lại của chính bug MISA** mà dự án đã sửa: MISA đã bỏ bit F,
còn build config thì chưa.

**Đã sửa:**

* `Driver/inc/soc_config.h` — `CONFIG_HAS_FPU` 1 → 0.
* `Driver/my_soc_firmware_word.mem` — word `@00000004` từ `00301073` thành
  `00000013` (NOP). Máy này không có toolchain RISC-V nên không build lại được;
  vá đúng một word **giữ nguyên layout**, nên mọi địa chỉ khác không đổi — an
  toàn hơn cho mục đích regression so với một lần build lại.

> **VIỆC CÒN LẠI:** build lại firmware trên máy có `riscv-none-elf-gcc` để ảnh
> `.mem`/`.hex`/`.bin`/`.elf` khớp lại với source. Bản vá một word chỉ là cầu tạm.

Hai lệnh còn lại của khối FPU (`lui t0,0x6` + `csrs mstatus,t0`) được giữ nguyên:
đường ghi `mstatus` trong `register_file.v` chỉ nhận bit [3], [7], [12:11] nên
trường FS bị bỏ qua — vô hại, không trap.

### Verify Phase A

Testbench mới `genus/rtl/tests/tb_core_traps.sv`. Tối thiểu:

1. `csrw mtvec, base|1` rồi bật timer interrupt → PC phải vào `base + 4*7`.
2. `csrw mtvec, base|2` (MODE reserved) → đọc lại `mtvec` phải thấy MODE = 0.
3. `csrr t0, time` → `mcause` = 2, `mtval` = mã lệnh.
4. `csrr t0, pmpcfg0` → `mcause` = 2.
5. `csrr t0, mcycle` → **không** trap.
6. `csrw dcsr` từ M-mode → `mcause` = 2.

---

## 4. Phase B — Bảng exception đầy đủ

### B1 — Misaligned load/store, mcause 4 / 6 (C2)

**Sai ở đâu.** Không có kiểm tra căn lề nào. `lw` vào địa chỉ lệch 1 byte đi
thẳng vào cache và cho ra kết quả sai, không exception nào để RTOS bắt.

**Sửa.** Trong `riscv_pipeline.v` (nơi đã có sẵn `ex_mem_alu_result`,
`ex_mem_mem_size`, `ex_mem_valid`):

```verilog
wire mem_ms_w = (ex_mem_mem_size == 2'b10) && (ex_mem_alu_result[1:0] != 2'b00);
wire mem_ms_h = (ex_mem_mem_size == 2'b01) &&  ex_mem_alu_result[0];
wire mem_misaligned = ex_mem_valid && (mem_ms_w || mem_ms_h);
wire trap_ld_misaligned = mem_misaligned && ex_mem_mem_read  && !ex_mem_mem_write;
wire trap_st_misaligned = mem_misaligned && ex_mem_mem_write;
```

`mtval` = địa chỉ gây lỗi (đặc tả cho phép).

**Điểm phải cẩn thận:** truy cập gây lỗi **không được phát ra bus**. `commit_kill`
(= `trap_enter`) đã chặn `dcache_write_req`, nhưng `dcache_read_req` thì chưa —
comment cũ nói "đọc lại là vô hại". Với địa chỉ lỗi thì không vô hại: cache sẽ
kéo `dcache_stall` lên, `mem_freeze` chặn `flush_trap`, và trap bị hoãn tới khi
giao dịch rác chạy xong. Vì vậy phải đổi thành:

```verilog
assign dcache_read_req = ex_mem_mem_read & ~commit_kill;
```

Không tạo vòng tổ hợp: `trap_enter` chỉ phụ thuộc thanh ghi `ex_mem_*`, không
phụ thuộc `dcache_stall`.

### B2 — Bus error → access fault, mcause 5 / 7 (C1, đường dữ liệu)

**Sai ở đâu.** `dcache.v` và `icache.v` có dòng

```verilog
wire _unused_ok = &{1'b0, m_axi_bid, m_axi_bresp, m_axi_rid, m_axi_rresp};
```

tức **chủ động vứt bỏ** phản hồi lỗi. Interconnect trả DECERR cho địa chỉ không
map, `axi_ram` trả SLVERR cho địa chỉ lệch word, APB default slave trả `pslverr`
— tất cả bay hơi. Toàn bộ hạ tầng phát hiện lỗi ở phía bus đã có, chỉ thiếu dây
nối tới CPU.

**Sửa (D-cache).** Chốt lỗi trong FSM, xuất ra ở state `DONE`:

```verilog
reg bus_err_r;
// IDLE: xoa;  R_WAIT: |= m_axi_rresp[1];  B_WAIT: |= m_axi_bresp[1]
assign dcache_error = (state == DONE) && bus_err_r && (cpu_addr == req_addr);
```

Và **không cập nhật tag khi lỗi** — nếu không thì line rác được đánh dấu hợp lệ
và lần đọc sau hit vào dữ liệu sai mà không còn lỗi nào để báo:

```verilog
if (cpu_read_req && !uncache_en && !bus_err_r) way_update[victim_way] = 1'b1;
```

`dcache_error` là xung đúng một chu kỳ, đúng chu kỳ `dcache_stall` hạ, nên lệnh
gây lỗi vẫn còn ở tầng MEM → `mepc`/`mtval` tự đúng.

### B3 — Instruction access fault, mcause 1 (C1, đường lệnh)

I-cache báo lỗi lúc **fetch**, nhưng trap phải nhận ở **MEM**. Cần một bit đi
suốt pipeline, y hệt bit `illegal_instr` đã có sẵn:

```
icache_error -> instr_fault -> if_id_fault -> id_ex_fault -> ex_mem_fault
```

Ba thanh ghi pipeline (`if_id_register`, `id_ex_register`, `ex_mem_register`)
đều đã có mẫu để chép: bit `illegal` phải bị **xoá khi flush** (bong bóng không
được mang lỗi) và **giữ khi stall**.

`mtval` = PC gây lỗi.

### Verify Phase B

`tb_mem_paths.sv` đã có sẵn cơ chế "đóng vai CPU" bằng `force` — đúng thứ cần.
Thêm:

1. `lw` từ `0x9000_0000` (không slave nào map) → `mcause` = 5, `mtval` = địa chỉ.
2. `sw` vào ROM `0x0001_0000` → `mcause` = 7.
3. `lw` từ `0x2000_0001` → `mcause` = 4 (misaligned thắng access fault).
4. `lh` từ `0x2000_0001` → `mcause` = 4.
5. `lb` từ `0x2000_0001` → **không** trap.
6. Nhảy vào `0x9000_0000` → `mcause` = 1.
7. Sau (1), đọc lại đúng địa chỉ đó lần nữa → vẫn phải trap (tag không được
   đánh dấu hợp lệ).

---

## 5. Phase C — Đường tới hạn ở IF (P1)

`reports/timing_syn.rpt` Path 1, slack **+6 ps** trên chu kỳ 2500 ps:

```
u_icache/state_reg[0] -> (mux hit cua cache) -> u_core/IF_add_279_30_g457..g401
                                                 ^ ~30 tang NAND2/NOR2 = ripple carry
                      -> u_core/IF_ID_if_id_pc_plus_4_reg[31]
```

Chuỗi cộng chiếm từ mốc 974 ps đến 2332 ps = **1358 ps, 58 % đường tới hạn**.

**Nguyên nhân.** `core/pipeline_stage/pipeline_stage.v`:

```verilog
wire [31:0] seq_pc    = pc_in + (instr0_compressed ? 32'd2 : ...);
assign      pc_plus_4 = pc_in + (instr0_compressed ? 32'd2 : 32'd4);
```

`instr0_compressed` phụ thuộc dữ liệu ra từ I-cache. Viết **mux trước adder**
buộc bộ cộng 32 bit phải bắt đầu *sau khi* cache trả lời. Genus không tự đảo
được vì đó là một toán hạng thật.

**Sửa** — tính song song, mux ở cuối:

```verilog
wire [31:0] pc_p2 = pc_in + 32'd2;
wire [31:0] pc_p4 = pc_in + 32'd4;
assign pc_plus_4  = instr0_compressed ? pc_p2 : pc_p4;
```

Hai bộ cộng chạy ngay từ đầu chu kỳ; `instr0_compressed` chỉ còn điều khiển một
tầng mux 2:1. `pc+2` và `pc+4` chỉ khác nhau ở carry của bit 1 nên tổng hợp chia
sẻ được gần hết logic — diện tích tăng không đáng kể.

Kỳ vọng thu hồi **700–1000 ps**. Không đổi chức năng, `fw` phải PASS y nguyên.

> `fetch_two_valid` bị nối cứng `1'b0` ở `riscv_pipeline.v` nên nhánh `+8` là
> code chết — bỏ luôn.

---

## 6. Phase D — Dự đoán nhánh (P2)

`core/block_unit/branch_prediction_unit.v`, ba khiếm khuyết độc lập:

| | Hiện tại | Đề xuất |
|---|---|---|
| BTB | 16 entry direct-mapped | 64 entry |
| BHT | 16 entry, index `pc_in[5:2]` (4 bit) | 256 entry, index `pc[9:2]` |
| RAS | **không có** | 8 entry |

**BHT là chỗ tệ nhất.** Index chỉ dùng `pc[5:2]` nên hai nhánh cách nhau 64 byte
dùng chung bộ đếm 2 bit. Trong một vòng lặp bình thường, điều đó đủ để bộ dự
đoán chạy quanh mức 50 %.

**RAS là chỗ đáng giá nhất.** `jalr` hoàn toàn không được dự đoán → **mỗi lệnh
`ret` là một mispredict đầy đủ**. Với code C nhiều hàm, đây là nguồn phạt lớn
nhất. Quy tắc chuẩn (đặc tả RISC-V, bảng "RAS hints"):

* `jal  rd=x1/x5`            → push `pc+4`
* `jalr rd=x1/x5, rs1≠x1/x5` → push
* `jalr rd=x0,   rs1=x1/x5`  → pop  (đây chính là `ret`)

Cộng thêm: `bpu_correct` hiện chỉ so **hướng**, không so **địa chỉ**. Với nhánh
điều kiện thì đủ (target là hằng số PC-relative), nhưng khi thêm RAS thì phải so
cả target, nếu không một dự đoán `ret` sai địa chỉ sẽ không bao giờ bị bắt.

### Đã thử, đo được, và ĐÃ REVERT

Ngày 2026-09-06 tôi thử BTB 16 → 64 (index `pc[7:2]`) và BHT 16 → 256
(index `pc[9:2]`). Cả ba testbench vẫn PASS, nhưng phép đo end-to-end nói ngược:

| | Mốc UART khớp trong `fw` |
|---|---|
| BTB 16 / BHT 16 (gốc) | **2 226 406 000 ns** |
| BTB 64 / BHT 256 | 2 834 036 000 ns — **chậm hơn 27 %** |

### ⚠️ ĐÍNH CHÍNH 2026-09-06: phép đo trên KHÔNG đáng tin

Sau khi firmware được build lại thật (bỏ khối FPU 3 lệnh, xem A6), cùng **đúng
RTL gốc 16/16** đó cho:

| Firmware | RTL | Mốc UART khớp |
|---|---|---|
| bản vá tay 1 word | BTB 16 / BHT 16 | 2 226 406 000 ns |
| build lại đầy đủ | BTB 16 / BHT 16 | **2 833 736 000 ns** |
| bản vá tay 1 word | BTB 64 / BHT 256 | 2 834 036 000 ns |

**Chỉ đổi firmware — bỏ 3 lệnh — đã làm mốc đo dịch 27 %, gần như đúng bằng mức
tôi quy cho việc phóng to BPU.**

Nguyên nhân: BTB và BHT index bằng `pc[5:2]`, nên dịch code 4 byte là đổi hẳn
cách các nhánh alias nhau. Workload `fw` lại bị chi phối bởi một vòng polling
chặt — đúng chỗ nhạy cảm nhất với điều đó.

**Kết luận đúng:** mốc `t` của testbench `fw` là một **chỉ báo alignment**, không
phải benchmark hiệu năng. Không được dùng nó để chấp nhận hay bác bỏ thay đổi ở
bộ dự đoán nhánh. Việc revert vẫn giữ — không ship thứ chưa chứng minh được là
tốt hơn, nhất là khi nó tốn ~2600 flop trên đường tới hạn còn 5.5 ps slack —
nhưng **lý do phải là "chưa đo được", không phải "đã đo ra tệ hơn"**.

**Giả thuyết cũ — vẫn đáng kiểm tra, nhưng CHƯA được chứng minh.** Một entry chỉ
vào BTB khi nhánh **đã từng nhảy** (`update_btb == 2'b01` yêu cầu
`actual_taken`), và `predict_taken` chỉ có hiệu lực khi BTB hit. Bảng 16 entry
vì vậy có thể vô tình hoạt động như một **bộ lọc bảo thủ**: phần lớn nhánh trượt
BTB → đoán "không nhảy" → đúng và rẻ với nhánh guard/kiểm tra lỗi. Phóng to bảng
giữ lại nhiều entry hơn → nhiều lần đoán "nhảy" hơn, trên những bộ đếm BHT còn ở
giá trị reset `2'b10` (weakly **taken**). Cần CoreMark để xác nhận hay bác bỏ.

**Đã revert** về 16/16.

**Điều kiện để thử lại — cả ba, không bỏ cái nào:**

1. **Một benchmark thật.** `fw` chủ yếu là vòng chờ UART/CLINT, không đại diện
   cho code thật. Cần CoreMark hoặc Dhrystone (⇒ cần toolchain RISC-V).
2. **Sửa chính sách cùng lúc, không chỉ kích thước.** Ít nhất: giá trị reset BHT
   `2'b01` (weakly not-taken) thay vì `2'b10`, và cân nhắc cấp phát BTB cả cho
   nhánh không nhảy.
3. **Genus xác nhận timing.** `btb_hit`/`predict_target` là tổ hợp đi thẳng vào
   mux PC; index rộng thêm 2 bit làm mux đọc to gấp 4 trên đúng khu vực đường
   tới hạn, mà slack `CLK_CPU` lần đo cuối chỉ +5.5 ps.

Bài học ghi lại: đây là hạng mục **không được sửa mù**. Không có phép đo thì
phóng to bộ dự đoán là đánh bạc, và lần đánh bạc này thua.

**Chưa làm: RAS.** Nó không tự chứa như hai cái trên — RAS cần biết lệnh đang
fetch là `jal`/`jalr` với `rd`/`rs1` nào, tức phải giải mã ngay ở tầng IF và
thêm đường push/pop vào mux PC. Kèm theo, `bpu_correct` hiện chỉ so **hướng**
chứ không so **địa chỉ**; với nhánh điều kiện thì đủ (target là hằng số
PC-relative nên một BTB entry khớp tag luôn có target đúng), nhưng một dự đoán
`ret` sai địa chỉ sẽ **không bao giờ bị bắt**. Vì vậy RAS phải đi kèm việc so
target, và đó là hai thay đổi cùng lúc vào đúng khu vực đường tới hạn.

**Rủi ro timing của phần đã làm:** `btb_hit` và `predict_target` là tổ hợp từ
mảng BTB và đi thẳng vào mux PC. Index rộng thêm 2 bit làm mux đọc to gấp 4.
Slack `CLK_CPU` lần đo cuối chỉ +5.5 ps, nên **Genus phải xác nhận lại**. Nếu
thiếu slack: hạ `ENTRY` về 32 (`INDEX = 5`) trước, rồi mới xét chốt
`predict_target` vào một flop.

**Đo được gì:** testbench `fw` báo UART khớp tại một mốc thời gian tất định.
Đó là phép đo hiệu năng end-to-end duy nhất hiện có — dùng nó để so trước/sau.

> **Cẩn thận với con số `t = 2 226 406 000 ns` ghi ngày 2026-09-05.** Nó gắn với
> một bản build firmware khác, nên KHÔNG so trực tiếp được với các lần đo sau.
> Muốn so trước/sau thì phải đảo đúng các file của thay đổi đang xét rồi chạy
> lại `fw` trên **cùng** file `.mem` — như đã làm cho Phase F ở §8. Vẫn nên thêm một đoạn firmware gọi hàm lồng
nhau và so `minstret`/`mcycle` để đo riêng bộ dự đoán.

---

## 7. Phase E — Nhân/chia (P3)

`core/block_unit/multiplier_divider_unit.v`: `BITS_PER_CYCLE = 4` cho nhân
(≈10 chu kỳ), `= 2` cho chia (≈19 chu kỳ).

Với định hướng "vòng lặp DSP / 1D-CNN" ghi trong `tcm.v`, nhân 10 chu kỳ là
thảm họa — MAC là lệnh chiếm ưu thế trong mọi kernel DSP.

**Đề xuất:** nhân pipeline 2–3 tầng (`a*b` để tổng hợp tự chọn Booth/Wallace),
giữ nguyên giao thức `md_alu_stall` / `md_alu_done` để tầng EX không phải đổi.
Giữ nguyên bộ chia iterative — lệnh chia hiếm và một bộ chia nhanh rất đắt.

**Phải cẩn thận:** nhân 32×32 một chu kỳ ở 400 MHz gần như chắc chắn thành đường
tới hạn mới. Vì vậy **pipeline 2–3 tầng, không phải 1 chu kỳ**, và phải chạy lại
Genus để xác nhận trước khi chốt.

---

## 8. Phase F — Store buffer (P4)

Thiết kế đầy đủ đã nằm ở [MEMORY_FIX_PLAN.md](MEMORY_FIX_PLAN.md) § Phase 1.
Không lặp lại ở đây. Hai điểm bổ sung:

**Đã làm ngày 2026-09-08, trước Phase G.**

**Đo A/B trên cùng một firmware**, chỉ đảo `memory/dcache.v` + `top_soc.v`:

| | `fw` UART khớp tại | store cacheable |
|---|---|---|
| 4-way, không store buffer | 2 831 456 000 ns | 35 chu kỳ |
| 2-way, store buffer 4 entry | **1 528 046 000 ns** | **1 chu kỳ** |

**Nhanh hơn 1.85×, giảm 46 % thời gian chạy end-to-end** — và đạt được trong
khi ĐỒNG THỜI hạ D-cache từ 4-way xuống 2-way.

* ~~**Chỉ làm sau Phase G.**~~ **Lập luận này đã bị số đo bác bỏ.** Kế hoạch cũ
  cho rằng F vô nghĩa khi trần IPC còn kẹp ở 0.5 vì P5. Thực tế 1.85× cho thấy
  ngược lại: trần IPC 0.5 chỉ chặn phần *thực thi*, còn store buffer gỡ phần
  *chờ bus* — hai nút cổ chai khác nhau, không che nhau. Với firmware thật
  (driver UART, store-heavy) thì chờ bus mới là phần chi phối.
* Lỗi bus của store **đã trở thành imprecise** đúng như dự đoán. Quyết định đã
  chốt: báo qua **ngắt riêng (PLIC nguồn 7)**, không phải exception đồng bộ.
  Store uncached vẫn giữ đường precise `dcache_error` → mcause 7.
* **Còn nợ:** `FENCE` chưa xả buffer. Xem `MEMORY_FIX_PLAN.md` § Phase 1.

---

## 9. Phase G — Pipeline hoá cache (P5)

**Đây là hạng mục lớn nhất và có giá trị lớn nhất.**

`icache.v` / `dcache.v` hiện tại:

```
IDLE:   if (cpu_read_req) { stall = 1; next = LOOKUP; }
LOOKUP: if (hit) { hit = 1; stall = 0; } next = IDLE;
```

Mỗi lệnh tốn **2 chu kỳ ngay cả khi hit**: một chu kỳ phát địa chỉ vào SRAM đồng
bộ, một chu kỳ so tag, rồi quay về IDLE và làm lại từ đầu cho PC kế tiếp.

→ **IPC bền vững không thể vượt 0.5.** Core 400 MHz có throughput của một core
1-IPC chạy 200 MHz. Toàn bộ nỗ lực đẩy `clk_core` lên 400 MHz bị nuốt mất một
nửa ngay tại đây.

**Hướng sửa.** Biến cache thành 2 tầng pipeline thật:

* Tầng 1 (địa chỉ): phát `pc_in` / `cpu_addr` vào SRAM **ngay trong chu kỳ có
  địa chỉ**, không cần một state riêng.
* Tầng 2 (so tag): so tag và trả dữ liệu, đồng thời **tầng 1 đã nhận địa chỉ kế
  tiếp** → 1 request/chu kỳ liên tục.
* Miss trở thành trường hợp ngoại lệ đẩy vào FSM refill như hiện nay.

`MEMORY_ARCHITECTURE.md` đã nhận ra đúng điều này ("core phải phát địa chỉ sớm
hơn một nhịp") nhưng mới áp cho TCM, chưa áp cho cache.

**Điều kiện tiên quyết:** Phase B xong (có test exception), Phase C xong (đường
tới hạn IF đã thoáng — pipeline cache sẽ đẩy thêm logic vào đúng chỗ đó), và
**chạy lại được Genus** để biết còn bao nhiêu slack.

---

## 10. Bảng theo dõi

| ID | Việc | Phase | Trạng thái | File |
|---|---|---|---|---|
| C3 | `mtvec` WARL + vectored | A | **Xong** | `core/register_file/register_file.v`, `core/riscv_pipeline.v` |
| C4 | `time`/`timeh` → illegal | A | **Xong** | `core/register_file/register_file.v` |
| C5 | CSR không tồn tại → illegal | A | **Xong** | `core/register_file/register_file.v` |
| C6 | CSR debug chỉ trong debug mode | A | **Xong** | `core/register_file/register_file.v` |
| C7 | Chặn ghi `dpc` khi trap | A | **Xong** | `core/register_file/register_file.v` |
| C2 | Misaligned load/store | B | **Xong (chưa có test riêng)** | `core/riscv_pipeline.v`, `core/pipeline_stage/pipeline_stage.v` |
| C1a | D-cache bus error → mcause 5/7 | B | **Xong (chưa có test riêng)** | `memory/dcache.v`, `core/riscv_pipeline.v` |
| C1b | I-cache bus error → mcause 1 | B | **Xong (chưa có test riêng)** | `memory/icache.v`, `core/pipeline_register/pipeline_register.v` |
| P1 | Mux sau adder ở IF | C | **Xong** | `core/pipeline_stage/pipeline_stage.v` |
| P2 | BTB/BHT lớn hơn + RAS | D | **Đã thử và REVERT — đo ra chậm hơn 27 %** | `core/block_unit/branch_prediction_unit.v` |
| P3 | Nhân pipeline | E | | `core/block_unit/multiplier_divider_unit.v` |
| C8 | `RESET_VECTOR` | D | | `peripheral/apb_syscon.v`, `core/riscv_pipeline.v` |
| P4 | Store buffer | F | Chờ G | `memory/dcache.v` |
| P5 | Pipeline hoá cache | G | Chờ Genus | `memory/icache.v`, `memory/dcache.v` |
| V | `tb_core_traps.sv` — test exception/CSR | A+B | | `genus/rtl/tests/` |
| A6 | `CONFIG_HAS_FPU` + vá `fcsr` trong ảnh firmware | A | **Xong** | `Driver/inc/soc_config.h`, `Driver/my_soc_firmware_word.mem` |
| — | Build lại firmware bằng toolchain RISC-V | A | **Chưa — máy không có toolchain**, hướng dẫn ở [`Driver/BUILD.md`](../../../../Driver/BUILD.md) | `Driver/` |
| — | **Chạy lại Genus** | GATE | Chặn E và G | máy có license |
