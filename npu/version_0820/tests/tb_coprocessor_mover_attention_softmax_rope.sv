`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

module tb_coprocessor_mover_attention_softmax_rope;
  localparam integer PID_W = 8;
  localparam integer OPCLASS_W = 8;
  localparam integer MEM_BYTES = 32'h0040_0000;
  localparam [63:0] SRC0_BASE = 64'h0000_0000_0001_0000;
  localparam [63:0] SRC1_BASE = 64'h0000_0000_0005_0000;
  localparam [63:0] DST_BASE  = 64'h0000_0000_0009_0000;
  localparam [63:0] BIG_SRC0_BASE = 64'h0000_0000_0010_0000;
  localparam [63:0] BIG_SRC1_BASE = 64'h0000_0000_0020_0000;
  localparam [63:0] BIG_DST_BASE  = 64'h0000_0000_0030_0000;
  localparam [31:0] FLAGS_REQUIRED_PROFILE = 32'h0000_0011;
  localparam [31:0] CANONICAL_CONTEXT_ID = 32'h4341_4e01;
  localparam [31:0] DTYPE_F32 = 32'd1;
  localparam [31:0] KERNEL_MOVER = 32'h514e_0007;
  localparam [31:0] KERNEL_SET_ROWS = 32'h514e_0008;
  localparam [31:0] KERNEL_ATTENTION = 32'h514e_0009;
  localparam [31:0] KERNEL_ROPE = 32'h514e_000a;
  localparam [31:0] KERNEL_REDUCE = 32'h514e_0011;

  reg clk, rst;
  reg cmd_valid, cmd_is_64, cmd_npu_required;
  wire cmd_ready;
  reg [63:0] cmd_bits, cmd_rs_value;
  reg [PID_W-1:0] cmd_producer_id;
  reg [OPCLASS_W-1:0] cmd_opclass;

  reg macro_cmd_valid;
  wire macro_cmd_ready;
  reg macro_abi_valid;
  reg [31:0] macro_kernel_id, macro_command_flags;
  reg [31:0] macro_context_id, macro_capability_epoch;
  reg [63:0] macro_sequence_id, macro_producer_id, macro_user_tag;
  reg [31:0] macro_node_count;
  reg [63:0] macro_node_hash_lo, macro_node_hash_hi;
  reg [63:0] macro_deadline_cycles;
  reg [31:0] macro_vector_op, macro_vector_flags;
  reg [63:0] macro_src0_iova, macro_src1_iova, macro_src2_iova;
  reg [63:0] macro_dst_iova, macro_scratch_iova;
  reg [63:0] macro_element_count;
  reg [31:0] macro_outer_count, macro_dtype;
  reg [63:0] macro_src0_stride, macro_src1_stride;
  reg [63:0] macro_src2_stride, macro_dst_stride;
  reg [31:0] macro_scalar0, macro_scalar1;
  reg [31:0] macro_scratch_bytes, macro_rope_position;
  reg [63:0] macro_src0_window_base, macro_src0_window_size;
  reg [1:0] macro_src0_window_perm;
  reg [63:0] macro_src1_window_base, macro_src1_window_size;
  reg [1:0] macro_src1_window_perm;
  reg [63:0] macro_dst_window_base, macro_dst_window_size;
  reg [1:0] macro_dst_window_perm;
  reg macro_windows_generation_valid;

  wire completion_valid;
  reg completion_ready;
  wire [PID_W-1:0] completion_producer_id;
  wire completion_npu_required;
  wire [OPCLASS_W-1:0] completion_opclass;
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

  reg desc_write_valid;
  wire desc_write_ready;
  reg [5:0] desc_write_id;
  reg [2:0] desc_write_word;
  reg [63:0] desc_write_data;
  wire desc_write_error;
  wire [`NPU_ERROR_W-1:0] desc_write_error_code;
  reg host_lmem_rd_valid;
  reg [31:0] host_lmem_rd_addr;
  reg [3:0] host_lmem_rd_bytes;
  wire [63:0] host_lmem_rd_data;
  wire host_lmem_rd_oob;
  reg host_lmem_wr_valid;
  reg [31:0] host_lmem_wr_addr;
  reg [63:0] host_lmem_wr_data;
  reg [7:0] host_lmem_wr_strb;
  wire host_lmem_wr_oob, host_lmem_ready;

  wire gmem_req_valid;
  wire gmem_req_ready;
  wire gmem_req_write;
  wire [63:0] gmem_req_addr, gmem_req_wdata;
  wire [7:0] gmem_req_wstrb;
  reg gmem_rsp_valid;
  wire gmem_rsp_ready;
  reg [63:0] gmem_rsp_rdata;
  reg gmem_rsp_error;
  reg sync_tag_ack, error_clear;
  wire [63:0] sync_tag;
  wire sync_tag_valid, busy, error;
  wire [`NPU_ERROR_W-1:0] error_code;
  wire [63:0] command_count, completion_count, error_count;
  wire [63:0] npu_required_issued, npu_required_completed;
  wire [63:0] tiu_cycles, dma_cycles, dma_bytes;
  wire [63:0] macro_command_count, macro_f32_start_count;
  wire [63:0] macro_completion_count;

  wire q8_portal_req_valid_unused;
  wire [3:0] q8_portal_req_mask_unused;
  wire [255:0] q8_portal_req_addr_unused;
  wire q8_portal_rsp_ready_unused;
  wire [63:0] q8_portal_request_count_unused;
  wire [63:0] q8_portal_response_count_unused;
  wire [63:0] q8_portal_block_count_unused;
  wire [63:0] q8_portal_byte_count_unused;
  wire q8_portal_outstanding_unused;

  wire f32_alu_portal_req_valid_unused;
  wire f32_alu_portal_req_write_unused;
  wire [7:0] f32_alu_portal_req_mask_unused;
  wire [511:0] f32_alu_portal_req_src0_addr_unused;
  wire [511:0] f32_alu_portal_req_src1_addr_unused;
  wire [511:0] f32_alu_portal_req_dst_addr_unused;
  wire [255:0] f32_alu_portal_req_wdata_unused;
  wire f32_alu_portal_rsp_ready_unused;
  wire [63:0] f32_alu_portal_request_groups_unused;
  wire [63:0] f32_alu_portal_response_groups_unused;
  wire [63:0] f32_alu_portal_read_groups_unused;
  wire [63:0] f32_alu_portal_write_groups_unused;
  wire [63:0] f32_alu_portal_input_words_unused;
  wire [63:0] f32_alu_portal_output_words_unused;
  wire [63:0] f32_alu_portal_read_bytes_unused;
  wire [63:0] f32_alu_portal_write_bytes_unused;
  wire f32_alu_portal_outstanding_unused;

  wire f32_mover_portal_req_valid_unused;
  wire f32_mover_portal_req_write_unused;
  wire [15:0] f32_mover_portal_req_mask_unused;
  wire [1023:0] f32_mover_portal_req_addr_unused;
  wire [511:0] f32_mover_portal_req_wdata_unused;
  wire f32_mover_portal_rsp_ready_unused;
  wire [63:0] f32_mover_portal_request_groups_unused;
  wire [63:0] f32_mover_portal_response_groups_unused;
  wire [63:0] f32_mover_portal_read_groups_unused;
  wire [63:0] f32_mover_portal_write_groups_unused;
  wire [63:0] f32_mover_portal_read_words_unused;
  wire [63:0] f32_mover_portal_write_words_unused;
  wire [63:0] f32_mover_portal_read_bytes_unused;
  wire [63:0] f32_mover_portal_write_bytes_unused;
  wire f32_mover_portal_outstanding_unused;

  TensorNpuCoprocessor #(
    .LMEM_BYTES(4096), .PID_W(PID_W), .OPCLASS_W(OPCLASS_W),
    .MACRO_CAPABILITY_EPOCH(32'h0000_0001)
  ) u_coprocessor (
    .clk(clk), .rst(rst),
    .cmd_valid_i(cmd_valid), .cmd_ready_o(cmd_ready),
    .cmd_is_64_i(cmd_is_64), .cmd_bits_i(cmd_bits),
    .cmd_rs_value_i(cmd_rs_value), .cmd_producer_id_i(cmd_producer_id),
    .cmd_npu_required_i(cmd_npu_required), .cmd_opclass_i(cmd_opclass),
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
    .macro_outer_count_i(macro_outer_count), .macro_dtype_i(macro_dtype),
    .macro_src0_stride_i(macro_src0_stride),
    .macro_src1_stride_i(macro_src1_stride),
    .macro_src2_stride_i(macro_src2_stride),
    .macro_dst_stride_i(macro_dst_stride),
    .macro_scalar0_i(macro_scalar0), .macro_scalar1_i(macro_scalar1),
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
    .desc_write_valid_i(desc_write_valid),
    .desc_write_ready_o(desc_write_ready), .desc_write_id_i(desc_write_id),
    .desc_write_word_i(desc_write_word), .desc_write_data_i(desc_write_data),
    .desc_write_error_o(desc_write_error),
    .desc_write_error_code_o(desc_write_error_code),
    .host_lmem_rd_valid_i(host_lmem_rd_valid),
    .host_lmem_rd_addr_i(host_lmem_rd_addr),
    .host_lmem_rd_bytes_i(host_lmem_rd_bytes),
    .host_lmem_rd_data_o(host_lmem_rd_data),
    .host_lmem_rd_oob_o(host_lmem_rd_oob),
    .host_lmem_wr_valid_i(host_lmem_wr_valid),
    .host_lmem_wr_addr_i(host_lmem_wr_addr),
    .host_lmem_wr_data_i(host_lmem_wr_data),
    .host_lmem_wr_strb_i(host_lmem_wr_strb),
    .host_lmem_wr_oob_o(host_lmem_wr_oob),
    .host_lmem_ready_o(host_lmem_ready),
    .gmem_req_valid_o(gmem_req_valid), .gmem_req_ready_i(gmem_req_ready),
    .gmem_req_write_o(gmem_req_write), .gmem_req_addr_o(gmem_req_addr),
    .gmem_req_wdata_o(gmem_req_wdata), .gmem_req_wstrb_o(gmem_req_wstrb),
    .gmem_rsp_valid_i(gmem_rsp_valid), .gmem_rsp_ready_o(gmem_rsp_ready),
    .gmem_rsp_rdata_i(gmem_rsp_rdata), .gmem_rsp_error_i(gmem_rsp_error),
    .q8_portal_req_valid_o(q8_portal_req_valid_unused),
    .q8_portal_req_ready_i(1'b0),
    .q8_portal_req_mask_o(q8_portal_req_mask_unused),
    .q8_portal_req_addr_o(q8_portal_req_addr_unused),
    .q8_portal_rsp_valid_i(1'b0),
    .q8_portal_rsp_ready_o(q8_portal_rsp_ready_unused),
    .q8_portal_rsp_mask_i(4'b0),
    .q8_portal_rsp_blocks_i(1088'b0),
    .q8_portal_rsp_error_i(1'b0),
    .q8_portal_request_count_o(q8_portal_request_count_unused),
    .q8_portal_response_count_o(q8_portal_response_count_unused),
    .q8_portal_block_count_o(q8_portal_block_count_unused),
    .q8_portal_byte_count_o(q8_portal_byte_count_unused),
    .q8_portal_outstanding_o(q8_portal_outstanding_unused),
    .f32_alu_portal_req_valid_o(f32_alu_portal_req_valid_unused),
    .f32_alu_portal_req_ready_i(1'b0),
    .f32_alu_portal_req_write_o(f32_alu_portal_req_write_unused),
    .f32_alu_portal_req_mask_o(f32_alu_portal_req_mask_unused),
    .f32_alu_portal_req_src0_addr_o(
        f32_alu_portal_req_src0_addr_unused),
    .f32_alu_portal_req_src1_addr_o(
        f32_alu_portal_req_src1_addr_unused),
    .f32_alu_portal_req_dst_addr_o(f32_alu_portal_req_dst_addr_unused),
    .f32_alu_portal_req_wdata_o(f32_alu_portal_req_wdata_unused),
    .f32_alu_portal_rsp_valid_i(1'b0),
    .f32_alu_portal_rsp_ready_o(f32_alu_portal_rsp_ready_unused),
    .f32_alu_portal_rsp_mask_i(8'b0),
    .f32_alu_portal_rsp_src0_data_i(256'b0),
    .f32_alu_portal_rsp_src1_data_i(256'b0),
    .f32_alu_portal_rsp_error_i(1'b0),
    .f32_alu_portal_request_groups_o(
        f32_alu_portal_request_groups_unused),
    .f32_alu_portal_response_groups_o(
        f32_alu_portal_response_groups_unused),
    .f32_alu_portal_read_groups_o(f32_alu_portal_read_groups_unused),
    .f32_alu_portal_write_groups_o(f32_alu_portal_write_groups_unused),
    .f32_alu_portal_input_words_o(f32_alu_portal_input_words_unused),
    .f32_alu_portal_output_words_o(f32_alu_portal_output_words_unused),
    .f32_alu_portal_read_bytes_o(f32_alu_portal_read_bytes_unused),
    .f32_alu_portal_write_bytes_o(f32_alu_portal_write_bytes_unused),
    .f32_alu_portal_outstanding_o(f32_alu_portal_outstanding_unused),
    .f32_mover_portal_req_valid_o(f32_mover_portal_req_valid_unused),
    .f32_mover_portal_req_ready_i(1'b0),
    .f32_mover_portal_req_write_o(f32_mover_portal_req_write_unused),
    .f32_mover_portal_req_mask_o(f32_mover_portal_req_mask_unused),
    .f32_mover_portal_req_addr_o(f32_mover_portal_req_addr_unused),
    .f32_mover_portal_req_wdata_o(f32_mover_portal_req_wdata_unused),
    .f32_mover_portal_rsp_valid_i(1'b0),
    .f32_mover_portal_rsp_ready_o(f32_mover_portal_rsp_ready_unused),
    .f32_mover_portal_rsp_mask_i(16'b0),
    .f32_mover_portal_rsp_rdata_i(512'b0),
    .f32_mover_portal_rsp_error_i(1'b0),
    .f32_mover_portal_request_groups_o(
        f32_mover_portal_request_groups_unused),
    .f32_mover_portal_response_groups_o(
        f32_mover_portal_response_groups_unused),
    .f32_mover_portal_read_groups_o(f32_mover_portal_read_groups_unused),
    .f32_mover_portal_write_groups_o(
        f32_mover_portal_write_groups_unused),
    .f32_mover_portal_read_words_o(f32_mover_portal_read_words_unused),
    .f32_mover_portal_write_words_o(
        f32_mover_portal_write_words_unused),
    .f32_mover_portal_read_bytes_o(f32_mover_portal_read_bytes_unused),
    .f32_mover_portal_write_bytes_o(
        f32_mover_portal_write_bytes_unused),
    .f32_mover_portal_outstanding_o(f32_mover_portal_outstanding_unused),
    .sync_tag_ack_i(sync_tag_ack), .sync_tag_o(sync_tag),
    .sync_tag_valid_o(sync_tag_valid), .error_clear_i(error_clear),
    .busy_o(busy), .error_o(error), .error_code_o(error_code),
    .command_count_o(command_count), .completion_count_o(completion_count),
    .error_count_o(error_count),
    .npu_required_issued_o(npu_required_issued),
    .npu_required_completed_o(npu_required_completed),
    .tiu_cycles_o(tiu_cycles), .dma_cycles_o(dma_cycles),
    .dma_bytes_o(dma_bytes), .macro_command_count_o(macro_command_count),
    .macro_f32_start_count_o(macro_f32_start_count),
    .macro_completion_count_o(macro_completion_count)
  );

  reg [7:0] memory [0:MEM_BYTES-1];
  reg pending_q, pending_write_q, pending_error_q;
  reg [63:0] pending_addr_q, pending_wdata_q, pending_rdata_q;
  reg [7:0] pending_wstrb_q;
  reg hold_response_q, request_backpressure_q;
  integer response_delay_q, pending_delay_q;
  integer inject_read_ordinal_q, inject_write_ordinal_q;
  integer command_reads_q, command_writes_q, command_responses_q;
  reg held_request_q, held_request_write_q;
  reg [63:0] held_request_addr_q, held_request_wdata_q;
  reg [7:0] held_request_wstrb_q;
  integer held_request_cycles_q;
  integer failures, i, byte_lane, run_group;
  reg protocol_failure_q;
  reg [63:0] expected_issued_q, expected_completed_q;
  reg [63:0] expected_sequence_q, expected_producer_q, expected_tag_q;
  reg [63:0] expected_node_lo_q, expected_node_hi_q;
  reg [31:0] expected_kernel_q, expected_profile_q, expected_context_q;
  reg [13:0] successful_profile_terminals_q;

  function automatic [63:0] load_u64(input [63:0] address);
    integer lane;
    begin
      load_u64 = 64'd0;
      for (lane = 0; lane < 8; lane = lane + 1)
        load_u64[(lane * 8) +: 8] =
            memory[{10'd0, address[21:0]} + lane];
    end
  endfunction

  function automatic [31:0] load_u32(input [63:0] address);
    begin
      load_u32 = {memory[{10'd0, address[21:0]} + 3],
                  memory[{10'd0, address[21:0]} + 2],
                  memory[{10'd0, address[21:0]} + 1],
                  memory[{10'd0, address[21:0]}]};
    end
  endfunction

  function automatic [15:0] load_u16(input [63:0] address);
    begin
      load_u16 = {memory[{10'd0, address[21:0]} + 1],
                  memory[{10'd0, address[21:0]}]};
    end
  endfunction

  task automatic put_u64(input [63:0] address, input [63:0] value);
    integer lane;
    begin
      for (lane = 0; lane < 8; lane = lane + 1)
        memory[{10'd0, address[21:0]} + lane] =
            value[(lane * 8) +: 8];
    end
  endtask

  task automatic put_u32(input [63:0] address, input [31:0] value);
    begin
      memory[{10'd0, address[21:0]}] = value[7:0];
      memory[{10'd0, address[21:0]} + 1] = value[15:8];
      memory[{10'd0, address[21:0]} + 2] = value[23:16];
      memory[{10'd0, address[21:0]} + 3] = value[31:24];
    end
  endtask

  task automatic put_u16(input [63:0] address, input [15:0] value);
    begin
      memory[{10'd0, address[21:0]}] = value[7:0];
      memory[{10'd0, address[21:0]} + 1] = value[15:8];
    end
  endtask

  task automatic check(input logic condition, input string message);
    begin
      if (!condition) begin
        failures = failures + 1;
        $display("[NPU-COPROC-BATCH2][FAIL] %s", message);
      end
    end
  endtask

  assign gmem_req_ready = !pending_q && !request_backpressure_q;

  always @(*) begin
    gmem_rsp_valid = pending_q && !hold_response_q &&
                     (pending_delay_q == 0);
    gmem_rsp_rdata = pending_rdata_q;
    gmem_rsp_error = pending_error_q;
  end

  always @(posedge clk) begin
    if (rst) begin
      pending_q <= 1'b0;
      pending_delay_q <= 0;
      command_reads_q <= 0;
      command_writes_q <= 0;
      command_responses_q <= 0;
      held_request_q <= 1'b0;
      held_request_cycles_q <= 0;
    end else begin
      if (pending_q && (pending_delay_q > 0) && !hold_response_q)
        pending_delay_q <= pending_delay_q - 1;
      if (gmem_req_valid && !gmem_req_ready) begin
        if (!held_request_q) begin
          held_request_q <= 1'b1;
          held_request_write_q <= gmem_req_write;
          held_request_addr_q <= gmem_req_addr;
          held_request_wdata_q <= gmem_req_wdata;
          held_request_wstrb_q <= gmem_req_wstrb;
        end else if ((held_request_write_q != gmem_req_write) ||
                     (held_request_addr_q != gmem_req_addr) ||
                     (held_request_wdata_q != gmem_req_wdata) ||
                     (held_request_wstrb_q != gmem_req_wstrb)) begin
          protocol_failure_q <= 1'b1;
          $display("[NPU-COPROC-BATCH2][FAIL] request payload changed under backpressure");
        end
        held_request_cycles_q <= held_request_cycles_q + 1;
      end else begin
        held_request_q <= 1'b0;
      end
      if (gmem_req_valid && gmem_req_ready) begin
        if (pending_q) begin
          protocol_failure_q <= 1'b1;
          $display("[NPU-COPROC-BATCH2][FAIL] more than one public GMEM request outstanding");
        end
        pending_q <= 1'b1;
        pending_write_q <= gmem_req_write;
        pending_addr_q <= gmem_req_addr;
        pending_wdata_q <= gmem_req_wdata;
        pending_wstrb_q <= gmem_req_wstrb;
        pending_rdata_q <= load_u64(gmem_req_addr & ~64'd7);
        pending_delay_q <= response_delay_q;
        if (gmem_req_write) begin
          command_writes_q <= command_writes_q + 1;
          pending_error_q <= (inject_write_ordinal_q > 0) &&
              ((command_writes_q + 1) == inject_write_ordinal_q);
        end else begin
          command_reads_q <= command_reads_q + 1;
          pending_error_q <= (inject_read_ordinal_q > 0) &&
              ((command_reads_q + 1) == inject_read_ordinal_q);
        end
      end
      if (gmem_rsp_valid && gmem_rsp_ready) begin
        command_responses_q <= command_responses_q + 1;
        if (pending_write_q && !pending_error_q)
          for (byte_lane = 0; byte_lane < 8; byte_lane = byte_lane + 1)
            if (pending_wstrb_q[byte_lane])
              memory[{10'd0, pending_addr_q[21:0]} + byte_lane] <=
                  pending_wdata_q[(byte_lane * 8) +: 8];
        pending_q <= 1'b0;
        pending_error_q <= 1'b0;
      end
    end
  end

  always #5 clk <= ~clk;

  task automatic clear_descriptor;
    begin
      macro_abi_valid = 1'b1;
      macro_kernel_id = 32'd0;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_context_id = CANONICAL_CONTEXT_ID;
      macro_capability_epoch = 32'd1;
      macro_sequence_id = macro_sequence_id + 64'd1;
      macro_producer_id = 64'h1020_3040_5060_7080 ^ macro_sequence_id;
      macro_user_tag = 64'h8877_6655_4433_2211 + macro_sequence_id;
      macro_node_count = 32'd1;
      macro_node_hash_lo = 64'h0123_4567_89ab_cdef ^ macro_sequence_id;
      macro_node_hash_hi = 64'hfedc_ba98_7654_3210 + macro_sequence_id;
      macro_deadline_cycles = 64'd0;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = SRC0_BASE;
      macro_src1_iova = SRC1_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = DST_BASE;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd0;
      macro_outer_count = 32'd0;
      macro_dtype = DTYPE_F32;
      macro_src0_stride = 64'd0;
      macro_src1_stride = 64'd0;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd0;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = SRC0_BASE;
      macro_src0_window_size = 64'd0;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = SRC1_BASE;
      macro_src1_window_size = 64'd0;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = DST_BASE;
      macro_dst_window_size = 64'd0;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      inject_read_ordinal_q = 0;
      inject_write_ordinal_q = 0;
      response_delay_q = 0;
      hold_response_q = 1'b0;
      request_backpressure_q = 1'b0;
    end
  endtask

  task automatic configure_mover(input integer profile);
    begin
      clear_descriptor();
      macro_kernel_id = profile >= 7 ? KERNEL_SET_ROWS : KERNEL_MOVER;
      macro_vector_flags = profile;
      case (profile)
        0: begin
          macro_vector_op = 32'd22;
          macro_element_count = 64'd4;
          macro_outer_count = 32'd6144;
          macro_src0_stride = 64'd12;
          macro_src1_stride = 64'd4;
          macro_dst_stride = 64'd16;
          macro_src0_window_size = 64'd73728;
          macro_src1_window_size = 64'd24576;
          macro_dst_window_size = 64'd98304;
        end
        1: begin
          macro_vector_op = 32'd35;
          macro_element_count = 64'd2048;
          macro_outer_count = 32'd1;
          macro_src0_stride = 64'd1024;
          macro_src1_iova = 64'd0;
          macro_src1_window_base = 64'd0;
          macro_src1_window_size = 64'd0;
          macro_dst_stride = 64'd8192;
          macro_src0_window_size = 64'd8192;
          macro_dst_window_size = 64'd8192;
        end
        2: begin
          macro_vector_op = 32'd35;
          macro_src0_iova = SRC0_BASE + 64'd1024;
          macro_element_count = 64'd2048;
          macro_outer_count = 32'd1;
          macro_src0_stride = 64'd2048;
          macro_src1_iova = 64'd0;
          macro_src1_window_base = 64'd0;
          macro_src1_window_size = 64'd0;
          macro_dst_stride = 64'd8192;
          macro_src0_window_size = 64'd16384;
          macro_dst_window_size = 64'd8192;
        end
        3: begin
          macro_vector_op = 32'd34;
          macro_src1_iova = SRC1_BASE + 64'd73728;
          macro_dst_iova = DST_BASE + 64'd73728;
          macro_element_count = 64'd18432;
          macro_outer_count = 32'd0;
          macro_src0_stride = 64'd73728;
          macro_src1_stride = 64'd73728;
          macro_dst_stride = 64'd73728;
          macro_src0_window_size = 64'd73728;
          macro_src1_window_size = 64'd73728;
          macro_dst_window_size = 64'd73728;
        end
        4: begin
          macro_vector_op = 32'd34;
          macro_src0_iova = SRC0_BASE + 64'd4;
          macro_element_count = 64'd18432;
          macro_outer_count = 32'd1;
          macro_src0_stride = 64'd16;
          macro_src1_stride = 64'd73728;
          macro_dst_stride = 64'd73728;
          macro_src0_window_size = 64'd98304;
          macro_src1_window_size = 64'd73728;
          macro_dst_window_size = 64'd73728;
        end
        5: begin
          macro_vector_op = 32'd34;
          macro_element_count = 64'd262144;
          macro_outer_count = 32'd0;
          macro_src0_iova = BIG_SRC0_BASE;
          macro_src1_iova = BIG_SRC1_BASE + 64'd1048576;
          macro_dst_iova = BIG_DST_BASE + 64'd1048576;
          macro_src0_stride = 64'd1048576;
          macro_src1_stride = 64'd1048576;
          macro_dst_stride = 64'd1048576;
          macro_src0_window_base = BIG_SRC0_BASE;
          macro_src1_window_base = BIG_SRC1_BASE;
          macro_dst_window_base = BIG_DST_BASE;
          macro_src0_window_size = 64'd1048576;
          macro_src1_window_size = 64'd1048576;
          macro_dst_window_size = 64'd1048576;
        end
        6: begin
          macro_vector_op = 32'd34;
          macro_element_count = 64'd262144;
          macro_outer_count = 32'd1;
          macro_src0_iova = BIG_SRC0_BASE;
          macro_src1_iova = BIG_SRC1_BASE;
          macro_dst_iova = BIG_DST_BASE;
          macro_src0_stride = 64'd512;
          macro_src1_stride = 64'd1048576;
          macro_dst_stride = 64'd1048576;
          macro_src0_window_base = BIG_SRC0_BASE;
          macro_src1_window_base = BIG_SRC1_BASE;
          macro_dst_window_base = BIG_DST_BASE;
          macro_src0_window_size = 64'd1048576;
          macro_src1_window_size = 64'd1048576;
          macro_dst_window_size = 64'd1048576;
        end
        7: begin
          macro_vector_op = 32'd42;
          macro_element_count = 64'd1;
          macro_outer_count = 32'd131072;
          macro_src0_stride = 64'd4;
          macro_src1_stride = 64'd4096;
          macro_src2_iova = DST_BASE;
          macro_src2_stride = 64'd2;
          macro_dst_stride = 64'd2;
          macro_scalar0 = 32'd256;
          macro_scalar1 = 32'd5;
          macro_src0_window_size = 64'd2048;
          macro_src1_window_size = 64'd4096;
          macro_dst_window_size = 64'd262144;
        end
        8: begin
          macro_vector_op = 32'd42;
          macro_element_count = 64'd512;
          macro_outer_count = 32'd256;
          macro_src0_stride = 64'd2048;
          macro_src1_stride = 64'd8;
          macro_src2_iova = DST_BASE;
          macro_src2_stride = 64'd1024;
          macro_dst_stride = 64'd1024;
          macro_scalar0 = 32'd256;
          macro_scalar1 = 32'd3;
          macro_src0_window_size = 64'd2048;
          macro_src1_window_size = 64'd8;
          macro_dst_window_size = 64'd262144;
        end
        default: begin
          macro_vector_op = 32'hffff_ffff;
        end
      endcase
    end
  endtask

  task automatic configure_attention(input integer profile);
    begin
      clear_descriptor();
      macro_kernel_id = KERNEL_ATTENTION;
      macro_vector_op = 32'd29;
      macro_vector_flags = profile;
      macro_element_count = 64'd256;
      macro_outer_count = 32'd8;
      macro_src0_stride = profile == 0 ? 64'd1024 : 64'd512;
      macro_src1_stride = profile == 0 ? 64'd8192 : 64'd1024;
      macro_dst_stride = 64'd1024;
      macro_scalar0 = profile == 0 ? 32'd10 : 32'd0;
      macro_src0_window_size = 64'd262144;
      macro_src1_window_size = 64'd8192;
      macro_dst_window_size = 64'd8192;
    end
  endtask

  task automatic configure_softmax;
    begin
      clear_descriptor();
      macro_kernel_id = KERNEL_REDUCE;
      macro_vector_op = 32'd6;
      macro_vector_flags = 32'd0;
      macro_element_count = 64'd256;
      macro_outer_count = 32'd8;
      macro_src0_stride = 64'd1024;
      macro_src1_stride = 64'd1024;
      macro_dst_stride = 64'd1024;
      macro_scalar0 = 32'h3d80_0000;
      macro_src0_window_size = 64'd8192;
      macro_src1_window_size = 64'd1024;
      macro_dst_window_size = 64'd8192;
    end
  endtask

  task automatic configure_rope(input integer profile);
    begin
      clear_descriptor();
      macro_kernel_id = KERNEL_ROPE;
      macro_vector_op = 32'd48;
      macro_vector_flags = profile;
      macro_element_count = 64'd256;
      macro_outer_count = profile == 0 ? 32'd8 : 32'd2;
      macro_src0_stride = 64'd1024;
      macro_src1_stride = 64'd16;
      macro_dst_stride = 64'd1024;
      macro_src0_window_size = profile == 0 ? 64'd8192 : 64'd2048;
      macro_src1_window_size = 64'd16;
      macro_dst_window_size = profile == 0 ? 64'd8192 : 64'd2048;
    end
  endtask

  task automatic zero_bytes(input [63:0] base, input integer count);
    integer offset;
    begin
      for (offset = 0; offset < count; offset = offset + 1)
        memory[{10'd0, base[21:0]} + offset] = 8'd0;
    end
  endtask

  task automatic launch_command;
    begin
      while (!macro_cmd_ready)
        @(negedge clk);
      command_reads_q = 0;
      command_writes_q = 0;
      command_responses_q = 0;
      expected_sequence_q = macro_sequence_id;
      expected_producer_q = macro_producer_id;
      expected_tag_q = macro_user_tag;
      expected_node_lo_q = macro_node_hash_lo;
      expected_node_hi_q = macro_node_hash_hi;
      expected_kernel_q = macro_kernel_id;
      expected_profile_q = macro_vector_flags;
      expected_context_q = macro_context_id;
      expected_issued_q = expected_issued_q + 64'd1;
      $display("[NPU-COPROC-BATCH2][START] kernel=%08x profile=%0d sequence=%0d",
               macro_kernel_id, macro_vector_flags, macro_sequence_id);
      $fflush();
      @(negedge clk);
      macro_cmd_valid = 1'b1;
      @(negedge clk);
      macro_cmd_valid = 1'b0;
    end
  endtask

  task automatic clear_sticky_error;
    begin
      if (error) begin
        @(negedge clk);
        error_clear = 1'b1;
        @(negedge clk);
        error_clear = 1'b0;
      end
      while (!macro_cmd_ready)
        @(negedge clk);
    end
  endtask

  task automatic wait_terminal(
      input logic expect_success,
      input [63:0] expected_read_bytes,
      input [63:0] expected_write_bytes,
      input [63:0] expected_work,
      input integer limit_cycles,
      input logic hold_completion);
    integer cycles, hold_index;
    reg [63:0] held_cycles;
    begin
      cycles = 0;
      while (!completion_valid && (cycles < limit_cycles)) begin
        @(negedge clk);
        cycles = cycles + 1;
      end
      check(completion_valid, "terminal timeout");
      if (completion_valid) begin
        check(completion_is_macro, "terminal lost macro identity");
        check(completion_npu_required, "terminal lost REQUIRED echo");
        check(completion_macro_kernel_id == expected_kernel_q,
              "kernel identity mismatch");
        check(completion_macro_vector_flags == expected_profile_q,
              "full profile identity mismatch");
        check(completion_macro_command_flags == FLAGS_REQUIRED_PROFILE,
              "command flags identity mismatch");
        check(completion_macro_sequence_id == expected_sequence_q,
              "sequence identity mismatch");
        check(completion_macro_producer_id == expected_producer_q,
              "producer identity mismatch");
        check(completion_macro_user_tag == expected_tag_q,
              "user tag identity mismatch");
        check(completion_macro_covered_node_count == 32'd1,
              "node count identity mismatch");
        check(completion_macro_node_hash_lo == expected_node_lo_q &&
              completion_macro_node_hash_hi == expected_node_hi_q,
              "full node hash identity mismatch");
        check(completion_macro_context_id == expected_context_q,
              "context identity mismatch");
        check(npu_required_issued == expected_issued_q,
              "REQUIRED issued counter mismatch");
        check(!pending_q && (command_reads_q + command_writes_q ==
                            command_responses_q),
              "terminal retained public GMEM credit");
        if (expect_success) begin
          expected_completed_q = expected_completed_q + 64'd1;
          check(!completion_error && (completion_error_code == `NPU_ERR_NONE),
                "success terminal carried error");
          check((completion_macro_status == 32'd0) &&
                (completion_macro_error_class == 32'd0),
                "success terminal carried failure ABI payload");
          check(completion_macro_gmem_read_bytes == expected_read_bytes,
                "success read byte counter mismatch");
          check(completion_macro_gmem_write_bytes == expected_write_bytes,
                "success write byte counter mismatch");
          check(completion_macro_vector_element_count == expected_work,
                "success work counter mismatch");
          check(completion_macro_q8_mac_count == 64'd0 &&
                completion_macro_state_update_count == 64'd0,
                "unrelated completion counters changed");
          if (!completion_error &&
              (completion_error_code == `NPU_ERR_NONE) &&
              (completion_macro_status == 32'd0) &&
              (completion_macro_error_class == 32'd0) &&
              (completion_macro_gmem_read_bytes == expected_read_bytes) &&
              (completion_macro_gmem_write_bytes == expected_write_bytes) &&
              (completion_macro_vector_element_count == expected_work) &&
              (completion_macro_q8_mac_count == 64'd0) &&
              (completion_macro_state_update_count == 64'd0)) begin
            case (expected_kernel_q)
              KERNEL_MOVER:
                if (expected_profile_q <= 32'd6)
                  successful_profile_terminals_q[
                      expected_profile_q[3:0]] = 1'b1;
              KERNEL_SET_ROWS:
                if ((expected_profile_q >= 32'd7) &&
                    (expected_profile_q <= 32'd8))
                  successful_profile_terminals_q[
                      expected_profile_q[3:0]] = 1'b1;
              KERNEL_ATTENTION:
                if (expected_profile_q <= 32'd1)
                  successful_profile_terminals_q[
                      4'd9 + {3'd0, expected_profile_q[0]}] = 1'b1;
              KERNEL_REDUCE:
                successful_profile_terminals_q[11] = 1'b1;
              KERNEL_ROPE:
                if (expected_profile_q <= 32'd1)
                  successful_profile_terminals_q[
                      4'd12 + {3'd0, expected_profile_q[0]}] = 1'b1;
              default: begin end
            endcase
            $display("[NPU-COPROC-BATCH2][PROFILE-PASS] kernel=%08x profile=%0d cycles=%0d read=%0d write=%0d work=%0d",
                     expected_kernel_q, expected_profile_q, cycles,
                     expected_read_bytes, expected_write_bytes,
                     expected_work);
            $fflush();
          end
        end else begin
          check(completion_error && (completion_error_code != `NPU_ERR_NONE),
                "failure became success-visible");
          check(completion_macro_status != 32'd0 &&
                completion_macro_error_class != 32'd0,
                "failure lacked ABI error payload");
        end
        check(npu_required_completed == expected_completed_q,
              "REQUIRED success-only completed counter mismatch");
        if (hold_completion) begin
          held_cycles = completion_macro_npu_cycles;
          for (hold_index = 0; hold_index < 4; hold_index = hold_index + 1) begin
            macro_sequence_id = macro_sequence_id + 64'h1111;
            macro_producer_id = macro_producer_id ^ 64'hffff;
            macro_user_tag = macro_user_tag + 64'h2222;
            macro_node_hash_lo = ~macro_node_hash_lo;
            @(negedge clk);
            check(completion_valid &&
                  (completion_macro_sequence_id == expected_sequence_q) &&
                  (completion_macro_producer_id == expected_producer_q) &&
                  (completion_macro_user_tag == expected_tag_q) &&
                  (completion_macro_node_hash_lo == expected_node_lo_q) &&
                  (completion_macro_node_hash_hi == expected_node_hi_q) &&
                  (completion_macro_npu_cycles == held_cycles),
                  "completion payload changed under backpressure");
          end
        end
      end
      completion_ready = 1'b1;
      @(negedge clk);
      completion_ready = 1'b0;
      if (!expect_success)
        clear_sticky_error();
      else
        while (!macro_cmd_ready)
          @(negedge clk);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    cmd_valid = 1'b0;
    cmd_is_64 = 1'b0;
    cmd_bits = 64'd0;
    cmd_rs_value = 64'd0;
    cmd_producer_id = {PID_W{1'b0}};
    cmd_npu_required = 1'b0;
    cmd_opclass = {OPCLASS_W{1'b0}};
    macro_cmd_valid = 1'b0;
    macro_sequence_id = 64'h1000_0000_0000_0000;
    macro_producer_id = 64'd0;
    macro_user_tag = 64'd0;
    completion_ready = 1'b0;
    desc_write_valid = 1'b0;
    desc_write_id = 6'd0;
    desc_write_word = 3'd0;
    desc_write_data = 64'd0;
    host_lmem_rd_valid = 1'b0;
    host_lmem_rd_addr = 32'd0;
    host_lmem_rd_bytes = 4'd0;
    host_lmem_wr_valid = 1'b0;
    host_lmem_wr_addr = 32'd0;
    host_lmem_wr_data = 64'd0;
    host_lmem_wr_strb = 8'd0;
    sync_tag_ack = 1'b0;
    error_clear = 1'b0;
    hold_response_q = 1'b0;
    request_backpressure_q = 1'b0;
    response_delay_q = 0;
    inject_read_ordinal_q = 0;
    inject_write_ordinal_q = 0;
    pending_q = 1'b0;
    pending_error_q = 1'b0;
    pending_delay_q = 0;
    command_reads_q = 0;
    command_writes_q = 0;
    command_responses_q = 0;
    held_request_q = 1'b0;
    held_request_cycles_q = 0;
    protocol_failure_q = 1'b0;
    successful_profile_terminals_q = 14'd0;
    run_group = -1;
    if (!$value$plusargs("GROUP=%d", run_group))
      run_group = -1;
    failures = 0;
    expected_issued_q = 64'd0;
    expected_completed_q = 64'd0;
    for (i = 0; i < MEM_BYTES; i = i + 1)
      memory[i] = 8'ha5;
    clear_descriptor();
    repeat (5) @(negedge clk);
    rst = 1'b0;
    repeat (3) @(negedge clk);
    check(macro_cmd_ready && !busy && !error,
          "reset did not expose clean public macro boundary");

    if ((run_group < 0) || (run_group == 0)) begin
    // Unsupported kernel, wrong full profile, short capability, alias,
    // semantic-IOVA mismatch and a 64-bit endpoint overflow all fail before
    // the first child/GMEM action.
    clear_descriptor();
    macro_kernel_id = 32'h514e_dead;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b1);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "unknown kernel emitted GMEM traffic");

    configure_attention(0);
    macro_context_id = 32'd0;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "non-canonical context emitted GMEM traffic");

    configure_attention(0);
    macro_vector_flags = 32'h0000_0100;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "full-width profile alias reached child");

    configure_attention(0);
    macro_dst_window_size = 64'd8184;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "short destination window emitted GMEM traffic");

    configure_softmax();
    macro_dst_iova = SRC0_BASE;
    macro_dst_window_base = SRC0_BASE;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "read/write physical alias emitted GMEM traffic");

    configure_rope(0);
    macro_src0_iova = 64'hffff_ffff_ffff_f000;
    macro_src0_window_base = 64'hffff_ffff_ffff_f000;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "widened overflow emitted GMEM traffic");

    configure_mover(4);
    macro_src0_iova = SRC0_BASE;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "CPY root IOVA without frozen view reached child");

    configure_mover(2);
    macro_src0_iova = SRC0_BASE + 64'd2048;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 100, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0),
          "CONT mismatched semantic IOVA reached child");

    // Empty CPY is a successful zero-traffic transaction.  Its one-past-end
    // views do not authorize any host copy or destination write.
    configure_mover(3);
    put_u32(DST_BASE + 64'd64, 32'h51c0_ffee);
    launch_command();
    wait_terminal(1'b1, 64'd0, 64'd0, 64'd0, 200, 1'b1);
    check((command_reads_q == 0) && (command_writes_q == 0) &&
          (load_u32(DST_BASE + 64'd64) == 32'h51c0_ffee),
          "empty CPY changed backing or generated traffic");

    // The second empty CPY profile has the widened 262144-element endpoint.
    // It still performs a genuine start/terminal transaction with zero GMEM.
    configure_mover(5);
    put_u32(BIG_DST_BASE + 64'd64, 32'h52c0_ffee);
    launch_command();
    wait_terminal(1'b1, 64'd0, 64'd0, 64'd0, 200, 1'b0);
    check((command_reads_q == 0) && (command_writes_q == 0) &&
          (load_u32(BIG_DST_BASE + 64'd64) == 32'h52c0_ffee),
          "large empty CPY changed backing or generated traffic");

    // CONT full profile.  Request and completion backpressure both prove
    // resident payload stability without hierarchy observation.
    configure_mover(1);
    zero_bytes(SRC0_BASE, 8192);
    zero_bytes(DST_BASE, 8192);
    put_u32(SRC0_BASE, 32'h7fc0_1234);
    put_u32(SRC0_BASE + 64'd4, 32'h8000_0000);
    put_u32(SRC0_BASE + 64'd8188, 32'h0000_0001);
    request_backpressure_q = 1'b1;
    launch_command();
    i = 0;
    while (!gmem_req_valid && (i < 100)) begin
      @(negedge clk);
      i = i + 1;
    end
    check(gmem_req_valid, "CONT did not present blocked request");
    repeat (5) @(negedge clk);
    request_backpressure_q = 1'b0;
    wait_terminal(1'b1, 64'd8192, 64'd8192, 64'd2048,
                  30000, 1'b1);
    check((held_request_cycles_q >= 5) &&
          (load_u32(DST_BASE) == 32'h7fc0_1234) &&
          (load_u32(DST_BASE + 64'd4) == 32'h8000_0000) &&
          (load_u32(DST_BASE + 64'd8188) == 32'h0000_0001),
          "CONT full raw-bit result/backpressure mismatch");

    // CONT's view-offset profile reads the eight logical rows from a 16-KiB
    // backing region; the gap bytes are never copied.
    configure_mover(2);
    zero_bytes(SRC0_BASE, 16384);
    zero_bytes(DST_BASE, 8192);
    put_u32(SRC0_BASE + 64'd1024, 32'h7fa1_0203);
    put_u32(SRC0_BASE + 64'd16380, 32'h8000_0001);
    launch_command();
    wait_terminal(1'b1, 64'd8192, 64'd8192, 64'd2048,
                  30000, 1'b0);
    check((load_u32(DST_BASE) == 32'h7fa1_0203) &&
          (load_u32(DST_BASE + 64'd8188) == 32'h8000_0001),
          "CONT view-offset raw result mismatch");

    // CONCAT0 full 3+1 profile: verify both source classes in the first and
    // last logical rows, not merely a contiguous byte copy.
    configure_mover(0);
    zero_bytes(SRC0_BASE, 73728);
    zero_bytes(SRC1_BASE, 24576);
    zero_bytes(DST_BASE, 98304);
    put_u32(SRC0_BASE, 32'h1111_1111);
    put_u32(SRC0_BASE + 64'd4, 32'h2222_2222);
    put_u32(SRC0_BASE + 64'd8, 32'h3333_3333);
    put_u32(SRC1_BASE, 32'h4444_4444);
    put_u32(SRC0_BASE + 64'd73716, 32'haaaa_aaaa);
    put_u32(SRC0_BASE + 64'd73720, 32'hbbbb_bbbb);
    put_u32(SRC0_BASE + 64'd73724, 32'hcccc_cccc);
    put_u32(SRC1_BASE + 64'd24572, 32'hdddd_dddd);
    launch_command();
    wait_terminal(1'b1, 64'd98304, 64'd98304, 64'd24576,
                  180000, 1'b0);
    check((load_u32(DST_BASE) == 32'h1111_1111) &&
          (load_u32(DST_BASE + 64'd4) == 32'h2222_2222) &&
          (load_u32(DST_BASE + 64'd8) == 32'h3333_3333) &&
          (load_u32(DST_BASE + 64'd12) == 32'h4444_4444) &&
          (load_u32(DST_BASE + 64'd98288) == 32'haaaa_aaaa) &&
          (load_u32(DST_BASE + 64'd98292) == 32'hbbbb_bbbb) &&
          (load_u32(DST_BASE + 64'd98296) == 32'hcccc_cccc) &&
          (load_u32(DST_BASE + 64'd98300) == 32'hdddd_dddd),
          "CONCAT0 full logical raw result mismatch");

    // CPY full strided-view profile.  Source-1 is dependency-only; the RTL
    // writes every logical destination word from source-0.
    configure_mover(4);
    zero_bytes(SRC0_BASE, 98304);
    zero_bytes(SRC1_BASE, 73728);
    zero_bytes(DST_BASE, 73728);
    put_u32(SRC0_BASE + 64'd4, 32'h7fc0_beef);
    put_u32(SRC0_BASE + 64'd8, 32'h8000_0000);
    put_u32(SRC0_BASE + 64'd12, 32'h0000_0001);
    put_u32(SRC0_BASE + 64'd98292, 32'h7f80_0000);
    put_u32(SRC0_BASE + 64'd98296, 32'hff80_0000);
    put_u32(SRC0_BASE + 64'd98300, 32'h3f80_0000);
    launch_command();
    wait_terminal(1'b1, 64'd73728, 64'd73728, 64'd18432,
                  140000, 1'b0);
    check((load_u32(DST_BASE) == 32'h7fc0_beef) &&
          (load_u32(DST_BASE + 64'd4) == 32'h8000_0000) &&
          (load_u32(DST_BASE + 64'd8) == 32'h0000_0001) &&
          (load_u32(DST_BASE + 64'd73716) == 32'h7f80_0000) &&
          (load_u32(DST_BASE + 64'd73720) == 32'hff80_0000) &&
          (load_u32(DST_BASE + 64'd73724) == 32'h3f80_0000),
          "CPY full strided-view raw result mismatch");

    // The flat [128,128,16] CPY is the widened one-MiB profile.  Distinct
    // physical capabilities and distinct raw-memory backing prove it is not
    // admitted through the smaller CPY table entry.
    configure_mover(6);
    zero_bytes(BIG_SRC0_BASE, 1048576);
    zero_bytes(BIG_SRC1_BASE, 1048576);
    zero_bytes(BIG_DST_BASE, 1048576);
    put_u32(BIG_SRC0_BASE, 32'h7fc6_0001);
    put_u32(BIG_SRC0_BASE + 64'd1048572, 32'h8000_0001);
    launch_command();
    wait_terminal(1'b1, 64'd1048576, 64'd1048576, 64'd262144,
                  3000000, 1'b0);
    check((load_u32(BIG_DST_BASE) == 32'h7fc6_0001) &&
          (load_u32(BIG_DST_BASE + 64'd1048572) == 32'h8000_0001),
          "flat CPY widened raw result mismatch");

    // SET_ROWS native profile: raw F32 one is converted solely in RTL to
    // F16 one and scattered into physical slot three.
    configure_mover(8);
    zero_bytes(SRC0_BASE, 2048);
    zero_bytes(SRC1_BASE, 8);
    for (i = 0; i < 262144; i = i + 1)
      memory[{10'd0, DST_BASE[21:0]} + i] = 8'h6d;
    for (i = 0; i < 512; i = i + 1)
      put_u32(SRC0_BASE + (i * 4), 32'h3f80_0000);
    put_u64(SRC1_BASE, 64'd3);
    launch_command();
    wait_terminal(1'b1, 64'd2056, 64'd1024, 64'd512,
                  30000, 1'b0);
    check((load_u16(DST_BASE + 64'd3072) == 16'h3c00) &&
          (load_u16(DST_BASE + 64'd4094) == 16'h3c00) &&
          (load_u16(DST_BASE + 64'd3070) == 16'h6d6d) &&
          (load_u16(DST_BASE + 64'd4096) == 16'h6d6d),
          "SET_ROWS full RTL conversion/scatter/canary mismatch");

    // Transposed SET_ROWS consumes all 512 widened I64 indices and writes one
    // F16 value at physical slot five of every 256-entry cache row.
    configure_mover(7);
    zero_bytes(SRC0_BASE, 2048);
    zero_bytes(SRC1_BASE, 4096);
    for (i = 0; i < 262144; i = i + 1)
      memory[{10'd0, DST_BASE[21:0]} + i] = 8'h3c;
    for (i = 0; i < 512; i = i + 1) begin
      put_u32(SRC0_BASE + (i * 4), 32'h3f80_0000);
      put_u64(SRC1_BASE + (i * 8), (i * 256) + 5);
    end
    launch_command();
    wait_terminal(1'b1, 64'd6144, 64'd1024, 64'd512,
                  30000, 1'b0);
    check((load_u16(DST_BASE + 64'd10) == 16'h3c00) &&
          (load_u16(DST_BASE + 64'd261642) == 16'h3c00) &&
          (load_u16(DST_BASE + 64'd8) == 16'h3c3c) &&
          (load_u16(DST_BASE + 64'd261644) == 16'h3c3c),
          "SET_ROWS transposed raw scatter/canary mismatch");

    // Late read and late write failures reach a failure terminal only after
    // the accepted response credit drains; REQUIRED completed cannot advance.
    configure_mover(1);
    zero_bytes(SRC0_BASE, 8192);
    zero_bytes(DST_BASE, 8192);
    inject_read_ordinal_q = 2;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 2000, 1'b0);

    configure_mover(1);
    zero_bytes(SRC0_BASE, 8192);
    zero_bytes(DST_BASE, 8192);
    inject_write_ordinal_q = 2;
    launch_command();
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 5000, 1'b0);

    // A held accepted response triggers the mover timeout path; releasing it
    // proves explicit drain rather than response-credit abandonment.
    configure_mover(1);
    zero_bytes(SRC0_BASE, 8192);
    hold_response_q = 1'b1;
    launch_command();
    i = 0;
    while (!pending_q && (i < 100)) begin
      @(negedge clk);
      i = i + 1;
    end
    check(pending_q, "timeout fixture never accepted a response credit");
    repeat (540) @(negedge clk);
    hold_response_q = 1'b0;
    wait_terminal(1'b0, 64'd0, 64'd0, 64'd0, 3000, 1'b0);
    end

    // Both full attention directions execute the RTL F16/F32/FMA reduction
    // schedule.  All-zero raw fixtures have an exact +0 output oracle.
    if ((run_group < 0) || (run_group == 1)) begin
    configure_attention(0);
    zero_bytes(SRC0_BASE, 262144);
    zero_bytes(SRC1_BASE, 8192);
    zero_bytes(DST_BASE, 8192);
    launch_command();
    wait_terminal(1'b1, 64'd1056768, 64'd8192, 64'd2048,
                  5000000, 1'b0);
    check((load_u32(DST_BASE) == 32'd0) &&
          (load_u32(DST_BASE + 64'd8188) == 32'd0),
          "attention KQ full raw zero oracle mismatch");
    end

    if ((run_group < 0) || (run_group == 2)) begin
    configure_attention(1);
    zero_bytes(SRC0_BASE, 262144);
    zero_bytes(SRC1_BASE, 8192);
    zero_bytes(DST_BASE, 8192);
    launch_command();
    wait_terminal(1'b1, 64'd1056768, 64'd8192, 64'd2048,
                  5000000, 1'b0);
    check((load_u32(DST_BASE) == 32'd0) &&
          (load_u32(DST_BASE + 64'd8188) == 32'd0),
          "attention KQV full raw zero oracle mismatch");
    end

    // Full 8x256 SOFT_MAX: zero score and zero mask yield exact 1/256.
    if ((run_group < 0) || (run_group == 3)) begin
    configure_softmax();
    zero_bytes(SRC0_BASE, 8192);
    zero_bytes(SRC1_BASE, 1024);
    zero_bytes(DST_BASE, 8192);
    launch_command();
    wait_terminal(1'b1, 64'd9216, 64'd8192, 64'd2048,
                  1000000, 1'b0);
    check((load_u32(DST_BASE) == 32'h3b80_0000) &&
          (load_u32(DST_BASE + 64'd1020) == 32'h3b80_0000) &&
          (load_u32(DST_BASE + 64'd8188) == 32'h3b80_0000),
          "SOFT_MAX full uniform raw oracle mismatch");

    // Both IMROPE profiles consume four I32 positions.  Rotated zero lanes
    // remain zero and raw-copy lanes preserve NaN/signed-zero payload bits.
    configure_rope(0);
    zero_bytes(SRC0_BASE, 8192);
    zero_bytes(SRC1_BASE, 16);
    zero_bytes(DST_BASE, 8192);
    put_u32(SRC0_BASE + 64'd256, 32'h7fc0_4321);
    put_u32(SRC0_BASE + 64'd8188, 32'h8000_0000);
    launch_command();
    wait_terminal(1'b1, 64'd8208, 64'd8192, 64'd2048,
                  1000000, 1'b0);
    check((load_u32(DST_BASE) == 32'd0) &&
          (load_u32(DST_BASE + 64'd256) == 32'h7fc0_4321) &&
          (load_u32(DST_BASE + 64'd8188) == 32'h8000_0000),
          "IMROPE Q full rotate/raw-copy oracle mismatch");

    configure_rope(1);
    zero_bytes(SRC0_BASE, 2048);
    zero_bytes(SRC1_BASE, 16);
    zero_bytes(DST_BASE, 2048);
    put_u32(SRC0_BASE + 64'd256, 32'h0000_0001);
    put_u32(SRC0_BASE + 64'd2044, 32'hff80_0000);
    launch_command();
    wait_terminal(1'b1, 64'd2064, 64'd2048, 64'd512,
                  500000, 1'b0);
    check((load_u32(DST_BASE) == 32'd0) &&
          (load_u32(DST_BASE + 64'd256) == 32'h0000_0001) &&
          (load_u32(DST_BASE + 64'd2044) == 32'hff80_0000),
          "IMROPE K full rotate/raw-copy oracle mismatch");
    end

    check((macro_command_count == expected_issued_q) &&
          (command_count == expected_issued_q),
          "public command accounting mismatch");
    check((macro_completion_count == expected_completed_q) &&
          (completion_count == expected_completed_q),
          "public success completion accounting mismatch");
    check(npu_required_issued == expected_issued_q &&
          npu_required_completed == expected_completed_q,
          "final REQUIRED accounting mismatch");
    check(!protocol_failure_q, "public GMEM protocol monitor failed");
    case (run_group)
      0: check(successful_profile_terminals_q == 14'h01ff,
               "mover/set group profile bitmap mismatch");
      1: check(successful_profile_terminals_q == 14'h0200,
               "attention profile-0 bitmap mismatch");
      2: check(successful_profile_terminals_q == 14'h0400,
               "attention profile-1 bitmap mismatch");
      3: check(successful_profile_terminals_q == 14'h3800,
               "softmax/RoPE group profile bitmap mismatch");
      default: check(successful_profile_terminals_q == 14'h3fff,
                     "not every exact profile reached a success terminal");
    endcase

    if (failures == 0) begin
      if (run_group < 0)
        $display("[NPU-COPROC-BATCH2][PASS] frozen_nodes=144 exact_profiles=14 mover=7 set_rows=2 attention=2 softmax=1 rope=2 static=8 late=2 timeout_drain=1 identity_backpressure=2 single_outstanding=1 host_float=0");
      else if (run_group == 0)
        $display("[NPU-COPROC-BATCH2][GROUP-PASS] group=0 profile_bitmap=%04x static=8 late=2 timeout_drain=1",
                 successful_profile_terminals_q);
      else
        $display("[NPU-COPROC-BATCH2][GROUP-PASS] group=%0d profile_bitmap=%04x",
                 run_group, successful_profile_terminals_q);
      $fflush();
      $finish;
    end else begin
      $fatal(1, "[NPU-COPROC-BATCH2][FAIL] failures=%0d", failures);
    end
  end

endmodule
