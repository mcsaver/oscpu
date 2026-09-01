`include "define.v"

module tb_ooo_alu_decode_backend;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam FREE_COUNT_W = 7;
  localparam ISSUE_COUNT_W = 4;

  reg clk;
  reg rst;
  reg flush;

  reg dispatch0_valid;
  wire dispatch0_ready;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  wire dispatch0_unsupported;
  reg dispatch0_is_tensor;
  reg [63:0] tensor_bits;
  reg tensor_is_64;
  reg tensor_cmd_ready;
  wire tensor_cmd_valid;
  wire [63:0] tensor_cmd_bits;
  wire [`XLEN-1:0] tensor_cmd_rs_value;
  wire [`OOO_PRODUCER_ID_W-1:0] tensor_cmd_pid;
  wire tensor_cmd_is_64;
  wire tensor_serialize;
  reg tensor_terminal_valid;
  reg [`OOO_PRODUCER_ID_W-1:0] tensor_terminal_pid;
  wire tensor_terminal_ready;

  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  wire dispatch1_unsupported;

  reg commit_ready;
  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire [`XLEN-1:0] commit0_next_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire commit0_rd_en;
  wire [`REG_ADDR_W-1:0] commit0_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit0_new_pdest;
  wire [`XLEN-1:0] commit0_data;
  wire commit0_exception;
  wire [`TRAP_CAUSE_W-1:0] commit0_cause;
  wire [`XLEN-1:0] commit0_tval;

  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire [`XLEN-1:0] commit1_next_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit1_new_pdest;
  wire [`XLEN-1:0] commit1_data;
  wire commit1_exception;
  wire [`TRAP_CAUSE_W-1:0] commit1_cause;
  wire [`XLEN-1:0] commit1_tval;

  wire [FREE_COUNT_W-1:0] free_count;
  wire [ROB_COUNT_W-1:0] rob_count;
  wire [ISSUE_COUNT_W-1:0] issue_count;
  wire execute0_valid;
  wire execute1_valid;
  wire branch_resolve_valid;
  wire [`XLEN-1:0] branch_resolve_pc;
  wire [`XLEN-1:0] branch_resolve_next_pc;
  wire branch_resolve_misaligned;
  wire mem_req_valid;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [3:0] mem_req_wstrb;
  wire mem_rsp_ready;
  wire unused_mem_w =
      mem_req_valid | mem_req_write | (|mem_req_addr) |
      (|mem_req_wdata) | (|mem_req_wstrb) | mem_rsp_ready;

`ifdef RV64_REAL_NPU_LINK
  reg link_stall;
  reg completion_stall;
  reg inject_wrong_pid;
  reg pair_head_valid;
  reg pair_head_slot1_valid;
  reg [`XLEN-1:0] pair_head_pc0;
  reg [`INST_W-1:0] pair_head_inst0;
  reg [`XLEN-1:0] pair_head_pc1;
  reg [`INST_W-1:0] pair_head_inst1;
  wire pair_head_pop;
  wire pair_tensor_valid;
  wire pair_tensor_ready = dispatch0_ready;
  wire [`XLEN-1:0] pair_tensor_pc;
  wire [`XLEN-1:0] pair_tensor_next_pc;
  wire [63:0] pair_tensor_bits;
  wire pair_tensor_is_64;
  wire pair_tensor_required;
  wire [7:0] pair_tensor_opclass;
  wire npu_cmd_ready;
  wire npu_completion_valid;
  wire [7:0] npu_completion_pid;
  wire npu_completion_error;
  wire [7:0] npu_completion_error_code;
  wire [63:0] npu_command_count;
  wire [63:0] npu_completion_count;
  wire [63:0] npu_error_count;

  OooTensorPairOwner u_real_pair_owner (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .head_valid_i(pair_head_valid),
    .head_slot1_valid_i(pair_head_slot1_valid),
    .head_pc0_i(pair_head_pc0),
    .head_inst0_i(pair_head_inst0),
    .head_resp0_i(2'b00),
    .head_pc1_i(pair_head_pc1),
    .head_inst1_i(pair_head_inst1),
    .head_resp1_i(2'b00),
    .head_fault_tval_i({`XLEN{1'b0}}),
    .normal_lane0_fire_i(1'b0),
    .head0_claim_o(),
    .head1_claim_o(),
    .head_pop_o(pair_head_pop),
    .residual_valid_o(),
    .residual_ready_i(1'b0),
    .residual_pc_o(),
    .residual_inst_o(),
    .residual_resp_o(),
    .tensor_valid_o(pair_tensor_valid),
    .tensor_ready_i(pair_tensor_ready),
    .tensor_pc_o(pair_tensor_pc),
    .tensor_next_pc_o(pair_tensor_next_pc),
    .tensor_bits_o(pair_tensor_bits),
    .tensor_is_64_o(pair_tensor_is_64),
    .tensor_required_o(pair_tensor_required),
    .tensor_opclass_o(pair_tensor_opclass),
    .tensor_cross_packet_o(),
    .error_valid_o(),
    .error_ready_i(1'b0),
    .error_pc_o(),
    .error_cause_o(),
    .error_tval_o(),
    .error_code_o(),
    .pair_pending_o(),
    .serialize_o()
  );
  wire dut_dispatch0_valid_w = pair_tensor_valid;
  wire [`XLEN-1:0] dut_dispatch0_pc_w = pair_tensor_pc;
  wire [`XLEN-1:0] dut_dispatch0_next_pc_w = pair_tensor_next_pc;
  wire [`INST_W-1:0] dut_dispatch0_inst_w = pair_tensor_bits[31:0];
  wire dut_dispatch0_is_tensor_w = 1'b1;
  wire [63:0] dut_tensor_bits_w = pair_tensor_bits;
  wire dut_tensor_is_64_w = pair_tensor_is_64;
  wire dut_tensor_required_w = pair_tensor_required;
  wire [7:0] dut_tensor_opclass_w = pair_tensor_opclass;
  wire dut_tensor_cmd_ready_w = npu_cmd_ready && !link_stall;
  wire dut_tensor_terminal_valid_w = npu_completion_valid &&
      !completion_stall;
  wire [7:0] dut_tensor_terminal_pid_w = inject_wrong_pid ?
      (npu_completion_pid ^ 8'h10) : npu_completion_pid;
  wire dut_tensor_terminal_error_w = npu_completion_error;
  wire [7:0] dut_tensor_terminal_error_code_w =
      npu_completion_error_code;
`else
  wire dut_dispatch0_valid_w = dispatch0_valid;
  wire [`XLEN-1:0] dut_dispatch0_pc_w = dispatch0_pc;
  wire [`XLEN-1:0] dut_dispatch0_next_pc_w = dispatch0_pc + 32'd4;
  wire [`INST_W-1:0] dut_dispatch0_inst_w = dispatch0_inst;
  wire dut_dispatch0_is_tensor_w = dispatch0_is_tensor;
  wire [63:0] dut_tensor_bits_w = tensor_bits;
  wire dut_tensor_is_64_w = tensor_is_64;
  wire dut_tensor_required_w = 1'b1;
  wire [7:0] dut_tensor_opclass_w = 8'h22;
  wire dut_tensor_cmd_ready_w = tensor_cmd_ready;
  wire dut_tensor_terminal_valid_w = tensor_terminal_valid;
  wire [7:0] dut_tensor_terminal_pid_w = tensor_terminal_pid;
  wire dut_tensor_terminal_error_w = 1'b0;
  wire [7:0] dut_tensor_terminal_error_code_w = 8'b0;
`endif

  OooAluDecodeBackend dut (
    .clk(clk),
    .rst(rst),
    .head0_context_permit_i(1'b1),
    .fencei_retire_permit_i(1'b1),
    .head0_retire_candidate_valid_o(),
    .head0_identity_valid_o(),
    .head0_identity_o(),
    .flush_i(flush),
    .checkpoint_capture_i(1'b0),
    .checkpoint_restore_i(1'b0),
    .checkpoint_quiesce_i(1'b0),
    .recover_gprs_i({(`XLEN * `REG_NUM){1'b0}}),
    .mem_issue_block_i(1'b0),
    .pending_branch_fast_valid_i(1'b0),
    .pending_branch_fast_pc_i({`XLEN{1'b0}}),
    .pending_system_producer_valid_i(1'b0),
    .pending_system_producer_id_i({(`OOO_ROB_INDEX_W + `OOO_PRODUCER_GEN_W){1'b0}}),
    .dispatch0_valid_i(dut_dispatch0_valid_w),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_producer_id_o(),
    .dispatch0_pc_i(dut_dispatch0_pc_w),
    .dispatch0_next_pc_i(dut_dispatch0_next_pc_w),
    .dispatch0_pred_npc_i('0),
    .dispatch0_bht_idx_i({`BPU_BHT_INDEX_W{1'b0}}),
    .dispatch0_pred_taken_i(1'b0),
    .dispatch0_inst_i(dut_dispatch0_inst_w),
    .dispatch0_csr_rdata_i({`XLEN{1'b0}}),
    .dispatch0_is_tensor_i(dut_dispatch0_is_tensor_w),
    .dispatch0_tensor_bits_i(dut_tensor_bits_w),
    .dispatch0_tensor_is_64_i(dut_tensor_is_64_w),
    .dispatch0_tensor_required_i(dut_tensor_required_w),
    .dispatch0_tensor_opclass_i(dut_tensor_opclass_w),
    .tensor_cmd_valid_o(tensor_cmd_valid),
    .tensor_cmd_ready_i(dut_tensor_cmd_ready_w),
    .tensor_cmd_bits_o(tensor_cmd_bits),
    .tensor_cmd_rs_value_o(tensor_cmd_rs_value),
    .tensor_cmd_producer_id_o(tensor_cmd_pid),
    .tensor_cmd_is_64_o(tensor_cmd_is_64),
    .tensor_cmd_required_o(),
    .tensor_cmd_opclass_o(),
    .tensor_terminal_valid_i(dut_tensor_terminal_valid_w),
    .tensor_terminal_ready_o(tensor_terminal_ready),
    .tensor_terminal_producer_id_i(dut_tensor_terminal_pid_w),
    .tensor_terminal_error_i(dut_tensor_terminal_error_w),
    .tensor_terminal_error_code_i(dut_tensor_terminal_error_code_w),
    .tensor_serialize_o(tensor_serialize),
    .dispatch0_unsupported_o(dispatch0_unsupported),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(1'b0),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i('0),
    .dispatch1_bht_idx_i({`BPU_BHT_INDEX_W{1'b0}}),
    .dispatch1_pred_taken_i(1'b0),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_csr_rdata_i({`XLEN{1'b0}}),
    .dispatch1_unsupported_o(dispatch1_unsupported),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(1'b1),
    .mem_req_write_o(mem_req_write),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(1'b0),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i({`XLEN{1'b0}}),
    .mem_rsp_error_i(1'b0),
    .mem_rsp_page_fault_i(1'b0),
    .mem_rsp_attr_valid_i(1'b1),
    .mem_rsp_class_i(`OOO_MEM_CLASS_CACHED),
    .mem_rsp_cacheable_i(1'b1),
    .mem_req_attr_valid_o(),
    .mem_req_class_o(),
    .mem_req_cacheable_o(),
    .commit_ready_i(commit_ready),
    .commit1_block_i(1'b0),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_arch_rd_o(commit0_arch_rd),
    .commit0_old_pdest_o(commit0_old_pdest),
    .commit0_new_pdest_o(commit0_new_pdest),
    .commit0_data_o(commit0_data),
    .commit0_exception_o(commit0_exception),
    .commit0_cause_o(commit0_cause),
    .commit0_tval_o(commit0_tval),
    .commit0_producer_id_o(),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_arch_rd_o(commit1_arch_rd),
    .commit1_old_pdest_o(commit1_old_pdest),
    .commit1_new_pdest_o(commit1_new_pdest),
    .commit1_data_o(commit1_data),
    .commit1_exception_o(commit1_exception),
    .commit1_cause_o(commit1_cause),
    .commit1_tval_o(commit1_tval),
    .frm_i(3'b000),
    .free_count_o(free_count),
    .rob_count_o(rob_count),
	    .issue_count_o(issue_count),
	    .execute0_valid_o(execute0_valid),
	    .execute1_valid_o(execute1_valid),
	    .branch_resolve_valid_o(branch_resolve_valid),
	    .branch_resolve_pc_o(branch_resolve_pc),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned)
	  );

`ifdef RV64_REAL_NPU_LINK
  TensorNpuCoprocessor #(
    .LMEM_BYTES(4096),
    .PID_W(8),
    .OPCLASS_W(8)
  ) real_npu (
    .clk(clk),
    .rst(rst),
    .cmd_valid_i(tensor_cmd_valid && !link_stall),
    .cmd_ready_o(npu_cmd_ready),
    .cmd_is_64_i(pair_tensor_is_64),
    .cmd_bits_i(tensor_cmd_bits),
    .cmd_rs_value_i(64'b0),
    .cmd_producer_id_i(tensor_cmd_pid),
    .cmd_npu_required_i(pair_tensor_required),
    .cmd_opclass_i(pair_tensor_opclass),
    .macro_cmd_valid_i(1'b0),
    .completion_valid_o(npu_completion_valid),
    .completion_ready_i(tensor_terminal_ready && !completion_stall &&
                        !inject_wrong_pid),
    .completion_producer_id_o(npu_completion_pid),
    .completion_error_o(npu_completion_error),
    .completion_error_code_o(npu_completion_error_code),
    .desc_write_valid_i(1'b0),
    .host_lmem_rd_valid_i(1'b0),
    .host_lmem_wr_valid_i(1'b0),
    .gmem_req_ready_i(1'b1),
    .gmem_rsp_valid_i(1'b0),
    .gmem_rsp_rdata_i(64'b0),
    .gmem_rsp_error_i(1'b0),
    .sync_tag_ack_i(1'b1),
    .error_clear_i(1'b0),
    .command_count_o(npu_command_count),
    .completion_count_o(npu_completion_count),
    .error_count_o(npu_error_count)
  );
`endif

  wire unused_next_pc_w = (|commit0_next_pc) | (|commit1_next_pc) |
                          branch_resolve_valid | (|branch_resolve_pc) |
                          (|branch_resolve_next_pc) |
                          branch_resolve_misaligned;

  function [`INST_W-1:0] inst_addi;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_addi = rv32_i(imm, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP_IMM);
    end
  endfunction

  function [`INST_W-1:0] inst_add;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_add = rv32_r(`FUNCT7_STD, rs2, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP);
    end
  endfunction

  function [`INST_W-1:0] inst_sub;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_sub = rv32_r(`FUNCT7_ALT, rs2, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP);
    end
  endfunction

  function [`INST_W-1:0] inst_jal;
    input [4:0] rd;
    input [20:0] imm;
    begin
      inst_jal = rv32_j(imm, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_jalr;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_jalr = rv32_i(imm, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_JALR);
    end
  endfunction

  function [`INST_W-1:0] inst_fmv_w_x;
    input [4:0] rd;
    input [4:0] rs1;
    begin
      inst_fmv_w_x = {7'b1111000, 5'b00000, rs1, 3'b000, rd,
                      `OPCODE_OP_FP};
    end
  endfunction

  task automatic clear_dispatch;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_is_tensor = 1'b0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      commit_ready = 1'b1;
      tensor_bits = 64'b0;
      tensor_is_64 = 1'b1;
      tensor_cmd_ready = 1'b0;
      tensor_terminal_valid = 1'b0;
      tensor_terminal_pid = {`OOO_PRODUCER_ID_W{1'b0}};
      clear_dispatch();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic set_pair;
    input [`XLEN-1:0] pc0;
    input [`INST_W-1:0] inst0;
    input [`XLEN-1:0] pc1;
    input [`INST_W-1:0] inst1;
    begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = pc0;
      dispatch0_inst = inst0;
      dispatch1_valid = 1'b1;
      dispatch1_pc = pc1;
      dispatch1_inst = inst1;
    end
  endtask

  task automatic dispatch_independent_pair;
    input [1023:0] label;
    input [`XLEN-1:0] exp0;
    input [`XLEN-1:0] exp1;
    integer cycles;
    reg seen;
    begin
      cycles = 0;
      seen = 1'b0;
      #1;
      tb_check1({label, " lane0 ready"}, dispatch0_ready, 1'b1);
      tb_check1({label, " lane1 ready"}, dispatch1_ready, 1'b1);
      tb_check1({label, " lane0 supported"}, dispatch0_unsupported, 1'b0);
      tb_check1({label, " lane1 supported"}, dispatch1_unsupported, 1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32({label, " two rob entries"}, {27'b0, rob_count}, 32'd2);

      while (!seen && cycles < 6) begin
        #1;
        if (commit0_valid && commit1_valid) begin
          tb_check32({label, " commit0 data"}, commit0_data, exp0);
          tb_check32({label, " commit1 data"}, commit1_data, exp1);
          seen = 1'b1;
        end else begin
          `TB_TICK(clk);
          cycles = cycles + 1;
        end
      end
      if (!seen) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s did not commit a pair", label);
      end
      `TB_TICK(clk);
      #1;
      tb_check32({label, " rob drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " iq drains"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"}, {25'b0, free_count}, 32'd32);
    end
  endtask

`ifndef RV64_REAL_NPU_LINK
`ifdef TENSOR_WB_DISPATCH_COLLISION_FOCUSED
  initial begin : tensor_wb_dispatch_collision_test
    integer cycles;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;

    tb_errors = 0;
    reset_dut();

    // Produce x5 through the normal integer dispatch/IQ/EX/WB path.  The
    // consumer is deliberately withheld until this LUI reaches formal WB.
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0500;
    dispatch0_inst = 32'h1234_52b7;  // lui x5, 0x12345
    dispatch0_is_tensor = 1'b0;
    #1;
    tb_check1("collision producer supported", dispatch0_unsupported, 1'b0);
    tb_check1("collision producer dispatch ready", dispatch0_ready, 1'b1);
    producer_pdest = dut.u_int_backend.dispatch0_pdest_w;
    tb_check1("collision producer owns a physical destination",
              |producer_pdest, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check32("collision producer PRF starts old low",
               dut.u_int_backend.u_phys_reg_file.regs_q[producer_pdest][31:0],
               32'b0);
    tb_check32("collision producer PRF starts old high",
               dut.u_int_backend.u_phys_reg_file.regs_q[producer_pdest][63:32],
               32'b0);

    // Wait only for the real formal-WB owner; this keeps the regression
    // independent of the current dispatch-to-EX latency while preserving the
    // exact WB/consumer-dispatch collision edge below.
    cycles = 0;
    while (!dut.u_int_backend.wb0_valid_w && cycles < 8) begin
      `TB_TICK(clk);
      cycles = cycles + 1;
    end
    #1;
    tb_check1("collision producer formal WB valid",
              dut.u_int_backend.wb0_valid_w, 1'b1);
    tb_check1("collision producer GPR WB enabled",
              dut.u_int_backend.gpr_wb0_write_valid_w, 1'b1);
    tb_check32("collision producer WB physical destination",
               {26'b0, dut.u_int_backend.wb0_pdest_w},
               {26'b0, producer_pdest});
    tb_check32("collision producer WB low",
               dut.u_int_backend.wb0_data_w[31:0], 32'h1234_5000);
    tb_check32("collision producer WB high",
               dut.u_int_backend.wb0_data_w[63:32], 32'b0);

    // CFG.SATU reads x5.  BusyTable sees the same-cycle WB wake and reports
    // ready, while the stored-only PRF read still exposes its pre-edge zero.
    // The sidecar must therefore capture the matching WB payload, not that old
    // PRF value, on the shared WB/dispatch edge.
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0504;
    dispatch0_inst = 32'h0a02_c05b;  // CFG.SATU, rs1=x5
    dispatch0_is_tensor = 1'b1;
    tensor_bits = 64'h0000_0000_0a02_c05b;
    tensor_is_64 = 1'b0;
    tensor_cmd_ready = 1'b0;
    #1;
    tb_check1("collision tensor supported", dispatch0_unsupported, 1'b0);
    tb_check1("collision tensor dispatch ready", dispatch0_ready, 1'b1);
    tb_check1("collision tensor dispatch fires",
              dut.u_int_backend.dispatch0_fire_w, 1'b1);
    tb_check32("collision tensor source maps producer pdest",
               {26'b0, dut.u_int_backend.dispatch0_src1_preg_w},
               {26'b0, producer_pdest});
    tb_check1("collision tensor source same-cycle ready",
              dut.u_int_backend.dispatch0_src1_ready_w, 1'b1);
    tb_check1("collision producer WB remains aligned",
              dut.u_int_backend.wb0_valid_w, 1'b1);
    tb_check32("collision PRF pre-edge value low",
               dut.u_int_backend.u_phys_reg_file.regs_q[producer_pdest][31:0],
               32'b0);
    tb_check32("collision PRF pre-edge value high",
               dut.u_int_backend.u_phys_reg_file.regs_q[producer_pdest][63:32],
               32'b0);
    $display("[TENSOR-WB-DISPATCH-COLLISION] preedge wb=%h prf=%h pdest=%0d",
             dut.u_int_backend.wb0_data_w,
             dut.u_int_backend.u_phys_reg_file.regs_q[producer_pdest],
             producer_pdest);
    `TB_TICK(clk);
    clear_dispatch();
    #1;

    tb_check32("collision PRF writes producer low",
               dut.u_int_backend.u_phys_reg_file.regs_q[producer_pdest][31:0],
               32'h1234_5000);
    tb_check32("collision PRF writes producer high",
               dut.u_int_backend.u_phys_reg_file.regs_q[producer_pdest][63:32],
               32'b0);
    tb_check1("collision sidecar dependency ready",
              dut.u_int_backend.u_tensor_rob_sidecar.src_dep_ready_q, 1'b1);
    tb_check1("collision sidecar WB operand valid",
              dut.u_int_backend.u_tensor_rob_sidecar.src_operand_valid_q,
              1'b1);
    tb_check1("collision sidecar bypasses deferred PRF read",
              dut.u_int_backend.tensor_src_read_valid_w, 1'b0);

    cycles = 0;
    while (!tensor_cmd_valid && cycles < 12) begin
      `TB_TICK(clk);
      cycles = cycles + 1;
    end
    #1;
    tb_check1("collision tensor command offered", tensor_cmd_valid, 1'b1);
    tb_check1("collision command remains backpressured", tensor_cmd_ready,
              1'b0);
    if (tensor_cmd_rs_value !== 64'h0000_0000_1234_5000) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] collision tensor rs value got=%h expected=%h",
               tensor_cmd_rs_value, 64'h0000_0000_1234_5000);
    end
    if (tensor_cmd_bits !== 64'h0000_0000_0a02_c05b) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] collision tensor bits got=%h expected=%h",
               tensor_cmd_bits, 64'h0000_0000_0a02_c05b);
    end
    tb_check1("collision tensor command is32", tensor_cmd_is_64, 1'b0);
    $display("[TENSOR-WB-DISPATCH-COLLISION] command rs=%h bits=%h is64=%b",
             tensor_cmd_rs_value, tensor_cmd_bits, tensor_cmd_is_64);

    tb_finish("tb_ooo_alu_decode_backend_tensor_wb_dispatch_collision");
  end
`elsif TENSOR_FP_SHARED_READ_COLLISION_FOCUSED
  initial begin : tensor_fp_shared_read_collision_test
    integer cycles;
    reg [PHY_REG_ADDR_W-1:0] fp_source_preg;
    reg [PHY_REG_ADDR_W-1:0] tensor_source_preg;
    reg [PHY_REG_ADDR_W-1:0] fp_pdest;

    tb_errors = 0;
    reset_dut();

    // Establish two distinct, committed GPR sources through the real integer
    // path.  x6 feeds the older FP operation; x5 belongs only to Tensor.
    set_pair(32'h8000_0600, 32'h1234_52b7,  // lui x5, 0x12345
             32'h8000_0604, 32'h3f80_0337); // lui x6, 0x3f800
    dispatch_independent_pair("shared-read source pair",
                              64'h0000_0000_1234_5000,
                              64'h0000_0000_3f80_0000);

    // The FP packet is older in ROB/program order.  Its GPR-consuming launch
    // crosses the real non-fallthrough FP issue-stage boundary.
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0610;
    dispatch0_inst = inst_fmv_w_x(5'd3, 5'd6);
    dispatch0_is_tensor = 1'b0;
    #1;
    tb_check1("shared-read FP supported", dispatch0_unsupported, 1'b0);
    tb_check1("shared-read FP dispatch ready", dispatch0_ready, 1'b1);
    fp_source_preg = dut.u_int_backend.dispatch0_src1_preg_w;
    fp_pdest = dut.u_int_backend.fp_disp_new_pdest_w;
    tb_check1("shared-read FP source is nonzero", |fp_source_preg, 1'b1);
    tb_check1("shared-read FP destination is nonzero", |fp_pdest, 1'b1);
    tb_check32("shared-read FP source PRF low",
               dut.u_int_backend.u_phys_reg_file.regs_q[fp_source_preg][31:0],
               32'h3f80_0000);
    tb_check32("shared-read FP source PRF high",
               dut.u_int_backend.u_phys_reg_file.regs_q[fp_source_preg][63:32],
               32'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("shared-read FP becomes IQ issue candidate",
              dut.u_int_backend.u_fp_backend.iq_issue_valid_w, 1'b1);

    // Allocate the younger Tensor exactly as the FP candidate enters its issue
    // packet.  Both will require PRF read8 after this edge.
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0614;
    dispatch0_inst = 32'h0a02_c05b;  // CFG.SATU, rs1=x5
    dispatch0_is_tensor = 1'b1;
    tensor_bits = 64'h0000_0000_0a02_c05b;
    tensor_is_64 = 1'b0;
    tensor_cmd_ready = 1'b0;
    #1;
    tb_check1("shared-read Tensor supported", dispatch0_unsupported, 1'b0);
    tb_check1("shared-read Tensor dispatch ready", dispatch0_ready, 1'b1);
    tb_check1("shared-read Tensor dispatch fires",
              dut.u_int_backend.dispatch0_fire_w, 1'b1);
    tensor_source_preg = dut.u_int_backend.dispatch0_src1_preg_w;
    tb_check1("shared-read sources use distinct physical registers",
              tensor_source_preg != fp_source_preg, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;

    // Conflict cycle: actual FP launch owns read8.  Tensor's resident request
    // stays asserted but sees no grant; the shared address/data and the value
    // consumed by FP all belong to x6, never Tensor's x5.
    tb_check1("shared-read FP actual-use fire",
              dut.u_int_backend.fp_gpr_read_fire_w, 1'b1);
    tb_check1("shared-read Tensor request resident",
              dut.u_int_backend.tensor_src_read_valid_w, 1'b1);
    tb_check32("shared-read Tensor retained preg during conflict",
               {26'b0, dut.u_int_backend.tensor_src_read_preg_w},
               {26'b0, tensor_source_preg});
    tb_check1("shared-read Tensor denied by older FP",
              dut.u_int_backend.tensor_src_read_ready_w, 1'b0);
    tb_check32("shared-read conflict address owned by FP",
               {26'b0, dut.u_int_backend.shared_gpr_read_addr_w},
               {26'b0, fp_source_preg});
    tb_check32("shared-read PRF read8 address owned by FP",
               {26'b0, dut.u_int_backend.u_phys_reg_file.read8_addr_i},
               {26'b0, fp_source_preg});
    tb_check32("shared-read conflict data low belongs to FP",
               dut.u_int_backend.u_phys_reg_file.read8_data_o[31:0],
               32'h3f80_0000);
    tb_check32("shared-read conflict data high belongs to FP",
               dut.u_int_backend.u_phys_reg_file.read8_data_o[63:32],
               32'b0);
    tb_check32("shared-read FP consumes selected data",
               dut.u_int_backend.u_fp_backend.gpr_read_data_i[31:0],
               32'h3f80_0000);
    tb_check1("shared-read conflict cannot offer Tensor command",
              tensor_cmd_valid, 1'b0);
    $display("[TENSOR-FP-SHARED-READ] conflict fp_preg=%0d tensor_preg=%0d addr=%0d data=%h",
             fp_source_preg, tensor_source_preg,
             dut.u_int_backend.shared_gpr_read_addr_w,
             dut.u_int_backend.u_phys_reg_file.read8_data_o);

    // On the first cycle after FP consumes its packet, the request must still
    // be present and immediately receive the now-free port.  The same cycle
    // also exposes the real, correctly NaN-boxed FMV.W.X result.
    `TB_TICK(clk);
    #1;
    tb_check1("shared-read FP releases port after launch",
              dut.u_int_backend.fp_gpr_read_fire_w, 1'b0);
    tb_check1("shared-read Tensor request survives conflict",
              dut.u_int_backend.tensor_src_read_valid_w, 1'b1);
    tb_check1("shared-read Tensor granted first free cycle",
              dut.u_int_backend.tensor_src_read_ready_w, 1'b1);
    tb_check32("shared-read free-cycle address belongs to Tensor",
               {26'b0, dut.u_int_backend.shared_gpr_read_addr_w},
               {26'b0, tensor_source_preg});
    tb_check32("shared-read Tensor source low",
               dut.u_int_backend.u_phys_reg_file.read8_data_o[31:0],
               32'h1234_5000);
    tb_check32("shared-read Tensor source high",
               dut.u_int_backend.u_phys_reg_file.read8_data_o[63:32],
               32'b0);
    tb_check1("shared-read FP result authorized",
              dut.u_int_backend.u_fp_backend.fp_result_wb_valid_w, 1'b1);
    tb_check32("shared-read FP result destination",
               {26'b0, dut.u_int_backend.u_fp_backend.fp_result_wb_preg_w},
               {26'b0, fp_pdest});
    tb_check32("shared-read FP result low",
               dut.u_int_backend.u_fp_backend.fp_result_wb_value_w[31:0],
               32'h3f80_0000);
    tb_check32("shared-read FP result NaN-box high",
               dut.u_int_backend.u_fp_backend.fp_result_wb_value_w[63:32],
               32'hffff_ffff);
    $display("[TENSOR-FP-SHARED-READ] first-free grant tensor_data=%h fp_result=%h",
             dut.u_int_backend.u_phys_reg_file.read8_data_o,
             dut.u_int_backend.u_fp_backend.fp_result_wb_value_w);

    `TB_TICK(clk);
    #1;
    tb_check1("shared-read Tensor request completes once",
              dut.u_int_backend.tensor_src_read_valid_w, 1'b0);
    tb_check1("shared-read Tensor operand becomes valid",
              dut.u_int_backend.u_tensor_rob_sidecar.src_operand_valid_q,
              1'b1);
    tb_check32("shared-read Tensor captured source low",
               dut.u_int_backend.u_tensor_rob_sidecar.src_value_q[31:0],
               32'h1234_5000);
    tb_check32("shared-read FP physical result low",
               dut.u_int_backend.u_fp_backend.u_fp_phys_reg_file.regs_q[fp_pdest][31:0],
               32'h3f80_0000);
    tb_check32("shared-read FP physical result high",
               dut.u_int_backend.u_fp_backend.u_fp_phys_reg_file.regs_q[fp_pdest][63:32],
               32'hffff_ffff);

    cycles = 0;
    while (!tensor_cmd_valid && cycles < 20) begin
      `TB_TICK(clk);
      cycles = cycles + 1;
    end
    #1;
    tb_check1("shared-read Tensor command eventually offered",
              tensor_cmd_valid, 1'b1);
    tb_check1("shared-read Tensor command stays backpressured",
              tensor_cmd_ready, 1'b0);
    tb_check32("shared-read final Tensor source low",
               tensor_cmd_rs_value[31:0], 32'h1234_5000);
    tb_check32("shared-read final Tensor source high",
               tensor_cmd_rs_value[63:32], 32'b0);
    tb_check1("shared-read Tensor did not capture FP source",
              tensor_cmd_rs_value != 64'h0000_0000_3f80_0000, 1'b1);
    tb_check32("shared-read final Tensor bits",
               tensor_cmd_bits[31:0], 32'h0a02_c05b);
    tb_check1("shared-read final Tensor is 32-bit", tensor_cmd_is_64, 1'b0);
    $display("[TENSOR-FP-SHARED-READ][PASS] fp=%h tensor=%h bits=%h",
             64'hffff_ffff_3f80_0000, tensor_cmd_rs_value,
             tensor_cmd_bits);

    tb_finish("tb_ooo_alu_decode_backend_tensor_fp_shared_read_collision");
  end
`else
  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check32("initial freelist count", {25'b0, free_count}, 32'd32);
    tb_check32("initial rob count", {27'b0, rob_count}, 32'd0);
    tb_check32("initial issue count", {28'b0, issue_count}, 32'd0);

    set_pair(32'h8000_0000, inst_addi(5'd5, 5'd0, 12'd7),
             32'h8000_0004, inst_addi(5'd6, 5'd0, 12'd9));
    dispatch_independent_pair("raw addi pair", 32'd7, 32'd9);

    set_pair(32'h8000_0010, inst_addi(5'd7, 5'd0, 12'd7),
             32'h8000_0014, inst_addi(5'd8, 5'd7, 12'd3));
    #1;
    tb_check1("raw dependent lane0 ready", dispatch0_ready, 1'b1);
    tb_check1("raw dependent lane1 ready", dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    // R3.2: producer actual fire writes IQ sticky ready and registered EX0
    // payload on the same edge.  The consumer selects in N+1 and forwards
    // only from that registered payload; both still retire in ROB order.
    tb_check32("raw dependent pair queued", {28'b0, issue_count}, 32'd2);
    `TB_TICK(clk);
    #1;
    tb_check32("raw consumer waits resident in iq", {28'b0, issue_count},
               32'd1);
    tb_check1("raw producer execute", execute0_valid, 1'b1);
    tb_check1("R3.2 raw consumer selects N+1",
              dut.u_int_backend.issue0_valid_w, 1'b1);
    tb_check1("R3.2 raw consumer registered EX0 hit",
              dut.u_int_backend.issue0_src1_ex0_fwd_hit_w, 1'b1);
    tb_check32("R3.2 raw consumer forwarded source",
               dut.u_int_backend.issue0_src1_data_w[31:0], 32'd7);
    tb_check1("raw producer does not retire on formal WB cycle",
              commit0_valid, 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check32("raw consumer leaves IQ on N+1 fire",
               {28'b0, issue_count}, 32'd0);
    tb_check1("raw producer commits from ROB Q", commit0_valid, 1'b1);
    tb_check32("raw producer data from ROB Q", commit0_data, 32'd7);
    tb_check1("raw consumer executes from registered EX", execute0_valid,
              1'b1);
    `TB_TICK(clk);
    #1;
    tb_check1("raw consumer commits from ROB Q", commit0_valid, 1'b1);
    tb_check32("raw consumer data from ROB Q", commit0_data, 32'd10);
    `TB_TICK(clk);
    #1;

    set_pair(32'h8000_0100, rv32_u(20'h12345, 5'd9, `OPCODE_LUI),
             32'h8000_0104, rv32_u(20'h00001, 5'd10, `OPCODE_AUIPC));
    dispatch_independent_pair("raw u-type pair", 32'h1234_5000, 32'h8000_1104);

    // mode=0：jal+jalr 作 independent pair 一起 commit；
    // mode=1（OOO_ROB_WALK_MODE）：控制流 de-pend + 强制 mispredict redirect 会 kill lane1（younger），
    // 故不 commit pair（设计意图），jump/jalr 正确性由 riscv-tests 135/0 端到端覆盖。
    if (!`OOO_ROB_WALK_MODE) begin
    set_pair(32'h8000_0180, inst_jal(5'd13, 21'd8),
             32'h8000_0184, inst_jalr(5'd14, 5'd0, 12'd0));
    dispatch_independent_pair("jump link pair", 32'h8000_0184, 32'h8000_0188);
    end

    set_pair(32'h8000_0200, inst_add(5'd11, 5'd5, 5'd6),
             32'h8000_0204, inst_sub(5'd12, 5'd6, 5'd5));
    dispatch_independent_pair("raw r-type pair", 32'd16, 32'd2);

    set_pair(32'h8000_0300, inst_addi(5'd13, 5'd0, 12'd13),
             32'h8000_0304, rv32_b(13'd8, 5'd0, 5'd0, `FUNCT3_BEQ));
    #1;
    tb_check1("unsupported lane0 still ready", dispatch0_ready, 1'b1);
    tb_check1("branch lane1 backend ready", dispatch1_ready, 1'b1);
    tb_check1("branch lane1 backend supported", dispatch1_unsupported, 1'b0);
    clear_dispatch();

    // Live direct-NPU chain: decoded tensor sideband allocates a canonical ROB
    // entry, bypasses the integer IQ, offers a sticky tagged command, accepts
    // the exact external terminal, arbitrates onto formal WB, then retires in
    // program order.  This is intentionally not a standalone owner-only TB.
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0400;
    dispatch0_inst = 32'h0000_005b;
    dispatch0_is_tensor = 1'b1;
    tensor_bits = 64'h55aa_1234_0000_005b;
    tensor_cmd_ready = 1'b0;
    #1;
    tb_check1("tensor dispatch supported", dispatch0_unsupported, 1'b0);
    tb_check1("tensor dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check32("tensor owns one ROB slot", {27'b0, rob_count}, 32'd1);
    tb_check32("tensor bypasses integer IQ", {28'b0, issue_count}, 32'd0);
    `TB_TICK(clk);
    #1;
    tb_check1("tensor command offered", tensor_cmd_valid, 1'b1);
    tb_check1("tensor serialization active", tensor_serialize, 1'b1);
    tb_check32("tensor command low payload", tensor_cmd_bits[31:0],
               32'h0000_005b);
    `TB_TICK(clk);
    #1;
    tb_check1("tensor command sticky under backpressure", tensor_cmd_valid,
              1'b1);
    tb_check32("tensor payload stable under backpressure",
               tensor_cmd_bits[31:0], 32'h0000_005b);
    tensor_terminal_pid = tensor_cmd_pid;
    tensor_cmd_ready = 1'b1;
    `TB_TICK(clk);
    tensor_cmd_ready = 1'b0;
    tensor_terminal_valid = 1'b1;
    #1;
    tb_check1("tensor terminal exact owner ready", tensor_terminal_ready,
              1'b1);
    tb_check1("tensor terminal cannot bypass registered ROB done preedge",
              commit0_valid, 1'b0);
    `TB_TICK(clk);
    tensor_terminal_valid = 1'b0;
    #1;
    tb_check1("tensor direct-WB registered precise commit", commit0_valid,
              1'b1);
    tb_check32("tensor direct-WB precise commit pc", commit0_pc[31:0],
               32'h8000_0400);
    tb_check1("tensor success has no exception", commit0_exception, 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check32("tensor ROB drains", {27'b0, rob_count}, 32'd0);
    tb_check1("tensor serialization releases", tensor_serialize, 1'b0);

    tb_finish("tb_ooo_alu_decode_backend");
  end
`endif
`else
  initial begin : real_npu_link_test
    integer cycles;
    reg [7:0] issued_pid;
  reg saw_matching_terminal;
  reg saw_precise_commit;
  reg saw_error_terminal;

    tb_errors = 0;
    link_stall = 1'b1;
    completion_stall = 1'b1;
    inject_wrong_pid = 1'b0;
    pair_head_valid = 1'b0;
    pair_head_slot1_valid = 1'b0;
    pair_head_pc0 = 64'b0;
    pair_head_inst0 = 32'b0;
    pair_head_pc1 = 64'b0;
    pair_head_inst1 = 32'b0;
    reset_dut();

    // Legal single-word CFG.SATU enters through the real PairOwner, allocates
    // a ROB identity and must keep the CPU offer stable while the link stalls.
    pair_head_pc0 = 64'h0000_0000_8000_0000;
    pair_head_inst0 = {7'b0000101, 5'b00000, 5'b00000, 3'b100,
                       5'b00000, 7'b1011011};
    pair_head_valid = 1'b1;
    #1;
    tb_check1("real single custom-2 claimed", pair_head_pop, 1'b1);
    `TB_TICK(clk);
    pair_head_valid = 1'b0;

    cycles = 0;
    while (!tensor_cmd_valid && cycles < 20) begin
      `TB_TICK(clk);
      cycles = cycles + 1;
    end
    tb_check1("real single reaches CPU command link", tensor_cmd_valid, 1'b1);
    tb_check1("real single serializes CPU", tensor_serialize, 1'b1);
    tb_check32("real single command encoding", tensor_cmd_bits[31:0],
               pair_head_inst0);
    issued_pid = tensor_cmd_pid;
    `TB_TICK(clk);
    #1;
    tb_check1("real command sticky during link backpressure", tensor_cmd_valid,
              1'b1);
    tb_check32("real NPU sees no command while link stalled",
               npu_command_count[31:0], 32'd0);

    link_stall = 1'b0;
    `TB_TICK(clk);
    #1;
    tb_check32("real NPU accepts single command",
               npu_command_count[31:0], 32'd1);

    cycles = 0;
    while (!npu_completion_valid && cycles < 30) begin
      `TB_TICK(clk);
      cycles = cycles + 1;
    end
    tb_check1("real NPU holds terminal under completion backpressure",
              npu_completion_valid, 1'b1);
    tb_check32("real held terminal PID", {24'b0, npu_completion_pid},
               {24'b0, issued_pid});
    `TB_TICK(clk);
    #1;
    tb_check1("real terminal valid remains sticky", npu_completion_valid,
              1'b1);
    tb_check32("real terminal PID stable under backpressure",
               {24'b0, npu_completion_pid}, {24'b0, issued_pid});

    // Present the held real terminal once with a deliberately corrupted
    // generation bit while withholding ready from the NPU.  The sidecar must
    // drain/drop that stale identity without completing the ROB; the same real
    // terminal is then re-presented unmodified and accepted exactly once.
    completion_stall = 1'b0;
    inject_wrong_pid = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("wrong-generation terminal cannot retire", commit0_valid, 1'b0);
    tb_check1("real terminal remains resident after wrong PID probe",
              npu_completion_valid, 1'b1);
    inject_wrong_pid = 1'b0;

    saw_matching_terminal = 1'b0;
    saw_precise_commit = 1'b0;
    cycles = 0;
    while (!saw_precise_commit && cycles < 40) begin
      #1;
      if (npu_completion_valid) begin
        tb_check32("real single terminal PID", {24'b0, npu_completion_pid},
                   {24'b0, issued_pid});
        tb_check1("real single terminal success", npu_completion_error,
                  1'b0);
        saw_matching_terminal = 1'b1;
      end
      if (commit0_valid) begin
        tb_check32("real single precise retire PC", commit0_pc[31:0],
                   32'h8000_0000);
        tb_check1("real single precise retire success", commit0_exception,
                  1'b0);
        saw_precise_commit = 1'b1;
      end
      if (!saw_precise_commit)
        `TB_TICK(clk);
      cycles = cycles + 1;
    end
    tb_check1("real single matching terminal observed", saw_matching_terminal,
              1'b1);
    tb_check1("real single precise retire observed", saw_precise_commit, 1'b1);
    if (commit0_valid)
      `TB_TICK(clk);

    completion_stall = 1'b0;

    // Correctly framed LO+HI reaches the same real legacy decoder.  Default
    // descriptor state is intentionally invalid, so the real NPU returns an
    // error which must retain the full PID and become a precise ROB exception.
    pair_head_pc0 = 64'h0000_0000_8000_0010;
    pair_head_inst0 = {5'b00000, 1'b0, 1'b1, 3'b000, 1'b1, 1'b0,
                       5'b00000, 3'b011, 5'b00000, 7'b1011011};
    pair_head_pc1 = 64'h0000_0000_8000_0014;
    pair_head_inst1 = {7'b0000101, 5'b00101, 5'b00000, 3'b011,
                       5'b00000, 7'b1011011};
    pair_head_slot1_valid = 1'b1;
    pair_head_valid = 1'b1;
    #1;
    tb_check1("real LO+HI custom-2 pair claimed", pair_head_pop, 1'b1);
    `TB_TICK(clk);
    pair_head_valid = 1'b0;
    pair_head_slot1_valid = 1'b0;

    cycles = 0;
    while (!tensor_cmd_valid && cycles < 20) begin
      `TB_TICK(clk);
      cycles = cycles + 1;
    end
    tb_check1("real LO+HI reaches CPU command link", tensor_cmd_valid, 1'b1);
    tb_check1("real LO+HI is 64-bit", pair_tensor_is_64, 1'b1);
    issued_pid = tensor_cmd_pid;
    `TB_TICK(clk);

    saw_matching_terminal = 1'b0;
    saw_precise_commit = 1'b0;
    saw_error_terminal = 1'b0;
    cycles = 0;
    while (!saw_precise_commit && cycles < 120) begin
      #1;
      if (npu_completion_valid) begin
        tb_check32("real LO+HI terminal PID", {24'b0, npu_completion_pid},
                   {24'b0, issued_pid});
        tb_check1("real LO+HI terminal reports error", npu_completion_error,
                  1'b1);
        if (npu_completion_error_code == 8'b0) begin
          $display("[CHECK-FAIL] real LO+HI error code must be nonzero");
          tb_errors = tb_errors + 1;
        end
        saw_matching_terminal = 1'b1;
        saw_error_terminal = 1'b1;
      end
      if (commit0_valid) begin
        tb_check32("real LO+HI precise retire PC", commit0_pc[31:0],
                   32'h8000_0010);
        tb_check1("real LO+HI error becomes precise exception",
                  commit0_exception, 1'b1);
        tb_check1("real LO+HI error cannot write an architectural register",
                  commit0_rd_en, 1'b0);
        saw_precise_commit = 1'b1;
      end
      if (!saw_precise_commit)
        `TB_TICK(clk);
      cycles = cycles + 1;
    end
    tb_check1("real LO+HI matching terminal observed", saw_matching_terminal,
              1'b1);
    tb_check1("real LO+HI error terminal observed", saw_error_terminal, 1'b1);
    tb_check1("real LO+HI precise retire observed", saw_precise_commit, 1'b1);
    if (commit0_valid)
      `TB_TICK(clk);
    #1;
    tb_check32("real NPU command count", npu_command_count[31:0], 32'd2);
    tb_check32("real NPU completion count", npu_completion_count[31:0],
               32'd1);
    tb_check32("real NPU error count", npu_error_count[31:0], 32'd1);

    tb_finish("tb_ooo_direct_npu_real_link");
  end
`endif
endmodule
