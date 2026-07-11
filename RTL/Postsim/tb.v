`timescale 1ns/1ps

module tb_attention_compare;
    localparam MAX_SEQ_LEN = 128;
    localparam WINDOW_SIZE = 4;
    localparam DILATION = 2;
    localparam GLOBAL_INDEX = 0;
    localparam IDX_WIDTH = 8;
    localparam BUFFER_SEL_WIDTH = 3;
    localparam COUNT_WIDTH = 32;
    localparam FEATURE_DIM = 4;
    localparam FEATURE_IDX_WIDTH = 2;
    localparam DATA_WIDTH = 8;
    localparam SCORE_WIDTH = 32;
`ifdef SDF
    localparam SAMPLE_DELAY = 8;
`else
    localparam SAMPLE_DELAY = 1;
`endif

    localparam MODE_SLIDING = 3'd1;
    localparam MODE_DILATED = 3'd2;
    localparam MODE_SLIDING_GLOBAL = 3'd3;
    localparam MODE_BUTTERFLY = 3'd4;

    reg clk;
    reg rst_n;
    reg full_start;
    reg sparse_start;
    reg [2:0] sparse_mode;
    reg [IDX_WIDTH-1:0] current_seq_len;
    reg qkv_we;
    reg [1:0] qkv_sel;
    reg [IDX_WIDTH-1:0] qkv_token_idx;
    reg [FEATURE_IDX_WIDTH-1:0] qkv_feature_idx;
    reg [DATA_WIDTH-1:0] qkv_data_in;

    wire full_done;
    wire full_pair_valid;
    wire [IDX_WIDTH-1:0] full_q_idx;
    wire [IDX_WIDTH-1:0] full_k_idx;
    wire [COUNT_WIDTH-1:0] full_pair_count;
    wire [COUNT_WIDTH-1:0] full_cycle_count;
    wire [COUNT_WIDTH-1:0] full_mac_count;
    wire full_score_valid;
    wire [SCORE_WIDTH-1:0] full_attention_score;

    wire sparse_done;
    wire sparse_pair_valid;
    wire [IDX_WIDTH-1:0] sparse_q_idx;
    wire [IDX_WIDTH-1:0] sparse_k_idx;
    wire [BUFFER_SEL_WIDTH-1:0] buffer_select;
    wire buffer_load;
    wire evict_valid;
    wire [IDX_WIDTH-1:0] buffer_dout;
    wire [COUNT_WIDTH-1:0] sparse_pair_count;
    wire [COUNT_WIDTH-1:0] sparse_cycle_count;
    wire [COUNT_WIDTH-1:0] sparse_mac_count;
    wire sparse_score_valid;
    wire [SCORE_WIDTH-1:0] sparse_attention_score;
    wire [1:0] buffer_phase;
    wire [1:0] buffer_bank;

    integer errors;
    integer case_errors;
    integer expected_count;
    integer observed_count;
    integer i;
    integer q_expected [0:20000];
    integer k_expected [0:20000];
    integer q_feature_expected [0:MAX_SEQ_LEN*FEATURE_DIM-1];
    integer k_feature_expected [0:MAX_SEQ_LEN*FEATURE_DIM-1];
    integer v_feature_expected [0:MAX_SEQ_LEN*FEATURE_DIM-1];

    full_attention_core #(
        .SEQ_LEN(MAX_SEQ_LEN),
        .IDX_WIDTH(IDX_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH),
        .FEATURE_DIM(FEATURE_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) u_full_attention_core (
        .clk(clk),
        .rst_n(rst_n),
        .start(full_start),
        .cfg_seq_len(current_seq_len),
        .done(full_done),
        .pair_valid(full_pair_valid),
        .q_idx(full_q_idx),
        .k_idx(full_k_idx),
        .pair_count(full_pair_count),
        .cycle_count(full_cycle_count),
        .mac_count(full_mac_count),
        .score_valid(full_score_valid),
        .attention_score(full_attention_score)
    );

    sparse_attention_core #(
        .SEQ_LEN(MAX_SEQ_LEN),
        .WINDOW_SIZE(WINDOW_SIZE),
        .DILATION(DILATION),
        .GLOBAL_INDEX(GLOBAL_INDEX),
        .IDX_WIDTH(IDX_WIDTH),
        .BUFFER_SEL_WIDTH(BUFFER_SEL_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH),
        .FEATURE_DIM(FEATURE_DIM),
        .FEATURE_IDX_WIDTH(FEATURE_IDX_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) u_sparse_attention_core (
        .clk(clk),
        .rst_n(rst_n),
        .start(sparse_start),
        .score_ready(1'b1),
        .cfg_seq_len(current_seq_len),
        .mode(sparse_mode),
        .qkv_we(qkv_we),
        .qkv_sel(qkv_sel),
        .qkv_token_idx(qkv_token_idx),
        .qkv_feature_idx(qkv_feature_idx),
        .qkv_data_in(qkv_data_in),
        .done(sparse_done),
        .pair_valid(sparse_pair_valid),
        .q_idx(sparse_q_idx),
        .k_idx(sparse_k_idx),
        .buffer_phase(buffer_phase),
        .buffer_bank(buffer_bank),
        .buffer_select(buffer_select),
        .buffer_load(buffer_load),
        .evict_valid(evict_valid),
        .buffer_dout(buffer_dout),
        .pair_count(sparse_pair_count),
        .cycle_count(sparse_cycle_count),
        .mac_count(sparse_mac_count),
        .score_valid(sparse_score_valid),
        .attention_score(sparse_attention_score)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

`ifndef NO_FSDB
    initial begin
        $fsdbDumpfile("postsim_attention_compare.fsdb");
        $fsdbDumpvars(0, tb_attention_compare);
        $fsdbDumpMDA();
    end
`endif

`ifdef SDF
    initial begin
        $sdf_annotate("../Syn/full_attention/full_attention_core_syn.sdf", u_full_attention_core);
        $sdf_annotate("sparse_attention_core_syn_postsim.sdf", u_sparse_attention_core);
    end
`endif

    task reset_dut;
        begin
            rst_n = 1'b0;
            full_start = 1'b0;
            sparse_start = 1'b0;
            sparse_mode = MODE_SLIDING;
            current_seq_len = 16;
            qkv_we = 1'b0;
            qkv_sel = 2'd0;
            qkv_token_idx = {IDX_WIDTH{1'b0}};
            qkv_feature_idx = {FEATURE_IDX_WIDTH{1'b0}};
            qkv_data_in = {DATA_WIDTH{1'b0}};
            repeat (4) @(posedge clk);
            rst_n = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    function integer feature_flat_index;
        input integer token;
        input integer feature;
        begin
            feature_flat_index = (token * FEATURE_DIM) + feature;
        end
    endfunction

    function integer q_feature_value;
        input integer token;
        input integer feature;
        begin
            q_feature_value = ((token + 1) * (feature + 2)) % 251;
        end
    endfunction

    function integer k_feature_value;
        input integer token;
        input integer feature;
        begin
            k_feature_value = ((token + 3) * (feature + 1)) % 251;
        end
    endfunction

    function integer v_feature_value;
        input integer token;
        input integer feature;
        begin
            v_feature_value = (token + (feature * 7) + 5) % 251;
        end
    endfunction

    task write_qkv_feature;
        input [1:0] sel;
        input integer token;
        input integer feature;
        input integer value;
        begin
            @(negedge clk);
            qkv_we = 1'b1;
            qkv_sel = sel;
            qkv_token_idx = token;
            qkv_feature_idx = feature;
            qkv_data_in = value;
            @(negedge clk);
            qkv_we = 1'b0;
            qkv_sel = 2'd0;
            qkv_token_idx = {IDX_WIDTH{1'b0}};
            qkv_feature_idx = {FEATURE_IDX_WIDTH{1'b0}};
            qkv_data_in = {DATA_WIDTH{1'b0}};
        end
    endtask

    task load_qkv_features;
        integer token;
        integer feature;
        integer flat_idx;
        begin
            for (token = 0; token < MAX_SEQ_LEN; token = token + 1) begin
                for (feature = 0; feature < FEATURE_DIM; feature = feature + 1) begin
                    flat_idx = feature_flat_index(token, feature);
                    q_feature_expected[flat_idx] = q_feature_value(token, feature);
                    k_feature_expected[flat_idx] = k_feature_value(token, feature);
                    v_feature_expected[flat_idx] = v_feature_value(token, feature);
                    write_qkv_feature(2'd0, token, feature, q_feature_expected[flat_idx]);
                    write_qkv_feature(2'd1, token, feature, k_feature_expected[flat_idx]);
                    write_qkv_feature(2'd2, token, feature, v_feature_expected[flat_idx]);
                end
            end
        end
    endtask

    task add_expected;
        input integer q;
        input integer k;
        begin
            q_expected[expected_count] = q;
            k_expected[expected_count] = k;
            expected_count = expected_count + 1;
        end
    endtask

    task build_full_expected;
        integer q;
        integer k;
        begin
            expected_count = 0;
            for (q = 0; q < current_seq_len; q = q + 1) begin
                for (k = 0; k < current_seq_len; k = k + 1) begin
                    add_expected(q, k);
                end
            end
        end
    endtask

    task build_sliding_expected;
        integer q;
        integer k;
        integer start_k;
        begin
            expected_count = 0;
            for (q = 0; q < current_seq_len; q = q + 1) begin
                start_k = (q / WINDOW_SIZE) * WINDOW_SIZE;
                for (k = start_k; k < start_k + WINDOW_SIZE; k = k + 1) begin
                    add_expected(q, k);
                end
            end
        end
    endtask

    task build_dilated_expected;
        integer q;
        integer k;
        integer start_k;
        begin
            expected_count = 0;
            for (q = 0; q < current_seq_len; q = q + 1) begin
                start_k = (q / WINDOW_SIZE) * WINDOW_SIZE;
                for (k = start_k; k < start_k + WINDOW_SIZE; k = k + DILATION) begin
                    add_expected(q, k);
                end
            end
        end
    endtask

    task build_sliding_global_expected;
        integer q;
        integer k;
        integer start_k;
        integer global_block;
        integer q_block;
        integer k_block;
        begin
            expected_count = 0;
            global_block = (GLOBAL_INDEX / WINDOW_SIZE) * WINDOW_SIZE;
            for (q = 0; q < current_seq_len; q = q + 1) begin
                start_k = (q / WINDOW_SIZE) * WINDOW_SIZE;
                for (k = start_k; k < start_k + WINDOW_SIZE; k = k + 1) begin
                    add_expected(q, k);
                end
            end
            for (q = 0; q < current_seq_len; q = q + 1) begin
                q_block = (q / WINDOW_SIZE) * WINDOW_SIZE;
                if (q_block != global_block) begin
                    add_expected(q, GLOBAL_INDEX);
                end
            end
            for (k = 0; k < current_seq_len; k = k + 1) begin
                k_block = (k / WINDOW_SIZE) * WINDOW_SIZE;
                if (k_block != global_block) begin
                    add_expected(GLOBAL_INDEX, k);
                end
            end
        end
    endtask

    task build_butterfly_expected;
        integer q;
        integer k;
        integer stride;
        begin
            expected_count = 0;
            for (stride = 1; stride < current_seq_len; stride = stride * 2) begin
                for (q = 0; q < current_seq_len; q = q + 1) begin
                    k = q ^ stride;
                    if (k < current_seq_len) begin
                        add_expected(q, k);
                    end
                end
            end
        end
    endtask

    task check_pair;
        input [IDX_WIDTH-1:0] q_actual;
        input [IDX_WIDTH-1:0] k_actual;
        input [SCORE_WIDTH-1:0] score_actual;
        input [127:0] label;
        reg [SCORE_WIDTH-1:0] score_expected;
        begin
            if (label == "full") begin
                score_expected = expected_full_qk_score(q_actual, k_actual);
            end else begin
                score_expected = expected_sparse_qk_score(q_actual, k_actual);
            end
            if (observed_count >= expected_count) begin
                $display("ERROR,%0s,extra_pair,%0d,%0d", label, q_actual, k_actual);
                errors = errors + 1;
                case_errors = case_errors + 1;
            end else if ((q_actual !== q_expected[observed_count]) ||
                         (k_actual !== k_expected[observed_count])) begin
                $display(
                    "ERROR,%0s,pair_mismatch,index=%0d,expected=(%0d,%0d),actual=(%0d,%0d)",
                    label,
                    observed_count,
                    q_expected[observed_count],
                    k_expected[observed_count],
                    q_actual,
                    k_actual
                );
                errors = errors + 1;
                case_errors = case_errors + 1;
            end else if (score_actual !== score_expected) begin
                $display(
                    "ERROR,%0s,score_mismatch,index=%0d,pair=(%0d,%0d),expected_score=%0d,actual_score=%0d",
                    label,
                    observed_count,
                    q_actual,
                    k_actual,
                    score_expected,
                    score_actual
                );
                errors = errors + 1;
                case_errors = case_errors + 1;
            end
            observed_count = observed_count + 1;
        end
    endtask

    function [SCORE_WIDTH-1:0] expected_full_qk_score;
        input [IDX_WIDTH-1:0] q;
        input [IDX_WIDTH-1:0] k;
        integer d;
        reg [SCORE_WIDTH-1:0] q_value;
        reg [SCORE_WIDTH-1:0] k_value;
        begin
            expected_full_qk_score = {SCORE_WIDTH{1'b0}};
            for (d = 0; d < FEATURE_DIM; d = d + 1) begin
                q_value = q + d + 1;
                k_value = k + d + 2;
                expected_full_qk_score = expected_full_qk_score + (q_value * k_value);
            end
        end
    endfunction

    function [SCORE_WIDTH-1:0] expected_sparse_qk_score;
        input [IDX_WIDTH-1:0] q;
        input [IDX_WIDTH-1:0] k;
        integer d;
        reg [SCORE_WIDTH-1:0] q_value;
        reg [SCORE_WIDTH-1:0] k_value;
        begin
            expected_sparse_qk_score = {SCORE_WIDTH{1'b0}};
            for (d = 0; d < FEATURE_DIM; d = d + 1) begin
                q_value = q_feature_expected[feature_flat_index(q, d)];
                k_value = k_feature_expected[feature_flat_index(k, d)];
                expected_sparse_qk_score = expected_sparse_qk_score + (q_value * k_value);
            end
        end
    endfunction

    task run_full_case;
        begin
            case_errors = 0;
            build_full_expected();
            observed_count = 0;
            @(negedge clk);
            full_start = 1'b1;
            @(negedge clk);
            full_start = 1'b0;
            while (!full_done) begin
                @(posedge clk);
                #SAMPLE_DELAY;
                if (full_pair_valid) begin
                    check_pair(full_q_idx, full_k_idx, full_attention_score, "full");
                end
            end
            if (observed_count != expected_count) begin
                $display("ERROR,full,count_mismatch,expected=%0d,actual=%0d", expected_count, observed_count);
                errors = errors + 1;
                case_errors = case_errors + 1;
            end
            print_result("full", expected_count, full_pair_count, full_pair_count,
                         full_cycle_count, full_cycle_count, full_mac_count,
                         full_mac_count, 0.0, (case_errors == 0) ? "PASS" : "FAIL");
        end
    endtask

    task run_sparse_case;
        input [2:0] mode;
        input [127:0] label;
        real reduction;
        begin
            case_errors = 0;
            if (mode == MODE_SLIDING) begin
                build_sliding_expected();
            end else if (mode == MODE_DILATED) begin
                build_dilated_expected();
            end else if (mode == MODE_SLIDING_GLOBAL) begin
                build_sliding_global_expected();
            end else begin
                build_butterfly_expected();
            end

            observed_count = 0;
            sparse_mode = mode;
            @(negedge clk);
            sparse_start = 1'b1;
            @(negedge clk);
            sparse_start = 1'b0;

            while (!sparse_done) begin
                @(posedge clk);
                #SAMPLE_DELAY;
                if (sparse_pair_valid) begin
                    check_pair(sparse_q_idx, sparse_k_idx, sparse_attention_score, label);
                end
            end

            if (observed_count != expected_count) begin
                $display("ERROR,%0s,count_mismatch,expected=%0d,actual=%0d", label, expected_count, observed_count);
                errors = errors + 1;
                case_errors = case_errors + 1;
            end

            reduction = 1.0 - (sparse_pair_count * 1.0 / full_pair_count);
            print_result(label, expected_count, full_pair_count, sparse_pair_count,
                         full_cycle_count, sparse_cycle_count, full_mac_count,
                         sparse_mac_count, reduction, (case_errors == 0) ? "PASS" : "FAIL");
        end
    endtask

    task print_header;
        begin
            $display("");
            $display("-----------------------------------------------------------------------------------------------");
            $display("%-7s %-15s %8s %10s %10s %10s %10s %9s %10s %10s %6s",
                     "seq_len", "mode", "sw_pair", "full_pair", "sprs_pair",
                     "full_cyc", "sprs_cyc", "full_mac", "sprs_mac", "reduction", "check");
            $display("-----------------------------------------------------------------------------------------------");
        end
    endtask

    task print_result;
        input [127:0] mode_name;
        input integer sw_pair_count;
        input integer full_hw_pair_count;
        input integer sparse_hw_pair_count;
        input integer full_hw_cycle_count;
        input integer sparse_hw_cycle_count;
        input integer full_hw_mac_count;
        input integer sparse_hw_mac_count;
        input real reduction;
        input [31:0] check_text;
        begin
            $display("%7d %-15s %8d %10d %10d %10d %10d %9d %10d %10.6f %6s",
                     current_seq_len, mode_name, sw_pair_count, full_hw_pair_count,
                     sparse_hw_pair_count, full_hw_cycle_count, sparse_hw_cycle_count,
                     full_hw_mac_count, sparse_hw_mac_count, reduction, check_text);
        end
    endtask

    task print_seq_block;
        input integer seq_len_value;
        begin
            $display("");
            $display("===============================================================================================");
            $display("SEQ_LEN_BLOCK %0d", seq_len_value);
            $display("===============================================================================================");
        end
    endtask

    task idle_block;
        input integer cycle_num;
        begin
            full_start = 1'b0;
            sparse_start = 1'b0;
            repeat (cycle_num) @(posedge clk);
        end
    endtask

    task run_length_case;
        input integer seq_len_value;
        begin
            idle_block(4);
            current_seq_len = seq_len_value;
            print_seq_block(seq_len_value);
            run_full_case();
            run_sparse_case(MODE_SLIDING, "sliding");
            run_sparse_case(MODE_DILATED, "dilated");
            run_sparse_case(MODE_SLIDING_GLOBAL, "sliding_global");
            run_sparse_case(MODE_BUTTERFLY, "butterfly");
        end
    endtask

    initial begin
        errors = 0;
        reset_dut();
        load_qkv_features();

        print_header();
        run_length_case(16);
        run_length_case(32);
        run_length_case(64);
        run_length_case(128);

        if (errors == 0) begin
            $display("TEST_PASS");
        end else begin
            $display("TEST_FAIL,errors=%0d", errors);
        end
        $finish;
    end
endmodule
