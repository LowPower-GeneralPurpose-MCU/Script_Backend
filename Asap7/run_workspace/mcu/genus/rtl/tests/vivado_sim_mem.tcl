#==============================================================================
# vivado_sim_mem.tcl - chay tb_mem_paths.sv trong project Vivado MCU_SOC_IOT
#==============================================================================
#
# TAI SAO CAN FILE NAY
#
# MCU_SOC_IOT.xpr KHONG chay duoc tb_mem_paths.sv nhu dang co, vi hai ly do doc
# lap nhau - sua mot cai van khong du:
#
#  1. Project chi co hai fileset mo phong: `sim_1` (SoC_testbench) va `sim_fw`
#     (tb_top_soc).  Ca file .xpr khong he nhac toi tb_mem_paths.sv, nen nhom
#     TS/TF/T9/T10 khong ton tai trong GUI.
#
#  2. RTL trong project la BAN SAO IMPORT, khong phai tham chieu toi repo.  Moi
#     <File> deu nam duoi $PSRCDIR/sources_1/imports/rtl/ voi mot ImportTime
#     rieng.  Sua file trong Script_Backend KHONG chay toi ban sao do.  Cac
#     ImportTime cua ban .xpr nay la 2026-09-03/04, tuc TRUOC ca store buffer
#     (P2, 2026-09-05) lan P2c - project dang giu mot D-cache khong co store
#     buffer, khong co gi de `fence` xa.
#
# Script nay sua ca hai: import lai toan bo RTL tu repo, roi tao fileset
# `sim_mem` va chay no.
#
# CACH CHAY
#
#   Vivado GUI -> Tcl Console, voi project da mo:
#       source <duong dan>/vivado_sim_mem.tcl
#
#   Hoac batch:
#       vivado -mode batch -source vivado_sim_mem.tcl \
#              -tclargs D:/GITHUB_PROJECT/MCU_SOC_IOT/MCU_SOC_IOT.xpr
#
# Ket qua can doc: cac dong [PASS]/[FAIL] cua nhom TF, T9 va T10, roi PASS COUNT /
# FAIL COUNT / TIMEOUTS o cuoi.  Mong doi 128/128 (121 truoc P2c + 7 cua TF).
#
# LUU Y: buoc import ghi de cac ban sao RTL trong project bang ban trong repo.
# Do la muc dich - nhung neu ban da sua tay RTL BEN TRONG project ma chua dua
# nguoc ve repo, hay sao luu truoc khi chay.
#==============================================================================

if {[llength $argv] > 0} {
    open_project [lindex $argv 0]
}

if {[catch {current_project} prj]} {
    error "Chua co project nao mo.  Mo MCU_SOC_IOT.xpr truoc, hoac truyen duong dan .xpr qua -tclargs."
}

set proj_dir [get_property DIRECTORY $prj]

# ---------------------------------------------------------------------------
# Tim repo.  Mac dinh suy ra tu chinh duong dan ImportPath cu trong .xpr:
#   <proj_dir>/../MCU_LowPower_GeneralPurpose/Script_Backend
# Neu bo tri cua ban khac, sua bien REPO ngay duoi day.
# ---------------------------------------------------------------------------
set REPO [file normalize "$proj_dir/../MCU_LowPower_GeneralPurpose/Script_Backend"]

set RTL   "$REPO/Asap7/run_workspace/mcu/genus/rtl"
set TESTS "$RTL/tests"

if {![file isdirectory $RTL]} {
    error "Khong thay RTL o $RTL.  Sua bien REPO trong script nay cho dung may ban."
}

puts "\[sim_mem\] project : $proj_dir"
puts "\[sim_mem\] repo    : $REPO"

# ---------------------------------------------------------------------------
# 1. Import lai RTL tu repo.
#
# Loai tru tests/ voi core.bak* - GIONG HET bo loc cua run_soc_sim.sh va cua
# filelist Genus.  Neu ba cho nay lech nhau thi mo hinh hanh vi cua hard macro
# bi nap hai lan, hoac mot file that bi bo sot.
# ---------------------------------------------------------------------------
set rtl_files {}
foreach f [glob -nocomplain -directory $RTL -types f *.v */*.v */*/*.v] {
    if {[string match "*/tests/*" $f] || [string match "*core.bak*" $f]} { continue }
    lappend rtl_files $f
}
# Header `include cua CLINT / DMA / PLIC - khong nam trong danh sach 58 file
# tong hop, nhung trinh bien dich van can chung.
foreach f [glob -nocomplain -directory $RTL -types f */*/*_defines.vh] {
    lappend rtl_files $f
}

# CO Y BO QUA: memory/boot_rom_image.vh va memory/boot.mem.
#
# boot_rom_image.vh trong .xpr mang co AutoDisabled = 1 (Vivado nhan ra no la
# header chi de `include, khong phai don vi bien dich).  Import lai se bat no
# thanh source va axi_rom bi elaborate hai lan.  Ca hai file deu la NOI DUNG
# BOOT ROM, ma tb_mem_paths thi cuop thang cong CPU va tu phat giao dich - no
# khong bao gio doc ROM.  De nguyen ban project dang co.

puts "\[sim_mem\] import lai [llength $rtl_files] file RTL ..."
import_files -force -fileset sources_1 $rtl_files
set_property top top_soc [get_filesets sources_1]

# ---------------------------------------------------------------------------
# 2. Fileset sim_mem.
#
# tb_mem_paths.sv duoc THEM BANG THAM CHIEU (add_files), khong import: testbench
# thay doi thuong xuyen hon RTL, va mot ban sao thu hai cua no chinh la cai bay
# da lam project nay chay RTL cu suot bon ngay.
# ---------------------------------------------------------------------------
if {[lsearch -exact [get_filesets -quiet *] sim_mem] >= 0} {
    delete_fileset -quiet [get_filesets sim_mem]
}
create_fileset -simset sim_mem

# Hai model macro, khop run_soc_sim.sh: 256x4x32 cho RAM / cache data / TCM,
# 128x4x20 cho tag cache (tu P2b).  Thieu model tag thi elaborate bao module
# `srambank_128x4x20_6t122` khong giai duoc.
add_files -fileset sim_mem -norecurse [list \
    "$TESTS/tb_mem_paths.sv" \
    "$TESTS/models/srambank_256x4x32_6t122.v" \
    "$TESTS/models/srambank_128x4x20_6t122.v"]

set_property top     tb_mem_paths   [get_filesets sim_mem]
set_property top_lib xil_defaultlib [get_filesets sim_mem]

# Duong include: khop `INC` trong run_soc_sim.sh.  Thieu mot cai la cac macro
# `SOC_IS_UNCACHED / `SOC_IS_ITCM khong giai duoc.
set src_rtl "$proj_dir/[file tail $prj].srcs/sources_1/imports/rtl"
set_property include_dirs [list \
    $src_rtl \
    "$src_rtl/interrupt/CLINT" \
    "$src_rtl/interrupt/dma" \
    "$src_rtl/interrupt/plic" \
    "$src_rtl/memory"] [get_filesets sim_mem]

# tb_mem_paths dung `force` tren tin hieu ben trong DUT.  Chay het la du - no tu
# goi $finish sau khi in bang diem.
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_mem]

# ---------------------------------------------------------------------------
# 3. Chay.
# ---------------------------------------------------------------------------
current_fileset -simset [get_filesets sim_mem]
launch_simulation -simset [get_filesets sim_mem] -mode behavioral

puts "\[sim_mem\] xong.  Doc log o:"
puts "\[sim_mem\]   $proj_dir/[file tail $prj].sim/sim_mem/behav/xsim/simulate.log"
