`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Public macro-port proof for the frozen F32 raw-bit GET_ROWS and REPEAT
// kernels.  The TB supplies only byte-addressed GMEM contents and compares raw
// result bits; every traversal/address calculation remains inside RTL.
module tb_coprocessor_f32_gather_repeat;

  localparam integer GMEM_BYTES = 16384;
  localparam integer MAX_WAIT_CYCLES = 250000;
  localparam [31:0] KERNEL_Q8_GET = 32'h514e0001;
  localparam [31:0] KERNEL_Q8_GEMV = 32'h514e0002;
  localparam [31:0] KERNEL_F32_GET = 32'h514e0003;
  localparam [31:0] KERNEL_F32_REPEAT = 32'h514e0004;
  localparam [31:0] KERNEL_VECTOR = 32'h514e0010;
  localparam [31:0] FLAGS_REQUIRED_PROFILE = 32'h00000011;
  localparam [31:0] FLAGS_PROFILE = 32'h00000010;

  localparam [63:0] GET_SRC = 64'h0000_0000_0000_0800;
  localparam [63:0] GET_IDX = 64'h0000_0000_0000_0900;
  localparam [63:0] GET_DST = 64'h0000_0000_0000_0a00;
  localparam [63:0] REP_SRC = 64'h0000_0000_0000_0b00;
  localparam [63:0] REP_DST = 64'h0000_0000_0000_0c00;
  localparam [63:0] GR_SRC = 64'h0000_0000_0000_0200;
  localparam [63:0] GR_IDX = 64'h0000_0000_0000_0280;
  localparam [63:0] GR_DST = 64'h0000_0000_0000_0340;
  localparam [63:0] VEC_SRC0 = 64'h0000_0000_0000_0600;
  localparam [63:0] VEC_SRC1 = 64'h0000_0000_0000_0680;
  localparam [63:0] VEC_DST = 64'h0000_0000_0000_0700;
  localparam [63:0] ACT_BASE = 64'h0000_0000_0000_1104;
  localparam [63:0] ACT_WIN = 64'h0000_0000_0000_1100;
  localparam [63:0] WT_BASE = 64'h0000_0000_0000_1502;
  localparam [63:0] WT_WIN = 64'h0000_0000_0000_1500;
  localparam [63:0] GEMV_DST = 64'h0000_0000_0000_1804;
  localparam [63:0] GEMV_DST_WIN = 64'h0000_0000_0000_1800;

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
  /* verilator lint_off UNUSEDSIGNAL */
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
  /* verilator lint_on UNUSEDSIGNAL */

  TensorNpuCoprocessor #(
    .LMEM_BYTES(512),
    .PID_W(8),
    .OPCLASS_W(8),
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
    .completion_macro_gmem_write_bytes_o(
        completion_macro_gmem_write_bytes),
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
    .q8_portal_req_valid_o(),
    .q8_portal_req_ready_i(1'b0),
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

  reg [7:0] gmem [0:GMEM_BYTES-1];
  reg [31:0] global_cycles;
  integer phase;
  integer checks;
  integer total_requests;
  integer total_reads;
  integer total_writes;
  integer accepted_commands;
  integer accepted_completions;
  integer backpressure_cycles;
  integer byte_index;
  integer lane;
  integer before_requests;
  integer before_reads;
  integer before_writes;

  reg pending;
  reg pending_write;
  reg [63:0] pending_addr;
  reg [63:0] pending_wdata;
  reg [7:0] pending_wstrb;
  reg [3:0] pending_delay;
  reg enable_backpressure;
  reg inject_any_read_error;
  reg inject_exact_read_error;
  reg [63:0] exact_read_error_addr;
  reg inject_exact_write_error;
  reg [63:0] exact_write_error_addr;
  reg saw_injected_fault;

  reg held_request;
  reg held_request_write;
  reg [63:0] held_request_addr;
  reg [63:0] held_request_wdata;
  reg [7:0] held_request_wstrb;

  reg [63:0] guard_src0_base;
  reg [63:0] guard_src0_size;
  reg [63:0] guard_src1_base;
  reg [63:0] guard_src1_size;
  reg [63:0] guard_dst_base;
  reg [63:0] guard_dst_size;

  reg [31:0] expected_kernel;
  reg [31:0] expected_flags;
  reg [31:0] expected_vector_flags;
  reg [31:0] expected_context;
  reg [63:0] expected_sequence;
  reg [63:0] expected_producer;
  reg [63:0] expected_user;
  reg [31:0] expected_node_count;
  reg [63:0] expected_hash_lo;
  reg [63:0] expected_hash_hi;
  reg expected_required;
  reg expected_completion_error;
  reg [`NPU_ERROR_W-1:0] expected_error_code;
  reg [31:0] expected_error_class;
  reg [63:0] expected_read_bytes;
  reg [63:0] expected_write_bytes;
  reg [63:0] expected_q8_macs;
  reg [63:0] expected_vector_elements;
  reg [63:0] held_completion_cycles;

  wire pending_response_error = pending_write ?
      (inject_exact_write_error &&
       (pending_addr == exact_write_error_addr)) :
      (inject_any_read_error ||
       (inject_exact_read_error &&
        (pending_addr == exact_read_error_addr)));

  assign gmem_req_ready = !rst && !pending && !gmem_rsp_valid &&
      (!enable_backpressure || (global_cycles[1:0] == 2'b11));

  initial clk = 1'b0;
  always #5 clk <= ~clk;

  task automatic fail;
    input string reason;
    begin
      $display("[NPU-COPROCESSOR-F32-GATHER-REPEAT][FAIL] %s cycle=%0d phase=%0d state=%0d req=%0d/%0d/%0d",
               reason, global_cycles, phase, dut.state_q,
               total_requests, total_reads, total_writes);
      $display("[NPU-COPROCESSOR-F32-GATHER-REPEAT][EVIDENCE] valid=%0b error=%0b/%0d class=%0d read=%0d write=%0d mac=%0d elems=%0d aggregate command=%0d completion=%0d error=%0d required=%0d/%0d macro=%0d/%0d f32=%0d",
               completion_valid, completion_error, completion_error_code,
               completion_macro_error_class,
               completion_macro_gmem_read_bytes,
               completion_macro_gmem_write_bytes,
               completion_macro_q8_mac_count,
               completion_macro_vector_element_count,
               command_count, completion_count, error_count,
               npu_required_issued, npu_required_completed,
               macro_command_count, macro_completion_count,
               macro_f32_start_count);
      $fatal(1);
    end
  endtask

  function automatic [63:0] load64_local;
    input [63:0] address;
    integer base;
    integer k;
    begin
      base = {18'd0, address[13:0]};
      load64_local = 64'd0;
      for (k = 0; k < 8; k = k + 1)
        load64_local[k*8 +: 8] = gmem[base+k];
    end
  endfunction

  function automatic [31:0] load32_local;
    input [63:0] address;
    integer base;
    begin
      base = {18'd0, address[13:0]};
      load32_local = {gmem[base+3], gmem[base+2],
                      gmem[base+1], gmem[base]};
    end
  endfunction

  task automatic write_byte;
    input [63:0] address;
    input [7:0] bits;
    begin
      if ((address >= 64'(GMEM_BYTES)) || (address[63:14] != 50'd0))
        fail("fixture byte escaped local GMEM");
      gmem[address[13:0]] = bits;
    end
  endtask

  task automatic write_u32;
    input [63:0] address;
    input [31:0] bits;
    begin
      write_byte(address + 64'd0, bits[7:0]);
      write_byte(address + 64'd1, bits[15:8]);
      write_byte(address + 64'd2, bits[23:16]);
      write_byte(address + 64'd3, bits[31:24]);
    end
  endtask

  task automatic write_q8_block;
    input [63:0] address;
    input [15:0] scale;
    input [7:0] default_q;
    integer qlane;
    begin
      write_byte(address, scale[7:0]);
      write_byte(address + 64'd1, scale[15:8]);
      for (qlane = 0; qlane < 32; qlane = qlane + 1)
        write_byte(address + 64'd2 + 64'(qlane), default_q);
    end
  endtask

  task automatic write_q8_lane;
    input [63:0] address;
    input integer qlane;
    input [7:0] bits;
    begin
      write_byte(address + 64'd2 + 64'(qlane), bits);
    end
  endtask

  task automatic poison_destination;
    input [63:0] address;
    input integer count;
    integer k;
    begin
      for (k = 0; k < count; k = k + 1)
        write_byte(address + 64'(k), 8'ha5);
    end
  endtask

  // Single-outstanding raw GMEM responder.  Error writes never update the
  // private byte array, and successful writes update only strobed lanes.
  always @(posedge clk) begin
    if (rst) begin
      global_cycles <= 32'd0;
      pending <= 1'b0;
      pending_write <= 1'b0;
      pending_addr <= 64'd0;
      pending_wdata <= 64'd0;
      pending_wstrb <= 8'd0;
      pending_delay <= 4'd0;
      gmem_rsp_valid <= 1'b0;
      gmem_rsp_rdata <= 64'd0;
      gmem_rsp_error <= 1'b0;
      total_requests <= 0;
      total_reads <= 0;
      total_writes <= 0;
      accepted_commands <= 0;
      accepted_completions <= 0;
      backpressure_cycles <= 0;
      saw_injected_fault <= 1'b0;
      held_request <= 1'b0;
      held_request_write <= 1'b0;
      held_request_addr <= 64'd0;
      held_request_wdata <= 64'd0;
      held_request_wstrb <= 8'd0;
    end else begin
      global_cycles <= global_cycles + 32'd1;
      if (global_cycles > 32'(MAX_WAIT_CYCLES * 12))
        fail("global watchdog expired");

      if (macro_cmd_valid && macro_cmd_ready)
        accepted_commands <= accepted_commands + 1;
      if (completion_valid && completion_ready)
        accepted_completions <= accepted_completions + 1;

      if (held_request &&
          (!gmem_req_valid ||
           (gmem_req_write != held_request_write) ||
           (gmem_req_addr != held_request_addr) ||
           (gmem_req_wdata != held_request_wdata) ||
           (gmem_req_wstrb != held_request_wstrb)))
        fail("public GMEM request changed under backpressure");
      if (gmem_req_valid && !gmem_req_ready) begin
        backpressure_cycles <= backpressure_cycles + 1;
        held_request <= 1'b1;
        held_request_write <= gmem_req_write;
        held_request_addr <= gmem_req_addr;
        held_request_wdata <= gmem_req_wdata;
        held_request_wstrb <= gmem_req_wstrb;
      end else begin
        held_request <= 1'b0;
      end

      // Four physical adapters implement five logical kernel identities.
      // Every inactive requester must observe zero public credit/response.
      if (dut.macro_select_f32_move_w &&
          (dut.macro_gmem_req_ready_w || dut.macro_gmem_rsp_valid_w ||
           (dut.macro_gmem_rsp_rdata_w != 64'd0) ||
           dut.macro_gmem_rsp_error_w ||
           dut.q8_gmem_req_ready_w || dut.q8_gmem_rsp_valid_w ||
           (dut.q8_gmem_rsp_rdata_w != 64'd0) ||
           dut.q8_gmem_rsp_error_w ||
           dut.gemv_gmem_req_ready_w || dut.gemv_gmem_rsp_valid_w ||
           (dut.gemv_gmem_rsp_rdata_w != 64'd0) ||
           dut.gemv_gmem_rsp_error_w))
        fail("inactive adapter received F32 mover credit");
      if (!dut.macro_select_f32_move_w &&
          (dut.f32_move_gmem_req_ready_w ||
           dut.f32_move_gmem_rsp_valid_w ||
           (dut.f32_move_gmem_rsp_rdata_w != 64'd0) ||
           dut.f32_move_gmem_rsp_error_w))
        fail("inactive F32 mover received public credit");
      if ((dut.macro_gmem_req_valid_w && dut.q8_gmem_req_valid_w) ||
          (dut.macro_gmem_req_valid_w && dut.gemv_gmem_req_valid_w) ||
          (dut.macro_gmem_req_valid_w &&
           dut.f32_move_gmem_req_valid_w) ||
          (dut.q8_gmem_req_valid_w && dut.gemv_gmem_req_valid_w) ||
          (dut.q8_gmem_req_valid_w && dut.f32_move_gmem_req_valid_w) ||
          (dut.gemv_gmem_req_valid_w &&
           dut.f32_move_gmem_req_valid_w))
        fail("two macro adapters requested GMEM concurrently");
      if (dut.macro_select_f32_get_w && dut.macro_select_f32_repeat_w)
        fail("two F32 logical kernel identities selected together");

      if (gmem_rsp_valid && gmem_rsp_ready) begin
        gmem_rsp_valid <= 1'b0;
        gmem_rsp_rdata <= 64'd0;
        gmem_rsp_error <= 1'b0;
        pending <= 1'b0;
      end

      if (pending && !gmem_rsp_valid) begin
        if (pending_delay == 4'd0) begin
          gmem_rsp_error <= pending_response_error;
          gmem_rsp_rdata <= 64'd0;
          if (pending_response_error)
            saw_injected_fault <= 1'b1;
          if (!pending_response_error) begin
            if ((pending_addr[63:14] != 50'd0) ||
                ({50'd0, pending_addr[13:0]} + 64'd8 >
                 64'(GMEM_BYTES)))
              fail("successful response escaped local GMEM");
            if (pending_write) begin
              for (lane = 0; lane < 8; lane = lane + 1)
                if (pending_wstrb[lane])
                  gmem[{18'd0, pending_addr[13:0]} + lane] <=
                      pending_wdata[lane*8 +: 8];
            end else begin
              gmem_rsp_rdata <= load64_local(pending_addr);
            end
          end
          gmem_rsp_valid <= 1'b1;
        end else begin
          pending_delay <= pending_delay - 4'd1;
        end
      end

      if (gmem_req_valid && gmem_req_ready) begin
        if (pending || gmem_rsp_valid)
          fail("more than one public GMEM request was outstanding");
        if (gmem_req_addr[2:0] != 3'b000)
          fail("public GMEM request was not beat aligned");
        if (gmem_req_write &&
            (gmem_req_wstrb != 8'h0f) && (gmem_req_wstrb != 8'hf0))
          fail("public FP32 write used an invalid strobe");
        if (!gmem_req_write &&
            ((gmem_req_wdata != 64'd0) || (gmem_req_wstrb != 8'd0)))
          fail("public read carried a write payload");
        if (gmem_req_write) begin
          if ((gmem_req_addr < guard_dst_base) ||
              (gmem_req_addr + 64'd8 > guard_dst_base + guard_dst_size))
            fail("write escaped resident private destination capability");
        end else if (!(((gmem_req_addr >= guard_src0_base) &&
                         (gmem_req_addr + 64'd8 <=
                          guard_src0_base + guard_src0_size)) ||
                        ((guard_src1_size != 64'd0) &&
                         (gmem_req_addr >= guard_src1_base) &&
                         (gmem_req_addr + 64'd8 <=
                          guard_src1_base + guard_src1_size)))) begin
          fail("read escaped resident source capability");
        end

        pending <= 1'b1;
        pending_write <= gmem_req_write;
        pending_addr <= gmem_req_addr;
        pending_wdata <= gmem_req_wdata;
        pending_wstrb <= gmem_req_wstrb;
        pending_delay <= gmem_req_write ? 4'd2 : 4'd1;
        total_requests <= total_requests + 1;
        if (gmem_req_write)
          total_writes <= total_writes + 1;
        else
          total_reads <= total_reads + 1;
      end
    end
  end

  task automatic configure_identity;
    input [63:0] sequence_value;
    begin
      macro_abi_valid = 1'b1;
      macro_context_id = 32'hf320_0000 | {16'd0, sequence_value[15:0]};
      macro_capability_epoch = 32'h0000_0001;
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
    end
  endtask

  task automatic clear_injection;
    begin
      inject_any_read_error = 1'b0;
      inject_exact_read_error = 1'b0;
      exact_read_error_addr = 64'd0;
      inject_exact_write_error = 1'b0;
      exact_write_error_addr = 64'd0;
      enable_backpressure = 1'b1;
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

  task automatic check_completion_payload;
    begin
      checks = checks + 1;
      if (!completion_valid || !completion_is_macro ||
          (completion_producer_id != 8'd0) ||
          (completion_opclass != 8'd0) ||
          (completion_npu_required != expected_required) ||
          (completion_error != expected_completion_error) ||
          (completion_error_code != expected_error_code) ||
          (completion_macro_status !=
           (expected_completion_error ? {24'd0, expected_error_code} :
                                        32'd0)) ||
          (completion_macro_error_class != expected_error_class) ||
          (completion_macro_kernel_id != expected_kernel) ||
          (completion_macro_command_flags != expected_flags) ||
          (completion_macro_vector_flags != expected_vector_flags) ||
          (completion_macro_context_id != expected_context) ||
          (completion_macro_sequence_id != expected_sequence) ||
          (completion_macro_producer_id != expected_producer) ||
          (completion_macro_user_tag != expected_user) ||
          (completion_macro_covered_node_count != expected_node_count) ||
          (completion_macro_node_hash_lo != expected_hash_lo) ||
          (completion_macro_node_hash_hi != expected_hash_hi) ||
          (completion_macro_gmem_read_bytes != expected_read_bytes) ||
          (completion_macro_gmem_write_bytes != expected_write_bytes) ||
          (completion_macro_q8_mac_count != expected_q8_macs) ||
          (completion_macro_vector_element_count !=
           expected_vector_elements) ||
          (completion_macro_state_update_count != 64'd0) ||
          (completion_macro_npu_cycles == 64'd0))
        fail("macro completion identity/counter payload mismatch");
    end
  endtask

  task automatic execute_macro;
    input integer new_phase;
    input expected_error;
    input [`NPU_ERROR_W-1:0] terminal_code;
    input [31:0] terminal_class;
    input [63:0] read_bytes;
    input [63:0] write_bytes;
    input [63:0] q8_macs;
    input [63:0] vector_elements;
    integer waited;
    integer hold_index;
    begin
      phase = new_phase;
      expected_kernel = macro_kernel_id;
      expected_flags = macro_command_flags;
      expected_vector_flags = macro_vector_flags;
      expected_context = macro_context_id;
      expected_sequence = macro_sequence_id;
      expected_producer = macro_producer_id;
      expected_user = macro_user_tag;
      expected_node_count = macro_node_count;
      expected_hash_lo = macro_node_hash_lo;
      expected_hash_hi = macro_node_hash_hi;
      expected_required = macro_command_flags[0];
      expected_completion_error = expected_error;
      expected_error_code = terminal_code;
      expected_error_class = terminal_class;
      expected_read_bytes = read_bytes;
      expected_write_bytes = write_bytes;
      expected_q8_macs = q8_macs;
      expected_vector_elements = vector_elements;
      guard_src0_base = macro_src0_window_base;
      guard_src0_size = macro_src0_window_size;
      guard_src1_base = macro_src1_window_base;
      guard_src1_size = macro_src1_window_size;
      guard_dst_base = macro_dst_window_base;
      guard_dst_size = macro_dst_window_size;

      waited = 0;
      while (!macro_cmd_ready && (waited < 100)) begin
        @(posedge clk);
        waited = waited + 1;
      end
      if (!macro_cmd_ready)
        fail("macro command did not become ready");
      @(negedge clk);
      macro_cmd_valid = 1'b1;
      @(posedge clk);
      @(negedge clk);
      macro_cmd_valid = 1'b0;
      poison_live_descriptor();

      waited = 0;
      while (!completion_valid && (waited < MAX_WAIT_CYCLES)) begin
        @(posedge clk);
        waited = waited + 1;
      end
      if (!completion_valid)
        fail("macro command timed out waiting for completion");
      @(negedge clk);
      check_completion_payload();
      held_completion_cycles = completion_macro_npu_cycles;
      for (hold_index = 0; hold_index < 3;
           hold_index = hold_index + 1) begin
        @(posedge clk);
        @(negedge clk);
        check_completion_payload();
        if (completion_macro_npu_cycles != held_completion_cycles)
          fail("completion payload changed under backpressure");
      end

      completion_ready = 1'b1;
      @(posedge clk);
      @(negedge clk);
      completion_ready = 1'b0;
      if (completion_valid)
        fail("completion did not retire on ready handshake");
    end
  endtask

  task automatic clear_terminal_error;
    begin
      if (!sticky_error || macro_cmd_ready)
        fail("terminal error did not enter fail-closed hold");
      @(negedge clk);
      error_clear = 1'b1;
      @(posedge clk);
      @(negedge clk);
      error_clear = 1'b0;
      if (sticky_error || !macro_cmd_ready)
        fail("error_clear did not reopen macro admission");
    end
  endtask

  task automatic configure_f32_get_small;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_F32_GET;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = GET_SRC;
      macro_src1_iova = GET_IDX;
      macro_src2_iova = 64'd0;
      macro_dst_iova = GET_DST;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd3;
      macro_outer_count = 32'd2;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd16;
      macro_src1_stride = 64'd8;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd16;
      macro_scalar0 = 32'd3;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = GET_SRC;
      macro_src0_window_size = 64'd48;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = GET_IDX;
      macro_src1_window_size = 64'd16;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = GET_DST;
      macro_dst_window_size = 64'd32;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      clear_injection();
    end
  endtask

  task automatic configure_f32_repeat_small;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_F32_REPEAT;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = REP_SRC;
      macro_src1_iova = 64'd0;
      macro_src2_iova = 64'd0;
      macro_dst_iova = REP_DST;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd2;
      macro_outer_count = 32'd2;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd16;
      macro_src1_stride = 64'd0;
      macro_src2_stride = 64'd32;
      macro_dst_stride = 64'd8;
      macro_scalar0 = 32'd3;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = REP_SRC;
      macro_src0_window_size = 64'd24;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = 64'd0;
      macro_src1_window_size = 64'd0;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = REP_DST;
      macro_dst_window_size = 64'd56;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      clear_injection();
    end
  endtask

  task automatic configure_empty_get;
    input [31:0] dimension;
    input [63:0] sequence_value;
    reg [63:0] row_bytes;
    begin
      configure_identity(sequence_value);
      row_bytes = {32'd0, dimension} * 64'd4;
      macro_kernel_id = KERNEL_F32_GET;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = 64'h0000_0004_0000_0000;
      macro_src1_iova = 64'h0000_0005_0000_0000;
      macro_src2_iova = 64'd0;
      macro_dst_iova = 64'h0000_0006_0000_0000;
      macro_scratch_iova = 64'd0;
      macro_element_count = {32'd0, dimension};
      macro_outer_count = 32'd0;
      macro_dtype = 32'd1;
      macro_src0_stride = row_bytes;
      macro_src1_stride = 64'd4;
      macro_src2_stride = 64'd0;
      macro_dst_stride = row_bytes;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = macro_src0_iova;
      macro_src0_window_size = 64'd0;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = macro_src1_iova;
      macro_src1_window_size = 64'd0;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = macro_dst_iova;
      macro_dst_window_size = 64'd0;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      clear_injection();
    end
  endtask

  task automatic configure_get_profile;
    input [31:0] dimension;
    input [63:0] sequence_value;
    reg [63:0] row_bytes;
    begin
      configure_identity(sequence_value);
      row_bytes = {32'd0, dimension} * 64'd4;
      macro_kernel_id = KERNEL_F32_GET;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_window_base = 64'h0000_0001_0000_1000;
      macro_src0_iova = macro_src0_window_base + 64'd4;
      macro_src1_window_base = GET_IDX;
      macro_src1_iova = GET_IDX;
      macro_src2_iova = 64'd0;
      macro_dst_window_base = 64'h0000_0003_0000_1000;
      macro_dst_iova = macro_dst_window_base + 64'd4;
      macro_scratch_iova = 64'd0;
      macro_element_count = {32'd0, dimension};
      macro_outer_count = 32'd1;
      macro_dtype = 32'd1;
      macro_src0_stride = row_bytes;
      macro_src1_stride = 64'd4;
      macro_src2_stride = 64'd0;
      macro_dst_stride = row_bytes;
      macro_scalar0 = 32'd1;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_size = row_bytes + 64'd8;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_size = 64'd8;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_size = row_bytes + 64'd8;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      write_u32(GET_IDX, 32'd0);
      clear_injection();
      inject_exact_read_error = 1'b1;
      exact_read_error_addr = macro_src0_window_base;
    end
  endtask

  task automatic configure_repeat_profile;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_F32_REPEAT;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_window_base = 64'h0000_0001_1000_1000;
      macro_src0_iova = macro_src0_window_base + 64'd4;
      macro_src1_iova = 64'd0;
      macro_src2_iova = 64'd0;
      macro_dst_window_base = 64'h0000_0003_1000_1000;
      macro_dst_iova = macro_dst_window_base + 64'd4;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd128;
      macro_outer_count = 32'd16;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd512;
      macro_src1_stride = 64'd0;
      macro_src2_stride = 64'd65536;
      macro_dst_stride = 64'd512;
      macro_scalar0 = 32'd128;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_size = 64'd8200;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = 64'd0;
      macro_src1_window_size = 64'd0;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_size = 64'd1048584;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      clear_injection();
      inject_exact_read_error = 1'b1;
      exact_read_error_addr = macro_src0_window_base;
    end
  endtask

  task automatic configure_q8_get;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_Q8_GET;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = GR_SRC;
      macro_src1_iova = GR_IDX;
      macro_src2_iova = 64'd0;
      macro_dst_iova = GR_DST;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd32;
      macro_outer_count = 32'd1;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd40;
      macro_src1_stride = 64'd4;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd128;
      macro_scalar0 = 32'd1;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = GR_SRC;
      macro_src0_window_size = 64'd40;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = GR_IDX;
      macro_src1_window_size = 64'd8;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = GR_DST;
      macro_dst_window_size = 64'd128;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      clear_injection();
    end
  endtask

  task automatic configure_q8_gemv;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_Q8_GEMV;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = ACT_BASE;
      macro_src1_iova = WT_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = GEMV_DST;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd64;
      macro_outer_count = 32'd2;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd0;
      macro_src1_stride = 64'd72;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd12;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = ACT_WIN;
      macro_src0_window_size = 64'h108;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = WT_WIN;
      macro_src1_window_size = 64'h90;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = GEMV_DST_WIN;
      macro_dst_window_size = 64'h18;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      clear_injection();
    end
  endtask

  task automatic configure_vector;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_VECTOR;
      macro_command_flags = FLAGS_PROFILE;
      macro_vector_op = 32'd1;
      macro_vector_flags = 32'd0;
      macro_src0_iova = VEC_SRC0;
      macro_src1_iova = VEC_SRC1;
      macro_src2_iova = 64'd0;
      macro_dst_iova = VEC_DST;
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
      macro_src0_window_base = VEC_SRC0;
      macro_src0_window_size = 64'd64;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = VEC_SRC1;
      macro_src1_window_size = 64'd64;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = VEC_DST;
      macro_dst_window_size = 64'd64;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      clear_injection();
    end
  endtask

  task automatic load_f32_fixtures;
    begin
      // Three table rows with padding; indices select row 2 then row 0.
      write_u32(GET_SRC + 64'd0, 32'h3f800001);
      write_u32(GET_SRC + 64'd4, 32'h40000002);
      write_u32(GET_SRC + 64'd8, 32'h40400003);
      write_u32(GET_SRC + 64'd16, 32'h41200011);
      write_u32(GET_SRC + 64'd20, 32'h41300012);
      write_u32(GET_SRC + 64'd24, 32'h41400013);
      write_u32(GET_SRC + 64'd32, 32'hbf800021);
      write_u32(GET_SRC + 64'd36, 32'hc0000022);
      write_u32(GET_SRC + 64'd40, 32'hc0400023);
      write_u32(GET_IDX + 64'd0, 32'd2);
      write_u32(GET_IDX + 64'd8, 32'd0);
      poison_destination(GET_DST, 32);

      write_u32(REP_SRC + 64'd0, 32'h7fc00001);
      write_u32(REP_SRC + 64'd4, 32'h80000000);
      write_u32(REP_SRC + 64'd16, 32'h00000001);
      write_u32(REP_SRC + 64'd20, 32'hff800000);
      poison_destination(REP_DST, 64);
    end
  endtask

  task automatic load_legacy_fixtures;
    integer k;
    integer qlane;
    begin
      write_q8_block(GR_SRC, 16'h3c00, 8'h00);
      for (k = 34; k < 40; k = k + 1)
        write_byte(GR_SRC + 64'(k), 8'h00);
      for (k = 0; k < 8; k = k + 1)
        write_byte(GR_IDX + 64'(k), 8'h00);
      poison_destination(GR_DST, 128);

      for (k = 0; k < 64; k = k + 1) begin
        write_byte(VEC_SRC0 + 64'(k), 8'h00);
        write_byte(VEC_SRC1 + 64'(k), 8'h00);
        write_byte(VEC_DST + 64'(k), 8'ha5);
      end

      write_u32(ACT_BASE + 64'd0, 32'hc2fe0000);
      write_u32(ACT_BASE + 64'd4, 32'hc2800000);
      write_u32(ACT_BASE + 64'd8, 32'hbf800000);
      write_u32(ACT_BASE + 64'd12, 32'h00000000);
      write_u32(ACT_BASE + 64'd16, 32'h3f800000);
      write_u32(ACT_BASE + 64'd20, 32'h427c0000);
      write_u32(ACT_BASE + 64'd24, 32'h42800000);
      write_u32(ACT_BASE + 64'd28, 32'h42fe0000);
      for (qlane = 8; qlane < 32; qlane = qlane + 1)
        write_u32(ACT_BASE + (64'(qlane) * 64'd4), 32'd0);
      for (qlane = 0; qlane < 32; qlane = qlane + 1)
        write_u32(ACT_BASE + ((64'd32 + 64'(qlane)) * 64'd4),
                  32'h42fe0000);
      write_q8_block(WT_BASE, 16'h3c00, 8'h00);
      write_q8_lane(WT_BASE, 0, 8'h81);
      write_q8_lane(WT_BASE, 1, 8'hc0);
      write_q8_lane(WT_BASE, 2, 8'hff);
      write_q8_lane(WT_BASE, 3, 8'h00);
      write_q8_lane(WT_BASE, 4, 8'h01);
      write_q8_lane(WT_BASE, 5, 8'h3f);
      write_q8_lane(WT_BASE, 6, 8'h40);
      write_q8_lane(WT_BASE, 7, 8'h7f);
      write_q8_block(WT_BASE + 64'd34, 16'h3c00, 8'h01);
      write_q8_block(WT_BASE + 64'd72, 16'h3800, 8'h02);
      write_q8_block(WT_BASE + 64'd106, 16'hc000, 8'h01);
      poison_destination(GEMV_DST_WIN, 24);
    end
  endtask

  task automatic run_empty_profile;
    input [31:0] dimension;
    input [63:0] sequence_value;
    begin
      configure_empty_get(dimension, sequence_value);
      before_requests = total_requests;
      execute_macro(phase + 1, 1'b0, `NPU_ERR_NONE, 32'd0,
                    64'd0, 64'd0, 64'd0, 64'd0);
      checks = checks + 1;
      if ((total_requests != before_requests) ||
          (dut.f32_move_d_ext_w != {96'd0, dimension}) ||
          (dut.f32_move_total_outputs_ext_w != 128'd0) ||
          (dut.f32_move_read_words_ext_w != 128'd0))
        fail("canonical N=0 profile was not zero-traffic success");
    end
  endtask

  task automatic run_get_profile;
    input [31:0] dimension;
    input [63:0] sequence_value;
    reg [127:0] expected_src_end;
    reg [127:0] expected_dst_end;
    begin
      configure_get_profile(dimension, sequence_value);
      expected_src_end = {64'd0, macro_src0_iova} +
                         ({96'd0, dimension} * 128'd4);
      expected_dst_end = {64'd0, macro_dst_iova} +
                         ({96'd0, dimension} * 128'd4);
      before_requests = total_requests;
      execute_macro(phase + 1, 1'b1, `NPU_ERR_GMEM_RESPONSE, 32'd6,
                    64'd4, 64'd0, 64'd0, 64'd0);
      checks = checks + 1;
      if ((total_requests - before_requests != 2) ||
          !saw_injected_fault ||
          (dut.f32_move_src_end_ext_w != expected_src_end) ||
          (dut.f32_move_index_end_ext_w !=
           {64'd0, GET_IDX + 64'd4}) ||
          (dut.f32_move_dst_end_ext_w != expected_dst_end) ||
          (dut.f32_move_total_outputs_ext_w !=
           ({96'd0, dimension} * 128'd1)))
        fail("canonical GET_ROWS widened boundary/profile mismatch");
      clear_terminal_error();
    end
  endtask

  task automatic run_repeat_profile;
    input [63:0] sequence_value;
    begin
      configure_repeat_profile(sequence_value);
      before_requests = total_requests;
      execute_macro(phase + 1, 1'b1, `NPU_ERR_GMEM_RESPONSE, 32'd6,
                    64'd0, 64'd0, 64'd0, 64'd0);
      checks = checks + 1;
      if ((total_requests - before_requests != 1) ||
          !saw_injected_fault ||
          (dut.f32_move_repeat_plane_ext_w != 128'd65536) ||
          (dut.f32_move_src_end_ext_w !=
           128'h0000_0000_0000_0000_0000_0001_1000_3004) ||
          (dut.f32_move_dst_end_ext_w !=
           128'h0000_0000_0000_0000_0000_0003_1010_1004) ||
          (dut.f32_move_total_outputs_ext_w != 128'd262144) ||
          (dut.f32_move_read_bytes_ext_w != 128'd8192) ||
          (dut.f32_move_write_bytes_ext_w != 128'd1048576))
        fail("canonical REPEAT widened boundary/profile mismatch");
      clear_terminal_error();
    end
  endtask

  initial begin
    rst = 1'b1;
    macro_cmd_valid = 1'b0;
    completion_ready = 1'b0;
    error_clear = 1'b0;
    phase = 0;
    checks = 0;
    enable_backpressure = 1'b1;
    inject_any_read_error = 1'b0;
    inject_exact_read_error = 1'b0;
    exact_read_error_addr = 64'd0;
    inject_exact_write_error = 1'b0;
    exact_write_error_addr = 64'd0;
    guard_src0_base = 64'd0;
    guard_src0_size = 64'd0;
    guard_src1_base = 64'd0;
    guard_src1_size = 64'd0;
    guard_dst_base = 64'd0;
    guard_dst_size = 64'd0;
    for (byte_index = 0; byte_index < GMEM_BYTES;
         byte_index = byte_index + 1)
      gmem[byte_index] = 8'ha7 ^ byte_index[7:0];
    load_f32_fixtures();
    load_legacy_fixtures();
    poison_live_descriptor();

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);

    // 1. Small GET_ROWS performs raw-bit gather, preserves padding and closes
    // semantic/physical counters exactly.
    configure_f32_get_small(64'hf320_0000_0000_0001);
    before_reads = total_reads;
    before_writes = total_writes;
    execute_macro(1, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd32, 64'd24, 64'd0, 64'd6);
    checks = checks + 1;
    if ((total_reads - before_reads != 8) ||
        (total_writes - before_writes != 6) ||
        (load32_local(GET_DST + 64'd0) != 32'hbf800021) ||
        (load32_local(GET_DST + 64'd4) != 32'hc0000022) ||
        (load32_local(GET_DST + 64'd8) != 32'hc0400023) ||
        (load32_local(GET_DST + 64'd16) != 32'h3f800001) ||
        (load32_local(GET_DST + 64'd20) != 32'h40000002) ||
        (load32_local(GET_DST + 64'd24) != 32'h40400003) ||
        (load32_local(GET_DST + 64'd12) != 32'ha5a5a5a5) ||
        (load32_local(GET_DST + 64'd28) != 32'ha5a5a5a5))
      fail("small GET_ROWS raw-bit oracle or exact counters mismatch");

    // 2. Small REPEAT reads each source word once and broadcasts raw bits.
    configure_f32_repeat_small(64'hf320_0000_0000_0002);
    before_reads = total_reads;
    before_writes = total_writes;
    execute_macro(2, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd16, 64'd48, 64'd0, 64'd12);
    checks = checks + 1;
    if ((total_reads - before_reads != 4) ||
        (total_writes - before_writes != 12))
      fail("small REPEAT request counters mismatch");
    for (lane = 0; lane < 3; lane = lane + 1) begin
      if ((load32_local(REP_DST + (64'(lane) * 64'd8)) !=
           32'h7fc00001) ||
          (load32_local(REP_DST + (64'(lane) * 64'd8) + 64'd4) !=
           32'h80000000) ||
          (load32_local(REP_DST + 64'd32 +
                        (64'(lane) * 64'd8)) != 32'h00000001) ||
          (load32_local(REP_DST + 64'd36 +
                        (64'(lane) * 64'd8)) != 32'hff800000))
        fail("small REPEAT raw-bit oracle mismatch");
    end

    // 3. Exact manifest zero-cardinality profiles are legal commits with no
    // source/index/destination traffic, even though D is large.
    run_empty_profile(32'd18432, 64'hf320_0000_0000_1840);
    run_empty_profile(32'd262144, 64'hf320_0000_0002_6214);

    // 4. Exact manifest N=1 profiles prove widened endpoints.  The local I32
    // zero index succeeds, then the first high-address source response fails.
    run_get_profile(32'd1024, 64'hf320_0000_0000_1024);
    run_get_profile(32'd18432, 64'hf320_0000_0001_8432);
    run_get_profile(32'd262144, 64'hf320_0000_0026_2144);

    // 5. Canonical [128,1,16] -> [128,128,16] repeat profile reaches its
    // selected owner after proving the full 1 MiB destination endpoint.
    run_repeat_profile(64'hf320_0000_0128_0016);

    // 6. Whole-descriptor rejection: one missing destination beat must emit
    // no GMEM request at all.
    configure_f32_get_small(64'hf320_0000_0000_0009);
    macro_dst_window_size = 64'd24;
    before_requests = total_requests;
    execute_macro(9, 1'b1, `NPU_ERR_MACRO_IOVA, 32'd5,
                  64'd0, 64'd0, 64'd0, 64'd0);
    if (total_requests != before_requests)
      fail("short F32 destination capability leaked partial traffic");
    clear_terminal_error();

    // 7. A late private write failure leaves the successful prefix private,
    // never increments success/REQUIRED-completed, and reports exact prefix
    // payload counters.
    poison_destination(REP_DST, 64);
    configure_f32_repeat_small(64'hf320_0000_0000_0010);
    inject_exact_write_error = 1'b1;
    exact_write_error_addr = REP_DST + 64'd8;
    before_reads = total_reads;
    before_writes = total_writes;
    execute_macro(10, 1'b1, `NPU_ERR_GMEM_RESPONSE, 32'd6,
                  64'd4, 64'd4, 64'd0, 64'd1);
    checks = checks + 1;
    if (!saw_injected_fault || (total_reads - before_reads != 1) ||
        (total_writes - before_writes != 2) ||
        (load32_local(REP_DST) != 32'h7fc00001) ||
        (load32_local(REP_DST + 64'd8) != 32'ha5a5a5a5) ||
        (completion_count != 64'd4) ||
        (macro_completion_count != 64'd4) ||
        (npu_required_completed != 64'd4))
      fail("late F32 write fault exposed commit or wrong prefix counters");
    clear_terminal_error();

    // 8. Frozen Q8 GET_ROWS dispatch remains functional and distinct.
    configure_q8_get(64'hf320_0000_0000_0011);
    before_reads = total_reads;
    before_writes = total_writes;
    execute_macro(11, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd48, 64'd128, 64'd0, 64'd32);
    if ((total_reads - before_reads != 6) ||
        (total_writes - before_writes != 32))
      fail("Q8 GET_ROWS dispatch/request counters regressed");
    for (lane = 0; lane < 32; lane = lane + 1)
      if (load32_local(GR_DST + (64'(lane) * 64'd4)) != 32'd0)
        fail("Q8 GET_ROWS numeric smoke regressed");

    // 9. Frozen Q8 GEMV M2/B2 numeric oracle remains bit exact.
    configure_q8_gemv(64'hf320_0000_0000_0012);
    before_reads = total_reads;
    before_writes = total_writes;
    execute_macro(12, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd408, 64'd8, 64'd128, 64'd2);
    if ((total_reads - before_reads != 51) ||
        (total_writes - before_writes != 2) ||
        (load32_local(GEMV_DST) != 32'h473d6500) ||
        (load32_local(GEMV_DST + 64'd12) != 32'hc5fc0800))
      fail("Q8 GEMV dispatch/numeric oracle regressed");

    // 10. Legacy VECTOR_F32 P00 remains independently selected.
    configure_vector(64'hf320_0000_0000_0013);
    before_requests = total_requests;
    before_reads = total_reads;
    before_writes = total_writes;
    execute_macro(13, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd128, 64'd64, 64'd0, 64'd16);
    if ((total_requests - before_requests != 32) ||
        (total_reads - before_reads != 16) ||
        (total_writes - before_writes != 16))
      fail("VECTOR dispatch/request counters regressed");
    for (lane = 0; lane < 16; lane = lane + 1)
      if (load32_local(VEC_DST + (64'(lane) * 64'd4)) != 32'd0)
        fail("VECTOR P00 numeric smoke regressed");

    checks = checks + 1;
    if ((accepted_commands != 13) || (accepted_completions != 13) ||
        (command_count != 64'd13) || (completion_count != 64'd7) ||
        (error_count != 64'd6) ||
        (npu_required_issued != 64'd12) ||
        (npu_required_completed != 64'd6) ||
        (macro_command_count != 64'd13) ||
        (macro_completion_count != 64'd7) ||
        (macro_f32_start_count != 64'd1) ||
        (backpressure_cycles == 0) || sticky_error || busy)
      fail("final five-kernel identity/REQUIRED/counter closure mismatch");

    $display("[NPU-COPROCESSOR-F32-GATHER-REPEAT][INFO] get=D3/N2/read32/write24/elements6 repeat=D2/O2/R3/read16/write48/elements12 empty=D18432+D262144/N0 profiles=get-D1024+D18432+D262144/N1 repeat-D128/O16/R128/1MiB late-fault=read4/write4/elements1/no-commit legacy=q8get+q8gemv+vector identity=full64+hash128 required=12/6 owner=five-logical/four-physical checks=%0d assertions=off waveform=off",
             checks);
    $display("[NPU-COPROCESSOR-F32-GATHER-REPEAT][PASS]");
    $finish;
  end

endmodule

`default_nettype wire
