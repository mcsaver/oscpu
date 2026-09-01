`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Raw-copy-only lane portal for the canonical VECTOR_F32 P00--P18 family.
// Descriptor/capability/window admission is intentionally identical to
// TensorNpuVectorF32Adapter.  This module owns no GMEM transport and performs
// no arithmetic: one TensorNpuF32AluSimdCore is the sole numerical child.
//
// A read request names both raw F32 source words for every active lane.  SCALE
// has no src1 payload.  A write request names only destination words and raw
// child results.  One request group can be outstanding.  Malformed/error
// responses never reach the child; a timed-out accepted request is drained
// before ERROR is published.
module TensorNpuF32AluPortalAdapter #(
    parameter integer LANES = 8,
    parameter [31:0] MACRO_CAPABILITY_EPOCH = 32'h00000001,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd4096,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd200000000
) (
    input  wire                         clk_i,
    input  wire                         rst_i,

    input  wire                         start_valid_i,
    output wire                         start_ready_o,
    output wire                         busy_o,

    input  wire                         abi_valid_i,
    input  wire [31:0]                  kernel_id_i,
    input  wire [31:0]                  command_flags_i,
    input  wire [31:0]                  capability_epoch_i,
    input  wire [31:0]                  node_count_i,
    input  wire [63:0]                  deadline_cycles_i,
    input  wire [31:0]                  vector_op_i,
    input  wire [31:0]                  vector_flags_i,
    input  wire [63:0]                  src0_iova_i,
    input  wire [63:0]                  src1_iova_i,
    input  wire [63:0]                  src2_iova_i,
    input  wire [63:0]                  dst_iova_i,
    input  wire [63:0]                  scratch_iova_i,
    input  wire [63:0]                  element_count_i,
    input  wire [31:0]                  outer_count_i,
    input  wire [31:0]                  dtype_i,
    input  wire [63:0]                  src0_stride_i,
    input  wire [63:0]                  src1_stride_i,
    input  wire [63:0]                  src2_stride_i,
    input  wire [63:0]                  dst_stride_i,
    input  wire [31:0]                  scalar0_i,
    input  wire [31:0]                  scalar1_i,
    input  wire [31:0]                  scratch_bytes_i,
    input  wire [31:0]                  rope_position_i,

    input  wire [63:0]                  src0_window_base_i,
    input  wire [63:0]                  src0_window_size_i,
    input  wire [1:0]                   src0_window_perm_i,
    input  wire [63:0]                  src1_window_base_i,
    input  wire [63:0]                  src1_window_size_i,
    input  wire [1:0]                   src1_window_perm_i,
    input  wire [63:0]                  dst_window_base_i,
    input  wire [63:0]                  dst_window_size_i,
    input  wire [1:0]                   dst_window_perm_i,
    input  wire                         windows_generation_valid_i,

    output wire                         req_valid_o,
    input  wire                         req_ready_i,
    output wire                         req_write_o,
    output wire [LANES-1:0]             req_mask_o,
    output wire [(LANES*64)-1:0]        req_src0_addr_o,
    output wire [(LANES*64)-1:0]        req_src1_addr_o,
    output wire [(LANES*64)-1:0]        req_dst_addr_o,
    output wire [(LANES*32)-1:0]        req_wdata_o,
    input  wire                         rsp_valid_i,
    output wire                         rsp_ready_o,
    input  wire [LANES-1:0]             rsp_mask_i,
    input  wire [(LANES*32)-1:0]        rsp_src0_data_i,
    input  wire [(LANES*32)-1:0]        rsp_src1_data_i,
    input  wire                         rsp_error_i,

    output wire                         done_o,
    output wire                         error_o,
    output wire [`NPU_ERROR_W-1:0]      error_code_o,
    output wire [31:0]                  error_class_o,
    output wire [63:0]                  gmem_read_bytes_o,
    output wire [63:0]                  gmem_write_bytes_o,
    output wire [63:0]                  vector_elements_o,
    output wire [63:0]                  expected_gmem_read_bytes_o,
    output wire [63:0]                  expected_gmem_write_bytes_o,
    output wire [63:0]                  expected_vector_elements_o,
    output wire                         gmem_outstanding_o,
    output wire                         f32_start_pulse_o,

    output wire [63:0]                  portal_request_groups_o,
    output wire [63:0]                  portal_response_groups_o,
    output wire [63:0]                  portal_read_groups_o,
    output wire [63:0]                  portal_write_groups_o,
    output wire [63:0]                  input_words_o,
    output wire [63:0]                  output_words_o,
    output wire [63:0]                  read_bytes_o,
    output wire [63:0]                  write_bytes_o,
    output wire                         portal_outstanding_o
);

    localparam [4:0] ST_IDLE        = 5'd0;
    localparam [4:0] ST_CHECK       = 5'd1;
    localparam [4:0] ST_CHILD_START = 5'd2;
    localparam [4:0] ST_READ_PREP   = 5'd3;
    localparam [4:0] ST_READ_REQ    = 5'd4;
    localparam [4:0] ST_READ_WAIT   = 5'd5;
    localparam [4:0] ST_RESULT_WAIT = 5'd6;
    localparam [4:0] ST_WRITE_PREP  = 5'd7;
    localparam [4:0] ST_WRITE_REQ   = 5'd8;
    localparam [4:0] ST_WRITE_WAIT  = 5'd9;
    localparam [4:0] ST_FINAL_WAIT  = 5'd10;
    localparam [4:0] ST_DRAIN       = 5'd11;
    localparam [4:0] ST_DONE        = 5'd12;
    localparam [4:0] ST_ERROR       = 5'd13;

    localparam [31:0] KERNEL_VECTOR_F32 = 32'h514e0010;
    localparam [31:0] COMMAND_FLAGS_REPRESENTATIVE = 32'h00000010;
    localparam [31:0] COMMAND_FLAGS_CANONICAL      = 32'h00000011;
    localparam [31:0] VECTOR_OP_ADD   = 32'd1;
    localparam [31:0] VECTOR_OP_MUL   = 32'd2;
    localparam [31:0] VECTOR_OP_SUB   = 32'd3;
    localparam [31:0] VECTOR_OP_SCALE = 32'd4;
    localparam [31:0] ABI_DTYPE_F32   = 32'd1;

    localparam [31:0] ABI_ERROR_NONE       = 32'd0;
    localparam [31:0] ABI_ERROR_ABI        = 32'd1;
    localparam [31:0] ABI_ERROR_CAPABILITY = 32'd3;
    localparam [31:0] ABI_ERROR_LAYOUT     = 32'd4;
    localparam [31:0] ABI_ERROR_IOVA       = 32'd5;
    localparam [31:0] ABI_ERROR_GMEM       = 32'd6;
    localparam [31:0] ABI_ERROR_TIMEOUT    = 32'd10;
    localparam [31:0] ABI_ERROR_PROTOCOL   = 32'd11;

    localparam [3:0] PORTAL_ERR_NONE     = 4'd0;
    localparam [3:0] PORTAL_ERR_RESPONSE = 4'd1;
    localparam [3:0] PORTAL_ERR_MASK     = 4'd2;
    localparam [3:0] PORTAL_ERR_STALL    = 4'd3;
    localparam [3:0] PORTAL_ERR_COMMAND  = 4'd4;
    localparam [3:0] PORTAL_ERR_CHILD    = 4'd5;
    localparam [3:0] PORTAL_ERR_PROTOCOL = 4'd6;
    localparam [3:0] PORTAL_ERR_ADDRESS  = 4'd7;
    localparam [3:0] PORTAL_ERR_INTERNAL = 4'd8;

    localparam [31:0] STALL_TIMEOUT_LAST =
        (STALL_TIMEOUT_CYCLES <= 32'd1) ? 32'd0
                                        : STALL_TIMEOUT_CYCLES - 32'd1;
    localparam [63:0] COMMAND_TIMEOUT_LAST =
        (COMMAND_TIMEOUT_CYCLES <= 64'd1) ? 64'd0
                                          : COMMAND_TIMEOUT_CYCLES - 64'd1;
    localparam [63:0] LANES_U64 = LANES;

    generate
        if ((LANES < 1) || (LANES > 16)) begin : gen_bad_lanes
            initial $fatal(1, "F32 portal adapter LANES must be in 1..16");
        end
        if (STALL_TIMEOUT_CYCLES < 32'd2) begin : gen_bad_stall_timeout
            initial $fatal(1, "F32 portal stall timeout must be >= 2");
        end
        if (COMMAND_TIMEOUT_CYCLES < 64'd2) begin : gen_bad_command_timeout
            initial $fatal(1, "F32 portal command timeout must be >= 2");
        end
    endgenerate

    function automatic [63:0] popcount_lanes;
        input [LANES-1:0] lane_mask;
        integer count_lane;
        begin
            popcount_lanes = 64'b0;
            for (count_lane = 0; count_lane < LANES;
                 count_lane = count_lane + 1) begin
                if (lane_mask[count_lane])
                    popcount_lanes = popcount_lanes + 64'd1;
            end
        end
    endfunction

    function automatic [63:0] safe_div_u64;
        input [63:0] value;
        input [31:0] divisor;
        begin
            safe_div_u64 = (divisor == 32'b0) ? 64'b0
                                               : value / divisor;
        end
    endfunction

    function automatic [31:0] safe_mod_u64;
        input [63:0] value;
        input [31:0] divisor;
        begin
            safe_mod_u64 = (divisor == 32'b0) ? 32'b0
                                               : value % divisor;
        end
    endfunction

    reg [4:0] state_q;

    reg        abi_valid_q;
    reg [31:0] kernel_id_q;
    reg [31:0] command_flags_q;
    reg [31:0] capability_epoch_q;
    reg [31:0] node_count_q;
    reg [63:0] deadline_cycles_q;
    reg [31:0] vector_op_q;
    reg [31:0] vector_flags_q;
    reg [63:0] src0_iova_q;
    reg [63:0] src1_iova_q;
    reg [63:0] src2_iova_q;
    reg [63:0] dst_iova_q;
    reg [63:0] scratch_iova_q;
    reg [63:0] element_count_q;
    reg [31:0] outer_count_q;
    reg [31:0] dtype_q;
    reg [63:0] src0_stride_q;
    reg [63:0] src1_stride_q;
    reg [63:0] src2_stride_q;
    reg [63:0] dst_stride_q;
    reg [31:0] scalar0_q;
    reg [31:0] scalar1_q;
    reg [31:0] scratch_bytes_q;
    reg [31:0] rope_position_q;
    reg [63:0] src0_window_base_q;
    reg [63:0] src0_window_size_q;
    reg [1:0]  src0_window_perm_q;
    reg [63:0] src1_window_base_q;
    reg [63:0] src1_window_size_q;
    reg [1:0]  src1_window_perm_q;
    reg [63:0] dst_window_base_q;
    reg [63:0] dst_window_size_q;
    reg [1:0]  dst_window_perm_q;
    reg        windows_generation_valid_q;

    reg [`NPU_ERROR_W-1:0] terminal_error_code_q;
    reg [31:0] terminal_error_class_q;
    reg [63:0] terminal_vector_elements_q;
    reg [3:0]  drain_error_q;

    reg [63:0] batch_base_q;
    reg         req_write_q;
    reg [LANES-1:0] req_mask_q;
    reg [(LANES*64)-1:0] req_src0_addr_q;
    reg [(LANES*64)-1:0] req_src1_addr_q;
    reg [(LANES*64)-1:0] req_dst_addr_q;
    reg [(LANES*32)-1:0] req_wdata_q;
    reg         portal_outstanding_q;
    reg         response_armed_q;
    reg [LANES-1:0] pending_mask_q;

    reg [(LANES*32)-1:0] held_result_bits_q;
    reg [LANES-1:0] held_result_mask_q;
    reg [63:0] held_result_base_q;
    reg child_force_reset_q;

    reg [31:0] stall_cycles_q;
    reg [63:0] command_cycles_q;
    reg [63:0] portal_request_groups_q;
    reg [63:0] portal_response_groups_q;
    reg [63:0] portal_read_groups_q;
    reg [63:0] portal_write_groups_q;
    reg [63:0] input_words_q;
    reg [63:0] output_words_q;
    reg [63:0] read_bytes_q;
    reg [63:0] write_bytes_q;

    wire start_fire_w = start_valid_i && start_ready_o;
    assign start_ready_o = !rst_i && (state_q == ST_IDLE);
    assign busy_o = !rst_i && (state_q != ST_IDLE);
    assign done_o = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign error_code_o = error_o ? terminal_error_code_q : `NPU_ERR_NONE;
    assign error_class_o = error_o ? terminal_error_class_q : ABI_ERROR_NONE;

    // This branch owns no raw GMEM transport.  Portal payload accounting is
    // deliberately separate and reflects 32-bit words, not legacy beat cost.
    assign gmem_read_bytes_o = 64'b0;
    assign gmem_write_bytes_o = 64'b0;
    assign expected_gmem_read_bytes_o = 64'b0;
    assign expected_gmem_write_bytes_o = 64'b0;
    assign gmem_outstanding_o = 1'b0;
    assign vector_elements_o = terminal_vector_elements_q;

    assign portal_request_groups_o = portal_request_groups_q;
    assign portal_response_groups_o = portal_response_groups_q;
    assign portal_read_groups_o = portal_read_groups_q;
    assign portal_write_groups_o = portal_write_groups_q;
    assign input_words_o = input_words_q;
    assign output_words_o = output_words_q;
    assign read_bytes_o = read_bytes_q;
    assign write_bytes_o = write_bytes_q;
    assign portal_outstanding_o = portal_outstanding_q;

    // ---------------------------------------------------------------------
    // Exact P00--P18 capability table.  Keep this packed row byte-for-byte
    // aligned with TensorNpuVectorF32Adapter.
    // ---------------------------------------------------------------------
    reg [1220:0] profile_row_r;
    wire profile_valid_w;
    wire profile_src1_present_w;
    wire [2:0] profile_opcode_w;
    wire [31:0] profile_vector_op_w;
    wire [31:0] profile_scalar0_w;
    wire [63:0] profile_element_count_w;
    wire [63:0] profile_outer_count_w;
    wire [63:0] profile_total_elements_w;
    wire [63:0] profile_dst_stride_w;
    wire [31:0] profile_src0_ne0_w;
    wire [31:0] profile_src0_ne1_w;
    wire [31:0] profile_src0_ne2_w;
    wire [31:0] profile_src0_ne3_w;
    wire [63:0] profile_src0_nb0_w;
    wire [63:0] profile_src0_nb1_w;
    wire [63:0] profile_src0_nb2_w;
    wire [63:0] profile_src0_nb3_w;
    wire [63:0] profile_src0_view_off_w;
    wire [31:0] profile_src1_ne0_w;
    wire [31:0] profile_src1_ne1_w;
    wire [31:0] profile_src1_ne2_w;
    wire [31:0] profile_src1_ne3_w;
    wire [63:0] profile_src1_nb0_w;
    wire [63:0] profile_src1_nb1_w;
    wire [63:0] profile_src1_nb2_w;
    wire [63:0] profile_src1_nb3_w;
    wire [63:0] profile_src1_view_off_w;

    assign {
        profile_valid_w, profile_src1_present_w, profile_opcode_w,
        profile_vector_op_w, profile_scalar0_w,
        profile_element_count_w, profile_outer_count_w,
        profile_total_elements_w, profile_dst_stride_w,
        profile_src0_ne0_w, profile_src0_ne1_w,
        profile_src0_ne2_w, profile_src0_ne3_w,
        profile_src0_nb0_w, profile_src0_nb1_w,
        profile_src0_nb2_w, profile_src0_nb3_w,
        profile_src0_view_off_w,
        profile_src1_ne0_w, profile_src1_ne1_w,
        profile_src1_ne2_w, profile_src1_ne3_w,
        profile_src1_nb0_w, profile_src1_nb1_w,
        profile_src1_nb2_w, profile_src1_nb3_w,
        profile_src1_view_off_w
    } = profile_row_r;

    always @(*) begin
        profile_row_r = 1221'd0;
        case (vector_flags_q[4:0])
            5'd0: profile_row_r = {1'b1,1'b1,3'd0,VECTOR_OP_ADD,32'd0,
                64'd16,64'd1,64'd16,64'd64,
                32'd16,32'd1,32'd1,32'd1,64'd4,64'd64,64'd64,64'd64,64'd0,
                32'd16,32'd1,32'd1,32'd1,64'd4,64'd64,64'd64,64'd64,64'd0};
            5'd1, 5'd2: profile_row_r = {1'b1,1'b1,3'd0,VECTOR_OP_ADD,32'd0,
                64'd1024,64'd1,64'd1024,64'd4096,
                32'd1024,32'd1,32'd1,32'd1,64'd4,64'd4096,64'd4096,64'd4096,64'd0,
                32'd1024,32'd1,32'd1,32'd1,64'd4,64'd4096,64'd4096,64'd4096,64'd0};
            5'd3: profile_row_r = {1'b1,1'b1,3'd0,VECTOR_OP_ADD,32'd0,
                64'd128,64'd2048,64'd262144,64'd512,
                32'd128,32'd128,32'd16,32'd1,64'd4,64'd512,64'd65536,64'd1048576,64'd0,
                32'd128,32'd128,32'd16,32'd1,64'd4,64'd512,64'd65536,64'd1048576,64'd0};
            5'd4: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd16,64'd1,64'd16,64'd64,
                32'd16,32'd1,32'd1,32'd1,64'd4,64'd64,64'd64,64'd64,64'd0,
                32'd16,32'd1,32'd1,32'd1,64'd4,64'd64,64'd64,64'd64,64'd0};
            5'd5: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd1024,64'd1,64'd1024,64'd4096,
                32'd1024,32'd1,32'd1,32'd1,64'd4,64'd4096,64'd4096,64'd4096,64'd0,
                32'd1024,32'd1,32'd1,32'd1,64'd4,64'd4096,64'd4096,64'd4096,64'd0};
            5'd6: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd128,64'd2048,64'd262144,64'd512,
                32'd128,32'd128,32'd16,32'd1,64'd4,64'd512,64'd65536,64'd1048576,64'd0,
                32'd128,32'd1,32'd16,32'd1,64'd4,64'd8192,64'd512,64'd8192,64'd0};
            5'd7: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd128,64'd16,64'd2048,64'd512,
                32'd128,32'd1,32'd16,32'd1,64'd4,64'd512,64'd512,64'd8192,64'd0,
                32'd1,32'd1,32'd16,32'd1,64'd4,64'd4,64'd4,64'd64,64'd0};
            5'd8: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd128,64'd2048,64'd262144,64'd512,
                32'd128,32'd128,32'd16,32'd1,64'd4,64'd512,64'd65536,64'd1048576,64'd0,
                32'd1,32'd128,32'd16,32'd1,64'd512,64'd4,64'd512,64'd8192,64'd0};
            5'd9: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd128,64'd2048,64'd262144,64'd512,
                32'd128,32'd128,32'd16,32'd1,64'd4,64'd512,64'd65536,64'd1048576,64'd0,
                32'd1,32'd1,32'd16,32'd1,64'd4,64'd4,64'd4,64'd64,64'd0};
            5'd10: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd128,64'd16,64'd2048,64'd512,
                32'd128,32'd16,32'd1,32'd1,64'd4,64'd512,64'd8192,64'd8192,64'd0,
                32'd128,32'd1,32'd1,32'd1,64'd4,64'd512,64'd512,64'd512,64'd0};
            5'd11: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd128,64'd16,64'd2048,64'd512,
                32'd128,32'd16,32'd1,32'd1,64'd4,64'd512,64'd8192,64'd8192,64'd0,
                32'd128,32'd16,32'd1,32'd1,64'd4,64'd512,64'd8192,64'd8192,64'd0};
            5'd12: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd2048,64'd1,64'd2048,64'd8192,
                32'd2048,32'd1,32'd1,32'd1,64'd4,64'd8192,64'd8192,64'd8192,64'd0,
                32'd2048,32'd1,32'd1,32'd1,64'd4,64'd8192,64'd8192,64'd8192,64'd0};
            5'd13: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd256,64'd2,64'd512,64'd1024,
                32'd256,32'd2,32'd1,32'd1,64'd4,64'd1024,64'd2048,64'd2048,64'd0,
                32'd256,32'd1,32'd1,32'd1,64'd4,64'd1024,64'd1024,64'd1024,64'd0};
            5'd14: profile_row_r = {1'b1,1'b1,3'd1,VECTOR_OP_MUL,32'd0,
                64'd256,64'd8,64'd2048,64'd1024,
                32'd256,32'd8,32'd1,32'd1,64'd4,64'd1024,64'd8192,64'd8192,64'd0,
                32'd256,32'd1,32'd1,32'd1,64'd4,64'd1024,64'd1024,64'd1024,64'd0};
            5'd15: profile_row_r = {1'b1,1'b1,3'd2,VECTOR_OP_SUB,32'd0,
                64'd128,64'd16,64'd2048,64'd512,
                32'd128,32'd1,32'd16,32'd1,64'd4,64'd24576,64'd512,64'd24576,64'd16384,
                32'd128,32'd1,32'd16,32'd1,64'd4,64'd4,64'd512,64'd8192,64'd0};
            5'd16: profile_row_r = {1'b1,1'b0,3'd3,VECTOR_OP_SCALE,32'h3db504f3,
                64'd128,64'd16,64'd2048,64'd512,
                32'd128,32'd16,32'd1,32'd1,64'd4,64'd512,64'd8192,64'd8192,64'd0,
                32'd0,32'd0,32'd0,32'd0,64'd0,64'd0,64'd0,64'd0,64'd0};
            5'd17: profile_row_r = {1'b1,1'b0,3'd3,VECTOR_OP_SCALE,32'd0,
                64'd18432,64'd1,64'd18432,64'd73728,
                32'd18432,32'd1,32'd1,32'd1,64'd4,64'd73728,64'd73728,64'd73728,64'd0,
                32'd0,32'd0,32'd0,32'd0,64'd0,64'd0,64'd0,64'd0,64'd0};
            5'd18: profile_row_r = {1'b1,1'b0,3'd3,VECTOR_OP_SCALE,32'd0,
                64'd262144,64'd1,64'd262144,64'd1048576,
                32'd262144,32'd1,32'd1,32'd1,64'd4,64'd1048576,64'd1048576,64'd1048576,64'd0,
                32'd0,32'd0,32'd0,32'd0,64'd0,64'd0,64'd0,64'd0,64'd0};
            default: profile_row_r = 1221'd0;
        endcase
    end

    wire [127:0] src0_logical_hi_ext_w;
    wire [127:0] src1_logical_hi_ext_w;
    wire [127:0] src0_beat_lo_ext_w;
    wire [127:0] src1_beat_lo_ext_w;
    wire [127:0] src0_beat_hi_ext_w;
    wire [127:0] src1_beat_hi_ext_w;
    wire [127:0] src0_iova_ext_w;
    wire [127:0] src1_iova_ext_w;
    wire [127:0] src0_actual_start_ext_w;
    wire [127:0] src0_actual_end_ext_w;
    wire [127:0] src1_actual_start_ext_w;
    wire [127:0] src1_actual_end_ext_w;
    wire [127:0] dst_size_ext_w;
    wire [127:0] dst_end_ext_w;
    wire [127:0] dst_nb1_ext_w;
    wire [127:0] dst_nb2_ext_w;
    wire [127:0] dst_nb3_ext_w;
    assign src0_logical_hi_ext_w = profile_valid_w ?
        ({64'd0, profile_src0_view_off_w} +
         ({96'd0, (profile_src0_ne0_w - 32'd1)} * {64'd0, profile_src0_nb0_w}) +
         ({96'd0, (profile_src0_ne1_w - 32'd1)} * {64'd0, profile_src0_nb1_w}) +
         ({96'd0, (profile_src0_ne2_w - 32'd1)} * {64'd0, profile_src0_nb2_w}) +
         ({96'd0, (profile_src0_ne3_w - 32'd1)} * {64'd0, profile_src0_nb3_w}) + 128'd4) : 128'd0;
    assign src1_logical_hi_ext_w = profile_src1_present_w ?
        ({64'd0, profile_src1_view_off_w} +
         ({96'd0, (profile_src1_ne0_w - 32'd1)} * {64'd0, profile_src1_nb0_w}) +
         ({96'd0, (profile_src1_ne1_w - 32'd1)} * {64'd0, profile_src1_nb1_w}) +
         ({96'd0, (profile_src1_ne2_w - 32'd1)} * {64'd0, profile_src1_nb2_w}) +
         ({96'd0, (profile_src1_ne3_w - 32'd1)} * {64'd0, profile_src1_nb3_w}) + 128'd4) : 128'd0;
    assign src0_beat_lo_ext_w = {64'd0, (profile_src0_view_off_w & 64'hfffffffffffffff8)};
    assign src1_beat_lo_ext_w = {64'd0, (profile_src1_view_off_w & 64'hfffffffffffffff8)};
    assign src0_beat_hi_ext_w = ((src0_logical_hi_ext_w + 128'd7) >> 3) << 3;
    assign src1_beat_hi_ext_w = profile_src1_present_w ?
        (((src1_logical_hi_ext_w + 128'd7) >> 3) << 3) : 128'd0;
    assign src0_iova_ext_w = {64'd0, src0_window_base_q} + {64'd0, profile_src0_view_off_w};
    assign src1_iova_ext_w = {64'd0, src1_window_base_q} + {64'd0, profile_src1_view_off_w};
    assign src0_actual_start_ext_w = {64'd0, src0_window_base_q} + src0_beat_lo_ext_w;
    assign src0_actual_end_ext_w = {64'd0, src0_window_base_q} + src0_beat_hi_ext_w;
    assign src1_actual_start_ext_w = {64'd0, src1_window_base_q} + src1_beat_lo_ext_w;
    assign src1_actual_end_ext_w = {64'd0, src1_window_base_q} + src1_beat_hi_ext_w;
    assign dst_size_ext_w = {64'd0, profile_total_elements_w} * 128'd4;
    assign dst_end_ext_w = {64'd0, dst_window_base_q} + dst_size_ext_w;
    assign dst_nb1_ext_w = {96'd0, profile_src0_ne0_w} * 128'd4;
    assign dst_nb2_ext_w = dst_nb1_ext_w * {96'd0, profile_src0_ne1_w};
    assign dst_nb3_ext_w = dst_nb2_ext_w * {96'd0, profile_src0_ne2_w};

    assign expected_vector_elements_o = profile_valid_w ?
                                        profile_total_elements_w : 64'd0;

    wire abi_reject_w;
    wire capability_reject_w;
    wire layout_reject_w;
    wire iova_reject_w;
    wire src0_dst_disjoint_w;
    wire src1_dst_disjoint_w;
    assign abi_reject_w = !abi_valid_q;
    assign capability_reject_w =
        (kernel_id_q != KERNEL_VECTOR_F32) ||
        ((command_flags_q != COMMAND_FLAGS_REPRESENTATIVE) &&
         (command_flags_q != COMMAND_FLAGS_CANONICAL)) ||
        (capability_epoch_q != MACRO_CAPABILITY_EPOCH) ||
        (node_count_q != 32'd1) ||
        (deadline_cycles_q != 64'd0);
    assign layout_reject_w =
        !profile_valid_w || (vector_flags_q[31:5] != 27'd0) ||
        (vector_op_q != profile_vector_op_w) ||
        (src2_iova_q != 64'd0) || (scratch_iova_q != 64'd0) ||
        (element_count_q != profile_element_count_w) ||
        (profile_outer_count_w[63:32] != 32'd0) ||
        (outer_count_q != profile_outer_count_w[31:0]) ||
        (dtype_q != ABI_DTYPE_F32) ||
        (src0_stride_q != profile_src0_nb1_w) ||
        (src1_stride_q != (profile_src1_present_w ? profile_src1_nb1_w : 64'd0)) ||
        (src2_stride_q != 64'd0) ||
        (dst_stride_q != profile_dst_stride_w) ||
        (scalar0_q != profile_scalar0_w) || (scalar1_q != 32'd0) ||
        (scratch_bytes_q != 32'd0) || (rope_position_q != 32'd0);
    assign src0_dst_disjoint_w =
        (src0_actual_end_ext_w <= {64'd0, dst_window_base_q}) ||
        (dst_end_ext_w <= src0_actual_start_ext_w);
    assign src1_dst_disjoint_w = !profile_src1_present_w ||
        (src1_actual_end_ext_w <= {64'd0, dst_window_base_q}) ||
        (dst_end_ext_w <= src1_actual_start_ext_w);
    assign iova_reject_w =
        !windows_generation_valid_q ||
        (src0_window_perm_q != 2'b01) ||
        (src1_window_perm_q != (profile_src1_present_w ? 2'b01 : 2'b00)) ||
        (dst_window_perm_q != 2'b10) ||
        (src0_window_base_q[2:0] != 3'b000) ||
        (dst_window_base_q[2:0] != 3'b000) ||
        (src0_iova_ext_w[127:64] != 64'd0) ||
        (src0_iova_q != src0_iova_ext_w[63:0]) ||
        (src0_iova_q[1:0] != 2'b00) ||
        (src0_logical_hi_ext_w[127:64] != 64'd0) ||
        (src0_beat_hi_ext_w[127:64] != 64'd0) ||
        (src0_window_size_q != src0_beat_hi_ext_w[63:0]) ||
        (src0_actual_start_ext_w[127:64] != 64'd0) ||
        (src0_actual_end_ext_w[127:64] != 64'd0) ||
        (dst_size_ext_w[127:64] != 64'd0) ||
        (dst_nb3_ext_w[127:64] != 64'd0) ||
        (dst_window_size_q != dst_size_ext_w[63:0]) ||
        (dst_iova_q != dst_window_base_q) ||
        (dst_iova_q[2:0] != 3'b000) ||
        (dst_end_ext_w[127:64] != 64'd0) || !src0_dst_disjoint_w ||
        (profile_src1_present_w ?
            ((src1_window_base_q[2:0] != 3'b000) ||
             (src1_iova_ext_w[127:64] != 64'd0) ||
             (src1_iova_q != src1_iova_ext_w[63:0]) ||
             (src1_iova_q[1:0] != 2'b00) ||
             (src1_logical_hi_ext_w[127:64] != 64'd0) ||
             (src1_beat_hi_ext_w[127:64] != 64'd0) ||
             (src1_window_size_q != src1_beat_hi_ext_w[63:0]) ||
             (src1_actual_start_ext_w[127:64] != 64'd0) ||
             (src1_actual_end_ext_w[127:64] != 64'd0) ||
             !src1_dst_disjoint_w) :
            ((src1_iova_q != 64'd0) ||
             (src1_window_base_q != 64'd0) ||
             (src1_window_size_q != 64'd0) ||
             (src1_stride_q != 64'd0)));

    // ---------------------------------------------------------------------
    // Parallel 4-D address generator.  Lane k always names flat index
    // batch_base_q+k.  Source-1 coordinates use exact per-dimension modulo.
    // ---------------------------------------------------------------------
    wire [LANES-1:0] candidate_mask_w;
    wire [(LANES*64)-1:0] candidate_src0_addr_w;
    wire [(LANES*64)-1:0] candidate_src1_addr_w;
    wire [(LANES*64)-1:0] candidate_dst_addr_w;
    wire [LANES-1:0] candidate_address_ok_w;

    genvar address_lane;
    generate
        for (address_lane = 0; address_lane < LANES;
             address_lane = address_lane + 1) begin : gen_address
            localparam [64:0] LANE_OFFSET = address_lane;
            wire [64:0] flat_ext_w;
            wire [63:0] flat_w;
            wire [63:0] div0_w;
            wire [63:0] div1_w;
            wire [63:0] div2_w;
            wire [31:0] coord0_w;
            wire [31:0] coord1_w;
            wire [31:0] coord2_w;
            wire [31:0] coord3_w;
            wire [31:0] src1_coord0_w;
            wire [31:0] src1_coord1_w;
            wire [31:0] src1_coord2_w;
            wire [31:0] src1_coord3_w;
            wire [127:0] src0_addr_ext_w;
            wire [127:0] src1_addr_ext_w;
            wire [127:0] dst_addr_ext_w;
            wire [127:0] src0_word_end_ext_w;
            wire [127:0] src1_word_end_ext_w;
            wire [127:0] dst_word_end_ext_w;

            assign flat_ext_w = {1'b0, batch_base_q} + LANE_OFFSET;
            assign flat_w = flat_ext_w[63:0];
            assign candidate_mask_w[address_lane] =
                flat_ext_w < {1'b0, profile_total_elements_w};
            assign coord0_w = safe_mod_u64(flat_w, profile_src0_ne0_w);
            assign div0_w = safe_div_u64(flat_w, profile_src0_ne0_w);
            assign coord1_w = safe_mod_u64(div0_w, profile_src0_ne1_w);
            assign div1_w = safe_div_u64(div0_w, profile_src0_ne1_w);
            assign coord2_w = safe_mod_u64(div1_w, profile_src0_ne2_w);
            assign div2_w = safe_div_u64(div1_w, profile_src0_ne2_w);
            assign coord3_w = safe_mod_u64(div2_w, profile_src0_ne3_w);

            assign src1_coord0_w = safe_mod_u64(
                {32'b0, coord0_w}, profile_src1_ne0_w);
            assign src1_coord1_w = safe_mod_u64(
                {32'b0, coord1_w}, profile_src1_ne1_w);
            assign src1_coord2_w = safe_mod_u64(
                {32'b0, coord2_w}, profile_src1_ne2_w);
            assign src1_coord3_w = safe_mod_u64(
                {32'b0, coord3_w}, profile_src1_ne3_w);

            assign src0_addr_ext_w = {64'b0, src0_window_base_q}
                + {64'b0, profile_src0_view_off_w}
                + ({96'b0, coord0_w} * {64'b0, profile_src0_nb0_w})
                + ({96'b0, coord1_w} * {64'b0, profile_src0_nb1_w})
                + ({96'b0, coord2_w} * {64'b0, profile_src0_nb2_w})
                + ({96'b0, coord3_w} * {64'b0, profile_src0_nb3_w});
            assign src1_addr_ext_w = {64'b0, src1_window_base_q}
                + {64'b0, profile_src1_view_off_w}
                + ({96'b0, src1_coord0_w} * {64'b0, profile_src1_nb0_w})
                + ({96'b0, src1_coord1_w} * {64'b0, profile_src1_nb1_w})
                + ({96'b0, src1_coord2_w} * {64'b0, profile_src1_nb2_w})
                + ({96'b0, src1_coord3_w} * {64'b0, profile_src1_nb3_w});
            assign dst_addr_ext_w = {64'b0, dst_window_base_q}
                                  + ({64'b0, flat_w} * 128'd4);
            assign src0_word_end_ext_w = src0_addr_ext_w + 128'd4;
            assign src1_word_end_ext_w = src1_addr_ext_w + 128'd4;
            assign dst_word_end_ext_w = dst_addr_ext_w + 128'd4;

            assign candidate_src0_addr_w[(address_lane*64) +: 64] =
                candidate_mask_w[address_lane] ? src0_addr_ext_w[63:0]
                                               : 64'b0;
            assign candidate_src1_addr_w[(address_lane*64) +: 64] =
                (candidate_mask_w[address_lane]
                 && profile_src1_present_w) ? src1_addr_ext_w[63:0]
                                           : 64'b0;
            assign candidate_dst_addr_w[(address_lane*64) +: 64] =
                candidate_mask_w[address_lane] ? dst_addr_ext_w[63:0]
                                               : 64'b0;
            assign candidate_address_ok_w[address_lane] =
                !candidate_mask_w[address_lane]
                || ((src0_addr_ext_w[127:64] == 64'b0)
                    && (src0_addr_ext_w[1:0] == 2'b0)
                    && (src0_addr_ext_w >= src0_actual_start_ext_w)
                    && (src0_word_end_ext_w <= src0_actual_end_ext_w)
                    && (dst_addr_ext_w[127:64] == 64'b0)
                    && (dst_addr_ext_w[1:0] == 2'b0)
                    && (dst_addr_ext_w >= {64'b0, dst_window_base_q})
                    && (dst_word_end_ext_w <= dst_end_ext_w)
                    && (!profile_src1_present_w
                        || ((src1_addr_ext_w[127:64] == 64'b0)
                            && (src1_addr_ext_w[1:0] == 2'b0)
                            && (src1_addr_ext_w
                                >= src1_actual_start_ext_w)
                            && (src1_word_end_ext_w
                                <= src1_actual_end_ext_w))));
        end
    endgenerate

    wire candidate_group_ok_w = (|candidate_mask_w)
                              && (&candidate_address_ok_w);

    assign req_valid_o = !rst_i && !portal_outstanding_q
                       && !rsp_valid_i
                       && !command_timeout_hit_w
                       && ((state_q == ST_READ_REQ)
                           || (state_q == ST_WRITE_REQ));
    assign req_write_o = req_write_q;
    assign req_mask_o = req_mask_q;
    assign req_src0_addr_o = req_src0_addr_q;
    assign req_src1_addr_o = req_src1_addr_q;
    assign req_dst_addr_o = req_dst_addr_q;
    assign req_wdata_o = req_wdata_q;
    wire req_fire_w = req_valid_o && req_ready_i;

    wire rsp_mask_match_w = (rsp_mask_i == pending_mask_q);
    wire rsp_fire_w = rsp_valid_i && rsp_ready_o;

    // ---------------------------------------------------------------------
    // Sole numerical child.
    // ---------------------------------------------------------------------
    wire child_rst_w = rst_i || child_force_reset_q
                     || (state_q == ST_IDLE) || (state_q == ST_CHECK)
                     || (state_q == ST_DRAIN) || (state_q == ST_DONE)
                     || (state_q == ST_ERROR);
    wire child_ready_w;
    wire child_busy_w;
    wire child_start_w = (state_q == ST_CHILD_START)
                       && !command_timeout_hit_w;
    wire child_start_fire_w = child_start_w && child_ready_w;
    assign f32_start_pulse_o = child_start_fire_w;

    wire child_input_ready_w;
    wire child_input_valid_w = (state_q == ST_READ_WAIT)
                             && portal_outstanding_q
                             && response_armed_q
                             && rsp_valid_i && rsp_mask_match_w
                             && !rsp_error_i
                             && !command_timeout_hit_w
                             && !stall_timeout_hit_w;
    wire child_input_fire_w = child_input_valid_w && child_input_ready_w;
    wire child_result_valid_w;
    wire child_result_ready_w;
    wire [(LANES*32)-1:0] child_result_bits_w;
    wire [LANES-1:0] child_result_mask_w;
    wire [63:0] child_result_base_w;
    wire child_done_w;
    wire child_error_w;
    wire [7:0] child_error_code_w;
    wire [63:0] child_error_index_w;
    wire [4:0] child_flags_w;
    wire [63:0] child_input_batches_w;
    wire [63:0] child_requests_w;
    wire [63:0] child_responses_w;
    wire [63:0] child_elements_w;
    wire [63:0] child_active_cycles_w;

    wire held_result_match_w = child_result_valid_w
                             && (child_result_bits_w
                                 == held_result_bits_q)
                             && (child_result_mask_w
                                 == held_result_mask_q)
                             && (child_result_base_w
                                 == held_result_base_q);
    wire current_result_metadata_ok_w = child_result_valid_w
                                      && (child_result_mask_w
                                          == candidate_mask_w)
                                      && (child_result_base_w
                                          == batch_base_q);

    assign child_result_ready_w = (state_q == ST_WRITE_WAIT)
                                && portal_outstanding_q
                                && response_armed_q
                                && rsp_valid_i && rsp_mask_match_w
                                && !rsp_error_i
                                && held_result_match_w
                                && !command_timeout_hit_w
                                && !stall_timeout_hit_w;

    TensorNpuF32AluSimdCore #(
        .LANES(LANES)
    ) u_f32_alu_simd_core (
        .clk_i                (clk_i),
        .rst_i                (child_rst_w),
        .start_i              (child_start_w),
        .ready_o              (child_ready_w),
        .busy_o               (child_busy_w),
        .opcode_i             (profile_opcode_w),
        .element_count_i      (profile_total_elements_w),
        .scale_bits_i         (scalar0_q),
        .input_batch_valid_i  (child_input_valid_w),
        .input_batch_ready_o  (child_input_ready_w),
        .lhs_bits_i           (rsp_src0_data_i),
        .rhs_bits_i           (rsp_src1_data_i),
        .mask_i               (pending_mask_q),
        .base_index_i         (batch_base_q),
        .result_batch_valid_o (child_result_valid_w),
        .result_batch_ready_i (child_result_ready_w),
        .result_bits_o        (child_result_bits_w),
        .result_mask_o        (child_result_mask_w),
        .result_base_index_o  (child_result_base_w),
        .done_o               (child_done_w),
        .error_o              (child_error_w),
        .error_code_o         (child_error_code_w),
        .error_index_o        (child_error_index_w),
        .flags_or_o           (child_flags_w),
        .input_batches_o      (child_input_batches_w),
        .child_requests_o     (child_requests_w),
        .child_responses_o    (child_responses_w),
        .elements_emitted_o   (child_elements_w),
        .active_cycles_o      (child_active_cycles_w)
    );

    // Correct responses are accepted only when their direct consumer can
    // fire.  The one-cycle response arm makes same-cycle request/response
    // impossible and gives the upstream a real valid-hold interval.
    assign rsp_ready_o = !rst_i && portal_outstanding_q
                       && ((state_q == ST_DRAIN)
                           || ((state_q == ST_READ_WAIT)
                               && (rsp_error_i || !rsp_mask_match_w
                                   || command_timeout_hit_w
                                   || stall_timeout_hit_w
                                   || (response_armed_q
                                       && child_input_ready_w)))
                           || ((state_q == ST_WRITE_WAIT)
                               && (rsp_error_i || !rsp_mask_match_w
                                   || command_timeout_hit_w
                                   || stall_timeout_hit_w
                                   || (response_armed_q
                                       && held_result_match_w))));

    wire unexpected_rsp_w = rsp_valid_i && !portal_outstanding_q
                          && (state_q != ST_IDLE) && (state_q != ST_CHECK)
                          && (state_q != ST_DONE) && (state_q != ST_ERROR);
    wire result_hold_state_w = (state_q == ST_WRITE_PREP)
                             || (state_q == ST_WRITE_REQ)
                             || (state_q == ST_WRITE_WAIT);
    wire child_result_protocol_w = child_result_valid_w
                                 && (state_q != ST_RESULT_WAIT)
                                 && !result_hold_state_w;
    wire held_result_protocol_w = result_hold_state_w
                                && !held_result_match_w;
    wire child_done_protocol_w = child_done_w
                               && (state_q != ST_FINAL_WAIT);

    reg progress_event_r;
    always @(*) begin
        progress_event_r = 1'b0;
        case (state_q)
            ST_CHECK:       progress_event_r = 1'b1;
            ST_CHILD_START: progress_event_r = child_start_fire_w;
            ST_READ_PREP:   progress_event_r = 1'b1;
            ST_READ_REQ:    progress_event_r = req_fire_w;
            ST_READ_WAIT:   progress_event_r = !response_armed_q
                                             || rsp_fire_w;
            ST_RESULT_WAIT: progress_event_r = child_result_valid_w
                                             || child_error_w;
            ST_WRITE_PREP:  progress_event_r = 1'b1;
            ST_WRITE_REQ:   progress_event_r = req_fire_w;
            ST_WRITE_WAIT:  progress_event_r = !response_armed_q
                                             || rsp_fire_w;
            ST_FINAL_WAIT:  progress_event_r = child_done_w
                                             || child_error_w;
            default:        progress_event_r = 1'b0;
        endcase
    end

    wire command_active_w = (state_q != ST_IDLE) && (state_q != ST_DONE)
                          && (state_q != ST_ERROR) && (state_q != ST_DRAIN);
    wire command_timeout_hit_w = command_active_w
                               && (command_cycles_q
                                   >= COMMAND_TIMEOUT_LAST);
    wire stall_timeout_hit_w = command_active_w && !progress_event_r
                             && (stall_cycles_q >= STALL_TIMEOUT_LAST);

    wire [63:0] batch_words_w = popcount_lanes(pending_mask_q);
    wire [63:0] read_words_per_element_w = profile_src1_present_w
                                         ? 64'd2 : 64'd1;
    wire [63:0] expected_groups_w =
        (profile_total_elements_w + LANES_U64 - 64'd1) / LANES_U64;
    wire [63:0] expected_input_words_w = profile_total_elements_w
                                       * read_words_per_element_w;
    wire [63:0] expected_read_bytes_w = expected_input_words_w << 2;
    wire [63:0] expected_write_bytes_w = profile_total_elements_w << 2;
    wire exact_success_counts_w =
           (portal_request_groups_q == (expected_groups_w << 1))
        && (portal_response_groups_q == (expected_groups_w << 1))
        && (portal_read_groups_q == expected_groups_w)
        && (portal_write_groups_q == expected_groups_w)
        && (input_words_q == expected_input_words_w)
        && (output_words_q == profile_total_elements_w)
        && (read_bytes_q == expected_read_bytes_w)
        && (write_bytes_q == expected_write_bytes_w)
        && (child_input_batches_w == expected_groups_w)
        && (child_requests_w == profile_total_elements_w)
        && (child_responses_w == profile_total_elements_w)
        && (child_elements_w == profile_total_elements_w)
        && !portal_outstanding_q;

    task automatic set_portal_error;
        input [3:0] portal_error;
        begin
            drain_error_q <= portal_error;
            terminal_vector_elements_q <= output_words_q;
            child_force_reset_q <= 1'b1;
            case (portal_error)
                PORTAL_ERR_RESPONSE: begin
                    terminal_error_code_q <= `NPU_ERR_GMEM_RESPONSE;
                    terminal_error_class_q <= ABI_ERROR_GMEM;
                end
                PORTAL_ERR_STALL,
                PORTAL_ERR_COMMAND: begin
                    terminal_error_code_q <= `NPU_ERR_MACRO_TIMEOUT;
                    terminal_error_class_q <= ABI_ERROR_TIMEOUT;
                end
                PORTAL_ERR_ADDRESS: begin
                    terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
                    terminal_error_class_q <= ABI_ERROR_IOVA;
                end
                default: begin
                    terminal_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
                    terminal_error_class_q <= ABI_ERROR_PROTOCOL;
                end
            endcase
        end
    endtask

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            abi_valid_q <= 1'b0;
            kernel_id_q <= 32'b0;
            command_flags_q <= 32'b0;
            capability_epoch_q <= 32'b0;
            node_count_q <= 32'b0;
            deadline_cycles_q <= 64'b0;
            vector_op_q <= 32'b0;
            vector_flags_q <= 32'b0;
            src0_iova_q <= 64'b0;
            src1_iova_q <= 64'b0;
            src2_iova_q <= 64'b0;
            dst_iova_q <= 64'b0;
            scratch_iova_q <= 64'b0;
            element_count_q <= 64'b0;
            outer_count_q <= 32'b0;
            dtype_q <= 32'b0;
            src0_stride_q <= 64'b0;
            src1_stride_q <= 64'b0;
            src2_stride_q <= 64'b0;
            dst_stride_q <= 64'b0;
            scalar0_q <= 32'b0;
            scalar1_q <= 32'b0;
            scratch_bytes_q <= 32'b0;
            rope_position_q <= 32'b0;
            src0_window_base_q <= 64'b0;
            src0_window_size_q <= 64'b0;
            src0_window_perm_q <= 2'b0;
            src1_window_base_q <= 64'b0;
            src1_window_size_q <= 64'b0;
            src1_window_perm_q <= 2'b0;
            dst_window_base_q <= 64'b0;
            dst_window_size_q <= 64'b0;
            dst_window_perm_q <= 2'b0;
            windows_generation_valid_q <= 1'b0;
            terminal_error_code_q <= `NPU_ERR_NONE;
            terminal_error_class_q <= ABI_ERROR_NONE;
            terminal_vector_elements_q <= 64'b0;
            drain_error_q <= PORTAL_ERR_NONE;
            batch_base_q <= 64'b0;
            req_write_q <= 1'b0;
            req_mask_q <= {LANES{1'b0}};
            req_src0_addr_q <= {(LANES*64){1'b0}};
            req_src1_addr_q <= {(LANES*64){1'b0}};
            req_dst_addr_q <= {(LANES*64){1'b0}};
            req_wdata_q <= {(LANES*32){1'b0}};
            portal_outstanding_q <= 1'b0;
            response_armed_q <= 1'b0;
            pending_mask_q <= {LANES{1'b0}};
            held_result_bits_q <= {(LANES*32){1'b0}};
            held_result_mask_q <= {LANES{1'b0}};
            held_result_base_q <= 64'b0;
            child_force_reset_q <= 1'b0;
            stall_cycles_q <= 32'b0;
            command_cycles_q <= 64'b0;
            portal_request_groups_q <= 64'b0;
            portal_response_groups_q <= 64'b0;
            portal_read_groups_q <= 64'b0;
            portal_write_groups_q <= 64'b0;
            input_words_q <= 64'b0;
            output_words_q <= 64'b0;
            read_bytes_q <= 64'b0;
            write_bytes_q <= 64'b0;
        end else begin
            if (command_active_w) begin
                if (command_cycles_q != 64'hffff_ffff_ffff_ffff)
                    command_cycles_q <= command_cycles_q + 64'd1;
                if (progress_event_r)
                    stall_cycles_q <= 32'b0;
                else if (stall_cycles_q != 32'hffff_ffff)
                    stall_cycles_q <= stall_cycles_q + 32'd1;
            end

            if (req_fire_w) begin
                portal_outstanding_q <= 1'b1;
                response_armed_q <= 1'b0;
                pending_mask_q <= req_mask_q;
                portal_request_groups_q <= portal_request_groups_q + 64'd1;
                if (req_write_q)
                    portal_write_groups_q <= portal_write_groups_q + 64'd1;
                else
                    portal_read_groups_q <= portal_read_groups_q + 64'd1;
            end
            if (rsp_fire_w) begin
                portal_outstanding_q <= 1'b0;
                response_armed_q <= 1'b0;
                portal_response_groups_q <= portal_response_groups_q + 64'd1;
            end

            if ((state_q == ST_READ_WAIT)
                    || (state_q == ST_WRITE_WAIT)) begin
                if (!response_armed_q)
                    response_armed_q <= 1'b1;
            end

            if (state_q == ST_DRAIN) begin
                stall_cycles_q <= 32'b0;
                if (!portal_outstanding_q) begin
                    terminal_vector_elements_q <= output_words_q;
                    state_q <= ST_ERROR;
                end else if (rsp_fire_w) begin
                    if (rsp_error_i)
                        set_portal_error(PORTAL_ERR_RESPONSE);
                    else if (!rsp_mask_match_w)
                        set_portal_error(PORTAL_ERR_MASK);
                    else
                        set_portal_error(drain_error_q);
                    state_q <= ST_ERROR;
                end
            end else if (state_q == ST_IDLE) begin
                child_force_reset_q <= 1'b0;
                if (start_fire_w) begin
                    abi_valid_q <= abi_valid_i;
                    kernel_id_q <= kernel_id_i;
                    command_flags_q <= command_flags_i;
                    capability_epoch_q <= capability_epoch_i;
                    node_count_q <= node_count_i;
                    deadline_cycles_q <= deadline_cycles_i;
                    vector_op_q <= vector_op_i;
                    vector_flags_q <= vector_flags_i;
                    src0_iova_q <= src0_iova_i;
                    src1_iova_q <= src1_iova_i;
                    src2_iova_q <= src2_iova_i;
                    dst_iova_q <= dst_iova_i;
                    scratch_iova_q <= scratch_iova_i;
                    element_count_q <= element_count_i;
                    outer_count_q <= outer_count_i;
                    dtype_q <= dtype_i;
                    src0_stride_q <= src0_stride_i;
                    src1_stride_q <= src1_stride_i;
                    src2_stride_q <= src2_stride_i;
                    dst_stride_q <= dst_stride_i;
                    scalar0_q <= scalar0_i;
                    scalar1_q <= scalar1_i;
                    scratch_bytes_q <= scratch_bytes_i;
                    rope_position_q <= rope_position_i;
                    src0_window_base_q <= src0_window_base_i;
                    src0_window_size_q <= src0_window_size_i;
                    src0_window_perm_q <= src0_window_perm_i;
                    src1_window_base_q <= src1_window_base_i;
                    src1_window_size_q <= src1_window_size_i;
                    src1_window_perm_q <= src1_window_perm_i;
                    dst_window_base_q <= dst_window_base_i;
                    dst_window_size_q <= dst_window_size_i;
                    dst_window_perm_q <= dst_window_perm_i;
                    windows_generation_valid_q <= windows_generation_valid_i;
                    terminal_error_code_q <= `NPU_ERR_NONE;
                    terminal_error_class_q <= ABI_ERROR_NONE;
                    terminal_vector_elements_q <= 64'b0;
                    drain_error_q <= PORTAL_ERR_NONE;
                    batch_base_q <= 64'b0;
                    req_write_q <= 1'b0;
                    req_mask_q <= {LANES{1'b0}};
                    req_src0_addr_q <= {(LANES*64){1'b0}};
                    req_src1_addr_q <= {(LANES*64){1'b0}};
                    req_dst_addr_q <= {(LANES*64){1'b0}};
                    req_wdata_q <= {(LANES*32){1'b0}};
                    portal_outstanding_q <= 1'b0;
                    response_armed_q <= 1'b0;
                    pending_mask_q <= {LANES{1'b0}};
                    held_result_bits_q <= {(LANES*32){1'b0}};
                    held_result_mask_q <= {LANES{1'b0}};
                    held_result_base_q <= 64'b0;
                    stall_cycles_q <= 32'b0;
                    command_cycles_q <= 64'b0;
                    portal_request_groups_q <= 64'b0;
                    portal_response_groups_q <= 64'b0;
                    portal_read_groups_q <= 64'b0;
                    portal_write_groups_q <= 64'b0;
                    input_words_q <= 64'b0;
                    output_words_q <= 64'b0;
                    read_bytes_q <= 64'b0;
                    write_bytes_q <= 64'b0;
                    state_q <= ST_CHECK;
                end
            end else if (state_q == ST_DONE) begin
                state_q <= ST_IDLE;
            end else if (state_q == ST_ERROR) begin
                state_q <= ST_IDLE;
            end else if (unexpected_rsp_w) begin
                set_portal_error(PORTAL_ERR_PROTOCOL);
                state_q <= (portal_outstanding_q || req_fire_w)
                         ? ST_DRAIN : ST_ERROR;
            end else if (rsp_fire_w && rsp_error_i) begin
                set_portal_error(PORTAL_ERR_RESPONSE);
                state_q <= ST_ERROR;
            end else if (rsp_fire_w && !rsp_mask_match_w) begin
                set_portal_error(PORTAL_ERR_MASK);
                state_q <= ST_ERROR;
            end else if (child_error_w) begin
                set_portal_error(PORTAL_ERR_CHILD);
                state_q <= ((portal_outstanding_q || req_fire_w)
                            && !rsp_fire_w)
                         ? ST_DRAIN : ST_ERROR;
            end else if (command_timeout_hit_w) begin
                set_portal_error(PORTAL_ERR_COMMAND);
                state_q <= ((portal_outstanding_q || req_fire_w)
                            && !rsp_fire_w)
                         ? ST_DRAIN : ST_ERROR;
            end else if (stall_timeout_hit_w) begin
                set_portal_error(PORTAL_ERR_STALL);
                state_q <= ((portal_outstanding_q || req_fire_w)
                            && !rsp_fire_w)
                         ? ST_DRAIN : ST_ERROR;
            end else if (child_done_protocol_w || child_result_protocol_w
                         || held_result_protocol_w) begin
                set_portal_error(PORTAL_ERR_PROTOCOL);
                state_q <= ((portal_outstanding_q || req_fire_w)
                            && !rsp_fire_w)
                         ? ST_DRAIN : ST_ERROR;
            end else begin
                case (state_q)
                    ST_CHECK: begin
                        if (abi_reject_w) begin
                            terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
                            terminal_error_class_q <= ABI_ERROR_ABI;
                            state_q <= ST_ERROR;
                        end else if (capability_reject_w) begin
                            terminal_error_code_q
                                <= `NPU_ERR_MACRO_CAPABILITY;
                            terminal_error_class_q <= ABI_ERROR_CAPABILITY;
                            state_q <= ST_ERROR;
                        end else if (layout_reject_w) begin
                            terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
                            terminal_error_class_q <= ABI_ERROR_LAYOUT;
                            state_q <= ST_ERROR;
                        end else if (iova_reject_w) begin
                            terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
                            terminal_error_class_q <= ABI_ERROR_IOVA;
                            state_q <= ST_ERROR;
                        end else begin
                            state_q <= ST_CHILD_START;
                        end
                    end

                    ST_CHILD_START: begin
                        if (child_start_fire_w)
                            state_q <= ST_READ_PREP;
                    end

                    ST_READ_PREP: begin
                        if (!candidate_group_ok_w) begin
                            set_portal_error(PORTAL_ERR_ADDRESS);
                            state_q <= ST_ERROR;
                        end else begin
                            req_write_q <= 1'b0;
                            req_mask_q <= candidate_mask_w;
                            req_src0_addr_q <= candidate_src0_addr_w;
                            req_src1_addr_q <= candidate_src1_addr_w;
                            req_dst_addr_q <= {(LANES*64){1'b0}};
                            req_wdata_q <= {(LANES*32){1'b0}};
                            state_q <= ST_READ_REQ;
                        end
                    end

                    ST_READ_REQ: begin
                        if (req_fire_w)
                            state_q <= ST_READ_WAIT;
                    end

                    ST_READ_WAIT: begin
                        if (rsp_fire_w) begin
                            if (!child_input_fire_w) begin
                                set_portal_error(PORTAL_ERR_INTERNAL);
                                state_q <= ST_ERROR;
                            end else begin
                                input_words_q <= input_words_q
                                    + (batch_words_w
                                       * read_words_per_element_w);
                                read_bytes_q <= read_bytes_q
                                    + ((batch_words_w
                                        * read_words_per_element_w) << 2);
                                state_q <= ST_RESULT_WAIT;
                            end
                        end
                    end

                    ST_RESULT_WAIT: begin
                        if (child_result_valid_w) begin
                            if (!current_result_metadata_ok_w) begin
                                set_portal_error(PORTAL_ERR_PROTOCOL);
                                state_q <= ST_ERROR;
                            end else begin
                                held_result_bits_q <= child_result_bits_w;
                                held_result_mask_q <= child_result_mask_w;
                                held_result_base_q <= child_result_base_w;
                                state_q <= ST_WRITE_PREP;
                            end
                        end
                    end

                    ST_WRITE_PREP: begin
                        req_write_q <= 1'b1;
                        req_mask_q <= held_result_mask_q;
                        req_src0_addr_q <= {(LANES*64){1'b0}};
                        req_src1_addr_q <= {(LANES*64){1'b0}};
                        req_dst_addr_q <= candidate_dst_addr_w;
                        req_wdata_q <= held_result_bits_q;
                        state_q <= ST_WRITE_REQ;
                    end

                    ST_WRITE_REQ: begin
                        if (req_fire_w)
                            state_q <= ST_WRITE_WAIT;
                    end

                    ST_WRITE_WAIT: begin
                        if (rsp_fire_w) begin
                            if (!child_result_ready_w) begin
                                set_portal_error(PORTAL_ERR_INTERNAL);
                                state_q <= ST_ERROR;
                            end else begin
                                output_words_q <= output_words_q
                                                + batch_words_w;
                                write_bytes_q <= write_bytes_q
                                               + (batch_words_w << 2);
                                if ((batch_base_q + batch_words_w)
                                        == profile_total_elements_w) begin
                                    state_q <= ST_FINAL_WAIT;
                                end else begin
                                    batch_base_q <= batch_base_q
                                                  + LANES_U64;
                                    state_q <= ST_READ_PREP;
                                end
                            end
                        end
                    end

                    ST_FINAL_WAIT: begin
                        if (child_done_w) begin
                            terminal_vector_elements_q <= output_words_q;
                            if (!exact_success_counts_w) begin
                                set_portal_error(PORTAL_ERR_PROTOCOL);
                                state_q <= ST_ERROR;
                            end else begin
                                terminal_error_code_q <= `NPU_ERR_NONE;
                                terminal_error_class_q <= ABI_ERROR_NONE;
                                state_q <= ST_DONE;
                            end
                        end
                    end

                    default: begin
                        set_portal_error(PORTAL_ERR_INTERNAL);
                        state_q <= (portal_outstanding_q || req_fire_w)
                                 ? ST_DRAIN : ST_ERROR;
                    end
                endcase
            end
        end
    end

`ifdef NPU_ASSERT
    always @(posedge clk_i) begin
        if (!rst_i && req_fire_w && portal_outstanding_q)
            $error("F32 portal accepted a second outstanding group");
        if (!rst_i && (done_o || error_o) && portal_outstanding_q)
            $error("F32 portal published terminal before response drain");
        if (!rst_i && req_valid_o && !req_write_o
                && ((|req_dst_addr_o) || (|req_wdata_o)))
            $error("F32 portal read leaked write-only fields");
        if (!rst_i && req_valid_o && req_write_o
                && ((|req_src0_addr_o) || (|req_src1_addr_o)))
            $error("F32 portal write leaked read-only fields");
    end
`endif

endmodule

`default_nettype wire
