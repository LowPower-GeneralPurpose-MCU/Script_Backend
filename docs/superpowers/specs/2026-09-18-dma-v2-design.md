# DMA v2 — Nâng cấp lên chuẩn công nghiệp

**Ngày:** 2026-09-18
**Phạm vi:** Đầy đủ — scatter-gather descriptor, IOPMP, clock gating, căn byte/đổi độ rộng
**Mục tiêu:** IP tái sử dụng dài hạn, không phải bản vá một lần

---

## 1. Bối cảnh

### 1.1 DMA hiện tại có gì

`rtl/interrupt/dma/` — 4 kênh, một AXI4 32-bit master dùng chung, cấu hình qua APB.
Mỗi kênh: FIFO 16×4 B, outstanding counter, token counter rate-match RD/WR,
watchdog timeout, cắt burst tại biên 4 KB, đặt chỗ FIFO cho burst đang bay
(`rd_inflight`), AXI ID routing `{CH_IDX, seq}`. Round-robin arbiter giữa các kênh.
Soft-reset toàn cục.

Đây đã vượt mức thông thường. Phần dưới là khoảng cách còn lại so với
PL330 / DW-DMAC / STM32 GPDMA.

### 1.2 Khoảng cách chức năng

| Thiếu | Vị trí |
|---|---|
| Chỉ copy word-aligned; mọi src/dst/len lệch 4 B bị reject thành DECERR | `dma_core.v:171` `cfg_bad` |
| `WSTRB` cứng toàn 1 → không ghi byte/halfword | `dma_axi_master.v:407` |
| Không đổi độ rộng (ngoại vi 8-bit → mem 32-bit) | không có logic đóng gói |
| Không scatter-gather / descriptor — CPU nạp tay từng block | — |
| Không 2D/stride | — |
| Max 64 KB/transfer | `LEN_FIELD_W=16`, `dma.v:96` |

### 1.3 Lỗi tiềm ẩn cần sửa

1. **FIXED burst thiếu.** `ARBURST/AWBURST` đóng cứng `INCR` (`dma.v:68`). Khi
   `cfg_src_incr=0` (đọc FIFO ngoại vi), địa chỉ chỉ đứng yên *giữa* các burst;
   *trong* burst slave vẫn tự tăng → đọc sai FIFO.
2. **`periph_dma_clr` treo lơ lửng.** Sinh ra ở DMA nhưng không ngoại vi nào
   nhận (`top_soc.v:328`). Flow-control chỉ dựa mức `req`, vòng handshake hở.
3. **`INT_EN` chỉ 1 bit.** `REG_INT_EN` khai báo `[1]=err_ie` nhưng `ch_int_en`
   là reg 1 bit (`dma_core.v:727`) → không tách được ngắt done và err.
4. **`TUNING` không lộ ra.** `cfg_tokens`/`rd_out_max`/`wr_out_max` nối cứng vào
   `DEF_*` (`dma_core.v:930`) — không chỉnh được theo kênh.
5. **Arbiter không có ưu tiên.** `arbiter_iwrr_1cycle` nhận trọng số nhưng tất cả
   nối cứng bằng 1, `req_weight_i` tied 0 (`dma_core.v:1010`).

### 1.4 Khoảng cách low-power

DMA là khối duy nhất ngoài CPU **không có clock gate**. CORDIC, ASCON, UART0/1,
SPI, I2C, GPIO, PWM, TIM0/1 đều có `cg_*` (`top_soc.v:263-279`); DMA chạy thẳng
`clk`, luôn bật. Với một MCU low-power đây là khoảng cách nặng nhất.

### 1.5 Khoảng cách an toàn / bảo mật

- `AWPROT/ARPROT` tied 0, không `AxCACHE`, `AxQOS`, `AxLOCK` (`top_soc.v:1705`).
- Không IOPMP/MPU trên đường DMA → DMA ghi đè được vùng PMP bảo vệ của CPU.
- Không coherency với dcache — buffer phải ở DMAPOOL uncached
  (`tb_mem_paths.sv:1044` ghi nhận điều này).
- Không abort/suspend theo kênh; chỉ soft-reset **toàn cục** reset cả 4 kênh
  (`dma_core.v:751`).
- Không đọc được tiến độ, không capture địa chỉ gây lỗi.

### 1.6 Khoảng cách kiểm chứng

Không có `tb_dma.sv`. Toàn bộ coverage là 5 lần gọi `dma_copy` trong
`tb_mem_paths.sv`. `tests/models/` chỉ có 2 model SRAM — **chưa có AXI slave BFM**.
Không test multi-channel đồng thời, không test periph-triggered, không error
injection, không test timeout.

---

## 2. Quyết định kiến trúc

| Quyết định | Chọn | Lý do |
|---|---|---|
| Scatter-gather | **A + C**: descriptor fetcher dùng chung + shadow reload | A cho memory-to-memory và packet buffer rời rạc; C cho streaming ngoại vi, nơi fetch descriptor mỗi vòng là lãng phí năng lượng trên MCU low-power. C gần như miễn phí vì dùng chung đường nạp cấu hình với A. Đây là mô hình GPDMA. |
| Fetcher riêng từng kênh (B) | **Không** | ~4× diện tích cho vấn đề chưa tồn tại ở 4 kênh. Cân nhắc lại khi scale ≥8 kênh. |
| Bảo vệ bộ nhớ | **IOPMP đầy đủ**, 8 vùng, khoá được | Là thứ mọi IP thương mại đều có (SMMU/IOPMP/TZ). Ngữ nghĩa LOCK giống PMP để firmware dùng lại kiến thức. |
| Độ rộng `LEN` | **32 bit** | Người dùng chọn sau khi đã cân nhắc rủi ro timing. Xem §6.1 về biện pháp giảm thiểu. |
| Cache coherency | **Chỉ AxCACHE**, chưa làm hardware invalidate | Đụng vào dcache rủi ro cao; AxCACHE đủ để SoC tự quyết. Để lại làm mở rộng sau. |
| 2D / stride | **Có** | Gần như miễn phí một khi có thanh ghi stride trong descriptor. |
| Clock gating | **Có**, giai đoạn 5 | Khoảng cách low-power nặng nhất; xem §4.6. |

---

## 3. Phân rã module

`dma_core.v` hiện gộp 2 module trong 1271 dòng. Tách theo file, mỗi file một
trách nhiệm:

```
axi_apb_dma            L3 wrapper — chọn parameter + map tên port SoC (giữ vai trò)
└── dma_engine         L2 top của IP
    ├── dma_regfile      [MỚI]  APB slave + register file
    ├── dma_desc         [MỚI]  SG descriptor fetch engine dùng chung
    ├── dma_iopmp        [MỚI]  kiểm tra địa chỉ/quyền trước khi phát AXI
    ├── dma_cfg_mux      [MỚI]  chọn nguồn cấu hình: APB │ descriptor │ shadow
    ├── N× dma_channel   sửa lớn
    │   └── dma_align      [MỚI]  byte packing + đổi độ rộng + sinh WSTRB
    ├── dma_arb           arbiter lấy trọng số thật từ regfile
    ├── axi4_master_rd    thêm ARBURST/ARCACHE/ARPROT/ARQOS theo lệnh
    └── axi4_master_wr    thêm AWBURST/AWCACHE/AWPROT/AWQOS + WSTRB thật
```

**File mới:** `dma_regfile.v`, `dma_desc.v`, `dma_iopmp.v`, `dma_align.v`,
`dma_cfg_mux.v`. **File tách ra:** `dma_channel.v`, `dma_engine.v` (từ
`dma_core.v`). `dma_defines.vh` mở rộng.

`dma_desc` tham gia RD arbiter như requester thứ **N+1** — thừa hưởng nguyên bộ
outstanding counter, timeout watchdog và error routing đã có, nên xử lý lỗi
descriptor không cần code mới.

**Ranh giới:** mỗi module phải trả lời được ba câu — nó làm gì, dùng nó thế nào,
nó phụ thuộc vào đâu. `dma_align` không biết gì về AXI; `dma_iopmp` không biết gì
về kênh; `dma_desc` không biết gì về cách kênh chạy transfer.

---

## 4. Cơ chế cốt lõi

### 4.1 `dma_align` — căn byte và đổi độ rộng

Thay thế `cfg_bad` cho trường hợp lệch căn. Sau thay đổi này `cfg_bad` chỉ còn
giữ lại cấu hình thật sự vô nghĩa (burst=0; len=0 khi SG tắt).

**Phía đọc.** AXI luôn trả nguyên word chứa địa chỉ. Giữ `src_off = cfg_src_addr[1:0]`,
bỏ byte thừa đầu beat đầu và cuối beat cuối, đẩy vào dòng byte liên tục —
shift register 2 word cộng bộ đếm byte.

**Phía ghi.** `dst_off = cfg_dst_addr[1:0]`. Beat đầu WSTRB che byte dẫn đầu,
beat cuối che byte đuôi, beat giữa `4'b1111`.

**Đổi độ rộng.** `cfg_src_width` / `cfg_dst_width` ∈ {8,16,32} lái ARSIZE/AWSIZE
và độ chi tiết nạp/xả của bộ đóng gói. Ngoại vi 8-bit → ARSIZE=`3'b000` + FIXED
burst; bộ đóng gói gom 4 byte → một lệnh ghi 32-bit vào RAM.

**Giao diện:** vào là `{data[31:0], valid, byte_en[3:0]}` từ FIFO đọc, ra là
`{data[31:0], valid, wstrb[3:0], last}` cho đường ghi. Không có tín hiệu AXI nào
xuyên qua module này.

### 4.2 FIXED burst

`AxBURST` thành tín hiệu theo lệnh thay vì tied ở `dma.v:68`:
`incr=0 → 2'b00 (FIXED)`, `incr=1 → 2'b01 (INCR)`. FIXED hợp lệ với `AxLEN>0`,
mọi beat cùng địa chỉ — đúng ngữ nghĩa FIFO ngoại vi.

Khi FIXED, bỏ qua logic cắt biên 4 KB (không có biên nào bị cắt vì địa chỉ đứng yên).

### 4.3 Descriptor scatter-gather

Descriptor 32 byte = 8 word, **căn 32 byte** nên một burst 8 beat không bao giờ
cắt biên 4 KB.

| Offset | Trường | Ý nghĩa |
|---|---|---|
| `+0x00` | `SRC_ADDR[31:0]` | |
| `+0x04` | `DST_ADDR[31:0]` | |
| `+0x08` | `LEN[31:0]` | byte |
| `+0x0C` | `CTRL[31:0]` | src_incr, dst_incr, src_width, dst_width, burst_max, periph_num, irq_en, 2d_en |
| `+0x10` | `NEXT_PTR[31:0]` | 0 = hết chuỗi; phải căn 32 B, lệch → `ERR_DESC` |
| `+0x14` | `SRC_STRIDE[31:0]` | chế độ 2D (có dấu) |
| `+0x18` | `DST_STRIDE[31:0]` | chế độ 2D (có dấu) |
| `+0x1C` | `NUM_LINES[15:0]` \| RSVD | 2D: tổng `NUM_LINES × LEN` byte |

**FSM kênh** thêm trạng thái `ST_FETCH` vào chuỗi hiện có
(`IDLE / RUN / DRAIN / DONE`):

```
IDLE --start, DESC_PTR!=0--> FETCH --desc về--> RUN --> DRAIN --> DONE
                                                                   |
                                   NEXT_PTR != 0 -----> FETCH <-----+
```

**2D** dùng lại chính chuỗi này: hết mỗi "dòng" `LEN` byte thì cộng stride vào
`rd_addr`/`wr_addr` và nạp lại `rd_remain`/`wr_remain`, giảm `line_cnt`, thay vì
chạy tiếp tuyến tính. Không cần trạng thái mới.

**Lỗi descriptor:** fetch trả SLVERR/DECERR, hoặc `NEXT_PTR` lệch căn, hoặc
`LEN=0` giữa chuỗi → dừng chuỗi, `err = DMA_ERR_DESC`, `ERR_ADDR` = địa chỉ
descriptor, ngắt `err`.

**Trọng tài giữa các kênh** khi nhiều kênh cùng cần descriptor: round-robin
trong `dma_desc`, độc lập với arbiter dữ liệu.

### 4.4 Shadow reload và circular

- `CTRL.RELOAD`: transfer xong thì nạp từ bộ thanh ghi bóng (`SHADOW_*`) thay vì
  dừng. Phần mềm nạp bộ bóng trong lúc transfer hiện tại đang chạy.
- `CTRL.CIRCULAR`: nạp lại chính cấu hình gốc, chạy vô hạn tới khi `ABORT`.
- Ghép với ngắt `HALF_DONE` → ping-pong buffer chuẩn cho ADC/UART streaming.
  Không sinh traffic AXI phụ, độ trễ tất định.

Dùng chung `dma_cfg_mux` với `dma_desc`; chi phí thêm chỉ là bộ thanh ghi bóng.

### 4.5 `dma_iopmp`

8 vùng, mỗi vùng `{BASE[31:0], LIMIT[31:0], PERM{R,W}, LOCK, CH_MASK[3:0]}`.

Kiểm tra `rd_cmd_addr` / `wr_cmd_addr` **trước khi arbiter cấp phép**. Vi phạm →
không phát lệnh ra bus, đặt `DMA_ERR_ACCESS`, ghi địa chỉ vi phạm vào `CH_ERR_ADDR`,
kênh chuyển sang `DRAIN` rồi `DONE`.

Kiểm cả **địa chỉ cuối burst** (`addr + burst_bytes - 1`), không chỉ địa chỉ đầu —
nếu không một burst có thể bắt đầu trong vùng hợp lệ và kết thúc ngoài nó.

`LOCK` dính tới khi hard reset, kể cả soft-reset toàn cục không xoá được — cùng
ngữ nghĩa PMP để firmware dùng lại kiến thức sẵn có.

**Bắt buộc đăng ký kết quả kiểm tra** (thêm 1 chu kỳ độ trễ phát lệnh) thay vì
để tổ hợp. Xem §6.2.

### 4.6 Clock gating

```verilog
wire dma_clk_req = |ch_active | desc_busy | apb_psel
                 | rd_outs_nonzero | wr_outs_nonzero     // BẮT BUỘC
                 | (|(periph_dma_req & ch_armed_mask));

clock_gate cg_dma (.clk_in(clk),
                   .en(clk_en_dma | dma_clk_req),
                   .test_en(1'b0),
                   .clk_out(clk_dma));
```

Hai vế outstanding counter là **bắt buộc**: tắt clock khi còn giao dịch AXI đang
bay sẽ treo bus — response về mà không ai nhận. Đây chính là loại lỗi đã gặp với
CORDIC, nơi `o_active` phải vòng về giữ gate mở suốt trạng thái CALC.

`clk_en_dma` là flop mới trong `apb_syscon`, theo đúng khuôn của các
`clk_en_*` hiện có (`top_soc.v:204-206`).

**Reset:** `reset_sys_n` vẫn lấy từ miền `clk` gốc, không qua gate.

**Kéo dài sau khi hạ:** giống các ngoại vi khác, `dma_clk_req` giữ thêm vài chu kỳ
sau khi điều kiện cuối hạ, vì `apb_pready` là thanh ghi — nếu cắt clock đúng chu kỳ
`psel` hạ thì `pready` không bao giờ về.

### 4.7 Abort / suspend / tiến độ

- `CTRL.ABORT`: ngừng phát lệnh mới, **chờ outstanding drain xong** rồi về IDLE
  với `ERR_ABORT`. Không reset thẳng — sẽ bỏ lại response mồ côi trên bus.
  Nếu chuỗi SG đang chạy, huỷ luôn cả chuỗi.
- `CTRL.SUSPEND`: tạm dừng phát lệnh, giữ nguyên trạng thái; bỏ bit thì chạy tiếp.
  Outstanding hiện có vẫn hoàn tất bình thường.
- `XFER_CNT` (RO) = `cfg_len − wr_remain`, tính theo transfer hiện tại.
- `HALF_DONE`: ngắt khi `wr_remain` vượt mốc `cfg_len/2`.

### 4.8 Ưu tiên kênh

Đưa `CH_PRIO[3:0]` từ regfile vào `req_weight_i` của `arbiter_iwrr_1cycle`.
Module đã nhận trọng số sẵn — gần như không tốn logic mới.

### 4.9 Sideband AXI

| Tín hiệu | Nguồn |
|---|---|
| `AxPROT[2:0]` | `CTRL.{PRIV, SECURE}` (bit `[2]` instruction = 0) |
| `AxCACHE[3:0]` | `CTRL.CACHE[3:0]` |
| `AxQOS[3:0]` | `CH_PRIO[3:0]` |
| `AxLOCK` | 0 (DMA không phát exclusive) |

Thay cho việc tied 0 ở `top_soc.v:1705`. Đây là đường để DMA hợp tác với dcache
thay vì buộc mọi buffer vào DMAPOOL uncached.

### 4.10 Vòng handshake ngoại vi

Đóng vòng `periph_dma_clr` đang treo:

- Thêm cổng `dma_ack` vào `apb_uart`, `apb_spi`, `apb_i2c` (và `apb_uart1`) để
  ngoại vi hạ `req` khi DMA đã lấy dữ liệu.
- Phân biệt **single request** và **burst request**: ngoại vi báo FIFO có ≥1 mục
  hay ≥ngưỡng watermark. DMA chỉ phát burst dài khi có burst request — cách
  DW-DMAC và PL330 tránh phát burst dài vào một FIFO gần cạn.
- `CTRL.PERIPH_MODE`: `0` = level (như hiện nay, tương thích ngược),
  `1` = handshake đầy đủ.

---

## 5. Register map

Stride 0x1000/kênh giữ nguyên. **Bảy offset đầu giữ nguyên vị trí và
`CTRL[14:0]` giữ nguyên layout** → `tb_mem_paths.sv` chạy tiếp không cần sửa.
Trường mới của `CTRL` nằm ở `[31:15]`.

### 5.1 Thanh ghi theo kênh

| Offset | Tên | R/W | Ghi chú |
|---|---|---|---|
| `0x00` | `SRC_ADDR` | RW | giữ nguyên |
| `0x04` | `DST_ADDR` | RW | giữ nguyên |
| `0x08` | `LEN` | RW | **16 → 32 bit** |
| `0x0C` | `CTRL` | RW | `[14:0]` giữ; `[31:15]` mới |
| `0x10` | `STATUS` | RO | thêm `suspended`, `chain_active` |
| `0x14` | `INT_EN` | RW | `[0]`done `[1]`err `[2]`half `[3]`chain_done |
| `0x18` | `INT_STAT` | W1C | cùng bit |
| `0x1C` | `DESC_PTR` | RW | descriptor đầu chuỗi; 0 = tắt SG |
| `0x20` | `XFER_CNT` | RO | byte đã hoàn thành |
| `0x24` | `ERR_ADDR` | RO | địa chỉ gây lỗi |
| `0x28` | `SRC_STRIDE` | RW | 2D, có dấu |
| `0x2C` | `DST_STRIDE` | RW | 2D, có dấu |
| `0x30` | `NUM_LINES` | RW | 2D |
| `0x34` | `PRIO` | RW | `[3:0]` trọng số arbiter |
| `0x38` | `TUNING` | RW | `[3:0]`tokens `[11:8]`rd_out_max `[19:16]`wr_out_max |
| `0x40` | `SHADOW_SRC` | RW | bộ bóng cho reload |
| `0x44` | `SHADOW_DST` | RW | |
| `0x48` | `SHADOW_LEN` | RW | |
| `0x4C` | `SHADOW_CTRL` | RW | |

### 5.2 `CTRL` bit layout

| Bit | Tên | Ghi chú |
|---|---|---|
| `[0]` | `START` | giữ nguyên |
| `[7:1]` | `BURST_MAX` | giữ nguyên |
| `[8]` | `SRC_INCR` | giữ nguyên; 0 → FIXED burst |
| `[9]` | `DST_INCR` | giữ nguyên; 0 → FIXED burst |
| `[14:10]` | `PERIPH_NUM` | giữ nguyên |
| `[16:15]` | `SRC_WIDTH` | 00=8b 01=16b 10=32b |
| `[18:17]` | `DST_WIDTH` | 00=8b 01=16b 10=32b |
| `[19]` | `SG_EN` | bật scatter-gather |
| `[20]` | `RELOAD` | nạp từ shadow khi xong |
| `[21]` | `CIRCULAR` | lặp vô hạn |
| `[22]` | `TWO_D` | bật 2D/stride |
| `[23]` | `ABORT` | ghi 1 để huỷ |
| `[24]` | `SUSPEND` | mức, không phải pulse |
| `[25]` | `PRIV` | `AxPROT[0] = PRIV` |
| `[26]` | `SECURE` | `AxPROT[1] = ~SECURE` (AMBA: 0 = secure) |
| `[30:27]` | `CACHE` | → AxCACHE[3:0] |
| `[31]` | `PERIPH_MODE` | 0=level 1=handshake |

### 5.3 `STATUS` bit layout (RO)

| Bit | Tên | Ghi chú |
|---|---|---|
| `[0]` | `ACTIVE` | giữ nguyên |
| `[1]` | `DONE` | giữ nguyên — vẫn lấy từ `INT_STAT[0]` để bền vững tới khi W1C |
| `[4:2]` | `ERR` | **mở 2 → 3 bit**; `[3:2]` giữ nguyên nghĩa với 4 mã cũ, `[4]` trước đây luôn 0 |
| `[5]` | `SUSPENDED` | mới |
| `[6]` | `CHAIN_ACTIVE` | mới — đang chạy chuỗi SG |
| `[31:7]` | RSVD | đọc về 0 |

### 5.4 Thanh ghi toàn cục (base `0xF00`)

| Offset | Tên | Ghi chú |
|---|---|---|
| `0xF00` | `GLOBAL_CTRL` | `[0]`soft_rst `[1]`dma_en |
| `0xF04` | `GLOBAL_STAT` | `[N-1:0]` bitmap kênh đang chạy |
| `0xF10`–`0xF4C` | `IOPMP_REGION0-7` | 2 word/vùng: `{BASE}`, `{LIMIT[31:4], CH_MASK[3:0], PERM_R, PERM_W}` |
| `0xF50` | `IOPMP_LOCK` | `[7:0]` sticky, mỗi bit khoá một vùng |

### 5.5 Mã lỗi (mở rộng `dma_defines.vh`)

| Mã | Tên | Ghi chú |
|---|---|---|
| `3'b000` | `DMA_ERR_NONE` | |
| `3'b001` | `DMA_ERR_SLVERR` | giữ |
| `3'b010` | `DMA_ERR_DECERR` | giữ |
| `3'b011` | `DMA_ERR_TIMEOUT` | giữ |
| `3'b100` | `DMA_ERR_ACCESS` | IOPMP chặn |
| `3'b101` | `DMA_ERR_DESC` | descriptor hỏng |
| `3'b110` | `DMA_ERR_ABORT` | phần mềm huỷ |

Xem §5.3 về vị trí bit. Phần mềm cũ đọc `STATUS[3:2]` vẫn đúng với 4 mã cũ.

---

## 6. Rủi ro và biện pháp giảm thiểu

### 6.1 `LEN` 32 bit trên đường găng

Comment trong `dma_core.v` ghi nhận `ch_bmax → rd_addr[31]` là đường găng nhất
chip (3761 ps, biên SS 3 ps ở thời điểm đó), và RTLOPT-55 khiến Genus không tổng
hợp lại bộ cộng thành dạng nhanh. Mở `LEN_FIELD_W` 16 → 32 nới rộng
`rd_remain` / `wr_remain` và chuỗi so sánh trên đúng đường đó.

**Biện pháp — tách phép so sánh.** Đường găng là `rd_remain < burst_cap`, mà
`burst_cap` luôn `< 2^BURST_W` (=128). Không cần bộ so sánh 32 bit:

```verilog
wire rd_rem_small = ~|rd_remain[LEN_FIELD_W-1:BURST_W];          // OR-reduce
wire rd_sel_rem   = rd_rem_small & (rd_remain[BURST_W-1:0] < burst_cap_bytes);
```

Vế trái là OR-reduce (độ sâu log, rẻ) chạy **song song** với bộ so sánh 7 bit.
Đường găng không dài thêm theo độ rộng `LEN` — chỉ thêm đúng một tầng OR.

Phép trừ `rd_remain_nxt` vẫn là 32 bit nhưng nằm ngoài đường găng nhờ cấu trúc
tính ứng viên song song đã có sẵn trong code.

**Kiểm chứng:** sau giai đoạn 3 chạy Genus và so `report_timing` trên đường
`ch_bmax → rd_addr` với baseline 2026-09-14. Nếu xấu đi >50 ps, quay lại 24 bit.

### 6.2 IOPMP trên đường AR/AW

Chuỗi so sánh 8 vùng đặt ngay trước arbiter. Biên SS hiện tại khoảng 100 ps ở 4 ns.

**Biện pháp:** đăng ký kết quả kiểm tra — kênh phát địa chỉ ở chu kỳ N,
IOPMP trả verdict ở chu kỳ N+1, arbiter cấp phép ở N+1. Thêm 1 chu kỳ độ trễ
phát lệnh, không ảnh hưởng throughput vì các burst vẫn pipeline được.

So sánh 8 vùng chạy song song, kết quả OR lại — độ sâu là `log2(8)=3` tầng sau
bộ so sánh, không phải 8 tầng nối tiếp.

### 6.3 Clock gate treo bus

Đã xử lý trong §4.6: `dma_clk_req` phải bao gồm cả hai outstanding counter và
phải kéo dài vài chu kỳ sau khi `psel` hạ. Test 11 trong §7 kiểm tra riêng điều này.

### 6.4 Phá vỡ tương thích ngược

`tb_mem_paths.sv` dùng offset `0x00`–`0x18` và `CTRL[14:0]`. Layout giữ nguyên nên
testbench chạy tiếp. **Cần kiểm tra lại** sau giai đoạn 2 vì `INT_EN` đổi từ 1 bit
thành 4 bit — phần mềm cũ ghi `1` vào `INT_EN` vẫn bật `done_ie`, đúng như trước.

### 6.5 Diện tích

Ước lượng thô: `dma_align` ×4 kênh là phần tốn nhất (shift register 2 word +
điều khiển byte). `dma_desc` là một FSM nhỏ. `dma_iopmp` là 8×2 thanh ghi 32 bit
cộng 16 bộ so sánh. Chấp nhận được với mục tiêu IP tái sử dụng, nhưng **phải đo
lại `gates_syn.rpt` sau mỗi giai đoạn**, không suy từ grep netlist
(một dòng grep đếm thiếu macro).

---

## 7. Kế hoạch kiểm chứng

### 7.1 Hạ tầng cần xây

- `tests/models/axi_slave_bfm.sv` — AXI4 slave model có thể tiêm SLVERR/DECERR,
  trễ ngẫu nhiên, và không phản hồi (cho test timeout).
- `tests/tb_dma.sv` — standalone, self-checking scoreboard.
- `tests/gen_dma_desc.py` — sinh chuỗi descriptor và ảnh bộ nhớ vàng.

### 7.2 Danh mục test

| # | Test | Nội dung |
|---|---|---|
| 1 | Alignment sweep | `src_off × dst_off × len ∈ 1..17` — toàn tổ hợp 4×4×17 |
| 2 | Width matrix | {8,16,32} × {8,16,32}, cả INCR và FIXED |
| 3 | SG chain | 1 / 2 / 8 descriptor; `NEXT_PTR` hợp lệ và descriptor lỗi giữa chuỗi |
| 4 | 2D / stride | stride dương, stride âm, `NUM_LINES=1` (suy biến về 1D) |
| 5 | Circular + half | ping-pong không mất beat qua 100 vòng |
| 6 | Multi-channel | 4 kênh đồng thời, `PRIO` khác nhau — xác nhận arbiter thật sự ưu tiên |
| 7 | Error injection | SLVERR/DECERR trên đường data **và** đường descriptor fetch |
| 8 | Timeout | slave không phản hồi AR, AW, W |
| 9 | Abort / suspend | huỷ giữa chừng — xác nhận outstanding drain sạch, không response mồ côi |
| 10 | IOPMP | vi phạm R, vi phạm W, burst vắt qua biên vùng, LOCK rồi ghi đè, `CH_MASK` chéo kênh |
| 11 | Clock gate | xác nhận gate **không** đóng khi `rd_outs`/`wr_outs` ≠ 0, và `pready` luôn về được |
| 12 | Handshake ngoại vi | single vs burst request, `dma_ack` đóng vòng |
| 13 | Hồi quy | `tb_mem_paths.sv` chạy lại không sửa |

Mỗi test tự kiểm bằng scoreboard so bộ nhớ đích với ảnh vàng, không dựa vào
`$display` thủ công.

---

## 8. Thứ tự thực hiện

Mỗi giai đoạn phải sim PASS trước khi sang tiếp. Genus chỉ chạy sau giai đoạn 3.

| GĐ | Nội dung | Rủi ro |
|---|---|---|
| **1** | Tách file theo §3 (chưa đổi chức năng) + `axi_slave_bfm.sv` + `tb_dma.sv` khung + test 1 & 13 | Rất thấp — lưới an toàn cho mọi giai đoạn sau |
| **2** | Sửa lỗi §1.3: FIXED burst, WSTRB thật, `INT_EN` 4 bit, `TUNING` ra APB, đóng vòng `periph_clr` | Thấp |
| **3** | `dma_align` (căn byte + đổi độ rộng), abort/suspend/progress, `PRIO`, sideband AXI, `LEN` 32 bit | Trung bình — đường dữ liệu đổi |
| **→** | **Chạy Genus một lần**, so `report_timing` với baseline 2026-09-14 | Bắt sớm hồi quy timing |
| **4** | `dma_desc` + shadow reload + circular + 2D | Trung bình — FSM mới nhưng tách biệt |
| **5** | `dma_iopmp` + clock gate `cg_dma` + `clk_en_dma` trong `apb_syscon` | Trung bình-cao — đụng đường AR/AW và cây clock |
| **→** | Genus + Innovus đầy đủ | |

Đừng dồn lần chạy Genus tới cuối — hồi quy timing phát hiện muộn sẽ khó truy nguyên
giữa năm nhóm thay đổi.

---

## 9. Ngoài phạm vi

- Hardware cache invalidate (DMA báo dcache vô hiệu hoá vùng vừa ghi). `AxCACHE`
  đã mở đường; làm phần cứng sau nếu cần bỏ quy ước DMAPOOL uncached.
- Descriptor fetcher riêng từng kênh (phương án B) — cân nhắc lại khi ≥8 kênh.
- Mở rộng AXI lên 64 bit — cả interconnect đang 32 bit.
- Exclusive access / `AxLOCK` — DMA không cần.
