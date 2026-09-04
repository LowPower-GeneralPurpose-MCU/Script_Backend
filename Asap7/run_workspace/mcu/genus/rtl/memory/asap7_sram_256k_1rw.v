`timescale 1ns / 1ps

// 256-KiB memory composed exclusively of ASAP7 1RW SRAM hard macros.
//
// Address map:
//   addr[17:12] = bank number 0..63
//   addr[11:2]  = 1024-word row address
//   addr[1:0]   = byte offset; the AXI front-end requires word alignment
//
// All 64 macro instances share address, data, read and write.
// Only one banksel bit is asserted for any request.
//
// The selected macro dataout is latched by the hard macro on a synchronous read.

module asap7_sram_256k_1rw (
    input  wire        clk,
    input  wire        read,
    input  wire        write,
    input  wire [17:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    asap7_sram_1rw #(
        .ADDR_W (16),
        .DATA_W (32)
    ) u_bank_array (
        .clk   (clk),
        .read  (read),
        .write (write),
        .addr  (addr[17:2]),
        .wdata (wdata),
        .rdata (rdata)
    );

endmodule
