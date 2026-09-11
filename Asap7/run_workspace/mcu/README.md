# MCU ASIC flow — ASAP7 + Cadence Genus/Innovus

Thư mục này là workspace đã chuẩn hóa cho `top_soc`. Toàn bộ bộ nhớ on-chip
dùng hard macro sinh từ `asap7_sram_0p0`, không dùng mảng RTL suy diễn:

- `srambank_256x4x32_6t122` — 1024 x 32 bit = 4 KiB: RAM, data cache, TCM.
- `srambank_128x4x20_6t122` — 512 x 20 bit: tag cache (19 bit tag, dùng 95 %).

Ngân sách macro hiện tại là **84 = 80 + 4**, khai báo tại
`genus/rtl/flow/project_config.tcl` và được `genus.tcl` kiểm tra lại cả trước
tổng hợp lẫn sau khi map:

| Khối | Dung lượng | Macro 256x4x32 | Macro 128x4x20 | Ghi chú |
|---|---|---|---|---|
| System RAM lo | 128 KiB | 32 | — | AXI slave 1 @ `0x2000_0000`, cacheable |
| System RAM hi | 128 KiB | 32 | — | AXI slave 6 @ `0x2002_0000`, **uncached** (DMAPOOL) |
| I-cache | 16 KiB | 4 | 2 | 2-way, 512 set |
| D-cache | 16 KiB | 4 | 2 | 2-way, 512 set, write-through, store buffer 4 entry |
| ITCM | 16 KiB | 4 | — | ngoài bus, nối thẳng core |
| DTCM | 16 KiB | 4 | — | ngoài bus, nối thẳng core |
| **Tổng** | | **80** | **4** | |

Xem `MEMORY_ARCHITECTURE.md` để biết vì sao chia như vậy, và
`MEMORY_FIX_PLAN.md` / `CORE_FIX_PLAN.md` / `GENUS_REVIEW_2026-09-09.md` để biết
cái gì đã sửa, cái gì còn mở.

Bố cục chạy hiện tại:

```text
mcu/
├── genus/
│   ├── rtl/                 # 58 RTL file tổng hợp, SRAM wrapper, tests/
│   ├── tcl/                 # Genus Tcl, SDC và filelist
│   ├── outputs/             # Netlist/SDC của lần chạy gần nhất (đang được commit)
│   └── reports/             # Report của lần chạy gần nhất (đang được commit)
└── innovus/                 # Nhận handoff từ genus/outputs
```

`outputs/` và `reports/` là sản phẩm của Genus nhưng hiện **có trong git** để
máy không có license (Windows) đọc được kết quả. Chúng chỉ đúng với RTL tại
commit đã sinh ra chúng. Bản đang commit là lần chạy **2026-09-10 18:47**, tức
**trước** ba thay đổi: tag cache sang `srambank_128x4x20` (netlist vẫn có 84 ×
`256x4x32`), `FENCE` (P2c), và `CLK_ASCON` trong SDC (netlist có 9 clock gate
nhưng SDC chỉ 18 clock). Lần chạy lại cho cấu hình 80 + 4 đang được thực hiện.

## Baseline collateral

Flow được khóa theo hai revision:

- `asap7sc7p5t_28`: `f970bd3c3292b79ae4d022a3ec80533534614066`
- `asap7_sram_0p0`: `522eeccbccefcd66e61893fa1059df24d95e9f86`

Đặt hai repository cạnh nhau trong một thư mục. Flow lần lượt ưu tiên biến môi
trường, collateral đầy đủ trong `Asap7/asap7`, rồi mới dùng đường dẫn legacy
`/home/user1/Desktop/asap7`:

```text
$ASAP7_ROOT/
├── asap7sc7p5t_28/
│   ├── LIB/CCS/*.lib          # TT bắt buộc; SS/FF dùng cho multi-corner (F2)
│   ├── LEF/scaled/*.lef
│   ├── techlef_misc/asap7_tech_4x_201209.lef
│   └── qrc/qrcTechFile_typ03_scaled4xV06
└── asap7_sram_0p0/
    ├── generated/LIB/srambank_256x4x32_6t122.lib
    ├── generated/LIB/srambank_128x4x20_6t122.lib
    ├── generated/LEF/4xLEF/srambank_{256x4x32,128x4x20}_6t122.lef.4x.lef
    ├── generated/verilog/srambank_{256x4x32,128x4x20}_6t122.v
    └── gds/srambank_32b.gds
```

Hai `.lib` SRAM chỉ có ở góc TT; cả ba `library_set` (TT/SS/FF) trỏ chung vào
chúng, nên độ trễ macro **không đổi theo góc**. Nếu máy thiếu `*_SS_*` /
`*_FF_*` của standard cell, `genus.tcl` tự lùi về một góc TT.

Các Liberty standard-cell trong repository được lưu dưới dạng `.lib.7z`; phải
giải nén để đường dẫn `LIB/CCS/*.lib` tồn tại trước khi chạy Genus.

Ngoài `ASAP7_ROOT`/`ASAP7_HOME`, flow hỗ trợ các override tách riêng như
`ASAP7_STDCELL_ROOT`, `ASAP7_SRAM_ROOT`, `ASAP7_STD_LIB_DIR`,
`ASAP7_SRAM_LIB_FILE` và `ASAP7_TECH_LEF_FILE`.

## Những gì đã chuẩn hóa

- `genus/rtl/memory/axi_ram.v` là AXI4 slave nối tới SRAM 1RW, kích thước theo
  tham số `MEM_DEPTH`; ghi dưới 32 bit dùng read-modify-write vì macro không có
  byte-write mask. Một instance tuần tự hóa mọi truy cập trong vùng của nó, nên
  System RAM được chia thành **hai** instance trên hai slave port khác nhau để
  CPU và DMA thực sự chạy song song.
- `genus/rtl/memory/asap7_sram_1rw.v` là mảng bank tổng quát: `addr[ADDR_W-1:10]`
  chọn macro, `addr[9:0]` chọn hàng. Cache, TCM và axi_ram đều dùng lại nó, nên
  chỉ cần đổi tham số là đổi số macro. Behavioral Verilog của macro chỉ dành cho
  mô phỏng, không nằm trong filelist tổng hợp.
- `genus/rtl/memory/tcm.v` là ITCM/DTCM nối thẳng vào core port, nằm ngoài AXI
  interconnect: không bao giờ miss, không bao giờ xếp hàng sau DMA. Latency là
  hằng số 2 chu kỳ (3 với store byte/halfword do read-modify-write), bằng đúng
  cache hit - cái được bỏ đi là trường hợp miss và tranh chấp bus, không phải
  chu kỳ pipeline.
- Filelist RTL có thứ tự cố định và include path tương thích filesystem Linux.
- Các kết nối hở/implicit net quan trọng ở cache, APB và lane 1 của core đã
  được xử lý trước khi tổng hợp.
- SDC có **19 clock**: 9 clock đầu vào, 1 forwarded (`sdram_clk`) và 9 gated
  (`CPU DBG PWM GPIO CORDIC ASCON UART_G SPI_G I2C_G`), cộng reset false path,
  nhóm clock bất đồng bộ, IO delay/load và giới hạn transition 300 ps.
  `genus.tcl` dừng nếu số clock khác `EXPECTED_CLOCKS`.
- Genus kiểm tra hard-macro Liberty trước tổng hợp và buộc mapped netlist phải
  có đúng **80** `srambank_256x4x32_6t122` và **4** `srambank_128x4x20_6t122`.
- Innovus kiểm tra đầy đủ Liberty/LEF/QRC/GDS, chuyển SDC từ ps/fF sang ns/pF,
  rồi tạo ba SRAM island từ trái sang phải — RAM 8 x 8, cache 8 x 2 (cache data
  + TCM), tag 4 x 1 — với halo và placement blockage.

Không chuyển register file, FIFO, ROB hoặc boot ROM sang macro này: các khối
đó cần multi-port, byte mask hoặc initialization không phù hợp với SRAM 1RW
hiện có. I-cache, D-cache và TCM thì đã dùng macro. RAM hard macro cũng không được preload từ `boot.mem`;
boot ROM hiện tại vẫn đảm nhiệm nội dung khởi động.

Ngoại vi APB: UART, GPIO, PWM, SPI, I2C, Watchdog, CORDIC, Syscon, DMA config,
PLIC, và **ASCON-128 / ASCON-Hash + TRNG** ở S10 `0x4000_C000` (IRQ = PLIC
nguồn 8, clock gate riêng `cg_ascon`, bit 7 của `CLK_GATE_CTRL`). Bảng địa chỉ
đầy đủ nằm ngay trên `apb_interconnect` trong `top_soc.v`.

Có thể kiểm tra độc lập AXI-to-SRAM controller bằng model đồng bộ chính thức:

```bash
bash genus/rtl/tests/run_rtl_lint.sh
bash genus/rtl/tests/run_axi_ram_verilator.sh
```

Bốn testbench mức SoC chạy bằng Vivado XSim:

```bash
bash genus/rtl/tests/run_soc_sim.sh all
```

| Suite | File | Phủ | Kết quả gần nhất |
|---|---|---|---|
| `apb` | `Test_bench/SoC_testbench.sv` | quét thanh ghi ngoại vi APB | 256/256 (2026-09-10) |
| `fw` | `Driver/tb_top_soc.v` | firmware thật qua CPU tới khi in UART và WFI | PASS `t = 1 701 796 000` (2026-09-10) |
| `mem` | `genus/rtl/tests/tb_mem_paths.sv` | RAM uncached, ITCM/DTCM, trọng tài F/D, DMA, thứ tự MMIO, store buffer, `fence`, debugger SBA, AMO, đo độ trễ hit/miss | 121/121 (2026-09-10); **mong đợi 128** sau P2c — chưa chạy lại |
| `ascon` | `genus/rtl/tests/tb_ascon_apb.sv` | KAT ASCON-128 / ASCON-Hash qua APB, TRNG | 31/31 (2026-09-10) |

`mem` không cần firmware: nó `force` các chân core-side của `top_soc` và tự đóng
vai CPU (kể cả tầng MEM cho AMO). Xem [MEMORY_FIX_PLAN.md](MEMORY_FIX_PLAN.md)
mục 5. Trong Vivado GUI dùng `genus/rtl/tests/vivado_sim_mem.tcl`.

Mốc `t` của `fw` là **chỉ báo alignment/hồi quy**, không phải benchmark — xem
CORE_FIX_PLAN.md §6.

Lệnh đầu lint cấu trúc toàn bộ 58 RTL file với top `top_soc`. Lệnh thứ hai bao
phủ full-word write/read, byte-strobe read-modify-write, chọn bank và phản hồi
`SLVERR` cho địa chỉ không word-aligned. Danh sách warning bị miễn trong lint
là warning debt của RTL gốc; báo cáo Genus/CDC/RDC vẫn phải được review độc lập.

## Chạy Genus

Chạy trong Linux có Cadence license và đã thiết lập `ASAP7_ROOT`:

```bash
cd Asap7/run_workspace/mcu/genus
genus -files tcl/genus.tcl
```

`genus.tcl` tự đọc config, filelist, SDC, timing Liberty và tự chạy các check
chuẩn bị trước tổng hợp. Các nút chỉnh là **biến Tcl ở đầu `genus.tcl`**, không
phải biến môi trường:

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `SYN_EFFORT` | `high` | `low` / `medium` / `high` |
| `MULTI_CORNER` | `1` | `0` = chỉ góc TT |
| `MULTI_VT` | `1` | cấm LVT ở `syn_generic`/`syn_map`, mở lại ở `syn_opt` |
| `GENUS_PHYSICAL` | `1` | LEF + QRC + PLE (có trễ dây ước lượng) |

Genus chạy **một thread** (`max_cpus_per_server 0`, cảnh báo PBS-2, ~75 phút) —
xem F3 trong GENUS_REVIEW. Biến môi trường mà flow đọc: `ASAP7_*` (đường dẫn
collateral, ở trên), `MCU_CLK_<DOMAIN>_PS` / `MCU_MAX_TRAN_*_PS` (trong SDC, ở
dưới) và `MCU_SAIF=<file>` để số power có nghĩa. Sau khi chạy, cần kiểm tra ít nhất:

- `reports/check_design_unresolved.rpt`
- `reports/timing_intent_post_syn.rpt`
- `reports/qor_syn.rpt` — slack theo **từng view** (`view_ss`, `view_tt`)
- `reports/timing_syn.rpt`, `area_syn.rpt`, `power_syn.rpt`
- `reports/messages_all.rpt`
- `outputs/top_soc_syn.v` phải chứa đúng 80 + 4 SRAM macro (flow tự kiểm)

Hold **không** báo cáo ở Genus (TUI-745); nó được đóng ở Innovus với
`view_ff`.

Kết quả lần chạy đang commit (2026-09-10, cấu hình cũ 84 × `256x4x32`, trước
P2c): CLK_CPU **+812.6 ps** ở TT nhưng chỉ **+1.3 ps** ở SS; CLK_AXI **+1.1 ps**
ở SS. Chi tiết và ý nghĩa ở
[GENUS_REVIEW_2026-09-09.md](GENUS_REVIEW_2026-09-09.md) §17.

## Chạy Innovus đến checkpoint floorplan

```bash
cd Asap7/run_workspace/mcu/innovus
tclsh preflight.tcl
innovus -stylus -files innovus.tcl
```

Script chủ động dừng tại `saved/top_soc_floorplan.enc`. Hãy review macro pin
access, PG connectivity, congestion và kích thước core trước khi bổ sung power
plan, placement, CTS, route, fill và stream-out. Đây chưa phải flow signoff.

Có thể chỉnh utilization/kích thước core mà không sửa Tcl:

```bash
export MCU_TARGET_STD_UTIL=0.55
# Chỉ dùng hai biến sau nếu đã tính được kích thước floorplan phù hợp:
export MCU_CORE_WIDTH_UM=0
export MCU_CORE_HEIGHT_UM=0
```

## Giả định timing cần xác nhận

Ba clock có comment rõ trong RTL được đặt lần lượt 400/200/100 MHz cho
core/AXI/APB. SDRAM là 200 MHz và RTC là 32.768 kHz. Các mặc định UART 50 MHz,
SPI 50 MHz, I2C 10 MHz và JTAG 10 MHz là giả định chuẩn bị flow, chưa phải đặc
tả hệ thống. Có thể override bằng `MCU_CLK_<DOMAIN>_PS`, ví dụ:

```bash
export MCU_CLK_UART_PS=40000
export MCU_CLK_TCK_PS=200000
```

Việc đặt tất cả clock input thành các nhóm bất đồng bộ dựa trên kiến trúc CDC
hiện tại. Trước tapeout phải review CDC/RDC độc lập và xác nhận quan hệ phase
thực tế của board/PLL. ASAP7 là PDK nghiên cứu; cần bổ sung power intent, DFT,
IR/EM, extraction, DRC/LVS và signoff rule deck phù hợp với môi trường sử dụng.
