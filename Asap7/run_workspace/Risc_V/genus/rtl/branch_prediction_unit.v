//==================================================================================================
// File: branch_prediction_unit.v
// Description: Direct-mapped BTB plus 2-bit BHT for the RV32IM pipeline.
//==================================================================================================

module branch_prediction_unit (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        stall,
    input  wire [31:0] pc_in,
    input  wire        ex_mem_valid,
    input  wire [31:0] ex_mem_pc_in,
    input  wire        ex_mem_branch,
    input  wire        ex_mem_branch_taken,
    input  wire        ex_mem_predict_taken,
    input  wire        ex_mem_btb_hit,
    input  wire [31:0] ex_mem_branch_target,
    output wire        bpu_correct,
    output wire        predict_taken,
    output wire        btb_hit,
    output wire        actual_taken,
    output wire [31:0] predict_target
);
    wire resolved_target_match;

    assign actual_taken = ex_mem_valid && ex_mem_branch && ex_mem_branch_taken;

    // A taken prediction is correct only when both the direction and target
    // match. Invalid EX/MEM bubbles never cause a pipeline flush.
    assign bpu_correct = stall || !ex_mem_valid ||
                         ((ex_mem_predict_taken == actual_taken) &&
                          (!actual_taken ||
                           (ex_mem_btb_hit && resolved_target_match)));

    wire [1:0] update_btb =
        (stall || !ex_mem_valid) ? 2'b00 :
        (ex_mem_branch && actual_taken &&
         (!ex_mem_btb_hit || !ex_mem_predict_taken || !resolved_target_match))
            ? 2'b01 :
        (ex_mem_btb_hit && !ex_mem_branch)
            ? 2'b10 : 2'b00;

    wire update_bht = ex_mem_valid && ex_mem_branch && !stall;

    branch_target_buffer BTB (
        .clk(clk),
        .reset_n(reset_n),
        .pc_in(pc_in),
        .ex_mem_pc_in(ex_mem_pc_in),
        .update_btb(update_btb),
        .actual_target(ex_mem_branch_target),
        .predict_target(predict_target),
        .btb_hit(btb_hit),
        .resolved_target_match(resolved_target_match)
    );

    branch_history_table BHT (
        .clk(clk),
        .reset_n(reset_n),
        .pc_in(pc_in),
        .ex_mem_pc_in(ex_mem_pc_in),
        .update_bht(update_bht),
        .btb_hit(btb_hit),
        .actual_taken(actual_taken),
        .predict_taken(predict_taken)
    );
endmodule


module branch_target_buffer #(
    parameter ENTRY       = 64,
    parameter INDEX       = 6,
    parameter TAG         = 24,
    parameter TARGET_ADDR = 30
) (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [31:0] pc_in,
    input  wire [31:0] ex_mem_pc_in,
    input  wire [1:0]  update_btb,
    input  wire [31:0] actual_target,
    output wire [31:0] predict_target,
    output wire        btb_hit,
    output wire        resolved_target_match
);
    wire [INDEX-1:0] lookup_index = pc_in[INDEX+1:2];
    wire [TAG-1:0]   lookup_tag   = pc_in[31:INDEX+2];
    wire [INDEX-1:0] update_index = ex_mem_pc_in[INDEX+1:2];
    wire [TAG-1:0]   update_tag   = ex_mem_pc_in[31:INDEX+2];

    reg [TAG-1:0]         tags    [0:ENTRY-1];
    reg [TARGET_ADDR-1:0] targets [0:ENTRY-1];
    reg                   valids  [0:ENTRY-1];

    assign btb_hit = valids[lookup_index] &&
                     (tags[lookup_index] == lookup_tag);

    assign predict_target = btb_hit
                          ? {targets[lookup_index], 2'b00}
                          : (pc_in + 32'd4);

    assign resolved_target_match =
        valids[update_index] &&
        (tags[update_index] == update_tag) &&
        (targets[update_index] == actual_target[31:2]);

    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < ENTRY; i = i + 1) begin
                valids[i]  <= 1'b0;
                tags[i]    <= {TAG{1'b0}};
                targets[i] <= {TARGET_ADDR{1'b0}};
            end
        end else if (update_btb == 2'b01) begin
            tags[update_index]    <= update_tag;
            targets[update_index] <= actual_target[31:2];
            valids[update_index]  <= 1'b1;
        end else if (update_btb == 2'b10) begin
            tags[update_index]    <= {TAG{1'b0}};
            targets[update_index] <= {TARGET_ADDR{1'b0}};
            valids[update_index]  <= 1'b0;
        end
    end
endmodule


module branch_history_table #(
    parameter ENTRY   = 16,
    parameter INDEX   = 4,
    parameter PREDICT = 2
) (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [31:0] pc_in,
    input  wire [31:0] ex_mem_pc_in,
    input  wire        update_bht,
    input  wire        btb_hit,
    input  wire        actual_taken,
    output wire        predict_taken
);
    wire [INDEX-1:0] lookup_index = pc_in[INDEX+1:2];
    wire [INDEX-1:0] update_index = ex_mem_pc_in[INDEX+1:2];

    reg [PREDICT-1:0] predicts [0:ENTRY-1];

    assign predict_taken = btb_hit && predicts[lookup_index][PREDICT-1];

    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < ENTRY; i = i + 1) begin
                predicts[i] <= 2'b10;
            end
        end else if (update_bht) begin
            if (actual_taken && (predicts[update_index] != 2'b11)) begin
                predicts[update_index] <= predicts[update_index] + 1'b1;
            end else if (!actual_taken && (predicts[update_index] != 2'b00)) begin
                predicts[update_index] <= predicts[update_index] - 1'b1;
            end
        end
    end
endmodule
