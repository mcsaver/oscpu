`timescale 1ns/1ps
`default_nettype none

// Transactional frozen-v5 SSM_CONV F32 engine.
//
// For each of 6144 output channels this module evaluates the pinned llama.cpp
// scalar order exactly:
//
//   acc = +0.0f
//   for i0 = 0..3:
//       product = round_f32(src0[i0, channel] * src1[i0, channel])
//       acc     = round_f32(acc + product)
//
// TensorNpuFp32AddMul is the sole numerical implementation.  MUL and ADD are
// separate accepted operations; no fused FMA path exists in this wrapper.
// Writes target a transaction-private shadow and dst_commit_o is the only
// eligibility signal for parent publication.
module TensorNpuSsmConvWritebackAdapter #(
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd512,
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
    output wire         poisoned_o,

    output wire [63:0]  outputs_computed_o,
    output wire [63:0]  outputs_completed_o,
    output wire [63:0]  source0_words_completed_o,
    output wire [63:0]  source1_words_completed_o,
    output wire [63:0]  work_items_completed_o,
    output wire [63:0]  gmem_read_requests_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_requests_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  mul_requests_o,
    output wire [63:0]  mul_responses_o,
    output wire [63:0]  add_requests_o,
    output wire [63:0]  add_responses_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire         numeric_outstanding_o,
    output wire         gmem_drain_o
);

    localparam [31:0] KERNEL_SSM_CONV_F32 = 32'h514e0022;
    localparam [15:0] MANIFEST_SSM_CONV = 16'd76;
    localparam [7:0] MANIFEST_F32 = 8'd0;
    localparam [7:0] PROFILE_SSM_CONV = 8'd0;
    localparam [7:0] PROFILE_INVALID = 8'hff;
    localparam [31:0] FROZEN_CENSUS = 32'd18;

    localparam [3:0] ST_IDLE        = 4'd0;
    localparam [3:0] ST_PREFLIGHT   = 4'd1;
    localparam [3:0] ST_READ_PREP   = 4'd2;
    localparam [3:0] ST_READ_REQ    = 4'd3;
    localparam [3:0] ST_READ_WAIT   = 4'd4;
    localparam [3:0] ST_MUL_REQ     = 4'd5;
    localparam [3:0] ST_MUL_WAIT    = 4'd6;
    localparam [3:0] ST_ADD_REQ     = 4'd7;
    localparam [3:0] ST_ADD_WAIT    = 4'd8;
    localparam [3:0] ST_WRITE_PREP  = 4'd9;
    localparam [3:0] ST_WRITE_REQ   = 4'd10;
    localparam [3:0] ST_WRITE_WAIT  = 4'd11;
    localparam [3:0] ST_GMEM_DRAIN  = 4'd12;
    localparam [3:0] ST_CORE_RESET  = 4'd13;
    localparam [3:0] ST_DONE        = 4'd14;
    localparam [3:0] ST_ERROR       = 4'd15;

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

    reg [3:0] state_q;
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
    reg poisoned_q, abort_hold_q;
    reg [31:0] stall_cycles_q, drain_cycles_q, abort_hold_cycles_q;
    reg [63:0] command_cycles_q, active_cycles_q;

    reg [31:0] output_index_q;
    reg [2:0] read_step_q;
    reg [1:0] tap_index_q;
    reg [31:0] src0_buffer_q [0:3];
    reg [31:0] src1_buffer_q [0:3];
    reg [31:0] accumulator_q, product_q, output_q;

    reg [63:0] request_addr_q, request_wdata_q;
    reg [7:0] request_wstrb_q;
    reg request_write_q;
    reg [1:0] request_kind_q;
    reg outstanding_q, numeric_resident_q;

    reg [63:0] outputs_computed_q, outputs_completed_q;
    reg [63:0] source0_words_completed_q, source1_words_completed_q;
    reg [63:0] gmem_read_requests_q, gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_requests_q, gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;
    reg [63:0] mul_requests_q, mul_responses_q;
    reg [63:0] add_requests_q, add_responses_q;

    wire numeric_req_ready_w, numeric_rsp_valid_w;
    wire [31:0] numeric_result_w;
    wire [4:0] numeric_flags_w;
    wire core_rst_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE)
                   && numeric_req_ready_w && !poisoned_q
                   && !gmem_rsp_valid_i;
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
                                      ? KERNEL_SSM_CONV_F32 : 32'b0;
    assign completion_operator_census_o = completion_valid_o
                                            ? operator_census_q : 32'b0;
    assign completion_profile_census_o = completion_valid_o
                                           ? profile_census_q : 32'b0;
    assign error_code_o = error_code_q;
    assign numeric_flags_o = numeric_flags_q;
    assign poisoned_o = !rst_i && poisoned_q;

    assign outputs_computed_o = outputs_computed_q;
    assign outputs_completed_o = outputs_completed_q;
    assign source0_words_completed_o = source0_words_completed_q;
    assign source1_words_completed_o = source1_words_completed_q;
    assign work_items_completed_o = add_responses_q;
    assign gmem_read_requests_o = gmem_read_requests_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_requests_o = gmem_write_requests_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign mul_requests_o = mul_requests_q;
    assign mul_responses_o = mul_responses_q;
    assign add_requests_o = add_requests_q;
    assign add_responses_o = add_responses_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign numeric_outstanding_o = numeric_resident_q;
    assign gmem_drain_o = !rst_i && (state_q == ST_GMEM_DRAIN);

    wire start_fire_w;
    wire gmem_request_state_w, gmem_response_state_w;
    wire gmem_req_fire_w, gmem_rsp_fire_w;
    wire numeric_req_valid_w, numeric_req_fire_w;
    wire numeric_rsp_ready_w, numeric_rsp_fire_w;
    wire phase_fire_w, stall_state_w;
    wire stall_timeout_hit_w, command_timeout_hit_w;
    wire drain_timeout_hit_w, abort_hold_timeout_hit_w;
    assign start_fire_w = start_i && ready_o;
    assign gmem_request_state_w = (state_q == ST_READ_REQ)
                                || (state_q == ST_WRITE_REQ);
    assign gmem_response_state_w = (state_q == ST_READ_WAIT)
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

    assign numeric_req_valid_w = !rst_i && ((state_q == ST_MUL_REQ)
                                           || (state_q == ST_ADD_REQ));
    assign numeric_rsp_ready_w = !rst_i && ((state_q == ST_MUL_WAIT)
                                           || (state_q == ST_ADD_WAIT))
                               && numeric_resident_q;
    assign numeric_req_fire_w = numeric_req_valid_w && numeric_req_ready_w;
    assign numeric_rsp_fire_w = numeric_rsp_valid_w && numeric_rsp_ready_w;
    assign core_rst_w = rst_i || (state_q == ST_CORE_RESET);

    assign phase_fire_w = gmem_req_fire_w || gmem_rsp_fire_w
                        || numeric_req_fire_w || numeric_rsp_fire_w;
    assign stall_state_w = gmem_request_state_w
                         || (state_q == ST_READ_WAIT)
                         || (state_q == ST_WRITE_WAIT)
                         || (state_q == ST_MUL_REQ)
                         || (state_q == ST_MUL_WAIT)
                         || (state_q == ST_ADD_REQ)
                         || (state_q == ST_ADD_WAIT);
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

    TensorNpuFp32AddMul u_numeric (
        .clk_i(clk_i),
        .rst_i(core_rst_w),
        .req_valid_i(numeric_req_valid_w),
        .req_ready_o(numeric_req_ready_w),
        .op_mul_i(state_q == ST_MUL_REQ),
        .lhs_bits_i((state_q == ST_MUL_REQ)
                    ? src0_buffer_q[tap_index_q] : accumulator_q),
        .rhs_bits_i((state_q == ST_MUL_REQ)
                    ? src1_buffer_q[tap_index_q] : product_q),
        .rsp_valid_o(numeric_rsp_valid_w),
        .rsp_ready_i(numeric_rsp_ready_w),
        .result_bits_o(numeric_result_w),
        .flags_o(numeric_flags_w)
    );

    // Whole-descriptor and capability preflight uses 128-bit intermediate
    // arithmetic throughout, including the 8-byte physical GMEM footprints.
    reg descriptor_ok_w, src0_window_ok_w, src1_window_ok_w;
    reg dst_window_ok_w, alias_ok_w;
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

        descriptor_ok_w = (manifest_op_id_q == MANIFEST_SSM_CONV)
                        && (source_arity_q == 3'd2)
                        && (op_params_q == 128'b0)
                        && op_params_tail_zero_q && npu_required_q
                        && dst_shadow_private_q
                        && windows_generation_valid_q
                        && ((canonical_node_id_lo_q != 64'b0)
                            || (canonical_node_id_hi_q != 64'b0))
                        && (src0_dtype_q == MANIFEST_F32)
                        && (src0_flags_q == 32'd16)
                        && (src0_view_off_q == 64'b0)
                        && (src0_ne0_q == 32'd4)
                        && (src0_ne1_q == 32'd6144)
                        && (src0_ne2_q == 32'd1)
                        && (src0_ne3_q == 32'd1)
                        && (src0_nb0_q == 64'd4)
                        && (src0_nb1_q == 64'd16)
                        && (src0_nb2_q == 64'd98304)
                        && (src0_nb3_q == 64'd98304)
                        && (src1_dtype_q == MANIFEST_F32)
                        && (src1_flags_q == 32'd0)
                        && (src1_view_off_q == 64'b0)
                        && (src1_ne0_q == 32'd4)
                        && (src1_ne1_q == 32'd6144)
                        && (src1_ne2_q == 32'd1)
                        && (src1_ne3_q == 32'd1)
                        && (src1_nb0_q == 64'd4)
                        && (src1_nb1_q == 64'd16)
                        && (src1_nb2_q == 64'd98304)
                        && (src1_nb3_q == 64'd98304)
                        && (dst_dtype_q == MANIFEST_F32)
                        && (dst_flags_q == 32'd16)
                        && (dst_view_off_q == 64'b0)
                        && (dst_ne0_q == 32'd6144)
                        && (dst_ne1_q == 32'd1)
                        && (dst_ne2_q == 32'd1)
                        && (dst_ne3_q == 32'd1)
                        && (dst_nb0_q == 64'd4)
                        && (dst_nb1_q == 64'd24576)
                        && (dst_nb2_q == 64'd24576)
                        && (dst_nb3_q == 64'd24576);
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

    reg [127:0] runtime_read_addr_w, runtime_read_end_w;
    reg [127:0] runtime_read_window_start_w, runtime_read_window_end_w;
    reg [1:0] runtime_read_kind_w;
    reg runtime_read_ok_w;
    reg [127:0] runtime_write_addr_w, runtime_write_end_w;
    reg [127:0] runtime_write_phys_start_w, runtime_write_phys_end_w;
    reg [127:0] runtime_align_w;
    reg runtime_write_ok_w;
    always @(*) begin
        runtime_read_kind_w = (read_step_q < 3'd2) ? 2'd0 : 2'd1;
        if (runtime_read_kind_w == 2'd0) begin
            runtime_read_addr_w = {64'b0, src0_base_q}
                                + ({96'b0, output_index_q} * 128'd16)
                                + (read_step_q[0] ? 128'd8 : 128'd0);
            runtime_read_window_start_w = {64'b0, src0_window_base_q};
            runtime_read_window_end_w = src0_window_end_w;
        end else begin
            runtime_read_addr_w = {64'b0, src1_base_q}
                                + ({96'b0, output_index_q} * 128'd16)
                                + (read_step_q[0] ? 128'd8 : 128'd0);
            runtime_read_window_start_w = {64'b0, src1_window_base_q};
            runtime_read_window_end_w = src1_window_end_w;
        end
        runtime_read_end_w = runtime_read_addr_w + 128'd8;
        runtime_read_ok_w = (output_index_q < 32'd6144)
                          && (read_step_q < 3'd4)
                          && (runtime_read_addr_w[127:64] == 64'b0)
                          && (runtime_read_addr_w[2:0] == 3'b000)
                          && (runtime_read_addr_w
                              >= runtime_read_window_start_w)
                          && (runtime_read_end_w <= runtime_read_window_end_w);

        runtime_write_addr_w = {64'b0, dst_base_q}
                             + ({96'b0, output_index_q} * 128'd4);
        runtime_write_end_w = runtime_write_addr_w + 128'd4;
        runtime_write_phys_start_w = runtime_write_addr_w;
        runtime_write_phys_start_w[2:0] = 3'b000;
        runtime_align_w = runtime_write_end_w + 128'd7;
        runtime_align_w[2:0] = 3'b000;
        runtime_write_phys_end_w = runtime_align_w;
        runtime_write_ok_w = (output_index_q < 32'd6144)
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
            poisoned_q <= 1'b0;
            abort_hold_q <= 1'b0;
            stall_cycles_q <= 32'b0;
            drain_cycles_q <= 32'b0;
            abort_hold_cycles_q <= 32'b0;
            command_cycles_q <= 64'b0;
            active_cycles_q <= 64'b0;
            output_index_q <= 32'b0;
            read_step_q <= 3'b0;
            tap_index_q <= 2'b0;
            accumulator_q <= 32'b0;
            product_q <= 32'b0;
            output_q <= 32'b0;
            request_addr_q <= 64'b0;
            request_wdata_q <= 64'b0;
            request_wstrb_q <= 8'b0;
            request_write_q <= 1'b0;
            request_kind_q <= 2'b0;
            outstanding_q <= 1'b0;
            numeric_resident_q <= 1'b0;
            outputs_computed_q <= 64'b0;
            outputs_completed_q <= 64'b0;
            source0_words_completed_q <= 64'b0;
            source1_words_completed_q <= 64'b0;
            gmem_read_requests_q <= 64'b0;
            gmem_read_responses_q <= 64'b0;
            read_payload_bytes_q <= 64'b0;
            gmem_write_requests_q <= 64'b0;
            gmem_write_responses_q <= 64'b0;
            write_payload_bytes_q <= 64'b0;
            mul_requests_q <= 64'b0;
            mul_responses_q <= 64'b0;
            add_requests_q <= 64'b0;
            add_responses_q <= 64'b0;
            for (reset_index = 0; reset_index < 4;
                    reset_index = reset_index + 1) begin
                src0_buffer_q[reset_index] <= 32'b0;
                src1_buffer_q[reset_index] <= 32'b0;
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

            // Transport and numerical accounting are tied only to public
            // ready-valid handshakes.
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
                    if (!gmem_rsp_error_i && (state_q == ST_READ_WAIT)) begin
                        read_payload_bytes_q <= read_payload_bytes_q + 64'd8;
                        if (request_kind_q == 2'd0)
                            source0_words_completed_q
                                <= source0_words_completed_q + 64'd2;
                        else
                            source1_words_completed_q
                                <= source1_words_completed_q + 64'd2;
                    end
                end
            end
            if (numeric_req_fire_w) begin
                numeric_resident_q <= 1'b1;
                if (state_q == ST_MUL_REQ)
                    mul_requests_q <= mul_requests_q + 64'd1;
                else
                    add_requests_q <= add_requests_q + 64'd1;
            end
            if (numeric_rsp_fire_w && numeric_resident_q) begin
                numeric_resident_q <= 1'b0;
                numeric_flags_q <= numeric_flags_q | numeric_flags_w;
                if (state_q == ST_MUL_WAIT)
                    mul_responses_q <= mul_responses_q + 64'd1;
                else
                    add_responses_q <= add_responses_q + 64'd1;
            end

            if (command_timeout_hit_w) begin
                if (error_code_q == ERR_NONE)
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                if (gmem_request_state_w) begin
                    abort_hold_q <= 1'b1;
                end else if (outstanding_q) begin
                    state_q <= ST_GMEM_DRAIN;
                end else if (numeric_resident_q
                        || (state_q == ST_MUL_REQ)
                        || (state_q == ST_ADD_REQ)) begin
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
                            abort_hold_q <= 1'b0;
                            stall_cycles_q <= 32'b0;
                            command_cycles_q <= 64'b0;
                            active_cycles_q <= 64'b0;
                            output_index_q <= 32'b0;
                            read_step_q <= 3'b0;
                            tap_index_q <= 2'b0;
                            accumulator_q <= 32'b0;
                            product_q <= 32'b0;
                            output_q <= 32'b0;
                            outstanding_q <= 1'b0;
                            numeric_resident_q <= 1'b0;
                            outputs_computed_q <= 64'b0;
                            outputs_completed_q <= 64'b0;
                            source0_words_completed_q <= 64'b0;
                            source1_words_completed_q <= 64'b0;
                            gmem_read_requests_q <= 64'b0;
                            gmem_read_responses_q <= 64'b0;
                            read_payload_bytes_q <= 64'b0;
                            gmem_write_requests_q <= 64'b0;
                            gmem_write_responses_q <= 64'b0;
                            write_payload_bytes_q <= 64'b0;
                            mul_requests_q <= 64'b0;
                            mul_responses_q <= 64'b0;
                            add_requests_q <= 64'b0;
                            add_responses_q <= 64'b0;
                            state_q <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q <= ST_ERROR;
                        end else begin
                            profile_id_q <= PROFILE_SSM_CONV;
                            operator_census_q <= FROZEN_CENSUS;
                            profile_census_q <= FROZEN_CENSUS;
                            output_index_q <= 32'b0;
                            read_step_q <= 3'b0;
                            state_q <= ST_READ_PREP;
                        end
                    end

                    ST_READ_PREP: begin
                        if (!runtime_read_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_addr_q <= runtime_read_addr_w[63:0];
                            request_wdata_q <= 64'b0;
                            request_wstrb_q <= 8'b0;
                            request_write_q <= 1'b0;
                            request_kind_q <= runtime_read_kind_w;
                            state_q <= ST_READ_REQ;
                        end
                    end

                    ST_READ_REQ: begin
                        if (gmem_req_fire_w) begin
                            if (abort_hold_q) begin
                                abort_hold_q <= 1'b0;
                                state_q <= ST_GMEM_DRAIN;
                            end else begin
                                state_q <= ST_READ_WAIT;
                            end
                        end else if (stall_timeout_hit_w) begin
                            if (error_code_q == ERR_NONE)
                                error_code_q <= ERR_STALL_TIMEOUT;
                            abort_hold_q <= 1'b1;
                        end
                    end

                    ST_READ_WAIT: begin
                        if (gmem_rsp_fire_w) begin
                            if (gmem_rsp_error_i) begin
                                error_code_q <= ERR_GMEM_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                case (read_step_q)
                                    3'd0: begin
                                        src0_buffer_q[0]
                                            <= gmem_rsp_rdata_i[31:0];
                                        src0_buffer_q[1]
                                            <= gmem_rsp_rdata_i[63:32];
                                    end
                                    3'd1: begin
                                        src0_buffer_q[2]
                                            <= gmem_rsp_rdata_i[31:0];
                                        src0_buffer_q[3]
                                            <= gmem_rsp_rdata_i[63:32];
                                    end
                                    3'd2: begin
                                        src1_buffer_q[0]
                                            <= gmem_rsp_rdata_i[31:0];
                                        src1_buffer_q[1]
                                            <= gmem_rsp_rdata_i[63:32];
                                    end
                                    default: begin
                                        src1_buffer_q[2]
                                            <= gmem_rsp_rdata_i[31:0];
                                        src1_buffer_q[3]
                                            <= gmem_rsp_rdata_i[63:32];
                                    end
                                endcase
                                if (read_step_q == 3'd3) begin
                                    tap_index_q <= 2'b0;
                                    accumulator_q <= 32'b0;
                                    state_q <= ST_MUL_REQ;
                                end else begin
                                    read_step_q <= read_step_q + 3'd1;
                                    state_q <= ST_READ_PREP;
                                end
                            end
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q <= ST_GMEM_DRAIN;
                        end
                    end

                    ST_MUL_REQ: begin
                        if (numeric_req_fire_w) begin
                            state_q <= ST_MUL_WAIT;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_MUL_WAIT: begin
                        if (numeric_rsp_fire_w) begin
                            product_q <= numeric_result_w;
                            state_q <= ST_ADD_REQ;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_ADD_REQ: begin
                        if (numeric_req_fire_w) begin
                            state_q <= ST_ADD_WAIT;
                        end else if (stall_timeout_hit_w) begin
                            error_code_q <= ERR_NUMERIC;
                            state_q <= ST_CORE_RESET;
                        end
                    end

                    ST_ADD_WAIT: begin
                        if (numeric_rsp_fire_w) begin
                            accumulator_q <= numeric_result_w;
                            if (tap_index_q == 2'd3) begin
                                output_q <= numeric_result_w;
                                outputs_computed_q
                                    <= outputs_computed_q + 64'd1;
                                state_q <= ST_WRITE_PREP;
                            end else begin
                                tap_index_q <= tap_index_q + 2'd1;
                                state_q <= ST_MUL_REQ;
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
                            end else if (output_index_q == 32'd6143) begin
                                state_q <= ST_DONE;
                            end else begin
                                output_index_q <= output_index_q + 32'd1;
                                read_step_q <= 3'b0;
                                state_q <= ST_READ_PREP;
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
                        numeric_resident_q <= 1'b0;
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
                        else if (numeric_resident_q)
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
