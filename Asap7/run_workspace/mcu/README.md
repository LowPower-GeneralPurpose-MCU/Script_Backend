# MCU ASIC flow — ASAP7 + Cadence Genus/Innovus

Thư mục này là workspace đã chuẩn hóa cho `top_soc`. Toàn bộ bộ nhớ on-chip
dùng hard macro `srambank_256x4x32_6t122` (mỗi macro 1024 x 32 bit = 4 KiB),
không dùng mảng RTL suy diễn.

Ngân sách macro hiện tại là **86**, khai báo tại `genus/rtl/flow/project_config.tcl`
và được `genus.tcl` kiểm tra lại sau khi map:

| Khối | Dung lượng | Macro | Ghi chú |
|---|---|---|---|
| System RAM lo | 128 KiB | 32 | AXI slave 1 @ `0x2000_0000` |
| System RAM hi | 128 KiB | 32 | AXI slave 6 @ `0x2002_0000` |
| I-cache | 16 KiB | 6 | 2-way, 512 set (4 data + 2 tag) |
| D-cache | 16 KiB | 8 | 4-way, 256 set (4 data + 4 tag) |
| ITCM | 16 KiB | 4 | ngoài bus, nối thẳng core |
| DTCM | 16 KiB | 4 | ngoài bus, nối thẳng core |

Xem `MEMORY_ARCHITECTURE.md` để biết vì sao chia như vậy.

Bố cục chạy hiện tại:

```text
mcu/
├── genus/
│   ├── rtl/                 # 55 RTL file, SRAM wrapper và test
│   ├── tcl/                 # Genus Tcl, SDC và filelist
│   ├── outputs/             # Được tạo khi chạy, không commit
│   └── reports/             # Được tạo khi chạy, không commit
└── innovus/                 # Nhận handoff từ genus/outputs
```

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
│   ├── LIB/CCS/*.lib
│   ├── LEF/scaled/*.lef
│   ├── techlef_misc/asap7_tech_4x_201209.lef
│   └── qrc/qrcTechFile_typ03_scaled4xV06
└── asap7_sram_0p0/
    ├── generated/LIB/srambank_256x4x32_6t122.lib
    ├── generated/LEF/4xLEF/srambank_256x4x32_6t122.lef.4x.lef
    ├── generated/verilog/srambank_256x4x32_6t122.v
    └── gds/srambank_32b.gds
```

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
- SDC có 9 clock đầu vào, 8 generated clock, reset false path, nhóm clock bất
  đồng bộ, IO delay/load và giới hạn transition 300 ps.
- Genus kiểm tra hard-macro Liberty trước tổng hợp và buộc mapped netlist phải
  có đúng 32 SRAM instance.
- Innovus kiểm tra đầy đủ Liberty/LEF/QRC/GDS, chuyển SDC từ ps/fF sang ns/pF,
  rồi tạo SRAM island 4 hàng x 8 cột với halo và placement blockage.

Không chuyển register file, FIFO, ROB hoặc boot ROM sang macro này: các khối
đó cần multi-port, byte mask hoặc initialization không phù hợp với SRAM 1RW
hiện có. I-cache, D-cache và TCM thì đã dùng macro. RAM hard macro cũng không được preload từ `boot.mem`;
boot ROM hiện tại vẫn đảm nhiệm nội dung khởi động.

Có thể kiểm tra độc lập AXI-to-SRAM controller bằng model đồng bộ chính thức:

```bash
bash genus/rtl/tests/run_rtl_lint.sh
bash genus/rtl/tests/run_axi_ram_verilator.sh
```

Lệnh đầu lint cấu trúc toàn bộ 55 RTL file với top `top_soc`. Lệnh thứ hai bao
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
chuẩn bị trước tổng hợp. Mặc định Genus dùng một process và effort `high`; chỉ
bật super-thread khi license đã sẵn sàng qua `GENUS_ENABLE_SUPER_THREAD=1`.
Có thể dùng `GENUS_CPUS` và `GENUS_SYN_EFFORT=low|medium|high` để điều chỉnh
lần chạy đầu. Sau khi chạy, cần kiểm tra ít nhất:

- `reports/check_design_unresolved.rpt`
- `reports/timing_intent_post_syn.rpt`
- `reports/timing_syn.rpt`, `area_syn.rpt`, `power_syn.rpt`
- `reports/messages_all.rpt`
- `outputs/top_soc_syn.v` phải chứa đúng 86 SRAM macro

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
