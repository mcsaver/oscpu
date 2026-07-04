`include "define.v"

module tb_ooo_dispatch_backend;
  `include "tb_common.svh"

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
  reg [`CTRL_BUS_W-1:0] dispatch0_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch0_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rd_arch;
  reg [`XLEN-1:0] dispatch0_imm;

  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg [`CTRL_BUS_W-1:0] dispatch1_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch1_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rd_arch;
  reg [`XLEN-1:0] dispatch1_imm;

  reg wb0_valid;
  reg [ROB_INDEX_W-1:0] wb0_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] wb0_pdest;
  reg [`XLEN-1:0] wb0_data;
  reg wb0_exception;
  reg [`TRAP_CAUSE_W-1:0] wb0_cause;
  reg [`XLEN-1:0] wb0_tval;

  reg wb1_valid;
  reg [ROB_INDEX_W-1:0] wb1_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] wb1_pdest;
  reg [`XLEN-1:0] wb1_data;
  reg wb1_exception;
  reg [`TRAP_CAUSE_W-1:0] wb1_cause;
  reg [`XLEN-1:0] wb1_tval;

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

  OooDispatchBackend dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .sq_alloc0_ready_i(1'b1),
    .sq_alloc1_ready_i(1'b1),
    .branch_mispredict_valid_i(1'b0),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_ctrl_i(dispatch0_ctrl),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch),
    .dispatch0_rd_arch_i(dispatch0_rd_arch),
    .dispatch0_is_fp_rd_i(1'b0),
    .dispatch0_is_fp_i(1'b0),
    .dispatch0_fp_pdest_i('0),
    .dispatch0_fp_old_pdest_i('0),
    .dispatch0_fp_st_src_en_i(1'b0),
    .dispatch0_fp_st_src_preg_i('0),
    .dispatch0_fp_st_src_ready_i(1'b1),
    .dispatch0_imm_i(dispatch0_imm),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(1'b0),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i('0),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_ctrl_i(dispatch1_ctrl),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch),
    .dispatch1_rd_arch_i(dispatch1_rd_arch),
    .dispatch1_is_fp_rd_i(1'b0),
    .dispatch1_is_fp_i(1'b0),
    .dispatch1_fp_pdest_i('0),
    .dispatch1_fp_old_pdest_i('0),
    .dispatch1_fp_st_src_en_i(1'b0),
    .dispatch1_fp_st_src_preg_i('0),
    .dispatch1_fp_st_src_ready_i(1'b1),
    .fp_wake0_valid_i(1'b0),
    .fp_wake0_preg_i('0),
    .fp_wake1_valid_i(1'b0),
    .fp_wake1_preg_i('0),
    .dispatch1_imm_i(dispatch1_imm),
    .wb0_valid_i(wb0_valid),
    .wb0_rob_idx_i(wb0_rob_idx),
    .wb0_pdest_i(wb0_pdest),
    .wb0_data_i(wb0_data),
    .wb0_exception_i(wb0_exception),
    .wb0_cause_i(wb0_cause),
    .wb0_tval_i(wb0_tval),
    .wb0_fflags_i(5'b00000),
    .wb1_valid_i(wb1_valid),
    .wb1_rob_idx_i(wb1_rob_idx),
    .wb1_pdest_i(wb1_pdest),
    .wb1_data_i(wb1_data),
    .wb1_exception_i(wb1_exception),
    .wb1_cause_i(wb1_cause),
    .wb1_tval_i(wb1_tval),
    .wb1_fflags_i(5'b00000),
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
    .issue_count_o(issue_count)
  );

  wire unused_next_pc_w =
      (|issue0_next_pc) | (|issue1_next_pc) |
      (|commit0_next_pc) | (|commit1_next_pc);

  function [`CTRL_BUS_W-1:0] make_ctrl;
    input rs1_en;
    input rs2_en;
    input rd_en;
    begin
      make_ctrl = {`CTRL_BUS_W{1'b0}};
      make_ctrl[`CTRL_VALID_BIT] = 1'b1;
      make_ctrl[`CTRL_RS1_EN_BIT] = rs1_en;
      make_ctrl[`CTRL_RS2_EN_BIT] = rs2_en;
      make_ctrl[`CTRL_RD_EN_BIT] = rd_en;
      make_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      make_ctrl[`CTRL_NEED_WB_BIT] = rd_en;
      make_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = rd_en ? `WB_SEL_ALU : `WB_SEL_NONE;
    end
  endfunction

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_rs1_arch = 5'd0;
      dispatch0_rs2_arch = 5'd0;
      dispatch0_rd_arch = 5'd0;
      dispatch0_imm = 32'h0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_rs1_arch = 5'd0;
      dispatch1_rs2_arch = 5'd0;
      dispatch1_rd_arch = 5'd0;
      dispatch1_imm = 32'h0;
      wb0_valid = 1'b0;
      wb0_rob_idx = 4'd0;
      wb0_pdest = 6'd0;
      wb0_data = 32'h0;
      wb0_exception = 1'b0;
      wb0_cause = {`TRAP_CAUSE_W{1'b0}};
      wb0_tval = 32'h0;
      wb1_valid = 1'b0;
      wb1_rob_idx = 4'd0;
      wb1_pdest = 6'd0;
      wb1_data = 32'h0;
      wb1_exception = 1'b0;
      wb1_cause = {`TRAP_CAUSE_W{1'b0}};
      wb1_tval = 32'h0;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      issue0_ready = 1'b1;
      issue1_ready = 1'b1;
      commit_ready = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic set_dispatch0;
    input [`XLEN-1:0] pc;
    input [`REG_ADDR_W-1:0] rs1;
    input rs1_en;
    input [`REG_ADDR_W-1:0] rs2;
    input rs2_en;
    input [`REG_ADDR_W-1:0] rd;
    input rd_en;
    begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = pc;
      dispatch0_inst = pc;
      dispatch0_ctrl = make_ctrl(rs1_en, rs2_en, rd_en);
      dispatch0_rs1_arch = rs1;
      dispatch0_rs2_arch = rs2;
      dispatch0_rd_arch = rd;
      dispatch0_imm = pc + 32'h10;
    end
  endtask

  task automatic set_dispatch1;
    input [`XLEN-1:0] pc;
    input [`REG_ADDR_W-1:0] rs1;
    input rs1_en;
    input [`REG_ADDR_W-1:0] rs2;
    input rs2_en;
    input [`REG_ADDR_W-1:0] rd;
    input rd_en;
    begin
      dispatch1_valid = 1'b1;
      dispatch1_pc = pc;
      dispatch1_inst = pc;
      dispatch1_ctrl = make_ctrl(rs1_en, rs2_en, rd_en);
      dispatch1_rs1_arch = rs1;
      dispatch1_rs2_arch = rs2;
      dispatch1_rd_arch = rd;
      dispatch1_imm = pc + 32'h20;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check32("initial freelist count", {25'b0, free_count}, 32'd32);
    tb_check32("initial rob count", {27'b0, rob_count}, 32'd0);
    tb_check32("initial issue count", {28'b0, issue_count}, 32'd0);

    set_dispatch0(32'h8000_0000, 5'd1, 1'b1, 5'd2, 1'b1, 5'd5, 1'b1);
    set_dispatch1(32'h8000_0004, 5'd5, 1'b1, 5'd3, 1'b1, 5'd6, 1'b1);
    #1;
    tb_check1("dual dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dual dispatch1 ready", dispatch1_ready, 1'b1);
    tb_check1("dispatch bypass older independent uop", issue0_valid, 1'b1);
    tb_check32("dispatch bypass older issue pc", issue0_pc, 32'h8000_0000);
    tb_check32("dispatch bypass older issue rob", {28'b0, issue0_rob_idx}, 32'd0);
    tb_check32("dispatch bypass older src1 preg", {26'b0, issue0_src1_preg}, 32'd1);
    tb_check32("dispatch bypass older src2 preg", {26'b0, issue0_src2_preg}, 32'd2);
    tb_check32("dispatch bypass older pdest", {26'b0, issue0_pdest}, 32'd32);
    tb_check1("dispatch bypass younger uses lane0 forward", issue1_valid, 1'b1);
    tb_check32("dispatch bypass younger issue pc", issue1_pc, 32'h8000_0004);
    tb_check32("dispatch bypass younger source sees lane0 pdest", {26'b0, issue1_src1_preg}, 32'd32);
    tb_check32("dispatch bypass younger pdest", {26'b0, issue1_pdest}, 32'd33);
    `TB_TICK(clk);
    clear_inputs();
    #1;

    tb_check32("two physical regs allocated", {25'b0, free_count}, 32'd30);
    tb_check32("two rob entries allocated", {27'b0, rob_count}, 32'd2);
    tb_check32("dependent uop issued via forward", {28'b0, issue_count}, 32'd0);

    wb0_valid = 1'b1;
    wb0_rob_idx = 4'd0;
    wb0_pdest = 6'd32;
    wb0_data = 32'h1111_0005;
    #1;
    tb_check1("lane0 commit becomes valid via wb bypass", commit0_valid, 1'b1);
    tb_check32("lane0 commit old pdest via wb bypass", {26'b0, commit0_old_pdest}, 32'd5);
    tb_check32("lane0 commit new pdest via wb bypass", {26'b0, commit0_new_pdest}, 32'd32);
    tb_check32("lane0 commit data via wb bypass", commit0_data, 32'h1111_0005);
    `TB_TICK(clk);
    clear_inputs();

    wb1_valid = 1'b1;
    wb1_rob_idx = 4'd1;
    wb1_pdest = 6'd33;
    wb1_data = 32'h2222_0006;
    #1;
    tb_check1("lane1 commit becomes valid via wb bypass", commit0_valid, 1'b1);
    tb_check32("lane1 commit old pdest via wb bypass", {26'b0, commit0_old_pdest}, 32'd6);
    tb_check32("lane1 commit new pdest via wb bypass", {26'b0, commit0_new_pdest}, 32'd33);
    tb_check32("lane1 commit data via wb bypass", commit0_data, 32'h2222_0006);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("freelist recovers after two commits", {25'b0, free_count}, 32'd32);
    tb_check32("rob drains after two commits", {27'b0, rob_count}, 32'd0);
    tb_check32("issue queue drains after dependent issue", {28'b0, issue_count}, 32'd0);

    set_dispatch0(32'h8000_0010, 5'd1, 1'b1, 5'd2, 1'b1, 5'd7, 1'b1);
    set_dispatch1(32'h8000_0014, 5'd3, 1'b1, 5'd4, 1'b1, 5'd7, 1'b1);
    #1;
    tb_check1("waw older dispatch bypass valid", issue0_valid, 1'b1);
    tb_check1("waw younger dispatch bypass valid", issue1_valid, 1'b1);
    tb_check32("waw older dispatch bypass pc", issue0_pc, 32'h8000_0010);
    tb_check32("waw younger dispatch bypass pc", issue1_pc, 32'h8000_0014);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("waw dispatch bypass leaves issue queue empty",
               {28'b0, issue_count}, 32'd0);

    wb0_valid = 1'b1;
    wb0_rob_idx = 4'd2;
    wb0_pdest = 6'd34;
    wb0_data = 32'haaaa_0007;
    wb1_valid = 1'b1;
    wb1_rob_idx = 4'd3;
    wb1_pdest = 6'd35;
    wb1_data = 32'hbbbb_0007;
    #1;
    tb_check1("waw commit0 valid via wb bypass", commit0_valid, 1'b1);
    tb_check1("waw commit1 valid via wb bypass", commit1_valid, 1'b1);
    tb_check32("waw older frees original x7 via wb bypass", {26'b0, commit0_old_pdest}, 32'd7);
    tb_check32("waw younger frees lane0 pdest via wb bypass", {26'b0, commit1_old_pdest}, 32'd34);
    tb_check32("waw older new pdest via wb bypass", {26'b0, commit0_new_pdest}, 32'd34);
    tb_check32("waw younger new pdest via wb bypass", {26'b0, commit1_new_pdest}, 32'd35);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("freelist recovers after waw commits", {25'b0, free_count}, 32'd32);
    tb_check32("rob drains after waw", {27'b0, rob_count}, 32'd0);

    // weak checkpoint capture/restore 场景已删（mode=0 专有恢复机制，dead silicon）；
    // mode=1 误预测恢复改用 ROB-walk reverse-undo（见 tb_ooo_rob 的 walk 测试），
    // 端到端由 riscv-tests 135/0 覆盖。此处仅保持 issue_ready，交给后续 flush 测试。
    issue0_ready = 1'b1;
    issue1_ready = 1'b1;

    set_dispatch0(32'h8000_0020, 5'd1, 1'b1, 5'd2, 1'b1, 5'd8, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    flush = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("flush restores freelist", {25'b0, free_count}, 32'd32);
    tb_check32("flush clears rob", {27'b0, rob_count}, 32'd0);
    tb_check32("flush clears issue queue", {28'b0, issue_count}, 32'd0);

    tb_finish("tb_ooo_dispatch_backend");
  end
endmodule
