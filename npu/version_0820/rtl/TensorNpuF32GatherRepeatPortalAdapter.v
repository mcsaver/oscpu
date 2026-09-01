`timescale 1ns/1ps
`default_nettype none

// Transactional wide raw32 portal owner for the canonical P06 GET_ROWS_F32
// and P12 REPEAT_F32 profiles.  The host side is only a byte-copy engine:
// every active read lane returns the four bytes at req_addr, and every active
// write lane stores req_wdata at req_addr.  Index decode, tensor coordinates,
// broadcast selection, range checks and publication remain entirely in RTL.
//
// The descriptor, capability, identity and fail-closed semantics intentionally
// match TensorNpuF32GatherRepeatAdapter.  Its aligned-eight-byte physical
// capability proof is retained as a compatibility boundary even though this
// portal transfers exact four-byte semantic words.  There is at most one
// accepted portal group outstanding.  Every accepted request, including a
// timed-out request, is drained before a terminal pulse is exposed.
module TensorNpuF32GatherRepeatPortalAdapter #(
    parameter integer LANES = 16,
    parameter integer MAX_ELEMENTS = 262144,
    parameter integer MAX_INDICES  = 16,
    parameter integer MAX_REPEAT   = 128,
    parameter integer MAX_OUTER    = 16,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd512,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd1000000000
) (
    input  wire                       clk_i,
    input  wire                       rst_i,

    input  wire                       start_i,
    output wire                       ready_o,
    output wire                       busy_o,
    input  wire                       operation_i,
    input  wire                       npu_required_i,
    input  wire [63:0]                command_id_i,
    input  wire [63:0]                canonical_node_id_lo_i,
    input  wire [63:0]                canonical_node_id_hi_i,
    input  wire                       dst_shadow_private_i,
    input  wire                       windows_generation_valid_i,

    input  wire [63:0]                src_base_i,
    input  wire [63:0]                index_base_i,
    input  wire [63:0]                dst_base_i,
    input  wire [31:0]                element_count_i,
    input  wire [31:0]                source_row_count_i,
    input  wire [31:0]                index_count_i,
    input  wire [31:0]                outer_count_i,
    input  wire [31:0]                repeat_count_i,
    input  wire [63:0]                src_row_stride_i,
    input  wire [63:0]                index_stride_i,
    input  wire [63:0]                dst_row_stride_i,
    input  wire [63:0]                dst_outer_stride_i,

    input  wire [63:0]                src_window_base_i,
    input  wire [63:0]                src_window_bytes_i,
    input  wire                       src_window_read_i,
    input  wire                       src_window_write_i,
    input  wire [63:0]                index_window_base_i,
    input  wire [63:0]                index_window_bytes_i,
    input  wire                       index_window_read_i,
    input  wire                       index_window_write_i,
    input  wire [63:0]                dst_window_base_i,
    input  wire [63:0]                dst_window_bytes_i,
    input  wire                       dst_window_read_i,
    input  wire                       dst_window_write_i,

    // Drop-in raw-GMEM compatibility surface.  The portal implementation owns
    // no raw-GMEM transaction, so every output and ledger below is constant 0.
    output wire                       gmem_req_valid_o,
    input  wire                       gmem_req_ready_i,
    output wire                       gmem_req_write_o,
    output wire [63:0]                gmem_req_addr_o,
    output wire [63:0]                gmem_req_wdata_o,
    output wire [7:0]                 gmem_req_wstrb_o,
    input  wire                       gmem_rsp_valid_i,
    output wire                       gmem_rsp_ready_o,
    input  wire [63:0]                gmem_rsp_rdata_i,
    input  wire                       gmem_rsp_error_i,

    // Lane k occupies [k*W +: W].  A single group is uniformly read or write.
    output wire                       portal_req_valid_o,
    input  wire                       portal_req_ready_i,
    output wire                       portal_req_write_o,
    output wire [LANES-1:0]           portal_req_mask_o,
    output wire [(LANES*64)-1:0]      portal_req_addr_o,
    output wire [(LANES*32)-1:0]      portal_req_wdata_o,
    input  wire                       portal_rsp_valid_i,
    output wire                       portal_rsp_ready_o,
    input  wire [LANES-1:0]           portal_rsp_mask_i,
    input  wire [(LANES*32)-1:0]      portal_rsp_rdata_i,
    input  wire                       portal_rsp_error_i,

    output wire                       completion_valid_o,
    output wire                       dst_commit_o,
    output wire [63:0]                completion_command_id_o,
    output wire [63:0]                completion_canonical_node_id_lo_o,
    output wire [63:0]                completion_canonical_node_id_hi_o,
    output wire                       completion_npu_required_o,
    output wire                       completion_operation_o,
    output wire [31:0]                completion_kernel_id_o,
    output wire                       done_o,
    output wire                       error_o,
    output wire [4:0]                 error_code_o,

    output wire [63:0]                indices_completed_o,
    output wire [63:0]                source_words_completed_o,
    output wire [63:0]                elements_completed_o,

    output wire [63:0]                portal_request_groups_o,
    output wire [63:0]                portal_response_groups_o,
    output wire [63:0]                portal_read_groups_o,
    output wire [63:0]                portal_write_groups_o,
    output wire [63:0]                portal_read_words_o,
    output wire [63:0]                portal_write_words_o,
    output wire [63:0]                portal_read_bytes_o,
    output wire [63:0]                portal_write_bytes_o,
    output wire                       portal_outstanding_o,

    output wire [63:0]                gmem_read_beats_o,
    output wire [63:0]                gmem_read_responses_o,
    output wire [63:0]                read_payload_bytes_o,
    output wire [63:0]                gmem_write_beats_o,
    output wire [63:0]                gmem_write_responses_o,
    output wire [63:0]                write_payload_bytes_o,
    output wire [63:0]                expected_gmem_read_bytes_o,
    output wire [63:0]                expected_gmem_write_bytes_o,
    output wire [63:0]                active_cycles_o,
    output wire                       gmem_outstanding_o
);

    localparam OP_GET_ROWS_F32 = 1'b0;
    localparam OP_REPEAT_F32   = 1'b1;

    localparam [31:0] KERNEL_ID_GET_ROWS_F32 = 32'h514e0003;
    localparam [31:0] KERNEL_ID_REPEAT_F32   = 32'h514e0004;

    localparam [4:0] ST_IDLE         = 5'd0;
    localparam [4:0] ST_PREFLIGHT    = 5'd1;
    localparam [4:0] ST_INDEX_PREP   = 5'd2;
    localparam [4:0] ST_INDEX_REQ    = 5'd3;
    localparam [4:0] ST_INDEX_WAIT   = 5'd4;
    localparam [4:0] ST_SOURCE_PREP  = 5'd5;
    localparam [4:0] ST_SOURCE_REQ   = 5'd6;
    localparam [4:0] ST_SOURCE_WAIT  = 5'd7;
    localparam [4:0] ST_WRITE_PREP   = 5'd8;
    localparam [4:0] ST_WRITE_REQ    = 5'd9;
    localparam [4:0] ST_WRITE_WAIT   = 5'd10;
    localparam [4:0] ST_PORTAL_DRAIN = 5'd11;
    localparam [4:0] ST_DONE         = 5'd12;
    localparam [4:0] ST_ERROR        = 5'd13;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_DESCRIPTOR      = 5'd1;
    localparam [4:0] ERR_SOURCE_WINDOW   = 5'd2;
    localparam [4:0] ERR_INDEX_WINDOW    = 5'd3;
    localparam [4:0] ERR_DEST_WINDOW     = 5'd4;
    localparam [4:0] ERR_ALIAS           = 5'd5;
    localparam [4:0] ERR_INDEX_RANGE     = 5'd6;
    localparam [4:0] ERR_PORTAL_RESPONSE = 5'd7;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd8;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd9;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd10;

    localparam [31:0] MAX_ELEMENTS_U32 = MAX_ELEMENTS;
    localparam [31:0] MAX_INDICES_U32  = MAX_INDICES;
    localparam [31:0] MAX_REPEAT_U32   = MAX_REPEAT;
    localparam [31:0] MAX_OUTER_U32    = MAX_OUTER;
    localparam         LANES_VALID     = (LANES >= 1) && (LANES <= 16);
    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                        : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 64'd1) ? 64'd0
                                          : COMMAND_TIMEOUT_CYCLES - 64'd1;

    generate
        if ((LANES < 1) || (LANES > 16)) begin : gen_bad_lanes
            initial $fatal(1,
                "F32 gather/repeat portal LANES must be in 1..16");
        end
    endgenerate

    reg [4:0] state_q;

    reg        operation_q;
    reg        npu_required_q;
    reg [63:0] command_id_q;
    reg [63:0] canonical_node_id_lo_q;
    reg [63:0] canonical_node_id_hi_q;
    reg        dst_shadow_private_q;
    reg        windows_generation_valid_q;
    reg [63:0] src_base_q;
    reg [63:0] index_base_q;
    reg [63:0] dst_base_q;
    reg [31:0] element_count_q;
    reg [31:0] source_row_count_q;
    reg [31:0] index_count_q;
    reg [31:0] outer_count_q;
    reg [31:0] repeat_count_q;
    reg [63:0] src_row_stride_q;
    reg [63:0] index_stride_q;
    reg [63:0] dst_row_stride_q;
    reg [63:0] dst_outer_stride_q;
    reg [63:0] src_window_base_q;
    reg [63:0] src_window_bytes_q;
    reg        src_window_read_q;
    reg        src_window_write_q;
    reg [63:0] index_window_base_q;
    reg [63:0] index_window_bytes_q;
    reg        index_window_read_q;
    reg        index_window_write_q;
    reg [63:0] dst_window_base_q;
    reg [63:0] dst_window_bytes_q;
    reg        dst_window_read_q;
    reg        dst_window_write_q;

    reg [31:0] index_position_q;
    reg [31:0] index_lane_q;
    reg [31:0] index_group_count_q;
    reg [31:0] element_position_q;
    reg [31:0] outer_position_q;
    reg [31:0] repeat_position_q;
    reg [31:0] selected_rows_q [0:LANES-1];
    reg [(LANES*32)-1:0] held_words_q;

    reg                       request_write_q;
    reg [LANES-1:0]           request_mask_q;
    reg [(LANES*64)-1:0]      request_addr_q;
    reg [(LANES*32)-1:0]      request_wdata_q;
    reg [31:0]                request_word_count_q;
    reg                       outstanding_q;
    reg                       outstanding_write_q;
    reg [LANES-1:0]           outstanding_mask_q;
    reg [31:0]                outstanding_word_count_q;

    reg [4:0]  error_code_q;
    reg [4:0]  drain_error_code_q;
    reg [31:0] stall_cycles_q;
    reg [63:0] command_cycles_q;
    reg [63:0] active_cycles_q;
    reg [63:0] indices_completed_q;
    reg [63:0] source_words_completed_q;
    reg [63:0] elements_completed_q;
    reg [63:0] portal_request_groups_q;
    reg [63:0] portal_response_groups_q;
    reg [63:0] portal_read_groups_q;
    reg [63:0] portal_write_groups_q;
    reg [63:0] portal_read_words_q;
    reg [63:0] portal_write_words_q;
    reg [63:0] portal_read_bytes_q;
    reg [63:0] portal_write_bytes_q;

    wire start_fire_w;
    wire request_state_w;
    wire response_state_w;
    wire stall_state_w;
    wire portal_req_fire_w;
    wire portal_rsp_fire_w;
    wire progress_w;
    wire stall_timeout_hit_w;
    wire command_timeout_hit_w;
    wire response_mask_matches_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE);
    assign busy_o  = !rst_i && (state_q != ST_IDLE);
    assign done_o  = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign completion_valid_o = done_o || error_o;
    assign dst_commit_o = done_o;
    assign completion_command_id_o = completion_valid_o
                                     ? command_id_q : 64'b0;
    assign completion_canonical_node_id_lo_o = completion_valid_o
                                               ? canonical_node_id_lo_q
                                               : 64'b0;
    assign completion_canonical_node_id_hi_o = completion_valid_o
                                               ? canonical_node_id_hi_q
                                               : 64'b0;
    assign completion_npu_required_o = completion_valid_o
                                       ? npu_required_q : 1'b0;
    assign completion_operation_o = completion_valid_o ? operation_q : 1'b0;
    assign completion_kernel_id_o = !completion_valid_o ? 32'b0
                                  : (operation_q == OP_GET_ROWS_F32)
                                    ? KERNEL_ID_GET_ROWS_F32
                                    : KERNEL_ID_REPEAT_F32;
    assign error_code_o = error_code_q;

    assign indices_completed_o = indices_completed_q;
    assign source_words_completed_o = source_words_completed_q;
    assign elements_completed_o = elements_completed_q;
    assign portal_request_groups_o = portal_request_groups_q;
    assign portal_response_groups_o = portal_response_groups_q;
    assign portal_read_groups_o = portal_read_groups_q;
    assign portal_write_groups_o = portal_write_groups_q;
    assign portal_read_words_o = portal_read_words_q;
    assign portal_write_words_o = portal_write_words_q;
    assign portal_read_bytes_o = portal_read_bytes_q;
    assign portal_write_bytes_o = portal_write_bytes_q;
    assign portal_outstanding_o = outstanding_q;
    assign active_cycles_o = active_cycles_q;

    assign gmem_req_valid_o = 1'b0;
    assign gmem_req_write_o = 1'b0;
    assign gmem_req_addr_o = 64'b0;
    assign gmem_req_wdata_o = 64'b0;
    assign gmem_req_wstrb_o = 8'b0;
    assign gmem_rsp_ready_o = 1'b0;
    assign gmem_read_beats_o = 64'b0;
    assign gmem_read_responses_o = 64'b0;
    assign read_payload_bytes_o = 64'b0;
    assign gmem_write_beats_o = 64'b0;
    assign gmem_write_responses_o = 64'b0;
    assign write_payload_bytes_o = 64'b0;
    assign expected_gmem_read_bytes_o = 64'b0;
    assign expected_gmem_write_bytes_o = 64'b0;
    assign gmem_outstanding_o = 1'b0;

    assign start_fire_w = start_i && ready_o;
    assign request_state_w = (state_q == ST_INDEX_REQ)
                           || (state_q == ST_SOURCE_REQ)
                           || (state_q == ST_WRITE_REQ);
    assign response_state_w = (state_q == ST_INDEX_WAIT)
                            || (state_q == ST_SOURCE_WAIT)
                            || (state_q == ST_WRITE_WAIT)
                            || (state_q == ST_PORTAL_DRAIN);
    assign stall_state_w = request_state_w
                         || (state_q == ST_INDEX_WAIT)
                         || (state_q == ST_SOURCE_WAIT)
                         || (state_q == ST_WRITE_WAIT);
    assign stall_timeout_hit_w = (stall_cycles_q >= STALL_TIMEOUT_LAST);
    assign command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);

    assign portal_req_valid_o = !rst_i && request_state_w
                              && !stall_timeout_hit_w
                              && !command_timeout_hit_w;
    assign portal_req_write_o = request_write_q;
    assign portal_req_mask_o = request_mask_q;
    assign portal_req_addr_o = request_addr_q;
    assign portal_req_wdata_o = request_wdata_q;
    assign portal_rsp_ready_o = !rst_i && response_state_w && outstanding_q;
    assign portal_req_fire_w = portal_req_valid_o && portal_req_ready_i;
    assign portal_rsp_fire_w = portal_rsp_valid_i && portal_rsp_ready_o;
    assign progress_w = portal_req_fire_w || portal_rsp_fire_w;
    assign response_mask_matches_w =
        (portal_rsp_mask_i == outstanding_mask_q);

    // ------------------------------------------------------------------
    // Complete 128-bit admission proof, deliberately identical to the raw
    // adapter's P06/P12 descriptor and aligned physical footprint contract.
    // ------------------------------------------------------------------
    reg [127:0] row_bytes_w;
    reg [127:0] total_outputs_w;
    reg [127:0] repeat_plane_span_w;
    reg [127:0] src_window_end_w;
    reg [127:0] index_window_end_w;
    reg [127:0] dst_window_end_w;
    reg [127:0] src_end_w;
    reg [127:0] index_end_w;
    reg [127:0] dst_end_w;
    reg [127:0] src_phys_start_w;
    reg [127:0] src_phys_end_w;
    reg [127:0] index_phys_start_w;
    reg [127:0] index_phys_end_w;
    reg [127:0] dst_phys_start_w;
    reg [127:0] dst_phys_end_w;
    reg [127:0] preflight_align_tmp_w;
    reg         empty_get_rows_w;
    reg         descriptor_ok_w;
    reg         source_window_ok_w;
    reg         index_window_ok_w;
    reg         destination_window_ok_w;
    reg         alias_ok_w;
    reg [4:0]   preflight_error_w;

    always @(*) begin
        preflight_align_tmp_w = 128'b0;
        row_bytes_w = {96'b0, element_count_q} * 128'd4;
        empty_get_rows_w = (operation_q == OP_GET_ROWS_F32)
                         && (index_count_q == 32'b0);

        if (operation_q == OP_GET_ROWS_F32) begin
            total_outputs_w = {96'b0, element_count_q}
                            * {96'b0, index_count_q};
            repeat_plane_span_w = 128'b0;
        end else begin
            total_outputs_w = {96'b0, element_count_q}
                            * {96'b0, repeat_count_q}
                            * {96'b0, outer_count_q};
            repeat_plane_span_w =
                ({96'b0, (repeat_count_q - 32'd1)}
                 * {64'b0, dst_row_stride_q}) + row_bytes_w;
        end

        src_window_end_w = {64'b0, src_window_base_q}
                         + {64'b0, src_window_bytes_q};
        index_window_end_w = {64'b0, index_window_base_q}
                           + {64'b0, index_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};

        src_end_w = {64'b0, src_base_q};
        index_end_w = {64'b0, index_base_q};
        dst_end_w = {64'b0, dst_base_q};
        if (!empty_get_rows_w) begin
            if (operation_q == OP_GET_ROWS_F32) begin
                src_end_w = {64'b0, src_base_q}
                          + ({96'b0, (source_row_count_q - 32'd1)}
                             * {64'b0, src_row_stride_q})
                          + row_bytes_w;
                index_end_w = {64'b0, index_base_q}
                            + ({96'b0, (index_count_q - 32'd1)}
                               * {64'b0, index_stride_q})
                            + 128'd4;
                dst_end_w = {64'b0, dst_base_q}
                          + ({96'b0, (index_count_q - 32'd1)}
                             * {64'b0, dst_row_stride_q})
                          + row_bytes_w;
            end else begin
                src_end_w = {64'b0, src_base_q}
                          + ({96'b0, (outer_count_q - 32'd1)}
                             * {64'b0, src_row_stride_q})
                          + row_bytes_w;
                dst_end_w = {64'b0, dst_base_q}
                          + ({96'b0, (outer_count_q - 32'd1)}
                             * {64'b0, dst_outer_stride_q})
                          + repeat_plane_span_w;
            end
        end

        src_phys_start_w = {64'b0, src_base_q};
        src_phys_start_w[2:0] = 3'b000;
        index_phys_start_w = {64'b0, index_base_q};
        index_phys_start_w[2:0] = 3'b000;
        dst_phys_start_w = {64'b0, dst_base_q};
        dst_phys_start_w[2:0] = 3'b000;
        src_phys_end_w = src_phys_start_w;
        index_phys_end_w = index_phys_start_w;
        dst_phys_end_w = dst_phys_start_w;
        if (!empty_get_rows_w) begin
            preflight_align_tmp_w = src_end_w - 128'd1;
            preflight_align_tmp_w[2:0] = 3'b000;
            src_phys_end_w = preflight_align_tmp_w + 128'd8;
            if (operation_q == OP_GET_ROWS_F32) begin
                preflight_align_tmp_w = index_end_w - 128'd1;
                preflight_align_tmp_w[2:0] = 3'b000;
                index_phys_end_w = preflight_align_tmp_w + 128'd8;
            end
            preflight_align_tmp_w = dst_end_w - 128'd1;
            preflight_align_tmp_w[2:0] = 3'b000;
            dst_phys_end_w = preflight_align_tmp_w + 128'd8;
        end

        descriptor_ok_w = LANES_VALID
                       && dst_shadow_private_q
                       && windows_generation_valid_q
                       && ((canonical_node_id_lo_q != 64'b0)
                           || (canonical_node_id_hi_q != 64'b0))
                       && (element_count_q >= 32'd1)
                       && (element_count_q <= MAX_ELEMENTS_U32)
                       && (row_bytes_w[127:64] == 64'b0)
                       && (total_outputs_w[127:64] == 64'b0)
                       && (empty_get_rows_w
                           || (total_outputs_w != 128'b0))
                       && (src_base_q[1:0] == 2'b00)
                       && (index_base_q[1:0] == 2'b00)
                       && (dst_base_q[1:0] == 2'b00)
                       && (src_row_stride_q[1:0] == 2'b00)
                       && (index_stride_q[1:0] == 2'b00)
                       && (dst_row_stride_q[1:0] == 2'b00)
                       && (dst_outer_stride_q[1:0] == 2'b00)
                       && (src_window_base_q[2:0] == 3'b000)
                       && (src_window_bytes_q[2:0] == 3'b000)
                       && (index_window_base_q[2:0] == 3'b000)
                       && (index_window_bytes_q[2:0] == 3'b000)
                       && (dst_window_base_q[2:0] == 3'b000)
                       && (dst_window_bytes_q[2:0] == 3'b000)
                       && src_window_read_q
                       && !src_window_write_q
                       && index_window_read_q
                       && !index_window_write_q
                       && !dst_window_read_q
                       && dst_window_write_q;

        if (operation_q == OP_GET_ROWS_F32) begin
            descriptor_ok_w = descriptor_ok_w
                           && (index_count_q <= MAX_INDICES_U32)
                           && (outer_count_q == 32'b0)
                           && (repeat_count_q == 32'b0)
                           && (src_row_stride_q >= row_bytes_w[63:0])
                           && (index_stride_q >= 64'd4)
                           && (dst_row_stride_q >= row_bytes_w[63:0])
                           && (dst_outer_stride_q == 64'b0)
                           && (empty_get_rows_w
                               || (source_row_count_q >= 32'd1));
        end else if (operation_q == OP_REPEAT_F32) begin
            descriptor_ok_w = descriptor_ok_w
                           && (source_row_count_q == 32'b0)
                           && (index_count_q == 32'b0)
                           && (outer_count_q >= 32'd1)
                           && (outer_count_q <= MAX_OUTER_U32)
                           && (repeat_count_q >= 32'd1)
                           && (repeat_count_q <= MAX_REPEAT_U32)
                           && (src_row_stride_q >= row_bytes_w[63:0])
                           && (index_stride_q == 64'b0)
                           && (dst_row_stride_q >= row_bytes_w[63:0])
                           && (repeat_plane_span_w[127:64] == 64'b0)
                           && (dst_outer_stride_q
                               >= repeat_plane_span_w[63:0]);
        end else begin
            descriptor_ok_w = 1'b0;
        end

        if (empty_get_rows_w) begin
            source_window_ok_w =
                (src_window_end_w[127:64] == 64'b0);
            index_window_ok_w =
                (index_window_end_w[127:64] == 64'b0);
            destination_window_ok_w =
                (dst_window_end_w[127:64] == 64'b0);
            alias_ok_w = 1'b1;
        end else begin
            source_window_ok_w =
                   (src_window_bytes_q != 64'b0)
                && (src_window_end_w[127:64] == 64'b0)
                && (src_end_w[127:64] == 64'b0)
                && (src_phys_start_w[127:64] == 64'b0)
                && (src_phys_end_w[127:64] == 64'b0)
                && (src_phys_start_w >= {64'b0, src_window_base_q})
                && (src_phys_end_w <= src_window_end_w);
            if (operation_q == OP_GET_ROWS_F32) begin
                index_window_ok_w =
                       (index_window_bytes_q != 64'b0)
                    && (index_window_end_w[127:64] == 64'b0)
                    && (index_end_w[127:64] == 64'b0)
                    && (index_phys_start_w[127:64] == 64'b0)
                    && (index_phys_end_w[127:64] == 64'b0)
                    && (index_phys_start_w
                        >= {64'b0, index_window_base_q})
                    && (index_phys_end_w <= index_window_end_w);
            end else begin
                index_window_ok_w =
                    (index_window_end_w[127:64] == 64'b0);
            end
            destination_window_ok_w =
                   (dst_window_bytes_q != 64'b0)
                && (dst_window_end_w[127:64] == 64'b0)
                && (dst_end_w[127:64] == 64'b0)
                && (dst_phys_start_w[127:64] == 64'b0)
                && (dst_phys_end_w[127:64] == 64'b0)
                && (dst_phys_start_w >= {64'b0, dst_window_base_q})
                && (dst_phys_end_w <= dst_window_end_w);
            alias_ok_w = ((dst_phys_end_w <= src_phys_start_w)
                          || (dst_phys_start_w >= src_phys_end_w));
            if (operation_q == OP_GET_ROWS_F32) begin
                alias_ok_w = alias_ok_w
                          && ((dst_phys_end_w <= index_phys_start_w)
                              || (dst_phys_start_w
                                  >= index_phys_end_w));
            end
        end

        if (!descriptor_ok_w)
            preflight_error_w = ERR_DESCRIPTOR;
        else if (!source_window_ok_w)
            preflight_error_w = ERR_SOURCE_WINDOW;
        else if (!index_window_ok_w)
            preflight_error_w = ERR_INDEX_WINDOW;
        else if (!destination_window_ok_w)
            preflight_error_w = ERR_DEST_WINDOW;
        else if (!alias_ok_w)
            preflight_error_w = ERR_ALIAS;
        else
            preflight_error_w = ERR_NONE;
    end

    // ------------------------------------------------------------------
    // Group preparation and per-coordinate re-proof.  Portal addresses are
    // exact raw32 semantic addresses; inactive lane payload is always zero.
    // ------------------------------------------------------------------
    integer prep_lane;
    reg [LANES-1:0] prep_mask_w;
    reg [(LANES*64)-1:0] prep_addr_w;
    reg [(LANES*32)-1:0] prep_wdata_w;
    reg [31:0] prep_word_count_w;
    reg prep_coordinate_ok_w;
    reg [127:0] prep_coord_w;
    reg [127:0] prep_semantic_addr_w;
    reg [127:0] prep_word_end_w;
    reg [127:0] prep_phys_start_w;
    reg [127:0] prep_phys_end_w;
    reg [127:0] prep_align_tmp_w;
    reg [127:0] prep_window_start_w;
    reg [127:0] prep_window_end_w;

    always @(*) begin
        prep_mask_w = {LANES{1'b0}};
        prep_addr_w = {(LANES*64){1'b0}};
        prep_wdata_w = {(LANES*32){1'b0}};
        prep_word_count_w = 32'b0;
        prep_coordinate_ok_w = LANES_VALID;
        prep_coord_w = 128'b0;
        prep_semantic_addr_w = 128'b0;
        prep_word_end_w = 128'b0;
        prep_phys_start_w = 128'b0;
        prep_phys_end_w = 128'b0;
        prep_align_tmp_w = 128'b0;
        prep_window_start_w = 128'b0;
        prep_window_end_w = 128'b0;

        for (prep_lane = 0; prep_lane < LANES;
             prep_lane = prep_lane + 1) begin
            if (state_q == ST_INDEX_PREP) begin
                prep_coord_w = {96'b0, index_position_q}
                             + {96'b0, prep_lane[31:0]};
                if (prep_coord_w < {96'b0, index_count_q}) begin
                    prep_mask_w[prep_lane] = 1'b1;
                    prep_word_count_w = prep_word_count_w + 32'd1;
                    prep_semantic_addr_w = {64'b0, index_base_q}
                        + (prep_coord_w * {64'b0, index_stride_q});
                    prep_window_start_w = {64'b0, index_window_base_q};
                    prep_window_end_w = index_window_end_w;
                    prep_word_end_w = prep_semantic_addr_w + 128'd4;
                    prep_phys_start_w = prep_semantic_addr_w;
                    prep_phys_start_w[2:0] = 3'b000;
                    prep_align_tmp_w = prep_word_end_w - 128'd1;
                    prep_align_tmp_w[2:0] = 3'b000;
                    prep_phys_end_w = prep_align_tmp_w + 128'd8;
                    prep_coordinate_ok_w = prep_coordinate_ok_w
                        && (operation_q == OP_GET_ROWS_F32)
                        && (prep_semantic_addr_w[1:0] == 2'b00)
                        && (prep_semantic_addr_w[127:64] == 64'b0)
                        && (prep_word_end_w[127:64] == 64'b0)
                        && (prep_phys_start_w[127:64] == 64'b0)
                        && (prep_phys_end_w[127:64] == 64'b0)
                        && (prep_phys_start_w >= prep_window_start_w)
                        && (prep_phys_end_w <= prep_window_end_w);
                    prep_addr_w[(prep_lane*64) +: 64]
                        = prep_semantic_addr_w[63:0];
                end
            end else if (state_q == ST_SOURCE_PREP) begin
                prep_coord_w = {96'b0, element_position_q}
                             + {96'b0, prep_lane[31:0]};
                if (prep_coord_w < {96'b0, element_count_q}) begin
                    prep_mask_w[prep_lane] = 1'b1;
                    prep_word_count_w = prep_word_count_w + 32'd1;
                    if (operation_q == OP_GET_ROWS_F32) begin
                        prep_semantic_addr_w = {64'b0, src_base_q}
                            + ({96'b0, selected_rows_q[index_lane_q]}
                               * {64'b0, src_row_stride_q})
                            + (prep_coord_w * 128'd4);
                        prep_coordinate_ok_w = prep_coordinate_ok_w
                            && (index_lane_q < index_group_count_q)
                            && (selected_rows_q[index_lane_q]
                                < source_row_count_q);
                    end else begin
                        prep_semantic_addr_w = {64'b0, src_base_q}
                            + ({96'b0, outer_position_q}
                               * {64'b0, src_row_stride_q})
                            + (prep_coord_w * 128'd4);
                        prep_coordinate_ok_w = prep_coordinate_ok_w
                            && (operation_q == OP_REPEAT_F32)
                            && (outer_position_q < outer_count_q);
                    end
                    prep_window_start_w = {64'b0, src_window_base_q};
                    prep_window_end_w = src_window_end_w;
                    prep_word_end_w = prep_semantic_addr_w + 128'd4;
                    prep_phys_start_w = prep_semantic_addr_w;
                    prep_phys_start_w[2:0] = 3'b000;
                    prep_align_tmp_w = prep_word_end_w - 128'd1;
                    prep_align_tmp_w[2:0] = 3'b000;
                    prep_phys_end_w = prep_align_tmp_w + 128'd8;
                    prep_coordinate_ok_w = prep_coordinate_ok_w
                        && (prep_semantic_addr_w[1:0] == 2'b00)
                        && (prep_semantic_addr_w[127:64] == 64'b0)
                        && (prep_word_end_w[127:64] == 64'b0)
                        && (prep_phys_start_w[127:64] == 64'b0)
                        && (prep_phys_end_w[127:64] == 64'b0)
                        && (prep_phys_start_w >= prep_window_start_w)
                        && (prep_phys_end_w <= prep_window_end_w);
                    prep_addr_w[(prep_lane*64) +: 64]
                        = prep_semantic_addr_w[63:0];
                end
            end else if (state_q == ST_WRITE_PREP) begin
                prep_coord_w = {96'b0, element_position_q}
                             + {96'b0, prep_lane[31:0]};
                if (prep_coord_w < {96'b0, element_count_q}) begin
                    prep_mask_w[prep_lane] = 1'b1;
                    prep_word_count_w = prep_word_count_w + 32'd1;
                    if (operation_q == OP_GET_ROWS_F32) begin
                        prep_semantic_addr_w = {64'b0, dst_base_q}
                            + (({96'b0, index_position_q}
                                + {96'b0, index_lane_q})
                               * {64'b0, dst_row_stride_q})
                            + (prep_coord_w * 128'd4);
                        prep_coordinate_ok_w = prep_coordinate_ok_w
                            && (index_lane_q < index_group_count_q)
                            && (({96'b0, index_position_q}
                                 + {96'b0, index_lane_q})
                                < {96'b0, index_count_q});
                    end else begin
                        prep_semantic_addr_w = {64'b0, dst_base_q}
                            + ({96'b0, outer_position_q}
                               * {64'b0, dst_outer_stride_q})
                            + ({96'b0, repeat_position_q}
                               * {64'b0, dst_row_stride_q})
                            + (prep_coord_w * 128'd4);
                        prep_coordinate_ok_w = prep_coordinate_ok_w
                            && (operation_q == OP_REPEAT_F32)
                            && (outer_position_q < outer_count_q)
                            && (repeat_position_q < repeat_count_q);
                    end
                    prep_window_start_w = {64'b0, dst_window_base_q};
                    prep_window_end_w = dst_window_end_w;
                    prep_word_end_w = prep_semantic_addr_w + 128'd4;
                    prep_phys_start_w = prep_semantic_addr_w;
                    prep_phys_start_w[2:0] = 3'b000;
                    prep_align_tmp_w = prep_word_end_w - 128'd1;
                    prep_align_tmp_w[2:0] = 3'b000;
                    prep_phys_end_w = prep_align_tmp_w + 128'd8;
                    prep_coordinate_ok_w = prep_coordinate_ok_w
                        && (prep_semantic_addr_w[1:0] == 2'b00)
                        && (prep_semantic_addr_w[127:64] == 64'b0)
                        && (prep_word_end_w[127:64] == 64'b0)
                        && (prep_phys_start_w[127:64] == 64'b0)
                        && (prep_phys_end_w[127:64] == 64'b0)
                        && (prep_phys_start_w >= prep_window_start_w)
                        && (prep_phys_end_w <= prep_window_end_w);
                    prep_addr_w[(prep_lane*64) +: 64]
                        = prep_semantic_addr_w[63:0];
                    prep_wdata_w[(prep_lane*32) +: 32]
                        = held_words_q[(prep_lane*32) +: 32];
                end
            end
        end
    end

    integer response_lane;
    reg response_indices_ok_w;
    always @(*) begin
        response_indices_ok_w = 1'b1;
        for (response_lane = 0; response_lane < LANES;
             response_lane = response_lane + 1) begin
            if (outstanding_mask_q[response_lane]) begin
                response_indices_ok_w = response_indices_ok_w
                    && !portal_rsp_rdata_i[(response_lane*32) + 31]
                    && (portal_rsp_rdata_i[(response_lane*32) +: 32]
                        < source_row_count_q);
            end
        end
    end

    integer reset_lane;
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            operation_q <= OP_GET_ROWS_F32;
            npu_required_q <= 1'b0;
            command_id_q <= 64'b0;
            canonical_node_id_lo_q <= 64'b0;
            canonical_node_id_hi_q <= 64'b0;
            dst_shadow_private_q <= 1'b0;
            windows_generation_valid_q <= 1'b0;
            src_base_q <= 64'b0;
            index_base_q <= 64'b0;
            dst_base_q <= 64'b0;
            element_count_q <= 32'b0;
            source_row_count_q <= 32'b0;
            index_count_q <= 32'b0;
            outer_count_q <= 32'b0;
            repeat_count_q <= 32'b0;
            src_row_stride_q <= 64'b0;
            index_stride_q <= 64'b0;
            dst_row_stride_q <= 64'b0;
            dst_outer_stride_q <= 64'b0;
            src_window_base_q <= 64'b0;
            src_window_bytes_q <= 64'b0;
            src_window_read_q <= 1'b0;
            src_window_write_q <= 1'b0;
            index_window_base_q <= 64'b0;
            index_window_bytes_q <= 64'b0;
            index_window_read_q <= 1'b0;
            index_window_write_q <= 1'b0;
            dst_window_base_q <= 64'b0;
            dst_window_bytes_q <= 64'b0;
            dst_window_read_q <= 1'b0;
            dst_window_write_q <= 1'b0;
            index_position_q <= 32'b0;
            index_lane_q <= 32'b0;
            index_group_count_q <= 32'b0;
            element_position_q <= 32'b0;
            outer_position_q <= 32'b0;
            repeat_position_q <= 32'b0;
            for (reset_lane = 0; reset_lane < LANES;
                 reset_lane = reset_lane + 1)
                selected_rows_q[reset_lane] <= 32'b0;
            held_words_q <= {(LANES*32){1'b0}};
            request_write_q <= 1'b0;
            request_mask_q <= {LANES{1'b0}};
            request_addr_q <= {(LANES*64){1'b0}};
            request_wdata_q <= {(LANES*32){1'b0}};
            request_word_count_q <= 32'b0;
            outstanding_q <= 1'b0;
            outstanding_write_q <= 1'b0;
            outstanding_mask_q <= {LANES{1'b0}};
            outstanding_word_count_q <= 32'b0;
            error_code_q <= ERR_NONE;
            drain_error_code_q <= ERR_NONE;
            stall_cycles_q <= 32'b0;
            command_cycles_q <= 64'b0;
            active_cycles_q <= 64'b0;
            indices_completed_q <= 64'b0;
            source_words_completed_q <= 64'b0;
            elements_completed_q <= 64'b0;
            portal_request_groups_q <= 64'b0;
            portal_response_groups_q <= 64'b0;
            portal_read_groups_q <= 64'b0;
            portal_write_groups_q <= 64'b0;
            portal_read_words_q <= 64'b0;
            portal_write_words_q <= 64'b0;
            portal_read_bytes_q <= 64'b0;
            portal_write_bytes_q <= 64'b0;
        end else begin
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)) begin
                command_cycles_q <= command_cycles_q + 64'd1;
                active_cycles_q <= active_cycles_q + 64'd1;
            end

            if (stall_state_w) begin
                if (progress_w)
                    stall_cycles_q <= 32'b0;
                else if (stall_cycles_q != 32'hffff_ffff)
                    stall_cycles_q <= stall_cycles_q + 32'd1;
            end else begin
                stall_cycles_q <= 32'b0;
            end

            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)
                    && (state_q != ST_PORTAL_DRAIN)
                    && command_timeout_hit_w && !progress_w) begin
                if (outstanding_q) begin
                    drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_PORTAL_DRAIN;
                end else begin
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_ERROR;
                end
            end else if (stall_state_w && stall_timeout_hit_w
                    && !progress_w) begin
                if (outstanding_q) begin
                    drain_error_code_q <= ERR_STALL_TIMEOUT;
                    state_q <= ST_PORTAL_DRAIN;
                end else begin
                    error_code_q <= ERR_STALL_TIMEOUT;
                    state_q <= ST_ERROR;
                end
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        outstanding_q <= 1'b0;
                        outstanding_write_q <= 1'b0;
                        if (start_fire_w) begin
                            operation_q <= operation_i;
                            npu_required_q <= npu_required_i;
                            command_id_q <= command_id_i;
                            canonical_node_id_lo_q
                                <= canonical_node_id_lo_i;
                            canonical_node_id_hi_q
                                <= canonical_node_id_hi_i;
                            dst_shadow_private_q <= dst_shadow_private_i;
                            windows_generation_valid_q
                                <= windows_generation_valid_i;
                            src_base_q <= src_base_i;
                            index_base_q <= index_base_i;
                            dst_base_q <= dst_base_i;
                            element_count_q <= element_count_i;
                            source_row_count_q <= source_row_count_i;
                            index_count_q <= index_count_i;
                            outer_count_q <= outer_count_i;
                            repeat_count_q <= repeat_count_i;
                            src_row_stride_q <= src_row_stride_i;
                            index_stride_q <= index_stride_i;
                            dst_row_stride_q <= dst_row_stride_i;
                            dst_outer_stride_q <= dst_outer_stride_i;
                            src_window_base_q <= src_window_base_i;
                            src_window_bytes_q <= src_window_bytes_i;
                            src_window_read_q <= src_window_read_i;
                            src_window_write_q <= src_window_write_i;
                            index_window_base_q <= index_window_base_i;
                            index_window_bytes_q <= index_window_bytes_i;
                            index_window_read_q <= index_window_read_i;
                            index_window_write_q <= index_window_write_i;
                            dst_window_base_q <= dst_window_base_i;
                            dst_window_bytes_q <= dst_window_bytes_i;
                            dst_window_read_q <= dst_window_read_i;
                            dst_window_write_q <= dst_window_write_i;
                            index_position_q <= 32'b0;
                            index_lane_q <= 32'b0;
                            index_group_count_q <= 32'b0;
                            element_position_q <= 32'b0;
                            outer_position_q <= 32'b0;
                            repeat_position_q <= 32'b0;
                            held_words_q <= {(LANES*32){1'b0}};
                            request_write_q <= 1'b0;
                            request_mask_q <= {LANES{1'b0}};
                            request_addr_q <= {(LANES*64){1'b0}};
                            request_wdata_q <= {(LANES*32){1'b0}};
                            request_word_count_q <= 32'b0;
                            outstanding_mask_q <= {LANES{1'b0}};
                            outstanding_word_count_q <= 32'b0;
                            error_code_q <= ERR_NONE;
                            drain_error_code_q <= ERR_NONE;
                            stall_cycles_q <= 32'b0;
                            command_cycles_q <= 64'b0;
                            active_cycles_q <= 64'b0;
                            indices_completed_q <= 64'b0;
                            source_words_completed_q <= 64'b0;
                            elements_completed_q <= 64'b0;
                            portal_request_groups_q <= 64'b0;
                            portal_response_groups_q <= 64'b0;
                            portal_read_groups_q <= 64'b0;
                            portal_write_groups_q <= 64'b0;
                            portal_read_words_q <= 64'b0;
                            portal_write_words_q <= 64'b0;
                            portal_read_bytes_q <= 64'b0;
                            portal_write_bytes_q <= 64'b0;
                            state_q <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q <= ST_ERROR;
                        end else if ((operation_q == OP_GET_ROWS_F32)
                                     && (index_count_q == 32'b0)) begin
                            state_q <= ST_DONE;
                        end else if (operation_q == OP_GET_ROWS_F32) begin
                            state_q <= ST_INDEX_PREP;
                        end else begin
                            state_q <= ST_SOURCE_PREP;
                        end
                    end

                    ST_INDEX_PREP: begin
                        if (!prep_coordinate_ok_w
                                || (prep_mask_w == {LANES{1'b0}})) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_write_q <= 1'b0;
                            request_mask_q <= prep_mask_w;
                            request_addr_q <= prep_addr_w;
                            request_wdata_q <= {(LANES*32){1'b0}};
                            request_word_count_q <= prep_word_count_w;
                            state_q <= ST_INDEX_REQ;
                        end
                    end

                    ST_INDEX_REQ: begin
                        if (portal_req_fire_w) begin
                            outstanding_q <= 1'b1;
                            outstanding_write_q <= 1'b0;
                            outstanding_mask_q <= request_mask_q;
                            outstanding_word_count_q
                                <= request_word_count_q;
                            portal_request_groups_q
                                <= portal_request_groups_q + 64'd1;
                            portal_read_groups_q
                                <= portal_read_groups_q + 64'd1;
                            state_q <= ST_INDEX_WAIT;
                        end
                    end

                    ST_INDEX_WAIT: begin
                        if (portal_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            portal_response_groups_q
                                <= portal_response_groups_q + 64'd1;
                            if (portal_rsp_error_i
                                    || !response_mask_matches_w) begin
                                error_code_q <= ERR_PORTAL_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                portal_read_words_q <= portal_read_words_q
                                    + {32'b0, outstanding_word_count_q};
                                portal_read_bytes_q <= portal_read_bytes_q
                                    + ({32'b0, outstanding_word_count_q}
                                       * 64'd4);
                                indices_completed_q <= indices_completed_q
                                    + {32'b0, outstanding_word_count_q};
                                for (reset_lane = 0; reset_lane < LANES;
                                     reset_lane = reset_lane + 1) begin
                                    if (outstanding_mask_q[reset_lane]) begin
                                        selected_rows_q[reset_lane]
                                            <= portal_rsp_rdata_i[
                                                (reset_lane*32) +: 32];
                                    end
                                end
                                if (!response_indices_ok_w) begin
                                    error_code_q <= ERR_INDEX_RANGE;
                                    state_q <= ST_ERROR;
                                end else begin
                                    index_group_count_q
                                        <= outstanding_word_count_q;
                                    index_lane_q <= 32'b0;
                                    element_position_q <= 32'b0;
                                    state_q <= ST_SOURCE_PREP;
                                end
                            end
                        end
                    end

                    ST_SOURCE_PREP: begin
                        if (!prep_coordinate_ok_w
                                || (prep_mask_w == {LANES{1'b0}})) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_write_q <= 1'b0;
                            request_mask_q <= prep_mask_w;
                            request_addr_q <= prep_addr_w;
                            request_wdata_q <= {(LANES*32){1'b0}};
                            request_word_count_q <= prep_word_count_w;
                            state_q <= ST_SOURCE_REQ;
                        end
                    end

                    ST_SOURCE_REQ: begin
                        if (portal_req_fire_w) begin
                            outstanding_q <= 1'b1;
                            outstanding_write_q <= 1'b0;
                            outstanding_mask_q <= request_mask_q;
                            outstanding_word_count_q
                                <= request_word_count_q;
                            portal_request_groups_q
                                <= portal_request_groups_q + 64'd1;
                            portal_read_groups_q
                                <= portal_read_groups_q + 64'd1;
                            state_q <= ST_SOURCE_WAIT;
                        end
                    end

                    ST_SOURCE_WAIT: begin
                        if (portal_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            portal_response_groups_q
                                <= portal_response_groups_q + 64'd1;
                            if (portal_rsp_error_i
                                    || !response_mask_matches_w) begin
                                error_code_q <= ERR_PORTAL_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                held_words_q <= portal_rsp_rdata_i;
                                source_words_completed_q
                                    <= source_words_completed_q
                                       + {32'b0,
                                          outstanding_word_count_q};
                                portal_read_words_q <= portal_read_words_q
                                    + {32'b0, outstanding_word_count_q};
                                portal_read_bytes_q <= portal_read_bytes_q
                                    + ({32'b0, outstanding_word_count_q}
                                       * 64'd4);
                                repeat_position_q <= 32'b0;
                                state_q <= ST_WRITE_PREP;
                            end
                        end
                    end

                    ST_WRITE_PREP: begin
                        if (!prep_coordinate_ok_w
                                || (prep_mask_w == {LANES{1'b0}})) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            request_write_q <= 1'b1;
                            request_mask_q <= prep_mask_w;
                            request_addr_q <= prep_addr_w;
                            request_wdata_q <= prep_wdata_w;
                            request_word_count_q <= prep_word_count_w;
                            state_q <= ST_WRITE_REQ;
                        end
                    end

                    ST_WRITE_REQ: begin
                        if (portal_req_fire_w) begin
                            outstanding_q <= 1'b1;
                            outstanding_write_q <= 1'b1;
                            outstanding_mask_q <= request_mask_q;
                            outstanding_word_count_q
                                <= request_word_count_q;
                            portal_request_groups_q
                                <= portal_request_groups_q + 64'd1;
                            portal_write_groups_q
                                <= portal_write_groups_q + 64'd1;
                            state_q <= ST_WRITE_WAIT;
                        end
                    end

                    ST_WRITE_WAIT: begin
                        if (portal_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            portal_response_groups_q
                                <= portal_response_groups_q + 64'd1;
                            if (portal_rsp_error_i
                                    || !response_mask_matches_w) begin
                                error_code_q <= ERR_PORTAL_RESPONSE;
                                state_q <= ST_ERROR;
                            end else begin
                                portal_write_words_q <= portal_write_words_q
                                    + {32'b0, outstanding_word_count_q};
                                portal_write_bytes_q <= portal_write_bytes_q
                                    + ({32'b0, outstanding_word_count_q}
                                       * 64'd4);
                                elements_completed_q <= elements_completed_q
                                    + {32'b0, outstanding_word_count_q};
                                if (operation_q == OP_GET_ROWS_F32) begin
                                    if (({96'b0, element_position_q}
                                         + {96'b0,
                                            outstanding_word_count_q})
                                            < {96'b0,
                                               element_count_q}) begin
                                        element_position_q
                                            <= element_position_q
                                               + outstanding_word_count_q;
                                        state_q <= ST_SOURCE_PREP;
                                    end else if ((index_lane_q + 32'd1)
                                            < index_group_count_q) begin
                                        index_lane_q
                                            <= index_lane_q + 32'd1;
                                        element_position_q <= 32'b0;
                                        state_q <= ST_SOURCE_PREP;
                                    end else if ((index_position_q
                                                  + index_group_count_q)
                                            < index_count_q) begin
                                        index_position_q
                                            <= index_position_q
                                               + index_group_count_q;
                                        index_lane_q <= 32'b0;
                                        element_position_q <= 32'b0;
                                        state_q <= ST_INDEX_PREP;
                                    end else begin
                                        state_q <= ST_DONE;
                                    end
                                end else begin
                                    if ((repeat_position_q + 32'd1)
                                            < repeat_count_q) begin
                                        repeat_position_q
                                            <= repeat_position_q + 32'd1;
                                        state_q <= ST_WRITE_PREP;
                                    end else if (({96'b0,
                                                   element_position_q}
                                                  + {96'b0,
                                                     outstanding_word_count_q})
                                            < {96'b0,
                                               element_count_q}) begin
                                        repeat_position_q <= 32'b0;
                                        element_position_q
                                            <= element_position_q
                                               + outstanding_word_count_q;
                                        state_q <= ST_SOURCE_PREP;
                                    end else if ((outer_position_q + 32'd1)
                                            < outer_count_q) begin
                                        repeat_position_q <= 32'b0;
                                        element_position_q <= 32'b0;
                                        outer_position_q
                                            <= outer_position_q + 32'd1;
                                        state_q <= ST_SOURCE_PREP;
                                    end else begin
                                        state_q <= ST_DONE;
                                    end
                                end
                            end
                        end
                    end

                    ST_PORTAL_DRAIN: begin
                        if (portal_rsp_fire_w) begin
                            outstanding_q <= 1'b0;
                            portal_response_groups_q
                                <= portal_response_groups_q + 64'd1;
                            if (outstanding_write_q
                                    && !portal_rsp_error_i
                                    && response_mask_matches_w) begin
                                portal_write_words_q <= portal_write_words_q
                                    + {32'b0, outstanding_word_count_q};
                                portal_write_bytes_q <= portal_write_bytes_q
                                    + ({32'b0, outstanding_word_count_q}
                                       * 64'd4);
                                elements_completed_q <= elements_completed_q
                                    + {32'b0, outstanding_word_count_q};
                            end
                            error_code_q <= drain_error_code_q;
                            state_q <= ST_ERROR;
                        end
                    end

                    ST_DONE: begin
                        if (outstanding_q) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end else begin
                            state_q <= ST_IDLE;
                        end
                    end

                    ST_ERROR: begin
                        if (outstanding_q) begin
                            drain_error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_PORTAL_DRAIN;
                        end else begin
                            state_q <= ST_IDLE;
                        end
                    end

                    default: begin
                        if (outstanding_q) begin
                            drain_error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_PORTAL_DRAIN;
                        end else begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ERROR;
                        end
                    end
                endcase
            end
        end
    end

    // Explicitly consume the inert compatibility inputs for lint/audit tools.
    wire unused_gmem_inputs_w;
    assign unused_gmem_inputs_w = gmem_req_ready_i
                                ^ gmem_rsp_valid_i
                                ^ (^gmem_rsp_rdata_i)
                                ^ gmem_rsp_error_i;

endmodule

`default_nettype wire
