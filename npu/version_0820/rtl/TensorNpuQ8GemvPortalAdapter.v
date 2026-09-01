`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// Transactional Row-SIMD Q8_0 GEMV adapter.
//
// Activation F32 words and result F32 words use the raw, eight-byte,
// single-outstanding GMEM channel.  Q8_0 weights use a separate portal whose
// only legal operation is copying the 34 raw bytes named by each RTL-proved
// address.  TensorNpuQ8RowSimdCore is the sole numerical child: its one public
// reference quantizer owns activation quantization and its ROW_LANES public
// scale accumulators own every dot, scale multiply, term multiply, and RN32
// accumulation.
//
// Portal order is fixed as (row_base tile, block_index, lane).  One request
// group can be outstanding.  Every active lane address is formed with a
// 128-bit intermediate and the complete 34-byte span is re-proved against the
// immutable weight capability before request publication.  A bad response
// mask or portal error is atomic: the numerical child is reset, dst_commit_o
// is suppressed, and all accepted transport transactions are drained before
// the terminal pulse.
module TensorNpuQ8GemvPortalAdapter #(
    parameter integer MAX_ROWS = 248320,
    parameter integer MAX_BLOCKS = 128,
    parameter integer ROW_LANES = 4,
    parameter integer MAC_LANES = 32,
    parameter integer TILE_FUNCTIONAL_ENABLE = 0,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd4096,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd1000000000
) (
    input  wire                          clk_i,
    input  wire                          rst_i,

    input  wire                          start_i,
    output wire                          ready_o,
    output wire                          busy_o,
    input  wire [63:0]                   command_id_i,
    input  wire                          dst_shadow_private_i,
    input  wire                          windows_generation_valid_i,

    input  wire [63:0]                   activation_base_i,
    input  wire [63:0]                   weight_base_i,
    input  wire [63:0]                   dst_base_i,
    input  wire [31:0]                   row_count_i,
    input  wire [31:0]                   block_count_i,
    input  wire [63:0]                   weight_row_stride_i,
    input  wire [63:0]                   dst_row_stride_i,

    input  wire [63:0]                   activation_window_base_i,
    input  wire [63:0]                   activation_window_bytes_i,
    input  wire                          activation_window_read_i,
    input  wire                          activation_window_write_i,
    input  wire [63:0]                   weight_window_base_i,
    input  wire [63:0]                   weight_window_bytes_i,
    input  wire                          weight_window_read_i,
    input  wire                          weight_window_write_i,
    input  wire [63:0]                   dst_window_base_i,
    input  wire [63:0]                   dst_window_bytes_i,
    input  wire                          dst_window_read_i,
    input  wire                          dst_window_write_i,

    // Raw, eight-byte, single-outstanding activation/result channel.
    output wire                          gmem_req_valid_o,
    input  wire                          gmem_req_ready_i,
    output wire                          gmem_req_write_o,
    output wire [63:0]                   gmem_req_addr_o,
    output wire [63:0]                   gmem_req_wdata_o,
    output wire [7:0]                    gmem_req_wstrb_o,
    input  wire                          gmem_rsp_valid_i,
    output wire                          gmem_rsp_ready_o,
    input  wire [63:0]                   gmem_rsp_rdata_i,
    input  wire                          gmem_rsp_error_i,

    // Raw Q8_0 block portal.  Lane k always occupies [k*W +: W].
    output wire                          portal_req_valid_o,
    input  wire                          portal_req_ready_i,
    output wire [ROW_LANES-1:0]          portal_req_mask_o,
    output wire [(ROW_LANES*64)-1:0]     portal_req_addr_o,
    input  wire                          portal_rsp_valid_i,
    output wire                          portal_rsp_ready_o,
    input  wire [ROW_LANES-1:0]          portal_rsp_mask_i,
    input  wire [(ROW_LANES*272)-1:0]    portal_rsp_blocks_i,
    input  wire                          portal_rsp_error_i,

    // completion_valid_o qualifies identity, terminal status, and counters.
    output wire                          completion_valid_o,
    output wire                          dst_commit_o,
    output wire [63:0]                   completion_command_id_o,
    output wire [31:0]                   completion_kernel_id_o,
    output wire [31:0]                   completion_row_count_o,
    output wire [31:0]                   completion_block_count_o,
    output wire                          done_o,
    output wire                          error_o,
    output wire [4:0]                    error_code_o,
    output wire [7:0]                    child_error_code_o,

    output wire [31:0]                   activation_words_accepted_o,
    output wire [63:0]                   weight_blocks_accepted_o,
    output wire [31:0]                   rows_written_o,
    output wire [63:0]                   gmem_read_beats_o,
    output wire [63:0]                   gmem_read_beats_completed_o,
    output wire [63:0]                   gmem_read_bytes_o,
    output wire [63:0]                   activation_payload_bytes_o,
    output wire [63:0]                   weight_payload_bytes_o,
    output wire [31:0]                   gmem_write_beats_o,
    output wire [31:0]                   writes_completed_o,
    output wire [63:0]                   write_bytes_o,
    output wire [63:0]                   child_active_cycles_o,
    output wire [63:0]                   active_cycles_o,
    output wire                          gmem_outstanding_o,
    output wire [63:0]                   portal_request_groups_o,
    output wire [63:0]                   portal_response_groups_o,
    output wire [63:0]                   portal_blocks_o,
    output wire [63:0]                   portal_bytes_o,
    output wire                          portal_outstanding_o
);

    localparam [31:0] KERNEL_ID_GEMV_Q8_0_F32 = 32'h514e0002;
    localparam [31:0] MAX_ROWS_U32 = MAX_ROWS;
    localparam [31:0] MAX_BLOCKS_U32 = MAX_BLOCKS;
    localparam [31:0] ROW_LANES_U32 = ROW_LANES;

    localparam [4:0] ST_IDLE          = 5'd0;
    localparam [4:0] ST_PREFLIGHT     = 5'd1;
    localparam [4:0] ST_CHILD_START   = 5'd2;
    localparam [4:0] ST_ACT_LOOKUP    = 5'd3;
    localparam [4:0] ST_ACT_REQ       = 5'd4;
    localparam [4:0] ST_ACT_WAIT      = 5'd5;
    localparam [4:0] ST_ACT_SEND      = 5'd6;
    localparam [4:0] ST_PORTAL_PREP   = 5'd7;
    localparam [4:0] ST_PORTAL_REQ    = 5'd8;
    localparam [4:0] ST_PORTAL_WAIT   = 5'd9;
    localparam [4:0] ST_RESULT_WAIT   = 5'd10;
    localparam [4:0] ST_WRITE_PREP    = 5'd11;
    localparam [4:0] ST_WRITE_REQ     = 5'd12;
    localparam [4:0] ST_WRITE_WAIT    = 5'd13;
    localparam [4:0] ST_FINAL_WAIT    = 5'd14;
    localparam [4:0] ST_DRAIN         = 5'd15;
    localparam [4:0] ST_DONE          = 5'd16;
    localparam [4:0] ST_ERROR         = 5'd17;
    localparam [4:0] ST_TILE_SEND     = 5'd18;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_DESCRIPTOR      = 5'd1;
    localparam [4:0] ERR_ACTIVATION_WIN  = 5'd2;
    localparam [4:0] ERR_WEIGHT_WIN      = 5'd3;
    localparam [4:0] ERR_DEST_WIN        = 5'd4;
    localparam [4:0] ERR_ALIAS           = 5'd5;
    localparam [4:0] ERR_CHILD           = 5'd6;
    localparam [4:0] ERR_CHILD_PROTOCOL  = 5'd7;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd8;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd9;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd10;
    localparam [4:0] ERR_INTERNAL        = 5'd11;
    localparam [4:0] ERR_PORTAL_RESPONSE = 5'd12;
    localparam [4:0] ERR_PORTAL_MASK     = 5'd13;

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                        : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 64'd1) ? 64'd0
                                          : COMMAND_TIMEOUT_CYCLES - 64'd1;

    generate
        if ((MAX_ROWS < 1) || (MAX_BLOCKS < 1)) begin : gen_bad_limits
            initial $fatal(1, "Q8 portal adapter limits must be positive");
        end
        if (MAX_BLOCKS > 128) begin : gen_bad_core_limit
            initial $fatal(1, "Q8 portal adapter MAX_BLOCKS exceeds core bank");
        end
        if ((ROW_LANES < 1) || (ROW_LANES > 8)) begin : gen_bad_rows
            initial $fatal(1, "Q8 portal adapter ROW_LANES must be in 1..8");
        end
        if ((MAC_LANES < 1) || (MAC_LANES > 32)) begin : gen_bad_macs
            initial $fatal(1, "Q8 portal adapter MAC_LANES must be in 1..32");
        end
        if ((TILE_FUNCTIONAL_ENABLE != 0) && (MAC_LANES != 32)) begin
            : gen_bad_tile_functional_macs
            initial $fatal(1,
                "Q8 tile functional core requires MAC_LANES=32");
        end
    endgenerate

    function automatic [31:0] popcount_lanes;
        input [ROW_LANES-1:0] lane_mask;
        integer count_lane;
        begin
            popcount_lanes = 32'b0;
            for (count_lane = 0; count_lane < ROW_LANES;
                 count_lane = count_lane + 1) begin
                if (lane_mask[count_lane])
                    popcount_lanes = popcount_lanes + 32'd1;
            end
        end
    endfunction

    reg [4:0] state_q;

    // Resident command.  start_i is deliberately ignored outside IDLE.
    reg [63:0] command_id_q;
    reg        dst_shadow_private_q;
    reg        windows_generation_valid_q;
    reg [63:0] activation_base_q;
    reg [63:0] weight_base_q;
    reg [63:0] dst_base_q;
    reg [31:0] row_count_q;
    reg [31:0] block_count_q;
    reg [63:0] weight_row_stride_q;
    reg [63:0] dst_row_stride_q;
    reg [63:0] activation_window_base_q;
    reg [63:0] activation_window_bytes_q;
    reg        activation_window_read_q;
    reg        activation_window_write_q;
    reg [63:0] weight_window_base_q;
    reg [63:0] weight_window_bytes_q;
    reg        weight_window_read_q;
    reg        weight_window_write_q;
    reg [63:0] dst_window_base_q;
    reg [63:0] dst_window_bytes_q;
    reg        dst_window_read_q;
    reg        dst_window_write_q;
    reg [63:0] activation_semantic_end_q;
    reg [63:0] weight_semantic_end_q;
    reg [63:0] dst_semantic_end_q;

    // Activation raw-transport coordinates and one aligned-beat cache.
    reg [31:0] activation_word_index_q;
    reg        cache_valid_q;
    reg [63:0] cache_addr_q;
    reg [63:0] cache_data_q;
    reg [31:0] activation_word_q;

    // Portal coordinates and the resident, backpressure-stable request.
    reg [31:0] portal_row_base_q;
    reg [31:0] portal_block_index_q;
    reg [ROW_LANES-1:0] portal_req_mask_q;
    reg [(ROW_LANES*64)-1:0] portal_req_addr_q;
    reg portal_outstanding_q;
    // In simulation-only tile mode, accepted raw34 portal responses remain
    // RTL-owned while one complete row tile is assembled.  Lane-major,
    // block-major layout exactly matches TensorNpuQ8RowTileFunctionalCore.
    reg [(ROW_LANES*MAX_BLOCKS*272)-1:0] weight_tile_bank_q;

    // A child result batch remains unacknowledged until every private write
    // response closes successfully.
    reg [(ROW_LANES*32)-1:0] held_result_bits_q;
    reg [ROW_LANES-1:0] held_result_mask_q;
    reg [31:0] held_result_row_base_q;
    reg [31:0] write_lane_q;
    reg [63:0] held_write_addr_q;
    reg [63:0] held_write_data_q;
    reg [7:0] held_write_strb_q;

    reg        outstanding_q;
    reg        outstanding_write_q;
    reg [63:0] outstanding_addr_q;
    reg        child_reset_q;
    reg [4:0]  drain_error_code_q;
    reg [4:0]  error_code_q;
    reg [7:0]  child_error_code_q;
    reg [31:0] stall_cycles_q;
    reg [63:0] command_cycles_q;
    reg [63:0] active_cycles_q;

    reg [31:0] activation_words_accepted_q;
    reg [63:0] weight_blocks_accepted_q;
    reg [31:0] rows_written_q;
    reg [63:0] gmem_read_beats_q;
    reg [63:0] gmem_read_beats_completed_q;
    reg [63:0] gmem_read_bytes_q;
    reg [63:0] activation_payload_bytes_q;
    reg [63:0] weight_payload_bytes_q;
    reg [31:0] gmem_write_beats_q;
    reg [31:0] writes_completed_q;
    reg [63:0] write_bytes_q;
    reg [63:0] child_active_cycles_snapshot_q;
    reg [63:0] portal_request_groups_q;
    reg [63:0] portal_response_groups_q;
    reg [63:0] portal_blocks_q;
    reg [63:0] portal_bytes_q;

    assign ready_o = !rst_i && (state_q == ST_IDLE) && child_ready_w;
    assign busy_o = !rst_i && (state_q != ST_IDLE);
    assign done_o = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign completion_valid_o = done_o || error_o;
    assign dst_commit_o = done_o;
    assign completion_command_id_o = completion_valid_o ? command_id_q : 64'b0;
    assign completion_kernel_id_o = completion_valid_o
                                  ? KERNEL_ID_GEMV_Q8_0_F32 : 32'b0;
    assign completion_row_count_o = completion_valid_o ? row_count_q : 32'b0;
    assign completion_block_count_o = completion_valid_o ? block_count_q : 32'b0;
    assign error_code_o = error_code_q;
    assign child_error_code_o = child_error_code_q;

    assign activation_words_accepted_o = activation_words_accepted_q;
    assign weight_blocks_accepted_o = weight_blocks_accepted_q;
    assign rows_written_o = rows_written_q;
    assign gmem_read_beats_o = gmem_read_beats_q;
    assign gmem_read_beats_completed_o = gmem_read_beats_completed_q;
    assign gmem_read_bytes_o = gmem_read_bytes_q;
    assign activation_payload_bytes_o = activation_payload_bytes_q;
    assign weight_payload_bytes_o = weight_payload_bytes_q;
    assign gmem_write_beats_o = gmem_write_beats_q;
    assign writes_completed_o = writes_completed_q;
    assign write_bytes_o = write_bytes_q;
    assign child_active_cycles_o = child_active_cycles_snapshot_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign portal_request_groups_o = portal_request_groups_q;
    assign portal_response_groups_o = portal_response_groups_q;
    assign portal_blocks_o = portal_blocks_q;
    assign portal_bytes_o = portal_bytes_q;
    assign portal_outstanding_o = portal_outstanding_q;

    wire start_fire_w = start_i && ready_o;
    wire command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);

    // ------------------------------------------------------------------
    // Whole-command preflight with 128-bit arithmetic.
    // ------------------------------------------------------------------
    reg [127:0] rows_minus_one_w;
    reg [127:0] activation_words_w;
    reg [127:0] activation_bytes_w;
    reg [127:0] weight_blocks_w;
    reg [127:0] weight_row_bytes_w;
    reg [127:0] output_bytes_w;
    reg [127:0] activation_window_end_w;
    reg [127:0] weight_window_end_w;
    reg [127:0] dst_window_end_w;
    reg [127:0] activation_end_w;
    reg [127:0] weight_last_row_w;
    reg [127:0] weight_end_w;
    reg [127:0] dst_last_row_w;
    reg [127:0] dst_end_w;
    reg [127:0] activation_phys_start_w;
    reg [127:0] activation_phys_end_w;
    reg [127:0] weight_phys_start_w;
    reg [127:0] weight_phys_end_w;
    reg [127:0] dst_phys_start_w;
    reg [127:0] dst_phys_end_w;
    reg [127:0] align_tmp_w;
    reg descriptor_ok_w;
    reg activation_window_ok_w;
    reg weight_window_ok_w;
    reg dst_window_ok_w;
    reg alias_ok_w;

    always @(*) begin
        rows_minus_one_w = {96'b0, row_count_q} - 128'd1;
        activation_words_w = {96'b0, block_count_q} * 128'd32;
        activation_bytes_w = activation_words_w * 128'd4;
        weight_blocks_w = {96'b0, row_count_q} * {96'b0, block_count_q};
        weight_row_bytes_w = {96'b0, block_count_q} * 128'd34;
        output_bytes_w = {96'b0, row_count_q} * 128'd4;

        activation_window_end_w = {64'b0, activation_window_base_q}
                                + {64'b0, activation_window_bytes_q};
        weight_window_end_w = {64'b0, weight_window_base_q}
                            + {64'b0, weight_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};
        activation_end_w = {64'b0, activation_base_q} + activation_bytes_w;
        weight_last_row_w = {64'b0, weight_base_q}
                          + rows_minus_one_w * {64'b0, weight_row_stride_q};
        weight_end_w = weight_last_row_w + weight_row_bytes_w;
        dst_last_row_w = {64'b0, dst_base_q}
                       + rows_minus_one_w * {64'b0, dst_row_stride_q};
        dst_end_w = dst_last_row_w + 128'd4;

        activation_phys_start_w = {64'b0, activation_base_q};
        activation_phys_start_w[2:0] = 3'b000;
        align_tmp_w = activation_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        activation_phys_end_w = align_tmp_w + 128'd8;

        // Keep the legacy adapter's conservative aligned physical envelope
        // for alias protection even though the portal transfers exact bytes.
        weight_phys_start_w = {64'b0, weight_base_q};
        weight_phys_start_w[2:0] = 3'b000;
        align_tmp_w = weight_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        weight_phys_end_w = align_tmp_w + 128'd8;

        dst_phys_start_w = {64'b0, dst_base_q};
        dst_phys_start_w[2:0] = 3'b000;
        align_tmp_w = dst_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        dst_phys_end_w = align_tmp_w + 128'd8;

        descriptor_ok_w = dst_shadow_private_q
                       && windows_generation_valid_q
                       && (row_count_q >= 32'd1)
                       && (row_count_q <= MAX_ROWS_U32)
                       && (block_count_q >= 32'd1)
                       && (block_count_q <= MAX_BLOCKS_U32)
                       && (activation_base_q[1:0] == 2'b00)
                       && (weight_base_q[0] == 1'b0)
                       && (weight_row_stride_q[0] == 1'b0)
                       && (weight_row_bytes_w[127:64] == 64'b0)
                       && ({64'b0, weight_row_stride_q} >= weight_row_bytes_w)
                       && (dst_base_q[1:0] == 2'b00)
                       && (dst_row_stride_q[1:0] == 2'b00)
                       && (dst_row_stride_q >= 64'd4)
                       && (activation_window_bytes_q != 64'b0)
                       && (weight_window_bytes_q != 64'b0)
                       && (dst_window_bytes_q != 64'b0)
                       && (activation_window_base_q[2:0] == 3'b000)
                       && (weight_window_base_q[2:0] == 3'b000)
                       && (dst_window_base_q[2:0] == 3'b000)
                       && (activation_window_bytes_q[2:0] == 3'b000)
                       && (weight_window_bytes_q[2:0] == 3'b000)
                       && (dst_window_bytes_q[2:0] == 3'b000)
                       && activation_window_read_q
                       && !activation_window_write_q
                       && weight_window_read_q
                       && !weight_window_write_q
                       && !dst_window_read_q
                       && dst_window_write_q
                       && (activation_words_w[127:32] == 96'b0)
                       && (weight_blocks_w[127:64] == 64'b0)
                       && (output_bytes_w[127:64] == 64'b0);

        activation_window_ok_w =
               (activation_window_end_w[127:64] == 64'b0)
            && (activation_end_w[127:64] == 64'b0)
            && (activation_phys_start_w[127:64] == 64'b0)
            && (activation_phys_end_w[127:64] == 64'b0)
            && (activation_phys_start_w >= {64'b0, activation_window_base_q})
            && (activation_phys_end_w <= activation_window_end_w);

        weight_window_ok_w =
               (weight_window_end_w[127:64] == 64'b0)
            && (weight_last_row_w[127:64] == 64'b0)
            && (weight_end_w[127:64] == 64'b0)
            && (weight_phys_start_w[127:64] == 64'b0)
            && (weight_phys_end_w[127:64] == 64'b0)
            && (weight_phys_start_w >= {64'b0, weight_window_base_q})
            && (weight_phys_end_w <= weight_window_end_w);

        dst_window_ok_w =
               (dst_window_end_w[127:64] == 64'b0)
            && (dst_last_row_w[127:64] == 64'b0)
            && (dst_end_w[127:64] == 64'b0)
            && (dst_phys_start_w[127:64] == 64'b0)
            && (dst_phys_end_w[127:64] == 64'b0)
            && (dst_phys_start_w >= {64'b0, dst_window_base_q})
            && (dst_phys_end_w <= dst_window_end_w);

        alias_ok_w = ((dst_phys_end_w <= activation_phys_start_w)
                      || (dst_phys_start_w >= activation_phys_end_w))
                  && ((dst_phys_end_w <= weight_phys_start_w)
                      || (dst_phys_start_w >= weight_phys_end_w));
    end

    // ------------------------------------------------------------------
    // Runtime coordinate proofs.
    // ------------------------------------------------------------------
    reg [127:0] activation_word_addr_w;
    reg [127:0] activation_aligned_addr_w;
    reg activation_runtime_ok_w;
    reg [127:0] result_addr_w;
    reg [127:0] result_aligned_addr_w;
    reg result_runtime_ok_w;

    always @(*) begin
        activation_word_addr_w = {64'b0, activation_base_q}
                               + {96'b0, activation_word_index_q} * 128'd4;
        activation_aligned_addr_w = activation_word_addr_w;
        activation_aligned_addr_w[2:0] = 3'b000;
        activation_runtime_ok_w =
               (activation_word_addr_w[127:64] == 64'b0)
            && (activation_aligned_addr_w[127:64] == 64'b0)
            && ((activation_word_addr_w + 128'd4)
                <= {64'b0, activation_semantic_end_q})
            && (activation_aligned_addr_w
                >= {64'b0, activation_window_base_q})
            && ((activation_aligned_addr_w + 128'd8)
                <= activation_window_end_w);

        result_addr_w = {64'b0, dst_base_q}
                      + ({96'b0, held_result_row_base_q}
                         + {96'b0, write_lane_q})
                        * {64'b0, dst_row_stride_q};
        result_aligned_addr_w = result_addr_w;
        result_aligned_addr_w[2:0] = 3'b000;
        result_runtime_ok_w =
               (write_lane_q < ROW_LANES_U32)
            && held_result_mask_q[write_lane_q]
            && (({1'b0, held_result_row_base_q}
                 + {1'b0, write_lane_q}) < {1'b0, row_count_q})
            && (result_addr_w[127:64] == 64'b0)
            && (result_aligned_addr_w[127:64] == 64'b0)
            && ((result_addr_w + 128'd4) <= {64'b0, dst_semantic_end_q})
            && (result_aligned_addr_w >= {64'b0, dst_window_base_q})
            && ((result_aligned_addr_w + 128'd8) <= dst_window_end_w);
    end

    // Portal request construction.  Inactive tail lanes publish zero address;
    // active lanes each receive an independent complete-span proof.
    reg [ROW_LANES-1:0] portal_candidate_mask_r;
    reg [(ROW_LANES*64)-1:0] portal_candidate_addr_r;
    reg portal_candidate_ok_r;
    reg [127:0] portal_abs_row_r;
    reg [127:0] portal_addr_r;
    reg [127:0] portal_row_end_r;
    integer portal_lane;
    integer tile_store_lane;
    always @(*) begin
        portal_candidate_mask_r = {ROW_LANES{1'b0}};
        portal_candidate_addr_r = {(ROW_LANES*64){1'b0}};
        portal_candidate_ok_r = (portal_row_base_q < row_count_q)
                              && (portal_block_index_q < block_count_q);
        portal_abs_row_r = 128'b0;
        portal_addr_r = 128'b0;
        portal_row_end_r = 128'b0;
        for (portal_lane = 0; portal_lane < ROW_LANES;
             portal_lane = portal_lane + 1) begin
            portal_abs_row_r = {96'b0, portal_row_base_q}
                             + {96'b0, portal_lane[31:0]};
            if (portal_abs_row_r < {96'b0, row_count_q}) begin
                portal_candidate_mask_r[portal_lane] = 1'b1;
                portal_addr_r = {64'b0, weight_base_q}
                              + portal_abs_row_r
                                * {64'b0, weight_row_stride_q}
                              + {96'b0, portal_block_index_q} * 128'd34;
                portal_row_end_r = {64'b0, weight_base_q}
                                 + portal_abs_row_r
                                   * {64'b0, weight_row_stride_q}
                                 + {96'b0, block_count_q} * 128'd34;
                portal_candidate_addr_r[(portal_lane*64) +: 64]
                    = portal_addr_r[63:0];
                if ((portal_addr_r[127:64] != 64'b0)
                    || (portal_row_end_r[127:64] != 64'b0)
                    || (portal_addr_r < {64'b0, weight_window_base_q})
                    || ((portal_addr_r + 128'd34) > weight_window_end_w)
                    || ((portal_addr_r + 128'd34) > portal_row_end_r)
                    || ((portal_addr_r + 128'd34)
                        > {64'b0, weight_semantic_end_q})) begin
                    portal_candidate_ok_r = 1'b0;
                end
            end
        end
        if (portal_candidate_mask_r == {ROW_LANES{1'b0}})
            portal_candidate_ok_r = 1'b0;
    end

    // ------------------------------------------------------------------
    // Sole numerical child.
    // ------------------------------------------------------------------
    wire child_rst_w = rst_i || child_reset_q || (state_q == ST_ERROR);
    wire child_start_w = (state_q == ST_CHILD_START)
                       && !command_timeout_hit_w;
    wire child_ready_w;
    wire child_busy_w;
    wire child_activation_ready_w;
    wire child_activation_valid_w = (state_q == ST_ACT_SEND)
                                  && !command_timeout_hit_w;
    wire child_activation_fire_w = child_activation_valid_w
                                 && child_activation_ready_w;
    wire child_weight_ready_w;
    wire portal_mask_match_w = (portal_rsp_mask_i == portal_req_mask_q);
    wire portal_payload_qualifies_w = (state_q == ST_PORTAL_WAIT)
                                    && portal_outstanding_q
                                    && portal_rsp_valid_i
                                    && portal_mask_match_w
                                    && !portal_rsp_error_i
                                    && !command_timeout_hit_w;
    wire child_weight_valid_w;
    wire child_weight_fire_w = child_weight_valid_w && child_weight_ready_w;
    wire child_result_valid_w;
    wire child_result_ready_w;
    wire [(ROW_LANES*32)-1:0] child_result_bits_w;
    wire [ROW_LANES-1:0] child_result_mask_w;
    wire [31:0] child_result_row_base_w;
    wire child_done_w;
    wire child_error_w;
    wire [7:0] child_error_code_w;
    wire [31:0] child_error_row_w;
    wire [63:0] child_active_cycles_w;
    wire [31:0] child_activation_words_w;
    wire [63:0] child_weight_blocks_w;
    wire [31:0] child_rows_emitted_w;

    wire held_batch_match_w = child_result_valid_w
                            && (child_result_bits_w == held_result_bits_q)
                            && (child_result_mask_w == held_result_mask_q)
                            && (child_result_row_base_w
                                == held_result_row_base_q);
    wire last_write_lane_w =
        ((held_result_mask_q >> (write_lane_q + 32'd1))
         == {ROW_LANES{1'b0}});

    generate
        if (TILE_FUNCTIONAL_ENABLE != 0) begin : gen_tile_functional_core
            assign child_weight_valid_w = (state_q == ST_TILE_SEND)
                                          && !command_timeout_hit_w;
            TensorNpuQ8RowTileFunctionalCore #(
                .ROW_LANES (ROW_LANES),
                .MAX_BLOCKS(MAX_BLOCKS)
            ) u_row_tile_functional_core (
                .clk_i                       (clk_i),
                .rst_i                       (child_rst_w),
                .start_i                     (child_start_w),
                .ready_o                     (child_ready_w),
                .busy_o                      (child_busy_w),
                .row_count_i                 (row_count_q),
                .block_count_i               (block_count_q),
                .activation_valid_i          (child_activation_valid_w),
                .activation_ready_o          (child_activation_ready_w),
                .activation_bits_i           (activation_word_q),
                .weight_tile_valid_i         (child_weight_valid_w),
                .weight_tile_ready_o         (child_weight_ready_w),
                .weight_tile_blocks_i        (weight_tile_bank_q),
                .weight_tile_mask_i          (portal_req_mask_q),
                .result_valid_o               (child_result_valid_w),
                .result_ready_i               (child_result_ready_w),
                .result_bits_o                (child_result_bits_w),
                .result_mask_o                (child_result_mask_w),
                .result_row_base_o            (child_result_row_base_w),
                .done_o                       (child_done_w),
                .error_o                      (child_error_w),
                .error_code_o                 (child_error_code_w),
                .error_row_index_o            (child_error_row_w),
                .active_cycles_o              (child_active_cycles_w),
                .activation_words_accepted_o  (child_activation_words_w),
                .weight_blocks_accepted_o     (child_weight_blocks_w),
                .rows_emitted_o               (child_rows_emitted_w)
            );
        end else begin : gen_row_simd_core
            assign child_weight_valid_w = portal_payload_qualifies_w;
            TensorNpuQ8RowSimdCore #(
                .ROW_LANES (ROW_LANES),
                .MAC_LANES (MAC_LANES),
                .MAX_BLOCKS(MAX_BLOCKS)
            ) u_row_simd_core (
                .clk_i                       (clk_i),
                .rst_i                       (child_rst_w),
                .start_i                     (child_start_w),
                .ready_o                     (child_ready_w),
                .busy_o                      (child_busy_w),
                .row_count_i                 (row_count_q),
                .block_count_i               (block_count_q),
                .activation_valid_i          (child_activation_valid_w),
                .activation_ready_o          (child_activation_ready_w),
                .activation_bits_i           (activation_word_q),
                .weight_group_valid_i        (child_weight_valid_w),
                .weight_group_ready_o        (child_weight_ready_w),
                .weight_group_blocks_i       (portal_rsp_blocks_i),
                .weight_group_mask_i         (portal_req_mask_q),
                .result_batch_valid_o        (child_result_valid_w),
                .result_batch_ready_i        (child_result_ready_w),
                .result_batch_bits_o         (child_result_bits_w),
                .result_batch_mask_o         (child_result_mask_w),
                .result_row_base_o           (child_result_row_base_w),
                .done_o                      (child_done_w),
                .error_o                     (child_error_w),
                .error_code_o                (child_error_code_w),
                .error_row_index_o           (child_error_row_w),
                .active_cycles_o             (child_active_cycles_w),
                .activation_words_accepted_o (child_activation_words_w),
                .weight_blocks_accepted_o    (child_weight_blocks_w),
                .rows_emitted_o              (child_rows_emitted_w)
            );
        end
    endgenerate

    // ------------------------------------------------------------------
    // Raw GMEM and portal handshakes.
    // ------------------------------------------------------------------
    wire write_request_state_w = (state_q == ST_WRITE_REQ);
    assign gmem_req_valid_o = !rst_i && !outstanding_q
                            && !command_timeout_hit_w
                            && (((state_q == ST_ACT_REQ)
                                 && activation_runtime_ok_w)
                                || (write_request_state_w
                                    && held_batch_match_w
                                    && result_runtime_ok_w));
    assign gmem_req_write_o = write_request_state_w;
    assign gmem_req_addr_o = (state_q == ST_ACT_REQ)
                           ? activation_aligned_addr_w[63:0]
                           : held_write_addr_q;
    assign gmem_req_wdata_o = write_request_state_w
                            ? held_write_data_q : 64'b0;
    assign gmem_req_wstrb_o = write_request_state_w
                            ? held_write_strb_q : 8'b0;
    wire gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;

    assign gmem_rsp_ready_o = !rst_i && outstanding_q
                            && ((state_q == ST_ACT_WAIT)
                                || (state_q == ST_WRITE_WAIT)
                                || (state_q == ST_DRAIN));
    wire gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;

    assign portal_req_valid_o = !rst_i && (state_q == ST_PORTAL_REQ)
                              && !portal_outstanding_q
                              && !command_timeout_hit_w;
    assign portal_req_mask_o = portal_req_mask_q;
    assign portal_req_addr_o = portal_req_addr_q;
    wire portal_req_fire_w = portal_req_valid_o && portal_req_ready_i;

    // A malformed/error response is always accepted for drain but is never
    // exposed as valid to the child.  Legacy Row-SIMD backpressures until the
    // accumulators accept this block group; tile mode accepts into its
    // RTL-owned bank and presents the whole tile to the child later.
    wire portal_response_sink_ready_w =
        (TILE_FUNCTIONAL_ENABLE != 0) ? 1'b1 : child_weight_ready_w;
    assign portal_rsp_ready_o = !rst_i && portal_outstanding_q
                              && ((state_q == ST_DRAIN)
                                  || ((state_q == ST_PORTAL_WAIT)
                                      && (command_timeout_hit_w
                                          || portal_rsp_error_i
                                          || !portal_mask_match_w
                                          || portal_response_sink_ready_w)));
    wire portal_rsp_fire_w = portal_rsp_valid_i && portal_rsp_ready_o;
    wire portal_payload_accept_w = portal_rsp_fire_w
                                 && portal_payload_qualifies_w
                                 && portal_response_sink_ready_w;

    assign child_result_ready_w = (state_q == ST_WRITE_WAIT)
                                && gmem_rsp_fire_w
                                && !gmem_rsp_error_i
                                && held_batch_match_w
                                && last_write_lane_w
                                && !command_timeout_hit_w;

    reg progress_event_r;
    always @(*) begin
        progress_event_r = 1'b0;
        case (state_q)
            ST_PREFLIGHT:   progress_event_r = 1'b1;
            ST_CHILD_START: progress_event_r = child_start_w && child_ready_w;
            ST_ACT_LOOKUP:  progress_event_r = 1'b1;
            ST_ACT_REQ:     progress_event_r = gmem_req_fire_w;
            ST_ACT_WAIT:    progress_event_r = gmem_rsp_fire_w;
            ST_ACT_SEND:    progress_event_r = child_activation_fire_w;
            ST_PORTAL_PREP: progress_event_r = 1'b1;
            ST_PORTAL_REQ:  progress_event_r = portal_req_fire_w;
            ST_PORTAL_WAIT: progress_event_r = portal_rsp_fire_w;
            ST_TILE_SEND:   progress_event_r = child_weight_fire_w;
            ST_RESULT_WAIT: progress_event_r = child_result_valid_w
                                             || child_done_w
                                             || child_error_w;
            ST_WRITE_PREP:  progress_event_r = 1'b1;
            ST_WRITE_REQ:   progress_event_r = gmem_req_fire_w;
            ST_WRITE_WAIT:  progress_event_r = gmem_rsp_fire_w;
            ST_FINAL_WAIT:  progress_event_r = child_done_w || child_error_w;
            default:        progress_event_r = 1'b0;
        endcase
    end
    wire stall_timeout_hit_w = !progress_event_r
                              && (stall_cycles_q >= STALL_TIMEOUT_LAST);

    wire [63:0] expected_activation_words_w =
        {32'b0, block_count_q} << 5;
    wire [63:0] expected_weight_blocks_w =
        {32'b0, row_count_q} * {32'b0, block_count_q};
    wire [63:0] expected_activation_bytes_w =
        expected_activation_words_w << 2;
    wire [63:0] expected_weight_bytes_w =
        expected_weight_blocks_w * 64'd34;
    wire [63:0] expected_output_bytes_w = {32'b0, row_count_q} << 2;
    wire [63:0] expected_tile_count_w =
        ({32'b0, row_count_q} + {32'b0, ROW_LANES_U32} - 64'd1)
        / {32'b0, ROW_LANES_U32};
    wire [63:0] expected_portal_groups_w =
        expected_tile_count_w * {32'b0, block_count_q};

    wire exact_success_counts_w =
           ({32'b0, activation_words_accepted_q}
            == expected_activation_words_w)
        && (weight_blocks_accepted_q == expected_weight_blocks_w)
        && (rows_written_q == row_count_q)
        && (activation_payload_bytes_q == expected_activation_bytes_w)
        && (weight_payload_bytes_q == expected_weight_bytes_w)
        && (gmem_read_beats_q == gmem_read_beats_completed_q)
        && (gmem_write_beats_q == row_count_q)
        && (writes_completed_q == row_count_q)
        && (write_bytes_q == expected_output_bytes_w)
        && (portal_request_groups_q == expected_portal_groups_w)
        && (portal_response_groups_q == expected_portal_groups_w)
        && (portal_blocks_q == expected_weight_blocks_w)
        && (portal_bytes_q == expected_weight_bytes_w)
        && ({32'b0, child_activation_words_w}
            == expected_activation_words_w)
        && (child_weight_blocks_w == expected_weight_blocks_w)
        && (child_rows_emitted_w == row_count_q)
        && !outstanding_q
        && !portal_outstanding_q;

    // ------------------------------------------------------------------
    // Transaction controller.
    // ------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            command_id_q <= 64'b0;
            dst_shadow_private_q <= 1'b0;
            windows_generation_valid_q <= 1'b0;
            activation_base_q <= 64'b0;
            weight_base_q <= 64'b0;
            dst_base_q <= 64'b0;
            row_count_q <= 32'b0;
            block_count_q <= 32'b0;
            weight_row_stride_q <= 64'b0;
            dst_row_stride_q <= 64'b0;
            activation_window_base_q <= 64'b0;
            activation_window_bytes_q <= 64'b0;
            activation_window_read_q <= 1'b0;
            activation_window_write_q <= 1'b0;
            weight_window_base_q <= 64'b0;
            weight_window_bytes_q <= 64'b0;
            weight_window_read_q <= 1'b0;
            weight_window_write_q <= 1'b0;
            dst_window_base_q <= 64'b0;
            dst_window_bytes_q <= 64'b0;
            dst_window_read_q <= 1'b0;
            dst_window_write_q <= 1'b0;
            activation_semantic_end_q <= 64'b0;
            weight_semantic_end_q <= 64'b0;
            dst_semantic_end_q <= 64'b0;
            activation_word_index_q <= 32'b0;
            cache_valid_q <= 1'b0;
            cache_addr_q <= 64'b0;
            cache_data_q <= 64'b0;
            activation_word_q <= 32'b0;
            portal_row_base_q <= 32'b0;
            portal_block_index_q <= 32'b0;
            portal_req_mask_q <= {ROW_LANES{1'b0}};
            portal_req_addr_q <= {(ROW_LANES*64){1'b0}};
            portal_outstanding_q <= 1'b0;
            held_result_bits_q <= {(ROW_LANES*32){1'b0}};
            held_result_mask_q <= {ROW_LANES{1'b0}};
            held_result_row_base_q <= 32'b0;
            write_lane_q <= 32'b0;
            held_write_addr_q <= 64'b0;
            held_write_data_q <= 64'b0;
            held_write_strb_q <= 8'b0;
            outstanding_q <= 1'b0;
            outstanding_write_q <= 1'b0;
            outstanding_addr_q <= 64'b0;
            child_reset_q <= 1'b0;
            drain_error_code_q <= ERR_NONE;
            error_code_q <= ERR_NONE;
            child_error_code_q <= 8'b0;
            stall_cycles_q <= 32'b0;
            command_cycles_q <= 64'b0;
            active_cycles_q <= 64'b0;
            activation_words_accepted_q <= 32'b0;
            weight_blocks_accepted_q <= 64'b0;
            rows_written_q <= 32'b0;
            gmem_read_beats_q <= 64'b0;
            gmem_read_beats_completed_q <= 64'b0;
            gmem_read_bytes_q <= 64'b0;
            activation_payload_bytes_q <= 64'b0;
            weight_payload_bytes_q <= 64'b0;
            gmem_write_beats_q <= 32'b0;
            writes_completed_q <= 32'b0;
            write_bytes_q <= 64'b0;
            child_active_cycles_snapshot_q <= 64'b0;
            portal_request_groups_q <= 64'b0;
            portal_response_groups_q <= 64'b0;
            portal_blocks_q <= 64'b0;
            portal_bytes_q <= 64'b0;
        end else begin
            child_reset_q <= 1'b0;

            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)) begin
                if (active_cycles_q != 64'hffff_ffff_ffff_ffff)
                    active_cycles_q <= active_cycles_q + 64'd1;
                if (state_q != ST_DRAIN) begin
                    if (command_cycles_q != 64'hffff_ffff_ffff_ffff)
                        command_cycles_q <= command_cycles_q + 64'd1;
                    if (progress_event_r)
                        stall_cycles_q <= 32'b0;
                    else if (stall_cycles_q != 32'hffff_ffff)
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                end
                child_active_cycles_snapshot_q <= child_active_cycles_w;
            end

            if (gmem_req_fire_w) begin
                outstanding_q <= 1'b1;
                outstanding_write_q <= gmem_req_write_o;
                outstanding_addr_q <= gmem_req_addr_o;
                if (gmem_req_write_o)
                    gmem_write_beats_q <= gmem_write_beats_q + 32'd1;
                else
                    gmem_read_beats_q <= gmem_read_beats_q + 64'd1;
            end
            if (gmem_rsp_fire_w) begin
                outstanding_q <= 1'b0;
                if (!gmem_rsp_error_i) begin
                    if (outstanding_write_q) begin
                        writes_completed_q <= writes_completed_q + 32'd1;
                        write_bytes_q <= write_bytes_q + 64'd4;
                    end else begin
                        gmem_read_beats_completed_q
                            <= gmem_read_beats_completed_q + 64'd1;
                        gmem_read_bytes_q <= gmem_read_bytes_q + 64'd8;
                    end
                end
            end

            if (portal_req_fire_w) begin
                portal_outstanding_q <= 1'b1;
                portal_request_groups_q <= portal_request_groups_q + 64'd1;
            end
            if (portal_rsp_fire_w) begin
                portal_outstanding_q <= 1'b0;
                portal_response_groups_q <= portal_response_groups_q + 64'd1;
                if (portal_payload_accept_w) begin
                    portal_blocks_q <= portal_blocks_q
                                     + {32'b0,
                                        popcount_lanes(portal_req_mask_q)};
                    portal_bytes_q <= portal_bytes_q
                                    + ({32'b0,
                                       popcount_lanes(portal_req_mask_q)}
                                       * 64'd34);
                end
            end
            if ((TILE_FUNCTIONAL_ENABLE != 0)
                && portal_payload_accept_w) begin
                for (tile_store_lane = 0;
                     tile_store_lane < ROW_LANES;
                     tile_store_lane = tile_store_lane + 1) begin
                    if (portal_req_mask_q[tile_store_lane]) begin
                        weight_tile_bank_q[
                            ((tile_store_lane * MAX_BLOCKS
                              + portal_block_index_q) * 272) +: 272]
                            <= portal_rsp_blocks_i[
                                (tile_store_lane * 272) +: 272];
                    end
                end
            end

            case (state_q)
                ST_IDLE: begin
                    stall_cycles_q <= 32'b0;
                    command_cycles_q <= 64'b0;
                    if (start_fire_w) begin
                        command_id_q <= command_id_i;
                        dst_shadow_private_q <= dst_shadow_private_i;
                        windows_generation_valid_q
                            <= windows_generation_valid_i;
                        activation_base_q <= activation_base_i;
                        weight_base_q <= weight_base_i;
                        dst_base_q <= dst_base_i;
                        row_count_q <= row_count_i;
                        block_count_q <= block_count_i;
                        weight_row_stride_q <= weight_row_stride_i;
                        dst_row_stride_q <= dst_row_stride_i;
                        activation_window_base_q <= activation_window_base_i;
                        activation_window_bytes_q <= activation_window_bytes_i;
                        activation_window_read_q <= activation_window_read_i;
                        activation_window_write_q <= activation_window_write_i;
                        weight_window_base_q <= weight_window_base_i;
                        weight_window_bytes_q <= weight_window_bytes_i;
                        weight_window_read_q <= weight_window_read_i;
                        weight_window_write_q <= weight_window_write_i;
                        dst_window_base_q <= dst_window_base_i;
                        dst_window_bytes_q <= dst_window_bytes_i;
                        dst_window_read_q <= dst_window_read_i;
                        dst_window_write_q <= dst_window_write_i;
                        activation_semantic_end_q <= 64'b0;
                        weight_semantic_end_q <= 64'b0;
                        dst_semantic_end_q <= 64'b0;
                        activation_word_index_q <= 32'b0;
                        cache_valid_q <= 1'b0;
                        cache_addr_q <= 64'b0;
                        cache_data_q <= 64'b0;
                        activation_word_q <= 32'b0;
                        portal_row_base_q <= 32'b0;
                        portal_block_index_q <= 32'b0;
                        portal_req_mask_q <= {ROW_LANES{1'b0}};
                        portal_req_addr_q <= {(ROW_LANES*64){1'b0}};
                        portal_outstanding_q <= 1'b0;
                        held_result_bits_q <= {(ROW_LANES*32){1'b0}};
                        held_result_mask_q <= {ROW_LANES{1'b0}};
                        held_result_row_base_q <= 32'b0;
                        write_lane_q <= 32'b0;
                        held_write_addr_q <= 64'b0;
                        held_write_data_q <= 64'b0;
                        held_write_strb_q <= 8'b0;
                        outstanding_q <= 1'b0;
                        outstanding_write_q <= 1'b0;
                        outstanding_addr_q <= 64'b0;
                        drain_error_code_q <= ERR_NONE;
                        error_code_q <= ERR_NONE;
                        child_error_code_q <= 8'b0;
                        stall_cycles_q <= 32'b0;
                        command_cycles_q <= 64'b0;
                        active_cycles_q <= 64'b0;
                        activation_words_accepted_q <= 32'b0;
                        weight_blocks_accepted_q <= 64'b0;
                        rows_written_q <= 32'b0;
                        gmem_read_beats_q <= 64'b0;
                        gmem_read_beats_completed_q <= 64'b0;
                        gmem_read_bytes_q <= 64'b0;
                        activation_payload_bytes_q <= 64'b0;
                        weight_payload_bytes_q <= 64'b0;
                        gmem_write_beats_q <= 32'b0;
                        writes_completed_q <= 32'b0;
                        write_bytes_q <= 64'b0;
                        child_active_cycles_snapshot_q <= 64'b0;
                        portal_request_groups_q <= 64'b0;
                        portal_response_groups_q <= 64'b0;
                        portal_blocks_q <= 64'b0;
                        portal_bytes_q <= 64'b0;
                        state_q <= ST_PREFLIGHT;
                    end
                end

                ST_DONE: state_q <= ST_IDLE;
                ST_ERROR: state_q <= ST_IDLE;

                ST_DRAIN: begin
                    stall_cycles_q <= 32'b0;
                    if ((!outstanding_q && !portal_outstanding_q)
                        || (gmem_rsp_fire_w && !portal_outstanding_q)
                        || (portal_rsp_fire_w && !outstanding_q)) begin
                        if (gmem_rsp_fire_w && gmem_rsp_error_i)
                            error_code_q <= ERR_GMEM_RESPONSE;
                        else if (portal_rsp_fire_w && portal_rsp_error_i)
                            error_code_q <= ERR_PORTAL_RESPONSE;
                        else
                            error_code_q <= drain_error_code_q;
                        state_q <= ST_ERROR;
                    end
                end

                default: begin
                    if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        error_code_q <= ERR_GMEM_RESPONSE;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_GMEM_RESPONSE;
                        state_q <= portal_outstanding_q ? ST_DRAIN : ST_ERROR;
                    end else if (portal_rsp_fire_w && portal_rsp_error_i) begin
                        error_code_q <= ERR_PORTAL_RESPONSE;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_PORTAL_RESPONSE;
                        state_q <= outstanding_q ? ST_DRAIN : ST_ERROR;
                    end else if (portal_rsp_fire_w && !portal_mask_match_w) begin
                        error_code_q <= ERR_PORTAL_MASK;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_PORTAL_MASK;
                        state_q <= outstanding_q ? ST_DRAIN : ST_ERROR;
                    end else if (child_error_w) begin
                        child_error_code_q <= child_error_code_w;
                        error_code_q <= ERR_CHILD;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_CHILD;
                        state_q <= (outstanding_q || portal_outstanding_q)
                                 ? ST_DRAIN : ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                        state_q <= (outstanding_q || portal_outstanding_q)
                                 ? ST_DRAIN : ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q <= ERR_STALL_TIMEOUT;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_STALL_TIMEOUT;
                        state_q <= (outstanding_q || portal_outstanding_q)
                                 ? ST_DRAIN : ST_ERROR;
                    end else if (child_done_w && (state_q != ST_FINAL_WAIT)) begin
                        error_code_q <= ERR_CHILD_PROTOCOL;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_CHILD_PROTOCOL;
                        state_q <= (outstanding_q || portal_outstanding_q)
                                 ? ST_DRAIN : ST_ERROR;
                    end else if (child_result_valid_w
                                 && (state_q != ST_RESULT_WAIT)
                                 && (state_q != ST_WRITE_PREP)
                                 && (state_q != ST_WRITE_REQ)
                                 && (state_q != ST_WRITE_WAIT)) begin
                        error_code_q <= ERR_CHILD_PROTOCOL;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_CHILD_PROTOCOL;
                        state_q <= (outstanding_q || portal_outstanding_q)
                                 ? ST_DRAIN : ST_ERROR;
                    end else if (((state_q == ST_WRITE_PREP)
                                  || (state_q == ST_WRITE_REQ)
                                  || (state_q == ST_WRITE_WAIT))
                                 && !held_batch_match_w) begin
                        error_code_q <= ERR_CHILD_PROTOCOL;
                        child_reset_q <= 1'b1;
                        drain_error_code_q <= ERR_CHILD_PROTOCOL;
                        state_q <= outstanding_q ? ST_DRAIN : ST_ERROR;
                    end else begin
                        case (state_q)
                            ST_PREFLIGHT: begin
                                if (!descriptor_ok_w) begin
                                    error_code_q <= ERR_DESCRIPTOR;
                                    state_q <= ST_ERROR;
                                end else if (!activation_window_ok_w) begin
                                    error_code_q <= ERR_ACTIVATION_WIN;
                                    state_q <= ST_ERROR;
                                end else if (!weight_window_ok_w) begin
                                    error_code_q <= ERR_WEIGHT_WIN;
                                    state_q <= ST_ERROR;
                                end else if (!dst_window_ok_w) begin
                                    error_code_q <= ERR_DEST_WIN;
                                    state_q <= ST_ERROR;
                                end else if (!alias_ok_w) begin
                                    error_code_q <= ERR_ALIAS;
                                    state_q <= ST_ERROR;
                                end else if (COMMAND_TIMEOUT_CYCLES <= 64'd1) begin
                                    error_code_q <= ERR_COMMAND_TIMEOUT;
                                    state_q <= ST_ERROR;
                                end else begin
                                    activation_semantic_end_q
                                        <= activation_end_w[63:0];
                                    weight_semantic_end_q <= weight_end_w[63:0];
                                    dst_semantic_end_q <= dst_end_w[63:0];
                                    state_q <= ST_CHILD_START;
                                end
                            end

                            ST_CHILD_START: begin
                                if (child_start_w && child_ready_w)
                                    state_q <= ST_ACT_LOOKUP;
                            end

                            ST_ACT_LOOKUP: begin
                                if (!activation_runtime_ok_w) begin
                                    error_code_q <= ERR_INTERNAL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else if (cache_valid_q
                                             && (cache_addr_q
                                                 == activation_aligned_addr_w[63:0])) begin
                                    activation_word_q <= activation_word_addr_w[2]
                                                       ? cache_data_q[63:32]
                                                       : cache_data_q[31:0];
                                    state_q <= ST_ACT_SEND;
                                end else begin
                                    state_q <= ST_ACT_REQ;
                                end
                            end

                            ST_ACT_REQ: begin
                                if (!activation_runtime_ok_w) begin
                                    error_code_q <= ERR_INTERNAL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else if (gmem_req_fire_w) begin
                                    state_q <= ST_ACT_WAIT;
                                end
                            end

                            ST_ACT_WAIT: begin
                                if (gmem_rsp_fire_w) begin
                                    cache_valid_q <= 1'b1;
                                    cache_addr_q <= outstanding_addr_q;
                                    cache_data_q <= gmem_rsp_rdata_i;
                                    activation_word_q <= activation_word_addr_w[2]
                                                       ? gmem_rsp_rdata_i[63:32]
                                                       : gmem_rsp_rdata_i[31:0];
                                    state_q <= ST_ACT_SEND;
                                end
                            end

                            ST_ACT_SEND: begin
                                if (child_activation_fire_w) begin
                                    activation_words_accepted_q
                                        <= activation_words_accepted_q + 32'd1;
                                    activation_payload_bytes_q
                                        <= activation_payload_bytes_q + 64'd4;
                                    if ({32'b0, activation_word_index_q}
                                        == (expected_activation_words_w
                                            - 64'd1)) begin
                                        cache_valid_q <= 1'b0;
                                        portal_row_base_q <= 32'b0;
                                        portal_block_index_q <= 32'b0;
                                        state_q <= ST_PORTAL_PREP;
                                    end else begin
                                        activation_word_index_q
                                            <= activation_word_index_q + 32'd1;
                                        state_q <= ST_ACT_LOOKUP;
                                    end
                                end
                            end

                            ST_PORTAL_PREP: begin
                                if (!portal_candidate_ok_r) begin
                                    error_code_q <= ERR_INTERNAL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else begin
                                    portal_req_mask_q
                                        <= portal_candidate_mask_r;
                                    portal_req_addr_q
                                        <= portal_candidate_addr_r;
                                    state_q <= ST_PORTAL_REQ;
                                end
                            end

                            ST_PORTAL_REQ: begin
                                if (portal_req_fire_w)
                                    state_q <= ST_PORTAL_WAIT;
                            end

                            ST_PORTAL_WAIT: begin
                                if (portal_payload_accept_w) begin
                                    weight_blocks_accepted_q
                                        <= weight_blocks_accepted_q
                                         + {32'b0,
                                            popcount_lanes(portal_req_mask_q)};
                                    weight_payload_bytes_q
                                        <= weight_payload_bytes_q
                                         + ({32'b0,
                                             popcount_lanes(portal_req_mask_q)}
                                            * 64'd34);
                                    if (portal_block_index_q
                                        == (block_count_q - 32'd1)) begin
                                        state_q <=
                                            (TILE_FUNCTIONAL_ENABLE != 0)
                                            ? ST_TILE_SEND
                                            : ST_RESULT_WAIT;
                                    end else begin
                                        portal_block_index_q
                                            <= portal_block_index_q + 32'd1;
                                        state_q <= ST_PORTAL_PREP;
                                    end
                                end
                            end

                            ST_TILE_SEND: begin
                                if (child_weight_fire_w)
                                    state_q <= ST_RESULT_WAIT;
                            end

                            ST_RESULT_WAIT: begin
                                if (child_result_valid_w) begin
                                    if ((child_result_row_base_w
                                         != portal_row_base_q)
                                        || (child_result_mask_w
                                            != portal_req_mask_q)) begin
                                        error_code_q <= ERR_CHILD_PROTOCOL;
                                        child_reset_q <= 1'b1;
                                        state_q <= ST_ERROR;
                                    end else begin
                                        held_result_bits_q
                                            <= child_result_bits_w;
                                        held_result_mask_q
                                            <= child_result_mask_w;
                                        held_result_row_base_q
                                            <= child_result_row_base_w;
                                        write_lane_q <= 32'b0;
                                        state_q <= ST_WRITE_PREP;
                                    end
                                end
                            end

                            ST_WRITE_PREP: begin
                                if (!result_runtime_ok_w) begin
                                    error_code_q <= ERR_INTERNAL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else begin
                                    held_write_addr_q
                                        <= result_aligned_addr_w[63:0];
                                    if (result_addr_w[2]) begin
                                        held_write_data_q
                                            <= {held_result_bits_q[
                                                (write_lane_q*32) +: 32],
                                                32'b0};
                                        held_write_strb_q <= 8'hf0;
                                    end else begin
                                        held_write_data_q
                                            <= {32'b0, held_result_bits_q[
                                                (write_lane_q*32) +: 32]};
                                        held_write_strb_q <= 8'h0f;
                                    end
                                    state_q <= ST_WRITE_REQ;
                                end
                            end

                            ST_WRITE_REQ: begin
                                if (!result_runtime_ok_w) begin
                                    error_code_q <= ERR_INTERNAL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else if (gmem_req_fire_w) begin
                                    rows_written_q <= rows_written_q + 32'd1;
                                    state_q <= ST_WRITE_WAIT;
                                end
                            end

                            ST_WRITE_WAIT: begin
                                if (gmem_rsp_fire_w) begin
                                    if (last_write_lane_w) begin
                                        if (!child_result_ready_w) begin
                                            error_code_q
                                                <= ERR_CHILD_PROTOCOL;
                                            child_reset_q <= 1'b1;
                                            state_q <= ST_ERROR;
                                        end else if ((portal_row_base_q
                                                      + ROW_LANES_U32)
                                                     >= row_count_q) begin
                                            state_q <= ST_FINAL_WAIT;
                                        end else begin
                                            portal_row_base_q
                                                <= portal_row_base_q
                                                 + ROW_LANES_U32;
                                            portal_block_index_q <= 32'b0;
                                            state_q <= ST_PORTAL_PREP;
                                        end
                                    end else begin
                                        write_lane_q <= write_lane_q + 32'd1;
                                        state_q <= ST_WRITE_PREP;
                                    end
                                end
                            end

                            ST_FINAL_WAIT: begin
                                if (child_done_w) begin
                                    if (exact_success_counts_w) begin
                                        error_code_q <= ERR_NONE;
                                        state_q <= ST_DONE;
                                    end else begin
                                        error_code_q <= ERR_CHILD_PROTOCOL;
                                        child_reset_q <= 1'b1;
                                        state_q <= ST_ERROR;
                                    end
                                end
                            end

                            default: begin
                                error_code_q <= ERR_INTERNAL;
                                child_reset_q <= 1'b1;
                                drain_error_code_q <= ERR_INTERNAL;
                                state_q <= (outstanding_q
                                            || portal_outstanding_q)
                                         ? ST_DRAIN : ST_ERROR;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

    // Intentional integration probes retained for lint-visible hierarchy.
    wire unused_child_busy_w = child_busy_w;
    wire [31:0] unused_child_error_row_w = child_error_row_w;

endmodule

`default_nettype wire
