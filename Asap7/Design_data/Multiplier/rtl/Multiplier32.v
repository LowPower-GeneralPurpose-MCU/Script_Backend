`timescale 1ps / 1ps

module Multiplier32(
    input  wire        iClk,
    input  wire        rst_n, 
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [63:0] p
);

    reg [31:0] a_reg;
    reg [31:0] b_reg;
    reg [63:0] mult_reg;

    always @(posedge iClk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg    <= 32'd0;
            b_reg    <= 32'd0;
            mult_reg <= 64'd0;
            p        <= 64'd0;
        end else begin
            a_reg    <= a;
            b_reg    <= b;
            mult_reg <= a_reg * b_reg;
            p        <= mult_reg;
        end
    end

endmodule
