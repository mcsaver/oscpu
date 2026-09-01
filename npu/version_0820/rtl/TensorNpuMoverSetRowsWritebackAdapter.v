`timescale 1ns/1ps
`default_nettype none

// TensorNpuMoverSetRowsWritebackAdapter
//
// Transactional public-descriptor shell for the frozen Qwen CPY/CONT/
// CONCAT0 and SET_ROWS profiles.  TensorNpuTensorMover owns every raw-bit
// mover result and TensorNpuSetRowsEngine owns every F32-to-F16 conversion and
// scatter write.  The host supplies only immutable descriptors and raw GMEM
// responses; it never copies, converts, or repairs tensor values.
//
// The old-destination operands present in the graph are ordering/backing
// dependencies.  CPY source 1 is proved as a complete read-only dependency,
// and SET_ROWS source 2 is proved by src2_matches_dst_i.  Neither is used as a
// license for host copy-on-write.  The NPU writes every byte in the node's
// logical write domain; bytes outside that domain survive only because the
// private destination allocation already owns them.  Empty CPY has an empty
// write domain and therefore succeeds with zero GMEM traffic.
//
// All semantic ends, aligned eight-byte physical footprints, capability ends,
// shape products, and strides remain 128-bit until admission succeeds.  A
// command can publish its transaction-private destination only through the
// success-only dst_commit_o pulse.  Child timeout/error paths drain their sole
// accepted response before terminal ownership is released.
module TensorNpuMoverSetRowsWritebackAdapter #(
    parameter integer STALL_TIMEOUT_CYCLES   = 512,
    parameter integer COMMAND_TIMEOUT_CYCLES = 1048576
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    // 0=CPY_F32, 1=CONT_F32, 2=CONCAT0_F32,
    // 3=SET_ROWS_NATIVE, 4=SET_ROWS_TRANSPOSED.
    input  wire [2:0]   operation_i,
    input  wire         npu_required_i,
    input  wire [63:0]  command_id_i,
    input  wire [63:0]  canonical_node_id_lo_i,
    input  wire [63:0]  canonical_node_id_hi_i,
    input  wire         dst_shadow_private_i,
    input  wire         windows_generation_valid_i,

    input  wire [31:0]  dst_descriptor_flags_i,
    input  wire [511:0] op_params_i,
    input  wire [2:0]   source_arity_i,
    input  wire [31:0]  src0_descriptor_flags_i,
    input  wire [31:0]  src1_descriptor_flags_i,
    input  wire [31:0]  src2_descriptor_flags_i,
    input  wire         src2_matches_dst_i,

    input  wire [7:0]   src0_dtype_i,
    input  wire [63:0]  src0_region_base_i,
    input  wire [63:0]  src0_region_size_i,
    input  wire [63:0]  src0_view_off_i,
    input  wire [31:0]  src0_ne0_i,
    input  wire [31:0]  src0_ne1_i,
    input  wire [31:0]  src0_ne2_i,
    input  wire [31:0]  src0_ne3_i,
    input  wire [63:0]  src0_nb0_i,
    input  wire [63:0]  src0_nb1_i,
    input  wire [63:0]  src0_nb2_i,
    input  wire [63:0]  src0_nb3_i,

    input  wire [7:0]   src1_dtype_i,
    input  wire [63:0]  src1_region_base_i,
    input  wire [63:0]  src1_region_size_i,
    input  wire [63:0]  src1_view_off_i,
    input  wire [31:0]  src1_ne0_i,
    input  wire [31:0]  src1_ne1_i,
    input  wire [31:0]  src1_ne2_i,
    input  wire [31:0]  src1_ne3_i,
    input  wire [63:0]  src1_nb0_i,
    input  wire [63:0]  src1_nb1_i,
    input  wire [63:0]  src1_nb2_i,
    input  wire [63:0]  src1_nb3_i,

    input  wire [7:0]   dst_dtype_i,
    input  wire [63:0]  dst_region_base_i,
    input  wire [63:0]  dst_region_size_i,
    input  wire [63:0]  dst_view_off_i,
    input  wire [31:0]  dst_ne0_i,
    input  wire [31:0]  dst_ne1_i,
    input  wire [31:0]  dst_ne2_i,
    input  wire [31:0]  dst_ne3_i,
    input  wire [63:0]  dst_nb0_i,
    input  wire [63:0]  dst_nb1_i,
    input  wire [63:0]  dst_nb2_i,
    input  wire [63:0]  dst_nb3_i,

    // SET_ROWS-only profile scalars.  Mover operations require both zero.
    input  wire [31:0]  cache_capacity_i,
    input  wire [31:0]  physical_slot_i,

    // Immutable R/R/W capability triplet.  CONT uses an aligned, zero-byte
    // read-only source-1 sentinel.
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

    // completion_valid_o qualifies all identity, terminal and per-command
    // counter outputs.  REQUIRED counters are cumulative since reset.
    output wire         completion_valid_o,
    output wire         dst_commit_o,
    output wire [63:0]  completion_command_id_o,
    output wire [63:0]  completion_canonical_node_id_lo_o,
    output wire [63:0]  completion_canonical_node_id_hi_o,
    output wire         completion_npu_required_o,
    output wire [2:0]   completion_operation_o,
    output wire [31:0]  completion_kernel_id_o,
    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,
    output wire [4:0]   child_error_code_o,

    output wire [63:0]  indices_completed_o,
    output wire [63:0]  source_elements_completed_o,
    output wire [63:0]  elements_completed_o,
    output wire [63:0]  gmem_read_beats_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_beats_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  child_active_cycles_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o,
    output wire [63:0]  npu_required_issued_o,
    output wire [63:0]  npu_required_completed_o
);

    localparam [2:0] OP_CPY_F32             = 3'd0;
    localparam [2:0] OP_CONT_F32            = 3'd1;
    localparam [2:0] OP_CONCAT0_F32         = 3'd2;
    localparam [2:0] OP_SET_ROWS_NATIVE     = 3'd3;
    localparam [2:0] OP_SET_ROWS_TRANSPOSED = 3'd4;

    localparam [31:0] KERNEL_ID_MOVER_F32    = 32'h514e0007;
    localparam [31:0] KERNEL_ID_SET_ROWS_F32 = 32'h514e0008;
    localparam [7:0] DTYPE_F32 = 8'd0;
    localparam [7:0] DTYPE_F16 = 8'd1;
    localparam [7:0] DTYPE_I64 = 8'd27;

    localparam [2:0] ST_IDLE        = 3'd0;
    localparam [2:0] ST_PREFLIGHT   = 3'd1;
    localparam [2:0] ST_CHILD_START = 3'd2;
    localparam [2:0] ST_CHILD_RUN   = 3'd3;
    localparam [2:0] ST_DONE        = 3'd4;
    localparam [2:0] ST_ERROR       = 3'd5;

    localparam [4:0] ERR_NONE           = 5'd0;
    localparam [4:0] ERR_DESCRIPTOR     = 5'd1;
    localparam [4:0] ERR_LAYOUT         = 5'd2;
    localparam [4:0] ERR_SOURCE0_WINDOW = 5'd3;
    localparam [4:0] ERR_SOURCE1_WINDOW = 5'd4;
    localparam [4:0] ERR_DEST_WINDOW    = 5'd5;
    localparam [4:0] ERR_ALIAS          = 5'd6;
    localparam [4:0] ERR_CHILD          = 5'd7;
    localparam [4:0] ERR_CHILD_PROTOCOL = 5'd8;
    localparam [4:0] ERR_GMEM_RESPONSE  = 5'd9;
    localparam [4:0] ERR_STALL_TIMEOUT  = 5'd10;
    localparam [4:0] ERR_COMMAND_TIMEOUT = 5'd11;
    localparam [4:0] ERR_DOMAIN         = 5'd12;
    localparam [4:0] ERR_INTERNAL       = 5'd13;

    reg [2:0] state_q;

    reg [2:0] operation_q;
    reg       npu_required_q;
    reg [63:0] command_id_q;
    reg [63:0] canonical_node_id_lo_q;
    reg [63:0] canonical_node_id_hi_q;
    reg       dst_shadow_private_q;
    reg       windows_generation_valid_q;
    reg [31:0] dst_descriptor_flags_q;
    reg [511:0] op_params_q;
    reg [2:0] source_arity_q;
    reg [31:0] src0_descriptor_flags_q;
    reg [31:0] src1_descriptor_flags_q;
    reg [31:0] src2_descriptor_flags_q;
    reg       src2_matches_dst_q;

    reg [7:0] src0_dtype_q;
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

    reg [7:0] src1_dtype_q;
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

    reg [7:0] dst_dtype_q;
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
    reg [31:0] cache_capacity_q;
    reg [31:0] physical_slot_q;

    reg [63:0] src0_window_base_q;
    reg [63:0] src0_window_bytes_q;
    reg        src0_window_read_q;
    reg        src0_window_write_q;
    reg [63:0] src1_window_base_q;
    reg [63:0] src1_window_bytes_q;
    reg        src1_window_read_q;
    reg        src1_window_write_q;
    reg [63:0] dst_window_base_q;
    reg [63:0] dst_window_bytes_q;
    reg        dst_window_read_q;
    reg        dst_window_write_q;

    reg [4:0] error_code_q;
    reg [4:0] child_error_code_q;
    reg [63:0] indices_completed_q;
    reg [63:0] source_elements_completed_q;
    reg [63:0] elements_completed_q;
    reg [63:0] gmem_read_beats_q;
    reg [63:0] gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_beats_q;
    reg [63:0] gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;
    reg [63:0] active_cycles_q;
    reg        outstanding_q;
    reg        outstanding_write_q;
    reg [3:0]  outstanding_payload_bytes_q;
    reg [63:0] npu_required_issued_q;
    reg [63:0] npu_required_completed_q;

    wire start_fire_w;
    wire mover_operation_w;
    wire set_operation_w;
    wire gmem_req_fire_w;
    wire gmem_rsp_fire_w;

    assign mover_operation_w = (operation_q <= OP_CONCAT0_F32);
    assign set_operation_w = (operation_q == OP_SET_ROWS_NATIVE)
                           || (operation_q == OP_SET_ROWS_TRANSPOSED);
    assign ready_o = !rst_i && (state_q == ST_IDLE)
                   && mover_ready_w && set_ready_w;
    assign busy_o = !rst_i && (state_q != ST_IDLE);
    assign done_o = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign completion_valid_o = done_o || error_o;
    assign dst_commit_o = done_o;
    assign completion_command_id_o = completion_valid_o
                                   ? command_id_q : 64'b0;
    assign completion_canonical_node_id_lo_o = completion_valid_o
                                             ? canonical_node_id_lo_q : 64'b0;
    assign completion_canonical_node_id_hi_o = completion_valid_o
                                             ? canonical_node_id_hi_q : 64'b0;
    assign completion_npu_required_o = completion_valid_o
                                     ? npu_required_q : 1'b0;
    assign completion_operation_o = completion_valid_o
                                  ? operation_q : 3'b0;
    assign completion_kernel_id_o = !completion_valid_o ? 32'b0
                                  : mover_operation_w
                                    ? KERNEL_ID_MOVER_F32
                                    : KERNEL_ID_SET_ROWS_F32;
    assign error_code_o = error_code_q;
    assign child_error_code_o = child_error_code_q;
    assign indices_completed_o = indices_completed_q;
    assign source_elements_completed_o = source_elements_completed_q;
    assign elements_completed_o = elements_completed_q;
    assign gmem_read_beats_o = gmem_read_beats_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_beats_o = gmem_write_beats_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign child_active_cycles_o = mover_operation_w
                                 ? mover_active_cycles_w
                                 : set_active_cycles_w;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;
    assign npu_required_issued_o = npu_required_issued_q;
    assign npu_required_completed_o = npu_required_completed_q;
    assign start_fire_w = start_i && ready_o;

    // ------------------------------------------------------------------
    // Complete 128-bit descriptor/capability proof.
    // ------------------------------------------------------------------
    reg [127:0] src0_count_w;
    reg [127:0] src1_count_w;
    reg [127:0] dst_count_w;
    reg [127:0] output_count_w;
    reg [127:0] output_bytes_w;
    reg [127:0] src0_last_rel_w;
    reg [127:0] src1_last_rel_w;
    reg [127:0] dst_last_rel_w;
    reg [127:0] src0_region_end_w;
    reg [127:0] src1_region_end_w;
    reg [127:0] dst_region_end_w;
    reg [127:0] src0_window_end_w;
    reg [127:0] src1_window_end_w;
    reg [127:0] dst_window_end_w;
    reg [127:0] src0_sem_start_w;
    reg [127:0] src0_sem_end_w;
    reg [127:0] src1_sem_start_w;
    reg [127:0] src1_sem_end_w;
    reg [127:0] dst_sem_start_w;
    reg [127:0] dst_sem_end_w;
    reg [127:0] src0_phys_start_w;
    reg [127:0] src0_phys_end_w;
    reg [127:0] src1_phys_start_w;
    reg [127:0] src1_phys_end_w;
    reg [127:0] dst_phys_start_w;
    reg [127:0] dst_phys_end_w;
    reg [127:0] align_tmp_w;
    reg [127:0] dst_nb1_expected_w;
    reg [127:0] dst_nb2_expected_w;
    reg [127:0] dst_nb3_expected_w;
    reg [127:0] set_dst_ne1_w;
    reg [127:0] set_dst_nb2_w;
    reg [127:0] set_dst_first_element_w;
    reg [127:0] set_dst_last_element_w;
    reg         operation_ok_w;
    reg         empty_mover_w;
    reg         src1_active_w;
    reg         descriptor_ok_w;
    reg         layout_ok_w;
    reg         src0_window_ok_w;
    reg         src1_window_ok_w;
    reg         dst_window_ok_w;
    reg         alias_ok_w;
    reg [4:0]   preflight_error_w;
    reg [63:0]  child_gmem_floor_w;
    reg [63:0]  child_gmem_limit_w;
    reg [63:0]  expected_indices_w;
    reg [63:0]  expected_source_elements_w;
    reg [63:0]  expected_elements_w;
    reg [63:0]  expected_read_beats_w;
    reg [63:0]  expected_read_bytes_w;
    reg [63:0]  expected_write_bytes_w;

    always @(*) begin
        operation_ok_w = (operation_q <= OP_SET_ROWS_TRANSPOSED);
        empty_mover_w = mover_operation_w
                      && ((src0_ne0_q == 32'b0)
                          || (src0_ne1_q == 32'b0)
                          || (src0_ne2_q == 32'b0)
                          || (src0_ne3_q == 32'b0));
        src1_active_w = (operation_q == OP_CPY_F32)
                      || (operation_q == OP_CONCAT0_F32)
                      || set_operation_w;

        src0_count_w = {96'b0, src0_ne0_q};
        src0_count_w = src0_count_w * {96'b0, src0_ne1_q};
        src0_count_w = src0_count_w * {96'b0, src0_ne2_q};
        src0_count_w = src0_count_w * {96'b0, src0_ne3_q};
        src1_count_w = {96'b0, src1_ne0_q};
        src1_count_w = src1_count_w * {96'b0, src1_ne1_q};
        src1_count_w = src1_count_w * {96'b0, src1_ne2_q};
        src1_count_w = src1_count_w * {96'b0, src1_ne3_q};
        dst_count_w = {96'b0, dst_ne0_q};
        dst_count_w = dst_count_w * {96'b0, dst_ne1_q};
        dst_count_w = dst_count_w * {96'b0, dst_ne2_q};
        dst_count_w = dst_count_w * {96'b0, dst_ne3_q};
        output_count_w = mover_operation_w ? dst_count_w : 128'd512;
        output_bytes_w = output_count_w
                       * (mover_operation_w ? 128'd4 : 128'd2);

        src0_last_rel_w = {64'b0, src0_view_off_q};
        src1_last_rel_w = {64'b0, src1_view_off_q};
        if ((src0_count_w != 128'b0) && !empty_mover_w) begin
            src0_last_rel_w = src0_last_rel_w
                + ({96'b0, (src0_ne0_q - 32'd1)} * {64'b0, src0_nb0_q})
                + ({96'b0, (src0_ne1_q - 32'd1)} * {64'b0, src0_nb1_q})
                + ({96'b0, (src0_ne2_q - 32'd1)} * {64'b0, src0_nb2_q})
                + ({96'b0, (src0_ne3_q - 32'd1)} * {64'b0, src0_nb3_q})
                + 128'd4;
        end
        if (src1_active_w && (src1_count_w != 128'b0)
                && !empty_mover_w) begin
            src1_last_rel_w = src1_last_rel_w
                + ({96'b0, (src1_ne0_q - 32'd1)} * {64'b0, src1_nb0_q})
                + ({96'b0, (src1_ne1_q - 32'd1)} * {64'b0, src1_nb1_q})
                + ({96'b0, (src1_ne2_q - 32'd1)} * {64'b0, src1_nb2_q})
                + ({96'b0, (src1_ne3_q - 32'd1)} * {64'b0, src1_nb3_q})
                + (set_operation_w ? 128'd8 : 128'd4);
        end

        set_dst_first_element_w = 128'b0;
        set_dst_last_element_w = 128'b0;
        if (operation_q == OP_SET_ROWS_NATIVE) begin
            set_dst_first_element_w = {96'b0, physical_slot_q} * 128'd512;
            set_dst_last_element_w = set_dst_first_element_w + 128'd511;
        end else if (operation_q == OP_SET_ROWS_TRANSPOSED) begin
            set_dst_first_element_w = {96'b0, physical_slot_q};
            set_dst_last_element_w = 128'd511
                                   * {96'b0, cache_capacity_q}
                                   + {96'b0, physical_slot_q};
        end
        if (mover_operation_w) begin
            dst_last_rel_w = {64'b0, dst_view_off_q} + output_bytes_w;
        end else begin
            dst_last_rel_w = {64'b0, dst_view_off_q}
                           + (set_dst_last_element_w * 128'd2) + 128'd2;
        end

        src0_region_end_w = {64'b0, src0_region_base_q}
                          + {64'b0, src0_region_size_q};
        src1_region_end_w = {64'b0, src1_region_base_q}
                          + {64'b0, src1_region_size_q};
        dst_region_end_w = {64'b0, dst_region_base_q}
                         + {64'b0, dst_region_size_q};
        src0_window_end_w = {64'b0, src0_window_base_q}
                          + {64'b0, src0_window_bytes_q};
        src1_window_end_w = {64'b0, src1_window_base_q}
                          + {64'b0, src1_window_bytes_q};
        dst_window_end_w = {64'b0, dst_window_base_q}
                         + {64'b0, dst_window_bytes_q};

        src0_sem_start_w = {64'b0, src0_region_base_q}
                         + {64'b0, src0_view_off_q};
        src0_sem_end_w = {64'b0, src0_region_base_q} + src0_last_rel_w;
        src1_sem_start_w = {64'b0, src1_region_base_q}
                         + {64'b0, src1_view_off_q};
        src1_sem_end_w = {64'b0, src1_region_base_q} + src1_last_rel_w;
        dst_sem_start_w = {64'b0, dst_region_base_q}
                        + {64'b0, dst_view_off_q};
        if (set_operation_w) begin
            dst_sem_start_w = dst_sem_start_w
                            + (set_dst_first_element_w * 128'd2);
        end
        dst_sem_end_w = {64'b0, dst_region_base_q} + dst_last_rel_w;

        src0_phys_start_w = src0_sem_start_w;
        src0_phys_start_w[2:0] = 3'b000;
        src1_phys_start_w = src1_sem_start_w;
        src1_phys_start_w[2:0] = 3'b000;
        dst_phys_start_w = dst_sem_start_w;
        dst_phys_start_w[2:0] = 3'b000;
        src0_phys_end_w = src0_phys_start_w;
        src1_phys_end_w = src1_phys_start_w;
        dst_phys_end_w = dst_phys_start_w;
        align_tmp_w = 128'b0;
        if (!empty_mover_w && (src0_count_w != 128'b0)) begin
            align_tmp_w = src0_sem_end_w - 128'd1;
            align_tmp_w[2:0] = 3'b000;
            src0_phys_end_w = align_tmp_w + 128'd8;
        end
        if (src1_active_w && !empty_mover_w
                && (src1_count_w != 128'b0)) begin
            align_tmp_w = src1_sem_end_w - 128'd1;
            align_tmp_w[2:0] = 3'b000;
            src1_phys_end_w = align_tmp_w + 128'd8;
        end
        if (!empty_mover_w && (output_count_w != 128'b0)) begin
            align_tmp_w = dst_sem_end_w - 128'd1;
            align_tmp_w[2:0] = 3'b000;
            dst_phys_end_w = align_tmp_w + 128'd8;
        end

        dst_nb1_expected_w = {96'b0, dst_ne0_q}
                           * (mover_operation_w ? 128'd4 : 128'd2);
        dst_nb2_expected_w = dst_nb1_expected_w * {96'b0, dst_ne1_q};
        dst_nb3_expected_w = dst_nb2_expected_w * {96'b0, dst_ne2_q};
        set_dst_ne1_w = {96'b0, cache_capacity_q} * 128'd512;
        set_dst_nb2_w = set_dst_ne1_w * 128'd2;

        descriptor_ok_w = operation_ok_w
                       && npu_required_q
                       && dst_shadow_private_q
                       && windows_generation_valid_q
                       && ((canonical_node_id_lo_q != 64'b0)
                           || (canonical_node_id_hi_q != 64'b0))
                       && (dst_descriptor_flags_q == 32'h00000010)
                       && (op_params_q == 512'b0)
                       && src0_window_read_q && !src0_window_write_q
                       && src1_window_read_q && !src1_window_write_q
                       && !dst_window_read_q && dst_window_write_q
                       && (src0_window_base_q[2:0] == 3'b000)
                       && (src0_window_bytes_q[2:0] == 3'b000)
                       && (src1_window_base_q[2:0] == 3'b000)
                       && (src1_window_bytes_q[2:0] == 3'b000)
                       && (dst_window_base_q[2:0] == 3'b000)
                       && (dst_window_bytes_q[2:0] == 3'b000)
                       && (src0_region_end_w[127:64] == 64'b0)
                       && (src1_region_end_w[127:64] == 64'b0)
                       && (dst_region_end_w[127:64] == 64'b0)
                       && (src0_window_end_w[127:64] == 64'b0)
                       && (src1_window_end_w[127:64] == 64'b0)
                       && (dst_window_end_w[127:64] == 64'b0);

        if (operation_q == OP_CPY_F32) begin
            descriptor_ok_w = descriptor_ok_w
                && (source_arity_q == 3'd2)
                && (src0_descriptor_flags_q == 32'h00000010)
                && (src1_descriptor_flags_q == 32'h00000010)
                && (src2_descriptor_flags_q == 32'b0)
                && !src2_matches_dst_q
                && (cache_capacity_q == 32'b0)
                && (physical_slot_q == 32'b0);
        end else if (operation_q == OP_CONT_F32) begin
            descriptor_ok_w = descriptor_ok_w
                && (source_arity_q == 3'd1)
                && !empty_mover_w
                && (src0_descriptor_flags_q == 32'h00000010)
                && (src1_descriptor_flags_q == 32'b0)
                && (src2_descriptor_flags_q == 32'b0)
                && !src2_matches_dst_q
                && (cache_capacity_q == 32'b0)
                && (physical_slot_q == 32'b0)
                && (src1_dtype_q == 8'b0)
                && (src1_region_base_q == 64'b0)
                && (src1_region_size_q == 64'b0)
                && (src1_view_off_q == 64'b0)
                && (src1_ne0_q == 32'b0)
                && (src1_ne1_q == 32'b0)
                && (src1_ne2_q == 32'b0)
                && (src1_ne3_q == 32'b0)
                && (src1_nb0_q == 64'b0)
                && (src1_nb1_q == 64'b0)
                && (src1_nb2_q == 64'b0)
                && (src1_nb3_q == 64'b0)
                && (src1_window_bytes_q == 64'b0);
        end else if (operation_q == OP_CONCAT0_F32) begin
            descriptor_ok_w = descriptor_ok_w
                && (source_arity_q == 3'd2)
                && !empty_mover_w
                && (src0_descriptor_flags_q == 32'h00000010)
                && (src1_descriptor_flags_q == 32'h00000010)
                && (src2_descriptor_flags_q == 32'b0)
                && !src2_matches_dst_q
                && (cache_capacity_q == 32'b0)
                && (physical_slot_q == 32'b0);
        end else if (operation_q == OP_SET_ROWS_NATIVE) begin
            descriptor_ok_w = descriptor_ok_w
                && (source_arity_q == 3'd3)
                && (src0_descriptor_flags_q == 32'h00000010)
                && (src1_descriptor_flags_q == 32'h00000001)
                && (src2_descriptor_flags_q == 32'h00000000)
                && src2_matches_dst_q;
        end else if (operation_q == OP_SET_ROWS_TRANSPOSED) begin
            descriptor_ok_w = descriptor_ok_w
                && (source_arity_q == 3'd3)
                && (src0_descriptor_flags_q == 32'h00000010)
                && (src1_descriptor_flags_q == 32'h00000001)
                && (src2_descriptor_flags_q == 32'h00000010)
                && src2_matches_dst_q;
        end

        layout_ok_w = (src0_count_w[127:32] == 96'b0)
                   && (src1_count_w[127:32] == 96'b0)
                   && (dst_count_w[127:32] == 96'b0)
                   && (output_count_w[127:64] == 64'b0)
                   && (output_bytes_w[127:64] == 64'b0)
                   && (dst_nb1_expected_w[127:64] == 64'b0)
                   && (dst_nb2_expected_w[127:64] == 64'b0)
                   && (dst_nb3_expected_w[127:64] == 64'b0)
                   && (dst_nb0_q == (mover_operation_w ? 64'd4 : 64'd2))
                   && (dst_nb1_q == dst_nb1_expected_w[63:0])
                   && (dst_nb2_q == dst_nb2_expected_w[63:0])
                   && (dst_nb3_q == dst_nb3_expected_w[63:0]);

        if (mover_operation_w) begin
            layout_ok_w = layout_ok_w
                && (src0_dtype_q == DTYPE_F32)
                && (dst_dtype_q == DTYPE_F32)
                && ((operation_q == OP_CONCAT0_F32)
                    ? ((src0_count_w + src1_count_w) == dst_count_w)
                    : (src0_count_w == dst_count_w))
                && (src0_sem_start_w[1:0] == 2'b00)
                && (dst_sem_start_w[1:0] == 2'b00);
            if (empty_mover_w) begin
                layout_ok_w = layout_ok_w && (dst_count_w == 128'b0);
            end else begin
                layout_ok_w = layout_ok_w
                    && (src0_count_w != 128'b0)
                    && (src0_ne0_q != 32'b0)
                    && (src0_ne1_q != 32'b0)
                    && (src0_ne2_q != 32'b0)
                    && (src0_ne3_q != 32'b0)
                    && (src0_nb0_q != 64'b0)
                    && (src0_nb1_q != 64'b0)
                    && (src0_nb2_q != 64'b0)
                    && (src0_nb3_q != 64'b0)
                    && (src0_nb0_q[1:0] == 2'b00)
                    && (src0_nb1_q[1:0] == 2'b00)
                    && (src0_nb2_q[1:0] == 2'b00)
                    && (src0_nb3_q[1:0] == 2'b00);
            end
            if (operation_q == OP_CPY_F32) begin
                layout_ok_w = layout_ok_w
                    && (src1_dtype_q == DTYPE_F32)
                    && (src1_ne0_q == dst_ne0_q)
                    && (src1_ne1_q == dst_ne1_q)
                    && (src1_ne2_q == dst_ne2_q)
                    && (src1_ne3_q == dst_ne3_q)
                    && (src1_nb0_q == dst_nb0_q)
                    && (src1_nb1_q == dst_nb1_q)
                    && (src1_nb2_q == dst_nb2_q)
                    && (src1_nb3_q == dst_nb3_q);
            end else if (operation_q == OP_CONCAT0_F32) begin
                layout_ok_w = layout_ok_w
                    && (src1_dtype_q == DTYPE_F32)
                    && (src1_ne0_q != 32'b0)
                    && (src1_ne1_q != 32'b0)
                    && (src1_ne2_q != 32'b0)
                    && (src1_ne3_q != 32'b0)
                    && (src1_nb0_q != 64'b0)
                    && (src1_nb1_q != 64'b0)
                    && (src1_nb2_q != 64'b0)
                    && (src1_nb3_q != 64'b0)
                    && (src0_ne1_q == src1_ne1_q)
                    && (src0_ne2_q == src1_ne2_q)
                    && (src0_ne3_q == src1_ne3_q)
                    && ({96'b0, dst_ne0_q}
                        == ({96'b0, src0_ne0_q}
                            + {96'b0, src1_ne0_q}))
                    && (dst_ne1_q == src0_ne1_q)
                    && (dst_ne2_q == src0_ne2_q)
                    && (dst_ne3_q == src0_ne3_q)
                    && (src1_sem_start_w[1:0] == 2'b00)
                    && (src1_nb0_q[1:0] == 2'b00)
                    && (src1_nb1_q[1:0] == 2'b00)
                    && (src1_nb2_q[1:0] == 2'b00)
                    && (src1_nb3_q[1:0] == 2'b00);
            end
        end else begin
            layout_ok_w = layout_ok_w
                && (src0_dtype_q == DTYPE_F32)
                && (src1_dtype_q == DTYPE_I64)
                && (dst_dtype_q == DTYPE_F16)
                && (cache_capacity_q >= 32'd1)
                && (physical_slot_q < cache_capacity_q)
                && (src0_count_w == 128'd512)
                && (src0_nb0_q == 64'd4)
                && (src0_sem_start_w[1:0] == 2'b00)
                && (src1_nb0_q == 64'd8)
                && (src1_sem_start_w[2:0] == 3'b000)
                && !dst_sem_start_w[0]
                && (dst_ne2_q == 32'd1)
                && (dst_ne3_q == 32'd1)
                && (set_dst_ne1_w[127:32] == 96'b0)
                && (set_dst_nb2_w[127:64] == 64'b0);
            if (operation_q == OP_SET_ROWS_NATIVE) begin
                layout_ok_w = layout_ok_w
                    && (src0_ne0_q == 32'd512)
                    && (src0_ne1_q == 32'd1)
                    && (src0_ne2_q == 32'd1)
                    && (src0_ne3_q == 32'd1)
                    && (src0_nb1_q == 64'd2048)
                    && (src0_nb2_q == 64'd2048)
                    && (src0_nb3_q == 64'd2048)
                    && (src1_ne0_q == 32'd1)
                    && (src1_ne1_q == 32'd1)
                    && (src1_ne2_q == 32'd1)
                    && (src1_ne3_q == 32'd1)
                    && (src1_nb1_q == 64'd8)
                    && (src1_nb2_q == 64'd8)
                    && (src1_nb3_q == 64'd8)
                    && (dst_ne0_q == 32'd512)
                    && (dst_ne1_q == cache_capacity_q)
                    && (dst_nb1_q == 64'd1024)
                    && (dst_nb2_q == set_dst_nb2_w[63:0])
                    && (dst_nb3_q == set_dst_nb2_w[63:0]);
            end else begin
                layout_ok_w = layout_ok_w
                    && (src0_ne0_q == 32'd1)
                    && (src0_ne1_q == 32'd512)
                    && (src0_ne2_q == 32'd1)
                    && (src0_ne3_q == 32'd1)
                    && (src0_nb1_q == 64'd4)
                    && (src0_nb2_q == 64'd2048)
                    && (src0_nb3_q == 64'd2048)
                    && (src1_ne0_q == 32'd512)
                    && (src1_ne1_q == 32'd1)
                    && (src1_ne2_q == 32'd1)
                    && (src1_ne3_q == 32'd1)
                    && (src1_nb1_q == 64'd4096)
                    && (src1_nb2_q == 64'd4096)
                    && (src1_nb3_q == 64'd4096)
                    && (dst_ne0_q == 32'd1)
                    && ({96'b0, dst_ne1_q} == set_dst_ne1_w)
                    && (dst_nb1_q == 64'd2)
                    && (dst_nb2_q == set_dst_nb2_w[63:0])
                    && (dst_nb3_q == set_dst_nb2_w[63:0]);
            end
        end

        if (empty_mover_w) begin
            src0_window_ok_w =
                   (src0_sem_start_w[127:64] == 64'b0)
                && (src0_view_off_q <= src0_region_size_q)
                && (src0_sem_start_w >= {64'b0, src0_window_base_q})
                && (src0_sem_start_w <= src0_window_end_w);
            src1_window_ok_w = (operation_q != OP_CPY_F32)
                || ((src1_sem_start_w[127:64] == 64'b0)
                    && (src1_view_off_q <= src1_region_size_q)
                    && (src1_sem_start_w >= {64'b0, src1_window_base_q})
                    && (src1_sem_start_w <= src1_window_end_w));
            dst_window_ok_w =
                   (dst_sem_start_w[127:64] == 64'b0)
                && (dst_view_off_q <= dst_region_size_q)
                && (dst_sem_start_w >= {64'b0, dst_window_base_q})
                && (dst_sem_start_w <= dst_window_end_w);
            alias_ok_w = 1'b1;
        end else begin
            src0_window_ok_w = (src0_window_bytes_q != 64'b0)
                && (src0_last_rel_w <= {64'b0, src0_region_size_q})
                && (src0_sem_start_w[127:64] == 64'b0)
                && (src0_sem_end_w[127:64] == 64'b0)
                && (src0_phys_start_w[127:64] == 64'b0)
                && (src0_phys_end_w[127:64] == 64'b0)
                && (src0_phys_start_w >= {64'b0, src0_region_base_q})
                && (src0_phys_end_w <= src0_region_end_w)
                && (src0_phys_start_w >= {64'b0, src0_window_base_q})
                && (src0_phys_end_w <= src0_window_end_w);
            if (src1_active_w) begin
                src1_window_ok_w = (src1_window_bytes_q != 64'b0)
                    && (src1_last_rel_w <= {64'b0, src1_region_size_q})
                    && (src1_sem_start_w[127:64] == 64'b0)
                    && (src1_sem_end_w[127:64] == 64'b0)
                    && (src1_phys_start_w[127:64] == 64'b0)
                    && (src1_phys_end_w[127:64] == 64'b0)
                    && (src1_phys_start_w >= {64'b0, src1_region_base_q})
                    && (src1_phys_end_w <= src1_region_end_w)
                    && (src1_phys_start_w >= {64'b0, src1_window_base_q})
                    && (src1_phys_end_w <= src1_window_end_w);
            end else begin
                src1_window_ok_w = (src1_window_end_w[127:64] == 64'b0);
            end
            dst_window_ok_w = (dst_window_bytes_q != 64'b0)
                && (dst_last_rel_w <= {64'b0, dst_region_size_q})
                && (dst_sem_start_w[127:64] == 64'b0)
                && (dst_sem_end_w[127:64] == 64'b0)
                && (dst_phys_start_w[127:64] == 64'b0)
                && (dst_phys_end_w[127:64] == 64'b0)
                && (dst_phys_start_w >= {64'b0, dst_region_base_q})
                && (dst_phys_end_w <= dst_region_end_w)
                && (dst_phys_start_w >= {64'b0, dst_window_base_q})
                && (dst_phys_end_w <= dst_window_end_w);
            alias_ok_w = ((dst_phys_end_w <= src0_phys_start_w)
                          || (dst_phys_start_w >= src0_phys_end_w));
            if (src1_active_w) begin
                alias_ok_w = alias_ok_w
                    && ((dst_phys_end_w <= src1_phys_start_w)
                        || (dst_phys_start_w >= src1_phys_end_w));
            end
        end

        if (!descriptor_ok_w)
            preflight_error_w = ERR_DESCRIPTOR;
        else if (!layout_ok_w)
            preflight_error_w = ERR_LAYOUT;
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

        child_gmem_floor_w = src0_window_base_q;
        if (src1_active_w && (src1_window_base_q < child_gmem_floor_w))
            child_gmem_floor_w = src1_window_base_q;
        if (dst_window_base_q < child_gmem_floor_w)
            child_gmem_floor_w = dst_window_base_q;
        child_gmem_limit_w = src0_window_end_w[63:0];
        if (src1_active_w
                && (src1_window_end_w[63:0] > child_gmem_limit_w))
            child_gmem_limit_w = src1_window_end_w[63:0];
        if (dst_window_end_w[63:0] > child_gmem_limit_w)
            child_gmem_limit_w = dst_window_end_w[63:0];

        expected_indices_w = 64'b0;
        expected_source_elements_w = output_count_w[63:0];
        expected_elements_w = output_count_w[63:0];
        expected_read_beats_w = output_count_w[63:0];
        expected_read_bytes_w = output_bytes_w[63:0];
        expected_write_bytes_w = output_bytes_w[63:0];
        if (operation_q == OP_SET_ROWS_NATIVE) begin
            expected_indices_w = 64'd1;
            expected_source_elements_w = 64'd512;
            expected_elements_w = 64'd512;
            expected_read_beats_w = 64'd513;
            expected_read_bytes_w = 64'd2056;
            expected_write_bytes_w = 64'd1024;
        end else if (operation_q == OP_SET_ROWS_TRANSPOSED) begin
            expected_indices_w = 64'd512;
            expected_source_elements_w = 64'd512;
            expected_elements_w = 64'd512;
            expected_read_beats_w = 64'd1024;
            expected_read_bytes_w = 64'd6144;
            expected_write_bytes_w = 64'd1024;
        end
    end

    // ------------------------------------------------------------------
    // Real child engines and exclusive GMEM ownership.
    // ------------------------------------------------------------------
    wire mover_ready_w;
    wire mover_busy_w;
    wire mover_start_w;
    wire [1:0] mover_opcode_w;
    wire mover_req_valid_w;
    wire mover_req_write_w;
    wire [63:0] mover_req_addr_w;
    wire [63:0] mover_req_wdata_w;
    wire [7:0] mover_req_wstrb_w;
    wire mover_rsp_ready_w;
    wire mover_done_w;
    wire mover_error_w;
    wire [4:0] mover_error_code_w;
    wire [63:0] mover_elements_w;
    wire [63:0] mover_bytes_w;
    wire [63:0] mover_read_beats_w;
    wire [63:0] mover_write_beats_w;
    wire [63:0] mover_writes_accepted_w;
    wire [63:0] mover_active_cycles_w;

    wire set_ready_w;
    wire set_busy_w;
    wire set_start_w;
    wire set_req_valid_w;
    wire set_req_write_w;
    wire [63:0] set_req_addr_w;
    wire [63:0] set_req_wdata_w;
    wire [7:0] set_req_wstrb_w;
    wire set_rsp_ready_w;
    wire set_done_w;
    wire set_error_w;
    wire [4:0] set_error_code_w;
    wire [31:0] set_indices_validated_w;
    wire [31:0] set_values_validated_w;
    wire [31:0] set_writes_completed_w;
    wire [31:0] set_bytes_written_w;
    wire [31:0] set_read_beats_w;
    wire [31:0] set_write_beats_w;
    wire [31:0] set_writes_accepted_w;
    wire [63:0] set_active_cycles_w;

    assign mover_start_w = (state_q == ST_CHILD_START)
                         && mover_operation_w && mover_ready_w;
    assign mover_opcode_w = (operation_q == OP_CONCAT0_F32)
                          ? 2'd3 : operation_q[1:0];
    assign set_start_w = (state_q == ST_CHILD_START)
                       && set_operation_w && set_ready_w;

    assign gmem_req_valid_o = (state_q == ST_CHILD_RUN)
                            && (mover_operation_w
                                ? mover_req_valid_w : set_req_valid_w);
    assign gmem_req_write_o = mover_operation_w
                            ? mover_req_write_w : set_req_write_w;
    assign gmem_req_addr_o = mover_operation_w
                           ? mover_req_addr_w : set_req_addr_w;
    assign gmem_req_wdata_o = mover_operation_w
                            ? mover_req_wdata_w : set_req_wdata_w;
    assign gmem_req_wstrb_o = mover_operation_w
                            ? mover_req_wstrb_w : set_req_wstrb_w;
    assign gmem_rsp_ready_o = (state_q == ST_CHILD_RUN)
                            && (mover_operation_w
                                ? mover_rsp_ready_w : set_rsp_ready_w);
    assign gmem_req_fire_w = gmem_req_valid_o && gmem_req_ready_i;
    assign gmem_rsp_fire_w = gmem_rsp_valid_i && gmem_rsp_ready_o;

    TensorNpuTensorMover #(
        .STALL_TIMEOUT_CYCLES(STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES(COMMAND_TIMEOUT_CYCLES)
    ) u_mover (
        .clk_i(clk_i), .rst_i(rst_i),
        .start_i(mover_start_w), .ready_o(mover_ready_w),
        .busy_o(mover_busy_w), .opcode_i(mover_opcode_w),
        .gmem_floor_i(child_gmem_floor_w),
        .gmem_limit_i(child_gmem_limit_w),
        .src0_region_base_i(src0_region_base_q),
        .src0_region_size_i(src0_region_size_q),
        .src0_view_off_i(src0_view_off_q),
        .src0_ne0_i(src0_ne0_q), .src0_ne1_i(src0_ne1_q),
        .src0_ne2_i(src0_ne2_q), .src0_ne3_i(src0_ne3_q),
        .src0_nb0_i(src0_nb0_q), .src0_nb1_i(src0_nb1_q),
        .src0_nb2_i(src0_nb2_q), .src0_nb3_i(src0_nb3_q),
        .src1_region_base_i(src1_region_base_q),
        .src1_region_size_i(src1_region_size_q),
        .src1_view_off_i(src1_view_off_q),
        .src1_ne0_i(src1_ne0_q), .src1_ne1_i(src1_ne1_q),
        .src1_ne2_i(src1_ne2_q), .src1_ne3_i(src1_ne3_q),
        .src1_nb0_i(src1_nb0_q), .src1_nb1_i(src1_nb1_q),
        .src1_nb2_i(src1_nb2_q), .src1_nb3_i(src1_nb3_q),
        .dst_region_base_i(dst_region_base_q),
        .dst_region_size_i(dst_region_size_q),
        .dst_view_off_i(dst_view_off_q),
        .gmem_req_valid_o(mover_req_valid_w),
        .gmem_req_ready_i(gmem_req_ready_i && (state_q == ST_CHILD_RUN)
                          && mover_operation_w),
        .gmem_req_write_o(mover_req_write_w),
        .gmem_req_addr_o(mover_req_addr_w),
        .gmem_req_wdata_o(mover_req_wdata_w),
        .gmem_req_wstrb_o(mover_req_wstrb_w),
        .gmem_rsp_valid_i(gmem_rsp_valid_i && (state_q == ST_CHILD_RUN)
                          && mover_operation_w),
        .gmem_rsp_ready_o(mover_rsp_ready_w),
        .gmem_rsp_rdata_i(gmem_rsp_rdata_i),
        .gmem_rsp_error_i(gmem_rsp_error_i),
        .done_o(mover_done_w), .error_o(mover_error_w),
        .error_code_o(mover_error_code_w),
        .elements_done_o(mover_elements_w),
        .bytes_moved_o(mover_bytes_w),
        .gmem_read_beats_o(mover_read_beats_w),
        .gmem_write_beats_o(mover_write_beats_w),
        .writes_accepted_o(mover_writes_accepted_w),
        .active_cycles_o(mover_active_cycles_w)
    );

    TensorNpuSetRowsEngine #(
        .VALUE_ELEMENTS(512),
        .STALL_TIMEOUT_CYCLES(STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES(COMMAND_TIMEOUT_CYCLES)
    ) u_set_rows (
        .clk_i(clk_i), .rst_i(rst_i),
        .start_i(set_start_w), .ready_o(set_ready_w),
        .busy_o(set_busy_w),
        .profile_i(operation_q == OP_SET_ROWS_NATIVE ? 2'd0 : 2'd1),
        .cache_capacity_i(cache_capacity_q),
        .physical_slot_i(physical_slot_q),
        .gmem_floor_i(child_gmem_floor_w),
        .gmem_limit_i(child_gmem_limit_w),
        .values_region_base_i(src0_region_base_q),
        .values_region_size_i(src0_region_size_q),
        .values_view_off_i(src0_view_off_q),
        .indices_region_base_i(src1_region_base_q),
        .indices_region_size_i(src1_region_size_q),
        .indices_view_off_i(src1_view_off_q),
        .dst_region_base_i(dst_region_base_q),
        .dst_region_size_i(dst_region_size_q),
        .dst_view_off_i(dst_view_off_q),
        .gmem_req_valid_o(set_req_valid_w),
        .gmem_req_ready_i(gmem_req_ready_i && (state_q == ST_CHILD_RUN)
                          && set_operation_w),
        .gmem_req_write_o(set_req_write_w),
        .gmem_req_addr_o(set_req_addr_w),
        .gmem_req_wdata_o(set_req_wdata_w),
        .gmem_req_wstrb_o(set_req_wstrb_w),
        .gmem_rsp_valid_i(gmem_rsp_valid_i && (state_q == ST_CHILD_RUN)
                          && set_operation_w),
        .gmem_rsp_ready_o(set_rsp_ready_w),
        .gmem_rsp_rdata_i(gmem_rsp_rdata_i),
        .gmem_rsp_error_i(gmem_rsp_error_i),
        .done_o(set_done_w), .error_o(set_error_w),
        .error_code_o(set_error_code_w),
        .indices_validated_o(set_indices_validated_w),
        .values_validated_o(set_values_validated_w),
        .writes_completed_o(set_writes_completed_w),
        .bytes_written_o(set_bytes_written_w),
        .gmem_read_beats_o(set_read_beats_w),
        .gmem_write_beats_o(set_write_beats_w),
        .writes_accepted_o(set_writes_accepted_w),
        .active_cycles_o(set_active_cycles_w)
    );

    reg [4:0] mapped_child_error_w;
    always @(*) begin
        mapped_child_error_w = ERR_CHILD;
        if (mover_operation_w) begin
            case (mover_error_code_w)
                5'd7: mapped_child_error_w = ERR_GMEM_RESPONSE;
                5'd8: mapped_child_error_w = ERR_STALL_TIMEOUT;
                5'd9: mapped_child_error_w = ERR_COMMAND_TIMEOUT;
                5'd10: mapped_child_error_w = ERR_INTERNAL;
                default: mapped_child_error_w = ERR_CHILD;
            endcase
        end else begin
            case (set_error_code_w)
                5'd8, 5'd9: mapped_child_error_w = ERR_DOMAIN;
                5'd10: mapped_child_error_w = ERR_GMEM_RESPONSE;
                5'd11: mapped_child_error_w = ERR_STALL_TIMEOUT;
                5'd12: mapped_child_error_w = ERR_COMMAND_TIMEOUT;
                5'd13: mapped_child_error_w = ERR_INTERNAL;
                default: mapped_child_error_w = ERR_CHILD;
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Resident owner, exact transport counters and success-only commit.
    // ------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            operation_q <= OP_CPY_F32;
            npu_required_q <= 1'b0;
            command_id_q <= 64'b0;
            canonical_node_id_lo_q <= 64'b0;
            canonical_node_id_hi_q <= 64'b0;
            dst_shadow_private_q <= 1'b0;
            windows_generation_valid_q <= 1'b0;
            dst_descriptor_flags_q <= 32'b0;
            op_params_q <= 512'b0;
            source_arity_q <= 3'b0;
            src0_descriptor_flags_q <= 32'b0;
            src1_descriptor_flags_q <= 32'b0;
            src2_descriptor_flags_q <= 32'b0;
            src2_matches_dst_q <= 1'b0;
            src0_dtype_q <= 8'b0;
            src0_region_base_q <= 64'b0;
            src0_region_size_q <= 64'b0;
            src0_view_off_q <= 64'b0;
            src0_ne0_q <= 32'b0; src0_ne1_q <= 32'b0;
            src0_ne2_q <= 32'b0; src0_ne3_q <= 32'b0;
            src0_nb0_q <= 64'b0; src0_nb1_q <= 64'b0;
            src0_nb2_q <= 64'b0; src0_nb3_q <= 64'b0;
            src1_dtype_q <= 8'b0;
            src1_region_base_q <= 64'b0;
            src1_region_size_q <= 64'b0;
            src1_view_off_q <= 64'b0;
            src1_ne0_q <= 32'b0; src1_ne1_q <= 32'b0;
            src1_ne2_q <= 32'b0; src1_ne3_q <= 32'b0;
            src1_nb0_q <= 64'b0; src1_nb1_q <= 64'b0;
            src1_nb2_q <= 64'b0; src1_nb3_q <= 64'b0;
            dst_dtype_q <= 8'b0;
            dst_region_base_q <= 64'b0;
            dst_region_size_q <= 64'b0;
            dst_view_off_q <= 64'b0;
            dst_ne0_q <= 32'b0; dst_ne1_q <= 32'b0;
            dst_ne2_q <= 32'b0; dst_ne3_q <= 32'b0;
            dst_nb0_q <= 64'b0; dst_nb1_q <= 64'b0;
            dst_nb2_q <= 64'b0; dst_nb3_q <= 64'b0;
            cache_capacity_q <= 32'b0;
            physical_slot_q <= 32'b0;
            src0_window_base_q <= 64'b0;
            src0_window_bytes_q <= 64'b0;
            src0_window_read_q <= 1'b0;
            src0_window_write_q <= 1'b0;
            src1_window_base_q <= 64'b0;
            src1_window_bytes_q <= 64'b0;
            src1_window_read_q <= 1'b0;
            src1_window_write_q <= 1'b0;
            dst_window_base_q <= 64'b0;
            dst_window_bytes_q <= 64'b0;
            dst_window_read_q <= 1'b0;
            dst_window_write_q <= 1'b0;
            error_code_q <= ERR_NONE;
            child_error_code_q <= 5'b0;
            indices_completed_q <= 64'b0;
            source_elements_completed_q <= 64'b0;
            elements_completed_q <= 64'b0;
            gmem_read_beats_q <= 64'b0;
            gmem_read_responses_q <= 64'b0;
            read_payload_bytes_q <= 64'b0;
            gmem_write_beats_q <= 64'b0;
            gmem_write_responses_q <= 64'b0;
            write_payload_bytes_q <= 64'b0;
            active_cycles_q <= 64'b0;
            outstanding_q <= 1'b0;
            outstanding_write_q <= 1'b0;
            outstanding_payload_bytes_q <= 4'b0;
            npu_required_issued_q <= 64'b0;
            npu_required_completed_q <= 64'b0;
        end else begin
            if ((state_q != ST_IDLE) && (state_q != ST_DONE)
                    && (state_q != ST_ERROR)) begin
                active_cycles_q <= active_cycles_q + 64'd1;
            end

            if (gmem_req_fire_w) begin
                outstanding_q <= 1'b1;
                outstanding_write_q <= gmem_req_write_o;
                if (gmem_req_write_o) begin
                    gmem_write_beats_q <= gmem_write_beats_q + 64'd1;
                    outstanding_payload_bytes_q <= set_operation_w
                                                 ? 4'd2 : 4'd4;
                end else begin
                    gmem_read_beats_q <= gmem_read_beats_q + 64'd1;
                    if (set_operation_w
                            && (gmem_read_beats_q < expected_indices_w))
                        outstanding_payload_bytes_q <= 4'd8;
                    else
                        outstanding_payload_bytes_q <= 4'd4;
                end
            end
            if (gmem_rsp_fire_w) begin
                outstanding_q <= 1'b0;
                if (outstanding_write_q) begin
                    gmem_write_responses_q <= gmem_write_responses_q + 64'd1;
                    if (!gmem_rsp_error_i)
                        write_payload_bytes_q <= write_payload_bytes_q
                            + {60'b0, outstanding_payload_bytes_q};
                end else begin
                    gmem_read_responses_q <= gmem_read_responses_q + 64'd1;
                    if (!gmem_rsp_error_i)
                        read_payload_bytes_q <= read_payload_bytes_q
                            + {60'b0, outstanding_payload_bytes_q};
                end
            end

            case (state_q)
                ST_IDLE: begin
                    outstanding_q <= 1'b0;
                    outstanding_write_q <= 1'b0;
                    outstanding_payload_bytes_q <= 4'b0;
                    if (start_fire_w) begin
                        operation_q <= operation_i;
                        npu_required_q <= npu_required_i;
                        command_id_q <= command_id_i;
                        canonical_node_id_lo_q <= canonical_node_id_lo_i;
                        canonical_node_id_hi_q <= canonical_node_id_hi_i;
                        dst_shadow_private_q <= dst_shadow_private_i;
                        windows_generation_valid_q
                            <= windows_generation_valid_i;
                        dst_descriptor_flags_q <= dst_descriptor_flags_i;
                        op_params_q <= op_params_i;
                        source_arity_q <= source_arity_i;
                        src0_descriptor_flags_q
                            <= src0_descriptor_flags_i;
                        src1_descriptor_flags_q
                            <= src1_descriptor_flags_i;
                        src2_descriptor_flags_q
                            <= src2_descriptor_flags_i;
                        src2_matches_dst_q <= src2_matches_dst_i;
                        src0_dtype_q <= src0_dtype_i;
                        src0_region_base_q <= src0_region_base_i;
                        src0_region_size_q <= src0_region_size_i;
                        src0_view_off_q <= src0_view_off_i;
                        src0_ne0_q <= src0_ne0_i;
                        src0_ne1_q <= src0_ne1_i;
                        src0_ne2_q <= src0_ne2_i;
                        src0_ne3_q <= src0_ne3_i;
                        src0_nb0_q <= src0_nb0_i;
                        src0_nb1_q <= src0_nb1_i;
                        src0_nb2_q <= src0_nb2_i;
                        src0_nb3_q <= src0_nb3_i;
                        src1_dtype_q <= src1_dtype_i;
                        src1_region_base_q <= src1_region_base_i;
                        src1_region_size_q <= src1_region_size_i;
                        src1_view_off_q <= src1_view_off_i;
                        src1_ne0_q <= src1_ne0_i;
                        src1_ne1_q <= src1_ne1_i;
                        src1_ne2_q <= src1_ne2_i;
                        src1_ne3_q <= src1_ne3_i;
                        src1_nb0_q <= src1_nb0_i;
                        src1_nb1_q <= src1_nb1_i;
                        src1_nb2_q <= src1_nb2_i;
                        src1_nb3_q <= src1_nb3_i;
                        dst_dtype_q <= dst_dtype_i;
                        dst_region_base_q <= dst_region_base_i;
                        dst_region_size_q <= dst_region_size_i;
                        dst_view_off_q <= dst_view_off_i;
                        dst_ne0_q <= dst_ne0_i;
                        dst_ne1_q <= dst_ne1_i;
                        dst_ne2_q <= dst_ne2_i;
                        dst_ne3_q <= dst_ne3_i;
                        dst_nb0_q <= dst_nb0_i;
                        dst_nb1_q <= dst_nb1_i;
                        dst_nb2_q <= dst_nb2_i;
                        dst_nb3_q <= dst_nb3_i;
                        cache_capacity_q <= cache_capacity_i;
                        physical_slot_q <= physical_slot_i;
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
                        error_code_q <= ERR_NONE;
                        child_error_code_q <= 5'b0;
                        indices_completed_q <= 64'b0;
                        source_elements_completed_q <= 64'b0;
                        elements_completed_q <= 64'b0;
                        gmem_read_beats_q <= 64'b0;
                        gmem_read_responses_q <= 64'b0;
                        read_payload_bytes_q <= 64'b0;
                        gmem_write_beats_q <= 64'b0;
                        gmem_write_responses_q <= 64'b0;
                        write_payload_bytes_q <= 64'b0;
                        active_cycles_q <= 64'd1;
                        if (npu_required_i)
                            npu_required_issued_q
                                <= npu_required_issued_q + 64'd1;
                        state_q <= ST_PREFLIGHT;
                    end
                end

                ST_PREFLIGHT: begin
                    if (preflight_error_w != ERR_NONE) begin
                        error_code_q <= preflight_error_w;
                        state_q <= ST_ERROR;
                    end else begin
                        state_q <= ST_CHILD_START;
                    end
                end

                ST_CHILD_START: begin
                    if ((mover_operation_w && !mover_ready_w)
                            || (set_operation_w && !set_ready_w)) begin
                        error_code_q <= ERR_CHILD_PROTOCOL;
                        state_q <= ST_ERROR;
                    end else begin
                        state_q <= ST_CHILD_RUN;
                    end
                end

                ST_CHILD_RUN: begin
                    if ((mover_operation_w && mover_error_w)
                            || (set_operation_w && set_error_w)) begin
                        child_error_code_q <= mover_operation_w
                                            ? mover_error_code_w
                                            : set_error_code_w;
                        error_code_q <= mapped_child_error_w;
                        indices_completed_q <= set_operation_w
                            ? {32'b0, set_indices_validated_w} : 64'b0;
                        source_elements_completed_q <= mover_operation_w
                            ? mover_elements_w
                            : {32'b0, set_values_validated_w};
                        elements_completed_q <= mover_operation_w
                            ? mover_elements_w
                            : {32'b0, set_writes_completed_w};
                        if (outstanding_q) begin
                            error_code_q <= ERR_CHILD_PROTOCOL;
                        end
                        state_q <= ST_ERROR;
                    end else if ((mover_operation_w && mover_done_w)
                            || (set_operation_w && set_done_w)) begin
                        child_error_code_q <= 5'b0;
                        indices_completed_q <= expected_indices_w;
                        source_elements_completed_q
                            <= expected_source_elements_w;
                        elements_completed_q <= expected_elements_w;
                        if (outstanding_q
                                || (gmem_read_beats_q
                                    != expected_read_beats_w)
                                || (gmem_read_responses_q
                                    != expected_read_beats_w)
                                || (read_payload_bytes_q
                                    != expected_read_bytes_w)
                                || (gmem_write_beats_q
                                    != expected_elements_w)
                                || (gmem_write_responses_q
                                    != expected_elements_w)
                                || (write_payload_bytes_q
                                    != expected_write_bytes_w)
                                || (mover_operation_w
                                    && ((mover_elements_w
                                         != expected_elements_w)
                                        || (mover_bytes_w
                                            != expected_write_bytes_w)
                                        || (mover_read_beats_w
                                            != expected_read_beats_w)
                                        || (mover_write_beats_w
                                            != expected_elements_w)
                                        || (mover_writes_accepted_w
                                            != expected_elements_w)))
                                || (set_operation_w
                                    && (({32'b0, set_indices_validated_w}
                                         != expected_indices_w)
                                        || (set_values_validated_w != 32'd512)
                                        || (set_writes_completed_w != 32'd512)
                                        || (set_bytes_written_w != 32'd1024)
                                        || ({32'b0, set_read_beats_w}
                                            != expected_read_beats_w)
                                        || (set_write_beats_w != 32'd512)
                                        || (set_writes_accepted_w
                                            != 32'd512)))) begin
                            error_code_q <= ERR_CHILD_PROTOCOL;
                            state_q <= ST_ERROR;
                        end else begin
                            if (npu_required_q)
                                npu_required_completed_q
                                    <= npu_required_completed_q + 64'd1;
                            state_q <= ST_DONE;
                        end
                    end else if ((mover_operation_w && !mover_busy_w)
                            || (set_operation_w && !set_busy_w)) begin
                        error_code_q <= ERR_CHILD_PROTOCOL;
                        state_q <= ST_ERROR;
                    end
                end

                ST_DONE: state_q <= ST_IDLE;
                ST_ERROR: state_q <= ST_IDLE;
                default: begin
                    error_code_q <= ERR_INTERNAL;
                    state_q <= ST_ERROR;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
