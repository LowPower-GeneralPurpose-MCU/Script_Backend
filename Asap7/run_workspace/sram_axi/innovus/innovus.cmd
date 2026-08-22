#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Sat Aug 22 12:15:16 2026                
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
win
set enc_source_continue_on_error false
set auto_file_dir /tmp/user1/innovus_master
set init_design_uniquify 1
setLibraryUnit -time 1ns -cap 1pf
set init_lef_file {/home/user1/Desktop/asap7/asap7sc7p5t_28/techlef_misc/asap7_tech_4x_201209.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_L_4x_220121a.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_R_4x_220121a.lef /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LEF/4xLEF/srambank_256x4x32_6t122.lef.4x.lef}
set ::TimeLib::tsgMarkCellLatchConstructFlag 1
set conf_qxconf_file NULL
set conf_qxlib_file NULL
set defHierChar /
set distributed_client_message_echo 1
set distributed_mmmc_disable_reports_auto_redirection 0
set init_abstract_view abstract
set init_layout_view layout
set init_design_settop 1
set init_top_cell axi_ram
set init_gnd_net VSS
set init_pwr_net VDD
set init_mmmc_file ./tcl/viewDefinition.tcl
set init_verilog ./outputs/axi_ram_syn.v
get_message -id GLOBAL-100 -suppress
get_message -id GLOBAL-100 -suppress
set latch_time_borrow_mode max_borrow
set pegDefaultResScaleFactor 1
set pegDetailResScaleFactor 1
get_message -id GLOBAL-100 -suppress
get_message -id GLOBAL-100 -suppress
set report_inactive_arcs_format {from to when arc_type sense reason}
set tso_post_client_restore_command {update_timing ; write_eco_opt_db ;}
init_design
group_path -name C2C -from [list \
  [get_cells {u_mem/G_SRAM_BANK[0].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[1].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[2].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[3].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[4].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[5].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[6].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[7].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[8].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[9].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[10].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[11].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[12].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[13].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[14].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[15].u_sram}]  \
  [get_cells {u_mem/read_bank_q_reg[0]}]  \
  [get_cells {u_mem/read_bank_q_reg[1]}]  \
  [get_cells {u_mem/read_bank_q_reg[2]}]  \
  [get_cells {u_mem/read_bank_q_reg[3]}]  \
  [get_cells {r_addr_reg_reg[2]}]  \
  [get_cells {r_addr_reg_reg[3]}]  \
  [get_cells {r_addr_reg_reg[4]}]  \
  [get_cells {r_addr_reg_reg[5]}]  \
  [get_cells {r_addr_reg_reg[6]}]  \
  [get_cells {r_addr_reg_reg[7]}]  \
  [get_cells {r_addr_reg_reg[8]}]  \
  [get_cells {r_addr_reg_reg[9]}]  \
  [get_cells {r_addr_reg_reg[10]}]  \
  [get_cells {r_addr_reg_reg[11]}]  \
  [get_cells {r_addr_reg_reg[12]}]  \
  [get_cells {r_addr_reg_reg[13]}]  \
  [get_cells {r_addr_reg_reg[14]}]  \
  [get_cells {r_addr_reg_reg[15]}]  \
  [get_cells {r_count_reg_reg[0]}]  \
  [get_cells {r_count_reg_reg[1]}]  \
  [get_cells {r_count_reg_reg[2]}]  \
  [get_cells {r_count_reg_reg[3]}]  \
  [get_cells {r_count_reg_reg[4]}]  \
  [get_cells {r_count_reg_reg[5]}]  \
  [get_cells {r_count_reg_reg[6]}]  \
  [get_cells {r_count_reg_reg[7]}]  \
  [get_cells r_error_reg_reg]  \
  [get_cells {r_id_reg_reg[0]}]  \
  [get_cells {r_id_reg_reg[1]}]  \
  [get_cells {r_id_reg_reg[2]}]  \
  [get_cells {r_id_reg_reg[3]}]  \
  [get_cells {r_id_reg_reg[4]}]  \
  [get_cells r_incr_reg_reg]  \
  [get_cells {r_len_reg_reg[0]}]  \
  [get_cells {r_len_reg_reg[1]}]  \
  [get_cells {r_len_reg_reg[2]}]  \
  [get_cells {r_len_reg_reg[3]}]  \
  [get_cells {r_len_reg_reg[4]}]  \
  [get_cells {r_len_reg_reg[5]}]  \
  [get_cells {r_len_reg_reg[6]}]  \
  [get_cells {r_len_reg_reg[7]}]  \
  [get_cells s_axi_arready_reg]  \
  [get_cells {s_axi_bid_reg[0]}]  \
  [get_cells {s_axi_bid_reg[1]}]  \
  [get_cells {s_axi_bid_reg[2]}]  \
  [get_cells {s_axi_bid_reg[3]}]  \
  [get_cells {s_axi_bid_reg[4]}]  \
  [get_cells {s_axi_bresp_reg[1]}]  \
  [get_cells s_axi_bvalid_reg]  \
  [get_cells {s_axi_rdata_reg[0]}]  \
  [get_cells {s_axi_rdata_reg[1]}]  \
  [get_cells {s_axi_rdata_reg[2]}]  \
  [get_cells {s_axi_rdata_reg[3]}]  \
  [get_cells {s_axi_rdata_reg[4]}]  \
  [get_cells {s_axi_rdata_reg[5]}]  \
  [get_cells {s_axi_rdata_reg[6]}]  \
  [get_cells {s_axi_rdata_reg[7]}]  \
  [get_cells {s_axi_rdata_reg[8]}]  \
  [get_cells {s_axi_rdata_reg[9]}]  \
  [get_cells {s_axi_rdata_reg[10]}]  \
  [get_cells {s_axi_rdata_reg[11]}]  \
  [get_cells {s_axi_rdata_reg[12]}]  \
  [get_cells {s_axi_rdata_reg[13]}]  \
  [get_cells {s_axi_rdata_reg[14]}]  \
  [get_cells {s_axi_rdata_reg[15]}]  \
  [get_cells {s_axi_rdata_reg[16]}]  \
  [get_cells {s_axi_rdata_reg[17]}]  \
  [get_cells {s_axi_rdata_reg[18]}]  \
  [get_cells {s_axi_rdata_reg[19]}]  \
  [get_cells {s_axi_rdata_reg[20]}]  \
  [get_cells {s_axi_rdata_reg[21]}]  \
  [get_cells {s_axi_rdata_reg[22]}]  \
  [get_cells {s_axi_rdata_reg[23]}]  \
  [get_cells {s_axi_rdata_reg[24]}]  \
  [get_cells {s_axi_rdata_reg[25]}]  \
  [get_cells {s_axi_rdata_reg[26]}]  \
  [get_cells {s_axi_rdata_reg[27]}]  \
  [get_cells {s_axi_rdata_reg[28]}]  \
  [get_cells {s_axi_rdata_reg[29]}]  \
  [get_cells {s_axi_rdata_reg[30]}]  \
  [get_cells {s_axi_rdata_reg[31]}]  \
  [get_cells s_axi_rlast_reg]  \
  [get_cells {s_axi_rresp_reg[1]}]  \
  [get_cells s_axi_rvalid_reg]  \
  [get_cells s_axi_wready_reg]  \
  [get_cells {state_reg[0]}]  \
  [get_cells {state_reg[1]}]  \
  [get_cells {state_reg[2]}]  \
  [get_cells {state_reg[3]}]  \
  [get_cells {w_addr_reg_reg[2]}]  \
  [get_cells {w_addr_reg_reg[3]}]  \
  [get_cells {w_addr_reg_reg[4]}]  \
  [get_cells {w_addr_reg_reg[5]}]  \
  [get_cells {w_addr_reg_reg[6]}]  \
  [get_cells {w_addr_reg_reg[7]}]  \
  [get_cells {w_addr_reg_reg[8]}]  \
  [get_cells {w_addr_reg_reg[9]}]  \
  [get_cells {w_addr_reg_reg[10]}]  \
  [get_cells {w_addr_reg_reg[11]}]  \
  [get_cells {w_addr_reg_reg[12]}]  \
  [get_cells {w_addr_reg_reg[13]}]  \
  [get_cells {w_addr_reg_reg[14]}]  \
  [get_cells {w_addr_reg_reg[15]}]  \
  [get_cells {w_count_reg_reg[0]}]  \
  [get_cells {w_count_reg_reg[1]}]  \
  [get_cells {w_count_reg_reg[2]}]  \
  [get_cells {w_count_reg_reg[3]}]  \
  [get_cells {w_count_reg_reg[4]}]  \
  [get_cells {w_count_reg_reg[5]}]  \
  [get_cells {w_count_reg_reg[6]}]  \
  [get_cells {w_count_reg_reg[7]}]  \
  [get_cells w_drop_reg_reg]  \
  [get_cells w_error_reg_reg]  \
  [get_cells w_finish_hold_reg]  \
  [get_cells w_incr_reg_reg]  \
  [get_cells {w_len_reg_reg[0]}]  \
  [get_cells {w_len_reg_reg[1]}]  \
  [get_cells {w_len_reg_reg[2]}]  \
  [get_cells {w_len_reg_reg[3]}]  \
  [get_cells {w_len_reg_reg[4]}]  \
  [get_cells {w_len_reg_reg[5]}]  \
  [get_cells {w_len_reg_reg[6]}]  \
  [get_cells {w_len_reg_reg[7]}]  \
  [get_cells {wdata_hold_reg[0]}]  \
  [get_cells {wdata_hold_reg[1]}]  \
  [get_cells {wdata_hold_reg[2]}]  \
  [get_cells {wdata_hold_reg[3]}]  \
  [get_cells {wdata_hold_reg[4]}]  \
  [get_cells {wdata_hold_reg[5]}]  \
  [get_cells {wdata_hold_reg[6]}]  \
  [get_cells {wdata_hold_reg[7]}]  \
  [get_cells {wdata_hold_reg[8]}]  \
  [get_cells {wdata_hold_reg[9]}]  \
  [get_cells {wdata_hold_reg[10]}]  \
  [get_cells {wdata_hold_reg[11]}]  \
  [get_cells {wdata_hold_reg[12]}]  \
  [get_cells {wdata_hold_reg[13]}]  \
  [get_cells {wdata_hold_reg[14]}]  \
  [get_cells {wdata_hold_reg[15]}]  \
  [get_cells {wdata_hold_reg[16]}]  \
  [get_cells {wdata_hold_reg[17]}]  \
  [get_cells {wdata_hold_reg[18]}]  \
  [get_cells {wdata_hold_reg[19]}]  \
  [get_cells {wdata_hold_reg[20]}]  \
  [get_cells {wdata_hold_reg[21]}]  \
  [get_cells {wdata_hold_reg[22]}]  \
  [get_cells {wdata_hold_reg[23]}]  \
  [get_cells {wdata_hold_reg[24]}]  \
  [get_cells {wdata_hold_reg[25]}]  \
  [get_cells {wdata_hold_reg[26]}]  \
  [get_cells {wdata_hold_reg[27]}]  \
  [get_cells {wdata_hold_reg[28]}]  \
  [get_cells {wdata_hold_reg[29]}]  \
  [get_cells {wdata_hold_reg[30]}]  \
  [get_cells {wdata_hold_reg[31]}]  \
  [get_cells {wstrb_hold_reg[0]}]  \
  [get_cells {wstrb_hold_reg[1]}]  \
  [get_cells {wstrb_hold_reg[2]}]  \
  [get_cells {wstrb_hold_reg[3]}] ] -to [list \
  [get_cells {u_mem/G_SRAM_BANK[0].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[1].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[2].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[3].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[4].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[5].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[6].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[7].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[8].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[9].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[10].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[11].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[12].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[13].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[14].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[15].u_sram}]  \
  [get_cells {u_mem/read_bank_q_reg[0]}]  \
  [get_cells {u_mem/read_bank_q_reg[1]}]  \
  [get_cells {u_mem/read_bank_q_reg[2]}]  \
  [get_cells {u_mem/read_bank_q_reg[3]}]  \
  [get_cells {r_addr_reg_reg[2]}]  \
  [get_cells {r_addr_reg_reg[3]}]  \
  [get_cells {r_addr_reg_reg[4]}]  \
  [get_cells {r_addr_reg_reg[5]}]  \
  [get_cells {r_addr_reg_reg[6]}]  \
  [get_cells {r_addr_reg_reg[7]}]  \
  [get_cells {r_addr_reg_reg[8]}]  \
  [get_cells {r_addr_reg_reg[9]}]  \
  [get_cells {r_addr_reg_reg[10]}]  \
  [get_cells {r_addr_reg_reg[11]}]  \
  [get_cells {r_addr_reg_reg[12]}]  \
  [get_cells {r_addr_reg_reg[13]}]  \
  [get_cells {r_addr_reg_reg[14]}]  \
  [get_cells {r_addr_reg_reg[15]}]  \
  [get_cells {r_count_reg_reg[0]}]  \
  [get_cells {r_count_reg_reg[1]}]  \
  [get_cells {r_count_reg_reg[2]}]  \
  [get_cells {r_count_reg_reg[3]}]  \
  [get_cells {r_count_reg_reg[4]}]  \
  [get_cells {r_count_reg_reg[5]}]  \
  [get_cells {r_count_reg_reg[6]}]  \
  [get_cells {r_count_reg_reg[7]}]  \
  [get_cells r_error_reg_reg]  \
  [get_cells {r_id_reg_reg[0]}]  \
  [get_cells {r_id_reg_reg[1]}]  \
  [get_cells {r_id_reg_reg[2]}]  \
  [get_cells {r_id_reg_reg[3]}]  \
  [get_cells {r_id_reg_reg[4]}]  \
  [get_cells r_incr_reg_reg]  \
  [get_cells {r_len_reg_reg[0]}]  \
  [get_cells {r_len_reg_reg[1]}]  \
  [get_cells {r_len_reg_reg[2]}]  \
  [get_cells {r_len_reg_reg[3]}]  \
  [get_cells {r_len_reg_reg[4]}]  \
  [get_cells {r_len_reg_reg[5]}]  \
  [get_cells {r_len_reg_reg[6]}]  \
  [get_cells {r_len_reg_reg[7]}]  \
  [get_cells s_axi_arready_reg]  \
  [get_cells {s_axi_bid_reg[0]}]  \
  [get_cells {s_axi_bid_reg[1]}]  \
  [get_cells {s_axi_bid_reg[2]}]  \
  [get_cells {s_axi_bid_reg[3]}]  \
  [get_cells {s_axi_bid_reg[4]}]  \
  [get_cells {s_axi_bresp_reg[1]}]  \
  [get_cells s_axi_bvalid_reg]  \
  [get_cells {s_axi_rdata_reg[0]}]  \
  [get_cells {s_axi_rdata_reg[1]}]  \
  [get_cells {s_axi_rdata_reg[2]}]  \
  [get_cells {s_axi_rdata_reg[3]}]  \
  [get_cells {s_axi_rdata_reg[4]}]  \
  [get_cells {s_axi_rdata_reg[5]}]  \
  [get_cells {s_axi_rdata_reg[6]}]  \
  [get_cells {s_axi_rdata_reg[7]}]  \
  [get_cells {s_axi_rdata_reg[8]}]  \
  [get_cells {s_axi_rdata_reg[9]}]  \
  [get_cells {s_axi_rdata_reg[10]}]  \
  [get_cells {s_axi_rdata_reg[11]}]  \
  [get_cells {s_axi_rdata_reg[12]}]  \
  [get_cells {s_axi_rdata_reg[13]}]  \
  [get_cells {s_axi_rdata_reg[14]}]  \
  [get_cells {s_axi_rdata_reg[15]}]  \
  [get_cells {s_axi_rdata_reg[16]}]  \
  [get_cells {s_axi_rdata_reg[17]}]  \
  [get_cells {s_axi_rdata_reg[18]}]  \
  [get_cells {s_axi_rdata_reg[19]}]  \
  [get_cells {s_axi_rdata_reg[20]}]  \
  [get_cells {s_axi_rdata_reg[21]}]  \
  [get_cells {s_axi_rdata_reg[22]}]  \
  [get_cells {s_axi_rdata_reg[23]}]  \
  [get_cells {s_axi_rdata_reg[24]}]  \
  [get_cells {s_axi_rdata_reg[25]}]  \
  [get_cells {s_axi_rdata_reg[26]}]  \
  [get_cells {s_axi_rdata_reg[27]}]  \
  [get_cells {s_axi_rdata_reg[28]}]  \
  [get_cells {s_axi_rdata_reg[29]}]  \
  [get_cells {s_axi_rdata_reg[30]}]  \
  [get_cells {s_axi_rdata_reg[31]}]  \
  [get_cells s_axi_rlast_reg]  \
  [get_cells {s_axi_rresp_reg[1]}]  \
  [get_cells s_axi_rvalid_reg]  \
  [get_cells s_axi_wready_reg]  \
  [get_cells {state_reg[0]}]  \
  [get_cells {state_reg[1]}]  \
  [get_cells {state_reg[2]}]  \
  [get_cells {state_reg[3]}]  \
  [get_cells {w_addr_reg_reg[2]}]  \
  [get_cells {w_addr_reg_reg[3]}]  \
  [get_cells {w_addr_reg_reg[4]}]  \
  [get_cells {w_addr_reg_reg[5]}]  \
  [get_cells {w_addr_reg_reg[6]}]  \
  [get_cells {w_addr_reg_reg[7]}]  \
  [get_cells {w_addr_reg_reg[8]}]  \
  [get_cells {w_addr_reg_reg[9]}]  \
  [get_cells {w_addr_reg_reg[10]}]  \
  [get_cells {w_addr_reg_reg[11]}]  \
  [get_cells {w_addr_reg_reg[12]}]  \
  [get_cells {w_addr_reg_reg[13]}]  \
  [get_cells {w_addr_reg_reg[14]}]  \
  [get_cells {w_addr_reg_reg[15]}]  \
  [get_cells {w_count_reg_reg[0]}]  \
  [get_cells {w_count_reg_reg[1]}]  \
  [get_cells {w_count_reg_reg[2]}]  \
  [get_cells {w_count_reg_reg[3]}]  \
  [get_cells {w_count_reg_reg[4]}]  \
  [get_cells {w_count_reg_reg[5]}]  \
  [get_cells {w_count_reg_reg[6]}]  \
  [get_cells {w_count_reg_reg[7]}]  \
  [get_cells w_drop_reg_reg]  \
  [get_cells w_error_reg_reg]  \
  [get_cells w_finish_hold_reg]  \
  [get_cells w_incr_reg_reg]  \
  [get_cells {w_len_reg_reg[0]}]  \
  [get_cells {w_len_reg_reg[1]}]  \
  [get_cells {w_len_reg_reg[2]}]  \
  [get_cells {w_len_reg_reg[3]}]  \
  [get_cells {w_len_reg_reg[4]}]  \
  [get_cells {w_len_reg_reg[5]}]  \
  [get_cells {w_len_reg_reg[6]}]  \
  [get_cells {w_len_reg_reg[7]}]  \
  [get_cells {wdata_hold_reg[0]}]  \
  [get_cells {wdata_hold_reg[1]}]  \
  [get_cells {wdata_hold_reg[2]}]  \
  [get_cells {wdata_hold_reg[3]}]  \
  [get_cells {wdata_hold_reg[4]}]  \
  [get_cells {wdata_hold_reg[5]}]  \
  [get_cells {wdata_hold_reg[6]}]  \
  [get_cells {wdata_hold_reg[7]}]  \
  [get_cells {wdata_hold_reg[8]}]  \
  [get_cells {wdata_hold_reg[9]}]  \
  [get_cells {wdata_hold_reg[10]}]  \
  [get_cells {wdata_hold_reg[11]}]  \
  [get_cells {wdata_hold_reg[12]}]  \
  [get_cells {wdata_hold_reg[13]}]  \
  [get_cells {wdata_hold_reg[14]}]  \
  [get_cells {wdata_hold_reg[15]}]  \
  [get_cells {wdata_hold_reg[16]}]  \
  [get_cells {wdata_hold_reg[17]}]  \
  [get_cells {wdata_hold_reg[18]}]  \
  [get_cells {wdata_hold_reg[19]}]  \
  [get_cells {wdata_hold_reg[20]}]  \
  [get_cells {wdata_hold_reg[21]}]  \
  [get_cells {wdata_hold_reg[22]}]  \
  [get_cells {wdata_hold_reg[23]}]  \
  [get_cells {wdata_hold_reg[24]}]  \
  [get_cells {wdata_hold_reg[25]}]  \
  [get_cells {wdata_hold_reg[26]}]  \
  [get_cells {wdata_hold_reg[27]}]  \
  [get_cells {wdata_hold_reg[28]}]  \
  [get_cells {wdata_hold_reg[29]}]  \
  [get_cells {wdata_hold_reg[30]}]  \
  [get_cells {wdata_hold_reg[31]}]  \
  [get_cells {wstrb_hold_reg[0]}]  \
  [get_cells {wstrb_hold_reg[1]}]  \
  [get_cells {wstrb_hold_reg[2]}]  \
  [get_cells {wstrb_hold_reg[3]}] ]
group_path -name C2O -from [list \
  [get_cells {u_mem/G_SRAM_BANK[0].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[1].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[2].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[3].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[4].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[5].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[6].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[7].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[8].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[9].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[10].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[11].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[12].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[13].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[14].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[15].u_sram}]  \
  [get_cells {u_mem/read_bank_q_reg[0]}]  \
  [get_cells {u_mem/read_bank_q_reg[1]}]  \
  [get_cells {u_mem/read_bank_q_reg[2]}]  \
  [get_cells {u_mem/read_bank_q_reg[3]}]  \
  [get_cells {r_addr_reg_reg[2]}]  \
  [get_cells {r_addr_reg_reg[3]}]  \
  [get_cells {r_addr_reg_reg[4]}]  \
  [get_cells {r_addr_reg_reg[5]}]  \
  [get_cells {r_addr_reg_reg[6]}]  \
  [get_cells {r_addr_reg_reg[7]}]  \
  [get_cells {r_addr_reg_reg[8]}]  \
  [get_cells {r_addr_reg_reg[9]}]  \
  [get_cells {r_addr_reg_reg[10]}]  \
  [get_cells {r_addr_reg_reg[11]}]  \
  [get_cells {r_addr_reg_reg[12]}]  \
  [get_cells {r_addr_reg_reg[13]}]  \
  [get_cells {r_addr_reg_reg[14]}]  \
  [get_cells {r_addr_reg_reg[15]}]  \
  [get_cells {r_count_reg_reg[0]}]  \
  [get_cells {r_count_reg_reg[1]}]  \
  [get_cells {r_count_reg_reg[2]}]  \
  [get_cells {r_count_reg_reg[3]}]  \
  [get_cells {r_count_reg_reg[4]}]  \
  [get_cells {r_count_reg_reg[5]}]  \
  [get_cells {r_count_reg_reg[6]}]  \
  [get_cells {r_count_reg_reg[7]}]  \
  [get_cells r_error_reg_reg]  \
  [get_cells {r_id_reg_reg[0]}]  \
  [get_cells {r_id_reg_reg[1]}]  \
  [get_cells {r_id_reg_reg[2]}]  \
  [get_cells {r_id_reg_reg[3]}]  \
  [get_cells {r_id_reg_reg[4]}]  \
  [get_cells r_incr_reg_reg]  \
  [get_cells {r_len_reg_reg[0]}]  \
  [get_cells {r_len_reg_reg[1]}]  \
  [get_cells {r_len_reg_reg[2]}]  \
  [get_cells {r_len_reg_reg[3]}]  \
  [get_cells {r_len_reg_reg[4]}]  \
  [get_cells {r_len_reg_reg[5]}]  \
  [get_cells {r_len_reg_reg[6]}]  \
  [get_cells {r_len_reg_reg[7]}]  \
  [get_cells s_axi_arready_reg]  \
  [get_cells {s_axi_bid_reg[0]}]  \
  [get_cells {s_axi_bid_reg[1]}]  \
  [get_cells {s_axi_bid_reg[2]}]  \
  [get_cells {s_axi_bid_reg[3]}]  \
  [get_cells {s_axi_bid_reg[4]}]  \
  [get_cells {s_axi_bresp_reg[1]}]  \
  [get_cells s_axi_bvalid_reg]  \
  [get_cells {s_axi_rdata_reg[0]}]  \
  [get_cells {s_axi_rdata_reg[1]}]  \
  [get_cells {s_axi_rdata_reg[2]}]  \
  [get_cells {s_axi_rdata_reg[3]}]  \
  [get_cells {s_axi_rdata_reg[4]}]  \
  [get_cells {s_axi_rdata_reg[5]}]  \
  [get_cells {s_axi_rdata_reg[6]}]  \
  [get_cells {s_axi_rdata_reg[7]}]  \
  [get_cells {s_axi_rdata_reg[8]}]  \
  [get_cells {s_axi_rdata_reg[9]}]  \
  [get_cells {s_axi_rdata_reg[10]}]  \
  [get_cells {s_axi_rdata_reg[11]}]  \
  [get_cells {s_axi_rdata_reg[12]}]  \
  [get_cells {s_axi_rdata_reg[13]}]  \
  [get_cells {s_axi_rdata_reg[14]}]  \
  [get_cells {s_axi_rdata_reg[15]}]  \
  [get_cells {s_axi_rdata_reg[16]}]  \
  [get_cells {s_axi_rdata_reg[17]}]  \
  [get_cells {s_axi_rdata_reg[18]}]  \
  [get_cells {s_axi_rdata_reg[19]}]  \
  [get_cells {s_axi_rdata_reg[20]}]  \
  [get_cells {s_axi_rdata_reg[21]}]  \
  [get_cells {s_axi_rdata_reg[22]}]  \
  [get_cells {s_axi_rdata_reg[23]}]  \
  [get_cells {s_axi_rdata_reg[24]}]  \
  [get_cells {s_axi_rdata_reg[25]}]  \
  [get_cells {s_axi_rdata_reg[26]}]  \
  [get_cells {s_axi_rdata_reg[27]}]  \
  [get_cells {s_axi_rdata_reg[28]}]  \
  [get_cells {s_axi_rdata_reg[29]}]  \
  [get_cells {s_axi_rdata_reg[30]}]  \
  [get_cells {s_axi_rdata_reg[31]}]  \
  [get_cells s_axi_rlast_reg]  \
  [get_cells {s_axi_rresp_reg[1]}]  \
  [get_cells s_axi_rvalid_reg]  \
  [get_cells s_axi_wready_reg]  \
  [get_cells {state_reg[0]}]  \
  [get_cells {state_reg[1]}]  \
  [get_cells {state_reg[2]}]  \
  [get_cells {state_reg[3]}]  \
  [get_cells {w_addr_reg_reg[2]}]  \
  [get_cells {w_addr_reg_reg[3]}]  \
  [get_cells {w_addr_reg_reg[4]}]  \
  [get_cells {w_addr_reg_reg[5]}]  \
  [get_cells {w_addr_reg_reg[6]}]  \
  [get_cells {w_addr_reg_reg[7]}]  \
  [get_cells {w_addr_reg_reg[8]}]  \
  [get_cells {w_addr_reg_reg[9]}]  \
  [get_cells {w_addr_reg_reg[10]}]  \
  [get_cells {w_addr_reg_reg[11]}]  \
  [get_cells {w_addr_reg_reg[12]}]  \
  [get_cells {w_addr_reg_reg[13]}]  \
  [get_cells {w_addr_reg_reg[14]}]  \
  [get_cells {w_addr_reg_reg[15]}]  \
  [get_cells {w_count_reg_reg[0]}]  \
  [get_cells {w_count_reg_reg[1]}]  \
  [get_cells {w_count_reg_reg[2]}]  \
  [get_cells {w_count_reg_reg[3]}]  \
  [get_cells {w_count_reg_reg[4]}]  \
  [get_cells {w_count_reg_reg[5]}]  \
  [get_cells {w_count_reg_reg[6]}]  \
  [get_cells {w_count_reg_reg[7]}]  \
  [get_cells w_drop_reg_reg]  \
  [get_cells w_error_reg_reg]  \
  [get_cells w_finish_hold_reg]  \
  [get_cells w_incr_reg_reg]  \
  [get_cells {w_len_reg_reg[0]}]  \
  [get_cells {w_len_reg_reg[1]}]  \
  [get_cells {w_len_reg_reg[2]}]  \
  [get_cells {w_len_reg_reg[3]}]  \
  [get_cells {w_len_reg_reg[4]}]  \
  [get_cells {w_len_reg_reg[5]}]  \
  [get_cells {w_len_reg_reg[6]}]  \
  [get_cells {w_len_reg_reg[7]}]  \
  [get_cells {wdata_hold_reg[0]}]  \
  [get_cells {wdata_hold_reg[1]}]  \
  [get_cells {wdata_hold_reg[2]}]  \
  [get_cells {wdata_hold_reg[3]}]  \
  [get_cells {wdata_hold_reg[4]}]  \
  [get_cells {wdata_hold_reg[5]}]  \
  [get_cells {wdata_hold_reg[6]}]  \
  [get_cells {wdata_hold_reg[7]}]  \
  [get_cells {wdata_hold_reg[8]}]  \
  [get_cells {wdata_hold_reg[9]}]  \
  [get_cells {wdata_hold_reg[10]}]  \
  [get_cells {wdata_hold_reg[11]}]  \
  [get_cells {wdata_hold_reg[12]}]  \
  [get_cells {wdata_hold_reg[13]}]  \
  [get_cells {wdata_hold_reg[14]}]  \
  [get_cells {wdata_hold_reg[15]}]  \
  [get_cells {wdata_hold_reg[16]}]  \
  [get_cells {wdata_hold_reg[17]}]  \
  [get_cells {wdata_hold_reg[18]}]  \
  [get_cells {wdata_hold_reg[19]}]  \
  [get_cells {wdata_hold_reg[20]}]  \
  [get_cells {wdata_hold_reg[21]}]  \
  [get_cells {wdata_hold_reg[22]}]  \
  [get_cells {wdata_hold_reg[23]}]  \
  [get_cells {wdata_hold_reg[24]}]  \
  [get_cells {wdata_hold_reg[25]}]  \
  [get_cells {wdata_hold_reg[26]}]  \
  [get_cells {wdata_hold_reg[27]}]  \
  [get_cells {wdata_hold_reg[28]}]  \
  [get_cells {wdata_hold_reg[29]}]  \
  [get_cells {wdata_hold_reg[30]}]  \
  [get_cells {wdata_hold_reg[31]}]  \
  [get_cells {wstrb_hold_reg[0]}]  \
  [get_cells {wstrb_hold_reg[1]}]  \
  [get_cells {wstrb_hold_reg[2]}]  \
  [get_cells {wstrb_hold_reg[3]}] ] -to [list \
  [get_ports s_axi_awready]  \
  [get_ports s_axi_wready]  \
  [get_ports {s_axi_bid[4]}]  \
  [get_ports {s_axi_bid[3]}]  \
  [get_ports {s_axi_bid[2]}]  \
  [get_ports {s_axi_bid[1]}]  \
  [get_ports {s_axi_bid[0]}]  \
  [get_ports {s_axi_bresp[1]}]  \
  [get_ports {s_axi_bresp[0]}]  \
  [get_ports s_axi_bvalid]  \
  [get_ports s_axi_arready]  \
  [get_ports {s_axi_rid[4]}]  \
  [get_ports {s_axi_rid[3]}]  \
  [get_ports {s_axi_rid[2]}]  \
  [get_ports {s_axi_rid[1]}]  \
  [get_ports {s_axi_rid[0]}]  \
  [get_ports {s_axi_rdata[31]}]  \
  [get_ports {s_axi_rdata[30]}]  \
  [get_ports {s_axi_rdata[29]}]  \
  [get_ports {s_axi_rdata[28]}]  \
  [get_ports {s_axi_rdata[27]}]  \
  [get_ports {s_axi_rdata[26]}]  \
  [get_ports {s_axi_rdata[25]}]  \
  [get_ports {s_axi_rdata[24]}]  \
  [get_ports {s_axi_rdata[23]}]  \
  [get_ports {s_axi_rdata[22]}]  \
  [get_ports {s_axi_rdata[21]}]  \
  [get_ports {s_axi_rdata[20]}]  \
  [get_ports {s_axi_rdata[19]}]  \
  [get_ports {s_axi_rdata[18]}]  \
  [get_ports {s_axi_rdata[17]}]  \
  [get_ports {s_axi_rdata[16]}]  \
  [get_ports {s_axi_rdata[15]}]  \
  [get_ports {s_axi_rdata[14]}]  \
  [get_ports {s_axi_rdata[13]}]  \
  [get_ports {s_axi_rdata[12]}]  \
  [get_ports {s_axi_rdata[11]}]  \
  [get_ports {s_axi_rdata[10]}]  \
  [get_ports {s_axi_rdata[9]}]  \
  [get_ports {s_axi_rdata[8]}]  \
  [get_ports {s_axi_rdata[7]}]  \
  [get_ports {s_axi_rdata[6]}]  \
  [get_ports {s_axi_rdata[5]}]  \
  [get_ports {s_axi_rdata[4]}]  \
  [get_ports {s_axi_rdata[3]}]  \
  [get_ports {s_axi_rdata[2]}]  \
  [get_ports {s_axi_rdata[1]}]  \
  [get_ports {s_axi_rdata[0]}]  \
  [get_ports {s_axi_rresp[1]}]  \
  [get_ports {s_axi_rresp[0]}]  \
  [get_ports s_axi_rlast]  \
  [get_ports s_axi_rvalid] ]
group_path -name I2C -from [list \
  [get_ports {s_axi_awid[4]}]  \
  [get_ports {s_axi_awid[3]}]  \
  [get_ports {s_axi_awid[2]}]  \
  [get_ports {s_axi_awid[1]}]  \
  [get_ports {s_axi_awid[0]}]  \
  [get_ports {s_axi_awaddr[31]}]  \
  [get_ports {s_axi_awaddr[30]}]  \
  [get_ports {s_axi_awaddr[29]}]  \
  [get_ports {s_axi_awaddr[28]}]  \
  [get_ports {s_axi_awaddr[27]}]  \
  [get_ports {s_axi_awaddr[26]}]  \
  [get_ports {s_axi_awaddr[25]}]  \
  [get_ports {s_axi_awaddr[24]}]  \
  [get_ports {s_axi_awaddr[23]}]  \
  [get_ports {s_axi_awaddr[22]}]  \
  [get_ports {s_axi_awaddr[21]}]  \
  [get_ports {s_axi_awaddr[20]}]  \
  [get_ports {s_axi_awaddr[19]}]  \
  [get_ports {s_axi_awaddr[18]}]  \
  [get_ports {s_axi_awaddr[17]}]  \
  [get_ports {s_axi_awaddr[16]}]  \
  [get_ports {s_axi_awaddr[15]}]  \
  [get_ports {s_axi_awaddr[14]}]  \
  [get_ports {s_axi_awaddr[13]}]  \
  [get_ports {s_axi_awaddr[12]}]  \
  [get_ports {s_axi_awaddr[11]}]  \
  [get_ports {s_axi_awaddr[10]}]  \
  [get_ports {s_axi_awaddr[9]}]  \
  [get_ports {s_axi_awaddr[8]}]  \
  [get_ports {s_axi_awaddr[7]}]  \
  [get_ports {s_axi_awaddr[6]}]  \
  [get_ports {s_axi_awaddr[5]}]  \
  [get_ports {s_axi_awaddr[4]}]  \
  [get_ports {s_axi_awaddr[3]}]  \
  [get_ports {s_axi_awaddr[2]}]  \
  [get_ports {s_axi_awaddr[1]}]  \
  [get_ports {s_axi_awaddr[0]}]  \
  [get_ports {s_axi_awlen[7]}]  \
  [get_ports {s_axi_awlen[6]}]  \
  [get_ports {s_axi_awlen[5]}]  \
  [get_ports {s_axi_awlen[4]}]  \
  [get_ports {s_axi_awlen[3]}]  \
  [get_ports {s_axi_awlen[2]}]  \
  [get_ports {s_axi_awlen[1]}]  \
  [get_ports {s_axi_awlen[0]}]  \
  [get_ports {s_axi_awsize[2]}]  \
  [get_ports {s_axi_awsize[1]}]  \
  [get_ports {s_axi_awsize[0]}]  \
  [get_ports {s_axi_awburst[1]}]  \
  [get_ports {s_axi_awburst[0]}]  \
  [get_ports s_axi_awlock]  \
  [get_ports {s_axi_awcache[3]}]  \
  [get_ports {s_axi_awcache[2]}]  \
  [get_ports {s_axi_awcache[1]}]  \
  [get_ports {s_axi_awcache[0]}]  \
  [get_ports {s_axi_awprot[2]}]  \
  [get_ports {s_axi_awprot[1]}]  \
  [get_ports {s_axi_awprot[0]}]  \
  [get_ports {s_axi_awqos[3]}]  \
  [get_ports {s_axi_awqos[2]}]  \
  [get_ports {s_axi_awqos[1]}]  \
  [get_ports {s_axi_awqos[0]}]  \
  [get_ports {s_axi_awregion[3]}]  \
  [get_ports {s_axi_awregion[2]}]  \
  [get_ports {s_axi_awregion[1]}]  \
  [get_ports {s_axi_awregion[0]}]  \
  [get_ports s_axi_awvalid]  \
  [get_ports {s_axi_wdata[31]}]  \
  [get_ports {s_axi_wdata[30]}]  \
  [get_ports {s_axi_wdata[29]}]  \
  [get_ports {s_axi_wdata[28]}]  \
  [get_ports {s_axi_wdata[27]}]  \
  [get_ports {s_axi_wdata[26]}]  \
  [get_ports {s_axi_wdata[25]}]  \
  [get_ports {s_axi_wdata[24]}]  \
  [get_ports {s_axi_wdata[23]}]  \
  [get_ports {s_axi_wdata[22]}]  \
  [get_ports {s_axi_wdata[21]}]  \
  [get_ports {s_axi_wdata[20]}]  \
  [get_ports {s_axi_wdata[19]}]  \
  [get_ports {s_axi_wdata[18]}]  \
  [get_ports {s_axi_wdata[17]}]  \
  [get_ports {s_axi_wdata[16]}]  \
  [get_ports {s_axi_wdata[15]}]  \
  [get_ports {s_axi_wdata[14]}]  \
  [get_ports {s_axi_wdata[13]}]  \
  [get_ports {s_axi_wdata[12]}]  \
  [get_ports {s_axi_wdata[11]}]  \
  [get_ports {s_axi_wdata[10]}]  \
  [get_ports {s_axi_wdata[9]}]  \
  [get_ports {s_axi_wdata[8]}]  \
  [get_ports {s_axi_wdata[7]}]  \
  [get_ports {s_axi_wdata[6]}]  \
  [get_ports {s_axi_wdata[5]}]  \
  [get_ports {s_axi_wdata[4]}]  \
  [get_ports {s_axi_wdata[3]}]  \
  [get_ports {s_axi_wdata[2]}]  \
  [get_ports {s_axi_wdata[1]}]  \
  [get_ports {s_axi_wdata[0]}]  \
  [get_ports {s_axi_wstrb[3]}]  \
  [get_ports {s_axi_wstrb[2]}]  \
  [get_ports {s_axi_wstrb[1]}]  \
  [get_ports {s_axi_wstrb[0]}]  \
  [get_ports s_axi_wlast]  \
  [get_ports s_axi_wvalid]  \
  [get_ports s_axi_bready]  \
  [get_ports {s_axi_arid[4]}]  \
  [get_ports {s_axi_arid[3]}]  \
  [get_ports {s_axi_arid[2]}]  \
  [get_ports {s_axi_arid[1]}]  \
  [get_ports {s_axi_arid[0]}]  \
  [get_ports {s_axi_araddr[31]}]  \
  [get_ports {s_axi_araddr[30]}]  \
  [get_ports {s_axi_araddr[29]}]  \
  [get_ports {s_axi_araddr[28]}]  \
  [get_ports {s_axi_araddr[27]}]  \
  [get_ports {s_axi_araddr[26]}]  \
  [get_ports {s_axi_araddr[25]}]  \
  [get_ports {s_axi_araddr[24]}]  \
  [get_ports {s_axi_araddr[23]}]  \
  [get_ports {s_axi_araddr[22]}]  \
  [get_ports {s_axi_araddr[21]}]  \
  [get_ports {s_axi_araddr[20]}]  \
  [get_ports {s_axi_araddr[19]}]  \
  [get_ports {s_axi_araddr[18]}]  \
  [get_ports {s_axi_araddr[17]}]  \
  [get_ports {s_axi_araddr[16]}]  \
  [get_ports {s_axi_araddr[15]}]  \
  [get_ports {s_axi_araddr[14]}]  \
  [get_ports {s_axi_araddr[13]}]  \
  [get_ports {s_axi_araddr[12]}]  \
  [get_ports {s_axi_araddr[11]}]  \
  [get_ports {s_axi_araddr[10]}]  \
  [get_ports {s_axi_araddr[9]}]  \
  [get_ports {s_axi_araddr[8]}]  \
  [get_ports {s_axi_araddr[7]}]  \
  [get_ports {s_axi_araddr[6]}]  \
  [get_ports {s_axi_araddr[5]}]  \
  [get_ports {s_axi_araddr[4]}]  \
  [get_ports {s_axi_araddr[3]}]  \
  [get_ports {s_axi_araddr[2]}]  \
  [get_ports {s_axi_araddr[1]}]  \
  [get_ports {s_axi_araddr[0]}]  \
  [get_ports {s_axi_arlen[7]}]  \
  [get_ports {s_axi_arlen[6]}]  \
  [get_ports {s_axi_arlen[5]}]  \
  [get_ports {s_axi_arlen[4]}]  \
  [get_ports {s_axi_arlen[3]}]  \
  [get_ports {s_axi_arlen[2]}]  \
  [get_ports {s_axi_arlen[1]}]  \
  [get_ports {s_axi_arlen[0]}]  \
  [get_ports {s_axi_arsize[2]}]  \
  [get_ports {s_axi_arsize[1]}]  \
  [get_ports {s_axi_arsize[0]}]  \
  [get_ports {s_axi_arburst[1]}]  \
  [get_ports {s_axi_arburst[0]}]  \
  [get_ports s_axi_arlock]  \
  [get_ports {s_axi_arcache[3]}]  \
  [get_ports {s_axi_arcache[2]}]  \
  [get_ports {s_axi_arcache[1]}]  \
  [get_ports {s_axi_arcache[0]}]  \
  [get_ports {s_axi_arprot[2]}]  \
  [get_ports {s_axi_arprot[1]}]  \
  [get_ports {s_axi_arprot[0]}]  \
  [get_ports {s_axi_arqos[3]}]  \
  [get_ports {s_axi_arqos[2]}]  \
  [get_ports {s_axi_arqos[1]}]  \
  [get_ports {s_axi_arqos[0]}]  \
  [get_ports {s_axi_arregion[3]}]  \
  [get_ports {s_axi_arregion[2]}]  \
  [get_ports {s_axi_arregion[1]}]  \
  [get_ports {s_axi_arregion[0]}]  \
  [get_ports s_axi_arvalid]  \
  [get_ports s_axi_rready] ] -to [list \
  [get_cells {u_mem/G_SRAM_BANK[0].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[1].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[2].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[3].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[4].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[5].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[6].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[7].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[8].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[9].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[10].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[11].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[12].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[13].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[14].u_sram}]  \
  [get_cells {u_mem/G_SRAM_BANK[15].u_sram}]  \
  [get_cells {u_mem/read_bank_q_reg[0]}]  \
  [get_cells {u_mem/read_bank_q_reg[1]}]  \
  [get_cells {u_mem/read_bank_q_reg[2]}]  \
  [get_cells {u_mem/read_bank_q_reg[3]}]  \
  [get_cells {r_addr_reg_reg[2]}]  \
  [get_cells {r_addr_reg_reg[3]}]  \
  [get_cells {r_addr_reg_reg[4]}]  \
  [get_cells {r_addr_reg_reg[5]}]  \
  [get_cells {r_addr_reg_reg[6]}]  \
  [get_cells {r_addr_reg_reg[7]}]  \
  [get_cells {r_addr_reg_reg[8]}]  \
  [get_cells {r_addr_reg_reg[9]}]  \
  [get_cells {r_addr_reg_reg[10]}]  \
  [get_cells {r_addr_reg_reg[11]}]  \
  [get_cells {r_addr_reg_reg[12]}]  \
  [get_cells {r_addr_reg_reg[13]}]  \
  [get_cells {r_addr_reg_reg[14]}]  \
  [get_cells {r_addr_reg_reg[15]}]  \
  [get_cells {r_count_reg_reg[0]}]  \
  [get_cells {r_count_reg_reg[1]}]  \
  [get_cells {r_count_reg_reg[2]}]  \
  [get_cells {r_count_reg_reg[3]}]  \
  [get_cells {r_count_reg_reg[4]}]  \
  [get_cells {r_count_reg_reg[5]}]  \
  [get_cells {r_count_reg_reg[6]}]  \
  [get_cells {r_count_reg_reg[7]}]  \
  [get_cells r_error_reg_reg]  \
  [get_cells {r_id_reg_reg[0]}]  \
  [get_cells {r_id_reg_reg[1]}]  \
  [get_cells {r_id_reg_reg[2]}]  \
  [get_cells {r_id_reg_reg[3]}]  \
  [get_cells {r_id_reg_reg[4]}]  \
  [get_cells r_incr_reg_reg]  \
  [get_cells {r_len_reg_reg[0]}]  \
  [get_cells {r_len_reg_reg[1]}]  \
  [get_cells {r_len_reg_reg[2]}]  \
  [get_cells {r_len_reg_reg[3]}]  \
  [get_cells {r_len_reg_reg[4]}]  \
  [get_cells {r_len_reg_reg[5]}]  \
  [get_cells {r_len_reg_reg[6]}]  \
  [get_cells {r_len_reg_reg[7]}]  \
  [get_cells s_axi_arready_reg]  \
  [get_cells {s_axi_bid_reg[0]}]  \
  [get_cells {s_axi_bid_reg[1]}]  \
  [get_cells {s_axi_bid_reg[2]}]  \
  [get_cells {s_axi_bid_reg[3]}]  \
  [get_cells {s_axi_bid_reg[4]}]  \
  [get_cells {s_axi_bresp_reg[1]}]  \
  [get_cells s_axi_bvalid_reg]  \
  [get_cells {s_axi_rdata_reg[0]}]  \
  [get_cells {s_axi_rdata_reg[1]}]  \
  [get_cells {s_axi_rdata_reg[2]}]  \
  [get_cells {s_axi_rdata_reg[3]}]  \
  [get_cells {s_axi_rdata_reg[4]}]  \
  [get_cells {s_axi_rdata_reg[5]}]  \
  [get_cells {s_axi_rdata_reg[6]}]  \
  [get_cells {s_axi_rdata_reg[7]}]  \
  [get_cells {s_axi_rdata_reg[8]}]  \
  [get_cells {s_axi_rdata_reg[9]}]  \
  [get_cells {s_axi_rdata_reg[10]}]  \
  [get_cells {s_axi_rdata_reg[11]}]  \
  [get_cells {s_axi_rdata_reg[12]}]  \
  [get_cells {s_axi_rdata_reg[13]}]  \
  [get_cells {s_axi_rdata_reg[14]}]  \
  [get_cells {s_axi_rdata_reg[15]}]  \
  [get_cells {s_axi_rdata_reg[16]}]  \
  [get_cells {s_axi_rdata_reg[17]}]  \
  [get_cells {s_axi_rdata_reg[18]}]  \
  [get_cells {s_axi_rdata_reg[19]}]  \
  [get_cells {s_axi_rdata_reg[20]}]  \
  [get_cells {s_axi_rdata_reg[21]}]  \
  [get_cells {s_axi_rdata_reg[22]}]  \
  [get_cells {s_axi_rdata_reg[23]}]  \
  [get_cells {s_axi_rdata_reg[24]}]  \
  [get_cells {s_axi_rdata_reg[25]}]  \
  [get_cells {s_axi_rdata_reg[26]}]  \
  [get_cells {s_axi_rdata_reg[27]}]  \
  [get_cells {s_axi_rdata_reg[28]}]  \
  [get_cells {s_axi_rdata_reg[29]}]  \
  [get_cells {s_axi_rdata_reg[30]}]  \
  [get_cells {s_axi_rdata_reg[31]}]  \
  [get_cells s_axi_rlast_reg]  \
  [get_cells {s_axi_rresp_reg[1]}]  \
  [get_cells s_axi_rvalid_reg]  \
  [get_cells s_axi_wready_reg]  \
  [get_cells {state_reg[0]}]  \
  [get_cells {state_reg[1]}]  \
  [get_cells {state_reg[2]}]  \
  [get_cells {state_reg[3]}]  \
  [get_cells {w_addr_reg_reg[2]}]  \
  [get_cells {w_addr_reg_reg[3]}]  \
  [get_cells {w_addr_reg_reg[4]}]  \
  [get_cells {w_addr_reg_reg[5]}]  \
  [get_cells {w_addr_reg_reg[6]}]  \
  [get_cells {w_addr_reg_reg[7]}]  \
  [get_cells {w_addr_reg_reg[8]}]  \
  [get_cells {w_addr_reg_reg[9]}]  \
  [get_cells {w_addr_reg_reg[10]}]  \
  [get_cells {w_addr_reg_reg[11]}]  \
  [get_cells {w_addr_reg_reg[12]}]  \
  [get_cells {w_addr_reg_reg[13]}]  \
  [get_cells {w_addr_reg_reg[14]}]  \
  [get_cells {w_addr_reg_reg[15]}]  \
  [get_cells {w_count_reg_reg[0]}]  \
  [get_cells {w_count_reg_reg[1]}]  \
  [get_cells {w_count_reg_reg[2]}]  \
  [get_cells {w_count_reg_reg[3]}]  \
  [get_cells {w_count_reg_reg[4]}]  \
  [get_cells {w_count_reg_reg[5]}]  \
  [get_cells {w_count_reg_reg[6]}]  \
  [get_cells {w_count_reg_reg[7]}]  \
  [get_cells w_drop_reg_reg]  \
  [get_cells w_error_reg_reg]  \
  [get_cells w_finish_hold_reg]  \
  [get_cells w_incr_reg_reg]  \
  [get_cells {w_len_reg_reg[0]}]  \
  [get_cells {w_len_reg_reg[1]}]  \
  [get_cells {w_len_reg_reg[2]}]  \
  [get_cells {w_len_reg_reg[3]}]  \
  [get_cells {w_len_reg_reg[4]}]  \
  [get_cells {w_len_reg_reg[5]}]  \
  [get_cells {w_len_reg_reg[6]}]  \
  [get_cells {w_len_reg_reg[7]}]  \
  [get_cells {wdata_hold_reg[0]}]  \
  [get_cells {wdata_hold_reg[1]}]  \
  [get_cells {wdata_hold_reg[2]}]  \
  [get_cells {wdata_hold_reg[3]}]  \
  [get_cells {wdata_hold_reg[4]}]  \
  [get_cells {wdata_hold_reg[5]}]  \
  [get_cells {wdata_hold_reg[6]}]  \
  [get_cells {wdata_hold_reg[7]}]  \
  [get_cells {wdata_hold_reg[8]}]  \
  [get_cells {wdata_hold_reg[9]}]  \
  [get_cells {wdata_hold_reg[10]}]  \
  [get_cells {wdata_hold_reg[11]}]  \
  [get_cells {wdata_hold_reg[12]}]  \
  [get_cells {wdata_hold_reg[13]}]  \
  [get_cells {wdata_hold_reg[14]}]  \
  [get_cells {wdata_hold_reg[15]}]  \
  [get_cells {wdata_hold_reg[16]}]  \
  [get_cells {wdata_hold_reg[17]}]  \
  [get_cells {wdata_hold_reg[18]}]  \
  [get_cells {wdata_hold_reg[19]}]  \
  [get_cells {wdata_hold_reg[20]}]  \
  [get_cells {wdata_hold_reg[21]}]  \
  [get_cells {wdata_hold_reg[22]}]  \
  [get_cells {wdata_hold_reg[23]}]  \
  [get_cells {wdata_hold_reg[24]}]  \
  [get_cells {wdata_hold_reg[25]}]  \
  [get_cells {wdata_hold_reg[26]}]  \
  [get_cells {wdata_hold_reg[27]}]  \
  [get_cells {wdata_hold_reg[28]}]  \
  [get_cells {wdata_hold_reg[29]}]  \
  [get_cells {wdata_hold_reg[30]}]  \
  [get_cells {wdata_hold_reg[31]}]  \
  [get_cells {wstrb_hold_reg[0]}]  \
  [get_cells {wstrb_hold_reg[1]}]  \
  [get_cells {wstrb_hold_reg[2]}]  \
  [get_cells {wstrb_hold_reg[3]}] ]
setDesignMode -process 7
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
setMultiCpuUsage -acquireLicense 12
setMultiCpuUsage -localCpu 12
setDistributeHost -local
floorPlan -s 620.928 766.464 2.16 2.16 2.16 2.16
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_proto.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_final.rpt
saveFPlan ./outputs/FloorPlan.fp
saveDesign ./saved/axi_ram_hierFP.enc
placeInstance {u_mem/G_SRAM_BANK[0].u_sram} 2.160000 2.160000 R0
placeInstance {u_mem/G_SRAM_BANK[1].u_sram} 127.872000 2.160000 MY
placeInstance {u_mem/G_SRAM_BANK[2].u_sram} 253.584000 2.160000 R0
placeInstance {u_mem/G_SRAM_BANK[3].u_sram} 379.296000 2.160000 MY
placeInstance {u_mem/G_SRAM_BANK[4].u_sram} 379.296000 179.280000 MY
placeInstance {u_mem/G_SRAM_BANK[5].u_sram} 253.584000 179.280000 R0
placeInstance {u_mem/G_SRAM_BANK[6].u_sram} 127.872000 179.280000 MY
placeInstance {u_mem/G_SRAM_BANK[7].u_sram} 2.160000 179.280000 R0
placeInstance {u_mem/G_SRAM_BANK[8].u_sram} 2.160000 356.400000 R0
placeInstance {u_mem/G_SRAM_BANK[9].u_sram} 127.872000 356.400000 MY
placeInstance {u_mem/G_SRAM_BANK[10].u_sram} 253.584000 356.400000 R0
placeInstance {u_mem/G_SRAM_BANK[11].u_sram} 379.296000 356.400000 MY
placeInstance {u_mem/G_SRAM_BANK[12].u_sram} 379.296000 533.520000 MY
placeInstance {u_mem/G_SRAM_BANK[13].u_sram} 253.584000 533.520000 R0
placeInstance {u_mem/G_SRAM_BANK[14].u_sram} 127.872000 533.520000 MY
placeInstance {u_mem/G_SRAM_BANK[15].u_sram} 2.160000 533.520000 R0
createInstGroup SRAM_ISLAND_GROUP
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[0].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[1].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[2].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[3].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[4].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[5].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[6].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[7].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[8].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[9].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[10].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[11].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[12].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[13].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[14].u_sram}
addInstToInstGroup SRAM_ISLAND_GROUP {u_mem/G_SRAM_BANK[15].u_sram}
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
placeInstance {u_mem/G_SRAM_BANK[0].u_sram} 2.160000 2.160000 R0
placeInstance {u_mem/G_SRAM_BANK[1].u_sram} 127.872000 2.160000 MY
placeInstance {u_mem/G_SRAM_BANK[2].u_sram} 253.584000 2.160000 R0
placeInstance {u_mem/G_SRAM_BANK[3].u_sram} 379.296000 2.160000 MY
placeInstance {u_mem/G_SRAM_BANK[7].u_sram} 2.160000 179.280000 R0
placeInstance {u_mem/G_SRAM_BANK[6].u_sram} 127.872000 179.280000 MY
placeInstance {u_mem/G_SRAM_BANK[5].u_sram} 253.584000 179.280000 R0
placeInstance {u_mem/G_SRAM_BANK[4].u_sram} 379.296000 179.280000 MY
placeInstance {u_mem/G_SRAM_BANK[8].u_sram} 2.160000 356.400000 R0
placeInstance {u_mem/G_SRAM_BANK[9].u_sram} 127.872000 356.400000 MY
placeInstance {u_mem/G_SRAM_BANK[10].u_sram} 253.584000 356.400000 R0
placeInstance {u_mem/G_SRAM_BANK[11].u_sram} 379.296000 356.400000 MY
placeInstance {u_mem/G_SRAM_BANK[15].u_sram} 2.160000 533.520000 R0
placeInstance {u_mem/G_SRAM_BANK[14].u_sram} 127.872000 533.520000 MY
placeInstance {u_mem/G_SRAM_BANK[13].u_sram} 253.584000 533.520000 R0
placeInstance {u_mem/G_SRAM_BANK[12].u_sram} 379.296000 533.520000 MY
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
addHaloToBlock -allBlock 2.16 2.16 2.16 2.16
snapFPlan -block
cutRow -area {2.16 2.16 502.848 708.48}
createPlaceBlockage -name SRAM_ISLAND_GROUP_BLOCKAGE -type hard -noCutByCore -box {2.16 2.16 502.848 708.48}
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_after_macroFP.rpt
saveFPlan ./outputs/FloorPlan_withMacro.fp
saveDesign ./saved/axi_ram_macroFP.enc
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_before_pnr.rpt
setAddStripeMode -reset
setAddStripeMode -allow_jog none
clearGlobalNets
deletePGPin -net VDD
deletePGPin -net VSS
deleteAllPowerPreroutes
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {} -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {} -override
globalNetConnect VDD -type tiehi -inst * -module {} -override
globalNetConnect VSS -type tielo -inst * -module {} -override
applyGlobalNets
addRing -nets VDD -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 0.192 -snap_wire_center_to_grid Grid
addRing -nets VSS -type core_rings -follow core -layer {top M8 bottom M8 left M9 right M9} -width 0.480 -spacing 0.480 -offset 1.152 -snap_wire_center_to_grid Grid
deselectAll
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.720000 -number_of_sets 1 -create_pins 0 -area {0.192 0.192 2.16 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 0.732000 -number_of_sets 1 -create_pins 0 -area {0.192 0.192 502.848 2.16} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 0.780000 -number_of_sets 1 -create_pins 0 -area {0.192 706.32 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -create_pins 0 -area {0.192 174.96 502.848 179.28} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.932000 -number_of_sets 1 -create_pins 0 -area {0.192 352.08 502.848 356.4} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M4 -direction horizontal -width 0.096 -spacing 0.288 -start_from bottom -start_offset 1.836000 -number_of_sets 1 -create_pins 0 -area {0.192 529.2 502.848 533.52} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -create_pins 0 -area {500.688 0.192 502.848 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.968000 -number_of_sets 1 -create_pins 0 -area {123.552 0.192 127.872 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.824000 -number_of_sets 1 -create_pins 0 -area {249.264 0.192 253.584 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 1.872000 -number_of_sets 1 -create_pins 0 -area {374.976 0.192 379.296 708.48} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M4 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.672000 -number_of_sets 1 -create_pins 0 -area {121.392 0.192 123.36 10.8} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.720000 -number_of_sets 1 -create_pins 0 -area {247.104 0.192 249.072 10.8} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -create_pins 0 -area {372.816 0.192 374.784 10.8} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.816000 -number_of_sets 1 -create_pins 0 -area {498.528 0.192 500.496 10.8} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.816000 -number_of_sets 1 -create_pins 0 -area {498.528 174.96 500.496 187.92} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -create_pins 0 -area {372.816 174.96 374.784 187.92} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.720000 -number_of_sets 1 -create_pins 0 -area {247.104 174.96 249.072 187.92} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.672000 -number_of_sets 1 -create_pins 0 -area {121.392 174.96 123.36 187.92} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.672000 -number_of_sets 1 -create_pins 0 -area {121.392 352.08 123.36 365.04} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.720000 -number_of_sets 1 -create_pins 0 -area {247.104 352.08 249.072 365.04} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -create_pins 0 -area {372.816 352.08 374.784 365.04} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.816000 -number_of_sets 1 -create_pins 0 -area {498.528 352.08 500.496 365.04} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.816000 -number_of_sets 1 -create_pins 0 -area {498.528 529.2 500.496 542.16} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.768000 -number_of_sets 1 -create_pins 0 -area {372.816 529.2 374.784 542.16} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.720000 -number_of_sets 1 -create_pins 0 -area {247.104 529.2 249.072 542.16} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 0.288 -start_from left -start_offset 0.672000 -number_of_sets 1 -create_pins 0 -area {121.392 529.2 123.36 542.16} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
editTrim -nets {VSS VDD}
clearDrc
deselectAll
deletePGPin -net VDD
deletePGPin -net VSS
createPGPin VSS -geom M9 0.264000 384.456000 0.744000 386.376000 -net VSS
createPGPin VDD -geom M9 1.344000 384.456000 1.824000 386.376000 -net VDD
editTrim -nets {VDD VSS}
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_before_stdcell_place.rpt
verify_drc -check_only special -layer_range {M4 M9} -report ./verify_rpt/pg_drc_before_stdcell_place.rpt
saveDesign ./saved/axi_ram_powerplan.enc
setPinConstraint -cell axi_ram -corner_to_pin_distance 8
setPinAssignMode -pinEditInBatch true
editPin -pin {{s_axi_arid[4]} {s_axi_arid[3]} {s_axi_arid[2]} {s_axi_arid[1]} {s_axi_arid[0]} {s_axi_araddr[31]} {s_axi_araddr[30]} {s_axi_araddr[29]} {s_axi_araddr[28]} {s_axi_araddr[27]} {s_axi_araddr[26]} {s_axi_araddr[25]} {s_axi_araddr[24]} {s_axi_araddr[23]} {s_axi_araddr[22]} {s_axi_araddr[21]} {s_axi_araddr[20]} {s_axi_araddr[19]} {s_axi_araddr[18]} {s_axi_araddr[17]} {s_axi_araddr[16]} {s_axi_araddr[15]} {s_axi_araddr[14]} {s_axi_araddr[13]} {s_axi_araddr[12]} {s_axi_araddr[11]} {s_axi_araddr[10]} {s_axi_araddr[9]} {s_axi_araddr[8]} {s_axi_araddr[7]} {s_axi_araddr[6]} {s_axi_araddr[5]} {s_axi_araddr[4]} {s_axi_araddr[3]} {s_axi_araddr[2]} {s_axi_araddr[1]} {s_axi_araddr[0]} {s_axi_arlen[7]} {s_axi_arlen[6]} {s_axi_arlen[5]} {s_axi_arlen[4]} {s_axi_arlen[3]} {s_axi_arlen[2]} {s_axi_arlen[1]} {s_axi_arlen[0]} {s_axi_arsize[2]} {s_axi_arsize[1]} {s_axi_arsize[0]} {s_axi_arburst[1]} {s_axi_arburst[0]} s_axi_arlock {s_axi_arcache[3]} {s_axi_arcache[2]} {s_axi_arcache[1]} {s_axi_arcache[0]} {s_axi_arprot[2]} {s_axi_arprot[1]} {s_axi_arprot[0]} {s_axi_arqos[3]} {s_axi_arqos[2]} {s_axi_arqos[1]} {s_axi_arqos[0]} {s_axi_arregion[3]} {s_axi_arregion[2]} {s_axi_arregion[1]} {s_axi_arregion[0]} s_axi_arvalid s_axi_arready} -side TOP -layer M7 -spreadType range -start {10.16 768.672} -end {615.088 768.672} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_bid[4]} {s_axi_bid[3]} {s_axi_bid[2]} {s_axi_bid[1]} {s_axi_bid[0]} {s_axi_bresp[1]} {s_axi_bresp[0]} s_axi_bvalid s_axi_bready {s_axi_rid[4]} {s_axi_rid[3]} {s_axi_rid[2]} {s_axi_rid[1]} {s_axi_rid[0]} {s_axi_rdata[31]} {s_axi_rdata[30]} {s_axi_rdata[29]} {s_axi_rdata[28]} {s_axi_rdata[27]} {s_axi_rdata[26]} {s_axi_rdata[25]} {s_axi_rdata[24]} {s_axi_rdata[23]} {s_axi_rdata[22]} {s_axi_rdata[21]} {s_axi_rdata[20]} {s_axi_rdata[19]} {s_axi_rdata[18]} {s_axi_rdata[17]} {s_axi_rdata[16]} {s_axi_rdata[15]} {s_axi_rdata[14]} {s_axi_rdata[13]} {s_axi_rdata[12]} {s_axi_rdata[11]} {s_axi_rdata[10]} {s_axi_rdata[9]} {s_axi_rdata[8]} {s_axi_rdata[7]} {s_axi_rdata[6]} {s_axi_rdata[5]} {s_axi_rdata[4]} {s_axi_rdata[3]} {s_axi_rdata[2]} {s_axi_rdata[1]} {s_axi_rdata[0]} {s_axi_rresp[1]} {s_axi_rresp[0]} s_axi_rlast s_axi_rvalid s_axi_rready} -side RIGHT -layer M6 -spreadType range -start {623.088 760.672} -end {623.088 10.16} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {{s_axi_wdata[31]} {s_axi_wdata[30]} {s_axi_wdata[29]} {s_axi_wdata[28]} {s_axi_wdata[27]} {s_axi_wdata[26]} {s_axi_wdata[25]} {s_axi_wdata[24]} {s_axi_wdata[23]} {s_axi_wdata[22]} {s_axi_wdata[21]} {s_axi_wdata[20]} {s_axi_wdata[19]} {s_axi_wdata[18]} {s_axi_wdata[17]} {s_axi_wdata[16]} {s_axi_wdata[15]} {s_axi_wdata[14]} {s_axi_wdata[13]} {s_axi_wdata[12]} {s_axi_wdata[11]} {s_axi_wdata[10]} {s_axi_wdata[9]} {s_axi_wdata[8]} {s_axi_wdata[7]} {s_axi_wdata[6]} {s_axi_wdata[5]} {s_axi_wdata[4]} {s_axi_wdata[3]} {s_axi_wdata[2]} {s_axi_wdata[1]} {s_axi_wdata[0]} {s_axi_wstrb[3]} {s_axi_wstrb[2]} {s_axi_wstrb[1]} {s_axi_wstrb[0]} s_axi_wlast s_axi_wvalid s_axi_wready} -side BOTTOM -layer M7 -spreadType range -start {615.088 2.16} -end {10.16 2.16} -spreadDirection clockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
editPin -pin {clk rst_n {s_axi_awid[4]} {s_axi_awid[3]} {s_axi_awid[2]} {s_axi_awid[1]} {s_axi_awid[0]} {s_axi_awaddr[31]} {s_axi_awaddr[30]} {s_axi_awaddr[29]} {s_axi_awaddr[28]} {s_axi_awaddr[27]} {s_axi_awaddr[26]} {s_axi_awaddr[25]} {s_axi_awaddr[24]} {s_axi_awaddr[23]} {s_axi_awaddr[22]} {s_axi_awaddr[21]} {s_axi_awaddr[20]} {s_axi_awaddr[19]} {s_axi_awaddr[18]} {s_axi_awaddr[17]} {s_axi_awaddr[16]} {s_axi_awaddr[15]} {s_axi_awaddr[14]} {s_axi_awaddr[13]} {s_axi_awaddr[12]} {s_axi_awaddr[11]} {s_axi_awaddr[10]} {s_axi_awaddr[9]} {s_axi_awaddr[8]} {s_axi_awaddr[7]} {s_axi_awaddr[6]} {s_axi_awaddr[5]} {s_axi_awaddr[4]} {s_axi_awaddr[3]} {s_axi_awaddr[2]} {s_axi_awaddr[1]} {s_axi_awaddr[0]} {s_axi_awlen[7]} {s_axi_awlen[6]} {s_axi_awlen[5]} {s_axi_awlen[4]} {s_axi_awlen[3]} {s_axi_awlen[2]} {s_axi_awlen[1]} {s_axi_awlen[0]} {s_axi_awsize[2]} {s_axi_awsize[1]} {s_axi_awsize[0]} {s_axi_awburst[1]} {s_axi_awburst[0]} s_axi_awlock {s_axi_awcache[3]} {s_axi_awcache[2]} {s_axi_awcache[1]} {s_axi_awcache[0]} {s_axi_awprot[2]} {s_axi_awprot[1]} {s_axi_awprot[0]} {s_axi_awqos[3]} {s_axi_awqos[2]} {s_axi_awqos[1]} {s_axi_awqos[0]} {s_axi_awregion[3]} {s_axi_awregion[2]} {s_axi_awregion[1]} {s_axi_awregion[0]} s_axi_awvalid s_axi_awready} -side LEFT -layer M6 -spreadType range -start {2.16 760.672} -end {2.16 10.16} -spreadDirection counterclockwise -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -honorConstraint 1 -fixedPin 1
setPinAssignMode -pinEditInBatch false
checkPinAssignment -outFile ./verify_rpt/checkPinAssignment_after_pin.rpt
saveDesign ./saved/axi_ram_floorplan_power_pins.enc
setDelayCalMode -SIAware false -equivalent_waveform_model none -ewm_type moments
setPlaceMode -reset
setPlaceMode -place_global_uniform_density false -place_global_module_aware_spare true -place_global_auto_blockage_in_channel soft -place_detail_preroute_as_obs {2 3} -place_global_cong_effort high -place_global_reorder_scan false -place_design_refine_macro false
place_opt_design
refinePlace
checkPlace ./verify_rpt/checkPlace_after_place.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_after_place.rpt
timeDesign -preCTS -outDir ./reports/timing_preCTS
setSrouteMode -reset
setSrouteMode -viaConnectToShape {ring stripe blockring}
sroute -connect corePin -nets {VDD VSS} -corePinCheckStdcellGeoms -allowJogging 0 -allowLayerChange 0
setAddStripeMode -allow_jog none -allow_nonpreferred_dir none -break_at none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M1 -stacked_via_top_layer M5
addStripe -nets {VSS VDD} -layer M5 -direction vertical -width 0.096 -spacing 2.16 -set_to_set_distance 25.920 -start_from left -start_offset 0.912000 -number_of_sets 1 -create_pins 0 -area {503.04 1.968 507.36 768.864} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 2.16 -set_to_set_distance 25.920 -start_from left -start_offset 11.568000 -create_pins 0 -area {507.36 1.968 623.088 768.864} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M5 -direction vertical -width 0.096 -spacing 2.16 -set_to_set_distance 25.920 -start_from left -start_offset 24.288000 -create_pins 0 -area {2.16 708.672 502.848 768.864} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M6 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.128 -spacing 0.288 -set_to_set_distance 34.560 -start_from left -start_offset 0.192000 -area {503.04 2.16 623.088 768.672} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M7 -direction vertical -width 0.128 -spacing 0.288 -set_to_set_distance 34.560 -start_from left -start_offset 17.232000 -area {2.16 708.672 502.848 768.672} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M5 -stacked_via_top_layer M7
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.128 -spacing 0.288 -set_to_set_distance 34.560 -start_from bottom -start_offset 17.232000 -area {500.688 2.16 623.088 768.672} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M6 -direction horizontal -width 0.128 -spacing 0.288 -set_to_set_distance 34.560 -start_from bottom -start_offset 1.920000 -area {2.16 708.672 502.848 768.672} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M7 -stacked_via_top_layer M8
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 19.168000 -create_pins 0 -area {504.000000 0.192 625.056 770.64} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M8 -direction horizontal -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from bottom -start_offset 1.120000 -create_pins 0 -area {0.192 709.440000 502.848 770.64} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
setAddStripeMode -allow_jog none -extend_to_closest_target area_boundary -stacked_via_bottom_layer M8 -stacked_via_top_layer M9
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 33.760000 -create_pins 0 -area {504.000000 0.192 625.056 770.64} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
addStripe -nets {VDD VSS} -layer M9 -direction vertical -width 1.600 -spacing 1.280 -set_to_set_distance 34.560 -start_from left -start_offset 19.168000 -create_pins 0 -area {0.192 709.440000 502.848 770.64} -snap_wire_center_to_grid Grid -allow_snapping_override_custom_spacing 1
applyGlobalNets
editTrim -nets {VDD VSS}
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_trim.rpt
verify_drc -check_only special -layer_range {M4 M5} -area {{500.688 0.0 625.248 770.832} {0.0 706.32 500.688 770.832} {0.0 0.0 2.16 706.32} {2.16 0.0 500.688 2.16} {123.552 2.16 127.872 174.96} {2.16 174.96 123.552 179.28} {249.264 2.16 253.584 174.96} {127.872 174.96 249.264 179.28} {374.976 2.16 379.296 174.96} {253.584 174.96 374.976 179.28} {379.296 174.96 500.688 179.28} {374.976 179.28 379.296 352.08} {379.296 352.08 500.688 356.4} {249.264 179.28 253.584 352.08} {253.584 352.08 374.976 356.4} {123.552 179.28 127.872 352.08} {127.872 352.08 249.264 356.4} {2.16 352.08 123.552 356.4} {123.552 356.4 127.872 529.2} {2.16 529.2 123.552 533.52} {249.264 356.4 253.584 529.2} {127.872 529.2 249.264 533.52} {374.976 356.4 379.296 529.2} {253.584 529.2 374.976 533.52} {379.296 529.2 500.688 533.52} {374.976 533.52 379.296 706.32} {249.264 533.52 253.584 706.32} {123.552 533.52 127.872 706.32} {121.392 0.192 123.36 10.8} {247.104 0.192 249.072 10.8} {372.816 0.192 374.784 10.8} {498.528 0.192 500.496 10.8} {498.528 174.96 500.496 187.92} {372.816 174.96 374.784 187.92} {247.104 174.96 249.072 187.92} {121.392 174.96 123.36 187.92} {121.392 352.08 123.36 365.04} {247.104 352.08 249.072 365.04} {372.816 352.08 374.784 365.04} {498.528 352.08 500.496 365.04} {498.528 529.2 500.496 542.16} {372.816 529.2 374.784 542.16} {247.104 529.2 249.072 542.16} {121.392 529.2 123.36 542.16}} -report ./verify_rpt/sram_m4_interface_drc.rpt
verify_drc -check_only special -layer_range {M6 M9} -area {{500.688 0.0 625.248 770.832} {0.0 706.32 500.688 770.832} {0.0 0.0 2.16 706.32} {2.16 0.0 500.688 2.16} {123.552 2.16 127.872 174.96} {2.16 174.96 123.552 179.28} {249.264 2.16 253.584 174.96} {127.872 174.96 249.264 179.28} {374.976 2.16 379.296 174.96} {253.584 174.96 374.976 179.28} {379.296 174.96 500.688 179.28} {374.976 179.28 379.296 352.08} {379.296 352.08 500.688 356.4} {249.264 179.28 253.584 352.08} {253.584 352.08 374.976 356.4} {123.552 179.28 127.872 352.08} {127.872 352.08 249.264 356.4} {2.16 352.08 123.552 356.4} {123.552 356.4 127.872 529.2} {2.16 529.2 123.552 533.52} {249.264 356.4 253.584 529.2} {127.872 529.2 249.264 533.52} {374.976 356.4 379.296 529.2} {253.584 529.2 374.976 533.52} {379.296 529.2 500.688 533.52} {374.976 533.52 379.296 706.32} {249.264 533.52 253.584 706.32} {123.552 533.52 127.872 706.32} {121.392 0.192 123.36 10.8} {247.104 0.192 249.072 10.8} {372.816 0.192 374.784 10.8} {498.528 0.192 500.496 10.8} {498.528 174.96 500.496 187.92} {372.816 174.96 374.784 187.92} {247.104 174.96 249.072 187.92} {121.392 174.96 123.36 187.92} {121.392 352.08 123.36 365.04} {247.104 352.08 249.072 365.04} {372.816 352.08 374.784 365.04} {498.528 352.08 500.496 365.04} {498.528 529.2 500.496 542.16} {372.816 529.2 374.784 542.16} {247.104 529.2 249.072 542.16} {121.392 529.2 123.36 542.16}} -report ./verify_rpt/pg_drc_after_trim.rpt
verify_drc -check_only special -layer_range {M1 M9} -area {{500.688 0.0 625.248 770.832} {0.0 706.32 500.688 770.832} {0.0 0.0 2.16 706.32} {2.16 0.0 500.688 2.16} {123.552 2.16 127.872 174.96} {2.16 174.96 123.552 179.28} {249.264 2.16 253.584 174.96} {127.872 174.96 249.264 179.28} {374.976 2.16 379.296 174.96} {253.584 174.96 374.976 179.28} {379.296 174.96 500.688 179.28} {374.976 179.28 379.296 352.08} {379.296 352.08 500.688 356.4} {249.264 179.28 253.584 352.08} {253.584 352.08 374.976 356.4} {123.552 179.28 127.872 352.08} {127.872 352.08 249.264 356.4} {2.16 352.08 123.552 356.4} {123.552 356.4 127.872 529.2} {2.16 529.2 123.552 533.52} {249.264 356.4 253.584 529.2} {127.872 529.2 249.264 533.52} {374.976 356.4 379.296 529.2} {253.584 529.2 374.976 533.52} {379.296 529.2 500.688 533.52} {374.976 533.52 379.296 706.32} {249.264 533.52 253.584 706.32} {123.552 533.52 127.872 706.32} {121.392 0.192 123.36 10.8} {247.104 0.192 249.072 10.8} {372.816 0.192 374.784 10.8} {498.528 0.192 500.496 10.8} {498.528 174.96 500.496 187.92} {372.816 174.96 374.784 187.92} {247.104 174.96 249.072 187.92} {121.392 174.96 123.36 187.92} {121.392 352.08 123.36 365.04} {247.104 352.08 249.072 365.04} {372.816 352.08 374.784 365.04} {498.528 352.08 500.496 365.04} {498.528 529.2 500.496 542.16} {372.816 529.2 374.784 542.16} {247.104 529.2 249.072 542.16} {121.392 529.2 123.36 542.16}} -report ./verify_rpt/pg_drc_after_trim_full.rpt
saveDesign ./saved/axi_ram_placed.enc
create_route_type -name leaf_rule -bottom_preferred_layer M2 -top_preferred_layer M3
create_route_type -name trunk_rule -bottom_preferred_layer M4 -top_preferred_layer M5
create_route_type -name top_rule -bottom_preferred_layer M6 -top_preferred_layer M7
set_ccopt_property -net_type leaf route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top route_type top_rule
set_ccopt_property routing_top_min_fanout 16
set_ccopt_property target_max_trans 0.3ns
set_ccopt_property -net_type leaf target_max_trans 35ps
set_ccopt_property -net_type trunk target_max_trans 40ps
set_ccopt_property -net_type top target_max_trans 40ps
set_ccopt_property target_skew 40ps
set_ccopt_property buffer_cells {
    BUFx4_ASAP7_75t_R
    BUFx8_ASAP7_75t_R
    BUFx10_ASAP7_75t_R
    BUFx12_ASAP7_75t_R
    BUFx12f_ASAP7_75t_R
    BUFx16f_ASAP7_75t_R
    BUFx24_ASAP7_75t_R
    BUFx8_ASAP7_75t_L
    BUFx10_ASAP7_75t_L
    BUFx12_ASAP7_75t_L
    BUFx12f_ASAP7_75t_L
    BUFx16f_ASAP7_75t_L
    BUFx24_ASAP7_75t_L
}
set_ccopt_property inverter_cells {
    CKINVDCx8_ASAP7_75t_R
    CKINVDCx12_ASAP7_75t_R
    CKINVDCx16_ASAP7_75t_R
}
set_ccopt_property use_inverters auto
setOptMode -reclaimArea true -leakageToDynamicRatio 0.5 -powerEffort high -fixFanoutLoad true
optDesign -prefix preCTS -preCTS
refinePlace
checkPlace ./verify_rpt/checkPlace_before_cts.rpt
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
clock_opt_design
refinePlace
checkPlace ./verify_rpt/checkPlace_after_cts.rpt
applyGlobalNets
setSrouteMode -reset
setSrouteMode -viaConnectToShape {ring stripe blockring}
sroute -connect corePin -nets {VDD VSS} -corePinCheckStdcellGeoms -corePinLayer M1 -allowJogging 0 -allowLayerChange 0
editTrim -nets {VDD VSS}
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_cts_preopt.rpt
all_constraint_modes -active
set_interactive_constraint_modes $active_constraint_modes
set_propagated_clock [all_clocks]
set_interactive_constraint_modes {}
optDesign -prefix postCTS -postCTS -setup -hold
checkPlace ./verify_rpt/checkPlace_after_postcts.rpt
applyGlobalNets
setSrouteMode -reset
setSrouteMode -viaConnectToShape {ring stripe blockring}
sroute -connect corePin -nets {VDD VSS} -corePinCheckStdcellGeoms -corePinLayer M1 -allowJogging 0 -allowLayerChange 0
editTrim -nets {VDD VSS}
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_postcts.rpt
timeDesign -postCTS -outDir ./reports/timing_postCTS
timeDesign -postCTS -hold -outDir ./reports/timing_postCTS_hold
saveDesign ./saved/axi_ram_postCTS.enc
setFillerMode -reset
setFillerMode -core {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -add_fillers_with_drc false -fitGap true -honorPrerouteAsObs true -diffCellViol true
addFiller -cell {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -prefix FILLER -honorPrerouteAsObs true -diffCellViol true
checkFiller -file ./verify_rpt/checkFiller_after_filler.rpt
checkPlace ./verify_rpt/checkPlace_after_filler.rpt
applyGlobalNets
setSrouteMode -reset
setSrouteMode -viaConnectToShape {ring stripe blockring}
sroute -connect corePin -nets {VDD VSS} -corePinCheckStdcellGeoms -corePinLayer M1 -allowJogging 0 -allowLayerChange 0
editTrim -nets {VDD VSS}
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_filler.rpt
verify_drc -check_only special -layer_range {M1 M9} -area {{500.688 0.0 625.248 770.832} {0.0 706.32 500.688 770.832} {0.0 0.0 2.16 706.32} {2.16 0.0 500.688 2.16} {123.552 2.16 127.872 174.96} {2.16 174.96 123.552 179.28} {249.264 2.16 253.584 174.96} {127.872 174.96 249.264 179.28} {374.976 2.16 379.296 174.96} {253.584 174.96 374.976 179.28} {379.296 174.96 500.688 179.28} {374.976 179.28 379.296 352.08} {379.296 352.08 500.688 356.4} {249.264 179.28 253.584 352.08} {253.584 352.08 374.976 356.4} {123.552 179.28 127.872 352.08} {127.872 352.08 249.264 356.4} {2.16 352.08 123.552 356.4} {123.552 356.4 127.872 529.2} {2.16 529.2 123.552 533.52} {249.264 356.4 253.584 529.2} {127.872 529.2 249.264 533.52} {374.976 356.4 379.296 529.2} {253.584 529.2 374.976 533.52} {379.296 529.2 500.688 533.52} {374.976 533.52 379.296 706.32} {249.264 533.52 253.584 706.32} {123.552 533.52 127.872 706.32} {121.392 0.192 123.36 10.8} {247.104 0.192 249.072 10.8} {372.816 0.192 374.784 10.8} {498.528 0.192 500.496 10.8} {498.528 174.96 500.496 187.92} {372.816 174.96 374.784 187.92} {247.104 174.96 249.072 187.92} {121.392 174.96 123.36 187.92} {121.392 352.08 123.36 365.04} {247.104 352.08 249.072 365.04} {372.816 352.08 374.784 365.04} {498.528 352.08 500.496 365.04} {498.528 529.2 500.496 542.16} {372.816 529.2 374.784 542.16} {247.104 529.2 249.072 542.16} {121.392 529.2 123.36 542.16}} -report ./verify_rpt/pg_drc_after_filler.rpt
zoomBox -254.31150 -220.00200 926.72425 837.27700
zoomBox -97.01475 12.76350 756.28375 776.64775
zoomBox 16.63225 181.24300 633.14050 733.14950
zoomBox 209.15125 352.03200 530.97250 640.13075
zoomBox 286.09500 402.75000 518.61075 610.90125
zoomBox 102.65450 281.83350 548.08225 680.58650
zoomBox 168.48325 404.12650 400.99975 612.27850
zoomBox 188.61200 466.95775 309.98750 575.61475
zoomBox 201.15400 492.82925 275.69400 559.55850
zoomBox 185.94550 467.19925 307.32175 575.85700
zoomBox 149.71250 406.37975 382.23150 614.53400
zoomBox 91.36800 287.84325 1022.29000 786.61100
zoomBox -40.73825 19.44550 1475.11300 831.60550
zoomBox 5.12350 109.94900 1293.59750 800.28525
zoomBox 36.62500 222.52325 967.54750 721.29125
zoomBox 75.82900 362.62300 561.77650 622.98300
zoomBox 96.29350 435.75550 349.96125 571.66525
zoomBox 99.64550 447.73525 315.26350 563.25875
zoomBox 106.38850 467.40350 262.17275 550.86925
zoomBox 93.16800 434.61500 346.83650 570.52500
zoomBox 50.21275 328.08100 621.91800 634.38825
zoomBox 1.53450 207.75150 932.46125 706.52175
zoomBox -77.72950 11.81500 1438.12925 823.97900
zoomBox -170.68625 -70.49400 1612.67700 884.99300
zoomBox -26.16100 58.53850 1262.31900 748.87800
fit
