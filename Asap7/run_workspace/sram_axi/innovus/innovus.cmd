#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Aug 27 12:00:22 2026                
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
set init_lef_file {/home/user1/Desktop/Script_Backend/Asap7/asap7/asap7sc7p5t_28/techlef_misc/asap7_tech_4x_201209.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_L_4x_220121a.lef /home/user1/Desktop/asap7/asap7sc7p5t_28/LEF/scaled/asap7sc7p5t_28_R_4x_220121a.lef /home/user1/Desktop/asap7/asap7_sram_0p0/generated/LEF/4xLEF/srambank_256x4x32_6t122.lef.4x.lef}
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
floorPlan -s 135.168 75.264 2.16 2.16 2.16 2.16
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_proto.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_hierFP_final.rpt
checkFPlan -reportUtil -outFile ./verify_rpt/reportUtil_before_pnr.rpt
setAddStripeMode -reset
setAddStripeMode -allow_jog none
clearGlobalNets
setPinConstraint -cell axi_ram -corner_to_pin_distance 8
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
applyGlobalNets
verify_drc -check_only special -layer_range {M4 M5} -area {{500.688 0.0 625.248 770.832} {0.0 706.32 500.688 770.832} {0.0 0.0 2.16 706.32} {2.16 0.0 500.688 2.16} {123.552 2.16 127.872 174.96} {2.16 174.96 123.552 179.28} {249.264 2.16 253.584 174.96} {127.872 174.96 249.264 179.28} {374.976 2.16 379.296 174.96} {253.584 174.96 374.976 179.28} {379.296 174.96 500.688 179.28} {374.976 179.28 379.296 352.08} {379.296 352.08 500.688 356.4} {249.264 179.28 253.584 352.08} {253.584 352.08 374.976 356.4} {123.552 179.28 127.872 352.08} {127.872 352.08 249.264 356.4} {2.16 352.08 123.552 356.4} {123.552 356.4 127.872 529.2} {2.16 529.2 123.552 533.52} {249.264 356.4 253.584 529.2} {127.872 529.2 249.264 533.52} {374.976 356.4 379.296 529.2} {253.584 529.2 374.976 533.52} {379.296 529.2 500.688 533.52} {374.976 533.52 379.296 706.32} {249.264 533.52 253.584 706.32} {123.552 533.52 127.872 706.32}} -report ./verify_rpt/sram_m4_interface_drc.rpt
verify_drc -check_only special -layer_range {M6 M9} -area {{500.688 0.0 625.248 770.832} {0.0 706.32 500.688 770.832} {0.0 0.0 2.16 706.32} {2.16 0.0 500.688 2.16} {123.552 2.16 127.872 174.96} {2.16 174.96 123.552 179.28} {249.264 2.16 253.584 174.96} {127.872 174.96 249.264 179.28} {374.976 2.16 379.296 174.96} {253.584 174.96 374.976 179.28} {379.296 174.96 500.688 179.28} {374.976 179.28 379.296 352.08} {379.296 352.08 500.688 356.4} {249.264 179.28 253.584 352.08} {253.584 352.08 374.976 356.4} {123.552 179.28 127.872 352.08} {127.872 352.08 249.264 356.4} {2.16 352.08 123.552 356.4} {123.552 356.4 127.872 529.2} {2.16 529.2 123.552 533.52} {249.264 356.4 253.584 529.2} {127.872 529.2 249.264 533.52} {374.976 356.4 379.296 529.2} {253.584 529.2 374.976 533.52} {379.296 529.2 500.688 533.52} {374.976 533.52 379.296 706.32} {249.264 533.52 253.584 706.32} {123.552 533.52 127.872 706.32}} -report ./verify_rpt/pg_drc_after_trim.rpt
verify_drc -check_only special -layer_range {M1 M9} -area {{500.688 0.0 625.248 770.832} {0.0 706.32 500.688 770.832} {0.0 0.0 2.16 706.32} {2.16 0.0 500.688 2.16} {123.552 2.16 127.872 174.96} {2.16 174.96 123.552 179.28} {249.264 2.16 253.584 174.96} {127.872 174.96 249.264 179.28} {374.976 2.16 379.296 174.96} {253.584 174.96 374.976 179.28} {379.296 174.96 500.688 179.28} {374.976 179.28 379.296 352.08} {379.296 352.08 500.688 356.4} {249.264 179.28 253.584 352.08} {253.584 352.08 374.976 356.4} {123.552 179.28 127.872 352.08} {127.872 352.08 249.264 356.4} {2.16 352.08 123.552 356.4} {123.552 356.4 127.872 529.2} {2.16 529.2 123.552 533.52} {249.264 356.4 253.584 529.2} {127.872 529.2 249.264 533.52} {374.976 356.4 379.296 529.2} {253.584 529.2 374.976 533.52} {379.296 529.2 500.688 533.52} {374.976 533.52 379.296 706.32} {249.264 533.52 253.584 706.32} {123.552 533.52 127.872 706.32}} -report ./verify_rpt/pg_drc_after_trim_full.rpt
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
all_constraint_modes -active
set_interactive_constraint_modes $active_constraint_modes
set_propagated_clock [all_clocks]
set_interactive_constraint_modes {}
optDesign -prefix postCTS -postCTS -setup -hold
checkPlace ./verify_rpt/checkPlace_after_postcts.rpt
applyGlobalNets
timeDesign -postCTS -outDir ./reports/timing_postCTS
timeDesign -postCTS -hold -outDir ./reports/timing_postCTS_hold
saveDesign ./saved/axi_ram_postCTS.enc
setSIMode -enable_delay_report true -enable_glitch_report true
setAnalysisMode -analysisType onChipVariation
setDelayCalMode -SIAware true -equivalent_waveform_model propagation
setExtractRCMode -engine postRoute -effortLevel medium
setNanoRouteMode -reset
setDesignMode -bottomRoutingLayer 2 -topRoutingLayer 7
setNanoRouteMode -quiet -route_strict_honor_route_rule true -route_strictly_honor_1d_routing true -route_detail_no_taper_in_layers 2:7 -route_detail_no_taper_on_output_pin true -route_use_auto_via false -route_with_via_only_for_stdcell_pin true -route_detail_use_multi_cut_via_effort low -route_with_timing_driven true -route_with_si_driven true -route_detail_fix_antenna false -route_detail_merge_abutting_cut true -route_detail_end_iteration 20
routeDesign -globalDetail
routeDesign -viaOpt -wireOpt -trackOpt
setNanoRouteMode -quiet -route_with_timing_driven true -route_with_si_driven true
ecoRoute -fix_drc
setOptMode -fixCap true -fixTran true -fixFanoutLoad true -fixGlitch true -reclaimArea false -setupTargetSlack 0.020 -holdTargetSlack 0.020 -detailDrvFailureReason true -detailDrvFailureReasonMaxNumNets 100
optDesign -postRoute -setup -hold -prefix postRoute
applyGlobalNets
ecoRoute -fix_drc
timeDesign -postRoute -outDir ./reports/timing_postRoute_preSiRepair
applyGlobalNets
setFillerMode -reset
setFillerMode -core {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -add_fillers_with_drc false -fitGap true -honorPrerouteAsObs true -diffCellViol true
addFiller -cell {FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L} -prefix FILLER -honorPrerouteAsObs true -diffCellViol true
checkFiller -file ./verify_rpt/checkFiller_after_filler.rpt
checkPlace ./verify_rpt/checkPlace_after_filler.rpt
verify_drc -report ./verify_rpt/pg_drc_after_filler.rpt
timeDesign -postRoute -outDir ./reports/timing_postRoute
timeDesign -postRoute -hold -outDir ./reports/timing_postRoute_hold
report_noise -bumpy_waveform -threshold 0 > ./reports/bumpy_transition_postRoute.rpt
verify_drc -report ./verify_rpt/drc_postroute.rpt
verifyConnectivity -type all -error 1000 -warning 1000 -report ./verify_rpt/connectivity_postroute.rpt
saveDesign ./saved/axi_ram_routed.enc
