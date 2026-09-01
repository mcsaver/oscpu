`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// TensorNpuF32AluSimdCore
//
// Pure numerical lane-SIMD core for VECTOR_F32 ADD/MUL/SUB/SCALE.  Addressing,
// capability checks, memory transport, and long-term stall policy belong to a
// separate portal adapter.
//
// Invariants:
//   * one existing TensorNpuFp32AddMul is instantiated per lane;
//   * every valid input batch atomically fires all active child requests;
//   * SUB only flips rhs sign before child ADD; SCALE only substitutes the
//     resident scale operand before child MUL;
//   * child responses are accepted one lane per cycle, so unselected children
//     exercise their public response hold contract while results/flags are
//     collected across cycles;
//   * result bits/mask/base are published together and remain stable under
//     result backpressure;
//   * flags_or_o changes only for a matching child response fire;
//   * all public counters count actual channel or child handshakes.
module TensorNpuF32AluSimdCore #(
    parameter integer LANES = 8
) (
    input  wire                       clk_i,
    input  wire                       rst_i,

    input  wire                       start_i,
    output wire                       ready_o,
    output wire                       busy_o,
    input  wire [2:0]                 opcode_i,
    input  wire [63:0]                element_count_i,
    input  wire [31:0]                scale_bits_i,

    input  wire                       input_batch_valid_i,
    output wire                       input_batch_ready_o,
    input  wire [(LANES*32)-1:0]      lhs_bits_i,
    input  wire [(LANES*32)-1:0]      rhs_bits_i,
    input  wire [LANES-1:0]           mask_i,
    input  wire [63:0]                base_index_i,

    output wire                       result_batch_valid_o,
    input  wire                       result_batch_ready_i,
    output wire [(LANES*32)-1:0]      result_bits_o,
    output wire [LANES-1:0]           result_mask_o,
    output wire [63:0]                result_base_index_o,

    output wire                       done_o,
    output wire                       error_o,
    output wire [7:0]                 error_code_o,
    output wire [63:0]                error_index_o,
    output wire [4:0]                 flags_or_o,
    output wire [63:0]                input_batches_o,
    output wire [63:0]                child_requests_o,
    output wire [63:0]                child_responses_o,
    output wire [63:0]                elements_emitted_o,
    output wire [63:0]                active_cycles_o
);

    localparam [2:0] OP_ADD   = 3'd0;
    localparam [2:0] OP_MUL   = 3'd1;
    localparam [2:0] OP_SUB   = 3'd2;
    localparam [2:0] OP_SCALE = 3'd3;

    localparam [7:0] ERROR_NONE           = 8'h00;
    localparam [7:0] ERROR_INVALID_OPCODE = 8'h10;
    localparam [7:0] ERROR_INVALID_COUNT  = 8'h11;
    localparam [7:0] ERROR_BASE_INDEX     = 8'h12;
    localparam [7:0] ERROR_MASK           = 8'h13;
    localparam [7:0] ERROR_INTERNAL_STATE = 8'hff;

    localparam [2:0] STATE_IDLE          = 3'd0;
    localparam [2:0] STATE_INPUT_WAIT    = 3'd1;
    localparam [2:0] STATE_RESPONSE_WAIT = 3'd2;
    localparam [2:0] STATE_RESULT_HOLD   = 3'd3;
    localparam [2:0] STATE_DONE          = 3'd4;
    localparam [2:0] STATE_ERROR         = 3'd5;

    localparam [63:0] LANES_U64 = LANES;

    generate
        if ((LANES < 1) || (LANES > 16)) begin : gen_bad_lanes
            initial begin
                $fatal(1, "TensorNpuF32AluSimdCore LANES must be in 1..16");
            end
        end
    endgenerate

    reg [2:0]  state_q;
    reg [2:0]  opcode_q;
    reg [63:0] element_count_q;
    reg [31:0] scale_bits_q;
    reg [63:0] expected_base_q;

    reg [LANES-1:0] response_seen_q;
    reg [31:0] lane_result_q [0:LANES-1];

    reg                       result_batch_valid_q;
    reg [(LANES*32)-1:0]      result_bits_q;
    reg [LANES-1:0]           result_mask_q;
    reg [63:0]                result_base_index_q;

    reg [7:0]  error_code_q;
    reg [63:0] error_index_q;
    reg [4:0]  flags_or_q;
    reg [63:0] input_batches_q;
    reg [63:0] child_requests_q;
    reg [63:0] child_responses_q;
    reg [63:0] elements_emitted_q;
    reg [63:0] command_cycles_q;
    reg [63:0] active_cycles_q;

    wire start_fire_w;
    wire input_batch_fire_w;
    wire result_batch_fire_w;
    wire child_rst_w;

    wire [LANES-1:0] active_mask_w;
    wire              input_base_match_w;
    wire              input_mask_match_w;
    wire              input_packet_valid_w;

    wire [LANES-1:0] child_req_valid_w;
    wire [LANES-1:0] child_req_ready_w;
    wire [LANES-1:0] child_req_fire_w;
    wire [LANES-1:0] child_rsp_valid_w;
    wire [LANES-1:0] child_rsp_ready_w;
    wire [LANES-1:0] child_rsp_fire_w;
    wire [(LANES*32)-1:0] child_result_bits_w;
    wire [(LANES*5)-1:0]  child_flags_w;

    wire all_active_children_ready_w;
    wire [LANES-1:0] unexpected_response_mask_w;
    wire unexpected_response_w;
    wire [LANES-1:0] response_select_mask_w;
    wire [LANES-1:0] response_seen_next_w;
    wire all_active_responses_w;
    wire [63:0] request_fire_count_w;
    wire [63:0] response_fire_count_w;
    wire [63:0] result_fire_count_w;

    reg [(LANES*32)-1:0] collected_results_r;
    reg [LANES-1:0]      response_select_mask_r;
    reg [4:0]            response_flags_or_r;
    reg                  mask_error_selected_r;
    reg [63:0]           mask_error_index_r;
    reg                  internal_error_selected_r;
    reg [63:0]           internal_error_index_r;

    integer comb_lane;
    integer seq_lane;

    function automatic [63:0] popcount_lanes;
        input [LANES-1:0] lane_mask;
        integer count_lane;
        begin
            popcount_lanes = 64'b0;
            for (count_lane = 0; count_lane < LANES;
                 count_lane = count_lane + 1) begin
                if (lane_mask[count_lane]) begin
                    popcount_lanes = popcount_lanes + 64'd1;
                end
            end
        end
    endfunction

    assign ready_o = !rst_i && (state_q == STATE_IDLE);
    assign busy_o  = !rst_i && (state_q != STATE_IDLE);
    assign done_o  = !rst_i && (state_q == STATE_DONE);
    assign error_o = !rst_i && (state_q == STATE_ERROR);

    assign input_batch_ready_o = !rst_i
                               && (state_q == STATE_INPUT_WAIT)
                               && all_active_children_ready_w
                               && !unexpected_response_w;
    // Suppress publication combinationally if an impossible stale/duplicate
    // child response is detected while a batch is being held.  The state
    // machine records the same condition as ERROR_INTERNAL_STATE on the edge.
    assign result_batch_valid_o = !rst_i
                                && result_batch_valid_q
                                && !unexpected_response_w;
    assign result_bits_o        = result_bits_q;
    assign result_mask_o        = result_mask_q;
    assign result_base_index_o  = result_base_index_q;

    assign error_code_o       = error_code_q;
    assign error_index_o      = error_index_q;
    assign flags_or_o         = flags_or_q;
    assign input_batches_o    = input_batches_q;
    assign child_requests_o   = child_requests_q;
    assign child_responses_o  = child_responses_q;
    assign elements_emitted_o = elements_emitted_q;
    assign active_cycles_o    = active_cycles_q;

    assign start_fire_w = start_i && ready_o;
    assign input_batch_fire_w = input_batch_valid_i
                              && input_batch_ready_o;
    assign result_batch_fire_w = result_batch_valid_o
                               && result_batch_ready_i;
    assign child_rst_w = rst_i || (state_q == STATE_ERROR);

    assign input_base_match_w = (base_index_i == expected_base_q);
    assign input_mask_match_w = (mask_i == active_mask_w);
    assign input_packet_valid_w = input_base_match_w
                                && input_mask_match_w;

    assign all_active_children_ready_w =
        &(child_req_ready_w | ~active_mask_w);
    assign child_req_valid_w =
        {LANES{input_batch_fire_w && input_packet_valid_w}}
        & active_mask_w;
    assign child_req_fire_w = child_req_valid_w & child_req_ready_w;

    // In RESPONSE_WAIT, valid from an inactive or already consumed lane is a
    // protocol fault.  Valid from an unselected active lane is expected and is
    // deliberately backpressured until its turn.
    assign unexpected_response_mask_w =
        (state_q == STATE_RESPONSE_WAIT)
        ? (child_rsp_valid_w & (~active_mask_w | response_seen_q))
        : (((state_q == STATE_INPUT_WAIT)
            || (state_q == STATE_RESULT_HOLD))
           ? child_rsp_valid_w : {LANES{1'b0}});
    assign unexpected_response_w = |unexpected_response_mask_w;

    assign response_select_mask_w = response_select_mask_r;
    assign child_rsp_ready_w =
        {LANES{(state_q == STATE_RESPONSE_WAIT)
               && !unexpected_response_w}}
        & response_select_mask_w;
    assign child_rsp_fire_w = child_rsp_valid_w & child_rsp_ready_w;
    assign response_seen_next_w = response_seen_q | child_rsp_fire_w;
    assign all_active_responses_w =
        ((response_seen_next_w & active_mask_w) == active_mask_w);

    assign request_fire_count_w  = popcount_lanes(child_req_fire_w);
    assign response_fire_count_w = popcount_lanes(child_rsp_fire_w);
    assign result_fire_count_w   = popcount_lanes(result_mask_q);

    // Tail mask generation uses a 65-bit candidate, avoiding wrap for counts
    // close to the top of the 64-bit index space.
    genvar mask_lane;
    generate
        for (mask_lane = 0; mask_lane < LANES;
             mask_lane = mask_lane + 1) begin : gen_active_mask
            localparam [64:0] LANE_OFFSET = mask_lane;
            wire [64:0] absolute_index_w;
            assign absolute_index_w = {1'b0, expected_base_q} + LANE_OFFSET;
            assign active_mask_w[mask_lane] =
                (absolute_index_w < {1'b0, element_count_q});
        end
    endgenerate

    // Lowest unseen active lane receives response credit.  If a lower lane is
    // slower, all higher valid responses remain held in their child wrappers.
    always @(*) begin
        response_select_mask_r = {LANES{1'b0}};
        for (comb_lane = 0; comb_lane < LANES;
             comb_lane = comb_lane + 1) begin
            if (!(|response_select_mask_r)
                && active_mask_w[comb_lane]
                && !response_seen_q[comb_lane]) begin
                response_select_mask_r[comb_lane] = 1'b1;
            end
        end
    end

    // Current response payload has not yet reached lane_result_q at the
    // publication edge, so select it directly for the firing lane.
    always @(*) begin
        collected_results_r = {(LANES*32){1'b0}};
        for (comb_lane = 0; comb_lane < LANES;
             comb_lane = comb_lane + 1) begin
            if (child_rsp_fire_w[comb_lane]) begin
                collected_results_r[(comb_lane*32) +: 32]
                    = child_result_bits_w[(comb_lane*32) +: 32];
            end else begin
                collected_results_r[(comb_lane*32) +: 32]
                    = lane_result_q[comb_lane];
            end
        end
    end

    always @(*) begin
        response_flags_or_r = 5'b0;
        for (comb_lane = 0; comb_lane < LANES;
             comb_lane = comb_lane + 1) begin
            if (child_rsp_fire_w[comb_lane]) begin
                response_flags_or_r = response_flags_or_r
                                    | child_flags_w[(comb_lane*5) +: 5];
            end
        end
    end

    // Deterministic lowest absolute index for a malformed mask.
    always @(*) begin
        mask_error_selected_r = 1'b0;
        mask_error_index_r    = expected_base_q;
        for (comb_lane = 0; comb_lane < LANES;
             comb_lane = comb_lane + 1) begin
            if (!mask_error_selected_r
                && (mask_i[comb_lane] != active_mask_w[comb_lane])) begin
                mask_error_selected_r = 1'b1;
                mask_error_index_r = expected_base_q
                                   + {32'b0, comb_lane[31:0]};
            end
        end
    end

    // The same priority rule is used for an unexpected child response.
    always @(*) begin
        internal_error_selected_r = 1'b0;
        internal_error_index_r    = expected_base_q;
        for (comb_lane = 0; comb_lane < LANES;
             comb_lane = comb_lane + 1) begin
            if (!internal_error_selected_r
                && unexpected_response_mask_w[comb_lane]) begin
                internal_error_selected_r = 1'b1;
                internal_error_index_r = expected_base_q
                                       + {32'b0, comb_lane[31:0]};
            end
        end
    end

    /* verilator lint_off PINCONNECTEMPTY */
    genvar child_lane;
    generate
        for (child_lane = 0; child_lane < LANES;
             child_lane = child_lane + 1) begin : gen_child
            wire [31:0] selected_rhs_w;
            wire        selected_mul_w;

            assign selected_mul_w = (opcode_q == OP_MUL)
                                  || (opcode_q == OP_SCALE);
            assign selected_rhs_w = (opcode_q == OP_SUB)
                                  ? {~rhs_bits_i[(child_lane*32) + 31],
                                     rhs_bits_i[(child_lane*32) +: 31]}
                                  : ((opcode_q == OP_SCALE)
                                     ? scale_bits_q
                                     : rhs_bits_i[(child_lane*32) +: 32]);

            TensorNpuFp32AddMul u_addmul (
                .clk_i         (clk_i),
                .rst_i         (child_rst_w),
                .req_valid_i   (child_req_valid_w[child_lane]),
                .req_ready_o   (child_req_ready_w[child_lane]),
                .op_mul_i      (selected_mul_w),
                .lhs_bits_i    (lhs_bits_i[(child_lane*32) +: 32]),
                .rhs_bits_i    (selected_rhs_w),
                .rsp_valid_o   (child_rsp_valid_w[child_lane]),
                .rsp_ready_i   (child_rsp_ready_w[child_lane]),
                .result_bits_o (child_result_bits_w[
                    (child_lane*32) +: 32]),
                .flags_o       (child_flags_w[(child_lane*5) +: 5])
            );
        end
    endgenerate
    /* verilator lint_on PINCONNECTEMPTY */

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                <= STATE_IDLE;
            opcode_q               <= OP_ADD;
            element_count_q        <= 64'b0;
            scale_bits_q           <= 32'b0;
            expected_base_q        <= 64'b0;
            response_seen_q        <= {LANES{1'b0}};
            result_batch_valid_q   <= 1'b0;
            result_bits_q          <= {(LANES*32){1'b0}};
            result_mask_q          <= {LANES{1'b0}};
            result_base_index_q    <= 64'b0;
            error_code_q           <= ERROR_NONE;
            error_index_q          <= 64'hffffffffffffffff;
            flags_or_q             <= 5'b0;
            input_batches_q        <= 64'b0;
            child_requests_q       <= 64'b0;
            child_responses_q      <= 64'b0;
            elements_emitted_q     <= 64'b0;
            command_cycles_q       <= 64'b0;
            active_cycles_q        <= 64'b0;
            for (seq_lane = 0; seq_lane < LANES;
                 seq_lane = seq_lane + 1) begin
                lane_result_q[seq_lane] <= 32'b0;
            end
        end else begin
            case (state_q)
                STATE_IDLE: begin
                    if (start_fire_w) begin
                        opcode_q            <= opcode_i;
                        element_count_q     <= element_count_i;
                        scale_bits_q        <= scale_bits_i;
                        expected_base_q     <= 64'b0;
                        response_seen_q     <= {LANES{1'b0}};
                        result_batch_valid_q <= 1'b0;
                        result_bits_q       <= {(LANES*32){1'b0}};
                        result_mask_q       <= {LANES{1'b0}};
                        result_base_index_q <= 64'b0;
                        error_code_q        <= ERROR_NONE;
                        error_index_q       <= 64'hffffffffffffffff;
                        flags_or_q          <= 5'b0;
                        input_batches_q     <= 64'b0;
                        child_requests_q    <= 64'b0;
                        child_responses_q   <= 64'b0;
                        elements_emitted_q  <= 64'b0;
                        command_cycles_q    <= 64'd1;
                        active_cycles_q     <= 64'b0;
                        for (seq_lane = 0; seq_lane < LANES;
                             seq_lane = seq_lane + 1) begin
                            lane_result_q[seq_lane] <= 32'b0;
                        end

                        if ((opcode_i != OP_ADD) && (opcode_i != OP_MUL)
                            && (opcode_i != OP_SUB)
                            && (opcode_i != OP_SCALE)) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_INVALID_OPCODE;
                            active_cycles_q  <= 64'd1;
                        end else if (element_count_i == 64'b0) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_INVALID_COUNT;
                            active_cycles_q  <= 64'd1;
                        end else begin
                            state_q <= STATE_INPUT_WAIT;
                        end
                    end
                end

                STATE_DONE: begin
                    state_q <= STATE_IDLE;
                end

                STATE_ERROR: begin
                    // child_rst_w remains asserted through this edge.
                    state_q <= STATE_IDLE;
                end

                STATE_INPUT_WAIT: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (unexpected_response_w) begin
                        state_q          <= STATE_ERROR;
                        error_code_q     <= ERROR_INTERNAL_STATE;
                        error_index_q    <= internal_error_index_r;
                        active_cycles_q  <= command_cycles_q + 64'd1;
                        result_batch_valid_q <= 1'b0;
                    end else if (input_batch_fire_w) begin
                        input_batches_q <= input_batches_q + 64'd1;
                        response_seen_q <= {LANES{1'b0}};
                        for (seq_lane = 0; seq_lane < LANES;
                             seq_lane = seq_lane + 1) begin
                            lane_result_q[seq_lane] <= 32'b0;
                        end

                        if (!input_base_match_w) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_BASE_INDEX;
                            error_index_q    <= expected_base_q;
                            active_cycles_q  <= command_cycles_q + 64'd1;
                            result_batch_valid_q <= 1'b0;
                        end else if (!input_mask_match_w) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_MASK;
                            error_index_q    <= mask_error_index_r;
                            active_cycles_q  <= command_cycles_q + 64'd1;
                            result_batch_valid_q <= 1'b0;
                        end else if (child_req_fire_w != active_mask_w) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_INTERNAL_STATE;
                            error_index_q    <= expected_base_q;
                            active_cycles_q  <= command_cycles_q + 64'd1;
                            result_batch_valid_q <= 1'b0;
                        end else begin
                            child_requests_q <= child_requests_q
                                              + request_fire_count_w;
                            state_q <= STATE_RESPONSE_WAIT;
                        end
                    end
                end

                STATE_RESPONSE_WAIT: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (unexpected_response_w) begin
                        state_q          <= STATE_ERROR;
                        error_code_q     <= ERROR_INTERNAL_STATE;
                        error_index_q    <= internal_error_index_r;
                        active_cycles_q  <= command_cycles_q + 64'd1;
                        result_batch_valid_q <= 1'b0;
                    end else begin
                        if (|child_rsp_fire_w) begin
                            response_seen_q <= response_seen_next_w;
                            child_responses_q <= child_responses_q
                                               + response_fire_count_w;
                            flags_or_q <= flags_or_q | response_flags_or_r;
                            for (seq_lane = 0; seq_lane < LANES;
                                 seq_lane = seq_lane + 1) begin
                                if (child_rsp_fire_w[seq_lane]) begin
                                    lane_result_q[seq_lane]
                                        <= child_result_bits_w[
                                            (seq_lane*32) +: 32];
                                end
                            end
                        end

                        if ((|child_rsp_fire_w)
                            && all_active_responses_w) begin
                            result_bits_q       <= collected_results_r;
                            result_mask_q       <= active_mask_w;
                            result_base_index_q <= expected_base_q;
                            result_batch_valid_q <= 1'b1;
                            state_q <= STATE_RESULT_HOLD;
                        end
                    end
                end

                STATE_RESULT_HOLD: begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                    if (unexpected_response_w) begin
                        state_q          <= STATE_ERROR;
                        error_code_q     <= ERROR_INTERNAL_STATE;
                        error_index_q    <= internal_error_index_r;
                        active_cycles_q  <= command_cycles_q + 64'd1;
                        result_batch_valid_q <= 1'b0;
                    end else if (result_batch_fire_w) begin
                        result_batch_valid_q <= 1'b0;
                        elements_emitted_q <= elements_emitted_q
                                            + result_fire_count_w;
                        if ((element_count_q - expected_base_q)
                            <= LANES_U64) begin
                            if ((child_requests_q == element_count_q)
                                && (child_responses_q == element_count_q)
                                && ((elements_emitted_q
                                     + result_fire_count_w)
                                    == element_count_q)) begin
                                state_q         <= STATE_DONE;
                                error_code_q    <= ERROR_NONE;
                                active_cycles_q <= command_cycles_q + 64'd1;
                            end else begin
                                state_q          <= STATE_ERROR;
                                error_code_q     <= ERROR_INTERNAL_STATE;
                                error_index_q    <= expected_base_q;
                                active_cycles_q  <= command_cycles_q + 64'd1;
                            end
                        end else begin
                            expected_base_q <= expected_base_q + LANES_U64;
                            state_q         <= STATE_INPUT_WAIT;
                        end
                    end
                end

                default: begin
                    state_q          <= STATE_ERROR;
                    error_code_q     <= ERROR_INTERNAL_STATE;
                    error_index_q    <= expected_base_q;
                    command_cycles_q <= command_cycles_q + 64'd1;
                    active_cycles_q  <= command_cycles_q + 64'd1;
                    result_batch_valid_q <= 1'b0;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
