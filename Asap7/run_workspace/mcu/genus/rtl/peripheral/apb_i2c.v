`timescale 1ns / 1ps

// MOT MIEN CLOCK DUY NHAT (2026-09-11): FSM I2C chay cung pclk voi giao dien
// APB. Truoc day no nam o i2c_clk rieng, noi qua async_fifo, cdc_pulse (lenh
// START) va cdc_sync_bit (busy/done/ack). Mot clock thi cac duong do noi thang.
// Thoi gian mot pha SCL = (PRER + 1) chu ky pclk. SDA van qua 2FF - dong bo
// chan vao.
module apb_i2c #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)(
    // --- Giao dien APB ---
    input wire                   pclk,
    input wire                   presetn,
    input wire                   psel,
    input wire                   penable,
    input wire                   pwrite,
    input wire [ADDR_WIDTH-1:0]  paddr,
    input wire [DATA_WIDTH-1:0]  pwdata,
    input wire [3:0]             pstrb,
    output reg [DATA_WIDTH-1:0]  prdata,
    output reg                   pready,
    output reg                   pslverr,

    // Giao diện vật lý I2C
    output wire                  scl_o, 
    output wire                  scl_oen,
    input  wire                  scl_i,
    output wire                  sda_o, 
    output wire                  sda_oen,
    input  wire                  sda_i,
    
    // Tín hiệu Ngắt và DMA
    output wire                  i2c_irq,
    output wire                  dma_tx_req,
    output wire                  dma_rx_req
);
    localparam S_IDLE=0, S_START_A=1, S_START_B=2, S_START_C=3;
    localparam S_BIT_A=4, S_BIT_B=5, S_BIT_C=6, S_BIT_D=7;
    localparam S_ACK_A=8, S_ACK_B=9, S_ACK_C=10, S_ACK_D=11;
    localparam S_STOP_A=12, S_STOP_B=13, S_STOP_C=14;
    
    // --- Thanh ghi nội bộ miền APB ---
    reg [15:0] reg_prer;
    reg [7:0]  reg_cmd;
    reg [7:0]  reg_stat;
    reg [3:0]  reg_dma_int;
    
    // Tín hiệu FIFO miền APB
    wire tx_fifo_full, rx_fifo_empty;
    wire [7:0] rx_fifo_rdata;
    reg  tx_fifo_wr, rx_fifo_rd;
    reg  cmd_trigger_pclk;

    // --- Tín hiệu I2C Core ---
    wire tx_fifo_empty, rx_fifo_full;
    wire [7:0] tx_fifo_rdata_core;
    reg  tx_fifo_rd_core, rx_fifo_wr_core;

    reg  core_done;
    reg  core_rx_ack;
    reg [7:0] core_rx_data;

    reg [4:0]  state;
    wire core_busy = (state != S_IDLE);

    // ============================================================
    // 1. APB INTERFACE & REGISTER LOGIC
    // ============================================================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            reg_prer <= 16'hFFFF; reg_cmd <= 0; reg_stat <= 0; reg_dma_int <= 0;
            pready <= 0; prdata <= 0; pslverr <= 0;
            tx_fifo_wr <= 0; rx_fifo_rd <= 0; cmd_trigger_pclk <= 0;
        end else begin
            pready <= psel && penable;
            pslverr <= 0;
            tx_fifo_wr <= 0; rx_fifo_rd <= 0; cmd_trigger_pclk <= 0;

            if (psel && penable && pwrite) begin
                case (paddr[11:0])
                    12'h000: reg_prer <= pwdata[15:0];
                    12'h004: if (!tx_fifo_full) tx_fifo_wr <= 1;
                    12'h00C: begin 
                        reg_cmd <= pwdata[7:0]; 
                        if (pwdata[7:4] != 4'b0000) begin
                            cmd_trigger_pclk <= 1;
                            reg_stat[1] <= 1; // Transferring
                        end
                    end
                    12'h010: if (pwdata[0]) reg_stat[0] <= 0; // Clear IRQ
                    12'h014: reg_dma_int <= pwdata[3:0];
                    default: pslverr <= 1;
                endcase
            end
            
            if (psel && !penable && !pwrite) begin
                case (paddr[11:0])
                    12'h000: prdata <= {16'b0, reg_prer};
                    12'h008: begin 
                        prdata <= {24'b0, rx_fifo_rdata}; 
                        if (!rx_fifo_empty) rx_fifo_rd <= 1;
                    end
                    12'h00C: prdata <= {24'b0, reg_cmd};
                    12'h010: prdata <= {24'b0, reg_stat[7], core_busy, 2'b0, rx_fifo_empty, tx_fifo_full, reg_stat[1:0]};
                    12'h014: prdata <= {28'b0, reg_dma_int};
                    default: prdata <= 0;
                endcase
            end

            // Cập nhật trạng thái khi Core báo xong
            if (core_done) begin
                reg_stat[1] <= 1'b0; // Clear Transferring
                reg_stat[0] <= 1'b1; // Set IRQ
                reg_stat[7] <= core_rx_ack;
                reg_cmd     <= 8'b0;
            end
        end
    end

    // ============================================================
    // 2. NỐI APB <-> CORE (cùng pclk)
    // ============================================================
    // PRER / CMD được FSM đọc thẳng, và xung START cũng đi thẳng.
    //
    // HAI THỨ NÀY PHẢI BỎ CÙNG NHAU. Bản cũ chép reg_cmd sang miền i2c_clk trễ
    // một chu kỳ, còn xung START đi qua cdc_pulse chậm 2-3 chu kỳ, nên khi xung
    // tới thì bản sao đã có lệnh MỚI. Nếu chỉ bỏ cdc_pulse mà giữ bản sao,
    // xung sẽ tới TRƯỚC và FSM chạy theo lệnh CŨ. cmd_trigger_pclk và reg_cmd
    // được ghi ở cùng một cạnh clock, nên đọc thẳng cả hai là nhất quán.
    wire [15:0] reg_prer_core    = reg_prer;
    wire [7:0]  reg_cmd_core     = reg_cmd;
    wire        cmd_trigger_core = cmd_trigger_pclk;

    assign dma_tx_req = (!tx_fifo_full)  & reg_dma_int[2];
    assign dma_rx_req = (!rx_fifo_empty) & reg_dma_int[3];
    assign i2c_irq    = (reg_stat[0] & reg_dma_int[0]) | (!rx_fifo_empty & reg_dma_int[1]);

    sync_fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) u_tx_fifo (
        .clk(pclk),                 .rst_n(presetn),
        .data_i(pwdata[7:0]),       .data_o(tx_fifo_rdata_core),
        .wr_valid_i(tx_fifo_wr),    .rd_valid_i(tx_fifo_rd_core),
        .full_o(tx_fifo_full),      .empty_o(tx_fifo_empty),
        .wr_ready_o(), .rd_ready_o(), .almost_empty_o(), .almost_full_o(),
        .counter()
    );

    sync_fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) u_rx_fifo (
        .clk(pclk),                 .rst_n(presetn),
        .data_i(core_rx_data),      .data_o(rx_fifo_rdata),
        .wr_valid_i(rx_fifo_wr_core),.rd_valid_i(rx_fifo_rd),
        .full_o(rx_fifo_full),      .empty_o(rx_fifo_empty),
        .wr_ready_o(), .rd_ready_o(), .almost_empty_o(), .almost_full_o(),
        .counter()
    );

    // ============================================================
    // 3. I2C CORE FSM
    // ============================================================

    // Lọc và lấy mẫu chân tín hiệu vào SDA
    reg sda_s1, sda_s2;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) {sda_s2, sda_s1} <= 2'b11;
        else          {sda_s2, sda_s1} <= {sda_s1, sda_i};
    end

    reg scl_out, sda_out;
    assign scl_oen = scl_out; 
    assign sda_oen = sda_out;
    assign scl_o   = 1'b0;    
    assign sda_o   = 1'b0;
    
    reg [15:0] tick_cnt;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_reg;
    
    wire tick = (tick_cnt == 0);

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            state <= S_IDLE; tick_cnt <= 0; bit_cnt <= 0;
            scl_out <= 1; sda_out <= 1;
            core_done <= 0; shift_reg <= 0;
            tx_fifo_rd_core <= 0; rx_fifo_wr_core <= 0;
            core_rx_ack <= 0; core_rx_data <= 0;
        end else begin
            core_done <= 0;
            tx_fifo_rd_core <= 0;
            rx_fifo_wr_core <= 0;

            if (tick) tick_cnt <= reg_prer_core;
            else if (state != S_IDLE) tick_cnt <= tick_cnt - 1;

            case (state)
                S_IDLE: begin
                    if (cmd_trigger_core) begin
                        if (reg_cmd_core[4] && !tx_fifo_empty) begin
                            shift_reg <= tx_fifo_rdata_core;
                            tx_fifo_rd_core <= 1;
                        end else begin
                            shift_reg <= 8'hFF;
                        end
                        
                        bit_cnt <= 7;
                        tick_cnt <= reg_prer_core;
                        
                        if (reg_cmd_core[7]) state <= S_START_A;
                        else                 state <= S_BIT_A;
                    end
                end

                S_START_A: if (tick) begin sda_out <= 1; scl_out <= 1; state <= S_START_B; end
                S_START_B: if (tick) begin sda_out <= 0; scl_out <= 1; state <= S_START_C; end
                S_START_C: if (tick) begin sda_out <= 0; scl_out <= 0; 
                                           if (reg_cmd_core[4] || reg_cmd_core[5]) state <= S_BIT_A;
                                           else begin core_done <= 1; state <= S_IDLE; end
                                     end

                S_BIT_A: if (tick) begin scl_out <= 0; sda_out <= reg_cmd_core[4] ? shift_reg[7] : 1'b1; state <= S_BIT_B; end
                S_BIT_B: if (tick) begin scl_out <= 1; state <= S_BIT_C; end
                S_BIT_C: if (tick) begin shift_reg <= {shift_reg[6:0], sda_s2}; state <= S_BIT_D; end
                S_BIT_D: if (tick) begin scl_out <= 0;
                            if (bit_cnt == 0) state <= S_ACK_A;
                            else begin bit_cnt <= bit_cnt - 1; state <= S_BIT_A; end
                         end

                S_ACK_A: if (tick) begin scl_out <= 0; sda_out <= reg_cmd_core[5] ? reg_cmd_core[3] : 1'b1; state <= S_ACK_B; end
                S_ACK_B: if (tick) begin scl_out <= 1; state <= S_ACK_C; end
                S_ACK_C: if (tick) begin 
                            core_rx_ack <= sda_s2;
                            core_rx_data <= shift_reg;
                            if (reg_cmd_core[5] && !rx_fifo_full) rx_fifo_wr_core <= 1;
                            state <= S_ACK_D; 
                         end
                S_ACK_D: if (tick) begin scl_out <= 0; sda_out <= 1; 
                            if (reg_cmd_core[6]) state <= S_STOP_A;
                            else begin core_done <= 1; state <= S_IDLE; end
                         end

                S_STOP_A: if (tick) begin sda_out <= 0; scl_out <= 0; state <= S_STOP_B; end
                S_STOP_B: if (tick) begin sda_out <= 0; scl_out <= 1; state <= S_STOP_C; end
                S_STOP_C: if (tick) begin sda_out <= 1; scl_out <= 1; core_done <= 1; state <= S_IDLE; end
            endcase
        end
    end

endmodule
