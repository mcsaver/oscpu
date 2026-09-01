`timescale 1ns/1ps
`default_nettype none

module tb_q8_row_tile_functional_core;

    localparam integer ROW_LANES  = 4;
    localparam integer MAX_BLOCKS = 128;
    localparam integer MAX_ROWS   = 5;
    localparam integer TILE_BITS  = ROW_LANES * MAX_BLOCKS * 272;

    localparam logic [7:0] ERROR_WEIGHT_MASK         = 8'h13;
    localparam logic [7:0] ERROR_DPI_NONFINITE_SCALE = 8'h32;

    logic clk_i;
    logic rst_i;

    logic        ref_start;
    logic        ref_ready;
    logic        ref_busy;
    logic [31:0] ref_row_count;
    logic [31:0] ref_block_count;
    logic        ref_activation_valid;
    logic        ref_activation_ready;
    logic [31:0] ref_activation_bits;
    logic        ref_weight_valid;
    logic        ref_weight_ready;
    logic [(ROW_LANES*272)-1:0] ref_weight_blocks;
    logic [ROW_LANES-1:0] ref_weight_mask;
    logic        ref_result_valid;
    logic        ref_result_ready;
    logic [(ROW_LANES*32)-1:0] ref_result_bits;
    logic [ROW_LANES-1:0] ref_result_mask;
    logic [31:0] ref_result_row_base;
    logic        ref_done;
    logic        ref_error;
    logic [7:0]  ref_error_code;
    logic [31:0] ref_error_row;
    logic [63:0] ref_active_cycles;
    logic [31:0] ref_activation_words;
    logic [63:0] ref_weight_blocks_count;
    logic [31:0] ref_rows_emitted;

    logic        bulk_start;
    logic        bulk_ready;
    logic        bulk_busy;
    logic [31:0] bulk_row_count;
    logic [31:0] bulk_block_count;
    logic        bulk_activation_valid;
    logic        bulk_activation_ready;
    logic [31:0] bulk_activation_bits;
    logic        bulk_weight_valid;
    logic        bulk_weight_ready;
    logic [TILE_BITS-1:0] bulk_weight_blocks;
    logic [ROW_LANES-1:0] bulk_weight_mask;
    logic        bulk_result_valid;
    logic        bulk_result_ready;
    logic [(ROW_LANES*32)-1:0] bulk_result_bits;
    logic [ROW_LANES-1:0] bulk_result_mask;
    logic [31:0] bulk_result_row_base;
    logic        bulk_done;
    logic        bulk_error;
    logic [7:0]  bulk_error_code;
    logic [31:0] bulk_error_row;
    logic [63:0] bulk_active_cycles;
    logic [31:0] bulk_activation_words;
    logic [63:0] bulk_weight_blocks_count;
    logic [31:0] bulk_rows_emitted;

    logic [31:0] reference_results [0:MAX_ROWS-1];
    logic [31:0] bulk_results [0:MAX_ROWS-1];

    logic [63:0] last_reference_cycles;
    logic [63:0] last_bulk_cycles;
    logic [63:0] total_reference_cycles;
    logic [63:0] total_bulk_cycles;
    integer total_positive_cases;
    integer total_rows_compared;
    integer total_nonzero_results;
    integer global_cycles;

    TensorNpuQ8RowSimdCore #(
        .ROW_LANES  (ROW_LANES),
        .MAC_LANES  (32),
        .MAX_BLOCKS (MAX_BLOCKS)
    ) u_reference (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .start_i                     (ref_start),
        .ready_o                     (ref_ready),
        .busy_o                      (ref_busy),
        .row_count_i                 (ref_row_count),
        .block_count_i               (ref_block_count),
        .activation_valid_i          (ref_activation_valid),
        .activation_ready_o          (ref_activation_ready),
        .activation_bits_i           (ref_activation_bits),
        .weight_group_valid_i        (ref_weight_valid),
        .weight_group_ready_o        (ref_weight_ready),
        .weight_group_blocks_i       (ref_weight_blocks),
        .weight_group_mask_i         (ref_weight_mask),
        .result_batch_valid_o        (ref_result_valid),
        .result_batch_ready_i        (ref_result_ready),
        .result_batch_bits_o         (ref_result_bits),
        .result_batch_mask_o         (ref_result_mask),
        .result_row_base_o           (ref_result_row_base),
        .done_o                      (ref_done),
        .error_o                     (ref_error),
        .error_code_o                (ref_error_code),
        .error_row_index_o           (ref_error_row),
        .active_cycles_o             (ref_active_cycles),
        .activation_words_accepted_o (ref_activation_words),
        .weight_blocks_accepted_o    (ref_weight_blocks_count),
        .rows_emitted_o              (ref_rows_emitted)
    );

    TensorNpuQ8RowTileFunctionalCore #(
        .ROW_LANES  (ROW_LANES),
        .MAX_BLOCKS (MAX_BLOCKS)
    ) u_bulk (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .start_i                     (bulk_start),
        .ready_o                     (bulk_ready),
        .busy_o                      (bulk_busy),
        .row_count_i                 (bulk_row_count),
        .block_count_i               (bulk_block_count),
        .activation_valid_i          (bulk_activation_valid),
        .activation_ready_o          (bulk_activation_ready),
        .activation_bits_i           (bulk_activation_bits),
        .weight_tile_valid_i         (bulk_weight_valid),
        .weight_tile_ready_o         (bulk_weight_ready),
        .weight_tile_blocks_i        (bulk_weight_blocks),
        .weight_tile_mask_i          (bulk_weight_mask),
        .result_valid_o              (bulk_result_valid),
        .result_ready_i              (bulk_result_ready),
        .result_bits_o               (bulk_result_bits),
        .result_mask_o               (bulk_result_mask),
        .result_row_base_o           (bulk_result_row_base),
        .done_o                      (bulk_done),
        .error_o                     (bulk_error),
        .error_code_o                (bulk_error_code),
        .error_row_index_o           (bulk_error_row),
        .active_cycles_o             (bulk_active_cycles),
        .activation_words_accepted_o (bulk_activation_words),
        .weight_blocks_accepted_o    (bulk_weight_blocks_count),
        .rows_emitted_o              (bulk_rows_emitted)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        global_cycles <= global_cycles + 1;
        if (global_cycles >= 32'd5000000) begin
            $fatal(1, "global timeout cycle=%0d", global_cycles + 1);
        end
        if (!rst_i) begin
            if (ref_done && ref_error) begin
                $fatal(1, "reference DONE/ERROR overlap");
            end
            if (bulk_done && bulk_error) begin
                $fatal(1, "bulk DONE/ERROR overlap");
            end
        end
    end

    function automatic logic [ROW_LANES-1:0] expected_mask(
        input integer row_base,
        input integer rows
    );
        integer lane;
        begin
            expected_mask = '0;
            for (lane = 0; lane < ROW_LANES; lane = lane + 1) begin
                if ((row_base + lane) < rows) begin
                    expected_mask[lane] = 1'b1;
                end
            end
        end
    endfunction

    // Finite raw-F32 fixture with both signs and a deterministic pseudo-random
    // mantissa/exponent branch.  No real/shortreal host oracle is used.
    function automatic logic [31:0] activation_word(
        input integer case_id,
        input integer word_index
    );
        logic [31:0] mixed;
        logic [7:0] exponent;
        begin
            mixed = (32'h9e3779b9 * (word_index + 1))
                  ^ (32'h7f4a7c15 * (case_id + 3));
            case ((word_index + case_id) % 12)
                0: activation_word = 32'h3f800000; // +1
                1: activation_word = 32'hbf000000; // -0.5
                2: activation_word = 32'h40200000; // +2.5
                3: activation_word = 32'hc0600000; // -3.5
                4: activation_word = 32'h41000000; // +8
                5: activation_word = 32'hc1200000; // -10
                6: activation_word = 32'h3e800000; // +0.25
                7: activation_word = 32'hbf400000; // -0.75
                default: begin
                    exponent = 8'd123 + {5'd0, mixed[4:2]};
                    activation_word = {mixed[0], exponent, mixed[27:5]};
                end
            endcase
        end
    endfunction

    function automatic logic [15:0] finite_weight_scale(
        input integer case_id,
        input integer row_index,
        input integer block_index
    );
        integer selector;
        begin
            selector = ((case_id * 3) + (row_index * 5) + block_index) % 12;
            case (selector)
                0: finite_weight_scale = 16'h3c00; // +1
                1: finite_weight_scale = 16'h3800; // +0.5
                2: finite_weight_scale = 16'h4000; // +2
                3: finite_weight_scale = 16'h3400; // +0.25
                4: finite_weight_scale = 16'hbc00; // -1
                5: finite_weight_scale = 16'hb800; // -0.5
                6: finite_weight_scale = 16'h3a00; // +0.75
                7: finite_weight_scale = 16'h4200; // +3
                8: finite_weight_scale = 16'h3600; // +0.375
                9: finite_weight_scale = 16'hbe00; // -1.5
                10: finite_weight_scale = 16'h0001; // +2^-24
                default: finite_weight_scale = 16'h8001; // -2^-24
            endcase
        end
    endfunction

    function automatic logic [271:0] make_weight_block(
        input integer case_id,
        input integer row_index,
        input integer block_index
    );
        logic [271:0] value;
        integer element_index;
        integer quant_value;
        begin
            value = '0;
            value[15:0] = finite_weight_scale(
                case_id, row_index, block_index);
            for (element_index = 0; element_index < 32;
                 element_index = element_index + 1) begin
                quant_value = ((case_id * 29) + (row_index * 37)
                               + (block_index * 19)
                               + (element_index * 7)) % 255;
                quant_value = quant_value - 127;
                // Keep the fixture strongly nonzero without introducing a
                // special all-zero arithmetic path.
                if (quant_value == 0) begin
                    quant_value = ((element_index & 1) == 0) ? 1 : -1;
                end
                value[16 + (element_index*8) +: 8] = quant_value[7:0];
            end
            make_weight_block = value;
        end
    endfunction

    task automatic step_cycle;
        begin
            @(posedge clk_i);
            #1;
        end
    endtask

    task automatic wait_ref_ready;
        integer guard;
        begin
            guard = 0;
            while (ref_ready !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "reference ready timeout");
                end
            end
        end
    endtask

    task automatic wait_bulk_ready;
        integer guard;
        begin
            guard = 0;
            while (bulk_ready !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "bulk ready timeout");
                end
            end
        end
    endtask

    task automatic launch_reference(input integer rows, input integer blocks);
        begin
            wait_ref_ready();
            @(negedge clk_i);
            ref_row_count = rows;
            ref_block_count = blocks;
            ref_start = 1'b1;
            step_cycle();
            ref_start = 1'b0;
        end
    endtask

    task automatic launch_bulk(input integer rows, input integer blocks);
        begin
            wait_bulk_ready();
            @(negedge clk_i);
            bulk_row_count = rows;
            bulk_block_count = blocks;
            bulk_start = 1'b1;
            step_cycle();
            bulk_start = 1'b0;
        end
    endtask

    task automatic feed_reference_activation(
        input integer case_id,
        input integer blocks
    );
        integer word_index;
        integer guard;
        begin
            for (word_index = 0; word_index < blocks*32;
                 word_index = word_index + 1) begin
                guard = 0;
                while (ref_activation_ready !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 2000) begin
                        $fatal(1,
                            "reference activation timeout word=%0d",
                            word_index);
                    end
                end
                @(negedge clk_i);
                ref_activation_bits = activation_word(case_id, word_index);
                ref_activation_valid = 1'b1;
                step_cycle();
                ref_activation_valid = 1'b0;
            end
        end
    endtask

    task automatic feed_bulk_activation(
        input integer case_id,
        input integer blocks
    );
        integer word_index;
        integer guard;
        begin
            for (word_index = 0; word_index < blocks*32;
                 word_index = word_index + 1) begin
                guard = 0;
                while (bulk_activation_ready !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 2000) begin
                        $fatal(1, "bulk activation timeout word=%0d",
                               word_index);
                    end
                end
                @(negedge clk_i);
                bulk_activation_bits = activation_word(case_id, word_index);
                bulk_activation_valid = 1'b1;
                step_cycle();
                bulk_activation_valid = 1'b0;
            end
        end
    endtask

    task automatic build_reference_weight_group(
        input integer case_id,
        input integer row_base,
        input integer rows,
        input integer block_index
    );
        integer lane;
        begin
            ref_weight_blocks = '0;
            ref_weight_mask = expected_mask(row_base, rows);
            for (lane = 0; lane < ROW_LANES; lane = lane + 1) begin
                if ((row_base + lane) < rows) begin
                    ref_weight_blocks[(lane*272) +: 272]
                        = make_weight_block(case_id, row_base + lane,
                                            block_index);
                end
            end
        end
    endtask

    task automatic build_bulk_weight_tile(
        input integer case_id,
        input integer row_base,
        input integer rows,
        input integer blocks
    );
        integer lane;
        integer block_index;
        begin
            bulk_weight_blocks = '0;
            bulk_weight_mask = expected_mask(row_base, rows);
            for (lane = 0; lane < ROW_LANES; lane = lane + 1) begin
                if ((row_base + lane) < rows) begin
                    for (block_index = 0; block_index < blocks;
                         block_index = block_index + 1) begin
                        bulk_weight_blocks[
                            ((lane*MAX_BLOCKS + block_index)*272) +: 272]
                            = make_weight_block(case_id, row_base + lane,
                                                block_index);
                    end
                end
            end
        end
    endtask

    task automatic hold_reference_result(
        input integer hold_cycles,
        input integer row_base,
        input integer rows
    );
        logic [(ROW_LANES*32)-1:0] held_bits;
        logic [ROW_LANES-1:0] held_mask;
        logic [31:0] held_base;
        integer hold_index;
        integer guard;
        integer lane;
        begin
            guard = 0;
            while (ref_result_valid !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 100000) begin
                    $fatal(1, "reference result timeout row=%0d", row_base);
                end
            end
            held_bits = ref_result_bits;
            held_mask = ref_result_mask;
            held_base = ref_result_row_base;
            if (held_mask !== expected_mask(row_base, rows)
                || held_base !== row_base) begin
                $fatal(1, "reference result framing mismatch row=%0d", row_base);
            end
            for (hold_index = 0; hold_index < hold_cycles;
                 hold_index = hold_index + 1) begin
                ref_result_ready = 1'b0;
                step_cycle();
                if (!ref_result_valid || ref_result_bits !== held_bits
                    || ref_result_mask !== held_mask
                    || ref_result_row_base !== held_base) begin
                    $fatal(1, "reference result changed under backpressure");
                end
            end
            for (lane = 0; lane < ROW_LANES; lane = lane + 1) begin
                if (held_mask[lane]) begin
                    reference_results[row_base + lane]
                        = held_bits[(lane*32) +: 32];
                end
            end
            ref_result_ready = 1'b1;
            step_cycle();
            ref_result_ready = 1'b0;
        end
    endtask

    task automatic hold_bulk_result_compare(
        input integer hold_cycles,
        input integer row_base,
        input integer rows
    );
        logic [(ROW_LANES*32)-1:0] held_bits;
        logic [ROW_LANES-1:0] held_mask;
        logic [31:0] held_base;
        integer hold_index;
        integer guard;
        integer lane;
        begin
            guard = 0;
            while (bulk_result_valid !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 100000) begin
                    $fatal(1, "bulk result timeout row=%0d", row_base);
                end
            end
            held_bits = bulk_result_bits;
            held_mask = bulk_result_mask;
            held_base = bulk_result_row_base;
            if (held_mask !== expected_mask(row_base, rows)
                || held_base !== row_base) begin
                $fatal(1, "bulk result framing mismatch row=%0d", row_base);
            end
            for (hold_index = 0; hold_index < hold_cycles;
                 hold_index = hold_index + 1) begin
                bulk_result_ready = 1'b0;
                step_cycle();
                if (!bulk_result_valid || bulk_result_bits !== held_bits
                    || bulk_result_mask !== held_mask
                    || bulk_result_row_base !== held_base) begin
                    $fatal(1, "bulk result changed under backpressure");
                end
            end
            for (lane = 0; lane < ROW_LANES; lane = lane + 1) begin
                if (held_mask[lane]) begin
                    bulk_results[row_base + lane]
                        = held_bits[(lane*32) +: 32];
                    if (held_bits[(lane*32) +: 32]
                        !== reference_results[row_base + lane]) begin
                        $fatal(1,
                            "bit oracle mismatch row=%0d ref=%08x bulk=%08x",
                            row_base + lane,
                            reference_results[row_base + lane],
                            held_bits[(lane*32) +: 32]);
                    end
                end
            end
            bulk_result_ready = 1'b1;
            step_cycle();
            bulk_result_ready = 1'b0;
        end
    endtask

    task automatic run_reference_case(
        input integer case_id,
        input integer blocks,
        input integer rows,
        input integer hold_cycles
    );
        integer row_base;
        integer block_index;
        integer guard;
        begin
            launch_reference(rows, blocks);
            feed_reference_activation(case_id, blocks);
            for (row_base = 0; row_base < rows;
                 row_base = row_base + ROW_LANES) begin
                for (block_index = 0; block_index < blocks;
                     block_index = block_index + 1) begin
                    guard = 0;
                    while (ref_weight_ready !== 1'b1) begin
                        step_cycle();
                        guard = guard + 1;
                        if (guard > 100000) begin
                            $fatal(1,
                                "reference weight timeout row=%0d block=%0d",
                                row_base, block_index);
                        end
                    end
                    @(negedge clk_i);
                    build_reference_weight_group(case_id, row_base, rows,
                                                 block_index);
                    ref_weight_valid = 1'b1;
                    step_cycle();
                    ref_weight_valid = 1'b0;
                end
                hold_reference_result(hold_cycles, row_base, rows);
            end
            guard = 0;
            while (!ref_done && !ref_error) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "reference terminal timeout");
                end
            end
            if (ref_error) begin
                $fatal(1, "reference error code=%02x row=%0d",
                       ref_error_code, ref_error_row);
            end
            if (ref_activation_words !== blocks*32
                || ref_weight_blocks_count !== rows*blocks
                || ref_rows_emitted !== rows) begin
                $fatal(1,
                    "reference ledger mismatch act=%0d weight=%0d rows=%0d",
                    ref_activation_words, ref_weight_blocks_count,
                    ref_rows_emitted);
            end
            last_reference_cycles = ref_active_cycles;
            step_cycle();
        end
    endtask

    task automatic run_bulk_case(
        input integer case_id,
        input integer blocks,
        input integer rows,
        input integer hold_cycles
    );
        integer row_base;
        integer guard;
        begin
            launch_bulk(rows, blocks);
            feed_bulk_activation(case_id, blocks);
            for (row_base = 0; row_base < rows;
                 row_base = row_base + ROW_LANES) begin
                guard = 0;
                while (bulk_weight_ready !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 5000) begin
                        $fatal(1, "bulk weight timeout row=%0d", row_base);
                    end
                end
                @(negedge clk_i);
                build_bulk_weight_tile(case_id, row_base, rows, blocks);
                bulk_weight_valid = 1'b1;
                step_cycle();
                bulk_weight_valid = 1'b0;
                hold_bulk_result_compare(hold_cycles, row_base, rows);
            end
            guard = 0;
            while (!bulk_done && !bulk_error) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "bulk terminal timeout");
                end
            end
            if (bulk_error) begin
                $fatal(1, "bulk error code=%02x row=%0d",
                       bulk_error_code, bulk_error_row);
            end
            if (bulk_activation_words !== blocks*32
                || bulk_weight_blocks_count !== rows*blocks
                || bulk_rows_emitted !== rows) begin
                $fatal(1,
                    "bulk ledger mismatch act=%0d weight=%0d rows=%0d",
                    bulk_activation_words, bulk_weight_blocks_count,
                    bulk_rows_emitted);
            end
            last_bulk_cycles = bulk_active_cycles;
            step_cycle();
        end
    endtask

    task automatic run_positive_case(
        input integer case_id,
        input integer blocks,
        input integer rows
    );
        integer row_index;
        integer case_nonzero;
        integer hold_cycles;
        logic [63:0] speedup_milli;
        begin
            hold_cycles = 2 + (case_id % 3);
            for (row_index = 0; row_index < MAX_ROWS;
                 row_index = row_index + 1) begin
                reference_results[row_index] = 32'hdeadbeef;
                bulk_results[row_index] = 32'hcafef00d;
            end
            run_reference_case(case_id, blocks, rows, hold_cycles);
            run_bulk_case(case_id, blocks, rows, hold_cycles);

            case_nonzero = 0;
            for (row_index = 0; row_index < rows;
                 row_index = row_index + 1) begin
                if (bulk_results[row_index] !== reference_results[row_index]) begin
                    $fatal(1, "post-case result mismatch row=%0d", row_index);
                end
                if (bulk_results[row_index][30:0] != 31'd0) begin
                    case_nonzero = case_nonzero + 1;
                end
            end
            if (case_nonzero == 0) begin
                $fatal(1,
                    "positive case unexpectedly produced only signed zeros");
            end
            if (last_bulk_cycles == 64'd0) begin
                $fatal(1, "bulk cycle ledger is zero");
            end
            speedup_milli = (last_reference_cycles * 64'd1000)
                          / last_bulk_cycles;
            total_reference_cycles = total_reference_cycles
                                   + last_reference_cycles;
            total_bulk_cycles = total_bulk_cycles + last_bulk_cycles;
            total_positive_cases = total_positive_cases + 1;
            total_rows_compared = total_rows_compared + rows;
            total_nonzero_results = total_nonzero_results + case_nonzero;
            $display("[NPU-Q8-ROW-TILE][CASE-PASS] case=%0d B=%0d rows=%0d reference_cycles=%0d bulk_cycles=%0d speedup_milli=%0d nonzero_results=%0d",
                     case_id, blocks, rows, last_reference_cycles,
                     last_bulk_cycles, speedup_milli, case_nonzero);
        end
    endtask

    task automatic expect_bulk_error(
        input logic [7:0] expected_code,
        input integer expected_activation,
        input integer expected_weights
    );
        integer guard;
        begin
            guard = 0;
            while (!bulk_error && !bulk_done) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 5000) begin
                    $fatal(1, "bulk negative terminal timeout");
                end
            end
            if (!bulk_error || bulk_done || bulk_error_code !== expected_code
                || bulk_result_valid || bulk_rows_emitted !== 0
                || bulk_activation_words !== expected_activation
                || bulk_weight_blocks_count !== expected_weights) begin
                $fatal(1,
                    "bulk negative mismatch code=%02x act=%0d weight=%0d rows=%0d valid=%0b",
                    bulk_error_code, bulk_activation_words,
                    bulk_weight_blocks_count, bulk_rows_emitted,
                    bulk_result_valid);
            end
            step_cycle();
        end
    endtask

    task automatic run_wrong_mask_negative;
        integer guard;
        begin
            launch_bulk(5, 2);
            feed_bulk_activation(41, 2);
            guard = 0;
            while (bulk_weight_ready !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 5000) begin
                    $fatal(1, "wrong-mask weight timeout");
                end
            end
            @(negedge clk_i);
            build_bulk_weight_tile(41, 0, 5, 2);
            bulk_weight_mask = 4'b0111;
            bulk_weight_valid = 1'b1;
            step_cycle();
            bulk_weight_valid = 1'b0;
            expect_bulk_error(ERROR_WEIGHT_MASK, 64, 0);
            $display("[NPU-Q8-ROW-TILE][NEGATIVE-PASS] kind=wrong-mask code=%02x",
                     ERROR_WEIGHT_MASK);
        end
    endtask

    task automatic run_nonfinite_scale_negative;
        integer guard;
        begin
            launch_bulk(1, 2);
            feed_bulk_activation(43, 2);
            guard = 0;
            while (bulk_weight_ready !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 5000) begin
                    $fatal(1, "nonfinite-scale weight timeout");
                end
            end
            @(negedge clk_i);
            build_bulk_weight_tile(43, 0, 1, 2);
            bulk_weight_blocks[15:0] = 16'h7c00;
            bulk_weight_valid = 1'b1;
            step_cycle();
            bulk_weight_valid = 1'b0;
            expect_bulk_error(ERROR_DPI_NONFINITE_SCALE, 64, 2);
            $display("[NPU-Q8-ROW-TILE][NEGATIVE-PASS] kind=nonfinite-scale code=%02x",
                     ERROR_DPI_NONFINITE_SCALE);
        end
    endtask

    initial begin
        rst_i = 1'b1;
        global_cycles = 0;

        ref_start = 1'b0;
        ref_row_count = 32'd0;
        ref_block_count = 32'd0;
        ref_activation_valid = 1'b0;
        ref_activation_bits = 32'd0;
        ref_weight_valid = 1'b0;
        ref_weight_blocks = '0;
        ref_weight_mask = '0;
        ref_result_ready = 1'b0;

        bulk_start = 1'b0;
        bulk_row_count = 32'd0;
        bulk_block_count = 32'd0;
        bulk_activation_valid = 1'b0;
        bulk_activation_bits = 32'd0;
        bulk_weight_valid = 1'b0;
        bulk_weight_blocks = '0;
        bulk_weight_mask = '0;
        bulk_result_ready = 1'b0;

        last_reference_cycles = 64'd0;
        last_bulk_cycles = 64'd0;
        total_reference_cycles = 64'd0;
        total_bulk_cycles = 64'd0;
        total_positive_cases = 0;
        total_rows_compared = 0;
        total_nonzero_results = 0;

        repeat (4) step_cycle();
        rst_i = 1'b0;
        step_cycle();
        if (!ref_ready || !bulk_ready || ref_busy || bulk_busy
            || ref_done || ref_error || bulk_done || bulk_error) begin
            $fatal(1, "reset did not establish clean IDLE");
        end

        run_positive_case(0, 1, 1);
        run_positive_case(1, 1, 4);
        run_positive_case(2, 1, 5);
        run_positive_case(3, 2, 1);
        run_positive_case(4, 2, 4);
        run_positive_case(5, 2, 5);
        run_positive_case(6, 32, 1);
        run_positive_case(7, 32, 4);
        run_positive_case(8, 32, 5);
        run_positive_case(9, 112, 1);
        run_positive_case(10, 112, 4);
        run_positive_case(11, 112, 5);

        run_wrong_mask_negative();
        run_nonfinite_scale_negative();

        if (total_positive_cases != 12 || total_rows_compared != 40
            || total_nonzero_results == 0 || total_bulk_cycles == 64'd0
            || total_reference_cycles <= total_bulk_cycles) begin
            $fatal(1,
                "summary mismatch cases=%0d rows=%0d nonzero=%0d ref=%0d bulk=%0d",
                total_positive_cases, total_rows_compared,
                total_nonzero_results, total_reference_cycles,
                total_bulk_cycles);
        end

        $display("[NPU-Q8-ROW-TILE][PASS] cases=%0d rows=%0d B=1,2,32,112 tails=1,4,5 bitwise=%0d nonzero=%0d reference_cycles=%0d bulk_cycles=%0d speedup_milli=%0d wrong_mask=1 nonfinite_scale=1 backpressure=1",
                 total_positive_cases, total_rows_compared,
                 total_rows_compared, total_nonzero_results,
                 total_reference_cycles, total_bulk_cycles,
                 (total_reference_cycles * 64'd1000)
                 / total_bulk_cycles);
        $finish;
    end

endmodule

`default_nettype wire
