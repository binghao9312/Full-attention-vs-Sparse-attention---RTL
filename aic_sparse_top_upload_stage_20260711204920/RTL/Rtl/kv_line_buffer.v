`timescale 1ns/1ps

module kv_line_buffer #(
    parameter WINDOW_SIZE = 4,
    parameter IDX_WIDTH = 8,
    parameter BUFFER_SEL_WIDTH = 2
) (
    input wire clk,
    input wire rst_n,
    input wire pair_valid,
    input wire [IDX_WIDTH-1:0] k_idx,
    output reg [BUFFER_SEL_WIDTH-1:0] buffer_select,
    output reg buffer_load,
    output reg evict_valid
);
    integer i;
    reg [IDX_WIDTH-1:0] slot_tag [0:WINDOW_SIZE-1];
    reg slot_valid [0:WINDOW_SIZE-1];
    wire [BUFFER_SEL_WIDTH-1:0] next_select;

    assign next_select = k_idx % WINDOW_SIZE;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_select <= {BUFFER_SEL_WIDTH{1'b0}};
            buffer_load <= 1'b0;
            evict_valid <= 1'b0;
            for (i = 0; i < WINDOW_SIZE; i = i + 1) begin
                slot_tag[i] <= {IDX_WIDTH{1'b0}};
                slot_valid[i] <= 1'b0;
            end
        end else begin
            buffer_load <= 1'b0;
            evict_valid <= 1'b0;
            if (pair_valid) begin
                buffer_select <= next_select;
                buffer_load <= !slot_valid[next_select] || (slot_tag[next_select] != k_idx);
                evict_valid <= slot_valid[next_select] && (slot_tag[next_select] != k_idx);
                slot_tag[next_select] <= k_idx;
                slot_valid[next_select] <= 1'b1;
            end
        end
    end
endmodule
