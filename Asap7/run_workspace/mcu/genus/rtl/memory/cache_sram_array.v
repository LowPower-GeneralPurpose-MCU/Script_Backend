`timescale 1ns / 1ps

// Cache storage arrays built from ASAP7 1RW SRAM hard macros.
//
// Both arrays give every way its own macro group so that a lookup can read all
// ways in the same cycle.  The macros are synchronous: the array output is
// valid the cycle after `read` is asserted and holds until the next read, which
// is why the caches run a dedicated LOOKUP state.
//
// The macro has no byte-write mask, so a data array write always replaces a
// full 32-bit word.  Sub-word CPU stores are merged by the cache using the word
// returned by the lookup read.

// -----------------------------------------------------------------------------
// Data array: one 32-bit word per row, addressed by {index, word_idx}.
// -----------------------------------------------------------------------------
module cache_data_array #(
    parameter WAYS   = 2,
    parameter ADDR_W = 12
)(
    input  wire                  clk,
    input  wire [ADDR_W-1:0]     addr,
    input  wire                  read,
    input  wire [WAYS-1:0]       write_en,
    input  wire [31:0]           write_data,
    output wire [(WAYS*32)-1:0]  read_data
);
    genvar w;
    generate
        for (w = 0; w < WAYS; w = w + 1) begin : G_DATA_WAY
            asap7_sram_1rw #(
                .ADDR_W (ADDR_W),
                .DATA_W (32)
            ) u_sram (
                .clk   (clk),
                .read  (read && !write_en[w]),
                .write (write_en[w]),
                .addr  (addr),
                .wdata (write_data),
                .rdata (read_data[w*32 +: 32])
            );
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Tag array: one tag per set and way, addressed by index.
//
// Valid bits are deliberately NOT stored here.  SRAM contents are undefined out
// of reset, so the caches keep valid state in resettable flip-flops and only the
// tag itself lives in the macro.
// -----------------------------------------------------------------------------
module cache_tag_array #(
    parameter WAYS   = 2,
    parameter ADDR_W = 10,
    parameter TAG_W  = 18
)(
    input  wire                     clk,
    input  wire [ADDR_W-1:0]        addr,
    input  wire                     read,
    input  wire [WAYS-1:0]          write_en,
    input  wire [TAG_W-1:0]         write_tag,
    output wire [(WAYS*TAG_W)-1:0]  read_tag
);
    genvar w;
    generate
        for (w = 0; w < WAYS; w = w + 1) begin : G_TAG_WAY
            asap7_sram_1rw #(
                .ADDR_W (ADDR_W),
                .DATA_W (TAG_W)
            ) u_sram (
                .clk   (clk),
                .read  (read && !write_en[w]),
                .write (write_en[w]),
                .addr  (addr),
                .wdata (write_tag),
                .rdata (read_tag[w*TAG_W +: TAG_W])
            );
        end
    endgenerate
endmodule
