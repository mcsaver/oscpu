`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

module tb_coprocessor;

  localparam integer LMEM_BYTES       = 512;
  localparam integer LMEM_WORDS       = LMEM_BYTES / 8;
  localparam integer GMEM_MODEL_BYTES = 512;
  localparam [63:0] GMEM_MODEL_BYTES_64 = 64'd512;
  localparam integer MAX_CYCLES       = 4000;
  localparam integer COMMANDS_EXPECTED = 8;

  localparam [31:0] MM2_X_BASE   = 32'd0;
  localparam [31:0] MM2_W_BASE   = 32'd64;
  localparam [31:0] MM2_DST_BASE = 32'd128;
  localparam [31:0] DMA_LMEM_BASE = 32'd256;
  localparam [47:0] DMA_GMEM_BASE = 48'h0000_0000_0040;

  localparam [63:0] EXPECT_MM2_CYCLES = 64'd29;
  localparam [63:0] EXPECT_DMA_LD_CYCLES = 64'd8;
  localparam [63:0] EXPECT_DMA_ST_CYCLES = 64'd10;

  reg clk;
  reg rst;

  reg                         cmd_valid;
  wire                        cmd_ready;
  reg                         cmd_is_64;
  reg  [63:0]                 cmd_bits;
  reg  [63:0]                 cmd_rs_value;
  reg  [7:0]                  cmd_producer_id;
  reg                         cmd_npu_required;
  reg  [7:0]                  cmd_opclass;
  wire                        macro_cmd_ready;

  wire                        completion_valid;
  reg                         completion_ready;
  wire [7:0]                  completion_producer_id;
  wire                        completion_npu_required;
  wire [7:0]                  completion_opclass;
  wire                        completion_error;
  wire [`NPU_ERROR_W-1:0]     completion_error_code;
  wire                        completion_is_macro;
  wire [31:0]                 completion_macro_status;
  wire [31:0]                 completion_macro_error_class;
  wire [31:0]                 completion_macro_kernel_id;
  wire [31:0]                 completion_macro_command_flags;
  wire [31:0]                 completion_macro_vector_flags;
  wire [31:0]                 completion_macro_context_id;
  wire [63:0]                 completion_macro_sequence_id;
  wire [63:0]                 completion_macro_producer_id;
  wire [63:0]                 completion_macro_user_tag;
  wire [31:0]                 completion_macro_covered_node_count;
  wire [63:0]                 completion_macro_node_hash_lo;
  wire [63:0]                 completion_macro_node_hash_hi;
  wire [63:0]                 completion_macro_npu_cycles;
  wire [63:0]                 completion_macro_gmem_read_bytes;
  wire [63:0]                 completion_macro_gmem_write_bytes;
  wire [63:0]                 completion_macro_q8_mac_count;
  wire [63:0]                 completion_macro_vector_element_count;
  wire [63:0]                 completion_macro_state_update_count;

  reg                         desc_write_valid;
  wire                        desc_write_ready;
  reg  [5:0]                  desc_write_id;
  reg  [2:0]                  desc_write_word;
  reg  [63:0]                 desc_write_data;
  wire                        desc_write_error;
  wire [`NPU_ERROR_W-1:0]     desc_write_error_code;

  reg                         host_lmem_rd_valid;
  reg  [31:0]                 host_lmem_rd_addr;
  reg  [3:0]                  host_lmem_rd_bytes;
  wire [63:0]                 host_lmem_rd_data;
  wire                        host_lmem_rd_oob;
  reg                         host_lmem_wr_valid;
  reg  [31:0]                 host_lmem_wr_addr;
  reg  [63:0]                 host_lmem_wr_data;
  reg  [7:0]                  host_lmem_wr_strb;
  wire                        host_lmem_wr_oob;
  wire                        host_lmem_ready;

  wire                        gmem_req_valid;
  wire                        gmem_req_ready;
  wire                        gmem_req_write;
  wire [63:0]                 gmem_req_addr;
  wire [63:0]                 gmem_req_wdata;
  wire [7:0]                  gmem_req_wstrb;
  reg                         gmem_rsp_valid;
  wire                        gmem_rsp_ready;
  reg  [63:0]                 gmem_rsp_rdata;
  reg                         gmem_rsp_error;

  reg                         sync_tag_ack;
  wire [63:0]                 sync_tag;
  wire                        sync_tag_valid;
  reg                         error_clear;
  wire                        busy;
  wire                        error;
  wire [`NPU_ERROR_W-1:0]     error_code;

  wire [63:0]                 command_count;
  wire [63:0]                 completion_count;
  wire [63:0]                 error_count;
  wire [63:0]                 npu_required_issued;
  wire [63:0]                 npu_required_completed;
  wire [63:0]                 tiu_cycles;
  wire [63:0]                 dma_cycles;
  wire [63:0]                 dma_bytes;
  wire [63:0]                 macro_command_count;
  wire [63:0]                 macro_f32_start_count;
  wire [63:0]                 macro_completion_count;

  integer checks;
  integer global_cycles;
  integer observed_cmd_fires;
  integer observed_completion_fires;

  TensorNpuCoprocessor #(
    .LMEM_BYTES(LMEM_BYTES),
    .PID_W(8),
    .OPCLASS_W(8)
  ) dut (
    .clk(clk),
    .rst(rst),
    .cmd_valid_i(cmd_valid),
    .cmd_ready_o(cmd_ready),
    .cmd_is_64_i(cmd_is_64),
    .cmd_bits_i(cmd_bits),
    .cmd_rs_value_i(cmd_rs_value),
    .cmd_producer_id_i(cmd_producer_id),
    .cmd_npu_required_i(cmd_npu_required),
    .cmd_opclass_i(cmd_opclass),
    .macro_cmd_valid_i(1'b0),
    .macro_cmd_ready_o(macro_cmd_ready),
    .macro_abi_valid_i(1'b0),
    .macro_kernel_id_i(32'd0),
    .macro_command_flags_i(32'd0),
    .macro_context_id_i(32'd0),
    .macro_capability_epoch_i(32'd0),
    .macro_sequence_id_i(64'd0),
    .macro_producer_id_i(64'd0),
    .macro_user_tag_i(64'd0),
    .macro_node_count_i(32'd0),
    .macro_node_hash_lo_i(64'd0),
    .macro_node_hash_hi_i(64'd0),
    .macro_deadline_cycles_i(64'd0),
    .macro_vector_op_i(32'd0),
    .macro_vector_flags_i(32'd0),
    .macro_src0_iova_i(64'd0),
    .macro_src1_iova_i(64'd0),
    .macro_src2_iova_i(64'd0),
    .macro_dst_iova_i(64'd0),
    .macro_scratch_iova_i(64'd0),
    .macro_element_count_i(64'd0),
    .macro_outer_count_i(32'd0),
    .macro_dtype_i(32'd0),
    .macro_src0_stride_i(64'd0),
    .macro_src1_stride_i(64'd0),
    .macro_src2_stride_i(64'd0),
    .macro_dst_stride_i(64'd0),
    .macro_scalar0_i(32'd0),
    .macro_scalar1_i(32'd0),
    .macro_scratch_bytes_i(32'd0),
    .macro_rope_position_i(32'd0),
    .macro_src0_window_base_i(64'd0),
    .macro_src0_window_size_i(64'd0),
    .macro_src0_window_perm_i(2'd0),
    .macro_src1_window_base_i(64'd0),
    .macro_src1_window_size_i(64'd0),
    .macro_src1_window_perm_i(2'd0),
    .macro_dst_window_base_i(64'd0),
    .macro_dst_window_size_i(64'd0),
    .macro_dst_window_perm_i(2'd0),
    .macro_windows_generation_valid_i(1'b0),
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
    .completion_macro_gmem_read_bytes_o(
        completion_macro_gmem_read_bytes),
    .completion_macro_gmem_write_bytes_o(
        completion_macro_gmem_write_bytes),
    .completion_macro_q8_mac_count_o(completion_macro_q8_mac_count),
    .completion_macro_vector_element_count_o(
        completion_macro_vector_element_count),
    .completion_macro_state_update_count_o(
        completion_macro_state_update_count),
    .desc_write_valid_i(desc_write_valid),
    .desc_write_ready_o(desc_write_ready),
    .desc_write_id_i(desc_write_id),
    .desc_write_word_i(desc_write_word),
    .desc_write_data_i(desc_write_data),
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
    .sync_tag_ack_i(sync_tag_ack),
    .sync_tag_o(sync_tag),
    .sync_tag_valid_o(sync_tag_valid),
    .error_clear_i(error_clear),
    .busy_o(busy),
    .error_o(error),
    .error_code_o(error_code),
    .command_count_o(command_count),
    .completion_count_o(completion_count),
    .error_count_o(error_count),
    .npu_required_issued_o(npu_required_issued),
    .npu_required_completed_o(npu_required_completed),
    .tiu_cycles_o(tiu_cycles),
    .dma_cycles_o(dma_cycles),
    .dma_bytes_o(dma_bytes),
    .macro_command_count_o(macro_command_count),
    .macro_f32_start_count_o(macro_f32_start_count),
    .macro_completion_count_o(macro_completion_count)
  );

  task automatic fail;
    input string reason;
    begin
      $display("[NPU-COPROCESSOR][FAIL] %s", reason);
      $fatal(1);
    end
  endtask

  function automatic [31:0] enc_cfg;
    input [4:0] subop;
    input [4:0] rs_addr;
    input [4:0] imm5;
    begin
      enc_cfg = {7'b0000101, subop, rs_addr, `NPU_FUNCT3_CONFIG,
                 imm5, `NPU_CUSTOM2_OPCODE};
    end
  endfunction

  function automatic [63:0] enc_tiu;
    input [2:0] variant;
    input       rq;
    input       relu;
    input [4:0] dst;
    input [4:0] src0;
    input [4:0] src1;
    input [4:0] src2;
    reg [31:0] lo;
    reg [31:0] hi;
    begin
      hi = {7'b0000101, 5'b00101, dst, `NPU_FUNCT3_TENSOR,
            src0, `NPU_CUSTOM2_OPCODE};
      lo = {5'b00000, 1'b0, 1'b1, variant, rq, relu, src2,
            `NPU_FUNCT3_TENSOR, src1, `NPU_CUSTOM2_OPCODE};
      enc_tiu = {hi, lo};
    end
  endfunction

  function automatic [63:0] enc_dma;
    input [2:0] variant;
    input [5:0] dst;
    input [5:0] src0;
    reg [31:0] lo;
    reg [31:0] hi;
    begin
      hi = {7'b0000111, 4'b0000, dst, `NPU_FUNCT3_TENSOR,
            5'b00000, `NPU_CUSTOM2_OPCODE};
      lo = {5'b00000, 1'b0, 1'b1, variant, 6'd0, src0[5],
            `NPU_FUNCT3_TENSOR, src0[4:0], `NPU_CUSTOM2_OPCODE};
      enc_dma = {hi, lo};
    end
  endfunction

  function automatic [`NPU_DESC_W-1:0] make_tr_desc;
    input [31:0] base;
    input        signed_data;
    input [3:0]  teew;
    input [15:0] dim_w;
    input [15:0] dim_h;
    input [15:0] dim_c;
    input [15:0] dim_n;
    reg [`NPU_DESC_W-1:0] value;
    begin
      value = {`NPU_DESC_W{1'b0}};
      value[31:0]    = base;
      value[55:52]   = 4'd1;
      value[59]      = signed_data;
      value[63:60]   = teew;
      value[79:64]   = dim_w;
      value[95:80]   = dim_h;
      value[111:96]  = dim_c;
      value[127:112] = dim_n;
      value[159:128] = 32'd1;
      value[191:160] = {16'd0, dim_w};
      value[223:192] = {16'd0, dim_w} * {16'd0, dim_h};
      value[255:224] = ({16'd0, dim_w} * {16'd0, dim_h}) *
                       {16'd0, dim_c};
      make_tr_desc = value;
    end
  endfunction

  function automatic [`NPU_DESC_W-1:0] make_gr_desc;
    input [47:0] base;
    input        signed_data;
    input [3:0]  teew;
    input [31:0] dim_w;
    input [31:0] dim_h;
    input [15:0] dim_c;
    input [15:0] dim_n;
    reg [`NPU_DESC_W-1:0] value;
    begin
      value = {`NPU_DESC_W{1'b0}};
      value[47:0]    = base;
      value[55:52]   = 4'd1;
      value[59]      = signed_data;
      value[63:60]   = teew;
      value[95:64]   = dim_w;
      value[127:96]  = dim_h;
      value[143:128] = dim_c;
      value[159:144] = dim_n;
      value[191:160] = 32'd1;
      value[223:192] = dim_w;
      value[255:224] = dim_w * dim_h;
      value[287:256] = (dim_w * dim_h) * {16'd0, dim_c};
      make_gr_desc = value;
    end
  endfunction

  // ----------------------------------------------------------------------
  // Deterministic one-outstanding GMEM model.  Every request is stalled for
  // exactly one rising edge, then receives its response on the next edge.
  // This makes the expected DMA cycle totals an independent, fixed oracle.
  // ----------------------------------------------------------------------
  reg [7:0] gmem_bytes_q [0:GMEM_MODEL_BYTES-1];
  reg       gmem_pending_q;
  reg       pending_write_q;
  reg [8:0] pending_addr_q;
  reg [63:0] pending_wdata_q;
  reg [7:0] pending_wstrb_q;
  integer ready_wait_q;
  integer gmem_request_count;
  integer gmem_response_count;
  integer gmem_write_response_count;
  integer gmem_stall_cycles;
  integer gmem_outstanding;
  integer gmem_max_outstanding;
  integer gmem_lane;

  assign gmem_req_ready = !gmem_pending_q && !gmem_rsp_valid &&
                          (ready_wait_q == 0);

  function automatic [63:0] gmem_read64;
    input [8:0] byte_addr;
    integer read_lane;
    begin
      gmem_read64 = 64'd0;
      for (read_lane = 0; read_lane < 8; read_lane = read_lane + 1)
        gmem_read64[(8 * read_lane) +: 8] =
          gmem_bytes_q[byte_addr + read_lane[8:0]];
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      gmem_pending_q             <= 1'b0;
      pending_write_q            <= 1'b0;
      pending_addr_q             <= 9'd0;
      pending_wdata_q            <= 64'd0;
      pending_wstrb_q            <= 8'd0;
      ready_wait_q               <= 1;
      gmem_rsp_valid             <= 1'b0;
      gmem_rsp_rdata             <= 64'd0;
      gmem_rsp_error             <= 1'b0;
      gmem_request_count         <= 0;
      gmem_response_count        <= 0;
      gmem_write_response_count  <= 0;
      gmem_stall_cycles          <= 0;
      gmem_outstanding           <= 0;
      gmem_max_outstanding       <= 0;
    end else begin
      if (gmem_req_valid && !gmem_req_ready) begin
        gmem_stall_cycles <= gmem_stall_cycles + 1;
        if (!gmem_pending_q && !gmem_rsp_valid && (ready_wait_q > 0))
          ready_wait_q <= ready_wait_q - 1;
      end

      if (gmem_req_valid && gmem_req_ready) begin
        if (gmem_pending_q || gmem_rsp_valid || (gmem_outstanding != 0))
          fail("GMEM accepted more than one outstanding request");
        if ((gmem_req_addr + 64'd7) >= GMEM_MODEL_BYTES_64)
          fail($sformatf("GMEM request OOB addr=0x%016x", gmem_req_addr));
        if (gmem_req_write && (gmem_req_wstrb !== 8'hff))
          fail("DMA store did not use the full 64-bit GMEM strobe");
        if (!gmem_req_write && (gmem_req_wstrb !== 8'h00))
          fail("DMA load exposed a nonzero GMEM write strobe");

        gmem_pending_q    <= 1'b1;
        pending_write_q   <= gmem_req_write;
        pending_addr_q    <= gmem_req_addr[8:0];
        pending_wdata_q   <= gmem_req_wdata;
        pending_wstrb_q   <= gmem_req_wstrb;
        gmem_rsp_valid    <= 1'b1;
        gmem_rsp_rdata    <= gmem_req_write ?
                             64'd0 : gmem_read64(gmem_req_addr[8:0]);
        gmem_rsp_error    <= 1'b0;
        gmem_request_count <= gmem_request_count + 1;
        gmem_outstanding   <= gmem_outstanding + 1;
        if (gmem_max_outstanding < (gmem_outstanding + 1))
          gmem_max_outstanding <= gmem_outstanding + 1;
      end

      if (gmem_rsp_valid && gmem_rsp_ready) begin
        if (!gmem_pending_q || (gmem_outstanding != 1))
          fail("GMEM response drained without exactly one outstanding request");
        if (pending_write_q) begin
          for (gmem_lane = 0; gmem_lane < 8; gmem_lane = gmem_lane + 1) begin
            if (pending_wstrb_q[gmem_lane])
              gmem_bytes_q[pending_addr_q + gmem_lane[8:0]] <=
                pending_wdata_q[(8 * gmem_lane) +: 8];
          end
          gmem_write_response_count <= gmem_write_response_count + 1;
        end
        gmem_pending_q      <= 1'b0;
        gmem_rsp_valid      <= 1'b0;
        gmem_rsp_rdata      <= 64'd0;
        gmem_rsp_error      <= 1'b0;
        gmem_response_count <= gmem_response_count + 1;
        gmem_outstanding    <= gmem_outstanding - 1;
        ready_wait_q        <= 1;
      end
    end
  end

  // GMEM request payload must be held through the model's deterministic
  // ready-low cycle.
  reg        held_gmem_request_q;
  reg        held_gmem_write_q;
  reg [63:0] held_gmem_addr_q;
  reg [63:0] held_gmem_wdata_q;
  reg [7:0]  held_gmem_wstrb_q;

  always @(posedge clk) begin
    if (rst) begin
      held_gmem_request_q <= 1'b0;
      held_gmem_write_q   <= 1'b0;
      held_gmem_addr_q    <= 64'd0;
      held_gmem_wdata_q   <= 64'd0;
      held_gmem_wstrb_q   <= 8'd0;
    end else if (gmem_req_valid && !gmem_req_ready) begin
      if (!held_gmem_request_q) begin
        held_gmem_request_q <= 1'b1;
        held_gmem_write_q   <= gmem_req_write;
        held_gmem_addr_q    <= gmem_req_addr;
        held_gmem_wdata_q   <= gmem_req_wdata;
        held_gmem_wstrb_q   <= gmem_req_wstrb;
      end else if ((gmem_req_write !== held_gmem_write_q) ||
                   (gmem_req_addr  !== held_gmem_addr_q)  ||
                   (gmem_req_wdata !== held_gmem_wdata_q) ||
                   (gmem_req_wstrb !== held_gmem_wstrb_q)) begin
        fail("GMEM request payload changed under backpressure");
      end
    end else if (gmem_req_valid && gmem_req_ready) begin
      if (held_gmem_request_q &&
          ((gmem_req_write !== held_gmem_write_q) ||
           (gmem_req_addr  !== held_gmem_addr_q)  ||
           (gmem_req_wdata !== held_gmem_wdata_q) ||
           (gmem_req_wstrb !== held_gmem_wstrb_q))) begin
        fail("GMEM request payload changed on its accepting edge");
      end
      held_gmem_request_q <= 1'b0;
    end else if (held_gmem_request_q) begin
      fail("GMEM request valid was withdrawn before ready");
    end
  end

  // Completion is the CPU-facing terminal transaction.  The monitor captures
  // every field on the first ready-low cycle and proves full ProducerId and
  // required/opclass/error metadata remain bit-for-bit stable until fire.
  reg        held_completion_q;
  reg [7:0]  held_completion_pid_q;
  reg        held_completion_required_q;
  reg [7:0]  held_completion_opclass_q;
  reg        held_completion_error_q;
  reg [`NPU_ERROR_W-1:0] held_completion_error_code_q;

  always @(posedge clk) begin
    if (rst) begin
      held_completion_q            <= 1'b0;
      held_completion_pid_q        <= 8'd0;
      held_completion_required_q   <= 1'b0;
      held_completion_opclass_q    <= 8'd0;
      held_completion_error_q      <= 1'b0;
      held_completion_error_code_q <= `NPU_ERR_NONE;
      observed_cmd_fires           <= 0;
      observed_completion_fires    <= 0;
    end else begin
      if (cmd_valid && cmd_ready)
        observed_cmd_fires <= observed_cmd_fires + 1;

      if (completion_valid &&
          ((completion_is_macro !== 1'b0) ||
           (completion_macro_status !== '0) ||
           (completion_macro_error_class !== '0) ||
           (completion_macro_kernel_id !== '0) ||
           (completion_macro_command_flags !== '0) ||
           (completion_macro_vector_flags !== '0) ||
           (completion_macro_context_id !== '0) ||
           (completion_macro_sequence_id !== '0) ||
           (completion_macro_producer_id !== '0) ||
           (completion_macro_user_tag !== '0) ||
           (completion_macro_covered_node_count !== '0) ||
           (completion_macro_node_hash_lo !== '0) ||
           (completion_macro_node_hash_hi !== '0) ||
           (completion_macro_npu_cycles !== '0) ||
           (completion_macro_gmem_read_bytes !== '0) ||
           (completion_macro_gmem_write_bytes !== '0) ||
           (completion_macro_q8_mac_count !== '0) ||
           (completion_macro_vector_element_count !== '0) ||
           (completion_macro_state_update_count !== '0))) begin
        fail("legacy completion leaked macro completion metadata");
      end

      if (completion_valid && !completion_ready) begin
        if (!held_completion_q) begin
          held_completion_q            <= 1'b1;
          held_completion_pid_q        <= completion_producer_id;
          held_completion_required_q   <= completion_npu_required;
          held_completion_opclass_q    <= completion_opclass;
          held_completion_error_q      <= completion_error;
          held_completion_error_code_q <= completion_error_code;
        end else if ((completion_producer_id !== held_completion_pid_q) ||
                     (completion_npu_required !==
                      held_completion_required_q) ||
                     (completion_opclass !== held_completion_opclass_q) ||
                     (completion_error !== held_completion_error_q) ||
                     (completion_error_code !==
                      held_completion_error_code_q)) begin
          fail("completion metadata changed under CPU backpressure");
        end
      end else if (completion_valid && completion_ready) begin
        if (held_completion_q &&
            ((completion_producer_id !== held_completion_pid_q) ||
             (completion_npu_required !== held_completion_required_q) ||
             (completion_opclass !== held_completion_opclass_q) ||
             (completion_error !== held_completion_error_q) ||
             (completion_error_code !== held_completion_error_code_q))) begin
          fail("completion metadata changed on its accepting edge");
        end
        held_completion_q         <= 1'b0;
        observed_completion_fires <= observed_completion_fires + 1;
      end else if (held_completion_q) begin
        fail("completion valid was withdrawn before CPU acceptance");
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      global_cycles <= 0;
    end else begin
      global_cycles <= global_cycles + 1;
      if (global_cycles >= MAX_CYCLES)
        fail("bounded testbench timeout");
    end
  end

  always #5 clk <= ~clk;

  // ----------------------------------------------------------------------
  // Public-port helpers.  No task reaches into DUT hierarchy.
  // ----------------------------------------------------------------------
  task automatic host_write64;
    input [31:0] addr;
    input [63:0] data;
    input [7:0]  strb;
    begin
      @(negedge clk);
      host_lmem_wr_valid = 1'b1;
      host_lmem_wr_addr  = addr;
      host_lmem_wr_data  = data;
      host_lmem_wr_strb  = strb;
      #1;
      if (!host_lmem_ready)
        fail("host LMEM write attempted while the engine owned LMEM");
      if (host_lmem_wr_oob)
        fail($sformatf("host LMEM write OOB addr=0x%08x strb=0x%02x",
                       addr, strb));
      @(posedge clk);
      #1;
      @(negedge clk);
      host_lmem_wr_valid = 1'b0;
      host_lmem_wr_addr  = 32'd0;
      host_lmem_wr_data  = 64'd0;
      host_lmem_wr_strb  = 8'd0;
    end
  endtask

  task automatic host_read64;
    input  [31:0] addr;
    output [63:0] data;
    begin
      @(negedge clk);
      host_lmem_rd_valid = 1'b1;
      host_lmem_rd_addr  = addr;
      host_lmem_rd_bytes = 4'd8;
      #1;
      if (!host_lmem_ready)
        fail("host LMEM read attempted while the engine owned LMEM");
      if (host_lmem_rd_oob)
        fail($sformatf("host LMEM read OOB addr=0x%08x", addr));
      data = host_lmem_rd_data;
      host_lmem_rd_valid = 1'b0;
      host_lmem_rd_addr  = 32'd0;
      host_lmem_rd_bytes = 4'd0;
    end
  endtask

  task automatic expect_lmem64;
    input [31:0] addr;
    input [63:0] expected;
    reg [63:0] observed;
    begin
      host_read64(addr, observed);
      checks = checks + 1;
      if (observed !== expected)
        fail($sformatf("LMEM mismatch addr=0x%08x got=0x%016x expected=0x%016x",
                       addr, observed, expected));
    end
  endtask

  reg [63:0] lmem_snapshot_q [0:LMEM_WORDS-1];

  task automatic snapshot_lmem;
    integer word_index;
    begin
      for (word_index = 0; word_index < LMEM_WORDS;
           word_index = word_index + 1)
        host_read64(word_index * 8, lmem_snapshot_q[word_index]);
    end
  endtask

  task automatic expect_lmem_snapshot;
    integer word_index;
    reg [63:0] observed;
    begin
      for (word_index = 0; word_index < LMEM_WORDS;
           word_index = word_index + 1) begin
        host_read64(word_index * 8, observed);
        if (observed !== lmem_snapshot_q[word_index])
          fail($sformatf("negative command modified LMEM word=%0d got=0x%016x expected=0x%016x",
                         word_index, observed, lmem_snapshot_q[word_index]));
      end
      checks = checks + 1;
    end
  endtask

  task automatic write_desc_word;
    input [5:0]  id;
    input [2:0]  word_index;
    input [63:0] data;
    begin
      @(negedge clk);
      desc_write_valid = 1'b1;
      desc_write_id    = id;
      desc_write_word  = word_index;
      desc_write_data  = data;
      #1;
      if (!desc_write_ready)
        fail("descriptor write was not accepted while top was idle");
      if (desc_write_error ||
          (desc_write_error_code !== `NPU_ERR_NONE))
        fail($sformatf("descriptor write id=%0d word=%0d failed code=%0d",
                       id, word_index, desc_write_error_code));
      @(posedge clk);
      #1;
      @(negedge clk);
      desc_write_valid = 1'b0;
      desc_write_id    = 6'd0;
      desc_write_word  = 3'd0;
      desc_write_data  = 64'd0;
    end
  endtask

  task automatic write_tr_desc;
    input [5:0] id;
    input [`NPU_DESC_W-1:0] value;
    integer word_index;
    begin
      for (word_index = 0; word_index < 4; word_index = word_index + 1)
        write_desc_word(id, word_index[2:0],
                        value[(word_index * 64) +: 64]);
    end
  endtask

  task automatic write_gr_desc;
    input [5:0] id;
    input [`NPU_DESC_W-1:0] value;
    integer word_index;
    begin
      for (word_index = 0; word_index < 5; word_index = word_index + 1)
        write_desc_word(id, word_index[2:0],
                        value[(word_index * 64) +: 64]);
    end
  endtask

  task automatic expect_completion_fields;
    input [7:0] expected_pid;
    input       expected_required;
    input [7:0] expected_opclass;
    input       expected_error;
    input [`NPU_ERROR_W-1:0] expected_error_code;
    begin
      checks = checks + 1;
      if (!completion_valid ||
          (completion_producer_id !== expected_pid) ||
          (completion_npu_required !== expected_required) ||
          (completion_opclass !== expected_opclass) ||
          (completion_error !== expected_error) ||
          (completion_error_code !== expected_error_code)) begin
        fail($sformatf("completion mismatch valid=%0b pid=%02x/%02x required=%0b/%0b opclass=%02x/%02x error=%0b/%0b code=%0d/%0d",
                       completion_valid,
                       completion_producer_id, expected_pid,
                       completion_npu_required, expected_required,
                       completion_opclass, expected_opclass,
                       completion_error, expected_error,
                       completion_error_code, expected_error_code));
      end
    end
  endtask

  task automatic run_command;
    input       is_64;
    input [63:0] bits;
    input [63:0] rs_value;
    input [7:0] producer_id;
    input       required;
    input [7:0] opclass;
    input integer completion_stall_cycles;
    input       expected_error;
    input [`NPU_ERROR_W-1:0] expected_error_code;
    integer guard;
    integer hold_cycle;
    begin
      if (!cmd_ready || error || completion_valid)
        fail("command launched while coprocessor was not cleanly idle");

      completion_ready = 1'b0;
      @(negedge clk);
      cmd_valid        = 1'b1;
      cmd_is_64        = is_64;
      cmd_bits         = bits;
      cmd_rs_value     = rs_value;
      cmd_producer_id  = producer_id;
      cmd_npu_required = required;
      cmd_opclass      = opclass;
      #1;
      if (!cmd_ready)
        fail("command did not fire from idle");
      if (macro_cmd_ready)
        fail("macro command won ready while legacy command was valid");
      @(posedge clk);
      #1;
      if (cmd_ready)
        fail("command ready remained high after a command fire");
      @(negedge clk);
      cmd_valid        = 1'b0;
      cmd_is_64        = 1'b0;
      cmd_bits         = 64'd0;
      cmd_rs_value     = 64'd0;
      cmd_producer_id  = 8'd0;
      cmd_npu_required = 1'b0;
      cmd_opclass      = 8'd0;

      guard = 0;
      while (!completion_valid && (guard < MAX_CYCLES)) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!completion_valid)
        fail("command completion watchdog expired");

      expect_completion_fields(producer_id, required, opclass,
                               expected_error, expected_error_code);
      if (cmd_ready || desc_write_ready)
        fail("command/descriptor ready asserted while completion was pending");

      for (hold_cycle = 0;
           hold_cycle < completion_stall_cycles;
           hold_cycle = hold_cycle + 1) begin
        @(posedge clk);
        #1;
        expect_completion_fields(producer_id, required, opclass,
                                 expected_error, expected_error_code);
        if (cmd_ready || desc_write_ready)
          fail("ready escaped while completion was backpressured");
      end

      @(negedge clk);
      completion_ready = 1'b1;
      @(posedge clk);
      #1;
      if (completion_valid)
        fail("completion valid remained high after CPU acceptance");
      @(negedge clk);
      completion_ready = 1'b0;
    end
  endtask

  task automatic expect_counters;
    input [63:0] expected_commands;
    input [63:0] expected_completions;
    input [63:0] expected_errors;
    input [63:0] expected_required_issued;
    input [63:0] expected_required_completed;
    input [63:0] expected_tiu_cycles;
    input [63:0] expected_dma_cycles;
    input [63:0] expected_dma_bytes;
    begin
      checks = checks + 1;
      if ((command_count !== expected_commands) ||
          (completion_count !== expected_completions) ||
          (error_count !== expected_errors) ||
          (npu_required_issued !== expected_required_issued) ||
          (npu_required_completed !== expected_required_completed) ||
          (tiu_cycles !== expected_tiu_cycles) ||
          (dma_cycles !== expected_dma_cycles) ||
          (dma_bytes !== expected_dma_bytes)) begin
        fail($sformatf("counter mismatch cmd=%0d/%0d completion=%0d/%0d error=%0d/%0d required=%0d:%0d/%0d:%0d tiu=%0d/%0d dma_cycles=%0d/%0d dma_bytes=%0d/%0d",
                       command_count, expected_commands,
                       completion_count, expected_completions,
                       error_count, expected_errors,
                       npu_required_issued, npu_required_completed,
                       expected_required_issued,
                       expected_required_completed,
                       tiu_cycles, expected_tiu_cycles,
                       dma_cycles, expected_dma_cycles,
                       dma_bytes, expected_dma_bytes));
      end
    end
  endtask

  task automatic expect_sticky_error;
    input [`NPU_ERROR_W-1:0] expected_code;
    integer hold_cycle;
    begin
      checks = checks + 1;
      if (!error || (error_code !== expected_code) || busy || cmd_ready ||
          macro_cmd_ready || desc_write_ready)
        fail($sformatf("sticky error state mismatch error=%0b code=%0d/%0d busy=%0b cmd_ready=%0b desc_ready=%0b",
                       error, error_code, expected_code, busy,
                       cmd_ready, desc_write_ready));
      for (hold_cycle = 0; hold_cycle < 3; hold_cycle = hold_cycle + 1) begin
        @(posedge clk);
        #1;
        if (!error || (error_code !== expected_code) || cmd_ready ||
            macro_cmd_ready || desc_write_ready)
          fail("sticky error or fail-closed ready state changed before clear");
      end
    end
  endtask

  task automatic clear_sticky_error;
    begin
      @(negedge clk);
      error_clear = 1'b1;
      @(posedge clk);
      #1;
      if (error || (error_code !== `NPU_ERR_NONE) || !cmd_ready ||
          !desc_write_ready || busy)
        fail("explicit error clear did not restore the idle interfaces");
      @(negedge clk);
      error_clear = 1'b0;
    end
  endtask

  initial begin
    integer init_index;
    integer requests_before;
    integer responses_before;
    integer writes_before;
    reg [`NPU_DESC_W-1:0] desc_value;

    clk                  = 1'b0;
    rst                  = 1'b1;
    checks               = 0;
    global_cycles        = 0;
    cmd_valid            = 1'b0;
    cmd_is_64            = 1'b0;
    cmd_bits             = 64'd0;
    cmd_rs_value         = 64'd0;
    cmd_producer_id      = 8'd0;
    cmd_npu_required     = 1'b0;
    cmd_opclass          = 8'd0;
    completion_ready     = 1'b0;
    desc_write_valid     = 1'b0;
    desc_write_id        = 6'd0;
    desc_write_word      = 3'd0;
    desc_write_data      = 64'd0;
    host_lmem_rd_valid   = 1'b0;
    host_lmem_rd_addr    = 32'd0;
    host_lmem_rd_bytes   = 4'd0;
    host_lmem_wr_valid   = 1'b0;
    host_lmem_wr_addr    = 32'd0;
    host_lmem_wr_data    = 64'd0;
    host_lmem_wr_strb    = 8'd0;
    sync_tag_ack         = 1'b0;
    error_clear          = 1'b0;

    for (init_index = 0; init_index < GMEM_MODEL_BYTES;
         init_index = init_index + 1)
      gmem_bytes_q[init_index] = 8'd0;
    for (init_index = 0; init_index < 16; init_index = init_index + 1)
      gmem_bytes_q[9'd64 + init_index[8:0]] =
        8'h80 + init_index[7:0];

    repeat (4) @(posedge clk);
    #1;
    rst = 1'b0;
    repeat (2) @(posedge clk);
    #1;

    if (!cmd_ready || !macro_cmd_ready || !desc_write_ready || busy || error ||
        completion_valid || sync_tag_valid)
      fail("reset did not produce a clean idle coprocessor");
    expect_counters(64'd0, 64'd0, 64'd0, 64'd0, 64'd0,
                    64'd0, 64'd0, 64'd0);

    // Initialize every LMEM byte so the later no-side-effect comparison has
    // no X-valued holes.
    for (init_index = 0; init_index < LMEM_WORDS;
         init_index = init_index + 1)
      host_write64(init_index * 8, 64'd0, 8'hff);

    // MM2 descriptors: signed S8 2x2 times signed S8 2x2 -> signed S32 2x2.
    desc_value = make_tr_desc(MM2_DST_BASE, 1'b1, 4'd2,
                              16'd2, 16'd1, 16'd2, 16'd1);
    write_tr_desc(6'd8, desc_value);
    desc_value = make_tr_desc(MM2_X_BASE, 1'b1, 4'd0,
                              16'd2, 16'd1, 16'd2, 16'd1);
    write_tr_desc(6'd9, desc_value);
    desc_value = make_tr_desc(MM2_W_BASE, 1'b1, 4'd0,
                              16'd2, 16'd1, 16'd2, 16'd1);
    write_tr_desc(6'd10, desc_value);

    // DMA descriptors: a 16-byte continuous E8 Tensor in TR11 and GR32.
    desc_value = make_tr_desc(DMA_LMEM_BASE, 1'b0, 4'd0,
                              16'd16, 16'd1, 16'd1, 16'd1);
    write_tr_desc(6'd11, desc_value);
    desc_value = make_gr_desc(DMA_GMEM_BASE, 1'b0, 4'd0,
                              32'd16, 32'd1, 16'd1, 16'd1);
    write_gr_desc(6'd32, desc_value);

    host_write64(MM2_X_BASE, 64'h0000_0000_0403_0201, 8'hff);
    host_write64(MM2_W_BASE, 64'h0000_0000_0807_0605, 8'hff);
    host_write64(MM2_DST_BASE,     64'hdead_beef_dead_beef, 8'hff);
    host_write64(MM2_DST_BASE + 8, 64'hdead_beef_dead_beef, 8'hff);

    // A scalar config command proves the 32-bit path and supplies the first
    // full-PID completion hold (generation A, ROB index 5).
    run_command(1'b0,
                {32'd0, enc_cfg(5'b00001, 5'd3, 5'd0)},
                64'h0123_4567_89ab_cdef,
                8'ha5, 1'b0, 8'h10, 3,
                1'b0, `NPU_ERR_NONE);
    expect_counters(64'd1, 64'd1, 64'd0, 64'd0, 64'd0,
                    64'd0, 64'd0, 64'd0);

    // Reuse ROB index 5 with a different generation.  The completion must
    // retain all eight ProducerId bits and MM2 must write four exact words.
    run_command(1'b1,
                enc_tiu(3'b000, 1'b0, 1'b0,
                        5'd8, 5'd9, 5'd10, 5'd0),
                64'd0,
                8'h35, 1'b1, 8'h21, 2,
                1'b0, `NPU_ERR_NONE);
    expect_lmem64(MM2_DST_BASE,     64'h0000_0016_0000_0013);
    expect_lmem64(MM2_DST_BASE + 8, 64'h0000_0032_0000_002b);
    expect_counters(64'd2, 64'd2, 64'd0, 64'd1, 64'd1,
                    EXPECT_MM2_CYCLES, 64'd0, 64'd0);

    // DMA LD: deterministic GMEM[0x40..0x4f] -> LMEM[0x100..0x10f].
    requests_before  = gmem_request_count;
    responses_before = gmem_response_count;
    run_command(1'b1,
                enc_dma(3'b000, 6'd11, 6'd32),
                64'd0,
                8'hc6, 1'b1, 8'h31, 1,
                1'b0, `NPU_ERR_NONE);
    if (((gmem_request_count - requests_before) != 2) ||
        ((gmem_response_count - responses_before) != 2))
      fail("DMA LD did not issue and drain exactly two GMEM beats");
    expect_lmem64(DMA_LMEM_BASE,
                  64'h8786_8584_8382_8180);
    expect_lmem64(DMA_LMEM_BASE + 8,
                  64'h8f8e_8d8c_8b8a_8988);
    expect_counters(64'd3, 64'd3, 64'd0, 64'd2, 64'd2,
                    EXPECT_MM2_CYCLES,
                    EXPECT_DMA_LD_CYCLES, 64'd16);

    // DMA ST uses the same public LMEM window after host replacement, then
    // checks every returned 64-bit word in the deterministic GMEM model.
    host_write64(DMA_LMEM_BASE,
                 64'h1122_3344_5566_7788, 8'hff);
    host_write64(DMA_LMEM_BASE + 8,
                 64'h99aa_bbcc_ddee_ff00, 8'hff);
    requests_before  = gmem_request_count;
    responses_before = gmem_response_count;
    writes_before    = gmem_write_response_count;
    run_command(1'b1,
                enc_dma(3'b010, 6'd32, 6'd11),
                64'd0,
                8'hd7, 1'b1, 8'h32, 1,
                1'b0, `NPU_ERR_NONE);
    if (((gmem_request_count - requests_before) != 2) ||
        ((gmem_response_count - responses_before) != 2) ||
        ((gmem_write_response_count - writes_before) != 2))
      fail("DMA ST did not issue, write, and drain exactly two GMEM beats");
    if ((gmem_read64(9'd64) !== 64'h1122_3344_5566_7788) ||
        (gmem_read64(9'd72) !== 64'h99aa_bbcc_ddee_ff00))
      fail("DMA ST GMEM data mismatch");
    expect_counters(64'd4, 64'd4, 64'd0, 64'd3, 64'd3,
                    EXPECT_MM2_CYCLES,
                    EXPECT_DMA_LD_CYCLES + EXPECT_DMA_ST_CYCLES,
                    64'd32);

    if ((gmem_request_count != 4) || (gmem_response_count != 4) ||
        (gmem_write_response_count != 2) ||
        (gmem_stall_cycles != 4) || (gmem_outstanding != 0) ||
        (gmem_max_outstanding != 1) || held_gmem_request_q)
      fail($sformatf("final GMEM protocol counts req=%0d rsp=%0d writes=%0d stalls=%0d out=%0d max=%0d held=%0b",
                     gmem_request_count, gmem_response_count,
                     gmem_write_response_count, gmem_stall_cycles,
                     gmem_outstanding, gmem_max_outstanding,
                     held_gmem_request_q));

    // sync.gdma may complete only after the preceding DMA terminal.  The tag
    // remains visible across completion backpressure and extra idle cycles.
    run_command(1'b0,
                {32'd0, enc_cfg(5'b01110, 5'd4, 5'd2)},
                64'h7319_cafe_0820_0002,
                8'he8, 1'b0, 8'h40, 2,
                1'b0, `NPU_ERR_NONE);
    if (!sync_tag_valid ||
        (sync_tag !== 64'h7319_cafe_0820_0002))
      fail("sync tag was absent or wrong after sync completion");
    repeat (3) begin
      @(posedge clk);
      #1;
      if (!sync_tag_valid ||
          (sync_tag !== 64'h7319_cafe_0820_0002))
        fail("sync tag changed before explicit ack");
    end
    @(negedge clk);
    sync_tag_ack = 1'b1;
    @(posedge clk);
    #1;
    if (sync_tag_valid || (sync_tag !== 64'd0))
      fail("sync tag ack did not clear valid and payload");
    @(negedge clk);
    sync_tag_ack = 1'b0;
    expect_counters(64'd5, 64'd5, 64'd0, 64'd3, 64'd3,
                    EXPECT_MM2_CYCLES,
                    EXPECT_DMA_LD_CYCLES + EXPECT_DMA_ST_CYCLES,
                    64'd32);

    // Freeze all LMEM words before the two negative commands.  A legal but
    // unsupported TIU variant must return UNSUPPORTED, carry required=1, and
    // enter sticky hold without any LMEM or GMEM request/write side effect.
    snapshot_lmem();
    requests_before = gmem_request_count;
    writes_before   = gmem_write_response_count;
    run_command(1'b1,
                enc_tiu(3'b111, 1'b0, 1'b0,
                        5'd8, 5'd9, 5'd10, 5'd0),
                64'd0,
                8'hf9, 1'b1, 8'h7e, 4,
                1'b1, `NPU_ERR_UNSUPPORTED);
    expect_sticky_error(`NPU_ERR_UNSUPPORTED);
    if ((gmem_request_count != requests_before) ||
        (gmem_write_response_count != writes_before))
      fail("unsupported command leaked a GMEM transaction");
    expect_lmem_snapshot();
    expect_counters(64'd6, 64'd5, 64'd1, 64'd4, 64'd3,
                    EXPECT_MM2_CYCLES,
                    EXPECT_DMA_LD_CYCLES + EXPECT_DMA_ST_CYCLES,
                    64'd32);
    clear_sticky_error();

    // A non-custom 32-bit word is an illegal Tensor command.  It must retain
    // its own PID/opclass/error completion, keep both ready outputs low in
    // sticky hold, and leave all Tensor memories unchanged.
    requests_before = gmem_request_count;
    writes_before   = gmem_write_response_count;
    run_command(1'b0,
                64'h0000_0000_0000_0013,
                64'hffff_ffff_ffff_ffff,
                8'h1a, 1'b0, 8'h7f, 3,
                1'b1, `NPU_ERR_ILLEGAL_ENCODING);
    expect_sticky_error(`NPU_ERR_ILLEGAL_ENCODING);
    if ((gmem_request_count != requests_before) ||
        (gmem_write_response_count != writes_before))
      fail("illegal command leaked a GMEM transaction");
    expect_lmem_snapshot();
    expect_counters(64'd7, 64'd5, 64'd2, 64'd4, 64'd3,
                    EXPECT_MM2_CYCLES,
                    EXPECT_DMA_LD_CYCLES + EXPECT_DMA_ST_CYCLES,
                    64'd32);
    clear_sticky_error();

    // A final config command proves that explicit clear restores command and
    // completion progress without resetting any architectural counters.
    run_command(1'b0,
                {32'd0, enc_cfg(5'b00101, 5'd2, 5'd0)},
                64'h0000_0000_0000_000d,
                8'h2b, 1'b0, 8'h11, 2,
                1'b0, `NPU_ERR_NONE);
    expect_lmem_snapshot();
    expect_counters(64'd8, 64'd6, 64'd2, 64'd4, 64'd3,
                    EXPECT_MM2_CYCLES,
                    EXPECT_DMA_LD_CYCLES + EXPECT_DMA_ST_CYCLES,
                    64'd32);

    if ((observed_cmd_fires != COMMANDS_EXPECTED) ||
        (observed_completion_fires != COMMANDS_EXPECTED) ||
        held_completion_q || completion_valid || busy || error ||
        !cmd_ready || !macro_cmd_ready || !desc_write_ready ||
        (macro_command_count != 0) || (macro_f32_start_count != 0) ||
        (macro_completion_count != 0))
      fail($sformatf("final transaction state cmd_fires=%0d completion_fires=%0d held=%0b completion_valid=%0b busy=%0b error=%0b cmd_ready=%0b desc_ready=%0b",
                     observed_cmd_fires, observed_completion_fires,
                     held_completion_q, completion_valid, busy, error,
                     cmd_ready, desc_write_ready));

    $display("[NPU-COPROCESSOR][PASS] checks=%0d commands=%0d completions=%0d errors=%0d required_issued=%0d required_completed=%0d tiu_cycles=%0d dma_cycles=%0d dma_bytes=%0d",
             checks, command_count, completion_count, error_count,
             npu_required_issued, npu_required_completed,
             tiu_cycles, dma_cycles, dma_bytes);
    $finish;
  end

endmodule
