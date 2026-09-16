`include "define.v"

module tb_ooo_alu_core_slice;
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
  wire [`XLEN-1:0] commit0_data;
  wire commit0_exception;
  wire commit0_write;
  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire [`XLEN-1:0] commit1_next_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_arch_rd;
  wire [`XLEN-1:0] commit1_data;
  wire commit1_exception;
  wire commit1_write;

  wire [FREE_COUNT_W-1:0] free_count;
  wire [ROB_COUNT_W-1:0] rob_count;
  wire [ISSUE_COUNT_W-1:0] issue_count;
  wire execute0_valid;
  wire execute1_valid;
  wire branch_resolve_valid;
  wire [`XLEN-1:0] branch_resolve_pc;
  wire [`XLEN-1:0] branch_resolve_next_pc;
  wire branch_resolve_misaligned;
  wire [1:0] retire_count;
  wire [`XLEN-1:0] a0_data;
  wire [`XLEN * `REG_NUM - 1:0] debug_gprs;
  wire mem_req_valid;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  wire mem_rsp_ready;
  wire unused_mem_w =
      mem_req_valid | mem_req_write | (|mem_req_addr) |
      (|mem_req_wdata) | (|mem_req_wstrb) | mem_rsp_ready;

  OooAluCoreSlice #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) dut (
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
    .mem_issue_block_i(1'b0),
    .pending_branch_fast_valid_i(1'b0),
    .pending_branch_fast_pc_i({`XLEN{1'b0}}),
    .pending_system_producer_valid_i(1'b0),
    .pending_system_producer_id_i({(ROB_INDEX_W + `OOO_PRODUCER_GEN_W){1'b0}}),
    .serial_write_valid_i(1'b0),
    .serial_write_arch_rd_i({`REG_ADDR_W{1'b0}}),
    .serial_write_data_i({`XLEN{1'b0}}),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_producer_id_o(),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_bht_idx_i({`BPU_BHT_INDEX_W{1'b0}}),
    .dispatch0_pred_taken_i(1'b0),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_csr_rdata_i({`XLEN{1'b0}}),
    .dispatch0_is_tensor_i(1'b0),
    .dispatch0_tensor_bits_i(64'b0),
    .dispatch0_tensor_is_64_i(1'b0),
    .dispatch0_tensor_required_i(1'b0),
    .dispatch0_tensor_opclass_i(8'b0),
    .tensor_cmd_ready_i(1'b0),
    .tensor_terminal_valid_i(1'b0),
    .tensor_terminal_producer_id_i(
        {(ROB_INDEX_W + `OOO_PRODUCER_GEN_W){1'b0}}),
    .tensor_terminal_error_i(1'b0),
    .tensor_terminal_error_code_i(8'b0),
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
    .mem_rsp_owner_kind_i(2'b00),
    .mem_rsp_owner_token_i(5'b00000),
    .mem_rsp_mmu_epoch_i(2'b00),
    .mem_rsp_fault_tval_i({`XLEN{1'b0}}),
    .mem_req_attr_valid_o(),
    .mem_req_class_o(),
    .mem_req_cacheable_o(),
    .mem_owner_query_valid_i(1'b0),
    .mem_owner_query_token_i(5'b00000),
    .mem_station_query_valid_i(1'b0),
    .mem_station_query_token_i(5'b00000),
    .mem_sq_query_valid_i(1'b0),
    .mem_sq_query_owner_kind_i(2'b00),
    .mem_sq_query_owner_token_i(5'b00000),
    .mem_sq_query_mmu_epoch_i(2'b00),
    .mem_sq_query_paddr_i({`XLEN{1'b0}}),
    .mem_sq_query_attr_valid_i(1'b0),
    .mem_sq_query_class_i(`OOO_MEM_CLASS_RSVD),
    .mem_sq_query_wstrb_i({`STRB_W{1'b0}}),
    .mem_drop0_valid_i(1'b0),
    .mem_drop0_owner_kind_i(2'b00),
    .mem_drop0_owner_token_i(5'b00000),
    .mem_drop0_mmu_epoch_i(2'b00),
    .mem_drop0_fault_tval_i({`XLEN{1'b0}}),
    .mem_drop1_valid_i(1'b0),
    .mem_drop1_owner_kind_i(2'b00),
    .mem_drop1_owner_token_i(5'b00000),
    .mem_drop1_mmu_epoch_i(2'b00),
    .mem_drop1_fault_tval_i({`XLEN{1'b0}}),
    .mem_bridge_owner_residency_mask_i(32'b0),
    .mem1_req_ready_i(1'b0),
    .mem1_rsp_valid_i(1'b0),
    .mem1_rsp_rdata_i({`XLEN{1'b0}}),
    .mem1_rsp_error_i(1'b0),
    .mem1_rsp_page_fault_i(1'b0),
    .mem1_rsp_attr_valid_i(1'b0),
    .mem1_rsp_class_i(`OOO_MEM_CLASS_RSVD),
    .mem1_rsp_cacheable_i(1'b0),
    .mem1_rsp_owner_kind_i(2'b00),
    .mem1_rsp_owner_token_i(5'b00000),
    .mem1_rsp_mmu_epoch_i(2'b00),
    .mem1_rsp_fault_tval_i({`XLEN{1'b0}}),
    .mem1_owner_query_valid_i(1'b0),
    .mem1_owner_query_token_i(5'b00000),
    .mem1_station_query_valid_i(1'b0),
    .mem1_station_query_token_i(5'b00000),
    .mem1_sq_query_valid_i(1'b0),
    .mem1_sq_query_owner_kind_i(2'b00),
    .mem1_sq_query_owner_token_i(5'b00000),
    .mem1_sq_query_mmu_epoch_i(2'b00),
    .mem1_sq_query_paddr_i({`XLEN{1'b0}}),
    .mem1_sq_query_attr_valid_i(1'b0),
    .mem1_sq_query_class_i(`OOO_MEM_CLASS_RSVD),
    .mem1_sq_query_wstrb_i({`STRB_W{1'b0}}),
    .mem1_drop0_valid_i(1'b0),
    .mem1_drop0_owner_kind_i(2'b00),
    .mem1_drop0_owner_token_i(5'b00000),
    .mem1_drop0_mmu_epoch_i(2'b00),
    .mem1_drop0_fault_tval_i({`XLEN{1'b0}}),
    .mem1_drop1_valid_i(1'b0),
    .mem1_drop1_owner_kind_i(2'b00),
    .mem1_drop1_owner_token_i(5'b00000),
    .mem1_drop1_mmu_epoch_i(2'b00),
    .mem1_drop1_fault_tval_i({`XLEN{1'b0}}),
    .mem1_bridge_owner_residency_mask_i(32'b0),
    .mem1_translate_active_i(1'b0),
    .mem_translate_active_i(1'b0),
    .frm_i(3'b000),
    .commit_ready_i(commit_ready),
    .commit1_block_i(1'b0),
    // 【serialize Phase1】commit-time CSR rd 覆写端口(此 TB 不测 CSR 队头化, 恒 0 = 基线 commit0_data)。
    .head0_csr_commit_i(1'b0),
    .commit0_csr_rdata_i({`XLEN{1'b0}}),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_arch_rd_o(commit0_arch_rd),
    .commit0_data_o(commit0_data),
    .commit0_exception_o(commit0_exception),
    .commit0_write_o(commit0_write),
    .commit0_producer_id_o(),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_arch_rd_o(commit1_arch_rd),
    .commit1_data_o(commit1_data),
    .commit1_exception_o(commit1_exception),
    .commit1_write_o(commit1_write),
    .free_count_o(free_count),
    .rob_count_o(rob_count),
	    .issue_count_o(issue_count),
	    .execute0_valid_o(execute0_valid),
	    .execute1_valid_o(execute1_valid),
	    .branch_resolve_valid_o(branch_resolve_valid),
	    .branch_resolve_pc_o(branch_resolve_pc),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned),
	    .retire_count_o(retire_count),
    .a0_data_o(a0_data),
    .debug_gprs_o(debug_gprs)
  );

  wire unused_next_pc_w = (|commit0_next_pc) | (|commit1_next_pc) |
                          branch_resolve_valid | (|branch_resolve_pc) |
                          (|branch_resolve_next_pc) |
                          branch_resolve_misaligned;

  function [`XLEN-1:0] gpr;
    input [`REG_ADDR_W-1:0] idx;
    begin
      gpr = debug_gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

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

  task automatic clear_dispatch;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = {`XLEN{1'b0}};
      dispatch0_inst = {`INST_W{1'b0}};
      dispatch1_valid = 1'b0;
      dispatch1_pc = {`XLEN{1'b0}};
      dispatch1_inst = {`INST_W{1'b0}};
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      commit_ready = 1'b1;
      clear_dispatch();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic dispatch_pair;
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
      #1;
      tb_check1("dispatch lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("dispatch lane1 ready", dispatch1_ready, 1'b1);
      tb_check1("dispatch lane0 supported", dispatch0_unsupported, 1'b0);
      tb_check1("dispatch lane1 supported", dispatch1_unsupported, 1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
    end
  endtask

  task automatic wait_retire_pair;
    input [1023:0] label;
    input [`REG_ADDR_W-1:0] rd0;
    input [`XLEN-1:0] data0;
    input [`REG_ADDR_W-1:0] rd1;
    input [`XLEN-1:0] data1;
    integer cycles;
    reg seen;
    begin
      seen = 1'b0;
      cycles = 0;
      while (!seen && cycles < 20) begin
        #1;
        if (commit0_valid && commit1_valid) begin
          tb_check32({label, " retire count"}, {30'b0, retire_count}, 32'd2);
          tb_check1({label, " commit0 write"}, commit0_write, (rd0 != 5'd0));
          tb_check1({label, " commit1 write"}, commit1_write, (rd1 != 5'd0));
          tb_check1({label, " commit0 exception"}, commit0_exception, 1'b0);
          tb_check1({label, " commit1 exception"}, commit1_exception, 1'b0);
          tb_check32({label, " commit0 rd"}, {27'b0, commit0_arch_rd}, {27'b0, rd0});
          tb_check32({label, " commit1 rd"}, {27'b0, commit1_arch_rd}, {27'b0, rd1});
          tb_check32({label, " commit0 data"}, commit0_data, data0);
          tb_check32({label, " commit1 data"}, commit1_data, data1);
          `TB_TICK(clk);
          #1;
          seen = 1'b1;
        end else begin
          `TB_TICK(clk);
          cycles = cycles + 1;
        end
      end
      if (!seen) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s did not retire a pair", label);
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check32("x0 after reset", gpr(5'd0), 32'd0);
    tb_check32("x1 after reset", gpr(5'd1), 32'd0);
    tb_check32("initial freelist", {25'b0, free_count}, 32'd32);

    dispatch_pair(32'h8000_0000, inst_addi(5'd1, 5'd0, 12'd11),
                  32'h8000_0004, inst_addi(5'd2, 5'd0, 12'd22));
    wait_retire_pair("addi pair", 5'd1, 32'd11, 5'd2, 32'd22);
    tb_check32("x1 committed", gpr(5'd1), 32'd11);
    tb_check32("x2 committed", gpr(5'd2), 32'd22);

    dispatch_pair(32'h8000_0010, inst_add(5'd3, 5'd1, 5'd2),
                  32'h8000_0014, inst_sub(5'd4, 5'd2, 5'd1));
    wait_retire_pair("dependent rtype pair", 5'd3, 32'd33, 5'd4, 32'd11);
    tb_check32("x3 committed", gpr(5'd3), 32'd33);
    tb_check32("x4 committed", gpr(5'd4), 32'd11);

    dispatch_pair(32'h8000_0020, inst_addi(5'd5, 5'd0, 12'd1),
                  32'h8000_0024, inst_addi(5'd5, 5'd0, 12'd9));
    wait_retire_pair("same-cycle waw pair", 5'd5, 32'd1, 5'd5, 32'd9);
    tb_check32("lane1 wins same-cycle WAW", gpr(5'd5), 32'd9);

    dispatch_pair(32'h8000_0030, inst_addi(5'd6, 5'd0, 12'd6),
                  32'h8000_0034, inst_addi(5'd7, 5'd0, 12'd7));
    commit_ready = 1'b0;
    repeat (6) begin
      `TB_TICK(clk);
      #1;
    end
    tb_check32("stall keeps x6 old", gpr(5'd6), 32'd0);
    tb_check32("stall keeps x7 old", gpr(5'd7), 32'd0);
    tb_check32("stall keeps rob entries", {27'b0, rob_count}, 32'd2);
    commit_ready = 1'b1;
    wait_retire_pair("backpressured pair", 5'd6, 32'd6, 5'd7, 32'd7);
    tb_check32("x6 committed after ready", gpr(5'd6), 32'd6);
    tb_check32("x7 committed after ready", gpr(5'd7), 32'd7);

    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0040;
    dispatch0_inst = inst_addi(5'd8, 5'd0, 12'd8);
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0044;
    dispatch1_inst = inst_addi(5'd9, 5'd0, 12'd9);
    #1;
    tb_check1("flush setup lane0 ready", dispatch0_ready, 1'b1);
    tb_check1("flush setup lane1 ready", dispatch1_ready, 1'b1);
    flush = 1'b1;
    `TB_TICK(clk);
    clear_dispatch();
    flush = 1'b0;
    #1;
    repeat (4) begin
      `TB_TICK(clk);
      #1;
    end
    tb_check32("flush drops speculative x8", gpr(5'd8), 32'd0);
    tb_check32("flush drops speculative x9", gpr(5'd9), 32'd0);
    tb_check32("a0 remains zero", a0_data, 32'd0);
    tb_check32("x0 remains zero", gpr(5'd0), 32'd0);
    tb_check32("empty ROB after flush", {27'b0, rob_count}, 32'd0);
    tb_check32("empty ROB has no retire", {30'b0, retire_count}, 32'd0);

    // INSTRET-G1 focused white-box vectors.  ROB commit-valid must remain high
    // for a precise exception, but the core ISA-retirement count filters that
    // lane.  Force only the already-public commit boundary; no internal ROB
    // state is modified.
    force dut.commit0_valid_o = 1'b1;
    force dut.commit0_exception_o = 1'b1;
    force dut.commit1_valid_o = 1'b0;
    force dut.commit1_exception_o = 1'b0;
    #1;
    tb_check32("exceptional lane0 is not ISA-retired",
               {30'b0, retire_count}, 32'd0);

    force dut.commit0_exception_o = 1'b0;
    force dut.commit1_valid_o = 1'b1;
    force dut.commit1_exception_o = 1'b1;
    #1;
    tb_check32("normal lane0 plus exceptional lane1 retires one",
               {30'b0, retire_count}, 32'd1);

    force dut.commit1_exception_o = 1'b0;
    #1;
    tb_check32("two normal commit lanes retire two",
               {30'b0, retire_count}, 32'd2);
    release dut.commit0_valid_o;
    release dut.commit0_exception_o;
    release dut.commit1_valid_o;
    release dut.commit1_exception_o;
    #1;
    tb_check32("forced retirement vectors release cleanly",
               {30'b0, retire_count}, 32'd0);

`ifdef OOO_NEGATIVE_CORE_RETIRE_WITH_EMPTY_ROB
    // Assertion non-vacuity only: the ROB is naturally empty here. Force the
    // theorem's producer, not both theorem endpoints, for exactly one edge.
    force dut.commit0_valid_o = 1'b1;
    `TB_TICK(clk);
    release dut.commit0_valid_o;
`endif

`ifdef OOO_NEGATIVE_CORE_RETIRE_X_WITH_EMPTY_ROB
    // Four-state companion: an unknown retire producer must not silently pass.
    force dut.commit0_valid_o = 1'bx;
    `TB_TICK(clk);
    release dut.commit0_valid_o;
`endif

    tb_finish("tb_ooo_alu_core_slice");
  end
endmodule
