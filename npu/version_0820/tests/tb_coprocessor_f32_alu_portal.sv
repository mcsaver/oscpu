`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Public macro-command/completion integration proof for the production
// VECTOR_F32 raw32 portal.  The portal model below is deliberately limited to
// copying words at RTL-issued addresses and committing a write only after its
// matching successful response.  All expected numeric bits come from a
// separate public TensorNpuFp32AddMul RTL instance.
module tb_coprocessor_f32_alu_portal;

  /* verilator lint_off BLKSEQ */
  /* verilator lint_off WIDTHTRUNC */
  /* verilator lint_off WIDTHEXPAND */

  localparam integer LANES = 8;
  localparam integer MEM_BYTES = 16'hb000;
  localparam integer MAX_WAIT_CYCLES = 200000;

  localparam [31:0] KERNEL_VECTOR_F32 = 32'h514e0010;
  localparam [31:0] FLAGS_CANONICAL = 32'h00000011;
  localparam [31:0] OP_ADD = 32'd1;
  localparam [31:0] OP_SCALE = 32'd4;
  localparam [31:0] SCALE_P16 = 32'h3db504f3;
  localparam [31:0] CONTEXT_ID = 32'h43414e01;

  localparam [31:0] ABI_ERROR_GMEM = 32'd6;
  localparam [31:0] ABI_ERROR_ABI = 32'd1;
  localparam [31:0] ABI_ERROR_CAPABILITY = 32'd3;
  localparam [31:0] ABI_ERROR_LAYOUT = 32'd4;
  localparam [31:0] ABI_ERROR_PROTOCOL = 32'd11;

  localparam [63:0] SRC0_BASE = 64'h0000_0000_0000_1000;
  localparam [63:0] SRC1_BASE = 64'h0000_0000_0000_4000;
  localparam [63:0] DST_BASE  = 64'h0000_0000_0000_8000;
  localparam [31:0] POISON_BITS = 32'ha5a5_5a5a;

  localparam integer P00_TOTAL = 16;
  localparam integer P16_TOTAL = 2048;

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

  wire f32_req_valid;
  reg f32_req_ready;
  wire f32_req_write;
  wire [LANES-1:0] f32_req_mask;
  wire [(LANES*64)-1:0] f32_req_src0_addr;
  wire [(LANES*64)-1:0] f32_req_src1_addr;
  wire [(LANES*64)-1:0] f32_req_dst_addr;
  wire [(LANES*32)-1:0] f32_req_wdata;
  reg f32_rsp_valid;
  wire f32_rsp_ready;
  reg [LANES-1:0] f32_rsp_mask;
  reg [(LANES*32)-1:0] f32_rsp_src0_data;
  reg [(LANES*32)-1:0] f32_rsp_src1_data;
  reg f32_rsp_error;
  wire [63:0] portal_request_groups;
  wire [63:0] portal_response_groups;
  wire [63:0] portal_read_groups;
  wire [63:0] portal_write_groups;
  wire [63:0] portal_input_words;
  wire [63:0] portal_output_words;
  wire [63:0] portal_read_bytes;
  wire [63:0] portal_write_bytes;
  wire portal_outstanding;

  wire q8_req_valid_unused;
  wire q8_rsp_ready_unused;
  wire q8_outstanding_unused;
  wire [63:0] q8_requests_unused;
  wire [63:0] q8_responses_unused;
  wire mover_req_valid_unused;
  wire mover_rsp_ready_unused;
  wire mover_outstanding_unused;
  wire [63:0] mover_requests_unused;
  wire [63:0] mover_responses_unused;

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

  wire cmd_ready_unused;
  wire desc_ready_unused;
  wire desc_error_unused;
  wire [`NPU_ERROR_W-1:0] desc_error_code_unused;
  wire [63:0] host_lmem_data_unused;
  wire host_lmem_rd_oob_unused;
  wire host_lmem_wr_oob_unused;
  wire host_lmem_ready_unused;
  wire [63:0] sync_tag_unused;
  wire sync_valid_unused;
  wire [63:0] tiu_cycles_unused;
  wire [63:0] dma_cycles_unused;
  wire [63:0] dma_bytes_unused;

  TensorNpuCoprocessor #(
    .LMEM_BYTES(512),
    .PID_W(8),
    .OPCLASS_W(8),
    .F32_ALU_PORTAL_ENABLE(1),
    .F32_ALU_PORTAL_LANES(LANES),
    .MACRO_CAPABILITY_EPOCH(32'h00000001)
  ) dut (
    .clk(clk),
    .rst(rst),
    .cmd_valid_i(1'b0),
    .cmd_ready_o(cmd_ready_unused),
    .cmd_is_64_i(1'b0),
    .cmd_bits_i(64'b0),
    .cmd_rs_value_i(64'b0),
    .cmd_producer_id_i(8'b0),
    .cmd_npu_required_i(1'b0),
    .cmd_opclass_i(8'b0),
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
    .desc_write_ready_o(desc_ready_unused),
    .desc_write_id_i(6'b0),
    .desc_write_word_i(3'b0),
    .desc_write_data_i(64'b0),
    .desc_write_error_o(desc_error_unused),
    .desc_write_error_code_o(desc_error_code_unused),
    .host_lmem_rd_valid_i(1'b0),
    .host_lmem_rd_addr_i(32'b0),
    .host_lmem_rd_bytes_i(4'b0),
    .host_lmem_rd_data_o(host_lmem_data_unused),
    .host_lmem_rd_oob_o(host_lmem_rd_oob_unused),
    .host_lmem_wr_valid_i(1'b0),
    .host_lmem_wr_addr_i(32'b0),
    .host_lmem_wr_data_i(64'b0),
    .host_lmem_wr_strb_i(8'b0),
    .host_lmem_wr_oob_o(host_lmem_wr_oob_unused),
    .host_lmem_ready_o(host_lmem_ready_unused),
    .gmem_req_valid_o(gmem_req_valid),
    .gmem_req_ready_i(1'b1),
    .gmem_req_write_o(gmem_req_write),
    .gmem_req_addr_o(gmem_req_addr),
    .gmem_req_wdata_o(gmem_req_wdata),
    .gmem_req_wstrb_o(gmem_req_wstrb),
    .gmem_rsp_valid_i(1'b0),
    .gmem_rsp_ready_o(gmem_rsp_ready),
    .gmem_rsp_rdata_i(64'b0),
    .gmem_rsp_error_i(1'b0),
    .q8_portal_req_valid_o(q8_req_valid_unused),
    .q8_portal_req_ready_i(1'b0),
    .q8_portal_req_mask_o(),
    .q8_portal_req_addr_o(),
    .q8_portal_rsp_valid_i(1'b0),
    .q8_portal_rsp_ready_o(q8_rsp_ready_unused),
    .q8_portal_rsp_mask_i(4'b0),
    .q8_portal_rsp_blocks_i(1088'b0),
    .q8_portal_rsp_error_i(1'b0),
    .q8_portal_request_count_o(q8_requests_unused),
    .q8_portal_response_count_o(q8_responses_unused),
    .q8_portal_block_count_o(),
    .q8_portal_byte_count_o(),
    .q8_portal_outstanding_o(q8_outstanding_unused),
    .f32_alu_portal_req_valid_o(f32_req_valid),
    .f32_alu_portal_req_ready_i(f32_req_ready),
    .f32_alu_portal_req_write_o(f32_req_write),
    .f32_alu_portal_req_mask_o(f32_req_mask),
    .f32_alu_portal_req_src0_addr_o(f32_req_src0_addr),
    .f32_alu_portal_req_src1_addr_o(f32_req_src1_addr),
    .f32_alu_portal_req_dst_addr_o(f32_req_dst_addr),
    .f32_alu_portal_req_wdata_o(f32_req_wdata),
    .f32_alu_portal_rsp_valid_i(f32_rsp_valid),
    .f32_alu_portal_rsp_ready_o(f32_rsp_ready),
    .f32_alu_portal_rsp_mask_i(f32_rsp_mask),
    .f32_alu_portal_rsp_src0_data_i(f32_rsp_src0_data),
    .f32_alu_portal_rsp_src1_data_i(f32_rsp_src1_data),
    .f32_alu_portal_rsp_error_i(f32_rsp_error),
    .f32_alu_portal_request_groups_o(portal_request_groups),
    .f32_alu_portal_response_groups_o(portal_response_groups),
    .f32_alu_portal_read_groups_o(portal_read_groups),
    .f32_alu_portal_write_groups_o(portal_write_groups),
    .f32_alu_portal_input_words_o(portal_input_words),
    .f32_alu_portal_output_words_o(portal_output_words),
    .f32_alu_portal_read_bytes_o(portal_read_bytes),
    .f32_alu_portal_write_bytes_o(portal_write_bytes),
    .f32_alu_portal_outstanding_o(portal_outstanding),
    .f32_mover_portal_req_valid_o(mover_req_valid_unused),
    .f32_mover_portal_req_ready_i(1'b0),
    .f32_mover_portal_req_write_o(),
    .f32_mover_portal_req_mask_o(),
    .f32_mover_portal_req_addr_o(),
    .f32_mover_portal_req_wdata_o(),
    .f32_mover_portal_rsp_valid_i(1'b0),
    .f32_mover_portal_rsp_ready_o(mover_rsp_ready_unused),
    .f32_mover_portal_rsp_mask_i(16'b0),
    .f32_mover_portal_rsp_rdata_i(512'b0),
    .f32_mover_portal_rsp_error_i(1'b0),
    .f32_mover_portal_request_groups_o(mover_requests_unused),
    .f32_mover_portal_response_groups_o(mover_responses_unused),
    .f32_mover_portal_read_groups_o(),
    .f32_mover_portal_write_groups_o(),
    .f32_mover_portal_read_words_o(),
    .f32_mover_portal_write_words_o(),
    .f32_mover_portal_read_bytes_o(),
    .f32_mover_portal_write_bytes_o(),
    .f32_mover_portal_outstanding_o(mover_outstanding_unused),
    .sync_tag_ack_i(1'b0),
    .sync_tag_o(sync_tag_unused),
    .sync_tag_valid_o(sync_valid_unused),
    .error_clear_i(error_clear),
    .busy_o(busy),
    .error_o(sticky_error),
    .error_code_o(sticky_error_code),
    .command_count_o(command_count),
    .completion_count_o(completion_count),
    .error_count_o(error_count),
    .npu_required_issued_o(npu_required_issued),
    .npu_required_completed_o(npu_required_completed),
    .tiu_cycles_o(tiu_cycles_unused),
    .dma_cycles_o(dma_cycles_unused),
    .dma_bytes_o(dma_bytes_unused),
    .macro_command_count_o(macro_command_count),
    .macro_f32_start_count_o(macro_f32_start_count),
    .macro_completion_count_o(macro_completion_count)
  );

  reg oracle_req_valid;
  wire oracle_req_ready;
  reg oracle_op_mul;
  reg [31:0] oracle_lhs;
  reg [31:0] oracle_rhs;
  wire oracle_rsp_valid;
  reg oracle_rsp_ready;
  wire [31:0] oracle_result;
  wire [4:0] oracle_flags;

  TensorNpuFp32AddMul oracle (
    .clk_i(clk),
    .rst_i(rst),
    .req_valid_i(oracle_req_valid),
    .req_ready_o(oracle_req_ready),
    .op_mul_i(oracle_op_mul),
    .lhs_bits_i(oracle_lhs),
    .rhs_bits_i(oracle_rhs),
    .rsp_valid_o(oracle_rsp_valid),
    .rsp_ready_i(oracle_rsp_ready),
    .result_bits_o(oracle_result),
    .flags_o(oracle_flags)
  );

  reg [7:0] memory [0:MEM_BYTES-1];
  reg [31:0] expected_p00 [0:P00_TOTAL-1];
  reg [31:0] expected_p16 [0:P16_TOTAL-1];
  reg [4:0] expected_p00_flags [0:P00_TOTAL-1];
  reg [4:0] expected_p16_flags [0:P16_TOTAL-1];

  reg pending_write;
  reg [LANES-1:0] pending_mask;
  reg [(LANES*64)-1:0] pending_src0_addr;
  reg [(LANES*64)-1:0] pending_src1_addr;
  reg [(LANES*64)-1:0] pending_dst_addr;
  reg [(LANES*32)-1:0] pending_wdata;

  integer global_cycles;
  integer checks;
  integer accepted_commands;
  integer accepted_completions;
  integer request_hold_cycles;
  integer response_hold_cycles;
  integer completion_hold_cycles;
  integer committed_words;

  wire [954:0] completion_payload_bus = {
    completion_producer_id,
    completion_npu_required,
    completion_opclass,
    completion_error,
    completion_error_code,
    completion_is_macro,
    completion_macro_status,
    completion_macro_error_class,
    completion_macro_kernel_id,
    completion_macro_command_flags,
    completion_macro_vector_flags,
    completion_macro_context_id,
    completion_macro_sequence_id,
    completion_macro_producer_id,
    completion_macro_user_tag,
    completion_macro_covered_node_count,
    completion_macro_node_hash_lo,
    completion_macro_node_hash_hi,
    completion_macro_npu_cycles,
    completion_macro_gmem_read_bytes,
    completion_macro_gmem_write_bytes,
    completion_macro_q8_mac_count,
    completion_macro_vector_element_count,
    completion_macro_state_update_count
  };

  wire [512:0] portal_ledger_bus = {
    portal_request_groups,
    portal_response_groups,
    portal_read_groups,
    portal_write_groups,
    portal_input_words,
    portal_output_words,
    portal_read_bytes,
    portal_write_bytes,
    portal_outstanding
  };

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic step_cycle;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic fail(input string reason);
    begin
      $display("[NPU-COPROCESSOR-F32-ALU-PORTAL][FAIL] %s cycle=%0d coproc_state=%0d portal_state=%0d",
               reason, global_cycles, dut.state_q,
               dut.gen_f32_alu_portal.u_vector_f32_portal_adapter.state_q);
      $display("[NPU-COPROCESSOR-F32-ALU-PORTAL][EVIDENCE] completion=%0b err=%0b/%0d class=%0d vector=%0d gmem=%0d/%0d portal=req%0d/rsp%0d/read%0d/write%0d/in%0d/out%0d/rb%0d/wb%0d outstanding=%0b commits=%0d",
               completion_valid, completion_error, completion_error_code,
               completion_macro_error_class,
               completion_macro_vector_element_count,
               completion_macro_gmem_read_bytes,
               completion_macro_gmem_write_bytes,
               portal_request_groups, portal_response_groups,
               portal_read_groups, portal_write_groups,
               portal_input_words, portal_output_words,
               portal_read_bytes, portal_write_bytes,
               portal_outstanding, committed_words);
      $fatal(1);
    end
  endtask

  function automatic [31:0] load32(input [63:0] address);
    begin
      load32 = {memory[int'(address)+3], memory[int'(address)+2],
                memory[int'(address)+1], memory[int'(address)+0]};
    end
  endfunction

  task automatic store32(input [63:0] address, input [31:0] bits);
    begin
      if ((address + 64'd4) > MEM_BYTES)
        fail("portal memory address out of bounds");
      memory[int'(address)+0] = bits[7:0];
      memory[int'(address)+1] = bits[15:8];
      memory[int'(address)+2] = bits[23:16];
      memory[int'(address)+3] = bits[31:24];
    end
  endtask

  function automatic [31:0] raw_lhs(input integer selector);
    begin
      case (selector % 13)
        0: raw_lhs = 32'h00000000;
        1: raw_lhs = 32'h80000000;
        2: raw_lhs = 32'h00000001;
        3: raw_lhs = 32'h807fffff;
        4: raw_lhs = 32'h3f800000;
        5: raw_lhs = 32'hc0200000;
        6: raw_lhs = 32'h7f800000;
        7: raw_lhs = 32'hff800000;
        8: raw_lhs = 32'h7fc12345;
        9: raw_lhs = 32'h7fa12345;
        10: raw_lhs = 32'h7f7fffff;
        11: raw_lhs = 32'h00800000;
        default: raw_lhs = 32'h40400000;
      endcase
    end
  endfunction

  function automatic [31:0] raw_rhs(input integer selector);
    begin
      case (selector % 13)
        0: raw_rhs = 32'h80000000;
        1: raw_rhs = 32'h00000000;
        2: raw_rhs = 32'h00000002;
        3: raw_rhs = 32'h40000000;
        4: raw_rhs = 32'hbf800000;
        5: raw_rhs = 32'h7f800000;
        6: raw_rhs = 32'h00000000;
        7: raw_rhs = 32'hff800000;
        8: raw_rhs = 32'h3f800000;
        9: raw_rhs = 32'h7fc54321;
        10: raw_rhs = 32'h40000000;
        11: raw_rhs = 32'h00000001;
        default: raw_rhs = 32'hc0400000;
      endcase
    end
  endfunction

  function automatic integer profile_total(input integer profile);
    begin
      profile_total = (profile == 0) ? P00_TOTAL : P16_TOTAL;
    end
  endfunction

  function automatic [31:0] expected_bits(input integer profile,
                                           input integer index);
    begin
      expected_bits = (profile == 0) ? expected_p00[index]
                                     : expected_p16[index];
    end
  endfunction

  function automatic [63:0] expected_src0_address(input integer index);
    begin
      expected_src0_address = SRC0_BASE + (64'(index) << 2);
    end
  endfunction

  function automatic [63:0] expected_src1_address(input integer profile,
                                                   input integer index);
    begin
      expected_src1_address = (profile == 0)
                            ? SRC1_BASE + (64'(index) << 2) : 64'b0;
    end
  endfunction

  function automatic [63:0] expected_dst_address(input integer index);
    begin
      expected_dst_address = DST_BASE + (64'(index) << 2);
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      global_cycles <= 0;
    end else begin
      global_cycles <= global_cycles + 1;
      if (gmem_req_valid || gmem_req_write || (gmem_req_addr != 64'b0)
          || (gmem_req_wdata != 64'b0) || (gmem_req_wstrb != 8'b0)
          || gmem_rsp_ready)
        fail("VECTOR_F32 portal branch leaked a public GMEM transaction");
      if (q8_req_valid_unused || q8_rsp_ready_unused
          || q8_outstanding_unused || (q8_requests_unused != 64'b0)
          || (q8_responses_unused != 64'b0))
        fail("VECTOR_F32 transaction leaked into Q8 portal");
      if (mover_req_valid_unused || mover_rsp_ready_unused
          || mover_outstanding_unused || (mover_requests_unused != 64'b0)
          || (mover_responses_unused != 64'b0))
        fail("VECTOR_F32 transaction leaked into F32 mover portal");
    end
  end

  task automatic oracle_eval(
      input integer multiply,
      input [31:0] lhs_bits,
      input [31:0] rhs_bits,
      output [31:0] result_bits,
      output [4:0] flags_bits);
    integer guard;
    reg [31:0] held_result;
    reg [4:0] held_flags;
    begin
      guard = 0;
      while (!oracle_req_ready) begin
        step_cycle();
        guard = guard + 1;
        if (guard > 1000)
          fail("oracle request timeout");
      end
      oracle_op_mul = multiply[0];
      oracle_lhs = lhs_bits;
      oracle_rhs = rhs_bits;
      oracle_rsp_ready = 1'b0;
      @(negedge clk);
      oracle_req_valid = 1'b1;
      step_cycle();
      oracle_req_valid = 1'b0;
      guard = 0;
      while (!oracle_rsp_valid) begin
        step_cycle();
        guard = guard + 1;
        if (guard > 1000)
          fail("oracle response timeout");
      end
      held_result = oracle_result;
      held_flags = oracle_flags;
      step_cycle();
      if (!oracle_rsp_valid || (oracle_result !== held_result)
          || (oracle_flags !== held_flags))
        fail("oracle response changed while backpressured");
      result_bits = held_result;
      flags_bits = held_flags;
      @(negedge clk);
      oracle_rsp_ready = 1'b1;
      step_cycle();
      oracle_rsp_ready = 1'b0;
    end
  endtask

  task automatic build_oracles;
    integer index;
    reg [31:0] result_bits;
    reg [4:0] flags_bits;
    begin
      for (index = 0; index < P00_TOTAL; index = index + 1) begin
        oracle_eval(0, raw_lhs(index), raw_rhs(index),
                    result_bits, flags_bits);
        expected_p00[index] = result_bits;
        expected_p00_flags[index] = flags_bits;
      end
      for (index = 0; index < P16_TOTAL; index = index + 1) begin
        oracle_eval(1, raw_lhs(index), SCALE_P16,
                    result_bits, flags_bits);
        expected_p16[index] = result_bits;
        expected_p16_flags[index] = flags_bits;
      end
    end
  endtask

  task automatic load_fixtures;
    integer index;
    begin
      for (index = 0; index < P16_TOTAL; index = index + 1)
        store32(SRC0_BASE + (64'(index) << 2), raw_lhs(index));
      for (index = 0; index < P00_TOTAL; index = index + 1)
        store32(SRC1_BASE + (64'(index) << 2), raw_rhs(index));
    end
  endtask

  task automatic poison_destination(input integer total);
    integer index;
    begin
      for (index = 0; index < total; index = index + 1)
        store32(DST_BASE + (64'(index) << 2), POISON_BITS);
    end
  endtask

  task automatic setup_descriptor(input integer profile,
                                  input [63:0] sequence_value);
    begin
      macro_abi_valid = 1'b1;
      macro_kernel_id = KERNEL_VECTOR_F32;
      macro_command_flags = FLAGS_CANONICAL;
      macro_context_id = CONTEXT_ID;
      macro_capability_epoch = 32'h00000001;
      macro_sequence_id = sequence_value;
      macro_producer_id = 64'h8877_6600_0000_0000
                        | {32'b0, sequence_value[31:0]};
      macro_user_tag = 64'h1234_5600_0000_0000
                     | {32'b0, sequence_value[31:0]};
      macro_node_count = 32'd1;
      macro_node_hash_lo = 64'h1122_3300_0000_0000
                         | {32'b0, sequence_value[31:0]};
      macro_node_hash_hi = 64'h4455_6600_0000_0000
                         | {32'b0, sequence_value[31:0]};
      macro_deadline_cycles = 64'b0;
      macro_vector_flags = profile;
      macro_src0_iova = SRC0_BASE;
      macro_src2_iova = 64'b0;
      macro_dst_iova = DST_BASE;
      macro_scratch_iova = 64'b0;
      macro_dtype = 32'd1;
      macro_src2_stride = 64'b0;
      macro_scalar1 = 32'b0;
      macro_scratch_bytes = 32'b0;
      macro_rope_position = 32'b0;
      macro_src0_window_base = SRC0_BASE;
      macro_src0_window_perm = 2'b01;
      macro_dst_window_base = DST_BASE;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      if (profile == 0) begin
        macro_vector_op = OP_ADD;
        macro_src1_iova = SRC1_BASE;
        macro_element_count = 64'd16;
        macro_outer_count = 32'd1;
        macro_src0_stride = 64'd64;
        macro_src1_stride = 64'd64;
        macro_dst_stride = 64'd64;
        macro_scalar0 = 32'b0;
        macro_src0_window_size = 64'd64;
        macro_src1_window_base = SRC1_BASE;
        macro_src1_window_size = 64'd64;
        macro_src1_window_perm = 2'b01;
        macro_dst_window_size = 64'd64;
      end else if (profile == 16) begin
        macro_vector_op = OP_SCALE;
        macro_src1_iova = 64'b0;
        macro_element_count = 64'd128;
        macro_outer_count = 32'd16;
        macro_src0_stride = 64'd512;
        macro_src1_stride = 64'b0;
        macro_dst_stride = 64'd512;
        macro_scalar0 = SCALE_P16;
        macro_src0_window_size = 64'd8192;
        macro_src1_window_base = 64'b0;
        macro_src1_window_size = 64'b0;
        macro_src1_window_perm = 2'b00;
        macro_dst_window_size = 64'd8192;
      end else begin
        // The post-bootstrap recurrent cache_r/cache_s SCALE descriptors keep
        // their P17/P18 owner identities but have ne0=0.  They carry aligned
        // zero-byte source/destination capabilities and never enter the F32
        // child or raw32 portal.
        macro_vector_op = OP_SCALE;
        macro_src1_iova = 64'b0;
        macro_element_count = 64'd0;
        macro_outer_count = 32'd1;
        macro_src0_stride = 64'd0;
        macro_src1_stride = 64'd0;
        macro_dst_stride = 64'd0;
        macro_scalar0 = 32'd0;
        macro_src0_window_size = 64'd0;
        macro_src1_window_base = 64'd0;
        macro_src1_window_size = 64'd0;
        macro_src1_window_perm = 2'b00;
        macro_dst_window_size = 64'd0;
      end
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

  task automatic issue_macro(input integer profile,
                             input [63:0] sequence_value);
    integer guard;
    begin
      setup_descriptor(profile, sequence_value);
      guard = 0;
      while (!macro_cmd_ready) begin
        step_cycle();
        guard = guard + 1;
        if (guard > 2000)
          fail("macro command ready timeout");
      end
      @(negedge clk);
      macro_cmd_valid = 1'b1;
      step_cycle();
      if (!busy || macro_cmd_ready)
        fail("macro command admission did not become resident");
      macro_cmd_valid = 1'b0;
      accepted_commands = accepted_commands + 1;
      poison_live_descriptor();
    end
  endtask

  task automatic issue_malformed_empty(input integer profile,
                                       input integer mutation,
                                       input [63:0] sequence_value);
    integer guard;
    begin
      setup_descriptor(profile, sequence_value);
      // Every mutation is adjacent to the canonical empty form.  None may use
      // the direct-success shortcut or reach the numerical/portal child.
      case (mutation)
        0: macro_outer_count = 32'd0;
        1: begin
          // A P16 owner can never claim the P17/P18 empty capability.
          macro_element_count = 64'd0;
          macro_outer_count = 32'd1;
          macro_src0_stride = 64'd0;
          macro_src1_stride = 64'd0;
          macro_dst_stride = 64'd0;
          macro_scalar0 = 32'd0;
          macro_src0_window_size = 64'd0;
          macro_dst_window_size = 64'd0;
        end
        2: macro_abi_valid = 1'b0;
        3: macro_capability_epoch = 32'd2;
        4: macro_element_count = 64'd1;
        5: macro_scalar0 = 32'h3f800000;
        6: begin
          macro_src1_iova = SRC1_BASE;
          macro_src1_window_base = SRC1_BASE;
          macro_src1_window_perm = 2'b01;
        end
        7: macro_windows_generation_valid = 1'b0;
        8: macro_src0_iova = 64'd0;
        9: macro_dst_window_size = 64'd4;
        10: macro_src0_stride = 64'd4;
        default: fail("unknown malformed-empty mutation");
      endcase
      guard = 0;
      while (!macro_cmd_ready) begin
        step_cycle();
        guard = guard + 1;
        if (guard > 2000)
          fail("malformed empty command ready timeout");
      end
      @(negedge clk);
      macro_cmd_valid = 1'b1;
      step_cycle();
      if (!busy || macro_cmd_ready)
        fail("malformed empty command did not become resident");
      macro_cmd_valid = 1'b0;
      accepted_commands = accepted_commands + 1;
      poison_live_descriptor();
    end
  endtask

  task automatic check_request(input integer profile,
                               input integer base_index,
                               input integer write_request);
    integer lane;
    integer index;
    begin
      if ((f32_req_write !== write_request[0])
          || (f32_req_mask !== {LANES{1'b1}}))
        fail("portal request type/mask mismatch");
      for (lane = 0; lane < LANES; lane = lane + 1) begin
        index = base_index + lane;
        if (!write_request) begin
          if ((f32_req_src0_addr[(lane*64) +: 64]
               !== expected_src0_address(index))
              || (f32_req_src1_addr[(lane*64) +: 64]
                  !== expected_src1_address(profile, index))
              || (f32_req_dst_addr[(lane*64) +: 64] != 64'b0)
              || (f32_req_wdata[(lane*32) +: 32] != 32'b0))
            fail("raw32 read request address/non-applicable field mismatch");
        end else begin
          if ((f32_req_src0_addr[(lane*64) +: 64] != 64'b0)
              || (f32_req_src1_addr[(lane*64) +: 64] != 64'b0)
              || (f32_req_dst_addr[(lane*64) +: 64]
                  !== expected_dst_address(index))
              || (f32_req_wdata[(lane*32) +: 32]
                  !== expected_bits(profile, index)))
            fail("raw32 write request address/oracle bits mismatch");
        end
      end
    end
  endtask

  task automatic accept_request(input integer profile,
                                input integer base_index,
                                input integer write_request);
    integer guard;
    integer hold_index;
    reg [LANES-1:0] held_mask;
    reg [(LANES*64)-1:0] held_src0;
    reg [(LANES*64)-1:0] held_src1;
    reg [(LANES*64)-1:0] held_dst;
    reg [(LANES*32)-1:0] held_wdata;
    reg [63:0] request_before;
    reg [63:0] read_before;
    reg [63:0] write_before;
    begin
      f32_req_ready = 1'b0;
      guard = 0;
      while (!f32_req_valid) begin
        step_cycle();
        guard = guard + 1;
        if (guard > 5000)
          fail("portal request timeout");
      end
      check_request(profile, base_index, write_request);
      held_mask = f32_req_mask;
      held_src0 = f32_req_src0_addr;
      held_src1 = f32_req_src1_addr;
      held_dst = f32_req_dst_addr;
      held_wdata = f32_req_wdata;
      request_before = portal_request_groups;
      read_before = portal_read_groups;
      write_before = portal_write_groups;
      for (hold_index = 0; hold_index < 2; hold_index = hold_index + 1) begin
        step_cycle();
        request_hold_cycles = request_hold_cycles + 1;
        if (!f32_req_valid || (f32_req_mask !== held_mask)
            || (f32_req_src0_addr !== held_src0)
            || (f32_req_src1_addr !== held_src1)
            || (f32_req_dst_addr !== held_dst)
            || (f32_req_wdata !== held_wdata)
            || (portal_request_groups !== request_before)
            || portal_outstanding)
          fail("portal request changed while ready was low");
      end
      pending_write = f32_req_write;
      pending_mask = f32_req_mask;
      pending_src0_addr = f32_req_src0_addr;
      pending_src1_addr = f32_req_src1_addr;
      pending_dst_addr = f32_req_dst_addr;
      pending_wdata = f32_req_wdata;
      @(negedge clk);
      f32_req_ready = 1'b1;
      step_cycle();
      f32_req_ready = 1'b0;
      if (!portal_outstanding
          || (portal_request_groups != request_before + 64'd1)
          || (portal_read_groups
              != read_before + (write_request ? 64'd0 : 64'd1))
          || (portal_write_groups
              != write_before + (write_request ? 64'd1 : 64'd0)))
        fail("portal request handshake accounting mismatch");
    end
  endtask

  task automatic send_success_response(input integer write_response);
    integer lane;
    reg [(LANES*32)-1:0] held_src0;
    reg [(LANES*32)-1:0] held_src1;
    reg [LANES-1:0] held_mask;
    reg [63:0] response_before;
    begin
      if (pending_write !== write_response[0])
        fail("testbench pending request type mismatch");
      f32_rsp_src0_data = {(LANES*32){1'b0}};
      f32_rsp_src1_data = {(LANES*32){1'b0}};
      if (!write_response) begin
        for (lane = 0; lane < LANES; lane = lane + 1) begin
          f32_rsp_src0_data[(lane*32) +: 32] =
              load32(pending_src0_addr[(lane*64) +: 64]);
          if (pending_src1_addr[(lane*64) +: 64] != 64'b0)
            f32_rsp_src1_data[(lane*32) +: 32] =
                load32(pending_src1_addr[(lane*64) +: 64]);
        end
      end
      f32_rsp_mask = pending_mask;
      f32_rsp_error = 1'b0;
      held_src0 = f32_rsp_src0_data;
      held_src1 = f32_rsp_src1_data;
      held_mask = f32_rsp_mask;
      response_before = portal_response_groups;
      @(negedge clk);
      f32_rsp_valid = 1'b1;
      if (f32_rsp_ready)
        fail("correct portal response was not initially backpressured");
      step_cycle();
      response_hold_cycles = response_hold_cycles + 1;
      if (!f32_rsp_valid || !f32_rsp_ready
          || (f32_rsp_src0_data !== held_src0)
          || (f32_rsp_src1_data !== held_src1)
          || (f32_rsp_mask !== held_mask)
          || (portal_response_groups !== response_before))
        fail("portal response hold/arm contract mismatch");
      step_cycle();
      f32_rsp_valid = 1'b0;
      if (portal_outstanding
          || (portal_response_groups != response_before + 64'd1))
        fail("portal response handshake accounting mismatch");
      if (write_response) begin
        for (lane = 0; lane < LANES; lane = lane + 1) begin
          if (pending_mask[lane]) begin
            store32(pending_dst_addr[(lane*64) +: 64],
                    pending_wdata[(lane*32) +: 32]);
            committed_words = committed_words + 1;
          end
        end
      end
      f32_rsp_mask = {LANES{1'b0}};
      f32_rsp_src0_data = {(LANES*32){1'b0}};
      f32_rsp_src1_data = {(LANES*32){1'b0}};
    end
  endtask

  task automatic check_completion(
      input integer profile,
      input [63:0] sequence_value,
      input integer expect_error,
      input [`NPU_ERROR_W-1:0] expected_code,
      input [31:0] expected_class,
      input [63:0] expected_elements,
      input [63:0] expected_requests,
      input [63:0] expected_responses,
      input [63:0] expected_reads,
      input [63:0] expected_writes,
      input [63:0] expected_input_words,
      input [63:0] expected_output_words,
      input [63:0] expected_portal_read_bytes,
      input [63:0] expected_portal_write_bytes);
    integer guard;
    integer hold_index;
    reg [954:0] held_completion;
    reg [512:0] held_ledger;
    begin
      guard = 0;
      while (!completion_valid) begin
        step_cycle();
        guard = guard + 1;
        if (guard > MAX_WAIT_CYCLES)
          fail("completion timeout");
      end
      if (portal_outstanding)
        fail("terminal completion preceded portal drain");
      checks = checks + 1;
      if ((completion_error !== expect_error[0])
          || (completion_error_code !== expected_code)
          || (completion_macro_status !== {24'b0, expected_code})
          || (completion_macro_error_class !== expected_class)
          || !completion_is_macro || !completion_npu_required
          || (completion_producer_id != 8'b0)
          || (completion_opclass != 8'b0)
          || (completion_macro_kernel_id != KERNEL_VECTOR_F32)
          || (completion_macro_command_flags != FLAGS_CANONICAL)
          || (completion_macro_vector_flags != profile)
          || (completion_macro_context_id != CONTEXT_ID)
          || (completion_macro_sequence_id != sequence_value)
          || (completion_macro_producer_id
              != (64'h8877_6600_0000_0000
                  | {32'b0, sequence_value[31:0]}))
          || (completion_macro_user_tag
              != (64'h1234_5600_0000_0000
                  | {32'b0, sequence_value[31:0]}))
          || (completion_macro_covered_node_count != 32'd1)
          || (completion_macro_node_hash_lo
              != (64'h1122_3300_0000_0000
                  | {32'b0, sequence_value[31:0]}))
          || (completion_macro_node_hash_hi
              != (64'h4455_6600_0000_0000
                  | {32'b0, sequence_value[31:0]}))
          || (completion_macro_npu_cycles == 64'b0)
          || (completion_macro_gmem_read_bytes != 64'b0)
          || (completion_macro_gmem_write_bytes != 64'b0)
          || (completion_macro_q8_mac_count != 64'b0)
          || (completion_macro_vector_element_count != expected_elements)
          || (completion_macro_state_update_count != 64'b0))
        fail("public completion identity/error/GMEM ledger mismatch");
      if ((portal_request_groups != expected_requests)
          || (portal_response_groups != expected_responses)
          || (portal_read_groups != expected_reads)
          || (portal_write_groups != expected_writes)
          || (portal_input_words != expected_input_words)
          || (portal_output_words != expected_output_words)
          || (portal_read_bytes != expected_portal_read_bytes)
          || (portal_write_bytes != expected_portal_write_bytes))
        fail("independent portal ledger mismatch at completion");
      held_completion = completion_payload_bus;
      held_ledger = portal_ledger_bus;
      for (hold_index = 0; hold_index < 2; hold_index = hold_index + 1) begin
        step_cycle();
        completion_hold_cycles = completion_hold_cycles + 1;
        if (!completion_valid
            || (completion_payload_bus !== held_completion)
            || (portal_ledger_bus !== held_ledger))
          fail("completion payload or portal counters changed under backpressure");
      end
      @(negedge clk);
      completion_ready = 1'b1;
      step_cycle();
      completion_ready = 1'b0;
      accepted_completions = accepted_completions + 1;
      if (completion_valid)
        fail("completion valid remained after consume");
      if (expect_error) begin
        if (!sticky_error || (sticky_error_code != expected_code)
            || macro_cmd_ready || busy)
          fail("error completion did not enter public fail-closed hold");
        @(negedge clk);
        error_clear = 1'b1;
        step_cycle();
        error_clear = 1'b0;
        if (sticky_error || !macro_cmd_ready || busy)
          fail("error clear did not restore idle admission");
      end else if (sticky_error || !macro_cmd_ready || busy) begin
        fail("successful completion did not return to idle");
      end
    end
  endtask

  task automatic verify_destination(input integer profile);
    integer index;
    begin
      for (index = 0; index < profile_total(profile); index = index + 1) begin
        checks = checks + 1;
        if (load32(expected_dst_address(index)) !== expected_bits(profile, index))
          fail("committed destination differs from independent AddMul oracle");
      end
    end
  endtask

  task automatic verify_destination_poison(input integer total);
    integer index;
    begin
      for (index = 0; index < total; index = index + 1) begin
        checks = checks + 1;
        if (load32(expected_dst_address(index)) !== POISON_BITS)
          fail("faulting command changed destination before successful commit");
      end
    end
  endtask

  task automatic run_success(input integer profile,
                             input [63:0] sequence_value);
    integer total;
    integer base_index;
    integer groups;
    integer input_words;
    integer commits_before;
    begin
      total = profile_total(profile);
      groups = total / LANES;
      input_words = (profile == 0) ? (total * 2) : total;
      poison_destination(total);
      commits_before = committed_words;
      issue_macro(profile, sequence_value);
      for (base_index = 0; base_index < total;
           base_index = base_index + LANES) begin
        accept_request(profile, base_index, 0);
        send_success_response(0);
        accept_request(profile, base_index, 1);
        send_success_response(1);
      end
      check_completion(profile, sequence_value, 0, `NPU_ERR_NONE, 32'b0,
                       total, groups * 2, groups * 2, groups, groups,
                       input_words, total, input_words * 4, total * 4);
      if ((committed_words - commits_before) != total)
        fail("successful command commit count mismatch");
      verify_destination(profile);
    end
  endtask

  task automatic run_empty_success(input integer profile,
                                   input [63:0] sequence_value);
    integer guard;
    integer commits_before;
    reg [31:0] dst_before;
    reg [512:0] ledger_before;
    reg [63:0] f32_starts_before;
    begin
      poison_destination(1);
      commits_before = committed_words;
      dst_before = load32(DST_BASE);
      ledger_before = portal_ledger_bus;
      f32_starts_before = macro_f32_start_count;
      issue_macro(profile, sequence_value);
      guard = 0;
      while (!completion_valid) begin
        step_cycle();
        guard = guard + 1;
        if (f32_req_valid || f32_rsp_ready || portal_outstanding ||
            gmem_req_valid || (portal_ledger_bus !== ledger_before))
          fail("empty SCALE leaked a numerical or memory transaction");
        if (guard > 100)
          fail("empty SCALE completion timeout");
      end
      if ((macro_f32_start_count !== f32_starts_before) ||
          (portal_ledger_bus !== ledger_before) ||
          (committed_words != commits_before) ||
          (load32(DST_BASE) !== dst_before))
        fail("empty SCALE changed child/portal/destination state");
      check_completion(profile, sequence_value, 0, `NPU_ERR_NONE, 32'd0,
                       64'd0, 64'd0, 64'd0, 64'd0, 64'd0,
                       64'd0, 64'd0, 64'd0, 64'd0);
    end
  endtask

  task automatic run_empty_reject(input integer profile,
                                  input integer mutation,
                                  input [63:0] sequence_value);
    integer commits_before;
    integer guard;
    reg [63:0] f32_starts_before;
    reg [512:0] ledger_before;
    reg [`NPU_ERROR_W-1:0] expected_code;
    reg [31:0] expected_class;
    begin
      poison_destination(1);
      commits_before = committed_words;
      f32_starts_before = macro_f32_start_count;
      ledger_before = portal_ledger_bus;
      expected_code = mutation == 2 ? `NPU_ERR_MACRO_ABI :
                      (mutation == 3 ? `NPU_ERR_MACRO_CAPABILITY :
                                       `NPU_ERR_MACRO_LAYOUT);
      expected_class = mutation == 2 ? ABI_ERROR_ABI :
                       (mutation == 3 ? ABI_ERROR_CAPABILITY :
                                        ABI_ERROR_LAYOUT);
      issue_malformed_empty(profile, mutation, sequence_value);
      guard = 0;
      while (!completion_valid) begin
        step_cycle();
        guard = guard + 1;
        if (f32_req_valid || f32_rsp_ready || portal_outstanding ||
            gmem_req_valid || gmem_rsp_ready ||
            (portal_ledger_bus !== ledger_before))
          fail("malformed empty SCALE leaked a child or memory transaction");
        if (guard > 100)
          fail("malformed empty SCALE completion timeout");
      end
      check_completion(profile, sequence_value, 1, expected_code,
                       expected_class, 64'd0,
                       64'd0, 64'd0, 64'd0, 64'd0,
                       64'd0, 64'd0, 64'd0, 64'd0);
      if ((macro_f32_start_count !== f32_starts_before) ||
          (committed_words != commits_before) ||
          (load32(DST_BASE) !== POISON_BITS))
        fail("malformed empty SCALE reached the child or destination");
    end
  endtask

  task automatic send_fault_response(input integer response_error);
    integer wait_index;
    reg [63:0] responses_before;
    begin
      for (wait_index = 0; wait_index < 3; wait_index = wait_index + 1) begin
        step_cycle();
        if (!portal_outstanding || completion_valid)
          fail("terminal published before accepted response was drained");
      end
      f32_rsp_src0_data = {(LANES*32){1'b0}};
      f32_rsp_src1_data = {(LANES*32){1'b0}};
      f32_rsp_mask = response_error ? pending_mask : 8'hfe;
      f32_rsp_error = response_error[0];
      responses_before = portal_response_groups;
      @(negedge clk);
      f32_rsp_valid = 1'b1;
      step_cycle();
      f32_rsp_valid = 1'b0;
      f32_rsp_error = 1'b0;
      f32_rsp_mask = {LANES{1'b0}};
      if (portal_outstanding
          || (portal_response_groups != responses_before + 64'd1))
        fail("fault response did not drain exactly once");
    end
  endtask

  task automatic run_fault(input integer response_error,
                           input [63:0] sequence_value);
    integer commits_before;
    begin
      poison_destination(P00_TOTAL);
      commits_before = committed_words;
      issue_macro(0, sequence_value);
      accept_request(0, 0, 0);
      send_fault_response(response_error);
      if (response_error) begin
        check_completion(0, sequence_value, 1, `NPU_ERR_GMEM_RESPONSE,
                         ABI_ERROR_GMEM, 64'b0,
                         64'd1, 64'd1, 64'd1, 64'd0,
                         64'd0, 64'd0, 64'd0, 64'd0);
      end else begin
        check_completion(0, sequence_value, 1, `NPU_ERR_MACRO_PROTOCOL,
                         ABI_ERROR_PROTOCOL, 64'b0,
                         64'd1, 64'd1, 64'd1, 64'd0,
                         64'd0, 64'd0, 64'd0, 64'd0);
      end
      if (committed_words != commits_before)
        fail("faulting command produced a successful portal write commit");
      verify_destination_poison(P00_TOTAL);
    end
  endtask

  integer init_index;
  initial begin
    rst = 1'b1;
    macro_cmd_valid = 1'b0;
    completion_ready = 1'b0;
    f32_req_ready = 1'b0;
    f32_rsp_valid = 1'b0;
    f32_rsp_mask = {LANES{1'b0}};
    f32_rsp_src0_data = {(LANES*32){1'b0}};
    f32_rsp_src1_data = {(LANES*32){1'b0}};
    f32_rsp_error = 1'b0;
    error_clear = 1'b0;
    oracle_req_valid = 1'b0;
    oracle_op_mul = 1'b0;
    oracle_lhs = 32'b0;
    oracle_rhs = 32'b0;
    oracle_rsp_ready = 1'b0;
    pending_write = 1'b0;
    pending_mask = {LANES{1'b0}};
    pending_src0_addr = {(LANES*64){1'b0}};
    pending_src1_addr = {(LANES*64){1'b0}};
    pending_dst_addr = {(LANES*64){1'b0}};
    pending_wdata = {(LANES*32){1'b0}};
    global_cycles = 0;
    checks = 0;
    accepted_commands = 0;
    accepted_completions = 0;
    request_hold_cycles = 0;
    response_hold_cycles = 0;
    completion_hold_cycles = 0;
    committed_words = 0;
    for (init_index = 0; init_index < MEM_BYTES; init_index = init_index + 1)
      memory[init_index] = 8'hc3 ^ init_index[7:0];
    setup_descriptor(0, 64'd1);
    load_fixtures();
    poison_destination(P16_TOTAL);

    repeat (5) step_cycle();
    // Coprocessor command ready is intentionally a pure IDLE/sticky-error
    // function and may be high during reset.  Transaction-producing valids and
    // the numerical child ready must remain quiescent.
    if (oracle_req_ready || f32_req_valid || f32_rsp_ready
        || completion_valid || portal_outstanding)
      fail("reset leaked a portal/numeric transaction");
    @(negedge clk);
    rst = 1'b0;
    step_cycle();
    if (!macro_cmd_ready || !oracle_req_ready || busy || sticky_error)
      fail("idle readiness missing after reset");

    build_oracles();

    // Both steady-state cache profiles close as real REQUIRED transactions
    // with zero child starts and zero raw32/public GMEM traffic.  A near miss
    // must be rejected by the ordinary adapter contract.
    run_empty_success(17, 64'h0000_0000_0000_0017);
    run_empty_success(18, 64'h0000_0000_0000_0018);
    run_empty_reject(17, 0, 64'h0000_0000_0000_0020);
    run_empty_reject(16, 1, 64'h0000_0000_0000_0021);
    run_empty_reject(17, 2, 64'h0000_0000_0000_0022);
    run_empty_reject(17, 3, 64'h0000_0000_0000_0023);
    run_empty_reject(17, 4, 64'h0000_0000_0000_0024);
    run_empty_reject(17, 5, 64'h0000_0000_0000_0025);
    run_empty_reject(17, 6, 64'h0000_0000_0000_0026);
    run_empty_reject(17, 7, 64'h0000_0000_0000_0027);
    run_empty_reject(17, 8, 64'h0000_0000_0000_0028);
    run_empty_reject(17, 9, 64'h0000_0000_0000_0029);
    run_empty_reject(17, 10, 64'h0000_0000_0000_002a);

    // P00 is frozen at 16 elements.  With production LANES=8 it is exactly
    // two full groups; tail-mask behavior is covered by the adapter-level TB.
    run_success(0, 64'h0000_0000_0000_0100);
    run_success(16, 64'h0000_0000_0000_0110);

    // Lowest-level response-mask mismatch maps to the public macro protocol
    // class; a transport error maps to GMEM.  Both are injected on the first
    // read so no write request or successful commit can exist.
    run_fault(0, 64'h0000_0000_0000_0200);
    run_fault(1, 64'h0000_0000_0000_0201);

    checks = checks + 1;
    if ((accepted_commands != 17) || (accepted_completions != 17)
        || (command_count != 64'd17) || (completion_count != 64'd4)
        || (error_count != 64'd13) || (npu_required_issued != 64'd17)
        || (npu_required_completed != 64'd4)
        || (macro_command_count != 64'd17)
        || (macro_completion_count != 64'd4)
        || (macro_f32_start_count != 64'd4)
        || (request_hold_cycles == 0) || (response_hold_cycles == 0)
        || (completion_hold_cycles == 0) || sticky_error || busy
        || !macro_cmd_ready || completion_valid || portal_outstanding)
      fail("aggregate counters/coverage markers did not close exactly");

    repeat (8) begin
      step_cycle();
      if (busy || sticky_error || completion_valid || f32_req_valid
          || f32_rsp_ready || portal_outstanding || !macro_cmd_ready)
        fail("final idle stability mismatch");
    end

    $display("[NPU-COPROCESSOR-F32-ALU-PORTAL][INFO] portal=1 lanes=8 P00=ADD/elements16/groups2/read128/write64 P16=SCALE/elements2048/groups256/read8192/write8192 P17/P18=steady-empty/child0/portal0 oracle=independent-public-AddMul raw32_specials=zeros,subnormals,finite,inf,qnan,snan malformed_empty=outer,p16,abi,epoch,count,scalar,src1,windows,iova,size,stride errors=ABI,CAPABILITY,LAYOUT,MACRO_PROTOCOL,GMEM completion_gmem=0/0 commands=17 success=4 errors=13 checks=%0d req_hold=%0d rsp_hold=%0d completion_hold=%0d assertions=off waveform=off",
             checks, request_hold_cycles, response_hold_cycles,
             completion_hold_cycles);
    $display("[NPU-COPROCESSOR-F32-ALU-PORTAL][PASS] portal=1 lanes=8 profiles=P00,P16,P17-empty,P18-empty scenarios=17 warnings=0 assertions=off waveform=off");
    $finish;
  end

endmodule

`default_nettype wire
