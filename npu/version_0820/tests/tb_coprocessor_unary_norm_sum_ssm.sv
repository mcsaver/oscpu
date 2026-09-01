`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

module tb_coprocessor_unary_norm_sum_ssm;
  localparam [31:0] CANONICAL_CONTEXT_ID = 32'h4341_4e01;
  localparam integer PID_W = 8;
  localparam integer OPCLASS_W = 8;
  localparam integer MEM_BYTES = 32'h0028_0000;
  localparam [63:0] SRC0_BASE = 64'h0000_0000_0001_0000;
  localparam [63:0] SRC1_BASE = 64'h0000_0000_0012_0000;
  localparam [63:0] DST_BASE  = 64'h0000_0000_0024_0000;
  localparam [31:0] FLAGS_REQUIRED_PROFILE = 32'h0000_0011;
  localparam [31:0] DTYPE_F32 = 32'd1;
  localparam [31:0] EPSILON_QWEN = 32'h3586_37bd;

  localparam [31:0] KERNEL_UNARY = 32'h514e_0005;
  localparam [31:0] KERNEL_GLU = 32'h514e_0006;
  localparam [31:0] KERNEL_REDUCE = 32'h514e_0011;
  localparam [31:0] KERNEL_SSM = 32'h514e_0022;

  reg clk;
  reg rst;

  reg cmd_valid;
  wire cmd_ready;
  reg cmd_is_64;
  reg [63:0] cmd_bits;
  reg [63:0] cmd_rs_value;
  reg [PID_W-1:0] cmd_producer_id;
  reg cmd_npu_required;
  reg [OPCLASS_W-1:0] cmd_opclass;

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
  wire host_lmem_wr_oob;
  wire host_lmem_ready;

  wire gmem_req_valid;
  reg gmem_req_ready;
  wire gmem_req_write;
  wire [63:0] gmem_req_addr;
  wire [63:0] gmem_req_wdata;
  wire [7:0] gmem_req_wstrb;
  reg gmem_rsp_valid;
  wire gmem_rsp_ready;
  reg [63:0] gmem_rsp_rdata;
  reg gmem_rsp_error;

  reg sync_tag_ack;
  wire [63:0] sync_tag;
  wire sync_tag_valid;
  reg error_clear;
  wire busy;
  wire error;
  wire [`NPU_ERROR_W-1:0] error_code;
  wire [63:0] command_count;
  wire [63:0] completion_count;
  wire [63:0] error_count;
  wire [63:0] npu_required_issued;
  wire [63:0] npu_required_completed;
  wire [63:0] tiu_cycles;
  wire [63:0] dma_cycles;
  wire [63:0] dma_bytes;
  wire [63:0] macro_command_count;
  wire [63:0] macro_f32_start_count;
  wire [63:0] macro_completion_count;

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
  reg pending_q;
  reg pending_write_q;
  reg [63:0] pending_addr_q;
  reg [63:0] pending_wdata_q;
  reg [7:0] pending_wstrb_q;
  reg [63:0] pending_rdata_q;
  reg pending_error_q;
  integer pending_delay_q;
  reg [63:0] accepted_requests_q;
  reg [63:0] accepted_reads_q;
  reg [63:0] accepted_writes_q;
  reg [63:0] completed_responses_q;
  reg [63:0] successful_writes_q;
  reg signed [63:0] inject_error_ordinal_q;
  integer response_delay_cfg_q;
  reg request_backpressure_q;
  reg [31:0] cycle_q;

  reg held_req_q;
  reg held_req_write_q;
  reg [63:0] held_req_addr_q, held_req_wdata_q;
  reg [7:0] held_req_wstrb_q;
  integer held_request_cycles_q;

  function automatic [63:0] load_u64(input [63:0] address);
    integer byte_index;
    begin
      load_u64 = 64'd0;
      for (byte_index = 0; byte_index < 8; byte_index = byte_index + 1)
        load_u64[(byte_index * 8) +: 8] =
            memory[address[21:0] + byte_index[21:0]];
    end
  endfunction

  function automatic [31:0] load_u32(input [63:0] address);
    begin
      load_u32 = {memory[address[21:0] + 22'd3],
                  memory[address[21:0] + 22'd2],
                  memory[address[21:0] + 22'd1], memory[address[21:0]]};
    end
  endfunction

  always #5 clk <= ~clk;

  always @(*) begin
    gmem_req_ready = !rst && !pending_q &&
                     (!request_backpressure_q ||
                      (held_req_q && cycle_q[0]));
    gmem_rsp_valid = !rst && pending_q && (pending_delay_q == 0);
    gmem_rsp_rdata = pending_rdata_q;
    gmem_rsp_error = pending_error_q;
  end

  integer lane_index;
  always @(posedge clk) begin
    if (rst) begin
      pending_q <= 1'b0;
      pending_write_q <= 1'b0;
      pending_addr_q <= 64'd0;
      pending_wdata_q <= 64'd0;
      pending_wstrb_q <= 8'd0;
      pending_rdata_q <= 64'd0;
      pending_error_q <= 1'b0;
      pending_delay_q <= 0;
      accepted_requests_q <= 0;
      accepted_reads_q <= 0;
      accepted_writes_q <= 0;
      completed_responses_q <= 0;
      successful_writes_q <= 0;
      cycle_q <= 32'd0;
      held_req_q <= 1'b0;
      held_req_write_q <= 1'b0;
      held_req_addr_q <= 64'd0;
      held_req_wdata_q <= 64'd0;
      held_req_wstrb_q <= 8'd0;
      held_request_cycles_q <= 0;
    end else begin
      cycle_q <= cycle_q + 32'd1;
      if (gmem_req_valid && !gmem_req_ready) begin
        held_request_cycles_q <= held_request_cycles_q + 1;
        if (!held_req_q) begin
          held_req_q <= 1'b1;
          held_req_write_q <= gmem_req_write;
          held_req_addr_q <= gmem_req_addr;
          held_req_wdata_q <= gmem_req_wdata;
          held_req_wstrb_q <= gmem_req_wstrb;
        end else if ((gmem_req_write != held_req_write_q) ||
                     (gmem_req_addr != held_req_addr_q) ||
                     (gmem_req_wdata != held_req_wdata_q) ||
                     (gmem_req_wstrb != held_req_wstrb_q)) begin
          $display("[NPU-COPROC-EXACT][FAIL] unstable held GMEM request");
          $finish;
        end
      end else begin
        held_req_q <= 1'b0;
      end

      if (gmem_req_valid && gmem_req_ready) begin
        if ((gmem_req_addr + 64'd8) > 64'd2621440) begin
          $display("[NPU-COPROC-EXACT][FAIL] GMEM request out of fixture");
          $finish;
        end
        if (pending_q) begin
          $display("[NPU-COPROC-EXACT][FAIL] more than one outstanding");
          $finish;
        end
        if (!busy) begin
          $display("[NPU-COPROC-EXACT][FAIL] GMEM traffic without owner");
          $finish;
        end
        pending_q <= 1'b1;
        pending_write_q <= gmem_req_write;
        pending_addr_q <= gmem_req_addr;
        pending_wdata_q <= gmem_req_wdata;
        pending_wstrb_q <= gmem_req_wstrb;
        pending_rdata_q <= load_u64(gmem_req_addr);
        pending_error_q <=
            (accepted_requests_q == inject_error_ordinal_q);
        pending_delay_q <= response_delay_cfg_q;
        accepted_requests_q <= accepted_requests_q + 1;
        if (gmem_req_write)
          accepted_writes_q <= accepted_writes_q + 1;
        else
          accepted_reads_q <= accepted_reads_q + 1;
      end else if (pending_q && (pending_delay_q != 0)) begin
        pending_delay_q <= pending_delay_q - 1;
      end

      if (gmem_rsp_valid && gmem_rsp_ready) begin
        completed_responses_q <= completed_responses_q + 1;
        if (pending_write_q && !pending_error_q) begin
          for (lane_index = 0; lane_index < 8;
               lane_index = lane_index + 1)
            if (pending_wstrb_q[lane_index])
              memory[pending_addr_q[21:0] + lane_index[21:0]] <=
                  pending_wdata_q[(lane_index * 8) +: 8];
          successful_writes_q <= successful_writes_q + 1;
        end
        pending_q <= 1'b0;
        pending_error_q <= 1'b0;
      end
    end
  end

  task automatic fail_case(input string reason);
    begin
      $fatal(1, "[NPU-COPROC-EXACT][FAIL] %s", reason);
    end
  endtask

  task automatic set_u32(input [63:0] address, input [31:0] value);
    begin
      memory[address[21:0]] = value[7:0];
      memory[address[21:0] + 22'd1] = value[15:8];
      memory[address[21:0] + 22'd2] = value[23:16];
      memory[address[21:0] + 22'd3] = value[31:24];
    end
  endtask

  task automatic fill_region(
      input [63:0] address,
      input integer bytes,
      input [7:0] value
  );
    integer offset;
    begin
      for (offset = 0; offset < bytes; offset = offset + 1)
        memory[address[21:0] + offset[21:0]] = value;
    end
  endtask

  task automatic bus_defaults;
    begin
      cmd_valid = 1'b0;
      cmd_is_64 = 1'b0;
      cmd_bits = 64'd0;
      cmd_rs_value = 64'd0;
      cmd_producer_id = {PID_W{1'b0}};
      cmd_npu_required = 1'b0;
      cmd_opclass = {OPCLASS_W{1'b0}};
      macro_cmd_valid = 1'b0;
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
      request_backpressure_q = 1'b0;
      response_delay_cfg_q = 0;
      inject_error_ordinal_q = -64'sd1;
    end
  endtask

  task automatic descriptor_defaults;
    begin
      macro_abi_valid = 1'b1;
      macro_kernel_id = KERNEL_UNARY;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_context_id = CANONICAL_CONTEXT_ID;
      macro_capability_epoch = 32'd1;
      macro_sequence_id = 64'h0102_0304_0506_0708;
      macro_producer_id = 64'h1112_1314_1516_1718;
      macro_user_tag = 64'h2122_2324_2526_2728;
      macro_node_count = 32'd1;
      macro_node_hash_lo = 64'h3132_3334_3536_3738;
      macro_node_hash_hi = 64'h4142_4344_4546_4748;
      macro_deadline_cycles = 64'd0;
      macro_vector_op = 32'd7;
      macro_vector_flags = 32'd0;
      macro_src0_iova = SRC0_BASE;
      macro_src1_iova = SRC1_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = DST_BASE;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd1;
      macro_outer_count = 32'd16;
      macro_dtype = DTYPE_F32;
      macro_src0_stride = 64'd4;
      macro_src1_stride = 64'd0;
      macro_src2_stride = 64'd64;
      macro_dst_stride = 64'd4;
      macro_scalar0 = 32'd0;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = SRC0_BASE;
      macro_src0_window_size = 64'd64;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = SRC1_BASE;
      macro_src1_window_size = 64'd0;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = DST_BASE;
      macro_dst_window_size = 64'd64;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
    end
  endtask

  task automatic configure_profile(input integer semantic);
    integer row;
    begin
      descriptor_defaults();
      case (semantic)
        0: begin
          fill_region(SRC0_BASE, 64, 8'h00);
          fill_region(DST_BASE, 64, 8'ha5);
        end
        1: begin
          macro_kernel_id = KERNEL_GLU;
          macro_vector_op = 32'd2;
          macro_vector_flags = 32'd6;
          macro_element_count = 64'd3584;
          macro_outer_count = 32'd1;
          macro_src0_stride = 64'd14336;
          macro_src1_stride = 64'd14336;
          macro_src2_stride = 64'd14336;
          macro_dst_stride = 64'd14336;
          macro_src0_window_size = 64'd14336;
          macro_src1_window_size = 64'd14336;
          macro_dst_window_size = 64'd14336;
          fill_region(SRC0_BASE, 14336, 8'h00);
          fill_region(SRC1_BASE, 14336, 8'h00);
          fill_region(DST_BASE, 14336, 8'ha5);
        end
        2: begin
          macro_kernel_id = KERNEL_REDUCE;
          macro_vector_op = 32'd4;
          macro_vector_flags = 32'd2;
          macro_element_count = 64'd256;
          macro_outer_count = 32'd2;
          macro_src0_stride = 64'd1024;
          macro_src1_stride = 64'd0;
          macro_src2_stride = 64'd2048;
          macro_dst_stride = 64'd1024;
          macro_scalar0 = EPSILON_QWEN;
          macro_src0_window_size = 64'd2048;
          macro_dst_window_size = 64'd2048;
          fill_region(SRC0_BASE, 2048, 8'h00);
          fill_region(DST_BASE, 2048, 8'ha5);
        end
        3: begin
          macro_kernel_id = KERNEL_REDUCE;
          macro_vector_op = 32'd5;
          macro_vector_flags = 32'd4;
          macro_element_count = 64'd128;
          macro_outer_count = 32'd16;
          macro_src0_stride = 64'd512;
          macro_src1_stride = 64'd0;
          macro_src2_stride = 64'd24576;
          macro_dst_stride = 64'd512;
          macro_scalar0 = EPSILON_QWEN;
          macro_src0_window_size = 64'd8192;
          macro_dst_window_size = 64'd8192;
          fill_region(SRC0_BASE, 8192, 8'h00);
          fill_region(DST_BASE, 8192, 8'ha5);
          for (row = 0; row < 16; row = row + 1)
            set_u32(SRC0_BASE + ({32'd0, row[31:0]} * 64'd512),
                    32'h3f80_0000);
        end
        4: begin
          macro_kernel_id = KERNEL_REDUCE;
          macro_vector_op = 32'd1;
          macro_vector_flags = 32'd0;
          macro_element_count = 64'd1;
          macro_outer_count = 32'd2048;
          macro_src0_stride = 64'd512;
          macro_src1_stride = 64'd0;
          macro_src2_stride = 64'd65536;
          macro_dst_stride = 64'd4;
          macro_src0_window_size = 64'd1048576;
          macro_dst_window_size = 64'd8192;
          fill_region(SRC0_BASE, 1048576, 8'h00);
          fill_region(DST_BASE, 8192, 8'ha5);
        end
        5: begin
          macro_kernel_id = KERNEL_SSM;
          macro_vector_op = 32'd76;
          macro_vector_flags = 32'd0;
          macro_element_count = 64'd6144;
          macro_outer_count = 32'd1;
          macro_src0_stride = 64'd16;
          macro_src1_stride = 64'd16;
          macro_src2_stride = 64'd98304;
          macro_dst_stride = 64'd24576;
          macro_src0_window_size = 64'd98304;
          macro_src1_window_size = 64'd98304;
          macro_dst_window_size = 64'd24576;
          fill_region(SRC0_BASE, 98304, 8'h00);
          fill_region(SRC1_BASE, 98304, 8'h00);
          fill_region(DST_BASE, 24576, 8'ha5);
        end
        default: fail_case("unknown fixture semantic");
      endcase
    end
  endtask

  task automatic pulse_reset;
    begin
      rst = 1'b1;
      repeat (5) @(posedge clk);
      @(negedge clk);
      rst = 1'b0;
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic reset_transport_counters;
    begin
      accepted_requests_q = 0;
      accepted_reads_q = 0;
      accepted_writes_q = 0;
      completed_responses_q = 0;
      successful_writes_q = 0;
      held_request_cycles_q = 0;
      inject_error_ordinal_q = -1;
      response_delay_cfg_q = 0;
      request_backpressure_q = 1'b0;
    end
  endtask

  reg [31:0] expected_kernel_q, expected_profile_q;
  reg [63:0] expected_sequence_q, expected_producer_q, expected_tag_q;
  reg [63:0] expected_hash_lo_q, expected_hash_hi_q;
  reg [`NPU_ERROR_W-1:0] last_completion_error_code_q;

  task automatic issue_macro;
    integer wait_cycles;
    begin
      expected_kernel_q = macro_kernel_id;
      expected_profile_q = macro_vector_flags;
      expected_sequence_q = macro_sequence_id;
      expected_producer_q = macro_producer_id;
      expected_tag_q = macro_user_tag;
      expected_hash_lo_q = macro_node_hash_lo;
      expected_hash_hi_q = macro_node_hash_hi;
      wait_cycles = 0;
      @(negedge clk);
      macro_cmd_valid = 1'b1;
      while (!macro_cmd_ready && (wait_cycles < 100)) begin
        @(negedge clk);
        wait_cycles = wait_cycles + 1;
      end
      if (!macro_cmd_ready)
        fail_case("macro admission timeout");
      @(posedge clk);
      @(negedge clk);
      macro_cmd_valid = 1'b0;

      // Mutate every identity/profile witness after the public fire.  The held
      // terminal must come only from the resident transaction.
      macro_kernel_id = 32'hffff_ffff;
      macro_vector_flags = 32'hffff_fffe;
      macro_sequence_id = 64'hffff_eeee_dddd_cccc;
      macro_producer_id = 64'hbbbb_aaaa_9999_8888;
      macro_user_tag = 64'h7777_6666_5555_4444;
      macro_node_hash_lo = 64'h3333_2222_1111_0000;
      macro_node_hash_hi = 64'h9999_aaaa_bbbb_cccc;
    end
  endtask

  task automatic check_identity;
    begin
      if (!completion_is_macro || !completion_npu_required ||
          (completion_producer_id != {PID_W{1'b0}}) ||
          (completion_opclass != {OPCLASS_W{1'b0}}) ||
          (completion_macro_kernel_id != expected_kernel_q) ||
          (completion_macro_command_flags != FLAGS_REQUIRED_PROFILE) ||
          (completion_macro_vector_flags != expected_profile_q) ||
          (completion_macro_context_id != CANONICAL_CONTEXT_ID) ||
          (completion_macro_sequence_id != expected_sequence_q) ||
          (completion_macro_producer_id != expected_producer_q) ||
          (completion_macro_user_tag != expected_tag_q) ||
          (completion_macro_covered_node_count != 32'd1) ||
          (completion_macro_node_hash_lo != expected_hash_lo_q) ||
          (completion_macro_node_hash_hi != expected_hash_hi_q) ||
          (completion_macro_npu_cycles == 64'd0))
        fail_case("resident completion identity mismatch");
    end
  endtask

  task automatic wait_terminal(
      input bit expect_error,
      input [63:0] expected_read_bytes,
      input [63:0] expected_write_bytes,
      input [63:0] expected_work,
      input integer timeout_cycles,
      input integer hold_cycles
  );
    integer cycles;
    reg [31:0] held_status;
    reg [31:0] held_error_class;
    reg [63:0] held_cycles;
    begin
      cycles = 0;
      while (!completion_valid && (cycles < timeout_cycles)) begin
        @(negedge clk);
        cycles = cycles + 1;
      end
      if (!completion_valid)
        fail_case("public completion timeout");
      check_identity();
      if (completion_error != expect_error)
        $fatal(1,
               "[NPU-COPROC-EXACT][FAIL] completion polarity got=%0d code=%0d status=%0d class=%0d read=%0d write=%0d work=%0d",
               completion_error, completion_error_code,
               completion_macro_status, completion_macro_error_class,
               completion_macro_gmem_read_bytes,
               completion_macro_gmem_write_bytes,
               completion_macro_vector_element_count);
      last_completion_error_code_q = completion_error_code;
      if (!expect_error) begin
        if ((completion_error_code != `NPU_ERR_NONE) ||
            (completion_macro_status != 32'd0) ||
            (completion_macro_error_class != 32'd0) ||
            (completion_macro_gmem_read_bytes != expected_read_bytes) ||
            (completion_macro_gmem_write_bytes != expected_write_bytes) ||
            (completion_macro_q8_mac_count != 64'd0) ||
            (completion_macro_vector_element_count != expected_work) ||
            (completion_macro_state_update_count != 64'd0))
          fail_case("successful completion counter oracle mismatch");
      end else begin
        if ((completion_error_code == `NPU_ERR_NONE) ||
            (completion_macro_status == 32'd0) ||
            (completion_macro_error_class == 32'd0))
          fail_case("error completion metadata mismatch");
      end

      held_status = completion_macro_status;
      held_error_class = completion_macro_error_class;
      held_cycles = completion_macro_npu_cycles;
      repeat (hold_cycles) begin
        @(posedge clk);
        #1;
        if (!completion_valid ||
            (completion_macro_status != held_status) ||
            (completion_macro_error_class != held_error_class) ||
            (completion_macro_npu_cycles != held_cycles))
          fail_case("held completion payload changed");
        check_identity();
      end
      @(negedge clk);
      completion_ready = 1'b1;
      @(posedge clk);
      @(negedge clk);
      completion_ready = 1'b0;
      if (expect_error) begin
        if (!error)
          fail_case("sticky error not held after terminal handshake");
        error_clear = 1'b1;
        @(posedge clk);
        @(negedge clk);
        error_clear = 1'b0;
      end
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic check_uniform_output(
      input [63:0] bytes,
      input [31:0] expected_word
  );
    reg [63:0] offset;
    begin
      for (offset = 0; offset < bytes; offset = offset + 4)
        if (load_u32(DST_BASE + offset) !== expected_word)
          fail_case($sformatf("raw output mismatch offset=%0d", offset));
    end
  endtask

  task automatic run_success(
      input string label,
      input integer semantic,
      input [63:0] expected_read_bytes,
      input [63:0] expected_write_bytes,
      input [63:0] expected_work,
      input [31:0] uniform_word,
      input bit one_hot_l2
  );
    integer row;
    reg [63:0] expected_read_requests;
    begin
      configure_profile(semantic);
      reset_transport_counters();
      // One full transaction proves request hold/stability at the public
      // boundary.  The large exact SUM_ROWS/SSM profiles run without the
      // artificial fixture delay so their numerical engines, rather than the
      // testbench, dominate the timeout budget.
      request_backpressure_q = (semantic == 0);
      response_delay_cfg_q = (semantic == 0) ? 1 : 0;
      issue_macro();
      wait_terminal(1'b0, expected_read_bytes, expected_write_bytes,
                    expected_work, 6000000, (semantic == 0) ? 4 : 0);
      // SUM_ROWS is the only frozen child whose raw port consumes two F32
      // values per successful 64-bit read beat.
      expected_read_requests = ((semantic == 4) || (semantic == 5)) ?
                               (expected_read_bytes >> 3) :
                               (expected_read_bytes >> 2);
      if ((accepted_reads_q != expected_read_requests) ||
          (accepted_writes_q != (expected_write_bytes >> 2)) ||
          (completed_responses_q !=
           (expected_read_requests + (expected_write_bytes >> 2))) ||
          (successful_writes_q != (expected_write_bytes >> 2)) ||
          ((semantic == 0) && (held_request_cycles_q == 0)))
        fail_case({label, ": public GMEM accounting/backpressure"});
      if (one_hot_l2) begin
        for (row = 0; row < 16; row = row + 1) begin
          if (load_u32(DST_BASE +
                       ({32'd0, row[31:0]} * 64'd512)) !== 32'h3f80_0000)
            fail_case("L2 one-hot leading lane mismatch");
          if (load_u32(DST_BASE +
                       ({32'd0, row[31:0]} * 64'd512) + 64'd4) !==
              32'h0000_0000)
            fail_case("L2 one-hot zero lane mismatch");
        end
      end else begin
        check_uniform_output(expected_write_bytes, uniform_word);
      end
      $display("[NPU-COPROC-EXACT][PASS-SEMANTIC] %s read=%0d write=%0d work=%0d held=%0d",
               label, expected_read_bytes, expected_write_bytes,
               expected_work, held_request_cycles_q);
    end
  endtask

  task automatic run_static_reject(
      input string label,
      input [`NPU_ERROR_W-1:0] expected_code
  );
    begin
      reset_transport_counters();
      issue_macro();
      wait_terminal(1'b1, 64'd0, 64'd0, 64'd0, 1000, 1);
      if ((accepted_requests_q != 0) || (completed_responses_q != 0) ||
          (completion_count != 64'd6))
        fail_case({label, ": static reject leaked traffic/success"});
      if (error_code != `NPU_ERR_NONE)
        fail_case({label, ": sticky error did not clear"});
      if (expected_code == `NPU_ERR_NONE)
        fail_case("invalid static expected code");
      if (last_completion_error_code_q != expected_code)
        fail_case({label, ": wrong completion error code"});
      $display("[NPU-COPROC-EXACT][PASS-STATIC] %s", label);
    end
  endtask

  task automatic run_late_write_fault;
    integer canary_count;
    reg [63:0] offset;
    begin
      configure_profile(0);
      reset_transport_counters();
      inject_error_ordinal_q = 7;
      issue_macro();
      wait_terminal(1'b1, 64'd0, 64'd0, 64'd0, 10000, 2);
      if ((accepted_requests_q != 8) || (accepted_reads_q != 4) ||
          (accepted_writes_q != 4) || (successful_writes_q != 3) ||
          (completed_responses_q != 8))
        fail_case("late write fault drain/accounting mismatch");
      canary_count = 0;
      for (offset = 0; offset < 64; offset = offset + 4)
        if (load_u32(DST_BASE + offset) == 32'ha5a5_a5a5)
          canary_count = canary_count + 1;
      if ((canary_count == 0) || (canary_count == 16))
        fail_case("late fault did not exercise private partial writes");
      $display("[NPU-COPROC-EXACT][PASS-LATE] private-partial=%0d commit=0",
               16 - canary_count);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    bus_defaults();
    descriptor_defaults();
    pulse_reset();

    run_success("UNARY/SIGMOID/profile0", 0, 64'd64, 64'd64,
                64'd16, 32'h3f00_0000, 1'b0);
    run_success("GLU/SWIGLU/profile6", 1, 64'd28672, 64'd14336,
                64'd3584, 32'h0000_0000, 1'b0);
    run_success("RMS_NORM/profile2", 2, 64'd2048, 64'd2048,
                64'd512, 32'h0000_0000, 1'b0);
    run_success("L2_NORM/profile4", 3, 64'd8192, 64'd8192,
                64'd2048, 32'h0000_0000, 1'b1);
    run_success("SUM_ROWS/profile0", 4, 64'd1048576, 64'd8192,
                64'd262144, 32'h0000_0000, 1'b0);
    run_success("SSM_CONV/profile0", 5, 64'd196608, 64'd24576,
                64'd24576, 32'h0000_0000, 1'b0);

    configure_profile(0);
    macro_kernel_id = 32'h514e_00ff;
    expected_kernel_q = macro_kernel_id;
    run_static_reject("unknown kernel", `NPU_ERR_MACRO_CAPABILITY);

    configure_profile(0);
    macro_vector_flags = 32'd99;
    run_static_reject("unknown exact profile", `NPU_ERR_MACRO_LAYOUT);

    configure_profile(0);
    macro_element_count = 64'd2;
    run_static_reject("profile/public-field mismatch", `NPU_ERR_MACRO_LAYOUT);

    run_late_write_fault();

    if ((command_count != 64'd10) || (completion_count != 64'd6) ||
        (error_count != 64'd4) || (npu_required_issued != 64'd10) ||
        (npu_required_completed != 64'd6) ||
        (macro_command_count != 64'd10) ||
        (macro_completion_count != 64'd6) ||
        (tiu_cycles != 64'd0) || (dma_cycles != 64'd0) ||
        (dma_bytes != 64'd0))
      fail_case("public issued/completed/error counter closure mismatch");

    $display("[NPU-COPROCESSOR-UNARY-NORM-SUM-SSM][PASS] semantics=6 exact_profiles=14 frozen_nodes=289 public_gmem=1 identity=full64+hash128 required=10/6 static=3 late=1 private_commit=success-only host_float=0 hierarchy=0");
    $finish;
  end
endmodule
