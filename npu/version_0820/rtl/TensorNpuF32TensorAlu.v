`timescale 1ns/1ps
`default_nettype none

// TensorNpuF32TensorAlu — serial F32 ADD/MUL/SUB/SCALE tensor engine。
//
// 结构映射到 docs/F32_TENSOR_ALU_RTL_CONTRACT.md：
//   * resident descriptor 在 IDLE start handshake 一次采样；
//   * 128-bit preflight 在首个 GMEM request 前闭合全部 descriptor；
//   * 单 GMEM owner 与单 TensorNpuFp32AddMul owner 逐元素互斥复用；
//   * SUB 只翻转 rhs sign 后走 ADD，SCALE 每元素只走一次 MUL；
//   * accepted GMEM/child timeout 进入唯一 owner-tagged DRAIN；
//   * arithmetic flags 只由成功 matching child response sticky-OR；
//   * destination 只写 contiguous transaction-private shadow。
//
// 候选最长组合路径是 preflight 的 4D span/bounds/overlap 比较，以及运行时
// modulo coordinate -> stride 乘加；本轮不作综合、STA 或 PPA 声明。
module TensorNpuF32TensorAlu #(
    parameter integer STALL_TIMEOUT_CYCLES   = 512,
    parameter integer CHILD_TIMEOUT_CYCLES   = 512,
    parameter integer COMMAND_TIMEOUT_CYCLES = 1048576,
    parameter integer MAX_ELEMENTS           = 262144
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        start_i,
    output wire        ready_o,
    output wire        busy_o,
    input  wire [2:0]  opcode_i,
    input  wire [1:0]  dtype_i,
    input  wire [3:0]  profile_i,
    input  wire [31:0] reserved_i,
    input  wire [63:0] op_params_i,

    input  wire [63:0] gmem_floor_i,
    input  wire [63:0] gmem_limit_i,

    input  wire [63:0] src0_region_base_i,
    input  wire [63:0] src0_region_size_i,
    input  wire [63:0] src0_view_off_i,
    input  wire [31:0] src0_ne0_i,
    input  wire [31:0] src0_ne1_i,
    input  wire [31:0] src0_ne2_i,
    input  wire [31:0] src0_ne3_i,
    input  wire [63:0] src0_nb0_i,
    input  wire [63:0] src0_nb1_i,
    input  wire [63:0] src0_nb2_i,
    input  wire [63:0] src0_nb3_i,

    input  wire [63:0] src1_region_base_i,
    input  wire [63:0] src1_region_size_i,
    input  wire [63:0] src1_view_off_i,
    input  wire [31:0] src1_ne0_i,
    input  wire [31:0] src1_ne1_i,
    input  wire [31:0] src1_ne2_i,
    input  wire [31:0] src1_ne3_i,
    input  wire [63:0] src1_nb0_i,
    input  wire [63:0] src1_nb1_i,
    input  wire [63:0] src1_nb2_i,
    input  wire [63:0] src1_nb3_i,

    input  wire [63:0] dst_region_base_i,
    input  wire [63:0] dst_region_size_i,
    input  wire [63:0] dst_view_off_i,
    input  wire [31:0] dst_ne0_i,
    input  wire [31:0] dst_ne1_i,
    input  wire [31:0] dst_ne2_i,
    input  wire [31:0] dst_ne3_i,
    input  wire [63:0] dst_nb0_i,
    input  wire [63:0] dst_nb1_i,
    input  wire [63:0] dst_nb2_i,
    input  wire [63:0] dst_nb3_i,

    output wire        gmem_req_valid_o,
    input  wire        gmem_req_ready_i,
    output wire        gmem_req_write_o,
    output wire [63:0] gmem_req_addr_o,
    output wire [63:0] gmem_req_wdata_o,
    output wire [7:0]  gmem_req_wstrb_o,
    input  wire        gmem_rsp_valid_i,
    output wire        gmem_rsp_ready_o,
    input  wire [63:0] gmem_rsp_rdata_i,
    input  wire        gmem_rsp_error_i,

    output wire        done_o,
    output wire        error_o,
    output wire [4:0]  error_code_o,
    output wire [4:0]  arithmetic_flags_o,
    output wire [63:0] elements_done_o,
    output wire [63:0] gmem_read_beats_o,
    output wire [63:0] gmem_pair_reuse_elements_o,
    output wire [63:0] gmem_write_beats_o,
    output wire [63:0] writes_accepted_o,
    output wire [63:0] child_requests_o,
    output wire [63:0] child_responses_o,
    output wire [63:0] active_cycles_o
);

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 1) ? 32'd0
                                    : (STALL_TIMEOUT_CYCLES - 1);
    localparam [31:0] CHILD_TIMEOUT_LAST =
        (CHILD_TIMEOUT_CYCLES <= 1) ? 32'd0
                                    : (CHILD_TIMEOUT_CYCLES - 1);
    localparam [31:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 1) ? 32'd0
                                      : (COMMAND_TIMEOUT_CYCLES - 1);
    localparam [127:0] MAX_ELEMENTS_LIMIT = 128'd262144;

    localparam [2:0] OP_ADD   = 3'd0;
    localparam [2:0] OP_MUL   = 3'd1;
    localparam [2:0] OP_SUB   = 3'd2;
    localparam [2:0] OP_SCALE = 3'd3;

    localparam [4:0] ST_IDLE         = 5'd0;
    localparam [4:0] ST_PREFLIGHT    = 5'd1;
    localparam [4:0] ST_ELEMENT_PREP = 5'd2;
    localparam [4:0] ST_SRC0_REQ     = 5'd3;
    localparam [4:0] ST_SRC0_WAIT    = 5'd4;
    localparam [4:0] ST_SRC1_REQ     = 5'd5;
    localparam [4:0] ST_SRC1_WAIT    = 5'd6;
    localparam [4:0] ST_CHILD_REQ    = 5'd7;
    localparam [4:0] ST_CHILD_WAIT   = 5'd8;
    localparam [4:0] ST_WRITE_REQ    = 5'd9;
    localparam [4:0] ST_WRITE_WAIT   = 5'd10;
    localparam [4:0] ST_DRAIN        = 5'd11;
    localparam [4:0] ST_DONE         = 5'd12;
    localparam [4:0] ST_ERROR        = 5'd13;

    localparam [1:0] DRAIN_NONE  = 2'd0;
    localparam [1:0] DRAIN_GMEM  = 2'd1;
    localparam [1:0] DRAIN_CHILD = 2'd2;

    localparam [4:0] ERR_NONE             = 5'd0;
    localparam [4:0] ERR_HEADER_PROFILE   = 5'd1;
    localparam [4:0] ERR_SHAPE_BROADCAST  = 5'd2;
    localparam [4:0] ERR_STRIDE_ALIGNMENT = 5'd3;
    localparam [4:0] ERR_SOURCE_BOUNDS    = 5'd4;
    localparam [4:0] ERR_DEST_BOUNDS      = 5'd5;
    localparam [4:0] ERR_OVERLAP          = 5'd6;
    localparam [4:0] ERR_GMEM_RESPONSE    = 5'd7;
    localparam [4:0] ERR_STALL_TIMEOUT    = 5'd8;
    localparam [4:0] ERR_COMMAND_TIMEOUT  = 5'd9;
    localparam [4:0] ERR_CHILD_PROTOCOL   = 5'd10;
    localparam [4:0] ERR_CHILD_TIMEOUT    = 5'd11;
    localparam [4:0] ERR_INTERNAL_STATE   = 5'd12;

    reg [4:0] state_q;

    // Resident descriptor：仅在 start_i && ready_o 时更新。
    reg [2:0]  opcode_q;
    reg [1:0]  dtype_q;
    reg [3:0]  profile_q;
    reg [31:0] reserved_q;
    reg [63:0] op_params_q;
    reg [63:0] gmem_floor_q;
    reg [63:0] gmem_limit_q;
    reg [63:0] src0_region_base_q;
    reg [63:0] src0_region_size_q;
    reg [63:0] src0_view_off_q;
    reg [31:0] src0_ne0_q;
    reg [31:0] src0_ne1_q;
    reg [31:0] src0_ne2_q;
    reg [31:0] src0_ne3_q;
    reg [63:0] src0_nb0_q;
    reg [63:0] src0_nb1_q;
    reg [63:0] src0_nb2_q;
    reg [63:0] src0_nb3_q;
    reg [63:0] src1_region_base_q;
    reg [63:0] src1_region_size_q;
    reg [63:0] src1_view_off_q;
    reg [31:0] src1_ne0_q;
    reg [31:0] src1_ne1_q;
    reg [31:0] src1_ne2_q;
    reg [31:0] src1_ne3_q;
    reg [63:0] src1_nb0_q;
    reg [63:0] src1_nb1_q;
    reg [63:0] src1_nb2_q;
    reg [63:0] src1_nb3_q;
    reg [63:0] dst_region_base_q;
    reg [63:0] dst_region_size_q;
    reg [63:0] dst_view_off_q;
    reg [31:0] dst_ne0_q;
    reg [31:0] dst_ne1_q;
    reg [31:0] dst_ne2_q;
    reg [31:0] dst_ne3_q;
    reg [63:0] dst_nb0_q;
    reg [63:0] dst_nb1_q;
    reg [63:0] dst_nb2_q;
    reg [63:0] dst_nb3_q;

    reg [63:0] total_elements_q;
    reg [63:0] flat_index_q;
    reg [31:0] coord_i0_q;
    reg [31:0] coord_i1_q;
    reg [31:0] coord_i2_q;
    reg [31:0] coord_i3_q;

    // 显式共享 GMEM payload register；REQ state 内保持。
    reg [63:0] gmem_req_addr_q;
    reg [63:0] gmem_req_wdata_q;
    reg [7:0]  gmem_req_wstrb_q;
    reg        gmem_read_upper_q;
    // Conservative one-entry beat reuse per source.  Tags are the exact
    // aligned byte address without the known-zero low three bits; payloads
    // are filled only by clean matching source responses.
    reg        src0_beat_valid_q;
    reg [60:0] src0_beat_tag_q;
    reg [63:0] src0_beat_data_q;
    reg        src1_beat_valid_q;
    reg [60:0] src1_beat_tag_q;
    reg [63:0] src1_beat_data_q;
    // Source-1 addresses are word aligned after preflight.  Retain only the
    // word address so no resident register carries known-zero low bits.
    reg [61:0] current_src1_word_q;
    reg [63:0] current_dst_addr_q;
    reg        gmem_outstanding_q;

    // 唯一 child operand/result owner。
    reg [31:0] lhs_bits_q;
    reg [31:0] rhs_bits_q;
    // A clean CHILD_WAIT response may prepare the exact dual-cache-hit
    // successor in the existing operand registers.  This bit is the only
    // authority for WRITE_WAIT -> child elastic direct; the child payload
    // therefore never depends on the live 4D address/tag/lane network.
    reg        pair_reuse_prepared_q;
    reg        child_outstanding_q;

    reg [1:0]  drain_owner_q;
    reg [4:0]  drain_error_code_q;
    reg [4:0]  error_code_q;
    reg [4:0]  arithmetic_flags_q;
    reg [31:0] stall_cycles_q;
    reg [31:0] command_cycles_q;
    reg [63:0] elements_done_q;
    reg [63:0] gmem_read_beats_q;
    reg [63:0] gmem_pair_reuse_elements_q;
    reg [63:0] gmem_write_beats_q;
    reg [63:0] writes_accepted_q;
    reg [63:0] child_requests_q;
    reg [63:0] child_responses_q;
    reg [63:0] active_cycles_q;

    // The first element always has zero coordinates.  Capture its three
    // base+view addresses on the command-admission edge so a successful
    // preflight can enter SRC0_REQ directly without an ELEMENT_PREP bubble.
    // These payloads remain speculative and externally invisible until the
    // registered descriptor passes the existing 128-bit preflight.
    wire [61:0] start_src0_word_w;
    wire [61:0] start_src1_word_w;
    wire [63:0] start_dst_addr_w;

    assign start_src0_word_w = 62'((src0_region_base_i
                                    + src0_view_off_i) >> 2);
    assign start_src1_word_w = 62'((src1_region_base_i
                                    + src1_view_off_i) >> 2);
    assign start_dst_addr_w  = dst_region_base_i + dst_view_off_i;

    wire start_fire_w;
    wire gmem_request_state_w;
    wire gmem_wait_state_w;
    wire child_request_state_w;
    wire child_wait_state_w;
    wire command_timeout_hit_w;
    wire phase_timeout_hit_w;
    wire gmem_req_fire_w;
    wire gmem_rsp_fire_w;
    wire child_req_fire_w;
    wire child_rsp_fire_w;
    wire child_rst_w;
    wire child_req_valid_w;
    wire child_req_ready_w;
    wire child_op_mul_w;
    wire src1_child_direct_offer_w;
    wire src1_child_direct_fire_w;
    wire pair_reuse_child_direct_offer_w;
    wire pair_reuse_child_direct_fire_w;
    wire [31:0] child_rhs_raw_w;
    wire [31:0] child_rhs_bits_w;
    wire child_rsp_valid_w;
    wire child_rsp_ready_w;
    wire [31:0] child_result_bits_w;
    wire [4:0] child_flags_w;
    wire child_write_direct_offer_w;
    wire child_write_direct_fire_w;
    wire [63:0] child_write_addr_w;
    wire [63:0] child_write_data_w;
    wire [7:0] child_write_strb_w;
    wire child_write_payload_valid_w;
    wire registered_write_payload_valid_w;
    wire [31:0] selected_gmem_word_w;

    assign ready_o = !rst_i && (state_q == ST_IDLE);
    assign busy_o  = !rst_i && (state_q != ST_IDLE);
    assign done_o  = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign start_fire_w = start_i && ready_o;

    assign gmem_request_state_w = (state_q == ST_SRC0_REQ)
                                || (state_q == ST_SRC1_REQ)
                                || (state_q == ST_WRITE_REQ);
    assign gmem_wait_state_w = (state_q == ST_SRC0_WAIT)
                             || (state_q == ST_SRC1_WAIT)
                             || (state_q == ST_WRITE_WAIT)
                             || ((state_q == ST_DRAIN)
                                 && (drain_owner_q == DRAIN_GMEM));
    assign child_request_state_w = (state_q == ST_CHILD_REQ);
    assign child_wait_state_w = (state_q == ST_CHILD_WAIT)
                              || ((state_q == ST_DRAIN)
                                  && (drain_owner_q == DRAIN_CHILD));
    assign command_timeout_hit_w =
        (command_cycles_q >= COMMAND_TIMEOUT_LAST);
    assign phase_timeout_hit_w =
        ((state_q == ST_CHILD_REQ) || (state_q == ST_CHILD_WAIT))
        ? (stall_cycles_q >= CHILD_TIMEOUT_LAST)
        : (stall_cycles_q >= STALL_TIMEOUT_LAST);

    // Owner/protocol fault 还会组合撤销 REQ valid，避免 fault 同拍产生新 owner。
    wire gmem_owner_expected_w;
    wire child_owner_expected_w;
    wire protocol_fault_active_w;
    wire gmem_response_owner_fault_w;
    wire child_response_owner_fault_w;
    wire outstanding_state_fault_w;
    wire protocol_fault_w;
    wire [4:0] protocol_error_code_w;
    wire gmem_drain_timeout_cause_w;

    assign protocol_fault_active_w = !rst_i
                                   && (state_q != ST_IDLE)
                                   && (state_q != ST_DRAIN)
                                   && (state_q != ST_DONE)
                                   && (state_q != ST_ERROR);
    assign gmem_owner_expected_w = gmem_outstanding_q
                                 && ((state_q == ST_SRC0_WAIT)
                                     || (state_q == ST_SRC1_WAIT)
                                     || (state_q == ST_WRITE_WAIT));
    assign child_owner_expected_w = child_outstanding_q
                                  && (state_q == ST_CHILD_WAIT);
    assign gmem_response_owner_fault_w = protocol_fault_active_w
                                       && gmem_rsp_valid_i
                                       && !gmem_owner_expected_w;
    assign child_response_owner_fault_w = protocol_fault_active_w
                                        && child_rsp_valid_w
                                        && !child_owner_expected_w;
    assign outstanding_state_fault_w = protocol_fault_active_w
                                     && ((gmem_outstanding_q
                                          && !gmem_owner_expected_w)
                                         || (child_outstanding_q
                                             && !child_owner_expected_w)
                                         || (gmem_outstanding_q
                                             && child_outstanding_q));
    assign protocol_fault_w = gmem_response_owner_fault_w
                            || child_response_owner_fault_w
                            || outstanding_state_fault_w;
    assign protocol_error_code_w = child_response_owner_fault_w
                                 ? ERR_CHILD_PROTOCOL
                                 : ERR_INTERNAL_STATE;
    // A late GMEM error refines only a watchdog terminal.  Protocol/internal
    // causes were already selected at a higher-priority edge and must remain
    // the final observable error after their owned credit is drained.
    assign gmem_drain_timeout_cause_w =
               (drain_error_code_q == ERR_COMMAND_TIMEOUT)
            || (drain_error_code_q == ERR_STALL_TIMEOUT);

    // 唯一 child-result -> shadow-write payload 网。direct offer 直接使用，
    // ready-low fallback 同沿采样到既有 q；禁止复制 result shift。
    assign child_write_addr_w = {
        current_dst_addr_q[63:3], 3'b000
    };
    assign child_write_data_w =
        ({32'b0, child_result_bits_w}
         << {current_dst_addr_q[2:0], 3'b000});
    assign child_write_strb_w = 8'h0f << current_dst_addr_q[2:0];
    assign child_write_payload_valid_w =
           (current_dst_addr_q[1:0] == 2'b00)
        && (child_write_addr_w[2:0] == 3'b000)
        && ((child_write_strb_w == 8'h0f)
            || (child_write_strb_w == 8'hf0));
    assign registered_write_payload_valid_w =
           (gmem_req_addr_q[2:0] == 3'b000)
        && ((gmem_req_wstrb_q == 8'h0f)
            || (gmem_req_wstrb_q == 8'hf0));

    // Direct valid/payload 不依赖 gmem_req_ready_i。protocol/watchdog gate
    // 高于 normal child response，因而 fault/deadline 同拍绝不创建 GMEM owner。
    assign child_write_direct_offer_w = !rst_i
                                      && (state_q == ST_CHILD_WAIT)
                                      && child_rsp_fire_w
                                      && !protocol_fault_w
                                      && !command_timeout_hit_w
                                      && !phase_timeout_hit_w
                                      && child_write_payload_valid_w;
    assign gmem_req_valid_o = (!rst_i && gmem_request_state_w
                               && !protocol_fault_w
                               && !command_timeout_hit_w
                               && !phase_timeout_hit_w
                               && ((state_q != ST_WRITE_REQ)
                                   || registered_write_payload_valid_w))
                            || child_write_direct_offer_w;
    assign gmem_req_write_o = (state_q == ST_WRITE_REQ)
                            || child_write_direct_offer_w;
    assign gmem_req_addr_o  = child_write_direct_offer_w
                            ? child_write_addr_w : gmem_req_addr_q;
    assign gmem_req_wdata_o = child_write_direct_offer_w
                            ? child_write_data_w
                            : ((state_q == ST_WRITE_REQ)
                               ? gmem_req_wdata_q : 64'b0);
    assign gmem_req_wstrb_o = child_write_direct_offer_w
                            ? child_write_strb_w
                            : ((state_q == ST_WRITE_REQ)
                               ? gmem_req_wstrb_q : 8'b0);
    // Global protocol fault wins before the per-state response handlers.  Do
    // not consume the otherwise-owned response on that fault edge: the FSM
    // first records the matching DRAIN owner, then returns the held credit in
    // ST_DRAIN on the following edge.  This prevents Q owner state from
    // outliving a response that the endpoint has already consumed.
    assign gmem_rsp_ready_o = !rst_i && !protocol_fault_w
                            && gmem_wait_state_w && gmem_outstanding_q;
    assign gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    assign child_write_direct_fire_w = child_write_direct_offer_w
                                     && gmem_req_ready_i;
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;

    assign error_code_o         = error_code_q;
    assign arithmetic_flags_o   = arithmetic_flags_q;
    assign elements_done_o      = elements_done_q;
    assign gmem_read_beats_o    = gmem_read_beats_q;
    assign gmem_pair_reuse_elements_o = gmem_pair_reuse_elements_q;
    assign gmem_write_beats_o   = gmem_write_beats_q;
    assign writes_accepted_o    = writes_accepted_q;
    assign child_requests_o     = child_requests_q;
    assign child_responses_o    = child_responses_q;
    assign active_cycles_o      = active_cycles_q;

    // ------------------------------------------------------------------
    // 128-bit full descriptor preflight。
    // ------------------------------------------------------------------
    reg         opcode_valid_w;
    reg         binary_op_w;
    reg         empty_scale_w;
    reg         active_shape_w;
    reg         broadcast_shape_w;
    reg [127:0] total_elements_w;
    reg [127:0] dst_expected_nb0_w;
    reg [127:0] dst_expected_nb1_w;
    reg [127:0] dst_expected_nb2_w;
    reg [127:0] dst_expected_nb3_w;
    reg [127:0] src0_region_end_w;
    reg [127:0] src1_region_end_w;
    reg [127:0] dst_region_end_w;
    reg [127:0] src0_last_rel_w;
    reg [127:0] src1_last_rel_w;
    reg [127:0] dst_last_rel_w;
    reg [127:0] src0_abs_start_w;
    reg [127:0] src0_abs_end_w;
    reg [127:0] src1_abs_start_w;
    reg [127:0] src1_abs_end_w;
    reg [127:0] dst_abs_start_w;
    reg [127:0] dst_abs_end_w;
    reg [127:0] src0_beat_start_w;
    reg [127:0] src0_beat_end_w;
    reg [127:0] src1_beat_start_w;
    reg [127:0] src1_beat_end_w;
    reg [127:0] dst_beat_start_w;
    reg [127:0] dst_beat_end_w;
    reg         header_profile_ok_w;
    reg         shape_broadcast_ok_w;
    reg         stride_alignment_ok_w;
    reg         source_bounds_ok_w;
    reg         destination_bounds_ok_w;
    reg         overlap_ok_w;
    reg         src0_stride_ok_w;
    reg         src1_stride_ok_w;
    reg         dst_contiguous_ok_w;
    reg [4:0]   preflight_error_w;

    always @(*) begin
        opcode_valid_w = (opcode_q == OP_ADD)
                       || (opcode_q == OP_MUL)
                       || (opcode_q == OP_SUB)
                       || (opcode_q == OP_SCALE);
        binary_op_w = (opcode_q == OP_ADD)
                    || (opcode_q == OP_MUL)
                    || (opcode_q == OP_SUB);
        empty_scale_w = (opcode_q == OP_SCALE)
                      && (src0_ne0_q == 32'd0)
                      && (src0_ne1_q == 32'd1)
                      && (src0_ne2_q == 32'd1)
                      && (src0_ne3_q == 32'd1)
                      && (dst_ne0_q == 32'd0)
                      && (dst_ne1_q == 32'd1)
                      && (dst_ne2_q == 32'd1)
                      && (dst_ne3_q == 32'd1)
                      && (op_params_q == 64'b0);

        active_shape_w = (src0_ne0_q != 32'b0)
                       && (src0_ne1_q != 32'b0)
                       && (src0_ne2_q != 32'b0)
                       && (src0_ne3_q != 32'b0)
                       && (dst_ne0_q == src0_ne0_q)
                       && (dst_ne1_q == src0_ne1_q)
                       && (dst_ne2_q == src0_ne2_q)
                       && (dst_ne3_q == src0_ne3_q);
        broadcast_shape_w = 1'b0;
        if ((src1_ne0_q != 32'b0)
                && (src1_ne1_q != 32'b0)
                && (src1_ne2_q != 32'b0)
                && (src1_ne3_q != 32'b0)) begin
            broadcast_shape_w = ((src0_ne0_q % src1_ne0_q) == 32'b0)
                              && ((src0_ne1_q % src1_ne1_q) == 32'b0)
                              && ((src0_ne2_q % src1_ne2_q) == 32'b0)
                              && ((src0_ne3_q % src1_ne3_q) == 32'b0);
        end

        total_elements_w = {96'b0, src0_ne0_q};
        total_elements_w = total_elements_w * {96'b0, src0_ne1_q};
        total_elements_w = total_elements_w * {96'b0, src0_ne2_q};
        total_elements_w = total_elements_w * {96'b0, src0_ne3_q};

        dst_expected_nb0_w = 128'd4;
        dst_expected_nb1_w = {96'b0, dst_ne0_q} * 128'd4;
        dst_expected_nb2_w = dst_expected_nb1_w
                           * {96'b0, dst_ne1_q};
        dst_expected_nb3_w = dst_expected_nb2_w
                           * {96'b0, dst_ne2_q};

        src0_region_end_w = {64'b0, src0_region_base_q}
                          + {64'b0, src0_region_size_q};
        src1_region_end_w = {64'b0, src1_region_base_q}
                          + {64'b0, src1_region_size_q};
        dst_region_end_w  = {64'b0, dst_region_base_q}
                          + {64'b0, dst_region_size_q};

        src0_last_rel_w = {64'b0, src0_view_off_q};
        if ((src0_ne0_q != 32'b0) && (src0_ne1_q != 32'b0)
                && (src0_ne2_q != 32'b0) && (src0_ne3_q != 32'b0)) begin
            src0_last_rel_w = src0_last_rel_w
                + ({96'b0, (src0_ne0_q - 32'd1)} * {64'b0, src0_nb0_q})
                + ({96'b0, (src0_ne1_q - 32'd1)} * {64'b0, src0_nb1_q})
                + ({96'b0, (src0_ne2_q - 32'd1)} * {64'b0, src0_nb2_q})
                + ({96'b0, (src0_ne3_q - 32'd1)} * {64'b0, src0_nb3_q})
                + 128'd4;
        end
        src1_last_rel_w = {64'b0, src1_view_off_q};
        if ((src1_ne0_q != 32'b0) && (src1_ne1_q != 32'b0)
                && (src1_ne2_q != 32'b0) && (src1_ne3_q != 32'b0)) begin
            src1_last_rel_w = src1_last_rel_w
                + ({96'b0, (src1_ne0_q - 32'd1)} * {64'b0, src1_nb0_q})
                + ({96'b0, (src1_ne1_q - 32'd1)} * {64'b0, src1_nb1_q})
                + ({96'b0, (src1_ne2_q - 32'd1)} * {64'b0, src1_nb2_q})
                + ({96'b0, (src1_ne3_q - 32'd1)} * {64'b0, src1_nb3_q})
                + 128'd4;
        end
        dst_last_rel_w = {64'b0, dst_view_off_q}
                       + (total_elements_w * 128'd4);

        src0_abs_start_w = {64'b0, src0_region_base_q}
                         + {64'b0, src0_view_off_q};
        src0_abs_end_w = {64'b0, src0_region_base_q} + src0_last_rel_w;
        src1_abs_start_w = {64'b0, src1_region_base_q}
                         + {64'b0, src1_view_off_q};
        src1_abs_end_w = {64'b0, src1_region_base_q} + src1_last_rel_w;
        dst_abs_start_w = {64'b0, dst_region_base_q}
                        + {64'b0, dst_view_off_q};
        dst_abs_end_w = {64'b0, dst_region_base_q} + dst_last_rel_w;

        src0_beat_start_w = src0_abs_start_w;
        src0_beat_start_w[2:0] = 3'b000;
        src0_beat_end_w = src0_abs_end_w;
        src1_beat_start_w = src1_abs_start_w;
        src1_beat_start_w[2:0] = 3'b000;
        src1_beat_end_w = src1_abs_end_w;
        dst_beat_start_w = dst_abs_start_w;
        dst_beat_start_w[2:0] = 3'b000;
        dst_beat_end_w = dst_abs_end_w;
        if (active_shape_w && (total_elements_w != 128'b0)) begin
            src0_beat_end_w = src0_abs_end_w - 128'd1;
            src0_beat_end_w[2:0] = 3'b000;
            src0_beat_end_w = src0_beat_end_w + 128'd8;
            if (binary_op_w) begin
                src1_beat_end_w = src1_abs_end_w - 128'd1;
                src1_beat_end_w[2:0] = 3'b000;
                src1_beat_end_w = src1_beat_end_w + 128'd8;
            end
            dst_beat_end_w = dst_abs_end_w - 128'd1;
            dst_beat_end_w[2:0] = 3'b000;
            dst_beat_end_w = dst_beat_end_w + 128'd8;
        end

        header_profile_ok_w = opcode_valid_w
                            && (dtype_q == 2'b0)
                            && (profile_q == 4'b0)
                            && (reserved_q == 32'b0)
                            && (gmem_floor_q < gmem_limit_q)
                            && (MAX_ELEMENTS == 262144)
                            && ((binary_op_w && (op_params_q == 64'b0))
                                || ((opcode_q == OP_SCALE)
                                    && (op_params_q[63:32] == 32'b0)));

        shape_broadcast_ok_w = empty_scale_w
                             || (active_shape_w
                                 && (total_elements_w >= 128'd1)
                                 && (total_elements_w
                                     <= MAX_ELEMENTS_LIMIT)
                                 && ((!binary_op_w)
                                     || broadcast_shape_w));

        src0_stride_ok_w = (src0_nb0_q != 64'b0)
                         && (src0_nb1_q != 64'b0)
                         && (src0_nb2_q != 64'b0)
                         && (src0_nb3_q != 64'b0)
                         && (src0_nb0_q[1:0] == 2'b0)
                         && (src0_nb1_q[1:0] == 2'b0)
                         && (src0_nb2_q[1:0] == 2'b0)
                         && (src0_nb3_q[1:0] == 2'b0);
        src1_stride_ok_w = (src1_nb0_q != 64'b0)
                         && (src1_nb1_q != 64'b0)
                         && (src1_nb2_q != 64'b0)
                         && (src1_nb3_q != 64'b0)
                         && (src1_nb0_q[1:0] == 2'b0)
                         && (src1_nb1_q[1:0] == 2'b0)
                         && (src1_nb2_q[1:0] == 2'b0)
                         && (src1_nb3_q[1:0] == 2'b0);
        dst_contiguous_ok_w = (dst_expected_nb0_w[127:64] == 64'b0)
                            && (dst_expected_nb1_w[127:64] == 64'b0)
                            && (dst_expected_nb2_w[127:64] == 64'b0)
                            && (dst_expected_nb3_w[127:64] == 64'b0)
                            && (dst_nb0_q == dst_expected_nb0_w[63:0])
                            && (dst_nb1_q == dst_expected_nb1_w[63:0])
                            && (dst_nb2_q == dst_expected_nb2_w[63:0])
                            && (dst_nb3_q == dst_expected_nb3_w[63:0]);
        stride_alignment_ok_w = empty_scale_w
                              || (src0_stride_ok_w
                                  && ((!binary_op_w) || src1_stride_ok_w)
                                  && dst_contiguous_ok_w
                                  && (src0_abs_start_w[1:0] == 2'b0)
                                  && ((!binary_op_w)
                                      || (src1_abs_start_w[1:0] == 2'b0))
                                  && (dst_abs_start_w[1:0] == 2'b0));

        if (empty_scale_w) begin
            source_bounds_ok_w = 1'b1;
            destination_bounds_ok_w = 1'b1;
        end else begin
            source_bounds_ok_w =
                   (src0_region_end_w[127:64] == 64'b0)
                && (src0_view_off_q <= src0_region_size_q)
                && (src0_last_rel_w <= {64'b0, src0_region_size_q})
                && (src0_abs_start_w[127:64] == 64'b0)
                && (src0_abs_end_w[127:64] == 64'b0)
                && (src0_beat_start_w[127:64] == 64'b0)
                && (src0_beat_end_w[127:64] == 64'b0)
                && (src0_beat_start_w[63:0] >= src0_region_base_q)
                && (src0_beat_end_w <= src0_region_end_w)
                && (src0_beat_start_w[63:0] >= gmem_floor_q)
                && (src0_beat_end_w[63:0] <= gmem_limit_q);
            if (binary_op_w) begin
                source_bounds_ok_w = source_bounds_ok_w
                    && (src1_region_end_w[127:64] == 64'b0)
                    && (src1_view_off_q <= src1_region_size_q)
                    && (src1_last_rel_w <= {64'b0, src1_region_size_q})
                    && (src1_abs_start_w[127:64] == 64'b0)
                    && (src1_abs_end_w[127:64] == 64'b0)
                    && (src1_beat_start_w[127:64] == 64'b0)
                    && (src1_beat_end_w[127:64] == 64'b0)
                    && (src1_beat_start_w[63:0] >= src1_region_base_q)
                    && (src1_beat_end_w <= src1_region_end_w)
                    && (src1_beat_start_w[63:0] >= gmem_floor_q)
                    && (src1_beat_end_w[63:0] <= gmem_limit_q);
            end

            destination_bounds_ok_w =
                   (dst_region_end_w[127:64] == 64'b0)
                && (dst_view_off_q <= dst_region_size_q)
                && (dst_last_rel_w <= {64'b0, dst_region_size_q})
                && (dst_abs_start_w[127:64] == 64'b0)
                && (dst_abs_end_w[127:64] == 64'b0)
                && (dst_beat_start_w[127:64] == 64'b0)
                && (dst_beat_end_w[127:64] == 64'b0)
                && (dst_beat_start_w[63:0] >= dst_region_base_q)
                && (dst_beat_end_w <= dst_region_end_w)
                && (dst_beat_start_w[63:0] >= gmem_floor_q)
                && (dst_beat_end_w[63:0] <= gmem_limit_q);
        end

        overlap_ok_w = 1'b1;
        if (!empty_scale_w && source_bounds_ok_w
                && destination_bounds_ok_w) begin
            if ((src0_beat_start_w < dst_beat_end_w)
                    && (dst_beat_start_w < src0_beat_end_w)) begin
                overlap_ok_w = 1'b0;
            end
            if (binary_op_w
                    && (src1_beat_start_w < dst_beat_end_w)
                    && (dst_beat_start_w < src1_beat_end_w)) begin
                overlap_ok_w = 1'b0;
            end
        end

        // 固定 preflight 优先级与合同一致。
        if (!header_profile_ok_w)
            preflight_error_w = ERR_HEADER_PROFILE;
        else if (!shape_broadcast_ok_w)
            preflight_error_w = ERR_SHAPE_BROADCAST;
        else if (!stride_alignment_ok_w)
            preflight_error_w = ERR_STRIDE_ALIGNMENT;
        else if (!source_bounds_ok_w)
            preflight_error_w = ERR_SOURCE_BOUNDS;
        else if (!destination_bounds_ok_w)
            preflight_error_w = ERR_DEST_BOUNDS;
        else if (!overlap_ok_w)
            preflight_error_w = ERR_OVERLAP;
        else
            preflight_error_w = ERR_NONE;
    end

    // ------------------------------------------------------------------
    // Runtime 4D walker。WRITE_WAIT 保留 commit lookahead；CHILD_WAIT
    // 额外选择同一 successor，仅用于在 clean child response 边沿预存
    // exact dual-cache-hit operands。唯一 modulo/stride/multiply 地址网
    // 不依赖 response valid/ready/fire，也不直接驱动 child payload。
    // ------------------------------------------------------------------
    wire [63:0] next_flat_index_w;
    reg  [31:0] next_coord_i0_w;
    reg  [31:0] next_coord_i1_w;
    reg  [31:0] next_coord_i2_w;
    reg  [31:0] next_coord_i3_w;
    wire        select_next_element_w;
    wire        select_pair_prepare_element_w;
    wire        select_successor_element_w;
    wire [63:0] selected_flat_index_w;
    wire [31:0] selected_coord_i0_w;
    wire [31:0] selected_coord_i1_w;
    wire [31:0] selected_coord_i2_w;
    wire [31:0] selected_coord_i3_w;
    reg [31:0] src1_i0_w;
    reg [31:0] src1_i1_w;
    reg [31:0] src1_i2_w;
    reg [31:0] src1_i3_w;
    reg [127:0] selected_src0_addr_w;
    reg [127:0] selected_src1_addr_w;
    reg [127:0] selected_dst_addr_w;
    reg selected_address_valid_w;
    wire selected_element_valid_w;
    wire selected_element_address_valid_w;
    wire src0_beat_reuse_hit_w;
    wire src1_beat_reuse_hit_w;
    wire gmem_pair_reuse_hit_w;
    wire src0_beat_prepare_hit_w;
    wire src1_beat_prepare_hit_w;
    wire gmem_pair_reuse_prepare_hit_w;
    wire [31:0] src0_beat_reuse_word_w;
    wire [31:0] src1_beat_reuse_word_w;
    wire current_element_integrity_ok_w;
    wire pair_reuse_prepare_w;

    assign next_flat_index_w = flat_index_q + 64'd1;

    // 唯一 4D carry 网络；sequential advance 直接采样这些 next wires。
    always @(*) begin
        next_coord_i0_w = coord_i0_q;
        next_coord_i1_w = coord_i1_q;
        next_coord_i2_w = coord_i2_q;
        next_coord_i3_w = coord_i3_q;
        if ((coord_i0_q + 32'd1) < src0_ne0_q) begin
            next_coord_i0_w = coord_i0_q + 32'd1;
        end else begin
            next_coord_i0_w = 32'b0;
            if ((coord_i1_q + 32'd1) < src0_ne1_q) begin
                next_coord_i1_w = coord_i1_q + 32'd1;
            end else begin
                next_coord_i1_w = 32'b0;
                if ((coord_i2_q + 32'd1) < src0_ne2_q) begin
                    next_coord_i2_w = coord_i2_q + 32'd1;
                end else begin
                    next_coord_i2_w = 32'b0;
                    next_coord_i3_w = coord_i3_q + 32'd1;
                end
            end
        end
    end

    assign select_next_element_w = (state_q == ST_WRITE_WAIT)
                                  && (next_flat_index_w
                                      < total_elements_q);
    assign select_pair_prepare_element_w = (state_q == ST_CHILD_WAIT)
                                         && (next_flat_index_w
                                             < total_elements_q);
    assign select_successor_element_w = select_next_element_w
                                      || select_pair_prepare_element_w;
    assign selected_flat_index_w = select_successor_element_w
                                 ? next_flat_index_w : flat_index_q;
    assign selected_coord_i0_w = select_successor_element_w
                               ? next_coord_i0_w : coord_i0_q;
    assign selected_coord_i1_w = select_successor_element_w
                               ? next_coord_i1_w : coord_i1_q;
    assign selected_coord_i2_w = select_successor_element_w
                               ? next_coord_i2_w : coord_i2_q;
    assign selected_coord_i3_w = select_successor_element_w
                               ? next_coord_i3_w : coord_i3_q;
    assign selected_element_valid_w = (total_elements_q != 64'b0)
                                    && (selected_flat_index_w
                                        < total_elements_q)
                                    && (selected_coord_i0_w < src0_ne0_q)
                                    && (selected_coord_i1_w < src0_ne1_q)
                                    && (selected_coord_i2_w < src0_ne2_q)
                                    && (selected_coord_i3_w < src0_ne3_q);
    assign selected_element_address_valid_w = selected_element_valid_w
                                            && selected_address_valid_w;

    // The reuse decision is made only for the already-computed non-last
    // successor in WRITE_WAIT.  It depends solely on registered cache state
    // and exact aligned tags; lane selection is deliberately separate from
    // tag matching so equal lanes in different beats cannot false-hit.
    assign src0_beat_reuse_hit_w = select_next_element_w
                                 && selected_element_address_valid_w
                                 && binary_op_w
                                 && src0_beat_valid_q
                                 && (src0_beat_tag_q
                                     == selected_src0_addr_w[63:3]);
    assign src1_beat_reuse_hit_w = select_next_element_w
                                 && selected_element_address_valid_w
                                 && binary_op_w
                                 && src1_beat_valid_q
                                 && (src1_beat_tag_q
                                     == selected_src1_addr_w[63:3]);
    assign gmem_pair_reuse_hit_w = src0_beat_reuse_hit_w
                                 && src1_beat_reuse_hit_w;
    // Separate CHILD_WAIT candidate: gmem_pair_reuse_hit_w remains the
    // WRITE_WAIT commit witness used by the existing protocol/error oracles.
    assign src0_beat_prepare_hit_w = select_pair_prepare_element_w
                                   && selected_element_address_valid_w
                                   && binary_op_w
                                   && src0_beat_valid_q
                                   && (src0_beat_tag_q
                                       == selected_src0_addr_w[63:3]);
    assign src1_beat_prepare_hit_w = select_pair_prepare_element_w
                                   && selected_element_address_valid_w
                                   && binary_op_w
                                   && src1_beat_valid_q
                                   && (src1_beat_tag_q
                                       == selected_src1_addr_w[63:3]);
    assign gmem_pair_reuse_prepare_hit_w = src0_beat_prepare_hit_w
                                         && src1_beat_prepare_hit_w;
    assign src0_beat_reuse_word_w = selected_src0_addr_w[2]
                                  ? src0_beat_data_q[63:32]
                                  : src0_beat_data_q[31:0];
    assign src1_beat_reuse_word_w = selected_src1_addr_w[2]
                                  ? src1_beat_data_q[63:32]
                                  : src1_beat_data_q[31:0];

    always @(*) begin
        src1_i0_w = 32'b0;
        src1_i1_w = 32'b0;
        src1_i2_w = 32'b0;
        src1_i3_w = 32'b0;
        if (src1_ne0_q != 32'b0)
            src1_i0_w = selected_coord_i0_w % src1_ne0_q;
        if (src1_ne1_q != 32'b0)
            src1_i1_w = selected_coord_i1_w % src1_ne1_q;
        if (src1_ne2_q != 32'b0)
            src1_i2_w = selected_coord_i2_w % src1_ne2_q;
        if (src1_ne3_q != 32'b0)
            src1_i3_w = selected_coord_i3_w % src1_ne3_q;

        selected_src0_addr_w = {64'b0, src0_region_base_q}
            + {64'b0, src0_view_off_q}
            + ({96'b0, selected_coord_i0_w} * {64'b0, src0_nb0_q})
            + ({96'b0, selected_coord_i1_w} * {64'b0, src0_nb1_q})
            + ({96'b0, selected_coord_i2_w} * {64'b0, src0_nb2_q})
            + ({96'b0, selected_coord_i3_w} * {64'b0, src0_nb3_q});
        selected_src1_addr_w = {64'b0, src1_region_base_q}
            + {64'b0, src1_view_off_q}
            + ({96'b0, src1_i0_w} * {64'b0, src1_nb0_q})
            + ({96'b0, src1_i1_w} * {64'b0, src1_nb1_q})
            + ({96'b0, src1_i2_w} * {64'b0, src1_nb2_q})
            + ({96'b0, src1_i3_w} * {64'b0, src1_nb3_q});
        selected_dst_addr_w = {64'b0, dst_region_base_q}
            + {64'b0, dst_view_off_q}
            + ({64'b0, selected_flat_index_w} * 128'd4);
        selected_address_valid_w =
               (selected_src0_addr_w[127:64] == 64'b0)
            && (selected_src0_addr_w[1:0] == 2'b0)
            && (selected_dst_addr_w[127:64] == 64'b0)
            && (selected_dst_addr_w[1:0] == 2'b0)
            && ((!binary_op_w)
                || ((selected_src1_addr_w[127:64] == 64'b0)
                    && (selected_src1_addr_w[1:0] == 2'b0)));
    end

    // This guard is shared by preparation and WRITE_WAIT commit/direct.  It
    // covers only the registered current walker state; successor validity is
    // captured by pair_reuse_prepared_q on the earlier CHILD_WAIT edge.
    assign current_element_integrity_ok_w =
           (flat_index_q < total_elements_q)
        && (next_flat_index_w > flat_index_q)
        && (coord_i0_q < src0_ne0_q)
        && (coord_i1_q < src0_ne1_q)
        && (coord_i2_q < src0_ne2_q)
        && (coord_i3_q < src0_ne3_q);

    // ------------------------------------------------------------------
    // 独占 FP32 ADD/MUL child 与显式 opcode operand mux。
    // ------------------------------------------------------------------
    assign child_rst_w = rst_i || (state_q == ST_IDLE)
                       || (state_q == ST_DONE) || (state_q == ST_ERROR)
                       || ((state_q == ST_DRAIN)
                           && (drain_owner_q == DRAIN_GMEM));
    // A clean SRC1 response may fall through into the otherwise-idle child.
    // The offer and its operand selector deliberately do not depend on child
    // ready: ready-low consumes the GMEM response into rhs_bits_q, then the
    // existing CHILD_REQ state holds the identical payload until acceptance.
    assign src1_child_direct_offer_w = !child_rst_w
                                      && (state_q == ST_SRC1_WAIT)
                                      && gmem_rsp_fire_w
                                      && !gmem_rsp_error_i
                                      && !protocol_fault_w
                                      && !command_timeout_hit_w
                                      && !phase_timeout_hit_w;
    // All expensive successor work has already been registered at the clean
    // child-response edge.  Ready controls only fire, never offer or payload.
    assign pair_reuse_child_direct_offer_w = !rst_i
                                           && !child_rst_w
                                           && (state_q == ST_WRITE_WAIT)
                                           && gmem_rsp_fire_w
                                           && !gmem_rsp_error_i
                                           && !protocol_fault_w
                                           && !command_timeout_hit_w
                                           && !phase_timeout_hit_w
                                           && current_element_integrity_ok_w
                                           && (next_flat_index_w
                                               < total_elements_q)
                                           && pair_reuse_prepared_q;
    assign child_req_valid_w = !child_rst_w
                             && (child_request_state_w
                                 || src1_child_direct_offer_w
                                 || pair_reuse_child_direct_offer_w)
                             && !protocol_fault_w
                             && !command_timeout_hit_w
                             && !phase_timeout_hit_w;
    assign child_op_mul_w = (opcode_q == OP_MUL) || (opcode_q == OP_SCALE);
    assign child_rhs_raw_w = src1_child_direct_offer_w
                           ? selected_gmem_word_w : rhs_bits_q;
    assign child_rhs_bits_w = (opcode_q == OP_SUB)
                            ? {~child_rhs_raw_w[31],
                               child_rhs_raw_w[30:0]}
                            : child_rhs_raw_w;
    assign child_rsp_ready_w = !child_rst_w && !protocol_fault_w
                             && child_wait_state_w && child_outstanding_q;
    assign child_req_fire_w = child_req_valid_w && child_req_ready_w;
    assign src1_child_direct_fire_w = src1_child_direct_offer_w
                                    && child_req_ready_w;
    assign pair_reuse_child_direct_fire_w =
        pair_reuse_child_direct_offer_w && child_req_ready_w;
    assign child_rsp_fire_w = child_rsp_valid_w && child_rsp_ready_w;

    assign pair_reuse_prepare_w = !rst_i
                                && !child_rst_w
                                && (state_q == ST_CHILD_WAIT)
                                && child_rsp_fire_w
                                && !protocol_fault_w
                                && !command_timeout_hit_w
                                && !phase_timeout_hit_w
                                && child_write_payload_valid_w
                                && current_element_integrity_ok_w
                                && gmem_pair_reuse_prepare_hit_w;

    TensorNpuFp32AddMul u_fp32_addmul (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .req_valid_i   (child_req_valid_w),
        .req_ready_o   (child_req_ready_w),
        .op_mul_i      (child_op_mul_w),
        .lhs_bits_i    (lhs_bits_q),
        .rhs_bits_i    (child_rhs_bits_w),
        .rsp_valid_o   (child_rsp_valid_w),
        .rsp_ready_i   (child_rsp_ready_w),
        .result_bits_o (child_result_bits_w),
        .flags_o       (child_flags_w)
    );

    assign selected_gmem_word_w = gmem_read_upper_q
                                ? gmem_rsp_rdata_i[63:32]
                                : gmem_rsp_rdata_i[31:0];

    // ------------------------------------------------------------------
    // 唯一时序块：descriptor、FSM、owner、watchdog、flags 与 counters。
    // ------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                <= ST_IDLE;
            opcode_q               <= 3'b0;
            dtype_q                <= 2'b0;
            profile_q              <= 4'b0;
            reserved_q             <= 32'b0;
            op_params_q            <= 64'b0;
            gmem_floor_q           <= 64'b0;
            gmem_limit_q           <= 64'b0;
            src0_region_base_q     <= 64'b0;
            src0_region_size_q     <= 64'b0;
            src0_view_off_q        <= 64'b0;
            src0_ne0_q             <= 32'b0;
            src0_ne1_q             <= 32'b0;
            src0_ne2_q             <= 32'b0;
            src0_ne3_q             <= 32'b0;
            src0_nb0_q             <= 64'b0;
            src0_nb1_q             <= 64'b0;
            src0_nb2_q             <= 64'b0;
            src0_nb3_q             <= 64'b0;
            src1_region_base_q     <= 64'b0;
            src1_region_size_q     <= 64'b0;
            src1_view_off_q        <= 64'b0;
            src1_ne0_q             <= 32'b0;
            src1_ne1_q             <= 32'b0;
            src1_ne2_q             <= 32'b0;
            src1_ne3_q             <= 32'b0;
            src1_nb0_q             <= 64'b0;
            src1_nb1_q             <= 64'b0;
            src1_nb2_q             <= 64'b0;
            src1_nb3_q             <= 64'b0;
            dst_region_base_q      <= 64'b0;
            dst_region_size_q      <= 64'b0;
            dst_view_off_q         <= 64'b0;
            dst_ne0_q              <= 32'b0;
            dst_ne1_q              <= 32'b0;
            dst_ne2_q              <= 32'b0;
            dst_ne3_q              <= 32'b0;
            dst_nb0_q              <= 64'b0;
            dst_nb1_q              <= 64'b0;
            dst_nb2_q              <= 64'b0;
            dst_nb3_q              <= 64'b0;
            total_elements_q       <= 64'b0;
            flat_index_q           <= 64'b0;
            coord_i0_q             <= 32'b0;
            coord_i1_q             <= 32'b0;
            coord_i2_q             <= 32'b0;
            coord_i3_q             <= 32'b0;
            gmem_req_addr_q        <= 64'b0;
            gmem_req_wdata_q       <= 64'b0;
            gmem_req_wstrb_q       <= 8'b0;
            gmem_read_upper_q      <= 1'b0;
            src0_beat_valid_q      <= 1'b0;
            src0_beat_tag_q        <= 61'b0;
            src0_beat_data_q       <= 64'b0;
            src1_beat_valid_q      <= 1'b0;
            src1_beat_tag_q        <= 61'b0;
            src1_beat_data_q       <= 64'b0;
            current_src1_word_q    <= 62'b0;
            current_dst_addr_q     <= 64'b0;
            gmem_outstanding_q     <= 1'b0;
            lhs_bits_q             <= 32'b0;
            rhs_bits_q             <= 32'b0;
            pair_reuse_prepared_q  <= 1'b0;
            child_outstanding_q    <= 1'b0;
            drain_owner_q          <= DRAIN_NONE;
            drain_error_code_q     <= ERR_NONE;
            error_code_q           <= ERR_NONE;
            arithmetic_flags_q     <= 5'b0;
            stall_cycles_q         <= 32'b0;
            command_cycles_q       <= 32'b0;
            elements_done_q        <= 64'b0;
            gmem_read_beats_q      <= 64'b0;
            gmem_pair_reuse_elements_q <= 64'b0;
            gmem_write_beats_q     <= 64'b0;
            writes_accepted_q      <= 64'b0;
            child_requests_q       <= 64'b0;
            child_responses_q      <= 64'b0;
            active_cycles_q        <= 64'b0;
        end else begin
            // DRAIN/terminal 冻结周期和结果 counters。
            if ((state_q != ST_IDLE) && (state_q != ST_DRAIN)
                    && (state_q != ST_DONE) && (state_q != ST_ERROR)) begin
                command_cycles_q <= command_cycles_q + 32'd1;
                active_cycles_q  <= active_cycles_q + 64'd1;
            end

            // active-state owner fault 高于 watchdog。若已有 accepted owner，先用
            // 唯一 DRAIN 归还其 response credit；否则直接 no-commit ERROR。
            if (protocol_fault_w) begin
                src0_beat_valid_q  <= 1'b0;
                src1_beat_valid_q  <= 1'b0;
                pair_reuse_prepared_q <= 1'b0;
                arithmetic_flags_q <= 5'b0;
                stall_cycles_q     <= 32'b0;
                if (gmem_outstanding_q) begin
                    drain_owner_q      <= DRAIN_GMEM;
                    drain_error_code_q <= protocol_error_code_w;
                    state_q            <= ST_DRAIN;
                end else if (child_outstanding_q) begin
                    drain_owner_q      <= DRAIN_CHILD;
                    drain_error_code_q <= protocol_error_code_w;
                    state_q            <= ST_DRAIN;
                end else begin
                    error_code_q <= protocol_error_code_w;
                    state_q      <= ST_ERROR;
                end
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        gmem_outstanding_q  <= 1'b0;
                        child_outstanding_q <= 1'b0;
                        drain_owner_q       <= DRAIN_NONE;
                        stall_cycles_q      <= 32'b0;
                        command_cycles_q    <= 32'b0;
                        if (start_fire_w) begin
                            opcode_q            <= opcode_i;
                            dtype_q             <= dtype_i;
                            profile_q           <= profile_i;
                            reserved_q          <= reserved_i;
                            op_params_q         <= op_params_i;
                            gmem_floor_q        <= gmem_floor_i;
                            gmem_limit_q        <= gmem_limit_i;
                            src0_region_base_q  <= src0_region_base_i;
                            src0_region_size_q  <= src0_region_size_i;
                            src0_view_off_q     <= src0_view_off_i;
                            src0_ne0_q          <= src0_ne0_i;
                            src0_ne1_q          <= src0_ne1_i;
                            src0_ne2_q          <= src0_ne2_i;
                            src0_ne3_q          <= src0_ne3_i;
                            src0_nb0_q          <= src0_nb0_i;
                            src0_nb1_q          <= src0_nb1_i;
                            src0_nb2_q          <= src0_nb2_i;
                            src0_nb3_q          <= src0_nb3_i;
                            src1_region_base_q  <= src1_region_base_i;
                            src1_region_size_q  <= src1_region_size_i;
                            src1_view_off_q     <= src1_view_off_i;
                            src1_ne0_q          <= src1_ne0_i;
                            src1_ne1_q          <= src1_ne1_i;
                            src1_ne2_q          <= src1_ne2_i;
                            src1_ne3_q          <= src1_ne3_i;
                            src1_nb0_q          <= src1_nb0_i;
                            src1_nb1_q          <= src1_nb1_i;
                            src1_nb2_q          <= src1_nb2_i;
                            src1_nb3_q          <= src1_nb3_i;
                            dst_region_base_q   <= dst_region_base_i;
                            dst_region_size_q   <= dst_region_size_i;
                            dst_view_off_q      <= dst_view_off_i;
                            dst_ne0_q           <= dst_ne0_i;
                            dst_ne1_q           <= dst_ne1_i;
                            dst_ne2_q           <= dst_ne2_i;
                            dst_ne3_q           <= dst_ne3_i;
                            dst_nb0_q           <= dst_nb0_i;
                            dst_nb1_q           <= dst_nb1_i;
                            dst_nb2_q           <= dst_nb2_i;
                            dst_nb3_q           <= dst_nb3_i;
                            total_elements_q    <= 64'b0;
                            flat_index_q        <= 64'b0;
                            coord_i0_q          <= 32'b0;
                            coord_i1_q          <= 32'b0;
                            coord_i2_q          <= 32'b0;
                            coord_i3_q          <= 32'b0;
                            gmem_req_addr_q     <= {
                                start_src0_word_w[61:1], 3'b000
                            };
                            gmem_req_wdata_q    <= 64'b0;
                            gmem_req_wstrb_q    <= 8'b0;
                            gmem_read_upper_q   <=
                                start_src0_word_w[0];
                            src0_beat_valid_q   <= 1'b0;
                            src0_beat_tag_q     <= 61'b0;
                            src0_beat_data_q    <= 64'b0;
                            src1_beat_valid_q   <= 1'b0;
                            src1_beat_tag_q     <= 61'b0;
                            src1_beat_data_q    <= 64'b0;
                            current_src1_word_q <=
                                start_src1_word_w;
                            current_dst_addr_q  <=
                                start_dst_addr_w;
                            lhs_bits_q          <= 32'b0;
                            rhs_bits_q          <= 32'b0;
                            pair_reuse_prepared_q <= 1'b0;
                            drain_error_code_q  <= ERR_NONE;
                            error_code_q        <= ERR_NONE;
                            arithmetic_flags_q  <= 5'b0;
                            stall_cycles_q      <= 32'b0;
                            command_cycles_q    <= 32'b0;
                            elements_done_q     <= 64'b0;
                            gmem_read_beats_q   <= 64'b0;
                            gmem_pair_reuse_elements_q <= 64'b0;
                            gmem_write_beats_q  <= 64'b0;
                            writes_accepted_q   <= 64'b0;
                            child_requests_q    <= 64'b0;
                            child_responses_q   <= 64'b0;
                            active_cycles_q     <= 64'b0;
                            state_q             <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        stall_cycles_q <= 32'b0;
                        if (preflight_error_w != ERR_NONE) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= preflight_error_w;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (empty_scale_w) begin
                            total_elements_q <= 64'b0;
                            state_q          <= ST_DONE;
                        end else begin
                            total_elements_q <= total_elements_w[63:0];
                            state_q          <= ST_SRC0_REQ;
                        end
                    end

                    ST_ELEMENT_PREP: begin
                        stall_cycles_q <= 32'b0;
                        if (!selected_element_address_valid_w
                                || gmem_outstanding_q
                                || child_outstanding_q) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else begin
                            gmem_req_addr_q <= {
                                selected_src0_addr_w[63:3], 3'b000
                            };
                            gmem_read_upper_q <= selected_src0_addr_w[2];
                            current_src1_word_q <= selected_src1_addr_w[63:2];
                            current_dst_addr_q  <= selected_dst_addr_w[63:0];
                            state_q <= ST_SRC0_REQ;
                        end
                    end

                    ST_SRC0_REQ: begin
                        if ((gmem_req_addr_q[2:0] != 3'b000)
                                || gmem_outstanding_q
                                || child_outstanding_q) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (phase_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_STALL_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (gmem_req_fire_w) begin
                            gmem_outstanding_q <= 1'b1;
                            gmem_read_beats_q  <= gmem_read_beats_q + 64'd1;
                            stall_cycles_q     <= 32'b0;
                            state_q            <= ST_SRC0_WAIT;
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_SRC0_WAIT: begin
                        if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                            gmem_outstanding_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_GMEM_RESPONSE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            if (gmem_rsp_fire_w) begin
                                gmem_outstanding_q <= 1'b0;
                                error_code_q       <= ERR_COMMAND_TIMEOUT;
                                state_q            <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_GMEM;
                                drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (phase_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            if (gmem_rsp_fire_w) begin
                                gmem_outstanding_q <= 1'b0;
                                error_code_q       <= ERR_STALL_TIMEOUT;
                                state_q            <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_GMEM;
                                drain_error_code_q <= ERR_STALL_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (gmem_rsp_fire_w) begin
                            gmem_outstanding_q <= 1'b0;
                            stall_cycles_q     <= 32'b0;
                            src0_beat_valid_q  <= 1'b1;
                            src0_beat_tag_q    <= gmem_req_addr_q[63:3];
                            src0_beat_data_q   <= gmem_rsp_rdata_i;
                            lhs_bits_q         <= selected_gmem_word_w;
                            if (opcode_q == OP_SCALE) begin
                                rhs_bits_q <= op_params_q[31:0];
                                state_q    <= ST_CHILD_REQ;
                            end else begin
                                gmem_req_addr_q <= {
                                    current_src1_word_q[61:1], 3'b000
                                };
                                gmem_read_upper_q <= current_src1_word_q[0];
                                state_q <= ST_SRC1_REQ;
                            end
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_SRC1_REQ: begin
                        if ((gmem_req_addr_q[2:0] != 3'b000)
                                || gmem_outstanding_q
                                || child_outstanding_q) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (phase_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_STALL_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (gmem_req_fire_w) begin
                            gmem_outstanding_q <= 1'b1;
                            gmem_read_beats_q  <= gmem_read_beats_q + 64'd1;
                            stall_cycles_q     <= 32'b0;
                            state_q            <= ST_SRC1_WAIT;
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_SRC1_WAIT: begin
                        if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                            gmem_outstanding_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_GMEM_RESPONSE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            if (gmem_rsp_fire_w) begin
                                gmem_outstanding_q <= 1'b0;
                                error_code_q       <= ERR_COMMAND_TIMEOUT;
                                state_q            <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_GMEM;
                                drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (phase_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            if (gmem_rsp_fire_w) begin
                                gmem_outstanding_q <= 1'b0;
                                error_code_q       <= ERR_STALL_TIMEOUT;
                                state_q            <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_GMEM;
                                drain_error_code_q <= ERR_STALL_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (gmem_rsp_fire_w) begin
                            gmem_outstanding_q <= 1'b0;
                            stall_cycles_q     <= 32'b0;
                            src1_beat_valid_q  <= 1'b1;
                            src1_beat_tag_q    <= gmem_req_addr_q[63:3];
                            src1_beat_data_q   <= gmem_rsp_rdata_i;
                            rhs_bits_q         <= selected_gmem_word_w;
                            if (src1_child_direct_fire_w) begin
                                child_outstanding_q <= 1'b1;
                                child_requests_q <= child_requests_q + 64'd1;
                                state_q <= ST_CHILD_WAIT;
                            end else begin
                                state_q <= ST_CHILD_REQ;
                            end
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_CHILD_REQ: begin
                        if (gmem_outstanding_q || child_outstanding_q) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (phase_timeout_hit_w) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_CHILD_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (child_req_fire_w) begin
                            child_outstanding_q <= 1'b1;
                            child_requests_q    <= child_requests_q + 64'd1;
                            stall_cycles_q      <= 32'b0;
                            state_q             <= ST_CHILD_WAIT;
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_CHILD_WAIT: begin
                        if (command_timeout_hit_w) begin
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            if (child_rsp_fire_w) begin
                                child_outstanding_q <= 1'b0;
                                child_responses_q   <= child_responses_q + 64'd1;
                                error_code_q        <= ERR_COMMAND_TIMEOUT;
                                state_q             <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_CHILD;
                                drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (phase_timeout_hit_w) begin
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            if (child_rsp_fire_w) begin
                                child_outstanding_q <= 1'b0;
                                child_responses_q   <= child_responses_q + 64'd1;
                                error_code_q        <= ERR_CHILD_TIMEOUT;
                                state_q             <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_CHILD;
                                drain_error_code_q <= ERR_CHILD_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (child_rsp_fire_w) begin
                            child_outstanding_q <= 1'b0;
                            child_responses_q   <= child_responses_q + 64'd1;
                            arithmetic_flags_q <= arithmetic_flags_q
                                                | child_flags_w;
                            stall_cycles_q <= 32'b0;
                            gmem_req_addr_q  <= child_write_addr_w;
                            gmem_req_wdata_q <= child_write_data_w;
                            gmem_req_wstrb_q <= child_write_strb_w;
                            if (pair_reuse_prepare_w) begin
                                lhs_bits_q <= src0_beat_reuse_word_w;
                                rhs_bits_q <= src1_beat_reuse_word_w;
                                pair_reuse_prepared_q <= 1'b1;
                            end else begin
                                pair_reuse_prepared_q <= 1'b0;
                            end
                            if (child_write_direct_fire_w) begin
                                gmem_outstanding_q <= 1'b1;
                                gmem_write_beats_q <=
                                    gmem_write_beats_q + 64'd1;
                                writes_accepted_q <=
                                    writes_accepted_q + 64'd1;
                                state_q <= ST_WRITE_WAIT;
                            end else begin
                                state_q <= ST_WRITE_REQ;
                            end
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_WRITE_REQ: begin
                        if (!registered_write_payload_valid_w
                                || gmem_outstanding_q
                                || child_outstanding_q) begin
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_COMMAND_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (phase_timeout_hit_w) begin
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_STALL_TIMEOUT;
                            state_q            <= ST_ERROR;
                        end else if (gmem_req_fire_w) begin
                            gmem_outstanding_q <= 1'b1;
                            gmem_write_beats_q <= gmem_write_beats_q + 64'd1;
                            writes_accepted_q  <= writes_accepted_q + 64'd1;
                            stall_cycles_q     <= 32'b0;
                            state_q            <= ST_WRITE_WAIT;
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_WRITE_WAIT: begin
                        if (gmem_rsp_fire_w && gmem_rsp_error_i) begin
                            gmem_outstanding_q <= 1'b0;
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_GMEM_RESPONSE;
                            state_q            <= ST_ERROR;
                        end else if (command_timeout_hit_w) begin
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            if (gmem_rsp_fire_w) begin
                                gmem_outstanding_q <= 1'b0;
                                error_code_q       <= ERR_COMMAND_TIMEOUT;
                                state_q            <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_GMEM;
                                drain_error_code_q <= ERR_COMMAND_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (phase_timeout_hit_w) begin
                            pair_reuse_prepared_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            if (gmem_rsp_fire_w) begin
                                gmem_outstanding_q <= 1'b0;
                                error_code_q       <= ERR_STALL_TIMEOUT;
                                state_q            <= ST_ERROR;
                            end else begin
                                drain_owner_q      <= DRAIN_GMEM;
                                drain_error_code_q <= ERR_STALL_TIMEOUT;
                                state_q            <= ST_DRAIN;
                            end
                        end else if (gmem_rsp_fire_w) begin
                            gmem_outstanding_q <= 1'b0;
                            pair_reuse_prepared_q <= 1'b0;
                            stall_cycles_q     <= 32'b0;
                            elements_done_q    <= elements_done_q + 64'd1;
                            if (!current_element_integrity_ok_w) begin
                                arithmetic_flags_q <= 5'b0;
                                error_code_q       <= ERR_INTERNAL_STATE;
                                state_q            <= ST_ERROR;
                            end else if (next_flat_index_w
                                    == total_elements_q) begin
                                state_q <= ST_DONE;
                            end else if (!select_next_element_w
                                    || !selected_element_address_valid_w) begin
                                arithmetic_flags_q <= 5'b0;
                                error_code_q       <= ERR_INTERNAL_STATE;
                                state_q            <= ST_ERROR;
                            end else begin
                                flat_index_q <= next_flat_index_w;
                                coord_i0_q   <= next_coord_i0_w;
                                coord_i1_q   <= next_coord_i1_w;
                                coord_i2_q   <= next_coord_i2_w;
                                coord_i3_q   <= next_coord_i3_w;
                                current_src1_word_q <=
                                    selected_src1_addr_w[63:2];
                                current_dst_addr_q <=
                                    selected_dst_addr_w[63:0];
                                if (pair_reuse_prepared_q) begin
                                    gmem_pair_reuse_elements_q <=
                                        gmem_pair_reuse_elements_q + 64'd1;
                                    if (pair_reuse_child_direct_fire_w) begin
                                        child_outstanding_q <= 1'b1;
                                        child_requests_q <=
                                            child_requests_q + 64'd1;
                                        state_q <= ST_CHILD_WAIT;
                                    end else begin
                                        state_q <= ST_CHILD_REQ;
                                    end
                                end else if (gmem_pair_reuse_hit_w) begin
                                    lhs_bits_q <= src0_beat_reuse_word_w;
                                    rhs_bits_q <= src1_beat_reuse_word_w;
                                    gmem_pair_reuse_elements_q <=
                                        gmem_pair_reuse_elements_q + 64'd1;
                                    state_q <= ST_CHILD_REQ;
                                end else begin
                                    gmem_req_addr_q <= {
                                        selected_src0_addr_w[63:3], 3'b000
                                    };
                                    gmem_read_upper_q <=
                                        selected_src0_addr_w[2];
                                    state_q <= ST_SRC0_REQ;
                                end
                            end
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end
                    end

                    ST_DRAIN: begin
                        pair_reuse_prepared_q <= 1'b0;
                        // accepted owner 的 semantic result 已失效；这里只归还唯一
                        // response credit，冻结坐标/flags/counters/cycles。
                        if ((drain_owner_q == DRAIN_GMEM)
                                && !gmem_outstanding_q) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end else if ((drain_owner_q == DRAIN_CHILD)
                                && !child_outstanding_q) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end else if ((drain_owner_q == DRAIN_GMEM)
                                && gmem_rsp_fire_w) begin
                            gmem_outstanding_q <= 1'b0;
                            arithmetic_flags_q <= 5'b0;
                            error_code_q <= (gmem_rsp_error_i
                                             && gmem_drain_timeout_cause_w)
                                          ? ERR_GMEM_RESPONSE
                                          : drain_error_code_q;
                            state_q <= ST_ERROR;
                        end else if ((drain_owner_q == DRAIN_CHILD)
                                && child_rsp_fire_w) begin
                            child_outstanding_q <= 1'b0;
                            child_responses_q   <= child_responses_q + 64'd1;
                            arithmetic_flags_q  <= 5'b0;
                            error_code_q        <= drain_error_code_q;
                            state_q             <= ST_ERROR;
                        end else if ((drain_owner_q != DRAIN_GMEM)
                                && (drain_owner_q != DRAIN_CHILD)) begin
                            arithmetic_flags_q <= 5'b0;
                            error_code_q       <= ERR_INTERNAL_STATE;
                            state_q            <= ST_ERROR;
                        end
                    end

                    ST_DONE: begin
                        src0_beat_valid_q <= 1'b0;
                        src1_beat_valid_q <= 1'b0;
                        pair_reuse_prepared_q <= 1'b0;
                        state_q <= ST_IDLE;
                    end

                    ST_ERROR: begin
                        src0_beat_valid_q  <= 1'b0;
                        src1_beat_valid_q  <= 1'b0;
                        pair_reuse_prepared_q <= 1'b0;
                        arithmetic_flags_q <= 5'b0;
                        state_q            <= ST_IDLE;
                    end

                    default: begin
                        pair_reuse_prepared_q <= 1'b0;
                        arithmetic_flags_q <= 5'b0;
                        if (gmem_outstanding_q) begin
                            drain_owner_q      <= DRAIN_GMEM;
                            drain_error_code_q <= ERR_INTERNAL_STATE;
                            state_q            <= ST_DRAIN;
                        end else if (child_outstanding_q) begin
                            drain_owner_q      <= DRAIN_CHILD;
                            drain_error_code_q <= ERR_INTERNAL_STATE;
                            state_q            <= ST_DRAIN;
                        end else begin
                            error_code_q <= ERR_INTERNAL_STATE;
                            state_q      <= ST_ERROR;
                        end
                    end
                endcase
            end
        end
    end

endmodule

`default_nettype wire
