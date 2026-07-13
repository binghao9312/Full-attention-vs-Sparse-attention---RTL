`timescale 1ns/1ps

module qk_dot_product #(
    parameter IDX_WIDTH = 8,
    parameter FEATURE_INDEX = 0,
    parameter SCORE_WIDTH = 32
) (
    input wire pair_valid,
    input wire [IDX_WIDTH-1:0] q_idx,
    input wire [IDX_WIDTH-1:0] k_idx,
    output wire product_valid,
    output wire [SCORE_WIDTH-1:0] product
);
    localparam VALUE_WIDTH = IDX_WIDTH + 4;

    wire [VALUE_WIDTH-1:0] q_value;
    wire [VALUE_WIDTH-1:0] k_value;

    assign q_value = q_idx + FEATURE_INDEX + 1;
    assign k_value = k_idx + FEATURE_INDEX + 2;
    assign product = q_value * k_value;
    assign product_valid = pair_valid;
endmodule
