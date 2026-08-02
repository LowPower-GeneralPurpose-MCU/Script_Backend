# ####################################################################

#  Created by Genus(TM) Synthesis Solution 23.14-s090_1 on Sun Aug 02 16:02:36 JST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1fF
set_units -time 1ps

# Set the current design
current_design axi_ram

create_clock -name "CLK" -period 1000.0 -waveform {0.0 500.0} [get_ports clk]
set_clock_transition -min 10.0 [get_clocks CLK]
set_clock_transition -max 40.0 [get_clocks CLK]
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
set_load -pin_load 10.0 [get_ports s_axi_awready]
set_load -pin_load 10.0 [get_ports s_axi_wready]
set_load -pin_load 10.0 [get_ports {s_axi_bid[4]}]
set_load -pin_load 10.0 [get_ports {s_axi_bid[3]}]
set_load -pin_load 10.0 [get_ports {s_axi_bid[2]}]
set_load -pin_load 10.0 [get_ports {s_axi_bid[1]}]
set_load -pin_load 10.0 [get_ports {s_axi_bid[0]}]
set_load -pin_load 10.0 [get_ports {s_axi_bresp[1]}]
set_load -pin_load 10.0 [get_ports {s_axi_bresp[0]}]
set_load -pin_load 10.0 [get_ports s_axi_bvalid]
set_load -pin_load 10.0 [get_ports s_axi_arready]
set_load -pin_load 10.0 [get_ports {s_axi_rid[4]}]
set_load -pin_load 10.0 [get_ports {s_axi_rid[3]}]
set_load -pin_load 10.0 [get_ports {s_axi_rid[2]}]
set_load -pin_load 10.0 [get_ports {s_axi_rid[1]}]
set_load -pin_load 10.0 [get_ports {s_axi_rid[0]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[31]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[30]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[29]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[28]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[27]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[26]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[25]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[24]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[23]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[22]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[21]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[20]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[19]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[18]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[17]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[16]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[15]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[14]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[13]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[12]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[11]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[10]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[9]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[8]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[7]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[6]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[5]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[4]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[3]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[2]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[1]}]
set_load -pin_load 10.0 [get_ports {s_axi_rdata[0]}]
set_load -pin_load 10.0 [get_ports {s_axi_rresp[1]}]
set_load -pin_load 10.0 [get_ports {s_axi_rresp[0]}]
set_load -pin_load 10.0 [get_ports s_axi_rlast]
set_load -pin_load 10.0 [get_ports s_axi_rvalid]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awid[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awid[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awid[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awid[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awid[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[31]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[30]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[29]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[28]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[27]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[26]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[25]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[24]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[23]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[22]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[21]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[20]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[19]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[18]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[17]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[16]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[15]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[14]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[13]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[12]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[11]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[10]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[9]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[8]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awaddr[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awlen[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awsize[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awsize[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awsize[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awburst[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awburst[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_awlock]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awcache[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awcache[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awcache[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awcache[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awprot[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awprot[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awprot[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awqos[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awqos[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awqos[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awqos[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awregion[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awregion[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awregion[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_awregion[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_awvalid]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[31]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[30]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[29]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[28]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[27]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[26]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[25]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[24]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[23]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[22]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[21]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[20]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[19]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[18]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[17]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[16]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[15]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[14]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[13]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[12]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[11]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[10]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[9]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[8]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wdata[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wstrb[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wstrb[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wstrb[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_wstrb[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_wlast]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_wvalid]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_bready]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arid[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arid[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arid[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arid[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arid[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[31]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[30]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[29]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[28]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[27]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[26]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[25]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[24]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[23]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[22]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[21]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[20]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[19]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[18]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[17]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[16]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[15]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[14]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[13]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[12]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[11]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[10]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[9]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[8]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_araddr[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arlen[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arsize[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arsize[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arsize[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arburst[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arburst[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_arlock]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arcache[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arcache[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arcache[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arcache[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arprot[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arprot[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arprot[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arqos[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arqos[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arqos[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arqos[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arregion[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arregion[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arregion[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports {s_axi_arregion[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_arvalid]
set_input_delay -clock [get_clocks CLK] -add_delay -max 250.0 [get_ports s_axi_rready]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awid[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awid[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awid[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awid[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awid[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[31]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[30]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[29]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[28]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[27]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[26]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[25]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[24]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[23]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[22]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[21]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[20]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[19]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[18]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[17]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[16]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[15]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[14]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[13]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[12]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[11]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[10]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[9]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[8]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awaddr[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awlen[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awsize[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awsize[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awsize[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awburst[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awburst[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_awlock]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awcache[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awcache[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awcache[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awcache[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awprot[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awprot[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awprot[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awqos[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awqos[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awqos[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awqos[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awregion[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awregion[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awregion[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_awregion[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_awvalid]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[31]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[30]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[29]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[28]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[27]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[26]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[25]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[24]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[23]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[22]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[21]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[20]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[19]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[18]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[17]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[16]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[15]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[14]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[13]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[12]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[11]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[10]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[9]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[8]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wdata[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wstrb[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wstrb[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wstrb[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_wstrb[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_wlast]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_wvalid]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_bready]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arid[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arid[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arid[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arid[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arid[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[31]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[30]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[29]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[28]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[27]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[26]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[25]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[24]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[23]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[22]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[21]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[20]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[19]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[18]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[17]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[16]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[15]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[14]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[13]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[12]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[11]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[10]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[9]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[8]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_araddr[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[7]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arlen[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arsize[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arsize[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arsize[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arburst[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arburst[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_arlock]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arcache[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arcache[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arcache[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arcache[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arprot[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arprot[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arprot[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arqos[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arqos[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arqos[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arqos[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arregion[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arregion[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arregion[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports {s_axi_arregion[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_arvalid]
set_input_delay -clock [get_clocks CLK] -add_delay -min 100.0 [get_ports s_axi_rready]
set_input_delay -clock [get_clocks CLK] -add_delay -max 100.0 [get_ports rst_n]
set_input_delay -clock [get_clocks CLK] -add_delay -min 0.0 [get_ports rst_n]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports s_axi_awready]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports s_axi_wready]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_bid[4]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_bid[3]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_bid[2]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_bid[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_bid[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_bresp[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_bresp[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports s_axi_bvalid]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports s_axi_arready]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rid[4]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rid[3]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rid[2]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rid[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rid[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[31]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[30]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[29]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[28]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[27]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[26]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[25]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[24]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[23]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[22]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[21]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[20]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[19]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[18]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[17]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[16]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[15]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[14]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[13]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[12]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[11]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[10]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[9]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[8]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[7]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[6]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[5]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[4]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[3]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[2]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rdata[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rresp[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports {s_axi_rresp[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports s_axi_rlast]
set_output_delay -clock [get_clocks CLK] -add_delay -max 300.0 [get_ports s_axi_rvalid]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports s_axi_awready]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports s_axi_wready]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_bid[4]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_bid[3]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_bid[2]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_bid[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_bid[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_bresp[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_bresp[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports s_axi_bvalid]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports s_axi_arready]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rid[4]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rid[3]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rid[2]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rid[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rid[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[31]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[30]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[29]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[28]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[27]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[26]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[25]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[24]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[23]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[22]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[21]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[20]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[19]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[18]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[17]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[16]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[15]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[14]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[13]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[12]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[11]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[10]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[9]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[8]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[7]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[6]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[5]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[4]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[3]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[2]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rdata[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rresp[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports {s_axi_rresp[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports s_axi_rlast]
set_output_delay -clock [get_clocks CLK] -add_delay -min 150.0 [get_ports s_axi_rvalid]
set_max_fanout 20.000 [current_design]
set_max_transition 500.0 [current_design]
set_input_transition -min 10.0 [get_ports rst_n]
set_input_transition -max 40.0 [get_ports rst_n]
set_input_transition -min 10.0 [get_ports {s_axi_awid[4]}]
set_input_transition -max 40.0 [get_ports {s_axi_awid[4]}]
set_input_transition -min 10.0 [get_ports {s_axi_awid[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_awid[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_awid[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awid[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awid[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awid[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awid[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awid[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[31]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[31]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[30]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[30]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[29]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[29]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[28]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[28]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[27]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[27]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[26]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[26]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[25]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[25]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[24]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[24]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[23]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[23]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[22]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[22]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[21]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[21]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[20]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[20]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[19]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[19]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[18]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[18]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[17]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[17]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[16]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[16]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[15]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[15]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[14]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[14]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[13]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[13]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[12]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[12]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[11]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[11]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[10]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[10]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[9]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[9]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[8]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[8]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[7]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[7]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[6]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[6]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[5]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[5]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[4]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[4]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awaddr[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awaddr[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[7]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[7]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[6]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[6]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[5]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[5]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[4]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[4]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awlen[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awlen[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_awsize[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awsize[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awsize[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awsize[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awsize[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awsize[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_awburst[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awburst[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awburst[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awburst[0]}]
set_input_transition -min 10.0 [get_ports s_axi_awlock]
set_input_transition -max 40.0 [get_ports s_axi_awlock]
set_input_transition -min 10.0 [get_ports {s_axi_awcache[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_awcache[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_awcache[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awcache[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awcache[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awcache[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awcache[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awcache[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_awprot[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awprot[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awprot[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awprot[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awprot[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awprot[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_awqos[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_awqos[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_awqos[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awqos[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awqos[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awqos[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awqos[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awqos[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_awregion[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_awregion[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_awregion[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_awregion[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_awregion[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_awregion[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_awregion[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_awregion[0]}]
set_input_transition -min 10.0 [get_ports s_axi_awvalid]
set_input_transition -max 40.0 [get_ports s_axi_awvalid]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[31]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[31]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[30]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[30]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[29]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[29]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[28]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[28]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[27]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[27]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[26]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[26]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[25]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[25]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[24]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[24]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[23]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[23]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[22]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[22]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[21]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[21]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[20]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[20]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[19]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[19]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[18]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[18]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[17]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[17]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[16]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[16]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[15]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[15]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[14]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[14]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[13]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[13]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[12]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[12]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[11]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[11]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[10]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[10]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[9]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[9]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[8]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[8]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[7]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[7]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[6]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[6]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[5]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[5]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[4]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[4]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_wdata[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_wdata[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_wstrb[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_wstrb[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_wstrb[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_wstrb[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_wstrb[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_wstrb[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_wstrb[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_wstrb[0]}]
set_input_transition -min 10.0 [get_ports s_axi_wlast]
set_input_transition -max 40.0 [get_ports s_axi_wlast]
set_input_transition -min 10.0 [get_ports s_axi_wvalid]
set_input_transition -max 40.0 [get_ports s_axi_wvalid]
set_input_transition -min 10.0 [get_ports s_axi_bready]
set_input_transition -max 40.0 [get_ports s_axi_bready]
set_input_transition -min 10.0 [get_ports {s_axi_arid[4]}]
set_input_transition -max 40.0 [get_ports {s_axi_arid[4]}]
set_input_transition -min 10.0 [get_ports {s_axi_arid[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_arid[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_arid[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_arid[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_arid[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arid[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arid[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arid[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[31]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[31]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[30]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[30]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[29]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[29]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[28]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[28]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[27]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[27]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[26]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[26]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[25]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[25]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[24]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[24]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[23]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[23]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[22]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[22]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[21]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[21]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[20]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[20]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[19]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[19]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[18]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[18]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[17]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[17]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[16]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[16]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[15]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[15]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[14]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[14]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[13]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[13]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[12]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[12]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[11]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[11]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[10]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[10]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[9]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[9]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[8]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[8]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[7]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[7]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[6]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[6]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[5]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[5]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[4]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[4]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_araddr[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_araddr[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[7]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[7]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[6]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[6]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[5]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[5]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[4]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[4]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arlen[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arlen[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_arsize[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_arsize[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_arsize[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arsize[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arsize[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arsize[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_arburst[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arburst[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arburst[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arburst[0]}]
set_input_transition -min 10.0 [get_ports s_axi_arlock]
set_input_transition -max 40.0 [get_ports s_axi_arlock]
set_input_transition -min 10.0 [get_ports {s_axi_arcache[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_arcache[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_arcache[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_arcache[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_arcache[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arcache[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arcache[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arcache[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_arprot[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_arprot[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_arprot[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arprot[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arprot[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arprot[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_arqos[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_arqos[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_arqos[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_arqos[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_arqos[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arqos[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arqos[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arqos[0]}]
set_input_transition -min 10.0 [get_ports {s_axi_arregion[3]}]
set_input_transition -max 40.0 [get_ports {s_axi_arregion[3]}]
set_input_transition -min 10.0 [get_ports {s_axi_arregion[2]}]
set_input_transition -max 40.0 [get_ports {s_axi_arregion[2]}]
set_input_transition -min 10.0 [get_ports {s_axi_arregion[1]}]
set_input_transition -max 40.0 [get_ports {s_axi_arregion[1]}]
set_input_transition -min 10.0 [get_ports {s_axi_arregion[0]}]
set_input_transition -max 40.0 [get_ports {s_axi_arregion[0]}]
set_input_transition -min 10.0 [get_ports s_axi_arvalid]
set_input_transition -max 40.0 [get_ports s_axi_arvalid]
set_input_transition -min 10.0 [get_ports s_axi_rready]
set_input_transition -max 40.0 [get_ports s_axi_rready]
set_wire_load_mode "enclosed"
set_clock_latency -source -early 100.0 [get_clocks CLK]
set_clock_latency -source -late 150.0 [get_clocks CLK]
set_clock_uncertainty -setup 50.0 [get_clocks CLK]
set_clock_uncertainty -hold 50.0 [get_clocks CLK]
