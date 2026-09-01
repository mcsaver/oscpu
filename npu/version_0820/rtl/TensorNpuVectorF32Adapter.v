`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Exact production lowering for the canonical VECTOR_F32 F32 ALU families.
//
// The host is allowed to parse the 128-byte ABI blocks and present their
// scalar fields here, but it cannot execute tensor arithmetic.  This adapter
// independently checks the bounded P00--P18 capability/window table,
// constructs the resident TensorNpuF32TensorAlu descriptor, and accounts matching raw
// 64-bit GMEM responses.  Accepted GMEM/FP-child drain remains owned by the
// F32 tensor engine; this adapter never publishes a terminal before that
// child reaches DONE/ERROR with no GMEM request outstanding.
module TensorNpuVectorF32Adapter #(
    parameter [31:0] MACRO_CAPABILITY_EPOCH = 32'h00000001
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        start_valid_i,
    output wire        start_ready_o,
    output wire        busy_o,

    input  wire        abi_valid_i,
    input  wire [31:0] kernel_id_i,
    input  wire [31:0] command_flags_i,
    input  wire [31:0] capability_epoch_i,
    input  wire [31:0] node_count_i,
    input  wire [63:0] deadline_cycles_i,
    input  wire [31:0] vector_op_i,
    input  wire [31:0] vector_flags_i,
    input  wire [63:0] src0_iova_i,
    input  wire [63:0] src1_iova_i,
    input  wire [63:0] src2_iova_i,
    input  wire [63:0] dst_iova_i,
    input  wire [63:0] scratch_iova_i,
    input  wire [63:0] element_count_i,
    input  wire [31:0] outer_count_i,
    input  wire [31:0] dtype_i,
    input  wire [63:0] src0_stride_i,
    input  wire [63:0] src1_stride_i,
    input  wire [63:0] src2_stride_i,
    input  wire [63:0] dst_stride_i,
    input  wire [31:0] scalar0_i,
    input  wire [31:0] scalar1_i,
    input  wire [31:0] scratch_bytes_i,
    input  wire [31:0] rope_position_i,

    input  wire [63:0] src0_window_base_i,
    input  wire [63:0] src0_window_size_i,
    input  wire [1:0]  src0_window_perm_i,
    input  wire [63:0] src1_window_base_i,
    input  wire [63:0] src1_window_size_i,
    input  wire [1:0]  src1_window_perm_i,
    input  wire [63:0] dst_window_base_i,
    input  wire [63:0] dst_window_size_i,
    input  wire [1:0]  dst_window_perm_i,
    input  wire        windows_generation_valid_i,

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
    output wire [`NPU_ERROR_W-1:0] error_code_o,
    output wire [31:0] error_class_o,
    output wire [63:0] gmem_read_bytes_o,
    output wire [63:0] gmem_write_bytes_o,
    output wire [63:0] vector_elements_o,
    output wire [63:0] expected_gmem_read_bytes_o,
    output wire [63:0] expected_gmem_write_bytes_o,
    output wire [63:0] expected_vector_elements_o,
    output wire        gmem_outstanding_o,
    output wire        f32_start_pulse_o
);

    localparam [2:0] AD_IDLE         = 3'd0;
    localparam [2:0] AD_CHECK        = 3'd1;
    localparam [2:0] AD_ENGINE_START = 3'd2;
    localparam [2:0] AD_ENGINE_RUN   = 3'd3;
    localparam [2:0] AD_DONE         = 3'd4;
    localparam [2:0] AD_ERROR        = 3'd5;

    localparam [31:0] KERNEL_VECTOR_F32 = 32'h514e0010;
    // Synthetic representatives are PROFILE-only and therefore cannot touch
    // canonical required counters.  A future exact canonical dispatch keeps
    // the predecessor REQUIRED|PROFILE value.  No other flag combination is
    // part of this finite adapter capability.
    localparam [31:0] COMMAND_FLAGS_REPRESENTATIVE = 32'h00000010;
    localparam [31:0] COMMAND_FLAGS_CANONICAL      = 32'h00000011;
    localparam [31:0] VECTOR_OP_ADD      = 32'd1;
    localparam [31:0] VECTOR_OP_MUL      = 32'd2;
    localparam [31:0] VECTOR_OP_SUB      = 32'd3;
    localparam [31:0] VECTOR_OP_SCALE    = 32'd4;
    localparam [31:0] ABI_DTYPE_F32      = 32'd1;

    localparam integer F32_COMMAND_TIMEOUT_CYCLES = 200000000;

    localparam [31:0] ABI_ERROR_NONE       = 32'd0;
    localparam [31:0] ABI_ERROR_ABI        = 32'd1;
    localparam [31:0] ABI_ERROR_CAPABILITY = 32'd3;
    localparam [31:0] ABI_ERROR_LAYOUT     = 32'd4;
    localparam [31:0] ABI_ERROR_IOVA       = 32'd5;
    localparam [31:0] ABI_ERROR_GMEM       = 32'd6;
    localparam [31:0] ABI_ERROR_TIMEOUT    = 32'd10;
    localparam [31:0] ABI_ERROR_PROTOCOL   = 32'd11;

    localparam [4:0] F32_ERR_NONE             = 5'd0;
    localparam [4:0] F32_ERR_HEADER_PROFILE   = 5'd1;
    localparam [4:0] F32_ERR_SHAPE_BROADCAST  = 5'd2;
    localparam [4:0] F32_ERR_STRIDE_ALIGNMENT = 5'd3;
    localparam [4:0] F32_ERR_SOURCE_BOUNDS    = 5'd4;
    localparam [4:0] F32_ERR_DEST_BOUNDS      = 5'd5;
    localparam [4:0] F32_ERR_OVERLAP          = 5'd6;
    localparam [4:0] F32_ERR_GMEM_RESPONSE    = 5'd7;
    localparam [4:0] F32_ERR_STALL_TIMEOUT    = 5'd8;
    localparam [4:0] F32_ERR_COMMAND_TIMEOUT  = 5'd9;
    localparam [4:0] F32_ERR_CHILD_PROTOCOL   = 5'd10;
    localparam [4:0] F32_ERR_CHILD_TIMEOUT    = 5'd11;
    localparam [4:0] F32_ERR_INTERNAL_STATE   = 5'd12;

    reg [2:0] state_q;

    // Adapter resident command.  Pin-level inputs cannot alter a transaction
    // after start_valid_i && start_ready_o.
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
    // Exact least privilege is row-dependent: binary=01/01/10 and
    // SCALE=01/00/10.  Capture all six public bits and compare for equality
    // only after the finite profile row has been decoded.
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

    // One accounting owner mirrors the child's single-outstanding GMEM
    // contract.  Bytes count only matching, non-error responses.
    reg        gmem_outstanding_q;
    reg        gmem_pending_write_q;
    reg [7:0]  gmem_pending_wstrb_q;
    reg [63:0] gmem_read_bytes_q;
    reg [63:0] gmem_write_bytes_q;
    reg        accounting_fault_q;

    wire start_fire_w;
    assign start_ready_o = !rst_i && (state_q == AD_IDLE);
    assign start_fire_w = start_valid_i && start_ready_o;
    assign busy_o = !rst_i && (state_q != AD_IDLE);
    assign done_o = !rst_i && (state_q == AD_DONE);
    assign error_o = !rst_i && (state_q == AD_ERROR);
    assign error_code_o = error_o ? terminal_error_code_q : `NPU_ERR_NONE;
    assign error_class_o = error_o ? terminal_error_class_q : ABI_ERROR_NONE;
    assign gmem_read_bytes_o = gmem_read_bytes_q;
    assign gmem_write_bytes_o = gmem_write_bytes_q;
    assign vector_elements_o = terminal_vector_elements_q;
    assign gmem_outstanding_o = gmem_outstanding_q;

    // ---------------------------------------------------------------------
    // Exact P00--P18 capability table.  The single packed row is fully
    // defaulted before the bounded case and is unpacked into the complete
    // child source descriptors plus exact public-summary fields.
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

    // Allocation-relative source spans and private destination bounds use
    // widened intermediates.  beat_hi is also the exact public region size.
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

    // The resident F32 engine may reuse both source words from two registered
    // 64-bit beat caches.  Keep the adapter's response-based byte counter
    // independent: start from the logical per-element read baseline and
    // subtract exactly two skipped 8-byte responses per pair-reused element.
    // Widen the arithmetic so a corrupt child counter cannot wrap into a
    // plausible public expectation.
    wire [67:0] expected_gmem_read_baseline_ext_w;
    wire [67:0] gmem_pair_reuse_saved_bytes_ext_w;
    wire [67:0] expected_gmem_read_bytes_ext_w;
    wire        gmem_pair_reuse_accounting_fault_w;
    assign expected_gmem_read_baseline_ext_w = profile_src1_present_w ?
        ({4'd0, profile_total_elements_w} << 4) :
        ({4'd0, profile_total_elements_w} << 3);
    assign gmem_pair_reuse_saved_bytes_ext_w = profile_src1_present_w ?
        ({4'd0, f32_gmem_pair_reuse_elements_w} << 4) : 68'd0;
    assign expected_gmem_read_bytes_ext_w =
        expected_gmem_read_baseline_ext_w -
        gmem_pair_reuse_saved_bytes_ext_w;
    assign gmem_pair_reuse_accounting_fault_w =
        (!profile_src1_present_w &&
         (f32_gmem_pair_reuse_elements_w != 64'd0)) ||
        (f32_gmem_pair_reuse_elements_w > profile_total_elements_w) ||
        (gmem_pair_reuse_saved_bytes_ext_w >
         expected_gmem_read_baseline_ext_w) ||
        (expected_gmem_read_bytes_ext_w[67:64] != 4'd0);
    assign expected_gmem_read_bytes_o = !profile_valid_w ? 64'd0 :
        (gmem_pair_reuse_accounting_fault_w ? 64'hffffffffffffffff :
         expected_gmem_read_bytes_ext_w[63:0]);
    assign expected_gmem_write_bytes_o = profile_valid_w ?
        (profile_total_elements_w << 2) : 64'd0;
    assign expected_vector_elements_o = profile_valid_w ? profile_total_elements_w : 64'd0;

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
        // 私有 destination 的末级 stride 进入 64-bit child port 前必须精确可表示；
        // upper half 非零时在 AD_CHECK fail-closed，禁止静默截断后启动 child/GMEM。
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

    wire [63:0] source_base_min_w;
    wire [63:0] source_end_max_w;
    wire [63:0] f32_gmem_floor_w;
    wire [63:0] f32_gmem_limit_w;
    assign source_base_min_w = profile_src1_present_w &&
                               (src1_actual_start_ext_w[63:0] < src0_actual_start_ext_w[63:0]) ?
                               src1_actual_start_ext_w[63:0] : src0_actual_start_ext_w[63:0];
    assign source_end_max_w = profile_src1_present_w &&
                              (src1_actual_end_ext_w[63:0] > src0_actual_end_ext_w[63:0]) ?
                              src1_actual_end_ext_w[63:0] : src0_actual_end_ext_w[63:0];
    assign f32_gmem_floor_w = (source_base_min_w < dst_window_base_q) ?
                              source_base_min_w : dst_window_base_q;
    assign f32_gmem_limit_w = (source_end_max_w > dst_end_ext_w[63:0]) ?
                              source_end_max_w : dst_end_ext_w[63:0];

    // ---------------------------------------------------------------------
    // Resident F32 tensor engine.  AD_ENGINE_START releases its synchronous
    // reset for a full cycle before the start handshake; DONE/ERROR assert it
    // again for at least one full cycle.
    // ---------------------------------------------------------------------
    wire f32_rst_w;
    wire f32_start_valid_w;
    wire f32_start_fire_w;
    wire f32_ready_w;
    /* verilator lint_off UNUSEDSIGNAL */
    wire f32_busy_w;
    /* verilator lint_on UNUSEDSIGNAL */
    wire f32_gmem_req_valid_w;
    wire f32_gmem_req_ready_w;
    wire f32_gmem_req_write_w;
    wire [63:0] f32_gmem_req_addr_w;
    wire [63:0] f32_gmem_req_wdata_w;
    wire [7:0] f32_gmem_req_wstrb_w;
    wire f32_gmem_rsp_valid_w;
    wire f32_gmem_rsp_ready_w;
    wire [63:0] f32_gmem_rsp_rdata_w;
    wire f32_gmem_rsp_error_w;
    wire f32_done_w;
    wire f32_error_w;
    wire [4:0] f32_error_code_w;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [4:0] f32_arithmetic_flags_w;
    wire [63:0] f32_gmem_read_beats_w;
    wire [63:0] f32_gmem_pair_reuse_elements_w;
    wire [63:0] f32_gmem_write_beats_w;
    wire [63:0] f32_writes_accepted_w;
    wire [63:0] f32_child_requests_w;
    wire [63:0] f32_child_responses_w;
    wire [63:0] f32_active_cycles_w;
    /* verilator lint_on UNUSEDSIGNAL */
    wire [63:0] f32_elements_done_w;

    assign f32_rst_w = rst_i ||
                       ((state_q != AD_ENGINE_START) &&
                        (state_q != AD_ENGINE_RUN));
    assign f32_start_valid_w = (state_q == AD_ENGINE_START);
    assign f32_start_fire_w = f32_start_valid_w && f32_ready_w;
    assign f32_start_pulse_o = f32_start_fire_w;

    assign gmem_req_valid_o = (state_q == AD_ENGINE_RUN) ?
                              f32_gmem_req_valid_w : 1'b0;
    assign gmem_req_write_o = (state_q == AD_ENGINE_RUN) ?
                              f32_gmem_req_write_w : 1'b0;
    assign gmem_req_addr_o = (state_q == AD_ENGINE_RUN) ?
                             f32_gmem_req_addr_w : 64'd0;
    assign gmem_req_wdata_o = (state_q == AD_ENGINE_RUN) ?
                              f32_gmem_req_wdata_w : 64'd0;
    assign gmem_req_wstrb_o = (state_q == AD_ENGINE_RUN) ?
                              f32_gmem_req_wstrb_w : 8'd0;
    assign f32_gmem_req_ready_w = (state_q == AD_ENGINE_RUN) ?
                                  gmem_req_ready_i : 1'b0;
    assign f32_gmem_rsp_valid_w = (state_q == AD_ENGINE_RUN) ?
                                  gmem_rsp_valid_i : 1'b0;
    assign f32_gmem_rsp_rdata_w = (state_q == AD_ENGINE_RUN) ?
                                  gmem_rsp_rdata_i : 64'd0;
    assign f32_gmem_rsp_error_w = (state_q == AD_ENGINE_RUN) ?
                                  gmem_rsp_error_i : 1'b0;
    assign gmem_rsp_ready_o = (state_q == AD_ENGINE_RUN) ?
                              f32_gmem_rsp_ready_w : 1'b0;

    TensorNpuF32TensorAlu #(
        .COMMAND_TIMEOUT_CYCLES(F32_COMMAND_TIMEOUT_CYCLES),
        .MAX_ELEMENTS(262144)
    ) u_f32_tensor_alu (
        .clk_i(clk_i),
        .rst_i(f32_rst_w),
        .start_i(f32_start_valid_w),
        .ready_o(f32_ready_w),
        .busy_o(f32_busy_w),
        .opcode_i(profile_opcode_w),
        .dtype_i(2'd0),
        .profile_i(4'd0),
        .reserved_i(32'd0),
        .op_params_i({scalar1_q, scalar0_q}),
        .gmem_floor_i(f32_gmem_floor_w),
        .gmem_limit_i(f32_gmem_limit_w),
        .src0_region_base_i(src0_window_base_q),
        .src0_region_size_i(src0_beat_hi_ext_w[63:0]),
        .src0_view_off_i(profile_src0_view_off_w),
        .src0_ne0_i(profile_src0_ne0_w),
        .src0_ne1_i(profile_src0_ne1_w),
        .src0_ne2_i(profile_src0_ne2_w),
        .src0_ne3_i(profile_src0_ne3_w),
        .src0_nb0_i(profile_src0_nb0_w),
        .src0_nb1_i(profile_src0_nb1_w),
        .src0_nb2_i(profile_src0_nb2_w),
        .src0_nb3_i(profile_src0_nb3_w),
        .src1_region_base_i(profile_src1_present_w ?
                            src1_window_base_q : 64'd0),
        .src1_region_size_i(profile_src1_present_w ?
                            src1_beat_hi_ext_w[63:0] : 64'd0),
        .src1_view_off_i(profile_src1_present_w ?
                         profile_src1_view_off_w : 64'd0),
        .src1_ne0_i(profile_src1_ne0_w),
        .src1_ne1_i(profile_src1_ne1_w),
        .src1_ne2_i(profile_src1_ne2_w),
        .src1_ne3_i(profile_src1_ne3_w),
        .src1_nb0_i(profile_src1_nb0_w),
        .src1_nb1_i(profile_src1_nb1_w),
        .src1_nb2_i(profile_src1_nb2_w),
        .src1_nb3_i(profile_src1_nb3_w),
        .dst_region_base_i(dst_window_base_q),
        .dst_region_size_i(dst_size_ext_w[63:0]),
        .dst_view_off_i(64'd0),
        .dst_ne0_i(profile_src0_ne0_w),
        .dst_ne1_i(profile_src0_ne1_w),
        .dst_ne2_i(profile_src0_ne2_w),
        .dst_ne3_i(profile_src0_ne3_w),
        .dst_nb0_i(64'd4),
        .dst_nb1_i(dst_nb1_ext_w[63:0]),
        .dst_nb2_i(dst_nb2_ext_w[63:0]),
        .dst_nb3_i(dst_nb3_ext_w[63:0]),
        .gmem_req_valid_o(f32_gmem_req_valid_w),
        .gmem_req_ready_i(f32_gmem_req_ready_w),
        .gmem_req_write_o(f32_gmem_req_write_w),
        .gmem_req_addr_o(f32_gmem_req_addr_w),
        .gmem_req_wdata_o(f32_gmem_req_wdata_w),
        .gmem_req_wstrb_o(f32_gmem_req_wstrb_w),
        .gmem_rsp_valid_i(f32_gmem_rsp_valid_w),
        .gmem_rsp_ready_o(f32_gmem_rsp_ready_w),
        .gmem_rsp_rdata_i(f32_gmem_rsp_rdata_w),
        .gmem_rsp_error_i(f32_gmem_rsp_error_w),
        .done_o(f32_done_w),
        .error_o(f32_error_w),
        .error_code_o(f32_error_code_w),
        .arithmetic_flags_o(f32_arithmetic_flags_w),
        .elements_done_o(f32_elements_done_w),
        .gmem_read_beats_o(f32_gmem_read_beats_w),
        .gmem_pair_reuse_elements_o(f32_gmem_pair_reuse_elements_w),
        .gmem_write_beats_o(f32_gmem_write_beats_w),
        .writes_accepted_o(f32_writes_accepted_w),
        .child_requests_o(f32_child_requests_w),
        .child_responses_o(f32_child_responses_w),
        .active_cycles_o(f32_active_cycles_w)
    );

    wire gmem_req_fire_w;
    wire gmem_rsp_fire_w;
    assign gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;

    // Explicit F32 error-code translation.  Fixed-descriptor preflight codes
    // are theoretically unreachable but remain terminal and fail closed.
    reg [`NPU_ERROR_W-1:0] mapped_error_code_r;
    reg [31:0] mapped_error_class_r;
    always @(*) begin
        mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
        mapped_error_class_r = ABI_ERROR_PROTOCOL;
        case (f32_error_code_w)
            F32_ERR_NONE: begin
                mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
                mapped_error_class_r = ABI_ERROR_PROTOCOL;
            end
            F32_ERR_HEADER_PROFILE,
            F32_ERR_SHAPE_BROADCAST,
            F32_ERR_STRIDE_ALIGNMENT: begin
                mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
                mapped_error_class_r = ABI_ERROR_PROTOCOL;
            end
            F32_ERR_SOURCE_BOUNDS,
            F32_ERR_DEST_BOUNDS,
            F32_ERR_OVERLAP: begin
                mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
                mapped_error_class_r = ABI_ERROR_IOVA;
            end
            F32_ERR_GMEM_RESPONSE: begin
                mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
                mapped_error_class_r = ABI_ERROR_GMEM;
            end
            F32_ERR_STALL_TIMEOUT,
            F32_ERR_COMMAND_TIMEOUT,
            F32_ERR_CHILD_TIMEOUT: begin
                mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
                mapped_error_class_r = ABI_ERROR_TIMEOUT;
            end
            F32_ERR_CHILD_PROTOCOL,
            F32_ERR_INTERNAL_STATE: begin
                mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
                mapped_error_class_r = ABI_ERROR_PROTOCOL;
            end
            default: begin
                mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
                mapped_error_class_r = ABI_ERROR_PROTOCOL;
            end
        endcase
    end

    // ---------------------------------------------------------------------
    // Adapter state, resident capture, accounting, and terminal snapshot.
    // ---------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= AD_IDLE;
            abi_valid_q <= 1'b0;
            kernel_id_q <= 32'd0;
            command_flags_q <= 32'd0;
            capability_epoch_q <= 32'd0;
            node_count_q <= 32'd0;
            deadline_cycles_q <= 64'd0;
            vector_op_q <= 32'd0;
            vector_flags_q <= 32'd0;
            src0_iova_q <= 64'd0;
            src1_iova_q <= 64'd0;
            src2_iova_q <= 64'd0;
            dst_iova_q <= 64'd0;
            scratch_iova_q <= 64'd0;
            element_count_q <= 64'd0;
            outer_count_q <= 32'd0;
            dtype_q <= 32'd0;
            src0_stride_q <= 64'd0;
            src1_stride_q <= 64'd0;
            src2_stride_q <= 64'd0;
            dst_stride_q <= 64'd0;
            scalar0_q <= 32'd0;
            scalar1_q <= 32'd0;
            scratch_bytes_q <= 32'd0;
            rope_position_q <= 32'd0;
            src0_window_base_q <= 64'd0;
            src0_window_size_q <= 64'd0;
            src0_window_perm_q <= 2'b00;
            src1_window_base_q <= 64'd0;
            src1_window_size_q <= 64'd0;
            src1_window_perm_q <= 2'b00;
            dst_window_base_q <= 64'd0;
            dst_window_size_q <= 64'd0;
            dst_window_perm_q <= 2'b00;
            windows_generation_valid_q <= 1'b0;
            terminal_error_code_q <= `NPU_ERR_NONE;
            terminal_error_class_q <= ABI_ERROR_NONE;
            terminal_vector_elements_q <= 64'd0;
            gmem_outstanding_q <= 1'b0;
            gmem_pending_write_q <= 1'b0;
            gmem_pending_wstrb_q <= 8'd0;
            gmem_read_bytes_q <= 64'd0;
            gmem_write_bytes_q <= 64'd0;
            accounting_fault_q <= 1'b0;
        end else begin
            case (state_q)
                AD_IDLE: begin
                    terminal_error_code_q <= `NPU_ERR_NONE;
                    terminal_error_class_q <= ABI_ERROR_NONE;
                    terminal_vector_elements_q <= 64'd0;
                    gmem_outstanding_q <= 1'b0;
                    gmem_pending_write_q <= 1'b0;
                    gmem_pending_wstrb_q <= 8'd0;
                    gmem_read_bytes_q <= 64'd0;
                    gmem_write_bytes_q <= 64'd0;
                    accounting_fault_q <= 1'b0;
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
                        state_q <= AD_CHECK;
                    end
                end

                AD_CHECK: begin
                    if (abi_reject_w) begin
                        terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
                        terminal_error_class_q <= ABI_ERROR_ABI;
                        state_q <= AD_ERROR;
                    end else if (capability_reject_w) begin
                        terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
                        terminal_error_class_q <= ABI_ERROR_CAPABILITY;
                        state_q <= AD_ERROR;
                    end else if (layout_reject_w) begin
                        terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
                        terminal_error_class_q <= ABI_ERROR_LAYOUT;
                        state_q <= AD_ERROR;
                    end else if (iova_reject_w) begin
                        terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
                        terminal_error_class_q <= ABI_ERROR_IOVA;
                        state_q <= AD_ERROR;
                    end else begin
                        state_q <= AD_ENGINE_START;
                    end
                end

                AD_ENGINE_START: begin
                    if (f32_start_fire_w)
                        state_q <= AD_ENGINE_RUN;
                end

                AD_ENGINE_RUN: begin
                    if (gmem_req_fire_w) begin
                        if (gmem_outstanding_q)
                            accounting_fault_q <= 1'b1;
                        gmem_outstanding_q <= 1'b1;
                        gmem_pending_write_q <= gmem_req_write_o;
                        gmem_pending_wstrb_q <= gmem_req_wstrb_o;
                    end
                    if (gmem_rsp_fire_w) begin
                        if (!gmem_outstanding_q) begin
                            accounting_fault_q <= 1'b1;
                        end else begin
                            gmem_outstanding_q <= 1'b0;
                            if (!gmem_rsp_error_i) begin
                                if (!gmem_pending_write_q) begin
                                    gmem_read_bytes_q <=
                                        gmem_read_bytes_q + 64'd8;
                                end else begin
                                    case (gmem_pending_wstrb_q)
                                        8'h0f,
                                        8'hf0: gmem_write_bytes_q <=
                                            gmem_write_bytes_q + 64'd4;
                                        default: accounting_fault_q <= 1'b1;
                                    endcase
                                end
                            end
                        end
                    end

                    if (f32_done_w || f32_error_w) begin
                        terminal_vector_elements_q <= f32_elements_done_w;
                        if ((f32_done_w && f32_error_w) ||
                            accounting_fault_q ||
                            gmem_pair_reuse_accounting_fault_w ||
                            gmem_outstanding_q) begin
                            terminal_error_code_q <=
                                `NPU_ERR_MACRO_PROTOCOL;
                            terminal_error_class_q <= ABI_ERROR_PROTOCOL;
                            state_q <= AD_ERROR;
                        end else if (f32_error_w) begin
                            terminal_error_code_q <= mapped_error_code_r;
                            terminal_error_class_q <= mapped_error_class_r;
                            state_q <= AD_ERROR;
                        end else if ((gmem_read_bytes_q !=
                                      expected_gmem_read_bytes_o) ||
                                     (gmem_write_bytes_q !=
                                      expected_gmem_write_bytes_o) ||
                                     (f32_elements_done_w !=
                                      expected_vector_elements_o)) begin
                            terminal_error_code_q <=
                                `NPU_ERR_MACRO_PROTOCOL;
                            terminal_error_class_q <= ABI_ERROR_PROTOCOL;
                            state_q <= AD_ERROR;
                        end else begin
                            terminal_error_code_q <= `NPU_ERR_NONE;
                            terminal_error_class_q <= ABI_ERROR_NONE;
                            state_q <= AD_DONE;
                        end
                    end
                end

                AD_DONE: begin
                    state_q <= AD_IDLE;
                end

                AD_ERROR: begin
                    state_q <= AD_IDLE;
                end

                default: begin
                    terminal_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
                    terminal_error_class_q <= ABI_ERROR_PROTOCOL;
                    terminal_vector_elements_q <= 64'd0;
                    gmem_outstanding_q <= 1'b0;
                    state_q <= AD_ERROR;
                end
            endcase
        end
    end

`ifdef NPU_ASSERT
    always @(posedge clk_i) begin
        if (!rst_i && gmem_req_fire_w && gmem_outstanding_q)
            $error("NPU F32 adapter accepted a second GMEM owner");
        if (!rst_i && gmem_req_fire_w && gmem_rsp_valid_i)
            $error("NPU F32 adapter observed forbidden same-cycle response");
        if (!rst_i && (done_o || error_o) && gmem_outstanding_q)
            $error("NPU F32 adapter published terminal with GMEM outstanding");
        if (!rst_i && done_o && (terminal_error_code_q != `NPU_ERR_NONE))
            $error("NPU F32 adapter success carried a non-zero error code");
        if (!rst_i && error_o && (terminal_error_code_q == `NPU_ERR_NONE))
            $error("NPU F32 adapter failure carried a zero error code");
        if (!rst_i && f32_start_fire_w && (state_q != AD_ENGINE_START))
            $error("NPU F32 adapter started child outside ENGINE_START");
    end
`endif

endmodule

`default_nettype wire
