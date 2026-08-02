//==================================================================================================
// File: multiplier_divider_unit.v
//==================================================================================================
module multiplier (
    input clk,
    input reset_n,
    input stall_id_ex,
    input md_type,
    input [31:0] alu_in1,
    input [31:0] alu_in2,
    input [2:0] md_operation,
    output [31:0] md_result,
    output md_alu_stall,
    output md_alu_done
);

    assign md_result = 0;
    assign md_alu_stall = 0;
    assign md_alu_done = 0;

endmodule


module divider (
    input clk,
    input reset_n,
    input stall_id_ex,
    input md_type,
    input [31:0] alu_in1,
    input [31:0] alu_in2,
    input [2:0] md_operation,
    output [31:0] md_result,
    output md_alu_stall,
    output md_alu_done
);

    assign md_result = 0;
    assign md_alu_stall = 0;
    assign md_alu_done = 0;

endmodule