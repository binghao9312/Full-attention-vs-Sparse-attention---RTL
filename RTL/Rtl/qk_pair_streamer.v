`timescale 1ns/1ps

module qk_pair_streamer #(
    parameter SEQ_LEN = 16,
    parameter WINDOW_SIZE = 4,
    parameter DILATION = 2,
    parameter GLOBAL_INDEX = 0,
    parameter IDX_WIDTH = 8,
    parameter BUFFER_SEL_WIDTH = 2
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
    output wire evict_valid
);
    pattern_controller #(
        .SEQ_LEN(SEQ_LEN),
        .WINDOW_SIZE(WINDOW_SIZE),
        .DILATION(DILATION),
        .GLOBAL_INDEX(GLOBAL_INDEX),
        .IDX_WIDTH(IDX_WIDTH)
    ) u_pattern_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .cfg_seq_len(cfg_seq_len),
        .mode(mode),
        .done(done),
        .pair_valid(pair_valid),
        .q_idx(q_idx),
        .k_idx(k_idx)
    );

    kv_line_buffer #(
        .WINDOW_SIZE(WINDOW_SIZE),
        .IDX_WIDTH(IDX_WIDTH),
        .BUFFER_SEL_WIDTH(BUFFER_SEL_WIDTH)
    ) u_kv_line_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .pair_valid(pair_valid),
        .k_idx(k_idx),
        .buffer_select(buffer_select),
        .buffer_load(buffer_load),
        .evict_valid(evict_valid)
    );
endmodule
