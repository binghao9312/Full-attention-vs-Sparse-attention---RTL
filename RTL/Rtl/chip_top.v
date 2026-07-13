`timescale 1ns/1ps

module chip_top #(
    parameter SEQ_LEN = 128,
    parameter WINDOW_SIZE = 4,
    parameter DILATION = 2,
    parameter GLOBAL_INDEX = 0,
    parameter IDX_WIDTH = 8,
    parameter BUFFER_SEL_WIDTH = 3,
    parameter COUNT_WIDTH = 32,
    parameter FEATURE_DIM = 4,
    parameter FEATURE_IDX_WIDTH = 2,
    parameter DATA_WIDTH = 8,
    parameter SCORE_WIDTH = 32,
    parameter OUTPUT_FRAC_BITS = 8,
    parameter CONTEXT_WIDTH = DATA_WIDTH + OUTPUT_FRAC_BITS,
    parameter RESULT_FIFO_ADDR_WIDTH = 4
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       req,
    input  wire       rw,
    input  wire [5:0] addr,
    inout  wire [7:0] data_io,
    output wire       ready,
    output wire       irq_done
);
    localparam MODE_SLIDING = 3'd1;
    localparam MODE_DILATED = 3'd2;
    localparam MODE_SLIDING_GLOBAL = 3'd3;
    localparam MODE_BUTTERFLY = 3'd4;

    localparam ADDR_CONTROL = 6'h00;
    localparam ADDR_SEQ_LEN = 6'h01;
    localparam ADDR_QKV_ADDR_L = 6'h02;
    localparam ADDR_QKV_ADDR_H = 6'h03;
    localparam ADDR_QKV_DATA = 6'h04;
    localparam ADDR_STATUS = 6'h05;
    localparam ADDR_RESULT_Q_IDX = 6'h08;
    localparam ADDR_RESULT_FEATURE_IDX = 6'h09;
    localparam ADDR_RESULT_VALUE_0 = 6'h0A;
    localparam ADDR_RESULT_VALUE_1 = 6'h0B;
    localparam ADDR_RESULT_VALUE_2 = 6'h0C;
    localparam ADDR_RESULT_VALUE_3 = 6'h0D;
    localparam ADDR_RESULT_POP = 6'h0E;
    localparam ADDR_PAIR_COUNT_0 = 6'h10;
    localparam ADDR_PAIR_COUNT_1 = 6'h11;
    localparam ADDR_PAIR_COUNT_2 = 6'h12;
    localparam ADDR_PAIR_COUNT_3 = 6'h13;
    localparam ADDR_CYCLE_COUNT_0 = 6'h14;
    localparam ADDR_CYCLE_COUNT_1 = 6'h15;
    localparam ADDR_CYCLE_COUNT_2 = 6'h16;
    localparam ADDR_CYCLE_COUNT_3 = 6'h17;
    localparam ADDR_MAC_COUNT_0 = 6'h18;
    localparam ADDR_MAC_COUNT_1 = 6'h19;
    localparam ADDR_MAC_COUNT_2 = 6'h1A;
    localparam ADDR_MAC_COUNT_3 = 6'h1B;

    localparam RESULT_FIFO_DEPTH = (1 << RESULT_FIFO_ADDR_WIDTH);
    localparam RESULT_FIFO_WIDTH = IDX_WIDTH + FEATURE_IDX_WIDTH + CONTEXT_WIDTH;
    localparam [RESULT_FIFO_ADDR_WIDTH:0] RESULT_FIFO_DEPTH_COUNT = (1 << RESULT_FIFO_ADDR_WIDTH);

    reg rst_sync_0;
    reg rst_sync_1;
    wire internal_rst_n;

    wire [7:0] data_i;
    reg [7:0] data_o;
    wire data_oe;

    reg busy;
    reg done_sticky;
    reg result_overflow;
    reg protocol_error;
    reg [7:0] seq_len_reg;
    reg [2:0] mode_reg;
    reg [10:0] qkv_addr;
    reg core_start;
    wire qkv_we;

    wire [1:0] qkv_sel;
    wire [IDX_WIDTH-1:0] qkv_token_idx;
    wire [FEATURE_IDX_WIDTH-1:0] qkv_feature_idx;
    wire qkv_addr_in_range;

    wire core_done;
    wire core_pair_valid;
    wire [IDX_WIDTH-1:0] core_q_idx;
    wire [IDX_WIDTH-1:0] core_k_idx;
    wire [COUNT_WIDTH-1:0] core_pair_count;
    wire [COUNT_WIDTH-1:0] core_cycle_count;
    wire [COUNT_WIDTH-1:0] core_mac_count;
    wire core_score_valid;
    wire [SCORE_WIDTH-1:0] core_attention_score;
    wire core_context_valid;
    wire [IDX_WIDTH-1:0] core_context_q_idx;
    wire [FEATURE_IDX_WIDTH-1:0] core_context_feature_idx;
    wire [CONTEXT_WIDTH-1:0] core_context_value;
    wire core_context_ready;
    wire [1:0] unused_buffer_phase;
    wire [1:0] unused_buffer_bank;
    wire [BUFFER_SEL_WIDTH-1:0] unused_buffer_select;
    wire unused_buffer_load;
    wire unused_evict_valid;
    wire [IDX_WIDTH-1:0] unused_buffer_dout;

    reg [COUNT_WIDTH-1:0] pair_count_snapshot;
    reg [COUNT_WIDTH-1:0] cycle_count_snapshot;
    reg [COUNT_WIDTH-1:0] mac_count_snapshot;

    reg [RESULT_FIFO_WIDTH-1:0] result_fifo [0:RESULT_FIFO_DEPTH-1];
    reg [RESULT_FIFO_ADDR_WIDTH-1:0] fifo_wr_ptr;
    reg [RESULT_FIFO_ADDR_WIDTH-1:0] fifo_rd_ptr;
    reg [RESULT_FIFO_ADDR_WIDTH:0] fifo_count;
    wire fifo_empty;
    wire fifo_full;
    wire result_valid;
    wire fifo_push;
    wire fifo_pop_req;
    wire fifo_pop_valid;
    wire [RESULT_FIFO_WIDTH-1:0] fifo_front;
    wire [IDX_WIDTH-1:0] result_q_idx;
    wire [FEATURE_IDX_WIDTH-1:0] result_feature_idx;
    wire [CONTEXT_WIDTH-1:0] result_value;

    wire bus_read;
    wire bus_write;
    wire [2:0] control_mode_write;
    wire control_mode_valid;
    wire seq_len_write_valid;
    wire seq_len_reg_valid;
    wire start_mode_valid;
    wire illegal_read_addr;

    assign internal_rst_n = rst_sync_1;
    assign ready = internal_rst_n;
    assign irq_done = done_sticky;

    assign data_i = data_io;
    assign data_oe = internal_rst_n && req && rw;
    assign data_io = data_oe ? data_o : 8'hZZ;

    assign bus_read = req && ready && rw;
    assign bus_write = req && ready && !rw;

    assign qkv_addr_in_range = (qkv_addr <= 11'h5FF);
    assign qkv_we = bus_write && (addr == ADDR_QKV_DATA) && !busy && qkv_addr_in_range;
    assign qkv_sel = qkv_addr[10:9];
    assign qkv_token_idx = {{(IDX_WIDTH-7){1'b0}}, qkv_addr[8:2]};
    assign qkv_feature_idx = qkv_addr[FEATURE_IDX_WIDTH-1:0];

    assign fifo_empty = (fifo_count == 0);
    assign fifo_full = (fifo_count == RESULT_FIFO_DEPTH_COUNT);
    assign result_valid = !fifo_empty;
    assign core_context_ready = !fifo_full;
    assign fifo_push = core_context_valid && core_context_ready;
    assign fifo_pop_req = bus_write && (addr == ADDR_RESULT_POP) && data_i[0];
    assign fifo_pop_valid = fifo_pop_req && !fifo_empty;
    assign fifo_front = result_fifo[fifo_rd_ptr];
    assign result_q_idx = fifo_front[RESULT_FIFO_WIDTH-1 -: IDX_WIDTH];
    assign result_feature_idx = fifo_front[CONTEXT_WIDTH +: FEATURE_IDX_WIDTH];
    assign result_value = fifo_front[CONTEXT_WIDTH-1:0];

    assign control_mode_write = data_i[3:1];
    assign control_mode_valid = (control_mode_write == MODE_SLIDING) ||
                                (control_mode_write == MODE_DILATED) ||
                                (control_mode_write == MODE_SLIDING_GLOBAL) ||
                                (control_mode_write == MODE_BUTTERFLY);
    assign start_mode_valid = (control_mode_write == 3'b000) || control_mode_valid;
    assign seq_len_write_valid = (data_i >= 8'd1) && (data_i <= SEQ_LEN);
    assign seq_len_reg_valid = (seq_len_reg >= 8'd1) && (seq_len_reg <= SEQ_LEN);
    assign illegal_read_addr =
        (addr != ADDR_CONTROL) &&
        (addr != ADDR_SEQ_LEN) &&
        (addr != ADDR_QKV_ADDR_L) &&
        (addr != ADDR_QKV_ADDR_H) &&
        (addr != ADDR_STATUS) &&
        (addr != ADDR_RESULT_Q_IDX) &&
        (addr != ADDR_RESULT_FEATURE_IDX) &&
        (addr != ADDR_RESULT_VALUE_0) &&
        (addr != ADDR_RESULT_VALUE_1) &&
        (addr != ADDR_RESULT_VALUE_2) &&
        (addr != ADDR_RESULT_VALUE_3) &&
        (addr != ADDR_PAIR_COUNT_0) &&
        (addr != ADDR_PAIR_COUNT_1) &&
        (addr != ADDR_PAIR_COUNT_2) &&
        (addr != ADDR_PAIR_COUNT_3) &&
        (addr != ADDR_CYCLE_COUNT_0) &&
        (addr != ADDR_CYCLE_COUNT_1) &&
        (addr != ADDR_CYCLE_COUNT_2) &&
        (addr != ADDR_CYCLE_COUNT_3) &&
        (addr != ADDR_MAC_COUNT_0) &&
        (addr != ADDR_MAC_COUNT_1) &&
        (addr != ADDR_MAC_COUNT_2) &&
        (addr != ADDR_MAC_COUNT_3);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_sync_0 <= 1'b0;
            rst_sync_1 <= 1'b0;
        end else begin
            rst_sync_0 <= 1'b1;
            rst_sync_1 <= rst_sync_0;
        end
    end

    always @(*) begin
        data_o = 8'h00;
        case (addr)
            ADDR_CONTROL: data_o = {3'b000, 1'b0, mode_reg, 1'b0};
            ADDR_SEQ_LEN: data_o = seq_len_reg;
            ADDR_QKV_ADDR_L: data_o = qkv_addr[7:0];
            ADDR_QKV_ADDR_H: data_o = {5'b00000, qkv_addr[10:8]};
            ADDR_STATUS: data_o = {2'b00, protocol_error, result_overflow, fifo_full, result_valid, done_sticky, busy};
            ADDR_RESULT_Q_IDX: data_o = result_valid ? result_q_idx : 8'h00;
            ADDR_RESULT_FEATURE_IDX: data_o = result_valid ? {{(8-FEATURE_IDX_WIDTH){1'b0}}, result_feature_idx} : 8'h00;
            ADDR_RESULT_VALUE_0: data_o = result_valid ? result_value[7:0] : 8'h00;
            ADDR_RESULT_VALUE_1: data_o = result_valid ? result_value[15:8] : 8'h00;
            ADDR_RESULT_VALUE_2: data_o = 8'h00;
            ADDR_RESULT_VALUE_3: data_o = 8'h00;
            ADDR_PAIR_COUNT_0: data_o = pair_count_snapshot[7:0];
            ADDR_PAIR_COUNT_1: data_o = pair_count_snapshot[15:8];
            ADDR_PAIR_COUNT_2: data_o = pair_count_snapshot[23:16];
            ADDR_PAIR_COUNT_3: data_o = pair_count_snapshot[31:24];
            ADDR_CYCLE_COUNT_0: data_o = cycle_count_snapshot[7:0];
            ADDR_CYCLE_COUNT_1: data_o = cycle_count_snapshot[15:8];
            ADDR_CYCLE_COUNT_2: data_o = cycle_count_snapshot[23:16];
            ADDR_CYCLE_COUNT_3: data_o = cycle_count_snapshot[31:24];
            ADDR_MAC_COUNT_0: data_o = mac_count_snapshot[7:0];
            ADDR_MAC_COUNT_1: data_o = mac_count_snapshot[15:8];
            ADDR_MAC_COUNT_2: data_o = mac_count_snapshot[23:16];
            ADDR_MAC_COUNT_3: data_o = mac_count_snapshot[31:24];
            default: data_o = 8'h00;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || !internal_rst_n) begin
            busy <= 1'b0;
            done_sticky <= 1'b0;
            result_overflow <= 1'b0;
            protocol_error <= 1'b0;
            seq_len_reg <= 8'd16;
            mode_reg <= MODE_SLIDING;
            qkv_addr <= 11'h000;
            core_start <= 1'b0;
            pair_count_snapshot <= {COUNT_WIDTH{1'b0}};
            cycle_count_snapshot <= {COUNT_WIDTH{1'b0}};
            mac_count_snapshot <= {COUNT_WIDTH{1'b0}};
            fifo_wr_ptr <= {RESULT_FIFO_ADDR_WIDTH{1'b0}};
            fifo_rd_ptr <= {RESULT_FIFO_ADDR_WIDTH{1'b0}};
            fifo_count <= {(RESULT_FIFO_ADDR_WIDTH+1){1'b0}};
        end else begin
            core_start <= 1'b0;

            if (core_done) begin
                busy <= 1'b0;
                done_sticky <= 1'b1;
                pair_count_snapshot <= core_pair_count;
                cycle_count_snapshot <= core_cycle_count;
                mac_count_snapshot <= core_mac_count;
            end

            if (bus_read && illegal_read_addr) begin
                protocol_error <= 1'b1;
            end

            if (bus_write) begin
                case (addr)
                    ADDR_CONTROL: begin
                        if (data_i[7:5] != 3'b000) begin
                            protocol_error <= 1'b1;
                        end

                        if (data_i[4]) begin
                            if (busy) begin
                                protocol_error <= 1'b1;
                            end else begin
                                fifo_wr_ptr <= {RESULT_FIFO_ADDR_WIDTH{1'b0}};
                                fifo_rd_ptr <= {RESULT_FIFO_ADDR_WIDTH{1'b0}};
                                fifo_count <= {(RESULT_FIFO_ADDR_WIDTH+1){1'b0}};
                                result_overflow <= 1'b0;
                            end
                        end

                        if (data_i[3:1] != 3'b000) begin
                            if (busy || !control_mode_valid) begin
                                protocol_error <= 1'b1;
                            end else begin
                                mode_reg <= control_mode_write;
                            end
                        end

                        if (data_i[0]) begin
                            if (busy || !seq_len_reg_valid || !start_mode_valid) begin
                                protocol_error <= 1'b1;
                            end else begin
                                core_start <= 1'b1;
                                busy <= 1'b1;
                                done_sticky <= 1'b0;
                            end
                        end
                    end

                    ADDR_SEQ_LEN: begin
                        if (busy || !seq_len_write_valid) begin
                            protocol_error <= 1'b1;
                        end else begin
                            seq_len_reg <= data_i;
                        end
                    end

                    ADDR_QKV_ADDR_L: begin
                        if (busy) begin
                            protocol_error <= 1'b1;
                        end else begin
                            qkv_addr[7:0] <= data_i;
                        end
                    end

                    ADDR_QKV_ADDR_H: begin
                        if (busy || (data_i[7:3] != 5'b00000)) begin
                            protocol_error <= 1'b1;
                        end else begin
                            qkv_addr[10:8] <= data_i[2:0];
                        end
                    end

                    ADDR_QKV_DATA: begin
                        if (busy || !qkv_addr_in_range) begin
                            protocol_error <= 1'b1;
                        end else begin
                            qkv_addr <= qkv_addr + 1'b1;
                        end
                    end

                    ADDR_RESULT_POP: begin
                        if (data_i[0] && fifo_empty) begin
                            protocol_error <= 1'b1;
                        end
                    end

                    default: begin
                        protocol_error <= 1'b1;
                    end
                endcase
            end

            if (!(bus_write && (addr == ADDR_CONTROL) && data_i[4] && !busy)) begin
                if (fifo_push && fifo_pop_valid) begin
                    result_fifo[fifo_wr_ptr] <= {core_context_q_idx, core_context_feature_idx, core_context_value};
                    fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                end else if (fifo_push) begin
                    result_fifo[fifo_wr_ptr] <= {core_context_q_idx, core_context_feature_idx, core_context_value};
                    fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                    fifo_count <= fifo_count + 1'b1;
                end else if (fifo_pop_valid) begin
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                    fifo_count <= fifo_count - 1'b1;
                end
            end
        end
    end

    sparse_attention_core #(
        .SEQ_LEN(SEQ_LEN),
        .WINDOW_SIZE(WINDOW_SIZE),
        .DILATION(DILATION),
        .GLOBAL_INDEX(GLOBAL_INDEX),
        .IDX_WIDTH(IDX_WIDTH),
        .BUFFER_SEL_WIDTH(BUFFER_SEL_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH),
        .FEATURE_DIM(FEATURE_DIM),
        .FEATURE_IDX_WIDTH(FEATURE_IDX_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SCORE_WIDTH(SCORE_WIDTH),
        .OUTPUT_FRAC_BITS(OUTPUT_FRAC_BITS),
        .CONTEXT_WIDTH(CONTEXT_WIDTH)
    ) u_sparse_attention_core (
        .clk(clk),
        .rst_n(internal_rst_n),
        .start(core_start),
        .score_ready(1'b1),
        .context_ready(core_context_ready),
        .cfg_seq_len(seq_len_reg),
        .mode(mode_reg),
        .qkv_we(qkv_we),
        .qkv_sel(qkv_sel),
        .qkv_token_idx(qkv_token_idx),
        .qkv_feature_idx(qkv_feature_idx),
        .qkv_data_in(data_i),
        .done(core_done),
        .pair_valid(core_pair_valid),
        .q_idx(core_q_idx),
        .k_idx(core_k_idx),
        .buffer_phase(unused_buffer_phase),
        .buffer_bank(unused_buffer_bank),
        .buffer_select(unused_buffer_select),
        .buffer_load(unused_buffer_load),
        .evict_valid(unused_evict_valid),
        .buffer_dout(unused_buffer_dout),
        .pair_count(core_pair_count),
        .cycle_count(core_cycle_count),
        .mac_count(core_mac_count),
        .score_valid(core_score_valid),
        .attention_score(core_attention_score),
        .context_valid(core_context_valid),
        .context_q_idx(core_context_q_idx),
        .context_feature_idx(core_context_feature_idx),
        .context_value(core_context_value)
    );
endmodule
