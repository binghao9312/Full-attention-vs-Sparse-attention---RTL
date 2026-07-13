`timescale 1ns/1ps

module sparse_softmax_sv #(
    parameter SEQ_LEN = 128,
    parameter IDX_WIDTH = 8,
    parameter FEATURE_DIM = 4,
    parameter FEATURE_IDX_WIDTH = 2,
    parameter DATA_WIDTH = 8,
    parameter SCORE_WIDTH = 32,
    parameter SCORE_SCALE_SHIFT = 1,
    parameter EXP_WIDTH = 16,
    parameter OUTPUT_FRAC_BITS = 8,
    parameter CONTEXT_WIDTH = DATA_WIDTH + OUTPUT_FRAC_BITS,
    parameter ACC_WIDTH = 48
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire scores_done,
    input wire [IDX_WIDTH-1:0] cfg_seq_len,
    input wire score_valid,
    output wire score_ready,
    input wire [IDX_WIDTH-1:0] score_q_idx,
    input wire [IDX_WIDTH-1:0] score_k_idx,
    input wire [SCORE_WIDTH-1:0] score_value,
    output wire [IDX_WIDTH-1:0] v_read_idx,
    input wire [FEATURE_DIM*DATA_WIDTH-1:0] v_feature_vector,
    input wire context_ready,
    output wire context_valid,
    output wire [IDX_WIDTH-1:0] context_q_idx,
    output wire [FEATURE_IDX_WIDTH-1:0] context_feature_idx,
    output wire [CONTEXT_WIDTH-1:0] context_value,
    output reg done
);
    localparam STATE_COLLECT = 3'd0;
    localparam STATE_UPDATE = 3'd1;
    localparam STATE_PREPARE = 3'd2;
    localparam STATE_DIVIDE = 3'd3;
    localparam STATE_OUTPUT = 3'd4;

    localparam SUM_WIDTH = EXP_WIDTH + IDX_WIDTH + 1;
    localparam WEIGHTED_MEM_DEPTH = SEQ_LEN * FEATURE_DIM;
    localparam DIV_BIT_WIDTH = (CONTEXT_WIDTH <= 2) ? 1 : $clog2(CONTEXT_WIDTH);
    localparam [EXP_WIDTH-1:0] EXP_ONE = {EXP_WIDTH{1'b1}};
    localparam [FEATURE_IDX_WIDTH-1:0] LAST_FEATURE = FEATURE_DIM - 1;

    reg [2:0] state;
    reg [2:0] next_state;
    reg [IDX_WIDTH-1:0] active_seq_len;
    reg scores_done_pending;
    reg row_initialized [0:SEQ_LEN-1];
    reg [SCORE_WIDTH-1:0] row_max [0:SEQ_LEN-1];
    reg [SUM_WIDTH-1:0] row_exp_sum [0:SEQ_LEN-1];
    reg [ACC_WIDTH-1:0] row_weighted_sum [0:WEIGHTED_MEM_DEPTH-1];

    reg [IDX_WIDTH-1:0] update_q;
    reg [FEATURE_IDX_WIDTH-1:0] update_feature;
    reg [FEATURE_DIM*DATA_WIDTH-1:0] update_v_vector;
    reg update_new_row;
    reg update_new_max;
    reg [EXP_WIDTH-1:0] update_weight;

    reg [IDX_WIDTH-1:0] output_q;
    reg [FEATURE_IDX_WIDTH-1:0] output_feature;
    reg [CONTEXT_WIDTH-1:0] context_value_reg;
    reg [ACC_WIDTH-1:0] division_remainder;
    reg [ACC_WIDTH-1:0] division_denominator;
    reg [CONTEXT_WIDTH-1:0] division_quotient;
    reg [DIV_BIT_WIDTH-1:0] division_bit;

    integer init_idx;
    integer update_addr;
    integer output_addr;
    reg [DATA_WIDTH-1:0] update_v;
    reg [ACC_WIDTH-1:0] update_product;
    reg [ACC_WIDTH+EXP_WIDTH-1:0] weighted_rescale_product;
    reg [ACC_WIDTH-1:0] rescaled_weighted_sum;
    reg [ACC_WIDTH-1:0] shifted_divisor;
    reg [ACC_WIDTH-1:0] one_weighted_v;
    reg [SCORE_WIDTH-1:0] incoming_delta;
    reg [EXP_WIDTH-1:0] incoming_weight;
    reg [SUM_WIDTH+EXP_WIDTH-1:0] rescaled_exp_product;
    reg [SUM_WIDTH-1:0] rescaled_exp_sum;

    // Q0.16 approximation of exp(-x), where x is the non-negative score
    // delta after the 1/sqrt(FEATURE_DIM) scale.  With FEATURE_DIM=4,
    // SCORE_SCALE_SHIFT=1 implements the required division by two.
    function [EXP_WIDTH-1:0] exp_lut;
        input [SCORE_WIDTH-1:0] x;
        begin
            case (x)
                0: exp_lut = 16'd65535;
                1: exp_lut = 16'd24109;
                2: exp_lut = 16'd8869;
                3: exp_lut = 16'd3263;
                4: exp_lut = 16'd1200;
                5: exp_lut = 16'd441;
                6: exp_lut = 16'd162;
                7: exp_lut = 16'd60;
                8: exp_lut = 16'd22;
                9: exp_lut = 16'd8;
                10: exp_lut = 16'd3;
                11: exp_lut = 16'd1;
                default: exp_lut = {EXP_WIDTH{1'b0}};
            endcase
        end
    endfunction

    assign score_ready = (state == STATE_COLLECT);
    assign v_read_idx = score_k_idx;
    assign context_valid = (state == STATE_OUTPUT);
    assign context_q_idx = output_q;
    assign context_feature_idx = output_feature;
    assign context_value = context_value_reg;

    // FSM sequential block: state register only.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_COLLECT;
        end else if (start) begin
            state <= STATE_COLLECT;
        end else begin
            state <= next_state;
        end
    end

    // FSM combinational block: next-state logic only.
    always @(*) begin
        next_state = state;

        case (state)
            STATE_COLLECT: begin
                if (scores_done || scores_done_pending) begin
                    next_state = STATE_PREPARE;
                end else if (score_valid) begin
                    next_state = STATE_UPDATE;
                end
            end

            STATE_UPDATE: begin
                if (update_feature == LAST_FEATURE) begin
                    if (scores_done || scores_done_pending) begin
                        next_state = STATE_PREPARE;
                    end else begin
                        next_state = STATE_COLLECT;
                    end
                end
            end

            STATE_PREPARE: begin
                if (!row_initialized[output_q] ||
                    (row_exp_sum[output_q] == 0)) begin
                    next_state = STATE_OUTPUT;
                end else begin
                    next_state = STATE_DIVIDE;
                end
            end

            STATE_DIVIDE: begin
                if (division_bit == 0) begin
                    next_state = STATE_OUTPUT;
                end
            end

            STATE_OUTPUT: begin
                if (context_ready) begin
                    if ((output_feature == LAST_FEATURE) &&
                        (output_q == active_seq_len - 1'b1)) begin
                        next_state = STATE_COLLECT;
                    end else begin
                        next_state = STATE_PREPARE;
                    end
                end
            end

            default: begin
                next_state = STATE_COLLECT;
            end
        endcase
    end

    // Datapath combinational calculations.
    always @(*) begin
        update_addr = (update_q * FEATURE_DIM) + update_feature;
        output_addr = (output_q * FEATURE_DIM) + output_feature;
        update_v = update_v_vector[update_feature*DATA_WIDTH +: DATA_WIDTH];
        update_product = update_weight * update_v;
        weighted_rescale_product = row_weighted_sum[update_addr] * update_weight;
        rescaled_weighted_sum =
            weighted_rescale_product[ACC_WIDTH+EXP_WIDTH-1:EXP_WIDTH];
        one_weighted_v = EXP_ONE * update_v;
        shifted_divisor = division_denominator << division_bit;

        if (score_value > row_max[score_q_idx]) begin
            incoming_delta = (score_value - row_max[score_q_idx]) >> SCORE_SCALE_SHIFT;
        end else begin
            incoming_delta = (row_max[score_q_idx] - score_value) >> SCORE_SCALE_SHIFT;
        end
        incoming_weight = exp_lut(incoming_delta);
        rescaled_exp_product = row_exp_sum[score_q_idx] * incoming_weight;
        rescaled_exp_sum =
            rescaled_exp_product[SUM_WIDTH+EXP_WIDTH-1:EXP_WIDTH];
    end

    // Datapath registers and memory updates.  State is not assigned here.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_seq_len <= {{(IDX_WIDTH-1){1'b0}}, 1'b1};
            scores_done_pending <= 1'b0;
            update_q <= {IDX_WIDTH{1'b0}};
            update_feature <= {FEATURE_IDX_WIDTH{1'b0}};
            update_v_vector <= {FEATURE_DIM*DATA_WIDTH{1'b0}};
            update_new_row <= 1'b0;
            update_new_max <= 1'b0;
            update_weight <= {EXP_WIDTH{1'b0}};
            output_q <= {IDX_WIDTH{1'b0}};
            output_feature <= {FEATURE_IDX_WIDTH{1'b0}};
            context_value_reg <= {CONTEXT_WIDTH{1'b0}};
            division_remainder <= {ACC_WIDTH{1'b0}};
            division_denominator <= {ACC_WIDTH{1'b0}};
            division_quotient <= {CONTEXT_WIDTH{1'b0}};
            division_bit <= {DIV_BIT_WIDTH{1'b0}};
            done <= 1'b0;
            for (init_idx = 0; init_idx < SEQ_LEN; init_idx = init_idx + 1) begin
                row_initialized[init_idx] <= 1'b0;
            end
        end else begin
            done <= 1'b0;

            if (start) begin
                active_seq_len <= cfg_seq_len;
                scores_done_pending <= 1'b0;
                update_q <= {IDX_WIDTH{1'b0}};
                update_feature <= {FEATURE_IDX_WIDTH{1'b0}};
                update_new_row <= 1'b0;
                update_new_max <= 1'b0;
                update_weight <= {EXP_WIDTH{1'b0}};
                output_q <= {IDX_WIDTH{1'b0}};
                output_feature <= {FEATURE_IDX_WIDTH{1'b0}};
                context_value_reg <= {CONTEXT_WIDTH{1'b0}};
                division_remainder <= {ACC_WIDTH{1'b0}};
                division_denominator <= {ACC_WIDTH{1'b0}};
                division_quotient <= {CONTEXT_WIDTH{1'b0}};
                division_bit <= {DIV_BIT_WIDTH{1'b0}};
                for (init_idx = 0; init_idx < SEQ_LEN; init_idx = init_idx + 1) begin
                    row_initialized[init_idx] <= 1'b0;
                end
            end else begin
                if (scores_done) begin
                    scores_done_pending <= 1'b1;
                end

                case (state)
                    STATE_COLLECT: begin
                        if (scores_done || scores_done_pending) begin
                            output_q <= {IDX_WIDTH{1'b0}};
                            output_feature <= {FEATURE_IDX_WIDTH{1'b0}};
                            scores_done_pending <= 1'b0;
                        end else if (score_valid) begin
                            update_q <= score_q_idx;
                            update_feature <= {FEATURE_IDX_WIDTH{1'b0}};
                            update_v_vector <= v_feature_vector;

                            if (!row_initialized[score_q_idx]) begin
                                row_initialized[score_q_idx] <= 1'b1;
                                row_max[score_q_idx] <= score_value;
                                row_exp_sum[score_q_idx] <= EXP_ONE;
                                update_new_row <= 1'b1;
                                update_new_max <= 1'b0;
                                update_weight <= EXP_ONE;
                            end else if (score_value > row_max[score_q_idx]) begin
                                row_max[score_q_idx] <= score_value;
                                row_exp_sum[score_q_idx] <=
                                    rescaled_exp_sum + EXP_ONE;
                                update_new_row <= 1'b0;
                                update_new_max <= 1'b1;
                                update_weight <= incoming_weight;
                            end else begin
                                row_exp_sum[score_q_idx] <=
                                    row_exp_sum[score_q_idx] + incoming_weight;
                                update_new_row <= 1'b0;
                                update_new_max <= 1'b0;
                                update_weight <= incoming_weight;
                            end
                        end
                    end

                    STATE_UPDATE: begin
                        if (update_new_row) begin
                            row_weighted_sum[update_addr] <= update_product;
                        end else if (update_new_max) begin
                            row_weighted_sum[update_addr] <=
                                rescaled_weighted_sum + one_weighted_v;
                        end else begin
                            row_weighted_sum[update_addr] <=
                                row_weighted_sum[update_addr] + update_product;
                        end

                        if (update_feature == LAST_FEATURE) begin
                            update_feature <= {FEATURE_IDX_WIDTH{1'b0}};
                            if (scores_done || scores_done_pending) begin
                                output_q <= {IDX_WIDTH{1'b0}};
                                output_feature <= {FEATURE_IDX_WIDTH{1'b0}};
                                scores_done_pending <= 1'b0;
                            end
                        end else begin
                            update_feature <= update_feature + 1'b1;
                        end
                    end

                    STATE_PREPARE: begin
                        division_quotient <= {CONTEXT_WIDTH{1'b0}};
                        if (!row_initialized[output_q] ||
                            (row_exp_sum[output_q] == 0)) begin
                            context_value_reg <= {CONTEXT_WIDTH{1'b0}};
                        end else begin
                            division_remainder <=
                                row_weighted_sum[output_addr] << OUTPUT_FRAC_BITS;
                            division_denominator <=
                                {{(ACC_WIDTH-SUM_WIDTH){1'b0}}, row_exp_sum[output_q]};
                            division_bit <= CONTEXT_WIDTH - 1;
                        end
                    end

                    STATE_DIVIDE: begin
                        if (division_remainder >= shifted_divisor) begin
                            division_remainder <= division_remainder - shifted_divisor;
                            division_quotient[division_bit] <= 1'b1;
                        end else begin
                            division_quotient[division_bit] <= 1'b0;
                        end

                        if (division_bit == 0) begin
                            context_value_reg <= {
                                division_quotient[CONTEXT_WIDTH-1:1],
                                (division_remainder >= shifted_divisor)
                            };
                        end else begin
                            division_bit <= division_bit - 1'b1;
                        end
                    end

                    STATE_OUTPUT: begin
                        if (context_ready) begin
                            if (output_feature == LAST_FEATURE) begin
                                output_feature <= {FEATURE_IDX_WIDTH{1'b0}};
                                if (output_q == active_seq_len - 1'b1) begin
                                    done <= 1'b1;
                                end else begin
                                    output_q <= output_q + 1'b1;
                                end
                            end else begin
                                output_feature <= output_feature + 1'b1;
                            end
                        end
                    end

                    default: begin
                    end
                endcase
            end
        end
    end
endmodule
