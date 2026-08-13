# Phan tich ky thuat SRAM Innovus flow den buoc CTS

Tai lieu nay tong hop cach script Tcl hien tai chay flow SRAM trong Innovus, giai thich cac lenh chinh, doi chieu voi log/report va tai lieu Cadence Innovus. Muc tieu la lam co so de trinh bay slide ve flow floorplan -> power plan -> pin assignment -> standard-cell placement -> CTS cho design `axi_ram` voi 16 SRAM macro ASAP7.

## 1. Nguon tham chieu

### 1.1. Script va report trong project

- Main one-command flow: `Asap7/run_workspace/sram_axi/innovus/tcl/innovus.tcl`
- Flow PnR staged: `Asap7/run_workspace/sram_axi/innovus/tcl/innovus_pnr.tcl`
- SRAM macro setup: `Asap7/run_workspace/sram_axi/innovus/tcl/sram_macro_setup.tcl`
- SRAM macro placement: `Asap7/run_workspace/sram_axi/innovus/tcl/sram_macro_floorplan.tcl`
- Finish/audit macro floorplan: `Asap7/run_workspace/sram_axi/innovus/tcl/finish_macroFP.tcl`
- Power plan top level: `Asap7/run_workspace/sram_axi/innovus/tcl/power_plan.tcl`
- SRAM island PG: `Asap7/run_workspace/sram_axi/innovus/tcl/sram_island_power.tcl`
- Route guard cho SRAM body: `Asap7/run_workspace/sram_axi/innovus/tcl/sram_route_guard.tcl`
- Current run log: `Asap7/run_workspace/sram_axi/innovus/innovus.log`
- SRAM final placement report: `Asap7/run_workspace/sram_axi/innovus/reports/sram_macro_final_map.rpt`
- SRAM route guard report: `Asap7/run_workspace/sram_axi/innovus/reports/sram_route_guard.rpt`
- SRAM PG edge report: `Asap7/run_workspace/sram_axi/innovus/reports/sram_island_pg_edges.rpt`
- Placement report after place: `Asap7/run_workspace/sram_axi/innovus/verify_rpt/checkPlace_after_place.rpt`
- PG connectivity report after trim: `Asap7/run_workspace/sram_axi/innovus/verify_rpt/pg_connectivity_after_trim.rpt`

### 1.2. Tai lieu duoc dung de doi chieu

- `D:/download/10_Macro.pdf`
  - Macro la block lon, power-hungry, thuong dat o boundary.
  - SRAM co the block routing toi M4/M5.
  - Macro gap can du de co it nhat mot cap VDD/VSS.
  - Macro pins nen quay ve phia core.
  - Macro chi nen dung R0/R180, sau khi dat xong phai set `FIXED`.
- `D:/download/x_Hierarchy Layout.pdf`
  - SRAM cung module nen gom thanh group.
  - SRAM group nen o corner/side.
  - Gap SRAM minh hoa la 4 row.
  - Sau khi dat SRAM phai chay power grid de power line di giua cac SRAM.
  - Top-level pins can duoc declare/spread deu tren cac canh.
- `D:/Subject/DocCadence/innovus_doc/innovus_doc/innovusTCR/innovusTCR.pdf`
  - `createRouteBlk -box ... -layer ... -exceptpgnet`: tao routing blockage cho signal nets, nhung khong chan power/ground special routing.
  - `setRouteMode -earlyGlobalReverseDirection "... M5:M5 ..."`: dung cho early global route de reserve/reverse direction resource trong vung chi dinh.
  - `set_interactive_constraint_modes [all_constraint_modes -active]` truoc `set_propagated_clock [all_clocks]` khi gan constraint tuong tac sau CTS.
  - `checkPlace ./file.rpt`: doi so file truc tiep la report file, khong phai `-outFile`.
- `D:/Subject/DocCadence/innovus_doc/innovus_doc/innovusUG/innovusUG.pdf`
  - Truoc optimization/CTS nen dung halo, placement obstruction, fence/blockage quanh hard block.
  - Neu thay bad routing over macros, can them blockage hoac sua floorplan.
  - Early global route dung de phan tich congestion/timing, va routing blockage co tac dung trong uoc luong resource.
- `D:/download/asap7_drm_201207a.pdf`
  - Dung de giu cach chon layer/width/track theo ASAP7, dac biet M4/M5 local SRAM collector va M8/M9 upper/global PG.

## 2. Tong quan flow den CTS

Flow chinh khi chay:

```tcl
innovus -stylus -files tcl/innovus.tcl
```

Thu tu trong `innovus.tcl`:

1. Init MMMC/library/design.
2. Tao hierarchy floorplan.
3. Dat SRAM macro thanh island 4x4.
4. Audit SRAM: count, orient, status.
5. Tao route guard cho SRAM body.
6. Tao power plan va SRAM island PG.
7. Dat top-level pins.
8. Standard-cell placement.
9. Tao post-placement PG mesh/tap cho standard cell.
10. Verify PG connectivity.
11. CTS bang `clock_opt_design`.
12. Set propagated clocks.
13. Chay postCTS optimization.

Tai lieu nay tap trung den buoc CTS. Buoc postCTS duoc nhac toi vi log hien tai van co mot van de lon sau CTS: hold fixing them qua nhieu cell.

## 3. SRAM macro setup va placement

### 3.1. SRAM setup

Trong `sram_macro_setup.tcl`, SRAM duoc khai bao:

```tcl
set SRAM_MASTER "srambank_256x4x32_6t122"
set SRAM_ROWS 4
set SRAM_COLS 4
set SRAM_COUNT [expr {$SRAM_ROWS * $SRAM_COLS}]
set SRAM_MACRO_GAP_ROWS 4
```

Y nghia:

- `SRAM_ROWS=4`, `SRAM_COLS=4` tao 16 macro thanh mot SRAM island.
- `SRAM_MACRO_GAP_ROWS=4` tao gap 4 standard-cell rows giua macro. Day khop voi slide hierarchy layout: gap SRAM minh hoa la 4 row.
- `SRAM_MASTER` giup script tim dung 16 instances SRAM trong database Innovus bang `dbGet -p2 top.insts.cell.name $SRAM_MASTER`.

Tai sao lam nhu vay:

- Theo `10_Macro.pdf`, SRAM chia se address/data nen nen cluster cung nhau.
- Theo `x_Hierarchy Layout.pdf`, module co SRAM nen dat gan corner/side va SRAM cung module nen gom cung group.
- Dung deterministic 4x4 island de tranh ket qua macro placer tu dong dat SRAM khong deu, tao notch/channel nho.

### 3.2. Dat SRAM macro island

Trong `sram_macro_floorplan.tcl`, script:

- Tim tat ca SRAM instance theo master.
- Sap xep theo bank index.
- Tinh kich thuoc macro tu database:

```tcl
set SRAM_W [dbGet $first_ptr.cell.size_x]
set SRAM_H [dbGet $first_ptr.cell.size_y]
```

- Tinh array width/height:

```tcl
set SRAM_ARRAY_W [expr {
    $SRAM_COLS * $SRAM_W +
    ($SRAM_COLS - 1) * $SRAM_MACRO_GAP_X
}]
```

- Snap toa do ve grid bang `sram_snap_to_grid`.
- Dat macro bang `placeInstance`.
- Cuoi flow, `finish_macroFP.tcl` audit orient/status.

Report `sram_macro_final_map.rpt` cho thay:

- 16 SRAM deu co `orient R180`.
- 16 SRAM deu co `status fixed`.
- Island nam o lower-left, tu gan `(2.16, 2.16)` toi `(500.688, 706.32)`.

Tai sao dung R180:

- Slide Macro priority 8 noi chi nen dung R0/R180. Khong dung R90/R270 vi macro co huong poly/PG internal rieng.
- Trong design nay, SRAM signal pins nam gan local bottom edge; R180 giup huong pin ve core/logic side dung hon.

Tai sao set fixed:

- Slide Macro priority 9 yeu cau sau khi dat macro thi set `FIXED`.
- Neu khong fixed, `place_opt_design`, CTS, hoac opt co the move macro, pha gap SRAM va PG topology.

## 4. Power plan va SRAM island PG

### 4.1. Top-level core ring M8/M9

Flow power plan chinh nam trong `power_plan.tcl`. Y tuong:

- Dung M8 cho horizontal global ring.
- Dung M9 cho vertical global ring.
- Tao ring rieng cho VDD va VSS thay vi mot call hai net de tranh tool chi tao/thay ro mot net trong GUI.
- Kiem tra ring sau khi tao bang guard function.

Ly do:

- M8/M9 la upper metal, phu hop di power global dai va it anh huong den M1-M5 cua standard-cell/local macro.
- Thay ban di project khac bang upper global ring va local SRAM ring/stripe. Voi ASAP7, dung M8/M9 ngoai cung la hop ly hon dung M4/M5 cho toan bo core ring.

### 4.2. SRAM island local PG

Script `sram_island_power.tcl` dung topology:

1. Reuse global M9-left va M8-bottom edge o canh sat SRAM island.
2. Khong ve lai duplicate closed local ring o canh left/bottom vi da co global ring gan island.
3. Tao open local ring:
   - M4 horizontal tren canh top exposed cua island.
   - M5 vertical tren canh right exposed cua island.
4. Tao M5 transition spine o canh left de noi M4 row collectors len stack M5/M8.
5. Tao M4 row-gap collector trong moi gap hang SRAM.
6. Tao M5 column-gap collector trong moi gap cot SRAM.
7. Dung `sroute -connect blockPin -blockPinLayerRange {M4 M4} -blockPinTarget stripe -allowJogging 0` de noi SRAM M4 VDD/VSS rail ports toi collector stripe gan nhat.
8. `editTrim -nets {VSS VDD}` de cat stub/dangling PG shapes.

Tai sao dung M4/M5 giua SRAM:

- `10_Macro.pdf` noi gap giua macro can it nhat mot cap VDD/VSS.
- Slide `x_Hierarchy Layout.pdf` noi power line phai di giua SRAMs.
- M4/M5 la local metal phu hop cho SRAM collector trong island; M8/M9 danh cho global ring/mesh.

Tai sao khong dung `-allowJogging` va `-allowLayerChange` trong `sroute`:

- Flow tham khao cua thay khong dung hai option nay cho SRAM island.
- Khi connect SRAM block pins, muc tieu la noi thang toi collector/ring co san, khong de tool tu jog/layer-change lung tung tao hinh kho kiem soat.
- Script chi dung stacked via options trong `setAddStripeMode` de kiem soat via stack M4->M5 hoac M5->M8.

### 4.3. Evidence tu report/log

`pg_connectivity_after_trim.rpt` hien tai:

```text
Begin Summary
    Found no problems or warnings.
End Summary
```

Dieu nay chung minh special-route connectivity cua VDD/VSS sau trim da sach.

`sram_island_pg_edges.rpt` hien tai cho thay:

- `reused_left` co VSS/VDD tren M9.
- `reused_bottom` co VSS/VDD tren M8.
- `local_top` co VSS/VDD tren M4.
- `local_right` co VSS/VDD tren M5.

Co mot diem can theo doi:

```text
local_left VDD M5 coverage=530.400 required=531.360
```

Nhung PG connectivity sau trim van clean. Nghia la day la edge-coverage guard hoi chat cho hinh local-left transition, khong phai open VDD/VSS thuc su. Neu can lam slide, nen noi: "Connectivity signoff local PG clean, nhung local-left transition coverage margin can review them bang GUI/DRC."

## 5. Pin assignment

Sau power plan, `innovus.tcl` chay:

```tcl
setPinConstraint -corner_to_pin_distance 8
source ./tcl/pins.tcl
```

Trong log hien tai, `editPin` spread pin nhu sau:

- TOP: 70 pins tren M7.
- RIGHT: 48 pins tren M6.
- LEFT: 68 pins tren M6.
- BOTTOM: 42 pins tren M7.

Y nghia:

- Top/bottom dung M7 vi la horizontal pin layer.
- Left/right dung M6 vi la vertical pin layer.
- Pins duoc spread tren 4 canh, khop voi yeu cau slide hierarchy layout: declare va spread pins deu tren boundary.

Warning can biet:

```text
IMPPTN-3837: setPinConstraint without specifying top-cell name will be obsolete
```

Day la compatibility warning, khong lam flow sai hien tai. Co the sua sau bang cach them top-cell name neu muon future-proof.

## 6. SRAM route guard truoc placement/CTS

### 6.1. Van de trong log cu

Trong log truoc do, early global route lap lai:

```text
[NR-eGR] #Routing Blockages  : 0
```

Hau qua:

- Innovus khong biet SRAM body phai bi han che routing tren M4/M5.
- Signal/clock co the bi uoc luong/chay len SRAM area.
- GUI nhin nhu routing/clock net di de len SRAM, khong giong flow thay.

### 6.2. Cach sua trong `sram_route_guard.tcl`

Script moi:

```tcl
set SRAM_ROUTE_GUARD_LAYERS {M4 M5}
set SRAM_ROUTE_GUARD_EGR_LAYER M5

createRouteBlk \
    -name $guard_name \
    -box [list $llx $lly $urx $ury] \
    -layer $SRAM_ROUTE_GUARD_LAYERS \
    -exceptpgnet

setRouteMode \
    -earlyGlobalReverseDirection $sram_egr_reverse_regions
```

Tai sao dung `createRouteBlk -exceptpgnet`:

- Theo Innovus TCR, `-exceptpgnet` block signal routing nhung khong block power/ground special routes.
- Dieu nay dung voi SRAM: khong muon signal/clock di tren SRAM body, nhung van phai cho VDD/VSS collector/ring duoc ket noi.

Tai sao block M4/M5:

- `10_Macro.pdf` noi mot so SRAM block routing toi M4/M5.
- SRAM local collectors cua script cung dang dung M4/M5. Neu signal/clock tu do chiem M4/M5 tren SRAM body, routing se nhiu va pin access xau.
- Khong block M8/M9 de global PG/top routing van co tai nguyen cao hon neu can.

Tai sao them `setRouteMode -earlyGlobalReverseDirection`:

- Hinh code cua thay dung y tuong reverse-direction/route resource reservation tren SRAM.
- Trong Innovus TCR ban 23.14, option dung la `-earlyGlobalReverseDirection`.
- Lenh nay tac dong vao early global route estimation, giup global placer/CTS nhin dung congestion/resource tren SRAM area.

### 6.3. Evidence sau khi sua

Trong log moi:

```text
innovus.log:2273 [NR-eGR] #Routing Blockages  : 32
innovus.log:2398 [NR-eGR] #Routing Blockages  : 32
innovus.log:6204 [NR-eGR] #Routing Blockages  : 32
innovus.log:11109 [NR-eGR] #Routing Blockages  : 32
```

So 32 hop ly vi:

- 16 SRAM macro.
- Moi macro co blockage tren 2 layer M4/M5.
- Tong blockage objects theo layer = 16 x 2 = 32.

`sram_route_guard.rpt` ghi ro tung SRAM:

```text
u_mem/G_SRAM_BANK[0].u_sram ... {M4 M5} M5 fixed
...
u_mem/G_SRAM_BANK[15].u_sram ... {M4 M5} M5 fixed
```

Day la bang chung de dua vao slide: route guard da duoc Innovus doc vao EGR/CTS.

## 7. Standard-cell placement

Trong `innovus.tcl`, placement section:

```tcl
setPlaceMode -reset
setPlaceMode \
    -place_global_uniform_density true \
    -place_global_module_aware_spare true \
    -place_global_auto_blockage_in_channel soft \
    -place_detail_preroute_as_obs {2 3} \
    -place_global_cong_effort high \
    -place_design_refine_macro false

place_opt_design
refinePlace
checkPlace ./verify_rpt/checkPlace_after_place.rpt
```

Giai thich:

- `place_global_uniform_density true`: trai cell deu hon, tranh dung cuc bo sat SRAM island.
- `place_global_auto_blockage_in_channel soft`: channel nho/canh macro duoc tool xem nhu blockage mem, giam nguy co nhai cell vao khe kho route.
- `place_detail_preroute_as_obs {2 3}`: coi preroute layers 2/3 nhu obstruction trong detail placement, tranh stdcell dung vao PG/pre-route gan macro.
- `place_design_refine_macro false`: khong de placement refine lai macro da fixed.
- `refinePlace`: legalize stdcell sau placement.
- `checkPlace ./verify_rpt/checkPlace_after_place.rpt`: tao report placement chi tiet theo dung syntax Innovus TCR.

Evidence:

`checkPlace_after_place.rpt` hien tai:

```text
## No violations found ##
Number of Placed Instances = 1703
of which 16 are fixed.
Number of Unplaced Instances = 0
Placement Density:0.47%
```

Nghia la sau standard-cell placement, placement clean.

Luu y:

Trong CTS log van co:

```text
Overlapping with other instance: 445
IMPCCOPT-2030 Found placement violations
```

Dieu nay xuat hien trong internal checkPlace cua CCOpt sau preCTS/place_opt stage, khong phai report sau placement ban dau. Can debug tiep o giai doan CTS/postCTS, co the lien quan cell CTS/hold buffer chen vao vung bi han che hoac fence/overlap voi SRAM island/core region.

## 8. Post-placement PG cho standard cell

Sau placement, script tao PG mesh/tap bo sung:

```tcl
source ./tcl/global_upper_pg_to_ring.tcl
source ./tcl/core_lower_pg_nojog.tcl

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

Giai thich:

- Standard cell M1 rails chi co y nghia sau placement vi luc do rows/cells da nam trong core.
- `global_upper_pg_to_ring.tcl` tao upper PG mesh/tap M8/M9 o vung logic ngoai SRAM island.
- `core_lower_pg_nojog.tcl` tao tap lower PG de M1 rails/logic PG ket noi len upper ring/mesh.
- `verifyConnectivity -type special -net {VDD VSS}` chi check PG nets, tranh warning signal IO chua route.
- `editTrim` cat cac dangling special wires.

Evidence:

`pg_connectivity_after_trim.rpt`:

```text
Found no problems or warnings.
```

Day la bang chung PG special connectivity clean truoc khi luu placed checkpoint va truoc CTS.

## 9. CTS flow

### 9.1. Clock route type

CTS setup trong `innovus.tcl`:

```tcl
create_route_type \
    -name leaf_rule \
    -bottom_preferred_layer M2 \
    -top_preferred_layer M3

create_route_type \
    -name trunk_rule \
    -shield_net VSS \
    -bottom_preferred_layer M4 \
    -top_preferred_layer M5

create_route_type \
    -name top_rule \
    -shield_net VSS \
    -bottom_preferred_layer M6 \
    -top_preferred_layer M7

set_ccopt_property -net_type leaf  route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top   route_type top_rule
set_ccopt_property buffer_cells $BUFCells
set_ccopt_property inverter_cells $INVCells
```

Y nghia:

- Leaf clock dung M2/M3 gan standard cell pins.
- Trunk clock dung M4/M5 va shield VSS de giam noise/crosstalk.
- Top clock dung M6/M7 cho route dai hon.
- SRAM route guard da chan signal/clock tren SRAM body M4/M5, nen CTS khong nen xem SRAM body la resource rong cho trunk.

### 9.2. Chay preCTS opt va CTS

```tcl
optDesign -prefix preCTS -preCTS
clock_opt_design
```

Log moi:

```text
innovus.log:6046 <CMD> clock_opt_design
innovus.log:6177 *** CTS #1 [begin]
innovus.log:9652 *** CTS #1 [finish]
```

CTS hoan tat, nhung con warning slew tai SRAM clock pins:

```text
Clock tree CLK has 3 slew violations.
u_mem/G_SRAM_BANK[9].u_sram/clk target 0.046ns achieved 0.070ns
u_mem/G_SRAM_BANK[8].u_sram/clk target 0.046ns achieved 0.064ns
u_mem/G_SRAM_BANK[10].u_sram/clk target 0.046ns achieved 0.046ns
```

Nhan xet:

- So violation giam tu 4 trong log cu xuong 3 trong log moi.
- Worst slew giam tu khoang 0.108ns trong log cu xuong 0.070ns trong log moi.
- Route guard giup CTS nhin SRAM resource dung hon, nhung constraint target 0.046ns rat chat voi SRAM macro clock pins va ASAP7 buffer set hien tai.

### 9.3. `set_propagated_clock` dung syntax Cadence

Loi cu:

```text
set_propagated_clock [all_clocks]
TCLCMD-1048: constraints are specified but no constraint mode is enabled interactively
```

Script da sua thanh:

```tcl
proc apply_post_cts_propagated_clocks {} {
    set active_constraint_modes [all_constraint_modes -active]

    if {[catch {
        set_interactive_constraint_modes $active_constraint_modes
        set_propagated_clock [all_clocks]
    } propagated_clock_setup_error]} {
        catch {set_interactive_constraint_modes {}}
        return -code error $propagated_clock_setup_error
    }

    set_interactive_constraint_modes {}
}

if {[catch {apply_post_cts_propagated_clocks} propagated_clock_error]} {
    puts stderr "Post-CTS propagated-clock setup failed: $propagated_clock_error"
    return -code error $propagated_clock_error
}
```

Tai sao dung nhu vay:

- Innovus TCR dua vi du dung `set_interactive_constraint_modes [all_constraint_modes -active]` truoc khi apply timing constraint tuong tac.
- Neu `set_propagated_clock` loi, script dung bang `return -code error` thay vi tiep tuc tao ket qua sai.
- Sau khi gan xong, clear lai bang `set_interactive_constraint_modes {}` de khong de side effect cho cac buoc sau.

Evidence log moi:

```text
innovus.log:11453 <CMD> all_constraint_modes -active
innovus.log:11454 mode_normal
innovus.log:11455 <CMD> set_interactive_constraint_modes $active_constraint_modes
innovus.log:11456 <CMD> set_propagated_clock [all_clocks]
innovus.log:11457 <CMD> set_interactive_constraint_modes {}
```

Khong con `TCLCMD-1048` o log moi.

## 10. So sanh voi flow tham khao cua thay

### 10.1. Diem giong

Flow thay:

```tcl
setHierMode -optStage preCTS
setPlaceMode -place_opt_run_global_place seed
...
setRouteMode -earlyGlobalRouteReversedirection $boxes
place_design
...
optDesign -prefix preCTS -preCTS
create_ccopt_clock_tree_spec -filename ccopt.spec
source ccopt.spec
ccopt_design -prefix postCTS
optDesign -prefix postCTS -postCTS -setup -hold
```

Flow hien tai:

- Cung dat SRAM thanh group/island.
- Cung co y tuong reserve routing resource tren SRAM truoc placement/CTS.
- Cung chay preCTS opt truoc CTS.
- Cung chay CTS truoc propagated clock/postCTS.

### 10.2. Diem khac co chu dich

1. Lenh route guard:
   - Flow thay trong anh dung option cu/sai capitalization: `-earlyGlobalRouteReversedirection`.
   - Innovus TCR 23.14 dung option: `-earlyGlobalReverseDirection`.
   - Script hien tai dung syntax theo doc Cadence de tranh sai version.

2. Them `createRouteBlk -exceptpgnet`:
   - Flow thay chi minh hoa reverse-direction.
   - Với ASAP7 SRAM fake LEF/report hien tai, EGR truoc do bao `#Routing Blockages : 0`, nen reverse-direction mot minh chua du ro rang.
   - `createRouteBlk -exceptpgnet` la cach Cadence document de block signal nhung khong chan PG.

3. CTS command:
   - Flow thay dung `ccopt_design`.
   - Script hien tai dung `clock_opt_design` va comment rang tranh loi `IMPCCOPT-2048` khi flow nay da co clock tree defined.
   - Trong Innovus moi, `clock_opt_design` la super command co the tu tao/use CCOpt spec va chay CTS.

4. `set_propagated_clock`:
   - Flow cu goi truc tiep co the chay duoc o version/mode khac.
   - Innovus 23.14 log cua minh yeu cau interactive constraint mode, nen script phai boc bang `set_interactive_constraint_modes`.

## 11. Cac warning/lau dai can giai thich tren slide

### 11.1. Warning library units

Log co:

```text
IMPTS-16: inconsistency in timing library time units
IMPTS-17: inconsistency in capacitance units
```

Nhan xet:

- Day la canh bao unit giua Liberty views.
- Khong truc tiep gay routing over SRAM.
- Nen fix bang cach thong nhat Liberty/setup view hoac dung `setLibraryUnit` neu flow Cadence yeu cau.

### 11.2. Unsupported `set_units` trong SDC

Log:

```text
TCLCMD-1461: Skipped unsupported command: set_units
```

Nhan xet:

- Innovus bo qua `set_units` trong SDC.
- Khong lam PG sai, nhung co the anh huong cach doc/rang buoc timing neu SDC dua vao unit command.
- Nen review `outputs/axi_ram_syn.sdc`.

### 11.3. SRAM fake LEF/OBS warnings

Log co nhieu:

```text
IMPPP-133: block boundary of SRAM instance was increased because OBS on V3 was outside original boundary
```

Nhan xet:

- Day lien quan fake/generated SRAM LEF co OBS/pin hinh hoc nam lech boundary.
- Slide hierarchy cung noi co the co DRC lien quan fake SRAM layouts.
- Khong nen bo qua moi loi routing, nhung warning fake SRAM OBS can phan loai rieng voi real PG connectivity.

### 11.4. CTS placement warning

Log moi:

```text
Overlapping with other instance: 445
IMPCCOPT-2030 Found placement violations
```

Nhan xet:

- `checkPlace_after_place.rpt` truoc CTS sach.
- Warning xuat hien trong CCOpt internal check sau khi preCTS/CTS them/move cell.
- Can them buoc report sau preCTS/CTS de biet instance nao overlap.
- Day la van de can debug tiep sau khi da co route guard.

### 11.5. PostCTS hold buffer explosion

Log moi:

```text
Added a total of 335809 cells to fix/reduce hold violation
density=76.242%
```

Nhan xet:

- Day khong hop ly voi design co khoang 1.7k placed instances truoc placement.
- Root cause co the den tu timing constraints/clock latency/hold constraints qua chat hoac bad clock/data modeling sau propagated clock.
- Day la van de sau CTS/postCTS, nen tren slide nen tach thanh "remaining issue after CTS", khong tron voi route guard/PG.

## 12. Ket luan ky thuat den CTS

### 12.1. Nhung diem da dung

- SRAM da dat thanh island 4x4 lower-left, macro fixed, orient R180.
- Gap SRAM theo 4-row rule, co local M4/M5 PG collectors giua macro.
- Core global ring dung M8/M9, SRAM island reuse M9-left/M8-bottom thay vi ve duplicate ring.
- VDD/VSS PG connectivity sau trim clean.
- Top-level pins spread tren 4 canh.
- Route guard M4/M5 tren SRAM body da duoc Innovus EGR nhan: `#Routing Blockages : 32`.
- `set_propagated_clock` da dung syntax Cadence 23.14 voi interactive constraint mode.

### 12.2. Nhung diem can tiep tuc sua sau CTS

- CTS con 3 max-transition/slew violations tai SRAM clock pins.
- CCOpt internal checkPlace con overlap warning.
- PostCTS hold fixing them 335k cells, can xem lai constraints/postCTS hold strategy truoc khi route.

### 12.3. Thong diep slide nen nhan manh

Mot SRAM physical-design flow dung khong chi la "dat macro va ve power". Can co 4 lop bao ve:

1. Macro placement rule: group, boundary/corner, R0/R180, fixed.
2. Power topology: M8/M9 global, M4/M5 local SRAM collectors, VDD/VSS pair trong gap.
3. Routing resource model: `createRouteBlk -exceptpgnet` va `setRouteMode -earlyGlobalReverseDirection`.
4. Timing/CTS correctness: route type, clock cells, propagated clock dung constraint mode, report CTS warnings rieng.

Neu thieu lop 3, Innovus co the route/estimate signal/clock len SRAM body. Neu thieu lop 4, postCTS co the tao ket qua nhin "day cell/day routing" ma khong con y nghia physical.
