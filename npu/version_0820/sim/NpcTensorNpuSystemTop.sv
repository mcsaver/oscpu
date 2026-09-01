`timescale 1ns/1ps
`include "define.v"
`include "tensor_npu_defs.vh"

// Real precise RV64 tensor-command boundary.  The CPU loads all descriptor
// words through its normal DPI memory path; NPU GMEM is a separate raw-byte
// ready/valid aperture and is never populated through a C++ macro shortcut.
module NpcTensorNpuSystemTop #(
  parameter integer LMEM_BYTES = 4096,
  parameter integer Q8_GEMV_PORTAL_ENABLE = 0,
  parameter integer Q8_GEMV_ROW_LANES = 4,
  parameter integer Q8_GEMV_MAC_LANES = 32,
  parameter integer Q8_GEMV_TILE_FUNCTIONAL_ENABLE = 0,
  parameter integer F32_ALU_PORTAL_ENABLE = 0,
  parameter integer F32_ALU_PORTAL_LANES = 8,
  parameter integer F32_MOVER_PORTAL_ENABLE = 0,
  parameter integer F32_MOVER_PORTAL_LANES = 16,
  parameter integer COMMAND_FUNCTIONAL_ENABLE = 0
) (
  input logic clk, input logic rst,
  output logic gmem_req_valid_o, input logic gmem_req_ready_i,
  output logic gmem_req_write_o, output logic [63:0] gmem_req_addr_o,
  output logic [63:0] gmem_req_wdata_o, output logic [7:0] gmem_req_wstrb_o,
  input logic gmem_rsp_valid_i, output logic gmem_rsp_ready_o,
  input logic [63:0] gmem_rsp_rdata_i, input logic gmem_rsp_error_i,
  output logic q8_portal_req_valid_o, input logic q8_portal_req_ready_i,
  output logic [Q8_GEMV_ROW_LANES-1:0] q8_portal_req_mask_o,
  output logic [(Q8_GEMV_ROW_LANES*64)-1:0] q8_portal_req_addr_o,
  input logic q8_portal_rsp_valid_i, output logic q8_portal_rsp_ready_o,
  input logic [Q8_GEMV_ROW_LANES-1:0] q8_portal_rsp_mask_i,
  input logic [(Q8_GEMV_ROW_LANES*272)-1:0] q8_portal_rsp_blocks_i,
  input logic q8_portal_rsp_error_i,
  output logic [63:0] q8_portal_request_count_o,
  output logic [63:0] q8_portal_response_count_o,
  output logic [63:0] q8_portal_block_count_o,
  output logic [63:0] q8_portal_byte_count_o,
  output logic q8_portal_outstanding_o,
  output logic f32_alu_portal_req_valid_o,
  input logic f32_alu_portal_req_ready_i,
  output logic f32_alu_portal_req_write_o,
  output logic [F32_ALU_PORTAL_LANES-1:0] f32_alu_portal_req_mask_o,
  output logic [(F32_ALU_PORTAL_LANES*64)-1:0]
      f32_alu_portal_req_src0_addr_o,
  output logic [(F32_ALU_PORTAL_LANES*64)-1:0]
      f32_alu_portal_req_src1_addr_o,
  output logic [(F32_ALU_PORTAL_LANES*64)-1:0]
      f32_alu_portal_req_dst_addr_o,
  output logic [(F32_ALU_PORTAL_LANES*32)-1:0]
      f32_alu_portal_req_wdata_o,
  input logic f32_alu_portal_rsp_valid_i,
  output logic f32_alu_portal_rsp_ready_o,
  input logic [F32_ALU_PORTAL_LANES-1:0] f32_alu_portal_rsp_mask_i,
  input logic [(F32_ALU_PORTAL_LANES*32)-1:0]
      f32_alu_portal_rsp_src0_data_i,
  input logic [(F32_ALU_PORTAL_LANES*32)-1:0]
      f32_alu_portal_rsp_src1_data_i,
  input logic f32_alu_portal_rsp_error_i,
  output logic [63:0] f32_alu_portal_request_groups_o,
  output logic [63:0] f32_alu_portal_response_groups_o,
  output logic [63:0] f32_alu_portal_read_groups_o,
  output logic [63:0] f32_alu_portal_write_groups_o,
  output logic [63:0] f32_alu_portal_input_words_o,
  output logic [63:0] f32_alu_portal_output_words_o,
  output logic [63:0] f32_alu_portal_read_bytes_o,
  output logic [63:0] f32_alu_portal_write_bytes_o,
  output logic f32_alu_portal_outstanding_o,
  output logic f32_mover_portal_req_valid_o,
  input logic f32_mover_portal_req_ready_i,
  output logic f32_mover_portal_req_write_o,
  output logic [F32_MOVER_PORTAL_LANES-1:0]
      f32_mover_portal_req_mask_o,
  output logic [(F32_MOVER_PORTAL_LANES*64)-1:0]
      f32_mover_portal_req_addr_o,
  output logic [(F32_MOVER_PORTAL_LANES*32)-1:0]
      f32_mover_portal_req_wdata_o,
  input logic f32_mover_portal_rsp_valid_i,
  output logic f32_mover_portal_rsp_ready_o,
  input logic [F32_MOVER_PORTAL_LANES-1:0]
      f32_mover_portal_rsp_mask_i,
  input logic [(F32_MOVER_PORTAL_LANES*32)-1:0]
      f32_mover_portal_rsp_rdata_i,
  input logic f32_mover_portal_rsp_error_i,
  output logic [63:0] f32_mover_portal_request_groups_o,
  output logic [63:0] f32_mover_portal_response_groups_o,
  output logic [63:0] f32_mover_portal_read_groups_o,
  output logic [63:0] f32_mover_portal_write_groups_o,
  output logic [63:0] f32_mover_portal_read_words_o,
  output logic [63:0] f32_mover_portal_write_words_o,
  output logic [63:0] f32_mover_portal_read_bytes_o,
  output logic [63:0] f32_mover_portal_write_bytes_o,
  output logic f32_mover_portal_outstanding_o,
  output logic direct_f32_desc_resident_o,
  output logic descriptor_inflight_o,
  output logic [5:0] descriptor_expected_index_o,
  input logic terminal_allow_i,
  output logic cpu_tensor_serialize_o,
  output logic cpu_tensor_cmd_valid_o, output logic cpu_tensor_cmd_ready_o,
  output logic [63:0] cpu_tensor_cmd_bits_o,
  output logic [7:0] cpu_tensor_cmd_producer_id_o,
  output logic npu_terminal_valid_o, output logic npu_terminal_ready_o,
  output logic [7:0] npu_terminal_producer_id_o,
  output logic npu_terminal_error_o,
  output logic [7:0] npu_terminal_error_code_o,
  output logic npu_identity_match_o, output logic [7:0] launch_cpu_pid_o,
  output logic macro_completion_valid_o,
  output logic [31:0] macro_completion_status_o,
  output logic [31:0] macro_completion_error_class_o,
  output logic [31:0] macro_completion_kernel_id_o,
  output logic [31:0] macro_completion_command_flags_o,
  output logic [31:0] macro_completion_vector_flags_o,
  output logic [31:0] macro_completion_context_id_o,
  output logic [63:0] macro_completion_sequence_id_o,
  output logic [63:0] completion_macro_producer_id_o,
  output logic [63:0] macro_completion_user_tag_o,
  output logic [31:0] macro_completion_covered_node_count_o,
  output logic [63:0] macro_completion_node_hash_lo_o,
  output logic [63:0] macro_completion_node_hash_hi_o,
  output logic [63:0] macro_completion_npu_cycles_o,
  output logic [63:0] macro_completion_gmem_read_bytes_o,
  output logic [63:0] macro_completion_gmem_write_bytes_o,
  output logic [63:0] macro_completion_q8_mac_count_o,
  output logic [63:0] macro_completion_vector_element_count_o,
  output logic [63:0] macro_completion_state_update_count_o,
  output logic cpu_commit0_valid_o, output logic [63:0] cpu_commit0_pc_o,
  output logic [31:0] cpu_commit0_inst_o,
  output logic cpu_commit0_rd_en_o, output logic cpu_commit0_exception_o,
  output logic [63:0] cpu_debug_pc_o,
  output logic [63:0] npu_command_count_o,
  output logic [63:0] npu_completion_count_o,
  output logic [63:0] npu_error_count_o,
  output logic [63:0] npu_required_issued_o,
  output logic [63:0] npu_required_completed_o,
  output logic [63:0] npu_macro_command_count_o,
  output logic [63:0] npu_macro_f32_start_count_o,
  output logic [63:0] npu_macro_completion_count_o
);
  localparam [63:0] DIRECT_MACRO_BITS = 64'h0bf0305b0220305b;
  localparam [2:0] DESC_EMPTY=3'd0, DESC_BUILD=3'd1,
      DESC_RESIDENT=3'd2, DESC_POISON=3'd3, DESC_INFLIGHT=3'd4;

  logic cpu_cmd_valid_w, cpu_cmd_ready_w, cpu_cmd_is_64_w;
  logic cpu_cmd_required_w, cpu_completion_ready_w;
  logic [63:0] cpu_cmd_rs_value_w;
  logic [7:0] cpu_cmd_opclass_w;
  logic legacy_cmd_ready_w, macro_cmd_ready_w;
  logic npu_completion_valid_w, npu_completion_ready_w;
  logic [7:0] npu_completion_pid_w, npu_completion_error_code_w;
  logic npu_completion_error_w, npu_completion_is_macro_w;
  logic npu_completion_required_unused_w;
  logic [7:0] npu_completion_opclass_unused_w;
  logic [31:0] nc_status_w, nc_error_class_w;
  logic [31:0] nc_kernel_w, nc_flags_w, nc_vector_flags_w, nc_context_w;
  logic [31:0] nc_node_count_w;
  logic [63:0] nc_sequence_w, nc_producer_w, nc_user_tag_w;
  logic [63:0] nc_hash_lo_w, nc_hash_hi_w;
  logic [63:0] nc_npu_cycles_w, nc_read_bytes_w, nc_write_bytes_w;
  logic [63:0] nc_q8_macs_w, nc_vector_elements_w, nc_state_updates_w;

  logic [2:0] desc_state_q;
  logic [5:0] desc_expected_q;
  logic [31:0] d_kernel_q, d_flags_q, d_context_q, d_epoch_q;
  logic [63:0] d_sequence_q, d_producer_q, d_user_tag_q;
  logic [31:0] d_node_count_q, d_vector_op_q;
  logic [63:0] d_hash_lo_q, d_hash_hi_q, d_deadline_q;
  logic [31:0] d_vector_flags_q, d_outer_q;
  logic [63:0] d_src0_q, d_src1_q, d_src2_q, d_dst_q, d_scratch_q;
  logic [63:0] d_elements_q;
  logic [31:0] d_dtype_q, d_scalar0_q, d_scalar1_q, d_scratch_bytes_q;
  logic [31:0] d_rope_position_q;
  logic [63:0] d_src0_stride_q, d_src1_stride_q, d_src2_stride_q;
  logic [63:0] d_dst_stride_q;
  logic [63:0] d_src0_base_q, d_src0_size_q, d_src1_base_q, d_src1_size_q;
  logic [63:0] d_dst_base_q, d_dst_size_q;
  logic d_abi_valid_q, d_windows_valid_q;
  logic [1:0] d_src0_perm_q, d_src1_perm_q, d_dst_perm_q;
  logic local_valid_q, local_error_q;
  logic [7:0] local_pid_q, local_error_code_q, launch_cpu_pid_q;

  wire direct_cfg_w = !cpu_cmd_is_64_w &&
      cpu_tensor_cmd_bits_o[31:25]==7'b0000101 &&
      cpu_tensor_cmd_bits_o[14:12]==`NPU_FUNCT3_CONFIG &&
      cpu_tensor_cmd_bits_o[11:7]==5'd31 &&
      cpu_tensor_cmd_bits_o[6:0]==`NPU_CUSTOM2_OPCODE;
  wire [4:0] cfg_index_w = cpu_tensor_cmd_bits_o[24:20];
  wire direct_macro_w = cpu_cmd_is_64_w &&
      cpu_tensor_cmd_bits_o==DIRECT_MACRO_BITS;
  wire resident_w = desc_state_q==DESC_RESIDENT;
  wire inflight_w = desc_state_q==DESC_INFLIGHT;
  // The real CPU has already issued the serializing LO/HI pair while the
  // descriptor is INFLIGHT, so it cannot make architectural progress until
  // the NPU terminal arrives.  Stop toggling only the CPU submodule during
  // that wait.  The NPU, descriptor FSM and completion path continue on the
  // ungated system clock; raw completion valid re-enables the CPU clock so
  // the same real sidecar accepts the terminal and retires the launch.  This
  // simulation-wrapper clock gate removes irrelevant OOO-core evaluation
  // from long tensor kernels without bypassing any CPU command, terminal or
  // commit edge.
  //
  // Update the enable only while the source clock is low.  A Coprocessor
  // completion is registered on posedge clk and can therefore rise during
  // the following high phase; using it in a combinational clock AND would
  // create a late CPU posedge on which only the consumer observes the
  // terminal.  The negedge register is the simulation equivalent of a
  // glitch-free low-phase ICG latch: launch gets a complete high pulse,
  // completion wakes the CPU at the next real system posedge, and reset is
  // sampled by the CPU only on an aligned edge.  The declaration initializer
  // keeps the first reset edge available before the first source negedge.
  logic cpu_clk_enable_q = 1'b1;
  always_ff @(negedge clk) begin
    if (rst)
      cpu_clk_enable_q <= 1'b1;
    else
      cpu_clk_enable_q <= !inflight_w || npu_completion_valid_w;
  end
  wire cpu_clk_w = clk && cpu_clk_enable_q;
  wire macro_valid_w = cpu_cmd_valid_w && direct_macro_w && resident_w &&
      !local_valid_q;
  wire macro_fire_w = macro_valid_w && macro_cmd_ready_w;
  wire cfg_fire_w = cpu_cmd_valid_w && cpu_cmd_ready_w && direct_cfg_w;
  wire bad_macro_fire_w = cpu_cmd_valid_w && cpu_cmd_ready_w &&
      direct_macro_w && !resident_w;
  wire legacy_valid_w = cpu_cmd_valid_w && !direct_cfg_w && !direct_macro_w;

  always_comb begin
    if (direct_cfg_w)
      cpu_cmd_ready_w = !local_valid_q && !inflight_w;
    else if (direct_macro_w)
      cpu_cmd_ready_w = resident_w ? (!local_valid_q && macro_cmd_ready_w) :
                                    (!local_valid_q && !inflight_w);
    else
      cpu_cmd_ready_w = legacy_cmd_ready_w;
  end

  wire local_fire_w = local_valid_q && cpu_completion_ready_w &&
      terminal_allow_i;
  assign npu_completion_ready_w = !local_valid_q && cpu_completion_ready_w &&
      terminal_allow_i;
  wire npu_fire_w = npu_completion_valid_w && npu_completion_ready_w;
  wire identity_match_w = inflight_w && npu_completion_is_macro_w &&
      nc_kernel_w==d_kernel_q && nc_flags_w==d_flags_q &&
      nc_vector_flags_w==d_vector_flags_q && nc_context_w==d_context_q &&
      nc_sequence_w==d_sequence_q && nc_producer_w==d_producer_q &&
      nc_user_tag_w==d_user_tag_q && nc_node_count_w==d_node_count_q &&
      nc_hash_lo_w==d_hash_lo_q && nc_hash_hi_w==d_hash_hi_q;
  wire identity_error_w = inflight_w && !identity_match_w;
  wire selected_npu_error_w = npu_completion_error_w || identity_error_w;
  wire [7:0] selected_npu_code_w = identity_error_w ?
      `NPU_ERR_MACRO_PROTOCOL : npu_completion_error_code_w;

  assign direct_f32_desc_resident_o=resident_w;
  assign descriptor_inflight_o=inflight_w;
  assign descriptor_expected_index_o=desc_expected_q;
  assign launch_cpu_pid_o=launch_cpu_pid_q;
  assign macro_completion_valid_o=npu_completion_valid_w &&
      npu_completion_is_macro_w;
  assign macro_completion_status_o=nc_status_w;
  assign macro_completion_error_class_o=nc_error_class_w;
  assign macro_completion_kernel_id_o=nc_kernel_w;
  assign macro_completion_command_flags_o=nc_flags_w;
  assign macro_completion_vector_flags_o=nc_vector_flags_w;
  assign macro_completion_context_id_o=nc_context_w;
  assign macro_completion_sequence_id_o=nc_sequence_w;
  assign completion_macro_producer_id_o=nc_producer_w;
  assign macro_completion_user_tag_o=nc_user_tag_w;
  assign macro_completion_covered_node_count_o=nc_node_count_w;
  assign macro_completion_node_hash_lo_o=nc_hash_lo_w;
  assign macro_completion_node_hash_hi_o=nc_hash_hi_w;
  assign macro_completion_npu_cycles_o=nc_npu_cycles_w;
  assign macro_completion_gmem_read_bytes_o=nc_read_bytes_w;
  assign macro_completion_gmem_write_bytes_o=nc_write_bytes_w;
  assign macro_completion_q8_mac_count_o=nc_q8_macs_w;
  assign macro_completion_vector_element_count_o=nc_vector_elements_w;
  assign macro_completion_state_update_count_o=nc_state_updates_w;
  assign npu_identity_match_o=npu_completion_valid_w && identity_match_w;
  assign cpu_tensor_cmd_valid_o=cpu_cmd_valid_w;
  assign cpu_tensor_cmd_ready_o=cpu_cmd_ready_w;
  assign npu_terminal_valid_o=local_valid_q || npu_completion_valid_w;
  assign npu_terminal_ready_o=cpu_completion_ready_w && terminal_allow_i;
  assign npu_terminal_producer_id_o=local_valid_q ? local_pid_q :
      (inflight_w ? launch_cpu_pid_q : npu_completion_pid_w);
  assign npu_terminal_error_o=local_valid_q ? local_error_q : selected_npu_error_w;
  assign npu_terminal_error_code_o=local_valid_q ? local_error_code_q :
      selected_npu_code_w;

  wire cpu_terminal_valid_w=(local_valid_q || npu_completion_valid_w) &&
      terminal_allow_i;
  wire [7:0] cpu_terminal_pid_w=local_valid_q ? local_pid_q :
      (inflight_w ? launch_cpu_pid_q : npu_completion_pid_w);
  wire cpu_terminal_error_w=local_valid_q ? local_error_q : selected_npu_error_w;
  wire [7:0] cpu_terminal_code_w=local_valid_q ? local_error_code_q :
      selected_npu_code_w;

  always_ff @(posedge clk) begin
    if (rst) begin
      desc_state_q<=DESC_EMPTY; desc_expected_q<=0;
      d_kernel_q<=0; d_flags_q<=0; d_context_q<=0; d_epoch_q<=0;
      d_sequence_q<=0; d_producer_q<=0; d_user_tag_q<=0;
      d_node_count_q<=0; d_vector_op_q<=0; d_hash_lo_q<=0; d_hash_hi_q<=0;
      d_deadline_q<=0; d_vector_flags_q<=0; d_outer_q<=0;
      d_src0_q<=0; d_src1_q<=0; d_src2_q<=0; d_dst_q<=0; d_scratch_q<=0;
      d_elements_q<=0; d_dtype_q<=0; d_scalar0_q<=0; d_scalar1_q<=0;
      d_scratch_bytes_q<=0; d_rope_position_q<=0;
      d_src0_stride_q<=0; d_src1_stride_q<=0; d_src2_stride_q<=0;
      d_dst_stride_q<=0; d_src0_base_q<=0; d_src0_size_q<=0;
      d_src1_base_q<=0; d_src1_size_q<=0; d_dst_base_q<=0; d_dst_size_q<=0;
      d_abi_valid_q<=0; d_windows_valid_q<=0;
      d_src0_perm_q<=0; d_src1_perm_q<=0; d_dst_perm_q<=0;
      local_valid_q<=0; local_pid_q<=0; local_error_q<=0;
      local_error_code_q<=`NPU_ERR_NONE; launch_cpu_pid_q<=0;
    end else begin
      if (local_fire_w) local_valid_q<=0;
      if (cfg_fire_w) begin
        local_valid_q<=1; local_pid_q<=cpu_tensor_cmd_producer_id_o;
        local_error_q<=0; local_error_code_q<=`NPU_ERR_NONE;
        if (cfg_index_w==5'd30) begin
          desc_state_q<=DESC_EMPTY; desc_expected_q<=0;
          d_kernel_q<=0; d_flags_q<=0; d_context_q<=0; d_epoch_q<=0;
          d_sequence_q<=0; d_producer_q<=0; d_user_tag_q<=0;
          d_node_count_q<=0; d_vector_op_q<=0; d_hash_lo_q<=0; d_hash_hi_q<=0;
          d_deadline_q<=0; d_vector_flags_q<=0; d_outer_q<=0;
          d_src0_q<=0; d_src1_q<=0; d_src2_q<=0; d_dst_q<=0; d_scratch_q<=0;
          d_elements_q<=0; d_dtype_q<=0; d_scalar0_q<=0; d_scalar1_q<=0;
          d_scratch_bytes_q<=0; d_rope_position_q<=0;
          d_src0_stride_q<=0; d_src1_stride_q<=0; d_src2_stride_q<=0;
          d_dst_stride_q<=0; d_src0_base_q<=0; d_src0_size_q<=0;
          d_src1_base_q<=0; d_src1_size_q<=0; d_dst_base_q<=0; d_dst_size_q<=0;
          d_abi_valid_q<=0; d_windows_valid_q<=0;
          d_src0_perm_q<=0; d_src1_perm_q<=0; d_dst_perm_q<=0;
          launch_cpu_pid_q<=0;
        end else if (cfg_index_w==5'd31) begin
          desc_state_q<=DESC_POISON; desc_expected_q<=0;
          local_error_q<=1; local_error_code_q<=`NPU_ERR_MACRO_PROTOCOL;
        end else if ((desc_state_q==DESC_EMPTY && cfg_index_w==0) ||
                     (desc_state_q==DESC_BUILD && {1'b0,cfg_index_w}==desc_expected_q)) begin
          case (cfg_index_w)
            0: begin d_kernel_q<=cpu_cmd_rs_value_w[31:0]; d_flags_q<=cpu_cmd_rs_value_w[63:32]; desc_state_q<=DESC_BUILD; desc_expected_q<=1; end
            1: begin d_context_q<=cpu_cmd_rs_value_w[31:0]; d_epoch_q<=cpu_cmd_rs_value_w[63:32]; desc_expected_q<=2; end
            2: begin d_sequence_q<=cpu_cmd_rs_value_w; desc_expected_q<=3; end
            3: begin d_producer_q<=cpu_cmd_rs_value_w; desc_expected_q<=4; end
            4: begin d_user_tag_q<=cpu_cmd_rs_value_w; desc_expected_q<=5; end
            5: begin d_node_count_q<=cpu_cmd_rs_value_w[31:0]; d_vector_op_q<=cpu_cmd_rs_value_w[63:32]; desc_expected_q<=6; end
            6: begin d_hash_lo_q<=cpu_cmd_rs_value_w; desc_expected_q<=7; end
            7: begin d_hash_hi_q<=cpu_cmd_rs_value_w; desc_expected_q<=8; end
            8: begin d_deadline_q<=cpu_cmd_rs_value_w; desc_expected_q<=9; end
            9: begin d_vector_flags_q<=cpu_cmd_rs_value_w[31:0]; d_outer_q<=cpu_cmd_rs_value_w[63:32]; desc_expected_q<=10; end
            10: begin d_src0_q<=cpu_cmd_rs_value_w; desc_expected_q<=11; end
            11: begin d_src1_q<=cpu_cmd_rs_value_w; desc_expected_q<=12; end
            12: begin d_src2_q<=cpu_cmd_rs_value_w; desc_expected_q<=13; end
            13: begin d_dst_q<=cpu_cmd_rs_value_w; desc_expected_q<=14; end
            14: begin d_scratch_q<=cpu_cmd_rs_value_w; desc_expected_q<=15; end
            15: begin d_elements_q<=cpu_cmd_rs_value_w; desc_expected_q<=16; end
            16: begin d_dtype_q<=cpu_cmd_rs_value_w[31:0]; d_scalar0_q<=cpu_cmd_rs_value_w[63:32]; desc_expected_q<=17; end
            17: begin d_scalar1_q<=cpu_cmd_rs_value_w[31:0]; d_scratch_bytes_q<=cpu_cmd_rs_value_w[63:32]; desc_expected_q<=18; end
            18: begin d_rope_position_q<=cpu_cmd_rs_value_w[31:0]; desc_expected_q<=19;
              if (cpu_cmd_rs_value_w[63:32]!=0) begin desc_state_q<=DESC_POISON; desc_expected_q<=0; local_error_q<=1; local_error_code_q<=`NPU_ERR_MACRO_PROTOCOL; end end
            19: begin d_src0_stride_q<=cpu_cmd_rs_value_w; desc_expected_q<=20; end
            20: begin d_src1_stride_q<=cpu_cmd_rs_value_w; desc_expected_q<=21; end
            21: begin d_src2_stride_q<=cpu_cmd_rs_value_w; desc_expected_q<=22; end
            22: begin d_dst_stride_q<=cpu_cmd_rs_value_w; desc_expected_q<=23; end
            23: begin d_src0_base_q<=cpu_cmd_rs_value_w; desc_expected_q<=24; end
            24: begin d_src0_size_q<=cpu_cmd_rs_value_w; desc_expected_q<=25; end
            25: begin
              d_abi_valid_q<=cpu_cmd_rs_value_w[0]; d_windows_valid_q<=cpu_cmd_rs_value_w[1];
              d_src0_perm_q<=cpu_cmd_rs_value_w[3:2]; d_src1_perm_q<=cpu_cmd_rs_value_w[5:4]; d_dst_perm_q<=cpu_cmd_rs_value_w[7:6]; desc_expected_q<=26;
              if (cpu_cmd_rs_value_w[63:8]!=0) begin desc_state_q<=DESC_POISON; desc_expected_q<=0; local_error_q<=1; local_error_code_q<=`NPU_ERR_MACRO_PROTOCOL; end end
            26: begin d_src1_base_q<=cpu_cmd_rs_value_w; desc_expected_q<=27; end
            27: begin d_src1_size_q<=cpu_cmd_rs_value_w; desc_expected_q<=28; end
            28: begin d_dst_base_q<=cpu_cmd_rs_value_w; desc_expected_q<=29; end
            29: begin d_dst_size_q<=cpu_cmd_rs_value_w; desc_state_q<=DESC_RESIDENT; desc_expected_q<=30; end
            default: begin end
          endcase
        end else begin
          desc_state_q<=DESC_POISON; desc_expected_q<=0;
          local_error_q<=1; local_error_code_q<=`NPU_ERR_MACRO_PROTOCOL;
        end
      end
      if (bad_macro_fire_w) begin
        desc_state_q<=DESC_POISON; desc_expected_q<=0;
        local_valid_q<=1; local_pid_q<=cpu_tensor_cmd_producer_id_o;
        local_error_q<=1; local_error_code_q<=`NPU_ERR_MACRO_PROTOCOL;
      end
      if (macro_fire_w) begin
        desc_state_q<=DESC_INFLIGHT;
        launch_cpu_pid_q<=cpu_tensor_cmd_producer_id_o;
      end
      // Any completion belonging to the sole admitted macro is drained.  A
      // bad identity is already translated into a precise protocol terminal.
      if (npu_fire_w && inflight_w) begin
        desc_state_q<=DESC_EMPTY; desc_expected_q<=0;
        d_kernel_q<=0; d_flags_q<=0; d_context_q<=0; d_epoch_q<=0;
        d_sequence_q<=0; d_producer_q<=0; d_user_tag_q<=0;
        d_node_count_q<=0; d_vector_op_q<=0; d_hash_lo_q<=0; d_hash_hi_q<=0;
        d_deadline_q<=0; d_vector_flags_q<=0; d_outer_q<=0;
        d_src0_q<=0; d_src1_q<=0; d_src2_q<=0; d_dst_q<=0; d_scratch_q<=0;
        d_elements_q<=0; d_dtype_q<=0; d_scalar0_q<=0; d_scalar1_q<=0;
        d_scratch_bytes_q<=0; d_rope_position_q<=0;
        d_src0_stride_q<=0; d_src1_stride_q<=0; d_src2_stride_q<=0;
        d_dst_stride_q<=0; d_src0_base_q<=0; d_src0_size_q<=0;
        d_src1_base_q<=0; d_src1_size_q<=0; d_dst_base_q<=0; d_dst_size_q<=0;
        d_abi_valid_q<=0; d_windows_valid_q<=0;
        d_src0_perm_q<=0; d_src1_perm_q<=0; d_dst_perm_q<=0;
        launch_cpu_pid_q<=0;
      end
    end
  end

  assign cpu_commit0_valid_o=u_cpu.core_commit0_valid_w;
  assign cpu_commit0_pc_o=u_cpu.core_commit0_pc_w;
  assign cpu_commit0_inst_o=u_cpu.core_commit0_inst_w;
  assign cpu_commit0_rd_en_o=u_cpu.core_commit0_rd_en_w;
  assign cpu_commit0_exception_o=u_cpu.core_commit0_exception_w;

  NpcSimTop u_cpu (
    .clk(cpu_clk_w),.rst(rst),.tensor_cmd_valid_o(cpu_cmd_valid_w),
    .tensor_cmd_ready_i(cpu_cmd_ready_w),.tensor_cmd_bits_o(cpu_tensor_cmd_bits_o),
    .tensor_cmd_rs_value_o(cpu_cmd_rs_value_w),
    .tensor_cmd_producer_id_o(cpu_tensor_cmd_producer_id_o),
    .tensor_cmd_is_64_o(cpu_cmd_is_64_w),.tensor_cmd_required_o(cpu_cmd_required_w),
    .tensor_cmd_opclass_o(cpu_cmd_opclass_w),
    .tensor_terminal_valid_i(cpu_terminal_valid_w),
    .tensor_terminal_ready_o(cpu_completion_ready_w),
    .tensor_terminal_producer_id_i(cpu_terminal_pid_w),
    .tensor_terminal_error_i(cpu_terminal_error_w),
    .tensor_terminal_error_code_i(cpu_terminal_code_w),
    .tensor_serialize_o(cpu_tensor_serialize_o),.debug_pc_o(cpu_debug_pc_o),
    .debug_state_o(),.debug_ooo_flags_o(),.debug_ooo_satp_o(),
    .debug_bus_flags_o(),.debug_bus2_flags_o(),.debug_fetch_addr_o(),
    .debug_mem_addr_o(),.debug_mem_diag_o(),.debug_fetch_pte_addr_o(),
    .debug_fetch_pte_o(),.debug_fetch_pte_meta_o(),.debug_clint_mtime_o()
  );

  TensorNpuCoprocessor #(
    .LMEM_BYTES(LMEM_BYTES),
    .PID_W(8),
    .OPCLASS_W(8),
    .Q8_GEMV_PORTAL_ENABLE(Q8_GEMV_PORTAL_ENABLE),
    .Q8_GEMV_ROW_LANES(Q8_GEMV_ROW_LANES),
    .Q8_GEMV_MAC_LANES(Q8_GEMV_MAC_LANES),
    .Q8_GEMV_TILE_FUNCTIONAL_ENABLE(Q8_GEMV_TILE_FUNCTIONAL_ENABLE),
    .F32_ALU_PORTAL_ENABLE(F32_ALU_PORTAL_ENABLE),
    .F32_ALU_PORTAL_LANES(F32_ALU_PORTAL_LANES),
    .F32_MOVER_PORTAL_ENABLE(F32_MOVER_PORTAL_ENABLE),
    .F32_MOVER_PORTAL_LANES(F32_MOVER_PORTAL_LANES),
    .COMMAND_FUNCTIONAL_ENABLE(COMMAND_FUNCTIONAL_ENABLE)
  ) u_npu (
    .clk(clk),.rst(rst),.cmd_valid_i(legacy_valid_w),.cmd_ready_o(legacy_cmd_ready_w),
    .cmd_is_64_i(cpu_cmd_is_64_w),.cmd_bits_i(cpu_tensor_cmd_bits_o),
    .cmd_rs_value_i(cpu_cmd_rs_value_w),.cmd_producer_id_i(cpu_tensor_cmd_producer_id_o),
    .cmd_npu_required_i(cpu_cmd_required_w),.cmd_opclass_i(cpu_cmd_opclass_w),
    .macro_cmd_valid_i(macro_valid_w),.macro_cmd_ready_o(macro_cmd_ready_w),
    .macro_abi_valid_i(d_abi_valid_q),.macro_kernel_id_i(d_kernel_q),
    .macro_command_flags_i(d_flags_q),.macro_context_id_i(d_context_q),
    .macro_capability_epoch_i(d_epoch_q),.macro_sequence_id_i(d_sequence_q),
    .macro_producer_id_i(d_producer_q),.macro_user_tag_i(d_user_tag_q),
    .macro_node_count_i(d_node_count_q),.macro_node_hash_lo_i(d_hash_lo_q),
    .macro_node_hash_hi_i(d_hash_hi_q),.macro_deadline_cycles_i(d_deadline_q),
    .macro_vector_op_i(d_vector_op_q),.macro_vector_flags_i(d_vector_flags_q),
    .macro_src0_iova_i(d_src0_q),.macro_src1_iova_i(d_src1_q),
    .macro_src2_iova_i(d_src2_q),.macro_dst_iova_i(d_dst_q),
    .macro_scratch_iova_i(d_scratch_q),.macro_element_count_i(d_elements_q),
    .macro_outer_count_i(d_outer_q),.macro_dtype_i(d_dtype_q),
    .macro_src0_stride_i(d_src0_stride_q),.macro_src1_stride_i(d_src1_stride_q),
    .macro_src2_stride_i(d_src2_stride_q),.macro_dst_stride_i(d_dst_stride_q),
    .macro_scalar0_i(d_scalar0_q),.macro_scalar1_i(d_scalar1_q),
    .macro_scratch_bytes_i(d_scratch_bytes_q),.macro_rope_position_i(d_rope_position_q),
    .macro_src0_window_base_i(d_src0_base_q),.macro_src0_window_size_i(d_src0_size_q),
    .macro_src0_window_perm_i(d_src0_perm_q),.macro_src1_window_base_i(d_src1_base_q),
    .macro_src1_window_size_i(d_src1_size_q),.macro_src1_window_perm_i(d_src1_perm_q),
    .macro_dst_window_base_i(d_dst_base_q),.macro_dst_window_size_i(d_dst_size_q),
    .macro_dst_window_perm_i(d_dst_perm_q),
    .macro_windows_generation_valid_i(d_windows_valid_q),
    .completion_valid_o(npu_completion_valid_w),.completion_ready_i(npu_completion_ready_w),
    .completion_producer_id_o(npu_completion_pid_w),
    .completion_npu_required_o(npu_completion_required_unused_w),
    .completion_opclass_o(npu_completion_opclass_unused_w),
    .completion_error_o(npu_completion_error_w),
    .completion_error_code_o(npu_completion_error_code_w),
    .completion_is_macro_o(npu_completion_is_macro_w),
    .completion_macro_status_o(nc_status_w),
    .completion_macro_error_class_o(nc_error_class_w),
    .completion_macro_kernel_id_o(nc_kernel_w),
    .completion_macro_command_flags_o(nc_flags_w),
    .completion_macro_vector_flags_o(nc_vector_flags_w),
    .completion_macro_context_id_o(nc_context_w),
    .completion_macro_sequence_id_o(nc_sequence_w),
    .completion_macro_producer_id_o(nc_producer_w),
    .completion_macro_user_tag_o(nc_user_tag_w),
    .completion_macro_covered_node_count_o(nc_node_count_w),
    .completion_macro_node_hash_lo_o(nc_hash_lo_w),
    .completion_macro_node_hash_hi_o(nc_hash_hi_w),
    .completion_macro_npu_cycles_o(nc_npu_cycles_w),
    .completion_macro_gmem_read_bytes_o(nc_read_bytes_w),
    .completion_macro_gmem_write_bytes_o(nc_write_bytes_w),
    .completion_macro_q8_mac_count_o(nc_q8_macs_w),
    .completion_macro_vector_element_count_o(nc_vector_elements_w),
    .completion_macro_state_update_count_o(nc_state_updates_w),
    .desc_write_valid_i(1'b0),.desc_write_ready_o(),.desc_write_id_i(6'b0),
    .desc_write_word_i(3'b0),.desc_write_data_i(64'b0),
    .desc_write_error_o(),.desc_write_error_code_o(),
    .host_lmem_rd_valid_i(1'b0),.host_lmem_rd_addr_i(32'b0),
    .host_lmem_rd_bytes_i(4'b0),.host_lmem_rd_data_o(),.host_lmem_rd_oob_o(),
    .host_lmem_wr_valid_i(1'b0),.host_lmem_wr_addr_i(32'b0),
    .host_lmem_wr_data_i(64'b0),.host_lmem_wr_strb_i(8'b0),
    .host_lmem_wr_oob_o(),.host_lmem_ready_o(),
    .gmem_req_valid_o(gmem_req_valid_o),.gmem_req_ready_i(gmem_req_ready_i),
    .gmem_req_write_o(gmem_req_write_o),.gmem_req_addr_o(gmem_req_addr_o),
    .gmem_req_wdata_o(gmem_req_wdata_o),.gmem_req_wstrb_o(gmem_req_wstrb_o),
    .gmem_rsp_valid_i(gmem_rsp_valid_i),.gmem_rsp_ready_o(gmem_rsp_ready_o),
    .gmem_rsp_rdata_i(gmem_rsp_rdata_i),.gmem_rsp_error_i(gmem_rsp_error_i),
    .q8_portal_req_valid_o(q8_portal_req_valid_o),
    .q8_portal_req_ready_i(q8_portal_req_ready_i),
    .q8_portal_req_mask_o(q8_portal_req_mask_o),
    .q8_portal_req_addr_o(q8_portal_req_addr_o),
    .q8_portal_rsp_valid_i(q8_portal_rsp_valid_i),
    .q8_portal_rsp_ready_o(q8_portal_rsp_ready_o),
    .q8_portal_rsp_mask_i(q8_portal_rsp_mask_i),
    .q8_portal_rsp_blocks_i(q8_portal_rsp_blocks_i),
    .q8_portal_rsp_error_i(q8_portal_rsp_error_i),
    .q8_portal_request_count_o(q8_portal_request_count_o),
    .q8_portal_response_count_o(q8_portal_response_count_o),
    .q8_portal_block_count_o(q8_portal_block_count_o),
    .q8_portal_byte_count_o(q8_portal_byte_count_o),
    .q8_portal_outstanding_o(q8_portal_outstanding_o),
    .f32_alu_portal_req_valid_o(f32_alu_portal_req_valid_o),
    .f32_alu_portal_req_ready_i(f32_alu_portal_req_ready_i),
    .f32_alu_portal_req_write_o(f32_alu_portal_req_write_o),
    .f32_alu_portal_req_mask_o(f32_alu_portal_req_mask_o),
    .f32_alu_portal_req_src0_addr_o(f32_alu_portal_req_src0_addr_o),
    .f32_alu_portal_req_src1_addr_o(f32_alu_portal_req_src1_addr_o),
    .f32_alu_portal_req_dst_addr_o(f32_alu_portal_req_dst_addr_o),
    .f32_alu_portal_req_wdata_o(f32_alu_portal_req_wdata_o),
    .f32_alu_portal_rsp_valid_i(f32_alu_portal_rsp_valid_i),
    .f32_alu_portal_rsp_ready_o(f32_alu_portal_rsp_ready_o),
    .f32_alu_portal_rsp_mask_i(f32_alu_portal_rsp_mask_i),
    .f32_alu_portal_rsp_src0_data_i(f32_alu_portal_rsp_src0_data_i),
    .f32_alu_portal_rsp_src1_data_i(f32_alu_portal_rsp_src1_data_i),
    .f32_alu_portal_rsp_error_i(f32_alu_portal_rsp_error_i),
    .f32_alu_portal_request_groups_o(f32_alu_portal_request_groups_o),
    .f32_alu_portal_response_groups_o(f32_alu_portal_response_groups_o),
    .f32_alu_portal_read_groups_o(f32_alu_portal_read_groups_o),
    .f32_alu_portal_write_groups_o(f32_alu_portal_write_groups_o),
    .f32_alu_portal_input_words_o(f32_alu_portal_input_words_o),
    .f32_alu_portal_output_words_o(f32_alu_portal_output_words_o),
    .f32_alu_portal_read_bytes_o(f32_alu_portal_read_bytes_o),
    .f32_alu_portal_write_bytes_o(f32_alu_portal_write_bytes_o),
    .f32_alu_portal_outstanding_o(f32_alu_portal_outstanding_o),
    .f32_mover_portal_req_valid_o(f32_mover_portal_req_valid_o),
    .f32_mover_portal_req_ready_i(f32_mover_portal_req_ready_i),
    .f32_mover_portal_req_write_o(f32_mover_portal_req_write_o),
    .f32_mover_portal_req_mask_o(f32_mover_portal_req_mask_o),
    .f32_mover_portal_req_addr_o(f32_mover_portal_req_addr_o),
    .f32_mover_portal_req_wdata_o(f32_mover_portal_req_wdata_o),
    .f32_mover_portal_rsp_valid_i(f32_mover_portal_rsp_valid_i),
    .f32_mover_portal_rsp_ready_o(f32_mover_portal_rsp_ready_o),
    .f32_mover_portal_rsp_mask_i(f32_mover_portal_rsp_mask_i),
    .f32_mover_portal_rsp_rdata_i(f32_mover_portal_rsp_rdata_i),
    .f32_mover_portal_rsp_error_i(f32_mover_portal_rsp_error_i),
    .f32_mover_portal_request_groups_o(
        f32_mover_portal_request_groups_o),
    .f32_mover_portal_response_groups_o(
        f32_mover_portal_response_groups_o),
    .f32_mover_portal_read_groups_o(f32_mover_portal_read_groups_o),
    .f32_mover_portal_write_groups_o(f32_mover_portal_write_groups_o),
    .f32_mover_portal_read_words_o(f32_mover_portal_read_words_o),
    .f32_mover_portal_write_words_o(f32_mover_portal_write_words_o),
    .f32_mover_portal_read_bytes_o(f32_mover_portal_read_bytes_o),
    .f32_mover_portal_write_bytes_o(f32_mover_portal_write_bytes_o),
    .f32_mover_portal_outstanding_o(f32_mover_portal_outstanding_o),
    .sync_tag_ack_i(1'b1),.sync_tag_o(),.sync_tag_valid_o(),
    .error_clear_i(1'b0),.busy_o(),.error_o(),.error_code_o(),
    .command_count_o(npu_command_count_o),.completion_count_o(npu_completion_count_o),
    .error_count_o(npu_error_count_o),
    .npu_required_issued_o(npu_required_issued_o),
    .npu_required_completed_o(npu_required_completed_o),
    .tiu_cycles_o(),.dma_cycles_o(),.dma_bytes_o(),
    .macro_command_count_o(npu_macro_command_count_o),
    .macro_f32_start_count_o(npu_macro_f32_start_count_o),
    .macro_completion_count_o(npu_macro_completion_count_o)
  );
endmodule
