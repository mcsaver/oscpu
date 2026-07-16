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

  OooAluDecodeBackend dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .checkpoint_capture_i(1'b0),
    .checkpoint_restore_i(1'b0),
    .checkpoint_quiesce_i(1'b0),
    .mem_issue_block_i(1'b0),
    .pending_branch_fast_valid_i(1'b0),
    .pending_branch_fast_pc_i({`XLEN{1'b0}}),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_unsupported_o(dispatch0_unsupported),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(1'b0),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i('0),
    .dispatch1_inst_i(dispatch1_inst),
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

  task automatic clear_dispatch;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
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

    tb_finish("tb_ooo_alu_decode_backend");
  end
endmodule
