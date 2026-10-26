REAd IMplementation Information fv/top_soc -golden fv_map -revised top_soc_synv -use_rtl_names
SET PARAllel Option -threads 1 -norelease_license
SET COmpare Options -threads 1
SET MUltiplier Implementation boothrca -both
SET UNDEfined Cell black_box -noascend -both
ADD NOtranslate Modules -library -both srambank_256x4x32_6t122 srambank_128x4x20_6t122
ADD SEarch Path /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LIB\
   -library -both
REAd LIbrary -liberty -both /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LIB/srambank_128x4x20_6t122.lib\
   /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LIB/srambank_256x4x32_6t122.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_AO_LVT_SS_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_AO_LVT_TT_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_AO_RVT_SS_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_AO_RVT_TT_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_INVBUF_LVT_SS_ccs_220122.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_INVBUF_LVT_TT_ccs_220122.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_INVBUF_RVT_SS_ccs_220122.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_INVBUF_RVT_TT_ccs_220122.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_OA_LVT_SS_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_OA_LVT_TT_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_OA_RVT_SS_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_OA_RVT_TT_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SEQ_LVT_SS_ccs_220123.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SEQ_LVT_TT_ccs_220123.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SEQ_RVT_SS_ccs_220123.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SEQ_RVT_TT_ccs_220123.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SIMPLE_LVT_SS_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SIMPLE_LVT_TT_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SIMPLE_RVT_SS_ccs_211120.lib\
   /home/user1/Desktop/asap7/asap7sc7p5t_28/LIB/CCS/asap7sc7p5t_SIMPLE_RVT_TT_ccs_211120.lib
REAd DEsign -verilog95 -golden -lastmod -noelab fv/top_soc/fv_map.v.gz
ELAborate DEsign -golden -root top_soc
REAd DEsign -verilog95 -revised -lastmod -noelab /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/genus/outputs/top_soc_syn.v
ELAborate DEsign -revised -root top_soc
WRIte DEsign -golden fv_map_top_soc_synv_db/elab.v -replace
REPort DEsign Data
REPort BLack Box
REPort MOdules
SET FLatten Model -seq_constant
SET FLatten Model -seq_constant_x_to 0
SET FLatten Model -hier_seq_merge
SET FLatten Model -gated_clock
ANAlyze EXtended Mapping fv/top_soc/fv_map.map.do fv/top_soc/top_soc_synv.map.do -output fv_map_top_soc_synv_1.map.do\
   -input_specification rtl-n1 rtl-n2 -output_specification n1-n2 -replace -verbose
SET MApping Method -mapping_file_nopipo
SET MApping Method -search_in_mapping_file
SET ANalyze Option -mapping_file fv_map_top_soc_synv_1.map.do
CHEck MApping Setup -mapping_file_quality -summary
CHEck VErification Information
