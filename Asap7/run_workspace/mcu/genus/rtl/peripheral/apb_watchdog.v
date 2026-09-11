`timescale 1ns / 1ps

// =============================================================================
// apb_watchdog - bo dem nguoc, bao IRQ va/hoac reset he thong khi chay ve 0.
//
// MOT MIEN CLOCK DUY NHAT (2026-09-11). Truoc day bo dem chay bang rtc_clk
// 32.768 kHz trong mien rieng, noi voi pclk qua cdc_pulse (feed) va
// cdc_sync_bit (irq). Gio moi flop chay bang pclk; bo dem chi giam o chu ky co
// `rtc_tick` - xung mot chu ky pclk, moi chu ky rtc mot lan, do top_soc tao ra
// bang cach lay mau chan rtc_clk. Nghia cua WDT_LOAD (don vi = chu ky RTC) vi
// the KHONG doi, firmware khong phai sua.
//
// Doi lai: watchdog khong con doc lap voi clock he thong. Neu clock he thong
// chet thi watchdog chet theo - chip nay khong co nguon clock thu hai de lam
// watchdog doc lap.
// =============================================================================
module apb_watchdog #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire pclk, presetn, psel, penable, pwrite,
    input  wire [ADDR_WIDTH-1:0] paddr,
    input  wire [DATA_WIDTH-1:0] pwdata,
    input  wire [3:0] pstrb,
    output reg  [DATA_WIDTH-1:0] prdata,
    output reg  pready, pslverr,

    // Xung mot chu ky pclk cho moi chu ky RTC (xem top_soc.v, rtc_tick).
    input  wire rtc_tick,
    output wire wdt_irq,
    output wire wdt_rst
);
    reg [31:0] wdt_load;
    reg wdt_en, wdt_ie, wdt_re;
    reg wdt_feed;

    reg [31:0] counter;
    reg irq_out, rst_out;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            counter <= 32'b0; irq_out <= 1'b0; rst_out <= 1'b0;
        end else begin
            if (wdt_feed) begin
                counter <= wdt_load;
                irq_out <= 1'b0;
                rst_out <= 1'b0;
            end else if (wdt_en && rtc_tick && counter > 0) begin
                counter <= counter - 1;
            end

            if (wdt_en && counter == 0) begin
                if (wdt_ie) irq_out <= 1'b1;
                if (wdt_re) rst_out <= 1'b1;
            end
        end
    end

    assign wdt_irq = irq_out;
    assign wdt_rst = rst_out;

    // Logic thanh ghi APB
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            wdt_load <= 32'hFFFF_FFFF;
            wdt_en <= 1'b0; wdt_ie <= 1'b0; wdt_re <= 1'b0; wdt_feed <= 1'b0;
            pready <= 1'b0; prdata <= 32'b0; pslverr <= 1'b0;
        end else begin
            pready <= psel && penable;
            pslverr <= 1'b0;
            wdt_feed <= 1'b0;

            if (psel && penable && pwrite) begin
                case (paddr[11:0])
                    12'h000: wdt_load <= pwdata;
                    12'h004: begin wdt_en <= pwdata[0]; wdt_ie <= pwdata[1]; wdt_re <= pwdata[2]; end
                    12'h008: if (pwdata == 32'h5A5A5A5A) wdt_feed <= 1'b1;
                    default: pslverr <= 1'b1;
                endcase
            end

            if (psel && !penable && !pwrite) begin
                case (paddr[11:0])
                    12'h000: prdata <= wdt_load;
                    12'h004: prdata <= {29'b0, wdt_re, wdt_ie, wdt_en};
                    default: prdata <= 32'b0;
                endcase
            end
        end
    end
endmodule
