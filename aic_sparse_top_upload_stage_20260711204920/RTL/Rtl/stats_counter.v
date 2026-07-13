`timescale 1ns/1ps

module stats_counter #(
    parameter COUNT_WIDTH = 32,
    parameter MACS_PER_PAIR = 4
) (
    input wire clk,
    input wire rst_n,
    input wire clear,
    input wire pair_valid,
    output reg [COUNT_WIDTH-1:0] pair_count,
    output reg [COUNT_WIDTH-1:0] cycle_count,
    output reg [COUNT_WIDTH-1:0] mac_count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pair_count <= {COUNT_WIDTH{1'b0}};
            cycle_count <= {COUNT_WIDTH{1'b0}};
            mac_count <= {COUNT_WIDTH{1'b0}};
        end else if (clear) begin
            pair_count <= {COUNT_WIDTH{1'b0}};
            cycle_count <= {COUNT_WIDTH{1'b0}};
            mac_count <= {COUNT_WIDTH{1'b0}};
        end else if (pair_valid) begin
            pair_count <= pair_count + 1'b1;
            cycle_count <= cycle_count + 1'b1;
            mac_count <= mac_count + MACS_PER_PAIR;
        end
    end
endmodule
