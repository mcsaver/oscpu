`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// TensorNpuQ8RowSimdCore
//
// Row-SIMD Q8_0 weight x F32 activation numerical core.
//
// Protocol and ordering invariants:
//   * One shared TensorNpuQ8ReferenceQuantizer consumes B*32 activation words
//     and fills one activation block bank.  Activations are never replicated
//     or requantized per row lane.
//   * A batch starts up to ROW_LANES independent
//     TensorNpuQ8ScaleAccumulator instances.  Every accepted weight group is
//     one common block_index and fires atomically into every active lane.
//   * Each accumulator therefore preserves its public dot -> scale_mul ->
//     term_mul -> RN32 add sequence for block 0..B-1.  This parent contains no
//     numerical bypass, host arithmetic, or alternate reduction topology.
//   * weight_group_mask_i must equal the current batch mask on every group.
//     A malformed group is consumed as a protocol error but is gated away from
//     every child, so weight_blocks_accepted_o remains a true child-fire
//     popcount.
//   * A result batch is registered atomically and all payload fields remain
//     stable while valid is held against backpressure.  rows_emitted_o changes
//     only on a real result batch handshake.  The final handshake precedes the
//     one-cycle DONE terminal.
//   * If multiple row lanes report errors together, the lowest lane number --
//     hence the lowest absolute row index in this contiguous batch -- wins.
module TensorNpuQ8RowSimdCore #(
    parameter integer ROW_LANES  = 4,
    parameter integer MAC_LANES  = 8,
    parameter integer MAX_BLOCKS = 128
) (
    input  wire                         clk_i,
    input  wire                         rst_i,

    input  wire                         start_i,
    output wire                         ready_o,
    output wire                         busy_o,
    input  wire [31:0]                  row_count_i,
    input  wire [31:0]                  block_count_i,

    input  wire                         activation_valid_i,
    output wire                         activation_ready_o,
    input  wire [31:0]                  activation_bits_i,

    input  wire                         weight_group_valid_i,
    output wire                         weight_group_ready_o,
    input  wire [(ROW_LANES*272)-1:0]   weight_group_blocks_i,
    input  wire [ROW_LANES-1:0]         weight_group_mask_i,

    output wire                         result_batch_valid_o,
    input  wire                         result_batch_ready_i,
    output wire [(ROW_LANES*32)-1:0]    result_batch_bits_o,
    output wire [ROW_LANES-1:0]         result_batch_mask_o,
    output wire [31:0]                  result_row_base_o,

    output wire                         done_o,
    output wire                         error_o,
    output wire [7:0]                   error_code_o,
    output wire [31:0]                  error_row_index_o,
    output wire [63:0]                  active_cycles_o,
    output wire [31:0]                  activation_words_accepted_o,
    output wire [63:0]                  weight_blocks_accepted_o,
    output wire [31:0]                  rows_emitted_o
);

    localparam [7:0] ERROR_NONE                = 8'h00;
    localparam [7:0] ERROR_ROW_COUNT_ZERO      = 8'h10;
    localparam [7:0] ERROR_BLOCK_COUNT_ZERO    = 8'h11;
    localparam [7:0] ERROR_BLOCK_COUNT_EXCEEDS = 8'h12;
    localparam [7:0] ERROR_WEIGHT_MASK         = 8'h13;
    localparam [7:0] ERROR_INTERNAL_STATE      = 8'hff;

    localparam [3:0] STATE_IDLE          = 4'd0;
    localparam [3:0] STATE_QUANT_START   = 4'd1;
    localparam [3:0] STATE_QUANT_LOAD32  = 4'd2;
    localparam [3:0] STATE_QUANT_WAIT    = 4'd3;
    localparam [3:0] STATE_BATCH_START   = 4'd4;
    localparam [3:0] STATE_WEIGHT_STREAM = 4'd5;
    localparam [3:0] STATE_BATCH_WAIT    = 4'd6;
    localparam [3:0] STATE_RESULT_HOLD   = 4'd7;
    localparam [3:0] STATE_DONE          = 4'd8;
    localparam [3:0] STATE_ERROR         = 4'd9;

    localparam integer BLOCK_INDEX_WIDTH =
        (MAX_BLOCKS <= 1) ? 1 : $clog2(MAX_BLOCKS);
    localparam [31:0] MAX_BLOCKS_U32 = MAX_BLOCKS;
    localparam [31:0] ROW_LANES_U32  = ROW_LANES;

    generate
        if ((ROW_LANES < 1) || (ROW_LANES > 8)) begin : gen_bad_row_lanes
            initial begin
                $fatal(1,
                    "TensorNpuQ8RowSimdCore ROW_LANES must be in 1..8");
            end
        end
        if ((MAC_LANES < 1) || (MAC_LANES > 32)) begin : gen_bad_mac_lanes
            initial begin
                $fatal(1,
                    "TensorNpuQ8RowSimdCore MAC_LANES must be in 1..32");
            end
        end
        if (MAX_BLOCKS < 1) begin : gen_bad_max_blocks
            initial begin
                $fatal(1,
                    "TensorNpuQ8RowSimdCore MAX_BLOCKS must be >= 1");
            end
        end
    endgenerate

    reg [3:0]  state_q;
    reg [31:0] row_count_q;
    reg [31:0] block_count_q;
    reg [31:0] quant_block_index_q;
    reg [5:0]  quant_word_index_q;
    reg [31:0] row_base_q;
    reg [31:0] weight_block_index_q;

    // Exactly one shared activation bank, written only by the single
    // reference quantizer's successful terminal.
    reg [271:0] activation_block_bank_q [0:MAX_BLOCKS-1];

    reg [ROW_LANES-1:0] lane_done_seen_q;
    reg [ROW_LANES-1:0] lane_error_seen_q;
    reg [31:0] lane_result_q [0:ROW_LANES-1];
    reg [3:0]  lane_error_code_q [0:ROW_LANES-1];

    reg                         result_batch_valid_q;
    reg [(ROW_LANES*32)-1:0]    result_batch_bits_q;
    reg [ROW_LANES-1:0]         result_batch_mask_q;
    reg [31:0]                  result_row_base_q;

    reg [7:0]  error_code_q;
    reg [31:0] error_row_index_q;
    reg [63:0] command_cycles_q;
    reg [63:0] active_cycles_q;
    reg [31:0] activation_words_accepted_q;
    reg [63:0] weight_blocks_accepted_q;
    reg [31:0] rows_emitted_q;

    wire start_fire_w;
    wire activation_fire_w;
    wire weight_group_fire_w;
    wire result_batch_fire_w;
    wire child_rst_w;

    wire                         quant_ready_w;
    wire                         quant_input_ready_w;
    wire                         quant_done_w;
    wire                         quant_error_w;
    wire [3:0]                   quant_error_code_w;
    wire [271:0]                 quant_block_w;

    wire [ROW_LANES-1:0]        active_lane_mask_w;
    wire [ROW_LANES-1:0]        accumulator_ready_w;
    wire [ROW_LANES-1:0]        accumulator_block_ready_w;
    wire [ROW_LANES-1:0]        accumulator_done_w;
    wire [ROW_LANES-1:0]        accumulator_error_w;
    wire [(ROW_LANES*4)-1:0]    accumulator_error_codes_w;
    wire [(ROW_LANES*32)-1:0]   accumulator_results_w;
    wire [ROW_LANES-1:0]        accumulator_start_w;
    wire [ROW_LANES-1:0]        accumulator_block_fire_w;

    wire all_active_accumulators_ready_w;
    wire all_active_block_ready_w;
    wire batch_start_fire_w;
    wire weight_mask_match_w;
    wire [ROW_LANES-1:0] current_terminal_mask_w;
    wire [ROW_LANES-1:0] current_error_mask_w;
    wire [ROW_LANES-1:0] terminal_mask_next_w;
    wire [ROW_LANES-1:0] error_mask_next_w;
    wire all_active_terminal_w;
    wire [31:0] weight_lane_fire_count_w;
    wire [31:0] result_lane_fire_count_w;
    wire [63:0] expected_weight_blocks_w;
    wire [31:0] expected_activation_words_w;

    reg [(ROW_LANES*32)-1:0] collected_results_r;
    reg                        selected_error_valid_r;
    reg [3:0]                  selected_error_code_r;
    reg [31:0]                 selected_error_row_r;
    reg                        selected_mask_error_valid_r;
    reg [31:0]                 selected_mask_error_row_r;

    integer comb_lane;
    integer seq_lane;

    function automatic [31:0] popcount_lanes;
        input [ROW_LANES-1:0] lane_mask;
        integer count_lane;
        begin
            popcount_lanes = 32'b0;
            for (count_lane = 0; count_lane < ROW_LANES;
                 count_lane = count_lane + 1) begin
                if (lane_mask[count_lane]) begin
                    popcount_lanes = popcount_lanes + 32'd1;
                end
            end
        end
    endfunction

    assign ready_o = !rst_i && (state_q == STATE_IDLE);
    assign busy_o  = !rst_i && (state_q != STATE_IDLE);
    assign done_o  = !rst_i && (state_q == STATE_DONE);
    assign error_o = !rst_i && (state_q == STATE_ERROR);

    assign activation_ready_o = !rst_i
                              && (state_q == STATE_QUANT_LOAD32)
                              && quant_input_ready_w;
    assign weight_group_ready_o = !rst_i
                                && (state_q == STATE_WEIGHT_STREAM)
                                && all_active_block_ready_w;
    assign result_batch_valid_o = !rst_i && result_batch_valid_q;

    assign result_batch_bits_o = result_batch_bits_q;
    assign result_batch_mask_o = result_batch_mask_q;
    assign result_row_base_o   = result_row_base_q;
    assign error_code_o        = error_code_q;
    assign error_row_index_o   = error_row_index_q;
    assign active_cycles_o     = active_cycles_q;
    assign activation_words_accepted_o = activation_words_accepted_q;
    assign weight_blocks_accepted_o    = weight_blocks_accepted_q;
    assign rows_emitted_o              = rows_emitted_q;

    assign start_fire_w = start_i && ready_o;
    assign activation_fire_w = activation_valid_i && activation_ready_o;
    assign weight_group_fire_w = weight_group_valid_i
                               && weight_group_ready_o;
    assign result_batch_fire_w = result_batch_valid_o
                               && result_batch_ready_i;

    // ERROR is held for a full cycle.  The following edge synchronously
    // cancels every resident child before the parent reopens IDLE credit.
    assign child_rst_w = rst_i || (state_q == STATE_ERROR);

    assign weight_mask_match_w =
        (weight_group_mask_i == active_lane_mask_w);
    assign all_active_accumulators_ready_w =
        &(accumulator_ready_w | ~active_lane_mask_w);
    assign all_active_block_ready_w =
        &(accumulator_block_ready_w | ~active_lane_mask_w);
    assign batch_start_fire_w = (state_q == STATE_BATCH_START)
                              && all_active_accumulators_ready_w;

    assign accumulator_start_w =
        {ROW_LANES{batch_start_fire_w}} & active_lane_mask_w;
    // Gating with the external group fire makes the group atomic: no fast
    // lane can consume a payload while another active lane is backpressured.
    assign accumulator_block_fire_w =
        {ROW_LANES{weight_group_fire_w && weight_mask_match_w}}
        & active_lane_mask_w;

    assign current_terminal_mask_w = accumulator_done_w
                                   & active_lane_mask_w;
    assign current_error_mask_w = accumulator_done_w
                                & accumulator_error_w
                                & active_lane_mask_w;
    assign terminal_mask_next_w = lane_done_seen_q
                                | current_terminal_mask_w;
    assign error_mask_next_w = lane_error_seen_q | current_error_mask_w;
    assign all_active_terminal_w =
        ((terminal_mask_next_w & active_lane_mask_w) == active_lane_mask_w);

    assign weight_lane_fire_count_w =
        popcount_lanes(accumulator_block_fire_w);
    assign result_lane_fire_count_w =
        popcount_lanes(result_batch_mask_q);
    assign expected_activation_words_w = block_count_q << 5;
    assign expected_weight_blocks_w = {32'b0, row_count_q}
                                    * {32'b0, block_count_q};

    // A 33-bit comparison prevents row_base + lane from wrapping at the end
    // of the 32-bit row index space.
    genvar mask_lane;
    generate
        for (mask_lane = 0; mask_lane < ROW_LANES;
             mask_lane = mask_lane + 1) begin : gen_active_mask
            localparam [32:0] LANE_OFFSET = mask_lane;
            wire [32:0] absolute_row_w;
            assign absolute_row_w = {1'b0, row_base_q} + LANE_OFFSET;
            assign active_lane_mask_w[mask_lane] =
                (absolute_row_w < {1'b0, row_count_q});
        end
    endgenerate

    // Select the completed result from the current terminal wires when
    // present, otherwise from the earlier terminal capture register.
    always @(*) begin
        collected_results_r = {(ROW_LANES*32){1'b0}};
        for (comb_lane = 0; comb_lane < ROW_LANES;
             comb_lane = comb_lane + 1) begin
            if (current_terminal_mask_w[comb_lane]
                && !current_error_mask_w[comb_lane]) begin
                collected_results_r[(comb_lane*32) +: 32]
                    = accumulator_results_w[(comb_lane*32) +: 32];
            end else begin
                collected_results_r[(comb_lane*32) +: 32]
                    = lane_result_q[comb_lane];
            end
        end
    end

    // Lowest active lane is the architecturally selected row error.  A lane
    // may have pulsed terminal on an earlier cycle, hence the code mux between
    // current child output and the capture bank.
    always @(*) begin
        selected_error_valid_r = 1'b0;
        selected_error_code_r  = 4'b0;
        selected_error_row_r   = 32'hffffffff;
        for (comb_lane = 0; comb_lane < ROW_LANES;
             comb_lane = comb_lane + 1) begin
            if (!selected_error_valid_r && error_mask_next_w[comb_lane]) begin
                selected_error_valid_r = 1'b1;
                if (current_error_mask_w[comb_lane]) begin
                    selected_error_code_r = accumulator_error_codes_w[
                        (comb_lane*4) +: 4];
                end else begin
                    selected_error_code_r = lane_error_code_q[comb_lane];
                end
                selected_error_row_r = row_base_q + comb_lane[31:0];
            end
        end
    end

    // A malformed tail mask also reports the lowest differing absolute row.
    always @(*) begin
        selected_mask_error_valid_r = 1'b0;
        selected_mask_error_row_r   = row_base_q;
        for (comb_lane = 0; comb_lane < ROW_LANES;
             comb_lane = comb_lane + 1) begin
            if (!selected_mask_error_valid_r
                && (weight_group_mask_i[comb_lane]
                    != active_lane_mask_w[comb_lane])) begin
                selected_mask_error_valid_r = 1'b1;
                selected_mask_error_row_r = row_base_q + comb_lane[31:0];
            end
        end
    end

    /* verilator lint_off PINCONNECTEMPTY */
    TensorNpuQ8ReferenceQuantizer u_activation_quantizer (
        .clk_i           (clk_i),
        .rst_i           (child_rst_w),
        .start_i         (state_q == STATE_QUANT_START),
        .ready_o         (quant_ready_w),
        .busy_o          (),
        .input_valid_i   (activation_valid_i
                          && (state_q == STATE_QUANT_LOAD32)),
        .input_ready_o   (quant_input_ready_w),
        .input_bits_i    (activation_bits_i),
        .done_o          (quant_done_w),
        .error_o         (quant_error_w),
        .error_code_o    (quant_error_code_w),
        .block_o         (quant_block_w),
        .active_cycles_o ()
    );

    genvar accumulator_lane;
    generate
        for (accumulator_lane = 0; accumulator_lane < ROW_LANES;
             accumulator_lane = accumulator_lane + 1) begin : gen_accumulator
            TensorNpuQ8ScaleAccumulator #(
                .MAC_LANES(MAC_LANES)
            ) u_scale_accumulator (
                .clk_i         (clk_i),
                .rst_i         (child_rst_w),
                .start_i       (accumulator_start_w[accumulator_lane]),
                .ready_o       (accumulator_ready_w[accumulator_lane]),
                .busy_o        (),
                .block_count_i (block_count_q),
                .block_valid_i (
                    accumulator_block_fire_w[accumulator_lane]),
                .block_ready_o (
                    accumulator_block_ready_w[accumulator_lane]),
                .x_block_i     (weight_group_blocks_i[
                    (accumulator_lane*272) +: 272]),
                .y_block_i     (activation_block_bank_q[
                    weight_block_index_q[BLOCK_INDEX_WIDTH-1:0]]),
                .done_o        (accumulator_done_w[accumulator_lane]),
                .error_o       (accumulator_error_w[accumulator_lane]),
                .error_code_o  (accumulator_error_codes_w[
                    (accumulator_lane*4) +: 4]),
                .result_bits_o (accumulator_results_w[
                    (accumulator_lane*32) +: 32])
            );
        end
    endgenerate
    /* verilator lint_on PINCONNECTEMPTY */

    // reset > terminal cleanup > state progress.  Public counters are updated
    // only in the exact external/child handshake states documented above.
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                     <= STATE_IDLE;
            row_count_q                 <= 32'b0;
            block_count_q               <= 32'b0;
            quant_block_index_q         <= 32'b0;
            quant_word_index_q          <= 6'b0;
            row_base_q                  <= 32'b0;
            weight_block_index_q        <= 32'b0;
            lane_done_seen_q            <= {ROW_LANES{1'b0}};
            lane_error_seen_q           <= {ROW_LANES{1'b0}};
            result_batch_valid_q        <= 1'b0;
            result_batch_bits_q         <= {(ROW_LANES*32){1'b0}};
            result_batch_mask_q         <= {ROW_LANES{1'b0}};
            result_row_base_q           <= 32'b0;
            error_code_q                <= ERROR_NONE;
            error_row_index_q           <= 32'hffffffff;
            command_cycles_q            <= 64'b0;
            active_cycles_q             <= 64'b0;
            activation_words_accepted_q <= 32'b0;
            weight_blocks_accepted_q    <= 64'b0;
            rows_emitted_q              <= 32'b0;
            for (seq_lane = 0; seq_lane < ROW_LANES;
                 seq_lane = seq_lane + 1) begin
                lane_result_q[seq_lane]     <= 32'b0;
                lane_error_code_q[seq_lane] <= 4'b0;
            end
        end else begin
            case (state_q)
                STATE_IDLE: begin
                    if (start_fire_w) begin
                        row_count_q          <= row_count_i;
                        block_count_q        <= block_count_i;
                        quant_block_index_q  <= 32'b0;
                        quant_word_index_q   <= 6'b0;
                        row_base_q           <= 32'b0;
                        weight_block_index_q <= 32'b0;
                        lane_done_seen_q     <= {ROW_LANES{1'b0}};
                        lane_error_seen_q    <= {ROW_LANES{1'b0}};
                        result_batch_valid_q <= 1'b0;
                        result_batch_bits_q  <= {(ROW_LANES*32){1'b0}};
                        result_batch_mask_q  <= {ROW_LANES{1'b0}};
                        result_row_base_q    <= 32'b0;
                        error_code_q         <= ERROR_NONE;
                        error_row_index_q    <= 32'hffffffff;
                        command_cycles_q     <= 64'd1;
                        active_cycles_q      <= 64'b0;
                        activation_words_accepted_q <= 32'b0;
                        weight_blocks_accepted_q    <= 64'b0;
                        rows_emitted_q              <= 32'b0;
                        for (seq_lane = 0; seq_lane < ROW_LANES;
                             seq_lane = seq_lane + 1) begin
                            lane_result_q[seq_lane]     <= 32'b0;
                            lane_error_code_q[seq_lane] <= 4'b0;
                        end

                        if (row_count_i == 32'b0) begin
                            state_q           <= STATE_ERROR;
                            error_code_q      <= ERROR_ROW_COUNT_ZERO;
                            active_cycles_q   <= 64'd1;
                        end else if (block_count_i == 32'b0) begin
                            state_q           <= STATE_ERROR;
                            error_code_q      <= ERROR_BLOCK_COUNT_ZERO;
                            active_cycles_q   <= 64'd1;
                        end else if (block_count_i > MAX_BLOCKS_U32) begin
                            state_q           <= STATE_ERROR;
                            error_code_q      <= ERROR_BLOCK_COUNT_EXCEEDS;
                            active_cycles_q   <= 64'd1;
                        end else begin
                            state_q <= STATE_QUANT_START;
                        end
                    end
                end

                STATE_DONE: begin
                    state_q <= STATE_IDLE;
                end

                STATE_ERROR: begin
                    // child_rst_w is still asserted at this edge.
                    state_q <= STATE_IDLE;
                end

                STATE_QUANT_START: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (quant_ready_w) begin
                        quant_word_index_q <= 6'b0;
                        state_q            <= STATE_QUANT_LOAD32;
                    end
                end

                STATE_QUANT_LOAD32: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (activation_fire_w) begin
                        activation_words_accepted_q
                            <= activation_words_accepted_q + 32'd1;
                        if (quant_word_index_q == 6'd31) begin
                            quant_word_index_q <= 6'd32;
                            state_q            <= STATE_QUANT_WAIT;
                        end else begin
                            quant_word_index_q
                                <= quant_word_index_q + 6'd1;
                        end
                    end
                end

                STATE_QUANT_WAIT: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (quant_error_w) begin
                        state_q           <= STATE_ERROR;
                        error_code_q      <= {4'h2, quant_error_code_w};
                        error_row_index_q <= 32'hffffffff;
                        active_cycles_q   <= command_cycles_q + 64'd1;
                        result_batch_valid_q <= 1'b0;
                    end else if (quant_done_w) begin
                        activation_block_bank_q[
                            quant_block_index_q[BLOCK_INDEX_WIDTH-1:0]]
                            <= quant_block_w;
                        if (quant_block_index_q
                            == (block_count_q - 32'd1)) begin
                            row_base_q <= 32'b0;
                            state_q    <= STATE_BATCH_START;
                        end else begin
                            quant_block_index_q
                                <= quant_block_index_q + 32'd1;
                            state_q <= STATE_QUANT_START;
                        end
                    end
                end

                STATE_BATCH_START: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (batch_start_fire_w) begin
                        weight_block_index_q <= 32'b0;
                        lane_done_seen_q     <= {ROW_LANES{1'b0}};
                        lane_error_seen_q    <= {ROW_LANES{1'b0}};
                        for (seq_lane = 0; seq_lane < ROW_LANES;
                             seq_lane = seq_lane + 1) begin
                            lane_result_q[seq_lane]     <= 32'b0;
                            lane_error_code_q[seq_lane] <= 4'b0;
                        end
                        state_q <= STATE_WEIGHT_STREAM;
                    end
                end

                STATE_WEIGHT_STREAM: begin
                    command_cycles_q <= command_cycles_q + 64'd1;

                    if (|current_error_mask_w) begin
                        // An early child error is terminal for this command;
                        // among errors visible together select the lowest row.
                        state_q           <= STATE_ERROR;
                        error_code_q      <= {4'h3, selected_error_code_r};
                        error_row_index_q <= selected_error_row_r;
                        active_cycles_q   <= command_cycles_q + 64'd1;
                        result_batch_valid_q <= 1'b0;
                    end else if (|current_terminal_mask_w) begin
                        // Successful completion before all B groups were
                        // accepted violates the parent/child block contract.
                        state_q           <= STATE_ERROR;
                        error_code_q      <= ERROR_INTERNAL_STATE;
                        error_row_index_q <= row_base_q;
                        active_cycles_q   <= command_cycles_q + 64'd1;
                        result_batch_valid_q <= 1'b0;
                    end else if (weight_group_fire_w) begin
                        if (!weight_mask_match_w) begin
                            state_q           <= STATE_ERROR;
                            error_code_q      <= ERROR_WEIGHT_MASK;
                            error_row_index_q <= selected_mask_error_row_r;
                            active_cycles_q   <= command_cycles_q + 64'd1;
                            result_batch_valid_q <= 1'b0;
                        end else begin
                            weight_blocks_accepted_q
                                <= weight_blocks_accepted_q
                                 + {32'b0, weight_lane_fire_count_w};
                            if (weight_block_index_q
                                == (block_count_q - 32'd1)) begin
                                state_q <= STATE_BATCH_WAIT;
                            end else begin
                                weight_block_index_q
                                    <= weight_block_index_q + 32'd1;
                            end
                        end
                    end
                end

                STATE_BATCH_WAIT: begin
                    command_cycles_q <= command_cycles_q + 64'd1;

                    for (seq_lane = 0; seq_lane < ROW_LANES;
                         seq_lane = seq_lane + 1) begin
                        if (current_terminal_mask_w[seq_lane]) begin
                            lane_done_seen_q[seq_lane] <= 1'b1;
                            lane_result_q[seq_lane] <= accumulator_results_w[
                                (seq_lane*32) +: 32];
                            if (current_error_mask_w[seq_lane]) begin
                                lane_error_seen_q[seq_lane] <= 1'b1;
                                lane_error_code_q[seq_lane]
                                    <= accumulator_error_codes_w[
                                        (seq_lane*4) +: 4];
                            end
                        end
                    end

                    if (all_active_terminal_w) begin
                        if (selected_error_valid_r) begin
                            state_q           <= STATE_ERROR;
                            error_code_q      <= {4'h3,
                                                  selected_error_code_r};
                            error_row_index_q <= selected_error_row_r;
                            active_cycles_q   <= command_cycles_q + 64'd1;
                            result_batch_valid_q <= 1'b0;
                        end else begin
                            result_batch_bits_q  <= collected_results_r;
                            result_batch_mask_q  <= active_lane_mask_w;
                            result_row_base_q    <= row_base_q;
                            result_batch_valid_q <= 1'b1;
                            state_q              <= STATE_RESULT_HOLD;
                        end
                    end
                end

                STATE_RESULT_HOLD: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (result_batch_fire_w) begin
                        result_batch_valid_q <= 1'b0;
                        rows_emitted_q <= rows_emitted_q
                                        + result_lane_fire_count_w;
                        if ((row_count_q - row_base_q) <= ROW_LANES_U32) begin
                            if ((activation_words_accepted_q
                                 == expected_activation_words_w)
                                && (weight_blocks_accepted_q
                                    == expected_weight_blocks_w)
                                && ((rows_emitted_q
                                     + result_lane_fire_count_w)
                                    == row_count_q)) begin
                                state_q         <= STATE_DONE;
                                error_code_q    <= ERROR_NONE;
                                active_cycles_q <= command_cycles_q + 64'd1;
                            end else begin
                                state_q           <= STATE_ERROR;
                                error_code_q      <= ERROR_INTERNAL_STATE;
                                error_row_index_q <= row_base_q;
                                active_cycles_q   <= command_cycles_q + 64'd1;
                            end
                        end else begin
                            row_base_q <= row_base_q + ROW_LANES_U32;
                            state_q    <= STATE_BATCH_START;
                        end
                    end
                end

                default: begin
                    state_q           <= STATE_ERROR;
                    error_code_q      <= ERROR_INTERNAL_STATE;
                    error_row_index_q <= row_base_q;
                    active_cycles_q   <= command_cycles_q + 64'd1;
                    command_cycles_q  <= command_cycles_q + 64'd1;
                    result_batch_valid_q <= 1'b0;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
