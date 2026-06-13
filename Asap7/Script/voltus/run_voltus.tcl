# =========================================================
# VOLTUS PURE STANDALONE SCRIPT (FIX TRI?T Ð?)
# M?ch: Mul32 | Ti?n trình: ASAP7 7nm
# =========================================================

set_multi_cpu_usage -localCpu 2

# 1. Ð?c LEF b?ng l?nh chu?n Voltus
read_lib -lef [list \
    "./saved/Mul32_pnr.enc.dat/libs/lef/asap7_tech_4x_201209.lef" \
    "./saved/Mul32_pnr.enc.dat/libs/lef/asap7sc7p5t_28_L_4x_220121a.lef" \
    "./saved/Mul32_pnr.enc.dat/libs/lef/asap7sc7p5t_28_R_4x_220121a.lef" \
    "./saved/Mul32_pnr.enc.dat/libs/lef/asap7sc7p5t_28_SL_4x_220121a.lef" \
    "./saved/Mul32_pnr.enc.dat/libs/lef/asap7sc7p5t_28_SRAM_4x_220121a.lef" \
]

# 2. Ð?c thu vi?n Liberty (.lib)
set ASAP7 "../tkvm/asap7"
set LIB "${ASAP7}/asap7sc7p5t_28/LIB/CCS"
read_lib [list \
    ${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib \
    ${LIB}/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib \
    ${LIB}/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib \
    ${LIB}/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib \
    ${LIB}/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib \
    ${LIB}/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib \
    ${LIB}/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib \
    ${LIB}/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib \
    ${LIB}/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib \
    ${LIB}/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib \
]

# 3. Ð?c Netlist và thi?t l?p Top Module (Trigger n?p toàn b? LEF/LIB vào core)
read_verilog ./outputs/Mul32_pnr_sta.v
set_top_module Mul32

# 4. Ð?c DEF (N?p Floorplan và dây d?n v?t lý - S? pass vì chua b? khóa timer)
read_def ./outputs/Mul32_pnr.def

# 5. Ð?c file Ràng bu?c (SDC) và Ký sinh (SPEF)
read_sdc ./outputs/Mul32_pnr.sdc
read_spef ./outputs/Mul32_quan.spef

# =========================================================
# PHÂN TÍCH CÔNG SU?T VÀ LU?I NGU?N
# =========================================================

# Bu?c 1: Tính toán Static Power
set_power_analysis_mode -method static -corner max -create_binary_db true
report_power -outfile ./reports/Mul32_static_power.rpt

# Bu?c 2: Kích ho?t Rail Analysis (ERA)
set_rail_analysis_mode \
    -method era_static \
    -accuracy hd \
    -enable_xp true \
    -em_temperature 110 \
    -extraction_tech_file "./saved/Mul32_pnr.enc.dat/libs/mmmc/rccorner/qrcTechFile_typ03_scaled4xV06"

# C?u hình di?n áp lu?i
set_pg_nets -net VDD -voltage 0.7 -threshold 0.65
set_pg_nets -net VSS -voltage 0.0 -threshold 0.05

# T? d?ng c?m di?m c?p ngu?n
set_power_pads -net VDD -auto_voltage_source_creation true
set_power_pads -net VSS -auto_voltage_source_creation true

# Th?c thi Engine gi?i quy?t s?t áp
analyze_rail -type net -output ./rail_results_VDD VDD
analyze_rail -type net -output ./rail_results_VSS VSS

puts "====================================================="
puts " VOLTUS RAIL ANALYSIS COMPLETED SUCCESSFULLY "
puts " Check reports in ./rail_results_VDD and VSS"
puts "====================================================="

exit