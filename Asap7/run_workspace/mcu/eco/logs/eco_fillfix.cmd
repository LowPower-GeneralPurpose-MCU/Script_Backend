#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Wed Oct 14 00:15:37 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v23.14-s088_1 (64bit) 02/28/2025 12:25 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 23.14-s088_1 NR250219-0822/23_14-UB (database version 18.20.661) {superthreading v2.20}
#@(#)CDS: AAE 23.14-s018 (64bit) 02/28/2025 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 23.14-s036_1 () Feb 22 2025 01:17:26 ( )
#@(#)CDS: SYNTECH 23.14-s010_1 () Feb 19 2025 23:56:49 ( )
#@(#)CDS: CPE v23.14-s082
#@(#)CDS: IQuantus/TQuantus 23.1.1-s336 (64bit) Mon Jan 20 22:11:00 PST 2025 (Linux 3.10.0-693.el7.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
getVersion
getVersion
restoreDesign ./saved/top_soc_postRoute_eco.enc.dat top_soc
setMultiCpuUsage -acquireLicense 1 -localCpu 1
setDistributeHost -local
set_timing_derate -delay_corner $corner $side -cell_delay -cell_check  $factor $sram_insts
set_timing_derate -delay_corner $corner $side -cell_delay -cell_check  $factor $sram_insts
set_timing_derate -delay_corner dc_ff -early -cell_delay  $factor $lib_cells
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
set_dont_touch [get_cells [dbGet $ro_ptr.name]] true
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
timeDesign -postRoute -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_fillfix -prefix r0
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
setEcoMode -batchMode true -refinePlace false -updateTiming false
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[7]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[15]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN3306_pad_oe_12 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7792_mem_rdata_25 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7788_mem_rdata_29 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN9181_wdata_hold_8 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_252 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7830_mem_rdata_19 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RID_i[3][7]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RID_i[3][7]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[14]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[13]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {sdram_dqm[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8326_mem_wdata_1 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -term u_axi_ram_lo/u_mem/FE_OFC6564_mem_wdata_1/A -cell BUFx10_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN24269_mem_rdata_30 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7791_mem_rdata_26 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7846_mem_rdata_3 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_itcm/u_mem/n_30 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/n_92 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wstrb_hold[3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wstrb_hold[3]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_12955 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_12955 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RID_i[3][8]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RID_i[3][8]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/FE_OFN8743_data_write_word_24 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7839_mem_rdata_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7242 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7242 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN6583_n_541 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_DBTN7_s3_arready -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_DBTN7_s3_arready -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN7751_n_14539 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7837_mem_rdata_12 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7786_mem_rdata_31 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7842_mem_rdata_7 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/FE_OFN8809_data_write_word_6 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7840_mem_rdata_9 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wstrb_hold[2]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wstrb_hold[2]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_4840 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RLAST_i[3][1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/FE_OFN8807_data_write_word_7 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {dbg_reg_read_data[7]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {dbg_reg_read_data[7]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[5]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[5]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3127 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3127 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_i2c/n_331 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_331 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_PHN25477_ex_mem_csr_write_data_19 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_PHN25477_ex_mem_csr_write_data_19 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8226_mem_wdata_22 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8226_mem_wdata_22 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7789_mem_rdata_28 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN22314_SA_GEN_0_genblk1_slave_arbitration_ARID_valid_nxt_6 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN22314_SA_GEN_0_genblk1_slave_arbitration_ARID_valid_nxt_6 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_96 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_96 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9512 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9512 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_dcache/data_write_word[20]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/n_84 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN25384_n_5108 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN25384_n_5108 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7845_mem_rdata_4 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5062 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5062 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7848_mem_rdata_1 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14352 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4488 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim0_cnt[11]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim0_cnt[11]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7834_mem_rdata_15 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14564 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN2959_mem_addr_11 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7838_mem_rdata_11 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2760_n_9973 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2760_n_9973 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_682 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_682 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7795_mem_rdata_22 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5256_FE_DBTN202_n_26232 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5256_FE_DBTN202_n_26232 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][3]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_tim0_cnt[22]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim0_cnt[22]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7841_mem_rdata_8 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN2308_n_8984 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN2308_n_8984 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {cpu_inst_addr[2]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {cpu_inst_addr[2]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_ram_lo/mem_addr[6]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8074_mem_wdata_21 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN6081_n_15458 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN6081_n_15458 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_itcm/u_mem/n_71 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_syscon/n_129 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1585_sdram_addr_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1438 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1438 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_4500 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_4500 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_63 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_63 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_23023 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_23023 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_R_channel/slv_skid_buffer_BWD_REGISTERED.rd_ptr[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_R_channel/slv_skid_buffer_BWD_REGISTERED.rd_ptr[0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN391_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN391_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/n_286 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN9115_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7793_mem_rdata_24 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7802_mem_rdata_15 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7802_mem_rdata_15 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_5279 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_5279 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_252} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_252} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_i2c/n_584 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_584 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_793 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_793 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_tim1_cnt[13]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim1_cnt[13]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_843 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_843 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_6804 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_6804 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN939_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN939_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/n_243 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_3804 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_3804 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_34 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_34 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9137 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9137 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_rom/n_293 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_rom/n_293 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_25972 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_25972 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_10024 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_10024 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9401 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9401 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN6072_n_15429 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN6072_n_15429 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7796_mem_rdata_21 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_12959 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_12959 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_B_channel/n_103} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_B_channel/n_103} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_17715 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17715 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2101 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2101 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9164 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9164 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[0].dispatcher_read_channel_R_channel_SLV_FIFO[2].fifo_rdata_n_31} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_6767 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_6767 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_13887 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_13887 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14498 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN5583_n_6542 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN5583_n_6542 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_10648 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_10648 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8164_mem_wdata_1 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/FE_OFN7532_m0_araddr_12 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_19289 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_279 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_114 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_114 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_431} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_431} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_751 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_751 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_48 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_48 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8286_mem_wdata_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7847_mem_rdata_2 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_24501 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_21275 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_21275 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN423_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN3144_FE_DBTN107_n_385 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN3144_FE_DBTN107_n_385 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clic/lvl_q[25][0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[25][0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5842 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5842 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2708 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2708 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pwdata_0[26]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {pwdata_0[26]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN9025_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_25} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_25} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5485 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5485 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_816 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_816 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net dc_rready -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net dc_rready -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN781_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN781_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1965 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1965 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_271 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_271 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_12198 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_12198 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN3679_mem_addr_8 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_8323 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_8323 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/EX_gen_muldiv.MUL_counter[5]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/EX_gen_muldiv.MUL_counter[5]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN142_n_26292 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN142_n_26292 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2071 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2071 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[26]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[26]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_i2c/n_242 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_242 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/trap_enter -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/trap_enter -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN2276_n_6981 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN2276_n_6981 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_13691 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_13691 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_R_channel/n_471} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_R_channel/n_471} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_753 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_753 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pwdata_0[24]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {pwdata_0[24]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8142_mem_wdata_6 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_17247 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_17247 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1442 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1442 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_1026 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1026 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4743 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8242_mem_wdata_20 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_93 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14766 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14766 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN5984_n_7147 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5984_n_7147 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1960 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1960 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[28]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[28]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_DBTN302_n_9930 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_DBTN302_n_9930 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_47 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_47 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3399 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_141 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_141 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_470} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_470} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14343 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5600 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5600 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FU_n_548 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FU_n_548 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN6802_alu_in2_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN6802_alu_in2_0 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/n_95 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8252_mem_wdata_18 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/mem_rdata[21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/mem_rdata[21]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2220 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2220 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN5447_n_976 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN5447_n_976 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_10818 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_10818 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9727 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9727 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6581 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6581 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN5752_n_5616 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5752_n_5616 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3359 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3359 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {cpu_inst_addr[13]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {cpu_inst_addr[13]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5508 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5508 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_600 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_600 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_debug_module/n_186 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7828_mem_rdata_21 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3039 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3039 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9447 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9447 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_8310 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_8310 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[9]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[9]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[10]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[10]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_15579 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_15579 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/FE_OFN1384_victim_way_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/FE_OFN1384_victim_way_0 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6040 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6040 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/mem_wb_reg_write -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/mem_wb_reg_write -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3272 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3272 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_14006 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_14006 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_10057 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_10057 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN2554_n_340 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2554_n_340 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_9173 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9173 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[14]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[14]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net spi_ss -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net spi_ss -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {itcm_d_rdata[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_3 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_3 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clic/lvl_q[27][0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[27][0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in1[2]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in1[2]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN3248_FE_DBTN34_n_9419 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN3248_FE_DBTN34_n_9419 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_4224 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_4224 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_PHN23866_SA_GEN_0_genblk1_slave_arbitration_ARID_valid_nxt_2 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN23866_SA_GEN_0_genblk1_slave_arbitration_ARID_valid_nxt_2 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5664 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5664 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {dbg_reg_read_data[18]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {dbg_reg_read_data[18]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8041_mem_wdata_29 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_PHN25942_FE_OFN6071_n_15428 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN25942_FE_OFN6071_n_15428 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_3306 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_3306 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1938 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1938 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_13620 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_13620 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8121_mem_wdata_11 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_AW_channel_n_1038} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_AW_channel_n_1038} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_PHN27584_FE_OFN6066_n_15421 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN27584_FE_OFN6066_n_15421 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_740 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_740 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_9636 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5989_n_7152 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_845 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_845 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_269 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_269 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dtcm/n_8 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dtcm/n_8 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_itcm/u_mem/n_29 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_775 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_775 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_syscon/n_123 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_16876 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_16876 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN689_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN689_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1607_sdram_dq_o_12 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_itcm/u_mem/n_86 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN3717_mem_addr_2 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9443 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9443 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9400 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9400 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5039 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5039 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1441 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1441 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_W_channel_WDATA_channel_shift_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_W_channel_WDATA_channel_shift_en} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2091 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2091 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_96273_BAR -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_96273_BAR -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_8547 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_8547 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/RF_rf_main[read_reg2][20]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN24002_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_10833 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_10833 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_7867 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7867 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_7161 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7161 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/x0_pl[9]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/x0_pl[9]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_704 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_704 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/pc_reg[11]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/pc_reg[11]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14844 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_226 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_226 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clic/lvl_q[21][1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[21][1]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_6081 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_99 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_99 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/if_id_pc_in[13]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/if_id_pc_in[13]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN972_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN972_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1819_u_apb_cordic_iter_cnt_3 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1819_u_apb_cordic_iter_cnt_3 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN9387_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_85 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_85 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_887 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_887 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_594 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_594 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_1474 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[30]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[30]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dtcm/n_75 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dtcm/n_75 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/n_508 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_292 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_68 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AR_crossing_flag} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AR_crossing_flag} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_54 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_54 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3402 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3402 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_123 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_123 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_775 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_775 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[40].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[40].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_9353 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_54 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_54 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_13811 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6001 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6001 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pad_out[8]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_95 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_95 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_AR_channel_n_799} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_AR_channel_n_799} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_806 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_806 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3122 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3122 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN2063_n_3278 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN2063_n_3278 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8315_mem_wdata_4 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8329_mem_wdata_1 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_82 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_82 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AW_channel_arbiter/n_95} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AW_channel_arbiter/n_95} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_R_channel/filter_rd_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_R_channel/filter_rd_en} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6041 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6041 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_i2c/n_329 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[13][1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[13][1]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1161 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AR_channel_arb_req[3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AR_channel_arb_req[3]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/ID_csr_set_or_clr -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/ID_csr_set_or_clr -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN3405_RF_n_18274 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN3405_RF_n_18274 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5684 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5684 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1614_sdram_dq_o_5 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_566} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_566} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_B_channel/n_99} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_B_channel/n_99} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9151 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9151 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_7174 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7174 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_35 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_35 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_785 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_785 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5816 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5816 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8029_mem_wdata_31 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7808_mem_rdata_9 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7808_mem_rdata_9 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_84 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_84 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN1316_n_1 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN1316_n_1 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_7274 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_7274 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/ID_add_574_40_n_734 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/ID_add_574_40_n_734 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5836 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5836 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_20049 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN24698_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_5190 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_5190 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/FE_OFN8821_data_write_word_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_644 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_644 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2978 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2978 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_13221 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_13221 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN2978_mem_addr_9 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8282_mem_wdata_11 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_rom/n_199 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_rom/n_199 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9581 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9581 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6383 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6383 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5496 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5496 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN154_n_26280 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_770 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_770 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[13].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[13].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_663 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_663 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4739 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN499_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN499_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_20778 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/n_53 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/FE_OFN8708_n_3214 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9499 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9499 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6105 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6105 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_10280 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_10280 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_tim1_cnt[5]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim1_cnt[5]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1613_sdram_dq_o_6 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_413 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_413 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[38].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[38].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2941 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2941 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_rom/n_296 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_rom/n_296 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN2602_n_5835 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2602_n_5835 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1950 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1950 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_syscon/n_148 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9734 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9734 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5837 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5837 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_19690 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_249 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7844_mem_rdata_5 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[0].dispatcher_read_channel_R_channel_SLV_FIFO[4].fifo_rdata_n_28} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_830 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_830 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3377 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3377 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pad_oe[21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {pad_out[19]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7387 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7387 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5065 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5065 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[61].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[61].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_65 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_65 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/FE_OFN8791_data_write_word_13 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_13675 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN231_n_16063 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2094 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2094 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_950 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_950 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5687 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5687 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN5386_n_16958 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN5386_n_16958 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_111} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_111} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_AR_channel_arbiter/n_102} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_AR_channel_arbiter/n_102} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_13124 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_13124 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6525 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6525 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_4846 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_4846 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_W_channel_n_3257} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[2].dispatcher_read_channel_R_channel_SLV_FIFO[5].fifo_rdata_n_28} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN3548_n_7030 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[48].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[48].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_165 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_165 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/pc_reg[27]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_24307 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_24307 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/n_271 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_94 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_35 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14522 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1754 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1754 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_125 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_60 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1854 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1854 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_760 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_760 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3123 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3123 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_437 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_437 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_4 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_4 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clic/best_key[2]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_gpio/n_522 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_6766 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_6766 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_3626 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_66 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
setEcoMode -batchMode false -refinePlace true -updateTiming true
refinePlace
ecoRoute
ecoRoute -fix_drc
clearDrc
verifyConnectivity -net {VDD VSS} -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_fillfix_pg.rpt
clearDrc
verify_drc -limit 500000 -report ./verify_rpt/drc_fillfix.rpt
verifyConnectivity -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_fillfix.rpt
saveDesign ./saved/top_soc_postRoute_ecofill.enc
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
timeDesign -postRoute -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_fillfix -prefix r1
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
setEcoMode -batchMode true -refinePlace false -updateTiming false
ecoAddRepeater -net n_23047 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_23047 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1617_sdram_dq_o_2 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1612_sdram_dq_o_7 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1609_sdram_dq_o_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN3239_FE_DBTN43_u_axi_to_apb_u_resp_fifo_rd_ptr_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN3239_FE_DBTN43_u_axi_to_apb_u_resp_fifo_rd_ptr_0 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_121 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_121 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3291 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3291 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_652 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_652 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_90 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_90 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1579_sdram_ba_1 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[29][0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[15][1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_617 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_253 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
setEcoMode -batchMode false -refinePlace true -updateTiming true
refinePlace
ecoRoute
ecoRoute -fix_drc
clearDrc
verifyConnectivity -net {VDD VSS} -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_fillfix_pg.rpt
clearDrc
verify_drc -limit 500000 -report ./verify_rpt/drc_fillfix.rpt
verifyConnectivity -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_fillfix.rpt
saveDesign ./saved/top_soc_postRoute_ecofill.enc
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
timeDesign -postRoute -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_fillfix -prefix r2
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
setEcoMode -batchMode true -refinePlace false -updateTiming false
ecoAddRepeater -net FE_OFN1606_sdram_dq_o_13 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_131 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_131 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_89 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_24844 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_24844 -cell BUFx4_ASAP7_75t_R
setEcoMode -batchMode false -refinePlace true -updateTiming true
refinePlace
ecoRoute
ecoRoute -fix_drc
clearDrc
verifyConnectivity -net {VDD VSS} -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_fillfix_pg.rpt
clearDrc
verify_drc -limit 500000 -report ./verify_rpt/drc_fillfix.rpt
verifyConnectivity -type all -error 100000 -warning 1000 -report ./verify_rpt/connectivity_fillfix.rpt
saveDesign ./saved/top_soc_postRoute_ecofill.enc
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
timeDesign -postRoute -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_fillfix -prefix r3
all_constraint_modes -active
set_interactive_constraint_modes [all_constraint_modes -active]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_max_transition {*}$flags [format %.4f [expr {$value - $delta}]]  [get_clocks $clocks]
set_interactive_constraint_modes {}
timeDesign -postRoute -hold -outDir /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/eco/reports/timing_fillfix_hold -prefix final
