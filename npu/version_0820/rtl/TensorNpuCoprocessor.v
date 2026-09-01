`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

// Functional-simulation Tensor coprocessor top.
//
// The CPU owns LO/HI pairing and precise ROB lifetime.  This module sees one
// already-paired logical command and returns one terminal completion carrying
// the same full ProducerId.  A terminal error is held until the CPU accepts the
// completion, then STATUS remains fail-closed until error_clear_i.
module TensorNpuCoprocessor #(
  parameter integer LMEM_BYTES = 4096,
  parameter integer PID_W = 8,
  parameter integer OPCLASS_W = 8,
  // The public/default build retains the scalar raw-GMEM GEMV adapter.  The
  // production Qwen build opts into the transactional raw-Q8 portal and its
  // real Row-SIMD numerical child explicitly at elaboration time.
  parameter integer Q8_GEMV_PORTAL_ENABLE = 0,
  parameter integer Q8_GEMV_ROW_LANES = 4,
  parameter integer Q8_GEMV_MAC_LANES = 32,
  parameter integer Q8_GEMV_TILE_FUNCTIONAL_ENABLE = 0,
  // VECTOR_F32 keeps its proven raw-GMEM adapter in public/default builds.
  // Production simulation may opt into a raw-copy-only lane portal whose
  // sole numerical child remains the RTL SIMD AddMul core.
  parameter integer F32_ALU_PORTAL_ENABLE = 0,
  parameter integer F32_ALU_PORTAL_LANES = 8,
  parameter integer F32_MOVER_PORTAL_ENABLE = 0,
  parameter integer F32_MOVER_PORTAL_LANES = 16,
  // Simulation-only production functional path.  The parameter is inert
  // unless the production file set also defines NPU_FUNCTIONAL_COMMAND_DPI;
  // public/direct RTL builds therefore retain the qualified adapters above.
  parameter integer COMMAND_FUNCTIONAL_ENABLE = 0,
  parameter [31:0] MACRO_CAPABILITY_EPOCH = 32'h00000001
) (
  input  wire                         clk,
  input  wire                         rst,

  input  wire                         cmd_valid_i,
  output wire                         cmd_ready_o,
  input  wire                         cmd_is_64_i,
  input  wire [63:0]                  cmd_bits_i,
  input  wire [63:0]                  cmd_rs_value_i,
  input  wire [PID_W-1:0]             cmd_producer_id_i,
  input  wire                         cmd_npu_required_i,
  input  wire [OPCLASS_W-1:0]         cmd_opclass_i,

  // Parsed macro descriptor.  The C++ byte adapter may parse ABI framing,
  // but all tensor arithmetic remains behind this clocked RTL transaction.
  input  wire                         macro_cmd_valid_i,
  output wire                         macro_cmd_ready_o,
  input  wire                         macro_abi_valid_i,
  input  wire [31:0]                  macro_kernel_id_i,
  input  wire [31:0]                  macro_command_flags_i,
  input  wire [31:0]                  macro_context_id_i,
  input  wire [31:0]                  macro_capability_epoch_i,
  input  wire [63:0]                  macro_sequence_id_i,
  input  wire [63:0]                  macro_producer_id_i,
  input  wire [63:0]                  macro_user_tag_i,
  input  wire [31:0]                  macro_node_count_i,
  input  wire [63:0]                  macro_node_hash_lo_i,
  input  wire [63:0]                  macro_node_hash_hi_i,
  input  wire [63:0]                  macro_deadline_cycles_i,
  input  wire [31:0]                  macro_vector_op_i,
  input  wire [31:0]                  macro_vector_flags_i,
  input  wire [63:0]                  macro_src0_iova_i,
  input  wire [63:0]                  macro_src1_iova_i,
  input  wire [63:0]                  macro_src2_iova_i,
  input  wire [63:0]                  macro_dst_iova_i,
  input  wire [63:0]                  macro_scratch_iova_i,
  input  wire [63:0]                  macro_element_count_i,
  input  wire [31:0]                  macro_outer_count_i,
  input  wire [31:0]                  macro_dtype_i,
  input  wire [63:0]                  macro_src0_stride_i,
  input  wire [63:0]                  macro_src1_stride_i,
  input  wire [63:0]                  macro_src2_stride_i,
  input  wire [63:0]                  macro_dst_stride_i,
  input  wire [31:0]                  macro_scalar0_i,
  input  wire [31:0]                  macro_scalar1_i,
  input  wire [31:0]                  macro_scratch_bytes_i,
  input  wire [31:0]                  macro_rope_position_i,
  input  wire [63:0]                  macro_src0_window_base_i,
  input  wire [63:0]                  macro_src0_window_size_i,
  input  wire [1:0]                   macro_src0_window_perm_i,
  input  wire [63:0]                  macro_src1_window_base_i,
  input  wire [63:0]                  macro_src1_window_size_i,
  input  wire [1:0]                   macro_src1_window_perm_i,
  input  wire [63:0]                  macro_dst_window_base_i,
  input  wire [63:0]                  macro_dst_window_size_i,
  input  wire [1:0]                   macro_dst_window_perm_i,
  input  wire                         macro_windows_generation_valid_i,

  output wire                         completion_valid_o,
  input  wire                         completion_ready_i,
  output wire [PID_W-1:0]             completion_producer_id_o,
  output wire                         completion_npu_required_o,
  output wire [OPCLASS_W-1:0]         completion_opclass_o,
  output wire                         completion_error_o,
  output wire [`NPU_ERROR_W-1:0]      completion_error_code_o,
  output wire                         completion_is_macro_o,
  output wire [31:0]                  completion_macro_status_o,
  output wire [31:0]                  completion_macro_error_class_o,
  output wire [31:0]                  completion_macro_kernel_id_o,
  output wire [31:0]                  completion_macro_command_flags_o,
  // v4 profile identity comes from the resident transaction, not a host
  // function argument.  It is held with the rest of the completion payload.
  output wire [31:0]                  completion_macro_vector_flags_o,
  output wire [31:0]                  completion_macro_context_id_o,
  output wire [63:0]                  completion_macro_sequence_id_o,
  output wire [63:0]                  completion_macro_producer_id_o,
  output wire [63:0]                  completion_macro_user_tag_o,
  output wire [31:0]                  completion_macro_covered_node_count_o,
  output wire [63:0]                  completion_macro_node_hash_lo_o,
  output wire [63:0]                  completion_macro_node_hash_hi_o,
  output wire [63:0]                  completion_macro_npu_cycles_o,
  output wire [63:0]                  completion_macro_gmem_read_bytes_o,
  output wire [63:0]                  completion_macro_gmem_write_bytes_o,
  output wire [63:0]                  completion_macro_q8_mac_count_o,
  output wire [63:0]                  completion_macro_vector_element_count_o,
  output wire [63:0]                  completion_macro_state_update_count_o,

  input  wire                         desc_write_valid_i,
  output wire                         desc_write_ready_o,
  input  wire [5:0]                   desc_write_id_i,
  input  wire [2:0]                   desc_write_word_i,
  input  wire [63:0]                  desc_write_data_i,
  output wire                         desc_write_error_o,
  output wire [`NPU_ERROR_W-1:0]      desc_write_error_code_o,

  // Simulation-only LMEM access.  It is available only when neither command
  // engine owns LMEM; it never counts as a model offload.
  input  wire                         host_lmem_rd_valid_i,
  input  wire [31:0]                  host_lmem_rd_addr_i,
  input  wire [3:0]                   host_lmem_rd_bytes_i,
  output wire [63:0]                  host_lmem_rd_data_o,
  output wire                         host_lmem_rd_oob_o,
  input  wire                         host_lmem_wr_valid_i,
  input  wire [31:0]                  host_lmem_wr_addr_i,
  input  wire [63:0]                  host_lmem_wr_data_i,
  input  wire [7:0]                   host_lmem_wr_strb_i,
  output wire                         host_lmem_wr_oob_o,
  output wire                         host_lmem_ready_o,

  output wire                         gmem_req_valid_o,
  input  wire                         gmem_req_ready_i,
  output wire                         gmem_req_write_o,
  output wire [63:0]                  gmem_req_addr_o,
  output wire [63:0]                  gmem_req_wdata_o,
  output wire [7:0]                   gmem_req_wstrb_o,
  input  wire                         gmem_rsp_valid_i,
  output wire                         gmem_rsp_ready_o,
  input  wire [63:0]                  gmem_rsp_rdata_i,
  input  wire                         gmem_rsp_error_i,

  // Simulation memory portal for raw Q8_0 blocks.  It is transport only:
  // the host may copy exactly the addressed 34 bytes but performs no tensor
  // arithmetic.  Inactive lanes publish address zero.  At most one request
  // group is outstanding and the response mask must match exactly.
  output wire                         q8_portal_req_valid_o,
  input  wire                         q8_portal_req_ready_i,
  output wire [Q8_GEMV_ROW_LANES-1:0] q8_portal_req_mask_o,
  output wire [(Q8_GEMV_ROW_LANES*64)-1:0]
                                      q8_portal_req_addr_o,
  input  wire                         q8_portal_rsp_valid_i,
  output wire                         q8_portal_rsp_ready_o,
  input  wire [Q8_GEMV_ROW_LANES-1:0] q8_portal_rsp_mask_i,
  input  wire [(Q8_GEMV_ROW_LANES*272)-1:0]
                                      q8_portal_rsp_blocks_i,
  input  wire                         q8_portal_rsp_error_i,
  output wire [63:0]                  q8_portal_request_count_o,
  output wire [63:0]                  q8_portal_response_count_o,
  output wire [63:0]                  q8_portal_block_count_o,
  output wire [63:0]                  q8_portal_byte_count_o,
  output wire                         q8_portal_outstanding_o,

  // Simulation memory portal for raw F32 VECTOR_F32 lane batches.  The host
  // is limited to copying the addressed words; all address generation,
  // arithmetic, error handling, and commit decisions remain in RTL.
  output wire                         f32_alu_portal_req_valid_o,
  input  wire                         f32_alu_portal_req_ready_i,
  output wire                         f32_alu_portal_req_write_o,
  output wire [F32_ALU_PORTAL_LANES-1:0]
                                      f32_alu_portal_req_mask_o,
  output wire [(F32_ALU_PORTAL_LANES*64)-1:0]
                                      f32_alu_portal_req_src0_addr_o,
  output wire [(F32_ALU_PORTAL_LANES*64)-1:0]
                                      f32_alu_portal_req_src1_addr_o,
  output wire [(F32_ALU_PORTAL_LANES*64)-1:0]
                                      f32_alu_portal_req_dst_addr_o,
  output wire [(F32_ALU_PORTAL_LANES*32)-1:0]
                                      f32_alu_portal_req_wdata_o,
  input  wire                         f32_alu_portal_rsp_valid_i,
  output wire                         f32_alu_portal_rsp_ready_o,
  input  wire [F32_ALU_PORTAL_LANES-1:0]
                                      f32_alu_portal_rsp_mask_i,
  input  wire [(F32_ALU_PORTAL_LANES*32)-1:0]
                                      f32_alu_portal_rsp_src0_data_i,
  input  wire [(F32_ALU_PORTAL_LANES*32)-1:0]
                                      f32_alu_portal_rsp_src1_data_i,
  input  wire                         f32_alu_portal_rsp_error_i,
  output wire [63:0]                  f32_alu_portal_request_groups_o,
  output wire [63:0]                  f32_alu_portal_response_groups_o,
  output wire [63:0]                  f32_alu_portal_read_groups_o,
  output wire [63:0]                  f32_alu_portal_write_groups_o,
  output wire [63:0]                  f32_alu_portal_input_words_o,
  output wire [63:0]                  f32_alu_portal_output_words_o,
  output wire [63:0]                  f32_alu_portal_read_bytes_o,
  output wire [63:0]                  f32_alu_portal_write_bytes_o,
  output wire                         f32_alu_portal_outstanding_o,

  // Raw32 memory portal for GET_ROWS_F32 and REPEAT_F32.  Index decode,
  // gathering, broadcasting, and every destination address remain in RTL.
  output wire                         f32_mover_portal_req_valid_o,
  input  wire                         f32_mover_portal_req_ready_i,
  output wire                         f32_mover_portal_req_write_o,
  output wire [F32_MOVER_PORTAL_LANES-1:0]
                                      f32_mover_portal_req_mask_o,
  output wire [(F32_MOVER_PORTAL_LANES*64)-1:0]
                                      f32_mover_portal_req_addr_o,
  output wire [(F32_MOVER_PORTAL_LANES*32)-1:0]
                                      f32_mover_portal_req_wdata_o,
  input  wire                         f32_mover_portal_rsp_valid_i,
  output wire                         f32_mover_portal_rsp_ready_o,
  input  wire [F32_MOVER_PORTAL_LANES-1:0]
                                      f32_mover_portal_rsp_mask_i,
  input  wire [(F32_MOVER_PORTAL_LANES*32)-1:0]
                                      f32_mover_portal_rsp_rdata_i,
  input  wire                         f32_mover_portal_rsp_error_i,
  output wire [63:0]                  f32_mover_portal_request_groups_o,
  output wire [63:0]                  f32_mover_portal_response_groups_o,
  output wire [63:0]                  f32_mover_portal_read_groups_o,
  output wire [63:0]                  f32_mover_portal_write_groups_o,
  output wire [63:0]                  f32_mover_portal_read_words_o,
  output wire [63:0]                  f32_mover_portal_write_words_o,
  output wire [63:0]                  f32_mover_portal_read_bytes_o,
  output wire [63:0]                  f32_mover_portal_write_bytes_o,
  output wire                         f32_mover_portal_outstanding_o,

  input  wire                         sync_tag_ack_i,
  output wire [63:0]                  sync_tag_o,
  output wire                         sync_tag_valid_o,
  input  wire                         error_clear_i,
  output wire                         busy_o,
  output wire                         error_o,
  output wire [`NPU_ERROR_W-1:0]      error_code_o,

  output wire [63:0]                  command_count_o,
  output wire [63:0]                  completion_count_o,
  output wire [63:0]                  error_count_o,
  output wire [63:0]                  npu_required_issued_o,
  output wire [63:0]                  npu_required_completed_o,
  output wire [63:0]                  tiu_cycles_o,
  output wire [63:0]                  dma_cycles_o,
  output wire [63:0]                  dma_bytes_o,
  output wire [63:0]                  macro_command_count_o,
  output wire [63:0]                  macro_f32_start_count_o,
  output wire [63:0]                  macro_completion_count_o
);

  localparam [3:0] ST_IDLE       = 4'd0;
  localparam [3:0] ST_DECODE     = 4'd1;
  localparam [3:0] ST_TIU_RUN    = 4'd2;
  localparam [3:0] ST_DMA_RUN    = 4'd3;
  localparam [3:0] ST_COMPLETE   = 4'd4;
  localparam [3:0] ST_ERROR_HOLD = 4'd5;
  localparam [3:0] ST_MACRO_START = 4'd6;
  localparam [3:0] ST_MACRO_RUN   = 4'd7;

  // The public macro descriptor is shared by a finite, exact kernel table.
  // Kernel ID is therefore the only internal adapter select; an unsupported
  // ID never reaches any adapter or the public GMEM owner.
  localparam [31:0] KERNEL_GET_ROWS_Q8_0 = 32'h514e0001;
  localparam [31:0] KERNEL_GEMV_Q8_0_F32 = 32'h514e0002;
  localparam [31:0] KERNEL_GET_ROWS_F32   = 32'h514e0003;
  localparam [31:0] KERNEL_REPEAT_F32     = 32'h514e0004;
  localparam [31:0] KERNEL_UNARY_F32      = 32'h514e0005;
  localparam [31:0] KERNEL_GLU_F32        = 32'h514e0006;
  localparam [31:0] KERNEL_MOVER_F32      = 32'h514e0007;
  localparam [31:0] KERNEL_SET_ROWS_F32   = 32'h514e0008;
  localparam [31:0] KERNEL_F16_ATTN_MATMUL = 32'h514e0009;
  localparam [31:0] KERNEL_IMROPE_F32     = 32'h514e000a;
  localparam [31:0] KERNEL_VECTOR_F32     = 32'h514e0010;
  localparam [31:0] KERNEL_REDUCE_F32     = 32'h514e0011;
  localparam [31:0] KERNEL_SSM_CONV_F32   = 32'h514e0022;
  localparam [31:0] KERNEL_F32_ARGMAX     = 32'h514e0030;
  localparam [31:0] COMMAND_FLAGS_REQUIRED_PROFILE = 32'h00000011;
  localparam [31:0] CANONICAL_CONTEXT_ID = 32'h43414e01;
  localparam [31:0] ABI_DTYPE_F32 = 32'd1;
  localparam [31:0] NORM_EPSILON_QWEN = 32'h358637bd;
  localparam [15:0] MANIFEST_SUM_ROWS = 16'd15;
  localparam [15:0] MANIFEST_SSM_CONV = 16'd76;
  localparam [15:0] MANIFEST_MUL_MAT = 16'd29;
  localparam [15:0] MANIFEST_SOFT_MAX = 16'd46;
  localparam [15:0] MANIFEST_ROPE = 16'd48;
  localparam [7:0] MANIFEST_F32 = 8'd0;
  localparam [7:0] MANIFEST_F16 = 8'd1;
  localparam [7:0] MANIFEST_I32 = 8'd26;
  localparam [7:0] MANIFEST_I64 = 8'd27;
  localparam [31:0] MANIFEST_FLAGS = 32'd16;
  localparam [511:0] ROPE_FROZEN_OP_PARAMS = {
      32'h00000000, 32'h00000000, 32'h0000000a, 32'h0000000b,
      32'h0000000b, 32'h3f800000, 32'h42000000, 32'h3f800000,
      32'h00000000, 32'h3f800000, 32'h4b189680, 32'h00040000,
      32'h00000000, 32'h00000028, 32'h00000040, 32'h00000000
  };
  localparam integer Q8_MAX_D   = 1024;
  localparam integer Q8_MAX_IDS = 16;
  localparam integer Q8_ID_W = $clog2(Q8_MAX_IDS + 1);
  localparam integer Q8_D_W  = $clog2(Q8_MAX_D + 1);
  localparam integer GEMV_MAX_ROWS   = 248320;
  localparam integer GEMV_MAX_BLOCKS = 128;
  localparam integer F32_MOVE_MAX_ELEMENTS = 262144;
  localparam integer F32_MOVE_MAX_INDICES  = 16;
  localparam integer F32_MOVE_MAX_REPEAT   = 128;
  localparam integer F32_MOVE_MAX_OUTER    = 16;
  localparam integer F32_ARGMAX_MAX_ELEMENTS = 1048576;

  localparam [31:0] ABI_ERROR_ABI        = 32'd1;
  localparam [31:0] ABI_ERROR_CAPABILITY = 32'd3;
  localparam [31:0] ABI_ERROR_LAYOUT     = 32'd4;
  localparam [31:0] ABI_ERROR_IOVA       = 32'd5;
  localparam [31:0] ABI_ERROR_GMEM       = 32'd6;
  localparam [31:0] ABI_ERROR_TIMEOUT    = 32'd10;
  localparam [31:0] ABI_ERROR_PROTOCOL   = 32'd11;

  reg [3:0] state_q;
  reg cmd_is_64_q;
  reg [63:0] cmd_bits_q;
  reg [63:0] cmd_rs_value_q;
  reg [PID_W-1:0] cmd_producer_id_q;
  reg cmd_npu_required_q;
  reg [OPCLASS_W-1:0] cmd_opclass_q;

  // Top-level macro resident identity and parsed descriptor.  These registers
  // are written only on macro admission and remain stable through the held
  // completion handshake.
  reg macro_transaction_q;
  reg macro_abi_valid_q;
  reg [31:0] macro_kernel_id_q;
  reg [31:0] macro_command_flags_q;
  reg [31:0] macro_context_id_q;
  reg [31:0] macro_capability_epoch_q;
  reg [63:0] macro_sequence_id_q;
  reg [63:0] macro_producer_id_q;
  reg [63:0] macro_user_tag_q;
  reg [31:0] macro_node_count_q;
  reg [63:0] macro_node_hash_lo_q;
  reg [63:0] macro_node_hash_hi_q;
  reg [63:0] macro_deadline_cycles_q;
  reg [31:0] macro_vector_op_q;
  reg [31:0] macro_vector_flags_q;
  reg [63:0] macro_src0_iova_q;
  reg [63:0] macro_src1_iova_q;
  reg [63:0] macro_src2_iova_q;
  reg [63:0] macro_dst_iova_q;
  reg [63:0] macro_scratch_iova_q;
  reg [63:0] macro_element_count_q;
  reg [31:0] macro_outer_count_q;
  reg [31:0] macro_dtype_q;
  reg [63:0] macro_src0_stride_q;
  reg [63:0] macro_src1_stride_q;
  reg [63:0] macro_src2_stride_q;
  reg [63:0] macro_dst_stride_q;
  reg [31:0] macro_scalar0_q;
  reg [31:0] macro_scalar1_q;
  reg [31:0] macro_scratch_bytes_q;
  reg [31:0] macro_rope_position_q;
  reg [63:0] macro_src0_window_base_q;
  reg [63:0] macro_src0_window_size_q;
  reg [1:0] macro_src0_window_perm_q;
  reg [63:0] macro_src1_window_base_q;
  reg [63:0] macro_src1_window_size_q;
  reg [1:0] macro_src1_window_perm_q;
  reg [63:0] macro_dst_window_base_q;
  reg [63:0] macro_dst_window_size_q;
  reg [1:0] macro_dst_window_perm_q;
  reg macro_windows_generation_valid_q;

  reg [31:0] macro_completion_status_q;
  reg [31:0] macro_completion_error_class_q;
  reg [63:0] macro_cycles_q;
  reg [63:0] macro_completion_cycles_q;
  reg [63:0] macro_completion_read_bytes_q;
  reg [63:0] macro_completion_write_bytes_q;
  reg [63:0] macro_completion_q8_mac_count_q;
  reg [63:0] macro_completion_vector_elements_q;
  // A functional command is one clocked child transaction.  Capture the
  // child's cumulative ledgers on admission so terminal acceptance can prove
  // exactly one DPI dispatch and exactly one completion for this resident
  // command, independently of the numerical translation unit.
  reg [63:0] functional_dispatch_baseline_q;
  reg [63:0] functional_completion_baseline_q;

  reg terminal_error_q;
  reg [`NPU_ERROR_W-1:0] terminal_error_code_q;
  reg sticky_error_q;
  reg [`NPU_ERROR_W-1:0] sticky_error_code_q;

  reg [63:0] command_count_q;
  reg [63:0] completion_count_q;
  reg [63:0] error_count_q;
  reg [63:0] npu_required_issued_q;
  reg [63:0] npu_required_completed_q;
  reg [63:0] tiu_cycles_q;
  reg [63:0] dma_cycles_q;
  reg [63:0] dma_bytes_q;
  reg [63:0] macro_command_count_q;
  reg [63:0] macro_f32_start_count_q;
  reg [63:0] macro_completion_count_q;

  assign cmd_ready_o = (state_q == ST_IDLE) && !sticky_error_q;
  // Legacy has fixed priority when both producers assert valid.  Macro valid
  // remains held and receives ready after the legacy admission leaves IDLE.
  assign macro_cmd_ready_o = (state_q == ST_IDLE) && !sticky_error_q &&
                             !cmd_valid_i;
  assign completion_valid_o = (state_q == ST_COMPLETE);
  assign completion_producer_id_o = macro_transaction_q ?
                                    {PID_W{1'b0}} : cmd_producer_id_q;
  assign completion_npu_required_o = macro_transaction_q ?
                                     macro_command_flags_q[0] :
                                     cmd_npu_required_q;
  assign completion_opclass_o = macro_transaction_q ?
                                {OPCLASS_W{1'b0}} : cmd_opclass_q;
  assign completion_error_o = terminal_error_q;
  assign completion_error_code_o = terminal_error_code_q;
  wire macro_completion_active_w;
  assign macro_completion_active_w = completion_valid_o &&
                                     macro_transaction_q;
  assign completion_is_macro_o = macro_completion_active_w;
  assign completion_macro_status_o = macro_completion_active_w ?
                                     macro_completion_status_q : 32'd0;
  assign completion_macro_error_class_o = macro_completion_active_w ?
                                          macro_completion_error_class_q :
                                          32'd0;
  assign completion_macro_kernel_id_o = macro_completion_active_w ?
                                        macro_kernel_id_q : 32'd0;
  assign completion_macro_command_flags_o = macro_completion_active_w ?
                                            macro_command_flags_q : 32'd0;
  assign completion_macro_vector_flags_o = macro_completion_active_w ?
                                           macro_vector_flags_q : 32'd0;
  assign completion_macro_context_id_o = macro_completion_active_w ?
                                         macro_context_id_q : 32'd0;
  assign completion_macro_sequence_id_o = macro_completion_active_w ?
                                          macro_sequence_id_q : 64'd0;
  assign completion_macro_producer_id_o = macro_completion_active_w ?
                                          macro_producer_id_q : 64'd0;
  assign completion_macro_user_tag_o = macro_completion_active_w ?
                                       macro_user_tag_q : 64'd0;
  assign completion_macro_covered_node_count_o = macro_completion_active_w ?
                                                 macro_node_count_q : 32'd0;
  assign completion_macro_node_hash_lo_o = macro_completion_active_w ?
                                           macro_node_hash_lo_q : 64'd0;
  assign completion_macro_node_hash_hi_o = macro_completion_active_w ?
                                           macro_node_hash_hi_q : 64'd0;
  assign completion_macro_npu_cycles_o = macro_completion_active_w ?
                                         macro_completion_cycles_q : 64'd0;
  assign completion_macro_gmem_read_bytes_o = macro_completion_active_w ?
                                              macro_completion_read_bytes_q :
                                              64'd0;
  assign completion_macro_gmem_write_bytes_o = macro_completion_active_w ?
                                               macro_completion_write_bytes_q :
                                               64'd0;
  assign completion_macro_q8_mac_count_o = macro_completion_active_w ?
                                            macro_completion_q8_mac_count_q :
                                            64'd0;
  assign completion_macro_vector_element_count_o =
      macro_completion_active_w ? macro_completion_vector_elements_q : 64'd0;
  assign completion_macro_state_update_count_o = 64'd0;
  assign busy_o = (state_q != ST_IDLE) && (state_q != ST_ERROR_HOLD);
  assign error_o = sticky_error_q;
  assign error_code_o = sticky_error_code_q;
  assign command_count_o = command_count_q;
  assign completion_count_o = completion_count_q;
  assign error_count_o = error_count_q;
  assign npu_required_issued_o = npu_required_issued_q;
  assign npu_required_completed_o = npu_required_completed_q;
  assign tiu_cycles_o = tiu_cycles_q;
  assign dma_cycles_o = dma_cycles_q;
  assign dma_bytes_o = dma_bytes_q;
  assign macro_command_count_o = macro_command_count_q;
  assign macro_f32_start_count_o = macro_f32_start_count_q;
  assign macro_completion_count_o = macro_completion_count_q;

  // ------------------------------------------------------------------------
  // Command decode and descriptor register file.
  // ------------------------------------------------------------------------
  wire dec_legal_w;
  wire [`NPU_OP_W-1:0] dec_op_w;
  // The CPU-side pair owner has already read rs and supplies cmd_rs_value_i.
  // Keep the decoded architectural address observable for decoder assertions,
  // but it is intentionally not consumed by this value-only boundary.
  /* verilator lint_off UNUSEDSIGNAL */
  wire [4:0] dec_rs_addr_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire [4:0] dec_imm5_w;
  wire [5:0] dec_dst_id_w;
  wire [5:0] dec_src0_id_w;
  wire [5:0] dec_src1_id_w;
  wire [5:0] dec_src2_id_w;
  wire [4:0] dec_flags_w;
  wire [1:0] dec_sync_engine_w;

  TensorNpuCommandDecoder u_decoder (
    .cmd_is_64_i(cmd_is_64_q),
    .cmd_bits_i(cmd_bits_q),
    .legal_o(dec_legal_w),
    .op_o(dec_op_w),
    .rs_addr_o(dec_rs_addr_w),
    .imm5_o(dec_imm5_w),
    .dst_id_o(dec_dst_id_w),
    .src0_id_o(dec_src0_id_w),
    .src1_id_o(dec_src1_id_w),
    .src2_id_o(dec_src2_id_w),
    .flags_o(dec_flags_w),
    .sync_engine_o(dec_sync_engine_w)
  );

  wire cfg_op_w;
  assign cfg_op_w = (dec_op_w == `NPU_OP_CFG_SATU) ||
                    (dec_op_w == `NPU_OP_CFG_PAD) ||
                    (dec_op_w == `NPU_OP_CFG_INSRT) ||
                    (dec_op_w == `NPU_OP_CFG_STENCIL) ||
                    (dec_op_w == `NPU_OP_CFG_ROUND) ||
                    (dec_op_w == `NPU_OP_CFG_RSQRT_ITER) ||
                    (dec_op_w == `NPU_OP_CFG_DMAIDX) ||
                    (dec_op_w == `NPU_OP_CFG_QUANT) ||
                    (dec_op_w == `NPU_OP_CFG_KZP) ||
                    (dec_op_w == `NPU_OP_TCR_CR) ||
                    (dec_op_w == `NPU_OP_TCR_TR) ||
                    (dec_op_w == `NPU_OP_TCR_GR);

  wire mm2_op_w;
  assign mm2_op_w = (dec_op_w == `NPU_OP_MM2_NN) ||
                    (dec_op_w == `NPU_OP_MM2_NT) ||
                    (dec_op_w == `NPU_OP_MM2_TT);
  wire dma_op_w;
  assign dma_op_w = (dec_op_w == `NPU_OP_DMA_LD) ||
                    (dec_op_w == `NPU_OP_DMA_ST);

  wire rf_cfg_valid_w;
  assign rf_cfg_valid_w = (state_q == ST_DECODE) && dec_legal_w && cfg_op_w;
  wire rf_cfg_error_w;
  wire [`NPU_ERROR_W-1:0] rf_cfg_error_code_w;
  wire rf_desc_error_w;
  wire [`NPU_ERROR_W-1:0] rf_desc_error_code_w;

  assign desc_write_ready_o = (state_q == ST_IDLE) && !sticky_error_q &&
                              !cmd_valid_i && !macro_cmd_valid_i;
  wire rf_desc_write_valid_w;
  assign rf_desc_write_valid_w = desc_write_valid_i && desc_write_ready_o;
  assign desc_write_error_o = rf_desc_write_valid_w && rf_desc_error_w;
  assign desc_write_error_code_o = desc_write_error_o ?
                                    rf_desc_error_code_w : `NPU_ERR_NONE;

  wire rf_sync_tag_write_valid_w;
  assign rf_sync_tag_write_valid_w = (state_q == ST_DECODE) && dec_legal_w &&
                                     (dec_op_w == `NPU_OP_SYNC);

  wire [`NPU_DESC_W-1:0] rf_read0_desc_w;
  wire [`NPU_DESC_W-1:0] rf_read1_desc_w;
  wire [`NPU_DESC_W-1:0] rf_read2_desc_w;
  wire [`NPU_DESC_W-1:0] rf_read3_desc_w;
  wire [`NPU_DESC_W-1:0] rf_read4_desc_w;
  wire [4:0] rf_read0_valid_w;
  wire [4:0] rf_read1_valid_w;
  wire [4:0] rf_read2_valid_w;
  wire [4:0] rf_read3_valid_w;
  wire [4:0] rf_read4_valid_w;
  wire [4:0] csr_kzp_id_w;

  /* verilator lint_off UNUSEDSIGNAL */
  wire csr_saturate_w;
  wire csr_sym_saturate_w;
  wire [3:0] csr_round_mode_w;
  wire [3:0] csr_rsqrt_iter_w;
  wire [63:0] csr_padding_w;
  wire [63:0] csr_inserts_w;
  wire [63:0] csr_stencil_w;
  wire [63:0] csr_dma_idx_w;
  wire [4:0] csr_quant_id_w;
  /* verilator lint_on UNUSEDSIGNAL */

  TensorNpuRegisterFile u_register_file (
    .clk(clk),
    .rst(rst),
    .cfg_valid_i(rf_cfg_valid_w),
    .cfg_op_i(dec_op_w),
    .cfg_rs_value_i(cmd_rs_value_q),
    .cfg_imm5_i(dec_imm5_w),
    .cfg_error_o(rf_cfg_error_w),
    .cfg_error_code_o(rf_cfg_error_code_w),
    .desc_write_valid_i(rf_desc_write_valid_w),
    .desc_write_id_i(desc_write_id_i),
    .desc_write_word_i(desc_write_word_i),
    .desc_write_data_i(desc_write_data_i),
    .desc_write_error_o(rf_desc_error_w),
    .desc_write_error_code_o(rf_desc_error_code_w),
    .sync_tag_write_valid_i(rf_sync_tag_write_valid_w),
    .sync_tag_write_data_i(cmd_rs_value_q),
    .sync_tag_ack_i(sync_tag_ack_i),
    .sync_tag_o(sync_tag_o),
    .sync_tag_valid_o(sync_tag_valid_o),
    .read0_id_i(dec_dst_id_w),
    .read1_id_i(dec_src0_id_w),
    .read2_id_i(dec_src1_id_w),
    .read3_id_i(dec_src2_id_w),
    .read4_id_i({1'b0, csr_kzp_id_w}),
    .read0_desc_o(rf_read0_desc_w),
    .read1_desc_o(rf_read1_desc_w),
    .read2_desc_o(rf_read2_desc_w),
    .read3_desc_o(rf_read3_desc_w),
    .read4_desc_o(rf_read4_desc_w),
    .read0_words_valid_o(rf_read0_valid_w),
    .read1_words_valid_o(rf_read1_valid_w),
    .read2_words_valid_o(rf_read2_valid_w),
    .read3_words_valid_o(rf_read3_valid_w),
    .read4_words_valid_o(rf_read4_valid_w),
    .csr_saturate_o(csr_saturate_w),
    .csr_sym_saturate_o(csr_sym_saturate_w),
    .csr_round_mode_o(csr_round_mode_w),
    .csr_rsqrt_iter_o(csr_rsqrt_iter_w),
    .csr_padding_o(csr_padding_w),
    .csr_inserts_o(csr_inserts_w),
    .csr_stencil_o(csr_stencil_w),
    .csr_dma_idx_o(csr_dma_idx_w),
    .csr_quant_id_o(csr_quant_id_w),
    .csr_kzp_id_o(csr_kzp_id_w)
  );

  // ------------------------------------------------------------------------
  // MM2 and DMA engines.
  // ------------------------------------------------------------------------
  wire mm2_start_w;
  assign mm2_start_w = (state_q == ST_DECODE) && dec_legal_w && mm2_op_w;
  // Busy is assertion-only at this serialized top; state_q owns arbitration.
  /* verilator lint_off UNUSEDSIGNAL */
  wire mm2_busy_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire mm2_done_w;
  wire mm2_error_w;
  wire [`NPU_ERROR_W-1:0] mm2_error_code_w;
  wire [63:0] mm2_cycles_w;
  wire mm2_rd0_valid_w;
  wire [31:0] mm2_rd0_addr_w;
  wire [3:0] mm2_rd0_bytes_w;
  wire mm2_rd1_valid_w;
  wire [31:0] mm2_rd1_addr_w;
  wire [3:0] mm2_rd1_bytes_w;
  wire mm2_wr_valid_w;
  wire [31:0] mm2_wr_addr_w;
  wire [63:0] mm2_wr_data_w;
  wire [7:0] mm2_wr_strb_w;

  wire [63:0] lmem_rd0_data_w;
  wire lmem_rd0_oob_w;
  wire [63:0] lmem_rd1_data_w;
  wire lmem_rd1_oob_w;
  wire lmem_wr_oob_w;

  TensorNpuMm2Engine #(.LMEM_BYTES(LMEM_BYTES)) u_mm2 (
    .clk(clk),
    .rst(rst),
    .start_i(mm2_start_w),
    .op_i(dec_op_w),
    .flags_i(dec_flags_w),
    .dst_id_i(dec_dst_id_w),
    .dst_desc_i(rf_read0_desc_w),
    .dst_words_valid_i(rf_read0_valid_w),
    .x_id_i(dec_src0_id_w),
    .x_desc_i(rf_read1_desc_w),
    .x_words_valid_i(rf_read1_valid_w),
    .w_id_i(dec_src1_id_w),
    .w_desc_i(rf_read2_desc_w),
    .w_words_valid_i(rf_read2_valid_w),
    .bias_id_i(dec_src2_id_w),
    .bias_desc_i(rf_read3_desc_w),
    .bias_words_valid_i(rf_read3_valid_w),
    .kzp_id_i({1'b0, csr_kzp_id_w}),
    .kzp_desc_i(rf_read4_desc_w),
    .kzp_words_valid_i(rf_read4_valid_w),
    .busy_o(mm2_busy_w),
    .done_o(mm2_done_w),
    .error_o(mm2_error_w),
    .error_code_o(mm2_error_code_w),
    .cycles_o(mm2_cycles_w),
    .rd0_valid_o(mm2_rd0_valid_w),
    .rd0_addr_o(mm2_rd0_addr_w),
    .rd0_bytes_o(mm2_rd0_bytes_w),
    .rd0_data_i(lmem_rd0_data_w),
    .rd0_oob_i(lmem_rd0_oob_w),
    .rd1_valid_o(mm2_rd1_valid_w),
    .rd1_addr_o(mm2_rd1_addr_w),
    .rd1_bytes_o(mm2_rd1_bytes_w),
    .rd1_data_i(lmem_rd1_data_w),
    .rd1_oob_i(lmem_rd1_oob_w),
    .wr_valid_o(mm2_wr_valid_w),
    .wr_addr_o(mm2_wr_addr_w),
    .wr_data_o(mm2_wr_data_w),
    .wr_strb_o(mm2_wr_strb_w),
    .wr_oob_i(lmem_wr_oob_w)
  );

  wire dma_start_w;
  assign dma_start_w = (state_q == ST_DECODE) && dec_legal_w && dma_op_w;
  // Busy is assertion-only at this serialized top; state_q owns arbitration.
  /* verilator lint_off UNUSEDSIGNAL */
  wire dma_busy_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire dma_done_w;
  wire dma_error_w;
  wire [`NPU_ERROR_W-1:0] dma_error_code_w;
  wire [63:0] dma_engine_cycles_w;
  wire [63:0] dma_engine_bytes_w;
  wire dma_rd_valid_w;
  wire [31:0] dma_rd_addr_w;
  wire [3:0] dma_rd_bytes_w;
  wire dma_wr_valid_w;
  wire [31:0] dma_wr_addr_w;
  wire [63:0] dma_wr_data_w;
  wire [7:0] dma_wr_strb_w;
  wire dma_gmem_req_valid_w;
  wire dma_gmem_req_ready_w;
  wire dma_gmem_req_write_w;
  wire [63:0] dma_gmem_req_addr_w;
  wire [63:0] dma_gmem_req_wdata_w;
  wire [7:0] dma_gmem_req_wstrb_w;
  wire dma_gmem_rsp_valid_w;
  wire dma_gmem_rsp_ready_w;
  wire [63:0] dma_gmem_rsp_rdata_w;
  wire dma_gmem_rsp_error_w;

  TensorNpuDmaEngine #(.LMEM_BYTES(LMEM_BYTES)) u_dma (
    .clk_i(clk),
    .rst_i(rst),
    .start_i(dma_start_w),
    .op_i(dec_op_w),
    .dst_id_i(dec_dst_id_w),
    .dst_desc_i(rf_read0_desc_w),
    .dst_words_valid_i(rf_read0_valid_w),
    .src_id_i(dec_src0_id_w),
    .src_desc_i(rf_read1_desc_w),
    .src_words_valid_i(rf_read1_valid_w),
    .busy_o(dma_busy_w),
    .done_o(dma_done_w),
    .error_o(dma_error_w),
    .error_code_o(dma_error_code_w),
    .cycles_o(dma_engine_cycles_w),
    .bytes_done_o(dma_engine_bytes_w),
    .lmem_rd_valid_o(dma_rd_valid_w),
    .lmem_rd_addr_o(dma_rd_addr_w),
    .lmem_rd_bytes_o(dma_rd_bytes_w),
    .lmem_rd_data_i(lmem_rd0_data_w),
    .lmem_rd_oob_i(lmem_rd0_oob_w),
    .lmem_wr_valid_o(dma_wr_valid_w),
    .lmem_wr_addr_o(dma_wr_addr_w),
    .lmem_wr_data_o(dma_wr_data_w),
    .lmem_wr_strb_o(dma_wr_strb_w),
    .lmem_wr_oob_i(lmem_wr_oob_w),
    .gmem_req_valid_o(dma_gmem_req_valid_w),
    .gmem_req_ready_i(dma_gmem_req_ready_w),
    .gmem_req_write_o(dma_gmem_req_write_w),
    .gmem_req_addr_o(dma_gmem_req_addr_w),
    .gmem_req_wdata_o(dma_gmem_req_wdata_w),
    .gmem_req_wstrb_o(dma_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(dma_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(dma_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(dma_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(dma_gmem_rsp_error_w)
  );

  // ------------------------------------------------------------------------
  // Exact macro adapters and the single public GMEM owner mux.
  //
  // GET_ROWS_Q8_0 reuses the existing parsed descriptor surface as follows:
  //   src0/src1/dst       = Q8 table / I32 index array / private F32 output
  //   element/outer      = D elements per row / N gathered rows
  //   scalar0            = V source rows
  //   src0/src1/dst stride = Q8 row / index / F32 row byte stride
  // Every other vector/scratch/tail field is fixed to zero and dtype is F32.
  // The registered windows remain independent R/R/W capabilities; widened
  // preflight below proves each complete aligned transaction footprint before
  // the lower-level gather/writeback adapter can start.
  //
  // GEMV_Q8_0_F32 freezes a second, disjoint macro mapping:
  //   src0/src1/dst       = F32 activation / Q8_0 weights / private F32 output
  //   element/outer      = K reduction elements / M output rows
  //   src1/dst stride    = Q8 weight row / F32 output row byte stride
  // K must be a multiple of 32 and B=K/32.  src0 is one contiguous F32
  // activation vector, so src0_stride is unused and must be zero.  Every other
  // vector/src2/scratch/scalar/tail field is also strictly zero; dtype is F32.
  //
  // GET_ROWS_F32 and REPEAT_F32 are two logical kernel identities implemented
  // by one frozen raw-bit mover adapter.  GET_ROWS maps outer=N and scalar0=V;
  // REPEAT maps outer=O, scalar0=R, dst_stride=repeat stride and
  // src2_stride=destination outer stride.  REPEAT's src1 capability is an
  // aligned zero-byte read-only sentinel.  The distinct selectors below are
  // retained through terminal identity even though the physical GMEM requester
  // is shared by the adapter's operation input.
  //
  // Kernel ID is the sole adapter select.  Request ready and every response
  // field are gated to zero for the non-owner, so a response can never be
  // credited to DMA or any macro kernel concurrently.
  // ------------------------------------------------------------------------
  wire macro_select_vector_w;
  wire macro_select_q8_w;
  wire macro_select_gemv_w;
  wire macro_select_f32_get_w;
  wire macro_select_f32_repeat_w;
  wire macro_select_f32_move_w;
  wire macro_select_unary_w;
  wire macro_select_glu_w;
  wire macro_select_unary_glu_w;
  wire macro_select_reduce_kernel_w;
  wire macro_select_norm_w;
  wire macro_select_sum_w;
  wire macro_select_ssm_w;
  wire macro_select_mover_w;
  wire macro_select_set_rows_w;
  wire macro_select_mover_set_w;
  wire macro_select_attention_w;
  wire macro_select_rope_w;
  wire macro_select_softmax_w;
  wire macro_select_argmax_w;
  wire macro_select_batch2_kernel_w;
  wire macro_select_batch2_profile_w;
  wire macro_select_exact_kernel_w;
  wire macro_select_exact_profile_w;
  assign macro_select_vector_w = (macro_kernel_id_q == KERNEL_VECTOR_F32);
  assign macro_select_q8_w = (macro_kernel_id_q == KERNEL_GET_ROWS_Q8_0);
  assign macro_select_gemv_w = (macro_kernel_id_q == KERNEL_GEMV_Q8_0_F32);
  wire gemv_empty_w;
  assign gemv_empty_w = macro_select_gemv_w &&
                        (macro_outer_count_q == 32'd0);
  assign macro_select_f32_get_w =
      (macro_kernel_id_q == KERNEL_GET_ROWS_F32);
  assign macro_select_f32_repeat_w =
      (macro_kernel_id_q == KERNEL_REPEAT_F32);
  assign macro_select_f32_move_w = macro_select_f32_get_w ||
                                   macro_select_f32_repeat_w;
  assign macro_select_unary_w = (macro_kernel_id_q == KERNEL_UNARY_F32);
  assign macro_select_glu_w = (macro_kernel_id_q == KERNEL_GLU_F32);
  assign macro_select_unary_glu_w = macro_select_unary_w ||
                                    macro_select_glu_w;
  assign macro_select_reduce_kernel_w =
      (macro_kernel_id_q == KERNEL_REDUCE_F32);
  assign macro_select_norm_w = macro_select_reduce_kernel_w &&
                               ((macro_vector_op_q == 32'd4) ||
                                (macro_vector_op_q == 32'd5));
  assign macro_select_sum_w = macro_select_reduce_kernel_w &&
                              (macro_vector_op_q == 32'd1);
  assign macro_select_ssm_w =
      (macro_kernel_id_q == KERNEL_SSM_CONV_F32);
  assign macro_select_mover_w =
      (macro_kernel_id_q == KERNEL_MOVER_F32);
  assign macro_select_set_rows_w =
      (macro_kernel_id_q == KERNEL_SET_ROWS_F32);
  assign macro_select_mover_set_w = macro_select_mover_w ||
                                    macro_select_set_rows_w;
  assign macro_select_attention_w =
      (macro_kernel_id_q == KERNEL_F16_ATTN_MATMUL);
  assign macro_select_rope_w =
      (macro_kernel_id_q == KERNEL_IMROPE_F32);
  assign macro_select_softmax_w = macro_select_reduce_kernel_w &&
                                  (macro_vector_op_q == 32'd6);
  assign macro_select_argmax_w =
      (macro_kernel_id_q == KERNEL_F32_ARGMAX);
  assign macro_select_batch2_kernel_w = macro_select_mover_set_w ||
                                        macro_select_attention_w ||
                                        macro_select_rope_w ||
                                        macro_select_softmax_w;
  assign macro_select_batch2_profile_w = macro_select_batch2_kernel_w;
  assign macro_select_exact_kernel_w = macro_select_unary_glu_w ||
                                       macro_select_reduce_kernel_w ||
                                       macro_select_ssm_w ||
                                       macro_select_mover_set_w ||
                                       macro_select_attention_w ||
                                       macro_select_rope_w;
  assign macro_select_exact_profile_w = macro_select_unary_glu_w ||
                                        macro_select_norm_w ||
                                        macro_select_sum_w ||
                                        macro_select_ssm_w;

  wire [127:0] q8_n_minus_one_ext_w;
  wire [127:0] q8_v_minus_one_ext_w;
  wire [127:0] q8_block_count_ext_w;
  wire [127:0] q8_packed_row_bytes_ext_w;
  wire [127:0] q8_output_row_bytes_ext_w;
  wire [127:0] q8_total_outputs_ext_w;
  wire [127:0] q8_source_end_ext_w;
  wire [127:0] q8_index_end_ext_w;
  wire [127:0] q8_dst_end_ext_w;
  wire [127:0] q8_src0_window_end_ext_w;
  wire [127:0] q8_src1_window_end_ext_w;
  wire [127:0] q8_dst_window_end_ext_w;
  wire [127:0] q8_source_beat_start_ext_w;
  wire [127:0] q8_index_beat_start_ext_w;
  wire [127:0] q8_dst_beat_start_ext_w;
  wire [127:0] q8_source_beat_end_ext_w;
  wire [127:0] q8_index_beat_end_ext_w;
  wire [127:0] q8_dst_beat_end_ext_w;
  wire [127:0] q8_expected_blocks_ext_w;
  wire [127:0] q8_expected_payload_bytes_ext_w;
  wire [127:0] q8_expected_write_bytes_ext_w;

  assign q8_n_minus_one_ext_w = {96'd0, macro_outer_count_q} - 128'd1;
  assign q8_v_minus_one_ext_w = {96'd0, macro_scalar0_q} - 128'd1;
  assign q8_block_count_ext_w = {64'd0, macro_element_count_q} >> 5;
  assign q8_packed_row_bytes_ext_w = q8_block_count_ext_w * 128'd34;
  assign q8_output_row_bytes_ext_w =
      {64'd0, macro_element_count_q} * 128'd4;
  assign q8_total_outputs_ext_w = {64'd0, macro_element_count_q}
                                * {96'd0, macro_outer_count_q};
  assign q8_source_end_ext_w = {64'd0, macro_src0_iova_q}
                             + (q8_v_minus_one_ext_w
                                * {64'd0, macro_src0_stride_q})
                             + q8_packed_row_bytes_ext_w;
  assign q8_index_end_ext_w = {64'd0, macro_src1_iova_q}
                            + (q8_n_minus_one_ext_w
                               * {64'd0, macro_src1_stride_q})
                            + 128'd4;
  assign q8_dst_end_ext_w = {64'd0, macro_dst_iova_q}
                          + (q8_n_minus_one_ext_w
                             * {64'd0, macro_dst_stride_q})
                          + q8_output_row_bytes_ext_w;
  assign q8_src0_window_end_ext_w = {64'd0, macro_src0_window_base_q}
                                  + {64'd0, macro_src0_window_size_q};
  assign q8_src1_window_end_ext_w = {64'd0, macro_src1_window_base_q}
                                  + {64'd0, macro_src1_window_size_q};
  assign q8_dst_window_end_ext_w = {64'd0, macro_dst_window_base_q}
                                 + {64'd0, macro_dst_window_size_q};
  assign q8_source_beat_start_ext_w =
      {64'd0, (macro_src0_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign q8_index_beat_start_ext_w =
      {64'd0, (macro_src1_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign q8_dst_beat_start_ext_w =
      {64'd0, (macro_dst_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign q8_source_beat_end_ext_w =
      ((q8_source_end_ext_w + 128'd7) >> 3) << 3;
  assign q8_index_beat_end_ext_w =
      ((q8_index_end_ext_w + 128'd7) >> 3) << 3;
  assign q8_dst_beat_end_ext_w =
      ((q8_dst_end_ext_w + 128'd7) >> 3) << 3;
  assign q8_expected_blocks_ext_w = q8_block_count_ext_w
                                  * {96'd0, macro_outer_count_q};
  assign q8_expected_payload_bytes_ext_w =
      ({96'd0, macro_outer_count_q} * 128'd4)
      + (q8_expected_blocks_ext_w * 128'd34);
  assign q8_expected_write_bytes_ext_w = q8_total_outputs_ext_w * 128'd4;

  wire q8_abi_reject_w;
  wire q8_capability_reject_w;
  wire q8_layout_reject_w;
  wire q8_iova_reject_w;
  wire q8_source_dst_disjoint_w;
  wire q8_index_dst_disjoint_w;
  assign q8_abi_reject_w = !macro_abi_valid_q;
  assign q8_capability_reject_w =
      (macro_command_flags_q != COMMAND_FLAGS_REQUIRED_PROFILE) ||
      (macro_capability_epoch_q != MACRO_CAPABILITY_EPOCH) ||
      (macro_node_count_q != 32'd1) ||
      (macro_deadline_cycles_q != 64'd0);
  assign q8_layout_reject_w =
      (macro_vector_op_q != 32'd0) ||
      (macro_vector_flags_q != 32'd0) ||
      (macro_src2_iova_q != 64'd0) ||
      (macro_scratch_iova_q != 64'd0) ||
      (macro_element_count_q < 64'd32) ||
      (macro_element_count_q > 64'd1024) ||
      (macro_element_count_q[4:0] != 5'd0) ||
      (macro_outer_count_q < 32'd1) ||
      (macro_outer_count_q > 32'd16) ||
      (macro_dtype_q != ABI_DTYPE_F32) ||
      (macro_scalar0_q == 32'd0) ||
      (macro_scalar1_q != 32'd0) ||
      (macro_src0_stride_q[63] != 1'b0) ||
      (macro_src0_stride_q[0] != 1'b0) ||
      ({64'd0, macro_src0_stride_q} < q8_packed_row_bytes_ext_w) ||
      (macro_src1_stride_q[63] != 1'b0) ||
      (macro_src1_stride_q < 64'd4) ||
      (macro_src2_stride_q != 64'd0) ||
      (macro_dst_stride_q[63] != 1'b0) ||
      (macro_dst_stride_q[1:0] != 2'b00) ||
      ({64'd0, macro_dst_stride_q} < q8_output_row_bytes_ext_w) ||
      (macro_scratch_bytes_q != 32'd0) ||
      (macro_rope_position_q != 32'd0) ||
      (q8_total_outputs_ext_w > 128'd16384);
  assign q8_source_dst_disjoint_w =
      (q8_source_beat_end_ext_w <= q8_dst_beat_start_ext_w) ||
      (q8_dst_beat_end_ext_w <= q8_source_beat_start_ext_w);
  assign q8_index_dst_disjoint_w =
      (q8_index_beat_end_ext_w <= q8_dst_beat_start_ext_w) ||
      (q8_dst_beat_end_ext_w <= q8_index_beat_start_ext_w);
  assign q8_iova_reject_w =
      !macro_windows_generation_valid_q ||
      (macro_src0_window_perm_q != 2'b01) ||
      (macro_src1_window_perm_q != 2'b01) ||
      (macro_dst_window_perm_q != 2'b10) ||
      (macro_src0_iova_q[0] != 1'b0) ||
      (macro_dst_iova_q[1:0] != 2'b00) ||
      (macro_src0_window_size_q == 64'd0) ||
      (macro_src1_window_size_q == 64'd0) ||
      (macro_dst_window_size_q == 64'd0) ||
      (q8_source_end_ext_w[127:64] != 64'd0) ||
      (q8_index_end_ext_w[127:64] != 64'd0) ||
      (q8_dst_end_ext_w[127:64] != 64'd0) ||
      (q8_src0_window_end_ext_w[127:64] != 64'd0) ||
      (q8_src1_window_end_ext_w[127:64] != 64'd0) ||
      (q8_dst_window_end_ext_w[127:64] != 64'd0) ||
      (q8_source_beat_start_ext_w < {64'd0, macro_src0_window_base_q}) ||
      (q8_source_beat_end_ext_w > q8_src0_window_end_ext_w) ||
      (q8_index_beat_start_ext_w < {64'd0, macro_src1_window_base_q}) ||
      (q8_index_beat_end_ext_w > q8_src1_window_end_ext_w) ||
      (q8_dst_beat_start_ext_w < {64'd0, macro_dst_window_base_q}) ||
      (q8_dst_beat_end_ext_w > q8_dst_window_end_ext_w) ||
      !q8_source_dst_disjoint_w || !q8_index_dst_disjoint_w;

  wire q8_static_descriptor_valid_w;
  assign q8_static_descriptor_valid_w = !q8_abi_reject_w &&
                                        !q8_capability_reject_w &&
                                        !q8_layout_reject_w &&
                                        !q8_iova_reject_w;

  // GEMV top-level capability/window proof.  The lower adapter repeats these
  // checks, but it must never be started for an invalid public descriptor.
  wire [127:0] gemv_m_minus_one_ext_w;
  wire [127:0] gemv_k_ext_w;
  wire [127:0] gemv_block_count_ext_w;
  wire [127:0] gemv_activation_bytes_ext_w;
  wire [127:0] gemv_weight_row_bytes_ext_w;
  wire [127:0] gemv_weight_blocks_ext_w;
  wire [127:0] gemv_weight_payload_bytes_ext_w;
  wire [127:0] gemv_output_bytes_ext_w;
  wire [127:0] gemv_q8_mac_count_ext_w;
  wire [127:0] gemv_activation_end_ext_w;
  wire [127:0] gemv_weight_end_ext_w;
  wire [127:0] gemv_dst_end_ext_w;
  wire [127:0] gemv_src0_window_end_ext_w;
  wire [127:0] gemv_src1_window_end_ext_w;
  wire [127:0] gemv_dst_window_end_ext_w;
  wire [127:0] gemv_activation_beat_start_ext_w;
  wire [127:0] gemv_weight_beat_start_ext_w;
  wire [127:0] gemv_dst_beat_start_ext_w;
  wire [127:0] gemv_activation_beat_end_ext_w;
  wire [127:0] gemv_weight_beat_end_ext_w;
  wire [127:0] gemv_dst_beat_end_ext_w;

  assign gemv_m_minus_one_ext_w =
      gemv_empty_w ? 128'd0 :
      ({96'd0, macro_outer_count_q} - 128'd1);
  assign gemv_k_ext_w = {64'd0, macro_element_count_q};
  assign gemv_block_count_ext_w = gemv_k_ext_w >> 5;
  assign gemv_activation_bytes_ext_w =
      gemv_empty_w ? 128'd0 : (gemv_k_ext_w * 128'd4);
  assign gemv_weight_row_bytes_ext_w =
      gemv_block_count_ext_w * 128'd34;
  assign gemv_weight_blocks_ext_w =
      {96'd0, macro_outer_count_q} * gemv_block_count_ext_w;
  assign gemv_weight_payload_bytes_ext_w =
      gemv_weight_blocks_ext_w * 128'd34;
  assign gemv_output_bytes_ext_w =
      {96'd0, macro_outer_count_q} * 128'd4;
  assign gemv_q8_mac_count_ext_w =
      {96'd0, macro_outer_count_q} * gemv_k_ext_w;

  assign gemv_activation_end_ext_w = {64'd0, macro_src0_iova_q}
                                      + gemv_activation_bytes_ext_w;
  assign gemv_weight_end_ext_w = gemv_empty_w ?
      {64'd0, macro_src1_iova_q} :
      ({64'd0, macro_src1_iova_q}
       + (gemv_m_minus_one_ext_w * {64'd0, macro_src1_stride_q})
       + gemv_weight_row_bytes_ext_w);
  assign gemv_dst_end_ext_w = gemv_empty_w ?
      {64'd0, macro_dst_iova_q} :
      ({64'd0, macro_dst_iova_q}
       + (gemv_m_minus_one_ext_w * {64'd0, macro_dst_stride_q})
       + 128'd4);
  assign gemv_src0_window_end_ext_w =
      {64'd0, macro_src0_window_base_q}
      + {64'd0, macro_src0_window_size_q};
  assign gemv_src1_window_end_ext_w =
      {64'd0, macro_src1_window_base_q}
      + {64'd0, macro_src1_window_size_q};
  assign gemv_dst_window_end_ext_w =
      {64'd0, macro_dst_window_base_q}
      + {64'd0, macro_dst_window_size_q};

  assign gemv_activation_beat_start_ext_w =
      {64'd0, (macro_src0_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign gemv_weight_beat_start_ext_w =
      {64'd0, (macro_src1_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign gemv_dst_beat_start_ext_w =
      {64'd0, (macro_dst_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign gemv_activation_beat_end_ext_w = gemv_empty_w ?
      gemv_activation_beat_start_ext_w :
      (((gemv_activation_end_ext_w + 128'd7) >> 3) << 3);
  assign gemv_weight_beat_end_ext_w = gemv_empty_w ?
      gemv_weight_beat_start_ext_w :
      (((gemv_weight_end_ext_w + 128'd7) >> 3) << 3);
  assign gemv_dst_beat_end_ext_w = gemv_empty_w ?
      gemv_dst_beat_start_ext_w :
      (((gemv_dst_end_ext_w + 128'd7) >> 3) << 3);

  wire gemv_abi_reject_w;
  wire gemv_capability_reject_w;
  wire gemv_layout_reject_w;
  wire gemv_iova_reject_w;
  wire gemv_activation_dst_disjoint_w;
  wire gemv_weight_dst_disjoint_w;
  assign gemv_abi_reject_w = !macro_abi_valid_q;
  assign gemv_capability_reject_w =
      (macro_command_flags_q != COMMAND_FLAGS_REQUIRED_PROFILE) ||
      (macro_capability_epoch_q != MACRO_CAPABILITY_EPOCH) ||
      (macro_node_count_q != 32'd1) ||
      (macro_deadline_cycles_q != 64'd0);
  assign gemv_layout_reject_w =
      (macro_vector_op_q != 32'd0) ||
      (macro_vector_flags_q != 32'd0) ||
      (macro_src2_iova_q != 64'd0) ||
      (macro_scratch_iova_q != 64'd0) ||
      (macro_element_count_q < 64'd32) ||
      (macro_element_count_q > 64'd4096) ||
      (macro_element_count_q[4:0] != 5'd0) ||
      (gemv_block_count_ext_w > 128'(GEMV_MAX_BLOCKS)) ||
      (macro_outer_count_q > 32'(GEMV_MAX_ROWS)) ||
      (macro_dtype_q != ABI_DTYPE_F32) ||
      (macro_src0_stride_q != 64'd0) ||
      (macro_src1_stride_q[63] != 1'b0) ||
      (macro_src1_stride_q[0] != 1'b0) ||
      ({64'd0, macro_src1_stride_q} < gemv_weight_row_bytes_ext_w) ||
      (macro_src2_stride_q != 64'd0) ||
      (macro_dst_stride_q[63] != 1'b0) ||
      (macro_dst_stride_q[1:0] != 2'b00) ||
      (macro_dst_stride_q < 64'd4) ||
      (macro_scalar0_q != 32'd0) ||
      (macro_scalar1_q != 32'd0) ||
      (macro_scratch_bytes_q != 32'd0) ||
      (macro_rope_position_q != 32'd0) ||
      (gemv_weight_blocks_ext_w[127:64] != 64'd0) ||
      (gemv_weight_payload_bytes_ext_w[127:64] != 64'd0) ||
      (gemv_q8_mac_count_ext_w[127:64] != 64'd0);
  assign gemv_activation_dst_disjoint_w =
      (gemv_activation_beat_end_ext_w <= gemv_dst_beat_start_ext_w) ||
      (gemv_dst_beat_end_ext_w <= gemv_activation_beat_start_ext_w);
  assign gemv_weight_dst_disjoint_w =
      (gemv_weight_beat_end_ext_w <= gemv_dst_beat_start_ext_w) ||
      (gemv_dst_beat_end_ext_w <= gemv_weight_beat_start_ext_w);
  assign gemv_iova_reject_w =
      !macro_windows_generation_valid_q ||
      (macro_src0_window_perm_q != 2'b01) ||
      (macro_src1_window_perm_q != 2'b01) ||
      (macro_dst_window_perm_q != 2'b10) ||
      (macro_src0_iova_q[1:0] != 2'b00) ||
      (macro_src1_iova_q[0] != 1'b0) ||
      (macro_dst_iova_q[1:0] != 2'b00) ||
      (macro_src0_window_base_q[2:0] != 3'b000) ||
      (macro_src1_window_base_q[2:0] != 3'b000) ||
      (macro_dst_window_base_q[2:0] != 3'b000) ||
      (macro_src0_window_size_q[2:0] != 3'b000) ||
      (macro_src1_window_size_q[2:0] != 3'b000) ||
      (macro_dst_window_size_q[2:0] != 3'b000) ||
      (gemv_activation_end_ext_w[127:64] != 64'd0) ||
      (gemv_weight_end_ext_w[127:64] != 64'd0) ||
      (gemv_dst_end_ext_w[127:64] != 64'd0) ||
      (gemv_src0_window_end_ext_w[127:64] != 64'd0) ||
      (gemv_src1_window_end_ext_w[127:64] != 64'd0) ||
      (gemv_dst_window_end_ext_w[127:64] != 64'd0) ||
      (gemv_empty_w ?
       ((macro_src0_window_size_q != 64'd0) ||
        (macro_src1_window_size_q != 64'd0) ||
        (macro_dst_window_size_q != 64'd0) ||
        (macro_src0_iova_q != macro_src0_window_base_q) ||
        (macro_src1_iova_q != macro_src1_window_base_q) ||
        (macro_dst_iova_q != macro_dst_window_base_q)) :
       ((macro_src0_window_size_q == 64'd0) ||
        (macro_src1_window_size_q == 64'd0) ||
        (macro_dst_window_size_q == 64'd0) ||
        (gemv_activation_beat_start_ext_w
         < {64'd0, macro_src0_window_base_q}) ||
        (gemv_activation_beat_end_ext_w > gemv_src0_window_end_ext_w) ||
        (gemv_weight_beat_start_ext_w
         < {64'd0, macro_src1_window_base_q}) ||
        (gemv_weight_beat_end_ext_w > gemv_src1_window_end_ext_w) ||
        (gemv_dst_beat_start_ext_w
         < {64'd0, macro_dst_window_base_q}) ||
        (gemv_dst_beat_end_ext_w > gemv_dst_window_end_ext_w) ||
        !gemv_activation_dst_disjoint_w || !gemv_weight_dst_disjoint_w));

  wire gemv_static_descriptor_valid_w;
  assign gemv_static_descriptor_valid_w = !gemv_abi_reject_w &&
                                          !gemv_capability_reject_w &&
                                          !gemv_layout_reject_w &&
                                          !gemv_iova_reject_w;

  // F32 GET_ROWS/REPEAT top-level proof.  These kernels transport raw FP32
  // words only, but their sparse table, repeat-plane and capability endpoints
  // still require the same full-width admission discipline as numeric kernels.
  wire f32_move_empty_get_w;
  wire [127:0] f32_move_d_ext_w;
  wire [127:0] f32_move_n_ext_w;
  wire [127:0] f32_move_v_ext_w;
  wire [127:0] f32_move_r_ext_w;
  wire [127:0] f32_move_o_ext_w;
  wire [127:0] f32_move_row_bytes_ext_w;
  wire [127:0] f32_move_total_outputs_ext_w;
  wire [127:0] f32_move_source_words_ext_w;
  wire [127:0] f32_move_read_words_ext_w;
  wire [127:0] f32_move_repeat_plane_ext_w;
  wire [127:0] f32_move_read_bytes_ext_w;
  wire [127:0] f32_move_write_bytes_ext_w;
  wire [127:0] f32_move_src_end_ext_w;
  wire [127:0] f32_move_index_end_ext_w;
  wire [127:0] f32_move_dst_end_ext_w;
  wire [127:0] f32_move_src_window_end_ext_w;
  wire [127:0] f32_move_index_window_end_ext_w;
  wire [127:0] f32_move_dst_window_end_ext_w;
  wire [127:0] f32_move_src_phys_start_ext_w;
  wire [127:0] f32_move_index_phys_start_ext_w;
  wire [127:0] f32_move_dst_phys_start_ext_w;
  wire [127:0] f32_move_src_phys_end_ext_w;
  wire [127:0] f32_move_index_phys_end_ext_w;
  wire [127:0] f32_move_dst_phys_end_ext_w;

  assign f32_move_empty_get_w = macro_select_f32_get_w &&
                                (macro_outer_count_q == 32'd0);
  assign f32_move_d_ext_w = {64'd0, macro_element_count_q};
  assign f32_move_n_ext_w = {96'd0, macro_outer_count_q};
  assign f32_move_v_ext_w = {96'd0, macro_scalar0_q};
  assign f32_move_r_ext_w = {96'd0, macro_scalar0_q};
  assign f32_move_o_ext_w = {96'd0, macro_outer_count_q};
  assign f32_move_row_bytes_ext_w = f32_move_d_ext_w * 128'd4;
  assign f32_move_total_outputs_ext_w = macro_select_f32_get_w ?
      (f32_move_d_ext_w * f32_move_n_ext_w) :
      (f32_move_d_ext_w * f32_move_o_ext_w * f32_move_r_ext_w);
  assign f32_move_source_words_ext_w = macro_select_f32_get_w ?
      (f32_move_d_ext_w * f32_move_n_ext_w) :
      (f32_move_d_ext_w * f32_move_o_ext_w);
  assign f32_move_read_words_ext_w = macro_select_f32_get_w ?
      (f32_move_n_ext_w + f32_move_source_words_ext_w) :
      f32_move_source_words_ext_w;
  assign f32_move_repeat_plane_ext_w =
      ((f32_move_r_ext_w - 128'd1) *
       {64'd0, macro_dst_stride_q}) + f32_move_row_bytes_ext_w;
  assign f32_move_read_bytes_ext_w = f32_move_read_words_ext_w * 128'd4;
  assign f32_move_write_bytes_ext_w =
      f32_move_total_outputs_ext_w * 128'd4;

  assign f32_move_src_end_ext_w = f32_move_empty_get_w ?
      {64'd0, macro_src0_iova_q} : (macro_select_f32_get_w ?
      ({64'd0, macro_src0_iova_q} +
       ((f32_move_v_ext_w - 128'd1) *
        {64'd0, macro_src0_stride_q}) + f32_move_row_bytes_ext_w) :
      ({64'd0, macro_src0_iova_q} +
       ((f32_move_o_ext_w - 128'd1) *
        {64'd0, macro_src0_stride_q}) + f32_move_row_bytes_ext_w));
  assign f32_move_index_end_ext_w =
      (macro_select_f32_get_w && !f32_move_empty_get_w) ?
      ({64'd0, macro_src1_iova_q} +
       ((f32_move_n_ext_w - 128'd1) *
        {64'd0, macro_src1_stride_q}) + 128'd4) :
      {64'd0, macro_src1_iova_q};
  assign f32_move_dst_end_ext_w = f32_move_empty_get_w ?
      {64'd0, macro_dst_iova_q} : (macro_select_f32_get_w ?
      ({64'd0, macro_dst_iova_q} +
       ((f32_move_n_ext_w - 128'd1) *
        {64'd0, macro_dst_stride_q}) + f32_move_row_bytes_ext_w) :
      ({64'd0, macro_dst_iova_q} +
       ((f32_move_o_ext_w - 128'd1) *
        {64'd0, macro_src2_stride_q}) + f32_move_repeat_plane_ext_w));

  assign f32_move_src_window_end_ext_w =
      {64'd0, macro_src0_window_base_q} +
      {64'd0, macro_src0_window_size_q};
  assign f32_move_index_window_end_ext_w =
      {64'd0, macro_src1_window_base_q} +
      {64'd0, macro_src1_window_size_q};
  assign f32_move_dst_window_end_ext_w =
      {64'd0, macro_dst_window_base_q} +
      {64'd0, macro_dst_window_size_q};
  assign f32_move_src_phys_start_ext_w =
      {64'd0, (macro_src0_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign f32_move_index_phys_start_ext_w =
      {64'd0, (macro_src1_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign f32_move_dst_phys_start_ext_w =
      {64'd0, (macro_dst_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign f32_move_src_phys_end_ext_w = f32_move_empty_get_w ?
      f32_move_src_phys_start_ext_w :
      (((f32_move_src_end_ext_w + 128'd7) >> 3) << 3);
  assign f32_move_index_phys_end_ext_w =
      (!macro_select_f32_get_w || f32_move_empty_get_w) ?
      f32_move_index_phys_start_ext_w :
      (((f32_move_index_end_ext_w + 128'd7) >> 3) << 3);
  assign f32_move_dst_phys_end_ext_w = f32_move_empty_get_w ?
      f32_move_dst_phys_start_ext_w :
      (((f32_move_dst_end_ext_w + 128'd7) >> 3) << 3);

  wire f32_move_abi_reject_w;
  wire f32_move_capability_reject_w;
  wire f32_move_layout_reject_w;
  wire f32_move_iova_reject_w;
  wire f32_move_src_dst_disjoint_w;
  wire f32_move_index_dst_disjoint_w;
  assign f32_move_abi_reject_w = !macro_abi_valid_q;
  assign f32_move_capability_reject_w =
      (macro_command_flags_q != COMMAND_FLAGS_REQUIRED_PROFILE) ||
      (macro_capability_epoch_q != MACRO_CAPABILITY_EPOCH) ||
      (macro_node_count_q != 32'd1) ||
      (macro_deadline_cycles_q != 64'd0);
  assign f32_move_layout_reject_w =
      (macro_vector_op_q != 32'd0) ||
      (macro_vector_flags_q != 32'd0) ||
      (macro_src2_iova_q != 64'd0) ||
      (macro_scratch_iova_q != 64'd0) ||
      (macro_element_count_q < 64'd1) ||
      (macro_element_count_q > 64'(F32_MOVE_MAX_ELEMENTS)) ||
      (macro_dtype_q != ABI_DTYPE_F32) ||
      (macro_scalar1_q != 32'd0) ||
      (macro_scratch_bytes_q != 32'd0) ||
      (macro_rope_position_q != 32'd0) ||
      ((macro_node_hash_lo_q == 64'd0) &&
       (macro_node_hash_hi_q == 64'd0)) ||
      (macro_src0_iova_q[1:0] != 2'b00) ||
      (macro_src1_iova_q[1:0] != 2'b00) ||
      (macro_dst_iova_q[1:0] != 2'b00) ||
      (macro_src0_stride_q[1:0] != 2'b00) ||
      (macro_src1_stride_q[1:0] != 2'b00) ||
      (macro_dst_stride_q[1:0] != 2'b00) ||
      (macro_src2_stride_q[1:0] != 2'b00) ||
      (f32_move_row_bytes_ext_w[127:64] != 64'd0) ||
      (f32_move_total_outputs_ext_w[127:64] != 64'd0) ||
      (f32_move_source_words_ext_w[127:64] != 64'd0) ||
      (f32_move_read_words_ext_w[127:64] != 64'd0) ||
      (f32_move_read_bytes_ext_w[127:64] != 64'd0) ||
      (f32_move_write_bytes_ext_w[127:64] != 64'd0) ||
      (macro_select_f32_get_w &&
       ((macro_outer_count_q > F32_MOVE_MAX_INDICES) ||
        ((macro_outer_count_q != 32'd0) &&
         (macro_scalar0_q < 32'd1)) ||
        ({64'd0, macro_src0_stride_q} < f32_move_row_bytes_ext_w) ||
        (macro_src1_stride_q < 64'd4) ||
        ({64'd0, macro_dst_stride_q} < f32_move_row_bytes_ext_w) ||
        (macro_src2_stride_q != 64'd0))) ||
      (macro_select_f32_repeat_w &&
       ((macro_outer_count_q < 32'd1) ||
        (macro_outer_count_q > F32_MOVE_MAX_OUTER) ||
        (macro_scalar0_q < 32'd1) ||
        (macro_scalar0_q > F32_MOVE_MAX_REPEAT) ||
        (macro_src1_iova_q != 64'd0) ||
        (macro_src1_stride_q != 64'd0) ||
        (macro_src1_window_base_q != 64'd0) ||
        (macro_src1_window_size_q != 64'd0) ||
        ({64'd0, macro_src0_stride_q} < f32_move_row_bytes_ext_w) ||
        ({64'd0, macro_dst_stride_q} < f32_move_row_bytes_ext_w) ||
        (f32_move_repeat_plane_ext_w[127:64] != 64'd0) ||
        ({64'd0, macro_src2_stride_q} < f32_move_repeat_plane_ext_w)));

  assign f32_move_src_dst_disjoint_w =
      (f32_move_dst_phys_end_ext_w <= f32_move_src_phys_start_ext_w) ||
      (f32_move_dst_phys_start_ext_w >= f32_move_src_phys_end_ext_w);
  assign f32_move_index_dst_disjoint_w =
      (f32_move_dst_phys_end_ext_w <= f32_move_index_phys_start_ext_w) ||
      (f32_move_dst_phys_start_ext_w >= f32_move_index_phys_end_ext_w);
  assign f32_move_iova_reject_w =
      !macro_windows_generation_valid_q ||
      (macro_src0_window_perm_q != 2'b01) ||
      (macro_src1_window_perm_q != 2'b01) ||
      (macro_dst_window_perm_q != 2'b10) ||
      (macro_src0_window_base_q[2:0] != 3'b000) ||
      (macro_src1_window_base_q[2:0] != 3'b000) ||
      (macro_dst_window_base_q[2:0] != 3'b000) ||
      (macro_src0_window_size_q[2:0] != 3'b000) ||
      (macro_src1_window_size_q[2:0] != 3'b000) ||
      (macro_dst_window_size_q[2:0] != 3'b000) ||
      (f32_move_src_window_end_ext_w[127:64] != 64'd0) ||
      (f32_move_index_window_end_ext_w[127:64] != 64'd0) ||
      (f32_move_dst_window_end_ext_w[127:64] != 64'd0) ||
      (!f32_move_empty_get_w &&
       ((macro_src0_window_size_q == 64'd0) ||
        (macro_dst_window_size_q == 64'd0) ||
        (f32_move_src_end_ext_w[127:64] != 64'd0) ||
        (f32_move_dst_end_ext_w[127:64] != 64'd0) ||
        (f32_move_src_phys_end_ext_w[127:64] != 64'd0) ||
        (f32_move_dst_phys_end_ext_w[127:64] != 64'd0) ||
        (f32_move_src_phys_start_ext_w <
         {64'd0, macro_src0_window_base_q}) ||
        (f32_move_src_phys_end_ext_w > f32_move_src_window_end_ext_w) ||
        (f32_move_dst_phys_start_ext_w <
         {64'd0, macro_dst_window_base_q}) ||
        (f32_move_dst_phys_end_ext_w > f32_move_dst_window_end_ext_w) ||
        !f32_move_src_dst_disjoint_w)) ||
      (macro_select_f32_get_w && !f32_move_empty_get_w &&
       ((macro_src1_window_size_q == 64'd0) ||
        (f32_move_index_end_ext_w[127:64] != 64'd0) ||
        (f32_move_index_phys_end_ext_w[127:64] != 64'd0) ||
        (f32_move_index_phys_start_ext_w <
         {64'd0, macro_src1_window_base_q}) ||
        (f32_move_index_phys_end_ext_w >
         f32_move_index_window_end_ext_w) ||
        !f32_move_index_dst_disjoint_w));

  wire f32_move_static_descriptor_valid_w;
  assign f32_move_static_descriptor_valid_w =
      !f32_move_abi_reject_w &&
      !f32_move_capability_reject_w &&
      !f32_move_layout_reject_w &&
      !f32_move_iova_reject_w;

  // F32 ARGMAX consumes every contiguous logit through the raw 64-bit GMEM
  // port and exposes only one I32 token index.  The physical byte ledger is
  // the aligned source beat span plus one four-byte destination write.
  wire [127:0] argmax_src_bytes_ext_w;
  wire [127:0] argmax_src_end_ext_w;
  wire [127:0] argmax_dst_end_ext_w;
  wire [127:0] argmax_src_window_end_ext_w;
  wire [127:0] argmax_dst_window_end_ext_w;
  wire [127:0] argmax_src_phys_start_ext_w;
  wire [127:0] argmax_src_phys_end_ext_w;
  wire [127:0] argmax_dst_phys_start_ext_w;
  wire [127:0] argmax_dst_phys_end_ext_w;
  wire [127:0] argmax_expected_read_bytes_ext_w;
  wire [127:0] argmax_expected_read_requests_ext_w;
  assign argmax_src_bytes_ext_w = {64'd0, macro_element_count_q} << 2;
  assign argmax_src_end_ext_w = {64'd0, macro_src0_iova_q}
                              + argmax_src_bytes_ext_w;
  assign argmax_dst_end_ext_w = {64'd0, macro_dst_iova_q} + 128'd4;
  assign argmax_src_window_end_ext_w =
      {64'd0, macro_src0_window_base_q}
      + {64'd0, macro_src0_window_size_q};
  assign argmax_dst_window_end_ext_w =
      {64'd0, macro_dst_window_base_q}
      + {64'd0, macro_dst_window_size_q};
  assign argmax_src_phys_start_ext_w =
      {64'd0, (macro_src0_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign argmax_src_phys_end_ext_w =
      ((argmax_src_end_ext_w + 128'd7) >> 3) << 3;
  assign argmax_dst_phys_start_ext_w =
      {64'd0, (macro_dst_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign argmax_dst_phys_end_ext_w =
      ((argmax_dst_end_ext_w + 128'd7) >> 3) << 3;
  assign argmax_expected_read_bytes_ext_w =
      argmax_src_phys_end_ext_w - argmax_src_phys_start_ext_w;
  assign argmax_expected_read_requests_ext_w =
      argmax_expected_read_bytes_ext_w >> 3;

  wire argmax_abi_reject_w;
  wire argmax_capability_reject_w;
  wire argmax_layout_reject_w;
  wire argmax_iova_reject_w;
  wire argmax_src_dst_disjoint_w;
  assign argmax_abi_reject_w = !macro_abi_valid_q;
  assign argmax_capability_reject_w =
      (macro_command_flags_q != COMMAND_FLAGS_REQUIRED_PROFILE) ||
      (macro_context_id_q != CANONICAL_CONTEXT_ID) ||
      (macro_capability_epoch_q != MACRO_CAPABILITY_EPOCH) ||
      (macro_node_count_q != 32'd1) ||
      (macro_deadline_cycles_q != 64'd0);
  assign argmax_layout_reject_w =
      (macro_vector_op_q != 32'd0) ||
      (macro_vector_flags_q != 32'd0) ||
      (macro_src1_iova_q != 64'd0) ||
      (macro_src2_iova_q != 64'd0) ||
      (macro_scratch_iova_q != 64'd0) ||
      (macro_element_count_q < 64'd1) ||
      (macro_element_count_q > 64'(F32_ARGMAX_MAX_ELEMENTS)) ||
      (macro_outer_count_q != 32'd1) ||
      (macro_dtype_q != ABI_DTYPE_F32) ||
      (macro_src0_stride_q != 64'd4) ||
      (macro_src1_stride_q != 64'd0) ||
      (macro_src2_stride_q != 64'd0) ||
      (macro_dst_stride_q != 64'd4) ||
      (macro_scalar0_q != 32'd0) ||
      (macro_scalar1_q != 32'd0) ||
      (macro_scratch_bytes_q != 32'd0) ||
      (macro_rope_position_q != 32'd0) ||
      ((macro_node_hash_lo_q == 64'd0) &&
       (macro_node_hash_hi_q == 64'd0));
  assign argmax_src_dst_disjoint_w =
      (argmax_src_phys_end_ext_w <= argmax_dst_phys_start_ext_w) ||
      (argmax_dst_phys_end_ext_w <= argmax_src_phys_start_ext_w);
  assign argmax_iova_reject_w =
      !macro_windows_generation_valid_q ||
      (macro_src0_window_perm_q != 2'b01) ||
      (macro_src1_window_perm_q != 2'b00) ||
      (macro_dst_window_perm_q != 2'b10) ||
      (macro_src1_window_base_q != 64'd0) ||
      (macro_src1_window_size_q != 64'd0) ||
      (macro_src0_iova_q[1:0] != 2'b00) ||
      (macro_dst_iova_q[1:0] != 2'b00) ||
      (macro_src0_window_base_q[2:0] != 3'b000) ||
      (macro_src0_window_size_q[2:0] != 3'b000) ||
      (macro_dst_window_base_q[2:0] != 3'b000) ||
      (macro_dst_window_size_q[2:0] != 3'b000) ||
      (macro_src0_window_size_q == 64'd0) ||
      (macro_dst_window_size_q == 64'd0) ||
      (argmax_src_end_ext_w[127:64] != 64'd0) ||
      (argmax_dst_end_ext_w[127:64] != 64'd0) ||
      (argmax_src_window_end_ext_w[127:64] != 64'd0) ||
      (argmax_dst_window_end_ext_w[127:64] != 64'd0) ||
      (argmax_src_phys_start_ext_w <
       {64'd0, macro_src0_window_base_q}) ||
      (argmax_src_phys_end_ext_w > argmax_src_window_end_ext_w) ||
      (argmax_dst_phys_start_ext_w <
       {64'd0, macro_dst_window_base_q}) ||
      (argmax_dst_phys_end_ext_w > argmax_dst_window_end_ext_w) ||
      !argmax_src_dst_disjoint_w;

  wire argmax_static_descriptor_valid_w;
  assign argmax_static_descriptor_valid_w =
      !argmax_abi_reject_w && !argmax_capability_reject_w &&
      !argmax_layout_reject_w && !argmax_iova_reject_w;

  // ------------------------------------------------------------------------
  // Frozen-v5 exact-profile table for UNARY/GLU/NORM/SUM_ROWS/SSM_CONV.
  //
  // For this public descriptor generation the common fields are frozen as:
  //   element_count = dst.ne0
  //   outer_count   = dst.ne1 * dst.ne2 * dst.ne3
  //   src0_stride   = src0.nb1
  //   src1_stride   = src1.nb1 (zero for the read-only sentinel)
  //   src2_stride   = src0.nb2 (an exact-profile witness, not a third source)
  //   dst_stride    = dst.nb1
  // Profile ID is the full 32-bit macro_vector_flags field.  No low-byte
  // alias is accepted.  The table creates the complete child descriptor only
  // after the public fields match the corresponding manifest row exactly.
  // ------------------------------------------------------------------------
  reg exact_profile_valid_r;
  reg [7:0] exact_profile_id_r;
  reg exact_operation_glu_r;
  reg [7:0] exact_subtype_r;
  reg [2:0] exact_reduce_op_r;
  reg [31:0] exact_epsilon_bits_r;
  reg [15:0] exact_manifest_op_id_r;
  reg [2:0] exact_source_arity_r;
  reg [127:0] exact_op_params_r;
  reg [7:0] exact_src0_dtype_r, exact_src1_dtype_r, exact_dst_dtype_r;
  reg [31:0] exact_src0_flags_r, exact_src1_flags_r, exact_dst_flags_r;
  reg [63:0] exact_src0_view_r, exact_src1_view_r, exact_dst_view_r;
  reg [31:0] exact_src0_ne0_r, exact_src0_ne1_r;
  reg [31:0] exact_src0_ne2_r, exact_src0_ne3_r;
  reg [31:0] exact_src1_ne0_r, exact_src1_ne1_r;
  reg [31:0] exact_src1_ne2_r, exact_src1_ne3_r;
  reg [31:0] exact_dst_ne0_r, exact_dst_ne1_r;
  reg [31:0] exact_dst_ne2_r, exact_dst_ne3_r;
  reg [63:0] exact_src0_nb0_r, exact_src0_nb1_r;
  reg [63:0] exact_src0_nb2_r, exact_src0_nb3_r;
  reg [63:0] exact_src1_nb0_r, exact_src1_nb1_r;
  reg [63:0] exact_src1_nb2_r, exact_src1_nb3_r;
  reg [63:0] exact_dst_nb0_r, exact_dst_nb1_r;
  reg [63:0] exact_dst_nb2_r, exact_dst_nb3_r;
  reg [31:0] exact_operator_census_r, exact_subtype_census_r;
  reg [31:0] exact_profile_census_r;
  reg [63:0] exact_expected_read_bytes_r;
  reg [63:0] exact_expected_write_bytes_r;
  reg [63:0] exact_expected_work_r;

  always @(*) begin
    exact_profile_valid_r = 1'b0;
    exact_profile_id_r = 8'hff;
    exact_operation_glu_r = macro_select_glu_w;
    exact_subtype_r = macro_vector_op_q[7:0];
    exact_reduce_op_r = macro_vector_op_q[2:0];
    exact_epsilon_bits_r = macro_select_norm_w ? NORM_EPSILON_QWEN : 32'd0;
    exact_manifest_op_id_r = macro_select_sum_w ? MANIFEST_SUM_ROWS :
                               (macro_select_ssm_w ? MANIFEST_SSM_CONV :
                                                    16'd0);
    exact_source_arity_r = (macro_select_glu_w || macro_select_ssm_w) ?
                           3'd2 : 3'd1;
    exact_op_params_r = 128'd0;
    exact_src0_dtype_r = MANIFEST_F32;
    exact_src1_dtype_r = MANIFEST_F32;
    exact_dst_dtype_r = MANIFEST_F32;
    exact_src0_flags_r = MANIFEST_FLAGS;
    exact_src1_flags_r = MANIFEST_FLAGS;
    exact_dst_flags_r = MANIFEST_FLAGS;
    exact_src0_view_r = 64'd0;
    exact_src1_view_r = 64'd0;
    exact_dst_view_r = 64'd0;
    exact_src0_ne0_r = 32'd0;
    exact_src0_ne1_r = 32'd0;
    exact_src0_ne2_r = 32'd0;
    exact_src0_ne3_r = 32'd0;
    exact_src1_ne0_r = 32'd0;
    exact_src1_ne1_r = 32'd0;
    exact_src1_ne2_r = 32'd0;
    exact_src1_ne3_r = 32'd0;
    exact_dst_ne0_r = 32'd0;
    exact_dst_ne1_r = 32'd0;
    exact_dst_ne2_r = 32'd0;
    exact_dst_ne3_r = 32'd0;
    exact_src0_nb0_r = 64'd0;
    exact_src0_nb1_r = 64'd0;
    exact_src0_nb2_r = 64'd0;
    exact_src0_nb3_r = 64'd0;
    exact_src1_nb0_r = 64'd0;
    exact_src1_nb1_r = 64'd0;
    exact_src1_nb2_r = 64'd0;
    exact_src1_nb3_r = 64'd0;
    exact_dst_nb0_r = 64'd0;
    exact_dst_nb1_r = 64'd0;
    exact_dst_nb2_r = 64'd0;
    exact_dst_nb3_r = 64'd0;
    exact_operator_census_r = 32'd0;
    exact_subtype_census_r = 32'd0;
    exact_profile_census_r = 32'd0;
    exact_expected_read_bytes_r = 64'd0;
    exact_expected_write_bytes_r = 64'd0;
    exact_expected_work_r = 64'd0;

    if (macro_select_unary_glu_w) begin
      exact_operator_census_r = macro_select_glu_w ? 32'd24 : 32'd96;
      case (macro_vector_flags_q)
        32'd0: begin
          if (macro_select_unary_w && (macro_vector_op_q == 32'h07)) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd0;
            exact_src0_ne0_r = 32'd1;
            exact_src0_ne1_r = 32'd16;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd4;
            exact_src0_nb2_r = 64'd64;
            exact_src0_nb3_r = 64'd64;
            exact_subtype_census_r = 32'd24;
            exact_profile_census_r = 32'd18;
            exact_expected_read_bytes_r = 64'd64;
            exact_expected_write_bytes_r = 64'd64;
            exact_expected_work_r = 64'd16;
          end
        end
        32'd1: begin
          if (macro_select_unary_w && (macro_vector_op_q == 32'h07)) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd1;
            exact_src0_ne0_r = 32'd2048;
            exact_src0_ne1_r = 32'd1;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd8192;
            exact_src0_nb2_r = 64'd8192;
            exact_src0_nb3_r = 64'd8192;
            exact_subtype_census_r = 32'd24;
            exact_profile_census_r = 32'd6;
            exact_expected_read_bytes_r = 64'd8192;
            exact_expected_write_bytes_r = 64'd8192;
            exact_expected_work_r = 64'd2048;
          end
        end
        32'd2: begin
          if (macro_select_unary_w && (macro_vector_op_q == 32'h0f)) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd2;
            exact_src0_ne0_r = 32'd16;
            exact_src0_ne1_r = 32'd1;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd64;
            exact_src0_nb2_r = 64'd64;
            exact_src0_nb3_r = 64'd64;
            exact_subtype_census_r = 32'd18;
            exact_profile_census_r = 32'd18;
            exact_expected_read_bytes_r = 64'd64;
            exact_expected_write_bytes_r = 64'd64;
            exact_expected_work_r = 64'd16;
          end
        end
        32'd3: begin
          if (macro_select_unary_w && (macro_vector_op_q == 32'h0a)) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd3;
            exact_src0_ne0_r = 32'd128;
            exact_src0_ne1_r = 32'd16;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd512;
            exact_src0_nb2_r = 64'd8192;
            exact_src0_nb3_r = 64'd8192;
            exact_subtype_census_r = 32'd36;
            exact_profile_census_r = 32'd18;
            exact_expected_read_bytes_r = 64'd8192;
            exact_expected_write_bytes_r = 64'd8192;
            exact_expected_work_r = 64'd2048;
          end
        end
        32'd4: begin
          if (macro_select_unary_w && (macro_vector_op_q == 32'h0a)) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd4;
            exact_src0_ne0_r = 32'd6144;
            exact_src0_ne1_r = 32'd1;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd24576;
            exact_src0_nb2_r = 64'd24576;
            exact_src0_nb3_r = 64'd24576;
            exact_subtype_census_r = 32'd36;
            exact_profile_census_r = 32'd18;
            exact_expected_read_bytes_r = 64'd24576;
            exact_expected_write_bytes_r = 64'd24576;
            exact_expected_work_r = 64'd6144;
          end
        end
        32'd5: begin
          if (macro_select_unary_w && (macro_vector_op_q == 32'h0d)) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd5;
            exact_src0_ne0_r = 32'd1;
            exact_src0_ne1_r = 32'd1;
            exact_src0_ne2_r = 32'd16;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd4;
            exact_src0_nb2_r = 64'd4;
            exact_src0_nb3_r = 64'd64;
            exact_subtype_census_r = 32'd18;
            exact_profile_census_r = 32'd18;
            exact_expected_read_bytes_r = 64'd64;
            exact_expected_write_bytes_r = 64'd64;
            exact_expected_work_r = 64'd16;
          end
        end
        32'd6: begin
          if (macro_select_glu_w && (macro_vector_op_q == 32'h02)) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd6;
            exact_src0_ne0_r = 32'd3584;
            exact_src0_ne1_r = 32'd1;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd14336;
            exact_src0_nb2_r = 64'd14336;
            exact_src0_nb3_r = 64'd14336;
            exact_src1_nb0_r = 64'd4;
            exact_src1_nb1_r = 64'd14336;
            exact_src1_nb2_r = 64'd14336;
            exact_src1_nb3_r = 64'd14336;
            exact_subtype_census_r = 32'd24;
            exact_profile_census_r = 32'd24;
            exact_expected_read_bytes_r = 64'd28672;
            exact_expected_write_bytes_r = 64'd14336;
            exact_expected_work_r = 64'd3584;
          end
        end
        default: begin end
      endcase
      exact_src1_ne0_r = exact_src0_ne0_r;
      exact_src1_ne1_r = exact_src0_ne1_r;
      exact_src1_ne2_r = exact_src0_ne2_r;
      exact_src1_ne3_r = exact_src0_ne3_r;
      exact_dst_ne0_r = exact_src0_ne0_r;
      exact_dst_ne1_r = exact_src0_ne1_r;
      exact_dst_ne2_r = exact_src0_ne2_r;
      exact_dst_ne3_r = exact_src0_ne3_r;
      exact_dst_nb0_r = exact_src0_nb0_r;
      exact_dst_nb1_r = exact_src0_nb1_r;
      exact_dst_nb2_r = exact_src0_nb2_r;
      exact_dst_nb3_r = exact_src0_nb3_r;
    end else if (macro_select_norm_w) begin
      exact_operator_census_r = (macro_vector_op_q == 32'd4) ?
                                32'd79 : 32'd36;
      case (macro_vector_flags_q)
        32'd0: begin
          if (macro_vector_op_q == 32'd4) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd0;
            exact_src0_ne0_r = 32'd1024;
            exact_src0_ne1_r = 32'd1;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd4096;
            exact_src0_nb2_r = 64'd4096;
            exact_src0_nb3_r = 64'd4096;
            exact_dst_nb0_r = 64'd4;
            exact_dst_nb1_r = 64'd4096;
            exact_dst_nb2_r = 64'd4096;
            exact_dst_nb3_r = 64'd4096;
            exact_profile_census_r = 32'd49;
            exact_expected_read_bytes_r = 64'd4096;
            exact_expected_write_bytes_r = 64'd4096;
            exact_expected_work_r = 64'd1024;
          end
        end
        32'd1: begin
          if (macro_vector_op_q == 32'd4) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd1;
            exact_src0_ne0_r = 32'd128;
            exact_src0_ne1_r = 32'd16;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd512;
            exact_src0_nb2_r = 64'd4;
            exact_src0_nb3_r = 64'd8192;
            exact_dst_nb0_r = 64'd4;
            exact_dst_nb1_r = 64'd512;
            exact_dst_nb2_r = 64'd8192;
            exact_dst_nb3_r = 64'd8192;
            exact_profile_census_r = 32'd18;
            exact_expected_read_bytes_r = 64'd8192;
            exact_expected_write_bytes_r = 64'd8192;
            exact_expected_work_r = 64'd2048;
          end
        end
        32'd2: begin
          if (macro_vector_op_q == 32'd4) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd2;
            exact_src0_ne0_r = 32'd256;
            exact_src0_ne1_r = 32'd2;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd1024;
            exact_src0_nb2_r = 64'd2048;
            exact_src0_nb3_r = 64'd2048;
            exact_dst_nb0_r = 64'd4;
            exact_dst_nb1_r = 64'd1024;
            exact_dst_nb2_r = 64'd2048;
            exact_dst_nb3_r = 64'd2048;
            exact_profile_census_r = 32'd6;
            exact_expected_read_bytes_r = 64'd2048;
            exact_expected_write_bytes_r = 64'd2048;
            exact_expected_work_r = 64'd512;
          end
        end
        32'd3: begin
          if (macro_vector_op_q == 32'd4) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd3;
            exact_src0_ne0_r = 32'd256;
            exact_src0_ne1_r = 32'd8;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd2048;
            exact_src0_nb2_r = 64'd16384;
            exact_src0_nb3_r = 64'd16384;
            exact_dst_nb0_r = 64'd4;
            exact_dst_nb1_r = 64'd1024;
            exact_dst_nb2_r = 64'd8192;
            exact_dst_nb3_r = 64'd8192;
            exact_profile_census_r = 32'd6;
            exact_expected_read_bytes_r = 64'd8192;
            exact_expected_write_bytes_r = 64'd8192;
            exact_expected_work_r = 64'd2048;
          end
        end
        32'd4: begin
          if (macro_vector_op_q == 32'd5) begin
            exact_profile_valid_r = 1'b1;
            exact_profile_id_r = 8'd4;
            exact_src0_ne0_r = 32'd128;
            exact_src0_ne1_r = 32'd16;
            exact_src0_ne2_r = 32'd1;
            exact_src0_ne3_r = 32'd1;
            exact_src0_nb0_r = 64'd4;
            exact_src0_nb1_r = 64'd512;
            exact_src0_nb2_r = 64'd24576;
            exact_src0_nb3_r = 64'd24576;
            exact_dst_nb0_r = 64'd4;
            exact_dst_nb1_r = 64'd512;
            exact_dst_nb2_r = 64'd8192;
            exact_dst_nb3_r = 64'd8192;
            exact_profile_census_r = 32'd36;
            exact_expected_read_bytes_r = 64'd8192;
            exact_expected_write_bytes_r = 64'd8192;
            exact_expected_work_r = 64'd2048;
          end
        end
        default: begin end
      endcase
      exact_src1_ne0_r = exact_src0_ne0_r;
      exact_src1_ne1_r = exact_src0_ne1_r;
      exact_src1_ne2_r = exact_src0_ne2_r;
      exact_src1_ne3_r = exact_src0_ne3_r;
      exact_dst_ne0_r = exact_src0_ne0_r;
      exact_dst_ne1_r = exact_src0_ne1_r;
      exact_dst_ne2_r = exact_src0_ne2_r;
      exact_dst_ne3_r = exact_src0_ne3_r;
    end else if (macro_select_sum_w && (macro_vector_flags_q == 32'd0)) begin
      exact_profile_valid_r = 1'b1;
      exact_profile_id_r = 8'd0;
      exact_src0_ne0_r = 32'd128;
      exact_src0_ne1_r = 32'd128;
      exact_src0_ne2_r = 32'd16;
      exact_src0_ne3_r = 32'd1;
      exact_src0_nb0_r = 64'd4;
      exact_src0_nb1_r = 64'd512;
      exact_src0_nb2_r = 64'd65536;
      exact_src0_nb3_r = 64'd1048576;
      exact_dst_ne0_r = 32'd1;
      exact_dst_ne1_r = 32'd128;
      exact_dst_ne2_r = 32'd16;
      exact_dst_ne3_r = 32'd1;
      exact_dst_nb0_r = 64'd4;
      exact_dst_nb1_r = 64'd4;
      exact_dst_nb2_r = 64'd512;
      exact_dst_nb3_r = 64'd8192;
      exact_operator_census_r = 32'd36;
      exact_profile_census_r = 32'd36;
      exact_expected_read_bytes_r = 64'd1048576;
      exact_expected_write_bytes_r = 64'd8192;
      exact_expected_work_r = 64'd262144;
    end else if (macro_select_ssm_w &&
                 (macro_vector_op_q == 32'd76) &&
                 (macro_vector_flags_q == 32'd0)) begin
      exact_profile_valid_r = 1'b1;
      exact_profile_id_r = 8'd0;
      exact_src0_ne0_r = 32'd4;
      exact_src0_ne1_r = 32'd6144;
      exact_src0_ne2_r = 32'd1;
      exact_src0_ne3_r = 32'd1;
      exact_src0_nb0_r = 64'd4;
      exact_src0_nb1_r = 64'd16;
      exact_src0_nb2_r = 64'd98304;
      exact_src0_nb3_r = 64'd98304;
      exact_src1_ne0_r = 32'd4;
      exact_src1_ne1_r = 32'd6144;
      exact_src1_ne2_r = 32'd1;
      exact_src1_ne3_r = 32'd1;
      exact_src1_nb0_r = 64'd4;
      exact_src1_nb1_r = 64'd16;
      exact_src1_nb2_r = 64'd98304;
      exact_src1_nb3_r = 64'd98304;
      exact_src1_flags_r = 32'd0;
      exact_dst_ne0_r = 32'd6144;
      exact_dst_ne1_r = 32'd1;
      exact_dst_ne2_r = 32'd1;
      exact_dst_ne3_r = 32'd1;
      exact_dst_nb0_r = 64'd4;
      exact_dst_nb1_r = 64'd24576;
      exact_dst_nb2_r = 64'd24576;
      exact_dst_nb3_r = 64'd24576;
      exact_operator_census_r = 32'd18;
      exact_profile_census_r = 32'd18;
      exact_expected_read_bytes_r = 64'd196608;
      exact_expected_write_bytes_r = 64'd24576;
      exact_expected_work_r = 64'd24576;
    end
  end

  wire [127:0] exact_outer_ext_w;
  wire [127:0] exact_src0_last_ext_w, exact_src1_last_ext_w;
  wire [127:0] exact_dst_last_ext_w;
  wire [127:0] exact_src0_end_ext_w, exact_src1_end_ext_w;
  wire [127:0] exact_dst_end_ext_w;
  wire [127:0] exact_src0_window_end_ext_w;
  wire [127:0] exact_src1_window_end_ext_w;
  wire [127:0] exact_dst_window_end_ext_w;
  wire [127:0] exact_src0_phys_start_ext_w;
  wire [127:0] exact_src1_phys_start_ext_w;
  wire [127:0] exact_dst_phys_start_ext_w;
  wire [127:0] exact_src0_phys_end_ext_w;
  wire [127:0] exact_src1_phys_end_ext_w;
  wire [127:0] exact_dst_phys_end_ext_w;
  wire exact_src1_sentinel_w;

  assign exact_outer_ext_w = {96'd0, exact_dst_ne1_r}
                           * {96'd0, exact_dst_ne2_r}
                           * {96'd0, exact_dst_ne3_r};
  assign exact_src0_last_ext_w =
      ({96'd0, (exact_src0_ne0_r - 32'd1)} *
       {64'd0, exact_src0_nb0_r}) +
      ({96'd0, (exact_src0_ne1_r - 32'd1)} *
       {64'd0, exact_src0_nb1_r}) +
      ({96'd0, (exact_src0_ne2_r - 32'd1)} *
       {64'd0, exact_src0_nb2_r}) +
      ({96'd0, (exact_src0_ne3_r - 32'd1)} *
       {64'd0, exact_src0_nb3_r});
  assign exact_src1_last_ext_w =
      ({96'd0, (exact_src1_ne0_r - 32'd1)} *
       {64'd0, exact_src1_nb0_r}) +
      ({96'd0, (exact_src1_ne1_r - 32'd1)} *
       {64'd0, exact_src1_nb1_r}) +
      ({96'd0, (exact_src1_ne2_r - 32'd1)} *
       {64'd0, exact_src1_nb2_r}) +
      ({96'd0, (exact_src1_ne3_r - 32'd1)} *
       {64'd0, exact_src1_nb3_r});
  assign exact_dst_last_ext_w =
      ({96'd0, (exact_dst_ne0_r - 32'd1)} *
       {64'd0, exact_dst_nb0_r}) +
      ({96'd0, (exact_dst_ne1_r - 32'd1)} *
       {64'd0, exact_dst_nb1_r}) +
      ({96'd0, (exact_dst_ne2_r - 32'd1)} *
       {64'd0, exact_dst_nb2_r}) +
      ({96'd0, (exact_dst_ne3_r - 32'd1)} *
       {64'd0, exact_dst_nb3_r});
  assign exact_src0_end_ext_w = {64'd0, macro_src0_iova_q} +
                                exact_src0_last_ext_w + 128'd4;
  assign exact_src1_sentinel_w = !macro_select_glu_w &&
                                 !macro_select_ssm_w;
  assign exact_src1_end_ext_w = exact_src1_sentinel_w ?
      {64'd0, macro_src1_iova_q} :
      ({64'd0, macro_src1_iova_q} + exact_src1_last_ext_w + 128'd4);
  assign exact_dst_end_ext_w = {64'd0, macro_dst_iova_q} +
                               exact_dst_last_ext_w + 128'd4;
  assign exact_src0_window_end_ext_w =
      {64'd0, macro_src0_window_base_q} +
      {64'd0, macro_src0_window_size_q};
  assign exact_src1_window_end_ext_w =
      {64'd0, macro_src1_window_base_q} +
      {64'd0, macro_src1_window_size_q};
  assign exact_dst_window_end_ext_w =
      {64'd0, macro_dst_window_base_q} +
      {64'd0, macro_dst_window_size_q};
  assign exact_src0_phys_start_ext_w =
      {64'd0, (macro_src0_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign exact_src1_phys_start_ext_w =
      {64'd0, (macro_src1_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign exact_dst_phys_start_ext_w =
      {64'd0, (macro_dst_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign exact_src0_phys_end_ext_w =
      ((exact_src0_end_ext_w + 128'd7) >> 3) << 3;
  assign exact_src1_phys_end_ext_w = exact_src1_sentinel_w ?
      exact_src1_phys_start_ext_w :
      (((exact_src1_end_ext_w + 128'd7) >> 3) << 3);
  assign exact_dst_phys_end_ext_w =
      ((exact_dst_end_ext_w + 128'd7) >> 3) << 3;

  wire exact_abi_reject_w;
  wire exact_capability_reject_w;
  wire exact_layout_reject_w;
  wire exact_iova_reject_w;
  wire exact_src0_dst_disjoint_w;
  wire exact_src1_dst_disjoint_w;
  wire exact_src0_src1_disjoint_w;
  assign exact_abi_reject_w = !macro_abi_valid_q;
  assign exact_capability_reject_w =
      (macro_command_flags_q != COMMAND_FLAGS_REQUIRED_PROFILE) ||
      (macro_context_id_q != CANONICAL_CONTEXT_ID) ||
      (macro_capability_epoch_q != MACRO_CAPABILITY_EPOCH) ||
      (macro_node_count_q != 32'd1) ||
      (macro_deadline_cycles_q != 64'd0);
  assign exact_layout_reject_w = !exact_profile_valid_r ||
      (macro_src2_iova_q != 64'd0) ||
      (macro_scratch_iova_q != 64'd0) ||
      (macro_element_count_q != {32'd0, exact_dst_ne0_r}) ||
      (exact_outer_ext_w[127:32] != 96'd0) ||
      (macro_outer_count_q != exact_outer_ext_w[31:0]) ||
      (macro_dtype_q != ABI_DTYPE_F32) ||
      (macro_src0_stride_q != exact_src0_nb1_r) ||
      (macro_src1_stride_q != exact_src1_nb1_r) ||
      (macro_src2_stride_q != exact_src0_nb2_r) ||
      (macro_dst_stride_q != exact_dst_nb1_r) ||
      (macro_scalar0_q != exact_epsilon_bits_r) ||
      (macro_scalar1_q != 32'd0) ||
      (macro_scratch_bytes_q != 32'd0) ||
      (macro_rope_position_q != 32'd0) ||
      ((macro_node_hash_lo_q == 64'd0) &&
       (macro_node_hash_hi_q == 64'd0));
  assign exact_src0_dst_disjoint_w =
      (exact_src0_phys_end_ext_w <= exact_dst_phys_start_ext_w) ||
      (exact_dst_phys_end_ext_w <= exact_src0_phys_start_ext_w);
  assign exact_src1_dst_disjoint_w = exact_src1_sentinel_w ||
      (exact_src1_phys_end_ext_w <= exact_dst_phys_start_ext_w) ||
      (exact_dst_phys_end_ext_w <= exact_src1_phys_start_ext_w);
  assign exact_src0_src1_disjoint_w = !macro_select_ssm_w ||
      (exact_src0_phys_end_ext_w <= exact_src1_phys_start_ext_w) ||
      (exact_src1_phys_end_ext_w <= exact_src0_phys_start_ext_w);
  assign exact_iova_reject_w =
      !macro_windows_generation_valid_q ||
      (macro_src0_window_perm_q != 2'b01) ||
      (macro_src1_window_perm_q != 2'b01) ||
      (macro_dst_window_perm_q != 2'b10) ||
      (macro_src0_iova_q[1:0] != 2'b00) ||
      (macro_src1_iova_q[1:0] != 2'b00) ||
      (macro_dst_iova_q[1:0] != 2'b00) ||
      (macro_src0_window_base_q[2:0] != 3'b000) ||
      (macro_src1_window_base_q[2:0] != 3'b000) ||
      (macro_dst_window_base_q[2:0] != 3'b000) ||
      (macro_src0_window_size_q[2:0] != 3'b000) ||
      (macro_src1_window_size_q[2:0] != 3'b000) ||
      (macro_dst_window_size_q[2:0] != 3'b000) ||
      (macro_src0_window_size_q == 64'd0) ||
      (!exact_src1_sentinel_w && (macro_src1_window_size_q == 64'd0)) ||
      (exact_src1_sentinel_w &&
       ((macro_src1_window_size_q != 64'd0) ||
        (macro_src1_iova_q != macro_src1_window_base_q))) ||
      (macro_dst_window_size_q == 64'd0) ||
      (exact_src0_end_ext_w[127:64] != 64'd0) ||
      (exact_src1_end_ext_w[127:64] != 64'd0) ||
      (exact_dst_end_ext_w[127:64] != 64'd0) ||
      (exact_src0_window_end_ext_w[127:64] != 64'd0) ||
      (exact_src1_window_end_ext_w[127:64] != 64'd0) ||
      (exact_dst_window_end_ext_w[127:64] != 64'd0) ||
      (exact_src0_phys_start_ext_w <
       {64'd0, macro_src0_window_base_q}) ||
      (exact_src0_phys_end_ext_w > exact_src0_window_end_ext_w) ||
      (!exact_src1_sentinel_w &&
       ((exact_src1_phys_start_ext_w <
         {64'd0, macro_src1_window_base_q}) ||
        (exact_src1_phys_end_ext_w > exact_src1_window_end_ext_w))) ||
      (exact_dst_phys_start_ext_w <
       {64'd0, macro_dst_window_base_q}) ||
      (exact_dst_phys_end_ext_w > exact_dst_window_end_ext_w) ||
      !exact_src0_dst_disjoint_w || !exact_src1_dst_disjoint_w ||
      !exact_src0_src1_disjoint_w;

  wire exact_static_descriptor_valid_w;
  assign exact_static_descriptor_valid_w = !exact_abi_reject_w &&
                                           !exact_capability_reject_w &&
                                           !exact_layout_reject_w &&
                                           !exact_iova_reject_w;

  // ------------------------------------------------------------------------
  // Frozen-v5 exact profiles for MOVER/SET_ROWS, F16 attention MUL_MAT,
  // IMROPE and SOFT_MAX.  The public macro surface intentionally carries only
  // profile witnesses.  Complete manifest descriptors (including all 512
  // ROPE parameter bits) are rebuilt here and are never supplied by host-side
  // arithmetic.  Profile IDs are matched as full 32-bit values.
  // ------------------------------------------------------------------------
  reg batch2_profile_valid_r;
  reg [7:0] batch2_profile_id_r;
  reg [2:0] batch2_operation_r;
  reg [31:0] batch2_vector_op_r;
  reg [15:0] batch2_manifest_op_r;
  reg [2:0] batch2_source_arity_r;
  reg [511:0] batch2_op_params_r;
  reg [7:0] batch2_src0_dtype_r, batch2_src1_dtype_r;
  reg [7:0] batch2_dst_dtype_r;
  reg [31:0] batch2_src0_flags_r, batch2_src1_flags_r;
  reg [31:0] batch2_src2_flags_r, batch2_dst_flags_r;
  reg [63:0] batch2_src0_region_size_r, batch2_src1_region_size_r;
  reg [63:0] batch2_dst_region_size_r;
  reg [63:0] batch2_src0_view_r, batch2_src1_view_r;
  reg [63:0] batch2_dst_view_r;
  reg [31:0] batch2_src0_ne0_r, batch2_src0_ne1_r;
  reg [31:0] batch2_src0_ne2_r, batch2_src0_ne3_r;
  reg [31:0] batch2_src1_ne0_r, batch2_src1_ne1_r;
  reg [31:0] batch2_src1_ne2_r, batch2_src1_ne3_r;
  reg [31:0] batch2_dst_ne0_r, batch2_dst_ne1_r;
  reg [31:0] batch2_dst_ne2_r, batch2_dst_ne3_r;
  reg [63:0] batch2_src0_nb0_r, batch2_src0_nb1_r;
  reg [63:0] batch2_src0_nb2_r, batch2_src0_nb3_r;
  reg [63:0] batch2_src1_nb0_r, batch2_src1_nb1_r;
  reg [63:0] batch2_src1_nb2_r, batch2_src1_nb3_r;
  reg [63:0] batch2_dst_nb0_r, batch2_dst_nb1_r;
  reg [63:0] batch2_dst_nb2_r, batch2_dst_nb3_r;
  reg [63:0] batch2_expected_read_bytes_r;
  reg [63:0] batch2_expected_write_bytes_r;
  reg [63:0] batch2_expected_work_r;
  reg [63:0] batch2_expected_read_requests_r;
  reg [63:0] batch2_expected_write_requests_r;

  always @(*) begin
    batch2_profile_valid_r = 1'b0;
    batch2_profile_id_r = 8'hff;
    batch2_operation_r = 3'd0;
    batch2_vector_op_r = 32'd0;
    batch2_manifest_op_r = 16'd0;
    batch2_source_arity_r = 3'd0;
    batch2_op_params_r = 512'd0;
    batch2_src0_dtype_r = MANIFEST_F32;
    batch2_src1_dtype_r = MANIFEST_F32;
    batch2_dst_dtype_r = MANIFEST_F32;
    batch2_src0_flags_r = MANIFEST_FLAGS;
    batch2_src1_flags_r = MANIFEST_FLAGS;
    batch2_src2_flags_r = 32'd0;
    batch2_dst_flags_r = MANIFEST_FLAGS;
    batch2_src0_region_size_r = 64'd0;
    batch2_src1_region_size_r = 64'd0;
    batch2_dst_region_size_r = 64'd0;
    batch2_src0_view_r = 64'd0;
    batch2_src1_view_r = 64'd0;
    batch2_dst_view_r = 64'd0;
    batch2_src0_ne0_r = 32'd0;
    batch2_src0_ne1_r = 32'd0;
    batch2_src0_ne2_r = 32'd0;
    batch2_src0_ne3_r = 32'd0;
    batch2_src1_ne0_r = 32'd0;
    batch2_src1_ne1_r = 32'd0;
    batch2_src1_ne2_r = 32'd0;
    batch2_src1_ne3_r = 32'd0;
    batch2_dst_ne0_r = 32'd0;
    batch2_dst_ne1_r = 32'd0;
    batch2_dst_ne2_r = 32'd0;
    batch2_dst_ne3_r = 32'd0;
    batch2_src0_nb0_r = 64'd0;
    batch2_src0_nb1_r = 64'd0;
    batch2_src0_nb2_r = 64'd0;
    batch2_src0_nb3_r = 64'd0;
    batch2_src1_nb0_r = 64'd0;
    batch2_src1_nb1_r = 64'd0;
    batch2_src1_nb2_r = 64'd0;
    batch2_src1_nb3_r = 64'd0;
    batch2_dst_nb0_r = 64'd0;
    batch2_dst_nb1_r = 64'd0;
    batch2_dst_nb2_r = 64'd0;
    batch2_dst_nb3_r = 64'd0;
    batch2_expected_read_bytes_r = 64'd0;
    batch2_expected_write_bytes_r = 64'd0;
    batch2_expected_work_r = 64'd0;
    batch2_expected_read_requests_r = 64'd0;
    batch2_expected_write_requests_r = 64'd0;

    if (macro_select_mover_set_w) begin
      case (macro_vector_flags_q)
        32'd0: begin
          if (macro_select_mover_w && (macro_vector_op_q == 32'd22)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = 8'd0;
            batch2_operation_r = 3'd2;
            batch2_vector_op_r = 32'd22;
            batch2_source_arity_r = 3'd2;
            batch2_src0_region_size_r = 64'd73728;
            batch2_src1_region_size_r = 64'd24576;
            batch2_dst_region_size_r = 64'd98304;
            batch2_src0_ne0_r = 32'd3; batch2_src0_ne1_r = 32'd6144;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd12;
            batch2_src0_nb2_r = 64'd73728; batch2_src0_nb3_r = 64'd73728;
            batch2_src1_ne0_r = 32'd1; batch2_src1_ne1_r = 32'd6144;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd24576; batch2_src1_nb1_r = 64'd4;
            batch2_src1_nb2_r = 64'd24576; batch2_src1_nb3_r = 64'd24576;
            batch2_dst_ne0_r = 32'd4; batch2_dst_ne1_r = 32'd6144;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd16;
            batch2_dst_nb2_r = 64'd98304; batch2_dst_nb3_r = 64'd98304;
            batch2_expected_read_bytes_r = 64'd98304;
            batch2_expected_write_bytes_r = 64'd98304;
            batch2_expected_work_r = 64'd24576;
            batch2_expected_read_requests_r = 64'd24576;
            batch2_expected_write_requests_r = 64'd24576;
          end
        end
        32'd1, 32'd2: begin
          if (macro_select_mover_w && (macro_vector_op_q == 32'd35)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = macro_vector_flags_q[7:0];
            batch2_operation_r = 3'd1;
            batch2_vector_op_r = 32'd35;
            batch2_source_arity_r = 3'd1;
            batch2_src1_flags_r = 32'd0;
            batch2_src0_region_size_r = (macro_vector_flags_q == 32'd1) ?
                                        64'd8192 : 64'd16384;
            batch2_dst_region_size_r = 64'd8192;
            batch2_src0_view_r = (macro_vector_flags_q == 32'd1) ?
                                 64'd0 : 64'd1024;
            batch2_src0_ne0_r = 32'd256; batch2_src0_ne1_r = 32'd8;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4;
            batch2_src0_nb1_r = (macro_vector_flags_q == 32'd1) ?
                                64'd1024 : 64'd2048;
            batch2_src0_nb2_r = (macro_vector_flags_q == 32'd1) ?
                                64'd1024 : 64'd16384;
            batch2_src0_nb3_r = (macro_vector_flags_q == 32'd1) ?
                                64'd8192 : 64'd16384;
            batch2_dst_ne0_r = 32'd2048; batch2_dst_ne1_r = 32'd1;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd8192;
            batch2_dst_nb2_r = 64'd8192; batch2_dst_nb3_r = 64'd8192;
            batch2_expected_read_bytes_r = 64'd8192;
            batch2_expected_write_bytes_r = 64'd8192;
            batch2_expected_work_r = 64'd2048;
            batch2_expected_read_requests_r = 64'd2048;
            batch2_expected_write_requests_r = 64'd2048;
          end
        end
        32'd3: begin
          if (macro_select_mover_w && (macro_vector_op_q == 32'd34)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = 8'd3;
            batch2_operation_r = 3'd0;
            batch2_vector_op_r = 32'd34;
            batch2_source_arity_r = 3'd2;
            // This frozen CPY is logically empty (ne1=0).  Its src1/dst
            // views sit exactly at the end of their 73728-byte windows, so
            // every semantic region is zero bytes.  Keeping a row-sized
            // region here makes the static IOVA check extend one row past
            // the window even though the owner correctly emits no traffic.
            batch2_src0_region_size_r = 64'd0;
            batch2_src1_region_size_r = 64'd0;
            batch2_dst_region_size_r = 64'd0;
            batch2_src1_view_r = 64'd73728;
            batch2_dst_view_r = 64'd73728;
            batch2_src0_ne0_r = 32'd18432; batch2_src0_ne1_r = 32'd0;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd73728;
            batch2_src1_ne0_r = 32'd18432; batch2_src1_ne1_r = 32'd0;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd4; batch2_src1_nb1_r = 64'd73728;
            batch2_dst_ne0_r = 32'd18432; batch2_dst_ne1_r = 32'd0;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd73728;
          end
        end
        32'd4: begin
          if (macro_select_mover_w && (macro_vector_op_q == 32'd34)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = 8'd4;
            batch2_operation_r = 3'd0;
            batch2_vector_op_r = 32'd34;
            batch2_source_arity_r = 3'd2;
            batch2_src0_region_size_r = 64'd98304;
            batch2_src1_region_size_r = 64'd73728;
            batch2_dst_region_size_r = 64'd73728;
            batch2_src0_view_r = 64'd4;
            batch2_src0_ne0_r = 32'd3; batch2_src0_ne1_r = 32'd6144;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd16;
            batch2_src0_nb2_r = 64'd98304; batch2_src0_nb3_r = 64'd98304;
            batch2_src1_ne0_r = 32'd18432; batch2_src1_ne1_r = 32'd1;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd4; batch2_src1_nb1_r = 64'd73728;
            batch2_src1_nb2_r = 64'd73728; batch2_src1_nb3_r = 64'd73728;
            batch2_dst_ne0_r = 32'd18432; batch2_dst_ne1_r = 32'd1;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd73728;
            batch2_dst_nb2_r = 64'd73728; batch2_dst_nb3_r = 64'd73728;
            batch2_expected_read_bytes_r = 64'd73728;
            batch2_expected_write_bytes_r = 64'd73728;
            batch2_expected_work_r = 64'd18432;
            batch2_expected_read_requests_r = 64'd18432;
            batch2_expected_write_requests_r = 64'd18432;
          end
        end
        32'd5: begin
          if (macro_select_mover_w && (macro_vector_op_q == 32'd34)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = 8'd5;
            batch2_operation_r = 3'd0;
            batch2_vector_op_r = 32'd34;
            batch2_source_arity_r = 3'd2;
            // Same zero-cardinality CPY contract as profile 3, for D=262144.
            batch2_src0_region_size_r = 64'd0;
            batch2_src1_region_size_r = 64'd0;
            batch2_dst_region_size_r = 64'd0;
            batch2_src1_view_r = 64'd1048576;
            batch2_dst_view_r = 64'd1048576;
            batch2_src0_ne0_r = 32'd262144; batch2_src0_ne1_r = 32'd0;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd1048576;
            batch2_src1_ne0_r = 32'd262144; batch2_src1_ne1_r = 32'd0;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd4; batch2_src1_nb1_r = 64'd1048576;
            batch2_dst_ne0_r = 32'd262144; batch2_dst_ne1_r = 32'd0;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd1048576;
          end
        end
        32'd6: begin
          if (macro_select_mover_w && (macro_vector_op_q == 32'd34)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = 8'd6;
            batch2_operation_r = 3'd0;
            batch2_vector_op_r = 32'd34;
            batch2_source_arity_r = 3'd2;
            batch2_src0_region_size_r = 64'd1048576;
            batch2_src1_region_size_r = 64'd1048576;
            batch2_dst_region_size_r = 64'd1048576;
            batch2_src0_ne0_r = 32'd128; batch2_src0_ne1_r = 32'd128;
            batch2_src0_ne2_r = 32'd16; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd512;
            batch2_src0_nb2_r = 64'd65536; batch2_src0_nb3_r = 64'd1048576;
            batch2_src1_ne0_r = 32'd262144; batch2_src1_ne1_r = 32'd1;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd4; batch2_src1_nb1_r = 64'd1048576;
            batch2_src1_nb2_r = 64'd1048576; batch2_src1_nb3_r = 64'd1048576;
            batch2_dst_ne0_r = 32'd262144; batch2_dst_ne1_r = 32'd1;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd1048576;
            batch2_dst_nb2_r = 64'd1048576; batch2_dst_nb3_r = 64'd1048576;
            batch2_expected_read_bytes_r = 64'd1048576;
            batch2_expected_write_bytes_r = 64'd1048576;
            batch2_expected_work_r = 64'd262144;
            batch2_expected_read_requests_r = 64'd262144;
            batch2_expected_write_requests_r = 64'd262144;
          end
        end
        32'd7: begin
          if (macro_select_set_rows_w && (macro_vector_op_q == 32'd42)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = 8'd7;
            batch2_operation_r = 3'd4;
            batch2_vector_op_r = 32'd42;
            batch2_source_arity_r = 3'd3;
            batch2_src1_dtype_r = MANIFEST_I64;
            batch2_dst_dtype_r = MANIFEST_F16;
            batch2_src1_flags_r = 32'd1;
            batch2_src2_flags_r = MANIFEST_FLAGS;
            batch2_src0_region_size_r = 64'd2048;
            batch2_src1_region_size_r = 64'd4096;
            batch2_dst_region_size_r = 64'd262144;
            batch2_src0_ne0_r = 32'd1; batch2_src0_ne1_r = 32'd512;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd4;
            batch2_src0_nb2_r = 64'd2048; batch2_src0_nb3_r = 64'd2048;
            batch2_src1_ne0_r = 32'd512; batch2_src1_ne1_r = 32'd1;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd8; batch2_src1_nb1_r = 64'd4096;
            batch2_src1_nb2_r = 64'd4096; batch2_src1_nb3_r = 64'd4096;
            batch2_dst_ne0_r = 32'd1; batch2_dst_ne1_r = 32'd131072;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd2; batch2_dst_nb1_r = 64'd2;
            batch2_dst_nb2_r = 64'd262144; batch2_dst_nb3_r = 64'd262144;
            batch2_expected_read_bytes_r = 64'd6144;
            batch2_expected_write_bytes_r = 64'd1024;
            batch2_expected_work_r = 64'd512;
            batch2_expected_read_requests_r = 64'd1024;
            batch2_expected_write_requests_r = 64'd512;
          end
        end
        32'd8: begin
          if (macro_select_set_rows_w && (macro_vector_op_q == 32'd42)) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = 8'd8;
            batch2_operation_r = 3'd3;
            batch2_vector_op_r = 32'd42;
            batch2_source_arity_r = 3'd3;
            batch2_src1_dtype_r = MANIFEST_I64;
            batch2_dst_dtype_r = MANIFEST_F16;
            batch2_src1_flags_r = 32'd1;
            batch2_src2_flags_r = 32'd0;
            batch2_src0_region_size_r = 64'd2048;
            batch2_src1_region_size_r = 64'd8;
            batch2_dst_region_size_r = 64'd262144;
            batch2_src0_ne0_r = 32'd512; batch2_src0_ne1_r = 32'd1;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd2048;
            batch2_src0_nb2_r = 64'd2048; batch2_src0_nb3_r = 64'd2048;
            batch2_src1_ne0_r = 32'd1; batch2_src1_ne1_r = 32'd1;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd8; batch2_src1_nb1_r = 64'd8;
            batch2_src1_nb2_r = 64'd8; batch2_src1_nb3_r = 64'd8;
            batch2_dst_ne0_r = 32'd512; batch2_dst_ne1_r = 32'd256;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd2; batch2_dst_nb1_r = 64'd1024;
            batch2_dst_nb2_r = 64'd262144; batch2_dst_nb3_r = 64'd262144;
            batch2_expected_read_bytes_r = 64'd2056;
            batch2_expected_write_bytes_r = 64'd1024;
            batch2_expected_work_r = 64'd512;
            batch2_expected_read_requests_r = 64'd513;
            batch2_expected_write_requests_r = 64'd512;
          end
        end
        default: begin end
      endcase
    end else if (macro_select_attention_w) begin
      case (macro_vector_flags_q)
        32'd0, 32'd1: begin
          if (macro_vector_op_q == 32'd29) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = macro_vector_flags_q[7:0];
            batch2_vector_op_r = 32'd29;
            batch2_manifest_op_r = MANIFEST_MUL_MAT;
            batch2_source_arity_r = 3'd2;
            batch2_op_params_r = (macro_vector_flags_q == 32'd0) ?
                                 512'd10 : 512'd0;
            batch2_src0_dtype_r = MANIFEST_F16;
            batch2_src0_region_size_r = 64'd262144;
            batch2_src1_region_size_r = 64'd8192;
            batch2_dst_region_size_r = 64'd8192;
            batch2_src0_ne0_r = 32'd256; batch2_src0_ne1_r = 32'd256;
            batch2_src0_ne2_r = 32'd2; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd2;
            batch2_src0_nb1_r = (macro_vector_flags_q == 32'd0) ?
                                64'd1024 : 64'd512;
            batch2_src0_nb2_r = (macro_vector_flags_q == 32'd0) ?
                                64'd512 : 64'd131072;
            batch2_src0_nb3_r = 64'd262144;
            batch2_src1_ne0_r = 32'd256; batch2_src1_ne1_r = 32'd1;
            batch2_src1_ne2_r = 32'd8; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd4;
            batch2_src1_nb1_r = (macro_vector_flags_q == 32'd0) ?
                                64'd8192 : 64'd1024;
            batch2_src1_nb2_r = 64'd1024; batch2_src1_nb3_r = 64'd8192;
            batch2_dst_ne0_r = 32'd256; batch2_dst_ne1_r = 32'd1;
            batch2_dst_ne2_r = 32'd8; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd1024;
            batch2_dst_nb2_r = 64'd1024; batch2_dst_nb3_r = 64'd8192;
            batch2_expected_read_bytes_r = 64'd1056768;
            batch2_expected_write_bytes_r = 64'd8192;
            batch2_expected_work_r = 64'd2048;
            batch2_expected_read_requests_r = 64'd132096;
            batch2_expected_write_requests_r = 64'd2048;
          end
        end
        default: begin end
      endcase
    end else if (macro_select_softmax_w &&
                 (macro_vector_flags_q == 32'd0)) begin
      batch2_profile_valid_r = 1'b1;
      batch2_profile_id_r = 8'd0;
      batch2_vector_op_r = 32'd6;
      batch2_manifest_op_r = MANIFEST_SOFT_MAX;
      batch2_source_arity_r = 3'd2;
      batch2_op_params_r = {384'd0, 96'd0, 32'h3d800000};
      batch2_src1_flags_r = 32'd1;
      batch2_src0_region_size_r = 64'd8192;
      batch2_src1_region_size_r = 64'd1024;
      batch2_dst_region_size_r = 64'd8192;
      batch2_src0_ne0_r = 32'd256; batch2_src0_ne1_r = 32'd1;
      batch2_src0_ne2_r = 32'd8; batch2_src0_ne3_r = 32'd1;
      batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd1024;
      batch2_src0_nb2_r = 64'd1024; batch2_src0_nb3_r = 64'd8192;
      batch2_src1_ne0_r = 32'd256; batch2_src1_ne1_r = 32'd1;
      batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
      batch2_src1_nb0_r = 64'd4; batch2_src1_nb1_r = 64'd1024;
      batch2_src1_nb2_r = 64'd1024; batch2_src1_nb3_r = 64'd1024;
      batch2_dst_ne0_r = 32'd256; batch2_dst_ne1_r = 32'd1;
      batch2_dst_ne2_r = 32'd8; batch2_dst_ne3_r = 32'd1;
      batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd1024;
      batch2_dst_nb2_r = 64'd1024; batch2_dst_nb3_r = 64'd8192;
      batch2_expected_read_bytes_r = 64'd9216;
      batch2_expected_write_bytes_r = 64'd8192;
      batch2_expected_work_r = 64'd2048;
      batch2_expected_read_requests_r = 64'd1152;
      batch2_expected_write_requests_r = 64'd1024;
    end else if (macro_select_rope_w) begin
      case (macro_vector_flags_q)
        32'd0, 32'd1: begin
          if (macro_vector_op_q == 32'd48) begin
            batch2_profile_valid_r = 1'b1;
            batch2_profile_id_r = macro_vector_flags_q[7:0];
            batch2_vector_op_r = 32'd48;
            batch2_manifest_op_r = MANIFEST_ROPE;
            batch2_source_arity_r = 3'd2;
            batch2_op_params_r = ROPE_FROZEN_OP_PARAMS;
            batch2_src1_dtype_r = MANIFEST_I32;
            batch2_src1_flags_r = 32'd1;
            batch2_src0_region_size_r = (macro_vector_flags_q == 32'd0) ?
                                        64'd8192 : 64'd2048;
            batch2_src1_region_size_r = 64'd16;
            batch2_dst_region_size_r = (macro_vector_flags_q == 32'd0) ?
                                       64'd8192 : 64'd2048;
            batch2_src0_ne0_r = 32'd256;
            batch2_src0_ne1_r = (macro_vector_flags_q == 32'd0) ?
                                32'd8 : 32'd2;
            batch2_src0_ne2_r = 32'd1; batch2_src0_ne3_r = 32'd1;
            batch2_src0_nb0_r = 64'd4; batch2_src0_nb1_r = 64'd1024;
            batch2_src0_nb2_r = (macro_vector_flags_q == 32'd0) ?
                                64'd8192 : 64'd2048;
            batch2_src0_nb3_r = batch2_src0_nb2_r;
            batch2_src1_ne0_r = 32'd4; batch2_src1_ne1_r = 32'd1;
            batch2_src1_ne2_r = 32'd1; batch2_src1_ne3_r = 32'd1;
            batch2_src1_nb0_r = 64'd4; batch2_src1_nb1_r = 64'd16;
            batch2_src1_nb2_r = 64'd16; batch2_src1_nb3_r = 64'd16;
            batch2_dst_ne0_r = batch2_src0_ne0_r;
            batch2_dst_ne1_r = batch2_src0_ne1_r;
            batch2_dst_ne2_r = 32'd1; batch2_dst_ne3_r = 32'd1;
            batch2_dst_nb0_r = 64'd4; batch2_dst_nb1_r = 64'd1024;
            batch2_dst_nb2_r = batch2_src0_nb2_r;
            batch2_dst_nb3_r = batch2_src0_nb3_r;
            batch2_expected_read_bytes_r =
                (macro_vector_flags_q == 32'd0) ? 64'd8208 : 64'd2064;
            batch2_expected_write_bytes_r =
                (macro_vector_flags_q == 32'd0) ? 64'd8192 : 64'd2048;
            batch2_expected_work_r =
                (macro_vector_flags_q == 32'd0) ? 64'd2048 : 64'd512;
            batch2_expected_read_requests_r =
                (macro_vector_flags_q == 32'd0) ? 64'd1026 : 64'd258;
            batch2_expected_write_requests_r =
                (macro_vector_flags_q == 32'd0) ? 64'd1280 : 64'd320;
          end
        end
        default: begin end
      endcase
    end
  end

  wire [127:0] batch2_outer_ext_w;
  wire batch2_src1_sentinel_w;
  wire [63:0] batch2_src0_static_span_w;
  wire [63:0] batch2_src1_static_span_w;
  wire [63:0] batch2_dst_static_span_w;
  wire [127:0] batch2_src0_expected_iova_ext_w;
  wire [127:0] batch2_src1_expected_iova_ext_w;
  wire [127:0] batch2_dst_expected_iova_ext_w;
  wire [127:0] batch2_src0_end_ext_w, batch2_src1_end_ext_w;
  wire [127:0] batch2_dst_end_ext_w;
  wire [127:0] batch2_src0_window_end_ext_w;
  wire [127:0] batch2_src1_window_end_ext_w;
  wire [127:0] batch2_dst_window_end_ext_w;
  wire [127:0] batch2_src0_phys_start_ext_w;
  wire [127:0] batch2_src1_phys_start_ext_w;
  wire [127:0] batch2_dst_phys_start_ext_w;
  wire [127:0] batch2_src0_phys_end_ext_w;
  wire [127:0] batch2_src1_phys_end_ext_w;
  wire [127:0] batch2_dst_phys_end_ext_w;
  wire batch2_src0_dst_disjoint_w, batch2_src1_dst_disjoint_w;
  wire batch2_abi_reject_w, batch2_capability_reject_w;
  wire batch2_layout_reject_w, batch2_iova_reject_w;
  wire batch2_static_descriptor_valid_w;
  wire batch2_empty_cpy_w;

  assign batch2_outer_ext_w = {96'd0, batch2_dst_ne1_r} *
                              {96'd0, batch2_dst_ne2_r} *
                              {96'd0, batch2_dst_ne3_r};
  assign batch2_src1_sentinel_w = macro_select_mover_w &&
                                  (batch2_operation_r == 3'd1);
  // The macro tensor IOVAs are semantic addresses (root + view offset),
  // while the frozen region sizes describe the complete root allocation.
  // Bound the semantic IOVA by only the bytes that remain after the view.
  // This also leaves the explicit zero-cardinality profiles at a zero span.
  assign batch2_src0_static_span_w =
      (batch2_src0_region_size_r >= batch2_src0_view_r) ?
          (batch2_src0_region_size_r - batch2_src0_view_r) : 64'd0;
  assign batch2_src1_static_span_w =
      (batch2_src1_region_size_r >= batch2_src1_view_r) ?
          (batch2_src1_region_size_r - batch2_src1_view_r) : 64'd0;
  assign batch2_dst_static_span_w =
      (batch2_dst_region_size_r >= batch2_dst_view_r) ?
          (batch2_dst_region_size_r - batch2_dst_view_r) : 64'd0;
  assign batch2_src0_expected_iova_ext_w =
      {64'd0, macro_src0_window_base_q} +
      {64'd0, batch2_src0_view_r};
  assign batch2_src1_expected_iova_ext_w =
      {64'd0, macro_src1_window_base_q} +
      {64'd0, batch2_src1_view_r};
  assign batch2_dst_expected_iova_ext_w =
      {64'd0, macro_dst_window_base_q} +
      {64'd0, batch2_dst_view_r};
  assign batch2_src0_end_ext_w = {64'd0, macro_src0_iova_q} +
                                 {64'd0, batch2_src0_static_span_w};
  assign batch2_src1_end_ext_w = {64'd0, macro_src1_iova_q} +
                                 {64'd0, batch2_src1_static_span_w};
  assign batch2_dst_end_ext_w = {64'd0, macro_dst_iova_q} +
                                {64'd0, batch2_dst_static_span_w};
  assign batch2_src0_window_end_ext_w =
      {64'd0, macro_src0_window_base_q} +
      {64'd0, macro_src0_window_size_q};
  assign batch2_src1_window_end_ext_w =
      {64'd0, macro_src1_window_base_q} +
      {64'd0, macro_src1_window_size_q};
  assign batch2_dst_window_end_ext_w =
      {64'd0, macro_dst_window_base_q} +
      {64'd0, macro_dst_window_size_q};
  assign batch2_src0_phys_start_ext_w =
      {64'd0, (macro_src0_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign batch2_src1_phys_start_ext_w =
      {64'd0, (macro_src1_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign batch2_dst_phys_start_ext_w =
      {64'd0, (macro_dst_iova_q & 64'hffff_ffff_ffff_fff8)};
  assign batch2_src0_phys_end_ext_w =
      ((batch2_src0_end_ext_w + 128'd7) >> 3) << 3;
  assign batch2_src1_phys_end_ext_w = batch2_src1_sentinel_w ?
      batch2_src1_phys_start_ext_w :
      (((batch2_src1_end_ext_w + 128'd7) >> 3) << 3);
  assign batch2_dst_phys_end_ext_w =
      ((batch2_dst_end_ext_w + 128'd7) >> 3) << 3;
  assign batch2_src0_dst_disjoint_w =
      (batch2_src0_phys_end_ext_w <= batch2_dst_phys_start_ext_w) ||
      (batch2_dst_phys_end_ext_w <= batch2_src0_phys_start_ext_w);
  assign batch2_src1_dst_disjoint_w = batch2_src1_sentinel_w ||
      (batch2_src1_phys_end_ext_w <= batch2_dst_phys_start_ext_w) ||
      (batch2_dst_phys_end_ext_w <= batch2_src1_phys_start_ext_w);

  assign batch2_abi_reject_w = !macro_abi_valid_q;
  assign batch2_capability_reject_w =
      (macro_command_flags_q != COMMAND_FLAGS_REQUIRED_PROFILE) ||
      (macro_context_id_q != CANONICAL_CONTEXT_ID) ||
      (macro_capability_epoch_q != MACRO_CAPABILITY_EPOCH) ||
      (macro_node_count_q != 32'd1) ||
      (macro_deadline_cycles_q != 64'd0);
  assign batch2_layout_reject_w = !batch2_profile_valid_r ||
      (macro_vector_op_q != batch2_vector_op_r) ||
      (macro_vector_flags_q != {24'd0, batch2_profile_id_r}) ||
      (macro_src2_iova_q != (macro_select_set_rows_w ?
                             macro_dst_iova_q : 64'd0)) ||
      (macro_scratch_iova_q != 64'd0) ||
      (macro_element_count_q != {32'd0, batch2_dst_ne0_r}) ||
      (batch2_outer_ext_w[127:32] != 96'd0) ||
      (macro_outer_count_q != batch2_outer_ext_w[31:0]) ||
      (macro_dtype_q != ABI_DTYPE_F32) ||
      (macro_src0_stride_q != batch2_src0_nb1_r) ||
      (macro_src1_stride_q != batch2_src1_nb1_r) ||
      (macro_src2_stride_q != (macro_select_set_rows_w ?
                               batch2_dst_nb1_r : 64'd0)) ||
      (macro_dst_stride_q != batch2_dst_nb1_r) ||
      (macro_scalar0_q != (macro_select_set_rows_w ? 32'd256 :
                           (macro_select_attention_w ?
                            batch2_op_params_r[31:0] :
                            (macro_select_softmax_w ? 32'h3d800000 :
                                                     32'd0)))) ||
      (!macro_select_set_rows_w && (macro_scalar1_q != 32'd0)) ||
      (macro_select_set_rows_w && (macro_scalar1_q >= 32'd256)) ||
      (macro_scratch_bytes_q != 32'd0) ||
      (macro_rope_position_q != 32'd0) ||
      ((macro_node_hash_lo_q == 64'd0) &&
       (macro_node_hash_hi_q == 64'd0));
  assign batch2_iova_reject_w =
      !macro_windows_generation_valid_q ||
      (macro_src0_window_perm_q != 2'b01) ||
      (macro_src1_window_perm_q != 2'b01) ||
      (macro_dst_window_perm_q != 2'b10) ||
      (macro_src0_iova_q[1:0] != 2'b00) ||
      (macro_src1_iova_q[1:0] != 2'b00) ||
      (macro_dst_iova_q[1:0] != 2'b00) ||
      (macro_src0_window_base_q[2:0] != 3'b000) ||
      (macro_src1_window_base_q[2:0] != 3'b000) ||
      (macro_dst_window_base_q[2:0] != 3'b000) ||
      (macro_src0_window_size_q[2:0] != 3'b000) ||
      (macro_src1_window_size_q[2:0] != 3'b000) ||
      (macro_dst_window_size_q[2:0] != 3'b000) ||
      // Public tensor IOVAs are semantic addresses.  Bind each one exactly
      // to its frozen root window plus view offset so the functional owner
      // and legacy child cannot observe different bytes for one admitted
      // command.  Keep the 128-bit overflow checks fail-closed.
      (batch2_src0_expected_iova_ext_w[127:64] != 64'd0) ||
      (macro_src0_iova_q != batch2_src0_expected_iova_ext_w[63:0]) ||
      (batch2_src1_expected_iova_ext_w[127:64] != 64'd0) ||
      (macro_src1_iova_q != batch2_src1_expected_iova_ext_w[63:0]) ||
      (batch2_dst_expected_iova_ext_w[127:64] != 64'd0) ||
      (macro_dst_iova_q != batch2_dst_expected_iova_ext_w[63:0]) ||
      // A zero-cardinality frozen profile owns no bytes.  Its scheduler
      // allocation may therefore be the exact empty window {base, size=0};
      // require a non-empty window only when the resident profile can issue
      // traffic for that operand.  Alignment, overflow, containment and
      // permission checks below remain active for both empty and non-empty
      // windows.
      ((batch2_src0_region_size_r != 64'd0) &&
       (macro_src0_window_size_q == 64'd0)) ||
      (!batch2_src1_sentinel_w &&
       (batch2_src1_region_size_r != 64'd0) &&
       (macro_src1_window_size_q == 64'd0)) ||
      (batch2_src1_sentinel_w &&
       ((macro_src1_window_size_q != 64'd0) ||
        (macro_src1_iova_q != macro_src1_window_base_q))) ||
      ((batch2_dst_region_size_r != 64'd0) &&
       (macro_dst_window_size_q == 64'd0)) ||
      (batch2_src0_end_ext_w[127:64] != 64'd0) ||
      (batch2_src1_end_ext_w[127:64] != 64'd0) ||
      (batch2_dst_end_ext_w[127:64] != 64'd0) ||
      (batch2_src0_window_end_ext_w[127:64] != 64'd0) ||
      (batch2_src1_window_end_ext_w[127:64] != 64'd0) ||
      (batch2_dst_window_end_ext_w[127:64] != 64'd0) ||
      (batch2_src0_phys_start_ext_w <
       {64'd0, macro_src0_window_base_q}) ||
      (batch2_src0_phys_end_ext_w > batch2_src0_window_end_ext_w) ||
      (!batch2_src1_sentinel_w &&
       ((batch2_src1_phys_start_ext_w <
         {64'd0, macro_src1_window_base_q}) ||
        (batch2_src1_phys_end_ext_w > batch2_src1_window_end_ext_w))) ||
      (batch2_dst_phys_start_ext_w <
       {64'd0, macro_dst_window_base_q}) ||
      (batch2_dst_phys_end_ext_w > batch2_dst_window_end_ext_w) ||
      !batch2_src0_dst_disjoint_w || !batch2_src1_dst_disjoint_w;
  assign batch2_static_descriptor_valid_w = !batch2_abi_reject_w &&
      !batch2_capability_reject_w && !batch2_layout_reject_w &&
      !batch2_iova_reject_w;
  assign batch2_empty_cpy_w = macro_select_mover_w &&
      batch2_profile_valid_r &&
      (batch2_operation_r == 3'd0) &&
      (batch2_vector_op_r == 32'd34) &&
      ((batch2_profile_id_r == 8'd3) ||
       (batch2_profile_id_r == 8'd5)) &&
      (batch2_outer_ext_w == 128'd0) &&
      (batch2_src0_region_size_r == 64'd0) &&
      (batch2_src1_region_size_r == 64'd0) &&
      (batch2_dst_region_size_r == 64'd0);

  // ------------------------------------------------------------------------
  // Production-only command-granular functional owner.
  //
  // Admission and every static descriptor rejection remain resident in this
  // Coprocessor.  Only an admitted frozen command can reach the clocked DPI
  // child, and the corresponding legacy adapter is kept silent for the full
  // transaction.  VECTOR_F32 performs its complete finite-profile validation
  // independently in the NPU numerical TU; the other families additionally
  // reuse their existing Coprocessor static preflight here.
  // ------------------------------------------------------------------------
  wire functional_command_compiled_w;
  wire functional_command_supported_w;
  wire functional_command_preflight_valid_w;
  wire functional_command_select_w;
  wire functional_command_start_valid_w;
  wire functional_command_ready_w;
  wire functional_command_busy_w;
  wire functional_command_terminal_valid_w;
  wire functional_command_success_w;
  wire functional_command_error_w;
  wire functional_command_dst_commit_w;
  wire [31:0] functional_command_error_code_w;
  wire [31:0] functional_command_error_class_w;
  wire [31:0] functional_completion_kernel_id_w;
  wire [31:0] functional_completion_command_flags_w;
  wire [31:0] functional_completion_vector_op_w;
  wire [31:0] functional_completion_vector_flags_w;
  wire [31:0] functional_completion_context_id_w;
  wire [31:0] functional_completion_capability_epoch_w;
  wire [31:0] functional_completion_node_count_w;
  wire [63:0] functional_completion_sequence_id_w;
  wire [63:0] functional_completion_producer_id_w;
  wire [63:0] functional_completion_user_tag_w;
  wire [63:0] functional_completion_node_hash_lo_w;
  wire [63:0] functional_completion_node_hash_hi_w;
  wire [63:0] functional_command_read_words_w;
  wire [63:0] functional_command_write_words_w;
  wire [63:0] functional_command_read_bytes_w;
  wire [63:0] functional_command_write_bytes_w;
  wire [63:0] functional_command_q8_blocks_w;
  wire [63:0] functional_command_q8_mac_count_w;
  wire [63:0] functional_command_vector_elements_w;
  wire [31:0] functional_command_callback_errors_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [63:0] functional_command_dispatch_count_w;
  wire [63:0] functional_command_completion_count_w;
  /* verilator lint_on UNUSEDSIGNAL */

  // Independent VECTOR_F32 P00--P18 command contract.  The functional child
  // performs the numerical operation, but it is not allowed to define its own
  // expected work.  This compact table is intentionally resident in the
  // Coprocessor trust boundary and derives raw32 read/write and vector ledgers
  // without consuming any child result.
  reg        functional_vector_profile_valid_r;
  reg        functional_vector_src1_present_r;
  reg [31:0] functional_vector_op_r;
  reg [31:0] functional_vector_scalar0_r;
  reg [63:0] functional_vector_element_count_r;
  reg [31:0] functional_vector_outer_count_r;
  reg [63:0] functional_vector_total_elements_r;
  reg [63:0] functional_vector_src0_stride_r;
  reg [63:0] functional_vector_src1_stride_r;
  reg [63:0] functional_vector_dst_stride_r;
  always @(*) begin
    functional_vector_profile_valid_r = 1'b1;
    functional_vector_src1_present_r = 1'b1;
    functional_vector_op_r = 32'd0;
    functional_vector_scalar0_r = 32'd0;
    functional_vector_element_count_r = 64'd0;
    functional_vector_outer_count_r = 32'd0;
    functional_vector_total_elements_r = 64'd0;
    functional_vector_src0_stride_r = 64'd0;
    functional_vector_src1_stride_r = 64'd0;
    functional_vector_dst_stride_r = 64'd0;
    case (macro_vector_flags_q)
      32'd0: begin
        functional_vector_op_r = 32'd1;
        functional_vector_element_count_r = 64'd16;
        functional_vector_outer_count_r = 32'd1;
        functional_vector_total_elements_r = 64'd16;
        functional_vector_src0_stride_r = 64'd64;
        functional_vector_src1_stride_r = 64'd64;
        functional_vector_dst_stride_r = 64'd64;
      end
      32'd1, 32'd2: begin
        functional_vector_op_r = 32'd1;
        functional_vector_element_count_r = 64'd1024;
        functional_vector_outer_count_r = 32'd1;
        functional_vector_total_elements_r = 64'd1024;
        functional_vector_src0_stride_r = 64'd4096;
        functional_vector_src1_stride_r = 64'd4096;
        functional_vector_dst_stride_r = 64'd4096;
      end
      32'd3: begin
        functional_vector_op_r = 32'd1;
        functional_vector_element_count_r = 64'd128;
        functional_vector_outer_count_r = 32'd2048;
        functional_vector_total_elements_r = 64'd262144;
        functional_vector_src0_stride_r = 64'd512;
        functional_vector_src1_stride_r = 64'd512;
        functional_vector_dst_stride_r = 64'd512;
      end
      32'd4: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd16;
        functional_vector_outer_count_r = 32'd1;
        functional_vector_total_elements_r = 64'd16;
        functional_vector_src0_stride_r = 64'd64;
        functional_vector_src1_stride_r = 64'd64;
        functional_vector_dst_stride_r = 64'd64;
      end
      32'd5: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd1024;
        functional_vector_outer_count_r = 32'd1;
        functional_vector_total_elements_r = 64'd1024;
        functional_vector_src0_stride_r = 64'd4096;
        functional_vector_src1_stride_r = 64'd4096;
        functional_vector_dst_stride_r = 64'd4096;
      end
      32'd6: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd128;
        functional_vector_outer_count_r = 32'd2048;
        functional_vector_total_elements_r = 64'd262144;
        functional_vector_src0_stride_r = 64'd512;
        functional_vector_src1_stride_r = 64'd8192;
        functional_vector_dst_stride_r = 64'd512;
      end
      32'd7: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd128;
        functional_vector_outer_count_r = 32'd16;
        functional_vector_total_elements_r = 64'd2048;
        functional_vector_src0_stride_r = 64'd512;
        functional_vector_src1_stride_r = 64'd4;
        functional_vector_dst_stride_r = 64'd512;
      end
      32'd8, 32'd9: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd128;
        functional_vector_outer_count_r = 32'd2048;
        functional_vector_total_elements_r = 64'd262144;
        functional_vector_src0_stride_r = 64'd512;
        functional_vector_src1_stride_r = 64'd4;
        functional_vector_dst_stride_r = 64'd512;
      end
      32'd10, 32'd11: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd128;
        functional_vector_outer_count_r = 32'd16;
        functional_vector_total_elements_r = 64'd2048;
        functional_vector_src0_stride_r = 64'd512;
        functional_vector_src1_stride_r = 64'd512;
        functional_vector_dst_stride_r = 64'd512;
      end
      32'd12: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd2048;
        functional_vector_outer_count_r = 32'd1;
        functional_vector_total_elements_r = 64'd2048;
        functional_vector_src0_stride_r = 64'd8192;
        functional_vector_src1_stride_r = 64'd8192;
        functional_vector_dst_stride_r = 64'd8192;
      end
      32'd13: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd256;
        functional_vector_outer_count_r = 32'd2;
        functional_vector_total_elements_r = 64'd512;
        functional_vector_src0_stride_r = 64'd1024;
        functional_vector_src1_stride_r = 64'd1024;
        functional_vector_dst_stride_r = 64'd1024;
      end
      32'd14: begin
        functional_vector_op_r = 32'd2;
        functional_vector_element_count_r = 64'd256;
        functional_vector_outer_count_r = 32'd8;
        functional_vector_total_elements_r = 64'd2048;
        functional_vector_src0_stride_r = 64'd1024;
        functional_vector_src1_stride_r = 64'd1024;
        functional_vector_dst_stride_r = 64'd1024;
      end
      32'd15: begin
        functional_vector_op_r = 32'd3;
        functional_vector_element_count_r = 64'd128;
        functional_vector_outer_count_r = 32'd16;
        functional_vector_total_elements_r = 64'd2048;
        functional_vector_src0_stride_r = 64'd24576;
        functional_vector_src1_stride_r = 64'd4;
        functional_vector_dst_stride_r = 64'd512;
      end
      32'd16: begin
        functional_vector_src1_present_r = 1'b0;
        functional_vector_op_r = 32'd4;
        functional_vector_scalar0_r = 32'h3db504f3;
        functional_vector_element_count_r = 64'd128;
        functional_vector_outer_count_r = 32'd16;
        functional_vector_total_elements_r = 64'd2048;
        functional_vector_src0_stride_r = 64'd512;
        functional_vector_dst_stride_r = 64'd512;
      end
      32'd17: begin
        functional_vector_src1_present_r = 1'b0;
        functional_vector_op_r = 32'd4;
        functional_vector_element_count_r = 64'd18432;
        functional_vector_outer_count_r = 32'd1;
        functional_vector_total_elements_r = 64'd18432;
        functional_vector_src0_stride_r = 64'd73728;
        functional_vector_dst_stride_r = 64'd73728;
      end
      32'd18: begin
        functional_vector_src1_present_r = 1'b0;
        functional_vector_op_r = 32'd4;
        functional_vector_element_count_r = 64'd262144;
        functional_vector_outer_count_r = 32'd1;
        functional_vector_total_elements_r = 64'd262144;
        functional_vector_src0_stride_r = 64'd1048576;
        functional_vector_dst_stride_r = 64'd1048576;
      end
      default: functional_vector_profile_valid_r = 1'b0;
    endcase
  end

  wire functional_vector_full_contract_ok_w;
  wire functional_vector_zero_cardinality_w;
  wire functional_vector_contract_ok_w;
  wire [63:0] functional_vector_expected_read_words_w;
  wire [63:0] functional_vector_expected_write_words_w;
  wire [63:0] functional_vector_expected_read_bytes_w;
  wire [63:0] functional_vector_expected_write_bytes_w;
  wire [63:0] functional_vector_expected_elements_w;
  assign functional_vector_expected_read_words_w =
      functional_vector_src1_present_r ?
      (functional_vector_total_elements_r << 1) :
      functional_vector_total_elements_r;
  assign functional_vector_expected_write_words_w =
      functional_vector_total_elements_r;
  assign functional_vector_expected_read_bytes_w =
      functional_vector_expected_read_words_w << 2;
  assign functional_vector_expected_write_bytes_w =
      functional_vector_expected_write_words_w << 2;
  assign functional_vector_expected_elements_w =
      functional_vector_total_elements_r;
  assign functional_vector_full_contract_ok_w =
      functional_vector_profile_valid_r && macro_abi_valid_q &&
      ((macro_command_flags_q == 32'h00000010) ||
       (macro_command_flags_q == COMMAND_FLAGS_REQUIRED_PROFILE)) &&
      (macro_capability_epoch_q == MACRO_CAPABILITY_EPOCH) &&
      (macro_node_count_q == 32'd1) &&
      (macro_deadline_cycles_q == 64'd0) &&
      (macro_vector_op_q == functional_vector_op_r) &&
      (macro_element_count_q == functional_vector_element_count_r) &&
      (macro_outer_count_q == functional_vector_outer_count_r) &&
      (macro_dtype_q == ABI_DTYPE_F32) &&
      (macro_src0_stride_q == functional_vector_src0_stride_r) &&
      (macro_src1_stride_q == functional_vector_src1_stride_r) &&
      (macro_src2_stride_q == 64'd0) &&
      (macro_dst_stride_q == functional_vector_dst_stride_r) &&
      (macro_scalar0_q == functional_vector_scalar0_r) &&
      (macro_scalar1_q == 32'd0) &&
      (macro_src2_iova_q == 64'd0) &&
      (macro_scratch_iova_q == 64'd0) &&
      (macro_scratch_bytes_q == 32'd0) &&
      (macro_rope_position_q == 32'd0) &&
      macro_windows_generation_valid_q &&
      (macro_src0_window_perm_q == 2'b01) &&
      (macro_src1_window_perm_q ==
       (functional_vector_src1_present_r ? 2'b01 : 2'b00)) &&
      (macro_dst_window_perm_q == 2'b10) &&
      (macro_src0_iova_q != 64'd0) &&
      (macro_src0_window_size_q != 64'd0) &&
      (macro_dst_iova_q == macro_dst_window_base_q) &&
      (macro_dst_window_size_q ==
       functional_vector_expected_write_bytes_w) &&
      (macro_src0_iova_q[1:0] == 2'b00) &&
      (macro_dst_iova_q[2:0] == 3'b000) &&
      (functional_vector_src1_present_r ?
       ((macro_src1_iova_q != 64'd0) &&
        (macro_src1_iova_q == macro_src1_window_base_q) &&
        (macro_src1_window_size_q != 64'd0) &&
        (macro_src1_iova_q[1:0] == 2'b00)) :
       ((macro_src1_iova_q == 64'd0) &&
        (macro_src1_window_base_q == 64'd0) &&
        (macro_src1_window_size_q == 64'd0)));

  // Dispatches after the bootstrap token expose the recurrent cache_r/cache_s
  // SCALE nodes as canonical zero-cardinality tensors.  Only the two frozen
  // cache profiles may use this form.  It remains a real REQUIRED transaction
  // with a public SUCCESS completion, but owns no numerical child or memory
  // traffic.  Keep this predicate deliberately complete so a malformed empty
  // descriptor falls through to the normal adapter and fails closed.
  assign functional_vector_zero_cardinality_w =
      macro_select_vector_w && macro_abi_valid_q &&
      ((macro_vector_flags_q == 32'd17) ||
       (macro_vector_flags_q == 32'd18)) &&
      (macro_command_flags_q == COMMAND_FLAGS_REQUIRED_PROFILE) &&
      (macro_capability_epoch_q == MACRO_CAPABILITY_EPOCH) &&
      (macro_node_count_q == 32'd1) &&
      (macro_deadline_cycles_q == 64'd0) &&
      (macro_vector_op_q == 32'd4) &&
      (macro_element_count_q == 64'd0) &&
      (macro_outer_count_q == 32'd1) &&
      (macro_dtype_q == ABI_DTYPE_F32) &&
      (macro_src0_stride_q == 64'd0) &&
      (macro_src1_stride_q == 64'd0) &&
      (macro_src2_stride_q == 64'd0) &&
      (macro_dst_stride_q == 64'd0) &&
      (macro_scalar0_q == 32'd0) &&
      (macro_scalar1_q == 32'd0) &&
      (macro_src1_iova_q == 64'd0) &&
      (macro_src2_iova_q == 64'd0) &&
      (macro_scratch_iova_q == 64'd0) &&
      (macro_scratch_bytes_q == 32'd0) &&
      (macro_rope_position_q == 32'd0) &&
      macro_windows_generation_valid_q &&
      (macro_src0_window_perm_q == 2'b01) &&
      (macro_src1_window_perm_q == 2'b00) &&
      (macro_dst_window_perm_q == 2'b10) &&
      (macro_src0_iova_q != 64'd0) &&
      (macro_src0_iova_q == macro_src0_window_base_q) &&
      (macro_src0_window_size_q == 64'd0) &&
      (macro_src0_iova_q[2:0] == 3'b000) &&
      (macro_src1_window_base_q == 64'd0) &&
      (macro_src1_window_size_q == 64'd0) &&
      (macro_dst_iova_q != 64'd0) &&
      (macro_dst_iova_q == macro_dst_window_base_q) &&
      (macro_dst_window_size_q == 64'd0) &&
      (macro_dst_iova_q[2:0] == 3'b000);
  assign functional_vector_contract_ok_w =
      functional_vector_full_contract_ok_w ||
      functional_vector_zero_cardinality_w;

`ifdef NPU_FUNCTIONAL_COMMAND_DPI
  assign functional_command_compiled_w = 1'b1;
`else
  assign functional_command_compiled_w = 1'b0;
`endif
  assign functional_command_supported_w =
      macro_select_vector_w || macro_select_q8_w || macro_select_gemv_w ||
      macro_select_f32_move_w || macro_select_mover_set_w;
  assign functional_command_preflight_valid_w = macro_select_vector_w ?
      functional_vector_contract_ok_w :
      (macro_select_q8_w ? q8_static_descriptor_valid_w :
       (macro_select_gemv_w ? gemv_static_descriptor_valid_w :
        (macro_select_f32_move_w ? f32_move_static_descriptor_valid_w :
         (macro_select_mover_set_w ? batch2_static_descriptor_valid_w :
          1'b0))));
  assign functional_command_select_w = functional_command_compiled_w &&
      (COMMAND_FUNCTIONAL_ENABLE != 0) &&
      functional_command_supported_w &&
      functional_command_preflight_valid_w &&
      !functional_vector_zero_cardinality_w;
  assign functional_command_start_valid_w =
      (state_q == ST_MACRO_START) && functional_command_select_w &&
      !gemv_empty_w;

`ifdef NPU_FUNCTIONAL_COMMAND_DPI
  TensorNpuFunctionalCommandDpi u_functional_command (
    .clk_i(clk),
    .rst_i(rst),
    .enable_i(COMMAND_FUNCTIONAL_ENABLE != 0),
    .command_valid_i(functional_command_start_valid_w),
    .command_ready_o(functional_command_ready_w),
    .busy_o(functional_command_busy_w),
    .command_abi_valid_i(macro_abi_valid_q),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .kernel_id_i(macro_kernel_id_q),
    .command_flags_i(macro_command_flags_q),
    .vector_op_i(macro_vector_op_q),
    .vector_flags_i(macro_vector_flags_q),
    .context_id_i(macro_context_id_q),
    .capability_epoch_i(macro_capability_epoch_q),
    .node_count_i(macro_node_count_q),
    .sequence_id_i(macro_sequence_id_q),
    .producer_id_i(macro_producer_id_q),
    .user_tag_i(macro_user_tag_q),
    .node_hash_lo_i(macro_node_hash_lo_q),
    .node_hash_hi_i(macro_node_hash_hi_q),
    .deadline_cycles_i(macro_deadline_cycles_q),
    .src0_iova_i(macro_src0_iova_q),
    .src1_iova_i(macro_src1_iova_q),
    .src2_iova_i(macro_src2_iova_q),
    .dst_iova_i(macro_dst_iova_q),
    .scratch_iova_i(macro_scratch_iova_q),
    .element_count_i(macro_element_count_q),
    .outer_count_i(macro_outer_count_q),
    .dtype_i(macro_dtype_q),
    .src0_stride_i(macro_src0_stride_q),
    .src1_stride_i(macro_src1_stride_q),
    .src2_stride_i(macro_src2_stride_q),
    .dst_stride_i(macro_dst_stride_q),
    .scalar0_i(macro_scalar0_q),
    .scalar1_i(macro_scalar1_q),
    .scratch_bytes_i(macro_scratch_bytes_q),
    .rope_position_i(macro_rope_position_q),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_size_i(macro_src0_window_size_q),
    .src0_window_perm_i({30'd0, macro_src0_window_perm_q}),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_size_i(macro_src1_window_size_q),
    .src1_window_perm_i({30'd0, macro_src1_window_perm_q}),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_size_i(macro_dst_window_size_q),
    .dst_window_perm_i({30'd0, macro_dst_window_perm_q}),
    .terminal_valid_o(functional_command_terminal_valid_w),
    .terminal_success_o(functional_command_success_w),
    .terminal_error_o(functional_command_error_w),
    .terminal_error_code_o(functional_command_error_code_w),
    .terminal_error_class_o(functional_command_error_class_w),
    .dst_commit_o(functional_command_dst_commit_w),
    .completion_kernel_id_o(functional_completion_kernel_id_w),
    .completion_command_flags_o(functional_completion_command_flags_w),
    .completion_vector_op_o(functional_completion_vector_op_w),
    .completion_vector_flags_o(functional_completion_vector_flags_w),
    .completion_context_id_o(functional_completion_context_id_w),
    .completion_capability_epoch_o(
        functional_completion_capability_epoch_w),
    .completion_node_count_o(functional_completion_node_count_w),
    .completion_sequence_id_o(functional_completion_sequence_id_w),
    .completion_producer_id_o(functional_completion_producer_id_w),
    .completion_user_tag_o(functional_completion_user_tag_w),
    .completion_node_hash_lo_o(functional_completion_node_hash_lo_w),
    .completion_node_hash_hi_o(functional_completion_node_hash_hi_w),
    .terminal_read_words_o(functional_command_read_words_w),
    .terminal_write_words_o(functional_command_write_words_w),
    .terminal_read_bytes_o(functional_command_read_bytes_w),
    .terminal_write_bytes_o(functional_command_write_bytes_w),
    .terminal_q8_blocks_o(functional_command_q8_blocks_w),
    .terminal_q8_mac_count_o(functional_command_q8_mac_count_w),
    .terminal_vector_elements_o(functional_command_vector_elements_w),
    .terminal_callback_errors_o(functional_command_callback_errors_w),
    .dispatch_count_o(functional_command_dispatch_count_w),
    .completion_count_o(functional_command_completion_count_w)
  );
`else
  assign functional_command_ready_w = 1'b0;
  assign functional_command_busy_w = 1'b0;
  assign functional_command_terminal_valid_w = 1'b0;
  assign functional_command_success_w = 1'b0;
  assign functional_command_error_w = 1'b0;
  assign functional_command_dst_commit_w = 1'b0;
  assign functional_command_error_code_w = 32'd0;
  assign functional_command_error_class_w = 32'd0;
  assign functional_completion_kernel_id_w = 32'd0;
  assign functional_completion_command_flags_w = 32'd0;
  assign functional_completion_vector_op_w = 32'd0;
  assign functional_completion_vector_flags_w = 32'd0;
  assign functional_completion_context_id_w = 32'd0;
  assign functional_completion_capability_epoch_w = 32'd0;
  assign functional_completion_node_count_w = 32'd0;
  assign functional_completion_sequence_id_w = 64'd0;
  assign functional_completion_producer_id_w = 64'd0;
  assign functional_completion_user_tag_w = 64'd0;
  assign functional_completion_node_hash_lo_w = 64'd0;
  assign functional_completion_node_hash_hi_w = 64'd0;
  assign functional_command_read_words_w = 64'd0;
  assign functional_command_write_words_w = 64'd0;
  assign functional_command_read_bytes_w = 64'd0;
  assign functional_command_write_bytes_w = 64'd0;
  assign functional_command_q8_blocks_w = 64'd0;
  assign functional_command_q8_mac_count_w = 64'd0;
  assign functional_command_vector_elements_w = 64'd0;
  assign functional_command_callback_errors_w = 32'd0;
  assign functional_command_dispatch_count_w = 64'd0;
  assign functional_command_completion_count_w = 64'd0;
`endif

  // The DPI child has a 32-bit private contract status space, whereas the
  // public NPU completion ABI has an 8-bit error code.  Map every supported
  // terminal explicitly; never truncate a private code into an unrelated
  // public error.  Callback failures are capability/IOVA failures, while
  // malformed status framing and ledger closure are protocol failures.
  reg [`NPU_ERROR_W-1:0] functional_mapped_error_code_r;
  reg [31:0] functional_mapped_error_class_r;
  always @(*) begin
    functional_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
    functional_mapped_error_class_r = ABI_ERROR_PROTOCOL;
    case (functional_command_error_code_w)
      32'd13: begin
        functional_mapped_error_code_r = `NPU_ERR_MACRO_ABI;
        functional_mapped_error_class_r = ABI_ERROR_ABI;
      end
      32'd14: begin
        functional_mapped_error_code_r = `NPU_ERR_MACRO_CAPABILITY;
        functional_mapped_error_class_r = ABI_ERROR_CAPABILITY;
      end
      32'd15: begin
        functional_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
        functional_mapped_error_class_r = ABI_ERROR_LAYOUT;
      end
      32'd16, 32'h0000f003: begin
        functional_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
        functional_mapped_error_class_r = ABI_ERROR_IOVA;
      end
      32'd17: begin
        functional_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
        functional_mapped_error_class_r = ABI_ERROR_TIMEOUT;
      end
      32'd18, 32'h0000f001, 32'h0000f002: begin
        functional_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
        functional_mapped_error_class_r = ABI_ERROR_PROTOCOL;
      end
      default: begin
        functional_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
        functional_mapped_error_class_r = ABI_ERROR_PROTOCOL;
      end
    endcase
  end

  wire functional_command_exact_once_ok_w;
  assign functional_command_exact_once_ok_w =
      (functional_dispatch_baseline_q ==
       functional_completion_baseline_q) &&
      (functional_dispatch_baseline_q != 64'hffff_ffff_ffff_ffff) &&
      (functional_command_dispatch_count_w ==
       (functional_dispatch_baseline_q + 64'd1)) &&
      (functional_command_completion_count_w ==
       (functional_completion_baseline_q + 64'd1)) &&
      (functional_command_dispatch_count_w ==
       functional_command_completion_count_w);

  wire [63:0] q8_source_index_floor_w;
  wire [63:0] q8_gmem_floor_w;
  wire [63:0] q8_source_index_limit_w;
  wire [63:0] q8_gmem_limit_w;
  assign q8_source_index_floor_w =
      (macro_src0_window_base_q < macro_src1_window_base_q) ?
      macro_src0_window_base_q : macro_src1_window_base_q;
  assign q8_gmem_floor_w =
      (q8_source_index_floor_w < macro_dst_window_base_q) ?
      q8_source_index_floor_w : macro_dst_window_base_q;
  assign q8_source_index_limit_w =
      (q8_src0_window_end_ext_w[63:0] >
       q8_src1_window_end_ext_w[63:0]) ?
      q8_src0_window_end_ext_w[63:0] : q8_src1_window_end_ext_w[63:0];
  assign q8_gmem_limit_w =
      (q8_source_index_limit_w > q8_dst_window_end_ext_w[63:0]) ?
      q8_source_index_limit_w : q8_dst_window_end_ext_w[63:0];

  wire macro_adapter_start_valid_w;
  wire macro_adapter_start_ready_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire macro_adapter_busy_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire macro_adapter_done_w;
  wire macro_adapter_error_w;
  wire [`NPU_ERROR_W-1:0] macro_adapter_error_code_w;
  wire [31:0] macro_adapter_error_class_w;
  wire [63:0] macro_adapter_read_bytes_w;
  wire [63:0] macro_adapter_write_bytes_w;
  wire [63:0] macro_adapter_vector_elements_w;
  wire [63:0] macro_adapter_expected_read_bytes_w;
  wire [63:0] macro_adapter_expected_write_bytes_w;
  wire [63:0] macro_adapter_expected_vector_elements_w;
  wire macro_adapter_gmem_outstanding_w;
  wire macro_adapter_f32_start_pulse_w;
  wire macro_gmem_req_valid_w;
  wire macro_gmem_req_ready_w;
  wire macro_gmem_req_write_w;
  wire [63:0] macro_gmem_req_addr_w;
  wire [63:0] macro_gmem_req_wdata_w;
  wire [7:0] macro_gmem_req_wstrb_w;
  wire macro_gmem_rsp_valid_w;
  wire macro_gmem_rsp_ready_w;
  wire [63:0] macro_gmem_rsp_rdata_w;
  wire macro_gmem_rsp_error_w;

  assign macro_adapter_start_valid_w = (state_q == ST_MACRO_START) &&
                                       macro_select_vector_w &&
                                       !functional_command_select_w &&
                                       !functional_vector_zero_cardinality_w;

  generate
    if (F32_ALU_PORTAL_ENABLE != 0) begin : gen_f32_alu_portal
      assign macro_gmem_req_valid_w = 1'b0;
      assign macro_gmem_req_write_w = 1'b0;
      assign macro_gmem_req_addr_w = 64'b0;
      assign macro_gmem_req_wdata_w = 64'b0;
      assign macro_gmem_req_wstrb_w = 8'b0;
      assign macro_gmem_rsp_ready_w = 1'b0;

      TensorNpuF32AluPortalAdapter #(
        .LANES(F32_ALU_PORTAL_LANES),
        .MACRO_CAPABILITY_EPOCH(MACRO_CAPABILITY_EPOCH)
      ) u_vector_f32_portal_adapter (
        .clk_i(clk),
        .rst_i(rst),
        .start_valid_i(macro_adapter_start_valid_w),
        .start_ready_o(macro_adapter_start_ready_w),
        .busy_o(macro_adapter_busy_w),
        .abi_valid_i(macro_abi_valid_q),
        .kernel_id_i(macro_kernel_id_q),
        .command_flags_i(macro_command_flags_q),
        .capability_epoch_i(macro_capability_epoch_q),
        .node_count_i(macro_node_count_q),
        .deadline_cycles_i(macro_deadline_cycles_q),
        .vector_op_i(macro_vector_op_q),
        .vector_flags_i(macro_vector_flags_q),
        .src0_iova_i(macro_src0_iova_q),
        .src1_iova_i(macro_src1_iova_q),
        .src2_iova_i(macro_src2_iova_q),
        .dst_iova_i(macro_dst_iova_q),
        .scratch_iova_i(macro_scratch_iova_q),
        .element_count_i(macro_element_count_q),
        .outer_count_i(macro_outer_count_q),
        .dtype_i(macro_dtype_q),
        .src0_stride_i(macro_src0_stride_q),
        .src1_stride_i(macro_src1_stride_q),
        .src2_stride_i(macro_src2_stride_q),
        .dst_stride_i(macro_dst_stride_q),
        .scalar0_i(macro_scalar0_q),
        .scalar1_i(macro_scalar1_q),
        .scratch_bytes_i(macro_scratch_bytes_q),
        .rope_position_i(macro_rope_position_q),
        .src0_window_base_i(macro_src0_window_base_q),
        .src0_window_size_i(macro_src0_window_size_q),
        .src0_window_perm_i(macro_src0_window_perm_q),
        .src1_window_base_i(macro_src1_window_base_q),
        .src1_window_size_i(macro_src1_window_size_q),
        .src1_window_perm_i(macro_src1_window_perm_q),
        .dst_window_base_i(macro_dst_window_base_q),
        .dst_window_size_i(macro_dst_window_size_q),
        .dst_window_perm_i(macro_dst_window_perm_q),
        .windows_generation_valid_i(macro_windows_generation_valid_q),
        .req_valid_o(f32_alu_portal_req_valid_o),
        .req_ready_i(f32_alu_portal_req_ready_i),
        .req_write_o(f32_alu_portal_req_write_o),
        .req_mask_o(f32_alu_portal_req_mask_o),
        .req_src0_addr_o(f32_alu_portal_req_src0_addr_o),
        .req_src1_addr_o(f32_alu_portal_req_src1_addr_o),
        .req_dst_addr_o(f32_alu_portal_req_dst_addr_o),
        .req_wdata_o(f32_alu_portal_req_wdata_o),
        .rsp_valid_i(f32_alu_portal_rsp_valid_i),
        .rsp_ready_o(f32_alu_portal_rsp_ready_o),
        .rsp_mask_i(f32_alu_portal_rsp_mask_i),
        .rsp_src0_data_i(f32_alu_portal_rsp_src0_data_i),
        .rsp_src1_data_i(f32_alu_portal_rsp_src1_data_i),
        .rsp_error_i(f32_alu_portal_rsp_error_i),
        .done_o(macro_adapter_done_w),
        .error_o(macro_adapter_error_w),
        .error_code_o(macro_adapter_error_code_w),
        .error_class_o(macro_adapter_error_class_w),
        .gmem_read_bytes_o(macro_adapter_read_bytes_w),
        .gmem_write_bytes_o(macro_adapter_write_bytes_w),
        .vector_elements_o(macro_adapter_vector_elements_w),
        .expected_gmem_read_bytes_o(macro_adapter_expected_read_bytes_w),
        .expected_gmem_write_bytes_o(macro_adapter_expected_write_bytes_w),
        .expected_vector_elements_o(
            macro_adapter_expected_vector_elements_w),
        .gmem_outstanding_o(macro_adapter_gmem_outstanding_w),
        .f32_start_pulse_o(macro_adapter_f32_start_pulse_w),
        .portal_request_groups_o(f32_alu_portal_request_groups_o),
        .portal_response_groups_o(f32_alu_portal_response_groups_o),
        .portal_read_groups_o(f32_alu_portal_read_groups_o),
        .portal_write_groups_o(f32_alu_portal_write_groups_o),
        .input_words_o(f32_alu_portal_input_words_o),
        .output_words_o(f32_alu_portal_output_words_o),
        .read_bytes_o(f32_alu_portal_read_bytes_o),
        .write_bytes_o(f32_alu_portal_write_bytes_o),
        .portal_outstanding_o(f32_alu_portal_outstanding_o)
      );
    end else begin : gen_f32_alu_legacy_gmem
      assign f32_alu_portal_req_valid_o = 1'b0;
      assign f32_alu_portal_req_write_o = 1'b0;
      assign f32_alu_portal_req_mask_o =
          {F32_ALU_PORTAL_LANES{1'b0}};
      assign f32_alu_portal_req_src0_addr_o =
          {(F32_ALU_PORTAL_LANES*64){1'b0}};
      assign f32_alu_portal_req_src1_addr_o =
          {(F32_ALU_PORTAL_LANES*64){1'b0}};
      assign f32_alu_portal_req_dst_addr_o =
          {(F32_ALU_PORTAL_LANES*64){1'b0}};
      assign f32_alu_portal_req_wdata_o =
          {(F32_ALU_PORTAL_LANES*32){1'b0}};
      assign f32_alu_portal_rsp_ready_o = 1'b0;
      assign f32_alu_portal_request_groups_o = 64'b0;
      assign f32_alu_portal_response_groups_o = 64'b0;
      assign f32_alu_portal_read_groups_o = 64'b0;
      assign f32_alu_portal_write_groups_o = 64'b0;
      assign f32_alu_portal_input_words_o = 64'b0;
      assign f32_alu_portal_output_words_o = 64'b0;
      assign f32_alu_portal_read_bytes_o = 64'b0;
      assign f32_alu_portal_write_bytes_o = 64'b0;
      assign f32_alu_portal_outstanding_o = 1'b0;

      TensorNpuVectorF32Adapter #(
        .MACRO_CAPABILITY_EPOCH(MACRO_CAPABILITY_EPOCH)
      ) u_vector_f32_adapter (
        .clk_i(clk),
        .rst_i(rst),
        .start_valid_i(macro_adapter_start_valid_w),
        .start_ready_o(macro_adapter_start_ready_w),
        .busy_o(macro_adapter_busy_w),
        .abi_valid_i(macro_abi_valid_q),
        .kernel_id_i(macro_kernel_id_q),
        .command_flags_i(macro_command_flags_q),
        .capability_epoch_i(macro_capability_epoch_q),
        .node_count_i(macro_node_count_q),
        .deadline_cycles_i(macro_deadline_cycles_q),
        .vector_op_i(macro_vector_op_q),
        .vector_flags_i(macro_vector_flags_q),
        .src0_iova_i(macro_src0_iova_q),
        .src1_iova_i(macro_src1_iova_q),
        .src2_iova_i(macro_src2_iova_q),
        .dst_iova_i(macro_dst_iova_q),
        .scratch_iova_i(macro_scratch_iova_q),
        .element_count_i(macro_element_count_q),
        .outer_count_i(macro_outer_count_q),
        .dtype_i(macro_dtype_q),
        .src0_stride_i(macro_src0_stride_q),
        .src1_stride_i(macro_src1_stride_q),
        .src2_stride_i(macro_src2_stride_q),
        .dst_stride_i(macro_dst_stride_q),
        .scalar0_i(macro_scalar0_q),
        .scalar1_i(macro_scalar1_q),
        .scratch_bytes_i(macro_scratch_bytes_q),
        .rope_position_i(macro_rope_position_q),
        .src0_window_base_i(macro_src0_window_base_q),
        .src0_window_size_i(macro_src0_window_size_q),
        .src0_window_perm_i(macro_src0_window_perm_q),
        .src1_window_base_i(macro_src1_window_base_q),
        .src1_window_size_i(macro_src1_window_size_q),
        .src1_window_perm_i(macro_src1_window_perm_q),
        .dst_window_base_i(macro_dst_window_base_q),
        .dst_window_size_i(macro_dst_window_size_q),
        .dst_window_perm_i(macro_dst_window_perm_q),
        .windows_generation_valid_i(macro_windows_generation_valid_q),
        .gmem_req_valid_o(macro_gmem_req_valid_w),
        .gmem_req_ready_i(macro_gmem_req_ready_w),
        .gmem_req_write_o(macro_gmem_req_write_w),
        .gmem_req_addr_o(macro_gmem_req_addr_w),
        .gmem_req_wdata_o(macro_gmem_req_wdata_w),
        .gmem_req_wstrb_o(macro_gmem_req_wstrb_w),
        .gmem_rsp_valid_i(macro_gmem_rsp_valid_w),
        .gmem_rsp_ready_o(macro_gmem_rsp_ready_w),
        .gmem_rsp_rdata_i(macro_gmem_rsp_rdata_w),
        .gmem_rsp_error_i(macro_gmem_rsp_error_w),
        .done_o(macro_adapter_done_w),
        .error_o(macro_adapter_error_w),
        .error_code_o(macro_adapter_error_code_w),
        .error_class_o(macro_adapter_error_class_w),
        .gmem_read_bytes_o(macro_adapter_read_bytes_w),
        .gmem_write_bytes_o(macro_adapter_write_bytes_w),
        .vector_elements_o(macro_adapter_vector_elements_w),
        .expected_gmem_read_bytes_o(macro_adapter_expected_read_bytes_w),
        .expected_gmem_write_bytes_o(macro_adapter_expected_write_bytes_w),
        .expected_vector_elements_o(
            macro_adapter_expected_vector_elements_w),
        .gmem_outstanding_o(macro_adapter_gmem_outstanding_w),
        .f32_start_pulse_o(macro_adapter_f32_start_pulse_w)
      );
    end
  endgenerate

  wire q8_adapter_start_w;
  wire q8_adapter_ready_w;
  wire q8_adapter_busy_w;
  wire q8_adapter_completion_valid_w;
  wire q8_adapter_dst_commit_w;
  wire [63:0] q8_adapter_completion_command_id_w;
  wire [31:0] q8_adapter_completion_kernel_id_w;
  wire q8_adapter_done_w;
  wire q8_adapter_error_w;
  wire [4:0] q8_adapter_error_code_w;
  wire [4:0] q8_adapter_engine_error_code_w;
  wire [31:0] q8_adapter_ids_scanned_w;
  wire [31:0] q8_adapter_blocks_done_w;
  wire [31:0] q8_adapter_outputs_accepted_w;
  wire [31:0] q8_adapter_gmem_read_beats_w;
  wire [31:0] q8_adapter_read_payload_bytes_w;
  wire [31:0] q8_adapter_gmem_write_beats_w;
  wire [31:0] q8_adapter_writes_completed_w;
  wire [31:0] q8_adapter_write_bytes_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [31:0] q8_adapter_engine_active_cycles_w;
  wire [63:0] q8_adapter_active_cycles_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire q8_adapter_gmem_outstanding_w;
  wire q8_gmem_req_valid_w;
  wire q8_gmem_req_ready_w;
  wire q8_gmem_req_write_w;
  wire [63:0] q8_gmem_req_addr_w;
  wire [63:0] q8_gmem_req_wdata_w;
  wire [7:0] q8_gmem_req_wstrb_w;
  wire q8_gmem_rsp_valid_w;
  wire q8_gmem_rsp_ready_w;
  wire [63:0] q8_gmem_rsp_rdata_w;
  wire q8_gmem_rsp_error_w;

  assign q8_adapter_start_w = (state_q == ST_MACRO_START) &&
                              macro_select_q8_w &&
                              q8_static_descriptor_valid_w &&
                              !functional_command_select_w;

  TensorNpuQ8GetRowsWritebackAdapter #(
    .MAX_D(Q8_MAX_D),
    .MAX_IDS(Q8_MAX_IDS)
  ) u_q8_get_rows_writeback_adapter (
    .clk_i(clk),
    .rst_i(rst),
    .start_i(q8_adapter_start_w),
    .ready_o(q8_adapter_ready_w),
    .busy_o(q8_adapter_busy_w),
    .command_id_i(macro_sequence_id_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .src_slice_base_i(macro_src0_iova_q),
    .idx_slice_base_i(macro_src1_iova_q),
    .dst_slice_base_i(macro_dst_iova_q),
    .dst_window_bytes_i(q8_dst_end_ext_w[63:0] - macro_dst_iova_q),
    .gmem_floor_i(q8_gmem_floor_w),
    .gmem_limit_i(q8_gmem_limit_w),
    .source_row_count_i(macro_scalar0_q),
    .index_count_i(macro_outer_count_q[Q8_ID_W-1:0]),
    .element_count_i(macro_element_count_q[Q8_D_W-1:0]),
    .src_row_stride_i(macro_src0_stride_q),
    .idx_stride_i(macro_src1_stride_q),
    .dst_row_stride_i(macro_dst_stride_q),
    .gmem_req_valid_o(q8_gmem_req_valid_w),
    .gmem_req_ready_i(q8_gmem_req_ready_w),
    .gmem_req_write_o(q8_gmem_req_write_w),
    .gmem_req_addr_o(q8_gmem_req_addr_w),
    .gmem_req_wdata_o(q8_gmem_req_wdata_w),
    .gmem_req_wstrb_o(q8_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(q8_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(q8_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(q8_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(q8_gmem_rsp_error_w),
    .completion_valid_o(q8_adapter_completion_valid_w),
    .dst_commit_o(q8_adapter_dst_commit_w),
    .completion_command_id_o(q8_adapter_completion_command_id_w),
    .completion_kernel_id_o(q8_adapter_completion_kernel_id_w),
    .done_o(q8_adapter_done_w),
    .error_o(q8_adapter_error_w),
    .error_code_o(q8_adapter_error_code_w),
    .engine_error_code_o(q8_adapter_engine_error_code_w),
    .ids_scanned_o(q8_adapter_ids_scanned_w),
    .blocks_done_o(q8_adapter_blocks_done_w),
    .outputs_accepted_o(q8_adapter_outputs_accepted_w),
    .gmem_read_beats_o(q8_adapter_gmem_read_beats_w),
    .read_payload_bytes_o(q8_adapter_read_payload_bytes_w),
    .gmem_write_beats_o(q8_adapter_gmem_write_beats_w),
    .writes_completed_o(q8_adapter_writes_completed_w),
    .write_bytes_o(q8_adapter_write_bytes_w),
    .engine_active_cycles_o(q8_adapter_engine_active_cycles_w),
    .active_cycles_o(q8_adapter_active_cycles_w),
    .gmem_outstanding_o(q8_adapter_gmem_outstanding_w)
  );

  wire gemv_adapter_start_w;
  wire gemv_adapter_ready_w;
  wire gemv_adapter_busy_w;
  wire gemv_adapter_completion_valid_w;
  wire gemv_adapter_dst_commit_w;
  wire [63:0] gemv_adapter_completion_command_id_w;
  wire [31:0] gemv_adapter_completion_kernel_id_w;
  wire [31:0] gemv_adapter_completion_row_count_w;
  wire [31:0] gemv_adapter_completion_block_count_w;
  wire gemv_adapter_done_w;
  wire gemv_adapter_error_w;
  wire [4:0] gemv_adapter_error_code_w;
  wire [7:0] gemv_adapter_child_error_code_w;
  wire [31:0] gemv_adapter_activation_words_w;
  wire [63:0] gemv_adapter_weight_blocks_w;
  wire [31:0] gemv_adapter_rows_written_w;
  wire [63:0] gemv_adapter_gmem_read_beats_w;
  wire [63:0] gemv_adapter_gmem_read_beats_completed_w;
  wire [63:0] gemv_adapter_gmem_read_bytes_w;
  wire [63:0] gemv_adapter_raw_gmem_read_bytes_w;
  wire [63:0] gemv_adapter_activation_payload_bytes_w;
  wire [63:0] gemv_adapter_weight_payload_bytes_w;
  wire [31:0] gemv_adapter_gmem_write_beats_w;
  wire [31:0] gemv_adapter_writes_completed_w;
  wire [63:0] gemv_adapter_write_bytes_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [63:0] gemv_adapter_child_active_cycles_w;
  wire [63:0] gemv_adapter_active_cycles_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire gemv_adapter_gmem_outstanding_w;
  wire gemv_adapter_raw_gmem_outstanding_w;
  wire gemv_gmem_req_valid_w;
  wire gemv_gmem_req_ready_w;
  wire gemv_gmem_req_write_w;
  wire [63:0] gemv_gmem_req_addr_w;
  wire [63:0] gemv_gmem_req_wdata_w;
  wire [7:0] gemv_gmem_req_wstrb_w;
  wire gemv_gmem_rsp_valid_w;
  wire gemv_gmem_rsp_ready_w;
  wire [63:0] gemv_gmem_rsp_rdata_w;
  wire gemv_gmem_rsp_error_w;

  assign gemv_adapter_start_w = (state_q == ST_MACRO_START) &&
                                macro_select_gemv_w &&
                                !gemv_empty_w &&
                                gemv_static_descriptor_valid_w &&
                                !functional_command_select_w;

  // completion_macro_gmem_read_bytes retains its literal raw-GMEM meaning.
  // Portal payload has a separate exact 34-byte ledger, avoiding mixed
  // physical/semantic byte accounting.  Outstanding ownership still covers
  // both transports, so a portal response can never be hidden by an idle raw
  // channel at macro terminal.
  assign gemv_adapter_gmem_read_bytes_w =
      gemv_adapter_raw_gmem_read_bytes_w;
  assign gemv_adapter_gmem_outstanding_w =
      gemv_adapter_raw_gmem_outstanding_w | q8_portal_outstanding_o;

  generate
    if (Q8_GEMV_PORTAL_ENABLE != 0) begin : gen_q8_gemv_portal
      TensorNpuQ8GemvPortalAdapter #(
        .MAX_ROWS(GEMV_MAX_ROWS),
        .MAX_BLOCKS(GEMV_MAX_BLOCKS),
        .ROW_LANES(Q8_GEMV_ROW_LANES),
        .MAC_LANES(Q8_GEMV_MAC_LANES),
        .TILE_FUNCTIONAL_ENABLE(Q8_GEMV_TILE_FUNCTIONAL_ENABLE)
      ) u_q8_gemv_portal_adapter (
        .clk_i(clk),
        .rst_i(rst),
        .start_i(gemv_adapter_start_w),
        .ready_o(gemv_adapter_ready_w),
        .busy_o(gemv_adapter_busy_w),
        .command_id_i(macro_sequence_id_q),
        .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
        .windows_generation_valid_i(macro_windows_generation_valid_q),
        .activation_base_i(macro_src0_iova_q),
        .weight_base_i(macro_src1_iova_q),
        .dst_base_i(macro_dst_iova_q),
        .row_count_i(macro_outer_count_q),
        .block_count_i(gemv_block_count_ext_w[31:0]),
        .weight_row_stride_i(macro_src1_stride_q),
        .dst_row_stride_i(macro_dst_stride_q),
        .activation_window_base_i(macro_src0_window_base_q),
        .activation_window_bytes_i(macro_src0_window_size_q),
        .activation_window_read_i(macro_src0_window_perm_q[0]),
        .activation_window_write_i(macro_src0_window_perm_q[1]),
        .weight_window_base_i(macro_src1_window_base_q),
        .weight_window_bytes_i(macro_src1_window_size_q),
        .weight_window_read_i(macro_src1_window_perm_q[0]),
        .weight_window_write_i(macro_src1_window_perm_q[1]),
        .dst_window_base_i(macro_dst_window_base_q),
        .dst_window_bytes_i(macro_dst_window_size_q),
        .dst_window_read_i(macro_dst_window_perm_q[0]),
        .dst_window_write_i(macro_dst_window_perm_q[1]),
        .gmem_req_valid_o(gemv_gmem_req_valid_w),
        .gmem_req_ready_i(gemv_gmem_req_ready_w),
        .gmem_req_write_o(gemv_gmem_req_write_w),
        .gmem_req_addr_o(gemv_gmem_req_addr_w),
        .gmem_req_wdata_o(gemv_gmem_req_wdata_w),
        .gmem_req_wstrb_o(gemv_gmem_req_wstrb_w),
        .gmem_rsp_valid_i(gemv_gmem_rsp_valid_w),
        .gmem_rsp_ready_o(gemv_gmem_rsp_ready_w),
        .gmem_rsp_rdata_i(gemv_gmem_rsp_rdata_w),
        .gmem_rsp_error_i(gemv_gmem_rsp_error_w),
        .portal_req_valid_o(q8_portal_req_valid_o),
        .portal_req_ready_i(q8_portal_req_ready_i),
        .portal_req_mask_o(q8_portal_req_mask_o),
        .portal_req_addr_o(q8_portal_req_addr_o),
        .portal_rsp_valid_i(q8_portal_rsp_valid_i),
        .portal_rsp_ready_o(q8_portal_rsp_ready_o),
        .portal_rsp_mask_i(q8_portal_rsp_mask_i),
        .portal_rsp_blocks_i(q8_portal_rsp_blocks_i),
        .portal_rsp_error_i(q8_portal_rsp_error_i),
        .completion_valid_o(gemv_adapter_completion_valid_w),
        .dst_commit_o(gemv_adapter_dst_commit_w),
        .completion_command_id_o(gemv_adapter_completion_command_id_w),
        .completion_kernel_id_o(gemv_adapter_completion_kernel_id_w),
        .completion_row_count_o(gemv_adapter_completion_row_count_w),
        .completion_block_count_o(gemv_adapter_completion_block_count_w),
        .done_o(gemv_adapter_done_w),
        .error_o(gemv_adapter_error_w),
        .error_code_o(gemv_adapter_error_code_w),
        .child_error_code_o(gemv_adapter_child_error_code_w),
        .activation_words_accepted_o(gemv_adapter_activation_words_w),
        .weight_blocks_accepted_o(gemv_adapter_weight_blocks_w),
        .rows_written_o(gemv_adapter_rows_written_w),
        .gmem_read_beats_o(gemv_adapter_gmem_read_beats_w),
        .gmem_read_beats_completed_o(
            gemv_adapter_gmem_read_beats_completed_w),
        .gmem_read_bytes_o(gemv_adapter_raw_gmem_read_bytes_w),
        .activation_payload_bytes_o(gemv_adapter_activation_payload_bytes_w),
        .weight_payload_bytes_o(gemv_adapter_weight_payload_bytes_w),
        .gmem_write_beats_o(gemv_adapter_gmem_write_beats_w),
        .writes_completed_o(gemv_adapter_writes_completed_w),
        .write_bytes_o(gemv_adapter_write_bytes_w),
        .child_active_cycles_o(gemv_adapter_child_active_cycles_w),
        .active_cycles_o(gemv_adapter_active_cycles_w),
        .gmem_outstanding_o(gemv_adapter_raw_gmem_outstanding_w),
        .portal_request_groups_o(q8_portal_request_count_o),
        .portal_response_groups_o(q8_portal_response_count_o),
        .portal_blocks_o(q8_portal_block_count_o),
        .portal_bytes_o(q8_portal_byte_count_o),
        .portal_outstanding_o(q8_portal_outstanding_o)
      );
    end else begin : gen_q8_gemv_raw_gmem
      assign q8_portal_req_valid_o = 1'b0;
      assign q8_portal_req_mask_o = {Q8_GEMV_ROW_LANES{1'b0}};
      assign q8_portal_req_addr_o = {(Q8_GEMV_ROW_LANES*64){1'b0}};
      assign q8_portal_rsp_ready_o = 1'b0;
      assign q8_portal_request_count_o = 64'b0;
      assign q8_portal_response_count_o = 64'b0;
      assign q8_portal_block_count_o = 64'b0;
      assign q8_portal_byte_count_o = 64'b0;
      assign q8_portal_outstanding_o = 1'b0;

      TensorNpuQ8GemvWritebackAdapter #(
        .MAX_ROWS(GEMV_MAX_ROWS),
        .MAX_BLOCKS(GEMV_MAX_BLOCKS)
      ) u_q8_gemv_writeback_adapter (
        .clk_i(clk),
        .rst_i(rst),
        .start_i(gemv_adapter_start_w),
        .ready_o(gemv_adapter_ready_w),
        .busy_o(gemv_adapter_busy_w),
        .command_id_i(macro_sequence_id_q),
        .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
        .windows_generation_valid_i(macro_windows_generation_valid_q),
        .activation_base_i(macro_src0_iova_q),
        .weight_base_i(macro_src1_iova_q),
        .dst_base_i(macro_dst_iova_q),
        .row_count_i(macro_outer_count_q),
        .block_count_i(gemv_block_count_ext_w[31:0]),
        .weight_row_stride_i(macro_src1_stride_q),
        .dst_row_stride_i(macro_dst_stride_q),
        .activation_window_base_i(macro_src0_window_base_q),
        .activation_window_bytes_i(macro_src0_window_size_q),
        .activation_window_read_i(macro_src0_window_perm_q[0]),
        .activation_window_write_i(macro_src0_window_perm_q[1]),
        .weight_window_base_i(macro_src1_window_base_q),
        .weight_window_bytes_i(macro_src1_window_size_q),
        .weight_window_read_i(macro_src1_window_perm_q[0]),
        .weight_window_write_i(macro_src1_window_perm_q[1]),
        .dst_window_base_i(macro_dst_window_base_q),
        .dst_window_bytes_i(macro_dst_window_size_q),
        .dst_window_read_i(macro_dst_window_perm_q[0]),
        .dst_window_write_i(macro_dst_window_perm_q[1]),
        .gmem_req_valid_o(gemv_gmem_req_valid_w),
        .gmem_req_ready_i(gemv_gmem_req_ready_w),
        .gmem_req_write_o(gemv_gmem_req_write_w),
        .gmem_req_addr_o(gemv_gmem_req_addr_w),
        .gmem_req_wdata_o(gemv_gmem_req_wdata_w),
        .gmem_req_wstrb_o(gemv_gmem_req_wstrb_w),
        .gmem_rsp_valid_i(gemv_gmem_rsp_valid_w),
        .gmem_rsp_ready_o(gemv_gmem_rsp_ready_w),
        .gmem_rsp_rdata_i(gemv_gmem_rsp_rdata_w),
        .gmem_rsp_error_i(gemv_gmem_rsp_error_w),
        .completion_valid_o(gemv_adapter_completion_valid_w),
        .dst_commit_o(gemv_adapter_dst_commit_w),
        .completion_command_id_o(gemv_adapter_completion_command_id_w),
        .completion_kernel_id_o(gemv_adapter_completion_kernel_id_w),
        .completion_row_count_o(gemv_adapter_completion_row_count_w),
        .completion_block_count_o(gemv_adapter_completion_block_count_w),
        .done_o(gemv_adapter_done_w),
        .error_o(gemv_adapter_error_w),
        .error_code_o(gemv_adapter_error_code_w),
        .child_error_code_o(gemv_adapter_child_error_code_w),
        .activation_words_accepted_o(gemv_adapter_activation_words_w),
        .weight_blocks_accepted_o(gemv_adapter_weight_blocks_w),
        .rows_written_o(gemv_adapter_rows_written_w),
        .gmem_read_beats_o(gemv_adapter_gmem_read_beats_w),
        .gmem_read_beats_completed_o(
            gemv_adapter_gmem_read_beats_completed_w),
        .gmem_read_bytes_o(gemv_adapter_raw_gmem_read_bytes_w),
        .activation_payload_bytes_o(gemv_adapter_activation_payload_bytes_w),
        .weight_payload_bytes_o(gemv_adapter_weight_payload_bytes_w),
        .gmem_write_beats_o(gemv_adapter_gmem_write_beats_w),
        .writes_completed_o(gemv_adapter_writes_completed_w),
        .write_bytes_o(gemv_adapter_write_bytes_w),
        .child_active_cycles_o(gemv_adapter_child_active_cycles_w),
        .active_cycles_o(gemv_adapter_active_cycles_w),
        .gmem_outstanding_o(gemv_adapter_raw_gmem_outstanding_w)
      );
    end
  endgenerate

  wire f32_move_adapter_start_w;
  wire f32_move_adapter_ready_w;
  wire f32_move_adapter_busy_w;
  wire f32_move_adapter_completion_valid_w;
  wire f32_move_adapter_dst_commit_w;
  wire [63:0] f32_move_adapter_completion_command_id_w;
  wire [63:0] f32_move_adapter_completion_node_lo_w;
  wire [63:0] f32_move_adapter_completion_node_hi_w;
  wire f32_move_adapter_completion_required_w;
  wire f32_move_adapter_completion_operation_w;
  wire [31:0] f32_move_adapter_completion_kernel_id_w;
  wire f32_move_adapter_done_w;
  wire f32_move_adapter_error_w;
  wire [4:0] f32_move_adapter_error_code_w;
  wire [63:0] f32_move_adapter_indices_w;
  wire [63:0] f32_move_adapter_source_words_w;
  wire [63:0] f32_move_adapter_elements_w;
  wire [63:0] f32_move_adapter_read_beats_w;
  wire [63:0] f32_move_adapter_read_responses_w;
  wire [63:0] f32_move_adapter_read_bytes_w;
  wire [63:0] f32_move_adapter_write_beats_w;
  wire [63:0] f32_move_adapter_write_responses_w;
  wire [63:0] f32_move_adapter_write_bytes_w;
  wire [63:0] f32_move_adapter_expected_read_bytes_w;
  wire [63:0] f32_move_adapter_expected_write_bytes_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [63:0] f32_move_adapter_active_cycles_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire f32_move_adapter_gmem_outstanding_w;
  wire f32_move_gmem_req_valid_w;
  wire f32_move_gmem_req_ready_w;
  wire f32_move_gmem_req_write_w;
  wire [63:0] f32_move_gmem_req_addr_w;
  wire [63:0] f32_move_gmem_req_wdata_w;
  wire [7:0] f32_move_gmem_req_wstrb_w;
  wire f32_move_gmem_rsp_valid_w;
  wire f32_move_gmem_rsp_ready_w;
  wire [63:0] f32_move_gmem_rsp_rdata_w;
  wire f32_move_gmem_rsp_error_w;

  assign f32_move_adapter_start_w = (state_q == ST_MACRO_START) &&
                                    macro_select_f32_move_w &&
                                    f32_move_static_descriptor_valid_w &&
                                    !functional_command_select_w;

  generate
    if (F32_MOVER_PORTAL_ENABLE != 0) begin : gen_f32_mover_portal
      TensorNpuF32GatherRepeatPortalAdapter #(
        .LANES(F32_MOVER_PORTAL_LANES),
        .MAX_ELEMENTS(F32_MOVE_MAX_ELEMENTS),
        .MAX_INDICES(F32_MOVE_MAX_INDICES),
        .MAX_REPEAT(F32_MOVE_MAX_REPEAT),
        .MAX_OUTER(F32_MOVE_MAX_OUTER)
      ) u_f32_gather_repeat_portal_adapter (
        .clk_i(clk),
        .rst_i(rst),
        .start_i(f32_move_adapter_start_w),
        .ready_o(f32_move_adapter_ready_w),
        .busy_o(f32_move_adapter_busy_w),
        .operation_i(macro_select_f32_repeat_w),
        .npu_required_i(macro_command_flags_q[0]),
        .command_id_i(macro_sequence_id_q),
        .canonical_node_id_lo_i(macro_node_hash_lo_q),
        .canonical_node_id_hi_i(macro_node_hash_hi_q),
        .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
        .windows_generation_valid_i(macro_windows_generation_valid_q),
        .src_base_i(macro_src0_iova_q),
        .index_base_i(macro_src1_iova_q),
        .dst_base_i(macro_dst_iova_q),
        .element_count_i(macro_element_count_q[31:0]),
        .source_row_count_i(macro_select_f32_get_w ?
                            macro_scalar0_q : 32'd0),
        .index_count_i(macro_select_f32_get_w ?
                       macro_outer_count_q : 32'd0),
        .outer_count_i(macro_select_f32_repeat_w ?
                       macro_outer_count_q : 32'd0),
        .repeat_count_i(macro_select_f32_repeat_w ?
                        macro_scalar0_q : 32'd0),
        .src_row_stride_i(macro_src0_stride_q),
        .index_stride_i(macro_select_f32_get_w ?
                        macro_src1_stride_q : 64'd0),
        .dst_row_stride_i(macro_dst_stride_q),
        .dst_outer_stride_i(macro_select_f32_repeat_w ?
                            macro_src2_stride_q : 64'd0),
        .src_window_base_i(macro_src0_window_base_q),
        .src_window_bytes_i(macro_src0_window_size_q),
        .src_window_read_i(macro_src0_window_perm_q[0]),
        .src_window_write_i(macro_src0_window_perm_q[1]),
        .index_window_base_i(macro_src1_window_base_q),
        .index_window_bytes_i(macro_src1_window_size_q),
        .index_window_read_i(macro_src1_window_perm_q[0]),
        .index_window_write_i(macro_src1_window_perm_q[1]),
        .dst_window_base_i(macro_dst_window_base_q),
        .dst_window_bytes_i(macro_dst_window_size_q),
        .dst_window_read_i(macro_dst_window_perm_q[0]),
        .dst_window_write_i(macro_dst_window_perm_q[1]),
        .gmem_req_valid_o(f32_move_gmem_req_valid_w),
        .gmem_req_ready_i(f32_move_gmem_req_ready_w),
        .gmem_req_write_o(f32_move_gmem_req_write_w),
        .gmem_req_addr_o(f32_move_gmem_req_addr_w),
        .gmem_req_wdata_o(f32_move_gmem_req_wdata_w),
        .gmem_req_wstrb_o(f32_move_gmem_req_wstrb_w),
        .gmem_rsp_valid_i(f32_move_gmem_rsp_valid_w),
        .gmem_rsp_ready_o(f32_move_gmem_rsp_ready_w),
        .gmem_rsp_rdata_i(f32_move_gmem_rsp_rdata_w),
        .gmem_rsp_error_i(f32_move_gmem_rsp_error_w),
        .portal_req_valid_o(f32_mover_portal_req_valid_o),
        .portal_req_ready_i(f32_mover_portal_req_ready_i),
        .portal_req_write_o(f32_mover_portal_req_write_o),
        .portal_req_mask_o(f32_mover_portal_req_mask_o),
        .portal_req_addr_o(f32_mover_portal_req_addr_o),
        .portal_req_wdata_o(f32_mover_portal_req_wdata_o),
        .portal_rsp_valid_i(f32_mover_portal_rsp_valid_i),
        .portal_rsp_ready_o(f32_mover_portal_rsp_ready_o),
        .portal_rsp_mask_i(f32_mover_portal_rsp_mask_i),
        .portal_rsp_rdata_i(f32_mover_portal_rsp_rdata_i),
        .portal_rsp_error_i(f32_mover_portal_rsp_error_i),
        .completion_valid_o(f32_move_adapter_completion_valid_w),
        .dst_commit_o(f32_move_adapter_dst_commit_w),
        .completion_command_id_o(f32_move_adapter_completion_command_id_w),
        .completion_canonical_node_id_lo_o(
            f32_move_adapter_completion_node_lo_w),
        .completion_canonical_node_id_hi_o(
            f32_move_adapter_completion_node_hi_w),
        .completion_npu_required_o(f32_move_adapter_completion_required_w),
        .completion_operation_o(f32_move_adapter_completion_operation_w),
        .completion_kernel_id_o(f32_move_adapter_completion_kernel_id_w),
        .done_o(f32_move_adapter_done_w),
        .error_o(f32_move_adapter_error_w),
        .error_code_o(f32_move_adapter_error_code_w),
        .indices_completed_o(f32_move_adapter_indices_w),
        .source_words_completed_o(f32_move_adapter_source_words_w),
        .elements_completed_o(f32_move_adapter_elements_w),
        .portal_request_groups_o(f32_mover_portal_request_groups_o),
        .portal_response_groups_o(f32_mover_portal_response_groups_o),
        .portal_read_groups_o(f32_mover_portal_read_groups_o),
        .portal_write_groups_o(f32_mover_portal_write_groups_o),
        .portal_read_words_o(f32_mover_portal_read_words_o),
        .portal_write_words_o(f32_mover_portal_write_words_o),
        .portal_read_bytes_o(f32_mover_portal_read_bytes_o),
        .portal_write_bytes_o(f32_mover_portal_write_bytes_o),
        .portal_outstanding_o(f32_mover_portal_outstanding_o),
        .gmem_read_beats_o(f32_move_adapter_read_beats_w),
        .gmem_read_responses_o(f32_move_adapter_read_responses_w),
        .read_payload_bytes_o(f32_move_adapter_read_bytes_w),
        .gmem_write_beats_o(f32_move_adapter_write_beats_w),
        .gmem_write_responses_o(f32_move_adapter_write_responses_w),
        .write_payload_bytes_o(f32_move_adapter_write_bytes_w),
        .expected_gmem_read_bytes_o(
            f32_move_adapter_expected_read_bytes_w),
        .expected_gmem_write_bytes_o(
            f32_move_adapter_expected_write_bytes_w),
        .active_cycles_o(f32_move_adapter_active_cycles_w),
        .gmem_outstanding_o(f32_move_adapter_gmem_outstanding_w)
      );
    end else begin : gen_f32_mover_legacy
      assign f32_mover_portal_req_valid_o = 1'b0;
      assign f32_mover_portal_req_write_o = 1'b0;
      assign f32_mover_portal_req_mask_o =
          {F32_MOVER_PORTAL_LANES{1'b0}};
      assign f32_mover_portal_req_addr_o =
          {(F32_MOVER_PORTAL_LANES*64){1'b0}};
      assign f32_mover_portal_req_wdata_o =
          {(F32_MOVER_PORTAL_LANES*32){1'b0}};
      assign f32_mover_portal_rsp_ready_o = 1'b0;
      assign f32_mover_portal_request_groups_o = 64'd0;
      assign f32_mover_portal_response_groups_o = 64'd0;
      assign f32_mover_portal_read_groups_o = 64'd0;
      assign f32_mover_portal_write_groups_o = 64'd0;
      assign f32_mover_portal_read_words_o = 64'd0;
      assign f32_mover_portal_write_words_o = 64'd0;
      assign f32_mover_portal_read_bytes_o = 64'd0;
      assign f32_mover_portal_write_bytes_o = 64'd0;
      assign f32_mover_portal_outstanding_o = 1'b0;
      assign f32_move_adapter_expected_read_bytes_w = 64'd0;
      assign f32_move_adapter_expected_write_bytes_w = 64'd0;

  TensorNpuF32GatherRepeatAdapter #(
    .MAX_ELEMENTS(F32_MOVE_MAX_ELEMENTS),
    .MAX_INDICES(F32_MOVE_MAX_INDICES),
    .MAX_REPEAT(F32_MOVE_MAX_REPEAT),
    .MAX_OUTER(F32_MOVE_MAX_OUTER)
  ) u_f32_gather_repeat_adapter (
    .clk_i(clk),
    .rst_i(rst),
    .start_i(f32_move_adapter_start_w),
    .ready_o(f32_move_adapter_ready_w),
    .busy_o(f32_move_adapter_busy_w),
    .operation_i(macro_select_f32_repeat_w),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .src_base_i(macro_src0_iova_q),
    .index_base_i(macro_src1_iova_q),
    .dst_base_i(macro_dst_iova_q),
    .element_count_i(macro_element_count_q[31:0]),
    .source_row_count_i(macro_select_f32_get_w ?
                        macro_scalar0_q : 32'd0),
    .index_count_i(macro_select_f32_get_w ?
                   macro_outer_count_q : 32'd0),
    .outer_count_i(macro_select_f32_repeat_w ?
                   macro_outer_count_q : 32'd0),
    .repeat_count_i(macro_select_f32_repeat_w ?
                    macro_scalar0_q : 32'd0),
    .src_row_stride_i(macro_src0_stride_q),
    .index_stride_i(macro_select_f32_get_w ?
                    macro_src1_stride_q : 64'd0),
    .dst_row_stride_i(macro_dst_stride_q),
    .dst_outer_stride_i(macro_select_f32_repeat_w ?
                        macro_src2_stride_q : 64'd0),
    .src_window_base_i(macro_src0_window_base_q),
    .src_window_bytes_i(macro_src0_window_size_q),
    .src_window_read_i(macro_src0_window_perm_q[0]),
    .src_window_write_i(macro_src0_window_perm_q[1]),
    .index_window_base_i(macro_src1_window_base_q),
    .index_window_bytes_i(macro_src1_window_size_q),
    .index_window_read_i(macro_src1_window_perm_q[0]),
    .index_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(f32_move_gmem_req_valid_w),
    .gmem_req_ready_i(f32_move_gmem_req_ready_w),
    .gmem_req_write_o(f32_move_gmem_req_write_w),
    .gmem_req_addr_o(f32_move_gmem_req_addr_w),
    .gmem_req_wdata_o(f32_move_gmem_req_wdata_w),
    .gmem_req_wstrb_o(f32_move_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(f32_move_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(f32_move_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(f32_move_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(f32_move_gmem_rsp_error_w),
    .completion_valid_o(f32_move_adapter_completion_valid_w),
    .dst_commit_o(f32_move_adapter_dst_commit_w),
    .completion_command_id_o(f32_move_adapter_completion_command_id_w),
    .completion_canonical_node_id_lo_o(
        f32_move_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(
        f32_move_adapter_completion_node_hi_w),
    .completion_npu_required_o(f32_move_adapter_completion_required_w),
    .completion_operation_o(f32_move_adapter_completion_operation_w),
    .completion_kernel_id_o(f32_move_adapter_completion_kernel_id_w),
    .done_o(f32_move_adapter_done_w),
    .error_o(f32_move_adapter_error_w),
    .error_code_o(f32_move_adapter_error_code_w),
    .indices_completed_o(f32_move_adapter_indices_w),
    .source_words_completed_o(f32_move_adapter_source_words_w),
    .elements_completed_o(f32_move_adapter_elements_w),
    .gmem_read_beats_o(f32_move_adapter_read_beats_w),
    .gmem_read_responses_o(f32_move_adapter_read_responses_w),
    .read_payload_bytes_o(f32_move_adapter_read_bytes_w),
    .gmem_write_beats_o(f32_move_adapter_write_beats_w),
    .gmem_write_responses_o(f32_move_adapter_write_responses_w),
    .write_payload_bytes_o(f32_move_adapter_write_bytes_w),
    .active_cycles_o(f32_move_adapter_active_cycles_w),
    .gmem_outstanding_o(f32_move_adapter_gmem_outstanding_w)
  );
    end
  endgenerate

  // Full-vocabulary F32 ARGMAX owner.  This path deliberately uses only the
  // public raw-GMEM request/response channel: the host copies beats, while
  // TensorNpuF32ArgmaxWritebackAdapter performs every FP32 decision in RTL.
  wire argmax_adapter_start_w;
  wire argmax_adapter_ready_w;
  wire argmax_adapter_busy_w;
  wire argmax_adapter_completion_valid_w;
  wire argmax_adapter_dst_commit_w;
  wire [63:0] argmax_adapter_completion_command_w;
  wire [63:0] argmax_adapter_completion_node_lo_w;
  wire [63:0] argmax_adapter_completion_node_hi_w;
  wire argmax_adapter_completion_required_w;
  wire [31:0] argmax_adapter_completion_kernel_w;
  wire argmax_adapter_done_w;
  wire argmax_adapter_error_w;
  wire [4:0] argmax_adapter_error_code_w;
  wire [63:0] argmax_adapter_elements_w;
  wire [63:0] argmax_adapter_comparisons_w;
  wire [63:0] argmax_adapter_read_requests_w;
  wire [63:0] argmax_adapter_read_responses_w;
  wire [63:0] argmax_adapter_read_bytes_w;
  wire [63:0] argmax_adapter_write_requests_w;
  wire [63:0] argmax_adapter_write_responses_w;
  wire [63:0] argmax_adapter_write_bytes_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [63:0] argmax_adapter_active_cycles_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire argmax_adapter_gmem_outstanding_w;
  wire argmax_gmem_req_valid_w;
  wire argmax_gmem_req_ready_w;
  wire argmax_gmem_req_write_w;
  wire [63:0] argmax_gmem_req_addr_w;
  wire [63:0] argmax_gmem_req_wdata_w;
  wire [7:0] argmax_gmem_req_wstrb_w;
  wire argmax_gmem_rsp_valid_w;
  wire argmax_gmem_rsp_ready_w;
  wire [63:0] argmax_gmem_rsp_rdata_w;
  wire argmax_gmem_rsp_error_w;

  assign argmax_adapter_start_w = (state_q == ST_MACRO_START) &&
                                   macro_select_argmax_w &&
                                   argmax_static_descriptor_valid_w &&
                                   !functional_command_select_w;

  TensorNpuF32ArgmaxWritebackAdapter #(
    .MAX_ELEMENTS(F32_ARGMAX_MAX_ELEMENTS)
  ) u_f32_argmax_writeback_adapter (
    .clk_i(clk),
    .rst_i(rst),
    .start_i(argmax_adapter_start_w),
    .ready_o(argmax_adapter_ready_w),
    .busy_o(argmax_adapter_busy_w),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .src_base_i(macro_src0_iova_q),
    .dst_base_i(macro_dst_iova_q),
    .element_count_i(macro_element_count_q),
    .src_stride_i(macro_src0_stride_q),
    .dst_stride_i(macro_dst_stride_q),
    .src_window_base_i(macro_src0_window_base_q),
    .src_window_bytes_i(macro_src0_window_size_q),
    .src_window_read_i(macro_src0_window_perm_q[0]),
    .src_window_write_i(macro_src0_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(argmax_gmem_req_valid_w),
    .gmem_req_ready_i(argmax_gmem_req_ready_w),
    .gmem_req_write_o(argmax_gmem_req_write_w),
    .gmem_req_addr_o(argmax_gmem_req_addr_w),
    .gmem_req_wdata_o(argmax_gmem_req_wdata_w),
    .gmem_req_wstrb_o(argmax_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(argmax_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(argmax_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(argmax_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(argmax_gmem_rsp_error_w),
    .completion_valid_o(argmax_adapter_completion_valid_w),
    .dst_commit_o(argmax_adapter_dst_commit_w),
    .completion_command_id_o(argmax_adapter_completion_command_w),
    .completion_canonical_node_id_lo_o(
        argmax_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(
        argmax_adapter_completion_node_hi_w),
    .completion_npu_required_o(argmax_adapter_completion_required_w),
    .completion_kernel_id_o(argmax_adapter_completion_kernel_w),
    .done_o(argmax_adapter_done_w),
    .error_o(argmax_adapter_error_w),
    .error_code_o(argmax_adapter_error_code_w),
    .elements_scanned_o(argmax_adapter_elements_w),
    .comparisons_o(argmax_adapter_comparisons_w),
    .gmem_read_requests_o(argmax_adapter_read_requests_w),
    .gmem_read_responses_o(argmax_adapter_read_responses_w),
    .read_payload_bytes_o(argmax_adapter_read_bytes_w),
    .gmem_write_requests_o(argmax_adapter_write_requests_w),
    .gmem_write_responses_o(argmax_adapter_write_responses_w),
    .write_payload_bytes_o(argmax_adapter_write_bytes_w),
    .active_cycles_o(argmax_adapter_active_cycles_w),
    .gmem_outstanding_o(argmax_adapter_gmem_outstanding_w)
  );

  reg [`NPU_ERROR_W-1:0] argmax_mapped_error_code_r;
  reg [31:0] argmax_mapped_error_class_r;
  always @(*) begin
    argmax_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
    argmax_mapped_error_class_r = ABI_ERROR_PROTOCOL;
    case (argmax_adapter_error_code_w)
      5'd1: begin
        argmax_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
        argmax_mapped_error_class_r = ABI_ERROR_LAYOUT;
      end
      5'd2, 5'd3, 5'd4: begin
        argmax_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
        argmax_mapped_error_class_r = ABI_ERROR_IOVA;
      end
      5'd6: begin
        argmax_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
        argmax_mapped_error_class_r = ABI_ERROR_GMEM;
      end
      default: begin end
    endcase
  end

  // Exact-profile UNARY/GLU adapter and public GMEM channel.
  wire unary_glu_adapter_start_w, unary_glu_adapter_ready_w;
  wire unary_glu_adapter_busy_w, unary_glu_adapter_completion_valid_w;
  wire unary_glu_adapter_dst_commit_w, unary_glu_adapter_done_w;
  wire unary_glu_adapter_error_w;
  wire [4:0] unary_glu_adapter_error_code_w;
  wire [63:0] unary_glu_adapter_completion_command_id_w;
  wire [63:0] unary_glu_adapter_completion_node_lo_w;
  wire [63:0] unary_glu_adapter_completion_node_hi_w;
  wire unary_glu_adapter_completion_required_w;
  wire unary_glu_adapter_completion_operation_w;
  wire [7:0] unary_glu_adapter_completion_subtype_w;
  wire [7:0] unary_glu_adapter_completion_profile_w;
  wire [31:0] unary_glu_adapter_completion_kernel_w;
  wire [31:0] unary_glu_adapter_operator_census_w;
  wire [31:0] unary_glu_adapter_subtype_census_w;
  wire [31:0] unary_glu_adapter_profile_census_w;
  wire [63:0] unary_glu_adapter_src0_words_w;
  wire [63:0] unary_glu_adapter_src1_words_w;
  wire [63:0] unary_glu_adapter_scalar_launches_w;
  wire [63:0] unary_glu_adapter_scalar_terminals_w;
  wire [63:0] unary_glu_adapter_elements_w;
  wire [63:0] unary_glu_adapter_read_beats_w;
  wire [63:0] unary_glu_adapter_read_responses_w;
  wire [63:0] unary_glu_adapter_read_bytes_w;
  wire [63:0] unary_glu_adapter_write_beats_w;
  wire [63:0] unary_glu_adapter_write_responses_w;
  wire [63:0] unary_glu_adapter_write_bytes_w;
  wire unary_glu_adapter_gmem_outstanding_w;
  wire unary_glu_gmem_req_valid_w, unary_glu_gmem_req_ready_w;
  wire unary_glu_gmem_req_write_w;
  wire [63:0] unary_glu_gmem_req_addr_w, unary_glu_gmem_req_wdata_w;
  wire [7:0] unary_glu_gmem_req_wstrb_w;
  wire unary_glu_gmem_rsp_valid_w, unary_glu_gmem_rsp_ready_w;
  wire [63:0] unary_glu_gmem_rsp_rdata_w;
  wire unary_glu_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [3:0] unary_glu_adapter_element_error_w;
  wire [4:0] unary_glu_adapter_flags_w;
  wire [4:0] unary_glu_adapter_child_mask_w;
  wire [63:0] unary_glu_adapter_element_cycles_w;
  wire [63:0] unary_glu_adapter_active_cycles_w;
  wire unary_glu_adapter_element_outstanding_w;
  wire unary_glu_adapter_gmem_drain_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign unary_glu_adapter_start_w = (state_q == ST_MACRO_START) &&
                                     macro_select_unary_glu_w &&
                                     exact_static_descriptor_valid_w;

  TensorNpuUnaryGluWritebackAdapter u_unary_glu_writeback_adapter (
    .clk_i(clk),
    .rst_i(rst),
    .start_i(unary_glu_adapter_start_w),
    .ready_o(unary_glu_adapter_ready_w),
    .busy_o(unary_glu_adapter_busy_w),
    .operation_glu_i(exact_operation_glu_r),
    .subtype_i(exact_subtype_r),
    .op_params_tail_zero_i(1'b1),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .ne0_i(exact_dst_ne0_r),
    .ne1_i(exact_dst_ne1_r),
    .ne2_i(exact_dst_ne2_r),
    .ne3_i(exact_dst_ne3_r),
    .src0_base_i(macro_src0_iova_q),
    .src0_nb0_i(exact_src0_nb0_r),
    .src0_nb1_i(exact_src0_nb1_r),
    .src0_nb2_i(exact_src0_nb2_r),
    .src0_nb3_i(exact_src0_nb3_r),
    .src1_base_i(macro_src1_iova_q),
    .src1_nb0_i(exact_src1_nb0_r),
    .src1_nb1_i(exact_src1_nb1_r),
    .src1_nb2_i(exact_src1_nb2_r),
    .src1_nb3_i(exact_src1_nb3_r),
    .dst_base_i(macro_dst_iova_q),
    .dst_nb0_i(exact_dst_nb0_r),
    .dst_nb1_i(exact_dst_nb1_r),
    .dst_nb2_i(exact_dst_nb2_r),
    .dst_nb3_i(exact_dst_nb3_r),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(unary_glu_gmem_req_valid_w),
    .gmem_req_ready_i(unary_glu_gmem_req_ready_w),
    .gmem_req_write_o(unary_glu_gmem_req_write_w),
    .gmem_req_addr_o(unary_glu_gmem_req_addr_w),
    .gmem_req_wdata_o(unary_glu_gmem_req_wdata_w),
    .gmem_req_wstrb_o(unary_glu_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(unary_glu_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(unary_glu_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(unary_glu_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(unary_glu_gmem_rsp_error_w),
    .completion_valid_o(unary_glu_adapter_completion_valid_w),
    .dst_commit_o(unary_glu_adapter_dst_commit_w),
    .completion_command_id_o(unary_glu_adapter_completion_command_id_w),
    .completion_canonical_node_id_lo_o(
        unary_glu_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(
        unary_glu_adapter_completion_node_hi_w),
    .completion_npu_required_o(unary_glu_adapter_completion_required_w),
    .completion_operation_glu_o(unary_glu_adapter_completion_operation_w),
    .completion_subtype_o(unary_glu_adapter_completion_subtype_w),
    .completion_profile_id_o(unary_glu_adapter_completion_profile_w),
    .completion_kernel_id_o(unary_glu_adapter_completion_kernel_w),
    .completion_operator_census_o(unary_glu_adapter_operator_census_w),
    .completion_subtype_census_o(unary_glu_adapter_subtype_census_w),
    .completion_profile_census_o(unary_glu_adapter_profile_census_w),
    .done_o(unary_glu_adapter_done_w),
    .error_o(unary_glu_adapter_error_w),
    .error_code_o(unary_glu_adapter_error_code_w),
    .element_error_code_o(unary_glu_adapter_element_error_w),
    .src0_words_completed_o(unary_glu_adapter_src0_words_w),
    .src1_words_completed_o(unary_glu_adapter_src1_words_w),
    .scalar_launches_o(unary_glu_adapter_scalar_launches_w),
    .scalar_terminals_o(unary_glu_adapter_scalar_terminals_w),
    .elements_completed_o(unary_glu_adapter_elements_w),
    .element_flags_or_o(unary_glu_adapter_flags_w),
    .element_child_call_mask_or_o(unary_glu_adapter_child_mask_w),
    .element_active_cycles_o(unary_glu_adapter_element_cycles_w),
    .gmem_read_beats_o(unary_glu_adapter_read_beats_w),
    .gmem_read_responses_o(unary_glu_adapter_read_responses_w),
    .read_payload_bytes_o(unary_glu_adapter_read_bytes_w),
    .gmem_write_beats_o(unary_glu_adapter_write_beats_w),
    .gmem_write_responses_o(unary_glu_adapter_write_responses_w),
    .write_payload_bytes_o(unary_glu_adapter_write_bytes_w),
    .active_cycles_o(unary_glu_adapter_active_cycles_w),
    .gmem_outstanding_o(unary_glu_adapter_gmem_outstanding_w),
    .element_outstanding_o(unary_glu_adapter_element_outstanding_w),
    .gmem_drain_o(unary_glu_adapter_gmem_drain_w)
  );

  // Exact-profile RMS_NORM/L2_NORM adapter and public GMEM channel.
  wire norm_adapter_start_w, norm_adapter_ready_w, norm_adapter_busy_w;
  wire norm_adapter_completion_valid_w, norm_adapter_dst_commit_w;
  wire norm_adapter_done_w, norm_adapter_error_w;
  wire [4:0] norm_adapter_error_code_w;
  wire [63:0] norm_adapter_completion_command_id_w;
  wire [63:0] norm_adapter_completion_node_lo_w;
  wire [63:0] norm_adapter_completion_node_hi_w;
  wire norm_adapter_completion_required_w;
  wire [2:0] norm_adapter_completion_reduce_op_w;
  wire [31:0] norm_adapter_completion_epsilon_w;
  wire [7:0] norm_adapter_completion_profile_w;
  wire [31:0] norm_adapter_completion_kernel_w;
  wire [31:0] norm_adapter_operator_census_w;
  wire [31:0] norm_adapter_profile_census_w;
  wire [63:0] norm_adapter_rows_w, norm_adapter_source_words_w;
  wire [63:0] norm_adapter_input_elements_w;
  wire [63:0] norm_adapter_output_elements_w, norm_adapter_elements_w;
  wire [63:0] norm_adapter_launches_w, norm_adapter_terminals_w;
  wire [63:0] norm_adapter_read_beats_w, norm_adapter_read_responses_w;
  wire [63:0] norm_adapter_read_bytes_w;
  wire [63:0] norm_adapter_write_beats_w, norm_adapter_write_responses_w;
  wire [63:0] norm_adapter_write_bytes_w;
  wire norm_adapter_gmem_outstanding_w;
  wire norm_gmem_req_valid_w, norm_gmem_req_ready_w;
  wire norm_gmem_req_write_w;
  wire [63:0] norm_gmem_req_addr_w, norm_gmem_req_wdata_w;
  wire [7:0] norm_gmem_req_wstrb_w;
  wire norm_gmem_rsp_valid_w, norm_gmem_rsp_ready_w;
  wire [63:0] norm_gmem_rsp_rdata_w;
  wire norm_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [4:0] norm_adapter_engine_error_w, norm_adapter_engine_flags_w;
  wire [63:0] norm_adapter_aborts_w, norm_adapter_engine_cycles_w;
  wire [63:0] norm_adapter_active_cycles_w;
  wire norm_adapter_engine_outstanding_w, norm_adapter_gmem_drain_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign norm_adapter_start_w = (state_q == ST_MACRO_START) &&
                                macro_select_norm_w &&
                                exact_static_descriptor_valid_w;

  TensorNpuNormWritebackAdapter u_norm_writeback_adapter (
    .clk_i(clk), .rst_i(rst),
    .start_i(norm_adapter_start_w),
    .ready_o(norm_adapter_ready_w), .busy_o(norm_adapter_busy_w),
    .reduce_op_i(exact_reduce_op_r),
    .epsilon_bits_i(exact_epsilon_bits_r),
    .op_params_tail_zero_i(1'b1),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .ne0_i(exact_dst_ne0_r), .ne1_i(exact_dst_ne1_r),
    .ne2_i(exact_dst_ne2_r), .ne3_i(exact_dst_ne3_r),
    .src0_base_i(macro_src0_iova_q),
    .src0_nb0_i(exact_src0_nb0_r), .src0_nb1_i(exact_src0_nb1_r),
    .src0_nb2_i(exact_src0_nb2_r), .src0_nb3_i(exact_src0_nb3_r),
    .src1_base_i(macro_src1_iova_q),
    .src1_nb0_i(exact_src1_nb0_r), .src1_nb1_i(exact_src1_nb1_r),
    .src1_nb2_i(exact_src1_nb2_r), .src1_nb3_i(exact_src1_nb3_r),
    .dst_base_i(macro_dst_iova_q),
    .dst_nb0_i(exact_dst_nb0_r), .dst_nb1_i(exact_dst_nb1_r),
    .dst_nb2_i(exact_dst_nb2_r), .dst_nb3_i(exact_dst_nb3_r),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(norm_gmem_req_valid_w),
    .gmem_req_ready_i(norm_gmem_req_ready_w),
    .gmem_req_write_o(norm_gmem_req_write_w),
    .gmem_req_addr_o(norm_gmem_req_addr_w),
    .gmem_req_wdata_o(norm_gmem_req_wdata_w),
    .gmem_req_wstrb_o(norm_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(norm_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(norm_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(norm_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(norm_gmem_rsp_error_w),
    .completion_valid_o(norm_adapter_completion_valid_w),
    .dst_commit_o(norm_adapter_dst_commit_w),
    .completion_command_id_o(norm_adapter_completion_command_id_w),
    .completion_canonical_node_id_lo_o(norm_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(norm_adapter_completion_node_hi_w),
    .completion_npu_required_o(norm_adapter_completion_required_w),
    .completion_reduce_op_o(norm_adapter_completion_reduce_op_w),
    .completion_epsilon_bits_o(norm_adapter_completion_epsilon_w),
    .completion_profile_id_o(norm_adapter_completion_profile_w),
    .completion_kernel_id_o(norm_adapter_completion_kernel_w),
    .completion_operator_census_o(norm_adapter_operator_census_w),
    .completion_profile_census_o(norm_adapter_profile_census_w),
    .done_o(norm_adapter_done_w), .error_o(norm_adapter_error_w),
    .error_code_o(norm_adapter_error_code_w),
    .engine_error_code_o(norm_adapter_engine_error_w),
    .rows_completed_o(norm_adapter_rows_w),
    .source_words_completed_o(norm_adapter_source_words_w),
    .engine_input_elements_o(norm_adapter_input_elements_w),
    .engine_output_elements_o(norm_adapter_output_elements_w),
    .elements_completed_o(norm_adapter_elements_w),
    .engine_launches_o(norm_adapter_launches_w),
    .engine_terminals_o(norm_adapter_terminals_w),
    .engine_aborts_o(norm_adapter_aborts_w),
    .engine_flags_or_o(norm_adapter_engine_flags_w),
    .engine_active_cycles_o(norm_adapter_engine_cycles_w),
    .gmem_read_beats_o(norm_adapter_read_beats_w),
    .gmem_read_responses_o(norm_adapter_read_responses_w),
    .read_payload_bytes_o(norm_adapter_read_bytes_w),
    .gmem_write_beats_o(norm_adapter_write_beats_w),
    .gmem_write_responses_o(norm_adapter_write_responses_w),
    .write_payload_bytes_o(norm_adapter_write_bytes_w),
    .active_cycles_o(norm_adapter_active_cycles_w),
    .gmem_outstanding_o(norm_adapter_gmem_outstanding_w),
    .engine_outstanding_o(norm_adapter_engine_outstanding_w),
    .gmem_drain_o(norm_adapter_gmem_drain_w)
  );

  // Exact manifest SUM_ROWS adapter and public GMEM channel.
  wire sum_adapter_start_w, sum_adapter_ready_w, sum_adapter_busy_w;
  wire sum_adapter_completion_valid_w, sum_adapter_dst_commit_w;
  wire sum_adapter_done_w, sum_adapter_error_w;
  wire [4:0] sum_adapter_error_code_w, sum_adapter_engine_error_w;
  wire [63:0] sum_adapter_completion_command_id_w;
  wire [63:0] sum_adapter_completion_node_lo_w;
  wire [63:0] sum_adapter_completion_node_hi_w;
  wire sum_adapter_completion_required_w;
  wire [2:0] sum_adapter_completion_reduce_op_w;
  wire [15:0] sum_adapter_completion_manifest_op_w;
  wire [2:0] sum_adapter_completion_arity_w;
  wire [7:0] sum_adapter_completion_profile_w;
  wire [31:0] sum_adapter_completion_kernel_w;
  wire [31:0] sum_adapter_operator_census_w;
  wire [31:0] sum_adapter_profile_census_w;
  wire [63:0] sum_adapter_rows_w, sum_adapter_elements_w;
  wire [63:0] sum_adapter_reductions_w, sum_adapter_results_w;
  wire [63:0] sum_adapter_read_requests_w, sum_adapter_read_responses_w;
  wire [63:0] sum_adapter_read_bytes_w;
  wire [63:0] sum_adapter_write_requests_w, sum_adapter_write_responses_w;
  wire [63:0] sum_adapter_write_bytes_w;
  wire [63:0] sum_adapter_launches_w, sum_adapter_terminals_w;
  wire sum_adapter_gmem_outstanding_w;
  wire sum_gmem_req_valid_w, sum_gmem_req_ready_w, sum_gmem_req_write_w;
  wire [63:0] sum_gmem_req_addr_w, sum_gmem_req_wdata_w;
  wire [7:0] sum_gmem_req_wstrb_w;
  wire sum_gmem_rsp_valid_w, sum_gmem_rsp_ready_w;
  wire [63:0] sum_gmem_rsp_rdata_w;
  wire sum_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [4:0] sum_adapter_engine_flags_w;
  wire sum_adapter_poisoned_w;
  wire [63:0] sum_adapter_widen_requests_w, sum_adapter_widen_responses_w;
  wire [63:0] sum_adapter_add_requests_w, sum_adapter_add_responses_w;
  wire [63:0] sum_adapter_narrow_requests_w, sum_adapter_narrow_responses_w;
  wire [63:0] sum_adapter_engine_cycles_w, sum_adapter_active_cycles_w;
  wire sum_adapter_engine_outstanding_w, sum_adapter_gmem_drain_w;
  wire sum_adapter_fault_valid_w;
  wire [63:0] sum_adapter_fault_cycle_w, sum_adapter_fault_addr_w;
  wire [127:0] sum_adapter_fault_coordinate_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign sum_adapter_start_w = (state_q == ST_MACRO_START) &&
                               macro_select_sum_w &&
                               exact_static_descriptor_valid_w;

  TensorNpuSumRowsWritebackAdapter u_sum_rows_writeback_adapter (
    .clk_i(clk), .rst_i(rst),
    .start_i(sum_adapter_start_w), .ready_o(sum_adapter_ready_w),
    .busy_o(sum_adapter_busy_w), .reduce_op_i(exact_reduce_op_r),
    .manifest_op_id_i(exact_manifest_op_id_r),
    .source_arity_i(exact_source_arity_r),
    .op_params_i(exact_op_params_r), .op_params_tail_zero_i(1'b1),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .src0_dtype_i(exact_src0_dtype_r), .src0_flags_i(exact_src0_flags_r),
    .src0_view_off_i(exact_src0_view_r),
    .src0_ne0_i(exact_src0_ne0_r), .src0_ne1_i(exact_src0_ne1_r),
    .src0_ne2_i(exact_src0_ne2_r), .src0_ne3_i(exact_src0_ne3_r),
    .src0_base_i(macro_src0_iova_q),
    .src0_nb0_i(exact_src0_nb0_r), .src0_nb1_i(exact_src0_nb1_r),
    .src0_nb2_i(exact_src0_nb2_r), .src0_nb3_i(exact_src0_nb3_r),
    .src1_base_i(macro_src1_iova_q),
    .src1_nb0_i(exact_src1_nb0_r), .src1_nb1_i(exact_src1_nb1_r),
    .src1_nb2_i(exact_src1_nb2_r), .src1_nb3_i(exact_src1_nb3_r),
    .dst_dtype_i(exact_dst_dtype_r), .dst_flags_i(exact_dst_flags_r),
    .dst_view_off_i(exact_dst_view_r),
    .dst_ne0_i(exact_dst_ne0_r), .dst_ne1_i(exact_dst_ne1_r),
    .dst_ne2_i(exact_dst_ne2_r), .dst_ne3_i(exact_dst_ne3_r),
    .dst_base_i(macro_dst_iova_q),
    .dst_nb0_i(exact_dst_nb0_r), .dst_nb1_i(exact_dst_nb1_r),
    .dst_nb2_i(exact_dst_nb2_r), .dst_nb3_i(exact_dst_nb3_r),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(sum_gmem_req_valid_w),
    .gmem_req_ready_i(sum_gmem_req_ready_w),
    .gmem_req_write_o(sum_gmem_req_write_w),
    .gmem_req_addr_o(sum_gmem_req_addr_w),
    .gmem_req_wdata_o(sum_gmem_req_wdata_w),
    .gmem_req_wstrb_o(sum_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(sum_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(sum_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(sum_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(sum_gmem_rsp_error_w),
    .completion_valid_o(sum_adapter_completion_valid_w),
    .dst_commit_o(sum_adapter_dst_commit_w),
    .completion_command_id_o(sum_adapter_completion_command_id_w),
    .completion_canonical_node_id_lo_o(sum_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(sum_adapter_completion_node_hi_w),
    .completion_npu_required_o(sum_adapter_completion_required_w),
    .completion_reduce_op_o(sum_adapter_completion_reduce_op_w),
    .completion_manifest_op_id_o(sum_adapter_completion_manifest_op_w),
    .completion_source_arity_o(sum_adapter_completion_arity_w),
    .completion_profile_id_o(sum_adapter_completion_profile_w),
    .completion_kernel_id_o(sum_adapter_completion_kernel_w),
    .completion_operator_census_o(sum_adapter_operator_census_w),
    .completion_profile_census_o(sum_adapter_profile_census_w),
    .done_o(sum_adapter_done_w), .error_o(sum_adapter_error_w),
    .error_code_o(sum_adapter_error_code_w),
    .engine_error_code_o(sum_adapter_engine_error_w),
    .engine_flags_o(sum_adapter_engine_flags_w),
    .poisoned_o(sum_adapter_poisoned_w),
    .rows_reduced_o(sum_adapter_rows_w),
    .elements_processed_o(sum_adapter_elements_w),
    .reduction_operations_o(sum_adapter_reductions_w),
    .results_generated_o(sum_adapter_results_w),
    .gmem_read_requests_o(sum_adapter_read_requests_w),
    .gmem_read_responses_o(sum_adapter_read_responses_w),
    .read_payload_bytes_o(sum_adapter_read_bytes_w),
    .gmem_write_requests_o(sum_adapter_write_requests_w),
    .gmem_write_responses_o(sum_adapter_write_responses_w),
    .write_payload_bytes_o(sum_adapter_write_bytes_w),
    .widen_requests_o(sum_adapter_widen_requests_w),
    .widen_responses_o(sum_adapter_widen_responses_w),
    .add_requests_o(sum_adapter_add_requests_w),
    .add_responses_o(sum_adapter_add_responses_w),
    .narrow_requests_o(sum_adapter_narrow_requests_w),
    .narrow_responses_o(sum_adapter_narrow_responses_w),
    .engine_launches_o(sum_adapter_launches_w),
    .engine_terminals_o(sum_adapter_terminals_w),
    .engine_active_cycles_o(sum_adapter_engine_cycles_w),
    .active_cycles_o(sum_adapter_active_cycles_w),
    .gmem_outstanding_o(sum_adapter_gmem_outstanding_w),
    .engine_outstanding_o(sum_adapter_engine_outstanding_w),
    .gmem_drain_o(sum_adapter_gmem_drain_w),
    .engine_fault_valid_o(sum_adapter_fault_valid_w),
    .engine_first_fault_cycle_o(sum_adapter_fault_cycle_w),
    .engine_first_fault_coordinate_o(sum_adapter_fault_coordinate_w),
    .engine_first_fault_gmem_addr_o(sum_adapter_fault_addr_w)
  );

  // Exact manifest SSM_CONV adapter and public GMEM channel.
  wire ssm_adapter_start_w, ssm_adapter_ready_w, ssm_adapter_busy_w;
  wire ssm_adapter_completion_valid_w, ssm_adapter_dst_commit_w;
  wire ssm_adapter_done_w, ssm_adapter_error_w;
  wire [4:0] ssm_adapter_error_code_w;
  wire [63:0] ssm_adapter_completion_command_id_w;
  wire [63:0] ssm_adapter_completion_node_lo_w;
  wire [63:0] ssm_adapter_completion_node_hi_w;
  wire ssm_adapter_completion_required_w;
  wire [15:0] ssm_adapter_completion_manifest_op_w;
  wire [2:0] ssm_adapter_completion_arity_w;
  wire [7:0] ssm_adapter_completion_profile_w;
  wire [31:0] ssm_adapter_completion_kernel_w;
  wire [31:0] ssm_adapter_operator_census_w;
  wire [31:0] ssm_adapter_profile_census_w;
  wire [63:0] ssm_adapter_outputs_computed_w;
  wire [63:0] ssm_adapter_outputs_completed_w;
  wire [63:0] ssm_adapter_src0_words_w, ssm_adapter_src1_words_w;
  wire [63:0] ssm_adapter_work_items_w;
  wire [63:0] ssm_adapter_read_requests_w, ssm_adapter_read_responses_w;
  wire [63:0] ssm_adapter_read_bytes_w;
  wire [63:0] ssm_adapter_write_requests_w, ssm_adapter_write_responses_w;
  wire [63:0] ssm_adapter_write_bytes_w;
  wire [63:0] ssm_adapter_mul_requests_w, ssm_adapter_mul_responses_w;
  wire [63:0] ssm_adapter_add_requests_w, ssm_adapter_add_responses_w;
  wire ssm_adapter_gmem_outstanding_w;
  wire ssm_gmem_req_valid_w, ssm_gmem_req_ready_w, ssm_gmem_req_write_w;
  wire [63:0] ssm_gmem_req_addr_w, ssm_gmem_req_wdata_w;
  wire [7:0] ssm_gmem_req_wstrb_w;
  wire ssm_gmem_rsp_valid_w, ssm_gmem_rsp_ready_w;
  wire [63:0] ssm_gmem_rsp_rdata_w;
  wire ssm_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [4:0] ssm_adapter_numeric_flags_w;
  wire ssm_adapter_poisoned_w, ssm_adapter_numeric_outstanding_w;
  wire ssm_adapter_gmem_drain_w;
  wire [63:0] ssm_adapter_active_cycles_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign ssm_adapter_start_w = (state_q == ST_MACRO_START) &&
                               macro_select_ssm_w &&
                               exact_static_descriptor_valid_w;

  TensorNpuSsmConvWritebackAdapter u_ssm_conv_writeback_adapter (
    .clk_i(clk), .rst_i(rst),
    .start_i(ssm_adapter_start_w), .ready_o(ssm_adapter_ready_w),
    .busy_o(ssm_adapter_busy_w),
    .manifest_op_id_i(exact_manifest_op_id_r),
    .source_arity_i(exact_source_arity_r),
    .op_params_i(exact_op_params_r), .op_params_tail_zero_i(1'b1),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .src0_dtype_i(exact_src0_dtype_r), .src0_flags_i(exact_src0_flags_r),
    .src0_view_off_i(exact_src0_view_r),
    .src0_ne0_i(exact_src0_ne0_r), .src0_ne1_i(exact_src0_ne1_r),
    .src0_ne2_i(exact_src0_ne2_r), .src0_ne3_i(exact_src0_ne3_r),
    .src0_base_i(macro_src0_iova_q),
    .src0_nb0_i(exact_src0_nb0_r), .src0_nb1_i(exact_src0_nb1_r),
    .src0_nb2_i(exact_src0_nb2_r), .src0_nb3_i(exact_src0_nb3_r),
    .src1_dtype_i(exact_src1_dtype_r), .src1_flags_i(exact_src1_flags_r),
    .src1_view_off_i(exact_src1_view_r),
    .src1_ne0_i(exact_src1_ne0_r), .src1_ne1_i(exact_src1_ne1_r),
    .src1_ne2_i(exact_src1_ne2_r), .src1_ne3_i(exact_src1_ne3_r),
    .src1_base_i(macro_src1_iova_q),
    .src1_nb0_i(exact_src1_nb0_r), .src1_nb1_i(exact_src1_nb1_r),
    .src1_nb2_i(exact_src1_nb2_r), .src1_nb3_i(exact_src1_nb3_r),
    .dst_dtype_i(exact_dst_dtype_r), .dst_flags_i(exact_dst_flags_r),
    .dst_view_off_i(exact_dst_view_r),
    .dst_ne0_i(exact_dst_ne0_r), .dst_ne1_i(exact_dst_ne1_r),
    .dst_ne2_i(exact_dst_ne2_r), .dst_ne3_i(exact_dst_ne3_r),
    .dst_base_i(macro_dst_iova_q),
    .dst_nb0_i(exact_dst_nb0_r), .dst_nb1_i(exact_dst_nb1_r),
    .dst_nb2_i(exact_dst_nb2_r), .dst_nb3_i(exact_dst_nb3_r),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(ssm_gmem_req_valid_w),
    .gmem_req_ready_i(ssm_gmem_req_ready_w),
    .gmem_req_write_o(ssm_gmem_req_write_w),
    .gmem_req_addr_o(ssm_gmem_req_addr_w),
    .gmem_req_wdata_o(ssm_gmem_req_wdata_w),
    .gmem_req_wstrb_o(ssm_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(ssm_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(ssm_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(ssm_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(ssm_gmem_rsp_error_w),
    .completion_valid_o(ssm_adapter_completion_valid_w),
    .dst_commit_o(ssm_adapter_dst_commit_w),
    .completion_command_id_o(ssm_adapter_completion_command_id_w),
    .completion_canonical_node_id_lo_o(ssm_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(ssm_adapter_completion_node_hi_w),
    .completion_npu_required_o(ssm_adapter_completion_required_w),
    .completion_manifest_op_id_o(ssm_adapter_completion_manifest_op_w),
    .completion_source_arity_o(ssm_adapter_completion_arity_w),
    .completion_profile_id_o(ssm_adapter_completion_profile_w),
    .completion_kernel_id_o(ssm_adapter_completion_kernel_w),
    .completion_operator_census_o(ssm_adapter_operator_census_w),
    .completion_profile_census_o(ssm_adapter_profile_census_w),
    .done_o(ssm_adapter_done_w), .error_o(ssm_adapter_error_w),
    .error_code_o(ssm_adapter_error_code_w),
    .numeric_flags_o(ssm_adapter_numeric_flags_w),
    .poisoned_o(ssm_adapter_poisoned_w),
    .outputs_computed_o(ssm_adapter_outputs_computed_w),
    .outputs_completed_o(ssm_adapter_outputs_completed_w),
    .source0_words_completed_o(ssm_adapter_src0_words_w),
    .source1_words_completed_o(ssm_adapter_src1_words_w),
    .work_items_completed_o(ssm_adapter_work_items_w),
    .gmem_read_requests_o(ssm_adapter_read_requests_w),
    .gmem_read_responses_o(ssm_adapter_read_responses_w),
    .read_payload_bytes_o(ssm_adapter_read_bytes_w),
    .gmem_write_requests_o(ssm_adapter_write_requests_w),
    .gmem_write_responses_o(ssm_adapter_write_responses_w),
    .write_payload_bytes_o(ssm_adapter_write_bytes_w),
    .mul_requests_o(ssm_adapter_mul_requests_w),
    .mul_responses_o(ssm_adapter_mul_responses_w),
    .add_requests_o(ssm_adapter_add_requests_w),
    .add_responses_o(ssm_adapter_add_responses_w),
    .active_cycles_o(ssm_adapter_active_cycles_w),
    .gmem_outstanding_o(ssm_adapter_gmem_outstanding_w),
    .numeric_outstanding_o(ssm_adapter_numeric_outstanding_w),
    .gmem_drain_o(ssm_adapter_gmem_drain_w)
  );

  // Frozen MOVER/SET_ROWS profiles.  SET_ROWS source 2 is the old private
  // destination backing dependency and is proved by equality to dst; it does
  // not create a fourth public capability or a host copy operation.
  wire mover_adapter_start_w, mover_adapter_ready_w, mover_adapter_busy_w;
  wire mover_adapter_completion_valid_w, mover_adapter_dst_commit_w;
  wire mover_adapter_done_w, mover_adapter_error_w;
  wire [4:0] mover_adapter_error_code_w, mover_adapter_child_error_w;
  wire [63:0] mover_adapter_completion_command_w;
  wire [63:0] mover_adapter_completion_node_lo_w;
  wire [63:0] mover_adapter_completion_node_hi_w;
  wire mover_adapter_completion_required_w;
  wire [2:0] mover_adapter_completion_operation_w;
  wire [31:0] mover_adapter_completion_kernel_w;
  wire [63:0] mover_adapter_indices_w, mover_adapter_source_elements_w;
  wire [63:0] mover_adapter_elements_w;
  wire [63:0] mover_adapter_read_beats_w, mover_adapter_read_responses_w;
  wire [63:0] mover_adapter_read_bytes_w;
  wire [63:0] mover_adapter_write_beats_w, mover_adapter_write_responses_w;
  wire [63:0] mover_adapter_write_bytes_w;
  wire mover_adapter_gmem_outstanding_w;
  wire mover_gmem_req_valid_w, mover_gmem_req_ready_w;
  wire mover_gmem_req_write_w;
  wire [63:0] mover_gmem_req_addr_w, mover_gmem_req_wdata_w;
  wire [7:0] mover_gmem_req_wstrb_w;
  wire mover_gmem_rsp_valid_w, mover_gmem_rsp_ready_w;
  wire [63:0] mover_gmem_rsp_rdata_w;
  wire mover_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [63:0] mover_adapter_child_cycles_w, mover_adapter_active_cycles_w;
  wire [63:0] mover_adapter_required_issued_w;
  wire [63:0] mover_adapter_required_completed_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign mover_adapter_start_w = (state_q == ST_MACRO_START) &&
                                 macro_select_mover_set_w &&
                                 batch2_static_descriptor_valid_w &&
                                 !batch2_empty_cpy_w &&
                                 !functional_command_select_w;

  // The largest frozen CPY profile performs 262144 single-outstanding reads
  // and writes.  Keep a finite command watchdog, but size it above that
  // protocol-derived legal bound; the child's 512-cycle no-progress watchdog
  // remains independently active for stalled credits/responses.
  TensorNpuMoverSetRowsWritebackAdapter #(
    .COMMAND_TIMEOUT_CYCLES(4194304)
  )
      u_mover_set_rows_writeback_adapter (
    .clk_i(clk), .rst_i(rst), .start_i(mover_adapter_start_w),
    .ready_o(mover_adapter_ready_w), .busy_o(mover_adapter_busy_w),
    .operation_i(batch2_operation_r),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .dst_descriptor_flags_i(batch2_dst_flags_r),
    .op_params_i(batch2_op_params_r),
    .source_arity_i(batch2_source_arity_r),
    .src0_descriptor_flags_i(batch2_src0_flags_r),
    .src1_descriptor_flags_i(batch2_src1_flags_r),
    .src2_descriptor_flags_i(batch2_src2_flags_r),
    .src2_matches_dst_i(macro_select_set_rows_w &&
                        (macro_src2_iova_q == macro_dst_iova_q)),
    .src0_dtype_i(batch2_src0_dtype_r),
    // Region bases are root-allocation bases.  The semantic macro IOVAs
    // already include view offsets, so feeding them here would apply every
    // non-zero view twice in the child preflight and address generator.
    .src0_region_base_i(macro_src0_window_base_q),
    .src0_region_size_i(batch2_src0_region_size_r),
    .src0_view_off_i(batch2_src0_view_r),
    .src0_ne0_i(batch2_src0_ne0_r), .src0_ne1_i(batch2_src0_ne1_r),
    .src0_ne2_i(batch2_src0_ne2_r), .src0_ne3_i(batch2_src0_ne3_r),
    .src0_nb0_i(batch2_src0_nb0_r), .src0_nb1_i(batch2_src0_nb1_r),
    .src0_nb2_i(batch2_src0_nb2_r), .src0_nb3_i(batch2_src0_nb3_r),
    .src1_dtype_i(batch2_src1_dtype_r),
    .src1_region_base_i(macro_src1_window_base_q),
    .src1_region_size_i(batch2_src1_region_size_r),
    .src1_view_off_i(batch2_src1_view_r),
    .src1_ne0_i(batch2_src1_ne0_r), .src1_ne1_i(batch2_src1_ne1_r),
    .src1_ne2_i(batch2_src1_ne2_r), .src1_ne3_i(batch2_src1_ne3_r),
    .src1_nb0_i(batch2_src1_nb0_r), .src1_nb1_i(batch2_src1_nb1_r),
    .src1_nb2_i(batch2_src1_nb2_r), .src1_nb3_i(batch2_src1_nb3_r),
    .dst_dtype_i(batch2_dst_dtype_r),
    .dst_region_base_i(macro_dst_window_base_q),
    .dst_region_size_i(batch2_dst_region_size_r),
    .dst_view_off_i(batch2_dst_view_r),
    .dst_ne0_i(batch2_dst_ne0_r), .dst_ne1_i(batch2_dst_ne1_r),
    .dst_ne2_i(batch2_dst_ne2_r), .dst_ne3_i(batch2_dst_ne3_r),
    .dst_nb0_i(batch2_dst_nb0_r), .dst_nb1_i(batch2_dst_nb1_r),
    .dst_nb2_i(batch2_dst_nb2_r), .dst_nb3_i(batch2_dst_nb3_r),
    .cache_capacity_i(macro_select_set_rows_w ? 32'd256 : 32'd0),
    .physical_slot_i(macro_select_set_rows_w ? macro_scalar1_q : 32'd0),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(mover_gmem_req_valid_w),
    .gmem_req_ready_i(mover_gmem_req_ready_w),
    .gmem_req_write_o(mover_gmem_req_write_w),
    .gmem_req_addr_o(mover_gmem_req_addr_w),
    .gmem_req_wdata_o(mover_gmem_req_wdata_w),
    .gmem_req_wstrb_o(mover_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(mover_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(mover_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(mover_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(mover_gmem_rsp_error_w),
    .completion_valid_o(mover_adapter_completion_valid_w),
    .dst_commit_o(mover_adapter_dst_commit_w),
    .completion_command_id_o(mover_adapter_completion_command_w),
    .completion_canonical_node_id_lo_o(mover_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(mover_adapter_completion_node_hi_w),
    .completion_npu_required_o(mover_adapter_completion_required_w),
    .completion_operation_o(mover_adapter_completion_operation_w),
    .completion_kernel_id_o(mover_adapter_completion_kernel_w),
    .done_o(mover_adapter_done_w), .error_o(mover_adapter_error_w),
    .error_code_o(mover_adapter_error_code_w),
    .child_error_code_o(mover_adapter_child_error_w),
    .indices_completed_o(mover_adapter_indices_w),
    .source_elements_completed_o(mover_adapter_source_elements_w),
    .elements_completed_o(mover_adapter_elements_w),
    .gmem_read_beats_o(mover_adapter_read_beats_w),
    .gmem_read_responses_o(mover_adapter_read_responses_w),
    .read_payload_bytes_o(mover_adapter_read_bytes_w),
    .gmem_write_beats_o(mover_adapter_write_beats_w),
    .gmem_write_responses_o(mover_adapter_write_responses_w),
    .write_payload_bytes_o(mover_adapter_write_bytes_w),
    .child_active_cycles_o(mover_adapter_child_cycles_w),
    .active_cycles_o(mover_adapter_active_cycles_w),
    .gmem_outstanding_o(mover_adapter_gmem_outstanding_w),
    .npu_required_issued_o(mover_adapter_required_issued_w),
    .npu_required_completed_o(mover_adapter_required_completed_w)
  );

  wire attention_adapter_start_w, attention_adapter_ready_w;
  wire attention_adapter_busy_w, attention_adapter_completion_valid_w;
  wire attention_adapter_dst_commit_w, attention_adapter_done_w;
  wire attention_adapter_error_w;
  wire [4:0] attention_adapter_error_code_w;
  wire [63:0] attention_adapter_completion_command_w;
  wire [63:0] attention_adapter_completion_node_lo_w;
  wire [63:0] attention_adapter_completion_node_hi_w;
  wire attention_adapter_completion_required_w;
  wire [15:0] attention_adapter_completion_manifest_op_w;
  wire [2:0] attention_adapter_completion_arity_w;
  wire [7:0] attention_adapter_completion_profile_w;
  wire [31:0] attention_adapter_completion_kernel_w;
  wire [31:0] attention_adapter_operator_census_w;
  wire [31:0] attention_adapter_profile_census_w;
  wire [63:0] attention_adapter_outputs_computed_w;
  wire [63:0] attention_adapter_outputs_completed_w;
  wire [63:0] attention_adapter_src0_words_w;
  wire [63:0] attention_adapter_src1_words_w;
  wire [63:0] attention_adapter_conversion_words_w;
  wire [63:0] attention_adapter_work_items_w;
  wire [63:0] attention_adapter_read_requests_w;
  wire [63:0] attention_adapter_read_responses_w;
  wire [63:0] attention_adapter_read_bytes_w;
  wire [63:0] attention_adapter_write_requests_w;
  wire [63:0] attention_adapter_write_responses_w;
  wire [63:0] attention_adapter_write_bytes_w;
  wire attention_adapter_gmem_outstanding_w;
  wire attention_gmem_req_valid_w, attention_gmem_req_ready_w;
  wire attention_gmem_req_write_w;
  wire [63:0] attention_gmem_req_addr_w, attention_gmem_req_wdata_w;
  wire [7:0] attention_gmem_req_wstrb_w;
  wire attention_gmem_rsp_valid_w, attention_gmem_rsp_ready_w;
  wire [63:0] attention_gmem_rsp_rdata_w;
  wire attention_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [4:0] attention_adapter_numeric_flags_w;
  wire [2:0] attention_adapter_conversion_flags_w;
  wire attention_adapter_poisoned_w;
  wire [63:0] attention_adapter_fma_requests_w;
  wire [63:0] attention_adapter_fma_responses_w;
  wire [63:0] attention_adapter_reduction_requests_w;
  wire [63:0] attention_adapter_reduction_responses_w;
  wire [63:0] attention_adapter_active_cycles_w;
  wire attention_adapter_numeric_outstanding_w;
  wire attention_adapter_gmem_drain_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign attention_adapter_start_w = (state_q == ST_MACRO_START) &&
                                     macro_select_attention_w &&
                                     batch2_static_descriptor_valid_w;

  TensorNpuF16AttentionMatmulWritebackAdapter
      u_f16_attention_matmul_writeback_adapter (
    .clk_i(clk), .rst_i(rst), .start_i(attention_adapter_start_w),
    .ready_o(attention_adapter_ready_w), .busy_o(attention_adapter_busy_w),
    .manifest_op_id_i(batch2_manifest_op_r),
    .source_arity_i(batch2_source_arity_r),
    .op_params_i(batch2_op_params_r[127:0]),
    .op_params_tail_zero_i(batch2_op_params_r[511:128] == 384'd0),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .src0_dtype_i(batch2_src0_dtype_r),
    .src0_flags_i(batch2_src0_flags_r),
    .src0_view_off_i(batch2_src0_view_r),
    .src0_ne0_i(batch2_src0_ne0_r), .src0_ne1_i(batch2_src0_ne1_r),
    .src0_ne2_i(batch2_src0_ne2_r), .src0_ne3_i(batch2_src0_ne3_r),
    .src0_base_i(macro_src0_iova_q),
    .src0_nb0_i(batch2_src0_nb0_r), .src0_nb1_i(batch2_src0_nb1_r),
    .src0_nb2_i(batch2_src0_nb2_r), .src0_nb3_i(batch2_src0_nb3_r),
    .src1_dtype_i(batch2_src1_dtype_r),
    .src1_flags_i(batch2_src1_flags_r),
    .src1_view_off_i(batch2_src1_view_r),
    .src1_ne0_i(batch2_src1_ne0_r), .src1_ne1_i(batch2_src1_ne1_r),
    .src1_ne2_i(batch2_src1_ne2_r), .src1_ne3_i(batch2_src1_ne3_r),
    .src1_base_i(macro_src1_iova_q),
    .src1_nb0_i(batch2_src1_nb0_r), .src1_nb1_i(batch2_src1_nb1_r),
    .src1_nb2_i(batch2_src1_nb2_r), .src1_nb3_i(batch2_src1_nb3_r),
    .dst_dtype_i(batch2_dst_dtype_r), .dst_flags_i(batch2_dst_flags_r),
    .dst_view_off_i(batch2_dst_view_r),
    .dst_ne0_i(batch2_dst_ne0_r), .dst_ne1_i(batch2_dst_ne1_r),
    .dst_ne2_i(batch2_dst_ne2_r), .dst_ne3_i(batch2_dst_ne3_r),
    .dst_base_i(macro_dst_iova_q),
    .dst_nb0_i(batch2_dst_nb0_r), .dst_nb1_i(batch2_dst_nb1_r),
    .dst_nb2_i(batch2_dst_nb2_r), .dst_nb3_i(batch2_dst_nb3_r),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(attention_gmem_req_valid_w),
    .gmem_req_ready_i(attention_gmem_req_ready_w),
    .gmem_req_write_o(attention_gmem_req_write_w),
    .gmem_req_addr_o(attention_gmem_req_addr_w),
    .gmem_req_wdata_o(attention_gmem_req_wdata_w),
    .gmem_req_wstrb_o(attention_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(attention_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(attention_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(attention_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(attention_gmem_rsp_error_w),
    .completion_valid_o(attention_adapter_completion_valid_w),
    .dst_commit_o(attention_adapter_dst_commit_w),
    .completion_command_id_o(attention_adapter_completion_command_w),
    .completion_canonical_node_id_lo_o(attention_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(attention_adapter_completion_node_hi_w),
    .completion_npu_required_o(attention_adapter_completion_required_w),
    .completion_manifest_op_id_o(attention_adapter_completion_manifest_op_w),
    .completion_source_arity_o(attention_adapter_completion_arity_w),
    .completion_profile_id_o(attention_adapter_completion_profile_w),
    .completion_kernel_id_o(attention_adapter_completion_kernel_w),
    .completion_operator_census_o(attention_adapter_operator_census_w),
    .completion_profile_census_o(attention_adapter_profile_census_w),
    .done_o(attention_adapter_done_w), .error_o(attention_adapter_error_w),
    .error_code_o(attention_adapter_error_code_w),
    .numeric_flags_o(attention_adapter_numeric_flags_w),
    .conversion_flags_o(attention_adapter_conversion_flags_w),
    .poisoned_o(attention_adapter_poisoned_w),
    .outputs_computed_o(attention_adapter_outputs_computed_w),
    .outputs_completed_o(attention_adapter_outputs_completed_w),
    .source0_half_words_completed_o(attention_adapter_src0_words_w),
    .source1_float_words_completed_o(attention_adapter_src1_words_w),
    .conversion_words_completed_o(attention_adapter_conversion_words_w),
    .work_items_completed_o(attention_adapter_work_items_w),
    .gmem_read_requests_o(attention_adapter_read_requests_w),
    .gmem_read_responses_o(attention_adapter_read_responses_w),
    .read_payload_bytes_o(attention_adapter_read_bytes_w),
    .gmem_write_requests_o(attention_adapter_write_requests_w),
    .gmem_write_responses_o(attention_adapter_write_responses_w),
    .write_payload_bytes_o(attention_adapter_write_bytes_w),
    .fma_requests_o(attention_adapter_fma_requests_w),
    .fma_responses_o(attention_adapter_fma_responses_w),
    .reduction_requests_o(attention_adapter_reduction_requests_w),
    .reduction_responses_o(attention_adapter_reduction_responses_w),
    .active_cycles_o(attention_adapter_active_cycles_w),
    .gmem_outstanding_o(attention_adapter_gmem_outstanding_w),
    .numeric_outstanding_o(attention_adapter_numeric_outstanding_w),
    .gmem_drain_o(attention_adapter_gmem_drain_w)
  );

  wire softmax_adapter_start_w, softmax_adapter_ready_w;
  wire softmax_adapter_busy_w, softmax_adapter_completion_valid_w;
  wire softmax_adapter_dst_commit_w, softmax_adapter_done_w;
  wire softmax_adapter_error_w;
  wire [4:0] softmax_adapter_error_code_w;
  wire [63:0] softmax_adapter_completion_command_w;
  wire [63:0] softmax_adapter_completion_node_lo_w;
  wire [63:0] softmax_adapter_completion_node_hi_w;
  wire softmax_adapter_completion_required_w;
  wire [2:0] softmax_adapter_completion_reduce_op_w;
  wire [15:0] softmax_adapter_completion_manifest_op_w;
  wire [2:0] softmax_adapter_completion_arity_w;
  wire [7:0] softmax_adapter_completion_profile_w;
  wire [31:0] softmax_adapter_completion_kernel_w;
  wire [31:0] softmax_adapter_operator_census_w;
  wire [31:0] softmax_adapter_profile_census_w;
  wire [63:0] softmax_adapter_rows_w, softmax_adapter_src0_words_w;
  wire [63:0] softmax_adapter_mask_words_w;
  wire [63:0] softmax_adapter_outputs_computed_w;
  wire [63:0] softmax_adapter_outputs_completed_w;
  wire [63:0] softmax_adapter_max_comparisons_w;
  wire [63:0] softmax_adapter_read_requests_w;
  wire [63:0] softmax_adapter_read_responses_w;
  wire [63:0] softmax_adapter_read_bytes_w;
  wire [63:0] softmax_adapter_write_requests_w;
  wire [63:0] softmax_adapter_write_responses_w;
  wire [63:0] softmax_adapter_write_bytes_w;
  wire softmax_adapter_gmem_outstanding_w;
  wire softmax_gmem_req_valid_w, softmax_gmem_req_ready_w;
  wire softmax_gmem_req_write_w;
  wire [63:0] softmax_gmem_req_addr_w, softmax_gmem_req_wdata_w;
  wire [7:0] softmax_gmem_req_wstrb_w;
  wire softmax_gmem_rsp_valid_w, softmax_gmem_rsp_ready_w;
  wire [63:0] softmax_gmem_rsp_rdata_w;
  wire softmax_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [3:0] softmax_adapter_exp_error_w;
  wire [4:0] softmax_adapter_numeric_flags_w;
  wire softmax_adapter_poisoned_w;
  wire [63:0] softmax_adapter_scale_req_w, softmax_adapter_scale_rsp_w;
  wire [63:0] softmax_adapter_maskadd_req_w, softmax_adapter_maskadd_rsp_w;
  wire [63:0] softmax_adapter_sub_req_w, softmax_adapter_sub_rsp_w;
  wire [63:0] softmax_adapter_exp_req_w, softmax_adapter_exp_rsp_w;
  wire [63:0] softmax_adapter_sum_req_w, softmax_adapter_sum_rsp_w;
  wire [63:0] softmax_adapter_div_req_w, softmax_adapter_div_rsp_w;
  wire [63:0] softmax_adapter_norm_req_w, softmax_adapter_norm_rsp_w;
  wire [63:0] softmax_adapter_exp_cycles_w, softmax_adapter_active_cycles_w;
  wire softmax_adapter_addmul_outstanding_w;
  wire softmax_adapter_exp_outstanding_w, softmax_adapter_div_outstanding_w;
  wire softmax_adapter_gmem_drain_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign softmax_adapter_start_w = (state_q == ST_MACRO_START) &&
                                   macro_select_softmax_w &&
                                   batch2_static_descriptor_valid_w;

  TensorNpuSoftmaxWritebackAdapter u_softmax_writeback_adapter (
    .clk_i(clk), .rst_i(rst), .start_i(softmax_adapter_start_w),
    .ready_o(softmax_adapter_ready_w), .busy_o(softmax_adapter_busy_w),
    .reduce_op_i(3'd6), .manifest_op_id_i(batch2_manifest_op_r),
    .source_arity_i(batch2_source_arity_r),
    .op_params_i(batch2_op_params_r[127:0]),
    .op_params_tail_zero_i(batch2_op_params_r[511:128] == 384'd0),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .src0_dtype_i(batch2_src0_dtype_r),
    .src0_flags_i(batch2_src0_flags_r),
    .src0_view_off_i(batch2_src0_view_r),
    .src0_ne0_i(batch2_src0_ne0_r), .src0_ne1_i(batch2_src0_ne1_r),
    .src0_ne2_i(batch2_src0_ne2_r), .src0_ne3_i(batch2_src0_ne3_r),
    .src0_base_i(macro_src0_iova_q),
    .src0_nb0_i(batch2_src0_nb0_r), .src0_nb1_i(batch2_src0_nb1_r),
    .src0_nb2_i(batch2_src0_nb2_r), .src0_nb3_i(batch2_src0_nb3_r),
    .src1_dtype_i(batch2_src1_dtype_r),
    .src1_flags_i(batch2_src1_flags_r),
    .src1_view_off_i(batch2_src1_view_r),
    .src1_ne0_i(batch2_src1_ne0_r), .src1_ne1_i(batch2_src1_ne1_r),
    .src1_ne2_i(batch2_src1_ne2_r), .src1_ne3_i(batch2_src1_ne3_r),
    .src1_base_i(macro_src1_iova_q),
    .src1_nb0_i(batch2_src1_nb0_r), .src1_nb1_i(batch2_src1_nb1_r),
    .src1_nb2_i(batch2_src1_nb2_r), .src1_nb3_i(batch2_src1_nb3_r),
    .dst_dtype_i(batch2_dst_dtype_r), .dst_flags_i(batch2_dst_flags_r),
    .dst_view_off_i(batch2_dst_view_r),
    .dst_ne0_i(batch2_dst_ne0_r), .dst_ne1_i(batch2_dst_ne1_r),
    .dst_ne2_i(batch2_dst_ne2_r), .dst_ne3_i(batch2_dst_ne3_r),
    .dst_base_i(macro_dst_iova_q),
    .dst_nb0_i(batch2_dst_nb0_r), .dst_nb1_i(batch2_dst_nb1_r),
    .dst_nb2_i(batch2_dst_nb2_r), .dst_nb3_i(batch2_dst_nb3_r),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(softmax_gmem_req_valid_w),
    .gmem_req_ready_i(softmax_gmem_req_ready_w),
    .gmem_req_write_o(softmax_gmem_req_write_w),
    .gmem_req_addr_o(softmax_gmem_req_addr_w),
    .gmem_req_wdata_o(softmax_gmem_req_wdata_w),
    .gmem_req_wstrb_o(softmax_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(softmax_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(softmax_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(softmax_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(softmax_gmem_rsp_error_w),
    .completion_valid_o(softmax_adapter_completion_valid_w),
    .dst_commit_o(softmax_adapter_dst_commit_w),
    .completion_command_id_o(softmax_adapter_completion_command_w),
    .completion_canonical_node_id_lo_o(softmax_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(softmax_adapter_completion_node_hi_w),
    .completion_npu_required_o(softmax_adapter_completion_required_w),
    .completion_reduce_op_o(softmax_adapter_completion_reduce_op_w),
    .completion_manifest_op_id_o(softmax_adapter_completion_manifest_op_w),
    .completion_source_arity_o(softmax_adapter_completion_arity_w),
    .completion_profile_id_o(softmax_adapter_completion_profile_w),
    .completion_kernel_id_o(softmax_adapter_completion_kernel_w),
    .completion_operator_census_o(softmax_adapter_operator_census_w),
    .completion_profile_census_o(softmax_adapter_profile_census_w),
    .done_o(softmax_adapter_done_w), .error_o(softmax_adapter_error_w),
    .error_code_o(softmax_adapter_error_code_w),
    .exp_error_code_o(softmax_adapter_exp_error_w),
    .numeric_flags_o(softmax_adapter_numeric_flags_w),
    .poisoned_o(softmax_adapter_poisoned_w),
    .rows_completed_o(softmax_adapter_rows_w),
    .source0_words_completed_o(softmax_adapter_src0_words_w),
    .mask_words_completed_o(softmax_adapter_mask_words_w),
    .outputs_computed_o(softmax_adapter_outputs_computed_w),
    .outputs_completed_o(softmax_adapter_outputs_completed_w),
    .max_comparisons_o(softmax_adapter_max_comparisons_w),
    .gmem_read_requests_o(softmax_adapter_read_requests_w),
    .gmem_read_responses_o(softmax_adapter_read_responses_w),
    .read_payload_bytes_o(softmax_adapter_read_bytes_w),
    .gmem_write_requests_o(softmax_adapter_write_requests_w),
    .gmem_write_responses_o(softmax_adapter_write_responses_w),
    .write_payload_bytes_o(softmax_adapter_write_bytes_w),
    .scale_requests_o(softmax_adapter_scale_req_w),
    .scale_responses_o(softmax_adapter_scale_rsp_w),
    .mask_add_requests_o(softmax_adapter_maskadd_req_w),
    .mask_add_responses_o(softmax_adapter_maskadd_rsp_w),
    .subtract_requests_o(softmax_adapter_sub_req_w),
    .subtract_responses_o(softmax_adapter_sub_rsp_w),
    .exp_requests_o(softmax_adapter_exp_req_w),
    .exp_responses_o(softmax_adapter_exp_rsp_w),
    .sum_add_requests_o(softmax_adapter_sum_req_w),
    .sum_add_responses_o(softmax_adapter_sum_rsp_w),
    .div_requests_o(softmax_adapter_div_req_w),
    .div_responses_o(softmax_adapter_div_rsp_w),
    .normalize_mul_requests_o(softmax_adapter_norm_req_w),
    .normalize_mul_responses_o(softmax_adapter_norm_rsp_w),
    .exp_active_cycles_o(softmax_adapter_exp_cycles_w),
    .active_cycles_o(softmax_adapter_active_cycles_w),
    .gmem_outstanding_o(softmax_adapter_gmem_outstanding_w),
    .addmul_outstanding_o(softmax_adapter_addmul_outstanding_w),
    .exp_outstanding_o(softmax_adapter_exp_outstanding_w),
    .div_outstanding_o(softmax_adapter_div_outstanding_w),
    .gmem_drain_o(softmax_adapter_gmem_drain_w)
  );

  wire rope_adapter_start_w, rope_adapter_ready_w, rope_adapter_busy_w;
  wire rope_adapter_completion_valid_w, rope_adapter_dst_commit_w;
  wire rope_adapter_done_w, rope_adapter_error_w;
  wire [4:0] rope_adapter_error_code_w;
  wire [63:0] rope_adapter_completion_command_w;
  wire [63:0] rope_adapter_completion_node_lo_w;
  wire [63:0] rope_adapter_completion_node_hi_w;
  wire rope_adapter_completion_required_w;
  wire [15:0] rope_adapter_completion_manifest_op_w;
  wire [2:0] rope_adapter_completion_arity_w;
  wire [7:0] rope_adapter_completion_profile_w;
  wire [31:0] rope_adapter_completion_kernel_w;
  wire [31:0] rope_adapter_operator_census_w;
  wire [31:0] rope_adapter_profile_census_w;
  wire [63:0] rope_adapter_outputs_computed_w;
  wire [63:0] rope_adapter_outputs_completed_w;
  wire [63:0] rope_adapter_src0_words_w, rope_adapter_position_words_w;
  wire [63:0] rope_adapter_position_conversions_w;
  wire [63:0] rope_adapter_raw_copy_words_w;
  wire [63:0] rope_adapter_rotation_pairs_w;
  wire [63:0] rope_adapter_read_requests_w, rope_adapter_read_responses_w;
  wire [63:0] rope_adapter_read_bytes_w;
  wire [63:0] rope_adapter_write_requests_w, rope_adapter_write_responses_w;
  wire [63:0] rope_adapter_write_bytes_w;
  wire rope_adapter_gmem_outstanding_w;
  wire rope_gmem_req_valid_w, rope_gmem_req_ready_w;
  wire rope_gmem_req_write_w;
  wire [63:0] rope_gmem_req_addr_w, rope_gmem_req_wdata_w;
  wire [7:0] rope_gmem_req_wstrb_w;
  wire rope_gmem_rsp_valid_w, rope_gmem_rsp_ready_w;
  wire [63:0] rope_gmem_rsp_rdata_w;
  wire rope_gmem_rsp_error_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [4:0] rope_adapter_numeric_flags_w;
  wire rope_adapter_poisoned_w;
  wire [63:0] rope_adapter_sincos_req_w, rope_adapter_sincos_rsp_w;
  wire [63:0] rope_adapter_theta_req_w, rope_adapter_theta_rsp_w;
  wire [63:0] rope_adapter_data_mul_req_w, rope_adapter_data_mul_rsp_w;
  wire [63:0] rope_adapter_fma_req_w, rope_adapter_fma_rsp_w;
  wire [63:0] rope_adapter_active_cycles_w;
  wire rope_adapter_numeric_outstanding_w, rope_adapter_gmem_drain_w;
  /* verilator lint_on UNUSEDSIGNAL */

  assign rope_adapter_start_w = (state_q == ST_MACRO_START) &&
                                macro_select_rope_w &&
                                batch2_static_descriptor_valid_w;

  TensorNpuRopeWritebackAdapter u_rope_writeback_adapter (
    .clk_i(clk), .rst_i(rst), .start_i(rope_adapter_start_w),
    .ready_o(rope_adapter_ready_w), .busy_o(rope_adapter_busy_w),
    .manifest_op_id_i(batch2_manifest_op_r),
    .source_arity_i(batch2_source_arity_r),
    .op_params_i(batch2_op_params_r),
    .npu_required_i(macro_command_flags_q[0]),
    .command_id_i(macro_sequence_id_q),
    .canonical_node_id_lo_i(macro_node_hash_lo_q),
    .canonical_node_id_hi_i(macro_node_hash_hi_q),
    .dst_shadow_private_i(macro_dst_window_perm_q == 2'b10),
    .windows_generation_valid_i(macro_windows_generation_valid_q),
    .src0_dtype_i(batch2_src0_dtype_r),
    .src0_flags_i(batch2_src0_flags_r),
    .src0_view_off_i(batch2_src0_view_r),
    .src0_ne0_i(batch2_src0_ne0_r), .src0_ne1_i(batch2_src0_ne1_r),
    .src0_ne2_i(batch2_src0_ne2_r), .src0_ne3_i(batch2_src0_ne3_r),
    .src0_base_i(macro_src0_iova_q),
    .src0_nb0_i(batch2_src0_nb0_r), .src0_nb1_i(batch2_src0_nb1_r),
    .src0_nb2_i(batch2_src0_nb2_r), .src0_nb3_i(batch2_src0_nb3_r),
    .src1_dtype_i(batch2_src1_dtype_r),
    .src1_flags_i(batch2_src1_flags_r),
    .src1_view_off_i(batch2_src1_view_r),
    .src1_ne0_i(batch2_src1_ne0_r), .src1_ne1_i(batch2_src1_ne1_r),
    .src1_ne2_i(batch2_src1_ne2_r), .src1_ne3_i(batch2_src1_ne3_r),
    .src1_base_i(macro_src1_iova_q),
    .src1_nb0_i(batch2_src1_nb0_r), .src1_nb1_i(batch2_src1_nb1_r),
    .src1_nb2_i(batch2_src1_nb2_r), .src1_nb3_i(batch2_src1_nb3_r),
    .dst_dtype_i(batch2_dst_dtype_r), .dst_flags_i(batch2_dst_flags_r),
    .dst_view_off_i(batch2_dst_view_r),
    .dst_ne0_i(batch2_dst_ne0_r), .dst_ne1_i(batch2_dst_ne1_r),
    .dst_ne2_i(batch2_dst_ne2_r), .dst_ne3_i(batch2_dst_ne3_r),
    .dst_base_i(macro_dst_iova_q),
    .dst_nb0_i(batch2_dst_nb0_r), .dst_nb1_i(batch2_dst_nb1_r),
    .dst_nb2_i(batch2_dst_nb2_r), .dst_nb3_i(batch2_dst_nb3_r),
    .src0_window_base_i(macro_src0_window_base_q),
    .src0_window_bytes_i(macro_src0_window_size_q),
    .src0_window_read_i(macro_src0_window_perm_q[0]),
    .src0_window_write_i(macro_src0_window_perm_q[1]),
    .src1_window_base_i(macro_src1_window_base_q),
    .src1_window_bytes_i(macro_src1_window_size_q),
    .src1_window_read_i(macro_src1_window_perm_q[0]),
    .src1_window_write_i(macro_src1_window_perm_q[1]),
    .dst_window_base_i(macro_dst_window_base_q),
    .dst_window_bytes_i(macro_dst_window_size_q),
    .dst_window_read_i(macro_dst_window_perm_q[0]),
    .dst_window_write_i(macro_dst_window_perm_q[1]),
    .gmem_req_valid_o(rope_gmem_req_valid_w),
    .gmem_req_ready_i(rope_gmem_req_ready_w),
    .gmem_req_write_o(rope_gmem_req_write_w),
    .gmem_req_addr_o(rope_gmem_req_addr_w),
    .gmem_req_wdata_o(rope_gmem_req_wdata_w),
    .gmem_req_wstrb_o(rope_gmem_req_wstrb_w),
    .gmem_rsp_valid_i(rope_gmem_rsp_valid_w),
    .gmem_rsp_ready_o(rope_gmem_rsp_ready_w),
    .gmem_rsp_rdata_i(rope_gmem_rsp_rdata_w),
    .gmem_rsp_error_i(rope_gmem_rsp_error_w),
    .completion_valid_o(rope_adapter_completion_valid_w),
    .dst_commit_o(rope_adapter_dst_commit_w),
    .completion_command_id_o(rope_adapter_completion_command_w),
    .completion_canonical_node_id_lo_o(rope_adapter_completion_node_lo_w),
    .completion_canonical_node_id_hi_o(rope_adapter_completion_node_hi_w),
    .completion_npu_required_o(rope_adapter_completion_required_w),
    .completion_manifest_op_id_o(rope_adapter_completion_manifest_op_w),
    .completion_source_arity_o(rope_adapter_completion_arity_w),
    .completion_profile_id_o(rope_adapter_completion_profile_w),
    .completion_kernel_id_o(rope_adapter_completion_kernel_w),
    .completion_operator_census_o(rope_adapter_operator_census_w),
    .completion_profile_census_o(rope_adapter_profile_census_w),
    .done_o(rope_adapter_done_w), .error_o(rope_adapter_error_w),
    .error_code_o(rope_adapter_error_code_w),
    .numeric_flags_o(rope_adapter_numeric_flags_w),
    .poisoned_o(rope_adapter_poisoned_w),
    .outputs_computed_o(rope_adapter_outputs_computed_w),
    .outputs_completed_o(rope_adapter_outputs_completed_w),
    .source0_words_completed_o(rope_adapter_src0_words_w),
    .position_words_completed_o(rope_adapter_position_words_w),
    .position_conversions_completed_o(rope_adapter_position_conversions_w),
    .raw_copy_words_completed_o(rope_adapter_raw_copy_words_w),
    .rotation_pairs_completed_o(rope_adapter_rotation_pairs_w),
    .gmem_read_requests_o(rope_adapter_read_requests_w),
    .gmem_read_responses_o(rope_adapter_read_responses_w),
    .read_payload_bytes_o(rope_adapter_read_bytes_w),
    .gmem_write_requests_o(rope_adapter_write_requests_w),
    .gmem_write_responses_o(rope_adapter_write_responses_w),
    .write_payload_bytes_o(rope_adapter_write_bytes_w),
    .sincos_requests_o(rope_adapter_sincos_req_w),
    .sincos_responses_o(rope_adapter_sincos_rsp_w),
    .theta_mul_requests_o(rope_adapter_theta_req_w),
    .theta_mul_responses_o(rope_adapter_theta_rsp_w),
    .data_mul_requests_o(rope_adapter_data_mul_req_w),
    .data_mul_responses_o(rope_adapter_data_mul_rsp_w),
    .fma_requests_o(rope_adapter_fma_req_w),
    .fma_responses_o(rope_adapter_fma_rsp_w),
    .active_cycles_o(rope_adapter_active_cycles_w),
    .gmem_outstanding_o(rope_adapter_gmem_outstanding_w),
    .numeric_outstanding_o(rope_adapter_numeric_outstanding_w),
    .gmem_drain_o(rope_adapter_gmem_drain_w)
  );

  reg [`NPU_ERROR_W-1:0] q8_mapped_error_code_r;
  reg [31:0] q8_mapped_error_class_r;
  always @(*) begin
    q8_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
    q8_mapped_error_class_r = ABI_ERROR_PROTOCOL;
    case (q8_adapter_error_code_w)
      5'd1: begin
        q8_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
        q8_mapped_error_class_r = ABI_ERROR_LAYOUT;
      end
      5'd2, 5'd3, 5'd4, 5'd5: begin
        q8_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
        q8_mapped_error_class_r = ABI_ERROR_IOVA;
      end
      5'd6: begin
        case (q8_adapter_engine_error_code_w)
          5'd1: begin
            q8_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
            q8_mapped_error_class_r = ABI_ERROR_LAYOUT;
          end
          5'd2, 5'd3, 5'd4: begin
            q8_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
            q8_mapped_error_class_r = ABI_ERROR_IOVA;
          end
          5'd5: begin
            q8_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
            q8_mapped_error_class_r = ABI_ERROR_GMEM;
          end
          5'd8, 5'd9: begin
            q8_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
            q8_mapped_error_class_r = ABI_ERROR_TIMEOUT;
          end
          default: begin
            q8_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
            q8_mapped_error_class_r = ABI_ERROR_PROTOCOL;
          end
        endcase
      end
      5'd8: begin
        q8_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
        q8_mapped_error_class_r = ABI_ERROR_GMEM;
      end
      5'd9, 5'd10: begin
        q8_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
        q8_mapped_error_class_r = ABI_ERROR_TIMEOUT;
      end
      default: begin
        q8_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
        q8_mapped_error_class_r = ABI_ERROR_PROTOCOL;
      end
    endcase
  end

  reg [`NPU_ERROR_W-1:0] gemv_mapped_error_code_r;
  reg [31:0] gemv_mapped_error_class_r;
  always @(*) begin
    gemv_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
    gemv_mapped_error_class_r = ABI_ERROR_PROTOCOL;
    case (gemv_adapter_error_code_w)
      5'd1: begin
        gemv_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
        gemv_mapped_error_class_r = ABI_ERROR_LAYOUT;
      end
      5'd2, 5'd3, 5'd4, 5'd5: begin
        gemv_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
        gemv_mapped_error_class_r = ABI_ERROR_IOVA;
      end
      5'd6: begin
        case (gemv_adapter_child_error_code_w)
          8'h10, 8'h11, 8'h12,
          8'h21, 8'h22, 8'h23, 8'h24,
          8'h31, 8'h32, 8'h33, 8'h34: begin
            gemv_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
            gemv_mapped_error_class_r = ABI_ERROR_LAYOUT;
          end
          8'h40, 8'h41, 8'h42, 8'h50: begin
            gemv_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
            gemv_mapped_error_class_r = ABI_ERROR_TIMEOUT;
          end
          default: begin
            gemv_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
            gemv_mapped_error_class_r = ABI_ERROR_PROTOCOL;
          end
        endcase
      end
      5'd8: begin
        gemv_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
        gemv_mapped_error_class_r = ABI_ERROR_GMEM;
      end
      5'd9, 5'd10: begin
        gemv_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
        gemv_mapped_error_class_r = ABI_ERROR_TIMEOUT;
      end
      default: begin
        gemv_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
        gemv_mapped_error_class_r = ABI_ERROR_PROTOCOL;
      end
    endcase
  end

  reg [`NPU_ERROR_W-1:0] f32_move_mapped_error_code_r;
  reg [31:0] f32_move_mapped_error_class_r;
  always @(*) begin
    f32_move_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
    f32_move_mapped_error_class_r = ABI_ERROR_PROTOCOL;
    case (f32_move_adapter_error_code_w)
      5'd1, 5'd6: begin
        f32_move_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
        f32_move_mapped_error_class_r = ABI_ERROR_LAYOUT;
      end
      5'd2, 5'd3, 5'd4, 5'd5: begin
        f32_move_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
        f32_move_mapped_error_class_r = ABI_ERROR_IOVA;
      end
      5'd7: begin
        f32_move_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
        f32_move_mapped_error_class_r = ABI_ERROR_GMEM;
      end
      5'd8, 5'd9: begin
        f32_move_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
        f32_move_mapped_error_class_r = ABI_ERROR_TIMEOUT;
      end
      default: begin
        f32_move_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
        f32_move_mapped_error_class_r = ABI_ERROR_PROTOCOL;
      end
    endcase
  end

  reg [`NPU_ERROR_W-1:0] exact_mapped_error_code_r;
  reg [31:0] exact_mapped_error_class_r;
  always @(*) begin
    exact_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
    exact_mapped_error_class_r = ABI_ERROR_PROTOCOL;
    if (macro_select_unary_glu_w) begin
      case (unary_glu_adapter_error_code_w)
        5'd1: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
          exact_mapped_error_class_r = ABI_ERROR_LAYOUT;
        end
        5'd2, 5'd3, 5'd4, 5'd5: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
          exact_mapped_error_class_r = ABI_ERROR_IOVA;
        end
        5'd7: begin
          exact_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
          exact_mapped_error_class_r = ABI_ERROR_GMEM;
        end
        5'd8, 5'd9: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
          exact_mapped_error_class_r = ABI_ERROR_TIMEOUT;
        end
        default: begin end
      endcase
    end else if (macro_select_norm_w) begin
      case (norm_adapter_error_code_w)
        5'd1: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
          exact_mapped_error_class_r = ABI_ERROR_LAYOUT;
        end
        5'd2, 5'd3, 5'd4, 5'd5: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
          exact_mapped_error_class_r = ABI_ERROR_IOVA;
        end
        5'd7: begin
          exact_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
          exact_mapped_error_class_r = ABI_ERROR_GMEM;
        end
        5'd8, 5'd9: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
          exact_mapped_error_class_r = ABI_ERROR_TIMEOUT;
        end
        default: begin end
      endcase
    end else if (macro_select_sum_w) begin
      if ((sum_adapter_error_code_w == 5'd1)) begin
        exact_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
        exact_mapped_error_class_r = ABI_ERROR_LAYOUT;
      end else if ((sum_adapter_error_code_w >= 5'd2) &&
                   (sum_adapter_error_code_w <= 5'd5)) begin
        exact_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
        exact_mapped_error_class_r = ABI_ERROR_IOVA;
      end else if ((sum_adapter_error_code_w == 5'd6) &&
                   (sum_adapter_engine_error_w == 5'd9)) begin
        exact_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
        exact_mapped_error_class_r = ABI_ERROR_GMEM;
      end else if ((sum_adapter_error_code_w == 5'd6) &&
                   ((sum_adapter_engine_error_w == 5'd12) ||
                    (sum_adapter_engine_error_w == 5'd13) ||
                    (sum_adapter_engine_error_w == 5'd15))) begin
        exact_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
        exact_mapped_error_class_r = ABI_ERROR_TIMEOUT;
      end
    end else if (macro_select_ssm_w) begin
      case (ssm_adapter_error_code_w)
        5'd1: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
          exact_mapped_error_class_r = ABI_ERROR_LAYOUT;
        end
        5'd2, 5'd3, 5'd4, 5'd5: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
          exact_mapped_error_class_r = ABI_ERROR_IOVA;
        end
        5'd6: begin
          exact_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
          exact_mapped_error_class_r = ABI_ERROR_GMEM;
        end
        5'd8, 5'd9: begin
          exact_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
          exact_mapped_error_class_r = ABI_ERROR_TIMEOUT;
        end
        default: begin end
      endcase
    end
  end

  reg [`NPU_ERROR_W-1:0] batch2_mapped_error_code_r;
  reg [31:0] batch2_mapped_error_class_r;
  reg [4:0] batch2_selected_child_error_r;
  always @(*) begin
    batch2_mapped_error_code_r = `NPU_ERR_MACRO_PROTOCOL;
    batch2_mapped_error_class_r = ABI_ERROR_PROTOCOL;
    batch2_selected_child_error_r = macro_select_mover_set_w ?
        mover_adapter_error_code_w : (macro_select_attention_w ?
        attention_adapter_error_code_w : (macro_select_softmax_w ?
        softmax_adapter_error_code_w : (macro_select_rope_w ?
        rope_adapter_error_code_w : 5'd0)));
    if (macro_select_mover_set_w) begin
      case (batch2_selected_child_error_r)
        5'd1, 5'd2, 5'd12: begin
          batch2_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
          batch2_mapped_error_class_r = ABI_ERROR_LAYOUT;
        end
        5'd3, 5'd4, 5'd5, 5'd6: begin
          batch2_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
          batch2_mapped_error_class_r = ABI_ERROR_IOVA;
        end
        5'd9: begin
          batch2_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
          batch2_mapped_error_class_r = ABI_ERROR_GMEM;
        end
        5'd10, 5'd11: begin
          batch2_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
          batch2_mapped_error_class_r = ABI_ERROR_TIMEOUT;
        end
        default: begin end
      endcase
    end else begin
      case (batch2_selected_child_error_r)
        5'd1: begin
          batch2_mapped_error_code_r = `NPU_ERR_MACRO_LAYOUT;
          batch2_mapped_error_class_r = ABI_ERROR_LAYOUT;
        end
        5'd2, 5'd3, 5'd4, 5'd5: begin
          batch2_mapped_error_code_r = `NPU_ERR_MACRO_IOVA;
          batch2_mapped_error_class_r = ABI_ERROR_IOVA;
        end
        5'd6: begin
          batch2_mapped_error_code_r = `NPU_ERR_GMEM_RESPONSE;
          batch2_mapped_error_class_r = ABI_ERROR_GMEM;
        end
        5'd8, 5'd9: begin
          batch2_mapped_error_code_r = `NPU_ERR_MACRO_TIMEOUT;
          batch2_mapped_error_class_r = ABI_ERROR_TIMEOUT;
        end
        default: begin end
      endcase
    end
  end

  /* verilator lint_off UNUSEDSIGNAL */
  wire selected_macro_busy_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire selected_macro_done_w;
  wire selected_macro_error_w;
  wire [`NPU_ERROR_W-1:0] selected_macro_error_code_w;
  wire [31:0] selected_macro_error_class_w;
  wire [63:0] selected_macro_read_bytes_w;
  wire [63:0] selected_macro_write_bytes_w;
  wire [63:0] selected_macro_q8_mac_count_w;
  wire [63:0] selected_macro_vector_elements_w;
  wire [63:0] selected_macro_expected_read_bytes_w;
  wire [63:0] selected_macro_expected_write_bytes_w;
  wire [63:0] selected_macro_expected_q8_mac_count_w;
  wire [63:0] selected_macro_expected_vector_elements_w;
  wire selected_macro_gmem_outstanding_w;
  wire selected_macro_terminal_identity_ok_w;
  wire q8_success_counts_ok_w;
  wire gemv_success_counts_ok_w;
  wire f32_move_success_counts_ok_w;
  wire argmax_success_counts_ok_w;
  wire exact_success_counts_ok_w;
  wire batch2_success_counts_ok_w;
  wire selected_macro_gmem_req_valid_w;
  wire selected_macro_gmem_req_write_w;
  wire [63:0] selected_macro_gmem_req_addr_w;
  wire [63:0] selected_macro_gmem_req_wdata_w;
  wire [7:0] selected_macro_gmem_req_wstrb_w;
  wire selected_macro_gmem_rsp_ready_w;

  wire exact_selected_busy_w = macro_select_unary_glu_w ?
      unary_glu_adapter_busy_w : (macro_select_norm_w ? norm_adapter_busy_w :
      (macro_select_sum_w ? sum_adapter_busy_w :
       (macro_select_ssm_w ? ssm_adapter_busy_w : 1'b0)));
  wire exact_selected_done_w = macro_select_unary_glu_w ?
      unary_glu_adapter_done_w : (macro_select_norm_w ? norm_adapter_done_w :
      (macro_select_sum_w ? sum_adapter_done_w :
       (macro_select_ssm_w ? ssm_adapter_done_w : 1'b0)));
  wire exact_selected_error_w = macro_select_unary_glu_w ?
      unary_glu_adapter_error_w : (macro_select_norm_w ?
      norm_adapter_error_w : (macro_select_sum_w ? sum_adapter_error_w :
      (macro_select_ssm_w ? ssm_adapter_error_w : 1'b0)));
  wire [63:0] exact_selected_read_bytes_w = macro_select_unary_glu_w ?
      unary_glu_adapter_read_bytes_w : (macro_select_norm_w ?
      norm_adapter_read_bytes_w : (macro_select_sum_w ?
      sum_adapter_read_bytes_w : (macro_select_ssm_w ?
      ssm_adapter_read_bytes_w : 64'd0)));
  wire [63:0] exact_selected_write_bytes_w = macro_select_unary_glu_w ?
      unary_glu_adapter_write_bytes_w : (macro_select_norm_w ?
      norm_adapter_write_bytes_w : (macro_select_sum_w ?
      sum_adapter_write_bytes_w : (macro_select_ssm_w ?
      ssm_adapter_write_bytes_w : 64'd0)));
  wire [63:0] exact_selected_work_w = macro_select_unary_glu_w ?
      unary_glu_adapter_elements_w : (macro_select_norm_w ?
      norm_adapter_elements_w : (macro_select_sum_w ?
      sum_adapter_elements_w : (macro_select_ssm_w ?
      ssm_adapter_work_items_w : 64'd0)));
  wire exact_selected_gmem_outstanding_w = macro_select_unary_glu_w ?
      unary_glu_adapter_gmem_outstanding_w : (macro_select_norm_w ?
      norm_adapter_gmem_outstanding_w : (macro_select_sum_w ?
      sum_adapter_gmem_outstanding_w : (macro_select_ssm_w ?
      ssm_adapter_gmem_outstanding_w : 1'b0)));
  wire exact_selected_gmem_req_valid_w = macro_select_unary_glu_w ?
      unary_glu_gmem_req_valid_w : (macro_select_norm_w ?
      norm_gmem_req_valid_w : (macro_select_sum_w ? sum_gmem_req_valid_w :
      (macro_select_ssm_w ? ssm_gmem_req_valid_w : 1'b0)));
  wire exact_selected_gmem_req_write_w = macro_select_unary_glu_w ?
      unary_glu_gmem_req_write_w : (macro_select_norm_w ?
      norm_gmem_req_write_w : (macro_select_sum_w ? sum_gmem_req_write_w :
      (macro_select_ssm_w ? ssm_gmem_req_write_w : 1'b0)));
  wire [63:0] exact_selected_gmem_req_addr_w = macro_select_unary_glu_w ?
      unary_glu_gmem_req_addr_w : (macro_select_norm_w ?
      norm_gmem_req_addr_w : (macro_select_sum_w ? sum_gmem_req_addr_w :
      (macro_select_ssm_w ? ssm_gmem_req_addr_w : 64'd0)));
  wire [63:0] exact_selected_gmem_req_wdata_w = macro_select_unary_glu_w ?
      unary_glu_gmem_req_wdata_w : (macro_select_norm_w ?
      norm_gmem_req_wdata_w : (macro_select_sum_w ? sum_gmem_req_wdata_w :
      (macro_select_ssm_w ? ssm_gmem_req_wdata_w : 64'd0)));
  wire [7:0] exact_selected_gmem_req_wstrb_w = macro_select_unary_glu_w ?
      unary_glu_gmem_req_wstrb_w : (macro_select_norm_w ?
      norm_gmem_req_wstrb_w : (macro_select_sum_w ? sum_gmem_req_wstrb_w :
      (macro_select_ssm_w ? ssm_gmem_req_wstrb_w : 8'd0)));
  wire exact_selected_gmem_rsp_ready_w = macro_select_unary_glu_w ?
      unary_glu_gmem_rsp_ready_w : (macro_select_norm_w ?
      norm_gmem_rsp_ready_w : (macro_select_sum_w ? sum_gmem_rsp_ready_w :
      (macro_select_ssm_w ? ssm_gmem_rsp_ready_w : 1'b0)));
  wire exact_selected_terminal_identity_ok_w = macro_select_unary_glu_w ?
      (unary_glu_adapter_completion_valid_w &&
       (unary_glu_adapter_completion_command_id_w == macro_sequence_id_q) &&
       (unary_glu_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
       (unary_glu_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
       (unary_glu_adapter_completion_required_w ==
        macro_command_flags_q[0]) &&
       (unary_glu_adapter_completion_operation_w == macro_select_glu_w) &&
       (unary_glu_adapter_completion_subtype_w == exact_subtype_r) &&
       (unary_glu_adapter_completion_profile_w == exact_profile_id_r) &&
       (unary_glu_adapter_completion_kernel_w == macro_kernel_id_q) &&
       (unary_glu_adapter_operator_census_w == exact_operator_census_r) &&
       (unary_glu_adapter_subtype_census_w == exact_subtype_census_r) &&
       (unary_glu_adapter_profile_census_w == exact_profile_census_r) &&
       (unary_glu_adapter_dst_commit_w == unary_glu_adapter_done_w)) :
      (macro_select_norm_w ?
       (norm_adapter_completion_valid_w &&
        (norm_adapter_completion_command_id_w == macro_sequence_id_q) &&
        (norm_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
        (norm_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
        (norm_adapter_completion_required_w == macro_command_flags_q[0]) &&
        (norm_adapter_completion_reduce_op_w == exact_reduce_op_r) &&
        (norm_adapter_completion_epsilon_w == exact_epsilon_bits_r) &&
        (norm_adapter_completion_profile_w == exact_profile_id_r) &&
        (norm_adapter_completion_kernel_w == macro_kernel_id_q) &&
        (norm_adapter_operator_census_w == exact_operator_census_r) &&
        (norm_adapter_profile_census_w == exact_profile_census_r) &&
        (norm_adapter_dst_commit_w == norm_adapter_done_w)) :
       (macro_select_sum_w ?
        (sum_adapter_completion_valid_w &&
         (sum_adapter_completion_command_id_w == macro_sequence_id_q) &&
         (sum_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
         (sum_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
         (sum_adapter_completion_required_w == macro_command_flags_q[0]) &&
         (sum_adapter_completion_reduce_op_w == exact_reduce_op_r) &&
         (sum_adapter_completion_manifest_op_w == exact_manifest_op_id_r) &&
         (sum_adapter_completion_arity_w == exact_source_arity_r) &&
         (sum_adapter_completion_profile_w == exact_profile_id_r) &&
         (sum_adapter_completion_kernel_w == macro_kernel_id_q) &&
         (sum_adapter_operator_census_w == exact_operator_census_r) &&
         (sum_adapter_profile_census_w == exact_profile_census_r) &&
         (sum_adapter_dst_commit_w == sum_adapter_done_w)) :
        (macro_select_ssm_w ?
         (ssm_adapter_completion_valid_w &&
          (ssm_adapter_completion_command_id_w == macro_sequence_id_q) &&
          (ssm_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
          (ssm_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
          (ssm_adapter_completion_required_w == macro_command_flags_q[0]) &&
          (ssm_adapter_completion_manifest_op_w == exact_manifest_op_id_r) &&
          (ssm_adapter_completion_arity_w == exact_source_arity_r) &&
          (ssm_adapter_completion_profile_w == exact_profile_id_r) &&
          (ssm_adapter_completion_kernel_w == macro_kernel_id_q) &&
          (ssm_adapter_operator_census_w == exact_operator_census_r) &&
          (ssm_adapter_profile_census_w == exact_profile_census_r) &&
          (ssm_adapter_dst_commit_w == ssm_adapter_done_w)) : 1'b0)));

  wire batch2_selected_busy_w = macro_select_mover_set_w ?
      mover_adapter_busy_w : (macro_select_attention_w ?
      attention_adapter_busy_w : (macro_select_softmax_w ?
      softmax_adapter_busy_w : (macro_select_rope_w ?
      rope_adapter_busy_w : 1'b0)));
  wire batch2_selected_done_w = macro_select_mover_set_w ?
      mover_adapter_done_w : (macro_select_attention_w ?
      attention_adapter_done_w : (macro_select_softmax_w ?
      softmax_adapter_done_w : (macro_select_rope_w ?
      rope_adapter_done_w : 1'b0)));
  wire batch2_selected_error_w = macro_select_mover_set_w ?
      mover_adapter_error_w : (macro_select_attention_w ?
      attention_adapter_error_w : (macro_select_softmax_w ?
      softmax_adapter_error_w : (macro_select_rope_w ?
      rope_adapter_error_w : 1'b0)));
  wire [63:0] batch2_selected_read_bytes_w = macro_select_mover_set_w ?
      mover_adapter_read_bytes_w : (macro_select_attention_w ?
      attention_adapter_read_bytes_w : (macro_select_softmax_w ?
      softmax_adapter_read_bytes_w : (macro_select_rope_w ?
      rope_adapter_read_bytes_w : 64'd0)));
  wire [63:0] batch2_selected_write_bytes_w = macro_select_mover_set_w ?
      mover_adapter_write_bytes_w : (macro_select_attention_w ?
      attention_adapter_write_bytes_w : (macro_select_softmax_w ?
      softmax_adapter_write_bytes_w : (macro_select_rope_w ?
      rope_adapter_write_bytes_w : 64'd0)));
  wire [63:0] batch2_selected_work_w = macro_select_mover_set_w ?
      mover_adapter_elements_w : (macro_select_attention_w ?
      attention_adapter_outputs_completed_w : (macro_select_softmax_w ?
      softmax_adapter_outputs_completed_w : (macro_select_rope_w ?
      rope_adapter_outputs_completed_w : 64'd0)));
  wire batch2_selected_gmem_outstanding_w = macro_select_mover_set_w ?
      mover_adapter_gmem_outstanding_w : (macro_select_attention_w ?
      attention_adapter_gmem_outstanding_w : (macro_select_softmax_w ?
      softmax_adapter_gmem_outstanding_w : (macro_select_rope_w ?
      rope_adapter_gmem_outstanding_w : 1'b0)));
  wire batch2_selected_gmem_req_valid_w = macro_select_mover_set_w ?
      mover_gmem_req_valid_w : (macro_select_attention_w ?
      attention_gmem_req_valid_w : (macro_select_softmax_w ?
      softmax_gmem_req_valid_w : (macro_select_rope_w ?
      rope_gmem_req_valid_w : 1'b0)));
  wire batch2_selected_gmem_req_write_w = macro_select_mover_set_w ?
      mover_gmem_req_write_w : (macro_select_attention_w ?
      attention_gmem_req_write_w : (macro_select_softmax_w ?
      softmax_gmem_req_write_w : (macro_select_rope_w ?
      rope_gmem_req_write_w : 1'b0)));
  wire [63:0] batch2_selected_gmem_req_addr_w = macro_select_mover_set_w ?
      mover_gmem_req_addr_w : (macro_select_attention_w ?
      attention_gmem_req_addr_w : (macro_select_softmax_w ?
      softmax_gmem_req_addr_w : (macro_select_rope_w ?
      rope_gmem_req_addr_w : 64'd0)));
  wire [63:0] batch2_selected_gmem_req_wdata_w = macro_select_mover_set_w ?
      mover_gmem_req_wdata_w : (macro_select_attention_w ?
      attention_gmem_req_wdata_w : (macro_select_softmax_w ?
      softmax_gmem_req_wdata_w : (macro_select_rope_w ?
      rope_gmem_req_wdata_w : 64'd0)));
  wire [7:0] batch2_selected_gmem_req_wstrb_w = macro_select_mover_set_w ?
      mover_gmem_req_wstrb_w : (macro_select_attention_w ?
      attention_gmem_req_wstrb_w : (macro_select_softmax_w ?
      softmax_gmem_req_wstrb_w : (macro_select_rope_w ?
      rope_gmem_req_wstrb_w : 8'd0)));
  wire batch2_selected_gmem_rsp_ready_w = macro_select_mover_set_w ?
      mover_gmem_rsp_ready_w : (macro_select_attention_w ?
      attention_gmem_rsp_ready_w : (macro_select_softmax_w ?
      softmax_gmem_rsp_ready_w : (macro_select_rope_w ?
      rope_gmem_rsp_ready_w : 1'b0)));

  wire batch2_selected_terminal_identity_ok_w =
      macro_select_mover_set_w ?
      (mover_adapter_completion_valid_w &&
       (mover_adapter_completion_command_w == macro_sequence_id_q) &&
       (mover_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
       (mover_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
       (mover_adapter_completion_required_w == macro_command_flags_q[0]) &&
       (mover_adapter_completion_operation_w == batch2_operation_r) &&
       (mover_adapter_completion_kernel_w == macro_kernel_id_q) &&
       (mover_adapter_dst_commit_w == mover_adapter_done_w)) :
      (macro_select_attention_w ?
       (attention_adapter_completion_valid_w &&
        (attention_adapter_completion_command_w == macro_sequence_id_q) &&
        (attention_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
        (attention_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
        (attention_adapter_completion_required_w ==
         macro_command_flags_q[0]) &&
        (attention_adapter_completion_manifest_op_w == MANIFEST_MUL_MAT) &&
        (attention_adapter_completion_arity_w == 3'd2) &&
        (attention_adapter_completion_profile_w == batch2_profile_id_r) &&
        (attention_adapter_completion_kernel_w == macro_kernel_id_q) &&
        (attention_adapter_operator_census_w == 32'd12) &&
        (attention_adapter_profile_census_w == 32'd6) &&
        (attention_adapter_dst_commit_w == attention_adapter_done_w)) :
       (macro_select_softmax_w ?
        (softmax_adapter_completion_valid_w &&
         (softmax_adapter_completion_command_w == macro_sequence_id_q) &&
         (softmax_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
         (softmax_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
         (softmax_adapter_completion_required_w ==
          macro_command_flags_q[0]) &&
         (softmax_adapter_completion_reduce_op_w == 3'd6) &&
         (softmax_adapter_completion_manifest_op_w == MANIFEST_SOFT_MAX) &&
         (softmax_adapter_completion_arity_w == 3'd2) &&
         (softmax_adapter_completion_profile_w == batch2_profile_id_r) &&
         (softmax_adapter_completion_kernel_w == macro_kernel_id_q) &&
         (softmax_adapter_operator_census_w == 32'd6) &&
         (softmax_adapter_profile_census_w == 32'd1) &&
         (softmax_adapter_dst_commit_w == softmax_adapter_done_w)) :
        (macro_select_rope_w ?
         (rope_adapter_completion_valid_w &&
          (rope_adapter_completion_command_w == macro_sequence_id_q) &&
          (rope_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
          (rope_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
          (rope_adapter_completion_required_w == macro_command_flags_q[0]) &&
          (rope_adapter_completion_manifest_op_w == MANIFEST_ROPE) &&
          (rope_adapter_completion_arity_w == 3'd2) &&
          (rope_adapter_completion_profile_w == batch2_profile_id_r) &&
          (rope_adapter_completion_kernel_w == macro_kernel_id_q) &&
          (rope_adapter_operator_census_w == 32'd12) &&
          (rope_adapter_profile_census_w == 32'd6) &&
          (rope_adapter_dst_commit_w == rope_adapter_done_w)) : 1'b0)));

  assign selected_macro_busy_w = functional_command_select_w ?
                                 functional_command_busy_w :
                                 (macro_select_vector_w ?
                                 macro_adapter_busy_w :
                                 (macro_select_q8_w ? q8_adapter_busy_w :
                                  (macro_select_gemv_w ?
                                   gemv_adapter_busy_w :
                                   (macro_select_f32_move_w ?
                                    f32_move_adapter_busy_w :
                                    (macro_select_argmax_w ?
                                     argmax_adapter_busy_w :
                                     (macro_select_exact_profile_w ?
                                      exact_selected_busy_w :
                                      (macro_select_batch2_profile_w ?
                                       batch2_selected_busy_w : 1'b0)))))));
  assign selected_macro_done_w = functional_command_select_w ?
                                 (functional_command_terminal_valid_w &&
                                  functional_command_success_w) :
                                 (macro_select_vector_w ?
                                 macro_adapter_done_w :
                                 (macro_select_q8_w ? q8_adapter_done_w :
                                  (macro_select_gemv_w ?
                                   gemv_adapter_done_w :
                                   (macro_select_f32_move_w ?
                                    f32_move_adapter_done_w :
                                    (macro_select_argmax_w ?
                                     argmax_adapter_done_w :
                                     (macro_select_exact_profile_w ?
                                      exact_selected_done_w :
                                      (macro_select_batch2_profile_w ?
                                       batch2_selected_done_w : 1'b0)))))));
  assign selected_macro_error_w = functional_command_select_w ?
                                  (functional_command_terminal_valid_w &&
                                   functional_command_error_w) :
                                  (macro_select_vector_w ?
                                  macro_adapter_error_w :
                                  (macro_select_q8_w ? q8_adapter_error_w :
                                   (macro_select_gemv_w ?
                                    gemv_adapter_error_w :
                                    (macro_select_f32_move_w ?
                                     f32_move_adapter_error_w :
                                     (macro_select_argmax_w ?
                                      argmax_adapter_error_w :
                                      (macro_select_exact_profile_w ?
                                       exact_selected_error_w :
                                       (macro_select_batch2_profile_w ?
                                        batch2_selected_error_w : 1'b0)))))));
  assign selected_macro_error_code_w = functional_command_select_w ?
      functional_mapped_error_code_r :
      (macro_select_vector_w ?
      macro_adapter_error_code_w : (macro_select_q8_w ?
      q8_mapped_error_code_r : (macro_select_gemv_w ?
      gemv_mapped_error_code_r : (macro_select_f32_move_w ?
      f32_move_mapped_error_code_r : (macro_select_argmax_w ?
      argmax_mapped_error_code_r : (macro_select_exact_profile_w ?
      exact_mapped_error_code_r : (macro_select_batch2_profile_w ?
      batch2_mapped_error_code_r : `NPU_ERR_MACRO_CAPABILITY)))))));
  assign selected_macro_error_class_w = functional_command_select_w ?
      functional_mapped_error_class_r : (macro_select_vector_w ?
      macro_adapter_error_class_w : (macro_select_q8_w ?
      q8_mapped_error_class_r : (macro_select_gemv_w ?
      gemv_mapped_error_class_r : (macro_select_f32_move_w ?
      f32_move_mapped_error_class_r : (macro_select_argmax_w ?
      argmax_mapped_error_class_r : (macro_select_exact_profile_w ?
      exact_mapped_error_class_r : (macro_select_batch2_profile_w ?
      batch2_mapped_error_class_r : ABI_ERROR_CAPABILITY)))))));
  // Completion byte counters retain each kernel's frozen ABI: Q8 GET_ROWS
  // reports physical read beats, while raw F32 mover kernels report accepted
  // semantic payload bytes.  All writes count only asserted FP32 byte lanes.
  assign selected_macro_read_bytes_w = functional_command_select_w ?
      functional_command_read_bytes_w : (macro_select_vector_w ?
      macro_adapter_read_bytes_w : (macro_select_q8_w ?
      ({32'd0, q8_adapter_gmem_read_beats_w} << 3) :
      (macro_select_gemv_w ? gemv_adapter_gmem_read_bytes_w :
       (macro_select_f32_move_w ? f32_move_adapter_read_bytes_w :
        (macro_select_argmax_w ? argmax_adapter_read_bytes_w :
         (macro_select_exact_profile_w ? exact_selected_read_bytes_w :
          (macro_select_batch2_profile_w ? batch2_selected_read_bytes_w :
           64'd0)))))));
  assign selected_macro_write_bytes_w = functional_command_select_w ?
      functional_command_write_bytes_w : (macro_select_vector_w ?
      macro_adapter_write_bytes_w : (macro_select_q8_w ?
      {32'd0, q8_adapter_write_bytes_w} : (macro_select_gemv_w ?
      gemv_adapter_write_bytes_w : (macro_select_f32_move_w ?
      f32_move_adapter_write_bytes_w : (macro_select_argmax_w ?
      argmax_adapter_write_bytes_w : (macro_select_exact_profile_w ?
      exact_selected_write_bytes_w : (macro_select_batch2_profile_w ?
      batch2_selected_write_bytes_w : 64'd0)))))));
  assign selected_macro_q8_mac_count_w = functional_command_select_w ?
      functional_command_q8_mac_count_w : (macro_select_gemv_w ?
      (gemv_adapter_weight_blocks_w << 5) : 64'd0);
  assign selected_macro_vector_elements_w = functional_command_select_w ?
      functional_command_vector_elements_w : (macro_select_vector_w ?
      macro_adapter_vector_elements_w : (macro_select_q8_w ?
      {32'd0, q8_adapter_outputs_accepted_w} : (macro_select_gemv_w ?
      {32'd0, gemv_adapter_rows_written_w} : (macro_select_f32_move_w ?
      f32_move_adapter_elements_w : (macro_select_argmax_w ?
      argmax_adapter_elements_w : (macro_select_exact_profile_w ?
      exact_selected_work_w : (macro_select_batch2_profile_w ?
      batch2_selected_work_w : 64'd0)))))));
  // Physical Q8 read-beat count depends on actual gathered IDs and alignment;
  // the child owns that exact count.  Independent semantic payload, block,
  // output and write closure is checked by q8_success_counts_ok_w below.
  assign selected_macro_expected_read_bytes_w = functional_command_select_w ?
      (macro_select_vector_w ? functional_vector_expected_read_bytes_w :
       functional_command_read_bytes_w) : (macro_select_vector_w ?
      macro_adapter_expected_read_bytes_w : (macro_select_f32_move_w ?
      ((F32_MOVER_PORTAL_ENABLE != 0) ? 64'd0 :
       f32_move_read_bytes_ext_w[63:0]) : (macro_select_argmax_w ?
      argmax_expected_read_bytes_ext_w[63:0] :
      (macro_select_exact_profile_w ? exact_expected_read_bytes_r :
       (macro_select_batch2_profile_w ? batch2_expected_read_bytes_r :
        selected_macro_read_bytes_w)))));
  assign selected_macro_expected_write_bytes_w = functional_command_select_w ?
      (macro_select_vector_w ? functional_vector_expected_write_bytes_w :
       functional_command_write_bytes_w) : (macro_select_vector_w ?
      macro_adapter_expected_write_bytes_w :
      (macro_select_q8_w ? q8_expected_write_bytes_ext_w[63:0] :
       (macro_select_gemv_w ? gemv_output_bytes_ext_w[63:0] :
       (macro_select_f32_move_w ?
         ((F32_MOVER_PORTAL_ENABLE != 0) ? 64'd0 :
          f32_move_write_bytes_ext_w[63:0]) :
         (macro_select_argmax_w ? 64'd4 :
          (macro_select_exact_profile_w ? exact_expected_write_bytes_r :
           (macro_select_batch2_profile_w ? batch2_expected_write_bytes_r :
            64'd0)))))));
  assign selected_macro_expected_q8_mac_count_w =
      functional_command_select_w ?
      (macro_select_vector_w ? 64'd0 : functional_command_q8_mac_count_w) :
      (macro_select_gemv_w ? gemv_q8_mac_count_ext_w[63:0] : 64'd0);
  assign selected_macro_expected_vector_elements_w =
      functional_command_select_w ?
      (macro_select_vector_w ? functional_vector_expected_elements_w :
       functional_command_vector_elements_w) :
      (macro_select_vector_w ?
      macro_adapter_expected_vector_elements_w :
      (macro_select_q8_w ? q8_total_outputs_ext_w[63:0] :
       (macro_select_gemv_w ? {32'd0, macro_outer_count_q} :
        (macro_select_f32_move_w ?
         f32_move_total_outputs_ext_w[63:0] :
         (macro_select_argmax_w ? macro_element_count_q :
          (macro_select_exact_profile_w ? exact_expected_work_r :
           (macro_select_batch2_profile_w ? batch2_expected_work_r :
            64'd0)))))));
  assign selected_macro_gmem_outstanding_w = functional_command_select_w ?
      1'b0 : (macro_select_vector_w ?
      (macro_adapter_gmem_outstanding_w | f32_alu_portal_outstanding_o) :
      (macro_select_q8_w ?
      q8_adapter_gmem_outstanding_w : (macro_select_gemv_w ?
      gemv_adapter_gmem_outstanding_w : (macro_select_f32_move_w ?
      (f32_move_adapter_gmem_outstanding_w |
       f32_mover_portal_outstanding_o) :
      (macro_select_argmax_w ? argmax_adapter_gmem_outstanding_w :
       (macro_select_exact_profile_w ? exact_selected_gmem_outstanding_w :
        (macro_select_batch2_profile_w ?
         batch2_selected_gmem_outstanding_w : 1'b0)))))));
  wire functional_command_status_metadata_ok_w;
  assign functional_command_status_metadata_ok_w =
      (functional_command_success_w && !functional_command_error_w &&
       (functional_command_error_code_w == 32'd0) &&
       (functional_command_error_class_w == 32'd0)) ||
      (functional_command_error_w && !functional_command_success_w &&
       (functional_command_error_code_w != 32'd0) &&
       (functional_command_error_class_w != 32'd0));
  assign selected_macro_terminal_identity_ok_w =
      functional_command_select_w ?
      (functional_command_terminal_valid_w &&
       (functional_completion_kernel_id_w == macro_kernel_id_q) &&
       (functional_completion_command_flags_w == macro_command_flags_q) &&
       (functional_completion_vector_op_w == macro_vector_op_q) &&
       (functional_completion_vector_flags_w == macro_vector_flags_q) &&
       (functional_completion_context_id_w == macro_context_id_q) &&
       (functional_completion_capability_epoch_w ==
        macro_capability_epoch_q) &&
       (functional_completion_node_count_w == macro_node_count_q) &&
       (functional_completion_sequence_id_w == macro_sequence_id_q) &&
       (functional_completion_producer_id_w == macro_producer_id_q) &&
       (functional_completion_user_tag_w == macro_user_tag_q) &&
       (functional_completion_node_hash_lo_w == macro_node_hash_lo_q) &&
       (functional_completion_node_hash_hi_w == macro_node_hash_hi_q) &&
       (functional_command_dst_commit_w == functional_command_success_w) &&
       functional_command_status_metadata_ok_w &&
       functional_command_exact_once_ok_w) :
      (macro_select_vector_w ?
      1'b1 : (macro_select_q8_w ?
      (q8_adapter_completion_valid_w &&
       (q8_adapter_completion_command_id_w == macro_sequence_id_q) &&
       (q8_adapter_completion_kernel_id_w == KERNEL_GET_ROWS_Q8_0) &&
       (q8_adapter_dst_commit_w == q8_adapter_done_w)) :
      (macro_select_gemv_w ?
       (gemv_adapter_completion_valid_w &&
        (gemv_adapter_completion_command_id_w == macro_sequence_id_q) &&
        (gemv_adapter_completion_kernel_id_w == KERNEL_GEMV_Q8_0_F32) &&
        (gemv_adapter_completion_row_count_w == macro_outer_count_q) &&
        ({96'd0, gemv_adapter_completion_block_count_w}
         == gemv_block_count_ext_w) &&
        (gemv_adapter_dst_commit_w == gemv_adapter_done_w)) :
       (macro_select_f32_move_w ?
        (f32_move_adapter_completion_valid_w &&
         (f32_move_adapter_completion_command_id_w ==
          macro_sequence_id_q) &&
         (f32_move_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
         (f32_move_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
         (f32_move_adapter_completion_required_w ==
          macro_command_flags_q[0]) &&
         (f32_move_adapter_completion_operation_w ==
          macro_select_f32_repeat_w) &&
         (f32_move_adapter_completion_kernel_id_w ==
          (macro_select_f32_get_w ? KERNEL_GET_ROWS_F32 :
                                    KERNEL_REPEAT_F32)) &&
         (f32_move_adapter_dst_commit_w == f32_move_adapter_done_w)) :
        (macro_select_argmax_w ?
         (argmax_adapter_completion_valid_w &&
          (argmax_adapter_completion_command_w == macro_sequence_id_q) &&
          (argmax_adapter_completion_node_lo_w == macro_node_hash_lo_q) &&
          (argmax_adapter_completion_node_hi_w == macro_node_hash_hi_q) &&
          (argmax_adapter_completion_required_w ==
           macro_command_flags_q[0]) &&
          (argmax_adapter_completion_kernel_w == KERNEL_F32_ARGMAX) &&
          (argmax_adapter_dst_commit_w == argmax_adapter_done_w)) :
         (macro_select_exact_profile_w ?
          exact_selected_terminal_identity_ok_w :
          (macro_select_batch2_profile_w ?
           batch2_selected_terminal_identity_ok_w : 1'b0)))))));
  wire functional_command_success_counts_ok_w;
  assign functional_command_success_counts_ok_w =
      !functional_command_select_w ||
      ((functional_command_callback_errors_w == 32'd0) &&
       (macro_select_gemv_w ?
        ((functional_command_read_words_w == gemv_k_ext_w[63:0]) &&
         (functional_command_write_words_w ==
          {32'd0, macro_outer_count_q}) &&
         (functional_command_q8_blocks_w ==
          gemv_weight_blocks_ext_w[63:0]) &&
         (functional_command_q8_mac_count_w ==
          gemv_q8_mac_count_ext_w[63:0]) &&
         (functional_command_vector_elements_w ==
          {32'd0, macro_outer_count_q})) :
        (macro_select_q8_w ?
         ((functional_command_read_words_w ==
           {32'd0, macro_outer_count_q}) &&
          (functional_command_write_words_w ==
           q8_total_outputs_ext_w[63:0]) &&
          (functional_command_q8_blocks_w ==
           q8_expected_blocks_ext_w[63:0]) &&
          (functional_command_q8_mac_count_w == 64'd0) &&
          (functional_command_vector_elements_w ==
           q8_total_outputs_ext_w[63:0])) :
         (macro_select_f32_move_w ?
          ((functional_command_read_words_w ==
            f32_move_read_words_ext_w[63:0]) &&
           (functional_command_write_words_w ==
            f32_move_total_outputs_ext_w[63:0]) &&
           (functional_command_q8_blocks_w == 64'd0) &&
           (functional_command_q8_mac_count_w == 64'd0) &&
           (functional_command_vector_elements_w ==
            f32_move_total_outputs_ext_w[63:0])) :
          (macro_select_mover_set_w ?
           ((functional_command_read_words_w ==
             (batch2_expected_read_bytes_r >> 2)) &&
            (functional_command_write_words_w ==
             (batch2_expected_write_bytes_r >> 2)) &&
            (functional_command_q8_blocks_w == 64'd0) &&
            (functional_command_q8_mac_count_w == 64'd0) &&
            (functional_command_vector_elements_w ==
             batch2_expected_work_r)) :
           (macro_select_vector_w ?
            (functional_vector_contract_ok_w &&
             (functional_command_read_words_w ==
              functional_vector_expected_read_words_w) &&
             (functional_command_write_words_w ==
              functional_vector_expected_write_words_w) &&
             (functional_command_read_bytes_w ==
              functional_vector_expected_read_bytes_w) &&
             (functional_command_write_bytes_w ==
              functional_vector_expected_write_bytes_w) &&
             (functional_command_q8_blocks_w == 64'd0) &&
             (functional_command_q8_mac_count_w == 64'd0) &&
             (functional_command_vector_elements_w ==
              functional_vector_expected_elements_w)) : 1'b0))))));
  assign q8_success_counts_ok_w = functional_command_select_w ||
      !macro_select_q8_w ||
      ((q8_expected_blocks_ext_w[127:32] == 96'd0) &&
       (q8_expected_payload_bytes_ext_w[127:32] == 96'd0) &&
       (q8_total_outputs_ext_w[127:32] == 96'd0) &&
       (q8_expected_write_bytes_ext_w[127:32] == 96'd0) &&
       (q8_adapter_ids_scanned_w == macro_outer_count_q) &&
       (q8_adapter_blocks_done_w == q8_expected_blocks_ext_w[31:0]) &&
       (q8_adapter_read_payload_bytes_w ==
        q8_expected_payload_bytes_ext_w[31:0]) &&
       (q8_adapter_outputs_accepted_w == q8_total_outputs_ext_w[31:0]) &&
       (q8_adapter_gmem_write_beats_w == q8_total_outputs_ext_w[31:0]) &&
       (q8_adapter_writes_completed_w == q8_total_outputs_ext_w[31:0]) &&
       (q8_adapter_write_bytes_w == q8_expected_write_bytes_ext_w[31:0]));
  assign gemv_success_counts_ok_w = functional_command_select_w ||
      !macro_select_gemv_w ||
      ((gemv_block_count_ext_w[127:32] == 96'd0) &&
       (gemv_activation_bytes_ext_w[127:64] == 64'd0) &&
       (gemv_weight_blocks_ext_w[127:64] == 64'd0) &&
       (gemv_weight_payload_bytes_ext_w[127:64] == 64'd0) &&
       (gemv_output_bytes_ext_w[127:64] == 64'd0) &&
       (gemv_q8_mac_count_ext_w[127:64] == 64'd0) &&
       ({32'd0, gemv_adapter_activation_words_w}
        == gemv_k_ext_w[63:0]) &&
       (gemv_adapter_weight_blocks_w
        == gemv_weight_blocks_ext_w[63:0]) &&
       (gemv_adapter_rows_written_w == macro_outer_count_q) &&
       (gemv_adapter_gmem_read_beats_w
        == gemv_adapter_gmem_read_beats_completed_w) &&
       (gemv_adapter_activation_payload_bytes_w
        == gemv_activation_bytes_ext_w[63:0]) &&
       (gemv_adapter_weight_payload_bytes_w
        == gemv_weight_payload_bytes_ext_w[63:0]) &&
       (gemv_adapter_gmem_write_beats_w == macro_outer_count_q) &&
       (gemv_adapter_writes_completed_w == macro_outer_count_q) &&
       (gemv_adapter_write_bytes_w == gemv_output_bytes_ext_w[63:0]));
  assign f32_move_success_counts_ok_w = functional_command_select_w ||
      !macro_select_f32_move_w ||
      ((f32_move_total_outputs_ext_w[127:64] == 64'd0) &&
       (f32_move_source_words_ext_w[127:64] == 64'd0) &&
       (f32_move_read_words_ext_w[127:64] == 64'd0) &&
       (f32_move_read_bytes_ext_w[127:64] == 64'd0) &&
       (f32_move_write_bytes_ext_w[127:64] == 64'd0) &&
       (f32_move_adapter_indices_w ==
        (macro_select_f32_get_w ? f32_move_n_ext_w[63:0] : 64'd0)) &&
       (f32_move_adapter_source_words_w ==
        f32_move_source_words_ext_w[63:0]) &&
       (f32_move_adapter_elements_w ==
        f32_move_total_outputs_ext_w[63:0]) &&
       (f32_move_adapter_expected_read_bytes_w == 64'd0) &&
       (f32_move_adapter_expected_write_bytes_w == 64'd0) &&
       ((F32_MOVER_PORTAL_ENABLE != 0) ?
        ((f32_move_adapter_read_beats_w == 64'd0) &&
         (f32_move_adapter_read_responses_w == 64'd0) &&
         (f32_move_adapter_read_bytes_w == 64'd0) &&
         (f32_move_adapter_write_beats_w == 64'd0) &&
         (f32_move_adapter_write_responses_w == 64'd0) &&
         (f32_move_adapter_write_bytes_w == 64'd0) &&
         !f32_move_adapter_gmem_outstanding_w &&
         !f32_mover_portal_outstanding_o &&
         (f32_mover_portal_request_groups_o ==
          f32_mover_portal_response_groups_o) &&
         (f32_mover_portal_request_groups_o ==
          (f32_mover_portal_read_groups_o +
           f32_mover_portal_write_groups_o)) &&
         (f32_mover_portal_read_words_o ==
          f32_move_read_words_ext_w[63:0]) &&
         (f32_mover_portal_write_words_o ==
          f32_move_total_outputs_ext_w[63:0]) &&
         (f32_mover_portal_read_bytes_o ==
          f32_move_read_bytes_ext_w[63:0]) &&
         (f32_mover_portal_write_bytes_o ==
          f32_move_write_bytes_ext_w[63:0])) :
        ((f32_move_adapter_read_beats_w ==
          f32_move_read_words_ext_w[63:0]) &&
         (f32_move_adapter_read_responses_w ==
          f32_move_read_words_ext_w[63:0]) &&
         (f32_move_adapter_read_bytes_w ==
          f32_move_read_bytes_ext_w[63:0]) &&
         (f32_move_adapter_write_beats_w ==
          f32_move_total_outputs_ext_w[63:0]) &&
         (f32_move_adapter_write_responses_w ==
          f32_move_total_outputs_ext_w[63:0]) &&
         (f32_move_adapter_write_bytes_w ==
          f32_move_write_bytes_ext_w[63:0]))));
  assign argmax_success_counts_ok_w = !macro_select_argmax_w ||
      ((argmax_expected_read_bytes_ext_w[127:64] == 64'd0) &&
       (argmax_expected_read_requests_ext_w[127:64] == 64'd0) &&
       (argmax_adapter_elements_w == macro_element_count_q) &&
       (argmax_adapter_comparisons_w == macro_element_count_q) &&
       (argmax_adapter_read_requests_w ==
        argmax_expected_read_requests_ext_w[63:0]) &&
       (argmax_adapter_read_responses_w ==
        argmax_expected_read_requests_ext_w[63:0]) &&
       (argmax_adapter_read_bytes_w ==
        argmax_expected_read_bytes_ext_w[63:0]) &&
       (argmax_adapter_write_requests_w == 64'd1) &&
       (argmax_adapter_write_responses_w == 64'd1) &&
       (argmax_adapter_write_bytes_w == 64'd4));
  assign exact_success_counts_ok_w = functional_command_select_w ||
      !macro_select_exact_profile_w ||
      (macro_select_unary_glu_w ?
       ((unary_glu_adapter_src0_words_w == exact_expected_work_r) &&
        (unary_glu_adapter_src1_words_w ==
         (macro_select_glu_w ? exact_expected_work_r : 64'd0)) &&
        (unary_glu_adapter_scalar_launches_w == exact_expected_work_r) &&
        (unary_glu_adapter_scalar_terminals_w == exact_expected_work_r) &&
        (unary_glu_adapter_elements_w == exact_expected_work_r) &&
        (unary_glu_adapter_read_beats_w ==
         (exact_expected_read_bytes_r >> 2)) &&
        (unary_glu_adapter_read_responses_w ==
         (exact_expected_read_bytes_r >> 2)) &&
        (unary_glu_adapter_read_bytes_w == exact_expected_read_bytes_r) &&
        (unary_glu_adapter_write_beats_w ==
         (exact_expected_write_bytes_r >> 2)) &&
        (unary_glu_adapter_write_responses_w ==
         (exact_expected_write_bytes_r >> 2)) &&
        (unary_glu_adapter_write_bytes_w == exact_expected_write_bytes_r)) :
       (macro_select_norm_w ?
        ((norm_adapter_rows_w == exact_outer_ext_w[63:0]) &&
         (norm_adapter_source_words_w == exact_expected_work_r) &&
         (norm_adapter_input_elements_w == exact_expected_work_r) &&
         (norm_adapter_output_elements_w == exact_expected_work_r) &&
         (norm_adapter_elements_w == exact_expected_work_r) &&
         (norm_adapter_launches_w == exact_outer_ext_w[63:0]) &&
         (norm_adapter_terminals_w == exact_outer_ext_w[63:0]) &&
         (norm_adapter_read_beats_w ==
          (exact_expected_read_bytes_r >> 2)) &&
         (norm_adapter_read_responses_w ==
          (exact_expected_read_bytes_r >> 2)) &&
         (norm_adapter_read_bytes_w == exact_expected_read_bytes_r) &&
         (norm_adapter_write_beats_w ==
          (exact_expected_write_bytes_r >> 2)) &&
         (norm_adapter_write_responses_w ==
          (exact_expected_write_bytes_r >> 2)) &&
         (norm_adapter_write_bytes_w == exact_expected_write_bytes_r)) :
        (macro_select_sum_w ?
         ((sum_adapter_rows_w == (exact_expected_write_bytes_r >> 2)) &&
          (sum_adapter_elements_w == exact_expected_work_r) &&
          (sum_adapter_reductions_w == exact_expected_work_r) &&
          (sum_adapter_results_w == (exact_expected_write_bytes_r >> 2)) &&
          (sum_adapter_read_requests_w ==
           (exact_expected_read_bytes_r >> 3)) &&
          (sum_adapter_read_responses_w ==
           (exact_expected_read_bytes_r >> 3)) &&
          (sum_adapter_read_bytes_w == exact_expected_read_bytes_r) &&
          (sum_adapter_write_requests_w ==
           (exact_expected_write_bytes_r >> 2)) &&
          (sum_adapter_write_responses_w ==
           (exact_expected_write_bytes_r >> 2)) &&
          (sum_adapter_write_bytes_w == exact_expected_write_bytes_r) &&
          (sum_adapter_launches_w == 64'd1) &&
          (sum_adapter_terminals_w == 64'd1)) :
         (macro_select_ssm_w ?
          ((ssm_adapter_outputs_computed_w ==
            (exact_expected_write_bytes_r >> 2)) &&
           (ssm_adapter_outputs_completed_w ==
            (exact_expected_write_bytes_r >> 2)) &&
           (ssm_adapter_src0_words_w == exact_expected_work_r) &&
           (ssm_adapter_src1_words_w == exact_expected_work_r) &&
           (ssm_adapter_work_items_w == exact_expected_work_r) &&
           (ssm_adapter_read_requests_w ==
            (exact_expected_read_bytes_r >> 3)) &&
           (ssm_adapter_read_responses_w ==
            (exact_expected_read_bytes_r >> 3)) &&
           (ssm_adapter_read_bytes_w == exact_expected_read_bytes_r) &&
           (ssm_adapter_write_requests_w ==
            (exact_expected_write_bytes_r >> 2)) &&
           (ssm_adapter_write_responses_w ==
            (exact_expected_write_bytes_r >> 2)) &&
           (ssm_adapter_write_bytes_w == exact_expected_write_bytes_r) &&
           (ssm_adapter_mul_requests_w == exact_expected_work_r) &&
           (ssm_adapter_mul_responses_w == exact_expected_work_r) &&
           (ssm_adapter_add_requests_w == exact_expected_work_r) &&
           (ssm_adapter_add_responses_w == exact_expected_work_r)) :
          1'b0))));

  assign batch2_success_counts_ok_w = functional_command_select_w ||
      !macro_select_batch2_profile_w ||
      (macro_select_mover_set_w ?
       ((mover_adapter_indices_w ==
         (batch2_operation_r == 3'd4 ? 64'd512 :
          (batch2_operation_r == 3'd3 ? 64'd1 : 64'd0))) &&
        (mover_adapter_source_elements_w == batch2_expected_work_r) &&
        (mover_adapter_elements_w == batch2_expected_work_r) &&
        (mover_adapter_read_beats_w == batch2_expected_read_requests_r) &&
        (mover_adapter_read_responses_w ==
         batch2_expected_read_requests_r) &&
        (mover_adapter_read_bytes_w == batch2_expected_read_bytes_r) &&
        (mover_adapter_write_beats_w == batch2_expected_write_requests_r) &&
        (mover_adapter_write_responses_w ==
         batch2_expected_write_requests_r) &&
        (mover_adapter_write_bytes_w == batch2_expected_write_bytes_r)) :
       (macro_select_attention_w ?
        ((attention_adapter_outputs_computed_w == 64'd2048) &&
         (attention_adapter_outputs_completed_w == 64'd2048) &&
         (attention_adapter_src0_words_w == 64'd524288) &&
         (attention_adapter_src1_words_w == 64'd2048) &&
         (attention_adapter_conversion_words_w == 64'd2048) &&
         (attention_adapter_work_items_w == 64'd524288) &&
         (attention_adapter_read_requests_w ==
          batch2_expected_read_requests_r) &&
         (attention_adapter_read_responses_w ==
          batch2_expected_read_requests_r) &&
         (attention_adapter_read_bytes_w == batch2_expected_read_bytes_r) &&
         (attention_adapter_write_requests_w ==
          batch2_expected_write_requests_r) &&
         (attention_adapter_write_responses_w ==
          batch2_expected_write_requests_r) &&
         (attention_adapter_write_bytes_w == batch2_expected_write_bytes_r) &&
         (attention_adapter_fma_requests_w == 64'd524288) &&
         (attention_adapter_fma_responses_w == 64'd524288) &&
         (attention_adapter_reduction_requests_w == 64'd73728) &&
         (attention_adapter_reduction_responses_w == 64'd73728)) :
        (macro_select_softmax_w ?
         ((softmax_adapter_rows_w == 64'd8) &&
          (softmax_adapter_src0_words_w == 64'd2048) &&
          (softmax_adapter_mask_words_w == 64'd256) &&
          (softmax_adapter_outputs_computed_w == 64'd2048) &&
          (softmax_adapter_outputs_completed_w == 64'd2048) &&
          (softmax_adapter_max_comparisons_w == 64'd2048) &&
          (softmax_adapter_read_requests_w ==
           batch2_expected_read_requests_r) &&
          (softmax_adapter_read_responses_w ==
           batch2_expected_read_requests_r) &&
          (softmax_adapter_read_bytes_w == batch2_expected_read_bytes_r) &&
          (softmax_adapter_write_requests_w ==
           batch2_expected_write_requests_r) &&
          (softmax_adapter_write_responses_w ==
           batch2_expected_write_requests_r) &&
          (softmax_adapter_write_bytes_w == batch2_expected_write_bytes_r) &&
          (softmax_adapter_scale_req_w == 64'd2048) &&
          (softmax_adapter_scale_rsp_w == 64'd2048) &&
          (softmax_adapter_maskadd_req_w == 64'd2048) &&
          (softmax_adapter_maskadd_rsp_w == 64'd2048) &&
          (softmax_adapter_sub_req_w == 64'd2048) &&
          (softmax_adapter_sub_rsp_w == 64'd2048) &&
          (softmax_adapter_exp_req_w == 64'd2048) &&
          (softmax_adapter_exp_rsp_w == 64'd2048) &&
          (softmax_adapter_sum_req_w == 64'd2048) &&
          (softmax_adapter_sum_rsp_w == 64'd2048) &&
          (softmax_adapter_div_req_w == 64'd8) &&
          (softmax_adapter_div_rsp_w == 64'd8) &&
          (softmax_adapter_norm_req_w == 64'd2048) &&
          (softmax_adapter_norm_rsp_w == 64'd2048)) :
         (macro_select_rope_w ?
          ((rope_adapter_outputs_computed_w == batch2_expected_work_r) &&
           (rope_adapter_outputs_completed_w == batch2_expected_work_r) &&
           (rope_adapter_src0_words_w == batch2_expected_work_r) &&
           (rope_adapter_position_words_w == 64'd4) &&
           (rope_adapter_position_conversions_w == 64'd4) &&
           (rope_adapter_raw_copy_words_w ==
            (batch2_profile_id_r == 8'd0 ? 64'd1536 : 64'd384)) &&
           (rope_adapter_rotation_pairs_w ==
            (batch2_profile_id_r == 8'd0 ? 64'd256 : 64'd64)) &&
           (rope_adapter_read_requests_w ==
            batch2_expected_read_requests_r) &&
           (rope_adapter_read_responses_w ==
            batch2_expected_read_requests_r) &&
           (rope_adapter_read_bytes_w == batch2_expected_read_bytes_r) &&
           (rope_adapter_write_requests_w ==
            batch2_expected_write_requests_r) &&
           (rope_adapter_write_responses_w ==
            batch2_expected_write_requests_r) &&
           (rope_adapter_write_bytes_w == batch2_expected_write_bytes_r) &&
           (rope_adapter_sincos_req_w == 64'd32) &&
           (rope_adapter_sincos_rsp_w == 64'd32) &&
           (rope_adapter_theta_req_w == 64'd96) &&
           (rope_adapter_theta_rsp_w == 64'd96) &&
           (rope_adapter_data_mul_req_w ==
            (batch2_profile_id_r == 8'd0 ? 64'd512 : 64'd128)) &&
           (rope_adapter_data_mul_rsp_w ==
            (batch2_profile_id_r == 8'd0 ? 64'd512 : 64'd128)) &&
           (rope_adapter_fma_req_w ==
            (batch2_profile_id_r == 8'd0 ? 64'd512 : 64'd128)) &&
           (rope_adapter_fma_rsp_w ==
            (batch2_profile_id_r == 8'd0 ? 64'd512 : 64'd128))) : 1'b0))));

  assign selected_macro_gmem_req_valid_w = functional_command_select_w ?
      1'b0 : (macro_select_vector_w ?
      macro_gmem_req_valid_w : (macro_select_q8_w ?
      q8_gmem_req_valid_w : (macro_select_gemv_w ?
      gemv_gmem_req_valid_w : (macro_select_f32_move_w ?
      f32_move_gmem_req_valid_w : (macro_select_argmax_w ?
      argmax_gmem_req_valid_w : (macro_select_exact_profile_w ?
      exact_selected_gmem_req_valid_w : (macro_select_batch2_profile_w ?
      batch2_selected_gmem_req_valid_w : 1'b0)))))));
  assign selected_macro_gmem_req_write_w = functional_command_select_w ?
      1'b0 : (macro_select_vector_w ?
      macro_gmem_req_write_w : (macro_select_q8_w ?
      q8_gmem_req_write_w : (macro_select_gemv_w ?
      gemv_gmem_req_write_w : (macro_select_f32_move_w ?
      f32_move_gmem_req_write_w : (macro_select_argmax_w ?
      argmax_gmem_req_write_w : (macro_select_exact_profile_w ?
      exact_selected_gmem_req_write_w : (macro_select_batch2_profile_w ?
      batch2_selected_gmem_req_write_w : 1'b0)))))));
  assign selected_macro_gmem_req_addr_w = functional_command_select_w ?
      64'd0 : (macro_select_vector_w ?
      macro_gmem_req_addr_w : (macro_select_q8_w ?
      q8_gmem_req_addr_w : (macro_select_gemv_w ?
      gemv_gmem_req_addr_w : (macro_select_f32_move_w ?
      f32_move_gmem_req_addr_w : (macro_select_argmax_w ?
      argmax_gmem_req_addr_w : (macro_select_exact_profile_w ?
      exact_selected_gmem_req_addr_w : (macro_select_batch2_profile_w ?
      batch2_selected_gmem_req_addr_w : 64'd0)))))));
  assign selected_macro_gmem_req_wdata_w = functional_command_select_w ?
      64'd0 : (macro_select_vector_w ?
      macro_gmem_req_wdata_w : (macro_select_q8_w ?
      q8_gmem_req_wdata_w : (macro_select_gemv_w ?
      gemv_gmem_req_wdata_w : (macro_select_f32_move_w ?
      f32_move_gmem_req_wdata_w : (macro_select_argmax_w ?
      argmax_gmem_req_wdata_w : (macro_select_exact_profile_w ?
      exact_selected_gmem_req_wdata_w : (macro_select_batch2_profile_w ?
      batch2_selected_gmem_req_wdata_w : 64'd0)))))));
  assign selected_macro_gmem_req_wstrb_w = functional_command_select_w ?
      8'd0 : (macro_select_vector_w ?
      macro_gmem_req_wstrb_w : (macro_select_q8_w ?
      q8_gmem_req_wstrb_w : (macro_select_gemv_w ?
      gemv_gmem_req_wstrb_w : (macro_select_f32_move_w ?
      f32_move_gmem_req_wstrb_w : (macro_select_argmax_w ?
      argmax_gmem_req_wstrb_w : (macro_select_exact_profile_w ?
      exact_selected_gmem_req_wstrb_w : (macro_select_batch2_profile_w ?
      batch2_selected_gmem_req_wstrb_w : 8'd0)))))));
  assign selected_macro_gmem_rsp_ready_w = functional_command_select_w ?
      1'b0 : (macro_select_vector_w ?
      macro_gmem_rsp_ready_w : (macro_select_q8_w ?
      q8_gmem_rsp_ready_w : (macro_select_gemv_w ?
      gemv_gmem_rsp_ready_w : (macro_select_f32_move_w ?
      f32_move_gmem_rsp_ready_w : (macro_select_argmax_w ?
      argmax_gmem_rsp_ready_w : (macro_select_exact_profile_w ?
      exact_selected_gmem_rsp_ready_w : (macro_select_batch2_profile_w ?
      batch2_selected_gmem_rsp_ready_w : 1'b0)))))));

  wire dma_gmem_owner_w;
  wire macro_gmem_owner_w;
  assign dma_gmem_owner_w = (state_q == ST_DMA_RUN);
  assign macro_gmem_owner_w = (state_q == ST_MACRO_RUN);

  assign gmem_req_valid_o = dma_gmem_owner_w ? dma_gmem_req_valid_w :
                            (macro_gmem_owner_w ?
                             selected_macro_gmem_req_valid_w :
                             1'b0);
  assign gmem_req_write_o = dma_gmem_owner_w ? dma_gmem_req_write_w :
                            (macro_gmem_owner_w ?
                             selected_macro_gmem_req_write_w :
                             1'b0);
  assign gmem_req_addr_o = dma_gmem_owner_w ? dma_gmem_req_addr_w :
                           (macro_gmem_owner_w ?
                            selected_macro_gmem_req_addr_w :
                            64'd0);
  assign gmem_req_wdata_o = dma_gmem_owner_w ? dma_gmem_req_wdata_w :
                            (macro_gmem_owner_w ?
                             selected_macro_gmem_req_wdata_w :
                             64'd0);
  assign gmem_req_wstrb_o = dma_gmem_owner_w ? dma_gmem_req_wstrb_w :
                            (macro_gmem_owner_w ?
                             selected_macro_gmem_req_wstrb_w :
                             8'd0);
  assign gmem_rsp_ready_o = dma_gmem_owner_w ? dma_gmem_rsp_ready_w :
                            (macro_gmem_owner_w ?
                             selected_macro_gmem_rsp_ready_w :
                             1'b0);

  assign dma_gmem_req_ready_w = dma_gmem_owner_w ?
                                 gmem_req_ready_i : 1'b0;
  assign dma_gmem_rsp_valid_w = dma_gmem_owner_w ?
                                gmem_rsp_valid_i : 1'b0;
  assign dma_gmem_rsp_rdata_w = dma_gmem_owner_w ?
                                gmem_rsp_rdata_i : 64'd0;
  assign dma_gmem_rsp_error_w = dma_gmem_owner_w ?
                                gmem_rsp_error_i : 1'b0;

  assign macro_gmem_req_ready_w = macro_gmem_owner_w &&
                                  macro_select_vector_w &&
                                  !functional_command_select_w ?
                                   gmem_req_ready_i : 1'b0;
  assign macro_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                  macro_select_vector_w &&
                                  !functional_command_select_w ?
                                  gmem_rsp_valid_i : 1'b0;
  assign macro_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                  macro_select_vector_w &&
                                  !functional_command_select_w ?
                                  gmem_rsp_rdata_i : 64'd0;
  assign macro_gmem_rsp_error_w = macro_gmem_owner_w &&
                                  macro_select_vector_w &&
                                  !functional_command_select_w ?
                                  gmem_rsp_error_i : 1'b0;

  assign q8_gmem_req_ready_w = macro_gmem_owner_w && macro_select_q8_w &&
                               !functional_command_select_w ?
                               gmem_req_ready_i : 1'b0;
  assign q8_gmem_rsp_valid_w = macro_gmem_owner_w && macro_select_q8_w &&
                               !functional_command_select_w ?
                               gmem_rsp_valid_i : 1'b0;
  assign q8_gmem_rsp_rdata_w = macro_gmem_owner_w && macro_select_q8_w &&
                               !functional_command_select_w ?
                               gmem_rsp_rdata_i : 64'd0;
  assign q8_gmem_rsp_error_w = macro_gmem_owner_w && macro_select_q8_w &&
                               !functional_command_select_w ?
                               gmem_rsp_error_i : 1'b0;

  assign gemv_gmem_req_ready_w = macro_gmem_owner_w &&
                                 macro_select_gemv_w &&
                                 !functional_command_select_w ?
                                 gmem_req_ready_i : 1'b0;
  assign gemv_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                 macro_select_gemv_w &&
                                 !functional_command_select_w ?
                                 gmem_rsp_valid_i : 1'b0;
  assign gemv_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                 macro_select_gemv_w &&
                                 !functional_command_select_w ?
                                 gmem_rsp_rdata_i : 64'd0;
  assign gemv_gmem_rsp_error_w = macro_gmem_owner_w &&
                                 macro_select_gemv_w &&
                                 !functional_command_select_w ?
                                 gmem_rsp_error_i : 1'b0;

  assign f32_move_gmem_req_ready_w = macro_gmem_owner_w &&
                                     macro_select_f32_move_w &&
                                     !functional_command_select_w ?
                                     gmem_req_ready_i : 1'b0;
  assign f32_move_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                     macro_select_f32_move_w &&
                                     !functional_command_select_w ?
                                     gmem_rsp_valid_i : 1'b0;
  assign f32_move_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                     macro_select_f32_move_w &&
                                     !functional_command_select_w ?
                                     gmem_rsp_rdata_i : 64'd0;
  assign f32_move_gmem_rsp_error_w = macro_gmem_owner_w &&
                                     macro_select_f32_move_w &&
                                     !functional_command_select_w ?
                                     gmem_rsp_error_i : 1'b0;

  assign argmax_gmem_req_ready_w = macro_gmem_owner_w &&
                                    macro_select_argmax_w &&
                                    !functional_command_select_w ?
                                    gmem_req_ready_i : 1'b0;
  assign argmax_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                    macro_select_argmax_w &&
                                    !functional_command_select_w ?
                                    gmem_rsp_valid_i : 1'b0;
  assign argmax_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                    macro_select_argmax_w &&
                                    !functional_command_select_w ?
                                    gmem_rsp_rdata_i : 64'd0;
  assign argmax_gmem_rsp_error_w = macro_gmem_owner_w &&
                                    macro_select_argmax_w &&
                                    !functional_command_select_w ?
                                    gmem_rsp_error_i : 1'b0;

  assign unary_glu_gmem_req_ready_w = macro_gmem_owner_w &&
                                       macro_select_unary_glu_w ?
                                       gmem_req_ready_i : 1'b0;
  assign unary_glu_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                       macro_select_unary_glu_w ?
                                       gmem_rsp_valid_i : 1'b0;
  assign unary_glu_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                       macro_select_unary_glu_w ?
                                       gmem_rsp_rdata_i : 64'd0;
  assign unary_glu_gmem_rsp_error_w = macro_gmem_owner_w &&
                                       macro_select_unary_glu_w ?
                                       gmem_rsp_error_i : 1'b0;

  assign norm_gmem_req_ready_w = macro_gmem_owner_w &&
                                 macro_select_norm_w ?
                                 gmem_req_ready_i : 1'b0;
  assign norm_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                 macro_select_norm_w ?
                                 gmem_rsp_valid_i : 1'b0;
  assign norm_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                 macro_select_norm_w ?
                                 gmem_rsp_rdata_i : 64'd0;
  assign norm_gmem_rsp_error_w = macro_gmem_owner_w &&
                                 macro_select_norm_w ?
                                 gmem_rsp_error_i : 1'b0;

  assign sum_gmem_req_ready_w = macro_gmem_owner_w &&
                                macro_select_sum_w ?
                                gmem_req_ready_i : 1'b0;
  assign sum_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                macro_select_sum_w ?
                                gmem_rsp_valid_i : 1'b0;
  assign sum_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                macro_select_sum_w ?
                                gmem_rsp_rdata_i : 64'd0;
  assign sum_gmem_rsp_error_w = macro_gmem_owner_w &&
                                macro_select_sum_w ?
                                gmem_rsp_error_i : 1'b0;

  assign ssm_gmem_req_ready_w = macro_gmem_owner_w &&
                                macro_select_ssm_w ?
                                gmem_req_ready_i : 1'b0;
  assign ssm_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                macro_select_ssm_w ?
                                gmem_rsp_valid_i : 1'b0;
  assign ssm_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                macro_select_ssm_w ?
                                gmem_rsp_rdata_i : 64'd0;
  assign ssm_gmem_rsp_error_w = macro_gmem_owner_w &&
                                macro_select_ssm_w ?
                                gmem_rsp_error_i : 1'b0;

  assign mover_gmem_req_ready_w = macro_gmem_owner_w &&
                                  macro_select_mover_set_w &&
                                  !functional_command_select_w ?
                                  gmem_req_ready_i : 1'b0;
  assign mover_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                  macro_select_mover_set_w &&
                                  !functional_command_select_w ?
                                  gmem_rsp_valid_i : 1'b0;
  assign mover_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                  macro_select_mover_set_w &&
                                  !functional_command_select_w ?
                                  gmem_rsp_rdata_i : 64'd0;
  assign mover_gmem_rsp_error_w = macro_gmem_owner_w &&
                                  macro_select_mover_set_w &&
                                  !functional_command_select_w ?
                                  gmem_rsp_error_i : 1'b0;

  assign attention_gmem_req_ready_w = macro_gmem_owner_w &&
                                      macro_select_attention_w ?
                                      gmem_req_ready_i : 1'b0;
  assign attention_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                      macro_select_attention_w ?
                                      gmem_rsp_valid_i : 1'b0;
  assign attention_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                      macro_select_attention_w ?
                                      gmem_rsp_rdata_i : 64'd0;
  assign attention_gmem_rsp_error_w = macro_gmem_owner_w &&
                                      macro_select_attention_w ?
                                      gmem_rsp_error_i : 1'b0;

  assign softmax_gmem_req_ready_w = macro_gmem_owner_w &&
                                    macro_select_softmax_w ?
                                    gmem_req_ready_i : 1'b0;
  assign softmax_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                    macro_select_softmax_w ?
                                    gmem_rsp_valid_i : 1'b0;
  assign softmax_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                    macro_select_softmax_w ?
                                    gmem_rsp_rdata_i : 64'd0;
  assign softmax_gmem_rsp_error_w = macro_gmem_owner_w &&
                                    macro_select_softmax_w ?
                                    gmem_rsp_error_i : 1'b0;

  assign rope_gmem_req_ready_w = macro_gmem_owner_w &&
                                 macro_select_rope_w ?
                                 gmem_req_ready_i : 1'b0;
  assign rope_gmem_rsp_valid_w = macro_gmem_owner_w &&
                                 macro_select_rope_w ?
                                 gmem_rsp_valid_i : 1'b0;
  assign rope_gmem_rsp_rdata_w = macro_gmem_owner_w &&
                                 macro_select_rope_w ?
                                 gmem_rsp_rdata_i : 64'd0;
  assign rope_gmem_rsp_error_w = macro_gmem_owner_w &&
                                 macro_select_rope_w ?
                                 gmem_rsp_error_i : 1'b0;

  // ------------------------------------------------------------------------
  // LMEM owner mux: engine state has priority, otherwise the debug host owns
  // the same public ports.  No engine can be active concurrently by top FSM.
  // ------------------------------------------------------------------------
  assign host_lmem_ready_o = ((state_q == ST_IDLE) ||
                              (state_q == ST_ERROR_HOLD)) &&
                             !cmd_valid_i && !macro_cmd_valid_i &&
                             !desc_write_valid_i;

  reg lmem_rd0_valid_mux;
  reg [31:0] lmem_rd0_addr_mux;
  reg [3:0] lmem_rd0_bytes_mux;
  reg lmem_rd1_valid_mux;
  reg [31:0] lmem_rd1_addr_mux;
  reg [3:0] lmem_rd1_bytes_mux;
  reg lmem_wr_valid_mux;
  reg [31:0] lmem_wr_addr_mux;
  reg [63:0] lmem_wr_data_mux;
  reg [7:0] lmem_wr_strb_mux;

  always @(*) begin
    lmem_rd0_valid_mux = host_lmem_ready_o && host_lmem_rd_valid_i;
    lmem_rd0_addr_mux = host_lmem_rd_addr_i;
    lmem_rd0_bytes_mux = host_lmem_rd_bytes_i;
    lmem_rd1_valid_mux = 1'b0;
    lmem_rd1_addr_mux = 32'd0;
    lmem_rd1_bytes_mux = 4'd0;
    lmem_wr_valid_mux = host_lmem_ready_o && host_lmem_wr_valid_i;
    lmem_wr_addr_mux = host_lmem_wr_addr_i;
    lmem_wr_data_mux = host_lmem_wr_data_i;
    lmem_wr_strb_mux = host_lmem_wr_strb_i;

    if (state_q == ST_TIU_RUN) begin
      lmem_rd0_valid_mux = mm2_rd0_valid_w;
      lmem_rd0_addr_mux = mm2_rd0_addr_w;
      lmem_rd0_bytes_mux = mm2_rd0_bytes_w;
      lmem_rd1_valid_mux = mm2_rd1_valid_w;
      lmem_rd1_addr_mux = mm2_rd1_addr_w;
      lmem_rd1_bytes_mux = mm2_rd1_bytes_w;
      lmem_wr_valid_mux = mm2_wr_valid_w;
      lmem_wr_addr_mux = mm2_wr_addr_w;
      lmem_wr_data_mux = mm2_wr_data_w;
      lmem_wr_strb_mux = mm2_wr_strb_w;
    end else if (state_q == ST_DMA_RUN) begin
      lmem_rd0_valid_mux = dma_rd_valid_w;
      lmem_rd0_addr_mux = dma_rd_addr_w;
      lmem_rd0_bytes_mux = dma_rd_bytes_w;
      lmem_rd1_valid_mux = 1'b0;
      lmem_rd1_addr_mux = 32'd0;
      lmem_rd1_bytes_mux = 4'd0;
      lmem_wr_valid_mux = dma_wr_valid_w;
      lmem_wr_addr_mux = dma_wr_addr_w;
      lmem_wr_data_mux = dma_wr_data_w;
      lmem_wr_strb_mux = dma_wr_strb_w;
    end
  end

  TensorNpuLocalMemory #(.LMEM_BYTES(LMEM_BYTES)) u_lmem (
    .clk(clk),
    .rd0_valid_i(lmem_rd0_valid_mux),
    .rd0_addr_i(lmem_rd0_addr_mux),
    .rd0_bytes_i(lmem_rd0_bytes_mux),
    .rd0_data_o(lmem_rd0_data_w),
    .rd0_oob_o(lmem_rd0_oob_w),
    .rd1_valid_i(lmem_rd1_valid_mux),
    .rd1_addr_i(lmem_rd1_addr_mux),
    .rd1_bytes_i(lmem_rd1_bytes_mux),
    .rd1_data_o(lmem_rd1_data_w),
    .rd1_oob_o(lmem_rd1_oob_w),
    .wr_valid_i(lmem_wr_valid_mux),
    .wr_addr_i(lmem_wr_addr_mux),
    .wr_data_i(lmem_wr_data_mux),
    .wr_strb_i(lmem_wr_strb_mux),
    .wr_oob_o(lmem_wr_oob_w)
  );

  assign host_lmem_rd_data_o = host_lmem_ready_o ? lmem_rd0_data_w : 64'd0;
  assign host_lmem_rd_oob_o = host_lmem_ready_o && host_lmem_rd_valid_i &&
                              lmem_rd0_oob_w;
  assign host_lmem_wr_oob_o = host_lmem_ready_o && host_lmem_wr_valid_i &&
                              lmem_wr_oob_w;

  // ------------------------------------------------------------------------
  // Top-level transaction state and counters.
  // ------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      state_q <= ST_IDLE;
      cmd_is_64_q <= 1'b0;
      cmd_bits_q <= 64'd0;
      cmd_rs_value_q <= 64'd0;
      cmd_producer_id_q <= {PID_W{1'b0}};
      cmd_npu_required_q <= 1'b0;
      cmd_opclass_q <= {OPCLASS_W{1'b0}};
      macro_transaction_q <= 1'b0;
      macro_abi_valid_q <= 1'b0;
      macro_kernel_id_q <= 32'd0;
      macro_command_flags_q <= 32'd0;
      macro_context_id_q <= 32'd0;
      macro_capability_epoch_q <= 32'd0;
      macro_sequence_id_q <= 64'd0;
      macro_producer_id_q <= 64'd0;
      macro_user_tag_q <= 64'd0;
      macro_node_count_q <= 32'd0;
      macro_node_hash_lo_q <= 64'd0;
      macro_node_hash_hi_q <= 64'd0;
      macro_deadline_cycles_q <= 64'd0;
      macro_vector_op_q <= 32'd0;
      macro_vector_flags_q <= 32'd0;
      macro_src0_iova_q <= 64'd0;
      macro_src1_iova_q <= 64'd0;
      macro_src2_iova_q <= 64'd0;
      macro_dst_iova_q <= 64'd0;
      macro_scratch_iova_q <= 64'd0;
      macro_element_count_q <= 64'd0;
      macro_outer_count_q <= 32'd0;
      macro_dtype_q <= 32'd0;
      macro_src0_stride_q <= 64'd0;
      macro_src1_stride_q <= 64'd0;
      macro_src2_stride_q <= 64'd0;
      macro_dst_stride_q <= 64'd0;
      macro_scalar0_q <= 32'd0;
      macro_scalar1_q <= 32'd0;
      macro_scratch_bytes_q <= 32'd0;
      macro_rope_position_q <= 32'd0;
      macro_src0_window_base_q <= 64'd0;
      macro_src0_window_size_q <= 64'd0;
      macro_src0_window_perm_q <= 2'd0;
      macro_src1_window_base_q <= 64'd0;
      macro_src1_window_size_q <= 64'd0;
      macro_src1_window_perm_q <= 2'd0;
      macro_dst_window_base_q <= 64'd0;
      macro_dst_window_size_q <= 64'd0;
      macro_dst_window_perm_q <= 2'd0;
      macro_windows_generation_valid_q <= 1'b0;
      macro_completion_status_q <= 32'd0;
      macro_completion_error_class_q <= 32'd0;
      macro_cycles_q <= 64'd0;
      macro_completion_cycles_q <= 64'd0;
      macro_completion_read_bytes_q <= 64'd0;
      macro_completion_write_bytes_q <= 64'd0;
      macro_completion_q8_mac_count_q <= 64'd0;
      macro_completion_vector_elements_q <= 64'd0;
      functional_dispatch_baseline_q <= 64'd0;
      functional_completion_baseline_q <= 64'd0;
      terminal_error_q <= 1'b0;
      terminal_error_code_q <= `NPU_ERR_NONE;
      sticky_error_q <= 1'b0;
      sticky_error_code_q <= `NPU_ERR_NONE;
      command_count_q <= 64'd0;
      completion_count_q <= 64'd0;
      error_count_q <= 64'd0;
      npu_required_issued_q <= 64'd0;
      npu_required_completed_q <= 64'd0;
      tiu_cycles_q <= 64'd0;
      dma_cycles_q <= 64'd0;
      dma_bytes_q <= 64'd0;
      macro_command_count_q <= 64'd0;
      macro_f32_start_count_q <= 64'd0;
      macro_completion_count_q <= 64'd0;
    end else begin
      case (state_q)
        ST_IDLE: begin
          terminal_error_q <= 1'b0;
          terminal_error_code_q <= `NPU_ERR_NONE;
          if (cmd_valid_i && cmd_ready_o) begin
            macro_transaction_q <= 1'b0;
            cmd_is_64_q <= cmd_is_64_i;
            cmd_bits_q <= cmd_bits_i;
            cmd_rs_value_q <= cmd_rs_value_i;
            cmd_producer_id_q <= cmd_producer_id_i;
            cmd_npu_required_q <= cmd_npu_required_i;
            cmd_opclass_q <= cmd_opclass_i;
            command_count_q <= command_count_q + 64'd1;
            if (cmd_npu_required_i)
              npu_required_issued_q <= npu_required_issued_q + 64'd1;
            state_q <= ST_DECODE;
          end else if (macro_cmd_valid_i && macro_cmd_ready_o) begin
            macro_transaction_q <= 1'b1;
            macro_abi_valid_q <= macro_abi_valid_i;
            macro_kernel_id_q <= macro_kernel_id_i;
            macro_command_flags_q <= macro_command_flags_i;
            macro_context_id_q <= macro_context_id_i;
            macro_capability_epoch_q <= macro_capability_epoch_i;
            macro_sequence_id_q <= macro_sequence_id_i;
            macro_producer_id_q <= macro_producer_id_i;
            macro_user_tag_q <= macro_user_tag_i;
            macro_node_count_q <= macro_node_count_i;
            macro_node_hash_lo_q <= macro_node_hash_lo_i;
            macro_node_hash_hi_q <= macro_node_hash_hi_i;
            macro_deadline_cycles_q <= macro_deadline_cycles_i;
            macro_vector_op_q <= macro_vector_op_i;
            macro_vector_flags_q <= macro_vector_flags_i;
            macro_src0_iova_q <= macro_src0_iova_i;
            macro_src1_iova_q <= macro_src1_iova_i;
            macro_src2_iova_q <= macro_src2_iova_i;
            macro_dst_iova_q <= macro_dst_iova_i;
            macro_scratch_iova_q <= macro_scratch_iova_i;
            macro_element_count_q <= macro_element_count_i;
            macro_outer_count_q <= macro_outer_count_i;
            macro_dtype_q <= macro_dtype_i;
            macro_src0_stride_q <= macro_src0_stride_i;
            macro_src1_stride_q <= macro_src1_stride_i;
            macro_src2_stride_q <= macro_src2_stride_i;
            macro_dst_stride_q <= macro_dst_stride_i;
            macro_scalar0_q <= macro_scalar0_i;
            macro_scalar1_q <= macro_scalar1_i;
            macro_scratch_bytes_q <= macro_scratch_bytes_i;
            macro_rope_position_q <= macro_rope_position_i;
            macro_src0_window_base_q <= macro_src0_window_base_i;
            macro_src0_window_size_q <= macro_src0_window_size_i;
            macro_src0_window_perm_q <= macro_src0_window_perm_i;
            macro_src1_window_base_q <= macro_src1_window_base_i;
            macro_src1_window_size_q <= macro_src1_window_size_i;
            macro_src1_window_perm_q <= macro_src1_window_perm_i;
            macro_dst_window_base_q <= macro_dst_window_base_i;
            macro_dst_window_size_q <= macro_dst_window_size_i;
            macro_dst_window_perm_q <= macro_dst_window_perm_i;
            macro_windows_generation_valid_q <=
                macro_windows_generation_valid_i;
            macro_completion_status_q <= 32'd0;
            macro_completion_error_class_q <= 32'd0;
            macro_cycles_q <= 64'd0;
            macro_completion_cycles_q <= 64'd0;
            macro_completion_read_bytes_q <= 64'd0;
            macro_completion_write_bytes_q <= 64'd0;
            macro_completion_q8_mac_count_q <= 64'd0;
            macro_completion_vector_elements_q <= 64'd0;
            command_count_q <= command_count_q + 64'd1;
            macro_command_count_q <= macro_command_count_q + 64'd1;
            if (macro_command_flags_i[0])
              npu_required_issued_q <= npu_required_issued_q + 64'd1;
            state_q <= ST_MACRO_START;
          end
        end

        ST_DECODE: begin
          if (!dec_legal_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_ILLEGAL_ENCODING;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_ILLEGAL_ENCODING;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (dec_op_w == `NPU_OP_UNSUPPORTED) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_UNSUPPORTED;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_UNSUPPORTED;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (cfg_op_w) begin
            if (rf_cfg_error_w) begin
              terminal_error_q <= 1'b1;
              terminal_error_code_q <= rf_cfg_error_code_w;
              sticky_error_q <= 1'b1;
              sticky_error_code_q <= rf_cfg_error_code_w;
              error_count_q <= error_count_q + 64'd1;
            end else begin
              terminal_error_q <= 1'b0;
              terminal_error_code_q <= `NPU_ERR_NONE;
              completion_count_q <= completion_count_q + 64'd1;
              if (cmd_npu_required_q)
                npu_required_completed_q <= npu_required_completed_q + 64'd1;
            end
            state_q <= ST_COMPLETE;
          end else if (dec_op_w == `NPU_OP_SYNC) begin
            // The MVP top is globally serialized, so reaching DECODE proves
            // every older TIU/GDMA command has terminated.  Retain an explicit
            // engine check here rather than relying only on decoder legality.
            if (dec_sync_engine_w > 2'd2) begin
              terminal_error_q <= 1'b1;
              terminal_error_code_q <= `NPU_ERR_SYNC_ENGINE;
              sticky_error_q <= 1'b1;
              sticky_error_code_q <= `NPU_ERR_SYNC_ENGINE;
              error_count_q <= error_count_q + 64'd1;
            end else begin
              terminal_error_q <= 1'b0;
              terminal_error_code_q <= `NPU_ERR_NONE;
              completion_count_q <= completion_count_q + 64'd1;
              if (cmd_npu_required_q)
                npu_required_completed_q <= npu_required_completed_q + 64'd1;
            end
            state_q <= ST_COMPLETE;
          end else if (mm2_op_w) begin
            state_q <= ST_TIU_RUN;
          end else if (dma_op_w) begin
            state_q <= ST_DMA_RUN;
          end else begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_UNSUPPORTED;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_UNSUPPORTED;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end
        end

        ST_TIU_RUN: begin
          if (mm2_done_w) begin
            terminal_error_q <= 1'b0;
            terminal_error_code_q <= `NPU_ERR_NONE;
            completion_count_q <= completion_count_q + 64'd1;
            if (cmd_npu_required_q)
              npu_required_completed_q <= npu_required_completed_q + 64'd1;
            tiu_cycles_q <= tiu_cycles_q + mm2_cycles_w;
            state_q <= ST_COMPLETE;
          end else if (mm2_error_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= mm2_error_code_w;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= mm2_error_code_w;
            error_count_q <= error_count_q + 64'd1;
            tiu_cycles_q <= tiu_cycles_q + mm2_cycles_w;
            state_q <= ST_COMPLETE;
          end
        end

        ST_DMA_RUN: begin
          if (dma_done_w) begin
            terminal_error_q <= 1'b0;
            terminal_error_code_q <= `NPU_ERR_NONE;
            completion_count_q <= completion_count_q + 64'd1;
            if (cmd_npu_required_q)
              npu_required_completed_q <= npu_required_completed_q + 64'd1;
            dma_cycles_q <= dma_cycles_q + dma_engine_cycles_w;
            dma_bytes_q <= dma_bytes_q + dma_engine_bytes_w;
            state_q <= ST_COMPLETE;
          end else if (dma_error_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= dma_error_code_w;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= dma_error_code_w;
            error_count_q <= error_count_q + 64'd1;
            dma_cycles_q <= dma_cycles_q + dma_engine_cycles_w;
            dma_bytes_q <= dma_bytes_q + dma_engine_bytes_w;
            state_q <= ST_COMPLETE;
          end
        end

        ST_MACRO_START: begin
          macro_cycles_q <= macro_cycles_q + 64'd1;
          if (!macro_select_vector_w && !macro_select_q8_w &&
              !macro_select_gemv_w && !macro_select_f32_move_w &&
              !macro_select_argmax_w && !macro_select_exact_kernel_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_CAPABILITY};
            macro_completion_error_class_q <= ABI_ERROR_CAPABILITY;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (functional_vector_zero_cardinality_w) begin
            // A canonical steady-state cache_r/cache_s SCALE with ne0=0 is
            // complete at admission: the exact descriptor was checked above,
            // no F32/functional child is started, and no portal or public GMEM
            // request is legal.  It still closes one REQUIRED NPU lifecycle.
            terminal_error_q <= 1'b0;
            terminal_error_code_q <= `NPU_ERR_NONE;
            macro_completion_status_q <= 32'd0;
            macro_completion_error_class_q <= 32'd0;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            macro_completion_read_bytes_q <= 64'd0;
            macro_completion_write_bytes_q <= 64'd0;
            macro_completion_q8_mac_count_q <= 64'd0;
            macro_completion_vector_elements_q <= 64'd0;
            completion_count_q <= completion_count_q + 64'd1;
            macro_completion_count_q <= macro_completion_count_q + 64'd1;
            npu_required_completed_q <=
                npu_required_completed_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_q8_w && q8_abi_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_ABI};
            macro_completion_error_class_q <= ABI_ERROR_ABI;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_ABI;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_q8_w && q8_capability_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_CAPABILITY};
            macro_completion_error_class_q <= ABI_ERROR_CAPABILITY;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_q8_w && q8_layout_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_LAYOUT};
            macro_completion_error_class_q <= ABI_ERROR_LAYOUT;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_q8_w && q8_iova_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_IOVA};
            macro_completion_error_class_q <= ABI_ERROR_IOVA;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_IOVA;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_gemv_w && gemv_abi_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_ABI};
            macro_completion_error_class_q <= ABI_ERROR_ABI;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_ABI;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_gemv_w && gemv_capability_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_CAPABILITY};
            macro_completion_error_class_q <= ABI_ERROR_CAPABILITY;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_gemv_w && gemv_layout_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_LAYOUT};
            macro_completion_error_class_q <= ABI_ERROR_LAYOUT;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_gemv_w && gemv_iova_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_IOVA};
            macro_completion_error_class_q <= ABI_ERROR_IOVA;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_IOVA;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (gemv_empty_w) begin
            // A canonical N=0 GEMV is still a real required NPU transaction:
            // the descriptor and full identity are checked above, while the
            // Coprocessor owns a zero-traffic SUCCESS terminal.  Do not start
            // the portal/functional child for this path.
            terminal_error_q <= 1'b0;
            terminal_error_code_q <= `NPU_ERR_NONE;
            macro_completion_status_q <= 32'd0;
            macro_completion_error_class_q <= 32'd0;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            macro_completion_read_bytes_q <= 64'd0;
            macro_completion_write_bytes_q <= 64'd0;
            macro_completion_q8_mac_count_q <= 64'd0;
            macro_completion_vector_elements_q <= 64'd0;
            completion_count_q <= completion_count_q + 64'd1;
            macro_completion_count_q <= macro_completion_count_q + 64'd1;
            if (macro_command_flags_q[0])
              npu_required_completed_q <=
                  npu_required_completed_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_f32_move_w &&
                       f32_move_abi_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_ABI};
            macro_completion_error_class_q <= ABI_ERROR_ABI;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_ABI;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_f32_move_w &&
                       f32_move_capability_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_CAPABILITY};
            macro_completion_error_class_q <= ABI_ERROR_CAPABILITY;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_f32_move_w &&
                       f32_move_layout_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_LAYOUT};
            macro_completion_error_class_q <= ABI_ERROR_LAYOUT;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_f32_move_w &&
                       f32_move_iova_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_IOVA};
            macro_completion_error_class_q <= ABI_ERROR_IOVA;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_IOVA;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_argmax_w && argmax_abi_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_ABI};
            macro_completion_error_class_q <= ABI_ERROR_ABI;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_ABI;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_argmax_w &&
                       argmax_capability_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_CAPABILITY};
            macro_completion_error_class_q <= ABI_ERROR_CAPABILITY;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_argmax_w && argmax_layout_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_LAYOUT};
            macro_completion_error_class_q <= ABI_ERROR_LAYOUT;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_argmax_w && argmax_iova_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_IOVA};
            macro_completion_error_class_q <= ABI_ERROR_IOVA;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_IOVA;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_batch2_kernel_w &&
                       batch2_abi_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_ABI};
            macro_completion_error_class_q <= ABI_ERROR_ABI;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_ABI;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_batch2_kernel_w &&
                       batch2_capability_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_CAPABILITY};
            macro_completion_error_class_q <= ABI_ERROR_CAPABILITY;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_batch2_kernel_w &&
                       batch2_layout_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_LAYOUT};
            macro_completion_error_class_q <= ABI_ERROR_LAYOUT;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_batch2_kernel_w &&
                       batch2_iova_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_IOVA};
            macro_completion_error_class_q <= ABI_ERROR_IOVA;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_IOVA;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (batch2_empty_cpy_w) begin
            // Profiles 3 and 5 are canonical CPY nodes with ne1=0.  The
            // Coprocessor has already checked the complete descriptor,
            // capabilities, windows and full identity above.  Own their
            // lifecycle as a real zero-traffic NPU SUCCESS without starting
            // the mover child, whose non-empty protocol requires at least one
            // source/destination element.
            terminal_error_q <= 1'b0;
            terminal_error_code_q <= `NPU_ERR_NONE;
            macro_completion_status_q <= 32'd0;
            macro_completion_error_class_q <= 32'd0;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            macro_completion_read_bytes_q <= 64'd0;
            macro_completion_write_bytes_q <= 64'd0;
            macro_completion_q8_mac_count_q <= 64'd0;
            macro_completion_vector_elements_q <= 64'd0;
            completion_count_q <= completion_count_q + 64'd1;
            macro_completion_count_q <= macro_completion_count_q + 64'd1;
            if (macro_command_flags_q[0])
              npu_required_completed_q <=
                  npu_required_completed_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_exact_kernel_w &&
                       !macro_select_batch2_kernel_w &&
                       exact_abi_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_ABI;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_ABI};
            macro_completion_error_class_q <= ABI_ERROR_ABI;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_ABI;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_exact_kernel_w &&
                       !macro_select_batch2_kernel_w &&
                       exact_capability_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_CAPABILITY};
            macro_completion_error_class_q <= ABI_ERROR_CAPABILITY;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_CAPABILITY;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_exact_kernel_w &&
                       !macro_select_batch2_kernel_w &&
                       exact_layout_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_LAYOUT};
            macro_completion_error_class_q <= ABI_ERROR_LAYOUT;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_LAYOUT;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if (macro_select_exact_kernel_w &&
                       !macro_select_batch2_kernel_w &&
                       exact_iova_reject_w) begin
            terminal_error_q <= 1'b1;
            terminal_error_code_q <= `NPU_ERR_MACRO_IOVA;
            macro_completion_status_q <= {24'd0, `NPU_ERR_MACRO_IOVA};
            macro_completion_error_class_q <= ABI_ERROR_IOVA;
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            sticky_error_q <= 1'b1;
            sticky_error_code_q <= `NPU_ERR_MACRO_IOVA;
            error_count_q <= error_count_q + 64'd1;
            state_q <= ST_COMPLETE;
          end else if ((functional_command_start_valid_w &&
                        functional_command_ready_w) ||
                       (macro_adapter_start_valid_w &&
                        macro_adapter_start_ready_w) ||
                       (q8_adapter_start_w && q8_adapter_ready_w) ||
                       (gemv_adapter_start_w &&
                        gemv_adapter_ready_w) ||
                       (f32_move_adapter_start_w &&
                        f32_move_adapter_ready_w) ||
                       (argmax_adapter_start_w &&
                        argmax_adapter_ready_w) ||
                       (unary_glu_adapter_start_w &&
                        unary_glu_adapter_ready_w) ||
                       (norm_adapter_start_w && norm_adapter_ready_w) ||
                       (sum_adapter_start_w && sum_adapter_ready_w) ||
                       (ssm_adapter_start_w && ssm_adapter_ready_w) ||
                       (mover_adapter_start_w && mover_adapter_ready_w) ||
                       (attention_adapter_start_w &&
                        attention_adapter_ready_w) ||
                       (softmax_adapter_start_w &&
                        softmax_adapter_ready_w) ||
                       (rope_adapter_start_w && rope_adapter_ready_w)) begin
            if (functional_command_start_valid_w &&
                functional_command_ready_w) begin
              functional_dispatch_baseline_q <=
                  functional_command_dispatch_count_w;
              functional_completion_baseline_q <=
                  functional_command_completion_count_w;
            end
            state_q <= ST_MACRO_RUN;
          end
        end

        ST_MACRO_RUN: begin
          macro_cycles_q <= macro_cycles_q + 64'd1;
          if (macro_adapter_f32_start_pulse_w)
            macro_f32_start_count_q <=
                macro_f32_start_count_q + 64'd1;

          if (selected_macro_done_w || selected_macro_error_w) begin
            macro_completion_cycles_q <= macro_cycles_q + 64'd1;
            macro_completion_read_bytes_q <=
                selected_macro_read_bytes_w;
            macro_completion_write_bytes_q <=
                selected_macro_write_bytes_w;
            macro_completion_q8_mac_count_q <=
                selected_macro_q8_mac_count_w;
            macro_completion_vector_elements_q <=
                selected_macro_vector_elements_w;

            if ((selected_macro_done_w && selected_macro_error_w) ||
                selected_macro_gmem_outstanding_w ||
                !selected_macro_terminal_identity_ok_w) begin
              terminal_error_q <= 1'b1;
              terminal_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
              macro_completion_status_q <=
                  {24'd0, `NPU_ERR_MACRO_PROTOCOL};
              macro_completion_error_class_q <= 32'd11;
              sticky_error_q <= 1'b1;
              sticky_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
              error_count_q <= error_count_q + 64'd1;
              state_q <= ST_COMPLETE;
            end else if (selected_macro_error_w) begin
              terminal_error_q <= 1'b1;
              if ((selected_macro_error_code_w == `NPU_ERR_NONE) ||
                  (selected_macro_error_class_w == 32'd0)) begin
                terminal_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
                macro_completion_status_q <=
                    {24'd0, `NPU_ERR_MACRO_PROTOCOL};
                macro_completion_error_class_q <= 32'd11;
                sticky_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
              end else begin
                terminal_error_code_q <= selected_macro_error_code_w;
                macro_completion_status_q <=
                    {24'd0, selected_macro_error_code_w};
                macro_completion_error_class_q <=
                    selected_macro_error_class_w;
                sticky_error_code_q <= selected_macro_error_code_w;
              end
              sticky_error_q <= 1'b1;
              error_count_q <= error_count_q + 64'd1;
              state_q <= ST_COMPLETE;
            end else if ((selected_macro_read_bytes_w !=
                          selected_macro_expected_read_bytes_w) ||
                         (selected_macro_write_bytes_w !=
                          selected_macro_expected_write_bytes_w) ||
                         (selected_macro_q8_mac_count_w !=
                          selected_macro_expected_q8_mac_count_w) ||
                         (selected_macro_vector_elements_w !=
                          selected_macro_expected_vector_elements_w) ||
                         !functional_command_success_counts_ok_w ||
                         !q8_success_counts_ok_w ||
                         !gemv_success_counts_ok_w ||
                         !f32_move_success_counts_ok_w ||
                         !argmax_success_counts_ok_w ||
                         !exact_success_counts_ok_w ||
                         !batch2_success_counts_ok_w) begin
              terminal_error_q <= 1'b1;
              terminal_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
              macro_completion_status_q <=
                  {24'd0, `NPU_ERR_MACRO_PROTOCOL};
              macro_completion_error_class_q <= 32'd11;
              sticky_error_q <= 1'b1;
              sticky_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
              error_count_q <= error_count_q + 64'd1;
              state_q <= ST_COMPLETE;
            end else begin
              terminal_error_q <= 1'b0;
              terminal_error_code_q <= `NPU_ERR_NONE;
              macro_completion_status_q <= 32'd0;
              macro_completion_error_class_q <= 32'd0;
              completion_count_q <= completion_count_q + 64'd1;
              macro_completion_count_q <=
                  macro_completion_count_q + 64'd1;
              if (macro_command_flags_q[0])
                npu_required_completed_q <=
                    npu_required_completed_q + 64'd1;
              state_q <= ST_COMPLETE;
            end
          end
        end

        ST_COMPLETE: begin
          if (completion_valid_o && completion_ready_i) begin
            if (terminal_error_q)
              state_q <= ST_ERROR_HOLD;
            else
              state_q <= ST_IDLE;
          end
        end

        ST_ERROR_HOLD: begin
          if (error_clear_i) begin
            sticky_error_q <= 1'b0;
            sticky_error_code_q <= `NPU_ERR_NONE;
            state_q <= ST_IDLE;
          end
        end

        default: begin
          terminal_error_q <= 1'b1;
          sticky_error_q <= 1'b1;
          if (macro_transaction_q) begin
            terminal_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
            sticky_error_code_q <= `NPU_ERR_MACRO_PROTOCOL;
            macro_completion_status_q <=
                {24'd0, `NPU_ERR_MACRO_PROTOCOL};
            macro_completion_error_class_q <= 32'd11;
            macro_completion_cycles_q <= macro_cycles_q;
            macro_completion_read_bytes_q <=
                selected_macro_read_bytes_w;
            macro_completion_write_bytes_q <=
                selected_macro_write_bytes_w;
            macro_completion_q8_mac_count_q <=
                selected_macro_q8_mac_count_w;
            macro_completion_vector_elements_q <=
                selected_macro_vector_elements_w;
          end else begin
            terminal_error_code_q <= `NPU_ERR_INTERNAL_STATE;
            sticky_error_code_q <= `NPU_ERR_INTERNAL_STATE;
          end
          error_count_q <= error_count_q + 64'd1;
          state_q <= ST_COMPLETE;
        end
      endcase
    end
  end

`ifdef NPU_ASSERT
  always @(posedge clk) begin
    if (!rst && mm2_start_w && dma_start_w)
      $error("NPU top attempted to start TIU and DMA together");
    if (!rst && (state_q == ST_COMPLETE) && !completion_valid_o)
      $error("NPU completion holder lost valid");
    if (!rst && completion_valid_o && completion_error_o &&
        (completion_error_code_o == `NPU_ERR_NONE))
      $error("NPU error completion carried NONE code");
    if (!rst && (state_q == ST_TIU_RUN) && dma_busy_w)
      $error("NPU DMA became busy under TIU owner");
    if (!rst && (state_q == ST_DMA_RUN) && mm2_busy_w)
      $error("NPU TIU became busy under DMA owner");
    if (!rst && cmd_valid_i && cmd_ready_o &&
        macro_cmd_valid_i && macro_cmd_ready_o)
      $error("NPU top accepted legacy and macro commands together");
    if (!rst && dma_gmem_owner_w && macro_gmem_owner_w)
      $error("NPU top selected two public GMEM owners");
    if (!rst && !dma_gmem_owner_w &&
        (dma_gmem_req_ready_w || dma_gmem_rsp_valid_w ||
         (dma_gmem_rsp_rdata_w != 64'd0) || dma_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner DMA");
    if (!rst && (!macro_gmem_owner_w || !macro_select_vector_w) &&
        (macro_gmem_req_ready_w || macro_gmem_rsp_valid_w ||
         (macro_gmem_rsp_rdata_w != 64'd0) || macro_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner vector adapter");
    if (!rst && (!macro_gmem_owner_w || !macro_select_q8_w) &&
        (q8_gmem_req_ready_w || q8_gmem_rsp_valid_w ||
         (q8_gmem_rsp_rdata_w != 64'd0) || q8_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner Q8 adapter");
    if (!rst && (!macro_gmem_owner_w || !macro_select_gemv_w) &&
        (gemv_gmem_req_ready_w || gemv_gmem_rsp_valid_w ||
         (gemv_gmem_rsp_rdata_w != 64'd0) || gemv_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner GEMV adapter");
    if (!rst && (!macro_gmem_owner_w || !macro_select_f32_move_w) &&
        (f32_move_gmem_req_ready_w || f32_move_gmem_rsp_valid_w ||
         (f32_move_gmem_rsp_rdata_w != 64'd0) ||
         f32_move_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner F32 mover");
    if (!rst && (!macro_gmem_owner_w || !macro_select_argmax_w) &&
        (argmax_gmem_req_ready_w || argmax_gmem_rsp_valid_w ||
         (argmax_gmem_rsp_rdata_w != 64'd0) || argmax_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner F32 ARGMAX");
    if (!rst && (!macro_gmem_owner_w || !macro_select_unary_glu_w) &&
        (unary_glu_gmem_req_ready_w || unary_glu_gmem_rsp_valid_w ||
         (unary_glu_gmem_rsp_rdata_w != 64'd0) ||
         unary_glu_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner unary/GLU");
    if (!rst && (!macro_gmem_owner_w || !macro_select_norm_w) &&
        (norm_gmem_req_ready_w || norm_gmem_rsp_valid_w ||
         (norm_gmem_rsp_rdata_w != 64'd0) || norm_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner norm");
    if (!rst && (!macro_gmem_owner_w || !macro_select_sum_w) &&
        (sum_gmem_req_ready_w || sum_gmem_rsp_valid_w ||
         (sum_gmem_rsp_rdata_w != 64'd0) || sum_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner SUM_ROWS");
    if (!rst && (!macro_gmem_owner_w || !macro_select_ssm_w) &&
        (ssm_gmem_req_ready_w || ssm_gmem_rsp_valid_w ||
         (ssm_gmem_rsp_rdata_w != 64'd0) || ssm_gmem_rsp_error_w))
      $error("NPU top leaked GMEM credit/response to non-owner SSM_CONV");
    if (!rst && macro_gmem_owner_w &&
        ((macro_gmem_req_valid_w && q8_gmem_req_valid_w) ||
         (macro_gmem_req_valid_w && gemv_gmem_req_valid_w) ||
         (macro_gmem_req_valid_w && f32_move_gmem_req_valid_w) ||
         (macro_gmem_req_valid_w && argmax_gmem_req_valid_w) ||
         (q8_gmem_req_valid_w && gemv_gmem_req_valid_w) ||
         (q8_gmem_req_valid_w && f32_move_gmem_req_valid_w) ||
         (q8_gmem_req_valid_w && argmax_gmem_req_valid_w) ||
         (gemv_gmem_req_valid_w && f32_move_gmem_req_valid_w) ||
         (gemv_gmem_req_valid_w && argmax_gmem_req_valid_w) ||
         (f32_move_gmem_req_valid_w && argmax_gmem_req_valid_w)))
      $error("NPU top observed two internal macro GMEM request owners");
    if (!rst && macro_gmem_owner_w &&
        ((unary_glu_gmem_req_valid_w &&
          (macro_gmem_req_valid_w || q8_gmem_req_valid_w ||
           gemv_gmem_req_valid_w || f32_move_gmem_req_valid_w ||
           norm_gmem_req_valid_w || sum_gmem_req_valid_w ||
           ssm_gmem_req_valid_w)) ||
         (norm_gmem_req_valid_w &&
          (macro_gmem_req_valid_w || q8_gmem_req_valid_w ||
           gemv_gmem_req_valid_w || f32_move_gmem_req_valid_w ||
           sum_gmem_req_valid_w || ssm_gmem_req_valid_w)) ||
         (sum_gmem_req_valid_w &&
          (macro_gmem_req_valid_w || q8_gmem_req_valid_w ||
           gemv_gmem_req_valid_w || f32_move_gmem_req_valid_w ||
           ssm_gmem_req_valid_w)) ||
         (ssm_gmem_req_valid_w &&
          (macro_gmem_req_valid_w || q8_gmem_req_valid_w ||
           gemv_gmem_req_valid_w || f32_move_gmem_req_valid_w)) ||
         (argmax_gmem_req_valid_w &&
          (unary_glu_gmem_req_valid_w || norm_gmem_req_valid_w ||
           sum_gmem_req_valid_w || ssm_gmem_req_valid_w))))
      $error("NPU top observed multiple exact-profile GMEM owners");
    if (!rst && ((macro_adapter_start_valid_w && q8_adapter_start_w) ||
                 (macro_adapter_start_valid_w && gemv_adapter_start_w) ||
                 (macro_adapter_start_valid_w &&
                  f32_move_adapter_start_w) ||
                 (macro_adapter_start_valid_w && argmax_adapter_start_w) ||
                 (q8_adapter_start_w && gemv_adapter_start_w) ||
                 (q8_adapter_start_w && f32_move_adapter_start_w) ||
                 (q8_adapter_start_w && argmax_adapter_start_w) ||
                 (gemv_adapter_start_w && f32_move_adapter_start_w) ||
                 (gemv_adapter_start_w && argmax_adapter_start_w) ||
                 (f32_move_adapter_start_w && argmax_adapter_start_w)))
      $error("NPU top attempted to start two macro adapters");
    if (!rst && functional_vector_zero_cardinality_w &&
        (functional_command_start_valid_w || macro_adapter_start_valid_w ||
         macro_adapter_f32_start_pulse_w || macro_gmem_req_valid_w ||
         f32_alu_portal_req_valid_o || f32_alu_portal_rsp_ready_o ||
         f32_alu_portal_outstanding_o))
      $error("NPU zero-cardinality VECTOR_F32 leaked into a child or GMEM path");
    if (!rst &&
        ((unary_glu_adapter_start_w &&
          (macro_adapter_start_valid_w || q8_adapter_start_w ||
           gemv_adapter_start_w || f32_move_adapter_start_w ||
           norm_adapter_start_w || sum_adapter_start_w ||
           ssm_adapter_start_w)) ||
         (norm_adapter_start_w &&
          (macro_adapter_start_valid_w || q8_adapter_start_w ||
           gemv_adapter_start_w || f32_move_adapter_start_w ||
           sum_adapter_start_w || ssm_adapter_start_w)) ||
         (sum_adapter_start_w &&
          (macro_adapter_start_valid_w || q8_adapter_start_w ||
           gemv_adapter_start_w || f32_move_adapter_start_w ||
           ssm_adapter_start_w)) ||
         (ssm_adapter_start_w &&
          (macro_adapter_start_valid_w || q8_adapter_start_w ||
           gemv_adapter_start_w || f32_move_adapter_start_w)) ||
         (argmax_adapter_start_w &&
          (unary_glu_adapter_start_w || norm_adapter_start_w ||
           sum_adapter_start_w || ssm_adapter_start_w))))
      $error("NPU top attempted to start multiple exact-profile adapters");
    if (!rst && macro_select_f32_get_w && macro_select_f32_repeat_w)
      $error("NPU top selected two F32 mover kernel identities");
    if (!rst && macro_select_norm_w && macro_select_sum_w)
      $error("NPU top selected two physical REDUCE_F32 adapters");
    if (!rst && (state_q == ST_MACRO_RUN) &&
        !selected_macro_busy_w && !selected_macro_done_w &&
        !selected_macro_error_w)
      $error("NPU selected macro adapter lost its resident transaction");
    if (!rst && macro_completion_active_w &&
        (completion_npu_required_o != macro_command_flags_q[0]))
      $error("NPU macro completion lost REQUIRED identity");
    if (!rst && macro_completion_active_w && completion_error_o &&
        (completion_macro_status_o == 32'd0))
      $error("NPU macro error completion carried SUCCESS status");
    if (!rst && macro_completion_active_w && !completion_error_o &&
        ((completion_macro_status_o != 32'd0) ||
         (completion_macro_error_class_o != 32'd0)))
      $error("NPU macro success completion carried failure metadata");
  end
`endif

endmodule
