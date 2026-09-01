`timescale 1ns/1ps
`default_nettype none

// Frozen-v5 SUM_ROWS transaction adapter.
//
// TensorNpuOrderedSumRows is the sole numerical and raw-GMEM implementation.
// This wrapper adds the dispatch identity, exact manifest-profile admission,
// R/R/W capability checks, and whole-command commit/census reporting.  GMEM
// writes target a transaction-private destination; only dst_commit_o permits
// the parent to publish that shadow after the Engine has completed every row.
module TensorNpuSumRowsWritebackAdapter #(
    parameter integer ENGINE_STALL_TIMEOUT_CYCLES = 512,
    parameter integer ENGINE_COMMAND_TIMEOUT_CYCLES = 8388608,
    parameter integer ENGINE_DRAIN_TIMEOUT_CYCLES = 1024,
    parameter integer ENGINE_ABORT_HOLD_TIMEOUT_CYCLES =
        ENGINE_DRAIN_TIMEOUT_CYCLES
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

    // SUM_ROWS has one semantic source.  src1 is the mandatory zero-byte,
    // aligned, read-only sentinel used by the common two-source transaction
    // envelope.
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
    output wire [4:0]   engine_error_code_o,
    output wire [4:0]   engine_flags_o,
    output wire         poisoned_o,

    output wire [63:0]  rows_reduced_o,
    output wire [63:0]  elements_processed_o,
    output wire [63:0]  reduction_operations_o,
    output wire [63:0]  results_generated_o,
    output wire [63:0]  gmem_read_requests_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_requests_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  widen_requests_o,
    output wire [63:0]  widen_responses_o,
    output wire [63:0]  add_requests_o,
    output wire [63:0]  add_responses_o,
    output wire [63:0]  narrow_requests_o,
    output wire [63:0]  narrow_responses_o,
    output wire [63:0]  engine_launches_o,
    output wire [63:0]  engine_terminals_o,
    output wire [63:0]  engine_active_cycles_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire         engine_outstanding_o,
    output wire         gmem_drain_o,

    output wire         engine_fault_valid_o,
    output wire [63:0]  engine_first_fault_cycle_o,
    output wire [127:0] engine_first_fault_coordinate_o,
    output wire [63:0]  engine_first_fault_gmem_addr_o
);

    localparam [31:0] KERNEL_REDUCE_F32 = 32'h514e0011;
    localparam [2:0]  REDUCE_SUM_ROWS = 3'd1;
    localparam [15:0] MANIFEST_SUM_ROWS = 16'd15;
    localparam [7:0]  MANIFEST_F32 = 8'd0;
    localparam [31:0] MANIFEST_FLAGS = 32'd16;
    localparam [7:0]  PROFILE_SUM_ROWS = 8'd0;
    localparam [7:0]  PROFILE_INVALID = 8'hff;
    localparam [31:0] FROZEN_CENSUS = 32'd36;

    localparam [3:0] ST_IDLE         = 4'd0;
    localparam [3:0] ST_PREFLIGHT    = 4'd1;
    localparam [3:0] ST_ENGINE_START = 4'd2;
    localparam [3:0] ST_ENGINE_RUN   = 4'd3;
    localparam [3:0] ST_ENGINE_DRAIN = 4'd4;
    localparam [3:0] ST_DONE         = 4'd5;
    localparam [3:0] ST_ERROR        = 4'd6;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_DESCRIPTOR      = 5'd1;
    localparam [4:0] ERR_SOURCE0_WINDOW  = 5'd2;
    localparam [4:0] ERR_SOURCE1_SENTINEL = 5'd3;
    localparam [4:0] ERR_DEST_WINDOW     = 5'd4;
    localparam [4:0] ERR_ALIAS           = 5'd5;
    localparam [4:0] ERR_ENGINE          = 5'd6;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd7;

    reg [3:0] state_q;
    reg [2:0] reduce_op_q, source_arity_q;
    reg [15:0] manifest_op_id_q;
    reg [127:0] op_params_q;
    reg op_params_tail_zero_q, npu_required_q;
    reg [63:0] command_id_q, canonical_node_id_lo_q;
    reg [63:0] canonical_node_id_hi_q;
    reg dst_shadow_private_q, windows_generation_valid_q;

    reg [7:0] src0_dtype_q;
    reg [31:0] src0_flags_q;
    reg [63:0] src0_view_off_q;
    reg [31:0] src0_ne0_q, src0_ne1_q, src0_ne2_q, src0_ne3_q;
    reg [63:0] src0_base_q;
    reg [63:0] src0_nb0_q, src0_nb1_q, src0_nb2_q, src0_nb3_q;
    reg [63:0] src1_base_q;
    reg [63:0] src1_nb0_q, src1_nb1_q, src1_nb2_q, src1_nb3_q;
    reg [7:0] dst_dtype_q;
    reg [31:0] dst_flags_q;
    reg [63:0] dst_view_off_q;
    reg [31:0] dst_ne0_q, dst_ne1_q, dst_ne2_q, dst_ne3_q;
    reg [63:0] dst_base_q;
    reg [63:0] dst_nb0_q, dst_nb1_q, dst_nb2_q, dst_nb3_q;

    reg [63:0] src0_window_base_q, src0_window_bytes_q;
    reg src0_window_read_q, src0_window_write_q;
    reg [63:0] src1_window_base_q, src1_window_bytes_q;
    reg src1_window_read_q, src1_window_write_q;
    reg [63:0] dst_window_base_q, dst_window_bytes_q;
    reg dst_window_read_q, dst_window_write_q;

    reg [7:0] profile_id_q;
    reg [31:0] operator_census_q, profile_census_q;
    reg [4:0] error_code_q, engine_error_code_q, engine_flags_q;
    reg outstanding_q, outstanding_write_q, engine_resident_q;
    reg drain_latched_q;
    reg [63:0] active_cycles_q;
    reg [63:0] rows_reduced_q, elements_processed_q;
    reg [63:0] reduction_operations_q, results_generated_q;
    reg [63:0] gmem_read_requests_q, gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_requests_q, gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;
    reg [63:0] widen_requests_q, widen_responses_q;
    reg [63:0] add_requests_q, add_responses_q;
    reg [63:0] narrow_requests_q, narrow_responses_q;
    reg [63:0] engine_launches_q, engine_terminals_q;
    reg [63:0] engine_active_cycles_q;

    wire engine_ready_w, engine_busy_w;
    wire engine_gmem_req_valid_w, engine_gmem_req_write_w;
    wire [63:0] engine_gmem_req_addr_w, engine_gmem_req_wdata_w;
    wire [7:0] engine_gmem_req_wstrb_w;
    wire engine_gmem_rsp_ready_w;
    wire engine_done_w, engine_error_w, engine_poisoned_w;
    wire [4:0] engine_error_code_w, engine_flags_w;
    wire engine_fault_valid_w;
    wire [63:0] engine_first_fault_cycle_w;
    wire [127:0] engine_first_fault_coordinate_w;
    wire [63:0] engine_first_fault_gmem_addr_w;
    wire [63:0] engine_rows_w, engine_elements_w;
    wire [63:0] engine_read_requests_w, engine_read_responses_w;
    wire [63:0] engine_write_requests_w, engine_write_responses_w;
    wire [63:0] engine_widen_requests_w, engine_widen_responses_w;
    wire [63:0] engine_add_requests_w, engine_add_responses_w;
    wire [63:0] engine_narrow_requests_w, engine_narrow_responses_w;
    wire [63:0] engine_active_cycles_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE) && engine_ready_w
                   && !engine_poisoned_w;
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
    assign completion_reduce_op_o = completion_valid_o ? reduce_op_q : 3'b0;
    assign completion_manifest_op_id_o = completion_valid_o
                                           ? manifest_op_id_q : 16'b0;
    assign completion_source_arity_o = completion_valid_o
                                         ? source_arity_q : 3'b0;
    assign completion_profile_id_o = completion_valid_o ? profile_id_q : 8'b0;
    assign completion_kernel_id_o = completion_valid_o
                                      ? KERNEL_REDUCE_F32 : 32'b0;
    assign completion_operator_census_o = completion_valid_o
                                            ? operator_census_q : 32'b0;
    assign completion_profile_census_o = completion_valid_o
                                           ? profile_census_q : 32'b0;
    assign error_code_o = error_code_q;
    assign engine_error_code_o = engine_error_code_q;
    assign engine_flags_o = engine_flags_q;
    assign poisoned_o = !rst_i && engine_poisoned_w;

    assign rows_reduced_o = rows_reduced_q;
    assign elements_processed_o = elements_processed_q;
    assign reduction_operations_o = reduction_operations_q;
    assign results_generated_o = results_generated_q;
    assign gmem_read_requests_o = gmem_read_requests_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_requests_o = gmem_write_requests_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign widen_requests_o = widen_requests_q;
    assign widen_responses_o = widen_responses_q;
    assign add_requests_o = add_requests_q;
    assign add_responses_o = add_responses_q;
    assign narrow_requests_o = narrow_requests_q;
    assign narrow_responses_o = narrow_responses_q;
    assign engine_launches_o = engine_launches_q;
    assign engine_terminals_o = engine_terminals_q;
    assign engine_active_cycles_o = engine_active_cycles_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign engine_outstanding_o = engine_resident_q;
    assign gmem_drain_o = !rst_i && outstanding_q
                        && (drain_latched_q || engine_fault_valid_w
                            || (state_q == ST_ENGINE_DRAIN));

    assign engine_fault_valid_o = engine_fault_valid_w;
    assign engine_first_fault_cycle_o = engine_first_fault_cycle_w;
    assign engine_first_fault_coordinate_o = engine_first_fault_coordinate_w;
    assign engine_first_fault_gmem_addr_o = engine_first_fault_gmem_addr_w;

    wire start_fire_w;
    wire engine_start_w;
    wire engine_terminal_w;
    wire engine_gmem_req_fire_w;
    wire gmem_rsp_fire_w;
    wire wrapper_drain_w;
    assign start_fire_w = start_i && ready_o;
    assign engine_start_w = (state_q == ST_ENGINE_START) && engine_ready_w;
    assign engine_terminal_w = engine_done_w || engine_error_w;
    assign engine_gmem_req_fire_w = engine_gmem_req_valid_w
                                  && gmem_req_ready_i;
    assign wrapper_drain_w = (state_q == ST_ENGINE_DRAIN) && outstanding_q;

    assign gmem_req_valid_o = engine_gmem_req_valid_w;
    assign gmem_req_write_o = engine_gmem_req_write_w;
    assign gmem_req_addr_o = engine_gmem_req_addr_w;
    assign gmem_req_wdata_o = engine_gmem_req_wdata_w;
    assign gmem_req_wstrb_o = engine_gmem_req_wstrb_w;
    assign gmem_rsp_ready_o = !rst_i
                            && (engine_gmem_rsp_ready_w || wrapper_drain_w);
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;

    // The frozen descriptor is one exact profile.  Runtime supplies tensor
    // data pointers after applying the manifest view offset, while the
    // descriptor view fields remain zero and are checked independently.
    reg descriptor_ok_w;
    reg src0_window_ok_w, src1_sentinel_ok_w, dst_window_ok_w;
    reg alias_ok_w;
    reg [4:0] preflight_error_w;
    reg [127:0] src0_last_w, src0_semantic_end_w;
    reg [127:0] dst_last_w, dst_semantic_end_w;
    reg [127:0] src0_window_end_w, src1_window_end_w, dst_window_end_w;
    reg [127:0] src0_phys_start_w, src0_phys_end_w;
    reg [127:0] dst_phys_start_w, dst_phys_end_w;
    reg [127:0] align_tmp_w;
    always @(*) begin
        src0_last_w = ({96'b0, (src0_ne0_q - 32'd1)}
                       * {64'b0, src0_nb0_q})
                    + ({96'b0, (src0_ne1_q - 32'd1)}
                       * {64'b0, src0_nb1_q})
                    + ({96'b0, (src0_ne2_q - 32'd1)}
                       * {64'b0, src0_nb2_q})
                    + ({96'b0, (src0_ne3_q - 32'd1)}
                       * {64'b0, src0_nb3_q});
        dst_last_w = ({96'b0, (dst_ne0_q - 32'd1)}
                      * {64'b0, dst_nb0_q})
                   + ({96'b0, (dst_ne1_q - 32'd1)}
                      * {64'b0, dst_nb1_q})
                   + ({96'b0, (dst_ne2_q - 32'd1)}
                      * {64'b0, dst_nb2_q})
                   + ({96'b0, (dst_ne3_q - 32'd1)}
                      * {64'b0, dst_nb3_q});
        src0_semantic_end_w = {64'b0, src0_base_q} + src0_last_w + 128'd4;
        dst_semantic_end_w = {64'b0, dst_base_q} + dst_last_w + 128'd4;
        src0_window_end_w = {64'b0, src0_window_base_q}
                          + {64'b0, src0_window_bytes_q};
        src1_window_end_w = {64'b0, src1_window_base_q}
                          + {64'b0, src1_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};

        src0_phys_start_w = {64'b0, src0_base_q};
        src0_phys_start_w[2:0] = 3'b000;
        align_tmp_w = src0_semantic_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b000;
        src0_phys_end_w = align_tmp_w;
        dst_phys_start_w = {64'b0, dst_base_q};
        dst_phys_start_w[2:0] = 3'b000;
        align_tmp_w = dst_semantic_end_w + 128'd7;
        align_tmp_w[2:0] = 3'b000;
        dst_phys_end_w = align_tmp_w;

        descriptor_ok_w = (reduce_op_q == REDUCE_SUM_ROWS)
                        && (manifest_op_id_q == MANIFEST_SUM_ROWS)
                        && (source_arity_q == 3'd1)
                        && (op_params_q == 128'b0)
                        && op_params_tail_zero_q
                        && npu_required_q
                        && dst_shadow_private_q
                        && windows_generation_valid_q
                        && ((canonical_node_id_lo_q != 64'b0)
                            || (canonical_node_id_hi_q != 64'b0))
                        && (src0_dtype_q == MANIFEST_F32)
                        && (src0_flags_q == MANIFEST_FLAGS)
                        && (src0_view_off_q == 64'b0)
                        && (src0_ne0_q == 32'd128)
                        && (src0_ne1_q == 32'd128)
                        && (src0_ne2_q == 32'd16)
                        && (src0_ne3_q == 32'd1)
                        && (src0_nb0_q == 64'd4)
                        && (src0_nb1_q == 64'd512)
                        && (src0_nb2_q == 64'd65536)
                        && (src0_nb3_q == 64'd1048576)
                        && (dst_dtype_q == MANIFEST_F32)
                        && (dst_flags_q == MANIFEST_FLAGS)
                        && (dst_view_off_q == 64'b0)
                        && (dst_ne0_q == 32'd1)
                        && (dst_ne1_q == 32'd128)
                        && (dst_ne2_q == 32'd16)
                        && (dst_ne3_q == 32'd1)
                        && (dst_nb0_q == 64'd4)
                        && (dst_nb1_q == 64'd4)
                        && (dst_nb2_q == 64'd512)
                        && (dst_nb3_q == 64'd8192);

        src0_window_ok_w = (src0_window_end_w[127:64] == 64'b0)
                         && (src0_semantic_end_w[127:64] == 64'b0)
                         && (src0_phys_start_w[127:64] == 64'b0)
                         && (src0_phys_end_w[127:64] == 64'b0)
                         && (src0_base_q[2:0] == 3'b000)
                         && (src0_window_base_q[2:0] == 3'b000)
                         && (src0_window_bytes_q[2:0] == 3'b000)
                         && src0_window_read_q && !src0_window_write_q
                         && (src0_window_bytes_q != 64'b0)
                         && (src0_phys_start_w
                             >= {64'b0, src0_window_base_q})
                         && (src0_phys_end_w <= src0_window_end_w);
        src1_sentinel_ok_w = (src1_window_end_w[127:64] == 64'b0)
                           && (src1_base_q == src1_window_base_q)
                           && (src1_base_q[2:0] == 3'b000)
                           && (src1_window_bytes_q == 64'b0)
                           && src1_window_read_q && !src1_window_write_q
                           && (src1_nb0_q == 64'b0)
                           && (src1_nb1_q == 64'b0)
                           && (src1_nb2_q == 64'b0)
                           && (src1_nb3_q == 64'b0);
        dst_window_ok_w = (dst_window_end_w[127:64] == 64'b0)
                        && (dst_semantic_end_w[127:64] == 64'b0)
                        && (dst_phys_start_w[127:64] == 64'b0)
                        && (dst_phys_end_w[127:64] == 64'b0)
                        && (dst_base_q[1:0] == 2'b00)
                        && (dst_window_base_q[2:0] == 3'b000)
                        && (dst_window_bytes_q[2:0] == 3'b000)
                        && !dst_window_read_q && dst_window_write_q
                        && (dst_window_bytes_q != 64'b0)
                        && (dst_phys_start_w >= {64'b0, dst_window_base_q})
                        && (dst_phys_end_w <= dst_window_end_w);
        alias_ok_w = (src0_phys_end_w <= dst_phys_start_w)
                  || (dst_phys_end_w <= src0_phys_start_w);

        if (!descriptor_ok_w)
            preflight_error_w = ERR_DESCRIPTOR;
        else if (!src0_window_ok_w)
            preflight_error_w = ERR_SOURCE0_WINDOW;
        else if (!src1_sentinel_ok_w)
            preflight_error_w = ERR_SOURCE1_SENTINEL;
        else if (!dst_window_ok_w)
            preflight_error_w = ERR_DEST_WINDOW;
        else if (!alias_ok_w)
            preflight_error_w = ERR_ALIAS;
        else
            preflight_error_w = ERR_NONE;
    end

    wire [63:0] engine_src_view_off_w;
    wire [63:0] engine_dst_view_off_w;
    wire [63:0] engine_gmem_floor_w;
    wire [63:0] engine_gmem_limit_w;
    assign engine_src_view_off_w = src0_base_q - src0_window_base_q;
    assign engine_dst_view_off_w = dst_base_q - dst_window_base_q;
    assign engine_gmem_floor_w = (src0_window_base_q < dst_window_base_q)
                               ? src0_window_base_q : dst_window_base_q;
    assign engine_gmem_limit_w = (src0_window_end_w[63:0]
                                  > dst_window_end_w[63:0])
                               ? src0_window_end_w[63:0]
                               : dst_window_end_w[63:0];

    wire [4:0] unused_first_fault_flags_w;
    wire [63:0] unused_first_fault_request_events_w;
    wire [63:0] unused_first_fault_response_events_w;
    wire [31:0] unused_first_fault_txn_tag_w;
    wire unused_first_fault_generation_w;
    wire [2:0] unused_first_fault_resource_w;
    wire [2:0] unused_first_fault_owner_type_w;
    wire unused_first_fault_owner_valid_w;
    wire unused_first_fault_owner_generation_w;
    wire [31:0] unused_first_fault_owner_row_w;
    wire [31:0] unused_first_fault_owner_index_w;

    TensorNpuOrderedSumRows #(
        .NE0(128),
        .NE1(128),
        .NE2(16),
        .NE3(1),
        .STALL_TIMEOUT_CYCLES(ENGINE_STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES(ENGINE_COMMAND_TIMEOUT_CYCLES),
        .DRAIN_TIMEOUT_CYCLES(ENGINE_DRAIN_TIMEOUT_CYCLES),
        .ABORT_HOLD_TIMEOUT_CYCLES(ENGINE_ABORT_HOLD_TIMEOUT_CYCLES)
    ) u_ordered_sum_rows (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(engine_start_w),
        .txn_tag_i(command_id_q[31:0]),
        .ready_o(engine_ready_w),
        .busy_o(engine_busy_w),
        .dtype_i(8'h01),
        .profile_i(8'h01),
        .rounding_mode_i(3'b000),
        .denormal_mode_i(2'b00),
        .nan_policy_i(2'b00),
        .dst_shadow_private_i(1'b1),
        .reserved_i(32'b0),
        .op_params_i(128'b0),
        .gmem_floor_i(engine_gmem_floor_w),
        .gmem_limit_i(engine_gmem_limit_w),
        .src_region_base_i(src0_window_base_q),
        .src_region_size_i(src0_window_bytes_q),
        .src_view_off_i(engine_src_view_off_w),
        .src_ne0_i(src0_ne0_q),
        .src_ne1_i(src0_ne1_q),
        .src_ne2_i(src0_ne2_q),
        .src_ne3_i(src0_ne3_q),
        .src_nb0_i(src0_nb0_q),
        .src_nb1_i(src0_nb1_q),
        .src_nb2_i(src0_nb2_q),
        .src_nb3_i(src0_nb3_q),
        .dst_region_base_i(dst_window_base_q),
        .dst_region_size_i(dst_window_bytes_q),
        .dst_view_off_i(engine_dst_view_off_w),
        .dst_ne0_i(dst_ne0_q),
        .dst_ne1_i(dst_ne1_q),
        .dst_ne2_i(dst_ne2_q),
        .dst_ne3_i(dst_ne3_q),
        .dst_nb0_i(dst_nb0_q),
        .dst_nb1_i(dst_nb1_q),
        .dst_nb2_i(dst_nb2_q),
        .dst_nb3_i(dst_nb3_q),
        .gmem_req_valid_o(engine_gmem_req_valid_w),
        .gmem_req_ready_i(gmem_req_ready_i),
        .gmem_req_write_o(engine_gmem_req_write_w),
        .gmem_req_addr_o(engine_gmem_req_addr_w),
        .gmem_req_wdata_o(engine_gmem_req_wdata_w),
        .gmem_req_wstrb_o(engine_gmem_req_wstrb_w),
        .gmem_rsp_valid_i(gmem_rsp_valid_i),
        .gmem_rsp_ready_o(engine_gmem_rsp_ready_w),
        .gmem_rsp_rdata_i(gmem_rsp_rdata_i),
        .gmem_rsp_error_i(gmem_rsp_error_i),
        .done_o(engine_done_w),
        .error_o(engine_error_w),
        .error_code_o(engine_error_code_w),
        .flags_o(engine_flags_w),
        .poisoned_o(engine_poisoned_w),
        .fault_valid_o(engine_fault_valid_w),
        .first_fault_cycle_o(engine_first_fault_cycle_w),
        .first_fault_coordinate_o(engine_first_fault_coordinate_w),
        .first_fault_gmem_addr_o(engine_first_fault_gmem_addr_w),
        .first_fault_flags_o(unused_first_fault_flags_w),
        .first_fault_request_events_o(unused_first_fault_request_events_w),
        .first_fault_response_events_o(unused_first_fault_response_events_w),
        .first_fault_txn_tag_o(unused_first_fault_txn_tag_w),
        .first_fault_generation_o(unused_first_fault_generation_w),
        .first_fault_resource_o(unused_first_fault_resource_w),
        .first_fault_owner_type_o(unused_first_fault_owner_type_w),
        .first_fault_owner_valid_o(unused_first_fault_owner_valid_w),
        .first_fault_owner_generation_o(
            unused_first_fault_owner_generation_w),
        .first_fault_owner_row_o(unused_first_fault_owner_row_w),
        .first_fault_owner_index_o(unused_first_fault_owner_index_w),
        .rows_reduced_o(engine_rows_w),
        .elements_processed_o(engine_elements_w),
        .gmem_read_requests_o(engine_read_requests_w),
        .gmem_read_responses_o(engine_read_responses_w),
        .gmem_write_requests_o(engine_write_requests_w),
        .gmem_write_responses_o(engine_write_responses_w),
        .widen_requests_o(engine_widen_requests_w),
        .widen_responses_o(engine_widen_responses_w),
        .add_requests_o(engine_add_requests_w),
        .add_responses_o(engine_add_responses_w),
        .narrow_requests_o(engine_narrow_requests_w),
        .narrow_responses_o(engine_narrow_responses_w),
        .active_cycles_o(engine_active_cycles_w)
    );

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
            src0_dtype_q <= 8'b0;
            src0_flags_q <= 32'b0;
            src0_view_off_q <= 64'b0;
            src0_ne0_q <= 32'b0;
            src0_ne1_q <= 32'b0;
            src0_ne2_q <= 32'b0;
            src0_ne3_q <= 32'b0;
            src0_base_q <= 64'b0;
            src0_nb0_q <= 64'b0;
            src0_nb1_q <= 64'b0;
            src0_nb2_q <= 64'b0;
            src0_nb3_q <= 64'b0;
            src1_base_q <= 64'b0;
            src1_nb0_q <= 64'b0;
            src1_nb1_q <= 64'b0;
            src1_nb2_q <= 64'b0;
            src1_nb3_q <= 64'b0;
            dst_dtype_q <= 8'b0;
            dst_flags_q <= 32'b0;
            dst_view_off_q <= 64'b0;
            dst_ne0_q <= 32'b0;
            dst_ne1_q <= 32'b0;
            dst_ne2_q <= 32'b0;
            dst_ne3_q <= 32'b0;
            dst_base_q <= 64'b0;
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
            engine_error_code_q <= 5'b0;
            engine_flags_q <= 5'b0;
            outstanding_q <= 1'b0;
            outstanding_write_q <= 1'b0;
            engine_resident_q <= 1'b0;
            drain_latched_q <= 1'b0;
            active_cycles_q <= 64'b0;
            rows_reduced_q <= 64'b0;
            elements_processed_q <= 64'b0;
            reduction_operations_q <= 64'b0;
            results_generated_q <= 64'b0;
            gmem_read_requests_q <= 64'b0;
            gmem_read_responses_q <= 64'b0;
            read_payload_bytes_q <= 64'b0;
            gmem_write_requests_q <= 64'b0;
            gmem_write_responses_q <= 64'b0;
            write_payload_bytes_q <= 64'b0;
            widen_requests_q <= 64'b0;
            widen_responses_q <= 64'b0;
            add_requests_q <= 64'b0;
            add_responses_q <= 64'b0;
            narrow_requests_q <= 64'b0;
            narrow_responses_q <= 64'b0;
            engine_launches_q <= 64'b0;
            engine_terminals_q <= 64'b0;
            engine_active_cycles_q <= 64'b0;
        end else begin
            if (state_q != ST_IDLE)
                active_cycles_q <= active_cycles_q + 64'd1;

            if (engine_gmem_req_fire_w) begin
                outstanding_q <= 1'b1;
                outstanding_write_q <= engine_gmem_req_write_w;
                if (engine_gmem_req_write_w)
                    gmem_write_requests_q <= gmem_write_requests_q + 64'd1;
                else
                    gmem_read_requests_q <= gmem_read_requests_q + 64'd1;
            end
            if (gmem_rsp_fire_w && outstanding_q) begin
                outstanding_q <= 1'b0;
                if (outstanding_write_q) begin
                    gmem_write_responses_q <= gmem_write_responses_q + 64'd1;
                    if (!gmem_rsp_error_i && !drain_latched_q
                            && !engine_fault_valid_w)
                        write_payload_bytes_q <= write_payload_bytes_q + 64'd4;
                end else begin
                    gmem_read_responses_q <= gmem_read_responses_q + 64'd1;
                    if (!gmem_rsp_error_i && !drain_latched_q
                            && !engine_fault_valid_w)
                        read_payload_bytes_q <= read_payload_bytes_q + 64'd8;
                end
                outstanding_write_q <= 1'b0;
                drain_latched_q <= 1'b0;
            end else if (outstanding_q && engine_fault_valid_w) begin
                drain_latched_q <= 1'b1;
            end

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
                        operator_census_q <= (reduce_op_i == REDUCE_SUM_ROWS)
                                           ? FROZEN_CENSUS : 32'b0;
                        profile_census_q <= 32'b0;
                        error_code_q <= ERR_NONE;
                        engine_error_code_q <= 5'b0;
                        engine_flags_q <= 5'b0;
                        outstanding_q <= 1'b0;
                        outstanding_write_q <= 1'b0;
                        engine_resident_q <= 1'b0;
                        drain_latched_q <= 1'b0;
                        active_cycles_q <= 64'b0;
                        rows_reduced_q <= 64'b0;
                        elements_processed_q <= 64'b0;
                        reduction_operations_q <= 64'b0;
                        results_generated_q <= 64'b0;
                        gmem_read_requests_q <= 64'b0;
                        gmem_read_responses_q <= 64'b0;
                        read_payload_bytes_q <= 64'b0;
                        gmem_write_requests_q <= 64'b0;
                        gmem_write_responses_q <= 64'b0;
                        write_payload_bytes_q <= 64'b0;
                        widen_requests_q <= 64'b0;
                        widen_responses_q <= 64'b0;
                        add_requests_q <= 64'b0;
                        add_responses_q <= 64'b0;
                        narrow_requests_q <= 64'b0;
                        narrow_responses_q <= 64'b0;
                        engine_launches_q <= 64'b0;
                        engine_terminals_q <= 64'b0;
                        engine_active_cycles_q <= 64'b0;
                        state_q <= ST_PREFLIGHT;
                    end
                end

                ST_PREFLIGHT: begin
                    if (preflight_error_w != ERR_NONE) begin
                        error_code_q <= preflight_error_w;
                        state_q <= ST_ERROR;
                    end else begin
                        profile_id_q <= PROFILE_SUM_ROWS;
                        operator_census_q <= FROZEN_CENSUS;
                        profile_census_q <= FROZEN_CENSUS;
                        state_q <= ST_ENGINE_START;
                    end
                end

                ST_ENGINE_START: begin
                    if (engine_start_w) begin
                        engine_resident_q <= 1'b1;
                        engine_launches_q <= 64'd1;
                        state_q <= ST_ENGINE_RUN;
                    end
                end

                ST_ENGINE_RUN: begin
                    if (engine_terminal_w) begin
                        rows_reduced_q <= engine_rows_w;
                        elements_processed_q <= engine_elements_w;
                        reduction_operations_q <= engine_add_responses_w;
                        results_generated_q <= engine_narrow_responses_w;
                        widen_requests_q <= engine_widen_requests_w;
                        widen_responses_q <= engine_widen_responses_w;
                        add_requests_q <= engine_add_requests_w;
                        add_responses_q <= engine_add_responses_w;
                        narrow_requests_q <= engine_narrow_requests_w;
                        narrow_responses_q <= engine_narrow_responses_w;
                        engine_active_cycles_q <= engine_active_cycles_w;
                        engine_flags_q <= engine_flags_w;
                        engine_error_code_q <= engine_error_code_w;
                        engine_terminals_q <= 64'd1;
                        engine_resident_q <= 1'b0;
                        if (engine_done_w && !engine_error_w
                                && !outstanding_q) begin
                            state_q <= ST_DONE;
                        end else begin
                            error_code_q <= engine_error_w
                                          ? ERR_ENGINE
                                          : ERR_INTERNAL_STATE;
                            if (outstanding_q)
                                state_q <= ST_ENGINE_DRAIN;
                            else
                                state_q <= ST_ERROR;
                        end
                    end
                end

                ST_ENGINE_DRAIN: begin
                    if (gmem_rsp_fire_w && outstanding_q)
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
                    error_code_q <= ERR_INTERNAL_STATE;
                    if (outstanding_q)
                        state_q <= ST_ENGINE_DRAIN;
                    else
                        state_q <= ST_ERROR;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
