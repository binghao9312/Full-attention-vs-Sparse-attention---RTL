`timescale 1ns/1ps

module pattern_controller #(
    parameter SEQ_LEN = 16,
    parameter WINDOW_SIZE = 4,
    parameter DILATION = 2,
    parameter GLOBAL_INDEX = 0,
    parameter IDX_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [IDX_WIDTH-1:0] cfg_seq_len,
    input wire [1:0] mode,
    output reg done,
    output reg pair_valid,
    output reg [IDX_WIDTH-1:0] q_idx,
    output reg [IDX_WIDTH-1:0] k_idx
);
    localparam MODE_SLIDING = 2'd1;
    localparam MODE_DILATED = 2'd2;
    localparam MODE_SLIDING_GLOBAL = 2'd3;

    localparam PHASE_LOCAL = 2'd0;
    localparam PHASE_COL_GLOBAL = 2'd1;
    localparam PHASE_ROW_GLOBAL = 2'd2;

    reg active;
    reg done_pending;
    reg [1:0] phase;
    reg [IDX_WIDTH-1:0] q_state;
    reg [IDX_WIDTH-1:0] k_state;
    reg [IDX_WIDTH-1:0] offset;
    reg [IDX_WIDTH-1:0] block_start;
    wire [IDX_WIDTH-1:0] local_step_value;
    wire [IDX_WIDTH-1:0] local_last_offset_value;

    assign local_step_value = (mode == MODE_DILATED) ? DILATION : 1;
    assign local_last_offset_value = (mode == MODE_DILATED) ? (WINDOW_SIZE - DILATION) : (WINDOW_SIZE - 1);

    always @(*) begin
        block_start = (q_state / WINDOW_SIZE) * WINDOW_SIZE;
    end

    task advance_local;
        begin
            if ((q_state == cfg_seq_len - 1) && (offset == local_last_offset_value)) begin
                if (mode == MODE_SLIDING_GLOBAL) begin
                    phase <= PHASE_COL_GLOBAL;
                    q_state <= {IDX_WIDTH{1'b0}};
                    offset <= {IDX_WIDTH{1'b0}};
                end else begin
                    done_pending <= 1'b1;
                end
            end else if (offset == local_last_offset_value) begin
                q_state <= q_state + 1'b1;
                offset <= {IDX_WIDTH{1'b0}};
            end else begin
                offset <= offset + local_step_value;
            end
        end
    endtask

    function is_in_global_block;
        input [IDX_WIDTH-1:0] idx;
        reg [IDX_WIDTH-1:0] idx_block;
        reg [IDX_WIDTH-1:0] global_block;
        begin
            idx_block = (idx / WINDOW_SIZE) * WINDOW_SIZE;
            global_block = (GLOBAL_INDEX / WINDOW_SIZE) * WINDOW_SIZE;
            is_in_global_block = (idx_block == global_block);
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 1'b0;
            done_pending <= 1'b0;
            phase <= PHASE_LOCAL;
            done <= 1'b0;
            pair_valid <= 1'b0;
            q_idx <= {IDX_WIDTH{1'b0}};
            k_idx <= {IDX_WIDTH{1'b0}};
            q_state <= {IDX_WIDTH{1'b0}};
            k_state <= {IDX_WIDTH{1'b0}};
            offset <= {IDX_WIDTH{1'b0}};
        end else begin
            done <= 1'b0;
            pair_valid <= 1'b0;

            if (done_pending) begin
                active <= 1'b0;
                done_pending <= 1'b0;
                done <= 1'b1;
            end else if (start && !active) begin
                active <= 1'b1;
                done_pending <= 1'b0;
                phase <= PHASE_LOCAL;
                q_idx <= {IDX_WIDTH{1'b0}};
                k_idx <= {IDX_WIDTH{1'b0}};
                q_state <= {IDX_WIDTH{1'b0}};
                k_state <= {IDX_WIDTH{1'b0}};
                offset <= {IDX_WIDTH{1'b0}};
            end else if (active) begin
                if (phase == PHASE_LOCAL) begin
                    pair_valid <= 1'b1;
                    q_idx <= q_state;
                    k_idx <= block_start + offset;
                    advance_local();
                end else if (phase == PHASE_COL_GLOBAL) begin
                    q_idx <= q_state;
                    k_idx <= GLOBAL_INDEX;
                    if (!is_in_global_block(q_state)) begin
                        pair_valid <= 1'b1;
                    end

                    if (q_state == cfg_seq_len - 1) begin
                        phase <= PHASE_ROW_GLOBAL;
                        q_state <= GLOBAL_INDEX;
                        k_state <= {IDX_WIDTH{1'b0}};
                    end else begin
                        q_state <= q_state + 1'b1;
                    end
                end else if (phase == PHASE_ROW_GLOBAL) begin
                    q_idx <= q_state;
                    k_idx <= k_state;
                    if (!is_in_global_block(k_state)) begin
                        pair_valid <= 1'b1;
                    end

                    if (k_state == cfg_seq_len - 1) begin
                        done_pending <= 1'b1;
                    end else begin
                        k_state <= k_state + 1'b1;
                    end
                end
            end
        end
    end
endmodule
