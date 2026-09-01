`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// TensorNpuQ8DequantBlock
//
// Requirement:
//   Atomically dequantize one resident 34-byte Q8_0 block.  block_i[15:0]
//   carries the little-endian binary16 scale and block_i[16+8*n +: 8]
//   carries signed int8 lane n.  A successful transaction publishes exactly
//   32 raw FP32 lanes in increasing index order.  A non-finite scale or any
//   child arithmetic failure publishes no lane and terminates with error_o.
//
// Protocol/FSM:
//   IDLE -> VALIDATE -> MUL_REQ -> MUL_WAIT --(32 lanes buffered)--> LANE_HOLD
//        -> DONE -> IDLE.  Any validation, child, result, or watchdog failure
//   goes to ERROR -> IDLE.  start_i is accepted only with ready_o; lane payload
//   is retained until lane_valid_o && lane_ready_i.
//
// Invariants:
//   * block_q and mul_index_q are stable while a child transaction is pending;
//   * result_buffer_q is written only by a flag-free finite child response;
//   * no lane is visible until all 32 child responses have succeeded;
//   * lane_index_q advances only on a lane handshake;
//   * reset has priority over every resident or held transaction.
//
// RTL topology:
//   resident block -> FP16 exact expansion -> selected signed byte -> exact
//   int32-to-FP32 -> one shared FP32 multiplier -> 32-entry atomic result
//   buffer -> held lane output mux.  The likely request-side combinational path
//   is byte mux/sign extension/int32 conversion into the multiplier adapter;
//   the lane path is the 32:1 result-buffer mux.  No function hides state,
//   arbitration, handshake, or reset behavior.
module TensorNpuQ8DequantBlock #(
    parameter [15:0] CHILD_TIMEOUT_CYCLES = 16'd16
) (
    input  wire         clk_i,
    input  wire         rst_i,
    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [271:0] block_i,

    output wire         lane_valid_o,
    input  wire         lane_ready_i,
    output wire [5:0]   lane_index_o,
    output wire [31:0]  lane_bits_o,
    output wire         lane_last_o,

    output wire         done_o,
    output wire         error_o,
    output wire [3:0]   error_code_o,
    output wire [15:0]  active_cycles_o
);

    localparam [3:0] ST_IDLE      = 4'd0;
    localparam [3:0] ST_VALIDATE  = 4'd1;
    localparam [3:0] ST_MUL_REQ   = 4'd2;
    localparam [3:0] ST_MUL_WAIT  = 4'd3;
    localparam [3:0] ST_LANE_HOLD = 4'd4;
    localparam [3:0] ST_DONE      = 4'd5;
    localparam [3:0] ST_ERROR     = 4'd6;

    localparam [3:0] ERR_NONE         = 4'h0;
    localparam [3:0] ERR_SCALE_CLASS  = 4'h1;
    localparam [3:0] ERR_CONVERT      = 4'h2;
    localparam [3:0] ERR_CHILD_FLAGS  = 4'h3;
    localparam [3:0] ERR_RESULT_CLASS = 4'h4;
    localparam [3:0] ERR_REQ_TIMEOUT  = 4'h5;
    localparam [3:0] ERR_RSP_TIMEOUT  = 4'h6;
    localparam [3:0] ERR_INTERNAL     = 4'hf;

    localparam [15:0] CHILD_TIMEOUT_LAST =
        (CHILD_TIMEOUT_CYCLES == 16'd0)
            ? 16'd0 : (CHILD_TIMEOUT_CYCLES - 16'd1);

    reg [3:0]    state_q;
    reg [271:0]  block_q;
    reg [4:0]    mul_index_q;
    reg [4:0]    lane_index_q;
    reg [1023:0] result_buffer_q;
    reg [15:0]   watchdog_q;
    reg [15:0]   active_cycles_q;
    reg [3:0]    error_code_q;
    reg          child_reset_q;

    wire         start_fire_w;
    wire         lane_fire_w;
    wire [31:0]  scale_fp32_bits_w;
    wire         scale_finite_w;
    wire         scale_zero_w;
    wire [8:0]   q_bit_base_w;
    wire [7:0]   selected_q_byte_w;
    wire signed [31:0] selected_q_int_w;
    wire [31:0]  selected_q_fp32_w;
    wire         selected_q_inexact_w;
    wire         mul_req_valid_w;
    wire         mul_req_ready_w;
    wire         mul_rsp_valid_w;
    wire         mul_rsp_ready_w;
    wire [31:0]  mul_result_bits_w;
    wire [4:0]   mul_rsp_flags_w;
    wire         child_rst_w;
    wire         result_nonfinite_w;

    assign ready_o         = !rst_i && (state_q == ST_IDLE);
    assign busy_o          = !rst_i && (state_q != ST_IDLE);
    assign start_fire_w    = start_i && ready_o;
    assign lane_valid_o    = !rst_i && (state_q == ST_LANE_HOLD);
    assign lane_fire_w     = lane_valid_o && lane_ready_i;
    assign lane_index_o    = {1'b0, lane_index_q};
    assign lane_bits_o     = result_buffer_q[{lane_index_q, 5'b00000} +: 32];
    assign lane_last_o     = lane_valid_o && (lane_index_q == 5'd31);
    assign done_o          = !rst_i && (state_q == ST_DONE);
    assign error_o         = !rst_i && (state_q == ST_ERROR);
    assign error_code_o    = error_code_q;
    assign active_cycles_o = active_cycles_q;

    // The 9-bit base ranges from 16 through 264 and implements the 32:1 Q8
    // byte-selection mux.  Every selected byte is explicitly sign-extended.
    assign q_bit_base_w       = {1'b0, mul_index_q, 3'b000} + 9'd16;
    assign selected_q_byte_w  = block_q[q_bit_base_w +: 8];
    assign selected_q_int_w   = {{24{selected_q_byte_w[7]}},
                                 selected_q_byte_w};
    assign result_nonfinite_w = (mul_result_bits_w[30:23] == 8'hff);

    TensorNpuFp16ToFp32 u_scale_expand (
        .fp16_bits_i (block_q[15:0]),
        .fp32_bits_o (scale_fp32_bits_w),
        .finite_o    (scale_finite_w),
        .zero_o      (scale_zero_w)
    );

    TensorNpuInt32ToFp32 u_q_expand (
        .int_i       (selected_q_int_w),
        .fp32_bits_o (selected_q_fp32_w),
        .inexact_o   (selected_q_inexact_w)
    );

    assign mul_req_valid_w = (state_q == ST_MUL_REQ)
                           && !selected_q_inexact_w;
    assign mul_rsp_ready_w = (state_q == ST_MUL_WAIT);
    assign child_rst_w     = rst_i || child_reset_q;

    TensorNpuFp32AddMul u_lane_mul (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .req_valid_i   (mul_req_valid_w),
        .req_ready_o   (mul_req_ready_w),
        .op_mul_i      (1'b1),
        .lhs_bits_i    (selected_q_fp32_w),
        .rhs_bits_i    (scale_fp32_bits_w),
        .rsp_valid_o   (mul_rsp_valid_w),
        .rsp_ready_i   (mul_rsp_ready_w),
        .result_bits_o (mul_result_bits_w),
        .flags_o       (mul_rsp_flags_w)
    );

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q         <= ST_IDLE;
            block_q         <= 272'b0;
            mul_index_q     <= 5'b0;
            lane_index_q    <= 5'b0;
            result_buffer_q <= 1024'b0;
            watchdog_q      <= 16'b0;
            active_cycles_q <= 16'b0;
            error_code_q    <= ERR_NONE;
            child_reset_q   <= 1'b0;
        end else begin
            // A one-cycle child reset is requested on an abandoned arithmetic
            // transaction.  The default deassertion lets a clean child reopen.
            child_reset_q <= 1'b0;

            // Count active non-terminal cycles and saturate instead of wrapping.
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)
                    && (active_cycles_q != 16'hffff)) begin
                active_cycles_q <= active_cycles_q + 16'd1;
            end

            case (state_q)
                ST_IDLE: begin
                    watchdog_q <= 16'b0;
                    if (start_fire_w) begin
                        block_q         <= block_i;
                        mul_index_q     <= 5'b0;
                        lane_index_q    <= 5'b0;
                        result_buffer_q <= 1024'b0;
                        active_cycles_q <= 16'd1;
                        error_code_q    <= ERR_NONE;
                        state_q         <= ST_VALIDATE;
                    end
                end

                ST_VALIDATE: begin
                    watchdog_q <= 16'b0;
                    if (!scale_finite_w) begin
                        error_code_q <= ERR_SCALE_CLASS;
                        state_q      <= ST_ERROR;
                    end else if (scale_zero_w
                            && (block_q[14:0] != 15'b0)) begin
                        // A disagreement between raw zero encoding and the
                        // converter's class output is an internal child fault.
                        error_code_q <= ERR_CONVERT;
                        state_q      <= ST_ERROR;
                    end else begin
                        state_q <= ST_MUL_REQ;
                    end
                end

                ST_MUL_REQ: begin
                    if (selected_q_inexact_w) begin
                        error_code_q  <= ERR_CONVERT;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else if (mul_req_valid_w && mul_req_ready_w) begin
                        watchdog_q <= 16'b0;
                        state_q    <= ST_MUL_WAIT;
                    end else if (watchdog_q >= CHILD_TIMEOUT_LAST) begin
                        error_code_q  <= ERR_REQ_TIMEOUT;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else begin
                        watchdog_q <= watchdog_q + 16'd1;
                    end
                end

                ST_MUL_WAIT: begin
                    if (mul_rsp_valid_w) begin
                        watchdog_q <= 16'b0;
                        if (mul_rsp_flags_w != 5'b0) begin
                            error_code_q  <= ERR_CHILD_FLAGS;
                            child_reset_q <= 1'b1;
                            state_q       <= ST_ERROR;
                        end else if (result_nonfinite_w) begin
                            error_code_q  <= ERR_RESULT_CLASS;
                            child_reset_q <= 1'b1;
                            state_q       <= ST_ERROR;
                        end else begin
                            result_buffer_q[
                                {mul_index_q, 5'b00000} +: 32
                            ] <= mul_result_bits_w;
                            if (mul_index_q == 5'd31) begin
                                lane_index_q <= 5'b0;
                                state_q      <= ST_LANE_HOLD;
                            end else begin
                                mul_index_q <= mul_index_q + 5'd1;
                                state_q     <= ST_MUL_REQ;
                            end
                        end
                    end else if (watchdog_q >= CHILD_TIMEOUT_LAST) begin
                        error_code_q  <= ERR_RSP_TIMEOUT;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else begin
                        watchdog_q <= watchdog_q + 16'd1;
                    end
                end

                ST_LANE_HOLD: begin
                    watchdog_q <= 16'b0;
                    if (lane_fire_w) begin
                        if (lane_index_q == 5'd31) begin
                            state_q <= ST_DONE;
                        end else begin
                            lane_index_q <= lane_index_q + 5'd1;
                        end
                    end
                end

                ST_DONE: begin
                    state_q <= ST_IDLE;
                end

                ST_ERROR: begin
                    state_q <= ST_IDLE;
                end

                default: begin
                    error_code_q  <= ERR_INTERNAL;
                    child_reset_q <= 1'b1;
                    state_q       <= ST_ERROR;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
