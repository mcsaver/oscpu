`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Public macro-descriptor integration proof for the production raw32 mover
// portal.  The portal model below performs only four-byte memcpy operations at
// addresses emitted by RTL.  All gather-index decode, tensor coordinates, and
// repeat/broadcast address generation remain inside the coprocessor.
module tb_coprocessor_f32_gather_repeat_portal;

  /* verilator lint_off WIDTHTRUNC */
  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off BLKSEQ */

  localparam integer LANES = 16;
  localparam integer MEM_BYTES = 1310720;
  localparam integer MAX_WAIT_CYCLES = 500000;

  localparam [31:0] KERNEL_GET_ROWS = 32'h514e0003;
  localparam [31:0] KERNEL_REPEAT   = 32'h514e0004;
  localparam [31:0] FLAGS_REQUIRED_PROFILE = 32'h00000011;
  localparam [31:0] ABI_ERROR_GMEM = 32'd6;

  // Exact P06 non-empty manifest profile: D=1024, N=1, V=1.
  localparam integer GET_D = 1024;
  localparam [63:0] GET_SRC_WIN = 64'h0000_0000_0000_1000;
  localparam [63:0] GET_SRC = 64'h0000_0000_0000_1004;
  localparam [63:0] GET_IDX_WIN = 64'h0000_0000_0000_3000;
  localparam [63:0] GET_IDX = 64'h0000_0000_0000_3004;
  localparam [63:0] GET_DST_WIN = 64'h0000_0000_0000_4000;
  localparam [63:0] GET_DST = 64'h0000_0000_0000_4004;

  // Exact P12 manifest profile: [D=128,O=16] repeated R=128.
  localparam integer REP_D = 128;
  localparam integer REP_OUTER = 16;
  localparam integer REP_COUNT = 128;
  localparam [63:0] REP_SRC_WIN = 64'h0000_0000_0001_0000;
  localparam [63:0] REP_SRC = 64'h0000_0000_0001_0004;
  localparam [63:0] REP_DST_WIN = 64'h0000_0000_0002_0000;
  localparam [63:0] REP_DST = 64'h0000_0000_0002_0004;

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
  wire gmem_req_write;
  wire [63:0] gmem_req_addr;
  wire [63:0] gmem_req_wdata;
  wire [7:0] gmem_req_wstrb;
  wire gmem_rsp_ready;

  wire portal_req_valid;
  wire portal_req_ready;
  wire portal_req_write;
  wire [LANES-1:0] portal_req_mask;
  wire [(LANES*64)-1:0] portal_req_addr;
  wire [(LANES*32)-1:0] portal_req_wdata;
  reg portal_rsp_valid;
  wire portal_rsp_ready;
  reg [LANES-1:0] portal_rsp_mask;
  reg [(LANES*32)-1:0] portal_rsp_rdata;
  reg portal_rsp_error;
  wire [63:0] portal_request_groups;
  wire [63:0] portal_response_groups;
  wire [63:0] portal_read_groups;
  wire [63:0] portal_write_groups;
  wire [63:0] portal_read_words;
  wire [63:0] portal_write_words;
  wire [63:0] portal_read_bytes;
  wire [63:0] portal_write_bytes;
  wire portal_outstanding;

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
    .F32_MOVER_PORTAL_ENABLE(1),
    .F32_MOVER_PORTAL_LANES(LANES),
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
    .gmem_req_ready_i(1'b1),
    .gmem_req_write_o(gmem_req_write),
    .gmem_req_addr_o(gmem_req_addr),
    .gmem_req_wdata_o(gmem_req_wdata),
    .gmem_req_wstrb_o(gmem_req_wstrb),
    .gmem_rsp_valid_i(1'b0),
    .gmem_rsp_ready_o(gmem_rsp_ready),
    .gmem_rsp_rdata_i(64'd0),
    .gmem_rsp_error_i(1'b0),
    .q8_portal_req_valid_o(),
    .q8_portal_req_ready_i(1'b1),
    .q8_portal_req_mask_o(),
    .q8_portal_req_addr_o(),
    .q8_portal_rsp_valid_i(1'b0),
    .q8_portal_rsp_ready_o(),
    .q8_portal_rsp_mask_i(4'b0),
    .q8_portal_rsp_blocks_i(1088'b0),
    .q8_portal_rsp_error_i(1'b0),
    .q8_portal_request_count_o(),
    .q8_portal_response_count_o(),
    .q8_portal_block_count_o(),
    .q8_portal_byte_count_o(),
    .q8_portal_outstanding_o(),
    .f32_alu_portal_req_valid_o(),
    .f32_alu_portal_req_ready_i(1'b1),
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
    .f32_mover_portal_req_valid_o(portal_req_valid),
    .f32_mover_portal_req_ready_i(portal_req_ready),
    .f32_mover_portal_req_write_o(portal_req_write),
    .f32_mover_portal_req_mask_o(portal_req_mask),
    .f32_mover_portal_req_addr_o(portal_req_addr),
    .f32_mover_portal_req_wdata_o(portal_req_wdata),
    .f32_mover_portal_rsp_valid_i(portal_rsp_valid),
    .f32_mover_portal_rsp_ready_o(portal_rsp_ready),
    .f32_mover_portal_rsp_mask_i(portal_rsp_mask),
    .f32_mover_portal_rsp_rdata_i(portal_rsp_rdata),
    .f32_mover_portal_rsp_error_i(portal_rsp_error),
    .f32_mover_portal_request_groups_o(portal_request_groups),
    .f32_mover_portal_response_groups_o(portal_response_groups),
    .f32_mover_portal_read_groups_o(portal_read_groups),
    .f32_mover_portal_write_groups_o(portal_write_groups),
    .f32_mover_portal_read_words_o(portal_read_words),
    .f32_mover_portal_write_words_o(portal_write_words),
    .f32_mover_portal_read_bytes_o(portal_read_bytes),
    .f32_mover_portal_write_bytes_o(portal_write_bytes),
    .f32_mover_portal_outstanding_o(portal_outstanding),
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

  reg [7:0] memory [0:MEM_BYTES-1];
  integer global_cycles;
  integer checks;
  integer accepted_commands;
  integer accepted_completions;
  integer accepted_requests;
  integer accepted_responses;
  integer accepted_read_groups;
  integer accepted_write_groups;
  integer accepted_read_words;
  integer accepted_write_words;
  integer request_backpressure_cycles;
  integer response_latency_cycles;
  integer completion_backpressure_cycles;
  integer commit_pulses;
  reg [63:0] guard_src0_base_q;
  reg [63:0] guard_src0_size_q;
  reg [63:0] guard_src1_base_q;
  reg [63:0] guard_src1_size_q;
  reg [63:0] guard_dst_base_q;
  reg [63:0] guard_dst_size_q;

  function automatic [31:0] load32(input [63:0] address);
    begin
      load32 = {memory[address+3], memory[address+2],
                memory[address+1], memory[address+0]};
    end
  endfunction

  task automatic store32(input [63:0] address, input [31:0] bits);
    begin
      memory[address+0] = bits[7:0];
      memory[address+1] = bits[15:8];
      memory[address+2] = bits[23:16];
      memory[address+3] = bits[31:24];
    end
  endtask

  function automatic [31:0] get_pattern(input integer element);
    begin
      get_pattern = 32'h3f80_0000 ^ (element * 32'h0001_0101);
    end
  endfunction

  function automatic [31:0] repeat_pattern(
      input integer outer_index,
      input integer element
  );
    begin
      repeat_pattern = 32'h8000_0001 ^
                       (outer_index * 32'h0100_0011) ^
                       (element * 32'h0001_0101);
    end
  endfunction

  task automatic fail(input string reason);
    begin
      $display("[NPU-COPROCESSOR-F32-MOVER-PORTAL][FAIL] %s cycle=%0d state=%0d mover_state=%0d",
               reason, global_cycles, dut.state_q,
               dut.gen_f32_mover_portal
                  .u_f32_gather_repeat_portal_adapter.state_q);
      $display("[NPU-COPROCESSOR-F32-MOVER-PORTAL][EVIDENCE] completion=%0b err=%0b/%0d class=%0d gmem=%0d/%0d vector=%0d portal req/rsp=%0d/%0d groups r/w=%0d/%0d words r/w=%0d/%0d bytes r/w=%0d/%0d out=%0b raw_out=%0b commits=%0d",
               completion_valid, completion_error, completion_error_code,
               completion_macro_error_class,
               completion_macro_gmem_read_bytes,
               completion_macro_gmem_write_bytes,
               completion_macro_vector_element_count,
               portal_request_groups, portal_response_groups,
               portal_read_groups, portal_write_groups,
               portal_read_words, portal_write_words,
               portal_read_bytes, portal_write_bytes,
               portal_outstanding,
               dut.f32_move_adapter_gmem_outstanding_w, commit_pulses);
      $fatal(1);
    end
  endtask

  // One-outstanding raw32 memcpy portal.  The host never derives a tensor
  // coordinate; it copies only each active lane at the address supplied by
  // RTL, and acknowledges the exact resident mask.
  reg portal_pending_q;
  reg portal_pending_write_q;
  reg [LANES-1:0] portal_pending_mask_q;
  reg [(LANES*64)-1:0] portal_pending_addr_q;
  reg [(LANES*32)-1:0] portal_pending_wdata_q;
  reg [(LANES*32)-1:0] portal_pending_rdata_q;
  reg portal_pending_wrong_mask_q;
  integer portal_pending_delay_q;
  integer portal_hold_count_q;
  integer command_request_ordinal_q;
  reg inject_wrong_mask_q;

  reg req_payload_hold_q;
  reg req_held_write_q;
  reg [LANES-1:0] req_held_mask_q;
  reg [(LANES*64)-1:0] req_held_addr_q;
  reg [(LANES*32)-1:0] req_held_wdata_q;
  reg rsp_payload_hold_q;
  reg [LANES-1:0] rsp_held_mask_q;
  reg [(LANES*32)-1:0] rsp_held_rdata_q;
  reg rsp_held_error_q;

  reg [(LANES*32)-1:0] model_rdata_r;
  integer model_lane;
  integer model_words;
  integer apply_lane;
  reg [63:0] model_addr_r;

  assign portal_req_ready = !rst && !portal_pending_q &&
                            !portal_rsp_valid &&
                            (portal_hold_count_q >= 2);

  always @(posedge clk) begin
    global_cycles <= global_cycles + 1;
    if (rst) begin
      portal_rsp_valid <= 1'b0;
      portal_rsp_mask <= {LANES{1'b0}};
      portal_rsp_rdata <= {(LANES*32){1'b0}};
      portal_rsp_error <= 1'b0;
      portal_pending_q <= 1'b0;
      portal_pending_write_q <= 1'b0;
      portal_pending_mask_q <= {LANES{1'b0}};
      portal_pending_addr_q <= {(LANES*64){1'b0}};
      portal_pending_wdata_q <= {(LANES*32){1'b0}};
      portal_pending_rdata_q <= {(LANES*32){1'b0}};
      portal_pending_wrong_mask_q <= 1'b0;
      portal_pending_delay_q <= 0;
      portal_hold_count_q <= 0;
      command_request_ordinal_q <= 0;
      req_payload_hold_q <= 1'b0;
      rsp_payload_hold_q <= 1'b0;
      accepted_commands <= 0;
      accepted_completions <= 0;
      accepted_requests <= 0;
      accepted_responses <= 0;
      accepted_read_groups <= 0;
      accepted_write_groups <= 0;
      accepted_read_words <= 0;
      accepted_write_words <= 0;
      request_backpressure_cycles <= 0;
      response_latency_cycles <= 0;
      completion_backpressure_cycles <= 0;
      commit_pulses <= 0;
      guard_src0_base_q <= 64'd0;
      guard_src0_size_q <= 64'd0;
      guard_src1_base_q <= 64'd0;
      guard_src1_size_q <= 64'd0;
      guard_dst_base_q <= 64'd0;
      guard_dst_size_q <= 64'd0;
    end else begin
      if (macro_cmd_valid && macro_cmd_ready) begin
        accepted_commands <= accepted_commands + 1;
        command_request_ordinal_q <= 0;
        guard_src0_base_q <= macro_src0_window_base;
        guard_src0_size_q <= macro_src0_window_size;
        guard_src1_base_q <= macro_src1_window_base;
        guard_src1_size_q <= macro_src1_window_size;
        guard_dst_base_q <= macro_dst_window_base;
        guard_dst_size_q <= macro_dst_window_size;
      end
      if (completion_valid && completion_ready)
        accepted_completions <= accepted_completions + 1;
      if (completion_valid && !completion_ready)
        completion_backpressure_cycles <=
            completion_backpressure_cycles + 1;
      if (dut.f32_move_adapter_dst_commit_w)
        commit_pulses <= commit_pulses + 1;

      if (gmem_req_valid)
        fail("raw GMEM request observed in mover portal mode");

      if (portal_req_valid && !portal_req_ready) begin
        request_backpressure_cycles <= request_backpressure_cycles + 1;
        if (!req_payload_hold_q) begin
          req_payload_hold_q <= 1'b1;
          req_held_write_q <= portal_req_write;
          req_held_mask_q <= portal_req_mask;
          req_held_addr_q <= portal_req_addr;
          req_held_wdata_q <= portal_req_wdata;
        end else if ((req_held_write_q != portal_req_write) ||
                     (req_held_mask_q != portal_req_mask) ||
                     (req_held_addr_q != portal_req_addr) ||
                     (req_held_wdata_q != portal_req_wdata)) begin
          fail("portal request payload changed under backpressure");
        end
      end else if (req_payload_hold_q) begin
        if (!(portal_req_valid && portal_req_ready))
          fail("portal request retracted before handshake");
        req_payload_hold_q <= 1'b0;
      end

      if (portal_req_valid && !portal_req_ready) begin
        if (portal_hold_count_q < 2)
          portal_hold_count_q <= portal_hold_count_q + 1;
      end else if (portal_req_valid && portal_req_ready) begin
        portal_hold_count_q <= 0;
      end else begin
        portal_hold_count_q <= 0;
      end

      if (portal_req_valid && portal_req_ready) begin
        if (portal_pending_q || portal_rsp_valid)
          fail("portal accepted more than one outstanding group");
        if (portal_req_mask == {LANES{1'b0}})
          fail("portal accepted an empty group");

        model_rdata_r = {(LANES*32){1'b0}};
        model_words = 0;
        for (model_lane = 0; model_lane < LANES;
             model_lane = model_lane + 1) begin
          model_addr_r = portal_req_addr[(model_lane*64) +: 64];
          if (portal_req_mask[model_lane]) begin
            model_words = model_words + 1;
            if ((model_addr_r[1:0] != 2'b00) ||
                ((model_addr_r + 64'd4) > MEM_BYTES))
              fail("active portal lane address is invalid");
            if (portal_req_write) begin
              if (!((model_addr_r >= guard_dst_base_q) &&
                    ((model_addr_r + 64'd4) <=
                     (guard_dst_base_q + guard_dst_size_q))))
                fail("portal write escaped resident destination capability");
            end else begin
              if (!(((model_addr_r >= guard_src0_base_q) &&
                    ((model_addr_r + 64'd4) <=
                      (guard_src0_base_q + guard_src0_size_q))) ||
                    ((guard_src1_size_q != 64'd0) &&
                     (model_addr_r >= guard_src1_base_q) &&
                    ((model_addr_r + 64'd4) <=
                      (guard_src1_base_q + guard_src1_size_q)))))
                fail("portal read escaped resident source capability");
              if (portal_req_wdata[(model_lane*32) +: 32] != 32'd0) begin
                fail("portal read carried write data");
              end
              model_rdata_r[(model_lane*32) +: 32]
                  = load32(model_addr_r);
            end
          end else begin
            if (model_addr_r != 64'd0)
              fail("inactive portal lane address was not zero");
            if (portal_req_wdata[(model_lane*32) +: 32] != 32'd0)
              fail("inactive portal lane write data was not zero");
          end
        end

        portal_pending_q <= 1'b1;
        portal_pending_write_q <= portal_req_write;
        portal_pending_mask_q <= portal_req_mask;
        portal_pending_addr_q <= portal_req_addr;
        portal_pending_wdata_q <= portal_req_wdata;
        portal_pending_rdata_q <= model_rdata_r;
        portal_pending_wrong_mask_q <= inject_wrong_mask_q &&
                                       (command_request_ordinal_q == 0);
        portal_pending_delay_q <= 1 + (command_request_ordinal_q & 1);
        command_request_ordinal_q <= command_request_ordinal_q + 1;
        accepted_requests <= accepted_requests + 1;
        if (portal_req_write) begin
          accepted_write_groups <= accepted_write_groups + 1;
          accepted_write_words <= accepted_write_words + model_words;
        end else begin
          accepted_read_groups <= accepted_read_groups + 1;
          accepted_read_words <= accepted_read_words + model_words;
        end
      end

      if (portal_pending_q && !portal_rsp_valid) begin
        response_latency_cycles <= response_latency_cycles + 1;
        if (portal_pending_delay_q > 0) begin
          portal_pending_delay_q <= portal_pending_delay_q - 1;
        end else begin
          portal_pending_q <= 1'b0;
          portal_rsp_valid <= 1'b1;
          portal_rsp_mask <= portal_pending_wrong_mask_q
                           ? (portal_pending_mask_q ^ {{(LANES-1){1'b0}},
                                                       1'b1})
                           : portal_pending_mask_q;
          portal_rsp_rdata <= portal_pending_rdata_q;
          portal_rsp_error <= 1'b0;
        end
      end

      if (portal_rsp_valid && !portal_rsp_ready) begin
        if (!rsp_payload_hold_q) begin
          rsp_payload_hold_q <= 1'b1;
          rsp_held_mask_q <= portal_rsp_mask;
          rsp_held_rdata_q <= portal_rsp_rdata;
          rsp_held_error_q <= portal_rsp_error;
        end else if ((rsp_held_mask_q != portal_rsp_mask) ||
                     (rsp_held_rdata_q != portal_rsp_rdata) ||
                     (rsp_held_error_q != portal_rsp_error)) begin
          fail("portal response payload changed while waiting");
        end
      end else if (rsp_payload_hold_q) begin
        if (!(portal_rsp_valid && portal_rsp_ready))
          fail("portal response retracted before handshake");
        rsp_payload_hold_q <= 1'b0;
      end

      if (portal_rsp_valid && portal_rsp_ready) begin
        accepted_responses <= accepted_responses + 1;
        if (portal_pending_write_q && !portal_rsp_error &&
            (portal_rsp_mask == portal_pending_mask_q)) begin
          for (apply_lane = 0; apply_lane < LANES;
               apply_lane = apply_lane + 1) begin
            if (portal_pending_mask_q[apply_lane])
              store32(portal_pending_addr_q[(apply_lane*64) +: 64],
                      portal_pending_wdata_q[(apply_lane*32) +: 32]);
          end
        end
        portal_rsp_valid <= 1'b0;
      end
    end
  end

  task automatic configure_identity(input [63:0] sequence_value);
    begin
      macro_abi_valid = 1'b1;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_context_id = 32'hf32f_0000 | sequence_value[15:0];
      macro_capability_epoch = 32'h00000001;
      macro_sequence_id = sequence_value;
      macro_producer_id = 64'h1020_3040_0000_0000 |
                          {32'd0, sequence_value[31:0]};
      macro_user_tag = 64'h5060_7080_0000_0000 |
                       {32'd0, sequence_value[31:0]};
      macro_node_count = 32'd1;
      macro_node_hash_lo = 64'h8899_aabb_0000_0000 |
                           {32'd0, sequence_value[31:0]};
      macro_node_hash_hi = 64'hccdd_eeff_0000_0000 |
                           {32'd0, sequence_value[31:0]};
      macro_deadline_cycles = 64'd0;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src2_iova = 64'd0;
      macro_scratch_iova = 64'd0;
      macro_dtype = 32'd1;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_windows_generation_valid = 1'b1;
    end
  endtask

  task automatic configure_get(input [63:0] sequence_value);
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_GET_ROWS;
      macro_src0_iova = GET_SRC;
      macro_src1_iova = GET_IDX;
      macro_dst_iova = GET_DST;
      macro_element_count = GET_D;
      macro_outer_count = 32'd1;
      macro_src0_stride = 64'd4096;
      macro_src1_stride = 64'd4;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd4096;
      macro_scalar0 = 32'd1;
      macro_src0_window_base = GET_SRC_WIN;
      macro_src0_window_size = 64'd4104;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = GET_IDX_WIN;
      macro_src1_window_size = 64'd8;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = GET_DST_WIN;
      macro_dst_window_size = 64'd4104;
      macro_dst_window_perm = 2'b10;
    end
  endtask

  task automatic configure_repeat(input [63:0] sequence_value);
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_REPEAT;
      macro_src0_iova = REP_SRC;
      macro_src1_iova = 64'd0;
      macro_dst_iova = REP_DST;
      macro_element_count = 64'd128;
      macro_outer_count = 32'd16;
      macro_src0_stride = 64'd512;
      macro_src1_stride = 64'd0;
      macro_src2_stride = 64'd65536;
      macro_dst_stride = 64'd512;
      macro_scalar0 = 32'd128;
      macro_src0_window_base = REP_SRC_WIN;
      macro_src0_window_size = 64'd8200;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = 64'd0;
      macro_src1_window_size = 64'd0;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = REP_DST_WIN;
      macro_dst_window_size = 64'd1048584;
      macro_dst_window_perm = 2'b10;
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
      macro_src0_iova = 64'hffff_ffff_ffff_fffc;
      macro_src1_iova = 64'hffff_ffff_ffff_fffc;
      macro_src2_iova = 64'hffff_ffff_ffff_fffc;
      macro_dst_iova = 64'hffff_ffff_ffff_fffc;
      macro_scratch_iova = 64'hffff_ffff_ffff_fffc;
      macro_element_count = 64'hffff_ffff_ffff_ffff;
      macro_outer_count = 32'hffff_ffff;
      macro_dtype = 32'hffff_ffff;
      macro_src0_stride = 64'hffff_ffff_ffff_fffc;
      macro_src1_stride = 64'hffff_ffff_ffff_fffc;
      macro_src2_stride = 64'hffff_ffff_ffff_fffc;
      macro_dst_stride = 64'hffff_ffff_ffff_fffc;
      macro_scalar0 = 32'hffff_ffff;
      macro_scalar1 = 32'hffff_ffff;
      macro_scratch_bytes = 32'hffff_ffff;
      macro_rope_position = 32'hffff_ffff;
      macro_src0_window_base = 64'hffff_ffff_ffff_fff8;
      macro_src0_window_size = 64'hffff_ffff_ffff_fff8;
      macro_src0_window_perm = 2'b11;
      macro_src1_window_base = 64'hffff_ffff_ffff_fff8;
      macro_src1_window_size = 64'hffff_ffff_ffff_fff8;
      macro_src1_window_perm = 2'b11;
      macro_dst_window_base = 64'hffff_ffff_ffff_fff8;
      macro_dst_window_size = 64'hffff_ffff_ffff_fff8;
      macro_dst_window_perm = 2'b11;
      macro_windows_generation_valid = 1'b0;
    end
  endtask

  reg [31:0] expected_kernel_q;
  reg [31:0] expected_context_q;
  reg [63:0] expected_sequence_q;
  reg [63:0] expected_producer_q;
  reg [63:0] expected_user_q;
  reg [63:0] expected_hash_lo_q;
  reg [63:0] expected_hash_hi_q;

  task automatic check_completion(
      input bit expect_error,
      input [`NPU_ERROR_W-1:0] expected_error_code,
      input [31:0] expected_error_class,
      input [63:0] expected_vector_elements
  );
    begin
      if (!completion_valid ||
          !completion_is_macro ||
          (completion_producer_id != 8'd0) ||
          !completion_npu_required ||
          (completion_opclass != 8'd0) ||
          (completion_error != expect_error) ||
          (completion_error_code != expected_error_code) ||
          (completion_macro_status != (expect_error
              ? {24'd0, expected_error_code} : 32'd0)) ||
          (completion_macro_error_class != expected_error_class) ||
          (completion_macro_kernel_id != expected_kernel_q) ||
          (completion_macro_command_flags != FLAGS_REQUIRED_PROFILE) ||
          (completion_macro_vector_flags != 32'd0) ||
          (completion_macro_context_id != expected_context_q) ||
          (completion_macro_sequence_id != expected_sequence_q) ||
          (completion_macro_producer_id != expected_producer_q) ||
          (completion_macro_user_tag != expected_user_q) ||
          (completion_macro_covered_node_count != 32'd1) ||
          (completion_macro_node_hash_lo != expected_hash_lo_q) ||
          (completion_macro_node_hash_hi != expected_hash_hi_q) ||
          (completion_macro_gmem_read_bytes != 64'd0) ||
          (completion_macro_gmem_write_bytes != 64'd0) ||
          (completion_macro_q8_mac_count != 64'd0) ||
          (completion_macro_vector_element_count !=
           expected_vector_elements) ||
          (completion_macro_state_update_count != 64'd0) ||
          (completion_macro_npu_cycles == 64'd0))
        fail("public completion identity or split ledger mismatch");
      if (portal_outstanding ||
          dut.f32_move_adapter_gmem_outstanding_w ||
          dut.selected_macro_gmem_outstanding_w)
        fail("terminal exposed with raw|portal outstanding");
      if ((portal_request_groups != portal_response_groups) ||
          (portal_request_groups !=
           (portal_read_groups + portal_write_groups)) ||
          (portal_read_bytes != (portal_read_words * 64'd4)) ||
          (portal_write_bytes != (portal_write_words * 64'd4)))
        fail("portal terminal closure mismatch");
    end
  endtask

  task automatic execute_command(
      input bit expect_error,
      input [`NPU_ERROR_W-1:0] expected_error_code,
      input [31:0] expected_error_class,
      input [63:0] expected_vector_elements
  );
    integer waited;
    integer held_cycle;
    reg [63:0] held_cycles;
    begin
      expected_kernel_q = macro_kernel_id;
      expected_context_q = macro_context_id;
      expected_sequence_q = macro_sequence_id;
      expected_producer_q = macro_producer_id;
      expected_user_q = macro_user_tag;
      expected_hash_lo_q = macro_node_hash_lo;
      expected_hash_hi_q = macro_node_hash_hi;

      waited = 0;
      while (!macro_cmd_ready && (waited < 100)) begin
        @(negedge clk);
        waited = waited + 1;
      end
      if (!macro_cmd_ready)
        fail("macro command did not become ready");
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
      check_completion(expect_error, expected_error_code,
                       expected_error_class, expected_vector_elements);
      held_cycles = completion_macro_npu_cycles;
      for (held_cycle = 0; held_cycle < 2;
           held_cycle = held_cycle + 1) begin
        @(posedge clk);
        @(negedge clk);
        check_completion(expect_error, expected_error_code,
                         expected_error_class, expected_vector_elements);
        if (completion_macro_npu_cycles != held_cycles)
          fail("completion payload changed under backpressure");
      end

      completion_ready = 1'b1;
      @(posedge clk);
      @(negedge clk);
      completion_ready = 1'b0;
      if (completion_valid)
        fail("completion did not close after handshake");
    end
  endtask

  task automatic clear_error_hold;
    integer waited;
    begin
      if (!sticky_error || macro_cmd_ready)
        fail("expected sticky terminal error hold");
      error_clear = 1'b1;
      @(posedge clk);
      @(negedge clk);
      error_clear = 1'b0;
      waited = 0;
      while ((sticky_error || !macro_cmd_ready) &&
             (waited < 20)) begin
        @(negedge clk);
        waited = waited + 1;
      end
      if (sticky_error || !macro_cmd_ready)
        fail("error_clear failed to restore idle");
    end
  endtask

  integer init_byte;
  integer init_element;
  integer init_outer;
  integer oracle_element;
  integer oracle_outer;
  integer oracle_repeat;
  integer before_requests;
  integer before_responses;
  integer before_read_groups;
  integer before_write_groups;
  integer before_read_words;
  integer before_write_words;
  integer before_commits;
  integer before_backpressure;
  integer before_latency;
  integer before_completion_bp;

  initial begin
    global_cycles = 0;
    checks = 0;
    rst = 1'b1;
    macro_cmd_valid = 1'b0;
    completion_ready = 1'b0;
    error_clear = 1'b0;
    inject_wrong_mask_q = 1'b0;
    poison_descriptor();

    for (init_byte = 0; init_byte < MEM_BYTES;
         init_byte = init_byte + 1)
      memory[init_byte] = 8'ha5;
    for (init_element = 0; init_element < GET_D;
         init_element = init_element + 1)
      store32(GET_SRC + init_element*4, get_pattern(init_element));
    store32(GET_IDX, 32'd0);
    for (init_element = 0; init_element < REP_D;
         init_element = init_element + 1) begin
      for (init_outer = 0; init_outer < REP_OUTER;
           init_outer = init_outer + 1)
        store32(REP_SRC + init_outer*512 + init_element*4,
                repeat_pattern(init_outer, init_element));
    end

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);

    // P06 GET_ROWS_F32: one raw I32 index plus 64 read and 64 write
    // lane groups.  D=1024 is an exact multiple of LANES=16.
    configure_get(64'hf32f_0000_0000_0601);
    before_requests = accepted_requests;
    before_responses = accepted_responses;
    before_read_groups = accepted_read_groups;
    before_write_groups = accepted_write_groups;
    before_read_words = accepted_read_words;
    before_write_words = accepted_write_words;
    before_commits = commit_pulses;
    before_backpressure = request_backpressure_cycles;
    before_latency = response_latency_cycles;
    before_completion_bp = completion_backpressure_cycles;
    execute_command(1'b0, `NPU_ERR_NONE, 32'd0, 64'd1024);
    checks = checks + 1;
    if ((portal_request_groups != 64'd129) ||
        (portal_response_groups != 64'd129) ||
        (portal_read_groups != 64'd65) ||
        (portal_write_groups != 64'd64) ||
        (portal_read_words != 64'd1025) ||
        (portal_write_words != 64'd1024) ||
        (portal_read_bytes != 64'd4100) ||
        (portal_write_bytes != 64'd4096) ||
        (accepted_requests-before_requests != 129) ||
        (accepted_responses-before_responses != 129) ||
        (accepted_read_groups-before_read_groups != 65) ||
        (accepted_write_groups-before_write_groups != 64) ||
        (accepted_read_words-before_read_words != 1025) ||
        (accepted_write_words-before_write_words != 1024) ||
        (commit_pulses-before_commits != 1) ||
        (request_backpressure_cycles-before_backpressure == 0) ||
        (response_latency_cycles-before_latency == 0) ||
        (completion_backpressure_cycles-before_completion_bp == 0))
      fail("P06 portal ledger, backpressure, or commit mismatch");
    for (oracle_element = 0; oracle_element < GET_D;
         oracle_element = oracle_element + 1) begin
      if (load32(GET_DST + oracle_element*4) !==
          load32(GET_SRC + oracle_element*4))
        fail("P06 GET_ROWS raw-bit oracle mismatch");
    end

    // P12 REPEAT_F32: the frozen [128,1,16] -> [128,128,16]
    // profile publishes the complete 1 MiB destination.
    configure_repeat(64'hf32f_0000_0000_1201);
    before_requests = accepted_requests;
    before_responses = accepted_responses;
    before_read_groups = accepted_read_groups;
    before_write_groups = accepted_write_groups;
    before_read_words = accepted_read_words;
    before_write_words = accepted_write_words;
    before_commits = commit_pulses;
    before_backpressure = request_backpressure_cycles;
    execute_command(1'b0, `NPU_ERR_NONE, 32'd0, 64'd262144);
    checks = checks + 1;
    if ((portal_request_groups != 64'd16512) ||
        (portal_response_groups != 64'd16512) ||
        (portal_read_groups != 64'd128) ||
        (portal_write_groups != 64'd16384) ||
        (portal_read_words != 64'd2048) ||
        (portal_write_words != 64'd262144) ||
        (portal_read_bytes != 64'd8192) ||
        (portal_write_bytes != 64'd1048576) ||
        (accepted_requests-before_requests != 16512) ||
        (accepted_responses-before_responses != 16512) ||
        (accepted_read_groups-before_read_groups != 128) ||
        (accepted_write_groups-before_write_groups != 16384) ||
        (accepted_read_words-before_read_words != 2048) ||
        (accepted_write_words-before_write_words != 262144) ||
        (commit_pulses-before_commits != 1) ||
        (request_backpressure_cycles-before_backpressure == 0))
      fail("P12 portal ledger, backpressure, or commit mismatch");
    for (oracle_outer = 0; oracle_outer < REP_OUTER;
         oracle_outer = oracle_outer + 1) begin
      for (oracle_repeat = 0; oracle_repeat < REP_COUNT;
           oracle_repeat = oracle_repeat + 1) begin
        for (oracle_element = 0; oracle_element < REP_D;
             oracle_element = oracle_element + 1) begin
          if (load32(REP_DST + oracle_outer*65536 +
                     oracle_repeat*512 + oracle_element*4) !==
              load32(REP_SRC + oracle_outer*512 +
                     oracle_element*4))
            fail("P12 REPEAT raw-bit oracle mismatch");
        end
      end
    end

    // Wrong-mask on the first GET index response is consumed and mapped by
    // Coprocessor to the real GMEM-response terminal.  No destination request
    // occurs and the private destination never receives a commit.
    for (init_element = 0; init_element < GET_D;
         init_element = init_element + 1)
      store32(GET_DST + init_element*4, 32'hca11_ab1e);
    configure_get(64'hf32f_0000_0000_0602);
    inject_wrong_mask_q = 1'b1;
    before_requests = accepted_requests;
    before_responses = accepted_responses;
    before_write_groups = accepted_write_groups;
    before_commits = commit_pulses;
    execute_command(1'b1, `NPU_ERR_GMEM_RESPONSE,
                    ABI_ERROR_GMEM, 64'd0);
    inject_wrong_mask_q = 1'b0;
    checks = checks + 1;
    if ((portal_request_groups != 64'd1) ||
        (portal_response_groups != 64'd1) ||
        (portal_read_groups != 64'd1) ||
        (portal_write_groups != 64'd0) ||
        (portal_read_words != 64'd0) ||
        (portal_write_words != 64'd0) ||
        (portal_read_bytes != 64'd0) ||
        (portal_write_bytes != 64'd0) ||
        (accepted_requests-before_requests != 1) ||
        (accepted_responses-before_responses != 1) ||
        (accepted_write_groups != before_write_groups) ||
        (commit_pulses != before_commits) ||
        (sticky_error_code != `NPU_ERR_GMEM_RESPONSE))
      fail("wrong-mask fail-closed mapping mismatch");
    for (oracle_element = 0; oracle_element < GET_D;
         oracle_element = oracle_element + 1) begin
      if (load32(GET_DST + oracle_element*4) !== 32'hca11_ab1e)
        fail("wrong-mask error changed private destination");
    end
    clear_error_hold();

    checks = checks + 1;
    if ((accepted_commands != 3) ||
        (accepted_completions != 3) ||
        (command_count != 64'd3) ||
        (completion_count != 64'd2) ||
        (error_count != 64'd1) ||
        (npu_required_issued != 64'd3) ||
        (npu_required_completed != 64'd2) ||
        (macro_command_count != 64'd3) ||
        (macro_completion_count != 64'd2) ||
        (macro_f32_start_count != 64'd0) ||
        sticky_error || busy || portal_outstanding ||
        dut.f32_move_adapter_gmem_outstanding_w ||
        dut.selected_macro_gmem_outstanding_w)
      fail("aggregate counters or terminal closure mismatch");

    $display("[NPU-COPROCESSOR-F32-MOVER-PORTAL][INFO] P06_GET=D1024/N1/V1 req/rsp=129 read/write_groups=65/64 words=1025/1024 bytes=4100/4096 P12_REPEAT=D128/O16/R128 req/rsp=16512 read/write_groups=128/16384 words=2048/262144 bytes=8192/1048576 gmem_completion_bytes=0/0 vector=1024+262144 raw_bit_exact=1 commits=2 wrong_mask=GMEM_RESPONSE/commit0 outstanding=0 checks=%0d",
             checks);
    $display("[NPU-COPROCESSOR-F32-MOVER-PORTAL][PASS] portal=1 lanes=16 profiles=P06_GET_ROWS_F32+P12_REPEAT_F32 scenarios=3 assertions=off waveform=off");
    $finish;
  end

  /* verilator lint_on BLKSEQ */
  /* verilator lint_on WIDTHEXPAND */
  /* verilator lint_on WIDTHTRUNC */

endmodule

`default_nettype wire
