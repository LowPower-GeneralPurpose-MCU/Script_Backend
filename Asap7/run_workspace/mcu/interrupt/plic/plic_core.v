`timescale 1ns / 1ps
`include "plic_defines.vh"

module plic_core #(
    parameter ALGORITHM = "SEQUENTIAL" // Lựa chọn: "SEQUENTIAL", "BINARY_TREE", "MATRIX"
)(
    input  wire                           clk_i,
    input  wire                           rst_ni,
    
    // Từ ngoại vi
    input  wire [`PLIC_NUM_SRC-1:0]       irq_src_i,
    
    // Từ/Đến Register Bus
    input  wire [(`PLIC_NUM_SRC*`PLIC_PRIO_WIDTH)-1:0] prio_i_flat,
    input  wire [`PLIC_NUM_SRC-1:0]       ie_i,
    input  wire [`PLIC_PRIO_WIDTH-1:0]    threshold_i,
    input  wire [31:0]                    claim_i,
    input  wire [31:0]                    complete_i,
    
    output wire [`PLIC_NUM_SRC-1:0]       ip_o,
    output wire [31:0]                    claim_id_o,
    output wire                           irq_o
);

    // Giải mã mảng phẳng
    wire [`PLIC_PRIO_WIDTH-1:0] prio_i [0:`PLIC_NUM_SRC-1];
    genvar g;
    generate
        for (g = 0; g < `PLIC_NUM_SRC; g = g + 1) begin : gen_prio_unpack
            assign prio_i[g] = prio_i_flat[g*`PLIC_PRIO_WIDTH +: `PLIC_PRIO_WIDTH];
        end
    endgenerate

    reg [`PLIC_NUM_SRC-1:0] ip_q;
    reg [`PLIC_NUM_SRC-1:0] claim_pulse;
    reg [`PLIC_NUM_SRC-1:0] complete_pulse;
    integer i;

    // --- GATEWAY LOGIC (Pending) ---
    always @(*) begin
        for (i = 0; i < `PLIC_NUM_SRC; i = i + 1) begin
            claim_pulse[i]    = (claim_i == i) && (claim_i != 0);
            complete_pulse[i] = (complete_i == i) && (complete_i != 0);
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ip_q <= 0;
        end else begin
            for (i = 1; i < `PLIC_NUM_SRC; i = i + 1) begin
                if (irq_src_i[i])        ip_q[i] <= 1'b1;  
                else if (claim_pulse[i]) ip_q[i] <= 1'b0;  
            end
        end
    end
    assign ip_o = ip_q;

    // --- TARGET ARBITER (3 Options) ---
    wire [`PLIC_PRIO_WIDTH-1:0] max_prio;
    wire [31:0]                 best_id;

    generate
        // ==========================================
        // OPTION 1: SEQUENTIAL (Quét tuần tự)
        // ==========================================
        if (ALGORITHM == "SEQUENTIAL") begin : gen_sequential
            reg [`PLIC_PRIO_WIDTH-1:0] seq_max_prio;
            reg [31:0]                 seq_best_id;
            integer j;
            always @(*) begin
                seq_max_prio = 0;
                seq_best_id  = 0;
                // Quét ngược từ trên xuống. Dùng '>=' để ID nhỏ hơn được ưu tiên khi hòa.
                for (j = `PLIC_NUM_SRC-1; j > 0; j = j - 1) begin
                    if (ip_q[j] && ie_i[j]) begin
                        if (prio_i[j] >= seq_max_prio) begin
                            seq_max_prio = prio_i[j];
                            seq_best_id  = j;
                        end
                    end
                end
            end
            assign max_prio = seq_max_prio;
            assign best_id  = seq_best_id;
        end
        
        // ==========================================
        // OPTION 2: MATRIX (Ma trận so sánh chéo)
        // ==========================================
        else if (ALGORITHM == "MATRIX") begin : gen_matrix
            wire [`PLIC_NUM_SRC-1:0] candidate;
            genvar row, col;
            for (row = 1; row < `PLIC_NUM_SRC; row = row + 1) begin : gen_mat_row
                wire [`PLIC_NUM_SRC-1:0] wins;
                for (col = 1; col < `PLIC_NUM_SRC; col = col + 1) begin : gen_mat_col
                    if (row == col) begin
                        assign wins[col] = 1'b1;
                    end else begin
                        wire valid_col = ip_q[col] && ie_i[col];
                        // row thắng col nếu col không hợp lệ, hoặc ưu tiên row cao hơn, 
                        // hoặc (ưu tiên bằng nhau và ID row nhỏ hơn ID col)
                        assign wins[col] = (!valid_col) ||
                                           (prio_i[row] > prio_i[col]) ||
                                           ((prio_i[row] == prio_i[col]) && (row < col));
                    end
                end
                // Ứng cử viên thắng cuộc là kẻ thắng TẤT CẢ mọi đối thủ
                assign candidate[row] = (ip_q[row] && ie_i[row]) ? (&wins[1:`PLIC_NUM_SRC-1]) : 1'b0;
            end
            
            // Chuyển mã One-hot của candidate thành Binary ID
            reg [31:0] mat_best_id;
            reg [`PLIC_PRIO_WIDTH-1:0] mat_max_prio;
            integer k;
            always @(*) begin
                mat_best_id = 0;
                mat_max_prio = 0;
                for (k = 1; k < `PLIC_NUM_SRC; k = k + 1) begin
                    if (candidate[k]) begin
                        mat_best_id = k;
                        mat_max_prio = prio_i[k];
                    end
                end
            end
            assign best_id  = mat_best_id;
            assign max_prio = mat_max_prio;
        end
        
        // ==========================================
        // OPTION 3: BINARY TREE (Cây đấu loại)
        // ==========================================
        else if (ALGORITHM == "BINARY_TREE") begin : gen_tree
            // Fixed five-stage 32-leaf tree. Separate arrays per stage make
            // the acyclic structure explicit to both lint and synthesis.
            wire [`PLIC_PRIO_WIDTH-1:0] leaf_prio [0:31];
            wire [31:0]                 leaf_id   [0:31];
            wire [`PLIC_PRIO_WIDTH-1:0] level1_prio [0:15];
            wire [31:0]                 level1_id   [0:15];
            wire [`PLIC_PRIO_WIDTH-1:0] level2_prio [0:7];
            wire [31:0]                 level2_id   [0:7];
            wire [`PLIC_PRIO_WIDTH-1:0] level3_prio [0:3];
            wire [31:0]                 level3_id   [0:3];
            wire [`PLIC_PRIO_WIDTH-1:0] level4_prio [0:1];
            wire [31:0]                 level4_id   [0:1];

            genvar n;
            for (n = 0; n < 32; n = n + 1) begin : gen_leaves
                if (n > 0 && n < `PLIC_NUM_SRC) begin
                    assign leaf_prio[n] =
                        (ip_q[n] && ie_i[n]) ? prio_i[n] : 0;
                    assign leaf_id[n] =
                        (ip_q[n] && ie_i[n]) ? n : 0;
                end else begin
                    assign leaf_prio[n] = 0;
                    assign leaf_id[n]   = 0;
                end
            end

            for (n = 0; n < 16; n = n + 1) begin : gen_level1
                wire left_wins =
                    (leaf_prio[2*n] > leaf_prio[2*n + 1]) ||
                    ((leaf_prio[2*n] == leaf_prio[2*n + 1]) &&
                     (leaf_id[2*n] != 0) &&
                     ((leaf_id[2*n + 1] == 0) ||
                      (leaf_id[2*n] < leaf_id[2*n + 1])));
                assign level1_prio[n] =
                    left_wins ? leaf_prio[2*n] : leaf_prio[2*n + 1];
                assign level1_id[n] =
                    left_wins ? leaf_id[2*n] : leaf_id[2*n + 1];
            end

            for (n = 0; n < 8; n = n + 1) begin : gen_level2
                wire left_wins =
                    (level1_prio[2*n] > level1_prio[2*n + 1]) ||
                    ((level1_prio[2*n] == level1_prio[2*n + 1]) &&
                     (level1_id[2*n] != 0) &&
                     ((level1_id[2*n + 1] == 0) ||
                      (level1_id[2*n] < level1_id[2*n + 1])));
                assign level2_prio[n] =
                    left_wins ? level1_prio[2*n] : level1_prio[2*n + 1];
                assign level2_id[n] =
                    left_wins ? level1_id[2*n] : level1_id[2*n + 1];
            end

            for (n = 0; n < 4; n = n + 1) begin : gen_level3
                wire left_wins =
                    (level2_prio[2*n] > level2_prio[2*n + 1]) ||
                    ((level2_prio[2*n] == level2_prio[2*n + 1]) &&
                     (level2_id[2*n] != 0) &&
                     ((level2_id[2*n + 1] == 0) ||
                      (level2_id[2*n] < level2_id[2*n + 1])));
                assign level3_prio[n] =
                    left_wins ? level2_prio[2*n] : level2_prio[2*n + 1];
                assign level3_id[n] =
                    left_wins ? level2_id[2*n] : level2_id[2*n + 1];
            end

            for (n = 0; n < 2; n = n + 1) begin : gen_level4
                wire left_wins =
                    (level3_prio[2*n] > level3_prio[2*n + 1]) ||
                    ((level3_prio[2*n] == level3_prio[2*n + 1]) &&
                     (level3_id[2*n] != 0) &&
                     ((level3_id[2*n + 1] == 0) ||
                      (level3_id[2*n] < level3_id[2*n + 1])));
                assign level4_prio[n] =
                    left_wins ? level3_prio[2*n] : level3_prio[2*n + 1];
                assign level4_id[n] =
                    left_wins ? level3_id[2*n] : level3_id[2*n + 1];
            end

            wire root_left_wins =
                (level4_prio[0] > level4_prio[1]) ||
                ((level4_prio[0] == level4_prio[1]) &&
                 (level4_id[0] != 0) &&
                 ((level4_id[1] == 0) || (level4_id[0] < level4_id[1])));
            assign max_prio =
                root_left_wins ? level4_prio[0] : level4_prio[1];
            assign best_id =
                root_left_wins ? level4_id[0] : level4_id[1];
        end
    endgenerate

    // Kích hoạt ngắt khi quán quân vượt ngưỡng Threshold
    assign claim_id_o = best_id;
    assign irq_o      = (max_prio > threshold_i) && (best_id != 0);

endmodule
