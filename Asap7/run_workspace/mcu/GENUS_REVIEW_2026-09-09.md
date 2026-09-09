# Đánh giá bản tổng hợp Genus 2026-09-09 + rà soát RTL

**Nguồn dữ liệu:** `genus/reports/*` (sinh lúc `Sep 09 2026 02:28`), `genus/genus.log`
(15.6 MB, thoát `Normal exit`), `genus/outputs/top_soc_syn.v` (23.7 MB),
`genus/tcl/genus.tcl`, `genus/tcl/constraint.sdc`, và cây RTL `genus/rtl/`.

> **Trạng thái 2026-09-09 (cập nhật sau khi sửa):** F1, F2, R1, R2, R3, R4, R6, R7, R8
> **đã áp và verify** (XSim: apb 256/256, fw PASS, mem 109/109). R5 để lại theo thoả
> thuận. Trong lúc làm R1 phát hiện thêm **R11 — một lỗi đúng đắn có sẵn từ trước**
> (AMO trượt cache retire mà không ghi), đã sửa. Năm con số trong bản gốc đã được
> **đính chính bằng đo đạc thật** — §12.

**Kết luận một dòng:** run **chạy sạch về mặt công cụ** (0 Error, 0 violating path,
84/84 macro SRAM khớp), nhưng **không đủ điều kiện để coi là đóng timing 400 MHz** —
CLK_CPU chỉ còn **+0.5 ps / 2500 ps** khi *chưa có clock tree*. Kèm theo đó là **một lỗi
thật trong `genus.tcl`** làm vô hiệu 6 trong 7 chỉ thị giữ hierarchy, và một nhóm vấn đề
kiến trúc RTL lặp lại ở AXI/CDC. Chi tiết bên dưới.

---

## 1. Bảng tóm tắt điều hành

| Hạng mục | Kết quả | Đánh giá |
|---|---|---|
| Lỗi / cảnh báo chặn | 0 Error | ✅ |
| Violating paths | 0 / 18 clock | ✅ (về hình thức) |
| **WNS CLK_CPU** | **+0.5 ps** trên 2500 ps (0.02 %) | 🔴 **Không an toàn** |
| WNS mọi domain khác | ≥ +529.8 ps | ✅ |
| Max transition trên đường tới hạn | đúng 100.0 ps = trần | 🟠 ràng buộc đang chặn |
| Cell area | 2 113 150 µm² (SRAM 1 762 029 = 83.4 %) | ✅ |
| Instance | 146 753 (seq 39 417 / comb 107 336) | ✅ |
| SRAM macro | 84 / 84 (đã verify trong netlist) | ✅ |
| Multi-Vt | 55 cell LVT / 146 753 (0.04 %) | ✅ đảo ngược hoàn toàn so với 99.5 % LVT |
| Leakage (std cell) | 17.5 µW | ✅ nhưng **thiếu leakage của 84 macro** |
| Dynamic power | 105.9 mW — 79.9 % là `bbox` không annotate | 🔴 **không dùng được** |
| Lint timing | 4 mục, cả 4 đã được giải thích trong SDC | ✅ |
| Flow script | **6/7 chỉ thị `ungroup_ok false` không khớp tên module** | 🔴 **Lỗi thật** |
| Song song hoá | **1 thread** (PBS-2), 65 phút | 🟠 lãng phí |
| Corner | **chỉ TT 0.7 V 25 °C**, không SS/FF, không hold riêng | 🔴 thiếu |
| DFT / scan | Không có; `test_en` nối cứng `1'b0` | 🟠 nợ kỹ thuật |

---

## 2. Thiết lập của run

Đọc từ `genus.log`:

```
Genus synthesis effort        : high
Genus interconnect mode       : ple (physical layout estimation)   <- co uoc luong RC
Multi-Vt                      : LVT bi cam o syn_generic/syn_map (212/212 cell),
                                mo lai o syn_opt + leakage_power_effort high
Power annotation              : KHONG co SAIF
Number of threads             : 1                                   <- PBS-2
Runtime                       : 3911 s CPU / 3930 s wall, peak 4.19 GB
Mapped SRAM instances         : 84 (expected 84)                    <- invariant PASS
```

`interconnect_mode = ple` là điểm cộng lớn: `Net Area = 128 812 µm²` khác 0, tức là các
con số timing đã có delay dây ước lượng, không còn là "zero-wire" như các bản trước.

---

## 3. Timing — phân tích chi tiết

### 3.1 Slack theo domain (`qor_syn.rpt`)

| Clock | Chu kỳ (ps) | WNS (ps) | Margin |
|---|---:|---:|---|
| **CLK_CPU** | 2500 | **+0.5** | **0.02 %** |
| CLK_CORE | 2500 | +1016.6 | 40.7 % |
| CLK_AXI | 5000 | +529.8 | 10.6 % |
| CLK_SDRAM_OUT | 5000 | +586.0 | 11.7 % |
| CLK_DBG | 5000 | +1566.2 | 31.3 % |
| CLK_APB | 10000 | +4230.8 | 42.3 % |
| CLK_CORDIC / GPIO / PWM | 10000 | +5262 … +7140 | ≥ 52 % |
| CLK_UART/SPI/I2C (± gated) | 20k–100k | +9741 … +74640 | ≥ 48 % |
| CLK_RTC | 30 517 578 | +30 514 432 | ~100 % |
| CLK_SDRAM | 5000 | *No paths* | (đã giải thích trong SDC) |

Toàn bộ **100 đường xấu nhất đều thuộc CLK_CPU**, slack từ 0 đến < 50 ps. Không có
domain nào khác lọt vào top-100 → áp lực timing tập trung 100 % vào miền CPU đã gate.

### 3.2 Đường tới hạn #1 — bộ cộng JALR vẫn là ripple carry

```
Startpoint : u_core/EX_MEM_ex_mem_csr_addr_reg[9]/CLK   (CLK_CPU)
Endpoint   : u_core/pc_reg_reg[31]/D                    (CLK_CPU)
Required   : 2361 ps   (2500 - 14 setup - 125 uncertainty)
Data path  : 2360 ps   -> Slack = 0 ps
```

Phân rã đường đi:

| Đoạn | Arrival (ps) | Δ (ps) | % |
|---|---:|---:|---:|
| Flop launch → logic điều khiển next-PC | 0 → 719 | 719 | 30 % |
| **`IF_add_396_40_Y_ADD_UNS_OP12` (bộ cộng JALR 32-bit)** | 719 → 2045 | **1326** | **56 %** |
| Mux ưu tiên next-PC + AND5 cuối | 2045 → 2360 | 315 | 13 % |

Cấu trúc bộ cộng trong netlist: `13 × MAJx2 + 4 × MAJIxp5 + FAx1 + chuỗi OA21x2`,
tức **vẫn là ripple/carry-skip nông, không phải CLA hay carry-select**.

**Nhận xét quan trọng:** sửa **T1** ở `pipeline_stage.v:396` (kéo
`wire [31:0] jalr_target = (alu_in1 + id_ex_ext_imm) & 32'hFFFFFFFE;` ra khỏi chuỗi
`if/else`) **đã có tác dụng một phần** — adder chiếm 56 % đường tới hạn thay vì 68 % như
bản trước — nhưng **chưa đạt mục tiêu**. Nguyên nhân còn lại là RTLOPT-55: `genus.log`
báo `Module 'CDN_DP_region_234_0_c7' has been invalidated for datapath optimizations`
**31 744 lần** (chỉ 1 region duy nhất, in lặp). Datapath extractor vẫn bỏ vùng đó, nên
Genus map bằng logic thường.

Ghi chú trong chính RTL đã dự đoán đúng tình huống này (`pipeline_stage.v:389-393`):
*"Neu sau khi re-synth van khong du margin thi buoc tiep theo la tinh `jalr_target` o
tang EX va cho no qua mot thanh ghi."* → **Đó là việc phải làm bây giờ.**

### 3.3 Họ đường tới hạn #2 — vòng tổ hợp AMO xuyên 3 module (99/100 đường)

99 trên 100 đường xấu nhất có cùng start/end:

```
Startpoint : u_dcache_state_reg[0]/CLK                                   (top_soc)
Endpoint   : u_dc_axi_bridge_u_w_fifo_u_async_fifo/genblk1.buffer_reg[*][*]/D
Slack      : +2 ... +49 ps
```

Chuỗi thật (đã đối chiếu với RTL):

```
dcache.v      state (flop)
   -> hit_flag / read_word      (so tag 2-way + mux way,  dcache.v:542-553)
   -> cpu_read_data             (read_data_with_size,     dcache.v:555-565)
pipeline_stage.v (module memory_access)
   -> amo_write_data            (cong 32-bit AMOADD + cac bo so sanh
                                 AMOMIN/MAX -> SUB_TC_OP...,        :908-928)
   -> dcache_write_data         (:952)
dcache.v
   -> lane_align_wdata -> m_axi_wdata                     (dcache.v:380)
top_soc -> u_dc_axi_bridge -> async_fifo buffer_reg
```

Bằng chứng trong `timing_syn.rpt` (Path 2): các cell
`u_core/MEM/SUB_TC_OP_1_Y_SUB_TC_OP20_Y_ADD_TC_OP_g*` nằm giữa đường, arrival
1463 → 1926 ps (**463 ps chỉ cho khối AMO ALU**), sau đó quay ngược ra
`u_dc_axi_bridge_u_w_fifo_u_async_fifo/g5791` rồi vào flop.

**Đây là vấn đề kiến trúc, không phải vấn đề tổng hợp:** đọc SRAM → so tag → mux way →
ALU nguyên tử → căn lane → ghi FIFO CDC, **tất cả trong một chu kỳ CPU**.

### 3.4 Về giá trị margin +0.5 ps

Con số này **không phải là "đóng được timing"**, vì:

1. **Chưa có clock tree.** `Src Latency = 0`, `Net Latency = 0` trên cả launch và capture.
   Sau CTS, skew thật + insertion delay mismatch sẽ ăn hết 0.5 ps ngay lập tức.
   Uncertainty 125 ps đã đặt là hợp lý nhưng nó *mô hình hoá* skew, không thay thế CTS.
2. **Chỉ có 1 corner TT 0.7 V 25 °C.** Chưa hề chạy SS (worst setup) hay FF (worst hold).
   Ở SS, đường 2360 ps sẽ dài thêm đáng kể.
3. **Chưa có OCV/AOCV/derate.** `set_timing_derate` không xuất hiện trong SDC lẫn
   `viewDefinition.tcl` của Innovus.
4. **Chưa route.** PLE là ước lượng, không phải RC trích xuất thật.

Ngoài ra `max_transition` trên CLK_CPU đang **chạm đúng trần 100.0 ps** ở điểm xấu nhất
trong 4 893 pin của 100 đường — nghĩa là ràng buộc DRV đang *chặn* chứ không còn dư.

**Ba lựa chọn, xếp theo mức khuyến nghị:**

| # | Phương án | Chi phí | Kết quả kỳ vọng |
|---|---|---|---|
| **A** | Đăng ký `jalr_target` ở tầng EX (thêm 1 flop 32-bit) + cắt vòng AMO bằng 1 chu kỳ phụ | RTL: trung bình; cần verify lại XSim + IPC | Lấy lại ~800–1300 ps → margin thật vài trăm ps |
| **B** | Nới `MCU_CLK_CORE_PS` từ 2500 → 2800–3000 ps (357–333 MHz) rồi mới vào Innovus | Gần như 0 | Có margin để CTS + OCV, nhưng bỏ mục tiêu 400 MHz |
| **C** | Nới cửa sổ `dont_use` LVT trong `genus.tcl` (cho phép LVT trên đường tới hạn ở `syn_map`) | Thấp | Lấy lại vài chục ps, **đổi bằng leakage** — không đủ một mình |

Khuyến nghị: **A** cho bản chính thức; nếu mục tiêu hiện tại chỉ là *đi hết flow một
lần*, thì **B** để vào Innovus ngay và giữ A cho vòng sau.

---

## 4. Area

### 4.1 Phân bố tổng

| Loại | Instance | Area (µm²) | % area |
|---|---:|---:|---:|
| timing_model (84 × SRAM) | 84 | 1 762 029 | **83.4 %** |
| sequential | 39 333 | 214 622 | 10.2 % |
| logic | 77 875 | 114 239 | 5.4 % |
| inverter | 28 084 | 20 520 | 1.0 % |
| buffer | 1 377 | 1 741 | 0.1 % |
| **Tổng cell** | **146 753** | **2 113 150** | 100 % |
| Net area (PLE) | — | 128 812 | — |

Tổng area chuẩn (không kể macro): **351 121 µm²**.

### 4.2 Xếp hạng khối (theo cell area)

| Khối | Cell | Area (µm²) | % logic |
|---|---:|---:|---:|
| **u_axi_interconnect** | **60 131** | **146 448** | **41.7 %** |
| u_core (riscv_pipeline) | 19 294 | 41 578 | 11.8 % |
| **Tổng 10 async FIFO CDC** | **17 660** | **43 875** | **12.5 %** |
| Toàn bộ ngoại vi APB + CLINT + flash + sdram + rom | ~9 300 | 36 943 | 10.5 % |
| u_axi_ram_lo / _hi (logic quanh macro) | 2 × 1 619 | ~10 000 | 2.8 % |
| u_debug_module + u_jtag_dtm | 1 556 | 3 826 | 1.1 % |

**Ba con số đáng nhớ:**

- Interconnect **gấp 3.5 lần CPU core**.
- 10 FIFO CDC **lớn hơn cả CPU core** (43 875 > 41 578 µm²).
- Icache/dcache **không xuất hiện** trong bảng — xem lỗi flow ở §6, mục F1.

### 4.3 Bên trong `u_axi_interconnect`

25 292 cell (59 071 µm²) nằm trong các sub-instance có tên; 34 839 cell còn lại đã bị
ungroup thẳng vào `u_axi_interconnect`.

Bất đối xứng rõ rệt của kênh W sau khi tham số hoá `SLV_W_FIFO_DEPTH` (T3):

| Slave | W_FIFO_DEPTH | Cell của `sa_W_channel` |
|---|---:|---:|
| SA_GEN[0] (ROM) | 2 | 282 |
| SA_GEN[1] (RAM lo) | 8 | **2 937** |
| SA_GEN[2] (QSPI flash) | 2 | 278 |
| SA_GEN[3] (SDRAM) | 8 | **2 931** |
| SA_GEN[4] (APB) | 2 | 919 |
| SA_GEN[5] (CLINT) | 2 | 992 |
| SA_GEN[6] (RAM hi) | 8 | **2 934** |

→ T3 đã có tác dụng đúng như thiết kế: ba slave băng thông cao giữ depth 8, bốn slave
còn lại giảm xuống 2 và co lại 3–10 lần. **Đây là thay đổi thành công nhất của đợt này.**

### 4.4 Elaborate → synthesis: mất 45 % số cell

| | Cell | Cell area (µm²) |
|---|---:|---:|
| Sau `elaborate` | 269 084 | 2 482 579 |
| Sau `syn_opt` | 146 753 | 2 113 150 |
| **Chênh** | **−122 331 (−45.5 %)** | **−369 429 (−14.9 %)** |

Genus phải xoá gần một nửa số cell mà RTL sinh ra. Đó **không phải lỗi của Genus** —
đó là chỉ dấu RTL đang mô tả rất nhiều logic hằng số. Xem §5.

---

## 5. Báo cáo sequential bị xoá — 27 404 flop

`reports/deleted_sequential_syn.rpt`:

| Lý do | Số flop |
|---|---:|
| constant 0 | 16 814 |
| constant 1 | 1 579 |
| unloaded | 8 616 |
| merged | 395 |
| **Tổng** | **27 404** |

So sánh: netlist cuối chỉ còn **39 417** flop. Tức là **41 %** số flop RTL suy ra đã bị
loại vì là hằng số hoặc không có tải.

Top khối "mất" nhiều flop nhất:

| Khối | Flop bị xoá |
|---|---:|
| `u_axi_interconnect/SA_GEN[0..6].slave_arbitration` (7 khối) | **13 912** |
| `u_axi_interconnect/DSP_GEN[0..3].dispatcher` | 2 720 |
| `u_ic_axi_bridge/u_aw_fifo` | 888 |
| `u_ic_axi_bridge/u_w_fifo` | 632 |
| `u_dc_axi_bridge/u_aw_fifo` | 368 |
| `u_dc_axi_bridge/u_ar_fifo` | 352 |
| `u_ic_axi_bridge/u_ar_fifo` | 320 |
| `u_axi_apb_dma/u_dma_engine` | 242 |
| `u_core/ID_EX` + `EX_MEM` + `MEM_WB` + `RF` + `CSR_RF` | 314 |

**Nguyên nhân đã truy được tận gốc:**

1. **Sideband AXI nối cứng hằng số.** `top_soc.v:1063` và `:1066`:
   ```verilog
   .m_AWLOCK_i({MST_AMT{1'b0}}), .m_AWCACHE_i({MST_AMT{4'b0011}}),
   .m_AWQOS_i({MST_AMT{4'b0000}}), .m_AWREGION_i({MST_AMT{4'b0000}}),
   ```
   `ADDR_INFO_W = DSP_ID_W + 32 + 2 + 8 + 3 + 1 + 4 + 3 + 4 + 4 = 66 bit`
   (`axi_slave_arbitration.v:183`), trong đó **16 bit là LOCK/CACHE/QOS/REGION hằng số**.
   FIFO depth 4 × 4 master × 2 kênh × 7 slave × 16 bit = **3 584 flop hằng số**, đúng
   nhóm `MST_FIFO[*].fifo_Ax_channel/mem_reg[*]` chiếm đầu bảng deleted-sequential.
2. **Master 0 (icache) không bao giờ ghi.** `top_soc.v:857-859` nối cứng
   `s_axi_awid/awaddr/awlen/... = 0`, `s_axi_wvalid = 1'b0`. Nhưng interconnect vẫn dựng
   **đủ** kênh AW/W/B cho master 0 ở cả 7 slave → toàn bộ `u_ic_axi_bridge/u_aw_fifo`
   (888 flop) và `u_w_fifo` (632 flop) là chết.
3. **ROM và QSPI flash là slave chỉ đọc**, nhưng vẫn có đủ hạ tầng arbitration ghi.

**Đánh giá:** Genus đã dọn sạch nên **không tốn diện tích**. Nhưng chi phí thật nằm ở:
runtime elaborate/generic, 4.19 GB peak memory, netlist 23.7 MB, và — quan trọng nhất —
**mỗi flop hằng số là một điểm mù cho LEC và cho DFT sau này**.

---

## 6. Vấn đề trong flow (`genus.tcl`, `constraint.sdc`, `viewDefinition.tcl`)

### 🔴 F1 — Vòng `ungroup_ok false` khớp sai tên module (6/7 thất bại)

`genus/tcl/genus.tcl:545-557`:

```tcl
foreach module_pattern {
    axi_ram  asap7_sram_1rw  tcm  riscv_pipeline
    instruction_cache  data_cache  axi_interconnect
} {
    foreach module_obj [get_db modules $module_pattern] {
        set_db $module_obj .ungroup_ok false
    }
}
```

`genus.log` chỉ in **một** dòng kết quả:

```
Setting attribute of module 'riscv_pipeline': 'ungroup_ok' = false
```

Lý do: `uniquify $TOP` (dòng 540) chạy **trước** vòng lặp, nên module đã mang hậu tố
tham số. Tên thật trong log/report là:

- `data_cache_C_CACHE_SIZE16384_C_BLOCK_SIZE16_C_WAYS2_STORE_BUF_DEPTH4`
- `axi_ram_ID_WIDTH9_ADDR_MASK32h0001ffff_MEM_DEPTH32768`
- `tcm_SIZE_BYTES16384_HAS_FETCH_PORT0`
- `asap7_sram_1rw_ADDR_W9_DATA_W19`
- `axi_interconnect_MST_AMT4_SLV_AMT7_...`

`riscv_pipeline` khớp vì nó **không có parameter**.

**Hậu quả đo được:** `reports/hierarchy_syn.rpt` không còn `u_icache`, `u_dcache`,
`u_itcm`, `u_dtcm`, `asap7_sram_1rw` nào cả — tất cả đã bị `auto_ungroup both` hoà tan
vào `top_soc`. Đó chính là lý do đường tới hạn #2 hiển thị `u_dcache_state_reg[0]` ở
**mức top**, và là lý do bảng area **không có dòng nào cho hai cache**. Chú thích ngay
trên vòng lặp — *"Keep the controller/wrapper boundary and the hard-macro array visible
for physical planning"* — hiện đang **không đúng sự thật**.

**Sửa:**

```tcl
foreach module_pattern {axi_ram asap7_sram_1rw tcm riscv_pipeline
                        instruction_cache data_cache axi_interconnect} {
    set matched [get_db modules -if {.name == $module_pattern ||
                                     .name =~ "${module_pattern}_*"}]
    if {[llength $matched] == 0} {
        error "preserve-hierarchy: khong module nao khop '$module_pattern'"
    }
    foreach module_obj $matched { set_db $module_obj .ungroup_ok false }
}
```

Thêm `error` khi không khớp là phần quan trọng nhất — lỗi này im lặng suốt nhiều run.

### 🔴 F2 — Chỉ một corner, hold dùng chung view với setup

`genus.tcl:501-533` tạo đúng **một** `library_set` (`libset_tt`), một `delay_corner`,
một `analysis_view`. `innovus/tcl/viewDefinition.tcl` lặp lại y hệt và còn khai báo
`set_analysis_view -setup {view_tt} -hold {view_tt}`.

Hệ quả: **chưa từng có phân tích hold ở corner nhanh**, và chưa có setup ở corner chậm.
ASAP7 có đủ `*_SS_*` và `*_FF_*`. Với 12 420 flop dùng `DFFASRHQNx1` (async reset) và
hàng loạt CDC, hold ở FF là rủi ro thật.

**Sửa (tối thiểu, trước khi vào Innovus):** thêm `libset_ss` + `libset_ff`, hai
`delay_corner`, hai `analysis_view`; ở Innovus đặt
`set_analysis_view -setup {view_ss view_tt} -hold {view_ff}`.

### 🟠 F3 — Chạy 1 thread

`PBS-2` xuất hiện 2 lần: *"Genus synthesis should be run with a minimum of 8 threads"*.
`Number of threads: 0 * 1` trong log. Runtime 65 phút.

**Sửa:** `set_db / .max_cpus_per_server 8` ngay sau khi set library. Kỳ vọng 2.5–4×
nhanh hơn, không đổi kết quả.

### 🟠 F4 — `lp_insert_clock_gating false` trong một MCU low-power

`genus.tcl:441`. Không có chú thích giải thích, khác hẳn phong cách phần còn lại của
file (mọi quyết định khác đều có comment dài).

Thiết kế có 39 333 flop; `power_syn.rpt` cho thấy **register chiếm 13.9 mW / 13.2 %**
tổng power, gần như toàn bộ là internal power (12.5 mW) — tức clock đang lật ở mọi flop
mọi chu kỳ. Tám clock gate thủ công (`cg_*`) chỉ gate **cả domain**, không gate theo
enable của từng bank thanh ghi.

**⚠️ ĐÍNH CHÍNH QUAN TRỌNG — ASAP7 CÓ ICG cell.** Tôi đã viết "ASAP7 public không có cell
ICG chuẩn" và điều đó **sai**. Grep chính `genus.log` của run này:

```
grep -oE "ICG[A-Za-z0-9p]*_ASAP7_75t_[RL]" genus.log | sort -u
  ICGx1_ASAP7_75t_L    ICGx2_ASAP7_75t_L    ICGx2p67DC_ASAP7_75t_L
  ICGx3_ASAP7_75t_L    ICGx4_ASAP7_75t_L    ICGx4DC_ASAP7_75t_L
  ICGx5_ASAP7_75t_L    ICGx5p33DC_ASAP7_75t_L
  ICGx6p67DC_ASAP7_75t_L                    ICGx8DC_ASAP7_75t_L
```

Đủ **10 biến thể**, đã được nạp vào Genus. Chúng chỉ xuất hiện ở đúng hai dòng trong log:

```
genus.log:1015    Setting attribute of lib_cell 'ICGx1_ASAP7_75t_L': 'dont_use' = true
genus.log:132303  Setting attribute of lib_cell 'ICGx1_ASAP7_75t_L': 'dont_use' = false
```

tức là hai lần bật/tắt của `mcu_set_lvt_dont_use` — **chưa bao giờ được dùng**, vì
`lp_insert_clock_gating false`.

**Hai hệ quả, cả hai đều quan trọng:**

1. `utils/clock_gate.v` (DLL latch + AND thủ công) là **không cần thiết**. Thay 8 instance
   `cg_*` bằng ICG thật sẽ giải quyết luôn **R9**: CTS của Innovus nhận diện được ICG,
   cân bằng đúng, và không còn rủi ro latch/AND bị đặt xa nhau. Với CLK_CPU chỉ còn
   0.5 ps margin thì `cg_cpu` là chỗ đáng lo nhất.
2. **Cả 10 ICG đều là `_L` (LVT), không có bản `_R`.** Nên công thức multi-Vt T2 —
   cấm toàn bộ `*_ASAP7_75t_L` trong `syn_generic`/`syn_map` — sẽ **chặn đúng giai đoạn
   Genus chèn clock gate**. Bật `lp_insert_clock_gating` mà không sửa `mcu_lvt_lib_cells`
   thì sẽ không có cổng nào được chèn. Phải loại `ICG*` ra khỏi danh sách `dont_use`:

   ```tcl
   proc mcu_lvt_lib_cells {} {
       set lvt {}
       foreach cell_obj [get_db lib_cells] {
           set cell_name [get_db $cell_obj .name]
           # ICG chi co ban LVT - cam chung la cam luon clock gating.
           if {[string match "ICG*" $cell_name]} { continue }
           if {[string match "*_ASAP7_75t_L" $cell_name]} { lappend lvt $cell_obj }
       }
       return $lvt
   }
   ```

Sau đó mới bật:

```tcl
set_db / .lp_clock_gating_style        latch
set_db / .lp_insert_clock_gating       true
set_db / .lp_clock_gating_min_flops    4
```

rồi kiểm tra bằng `report_clock_gating`. Nếu Genus không nhận cell tự dựng, phương án hai
là chèn enable thủ công ở các bank lớn (register file, CSR, FIFO buffer).

### 🟠 F5 — Không có bước report DRV

SDC đặt `set_max_fanout 20`, `set_max_transition 100/150/250/300` nhưng flow **không
gọi** `report_design_rules`. Ta chỉ biết DRV sạch trên 100 đường được in ra; phần còn lại
của 146 753 cell chưa được kiểm.

**Sửa:** thêm sau `syn_opt`: `report_design_rules > ./reports/drv_syn.rpt`

### 🟡 F6 — `report_area` gọi trước `syn_map` (RPT-80)

`genus.tcl:591` gọi `report_area` ngay sau `init_design`, sinh ra `area_elaborated.rpt`
**7.0 MB** và cảnh báo `RPT-80: The details given in report might be incorrect or
incomplete`. Số liệu vẫn dùng được để so sánh trước/sau, nhưng nên đổi sang
`report_area -summary` để bỏ 7 MB rác.

### 🟡 F7 — `LBR-714`: lệch đơn vị giữa các thư viện timing

```
Warning : Inconsistency detected among the units specified in the timing libraries [LBR-714]
        : Default system time/capacitance unit will be used.
```

11 thư viện được nạp, trong đó `srambank_256x4x32_6t122.lib` là file sinh riêng. Genus âm
thầm quy về đơn vị hệ thống. **Cần kiểm tra bằng tay** `time_unit` /
`capacitive_load_unit` trong `.lib` của SRAM so với `asap7sc7p5t_*`; nếu SRAM khai
`1ns/1pf` còn std cell khai `1ps/1ff` thì mọi con số setup/hold của macro đang sai hệ số
1000. Đây là loại lỗi làm hỏng cả sign-off mà không có triệu chứng nào khác.

*(Không kiểm tra được từ máy Windows này — thư viện nằm trên máy Linux
`/home/user1/Desktop/asap7/`.)*

### 🟡 F8 — Nợ DFT

Không có `set_db dft_scan_style`, không `check_dft_rules`, không `connect_scan_chains`,
không `write_scandef`. `clock_gate.v:22` ghi rõ *"Hien top_soc noi cung 1'b0 vi thiet ke
chua co scan chain"*. 11 703 cell `SDFHx*` trong netlist **không phải scan chain** — đó là
Genus dùng flop có mux-D để hợp nhất mux + flop.

Không chặn Innovus, nhưng nếu định làm đến sign-off thì scan phải chèn **ở Genus**, không
phải sau.

---

## 7. Rà soát RTL — những điểm chưa hợp lý

Xếp theo mức độ. Mỗi mục đều có bằng chứng từ report hoặc netlist của chính run này.

### 🔴 R1 — AMO đọc-sửa-ghi tổ hợp xuyên 3 module trong 1 chu kỳ

**File:** `core/pipeline_stage/pipeline_stage.v:908-953` (`memory_access`),
`memory/dcache.v:380, 542-565`

**Bằng chứng:** 99/100 đường tới hạn (§3.3); khối `SUB_TC_OP_1_Y_SUB_TC_OP20_Y_ADD_TC_OP`
chiếm 463 ps của đường 2 353 ps.

**Vấn đề:** `amo_write_data` chứa một bộ cộng 32-bit (AMOADD) và bốn bộ so sánh 32-bit
(AMOMIN/AMOMAX có dấu, AMOMINU/AMOMAXU không dấu), tất cả ăn trực tiếp `dcache_read_data`
— vốn đã là kết quả của (đọc SRAM → so tag 2-way → mux way → `read_data_with_size`). Kết
quả lại chạy ngược vào `dcache` để căn lane rồi vào FIFO CDC.

Toàn bộ chuỗi này chỉ có nghĩa cho **9 lệnh AMO của RV32A**, nhưng nó **định giá cho mọi
chu kỳ** của miền CPU.

**✅ ĐÃ ÁP 2026-09-09, làm ba phần.** Xem §12.6 để biết vì sao phải tách ba.

- **R1a — chốt payload W của đường FSM** (`dcache.v`). Đây mới là thứ trực tiếp cắt
  đường tổ hợp `AMO ALU → m_axi_wdata → FIFO CDC`. Chỉ 32+4 flop, **không tốn một chu kỳ
  nào**: fw giữ nguyên `t=1701796000`. Đáng ra phải làm cái này trước tiên.
- **R1b — bắt tay hai chu kỳ cho AMO** (`dcache.v`, `pipeline_stage.v`, `riscv_pipeline.v`,
  `top_soc.v`). `dcache_amo_req` / `dcache_amo_capture`: chu kỳ đầu trả giá trị cũ và chốt
  vào `amo_read_q`, chu kỳ sau ALU chạy từ flop. Chỉ AMO thật tốn thêm chu kỳ; LR.W và
  SC.W không đụng tới.
- **R11 — lỗi có sẵn, xem §14.**

### 🔴 R2 — `jalr_target` vẫn nằm ở IF, chưa được đăng ký

**File:** `core/pipeline_stage/pipeline_stage.v:396`

**Bằng chứng:** đường tới hạn #1 (§3.2), adder chiếm 1 326 / 2 360 ps.

**Đề xuất:** đúng như comment T1 đã viết sẵn — tính `jalr_target` ở tầng **EX** và cho qua
một flop.

**✅ ĐÃ ÁP 2026-09-09 — nhưng hai con số dự đoán ở trên đều sai, xem §12.1.**
Lợi thật là **~315 ps** (bỏ mux next-PC khỏi đường của bộ cộng), không phải 1 300 ps: bộ
cộng vẫn nằm nguyên trong một chu kỳ, chỉ có mux phía sau bị cắt. Giá thật là **+11.4 %
thời gian chạy firmware**, không phải "gần như không ảnh hưởng IPC".

### 🟠 R3 — FIFO CDC đều hard-code depth 16, không tham số hoá

**File:** `bus/axi_interconnect/axi_async_bridge.v:103,122,141,160,179`

```verilog
cdc_async_fifo_wrapper #(.DATA_WIDTH(53), .DEPTH_LOG2(4)) u_aw_fifo (...);
cdc_async_fifo_wrapper #(.DATA_WIDTH(37), .DEPTH_LOG2(4)) u_w_fifo  (...);
cdc_async_fifo_wrapper #(.DATA_WIDTH(7),  .DEPTH_LOG2(4)) u_b_fifo  (...);
cdc_async_fifo_wrapper #(.DATA_WIDTH(53), .DEPTH_LOG2(4)) u_ar_fifo (...);
cdc_async_fifo_wrapper #(.DATA_WIDTH(40), .DEPTH_LOG2(4)) u_r_fifo  (...);
```

**Bằng chứng:** 10 async FIFO = **17 660 cell / 43 875 µm²**, lớn hơn cả CPU core. Trong
đó `u_ic_axi_bridge_u_ar_fifo` một mình đã là 1 752 cell / 4 272 µm².

**Vấn đề:** icache phát **1** read outstanding (ghi chú `top_soc.v:496-503` xác nhận),
dcache cũng 1, DTM debug 1, DMA có `CMD_DEPTH = 4`. Không master nào cần 16 slot.
`async_fifo` dựng `buffer` bằng flip-flop (`fifo_async.v:59`) và đọc bằng mux tổ hợp
(`data_o = buffer[rd_addr_map]`), nên chi phí tỷ lệ thẳng với depth × width.

**Đề xuất:** đưa `AW_DEPTH_LOG2 / W_DEPTH_LOG2 / ...` lên thành parameter của
`axi_async_bridge`.

**✅ ĐÃ ÁP 2026-09-09.** Depth đặt tại `top_soc.v`: AW/B/AR = 2 (4 slot), W = 3 (8 slot,
chỉ dcache), R = 3 (8 slot, gấp đôi một burst refill 4 beat). Mặc định trong module giữ
nguyên 4 (= 16 slot) nên bất kỳ bản instantiate nào khác không đổi hành vi.

**Đính chính ước tính (§12.3):** ~25 000–30 000 µm² là **quá lạc quan**. Ba FIFO AW/W/B
của cầu icache đã bị Genus xoá sạch từ trước vì icache không bao giờ ghi, nên phần thu hồi
thật chỉ tính trên sáu FIFO còn sống: **~10 000–14 000 µm²**, tức ~3–4 % area logic. Vẫn
là thay đổi rẻ nhất trong danh sách, nhưng không phải 7–8 %.

### 🟠 R4 — Interconnect mang 16 bit sideband AXI hằng số qua mọi FIFO

**File:** `bus/axi_interconnect/axi_slave_arbitration.v:183-184`, `top_soc.v:1063,1066`

**Bằng chứng:** 13 912 flop bị xoá trong 7 khối `slave_arbitration` (§5).

**Đính chính (§12.4):** là **13 bit hằng số**, không phải 16. `top_soc.v:1063` nối cứng
LOCK (1) + CACHE (4) + QOS (4) + REGION (4) = 13 bit, nhưng **PROT (3 bit) là tín hiệu
thật của từng master** (`.m_AWPROT_i(m_axi_awprot)`) và phải giữ nguyên.

**Đề xuất:** thêm parameter `AXI_SIDEBAND_EN = 0` cùng bốn parameter mang giá trị hằng
(`AXI_LOCK_CONST`, `AXI_CACHE_CONST`, `AXI_QOS_CONST`, `AXI_REGION_CONST`) để bỏ 13 bit đó
khỏi `ADDR_INFO_W` / `AX_INFO_W` và tái tạo ở đầu ra slave. Không đổi diện tích cuối
(Genus đã dọn) nhưng cắt phần lớn thời gian elaborate/generic và giảm peak memory.

**⏳ CHƯA LÀM** — cùng R1 là hai mục còn lại của nhóm đã duyệt.

### 🟠 R5 — Crossbar 4×7 đầy đủ trong khi ma trận kết nối thật rất thưa

**File:** `bus/axi_interconnect/axi_interconnect.v`, `top_soc.v:1030-1070`

**Bằng chứng:** `u_axi_interconnect` = 41.7 % diện tích logic; master 0 (icache) chỉ đọc;
slave 0 (ROM) và slave 2 (QSPI flash) chỉ đọc.

**Đề xuất:** thêm hai parameter bitmap `MST_WR_EN[MST_AMT]` và `SLV_WR_EN[SLV_AMT]`, dùng
`generate if` để không dựng kênh AW/W/B cho các cặp không tồn tại. Ước tính bỏ được
1 master × 7 slave + 3 master × 2 slave read-only = **13 trong 28 đường ghi**.

### 🟡 R6 — `read_bank_q` suy ra kể cả khi chỉ có 1 bank

**File:** `memory/asap7_sram_1rw.v:53-57`

```
Warning : Removing unused register. [CDFG-508]
        : Removing unused flip-flop register 'read_bank_q' in module
          'asap7_sram_1rw_ADDR_W9_DATA_W19' ... on line 55.
```

`read_bank_q` chỉ được dùng trong nhánh `G_BANKED_RDATA` (`NUM_BANKS > 1`), nhưng được
khai báo và gán ngoài `generate`. Với mảng tag `ADDR_W = 9` → 1 bank → flop chết. Vô hại
nhưng gây warning ở mọi lần chạy.

**Sửa:** đưa `reg read_bank_q` và `always` block vào trong `generate ... if (NUM_BANKS > 1)`.

### 🟡 R7 — `f_starved` chết vì `HAS_FETCH_PORT = 0`

**File:** `memory/tcm.v:231`

```
Warning : Removing unused register. [CDFG-508]
        : Removing unused flip-flop register 'f_starved' in module
          'tcm_SIZE_BYTES16384_HAS_FETCH_PORT0' ... on line 231.
```

**Đính chính (§12.2):** chỉ `u_dtcm` (`top_soc.v:1009`) dùng `HAS_FETCH_PORT = 0`;
`u_itcm` (`top_soc.v:985`) dùng **1** và vẫn giữ flop này. Bản gốc viết "cả hai TCM" là
sai — `hierarchy_elaborated.rpt` có cả `tcm_..._HAS_FETCH_PORT0` lẫn
`tcm_..._HAS_FETCH_PORT1`. Cảnh báo CDFG-508 chỉ đến từ instance DTCM.

**✅ ĐÃ ÁP 2026-09-09:** `f_starved` chuyển thành `wire`, lái bởi
`generate if (HAS_FETCH_PORT != 0)` — có cổng fetch thì có flop thật, không thì là hằng số
0. ITCM không đổi hành vi một bit nào.

### 🟡 R8 — Hai nhánh `default` không thể tới trong FSM dcache

**File:** `memory/dcache.v:508` (`sb_state`), `:596` (`state`)

```
Warning : Unreachable statements for case item. [CDFG-472]
        : Case item 'default' in module data_cache_... on line 508 / 596.
```

Không sai — đó là kiểu viết phòng thủ. Nhưng với FSM mã hoá đầy đủ, `default` không tới
được nghĩa là **không có đường phục hồi thật nếu state bị lỗi mềm**. Nếu muốn giữ ý nghĩa
phòng thủ thì phải dùng one-hot + phát hiện state bất hợp lệ; nếu không, có thể bỏ để hết
warning.

### 🟡 R9 — Clock gate tự dựng chưa được khai báo cho CTS

**File:** `utils/clock_gate.v:26-36`

```verilog
reg en_latch;
always @* if (!clk_in) en_latch = en | test_en;
assign clk_out = clk_in & en_latch;
```

8 instance được map thành `DLLx1_ASAP7_75t_R` + AND (xác nhận trong netlist, dòng 11391,
73235, 84350, 98358-98402). Cấu trúc đúng về nguyên lý, và SDC có
`set_clock_gating_check -setup 50.0 -hold 50.0` cho cả 8 clock gated — tốt.

Rủi ro còn lại: `DLLx1` là latch dữ liệu thường, không phải ICG được đặc tả. **Innovus sẽ
không tự nhận ra nó là clock gate khi làm CTS** trừ khi được chỉ định rõ — latch và cổng
AND có thể bị đặt xa nhau (rủi ro hold trên đường enable), và cổng AND không phải clock
cell được cân bằng delay. Ảnh hưởng cả 8 cổng, trong đó có `cg_cpu` — miền chỉ còn
0.5 ps margin.

**Cách sửa đúng đã rõ (xem §6, F4):** ASAP7 **có** `ICGx1..ICGx8DC_ASAP7_75t_L`. Thay
`clock_gate.v` bằng ICG thật là cách xử lý triệt để, thay cho việc phải khai báo
`create_ccopt_clock_tree_spec` / `set_ccopt_property` cho một cấu trúc tự dựng. Lưu ý ICG
chỉ có bản LVT nên phải loại chúng khỏi `mcu_lvt_lib_cells`.

### 🟢 R10 — Những điều **không** phải lỗi (đã xác nhận lại trong run này)

Ghi lại để không mở lại lần sau:

- `CLK_SDRAM: No paths` — `clk_sdram_ext` chỉ được forward ra chân `sdram_clk`, không flop
  nào trong chip chạy bằng nó. Đã có giải thích ở `constraint.sdc:126-136`.
- `constraint.sdc_line_206` exception vô hiệu — đó là `set_false_path -from $RESET_PORTS`;
  đường port → synchronizer đúng là không có gì để bỏ vì reset là async.
- `rst_n` / `trst_n` không có external delay — đúng, chúng là reset async.
- `u_axi_sdram/write_data_hold` unloaded — `PHY_NARROW` bằng 0 làm nhánh ghi nửa trên
  thành code chết theo tham số, không phải lỗi.
- `u_axi_flash/shift_out_reg[31]` unloaded — bit 31 phát thẳng từ hằng số ở `R_IDLE`.
  Thừa đúng 1 flop.
- **BPU reset** và **CORDIC clock-gate**: đã sửa 2026-09-04, verify lại 2026-09-08. Run
  này không có triệu chứng tái xuất hiện (`flush_branch` không nằm trong
  deleted-sequential; `cg_cordic` vẫn còn đủ 2 cell).
- Không có `initial`, không có delay `#`, không có `casex/casez`, và **không có latch ngoài
  ý muốn** trong toàn bộ RTL — 8 latch duy nhất trong netlist đều là clock gate cố ý.

---

## 8. Power — vì sao con số hiện tại chưa dùng được

`reports/power_syn.rpt`:

| Nhóm | Leakage (W) | Internal (W) | Switching (W) | Tổng (W) | % |
|---|---:|---:|---:|---:|---:|
| memory | 0 | 0 | 0 | 0 | 0.00 % |
| register | 1.05e−5 | 1.247e−2 | 1.490e−3 | 1.397e−2 | 13.19 % |
| latch | 1.5e−9 | 5.6e−7 | 4.6e−8 | 6.1e−7 | 0.00 % |
| logic | 7.04e−6 | 1.162e−3 | 6.096e−3 | 7.265e−3 | 6.86 % |
| **bbox (84 SRAM)** | **0** | **8.460e−2** | 3.66e−5 | **8.463e−2** | **79.90 %** |
| clock | 1.2e−9 | 1.13e−6 | 5.26e−5 | 5.37e−5 | 0.05 % |
| **Tổng** | 1.750e−5 | 9.823e−2 | 7.676e−3 | **1.0592e−1** | 100 % |

Ba lý do con số này chỉ dùng để **so sánh giữa các bản tổng hợp**, không phải để báo cáo:

1. **Không có SAIF.** Log ghi rõ `Power: KHONG co SAIF`. 84.6 mW của hàng `bbox` là dynamic
   power tính từ toggle rate mặc định áp **đồng thời lên cả 84 macro**. Thực tế mỗi thời
   điểm chỉ một macro trong mỗi mảng được truy cập → con số cao hơn sự thật hàng chục lần.
2. **Leakage của SRAM = 0 theo định nghĩa** (`cell_leakage_power : 0` trong `.lib`).
   17.5 µW là leakage **chỉ của standard cell**.
3. **Hàng `clock` = 0.05 %** vì chưa có clock tree. Sau CTS ở Innovus, đây sẽ là một trong
   những hàng lớn nhất.

**Việc phải làm:** flow đã có sẵn hook `MCU_SAIF` (`genus.tcl:666-674`). Chạy
`rtl/tests/run_soc_sim.sh SAIF=1 fw` → `rtl/tests/sim_work/fw.saif`, rồi
`MCU_SAIF=<path> genus -f tcl/genus.tcl`. Chỉ sau đó mới có số power nói được điều gì.

---

## 9. Bảng ưu tiên hành động

| # | Hạng mục | Loại | Công | Lợi |
|---|---|---|---|---|
| 1 | **F1** — sửa vòng `ungroup_ok` + thêm `error` khi không khớp | flow | 15 phút | Lấy lại hierarchy cache/TCM/SRAM cho Innovus + report |
| 2 | **R3** — tham số hoá depth FIFO CDC (16 → 4) | RTL | 1–2 h | ~25–30 k µm², ~7 % area logic |
| 3 | **R2** — đăng ký `jalr_target` ở EX | RTL | nửa ngày + verify | ~1 300 ps trên đường tới hạn #1 |
| 4 | **R1** — thêm 1 chu kỳ cho AMO | RTL | nửa ngày + verify | Cắt cả họ 99 đường tới hạn |
| 5 | **F2** — thêm corner SS/FF, tách hold view | flow | 1 h | Điều kiện cần để tin bất kỳ con số nào |
| 6 | **T5** — chạy lại với `MCU_SAIF` | flow | 30 phút (đã có script) | Power lần đầu có nghĩa |
| 7 | **F3** — bật 8 thread | flow | 2 phút | Runtime 65 → ~20 phút |
| 8 | **F4** — bật clock gating tự động | flow+RTL | 2–4 h | Giảm phần lớn 12.5 mW internal của register |
| 9 | **R4 / R5** — cắt sideband + ma trận kết nối thưa | RTL | 1 ngày | Runtime/memory elaborate, dọn đường cho DFT |
| 10 | **F5–F7, R6–R8** — dọn warning, thêm `report_design_rules`, kiểm đơn vị `.lib` | flow+RTL | 2 h | Sạch log, loại rủi ro F7 |

---

## 10. Có nên chuyển sang bước tiếp theo (Innovus) chưa?

**Trạng thái Innovus hiện tại:** scaffolding đã có (`tcl/innovus.tcl`,
`macro_floorplan.tcl`, `viewDefinition.tcl`, `check_handoff.tcl`, `preflight.tcl`) nhưng
`reports/` rỗng và `outputs/top_soc_syn.innovus.sdc` còn là bản **23/08**, tức chưa từng
chạy trên netlist mới.

**Trả lời có điều kiện:**

- ❌ **Không** nên coi đây là handoff để đi tới sign-off. `+0.5 ps` pre-CTS, một corner,
  không hold, không DFT — mọi kết quả P&R sẽ phải làm lại.
- ✅ **Có** thể chạy Innovus **đến checkpoint floorplan** ngay bây giờ, vì mục tiêu của
  checkpoint đó là *"Review macro connectivity, pin access, congestion and PG strategy"* —
  84 macro và tổng area 2.11 mm² đã đủ ổn định để đánh giá floorplan, và số này sẽ không
  đổi nhiều dù có sửa R1–R5.

**Thứ tự đề nghị:**

1. Sửa **F1** (15 phút) → chạy lại Genus với **F3** (8 thread, ~20 phút) và **T5** (SAIF).
   Bản này mới là bản có hierarchy đúng để giao cho Innovus.
2. Song song, chạy `innovus -files tcl/innovus.tcl` với netlist hiện tại **chỉ để xem
   floorplan / congestion** — không CTS, không route.
3. Sau khi có ảnh floorplan, quyết định giữa **phương án A** (sửa R1+R2, giữ 400 MHz) và
   **phương án B** (hạ xuống 350 MHz, vào P&R ngay).
4. Chỉ khi đã chọn xong và có **F2** (multi-corner), mới chạy placement → CTS → route.

---

## 11. Phụ lục — lệnh tái tạo các con số trong tài liệu này

Chạy từ `Asap7/run_workspace/mcu/`:

```bash
# Slack theo domain
sed -n '/^Analysis      Cost/,/^Total/p' genus/reports/qor_syn.rpt

# Phan bo endpoint cua 100 duong xau nhat
grep "^       Endpoint:" genus/reports/timing_syn.rpt \
  | sed -E 's/.*\) //; s/\[[0-9]+\]//g' | sort | uniq -c | sort -rn

# Area theo khoi top-level
awk 'NR>21 && NF>=5 && $0 !~ /^    /' genus/reports/area_syn.rpt \
  | awk '{n=NF; printf "%8s %12s  %s\n", $(n-3), $(n-2), $1}' | sort -k2 -rn

# Flop bi xoa, gom theo module
tail -n +18 genus/reports/deleted_sequential_syn.rpt \
  | awk '{i=($1=="constant")?$3:$2; split(i,a,"/"); m=a[1]; if(a[2]!="")m=m"/"a[2]; c[m]++}
         END{for(k in c) print c[k], k}' | sort -rn | head -20

# So cell LVT con lai
grep -E "_LVT_" genus/reports/gates_syn.rpt

# Xac nhan vong ungroup_ok chi khop 1 module
grep "ungroup_ok" genus/genus.log

# Dem macro SRAM dung cach (KHONG grep netlist mot dong - xem ghi chu pitfall)
grep "srambank_256x4x32_6t122" genus/reports/gates_syn.rpt
```

---

## 12. Đính chính — những con số trong bản gốc đã được đo lại

Bản gốc của tài liệu này viết từ report Genus. Khi thực sự áp các sửa đổi và chạy XSim,
bốn chỗ hoá ra sai. Ghi lại đầy đủ thay vì sửa lặng lẽ.

### 12.1 R2 — lợi ít hơn, giá đắt hơn dự đoán

Bản gốc: *"cắt ~1 300 ps khỏi đường next-PC"* và ngụ ý IPC gần như không đổi. **Cả hai sai.**

*Lợi:* đăng ký `jalr_target` **không** loại bỏ bộ cộng khỏi đường tới hạn — nó chỉ chuyển
bộ cộng sang một chu kỳ khác và cắt phần **mux next-PC (315 ps)** ra khỏi đuôi đường.
Đường mới ở EX là `forward mux (719 ps) → bộ cộng (1 326 ps) → EX/MEM flop ≈ 2 045 ps`.
Muốn lấy 1 300 ps thì phải **pipeline chính bộ cộng**, việc đó chưa làm.

*Giá:* đo bằng `run_soc_sim.sh fw` trên cùng ảnh ROM:

| Biến thể | fw PASS tại | So baseline |
|---|---:|---:|
| Baseline (JALR resolve ở ID/EX) | `t = 1 528 046 000` | — |
| R2, `flush_jalr` **có** trong `flush_ex_mem` | `t = 2 830 376 000` | **+85 %** |
| R2, `flush_jalr` **không** trong `flush_ex_mem` ← bản đã chọn | `t = 1 701 796 000` | **+11.4 %** |

Term `flush_jalr` trong `flush_ex_mem` vừa **thừa về mặt logic** (EX/MEM đang giữ chính
lệnh JALR — nó còn phải ghi `ra`, không được xoá) vừa đắt: một mình nó chiếm 74 điểm
phần trăm. Nếu chỉ sao chép mù `flush_branch` sang `flush_jalr` ở cả bốn phương trình thì
đã ship một hồi quy 85 % mà testbench vẫn PASS — **PASS không phát hiện được hồi quy hiệu
năng**, chỉ có so sánh mốc thời gian mới thấy.

+11.4 % còn lại là giá thật của việc JALR đi từ 1 bong bóng lên 2. Firmware này gọi hàm
rất dày nên đây là **cận trên**, không phải số trung bình.

### 12.2 R7 — chỉ DTCM, không phải cả hai TCM

`top_soc.v:985` → `u_itcm` dùng `HAS_FETCH_PORT = 1`; `top_soc.v:1009` → `u_dtcm` dùng `0`.
`hierarchy_elaborated.rpt` có cả hai module `tcm_..._HAS_FETCH_PORT0` và `...PORT1`.
Cảnh báo CDFG-508 chỉ đến từ instance DTCM.

### 12.3 R3 — thu hồi diện tích khoảng một nửa ước tính ban đầu

Bản gốc nói ~25 000–30 000 µm² (7–8 % area logic). Nhưng ba FIFO **AW/W/B của cầu icache
đã bị Genus xoá sạch từ trước** (icache không bao giờ ghi — 888 + 632 flop nằm trong bảng
deleted-sequential ở §5). Chỉ sáu FIFO còn sống mới thực sự co lại:

| FIFO | Rộng × sâu cũ | Sâu mới | Area cũ (µm²) | Ước tính mới |
|---|---|---:|---:|---:|
| `u_dc_axi_bridge/u_w_fifo` | 37 × 16 | 8 | 4 850 | ~2 400 |
| `u_ic_axi_bridge/u_ar_fifo` | 53 × 16 | 4 | 4 272 | ~1 070 |
| `u_ic_axi_bridge/u_r_fifo` | 40 × 16 | 8 | 4 353 | ~2 180 |
| `u_dc_axi_bridge/u_ar_fifo` | 53 × 16 | 4 | 4 029 | ~1 010 |
| `u_dc_axi_bridge/u_aw_fifo` | 53 × 16 | 4 | 3 908 | ~980 |
| `u_dc_axi_bridge/u_b_fifo` | 7 × 16 | 4 | 517 | ~130 |
| **Tổng** | | | **21 929** | **~7 800** |

Thu hồi **~10 000–14 000 µm²** (phần điều khiển không co tuyến tính theo depth), tức
**~3–4 %** area logic, không phải 7–8 %. Vẫn là thay đổi rẻ nhất trong danh sách.

Con số chính xác chỉ biết được sau lần chạy Genus tiếp theo.

### 12.4 R4 — 13 bit hằng số, không phải 16

`top_soc.v:1063` nối cứng LOCK (1) + CACHE (4) + QOS (4) + REGION (4) = **13 bit**.
**PROT (3 bit) KHÔNG phải hằng số** — nó là `.m_AWPROT_i(m_axi_awprot)`, tín hiệu thật của
từng master. Bản gốc gộp PROT vào nhóm hằng số là sai.

### 12.5 F4 / R9 — ASAP7 **có** ICG cell

Bản gốc viết *"ASAP7 public không có cell ICG chuẩn"*. Sai. `genus.log` cho thấy 10 biến
thể `ICGx1..ICGx8DC_ASAP7_75t_L` đã được nạp, và chúng chỉ xuất hiện ở đúng hai dòng
`dont_use = true/false` của `mcu_set_lvt_dont_use` — nghĩa là có sẵn nhưng chưa từng dùng.

Điều này đổi hướng xử lý của cả F4 lẫn R9: thay `utils/clock_gate.v` bằng ICG thật là cách
triệt để. Kèm một bẫy: **ICG chỉ có bản LVT**, nên `mcu_lvt_lib_cells` đang cấm luôn chúng
trong `syn_generic`/`syn_map` — đúng giai đoạn Genus chèn clock gate. Phải loại `ICG*` ra
khỏi danh sách `dont_use` trước, nếu không bật `lp_insert_clock_gating` sẽ không có tác dụng.

---

## 13. Nhật ký thay đổi đã áp (2026-09-09)

| Mục | File | Verify |
|---|---|---|
| **F1** | `genus/tcl/genus.tcl` — khớp tên đã uniquify bằng `string match`, `error` khi không khớp | unit-test tclsh với stub: 7/7 mẫu khớp, negative test raise |
| **F2** | `genus/rtl/flow/project_config.tcl`, `genus/tcl/genus.tcl`, `innovus/tcl/viewDefinition.tcl` — thêm goc SS/FF, tách hold view, fallback khi thiếu thư viện, `timing_hold_syn.rpt` | unit-test tclsh 3 case: đủ thư viện / thiếu FF / tắt bằng env |
| **R2** | `core/pipeline_stage/pipeline_stage.v`, `core/pipeline_register/pipeline_register.v`, `core/block_unit/pipeline_control_unit.v`, `core/riscv_pipeline.v` | XSim fw PASS; đo hồi quy +11.4 % (xem §12.1) |
| **R3** | `bus/axi_interconnect/axi_async_bridge.v`, `top_soc.v` | XSim mem 109/109, apb 256/256 |
| **R6** | `memory/asap7_sram_1rw.v` | XSim mem 109/109 |
| **R7** | `memory/tcm.v` | XSim mem 109/109 |
| **R8** | `memory/dcache.v` | XSim mem 109/109, fw PASS |

**Chạy verify cuối cùng:** `rtl/tests/run_soc_sim.sh all`
→ apb **256/256 PASS**, fw **PASS** `t=1701796000`, mem **109/109 PASS**.

**Còn lại trong nhóm đã duyệt:** R1 (AMO thêm chu kỳ), R4 (sideband 13 bit).
**Để lại theo thoả thuận:** R5 (ma trận kết nối thưa).

### Bổ sung sau khi làm tiếp R1 và R4

| Mục | File | Verify |
|---|---|---|
| **R1a** | `memory/dcache.v` — chốt `fsm_wdata_q` / `fsm_wstrb_q` | mem 109/109 (T2/T6 chính là đường này); fw **không đổi** `t=1701796000` |
| **R1b** | `memory/dcache.v`, `core/pipeline_stage/pipeline_stage.v`, `core/riscv_pipeline.v`, `top_soc.v` | elaborate + 3 suite PASS — **nhưng không suite nào chạy AMO**, xem §14 |
| **R11** | `memory/dcache.v` nhánh `DONE` | như trên — **chưa có test AMO** |
| **R4** | `bus/axi_interconnect/axi_slave_arbitration.v`, `axi_interconnect.v`, `top_soc.v` | apb 256/256 + mem 109/109 đẩy giao dịch AXI thật qua interconnect |

### 12.6 Vì sao R1 phải tách làm ba

Bản gốc đề xuất R1 là "thêm một chu kỳ cho AMO". Khi lần theo netlist mới thấy điều đó
**không phải là phần quan trọng nhất**:

- Đường tổ hợp thật sự chạm tới FIFO CDC là `m_axi_wdata = sb_active ? ... :
  lane_align_wdata(cpu_write_data, ...)` — nhánh **trực tiếp**, không đi qua store buffer.
  Chốt nhánh đó (**R1a**) cắt đúng cái endpoint mà 99 đường tới hạn trỏ tới, tốn 36 flop,
  và **không tốn một chu kỳ nào**. Đây mới là thứ nên làm trước.
- Thêm chu kỳ cho AMO (**R1b**) xử lý phần còn lại: chuỗi `state → so tag → mux way →
  AMO ALU → sb_data[sb_tail]`. Cần thiết, nhưng là phần thứ hai chứ không phải thứ nhất.
- Và trong lúc lần đường đi mới lộ ra **R11**, một lỗi đúng đắn có sẵn (§14).

**Chưa làm và cần nhớ:** `pipeline_stage.v` được chia sẻ với
`D:/GITHUB_PROJECT/integrated-matrix-extension/core/` — thay đổi R2 phải vá song song
sang cây đó (kèm `pipeline_register.v`, `pipeline_control_unit.v`, `riscv_pipeline.v`).

---

## 14. 🔴 R11 — AMO trượt cache retire mà **không hề ghi** (lỗi có sẵn, phát hiện khi làm R1)

**File:** `memory/dcache.v`, nhánh `DONE`

**Đây không phải lỗi do R1 gây ra.** Nó có trong RTL từ trước, và chỉ lộ ra khi tôi lần
theo mọi đường đi của một lệnh nguyên tử để làm R1b.

**Cơ chế.** Một AMO đặt **cả** `mem_read = 1` **và** `mem_write = 1` (`control_unit.v:147-150`).
Trong `LOOKUP`, nhánh **đọc** được ưu tiên:

```verilog
if (cpu_read_req && cpu_addr == req_addr) begin
    if (hit_flag) ...              // HIT  -> sb_push chạy song song, ghi OK
    else if (sb_drained) next_state = AR_REQ;   // MISS -> đi nạp line
```

Nhưng phần ghi nằm ở `sb_push`, mà `sb_push` đòi `state == LOOKUP`:

```verilog
wire sb_push = (state == LOOKUP) && cpu_write_req && ... ;
```

Đường trượt là `LOOKUP → AR_REQ → R_WAIT → DONE`, và `DONE` nhả stall
(`dcache_stall = 0; dcache_hit = 1`). Lệnh **retire** — `sb_push` chưa bao giờ chạy.

> Một `amoadd.w` vào địa chỉ chưa nằm trong cache âm thầm biến thành một lệnh **chỉ đọc**.
> Giá trị cũ trả về `rd` đúng, nên phần mềm không thấy gì bất thường; chỉ có bộ nhớ là
> không bao giờ được cập nhật. Đúng cái kiểu lỗi phá spinlock và refcount.

**Sửa:** trong `DONE`, một AMO giữ stall và quay về `IDLE` để chạy lại vòng tra cứu. Line
vừa nạp đã được `way_update` đánh dấu valid ngay trong chu kỳ đó, nên vòng thứ hai chắc
chắn HIT và chạy đúng nhịp hai chu kỳ của R1b.

Điều kiện `!bus_err_r` là **bắt buộc**: khi refill lỗi thì `way_update` bị chặn (để một
line rác không thành hợp lệ — ghi chú B2 ở ngay trên), line không valid, nên vòng thứ hai
sẽ trượt tiếp → **lặp vô hạn**. Trường hợp đó phải nhả ra để `dcache_error` báo trap.

### ⚠️ Nợ verification — đọc trước khi tin ba mục R1a/R1b/R11

**Không testbench nào trên máy này thực thi một lệnh AMO.**

- `fw` chạy firmware thật, nhưng firmware là bài test UART bare-metal, không có atomics.
  Bằng chứng: `t=1701796000` **không đổi một pico giây nào** qua cả R1a, R1b và R11.
- `mem` (`tb_mem_paths.sv`) `force` thẳng các cổng core-side của `top_soc` và tự đóng vai
  CPU — nó **bypass** `memory_access`, tức bypass toàn bộ AMO ALU.
- Không có toolchain RISC-V trên máy (xem `[[mcu-sim-setup]]`), nên không build được
  firmware mới có atomics.

Nghĩa là: **R1a được verify thật** (nó đổi đường uncached store, đúng thứ nhóm T2/T6 của
`tb_mem_paths` kiểm), còn **R1b và R11 mới chỉ được kiểm bằng đọc code và bằng việc chúng
không làm hỏng gì khác**.

**Cách đóng lỗ hổng này**, theo thứ tự dễ dần:

1. Viết một firmware nhỏ có `lr.w`/`sc.w`/`amoadd.w`/`amoswap.w` vào **cả** địa chỉ đã
   cache và chưa cache, rồi chạy qua `run_soc_sim.sh fw`. Cần toolchain RISC-V — chưa có.
2. Mở rộng `tb_mem_paths.sv` để `force` `ex_mem_instr` với opcode `0101111` thay vì chỉ
   force cổng cache. Làm được trên máy này, nhưng phải hiểu kỹ nhịp của tầng MEM.
3. Formal/LEC so sánh trước-sau: chỉ chứng minh được R1a (không đổi hành vi), **không**
   dùng được cho R1b và R11 vì hai cái đó **cố ý** đổi hành vi.


---

## 15. ✅ Đã trả nợ verification cho R1a / R1b / R11 (2026-09-10)

Cách 2 của §14 đã được làm: **mở rộng `tb_mem_paths.sv`** để testbench đóng vai tầng MEM
cho lệnh nguyên tử, thay vì chỉ force cổng cache.

### 15.1 Cách làm

`tb_mem_paths` force các chân core-side của `top_soc` nên bỏ qua `memory_access`, tức bỏ
qua luôn AMO ALU. Bản mở rộng mô phỏng đúng ba bước mà `pipeline_stage.v` làm:

1. giữ **cả** `cpu_data_rd_req` lẫn `cpu_data_wr_req` cùng với `cpu_data_amo_req`;
2. chốt dữ liệu đọc ở chu kỳ có `cpu_data_amo_capture`;
3. từ chu kỳ sau đặt **kết quả ALU** lên `cpu_data_wdata`.

Thêm `force uut.cpu_data_amo_req` và một mux `tb_d_wdata_eff = tb_d_amo ? amo_alu :
tb_d_wdata`, cùng task `amo_w(op, addr, rs2, old_val)`. Không cần toolchain RISC-V.

### 15.2 Kết quả — `mem` 109 → **121/121 PASS**

| Test | Kiểm cái gì | Kết quả |
|---|---|---|
| T10a | `amoadd.w` vào line **đã cache** — đường R1b | old = 0x10 ✓, `dcache_amo_capture` xung **đúng 1 lần** ✓, RAM = 0x15 ✓ |
| T10b | `amoadd.w` vào line **chưa cache** — nhánh R11 | 123 chu kỳ (đúng vòng AXI refill), old đúng, capture 1 lần ✓ |
| T10b′ | **Bằng chứng mạnh cho R11**: đọc lại bằng SBA của debug module, đi thẳng qua AXI, **không** qua mảng cache | RAM thật = `0x1000_0007` ✓ |
| T10c | `amoswap.w` | ✓ |
| T10d | `amoand.w` / `amoor.w` | ✓ |

### 15.3 Negative control — test có thật sự bắt được lỗi không

Một regression test không thể fail thì vô giá trị. Đã gỡ tạm từng bản vá rồi chạy lại:

| Gỡ cái gì | Kết quả |
|---|---|
| Bỏ nhánh R11 ở `DONE` (`if (1'b0)`) | **FAIL 4** — trong đó `T10b R11: capture 0 lần` và SBA đọc RAM ra giá trị **cũ**. Đúng triệu chứng mô tả ở §14. |
| Bỏ bắt tay R1b (`amo_hold = 1'b0`) | **FAIL 11** — T10a capture 0 lần, T10b timeout 4000 chu kỳ, T10c/T10d ra sai giá trị |

`memory/dcache.v` đã được khôi phục nguyên trạng sau cả hai lần thử (grep `NEGATIVE
CONTROL` = 0).

**Kết luận: R1b và R11 giờ đã được verify bằng mô phỏng thật, không còn là "chỉ đọc code".**

### 15.4 🟠 R12 — phát hiện mới: AMO vào vùng **uncached** bị bỏ âm thầm

T10e (chỉ quan sát, không tính điểm) cho ra:

```
[INFO] T10e capture = 0 lan, RAM sau amoadd = 00000021 (ban dau 0x21, rs2 = 0x2)
[INFO] T10e AMO uncached KHONG ghi - AMO tren vung uncached bi bo am tham
```

**Cơ chế** — đây là *anh em sinh đôi* của R11, cùng một lớp lỗi:

- `dcache_amo_capture` đòi `!uncache_en` → không bao giờ xung.
- Nhánh sửa R11 ở `DONE` cũng đòi `!uncache_en` → không giữ stall.
- Ở `IDLE`, một truy cập uncached có **cả** read lẫn write đi
  `next_state = cpu_read_req ? AR_REQ : AW_REQ` — **ưu tiên đọc**, phần ghi rơi mất.

Hậu quả giống hệt R11: `rd` vẫn đúng nên phần mềm không thấy gì, chỉ có bộ nhớ là không
bao giờ được cập nhật. Nguy hiểm ở chỗ **DMAPOOL (`0x2002_0000`) là RAM bình thường được
đánh uncached để tránh hazard coherency** — một spinlock hay refcount mà phần mềm đặt vào
`.dmabuf` sẽ hỏng im lặng.

**Chưa sửa** — cần quyết định thiết kế, ba hướng:

| Hướng | Việc | Đánh đổi |
|---|---|---|
| A. Cho AMO uncached chạy thật | Thêm chuỗi `AR_REQ → R_WAIT → AW_REQ → W_REQ → B_WAIT` cho AMO | Đúng nhất, nhưng thêm state và không nguyên tử trên bus (không có lock AXI) |
| B. Trap | `dcache_error` khi `cpu_amo_req && uncache_en` → store/AMO access fault | Rẻ, an toàn, đúng tinh thần RISC-V (AMO tới vùng I/O là implementation-defined) |
| C. Chỉ ghi tài liệu | Cấm bằng quy ước phần mềm | Rẻ nhất, nhưng đúng loại lỗi im lặng mà R11 vừa dạy ta là không nên để lại |

Khuyến nghị **B**: nó biến một lỗi im lặng thành một trap nhìn thấy được, và đúng bằng
một dòng trong biểu thức `dcache_error`.

---

## 16. Khối ASCON mới — đánh giá và tích hợp vào APB (2026-09-10)

`rtl/apb_ascon/` (3 file, thêm 2026-09-08/09) chưa được nối vào SoC, chưa nằm trong
`tcl/rtl_filelist.tcl`, và chưa có test nào. Mục này xử lý cả ba.

### 16.1 Lõi thuật toán — ĐÚNG, đã chứng minh bằng KAT

`ascon_core.v` được đối chiếu từng bước với ASCON v1.2, rồi kiểm bằng testbench mới
`rtl/tests/tb_ascon_apb.sv` với vector sinh từ mô hình tham chiếu (mô hình đó đã được
xác thực trước bằng KAT chính thức của NIST LWC: Ascon128 Count=1 và Ascon-Hash chuỗi rỗng).

| Thành phần | Kết luận |
|---|---|
| Hằng số vòng `cr` | ✅ khớp `((0xf-r)<<4) or r` |
| S-box (`pS`) | ✅ khớp từng phép của bản tham chiếu, kể cả thứ tự `x1^=x0` trước `x0^=x4` |
| Lớp tuyến tính (`pL`) | ✅ cả 10 phép quay phải đúng (19/28, 61/39, 1/6, 10/17, 7/41) |
| Init AEAD | ✅ IV, K, N rồi p^12, rồi `state[127:0] ^= K` |
| pa/pb | ✅ `round<=6` cho pb (6 vòng, đúng hằng số cuối), `round<=0` cho pa |
| Domain separation | ✅ `AD_LAST` và `EMPTY_AD` đều lật bit 0 của x4 |
| Finalization | ✅ x1,x2 XOR K, p^12, TAG = (x3,x4) XOR K |
| ASCON-Hash | ✅ IV đúng, 4 khối squeeze, p^12 giữa mỗi khối |

**Kết quả chạy:** `run_soc_sim.sh ascon` → **31/31 PASS**, khớp bit-chính-xác cả C0, C1,
TAG 128-bit và HASH 256-bit.

### 16.2 🔴 A1 — Bản mã không bao giờ đọc được (đã sửa)

`data_out = x0 ^ data_in` là **tổ hợp**. Nó chỉ đúng ở đúng chu kỳ lõi hấp thụ khối. Ngay
sau đó `x0` đã bị XOR với chính `data_in`, nên `data_out` quay về **x0 cũ**, rồi 6/12 vòng
hoán vị xoá sạch. Đọc `0x40/0x44` sau `done` chỉ ra rác — tức **AEAD encrypt không dùng
được**, dù TAG vẫn đúng.

**Sửa (ở wrapper, không đụng lõi):** chốt `ct_reg <= ascon_data_out` khi
`ctrl_reg[4] && ascon_ready`. Phần mềm đọc `DATA_OUT` sau **mỗi** khối PT.

### 16.3 🔴 A2 — `done` là xung 1 chu kỳ, không polling được (đã sửa)

`STATUS` cũ trả thẳng `ascon_done`. Đó là xung một chu kỳ ở 100 MHz — phần mềm polling
qua APB (mỗi giao dịch ít nhất 2 chu kỳ) **không bao giờ bắt kịp**. `ascon_irq = ascon_done`
thì PLIC lại bắt được, vì `plic_core.v:52` chốt `if (irq_src_i[i]) ip_q[i] <= 1'b1`.

**Sửa:** thêm `done_sticky`, xoá bằng ghi 1 vào `STATUS[1]` (W1C); `ascon_irq` lấy từ
`done_sticky`.

### 16.4 🟠 A3 — Thanh ghi bị alias 16 lần (đã sửa)

Cả khối ghi lẫn read-mux chỉ so sánh `PADDR[7:0]` trong một cửa sổ 4 KB → ghi vào `0x100`,
`0x200`, … đều **trúng CTRL**. `PSLVERR` thì bị nối cứng 0 nên không có cách nào phát
hiện. **Sửa:** giải mã đủ 12 bit, và `PSLVERR` báo lỗi cho địa chỉ chưa map, đọc thanh ghi
write-only (KEY/NONCE), ghi thanh ghi read-only.

### 16.5 🟠 A4 — TRNG không có đường reset từ hệ thống (đã sửa)

`trng_128b.reset` là mức CAO và chỉ nối `ctrl_reg[2]`. **Sửa:** `~PRESETn | ctrl_reg[2]`.

### 16.6 🔴 A5 — Ring oscillator: vòng lặp tổ hợp (đã xử lý cả sim lẫn synth)

**Đo thật, không suy đoán.** Probe `RingOscillator` đứng một mình trong XSim:

```
[PROBE] en=0 taps=1010101      <- on dinh
[PROBE] bat en=1 ...
=== exit code: 124 (timeout giet) ===
```

Bật `enable` là XSim **treo cứng**: vòng 7 inverter + NAND với `assign out = ~i0` không có
trễ → dao động zero-delay, mô phỏng không bao giờ tiến được thời gian.

Về phía Genus thì ngược lại và tệ hơn: `(* DONT_TOUCH *)` / `(* KEEP_HIERARCHY *)` là **cú
pháp Vivado, Genus bỏ qua hoàn toàn**. Bảy tầng `assign out = ~i0` nối tiếp sẽ bị bộ tối ưu
Boolean **gộp thành một buffer** (hoặc xoá hẳn vì là vòng lặp tổ hợp không dẫn tới flop).
Khi đó `stateReg` của RingGenerator không còn mũi tiêm nào, mà `{stateReg[126:0],1'b0} ^
feedback` với state = 0 thì **đứng yên ở 0 vĩnh viễn** → `rand_out` luôn bằng 0. Đây là lớp
lỗi tệ nhất: mạch vẫn "chạy", `valid` vẫn lên, chỉ là không còn ngẫu nhiên.

**Cách xử lý đã áp — ba tầng, phải có cả ba:**

1. **RTL** (`trng_128b.v`): thêm nhánh `elsif ASAP7` **instantiate thẳng cell chuẩn**
   — `INVx1_ASAP7_75t_R (.A, .Y)` và `NAND2x1_ASAP7_75t_R (.A, .B, .Y)` (tên cell và tên
   chân đã đối chiếu trong `asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib` và
   `asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib`). Genus không thể "map lại" thứ mà RTL đã
   chỉ đích danh. Nhánh mô phỏng nhận trễ 50 ps mỗi tầng (~1.4 GHz) nên XSim hết treo.
2. **Cấm tối ưu** (`tcl/genus.tcl`): `read_hdl -define {ASAP7}`; thêm `RingOscillator`,
   `xilinx_not/nand`, `xilinx_primitive_not/nand` vào vòng `ungroup_ok false`; và
   `set_db <inst> .preserve true` cho mọi instance của RO — **giữ hierarchy thôi là chưa
   đủ**, vì trong từng leaf Genus vẫn có quyền đổi cell hoặc xoá mạch.
3. **Cắt vòng cho STA**: `set_disable_timing -from B -to Y` trên cell NAND (giữ nguyên
   đường enable A→Y), và `set_false_path` từ các tap của RO sang flop của RingGenerator —
   crossing đó **bất đồng bộ có chủ đích**, chính là nguồn entropy.

Cả ba khối đều dùng `error` khi không khớp tên object, theo đúng nguyên tắc của F1.

> ⚠️ **Chưa kiểm được trên công cụ.** Máy này không cài Genus, nên phần 2 và 3 mới chỉ
> viết theo tài liệu. Phần 1 (RTL + probe treo) thì đã đo thật. Lần chạy Genus tới cần
> xác nhận trong netlist là còn đủ 6 cell inverter và 1 NAND của vòng ring:
> đếm `INVx1_ASAP7_75t_R` gắn với tên `ro_invs` phải ra **6**, và `ro_nand` ra **1**.
>
> **Innovus cũng cần bước tương ứng** (chưa làm): `set_dont_touch` trên các net của vòng,
> đặt 7 cell sát nhau bằng tay, và loại chúng khỏi CTS/optDesign. Nếu để P&R tự chèn
> buffer vào vòng thì tần số dao động đổi và có thể tự tắt.

### 16.7 🟡 A6 — Những điều còn lại, **chưa sửa**, cần bạn quyết

| # | Vấn đề | Ghi chú |
|---|---|---|
| A6.1 | **Không có giải mã.** Decrypt cần `x0 <= C` chứ không phải `x0 ^= C`. Cần thêm lệnh `CMD_CT/CT_LAST` vào `ascon_core`. | Hiện chỉ mã hoá được |
| A6.2 | **Không chặn xung `DATA_VALID` sai lúc.** Nếu phần mềm xung khi lõi đang ở `ST_PROCESS`, khối bị **bỏ âm thầm** và kết quả sai mà không có lỗi nào. Nên trả `PSLVERR` khi `READY` đang thấp. | Đã ghi vào comment header |
| A6.3 | **Không có padding trong phần cứng.** Phần mềm phải tự ghép `0x80` rồi các byte 0. | Đã ghi tài liệu |
| A6.4 | **Không zeroize khoá.** KEY/NONCE giữ nguyên sau khi xong; chỉ write-only nên không đọc ngược được qua bus, nhưng vẫn nằm trong flop. | Cân nhắc bit `KEY_CLEAR` |
| A6.5 | **Entropy chưa được đánh giá.** Testbench chỉ kiểm bắt tay `valid` và `rand_out` khác 0; trong mô phỏng RO là sóng vuông **tất định**. Entropy thật chỉ đo được sau silicon hoặc analog sim. | Không nên coi TRNG này là đã kiểm chứng |

### 16.8 Đã nối vào APB như thế nào

| Thay đổi | File |
|---|---|
| Slave **S10** `0x4000_C000` mask `FFFF_F000` (4 KB) — khe trống đầu tiên sau cửa sổ 16 KB của DMA | `bus/apb_interconnect/apb_interconnect.v` |
| Wire `paddr_10..pslverr_10`, port map S10, bảng địa chỉ đầy đủ trong comment | `top_soc.v` |
| **Clock gate riêng** `cg_ascon` từ `clk_apb`, mở bằng `clk_en_asc` hoặc `ascon_clk_req` | `top_soc.v` |
| `ascon_clk_req` = `psel_10` hoặc `psel_ascon_ext` hoặc `ascon_active` — **bắt buộc**: START mất 12 chu kỳ, một khối 6/12 chu kỳ, TRNG cần 128 chu kỳ liên tục. Đây đúng là lỗi đã mắc với `apb_cordic`. | `top_soc.v` |
| `o_active` = `busy` hoặc START hoặc DATA_VALID hoặc TRNG_EN; thêm output `busy` cho `ascon_core` | `apb_ascon.v`, `ascon_core.v` |
| `CLK_GATE_CTRL` mở rộng 7→8 bit, **bit 7 = ASCON**, reset `8'b0100_0011` (giá trị số vẫn là `0x43` nên `Driver/inc/syscon.h` và firmware cũ **không hỏng**) | `peripheral/apb_syscon.v` |
| IRQ vào **PLIC nguồn 8**, qua `cdc_sync_bit` theo đúng lệ của các ngoại vi khác | `top_soc.v` |
| 3 file RTL vào filelist Genus | `tcl/rtl_filelist.tcl` |
| Suite mới `run_soc_sim.sh ascon` | `rtl/tests/run_soc_sim.sh` |

`Driver/inc/` **chưa** có header cho ASCON — cần thêm nếu firmware sẽ dùng.

### 16.9 Hồi quy cuối (2026-09-10)

`rtl/tests/run_soc_sim.sh all`:

| Suite | Trước | Sau |
|---|---|---|
| `apb` | 256/256 | **256/256 PASS** |
| `fw` | PASS `t=1701796000` | **PASS `t=1701796000`** (không đổi 1 pico giây) |
| `mem` | 109/109 | **121/121 PASS** (+12 check AMO) |
| `ascon` | — | **31/31 PASS** |
