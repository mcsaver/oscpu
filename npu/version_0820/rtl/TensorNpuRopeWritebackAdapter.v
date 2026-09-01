`timescale 1ns/1ps
`default_nettype none

// Transactional frozen-v5 Qwen IMROPE owner.
//
// The adapter accepts only the two manifest-frozen F32 Q/K profiles.  It
// reads all four I32 position operands, converts them through the public RNE
// converter, generates 32 sine/cosine pairs once, and reuses that cache for
// every head.  The first 64 channels are rotated as split MUL plus fused FMA
// operations in the pinned Alder Lake order; channels 64..255 are copied as
// raw bits.  Every write targets a transaction-private shadow.  dst_commit_o
// is the sole publication eligibility signal.
module TensorNpuRopeWritebackAdapter #(
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd128,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd4194304,
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
    input  wire [511:0] op_params_i,
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
    output wire         poisoned_o,

    output wire [63:0]  outputs_computed_o,
    output wire [63:0]  outputs_completed_o,
    output wire [63:0]  source0_words_completed_o,
    output wire [63:0]  position_words_completed_o,
    output wire [63:0]  position_conversions_completed_o,
    output wire [63:0]  raw_copy_words_completed_o,
    output wire [63:0]  rotation_pairs_completed_o,
    output wire [63:0]  gmem_read_requests_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_requests_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  sincos_requests_o,
    output wire [63:0]  sincos_responses_o,
    output wire [63:0]  theta_mul_requests_o,
    output wire [63:0]  theta_mul_responses_o,
    output wire [63:0]  data_mul_requests_o,
    output wire [63:0]  data_mul_responses_o,
    output wire [63:0]  fma_requests_o,
    output wire [63:0]  fma_responses_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire         numeric_outstanding_o,
    output wire         gmem_drain_o
);

    localparam [31:0] KERNEL_IMROPE_F32 = 32'h514e000a;
    localparam [15:0] MANIFEST_ROPE = 16'd48;
    localparam [7:0] DTYPE_F32 = 8'd0;
    localparam [7:0] DTYPE_I32 = 8'd26;
    localparam [7:0] PROFILE_Q = 8'd0;
    localparam [7:0] PROFILE_K = 8'd1;
    localparam [7:0] PROFILE_INVALID = 8'hff;
    localparam [31:0] OPERATOR_CENSUS = 32'd12;
    localparam [31:0] PROFILE_CENSUS = 32'd6;
    localparam [31:0] THETA_SCALE = 32'h3f1ab32b;
    // Packed little-endian words 15..0 from the frozen 64-byte record.
    localparam [511:0] FROZEN_OP_PARAMS = {
        32'h00000000, 32'h00000000, 32'h0000000a, 32'h0000000b,
        32'h0000000b, 32'h3f800000, 32'h42000000, 32'h3f800000,
        32'h00000000, 32'h3f800000, 32'h4b189680, 32'h00040000,
        32'h00000000, 32'h00000028, 32'h00000040, 32'h00000000
    };

    localparam [4:0] ST_IDLE            = 5'd0;
    localparam [4:0] ST_PREFLIGHT       = 5'd1;
    localparam [4:0] ST_POS_PREP        = 5'd2;
    localparam [4:0] ST_POS_REQ         = 5'd3;
    localparam [4:0] ST_POS_WAIT        = 5'd4;
    localparam [4:0] ST_POS_CONVERT     = 5'd5;
    localparam [4:0] ST_SINCOS_REQ      = 5'd6;
    localparam [4:0] ST_SINCOS_WAIT     = 5'd7;
    localparam [4:0] ST_THETA_MUL_REQ   = 5'd8;
    localparam [4:0] ST_THETA_MUL_WAIT  = 5'd9;
    localparam [4:0] ST_HEAD_READ_PREP  = 5'd10;
    localparam [4:0] ST_HEAD_READ_REQ   = 5'd11;
    localparam [4:0] ST_HEAD_READ_WAIT  = 5'd12;
    localparam [4:0] ST_DATA_MUL0_REQ   = 5'd13;
    localparam [4:0] ST_DATA_MUL0_WAIT  = 5'd14;
    localparam [4:0] ST_FMA0_REQ        = 5'd15;
    localparam [4:0] ST_FMA0_WAIT       = 5'd16;
    localparam [4:0] ST_DATA_MUL1_REQ   = 5'd17;
    localparam [4:0] ST_DATA_MUL1_WAIT  = 5'd18;
    localparam [4:0] ST_FMA1_REQ        = 5'd19;
    localparam [4:0] ST_FMA1_WAIT       = 5'd20;
    localparam [4:0] ST_ROT_WRITE_PREP  = 5'd21;
    localparam [4:0] ST_COPY_WRITE_PREP = 5'd22;
    localparam [4:0] ST_WRITE_REQ       = 5'd23;
    localparam [4:0] ST_WRITE_WAIT      = 5'd24;
    localparam [4:0] ST_GMEM_DRAIN      = 5'd25;
    localparam [4:0] ST_CORE_RESET      = 5'd26;
    localparam [4:0] ST_DONE            = 5'd27;
    localparam [4:0] ST_ERROR           = 5'd28;

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

    localparam [1:0] REQ_POSITION = 2'd0;
    localparam [1:0] REQ_SOURCE0  = 2'd1;
    localparam [1:0] REQ_ROT_WRITE = 2'd2;
    localparam [1:0] REQ_COPY_WRITE = 2'd3;

    localparam [31:0] STALL_TIMEOUT_LAST =
        STALL_TIMEOUT_CYCLES <= 32'd1 ? 32'd0 : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        COMMAND_TIMEOUT_CYCLES <= 64'd1 ? 64'd0
                                         : COMMAND_TIMEOUT_CYCLES - 64'd1;
    localparam [31:0] DRAIN_TIMEOUT_LAST =
        DRAIN_TIMEOUT_CYCLES <= 32'd1 ? 32'd0 : DRAIN_TIMEOUT_CYCLES - 32'd1;
    localparam [31:0] ABORT_HOLD_TIMEOUT_LAST =
        ABORT_HOLD_TIMEOUT_CYCLES <= 32'd1 ? 32'd0
                                           : ABORT_HOLD_TIMEOUT_CYCLES - 32'd1;

    reg [4:0] state_q;
    reg [15:0] manifest_op_id_q;
    reg [2:0] source_arity_q;
    reg [511:0] op_params_q;
    reg npu_required_q;
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
    reg [4:0] error_code_q, numeric_flags_q;
    reg poisoned_q, abort_hold_q;
    reg [31:0] stall_cycles_q, drain_cycles_q, abort_hold_cycles_q;
    reg [63:0] command_cycles_q, active_cycles_q;

    reg [0:0] position_beat_q;
    reg [1:0] position_index_q;
    reg [5:0] sincos_index_q;
    reg [1:0] theta_selector_q, theta_mul_index_q;
    reg [2:0] head_index_q;
    reg [6:0] head_read_beat_q, copy_beat_q;
    reg [5:0] pair_index_q;
    reg write_slot_q;
    reg signed [31:0] position_q [0:3];
    reg [31:0] theta_t_q, theta_h_q, theta_w_q;
    reg [31:0] sin_cache_q [0:31];
    reg [31:0] cos_cache_q [0:31];
    reg [31:0] source_cache_q [0:255];
    reg [31:0] tmp0_q, tmp1_q, out0_q, out1_q;

    reg [63:0] request_addr_q, request_wdata_q;
    reg [7:0] request_wstrb_q;
    reg request_write_q;
    reg [1:0] request_kind_q;
    reg outstanding_q, add_resident_q, fma_resident_q, sincos_resident_q;

    reg [63:0] outputs_computed_q, outputs_completed_q;
    reg [63:0] source0_words_completed_q, position_words_completed_q;
    reg [63:0] position_conversions_completed_q;
    reg [63:0] raw_copy_words_completed_q, rotation_pairs_completed_q;
    reg [63:0] gmem_read_requests_q, gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_requests_q, gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;
    reg [63:0] sincos_requests_q, sincos_responses_q;
    reg [63:0] theta_mul_requests_q, theta_mul_responses_q;
    reg [63:0] data_mul_requests_q, data_mul_responses_q;
    reg [63:0] fma_requests_q, fma_responses_q;

    wire add_req_ready_w, add_rsp_valid_w;
    wire [31:0] add_result_w;
    wire [4:0] add_flags_w;
    wire fma_req_ready_w, fma_rsp_valid_w;
    wire [31:0] fma_result_w;
    wire [4:0] fma_flags_w;
    wire sincos_req_ready_w, sincos_rsp_valid_w;
    wire [31:0] sincos_sin_w, sincos_cos_w;
    wire sincos_error_w;
    wire core_rst_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE) && !poisoned_q
                   && add_req_ready_w && fma_req_ready_w
                   && sincos_req_ready_w && !gmem_rsp_valid_i;
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
    assign completion_npu_required_o = completion_valid_o
                                        ? npu_required_q : 1'b0;
    assign completion_manifest_op_id_o = completion_valid_o
                                           ? manifest_op_id_q : 16'b0;
    assign completion_source_arity_o = completion_valid_o
                                         ? source_arity_q : 3'b0;
    assign completion_profile_id_o = completion_valid_o ? profile_id_q : 8'b0;
    assign completion_kernel_id_o = completion_valid_o
                                      ? KERNEL_IMROPE_F32 : 32'b0;
    assign completion_operator_census_o = completion_valid_o
                                            ? OPERATOR_CENSUS : 32'b0;
    assign completion_profile_census_o = completion_valid_o
                                           ? (profile_id_q == PROFILE_INVALID
                                              ? 32'b0 : PROFILE_CENSUS)
                                           : 32'b0;
    assign error_code_o = error_code_q;
    assign numeric_flags_o = numeric_flags_q;
    assign poisoned_o = !rst_i && poisoned_q;

    assign outputs_computed_o = outputs_computed_q;
    assign outputs_completed_o = outputs_completed_q;
    assign source0_words_completed_o = source0_words_completed_q;
    assign position_words_completed_o = position_words_completed_q;
    assign position_conversions_completed_o = position_conversions_completed_q;
    assign raw_copy_words_completed_o = raw_copy_words_completed_q;
    assign rotation_pairs_completed_o = rotation_pairs_completed_q;
    assign gmem_read_requests_o = gmem_read_requests_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_requests_o = gmem_write_requests_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign sincos_requests_o = sincos_requests_q;
    assign sincos_responses_o = sincos_responses_q;
    assign theta_mul_requests_o = theta_mul_requests_q;
    assign theta_mul_responses_o = theta_mul_responses_q;
    assign data_mul_requests_o = data_mul_requests_q;
    assign data_mul_responses_o = data_mul_responses_q;
    assign fma_requests_o = fma_requests_q;
    assign fma_responses_o = fma_responses_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign numeric_outstanding_o = add_resident_q || fma_resident_q
                                 || sincos_resident_q;
    assign gmem_drain_o = !rst_i && (state_q == ST_GMEM_DRAIN);

    wire start_fire_w = start_i && ready_o;
    wire gmem_request_state_w = (state_q == ST_POS_REQ)
                              || (state_q == ST_HEAD_READ_REQ)
                              || (state_q == ST_WRITE_REQ);
    wire gmem_response_state_w = (state_q == ST_POS_WAIT)
                               || (state_q == ST_HEAD_READ_WAIT)
                               || (state_q == ST_WRITE_WAIT)
                               || (state_q == ST_GMEM_DRAIN);
    assign gmem_req_valid_o = !rst_i && gmem_request_state_w;
    assign gmem_req_write_o = request_write_q;
    assign gmem_req_addr_o = request_addr_q;
    assign gmem_req_wdata_o = request_wdata_q;
    assign gmem_req_wstrb_o = request_wstrb_q;
    assign gmem_rsp_ready_o = !rst_i && gmem_response_state_w
                            && outstanding_q;
    wire gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    wire gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;

    wire add_req_state_w = (state_q == ST_THETA_MUL_REQ)
                         || (state_q == ST_DATA_MUL0_REQ)
                         || (state_q == ST_DATA_MUL1_REQ);
    wire add_wait_state_w = (state_q == ST_THETA_MUL_WAIT)
                          || (state_q == ST_DATA_MUL0_WAIT)
                          || (state_q == ST_DATA_MUL1_WAIT);
    wire fma_req_state_w = (state_q == ST_FMA0_REQ)
                         || (state_q == ST_FMA1_REQ);
    wire fma_wait_state_w = (state_q == ST_FMA0_WAIT)
                          || (state_q == ST_FMA1_WAIT);
    wire sincos_req_state_w = state_q == ST_SINCOS_REQ;
    wire sincos_wait_state_w = state_q == ST_SINCOS_WAIT;
    wire add_req_valid_w = !rst_i && add_req_state_w;
    wire add_rsp_ready_w = !rst_i && add_wait_state_w && add_resident_q;
    wire fma_req_valid_w = !rst_i && fma_req_state_w;
    wire fma_rsp_ready_w = !rst_i && fma_wait_state_w && fma_resident_q;
    wire sincos_req_valid_w = !rst_i && sincos_req_state_w;
    wire sincos_rsp_ready_w = !rst_i && sincos_wait_state_w
                            && sincos_resident_q;
    wire add_req_fire_w = add_req_valid_w && add_req_ready_w;
    wire add_rsp_fire_w = add_rsp_valid_w && add_rsp_ready_w;
    wire fma_req_fire_w = fma_req_valid_w && fma_req_ready_w;
    wire fma_rsp_fire_w = fma_rsp_valid_w && fma_rsp_ready_w;
    wire sincos_req_fire_w = sincos_req_valid_w && sincos_req_ready_w;
    wire sincos_rsp_fire_w = sincos_rsp_valid_w && sincos_rsp_ready_w;
    assign core_rst_w = rst_i || (state_q == ST_CORE_RESET);

    reg [31:0] selected_theta_w;
    always @(*) begin
        case (theta_selector_q)
            2'd0: selected_theta_w = theta_t_q;
            2'd1: selected_theta_w = theta_h_q;
            default: selected_theta_w = theta_w_q;
        endcase
    end

    reg [31:0] add_lhs_w, add_rhs_w;
    always @(*) begin
        add_lhs_w = 32'b0;
        add_rhs_w = 32'b0;
        if (state_q == ST_THETA_MUL_REQ) begin
            case (theta_mul_index_q)
                2'd0: add_lhs_w = theta_t_q;
                2'd1: add_lhs_w = theta_h_q;
                default: add_lhs_w = theta_w_q;
            endcase
            add_rhs_w = THETA_SCALE;
        end else if (state_q == ST_DATA_MUL0_REQ) begin
            add_lhs_w = source_cache_q[pair_index_q + 6'd32];
            add_rhs_w = sin_cache_q[pair_index_q];
        end else if (state_q == ST_DATA_MUL1_REQ) begin
            add_lhs_w = source_cache_q[pair_index_q + 6'd32];
            add_rhs_w = cos_cache_q[pair_index_q];
        end
    end

    reg [31:0] fma_a_w, fma_b_w, fma_c_w;
    always @(*) begin
        fma_a_w = source_cache_q[pair_index_q];
        fma_b_w = 32'b0;
        fma_c_w = 32'b0;
        if (state_q == ST_FMA0_REQ) begin
            fma_b_w = cos_cache_q[pair_index_q];
            fma_c_w = {~tmp0_q[31], tmp0_q[30:0]};
        end else if (state_q == ST_FMA1_REQ) begin
            fma_b_w = sin_cache_q[pair_index_q];
            fma_c_w = tmp1_q;
        end
    end

    TensorNpuInt32ToFp32 u_position_convert (
        .int_i(position_q[position_index_q]),
        .fp32_bits_o(position_fp_bits_w),
        .inexact_o(position_inexact_w)
    );
    wire [31:0] position_fp_bits_w;
    wire position_inexact_w;

    TensorNpuFp32SincosCordic u_sincos (
        .clk_i(clk_i), .rst_i(core_rst_w),
        .req_valid_i(sincos_req_valid_w),
        .req_ready_o(sincos_req_ready_w),
        .angle_bits_i(selected_theta_w),
        .rsp_valid_o(sincos_rsp_valid_w),
        .rsp_ready_i(sincos_rsp_ready_w),
        .sin_bits_o(sincos_sin_w), .cos_bits_o(sincos_cos_w),
        .error_o(sincos_error_w)
    );

    TensorNpuFp32AddMul u_mul (
        .clk_i(clk_i), .rst_i(core_rst_w),
        .req_valid_i(add_req_valid_w), .req_ready_o(add_req_ready_w),
        .op_mul_i(1'b1), .lhs_bits_i(add_lhs_w), .rhs_bits_i(add_rhs_w),
        .rsp_valid_o(add_rsp_valid_w), .rsp_ready_i(add_rsp_ready_w),
        .result_bits_o(add_result_w), .flags_o(add_flags_w)
    );

    TensorNpuFp32Fma u_fma (
        .clk_i(clk_i), .rst_i(core_rst_w),
        .req_valid_i(fma_req_valid_w), .req_ready_o(fma_req_ready_w),
        .multiplicand_a_bits_i(fma_a_w),
        .multiplicand_b_bits_i(fma_b_w), .addend_bits_i(fma_c_w),
        .rsp_valid_o(fma_rsp_valid_w), .rsp_ready_i(fma_rsp_ready_w),
        .result_bits_o(fma_result_w), .flags_o(fma_flags_w)
    );

    wire phase_fire_w = gmem_req_fire_w || gmem_rsp_fire_w
                      || add_req_fire_w || add_rsp_fire_w
                      || fma_req_fire_w || fma_rsp_fire_w
                      || sincos_req_fire_w || sincos_rsp_fire_w;
    wire stall_state_w = gmem_request_state_w
                       || (state_q == ST_POS_WAIT)
                       || (state_q == ST_HEAD_READ_WAIT)
                       || (state_q == ST_WRITE_WAIT)
                       || add_req_state_w || add_wait_state_w
                       || fma_req_state_w || fma_wait_state_w
                       || sincos_req_state_w || sincos_wait_state_w;
    wire stall_timeout_hit_w = stall_state_w
                             && (stall_cycles_q >= STALL_TIMEOUT_LAST)
                             && !phase_fire_w;
    wire command_timeout_hit_w = (state_q != ST_IDLE)
                               && (state_q != ST_DONE)
                               && (state_q != ST_ERROR)
                               && (state_q != ST_GMEM_DRAIN)
                               && (state_q != ST_CORE_RESET)
                               && (command_cycles_q >= COMMAND_TIMEOUT_LAST)
                               && !phase_fire_w;
    wire drain_timeout_hit_w = (state_q == ST_GMEM_DRAIN)
                             && (drain_cycles_q >= DRAIN_TIMEOUT_LAST)
                             && !gmem_rsp_fire_w;
    wire abort_hold_timeout_hit_w = abort_hold_q && !gmem_req_fire_w
                                  && (abort_hold_cycles_q
                                      >= ABORT_HOLD_TIMEOUT_LAST);

    // Full 128-bit semantic, physical-beat, capability and alias preflight.
    reg descriptor_common_ok_w, profile_q_ok_w, profile_k_ok_w;
    reg src0_window_ok_w, src1_window_ok_w, dst_window_ok_w, alias_ok_w;
    reg [4:0] preflight_error_w;
    reg [7:0] preflight_profile_w;
    reg [127:0] src0_last_w, src1_last_w, dst_last_w;
    reg [127:0] src0_end_w, src1_end_w, dst_end_w;
    reg [127:0] src0_window_end_w, src1_window_end_w, dst_window_end_w;
    reg [127:0] src0_phys_start_w, src0_phys_end_w;
    reg [127:0] src1_phys_start_w, src1_phys_end_w;
    reg [127:0] dst_phys_start_w, dst_phys_end_w, align_tmp_w;
    always @(*) begin
        src0_last_w = ({96'b0, src0_ne0_q - 32'd1} * {64'b0, src0_nb0_q})
                    + ({96'b0, src0_ne1_q - 32'd1} * {64'b0, src0_nb1_q})
                    + ({96'b0, src0_ne2_q - 32'd1} * {64'b0, src0_nb2_q})
                    + ({96'b0, src0_ne3_q - 32'd1} * {64'b0, src0_nb3_q});
        src1_last_w = ({96'b0, src1_ne0_q - 32'd1} * {64'b0, src1_nb0_q})
                    + ({96'b0, src1_ne1_q - 32'd1} * {64'b0, src1_nb1_q})
                    + ({96'b0, src1_ne2_q - 32'd1} * {64'b0, src1_nb2_q})
                    + ({96'b0, src1_ne3_q - 32'd1} * {64'b0, src1_nb3_q});
        dst_last_w = ({96'b0, dst_ne0_q - 32'd1} * {64'b0, dst_nb0_q})
                   + ({96'b0, dst_ne1_q - 32'd1} * {64'b0, dst_nb1_q})
                   + ({96'b0, dst_ne2_q - 32'd1} * {64'b0, dst_nb2_q})
                   + ({96'b0, dst_ne3_q - 32'd1} * {64'b0, dst_nb3_q});
        src0_end_w = {64'b0, src0_base_q} + src0_last_w + 128'd4;
        src1_end_w = {64'b0, src1_base_q} + src1_last_w + 128'd4;
        dst_end_w = {64'b0, dst_base_q} + dst_last_w + 128'd4;
        src0_window_end_w = {64'b0, src0_window_base_q}
                          + {64'b0, src0_window_bytes_q};
        src1_window_end_w = {64'b0, src1_window_base_q}
                          + {64'b0, src1_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};

        src0_phys_start_w = {64'b0, src0_base_q};
        src0_phys_start_w[2:0] = 3'b0;
        align_tmp_w = src0_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b0;
        src0_phys_end_w = align_tmp_w;
        src1_phys_start_w = {64'b0, src1_base_q};
        src1_phys_start_w[2:0] = 3'b0;
        align_tmp_w = src1_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b0;
        src1_phys_end_w = align_tmp_w;
        dst_phys_start_w = {64'b0, dst_base_q};
        dst_phys_start_w[2:0] = 3'b0;
        align_tmp_w = dst_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b0;
        dst_phys_end_w = align_tmp_w;

        profile_q_ok_w = (src0_ne0_q == 32'd256)
                       && (src0_ne1_q == 32'd8)
                       && (src0_ne2_q == 32'd1)
                       && (src0_ne3_q == 32'd1)
                       && (src0_nb0_q == 64'd4)
                       && (src0_nb1_q == 64'd1024)
                       && (src0_nb2_q == 64'd8192)
                       && (src0_nb3_q == 64'd8192)
                       && (dst_ne0_q == 32'd256)
                       && (dst_ne1_q == 32'd8)
                       && (dst_ne2_q == 32'd1)
                       && (dst_ne3_q == 32'd1)
                       && (dst_nb0_q == 64'd4)
                       && (dst_nb1_q == 64'd1024)
                       && (dst_nb2_q == 64'd8192)
                       && (dst_nb3_q == 64'd8192);
        profile_k_ok_w = (src0_ne0_q == 32'd256)
                       && (src0_ne1_q == 32'd2)
                       && (src0_ne2_q == 32'd1)
                       && (src0_ne3_q == 32'd1)
                       && (src0_nb0_q == 64'd4)
                       && (src0_nb1_q == 64'd1024)
                       && (src0_nb2_q == 64'd2048)
                       && (src0_nb3_q == 64'd2048)
                       && (dst_ne0_q == 32'd256)
                       && (dst_ne1_q == 32'd2)
                       && (dst_ne2_q == 32'd1)
                       && (dst_ne3_q == 32'd1)
                       && (dst_nb0_q == 64'd4)
                       && (dst_nb1_q == 64'd1024)
                       && (dst_nb2_q == 64'd2048)
                       && (dst_nb3_q == 64'd2048);
        descriptor_common_ok_w = (manifest_op_id_q == MANIFEST_ROPE)
                               && (source_arity_q == 3'd2)
                               && (op_params_q == FROZEN_OP_PARAMS)
                               && npu_required_q && dst_shadow_private_q
                               && windows_generation_valid_q
                               && ((canonical_node_id_lo_q != 64'b0)
                                   || (canonical_node_id_hi_q != 64'b0))
                               && (src0_dtype_q == DTYPE_F32)
                               && (src0_flags_q == 32'd16)
                               && (src0_view_off_q == 64'b0)
                               && (src1_dtype_q == DTYPE_I32)
                               && (src1_flags_q == 32'd1)
                               && (src1_view_off_q == 64'b0)
                               && (src1_ne0_q == 32'd4)
                               && (src1_ne1_q == 32'd1)
                               && (src1_ne2_q == 32'd1)
                               && (src1_ne3_q == 32'd1)
                               && (src1_nb0_q == 64'd4)
                               && (src1_nb1_q == 64'd16)
                               && (src1_nb2_q == 64'd16)
                               && (src1_nb3_q == 64'd16)
                               && (dst_dtype_q == DTYPE_F32)
                               && (dst_flags_q == 32'd16)
                               && (dst_view_off_q == 64'b0);
        preflight_profile_w = profile_q_ok_w ? PROFILE_Q
                                             : (profile_k_ok_w ? PROFILE_K
                                                               : PROFILE_INVALID);
        src0_window_ok_w = (src0_window_end_w[127:64] == 64'b0)
                         && (src0_end_w[127:64] == 64'b0)
                         && (src0_phys_end_w[127:64] == 64'b0)
                         && (src0_base_q[2:0] == 3'b0)
                         && (src0_window_base_q[2:0] == 3'b0)
                         && (src0_window_bytes_q[2:0] == 3'b0)
                         && src0_window_read_q && !src0_window_write_q
                         && (src0_window_bytes_q != 64'b0)
                         && (src0_phys_start_w >= {64'b0, src0_window_base_q})
                         && (src0_phys_end_w <= src0_window_end_w);
        src1_window_ok_w = (src1_window_end_w[127:64] == 64'b0)
                         && (src1_end_w[127:64] == 64'b0)
                         && (src1_phys_end_w[127:64] == 64'b0)
                         && (src1_base_q[2:0] == 3'b0)
                         && (src1_window_base_q[2:0] == 3'b0)
                         && (src1_window_bytes_q[2:0] == 3'b0)
                         && src1_window_read_q && !src1_window_write_q
                         && (src1_window_bytes_q != 64'b0)
                         && (src1_phys_start_w >= {64'b0, src1_window_base_q})
                         && (src1_phys_end_w <= src1_window_end_w);
        dst_window_ok_w = (dst_window_end_w[127:64] == 64'b0)
                        && (dst_end_w[127:64] == 64'b0)
                        && (dst_phys_end_w[127:64] == 64'b0)
                        && (dst_base_q[2:0] == 3'b0)
                        && (dst_window_base_q[2:0] == 3'b0)
                        && (dst_window_bytes_q[2:0] == 3'b0)
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
        if (!descriptor_common_ok_w || (preflight_profile_w == PROFILE_INVALID))
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

    // Per-request address proofs are repeated immediately before latching a
    // request so corrupted control state cannot escape the admitted windows.
    reg [127:0] runtime_addr_w, runtime_end_w;
    reg [127:0] runtime_window_start_w, runtime_window_end_w;
    reg runtime_access_ok_w;
    reg [31:0] runtime_write_word_w;
    always @(*) begin
        runtime_addr_w = 128'b0;
        runtime_end_w = 128'b0;
        runtime_window_start_w = 128'b0;
        runtime_window_end_w = 128'b0;
        runtime_write_word_w = 32'b0;
        if (state_q == ST_POS_PREP) begin
            runtime_addr_w = {64'b0, src1_base_q}
                           + (position_beat_q ? 128'd8 : 128'd0);
            runtime_window_start_w = {64'b0, src1_window_base_q};
            runtime_window_end_w = src1_window_end_w;
            runtime_end_w = runtime_addr_w + 128'd8;
        end else if (state_q == ST_HEAD_READ_PREP) begin
            runtime_addr_w = {64'b0, src0_base_q}
                           + ({125'b0, head_index_q} * {64'b0, src0_nb1_q})
                           + ({121'b0, head_read_beat_q} * 128'd8);
            runtime_window_start_w = {64'b0, src0_window_base_q};
            runtime_window_end_w = src0_window_end_w;
            runtime_end_w = runtime_addr_w + 128'd8;
        end else if (state_q == ST_ROT_WRITE_PREP) begin
            runtime_addr_w = {64'b0, dst_base_q}
                           + ({125'b0, head_index_q} * {64'b0, dst_nb1_q})
                           + ({122'b0, pair_index_q + (write_slot_q ? 6'd32
                                                                    : 6'd0)}
                              * 128'd4);
            runtime_window_start_w = {64'b0, dst_window_base_q};
            runtime_window_end_w = dst_window_end_w;
            runtime_end_w = runtime_addr_w + 128'd4;
            runtime_write_word_w = write_slot_q ? out1_q : out0_q;
        end else if (state_q == ST_COPY_WRITE_PREP) begin
            runtime_addr_w = {64'b0, dst_base_q}
                           + ({125'b0, head_index_q} * {64'b0, dst_nb1_q})
                           + 128'd256
                           + ({121'b0, copy_beat_q} * 128'd8);
            runtime_window_start_w = {64'b0, dst_window_base_q};
            runtime_window_end_w = dst_window_end_w;
            runtime_end_w = runtime_addr_w + 128'd8;
        end
        runtime_access_ok_w = (runtime_addr_w[127:64] == 64'b0)
                            && (runtime_addr_w[2:0] == 3'b0)
                            && (runtime_addr_w >= runtime_window_start_w)
                            && (runtime_end_w <= runtime_window_end_w);
        if (state_q == ST_ROT_WRITE_PREP)
            runtime_access_ok_w = (runtime_addr_w[127:64] == 64'b0)
                                && (runtime_addr_w[1:0] == 2'b0)
                                && (runtime_addr_w >= runtime_window_start_w)
                                && (runtime_end_w <= runtime_window_end_w);
    end

    integer reset_index;
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            manifest_op_id_q <= 16'b0;
            source_arity_q <= 3'b0;
            op_params_q <= 512'b0;
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
            error_code_q <= ERR_NONE;
            numeric_flags_q <= 5'b0;
            poisoned_q <= 1'b0;
            abort_hold_q <= 1'b0;
            stall_cycles_q <= 32'b0;
            drain_cycles_q <= 32'b0;
            abort_hold_cycles_q <= 32'b0;
            command_cycles_q <= 64'b0;
            active_cycles_q <= 64'b0;
            position_beat_q <= 1'b0;
            position_index_q <= 2'b0;
            sincos_index_q <= 6'b0;
            theta_selector_q <= 2'b0;
            theta_mul_index_q <= 2'b0;
            head_index_q <= 3'b0;
            head_read_beat_q <= 7'b0;
            copy_beat_q <= 7'b0;
            pair_index_q <= 6'b0;
            write_slot_q <= 1'b0;
            theta_t_q <= 32'b0;
            theta_h_q <= 32'b0;
            theta_w_q <= 32'b0;
            tmp0_q <= 32'b0;
            tmp1_q <= 32'b0;
            out0_q <= 32'b0;
            out1_q <= 32'b0;
            request_addr_q <= 64'b0;
            request_wdata_q <= 64'b0;
            request_wstrb_q <= 8'b0;
            request_write_q <= 1'b0;
            request_kind_q <= REQ_POSITION;
            outstanding_q <= 1'b0;
            add_resident_q <= 1'b0;
            fma_resident_q <= 1'b0;
            sincos_resident_q <= 1'b0;
            outputs_computed_q <= 64'b0;
            outputs_completed_q <= 64'b0;
            source0_words_completed_q <= 64'b0;
            position_words_completed_q <= 64'b0;
            position_conversions_completed_q <= 64'b0;
            raw_copy_words_completed_q <= 64'b0;
            rotation_pairs_completed_q <= 64'b0;
            gmem_read_requests_q <= 64'b0;
            gmem_read_responses_q <= 64'b0;
            read_payload_bytes_q <= 64'b0;
            gmem_write_requests_q <= 64'b0;
            gmem_write_responses_q <= 64'b0;
            write_payload_bytes_q <= 64'b0;
            sincos_requests_q <= 64'b0;
            sincos_responses_q <= 64'b0;
            theta_mul_requests_q <= 64'b0;
            theta_mul_responses_q <= 64'b0;
            data_mul_requests_q <= 64'b0;
            data_mul_responses_q <= 64'b0;
            fma_requests_q <= 64'b0;
            fma_responses_q <= 64'b0;
            for (reset_index = 0; reset_index < 4;
                    reset_index = reset_index + 1)
                position_q[reset_index] <= 32'sb0;
        end else begin
            if (state_q != ST_IDLE)
                active_cycles_q <= active_cycles_q + 64'd1;
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)
                    && (state_q != ST_GMEM_DRAIN)
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
                outstanding_q <= 1'b1;
                if (request_write_q)
                    gmem_write_requests_q <= gmem_write_requests_q + 64'd1;
                else
                    gmem_read_requests_q <= gmem_read_requests_q + 64'd1;
            end
            if (gmem_rsp_fire_w && outstanding_q) begin
                outstanding_q <= 1'b0;
                if (request_write_q) begin
                    gmem_write_responses_q <= gmem_write_responses_q + 64'd1;
                    if (!gmem_rsp_error_i && (state_q == ST_WRITE_WAIT)) begin
                        if (request_kind_q == REQ_ROT_WRITE) begin
                            write_payload_bytes_q <= write_payload_bytes_q + 64'd4;
                            outputs_completed_q <= outputs_completed_q + 64'd1;
                        end else begin
                            write_payload_bytes_q <= write_payload_bytes_q + 64'd8;
                            outputs_completed_q <= outputs_completed_q + 64'd2;
                        end
                    end
                end else begin
                    gmem_read_responses_q <= gmem_read_responses_q + 64'd1;
                    if (!gmem_rsp_error_i
                            && ((state_q == ST_POS_WAIT)
                                || (state_q == ST_HEAD_READ_WAIT))) begin
                        read_payload_bytes_q <= read_payload_bytes_q + 64'd8;
                        if (request_kind_q == REQ_POSITION)
                            position_words_completed_q
                                <= position_words_completed_q + 64'd2;
                        else
                            source0_words_completed_q
                                <= source0_words_completed_q + 64'd2;
                    end
                end
            end
            if (add_req_fire_w) begin
                add_resident_q <= 1'b1;
                if (state_q == ST_THETA_MUL_REQ)
                    theta_mul_requests_q <= theta_mul_requests_q + 64'd1;
                else
                    data_mul_requests_q <= data_mul_requests_q + 64'd1;
            end
            if (add_rsp_fire_w && add_resident_q) begin
                add_resident_q <= 1'b0;
                numeric_flags_q <= numeric_flags_q | add_flags_w;
                if (state_q == ST_THETA_MUL_WAIT)
                    theta_mul_responses_q <= theta_mul_responses_q + 64'd1;
                else
                    data_mul_responses_q <= data_mul_responses_q + 64'd1;
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
            if (sincos_req_fire_w) begin
                sincos_resident_q <= 1'b1;
                sincos_requests_q <= sincos_requests_q + 64'd1;
            end
            if (sincos_rsp_fire_w && sincos_resident_q) begin
                sincos_resident_q <= 1'b0;
                sincos_responses_q <= sincos_responses_q + 64'd1;
            end

            if (abort_hold_timeout_hit_w || drain_timeout_hit_w) begin
                poisoned_q <= 1'b1;
                abort_hold_q <= 1'b0;
                outstanding_q <= 1'b0;
                if (error_code_q == ERR_NONE)
                    error_code_q <= ERR_STALL_TIMEOUT;
                state_q <= ST_CORE_RESET;
            end else if (command_timeout_hit_w) begin
                if (error_code_q == ERR_NONE)
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                if (gmem_request_state_w)
                    abort_hold_q <= 1'b1;
                else if (outstanding_q)
                    state_q <= ST_GMEM_DRAIN;
                else
                    state_q <= ST_CORE_RESET;
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        if (start_fire_w) begin
                            manifest_op_id_q <= manifest_op_id_i;
                            source_arity_q <= source_arity_i;
                            op_params_q <= op_params_i;
                            npu_required_q <= npu_required_i;
                            command_id_q <= command_id_i;
                            canonical_node_id_lo_q <= canonical_node_id_lo_i;
                            canonical_node_id_hi_q <= canonical_node_id_hi_i;
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
                            error_code_q <= ERR_NONE;
                            numeric_flags_q <= 5'b0;
                            abort_hold_q <= 1'b0;
                            stall_cycles_q <= 32'b0;
                            command_cycles_q <= 64'b0;
                            active_cycles_q <= 64'b0;
                            position_beat_q <= 1'b0;
                            position_index_q <= 2'b0;
                            sincos_index_q <= 6'b0;
                            theta_selector_q <= 2'b0;
                            theta_mul_index_q <= 2'b0;
                            head_index_q <= 3'b0;
                            head_read_beat_q <= 7'b0;
                            copy_beat_q <= 7'b0;
                            pair_index_q <= 6'b0;
                            write_slot_q <= 1'b0;
                            outputs_computed_q <= 64'b0;
                            outputs_completed_q <= 64'b0;
                            source0_words_completed_q <= 64'b0;
                            position_words_completed_q <= 64'b0;
                            position_conversions_completed_q <= 64'b0;
                            raw_copy_words_completed_q <= 64'b0;
                            rotation_pairs_completed_q <= 64'b0;
                            gmem_read_requests_q <= 64'b0;
                            gmem_read_responses_q <= 64'b0;
                            read_payload_bytes_q <= 64'b0;
                            gmem_write_requests_q <= 64'b0;
                            gmem_write_responses_q <= 64'b0;
                            write_payload_bytes_q <= 64'b0;
                            sincos_requests_q <= 64'b0;
                            sincos_responses_q <= 64'b0;
                            theta_mul_requests_q <= 64'b0;
                            theta_mul_responses_q <= 64'b0;
                            data_mul_requests_q <= 64'b0;
                            data_mul_responses_q <= 64'b0;
                            fma_requests_q <= 64'b0;
                            fma_responses_q <= 64'b0;
                            state_q <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        profile_id_q <= preflight_profile_w;
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q <= ST_ERROR;
                        end else begin
                            position_beat_q <= 1'b0;
                            state_q <= ST_POS_PREP;
                        end
                    end

                    ST_POS_PREP: begin
                        if (!runtime_access_ok_w) begin
                            error_code_q <= ERR_SOURCE1_WINDOW;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_addr_w[63:0];
                            request_wdata_q <= 64'b0;
                            request_wstrb_q <= 8'b0;
                            request_write_q <= 1'b0;
                            request_kind_q <= REQ_POSITION;
                            state_q <= ST_POS_REQ;
                        end
                    end

                    ST_POS_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else
                                state_q <= ST_POS_WAIT;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end

                    ST_POS_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                if (!position_beat_q) begin
                                    position_q[0] <= gmem_rsp_rdata_i[31:0];
                                    position_q[1] <= gmem_rsp_rdata_i[63:32];
                                    position_beat_q <= 1'b1;
                                    state_q <= ST_POS_PREP;
                                end else begin
                                    position_q[2] <= gmem_rsp_rdata_i[31:0];
                                    position_q[3] <= gmem_rsp_rdata_i[63:32];
                                    position_index_q <= 2'b0;
                                    state_q <= ST_POS_CONVERT;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_POS_CONVERT: begin
                        position_conversions_completed_q
                            <= position_conversions_completed_q + 64'd1;
                        if (position_inexact_w)
                            numeric_flags_q[0] <= 1'b1;
                        case (position_index_q)
                            2'd0: theta_t_q <= position_fp_bits_w;
                            2'd1: theta_h_q <= position_fp_bits_w;
                            2'd2: theta_w_q <= position_fp_bits_w;
                            default: begin end
                        endcase
                        if (position_index_q == 2'd3) begin
                            sincos_index_q <= 6'b0;
                            theta_selector_q <= 2'b0;
                            state_q <= ST_SINCOS_REQ;
                        end else
                            position_index_q <= position_index_q + 2'd1;
                    end

                    ST_SINCOS_REQ: begin
                        if (sincos_req_fire_w)
                            state_q <= ST_SINCOS_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_SINCOS_WAIT: begin
                        if (sincos_rsp_fire_w) begin
                            if (sincos_error_w) begin
                                error_code_q <= ERR_NUMERIC;
                                state_q <= ST_CORE_RESET;
                            end else begin
                                sin_cache_q[sincos_index_q] <= sincos_sin_w;
                                cos_cache_q[sincos_index_q] <= sincos_cos_w;
                                theta_mul_index_q <= 2'b0;
                                state_q <= ST_THETA_MUL_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_THETA_MUL_REQ: begin
                        if (add_req_fire_w)
                            state_q <= ST_THETA_MUL_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_THETA_MUL_WAIT: begin
                        if (add_rsp_fire_w) begin
                            case (theta_mul_index_q)
                                2'd0: theta_t_q <= add_result_w;
                                2'd1: theta_h_q <= add_result_w;
                                default: theta_w_q <= add_result_w;
                            endcase
                            if (theta_mul_index_q == 2'd2) begin
                                if (sincos_index_q == 6'd31) begin
                                    head_index_q <= 3'b0;
                                    head_read_beat_q <= 7'b0;
                                    state_q <= ST_HEAD_READ_PREP;
                                end else begin
                                    sincos_index_q <= sincos_index_q + 6'd1;
                                    if (theta_selector_q == 2'd2)
                                        theta_selector_q <= 2'd0;
                                    else
                                        theta_selector_q
                                            <= theta_selector_q + 2'd1;
                                    state_q <= ST_SINCOS_REQ;
                                end
                            end else begin
                                theta_mul_index_q <= theta_mul_index_q + 2'd1;
                                state_q <= ST_THETA_MUL_REQ;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_HEAD_READ_PREP: begin
                        if (!runtime_access_ok_w) begin
                            error_code_q <= ERR_SOURCE0_WINDOW;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_addr_w[63:0];
                            request_wdata_q <= 64'b0;
                            request_wstrb_q <= 8'b0;
                            request_write_q <= 1'b0;
                            request_kind_q <= REQ_SOURCE0;
                            state_q <= ST_HEAD_READ_REQ;
                        end
                    end

                    ST_HEAD_READ_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else
                                state_q <= ST_HEAD_READ_WAIT;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end

                    ST_HEAD_READ_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                source_cache_q[{head_read_beat_q, 1'b0}]
                                    <= gmem_rsp_rdata_i[31:0];
                                source_cache_q[{head_read_beat_q, 1'b1}]
                                    <= gmem_rsp_rdata_i[63:32];
                                if (head_read_beat_q == 7'd127) begin
                                    pair_index_q <= 6'b0;
                                    state_q <= ST_DATA_MUL0_REQ;
                                end else begin
                                    head_read_beat_q
                                        <= head_read_beat_q + 7'd1;
                                    state_q <= ST_HEAD_READ_PREP;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_DATA_MUL0_REQ: begin
                        if (add_req_fire_w)
                            state_q <= ST_DATA_MUL0_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_DATA_MUL0_WAIT: begin
                        if (add_rsp_fire_w) begin
                            tmp0_q <= add_result_w;
                            state_q <= ST_FMA0_REQ;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_FMA0_REQ: begin
                        if (fma_req_fire_w)
                            state_q <= ST_FMA0_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_FMA0_WAIT: begin
                        if (fma_rsp_fire_w) begin
                            out0_q <= fma_result_w;
                            outputs_computed_q <= outputs_computed_q + 64'd1;
                            state_q <= ST_DATA_MUL1_REQ;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_DATA_MUL1_REQ: begin
                        if (add_req_fire_w)
                            state_q <= ST_DATA_MUL1_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_DATA_MUL1_WAIT: begin
                        if (add_rsp_fire_w) begin
                            tmp1_q <= add_result_w;
                            state_q <= ST_FMA1_REQ;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_FMA1_REQ: begin
                        if (fma_req_fire_w)
                            state_q <= ST_FMA1_WAIT;
                        else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end
                    ST_FMA1_WAIT: begin
                        if (fma_rsp_fire_w) begin
                            out1_q <= fma_result_w;
                            outputs_computed_q <= outputs_computed_q + 64'd1;
                            rotation_pairs_completed_q
                                <= rotation_pairs_completed_q + 64'd1;
                            write_slot_q <= 1'b0;
                            state_q <= ST_ROT_WRITE_PREP;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_ROT_WRITE_PREP: begin
                        if (!runtime_access_ok_w) begin
                            error_code_q <= ERR_DEST_WINDOW;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= {runtime_addr_w[63:3], 3'b0};
                            if (runtime_addr_w[2]) begin
                                request_wdata_q <= {runtime_write_word_w, 32'b0};
                                request_wstrb_q <= 8'hf0;
                            end else begin
                                request_wdata_q <= {32'b0, runtime_write_word_w};
                                request_wstrb_q <= 8'h0f;
                            end
                            request_write_q <= 1'b1;
                            request_kind_q <= REQ_ROT_WRITE;
                            state_q <= ST_WRITE_REQ;
                        end
                    end

                    ST_COPY_WRITE_PREP: begin
                        if (!runtime_access_ok_w) begin
                            error_code_q <= ERR_DEST_WINDOW;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_addr_w[63:0];
                            request_wdata_q <= {
                                source_cache_q[{copy_beat_q, 1'b1} + 8'd64],
                                source_cache_q[{copy_beat_q, 1'b0} + 8'd64]
                            };
                            request_wstrb_q <= 8'hff;
                            request_write_q <= 1'b1;
                            request_kind_q <= REQ_COPY_WRITE;
                            outputs_computed_q <= outputs_computed_q + 64'd2;
                            raw_copy_words_completed_q
                                <= raw_copy_words_completed_q + 64'd2;
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
                            end else if (request_kind_q == REQ_ROT_WRITE) begin
                                if (!write_slot_q) begin
                                    write_slot_q <= 1'b1;
                                    state_q <= ST_ROT_WRITE_PREP;
                                end else if (pair_index_q == 6'd31) begin
                                    copy_beat_q <= 7'b0;
                                    state_q <= ST_COPY_WRITE_PREP;
                                end else begin
                                    pair_index_q <= pair_index_q + 6'd1;
                                    state_q <= ST_DATA_MUL0_REQ;
                                end
                            end else if (copy_beat_q == 7'd95) begin
                                if ((profile_id_q == PROFILE_Q
                                        && head_index_q == 3'd7)
                                        || (profile_id_q == PROFILE_K
                                            && head_index_q == 3'd1)) begin
                                    state_q <= ST_DONE;
                                end else begin
                                    head_index_q <= head_index_q + 3'd1;
                                    head_read_beat_q <= 7'b0;
                                    state_q <= ST_HEAD_READ_PREP;
                                end
                            end else begin
                                copy_beat_q <= copy_beat_q + 7'd1;
                                state_q <= ST_COPY_WRITE_PREP;
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_GMEM_DRAIN: begin
                        if (gmem_rsp_fire_w)
                            state_q <= ST_CORE_RESET;
                    end
                    ST_CORE_RESET: begin
                        add_resident_q <= 1'b0;
                        fma_resident_q <= 1'b0;
                        sincos_resident_q <= 1'b0;
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
                        if (outstanding_q)
                            state_q <= ST_GMEM_DRAIN;
                        else
                            state_q <= ST_CORE_RESET;
                    end
                endcase
            end
        end
    end

endmodule

`default_nettype wire
