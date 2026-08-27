#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Aug 27 19:12:21 2026                
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
setLibraryUnit -time 1ns -cap 1pf
set init_lef_file {/home/user1/Desktop/Script_Backend/Asap7/asap7/asap7sc7p5t_28/techlef_misc/asap7_tech_4x_201209.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_L_4x_220121a.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_R_4x_220121a.lef /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LEF/4xLEF/srambank_256x4x32_6t122.lef.4x.lef}
set init_top_cell axi_ram
set init_gnd_net VSS
set init_pwr_net VDD
set init_mmmc_file ./tcl/viewDefinition.tcl
set init_verilog ./outputs/axi_ram_syn.v
set init_layout_view layout
set init_design_uniquify 1
set ::TimeLib::tsgMarkCellLatchConstructFlag 1
set conf_qxconf_file NULL
set conf_qxlib_file NULL
set distributed_client_message_echo 1
set distributed_mmmc_disable_reports_auto_redirection 0
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
addHaloToBlock -allBlock 1.08 1.08 1.08 1.08
addHaloToBlock -allBlock 1.08 1.08 1.08 1.08
snapFPlan -block
cutRow -area {2.16 2.16 123.552 174.96}
cutRow -area {127.872 2.16 249.264 174.96}
cutRow -area {253.584 2.16 374.976 174.96}
cutRow -area {379.296 2.16 500.688 174.96}
cutRow -area {379.296 179.28 500.688 352.08}
cutRow -area {253.584 179.28 374.976 352.08}
cutRow -area {127.872 179.28 249.264 352.08}
cutRow -area {2.16 179.28 123.552 352.08}
cutRow -area {2.16 356.4 123.552 529.2}
cutRow -area {127.872 356.4 249.264 529.2}
cutRow -area {253.584 356.4 374.976 529.2}
cutRow -area {379.296 356.4 500.688 529.2}
cutRow -area {379.296 533.52 500.688 706.32}
cutRow -area {253.584 533.52 374.976 706.32}
cutRow -area {127.872 533.52 249.264 706.32}
cutRow -area {2.16 533.52 123.552 706.32}
createPlaceBlockage -name SRAM_ISLAND_GROUP_BLOCKAGE -type soft -noCutByCore -box {2.16 2.16 502.848 708.48}
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
zoomBox 69.02650 105.41850 593.05825 574.53875
zoomBox 131.85950 167.87500 510.47250 506.81450
zoomBox 164.48000 216.94150 438.02800 461.82525
zoomBox 197.25250 266.23700 365.24525 416.62625
zoomBox 222.18375 303.73750 309.87700 382.24175
zoomBox 232.68950 319.58400 286.54450 367.79575
zoomBox 239.14125 329.31575 272.21525 358.92400
zoomBox 244.04925 336.71875 261.31450 352.17475
zoomBox 244.85325 337.93150 259.52875 351.06925
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
zoomBox 239.16325 334.11425 263.05975 355.50675
fit
zoomBox -191.35425 175.85200 780.55125 696.57775
zoomBox 22.02150 353.49175 529.36225 625.31375
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
set_max_fanout $SRAM_OUTPUT_MAX_FANOUT $sram_out_pins
setOptMode -reclaimArea true -leakageToDynamicRatio 0.5 -powerEffort high -fixFanoutLoad true
optDesign -prefix preCTS -preCTS
refinePlace
checkPlace ./verify_rpt/checkPlace_before_cts.rpt
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
clock_opt_design
refinePlace
checkPlace ./verify_rpt/checkPlace_after_cts.rpt
applyGlobalNets
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
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_postcts.rpt
timeDesign -postCTS -outDir ./reports/timing_postCTS
timeDesign -postCTS -hold -outDir ./reports/timing_postCTS_hold
saveDesign ./saved/axi_ram_postCTS.enc
setSIMode -enable_delay_report true -enable_glitch_report true
setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -SIAware true -equivalent_waveform_model propagation
setExtractRCMode -engine postRoute -effortLevel medium
setNanoRouteMode -reset
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
setAttribute -net FE_OFN710_n_54 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_addr[11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {mem_wdata[31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[0][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[1][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[2][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[3][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[4][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[5][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[6][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[7][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[8][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[9][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[10][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[11][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[12][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[13][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[14][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][0]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][1]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][2]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][3]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][4]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][5]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][6]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][7]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][8]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][9]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][10]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][11]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][12]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][13]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][14]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][15]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][16]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][17]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][18]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][19]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][20]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][21]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][22]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][23]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][24]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][25]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][26]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][27]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][28]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][29]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][30]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net {u_mem/bank_rdata[15][31]} -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN799_mem_wdata_30 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN800_mem_wdata_10 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN802_mem_wdata_1 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN805_mem_wdata_13 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN806_mem_wdata_13 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN808_mem_wdata_12 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN810_mem_wdata_9 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN812_FE_OFN625_mem_wdata_0 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN813_mem_wdata_4 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_GLN816_mem_wdata_11 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN18_mem_wdata_8 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN19_mem_wdata_7 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN22_mem_wdata_4 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN23_mem_wdata_3 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN26_mem_wdata_0 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN43_mem_addr_11 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN44_mem_addr_11 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN45_mem_addr_10 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN46_mem_addr_10 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN47_mem_addr_9 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN48_mem_addr_9 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN49_mem_addr_8 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN50_mem_addr_8 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN51_mem_addr_7 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN52_mem_addr_7 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN53_mem_addr_6 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN54_mem_addr_6 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN55_mem_addr_5 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN56_mem_addr_5 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN57_mem_addr_4 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN58_mem_addr_4 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN59_mem_addr_3 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN60_mem_addr_3 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN61_mem_addr_2 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN62_mem_addr_2 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN98_mem_wdata_31 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN100_mem_wdata_30 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN107_mem_wdata_27 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN108_mem_wdata_26 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN109_mem_wdata_26 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN112_mem_wdata_24 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN113_mem_wdata_24 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN115_mem_wdata_22 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN116_mem_wdata_21 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN117_mem_wdata_21 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN118_mem_wdata_20 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN120_mem_wdata_19 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN122_mem_wdata_18 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN127_mem_wdata_16 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN130_mem_wdata_15 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN132_mem_wdata_13 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN133_mem_wdata_12 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN134_mem_wdata_11 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN136_mem_wdata_9 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN138_n_415 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN141_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN145_mem_wdata_29 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN148_mem_wdata_27 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN149_mem_wdata_27 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN152_mem_wdata_31 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN153_mem_wdata_31 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN165_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN166_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN171_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN190_n_616 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN619_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN620_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN622_mem_wdata_1 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN638_mem_wdata_8 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN640_mem_wdata_6 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN658_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN660_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN664_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN667_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN669_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN673_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN674_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN675_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN677_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN684_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN685_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN686_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN687_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN690_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN691_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN693_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN701_mem_wdata_25 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN702_mem_wdata_25 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN706_mem_wdata_7 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN707_mem_wdata_7 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN711_n_54 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN732_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN737_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN738_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN740_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN755_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN756_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN758_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN759_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN760_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN761_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN762_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN763_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN764_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN774_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN775_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN776_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN777_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN778_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN779_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN780_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN781_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN782_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN783_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN784_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN785_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN786_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN787_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN795_n_409 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN796_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN820_mem_wdata_3 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN821_mem_wdata_3 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN822_mem_wdata_3 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN823_mem_wdata_5 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN824_mem_wdata_5 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN826_mem_wdata_6 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN827_mem_wdata_6 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN828_mem_wdata_26 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN829_mem_wdata_26 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN833_mem_wdata_28 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN834_mem_wdata_28 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN835_mem_wdata_28 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN836_mem_wdata_31 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN844_mem_wdata_29 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN845_mem_wdata_29 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN846_mem_wdata_29 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN888_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN889_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN904_mem_wdata_2 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN921_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN924_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN925_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN928_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN930_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN931_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN954_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN956_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN977_FE_GLN804_mem_wdata_14 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN978_FE_GLN804_mem_wdata_14 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN979_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN980_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN981_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN982_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN984_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN985_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN987_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN988_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN989_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN992_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN994_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_OFN995_n -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_PHN1190_mem_wdata_29 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_PHN1252_mem_wdata_3 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_PHN1268_mem_wdata_5 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/FE_PHN1275_mem_wdata_13 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_407 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_408 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_410 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_411 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_412 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_413 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_414 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_416 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_417 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_418 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_419 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_420 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_421 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setAttribute -net u_mem/n_456 -bottom_preferred_routing_layer 4 -top_preferred_routing_layer 7 -preferred_routing_layer_effort high
setNanoRouteMode -quiet -route_strict_honor_route_rule true -route_strictly_honor_1d_routing true -route_detail_no_taper_in_layers 2:7 -route_detail_no_taper_on_output_pin true -route_use_auto_via false -route_with_via_only_for_stdcell_pin true -route_detail_use_multi_cut_via_effort low -route_with_timing_driven true -route_with_si_driven true -route_detail_fix_antenna false -route_detail_merge_abutting_cut true -route_detail_end_iteration 20
routeDesign -globalDetail
routeDesign -viaOpt -wireOpt -trackOpt
setNanoRouteMode -quiet -route_with_timing_driven true -route_with_si_driven true
ecoRoute -fix_drc
setOptMode -fixCap true -fixTran true -fixFanoutLoad true -fixGlitch true -reclaimArea false -setupTargetSlack 0.020 -holdTargetSlack 0.020 -detailDrvFailureReason true -detailDrvFailureReasonMaxNumNets 100
optDesign -postRoute -setup -hold -prefix postRoute
applyGlobalNets
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_postroute_opt.rpt
ecoRoute -fix_drc
timeDesign -postRoute -outDir ./reports/timing_postRoute_preSiRepair
applyGlobalNets
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_si_repair.rpt
setFillerMode -reset
setFillerMode -core {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -add_fillers_with_drc false -fitGap true -honorPrerouteAsObs true -diffCellViol true
addFiller -cell {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -prefix FILLER -honorPrerouteAsObs true -diffCellViol true
checkFiller -file ./verify_rpt/checkFiller_after_filler.rpt
checkPlace ./verify_rpt/checkPlace_after_filler.rpt
applyGlobalNets
clearDrc
applyGlobalNets
verifyConnectivity -type special -net {VDD VSS} -allPGPinPort -noUnroutedNet -report ./verify_rpt/pg_connectivity_after_filler.rpt
verify_drc -report ./verify_rpt/pg_drc_after_filler.rpt
timeDesign -postRoute -outDir ./reports/timing_postRoute
timeDesign -postRoute -hold -outDir ./reports/timing_postRoute_hold
report_noise -bumpy_waveform -threshold 0 > ./reports/bumpy_transition_postRoute.rpt
verify_drc -report ./verify_rpt/drc_postroute.rpt
ecoRoute -fix_drc
optDesign -postRoute -drv -prefix drvFix1
verify_drc -report ./verify_rpt/drc_postroute.rpt
ecoRoute -fix_drc
optDesign -postRoute -drv -prefix drvFix2
verify_drc -report ./verify_rpt/drc_postroute.rpt
verifyConnectivity -type all -error 1000 -warning 1000 -report ./verify_rpt/connectivity_postroute.rpt
saveDesign ./saved/axi_ram_routed.enc
zoomBox -47.55100 241.00625 778.56875 683.62325
zoomBox -257.00250 122.79950 886.41650 735.41850
zoomBox -444.17925 -41.00450 1138.40775 806.91100
