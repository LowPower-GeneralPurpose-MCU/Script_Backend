set ASAP7 "../tkvm/asap7"
set LIB "${ASAP7}/asap7sc7p5t_28/LIB/CCS"
set LIB_LIST [list ${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib ${LIB}/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib ${LIB}/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib ${LIB}/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib]

# Setting up system mode
set_system_mode setup

# 1. Read ASAP7 libraries (For BOTH versions as both are netlists)
read_library -liberty $LIB_LIST -both

# 2. Read the Golden design (Post-Synthesis Netlist)
read_design ./outputs/Mul32_syn.v -verilog -golden

# 3. Read the Revised design (Post-PnR Netlist)
read_design ./outputs/Mul32_pnr_lec.v -verilog -revised

# Specify Top Modules
set_root_module Mul32 -golden
set_root_module Mul32 -revised

# 4. Extremely important settings for Post-PnR
# Innovus inserts many buffers/inverters on the clock line; Conformal needs to be notified to skip them.
set_flatten_model -seq_constant
set_flatten_model -seq_constant_x_to 0
set_analyze_option -auto

# ---------------------------------------------------------
# 4. CHU?I L?NH HIERARCHICAL (THAY TH? CHO L?NH COMPARE THÔNG THU?NG)
# ---------------------------------------------------------
# B? qua system mode lec, d? tool t? vi?t m?t file k?ch b?n phân c?p
write_hier_compare_dofile hier_pnr.do -replace -usage -verbose \
    -balanced_extraction -input_output_pin_equivalence

# Kh?i ch?y file k?ch b?n v?a t?o b?ng engine Hierarchical
run_hier_compare hier_pnr.do -dynamic_hierarchy

# 5. Report
report_hier_compare_result -all -usage
report_verification -hier -verbose
