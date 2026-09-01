`timescale 1ns/1ps
`default_nettype none

// TensorNpuQ8GemvWritebackAdapter
//
// Transactional GMEM shell for GEMV_Q8_0_F32.  The wrapped
// TensorNpuQ8StreamGemv remains the only numeric implementation: activation
// F32 words are transported once into its RTL reference quantizer, Q8_0
// weight blocks are transported in row-major order, and its FP32 result stream
// is written only into a caller-provided private destination.
//
// A command becomes publication-visible only through dst_commit_o.  Any
// descriptor, transport, child, protocol, stall, or command-timeout failure
// suppresses that pulse.  An already accepted GMEM request is always drained
// before terminal completion, so the parent owner can switch safely.
//
// All complete descriptor spans and aligned eight-byte physical footprints are
// proved with 128-bit intermediates before the first child or GMEM handshake.
// The two source windows must be read-only, the destination window write-only,
// and the private destination physical footprint may not alias either source.
module TensorNpuQ8GemvWritebackAdapter #(
    parameter integer MAX_ROWS = 248320,
    parameter integer MAX_BLOCKS = 128,
    parameter integer MAC_LANES = 8,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd4096,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd1000000000
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [63:0]  command_id_i,
    input  wire         dst_shadow_private_i,
    input  wire         windows_generation_valid_i,

    input  wire [63:0]  activation_base_i,
    input  wire [63:0]  weight_base_i,
    input  wire [63:0]  dst_base_i,
    input  wire [31:0]  row_count_i,
    input  wire [31:0]  block_count_i,
    input  wire [63:0]  weight_row_stride_i,
    input  wire [63:0]  dst_row_stride_i,

    input  wire [63:0]  activation_window_base_i,
    input  wire [63:0]  activation_window_bytes_i,
    input  wire         activation_window_read_i,
    input  wire         activation_window_write_i,
    input  wire [63:0]  weight_window_base_i,
    input  wire [63:0]  weight_window_bytes_i,
    input  wire         weight_window_read_i,
    input  wire         weight_window_write_i,
    input  wire [63:0]  dst_window_base_i,
    input  wire [63:0]  dst_window_bytes_i,
    input  wire         dst_window_read_i,
    input  wire         dst_window_write_i,

    // One raw, eight-byte, single-outstanding GMEM channel.
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

    // completion_valid_o qualifies identity, terminal status, and counters.
    output wire         completion_valid_o,
    output wire         dst_commit_o,
    output wire [63:0]  completion_command_id_o,
    output wire [31:0]  completion_kernel_id_o,
    output wire [31:0]  completion_row_count_o,
    output wire [31:0]  completion_block_count_o,
    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,
    output wire [7:0]   child_error_code_o,

    output wire [31:0]  activation_words_accepted_o,
    output wire [63:0]  weight_blocks_accepted_o,
    output wire [31:0]  rows_written_o,
    output wire [63:0]  gmem_read_beats_o,
    output wire [63:0]  gmem_read_beats_completed_o,
    output wire [63:0]  gmem_read_bytes_o,
    output wire [63:0]  activation_payload_bytes_o,
    output wire [63:0]  weight_payload_bytes_o,
    output wire [31:0]  gmem_write_beats_o,
    output wire [31:0]  writes_completed_o,
    output wire [63:0]  write_bytes_o,
    output wire [63:0]  child_active_cycles_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o
);

    localparam [31:0] KERNEL_ID_GEMV_Q8_0_F32 = 32'h514e0002;
    localparam [31:0] MAX_ROWS_U32 = MAX_ROWS;
    localparam [31:0] MAX_BLOCKS_U32 = MAX_BLOCKS;

    localparam [4:0] ST_IDLE          = 5'd0;
    localparam [4:0] ST_PREFLIGHT     = 5'd1;
    localparam [4:0] ST_CHILD_START   = 5'd2;
    localparam [4:0] ST_ACT_LOOKUP    = 5'd3;
    localparam [4:0] ST_ACT_REQ       = 5'd4;
    localparam [4:0] ST_ACT_WAIT      = 5'd5;
    localparam [4:0] ST_ACT_SEND      = 5'd6;
    localparam [4:0] ST_WEIGHT_LOOKUP = 5'd7;
    localparam [4:0] ST_WEIGHT_REQ    = 5'd8;
    localparam [4:0] ST_WEIGHT_WAIT   = 5'd9;
    localparam [4:0] ST_WEIGHT_SEND   = 5'd10;
    localparam [4:0] ST_RESULT_WAIT   = 5'd11;
    localparam [4:0] ST_WRITE_REQ     = 5'd12;
    localparam [4:0] ST_WRITE_WAIT    = 5'd13;
    localparam [4:0] ST_FINAL_WAIT    = 5'd14;
    localparam [4:0] ST_GMEM_DRAIN    = 5'd15;
    localparam [4:0] ST_DONE          = 5'd16;
    localparam [4:0] ST_ERROR         = 5'd17;

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

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                        : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 64'd1) ? 64'd0
                                          : COMMAND_TIMEOUT_CYCLES - 64'd1;

    generate
        if ((MAX_ROWS < 1) || (MAX_BLOCKS < 1)) begin : gen_bad_limits
            initial $fatal(1, "Q8 GEMV adapter limits must be positive");
        end
        if (MAX_BLOCKS > 128) begin : gen_bad_core_limit
            initial $fatal(1, "Q8 GEMV adapter MAX_BLOCKS exceeds core bank");
        end
    endgenerate

    reg [4:0] state_q;

    // Resident command.  Busy starts cannot mutate it.
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

    // Transport/stream coordinates.
    reg [31:0] activation_word_index_q;
    reg [31:0] weight_row_index_q;
    reg [31:0] weight_block_index_q;
    reg [5:0]  weight_byte_index_q;
    reg [31:0] result_row_index_q;

    reg        cache_valid_q;
    reg [63:0] cache_addr_q;
    reg [63:0] cache_data_q;
    reg [31:0] activation_word_q;
    reg [271:0] weight_block_q;

    reg [31:0] held_result_bits_q;
    reg [31:0] held_result_row_q;
    reg [63:0] held_write_addr_q;
    reg [63:0] held_write_data_q;
    reg [7:0]  held_write_strb_q;

    reg        outstanding_q;
    reg        outstanding_write_q;
    reg [63:0] outstanding_addr_q;
    reg        child_reset_q;
    reg        child_done_seen_q;
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

    wire start_fire_w;
    wire command_timeout_hit_w;
    wire stall_timeout_hit_w;
    wire gmem_req_fire_w;
    wire gmem_rsp_fire_w;

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

    assign start_fire_w = start_i && ready_o;
    assign command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);

    // ------------------------------------------------------------------
    // Whole-command, 128-bit preflight.
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
        weight_blocks_w = {96'b0, row_count_q}
                        * {96'b0, block_count_q};
        weight_row_bytes_w = {96'b0, block_count_q} * 128'd34;
        output_bytes_w = {96'b0, row_count_q} * 128'd4;

        activation_window_end_w = {64'b0, activation_window_base_q}
                                + {64'b0, activation_window_bytes_q};
        weight_window_end_w = {64'b0, weight_window_base_q}
                            + {64'b0, weight_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};

        activation_end_w = {64'b0, activation_base_q}
                         + activation_bytes_w;
        weight_last_row_w = {64'b0, weight_base_q}
                          + (rows_minus_one_w
                             * {64'b0, weight_row_stride_q});
        weight_end_w = weight_last_row_w + weight_row_bytes_w;
        dst_last_row_w = {64'b0, dst_base_q}
                       + (rows_minus_one_w
                          * {64'b0, dst_row_stride_q});
        dst_end_w = dst_last_row_w + 128'd4;

        activation_phys_start_w = {64'b0, activation_base_q};
        activation_phys_start_w[2:0] = 3'b000;
        align_tmp_w = activation_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        activation_phys_end_w = align_tmp_w + 128'd8;

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
                       && ({64'b0, weight_row_stride_q}
                           >= weight_row_bytes_w)
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
                       && (output_bytes_w[127:64] == 64'b0)
                       && (weight_blocks_w >= 128'd1)
                       && (output_bytes_w >= 128'd4);

        activation_window_ok_w =
               (activation_window_end_w[127:64] == 64'b0)
            && (activation_end_w[127:64] == 64'b0)
            && (activation_phys_start_w[127:64] == 64'b0)
            && (activation_phys_end_w[127:64] == 64'b0)
            && (activation_phys_start_w
                >= {64'b0, activation_window_base_q})
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

        // Read/read overlap is legal; no physical destination beat may touch
        // either immutable source footprint.
        alias_ok_w = ((dst_phys_end_w <= activation_phys_start_w)
                      || (dst_phys_start_w >= activation_phys_end_w))
                  && ((dst_phys_end_w <= weight_phys_start_w)
                      || (dst_phys_start_w >= weight_phys_end_w));
    end

    // ------------------------------------------------------------------
    // Re-prove every runtime coordinate before issuing a physical request.
    // ------------------------------------------------------------------
    reg [127:0] activation_word_addr_w;
    reg [127:0] activation_aligned_addr_w;
    reg         activation_runtime_ok_w;
    reg [127:0] weight_block_base_w;
    reg [127:0] weight_byte_addr_w;
    reg [127:0] weight_aligned_addr_w;
    reg         weight_runtime_ok_w;
    reg [127:0] result_addr_w;
    reg [127:0] result_aligned_addr_w;
    reg         result_runtime_ok_w;

    always @(*) begin
        activation_word_addr_w = {64'b0, activation_base_q}
                               + ({96'b0, activation_word_index_q}
                                  * 128'd4);
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

        weight_block_base_w = {64'b0, weight_base_q}
                            + ({96'b0, weight_row_index_q}
                               * {64'b0, weight_row_stride_q})
                            + ({96'b0, weight_block_index_q}
                               * 128'd34);
        weight_byte_addr_w = weight_block_base_w
                           + {122'b0, weight_byte_index_q};
        weight_aligned_addr_w = weight_byte_addr_w;
        weight_aligned_addr_w[2:0] = 3'b000;
        weight_runtime_ok_w =
               (weight_byte_addr_w[127:64] == 64'b0)
            && (weight_aligned_addr_w[127:64] == 64'b0)
            && ((weight_byte_addr_w + 128'd1)
                <= {64'b0, weight_semantic_end_q})
            && (weight_aligned_addr_w >= {64'b0, weight_window_base_q})
            && ((weight_aligned_addr_w + 128'd8) <= weight_window_end_w);

        result_addr_w = {64'b0, dst_base_q}
                      + ({96'b0, result_row_index_q}
                         * {64'b0, dst_row_stride_q});
        result_aligned_addr_w = result_addr_w;
        result_aligned_addr_w[2:0] = 3'b000;
        result_runtime_ok_w =
               (result_addr_w[127:64] == 64'b0)
            && (result_aligned_addr_w[127:64] == 64'b0)
            && ((result_addr_w + 128'd4)
                <= {64'b0, dst_semantic_end_q})
            && (result_aligned_addr_w >= {64'b0, dst_window_base_q})
            && ((result_aligned_addr_w + 128'd8) <= dst_window_end_w);
    end

    // ------------------------------------------------------------------
    // Wrapped numeric core.
    // ------------------------------------------------------------------
    wire child_start_w;
    wire child_start_fire_w;
    wire child_ready_w;
    wire child_busy_w;
    wire child_activation_valid_w;
    wire child_activation_ready_w;
    wire child_activation_fire_w;
    wire child_weight_valid_w;
    wire child_weight_ready_w;
    wire child_weight_fire_w;
    wire child_result_valid_w;
    wire child_result_ready_w;
    wire child_result_fire_w;
    wire [31:0] child_result_bits_w;
    wire [31:0] child_result_row_w;
    wire child_done_w;
    wire child_error_w;
    wire [7:0] child_error_code_w;
    wire [63:0] child_active_cycles_w;
    wire [31:0] child_activation_words_w;
    wire [63:0] child_weight_blocks_w;
    wire [31:0] child_rows_emitted_w;
    wire child_rst_w;

    assign child_rst_w = rst_i || child_reset_q || (state_q == ST_ERROR);
    assign child_start_w = (state_q == ST_CHILD_START)
                         && !command_timeout_hit_w;
    assign child_start_fire_w = child_start_w && child_ready_w;
    assign child_activation_valid_w = (state_q == ST_ACT_SEND)
                                    && !command_timeout_hit_w;
    assign child_activation_fire_w = child_activation_valid_w
                                   && child_activation_ready_w;
    assign child_weight_valid_w = (state_q == ST_WEIGHT_SEND)
                                && !command_timeout_hit_w;
    assign child_weight_fire_w = child_weight_valid_w
                               && child_weight_ready_w;

    wire held_result_match_w;
    assign held_result_match_w = child_result_valid_w
                              && (child_result_bits_w == held_result_bits_q)
                              && (child_result_row_w == held_result_row_q);
    assign child_result_ready_w = (state_q == ST_WRITE_REQ)
                                && gmem_req_fire_w
                                && held_result_match_w;
    assign child_result_fire_w = child_result_valid_w
                               && child_result_ready_w;

    TensorNpuQ8StreamGemv #(
        .MAX_BLOCKS            (MAX_BLOCKS),
        .MAC_LANES             (MAC_LANES),
        .STALL_TIMEOUT_CYCLES  (STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES(COMMAND_TIMEOUT_CYCLES)
    ) u_gemv (
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
        .weight_valid_i              (child_weight_valid_w),
        .weight_ready_o              (child_weight_ready_w),
        .weight_block_i              (weight_block_q),
        .result_valid_o              (child_result_valid_w),
        .result_ready_i              (child_result_ready_w),
        .result_bits_o               (child_result_bits_w),
        .result_row_index_o          (child_result_row_w),
        .done_o                      (child_done_w),
        .error_o                     (child_error_w),
        .error_code_o                (child_error_code_w),
        .active_cycles_o             (child_active_cycles_w),
        .activation_words_accepted_o (child_activation_words_w),
        .weight_blocks_accepted_o    (child_weight_blocks_w),
        .rows_emitted_o              (child_rows_emitted_w)
    );

    // ------------------------------------------------------------------
    // Raw GMEM request/response ownership.
    // ------------------------------------------------------------------
    wire write_request_state_w;
    assign write_request_state_w = (state_q == ST_WRITE_REQ);

    assign gmem_req_valid_o = !rst_i && !outstanding_q
                            && !command_timeout_hit_w
                            && (((state_q == ST_ACT_REQ)
                                 && activation_runtime_ok_w)
                                || ((state_q == ST_WEIGHT_REQ)
                                    && weight_runtime_ok_w)
                                || (write_request_state_w
                                    && held_result_match_w));
    assign gmem_req_write_o = write_request_state_w;
    assign gmem_req_addr_o = (state_q == ST_ACT_REQ)
                           ? activation_aligned_addr_w[63:0]
                           : (state_q == ST_WEIGHT_REQ)
                           ? weight_aligned_addr_w[63:0]
                           : held_write_addr_q;
    assign gmem_req_wdata_o = write_request_state_w
                            ? held_write_data_q : 64'b0;
    assign gmem_req_wstrb_o = write_request_state_w
                            ? held_write_strb_q : 8'b0;
    assign gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;

    assign gmem_rsp_ready_o = !rst_i && outstanding_q
                            && ((state_q == ST_ACT_WAIT)
                                || (state_q == ST_WEIGHT_WAIT)
                                || (state_q == ST_WRITE_WAIT)
                                || (state_q == ST_GMEM_DRAIN));
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;

    // A lookup is an internal, one-cycle progress step.  Child compute waits
    // are bounded by the same watchdog as the wrapped core.
    reg progress_event_r;
    always @(*) begin
        progress_event_r = 1'b0;
        case (state_q)
            ST_PREFLIGHT:     progress_event_r = 1'b1;
            ST_CHILD_START:   progress_event_r = child_start_fire_w;
            ST_ACT_LOOKUP:    progress_event_r = 1'b1;
            ST_ACT_REQ:       progress_event_r = gmem_req_fire_w;
            ST_ACT_WAIT:      progress_event_r = gmem_rsp_fire_w;
            ST_ACT_SEND:      progress_event_r = child_activation_fire_w;
            ST_WEIGHT_LOOKUP: progress_event_r = 1'b1;
            ST_WEIGHT_REQ:    progress_event_r = gmem_req_fire_w;
            ST_WEIGHT_WAIT:   progress_event_r = gmem_rsp_fire_w;
            ST_WEIGHT_SEND:   progress_event_r = child_weight_fire_w;
            ST_RESULT_WAIT:   progress_event_r = child_result_valid_w
                                               || child_done_w
                                               || child_error_w;
            ST_WRITE_REQ:     progress_event_r = gmem_req_fire_w;
            ST_WRITE_WAIT:    progress_event_r = gmem_rsp_fire_w
                                               || child_done_w
                                               || child_error_w;
            ST_FINAL_WAIT:    progress_event_r = child_done_w
                                               || child_error_w;
            default:          progress_event_r = 1'b0;
        endcase
    end
    assign stall_timeout_hit_w = !progress_event_r
                               && (stall_cycles_q >= STALL_TIMEOUT_LAST);

    wire [63:0] expected_activation_words_w;
    wire [63:0] expected_weight_blocks_w;
    wire [63:0] expected_activation_bytes_w;
    wire [63:0] expected_weight_bytes_w;
    wire [63:0] expected_output_bytes_w;
    assign expected_activation_words_w = {32'b0, block_count_q} << 5;
    assign expected_weight_blocks_w = {32'b0, row_count_q}
                                    * {32'b0, block_count_q};
    assign expected_activation_bytes_w = expected_activation_words_w << 2;
    assign expected_weight_bytes_w = expected_weight_blocks_w * 64'd34;
    assign expected_output_bytes_w = {32'b0, row_count_q} << 2;

    wire exact_success_counts_w;
    assign exact_success_counts_w =
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
        && ({32'b0, child_activation_words_w}
            == expected_activation_words_w)
        && (child_weight_blocks_w == expected_weight_blocks_w)
        && (child_rows_emitted_w == row_count_q);

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
            weight_row_index_q <= 32'b0;
            weight_block_index_q <= 32'b0;
            weight_byte_index_q <= 6'b0;
            result_row_index_q <= 32'b0;
            cache_valid_q <= 1'b0;
            cache_addr_q <= 64'b0;
            cache_data_q <= 64'b0;
            activation_word_q <= 32'b0;
            weight_block_q <= 272'b0;
            held_result_bits_q <= 32'b0;
            held_result_row_q <= 32'b0;
            held_write_addr_q <= 64'b0;
            held_write_data_q <= 64'b0;
            held_write_strb_q <= 8'b0;
            outstanding_q <= 1'b0;
            outstanding_write_q <= 1'b0;
            outstanding_addr_q <= 64'b0;
            child_reset_q <= 1'b0;
            child_done_seen_q <= 1'b0;
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
        end else begin
            child_reset_q <= 1'b0;

            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)) begin
                if (active_cycles_q != 64'hffff_ffff_ffff_ffff)
                    active_cycles_q <= active_cycles_q + 64'd1;
                if (state_q != ST_GMEM_DRAIN) begin
                    if (command_cycles_q != 64'hffff_ffff_ffff_ffff)
                        command_cycles_q <= command_cycles_q + 64'd1;
                    if (progress_event_r)
                        stall_cycles_q <= 32'b0;
                    else if (stall_cycles_q != 32'hffff_ffff)
                        stall_cycles_q <= stall_cycles_q + 32'd1;
                end
                child_active_cycles_snapshot_q <= child_active_cycles_w;
            end

            if (child_done_w)
                child_done_seen_q <= 1'b1;

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
                        activation_window_base_q
                            <= activation_window_base_i;
                        activation_window_bytes_q
                            <= activation_window_bytes_i;
                        activation_window_read_q
                            <= activation_window_read_i;
                        activation_window_write_q
                            <= activation_window_write_i;
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
                        weight_row_index_q <= 32'b0;
                        weight_block_index_q <= 32'b0;
                        weight_byte_index_q <= 6'b0;
                        result_row_index_q <= 32'b0;
                        cache_valid_q <= 1'b0;
                        cache_addr_q <= 64'b0;
                        cache_data_q <= 64'b0;
                        activation_word_q <= 32'b0;
                        weight_block_q <= 272'b0;
                        held_result_bits_q <= 32'b0;
                        held_result_row_q <= 32'b0;
                        held_write_addr_q <= 64'b0;
                        held_write_data_q <= 64'b0;
                        held_write_strb_q <= 8'b0;
                        outstanding_q <= 1'b0;
                        outstanding_write_q <= 1'b0;
                        outstanding_addr_q <= 64'b0;
                        child_done_seen_q <= 1'b0;
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
                        state_q <= ST_PREFLIGHT;
                    end
                end

                ST_DONE: begin
                    state_q <= ST_IDLE;
                end

                ST_ERROR: begin
                    state_q <= ST_IDLE;
                end

                ST_GMEM_DRAIN: begin
                    stall_cycles_q <= 32'b0;
                    if (!outstanding_q) begin
                        error_code_q <= drain_error_code_q;
                        state_q <= ST_ERROR;
                    end else if (gmem_rsp_fire_w) begin
                        error_code_q <= gmem_rsp_error_i
                                      ? ERR_GMEM_RESPONSE
                                      : drain_error_code_q;
                        state_q <= ST_ERROR;
                    end
                end

                default: begin
                    // A fabric error has precedence because this response has
                    // closed the sole accepted external transaction.
                    if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                        error_code_q <= ERR_GMEM_RESPONSE;
                        child_reset_q <= 1'b1;
                        state_q <= ST_ERROR;
                    end else if (child_error_w) begin
                        child_error_code_q <= child_error_code_w;
                        drain_error_code_q <= ERR_CHILD;
                        child_reset_q <= 1'b1;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN : ST_ERROR;
                        error_code_q <= ERR_CHILD;
                    end else if (command_timeout_hit_w) begin
                        drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                        child_reset_q <= 1'b1;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN : ST_ERROR;
                        error_code_q <= ERR_COMMAND_TIMEOUT;
                    end else if (stall_timeout_hit_w) begin
                        drain_error_code_q <= ERR_STALL_TIMEOUT;
                        child_reset_q <= 1'b1;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN : ST_ERROR;
                        error_code_q <= ERR_STALL_TIMEOUT;
                    end else if (child_done_w
                                 && !(((state_q == ST_WRITE_WAIT)
                                       || (state_q == ST_FINAL_WAIT))
                                      && (rows_written_q == row_count_q))) begin
                        error_code_q <= ERR_CHILD_PROTOCOL;
                        child_reset_q <= 1'b1;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN : ST_ERROR;
                        drain_error_code_q <= ERR_CHILD_PROTOCOL;
                    end else if (child_result_valid_w
                                 && (state_q != ST_RESULT_WAIT)
                                 && (state_q != ST_WRITE_REQ)) begin
                        error_code_q <= ERR_CHILD_PROTOCOL;
                        child_reset_q <= 1'b1;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN : ST_ERROR;
                        drain_error_code_q <= ERR_CHILD_PROTOCOL;
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
                                end else if (COMMAND_TIMEOUT_CYCLES
                                             <= 64'd1) begin
                                    error_code_q <= ERR_COMMAND_TIMEOUT;
                                    state_q <= ST_ERROR;
                                end else begin
                                    activation_semantic_end_q
                                        <= activation_end_w[63:0];
                                    weight_semantic_end_q
                                        <= weight_end_w[63:0];
                                    dst_semantic_end_q <= dst_end_w[63:0];
                                    state_q <= ST_CHILD_START;
                                end
                            end

                            ST_CHILD_START: begin
                                if (child_start_fire_w)
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
                                    activation_word_q
                                        <= activation_word_addr_w[2]
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
                                        weight_row_index_q <= 32'b0;
                                        weight_block_index_q <= 32'b0;
                                        weight_byte_index_q <= 6'b0;
                                        state_q <= ST_WEIGHT_LOOKUP;
                                    end else begin
                                        activation_word_index_q
                                            <= activation_word_index_q + 32'd1;
                                        state_q <= ST_ACT_LOOKUP;
                                    end
                                end
                            end

                            ST_WEIGHT_LOOKUP: begin
                                if (!weight_runtime_ok_w) begin
                                    error_code_q <= ERR_INTERNAL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else if (cache_valid_q
                                             && (cache_addr_q
                                                 == weight_aligned_addr_w[63:0])) begin
                                    weight_block_q[(weight_byte_index_q * 8)
                                                   +: 8]
                                        <= cache_data_q[(weight_byte_addr_w[2:0]
                                                         * 8) +: 8];
                                    if (weight_byte_index_q == 6'd33) begin
                                        state_q <= ST_WEIGHT_SEND;
                                    end else begin
                                        weight_byte_index_q
                                            <= weight_byte_index_q + 6'd1;
                                    end
                                end else begin
                                    state_q <= ST_WEIGHT_REQ;
                                end
                            end

                            ST_WEIGHT_REQ: begin
                                if (!weight_runtime_ok_w) begin
                                    error_code_q <= ERR_INTERNAL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else if (gmem_req_fire_w) begin
                                    state_q <= ST_WEIGHT_WAIT;
                                end
                            end

                            ST_WEIGHT_WAIT: begin
                                if (gmem_rsp_fire_w) begin
                                    cache_valid_q <= 1'b1;
                                    cache_addr_q <= outstanding_addr_q;
                                    cache_data_q <= gmem_rsp_rdata_i;
                                    state_q <= ST_WEIGHT_LOOKUP;
                                end
                            end

                            ST_WEIGHT_SEND: begin
                                if (!child_result_valid_w
                                    && child_weight_fire_w) begin
                                    weight_blocks_accepted_q
                                        <= weight_blocks_accepted_q + 64'd1;
                                    weight_payload_bytes_q
                                        <= weight_payload_bytes_q + 64'd34;
                                    if (weight_block_index_q
                                        == (block_count_q - 32'd1)) begin
                                        result_row_index_q
                                            <= weight_row_index_q;
                                        state_q <= ST_RESULT_WAIT;
                                    end else begin
                                        weight_block_index_q
                                            <= weight_block_index_q + 32'd1;
                                        weight_byte_index_q <= 6'b0;
                                        state_q <= ST_WEIGHT_LOOKUP;
                                    end
                                end
                            end

                            ST_RESULT_WAIT: begin
                                if (child_result_valid_w) begin
                                    if ((child_result_row_w
                                         != result_row_index_q)
                                        || !result_runtime_ok_w) begin
                                        error_code_q <= ERR_CHILD_PROTOCOL;
                                        child_reset_q <= 1'b1;
                                        state_q <= ST_ERROR;
                                    end else begin
                                        held_result_bits_q
                                            <= child_result_bits_w;
                                        held_result_row_q
                                            <= child_result_row_w;
                                        held_write_addr_q
                                            <= result_aligned_addr_w[63:0];
                                        if (result_addr_w[2]) begin
                                            held_write_data_q
                                                <= {child_result_bits_w,
                                                    32'b0};
                                            held_write_strb_q <= 8'hf0;
                                        end else begin
                                            held_write_data_q
                                                <= {32'b0,
                                                    child_result_bits_w};
                                            held_write_strb_q <= 8'h0f;
                                        end
                                        state_q <= ST_WRITE_REQ;
                                    end
                                end
                            end

                            ST_WRITE_REQ: begin
                                if (!held_result_match_w) begin
                                    error_code_q <= ERR_CHILD_PROTOCOL;
                                    child_reset_q <= 1'b1;
                                    state_q <= ST_ERROR;
                                end else if (gmem_req_fire_w) begin
                                    if (!child_result_fire_w) begin
                                        error_code_q <= ERR_CHILD_PROTOCOL;
                                        child_reset_q <= 1'b1;
                                        state_q <= ST_GMEM_DRAIN;
                                        drain_error_code_q
                                            <= ERR_CHILD_PROTOCOL;
                                    end else begin
                                        rows_written_q <= rows_written_q + 32'd1;
                                        state_q <= ST_WRITE_WAIT;
                                    end
                                end
                            end

                            ST_WRITE_WAIT: begin
                                if (gmem_rsp_fire_w) begin
                                    if (result_row_index_q
                                        == (row_count_q - 32'd1)) begin
                                        // Global response accounting above is
                                        // nonblocking; compare the successful
                                        // final write with its +1 contribution.
                                        if ((child_done_seen_q || child_done_w)
                                            && ({32'b0,
                                                 activation_words_accepted_q}
                                                == expected_activation_words_w)
                                            && (weight_blocks_accepted_q
                                                == expected_weight_blocks_w)
                                            && (rows_written_q == row_count_q)
                                            && (activation_payload_bytes_q
                                                == expected_activation_bytes_w)
                                            && (weight_payload_bytes_q
                                                == expected_weight_bytes_w)
                                            && (gmem_read_beats_q
                                                == gmem_read_beats_completed_q)
                                            && (gmem_write_beats_q
                                                == row_count_q)
                                            && ((writes_completed_q + 32'd1)
                                                == row_count_q)
                                            && ((write_bytes_q + 64'd4)
                                                == expected_output_bytes_w)
                                            && ({32'b0,
                                                 child_activation_words_w}
                                                == expected_activation_words_w)
                                            && (child_weight_blocks_w
                                                == expected_weight_blocks_w)
                                            && (child_rows_emitted_w
                                                == row_count_q)) begin
                                            error_code_q <= ERR_NONE;
                                            state_q <= ST_DONE;
                                        end else begin
                                            state_q <= ST_FINAL_WAIT;
                                        end
                                    end else begin
                                        result_row_index_q
                                            <= result_row_index_q + 32'd1;
                                        weight_row_index_q
                                            <= weight_row_index_q + 32'd1;
                                        weight_block_index_q <= 32'b0;
                                        weight_byte_index_q <= 6'b0;
                                        state_q <= ST_WEIGHT_LOOKUP;
                                    end
                                end
                            end

                            ST_FINAL_WAIT: begin
                                if (child_done_seen_q || child_done_w) begin
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
                                state_q <= outstanding_q
                                         ? ST_GMEM_DRAIN : ST_ERROR;
                                drain_error_code_q <= ERR_INTERNAL;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

    // Keep otherwise useful integration probes intentional under lint.
    wire unused_child_busy_w;
    assign unused_child_busy_w = child_busy_w;

endmodule

`default_nettype wire
