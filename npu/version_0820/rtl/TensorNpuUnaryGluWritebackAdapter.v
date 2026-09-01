`timescale 1ns/1ps
`default_nettype none

// Transactional raw-GMEM owner for the exact Qwen3.5-0.8B v5 UNARY/GLU
// profiles.  TensorNpuUnaryGluElement is the sole numeric implementation; this
// module only transports raw F32 words, proves capabilities/layout, sequences
// scalar requests, and writes results into transaction-private storage.
module TensorNpuUnaryGluWritebackAdapter #(
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd512,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd10000000
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire         operation_glu_i,
    input  wire [7:0]   subtype_i,
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
    output wire         completion_operation_glu_o,
    output wire [7:0]   completion_subtype_o,
    output wire [7:0]   completion_profile_id_o,
    output wire [31:0]  completion_kernel_id_o,
    output wire [31:0]  completion_operator_census_o,
    output wire [31:0]  completion_subtype_census_o,
    output wire [31:0]  completion_profile_census_o,
    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,
    output wire [3:0]   element_error_code_o,

    output wire [63:0]  src0_words_completed_o,
    output wire [63:0]  src1_words_completed_o,
    output wire [63:0]  scalar_launches_o,
    output wire [63:0]  scalar_terminals_o,
    output wire [63:0]  elements_completed_o,
    output wire [4:0]   element_flags_or_o,
    output wire [4:0]   element_child_call_mask_or_o,
    output wire [63:0]  element_active_cycles_o,
    output wire [63:0]  gmem_read_beats_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_beats_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire         element_outstanding_o,
    output wire         gmem_drain_o
);

    localparam [7:0] SUBTYPE_SWIGLU   = 8'h02;
    localparam [7:0] SUBTYPE_SIGMOID  = 8'h07;
    localparam [7:0] SUBTYPE_SILU     = 8'h0a;
    localparam [7:0] SUBTYPE_EXP      = 8'h0d;
    localparam [7:0] SUBTYPE_SOFTPLUS = 8'h0f;

    localparam [7:0] PROFILE_SIGMOID_16   = 8'd0;
    localparam [7:0] PROFILE_SIGMOID_2048 = 8'd1;
    localparam [7:0] PROFILE_SOFTPLUS_16  = 8'd2;
    localparam [7:0] PROFILE_SILU_2048    = 8'd3;
    localparam [7:0] PROFILE_SILU_6144    = 8'd4;
    localparam [7:0] PROFILE_EXP_16       = 8'd5;
    localparam [7:0] PROFILE_SWIGLU_3584  = 8'd6;
    localparam [7:0] PROFILE_INVALID      = 8'hff;

    localparam [31:0] KERNEL_UNARY_F32 = 32'h514e0005;
    localparam [31:0] KERNEL_GLU_F32   = 32'h514e0006;

    localparam [4:0] ST_IDLE          = 5'd0;
    localparam [4:0] ST_PREFLIGHT     = 5'd1;
    localparam [4:0] ST_SRC0_PREP     = 5'd2;
    localparam [4:0] ST_SRC0_REQ      = 5'd3;
    localparam [4:0] ST_SRC0_WAIT     = 5'd4;
    localparam [4:0] ST_SRC1_PREP     = 5'd5;
    localparam [4:0] ST_SRC1_REQ      = 5'd6;
    localparam [4:0] ST_SRC1_WAIT     = 5'd7;
    localparam [4:0] ST_ELEMENT_REQ   = 5'd8;
    localparam [4:0] ST_ELEMENT_WAIT  = 5'd9;
    localparam [4:0] ST_WRITE_PREP    = 5'd10;
    localparam [4:0] ST_WRITE_REQ     = 5'd11;
    localparam [4:0] ST_WRITE_WAIT    = 5'd12;
    localparam [4:0] ST_GMEM_DRAIN    = 5'd13;
    localparam [4:0] ST_ELEMENT_ABORT = 5'd14;
    localparam [4:0] ST_DONE          = 5'd15;
    localparam [4:0] ST_ERROR         = 5'd16;

    localparam [4:0] ERR_NONE            = 5'd0;
    localparam [4:0] ERR_PROFILE         = 5'd1;
    localparam [4:0] ERR_SOURCE0_WINDOW  = 5'd2;
    localparam [4:0] ERR_SOURCE1_WINDOW  = 5'd3;
    localparam [4:0] ERR_DEST_WINDOW     = 5'd4;
    localparam [4:0] ERR_ALIAS           = 5'd5;
    localparam [4:0] ERR_ELEMENT         = 5'd6;
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
    reg operation_glu_q;
    reg [7:0] subtype_q;
    reg op_params_tail_zero_q;
    reg npu_required_q;
    reg [63:0] command_id_q;
    reg [63:0] canonical_node_id_lo_q;
    reg [63:0] canonical_node_id_hi_q;
    reg dst_shadow_private_q;
    reg windows_generation_valid_q;
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
    reg [2:0] element_opcode_q;
    reg [31:0] operator_census_q;
    reg [31:0] subtype_census_q;
    reg [31:0] profile_census_q;
    reg [31:0] coord0_q, coord1_q, coord2_q, coord3_q;
    reg [31:0] held_src0_q, held_src1_q, held_result_q;
    reg read_upper_q;
    reg [63:0] request_addr_q, request_wdata_q;
    reg [7:0] request_wstrb_q;
    reg outstanding_q, outstanding_write_q, element_resident_q;

    reg [4:0] error_code_q, drain_error_code_q;
    reg [3:0] element_error_code_q;
    reg [31:0] stall_cycles_q;
    reg [63:0] command_cycles_q, active_cycles_q;
    reg [63:0] src0_words_completed_q, src1_words_completed_q;
    reg [63:0] scalar_launches_q, scalar_terminals_q, elements_completed_q;
    reg [4:0] element_flags_or_q;
    reg [4:0] element_child_call_mask_or_q;
    reg [63:0] element_active_cycles_q;
    reg [63:0] gmem_read_beats_q, gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_beats_q, gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;

    wire start_fire_w;
    wire request_state_w, response_state_w, stall_state_w;
    wire gmem_req_fire_w, gmem_rsp_fire_w;
    wire command_timeout_hit_w, stall_timeout_hit_w;
    wire [31:0] response_word_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE) && element_req_ready_w;
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
    assign completion_operation_glu_o = completion_valid_o
                                          ? operation_glu_q : 1'b0;
    assign completion_subtype_o = completion_valid_o ? subtype_q : 8'b0;
    assign completion_profile_id_o = completion_valid_o ? profile_id_q : 8'b0;
    assign completion_kernel_id_o = !completion_valid_o ? 32'b0
                                  : operation_glu_q ? KERNEL_GLU_F32
                                                    : KERNEL_UNARY_F32;
    assign completion_operator_census_o = completion_valid_o
                                            ? operator_census_q : 32'b0;
    assign completion_subtype_census_o = completion_valid_o
                                           ? subtype_census_q : 32'b0;
    assign completion_profile_census_o = completion_valid_o
                                           ? profile_census_q : 32'b0;
    assign error_code_o = error_code_q;
    assign element_error_code_o = element_error_code_q;
    assign src0_words_completed_o = src0_words_completed_q;
    assign src1_words_completed_o = src1_words_completed_q;
    assign scalar_launches_o = scalar_launches_q;
    assign scalar_terminals_o = scalar_terminals_q;
    assign elements_completed_o = elements_completed_q;
    assign element_flags_or_o = element_flags_or_q;
    assign element_child_call_mask_or_o = element_child_call_mask_or_q;
    assign element_active_cycles_o = element_active_cycles_q;
    assign gmem_read_beats_o = gmem_read_beats_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_beats_o = gmem_write_beats_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign element_outstanding_o = element_resident_q;
    assign gmem_drain_o = !rst_i && (state_q == ST_GMEM_DRAIN);

    assign start_fire_w = start_i && ready_o;
    assign request_state_w = (state_q == ST_SRC0_REQ)
                           || (state_q == ST_SRC1_REQ)
                           || (state_q == ST_WRITE_REQ);
    assign response_state_w = (state_q == ST_SRC0_WAIT)
                            || (state_q == ST_SRC1_WAIT)
                            || (state_q == ST_WRITE_WAIT)
                            || (state_q == ST_GMEM_DRAIN);
    assign stall_state_w = request_state_w
                         || (state_q == ST_SRC0_WAIT)
                         || (state_q == ST_SRC1_WAIT)
                         || (state_q == ST_WRITE_WAIT);
    assign command_timeout_hit_w = command_cycles_q >= COMMAND_TIMEOUT_LAST;
    assign stall_timeout_hit_w = stall_cycles_q >= STALL_TIMEOUT_LAST;
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
    assign gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;
    assign response_word_w = read_upper_q ? gmem_rsp_rdata_i[63:32]
                                           : gmem_rsp_rdata_i[31:0];

    // Closed manifest profile table.  All values below are machine-derived
    // from qwen-graph-manifest-v5/dispatch.manifest.json.
    reg profile_match_w;
    reg [7:0] profile_id_w;
    reg [2:0] element_opcode_w;
    reg [31:0] operator_census_w, subtype_census_w, profile_census_w;
    reg shape_sigmoid16_w, shape_sigmoid2048_w, shape_softplus16_w;
    reg shape_silu2048_w, shape_silu6144_w, shape_exp16_w, shape_swiglu3584_w;
    reg layout_src0_w, layout_src1_w, layout_dst_w;

    always @(*) begin
        shape_sigmoid16_w = (ne0_q == 32'd1) && (ne1_q == 32'd16)
                          && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_sigmoid2048_w = (ne0_q == 32'd2048) && (ne1_q == 32'd1)
                            && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_softplus16_w = (ne0_q == 32'd16) && (ne1_q == 32'd1)
                           && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_silu2048_w = (ne0_q == 32'd128) && (ne1_q == 32'd16)
                         && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_silu6144_w = (ne0_q == 32'd6144) && (ne1_q == 32'd1)
                         && (ne2_q == 32'd1) && (ne3_q == 32'd1);
        shape_exp16_w = (ne0_q == 32'd1) && (ne1_q == 32'd1)
                      && (ne2_q == 32'd16) && (ne3_q == 32'd1);
        shape_swiglu3584_w = (ne0_q == 32'd3584) && (ne1_q == 32'd1)
                           && (ne2_q == 32'd1) && (ne3_q == 32'd1);

        layout_src0_w = 1'b0;
        layout_src1_w = 1'b0;
        layout_dst_w = 1'b0;
        if (shape_sigmoid16_w) begin
            layout_src0_w = (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd4)
                          && (src0_nb2_q == 64'd64) && (src0_nb3_q == 64'd64);
            layout_src1_w = (src1_nb0_q == 64'b0) && (src1_nb1_q == 64'b0)
                          && (src1_nb2_q == 64'b0) && (src1_nb3_q == 64'b0);
            layout_dst_w = (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd4)
                         && (dst_nb2_q == 64'd64) && (dst_nb3_q == 64'd64);
        end else if (shape_sigmoid2048_w) begin
            layout_src0_w = (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd8192)
                          && (src0_nb2_q == 64'd8192) && (src0_nb3_q == 64'd8192);
            layout_src1_w = (src1_nb0_q == 64'b0) && (src1_nb1_q == 64'b0)
                          && (src1_nb2_q == 64'b0) && (src1_nb3_q == 64'b0);
            layout_dst_w = (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd8192)
                         && (dst_nb2_q == 64'd8192) && (dst_nb3_q == 64'd8192);
        end else if (shape_softplus16_w) begin
            layout_src0_w = (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd64)
                          && (src0_nb2_q == 64'd64) && (src0_nb3_q == 64'd64);
            layout_src1_w = (src1_nb0_q == 64'b0) && (src1_nb1_q == 64'b0)
                          && (src1_nb2_q == 64'b0) && (src1_nb3_q == 64'b0);
            layout_dst_w = (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd64)
                         && (dst_nb2_q == 64'd64) && (dst_nb3_q == 64'd64);
        end else if (shape_silu2048_w) begin
            layout_src0_w = (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd512)
                          && (src0_nb2_q == 64'd8192) && (src0_nb3_q == 64'd8192);
            layout_src1_w = (src1_nb0_q == 64'b0) && (src1_nb1_q == 64'b0)
                          && (src1_nb2_q == 64'b0) && (src1_nb3_q == 64'b0);
            layout_dst_w = (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd512)
                         && (dst_nb2_q == 64'd8192) && (dst_nb3_q == 64'd8192);
        end else if (shape_silu6144_w) begin
            layout_src0_w = (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd24576)
                          && (src0_nb2_q == 64'd24576) && (src0_nb3_q == 64'd24576);
            layout_src1_w = (src1_nb0_q == 64'b0) && (src1_nb1_q == 64'b0)
                          && (src1_nb2_q == 64'b0) && (src1_nb3_q == 64'b0);
            layout_dst_w = (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd24576)
                         && (dst_nb2_q == 64'd24576) && (dst_nb3_q == 64'd24576);
        end else if (shape_exp16_w) begin
            layout_src0_w = (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd4)
                          && (src0_nb2_q == 64'd4) && (src0_nb3_q == 64'd64);
            layout_src1_w = (src1_nb0_q == 64'b0) && (src1_nb1_q == 64'b0)
                          && (src1_nb2_q == 64'b0) && (src1_nb3_q == 64'b0);
            layout_dst_w = (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd4)
                         && (dst_nb2_q == 64'd4) && (dst_nb3_q == 64'd64);
        end else if (shape_swiglu3584_w) begin
            layout_src0_w = (src0_nb0_q == 64'd4) && (src0_nb1_q == 64'd14336)
                          && (src0_nb2_q == 64'd14336) && (src0_nb3_q == 64'd14336);
            layout_src1_w = (src1_nb0_q == 64'd4) && (src1_nb1_q == 64'd14336)
                          && (src1_nb2_q == 64'd14336) && (src1_nb3_q == 64'd14336);
            layout_dst_w = (dst_nb0_q == 64'd4) && (dst_nb1_q == 64'd14336)
                         && (dst_nb2_q == 64'd14336) && (dst_nb3_q == 64'd14336);
        end

        profile_match_w = 1'b0;
        profile_id_w = PROFILE_INVALID;
        element_opcode_w = 3'b0;
        operator_census_w = operation_glu_q ? 32'd24 : 32'd96;
        subtype_census_w = 32'b0;
        profile_census_w = 32'b0;
        if (!operation_glu_q && (subtype_q == SUBTYPE_SIGMOID)
                && shape_sigmoid16_w && layout_src0_w && layout_src1_w
                && layout_dst_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_SIGMOID_16;
            element_opcode_w = 3'd0;
            subtype_census_w = 32'd24;
            profile_census_w = 32'd18;
        end else if (!operation_glu_q && (subtype_q == SUBTYPE_SIGMOID)
                && shape_sigmoid2048_w && layout_src0_w && layout_src1_w
                && layout_dst_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_SIGMOID_2048;
            element_opcode_w = 3'd0;
            subtype_census_w = 32'd24;
            profile_census_w = 32'd6;
        end else if (!operation_glu_q && (subtype_q == SUBTYPE_SOFTPLUS)
                && shape_softplus16_w && layout_src0_w && layout_src1_w
                && layout_dst_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_SOFTPLUS_16;
            element_opcode_w = 3'd1;
            subtype_census_w = 32'd18;
            profile_census_w = 32'd18;
        end else if (!operation_glu_q && (subtype_q == SUBTYPE_SILU)
                && shape_silu2048_w && layout_src0_w && layout_src1_w
                && layout_dst_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_SILU_2048;
            element_opcode_w = 3'd2;
            subtype_census_w = 32'd36;
            profile_census_w = 32'd18;
        end else if (!operation_glu_q && (subtype_q == SUBTYPE_SILU)
                && shape_silu6144_w && layout_src0_w && layout_src1_w
                && layout_dst_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_SILU_6144;
            element_opcode_w = 3'd2;
            subtype_census_w = 32'd36;
            profile_census_w = 32'd18;
        end else if (!operation_glu_q && (subtype_q == SUBTYPE_EXP)
                && shape_exp16_w && layout_src0_w && layout_src1_w
                && layout_dst_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_EXP_16;
            element_opcode_w = 3'd4;
            subtype_census_w = 32'd18;
            profile_census_w = 32'd18;
        end else if (operation_glu_q && (subtype_q == SUBTYPE_SWIGLU)
                && shape_swiglu3584_w && layout_src0_w && layout_src1_w
                && layout_dst_w) begin
            profile_match_w = 1'b1;
            profile_id_w = PROFILE_SWIGLU_3584;
            element_opcode_w = 3'd3;
            subtype_census_w = 32'd24;
            profile_census_w = 32'd24;
        end
    end

    reg [127:0] total_elements_w;
    reg [127:0] src0_last_w, src1_last_w, dst_last_w;
    reg [127:0] src0_end_w, src1_end_w, dst_end_w;
    reg [127:0] src0_window_end_w, src1_window_end_w, dst_window_end_w;
    reg [127:0] src0_phys_start_w, src0_phys_end_w;
    reg [127:0] src1_phys_start_w, src1_phys_end_w;
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
        src1_last_w = ({96'b0, (ne0_q - 32'd1)} * {64'b0, src1_nb0_q})
                    + ({96'b0, (ne1_q - 32'd1)} * {64'b0, src1_nb1_q})
                    + ({96'b0, (ne2_q - 32'd1)} * {64'b0, src1_nb2_q})
                    + ({96'b0, (ne3_q - 32'd1)} * {64'b0, src1_nb3_q});
        dst_last_w = ({96'b0, (ne0_q - 32'd1)} * {64'b0, dst_nb0_q})
                   + ({96'b0, (ne1_q - 32'd1)} * {64'b0, dst_nb1_q})
                   + ({96'b0, (ne2_q - 32'd1)} * {64'b0, dst_nb2_q})
                   + ({96'b0, (ne3_q - 32'd1)} * {64'b0, dst_nb3_q});
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
        align_tmp_w = src0_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        src0_phys_end_w = align_tmp_w + 128'd8;
        src1_phys_start_w = {64'b0, src1_base_q};
        src1_phys_start_w[2:0] = 3'b000;
        align_tmp_w = src1_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        src1_phys_end_w = align_tmp_w + 128'd8;
        dst_phys_start_w = {64'b0, dst_base_q};
        dst_phys_start_w[2:0] = 3'b000;
        align_tmp_w = dst_end_w - 128'd1;
        align_tmp_w[2:0] = 3'b000;
        dst_phys_end_w = align_tmp_w + 128'd8;

        descriptor_ok_w = profile_match_w && op_params_tail_zero_q
                       && dst_shadow_private_q && windows_generation_valid_q
                       && ((canonical_node_id_lo_q != 64'b0)
                           || (canonical_node_id_hi_q != 64'b0))
                       && (total_elements_w[127:64] == 64'b0)
                       && (total_elements_w != 128'b0);
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
        if (operation_glu_q) begin
            src1_window_ok_w = (src1_window_end_w[127:64] == 64'b0)
                            && (src1_end_w[127:64] == 64'b0)
                            && (src1_phys_start_w[127:64] == 64'b0)
                            && (src1_phys_end_w[127:64] == 64'b0)
                            && (src1_base_q[1:0] == 2'b00)
                            && (src1_window_base_q[2:0] == 3'b000)
                            && (src1_window_bytes_q[2:0] == 3'b000)
                            && src1_window_read_q && !src1_window_write_q
                            && (src1_window_bytes_q != 64'b0)
                            && (src1_phys_start_w
                                >= {64'b0, src1_window_base_q})
                            && (src1_phys_end_w <= src1_window_end_w);
        end else begin
            src1_window_ok_w = (src1_window_end_w[127:64] == 64'b0)
                            && (src1_base_q[1:0] == 2'b00)
                            && (src1_window_base_q[2:0] == 3'b000)
                            && (src1_window_bytes_q == 64'b0)
                            && src1_window_read_q && !src1_window_write_q;
        end
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
        alias_ok_w = ((dst_phys_end_w <= src0_phys_start_w)
                      || (dst_phys_start_w >= src0_phys_end_w));
        if (operation_glu_q)
            alias_ok_w = alias_ok_w
                      && ((dst_phys_end_w <= src1_phys_start_w)
                          || (dst_phys_start_w >= src1_phys_end_w));

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
        runtime_ok_w = (coord0_q < ne0_q) && (coord1_q < ne1_q)
                    && (coord2_q < ne2_q) && (coord3_q < ne3_q);
        case (state_q)
            ST_SRC0_PREP: begin
                runtime_addr_w = {64'b0, src0_base_q}
                    + ({96'b0, coord0_q} * {64'b0, src0_nb0_q})
                    + ({96'b0, coord1_q} * {64'b0, src0_nb1_q})
                    + ({96'b0, coord2_q} * {64'b0, src0_nb2_q})
                    + ({96'b0, coord3_q} * {64'b0, src0_nb3_q});
                runtime_window_start_w = {64'b0, src0_window_base_q};
                runtime_window_end_w = src0_window_end_w;
            end
            ST_SRC1_PREP: begin
                runtime_addr_w = {64'b0, src1_base_q}
                    + ({96'b0, coord0_q} * {64'b0, src1_nb0_q})
                    + ({96'b0, coord1_q} * {64'b0, src1_nb1_q})
                    + ({96'b0, coord2_q} * {64'b0, src1_nb2_q})
                    + ({96'b0, coord3_q} * {64'b0, src1_nb3_q});
                runtime_window_start_w = {64'b0, src1_window_base_q};
                runtime_window_end_w = src1_window_end_w;
                runtime_ok_w = runtime_ok_w && operation_glu_q;
            end
            ST_WRITE_PREP: begin
                runtime_addr_w = {64'b0, dst_base_q}
                    + ({96'b0, coord0_q} * {64'b0, dst_nb0_q})
                    + ({96'b0, coord1_q} * {64'b0, dst_nb1_q})
                    + ({96'b0, coord2_q} * {64'b0, dst_nb2_q})
                    + ({96'b0, coord3_q} * {64'b0, dst_nb3_q});
                runtime_window_start_w = {64'b0, dst_window_base_q};
                runtime_window_end_w = dst_window_end_w;
            end
            default: runtime_ok_w = 1'b0;
        endcase
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

    wire element_rst_w = rst_i || (state_q == ST_ELEMENT_ABORT);
    wire element_req_valid_w = (state_q == ST_ELEMENT_REQ)
                             && !command_timeout_hit_w;
    wire element_req_ready_w;
    wire element_req_fire_w = element_req_valid_w && element_req_ready_w;
    wire element_rsp_valid_w;
    wire element_rsp_ready_w = (state_q == ST_ELEMENT_WAIT);
    wire element_rsp_fire_w = element_rsp_valid_w && element_rsp_ready_w;
    wire [31:0] element_result_w;
    wire [4:0] element_flags_w, element_child_mask_w;
    wire element_error_w;
    wire [3:0] element_error_code_w;
    wire [31:0] element_cycles_w;

    TensorNpuUnaryGluElement u_element (
        .clk_i(clk_i), .rst_i(element_rst_w),
        .req_valid_i(element_req_valid_w), .req_ready_o(element_req_ready_w),
        .opcode_i(element_opcode_q), .src0_bits_i(held_src0_q),
        .src1_bits_i(held_src1_q), .rsp_valid_o(element_rsp_valid_w),
        .rsp_ready_i(element_rsp_ready_w), .result_bits_o(element_result_w),
        .flags_o(element_flags_w), .error_o(element_error_w),
        .error_code_o(element_error_code_w),
        .child_call_mask_o(element_child_mask_w),
        .active_cycles_o(element_cycles_w)
    );

    wire progress_w = gmem_req_fire_w || gmem_rsp_fire_w
                    || element_req_fire_w || element_rsp_fire_w;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            operation_glu_q <= 1'b0; subtype_q <= 8'b0;
            op_params_tail_zero_q <= 1'b0; npu_required_q <= 1'b0;
            command_id_q <= 64'b0; canonical_node_id_lo_q <= 64'b0;
            canonical_node_id_hi_q <= 64'b0; dst_shadow_private_q <= 1'b0;
            windows_generation_valid_q <= 1'b0;
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
            profile_id_q <= PROFILE_INVALID; element_opcode_q <= 0;
            operator_census_q <= 0; subtype_census_q <= 0; profile_census_q <= 0;
            coord0_q <= 0; coord1_q <= 0; coord2_q <= 0; coord3_q <= 0;
            held_src0_q <= 0; held_src1_q <= 0; held_result_q <= 0;
            read_upper_q <= 0; request_addr_q <= 0; request_wdata_q <= 0;
            request_wstrb_q <= 0; outstanding_q <= 0;
            outstanding_write_q <= 0; element_resident_q <= 0;
            error_code_q <= ERR_NONE; drain_error_code_q <= ERR_NONE;
            element_error_code_q <= 0; stall_cycles_q <= 0;
            command_cycles_q <= 0; active_cycles_q <= 0;
            src0_words_completed_q <= 0; src1_words_completed_q <= 0;
            scalar_launches_q <= 0; scalar_terminals_q <= 0;
            elements_completed_q <= 0; element_flags_or_q <= 0;
            element_child_call_mask_or_q <= 0;
            element_active_cycles_q <= 0; gmem_read_beats_q <= 0;
            gmem_read_responses_q <= 0; read_payload_bytes_q <= 0;
            gmem_write_beats_q <= 0; gmem_write_responses_q <= 0;
            write_payload_bytes_q <= 0;
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
            end else stall_cycles_q <= 0;

            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR) && (state_q != ST_GMEM_DRAIN)
                    && (state_q != ST_ELEMENT_ABORT)
                    && command_timeout_hit_w && !progress_w) begin
                if (outstanding_q) begin
                    drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_GMEM_DRAIN;
                end else if (element_resident_q) begin
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_ELEMENT_ABORT;
                end else begin
                    error_code_q <= ERR_COMMAND_TIMEOUT;
                    state_q <= ST_ERROR;
                end
            end else if (stall_state_w && stall_timeout_hit_w
                    && !(gmem_req_fire_w || gmem_rsp_fire_w)) begin
                if (outstanding_q) begin
                    drain_error_code_q <= ERR_STALL_TIMEOUT;
                    state_q <= ST_GMEM_DRAIN;
                end else begin
                    error_code_q <= ERR_STALL_TIMEOUT;
                    state_q <= ST_ERROR;
                end
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        outstanding_q <= 0; outstanding_write_q <= 0;
                        element_resident_q <= 0;
                        if (start_fire_w) begin
                            operation_glu_q <= operation_glu_i;
                            subtype_q <= subtype_i;
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
                            profile_id_q <= PROFILE_INVALID; element_opcode_q <= 0;
                            operator_census_q <= 0; subtype_census_q <= 0;
                            profile_census_q <= 0;
                            coord0_q <= 0; coord1_q <= 0; coord2_q <= 0; coord3_q <= 0;
                            held_src0_q <= 0; held_src1_q <= 0; held_result_q <= 0;
                            error_code_q <= ERR_NONE; drain_error_code_q <= ERR_NONE;
                            element_error_code_q <= 0; stall_cycles_q <= 0;
                            command_cycles_q <= 0; active_cycles_q <= 0;
                            src0_words_completed_q <= 0; src1_words_completed_q <= 0;
                            scalar_launches_q <= 0; scalar_terminals_q <= 0;
                            elements_completed_q <= 0; element_flags_or_q <= 0;
                            element_child_call_mask_or_q <= 0;
                            element_active_cycles_q <= 0; gmem_read_beats_q <= 0;
                            gmem_read_responses_q <= 0; read_payload_bytes_q <= 0;
                            gmem_write_beats_q <= 0; gmem_write_responses_q <= 0;
                            write_payload_bytes_q <= 0;
                            state_q <= ST_PREFLIGHT;
                        end
                    end
                    ST_PREFLIGHT: begin
                        profile_id_q <= profile_id_w;
                        element_opcode_q <= element_opcode_w;
                        operator_census_q <= operator_census_w;
                        subtype_census_q <= subtype_census_w;
                        profile_census_q <= profile_census_w;
                        if (preflight_error_w != ERR_NONE) begin
                            error_code_q <= preflight_error_w;
                            state_q <= ST_ERROR;
                        end else begin
                            state_q <= ST_SRC0_PREP;
                        end
                    end
                    ST_SRC0_PREP: begin
                        if (!runtime_ok_w) begin error_code_q <= ERR_INTERNAL_STATE; state_q <= ST_ERROR; end
                        else begin request_addr_q <= runtime_phys_start_w[63:0];
                            read_upper_q <= runtime_addr_w[2]; state_q <= ST_SRC0_REQ; end
                    end
                    ST_SRC0_REQ: if (gmem_req_fire_w) begin
                        outstanding_q <= 1; outstanding_write_q <= 0;
                        gmem_read_beats_q <= gmem_read_beats_q + 1;
                        state_q <= ST_SRC0_WAIT;
                    end
                    ST_SRC0_WAIT: if (gmem_rsp_fire_w) begin
                        outstanding_q <= 0; gmem_read_responses_q <= gmem_read_responses_q + 1;
                        if (gmem_rsp_error_i) begin error_code_q <= ERR_GMEM_RESPONSE; state_q <= ST_ERROR; end
                        else begin held_src0_q <= response_word_w;
                            src0_words_completed_q <= src0_words_completed_q + 1;
                            read_payload_bytes_q <= read_payload_bytes_q + 4;
                            state_q <= operation_glu_q ? ST_SRC1_PREP : ST_ELEMENT_REQ; end
                    end
                    ST_SRC1_PREP: begin
                        if (!runtime_ok_w) begin error_code_q <= ERR_INTERNAL_STATE; state_q <= ST_ERROR; end
                        else begin request_addr_q <= runtime_phys_start_w[63:0];
                            read_upper_q <= runtime_addr_w[2]; state_q <= ST_SRC1_REQ; end
                    end
                    ST_SRC1_REQ: if (gmem_req_fire_w) begin
                        outstanding_q <= 1; outstanding_write_q <= 0;
                        gmem_read_beats_q <= gmem_read_beats_q + 1;
                        state_q <= ST_SRC1_WAIT;
                    end
                    ST_SRC1_WAIT: if (gmem_rsp_fire_w) begin
                        outstanding_q <= 0; gmem_read_responses_q <= gmem_read_responses_q + 1;
                        if (gmem_rsp_error_i) begin error_code_q <= ERR_GMEM_RESPONSE; state_q <= ST_ERROR; end
                        else begin held_src1_q <= response_word_w;
                            src1_words_completed_q <= src1_words_completed_q + 1;
                            read_payload_bytes_q <= read_payload_bytes_q + 4;
                            state_q <= ST_ELEMENT_REQ; end
                    end
                    ST_ELEMENT_REQ: if (element_req_fire_w) begin
                        element_resident_q <= 1; scalar_launches_q <= scalar_launches_q + 1;
                        state_q <= ST_ELEMENT_WAIT;
                    end
                    ST_ELEMENT_WAIT: if (element_rsp_fire_w) begin
                        element_resident_q <= 0; scalar_terminals_q <= scalar_terminals_q + 1;
                        element_active_cycles_q <= element_active_cycles_q
                                                   + {32'b0, element_cycles_w};
                        if (element_error_w) begin
                            element_error_code_q <= element_error_code_w;
                            error_code_q <= ERR_ELEMENT; state_q <= ST_ERROR;
                        end else begin
                            held_result_q <= element_result_w;
                            element_flags_or_q <= element_flags_or_q | element_flags_w;
                            element_child_call_mask_or_q <=
                                element_child_call_mask_or_q
                                | element_child_mask_w;
                            state_q <= ST_WRITE_PREP;
                        end
                    end
                    ST_WRITE_PREP: begin
                        if (!runtime_ok_w) begin error_code_q <= ERR_INTERNAL_STATE; state_q <= ST_ERROR; end
                        else begin request_addr_q <= runtime_phys_start_w[63:0];
                            request_wdata_q <= runtime_addr_w[2]
                                ? {held_result_q, 32'b0} : {32'b0, held_result_q};
                            request_wstrb_q <= runtime_addr_w[2] ? 8'hf0 : 8'h0f;
                            state_q <= ST_WRITE_REQ; end
                    end
                    ST_WRITE_REQ: if (gmem_req_fire_w) begin
                        outstanding_q <= 1; outstanding_write_q <= 1;
                        gmem_write_beats_q <= gmem_write_beats_q + 1;
                        state_q <= ST_WRITE_WAIT;
                    end
                    ST_WRITE_WAIT: if (gmem_rsp_fire_w) begin
                        outstanding_q <= 0; gmem_write_responses_q <= gmem_write_responses_q + 1;
                        if (gmem_rsp_error_i) begin error_code_q <= ERR_GMEM_RESPONSE; state_q <= ST_ERROR; end
                        else begin
                            elements_completed_q <= elements_completed_q + 1;
                            write_payload_bytes_q <= write_payload_bytes_q + 4;
                            if (coord0_q != ne0_q - 1) begin coord0_q <= coord0_q + 1; state_q <= ST_SRC0_PREP; end
                            else if (coord1_q != ne1_q - 1) begin coord0_q <= 0; coord1_q <= coord1_q + 1; state_q <= ST_SRC0_PREP; end
                            else if (coord2_q != ne2_q - 1) begin coord0_q <= 0; coord1_q <= 0; coord2_q <= coord2_q + 1; state_q <= ST_SRC0_PREP; end
                            else if (coord3_q != ne3_q - 1) begin coord0_q <= 0; coord1_q <= 0; coord2_q <= 0; coord3_q <= coord3_q + 1; state_q <= ST_SRC0_PREP; end
                            else state_q <= ST_DONE;
                        end
                    end
                    ST_GMEM_DRAIN: if (gmem_rsp_fire_w) begin
                        outstanding_q <= 0;
                        if (outstanding_write_q) begin
                            gmem_write_responses_q <= gmem_write_responses_q + 1;
                            if (!gmem_rsp_error_i) begin
                                elements_completed_q <= elements_completed_q + 1;
                                write_payload_bytes_q <= write_payload_bytes_q + 4;
                            end
                        end else gmem_read_responses_q <= gmem_read_responses_q + 1;
                        error_code_q <= drain_error_code_q; state_q <= ST_ERROR;
                    end
                    ST_ELEMENT_ABORT: begin element_resident_q <= 0; state_q <= ST_ERROR; end
                    ST_DONE: if (outstanding_q || element_resident_q) begin
                        error_code_q <= ERR_INTERNAL_STATE;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN : ST_ELEMENT_ABORT;
                    end else state_q <= ST_IDLE;
                    ST_ERROR: if (outstanding_q) begin
                        drain_error_code_q <= ERR_INTERNAL_STATE; state_q <= ST_GMEM_DRAIN;
                    end else if (element_resident_q) begin
                        error_code_q <= ERR_INTERNAL_STATE; state_q <= ST_ELEMENT_ABORT;
                    end else state_q <= ST_IDLE;
                    default: begin error_code_q <= ERR_INTERNAL_STATE;
                        state_q <= outstanding_q ? ST_GMEM_DRAIN
                                                : element_resident_q ? ST_ELEMENT_ABORT
                                                                     : ST_ERROR; end
                endcase
            end
        end
    end

endmodule

`default_nettype wire
