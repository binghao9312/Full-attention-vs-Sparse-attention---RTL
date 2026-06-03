`timescale 1ns/1ps

module sparse_attention_core #(
    parameter SEQ_LEN = 16,
    parameter WINDOW_SIZE = 4,
    parameter DILATION = 2,
    parameter GLOBAL_INDEX = 0,
    parameter IDX_WIDTH = 8,
    parameter BUFFER_SEL_WIDTH = 2,
    parameter COUNT_WIDTH = 32,
    parameter FEATURE_DIM = 4,
    parameter SCORE_WIDTH = 32
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [IDX_WIDTH-1:0] cfg_seq_len,
    input wire [1:0] mode,
    output wire done,
    output wire pair_valid,
    output wire [IDX_WIDTH-1:0] q_idx,
    output wire [IDX_WIDTH-1:0] k_idx,
    output wire [BUFFER_SEL_WIDTH-1:0] buffer_select,
    output wire buffer_load,
    output wire evict_valid,
    output wire [COUNT_WIDTH-1:0] pair_count,
    output wire [COUNT_WIDTH-1:0] cycle_count,
    output wire [COUNT_WIDTH-1:0] mac_count,
    output wire score_valid,
    output wire [SCORE_WIDTH-1:0] attention_score
);
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
        .done(done),
        .pair_valid(pair_valid),
        .q_idx(q_idx),
        .k_idx(k_idx),
        .buffer_select(buffer_select),
        .buffer_load(buffer_load),
        .evict_valid(evict_valid)
    );

    stats_counter #(
        .COUNT_WIDTH(COUNT_WIDTH),
        .MACS_PER_PAIR(FEATURE_DIM)
    ) u_stats_counter (
        .clk(clk),
        .rst_n(rst_n),
        .clear(start),
        .pair_valid(pair_valid),
        .pair_count(pair_count),
        .cycle_count(cycle_count),
        .mac_count(mac_count)
    );

    qk_dot_product #(
        .IDX_WIDTH(IDX_WIDTH),
        .FEATURE_DIM(FEATURE_DIM),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) u_qk_dot_product (
        .pair_valid(pair_valid),
        .q_idx(q_idx),
        .k_idx(k_idx),
        .score_valid(score_valid),
        .attention_score(attention_score)
    );
endmodule
