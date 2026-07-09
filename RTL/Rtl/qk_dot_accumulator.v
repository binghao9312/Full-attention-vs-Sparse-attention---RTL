`timescale 1ns/1ps

module qk_dot_accumulator #(
    parameter IDX_WIDTH = 8,
    parameter FEATURE_DIM = 4,
    parameter DATA_WIDTH = 8,
    parameter SCORE_WIDTH = 32
) (
    input wire clk,
    input wire rst_n,
    input wire pair_valid,
    input wire [IDX_WIDTH-1:0] q_idx,
    input wire [IDX_WIDTH-1:0] k_idx,
    input wire [FEATURE_DIM*DATA_WIDTH-1:0] q_feature_vector,
    input wire [FEATURE_DIM*DATA_WIDTH-1:0] k_feature_vector,
    output reg score_valid,
    output reg [IDX_WIDTH-1:0] score_q_idx,
    output reg [IDX_WIDTH-1:0] score_k_idx,
    output reg [SCORE_WIDTH-1:0] attention_score
);
    genvar d;
    integer acc_idx;
    wire [SCORE_WIDTH-1:0] product [0:FEATURE_DIM-1];
    reg stage0_valid;
    reg [IDX_WIDTH-1:0] stage0_q_idx;
    reg [IDX_WIDTH-1:0] stage0_k_idx;
    reg [FEATURE_DIM*DATA_WIDTH-1:0] stage0_q_feature_vector;
    reg [FEATURE_DIM*DATA_WIDTH-1:0] stage0_k_feature_vector;
    reg stage1_valid;
    reg [IDX_WIDTH-1:0] stage1_q_idx;
    reg [IDX_WIDTH-1:0] stage1_k_idx;
    reg [SCORE_WIDTH-1:0] product_reg [0:FEATURE_DIM-1];
    reg [SCORE_WIDTH-1:0] score_sum;

    generate
        for (d = 0; d < FEATURE_DIM; d = d + 1) begin : gen_dot_lane
            wire [DATA_WIDTH-1:0] q_value;
            wire [DATA_WIDTH-1:0] k_value;

            assign q_value = stage0_q_feature_vector[d*DATA_WIDTH +: DATA_WIDTH];
            assign k_value = stage0_k_feature_vector[d*DATA_WIDTH +: DATA_WIDTH];
            assign product[d] = q_value * k_value;
        end
    endgenerate

    always @(*) begin
        score_sum = {SCORE_WIDTH{1'b0}};
        for (acc_idx = 0; acc_idx < FEATURE_DIM; acc_idx = acc_idx + 1) begin
            score_sum = score_sum + product_reg[acc_idx];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_valid <= 1'b0;
            stage0_q_idx <= {IDX_WIDTH{1'b0}};
            stage0_k_idx <= {IDX_WIDTH{1'b0}};
            stage0_q_feature_vector <= {FEATURE_DIM*DATA_WIDTH{1'b0}};
            stage0_k_feature_vector <= {FEATURE_DIM*DATA_WIDTH{1'b0}};
            stage1_valid <= 1'b0;
            stage1_q_idx <= {IDX_WIDTH{1'b0}};
            stage1_k_idx <= {IDX_WIDTH{1'b0}};
            score_valid <= 1'b0;
            score_q_idx <= {IDX_WIDTH{1'b0}};
            score_k_idx <= {IDX_WIDTH{1'b0}};
            attention_score <= {SCORE_WIDTH{1'b0}};
            for (acc_idx = 0; acc_idx < FEATURE_DIM; acc_idx = acc_idx + 1) begin
                product_reg[acc_idx] <= {SCORE_WIDTH{1'b0}};
            end
        end else begin
            stage0_valid <= pair_valid;
            stage0_q_idx <= q_idx;
            stage0_k_idx <= k_idx;
            stage0_q_feature_vector <= q_feature_vector;
            stage0_k_feature_vector <= k_feature_vector;

            stage1_valid <= stage0_valid;
            stage1_q_idx <= stage0_q_idx;
            stage1_k_idx <= stage0_k_idx;
            
            for (acc_idx = 0; acc_idx < FEATURE_DIM; acc_idx = acc_idx + 1) begin
                product_reg[acc_idx] <= product[acc_idx];
            end

            score_valid <= stage1_valid;
            score_q_idx <= stage1_q_idx;
            score_k_idx <= stage1_k_idx;
            attention_score <= score_sum;
        end
    end
endmodule
