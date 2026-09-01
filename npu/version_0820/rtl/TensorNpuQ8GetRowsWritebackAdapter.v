`timescale 1ns/1ps
`default_nettype none

// TensorNpuQ8GetRowsWritebackAdapter
//
// Lower-level GET_ROWS_Q8_0 command slice.  The wrapped gather engine performs
// all numeric work and makes its FP32 stream visible only after its complete
// read/dequant transaction has committed.  This adapter then writes that
// committed stream into a caller-owned private destination span.  The span is
// not publication-visible until dst_commit_o/done_o; a failed writeback can
// therefore leave bytes only in transaction-private staging, never in a
// published tensor.
//
// Before starting the child, a 128-bit preflight proves the complete source
// table, index vector and strided destination footprint, including aligned
// physical GMEM beats, arithmetic overflow, destination privacy and forbidden
// source/destination aliasing.  Invalid descriptors issue no GMEM request.
// The host merely supplies descriptor scalars and transports raw bytes; Q8_0
// dequantization remains entirely in TensorNpuQ8GetRowsEngine and its RTL
// numeric children.
module TensorNpuQ8GetRowsWritebackAdapter #(
    parameter integer MAX_D                  = 1024,
    parameter integer MAX_IDS                = 16,
    parameter integer STALL_TIMEOUT_CYCLES   = 512,
    parameter integer COMMAND_TIMEOUT_CYCLES = 1048576
) (
    input  wire                               clk_i,
    input  wire                               rst_i,

    input  wire                               start_i,
    output wire                               ready_o,
    output wire                               busy_o,
    input  wire [63:0]                        command_id_i,
    input  wire                               dst_shadow_private_i,

    input  wire [63:0]                        src_slice_base_i,
    input  wire [63:0]                        idx_slice_base_i,
    input  wire [63:0]                        dst_slice_base_i,
    input  wire [63:0]                        dst_window_bytes_i,
    input  wire [63:0]                        gmem_floor_i,
    input  wire [63:0]                        gmem_limit_i,
    input  wire [31:0]                        source_row_count_i,
    input  wire [$clog2(MAX_IDS+1)-1:0]       index_count_i,
    input  wire [$clog2(MAX_D+1)-1:0]         element_count_i,
    input  wire [63:0]                        src_row_stride_i,
    input  wire [63:0]                        idx_stride_i,
    input  wire [63:0]                        dst_row_stride_i,

    output wire                               gmem_req_valid_o,
    input  wire                               gmem_req_ready_i,
    output wire                               gmem_req_write_o,
    output wire [63:0]                        gmem_req_addr_o,
    output wire [63:0]                        gmem_req_wdata_o,
    output wire [7:0]                         gmem_req_wstrb_o,
    input  wire                               gmem_rsp_valid_i,
    output wire                               gmem_rsp_ready_o,
    input  wire [63:0]                        gmem_rsp_rdata_i,
    input  wire                               gmem_rsp_error_i,

    // completion_valid_o qualifies every completion identity/counter field.
    // dst_commit_o is success-only publication eligibility for the private
    // destination span and is intentionally identical to done_o.
    output wire                               completion_valid_o,
    output wire                               dst_commit_o,
    output wire [63:0]                        completion_command_id_o,
    output wire [31:0]                        completion_kernel_id_o,
    output wire                               done_o,
    output wire                               error_o,
    output wire [4:0]                         error_code_o,
    output wire [4:0]                         engine_error_code_o,
    output wire [31:0]                        ids_scanned_o,
    output wire [31:0]                        blocks_done_o,
    output wire [31:0]                        outputs_accepted_o,
    output wire [31:0]                        gmem_read_beats_o,
    output wire [31:0]                        read_payload_bytes_o,
    output wire [31:0]                        gmem_write_beats_o,
    output wire [31:0]                        writes_completed_o,
    output wire [31:0]                        write_bytes_o,
    output wire [31:0]                        engine_active_cycles_o,
    output wire [63:0]                        active_cycles_o,
    // Completion is never published with a write-response credit live.  The
    // parent owner mux consumes this bit as an independent terminal check.
    output wire                               gmem_outstanding_o
);

    localparam integer ID_COUNT_W = $clog2(MAX_IDS + 1);
    localparam integer D_COUNT_W  = $clog2(MAX_D + 1);
    localparam [31:0] OUTPUT_DEPTH_U32 = MAX_IDS * MAX_D;
    localparam [31:0] KERNEL_ID_GET_ROWS_Q8_0 = 32'h514e0001;

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 1) ? 32'd0
                                    : (STALL_TIMEOUT_CYCLES - 1);
    localparam [63:0] COMMAND_TIMEOUT_VALUE =
        64'(COMMAND_TIMEOUT_CYCLES);
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_VALUE <= 64'd1) ? 64'd0
                                        : (COMMAND_TIMEOUT_VALUE - 64'd1);

    localparam [3:0] ST_IDLE         = 4'd0;
    localparam [3:0] ST_PREFLIGHT    = 4'd1;
    localparam [3:0] ST_ENGINE_START = 4'd2;
    localparam [3:0] ST_ENGINE_RUN   = 4'd3;
    localparam [3:0] ST_WRITE_REQ    = 4'd4;
    localparam [3:0] ST_WRITE_WAIT   = 4'd5;
    localparam [3:0] ST_GMEM_DRAIN   = 4'd6;
    localparam [3:0] ST_DONE         = 4'd7;
    localparam [3:0] ST_ERROR        = 4'd8;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_DESCRIPTOR      = 5'd1;
    localparam [4:0] ERR_SOURCE_BOUNDS   = 5'd2;
    localparam [4:0] ERR_INDEX_BOUNDS    = 5'd3;
    localparam [4:0] ERR_DEST_BOUNDS     = 5'd4;
    localparam [4:0] ERR_OVERLAP         = 5'd5;
    localparam [4:0] ERR_ENGINE          = 5'd6;
    localparam [4:0] ERR_ENGINE_PROTOCOL = 5'd7;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd8;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd9;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd10;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd11;

    reg [3:0] state_q;

    // Resident descriptor.  Busy start_i cannot mutate any of these fields.
    reg [63:0] command_id_q;
    reg        dst_shadow_private_q;
    reg [63:0] src_slice_base_q;
    reg [63:0] idx_slice_base_q;
    reg [63:0] dst_slice_base_q;
    reg [63:0] dst_window_bytes_q;
    reg [63:0] gmem_floor_q;
    reg [63:0] gmem_limit_q;
    reg [31:0] source_row_count_q;
    reg [ID_COUNT_W-1:0] index_count_q;
    reg [D_COUNT_W-1:0] element_count_q;
    reg [63:0] src_row_stride_q;
    reg [63:0] idx_stride_q;
    reg [63:0] dst_row_stride_q;
    reg [63:0] dst_span_end_q;
    reg [31:0] total_outputs_q;

    // Stream order and held write request.  The child output is consumed only
    // on the exact GMEM write-request handshake for the matching payload.
    reg [ID_COUNT_W-1:0] expected_id_position_q;
    reg [D_COUNT_W-1:0] expected_lane_index_q;
    reg [63:0] write_addr_q;
    reg [63:0] write_data_q;
    reg [7:0]  write_strb_q;
    reg [31:0] write_bits_q;
    reg [ID_COUNT_W-1:0] write_id_position_q;
    reg [31:0] write_source_id_q;
    reg [D_COUNT_W-1:0] write_lane_index_q;
    reg        write_row_last_q;
    reg        write_last_q;
    reg        write_outstanding_q;
    reg        child_done_seen_q;
    reg        child_reset_q;

    reg [31:0] stall_cycles_q;
    reg [63:0] command_cycles_q;
    reg [63:0] active_cycles_q;
    reg [4:0]  error_code_q;
    reg [4:0]  engine_error_code_q;
    reg [4:0]  drain_error_code_q;
    reg [31:0] gmem_write_beats_q;
    reg [31:0] writes_completed_q;
    reg [31:0] write_bytes_q;
    reg [31:0] ids_scanned_snapshot_q;
    reg [31:0] blocks_done_snapshot_q;
    reg [31:0] outputs_accepted_snapshot_q;
    reg [31:0] gmem_read_beats_snapshot_q;
    reg [31:0] read_payload_bytes_snapshot_q;
    reg [31:0] engine_active_cycles_snapshot_q;

    wire start_fire_w;
    wire command_timeout_hit_w;
    wire stall_timeout_hit_w;
    wire adapter_write_req_valid_w;
    wire adapter_write_req_fire_w;
    wire adapter_write_rsp_ready_w;
    wire adapter_write_rsp_fire_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE) && engine_ready_w;
    assign busy_o  = !rst_i && (state_q != ST_IDLE);
    assign done_o  = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign completion_valid_o = done_o || error_o;
    assign dst_commit_o       = done_o;
    assign completion_command_id_o = completion_valid_o
                                         ? command_id_q : 64'b0;
    assign completion_kernel_id_o = completion_valid_o
                                      ? KERNEL_ID_GET_ROWS_Q8_0 : 32'b0;
    assign error_code_o        = error_code_q;
    assign engine_error_code_o = engine_error_code_q;
    assign gmem_write_beats_o  = gmem_write_beats_q;
    assign writes_completed_o  = writes_completed_q;
    assign write_bytes_o       = write_bytes_q;
    assign active_cycles_o     = active_cycles_q;
    assign gmem_outstanding_o  = write_outstanding_q;

    assign start_fire_w = start_i && ready_o;
    assign command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);
    assign stall_timeout_hit_w =
        (stall_cycles_q >= STALL_TIMEOUT_LAST);

    // ------------------------------------------------------------------
    // Whole-descriptor preflight.  Every multiply/add remains 128-bit until
    // all semantic spans and aligned physical transactions have been proven.
    // ------------------------------------------------------------------
    reg [127:0] n_minus_one_w;
    reg [127:0] source_rows_minus_one_w;
    reg [127:0] block_count_w;
    reg [127:0] packed_row_bytes_w;
    reg [127:0] output_row_bytes_w;
    reg [127:0] total_outputs_w;

    reg [127:0] source_last_row_w;
    reg [127:0] source_end_w;
    reg [127:0] source_aligned_start_w;
    reg [127:0] source_last_byte_w;
    reg [127:0] source_aligned_end_w;

    reg [127:0] index_last_w;
    reg [127:0] index_end_w;
    reg [127:0] index_aligned_start_w;
    reg [127:0] index_last_byte_w;
    reg [127:0] index_aligned_end_w;

    reg [127:0] dst_window_end_w;
    reg [127:0] dst_last_row_w;
    reg [127:0] dst_end_w;
    reg [127:0] dst_aligned_start_w;
    reg [127:0] dst_last_byte_w;
    reg [127:0] dst_aligned_end_w;

    reg descriptor_ok_w;
    reg source_bounds_ok_w;
    reg index_bounds_ok_w;
    reg destination_bounds_ok_w;
    reg overlap_ok_w;

    always @(*) begin
        n_minus_one_w          = 128'b0;
        source_rows_minus_one_w = 128'b0;
        block_count_w          = 128'b0;
        packed_row_bytes_w     = 128'b0;
        output_row_bytes_w     = 128'b0;
        total_outputs_w        = 128'b0;
        source_last_row_w      = 128'b0;
        source_end_w           = 128'b0;
        source_aligned_start_w = 128'b0;
        source_last_byte_w     = 128'b0;
        source_aligned_end_w   = 128'b0;
        index_last_w           = 128'b0;
        index_end_w            = 128'b0;
        index_aligned_start_w  = 128'b0;
        index_last_byte_w      = 128'b0;
        index_aligned_end_w    = 128'b0;
        dst_window_end_w       = 128'b0;
        dst_last_row_w         = 128'b0;
        dst_end_w              = 128'b0;
        dst_aligned_start_w    = 128'b0;
        dst_last_byte_w        = 128'b0;
        dst_aligned_end_w      = 128'b0;
        descriptor_ok_w        = 1'b0;
        source_bounds_ok_w     = 1'b0;
        index_bounds_ok_w      = 1'b0;
        destination_bounds_ok_w = 1'b0;
        overlap_ok_w           = 1'b0;

        n_minus_one_w = {
            {(128-ID_COUNT_W){1'b0}}, index_count_q
        } - 128'd1;
        source_rows_minus_one_w = {96'b0, source_row_count_q} - 128'd1;
        block_count_w = {
            {(128-D_COUNT_W){1'b0}}, element_count_q
        } >> 5;
        packed_row_bytes_w = block_count_w * 128'd34;
        output_row_bytes_w = {
            {(128-D_COUNT_W){1'b0}}, element_count_q
        } * 128'd4;
        total_outputs_w = {
            {(128-D_COUNT_W){1'b0}}, element_count_q
        } * {
            {(128-ID_COUNT_W){1'b0}}, index_count_q
        };

        source_last_row_w = {64'b0, src_slice_base_q}
                          + (source_rows_minus_one_w
                             * {64'b0, src_row_stride_q});
        source_end_w = source_last_row_w + packed_row_bytes_w;
        source_aligned_start_w = {64'b0, src_slice_base_q};
        source_aligned_start_w[2:0] = 3'b000;
        source_last_byte_w = source_end_w - 128'd1;
        source_aligned_end_w = source_last_byte_w;
        source_aligned_end_w[2:0] = 3'b000;
        source_aligned_end_w = source_aligned_end_w + 128'd8;

        index_last_w = {64'b0, idx_slice_base_q}
                     + (n_minus_one_w * {64'b0, idx_stride_q});
        index_end_w = index_last_w + 128'd4;
        index_aligned_start_w = {64'b0, idx_slice_base_q};
        index_aligned_start_w[2:0] = 3'b000;
        index_last_byte_w = index_end_w - 128'd1;
        index_aligned_end_w = index_last_byte_w;
        index_aligned_end_w[2:0] = 3'b000;
        index_aligned_end_w = index_aligned_end_w + 128'd8;

        dst_window_end_w = {64'b0, dst_slice_base_q}
                         + {64'b0, dst_window_bytes_q};
        dst_last_row_w = {64'b0, dst_slice_base_q}
                       + (n_minus_one_w * {64'b0, dst_row_stride_q});
        dst_end_w = dst_last_row_w + output_row_bytes_w;
        dst_aligned_start_w = {64'b0, dst_slice_base_q};
        dst_aligned_start_w[2:0] = 3'b000;
        dst_last_byte_w = dst_end_w - 128'd1;
        dst_aligned_end_w = dst_last_byte_w;
        dst_aligned_end_w[2:0] = 3'b000;
        dst_aligned_end_w = dst_aligned_end_w + 128'd8;

        descriptor_ok_w = dst_shadow_private_q
                       && (source_row_count_q != 32'b0)
                       && (index_count_q >= 1)
                       && (index_count_q <= ID_COUNT_W'(MAX_IDS))
                       && (element_count_q >= 32)
                       && (element_count_q <= D_COUNT_W'(MAX_D))
                       && (element_count_q[4:0] == 5'b0)
                       && (src_slice_base_q[0] == 1'b0)
                       && (src_row_stride_q[0] == 1'b0)
                       && (packed_row_bytes_w[127:64] == 64'b0)
                       && ({64'b0, src_row_stride_q}
                           >= packed_row_bytes_w)
                       && (idx_stride_q >= 64'd4)
                       && (dst_slice_base_q[1:0] == 2'b00)
                       && (dst_row_stride_q[1:0] == 2'b00)
                       && (output_row_bytes_w[127:64] == 64'b0)
                       && ({64'b0, dst_row_stride_q}
                           >= output_row_bytes_w)
                       && (dst_window_bytes_q != 64'b0)
                       && (gmem_floor_q < gmem_limit_q)
                       && (total_outputs_w <= {96'b0, OUTPUT_DEPTH_U32});

        source_bounds_ok_w = (source_last_row_w[127:64] == 64'b0)
                          && (source_end_w[127:64] == 64'b0)
                          && (source_aligned_start_w[127:64] == 64'b0)
                          && (source_aligned_end_w[127:64] == 64'b0)
                          && (src_slice_base_q >= gmem_floor_q)
                          && (source_end_w[63:0] <= gmem_limit_q)
                          && (source_aligned_start_w[63:0]
                              >= gmem_floor_q)
                          && (source_aligned_end_w[63:0]
                              <= gmem_limit_q);

        index_bounds_ok_w = (index_last_w[127:64] == 64'b0)
                         && (index_end_w[127:64] == 64'b0)
                         && (index_aligned_start_w[127:64] == 64'b0)
                         && (index_aligned_end_w[127:64] == 64'b0)
                         && (idx_slice_base_q >= gmem_floor_q)
                         && (index_end_w[63:0] <= gmem_limit_q)
                         && (index_aligned_start_w[63:0] >= gmem_floor_q)
                         && (index_aligned_end_w[63:0] <= gmem_limit_q);

        destination_bounds_ok_w =
                             (dst_window_end_w[127:64] == 64'b0)
                          && (dst_last_row_w[127:64] == 64'b0)
                          && (dst_end_w[127:64] == 64'b0)
                          && (dst_aligned_start_w[127:64] == 64'b0)
                          && (dst_aligned_end_w[127:64] == 64'b0)
                          && (dst_slice_base_q >= gmem_floor_q)
                          && (dst_window_end_w[63:0] <= gmem_limit_q)
                          && (dst_end_w <= dst_window_end_w)
                          && (dst_aligned_start_w[63:0] >= gmem_floor_q)
                          && (dst_aligned_end_w[63:0] <= gmem_limit_q);

        // Read/read overlap is harmless.  A transaction-private destination
        // may not alias either read footprint because the ABI treats model
        // weights/indices as immutable even before publication.
        overlap_ok_w = ((dst_end_w <= {64'b0, src_slice_base_q})
                        || ({64'b0, dst_slice_base_q} >= source_end_w))
                    && ((dst_end_w <= {64'b0, idx_slice_base_q})
                        || ({64'b0, dst_slice_base_q} >= index_end_w));
    end

    // Re-prove each child stream coordinate before creating a write request.
    reg [127:0] runtime_row_offset_w;
    reg [127:0] runtime_lane_offset_w;
    reg [127:0] runtime_dst_addr_w;
    reg [127:0] runtime_dst_end_w;
    reg [127:0] runtime_aligned_addr_w;
    reg [127:0] runtime_aligned_end_w;
    reg         runtime_dst_valid_w;

    always @(*) begin
        runtime_row_offset_w = {
            {(128-ID_COUNT_W){1'b0}}, engine_out_id_position_w
        } * {64'b0, dst_row_stride_q};
        runtime_lane_offset_w = {
            {(128-D_COUNT_W){1'b0}}, engine_out_lane_index_w
        } * 128'd4;
        runtime_dst_addr_w = {64'b0, dst_slice_base_q}
                           + runtime_row_offset_w
                           + runtime_lane_offset_w;
        runtime_dst_end_w = runtime_dst_addr_w + 128'd4;
        runtime_aligned_addr_w = runtime_dst_addr_w;
        runtime_aligned_addr_w[2:0] = 3'b000;
        runtime_aligned_end_w = runtime_aligned_addr_w + 128'd8;
        runtime_dst_valid_w = (runtime_dst_addr_w[127:64] == 64'b0)
                           && (runtime_dst_end_w[127:64] == 64'b0)
                           && (runtime_aligned_addr_w[127:64] == 64'b0)
                           && (runtime_aligned_end_w[127:64] == 64'b0)
                           && (runtime_dst_addr_w[63:0]
                               >= dst_slice_base_q)
                           && (runtime_dst_end_w[63:0] <= dst_span_end_q)
                           && (runtime_aligned_addr_w[63:0]
                               >= gmem_floor_q)
                           && (runtime_aligned_end_w[63:0]
                               <= gmem_limit_q);
    end

    wire expected_row_last_w;
    wire expected_last_w;
    wire engine_stream_match_w;
    wire held_engine_stream_match_w;

    assign expected_row_last_w =
        (expected_lane_index_q == (element_count_q - 1'b1));
    assign expected_last_w = expected_row_last_w
                          && (expected_id_position_q
                              == (index_count_q - 1'b1));
    assign engine_stream_match_w = engine_out_valid_w
                                && runtime_dst_valid_w
                                && (engine_out_id_position_w
                                    == expected_id_position_q)
                                && (engine_out_lane_index_w
                                    == expected_lane_index_q)
                                && (engine_out_row_last_w
                                    == expected_row_last_w)
                                && (engine_out_last_w == expected_last_w);
    assign held_engine_stream_match_w = engine_out_valid_w
                                     && (engine_out_bits_w == write_bits_q)
                                     && (engine_out_id_position_w
                                         == write_id_position_q)
                                     && (engine_out_source_id_w
                                         == write_source_id_q)
                                     && (engine_out_lane_index_w
                                         == write_lane_index_q)
                                     && (engine_out_row_last_w
                                         == write_row_last_q)
                                     && (engine_out_last_w == write_last_q);

    // ------------------------------------------------------------------
    // Wrapped numeric gather engine and shared GMEM ownership mux.
    // ------------------------------------------------------------------
    wire engine_start_w;
    wire engine_ready_w;
    wire engine_busy_w;
    wire engine_gmem_req_valid_w;
    wire engine_gmem_req_ready_w;
    wire engine_gmem_req_write_w;
    wire [63:0] engine_gmem_req_addr_w;
    wire [63:0] engine_gmem_req_wdata_w;
    wire [7:0] engine_gmem_req_wstrb_w;
    wire engine_gmem_rsp_valid_w;
    wire engine_gmem_rsp_ready_w;
    wire engine_out_valid_w;
    wire engine_out_ready_w;
    wire [31:0] engine_out_bits_w;
    wire [ID_COUNT_W-1:0] engine_out_id_position_w;
    wire [31:0] engine_out_source_id_w;
    wire [D_COUNT_W-1:0] engine_out_lane_index_w;
    wire engine_out_row_last_w;
    wire engine_out_last_w;
    wire engine_done_w;
    wire engine_error_w;
    wire [4:0] engine_error_code_w;
    wire [31:0] engine_ids_scanned_w;
    wire [31:0] engine_blocks_done_w;
    wire [31:0] engine_outputs_emitted_w;
    wire [31:0] engine_gmem_beats_w;
    wire [31:0] engine_payload_bytes_w;
    wire [31:0] engine_active_cycles_w;
    wire engine_rst_w;

    assign engine_start_w = (state_q == ST_ENGINE_START)
                          && engine_ready_w
                          && !command_timeout_hit_w;
    assign engine_rst_w = rst_i || child_reset_q || (state_q == ST_ERROR);

    assign engine_gmem_req_ready_w = (state_q == ST_ENGINE_RUN)
                                   ? gmem_req_ready_i : 1'b0;
    assign engine_gmem_rsp_valid_w = (state_q == ST_ENGINE_RUN)
                                   ? gmem_rsp_valid_i : 1'b0;

    assign adapter_write_req_valid_w = (state_q == ST_WRITE_REQ)
                                     && !write_outstanding_q
                                     && held_engine_stream_match_w
                                     && !command_timeout_hit_w
                                     && !stall_timeout_hit_w;
    assign adapter_write_req_fire_w = adapter_write_req_valid_w
                                    && gmem_req_ready_i;
    assign adapter_write_rsp_ready_w = ((state_q == ST_WRITE_WAIT)
                                      || (state_q == ST_GMEM_DRAIN))
                                     && write_outstanding_q;
    assign adapter_write_rsp_fire_w = adapter_write_rsp_ready_w
                                    && gmem_rsp_valid_i;

    assign gmem_req_valid_o = (state_q == ST_ENGINE_RUN)
                            ? engine_gmem_req_valid_w
                            : adapter_write_req_valid_w;
    assign gmem_req_write_o = (state_q == ST_ENGINE_RUN)
                            ? engine_gmem_req_write_w
                            : (state_q == ST_WRITE_REQ);
    assign gmem_req_addr_o = (state_q == ST_ENGINE_RUN)
                           ? engine_gmem_req_addr_w : write_addr_q;
    assign gmem_req_wdata_o = (state_q == ST_ENGINE_RUN)
                            ? engine_gmem_req_wdata_w : write_data_q;
    assign gmem_req_wstrb_o = (state_q == ST_ENGINE_RUN)
                            ? engine_gmem_req_wstrb_w : write_strb_q;
    assign gmem_rsp_ready_o = (state_q == ST_ENGINE_RUN)
                            ? engine_gmem_rsp_ready_w
                            : adapter_write_rsp_ready_w;

    // The child stream advances at exactly the write-request acceptance edge.
    assign engine_out_ready_w = adapter_write_req_fire_w;

    assign ids_scanned_o          = ids_scanned_snapshot_q;
    assign blocks_done_o          = blocks_done_snapshot_q;
    assign outputs_accepted_o     = outputs_accepted_snapshot_q;
    assign gmem_read_beats_o      = gmem_read_beats_snapshot_q;
    assign read_payload_bytes_o   = read_payload_bytes_snapshot_q;
    assign engine_active_cycles_o = engine_active_cycles_snapshot_q;

    TensorNpuQ8GetRowsEngine #(
        .MAX_D                  (MAX_D),
        .MAX_IDS                (MAX_IDS),
        .STALL_TIMEOUT_CYCLES   (STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES (COMMAND_TIMEOUT_CYCLES)
    ) u_engine (
        .clk_i                 (clk_i),
        .rst_i                 (engine_rst_w),
        .start_i               (engine_start_w),
        .ready_o               (engine_ready_w),
        .busy_o                (engine_busy_w),
        .src_slice_base_i      (src_slice_base_q),
        .idx_slice_base_i      (idx_slice_base_q),
        .gmem_floor_i          (gmem_floor_q),
        .gmem_limit_i          (gmem_limit_q),
        .source_row_count_i    (source_row_count_q),
        .index_count_i         (index_count_q),
        .element_count_i       (element_count_q),
        .src_row_stride_i      (src_row_stride_q),
        .idx_stride_i          (idx_stride_q),
        .gmem_req_valid_o      (engine_gmem_req_valid_w),
        .gmem_req_ready_i      (engine_gmem_req_ready_w),
        .gmem_req_write_o      (engine_gmem_req_write_w),
        .gmem_req_addr_o       (engine_gmem_req_addr_w),
        .gmem_req_wdata_o      (engine_gmem_req_wdata_w),
        .gmem_req_wstrb_o      (engine_gmem_req_wstrb_w),
        .gmem_rsp_valid_i      (engine_gmem_rsp_valid_w),
        .gmem_rsp_ready_o      (engine_gmem_rsp_ready_w),
        .gmem_rsp_rdata_i      (gmem_rsp_rdata_i),
        .gmem_rsp_error_i      (gmem_rsp_error_i),
        .out_valid_o           (engine_out_valid_w),
        .out_ready_i           (engine_out_ready_w),
        .out_bits_o            (engine_out_bits_w),
        .out_id_position_o     (engine_out_id_position_w),
        .out_source_id_o       (engine_out_source_id_w),
        .out_lane_index_o      (engine_out_lane_index_w),
        .out_row_last_o        (engine_out_row_last_w),
        .out_last_o            (engine_out_last_w),
        .done_o                (engine_done_w),
        .error_o               (engine_error_w),
        .error_code_o          (engine_error_code_w),
        .ids_scanned_o         (engine_ids_scanned_w),
        .blocks_done_o         (engine_blocks_done_w),
        .outputs_emitted_o     (engine_outputs_emitted_w),
        .gmem_beats_o          (engine_gmem_beats_w),
        .payload_bytes_o       (engine_payload_bytes_w),
        .active_cycles_o       (engine_active_cycles_w)
    );

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                  <= ST_IDLE;
            command_id_q             <= 64'b0;
            dst_shadow_private_q     <= 1'b0;
            src_slice_base_q         <= 64'b0;
            idx_slice_base_q         <= 64'b0;
            dst_slice_base_q         <= 64'b0;
            dst_window_bytes_q       <= 64'b0;
            gmem_floor_q             <= 64'b0;
            gmem_limit_q             <= 64'b0;
            source_row_count_q       <= 32'b0;
            index_count_q            <= {ID_COUNT_W{1'b0}};
            element_count_q          <= {D_COUNT_W{1'b0}};
            src_row_stride_q         <= 64'b0;
            idx_stride_q             <= 64'b0;
            dst_row_stride_q         <= 64'b0;
            dst_span_end_q           <= 64'b0;
            total_outputs_q          <= 32'b0;
            expected_id_position_q   <= {ID_COUNT_W{1'b0}};
            expected_lane_index_q    <= {D_COUNT_W{1'b0}};
            write_addr_q             <= 64'b0;
            write_data_q             <= 64'b0;
            write_strb_q             <= 8'b0;
            write_bits_q             <= 32'b0;
            write_id_position_q      <= {ID_COUNT_W{1'b0}};
            write_source_id_q        <= 32'b0;
            write_lane_index_q       <= {D_COUNT_W{1'b0}};
            write_row_last_q         <= 1'b0;
            write_last_q             <= 1'b0;
            write_outstanding_q      <= 1'b0;
            child_done_seen_q        <= 1'b0;
            child_reset_q            <= 1'b0;
            stall_cycles_q           <= 32'b0;
            command_cycles_q         <= 64'b0;
            active_cycles_q          <= 64'b0;
            error_code_q             <= ERR_NONE;
            engine_error_code_q      <= 5'b0;
            drain_error_code_q       <= ERR_NONE;
            gmem_write_beats_q       <= 32'b0;
            writes_completed_q       <= 32'b0;
            write_bytes_q            <= 32'b0;
            ids_scanned_snapshot_q   <= 32'b0;
            blocks_done_snapshot_q   <= 32'b0;
            outputs_accepted_snapshot_q <= 32'b0;
            gmem_read_beats_snapshot_q <= 32'b0;
            read_payload_bytes_snapshot_q <= 32'b0;
            engine_active_cycles_snapshot_q <= 32'b0;
        end else begin
            child_reset_q <= 1'b0;

            // Completion counters are adapter-owned snapshots.  They remain
            // stable after a terminal child reset and are cleared only when a
            // new descriptor is accepted.
            if ((state_q == ST_ENGINE_START)
                    || (state_q == ST_ENGINE_RUN)
                    || (state_q == ST_WRITE_REQ)
                    || (state_q == ST_WRITE_WAIT)) begin
                ids_scanned_snapshot_q <= engine_ids_scanned_w;
                blocks_done_snapshot_q <= engine_blocks_done_w;
                outputs_accepted_snapshot_q <= engine_outputs_emitted_w;
                gmem_read_beats_snapshot_q <= engine_gmem_beats_w;
                read_payload_bytes_snapshot_q <= engine_payload_bytes_w;
                engine_active_cycles_snapshot_q <= engine_active_cycles_w;
            end

            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)) begin
                if (active_cycles_q != 64'hffff_ffff_ffff_ffff)
                    active_cycles_q <= active_cycles_q + 64'd1;
                if ((state_q != ST_GMEM_DRAIN)
                        && (command_cycles_q
                            != 64'hffff_ffff_ffff_ffff)) begin
                    command_cycles_q <= command_cycles_q + 64'd1;
                end
            end

            if (engine_done_w)
                child_done_seen_q <= 1'b1;

            if (adapter_write_req_fire_w) begin
                write_outstanding_q <= 1'b1;
                gmem_write_beats_q  <= gmem_write_beats_q + 32'd1;
            end
            if (adapter_write_rsp_fire_w) begin
                write_outstanding_q <= 1'b0;
                if (!gmem_rsp_error_i) begin
                    writes_completed_q <= writes_completed_q + 32'd1;
                    write_bytes_q      <= write_bytes_q + 32'd4;
                end
            end

            case (state_q)
                ST_IDLE: begin
                    stall_cycles_q   <= 32'b0;
                    command_cycles_q <= 64'b0;
                    if (start_fire_w) begin
                        command_id_q           <= command_id_i;
                        dst_shadow_private_q   <= dst_shadow_private_i;
                        src_slice_base_q       <= src_slice_base_i;
                        idx_slice_base_q       <= idx_slice_base_i;
                        dst_slice_base_q       <= dst_slice_base_i;
                        dst_window_bytes_q     <= dst_window_bytes_i;
                        gmem_floor_q           <= gmem_floor_i;
                        gmem_limit_q           <= gmem_limit_i;
                        source_row_count_q     <= source_row_count_i;
                        index_count_q          <= index_count_i;
                        element_count_q        <= element_count_i;
                        src_row_stride_q       <= src_row_stride_i;
                        idx_stride_q           <= idx_stride_i;
                        dst_row_stride_q       <= dst_row_stride_i;
                        dst_span_end_q         <= 64'b0;
                        total_outputs_q        <= 32'b0;
                        expected_id_position_q <= {ID_COUNT_W{1'b0}};
                        expected_lane_index_q  <= {D_COUNT_W{1'b0}};
                        write_addr_q           <= 64'b0;
                        write_data_q           <= 64'b0;
                        write_strb_q           <= 8'b0;
                        write_bits_q           <= 32'b0;
                        write_id_position_q    <= {ID_COUNT_W{1'b0}};
                        write_source_id_q      <= 32'b0;
                        write_lane_index_q     <= {D_COUNT_W{1'b0}};
                        write_row_last_q       <= 1'b0;
                        write_last_q           <= 1'b0;
                        write_outstanding_q    <= 1'b0;
                        child_done_seen_q      <= 1'b0;
                        stall_cycles_q         <= 32'b0;
                        command_cycles_q       <= 64'd1;
                        active_cycles_q        <= 64'd1;
                        error_code_q           <= ERR_NONE;
                        engine_error_code_q    <= 5'b0;
                        drain_error_code_q     <= ERR_NONE;
                        gmem_write_beats_q     <= 32'b0;
                        writes_completed_q     <= 32'b0;
                        write_bytes_q          <= 32'b0;
                        ids_scanned_snapshot_q <= 32'b0;
                        blocks_done_snapshot_q <= 32'b0;
                        outputs_accepted_snapshot_q <= 32'b0;
                        gmem_read_beats_snapshot_q <= 32'b0;
                        read_payload_bytes_snapshot_q <= 32'b0;
                        engine_active_cycles_snapshot_q <= 32'b0;
                        state_q                <= ST_PREFLIGHT;
                    end
                end

                ST_PREFLIGHT: begin
                    stall_cycles_q <= 32'b0;
                    if (!descriptor_ok_w) begin
                        error_code_q <= ERR_DESCRIPTOR;
                        state_q      <= ST_ERROR;
                    end else if (!source_bounds_ok_w) begin
                        error_code_q <= ERR_SOURCE_BOUNDS;
                        state_q      <= ST_ERROR;
                    end else if (!index_bounds_ok_w) begin
                        error_code_q <= ERR_INDEX_BOUNDS;
                        state_q      <= ST_ERROR;
                    end else if (!destination_bounds_ok_w) begin
                        error_code_q <= ERR_DEST_BOUNDS;
                        state_q      <= ST_ERROR;
                    end else if (!overlap_ok_w) begin
                        error_code_q <= ERR_OVERLAP;
                        state_q      <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q      <= ST_ERROR;
                    end else begin
                        dst_span_end_q  <= dst_end_w[63:0];
                        total_outputs_q <= total_outputs_w[31:0];
                        state_q         <= ST_ENGINE_START;
                    end
                end

                ST_ENGINE_START: begin
                    stall_cycles_q <= 32'b0;
                    if (engine_error_w || engine_busy_w) begin
                        error_code_q        <= ERR_ENGINE_PROTOCOL;
                        engine_error_code_q <= engine_error_code_w;
                        child_reset_q       <= 1'b1;
                        state_q             <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q  <= ERR_COMMAND_TIMEOUT;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else if (engine_ready_w) begin
                        state_q <= ST_ENGINE_RUN;
                    end
                end

                ST_ENGINE_RUN: begin
                    stall_cycles_q <= 32'b0;
                    if (engine_error_w) begin
                        error_code_q        <= ERR_ENGINE;
                        engine_error_code_q <= engine_error_code_w;
                        child_reset_q       <= 1'b1;
                        state_q             <= ST_ERROR;
                    end else if (engine_done_w) begin
                        error_code_q  <= ERR_ENGINE_PROTOCOL;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else if (engine_out_valid_w) begin
                        if (command_timeout_hit_w) begin
                            error_code_q  <= ERR_COMMAND_TIMEOUT;
                            child_reset_q <= 1'b1;
                            state_q       <= ST_ERROR;
                        end else if (!engine_stream_match_w
                                || engine_gmem_req_valid_w
                                || engine_gmem_rsp_ready_w) begin
                            error_code_q  <= ERR_ENGINE_PROTOCOL;
                            child_reset_q <= 1'b1;
                            state_q       <= ST_ERROR;
                        end else begin
                            write_addr_q <= runtime_aligned_addr_w[63:0];
                            write_bits_q <= engine_out_bits_w;
                            write_id_position_q <= engine_out_id_position_w;
                            write_source_id_q <= engine_out_source_id_w;
                            write_lane_index_q <= engine_out_lane_index_w;
                            write_row_last_q <= engine_out_row_last_w;
                            write_last_q     <= engine_out_last_w;
                            if (runtime_dst_addr_w[2]) begin
                                write_data_q <= {engine_out_bits_w, 32'b0};
                                write_strb_q <= 8'hf0;
                            end else begin
                                write_data_q <= {32'b0, engine_out_bits_w};
                                write_strb_q <= 8'h0f;
                            end
                            state_q <= ST_WRITE_REQ;
                        end
                    end else if (!engine_busy_w && engine_ready_w) begin
                        error_code_q  <= ERR_ENGINE_PROTOCOL;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end
                end

                ST_WRITE_REQ: begin
                    if (engine_error_w || !held_engine_stream_match_w) begin
                        error_code_q        <= ERR_ENGINE_PROTOCOL;
                        engine_error_code_q <= engine_error_code_w;
                        child_reset_q       <= 1'b1;
                        state_q             <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q  <= ERR_COMMAND_TIMEOUT;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q  <= ERR_STALL_TIMEOUT;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else if (adapter_write_req_fire_w) begin
                        stall_cycles_q <= 32'b0;
                        if (write_row_last_q) begin
                            expected_id_position_q <= expected_id_position_q
                                                      + 1'b1;
                            expected_lane_index_q <= {D_COUNT_W{1'b0}};
                        end else begin
                            expected_lane_index_q <= expected_lane_index_q
                                                   + 1'b1;
                        end
                        state_q <= ST_WRITE_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_WRITE_WAIT: begin
                    if (adapter_write_rsp_fire_w && gmem_rsp_error_i) begin
                        error_code_q  <= ERR_GMEM_RESPONSE;
                        child_reset_q <= 1'b1;
                        state_q       <= ST_ERROR;
                    end else if (engine_error_w) begin
                        engine_error_code_q <= engine_error_code_w;
                        child_reset_q       <= 1'b1;
                        if (adapter_write_rsp_fire_w) begin
                            error_code_q <= ERR_ENGINE;
                            state_q      <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_ENGINE;
                            state_q            <= ST_GMEM_DRAIN;
                        end
                    end else if (command_timeout_hit_w) begin
                        child_reset_q <= 1'b1;
                        if (adapter_write_rsp_fire_w) begin
                            error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_GMEM_DRAIN;
                        end
                    end else if (stall_timeout_hit_w) begin
                        child_reset_q <= 1'b1;
                        if (adapter_write_rsp_fire_w) begin
                            error_code_q <= ERR_STALL_TIMEOUT;
                            state_q      <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_STALL_TIMEOUT;
                            state_q            <= ST_GMEM_DRAIN;
                        end
                    end else if (adapter_write_rsp_fire_w) begin
                        stall_cycles_q <= 32'b0;
                        if (write_last_q) begin
                            if (!(child_done_seen_q || engine_done_w)
                                    || (writes_completed_q + 32'd1
                                        != total_outputs_q)
                                    || (gmem_write_beats_q
                                        != total_outputs_q)
                                    || (engine_outputs_emitted_w
                                        != total_outputs_q)) begin
                                error_code_q  <= ERR_ENGINE_PROTOCOL;
                                child_reset_q <= 1'b1;
                                state_q       <= ST_ERROR;
                            end else begin
                                state_q <= ST_DONE;
                            end
                        end else begin
                            state_q <= ST_ENGINE_RUN;
                        end
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_GMEM_DRAIN: begin
                    // A write request already owns one response credit.  Keep
                    // only that credit live; no new request, output handshake
                    // or publication is possible while the response drains.
                    if (adapter_write_rsp_fire_w) begin
                        error_code_q <= gmem_rsp_error_i
                                      ? ERR_GMEM_RESPONSE
                                      : drain_error_code_q;
                        state_q <= ST_ERROR;
                    end
                end

                ST_DONE: begin
                    state_q <= ST_IDLE;
                end

                ST_ERROR: begin
                    // state_q==ST_ERROR already drives one complete child
                    // reset cycle.  Let the default clear child_reset_q so
                    // IDLE reopens immediately after the terminal pulse.
                    state_q <= ST_IDLE;
                end

                default: begin
                    error_code_q  <= ERR_INTERNAL_STATE;
                    child_reset_q <= 1'b1;
                    state_q       <= ST_ERROR;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
