`timescale 1ns/1ps

module KV_LBV2 #(
    parameter D_width = 8,
    parameter D_length = 4
) (
    input wire clk,
    input wire rst_n,
    input wire clear,
    input wire en,
    input wire [D_width-1:0] Din,
    output reg [D_width-1:0] Dout,
    output reg buffer_full
);
    reg [D_width-1:0] LB [0:D_length-1];
    reg [31:0] valid_count;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Dout <= {D_width{1'b0}};
            buffer_full <= 1'b0;
            valid_count <= 32'd0;
            for (i = 0; i < D_length; i = i + 1) begin
                LB[i] <= {D_width{1'b0}};
            end
        end else if (clear) begin
            Dout <= {D_width{1'b0}};
            buffer_full <= 1'b0;
            valid_count <= 32'd0;
            for (i = 0; i < D_length; i = i + 1) begin
                LB[i] <= {D_width{1'b0}};
            end
        end else if (en) begin
            LB[0] <= Din;
            for (i = 1; i < D_length; i = i + 1) begin
                LB[i] <= LB[i - 1];
            end
            Dout <= LB[D_length - 1];
            if (valid_count < D_length) begin
                valid_count <= valid_count + 1'b1;
            end
            buffer_full <= (valid_count >= D_length - 1);
        end
    end
endmodule
