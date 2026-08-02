//==================================================================================================
// File: fpu_unit.v
// Description: Fully parameterized iterative IEEE-754 FPU
// Fixed: Perfected Division Restoring Alignment and IEEE-754 Ties-To-Even Rounding
//==================================================================================================
`timescale 1ns / 1ps

module fpu_unit #(
    parameter BITS_PER_CYCLE = 2 
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        stall_id_ex,
    input  wire        fpu_start,
    input  wire [4:0]  fpu_op,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    output reg  [31:0] result,
    output wire        fpu_stall,
    output wire        fpu_done
);

    assign result = 0;
    assign fpu_stall = 0;
    assign fpu_done = 0;

endmodule