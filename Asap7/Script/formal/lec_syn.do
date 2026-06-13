set ASAP7 "../tkvm/asap7"
set LIB "${ASAP7}/asap7sc7p5t_28/LIB/CCS"
set LIB_LIST [list ${LIB}/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib ${LIB}/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib ${LIB}/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib ${LIB}/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib ${LIB}/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib]

# Setting up the setup mode
set_system_mode setup

# 1. Read libraries as soon as possible (Only for revisions as RTL doesn't use portable libraries)
read_library -liberty $LIB_LIST -revised

# 2. Read the Golden design (RTL)
read_design ./rtl/Mul32.v -verilog -golden

# 3. Read Revised Design (Netlist after synthesis)
read_design ./outputs/Mul32_netlist.v -verilog -revised

# Specify Top Module
set_root_module Mul32 -golden
set_root_module Mul32 -revised

# 4. Handle Undriven Signals
set_undriven_signal Z -golden

# (Optional) Run Genus-generated auxiliary script to map FSM/Data Path
# source genus_mapping_hints.do

# 5. Switch to comparison mode
set_system_mode lec
analyze_datapath -module -effort medium
add_compared_points -all
compare

# 6. Report
report_verification -compare_result
report_unmapped_points -summary
