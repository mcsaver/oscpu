`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// Simulation-only whole-row-tile Q8_0 functional core.
//
// The synthesizable/public Q8 core remains TensorNpuQ8RowSimdCore.  This
// module deliberately keeps the transport, quantization, command protocol,
// publication point, and all ledgers in RTL, while replacing only the
// block-at-a-time arithmetic schedule with one DPI-C functional transaction
// per row tile.  DPI receives fixed packed raw blocks; it has no address,
// allocation, or tensor-memory interface.
//
// Ordering invariants:
//   * one TensorNpuQ8ReferenceQuantizer is shared across all rows;
//   * each of B activation blocks is quantized exactly once and retained in an
//     RTL-owned bank;
//   * one weight-tile handshake carries B raw Q8_0 blocks for every active
//     lane, laid out lane-major then block-major;
//   * the DPI result is registered and published only after a zero status;
//   * result payload/mask/base remain stable under ready backpressure;
//   * malformed masks and numerical failures never publish a result.
module TensorNpuQ8RowTileFunctionalCore #(
    parameter integer ROW_LANES  = 4,
    parameter integer MAX_BLOCKS = 128
) (
    input  logic clk_i,
    input  logic rst_i,

    input  logic        start_i,
    output logic        ready_o,
    output logic        busy_o,
    input  logic [31:0] row_count_i,
    input  logic [31:0] block_count_i,

    input  logic        activation_valid_i,
    output logic        activation_ready_o,
    input  logic [31:0] activation_bits_i,

    input  logic weight_tile_valid_i,
    output logic weight_tile_ready_o,
    input  logic [(ROW_LANES*MAX_BLOCKS*272)-1:0]
                       weight_tile_blocks_i,
    input  logic [ROW_LANES-1:0] weight_tile_mask_i,

    output logic                      result_valid_o,
    input  logic                      result_ready_i,
    output logic [(ROW_LANES*32)-1:0] result_bits_o,
    output logic [ROW_LANES-1:0]      result_mask_o,
    output logic [31:0]               result_row_base_o,

    output logic        done_o,
    output logic        error_o,
    output logic [7:0]  error_code_o,
    output logic [31:0] error_row_index_o,
    output logic [63:0] active_cycles_o,
    output logic [31:0] activation_words_accepted_o,
    output logic [63:0] weight_blocks_accepted_o,
    output logic [31:0] rows_emitted_o
);

    localparam integer ACTIVATION_BANK_BITS = MAX_BLOCKS * 272;
    localparam integer WEIGHT_TILE_BITS = ROW_LANES * MAX_BLOCKS * 272;
    localparam integer RESULT_BITS = ROW_LANES * 32;
    localparam integer BLOCK_INDEX_WIDTH =
        (MAX_BLOCKS <= 1) ? 1 : $clog2(MAX_BLOCKS);

    localparam logic [31:0] MAX_BLOCKS_U32 = MAX_BLOCKS;
    localparam logic [31:0] ROW_LANES_U32  = ROW_LANES;

    localparam logic [7:0] ERROR_NONE                = 8'h00;
    localparam logic [7:0] ERROR_ROW_COUNT_ZERO      = 8'h10;
    localparam logic [7:0] ERROR_BLOCK_COUNT_ZERO    = 8'h11;
    localparam logic [7:0] ERROR_BLOCK_COUNT_EXCEEDS = 8'h12;
    localparam logic [7:0] ERROR_WEIGHT_MASK         = 8'h13;
    localparam logic [7:0] ERROR_DPI_NONFINITE_SCALE = 8'h32;
    localparam logic [7:0] ERROR_DPI_DOT_RANGE       = 8'h33;
    localparam logic [7:0] ERROR_DPI_FP32_NUMERIC    = 8'h34;
    localparam logic [7:0] ERROR_DPI_CONTRACT        = 8'h3f;
    localparam logic [7:0] ERROR_INTERNAL_STATE      = 8'hff;

    localparam logic [3:0] STATE_IDLE         = 4'd0;
    localparam logic [3:0] STATE_QUANT_START  = 4'd1;
    localparam logic [3:0] STATE_QUANT_LOAD32 = 4'd2;
    localparam logic [3:0] STATE_QUANT_WAIT   = 4'd3;
    localparam logic [3:0] STATE_WEIGHT_TILE  = 4'd4;
    localparam logic [3:0] STATE_RESULT_HOLD  = 4'd5;
    localparam logic [3:0] STATE_DONE         = 4'd6;
    localparam logic [3:0] STATE_ERROR        = 4'd7;

    // Packed-bit ABI keeps the simulation functional unit isolated from all
    // host addresses and tensor allocations.  Status zero is the sole success
    // value; nonzero statuses are translated to public fail-closed errors.
    import "DPI-C" function int npu_q8_row_tile_compute(
        input int unsigned row_lanes,
        input int unsigned max_blocks,
        input int unsigned block_count,
        input bit [ACTIVATION_BANK_BITS-1:0] activation_blocks,
        input bit [WEIGHT_TILE_BITS-1:0] weight_blocks,
        input int unsigned lane_mask,
        output bit [RESULT_BITS-1:0] result_bits
    );

    logic [3:0] state_q;
    logic [31:0] row_count_q;
    logic [31:0] block_count_q;
    logic [31:0] quant_block_index_q;
    logic [5:0] quant_word_index_q;
    logic [31:0] row_base_q;

    // The quantized activation bank is physically owned by RTL.  A block is
    // committed only on the reference quantizer's successful terminal.
    logic [ACTIVATION_BANK_BITS-1:0] activation_block_bank_q;

    logic result_valid_q;
    logic [RESULT_BITS-1:0] result_bits_q;
    logic [ROW_LANES-1:0] result_mask_q;
    logic [31:0] result_row_base_q;

    logic [7:0] error_code_q;
    logic [31:0] error_row_index_q;
    logic [63:0] command_cycles_q;
    logic [63:0] active_cycles_q;
    logic [31:0] activation_words_accepted_q;
    logic [63:0] weight_blocks_accepted_q;
    logic [31:0] rows_emitted_q;

    logic quant_ready_w;
    logic quant_input_ready_w;
    logic quant_done_w;
    logic quant_error_w;
    logic [3:0] quant_error_code_w;
    logic [271:0] quant_block_w;

    logic [ROW_LANES-1:0] active_lane_mask_w;
    logic [31:0] active_lane_count_w;
    logic [63:0] accepted_tile_blocks_w;
    logic [63:0] next_weight_blocks_w;
    logic [31:0] expected_activation_words_w;
    logic [63:0] expected_weight_blocks_w;
    logic [32:0] next_row_count_w;

    logic start_fire_w;
    logic activation_fire_w;
    logic weight_tile_fire_w;
    logic result_fire_w;
    logic child_rst_w;

    // These temporaries exist only at the single weight-tile acceptance edge.
    // Blocking assignment is intentional: the DPI status and payload form one
    // atomic simulation functional transaction before architectural registers
    // are updated with nonblocking assignments.
    integer dpi_status_tmp;
    logic [RESULT_BITS-1:0] dpi_result_tmp;
    logic [31:0] dpi_lane_mask_w;

    integer lane_index;

    function automatic logic [31:0] popcount_lanes(
        input logic [ROW_LANES-1:0] lane_mask
    );
        integer count_lane;
        begin
            popcount_lanes = 32'd0;
            for (count_lane = 0; count_lane < ROW_LANES;
                 count_lane = count_lane + 1) begin
                if (lane_mask[count_lane]) begin
                    popcount_lanes = popcount_lanes + 32'd1;
                end
            end
        end
    endfunction

    generate
        if ((ROW_LANES < 1) || (ROW_LANES > 8)) begin : gen_bad_row_lanes
            initial $fatal(1,
                "TensorNpuQ8RowTileFunctionalCore ROW_LANES must be 1..8");
        end
        if (MAX_BLOCKS < 1 || MAX_BLOCKS > 128) begin : gen_bad_max_blocks
            initial $fatal(1,
                "TensorNpuQ8RowTileFunctionalCore MAX_BLOCKS must be 1..128");
        end
    endgenerate

    always_comb begin
        for (lane_index = 0; lane_index < ROW_LANES;
             lane_index = lane_index + 1) begin
            active_lane_mask_w[lane_index] =
                ({1'b0, row_base_q} + lane_index) < {1'b0, row_count_q};
        end
    end

    assign ready_o = !rst_i && (state_q == STATE_IDLE);
    assign busy_o = !rst_i && (state_q != STATE_IDLE);
    assign done_o = !rst_i && (state_q == STATE_DONE);
    assign error_o = !rst_i && (state_q == STATE_ERROR);

    assign activation_ready_o = !rst_i
                              && (state_q == STATE_QUANT_LOAD32)
                              && quant_input_ready_w;
    assign weight_tile_ready_o = !rst_i && (state_q == STATE_WEIGHT_TILE);
    assign result_valid_o = !rst_i && result_valid_q;
    assign result_bits_o = result_bits_q;
    assign result_mask_o = result_mask_q;
    assign result_row_base_o = result_row_base_q;

    assign error_code_o = error_code_q;
    assign error_row_index_o = error_row_index_q;
    assign active_cycles_o = active_cycles_q;
    assign activation_words_accepted_o = activation_words_accepted_q;
    assign weight_blocks_accepted_o = weight_blocks_accepted_q;
    assign rows_emitted_o = rows_emitted_q;

    assign start_fire_w = start_i && ready_o;
    assign activation_fire_w = activation_valid_i && activation_ready_o;
    assign weight_tile_fire_w = weight_tile_valid_i && weight_tile_ready_o;
    assign result_fire_w = result_valid_o && result_ready_i;
    assign child_rst_w = rst_i || (state_q == STATE_ERROR);

    assign active_lane_count_w = popcount_lanes(active_lane_mask_w);
    assign accepted_tile_blocks_w = {32'd0, active_lane_count_w}
                                  * {32'd0, block_count_q};
    assign next_weight_blocks_w = weight_blocks_accepted_q
                                + accepted_tile_blocks_w;
    assign expected_activation_words_w = block_count_q << 5;
    assign expected_weight_blocks_w = {32'd0, row_count_q}
                                    * {32'd0, block_count_q};
    assign next_row_count_w = {1'b0, row_base_q}
                            + {1'b0, active_lane_count_w};
    assign dpi_lane_mask_w = {{(32-ROW_LANES){1'b0}}, active_lane_mask_w};

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
    /* verilator lint_on PINCONNECTEMPTY */

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= STATE_IDLE;
            row_count_q <= 32'd0;
            block_count_q <= 32'd0;
            quant_block_index_q <= 32'd0;
            quant_word_index_q <= 6'd0;
            row_base_q <= 32'd0;
            activation_block_bank_q <= '0;
            result_valid_q <= 1'b0;
            result_bits_q <= '0;
            result_mask_q <= '0;
            result_row_base_q <= 32'd0;
            error_code_q <= ERROR_NONE;
            error_row_index_q <= 32'hffffffff;
            command_cycles_q <= 64'd0;
            active_cycles_q <= 64'd0;
            activation_words_accepted_q <= 32'd0;
            weight_blocks_accepted_q <= 64'd0;
            rows_emitted_q <= 32'd0;
            dpi_status_tmp = 0;
            dpi_result_tmp = '0;
        end else begin
            case (state_q)
                STATE_IDLE: begin
                    if (start_fire_w) begin
                        row_count_q <= row_count_i;
                        block_count_q <= block_count_i;
                        quant_block_index_q <= 32'd0;
                        quant_word_index_q <= 6'd0;
                        row_base_q <= 32'd0;
                        activation_block_bank_q <= '0;
                        result_valid_q <= 1'b0;
                        result_bits_q <= '0;
                        result_mask_q <= '0;
                        result_row_base_q <= 32'd0;
                        error_code_q <= ERROR_NONE;
                        error_row_index_q <= 32'hffffffff;
                        command_cycles_q <= 64'd1;
                        active_cycles_q <= 64'd0;
                        activation_words_accepted_q <= 32'd0;
                        weight_blocks_accepted_q <= 64'd0;
                        rows_emitted_q <= 32'd0;

                        if (row_count_i == 32'd0) begin
                            state_q <= STATE_ERROR;
                            error_code_q <= ERROR_ROW_COUNT_ZERO;
                            active_cycles_q <= 64'd1;
                        end else if (block_count_i == 32'd0) begin
                            state_q <= STATE_ERROR;
                            error_code_q <= ERROR_BLOCK_COUNT_ZERO;
                            active_cycles_q <= 64'd1;
                        end else if (block_count_i > MAX_BLOCKS_U32) begin
                            state_q <= STATE_ERROR;
                            error_code_q <= ERROR_BLOCK_COUNT_EXCEEDS;
                            active_cycles_q <= 64'd1;
                        end else begin
                            state_q <= STATE_QUANT_START;
                        end
                    end
                end

                STATE_QUANT_START: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (quant_ready_w) begin
                        quant_word_index_q <= 6'd0;
                        state_q <= STATE_QUANT_LOAD32;
                    end
                end

                STATE_QUANT_LOAD32: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (activation_fire_w) begin
                        activation_words_accepted_q
                            <= activation_words_accepted_q + 32'd1;
                        if (quant_word_index_q == 6'd31) begin
                            quant_word_index_q <= 6'd32;
                            state_q <= STATE_QUANT_WAIT;
                        end else begin
                            quant_word_index_q <= quant_word_index_q + 6'd1;
                        end
                    end
                end

                STATE_QUANT_WAIT: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (quant_error_w) begin
                        state_q <= STATE_ERROR;
                        error_code_q <= {4'h2, quant_error_code_w};
                        error_row_index_q <= 32'hffffffff;
                        active_cycles_q <= command_cycles_q + 64'd1;
                        result_valid_q <= 1'b0;
                    end else if (quant_done_w) begin
                        activation_block_bank_q[
                            (quant_block_index_q[BLOCK_INDEX_WIDTH-1:0]*272)
                            +: 272] <= quant_block_w;
                        if (quant_block_index_q
                            == (block_count_q - 32'd1)) begin
                            row_base_q <= 32'd0;
                            state_q <= STATE_WEIGHT_TILE;
                        end else begin
                            quant_block_index_q
                                <= quant_block_index_q + 32'd1;
                            state_q <= STATE_QUANT_START;
                        end
                    end
                end

                STATE_WEIGHT_TILE: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (weight_tile_fire_w) begin
                        if (weight_tile_mask_i != active_lane_mask_w) begin
                            state_q <= STATE_ERROR;
                            error_code_q <= ERROR_WEIGHT_MASK;
                            error_row_index_q <= row_base_q;
                            active_cycles_q <= command_cycles_q + 64'd1;
                            result_valid_q <= 1'b0;
                        end else if ((activation_words_accepted_q
                                     != expected_activation_words_w)
                                    || (next_weight_blocks_w
                                        > expected_weight_blocks_w)) begin
                            state_q <= STATE_ERROR;
                            error_code_q <= ERROR_INTERNAL_STATE;
                            error_row_index_q <= row_base_q;
                            active_cycles_q <= command_cycles_q + 64'd1;
                            result_valid_q <= 1'b0;
                        end else begin
                            weight_blocks_accepted_q <= next_weight_blocks_w;
                            /* verilator lint_off BLKSEQ */
                            dpi_result_tmp = '0;
                            dpi_status_tmp = npu_q8_row_tile_compute(
                                ROW_LANES_U32,
                                MAX_BLOCKS_U32,
                                block_count_q,
                                activation_block_bank_q,
                                weight_tile_blocks_i,
                                dpi_lane_mask_w,
                                dpi_result_tmp);
                            /* verilator lint_on BLKSEQ */
                            if (dpi_status_tmp != 0) begin
                                state_q <= STATE_ERROR;
                                case (dpi_status_tmp)
                                    1: error_code_q
                                        <= ERROR_DPI_NONFINITE_SCALE;
                                    2: error_code_q <= ERROR_DPI_DOT_RANGE;
                                    3: error_code_q <= ERROR_DPI_FP32_NUMERIC;
                                    default: error_code_q
                                        <= ERROR_DPI_CONTRACT;
                                endcase
                                error_row_index_q <= row_base_q;
                                active_cycles_q
                                    <= command_cycles_q + 64'd1;
                                result_valid_q <= 1'b0;
                                result_bits_q <= '0;
                                result_mask_q <= '0;
                            end else if ((next_row_count_w
                                          > {1'b0, row_count_q})
                                         || ((next_row_count_w
                                              == {1'b0, row_count_q})
                                             && (next_weight_blocks_w
                                                 != expected_weight_blocks_w))) begin
                                state_q <= STATE_ERROR;
                                error_code_q <= ERROR_INTERNAL_STATE;
                                error_row_index_q <= row_base_q;
                                active_cycles_q
                                    <= command_cycles_q + 64'd1;
                                result_valid_q <= 1'b0;
                            end else begin
                                result_bits_q <= dpi_result_tmp;
                                result_mask_q <= active_lane_mask_w;
                                result_row_base_q <= row_base_q;
                                result_valid_q <= 1'b1;
                                state_q <= STATE_RESULT_HOLD;
                            end
                        end
                    end
                end

                STATE_RESULT_HOLD: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (result_fire_w) begin
                        result_valid_q <= 1'b0;
                        rows_emitted_q <= rows_emitted_q
                                        + active_lane_count_w;
                        if (next_row_count_w == {1'b0, row_count_q}) begin
                            active_cycles_q <= command_cycles_q + 64'd1;
                            state_q <= STATE_DONE;
                        end else begin
                            row_base_q <= row_base_q + ROW_LANES_U32;
                            state_q <= STATE_WEIGHT_TILE;
                        end
                    end
                end

                STATE_DONE: begin
                    state_q <= STATE_IDLE;
                end

                STATE_ERROR: begin
                    result_valid_q <= 1'b0;
                    state_q <= STATE_IDLE;
                end

                default: begin
                    state_q <= STATE_ERROR;
                    error_code_q <= ERROR_INTERNAL_STATE;
                    error_row_index_q <= row_base_q;
                    active_cycles_q <= command_cycles_q + 64'd1;
                    command_cycles_q <= command_cycles_q + 64'd1;
                    result_valid_q <= 1'b0;
                    result_bits_q <= '0;
                    result_mask_q <= '0;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
