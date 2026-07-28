`timescale 1ps / 1ps

module Multiplier32(
    input  wire        iclk,
    input  wire        rst_n, 
    input  wire [31:0] iA,
    input  wire [31:0] iB,
    output reg  [63:0] oP
);

    

    always @(posedge iclk or negedge rst_n) begin
        if (!rst_n) begin
            oP        <= 64'd0;
        end else begin
            oP        <=  iA * iB;
        end
    end

endmodule
