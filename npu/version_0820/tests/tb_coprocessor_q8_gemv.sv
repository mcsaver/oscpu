`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Public macro-port proof for the Q8_0 GEMV dispatch entry.  This testbench
// transports only raw bytes.  All activation quantization, Q8 dot products,
// scale accumulation and FP32 result generation are performed by RTL.
module tb_coprocessor_q8_gemv;

  localparam integer GMEM_BYTES = 8192;
  localparam integer MAX_WAIT_CYCLES = 250000;
  localparam [31:0] KERNEL_GET_ROWS = 32'h514e0001;
  localparam [31:0] KERNEL_GEMV = 32'h514e0002;
  localparam [31:0] KERNEL_VECTOR = 32'h514e0010;
  localparam [31:0] FLAGS_REQUIRED_PROFILE = 32'h00000011;
  localparam [31:0] FLAGS_PROFILE = 32'h00000010;

  localparam [63:0] ACT_BASE = 64'h0000_0000_0000_1104;
  localparam [63:0] ACT_WIN  = 64'h0000_0000_0000_1100;
  localparam [63:0] WT_BASE  = 64'h0000_0000_0000_1502;
  localparam [63:0] WT_WIN   = 64'h0000_0000_0000_1500;
  localparam [63:0] DST_BASE = 64'h0000_0000_0000_1804;
  localparam [63:0] DST_WIN  = 64'h0000_0000_0000_1800;

  localparam [63:0] GR_SRC_BASE = 64'h0000_0000_0000_0200;
  localparam [63:0] GR_IDX_BASE = 64'h0000_0000_0000_0280;
  localparam [63:0] GR_DST_BASE = 64'h0000_0000_0000_0340;
  localparam [63:0] VEC_SRC0_BASE = 64'h0000_0000_0000_0600;
  localparam [63:0] VEC_SRC1_BASE = 64'h0000_0000_0000_0680;
  localparam [63:0] VEC_DST_BASE  = 64'h0000_0000_0000_0700;

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
  integer total_requests;
  integer total_read_requests;
  integer total_write_requests;
  integer accepted_commands;
  integer accepted_completions;
  integer backpressure_cycles;
  integer checks;
  integer lane;
  integer byte_index;
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
  reg saw_late_fault_addr;
  reg saw_profile_probe;

  reg held_request;
  reg held_request_write;
  reg [63:0] held_request_addr;
  reg [63:0] held_request_wdata;
  reg [7:0] held_request_wstrb;

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

  wire pending_response_error = !pending_write &&
      (inject_any_read_error ||
       (inject_exact_read_error && (pending_addr == exact_read_error_addr)));

  assign gmem_req_ready = !rst && !pending && !gmem_rsp_valid &&
      (!enable_backpressure || (global_cycles[1:0] == 2'b11));

  initial clk = 1'b0;
  always #5 clk <= ~clk;

  task automatic fail;
    input string reason;
    begin
      $display("[NPU-COPROCESSOR-Q8-GEMV][FAIL] %s cycle=%0d phase=%0d state=%0d req=%0d/%0d/%0d",
               reason, global_cycles, phase, dut.state_q,
               total_requests, total_read_requests, total_write_requests);
      $display("[NPU-COPROCESSOR-Q8-GEMV][EVIDENCE] completion=%0b err=%0b/%0d class=%0d read=%0d write=%0d mac=%0d elems=%0d aggregate command=%0d completion=%0d error=%0d required=%0d/%0d macro=%0d/%0d f32=%0d",
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
      base = {19'd0, address[12:0]};
      load64_local = 64'd0;
      for (k = 0; k < 8; k = k + 1)
        load64_local[k*8 +: 8] = gmem[base+k];
    end
  endfunction

  function automatic [31:0] load32_local;
    input [63:0] address;
    integer base;
    begin
      base = {19'd0, address[12:0]};
      load32_local = {gmem[base+3], gmem[base+2],
                      gmem[base+1], gmem[base]};
    end
  endfunction

  task automatic write_byte;
    input [63:0] address;
    input [7:0] bits;
    begin
      if ((address >= 64'(GMEM_BYTES)) || (address[63:13] != 51'd0))
        fail("fixture byte escaped local GMEM");
      gmem[address[12:0]] = bits;
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
    input [7:0] q;
    begin
      write_byte(address + 64'd2 + 64'(qlane), q);
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

  // One response at a time.  Successful writes update only the strobed raw
  // bytes.  A dynamic error therefore leaves any prefix writes private until
  // the public terminal completion decides whether the transaction commits.
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
      total_read_requests <= 0;
      total_write_requests <= 0;
      accepted_commands <= 0;
      accepted_completions <= 0;
      backpressure_cycles <= 0;
      saw_late_fault_addr <= 1'b0;
      saw_profile_probe <= 1'b0;
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

      if (!completion_valid &&
          (completion_is_macro ||
           (completion_macro_status != 32'd0) ||
           (completion_macro_kernel_id != 32'd0) ||
           (completion_macro_sequence_id != 64'd0) ||
           (completion_macro_q8_mac_count != 64'd0)))
        fail("macro completion identity leaked outside valid");

      // White-box observation of the public GMEM credit firewall.  This does
      // not inspect numeric results; it proves inactive adapters see zero
      // ready/response credit even while another macro owns the public port.
      if (dut.macro_select_gemv_w &&
          (dut.macro_gmem_req_ready_w || dut.macro_gmem_rsp_valid_w ||
           (dut.macro_gmem_rsp_rdata_w != 64'd0) ||
           dut.macro_gmem_rsp_error_w ||
           dut.q8_gmem_req_ready_w || dut.q8_gmem_rsp_valid_w ||
           (dut.q8_gmem_rsp_rdata_w != 64'd0) ||
           dut.q8_gmem_rsp_error_w))
        fail("inactive VECTOR/GET_ROWS adapter received GEMV credit");
      if (dut.macro_select_q8_w &&
          (dut.macro_gmem_req_ready_w || dut.macro_gmem_rsp_valid_w ||
           (dut.macro_gmem_rsp_rdata_w != 64'd0) ||
           dut.macro_gmem_rsp_error_w ||
           dut.gemv_gmem_req_ready_w || dut.gemv_gmem_rsp_valid_w ||
           (dut.gemv_gmem_rsp_rdata_w != 64'd0) ||
           dut.gemv_gmem_rsp_error_w))
        fail("inactive VECTOR/GEMV adapter received GET_ROWS credit");
      if (dut.macro_select_vector_w &&
          (dut.q8_gmem_req_ready_w || dut.q8_gmem_rsp_valid_w ||
           (dut.q8_gmem_rsp_rdata_w != 64'd0) ||
           dut.q8_gmem_rsp_error_w ||
           dut.gemv_gmem_req_ready_w || dut.gemv_gmem_rsp_valid_w ||
           (dut.gemv_gmem_rsp_rdata_w != 64'd0) ||
           dut.gemv_gmem_rsp_error_w))
        fail("inactive GET_ROWS/GEMV adapter received VECTOR credit");
      if (!dut.macro_gmem_owner_w &&
          (dut.macro_gmem_req_ready_w || dut.macro_gmem_rsp_valid_w ||
           (dut.macro_gmem_rsp_rdata_w != 64'd0) ||
           dut.macro_gmem_rsp_error_w ||
           dut.q8_gmem_req_ready_w || dut.q8_gmem_rsp_valid_w ||
           (dut.q8_gmem_rsp_rdata_w != 64'd0) ||
           dut.q8_gmem_rsp_error_w ||
           dut.gemv_gmem_req_ready_w || dut.gemv_gmem_rsp_valid_w ||
           (dut.gemv_gmem_rsp_rdata_w != 64'd0) ||
           dut.gemv_gmem_rsp_error_w))
        fail("macro adapters received GMEM credit without macro owner");
      if ((dut.macro_gmem_req_valid_w && dut.q8_gmem_req_valid_w) ||
          (dut.macro_gmem_req_valid_w && dut.gemv_gmem_req_valid_w) ||
          (dut.q8_gmem_req_valid_w && dut.gemv_gmem_req_valid_w))
        fail("two macro adapters requested GMEM concurrently");

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
          if (!pending_response_error) begin
            if ((pending_addr[63:13] != 51'd0) ||
                ({51'd0, pending_addr[12:0]} + 64'd8 >
                 64'(GMEM_BYTES)))
              fail("successful response escaped local GMEM");
            if (pending_write) begin
              for (lane = 0; lane < 8; lane = lane + 1)
                if (pending_wstrb[lane])
                  gmem[{19'd0, pending_addr[12:0]} + lane] <=
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
          fail("public FP32 write used an invalid byte strobe");
        if (!gmem_req_write &&
            ((gmem_req_wdata != 64'd0) || (gmem_req_wstrb != 8'd0)))
          fail("public read carried a write payload");
        if ((phase == 2) || (phase == 5))
          fail("static invalid descriptor issued GMEM traffic");

        if ((phase >= 1) && (phase <= 3)) begin
          if (gmem_req_write) begin
            if ((gmem_req_addr < DST_WIN) ||
                (gmem_req_addr + 64'd8 > DST_WIN + 64'h18))
              fail("GEMV write escaped private destination window");
          end else if (!(((gmem_req_addr >= ACT_WIN) &&
                           (gmem_req_addr + 64'd8 <= ACT_WIN + 64'h108)) ||
                          ((gmem_req_addr >= WT_WIN) &&
                           (gmem_req_addr + 64'd8 <= WT_WIN + 64'h90)))) begin
            fail("GEMV read escaped activation/weight windows");
          end
        end else if (phase == 4) begin
          if (gmem_req_write)
            fail("profile probe wrote before injected read failure");
          saw_profile_probe <= 1'b1;
        end else if (phase == 6) begin
          if (gmem_req_write) begin
            if ((gmem_req_addr < GR_DST_BASE) ||
                (gmem_req_addr + 64'd8 > GR_DST_BASE + 64'd128))
              fail("GET_ROWS write escaped destination window");
          end else if (!(((gmem_req_addr >= GR_SRC_BASE) &&
                           (gmem_req_addr + 64'd8 <=
                            GR_SRC_BASE + 64'd40)) ||
                          ((gmem_req_addr >= GR_IDX_BASE) &&
                           (gmem_req_addr + 64'd8 <=
                            GR_IDX_BASE + 64'd8)))) begin
            fail("GET_ROWS read escaped source/index windows");
          end
        end else if (phase == 7) begin
          if (gmem_req_write) begin
            if ((gmem_req_addr < VEC_DST_BASE) ||
                (gmem_req_addr + 64'd8 > VEC_DST_BASE + 64'd64))
              fail("VECTOR write escaped destination window");
          end else if (!(((gmem_req_addr >= VEC_SRC0_BASE) &&
                           (gmem_req_addr + 64'd8 <=
                            VEC_SRC0_BASE + 64'd64)) ||
                          ((gmem_req_addr >= VEC_SRC1_BASE) &&
                           (gmem_req_addr + 64'd8 <=
                            VEC_SRC1_BASE + 64'd64)))) begin
            fail("VECTOR read escaped source windows");
          end
        end

        pending <= 1'b1;
        pending_write <= gmem_req_write;
        pending_addr <= gmem_req_addr;
        pending_wdata <= gmem_req_wdata;
        pending_wstrb <= gmem_req_wstrb;
        pending_delay <= gmem_req_write ? 4'd2 : 4'd1;
        total_requests <= total_requests + 1;
        if (gmem_req_write) begin
          total_write_requests <= total_write_requests + 1;
        end else begin
          total_read_requests <= total_read_requests + 1;
          if (inject_exact_read_error &&
              (gmem_req_addr == exact_read_error_addr))
            saw_late_fault_addr <= 1'b1;
        end
      end
    end
  end

  task automatic configure_identity;
    input [63:0] sequence_value;
    begin
      macro_abi_valid = 1'b1;
      macro_context_id = 32'hc830_0000 | {16'd0, sequence_value[15:0]};
      macro_capability_epoch = 32'h00000001;
      macro_sequence_id = sequence_value;
      macro_producer_id = 64'hfedc_ba98_0000_0000 |
                          {32'd0, sequence_value[31:0]};
      macro_user_tag = 64'h0123_4567_0000_0000 |
                       {32'd0, sequence_value[31:0]};
      macro_node_count = 32'd1;
      macro_node_hash_lo = 64'h8899_aabb_0000_0000 |
                           {32'd0, sequence_value[31:0]};
      macro_node_hash_hi = 64'hccdd_eeff_0000_0000 |
                           {32'd0, sequence_value[31:0]};
      macro_deadline_cycles = 64'd0;
    end
  endtask

  task automatic configure_gemv_numeric;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_GEMV;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = ACT_BASE;
      macro_src1_iova = WT_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = DST_BASE;
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
      macro_dst_window_base = DST_WIN;
      macro_dst_window_size = 64'h18;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      inject_any_read_error = 1'b0;
      inject_exact_read_error = 1'b0;
      exact_read_error_addr = 64'd0;
      enable_backpressure = 1'b1;
    end
  endtask

  task automatic configure_gemv_profile;
    input [31:0] m;
    input [31:0] b;
    input [63:0] sequence_value;
    reg [63:0] activation_bytes;
    reg [63:0] weight_row_bytes;
    reg [63:0] weight_matrix_bytes;
    reg [63:0] dst_extent;
    begin
      configure_identity(sequence_value);
      activation_bytes = {32'd0, b} * 64'd128;
      weight_row_bytes = {32'd0, b} * 64'd34;
      weight_matrix_bytes = {32'd0, m} * weight_row_bytes;
      dst_extent = 64'd4 + ({32'd0, m} * 64'd4);

      macro_kernel_id = KERNEL_GEMV;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_window_base = 64'h0000_0001_0000_1000;
      macro_src0_iova = macro_src0_window_base + 64'd4;
      macro_src1_window_base = 64'h0000_0002_0000_0000;
      macro_src1_iova = macro_src1_window_base + 64'd2;
      macro_src2_iova = 64'd0;
      macro_dst_window_base = 64'h0000_0003_0000_0000;
      macro_dst_iova = macro_dst_window_base + 64'd4;
      macro_scratch_iova = 64'd0;
      macro_element_count = {32'd0, b} * 64'd32;
      macro_outer_count = m;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd0;
      macro_src1_stride = weight_row_bytes;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd4;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_size = activation_bytes + 64'd8;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_size = weight_matrix_bytes + 64'd8;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_size = ((dst_extent + 64'd7) >> 3) << 3;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      inject_any_read_error = 1'b1;
      inject_exact_read_error = 1'b0;
      exact_read_error_addr = 64'd0;
      enable_backpressure = 1'b1;
    end
  endtask

  task automatic configure_get_rows;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value);
      macro_kernel_id = KERNEL_GET_ROWS;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = GR_SRC_BASE;
      macro_src1_iova = GR_IDX_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = GR_DST_BASE;
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
      macro_src0_window_base = GR_SRC_BASE;
      macro_src0_window_size = 64'd40;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = GR_IDX_BASE;
      macro_src1_window_size = 64'd8;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = GR_DST_BASE;
      macro_dst_window_size = 64'd128;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      inject_any_read_error = 1'b0;
      inject_exact_read_error = 1'b0;
      exact_read_error_addr = 64'd0;
      enable_backpressure = 1'b1;
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
      macro_src0_iova = VEC_SRC0_BASE;
      macro_src1_iova = VEC_SRC1_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = VEC_DST_BASE;
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
      macro_src0_window_base = VEC_SRC0_BASE;
      macro_src0_window_size = 64'd64;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = VEC_SRC1_BASE;
      macro_src1_window_size = 64'd64;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = VEC_DST_BASE;
      macro_dst_window_size = 64'd64;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
      inject_any_read_error = 1'b0;
      inject_exact_read_error = 1'b0;
      exact_read_error_addr = 64'd0;
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
          (completion_macro_npu_cycles == 64'd0)) begin
        fail("macro completion identity/counter payload mismatch");
      end
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
          fail("completion identity changed under public backpressure");
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

  task automatic load_numeric_fixture;
    integer qlane;
    begin
      // Activation block 0: frozen IEEE bits for
      // [-127,-64,-1,0,1,63,64,127,0...].
      write_u32(ACT_BASE + 64'd0, 32'hc2fe0000);
      write_u32(ACT_BASE + 64'd4, 32'hc2800000);
      write_u32(ACT_BASE + 64'd8, 32'hbf800000);
      write_u32(ACT_BASE + 64'd12, 32'h00000000);
      write_u32(ACT_BASE + 64'd16, 32'h3f800000);
      write_u32(ACT_BASE + 64'd20, 32'h427c0000);
      write_u32(ACT_BASE + 64'd24, 32'h42800000);
      write_u32(ACT_BASE + 64'd28, 32'h42fe0000);
      for (qlane = 8; qlane < 32; qlane = qlane + 1)
        write_u32(ACT_BASE + (64'(qlane) * 64'd4), 32'h00000000);
      // Activation block 1: 32 copies of +127.0f.
      for (qlane = 0; qlane < 32; qlane = qlane + 1)
        write_u32(ACT_BASE +
                  ((64'd32 + 64'(qlane)) * 64'd4), 32'h42fe0000);

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
      poison_destination(DST_WIN, 24);
    end
  endtask

  task automatic load_legacy_fixtures;
    integer k;
    begin
      // GET_ROWS: one scale=1.0 Q8_0 block filled with zero and index 0.
      write_q8_block(GR_SRC_BASE, 16'h3c00, 8'h00);
      for (k = 34; k < 40; k = k + 1)
        write_byte(GR_SRC_BASE + 64'(k), 8'h00);
      for (k = 0; k < 8; k = k + 1)
        write_byte(GR_IDX_BASE + 64'(k), 8'h00);
      poison_destination(GR_DST_BASE, 128);

      // VECTOR P00: zero + zero must remain exact +0 FP32.
      for (k = 0; k < 64; k = k + 1) begin
        write_byte(VEC_SRC0_BASE + 64'(k), 8'h00);
        write_byte(VEC_SRC1_BASE + 64'(k), 8'h00);
        write_byte(VEC_DST_BASE + 64'(k), 8'ha5);
      end
    end
  endtask

  task automatic run_profile_probe;
    input [31:0] m;
    input [31:0] b;
    input [63:0] sequence_value;
    reg [63:0] expected_activation_end;
    reg [63:0] expected_weight_end;
    reg [63:0] expected_dst_end;
    begin
      configure_gemv_profile(m, b, sequence_value);
      expected_activation_end = macro_src0_iova +
          ({32'd0, b} * 64'd128);
      expected_weight_end = macro_src1_iova +
          ({32'd0, m} * ({32'd0, b} * 64'd34));
      expected_dst_end = macro_dst_iova + ({32'd0, m} * 64'd4);
      before_requests = total_requests;
      execute_macro(4, 1'b1, `NPU_ERR_GMEM_RESPONSE, 32'd6,
                    64'd0, 64'd0, 64'd0, 64'd0);
      checks = checks + 1;
      if ((total_requests - before_requests != 1) ||
          (dut.gemv_activation_end_ext_w !=
           {64'd0, expected_activation_end}) ||
          (dut.gemv_weight_end_ext_w != {64'd0, expected_weight_end}) ||
          (dut.gemv_dst_end_ext_w != {64'd0, expected_dst_end}) ||
          (dut.gemv_block_count_ext_w != {96'd0, b}) ||
          (dut.gemv_q8_mac_count_ext_w !=
           ({96'd0, m} * ({96'd0, b} << 5))))
        fail("Qwen profile lost full-width public preflight identity");
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
    for (byte_index = 0; byte_index < GMEM_BYTES;
         byte_index = byte_index + 1)
      gmem[byte_index] = 8'ha7 ^ byte_index[7:0];
    load_numeric_fixture();
    load_legacy_fixtures();
    poison_live_descriptor();

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);

    // 1. Frozen M=2, K=64 (B=2) numeric transaction.  The host oracle is
    // raw-bit-only; exact results came from the standalone RTL proof.
    configure_gemv_numeric(64'h2233_4455_6600_0001);
    before_requests = total_requests;
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(1, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd408, 64'd8, 64'd128, 64'd2);
    checks = checks + 1;
    if ((total_requests - before_requests != 53) ||
        (total_read_requests - before_reads != 51) ||
        (total_write_requests - before_writes != 2) ||
        (load32_local(DST_BASE) != 32'h473d6500) ||
        (load32_local(DST_BASE + 64'd12) != 32'hc5fc0800) ||
        (backpressure_cycles == 0) ||
        (command_count != 64'd1) || (completion_count != 64'd1) ||
        (error_count != 64'd0) ||
        (npu_required_issued != 64'd1) ||
        (npu_required_completed != 64'd1) ||
        (macro_command_count != 64'd1) ||
        (macro_completion_count != 64'd1) ||
        (macro_f32_start_count != 64'd0))
      fail("M2/B2 public numeric result or exact counters regressed");

    // 2. Top-level whole-descriptor preflight: the activation window is one
    // beat short.  Neither reads nor writes may become visible.
    configure_gemv_numeric(64'h2233_4455_6600_0002);
    macro_src0_window_size = 64'h100;
    before_requests = total_requests;
    execute_macro(2, 1'b1, `NPU_ERR_MACRO_IOVA, 32'd5,
                  64'd0, 64'd0, 64'd0, 64'd0);
    if ((total_requests != before_requests) ||
        (npu_required_issued != 64'd2) ||
        (npu_required_completed != 64'd1) ||
        (macro_completion_count != 64'd1))
      fail("short GEMV window issued traffic or completed REQUIRED");
    clear_terminal_error();

    // 3. A read error after row 0 has been privately written must not emit a
    // success/commit completion.  Dynamic counters report only the prefix.
    poison_destination(DST_WIN, 24);
    configure_gemv_numeric(64'h2233_4455_6600_0003);
    inject_exact_read_error = 1'b1;
    exact_read_error_addr = 64'h0000_0000_0000_1548;
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(3, 1'b1, `NPU_ERR_GMEM_RESPONSE, 32'd6,
                  64'd336, 64'd4, 64'd64, 64'd1);
    checks = checks + 1;
    if (!saw_late_fault_addr ||
        (total_read_requests - before_reads != 43) ||
        (total_write_requests - before_writes != 1) ||
        (load32_local(DST_BASE) != 32'h473d6500) ||
        (load32_local(DST_BASE + 64'd12) != 32'ha5a5a5a5) ||
        (completion_count != 64'd1) ||
        (macro_completion_count != 64'd1) ||
        (npu_required_completed != 64'd1))
      fail("late GMEM fault exposed a public commit or wrong prefix counters");
    clear_terminal_error();

    // 4. Real Qwen profiles pass the full 128-bit capability/window proof.
    // A first-read error makes these sparse and fast without host arithmetic.
    run_profile_probe(32'd248320, 32'd32,
                      64'h2233_4455_6600_0020);
    run_profile_probe(32'd1, 32'd64,
                      64'h2233_4455_6600_0040);
    run_profile_probe(32'd1, 32'd112,
                      64'h2233_4455_6600_0070);
    if (!saw_profile_probe)
      fail("Qwen profiles never reached the selected GEMV GMEM owner");

    // Independent maximum M/B endpoint: removing its last weight beat must
    // fail in top-level preflight before either read source can issue.
    configure_gemv_profile(32'd248320, 32'd112,
                           64'h2233_4455_6600_0071);
    macro_src1_window_size = macro_src1_window_size - 64'd8;
    inject_any_read_error = 1'b0;
    before_requests = total_requests;
    execute_macro(5, 1'b1, `NPU_ERR_MACRO_IOVA, 32'd5,
                  64'd0, 64'd0, 64'd0, 64'd0);
    if (total_requests != before_requests)
      fail("maximum-shape short weight window issued partial traffic");
    clear_terminal_error();

    // 5. Existing GET_ROWS_Q8_0 remains a distinct dispatch entry.
    configure_get_rows(64'h2233_4455_6600_0101);
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(6, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd48, 64'd128, 64'd0, 64'd32);
    if ((total_read_requests - before_reads != 6) ||
        (total_write_requests - before_writes != 32))
      fail("GET_ROWS public request counts regressed");
    for (lane = 0; lane < 32; lane = lane + 1)
      if (load32_local(GR_DST_BASE + (64'(lane) * 64'd4)) != 32'd0)
        fail("GET_ROWS zero Q8 block output regressed");

    // 6. Existing VECTOR_F32 P00 remains selected and functional.
    configure_vector(64'h2233_4455_6600_0110);
    before_requests = total_requests;
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(7, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd128, 64'd64, 64'd0, 64'd16);
    if ((total_requests - before_requests != 32) ||
        (total_read_requests - before_reads != 16) ||
        (total_write_requests - before_writes != 16))
      fail("VECTOR public request counts regressed");
    for (lane = 0; lane < 16; lane = lane + 1)
      if (load32_local(VEC_DST_BASE + (64'(lane) * 64'd4)) != 32'd0)
        fail("VECTOR P00 raw FP32 output regressed");

    checks = checks + 1;
    if ((accepted_commands != 9) || (accepted_completions != 9) ||
        (command_count != 64'd9) || (completion_count != 64'd3) ||
        (error_count != 64'd6) ||
        (npu_required_issued != 64'd8) ||
        (npu_required_completed != 64'd2) ||
        (macro_command_count != 64'd9) ||
        (macro_completion_count != 64'd3) ||
        (macro_f32_start_count != 64'd1) || sticky_error || busy)
      fail("final three-kernel aggregate counters did not close");

    $display("[NPU-COPROCESSOR-Q8-GEMV][INFO] gemv=M2/B2/read408/write8/mac128/rows2 oracle=473d6500,c5fc0800 profiles=M248320/B32+B64+B112 worst=M248320/B112 preflight=128b late_fault=read336/write4/mac64/no_commit required=8/2 get_rows=read48/write128/elements32 vector=read128/write64/elements16 identity=full64 node_hash=128 gmem_owner=exclusive checks=%0d assertions=off waveform=off",
             checks);
    $display("[NPU-COPROCESSOR-Q8-GEMV][PASS]");
    $finish;
  end

endmodule

`default_nettype wire
