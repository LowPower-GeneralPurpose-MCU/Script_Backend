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
├── innovus/                 # Nhận handoff từ genus/outputs
├── conformal/               # LEC: genus/outputs/top_soc_syn.v vs innovus/outputs/top_soc_pnr.v
├── quantus/                 # Trích RC signoff từ innovus/saved/top_soc_final.enc.dat -> SPEF
├── tempus/                  # STA signoff trên SPEF Quantus
├── voltus/                  # Công suất + IR drop
└── eco/                     # ECO sửa DRV mà Tempus báo, rồi chạy lại KHỐI 15 + 16
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

Không chuyển register file, FIFO hay ROB sang macro này, vì các khối đó cần
multi-port hoặc byte mask. Boot ROM cũng **cố ý không dùng macro**: macro SRAM là X
lúc cấp nguồn và ASAP7 không có ROM compiler. Boot ROM là **mask ROM 32 KiB tổng hợp
thành logic** từ `rtl/memory/boot.mem`, chứa mã boot tầng 1: đặt `mtvec`, kiểm
header ảnh ở đầu QSPI flash, chép (tuỳ chọn) rồi nhảy vào firmware chạy XIP.
Phương án shadow ROM trên 2 macro + loader phần cứng đã thử rồi bỏ; lý do, định
dạng header và luồng boot ở [MEMORY_ARCHITECTURE.md](MEMORY_ARCHITECTURE.md)
mục 6. Rà soát "còn chỗ nào thiếu vùng nhớ" ở
[MEMORY_FIX_PLAN.md](MEMORY_FIX_PLAN.md) mục 8.

Ngoại vi APB: UART, GPIO, PWM, SPI, I2C, Watchdog, CORDIC, Syscon, DMA config,
PLIC, và **ASCON-128 / ASCON-Hash + TRNG** ở S10 `0x4000_C000` (IRQ = PLIC
nguồn 8, clock gate riêng `cg_ascon`, bit 7 của `CLK_GATE_CTRL`). Bảng địa chỉ
đầy đủ nằm ngay trên `apb_interconnect` trong `top_soc.v`.

Có thể kiểm tra độc lập AXI-to-SRAM controller bằng model đồng bộ chính thức:

```bash
bash genus/rtl/tests/run_rtl_lint.sh
bash genus/rtl/tests/run_axi_ram_verilator.sh
```

Năm testbench chạy bằng Vivado XSim:

```bash
bash genus/rtl/tests/run_soc_sim.sh all
```

| Suite | File | Phủ | Kết quả gần nhất |
|---|---|---|---|
| `apb` | `Test_bench/SoC_testbench.sv` | quét thanh ghi ngoại vi APB | 256/256 (2026-09-10) |
| `fw` | `Driver/tb_top_soc.v` | firmware thật qua CPU tới khi in UART và WFI | PASS `t = 1 701 796 000` (2026-09-10) — **mốc hết hiệu lực sau R13**, xem CORE_FIX_PLAN.md §10; ảnh firmware nay phải ≤ 32 KiB |
| `mem` | `genus/rtl/tests/tb_mem_paths.sv` | RAM uncached, ITCM/DTCM, trọng tài F/D, DMA, thứ tự MMIO, store buffer, `fence`, debugger SBA, AMO, đo độ trễ hit/miss | 121/121 (2026-09-10); **mong đợi 128** sau P2c — chưa chạy lại |
| `ascon` | `genus/rtl/tests/tb_ascon_apb.sv` | KAT ASCON-128 / ASCON-Hash qua APB, TRNG | 31/31 (2026-09-10) |
| `core` | `genus/rtl/tests/tb_core_jalr.sv` | R13 (lệnh đường sai sau JALR) và R14 (link của JALR) trên CPU thật, ảnh ROM `tests/core_jalr.mem` | mới 2026-09-11, **chưa chạy** |

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

## Chạy Conformal LEC sau Innovus

Sau khi KHỐI 16 của `innovus/tcl/innovus.tcl` ghi `outputs/top_soc_pnr.v`:

```bash
cd Asap7/run_workspace/mcu/conformal
make all
```

`conformal.tcl` so netlist Genus (golden) với netlist sau P&R (revised) theo
kiểu phân cấp (`write_hier_compare_dofile` + `run_hier_compare`), dùng chung
`genus/rtl/flow/project_config.tcl` để lấy thư viện. Hai master SRAM và
`RingOscillator` (vòng tổ hợp của TRNG) là hộp đen ở cả hai bên; bên trong
`RingOscillator` được so cấu trúc bằng Tcl trước khi LEC chạy. Script dừng ngay
nếu hai netlist không cùng một lần tổng hợp Genus.

Kết luận nằm ở dòng đầu `reports/lec_verdict.txt` (`PASS` / `FAIL` /
`UNKNOWN`); `make` trả lỗi nếu không phải `PASS`. Chi tiết:
`reports/lec_hier_result.rpt`, `lec_verification.rpt`, `lec_noneq.rpt`,
`lec_unmapped.rpt`, `lec_black_box.rpt` và `logs/conformal.log`.

| Biến `make` | Mặc định | Ý nghĩa |
|---|---|---|
| `LEC` | `lec` | tên lệnh Conformal (mẫu môn học dùng `lec_64`) |
| `LEC_MODE` | `hier` | `flat` = so phẳng cả thiết kế |
| `LEC_THREADS` | `1` | số thread; >1 làm `lec` treo ở `compare` trên máy này (2026-10-01) |
| `GOLDEN` / `REVISED` | hai file ở trên | đổi netlist đem so |

RTL → netlist tổng hợp là bước riêng, dùng dofile Genus tự sinh
(`genus/outputs/genus_mapping_hints.do`).

## Chạy Quantus (trích RC signoff) sau Conformal

Cả flow Innovus trích RC bằng tQuantus (`-effortLevel medium`), kể cả SPEF mà
KHỐI 16 xuất ra. Bước này trích lại bằng Quantus QRC có tụ ghép để STA signoff
dùng RC độc lập với công cụ đã tối ưu thiết kế:

```bash
cd Asap7/run_workspace/mcu/quantus
make all
```

`quantus.tcl` chạy trong Innovus (batch, thư mục `mcu/innovus`): nạp
`saved/top_soc_final.enc.dat`, xoá metal fill lớp `Pad` **trong RAM** (QRC tech
file không có lớp Pad), `extractRC` ở `-effortLevel signoff -coupled true`, rồi
`rcOut` ba góc ra `quantus/outputs/top_soc_quantus_{rc_typ,rc_ss,rc_ff}.spef`.
Script không `saveDesign`.

`quantus/reports/quantus_summary.rpt` có dòng đầu `DONE` khi xong, kèm số net
và tổng điện dung từng góc, đối chiếu với SPEF tQuantus của KHỐI 16
(`innovus/outputs/top_soc_pnr_<rc>.spef`).

| Biến `make` | Mặc định | Ý nghĩa |
|---|---|---|
| `QUANTUS_EFFORT` | `signoff` | `high` = IQuantus tích hợp, dùng khi máy không có lệnh `qrc` |
| `QRC_BIN` | tìm trong `PATH` | đường dẫn đầy đủ tới lệnh `qrc` |
| `QUANTUS_CPUS` | `8` | đặt `1` nếu `qrc` treo khi chạy nhiều tiến trình |
| `INNOVUS` | `innovus` | tên lệnh Innovus |

## ECO sửa DRV mà Tempus báo (sau Tempus)

Innovus tối ưu trên RC tQuantus với lớp LEF/QRC ghép lệch một bậc, nên nó không
thấy các chân `max_transition` mà Tempus báo trên SPEF Quantus (C ×1.084). Bước
này mở lại checkpoint cuối KHỐI 14, trích RC bằng đúng engine đã sinh SPEF
signoff rồi chạy lại lượt tối ưu của KHỐI 14 (setup + hold + DRV):

```bash
cd Asap7/run_workspace/mcu/eco
make all       # saved/top_soc_postRoute.enc.dat -> top_soc_postRoute_eco.enc.dat
make fillfix   # đo + sửa max_transition khi đã có metal fill -> top_soc_postRoute_ecofill.enc.dat
make finish    # KHỐI 15 + 16 trên checkpoint mà fillfix chỉ ra, GHI ĐÈ innovus/outputs/
```

Dòng đầu của `eco/reports/eco_summary.rpt` và `eco_fillfix_summary.rpt` là
`PASS`/`FAIL`, của `eco_finish_summary.rpt` là `DONE`/`FAIL`. `PASS` chỉ nói
Innovus sạch trên RC như signoff; kết luận là của Tempus, nên sau `make finish`
phải chạy lại `conformal`, `quantus`, `tempus` (netlist đã đổi).

`make fillfix` là bắt buộc giữa hai bước: `make all` tối ưu trên RC **chưa có
metal fill**, còn cổng timing của KHỐI 15/16 đo **sau** fill. Run 2026-10-12:
`make all` PASS với 0 net `max_tran`, `make finish` dừng với 64 net (xấu nhất
−25 ps) — tăng `ECO_DRV_MARGIN` từ 0.05 lên 0.25 không đổi gì, vì đó là những
net `optDesign` ghi "can't be fixed" (driver chỉ có bản x1, hold buffer
`HB1xp67`). `eco_fillfix.tcl` đổ fill thử trên database chưa có filler, đo, chèn
buffer cho từng net vượt giới hạn (`ecoAddRepeater`), route lại, rồi đổ fill và
đo lại, tối đa `ECO_FILL_ROUNDS` vòng; checkpoint nó lưu không chứa fill. Từng
net và cách xử lý nằm trong `eco/reports/fillfix_nets.rpt`.

Cách chèn tuỳ loại net (luật rút từ run 2026-10-12 21:13, xem `eco_buffer_nets`):

| Loại net | Cách xử lý |
|---|---|
| một tải | buffer dọc theo dây, sát driver (`-relativeDistToSink`) |
| nhiều tải, chính chân ra của driver cũng vi phạm (driver yếu) | buffer nối tiếp, kéo mọi tải |
| nhiều tải, driver không vi phạm (driver đã mạnh), vi phạm thật | buffer mạnh kéo nửa số tải xấu nhất (`-term`) |
| nhiều tải, driver không vi phạm, chỉ nằm trong khoảng dư | **không đụng** — chèn `BUFx4` sau `BUFx10` đã biến +6 ps thành −94 ps |

| Biến `make` | Mặc định | Ý nghĩa |
|---|---|---|
| `ECO_FILL_GUARD` | `0.010` | ns; khi đo, siết giới hạn `max_transition` theo clock thêm chừng này để sửa cả net sát giới hạn (`0` = đo đúng giới hạn thật) |
| `ECO_FILL_ROUNDS` | `3` | số vòng sửa tối đa |
| `ECO_FILL_BUF` | `BUFx4_ASAP7_75t_R` | buffer được chèn |
| `ECO_FILL_BUF_STRONG` | `BUFx10_ASAP7_75t_R` | buffer cho net mà driver vốn đã mạnh (tách tải) |
| `ECO_FILL_DIST` | `0.9` | `ecoAddRepeater -relativeDistToSink` (1 = sát driver), chỉ cho net một tải |
| `ECO_FINISH_IN` | — | `make finish ECO_FINISH_IN=./saved/<tên>.enc.dat`: bỏ qua `fillfix` có chủ đích |

`eco_drv.tcl` từ chối chạy khi checkpoint còn `.lib` sai điện áp: `saveDesign`
chép `.lib` vào `<tên>.enc.dat/libs/mmmc/` và `restoreDesign` nạp bản sao đó,
không phải file của PDK. `innovus/scripts/fix_ff_lib.py` kiểm tra điện áp mọi
`.lib` std cell, tìm bản đúng (file nén / git của PDK) và với `--apply` thay cả
file trong PDK lẫn các bản sao trong `innovus/saved/*.enc.dat`.

Ngoại lệ: `asap7sc7p5t_SIMPLE_RVT_FF_ccs_211120.lib` là process FF nhưng đo ở
0.7 V / 25 °C (các lib FF khác 0.77 V / 0 °C), và cả bản trong git của PDK lẫn
bản gốc trên GitHub đều như vậy — không có file đúng để thay. Flow bù bằng
derate `-early -cell_delay` trên `dc_ff` cho riêng cell của lib này:
`STD_FF_LOWV_DERATE` trong `genus/rtl/flow/project_config.tcl` (tạm `0.90`,
`1.0` = tắt), được `tempus.tcl`, `innovus/tcl/init_common.tcl` và `eco_drv.tcl`
gọi qua cùng một proc `mcu_apply_ff_lowv_derate`. Khi derate đang bật, lib này
chỉ còn là `WARNING` trong `eco_drv.tcl`; mọi lib sai điện áp khác vẫn chặn.
Đo hệ số trên máy có PDK rồi sửa con số:

```bash
cd Asap7/run_workspace/mcu/innovus
python3 scripts/fix_ff_lib.py --derate
```

Sau mỗi lần chạy, kiểm `reports/timing_derate.rpt` (Tempus, ECO) hoặc
`reports/sram_derate.rpt` (Innovus): phần `dc_ff` phải có dòng `Cell Delay`
mang hệ số đó; thiếu thì file tóm tắt có `WARNING`.

| Biến `make` | Mặc định | Ý nghĩa |
|---|---|---|
| `ECO_EXTRACT` | `high` | `flow` = giữ chế độ trích RC của checkpoint (Innovus sẽ không thấy vi phạm) |
| `ECO_DRV_MARGIN` | `0.05` | `setOptMode -drcMargin`: siết giới hạn DRV khi sửa |
| `ECO_CPUS` | `1` | IQuantus nhiều tiến trình đã treo trên máy đang dùng |
| `ECO_CHECKPOINT` | `./saved/top_soc_postRoute.enc.dat` | tính từ `mcu/innovus` |
| `ECO_ALLOW_BAD_LIB` | *(trống)* | `1` = vẫn chạy khi checkpoint còn `.lib` sai điện áp (không cần cho `SIMPLE_RVT_FF` khi `STD_FF_LOWV_DERATE` bật) |

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
