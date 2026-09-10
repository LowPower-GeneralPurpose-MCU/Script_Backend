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
//
// Each way gets one srambank_128x4x20_6t122 (512 x 20) when the tag fits in it,
// as it does for the 16 KiB 2-way caches (512 sets x 19 bits).  Anything larger
// falls back to the 1024 x 32 data macro through asap7_sram_1rw.
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
    localparam USE_TAG_MACRO = (ADDR_W <= 9) && (TAG_W <= 20);

    genvar w;
    generate
        for (w = 0; w < WAYS; w = w + 1) begin : G_TAG_WAY
            if (USE_TAG_MACRO) begin : G_TAG_MACRO
                asap7_sram_tag_512x20 #(
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
            end else begin : G_DATA_MACRO
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
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Tag macro: one srambank_128x4x20_6t122 = 512 words x 20 bits.
//
// A 512 x 19-bit tag uses 95% of it, against 29.7% of the 1024 x 32 macro the
// tag arrays used before; the 4x LEF is 64 x 120.96 um (7741 um^2) against
// 121.392 x 172.8 um (20976 um^2).  Same pins and read behaviour as the data
// macro: synchronous, dataout valid the cycle after `read`, no bit-write mask.
// Shallower arrays tie the upper address bits low; narrower tags tie the
// unused write bits low and drop the unused read bits.
// -----------------------------------------------------------------------------
module asap7_sram_tag_512x20 #(
    parameter ADDR_W = 9,
    parameter DATA_W = 19
)(
    input  wire               clk,
    input  wire               read,
    input  wire               write,
    input  wire [ADDR_W-1:0]  addr,
    input  wire [DATA_W-1:0]  wdata,
    output wire [DATA_W-1:0]  rdata
);
    wire [8:0]  macro_addr;
    wire [19:0] macro_wdata;
    wire [19:0] macro_rdata;

    generate
        if (ADDR_W < 9) begin : G_ADDR_PAD
            assign macro_addr = {{(9-ADDR_W){1'b0}}, addr};
        end else begin : G_ADDR_FULL
            assign macro_addr = addr;
        end
        if (DATA_W < 20) begin : G_WDATA_PAD
            assign macro_wdata = {{(20-DATA_W){1'b0}}, wdata};
        end else begin : G_WDATA_FULL
            assign macro_wdata = wdata;
        end
    endgenerate

    srambank_128x4x20_6t122 u_sram (
        .clk     (clk),
        .ADDRESS (macro_addr),
        .wd      (macro_wdata),
        .banksel (read || write),
        .read    (read),
        .write   (write),
        .dataout (macro_rdata)
    );

    assign rdata = macro_rdata[DATA_W-1:0];
endmodule
