`include "define.v"

module tb_ooo_int_issue_queue;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ENTRY_COUNT_W = 4;

  reg clk;
  reg rst;
  reg flush;
  reg checkpoint_capture;
  reg checkpoint_restore;
  reg issue_mem_block;
  reg dispatch0_valid;
  wire dispatch0_ready;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  reg [`CTRL_BUS_W-1:0] dispatch0_ctrl;
  reg [ROB_INDEX_W-1:0] dispatch0_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg;
  reg dispatch0_src1_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg;
  reg dispatch0_src2_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_pdest;
  reg [`XLEN-1:0] dispatch0_imm;
  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg [`CTRL_BUS_W-1:0] dispatch1_ctrl;
  reg dispatch1_optional;
  reg [ROB_INDEX_W-1:0] dispatch1_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg;
  reg dispatch1_src1_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg;
  reg dispatch1_src2_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_pdest;
  reg [`XLEN-1:0] dispatch1_imm;
  reg wakeup0_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
  reg wakeup1_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
  reg pending_load0_valid;
  reg [PHY_REG_ADDR_W-1:0] pending_load0_pdest;
  reg pending_load1_valid;
  reg [PHY_REG_ADDR_W-1:0] pending_load1_pdest;
  wire issue0_valid;
  reg issue0_ready;
  wire [`XLEN-1:0] issue0_pc;
  wire [`XLEN-1:0] issue0_next_pc;
  wire [`INST_W-1:0] issue0_inst;
  wire [`CTRL_BUS_W-1:0] issue0_ctrl;
  wire [ROB_INDEX_W-1:0] issue0_rob_idx;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg;
  wire [PHY_REG_ADDR_W-1:0] issue0_pdest;
  wire [`XLEN-1:0] issue0_imm;
  wire issue1_valid;
  reg issue1_ready;
  wire [`XLEN-1:0] issue1_pc;
  wire [`XLEN-1:0] issue1_next_pc;
  wire [`INST_W-1:0] issue1_inst;
  wire [`CTRL_BUS_W-1:0] issue1_ctrl;
  wire [ROB_INDEX_W-1:0] issue1_rob_idx;
  wire [PHY_REG_ADDR_W-1:0] issue1_src1_preg;
  wire [PHY_REG_ADDR_W-1:0] issue1_src2_preg;
  wire [PHY_REG_ADDR_W-1:0] issue1_pdest;
  wire [`XLEN-1:0] issue1_imm;
  wire [ENTRY_COUNT_W-1:0] count;
  wire empty;
  wire full;
  wire pending_load_branch_dep;
  wire load_branch_fast_valid;
  wire [ROB_INDEX_W-1:0] load_branch_fast_rob_idx;
  wire [`XLEN-1:0] load_branch_fast_pc;
  wire [`XLEN-1:0] load_branch_fast_next_pc;
  wire [`XLEN-1:0] load_branch_fast_imm;
  wire [2:0] load_branch_fast_cmp_op;
  wire [PHY_REG_ADDR_W-1:0] load_branch_fast_src1_preg;
  wire [PHY_REG_ADDR_W-1:0] load_branch_fast_src2_preg;
  wire load_branch_fast_wait_load0;
  wire load_branch_fast_wait_load1;
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  reg [ROB_INDEX_W-1:0] rob_head_idx;
  reg recover_active;

  OooIntIssueQueue dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .checkpoint_capture_i(checkpoint_capture),
    .checkpoint_restore_i(checkpoint_restore),
    .issue_mem_block_i(issue_mem_block),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_ctrl_i(dispatch0_ctrl),
    .dispatch0_rob_idx_i(dispatch0_rob_idx),
    .dispatch0_src1_preg_i(dispatch0_src1_preg),
    .dispatch0_src1_ready_i(dispatch0_src1_ready),
    .dispatch0_src2_preg_i(dispatch0_src2_preg),
    .dispatch0_src2_ready_i(dispatch0_src2_ready),
    .dispatch0_pdest_i(dispatch0_pdest),
    .dispatch0_fp_pdest_i(1'b0),
    .dispatch0_fp_st_src_en_i(1'b0),
    .dispatch0_fp_st_src_preg_i('0),
    .dispatch0_fp_st_src_ready_i(1'b1),
    .dispatch0_imm_i(dispatch0_imm),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(dispatch1_optional),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i('0),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_ctrl_i(dispatch1_ctrl),
    .dispatch1_rob_idx_i(dispatch1_rob_idx),
    .dispatch1_src1_preg_i(dispatch1_src1_preg),
    .dispatch1_src1_ready_i(dispatch1_src1_ready),
    .dispatch1_src2_preg_i(dispatch1_src2_preg),
    .dispatch1_src2_ready_i(dispatch1_src2_ready),
    .dispatch1_pdest_i(dispatch1_pdest),
    .dispatch1_fp_pdest_i(1'b0),
    .dispatch1_fp_st_src_en_i(1'b0),
    .dispatch1_fp_st_src_preg_i('0),
    .dispatch1_fp_st_src_ready_i(1'b1),
    .dispatch1_imm_i(dispatch1_imm),
    .wakeup0_valid_i(wakeup0_valid),
    .wakeup0_pdest_i(wakeup0_pdest),
    .wakeup1_valid_i(wakeup1_valid),
    .wakeup1_pdest_i(wakeup1_pdest),
    .fp_wake0_valid_i(1'b0),
    .fp_wake0_preg_i('0),
    .fp_wake1_valid_i(1'b0),
    .fp_wake1_preg_i('0),
    .pending_load0_valid_i(pending_load0_valid),
    .pending_load0_pdest_i(pending_load0_pdest),
    .pending_load1_valid_i(pending_load1_valid),
    .pending_load1_pdest_i(pending_load1_pdest),
    .issue0_valid_o(issue0_valid),
    .issue0_ready_i(issue0_ready),
    .issue0_pc_o(issue0_pc),
    .issue0_next_pc_o(issue0_next_pc),
    .issue0_inst_o(issue0_inst),
    .issue0_ctrl_o(issue0_ctrl),
    .issue0_rob_idx_o(issue0_rob_idx),
    .issue0_src1_preg_o(issue0_src1_preg),
    .issue0_src2_preg_o(issue0_src2_preg),
    .issue0_pdest_o(issue0_pdest),
    .issue0_imm_o(issue0_imm),
    .issue1_valid_o(issue1_valid),
    .issue1_ready_i(issue1_ready),
    .issue1_pc_o(issue1_pc),
    .issue1_next_pc_o(issue1_next_pc),
    .issue1_inst_o(issue1_inst),
    .issue1_ctrl_o(issue1_ctrl),
    .issue1_rob_idx_o(issue1_rob_idx),
    .issue1_src1_preg_o(issue1_src1_preg),
    .issue1_src2_preg_o(issue1_src2_preg),
    .issue1_pdest_o(issue1_pdest),
    .issue1_imm_o(issue1_imm),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
    .pending_load_branch_dep_o(pending_load_branch_dep),
    .load_branch_fast_valid_o(load_branch_fast_valid),
    .load_branch_fast_rob_idx_o(load_branch_fast_rob_idx),
    .load_branch_fast_pc_o(load_branch_fast_pc),
    .load_branch_fast_next_pc_o(load_branch_fast_next_pc),
    .load_branch_fast_imm_o(load_branch_fast_imm),
    .load_branch_fast_cmp_op_o(load_branch_fast_cmp_op),
    .load_branch_fast_src1_preg_o(load_branch_fast_src1_preg),
    .load_branch_fast_src2_preg_o(load_branch_fast_src2_preg),
    .load_branch_fast_wait_load0_o(load_branch_fast_wait_load0),
    .load_branch_fast_wait_load1_o(load_branch_fast_wait_load1),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .rob_head_idx_i(rob_head_idx),
    .recover_active_i(recover_active)
  );

  wire unused_next_pc_w = (|issue0_next_pc) | (|issue1_next_pc) |
                          pending_load_branch_dep |
                          load_branch_fast_valid |
                          (|load_branch_fast_rob_idx) |
                          (|load_branch_fast_pc) |
                          (|load_branch_fast_next_pc) |
                          (|load_branch_fast_imm) |
                          (|load_branch_fast_cmp_op) |
                          (|load_branch_fast_src1_preg) |
                          (|load_branch_fast_src2_preg) |
                          load_branch_fast_wait_load0 |
                          load_branch_fast_wait_load1;

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      checkpoint_capture = 1'b0;
      checkpoint_restore = 1'b0;
      issue_mem_block = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_rob_idx = 4'd0;
      dispatch0_src1_preg = 6'd0;
      dispatch0_src1_ready = 1'b0;
      dispatch0_src2_preg = 6'd0;
      dispatch0_src2_ready = 1'b0;
      dispatch0_pdest = 6'd0;
      dispatch0_imm = 32'h0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_optional = 1'b0;
      dispatch1_rob_idx = 4'd0;
      dispatch1_src1_preg = 6'd0;
      dispatch1_src1_ready = 1'b0;
      dispatch1_src2_preg = 6'd0;
      dispatch1_src2_ready = 1'b0;
      dispatch1_pdest = 6'd0;
      dispatch1_imm = 32'h0;
      wakeup0_valid = 1'b0;
      wakeup0_pdest = 6'd0;
      wakeup1_valid = 1'b0;
      wakeup1_pdest = 6'd0;
      pending_load0_valid = 1'b0;
      pending_load0_pdest = 6'd0;
      pending_load1_valid = 1'b0;
      pending_load1_pdest = 6'd0;
      kill_valid = 1'b0;
      kill_rob_idx = 4'd0;
      rob_head_idx = 4'd0;
      recover_active = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      issue0_ready = 1'b1;
      issue1_ready = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic set_dispatch0;
    input [`XLEN-1:0] pc;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] src1;
    input src1_ready;
    input [PHY_REG_ADDR_W-1:0] src2;
    input src2_ready;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = pc;
      dispatch0_inst = pc;
      dispatch0_ctrl = {{(`CTRL_BUS_W-1){1'b0}}, 1'b1};
      dispatch0_rob_idx = rob_idx;
      dispatch0_src1_preg = src1;
      dispatch0_src1_ready = src1_ready;
      dispatch0_src2_preg = src2;
      dispatch0_src2_ready = src2_ready;
      dispatch0_pdest = pdest;
      dispatch0_imm = pc + 32'h10;
    end
  endtask

  task automatic set_dispatch1;
    input [`XLEN-1:0] pc;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] src1;
    input src1_ready;
    input [PHY_REG_ADDR_W-1:0] src2;
    input src2_ready;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      dispatch1_valid = 1'b1;
      dispatch1_pc = pc;
      dispatch1_inst = pc;
      dispatch1_ctrl = {{(`CTRL_BUS_W-1){1'b0}}, 1'b1};
      dispatch1_rob_idx = rob_idx;
      dispatch1_src1_preg = src1;
      dispatch1_src1_ready = src1_ready;
      dispatch1_src2_preg = src2;
      dispatch1_src2_ready = src2_ready;
      dispatch1_pdest = pdest;
      dispatch1_imm = pc + 32'h20;
    end
  endtask

  function [`INST_W-1:0] inst_op;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_op = {funct7, rs2, rs1, funct3, rd, `OPCODE_OP};
    end
  endfunction

  task automatic mark_clmul0;
    begin
      dispatch0_ctrl[`CTRL_BITMANIP_BIT] = 1'b1;
      dispatch0_inst = inst_op(7'h05, 5'd2, 5'd1, `FUNCT3_SLL, 5'd3);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();
    tb_check1("reset empty", empty, 1'b1);

    set_dispatch0(32'h8000_0000, 4'd0, 6'd1, 1'b1, 6'd2, 1'b1, 6'd32);
    set_dispatch1(32'h8000_0004, 4'd1, 6'd5, 1'b0, 6'd3, 1'b1, 6'd33);
    #1;
    tb_check1("dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dispatch1 ready", dispatch1_ready, 1'b1);
    tb_check1("dispatch bypass issues ready lane0", issue0_valid, 1'b1);
    tb_check32("dispatch bypass lane0 pc", issue0_pc, 32'h8000_0000);
    tb_check1("dispatch bypass keeps waiting lane1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("only waiting lane remains after bypass", {28'b0, count}, 32'd1);
    tb_check1("waiting lane not ready yet", issue0_valid, 1'b0);

    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd5;
    #1;
    tb_check1("wakeup makes waiting uop issuable", issue0_valid, 1'b1);
    tb_check32("wakeup issue pc", issue0_pc, 32'h8000_0004);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after wakeup issue", empty, 1'b1);

    set_dispatch0(32'h8000_0008, 4'd8, 6'd1, 1'b1, 6'd2, 1'b1, 6'd40);
    mark_clmul0();
    set_dispatch1(32'h8000_000c, 4'd9, 6'd40, 1'b0, 6'd0, 1'b1, 6'd41);
    #1;
    tb_check1("clmul can issue when operands ready", issue0_valid, 1'b1);
    tb_check1("clmul cannot forward to dependent lane1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("clmul dependent waits in iq", {28'b0, count}, 32'd1);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd40;
    #1;
    tb_check1("clmul wakeup releases dependent", issue0_valid, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after clmul dependent wakeup", empty, 1'b1);

    set_dispatch0(32'h8000_0010, 4'd2, 6'd1, 1'b1, 6'd2, 1'b1, 6'd34);
    set_dispatch1(32'h8000_0014, 4'd3, 6'd3, 1'b1, 6'd4, 1'b1, 6'd35);
    #1;
    tb_check1("dual dispatch bypass issue0 valid", issue0_valid, 1'b1);
    tb_check1("dual dispatch bypass issue1 valid", issue1_valid, 1'b1);
    tb_check32("dual dispatch bypass issue0 pc", issue0_pc, 32'h8000_0010);
    tb_check32("dual dispatch bypass issue1 pc", issue1_pc, 32'h8000_0014);
    `TB_TICK(clk);
    clear_inputs();
    #1;
	    tb_check1("empty after dual dispatch bypass", empty, 1'b1);

    // ===== mode=0 专有：control-flow（branch/JAL）dispatch-bypass 契约 =====
    // mode=1（OOO_ROB_WALK_MODE）设计性禁用控制流 dispatch-bypass，强制经 IQ 寄存项发射，
    // 以打破 pred_npc→mispredict→redirect→预测后继 组合环；该语义由 riscv-tests 135/0 端到端覆盖。
    if (!`OOO_ROB_WALK_MODE) begin
    set_dispatch0(32'h8000_0018, 4'd13, 6'd1, 1'b1, 6'd2, 1'b1, 6'd45);
    set_dispatch1(32'h8000_001c, 4'd14, 6'd3, 1'b1, 6'd4, 1'b1, 6'd0);
    dispatch1_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
    #1;
    tb_check1("lane1 branch bypass issue0 valid", issue0_valid, 1'b1);
    tb_check1("lane1 branch bypass issue1 valid", issue1_valid, 1'b1);
    tb_check32("lane1 branch bypass issue1 pc", issue1_pc, 32'h8000_001c);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after lane1 branch bypass", empty, 1'b1);

    set_dispatch0(32'h8000_0064, 4'd1, 6'd1, 1'b1, 6'd2, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
    set_dispatch1(32'h8000_0068, 4'd2, 6'd3, 1'b1, 6'd4, 1'b1, 6'd53);
    dispatch1_optional = 1'b1;
    #1;
    tb_check1("optional lane1 behind branch issue0 valid", issue0_valid,
              1'b1);
    tb_check1("optional lane1 behind branch issue1 valid", issue1_valid,
              1'b1);
    tb_check32("optional lane1 behind branch issue1 pc", issue1_pc,
               32'h8000_0068);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after optional lane1 branch pair", empty, 1'b1);

    set_dispatch0(32'h8000_006c, 4'd3, 6'd1, 1'b1, 6'd2, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
    set_dispatch1(32'h8000_0070, 4'd4, 6'd3, 1'b1, 6'd0, 1'b1, 6'd54);
    dispatch1_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    dispatch1_optional = 1'b1;
    #1;
    tb_check1("optional lane1 load behind branch issue0 valid", issue0_valid,
              1'b1);
    tb_check1("optional lane1 load behind branch issue1 valid", issue1_valid,
              1'b1);
    tb_check32("optional lane1 load behind branch issue1 pc", issue1_pc,
               32'h8000_0070);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after optional lane1 load branch pair", empty, 1'b1);

    set_dispatch0(32'h8000_0038, 4'd15, 6'd1, 1'b1, 6'd2, 1'b1, 6'd46);
    set_dispatch1(32'h8000_003c, 4'd0, 6'd3, 1'b1, 6'd4, 1'b1, 6'd47);
    dispatch1_ctrl[`CTRL_JAL_BIT] = 1'b1;
    #1;
    tb_check1("lane1 jal bypass issue0 valid", issue0_valid, 1'b1);
    tb_check1("lane1 jal bypass issue1 valid", issue1_valid, 1'b1);
    tb_check32("lane1 jal bypass issue1 pc", issue1_pc, 32'h8000_003c);
    `TB_TICK(clk);
    clear_inputs();
    #1;
	    tb_check1("empty after lane1 jal bypass", empty, 1'b1);

    set_dispatch0(32'h8000_0060, 4'd0, 6'd0, 1'b1, 6'd0, 1'b1, 6'd52);
    dispatch0_ctrl[`CTRL_JAL_BIT] = 1'b1;
    #1;
    tb_check1("lane0 jal bypass issue0 valid", issue0_valid, 1'b1);
    tb_check1("lane0 jal bypass keeps issue1 idle", issue1_valid, 1'b0);
    tb_check32("lane0 jal bypass issue0 pc", issue0_pc, 32'h8000_0060);
    `TB_TICK(clk);
    clear_inputs();
    #1;
	    tb_check1("empty after lane0 jal bypass", empty, 1'b1);

    issue0_ready = 1'b0;
    set_dispatch0(32'h8000_0040, 4'd1, 6'd1, 1'b1, 6'd2, 1'b1, 6'd48);
    `TB_TICK(clk);
    clear_inputs();
    issue0_ready = 1'b1;
    set_dispatch0(32'h8000_0044, 4'd2, 6'd0, 1'b1, 6'd0, 1'b1, 6'd49);
    dispatch0_ctrl[`CTRL_JAL_BIT] = 1'b1;
    #1;
    tb_check1("lane0 jal issue1 bypass issue0 valid", issue0_valid, 1'b1);
    tb_check1("lane0 jal issue1 bypass issue1 valid", issue1_valid, 1'b1);
    tb_check32("lane0 jal issue1 bypass older pc", issue0_pc, 32'h8000_0040);
    tb_check32("lane0 jal issue1 bypass jal pc", issue1_pc, 32'h8000_0044);
    `TB_TICK(clk);
    clear_inputs();
    #1;
	    tb_check1("empty after lane0 jal issue1 bypass", empty, 1'b1);
    end // if (!`OOO_ROB_WALK_MODE)：control-flow dispatch-bypass 为 mode=0 专有契约

	    set_dispatch0(32'h8000_0048, 4'd3, 6'd20, 1'b0, 6'd0, 1'b1, 6'd50);
	    `TB_TICK(clk);
	    clear_inputs();
	    #1;
	    tb_check32("unready entry queued before dispatch bypass", {28'b0, count},
	               32'd1);
	    tb_check1("unready entry blocks issue", issue0_valid, 1'b0);
	    set_dispatch0(32'h8000_004c, 4'd4, 6'd1, 1'b1, 6'd2, 1'b1, 6'd51);
	    #1;
	    tb_check1("dispatch bypass beside unready entry valid", issue0_valid,
	              1'b1);
	    tb_check32("dispatch bypass beside unready entry pc", issue0_pc,
	               32'h8000_004c);
	    `TB_TICK(clk);
	    clear_inputs();
	    #1;
	    tb_check32("dispatch bypass preserves unready queue entry",
	               {28'b0, count}, 32'd1);
	    tb_check1("preserved unready entry still waits", issue0_valid, 1'b0);
	    wakeup0_valid = 1'b1;
	    wakeup0_pdest = 6'd20;
	    #1;
	    tb_check1("preserved entry wakes", issue0_valid, 1'b1);
	    tb_check32("preserved entry issue pc", issue0_pc, 32'h8000_0048);
	    `TB_TICK(clk);
	    clear_inputs();
	    #1;
	    tb_check1("preserved entry drains", empty, 1'b1);

	    set_dispatch0(32'h8000_0020, 4'd4, 6'd1, 1'b1, 6'd2, 1'b1, 6'd36);
	    set_dispatch1(32'h8000_0024, 4'd5, 6'd3, 1'b1, 6'd4, 1'b1, 6'd37);
    issue0_ready = 1'b0;
    issue1_ready = 1'b1;
    #1;
    tb_check1("dispatch bypass respects issue0 backpressure", issue0_valid, 1'b1);
    tb_check1("independent issue1 bypass under issue0 backpressure",
              issue1_valid, 1'b1);
    tb_check32("independent issue1 bypass pc", issue1_pc, 32'h8000_0024);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("backpressure keeps lane0 entry", {28'b0, count}, 32'd1);
    issue0_ready = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("entries drain after ready", empty, 1'b1);

    issue0_ready = 1'b0;
    issue1_ready = 1'b0;
    set_dispatch0(32'h8000_0028, 4'd10, 6'd1, 1'b1, 6'd2, 1'b1, 6'd42);
    dispatch0_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    set_dispatch1(32'h8000_002c, 4'd11, 6'd3, 1'b1, 6'd4, 1'b1, 6'd43);
    dispatch1_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    set_dispatch0(32'h8000_0034, 4'd12, 6'd5, 1'b1, 6'd6, 1'b1, 6'd44);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("dual load setup count", {28'b0, count}, 32'd3);
    issue0_ready = 1'b1;
    issue1_ready = 1'b1;
    #1;
    tb_check1("dual load issue0 valid", issue0_valid, 1'b1);
	    tb_check1("dual load issue1 valid", issue1_valid, 1'b1);
	    tb_check32("dual load issue0 oldest load", issue0_pc, 32'h8000_0028);
	    tb_check32("dual load issue1 second load", issue1_pc, 32'h8000_002c);
	    `TB_TICK(clk);
	    #1;
	    tb_check32("dual load leaves later alu", {28'b0, count}, 32'd1);
	    tb_check32("dual load remaining pc", issue0_pc, 32'h8000_0034);
    `TB_TICK(clk);
    #1;
    tb_check1("dual load drains", empty, 1'b1);

    set_dispatch0(32'h8000_0030, 4'd6, 6'd9, 1'b0, 6'd0, 1'b1, 6'd38);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd9;
    #1;
    tb_check1("dispatch bypass sees same-cycle wakeup", issue0_valid, 1'b1);
    tb_check32("same-cycle wakeup bypass pc", issue0_pc, 32'h8000_0030);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("same-cycle wakeup bypass drains", empty, 1'b1);

    clear_inputs();
    issue0_ready = 1'b0;
    issue1_ready = 1'b1;
    set_dispatch0(32'h8000_0050, 4'd8, 6'd1, 1'b1, 6'd2, 1'b1, 6'd40);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("checkpoint source count", {28'b0, count}, 32'd1);
    tb_check32("checkpoint source issue pc", issue0_pc, 32'h8000_0050);
    checkpoint_capture = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    issue1_ready = 1'b0;
    set_dispatch0(32'h8000_0054, 4'd9, 6'd3, 1'b1, 6'd4, 1'b1, 6'd41);
    `TB_TICK(clk);
    clear_inputs();
    issue1_ready = 1'b1;
    #1;
    tb_check32("checkpoint mutation count", {28'b0, count}, 32'd2);
    checkpoint_restore = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("checkpoint restore count", {28'b0, count}, 32'd1);
    tb_check32("checkpoint restore issue pc", issue0_pc, 32'h8000_0050);
    issue0_ready = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("checkpoint restored entry drains", empty, 1'b1);

    set_dispatch0(32'h8000_0040, 4'd7, 6'd1, 1'b1, 6'd2, 1'b1, 6'd39);
    `TB_TICK(clk);
    clear_inputs();
    flush = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("flush empties queue", empty, 1'b1);

    tb_finish("tb_ooo_int_issue_queue");
  end
endmodule
