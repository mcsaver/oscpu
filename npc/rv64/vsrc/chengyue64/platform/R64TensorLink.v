`include "tensor_npu_defs.vh"
// Native CPU/NPU lifetime boundary. Arithmetic and DMA are performed by the
// actual TensorNpuCoprocessor below. One serial ROB-head owner is sufficient:
// the CPU retains successful irrevocability after our terminal until commit.
module R64TensorLink #(parameter integer LMEM_BYTES=4096)(
 input clk_i,input rst_i,
 input cmd_valid_i,output cmd_ready_o,input [8:0] cmd_tag_i,
 input [63:0] cmd_i,operand_i,input pair_i,input [7:0] class_i,
 output terminal_valid_o,input terminal_ready_i,output [8:0] terminal_tag_o,
 output error_o,output [7:0] error_code_o,
 output dma_invalidate_o,output busy_o,output reg protocol_error_o,
 output req_valid_o,input req_ready_i,output req_write_o,
 output [63:0] req_addr_o,req_wdata_o,output [7:0] req_wstrb_o,output [8:0] req_tag_o,
 input rsp_valid_i,output rsp_ready_o,input [63:0] rsp_rdata_i,input rsp_error_i,input [8:0] rsp_tag_i,
 output npu_error_o,output [7:0] npu_error_code_o,
 output [63:0] command_count_o,completion_count_o,macro_command_count_o,
 output descriptor_resident_o,output [5:0] descriptor_expected_o
);
 localparam [2:0] IDLE=0,CHECK=1,LEGACY=2,MACRO=3,WAIT_NPU=4,INVALIDATE=5,TERMINAL=6;
 localparam [1:0] EMPTY=0,BUILD=1,RESIDENT=2,POISON=3;
 localparam integer PID_W=9,OPCLASS_W=8,Q8_GEMV_ROW_LANES=4,
   F32_ALU_PORTAL_LANES=8,F32_MOVER_PORTAL_LANES=16;
 reg [2:0] state_q;reg [1:0] descriptor_state_q;
 reg [5:0] expected_q;
 // All thirty words are written in sequence before macro admission. Descriptor
 // contents need no reset mux; EMPTY/BUILD/RESIDENT are the sole authority.
 reg [63:0] descriptor_q[0:29];
 reg [8:0] tag_q;reg [63:0] command_q,operand_q;
 reg pair_q,macro_q,dirty_q,result_error_q;
 reg [7:0] class_q,result_code_q;
 wire cfg_w=!pair_q&&command_q[31:25]==7'd5&&command_q[14:12]==4&&
             command_q[11:7]==31&&command_q[6:0]==7'h5b;
 wire [4:0] index_w=command_q[24:20];
 wire macro_w=pair_q&&command_q==64'h0bf0305b0220305b;
 wire ordered_w=(descriptor_state_q==EMPTY&&index_w==0)||
                (descriptor_state_q==BUILD&&{1'b0,index_w}==expected_q);
 wire reserved_w=(index_w==18&&operand_q[63:32]!=0)||(index_w==25&&operand_q[63:8]!=0);
 assign cmd_ready_o=state_q==IDLE&&!rst_i;
 assign terminal_valid_o=state_q==TERMINAL&&!rst_i;
 assign terminal_tag_o=tag_q;assign error_o=result_error_q;assign error_code_o=result_code_q;
 assign dma_invalidate_o=state_q==INVALIDATE&&!rst_i;
 assign busy_o=state_q!=IDLE;
 assign descriptor_resident_o=descriptor_state_q==RESIDENT;
 assign descriptor_expected_o=expected_q;

 wire legacy_ready_w,macro_ready_w,npu_terminal_w,npu_ready_w,npu_required_w,npu_macro_w;
 wire [8:0] npu_tag_w;wire [7:0] npu_class_w,npu_code_w;wire npu_fault_w,clear_ready_w;
 wire clear_w=state_q==CHECK&&cfg_w&&index_w==30&&clear_ready_w;
 wire [31:0] nc_kernel_w,nc_flags_w,nc_vflags_w,nc_context_w,nc_nodes_w;
 wire [63:0] nc_sequence_w,nc_producer_w,nc_user_w,nc_hashlo_w,nc_hashhi_w;
 wire identity_w=macro_q ?
    (npu_macro_w&&nc_kernel_w==descriptor_q[0][31:0]&&nc_flags_w==descriptor_q[0][63:32]&&
     nc_vflags_w==descriptor_q[9][31:0]&&nc_context_w==descriptor_q[1][31:0]&&
     nc_sequence_w==descriptor_q[2]&&nc_producer_w==descriptor_q[3]&&
     nc_user_w==descriptor_q[4]&&nc_nodes_w==descriptor_q[5][31:0]&&
     nc_hashlo_w==descriptor_q[6]&&nc_hashhi_w==descriptor_q[7]):
    (!npu_macro_w&&npu_tag_w==tag_q&&npu_required_w==pair_q&&npu_class_w==class_q);
 wire memory_idle_w,write_admitted_w,memory_protocol_w;
 wire nreq_valid_w,nreq_ready_w,nreq_write_w,nrsp_valid_w,nrsp_ready_w,nrsp_error_w;
 wire [63:0] nreq_addr_w,nreq_data_w,nrsp_data_w;wire [7:0] nreq_strb_w;
 assign npu_ready_w=state_q==WAIT_NPU&&memory_idle_w&&!rst_i;
 R64TensorMemory u_memory(
  .clk_i(clk_i),.rst_i(rst_i),.owner_tag_i(tag_q),
  .nreq_valid_i(nreq_valid_w),.nreq_ready_o(nreq_ready_w),.nreq_write_i(nreq_write_w),
  .nreq_addr_i(nreq_addr_w),.nreq_wdata_i(nreq_data_w),.nreq_wstrb_i(nreq_strb_w),
  .nrsp_valid_o(nrsp_valid_w),.nrsp_ready_i(nrsp_ready_w),.nrsp_rdata_o(nrsp_data_w),.nrsp_error_o(nrsp_error_w),
  .req_valid_o(req_valid_o),.req_ready_i(req_ready_i),.req_write_o(req_write_o),
  .req_addr_o(req_addr_o),.req_wdata_o(req_wdata_o),.req_wstrb_o(req_wstrb_o),.req_tag_o(req_tag_o),
  .rsp_valid_i(rsp_valid_i),.rsp_ready_o(rsp_ready_o),.rsp_rdata_i(rsp_rdata_i),
  .rsp_error_i(rsp_error_i),.rsp_tag_i(rsp_tag_i),
  .write_admitted_o(write_admitted_w),.idle_o(memory_idle_w),.protocol_error_o(memory_protocol_w));

 always @(posedge clk_i)begin
  if(rst_i)begin
   state_q<=IDLE;descriptor_state_q<=EMPTY;expected_q<=0;
   dirty_q<=0;macro_q<=0;result_error_q<=0;result_code_q<=0;protocol_error_o<=0;
  end else begin
   if(memory_protocol_w)protocol_error_o<=1;
   if(write_admitted_w)dirty_q<=1;
   if(cmd_valid_i&&cmd_ready_o)begin
    state_q<=CHECK;tag_q<=cmd_tag_i;command_q<=cmd_i;operand_q<=operand_i;
    pair_q<=pair_i;class_q<=class_i;dirty_q<=0;macro_q<=0;result_error_q<=0;result_code_q<=0;
   end
   if(state_q==CHECK)begin
    if(cfg_w)begin
     state_q<=TERMINAL;
     if(npu_error_o&&index_w!=30)begin result_error_q<=1;result_code_q<=npu_error_code_o;end
     else if(index_w==30)begin
      if(npu_error_o&&!clear_ready_w)begin
       result_error_q<=1;result_code_q<=npu_error_code_o|`NPU_ERROR_FATAL_MASK;
      end else begin descriptor_state_q<=EMPTY;expected_q<=0;end
     end else if(index_w==31||!ordered_w||reserved_w)begin
      descriptor_state_q<=POISON;expected_q<=0;result_error_q<=1;result_code_q<=`NPU_ERR_MACRO_PROTOCOL;
     end else begin
      descriptor_q[index_w]<=operand_q;expected_q<={1'b0,index_w}+1'b1;
      descriptor_state_q<=index_w==29?RESIDENT:BUILD;
     end
    end else if(npu_error_o)begin
     result_error_q<=1;result_code_q<=npu_error_code_o;state_q<=TERMINAL;
    end else if(macro_w)begin
     if(descriptor_state_q==RESIDENT)begin state_q<=MACRO;macro_q<=1;end
     else begin
      descriptor_state_q<=POISON;expected_q<=0;result_error_q<=1;
      result_code_q<=`NPU_ERR_MACRO_PROTOCOL;state_q<=TERMINAL;
     end
    end else state_q<=LEGACY;
   end
   if((state_q==LEGACY&&legacy_ready_w)||(state_q==MACRO&&macro_ready_w))state_q<=WAIT_NPU;
   if(npu_terminal_w&&npu_ready_w)begin
    result_error_q<=npu_fault_w||!identity_w;
    result_code_q<=identity_w?npu_code_w:(`NPU_ERROR_FATAL_MASK|`NPU_ERR_MACRO_PROTOCOL);
    if(!identity_w)protocol_error_o<=1;
    if(macro_q)begin descriptor_state_q<=EMPTY;expected_q<=0;end
    state_q<=dirty_q?INVALIDATE:TERMINAL;
   end
   if(state_q==INVALIDATE)state_q<=TERMINAL;
   if(terminal_valid_o&&terminal_ready_i)state_q<=IDLE;
  end
 end
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i)begin
  if(nreq_valid_w&&state_q!=WAIT_NPU)$fatal(1,"NPU DMA without executing owner");
  if(npu_terminal_w&&npu_ready_w&&!identity_w)$fatal(1,"NPU terminal identity mismatch");
 end
`endif
 // Optional host portals and functional DPI are disabled in this real RTL
 // raw-GMEM configuration; all numerical engines remain the NPU implementation.
 TensorNpuCoprocessor #(.LMEM_BYTES(LMEM_BYTES),.PID_W(PID_W),.OPCLASS_W(OPCLASS_W)) u_npu(
  .clk(clk_i),
  .rst(rst_i),
  .cmd_valid_i(state_q==LEGACY&&!rst_i),
  .cmd_ready_o(legacy_ready_w),
  .cmd_is_64_i(pair_q),
  .cmd_bits_i(command_q),
  .cmd_rs_value_i(operand_q),
  .cmd_producer_id_i(tag_q),
  .cmd_npu_required_i(pair_q),
  .cmd_opclass_i(class_q),
  .macro_cmd_valid_i(state_q==MACRO&&!rst_i),
  .macro_cmd_ready_o(macro_ready_w),
  .macro_abi_valid_i(descriptor_q[25][0]),
  .macro_kernel_id_i(descriptor_q[0][31:0]),
  .macro_command_flags_i(descriptor_q[0][63:32]),
  .macro_context_id_i(descriptor_q[1][31:0]),
  .macro_capability_epoch_i(descriptor_q[1][63:32]),
  .macro_sequence_id_i(descriptor_q[2]),
  .macro_producer_id_i(descriptor_q[3]),
  .macro_user_tag_i(descriptor_q[4]),
  .macro_node_count_i(descriptor_q[5][31:0]),
  .macro_node_hash_lo_i(descriptor_q[6]),
  .macro_node_hash_hi_i(descriptor_q[7]),
  .macro_deadline_cycles_i(descriptor_q[8]),
  .macro_vector_op_i(descriptor_q[5][63:32]),
  .macro_vector_flags_i(descriptor_q[9][31:0]),
  .macro_src0_iova_i(descriptor_q[10]),
  .macro_src1_iova_i(descriptor_q[11]),
  .macro_src2_iova_i(descriptor_q[12]),
  .macro_dst_iova_i(descriptor_q[13]),
  .macro_scratch_iova_i(descriptor_q[14]),
  .macro_element_count_i(descriptor_q[15]),
  .macro_outer_count_i(descriptor_q[9][63:32]),
  .macro_dtype_i(descriptor_q[16][31:0]),
  .macro_src0_stride_i(descriptor_q[19]),
  .macro_src1_stride_i(descriptor_q[20]),
  .macro_src2_stride_i(descriptor_q[21]),
  .macro_dst_stride_i(descriptor_q[22]),
  .macro_scalar0_i(descriptor_q[16][63:32]),
  .macro_scalar1_i(descriptor_q[17][31:0]),
  .macro_scratch_bytes_i(descriptor_q[17][63:32]),
  .macro_rope_position_i(descriptor_q[18][31:0]),
  .macro_src0_window_base_i(descriptor_q[23]),
  .macro_src0_window_size_i(descriptor_q[24]),
  .macro_src0_window_perm_i(descriptor_q[25][3:2]),
  .macro_src1_window_base_i(descriptor_q[26]),
  .macro_src1_window_size_i(descriptor_q[27]),
  .macro_src1_window_perm_i(descriptor_q[25][5:4]),
  .macro_dst_window_base_i(descriptor_q[28]),
  .macro_dst_window_size_i(descriptor_q[29]),
  .macro_dst_window_perm_i(descriptor_q[25][7:6]),
  .macro_windows_generation_valid_i(descriptor_q[25][1]),
  .completion_valid_o(npu_terminal_w),
  .completion_ready_i(npu_ready_w),
  .completion_producer_id_o(npu_tag_w),
  .completion_npu_required_o(npu_required_w),
  .completion_opclass_o(npu_class_w),
  .completion_error_o(npu_fault_w),
  .completion_error_code_o(npu_code_w),
  .completion_is_macro_o(npu_macro_w),
  .completion_macro_status_o(),
  .completion_macro_error_class_o(),
  .completion_macro_kernel_id_o(nc_kernel_w),
  .completion_macro_command_flags_o(nc_flags_w),
  .completion_macro_vector_flags_o(nc_vflags_w),
  .completion_macro_context_id_o(nc_context_w),
  .completion_macro_sequence_id_o(nc_sequence_w),
  .completion_macro_producer_id_o(nc_producer_w),
  .completion_macro_user_tag_o(nc_user_w),
  .completion_macro_covered_node_count_o(nc_nodes_w),
  .completion_macro_node_hash_lo_o(nc_hashlo_w),
  .completion_macro_node_hash_hi_o(nc_hashhi_w),
  .completion_macro_npu_cycles_o(),
  .completion_macro_gmem_read_bytes_o(),
  .completion_macro_gmem_write_bytes_o(),
  .completion_macro_q8_mac_count_o(),
  .completion_macro_vector_element_count_o(),
  .completion_macro_state_update_count_o(),
  .desc_write_valid_i(1'b0),
  .desc_write_ready_o(),
  .desc_write_id_i({(5+1){1'b0}}),
  .desc_write_word_i({(2+1){1'b0}}),
  .desc_write_data_i({(63+1){1'b0}}),
  .desc_write_error_o(),
  .desc_write_error_code_o(),
  .host_lmem_rd_valid_i(1'b0),
  .host_lmem_rd_addr_i({(31+1){1'b0}}),
  .host_lmem_rd_bytes_i({(3+1){1'b0}}),
  .host_lmem_rd_data_o(),
  .host_lmem_rd_oob_o(),
  .host_lmem_wr_valid_i(1'b0),
  .host_lmem_wr_addr_i({(31+1){1'b0}}),
  .host_lmem_wr_data_i({(63+1){1'b0}}),
  .host_lmem_wr_strb_i({(7+1){1'b0}}),
  .host_lmem_wr_oob_o(),
  .host_lmem_ready_o(),
  .gmem_req_valid_o(nreq_valid_w),
  .gmem_req_ready_i(nreq_ready_w),
  .gmem_req_write_o(nreq_write_w),
  .gmem_req_addr_o(nreq_addr_w),
  .gmem_req_wdata_o(nreq_data_w),
  .gmem_req_wstrb_o(nreq_strb_w),
  .gmem_rsp_valid_i(nrsp_valid_w),
  .gmem_rsp_ready_o(nrsp_ready_w),
  .gmem_rsp_rdata_i(nrsp_data_w),
  .gmem_rsp_error_i(nrsp_error_w),
  .q8_portal_req_valid_o(),
  .q8_portal_req_ready_i(1'b0),
  .q8_portal_req_mask_o(),
  .q8_portal_req_addr_o(),
  .q8_portal_rsp_valid_i(1'b0),
  .q8_portal_rsp_ready_o(),
  .q8_portal_rsp_mask_i({(Q8_GEMV_ROW_LANES-1+1){1'b0}}),
  .q8_portal_rsp_blocks_i({((Q8_GEMV_ROW_LANES*272)-1+1){1'b0}}),
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
  .f32_alu_portal_rsp_mask_i({(F32_ALU_PORTAL_LANES-1+1){1'b0}}),
  .f32_alu_portal_rsp_src0_data_i({((F32_ALU_PORTAL_LANES*32)-1+1){1'b0}}),
  .f32_alu_portal_rsp_src1_data_i({((F32_ALU_PORTAL_LANES*32)-1+1){1'b0}}),
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
  .f32_mover_portal_rsp_mask_i({(F32_MOVER_PORTAL_LANES-1+1){1'b0}}),
  .f32_mover_portal_rsp_rdata_i({((F32_MOVER_PORTAL_LANES*32)-1+1){1'b0}}),
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
  .sync_tag_ack_i(1'b1),
  .sync_tag_o(),
  .sync_tag_valid_o(),
  .error_clear_i(clear_w),
  .error_clear_ready_o(clear_ready_w),
  .busy_o(),
  .error_o(npu_error_o),
  .error_code_o(npu_error_code_o),
  .command_count_o(command_count_o),
  .completion_count_o(completion_count_o),
  .error_count_o(),
  .npu_required_issued_o(),
  .npu_required_completed_o(),
  .tiu_cycles_o(),
  .dma_cycles_o(),
  .dma_bytes_o(),
  .macro_command_count_o(macro_command_count_o),
  .macro_f32_start_count_o(),
  .macro_completion_count_o()
 );
endmodule
