`timescale 1ns/1ps
`default_nettype none

// TensorNpuQ8GetRowsEngine
//
// Phase-B Q8_0 GET_ROWS gather engine for one fixed (h1,h2) slice.  The
// command first proves every index beat and every selected source-row beat is
// addressable, then gathers/dequantizes into a private parent buffer.  The
// committed output stream is enabled only after every child block transaction
// has completed, so every precommit failure is externally atomic.
//
// Protocol and topology:
//   * one held, aligned 64-bit GMEM read request and one matching response;
//   * one shared TensorNpuQ8DequantBlock child with real ready/valid/done;
//   * byte-address-qualified 8B->I32 and 8B->34B merge networks;
//   * MAX_IDS resident ids/row bases and MAX_IDS*MAX_D private FP32 lanes;
//   * reset > corrupt state > domain fatal > command timeout > stall timeout.
//
// The widest combinational path is the 128-bit row multiply/add/bounds
// preflight.  The private output-buffer read mux is the other wide path.  No
// function hides state, arbitration, handshake, reset, or shared-resource
// ownership.
module TensorNpuQ8GetRowsEngine #(
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
    input  wire [63:0]                        src_slice_base_i,
    input  wire [63:0]                        idx_slice_base_i,
    input  wire [63:0]                        gmem_floor_i,
    input  wire [63:0]                        gmem_limit_i,
    input  wire [31:0]                        source_row_count_i,
    input  wire [$clog2(MAX_IDS+1)-1:0]       index_count_i,
    input  wire [$clog2(MAX_D+1)-1:0]         element_count_i,
    input  wire [63:0]                        src_row_stride_i,
    input  wire [63:0]                        idx_stride_i,

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

    output wire                               out_valid_o,
    input  wire                               out_ready_i,
    output wire [31:0]                        out_bits_o,
    output wire [$clog2(MAX_IDS+1)-1:0]       out_id_position_o,
    output wire [31:0]                        out_source_id_o,
    output wire [$clog2(MAX_D+1)-1:0]         out_lane_index_o,
    output wire                               out_row_last_o,
    output wire                               out_last_o,

    output wire                               done_o,
    output wire                               error_o,
    output wire [4:0]                         error_code_o,
    output wire [31:0]                        ids_scanned_o,
    output wire [31:0]                        blocks_done_o,
    output wire [31:0]                        outputs_emitted_o,
    output wire [31:0]                        gmem_beats_o,
    output wire [31:0]                        payload_bytes_o,
    output wire [31:0]                        active_cycles_o
);

    localparam integer ID_COUNT_W     = $clog2(MAX_IDS + 1);
    localparam integer ID_INDEX_W     = $clog2(MAX_IDS);
    localparam integer D_COUNT_W      = $clog2(MAX_D + 1);
    localparam integer BLOCK_COUNT_W  = $clog2((MAX_D / 32) + 1);
    localparam integer OUTPUT_DEPTH   = MAX_IDS * MAX_D;
    localparam integer OUTPUT_INDEX_W = $clog2(OUTPUT_DEPTH);

    localparam [31:0] OUTPUT_DEPTH_U32 = OUTPUT_DEPTH;
    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 1) ? 32'd0
                                    : (STALL_TIMEOUT_CYCLES - 1);
    localparam [31:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 1) ? 32'd0
                                      : (COMMAND_TIMEOUT_CYCLES - 1);

    localparam [5:0] ST_IDLE              = 6'd0;
    localparam [5:0] ST_HEADER_CHECK      = 6'd1;
    localparam [5:0] ST_INDEX_PREFLIGHT   = 6'd2;
    localparam [5:0] ST_ID_PREP           = 6'd3;
    localparam [5:0] ST_ID_REQ            = 6'd4;
    localparam [5:0] ST_ID_WAIT           = 6'd5;
    localparam [5:0] ST_ID_CAPTURE        = 6'd6;
    localparam [5:0] ST_ROW_PREFLIGHT     = 6'd7;
    localparam [5:0] ST_BLOCK_PREP        = 6'd8;
    localparam [5:0] ST_BLOCK_REQ         = 6'd9;
    localparam [5:0] ST_BLOCK_WAIT        = 6'd10;
    localparam [5:0] ST_DEQUANT_START     = 6'd11;
    localparam [5:0] ST_DEQUANT_RUN       = 6'd12;
    localparam [5:0] ST_DEQUANT_DONE_WAIT = 6'd13;
    localparam [5:0] ST_COMMIT            = 6'd14;
    localparam [5:0] ST_OUTPUT_STREAM     = 6'd15;
    localparam [5:0] ST_DONE              = 6'd16;
    localparam [5:0] ST_ERROR             = 6'd17;
    localparam [5:0] ST_GMEM_DRAIN        = 6'd18;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_HEADER          = 5'd1;
    localparam [4:0] ERR_INDEX_ADDRESS   = 5'd2;
    localparam [4:0] ERR_ID_RANGE        = 5'd3;
    localparam [4:0] ERR_ROW_ADDRESS     = 5'd4;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd5;
    localparam [4:0] ERR_CHILD           = 5'd6;
    localparam [4:0] ERR_CHILD_PROTOCOL  = 5'd7;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd8;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd9;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd10;

    reg [5:0] state_q;

    // Resident command.  Busy start_i never writes these registers.
    reg [63:0] src_slice_base_q;
    reg [63:0] idx_slice_base_q;
    reg [63:0] gmem_floor_q;
    reg [63:0] gmem_limit_q;
    reg [31:0] source_row_count_q;
    reg [ID_COUNT_W-1:0] index_count_q;
    reg [D_COUNT_W-1:0] element_count_q;
    reg [63:0] src_row_stride_q;
    reg [63:0] idx_stride_q;
    reg [BLOCK_COUNT_W-1:0] block_count_q;
    reg [31:0] packed_row_bytes_q;
    reg [31:0] total_outputs_q;
    reg [31:0] total_blocks_q;

    // MAX_IDS-entry preflight residency.  These arrays need no reset because
    // state/cursors make old entries ineligible until rewritten this command.
    reg [31:0] id_buffer_q [0:MAX_IDS-1];
    reg [63:0] row_base_buffer_q [0:MAX_IDS-1];

    reg [ID_COUNT_W-1:0] index_preflight_pos_q;
    reg [ID_COUNT_W-1:0] id_position_q;
    reg [ID_COUNT_W-1:0] row_preflight_pos_q;
    reg [ID_COUNT_W-1:0] gather_id_position_q;
    reg [BLOCK_COUNT_W-1:0] block_index_q;

    // The request address is written only before entering a REQ state or
    // after its matching response, so valid&&!ready holds every payload bit.
    reg [63:0] gmem_req_addr_q;
    reg [63:0] id_target_addr_q;
    reg [63:0] id_last_aligned_q;
    reg [31:0] id_word_q;
    reg [63:0] block_target_addr_q;
    reg [63:0] block_last_aligned_q;
    reg [271:0] block_buffer_q;

    // Private command-atomic result store.  Data bits deliberately have no
    // reset; only a completed COMMIT makes the current prefix observable.
    reg [31:0] output_buffer_q [0:OUTPUT_DEPTH-1];
    reg [31:0] store_flat_q;
    reg [OUTPUT_INDEX_W-1:0] output_flat_q;
    reg [ID_COUNT_W-1:0] output_id_position_q;
    reg [D_COUNT_W-1:0] output_lane_index_q;
    reg [6:0] child_lane_count_q;

    reg [31:0] stall_cycles_q;
    reg [31:0] command_cycles_q;
    reg [31:0] active_cycles_q;
    reg [4:0] error_code_q;
    reg [31:0] ids_scanned_q;
    reg [31:0] blocks_done_q;
    reg [31:0] outputs_emitted_q;
    reg [31:0] gmem_beats_q;
    reg [31:0] payload_bytes_q;
    reg child_reset_q;
    reg [4:0] drain_error_code_q;

    wire start_fire_w;
    wire out_fire_w;
    wire request_state_w;
    wire response_state_w;
    wire gmem_req_fire_w;
    wire gmem_rsp_fire_w;
    wire command_timeout_hit_w;
    wire stall_timeout_hit_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE);
    assign busy_o  = !rst_i && (state_q != ST_IDLE);
    assign done_o  = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign start_fire_w = start_i && ready_o;

    assign request_state_w = (state_q == ST_ID_REQ)
                           || (state_q == ST_BLOCK_REQ);
    assign response_state_w = (state_q == ST_ID_WAIT)
                            || (state_q == ST_BLOCK_WAIT)
                            || (state_q == ST_GMEM_DRAIN);
    // A watchdog terminal outranks a same-cycle late ready.  Gating valid here
    // prevents a request from becoming externally accepted after its command
    // has already lost completion eligibility.
    assign gmem_req_valid_o = !rst_i && request_state_w
                            && !command_timeout_hit_w
                            && !stall_timeout_hit_w;
    assign gmem_req_write_o = 1'b0;
    assign gmem_req_addr_o  = gmem_req_addr_q;
    assign gmem_req_wdata_o = 64'b0;
    assign gmem_req_wstrb_o = 8'b0;
    assign gmem_rsp_ready_o = !rst_i && response_state_w;
    assign gmem_req_fire_w  = gmem_req_valid_o && gmem_req_ready_i;
    assign gmem_rsp_fire_w  = gmem_rsp_valid_i && gmem_rsp_ready_o;

    assign out_valid_o       = !rst_i && (state_q == ST_OUTPUT_STREAM);
    assign out_bits_o        = out_valid_o
                             ? output_buffer_q[output_flat_q] : 32'b0;
    assign out_id_position_o = out_valid_o ? output_id_position_q
                                           : {ID_COUNT_W{1'b0}};
    assign out_source_id_o   = out_valid_o
                             ? id_buffer_q[
                                   output_id_position_q[ID_INDEX_W-1:0]
                               ] : 32'b0;
    assign out_lane_index_o  = out_valid_o ? output_lane_index_q
                                           : {D_COUNT_W{1'b0}};
    assign out_row_last_o    = out_valid_o
                             && (output_lane_index_q
                                 == (element_count_q - 1'b1));
    assign out_last_o        = out_row_last_o
                             && (output_id_position_q
                                 == (index_count_q - 1'b1));
    assign out_fire_w        = out_valid_o && out_ready_i;

    assign error_code_o      = error_code_q;
    assign ids_scanned_o     = ids_scanned_q;
    assign blocks_done_o     = blocks_done_q;
    assign outputs_emitted_o = outputs_emitted_q;
    assign gmem_beats_o      = gmem_beats_q;
    assign payload_bytes_o   = payload_bytes_q;
    assign active_cycles_o   = active_cycles_q;
    assign command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);
    assign stall_timeout_hit_w =
        (stall_cycles_q >= STALL_TIMEOUT_LAST);

    // Header-wide arithmetic.  128 bits preserve the full 32x64 row-product
    // requirement with carry room for base/end additions before truncation.
    reg [127:0] header_n_minus_one_w;
    reg [127:0] header_index_product_w;
    reg [127:0] header_index_last_w;
    reg [127:0] header_index_end_w;
    reg [127:0] header_packed_bytes_w;
    reg [127:0] header_output_count_w;
    reg [127:0] header_block_count_w;
    reg          header_valid_w;

    always @(*) begin
        header_n_minus_one_w  = 128'b0;
        header_index_product_w = 128'b0;
        header_index_last_w   = 128'b0;
        header_index_end_w    = 128'b0;
        header_packed_bytes_w = 128'b0;
        header_output_count_w = 128'b0;
        header_block_count_w  = 128'b0;
        header_valid_w        = 1'b0;

        header_n_minus_one_w = {
            {(128-ID_COUNT_W){1'b0}}, index_count_q
        };
        header_n_minus_one_w = header_n_minus_one_w - 128'd1;
        header_index_product_w = header_n_minus_one_w
                               * {64'b0, idx_stride_q};
        header_index_last_w = {64'b0, idx_slice_base_q}
                            + header_index_product_w;
        header_index_end_w = header_index_last_w + 128'd4;
        header_block_count_w = {
            {(128-D_COUNT_W){1'b0}}, element_count_q
        };
        header_block_count_w = header_block_count_w >> 5;
        header_packed_bytes_w = header_block_count_w * 128'd34;
        header_output_count_w = element_count_q * index_count_q;

        if ((source_row_count_q != 32'b0)
                && (index_count_q >= 1)
                && (index_count_q <= ID_COUNT_W'(MAX_IDS))
                && (element_count_q >= 32)
                && (element_count_q <= D_COUNT_W'(MAX_D))
                && (element_count_q[4:0] == 5'b0)
                && (header_packed_bytes_w[127:64] == 64'b0)
                && ({64'b0, src_row_stride_q} >= header_packed_bytes_w)
                && (idx_stride_q >= 64'd4)
                && (gmem_floor_q < gmem_limit_q)
                && (header_index_last_w[127:64] == 64'b0)
                && (header_index_end_w[127:64] == 64'b0)
                && (idx_slice_base_q >= gmem_floor_q)
                && (header_index_end_w[63:0] <= gmem_limit_q)
                && (header_output_count_w
                    <= {96'b0, OUTPUT_DEPTH_U32})) begin
            header_valid_w = 1'b1;
        end
    end

    // Before the first GMEM request, every index semantic and aligned physical
    // window is checked in the expanded domain.
    reg [127:0] index_position_wide_w;
    reg [127:0] index_stride_product_w;
    reg [127:0] index_addr_wide_w;
    reg [127:0] index_end_wide_w;
    reg [127:0] index_first_aligned_wide_w;
    reg [127:0] index_last_byte_wide_w;
    reg [127:0] index_last_aligned_end_wide_w;
    reg         index_preflight_valid_w;

    always @(*) begin
        index_position_wide_w         = {
            {(128-ID_COUNT_W){1'b0}}, index_preflight_pos_q
        };
        index_stride_product_w        = index_position_wide_w
                                      * {64'b0, idx_stride_q};
        index_addr_wide_w             = {64'b0, idx_slice_base_q}
                                      + index_stride_product_w;
        index_end_wide_w              = index_addr_wide_w + 128'd4;
        index_first_aligned_wide_w    = index_addr_wide_w;
        index_first_aligned_wide_w[2:0] = 3'b000;
        index_last_byte_wide_w        = index_end_wide_w - 128'd1;
        index_last_aligned_end_wide_w = index_last_byte_wide_w;
        index_last_aligned_end_wide_w[2:0] = 3'b000;
        index_last_aligned_end_wide_w = index_last_aligned_end_wide_w
                                      + 128'd8;
        index_preflight_valid_w       = 1'b0;

        if ((index_addr_wide_w[127:64] == 64'b0)
                && (index_end_wide_w[127:64] == 64'b0)
                && (index_first_aligned_wide_w[127:64] == 64'b0)
                && (index_last_aligned_end_wide_w[127:64] == 64'b0)
                && (index_addr_wide_w[63:0] >= gmem_floor_q)
                && (index_end_wide_w[63:0] <= gmem_limit_q)
                && (index_first_aligned_wide_w[63:0] >= gmem_floor_q)
                && (index_last_aligned_end_wide_w[63:0]
                    <= gmem_limit_q)) begin
            index_preflight_valid_w = 1'b1;
        end
    end

    // Current index address is recomputed from the proven resident command.
    reg [127:0] id_position_wide_w;
    reg [127:0] id_addr_wide_w;
    reg [127:0] id_last_byte_wide_w;
    reg [127:0] id_last_aligned_wide_w;

    always @(*) begin
        id_position_wide_w = {
            {(128-ID_COUNT_W){1'b0}}, id_position_q
        };
        id_addr_wide_w = {64'b0, idx_slice_base_q}
                       + (id_position_wide_w * {64'b0, idx_stride_q});
        id_last_byte_wide_w = id_addr_wide_w + 128'd3;
        id_last_aligned_wide_w = id_last_byte_wide_w;
        id_last_aligned_wide_w[2:0] = 3'b000;
    end

    // Full id*stride product and all row/last-beat additions remain expanded.
    reg [127:0] row_id_wide_w;
    reg [127:0] row_product_wide_w;
    reg [127:0] row_base_wide_w;
    reg [127:0] row_end_wide_w;
    reg [127:0] row_first_aligned_wide_w;
    reg [127:0] row_last_byte_wide_w;
    reg [127:0] row_last_aligned_end_wide_w;
    reg         row_preflight_valid_w;

    always @(*) begin
        row_id_wide_w = {
            96'b0,
            id_buffer_q[row_preflight_pos_q[ID_INDEX_W-1:0]]
        };
        row_product_wide_w = row_id_wide_w * {64'b0, src_row_stride_q};
        row_base_wide_w = {64'b0, src_slice_base_q} + row_product_wide_w;
        row_end_wide_w = row_base_wide_w
                       + {96'b0, packed_row_bytes_q};
        row_first_aligned_wide_w = row_base_wide_w;
        row_first_aligned_wide_w[2:0] = 3'b000;
        row_last_byte_wide_w = row_end_wide_w - 128'd1;
        row_last_aligned_end_wide_w = row_last_byte_wide_w;
        row_last_aligned_end_wide_w[2:0] = 3'b000;
        row_last_aligned_end_wide_w = row_last_aligned_end_wide_w
                                    + 128'd8;
        row_preflight_valid_w = 1'b0;

        if ((row_base_wide_w[127:64] == 64'b0)
                && (row_end_wide_w[127:64] == 64'b0)
                && (row_first_aligned_wide_w[127:64] == 64'b0)
                && (row_last_aligned_end_wide_w[127:64] == 64'b0)
                && (row_base_wide_w[63:0] >= gmem_floor_q)
                && (row_end_wide_w[63:0] <= gmem_limit_q)
                && (row_first_aligned_wide_w[63:0] >= gmem_floor_q)
                && (row_last_aligned_end_wide_w[63:0] <= gmem_limit_q)) begin
            row_preflight_valid_w = 1'b1;
        end
    end

    // Block-local bounds are re-proved even though the whole row passed.  This
    // keeps block offset and aligned last-beat truncation independently guarded.
    reg [127:0] block_index_wide_w;
    reg [127:0] block_offset_wide_w;
    reg [127:0] block_addr_wide_w;
    reg [127:0] block_end_wide_w;
    reg [127:0] block_first_aligned_wide_w;
    reg [127:0] block_last_byte_wide_w;
    reg [127:0] block_last_aligned_wide_w;
    reg [127:0] block_last_aligned_end_wide_w;
    reg         block_preflight_valid_w;

    always @(*) begin
        block_index_wide_w = {
            {(128-BLOCK_COUNT_W){1'b0}}, block_index_q
        };
        block_offset_wide_w = block_index_wide_w * 128'd34;
        block_addr_wide_w = {
            64'b0,
            row_base_buffer_q[gather_id_position_q[ID_INDEX_W-1:0]]
        } + block_offset_wide_w;
        block_end_wide_w = block_addr_wide_w + 128'd34;
        block_first_aligned_wide_w = block_addr_wide_w;
        block_first_aligned_wide_w[2:0] = 3'b000;
        block_last_byte_wide_w = block_end_wide_w - 128'd1;
        block_last_aligned_wide_w = block_last_byte_wide_w;
        block_last_aligned_wide_w[2:0] = 3'b000;
        block_last_aligned_end_wide_w = block_last_aligned_wide_w
                                      + 128'd8;
        block_preflight_valid_w = 1'b0;

        if ((block_addr_wide_w[127:64] == 64'b0)
                && (block_end_wide_w[127:64] == 64'b0)
                && (block_first_aligned_wide_w[127:64] == 64'b0)
                && (block_last_aligned_end_wide_w[127:64] == 64'b0)
                && (block_addr_wide_w[63:0] >= gmem_floor_q)
                && (block_end_wide_w[63:0] <= gmem_limit_q)
                && (block_first_aligned_wide_w[63:0] >= gmem_floor_q)
                && (block_last_aligned_end_wide_w[63:0]
                    <= gmem_limit_q)) begin
            block_preflight_valid_w = 1'b1;
        end
    end

    // Byte mask/merge for a possibly unaligned little-endian I32.  The loop
    // elaborates to eight parallel address compares and four byte write muxes.
    reg [31:0] id_word_merge_w;
    reg [3:0] id_payload_bytes_w;
    reg [64:0] id_merge_abs_addr_w;
    reg [63:0] id_merge_offset_w;
    integer id_merge_lane;

    always @(*) begin
        id_word_merge_w = id_word_q;
        id_payload_bytes_w = 4'b0;
        id_merge_abs_addr_w = 65'b0;
        id_merge_offset_w = 64'b0;
        for (id_merge_lane = 0; id_merge_lane < 8;
                id_merge_lane = id_merge_lane + 1) begin
            id_merge_abs_addr_w = {1'b0, gmem_req_addr_q}
                                + {33'b0, id_merge_lane};
            if ((id_merge_abs_addr_w >= {1'b0, id_target_addr_q})
                    && (id_merge_abs_addr_w
                        < ({1'b0, id_target_addr_q} + 65'd4))) begin
                id_merge_offset_w = id_merge_abs_addr_w[63:0]
                                  - id_target_addr_q;
                id_word_merge_w[
                    {id_merge_offset_w[1:0], 3'b000} +: 8
                ] = gmem_rsp_rdata_i[{id_merge_lane[2:0], 3'b000} +: 8];
                id_payload_bytes_w = id_payload_bytes_w + 4'd1;
            end
        end
    end

    // Byte mask/merge for one 34-byte Q8_0 block.  Alignment bytes and row
    // padding are physically readable but cannot select any block-buffer bit.
    reg [271:0] block_buffer_merge_w;
    reg [3:0] block_payload_bytes_w;
    reg [64:0] block_merge_abs_addr_w;
    reg [63:0] block_merge_offset_w;
    integer block_merge_lane;

    always @(*) begin
        block_buffer_merge_w = block_buffer_q;
        block_payload_bytes_w = 4'b0;
        block_merge_abs_addr_w = 65'b0;
        block_merge_offset_w = 64'b0;
        for (block_merge_lane = 0; block_merge_lane < 8;
                block_merge_lane = block_merge_lane + 1) begin
            block_merge_abs_addr_w = {1'b0, gmem_req_addr_q}
                                   + {33'b0, block_merge_lane};
            if ((block_merge_abs_addr_w >= {1'b0, block_target_addr_q})
                    && (block_merge_abs_addr_w
                        < ({1'b0, block_target_addr_q} + 65'd34))) begin
                block_merge_offset_w = block_merge_abs_addr_w[63:0]
                                     - block_target_addr_q;
                block_buffer_merge_w[
                    {block_merge_offset_w[5:0], 3'b000} +: 8
                ] = gmem_rsp_rdata_i[
                    {block_merge_lane[2:0], 3'b000} +: 8
                ];
                block_payload_bytes_w = block_payload_bytes_w + 4'd1;
            end
        end
    end

    wire child_start_w;
    wire child_ready_w;
    wire child_busy_w;
    wire child_lane_valid_w;
    wire child_lane_ready_w;
    wire [5:0] child_lane_index_w;
    wire [31:0] child_lane_bits_w;
    wire child_lane_last_w;
    wire child_done_w;
    wire child_error_w;
    wire [3:0] child_error_code_w;
    wire [15:0] child_active_cycles_w;
    wire child_rst_w;

    assign child_start_w      = (state_q == ST_DEQUANT_START)
                              && !command_timeout_hit_w
                              && !stall_timeout_hit_w;
    assign child_lane_ready_w = (state_q == ST_DEQUANT_RUN)
                              && !command_timeout_hit_w
                              && !stall_timeout_hit_w;
    assign child_rst_w        = rst_i || child_reset_q
                              || (state_q == ST_ERROR);

    TensorNpuQ8DequantBlock u_dequant (
        .clk_i           (clk_i),
        .rst_i           (child_rst_w),
        .start_i         (child_start_w),
        .ready_o         (child_ready_w),
        .busy_o          (child_busy_w),
        .block_i         (block_buffer_q),
        .lane_valid_o    (child_lane_valid_w),
        .lane_ready_i    (child_lane_ready_w),
        .lane_index_o    (child_lane_index_w),
        .lane_bits_o     (child_lane_bits_w),
        .lane_last_o     (child_lane_last_w),
        .done_o          (child_done_w),
        .error_o         (child_error_w),
        .error_code_o    (child_error_code_w),
        .active_cycles_o (child_active_cycles_w)
    );

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                  <= ST_IDLE;
            src_slice_base_q         <= 64'b0;
            idx_slice_base_q         <= 64'b0;
            gmem_floor_q             <= 64'b0;
            gmem_limit_q             <= 64'b0;
            source_row_count_q       <= 32'b0;
            index_count_q            <= {ID_COUNT_W{1'b0}};
            element_count_q          <= {D_COUNT_W{1'b0}};
            src_row_stride_q         <= 64'b0;
            idx_stride_q             <= 64'b0;
            block_count_q            <= {BLOCK_COUNT_W{1'b0}};
            packed_row_bytes_q       <= 32'b0;
            total_outputs_q          <= 32'b0;
            total_blocks_q           <= 32'b0;
            index_preflight_pos_q    <= {ID_COUNT_W{1'b0}};
            id_position_q            <= {ID_COUNT_W{1'b0}};
            row_preflight_pos_q      <= {ID_COUNT_W{1'b0}};
            gather_id_position_q     <= {ID_COUNT_W{1'b0}};
            block_index_q            <= {BLOCK_COUNT_W{1'b0}};
            gmem_req_addr_q          <= 64'b0;
            id_target_addr_q         <= 64'b0;
            id_last_aligned_q        <= 64'b0;
            id_word_q                <= 32'b0;
            block_target_addr_q      <= 64'b0;
            block_last_aligned_q     <= 64'b0;
            block_buffer_q           <= 272'b0;
            store_flat_q             <= 32'b0;
            output_flat_q            <= {OUTPUT_INDEX_W{1'b0}};
            output_id_position_q     <= {ID_COUNT_W{1'b0}};
            output_lane_index_q      <= {D_COUNT_W{1'b0}};
            child_lane_count_q       <= 7'b0;
            stall_cycles_q           <= 32'b0;
            command_cycles_q         <= 32'b0;
            active_cycles_q          <= 32'b0;
            error_code_q             <= ERR_NONE;
            ids_scanned_q            <= 32'b0;
            blocks_done_q            <= 32'b0;
            outputs_emitted_q        <= 32'b0;
            gmem_beats_q             <= 32'b0;
            payload_bytes_q          <= 32'b0;
            child_reset_q            <= 1'b0;
            drain_error_code_q        <= ERR_NONE;
        end else begin
            child_reset_q <= 1'b0;

            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)
                    && (state_q != ST_GMEM_DRAIN)
                    && (active_cycles_q != 32'hffffffff)) begin
                active_cycles_q <= active_cycles_q + 32'd1;
            end
            if ((state_q >= ST_HEADER_CHECK)
                    && (state_q <= ST_COMMIT)
                    && (command_cycles_q != 32'hffffffff)) begin
                command_cycles_q <= command_cycles_q + 32'd1;
            end
            if (gmem_req_fire_w) begin
                gmem_beats_q <= gmem_beats_q + 32'd1;
            end

            case (state_q)
                ST_IDLE: begin
                    stall_cycles_q   <= 32'b0;
                    command_cycles_q <= 32'b0;
                    if (start_fire_w) begin
                        src_slice_base_q     <= src_slice_base_i;
                        idx_slice_base_q     <= idx_slice_base_i;
                        gmem_floor_q         <= gmem_floor_i;
                        gmem_limit_q         <= gmem_limit_i;
                        source_row_count_q   <= source_row_count_i;
                        index_count_q        <= index_count_i;
                        element_count_q      <= element_count_i;
                        src_row_stride_q     <= src_row_stride_i;
                        idx_stride_q         <= idx_stride_i;
                        block_count_q        <= {BLOCK_COUNT_W{1'b0}};
                        packed_row_bytes_q   <= 32'b0;
                        total_outputs_q      <= 32'b0;
                        total_blocks_q       <= 32'b0;
                        index_preflight_pos_q <= {ID_COUNT_W{1'b0}};
                        id_position_q        <= {ID_COUNT_W{1'b0}};
                        row_preflight_pos_q  <= {ID_COUNT_W{1'b0}};
                        gather_id_position_q <= {ID_COUNT_W{1'b0}};
                        block_index_q        <= {BLOCK_COUNT_W{1'b0}};
                        store_flat_q         <= 32'b0;
                        output_flat_q        <= {OUTPUT_INDEX_W{1'b0}};
                        output_id_position_q <= {ID_COUNT_W{1'b0}};
                        output_lane_index_q  <= {D_COUNT_W{1'b0}};
                        child_lane_count_q   <= 7'b0;
                        stall_cycles_q       <= 32'b0;
                        command_cycles_q     <= 32'd1;
                        active_cycles_q      <= 32'd1;
                        error_code_q         <= ERR_NONE;
                        ids_scanned_q        <= 32'b0;
                        blocks_done_q        <= 32'b0;
                        outputs_emitted_q    <= 32'b0;
                        gmem_beats_q         <= 32'b0;
                        payload_bytes_q      <= 32'b0;
                        drain_error_code_q   <= ERR_NONE;
                        state_q              <= ST_HEADER_CHECK;
                    end
                end

                ST_HEADER_CHECK: begin
                    stall_cycles_q <= 32'b0;
                    if (!header_valid_w) begin
                        error_code_q          <= ERR_HEADER;
                        outputs_emitted_q     <= 32'b0;
                        child_reset_q         <= 1'b1;
                        state_q               <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q          <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q     <= 32'b0;
                        child_reset_q         <= 1'b1;
                        state_q               <= ST_ERROR;
                    end else begin
                        block_count_q          <= header_block_count_w[
                            BLOCK_COUNT_W-1:0
                        ];
                        packed_row_bytes_q     <= header_packed_bytes_w[31:0];
                        total_outputs_q        <= header_output_count_w[31:0];
                        total_blocks_q          <= header_block_count_w[31:0]
                                                 * index_count_q;
                        index_preflight_pos_q  <= {ID_COUNT_W{1'b0}};
                        state_q                 <= ST_INDEX_PREFLIGHT;
                    end
                end

                ST_INDEX_PREFLIGHT: begin
                    stall_cycles_q <= 32'b0;
                    if (!index_preflight_valid_w) begin
                        error_code_q      <= ERR_INDEX_ADDRESS;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (index_preflight_pos_q
                            == (index_count_q - 1'b1)) begin
                        id_position_q <= {ID_COUNT_W{1'b0}};
                        state_q       <= ST_ID_PREP;
                    end else begin
                        index_preflight_pos_q <= index_preflight_pos_q + 1'b1;
                    end
                end

                ST_ID_PREP: begin
                    stall_cycles_q    <= 32'b0;
                    id_target_addr_q  <= id_addr_wide_w[63:0];
                    id_last_aligned_q <= id_last_aligned_wide_w[63:0];
                    gmem_req_addr_q   <= {id_addr_wide_w[63:3], 3'b000};
                    id_word_q         <= 32'b0;
                    if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else begin
                        state_q <= ST_ID_REQ;
                    end
                end

                ST_ID_REQ: begin
                    if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q      <= ERR_STALL_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (gmem_req_fire_w) begin
                        stall_cycles_q <= 32'b0;
                        state_q        <= ST_ID_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_ID_WAIT: begin
                    if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        error_code_q      <= ERR_GMEM_RESPONSE;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            error_code_q      <= ERR_COMMAND_TIMEOUT;
                            outputs_emitted_q <= 32'b0;
                            child_reset_q     <= 1'b1;
                            state_q           <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q             <= ST_GMEM_DRAIN;
                        end
                    end else if (stall_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            error_code_q      <= ERR_STALL_TIMEOUT;
                            outputs_emitted_q <= 32'b0;
                            child_reset_q     <= 1'b1;
                            state_q           <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_STALL_TIMEOUT;
                            state_q             <= ST_GMEM_DRAIN;
                        end
                    end else if (gmem_rsp_fire_w) begin
                        id_word_q       <= id_word_merge_w;
                        payload_bytes_q <= payload_bytes_q
                                         + {28'b0, id_payload_bytes_w};
                        stall_cycles_q  <= 32'b0;
                        if (gmem_req_addr_q == id_last_aligned_q) begin
                            state_q <= ST_ID_CAPTURE;
                        end else begin
                            gmem_req_addr_q <= gmem_req_addr_q + 64'd8;
                            state_q         <= ST_ID_REQ;
                        end
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_ID_CAPTURE: begin
                    stall_cycles_q <= 32'b0;
                    ids_scanned_q  <= ids_scanned_q + 32'd1;
                    if (id_word_q[31]
                            || (id_word_q >= source_row_count_q)) begin
                        error_code_q      <= ERR_ID_RANGE;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else begin
                        id_buffer_q[id_position_q[ID_INDEX_W-1:0]]
                            <= id_word_q;
                        if (id_position_q == (index_count_q - 1'b1)) begin
                            row_preflight_pos_q <= {ID_COUNT_W{1'b0}};
                            state_q             <= ST_ROW_PREFLIGHT;
                        end else begin
                            id_position_q <= id_position_q + 1'b1;
                            state_q       <= ST_ID_PREP;
                        end
                    end
                end

                ST_ROW_PREFLIGHT: begin
                    stall_cycles_q <= 32'b0;
                    if (!row_preflight_valid_w) begin
                        error_code_q      <= ERR_ROW_ADDRESS;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else begin
                        row_base_buffer_q[
                            row_preflight_pos_q[ID_INDEX_W-1:0]
                        ] <= row_base_wide_w[63:0];
                        if (row_preflight_pos_q
                                == (index_count_q - 1'b1)) begin
                            gather_id_position_q <= {ID_COUNT_W{1'b0}};
                            block_index_q        <= {BLOCK_COUNT_W{1'b0}};
                            store_flat_q         <= 32'b0;
                            state_q              <= ST_BLOCK_PREP;
                        end else begin
                            row_preflight_pos_q <= row_preflight_pos_q + 1'b1;
                        end
                    end
                end

                ST_BLOCK_PREP: begin
                    stall_cycles_q <= 32'b0;
                    if (!block_preflight_valid_w) begin
                        error_code_q      <= ERR_ROW_ADDRESS;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else begin
                        block_target_addr_q  <= block_addr_wide_w[63:0];
                        block_last_aligned_q <= block_last_aligned_wide_w[63:0];
                        gmem_req_addr_q      <= block_first_aligned_wide_w[63:0];
                        block_buffer_q       <= 272'b0;
                        state_q              <= ST_BLOCK_REQ;
                    end
                end

                ST_BLOCK_REQ: begin
                    if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q      <= ERR_STALL_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (gmem_req_fire_w) begin
                        stall_cycles_q <= 32'b0;
                        state_q        <= ST_BLOCK_WAIT;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_BLOCK_WAIT: begin
                    if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        error_code_q      <= ERR_GMEM_RESPONSE;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            error_code_q      <= ERR_COMMAND_TIMEOUT;
                            outputs_emitted_q <= 32'b0;
                            child_reset_q     <= 1'b1;
                            state_q           <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                            state_q             <= ST_GMEM_DRAIN;
                        end
                    end else if (stall_timeout_hit_w) begin
                        if (gmem_rsp_fire_w) begin
                            error_code_q      <= ERR_STALL_TIMEOUT;
                            outputs_emitted_q <= 32'b0;
                            child_reset_q     <= 1'b1;
                            state_q           <= ST_ERROR;
                        end else begin
                            drain_error_code_q <= ERR_STALL_TIMEOUT;
                            state_q             <= ST_GMEM_DRAIN;
                        end
                    end else if (gmem_rsp_fire_w) begin
                        block_buffer_q  <= block_buffer_merge_w;
                        payload_bytes_q <= payload_bytes_q
                                         + {28'b0, block_payload_bytes_w};
                        stall_cycles_q  <= 32'b0;
                        if (gmem_req_addr_q == block_last_aligned_q) begin
                            state_q <= ST_DEQUANT_START;
                        end else begin
                            gmem_req_addr_q <= gmem_req_addr_q + 64'd8;
                            state_q         <= ST_BLOCK_REQ;
                        end
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_GMEM_DRAIN: begin
                    // The request was already accepted, so timeout cancels
                    // only semantic adoption.  Hold the sole response credit
                    // until the matching beat is consumed; never merge it.
                    if (gmem_rsp_fire_w) begin
                        error_code_q <= gmem_rsp_error_i
                                      ? ERR_GMEM_RESPONSE
                                      : drain_error_code_q;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end
                end

                ST_DEQUANT_START: begin
                    if (child_error_w || child_busy_w) begin
                        error_code_q      <= (child_error_w
                                             && (child_error_code_w != 4'b0))
                                            ? ERR_CHILD
                                            : ERR_CHILD_PROTOCOL;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q      <= ERR_STALL_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (child_ready_w) begin
                        child_lane_count_q <= 7'b0;
                        stall_cycles_q     <= 32'b0;
                        state_q            <= ST_DEQUANT_RUN;
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_DEQUANT_RUN: begin
                    if (child_error_w) begin
                        error_code_q      <= (child_error_code_w != 4'b0)
                                           ? ERR_CHILD : ERR_CHILD_PROTOCOL;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (child_done_w
                            || (child_lane_valid_w
                                && ((child_lane_count_q >= 7'd32)
                                    || (child_lane_index_w
                                        != child_lane_count_q[5:0])
                                    || (child_lane_last_w
                                        != (child_lane_count_q == 7'd31))
                                    || (store_flat_q >= total_outputs_q)
                                    || (store_flat_q >= OUTPUT_DEPTH_U32)))) begin
                        error_code_q      <= ERR_CHILD_PROTOCOL;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q      <= ERR_STALL_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (child_lane_valid_w) begin
                        output_buffer_q[store_flat_q[OUTPUT_INDEX_W-1:0]]
                            <= child_lane_bits_w;
                        store_flat_q       <= store_flat_q + 32'd1;
                        child_lane_count_q <= child_lane_count_q + 7'd1;
                        stall_cycles_q     <= 32'b0;
                        if (child_lane_last_w) begin
                            state_q <= ST_DEQUANT_DONE_WAIT;
                        end
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_DEQUANT_DONE_WAIT: begin
                    if (child_error_w) begin
                        error_code_q      <= (child_error_code_w != 4'b0)
                                           ? ERR_CHILD : ERR_CHILD_PROTOCOL;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (child_lane_valid_w) begin
                        error_code_q      <= ERR_CHILD_PROTOCOL;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (child_done_w
                            && ((child_lane_count_q != 7'd32)
                                || (child_active_cycles_w == 16'b0)
                                || (child_error_code_w != 4'b0))) begin
                        error_code_q      <= ERR_CHILD_PROTOCOL;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (stall_timeout_hit_w) begin
                        error_code_q      <= ERR_STALL_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (child_done_w) begin
                        blocks_done_q  <= blocks_done_q + 32'd1;
                        stall_cycles_q <= 32'b0;
                        if ((block_index_q + 1'b1) < block_count_q) begin
                            block_index_q <= block_index_q + 1'b1;
                            state_q       <= ST_BLOCK_PREP;
                        end else if ((gather_id_position_q + 1'b1)
                                < index_count_q) begin
                            gather_id_position_q <= gather_id_position_q + 1'b1;
                            block_index_q        <= {BLOCK_COUNT_W{1'b0}};
                            state_q              <= ST_BLOCK_PREP;
                        end else if (store_flat_q != total_outputs_q) begin
                            error_code_q      <= ERR_CHILD_PROTOCOL;
                            outputs_emitted_q <= 32'b0;
                            child_reset_q     <= 1'b1;
                            state_q           <= ST_ERROR;
                        end else begin
                            state_q <= ST_COMMIT;
                        end
                    end else begin
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                    end
                end

                ST_COMMIT: begin
                    stall_cycles_q <= 32'b0;
                    if ((store_flat_q != total_outputs_q)
                            || (blocks_done_q != total_blocks_q)) begin
                        error_code_q      <= ERR_CHILD_PROTOCOL;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else if (command_timeout_hit_w) begin
                        error_code_q      <= ERR_COMMAND_TIMEOUT;
                        outputs_emitted_q <= 32'b0;
                        child_reset_q     <= 1'b1;
                        state_q           <= ST_ERROR;
                    end else begin
                        output_flat_q        <= {OUTPUT_INDEX_W{1'b0}};
                        output_id_position_q <= {ID_COUNT_W{1'b0}};
                        output_lane_index_q  <= {D_COUNT_W{1'b0}};
                        state_q              <= ST_OUTPUT_STREAM;
                    end
                end

                ST_OUTPUT_STREAM: begin
                    stall_cycles_q <= 32'b0;
                    if (out_fire_w) begin
                        outputs_emitted_q <= outputs_emitted_q + 32'd1;
                        if (out_last_o) begin
                            state_q <= ST_DONE;
                        end else begin
                            output_flat_q <= output_flat_q + 1'b1;
                            if (out_row_last_o) begin
                                output_id_position_q <= output_id_position_q
                                                      + 1'b1;
                                output_lane_index_q <= {D_COUNT_W{1'b0}};
                            end else begin
                                output_lane_index_q <= output_lane_index_q
                                                     + 1'b1;
                            end
                        end
                    end
                end

                ST_DONE: begin
                    state_q <= ST_IDLE;
                end

                ST_ERROR: begin
                    outputs_emitted_q <= 32'b0;
                    state_q           <= ST_IDLE;
                end

                default: begin
                    // A corrupt FSM encoding can never emit a request/output;
                    // it is contained as the highest-priority domain failure.
                    error_code_q      <= ERR_INTERNAL_STATE;
                    outputs_emitted_q <= 32'b0;
                    child_reset_q     <= 1'b1;
                    state_q           <= ST_ERROR;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
