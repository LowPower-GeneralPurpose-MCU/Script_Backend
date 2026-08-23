`timescale 1ns / 1ps

// 128-KiB memory composed exclusively of ASAP7 1RW SRAM hard macros.
//
// Address map:
//   addr[16:12] = bank number 0..31
//   addr[11:2]  = 1024-word row address
//   addr[1:0]   = byte offset; the AXI front-end requires word alignment
//
// All 32 macro instances share address, data, read and write.
// Only one banksel bit is asserted for any request.
//
// The selected macro dataout is latched by the hard macro on a synchronous read.

module asap7_sram_128k_1rw (
    input  wire        clk,
    input  wire        read,
    input  wire        write,
    input  wire [16:0] addr,
    input  wire [31:0] wdata,
    output wire  [31:0] rdata
);

    wire [4:0] bank_sel = addr[16:12];
    wire [9:0] row_addr = addr[11:2];

    reg [4:0] read_bank_q;

    wire [31:0] bank_rdata [0:31];

    always @(posedge clk) begin
        if (read)
            read_bank_q <= bank_sel;
    end

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : G_SRAM_BANK
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

