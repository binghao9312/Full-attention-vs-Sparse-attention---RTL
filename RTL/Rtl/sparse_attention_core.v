`timescale 1ns/1ps

module sparse_attention_core #(
    parameter SEQ_LEN = 16,
    parameter WINDOW_SIZE = 4,
    parameter DILATION = 2,
    parameter GLOBAL_INDEX = 0,
    parameter IDX_WIDTH = 8,
    parameter BUFFER_SEL_WIDTH = 3,
    parameter COUNT_WIDTH = 32,
    parameter FEATURE_DIM = 4,
    parameter SCORE_WIDTH = 32
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [IDX_WIDTH-1:0] cfg_seq_len,
    input wire [2:0] mode,
    output reg done,
    output reg pair_valid,
    output reg [IDX_WIDTH-1:0] q_idx,
    output reg [IDX_WIDTH-1:0] k_idx,
    output wire [1:0] buffer_phase,
    output wire [1:0] buffer_bank,
    output wire [BUFFER_SEL_WIDTH-1:0] buffer_select,
    output wire buffer_load,
    output wire evict_valid,
    output wire [IDX_WIDTH-1:0] buffer_dout,
    output wire [COUNT_WIDTH-1:0] pair_count,
    output wire [COUNT_WIDTH-1:0] cycle_count,
    output wire [COUNT_WIDTH-1:0] mac_count,
    output reg score_valid,
    output reg [SCORE_WIDTH-1:0] attention_score
);
    wire raw_done;
    wire raw_pair_valid;
    wire [IDX_WIDTH-1:0] raw_q_idx;
    wire [IDX_WIDTH-1:0] raw_k_idx;
    reg done_delay0;
    reg done_delay1;
    wire score_valid_pipe;
    wire [IDX_WIDTH-1:0] score_q_idx_pipe;
    wire [IDX_WIDTH-1:0] score_k_idx_pipe;
    wire [SCORE_WIDTH-1:0] attention_score_pipe;

    qk_pair_streamer #(
        .SEQ_LEN(SEQ_LEN),
        .WINDOW_SIZE(WINDOW_SIZE),
        .DILATION(DILATION),
        .GLOBAL_INDEX(GLOBAL_INDEX),
        .IDX_WIDTH(IDX_WIDTH),
        .BUFFER_SEL_WIDTH(BUFFER_SEL_WIDTH)
    ) 
    u_qk_pair_streamer (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .cfg_seq_len(cfg_seq_len),
        .mode(mode),
        .done(raw_done),
        .pair_valid(raw_pair_valid),
        .q_idx(raw_q_idx),
        .k_idx(raw_k_idx),
        .buffer_phase(buffer_phase),
        .buffer_bank(buffer_bank),
        .buffer_select(buffer_select),
        .buffer_load(buffer_load),
        .evict_valid(evict_valid),
        .buffer_dout(buffer_dout)
    );

    stats_counter #(
        .COUNT_WIDTH(COUNT_WIDTH),
        .MACS_PER_PAIR(FEATURE_DIM)
    ) u_stats_counter (
        .clk(clk),
        .rst_n(rst_n),
        .clear(start),
        .pair_valid(raw_pair_valid),
        .pair_count(pair_count),
        .cycle_count(cycle_count),
        .mac_count(mac_count)
    );

    qk_dot_accumulator #(
        .IDX_WIDTH(IDX_WIDTH),
        .FEATURE_DIM(FEATURE_DIM),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) u_qk_dot_accumulator (
        .clk(clk),
        .rst_n(rst_n),
        .pair_valid(raw_pair_valid),
        .q_idx(raw_q_idx),
        .k_idx(raw_k_idx),
        .score_valid(score_valid_pipe),
        .score_q_idx(score_q_idx_pipe),
        .score_k_idx(score_k_idx_pipe),
        .attention_score(attention_score_pipe)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
            pair_valid <= 1'b0;
            score_valid <= 1'b0;
            q_idx <= {IDX_WIDTH{1'b0}};
            k_idx <= {IDX_WIDTH{1'b0}};
            attention_score <= {SCORE_WIDTH{1'b0}};
            done_delay0 <= 1'b0;
            done_delay1 <= 1'b0;
        end
        else begin
            done <= done_delay1;
            done_delay1 <= done_delay0;
            done_delay0 <= raw_done;
            pair_valid <= score_valid_pipe;
            score_valid <= score_valid_pipe;
            q_idx <= score_q_idx_pipe;
            k_idx <= score_k_idx_pipe;
            attention_score <= attention_score_pipe;

            if (start) begin
                done <= 1'b0;
                done_delay0 <= 1'b0;
                done_delay1 <= 1'b0;
                pair_valid <= 1'b0;
                score_valid <= 1'b0;
                q_idx <= {IDX_WIDTH{1'b0}};
                k_idx <= {IDX_WIDTH{1'b0}};
                attention_score <= {SCORE_WIDTH{1'b0}};
            end
        end
    end
endmodule
