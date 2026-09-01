// SPDX-License-Identifier: MIT
//
// TensorNpuQ8ScaleAccumulator
//
// Requirement -> protocol -> FSM -> invariant -> datapath -> topology trace:
//   * One command consumes block_count_i pairs of GGML Q8_0 blocks.
//   * The input stream is accepted only in WAIT_BLOCK; start_i is accepted only
//     in IDLE and is deliberately ignored while the command is busy.
//   * Each block follows the generic ggml order exactly:
//       sumi = dot(qx, qy)
//       scale = RN32(fp32(dx)   * fp32(dy))
//       term  = RN32(fp32(sumi) * scale)
//       acc   = RN32(acc         + term)
//     The two multiplies and the add are separate transactions.  In
//     particular, the parenthesized scale product matches b10507
//     ggml_vec_dot_q8_0_q8_0_generic; this module neither reassociates the
//     multiplies, contracts them into an FMA, nor builds a cross-block tree.
//   * At most one dot transaction and one FP32 transaction are outstanding.
//     REQ states hold their valid bit and payload until the child accepts them;
//     WAIT states alone return response credit.
//   * block_index_q advances only after a successful ADD response.  Therefore
//     a failing block cannot make a partial result architecturally visible.
//   * result_bits_o is cleared when a command is accepted and is published only
//     by the final successful ADD.  DONE and ERROR are one-cycle terminal
//     states, while busy_o covers every non-IDLE state including those states.
//   * Critical-path isolation: the integer dot, both FP32 multiplies, and FP32
//     add are separated by registered FSM boundaries.  The only shared-FPU mux
//     selects registered operands in the three explicit REQ states.

module TensorNpuQ8ScaleAccumulator #(
    parameter integer MAC_LANES = 8
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [31:0]  block_count_i,

    input  wire         block_valid_i,
    output wire         block_ready_o,
    input  wire [271:0] x_block_i,
    input  wire [271:0] y_block_i,

    output wire         done_o,
    output wire         error_o,
    output wire [3:0]   error_code_o,
    output reg  [31:0]  result_bits_o
);

    localparam [3:0] ERR_NONE            = 4'd0;
    localparam [3:0] ERR_INVALID_COUNT   = 4'd1;
    localparam [3:0] ERR_NONFINITE_SCALE = 4'd2;
    localparam [3:0] ERR_DOT_CONVERSION  = 4'd3;
    localparam [3:0] ERR_FP32_NUMERIC    = 4'd4;

    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_WAIT_BLOCK = 4'd1;
    localparam [3:0] ST_DOT_WAIT   = 4'd2;
    localparam [3:0] ST_SCALE_MUL_REQ  = 4'd3;
    localparam [3:0] ST_SCALE_MUL_WAIT = 4'd4;
    localparam [3:0] ST_TERM_MUL_REQ   = 4'd5;
    localparam [3:0] ST_TERM_MUL_WAIT  = 4'd6;
    localparam [3:0] ST_ADD_REQ        = 4'd7;
    localparam [3:0] ST_ADD_WAIT       = 4'd8;
    localparam [3:0] ST_DONE           = 4'd9;
    localparam [3:0] ST_ERROR          = 4'd10;

    reg [3:0]  state_q;
    reg [3:0]  error_code_q;
    reg [31:0] block_count_q;
    reg [31:0] block_index_q;
    reg [31:0] acc_bits_q;
    reg [31:0] sum_bits_q;
    reg [31:0] scale_x_bits_q;
    reg [31:0] scale_y_bits_q;
    reg [31:0] scale_product_bits_q;
    reg [31:0] term_bits_q;

    wire        dot_ready_w;
    wire        unused_dot_busy_w;
    wire        dot_done_w;
    wire signed [31:0] dot_sum_w;
    wire [15:0] dot_x_scale_w;
    wire [15:0] dot_y_scale_w;
    wire        dot_start_w;

    wire [31:0] dot_x_scale_fp32_w;
    wire [31:0] dot_y_scale_fp32_w;
    wire        dot_x_scale_finite_w;
    wire        dot_y_scale_finite_w;
    wire        unused_dot_x_scale_zero_w;
    wire        unused_dot_y_scale_zero_w;
    wire [31:0] dot_sum_fp32_w;
    wire        dot_sum_inexact_w;

    reg         fp_req_valid_r;
    reg         fp_op_mul_r;
    reg [31:0]  fp_lhs_bits_r;
    reg [31:0]  fp_rhs_bits_r;
    wire        fp_req_ready_w;
    wire        fp_rsp_valid_w;
    wire        fp_rsp_ready_w;
    wire [31:0] fp_result_bits_w;
    wire [4:0]  fp_flags_w;
    wire        fp_req_fire_w;
    wire        fp_rsp_fire_w;
    wire        fp_response_bad_w;

    assign ready_o      = !rst_i && (state_q == ST_IDLE);
    assign busy_o       = (state_q != ST_IDLE);
    assign done_o       = !rst_i && ((state_q == ST_DONE) ||
                                     (state_q == ST_ERROR));
    assign error_o      = !rst_i && (state_q == ST_ERROR);
    assign error_code_o = (state_q == ST_ERROR) ? error_code_q : ERR_NONE;

    // Input-stream credit is withheld for every arithmetic phase.  dot_ready_w
    // additionally prevents a new block from overwriting a live dot request.
    assign block_ready_o = !rst_i && (state_q == ST_WAIT_BLOCK) &&
                           dot_ready_w;
    assign dot_start_w   = block_valid_i && block_ready_o;

    assign fp_req_fire_w = fp_req_valid_r && fp_req_ready_w;
    assign fp_rsp_ready_w = (state_q == ST_SCALE_MUL_WAIT) ||
                            (state_q == ST_TERM_MUL_WAIT) ||
                            (state_q == ST_ADD_WAIT);
    assign fp_rsp_fire_w = fp_rsp_valid_w && fp_rsp_ready_w;

    // fflags[4:0] = {NV,DZ,OF,UF,NX}.  Q8_0 permits an exact or inexact finite
    // result, including UF/NX, but never permits NaN/Inf, NV, DZ, or OF.
    assign fp_response_bad_w = (&fp_result_bits_w[30:23]) ||
                               fp_flags_w[4] || fp_flags_w[3] ||
                               fp_flags_w[2];

    // Shared FP32 request mux.  Every selected payload is backed by a register,
    // so it remains stable throughout arbitrary req_ready_o backpressure.
    always @(*) begin
        fp_req_valid_r = 1'b0;
        fp_op_mul_r    = 1'b0;
        fp_lhs_bits_r  = 32'h00000000;
        fp_rhs_bits_r  = 32'h00000000;

        case (state_q)
            ST_SCALE_MUL_REQ: begin
                fp_req_valid_r = 1'b1;
                fp_op_mul_r    = 1'b1;
                fp_lhs_bits_r  = scale_x_bits_q;
                fp_rhs_bits_r  = scale_y_bits_q;
            end

            ST_TERM_MUL_REQ: begin
                fp_req_valid_r = 1'b1;
                fp_op_mul_r    = 1'b1;
                fp_lhs_bits_r  = sum_bits_q;
                fp_rhs_bits_r  = scale_product_bits_q;
            end

            ST_ADD_REQ: begin
                fp_req_valid_r = 1'b1;
                fp_op_mul_r    = 1'b0;
                fp_lhs_bits_r  = acc_bits_q;
                fp_rhs_bits_r  = term_bits_q;
            end

            default: begin
                fp_req_valid_r = 1'b0;
                fp_op_mul_r    = 1'b0;
                fp_lhs_bits_r  = 32'h00000000;
                fp_rhs_bits_r  = 32'h00000000;
            end
        endcase
    end

    TensorNpuQ8DotEngine #(
        .MAC_LANES(MAC_LANES)
    ) u_dot_engine (
        .clk_i     (clk_i),
        .rst_i     (rst_i),
        .start_i   (dot_start_w),
        .ready_o   (dot_ready_w),
        .busy_o    (unused_dot_busy_w),
        .x_block_i (x_block_i),
        .y_block_i (y_block_i),
        .done_o    (dot_done_w),
        .sum_o     (dot_sum_w),
        .x_scale_o (dot_x_scale_w),
        .y_scale_o (dot_y_scale_w)
    );

    TensorNpuFp16ToFp32 u_x_scale_convert (
        .fp16_bits_i (dot_x_scale_w),
        .fp32_bits_o (dot_x_scale_fp32_w),
        .finite_o    (dot_x_scale_finite_w),
        .zero_o      (unused_dot_x_scale_zero_w)
    );

    TensorNpuFp16ToFp32 u_y_scale_convert (
        .fp16_bits_i (dot_y_scale_w),
        .fp32_bits_o (dot_y_scale_fp32_w),
        .finite_o    (dot_y_scale_finite_w),
        .zero_o      (unused_dot_y_scale_zero_w)
    );

    TensorNpuInt32ToFp32 u_dot_sum_convert (
        .int_i        (dot_sum_w),
        .fp32_bits_o  (dot_sum_fp32_w),
        .inexact_o    (dot_sum_inexact_w)
    );

    TensorNpuFp32AddMul u_fp32_addmul (
        .clk_i         (clk_i),
        .rst_i         (rst_i),
        .req_valid_i   (fp_req_valid_r),
        .req_ready_o   (fp_req_ready_w),
        .op_mul_i      (fp_op_mul_r),
        .lhs_bits_i    (fp_lhs_bits_r),
        .rhs_bits_i    (fp_rhs_bits_r),
        .rsp_valid_o   (fp_rsp_valid_w),
        .rsp_ready_i   (fp_rsp_ready_w),
        .result_bits_o (fp_result_bits_w),
        .flags_o       (fp_flags_w)
    );

    // Sequential traceability:
    // IDLE -> WAIT_BLOCK -> DOT_WAIT -> SCALE_MUL -> TERM_MUL -> ADD ->
    // (WAIT_BLOCK | DONE), with every validation failure routed to ERROR.
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q        <= ST_IDLE;
            error_code_q   <= ERR_NONE;
            block_count_q  <= 32'd0;
            block_index_q  <= 32'd0;
            acc_bits_q     <= 32'h00000000;
            sum_bits_q     <= 32'h00000000;
            scale_x_bits_q <= 32'h00000000;
            scale_y_bits_q <= 32'h00000000;
            scale_product_bits_q <= 32'h00000000;
            term_bits_q          <= 32'h00000000;
            result_bits_o  <= 32'h00000000;
        end else begin
            case (state_q)
                ST_IDLE: begin
                    error_code_q <= ERR_NONE;
                    if (start_i) begin
                        // Every accepted command starts with a non-published
                        // +0; an old successful result remains visible until
                        // this architectural acceptance point.
                        block_count_q <= block_count_i;
                        block_index_q <= 32'd0;
                        acc_bits_q    <= 32'h00000000;
                        result_bits_o <= 32'h00000000;
                        if (block_count_i == 32'd0) begin
                            error_code_q <= ERR_INVALID_COUNT;
                            state_q      <= ST_ERROR;
                        end else begin
                            state_q <= ST_WAIT_BLOCK;
                        end
                    end
                end

                ST_WAIT_BLOCK: begin
                    if (dot_start_w) begin
                        state_q <= ST_DOT_WAIT;
                    end
                end

                ST_DOT_WAIT: begin
                    if (dot_done_w) begin
                        // Error ordering is architectural: malformed scale has
                        // priority over the defensive dot-conversion guard.
                        if (!dot_x_scale_finite_w || !dot_y_scale_finite_w) begin
                            error_code_q <= ERR_NONFINITE_SCALE;
                            state_q      <= ST_ERROR;
                        end else if (dot_sum_inexact_w) begin
                            error_code_q <= ERR_DOT_CONVERSION;
                            state_q      <= ST_ERROR;
                        end else begin
                            sum_bits_q     <= dot_sum_fp32_w;
                            scale_x_bits_q <= dot_x_scale_fp32_w;
                            scale_y_bits_q <= dot_y_scale_fp32_w;
                            state_q        <= ST_SCALE_MUL_REQ;
                        end
                    end
                end

                ST_SCALE_MUL_REQ: begin
                    if (fp_req_fire_w) begin
                        state_q <= ST_SCALE_MUL_WAIT;
                    end
                end

                ST_SCALE_MUL_WAIT: begin
                    if (fp_rsp_fire_w) begin
                        if (fp_response_bad_w) begin
                            error_code_q <= ERR_FP32_NUMERIC;
                            state_q      <= ST_ERROR;
                        end else begin
                            scale_product_bits_q <= fp_result_bits_w;
                            state_q              <= ST_TERM_MUL_REQ;
                        end
                    end
                end

                ST_TERM_MUL_REQ: begin
                    if (fp_req_fire_w) begin
                        state_q <= ST_TERM_MUL_WAIT;
                    end
                end

                ST_TERM_MUL_WAIT: begin
                    if (fp_rsp_fire_w) begin
                        if (fp_response_bad_w) begin
                            error_code_q <= ERR_FP32_NUMERIC;
                            state_q      <= ST_ERROR;
                        end else begin
                            term_bits_q <= fp_result_bits_w;
                            state_q     <= ST_ADD_REQ;
                        end
                    end
                end

                ST_ADD_REQ: begin
                    if (fp_req_fire_w) begin
                        state_q <= ST_ADD_WAIT;
                    end
                end

                ST_ADD_WAIT: begin
                    if (fp_rsp_fire_w) begin
                        if (fp_response_bad_w) begin
                            error_code_q <= ERR_FP32_NUMERIC;
                            state_q      <= ST_ERROR;
                        end else if (block_index_q ==
                                     (block_count_q - 32'd1)) begin
                            // The only architectural publication point.
                            acc_bits_q    <= fp_result_bits_w;
                            result_bits_o <= fp_result_bits_w;
                            state_q       <= ST_DONE;
                        end else begin
                            acc_bits_q    <= fp_result_bits_w;
                            block_index_q <= block_index_q + 32'd1;
                            state_q       <= ST_WAIT_BLOCK;
                        end
                    end
                end

                ST_DONE: begin
                    error_code_q <= ERR_NONE;
                    state_q      <= ST_IDLE;
                end

                ST_ERROR: begin
                    error_code_q <= ERR_NONE;
                    state_q      <= ST_IDLE;
                end

                default: begin
                    // Corrupt/unknown control state fails closed and never
                    // publishes a partial arithmetic result.
                    result_bits_o <= 32'h00000000;
                    error_code_q  <= ERR_FP32_NUMERIC;
                    state_q       <= ST_ERROR;
                end
            endcase
        end
    end

endmodule
