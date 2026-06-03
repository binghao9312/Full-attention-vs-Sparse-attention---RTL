`timescale 1ns/1ps

module full_attention_core #(
    parameter SEQ_LEN = 16,
    parameter IDX_WIDTH = 8,
    parameter COUNT_WIDTH = 32,
    parameter FEATURE_DIM = 4,
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
    output wire score_valid,
    output wire [SCORE_WIDTH-1:0] attention_score
);
    reg active;
    reg [IDX_WIDTH-1:0] q_state;
    reg [IDX_WIDTH-1:0] k_state;

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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 1'b0;
            done <= 1'b0;
            pair_valid <= 1'b0;
            q_idx <= {IDX_WIDTH{1'b0}};
            k_idx <= {IDX_WIDTH{1'b0}};
            q_state <= {IDX_WIDTH{1'b0}};
            k_state <= {IDX_WIDTH{1'b0}};
            pair_count <= {COUNT_WIDTH{1'b0}};
            cycle_count <= {COUNT_WIDTH{1'b0}};
            mac_count <= {COUNT_WIDTH{1'b0}};
        end 
        else begin
            done <= 1'b0;
            pair_valid <= 1'b0;

            if (start && !active) begin
                active <= 1'b1;
                q_idx <= {IDX_WIDTH{1'b0}};
                k_idx <= {IDX_WIDTH{1'b0}};
                q_state <= {IDX_WIDTH{1'b0}};
                k_state <= {IDX_WIDTH{1'b0}};
                pair_count <= {COUNT_WIDTH{1'b0}};
                cycle_count <= {COUNT_WIDTH{1'b0}};
                mac_count <= {COUNT_WIDTH{1'b0}};
            end 
            else if (active) begin
                pair_valid <= 1'b1;
                q_idx <= q_state;
                k_idx <= k_state;
                pair_count <= pair_count + 1'b1;
                cycle_count <= cycle_count + 1'b1;
                mac_count <= mac_count + FEATURE_DIM;

                if ((q_state == cfg_seq_len - 1) && (k_state == cfg_seq_len - 1)) begin
                    active <= 1'b0;
                    done <= 1'b1;
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
