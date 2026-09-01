`timescale 1ns/1ps
`default_nettype none

// Self-checking directed test for TensorNpuQ8RowSimdCore.
//
// The numerical oracle is composed only from the public existing RTL:
// one TensorNpuQ8ReferenceQuantizer plus four independent
// TensorNpuQ8ScaleAccumulator instances.  The testbench constructs raw input
// bit patterns and compares raw result bits; it performs no host FP math.
module tb_q8_row_simd_core;

    localparam integer M = 5;
    localparam integer B = 2;

    localparam logic [7:0] ERROR_BLOCK_COUNT_EXCEEDS = 8'h12;
    localparam logic [7:0] ERROR_WEIGHT_MASK         = 8'h13;
    localparam logic [7:0] ERROR_ACC_NONFINITE_SCALE = 8'h32;

    logic clk_i;
    logic rst_i;

    logic        start_1;
    wire         ready_1;
    wire         busy_1;
    logic [31:0] row_count_1;
    logic [31:0] block_count_1;
    logic        activation_valid_1;
    wire         activation_ready_1;
    logic [31:0] activation_bits_1;
    logic        weight_valid_1;
    wire         weight_ready_1;
    logic [271:0] weight_blocks_1;
    logic [0:0]   weight_mask_1;
    wire          result_valid_1;
    logic         result_ready_1;
    wire [31:0]   result_bits_1;
    wire [0:0]    result_mask_1;
    wire [31:0]   result_row_base_1;
    wire          done_1;
    wire          error_1;
    wire [7:0]    error_code_1;
    wire [31:0]   error_row_1;
    wire [63:0]   active_cycles_1;
    wire [31:0]   activation_count_1;
    wire [63:0]   weight_count_1;
    wire [31:0]   rows_count_1;

    logic        start_4;
    wire         ready_4;
    wire         busy_4;
    logic [31:0] row_count_4;
    logic [31:0] block_count_4;
    logic        activation_valid_4;
    wire         activation_ready_4;
    logic [31:0] activation_bits_4;
    logic        weight_valid_4;
    wire         weight_ready_4;
    logic [1087:0] weight_blocks_4;
    logic [3:0]    weight_mask_4;
    wire           result_valid_4;
    logic          result_ready_4;
    wire [127:0]   result_bits_4;
    wire [3:0]     result_mask_4;
    wire [31:0]    result_row_base_4;
    wire           done_4;
    wire           error_4;
    wire [7:0]     error_code_4;
    wire [31:0]    error_row_4;
    wire [63:0]    active_cycles_4;
    wire [31:0]    activation_count_4;
    wire [63:0]    weight_count_4;
    wire [31:0]    rows_count_4;

    logic         oracle_quant_start;
    wire          oracle_quant_ready;
    logic         oracle_quant_input_valid;
    wire          oracle_quant_input_ready;
    logic [31:0]  oracle_quant_input_bits;
    wire          oracle_quant_done;
    wire          oracle_quant_error;
    wire [3:0]    oracle_quant_error_code;
    wire [271:0]  oracle_quant_block;

    logic [3:0]    oracle_acc_start;
    wire [3:0]     oracle_acc_ready;
    logic [31:0]   oracle_acc_block_count;
    logic [3:0]    oracle_acc_block_valid;
    wire [3:0]     oracle_acc_block_ready;
    logic [1087:0] oracle_acc_x_blocks;
    logic [1087:0] oracle_acc_y_blocks;
    wire [3:0]     oracle_acc_done;
    wire [3:0]     oracle_acc_error;
    wire [15:0]    oracle_acc_error_codes;
    wire [127:0]   oracle_acc_results;

    logic [271:0] oracle_activation_bank [0:B-1];
    logic [31:0]  oracle_results [0:M-1];
    logic [31:0]  lane1_results [0:M-1];
    logic [31:0]  lane4_results [0:M-1];

    integer cycle_count;
    integer weight_backpressure_1;
    integer weight_backpressure_4;
    integer result_hold_cycles_1;
    integer result_hold_cycles_4;
    integer positive_done_seen_1;
    integer positive_done_seen_4;
    integer check_row;

    TensorNpuQ8RowSimdCore #(
        .ROW_LANES(1)
    ) dut_lane1 (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .start_i                     (start_1),
        .ready_o                     (ready_1),
        .busy_o                      (busy_1),
        .row_count_i                 (row_count_1),
        .block_count_i               (block_count_1),
        .activation_valid_i          (activation_valid_1),
        .activation_ready_o          (activation_ready_1),
        .activation_bits_i           (activation_bits_1),
        .weight_group_valid_i        (weight_valid_1),
        .weight_group_ready_o        (weight_ready_1),
        .weight_group_blocks_i       (weight_blocks_1),
        .weight_group_mask_i         (weight_mask_1),
        .result_batch_valid_o        (result_valid_1),
        .result_batch_ready_i        (result_ready_1),
        .result_batch_bits_o         (result_bits_1),
        .result_batch_mask_o         (result_mask_1),
        .result_row_base_o           (result_row_base_1),
        .done_o                      (done_1),
        .error_o                     (error_1),
        .error_code_o                (error_code_1),
        .error_row_index_o           (error_row_1),
        .active_cycles_o             (active_cycles_1),
        .activation_words_accepted_o (activation_count_1),
        .weight_blocks_accepted_o    (weight_count_1),
        .rows_emitted_o              (rows_count_1)
    );

    // Production SIMD configuration: four rows in parallel and one dot MAC
    // per Q8 byte.
    TensorNpuQ8RowSimdCore #(
        .ROW_LANES(4),
        .MAC_LANES(32),
        .MAX_BLOCKS(128)
    ) dut_lane4 (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .start_i                     (start_4),
        .ready_o                     (ready_4),
        .busy_o                      (busy_4),
        .row_count_i                 (row_count_4),
        .block_count_i               (block_count_4),
        .activation_valid_i          (activation_valid_4),
        .activation_ready_o          (activation_ready_4),
        .activation_bits_i           (activation_bits_4),
        .weight_group_valid_i        (weight_valid_4),
        .weight_group_ready_o        (weight_ready_4),
        .weight_group_blocks_i       (weight_blocks_4),
        .weight_group_mask_i         (weight_mask_4),
        .result_batch_valid_o        (result_valid_4),
        .result_batch_ready_i        (result_ready_4),
        .result_batch_bits_o         (result_bits_4),
        .result_batch_mask_o         (result_mask_4),
        .result_row_base_o           (result_row_base_4),
        .done_o                      (done_4),
        .error_o                     (error_4),
        .error_code_o                (error_code_4),
        .error_row_index_o           (error_row_4),
        .active_cycles_o             (active_cycles_4),
        .activation_words_accepted_o (activation_count_4),
        .weight_blocks_accepted_o    (weight_count_4),
        .rows_emitted_o              (rows_count_4)
    );

    /* verilator lint_off PINCONNECTEMPTY */
    TensorNpuQ8ReferenceQuantizer u_oracle_quantizer (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .start_i         (oracle_quant_start),
        .ready_o         (oracle_quant_ready),
        .busy_o          (),
        .input_valid_i   (oracle_quant_input_valid),
        .input_ready_o   (oracle_quant_input_ready),
        .input_bits_i    (oracle_quant_input_bits),
        .done_o          (oracle_quant_done),
        .error_o         (oracle_quant_error),
        .error_code_o    (oracle_quant_error_code),
        .block_o         (oracle_quant_block),
        .active_cycles_o ()
    );

    genvar oracle_lane;
    generate
        for (oracle_lane = 0; oracle_lane < 4;
             oracle_lane = oracle_lane + 1) begin : gen_oracle_acc
            TensorNpuQ8ScaleAccumulator #(
                .MAC_LANES(32)
            ) u_oracle_accumulator (
                .clk_i         (clk_i),
                .rst_i         (rst_i),
                .start_i       (oracle_acc_start[oracle_lane]),
                .ready_o       (oracle_acc_ready[oracle_lane]),
                .busy_o        (),
                .block_count_i (oracle_acc_block_count),
                .block_valid_i (oracle_acc_block_valid[oracle_lane]),
                .block_ready_o (oracle_acc_block_ready[oracle_lane]),
                .x_block_i     (oracle_acc_x_blocks[
                    (oracle_lane*272) +: 272]),
                .y_block_i     (oracle_acc_y_blocks[
                    (oracle_lane*272) +: 272]),
                .done_o        (oracle_acc_done[oracle_lane]),
                .error_o       (oracle_acc_error[oracle_lane]),
                .error_code_o  (oracle_acc_error_codes[
                    (oracle_lane*4) +: 4]),
                .result_bits_o (oracle_acc_results[
                    (oracle_lane*32) +: 32])
            );
        end
    endgenerate
    /* verilator lint_on PINCONNECTEMPTY */

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 200000) begin
            $display("[NPU-Q8-ROW-SIMD][FAIL] global timeout cycle=%0d",
                     cycle_count + 1);
            $fatal(1);
        end
        if (!rst_i) begin
            if (done_1 && error_1) begin
                $fatal(1, "lane1 DONE/ERROR overlap");
            end
            if (done_4 && error_4) begin
                $fatal(1, "lane4 DONE/ERROR overlap");
            end
        end
    end

    function automatic [31:0] activation_word(input integer word_index);
        integer pattern_index;
        begin
            pattern_index = word_index % 8;
            if (word_index < 32) begin
                case (pattern_index)
                    0: activation_word = 32'hc2fe0000;
                    1: activation_word = 32'hc2800000;
                    2: activation_word = 32'hbf800000;
                    3: activation_word = 32'h00000000;
                    4: activation_word = 32'h3f800000;
                    5: activation_word = 32'h427c0000;
                    6: activation_word = 32'h42800000;
                    default: activation_word = 32'h42fe0000;
                endcase
            end else begin
                case (pattern_index)
                    0: activation_word = 32'hc1800000;
                    1: activation_word = 32'hc1000000;
                    2: activation_word = 32'hc0800000;
                    3: activation_word = 32'hc0000000;
                    4: activation_word = 32'h3f800000;
                    5: activation_word = 32'h40000000;
                    6: activation_word = 32'h40800000;
                    default: activation_word = 32'h41000000;
                endcase
            end
        end
    endfunction

    function automatic [15:0] weight_scale(
        input integer row_index,
        input integer block_index
    );
        integer scale_index;
        begin
            scale_index = ((row_index * 2) + block_index) % 10;
            case (scale_index)
                0: weight_scale = 16'h3c00;
                1: weight_scale = 16'h3800;
                2: weight_scale = 16'h4000;
                3: weight_scale = 16'h3400;
                4: weight_scale = 16'hbc00;
                5: weight_scale = 16'hb800;
                6: weight_scale = 16'h3a00;
                7: weight_scale = 16'h4200;
                8: weight_scale = 16'h3600;
                default: weight_scale = 16'hbe00;
            endcase
        end
    endfunction

    function automatic [271:0] make_weight_block(
        input integer row_index,
        input integer block_index
    );
        reg [271:0] value;
        integer element_index;
        integer quant_value;
        begin
            value = 272'b0;
            value[15:0] = weight_scale(row_index, block_index);
            for (element_index = 0; element_index < 32;
                 element_index = element_index + 1) begin
                quant_value = ((row_index * 37) + (block_index * 19)
                               + (element_index * 7)) % 63;
                quant_value = quant_value - 31;
                value[16 + (element_index*8) +: 8]
                    = quant_value[7:0];
            end
            make_weight_block = value;
        end
    endfunction

    function automatic [1087:0] make_weight_group4(
        input integer row_base,
        input integer block_index
    );
        reg [1087:0] value;
        integer lane;
        begin
            value = 1088'b0;
            for (lane = 0; lane < 4; lane = lane + 1) begin
                value[(lane*272) +: 272]
                    = make_weight_block(row_base + lane, block_index);
            end
            make_weight_group4 = value;
        end
    endfunction

    function automatic [31:0] mask_popcount4(input [3:0] lane_mask);
        integer lane;
        begin
            mask_popcount4 = 32'b0;
            for (lane = 0; lane < 4; lane = lane + 1) begin
                if (lane_mask[lane]) begin
                    mask_popcount4 = mask_popcount4 + 32'd1;
                end
            end
        end
    endfunction

    task automatic step_cycle;
        begin
            @(posedge clk_i);
            #1;
        end
    endtask

    task automatic wait_both_cores_idle;
        integer guard;
        begin
            guard = 0;
            while ((ready_1 !== 1'b1) || (ready_4 !== 1'b1)) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 4000) begin
                    $fatal(1, "timeout waiting for both cores IDLE");
                end
            end
        end
    endtask

    task automatic build_oracle_activation_bank;
        integer block_index;
        integer element_index;
        integer guard;
        begin
            for (block_index = 0; block_index < B;
                 block_index = block_index + 1) begin
                guard = 0;
                while (oracle_quant_ready !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 2000) begin
                        $fatal(1, "oracle quantizer ready timeout");
                    end
                end
                @(negedge clk_i);
                oracle_quant_start = 1'b1;
                step_cycle();
                oracle_quant_start = 1'b0;

                for (element_index = 0; element_index < 32;
                     element_index = element_index + 1) begin
                    guard = 0;
                    while (oracle_quant_input_ready !== 1'b1) begin
                        step_cycle();
                        guard = guard + 1;
                        if (guard > 1000) begin
                            $fatal(1, "oracle quantizer input timeout");
                        end
                    end
                    @(negedge clk_i);
                    oracle_quant_input_bits
                        = activation_word((block_index*32) + element_index);
                    oracle_quant_input_valid = 1'b1;
                    step_cycle();
                    oracle_quant_input_valid = 1'b0;
                end

                guard = 0;
                while (!oracle_quant_done && !oracle_quant_error) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 2000) begin
                        $fatal(1, "oracle quantizer terminal timeout");
                    end
                end
                if (oracle_quant_error) begin
                    $fatal(1, "oracle quantizer error code=%0h",
                           oracle_quant_error_code);
                end
                oracle_activation_bank[block_index] = oracle_quant_block;
                step_cycle();
            end
        end
    endtask

    task automatic oracle_run_tile(
        input integer row_base,
        input [3:0] active_mask
    );
        integer block_index;
        integer lane;
        integer guard;
        reg [3:0] terminal_seen;
        begin
            guard = 0;
            while ((oracle_acc_ready | ~active_mask) !== 4'hf) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "oracle accumulator ready timeout");
                end
            end
            oracle_acc_block_count = B;
            @(negedge clk_i);
            oracle_acc_start = active_mask;
            step_cycle();
            oracle_acc_start = 4'b0;

            for (block_index = 0; block_index < B;
                 block_index = block_index + 1) begin
                guard = 0;
                while ((oracle_acc_block_ready | ~active_mask) !== 4'hf) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 2000) begin
                        $fatal(1, "oracle accumulator block timeout");
                    end
                end
                @(negedge clk_i);
                for (lane = 0; lane < 4; lane = lane + 1) begin
                    oracle_acc_x_blocks[(lane*272) +: 272]
                        = make_weight_block(row_base + lane, block_index);
                    oracle_acc_y_blocks[(lane*272) +: 272]
                        = oracle_activation_bank[block_index];
                end
                oracle_acc_block_valid = active_mask;
                step_cycle();
                oracle_acc_block_valid = 4'b0;
            end

            terminal_seen = 4'b0;
            guard = 0;
            while ((terminal_seen & active_mask) != active_mask) begin
                step_cycle();
                for (lane = 0; lane < 4; lane = lane + 1) begin
                    if (active_mask[lane] && oracle_acc_done[lane]) begin
                        if (oracle_acc_error[lane]) begin
                            $fatal(1,
                                "oracle accumulator lane=%0d error=%0h",
                                lane,
                                oracle_acc_error_codes[(lane*4) +: 4]);
                        end
                        terminal_seen[lane] = 1'b1;
                        oracle_results[row_base + lane]
                            = oracle_acc_results[(lane*32) +: 32];
                    end
                end
                guard = guard + 1;
                if (guard > 4000) begin
                    $fatal(1, "oracle accumulator terminal timeout");
                end
            end
            step_cycle();
        end
    endtask

    task automatic build_oracle_results;
        begin
            oracle_run_tile(0, 4'hf);
            oracle_run_tile(4, 4'h1);
        end
    endtask

    task automatic launch_positive_cores;
        begin
            wait_both_cores_idle();
            row_count_1   = M;
            block_count_1 = B;
            row_count_4   = M;
            block_count_4 = B;
            @(negedge clk_i);
            start_1 = 1'b1;
            start_4 = 1'b1;
            step_cycle();
            start_1 = 1'b0;
            start_4 = 1'b0;
            if (!busy_1 || !busy_4 || ready_1 || ready_4
                || result_valid_1 || result_valid_4) begin
                $fatal(1, "positive launch protocol mismatch");
            end
        end
    endtask

    task automatic send_activation_both(input integer word_index);
        integer guard;
        reg [31:0] count_before_1;
        reg [31:0] count_before_4;
        reg [31:0] bits;
        begin
            guard = 0;
            while ((activation_ready_1 !== 1'b1)
                   || (activation_ready_4 !== 1'b1)) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1,
                        "core activation credit timeout word=%0d", word_index);
                end
            end
            if ((word_index % 11) == 3) begin
                step_cycle();
                if (!activation_ready_1 || !activation_ready_4) begin
                    $fatal(1, "activation credit changed during input bubble");
                end
            end
            bits = activation_word(word_index);
            count_before_1 = activation_count_1;
            count_before_4 = activation_count_4;
            @(negedge clk_i);
            activation_bits_1  = bits;
            activation_bits_4  = bits;
            activation_valid_1 = 1'b1;
            activation_valid_4 = 1'b1;
            step_cycle();
            activation_valid_1 = 1'b0;
            activation_valid_4 = 1'b0;
            if ((activation_count_1 != (count_before_1 + 32'd1))
                || (activation_count_4 != (count_before_4 + 32'd1))) begin
                $fatal(1, "activation true-fire accounting mismatch");
            end
        end
    endtask

    task automatic send_weight_lane1(
        input integer row_index,
        input integer block_index
    );
        integer guard;
        reg [271:0] held_block;
        reg [63:0] count_before;
        begin
            held_block = make_weight_block(row_index, block_index);
            count_before = weight_count_1;
            @(negedge clk_i);
            weight_blocks_1 = held_block;
            weight_mask_1   = 1'b1;
            weight_valid_1  = 1'b1;
            guard = 0;
            while (weight_ready_1 !== 1'b1) begin
                weight_backpressure_1 = weight_backpressure_1 + 1;
                step_cycle();
                if (!weight_valid_1 || (weight_blocks_1 !== held_block)
                    || (weight_mask_1 !== 1'b1)) begin
                    $fatal(1, "lane1 producer payload changed under stall");
                end
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 4000) begin
                    $fatal(1, "lane1 weight credit timeout");
                end
            end
            step_cycle();
            weight_valid_1 = 1'b0;
            if (weight_count_1 != (count_before + 64'd1)) begin
                $fatal(1, "lane1 weight child-fire count mismatch");
            end
        end
    endtask

    task automatic send_weight_lane4(
        input integer row_base,
        input integer block_index,
        input [3:0] active_mask
    );
        integer guard;
        reg [1087:0] held_blocks;
        reg [63:0] count_before;
        begin
            held_blocks = make_weight_group4(row_base, block_index);
            count_before = weight_count_4;
            @(negedge clk_i);
            weight_blocks_4 = held_blocks;
            weight_mask_4   = active_mask;
            weight_valid_4  = 1'b1;
            guard = 0;
            while (weight_ready_4 !== 1'b1) begin
                weight_backpressure_4 = weight_backpressure_4 + 1;
                step_cycle();
                if (!weight_valid_4 || (weight_blocks_4 !== held_blocks)
                    || (weight_mask_4 !== active_mask)) begin
                    $fatal(1, "lane4 producer payload changed under stall");
                end
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 4000) begin
                    $fatal(1, "lane4 weight group credit timeout");
                end
            end
            step_cycle();
            weight_valid_4 = 1'b0;
            if (weight_count_4
                != (count_before + {32'b0, mask_popcount4(active_mask)})) begin
                $fatal(1, "lane4 weight lane-popcount mismatch");
            end
        end
    endtask

    task automatic drive_lane1_weights;
        integer row_index;
        integer block_index;
        begin
            for (row_index = 0; row_index < M;
                 row_index = row_index + 1) begin
                for (block_index = 0; block_index < B;
                     block_index = block_index + 1) begin
                    send_weight_lane1(row_index, block_index);
                end
            end
        end
    endtask

    task automatic drive_lane4_weights;
        integer block_index;
        begin
            for (block_index = 0; block_index < B;
                 block_index = block_index + 1) begin
                send_weight_lane4(0, block_index, 4'hf);
            end
            for (block_index = 0; block_index < B;
                 block_index = block_index + 1) begin
                send_weight_lane4(4, block_index, 4'h1);
            end
        end
    endtask

    task automatic collect_lane1_results;
        integer row_index;
        integer block_index;
        integer hold_index;
        integer guard;
        reg [31:0] held_bits;
        reg [31:0] held_base;
        reg [0:0]  held_mask;
        reg [31:0] count_before;
        begin
            result_ready_1 = 1'b0;
            for (row_index = 0; row_index < M;
                 row_index = row_index + 1) begin
                for (block_index = 0; block_index < B;
                     block_index = block_index + 1) begin
                    send_weight_lane1(row_index, block_index);
                end
                guard = 0;
                while (result_valid_1 !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 5000) begin
                        $fatal(1, "lane1 result timeout row=%0d", row_index);
                    end
                end
                if ((result_mask_1 !== 1'b1)
                    || (result_row_base_1 !== row_index[31:0])) begin
                    $fatal(1, "lane1 result metadata mismatch row=%0d",
                           row_index);
                end
                held_bits = result_bits_1;
                held_mask = result_mask_1;
                held_base = result_row_base_1;
                count_before = rows_count_1;
                lane1_results[row_index] = held_bits;
                for (hold_index = 0; hold_index < ((row_index % 3) + 1);
                     hold_index = hold_index + 1) begin
                    result_hold_cycles_1 = result_hold_cycles_1 + 1;
                    step_cycle();
                    if (!result_valid_1 || (result_bits_1 !== held_bits)
                        || (result_mask_1 !== held_mask)
                        || (result_row_base_1 !== held_base)
                        || (rows_count_1 !== count_before)
                        || done_1 || error_1) begin
                        $fatal(1, "lane1 result changed under backpressure");
                    end
                end
                @(negedge clk_i);
                result_ready_1 = 1'b1;
                step_cycle();
                result_ready_1 = 1'b0;
                if (rows_count_1 != (count_before + 32'd1)) begin
                    $fatal(1, "lane1 rows_emitted handshake mismatch");
                end
                if (row_index == (M - 1)) begin
                    if (!done_1 || error_1 || result_valid_1
                        || (activation_count_1 != 32'd64)
                        || (weight_count_1 != 64'd10)
                        || (rows_count_1 != 32'd5)
                        || (active_cycles_1 == 64'b0)) begin
                        $fatal(1, "lane1 final-fire/DONE accounting mismatch");
                    end
                    positive_done_seen_1 = 1;
                end else if (done_1 || error_1) begin
                    $fatal(1, "lane1 terminal before final result consume");
                end
            end
        end
    endtask

    task automatic collect_lane4_results;
        integer batch_index;
        integer block_index;
        integer lane;
        integer hold_index;
        integer guard;
        reg [127:0] held_bits;
        reg [3:0]   held_mask;
        reg [31:0]  held_base;
        reg [31:0]  count_before;
        reg [3:0]   expected_mask;
        reg [31:0]  expected_base;
        reg [31:0]  expected_delta;
        begin
            result_ready_4 = 1'b0;
            for (batch_index = 0; batch_index < 2;
                 batch_index = batch_index + 1) begin
                expected_mask = (batch_index == 0) ? 4'hf : 4'h1;
                expected_base = (batch_index == 0) ? 32'd0 : 32'd4;
                expected_delta = mask_popcount4(expected_mask);
                for (block_index = 0; block_index < B;
                     block_index = block_index + 1) begin
                    send_weight_lane4(expected_base, block_index,
                                      expected_mask);
                end
                guard = 0;
                while (result_valid_4 !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 5000) begin
                        $fatal(1, "lane4 result timeout batch=%0d",
                               batch_index);
                    end
                end
                if ((result_mask_4 !== expected_mask)
                    || (result_row_base_4 !== expected_base)) begin
                    $fatal(1,
                        "lane4 result metadata got base=%0d mask=%h expected base=%0d mask=%h",
                        result_row_base_4, result_mask_4,
                        expected_base, expected_mask);
                end
                held_bits = result_bits_4;
                held_mask = result_mask_4;
                held_base = result_row_base_4;
                count_before = rows_count_4;
                for (lane = 0; lane < 4; lane = lane + 1) begin
                    if (expected_mask[lane]) begin
                        lane4_results[expected_base + lane]
                            = held_bits[(lane*32) +: 32];
                    end else if (held_bits[(lane*32) +: 32] !== 32'b0) begin
                        $fatal(1, "inactive tail lane leaked result bits");
                    end
                end
                for (hold_index = 0; hold_index < (batch_index + 3);
                     hold_index = hold_index + 1) begin
                    result_hold_cycles_4 = result_hold_cycles_4 + 1;
                    step_cycle();
                    if (!result_valid_4 || (result_bits_4 !== held_bits)
                        || (result_mask_4 !== held_mask)
                        || (result_row_base_4 !== held_base)
                        || (rows_count_4 !== count_before)
                        || done_4 || error_4) begin
                        $fatal(1, "lane4 result changed under backpressure");
                    end
                end
                @(negedge clk_i);
                result_ready_4 = 1'b1;
                step_cycle();
                result_ready_4 = 1'b0;
                if (rows_count_4 != (count_before + expected_delta)) begin
                    $fatal(1, "lane4 rows_emitted popcount mismatch");
                end
                if (batch_index == 1) begin
                    if (!done_4 || error_4 || result_valid_4
                        || (activation_count_4 != 32'd64)
                        || (weight_count_4 != 64'd10)
                        || (rows_count_4 != 32'd5)
                        || (active_cycles_4 == 64'b0)) begin
                        $fatal(1, "lane4 final-fire/DONE accounting mismatch");
                    end
                    positive_done_seen_4 = 1;
                end else if (done_4 || error_4) begin
                    $fatal(1, "lane4 terminal before last tail batch");
                end
            end
        end
    endtask

    task automatic run_positive_m5_b2;
        integer word_index;
        begin
            launch_positive_cores();
            for (word_index = 0; word_index < 64;
                 word_index = word_index + 1) begin
                send_activation_both(word_index);
            end

            // Both commands are resident at once.  The streams are serviced
            // deterministically (lane1 first, then lane4) to avoid relying on
            // simulator-specific fork scheduling; each core independently
            // holds ready/valid state while the other is being exercised.
            collect_lane1_results();
            collect_lane4_results();

            if ((positive_done_seen_1 != 1)
                || (positive_done_seen_4 != 1)
                || (weight_backpressure_1 == 0)
                || (weight_backpressure_4 == 0)
                || (result_hold_cycles_1 == 0)
                || (result_hold_cycles_4 == 0)) begin
                $fatal(1, "positive protocol coverage census mismatch");
            end

            for (check_row = 0; check_row < M;
                 check_row = check_row + 1) begin
                if ((lane1_results[check_row] !== oracle_results[check_row])
                    || (lane4_results[check_row]
                        !== oracle_results[check_row])
                    || (lane1_results[check_row]
                        !== lane4_results[check_row])) begin
                    $fatal(1,
                        "row bit mismatch row=%0d lane1=%08x lane4=%08x oracle=%08x",
                        check_row, lane1_results[check_row],
                        lane4_results[check_row], oracle_results[check_row]);
                end
            end

            wait_both_cores_idle();
        end
    endtask

    task automatic run_invalid_block_count;
        begin
            wait_both_cores_idle();
            row_count_1   = 32'd5;
            block_count_1 = 32'd129;
            row_count_4   = 32'd5;
            block_count_4 = 32'd129;
            activation_valid_1 = 1'b1;
            activation_valid_4 = 1'b1;
            weight_valid_1 = 1'b1;
            weight_valid_4 = 1'b1;
            result_ready_1 = 1'b1;
            result_ready_4 = 1'b1;
            @(negedge clk_i);
            start_1 = 1'b1;
            start_4 = 1'b1;
            step_cycle();
            start_1 = 1'b0;
            start_4 = 1'b0;
            activation_valid_1 = 1'b0;
            activation_valid_4 = 1'b0;
            weight_valid_1 = 1'b0;
            weight_valid_4 = 1'b0;
            result_ready_1 = 1'b0;
            result_ready_4 = 1'b0;

            if (!error_1 || !error_4 || done_1 || done_4
                || (error_code_1 !== ERROR_BLOCK_COUNT_EXCEEDS)
                || (error_code_4 !== ERROR_BLOCK_COUNT_EXCEEDS)
                || (error_row_1 !== 32'hffffffff)
                || (error_row_4 !== 32'hffffffff)
                || result_valid_1 || result_valid_4
                || (activation_count_1 != 0) || (activation_count_4 != 0)
                || (weight_count_1 != 0) || (weight_count_4 != 0)
                || (rows_count_1 != 0) || (rows_count_4 != 0)) begin
                $fatal(1, "invalid block_count was not fail-closed");
            end
            step_cycle();
            if (!ready_1 || !ready_4 || busy_1 || busy_4
                || result_valid_1 || result_valid_4) begin
                $fatal(1, "invalid-count terminal cleanup mismatch");
            end
        end
    endtask

    task automatic launch_lane4_only(
        input [31:0] rows,
        input [31:0] blocks
    );
        begin
            while (ready_4 !== 1'b1) begin
                step_cycle();
            end
            row_count_4   = rows;
            block_count_4 = blocks;
            @(negedge clk_i);
            start_4 = 1'b1;
            step_cycle();
            start_4 = 1'b0;
            if (!busy_4 || ready_4 || result_valid_4) begin
                $fatal(1, "lane4-only launch mismatch");
            end
        end
    endtask

    task automatic send_activation_lane4_block0;
        integer word_index;
        integer guard;
        reg [31:0] count_before;
        begin
            for (word_index = 0; word_index < 32;
                 word_index = word_index + 1) begin
                guard = 0;
                while (activation_ready_4 !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 2000) begin
                        $fatal(1, "lane4-only activation timeout");
                    end
                end
                count_before = activation_count_4;
                @(negedge clk_i);
                activation_bits_4  = activation_word(word_index);
                activation_valid_4 = 1'b1;
                step_cycle();
                activation_valid_4 = 1'b0;
                if (activation_count_4 != (count_before + 32'd1)) begin
                    $fatal(1, "lane4-only activation count mismatch");
                end
            end
        end
    endtask

    task automatic run_mask_mismatch;
        integer guard;
        begin
            launch_lane4_only(32'd5, 32'd1);
            send_activation_lane4_block0();
            guard = 0;
            while (weight_ready_4 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 3000) begin
                    $fatal(1, "mask-mismatch weight credit timeout");
                end
            end
            @(negedge clk_i);
            weight_blocks_4 = make_weight_group4(0, 0);
            weight_mask_4   = 4'h7;
            weight_valid_4  = 1'b1;
            step_cycle();
            weight_valid_4 = 1'b0;

            if (!error_4 || done_4
                || (error_code_4 !== ERROR_WEIGHT_MASK)
                || (error_row_4 !== 32'd3)
                || result_valid_4
                || (activation_count_4 != 32'd32)
                || (weight_count_4 != 64'd0)
                || (rows_count_4 != 32'd0)) begin
                $fatal(1, "mask mismatch was not atomic fail-closed");
            end
            step_cycle();
            if (!ready_4 || result_valid_4) begin
                $fatal(1, "mask-mismatch terminal cleanup mismatch");
            end
        end
    endtask

    task automatic run_lowest_row_error_priority;
        integer guard;
        reg [1087:0] malformed_group;
        begin
            launch_lane4_only(32'd4, 32'd1);
            send_activation_lane4_block0();
            guard = 0;
            while (weight_ready_4 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 3000) begin
                    $fatal(1, "row-error weight credit timeout");
                end
            end
            malformed_group = make_weight_group4(0, 0);
            malformed_group[(1*272) +: 16] = 16'h7c00;
            malformed_group[(3*272) +: 16] = 16'h7c00;
            @(negedge clk_i);
            weight_blocks_4 = malformed_group;
            weight_mask_4   = 4'hf;
            weight_valid_4  = 1'b1;
            step_cycle();
            weight_valid_4 = 1'b0;
            if (weight_count_4 != 64'd4) begin
                $fatal(1, "malformed scale group child-fire count mismatch");
            end

            guard = 0;
            while (!error_4) begin
                if (result_valid_4 || done_4) begin
                    $fatal(1, "row error published a result/DONE");
                end
                step_cycle();
                guard = guard + 1;
                if (guard > 4000) begin
                    $fatal(1, "row-error terminal timeout");
                end
            end
            if ((error_code_4 !== ERROR_ACC_NONFINITE_SCALE)
                || (error_row_4 !== 32'd1)
                || result_valid_4
                || (activation_count_4 != 32'd32)
                || (weight_count_4 != 64'd4)
                || (rows_count_4 != 32'd0)) begin
                $fatal(1,
                    "lowest absolute row error priority mismatch code=%h row=%0d",
                    error_code_4, error_row_4);
            end
            step_cycle();
            if (!ready_4 || result_valid_4) begin
                $fatal(1, "row-error terminal cleanup mismatch");
            end
        end
    endtask

    initial begin
        cycle_count = 0;
        weight_backpressure_1 = 0;
        weight_backpressure_4 = 0;
        result_hold_cycles_1 = 0;
        result_hold_cycles_4 = 0;
        positive_done_seen_1 = 0;
        positive_done_seen_4 = 0;

        rst_i = 1'b1;
        start_1 = 1'b0;
        row_count_1 = 32'b0;
        block_count_1 = 32'b0;
        activation_valid_1 = 1'b0;
        activation_bits_1 = 32'b0;
        weight_valid_1 = 1'b0;
        weight_blocks_1 = 272'b0;
        weight_mask_1 = 1'b0;
        result_ready_1 = 1'b0;

        start_4 = 1'b0;
        row_count_4 = 32'b0;
        block_count_4 = 32'b0;
        activation_valid_4 = 1'b0;
        activation_bits_4 = 32'b0;
        weight_valid_4 = 1'b0;
        weight_blocks_4 = 1088'b0;
        weight_mask_4 = 4'b0;
        result_ready_4 = 1'b0;

        oracle_quant_start = 1'b0;
        oracle_quant_input_valid = 1'b0;
        oracle_quant_input_bits = 32'b0;
        oracle_acc_start = 4'b0;
        oracle_acc_block_count = 32'b0;
        oracle_acc_block_valid = 4'b0;
        oracle_acc_x_blocks = 1088'b0;
        oracle_acc_y_blocks = 1088'b0;

        for (check_row = 0; check_row < M;
             check_row = check_row + 1) begin
            oracle_results[check_row] = 32'b0;
            lane1_results[check_row]  = 32'b0;
            lane4_results[check_row]  = 32'b0;
        end

        repeat (4) step_cycle();
        if (ready_1 || ready_4 || busy_1 || busy_4
            || result_valid_1 || result_valid_4) begin
            $fatal(1, "reset protocol mismatch");
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        step_cycle();
        if (!ready_1 || !ready_4 || busy_1 || busy_4
            || !oracle_quant_ready || (oracle_acc_ready !== 4'hf)) begin
            $fatal(1, "IDLE credit did not open after reset");
        end

        build_oracle_activation_bank();
        build_oracle_results();
        run_positive_m5_b2();
        run_invalid_block_count();
        run_mask_mismatch();
        run_lowest_row_error_priority();

        repeat (8) begin
            step_cycle();
            if (!ready_1 || !ready_4 || busy_1 || busy_4
                || done_1 || done_4 || error_1 || error_4
                || result_valid_1 || result_valid_4) begin
                $fatal(1, "final stale-terminal observation failed");
            end
        end

        $display("[NPU-Q8-ROW-SIMD][PASS] M=5 B=2 row_lanes=1,4 mac_lanes=8,32 oracle=quantizer+4x-accumulator bit_exact=5 tail_mask=1 result_hold=stable counters=a64,w10,r5 mask_mismatch=atomic invalid_B=closed error_priority=lowest_row");
        $finish;
    end

endmodule

`default_nettype wire
