`timescale 1ns / 1ps

// Generic single-port (1RW) memory array built from ASAP7 hard macros.
//
// One srambank_256x4x32_6t122 holds 1024 words x 32 bits (4 KiB).  Deeper
// arrays stack banks; the upper address bits select the bank and only the
// selected bank sees banksel asserted, so exactly one macro is active per
// request.
//
//   addr[ADDR_W-1:10] = bank number   (only when ADDR_W > 10)
//   addr[9:0]         = row inside the selected bank
//
// DATA_W may be narrower than 32.  Unused macro write bits are tied low and
// the unused read bits are dropped, which is how the cache tag arrays reuse
// this array without a second macro variant.
//
// The macro registers dataout: rdata is valid the cycle after `read` and holds
// its value until the next read.

module asap7_sram_1rw #(
    parameter ADDR_W = 10,
    parameter DATA_W = 32
)(
    input  wire               clk,
    input  wire               read,
    input  wire               write,
    input  wire [ADDR_W-1:0]  addr,
    input  wire [DATA_W-1:0]  wdata,
    output wire [DATA_W-1:0]  rdata
);

    localparam ROW_ADDR_W  = 10;
    localparam BANK_ADDR_W = (ADDR_W > ROW_ADDR_W) ? (ADDR_W - ROW_ADDR_W) : 1;
    localparam NUM_BANKS   = (ADDR_W > ROW_ADDR_W) ? (1 << (ADDR_W - ROW_ADDR_W)) : 1;

    wire [BANK_ADDR_W-1:0] bank_sel;
    wire [ROW_ADDR_W-1:0]  row_addr;

    generate
        if (ADDR_W > ROW_ADDR_W) begin : G_BANKED_ADDR
            assign bank_sel = addr[ADDR_W-1:ROW_ADDR_W];
            assign row_addr = addr[ROW_ADDR_W-1:0];
        end else begin : G_SINGLE_ADDR
            assign bank_sel = {BANK_ADDR_W{1'b0}};
            assign row_addr = {{(ROW_ADDR_W-ADDR_W){1'b0}}, addr};
        end
    endgenerate

    // The read bank must be remembered because the macro output appears one
    // cycle after the request.
    reg [BANK_ADDR_W-1:0] read_bank_q;

    always @(posedge clk) begin
        if (read)
            read_bank_q <= bank_sel;
    end

    wire [31:0] macro_wdata;

    assign macro_wdata[DATA_W-1:0] = wdata;
    generate
        if (DATA_W < 32) begin : G_WDATA_PAD
            assign macro_wdata[31:DATA_W] = {(32-DATA_W){1'b0}};
        end
    endgenerate

    wire [31:0] bank_rdata [0:NUM_BANKS-1];
    wire [31:0] rdata_full;

    genvar i;
    generate
        for (i = 0; i < NUM_BANKS; i = i + 1) begin : G_SRAM_BANK
            srambank_256x4x32_6t122 u_sram (
                .clk     (clk),
                .ADDRESS (row_addr),
                .wd      (macro_wdata),
                .banksel ((read || write) && (bank_sel == i)),
                .read    (read),
                .write   (write),
                .dataout (bank_rdata[i])
            );
        end
    endgenerate

    generate
        if (NUM_BANKS == 1) begin : G_SINGLE_RDATA
            assign rdata_full = bank_rdata[0];
        end else begin : G_BANKED_RDATA
            assign rdata_full = bank_rdata[read_bank_q];
        end
    endgenerate

    assign rdata = rdata_full[DATA_W-1:0];

endmodule
