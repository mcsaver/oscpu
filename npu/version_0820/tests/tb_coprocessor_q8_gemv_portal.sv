`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Public macro-descriptor integration proof for the production Q8 GEMV raw
// block portal.  The portal model copies only the 34 bytes at each RTL-issued
// address.  It performs no dequantization, dot product, accumulation, result
// arithmetic, or destination access.
module tb_coprocessor_q8_gemv_portal;

  /* verilator lint_off WIDTHTRUNC */
  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off BLKSEQ */

  localparam integer ROW_LANES = 4;
  localparam integer MAC_LANES = 32;
  localparam integer GMEM_BYTES = 16384;
  localparam integer MAX_WAIT_CYCLES = 200000;
  localparam [31:0] KERNEL_GEMV = 32'h514e0002;
  localparam [31:0] FLAGS_REQUIRED_PROFILE = 32'h00000011;
  localparam [31:0] ABI_ERROR_IOVA = 32'd5;
  localparam [31:0] ABI_ERROR_PROTOCOL = 32'd11;
  localparam [63:0] ACT_WIN = 64'h0000_0000_0000_1000;
  localparam [63:0] ACT_BASE = 64'h0000_0000_0000_1104;
  localparam [63:0] WT_WIN = 64'h0000_0000_0000_1800;
  localparam [63:0] WT_BASE = 64'h0000_0000_0000_1802;
  localparam [63:0] DST_WIN = 64'h0000_0000_0000_2000;
  localparam [63:0] DST_BASE = 64'h0000_0000_0000_2104;
  localparam [63:0] WT_STRIDE = 64'd72;
  localparam [63:0] DST_STRIDE = 64'd4;
  localparam integer ROW_COUNT = 5;
  localparam integer BLOCK_COUNT = 2;

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
  wire gmem_req_ready;
  wire gmem_req_write;
  wire [63:0] gmem_req_addr;
  wire [63:0] gmem_req_wdata;
  wire [7:0] gmem_req_wstrb;
  reg gmem_rsp_valid;
  wire gmem_rsp_ready;
  reg [63:0] gmem_rsp_rdata;
  reg gmem_rsp_error;

  wire q8_portal_req_valid;
  wire q8_portal_req_ready;
  wire [ROW_LANES-1:0] q8_portal_req_mask;
  wire [(ROW_LANES*64)-1:0] q8_portal_req_addr;
  reg q8_portal_rsp_valid;
  wire q8_portal_rsp_ready;
  reg [ROW_LANES-1:0] q8_portal_rsp_mask;
  reg [(ROW_LANES*272)-1:0] q8_portal_rsp_blocks;
  reg q8_portal_rsp_error;
  wire [63:0] q8_portal_request_count;
  wire [63:0] q8_portal_response_count;
  wire [63:0] q8_portal_block_count;
  wire [63:0] q8_portal_byte_count;
  wire q8_portal_outstanding;

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
  wire unused_desc_write_ready;
  wire unused_desc_write_error;
  wire [`NPU_ERROR_W-1:0] unused_desc_write_error_code;
  wire [63:0] unused_host_lmem_rd_data;
  wire unused_host_lmem_rd_oob;
  wire unused_host_lmem_wr_oob;
  wire unused_host_lmem_ready;
  wire [63:0] unused_sync_tag;
  wire unused_sync_tag_valid;
  wire [63:0] unused_tiu_cycles;
  wire [63:0] unused_dma_cycles;
  wire [63:0] unused_dma_bytes;

  TensorNpuCoprocessor #(
    .LMEM_BYTES(512),
    .PID_W(8),
    .OPCLASS_W(8),
    .Q8_GEMV_PORTAL_ENABLE(1),
    .Q8_GEMV_ROW_LANES(ROW_LANES),
    .Q8_GEMV_MAC_LANES(MAC_LANES),
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
    .desc_write_ready_o(unused_desc_write_ready),
    .desc_write_id_i(6'd0),
    .desc_write_word_i(3'd0),
    .desc_write_data_i(64'd0),
    .desc_write_error_o(unused_desc_write_error),
    .desc_write_error_code_o(unused_desc_write_error_code),
    .host_lmem_rd_valid_i(1'b0),
    .host_lmem_rd_addr_i(32'd0),
    .host_lmem_rd_bytes_i(4'd0),
    .host_lmem_rd_data_o(unused_host_lmem_rd_data),
    .host_lmem_rd_oob_o(unused_host_lmem_rd_oob),
    .host_lmem_wr_valid_i(1'b0),
    .host_lmem_wr_addr_i(32'd0),
    .host_lmem_wr_data_i(64'd0),
    .host_lmem_wr_strb_i(8'd0),
    .host_lmem_wr_oob_o(unused_host_lmem_wr_oob),
    .host_lmem_ready_o(unused_host_lmem_ready),
    .gmem_req_valid_o(gmem_req_valid),
    .gmem_req_ready_i(gmem_req_ready),
    .gmem_req_write_o(gmem_req_write),
    .gmem_req_addr_o(gmem_req_addr),
    .gmem_req_wdata_o(gmem_req_wdata),
    .gmem_req_wstrb_o(gmem_req_wstrb),
    .gmem_rsp_valid_i(gmem_rsp_valid),
    .gmem_rsp_ready_o(gmem_rsp_ready),
    .gmem_rsp_rdata_i(gmem_rsp_rdata),
    .gmem_rsp_error_i(gmem_rsp_error),
    .q8_portal_req_valid_o(q8_portal_req_valid),
    .q8_portal_req_ready_i(q8_portal_req_ready),
    .q8_portal_req_mask_o(q8_portal_req_mask),
    .q8_portal_req_addr_o(q8_portal_req_addr),
    .q8_portal_rsp_valid_i(q8_portal_rsp_valid),
    .q8_portal_rsp_ready_o(q8_portal_rsp_ready),
    .q8_portal_rsp_mask_i(q8_portal_rsp_mask),
    .q8_portal_rsp_blocks_i(q8_portal_rsp_blocks),
    .q8_portal_rsp_error_i(q8_portal_rsp_error),
    .q8_portal_request_count_o(q8_portal_request_count),
    .q8_portal_response_count_o(q8_portal_response_count),
    .q8_portal_block_count_o(q8_portal_block_count),
    .q8_portal_byte_count_o(q8_portal_byte_count),
    .q8_portal_outstanding_o(q8_portal_outstanding),
    .f32_alu_portal_req_valid_o(),
    .f32_alu_portal_req_ready_i(1'b0),
    .f32_alu_portal_req_write_o(),
    .f32_alu_portal_req_mask_o(),
    .f32_alu_portal_req_src0_addr_o(),
    .f32_alu_portal_req_src1_addr_o(),
    .f32_alu_portal_req_dst_addr_o(),
    .f32_alu_portal_req_wdata_o(),
    .f32_alu_portal_rsp_valid_i(1'b0),
    .f32_alu_portal_rsp_ready_o(),
    .f32_alu_portal_rsp_mask_i(8'b0),
    .f32_alu_portal_rsp_src0_data_i(256'b0),
    .f32_alu_portal_rsp_src1_data_i(256'b0),
    .f32_alu_portal_rsp_error_i(1'b0),
    .f32_alu_portal_request_groups_o(),
    .f32_alu_portal_response_groups_o(),
    .f32_alu_portal_read_groups_o(),
    .f32_alu_portal_write_groups_o(),
    .f32_alu_portal_input_words_o(),
    .f32_alu_portal_output_words_o(),
    .f32_alu_portal_read_bytes_o(),
    .f32_alu_portal_write_bytes_o(),
    .f32_alu_portal_outstanding_o(),
    .f32_mover_portal_req_valid_o(),
    .f32_mover_portal_req_ready_i(1'b0),
    .f32_mover_portal_req_write_o(),
    .f32_mover_portal_req_mask_o(),
    .f32_mover_portal_req_addr_o(),
    .f32_mover_portal_req_wdata_o(),
    .f32_mover_portal_rsp_valid_i(1'b0),
    .f32_mover_portal_rsp_ready_o(),
    .f32_mover_portal_rsp_mask_i(16'b0),
    .f32_mover_portal_rsp_rdata_i(512'b0),
    .f32_mover_portal_rsp_error_i(1'b0),
    .f32_mover_portal_request_groups_o(),
    .f32_mover_portal_response_groups_o(),
    .f32_mover_portal_read_groups_o(),
    .f32_mover_portal_write_groups_o(),
    .f32_mover_portal_read_words_o(),
    .f32_mover_portal_write_words_o(),
    .f32_mover_portal_read_bytes_o(),
    .f32_mover_portal_write_bytes_o(),
    .f32_mover_portal_outstanding_o(),
    .sync_tag_ack_i(1'b0),
    .sync_tag_o(unused_sync_tag),
    .sync_tag_valid_o(unused_sync_tag_valid),
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

  reg [7:0] gmem [0:GMEM_BYTES-1];
  integer global_cycles;
  integer checks;
  integer accepted_commands;
  integer accepted_completions;
  integer commit_pulses;
  integer raw_reads;
  integer raw_writes;
  integer raw_req_backpressure_cycles;
  integer portal_req_backpressure_cycles;
  integer portal_rsp_backpressure_cycles;

  function automatic [63:0] load64(input [63:0] address);
    begin
      load64 = {gmem[address+7], gmem[address+6],
                gmem[address+5], gmem[address+4],
                gmem[address+3], gmem[address+2],
                gmem[address+1], gmem[address+0]};
    end
  endfunction

  function automatic [31:0] load32(input [63:0] address);
    begin
      load32 = {gmem[address+3], gmem[address+2],
                gmem[address+1], gmem[address+0]};
    end
  endfunction

  function automatic [271:0] load_q8_block(input [63:0] address);
    integer byte_lane;
    begin
      load_q8_block = 272'd0;
      for (byte_lane = 0; byte_lane < 34; byte_lane = byte_lane + 1)
        load_q8_block[(byte_lane*8) +: 8] = gmem[address+byte_lane];
    end
  endfunction

  task automatic store32(input [63:0] address, input [31:0] bits);
    begin
      gmem[address+0] = bits[7:0];
      gmem[address+1] = bits[15:8];
      gmem[address+2] = bits[23:16];
      gmem[address+3] = bits[31:24];
    end
  endtask

  task automatic fail(input string reason);
    begin
      $display("[NPU-COPROCESSOR-Q8-GEMV-PORTAL][FAIL] %s cycle=%0d state=%0d portal_state=%0d",
               reason, global_cycles, dut.state_q,
               dut.gen_q8_gemv_portal.u_q8_gemv_portal_adapter.state_q);
      $display("[NPU-COPROCESSOR-Q8-GEMV-PORTAL][EVIDENCE] completion=%0b err=%0b/%0d class=%0d read=%0d write=%0d mac=%0d rows=%0d portal=%0d/%0d blocks=%0d bytes=%0d out=%0b raw_out=%0b commits=%0d",
               completion_valid, completion_error, completion_error_code,
               completion_macro_error_class,
               completion_macro_gmem_read_bytes,
               completion_macro_gmem_write_bytes,
               completion_macro_q8_mac_count,
               completion_macro_vector_element_count,
               q8_portal_request_count, q8_portal_response_count,
               q8_portal_block_count, q8_portal_byte_count,
               q8_portal_outstanding,
               dut.gemv_adapter_raw_gmem_outstanding_w, commit_pulses);
      $fatal(1);
    end
  endtask

  // Raw GMEM response model.
  reg raw_pending_q;
  reg raw_pending_write_q;
  reg [63:0] raw_pending_addr_q;
  reg [63:0] raw_pending_wdata_q;
  reg [7:0] raw_pending_wstrb_q;
  integer raw_pending_delay_q;
  integer raw_hold_count_q;
  reg raw_payload_hold_q;
  reg raw_held_write_q;
  reg [63:0] raw_held_addr_q;
  reg [63:0] raw_held_wdata_q;
  reg [7:0] raw_held_wstrb_q;
  assign gmem_req_ready = !rst && !raw_pending_q && !gmem_rsp_valid
                        && (raw_hold_count_q >= 2);

  // Portal byte-copy response model.
  reg portal_pending_q;
  reg [ROW_LANES-1:0] portal_pending_mask_q;
  reg [(ROW_LANES*272)-1:0] portal_pending_blocks_q;
  integer portal_pending_delay_q;
  integer portal_hold_count_q;
  integer command_portal_requests_q;
  reg inject_wrong_mask_q;
  reg portal_payload_hold_q;
  reg [ROW_LANES-1:0] portal_held_mask_q;
  reg [(ROW_LANES*64)-1:0] portal_held_addr_q;
  reg portal_rsp_payload_hold_q;
  reg [ROW_LANES-1:0] portal_rsp_held_mask_q;
  reg [(ROW_LANES*272)-1:0] portal_rsp_held_blocks_q;
  assign q8_portal_req_ready = !rst && !portal_pending_q
                             && !q8_portal_rsp_valid
                             && (portal_hold_count_q >= 3);

  integer model_lane;
  integer model_tile;
  integer model_block;
  integer apply_lane;
  reg [ROW_LANES-1:0] expected_mask_r;
  reg [63:0] expected_addr_r;

  always @(posedge clk) begin
    global_cycles <= global_cycles + 1;
    if (rst) begin
      gmem_rsp_valid <= 1'b0;
      gmem_rsp_rdata <= 64'd0;
      gmem_rsp_error <= 1'b0;
      raw_pending_q <= 1'b0;
      raw_pending_write_q <= 1'b0;
      raw_pending_addr_q <= 64'd0;
      raw_pending_wdata_q <= 64'd0;
      raw_pending_wstrb_q <= 8'd0;
      raw_pending_delay_q <= 0;
      raw_hold_count_q <= 0;
      raw_payload_hold_q <= 1'b0;
      q8_portal_rsp_valid <= 1'b0;
      q8_portal_rsp_mask <= {ROW_LANES{1'b0}};
      q8_portal_rsp_blocks <= {(ROW_LANES*272){1'b0}};
      q8_portal_rsp_error <= 1'b0;
      portal_pending_q <= 1'b0;
      portal_pending_mask_q <= {ROW_LANES{1'b0}};
      portal_pending_blocks_q <= {(ROW_LANES*272){1'b0}};
      portal_pending_delay_q <= 0;
      portal_hold_count_q <= 0;
      command_portal_requests_q <= 0;
      portal_payload_hold_q <= 1'b0;
      portal_rsp_payload_hold_q <= 1'b0;
      accepted_commands <= 0;
      accepted_completions <= 0;
      commit_pulses <= 0;
      raw_reads <= 0;
      raw_writes <= 0;
      raw_req_backpressure_cycles <= 0;
      portal_req_backpressure_cycles <= 0;
      portal_rsp_backpressure_cycles <= 0;
    end else begin
      if (macro_cmd_valid && macro_cmd_ready) begin
        accepted_commands <= accepted_commands + 1;
        command_portal_requests_q <= 0;
      end
      if (completion_valid && completion_ready)
        accepted_completions <= accepted_completions + 1;
      if (dut.gemv_adapter_dst_commit_w)
        commit_pulses <= commit_pulses + 1;

      if (gmem_req_valid && !gmem_req_ready) begin
        raw_req_backpressure_cycles <= raw_req_backpressure_cycles + 1;
        if (!raw_payload_hold_q) begin
          raw_payload_hold_q <= 1'b1;
          raw_held_write_q <= gmem_req_write;
          raw_held_addr_q <= gmem_req_addr;
          raw_held_wdata_q <= gmem_req_wdata;
          raw_held_wstrb_q <= gmem_req_wstrb;
        end else if (!gmem_req_valid ||
                     (raw_held_write_q != gmem_req_write) ||
                     (raw_held_addr_q != gmem_req_addr) ||
                     (raw_held_wdata_q != gmem_req_wdata) ||
                     (raw_held_wstrb_q != gmem_req_wstrb)) begin
          fail("raw request changed under backpressure");
        end
      end else if (raw_payload_hold_q) begin
        if (!(gmem_req_valid && gmem_req_ready))
          fail("raw request retracted before handshake");
        raw_payload_hold_q <= 1'b0;
      end

      if (gmem_req_valid && !gmem_req_ready) begin
        if (raw_hold_count_q < 2)
          raw_hold_count_q <= raw_hold_count_q + 1;
      end else if (gmem_req_valid && gmem_req_ready) begin
        raw_hold_count_q <= 0;
      end else begin
        raw_hold_count_q <= 0;
      end

      if (gmem_req_valid && gmem_req_ready) begin
        raw_pending_q <= 1'b1;
        raw_pending_write_q <= gmem_req_write;
        raw_pending_addr_q <= gmem_req_addr;
        raw_pending_wdata_q <= gmem_req_wdata;
        raw_pending_wstrb_q <= gmem_req_wstrb;
        raw_pending_delay_q <= gmem_req_write ? 3 : 2;
        if (gmem_req_write) begin
          if ((gmem_req_addr < DST_WIN) ||
              ((gmem_req_addr + 64'd8) > (DST_WIN + 64'h200)))
            fail("result write escaped private destination");
          if ((gmem_req_wstrb != 8'h0f) &&
              (gmem_req_wstrb != 8'hf0))
            fail("result write strobe is not unaligned4-safe");
          raw_writes <= raw_writes + 1;
        end else begin
          if ((gmem_req_addr < ACT_WIN) ||
              ((gmem_req_addr + 64'd8) > (ACT_WIN + 64'h400)))
            fail("raw GMEM observed a weight read");
          if ((gmem_req_wdata != 64'd0) || (gmem_req_wstrb != 8'd0))
            fail("raw read carried write payload");
          raw_reads <= raw_reads + 1;
        end
      end

      if (raw_pending_q && !gmem_rsp_valid) begin
        if (raw_pending_delay_q > 0) begin
          raw_pending_delay_q <= raw_pending_delay_q - 1;
        end else begin
          raw_pending_q <= 1'b0;
          gmem_rsp_valid <= 1'b1;
          gmem_rsp_rdata <= raw_pending_write_q
                         ? 64'd0 : load64(raw_pending_addr_q);
          gmem_rsp_error <= 1'b0;
        end
      end
      if (gmem_rsp_valid && gmem_rsp_ready) begin
        if (raw_pending_write_q) begin
          for (apply_lane = 0; apply_lane < 8;
               apply_lane = apply_lane + 1) begin
            if (raw_pending_wstrb_q[apply_lane])
              gmem[raw_pending_addr_q+apply_lane]
                  <= raw_pending_wdata_q[(apply_lane*8) +: 8];
          end
        end
        gmem_rsp_valid <= 1'b0;
      end

      if (q8_portal_req_valid && !q8_portal_req_ready) begin
        portal_req_backpressure_cycles <=
            portal_req_backpressure_cycles + 1;
        if (!portal_payload_hold_q) begin
          portal_payload_hold_q <= 1'b1;
          portal_held_mask_q <= q8_portal_req_mask;
          portal_held_addr_q <= q8_portal_req_addr;
        end else if ((portal_held_mask_q != q8_portal_req_mask) ||
                     (portal_held_addr_q != q8_portal_req_addr)) begin
          fail("portal request changed under backpressure");
        end
      end else if (portal_payload_hold_q) begin
        if (!(q8_portal_req_valid && q8_portal_req_ready))
          fail("portal request retracted before handshake");
        portal_payload_hold_q <= 1'b0;
      end

      if (q8_portal_req_valid && !q8_portal_req_ready) begin
        if (portal_hold_count_q < 3)
          portal_hold_count_q <= portal_hold_count_q + 1;
      end else if (q8_portal_req_valid && q8_portal_req_ready) begin
        portal_hold_count_q <= 0;
      end else begin
        portal_hold_count_q <= 0;
      end

      if (q8_portal_req_valid && q8_portal_req_ready) begin
        model_tile = command_portal_requests_q / BLOCK_COUNT;
        model_block = command_portal_requests_q % BLOCK_COUNT;
        expected_mask_r = {ROW_LANES{1'b0}};
        portal_pending_blocks_q <= {(ROW_LANES*272){1'b0}};
        for (model_lane = 0; model_lane < ROW_LANES;
             model_lane = model_lane + 1) begin
          if ((model_tile*ROW_LANES + model_lane) < ROW_COUNT) begin
            expected_mask_r[model_lane] = 1'b1;
            expected_addr_r = WT_BASE
                + (model_tile*ROW_LANES + model_lane)*WT_STRIDE
                + model_block*34;
            if (q8_portal_req_addr[(model_lane*64) +: 64]
                != expected_addr_r) begin
              fail("portal tile/block/lane address order mismatch");
            end
            portal_pending_blocks_q[(model_lane*272) +: 272]
                <= load_q8_block(expected_addr_r);
          end else if (q8_portal_req_addr[(model_lane*64) +: 64]
                       != 64'd0) begin
            fail("inactive portal lane address was not zero");
          end
        end
        if (q8_portal_req_mask != expected_mask_r)
          fail("portal tail mask mismatch");
        portal_pending_q <= 1'b1;
        portal_pending_mask_q <= q8_portal_req_mask;
        portal_pending_delay_q <= 1;
        command_portal_requests_q <= command_portal_requests_q + 1;
      end

      if (portal_pending_q && !q8_portal_rsp_valid) begin
        if (portal_pending_delay_q > 0) begin
          portal_pending_delay_q <= portal_pending_delay_q - 1;
        end else begin
          portal_pending_q <= 1'b0;
          q8_portal_rsp_valid <= 1'b1;
          q8_portal_rsp_mask <= inject_wrong_mask_q
                              ? (portal_pending_mask_q ^ 4'b0010)
                              : portal_pending_mask_q;
          q8_portal_rsp_blocks <= portal_pending_blocks_q;
          q8_portal_rsp_error <= 1'b0;
        end
      end

      if (q8_portal_rsp_valid && !q8_portal_rsp_ready) begin
        portal_rsp_backpressure_cycles <=
            portal_rsp_backpressure_cycles + 1;
        if (!portal_rsp_payload_hold_q) begin
          portal_rsp_payload_hold_q <= 1'b1;
          portal_rsp_held_mask_q <= q8_portal_rsp_mask;
          portal_rsp_held_blocks_q <= q8_portal_rsp_blocks;
        end else if ((portal_rsp_held_mask_q != q8_portal_rsp_mask) ||
                     (portal_rsp_held_blocks_q != q8_portal_rsp_blocks)) begin
          fail("portal response changed under backpressure");
        end
      end else if (portal_rsp_payload_hold_q) begin
        if (!(q8_portal_rsp_valid && q8_portal_rsp_ready))
          fail("portal response retracted before handshake");
        portal_rsp_payload_hold_q <= 1'b0;
      end

      if (q8_portal_rsp_valid && q8_portal_rsp_ready)
        q8_portal_rsp_valid <= 1'b0;
    end
  end

  integer init_index;
  integer init_row;
  integer init_block;
  integer init_lane;
  reg [63:0] init_addr;
  task automatic initialize_fixture;
    begin
      for (init_index = 0; init_index < GMEM_BYTES;
           init_index = init_index + 1)
        gmem[init_index] = 8'ha5;
      for (init_index = 0; init_index < 64;
           init_index = init_index + 1) begin
        case (init_index & 3)
          0: store32(ACT_BASE + init_index*4, 32'h3f800000);
          1: store32(ACT_BASE + init_index*4, 32'hbf800000);
          2: store32(ACT_BASE + init_index*4, 32'h3f000000);
          default: store32(ACT_BASE + init_index*4, 32'hbe800000);
        endcase
      end
      // Nonzero scales and zero q bytes force an exact +0 result while every
      // real RTL quantizer/dot/scale/term/add state still executes.
      for (init_row = 0; init_row < ROW_COUNT; init_row = init_row + 1) begin
        for (init_block = 0; init_block < BLOCK_COUNT;
             init_block = init_block + 1) begin
          init_addr = WT_BASE + init_row*WT_STRIDE + init_block*34;
          gmem[init_addr+0] = 8'h00;
          gmem[init_addr+1] = 8'h3c;
          for (init_lane = 0; init_lane < 32; init_lane = init_lane + 1)
            gmem[init_addr+2+init_lane] = 8'h00;
        end
      end
      for (init_index = 0; init_index < 512;
           init_index = init_index + 1)
        gmem[DST_WIN+init_index] = 8'h5a;
    end
  endtask

  task automatic configure_descriptor(input [63:0] sequence_value);
    begin
      macro_abi_valid = 1'b1;
      macro_kernel_id = KERNEL_GEMV;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_context_id = 32'hcafe_0000 | sequence_value[15:0];
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
      macro_src0_iova = ACT_BASE;
      macro_src1_iova = WT_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = DST_BASE;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd64;
      macro_outer_count = ROW_COUNT;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd0;
      macro_src1_stride = WT_STRIDE;
      macro_src2_stride = 64'd0;
      macro_dst_stride = DST_STRIDE;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = ACT_WIN;
      macro_src0_window_size = 64'h400;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = WT_WIN;
      macro_src1_window_size = 64'h200;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = DST_WIN;
      macro_dst_window_size = 64'h200;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
    end
  endtask

  task automatic configure_empty_descriptor(input [63:0] sequence_value);
    begin
      configure_descriptor(sequence_value);
      // Canonical N=0 keeps the frozen K/stride/profile identity, but every
      // physical window is an exact empty interval rooted at its command IOVA.
      macro_outer_count = 32'd0;
      macro_src0_iova = ACT_WIN;
      macro_src1_iova = WT_WIN;
      macro_dst_iova = DST_WIN;
      macro_src0_window_size = 64'd0;
      macro_src1_window_size = 64'd0;
      macro_dst_window_size = 64'd0;
    end
  endtask

  task automatic poison_descriptor;
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

  reg [63:0] expected_sequence_q;
  reg [31:0] expected_context_q;
  reg [63:0] expected_producer_q;
  reg [63:0] expected_user_q;
  reg [63:0] expected_hash_lo_q;
  reg [63:0] expected_hash_hi_q;
  task automatic execute_command(
      input bit expect_error,
      input [`NPU_ERROR_W-1:0] expected_error_code,
      input [31:0] expected_error_class,
      input [63:0] expected_read_bytes,
      input [63:0] expected_write_bytes,
      input [63:0] expected_q8_mac_count,
      input [63:0] expected_vector_element_count);
    integer waited;
    integer held_cycle;
    reg [63:0] held_npu_cycles;
    begin
      expected_sequence_q = macro_sequence_id;
      expected_context_q = macro_context_id;
      expected_producer_q = macro_producer_id;
      expected_user_q = macro_user_tag;
      expected_hash_lo_q = macro_node_hash_lo;
      expected_hash_hi_q = macro_node_hash_hi;
      while (!macro_cmd_ready) @(negedge clk);
      macro_cmd_valid = 1'b1;
      @(posedge clk);
      @(negedge clk);
      macro_cmd_valid = 1'b0;
      poison_descriptor();

      waited = 0;
      while (!completion_valid && (waited < MAX_WAIT_CYCLES)) begin
        @(negedge clk);
        waited = waited + 1;
      end
      if (!completion_valid)
        fail("timed out waiting for public completion");
      checks = checks + 1;
      if (!completion_is_macro ||
          (completion_producer_id != 8'd0) ||
          !completion_npu_required ||
          (completion_opclass != 8'd0) ||
          (completion_error != expect_error) ||
          (completion_error_code != expected_error_code) ||
          (completion_macro_status != {24'd0, expected_error_code}) ||
          (completion_macro_error_class != expected_error_class) ||
          (completion_macro_kernel_id != KERNEL_GEMV) ||
          (completion_macro_command_flags != FLAGS_REQUIRED_PROFILE) ||
          (completion_macro_vector_flags != 32'd0) ||
          (completion_macro_context_id != expected_context_q) ||
          (completion_macro_sequence_id != expected_sequence_q) ||
          (completion_macro_producer_id != expected_producer_q) ||
          (completion_macro_user_tag != expected_user_q) ||
          (completion_macro_covered_node_count != 32'd1) ||
          (completion_macro_node_hash_lo != expected_hash_lo_q) ||
          (completion_macro_node_hash_hi != expected_hash_hi_q) ||
          (completion_macro_gmem_read_bytes != expected_read_bytes) ||
          (completion_macro_gmem_write_bytes != expected_write_bytes) ||
          (completion_macro_q8_mac_count != expected_q8_mac_count) ||
          (completion_macro_vector_element_count !=
              expected_vector_element_count) ||
          (completion_macro_state_update_count != 64'd0) ||
          (completion_macro_npu_cycles == 64'd0)) begin
        fail("public completion identity/ledger mismatch");
      end
      if (q8_portal_outstanding ||
          dut.gemv_adapter_raw_gmem_outstanding_w ||
          dut.gemv_adapter_gmem_outstanding_w)
        fail("terminal exposed with raw|portal outstanding");
      held_npu_cycles = completion_macro_npu_cycles;
      for (held_cycle = 0; held_cycle < 2;
           held_cycle = held_cycle + 1) begin
        @(posedge clk);
        @(negedge clk);
        if (!completion_valid ||
            (completion_macro_sequence_id != expected_sequence_q) ||
            (completion_macro_npu_cycles != held_npu_cycles))
          fail("completion changed under backpressure");
      end
      completion_ready = 1'b1;
      @(posedge clk);
      @(negedge clk);
      completion_ready = 1'b0;
      if (completion_valid)
        fail("completion failed to retire");
    end
  endtask

  task automatic clear_error_hold;
    begin
      if (!sticky_error || macro_cmd_ready)
        fail("mapped macro error did not enter fail-closed hold");
      error_clear = 1'b1;
      @(posedge clk);
      @(negedge clk);
      error_clear = 1'b0;
      if (sticky_error || !macro_cmd_ready)
        fail("error_clear did not reopen macro admission");
    end
  endtask

  integer result_row;
  integer before_raw_reads;
  integer before_raw_writes;
  integer before_commits;
  integer before_raw_req_backpressure_cycles;
  integer before_portal_req_backpressure_cycles;
  integer before_portal_rsp_backpressure_cycles;
  reg [63:0] before_portal_requests;
  reg [63:0] before_portal_responses;
  reg [63:0] before_portal_blocks;
  reg [63:0] before_portal_bytes;
  initial begin
    global_cycles = 0;
    checks = 0;
    rst = 1'b1;
    macro_cmd_valid = 1'b0;
    completion_ready = 1'b0;
    error_clear = 1'b0;
    inject_wrong_mask_q = 1'b0;
    initialize_fixture();
    poison_descriptor();
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);

    // Positive M=5/B=2 includes one full ROW4 tile and one lane-0 tail tile.
    configure_descriptor(64'h4455_6677_8800_0001);
    before_raw_reads = raw_reads;
    before_raw_writes = raw_writes;
    before_commits = commit_pulses;
    execute_command(1'b0, `NPU_ERR_NONE, 32'd0,
                    64'd264, 64'd20, 64'd320, 64'd5);
    checks = checks + 1;
    if ((raw_reads - before_raw_reads != 33) ||
        (raw_writes - before_raw_writes != 5) ||
        (q8_portal_request_count != 64'd4) ||
        (q8_portal_response_count != 64'd4) ||
        (q8_portal_block_count != 64'd10) ||
        (q8_portal_byte_count != 64'd340) ||
        (dut.gemv_adapter_raw_gmem_read_bytes_w != 64'd264) ||
        (dut.gemv_adapter_gmem_read_bytes_w != 64'd264) ||
        (dut.gemv_adapter_gmem_read_beats_w != 64'd33) ||
        (dut.gemv_adapter_gmem_read_beats_completed_w != 64'd33) ||
        (commit_pulses - before_commits != 1) ||
        (raw_req_backpressure_cycles == 0) ||
        (portal_req_backpressure_cycles == 0) ||
        (portal_rsp_backpressure_cycles == 0))
      fail("positive raw/portal ledger or commit mismatch");
    for (result_row = 0; result_row < ROW_COUNT;
         result_row = result_row + 1) begin
      if (load32(DST_BASE + result_row*DST_STRIDE) !== 32'h00000000)
        fail("M5/B2 destination raw bits are not exact +0");
    end

    // Wrong mask is consumed by the portal adapter, mapped by Coprocessor to
    // the real public MACRO_PROTOCOL terminal, and never publishes dst.
    for (result_row = 0; result_row < ROW_COUNT;
         result_row = result_row + 1)
      store32(DST_BASE + result_row*DST_STRIDE, 32'h5a5a5a5a);
    configure_descriptor(64'h4455_6677_8800_0002);
    inject_wrong_mask_q = 1'b1;
    before_raw_reads = raw_reads;
    before_raw_writes = raw_writes;
    before_commits = commit_pulses;
    execute_command(1'b1, `NPU_ERR_MACRO_PROTOCOL, ABI_ERROR_PROTOCOL,
                    64'd264, 64'd0, 64'd0, 64'd0);
    checks = checks + 1;
    if ((raw_reads - before_raw_reads != 33) ||
        (raw_writes - before_raw_writes != 0) ||
        (q8_portal_request_count != 64'd1) ||
        (q8_portal_response_count != 64'd1) ||
        (q8_portal_block_count != 64'd0) ||
        (q8_portal_byte_count != 64'd0) ||
        (commit_pulses != before_commits) ||
        (sticky_error_code != `NPU_ERR_MACRO_PROTOCOL))
      fail("wrong-mask mapping/atomic publication mismatch");
    for (result_row = 0; result_row < ROW_COUNT;
         result_row = result_row + 1) begin
      if (load32(DST_BASE + result_row*DST_STRIDE) !== 32'h5a5a5a5a)
        fail("wrong-mask error changed private destination");
    end
    clear_error_hold();

    // A canonical terminal N=0 descriptor is still accepted as a required
    // command with full identity, but completes in Coprocessor ownership
    // without starting the functional child, portal adapter, or raw GMEM.
    inject_wrong_mask_q = 1'b0;
    configure_empty_descriptor(64'h4455_6677_8800_0003);
    before_raw_reads = raw_reads;
    before_raw_writes = raw_writes;
    before_commits = commit_pulses;
    before_portal_requests = q8_portal_request_count;
    before_portal_responses = q8_portal_response_count;
    before_portal_blocks = q8_portal_block_count;
    before_portal_bytes = q8_portal_byte_count;
    before_raw_req_backpressure_cycles = raw_req_backpressure_cycles;
    before_portal_req_backpressure_cycles =
        portal_req_backpressure_cycles;
    before_portal_rsp_backpressure_cycles =
        portal_rsp_backpressure_cycles;
    execute_command(1'b0, `NPU_ERR_NONE, 32'd0,
                    64'd0, 64'd0, 64'd0, 64'd0);
    checks = checks + 1;
    if ((raw_reads != before_raw_reads) ||
        (raw_writes != before_raw_writes) ||
        (commit_pulses != before_commits) ||
        (q8_portal_request_count != before_portal_requests) ||
        (q8_portal_response_count != before_portal_responses) ||
        (q8_portal_block_count != before_portal_blocks) ||
        (q8_portal_byte_count != before_portal_bytes) ||
        (raw_req_backpressure_cycles !=
            before_raw_req_backpressure_cycles) ||
        (portal_req_backpressure_cycles !=
            before_portal_req_backpressure_cycles) ||
        (portal_rsp_backpressure_cycles !=
            before_portal_rsp_backpressure_cycles) ||
        q8_portal_outstanding ||
        dut.gemv_adapter_raw_gmem_outstanding_w ||
        dut.gemv_adapter_gmem_outstanding_w)
      fail("canonical empty descriptor produced physical traffic");

    // An almost-empty descriptor is not a broader zero-size capability.  A
    // nonzero destination window must fail closed as MACRO_IOVA before either
    // child starts, with the same strict zero-traffic proof.
    configure_empty_descriptor(64'h4455_6677_8800_0004);
    macro_dst_window_size = 64'd8;
    before_raw_reads = raw_reads;
    before_raw_writes = raw_writes;
    before_commits = commit_pulses;
    before_portal_requests = q8_portal_request_count;
    before_portal_responses = q8_portal_response_count;
    before_portal_blocks = q8_portal_block_count;
    before_portal_bytes = q8_portal_byte_count;
    before_raw_req_backpressure_cycles = raw_req_backpressure_cycles;
    before_portal_req_backpressure_cycles =
        portal_req_backpressure_cycles;
    before_portal_rsp_backpressure_cycles =
        portal_rsp_backpressure_cycles;
    execute_command(1'b1, `NPU_ERR_MACRO_IOVA, ABI_ERROR_IOVA,
                    64'd0, 64'd0, 64'd0, 64'd0);
    checks = checks + 1;
    if ((raw_reads != before_raw_reads) ||
        (raw_writes != before_raw_writes) ||
        (commit_pulses != before_commits) ||
        (q8_portal_request_count != before_portal_requests) ||
        (q8_portal_response_count != before_portal_responses) ||
        (q8_portal_block_count != before_portal_blocks) ||
        (q8_portal_byte_count != before_portal_bytes) ||
        (raw_req_backpressure_cycles !=
            before_raw_req_backpressure_cycles) ||
        (portal_req_backpressure_cycles !=
            before_portal_req_backpressure_cycles) ||
        (portal_rsp_backpressure_cycles !=
            before_portal_rsp_backpressure_cycles) ||
        q8_portal_outstanding ||
        dut.gemv_adapter_raw_gmem_outstanding_w ||
        dut.gemv_adapter_gmem_outstanding_w ||
        (sticky_error_code != `NPU_ERR_MACRO_IOVA))
      fail("malformed empty descriptor did not fail before traffic");
    clear_error_hold();

    checks = checks + 1;
    if ((accepted_commands != 4) || (accepted_completions != 4) ||
        (command_count != 64'd4) || (completion_count != 64'd2) ||
        (error_count != 64'd2) || (npu_required_issued != 64'd4) ||
        (npu_required_completed != 64'd2) ||
        (macro_command_count != 64'd4) ||
        (macro_completion_count != 64'd2) ||
        (macro_f32_start_count != 64'd0) || sticky_error || busy)
      fail("aggregate success/error counters did not close");

    $display("[NPU-COPROCESSOR-Q8-GEMV-PORTAL][INFO] positive=M5/B2/tail raw=33/33/264B portal=4/4/10/340B split_ledger=1 writes=5/5/20B q8_macs=320 rows=5 bit_exact=+0 commit=1 wrong_mask=MACRO_PROTOCOL/commit0 empty=N0/K64/SUCCESS/read0/write0/mac0/elements0/commit0 malformed_empty=MACRO_IOVA/traffic0 raw_or_portal_outstanding=0 checks=%0d",
             checks);
    $display("[NPU-COPROCESSOR-Q8-GEMV-PORTAL][PASS] portal=1 row_lanes=4 mac_lanes=32 scenarios=4 empty_zero_work=1 malformed_empty_reject=1 assertions=off waveform=off");
    $finish;
  end

  /* verilator lint_on BLKSEQ */
  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */

endmodule

`default_nettype wire
