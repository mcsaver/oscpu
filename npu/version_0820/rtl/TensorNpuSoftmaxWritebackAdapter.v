`timescale 1ns/1ps
`default_nettype none

// Standalone raw-GMEM owner for the one frozen Qwen SOFT_MAX profile.
//
// The numerical contract is deliberately NPU-owned and deterministic:
//   score[i] = ADD_RNE(MUL_RNE(src0[i], 0x3d800000), mask[i])
//   max      = a left-to-right raw IEEE-754 comparison over non-NaN scores
//   e[i]     = AOR_EXP32(ADD_RNE(score[i], -max))
//   sum      = ADD_RNE(...ADD_RNE(ADD_RNE(+0,e[0]),e[1])...,e[255])
//   inv      = DIV_RNE(1.0,sum)
//   dst[i]   = MUL_RNE(e[i],inv)
//
// Mask data is read once and broadcast to all eight heads.  The AOR exp is an
// Arm optimized-routines source replay and is not claimed to be bit-identical
// to a host libm expf implementation.  All destination writes target a private
// shadow; dst_commit_o is the only publication eligibility signal.
module TensorNpuSoftmaxWritebackAdapter #(
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd512,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd16777216,
    parameter [31:0] DRAIN_TIMEOUT_CYCLES = 32'd1024,
    parameter [31:0] ABORT_HOLD_TIMEOUT_CYCLES = 32'd1024,
    parameter integer EXP_COMMAND_TIMEOUT_CYCLES = 128
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [2:0]   reduce_op_i,
    input  wire [15:0]  manifest_op_id_i,
    input  wire [2:0]   source_arity_i,
    input  wire [127:0] op_params_i,
    input  wire         op_params_tail_zero_i,
    input  wire         npu_required_i,
    input  wire [63:0]  command_id_i,
    input  wire [63:0]  canonical_node_id_lo_i,
    input  wire [63:0]  canonical_node_id_hi_i,
    input  wire         dst_shadow_private_i,
    input  wire         windows_generation_valid_i,

    input  wire [7:0]   src0_dtype_i,
    input  wire [31:0]  src0_flags_i,
    input  wire [63:0]  src0_view_off_i,
    input  wire [31:0]  src0_ne0_i,
    input  wire [31:0]  src0_ne1_i,
    input  wire [31:0]  src0_ne2_i,
    input  wire [31:0]  src0_ne3_i,
    input  wire [63:0]  src0_base_i,
    input  wire [63:0]  src0_nb0_i,
    input  wire [63:0]  src0_nb1_i,
    input  wire [63:0]  src0_nb2_i,
    input  wire [63:0]  src0_nb3_i,

    input  wire [7:0]   src1_dtype_i,
    input  wire [31:0]  src1_flags_i,
    input  wire [63:0]  src1_view_off_i,
    input  wire [31:0]  src1_ne0_i,
    input  wire [31:0]  src1_ne1_i,
    input  wire [31:0]  src1_ne2_i,
    input  wire [31:0]  src1_ne3_i,
    input  wire [63:0]  src1_base_i,
    input  wire [63:0]  src1_nb0_i,
    input  wire [63:0]  src1_nb1_i,
    input  wire [63:0]  src1_nb2_i,
    input  wire [63:0]  src1_nb3_i,

    input  wire [7:0]   dst_dtype_i,
    input  wire [31:0]  dst_flags_i,
    input  wire [63:0]  dst_view_off_i,
    input  wire [31:0]  dst_ne0_i,
    input  wire [31:0]  dst_ne1_i,
    input  wire [31:0]  dst_ne2_i,
    input  wire [31:0]  dst_ne3_i,
    input  wire [63:0]  dst_base_i,
    input  wire [63:0]  dst_nb0_i,
    input  wire [63:0]  dst_nb1_i,
    input  wire [63:0]  dst_nb2_i,
    input  wire [63:0]  dst_nb3_i,

    input  wire [63:0]  src0_window_base_i,
    input  wire [63:0]  src0_window_bytes_i,
    input  wire         src0_window_read_i,
    input  wire         src0_window_write_i,
    input  wire [63:0]  src1_window_base_i,
    input  wire [63:0]  src1_window_bytes_i,
    input  wire         src1_window_read_i,
    input  wire         src1_window_write_i,
    input  wire [63:0]  dst_window_base_i,
    input  wire [63:0]  dst_window_bytes_i,
    input  wire         dst_window_read_i,
    input  wire         dst_window_write_i,

    output wire         gmem_req_valid_o,
    input  wire         gmem_req_ready_i,
    output wire         gmem_req_write_o,
    output wire [63:0]  gmem_req_addr_o,
    output wire [63:0]  gmem_req_wdata_o,
    output wire [7:0]   gmem_req_wstrb_o,
    input  wire         gmem_rsp_valid_i,
    output wire         gmem_rsp_ready_o,
    input  wire [63:0]  gmem_rsp_rdata_i,
    input  wire         gmem_rsp_error_i,

    output wire         completion_valid_o,
    output wire         dst_commit_o,
    output wire [63:0]  completion_command_id_o,
    output wire [63:0]  completion_canonical_node_id_lo_o,
    output wire [63:0]  completion_canonical_node_id_hi_o,
    output wire         completion_npu_required_o,
    output wire [2:0]   completion_reduce_op_o,
    output wire [15:0]  completion_manifest_op_id_o,
    output wire [2:0]   completion_source_arity_o,
    output wire [7:0]   completion_profile_id_o,
    output wire [31:0]  completion_kernel_id_o,
    output wire [31:0]  completion_operator_census_o,
    output wire [31:0]  completion_profile_census_o,
    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,
    output wire [3:0]   exp_error_code_o,
    output wire [4:0]   numeric_flags_o,
    output wire         poisoned_o,

    output wire [63:0]  rows_completed_o,
    output wire [63:0]  source0_words_completed_o,
    output wire [63:0]  mask_words_completed_o,
    output wire [63:0]  outputs_computed_o,
    output wire [63:0]  outputs_completed_o,
    output wire [63:0]  max_comparisons_o,
    output wire [63:0]  gmem_read_requests_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_requests_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  scale_requests_o,
    output wire [63:0]  scale_responses_o,
    output wire [63:0]  mask_add_requests_o,
    output wire [63:0]  mask_add_responses_o,
    output wire [63:0]  subtract_requests_o,
    output wire [63:0]  subtract_responses_o,
    output wire [63:0]  exp_requests_o,
    output wire [63:0]  exp_responses_o,
    output wire [63:0]  sum_add_requests_o,
    output wire [63:0]  sum_add_responses_o,
    output wire [63:0]  div_requests_o,
    output wire [63:0]  div_responses_o,
    output wire [63:0]  normalize_mul_requests_o,
    output wire [63:0]  normalize_mul_responses_o,
    output wire [63:0]  exp_active_cycles_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire         addmul_outstanding_o,
    output wire         exp_outstanding_o,
    output wire         div_outstanding_o,
    output wire         gmem_drain_o
);

    localparam [31:0] KERNEL_REDUCE_F32 = 32'h514e0011;
    localparam [2:0]  REDUCE_SOFT_MAX = 3'd6;
    localparam [15:0] MANIFEST_SOFT_MAX = 16'd46;
    localparam [7:0]  MANIFEST_F32 = 8'd0;
    localparam [7:0]  PROFILE_SOFT_MAX = 8'd0;
    localparam [7:0]  PROFILE_INVALID = 8'hff;
    localparam [31:0] FROZEN_OPERATOR_CENSUS = 32'd6;
    localparam [31:0] FROZEN_PROFILE_CENSUS = 32'd1;
    localparam [31:0] SCALE_BITS = 32'h3d800000;

    localparam [4:0] ST_IDLE         = 5'd0;
    localparam [4:0] ST_PREFLIGHT    = 5'd1;
    localparam [4:0] ST_MASK_PREP    = 5'd2;
    localparam [4:0] ST_MASK_REQ     = 5'd3;
    localparam [4:0] ST_MASK_WAIT    = 5'd4;
    localparam [4:0] ST_SRC_PREP     = 5'd5;
    localparam [4:0] ST_SRC_REQ      = 5'd6;
    localparam [4:0] ST_SRC_WAIT     = 5'd7;
    localparam [4:0] ST_SCALE_REQ    = 5'd8;
    localparam [4:0] ST_SCALE_WAIT   = 5'd9;
    localparam [4:0] ST_MASKADD_REQ  = 5'd10;
    localparam [4:0] ST_MASKADD_WAIT = 5'd11;
    localparam [4:0] ST_SUB_REQ      = 5'd12;
    localparam [4:0] ST_SUB_WAIT     = 5'd13;
    localparam [4:0] ST_EXP_REQ      = 5'd14;
    localparam [4:0] ST_EXP_WAIT     = 5'd15;
    localparam [4:0] ST_SUM_REQ      = 5'd16;
    localparam [4:0] ST_SUM_WAIT     = 5'd17;
    localparam [4:0] ST_DIV_REQ      = 5'd18;
    localparam [4:0] ST_DIV_WAIT     = 5'd19;
    localparam [4:0] ST_NORM_REQ     = 5'd20;
    localparam [4:0] ST_NORM_WAIT    = 5'd21;
    localparam [4:0] ST_WRITE_PREP   = 5'd22;
    localparam [4:0] ST_WRITE_REQ    = 5'd23;
    localparam [4:0] ST_WRITE_WAIT   = 5'd24;
    localparam [4:0] ST_GMEM_DRAIN   = 5'd25;
    localparam [4:0] ST_CORE_RESET   = 5'd26;
    localparam [4:0] ST_DONE         = 5'd27;
    localparam [4:0] ST_ERROR        = 5'd28;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_DESCRIPTOR      = 5'd1;
    localparam [4:0] ERR_SOURCE0_WINDOW  = 5'd2;
    localparam [4:0] ERR_SOURCE1_WINDOW  = 5'd3;
    localparam [4:0] ERR_DEST_WINDOW     = 5'd4;
    localparam [4:0] ERR_ALIAS           = 5'd5;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd6;
    localparam [4:0] ERR_NUMERIC         = 5'd7;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd8;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd9;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd10;
    localparam [4:0] ERR_PROTOCOL        = 5'd11;

    localparam [1:0] REQ_MASK  = 2'd0;
    localparam [1:0] REQ_SRC0  = 2'd1;
    localparam [1:0] REQ_WRITE = 2'd2;

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 32'd1) ? 32'd0 : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 64'd1) ? 64'd0 : COMMAND_TIMEOUT_CYCLES - 64'd1;
    localparam [31:0] DRAIN_TIMEOUT_LAST =
        (DRAIN_TIMEOUT_CYCLES <= 32'd1) ? 32'd0 : DRAIN_TIMEOUT_CYCLES - 32'd1;
    localparam [31:0] ABORT_HOLD_TIMEOUT_LAST =
        (ABORT_HOLD_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                             : ABORT_HOLD_TIMEOUT_CYCLES - 32'd1;

    function is_nan32;
        input [31:0] value;
        begin
            is_nan32 = (value[30:23] == 8'hff) && (value[22:0] != 23'b0);
        end
    endfunction

    function is_inf32;
        input [31:0] value;
        begin
            is_inf32 = (value[30:23] == 8'hff) && (value[22:0] == 23'b0);
        end
    endfunction

    // Total ordering used only after NaNs have been rejected.  +0 and -0 tie.
    function fp32_gt;
        input [31:0] lhs;
        input [31:0] rhs;
        begin
            if ((lhs[30:0] == 31'b0) && (rhs[30:0] == 31'b0))
                fp32_gt = 1'b0;
            else if (lhs[31] != rhs[31])
                fp32_gt = !lhs[31];
            else if (!lhs[31])
                fp32_gt = lhs[30:0] > rhs[30:0];
            else
                fp32_gt = lhs[30:0] < rhs[30:0];
        end
    endfunction

    reg [4:0] state_q;
    reg [2:0] reduce_op_q, source_arity_q;
    reg [15:0] manifest_op_id_q;
    reg [127:0] op_params_q;
    reg op_params_tail_zero_q, npu_required_q;
    reg [63:0] command_id_q, canonical_node_id_lo_q, canonical_node_id_hi_q;
    reg dst_shadow_private_q, windows_generation_valid_q;
    reg [7:0] src0_dtype_q, src1_dtype_q, dst_dtype_q;
    reg [31:0] src0_flags_q, src1_flags_q, dst_flags_q;
    reg [63:0] src0_view_off_q, src1_view_off_q, dst_view_off_q;
    reg [31:0] src0_ne0_q, src0_ne1_q, src0_ne2_q, src0_ne3_q;
    reg [31:0] src1_ne0_q, src1_ne1_q, src1_ne2_q, src1_ne3_q;
    reg [31:0] dst_ne0_q, dst_ne1_q, dst_ne2_q, dst_ne3_q;
    reg [63:0] src0_base_q, src1_base_q, dst_base_q;
    reg [63:0] src0_nb0_q, src0_nb1_q, src0_nb2_q, src0_nb3_q;
    reg [63:0] src1_nb0_q, src1_nb1_q, src1_nb2_q, src1_nb3_q;
    reg [63:0] dst_nb0_q, dst_nb1_q, dst_nb2_q, dst_nb3_q;
    reg [63:0] src0_window_base_q, src0_window_bytes_q;
    reg src0_window_read_q, src0_window_write_q;
    reg [63:0] src1_window_base_q, src1_window_bytes_q;
    reg src1_window_read_q, src1_window_write_q;
    reg [63:0] dst_window_base_q, dst_window_bytes_q;
    reg dst_window_read_q, dst_window_write_q;

    reg [7:0] profile_id_q;
    reg [31:0] operator_census_q, profile_census_q;
    reg [4:0] error_code_q, numeric_flags_q;
    reg [3:0] exp_error_code_q;
    reg poisoned_q, abort_hold_q;
    reg [31:0] stall_cycles_q, drain_cycles_q, abort_hold_cycles_q;
    reg [63:0] command_cycles_q, active_cycles_q;

    reg [7:0] mask_pair_q, src_pair_q, element_index_q;
    reg [2:0] head_q;
    reg lane_q;
    reg [31:0] source_value_q, source_upper_q, scaled_q, delta_q;
    reg [31:0] max_q, sum_q, inverse_q, output_lower_q, output_upper_q;
    reg [31:0] mask_mem_q [0:255];
    reg [31:0] score_mem_q [0:255];
    reg [31:0] exp_mem_q [0:255];

    reg [63:0] request_addr_q, request_wdata_q;
    reg [7:0] request_wstrb_q;
    reg request_write_q;
    reg [1:0] request_kind_q;
    reg gmem_outstanding_q, addmul_resident_q, exp_resident_q, div_resident_q;

    reg [63:0] rows_completed_q, source0_words_completed_q, mask_words_completed_q;
    reg [63:0] outputs_computed_q, outputs_completed_q, max_comparisons_q;
    reg [63:0] gmem_read_requests_q, gmem_read_responses_q, read_payload_bytes_q;
    reg [63:0] gmem_write_requests_q, gmem_write_responses_q, write_payload_bytes_q;
    reg [63:0] scale_requests_q, scale_responses_q;
    reg [63:0] mask_add_requests_q, mask_add_responses_q;
    reg [63:0] subtract_requests_q, subtract_responses_q;
    reg [63:0] exp_requests_q, exp_responses_q, exp_active_cycles_q;
    reg [63:0] sum_add_requests_q, sum_add_responses_q;
    reg [63:0] div_requests_q, div_responses_q;
    reg [63:0] normalize_mul_requests_q, normalize_mul_responses_q;

    wire start_fire_w = start_i && ready_o;
    wire request_state_w = (state_q == ST_MASK_REQ) || (state_q == ST_SRC_REQ)
                         || (state_q == ST_WRITE_REQ);
    wire response_state_w = (state_q == ST_MASK_WAIT) || (state_q == ST_SRC_WAIT)
                          || (state_q == ST_WRITE_WAIT) || (state_q == ST_GMEM_DRAIN);
    wire addmul_req_state_w = (state_q == ST_SCALE_REQ)
                            || (state_q == ST_MASKADD_REQ)
                            || (state_q == ST_SUB_REQ)
                            || (state_q == ST_SUM_REQ)
                            || (state_q == ST_NORM_REQ);
    wire addmul_rsp_state_w = (state_q == ST_SCALE_WAIT)
                            || (state_q == ST_MASKADD_WAIT)
                            || (state_q == ST_SUB_WAIT)
                            || (state_q == ST_SUM_WAIT)
                            || (state_q == ST_NORM_WAIT);
    wire stall_state_w = request_state_w || response_state_w
                       || addmul_req_state_w || addmul_rsp_state_w
                       || (state_q == ST_EXP_REQ) || (state_q == ST_EXP_WAIT)
                       || (state_q == ST_DIV_REQ) || (state_q == ST_DIV_WAIT);

    wire gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    wire gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;
    wire core_rst_w = rst_i || (state_q == ST_CORE_RESET);

    reg addmul_op_mul_w;
    reg [31:0] addmul_lhs_w, addmul_rhs_w;
    always @(*) begin
        addmul_op_mul_w = 1'b0;
        addmul_lhs_w = 32'b0;
        addmul_rhs_w = 32'b0;
        case (state_q)
            ST_SCALE_REQ: begin
                addmul_op_mul_w = 1'b1;
                addmul_lhs_w = source_value_q;
                addmul_rhs_w = SCALE_BITS;
            end
            ST_MASKADD_REQ: begin
                addmul_lhs_w = scaled_q;
                addmul_rhs_w = mask_mem_q[element_index_q];
            end
            ST_SUB_REQ: begin
                addmul_lhs_w = score_mem_q[element_index_q];
                addmul_rhs_w = {~max_q[31], max_q[30:0]};
            end
            ST_SUM_REQ: begin
                addmul_lhs_w = sum_q;
                addmul_rhs_w = exp_mem_q[element_index_q];
            end
            ST_NORM_REQ: begin
                addmul_op_mul_w = 1'b1;
                addmul_lhs_w = exp_mem_q[element_index_q];
                addmul_rhs_w = inverse_q;
            end
            default: begin
                addmul_op_mul_w = 1'b0;
                addmul_lhs_w = 32'b0;
                addmul_rhs_w = 32'b0;
            end
        endcase
    end

    wire addmul_req_valid_w = !rst_i && addmul_req_state_w;
    wire addmul_req_ready_w, addmul_rsp_valid_w;
    wire addmul_rsp_ready_w = !rst_i && addmul_rsp_state_w && addmul_resident_q;
    wire [31:0] addmul_result_w;
    wire [4:0] addmul_flags_w;
    wire addmul_req_fire_w = addmul_req_valid_w && addmul_req_ready_w;
    wire addmul_rsp_fire_w = addmul_rsp_valid_w && addmul_rsp_ready_w;

    TensorNpuFp32AddMul u_addmul (
        .clk_i(clk_i), .rst_i(core_rst_w),
        .req_valid_i(addmul_req_valid_w), .req_ready_o(addmul_req_ready_w),
        .op_mul_i(addmul_op_mul_w), .lhs_bits_i(addmul_lhs_w),
        .rhs_bits_i(addmul_rhs_w), .rsp_valid_o(addmul_rsp_valid_w),
        .rsp_ready_i(addmul_rsp_ready_w), .result_bits_o(addmul_result_w),
        .flags_o(addmul_flags_w)
    );

    wire exp_req_valid_w = !rst_i && (state_q == ST_EXP_REQ);
    wire exp_req_ready_w, exp_rsp_valid_w;
    wire exp_rsp_ready_w = !rst_i && (state_q == ST_EXP_WAIT) && exp_resident_q;
    wire [31:0] exp_result_w, exp_cycles_w;
    wire [4:0] exp_flags_w;
    wire exp_error_w;
    wire [3:0] exp_error_code_w;
    wire exp_req_fire_w = exp_req_valid_w && exp_req_ready_w;
    wire exp_rsp_fire_w = exp_rsp_valid_w && exp_rsp_ready_w;

    TensorNpuAorExp32 #(
        .COMMAND_TIMEOUT_CYCLES(EXP_COMMAND_TIMEOUT_CYCLES)
    ) u_exp (
        .clk_i(clk_i), .rst_i(core_rst_w), .req_valid_i(exp_req_valid_w),
        .req_ready_o(exp_req_ready_w), .operand_i(delta_q),
        .rsp_valid_o(exp_rsp_valid_w), .rsp_ready_i(exp_rsp_ready_w),
        .result_o(exp_result_w), .flags_o(exp_flags_w), .error_o(exp_error_w),
        .error_code_o(exp_error_code_w), .active_cycles_o(exp_cycles_w)
    );

    wire div_req_valid_w = !rst_i && (state_q == ST_DIV_REQ);
    wire div_req_ready_w, div_rsp_valid_w;
    wire div_rsp_ready_w = !rst_i && (state_q == ST_DIV_WAIT) && div_resident_q;
    wire [31:0] div_result_w;
    wire [4:0] div_flags_w;
    wire div_req_fire_w = div_req_valid_w && div_req_ready_w;
    wire div_rsp_fire_w = div_rsp_valid_w && div_rsp_ready_w;

    TensorNpuFp32Div u_div (
        .clk_i(clk_i), .rst_i(core_rst_w), .req_valid_i(div_req_valid_w),
        .req_ready_o(div_req_ready_w), .lhs_bits_i(32'h3f800000),
        .rhs_bits_i(sum_q), .rsp_valid_o(div_rsp_valid_w),
        .rsp_ready_i(div_rsp_ready_w), .result_bits_o(div_result_w),
        .flags_o(div_flags_w)
    );

    wire phase_fire_w = gmem_req_fire_w || gmem_rsp_fire_w
                      || addmul_req_fire_w || addmul_rsp_fire_w
                      || exp_req_fire_w || exp_rsp_fire_w
                      || div_req_fire_w || div_rsp_fire_w;
    wire stall_timeout_hit_w = stall_state_w
                             && (stall_cycles_q >= STALL_TIMEOUT_LAST)
                             && !phase_fire_w;
    wire command_timeout_hit_w = (state_q != ST_IDLE) && (state_q != ST_DONE)
                               && (state_q != ST_ERROR) && (state_q != ST_GMEM_DRAIN)
                               && (state_q != ST_CORE_RESET)
                               && (command_cycles_q >= COMMAND_TIMEOUT_LAST)
                               && !phase_fire_w;
    wire drain_timeout_hit_w = (state_q == ST_GMEM_DRAIN)
                             && (drain_cycles_q >= DRAIN_TIMEOUT_LAST)
                             && !gmem_rsp_fire_w;
    wire abort_hold_timeout_hit_w = abort_hold_q && !gmem_req_fire_w
                                  && (abort_hold_cycles_q
                                      >= ABORT_HOLD_TIMEOUT_LAST);

    assign ready_o = !rst_i && (state_q == ST_IDLE) && !poisoned_q
                   && !gmem_rsp_valid_i && addmul_req_ready_w
                   && exp_req_ready_w && div_req_ready_w;
    assign busy_o = !rst_i && (state_q != ST_IDLE);
    assign done_o = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign completion_valid_o = done_o || error_o;
    assign dst_commit_o = done_o;
    assign completion_command_id_o = completion_valid_o ? command_id_q : 64'b0;
    assign completion_canonical_node_id_lo_o = completion_valid_o
                                                ? canonical_node_id_lo_q : 64'b0;
    assign completion_canonical_node_id_hi_o = completion_valid_o
                                                ? canonical_node_id_hi_q : 64'b0;
    assign completion_npu_required_o = completion_valid_o ? npu_required_q : 1'b0;
    assign completion_reduce_op_o = completion_valid_o ? reduce_op_q : 3'b0;
    assign completion_manifest_op_id_o = completion_valid_o ? manifest_op_id_q : 16'b0;
    assign completion_source_arity_o = completion_valid_o ? source_arity_q : 3'b0;
    assign completion_profile_id_o = completion_valid_o ? profile_id_q : 8'b0;
    assign completion_kernel_id_o = completion_valid_o ? KERNEL_REDUCE_F32 : 32'b0;
    assign completion_operator_census_o = completion_valid_o ? operator_census_q : 32'b0;
    assign completion_profile_census_o = completion_valid_o ? profile_census_q : 32'b0;
    assign error_code_o = error_code_q;
    assign exp_error_code_o = exp_error_code_q;
    assign numeric_flags_o = numeric_flags_q;
    assign poisoned_o = !rst_i && poisoned_q;

    assign gmem_req_valid_o = !rst_i && request_state_w;
    assign gmem_req_write_o = request_write_q;
    assign gmem_req_addr_o = request_addr_q;
    assign gmem_req_wdata_o = request_wdata_q;
    assign gmem_req_wstrb_o = request_wstrb_q;
    assign gmem_rsp_ready_o = !rst_i && response_state_w && gmem_outstanding_q;

    assign rows_completed_o = rows_completed_q;
    assign source0_words_completed_o = source0_words_completed_q;
    assign mask_words_completed_o = mask_words_completed_q;
    assign outputs_computed_o = outputs_computed_q;
    assign outputs_completed_o = outputs_completed_q;
    assign max_comparisons_o = max_comparisons_q;
    assign gmem_read_requests_o = gmem_read_requests_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_requests_o = gmem_write_requests_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign scale_requests_o = scale_requests_q;
    assign scale_responses_o = scale_responses_q;
    assign mask_add_requests_o = mask_add_requests_q;
    assign mask_add_responses_o = mask_add_responses_q;
    assign subtract_requests_o = subtract_requests_q;
    assign subtract_responses_o = subtract_responses_q;
    assign exp_requests_o = exp_requests_q;
    assign exp_responses_o = exp_responses_q;
    assign sum_add_requests_o = sum_add_requests_q;
    assign sum_add_responses_o = sum_add_responses_q;
    assign div_requests_o = div_requests_q;
    assign div_responses_o = div_responses_q;
    assign normalize_mul_requests_o = normalize_mul_requests_q;
    assign normalize_mul_responses_o = normalize_mul_responses_q;
    assign exp_active_cycles_o = exp_active_cycles_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = gmem_outstanding_q;
    assign addmul_outstanding_o = addmul_resident_q;
    assign exp_outstanding_o = exp_resident_q;
    assign div_outstanding_o = div_resident_q;
    assign gmem_drain_o = !rst_i && (state_q == ST_GMEM_DRAIN);

    // Whole-footprint preflight.  128-bit intermediates make wraparound an
    // explicit rejection rather than an implicit 64-bit truncation.
    reg descriptor_ok_w, src0_window_ok_w, src1_window_ok_w;
    reg dst_window_ok_w, alias_ok_w;
    reg [4:0] preflight_error_w;
    reg [127:0] src0_end_w, src1_end_w, dst_end_w;
    reg [127:0] src0_window_end_w, src1_window_end_w, dst_window_end_w;
    always @(*) begin
        src0_end_w = {64'b0, src0_base_q} + 128'd8192;
        src1_end_w = {64'b0, src1_base_q} + 128'd1024;
        dst_end_w = {64'b0, dst_base_q} + 128'd8192;
        src0_window_end_w = {64'b0, src0_window_base_q}
                          + {64'b0, src0_window_bytes_q};
        src1_window_end_w = {64'b0, src1_window_base_q}
                          + {64'b0, src1_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};

        descriptor_ok_w = (reduce_op_q == REDUCE_SOFT_MAX)
                        && (manifest_op_id_q == MANIFEST_SOFT_MAX)
                        && (source_arity_q == 3'd2)
                        && (op_params_q == {96'b0, SCALE_BITS})
                        && op_params_tail_zero_q && npu_required_q
                        && dst_shadow_private_q && windows_generation_valid_q
                        && ((canonical_node_id_lo_q != 64'b0)
                            || (canonical_node_id_hi_q != 64'b0))
                        && (src0_dtype_q == MANIFEST_F32)
                        && (src0_flags_q == 32'd16)
                        && (src0_view_off_q == 64'b0)
                        && (src0_ne0_q == 32'd256) && (src0_ne1_q == 32'd1)
                        && (src0_ne2_q == 32'd8) && (src0_ne3_q == 32'd1)
                        && (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd1024)
                        && (src0_nb2_q == 64'd1024) && (src0_nb3_q == 64'd8192)
                        && (src1_dtype_q == MANIFEST_F32)
                        && (src1_flags_q == 32'd1)
                        && (src1_view_off_q == 64'b0)
                        && (src1_ne0_q == 32'd256) && (src1_ne1_q == 32'd1)
                        && (src1_ne2_q == 32'd1) && (src1_ne3_q == 32'd1)
                        && (src1_nb0_q == 64'd4) && (src1_nb1_q == 64'd1024)
                        && (src1_nb2_q == 64'd1024) && (src1_nb3_q == 64'd1024)
                        && (dst_dtype_q == MANIFEST_F32)
                        && (dst_flags_q == 32'd16)
                        && (dst_view_off_q == 64'b0)
                        && (dst_ne0_q == 32'd256) && (dst_ne1_q == 32'd1)
                        && (dst_ne2_q == 32'd8) && (dst_ne3_q == 32'd1)
                        && (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd1024)
                        && (dst_nb2_q == 64'd1024) && (dst_nb3_q == 64'd8192);

        src0_window_ok_w = (src0_end_w[127:64] == 64'b0)
                         && (src0_window_end_w[127:64] == 64'b0)
                         && (src0_base_q[2:0] == 3'b000)
                         && (src0_window_base_q[2:0] == 3'b000)
                         && (src0_window_bytes_q[2:0] == 3'b000)
                         && src0_window_read_q && !src0_window_write_q
                         && (src0_window_bytes_q != 64'b0)
                         && ({64'b0, src0_base_q} >= {64'b0, src0_window_base_q})
                         && (src0_end_w <= src0_window_end_w);
        src1_window_ok_w = (src1_end_w[127:64] == 64'b0)
                         && (src1_window_end_w[127:64] == 64'b0)
                         && (src1_base_q[2:0] == 3'b000)
                         && (src1_window_base_q[2:0] == 3'b000)
                         && (src1_window_bytes_q[2:0] == 3'b000)
                         && src1_window_read_q && !src1_window_write_q
                         && (src1_window_bytes_q != 64'b0)
                         && ({64'b0, src1_base_q} >= {64'b0, src1_window_base_q})
                         && (src1_end_w <= src1_window_end_w);
        dst_window_ok_w = (dst_end_w[127:64] == 64'b0)
                        && (dst_window_end_w[127:64] == 64'b0)
                        && (dst_base_q[2:0] == 3'b000)
                        && (dst_window_base_q[2:0] == 3'b000)
                        && (dst_window_bytes_q[2:0] == 3'b000)
                        && !dst_window_read_q && dst_window_write_q
                        && (dst_window_bytes_q != 64'b0)
                        && ({64'b0, dst_base_q} >= {64'b0, dst_window_base_q})
                        && (dst_end_w <= dst_window_end_w);
        alias_ok_w = ((src0_end_w <= {64'b0, src1_base_q})
                      || (src1_end_w <= {64'b0, src0_base_q}))
                  && ((src0_end_w <= {64'b0, dst_base_q})
                      || (dst_end_w <= {64'b0, src0_base_q}))
                  && ((src1_end_w <= {64'b0, dst_base_q})
                      || (dst_end_w <= {64'b0, src1_base_q}));

        if (!descriptor_ok_w)
            preflight_error_w = ERR_DESCRIPTOR;
        else if (!src0_window_ok_w)
            preflight_error_w = ERR_SOURCE0_WINDOW;
        else if (!src1_window_ok_w)
            preflight_error_w = ERR_SOURCE1_WINDOW;
        else if (!dst_window_ok_w)
            preflight_error_w = ERR_DEST_WINDOW;
        else if (!alias_ok_w)
            preflight_error_w = ERR_ALIAS;
        else
            preflight_error_w = ERR_NONE;
    end

    reg [127:0] runtime_mask_addr_w, runtime_src_addr_w, runtime_dst_addr_w;
    reg runtime_mask_ok_w, runtime_src_ok_w, runtime_dst_ok_w;
    always @(*) begin
        runtime_mask_addr_w = {64'b0, src1_base_q} + ({120'b0, mask_pair_q} * 128'd8);
        runtime_src_addr_w = {64'b0, src0_base_q}
                           + ({125'b0, head_q} * 128'd1024)
                           + ({120'b0, src_pair_q} * 128'd8);
        runtime_dst_addr_w = {64'b0, dst_base_q}
                           + ({125'b0, head_q} * 128'd1024)
                           + ({120'b0, src_pair_q} * 128'd8);
        runtime_mask_ok_w = (mask_pair_q < 8'd128)
                          && (runtime_mask_addr_w[127:64] == 64'b0)
                          && (runtime_mask_addr_w[2:0] == 3'b000)
                          && (runtime_mask_addr_w >= {64'b0, src1_window_base_q})
                          && ((runtime_mask_addr_w + 128'd8) <= src1_window_end_w);
        runtime_src_ok_w = (src_pair_q < 8'd128)
                         && (runtime_src_addr_w[127:64] == 64'b0)
                         && (runtime_src_addr_w[2:0] == 3'b000)
                         && (runtime_src_addr_w >= {64'b0, src0_window_base_q})
                         && ((runtime_src_addr_w + 128'd8) <= src0_window_end_w);
        runtime_dst_ok_w = (src_pair_q < 8'd128)
                         && (runtime_dst_addr_w[127:64] == 64'b0)
                         && (runtime_dst_addr_w[2:0] == 3'b000)
                         && (runtime_dst_addr_w >= {64'b0, dst_window_base_q})
                         && ((runtime_dst_addr_w + 128'd8) <= dst_window_end_w);
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            reduce_op_q <= 3'b0;
            manifest_op_id_q <= 16'b0;
            source_arity_q <= 3'b0;
            op_params_q <= 128'b0;
            op_params_tail_zero_q <= 1'b0;
            npu_required_q <= 1'b0;
            command_id_q <= 64'b0;
            canonical_node_id_lo_q <= 64'b0;
            canonical_node_id_hi_q <= 64'b0;
            dst_shadow_private_q <= 1'b0;
            windows_generation_valid_q <= 1'b0;
            src0_dtype_q <= 8'b0; src1_dtype_q <= 8'b0; dst_dtype_q <= 8'b0;
            src0_flags_q <= 32'b0; src1_flags_q <= 32'b0; dst_flags_q <= 32'b0;
            src0_view_off_q <= 64'b0; src1_view_off_q <= 64'b0; dst_view_off_q <= 64'b0;
            src0_ne0_q <= 32'b0; src0_ne1_q <= 32'b0; src0_ne2_q <= 32'b0; src0_ne3_q <= 32'b0;
            src1_ne0_q <= 32'b0; src1_ne1_q <= 32'b0; src1_ne2_q <= 32'b0; src1_ne3_q <= 32'b0;
            dst_ne0_q <= 32'b0; dst_ne1_q <= 32'b0; dst_ne2_q <= 32'b0; dst_ne3_q <= 32'b0;
            src0_base_q <= 64'b0; src1_base_q <= 64'b0; dst_base_q <= 64'b0;
            src0_nb0_q <= 64'b0; src0_nb1_q <= 64'b0; src0_nb2_q <= 64'b0; src0_nb3_q <= 64'b0;
            src1_nb0_q <= 64'b0; src1_nb1_q <= 64'b0; src1_nb2_q <= 64'b0; src1_nb3_q <= 64'b0;
            dst_nb0_q <= 64'b0; dst_nb1_q <= 64'b0; dst_nb2_q <= 64'b0; dst_nb3_q <= 64'b0;
            src0_window_base_q <= 64'b0; src0_window_bytes_q <= 64'b0;
            src0_window_read_q <= 1'b0; src0_window_write_q <= 1'b0;
            src1_window_base_q <= 64'b0; src1_window_bytes_q <= 64'b0;
            src1_window_read_q <= 1'b0; src1_window_write_q <= 1'b0;
            dst_window_base_q <= 64'b0; dst_window_bytes_q <= 64'b0;
            dst_window_read_q <= 1'b0; dst_window_write_q <= 1'b0;
            profile_id_q <= PROFILE_INVALID;
            operator_census_q <= 32'b0; profile_census_q <= 32'b0;
            error_code_q <= ERR_NONE; exp_error_code_q <= 4'b0;
            numeric_flags_q <= 5'b0; poisoned_q <= 1'b0; abort_hold_q <= 1'b0;
            stall_cycles_q <= 32'b0; drain_cycles_q <= 32'b0; abort_hold_cycles_q <= 32'b0;
            command_cycles_q <= 64'b0; active_cycles_q <= 64'b0;
            mask_pair_q <= 8'b0; src_pair_q <= 8'b0; element_index_q <= 8'b0;
            head_q <= 3'b0; lane_q <= 1'b0;
            source_value_q <= 32'b0; source_upper_q <= 32'b0; scaled_q <= 32'b0;
            delta_q <= 32'b0; max_q <= 32'hff800000; sum_q <= 32'b0;
            inverse_q <= 32'b0; output_lower_q <= 32'b0; output_upper_q <= 32'b0;
            request_addr_q <= 64'b0; request_wdata_q <= 64'b0;
            request_wstrb_q <= 8'b0; request_write_q <= 1'b0; request_kind_q <= REQ_MASK;
            gmem_outstanding_q <= 1'b0; addmul_resident_q <= 1'b0;
            exp_resident_q <= 1'b0; div_resident_q <= 1'b0;
            rows_completed_q <= 64'b0; source0_words_completed_q <= 64'b0;
            mask_words_completed_q <= 64'b0; outputs_computed_q <= 64'b0;
            outputs_completed_q <= 64'b0; max_comparisons_q <= 64'b0;
            gmem_read_requests_q <= 64'b0; gmem_read_responses_q <= 64'b0;
            read_payload_bytes_q <= 64'b0; gmem_write_requests_q <= 64'b0;
            gmem_write_responses_q <= 64'b0; write_payload_bytes_q <= 64'b0;
            scale_requests_q <= 64'b0; scale_responses_q <= 64'b0;
            mask_add_requests_q <= 64'b0; mask_add_responses_q <= 64'b0;
            subtract_requests_q <= 64'b0; subtract_responses_q <= 64'b0;
            exp_requests_q <= 64'b0; exp_responses_q <= 64'b0; exp_active_cycles_q <= 64'b0;
            sum_add_requests_q <= 64'b0; sum_add_responses_q <= 64'b0;
            div_requests_q <= 64'b0; div_responses_q <= 64'b0;
            normalize_mul_requests_q <= 64'b0; normalize_mul_responses_q <= 64'b0;
        end else begin
            if (state_q != ST_IDLE)
                active_cycles_q <= active_cycles_q + 64'd1;
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR) && (state_q != ST_GMEM_DRAIN)
                    && (state_q != ST_CORE_RESET))
                command_cycles_q <= command_cycles_q + 64'd1;

            if (phase_fire_w)
                stall_cycles_q <= 32'b0;
            else if (stall_state_w && (stall_cycles_q != 32'hffff_ffff))
                stall_cycles_q <= stall_cycles_q + 32'd1;
            else if (!stall_state_w)
                stall_cycles_q <= 32'b0;
            if (state_q == ST_GMEM_DRAIN) begin
                if (gmem_rsp_fire_w)
                    drain_cycles_q <= 32'b0;
                else if (drain_cycles_q != 32'hffff_ffff)
                    drain_cycles_q <= drain_cycles_q + 32'd1;
            end else
                drain_cycles_q <= 32'b0;
            if (abort_hold_q && !gmem_req_fire_w) begin
                if (abort_hold_cycles_q != 32'hffff_ffff)
                    abort_hold_cycles_q <= abort_hold_cycles_q + 32'd1;
            end else
                abort_hold_cycles_q <= 32'b0;

            if (gmem_req_fire_w) begin
                gmem_outstanding_q <= 1'b1;
                if (request_write_q)
                    gmem_write_requests_q <= gmem_write_requests_q + 64'd1;
                else
                    gmem_read_requests_q <= gmem_read_requests_q + 64'd1;
            end
            if (gmem_rsp_fire_w && gmem_outstanding_q) begin
                gmem_outstanding_q <= 1'b0;
                if (request_kind_q == REQ_WRITE) begin
                    gmem_write_responses_q <= gmem_write_responses_q + 64'd1;
                    if (!gmem_rsp_error_i && (state_q == ST_WRITE_WAIT)) begin
                        write_payload_bytes_q <= write_payload_bytes_q + 64'd8;
                        outputs_completed_q <= outputs_completed_q + 64'd2;
                    end
                end else begin
                    gmem_read_responses_q <= gmem_read_responses_q + 64'd1;
                    if (!gmem_rsp_error_i
                            && ((state_q == ST_MASK_WAIT) || (state_q == ST_SRC_WAIT))) begin
                        read_payload_bytes_q <= read_payload_bytes_q + 64'd8;
                        if (request_kind_q == REQ_MASK)
                            mask_words_completed_q <= mask_words_completed_q + 64'd2;
                        else
                            source0_words_completed_q <= source0_words_completed_q + 64'd2;
                    end
                end
            end
            if (addmul_req_fire_w) begin
                addmul_resident_q <= 1'b1;
                case (state_q)
                    ST_SCALE_REQ: scale_requests_q <= scale_requests_q + 64'd1;
                    ST_MASKADD_REQ: mask_add_requests_q <= mask_add_requests_q + 64'd1;
                    ST_SUB_REQ: subtract_requests_q <= subtract_requests_q + 64'd1;
                    ST_SUM_REQ: sum_add_requests_q <= sum_add_requests_q + 64'd1;
                    default: normalize_mul_requests_q <= normalize_mul_requests_q + 64'd1;
                endcase
            end
            if (addmul_rsp_fire_w && addmul_resident_q) begin
                addmul_resident_q <= 1'b0;
                numeric_flags_q <= numeric_flags_q | addmul_flags_w;
                case (state_q)
                    ST_SCALE_WAIT: scale_responses_q <= scale_responses_q + 64'd1;
                    ST_MASKADD_WAIT: mask_add_responses_q <= mask_add_responses_q + 64'd1;
                    ST_SUB_WAIT: subtract_responses_q <= subtract_responses_q + 64'd1;
                    ST_SUM_WAIT: sum_add_responses_q <= sum_add_responses_q + 64'd1;
                    default: normalize_mul_responses_q <= normalize_mul_responses_q + 64'd1;
                endcase
            end
            if (exp_req_fire_w) begin
                exp_resident_q <= 1'b1;
                exp_requests_q <= exp_requests_q + 64'd1;
            end
            if (exp_rsp_fire_w && exp_resident_q) begin
                exp_resident_q <= 1'b0;
                exp_responses_q <= exp_responses_q + 64'd1;
                exp_active_cycles_q <= exp_active_cycles_q + {32'b0, exp_cycles_w};
                numeric_flags_q <= numeric_flags_q | exp_flags_w;
                exp_error_code_q <= exp_error_code_w;
            end
            if (div_req_fire_w) begin
                div_resident_q <= 1'b1;
                div_requests_q <= div_requests_q + 64'd1;
            end
            if (div_rsp_fire_w && div_resident_q) begin
                div_resident_q <= 1'b0;
                div_responses_q <= div_responses_q + 64'd1;
                numeric_flags_q <= numeric_flags_q | div_flags_w;
            end

            if (abort_hold_timeout_hit_w || drain_timeout_hit_w) begin
                poisoned_q <= 1'b1;
                if (error_code_q == ERR_NONE)
                    error_code_q <= ERR_PROTOCOL;
                state_q <= ST_ERROR;
            end else if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                         && (state_q != ST_ERROR) && gmem_rsp_valid_i
                         && !gmem_outstanding_q) begin
                poisoned_q <= 1'b1;
                error_code_q <= ERR_PROTOCOL;
                state_q <= ST_ERROR;
            end else if (command_timeout_hit_w) begin
                if (error_code_q == ERR_NONE)
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                if (request_state_w)
                    abort_hold_q <= 1'b1;
                else if (gmem_outstanding_q)
                    state_q <= ST_GMEM_DRAIN;
                else if (addmul_resident_q || exp_resident_q || div_resident_q
                         || addmul_req_state_w || (state_q == ST_EXP_REQ)
                         || (state_q == ST_DIV_REQ))
                    state_q <= ST_CORE_RESET;
                else
                    state_q <= ST_ERROR;
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        if (start_fire_w) begin
                            reduce_op_q <= reduce_op_i;
                            manifest_op_id_q <= manifest_op_id_i;
                            source_arity_q <= source_arity_i;
                            op_params_q <= op_params_i;
                            op_params_tail_zero_q <= op_params_tail_zero_i;
                            npu_required_q <= npu_required_i;
                            command_id_q <= command_id_i;
                            canonical_node_id_lo_q <= canonical_node_id_lo_i;
                            canonical_node_id_hi_q <= canonical_node_id_hi_i;
                            dst_shadow_private_q <= dst_shadow_private_i;
                            windows_generation_valid_q <= windows_generation_valid_i;
                            src0_dtype_q <= src0_dtype_i; src0_flags_q <= src0_flags_i;
                            src0_view_off_q <= src0_view_off_i;
                            src0_ne0_q <= src0_ne0_i; src0_ne1_q <= src0_ne1_i;
                            src0_ne2_q <= src0_ne2_i; src0_ne3_q <= src0_ne3_i;
                            src0_base_q <= src0_base_i; src0_nb0_q <= src0_nb0_i;
                            src0_nb1_q <= src0_nb1_i; src0_nb2_q <= src0_nb2_i;
                            src0_nb3_q <= src0_nb3_i;
                            src1_dtype_q <= src1_dtype_i; src1_flags_q <= src1_flags_i;
                            src1_view_off_q <= src1_view_off_i;
                            src1_ne0_q <= src1_ne0_i; src1_ne1_q <= src1_ne1_i;
                            src1_ne2_q <= src1_ne2_i; src1_ne3_q <= src1_ne3_i;
                            src1_base_q <= src1_base_i; src1_nb0_q <= src1_nb0_i;
                            src1_nb1_q <= src1_nb1_i; src1_nb2_q <= src1_nb2_i;
                            src1_nb3_q <= src1_nb3_i;
                            dst_dtype_q <= dst_dtype_i; dst_flags_q <= dst_flags_i;
                            dst_view_off_q <= dst_view_off_i;
                            dst_ne0_q <= dst_ne0_i; dst_ne1_q <= dst_ne1_i;
                            dst_ne2_q <= dst_ne2_i; dst_ne3_q <= dst_ne3_i;
                            dst_base_q <= dst_base_i; dst_nb0_q <= dst_nb0_i;
                            dst_nb1_q <= dst_nb1_i; dst_nb2_q <= dst_nb2_i;
                            dst_nb3_q <= dst_nb3_i;
                            src0_window_base_q <= src0_window_base_i;
                            src0_window_bytes_q <= src0_window_bytes_i;
                            src0_window_read_q <= src0_window_read_i;
                            src0_window_write_q <= src0_window_write_i;
                            src1_window_base_q <= src1_window_base_i;
                            src1_window_bytes_q <= src1_window_bytes_i;
                            src1_window_read_q <= src1_window_read_i;
                            src1_window_write_q <= src1_window_write_i;
                            dst_window_base_q <= dst_window_base_i;
                            dst_window_bytes_q <= dst_window_bytes_i;
                            dst_window_read_q <= dst_window_read_i;
                            dst_window_write_q <= dst_window_write_i;
                            profile_id_q <= PROFILE_INVALID;
                            operator_census_q <= 32'b0; profile_census_q <= 32'b0;
                            error_code_q <= ERR_NONE; exp_error_code_q <= 4'b0;
                            numeric_flags_q <= 5'b0; abort_hold_q <= 1'b0;
                            stall_cycles_q <= 32'b0; command_cycles_q <= 64'b0;
                            active_cycles_q <= 64'b0; mask_pair_q <= 8'b0;
                            src_pair_q <= 8'b0; element_index_q <= 8'b0;
                            head_q <= 3'b0; lane_q <= 1'b0;
                            max_q <= 32'hff800000; sum_q <= 32'b0;
                            gmem_outstanding_q <= 1'b0; addmul_resident_q <= 1'b0;
                            exp_resident_q <= 1'b0; div_resident_q <= 1'b0;
                            rows_completed_q <= 64'b0; source0_words_completed_q <= 64'b0;
                            mask_words_completed_q <= 64'b0; outputs_computed_q <= 64'b0;
                            outputs_completed_q <= 64'b0; max_comparisons_q <= 64'b0;
                            gmem_read_requests_q <= 64'b0; gmem_read_responses_q <= 64'b0;
                            read_payload_bytes_q <= 64'b0; gmem_write_requests_q <= 64'b0;
                            gmem_write_responses_q <= 64'b0; write_payload_bytes_q <= 64'b0;
                            scale_requests_q <= 64'b0; scale_responses_q <= 64'b0;
                            mask_add_requests_q <= 64'b0; mask_add_responses_q <= 64'b0;
                            subtract_requests_q <= 64'b0; subtract_responses_q <= 64'b0;
                            exp_requests_q <= 64'b0; exp_responses_q <= 64'b0;
                            exp_active_cycles_q <= 64'b0;
                            sum_add_requests_q <= 64'b0; sum_add_responses_q <= 64'b0;
                            div_requests_q <= 64'b0; div_responses_q <= 64'b0;
                            normalize_mul_requests_q <= 64'b0;
                            normalize_mul_responses_q <= 64'b0;
                            state_q <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q <= ST_ERROR;
                        end else begin
                            profile_id_q <= PROFILE_SOFT_MAX;
                            operator_census_q <= FROZEN_OPERATOR_CENSUS;
                            profile_census_q <= FROZEN_PROFILE_CENSUS;
                            mask_pair_q <= 8'b0;
                            state_q <= ST_MASK_PREP;
                        end
                    end

                    ST_MASK_PREP: begin
                        if (!runtime_mask_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_mask_addr_w[63:0];
                            request_wdata_q <= 64'b0;
                            request_wstrb_q <= 8'b0;
                            request_write_q <= 1'b0;
                            request_kind_q <= REQ_MASK;
                            state_q <= ST_MASK_REQ;
                        end
                    end
                    ST_MASK_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else
                                state_q <= ST_MASK_WAIT;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end
                    ST_MASK_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                mask_mem_q[{mask_pair_q[6:0],1'b0}] <= gmem_rsp_rdata_i[31:0];
                                mask_mem_q[{mask_pair_q[6:0],1'b1}] <= gmem_rsp_rdata_i[63:32];
                                if (mask_pair_q == 8'd127) begin
                                    head_q <= 3'b0; src_pair_q <= 8'b0;
                                    max_q <= 32'hff800000;
                                    state_q <= ST_SRC_PREP;
                                end else begin
                                    mask_pair_q <= mask_pair_q + 8'd1;
                                    state_q <= ST_MASK_PREP;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_SRC_PREP: begin
                        if (!runtime_src_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_src_addr_w[63:0];
                            request_wdata_q <= 64'b0;
                            request_wstrb_q <= 8'b0;
                            request_write_q <= 1'b0;
                            request_kind_q <= REQ_SRC0;
                            state_q <= ST_SRC_REQ;
                        end
                    end
                    ST_SRC_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else
                                state_q <= ST_SRC_WAIT;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end
                    ST_SRC_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                source_value_q <= gmem_rsp_rdata_i[31:0];
                                source_upper_q <= gmem_rsp_rdata_i[63:32];
                                element_index_q <= {src_pair_q[6:0],1'b0};
                                lane_q <= 1'b0;
                                state_q <= ST_SCALE_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_SCALE_REQ: begin
                        if (addmul_req_fire_w)
                            state_q <= ST_SCALE_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_SCALE_WAIT: begin
                        if (addmul_rsp_fire_w) begin
                            if (addmul_flags_w[4] || addmul_flags_w[3]
                                    || addmul_flags_w[2] || is_nan32(addmul_result_w)) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                scaled_q <= addmul_result_w;
                                state_q <= ST_MASKADD_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_MASKADD_REQ: begin
                        if (addmul_req_fire_w)
                            state_q <= ST_MASKADD_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_MASKADD_WAIT: begin
                        if (addmul_rsp_fire_w) begin
                            if (addmul_flags_w[4] || addmul_flags_w[3]
                                    || addmul_flags_w[2] || is_nan32(addmul_result_w)) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                score_mem_q[element_index_q] <= addmul_result_w;
                                max_comparisons_q <= max_comparisons_q + 64'd1;
                                if (fp32_gt(addmul_result_w, max_q))
                                    max_q <= addmul_result_w;
                                if (!lane_q) begin
                                    lane_q <= 1'b1;
                                    element_index_q <= element_index_q + 8'd1;
                                    source_value_q <= source_upper_q;
                                    state_q <= ST_SCALE_REQ;
                                end else if (src_pair_q == 8'd127) begin
                                    element_index_q <= 8'b0;
                                    sum_q <= 32'b0;
                                    state_q <= ST_SUB_REQ;
                                end else begin
                                    src_pair_q <= src_pair_q + 8'd1;
                                    state_q <= ST_SRC_PREP;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_SUB_REQ: begin
                        if (addmul_req_fire_w)
                            state_q <= ST_SUB_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_SUB_WAIT: begin
                        if (addmul_rsp_fire_w) begin
                            if (addmul_flags_w[4] || addmul_flags_w[3]
                                    || addmul_flags_w[2] || is_nan32(addmul_result_w)) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                delta_q <= addmul_result_w;
                                state_q <= ST_EXP_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_EXP_REQ: begin
                        if (exp_req_fire_w)
                            state_q <= ST_EXP_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_EXP_WAIT: begin
                        if (exp_rsp_fire_w) begin
                            if (exp_error_w || (exp_error_code_w != 4'b0)
                                    || exp_flags_w[4] || exp_flags_w[3]
                                    || is_nan32(exp_result_w) || is_inf32(exp_result_w)) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                exp_mem_q[element_index_q] <= exp_result_w;
                                state_q <= ST_SUM_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_SUM_REQ: begin
                        if (addmul_req_fire_w)
                            state_q <= ST_SUM_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_SUM_WAIT: begin
                        if (addmul_rsp_fire_w) begin
                            if (addmul_flags_w[4] || addmul_flags_w[3]
                                    || addmul_flags_w[2] || is_nan32(addmul_result_w)
                                    || is_inf32(addmul_result_w)) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                sum_q <= addmul_result_w;
                                if (element_index_q == 8'd255)
                                    state_q <= ST_DIV_REQ;
                                else begin
                                    element_index_q <= element_index_q + 8'd1;
                                    state_q <= ST_SUB_REQ;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_DIV_REQ: begin
                        if ((sum_q[30:0] == 31'b0) || is_nan32(sum_q)
                                || is_inf32(sum_q) || sum_q[31]) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end else if (div_req_fire_w)
                            state_q <= ST_DIV_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_DIV_WAIT: begin
                        if (div_rsp_fire_w) begin
                            if (div_flags_w[4] || div_flags_w[3] || div_flags_w[2]
                                    || is_nan32(div_result_w) || is_inf32(div_result_w)) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                inverse_q <= div_result_w;
                                element_index_q <= 8'b0;
                                src_pair_q <= 8'b0;
                                lane_q <= 1'b0;
                                state_q <= ST_NORM_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_NORM_REQ: begin
                        if (addmul_req_fire_w)
                            state_q <= ST_NORM_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_NORM_WAIT: begin
                        if (addmul_rsp_fire_w) begin
                            if (addmul_flags_w[4] || addmul_flags_w[3]
                                    || addmul_flags_w[2] || is_nan32(addmul_result_w)
                                    || is_inf32(addmul_result_w)) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                outputs_computed_q <= outputs_computed_q + 64'd1;
                                if (!lane_q) begin
                                    output_lower_q <= addmul_result_w;
                                    lane_q <= 1'b1;
                                    element_index_q <= element_index_q + 8'd1;
                                    state_q <= ST_NORM_REQ;
                                end else begin
                                    output_upper_q <= addmul_result_w;
                                    state_q <= ST_WRITE_PREP;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_WRITE_PREP: begin
                        if (!runtime_dst_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_dst_addr_w[63:0];
                            request_wdata_q <= {output_upper_q, output_lower_q};
                            request_wstrb_q <= 8'hff;
                            request_write_q <= 1'b1;
                            request_kind_q <= REQ_WRITE;
                            state_q <= ST_WRITE_REQ;
                        end
                    end
                    ST_WRITE_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else
                                state_q <= ST_WRITE_WAIT;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end
                    ST_WRITE_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else if (src_pair_q == 8'd127) begin
                                rows_completed_q <= rows_completed_q + 64'd1;
                                if (head_q == 3'd7)
                                    state_q <= ST_DONE;
                                else begin
                                    head_q <= head_q + 3'd1;
                                    src_pair_q <= 8'b0;
                                    max_q <= 32'hff800000;
                                    state_q <= ST_SRC_PREP;
                                end
                            end else begin
                                src_pair_q <= src_pair_q + 8'd1;
                                element_index_q <= element_index_q + 8'd1;
                                lane_q <= 1'b0;
                                state_q <= ST_NORM_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_GMEM_DRAIN: begin
                        if (gmem_rsp_fire_w)
                            state_q <= ST_ERROR;
                    end
                    ST_CORE_RESET: begin
                        addmul_resident_q <= 1'b0;
                        exp_resident_q <= 1'b0;
                        div_resident_q <= 1'b0;
                        state_q <= ST_ERROR;
                    end
                    ST_DONE: begin
                        error_code_q <= ERR_NONE;
                        state_q <= ST_IDLE;
                    end
                    ST_ERROR: state_q <= ST_IDLE;
                    default: begin
                        if (error_code_q == ERR_NONE)
                            error_code_q <= ERR_INTERNAL_STATE;
                        if (gmem_outstanding_q)
                            state_q <= ST_GMEM_DRAIN;
                        else if (addmul_resident_q || exp_resident_q || div_resident_q)
                            state_q <= ST_CORE_RESET;
                        else
                            state_q <= ST_ERROR;
                    end
                endcase
            end
        end
    end

endmodule

`default_nettype wire
