`timescale 1ns/1ps
`default_nettype none

// Transactional raw-GMEM owner for the exact frozen-v5 RMS_NORM/L2_NORM
// profiles.  TensorNpuNormEngine is the only numeric implementation.  This
// wrapper proves descriptor/capability bounds, transports raw F32 words, runs
// one Engine transaction per row, and publishes only a whole-command commit.
module TensorNpuNormWritebackAdapter #(
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd512,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd10000000,
    parameter [31:0] ENGINE_STALL_TIMEOUT_CYCLES = 32'd256,
    parameter [31:0] ENGINE_COMMAND_TIMEOUT_CYCLES = 32'd262144
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [2:0]   reduce_op_i,
    input  wire [31:0]  epsilon_bits_i,
    input  wire         op_params_tail_zero_i,
    input  wire         npu_required_i,
    input  wire [63:0]  command_id_i,
    input  wire [63:0]  canonical_node_id_lo_i,
    input  wire [63:0]  canonical_node_id_hi_i,
    input  wire         dst_shadow_private_i,
    input  wire         windows_generation_valid_i,

    input  wire [31:0]  ne0_i,
    input  wire [31:0]  ne1_i,
    input  wire [31:0]  ne2_i,
    input  wire [31:0]  ne3_i,

    // src0_base_i is the runtime tensor data pointer after any manifest view
    // offset has been applied.  The frozen descriptor strides are still
    // checked exactly below.
    input  wire [63:0]  src0_base_i,
    input  wire [63:0]  src0_nb0_i,
    input  wire [63:0]  src0_nb1_i,
    input  wire [63:0]  src0_nb2_i,
    input  wire [63:0]  src0_nb3_i,
    input  wire [63:0]  src1_base_i,
    input  wire [63:0]  src1_nb0_i,
    input  wire [63:0]  src1_nb1_i,
    input  wire [63:0]  src1_nb2_i,
    input  wire [63:0]  src1_nb3_i,
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
    output wire [31:0]  completion_epsilon_bits_o,
    output wire [7:0]   completion_profile_id_o,
    output wire [31:0]  completion_kernel_id_o,
    output wire [31:0]  completion_operator_census_o,
    output wire [31:0]  completion_profile_census_o,
    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,
    output wire [4:0]   engine_error_code_o,

    output wire [63:0]  rows_completed_o,
    output wire [63:0]  source_words_completed_o,
    output wire [63:0]  engine_input_elements_o,
    output wire [63:0]  engine_output_elements_o,
    output wire [63:0]  elements_completed_o,
    output wire [63:0]  engine_launches_o,
    output wire [63:0]  engine_terminals_o,
    output wire [63:0]  engine_aborts_o,
    output wire [4:0]   engine_flags_or_o,
    output wire [63:0]  engine_active_cycles_o,
    output wire [63:0]  gmem_read_beats_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_beats_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire         engine_outstanding_o,
    output wire         gmem_drain_o
);

    localparam [2:0] REDUCE_RMSNORM = 3'd4;
    localparam [2:0] REDUCE_L2NORM  = 3'd5;
    localparam [31:0] EPSILON_QWEN = 32'h358637bd;
    localparam [31:0] KERNEL_REDUCE_F32 = 32'h514e0011;

    localparam [7:0] PROFILE_RMS_D1024_R1 = 8'd0;
    localparam [7:0] PROFILE_RMS_D128_R16 = 8'd1;
    localparam [7:0] PROFILE_RMS_D256_R2  = 8'd2;
    localparam [7:0] PROFILE_RMS_D256_R8  = 8'd3;
    localparam [7:0] PROFILE_L2_D128_R16  = 8'd4;
    localparam [7:0] PROFILE_INVALID      = 8'hff;

    localparam [4:0] ST_IDLE               = 5'd0;
    localparam [4:0] ST_PREFLIGHT          = 5'd1;
    localparam [4:0] ST_ENGINE_START       = 5'd2;
    localparam [4:0] ST_READ_PREP          = 5'd3;
    localparam [4:0] ST_READ_REQ           = 5'd4;
    localparam [4:0] ST_READ_WAIT          = 5'd5;
    localparam [4:0] ST_LANE_SEND          = 5'd6;
    localparam [4:0] ST_ENGINE_OUTPUT_WAIT = 5'd7;
    localparam [4:0] ST_WRITE_PREP         = 5'd8;
    localparam [4:0] ST_WRITE_REQ          = 5'd9;
    localparam [4:0] ST_WRITE_WAIT         = 5'd10;
    localparam [4:0] ST_OUT_CONSUME        = 5'd11;
    localparam [4:0] ST_ENGINE_TERM        = 5'd12;
    localparam [4:0] ST_GMEM_DRAIN         = 5'd13;
    localparam [4:0] ST_ENGINE_ABORT       = 5'd14;
    localparam [4:0] ST_DONE               = 5'd15;
    localparam [4:0] ST_ERROR              = 5'd16;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_PROFILE         = 5'd1;
    localparam [4:0] ERR_SOURCE0_WINDOW  = 5'd2;
    localparam [4:0] ERR_SOURCE1_WINDOW  = 5'd3;
    localparam [4:0] ERR_DEST_WINDOW     = 5'd4;
    localparam [4:0] ERR_ALIAS           = 5'd5;
    localparam [4:0] ERR_ENGINE          = 5'd6;
    localparam [4:0] ERR_GMEM_RESPONSE   = 5'd7;
    localparam [4:0] ERR_STALL_TIMEOUT   = 5'd8;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd9;
    localparam [4:0] ERR_INTERNAL_STATE  = 5'd10;

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                        : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 64'd1) ? 64'd0
                                          : COMMAND_TIMEOUT_CYCLES - 64'd1;

    reg [4:0] state_q;
    reg [2:0] reduce_op_q;
    reg [31:0] epsilon_bits_q;
    reg op_params_tail_zero_q, npu_required_q;
    reg [63:0] command_id_q, canonical_node_id_lo_q;
    reg [63:0] canonical_node_id_hi_q;
    reg dst_shadow_private_q, windows_generation_valid_q;
    reg [31:0] ne0_q, ne1_q, ne2_q, ne3_q;
    reg [63:0] src0_base_q, src0_nb0_q, src0_nb1_q, src0_nb2_q, src0_nb3_q;
    reg [63:0] src1_base_q, src1_nb0_q, src1_nb1_q, src1_nb2_q, src1_nb3_q;
    reg [63:0] dst_base_q, dst_nb0_q, dst_nb1_q, dst_nb2_q, dst_nb3_q;
    reg [63:0] src0_window_base_q, src0_window_bytes_q;
    reg src0_window_read_q, src0_window_write_q;
    reg [63:0] src1_window_base_q, src1_window_bytes_q;
    reg src1_window_read_q, src1_window_write_q;
    reg [63:0] dst_window_base_q, dst_window_bytes_q;
    reg dst_window_read_q, dst_window_write_q;

    reg [7:0] profile_id_q;
    reg [31:0] operator_census_q, profile_census_q;
    reg [31:0] row_index_q, element_index_q;
    reg [31:0] held_source_q, held_output_q;
    reg read_upper_q;
    reg [63:0] request_addr_q, request_wdata_q;
    reg [7:0] request_wstrb_q;
    reg outstanding_q, outstanding_write_q, engine_resident_q;
    reg [4:0] error_code_q, drain_error_code_q, engine_error_code_q;
    reg [31:0] stall_cycles_q;
    reg [63:0] command_cycles_q, active_cycles_q;
    reg [63:0] rows_completed_q, source_words_completed_q;
    reg [63:0] engine_input_elements_q, engine_output_elements_q;
    reg [63:0] elements_completed_q;
    reg [63:0] engine_launches_q, engine_terminals_q, engine_aborts_q;
    reg [4:0] engine_flags_or_q;
    reg [63:0] engine_active_cycles_q;
    reg [63:0] gmem_read_beats_q, gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_beats_q, gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;

    wire engine_ready_w, engine_busy_w, engine_lane_ready_w;
    wire engine_out_valid_w, engine_out_last_w;
    wire [31:0] engine_out_bits_w;
    wire [10:0] engine_out_index_w;
    wire engine_done_w, engine_error_w;
    wire [4:0] engine_error_code_w, engine_flags_w;
    wire [10:0] engine_elements_accepted_w, engine_elements_emitted_w;
    wire [31:0] engine_active_cycles_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE) && engine_ready_w;
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
    assign completion_epsilon_bits_o = completion_valid_o
                                         ? epsilon_bits_q : 32'b0;
    assign completion_profile_id_o = completion_valid_o ? profile_id_q : 8'b0;
    assign completion_kernel_id_o = completion_valid_o
                                      ? KERNEL_REDUCE_F32 : 32'b0;
    assign completion_operator_census_o = completion_valid_o
                                            ? operator_census_q : 32'b0;
    assign completion_profile_census_o = completion_valid_o
                                           ? profile_census_q : 32'b0;
    assign error_code_o = error_code_q;
    assign engine_error_code_o = engine_error_code_q;
    assign rows_completed_o = rows_completed_q;
    assign source_words_completed_o = source_words_completed_q;
    assign engine_input_elements_o = engine_input_elements_q;
    assign engine_output_elements_o = engine_output_elements_q;
    assign elements_completed_o = elements_completed_q;
    assign engine_launches_o = engine_launches_q;
    assign engine_terminals_o = engine_terminals_q;
    assign engine_aborts_o = engine_aborts_q;
    assign engine_flags_or_o = engine_flags_or_q;
    assign engine_active_cycles_o = engine_active_cycles_q;
    assign gmem_read_beats_o = gmem_read_beats_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_beats_o = gmem_write_beats_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign engine_outstanding_o = engine_resident_q;
    assign gmem_drain_o = !rst_i && (state_q == ST_GMEM_DRAIN);

    wire start_fire_w = start_i && ready_o;
    wire request_state_w = (state_q == ST_READ_REQ)
                         || (state_q == ST_WRITE_REQ);
    wire response_state_w = (state_q == ST_READ_WAIT)
                          || (state_q == ST_WRITE_WAIT)
                          || (state_q == ST_GMEM_DRAIN);
    wire stall_state_w = (state_q == ST_READ_REQ)
                       || (state_q == ST_READ_WAIT)
                       || (state_q == ST_WRITE_REQ)
                       || (state_q == ST_WRITE_WAIT);
    wire command_timeout_hit_w = command_cycles_q >= COMMAND_TIMEOUT_LAST;
    wire stall_timeout_hit_w = stall_cycles_q >= STALL_TIMEOUT_LAST;
    assign gmem_req_valid_o = !rst_i && request_state_w
                            && !command_timeout_hit_w
                            && !stall_timeout_hit_w;
    assign gmem_req_write_o = (state_q == ST_WRITE_REQ);
    assign gmem_req_addr_o = request_addr_q;
    assign gmem_req_wdata_o = (state_q == ST_WRITE_REQ)
                            ? request_wdata_q : 64'b0;
    assign gmem_req_wstrb_o = (state_q == ST_WRITE_REQ)
                            ? request_wstrb_q : 8'b0;
    assign gmem_rsp_ready_o = !rst_i && response_state_w && outstanding_q;
    wire gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    wire gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;
    wire [31:0] response_word_w = read_upper_q
                                   ? gmem_rsp_rdata_i[63:32]
                                   : gmem_rsp_rdata_i[31:0];

    reg profile_match_w;
    reg [7:0] profile_id_w;
    reg [31:0] operator_census_w, profile_census_w;
    reg src0_layout_w, dst_layout_w, src1_layout_w;
    reg shape_rms1024_w, shape_rms128_w, shape_rms256r2_w;
    reg shape_rms256r8_w, shape_l2r128_w;
    always @(*) begin
        shape_rms1024_w = (ne0_q == 32'd1024) && (ne1_q == 32'd1)
                        && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_rms128_w = (ne0_q == 32'd128) && (ne1_q == 32'd16)
                       && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_rms256r2_w = (ne0_q == 32'd256) && (ne1_q == 32'd2)
                         && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_rms256r8_w = (ne0_q == 32'd256) && (ne1_q == 32'd8)
                         && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_l2r128_w = shape_rms128_w;
        src0_layout_w = 1'b0;
        dst_layout_w = 1'b0;
        if (shape_rms1024_w) begin
            src0_layout_w = (src0_nb0_q == 64'd4)
                          && (src0_nb1_q == 64'd4096)
                          && (src0_nb2_q == 64'd4096)
                          && (src0_nb3_q == 64'd4096);
            dst_layout_w = (dst_nb0_q == 64'd4)
                         && (dst_nb1_q == 64'd4096)
                         && (dst_nb2_q == 64'd4096)
                         && (dst_nb3_q == 64'd4096);
        end else if (shape_rms256r2_w) begin
            src0_layout_w = (src0_nb0_q == 64'd4)
                          && (src0_nb1_q == 64'd1024)
                          && (src0_nb2_q == 64'd2048)
                          && (src0_nb3_q == 64'd2048);
            dst_layout_w = (dst_nb0_q == 64'd4)
                         && (dst_nb1_q == 64'd1024)
                         && (dst_nb2_q == 64'd2048)
                         && (dst_nb3_q == 64'd2048);
        end else if (shape_rms256r8_w) begin
            src0_layout_w = (src0_nb0_q == 64'd4)
                          && (src0_nb1_q == 64'd2048)
                          && (src0_nb2_q == 64'd16384)
                          && (src0_nb3_q == 64'd16384);
            dst_layout_w = (dst_nb0_q == 64'd4)
                         && (dst_nb1_q == 64'd1024)
                         && (dst_nb2_q == 64'd8192)
                         && (dst_nb3_q == 64'd8192);
        end else if (shape_rms128_w && (reduce_op_q == REDUCE_RMSNORM)) begin
            src0_layout_w = (src0_nb0_q == 64'd4)
                          && (src0_nb1_q == 64'd512)
                          && (src0_nb2_q == 64'd4)
                          && (src0_nb3_q == 64'd8192);
            dst_layout_w = (dst_nb0_q == 64'd4)
                         && (dst_nb1_q == 64'd512)
                         && (dst_nb2_q == 64'd8192)
                         && (dst_nb3_q == 64'd8192);
        end else if (shape_l2r128_w && (reduce_op_q == REDUCE_L2NORM)) begin
            src0_layout_w = (src0_nb0_q == 64'd4)
                          && (src0_nb1_q == 64'd512)
                          && (src0_nb2_q == 64'd24576)
                          && (src0_nb3_q == 64'd24576);
            dst_layout_w = (dst_nb0_q == 64'd4)
                         && (dst_nb1_q == 64'd512)
                         && (dst_nb2_q == 64'd8192)
                         && (dst_nb3_q == 64'd8192);
        end
        src1_layout_w = (src1_nb0_q == 64'b0)
                      && (src1_nb1_q == 64'b0)
                      && (src1_nb2_q == 64'b0)
                      && (src1_nb3_q == 64'b0);

        profile_match_w = 1'b0;
        profile_id_w = PROFILE_INVALID;
        operator_census_w = (reduce_op_q == REDUCE_RMSNORM)
                              ? 32'd79
                              : (reduce_op_q == REDUCE_L2NORM)
                                  ? 32'd36 : 32'b0;
        profile_census_w = 32'b0;
        if ((reduce_op_q == REDUCE_RMSNORM) && shape_rms1024_w
                && src0_layout_w && dst_layout_w && src1_layout_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_RMS_D1024_R1;
            profile_census_w = 32'd49;
        end else if ((reduce_op_q == REDUCE_RMSNORM) && shape_rms128_w
                && src0_layout_w && dst_layout_w && src1_layout_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_RMS_D128_R16;
            profile_census_w = 32'd18;
        end else if ((reduce_op_q == REDUCE_RMSNORM) && shape_rms256r2_w
                && src0_layout_w && dst_layout_w && src1_layout_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_RMS_D256_R2;
            profile_census_w = 32'd6;
        end else if ((reduce_op_q == REDUCE_RMSNORM) && shape_rms256r8_w
                && src0_layout_w && dst_layout_w && src1_layout_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_RMS_D256_R8;
            profile_census_w = 32'd6;
        end else if ((reduce_op_q == REDUCE_L2NORM) && shape_l2r128_w
                && src0_layout_w && dst_layout_w && src1_layout_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_L2_D128_R16;
            profile_census_w = 32'd36;
        end
    end

    reg [127:0] total_elements_w, src0_last_w, dst_last_w;
    reg [127:0] src0_end_w, dst_end_w;
    reg [127:0] src0_window_end_w, src1_window_end_w, dst_window_end_w;
    reg [127:0] src0_phys_start_w, src0_phys_end_w;
    reg [127:0] dst_phys_start_w, dst_phys_end_w, align_tmp_w;
    reg descriptor_ok_w, src0_window_ok_w, src1_window_ok_w;
    reg dst_window_ok_w, alias_ok_w;
    reg [4:0] preflight_error_w;
    always @(*) begin
        total_elements_w = {96'b0, ne0_q} * {96'b0, ne1_q}
                         * {96'b0, ne2_q} * {96'b0, ne3_q};
        src0_last_w = ({96'b0, (ne0_q - 32'd1)} * {64'b0, src0_nb0_q})
                    + ({96'b0, (ne1_q - 32'd1)} * {64'b0, src0_nb1_q})
                    + ({96'b0, (ne2_q - 32'd1)} * {64'b0, src0_nb2_q})
                    + ({96'b0, (ne3_q - 32'd1)} * {64'b0, src0_nb3_q});
        dst_last_w = ({96'b0, (ne0_q - 32'd1)} * {64'b0, dst_nb0_q})
                   + ({96'b0, (ne1_q - 32'd1)} * {64'b0, dst_nb1_q})
                   + ({96'b0, (ne2_q - 32'd1)} * {64'b0, dst_nb2_q})
                   + ({96'b0, (ne3_q - 32'd1)} * {64'b0, dst_nb3_q});
        src0_end_w = {64'b0, src0_base_q} + src0_last_w + 128'd4;
        dst_end_w = {64'b0, dst_base_q} + dst_last_w + 128'd4;
        src0_window_end_w = {64'b0, src0_window_base_q}
                          + {64'b0, src0_window_bytes_q};
        src1_window_end_w = {64'b0, src1_window_base_q}
                          + {64'b0, src1_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};
        src0_phys_start_w = {64'b0, src0_base_q};
        src0_phys_start_w[2:0] = 3'b000;
        align_tmp_w = src0_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        src0_phys_end_w = align_tmp_w + 128'd8;
        dst_phys_start_w = {64'b0, dst_base_q};
        dst_phys_start_w[2:0] = 3'b000;
        align_tmp_w = dst_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        dst_phys_end_w = align_tmp_w + 128'd8;

        descriptor_ok_w = profile_match_w
                       && (epsilon_bits_q == EPSILON_QWEN)
                       && op_params_tail_zero_q
                       && dst_shadow_private_q && windows_generation_valid_q
                       && ((canonical_node_id_lo_q != 64'b0)
                           || (canonical_node_id_hi_q != 64'b0))
                       && (total_elements_w != 128'b0)
                       && (total_elements_w[127:64] == 64'b0);
        src0_window_ok_w = (src0_window_end_w[127:64] == 64'b0)
                        && (src0_end_w[127:64] == 64'b0)
                        && (src0_phys_start_w[127:64] == 64'b0)
                        && (src0_phys_end_w[127:64] == 64'b0)
                        && (src0_base_q[1:0] == 2'b00)
                        && (src0_window_base_q[2:0] == 3'b000)
                        && (src0_window_bytes_q[2:0] == 3'b000)
                        && src0_window_read_q && !src0_window_write_q
                        && (src0_window_bytes_q != 64'b0)
                        && (src0_phys_start_w >= {64'b0, src0_window_base_q})
                        && (src0_phys_end_w <= src0_window_end_w);
        src1_window_ok_w = (src1_window_end_w[127:64] == 64'b0)
                        && (src1_base_q[1:0] == 2'b00)
                        && (src1_window_base_q[2:0] == 3'b000)
                        && (src1_window_bytes_q == 64'b0)
                        && src1_window_read_q && !src1_window_write_q;
        dst_window_ok_w = (dst_window_end_w[127:64] == 64'b0)
                       && (dst_end_w[127:64] == 64'b0)
                       && (dst_phys_start_w[127:64] == 64'b0)
                       && (dst_phys_end_w[127:64] == 64'b0)
                       && (dst_base_q[1:0] == 2'b00)
                       && (dst_window_base_q[2:0] == 3'b000)
                       && (dst_window_bytes_q[2:0] == 3'b000)
                       && !dst_window_read_q && dst_window_write_q
                       && (dst_window_bytes_q != 64'b0)
                       && (dst_phys_start_w >= {64'b0, dst_window_base_q})
                       && (dst_phys_end_w <= dst_window_end_w);
        alias_ok_w = (dst_phys_end_w <= src0_phys_start_w)
                  || (dst_phys_start_w >= src0_phys_end_w);
        if (!descriptor_ok_w)
            preflight_error_w = ERR_PROFILE;
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

    reg [127:0] runtime_addr_w, runtime_end_w;
    reg [127:0] runtime_phys_start_w, runtime_phys_end_w;
    reg [127:0] runtime_window_start_w, runtime_window_end_w;
    reg [127:0] runtime_align_w;
    reg runtime_ok_w;
    always @(*) begin
        runtime_addr_w = 128'b0;
        runtime_window_start_w = 128'b0;
        runtime_window_end_w = 128'b0;
        runtime_ok_w = (element_index_q < ne0_q) && (row_index_q < ne1_q);
        if (state_q == ST_READ_PREP) begin
            runtime_addr_w = {64'b0, src0_base_q}
                           + ({96'b0, element_index_q}
                              * {64'b0, src0_nb0_q})
                           + ({96'b0, row_index_q}
                              * {64'b0, src0_nb1_q});
            runtime_window_start_w = {64'b0, src0_window_base_q};
            runtime_window_end_w = src0_window_end_w;
        end else if (state_q == ST_WRITE_PREP) begin
            runtime_addr_w = {64'b0, dst_base_q}
                           + ({96'b0, element_index_q}
                              * {64'b0, dst_nb0_q})
                           + ({96'b0, row_index_q}
                              * {64'b0, dst_nb1_q});
            runtime_window_start_w = {64'b0, dst_window_base_q};
            runtime_window_end_w = dst_window_end_w;
        end else begin
            runtime_ok_w = 1'b0;
        end
        runtime_end_w = runtime_addr_w + 128'd4;
        runtime_phys_start_w = runtime_addr_w;
        runtime_phys_start_w[2:0] = 3'b000;
        runtime_align_w = runtime_end_w - 128'd1;
        runtime_align_w[2:0] = 3'b000;
        runtime_phys_end_w = runtime_align_w + 128'd8;
        runtime_ok_w = runtime_ok_w && (runtime_addr_w[1:0] == 2'b00)
                    && (runtime_addr_w[127:64] == 64'b0)
                    && (runtime_end_w[127:64] == 64'b0)
                    && (runtime_phys_start_w >= runtime_window_start_w)
                    && (runtime_phys_end_w <= runtime_window_end_w);
    end

    wire engine_rst_w = rst_i || (state_q == ST_ENGINE_ABORT);
    wire engine_start_w = (state_q == ST_ENGINE_START)
                        && !command_timeout_hit_w;
    wire engine_start_fire_w = engine_start_w && engine_ready_w;
    wire engine_lane_valid_w = (state_q == ST_LANE_SEND)
                             && !command_timeout_hit_w;
    wire engine_lane_fire_w = engine_lane_valid_w && engine_lane_ready_w;
    wire engine_out_ready_w = (state_q == ST_OUT_CONSUME)
                            && !command_timeout_hit_w;
    wire engine_out_fire_w = engine_out_valid_w && engine_out_ready_w;
    wire [1:0] engine_mode_w = (reduce_op_q == REDUCE_RMSNORM)
                                ? 2'd0 : 2'd1;

    TensorNpuNormEngine #(
        .MAX_D(1024),
        .STALL_TIMEOUT_CYCLES(ENGINE_STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES(ENGINE_COMMAND_TIMEOUT_CYCLES)
    ) u_engine (
        .clk_i(clk_i), .rst_i(engine_rst_w),
        .start_i(engine_start_w), .ready_o(engine_ready_w),
        .busy_o(engine_busy_w), .mode_i(engine_mode_w),
        .element_count_i(ne0_q[10:0]), .eps_bits_i(epsilon_bits_q),
        .lane_valid_i(engine_lane_valid_w),
        .lane_ready_o(engine_lane_ready_w), .lane_bits_i(held_source_q),
        .out_valid_o(engine_out_valid_w),
        .out_ready_i(engine_out_ready_w), .out_bits_o(engine_out_bits_w),
        .out_index_o(engine_out_index_w), .out_last_o(engine_out_last_w),
        .done_o(engine_done_w), .error_o(engine_error_w),
        .error_code_o(engine_error_code_w), .flags_o(engine_flags_w),
        .elements_accepted_o(engine_elements_accepted_w),
        .elements_emitted_o(engine_elements_emitted_w),
        .active_cycles_o(engine_active_cycles_w)
    );

    wire progress_w = gmem_req_fire_w || gmem_rsp_fire_w
                    || engine_start_fire_w || engine_lane_fire_w
                    || engine_out_fire_w || engine_done_w;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            reduce_op_q <= 3'b0; epsilon_bits_q <= 32'b0;
            op_params_tail_zero_q <= 1'b0; npu_required_q <= 1'b0;
            command_id_q <= 64'b0; canonical_node_id_lo_q <= 64'b0;
            canonical_node_id_hi_q <= 64'b0;
            dst_shadow_private_q <= 1'b0; windows_generation_valid_q <= 1'b0;
            ne0_q <= 0; ne1_q <= 0; ne2_q <= 0; ne3_q <= 0;
            src0_base_q <= 0; src0_nb0_q <= 0; src0_nb1_q <= 0;
            src0_nb2_q <= 0; src0_nb3_q <= 0;
            src1_base_q <= 0; src1_nb0_q <= 0; src1_nb1_q <= 0;
            src1_nb2_q <= 0; src1_nb3_q <= 0;
            dst_base_q <= 0; dst_nb0_q <= 0; dst_nb1_q <= 0;
            dst_nb2_q <= 0; dst_nb3_q <= 0;
            src0_window_base_q <= 0; src0_window_bytes_q <= 0;
            src0_window_read_q <= 0; src0_window_write_q <= 0;
            src1_window_base_q <= 0; src1_window_bytes_q <= 0;
            src1_window_read_q <= 0; src1_window_write_q <= 0;
            dst_window_base_q <= 0; dst_window_bytes_q <= 0;
            dst_window_read_q <= 0; dst_window_write_q <= 0;
            profile_id_q <= PROFILE_INVALID;
            operator_census_q <= 0; profile_census_q <= 0;
            row_index_q <= 0; element_index_q <= 0;
            held_source_q <= 0; held_output_q <= 0; read_upper_q <= 0;
            request_addr_q <= 0; request_wdata_q <= 0; request_wstrb_q <= 0;
            outstanding_q <= 0; outstanding_write_q <= 0;
            engine_resident_q <= 0;
            error_code_q <= ERR_NONE; drain_error_code_q <= ERR_NONE;
            engine_error_code_q <= 0; stall_cycles_q <= 0;
            command_cycles_q <= 0; active_cycles_q <= 0;
            rows_completed_q <= 0; source_words_completed_q <= 0;
            engine_input_elements_q <= 0; engine_output_elements_q <= 0;
            elements_completed_q <= 0; engine_launches_q <= 0;
            engine_terminals_q <= 0; engine_aborts_q <= 0;
            engine_flags_or_q <= 0; engine_active_cycles_q <= 0;
            gmem_read_beats_q <= 0; gmem_read_responses_q <= 0;
            read_payload_bytes_q <= 0; gmem_write_beats_q <= 0;
            gmem_write_responses_q <= 0; write_payload_bytes_q <= 0;
        end else begin
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)) begin
                command_cycles_q <= command_cycles_q + 64'd1;
                active_cycles_q <= active_cycles_q + 64'd1;
            end
            if (stall_state_w) begin
                if (gmem_req_fire_w || gmem_rsp_fire_w)
                    stall_cycles_q <= 0;
                else if (stall_cycles_q != 32'hffff_ffff)
                    stall_cycles_q <= stall_cycles_q + 32'd1;
            end else begin
                stall_cycles_q <= 0;
            end

            // A real Engine terminal has priority over wrapper watchdogs.  If
            // a GMEM response retires on the same edge, its credit is still
            // accounted before exposing the Engine failure.
            if (engine_resident_q && engine_done_w
                    && (state_q != ST_ENGINE_ABORT)
                    && (state_q != ST_GMEM_DRAIN)) begin
                engine_terminals_q <= engine_terminals_q + 64'd1;
                engine_active_cycles_q <= engine_active_cycles_q
                                           + {32'b0, engine_active_cycles_w};
                engine_flags_or_q <= engine_flags_or_q | engine_flags_w;
                engine_resident_q <= 1'b0;
                if (engine_error_w) begin
                    engine_error_code_q <= engine_error_code_w;
                    error_code_q <= ERR_ENGINE;
                    if (gmem_rsp_fire_w) begin
                        outstanding_q <= 1'b0;
                        if (outstanding_write_q) begin
                            gmem_write_responses_q <= gmem_write_responses_q
                                                       + 64'd1;
                            if (!gmem_rsp_error_i) begin
                                elements_completed_q <= elements_completed_q
                                                        + 64'd1;
                                write_payload_bytes_q <= write_payload_bytes_q
                                                         + 64'd4;
                            end
                        end else begin
                            gmem_read_responses_q <= gmem_read_responses_q
                                                      + 64'd1;
                        end
                        state_q <= ST_ERROR;
                    end else if (outstanding_q) begin
                        drain_error_code_q <= ERR_ENGINE;
                        state_q <= ST_GMEM_DRAIN;
                    end else begin
                        state_q <= ST_ERROR;
                    end
                end else if (state_q != ST_ENGINE_TERM) begin
                    error_code_q <= ERR_INTERNAL_STATE;
                    if (outstanding_q) begin
                        drain_error_code_q <= ERR_INTERNAL_STATE;
                        state_q <= ST_GMEM_DRAIN;
                    end else begin
                        state_q <= ST_ERROR;
                    end
                end else if ((engine_elements_accepted_w != ne0_q[10:0])
                        || (engine_elements_emitted_w != ne0_q[10:0])
                        || engine_out_valid_w || !engine_busy_w) begin
                    error_code_q <= ERR_INTERNAL_STATE;
                    state_q <= ST_ERROR;
                end else begin
                    rows_completed_q <= rows_completed_q + 64'd1;
                    if (row_index_q == (ne1_q - 32'd1)) begin
                        state_q <= ST_DONE;
                    end else begin
                        row_index_q <= row_index_q + 32'd1;
                        element_index_q <= 32'b0;
                        state_q <= ST_ENGINE_START;
                    end
                end
            end else if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR) && (state_q != ST_GMEM_DRAIN)
                    && (state_q != ST_ENGINE_ABORT)
                    && command_timeout_hit_w && !progress_w) begin
                if (outstanding_q) begin
                    drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_GMEM_DRAIN;
                end else if (engine_resident_q) begin
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_ENGINE_ABORT;
                end else begin
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_ERROR;
                end
            end else if (stall_state_w && stall_timeout_hit_w
                    && !(gmem_req_fire_w || gmem_rsp_fire_w)) begin
                if (outstanding_q) begin
                    drain_error_code_q <= ERR_STALL_TIMEOUT;
                    state_q <= ST_GMEM_DRAIN;
                end else if (engine_resident_q) begin
                    error_code_q <= ERR_STALL_TIMEOUT;
                    state_q <= ST_ENGINE_ABORT;
                end else begin
                    error_code_q <= ERR_STALL_TIMEOUT;
                    state_q <= ST_ERROR;
                end
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        outstanding_q <= 1'b0;
                        outstanding_write_q <= 1'b0;
                        engine_resident_q <= 1'b0;
                        if (start_fire_w) begin
                            reduce_op_q <= reduce_op_i;
                            epsilon_bits_q <= epsilon_bits_i;
                            op_params_tail_zero_q <= op_params_tail_zero_i;
                            npu_required_q <= npu_required_i;
                            command_id_q <= command_id_i;
                            canonical_node_id_lo_q <= canonical_node_id_lo_i;
                            canonical_node_id_hi_q <= canonical_node_id_hi_i;
                            dst_shadow_private_q <= dst_shadow_private_i;
                            windows_generation_valid_q <= windows_generation_valid_i;
                            ne0_q <= ne0_i; ne1_q <= ne1_i;
                            ne2_q <= ne2_i; ne3_q <= ne3_i;
                            src0_base_q <= src0_base_i; src0_nb0_q <= src0_nb0_i;
                            src0_nb1_q <= src0_nb1_i; src0_nb2_q <= src0_nb2_i;
                            src0_nb3_q <= src0_nb3_i;
                            src1_base_q <= src1_base_i; src1_nb0_q <= src1_nb0_i;
                            src1_nb1_q <= src1_nb1_i; src1_nb2_q <= src1_nb2_i;
                            src1_nb3_q <= src1_nb3_i;
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
                            operator_census_q <= 0; profile_census_q <= 0;
                            row_index_q <= 0; element_index_q <= 0;
                            held_source_q <= 0; held_output_q <= 0;
                            error_code_q <= ERR_NONE; drain_error_code_q <= ERR_NONE;
                            engine_error_code_q <= 0; stall_cycles_q <= 0;
                            command_cycles_q <= 0; active_cycles_q <= 0;
                            rows_completed_q <= 0; source_words_completed_q <= 0;
                            engine_input_elements_q <= 0;
                            engine_output_elements_q <= 0;
                            elements_completed_q <= 0; engine_launches_q <= 0;
                            engine_terminals_q <= 0; engine_aborts_q <= 0;
                            engine_flags_or_q <= 0; engine_active_cycles_q <= 0;
                            gmem_read_beats_q <= 0; gmem_read_responses_q <= 0;
                            read_payload_bytes_q <= 0; gmem_write_beats_q <= 0;
                            gmem_write_responses_q <= 0;
                            write_payload_bytes_q <= 0;
                            state_q <= ST_PREFLIGHT;
                        end
                    end
                    ST_PREFLIGHT: begin
                        profile_id_q <= profile_id_w;
                        operator_census_q <= operator_census_w;
                        profile_census_q <= profile_census_w;
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q <= ST_ERROR;
                        end else begin
                            state_q <= ST_ENGINE_START;
                        end
                    end
                    ST_ENGINE_START: if (engine_start_fire_w) begin
                        engine_resident_q <= 1'b1;
                        engine_launches_q <= engine_launches_q + 64'd1;
                        element_index_q <= 32'b0;
                        state_q <= ST_READ_PREP;
                    end
                    ST_READ_PREP: begin
                        if (!runtime_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ENGINE_ABORT;
                        end else begin
                            request_addr_q <= runtime_phys_start_w[63:0];
                            read_upper_q <= runtime_addr_w[2];
                            state_q <= ST_READ_REQ;
                        end
                    end
                    ST_READ_REQ: if (gmem_req_fire_w) begin
                        outstanding_q <= 1'b1; outstanding_write_q <= 1'b0;
                        gmem_read_beats_q <= gmem_read_beats_q + 64'd1;
                        state_q <= ST_READ_WAIT;
                    end
                    ST_READ_WAIT: if (gmem_rsp_fire_w) begin
                        outstanding_q <= 1'b0; outstanding_write_q <= 1'b0;
                        gmem_read_responses_q <= gmem_read_responses_q + 64'd1;
                        if (gmem_rsp_error_i) begin
                            error_code_q <= ERR_GMEM_RESPONSE;
                            state_q <= ST_ENGINE_ABORT;
                        end else begin
                            held_source_q <= response_word_w;
                            source_words_completed_q <= source_words_completed_q
                                                        + 64'd1;
                            read_payload_bytes_q <= read_payload_bytes_q + 64'd4;
                            state_q <= ST_LANE_SEND;
                        end
                    end
                    ST_LANE_SEND: if (engine_lane_fire_w) begin
                        engine_input_elements_q <= engine_input_elements_q
                                                   + 64'd1;
                        if (element_index_q == (ne0_q - 32'd1)) begin
                            element_index_q <= 32'b0;
                            state_q <= ST_ENGINE_OUTPUT_WAIT;
                        end else begin
                            element_index_q <= element_index_q + 32'd1;
                            state_q <= ST_READ_PREP;
                        end
                    end
                    ST_ENGINE_OUTPUT_WAIT: if (engine_out_valid_w) begin
                        if (engine_out_index_w != element_index_q[10:0]) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ENGINE_ABORT;
                        end else begin
                            held_output_q <= engine_out_bits_w;
                            state_q <= ST_WRITE_PREP;
                        end
                    end
                    ST_WRITE_PREP: begin
                        if (!runtime_ok_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ENGINE_ABORT;
                        end else begin
                            request_addr_q <= runtime_phys_start_w[63:0];
                            request_wdata_q <= runtime_addr_w[2]
                                ? {held_output_q, 32'b0}
                                : {32'b0, held_output_q};
                            request_wstrb_q <= runtime_addr_w[2]
                                ? 8'hf0 : 8'h0f;
                            state_q <= ST_WRITE_REQ;
                        end
                    end
                    ST_WRITE_REQ: if (gmem_req_fire_w) begin
                        outstanding_q <= 1'b1; outstanding_write_q <= 1'b1;
                        gmem_write_beats_q <= gmem_write_beats_q + 64'd1;
                        state_q <= ST_WRITE_WAIT;
                    end
                    ST_WRITE_WAIT: if (gmem_rsp_fire_w) begin
                        outstanding_q <= 1'b0; outstanding_write_q <= 1'b0;
                        gmem_write_responses_q <= gmem_write_responses_q + 64'd1;
                        if (gmem_rsp_error_i) begin
                            error_code_q <= ERR_GMEM_RESPONSE;
                            state_q <= ST_ENGINE_ABORT;
                        end else begin
                            elements_completed_q <= elements_completed_q + 64'd1;
                            write_payload_bytes_q <= write_payload_bytes_q + 64'd4;
                            state_q <= ST_OUT_CONSUME;
                        end
                    end
                    ST_OUT_CONSUME: begin
                        if (!engine_out_valid_w
                                || (engine_out_bits_w != held_output_q)
                                || (engine_out_index_w != element_index_q[10:0])
                                || (engine_out_last_w
                                    != (element_index_q == (ne0_q - 32'd1)))) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= ST_ENGINE_ABORT;
                        end else if (engine_out_fire_w) begin
                            engine_output_elements_q <= engine_output_elements_q
                                                    + 64'd1;
                            if (element_index_q == (ne0_q - 32'd1)) begin
                                state_q <= ST_ENGINE_TERM;
                            end else begin
                                element_index_q <= element_index_q + 32'd1;
                                state_q <= ST_ENGINE_OUTPUT_WAIT;
                            end
                        end
                    end
                    ST_ENGINE_TERM: begin
                        if (!engine_resident_q || !engine_busy_w) begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q <= engine_resident_q
                                     ? ST_ENGINE_ABORT : ST_ERROR;
                        end
                    end
                    ST_GMEM_DRAIN: if (gmem_rsp_fire_w) begin
                        outstanding_q <= 1'b0; outstanding_write_q <= 1'b0;
                        if (outstanding_write_q) begin
                            gmem_write_responses_q <= gmem_write_responses_q
                                                       + 64'd1;
                            if (!gmem_rsp_error_i) begin
                                elements_completed_q <= elements_completed_q
                                                        + 64'd1;
                                write_payload_bytes_q <= write_payload_bytes_q
                                                         + 64'd4;
                            end
                        end else begin
                            gmem_read_responses_q <= gmem_read_responses_q
                                                      + 64'd1;
                        end
                        error_code_q <= drain_error_code_q;
                        state_q <= engine_resident_q
                                 ? ST_ENGINE_ABORT : ST_ERROR;
                    end
                    ST_ENGINE_ABORT: begin
                        if (engine_resident_q) begin
                            engine_aborts_q <= engine_aborts_q + 64'd1;
                            engine_active_cycles_q <= engine_active_cycles_q
                                                   + {32'b0,
                                                      engine_active_cycles_w};
                            engine_flags_or_q <= engine_flags_or_q
                                               | engine_flags_w;
                        end
                        engine_resident_q <= 1'b0;
                        state_q <= ST_ERROR;
                    end
                    ST_DONE: if (outstanding_q || engine_resident_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN
                                                 : ST_ENGINE_ABORT;
                    end else begin
                        state_q <= ST_IDLE;
                    end
                    ST_ERROR: if (outstanding_q) begin
                        drain_error_code_q <= ERR_INTERNAL_STATE;
                        state_q <= ST_GMEM_DRAIN;
                    end else if (engine_resident_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q <= ST_ENGINE_ABORT;
                    end else begin
                        state_q <= ST_IDLE;
                    end
                    default: begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN
                              : engine_resident_q ? ST_ENGINE_ABORT
                                                  : ST_ERROR;
                    end
                endcase
            end
        end
    end

endmodule

`default_nettype wire
