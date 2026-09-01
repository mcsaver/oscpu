`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Focused public-boundary proof for the Coprocessor macro dispatch table.
// The GMEM model transports raw 64-bit beats only.  Q8_0 dequantization is
// performed by the instantiated RTL; the TB compares committed raw FP32 bits
// against a small fixed-bit oracle and never uses real/shortreal or DPI.
module tb_coprocessor_q8_get_rows;

  localparam integer GMEM_BYTES = 8192;
  localparam integer MAX_WAIT_CYCLES = 200000;
  localparam [31:0] KERNEL_Q8 = 32'h514e0001;
  localparam [31:0] KERNEL_VECTOR = 32'h514e0010;
  localparam [31:0] FLAGS_REQUIRED_PROFILE = 32'h00000011;
  localparam [31:0] FLAGS_PROFILE = 32'h00000010;

  localparam [63:0] Q8_SRC_BASE = 64'h0000_0000_0000_0100;
  localparam [63:0] Q8_IDX_BASE = 64'h0000_0000_0000_0180;
  localparam [63:0] Q8_DST_BASE = 64'h0000_0000_0000_0244;
  localparam [63:0] Q8_DST_ERROR_BASE = 64'h0000_0000_0000_0404;
  localparam [63:0] Q8_SRC_STRIDE = 64'd40;
  localparam [63:0] Q8_IDX_STRIDE = 64'd4;
  localparam [63:0] Q8_DST_STRIDE = 64'd136;

  // Integer aliases are used exclusively for the bounded local byte array.
  // Descriptor IOVAs remain full 64-bit values above.
  localparam integer Q8_SRC_MEM = 32'h0000_0100;
  localparam integer Q8_IDX_MEM = 32'h0000_0180;
  localparam integer Q8_DST_MEM = 32'h0000_0244;
  localparam integer Q8_SRC_STRIDE_MEM = 40;
  localparam integer Q8_DST_STRIDE_MEM = 136;

  localparam [63:0] VEC_SRC0_BASE = 64'h0000_0000_0000_0600;
  localparam [63:0] VEC_SRC1_BASE = 64'h0000_0000_0000_0680;
  localparam [63:0] VEC_DST_BASE  = 64'h0000_0000_0000_0700;
  localparam integer VEC_SRC0_MEM = 32'h0000_0600;
  localparam integer VEC_SRC1_MEM = 32'h0000_0680;
  localparam integer VEC_DST_MEM  = 32'h0000_0700;
  localparam [12:0] GMEM_LAST_BEAT = 13'd8184;

  // Real Qwen embedding geometry.  Only the selected last row is materialized
  // by the sparse responder; descriptor math still proves the complete
  // 248320-row source table using 128-bit intermediates in the DUT.
  localparam [31:0] BOUND_V = 32'd248320;
  localparam [31:0] BOUND_LAST_ID = 32'd248319;
  localparam [63:0] BOUND_SRC_IOVA = 64'h0000_0001_2000_0002;
  localparam [63:0] BOUND_SRC_WINDOW_BASE = 64'h0000_0001_2000_0000;
  localparam [63:0] BOUND_SRC_WINDOW_SIZE = 64'h0000_0000_101a_8008;
  localparam [63:0] BOUND_LAST_ROW = 64'h0000_0001_301a_7bc2;
  localparam [63:0] BOUND_IDX_IOVA = 64'h0000_0002_4000_0005;
  localparam [63:0] BOUND_IDX_WINDOW_BASE = 64'h0000_0002_4000_0000;
  localparam [63:0] BOUND_DST_IOVA = 64'h0000_0000_0000_0900;

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

  reg [7:0] gmem [0:GMEM_BYTES-1];
  integer global_cycles;
  integer phase;
  integer phase_q;
  integer phase_read_requests;
  integer total_requests;
  integer total_read_requests;
  integer total_write_requests;
  integer accepted_commands;
  integer accepted_completions;
  reg saw_boundary_source_first;
  reg saw_boundary_source_last;
  reg saw_boundary_index_first;
  reg saw_boundary_index_second;
  integer checks;
  integer lane;
  integer byte_index;
  integer before_requests;
  integer before_reads;
  integer before_writes;

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
  reg [63:0] expected_vector_elements;
  reg [63:0] held_completion_cycles;

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

  task automatic fail;
    input string reason;
    begin
      $display("[NPU-COPROCESSOR-Q8-GET-ROWS][FAIL] %s", reason);
      $fatal(1);
    end
  endtask

  function automatic [7:0] boundary_byte;
    input [63:0] addr;
    reg [63:0] row_offset;
    begin
      boundary_byte = 8'h00;
      if (addr == BOUND_IDX_IOVA)
        boundary_byte = 8'hff;
      else if (addr == BOUND_IDX_IOVA + 64'd1)
        boundary_byte = 8'hc9;
      else if (addr == BOUND_IDX_IOVA + 64'd2)
        boundary_byte = 8'h03;
      else if (addr == BOUND_IDX_IOVA + 64'd3)
        boundary_byte = 8'h00;
      else if ((addr >= BOUND_LAST_ROW) &&
               (addr < BOUND_LAST_ROW + 64'd1088)) begin
        row_offset = addr - BOUND_LAST_ROW;
        case (row_offset % 64'd34)
          64'd0: boundary_byte = 8'h00;
          64'd1: boundary_byte = 8'h3c;
          default: boundary_byte = 8'h00;
        endcase
      end
    end
  endfunction

  function automatic [63:0] load64;
    input [63:0] addr;
    integer k;
    integer base;
    begin
      base = {19'd0, addr[12:0]};
      load64 = 64'd0;
      for (k = 0; k < 8; k = k + 1) begin
        if ((phase == 6) && (addr[63:13] != 51'd0))
          load64[k*8 +: 8] = boundary_byte(
              addr + {32'd0, k[31:0]});
        else
          load64[k*8 +: 8] = gmem[base+k];
      end
    end
  endfunction

  function automatic [31:0] load32;
    input integer addr;
    begin
      load32 = {gmem[addr+3], gmem[addr+2],
                gmem[addr+1], gmem[addr]};
    end
  endfunction

  function automatic [7:0] q8_pattern;
    input integer row;
    input integer qlane;
    integer selector;
    begin
      selector = (qlane + (row * 3)) % 7;
      case (selector)
        0: q8_pattern = 8'h80; // -128
        1: q8_pattern = 8'hfe; // -2
        2: q8_pattern = 8'hff; // -1
        3: q8_pattern = 8'h00;
        4: q8_pattern = 8'h01;
        5: q8_pattern = 8'h02;
        default: q8_pattern = 8'h7f; // +127
      endcase
    end
  endfunction

  function automatic [31:0] q8_scale_one_bits;
    input [7:0] qbits;
    begin
      case (qbits)
        8'h80: q8_scale_one_bits = 32'hc3000000;
        8'hfe: q8_scale_one_bits = 32'hc0000000;
        8'hff: q8_scale_one_bits = 32'hbf800000;
        8'h00: q8_scale_one_bits = 32'h00000000;
        8'h01: q8_scale_one_bits = 32'h3f800000;
        8'h02: q8_scale_one_bits = 32'h40000000;
        8'h7f: q8_scale_one_bits = 32'h42fe0000;
        default: q8_scale_one_bits = 32'h7fc00000;
      endcase
    end
  endfunction

  task automatic configure_identity;
    input [63:0] sequence_value;
    input [31:0] context_value;
    input [63:0] producer;
    input [63:0] user_tag;
    input [63:0] hash_lo;
    input [63:0] hash_hi;
    begin
      macro_abi_valid = 1'b1;
      macro_context_id = context_value;
      macro_capability_epoch = 32'h00000001;
      macro_sequence_id = sequence_value;
      macro_producer_id = producer;
      macro_user_tag = user_tag;
      macro_node_count = 32'd1;
      macro_node_hash_lo = hash_lo;
      macro_node_hash_hi = hash_hi;
      macro_deadline_cycles = 64'd0;
    end
  endtask

  task automatic configure_q8;
    input [63:0] sequence_value;
    input [63:0] dst_base;
    begin
      configure_identity(sequence_value,
          32'hc8100000 | {16'd0, sequence_value[15:0]},
          64'hfedcba9800000000 | {32'd0, sequence_value[31:0]},
          64'h0123456700000000 | {32'd0, sequence_value[31:0]},
          64'h8899aabb00000000 | {32'd0, sequence_value[31:0]},
          64'hccddeeff00000000 | {32'd0, sequence_value[31:0]});
      macro_kernel_id = KERNEL_Q8;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = Q8_SRC_BASE;
      macro_src1_iova = Q8_IDX_BASE;
      macro_src2_iova = 64'd0;
      macro_dst_iova = dst_base;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd32;
      macro_outer_count = 32'd2;
      macro_dtype = 32'd1;
      macro_src0_stride = Q8_SRC_STRIDE;
      macro_src1_stride = Q8_IDX_STRIDE;
      macro_src2_stride = 64'd0;
      macro_dst_stride = Q8_DST_STRIDE;
      macro_scalar0 = 32'd2;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = Q8_SRC_BASE;
      macro_src0_window_size = 64'h50;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = Q8_IDX_BASE;
      macro_src1_window_size = 64'h8;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = dst_base & 64'hffff_ffff_ffff_fff8;
      macro_dst_window_size =
          (((dst_base + 64'd264 + 64'd7) & 64'hffff_ffff_ffff_fff8)
           - macro_dst_window_base);
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
    end
  endtask

  task automatic configure_q8_embedding_boundary;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value, 32'hc8101024,
          64'hf2483200aaaabbbb, 64'he1024000ccccdddd,
          64'h2483200010240001, 64'h2483200010240002);
      macro_kernel_id = KERNEL_Q8;
      macro_command_flags = FLAGS_REQUIRED_PROFILE;
      macro_vector_op = 32'd0;
      macro_vector_flags = 32'd0;
      macro_src0_iova = BOUND_SRC_IOVA;
      macro_src1_iova = BOUND_IDX_IOVA;
      macro_src2_iova = 64'd0;
      macro_dst_iova = BOUND_DST_IOVA;
      macro_scratch_iova = 64'd0;
      macro_element_count = 64'd1024;
      macro_outer_count = 32'd1;
      macro_dtype = 32'd1;
      macro_src0_stride = 64'd1088;
      macro_src1_stride = 64'd4;
      macro_src2_stride = 64'd0;
      macro_dst_stride = 64'd4096;
      macro_scalar0 = BOUND_V;
      macro_scalar1 = 32'd0;
      macro_scratch_bytes = 32'd0;
      macro_rope_position = 32'd0;
      macro_src0_window_base = BOUND_SRC_WINDOW_BASE;
      macro_src0_window_size = BOUND_SRC_WINDOW_SIZE;
      macro_src0_window_perm = 2'b01;
      macro_src1_window_base = BOUND_IDX_WINDOW_BASE;
      macro_src1_window_size = 64'd16;
      macro_src1_window_perm = 2'b01;
      macro_dst_window_base = BOUND_DST_IOVA;
      macro_dst_window_size = 64'd4096;
      macro_dst_window_perm = 2'b10;
      macro_windows_generation_valid = 1'b1;
    end
  endtask

  task automatic configure_vector_p00;
    input [63:0] sequence_value;
    begin
      configure_identity(sequence_value, 32'hc8200010,
          64'hf00df00d11223344, 64'hdeadbeef55667788,
          64'h0102030405060708, 64'h90abcdef12345678);
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
    end
  endtask

  task automatic poison_live_descriptor;
    begin
      macro_abi_valid = 1'b0;
      macro_kernel_id = 32'hffff0000;
      macro_command_flags = 32'hfffffff0;
      macro_context_id = 32'hffffffff;
      macro_capability_epoch = 32'hffffffff;
      macro_sequence_id = 64'hffffffffffffffff;
      macro_producer_id = 64'hffffffffffffffff;
      macro_user_tag = 64'hffffffffffffffff;
      macro_node_count = 32'hffffffff;
      macro_node_hash_lo = 64'hffffffffffffffff;
      macro_node_hash_hi = 64'hffffffffffffffff;
      macro_deadline_cycles = 64'hffffffffffffffff;
      macro_vector_op = 32'hffffffff;
      macro_vector_flags = 32'hffffffff;
      macro_src0_iova = 64'hffffffffffffffff;
      macro_src1_iova = 64'hffffffffffffffff;
      macro_src2_iova = 64'hffffffffffffffff;
      macro_dst_iova = 64'hffffffffffffffff;
      macro_scratch_iova = 64'hffffffffffffffff;
      macro_element_count = 64'hffffffffffffffff;
      macro_outer_count = 32'hffffffff;
      macro_dtype = 32'hffffffff;
      macro_src0_stride = 64'hffffffffffffffff;
      macro_src1_stride = 64'hffffffffffffffff;
      macro_src2_stride = 64'hffffffffffffffff;
      macro_dst_stride = 64'hffffffffffffffff;
      macro_scalar0 = 32'hffffffff;
      macro_scalar1 = 32'hffffffff;
      macro_scratch_bytes = 32'hffffffff;
      macro_rope_position = 32'hffffffff;
      macro_src0_window_base = 64'hffffffffffffffff;
      macro_src0_window_size = 64'hffffffffffffffff;
      macro_src0_window_perm = 2'b11;
      macro_src1_window_base = 64'hffffffffffffffff;
      macro_src1_window_size = 64'hffffffffffffffff;
      macro_src1_window_perm = 2'b11;
      macro_dst_window_base = 64'hffffffffffffffff;
      macro_dst_window_size = 64'hffffffffffffffff;
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
          (completion_macro_q8_mac_count != 64'd0) ||
          (completion_macro_vector_element_count !=
           expected_vector_elements) ||
          (completion_macro_state_update_count != 64'd0) ||
          (completion_macro_npu_cycles == 64'd0)) begin
        $display("[NPU-COPROCESSOR-Q8-GET-ROWS][DBG] valid=%0b macro=%0b req=%0b err=%0b/%0d status=%0d class=%0d kernel=%h flags=%h ctx=%h seq=%h producer=%h user=%h nodes=%0d hash=%h:%h cycles=%0d read=%0d write=%0d elems=%0d",
            completion_valid, completion_is_macro,
            completion_npu_required, completion_error,
            completion_error_code, completion_macro_status,
            completion_macro_error_class, completion_macro_kernel_id,
            completion_macro_command_flags, completion_macro_context_id,
            completion_macro_sequence_id, completion_macro_producer_id,
            completion_macro_user_tag,
            completion_macro_covered_node_count,
            completion_macro_node_hash_hi,
            completion_macro_node_hash_lo,
            completion_macro_npu_cycles,
            completion_macro_gmem_read_bytes,
            completion_macro_gmem_write_bytes,
            completion_macro_vector_element_count);
        fail("macro completion payload/identity/counter mismatch");
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
      if (!macro_cmd_ready)
        fail("macro ready fell on admission edge");
      @(negedge clk);
      macro_cmd_valid = 1'b0;
      poison_live_descriptor();

      waited = 0;
      while (!completion_valid && (waited < MAX_WAIT_CYCLES)) begin
        @(posedge clk);
        waited = waited + 1;
      end
      if (!completion_valid)
        fail("macro command timed out waiting for terminal completion");
      @(negedge clk);
      check_completion_payload();
      held_completion_cycles = completion_macro_npu_cycles;
      for (hold_index = 0; hold_index < 3; hold_index = hold_index + 1) begin
        @(posedge clk);
        @(negedge clk);
        check_completion_payload();
        if (completion_macro_npu_cycles != held_completion_cycles)
          fail("held macro completion cycles changed");
      end

      completion_ready = 1'b1;
      @(posedge clk);
      @(negedge clk);
      completion_ready = 1'b0;
      if (completion_valid)
        fail("macro completion did not retire on ready handshake");
    end
  endtask

  task automatic clear_terminal_error;
    begin
      checks = checks + 1;
      if (!sticky_error || macro_cmd_ready)
        fail("terminal macro failure did not enter fail-closed hold");
      @(negedge clk);
      error_clear = 1'b1;
      @(posedge clk);
      @(negedge clk);
      error_clear = 1'b0;
      if (sticky_error || !macro_cmd_ready)
        fail("error_clear did not reopen clean macro admission");
    end
  endtask

  assign gmem_req_ready = !rst && !gmem_rsp_valid;

  always #5 clk <= ~clk;

  always @(posedge clk) begin
    if (rst) begin
      global_cycles <= 0;
      phase_q <= 0;
      phase_read_requests <= 0;
      total_requests <= 0;
      total_read_requests <= 0;
      total_write_requests <= 0;
      accepted_commands <= 0;
      accepted_completions <= 0;
      saw_boundary_source_first <= 1'b0;
      saw_boundary_source_last <= 1'b0;
      saw_boundary_index_first <= 1'b0;
      saw_boundary_index_second <= 1'b0;
      gmem_rsp_valid <= 1'b0;
      gmem_rsp_rdata <= 64'd0;
      gmem_rsp_error <= 1'b0;
    end else begin
      global_cycles <= global_cycles + 1;
      if (global_cycles > MAX_WAIT_CYCLES * 8)
        fail("global watchdog expired");

      if (phase != phase_q) begin
        phase_q <= phase;
        phase_read_requests <= 0;
      end

      if (macro_cmd_valid && macro_cmd_ready)
        accepted_commands <= accepted_commands + 1;
      if (completion_valid && completion_ready)
        accepted_completions <= accepted_completions + 1;

      if (gmem_rsp_valid && gmem_rsp_ready) begin
        gmem_rsp_valid <= 1'b0;
        gmem_rsp_rdata <= 64'd0;
        gmem_rsp_error <= 1'b0;
      end

      if (gmem_req_valid && gmem_req_ready) begin
        if ((phase != 6) &&
            ((gmem_req_addr[63:13] != 51'd0) ||
             (gmem_req_addr[12:0] > GMEM_LAST_BEAT)))
          fail("GMEM request escaped the TB aperture");
        if ((phase == 2) || (phase == 4))
          fail("static invalid/unknown descriptor issued GMEM traffic");
        if (gmem_req_write &&
            (gmem_req_wstrb != 8'h0f) && (gmem_req_wstrb != 8'hf0))
          fail("macro write used a non-FP32 byte strobe");

        if ((phase == 1) || (phase == 3)) begin
          if (gmem_req_write) begin
            if ((gmem_req_addr < ((phase == 1) ? 64'h240 : 64'h400)) ||
                (gmem_req_addr + 64'd8 >
                 ((phase == 1) ? 64'h350 : 64'h510)))
              fail("Q8 write escaped its private destination window");
          end else if (!(((gmem_req_addr >= 64'h100) &&
                          (gmem_req_addr + 64'd8 <= 64'h150)) ||
                         ((gmem_req_addr >= 64'h180) &&
                          (gmem_req_addr + 64'd8 <= 64'h188)))) begin
            fail("Q8 read escaped its source/index windows");
          end
        end else if (phase == 5) begin
          if (gmem_req_write) begin
            if ((gmem_req_addr < VEC_DST_BASE) ||
                (gmem_req_addr + 64'd8 > VEC_DST_BASE + 64'd64))
              fail("VECTOR_F32 write escaped destination window");
          end else if (!(((gmem_req_addr >= VEC_SRC0_BASE) &&
                          (gmem_req_addr + 64'd8 <=
                           VEC_SRC0_BASE + 64'd64)) ||
                         ((gmem_req_addr >= VEC_SRC1_BASE) &&
                          (gmem_req_addr + 64'd8 <=
                           VEC_SRC1_BASE + 64'd64)))) begin
            fail("VECTOR_F32 read escaped source windows");
          end
        end else if (phase == 6) begin
          if (gmem_req_write) begin
            if ((gmem_req_addr < BOUND_DST_IOVA) ||
                (gmem_req_addr + 64'd8 >
                 BOUND_DST_IOVA + 64'd4096))
              fail("embedding-boundary write escaped private destination");
          end else if (!(((gmem_req_addr >=
                           (BOUND_LAST_ROW & 64'hffff_ffff_ffff_fff8)) &&
                          (gmem_req_addr + 64'd8 <=
                           ((BOUND_LAST_ROW + 64'd1088 + 64'd7) &
                            64'hffff_ffff_ffff_fff8))) ||
                         ((gmem_req_addr >= BOUND_IDX_WINDOW_BASE) &&
                          (gmem_req_addr + 64'd8 <=
                           BOUND_IDX_WINDOW_BASE + 64'd16)))) begin
            fail("embedding-boundary read escaped last-row/index windows");
          end
        end

        total_requests <= total_requests + 1;
        if (gmem_req_write) begin
          total_write_requests <= total_write_requests + 1;
          for (byte_index = 0; byte_index < 8;
               byte_index = byte_index + 1) begin
            if (gmem_req_wstrb[byte_index])
              gmem[{19'd0, gmem_req_addr[12:0]} + byte_index] <=
                  gmem_req_wdata[byte_index*8 +: 8];
          end
          gmem_rsp_rdata <= 64'd0;
          gmem_rsp_error <= 1'b0;
        end else begin
          total_read_requests <= total_read_requests + 1;
          phase_read_requests <= phase_read_requests + 1;
          if (phase == 6) begin
            if (gmem_req_addr ==
                (BOUND_LAST_ROW & 64'hffff_ffff_ffff_fff8))
              saw_boundary_source_first <= 1'b1;
            if (gmem_req_addr ==
                ((BOUND_LAST_ROW + 64'd1088 - 64'd1) &
                 64'hffff_ffff_ffff_fff8))
              saw_boundary_source_last <= 1'b1;
            if (gmem_req_addr == BOUND_IDX_WINDOW_BASE)
              saw_boundary_index_first <= 1'b1;
            if (gmem_req_addr == BOUND_IDX_WINDOW_BASE + 64'd8)
              saw_boundary_index_second <= 1'b1;
          end
          gmem_rsp_rdata <= load64(gmem_req_addr);
          // Phase 3 injects an error on its first accepted index read.  This
          // proves a public error completion cannot publish any destination.
          gmem_rsp_error <= (phase == 3) &&
                            (phase_read_requests == 0);
        end
        gmem_rsp_valid <= 1'b1;
      end
    end
  end

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    macro_cmd_valid = 1'b0;
    completion_ready = 1'b0;
    error_clear = 1'b0;
    phase = 0;
    checks = 0;
    for (byte_index = 0; byte_index < GMEM_BYTES;
         byte_index = byte_index + 1)
      gmem[byte_index] = 8'h00;
    poison_live_descriptor();

    // Two Q8_0 rows, each with binary16 scale 1.0 and distinct signed bytes.
    for (lane = 0; lane < 2; lane = lane + 1) begin
      gmem[Q8_SRC_MEM + lane*Q8_SRC_STRIDE_MEM] = 8'h00;
      gmem[Q8_SRC_MEM + lane*Q8_SRC_STRIDE_MEM + 1] = 8'h3c;
      for (byte_index = 0; byte_index < 32; byte_index = byte_index + 1)
        gmem[Q8_SRC_MEM + lane*Q8_SRC_STRIDE_MEM + 2 + byte_index] =
            q8_pattern(lane, byte_index);
    end
    // Gather IDs [1, 0].
    gmem[Q8_IDX_MEM + 0] = 8'h01;
    gmem[Q8_IDX_MEM + 1] = 8'h00;
    gmem[Q8_IDX_MEM + 2] = 8'h00;
    gmem[Q8_IDX_MEM + 3] = 8'h00;
    gmem[Q8_IDX_MEM + 4] = 8'h00;
    gmem[Q8_IDX_MEM + 5] = 8'h00;
    gmem[Q8_IDX_MEM + 6] = 8'h00;
    gmem[Q8_IDX_MEM + 7] = 8'h00;
    for (byte_index = 32'h0000_0240; byte_index < 32'h0000_0510;
         byte_index = byte_index + 1)
      gmem[byte_index] = 8'ha5;
    for (byte_index = VEC_SRC0_MEM; byte_index < VEC_SRC0_MEM + 64;
         byte_index = byte_index + 1) begin
      gmem[byte_index] = 8'h00;
      gmem[VEC_SRC1_MEM + (byte_index - VEC_SRC0_MEM)] = 8'h00;
      gmem[VEC_DST_MEM + (byte_index - VEC_SRC0_MEM)] = 8'ha5;
    end
    for (byte_index = 32'h900; byte_index < 32'h1900;
         byte_index = byte_index + 1)
      gmem[byte_index] = 8'ha5;

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);

    // 1. Public macro command: real multi-ID Q8_0 -> committed FP32 writes.
    configure_q8(64'h1122334455660001, Q8_DST_BASE);
    before_requests = total_requests;
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(1, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd96, 64'd256, 64'd64);
    checks = checks + 1;
    if ((total_requests - before_requests != 76) ||
        (total_read_requests - before_reads != 12) ||
        (total_write_requests - before_writes != 64))
      fail("Q8 success request counts were not exact");
    for (lane = 0; lane < 32; lane = lane + 1) begin
      checks = checks + 1;
      if (load32(Q8_DST_MEM + lane*4) !=
          q8_scale_one_bits(q8_pattern(1, lane)))
        fail("Q8 gathered row 1 raw FP32 mismatch");
      checks = checks + 1;
      if (load32(Q8_DST_MEM + Q8_DST_STRIDE_MEM + lane*4) !=
          q8_scale_one_bits(q8_pattern(0, lane)))
        fail("Q8 gathered row 0 raw FP32 mismatch");
    end
    for (byte_index = 32'h0000_0240; byte_index < 32'h0000_0244;
         byte_index = byte_index + 1)
      if (gmem[byte_index] != 8'ha5)
        fail("Q8 write touched bytes before private destination");
    for (byte_index = 32'h0000_02c4; byte_index < 32'h0000_02cc;
         byte_index = byte_index + 1)
      if (gmem[byte_index] != 8'ha5)
        fail("Q8 write touched destination row padding");
    for (byte_index = 32'h0000_034c; byte_index < 32'h0000_0350;
         byte_index = byte_index + 1)
      if (gmem[byte_index] != 8'ha5)
        fail("Q8 write touched bytes after private destination");
    if ((command_count != 64'd1) || (completion_count != 64'd1) ||
        (error_count != 64'd0) || (npu_required_issued != 64'd1) ||
        (npu_required_completed != 64'd1) ||
        (macro_command_count != 64'd1) ||
        (macro_completion_count != 64'd1) ||
        (macro_f32_start_count != 64'd0))
      fail("Q8 success aggregate counters did not close");

    // 2. Whole-descriptor preflight: short private window, zero traffic.
    configure_q8(64'h1122334455660002, Q8_DST_BASE);
    macro_dst_window_size = 64'h108;
    before_requests = total_requests;
    execute_macro(2, 1'b1, `NPU_ERR_MACRO_IOVA, 32'd5,
                  64'd0, 64'd0, 64'd0);
    if (total_requests != before_requests)
      fail("invalid Q8 descriptor produced partial traffic");
    if ((npu_required_issued != 64'd2) ||
        (npu_required_completed != 64'd1) ||
        (macro_completion_count != 64'd1))
      fail("invalid REQUIRED Q8 descriptor changed success counters");
    clear_terminal_error();

    // 3. Dynamic GMEM error on the first ID read: no destination write/commit.
    configure_q8(64'h1122334455660003, Q8_DST_ERROR_BASE);
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(3, 1'b1, `NPU_ERR_GMEM_RESPONSE, 32'd6,
                  64'd8, 64'd0, 64'd0);
    if ((total_read_requests - before_reads != 1) ||
        (total_write_requests != before_writes))
      fail("Q8 GMEM error did not stop before private writeback");
    for (byte_index = 32'h0000_0400; byte_index < 32'h0000_0510;
         byte_index = byte_index + 1)
      if (gmem[byte_index] != 8'ha5)
        fail("failed Q8 command made destination bytes visible");
    if ((npu_required_issued != 64'd3) ||
        (npu_required_completed != 64'd1))
      fail("failed REQUIRED Q8 command completed coverage");
    clear_terminal_error();

    // 4. Unknown kernel is rejected by dispatch before either adapter/GMEM.
    configure_q8(64'h1122334455660004, Q8_DST_ERROR_BASE);
    macro_kernel_id = 32'h514e00ff;
    before_requests = total_requests;
    execute_macro(4, 1'b1, `NPU_ERR_MACRO_CAPABILITY, 32'd3,
                  64'd0, 64'd0, 64'd0);
    if (total_requests != before_requests)
      fail("unknown macro kernel reached a GMEM adapter");
    clear_terminal_error();

    // 5. Existing VECTOR_F32 P00 remains selected and fully functional.
    configure_vector_p00(64'h1122334455660010);
    before_requests = total_requests;
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(5, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd128, 64'd64, 64'd16);
    if ((total_requests - before_requests != 32) ||
        (total_read_requests - before_reads != 16) ||
        (total_write_requests - before_writes != 16))
      fail("VECTOR_F32 legacy request counts regressed");
    for (lane = 0; lane < 16; lane = lane + 1)
      if (load32(VEC_DST_MEM + lane*4) != 32'h00000000)
        fail("VECTOR_F32 P00 output regressed");

    // 6. Real embedding boundary: the maximum v1 D and actual Qwen V/stride.
    // The I32 value is V-1 and both source/index IOVAs are above 4 GiB.  A
    // successful transaction therefore proves the complete widened table end
    // survived dispatch without 32/64-bit truncation before the last row read.
    configure_q8_embedding_boundary(64'h1122334455661024);
    before_reads = total_read_requests;
    before_writes = total_write_requests;
    execute_macro(6, 1'b0, `NPU_ERR_NONE, 32'd0,
                  64'd1296, 64'd4096, 64'd1024);
    checks = checks + 1;
    if ((total_read_requests - before_reads != 162) ||
        (total_write_requests - before_writes != 1024) ||
        !saw_boundary_source_first || !saw_boundary_source_last ||
        !saw_boundary_index_first || !saw_boundary_index_second)
      fail("embedding boundary did not reach exact first/last sparse beats");
    if ((BOUND_LAST_ROW !=
         (BOUND_SRC_IOVA + 64'h0000_0000_101a_7bc0)) ||
        (BOUND_SRC_WINDOW_BASE + BOUND_SRC_WINDOW_SIZE !=
         64'h0000_0001_301a_8008) ||
        (BOUND_LAST_ID + 32'd1 != BOUND_V))
      fail("embedding boundary constants lost widened endpoint identity");
    for (lane = 0; lane < 1024; lane = lane + 1)
      if (load32(32'h900 + lane*4) != 32'h00000000)
        fail("embedding boundary Q8 output was not exact +0 FP32");

    checks = checks + 1;
    if ((accepted_commands != 6) || (accepted_completions != 6) ||
        (command_count != 64'd6) || (completion_count != 64'd3) ||
        (error_count != 64'd3) || (npu_required_issued != 64'd5) ||
        (npu_required_completed != 64'd2) ||
        (macro_command_count != 64'd6) ||
        (macro_completion_count != 64'd3) ||
        (macro_f32_start_count != 64'd1) || sticky_error || busy) begin
      $display("[NPU-COPROCESSOR-Q8-GET-ROWS][DBG] accepted=%0d/%0d command=%0d completion=%0d error=%0d required=%0d/%0d macro=%0d/%0d f32=%0d sticky=%0b busy=%0b",
          accepted_commands, accepted_completions, command_count,
          completion_count, error_count, npu_required_issued,
          npu_required_completed, macro_command_count,
          macro_completion_count, macro_f32_start_count,
          sticky_error, busy);
      fail("final public counter closure mismatch");
    end

    $display("[NPU-COPROCESSOR-Q8-GET-ROWS][INFO] q8=ids2/read96/write256/elements64 embedding=D1024/N1/V248320/stride1088/idV-1/read1296/write4096/elements1024 required=5/2 static_fail_closed=1 gmem_error_no_commit=1 unknown_dispatch=1 vector_p00=read128/write64/elements16 identity=full64 node_hash=128 checks=%0d assertions=off waveform=off",
             checks);
    $display("[NPU-COPROCESSOR-Q8-GET-ROWS][PASS]");
    $finish;
  end

endmodule

`default_nettype wire
