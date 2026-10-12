#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Mon Oct 12 22:33:21 2026                
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
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[11]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[27]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[14]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[22]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[7]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[30]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[28]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[23]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[24]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7876_mem_rdata_21 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[25]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[10]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN6924_n_14515 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[26]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[16]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[17]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN6303_n_364 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[8]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_AR_channel_MST_FIFO[1].fifo_Ax_channel_rd_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7839_mem_rdata_23 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7839_mem_rdata_23 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1584_sdram_dq_o_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14495 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_itcm/mem_read -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wstrb_hold[2]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wstrb_hold[2]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN7295_n_235 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[9]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1160 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN33957_dsp_sa_RDATA_i_3_133 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN33957_dsp_sa_RDATA_i_3_133 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14497 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14566 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[19]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7882_mem_rdata_15 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[18]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7897_mem_rdata_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_84 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_84 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_itcm/u_mem/n_22 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_8993 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_8993 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pad_oe[21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1140 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][158]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][158]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {paddr_9[12]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {paddr_9[12]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[20]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[29]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {clic_irq_id[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {clic_irq_id[0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14401 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][146]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][146]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN184_n_26250 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN184_n_26250 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1099 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/FE_OFN3584_n_380 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7889_mem_rdata_8 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_19245 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_19245 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_18760 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {clic_irq_id[1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {clic_irq_id[1]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_8951 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_8951 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1283 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/wr_timeout_w_top -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/wr_timeout_w_top -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1953 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1953 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN9014_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN9014_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/n_233} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/n_233} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_AR_crossing_flag} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_AR_crossing_flag} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_13991 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[1].dispatcher_read_channel_R_channel_SLV_FIFO[6].fifo_rdata_n_28} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[1].dispatcher_read_channel_R_channel_SLV_FIFO[3].fifo_rdata_n_31} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_20019 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_20019 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7888_mem_rdata_9 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[15]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14437 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14437 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7877_mem_rdata_20 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7831_mem_rdata_31 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7836_mem_rdata_26 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7836_mem_rdata_26 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_cordic_iter_cnt[3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_cordic_iter_cnt[3]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1148 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/sa_dsp_RVALID_o[5][0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7709 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7709 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_7088 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7088 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_AR_channel_n_1023} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_AR_channel_n_1023} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_debug_module/n_143 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[2].dispatcher_read_channel_AR_channel_mst_skid_buffer_BWD_REGISTERED.rd_ptr[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[2].dispatcher_read_channel_AR_channel_mst_skid_buffer_BWD_REGISTERED.rd_ptr[0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5459 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5459 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_cordic_state[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_cordic_state[0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN6387_n_181 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7893_mem_rdata_4 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7895_mem_rdata_2 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN1322_n_5222 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN1322_n_5222 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pad_oe[6]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7835_mem_rdata_27 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN29356_FE_DBTN144_n_26290 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN29356_FE_DBTN144_n_26290 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[31]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/ex_mem_csr_write_data[31]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7840_mem_rdata_22 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7840_mem_rdata_22 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7841_mem_rdata_21 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7841_mem_rdata_21 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_80 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_80 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9477 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9477 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_802 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_802 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5817 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5817 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_663 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_663 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_94 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_129 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_129 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_427} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_R_channel/n_427} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_15984 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_15984 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[3].dispatcher_read_channel_R_channel_SLV_FIFO[3].fifo_rdata_n_31} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_347 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5929 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5929 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7883_mem_rdata_14 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6961 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6961 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pwdata_0[11]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {pwdata_0[11]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_R_channel/FE_OFN3691_n_194} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_R_channel/FE_OFN3691_n_194} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[24]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[24]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/trap_enter -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/trap_enter -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN5561_n_7379 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN5561_n_7379 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[13]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9208 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9208 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN139_n_26295 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN139_n_26295 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN185_n_26249 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN185_n_26249 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN2233_n_1127 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN2233_n_1127 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7838_mem_rdata_24 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5652_n_347 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5652_n_347 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_PHN36731_SA_GEN_4_genblk1_slave_arbitration_ARID_valid_nxt_6 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN36731_SA_GEN_4_genblk1_slave_arbitration_ARID_valid_nxt_6 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_775 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_775 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_35 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_35 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_8760 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_8760 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1819_u_axi_to_apb_u_cmd_fifo_rd_ptr_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1819_u_axi_to_apb_u_cmd_fifo_rd_ptr_0 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/FE_OFN8779_data_write_word_15 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[21][1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[21][1]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/RF_x2_sp[26]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/RF_x2_sp[26]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1590_sdram_dq_o_4 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1599_sdram_dqm_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_115 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_115 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14938 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN3674_n_12079 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN3674_n_12079 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clic/lvl_q[18][0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[18][0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_9717 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_9717 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_425} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_425} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clint_u_irq_gen_mtip_comb[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN7878_mem_rdata_19 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/FE_OFN7966_n_86 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/n_46 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/n_46 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_watchdog/FE_OFN3588_n_148 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_watchdog/FE_OFN3588_n_148 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1902 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1902 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_8786 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_8786 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dtcm/u_mem/n_47 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_R_channel/n_252} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_R_channel/n_252} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14354 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7161 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7161 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN3615_n_343 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN3615_n_343 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_801 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_801 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_3611 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_3611 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_263 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_263 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[9]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[9]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {cpu_data_addr[20]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {cpu_data_addr[20]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_14516 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_12290 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/u_wr_master_n_1569 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/u_wr_master_n_1569 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_PHN23913_cpu_data_wdata_15 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_PHN23913_cpu_data_wdata_15 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_66 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_66 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_ARID_valid_nxt[3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_ARID_valid_nxt[3]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN2178_pc_reg_3 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN2178_pc_reg_3 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_631 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN7779_n_9239 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN7779_n_9239 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2064 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2064 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN977_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN977_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1439 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1439 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_1951 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1951 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_15579 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_15579 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1556_sdram_ba_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7086 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7086 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_AR_channel_n_2955} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_AR_channel_n_2955} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[26].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[26].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/RF_x2_sp[31]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/RF_x2_sp[31]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2752 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2752 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN704_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN704_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_5894 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_5894 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_R_channel/filter_rd_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_R_channel/filter_rd_en} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_19389 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9145 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9145 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_i2c/n_316 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_316 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_652 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_652 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_283 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_283 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/EX_gen_muldiv.DIV_remainder[21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/EX_gen_muldiv.DIV_remainder[21]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_10131 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_10131 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_R_channel/filter_rd_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_R_channel/filter_rd_en} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_R_channel/n_581} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_R_channel/n_581} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN2506_SA_GEN_4__genblk1_slave_arbitration_AR_channel_n_177_BAR -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2506_SA_GEN_4__genblk1_slave_arbitration_AR_channel_n_177_BAR -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_774 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_774 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_11295 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_11295 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_7852 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7852 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_995 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_995 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8165_mem_wdata_2 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8165_mem_wdata_2 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_13997 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7106 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7106 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_815 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_815 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_11245 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_11245 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_53 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_53 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5020 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5020 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN212_n_26222 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN212_n_26222 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8254_mem_wdata_23 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8254_mem_wdata_23 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8080_mem_wdata_22 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8080_mem_wdata_22 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3127 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3127 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_170 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_170 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[2].dispatcher_read_channel_R_channel_SLV_FIFO[2].fifo_rdata_n_31} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9375 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9375 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_273 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_273 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4739 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8060_mem_wdata_26 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8060_mem_wdata_26 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_25} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_25} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_7692 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7692 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN121_n_26313 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN121_n_26313 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_9714 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9714 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[25]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[25]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN989_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN989_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_PHN24412_if_id_instr_11 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_PHN24412_if_id_instr_11 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_tim1_cnt[8]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim1_cnt[8]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/FE_OFN3166_FE_DBTN374_slv_skid_buffer_BWD_REGISTERED_rd_ptr_0} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/FE_OFN3166_FE_DBTN374_slv_skid_buffer_BWD_REGISTERED_rd_ptr_0} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN2571_n_5817 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2571_n_5817 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1518_pad_oe_23 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {sdram_addr[9]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN7045_n_304 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/FE_OFN1358_victim_way_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/FE_OFN1358_victim_way_0 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_107} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_107} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_i2c/n_242 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_242 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_798 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_798 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_dcache/DATA_RAM_G_DATA_WAY[0].u_sram/FE_PDN30_bank_rdata_0__21} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6014 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6014 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clic/lvl_q[27][0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[27][0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6023 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6023 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_AR_channel_AxID_valid[granted_mst_id][2]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_AR_channel_AxID_valid[granted_mst_id][2]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_3303 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_3303 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2149 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2149 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3343 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3343 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_1191 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_1191 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_13018 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_13018 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9213 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9213 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN7996_n_14565 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_266 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_266 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_5217 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_5217 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN5418_n_982 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN5418_n_982 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1811_u_axi_to_apb_w_state_1 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1811_u_axi_to_apb_w_state_1 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7833_mem_rdata_29 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN2066_n_3314 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN2066_n_3314 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN902_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN902_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_4954 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_4954 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_AR_channel_n_798} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_AR_channel_n_798} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[15].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[15].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_749 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_749 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_269 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_269 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_1441 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_1441 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3214 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][203]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][203]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_AR_channel_MST_FIFO[1].fifo_Ax_channel_rd_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_2279 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_2279 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_954 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_954 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_787 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_787 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_11333 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_11333 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_7331 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_7331 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3034 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3034 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/inc_CSR_RF_add_641_38_n_606 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/inc_CSR_RF_add_641_38_n_606 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/RF_n_18251 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/RF_n_18251 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8095_mem_wdata_19 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8095_mem_wdata_19 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_ARID_valid_nxt[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_ARID_valid_nxt[0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_debug_module/n_387 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_debug_module/n_387 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_5520 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_5520 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_3120 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_3120 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_267 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_267 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_17715 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17715 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6100 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6100 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6057 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6057 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_769 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_769 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/RF_n_14904 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/if_id_instr[8]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/if_id_instr[8]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN1372_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN1372_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_dtcm/mem_rdata[28]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_dtcm/mem_rdata[28]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_124 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_124 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_3001 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_3001 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5683 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5683 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {sdram_addr[12]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5574 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5574 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_1030 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1030 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_4 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_4 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_PHN24155_cpu_data_wdata_25 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_PHN24155_cpu_data_wdata_25 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8132_mem_wdata_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN8132_mem_wdata_10 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_814 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_814 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[28].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[28].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN9012_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN9012_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/FE_OFN8766_data_write_word_22 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/FE_OFN8766_data_write_word_22 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_457} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_457} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_4964 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_4964 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RREADY_o[0][3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RREADY_o[0][3]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2108 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2108 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2089 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2089 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[30].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[30].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_253 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_253 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_itcm/n_261 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8331_mem_wdata_9 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8331_mem_wdata_9 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_17037 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17037 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_39 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_39 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2011 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2011 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_785 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_785 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_784 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_784 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/if_id_pc_in[20]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/if_id_pc_in[20]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2941 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2941 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_23096 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_23096 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8284_mem_wdata_18 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8284_mem_wdata_18 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_5237 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_5237 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_26113 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_26113 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN217_n_26217 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN217_n_26217 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2090 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2090 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[6].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[6].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_5900 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_5900 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_9817 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9817 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_650 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_650 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5914 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5914 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_R_channel/n_194} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_R_channel/n_194} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_12044 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9449 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9449 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_AR_channel_n_890} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[1].genblk1.slave_arbitration_AR_channel_n_890} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[2].dispatcher_read_channel_R_channel_SLV_FIFO[3].fifo_rdata_n_31} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_816 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_816 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_debug_module/FE_OFN8396_dbg_reg_read_data_26 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_debug_module/FE_OFN8396_dbg_reg_read_data_26 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_19963 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_to_apb_r_state[1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_to_apb_r_state[1]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8388_n_92 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5997 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5997 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[0].dispatcher_read_channel_AR_channel_fifo_xa_order_rd_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1963 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1963 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_18944 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN5360_n_18376 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN5360_n_18376 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_10174 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_10174 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1972 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1972 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/if_id_instr[9]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/if_id_instr[9]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN1397_FE_DBTN318_n_16870 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN1397_FE_DBTN318_n_16870 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN9035_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN9035_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_OFN7837_mem_rdata_25 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_7009 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[5].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[5].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_4502 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_4502 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/id_ex_alu_src -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/id_ex_alu_src -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/RF_n_18233 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/RF_n_18233 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4469 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4469 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_5253 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_5253 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_12179 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_12179 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6964 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6964 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_370 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN7901_FE_DBTN319_n_9748 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN7901_FE_DBTN319_n_9748 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8236_mem_wdata_26 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8236_mem_wdata_26 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8910_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN8910_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/n_550 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14051 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_14051 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN5845_n_6931 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5845_n_6931 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_PHN23394_SA_GEN_5_genblk1_slave_arbitration_AR_crossing_flag -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN23394_SA_GEN_5_genblk1_slave_arbitration_AR_crossing_flag -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_810 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_810 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_9798 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_9798 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/n_338 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_338 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/FE_OFN3213_FE_DBTN107_n_385 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/FE_OFN3213_FE_DBTN107_n_385 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/FE_DBTN108_n_51 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/FE_DBTN108_n_51 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_4379 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_15976 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_15976 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN252_DSP_GEN_1__dispatcher_read_channel_AR_channel_mst_skid_buffer_BWD_REGISTERED_rd_ptr_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN252_DSP_GEN_1__dispatcher_read_channel_AR_channel_mst_skid_buffer_BWD_REGISTERED_rd_ptr_0 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_9701 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_9701 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_itcm/u_mem/n_35 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_itcm/n_120 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_itcm/n_120 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN6427_n_269 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_116 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_116 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6104 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6104 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3336 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3336 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2939 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2939 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_4839 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_47} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_47} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_AW_channel_msk_addr_crossing_flag[3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_AW_channel_msk_addr_crossing_flag[3]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN6070_n_15469 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN6070_n_15469 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/RF_n_18232 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/RF_n_18232 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[21]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_9863 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_9863 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_DBTN33_n_9873 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_DBTN33_n_9873 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1560_sdram_addr_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_ARID_valid_nxt[6]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_ARID_valid_nxt[6]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_4919 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_DBTN342_n_4838 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_DBTN342_n_4838 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_21294 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_21294 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AR_channel_arbiter/n_89} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_AR_channel_arbiter/n_89} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_B_channel/n_46} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_B_channel/n_46} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9514 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9514 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2220 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2220 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_1429 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1429 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_990 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_990 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_debug_module/FE_OFN2319_n_400 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_debug_module/FE_OFN2319_n_400 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/RF_rf_main[read_reg2][21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/wdata_hold[31]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_585} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_585} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_13633 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_13633 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4778 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_itcm/mem_rdata[31]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_itcm/mem_rdata[31]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN3071_mem_addr_5 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN3071_mem_addr_5 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/n_291 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3223 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3211 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_643 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_643 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_559 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_559 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6587 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6587 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_i2c/n_329 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_329 -cell BUFx4_ASAP7_75t_R
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
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37184_FE_OFN8095_mem_wdata_19 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37184_FE_OFN8095_mem_wdata_19 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37209_FE_OFN9012_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37209_FE_OFN9012_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON36984_FE_OFN9014_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON36984_FE_OFN9014_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_ECON37272_FE_OFN8910_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_ECON37272_FE_OFN8910_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37206_FE_OFN8132_mem_wdata_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37206_FE_OFN8132_mem_wdata_10 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/FE_OFN8693_n_3066 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/FE_OFN8693_n_3066 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_262} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[5].genblk1.slave_arbitration_R_channel/n_262} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[27]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[27]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_9813 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_9813 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_800 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_800 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_ARID_valid_nxt[6]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[2].genblk1.slave_arbitration_ARID_valid_nxt[6]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1594_sdram_dq_o_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1915 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1915 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_661 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_661 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN1587_sdram_dq_o_7 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_OFN6986_n_181 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17712 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17712 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5936 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5936 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN1217_n_0 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN1217_n_0 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/n_302 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_302 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_2050 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_12209 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_12209 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_icache/DATA_RAM_G_DATA_WAY[0].u_sram/G_BANKED_RDATA.read_bank_q[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_icache/DATA_RAM_G_DATA_WAY[0].u_sram/G_BANKED_RDATA.read_bank_q[0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3247 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3247 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_clic/lvl_q[4][1]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_clic/lvl_q[4][1]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/u_wr_master_n_858 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/u_wr_master_n_858 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5682 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5682 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_tim1_cnt[12]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim1_cnt[12]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pwdata_0[10]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {pwdata_0[10]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_ram_hi/mem_wdata[24]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_hi/mem_wdata[24]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_5255 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_5255 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3126 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3126 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_debug_module/n_620 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_debug_module/n_620 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5836 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5836 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5027 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5027 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN146_n_26288 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN146_n_26288 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_845 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_845 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_2971 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_2971 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_62 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_62 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_12224 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_12224 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_icache/n_131 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_icache/n_131 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/FE_OFN8760_data_write_word_26 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/FE_OFN8760_data_write_word_26 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_818 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_818 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_768 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_768 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_948 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_948 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_debug_module/n_624 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_debug_module/n_624 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_4205 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_4205 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_30180 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_30180 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_17723 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17723 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_295 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_295 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/n_244} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/n_244} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9942 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9942 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3165 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3165 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_9201 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_9201 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5457 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5457 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_2449 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_2449 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_1963 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1963 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_740 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_740 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_644 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_644 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_8190 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/if_id_instr[7]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/if_id_instr[7]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/n_15} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/n_15} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5053 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5053 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[3].dispatcher_read_channel_AR_channel_mst_skid_buffer_BWD_REGISTERED.rd_en} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/DSP_GEN[3].dispatcher_read_channel_AR_channel_mst_skid_buffer_BWD_REGISTERED.rd_en} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN2616_n_5950 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2616_n_5950 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_2278 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_819 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_819 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_950 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_950 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_285 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_285 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3171 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_3171 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2960 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_2960 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_17699 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17699 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN6372_n_148 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/FE_OFN2887_slv_skid_buffer_BWD_REGISTERED_rd_ptr_0} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/FE_OFN2887_slv_skid_buffer_BWD_REGISTERED_rd_ptr_0} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][143]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/dsp_sa_RDATA_i[3][143]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_DBTN174_n_26260 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_DBTN174_n_26260 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1832 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1832 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[58].t2_a} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_apb_ascon_u_ascon/gen_sbox[58].t2_a} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_core/alu_in2[18]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_core/alu_in2[18]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN1781_cpu_data_addr_17 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN1781_cpu_data_addr_17 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_18588 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN3051_mem_addr_8 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_OFN3051_mem_addr_8 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_16523 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_8917 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_8917 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5021 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5021 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN2826_n_15297 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN2826_n_15297 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_OFN5809_n_6909 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_OFN5809_n_6909 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/FE_PHN23769_SA_GEN_5_genblk1_slave_arbitration_ARID_valid_nxt_2 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/FE_PHN23769_SA_GEN_5_genblk1_slave_arbitration_ARID_valid_nxt_2 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/FE_OFN1774_cpu_data_addr_23 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/FE_OFN1774_cpu_data_addr_23 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN477_reset_sys_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN477_reset_sys_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_22842 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_16997 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_16997 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_tim0_cnt[0]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_tim0_cnt[0]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_PHN23852_cpu_data_wdata_31 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_PHN23852_cpu_data_wdata_31 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_PHN34325_pwdata_0_28 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_PHN34325_pwdata_0_28 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/n_54 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/n_54 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3335 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_dcache/n_3335 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[3].genblk1.slave_arbitration_B_channel/n_26} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_B_channel/n_43} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[0].genblk1.slave_arbitration_B_channel/n_43} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_16024 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_16024 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_watchdog/n_78 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1950 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1950 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_104 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_104 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_86 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_488 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_488 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN3464_n_4898 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/FE_OFN3464_n_4898 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_10119 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_10119 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_ram_lo/mem_rdata[21]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_ram_lo/mem_rdata[21]} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_dcache/n_3238 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_225 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_i2c/n_225 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_639 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_639 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_core/n_155 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_core/n_155 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/FE_OFN3169_FE_DBTN372_slv_skid_buffer_BWD_REGISTERED_rd_ptr_0} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[6].genblk1.slave_arbitration_R_channel/FE_OFN3169_FE_DBTN372_slv_skid_buffer_BWD_REGISTERED_rd_ptr_0} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net {u_axi_interconnect/SA_GEN[4].genblk1.slave_arbitration_B_channel/n_105} -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_6973 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_6973 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1981 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_apb_ascon_u_ascon/n_1981 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_2056 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_2056 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_1430 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1430 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5854 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_5854 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4431 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_13377 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1862_n_14648 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN1862_n_14648 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_OFN5225_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_OFN5225_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net FE_PHN28214_pwdata_0_19 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net FE_PHN28214_pwdata_0_19 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net {pad_oe[3]} -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
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
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37327_FE_OFN8095_mem_wdata_19 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37327_FE_OFN8095_mem_wdata_19 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37328_FE_OFN9012_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37328_FE_OFN9012_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37329_FE_OFN9014_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37329_FE_OFN9014_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_ECON37330_FE_OFN8910_n -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_lo/u_mem/FE_ECON37330_FE_OFN8910_n -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37331_FE_OFN8132_mem_wdata_10 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_ram_hi/u_mem/FE_ECON37331_FE_OFN8132_mem_wdata_10 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_5304 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_5304 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_clic/n_1754 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_clic/n_1754 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4231 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_apb_dma_u_dma_engine/n_4231 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net n_17702 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net n_17702 -cell BUFx4_ASAP7_75t_R
ecoAddRepeater -net u_axi_interconnect/n_4989 -cell BUFx4_ASAP7_75t_R -relativeDistToSink 0.9
ecoAddRepeater -net u_axi_interconnect/n_4989 -cell BUFx4_ASAP7_75t_R
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
