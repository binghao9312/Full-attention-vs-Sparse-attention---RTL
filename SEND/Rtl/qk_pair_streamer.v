`timescale 1ns/1ps

module qk_pair_streamer #(
    parameter SEQ_LEN = 16,
    parameter WINDOW_SIZE = 4,
    parameter DILATION = 2,
    parameter GLOBAL_INDEX = 0,
    parameter IDX_WIDTH = 8,
    parameter BUFFER_SEL_WIDTH = 3
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [IDX_WIDTH-1:0] cfg_seq_len,
    input wire [2:0] mode,
    output wire done,
    output wire pair_valid,
    output wire [IDX_WIDTH-1:0] q_idx,
    output wire [IDX_WIDTH-1:0] k_idx,
    output wire [1:0] buffer_phase,
    output wire [1:0] buffer_bank,
    output wire [BUFFER_SEL_WIDTH-1:0] buffer_select,
    output wire buffer_load,
    output wire evict_valid,
    output wire [IDX_WIDTH-1:0] buffer_dout
);
    localparam PHASE_LOCAL = 2'd0;
    localparam PHASE_COL_GLOBAL = 2'd1;
    localparam PHASE_ROW_GLOBAL = 2'd2;
    localparam PHASE_BUTTERFLY = 2'd3;

    localparam BANK_BLOCK = 2'd0;
    localparam BANK_GLOBAL = 2'd1;
    localparam BANK_GLOBAL_ROW = 2'd2;
    localparam BANK_BUTTERFLY = 2'd3;

    genvar lb_idx;
    integer sel_idx;
    wire [BUFFER_SEL_WIDTH-1:0] block_select;
    wire [BUFFER_SEL_WIDTH-1:0] butterfly_select;
    wire [IDX_WIDTH-1:0] butterfly_stride;
    wire block_buffer_en;
    wire global_buffer_en;
    wire global_row_buffer_en;
    wire butterfly_buffer_en;
    wire [IDX_WIDTH-1:0] block_dout [0:WINDOW_SIZE-1];
    wire [IDX_WIDTH-1:0] global_dout;
    wire [IDX_WIDTH-1:0] global_row_dout [0:WINDOW_SIZE-1];
    wire [IDX_WIDTH-1:0] butterfly_dout [0:IDX_WIDTH-1];
    wire block_full [0:WINDOW_SIZE-1];
    wire global_full;
    wire global_row_full [0:WINDOW_SIZE-1];
    wire butterfly_full [0:IDX_WIDTH-1];
    reg selected_full;
    reg [IDX_WIDTH-1:0] selected_dout;

    function [BUFFER_SEL_WIDTH-1:0] butterfly_stage_select;
        input [IDX_WIDTH-1:0] stride_value;
        integer bit_idx;
        begin
            butterfly_stage_select = {BUFFER_SEL_WIDTH{1'b0}};
            for (bit_idx = 0; bit_idx < IDX_WIDTH; bit_idx = bit_idx + 1) begin
                if (stride_value[bit_idx]) begin
                    butterfly_stage_select = bit_idx;
                end
            end
        end
    endfunction

    assign block_select = k_idx % WINDOW_SIZE;
    assign butterfly_stride = q_idx ^ k_idx;
    assign butterfly_select = butterfly_stage_select(butterfly_stride);
    assign block_buffer_en = pair_valid && (buffer_phase == PHASE_LOCAL);
    assign global_buffer_en = pair_valid && (buffer_phase == PHASE_COL_GLOBAL);
    assign global_row_buffer_en = pair_valid && (buffer_phase == PHASE_ROW_GLOBAL);
    assign butterfly_buffer_en = pair_valid && (buffer_phase == PHASE_BUTTERFLY);
    assign buffer_bank = (buffer_phase == PHASE_BUTTERFLY) ? BANK_BUTTERFLY :
                         (buffer_phase == PHASE_ROW_GLOBAL) ? BANK_GLOBAL_ROW :
                         (buffer_phase == PHASE_COL_GLOBAL) ? BANK_GLOBAL :
                         BANK_BLOCK;
    assign buffer_select = (buffer_phase == PHASE_BUTTERFLY) ? butterfly_select :
                           (buffer_phase == PHASE_COL_GLOBAL) ? {BUFFER_SEL_WIDTH{1'b0}} :
                           block_select;
    assign buffer_load = pair_valid;
    assign evict_valid = pair_valid && selected_full;
    assign buffer_dout = selected_dout;

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
        .k_idx(k_idx),
        .buffer_phase(buffer_phase)
    );

    generate
        for (lb_idx = 0; lb_idx < WINDOW_SIZE; lb_idx = lb_idx + 1) begin : gen_block_lb
            KV_LBV2 #(
                .D_width(IDX_WIDTH),
                .D_length(WINDOW_SIZE)
            ) u_block_lb (
                .clk(clk),
                .rst_n(rst_n),
                .clear(start),
                .en(block_buffer_en && (block_select == lb_idx)),
                .Din(k_idx),
                .Dout(block_dout[lb_idx]),
                .buffer_full(block_full[lb_idx])
            );
        end

        for (lb_idx = 0; lb_idx < WINDOW_SIZE; lb_idx = lb_idx + 1) begin : gen_global_row_lb
            KV_LBV2 #(
                .D_width(IDX_WIDTH),
                .D_length(WINDOW_SIZE)
            ) u_global_row_lb (
                .clk(clk),
                .rst_n(rst_n),
                .clear(start),
                .en(global_row_buffer_en && (block_select == lb_idx)),
                .Din(k_idx),
                .Dout(global_row_dout[lb_idx]),
                .buffer_full(global_row_full[lb_idx])
            );
        end

        for (lb_idx = 0; lb_idx < IDX_WIDTH; lb_idx = lb_idx + 1) begin : gen_butterfly_lb
            KV_LBV2 #(
                .D_width(IDX_WIDTH),
                .D_length(WINDOW_SIZE)
            ) u_butterfly_lb (
                .clk(clk),
                .rst_n(rst_n),
                .clear(start),
                .en(butterfly_buffer_en && (butterfly_select == lb_idx)),
                .Din(k_idx),
                .Dout(butterfly_dout[lb_idx]),
                .buffer_full(butterfly_full[lb_idx])
            );
        end
    endgenerate

    KV_LBV2 #(
        .D_width(IDX_WIDTH),
        .D_length(1)
    ) u_global_lb (
        .clk(clk),
        .rst_n(rst_n),
        .clear(start),
        .en(global_buffer_en),
        .Din(k_idx),
        .Dout(global_dout),
        .buffer_full(global_full)
    );

    always @(*) begin
        selected_full = 1'b0;
        selected_dout = {IDX_WIDTH{1'b0}};

        if (buffer_phase == PHASE_COL_GLOBAL) begin
            selected_full = global_full;
            selected_dout = global_dout;
        end else if (buffer_phase == PHASE_ROW_GLOBAL) begin
            for (sel_idx = 0; sel_idx < WINDOW_SIZE; sel_idx = sel_idx + 1) begin
                if (block_select == sel_idx) begin
                    selected_full = global_row_full[sel_idx];
                    selected_dout = global_row_dout[sel_idx];
                end
            end
        end else if (buffer_phase == PHASE_BUTTERFLY) begin
            for (sel_idx = 0; sel_idx < IDX_WIDTH; sel_idx = sel_idx + 1) begin
                if (butterfly_select == sel_idx) begin
                    selected_full = butterfly_full[sel_idx];
                    selected_dout = butterfly_dout[sel_idx];
                end
            end
        end else begin
            for (sel_idx = 0; sel_idx < WINDOW_SIZE; sel_idx = sel_idx + 1) begin
                if (block_select == sel_idx) begin
                    selected_full = block_full[sel_idx];
                    selected_dout = block_dout[sel_idx];
                end
            end
        end
    end
endmodule
