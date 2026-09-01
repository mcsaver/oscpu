`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Coprocessor-level proof that admitted Q8 GEMV and VECTOR_F32 commands are
// owned exclusively by the clocked functional-command child.  Every legacy
// memory/portal response is held at valid+error with poison data throughout
// the test; the fast owner must keep all corresponding ready/request signals,
// outstanding bits and counters at zero.
module tb_coprocessor_functional_command;

  /* verilator lint_off BLKSEQ */
  /* verilator lint_off WIDTHTRUNC */
  /* verilator lint_off WIDTHEXPAND */

  localparam integer ROW_LANES = 4;
  localparam integer F32_LANES = 8;
  localparam integer MOVER_LANES = 16;
  localparam integer MAX_WAIT_CYCLES = 2000;

  localparam [31:0] KERNEL_GEMV = 32'h514e0002;
  localparam [31:0] KERNEL_VECTOR_F32 = 32'h514e0010;
  localparam [31:0] FLAGS_REQUIRED = 32'h00000011;
  localparam [31:0] CONTEXT_F32 = 32'h43414e01;
  localparam [31:0] ABI_ERROR_LAYOUT = 32'd4;
  localparam [31:0] ABI_ERROR_IOVA = 32'd5;
  localparam [31:0] ABI_ERROR_PROTOCOL = 32'd11;
  localparam [31:0] PRIVATE_ERROR_CALLBACK = 32'h0000_f003;
  localparam [31:0] PRIVATE_CLASS_DPI_CONTRACT = 32'hffff_ff00;
  localparam [63:0] GEMV_SEQUENCE = 64'h4455_6677_8800_1001;
  localparam [63:0] F32_SEQUENCE = 64'h4455_6677_8800_2001;
  localparam [63:0] REJECT_SEQUENCE = 64'h4455_6677_8800_3001;
  localparam [63:0] F32_ZERO_LEDGER_SEQUENCE =
      64'h4455_6677_8800_4001;
  localparam [63:0] F32_CALLBACK_SEQUENCE =
      64'h4455_6677_8800_5001;

  localparam [63:0] GEMV_ACT_WIN = 64'h0000_0000_0000_1000;
  localparam [63:0] GEMV_ACT_BASE = 64'h0000_0000_0000_1104;
  localparam [63:0] GEMV_WT_WIN = 64'h0000_0000_0000_1800;
  localparam [63:0] GEMV_WT_BASE = 64'h0000_0000_0000_1802;
  localparam [63:0] GEMV_DST_WIN = 64'h0000_0000_0000_2000;
  localparam [63:0] GEMV_DST_BASE = 64'h0000_0000_0000_2104;
  localparam [63:0] F32_SRC0 = 64'h0000_0000_0000_1000;
  localparam [63:0] F32_SRC1 = 64'h0000_0000_0000_4000;
  localparam [63:0] F32_DST = 64'h0000_0000_0000_8000;

  reg clk;
  reg rst;
  reg macro_cmd_valid;
  wire macro_cmd_ready;
  reg macro_abi_valid;
  reg [31:0] macro_kernel_id;
  reg [31:0] macro_command_flags;
  reg [31:0] macro_context_id;
  reg [31:0] macro_capability_epoch;
  reg [63:0] macro_sequence_id;
  reg [63:0] macro_producer_id;
  reg [63:0] macro_user_tag;
  reg [31:0] macro_node_count;
  reg [63:0] macro_node_hash_lo;
  reg [63:0] macro_node_hash_hi;
  reg [63:0] macro_deadline_cycles;
  reg [31:0] macro_vector_op;
  reg [31:0] macro_vector_flags;
  reg [63:0] macro_src0_iova;
  reg [63:0] macro_src1_iova;
  reg [63:0] macro_src2_iova;
  reg [63:0] macro_dst_iova;
  reg [63:0] macro_scratch_iova;
  reg [63:0] macro_element_count;
  reg [31:0] macro_outer_count;
  reg [31:0] macro_dtype;
  reg [63:0] macro_src0_stride;
  reg [63:0] macro_src1_stride;
  reg [63:0] macro_src2_stride;
  reg [63:0] macro_dst_stride;
  reg [31:0] macro_scalar0;
  reg [31:0] macro_scalar1;
  reg [31:0] macro_scratch_bytes;
  reg [31:0] macro_rope_position;
  reg [63:0] macro_src0_window_base;
  reg [63:0] macro_src0_window_size;
  reg [1:0] macro_src0_window_perm;
  reg [63:0] macro_src1_window_base;
  reg [63:0] macro_src1_window_size;
  reg [1:0] macro_src1_window_perm;
  reg [63:0] macro_dst_window_base;
  reg [63:0] macro_dst_window_size;
  reg [1:0] macro_dst_window_perm;
  reg macro_windows_generation_valid;

  wire completion_valid;
  reg completion_ready;
  wire [7:0] completion_producer_id;
  wire completion_npu_required;
  wire [7:0] completion_opclass;
  wire completion_error;
  wire [`NPU_ERROR_W-1:0] completion_error_code;
  wire completion_is_macro;
  wire [31:0] completion_macro_status;
  wire [31:0] completion_macro_error_class;
  wire [31:0] completion_macro_kernel_id;
  wire [31:0] completion_macro_command_flags;
  wire [31:0] completion_macro_vector_flags;
  wire [31:0] completion_macro_context_id;
  wire [63:0] completion_macro_sequence_id;
  wire [63:0] completion_macro_producer_id;
  wire [63:0] completion_macro_user_tag;
  wire [31:0] completion_macro_covered_node_count;
  wire [63:0] completion_macro_node_hash_lo;
  wire [63:0] completion_macro_node_hash_hi;
  wire [63:0] completion_macro_npu_cycles;
  wire [63:0] completion_macro_gmem_read_bytes;
  wire [63:0] completion_macro_gmem_write_bytes;
  wire [63:0] completion_macro_q8_mac_count;
  wire [63:0] completion_macro_vector_element_count;
  wire [63:0] completion_macro_state_update_count;

  wire gmem_req_valid;
  wire gmem_rsp_ready;

  wire q8_req_valid;
  wire q8_rsp_ready;
  wire [63:0] q8_request_count;
  wire [63:0] q8_response_count;
  wire [63:0] q8_block_count;
  wire [63:0] q8_byte_count;
  wire q8_outstanding;

  wire f32_req_valid;
  wire f32_rsp_ready;
  wire [63:0] f32_request_groups;
  wire [63:0] f32_response_groups;
  wire [63:0] f32_read_groups;
  wire [63:0] f32_write_groups;
  wire [63:0] f32_input_words;
  wire [63:0] f32_output_words;
  wire [63:0] f32_read_bytes;
  wire [63:0] f32_write_bytes;
  wire f32_outstanding;

  wire mover_req_valid;
  wire mover_rsp_ready;
  wire [63:0] mover_request_groups;
  wire [63:0] mover_response_groups;
  wire [63:0] mover_read_groups;
  wire [63:0] mover_write_groups;
  wire [63:0] mover_read_words;
  wire [63:0] mover_write_words;
  wire [63:0] mover_read_bytes;
  wire [63:0] mover_write_bytes;
  wire mover_outstanding;

  reg error_clear;
  wire busy;
  wire sticky_error;
  wire [`NPU_ERROR_W-1:0] sticky_error_code;
  wire [63:0] command_count;
  wire [63:0] completion_count;
  wire [63:0] error_count;
  wire [63:0] npu_required_issued;
  wire [63:0] npu_required_completed;
  wire [63:0] macro_command_count;
  wire [63:0] macro_f32_start_count;
  wire [63:0] macro_completion_count;

  wire unused_cmd_ready;
  wire unused_desc_ready;
  wire unused_desc_error;
  wire [`NPU_ERROR_W-1:0] unused_desc_error_code;
  wire [63:0] unused_lmem_data;
  wire unused_lmem_rd_oob;
  wire unused_lmem_wr_oob;
  wire unused_lmem_ready;
  wire [63:0] unused_sync_tag;
  wire unused_sync_valid;
  wire [63:0] unused_tiu_cycles;
  wire [63:0] unused_dma_cycles;
  wire [63:0] unused_dma_bytes;

  integer global_cycles;
  integer checks;

  reg [31:0] expected_kernel_q;
  reg [31:0] expected_flags_q;
  reg [31:0] expected_vector_op_q;
  reg [31:0] expected_vector_flags_q;
  reg [31:0] expected_context_q;
  reg [31:0] expected_capability_epoch_q;
  reg [63:0] expected_sequence_q;
  reg [63:0] expected_producer_q;
  reg [63:0] expected_user_tag_q;
  reg [31:0] expected_node_count_q;
  reg [63:0] expected_hash_lo_q;
  reg [63:0] expected_hash_hi_q;

  import "DPI-C" function void npu_functional_coprocessor_stub_reset();
  import "DPI-C" function longint unsigned
      npu_functional_coprocessor_stub_call_count();

  TensorNpuCoprocessor #(
    .LMEM_BYTES(512),
    .PID_W(8),
    .OPCLASS_W(8),
    .Q8_GEMV_PORTAL_ENABLE(1),
    .Q8_GEMV_ROW_LANES(ROW_LANES),
    .Q8_GEMV_MAC_LANES(32),
    .F32_ALU_PORTAL_ENABLE(1),
    .F32_ALU_PORTAL_LANES(F32_LANES),
    .F32_MOVER_PORTAL_ENABLE(1),
    .F32_MOVER_PORTAL_LANES(MOVER_LANES),
    .COMMAND_FUNCTIONAL_ENABLE(1),
    .MACRO_CAPABILITY_EPOCH(32'h00000001)
  ) dut (
    .clk(clk),
    .rst(rst),
    .cmd_valid_i(1'b0),
    .cmd_ready_o(unused_cmd_ready),
    .cmd_is_64_i(1'b0),
    .cmd_bits_i(64'd0),
    .cmd_rs_value_i(64'd0),
    .cmd_producer_id_i(8'd0),
    .cmd_npu_required_i(1'b0),
    .cmd_opclass_i(8'd0),
    .macro_cmd_valid_i(macro_cmd_valid),
    .macro_cmd_ready_o(macro_cmd_ready),
    .macro_abi_valid_i(macro_abi_valid),
    .macro_kernel_id_i(macro_kernel_id),
    .macro_command_flags_i(macro_command_flags),
    .macro_context_id_i(macro_context_id),
    .macro_capability_epoch_i(macro_capability_epoch),
    .macro_sequence_id_i(macro_sequence_id),
    .macro_producer_id_i(macro_producer_id),
    .macro_user_tag_i(macro_user_tag),
    .macro_node_count_i(macro_node_count),
    .macro_node_hash_lo_i(macro_node_hash_lo),
    .macro_node_hash_hi_i(macro_node_hash_hi),
    .macro_deadline_cycles_i(macro_deadline_cycles),
    .macro_vector_op_i(macro_vector_op),
    .macro_vector_flags_i(macro_vector_flags),
    .macro_src0_iova_i(macro_src0_iova),
    .macro_src1_iova_i(macro_src1_iova),
    .macro_src2_iova_i(macro_src2_iova),
    .macro_dst_iova_i(macro_dst_iova),
    .macro_scratch_iova_i(macro_scratch_iova),
    .macro_element_count_i(macro_element_count),
    .macro_outer_count_i(macro_outer_count),
    .macro_dtype_i(macro_dtype),
    .macro_src0_stride_i(macro_src0_stride),
    .macro_src1_stride_i(macro_src1_stride),
    .macro_src2_stride_i(macro_src2_stride),
    .macro_dst_stride_i(macro_dst_stride),
    .macro_scalar0_i(macro_scalar0),
    .macro_scalar1_i(macro_scalar1),
    .macro_scratch_bytes_i(macro_scratch_bytes),
    .macro_rope_position_i(macro_rope_position),
    .macro_src0_window_base_i(macro_src0_window_base),
    .macro_src0_window_size_i(macro_src0_window_size),
    .macro_src0_window_perm_i(macro_src0_window_perm),
    .macro_src1_window_base_i(macro_src1_window_base),
    .macro_src1_window_size_i(macro_src1_window_size),
    .macro_src1_window_perm_i(macro_src1_window_perm),
    .macro_dst_window_base_i(macro_dst_window_base),
    .macro_dst_window_size_i(macro_dst_window_size),
    .macro_dst_window_perm_i(macro_dst_window_perm),
    .macro_windows_generation_valid_i(macro_windows_generation_valid),
    .completion_valid_o(completion_valid),
    .completion_ready_i(completion_ready),
    .completion_producer_id_o(completion_producer_id),
    .completion_npu_required_o(completion_npu_required),
    .completion_opclass_o(completion_opclass),
    .completion_error_o(completion_error),
    .completion_error_code_o(completion_error_code),
    .completion_is_macro_o(completion_is_macro),
    .completion_macro_status_o(completion_macro_status),
    .completion_macro_error_class_o(completion_macro_error_class),
    .completion_macro_kernel_id_o(completion_macro_kernel_id),
    .completion_macro_command_flags_o(completion_macro_command_flags),
    .completion_macro_vector_flags_o(completion_macro_vector_flags),
    .completion_macro_context_id_o(completion_macro_context_id),
    .completion_macro_sequence_id_o(completion_macro_sequence_id),
    .completion_macro_producer_id_o(completion_macro_producer_id),
    .completion_macro_user_tag_o(completion_macro_user_tag),
    .completion_macro_covered_node_count_o(
        completion_macro_covered_node_count),
    .completion_macro_node_hash_lo_o(completion_macro_node_hash_lo),
    .completion_macro_node_hash_hi_o(completion_macro_node_hash_hi),
    .completion_macro_npu_cycles_o(completion_macro_npu_cycles),
    .completion_macro_gmem_read_bytes_o(completion_macro_gmem_read_bytes),
    .completion_macro_gmem_write_bytes_o(completion_macro_gmem_write_bytes),
    .completion_macro_q8_mac_count_o(completion_macro_q8_mac_count),
    .completion_macro_vector_element_count_o(
        completion_macro_vector_element_count),
    .completion_macro_state_update_count_o(
        completion_macro_state_update_count),
    .desc_write_valid_i(1'b0),
    .desc_write_ready_o(unused_desc_ready),
    .desc_write_id_i(6'd0),
    .desc_write_word_i(3'd0),
    .desc_write_data_i(64'd0),
    .desc_write_error_o(unused_desc_error),
    .desc_write_error_code_o(unused_desc_error_code),
    .host_lmem_rd_valid_i(1'b0),
    .host_lmem_rd_addr_i(32'd0),
    .host_lmem_rd_bytes_i(4'd0),
    .host_lmem_rd_data_o(unused_lmem_data),
    .host_lmem_rd_oob_o(unused_lmem_rd_oob),
    .host_lmem_wr_valid_i(1'b0),
    .host_lmem_wr_addr_i(32'd0),
    .host_lmem_wr_data_i(64'd0),
    .host_lmem_wr_strb_i(8'd0),
    .host_lmem_wr_oob_o(unused_lmem_wr_oob),
    .host_lmem_ready_o(unused_lmem_ready),
    .gmem_req_valid_o(gmem_req_valid),
    .gmem_req_ready_i(1'b1),
    .gmem_req_write_o(),
    .gmem_req_addr_o(),
    .gmem_req_wdata_o(),
    .gmem_req_wstrb_o(),
    .gmem_rsp_valid_i(1'b1),
    .gmem_rsp_ready_o(gmem_rsp_ready),
    .gmem_rsp_rdata_i(64'hdead_beef_a5a5_5a5a),
    .gmem_rsp_error_i(1'b1),
    .q8_portal_req_valid_o(q8_req_valid),
    .q8_portal_req_ready_i(1'b1),
    .q8_portal_req_mask_o(),
    .q8_portal_req_addr_o(),
    .q8_portal_rsp_valid_i(1'b1),
    .q8_portal_rsp_ready_o(q8_rsp_ready),
    .q8_portal_rsp_mask_i({ROW_LANES{1'b1}}),
    .q8_portal_rsp_blocks_i({(ROW_LANES*272){1'b1}}),
    .q8_portal_rsp_error_i(1'b1),
    .q8_portal_request_count_o(q8_request_count),
    .q8_portal_response_count_o(q8_response_count),
    .q8_portal_block_count_o(q8_block_count),
    .q8_portal_byte_count_o(q8_byte_count),
    .q8_portal_outstanding_o(q8_outstanding),
    .f32_alu_portal_req_valid_o(f32_req_valid),
    .f32_alu_portal_req_ready_i(1'b1),
    .f32_alu_portal_req_write_o(),
    .f32_alu_portal_req_mask_o(),
    .f32_alu_portal_req_src0_addr_o(),
    .f32_alu_portal_req_src1_addr_o(),
    .f32_alu_portal_req_dst_addr_o(),
    .f32_alu_portal_req_wdata_o(),
    .f32_alu_portal_rsp_valid_i(1'b1),
    .f32_alu_portal_rsp_ready_o(f32_rsp_ready),
    .f32_alu_portal_rsp_mask_i({F32_LANES{1'b1}}),
    .f32_alu_portal_rsp_src0_data_i({(F32_LANES*32){1'b1}}),
    .f32_alu_portal_rsp_src1_data_i({(F32_LANES*32){1'b1}}),
    .f32_alu_portal_rsp_error_i(1'b1),
    .f32_alu_portal_request_groups_o(f32_request_groups),
    .f32_alu_portal_response_groups_o(f32_response_groups),
    .f32_alu_portal_read_groups_o(f32_read_groups),
    .f32_alu_portal_write_groups_o(f32_write_groups),
    .f32_alu_portal_input_words_o(f32_input_words),
    .f32_alu_portal_output_words_o(f32_output_words),
    .f32_alu_portal_read_bytes_o(f32_read_bytes),
    .f32_alu_portal_write_bytes_o(f32_write_bytes),
    .f32_alu_portal_outstanding_o(f32_outstanding),
    .f32_mover_portal_req_valid_o(mover_req_valid),
    .f32_mover_portal_req_ready_i(1'b1),
    .f32_mover_portal_req_write_o(),
    .f32_mover_portal_req_mask_o(),
    .f32_mover_portal_req_addr_o(),
    .f32_mover_portal_req_wdata_o(),
    .f32_mover_portal_rsp_valid_i(1'b1),
    .f32_mover_portal_rsp_ready_o(mover_rsp_ready),
    .f32_mover_portal_rsp_mask_i({MOVER_LANES{1'b1}}),
    .f32_mover_portal_rsp_rdata_i({(MOVER_LANES*32){1'b1}}),
    .f32_mover_portal_rsp_error_i(1'b1),
    .f32_mover_portal_request_groups_o(mover_request_groups),
    .f32_mover_portal_response_groups_o(mover_response_groups),
    .f32_mover_portal_read_groups_o(mover_read_groups),
    .f32_mover_portal_write_groups_o(mover_write_groups),
    .f32_mover_portal_read_words_o(mover_read_words),
    .f32_mover_portal_write_words_o(mover_write_words),
    .f32_mover_portal_read_bytes_o(mover_read_bytes),
    .f32_mover_portal_write_bytes_o(mover_write_bytes),
    .f32_mover_portal_outstanding_o(mover_outstanding),
    .sync_tag_ack_i(1'b0),
    .sync_tag_o(unused_sync_tag),
    .sync_tag_valid_o(unused_sync_valid),
    .error_clear_i(error_clear),
    .busy_o(busy),
    .error_o(sticky_error),
    .error_code_o(sticky_error_code),
    .command_count_o(command_count),
    .completion_count_o(completion_count),
    .error_count_o(error_count),
    .npu_required_issued_o(npu_required_issued),
    .npu_required_completed_o(npu_required_completed),
    .tiu_cycles_o(unused_tiu_cycles),
    .dma_cycles_o(unused_dma_cycles),
    .dma_bytes_o(unused_dma_bytes),
    .macro_command_count_o(macro_command_count),
    .macro_f32_start_count_o(macro_f32_start_count),
    .macro_completion_count_o(macro_completion_count)
  );

  initial clk = 1'b0;
  always #5 clk <= ~clk;

  task automatic fail(input string reason);
    begin
      $display("[NPU-COPROCESSOR-FUNCTIONAL-COMMAND][FAIL] %s cycle=%0d state=%0d calls=%0d commands=%0d/%0d required=%0d/%0d",
               reason, global_cycles, dut.state_q,
               npu_functional_coprocessor_stub_call_count(),
               command_count, completion_count,
               npu_required_issued, npu_required_completed);
      $fatal(1);
    end
  endtask

  task automatic step_cycle;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  always @(posedge clk) begin
    global_cycles <= global_cycles + 1;
    if (global_cycles >= 1000)
      fail("global timeout");
    if (!rst) begin
      if (gmem_req_valid || gmem_rsp_ready
          || q8_req_valid || q8_rsp_ready || q8_outstanding
          || (q8_request_count != 64'd0)
          || (q8_response_count != 64'd0)
          || (q8_block_count != 64'd0)
          || (q8_byte_count != 64'd0)
          || f32_req_valid || f32_rsp_ready || f32_outstanding
          || (f32_request_groups != 64'd0)
          || (f32_response_groups != 64'd0)
          || (f32_read_groups != 64'd0)
          || (f32_write_groups != 64'd0)
          || (f32_input_words != 64'd0)
          || (f32_output_words != 64'd0)
          || (f32_read_bytes != 64'd0)
          || (f32_write_bytes != 64'd0)
          || mover_req_valid || mover_rsp_ready || mover_outstanding
          || (mover_request_groups != 64'd0)
          || (mover_response_groups != 64'd0)
          || (mover_read_groups != 64'd0)
          || (mover_write_groups != 64'd0)
          || (mover_read_words != 64'd0)
          || (mover_write_words != 64'd0)
          || (mover_read_bytes != 64'd0)
          || (mover_write_bytes != 64'd0)) begin
        fail("legacy raw/portal path observed activity under fast owner");
      end
    end
  end

  task automatic configure_gemv(input [63:0] sequence_value);
    begin
      macro_abi_valid = 1'b1;
      macro_kernel_id = KERNEL_GEMV;
      macro_command_flags = FLAGS_REQUIRED;
      macro_context_id = 32'hcafe_1001;
      macro_capability_epoch = 32'h00000001;
      macro_sequence_id = sequence_value;
      macro_producer_id = 64'h1122_3344_0000_0000
                        | {32'd0, sequence_value[31:0]};
      macro_user_tag = 64'h5566_7788_0000_0000
                     | {32'd0, sequence_value[31:0]};
      macro_node_count = 32'd1;
      macro_node_hash_lo = 64'h8899_aabb_0000_0000
                         | {32'd0, sequence_value[31:0]};
      macro_node_hash_hi = 64'hccdd_eeff_0000_0000
                         | {32'd0, sequence_value[31:0]};
      macro_deadline_cycles = 64'd0;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = GEMV_ACT_BASE;
      macro_src1_iova = GEMV_WT_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = GEMV_DST_BASE;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd64;
      macro_outer_count = 32'd5;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd0;
      macro_src1_stride = 64'd72;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd4;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = GEMV_ACT_WIN;
      macro_src0_window_size = 64'h400;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = GEMV_WT_WIN;
      macro_src1_window_size = 64'h200;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = GEMV_DST_WIN;
      macro_dst_window_size = 64'h200;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
    end
  endtask

  task automatic configure_f32_p00(input [63:0] sequence_value);
    begin
      macro_abi_valid = 1'b1;
      macro_kernel_id = KERNEL_VECTOR_F32;
      macro_command_flags = FLAGS_REQUIRED;
      macro_context_id = CONTEXT_F32;
      macro_capability_epoch = 32'h00000001;
      macro_sequence_id = sequence_value;
      macro_producer_id = 64'h8877_6600_0000_0000
                        | {32'd0, sequence_value[31:0]};
      macro_user_tag = 64'h1234_5600_0000_0000
                     | {32'd0, sequence_value[31:0]};
      macro_node_count = 32'd1;
      macro_node_hash_lo = 64'h1122_3300_0000_0000
                         | {32'd0, sequence_value[31:0]};
      macro_node_hash_hi = 64'h4455_6600_0000_0000
                         | {32'd0, sequence_value[31:0]};
      macro_deadline_cycles = 64'd0;
      macro_vector_op = 32'd1;
      macro_vector_flags = 32'd0;
      macro_src0_iova = F32_SRC0;
      macro_src1_iova = F32_SRC1;
      macro_src2_iova = 64'd0;
      macro_dst_iova = F32_DST;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd16;
      macro_outer_count = 32'd1;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd64;
      macro_src1_stride = 64'd64;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd64;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = F32_SRC0;
      macro_src0_window_size = 64'd64;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = F32_SRC1;
      macro_src1_window_size = 64'd64;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = F32_DST;
      macro_dst_window_size = 64'd64;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
    end
  endtask

  task automatic poison_live_descriptor;
    begin
      macro_abi_valid = 1'b0;
      macro_kernel_id = 32'hffff_ffff;
      macro_command_flags = 32'hffff_ffff;
      macro_context_id = 32'hffff_ffff;
      macro_capability_epoch = 32'hffff_ffff;
      macro_sequence_id = 64'hffff_ffff_ffff_ffff;
      macro_producer_id = 64'hffff_ffff_ffff_ffff;
      macro_user_tag = 64'hffff_ffff_ffff_ffff;
      macro_node_count = 32'hffff_ffff;
      macro_node_hash_lo = 64'hffff_ffff_ffff_ffff;
      macro_node_hash_hi = 64'hffff_ffff_ffff_ffff;
      macro_deadline_cycles = 64'hffff_ffff_ffff_ffff;
      macro_vector_op = 32'hffff_ffff;
      macro_vector_flags = 32'hffff_ffff;
      macro_src0_iova = 64'hffff_ffff_ffff_ffff;
      macro_src1_iova = 64'hffff_ffff_ffff_ffff;
      macro_src2_iova = 64'hffff_ffff_ffff_ffff;
      macro_dst_iova = 64'hffff_ffff_ffff_ffff;
      macro_scratch_iova = 64'hffff_ffff_ffff_ffff;
      macro_element_count = 64'hffff_ffff_ffff_ffff;
      macro_outer_count = 32'hffff_ffff;
      macro_dtype = 32'hffff_ffff;
      macro_src0_stride = 64'hffff_ffff_ffff_ffff;
      macro_src1_stride = 64'hffff_ffff_ffff_ffff;
      macro_src2_stride = 64'hffff_ffff_ffff_ffff;
      macro_dst_stride = 64'hffff_ffff_ffff_ffff;
      macro_scalar0 = 32'hffff_ffff;
      macro_scalar1 = 32'hffff_ffff;
      macro_scratch_bytes = 32'hffff_ffff;
      macro_rope_position = 32'hffff_ffff;
      macro_src0_window_base = 64'hffff_ffff_ffff_ffff;
      macro_src0_window_size = 64'hffff_ffff_ffff_ffff;
      macro_src0_window_perm = 2'b11;
      macro_src1_window_base = 64'hffff_ffff_ffff_ffff;
      macro_src1_window_size = 64'hffff_ffff_ffff_ffff;
      macro_src1_window_perm = 2'b11;
      macro_dst_window_base = 64'hffff_ffff_ffff_ffff;
      macro_dst_window_size = 64'hffff_ffff_ffff_ffff;
      macro_dst_window_perm = 2'b11;
      macro_windows_generation_valid = 1'b0;
    end
  endtask

  task automatic capture_expected_identity;
    begin
      expected_kernel_q = macro_kernel_id;
      expected_flags_q = macro_command_flags;
      expected_vector_op_q = macro_vector_op;
      expected_vector_flags_q = macro_vector_flags;
      expected_context_q = macro_context_id;
      expected_capability_epoch_q = macro_capability_epoch;
      expected_sequence_q = macro_sequence_id;
      expected_producer_q = macro_producer_id;
      expected_user_tag_q = macro_user_tag;
      expected_node_count_q = macro_node_count;
      expected_hash_lo_q = macro_node_hash_lo;
      expected_hash_hi_q = macro_node_hash_hi;
    end
  endtask

  task automatic check_completion_fields(
      input bit expected_error,
      input [`NPU_ERROR_W-1:0] expected_error_code,
      input [31:0] expected_error_class,
      input [63:0] expected_read_bytes,
      input [63:0] expected_write_bytes,
      input [63:0] expected_q8_mac_count,
      input [63:0] expected_vector_elements);
    begin
      if (!completion_valid || !completion_is_macro
          || (completion_producer_id != 8'd0)
          || !completion_npu_required
          || (completion_opclass != 8'd0)
          || (completion_error != expected_error)
          || (completion_error_code != expected_error_code)
          || (completion_macro_status
              != {24'd0, expected_error_code})
          || (completion_macro_error_class != expected_error_class)
          || (completion_macro_kernel_id != expected_kernel_q)
          || (completion_macro_command_flags != expected_flags_q)
          || (completion_macro_vector_flags != expected_vector_flags_q)
          || (completion_macro_context_id != expected_context_q)
          || (completion_macro_sequence_id != expected_sequence_q)
          || (completion_macro_producer_id != expected_producer_q)
          || (completion_macro_user_tag != expected_user_tag_q)
          || (completion_macro_covered_node_count
              != expected_node_count_q)
          || (completion_macro_node_hash_lo != expected_hash_lo_q)
          || (completion_macro_node_hash_hi != expected_hash_hi_q)
          || (completion_macro_npu_cycles == 64'd0)
          || (completion_macro_gmem_read_bytes != expected_read_bytes)
          || (completion_macro_gmem_write_bytes != expected_write_bytes)
          || (completion_macro_q8_mac_count != expected_q8_mac_count)
          || (completion_macro_vector_element_count
              != expected_vector_elements)
          || (completion_macro_state_update_count != 64'd0)) begin
        fail("public completion identity/semantic ledger mismatch");
      end
    end
  endtask

  task automatic check_functional_terminal_fields(
      input bit expected_child_success,
      input bit expected_child_commit,
      input [31:0] expected_private_error_code,
      input [31:0] expected_private_error_class,
      input [63:0] expected_read_words,
      input [63:0] expected_write_words,
      input [63:0] expected_read_bytes,
      input [63:0] expected_write_bytes,
      input [63:0] expected_q8_blocks,
      input [63:0] expected_q8_mac_count,
      input [63:0] expected_vector_elements,
      input [31:0] expected_callback_errors);
    begin
      if (!dut.functional_command_terminal_valid_w
          || (dut.functional_command_success_w
              != expected_child_success)
          || (dut.functional_command_error_w
              != !expected_child_success)
          || (dut.functional_command_dst_commit_w
              != expected_child_commit)
          || (dut.functional_command_error_code_w
              != expected_private_error_code)
          || (dut.functional_command_error_class_w
              != expected_private_error_class)
          || (dut.functional_completion_kernel_id_w != expected_kernel_q)
          || (dut.functional_completion_command_flags_w
              != expected_flags_q)
          || (dut.functional_completion_vector_op_w
              != expected_vector_op_q)
          || (dut.functional_completion_vector_flags_w
              != expected_vector_flags_q)
          || (dut.functional_completion_context_id_w != expected_context_q)
          || (dut.functional_completion_capability_epoch_w
              != expected_capability_epoch_q)
          || (dut.functional_completion_node_count_w
              != expected_node_count_q)
          || (dut.functional_completion_sequence_id_w
              != expected_sequence_q)
          || (dut.functional_completion_producer_id_w
              != expected_producer_q)
          || (dut.functional_completion_user_tag_w != expected_user_tag_q)
          || (dut.functional_completion_node_hash_lo_w
              != expected_hash_lo_q)
          || (dut.functional_completion_node_hash_hi_w
              != expected_hash_hi_q)
          || (dut.functional_command_read_words_w != expected_read_words)
          || (dut.functional_command_write_words_w != expected_write_words)
          || (dut.functional_command_read_bytes_w != expected_read_bytes)
          || (dut.functional_command_write_bytes_w != expected_write_bytes)
          || (dut.functional_command_q8_blocks_w != expected_q8_blocks)
          || (dut.functional_command_q8_mac_count_w
              != expected_q8_mac_count)
          || (dut.functional_command_vector_elements_w
              != expected_vector_elements)
          || (dut.functional_command_callback_errors_w
              != expected_callback_errors)) begin
        fail("private functional terminal/commit contract mismatch");
      end
    end
  endtask

  task automatic issue_and_check(
      input bit expected_error,
      input [`NPU_ERROR_W-1:0] expected_error_code,
      input [31:0] expected_error_class,
      input [63:0] expected_read_words,
      input [63:0] expected_write_words,
      input [63:0] expected_read_bytes,
      input [63:0] expected_write_bytes,
      input [63:0] expected_q8_blocks,
      input [63:0] expected_q8_mac_count,
      input [63:0] expected_vector_elements,
      input [63:0] expected_call_delta,
      input [63:0] expected_commands,
      input [63:0] expected_successes,
      input [63:0] expected_errors,
      input [63:0] expected_functional_terminals,
      input bit expected_child_terminal,
      input bit expected_child_success,
      input bit expected_child_commit,
      input [31:0] expected_private_error_code,
      input [31:0] expected_private_error_class,
      input [31:0] expected_callback_errors);
    integer waited;
    integer held_cycle;
    integer child_terminal_count;
    longint unsigned calls_before;
    begin
      capture_expected_identity();
      calls_before = npu_functional_coprocessor_stub_call_count();
      waited = 0;
      while (!macro_cmd_ready) begin
        step_cycle();
        waited = waited + 1;
        if (waited > 20)
          fail("macro admission timeout");
      end
      @(negedge clk);
      macro_cmd_valid = 1'b1;
      step_cycle();
      if (!busy || macro_cmd_ready)
        fail("accepted macro descriptor did not become resident");
      macro_cmd_valid = 1'b0;
      poison_live_descriptor();

      waited = 0;
      child_terminal_count = 0;
      while (!completion_valid) begin
        step_cycle();
        waited = waited + 1;
        if (dut.functional_command_terminal_valid_w) begin
          child_terminal_count = child_terminal_count + 1;
          check_functional_terminal_fields(
              expected_child_success,
              expected_child_commit,
              expected_private_error_code,
              expected_private_error_class,
              expected_read_words,
              expected_write_words,
              expected_read_bytes,
              expected_write_bytes,
              expected_q8_blocks,
              expected_q8_mac_count,
              expected_vector_elements,
              expected_callback_errors);
        end
        if (waited > MAX_WAIT_CYCLES)
          fail("public completion timeout");
      end
      if (child_terminal_count != (expected_child_terminal ? 1 : 0))
        fail("functional child terminal beat count mismatch");
      if (npu_functional_coprocessor_stub_call_count()
          != (calls_before + expected_call_delta)) begin
        fail("DPI call count delta mismatch");
      end
      check_completion_fields(
          expected_error,
          expected_error_code,
          expected_error_class,
          expected_read_bytes,
          expected_write_bytes,
          expected_q8_mac_count,
          expected_vector_elements);

      for (held_cycle = 0; held_cycle < 2;
           held_cycle = held_cycle + 1) begin
        step_cycle();
        check_completion_fields(
            expected_error,
            expected_error_code,
            expected_error_class,
            expected_read_bytes,
            expected_write_bytes,
            expected_q8_mac_count,
            expected_vector_elements);
      end

      @(negedge clk);
      completion_ready = 1'b1;
      step_cycle();
      completion_ready = 1'b0;
      if (completion_valid)
        fail("completion did not retire");

      if ((command_count != expected_commands)
          || (completion_count != expected_successes)
          || (error_count != expected_errors)
          || (npu_required_issued != expected_commands)
          || (npu_required_completed != expected_successes)
          || (macro_command_count != expected_commands)
          || (macro_completion_count != expected_successes)
          || (macro_f32_start_count != 64'd0)
          || (dut.functional_command_dispatch_count_w
              != expected_functional_terminals)
          || (dut.functional_command_completion_count_w
              != expected_functional_terminals)) begin
        fail("aggregate public/functional counters did not close");
      end

      if (expected_error) begin
        if (!sticky_error || (sticky_error_code != expected_error_code)
            || macro_cmd_ready)
          fail("error completion did not enter fail-closed hold");
        @(negedge clk);
        error_clear = 1'b1;
        step_cycle();
        error_clear = 1'b0;
        if (sticky_error || !macro_cmd_ready)
          fail("error_clear failed to reopen macro admission");
      end else if (sticky_error || busy || !macro_cmd_ready) begin
        fail("successful fast completion failed to recover IDLE");
      end
      checks = checks + 1;
    end
  endtask

  initial begin
    global_cycles = 0;
    checks = 0;
    rst = 1'b1;
    macro_cmd_valid = 1'b0;
    completion_ready = 1'b0;
    error_clear = 1'b0;
    poison_live_descriptor();
    npu_functional_coprocessor_stub_reset();

    repeat (5) step_cycle();
    @(negedge clk);
    rst = 1'b0;
    repeat (2) step_cycle();

    configure_gemv(GEMV_SEQUENCE);
    issue_and_check(
        1'b0,
        `NPU_ERR_NONE,
        32'd0,
        64'd64,
        64'd5,
        64'd596,
        64'd20,
        64'd10,
        64'd320,
        64'd5,
        64'd1,
        64'd1,
        64'd1,
        64'd0,
        64'd1,
        1'b1,
        1'b1,
        1'b1,
        32'd0,
        32'd0,
        32'd0);

    configure_f32_p00(F32_SEQUENCE);
    issue_and_check(
        1'b0,
        `NPU_ERR_NONE,
        32'd0,
        64'd32,
        64'd16,
        64'd128,
        64'd64,
        64'd0,
        64'd0,
        64'd16,
        64'd1,
        64'd2,
        64'd2,
        64'd0,
        64'd2,
        1'b1,
        1'b1,
        1'b1,
        32'd0,
        32'd0,
        32'd0);

    // Odd Q8 row stride is a resident static layout reject.  It must finish
    // without selecting either the DPI child or the legacy GEMV adapter.
    configure_gemv(REJECT_SEQUENCE);
    macro_src1_stride = 64'd71;
    issue_and_check(
        1'b1,
        `NPU_ERR_MACRO_LAYOUT,
        ABI_ERROR_LAYOUT,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd3,
        64'd2,
        64'd1,
        64'd2,
        1'b0,
        1'b0,
        1'b0,
        32'd0,
        32'd0,
        32'd0);

    // The child's generic closure accepts a self-consistent all-zero success
    // ledger.  The Coprocessor's independent VECTOR P00 contract must still
    // convert it into a public protocol failure and withhold architectural
    // success/completion accounting.
    configure_f32_p00(F32_ZERO_LEDGER_SEQUENCE);
    issue_and_check(
        1'b1,
        `NPU_ERR_MACRO_PROTOCOL,
        ABI_ERROR_PROTOCOL,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd1,
        64'd4,
        64'd2,
        64'd2,
        64'd3,
        1'b1,
        1'b1,
        1'b1,
        32'd0,
        32'd0,
        32'd0);

    // A callback failure overrides the otherwise framed runtime status with
    // private F003 and no child commit.  The Coprocessor must expose the
    // explicit public IOVA/class-5 mapping, not truncate the private code.
    configure_f32_p00(F32_CALLBACK_SEQUENCE);
    issue_and_check(
        1'b1,
        `NPU_ERR_MACRO_IOVA,
        ABI_ERROR_IOVA,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd0,
        64'd1,
        64'd5,
        64'd2,
        64'd3,
        64'd4,
        1'b1,
        1'b0,
        1'b0,
        PRIVATE_ERROR_CALLBACK,
        PRIVATE_CLASS_DPI_CONTRACT,
        32'd1);

    if (npu_functional_coprocessor_stub_call_count() != 64'd4)
      fail("final DPI exact-once total mismatch");

    $display("[NPU-COPROCESSOR-FUNCTIONAL-COMMAND][PASS] q8_gemv=M5/K64/B2/read596/write20/q8mac320/vector5 f32_p00=ADD16/read128/write64/vector16 preflight_layout_reject=calls0 vector_zero_ledger=MACRO_PROTOCOL/class11 callback_f003=MACRO_IOVA/class5/no_commit required=5/2 macro=5/2 errors=3 dpi=4/4 raw_gmem=0/0 q8_portal=0/0/0 f32_alu_portal=0/0/0 f32_mover_portal=0/0/0 poison_responses=ignored checks=%0d assertions=off waveform=off",
             checks);
    $finish;
  end

  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */
  /* verilator lint_on BLKSEQ */

endmodule

`default_nettype wire
