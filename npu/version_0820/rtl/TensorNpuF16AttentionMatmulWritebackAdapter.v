`timescale 1ns/1ps
`default_nettype none

// Transactional frozen-v5 F16 attention MUL_MAT implementation.
//
// The numerical schedule is the pinned AVX2/FMA ggml_vec_dot_f16 schedule for
// K=256: four vectors of eight FP32 lane accumulators, eight 32-element chunks,
// one fused FMADD per element, then the exact GGML_F32x8_REDUCE add tree.
// src1 F32 words are converted RNE to F16 once per head and expanded exactly
// back to F32 before any FMADD.  Only transaction-private writes are emitted;
// dst_commit_o is the sole eligibility signal for public publication.
module TensorNpuF16AttentionMatmulWritebackAdapter #(
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd512,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd16777216,
    parameter [31:0] DRAIN_TIMEOUT_CYCLES = 32'd1024,
    parameter [31:0] ABORT_HOLD_TIMEOUT_CYCLES = 32'd1024
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
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
    output wire [15:0]  completion_manifest_op_id_o,
    output wire [2:0]   completion_source_arity_o,
    output wire [7:0]   completion_profile_id_o,
    output wire [31:0]  completion_kernel_id_o,
    output wire [31:0]  completion_operator_census_o,
    output wire [31:0]  completion_profile_census_o,
    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,
    output wire [4:0]   numeric_flags_o,
    output wire [2:0]   conversion_flags_o,
    output wire         poisoned_o,

    output wire [63:0]  outputs_computed_o,
    output wire [63:0]  outputs_completed_o,
    output wire [63:0]  source0_half_words_completed_o,
    output wire [63:0]  source1_float_words_completed_o,
    output wire [63:0]  conversion_words_completed_o,
    output wire [63:0]  work_items_completed_o,
    output wire [63:0]  gmem_read_requests_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_requests_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  fma_requests_o,
    output wire [63:0]  fma_responses_o,
    output wire [63:0]  reduction_requests_o,
    output wire [63:0]  reduction_responses_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire         numeric_outstanding_o,
    output wire         gmem_drain_o
);

    localparam [31:0] KERNEL_F16_ATTENTION_MATMUL = 32'h514e0009;
    localparam [15:0] MANIFEST_MUL_MAT = 16'd29;
    localparam [7:0] DTYPE_F32 = 8'd0;
    localparam [7:0] DTYPE_F16 = 8'd1;
    localparam [7:0] PROFILE_KQ = 8'd0;
    localparam [7:0] PROFILE_KQV = 8'd1;
    localparam [7:0] PROFILE_INVALID = 8'hff;
    localparam [31:0] OPERATOR_CENSUS = 32'd12;
    localparam [31:0] PROFILE_CENSUS = 32'd6;

    localparam [4:0] ST_IDLE          = 5'd0;
    localparam [4:0] ST_PREFLIGHT     = 5'd1;
    localparam [4:0] ST_SRC1_PREP     = 5'd2;
    localparam [4:0] ST_SRC1_REQ      = 5'd3;
    localparam [4:0] ST_SRC1_WAIT     = 5'd4;
    localparam [4:0] ST_OUTPUT_INIT   = 5'd5;
    localparam [4:0] ST_SRC0_PREP     = 5'd6;
    localparam [4:0] ST_SRC0_REQ      = 5'd7;
    localparam [4:0] ST_SRC0_WAIT     = 5'd8;
    localparam [4:0] ST_FMA_REQ       = 5'd9;
    localparam [4:0] ST_FMA_WAIT      = 5'd10;
    localparam [4:0] ST_REDUCE_REQ    = 5'd11;
    localparam [4:0] ST_REDUCE_WAIT   = 5'd12;
    localparam [4:0] ST_WRITE_PREP    = 5'd13;
    localparam [4:0] ST_WRITE_REQ     = 5'd14;
    localparam [4:0] ST_WRITE_WAIT    = 5'd15;
    localparam [4:0] ST_GMEM_DRAIN    = 5'd16;
    localparam [4:0] ST_CORE_RESET    = 5'd17;
    localparam [4:0] ST_DONE          = 5'd18;
    localparam [4:0] ST_ERROR         = 5'd19;

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

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                        : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 64'd1) ? 64'd0
                                          : COMMAND_TIMEOUT_CYCLES - 64'd1;
    localparam [31:0] DRAIN_TIMEOUT_LAST =
        (DRAIN_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                        : DRAIN_TIMEOUT_CYCLES - 32'd1;
    localparam [31:0] ABORT_HOLD_TIMEOUT_LAST =
        (ABORT_HOLD_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                             : ABORT_HOLD_TIMEOUT_CYCLES
                                               - 32'd1;

    reg [4:0] state_q;
    reg [15:0] manifest_op_id_q;
    reg [2:0] source_arity_q;
    reg [127:0] op_params_q;
    reg op_params_tail_zero_q, npu_required_q;
    reg [63:0] command_id_q, canonical_node_id_lo_q;
    reg [63:0] canonical_node_id_hi_q;
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
    reg conversion_inexact_q, conversion_overflow_q;
    reg conversion_nonfinite_q;
    reg poisoned_q, abort_hold_q;
    reg [31:0] stall_cycles_q, drain_cycles_q, abort_hold_cycles_q;
    reg [63:0] command_cycles_q, active_cycles_q;

    reg [2:0] head_index_q;
    reg [7:0] output_row_q;
    reg [6:0] src1_beat_q;
    reg [2:0] chunk_q;
    reg [1:0] vector_group_q;
    reg src0_beat_q;
    reg [2:0] lane_q;
    reg [5:0] reduction_step_q;
    reg [31:0] src1_cache_q [0:255];
    reg [31:0] src0_group_q [0:7];
    reg [31:0] accumulator_q [0:31];
    reg [31:0] hadd_stage1_q [0:3];
    reg [31:0] hadd_stage2_q [0:3];
    reg [31:0] output_q;

    reg [63:0] request_addr_q, request_wdata_q;
    reg [7:0] request_wstrb_q;
    reg request_write_q;
    reg [1:0] request_kind_q;
    reg outstanding_q, fma_resident_q, add_resident_q;

    reg [63:0] outputs_computed_q, outputs_completed_q;
    reg [63:0] source0_half_words_completed_q;
    reg [63:0] source1_float_words_completed_q;
    reg [63:0] conversion_words_completed_q;
    reg [63:0] gmem_read_requests_q, gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_requests_q, gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;
    reg [63:0] fma_requests_q, fma_responses_q;
    reg [63:0] reduction_requests_q, reduction_responses_q;

    assign busy_o = !rst_i && (state_q != ST_IDLE);
    assign done_o = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign completion_valid_o = done_o || error_o;
    assign dst_commit_o = done_o;
    assign completion_command_id_o = completion_valid_o ? command_id_q
                                                         : 64'b0;
    assign completion_canonical_node_id_lo_o = completion_valid_o
                                                ? canonical_node_id_lo_q
                                                : 64'b0;
    assign completion_canonical_node_id_hi_o = completion_valid_o
                                                ? canonical_node_id_hi_q
                                                : 64'b0;
    assign completion_npu_required_o = completion_valid_o
                                        ? npu_required_q : 1'b0;
    assign completion_manifest_op_id_o = completion_valid_o
                                           ? manifest_op_id_q : 16'b0;
    assign completion_source_arity_o = completion_valid_o
                                         ? source_arity_q : 3'b0;
    assign completion_profile_id_o = completion_valid_o ? profile_id_q
                                                         : 8'b0;
    assign completion_kernel_id_o = completion_valid_o
                                      ? KERNEL_F16_ATTENTION_MATMUL : 32'b0;
    assign completion_operator_census_o = completion_valid_o
                                            ? operator_census_q : 32'b0;
    assign completion_profile_census_o = completion_valid_o
                                           ? profile_census_q : 32'b0;
    assign error_code_o = error_code_q;
    assign numeric_flags_o = numeric_flags_q;
    assign conversion_flags_o = {conversion_nonfinite_q,
                                 conversion_overflow_q,
                                 conversion_inexact_q};
    assign poisoned_o = !rst_i && poisoned_q;

    assign outputs_computed_o = outputs_computed_q;
    assign outputs_completed_o = outputs_completed_q;
    assign source0_half_words_completed_o =
        source0_half_words_completed_q;
    assign source1_float_words_completed_o =
        source1_float_words_completed_q;
    assign conversion_words_completed_o = conversion_words_completed_q;
    assign work_items_completed_o = fma_responses_q;
    assign gmem_read_requests_o = gmem_read_requests_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_requests_o = gmem_write_requests_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign fma_requests_o = fma_requests_q;
    assign fma_responses_o = fma_responses_q;
    assign reduction_requests_o = reduction_requests_q;
    assign reduction_responses_o = reduction_responses_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign numeric_outstanding_o = fma_resident_q || add_resident_q;
    assign gmem_drain_o = !rst_i && (state_q == ST_GMEM_DRAIN);

    wire fma_req_ready_w, fma_rsp_valid_w;
    wire [31:0] fma_result_w;
    wire [4:0] fma_flags_w;
    wire add_req_ready_w, add_rsp_valid_w;
    wire [31:0] add_result_w;
    wire [4:0] add_flags_w;
    wire core_rst_w;
    wire fma_req_valid_w, fma_rsp_ready_w;
    wire add_req_valid_w, add_rsp_ready_w;
    wire fma_req_fire_w, fma_rsp_fire_w;
    wire add_req_fire_w, add_rsp_fire_w;

    wire [8:0] fma_cache_index_w;
    wire [5:0] fma_accumulator_index_w;
    assign fma_cache_index_w = {chunk_q, 5'b0}
                             + {5'b0, vector_group_q, 3'b0}
                             + {6'b0, lane_q};
    assign fma_accumulator_index_w = {vector_group_q, 3'b0}
                                   + {3'b0, lane_q};
    assign fma_req_valid_w = !rst_i && (state_q == ST_FMA_REQ);
    assign fma_rsp_ready_w = !rst_i && (state_q == ST_FMA_WAIT)
                           && fma_resident_q;
    assign fma_req_fire_w = fma_req_valid_w && fma_req_ready_w;
    assign fma_rsp_fire_w = fma_rsp_valid_w && fma_rsp_ready_w;

    reg [31:0] reduction_lhs_w, reduction_rhs_w;
    reg [5:0] reduction_dest_w;
    always @(*) begin
        reduction_lhs_w = 32'b0;
        reduction_rhs_w = 32'b0;
        reduction_dest_w = 6'b0;
        if (reduction_step_q < 6'd8) begin
            reduction_lhs_w = accumulator_q[reduction_step_q];
            reduction_rhs_w = accumulator_q[reduction_step_q + 6'd16];
            reduction_dest_w = reduction_step_q;
        end else if (reduction_step_q < 6'd16) begin
            reduction_lhs_w = accumulator_q[reduction_step_q];
            reduction_rhs_w = accumulator_q[reduction_step_q + 6'd16];
            reduction_dest_w = reduction_step_q;
        end else if (reduction_step_q < 6'd24) begin
            reduction_lhs_w = accumulator_q[reduction_step_q - 6'd16];
            reduction_rhs_w = accumulator_q[reduction_step_q - 6'd8];
            reduction_dest_w = reduction_step_q - 6'd16;
        end else if (reduction_step_q < 6'd28) begin
            reduction_lhs_w = accumulator_q[reduction_step_q - 6'd24];
            reduction_rhs_w = accumulator_q[reduction_step_q - 6'd20];
            reduction_dest_w = reduction_step_q - 6'd24;
        end else if (reduction_step_q < 6'd32) begin
            if (!reduction_step_q[0]) begin
                reduction_lhs_w = accumulator_q[0];
                reduction_rhs_w = accumulator_q[1];
            end else begin
                reduction_lhs_w = accumulator_q[2];
                reduction_rhs_w = accumulator_q[3];
            end
            reduction_dest_w = reduction_step_q - 6'd28;
        end else begin
            if (!reduction_step_q[0]) begin
                reduction_lhs_w = hadd_stage1_q[0];
                reduction_rhs_w = hadd_stage1_q[1];
            end else begin
                reduction_lhs_w = hadd_stage1_q[2];
                reduction_rhs_w = hadd_stage1_q[3];
            end
            reduction_dest_w = reduction_step_q - 6'd32;
        end
    end

    assign add_req_valid_w = !rst_i && (state_q == ST_REDUCE_REQ);
    assign add_rsp_ready_w = !rst_i && (state_q == ST_REDUCE_WAIT)
                           && add_resident_q;
    assign add_req_fire_w = add_req_valid_w && add_req_ready_w;
    assign add_rsp_fire_w = add_rsp_valid_w && add_rsp_ready_w;
    assign core_rst_w = rst_i || (state_q == ST_CORE_RESET);

    TensorNpuFp32Fma u_fma (
        .clk_i(clk_i), .rst_i(core_rst_w),
        .req_valid_i(fma_req_valid_w), .req_ready_o(fma_req_ready_w),
        .multiplicand_a_bits_i(src0_group_q[lane_q]),
        .multiplicand_b_bits_i(src1_cache_q[fma_cache_index_w]),
        .addend_bits_i(accumulator_q[fma_accumulator_index_w]),
        .rsp_valid_o(fma_rsp_valid_w), .rsp_ready_i(fma_rsp_ready_w),
        .result_bits_o(fma_result_w), .flags_o(fma_flags_w)
    );

    TensorNpuFp32AddMul u_reduction_add (
        .clk_i(clk_i), .rst_i(core_rst_w),
        .req_valid_i(add_req_valid_w), .req_ready_o(add_req_ready_w),
        .op_mul_i(1'b0),
        .lhs_bits_i(reduction_lhs_w), .rhs_bits_i(reduction_rhs_w),
        .rsp_valid_o(add_rsp_valid_w), .rsp_ready_i(add_rsp_ready_w),
        .result_bits_o(add_result_w), .flags_o(add_flags_w)
    );

    wire [15:0] src1_half_low_w, src1_half_high_w;
    wire src1_low_finite_w, src1_low_overflow_w, src1_low_inexact_w;
    wire src1_high_finite_w, src1_high_overflow_w, src1_high_inexact_w;
    wire [31:0] src1_expanded_low_w, src1_expanded_high_w;
    wire unused_src1_expand_low_finite_w, unused_src1_expand_low_zero_w;
    wire unused_src1_expand_high_finite_w, unused_src1_expand_high_zero_w;
    TensorNpuFp32ToFp16 u_src1_low_to_half (
        .fp32_bits_i(gmem_rsp_rdata_i[31:0]),
        .fp16_bits_o(src1_half_low_w), .finite_o(src1_low_finite_w),
        .overflow_o(src1_low_overflow_w), .inexact_o(src1_low_inexact_w)
    );
    TensorNpuFp32ToFp16 u_src1_high_to_half (
        .fp32_bits_i(gmem_rsp_rdata_i[63:32]),
        .fp16_bits_o(src1_half_high_w), .finite_o(src1_high_finite_w),
        .overflow_o(src1_high_overflow_w), .inexact_o(src1_high_inexact_w)
    );
    TensorNpuFp16ToFp32 u_src1_low_expand (
        .fp16_bits_i(src1_half_low_w), .fp32_bits_o(src1_expanded_low_w),
        .finite_o(unused_src1_expand_low_finite_w),
        .zero_o(unused_src1_expand_low_zero_w)
    );
    TensorNpuFp16ToFp32 u_src1_high_expand (
        .fp16_bits_i(src1_half_high_w), .fp32_bits_o(src1_expanded_high_w),
        .finite_o(unused_src1_expand_high_finite_w),
        .zero_o(unused_src1_expand_high_zero_w)
    );

    wire [31:0] src0_expanded_w [0:3];
    wire src0_expand_finite_w [0:3];
    wire src0_expand_zero_w [0:3];
    genvar expand_lane;
    generate
        for (expand_lane = 0; expand_lane < 4;
                expand_lane = expand_lane + 1) begin : g_src0_expand
            TensorNpuFp16ToFp32 u_expand (
                .fp16_bits_i(gmem_rsp_rdata_i[(expand_lane * 16) +: 16]),
                .fp32_bits_o(src0_expanded_w[expand_lane]),
                .finite_o(src0_expand_finite_w[expand_lane]),
                .zero_o(src0_expand_zero_w[expand_lane])
            );
        end
    endgenerate

    wire start_fire_w;
    wire gmem_request_state_w, gmem_response_state_w;
    wire gmem_req_fire_w, gmem_rsp_fire_w;
    wire phase_fire_w, stall_state_w;
    wire stall_timeout_hit_w, command_timeout_hit_w;
    wire drain_timeout_hit_w, abort_hold_timeout_hit_w;
    assign ready_o = !rst_i && (state_q == ST_IDLE)
                   && fma_req_ready_w && add_req_ready_w && !poisoned_q
                   && !gmem_rsp_valid_i;
    assign start_fire_w = start_i && ready_o;
    assign gmem_request_state_w = (state_q == ST_SRC1_REQ)
                                || (state_q == ST_SRC0_REQ)
                                || (state_q == ST_WRITE_REQ);
    assign gmem_response_state_w = (state_q == ST_SRC1_WAIT)
                                 || (state_q == ST_SRC0_WAIT)
                                 || (state_q == ST_WRITE_WAIT)
                                 || (state_q == ST_GMEM_DRAIN);
    assign gmem_req_valid_o = !rst_i && gmem_request_state_w;
    assign gmem_req_write_o = request_write_q;
    assign gmem_req_addr_o = request_addr_q;
    assign gmem_req_wdata_o = request_wdata_q;
    assign gmem_req_wstrb_o = request_wstrb_q;
    assign gmem_rsp_ready_o = !rst_i && gmem_response_state_w
                            && outstanding_q;
    assign gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;
    assign phase_fire_w = gmem_req_fire_w || gmem_rsp_fire_w
                        || fma_req_fire_w || fma_rsp_fire_w
                        || add_req_fire_w || add_rsp_fire_w;
    assign stall_state_w = gmem_request_state_w
                         || (state_q == ST_SRC1_WAIT)
                         || (state_q == ST_SRC0_WAIT)
                         || (state_q == ST_WRITE_WAIT)
                         || (state_q == ST_FMA_REQ)
                         || (state_q == ST_FMA_WAIT)
                         || (state_q == ST_REDUCE_REQ)
                         || (state_q == ST_REDUCE_WAIT);
    assign stall_timeout_hit_w = stall_state_w
                               && (stall_cycles_q >= STALL_TIMEOUT_LAST)
                               && !phase_fire_w;
    assign command_timeout_hit_w = (state_q != ST_IDLE)
                                 && (state_q != ST_DONE)
                                 && (state_q != ST_ERROR)
                                 && (state_q != ST_GMEM_DRAIN)
                                 && (state_q != ST_CORE_RESET)
                                 && (command_cycles_q
                                     >= COMMAND_TIMEOUT_LAST)
                                 && !phase_fire_w;
    assign drain_timeout_hit_w = (state_q == ST_GMEM_DRAIN)
                               && (drain_cycles_q >= DRAIN_TIMEOUT_LAST)
                               && !gmem_rsp_fire_w;
    assign abort_hold_timeout_hit_w = abort_hold_q
                                    && !gmem_req_fire_w
                                    && (abort_hold_cycles_q
                                        >= ABORT_HOLD_TIMEOUT_LAST);

    // Exact descriptor and capability admission with 128-bit intermediates.
    reg common_descriptor_ok_w, profile_kq_w, profile_kqv_w;
    reg src0_window_ok_w, src1_window_ok_w, dst_window_ok_w, alias_ok_w;
    reg [4:0] preflight_error_w;
    reg [127:0] src0_last_w, src1_last_w, dst_last_w;
    reg [127:0] src0_end_w, src1_end_w, dst_end_w;
    reg [127:0] src0_window_end_w, src1_window_end_w, dst_window_end_w;
    reg [127:0] src0_phys_start_w, src0_phys_end_w;
    reg [127:0] src1_phys_start_w, src1_phys_end_w;
    reg [127:0] dst_phys_start_w, dst_phys_end_w, align_tmp_w;
    always @(*) begin
        src0_last_w = ({96'b0, (src0_ne0_q - 32'd1)}
                       * {64'b0, src0_nb0_q})
                    + ({96'b0, (src0_ne1_q - 32'd1)}
                       * {64'b0, src0_nb1_q})
                    + ({96'b0, (src0_ne2_q - 32'd1)}
                       * {64'b0, src0_nb2_q})
                    + ({96'b0, (src0_ne3_q - 32'd1)}
                       * {64'b0, src0_nb3_q});
        src1_last_w = ({96'b0, (src1_ne0_q - 32'd1)}
                       * {64'b0, src1_nb0_q})
                    + ({96'b0, (src1_ne1_q - 32'd1)}
                       * {64'b0, src1_nb1_q})
                    + ({96'b0, (src1_ne2_q - 32'd1)}
                       * {64'b0, src1_nb2_q})
                    + ({96'b0, (src1_ne3_q - 32'd1)}
                       * {64'b0, src1_nb3_q});
        dst_last_w = ({96'b0, (dst_ne0_q - 32'd1)}
                      * {64'b0, dst_nb0_q})
                   + ({96'b0, (dst_ne1_q - 32'd1)}
                      * {64'b0, dst_nb1_q})
                   + ({96'b0, (dst_ne2_q - 32'd1)}
                      * {64'b0, dst_nb2_q})
                   + ({96'b0, (dst_ne3_q - 32'd1)}
                      * {64'b0, dst_nb3_q});
        src0_end_w = {64'b0, src0_base_q} + src0_last_w + 128'd2;
        src1_end_w = {64'b0, src1_base_q} + src1_last_w + 128'd4;
        dst_end_w = {64'b0, dst_base_q} + dst_last_w + 128'd4;
        src0_window_end_w = {64'b0, src0_window_base_q}
                          + {64'b0, src0_window_bytes_q};
        src1_window_end_w = {64'b0, src1_window_base_q}
                          + {64'b0, src1_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};

        src0_phys_start_w = {64'b0, src0_base_q};
        src0_phys_start_w[2:0] = 3'b000;
        align_tmp_w = src0_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b000;
        src0_phys_end_w = align_tmp_w;
        src1_phys_start_w = {64'b0, src1_base_q};
        src1_phys_start_w[2:0] = 3'b000;
        align_tmp_w = src1_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b000;
        src1_phys_end_w = align_tmp_w;
        dst_phys_start_w = {64'b0, dst_base_q};
        dst_phys_start_w[2:0] = 3'b000;
        align_tmp_w = dst_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b000;
        dst_phys_end_w = align_tmp_w;

        common_descriptor_ok_w = (manifest_op_id_q == MANIFEST_MUL_MAT)
                               && (source_arity_q == 3'd2)
                               && op_params_tail_zero_q && npu_required_q
                               && dst_shadow_private_q
                               && windows_generation_valid_q
                               && ((canonical_node_id_lo_q != 64'b0)
                                   || (canonical_node_id_hi_q != 64'b0))
                               && (src0_dtype_q == DTYPE_F16)
                               && (src0_flags_q == 32'd16)
                               && (src0_view_off_q == 64'b0)
                               && (src0_ne0_q == 32'd256)
                               && (src0_ne1_q == 32'd256)
                               && (src0_ne2_q == 32'd2)
                               && (src0_ne3_q == 32'd1)
                               && (src0_nb0_q == 64'd2)
                               && (src0_nb3_q == 64'd262144)
                               && (src1_dtype_q == DTYPE_F32)
                               && (src1_flags_q == 32'd16)
                               && (src1_view_off_q == 64'b0)
                               && (src1_ne0_q == 32'd256)
                               && (src1_ne1_q == 32'd1)
                               && (src1_ne2_q == 32'd8)
                               && (src1_ne3_q == 32'd1)
                               && (src1_nb0_q == 64'd4)
                               && (src1_nb3_q == 64'd8192)
                               && (dst_dtype_q == DTYPE_F32)
                               && (dst_flags_q == 32'd16)
                               && (dst_view_off_q == 64'b0)
                               && (dst_ne0_q == 32'd256)
                               && (dst_ne1_q == 32'd1)
                               && (dst_ne2_q == 32'd8)
                               && (dst_ne3_q == 32'd1)
                               && (dst_nb0_q == 64'd4)
                               && (dst_nb1_q == 64'd1024)
                               && (dst_nb2_q == 64'd1024)
                               && (dst_nb3_q == 64'd8192);
        profile_kq_w = common_descriptor_ok_w
                     && (op_params_q == 128'd10)
                     && (src0_nb1_q == 64'd1024)
                     && (src0_nb2_q == 64'd512)
                     && (src1_nb1_q == 64'd8192)
                     && (src1_nb2_q == 64'd1024);
        profile_kqv_w = common_descriptor_ok_w
                      && (op_params_q == 128'b0)
                      && (src0_nb1_q == 64'd512)
                      && (src0_nb2_q == 64'd131072)
                      && (src1_nb1_q == 64'd1024)
                      && (src1_nb2_q == 64'd1024);

        src0_window_ok_w = (src0_window_end_w[127:64] == 64'b0)
                         && (src0_end_w[127:64] == 64'b0)
                         && (src0_phys_end_w[127:64] == 64'b0)
                         && (src0_base_q[2:0] == 3'b000)
                         && (src0_window_base_q[2:0] == 3'b000)
                         && (src0_window_bytes_q[2:0] == 3'b000)
                         && src0_window_read_q && !src0_window_write_q
                         && (src0_window_bytes_q != 64'b0)
                         && (src0_phys_start_w
                             >= {64'b0, src0_window_base_q})
                         && (src0_phys_end_w <= src0_window_end_w);
        src1_window_ok_w = (src1_window_end_w[127:64] == 64'b0)
                         && (src1_end_w[127:64] == 64'b0)
                         && (src1_phys_end_w[127:64] == 64'b0)
                         && (src1_base_q[2:0] == 3'b000)
                         && (src1_window_base_q[2:0] == 3'b000)
                         && (src1_window_bytes_q[2:0] == 3'b000)
                         && src1_window_read_q && !src1_window_write_q
                         && (src1_window_bytes_q != 64'b0)
                         && (src1_phys_start_w
                             >= {64'b0, src1_window_base_q})
                         && (src1_phys_end_w <= src1_window_end_w);
        dst_window_ok_w = (dst_window_end_w[127:64] == 64'b0)
                        && (dst_end_w[127:64] == 64'b0)
                        && (dst_phys_end_w[127:64] == 64'b0)
                        && (dst_base_q[1:0] == 2'b00)
                        && (dst_window_base_q[2:0] == 3'b000)
                        && (dst_window_bytes_q[2:0] == 3'b000)
                        && !dst_window_read_q && dst_window_write_q
                        && (dst_window_bytes_q != 64'b0)
                        && (dst_phys_start_w >= {64'b0, dst_window_base_q})
                        && (dst_phys_end_w <= dst_window_end_w);
        alias_ok_w = ((src0_phys_end_w <= src1_phys_start_w)
                      || (src1_phys_end_w <= src0_phys_start_w))
                  && ((src0_phys_end_w <= dst_phys_start_w)
                      || (dst_phys_end_w <= src0_phys_start_w))
                  && ((src1_phys_end_w <= dst_phys_start_w)
                      || (dst_phys_end_w <= src1_phys_start_w));

        if (!profile_kq_w && !profile_kqv_w)
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

    reg [127:0] runtime_src1_addr_w, runtime_src1_end_w;
    reg runtime_src1_ok_w;
    reg [127:0] runtime_src0_addr_w, runtime_src0_end_w;
    reg runtime_src0_ok_w;
    reg [127:0] runtime_write_addr_w, runtime_write_end_w;
    reg [127:0] runtime_write_phys_start_w, runtime_write_phys_end_w;
    reg [127:0] runtime_align_w;
    reg runtime_write_ok_w;
    always @(*) begin
        runtime_src1_addr_w = {64'b0, src1_base_q}
                            + ({125'b0, head_index_q}
                               * {64'b0, src1_nb2_q})
                            + ({121'b0, src1_beat_q} * 128'd8);
        runtime_src1_end_w = runtime_src1_addr_w + 128'd8;
        runtime_src1_ok_w = ({1'b0, head_index_q} < 4'd8)
                          && ({1'b0, src1_beat_q} < 8'd128)
                          && (runtime_src1_addr_w[127:64] == 64'b0)
                          && (runtime_src1_addr_w[2:0] == 3'b000)
                          && (runtime_src1_addr_w
                              >= {64'b0, src1_window_base_q})
                          && (runtime_src1_end_w <= src1_window_end_w);

        runtime_src0_addr_w = {64'b0, src0_base_q}
                            + ({120'b0, output_row_q}
                               * {64'b0, src0_nb1_q})
                            + ({127'b0, head_index_q[2]}
                               * {64'b0, src0_nb2_q})
                            + ({125'b0, chunk_q} * 128'd64)
                            + ({126'b0, vector_group_q} * 128'd16)
                            + (src0_beat_q ? 128'd8 : 128'd0);
        runtime_src0_end_w = runtime_src0_addr_w + 128'd8;
        runtime_src0_ok_w = ({1'b0, head_index_q} < 4'd8)
                          && ({1'b0, chunk_q} < 4'd8)
                          && ({1'b0, vector_group_q} < 3'd4)
                          && (runtime_src0_addr_w[127:64] == 64'b0)
                          && (runtime_src0_addr_w[2:0] == 3'b000)
                          && (runtime_src0_addr_w
                              >= {64'b0, src0_window_base_q})
                          && (runtime_src0_end_w <= src0_window_end_w);

        runtime_write_addr_w = {64'b0, dst_base_q}
                             + ({125'b0, head_index_q}
                                * {64'b0, dst_nb2_q})
                             + ({120'b0, output_row_q} * 128'd4);
        runtime_write_end_w = runtime_write_addr_w + 128'd4;
        runtime_write_phys_start_w = runtime_write_addr_w;
        runtime_write_phys_start_w[2:0] = 3'b000;
        runtime_align_w = runtime_write_end_w + 128'd7;
        runtime_align_w[2:0] = 3'b000;
        runtime_write_phys_end_w = runtime_align_w;
        runtime_write_ok_w = ({1'b0, head_index_q} < 4'd8)
                           && (runtime_write_addr_w[127:64] == 64'b0)
                           && (runtime_write_addr_w[1:0] == 2'b00)
                           && (runtime_write_phys_start_w
                               >= {64'b0, dst_window_base_q})
                           && (runtime_write_phys_end_w <= dst_window_end_w);
    end

    integer reset_index;
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
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
            src0_dtype_q <= 8'b0;
            src1_dtype_q <= 8'b0;
            dst_dtype_q <= 8'b0;
            src0_flags_q <= 32'b0;
            src1_flags_q <= 32'b0;
            dst_flags_q <= 32'b0;
            src0_view_off_q <= 64'b0;
            src1_view_off_q <= 64'b0;
            dst_view_off_q <= 64'b0;
            src0_ne0_q <= 32'b0;
            src0_ne1_q <= 32'b0;
            src0_ne2_q <= 32'b0;
            src0_ne3_q <= 32'b0;
            src1_ne0_q <= 32'b0;
            src1_ne1_q <= 32'b0;
            src1_ne2_q <= 32'b0;
            src1_ne3_q <= 32'b0;
            dst_ne0_q <= 32'b0;
            dst_ne1_q <= 32'b0;
            dst_ne2_q <= 32'b0;
            dst_ne3_q <= 32'b0;
            src0_base_q <= 64'b0;
            src1_base_q <= 64'b0;
            dst_base_q <= 64'b0;
            src0_nb0_q <= 64'b0;
            src0_nb1_q <= 64'b0;
            src0_nb2_q <= 64'b0;
            src0_nb3_q <= 64'b0;
            src1_nb0_q <= 64'b0;
            src1_nb1_q <= 64'b0;
            src1_nb2_q <= 64'b0;
            src1_nb3_q <= 64'b0;
            dst_nb0_q <= 64'b0;
            dst_nb1_q <= 64'b0;
            dst_nb2_q <= 64'b0;
            dst_nb3_q <= 64'b0;
            src0_window_base_q <= 64'b0;
            src0_window_bytes_q <= 64'b0;
            src0_window_read_q <= 1'b0;
            src0_window_write_q <= 1'b0;
            src1_window_base_q <= 64'b0;
            src1_window_bytes_q <= 64'b0;
            src1_window_read_q <= 1'b0;
            src1_window_write_q <= 1'b0;
            dst_window_base_q <= 64'b0;
            dst_window_bytes_q <= 64'b0;
            dst_window_read_q <= 1'b0;
            dst_window_write_q <= 1'b0;
            profile_id_q <= PROFILE_INVALID;
            operator_census_q <= 32'b0;
            profile_census_q <= 32'b0;
            error_code_q <= ERR_NONE;
            numeric_flags_q <= 5'b0;
            conversion_inexact_q <= 1'b0;
            conversion_overflow_q <= 1'b0;
            conversion_nonfinite_q <= 1'b0;
            poisoned_q <= 1'b0;
            abort_hold_q <= 1'b0;
            stall_cycles_q <= 32'b0;
            drain_cycles_q <= 32'b0;
            abort_hold_cycles_q <= 32'b0;
            command_cycles_q <= 64'b0;
            active_cycles_q <= 64'b0;
            head_index_q <= 3'b0;
            output_row_q <= 8'b0;
            src1_beat_q <= 7'b0;
            chunk_q <= 3'b0;
            vector_group_q <= 2'b0;
            src0_beat_q <= 1'b0;
            lane_q <= 3'b0;
            reduction_step_q <= 6'b0;
            output_q <= 32'b0;
            request_addr_q <= 64'b0;
            request_wdata_q <= 64'b0;
            request_wstrb_q <= 8'b0;
            request_write_q <= 1'b0;
            request_kind_q <= 2'b0;
            outstanding_q <= 1'b0;
            fma_resident_q <= 1'b0;
            add_resident_q <= 1'b0;
            outputs_computed_q <= 64'b0;
            outputs_completed_q <= 64'b0;
            source0_half_words_completed_q <= 64'b0;
            source1_float_words_completed_q <= 64'b0;
            conversion_words_completed_q <= 64'b0;
            gmem_read_requests_q <= 64'b0;
            gmem_read_responses_q <= 64'b0;
            read_payload_bytes_q <= 64'b0;
            gmem_write_requests_q <= 64'b0;
            gmem_write_responses_q <= 64'b0;
            write_payload_bytes_q <= 64'b0;
            fma_requests_q <= 64'b0;
            fma_responses_q <= 64'b0;
            reduction_requests_q <= 64'b0;
            reduction_responses_q <= 64'b0;
            // src1_cache_q is deliberately not reset: every one of its 256
            // entries is overwritten by the per-head preload before use.
            for (reset_index = 0; reset_index < 8;
                    reset_index = reset_index + 1)
                src0_group_q[reset_index] <= 32'b0;
            for (reset_index = 0; reset_index < 32;
                    reset_index = reset_index + 1)
                accumulator_q[reset_index] <= 32'b0;
            for (reset_index = 0; reset_index < 4;
                    reset_index = reset_index + 1) begin
                hadd_stage1_q[reset_index] <= 32'b0;
                hadd_stage2_q[reset_index] <= 32'b0;
            end
        end else begin
            if (state_q != ST_IDLE)
                active_cycles_q <= active_cycles_q + 64'd1;
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)
                    && (state_q != ST_GMEM_DRAIN))
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
            end else begin
                drain_cycles_q <= 32'b0;
            end
            if (abort_hold_q && !gmem_req_fire_w) begin
                if (abort_hold_cycles_q != 32'hffff_ffff)
                    abort_hold_cycles_q <= abort_hold_cycles_q + 32'd1;
            end else begin
                abort_hold_cycles_q <= 32'b0;
            end
            if (abort_hold_timeout_hit_w || drain_timeout_hit_w)
                poisoned_q <= 1'b1;

            if (gmem_req_fire_w) begin
                outstanding_q <= 1'b1;
                if (request_write_q)
                    gmem_write_requests_q <= gmem_write_requests_q + 64'd1;
                else
                    gmem_read_requests_q <= gmem_read_requests_q + 64'd1;
            end
            if (gmem_rsp_fire_w && outstanding_q) begin
                outstanding_q <= 1'b0;
                if (request_kind_q == 2'd2) begin
                    gmem_write_responses_q <= gmem_write_responses_q + 64'd1;
                    if (!gmem_rsp_error_i && (state_q == ST_WRITE_WAIT)) begin
                        write_payload_bytes_q <= write_payload_bytes_q + 64'd4;
                        outputs_completed_q <= outputs_completed_q + 64'd1;
                    end
                end else begin
                    gmem_read_responses_q <= gmem_read_responses_q + 64'd1;
                    if (!gmem_rsp_error_i
                            && ((state_q == ST_SRC0_WAIT)
                                || (state_q == ST_SRC1_WAIT))) begin
                        read_payload_bytes_q <= read_payload_bytes_q + 64'd8;
                        if (request_kind_q == 2'd0) begin
                            source0_half_words_completed_q
                                <= source0_half_words_completed_q + 64'd4;
                        end else begin
                            source1_float_words_completed_q
                                <= source1_float_words_completed_q + 64'd2;
                            conversion_words_completed_q
                                <= conversion_words_completed_q + 64'd2;
                        end
                    end
                end
            end
            if (fma_req_fire_w) begin
                fma_resident_q <= 1'b1;
                fma_requests_q <= fma_requests_q + 64'd1;
            end
            if (fma_rsp_fire_w && fma_resident_q) begin
                fma_resident_q <= 1'b0;
                fma_responses_q <= fma_responses_q + 64'd1;
                numeric_flags_q <= numeric_flags_q | fma_flags_w;
            end
            if (add_req_fire_w) begin
                add_resident_q <= 1'b1;
                reduction_requests_q <= reduction_requests_q + 64'd1;
            end
            if (add_rsp_fire_w && add_resident_q) begin
                add_resident_q <= 1'b0;
                reduction_responses_q <= reduction_responses_q + 64'd1;
                numeric_flags_q <= numeric_flags_q | add_flags_w;
            end

            if (command_timeout_hit_w) begin
                if (error_code_q == ERR_NONE)
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                if (gmem_request_state_w) begin
                    abort_hold_q <= 1'b1;
                end else if (outstanding_q) begin
                    state_q <= ST_GMEM_DRAIN;
                end else if (fma_resident_q || add_resident_q
                        || (state_q == ST_FMA_REQ)
                        || (state_q == ST_REDUCE_REQ)) begin
                    state_q <= ST_CORE_RESET;
                end else begin
                    state_q <= ST_ERROR;
                end
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        if (start_fire_w) begin
                            manifest_op_id_q <= manifest_op_id_i;
                            source_arity_q <= source_arity_i;
                            op_params_q <= op_params_i;
                            op_params_tail_zero_q <= op_params_tail_zero_i;
                            npu_required_q <= npu_required_i;
                            command_id_q <= command_id_i;
                            canonical_node_id_lo_q
                                <= canonical_node_id_lo_i;
                            canonical_node_id_hi_q
                                <= canonical_node_id_hi_i;
                            dst_shadow_private_q <= dst_shadow_private_i;
                            windows_generation_valid_q
                                <= windows_generation_valid_i;
                            src0_dtype_q <= src0_dtype_i;
                            src0_flags_q <= src0_flags_i;
                            src0_view_off_q <= src0_view_off_i;
                            src0_ne0_q <= src0_ne0_i;
                            src0_ne1_q <= src0_ne1_i;
                            src0_ne2_q <= src0_ne2_i;
                            src0_ne3_q <= src0_ne3_i;
                            src0_base_q <= src0_base_i;
                            src0_nb0_q <= src0_nb0_i;
                            src0_nb1_q <= src0_nb1_i;
                            src0_nb2_q <= src0_nb2_i;
                            src0_nb3_q <= src0_nb3_i;
                            src1_dtype_q <= src1_dtype_i;
                            src1_flags_q <= src1_flags_i;
                            src1_view_off_q <= src1_view_off_i;
                            src1_ne0_q <= src1_ne0_i;
                            src1_ne1_q <= src1_ne1_i;
                            src1_ne2_q <= src1_ne2_i;
                            src1_ne3_q <= src1_ne3_i;
                            src1_base_q <= src1_base_i;
                            src1_nb0_q <= src1_nb0_i;
                            src1_nb1_q <= src1_nb1_i;
                            src1_nb2_q <= src1_nb2_i;
                            src1_nb3_q <= src1_nb3_i;
                            dst_dtype_q <= dst_dtype_i;
                            dst_flags_q <= dst_flags_i;
                            dst_view_off_q <= dst_view_off_i;
                            dst_ne0_q <= dst_ne0_i;
                            dst_ne1_q <= dst_ne1_i;
                            dst_ne2_q <= dst_ne2_i;
                            dst_ne3_q <= dst_ne3_i;
                            dst_base_q <= dst_base_i;
                            dst_nb0_q <= dst_nb0_i;
                            dst_nb1_q <= dst_nb1_i;
                            dst_nb2_q <= dst_nb2_i;
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
                            operator_census_q <= 32'b0;
                            profile_census_q <= 32'b0;
                            error_code_q <= ERR_NONE;
                            numeric_flags_q <= 5'b0;
                            conversion_inexact_q <= 1'b0;
                            conversion_overflow_q <= 1'b0;
                            conversion_nonfinite_q <= 1'b0;
                            abort_hold_q <= 1'b0;
                            stall_cycles_q <= 32'b0;
                            command_cycles_q <= 64'b0;
                            active_cycles_q <= 64'b0;
                            head_index_q <= 3'b0;
                            output_row_q <= 8'b0;
                            src1_beat_q <= 7'b0;
                            chunk_q <= 3'b0;
                            vector_group_q <= 2'b0;
                            src0_beat_q <= 1'b0;
                            lane_q <= 3'b0;
                            reduction_step_q <= 6'b0;
                            output_q <= 32'b0;
                            outstanding_q <= 1'b0;
                            fma_resident_q <= 1'b0;
                            add_resident_q <= 1'b0;
                            outputs_computed_q <= 64'b0;
                            outputs_completed_q <= 64'b0;
                            source0_half_words_completed_q <= 64'b0;
                            source1_float_words_completed_q <= 64'b0;
                            conversion_words_completed_q <= 64'b0;
                            gmem_read_requests_q <= 64'b0;
                            gmem_read_responses_q <= 64'b0;
                            read_payload_bytes_q <= 64'b0;
                            gmem_write_requests_q <= 64'b0;
                            gmem_write_responses_q <= 64'b0;
                            write_payload_bytes_q <= 64'b0;
                            fma_requests_q <= 64'b0;
                            fma_responses_q <= 64'b0;
                            reduction_requests_q <= 64'b0;
                            reduction_responses_q <= 64'b0;
                            state_q <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q <= ST_ERROR;
                        end else begin
                            profile_id_q <= profile_kq_w ? PROFILE_KQ
                                                        : PROFILE_KQV;
                            operator_census_q <= OPERATOR_CENSUS;
                            profile_census_q <= PROFILE_CENSUS;
                            head_index_q <= 3'b0;
                            output_row_q <= 8'b0;
                            src1_beat_q <= 7'b0;
                            state_q <= ST_SRC1_PREP;
                        end
                    end

                    ST_SRC1_PREP: begin
                        if (!runtime_src1_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_src1_addr_w[63:0];
                            request_wdata_q <= 64'b0;
                            request_wstrb_q <= 8'b0;
                            request_write_q <= 1'b0;
                            request_kind_q <= 2'd1;
                            state_q <= ST_SRC1_REQ;
                        end
                    end

                    ST_SRC1_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else begin
                                state_q <= ST_SRC1_WAIT;
                            end
                        end else if (stall_timeout_hit_w) begin
                            if (error_code_q == ERR_NONE)
                                error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end

                    ST_SRC1_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                src1_cache_q[{src1_beat_q, 1'b0}]
                                    <= src1_expanded_low_w;
                                src1_cache_q[{src1_beat_q, 1'b1}]
                                    <= src1_expanded_high_w;
                                conversion_inexact_q <= conversion_inexact_q
                                    || src1_low_inexact_w
                                    || src1_high_inexact_w;
                                conversion_overflow_q <= conversion_overflow_q
                                    || src1_low_overflow_w
                                    || src1_high_overflow_w;
                                conversion_nonfinite_q
                                    <= conversion_nonfinite_q
                                    || !src1_low_finite_w
                                    || !src1_high_finite_w;
                                if (src1_beat_q == 7'd127) begin
                                    output_row_q <= 8'b0;
                                    state_q <= ST_OUTPUT_INIT;
                                end else begin
                                    src1_beat_q <= src1_beat_q + 7'd1;
                                    state_q <= ST_SRC1_PREP;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_OUTPUT_INIT: begin
                        for (reset_index = 0; reset_index < 32;
                                reset_index = reset_index + 1)
                            accumulator_q[reset_index] <= 32'b0;
                        for (reset_index = 0; reset_index < 4;
                                reset_index = reset_index + 1) begin
                            hadd_stage1_q[reset_index] <= 32'b0;
                            hadd_stage2_q[reset_index] <= 32'b0;
                        end
                        chunk_q <= 3'b0;
                        vector_group_q <= 2'b0;
                        src0_beat_q <= 1'b0;
                        lane_q <= 3'b0;
                        reduction_step_q <= 6'b0;
                        state_q <= ST_SRC0_PREP;
                    end

                    ST_SRC0_PREP: begin
                        if (!runtime_src0_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_src0_addr_w[63:0];
                            request_wdata_q <= 64'b0;
                            request_wstrb_q <= 8'b0;
                            request_write_q <= 1'b0;
                            request_kind_q <= 2'd0;
                            state_q <= ST_SRC0_REQ;
                        end
                    end

                    ST_SRC0_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else begin
                                state_q <= ST_SRC0_WAIT;
                            end
                        end else if (stall_timeout_hit_w) begin
                            if (error_code_q == ERR_NONE)
                                error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end

                    ST_SRC0_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                src0_group_q[{src0_beat_q, 2'b00}]
                                    <= src0_expanded_w[0];
                                src0_group_q[{src0_beat_q, 2'b01}]
                                    <= src0_expanded_w[1];
                                src0_group_q[{src0_beat_q, 2'b10}]
                                    <= src0_expanded_w[2];
                                src0_group_q[{src0_beat_q, 2'b11}]
                                    <= src0_expanded_w[3];
                                if (!src0_beat_q) begin
                                    src0_beat_q <= 1'b1;
                                    state_q <= ST_SRC0_PREP;
                                end else begin
                                    lane_q <= 3'b0;
                                    state_q <= ST_FMA_REQ;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_FMA_REQ: begin
                        if (fma_req_fire_w)
                            state_q <= ST_FMA_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_FMA_WAIT: begin
                        if (fma_rsp_fire_w) begin
                            accumulator_q[fma_accumulator_index_w]
                                <= fma_result_w;
                            if (lane_q == 3'd7) begin
                                if (vector_group_q == 2'd3) begin
                                    if (chunk_q == 3'd7) begin
                                        reduction_step_q <= 6'b0;
                                        state_q <= ST_REDUCE_REQ;
                                    end else begin
                                        chunk_q <= chunk_q + 3'd1;
                                        vector_group_q <= 2'b0;
                                        src0_beat_q <= 1'b0;
                                        state_q <= ST_SRC0_PREP;
                                    end
                                end else begin
                                    vector_group_q <= vector_group_q + 2'd1;
                                    src0_beat_q <= 1'b0;
                                    state_q <= ST_SRC0_PREP;
                                end
                            end else begin
                                lane_q <= lane_q + 3'd1;
                                state_q <= ST_FMA_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_REDUCE_REQ: begin
                        if (add_req_fire_w)
                            state_q <= ST_REDUCE_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_REDUCE_WAIT: begin
                        if (add_rsp_fire_w) begin
                            if (reduction_step_q < 6'd28)
                                accumulator_q[reduction_dest_w] <= add_result_w;
                            else if (reduction_step_q < 6'd32)
                                hadd_stage1_q[reduction_dest_w] <= add_result_w;
                            else
                                hadd_stage2_q[reduction_dest_w] <= add_result_w;

                            if (reduction_step_q == 6'd35) begin
                                output_q <= hadd_stage2_q[0];
                                outputs_computed_q
                                    <= outputs_computed_q + 64'd1;
                                state_q <= ST_WRITE_PREP;
                            end else begin
                                reduction_step_q <= reduction_step_q + 6'd1;
                                state_q <= ST_REDUCE_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_WRITE_PREP: begin
                        if (!runtime_write_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q
                                <= runtime_write_phys_start_w[63:0];
                            if (runtime_write_addr_w[2]) begin
                                request_wdata_q <= {output_q, 32'b0};
                                request_wstrb_q <= 8'hf0;
                            end else begin
                                request_wdata_q <= {32'b0, output_q};
                                request_wstrb_q <= 8'h0f;
                            end
                            request_write_q <= 1'b1;
                            request_kind_q <= 2'd2;
                            state_q <= ST_WRITE_REQ;
                        end
                    end

                    ST_WRITE_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else begin
                                state_q <= ST_WRITE_WAIT;
                            end
                        end else if (stall_timeout_hit_w) begin
                            if (error_code_q == ERR_NONE)
                                error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end

                    ST_WRITE_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else if (output_row_q == 8'd255) begin
                                if (head_index_q == 3'd7) begin
                                    state_q <= ST_DONE;
                                end else begin
                                    head_index_q <= head_index_q + 3'd1;
                                    output_row_q <= 8'b0;
                                    src1_beat_q <= 7'b0;
                                    state_q <= ST_SRC1_PREP;
                                end
                            end else begin
                                output_row_q <= output_row_q + 8'd1;
                                state_q <= ST_OUTPUT_INIT;
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
                        fma_resident_q <= 1'b0;
                        add_resident_q <= 1'b0;
                        state_q <= ST_ERROR;
                    end

                    ST_DONE: begin
                        error_code_q <= ERR_NONE;
                        state_q <= ST_IDLE;
                    end

                    ST_ERROR: begin
                        state_q <= ST_IDLE;
                    end

                    default: begin
                        if (error_code_q == ERR_NONE)
                            error_code_q <= ERR_INTERNAL_STATE;
                        if (outstanding_q)
                            state_q <= ST_GMEM_DRAIN;
                        else if (fma_resident_q || add_resident_q)
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
