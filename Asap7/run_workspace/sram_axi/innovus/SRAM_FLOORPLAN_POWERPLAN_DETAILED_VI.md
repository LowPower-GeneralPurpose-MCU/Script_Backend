# Phân tích chi tiết floorplan và power plan cho SRAM island

Update 2026-08-13:

- Default SRAM island PG has been simplified after reading the latest `innovus.cmd`, `innovus.log`, and `pg_drc_*` reports.
- M5 column-gap collectors are disabled by default (`SRAM_ENABLE_COLUMN_GAP_PG=0`) because the latest DRC showed special M5 wires too close to ASAP7 SRAM M4 PG rail/pin shapes around the inter-bank gaps.
- SRAM `blockPin` special routing is disabled by default (`SRAM_CONNECT_BLOCK_PINS=0`) because the ASAP7 SRAM VDD/VSS rails are treated as hard-macro-internal shapes unless the abstract provides clean edge PG access.
- The default island now keeps only M4 top/row-gap straps and M5 left/right edge spines, preserving hard-macro priority and keeping top-level PG off the SRAM body.

Tài liệu này phân tích kỹ logic floorplan và power plan trong flow Innovus hiện tại của design `axi_ram`, tập trung vào giai đoạn trước standard-cell placement và phần power plan cho SRAM island. Nội dung bám theo script Tcl đang chạy, log/report hiện có, slide của thầy và tài liệu Cadence Innovus.

## 1. Mục tiêu vật lý của flow

Design dùng 16 SRAM macro `srambank_256x4x32_6t122`. Mục tiêu floorplan không chỉ là “đặt đủ 16 SRAM”, mà là tạo một cấu trúc physical có thể route, có power ổn định, và không phá các bước placement/CTS phía sau.

Các nguyên tắc chính:

- SRAM là hard macro lớn, nên ưu tiên đặt sát biên/corner để không chặn routing của standard cell ở giữa core.
- SRAM cùng module nên gom thành một island để giảm kết nối dài và giảm congestion.
- Giữa hai SRAM phải có khoảng hở đủ để đặt ít nhất một cặp VDD/VSS.
- SRAM dùng cặp orientation `R0/MY` xen kẽ theo cột; không dùng R90/R270.
- Sau khi macro placement xong phải set macro `FIXED`.
- Power global nên dùng metal cao, còn power local giữa SRAM dùng M4/M5 theo hướng routing của ASAP7.
- Signal/clock routing không nên đi xuyên qua thân SRAM; M6/M7 được guard cho over-the-macro route, còn M4/M5 giữ cho pin access/local SRAM PG.

Các nguyên tắc này khớp với:

- `10_Macro.pdf`: macro nên đặt ở boundary, SRAM có thể block routing tới M4/M5, gap giữa macro cần có VDD/VSS, macro chỉ nên R0/R180 và phải fixed.
- `x_Hierarchy Layout.pdf`: SRAM cùng module nên nằm cùng group, group SRAM nên ở corner/side, gap SRAM minh họa là 4 row, sau khi đặt SRAM phải chạy power grid để power lines đi giữa SRAM.
- `innovusUG.pdf`: trước optimization/CTS nên dùng halo/blockage/fence quanh hard block; nếu thấy routing xấu trên macro thì thêm blockage hoặc sửa floorplan.
- `innovusTCR.pdf`: các lệnh `floorPlan`, `placeInstance`, `addHaloToBlock`, `snapFPlan`, `createPlaceBlockage`, `addRing`, `addStripe`, `sroute`, `verifyConnectivity`, `createRouteBlk`, `setRouteMode` đều là lệnh đúng mục đích trong Innovus.

## 2. Flow tổng thể trong `innovus.tcl`

Main flow chạy bằng:

```tcl
innovus -stylus -files tcl/innovus.tcl
```

Thứ tự liên quan tới floorplan và power plan:

```tcl
source ./tcl/innovus.globals
init_design
setDesignMode -process 7

floorPlan ...
source ./tcl/finish_hierFP.tcl

source ./tcl/sram_macro_floorplan.tcl
source ./tcl/finish_macroFP.tcl

source ./tcl/sram_route_guard.tcl
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_before_pnr.rpt

source ./tcl/power_plan.tcl
source ./tcl/pins.tcl
saveDesign ./saved/axi_ram_floorplan_power_pins.enc
```

Ý nghĩa:

- `innovus.globals` nạp cấu hình công nghệ, thư viện, netlist, MMMC và `project_config.tcl`.
- `init_design` tạo database Innovus.
- `floorPlan` tạo die/core ban đầu.
- `sram_macro_floorplan.tcl` đặt 16 SRAM.
- `finish_macroFP.tcl` kiểm tra và cố định SRAM.
- `sram_route_guard.tcl` tạo routing blockage cho thân SRAM trước placement/CTS.
- `power_plan.tcl` tạo global ring, SRAM island PG và PG pin.
- `pins.tcl` spread signal pins lên 4 cạnh.

Điểm quan trọng: mọi phần Tcl phụ phải được source trực tiếp trong `innovus.tcl`, vì bạn thường chỉ chạy main file. Nếu chỉ tạo file phụ mà không source trong main flow thì Innovus sẽ không thực hiện phần đó.

## 3. Setup SRAM trong `sram_macro_setup.tcl`

### 3.1. Khai báo SRAM master và số lượng macro

Script khai báo:

```tcl
set SRAM_MASTER "srambank_256x4x32_6t122"
set SRAM_ROWS 4
set SRAM_COLS 4
set SRAM_COUNT [expr {$SRAM_ROWS * $SRAM_COLS}]
```

Logic:

- `SRAM_MASTER` là tên LEF/LIB cell của SRAM macro.
- `SRAM_ROWS=4`, `SRAM_COLS=4` tạo island 4x4.
- `SRAM_COUNT=16` là số SRAM bắt buộc phải tìm thấy trong database.

Vì sao phải kiểm `SRAM_COUNT`:

- Nếu netlist thiếu hoặc thừa SRAM, placement/power plan sẽ sai toàn bộ.
- `dbGet -p2 top.insts.cell.name $SRAM_MASTER` được dùng để lấy đúng các instance SRAM theo master.
- Nếu số lượng không đúng, script phải dừng sớm thay vì tiếp tục tạo floorplan sai.

### 3.2. Khai báo physical view của SRAM

```tcl
set SRAM_LIB "${SRAM_ROOT}/generated/LIB/${SRAM_MASTER}.lib"
set SRAM_LEF "${SRAM_ROOT}/generated/LEF/4xLEF/${SRAM_MASTER}.lef.4x.lef"
set SRAM_GDS "${SRAM_ROOT}/gds/srambank_32b.gds"
```

Logic:

- Liberty `.lib` phục vụ timing/power model.
- LEF phục vụ placement/routing abstraction.
- GDS phục vụ stream-out/signoff.

Script kiểm tra tồn tại các file này:

```tcl
foreach f [list $SRAM_LIB $SRAM_LEF $SRAM_GDS] {
    if {![file exists $f]} {
        error "Missing ASAP7 SRAM macro view: [file normalize $f]"
    }
}
```

Vì sao cần dừng nếu thiếu:

- Thiếu LEF: Innovus không biết kích thước, pin, OBS của macro.
- Thiếu Liberty: CTS/timing không hiểu delay/constraint của SRAM.
- Thiếu GDS: route có thể chạy nhưng stream-out/signoff không đầy đủ.

### 3.3. Grid, row height và gap SRAM

```tcl
set FLOORPLAN_GRID 0.384
set ASAP7_SITE_WIDTH 0.216
set ASAP7_ROW_HEIGHT 1.080
set SRAM_MACRO_GAP_ROWS 4
set SRAM_BLOCKAGE_BORDER_ROWS 2

set SRAM_MACRO_GAP_X [expr {
    $SRAM_MACRO_GAP_ROWS * $ASAP7_ROW_HEIGHT
}]
set SRAM_MACRO_GAP_Y [expr {
    $SRAM_MACRO_GAP_ROWS * $ASAP7_ROW_HEIGHT
}]
set SRAM_BLOCKAGE_BORDER [expr {
    $SRAM_BLOCKAGE_BORDER_ROWS * $ASAP7_ROW_HEIGHT
}]
```

Tính ra:

- Gap giữa SRAM: `4 * 1.080 = 4.320 um`.
- Border quanh island: `2 * 1.080 = 2.160 um`.

Logic:

- Gap 4 row khớp với slide hierarchy layout.
- Border 2 row mỗi bên giúp tạo halo/blockage quanh macro.
- Hai halo 2 row của hai SRAM kề nhau vừa đủ gặp nhau trong gap 4 row.
- Gap 4 row đủ chỗ để đặt một cặp VDD/VSS local collector trên M4/M5.

Vì sao không để gap quá nhỏ:

- SRAM có thể block routing tới M4/M5.
- Nếu gap không đủ, addStripe không thể đặt đủ một cặp VDD/VSS.
- Nếu standard cell bị đẩy vào khe nhỏ giữa SRAM, routing và CTS rất dễ lỗi.

### 3.4. Logic chọn cặp orientation R0/MY

```tcl
set SRAM_ISLAND_ORIENT "R0"
set SRAM_MIRROR_ORIENT "MY"
```

Lý do:

- `R0` là orientation chuẩn; `MY` mirror macro theo trục Y, tức đảo trái-phải.
- Đặt xen kẽ `R0`, `MY`, `R0`, `MY` theo chiều X làm hai SRAM kề nhau đối xứng trong khe giữa chúng.
- Cặp này giữ nguyên `SRAM_W`, `SRAM_H`, tọa độ origin và khoảng hở 4 row, nên không làm thay đổi kích thước island hay PG area.
- `sram_macro_floorplan.tcl` tính orientation từ column thay vì dùng một orientation chung cho cả 16 macro.
- Không dùng R90/R270 để tránh phá hướng internal rails/poly và rule của advanced node.

## 4. Tính core size và hierarchy floorplan trong `innovus.tcl`

### 4.1. Lấy kích thước SRAM thật từ database

```tcl
set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]
set first_sram_ptr [lindex $SRAM_PTRS 0]
set SRAM_W [dbGet $first_sram_ptr.cell.size_x]
set SRAM_H [dbGet $first_sram_ptr.cell.size_y]
```

Logic:

- Không hard-code kích thước SRAM.
- Lấy size từ LEF/database để nếu macro view thay đổi, floorplan cũng cập nhật.
- Đây là cách đúng hơn so với đo bằng mắt trong GUI.

### 4.2. Tính kích thước SRAM island

```tcl
set SRAM_ISLAND_W [expr {
    $SRAM_COLS * $SRAM_W +
    ($SRAM_COLS - 1) * $SRAM_MACRO_GAP_X
}]
set SRAM_ISLAND_H [expr {
    $SRAM_ROWS * $SRAM_H +
    ($SRAM_ROWS - 1) * $SRAM_MACRO_GAP_Y
}]
```

Logic:

- Width island = tổng width 4 macro + 3 gap ngang.
- Height island = tổng height 4 macro + 3 gap dọc.

Với report hiện tại:

- SRAM body từ `x=2.16` tới `x=500.688`.
- SRAM body từ `y=2.16` tới `y=706.32`.
- Đây là vùng 4x4 đã được đặt đúng lower-left.

### 4.3. Tính core size

```tcl
set CORE_W [snap_up [expr {
    2.0 * $SRAM_EDGE_GAP_X +
    $SRAM_ISLAND_W +
    $SRAM_ISLAND_ESCAPE_RIGHT +
    $LOGIC_REGION_WIDTH
}] $FLOORPLAN_GRID]

set CORE_H [snap_up [expr {
    2.0 * $SRAM_EDGE_GAP_Y +
    $SRAM_ISLAND_H +
    $SRAM_ISLAND_ESCAPE_TOP +
    $LOGIC_REGION_HEIGHT
}] $FLOORPLAN_GRID]
```

Logic:

- Core phải chứa SRAM island.
- Bên phải SRAM cần logic region.
- Phía trên SRAM cần logic region.
- `SRAM_ISLAND_ESCAPE_RIGHT` và `SRAM_ISLAND_ESCAPE_TOP` tạo vùng thoát power/routing ở cạnh exposed của island.
- `snap_up` ép core size lên `FLOORPLAN_GRID` để core/die nằm đúng grid.

### 4.4. Tạo floorplan

```tcl
floorPlan \
    -s $CORE_W $CORE_H \
    $margin_dist $margin_dist $margin_dist $margin_dist
```

Ý nghĩa lệnh:

- `floorPlan -s $CORE_W $CORE_H` tạo core size.
- Bốn giá trị `margin_dist` tạo khoảng cách die-to-core đều bốn phía.
- `margin_dist = SRAM_BLOCKAGE_BORDER = 2.160 um`.

Vì sao margin bằng 2 row:

- Tạo đủ không gian cho M8/M9 global ring nằm quanh core.
- Lower-left SRAM sát core boundary nhưng vẫn có die-to-core margin để đặt/reuse global ring.
- Điều này giúp SRAM island có thể tận dụng M9-left và M8-bottom global ring thay vì vẽ thêm duplicate local ring ở hai cạnh sát biên.

## 5. Logic đặt SRAM trong `sram_macro_floorplan.tcl`

### 5.1. Tìm và sắp xếp SRAM instance

```tcl
set SRAM_PTRS [dbGet -p2 top.insts.cell.name $SRAM_MASTER]

foreach ptr $SRAM_PTRS {
    set name [lindex [dbGet $ptr.name] 0]
    set index [sram_bank_index $name $fallback]
    lappend SRAM_RECORDS [list $index $name $ptr]
}
set SRAM_RECORDS [lsort -integer -index 0 $SRAM_RECORDS]
```

Logic:

- Lấy instance bằng master SRAM.
- Parse bank index từ tên instance, ví dụ `G_SRAM_BANK[9]`.
- Sort theo index để mapping placement ổn định giữa các lần chạy.

Vì sao cần deterministic order:

- Nếu thứ tự `dbGet` thay đổi, SRAM bank có thể bị hoán đổi vị trí giữa các lần chạy.
- Điều đó làm thay đổi routing, timing và debug GUI rất khó.
- Report `sram_macro_final_map.rpt` sẽ có mapping rõ bank nào nằm ở tọa độ nào.

### 5.2. Kiểm tra số lượng và index

```tcl
if {[llength $SRAM_RECORDS] != $SRAM_COUNT} {
    error "Expected $SRAM_COUNT SRAM macros, found [llength $SRAM_RECORDS]"
}
```

Script cũng kiểm duplicate bank index.

Lý do:

- Nếu hai instance parse ra cùng index, snake-order placement sẽ sai.
- Nếu thiếu index, một bank có thể bị đặt nhầm vị trí.
- Đây là lỗi logic, phải dừng trước placement.

### 5.3. Đặt seed 4x4 với snake ordering

```tcl
set row [expr {int($k / $SRAM_COLS)}]
set pos [expr {$k % $SRAM_COLS}]

if {[expr {$row % 2}] == 0} {
    set col $pos
} else {
    set col [expr {$SRAM_COLS - 1 - $pos}]
}
```

Logic:

- Mỗi row có 4 SRAM.
- Row chẵn đặt trái sang phải.
- Row lẻ đặt phải sang trái.
- Đây là snake pattern.

Vì sao dùng snake pattern:

- Giảm độ dài kết nối giữa các bank liên tiếp nếu bus/address/data có quan hệ tuần tự.
- Tránh để bank index nhảy quá xa giữa hai row.
- Vẫn giữ island hình chữ nhật đều, không tạo notch.

### 5.4. Tính tọa độ từng macro

```tcl
set x [expr {
    $SRAM_X0 + $col * ($SRAM_W + $SRAM_MACRO_GAP_X)
}]
set y [expr {
    $SRAM_Y0 + $row * ($SRAM_H + $SRAM_MACRO_GAP_Y)
}]
set snap_x [sram_snap_to_grid $x $ASAP7_SITE_WIDTH]
set snap_y [sram_snap_to_grid $y $ASAP7_SITE_WIDTH]
placeInstance $name $snap_x $snap_y $SRAM_ISLAND_ORIENT
```

Ý nghĩa lệnh:

- `placeInstance` đặt hard macro tại tọa độ `(x, y)` với orientation lấy từ pattern R0/MY của column.
- `sram_snap_to_grid` ép tọa độ về site/manufacturing grid.

Vì sao snap theo site width:

- Macro nếu lệch grid có thể gây warning placement hoặc DRC.
- Standard-cell row/site trong ASAP7 có grid rất chặt.
- Snap giúp `snapFPlan -block` phía sau không làm thay đổi gap 4 row quá nhiều.

### 5.5. Bỏ temporary PG resource model trong macro placement

Flow hiện tại không còn dùng PG-model tạm hay concurrent macro placer.

Lý do bỏ:

- SRAM đã được yêu cầu thành một island 4x4 cố định, nên concurrent macro placement không còn cần thiết.
- PG model tạm từng tạo M4/M5 ring/stripe với `extend_to design_boundary`; khi debug GUI rất dễ nhìn thành global power đi phủ lên SRAM island.
- Theo cách đi đơn giản trong slide của thầy, final SRAM PG nên chỉ được tạo một lần ở gap/halo bằng `sram_island_power.tcl`.

### 5.6. Deterministic 4x4 packing

Script hiện tại đi theo sequence:

```tcl
# deterministic 4x4 seed -> physical group/fence
# -> snap -> validate -> FIXED -> save
```

Logic:

- Dùng seed 4x4 để đặt SRAM vào vị trí mong muốn ngay từ đầu.
- Tạo physical group/fence để giữ toàn bộ macro trong island lower-left.
- Ép lại deterministic 4x4 packing để layout cuối ổn định.

Vì sao không dùng macro placement tự động cho case này:

- Macro placer có thể tạo island không đều, overlap hoặc notch.
- Với 16 SRAM gần nhau, yêu cầu gap 4 row và power collector giữa SRAM quan trọng hơn kết quả wirelength tự động.
- Slide của thầy cũng yêu cầu SRAM placement thường phải review/manual optimize.

## 6. Finish macro floorplan trong `finish_macroFP.tcl`

### 6.1. Thêm halo quanh SRAM

```tcl
addHaloToBlock \
    -allBlock \
    $SRAM_HALO_L $SRAM_HALO_B $SRAM_HALO_R $SRAM_HALO_T
```

Ý nghĩa:

- Tạo halo quanh tất cả macro.
- Halo dùng border 2 row.

Vì sao cần halo:

- Tránh standard cell áp sát SRAM.
- Chừa khoảng cho PG stripe, via, routing access.
- Theo Innovus UG, hard block nên có halo/blockage trước optimization/CTS.

### 6.2. Snap macro/floorplan block

```tcl
snapFPlan -block
```

Ý nghĩa:

- Snap block placement về grid hợp lệ.
- Giảm lỗi off-grid.

Vì sao phải validate sau snap:

- Snap có thể làm thay đổi tọa độ.
- Nếu không kiểm lại, gap 4 row có thể bị lệch hoặc macro overlap.

### 6.3. Dùng nominal box thay vì expanded db box

Script tính:

```tcl
set nominal_llx $x
set nominal_lly $y
set nominal_urx [expr {$x + $SRAM_W}]
set nominal_ury [expr {$y + $SRAM_H}]
```

Lý do:

- Log có warning `IMPPP-133`: SRAM LEF có OBS V3 hơi vượt ra ngoài macro boundary.
- Innovus mở rộng `ptr.box` vì OBS, nhưng placement spacing nên đo theo declared macro body.
- Nếu đo theo expanded box, script có thể báo gap sai dù macro body đúng.

### 6.4. Set SRAM fixed

```tcl
dbSet $ptr.pStatus fixed
set status [lindex [dbGet $ptr.pStatus] 0]
if {$status ne "fixed"} {
    error "$name was not FIXED after snapFPlan"
}
```

Ý nghĩa:

- `dbSet $ptr.pStatus fixed` cố định macro.
- `dbGet` kiểm lại status thực tế.

Vì sao dùng `[lindex [dbGet ...] 0]`:

- `dbGet` trong Innovus nhiều khi trả list.
- So sánh trực tiếp list với string có thể sai hoặc gây fail giả.
- Chuẩn hóa bằng `lindex 0` giúp Tcl so sánh đúng.

### 6.5. Kiểm tra overlap và gap 4 row

Script lặp qua từng cặp SRAM:

- Nếu overlap X và overlap Y cùng dương thì báo overlap.
- Nếu cùng hàng thì tính gap X.
- Nếu cùng cột thì tính gap Y.
- So sánh gap nhỏ nhất với `SRAM_MACRO_GAP_X/Y`.

Ý nghĩa:

- Bảo đảm SRAM island đúng cấu trúc lưới.
- Bảo đảm gap ngang/dọc vẫn là 4 row.
- Nếu sai thì dừng trước power plan.

Report baseline hiện tại `sram_macro_final_map.rpt` cho thấy:

- 16 SRAM đều `R180 fixed`; đây là checkpoint trước khi đổi orientation và không đại diện cho run mới.
- Tọa độ nằm đúng island lower-left.
- Không có SRAM bị unplaced.

## 7. Placement blockage và island boundary

Trong `finish_macroFP.tcl`, sau khi có actual island bbox, script tính:

- `SRAM_ISLAND_LLX/LLY/URX/URY`: biên macro body thật.
- `SRAM_ISLAND_CUT_URX/URY`: biên island có thêm escape/border.
- `SRAM_ISLAND_BLOCKAGE_*`: blockage bao toàn bộ SRAM body, gap và border.

Logic:

- Placement blockage phải bao phủ cả macro body lẫn gap giữa macro.
- Nếu không, standard cell có thể bị nhét vào gap SRAM.
- Với SRAM island, gap đó dành cho PG collector, không dành cho random standard cell.

Vì sao blockage clamp tới die ở lower-left:

- SRAM island đặt sát lower-left core boundary.
- Die-to-core margin ở lower-left có global ring.
- Blockage nhìn trên GUI cần phủ đúng vùng SRAM island và margin liên quan tới ring, tránh cảm giác lệch.

## 8. Route guard cho SRAM body

Sau macro fixed, `innovus.tcl` source:

```tcl
source ./tcl/sram_route_guard.tcl
```

Trong `sram_route_guard.tcl`:

```tcl
set SRAM_ROUTE_GUARD_LAYERS {M6 M7}
set SRAM_ROUTE_GUARD_EGR_LAYER M5

createRouteBlk \
    -name $guard_name \
    -box [list $llx $lly $urx $ury] \
    -layer $SRAM_ROUTE_GUARD_LAYERS \
    -exceptpgnet

setRouteMode \
    -earlyGlobalReverseDirection $sram_egr_reverse_regions
```

Logic:

- `createRouteBlk` tạo routing blockage trên từng SRAM body.
- `-layer {M6 M7}` chặn over-the-macro signal/clock routing; không block M4/M5 vì đây là pin-access/local SRAM PG layer của generated ASAP7 SRAM.
- `-exceptpgnet` không chặn power/ground special routing.
- `setRouteMode -earlyGlobalReverseDirection` giúp early global route/CTS estimation biết vùng SRAM trên M5 có resource đặc biệt.

Vì sao không dùng blockage all-layer:

- SRAM có thể cần power special routing/via đi qua một số vùng hợp lệ.
- Global/top routing trên layer cao không nhất thiết phải block hết.
- Mục tiêu trước mắt là bảo vệ SRAM body khỏi over-route M6/M7, trong khi vẫn để M4/M5 cho pin access và local SRAM PG.

Evidence từ log:

```text
[NR-eGR] #Routing Blockages : 32
```

Giải thích số 32:

- 16 SRAM macro.
- Mỗi macro có blockage trên 2 layer M6 và M7.
- 16 x 2 = 32 route blockages.

Report `sram_route_guard.rpt` cũng ghi từng SRAM có `{M6 M7}`, `yes`, `M5`, `fixed`.

## 9. Power plan tổng quan trong `power_plan.tcl`

Power plan chia thành 3 lớp:

1. Global core ring trên M8/M9.
2. SRAM island local PG trên M4/M5, có reuse global ring ở left/bottom.
3. Sau placement, standard-cell PG rails/taps trên M1/M5 và upper mesh M8/M9 ngoài SRAM.

Layer roles trong comment script:

```tcl
##   M4/M5 : legal-width SRAM row/column collectors
##   M8/M9 : deterministic VDD/VSS core-ring pair shared by logic and SRAM
##   M1/M5 : post-placement standard-cell rails/taps
```

Logic:

- M8/M9 dùng cho power global vì là layer cao, phù hợp route dài.
- M4/M5 dùng cho local SRAM collector vì SRAM gap nằm trong local macro island.
- M1 là rail chuẩn của standard cell, chỉ xử lý sau placement.

## 10. Track grid và helper functions trong power plan

### 10.1. Khai báo pitch/offset theo ASAP7

```tcl
array set PG_TRACK_PITCH {
    M4 0.192
    M5 0.192
    M6 0.256
    M7 0.256
    M8 0.320
    M9 0.320
}

array set PG_TRACK_OFFSET {
    M4 0.012
    M5 0.000
    M6 0.000
    M7 0.000
    M8 0.000
    M9 0.000
}
```

Logic:

- `addStripe` cần `start_offset`.
- Nếu offset không align routing track, Innovus sẽ snap hoặc báo warning.
- Helper function tự tính offset hợp lệ trước khi gọi `addStripe`.

### 10.2. Snap stripe về track

```tcl
proc pg_snap_value_to_layer_track {value layer} {
    set pitch [pg_layer_pitch $layer]
    set offset [pg_layer_offset $layer]
    set snapped [expr {$offset + round(($value - $offset) / $pitch) * $pitch}]
    return [pg_format_coord $snapped]
}
```

Ý nghĩa:

- Tính tọa độ gần nhất trên routing track.
- Dùng cho edge/center của power stripe.

Vì sao cần:

- ASAP7 là advanced node, routing grid chặt.
- Nếu để tool tự snap quá nhiều, report/GUI nominal có thể không khớp vị trí thật.
- Tự tính offset giúp deterministic và dễ debug.

### 10.3. Tính offset cho một cặp VDD/VSS trong channel

```tcl
proc pg_track_aligned_pair_offset {area_start area_stop layer width spacing} {
    set channel [expr {$area_stop - $area_start}]
    set pair_total [expr {2.0 * $width + $spacing}]
    ...
    return [pg_format_coord [expr {$edge - $area_start}]]
}
```

Logic:

- Một cặp gồm 2 stripe: VDD và VSS.
- Tổng bề rộng cần: `2*width + spacing`.
- Hàm đặt cặp này vào giữa channel và snap về track.

Vì sao dùng cho SRAM gap:

- Mỗi gap giữa SRAM chỉ cần một cặp VDD/VSS.
- Dùng offset theo channel giúp cặp power nằm giữa gap, không sát macro edge.

## 11. Global core ring M8/M9

Power plan tạo core ring deterministic bằng M8/M9:

- M8: top/bottom horizontal.
- M9: left/right vertical.
- VDD và VSS được tạo thành hai ring riêng.

Logic:

- Không phụ thuộc vào một lệnh two-net `addRing` duy nhất vì với margin nhỏ và snapping, GUI/log trước đó có tình trạng nhìn như chỉ có một net rõ.
- Tạo ring riêng cho VDD/VSS giúp kiểm tra từng net rõ hơn.
- Sau khi tạo ring, script chạy `pg_assert_complete_core_rings`.

### 11.1. Vì sao dùng M8/M9 cho global ring

- M8/M9 là metal cao, phù hợp cấp nguồn toàn chip.
- Ít tranh chấp với M4/M5 local SRAM collector.
- Phù hợp với cách hiểu của bạn: global ring ngoài dùng M8/M9, local giữa SRAM dùng M4/M5.

### 11.2. Tạo PG pin từ ring thật

Script không đoán hình ring theo offset nominal, mà query actual special wire:

```tcl
set wire_ptrs [dbGet -p2 $net_ptr.sWires.layer.name M9]
...
createPGPin $net -geom M9 ... -net $net
```

Logic:

- `addRing` có thể snap wire center theo grid.
- Nếu tự tính geometry từ offset nominal, PG pin có thể lệch khỏi wire thật.
- Query actual `sWire.box` giúp PG pin nằm đúng trên M9 ring thật.

## 12. SRAM island power plan trong `sram_island_power.tcl`

### 12.1. Topology được chọn

Comment đầu file mô tả rõ:

```tcl
## 1. Build an open local ring on the exposed top/right island edges.
## 2. Reuse the global M9-left/M8-bottom ring edges beside the island.
## 3. Add a narrow M5 transition spine at the reused left edge.
## 4. Add no-jog M4/M5 collectors in the actual SRAM gaps.
## 5. Use stacked ViaGen connections only at matching-net intersections.
## 6. Connect SRAM block pins to the nearest collector stripe and trim stubs.
```

Nói ngắn gọn:

- Cạnh left của SRAM island: tận dụng M9 global ring.
- Cạnh bottom của SRAM island: tận dụng M8 global ring.
- Cạnh top exposed: tạo local M4 pair.
- Cạnh right exposed: tạo local M5 pair.
- Giữa các row SRAM: tạo M4 horizontal VDD/VSS pair.
- Giữa các column SRAM: tạo M5 vertical VDD/VSS pair.

Đây là logic đúng với ý bạn: cạnh sát global ring thì tận dụng global ring; còn giữa các SRAM phải có M4/M5 local PG.

### 12.2. Kiểm tra biến đầu vào

```tcl
foreach required_variable {
    SRAM_MASTER
    SRAM_COUNT
    SRAM_ROWS
    SRAM_COLS
    SRAM_X0
    SRAM_Y0
    SRAM_W
    SRAM_H
    SRAM_MACRO_GAP_X
    SRAM_MACRO_GAP_Y
    SRAM_ISLAND_URX
    SRAM_ISLAND_URY
    SRAM_ISLAND_CUT_URX
    SRAM_ISLAND_CUT_URY
    ASAP7_ROW_HEIGHT
    power_die_llx
    power_die_lly
    stripe_m45_w
    stripe_m45_s
} {
    if {![info exists $required_variable]} {
        error "Missing $required_variable before SRAM island power planning"
    }
}
```

Logic:

- Power plan phụ thuộc vào geometry được tạo ở floorplan.
- Nếu thiếu geometry, addStripe có thể vẽ sai vùng hoặc ra ngoài die.
- Vì vậy script dừng sớm nếu thiếu biến.

### 12.3. Kiểm tra gap có đủ một cặp VDD/VSS

```tcl
set sram_pair_total [expr {2.0 * $sram_stripe_w + $sram_stripe_s}]
if {$SRAM_MACRO_GAP_Y <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_Y=$SRAM_MACRO_GAP_Y is too small for one M4 VSS/VDD pair"
}
if {$SRAM_MACRO_GAP_X <= $sram_pair_total} {
    error "SRAM_MACRO_GAP_X=$SRAM_MACRO_GAP_X is too small for one M5 VSS/VDD pair"
}
```

Logic:

- Mỗi gap cần chứa 2 stripes và spacing giữa chúng.
- Nếu gap nhỏ hơn tổng này, physical power plan không hợp lệ.
- Đây là check trực tiếp theo slide Macro: giữa macro phải có ít nhất một cặp VDD/VSS.

### 12.4. Vùng power của SRAM island

```tcl
set sram_pg_left $power_die_llx
set sram_pg_bottom $power_die_lly
set sram_pg_right $SRAM_ISLAND_CUT_URX
set sram_pg_top $SRAM_ISLAND_CUT_URY
```

Logic:

- Stripe bắt đầu từ die boundary, không chỉ từ core boundary.
- Lý do là global ring nằm trong vùng die-to-core margin.
- Cho stripe cross qua vùng ring rồi dùng `editTrim` cắt stub thừa.

Vì sao không dừng ở core boundary:

- Nếu stripe dừng trước ring, nó không chạm global ring.
- Khi đó local SRAM PG có thể nhìn có shape nhưng không connect ra global PG.
- Đây chính là lỗi GUI bạn từng thấy: đường trong SRAM không nối ra global ring.

### 12.5. Local-left M5 transition spine

Script tạo trước:

```tcl
setAddStripeMode \
    -allow_jog none \
    -allow_nonpreferred_dir none \
    -break_at none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M4 \
    -stacked_via_top_layer M8

addStripe \
    -nets {VSS VDD} \
    -layer M5 \
    -direction vertical \
    -width $sram_stripe_w \
    -spacing $sram_stripe_s \
    -start_from left \
    -start_offset $local_left_offset \
    -number_of_sets 1 \
    -create_pins 0 \
    -area $local_left_area \
    -snap_wire_center_to_grid Grid \
    -allow_snapping_override_custom_spacing 1
```

Logic:

- Left global edge là M9, nhưng SRAM row collectors là M4.
- Cần M5 transition spine để M4 row collectors có thể qua M5 rồi lên M8/M9.
- Tạo spine trước để các M4 horizontal stripes có target cùng net khi cắt/giao nhau.

Vì sao dùng `-allow_jog none`:

- Không muốn tool tự bẻ power stripe.
- SRAM PG cần thẳng, dễ kiểm, giống reference flow của thầy.

Vì sao `-create_pins 0`:

- Đây là internal PG stripe, không phải top-level IO pin.
- PG pins đã tạo riêng từ core ring.

### 12.6. Local-top M4 pair

```tcl
addStripe \
    -nets {VSS VDD} \
    -layer M4 \
    -direction horizontal \
    ...
    -area $local_top_area
```

Logic:

- Top edge là cạnh exposed của SRAM island.
- Dùng M4 horizontal vì ASAP7 mapping trong script: M4 horizontal, M5 vertical.
- Local-top pair đóng vai trò cạnh trên của open local ring.

Vì sao không dùng M8/M9 cho cạnh này:

- M8/M9 đã là global/top resource.
- Giữa SRAM và local pins/PG collector cần M4/M5 thấp hơn.
- M4/M5 phù hợp với local SRAM island power grid.

### 12.7. M4 row-gap collectors giữa các hàng SRAM

```tcl
for {set r 0} {$r < [expr {$SRAM_ROWS - 1}]} {incr r} {
    set gap_lly [expr {
        $SRAM_Y0 + ($r + 1) * $SRAM_H + $r * $SRAM_MACRO_GAP_Y
    }]
    set gap_ury [expr {$gap_lly + $SRAM_MACRO_GAP_Y}]
    ...
    addStripe \
        -nets {VSS VDD} \
        -layer M4 \
        -direction horizontal \
        -area $stripe_area
}
```

Với 4 row SRAM, có 3 row gaps.

Logic:

- Mỗi gap ngang giữa hai hàng SRAM có một cặp VSS/VDD trên M4.
- M4 horizontal đi xuyên qua width island.
- Vùng stripe bắt đầu từ die-left để cross/reuse global ring và dừng ở `SRAM_ISLAND_CUT_URX`.

Vì sao loop theo `SRAM_ROWS - 1`:

- 4 hàng SRAM có 3 khoảng giữa hàng.
- Không vẽ stripe trên thân macro, chỉ vẽ trong gap.

### 12.8. Local-right M5 pair

```tcl
addStripe \
    -nets {VSS VDD} \
    -layer M5 \
    -direction vertical \
    ...
    -area $local_right_area
```

Logic:

- Right edge là cạnh exposed của SRAM island.
- Dùng M5 vertical làm cạnh phải của open local ring.
- M5 right edge giúp nối các M4 row-gap collectors và M5 column-gap collectors về một edge PG liên tục.

### 12.9. M5 column-gap collectors giữa các cột SRAM

```tcl
for {set c 0} {$c < [expr {$SRAM_COLS - 1}]} {incr c} {
    set gap_llx [expr {
        $SRAM_X0 + ($c + 1) * $SRAM_W + $c * $SRAM_MACRO_GAP_X
    }]
    set gap_urx [expr {$gap_llx + $SRAM_MACRO_GAP_X}]
    ...
    addStripe \
        -nets {VSS VDD} \
        -layer M5 \
        -direction vertical \
        -area $stripe_area
}
```

Với 4 column SRAM, có 3 column gaps.

Logic:

- Mỗi gap dọc giữa hai cột SRAM có một cặp VSS/VDD trên M5.
- M5 vertical đi từ die-bottom tới `SRAM_ISLAND_CUT_URY`.
- Nó cross bottom global M8 ring để có via connection lên global network.

### 12.10. Kết nối SRAM block pins

Sau khi tạo collectors, script dùng `sroute`:

```tcl
setSrouteMode ...
sroute \
    -connect {blockPin} \
    -nets {VSS VDD} \
    -blockPinLayerRange {M4 M4} \
    -blockPinWidthRange {0.150 0.250} \
    -blockPinTarget {stripe} \
    -allowJogging 0
```

Logic:

- SRAM PG pins được connect tới target power stripe gần nhất.
- The SRAM hard macro exposes its main VDD/VSS rail ports on M4, so the
  top-level blockPin stitch should target those M4 rail ports rather than
  narrow internal M3 access shapes.
- `viaConnectToShape stripe` ưu tiên nối pin tới stripe collector nội bộ.

Vì sao không dùng `allowJogging/allowLayerChange` ở đây:

- Mục tiêu là để SRAM block pins đâm thẳng vào collector.
- Nếu cho phép jog/layer change tự do, Innovus có thể tạo các đoạn vòng vèo khó kiểm soát.
- Flow của thầy cũng minh họa SRAM island PG theo kiểu thẳng, không dùng allowJogging/allowLayerChange cho phần này.

## 13. Kiểm tra SRAM PG edge

Script có hàm:

```tcl
proc sram_pg_assert_edge_wires {report_path edge_specs} { ... }
```

Nó ghi report:

```text
edge net layer direction wires coverage_um required_um area
```

Report hiện tại cho thấy:

- `reused_left`: VSS/VDD trên M9 vertical.
- `reused_bottom`: VSS/VDD trên M8 horizontal.
- `local_top`: VSS/VDD trên M4 horizontal.
- `local_right`: VSS/VDD trên M5 vertical.

Ý nghĩa:

- Cạnh left/bottom đã reuse global ring.
- Cạnh top/right đã có local open ring.
- SRAM island không còn chỉ có một đường VDD hoặc thiếu VSS như lỗi GUI trước.

Lưu ý kỹ thuật:

- `local_left VDD M5` trong report hiện có coverage hơi thấp hơn threshold edge guard.
- Tuy nhiên `verifyConnectivity` sau trim báo VDD/VSS clean.
- Nghĩa là connectivity tổng thể sạch, nhưng local-left transition spine nên tiếp tục review bằng GUI nếu muốn edge coverage đẹp hơn.

## 14. Post-placement power cho standard cell

Power cho standard cell không nên làm quá sớm, vì M1 rails phụ thuộc placement của rows/cells.

Sau `place_opt_design`, script chạy:

```tcl
source ./tcl/global_upper_pg_to_ring.tcl
source ./tcl/core_lower_pg_nojog.tcl
```

### 14.1. `global_upper_pg_to_ring.tcl`

Script chia vùng logic ngoài SRAM thành L-shape:

- M8 horizontal:
  - `UPPER_TOP_FULL_BOX`
  - `UPPER_RIGHT_LOWER_BOX`
- M9 vertical:
  - `UPPER_RIGHT_FULL_BOX`
  - `UPPER_TOP_LEFT_BOX`

Logic:

- Không tạo regular M8/M9 stripe trên SRAM island.
- Chỉ tạo upper mesh ở vùng logic ngoài SRAM.
- Vẫn giữ global phase chung để các stripe thẳng hàng.

Lệnh chính:

```tcl
setAddStripeMode \
    -allow_jog none \
    -extend_to_closest_target area_boundary \
    -stacked_via_bottom_layer M7 \
    -stacked_via_top_layer M9

addStripe \
    -nets {VDD VSS} \
    -layer M8 \
    -direction horizontal \
    -area $area
```

Vì sao dùng `-area` thay vì `-extend_to design_boundary`:

- `-area` kiểm soát rõ vùng stripe.
- Tránh stripe đi qua SRAM island.
- Tránh Innovus vẽ power global đè lên macro body.

### 14.2. `core_lower_pg_nojog.tcl`

Script làm hai việc:

1. Nối M1 follow-pin rails của standard cell:

```tcl
sroute \
    -connect {corePin} \
    -nets {VDD VSS} \
    -allowJogging 0 \
    -allowLayerChange 0
```

2. Tạo M5 vertical taps để nối M1 rails lên upper/global PG:

```tcl
addStripe \
    -nets {VDD VSS} \
    -layer M5 \
    -direction vertical \
    -area $area \
    -snap_wire_center_to_grid Grid
```

Logic:

- `sroute -connect corePin` nối standard-cell PG pins/rails.
- `-allowJogging 0 -allowLayerChange 0` giữ kết nối thẳng, tránh tool tự bẻ/đổi layer lung tung.
- M5 taps tạo kết nối M1 -> M8 qua stacked ViaGen.
- Có một `LOGIC_RIGHT_EDGE_TAP_BOX` sát cạnh phải SRAM island để local/global PG không bị hở ngay sát boundary SRAM.

Vì sao không tạo M5 mesh trong SRAM island:

- SRAM island đã có local M4/M5 collectors riêng.
- M5 mesh standard-cell nếu đi vào SRAM island sẽ lẫn với SRAM PG và dễ nhìn sai trong GUI.
- Vùng SRAM đã có blockage và không dành cho standard cell.

## 15. Kiểm tra PG connectivity

Sau power routing, script chạy:

```tcl
verifyConnectivity \
    -type special \
    -net {VDD VSS} \
    -noUnroutedNet \
    -report ./verify_rpt/pg_connectivity_before_trim.rpt

editTrim -nets {VDD VSS}

verifyConnectivity \
    -type special \
    -net {VDD VSS} \
    -noUnroutedNet \
    -report ./verify_rpt/pg_connectivity_after_trim.rpt
```

Ý nghĩa:

- Chỉ kiểm VDD/VSS special routes, không kéo signal IO chưa route vào report.
- `editTrim` cắt các stub/dangling wire do addStripe/sroute tạo ra khi stripe extend tới boundary.
- Sau trim phải verify lại.

Report hiện tại:

```text
Begin Summary
    Found no problems or warnings.
End Summary
```

Kết luận:

- VDD/VSS special connectivity sạch sau trim.
- Power plan về mặt connectivity đã đi đúng hơn so với lỗi ban đầu chỉ thấy một net hoặc local SRAM PG không nối ra global ring.

## 16. Vì sao flow hiện tại hợp lý hơn cách vá trực tiếp trong GUI

Các lỗi trước đó trong GUI như:

- Chỉ thấy một đường VDD, không thấy VSS.
- Local SRAM PG không nối ra global ring.
- Power đi sai giữa SRAM và core.
- Global power đè lên SRAM island.

Không nên sửa bằng cách vẽ tay từng shape, vì sẽ khó lặp lại và dễ sai khi rerun. Flow hiện tại sửa ở mức script:

- Floorplan xác định rõ island và geometry.
- Power plan dùng biến geometry thay vì tọa độ đo bằng mắt.
- Mọi addStripe có `-area`, `-snap_wire_center_to_grid Grid`, width/spacing cố định.
- Mọi bước có report/guard để bắt lỗi.
- Main `innovus.tcl` source trực tiếp các file cần thiết.

Đây là cách đúng trong physical design: sửa rule và flow, không sửa hình bằng tay.

## 17. Những điểm đúng hiện tại

- SRAM được gom thành island 4x4 ở lower-left.
- Tọa độ SRAM được snap về grid.
- Flow mới sẽ xuất 8 macro `R0` và 8 macro `MY`, tất cả `fixed`; cần tạo lại report sau khi chạy lại macro floorplan.
- Gap ngang/dọc được validate đúng 4 row.
- Placement blockage bao phủ macro body và gap SRAM.
- Route blockage M6/M7 trên SRAM body đã được EGR nhận, log báo `#Routing Blockages : 32`; M5 vẫn là eGR resource hint.
- Global core ring dùng M8/M9.
- SRAM island reuse M9-left và M8-bottom global ring.
- Giữa SRAM có M4/M5 VDD/VSS collectors.
- Post-placement PG không tạo regular M8/M9 stripe lên SRAM island.
- `verifyConnectivity` sau trim báo clean cho VDD/VSS.

## 18. Những điểm còn nên theo dõi

### 18.1. Local-left edge coverage

`sram_island_pg_edges.rpt` hiện có một dòng `local_left VDD M5` coverage thấp hơn threshold. Vì PG connectivity tổng thể clean, đây chưa phải open PG, nhưng nếu làm slide nên ghi là điểm cần review GUI/DRC thêm.

### 18.2. CTS/postCTS chưa hoàn toàn sạch

Floorplan và power plan đã tốt hơn, nhưng CTS log vẫn có warning về placement overlap trong internal CCOpt check và sau postCTS có hiện tượng thêm rất nhiều hold buffers. Đây là vấn đề sau floorplan/power plan, cần phân tích timing constraint và CTS/hold strategy riêng.

### 18.3. Warning fake SRAM LEF

Warning `IMPPP-133` do SRAM LEF OBS V3 vượt boundary là đặc điểm của fake/generated SRAM abstraction. Không nên bỏ qua mọi DRC, nhưng cần phân loại rõ fake SRAM abstraction warning với lỗi PG/routing thật.

## 19. Câu chuyện trình bày slide đề xuất

Có thể trình bày theo 6 slide kỹ thuật:

1. **Vấn đề ban đầu**
   - SRAM island có power/routing nhìn sai trong GUI.
   - EGR trước đó không có route blockage cho SRAM body.
   - Local PG có lúc không nối rõ ra global ring.

2. **Floorplan strategy**
   - 16 SRAM thành island 4x4 lower-left.
   - Gap 4 row, border 2 row.
   - R0/MY xen kẽ theo cột để hai SRAM kề nhau đối xứng theo phương X.
   - Macro fixed sau placement.

3. **Macro placement implementation**
   - `dbGet` tìm SRAM.
   - Tính island width/height.
   - `placeInstance`, `snapFPlan`, `addHaloToBlock`.
   - Validate overlap/gap và ghi `sram_macro_final_map.rpt`.

4. **Power topology**
   - M8/M9 global ring.
   - Reuse left/bottom global ring cho SRAM.
   - M4/M5 local open ring và collectors giữa SRAM.
   - `sroute` nối SRAM block pins tới nearest stripe.

5. **Route/resource protection**
   - `createRouteBlk -exceptpgnet` trên M6/M7 SRAM body; không block M4/M5 pin-access/local PG.
   - `setRouteMode -earlyGlobalReverseDirection` theo cú pháp Innovus TCR.
   - Log sau sửa báo `#Routing Blockages : 32`.

6. **Verification và remaining issues**
   - `verifyConnectivity` VDD/VSS clean.
   - `checkPlace_after_place.rpt` clean sau placement.
   - Còn review local-left coverage và CTS/postCTS hold.

## 20. Kết luận

Logic floorplan và power plan hiện tại đi theo hướng physical-design có kiểm soát:

- Geometry không đo bằng mắt mà lấy từ database và report.
- SRAM placement không phụ thuộc hoàn toàn vào auto placer mà deterministic 4x4.
- Power không vẽ tràn lên SRAM mà chia rõ global ring, SRAM local collectors và standard-cell PG.
- Routing resource của SRAM được bảo vệ bằng route blockage đúng cú pháp Cadence.
- Mỗi giai đoạn quan trọng đều có report để chứng minh: final macro map, route guard report, SRAM PG edge report, checkPlace report và PG connectivity report.

Điểm quan trọng nhất để trình bày là: flow này không chỉ “làm cho GUI nhìn giống hình thầy”, mà đang mô hình hóa đúng vai trò vật lý của SRAM trong Innovus: macro cố định, có gap cho VDD/VSS, có PG topology phân cấp, có blockage bảo vệ routing resource, và có verification sau từng bước.
