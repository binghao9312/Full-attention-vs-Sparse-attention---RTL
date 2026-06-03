`timescale 1ns/1ps

module qk_dot_product #(
    parameter IDX_WIDTH = 8,
    parameter FEATURE_DIM = 4,
    parameter SCORE_WIDTH = 32
) (
    input wire pair_valid,
    input wire [IDX_WIDTH-1:0] q_idx,
    input wire [IDX_WIDTH-1:0] k_idx,
    output wire score_valid,
    output reg [SCORE_WIDTH-1:0] attention_score
);
    integer d;
    reg [SCORE_WIDTH-1:0] q_value;
    reg [SCORE_WIDTH-1:0] k_value;

    assign score_valid = pair_valid;

    always @(*) begin
        attention_score = {SCORE_WIDTH{1'b0}};
        for (d = 0; d < FEATURE_DIM; d = d + 1) begin
            q_value = q_idx + d + 1;
            k_value = k_idx + d + 2;
            attention_score = attention_score + (q_value * k_value);
        end
    end
endmodule
