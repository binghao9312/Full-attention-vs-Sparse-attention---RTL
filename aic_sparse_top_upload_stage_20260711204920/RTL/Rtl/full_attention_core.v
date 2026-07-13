`timescale 1ns/1ps

module full_attention_core #(
    parameter SEQ_LEN = 16,
    parameter IDX_WIDTH = 8,
    parameter COUNT_WIDTH = 32,
    parameter FEATURE_DIM = 4,
    parameter DATA_WIDTH = 8,
    parameter SCORE_WIDTH = 32
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [IDX_WIDTH-1:0] cfg_seq_len,
    output reg done,
    output reg pair_valid,
    output reg [IDX_WIDTH-1:0] q_idx,
    output reg [IDX_WIDTH-1:0] k_idx,
    output reg [COUNT_WIDTH-1:0] pair_count,
    output reg [COUNT_WIDTH-1:0] cycle_count,
    output reg [COUNT_WIDTH-1:0] mac_count,
    output reg score_valid,
    output reg [SCORE_WIDTH-1:0] attention_score
);
    reg active;
    reg [IDX_WIDTH-1:0] q_state;
    reg [IDX_WIDTH-1:0] k_state;
    reg done_delay0;
    reg done_delay1;
    reg done_delay2;
    wire score_valid_pipe;
    wire [IDX_WIDTH-1:0] score_q_idx_pipe;
    wire [IDX_WIDTH-1:0] score_k_idx_pipe;
    wire [SCORE_WIDTH-1:0] attention_score_pipe;
    wire [FEATURE_DIM*DATA_WIDTH-1:0] q_feature_vector;
    wire [FEATURE_DIM*DATA_WIDTH-1:0] k_feature_vector;
    genvar feature_idx;

    generate
        for (feature_idx = 0; feature_idx < FEATURE_DIM; feature_idx = feature_idx + 1) begin : gen_full_feature_vector
            assign q_feature_vector[feature_idx*DATA_WIDTH +: DATA_WIDTH] =
                q_state + feature_idx + 1;
            assign k_feature_vector[feature_idx*DATA_WIDTH +: DATA_WIDTH] =
                k_state + feature_idx + 2;
        end
    endgenerate

    qk_dot_accumulator #(
        .IDX_WIDTH(IDX_WIDTH),
        .FEATURE_DIM(FEATURE_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) u_qk_dot_accumulator (
        .clk(clk),
        .rst_n(rst_n),
        .advance_ready(1'b1),
        .pair_valid(active),
        .q_idx(q_state),
        .k_idx(k_state),
        .q_feature_vector(q_feature_vector),
        .k_feature_vector(k_feature_vector),
        .score_valid(score_valid_pipe),
        .score_q_idx(score_q_idx_pipe),
        .score_k_idx(score_k_idx_pipe),
        .attention_score(attention_score_pipe)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 1'b0;
            done <= 1'b0;
            pair_valid <= 1'b0;
            score_valid <= 1'b0;
            q_idx <= {IDX_WIDTH{1'b0}};
            k_idx <= {IDX_WIDTH{1'b0}};
            attention_score <= {SCORE_WIDTH{1'b0}};
            q_state <= {IDX_WIDTH{1'b0}};
            k_state <= {IDX_WIDTH{1'b0}};
            done_delay0 <= 1'b0;
            done_delay1 <= 1'b0;
            done_delay2 <= 1'b0;
            pair_count <= {COUNT_WIDTH{1'b0}};
            cycle_count <= {COUNT_WIDTH{1'b0}};
            mac_count <= {COUNT_WIDTH{1'b0}};
        end 
        else begin
            done <= done_delay2;
            done_delay2 <= done_delay1;
            done_delay1 <= done_delay0;
            done_delay0 <= 1'b0;
            pair_valid <= score_valid_pipe;
            score_valid <= score_valid_pipe;
            q_idx <= score_q_idx_pipe;
            k_idx <= score_k_idx_pipe;
            attention_score <= attention_score_pipe;

            if (start && !active) begin
                active <= 1'b1;
                q_idx <= {IDX_WIDTH{1'b0}};
                k_idx <= {IDX_WIDTH{1'b0}};
                attention_score <= {SCORE_WIDTH{1'b0}};
                done <= 1'b0;
                done_delay0 <= 1'b0;
                done_delay1 <= 1'b0;
                done_delay2 <= 1'b0;
                q_state <= {IDX_WIDTH{1'b0}};
                k_state <= {IDX_WIDTH{1'b0}};
                pair_count <= {COUNT_WIDTH{1'b0}};
                cycle_count <= {COUNT_WIDTH{1'b0}};
                mac_count <= {COUNT_WIDTH{1'b0}};
            end 
            else if (active) begin
                pair_count <= pair_count + 1'b1;
                cycle_count <= cycle_count + 1'b1;
                mac_count <= mac_count + FEATURE_DIM;

                if ((q_state == cfg_seq_len - 1) && (k_state == cfg_seq_len - 1)) begin
                    active <= 1'b0;
                    done_delay0 <= 1'b1;
                end 
                else if (k_state == cfg_seq_len - 1) begin
                    q_state <= q_state + 1'b1;
                    k_state <= {IDX_WIDTH{1'b0}};
                end 
                else begin
                    k_state <= k_state + 1'b1;
                end
            end
        end
    end
endmodule
