`timescale 1ns / 1ps

// 64-KiB memory composed exclusively of ASAP7 1RW SRAM hard macros.
//
// Address map:
//   addr[15:12] = bank number 0..15
//   addr[11:2]  = 1024-word row address
//   addr[1:0]   = byte offset; the AXI front-end requires word alignment
//
// All 16 macro instances share address, data, read and write.
// Only one banksel bit is asserted for any request.
//
// The selected macro dataout is latched by the hard macro on a synchronous read.

module asap7_sram_64k_1rw (
    input  wire        clk,
    input  wire        read,
    input  wire        write,
    input  wire [15:0] addr,
    input  wire [31:0] wdata,
    output wire  [31:0] rdata
);

    wire [3:0] bank_sel = addr[15:12];
    wire [9:0] row_addr = addr[11:2];

    reg [3:0] read_bank_q;

    wire [31:0] bank_rdata [0:15];

    always @(posedge clk) begin
        if (read)
            read_bank_q <= bank_sel;
    end

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : G_SRAM_BANK
            srambank_256x4x32_6t122 u_sram (
                .clk     (clk),
                .ADDRESS (row_addr),
                .wd      (wdata),
                .banksel ((read || write) && (bank_sel == i)),
                .read    (read),
                .write   (write),
                .dataout (bank_rdata[i])
            );
        end
    endgenerate

    assign rdata = bank_rdata[read_bank_q];

endmodule
