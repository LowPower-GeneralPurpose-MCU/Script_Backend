# 1. C?u hình CPU 
set_multi_cpu_usage -localCpu 2
set load_netlist_ignore_undefined_cell true

# 2. Ð?nh nghia danh sách thu vi?n (.lib)
set ASAP7 "../tkvm/asap7"
set LIB "${ASAP7}/asap7sc7p5t_28/LIB/CCS"

set LIB_LIST [list \
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

# FIX: Truy?n tr?c ti?p danh sách file vào không c?n c? -timing
read_lib $LIB_LIST

# 3. Ð?c Netlist và thi?t l?p Top Module
read_verilog ./outputs/Mul32_pnr_sta.v
set_top_module Mul32

# 4. Nap file rang buoc
read_sdc ./outputs/Mul32_pnr.sdc
read_spef ./outputs/Mul32_quan.spef

# 5. C?p nh?t gi?i toán Timing toàn m?ch
update_timing -full

# 6. Xu?t báo cáo k?t qu? (Reports)
file mkdir rpt_tempus

report_timing -path_type full_clock -max_paths 50 -check_type setup > rpt_tempus/setup_timing_sta.rpt
report_timing -path_type full_clock -max_paths 50 -check_type hold > rpt_tempus/hold_timing_sta.rpt
report_analysis_coverage > rpt_tempus/analysis_coverage_sta.rpt
report_constraint -all_violators > rpt_tempus/all_violators_sta.rpt

exit