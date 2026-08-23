# MCU ASIC flow — ASAP7 + Cadence Genus/Innovus

Thư mục này là workspace đã chuẩn hóa cho `top_soc`. Flow giữ nguyên vùng RAM
chính 128 KiB của MCU, nhưng thay mảng RTL suy diễn bằng 32 hard macro
`srambank_256x4x32_6t122` (mỗi macro 1024 x 32 bit, tương đương 4 KiB).

## Baseline collateral

Flow được khóa theo hai revision:

- `asap7sc7p5t_28`: `f970bd3c3292b79ae4d022a3ec80533534614066`
- `asap7_sram_0p0`: `522eeccbccefcd66e61893fa1059df24d95e9f86`

Đặt hai repository cạnh nhau trong một thư mục và trỏ `ASAP7_ROOT` vào thư
mục cha đó:

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

## Những gì đã chuẩn hóa

- `memory/axi_ram.v` là AXI4 slave nối tới SRAM 1RW; truy cập được tuần tự hóa
  và ghi từng byte dùng read-modify-write vì macro không có byte-write mask.
- `memory/asap7_sram_128k_1rw.v` ánh xạ `addr[16:12]` thành 32 bank và tạo đúng
  32 hard-macro instance. Behavioral Verilog của macro chỉ dành cho mô phỏng,
  không nằm trong filelist tổng hợp.
- Filelist RTL có thứ tự cố định và include path tương thích filesystem Linux.
- Các kết nối hở/implicit net quan trọng ở cache, APB và lane 1 của core đã
  được xử lý trước khi tổng hợp.
- SDC có 9 clock đầu vào, 8 generated clock, reset false path, nhóm clock bất
  đồng bộ, IO delay/load và giới hạn transition 300 ps.
- Genus kiểm tra hard-macro Liberty trước tổng hợp và buộc mapped netlist phải
  có đúng 32 SRAM instance.
- Innovus kiểm tra đầy đủ Liberty/LEF/QRC/GDS, chuyển SDC từ ps/fF sang ns/pF,
  rồi tạo SRAM island 4 hàng x 8 cột với halo và placement blockage.

Không chuyển register file, I-cache, D-cache, FIFO, ROB hoặc boot ROM sang
macro này: các khối đó cần multi-port, byte mask hoặc initialization không phù
hợp với SRAM 1RW hiện có. RAM hard macro cũng không được preload từ `boot.mem`;
boot ROM hiện tại vẫn đảm nhiệm nội dung khởi động.

Có thể kiểm tra độc lập AXI-to-SRAM controller bằng model đồng bộ chính thức:

```bash
bash tests/run_rtl_lint.sh
bash tests/run_axi_ram_verilator.sh
```

Lệnh đầu lint cấu trúc toàn bộ 53 RTL file với top `top_soc`. Lệnh thứ hai bao
phủ full-word write/read, byte-strobe read-modify-write, chọn bank và phản hồi
`SLVERR` cho địa chỉ không word-aligned. Danh sách warning bị miễn trong lint
là warning debt của RTL gốc; báo cáo Genus/CDC/RDC vẫn phải được review độc lập.

## Chạy Genus

Chạy trong Linux có Cadence license và đã thiết lập `ASAP7_ROOT`:

```bash
cd Asap7/run_workspace/mcu/genus
tclsh preflight.tcl
genus -f genus.tcl
```

Preflight của Genus chỉ yêu cầu RTL, SDC và timing Liberty. Nếu physical view
còn thiếu, nó chỉ báo để chuẩn bị Innovus. Sau khi chạy, cần kiểm tra ít nhất:

- `reports/check_design_unresolved.rpt`
- `reports/timing_intent_post_syn.rpt`
- `reports/timing_syn.rpt`, `area_syn.rpt`, `power_syn.rpt`
- `reports/messages_all.rpt`
- `outputs/top_soc_syn.v` phải chứa đúng 32 SRAM macro

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
