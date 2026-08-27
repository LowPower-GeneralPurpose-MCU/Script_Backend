# Phân Tích Flow Innovus Cho Design `axi_ram`

## 0. Phạm vi và kết luận ngắn

Tài liệu này đối chiếu trực tiếp:

- Tcl master flow: `tcl/innovus.tcl`
- Tcl module: `tcl/sram_macro_setup.tcl`, `tcl/sram_macro_floorplan.tcl`, `tcl/finish_macroFP.tcl`, `tcl/power_plan.tcl`, `tcl/sram_island_power.tcl`, `tcl/pins.tcl`, `tcl/add_fill_and_verify.tcl`, `tcl/export_gds.tcl`
- Command transcript: `innovus.cmd`
- Log thực thi: `innovus.log`
- Checkpoint reports: `verify_rpt/` và `reports/`

Run được phân tích:

- Innovus `23.14-s088_1`
- Ngày chạy: `27 August 2026`
- Top design: `axi_ram`
- Process mode: `7nm`
- Voltage hiển thị trong log: `0.7 V`
- Analysis view: `tt`
- Standard-cell instances lúc init: `1240`
- SRAM hard macros lúc init: `16`
- SRAM master: `srambank_256x4x32_6t122`
- SRAM array: `4 x 4`

**Kết luận kỹ thuật:** flow đã hoàn thành sạch ở mức Innovus in-design: placement, CTS, routing, filler, timing, DRC, connectivity và SI đều có checkpoint sạch. Tuy nhiên, GDS xuất ra chưa đủ để gọi là signoff hoàn chỉnh vì file SRAM được merge là `srambank_32b.gds`, không chứa structure đúng tên `srambank_256x4x32_6t122`. Cần sửa nguồn GDS của macro rồi chạy lại stream-out và signoff DRC/LVS/density/antenna.

**Lưu ý khi trình bày:** run hiện tại là floorplan tự động/deterministic bằng Tcl, chưa phải floorplan thủ công bằng GUI. Trong code vẫn có `SRAM_AUTO_PACK_4X4=1`.

## 1. Cách đọc bằng chứng

Khi trình bày với thầy, mỗi bước nên nói theo thứ tự:

1. Tcl nào chịu trách nhiệm và lệnh chính là gì.
2. Lệnh đó xuất hiện ở đâu trong `innovus.log`.
3. Report nào chứng minh kết quả.
4. Kết luận là `PASS`, `DEFERRED`, `WARNING` hay `CRITICAL`.

Không nên chỉ trích một dòng `WARN` trong log để kết luận flow hỏng. Cần xem checkpoint report ngay sau bước đó. Ngược lại, cũng không nên chỉ nhìn dòng `Streamout is finished` để kết luận GDS đã signoff; stream-out có thể hoàn thành dù macro GDS bị thiếu structure.

## 2. Init design và MMMC

### Code và lệnh

Trong `tcl/innovus.tcl`:

```tcl
source ./tcl/innovus.globals
source ./tcl/prepare_innovus_sdc.tcl
source ./tcl/sync_genus_handoff.tcl
source ./tcl/flow_checks.tcl

sync_genus_handoff ...
prepare_innovus_sdc ...
init_design

setDesignMode -process 7
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
setMultiCpuUsage ...
```

Tham chiếu: `tcl/innovus.tcl:80-121`, `tcl/innovus.globals`, `tcl/viewDefinition.tcl`.

### Ý nghĩa

- `innovus.globals` nạp technology LEF, standard-cell LEF, SRAM LEF, netlist, top cell, VDD/VSS và MMMC.
- `sync_genus_handoff` đồng bộ netlist và SDC từ Genus sang thư mục Innovus.
- `prepare_innovus_sdc` chuyển numeric unit của SDC sang hệ `ns/pF` mà Innovus đang sử dụng.
- `init_design` tạo database physical design.
- `setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7` giới hạn signal routing trong M2-M7. M8/M9 được dùng cho upper/global PG.

### Log chứng minh

Trong `innovus.log`:

- LEF công nghệ và LEF SRAM được đọc: lines `58-65`.
- SRAM Liberty được đọc: lines `95-96`.
- Netlist `./outputs/axi_ram_syn.v` được đọc: lines `98-108`.
- Design có `1240 stdCell insts` và `16 macros`: lines `115-120`.
- Constraint summary có các lệnh `create_clock`, `set_input_delay`, `set_output_delay`, `set_max_transition` đều `Fail = 0`: lines `155-179`.

### Kết luận

**PASS - init và constraint loading thành công.**

Các cảnh báo `TECHLIB-1277` ở `innovus.log:72-73` và `84-85` chỉ ra một attribute Liberty `input_signal_level` nằm sai cấp trong file library nên bị bỏ qua. Đây là vấn đề chất lượng timing library, không làm `init_design` thất bại trong run này.

## 3. Hierarchy floorplan

### Code và lệnh

Trong `tcl/innovus.tcl:132-207`:

```tcl
set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
set SRAM_W [dbGet $first_sram_ptr.cell.size_x]
set SRAM_H [dbGet $first_sram_ptr.cell.size_y]

set CORE_W [snap_up ... $FLOORPLAN_GRID]
set CORE_H [snap_up ... $FLOORPLAN_GRID]

floorPlan \
    -s $CORE_W $CORE_H \
    $margin_dist $margin_dist $margin_dist $margin_dist

checkFPlan \
    -reportUtil \
    -outFile ./verify_rpt/reportUtil_hierFP_proto.rpt

source ./tcl/finish_hierFP.tcl
```

### Ý nghĩa

Script không đo kích thước macro bằng tay. Nó lấy kích thước từ database sau khi LEF được load, sau đó tính core size đủ chứa SRAM island và logic region. `snap_up` đưa kích thước lên `FLOORPLAN_GRID=0.384`.

Trong log:

```text
floorPlan -s 620.928 766.464 2.16 2.16 2.16 2.16
```

Innovus snap chiều cao core từ `766.464` lên `766.512`.

### Report chứng minh

`verify_rpt/reportUtil_hierFP_final.rpt`:

```text
Core Utilization = 70.971611
Average macro density = 0.706
Average macro with halo density = 0.706
Average module density = 0.711
Density for the design = 0.711
Pin Density = 0.003074
```

Log tương ứng: `innovus.log:1168-1246`.

### Kết luận

**PASS - hierarchy floorplan hợp lệ.**

`checkFPlan` cho thấy:

- Core/die nằm trên grid.
- Row nằm trên grid.
- Không có regular pre-route off-track: `0`.
- Không có message error trong checkpoint này.

`IMPFP-325` ở `innovus.log:1171` chỉ là thông báo floorplan được resize do snap grid. Đây là hành vi dự kiến khi kích thước ban đầu chưa nằm đúng placement grid.

## 4. SRAM macro floorplan 4 x 4

### 4.1. Khai báo physical intent

Trong `tcl/sram_macro_setup.tcl:11-23`:

```tcl
set DESIGN      "axi_ram"
set SRAM_MASTER "srambank_256x4x32_6t122"
set SRAM_ROWS 4
set SRAM_COLS 4
set SRAM_COUNT [expr {$SRAM_ROWS * $SRAM_COLS}]
```

Trong `tcl/sram_macro_setup.tcl:49-67`:

```tcl
set FLOORPLAN_GRID       0.384
set ASAP7_ROW_HEIGHT     1.080
set SRAM_MACRO_GAP_ROWS  4
set SRAM_BLOCKAGE_BORDER_ROWS 2
```

Do đó:

- Gap giữa hai macro: `4 x 1.080 = 4.320 um`.
- Border/halo quanh island: `2 x 1.080 = 2.160 um`.
- Macro width: `121.392 um`.
- Macro height: `172.800 um`.
- X pitch: `121.392 + 4.320 = 125.712 um`.
- Y pitch: `172.800 + 4.320 = 177.120 um`.

### 4.2. Orientation theo yêu cầu của thầy

Trong `tcl/sram_macro_setup.tcl:181-200`:

```tcl
set SRAM_ISLAND_ORIENT "R0"
set SRAM_MIRROR_ORIENT "MY"

proc sram_orientation_for_column {column} {
    if {[expr {$column % 2}] == 0} {
        return $SRAM_ISLAND_ORIENT
    }
    return $SRAM_MIRROR_ORIENT
}
```

Pattern theo cột là:

```text
Column 0: R0
Column 1: MY
Column 2: R0
Column 3: MY
```

`MY` là mirror theo trục Y, làm biến đổi theo hướng X. Khi đặt xen kẽ `R0/MY` trong cùng một hàng, các macro kề nhau có interface đối xứng trong khe ngang. Đây là cách triển khai đúng với yêu cầu “dùng R0 và flip theo trục Y để hai SRAM đối xứng và dễ nối”.

Điểm cần nói rõ: không phải tất cả SRAM đều cùng orientation `R0`. Quy tắc đúng ở đây là `R0/MY` xen kẽ theo column.

### 4.3. Lệnh placement

Trong `tcl/sram_macro_floorplan.tcl:124-198`, script:

- Tìm đúng 16 instance theo `SRAM_MASTER`.
- Parse bank index từ tên instance.
- Sort theo bank index.
- Tính kích thước array.
- Kiểm tra core đủ lớn.

Sau đó tại phần seed placement:

```tcl
placeInstance <instance> <x> <y> <orient>
createInstGroup SRAM_ISLAND_GROUP
addInstToInstGroup SRAM_ISLAND_GROUP <instance>
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
snapFPlan -block
```

Cuối cùng:

```tcl
cutRow -area {2.16 2.16 502.848 708.48}
createPlaceBlockage \
    -name SRAM_ISLAND_GROUP_BLOCKAGE \
    -type hard \
    -noCutByCore \
    -box {2.16 2.16 502.848 708.48}
```

Tham chiếu: `tcl/sram_macro_floorplan.tcl:200-419`.

### 4.4. Log và report chứng minh

Trong `innovus.log:1305-1320`, 16 lệnh `placeInstance` được ghi trực tiếp. Ví dụ:

```text
u_mem/G_SRAM_BANK[0].u_sram  2.160000   2.160000 R0
u_mem/G_SRAM_BANK[1].u_sram  127.872000 2.160000 MY
u_mem/G_SRAM_BANK[2].u_sram  253.584000 2.160000 R0
u_mem/G_SRAM_BANK[3].u_sram  379.296000 2.160000 MY
```

Các row tiếp theo có Y origin:

```text
2.160
179.280
356.400
533.520
```

`reports/sram_macro_final_map.rpt` xác nhận:

- 16 instance đều là `srambank_256x4x32_6t122`.
- Tất cả đều `status fixed`.
- Orientation chỉ có `R0` và `MY`.
- Macro bbox: `2.16 2.16 500.688 706.32`.

`reports/sram_macro_gap_check.rpt`:

```text
configured_gap_x 4.32
configured_gap_y 4.32
minimum_horizontal_gap 4.32
minimum_vertical_gap 4.32
horizontal_adjacencies 24
vertical_adjacencies 24
```

`reports/sram_island_blockage_geometry.rpt`:

```text
die_box 0.0 0.0 625.248 770.832
core_box 2.16 2.16 623.088 768.672
macro_bbox 2.16 2.16 500.688 706.32
inter_macro_gap_rows 4
inter_macro_gap_um 4.32
halo_rows 2
halo_um 2.16
place_blockage_type hard
blockage_clearance_left 2.16
blockage_clearance_bottom 2.16
blockage_clearance_right 2.16
blockage_clearance_top 2.16
```

### 4.5. Giải thích `Average macro density = 0`

`reportUtil_after_macroFP.rpt` và `reportUtil_before_pnr.rpt` có:

```text
Average macro density = 0.000
Average module density = 0.018
```

Không được hiểu là SRAM biến mất. Sau khi `cutRow` và tạo hard placement blockage, vùng SRAM bị loại khỏi effective allocation area mà report utilization dùng để tính density. Bằng chứng SRAM tồn tại phải lấy từ:

- `reports/sram_macro_final_map.rpt`
- `innovus.log:1305-1359`
- `reports/sram_island_blockage_geometry.rpt`
- `checkPlace` có fixed instances

Đây là khác biệt giữa physical database và cách Innovus tính effective utilization.

### Kết luận

**PASS - SRAM floorplan đúng về số lượng, vị trí, orientation, gap, halo, blockage và FIXED status.**

Đây là phần mạnh nhất để trình bày với thầy vì có cả lệnh, tọa độ và report kiểm tra hình học.

## 5. Route guard quanh SRAM

### Code và trạng thái thực tế

`source ./tcl/sram_route_guard.tcl` được gọi trước placement và một lần nữa trước routing: `tcl/innovus.tcl:258` và `tcl/innovus.tcl:646`.

Trong `tcl/sram_route_guard.tcl:29-37`:

```tcl
set SRAM_ROUTE_GUARD_EGR_LAYER M5
set SRAM_ROUTE_GUARD_LAYERS {M6 M7}
set SRAM_ROUTE_GUARD_ENABLE 0
```

Khi `SRAM_ROUTE_GUARD_ENABLE=0`, script không tạo `createRouteBlk`. Nó tin vào OBS trong SRAM LEF:

- LEF đã block M1/M2/M4/V4/M5.
- M6/M7 vẫn cho phép signal escape trên macro body.

`reports/sram_route_guard.rpt` là bằng chứng trạng thái guard đang disabled.

### Ý nghĩa thiết kế

Có hai loại keepout khác nhau:

- `createPlaceBlockage` trong macro floorplan: ngăn standard cell đi vào SRAM island.
- `createRouteBlk` trong route guard: ngăn signal routing trên các layer chỉ định.

Run hiện tại dùng hard placement blockage nhưng không dùng signal route blockage M6/M7. Vì vậy không nên nói “mọi signal đều bị cấm đi trên SRAM”. Cách nói chính xác là “SRAM LEF OBS bảo vệ các layer nội bộ, còn M6/M7 được để mở cho escape”.

### Kết luận

**PASS theo cấu hình hiện tại, nhưng đây là một lựa chọn architecture cần nêu rõ.**

Nếu GUI cho thấy signal/clock chạy trên M6/M7 qua macro và đó không phải intent mong muốn, có thể chạy debug với `SRAM_ROUTE_GUARD_ENABLE=1`, sau đó phải kiểm lại congestion, timing và DRC.

## 6. Power plan cho core và SRAM island

### 6.1. Global VDD/VSS ring

Trong `tcl/power_plan.tcl:472-483`:

```tcl
setAddStripeMode -reset
setAddStripeMode -allow_jog none

globalNetConnect VDD -type pgpin -pin VDD -inst * -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -override
globalNetConnect VDD -type tiehi -inst * -override
globalNetConnect VSS -type tielo -inst * -override
applyGlobalNets
```

Trong `tcl/power_plan.tcl:540-558`:

```tcl
addRing -nets {VDD} \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width 0.480 \
    -spacing 0.480 \
    -offset 0.192 \
    -snap_wire_center_to_grid Grid

addRing -nets {VSS} \
    -layer {top M8 bottom M8 left M9 right M9} \
    -width 0.480 \
    -spacing 0.480 \
    -offset 1.152 \
    -snap_wire_center_to_grid Grid
```

VDD và VSS được tạo bằng hai lệnh độc lập để ownership và offset của hai ring không bị mơ hồ.

Log `innovus.log:1499-1559` chứng minh:

- Mỗi `addRing` tạo 4 wires.
- Mỗi ring tạo 4 vias.
- VDD và VSS có hai offset riêng.

### 6.2. SRAM local PG

Trong `tcl/sram_island_power.tcl:150-225`:

- M4 horizontal ở bottom/top halo.
- M4 horizontal trong ba row gaps.
- M5 vertical ở left/right edge.
- M5 vertical trong ba column gaps nếu `SRAM_ENABLE_COLUMN_GAP_PG=1`.

Trạng thái thực tế của script hiện tại được đặt mặc định tại `tcl/sram_island_power.tcl:64-68`:

```tcl
set SRAM_ENABLE_COLUMN_GAP_PG 1
set SRAM_CONNECT_BLOCK_PINS 1
```

Do đó report hiện tại có:

- `gap col_0`, `gap col_1`, `gap col_2` trên M5.
- 16 deterministic M5 edge taps.
- 32 expected connected ports.

Mỗi tap được tạo bằng cặp M5 ngắn tại cạnh macro, không dùng broad `sroute -connect blockPin`. Phần này nằm ở `tcl/sram_island_power.tcl:243-288`.

Các report:

`reports/sram_island_pg_edges.rpt`:

```text
gap row_0 M4 horizontal ...
gap row_1 M4 horizontal ...
gap row_2 M4 horizontal ...
gap col_0 M5 vertical ...
gap col_1 M5 vertical ...
gap col_2 M5 vertical ...
tap macro_0 M5 vertical ...
...
tap macro_15 M5 vertical ...
```

`reports/sram_blockpin_stitch_intent.rpt`:

```text
strategy deterministic_m5_edge_taps
source_layer M4
tap_layer M5
tap_depth 8.64
tap_count 16
expected_connected_ports 32
nearest_target_sroute disabled
```

### 6.3. Trim và PG verification

Sau khi tạo ring/stripe:

```tcl
editTrim -nets {VDD VSS}
verifyConnectivity -type special -net {VDD VSS} ...
verify_drc -check_only special -layer_range {M4 M9} ...
```

Tham chiếu: `tcl/power_plan.tcl:589-620`.

Checkpoint pre-placement:

```text
verify_rpt/pg_connectivity_before_stdcell_place.rpt
4 Problem(s): Special Wires: Pieces of the net are not connected together.
```

Log tương ứng: `innovus.log:2761-2785`.

Đây là **staged/deferred result**, không phải final PG failure. Ở thời điểm này:

- Core standard-cell PG chưa được build.
- Một số ring/island special-wire open được flow cho phép tạm thời.
- Code `flow_checks.tcl:468-480` nhận diện đây là pre-placement checkpoint và defer strict handoff.

PG DRC ở checkpoint này vẫn là:

```text
No DRC violations were found
```

Sau khi standard-cell PG được xây ở `tcl/innovus.tcl:392-435`, các report:

- `verify_rpt/pg_connectivity_after_trim.rpt`
- `verify_rpt/sram_m4_interface_drc.rpt`
- `verify_rpt/pg_drc_after_trim.rpt`
- `verify_rpt/pg_drc_after_trim_full.rpt`

đều sạch:

```text
Found no problems or warnings.
No DRC violations were found
```

### Kết luận

**PASS - local SRAM PG và core PG sạch sau khi hoàn tất handoff với standard-cell placement.**

Khi trình bày, phải nói đủ hai ý:

1. Pre-placement có 4 open được defer theo thiết kế flow.
2. Sau post-placement PG reconnect, strict connectivity/DRC sạch.

## 7. Top-level pin assignment

### Code và lệnh

Trong `tcl/innovus.tcl:322-325`:

```tcl
setPinConstraint \
    -cell $DESIGN \
    -corner_to_pin_distance 8
source ./tcl/pins.tcl
```

Trong `tcl/pins.tcl:143-204`:

```tcl
setPinAssignMode -pinEditInBatch true

editPin -pin $TOP_PINS   -side TOP    -layer M7 ...
editPin -pin $RIGHT_PINS -side RIGHT  -layer M6 ...
editPin -pin $BOTTOM_PINS -side BOTTOM -layer M7 ...
editPin -pin $LEFT_PINS  -side LEFT  -layer M6 ...

setPinAssignMode -pinEditInBatch false
checkPinAssignment \
    -outFile ./verify_rpt/checkPinAssignment_after_pin.rpt
```

Layer mapping:

- TOP/BOTTOM dùng M7 vì hướng pin ngang.
- LEFT/RIGHT dùng M6 vì hướng pin dọc.

### Report chứng minh

`reports/top_level_pin_geometry.rpt`:

```text
TOP    M7  count=68
RIGHT  M6  count=51
BOTTOM M7  count=39
LEFT   M6  count=70
```

Tổng cộng `68 + 51 + 39 + 70 = 228` signal pins.

`verify_rpt/checkPinAssignment_after_pin.rpt`:

```text
Total Pins                 : 228
Legally Assigned Pins      : 228
illegal                    : 0
unplaced                   : 0
```

### Kết luận

**PASS - 228/228 top-level pins được assign hợp lệ.**

Nếu log stream-out báo `Ports/Pins = 230`, không nên nhầm với 228 signal pins. Stream-out còn đếm thêm physical PG terminals trên M9.

## 8. Standard-cell placement và pre-CTS optimization

### Code và lệnh

Trong `tcl/innovus.tcl:343-369`:

```tcl
setDelayCalMode -SIAware false ...
setPlaceMode -reset
setPlaceMode \
    -place_global_cong_effort high \
    -place_global_auto_blockage_in_channel soft \
    -place_detail_preroute_as_obs {2 3} \
    -place_design_refine_macro false

place_opt_design
refinePlace
checkPlace ./verify_rpt/checkPlace_after_place.rpt
timeDesign -preCTS -outDir ./reports/timing_preCTS
```

Sau đó flow xây core PG và chạy:

```tcl
optDesign -prefix preCTS -preCTS
refinePlace
checkPlace ./verify_rpt/checkPlace_before_cts.rpt
```

### Vì sao đặt `-place_design_refine_macro false`

SRAM đã được đặt deterministic và fixed. Nếu để placement refine macro, tool có thể thay đổi vị trí hard macro, phá:

- 4-row gap.
- R0/MY orientation pattern.
- local SRAM PG topology.
- route blockage geometry.

### Report chứng minh

`checkPlace_after_place.rpt`:

```text
No violations found
Placed Instances = 1415
fixed = 16
Unplaced Instances = 0
```

`checkPlace_before_cts.rpt`:

```text
No violations found
Placed Instances = 1509
fixed = 16
Unplaced Instances = 0
```

`reportUtil_after_place.rpt`:

```text
Core Utilization = 75.348043
No. of regular pre-routes not on tracks : 0
```

### Kết luận

**PASS - placement hợp lệ, không còn unplaced instance và 16 SRAM vẫn fixed.**

Các timing âm trong những bảng nội bộ đầu của `place_opt_design` là intermediate optimization snapshots. Kết quả cần dùng để kết luận là checkpoint sau optimization, không phải snapshot xấu nhất trong quá trình optimizer.

## 9. CTS

### Code và lệnh

Trong `tcl/innovus.tcl:443-513`, flow tạo:

```tcl
create_route_type -name leaf_rule ...
create_route_type -name trunk_rule ...
create_route_type -name top_rule ...

set_ccopt_property -net_type leaf  route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top   route_type top_rule

set_ccopt_property target_skew 40ps
set_ccopt_property -net_type leaf  target_max_trans 35ps
set_ccopt_property -net_type trunk target_max_trans 40ps
set_ccopt_property -net_type top   target_max_trans 40ps

clock_opt_design
```

Sau CTS:

```tcl
refinePlace
checkPlace ./verify_rpt/checkPlace_after_cts.rpt
set_propagated_clock [all_clocks]
optDesign -prefix postCTS -postCTS -setup -hold
checkPlace ./verify_rpt/checkPlace_after_postcts.rpt
```

### Log chứng minh

`innovus.log:7064` có lệnh `clock_opt_design`.

Log báo:

```text
skew_group CLK/mode_normal with 175 sinks and 1 source
Slew time target (leaf): 0.035ns
Slew time target (trunk): 0.040ns
Slew time target (top): 0.040ns
Skew target: 0.040ns
```

Sau CTS, `innovus.log:12143-12149`:

```text
WARNING IMPCCOPT-1007 10
Message Summary: 10 warning(s), 0 error(s)
```

### Giải thích `IMPCCOPT-1007`

Các warning cụ thể tại `innovus.log:10487-10516` tập trung vào các pin clock của SRAM. Ví dụ:

```text
SRAM_BANK[0].u_sram/clk
target 0.035ns
achieved 0.115ns
```

Code tại `tcl/innovus.tcl:468-478` đã ghi rõ nguyên nhân dự kiến: 16 nhánh clock đi đến SRAM dài vài trăm micron vì hard placement blockage đẩy clock buffers ra ngoài island, trong khi leaf route mặc định ở M2/M3.

Đây là warning cần báo cáo trung thực:

- CTS vẫn hoàn tất.
- Setup/hold sau CTS không có violating paths.
- Nhưng SRAM clock slew có warning intermediate.
- Post-route `.tran.gz` vẫn có 4 max-transition entries trên SRAM clock, được đánh dấu `0 violation is real`, `4 violations may not be fixable`, remark `C`.

Không nên nói “không còn bất kỳ max-transition report nào”. Cách nói chính xác là “không còn real DRV violation theo gate của flow; còn 4 clock max-transition diagnostic entries do macro abstract/clock endpoint”.

### Report placement và timing

`checkPlace_after_cts.rpt`:

```text
No violations found
Placed Instances = 1590
fixed = 58
Unplaced Instances = 0
```

`checkPlace_after_postcts.rpt`:

```text
No violations found
Placed Instances = 1747
fixed = 52
Unplaced Instances = 0
```

Post-CTS setup/hold trong log:

```text
setup WNS = 0.000 ns, TNS = 0.000 ns, violating paths = 0
hold  WNS = 0.001 ns, TNS = 0.000 ns, violating paths = 0
```

### Kết luận

**PASS về placement/clock tree/timing paths; WARNING cần theo dõi về SRAM clock slew.**

Nếu cần cải thiện warning này, knob đúng là `SRAM_CTS_LEAF_TOP_LAYER` trong `tcl/sram_macro_setup.tcl:203-217`, không phải set layer cho clock net sau `clock_opt_design`, vì clock nets đã được CCOpt finalize/fix.

## 10. Signal routing và post-route optimization

### Code và lệnh

Trong `tcl/innovus.tcl:627-660`:

```tcl
setSIMode \
    -enable_delay_report true \
    -enable_glitch_report true
setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -SIAware true ...
setExtractRCMode -engine postRoute -effortLevel medium

setNanoRouteMode ...

routeDesign -globalDetail
routeDesign -viaOpt -wireOpt -trackOpt
ecoRoute -fix_drc
```

Sau đó:

```tcl
setOptMode \
    -fixCap true \
    -fixTran true \
    -fixFanoutLoad true \
    -fixGlitch true \
    -reclaimArea false

optDesign -postRoute -setup -hold -prefix postRoute
ecoRoute -fix_drc
```

### Ý nghĩa

- `routeDesign -globalDetail` là global/detail route một pass.
- `routeDesign -viaOpt -wireOpt -trackOpt` tối ưu via, wire và track sau pass đầu.
- `ecoRoute -fix_drc` sửa DRC còn lại.
- `setAnalysisMode -cppr both` loại bớt clock common-path pessimism.
- `-reclaimArea false` sau SI repair giữ lại buffer/routing đã sửa, không để area reclaim phá kết quả.

`NRIG-96` nói `-globalDetail` là single-pass route. Đây là warning/information, không phải flow fail, vì ngay sau đó flow vẫn chạy via/wire/track optimization và ECO route.

### PG intermediate sau CTS/post-route

Các report:

- `pg_connectivity_after_cts_preopt.rpt`: 219 info/violations.
- `pg_connectivity_after_postcts.rpt`: 227.
- `pg_connectivity_after_postroute_opt.rpt`: 228.

Những report này có unconnected terminal, special-wire opens và dangling wires do các ECO/CTS cell đã được thêm nhưng M1 standard-cell rail chưa được filler bridge. Code gọi các checkpoint này với cơ chế deferred và không dùng chúng làm final signoff.

Đây là lý do filler được đặt sau mọi post-route optimization, thay vì đặt filler sớm.

### Route recheck

Trong `tcl/verify_route.tcl`:

```tcl
ecoRoute -fix_drc
verify_pg_connectivity_or_stop ...
verify_drc -report ./verify_rpt/drc_postroute.rpt
verifyConnectivity -type all ...
timeDesign -postRoute ...
timeDesign -postRoute -hold ...
```

Log recheck:

- `innovus.log:20495-20556`: DRC `0`, connectivity `0`.
- `innovus.log:20785-20804`: setup WNS `+0.021 ns`, TNS `0`, violating paths `0`, SI glitch `0`.
- `innovus.log:20889-20891`: hold WNS `+0.045 ns`, TNS `0`, violating paths `0`.

Các report:

- `verify_rpt/drc_postroute.rpt`: `No DRC violations were found`.
- `verify_rpt/connectivity_postroute.rpt`: `Found no problems or warnings`.
- `reports/timing_postRoute/axi_ram_postRoute.summary.gz`: setup clean.
- `reports/timing_postRoute_hold/axi_ram_postRoute_hold.summary.gz`: hold clean.
- `reports/si_glitch_postRoute.rpt`: `Total number of glitch violations: 0`.

### Kết luận

**PASS - routed checkpoint sạch và đủ điều kiện để đi filler.**

## 11. Filler insertion

### Code và lệnh

Trong `tcl/innovus.tcl:697-725`:

```tcl
set FILLERCells [list \
    FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R \
    FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L]

setFillerMode -reset
setFillerMode \
    -core $FILLERCells \
    -add_fillers_with_drc false \
    -fitGap true \
    -honorPrerouteAsObs true \
    -diffCellViol true

addFiller \
    -cell $FILLERCells \
    -prefix FILLER \
    -honorPrerouteAsObs true \
    -diffCellViol true

checkFiller -file ./verify_rpt/checkFiller_after_filler.rpt
checkPlace ./verify_rpt/checkPlace_after_filler.rpt
verify_core_pg_after_filler_nojog ...
verify_drc -report ./verify_rpt/pg_drc_after_filler.rpt
```

### Log và report

`innovus.log:19604-19627`:

```text
Added 254401 filler insts: FILLER_ASAP7_75t_L
Added 959 filler insts: FILLERxp5_ASAP7_75t_L
Total 255360 filler insts added
Total number of padded cell violations: 0
Total number of gaps found: 0
Placed = 257107
Unplaced = 0
Placement Density = 100.00%
```

`verify_rpt/checkFiller_after_filler.rpt` không báo gap. `verify_rpt/pg_connectivity_after_filler.rpt`:

```text
Found no problems or warnings.
```

`verify_rpt/pg_drc_after_filler.rpt`:

```text
No DRC violations were found
```

### Kết luận

**PASS - filler đã lấp row hợp lệ và bridge được các temporary M1 rail gaps.**

Warning `IMPSP-5217` ở `innovus.log:19607` chỉ nhắc rằng `addFiller` đang chạy trên post-route database và khuyến nghị `ecoRoute -target`; flow vẫn chạy ECO/check DRC sau đó, nên final reports sạch.

## 12. Final timing, DRC, connectivity và SI

### Timing

`reports/timing_postFill/axi_ram_postRoute.summary.gz`:

```text
Setup WNS = 0.021 ns
Setup TNS = 0.000 ns
Violating Paths = 0
```

`reports/timing_postFill_hold/axi_ram_postRoute_hold.summary.gz`:

```text
Hold WNS = 0.045 ns
Hold TNS = 0.000 ns
Violating Paths = 0
```

`reports/si_glitch_postFill.rpt`:

```text
Total number of glitch violations: 0
```

`verify_rpt/timing_final.rpt` còn cho thấy một path thực tế đi vào SRAM:

```text
Endpoint: u_mem/G_SRAM_BANK[12].u_sram/wd[3]
Slack Time: 0.021
```

Điều này chứng minh timing report không chỉ kiểm standard-cell mà có path kết thúc tại SRAM macro pin.

### Physical checks

Các report cuối:

- `verify_rpt/drc_after_fill.rpt`: `No DRC violations were found`.
- `verify_rpt/connectivity_after_fill.rpt`: `Found no problems or warnings`.
- `verify_rpt/drc_final.rpt`: `No DRC violations were found`.
- `verify_rpt/connectivity_final.rpt`: `Found no problems or warnings`.

Log:

- `innovus.log:21080-21133`: post-fill DRC/connectivity sạch.
- `innovus.log:21568-21621`: final DRC/connectivity sạch.

### Kết luận

**PASS - Innovus in-design closure sạch về timing, DRC, connectivity và SI.**

## 13. DEF, netlist và GDS export

### Code và lệnh

Trong `tcl/export_gds.tcl:49-87`:

```tcl
verify_drc -report ./verify_rpt/drc_final.rpt
verifyConnectivity -type all ...

saveNetlist ./outputs/axi_ram_pnr_lec.v ...
saveNetlist ./outputs/axi_ram_pnr_sta.v
write_sdc ./outputs/axi_ram_pnr.sdc

defOut -floorplan -netlist -routing ./outputs/axi_ram_pnr.def

streamOut ./outputs/axi_ram_pnr.gds \
    -units $STREAMOUT_UNITS \
    -mapFile $GDS_MAP_FILE \
    -dieAreaAsBoundary \
    -merge $merge_gds_files
```

Log chứng minh:

- `innovus.log:21624-21631`: LEC netlist, STA netlist và DEF được ghi.
- `innovus.log:21632`: stream-out GDS bắt đầu.
- `innovus.log:21771`: stream-out kết thúc.

### Vấn đề quan trọng của SRAM GDS

Lệnh hiện tại merge:

```text
/home/user1/Desktop/asap7/asap7_sram_0p0/gds/srambank_32b.gds
```

Nhưng log báo:

```text
IMPOGDS-217:
Master cell: srambank_256x4x32_6t122 not found in merged file(s)

IMPOGDS-218:
Number of master cells not found after merging: 1
```

Tham chiếu: `innovus.log:21632-21771`, đặc biệt lines `21768-21769`.

`verify_rpt/signoff_handoff.rpt` ghi rõ:

```text
Macro GDS: INCOMPLETE
The exported GDS has empty outlines at those macro locations.
Density, DRC, LVS and antenna results on this GDS are not meaningful.
```

Nguyên nhân là file `srambank_32b.gds` là primitive SRAM library, có các structure như bitcell/column/sense amp/filler, nhưng không có structure assembled macro tên chính xác:

```text
srambank_256x4x32_6t122
```

`streamOut -merge` match theo exact structure name. Innovus vẫn cho stream-out hoàn thành, nhưng macro outline không được thay bằng layout GDS thật.

### Kết luận

**CRITICAL - export đã hoàn thành về mặt lệnh, nhưng GDS chưa đủ cho signoff.**

Không được trình bày câu “GDS đã signoff”. Câu chính xác là:

> Innovus đã tạo signoff candidate và tất cả in-design checks đều clean; tuy nhiên macro GDS của SRAM chưa complete nên cần thay đúng GDS assembled macro rồi chạy lại merged-GDS signoff.

## 14. Phân loại warning trong run

| Message | Mức độ | Ý nghĩa | Cách trình bày |
|---|---:|---|---|
| `IMPOGDS-217/218` | CRITICAL | SRAM master không có trong merged GDS; macro GDS bị rỗng | Phải sửa trước GDS DRC/LVS/signoff |
| `IMPCCOPT-1007` | WARNING | 10 intermediate SRAM clock slew violations trong CTS | CTS vẫn xong, final timing paths pass; còn diagnostic max-tran cần theo dõi |
| `IMPPP-133` | WARNING | OBS/pin abstraction của SRAM LEF hơi vượt declared SIZE nên Innovus mở rộng DB boundary | Không phải overlap theo report hiện tại, nhưng nên kiểm tra/cập nhật LEF generated |
| `TECHLIB-1277` | WARNING | Liberty attribute nằm sai cấp và bị ignore | Sửa library nếu cần model sạch hơn |
| `IMPMF-5050/5045/5054` | WARNING | Lệnh metal fill legacy obsolete | Educational PDK chưa có Pegasus deck; signoff nên chuyển sang Pegasus fill |
| `IMPSP-5217` | WARNING | Add filler trên post-route DB nên theo bằng ECO route | Flow đã chạy ECO/check và final sạch |
| `IMPVFG-1198` | INFO/WARNING | Verify DRC yêu cầu 12 CPU nhưng vùng kiểm tra chỉ tạo 1 subarea nên dùng 1 CPU | Chỉ ảnh hưởng runtime |
| `NRIG-96` | INFO/WARNING | `routeDesign -globalDetail` là single pass | Có các route optimization/ECO sau đó |
| `NRIF-78` | INFO/WARNING | ECO route kết hợp timing-driven có thể tốn memory/runtime | Không có fail trong run |
| `NRDB-778/2040` | WARNING | Một số via rule/LEF rule không đầy đủ hoặc không có multicut phù hợp | Cần review PDK nếu làm signoff nghiêm ngặt |
| `NRDB-942` | INFO/WARNING | Shielding ECO bị reset vì không có shielding wire hiện hữu | Không phải DRC fail |
| `IMPOPT-3195` | INFO/WARNING | Analysis mode thay đổi trong các phase optimization | Là thay đổi tool mode theo flow |
| `IMPPSP-1501` | INFO/WARNING | Degenerated 2-pin net bị ignore | Không ảnh hưởng physical closure hiện tại |
| `invalid command name "exitttt"` | SCRIPT/SESSION ERROR | Lệnh gõ sai sau khi đã save/export xong | Rerun sạch để log trình bày không có dòng này |

`innovus.log:22038` báo `3264 warning(s)` ở cuối session. Con số này là message summary tích lũy của cả session, bao gồm warning lặp từ nhiều phase; không được hiểu là có 3264 physical violations. Kết luận phải dựa vào từng checkpoint report và các message ID quan trọng ở bảng trên.

## 15. Bảng checkpoint để đưa vào slide

| Stage | Lệnh chính | Report chứng minh | Kết quả |
|---|---|---|---|
| Init | `init_design` | Log lines `58-179` | PASS, 16 macro, 1240 std cells, constraints fail 0 |
| Hierarchy FP | `floorPlan`, `checkFPlan` | `reportUtil_hierFP_final.rpt` | PASS, core util 70.97%, off-track 0 |
| SRAM FP | `placeInstance`, `snapFPlan`, `createPlaceBlockage` | `sram_macro_final_map.rpt`, `sram_macro_gap_check.rpt` | PASS, 16 fixed, R0/MY, gap 4.32 um |
| SRAM keepout | `cutRow`, hard blockage | `sram_island_blockage_geometry.rpt` | PASS, border 2.16 um, hard blockage |
| SRAM PG | `addStripe`, `editTrim` | `sram_island_pg_edges.rpt`, `sram_blockpin_stitch_intent.rpt` | PASS, M4/M5 local PG, 16 taps/32 ports |
| Top pins | `editPin`, `checkPinAssignment` | `checkPinAssignment_after_pin.rpt` | PASS, 228 legal, 0 unplaced |
| Placement | `place_opt_design`, `checkPlace` | `checkPlace_after_place.rpt` | PASS, 0 unplaced |
| Pre-CTS | `optDesign -preCTS` | `checkPlace_before_cts.rpt`, `timing_preCTS` | PASS |
| CTS | `clock_opt_design` | `checkPlace_after_cts.rpt`, CTS log | PASS with `IMPCCOPT-1007` diagnostic |
| Post-CTS | `optDesign -postCTS` | `checkPlace_after_postcts.rpt`, postCTS timing | PASS |
| Route | `routeDesign`, `ecoRoute`, `optDesign -postRoute` | `drc_postroute.rpt`, `connectivity_postroute.rpt` | PASS |
| Route recheck | `source tcl/verify_route.tcl` | recheck reports | PASS, setup +0.021 ns, hold +0.045 ns |
| Filler | `addFiller`, `checkFiller` | `checkFiller_after_filler.rpt`, `checkPlace_after_filler.rpt` | PASS, 255360 filler, gaps 0 |
| Final Innovus | `verify_drc`, `verifyConnectivity`, `timeDesign` | `drc_final.rpt`, `connectivity_final.rpt`, postFill timing | PASS |
| GDS export | `defOut`, `streamOut` | `signoff_handoff.rpt` | CRITICAL, SRAM master GDS missing |

## 16. Kịch bản trình bày ngắn với thầy

> Em sử dụng design `axi_ram` với 16 SRAM hard macro `srambank_256x4x32_6t122`, sắp thành array 4 x 4 ở góc lower-left. Trước tiên em load technology LEF, standard-cell LEF, SRAM LEF/Liberty, netlist và MMMC bằng `init_design`.
>
> Sau đó em tính kích thước core từ kích thước macro trong database, tạo hierarchy floorplan và snap theo grid. SRAM được đặt deterministic bằng `placeInstance`, với gap ngang/dọc 4 row tương đương 4.32 um và border 2 row tương đương 2.16 um.
>
> Về orientation, em dùng pattern R0/MY/R0/MY theo column. `MY` mirror macro theo trục Y, làm các SRAM kề nhau đối xứng theo hướng X để thuận tiện nối interface và local power. Sau khi đặt xong, tất cả 16 macro được kiểm tra và set fixed.
>
> Tiếp theo em tạo hard placement blockage quanh SRAM island, tạo global VDD/VSS ring trên M8/M9 và local SRAM PG trên M4/M5. Các row gap dùng M4 horizontal collector, column gap và edge dùng M5 vertical collector, kèm 16 deterministic edge taps. PG connectivity và special DRC được kiểm tra lại sau khi core PG handoff hoàn tất.
>
> Top-level pins được spread trên bốn cạnh: TOP/BOTTOM trên M7, LEFT/RIGHT trên M6. `checkPinAssignment` cho kết quả 228 legal pins, 0 illegal và 0 unplaced.
>
> Sau đó em chạy standard-cell placement, pre-CTS optimization, `clock_opt_design`, post-CTS optimization, signal routing và post-route optimization. Flow có warning SRAM clock slew trong CTS, nhưng final setup WNS là +0.021 ns, hold WNS là +0.045 ns, TNS bằng 0 và violating paths bằng 0.
>
> Cuối cùng em add 255360 filler cells. `checkFiller` có 0 gap, `checkPlace` có 0 unplaced, PG connectivity sạch, DRC sạch và SI glitch bằng 0.
>
> Kết luận của em là Innovus in-design closure đã sạch. Tuy nhiên em chưa gọi GDS là signoff cuối cùng vì log `IMPOGDS-217/218` cho biết file merge hiện tại không chứa structure `srambank_256x4x32_6t122`. Em cần thay đúng assembled SRAM macro GDS, stream-out lại, rồi chạy Pegasus/Calibre DRC, LVS, density và antenna.

## 17. Việc cần làm trước khi gọi là signoff

1. Tìm file GDS assembled có structure chính xác `srambank_256x4x32_6t122`.
2. Kiểm tra structure bằng tool/script GDS:

```bash
python3 ./scripts/gds_structure_tool.py list /absolute/path/to/candidate.gds
```

3. Trỏ biến môi trường trước khi chạy flow/export:

```bash
export ASAP7_SRAM_GDS=/absolute/path/to/srambank_256x4x32_6t122.gds
```

4. Xác nhận `signoff_handoff.rpt` chuyển từ `Macro GDS: INCOMPLETE` sang `Macro GDS: COMPLETE`.
5. Chạy lại merged GDS stream-out.
6. Chạy Pegasus/Calibre trên merged GDS:

```text
DRC
LVS
antenna
metal density
```

7. Nếu muốn giảm warning CTS, thử nâng `SRAM_CTS_LEAF_TOP_LAYER` có kiểm soát, rồi so sánh lại:

```text
IMPCCOPT-1007 count
reports/timing_postRoute/*.tran.gz
setup/hold WNS
congestion
```

8. Rerun sạch và không gõ lệnh `exitttt` sau `fit`.

## 18. Các lệnh kiểm tra trực tiếp trong GUI Innovus

Sau khi load checkpoint `saved/axi_ram_filled.enc` hoặc `saved/axi_ram_signoff_candidate.enc`, có thể dùng:

```tcl
dbGet [dbGet -p2 top.insts.cell.name srambank_256x4x32_6t122].name
dbGet [dbGet -p2 top.insts.cell.name srambank_256x4x32_6t122].pStatus
dbGet [dbGet -p2 top.insts.cell.name srambank_256x4x32_6t122].orient

checkPlace ./verify_rpt/checkPlace_gui_recheck.rpt
verify_drc -report ./verify_rpt/drc_gui_recheck.rpt
verifyConnectivity \
    -type all \
    -error 1000 \
    -warning 1000 \
    -report ./verify_rpt/connectivity_gui_recheck.rpt

timeDesign -postRoute -outDir ./reports/timing_gui_recheck
timeDesign -postRoute -hold -outDir ./reports/timing_gui_recheck_hold
```

Khi chụp hình GUI để trình bày, nên hiển thị riêng:

- Macro array 4 x 4 và orientation.
- Các gap M4/M5 giữa macro.
- Hard placement blockage quanh SRAM island.
- M8/M9 global ring.
- M4/M5 local SRAM PG.
- Top-level pins trên bốn cạnh.
- Clock tree sau CTS.
- Final routed layout sau filler.

