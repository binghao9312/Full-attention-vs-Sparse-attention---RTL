`timescale 1ns/1ps

module qkv_feature_mem #(
    parameter SEQ_LEN = 128,
    parameter IDX_WIDTH = 8,
    parameter FEATURE_DIM = 4,
    parameter FEATURE_IDX_WIDTH = 2,
    parameter DATA_WIDTH = 8
) (
    input wire clk,
    input wire qkv_we,
    input wire [1:0] qkv_sel,
    input wire [IDX_WIDTH-1:0] qkv_token_idx,
    input wire [FEATURE_IDX_WIDTH-1:0] qkv_feature_idx,
    input wire [DATA_WIDTH-1:0] qkv_data_in,
    input wire [IDX_WIDTH-1:0] q_read_idx,
    input wire [IDX_WIDTH-1:0] k_read_idx,
    input wire [IDX_WIDTH-1:0] v_read_idx,
    output reg [FEATURE_DIM*DATA_WIDTH-1:0] q_feature_vector,
    output reg [FEATURE_DIM*DATA_WIDTH-1:0] k_feature_vector,
    output reg [FEATURE_DIM*DATA_WIDTH-1:0] v_feature_vector
);
    localparam QKV_SEL_Q = 2'd0;
    localparam QKV_SEL_K = 2'd1;
    localparam QKV_SEL_V = 2'd2;
    localparam MEM_DEPTH = SEQ_LEN * FEATURE_DIM;

    reg [DATA_WIDTH-1:0] q_mem [0:MEM_DEPTH-1];
    reg [DATA_WIDTH-1:0] k_mem [0:MEM_DEPTH-1];
    reg [DATA_WIDTH-1:0] v_mem [0:MEM_DEPTH-1];
    integer dim_idx;
    wire [IDX_WIDTH+FEATURE_IDX_WIDTH-1:0] write_addr;
    wire write_in_range;

    assign write_addr = (qkv_token_idx * FEATURE_DIM) + qkv_feature_idx;
    assign write_in_range = (qkv_token_idx < SEQ_LEN) && (qkv_feature_idx < FEATURE_DIM);

    always @(posedge clk) begin
        if (qkv_we && write_in_range) begin
            if (qkv_sel == QKV_SEL_Q) begin
                q_mem[write_addr] <= qkv_data_in;
            end else if (qkv_sel == QKV_SEL_K) begin
                k_mem[write_addr] <= qkv_data_in;
            end else if (qkv_sel == QKV_SEL_V) begin
                v_mem[write_addr] <= qkv_data_in;
            end else begin
                // unsupported qkv_sel: keep all memories unchanged
            end
        end else if (!qkv_we) begin
            // no write request: keep all memories unchanged
        end else begin
            // out-of-range write request: keep all memories unchanged
        end
    end

    always @(*) begin
        q_feature_vector = {FEATURE_DIM*DATA_WIDTH{1'b0}};
        k_feature_vector = {FEATURE_DIM*DATA_WIDTH{1'b0}};
        v_feature_vector = {FEATURE_DIM*DATA_WIDTH{1'b0}};

        for (dim_idx = 0; dim_idx < FEATURE_DIM; dim_idx = dim_idx + 1) begin
            if (q_read_idx < SEQ_LEN) begin
                q_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =
                    q_mem[(q_read_idx * FEATURE_DIM) + dim_idx];
            end else begin
                q_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =
                    {DATA_WIDTH{1'b0}};
            end

            if (k_read_idx < SEQ_LEN) begin
                k_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =
                    k_mem[(k_read_idx * FEATURE_DIM) + dim_idx];
            end else begin
                k_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =
                    {DATA_WIDTH{1'b0}};
            end

            if (v_read_idx < SEQ_LEN) begin
                v_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =
                    v_mem[(v_read_idx * FEATURE_DIM) + dim_idx];
            end else begin
                v_feature_vector[dim_idx*DATA_WIDTH +: DATA_WIDTH] =
                    {DATA_WIDTH{1'b0}};
            end
        end
    end
endmodule
