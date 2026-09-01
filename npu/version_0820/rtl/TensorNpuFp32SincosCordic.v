`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// Single-outstanding binary32 sine/cosine block for the functional NPU.
//
// The implementation is deliberately RTL-owned: no DPI call, SystemVerilog
// real, simulator math system task, or host tensor arithmetic participates in
// the result.  A 24x128-bit fixed reciprocal converts the finite binary32
// angle from radians to a modulo-one-turn phase.  A 48-step circular CORDIC
// then produces Q2.62 sine/cosine values, rounded to Q2.30 and packed as
// binary32.  The final Q2.30 quantization bounds the absolute trigonometric
// error contributed by this block to below 2^-30 plus CORDIC/range-reduction
// truncation; it is not claimed to reproduce a particular libc sincosf bit
// pattern.
//
// Protocol:
//   * one request may be resident;
//   * req_ready_o is low until the held response is consumed;
//   * response data and error remain stable under backpressure;
//   * NaN/Inf input completes with error_o and quiet-NaN payloads.
module TensorNpuFp32SincosCordic (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] angle_bits_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] sin_bits_o,
    output wire [31:0] cos_bits_o,
    output wire        error_o
);

    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_ITER = 2'd1;
    localparam [1:0] ST_PACK = 2'd2;
    localparam [1:0] ST_RSP  = 2'd3;

    // round((1/(2*pi))*2^128), generated with 100-decimal-digit arithmetic.
    localparam [127:0] INV_TWO_PI_Q128 =
        128'h28be60db9391054a7f09d5f47d4d3770;
    // round(K_cordic*2^62), K_cordic = product_i 1/sqrt(1+2^(-2i)).
    localparam signed [63:0] CORDIC_K_Q62 =
        64'sh26dd3b6a10d7969a;
    localparam signed [63:0] QUARTER_TURN =
        64'sh4000000000000000;
    localparam signed [63:0] NEG_QUARTER_TURN =
       -64'sh4000000000000000;
    localparam signed [63:0] HALF_TURN_MOD =
        64'sh8000000000000000;

    reg [1:0] state_q;
    reg [5:0] iteration_q;
    reg signed [63:0] x_q;
    reg signed [63:0] y_q;
    reg signed [63:0] z_q;
    reg negate_q;
    reg [31:0] sin_bits_q;
    reg [31:0] cos_bits_q;
    reg error_q;

    wire req_fire_w = req_valid_i && req_ready_o;
    wire rsp_fire_w = rsp_valid_o && rsp_ready_i;
    assign req_ready_o = !rst_i && (state_q == ST_IDLE);
    assign rsp_valid_o = !rst_i && (state_q == ST_RSP);
    assign sin_bits_o = sin_bits_q;
    assign cos_bits_o = cos_bits_q;
    assign error_o = rsp_valid_o && error_q;

    // ------------------------------------------------------------------
    // Exact binary32 -> binary-turn reduction.
    //
    // finite normal value = mantissa * 2^(exponent-150) radians
    // phase_q64          = value/(2*pi) * 2^64
    //                    = mantissa*INV_TWO_PI_Q128 * 2^(exponent-214)
    // Expected ROPE inputs are bounded to |angle| <= 262143, so the variable
    // right shift is in [69, 151].  The general finite/subnormal cases remain
    // deterministic and fail closed only for NaN/Inf.
    // ------------------------------------------------------------------
    wire angle_nonfinite_w = angle_bits_i[30:23] == 8'hff;
    wire angle_zero_w = angle_bits_i[30:0] == 31'd0;
    wire [23:0] angle_mantissa_w = angle_bits_i[30:23] == 8'd0 ?
        {1'b0, angle_bits_i[22:0]} : {1'b1, angle_bits_i[22:0]};
    wire [7:0] effective_exponent_w = angle_bits_i[30:23] == 8'd0 ?
        8'd1 : angle_bits_i[30:23];
    wire [151:0] phase_product_w =
        angle_mantissa_w * INV_TWO_PI_Q128;

    integer phase_shift_r;
    reg [151:0] phase_round_bias_r;
    // Upper bits are whole turns and are intentionally discarded modulo one
    // turn after the shift below.
    /* verilator lint_off UNUSEDSIGNAL */
    reg [151:0] phase_rounded_r;
    /* verilator lint_on UNUSEDSIGNAL */
    reg [63:0] phase_abs_r;
    reg signed [63:0] phase_signed_r;
    reg signed [63:0] reduced_phase_r;
    reg reduced_negate_r;
    always @(*) begin
        phase_shift_r = 32'd214 - {24'd0, effective_exponent_w};
        phase_round_bias_r = 152'd0;
        phase_rounded_r = 152'd0;
        phase_abs_r = 64'd0;
        if (!angle_zero_w) begin
            if (phase_shift_r >= 152) begin
                phase_abs_r = 64'd0;
            end else if (phase_shift_r > 0) begin
                phase_round_bias_r = 152'd1 << (phase_shift_r - 1);
                phase_rounded_r =
                    (phase_product_w + phase_round_bias_r) >> phase_shift_r;
                phase_abs_r = phase_rounded_r[63:0];
            end else begin
                phase_rounded_r = phase_product_w << (-phase_shift_r);
                phase_abs_r = phase_rounded_r[63:0];
            end
        end
        phase_signed_r = angle_bits_i[31] ?
            -$signed(phase_abs_r) : $signed(phase_abs_r);
        reduced_phase_r = phase_signed_r;
        reduced_negate_r = 1'b0;
        if (phase_signed_r > QUARTER_TURN) begin
            // Subtract one half-turn modulo 2^64 and negate the final vector.
            reduced_phase_r = phase_signed_r + HALF_TURN_MOD;
            reduced_negate_r = 1'b1;
        end else if (phase_signed_r < NEG_QUARTER_TURN) begin
            // Add one half-turn modulo 2^64 and negate the final vector.
            reduced_phase_r = phase_signed_r - HALF_TURN_MOD;
            reduced_negate_r = 1'b1;
        end
    end

    // atan(2^-i)/(2*pi) in unsigned Q0.64 turns.  All values are positive;
    // z_q chooses add/subtract according to its current sign.
    reg signed [63:0] atan_r;
    always @(*) begin
        case (iteration_q)
            6'd0:  atan_r = 64'sh2000000000000000;
            6'd1:  atan_r = 64'sh12e4051d9df30866;
            6'd2:  atan_r = 64'sh09fb385b5ee39e8e;
            6'd3:  atan_r = 64'sh051111d41ddd9a1b;
            6'd4:  atan_r = 64'sh028b0d430e589aed;
            6'd5:  atan_r = 64'sh0145d7e159046278;
            6'd6:  atan_r = 64'sh00a2f61e5c28262a;
            6'd7:  atan_r = 64'sh00517c5511d442af;
            6'd8:  atan_r = 64'sh0028be5346d0c337;
            6'd9:  atan_r = 64'sh00145f2ebb30ab38;
            6'd10: atan_r = 64'sh000a2f980091ba7b;
            6'd11: atan_r = 64'sh000517cc14a80cb7;
            6'd12: atan_r = 64'sh00028be60cdfec62;
            6'd13: atan_r = 64'sh000145f306c172f2;
            6'd14: atan_r = 64'sh0000a2f9836ae911;
            6'd15: atan_r = 64'sh0000517cc1b6ba7c;
            6'd16: atan_r = 64'sh000028be60db85fc;
            6'd17: atan_r = 64'sh0000145f306dc816;
            6'd18: atan_r = 64'sh00000a2f9836e4ae;
            6'd19: atan_r = 64'sh00000517cc1b726b;
            6'd20: atan_r = 64'sh0000028be60db938;
            6'd21: atan_r = 64'sh00000145f306dc9c;
            6'd22: atan_r = 64'sh000000a2f9836e4e;
            6'd23: atan_r = 64'sh000000517cc1b727;
            6'd24: atan_r = 64'sh00000028be60db94;
            6'd25: atan_r = 64'sh000000145f306dca;
            6'd26: atan_r = 64'sh0000000a2f9836e5;
            6'd27: atan_r = 64'sh0000000517cc1b72;
            6'd28: atan_r = 64'sh000000028be60db9;
            6'd29: atan_r = 64'sh0000000145f306dd;
            6'd30: atan_r = 64'sh00000000a2f9836e;
            6'd31: atan_r = 64'sh00000000517cc1b7;
            6'd32: atan_r = 64'sh0000000028be60dc;
            6'd33: atan_r = 64'sh00000000145f306e;
            6'd34: atan_r = 64'sh000000000a2f9837;
            6'd35: atan_r = 64'sh000000000517cc1b;
            6'd36: atan_r = 64'sh00000000028be60e;
            6'd37: atan_r = 64'sh000000000145f307;
            6'd38: atan_r = 64'sh0000000000a2f983;
            6'd39: atan_r = 64'sh0000000000517cc2;
            6'd40: atan_r = 64'sh000000000028be61;
            6'd41: atan_r = 64'sh0000000000145f30;
            6'd42: atan_r = 64'sh00000000000a2f98;
            6'd43: atan_r = 64'sh00000000000517cc;
            6'd44: atan_r = 64'sh0000000000028be6;
            6'd45: atan_r = 64'sh00000000000145f3;
            6'd46: atan_r = 64'sh000000000000a2fa;
            6'd47: atan_r = 64'sh000000000000517d;
            default: atan_r = 64'sd0;
        endcase
    end

    wire signed [63:0] x_shift_w = x_q >>> iteration_q;
    wire signed [63:0] y_shift_w = y_q >>> iteration_q;
    wire signed [63:0] x_next_w = z_q[63] ?
        (x_q + y_shift_w) : (x_q - y_shift_w);
    wire signed [63:0] y_next_w = z_q[63] ?
        (y_q - x_shift_w) : (y_q + x_shift_w);
    wire signed [63:0] z_next_w = z_q[63] ?
        (z_q + atan_r) : (z_q - atan_r);

    // Symmetric RNE from signed Q2.62 to signed Q2.30.  Ties select the even
    // Q2.30 integer; the values remain inside [-2^30, +2^30].
    reg [63:0] sin_abs_r;
    reg [63:0] cos_abs_r;
    reg [31:0] sin_trunc_r;
    reg [31:0] cos_trunc_r;
    reg sin_guard_r;
    reg cos_guard_r;
    reg sin_sticky_r;
    reg cos_sticky_r;
    reg signed [31:0] sin_q30_r;
    reg signed [31:0] cos_q30_r;
    reg signed [63:0] final_sin_r;
    reg signed [63:0] final_cos_r;
    always @(*) begin
        final_sin_r = negate_q ? -y_q : y_q;
        final_cos_r = negate_q ? -x_q : x_q;
        sin_abs_r = final_sin_r[63] ? -final_sin_r : final_sin_r;
        cos_abs_r = final_cos_r[63] ? -final_cos_r : final_cos_r;
        sin_trunc_r = sin_abs_r[63:32];
        cos_trunc_r = cos_abs_r[63:32];
        sin_guard_r = sin_abs_r[31];
        cos_guard_r = cos_abs_r[31];
        sin_sticky_r = |sin_abs_r[30:0];
        cos_sticky_r = |cos_abs_r[30:0];
        if (sin_guard_r && (sin_sticky_r || sin_trunc_r[0]))
            sin_trunc_r = sin_trunc_r + 32'd1;
        if (cos_guard_r && (cos_sticky_r || cos_trunc_r[0]))
            cos_trunc_r = cos_trunc_r + 32'd1;
        sin_q30_r = final_sin_r[63] ? -$signed(sin_trunc_r) :
                                      $signed(sin_trunc_r);
        cos_q30_r = final_cos_r[63] ? -$signed(cos_trunc_r) :
                                      $signed(cos_trunc_r);
    end

    wire [31:0] sin_integer_bits_w;
    wire [31:0] cos_integer_bits_w;
    wire sin_integer_inexact_unused_w;
    wire cos_integer_inexact_unused_w;
    TensorNpuInt32ToFp32 u_sin_pack (
        .int_i(sin_q30_r),
        .fp32_bits_o(sin_integer_bits_w),
        .inexact_o(sin_integer_inexact_unused_w)
    );
    TensorNpuInt32ToFp32 u_cos_pack (
        .int_i(cos_q30_r),
        .fp32_bits_o(cos_integer_bits_w),
        .inexact_o(cos_integer_inexact_unused_w)
    );

    wire [31:0] sin_scaled_bits_w = sin_integer_bits_w[30:0] == 31'd0 ?
        32'd0 : {sin_integer_bits_w[31],
                 sin_integer_bits_w[30:23] - 8'd30,
                 sin_integer_bits_w[22:0]};
    wire [31:0] cos_scaled_bits_w = cos_integer_bits_w[30:0] == 31'd0 ?
        32'd0 : {cos_integer_bits_w[31],
                 cos_integer_bits_w[30:23] - 8'd30,
                 cos_integer_bits_w[22:0]};

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            iteration_q <= 6'd0;
            x_q <= 64'sd0;
            y_q <= 64'sd0;
            z_q <= 64'sd0;
            negate_q <= 1'b0;
            sin_bits_q <= 32'd0;
            cos_bits_q <= 32'd0;
            error_q <= 1'b0;
        end else begin
            case (state_q)
                ST_IDLE: begin
                    error_q <= 1'b0;
                    if (req_fire_w) begin
                        if (angle_nonfinite_w) begin
                            sin_bits_q <= 32'h7fc00000;
                            cos_bits_q <= 32'h7fc00000;
                            error_q <= 1'b1;
                            state_q <= ST_RSP;
                        end else begin
                            iteration_q <= 6'd0;
                            x_q <= CORDIC_K_Q62;
                            y_q <= 64'sd0;
                            z_q <= reduced_phase_r;
                            negate_q <= reduced_negate_r;
                            state_q <= ST_ITER;
                        end
                    end
                end

                ST_ITER: begin
                    x_q <= x_next_w;
                    y_q <= y_next_w;
                    z_q <= z_next_w;
                    if (iteration_q == 6'd47) begin
                        state_q <= ST_PACK;
                    end else begin
                        iteration_q <= iteration_q + 6'd1;
                    end
                end

                ST_PACK: begin
                    sin_bits_q <= sin_scaled_bits_w;
                    cos_bits_q <= cos_scaled_bits_w;
                    state_q <= ST_RSP;
                end

                ST_RSP: begin
                    if (rsp_fire_w)
                        state_q <= ST_IDLE;
                end

                default: begin
                    state_q <= ST_IDLE;
                    error_q <= 1'b1;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
