`include "define.v"

module tb_ooo_dispatch_backend;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam FREE_COUNT_W = 7;
  localparam ISSUE_COUNT_W = 4;
  localparam PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W;

  reg clk;
  reg rst;
  reg flush;
  reg branch_mispredict_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;

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

  reg completion0_query_valid;
  reg [PRODUCER_ID_W-1:0] completion0_query_producer_id;
  wire completion0_query_match;
  reg completion1_query_valid;
  reg [PRODUCER_ID_W-1:0] completion1_query_producer_id;
  wire completion1_query_match;

  wire issue0_valid;
  reg issue0_ready;
  wire [`XLEN-1:0] issue0_pc;
  wire [`XLEN-1:0] issue0_next_pc;
  wire [`INST_W-1:0] issue0_inst;
  wire [`CTRL_BUS_W-1:0] issue0_ctrl;
  wire [ROB_INDEX_W-1:0] issue0_rob_idx;
  wire [PRODUCER_ID_W-1:0] issue0_producer_id;
  wire issue0_producer_current;
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
  wire [PRODUCER_ID_W-1:0] issue1_producer_id;
  wire issue1_producer_current;
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
  wire rob_recover_active;

  OooDispatchBackend dut (
    .clk(clk),
    .rst(rst),
    .head0_context_permit_i(1'b1),
    .fencei_retire_permit_i(1'b1),
    .head0_retire_candidate_valid_o(),
    .head0_identity_valid_o(),
    .head0_identity_o(),
    .flush_i(flush),
    .kill_rob_idx_i(kill_rob_idx),
    .issue_mem_block_i(1'b0),
    .universal_owner_present_i(1'b0),
    .sq_alloc0_ready_i(1'b1),
    .sq_alloc1_ready_i(1'b1),
    .branch_mispredict_valid_i(branch_mispredict_valid),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_bht_idx_i({`BPU_BHT_INDEX_W{1'b0}}),
    .dispatch0_pred_taken_i(1'b0),
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
    .dispatch1_bht_idx_i({`BPU_BHT_INDEX_W{1'b0}}),
    .dispatch1_pred_taken_i(1'b0),
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
    .completion0_query_valid_i(completion0_query_valid),
    .completion0_query_producer_id_i(completion0_query_producer_id),
    .completion0_query_match_o(completion0_query_match),
    .completion1_query_valid_i(completion1_query_valid),
    .completion1_query_producer_id_i(completion1_query_producer_id),
    .completion1_query_match_o(completion1_query_match),
    .early_wakeup0_valid_i(1'b0),
    .early_wakeup0_pdest_i({PHY_REG_ADDR_W{1'b0}}),
    .early_wakeup1_valid_i(1'b0),
    .early_wakeup1_pdest_i({PHY_REG_ADDR_W{1'b0}}),
    .issue0_valid_o(issue0_valid),
    .issue0_ready_i(issue0_ready),
    .issue0_pc_o(issue0_pc),
    .issue0_next_pc_o(issue0_next_pc),
    .issue0_inst_o(issue0_inst),
    .issue0_ctrl_o(issue0_ctrl),
    .issue0_rob_idx_o(issue0_rob_idx),
    .issue0_producer_id_o(issue0_producer_id),
    .issue0_producer_current_o(issue0_producer_current),
    .issue0_src1_preg_o(issue0_src1_preg),
    .issue0_src2_preg_o(issue0_src2_preg),
    .issue0_pdest_o(issue0_pdest),
    .issue0_fixed_gpr_producer_o(),
    .issue0_imm_o(issue0_imm),
    .issue_pair_swapped_o(),
    .issue1_valid_o(issue1_valid),
    .issue1_ready_i(issue1_ready),
    .issue1_pc_o(issue1_pc),
    .issue1_next_pc_o(issue1_next_pc),
    .issue1_inst_o(issue1_inst),
    .issue1_ctrl_o(issue1_ctrl),
    .issue1_rob_idx_o(issue1_rob_idx),
    .issue1_producer_id_o(issue1_producer_id),
    .issue1_producer_current_o(issue1_producer_current),
    .issue1_src1_preg_o(issue1_src1_preg),
    .issue1_src2_preg_o(issue1_src2_preg),
    .issue1_pdest_o(issue1_pdest),
    .issue1_fixed_gpr_producer_o(),
    .issue1_imm_o(issue1_imm),
    .commit_ready_i(commit_ready),
    .commit1_block_i(1'b0),
    .mem_quiet_i(1'b1),
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
    .rob_recover_active_o(rob_recover_active)
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
      branch_mispredict_valid = 1'b0;
      kill_rob_idx = {ROB_INDEX_W{1'b0}};
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
      completion0_query_valid = 1'b0;
      completion0_query_producer_id = {PRODUCER_ID_W{1'b0}};
      completion1_query_valid = 1'b0;
      completion1_query_producer_id = {PRODUCER_ID_W{1'b0}};
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
      dispatch0_valid = 1'b1;
      dispatch1_valid = 1'b1;
      #1;
      tb_check1("v8e dispatch parent reset blocks lane0", dispatch0_ready,
                1'b0);
      tb_check1("v8e dispatch parent reset blocks lane1", dispatch1_ready,
                1'b0);
      `TB_TICK(clk);
      clear_inputs();
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

  // v8f bridge check: ROB-created ProducerId must reach both IQ issue ports;
  // current and completion-open decisions are then returned through distinct
  // query channels without entering issue READY.
  task automatic run_v8f_query_bridge;
    reg [PRODUCER_ID_W-1:0] id0;
    reg [PRODUCER_ID_W-1:0] id1;
    reg [PRODUCER_ID_W-1:0] wrong0;
    reg [PRODUCER_ID_W-1:0] wrong1;
    reg [PHY_REG_ADDR_W-1:0] pdest0;
    begin
      reset_dut();
      commit_ready = 1'b0;
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      set_dispatch0(32'h8000_1300,
                    5'd1, 1'b1, 5'd2, 1'b1, 5'd20, 1'b1);
      set_dispatch1(32'h8000_1304,
                    5'd3, 1'b1, 5'd4, 1'b1, 5'd21, 1'b1);
      #1;
      id0 = dut.rob_dispatch0_producer_id_w;
      id1 = dut.rob_dispatch1_producer_id_w;
      `TB_TICK(clk);
      clear_inputs();
      #1;
      pdest0 = issue0_pdest;
      tb_check1("v8f bridge issue0 resident", issue0_valid, 1'b1);
      tb_check1("v8f bridge issue1 resident", issue1_valid, 1'b1);
      tb_check32("v8f bridge issue0 carries ROB id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id0});
      tb_check32("v8f bridge issue1 carries ROB id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue1_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id1});
      tb_check1("v8f bridge issue0 current", issue0_producer_current, 1'b1);
      tb_check1("v8f bridge issue1 current", issue1_producer_current, 1'b1);

      wrong0 = id0;
      wrong0[ROB_INDEX_W] = ~id0[ROB_INDEX_W];
      wrong1 = id1;
      wrong1[ROB_INDEX_W] = ~id1[ROB_INDEX_W];
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id0;
      completion1_query_valid = 1'b1;
      completion1_query_producer_id = wrong1;
      #1;
      tb_check1("v8f bridge query0 exact open",
                completion0_query_match, 1'b1);
      tb_check1("v8f bridge query1 wrong generation closed",
                completion1_query_match, 1'b0);
      completion0_query_producer_id = wrong0;
      completion1_query_producer_id = id1;
      #1;
      tb_check1("v8f bridge query0 wrong generation closed",
                completion0_query_match, 1'b0);
      tb_check1("v8f bridge query1 exact open",
                completion1_query_match, 1'b1);

      wb0_valid = 1'b1;
      wb0_rob_idx = id0[ROB_INDEX_W-1:0];
      wb0_pdest = pdest0;
      wb0_data = 64'h0000_0000_1300_0020;
      `TB_TICK(clk);
      clear_inputs();
      commit_ready = 1'b0;
      completion0_query_valid = 1'b1;
      completion0_query_producer_id = id0;
      completion1_query_valid = 1'b1;
      completion1_query_producer_id = id1;
      #1;
      tb_check1("v8f bridge done issue remains current",
                issue0_producer_current, 1'b1);
      tb_check1("v8f bridge done completion closes",
                completion0_query_match, 1'b0);
      tb_check1("v8f bridge other completion remains open",
                completion1_query_match, 1'b1);

      flush = 1'b1;
      #1;
      tb_check1("v8f bridge flush masks issue0 current",
                issue0_producer_current, 1'b0);
      tb_check1("v8f bridge flush masks issue1 current",
                issue1_producer_current, 1'b0);
      tb_check1("v8f bridge flush masks completion0",
                completion0_query_match, 1'b0);
      tb_check1("v8f bridge flush masks completion1",
                completion1_query_match, 1'b0);
      $display("[V8F-DISPATCH-QUERY-BRIDGE] carrier/current/open/wrong-gen/done/flush PASS");
      reset_dut();
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check32("initial freelist count", {25'b0, free_count}, 32'd32);
    tb_check32("initial rob count", {27'b0, rob_count}, 32'd0);
    tb_check32("initial issue count", {28'b0, issue_count}, 32'd0);

    // 【P5 刀 B】IQ dispatch→issue 同拍 bypass 已删除:dispatch 项当拍只入队,
    // 次拍(N+1)起才从寄存项发射;T3M 起依赖 uop 等 wb 在沿上落 sticky 后再发射。
    set_dispatch0(32'h8000_0000, 5'd1, 1'b1, 5'd2, 1'b1, 5'd5, 1'b1);
    set_dispatch1(32'h8000_0004, 5'd5, 1'b1, 5'd3, 1'b1, 5'd6, 1'b1);
    #1;
    tb_check1("dual dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dual dispatch1 ready", dispatch1_ready, 1'b1);
    tb_check1("no same-cycle dispatch issue0", issue0_valid, 1'b0);
    tb_check1("no same-cycle dispatch issue1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;

    tb_check32("two physical regs allocated", {25'b0, free_count}, 32'd30);
    tb_check32("two rob entries allocated", {27'b0, rob_count}, 32'd2);
    tb_check32("both uops queued in iq", {28'b0, issue_count}, 32'd2);
    tb_check1("queued older independent uop issues", issue0_valid, 1'b1);
    tb_check32("queued older issue pc", issue0_pc, 32'h8000_0000);
    tb_check32("queued older issue rob", {28'b0, issue0_rob_idx}, 32'd0);
    tb_check32("queued older src1 preg", {26'b0, issue0_src1_preg}, 32'd1);
    tb_check32("queued older src2 preg", {26'b0, issue0_src2_preg}, 32'd2);
    tb_check32("queued older pdest", {26'b0, issue0_pdest}, 32'd32);
    tb_check1("dependent younger waits for wakeup", issue1_valid, 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check32("dependent uop remains queued", {28'b0, issue_count}, 32'd1);

    wb0_valid = 1'b1;
    wb0_rob_idx = 4'd0;
    wb0_pdest = 6'd32;
    wb0_data = 32'h1111_0005;
    #1;
    tb_check1("lane0 formal WB does not retire combinationally",
              commit0_valid, 1'b0);
    tb_check1("T3M dependent does not wake-select in WB cycle",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("lane0 commit becomes valid from ROB Q", commit0_valid, 1'b1);
    tb_check32("lane0 commit old pdest from ROB Q", {26'b0, commit0_old_pdest}, 32'd5);
    tb_check32("lane0 commit new pdest from ROB Q", {26'b0, commit0_new_pdest}, 32'd32);
    tb_check32("lane0 commit data from ROB Q", commit0_data, 32'h1111_0005);
    tb_check1("dependent wakes after wb sticky edge", issue0_valid, 1'b1);
    tb_check32("woken dependent issue pc", issue0_pc, 32'h8000_0004);
    tb_check32("woken dependent sees lane0 pdest", {26'b0, issue0_src1_preg}, 32'd32);
    tb_check32("woken dependent pdest", {26'b0, issue0_pdest}, 32'd33);
    `TB_TICK(clk);
    clear_inputs();

    wb1_valid = 1'b1;
    wb1_rob_idx = 4'd1;
    wb1_pdest = 6'd33;
    wb1_data = 32'h2222_0006;
    #1;
    tb_check1("lane1 formal WB does not retire combinationally",
              commit0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("lane1 commit becomes valid from ROB Q", commit0_valid, 1'b1);
    tb_check32("lane1 commit old pdest from ROB Q", {26'b0, commit0_old_pdest}, 32'd6);
    tb_check32("lane1 commit new pdest from ROB Q", {26'b0, commit0_new_pdest}, 32'd33);
    tb_check32("lane1 commit data from ROB Q", commit0_data, 32'h2222_0006);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("freelist recovers after two commits", {25'b0, free_count}, 32'd32);
    tb_check32("rob drains after two commits", {27'b0, rob_count}, 32'd0);
    tb_check32("issue queue drains after dependent issue", {28'b0, issue_count}, 32'd0);

    set_dispatch0(32'h8000_0010, 5'd1, 1'b1, 5'd2, 1'b1, 5'd7, 1'b1);
    set_dispatch1(32'h8000_0014, 5'd3, 1'b1, 5'd4, 1'b1, 5'd7, 1'b1);
    #1;
    tb_check1("waw no same-cycle issue0", issue0_valid, 1'b0);
    tb_check1("waw no same-cycle issue1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("waw pair queued", {28'b0, issue_count}, 32'd2);
    tb_check1("waw older queued issue valid", issue0_valid, 1'b1);
    tb_check1("waw younger queued issue valid", issue1_valid, 1'b1);
    tb_check32("waw older queued issue pc", issue0_pc, 32'h8000_0010);
    tb_check32("waw younger queued issue pc", issue1_pc, 32'h8000_0014);
    `TB_TICK(clk);
    #1;
    tb_check32("waw dual issue leaves issue queue empty",
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
    tb_check1("waw formal WBs do not retire combinationally",
              commit0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("waw commit0 valid from ROB Q", commit0_valid, 1'b1);
    tb_check1("waw commit1 valid from ROB Q", commit1_valid, 1'b1);
    tb_check32("waw older frees original x7 from ROB Q", {26'b0, commit0_old_pdest}, 32'd7);
    tb_check32("waw younger frees lane0 pdest from ROB Q", {26'b0, commit1_old_pdest}, 32'd34);
    tb_check32("waw older new pdest from ROB Q", {26'b0, commit0_new_pdest}, 32'd34);
    tb_check32("waw younger new pdest from ROB Q", {26'b0, commit1_new_pdest}, 32'd35);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("freelist recovers after waw commits", {25'b0, free_count}, 32'd32);
    tb_check32("rob drains after waw", {27'b0, rob_count}, 32'd0);

    // 隔离 T3B 周期场景并恢复 canonical free-list/ROB 索引，避免前序合法
    // 分配轮转让定向使用的 pdest32/rob0 变成脆弱隐含前提。
    set_dispatch0(32'h8000_0028, 5'd1, 1'b1, 5'd2, 1'b1, 5'd8, 1'b1);
    set_dispatch1(32'h8000_002c, 5'd3, 1'b1, 5'd4, 1'b1, 5'd9, 1'b1);
    flush = 1'b1;
    #1;
    tb_check1("v8e dispatch parent flush blocks lane0", dispatch0_ready,
              1'b0);
    tb_check1("v8e dispatch parent flush blocks lane1", dispatch1_ready,
              1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;

    // ===== T3B full-only WB0：resident 不得在 N 拍被 select，但 full wakeup
    // 必须同时更新 BusyTable 查询、IQ survivor sticky ready 与新 dispatch entry。 =====
    set_dispatch0(32'h8000_0030, 5'd1, 1'b1, 5'd2, 1'b1, 5'd9, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3B WB0 producer issues", issue0_valid, 1'b1);
    tb_check32("T3B WB0 producer issue pc", issue0_pc, 32'h8000_0030);
    `TB_TICK(clk);
    clear_inputs();

    set_dispatch0(32'h8000_0034, 5'd9, 1'b1, 5'd0, 1'b0, 5'd10, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3B WB0 resident queued", {28'b0, issue_count}, 32'd1);
    tb_check1("T3B WB0 resident initially waits", issue0_valid, 1'b0);

    wb0_valid = 1'b1;
    wb0_rob_idx = 4'd0;
    wb0_pdest = 6'd32;
    wb0_data = 32'h3333_0009;
    set_dispatch0(32'h8000_0038, 5'd9, 1'b1, 5'd0, 1'b0, 5'd11, 1'b1);
    #1;
    tb_check1("T3B WB0 full-only dispatch accepted", dispatch0_ready, 1'b1);
    tb_check1("T3B WB0 full-only resident not selected in N", issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3B WB0 resident issues in N+1", issue0_valid, 1'b1);
    tb_check32("T3B WB0 resident keeps oldest pc", issue0_pc, 32'h8000_0034);
    tb_check1("T3B WB0 dispatch absorbed BusyTable wakeup", issue1_valid, 1'b1);
    tb_check32("T3B WB0 absorbed dispatch pc", issue1_pc, 32'h8000_0038);
    `TB_TICK(clk);
    clear_inputs();
    flush = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3B WB0 cleanup freelist", {25'b0, free_count}, 32'd32);
    tb_check32("T3B WB0 cleanup rob", {27'b0, rob_count}, 32'd0);
    tb_check32("T3B WB0 cleanup iq", {28'b0, issue_count}, 32'd0);

    // ===== T3B full-only WB1：与 WB0 相同的 sticky/dispatch 合同，证明 lane1
    // 不是因遗漏透传而退化成永不 select。 =====
    set_dispatch0(32'h8000_0040, 5'd1, 1'b1, 5'd2, 1'b1, 5'd12, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3B WB1 producer issues", issue0_valid, 1'b1);
    tb_check32("T3B WB1 producer issue pc", issue0_pc, 32'h8000_0040);
    `TB_TICK(clk);
    clear_inputs();

    set_dispatch0(32'h8000_0044, 5'd12, 1'b1, 5'd0, 1'b0, 5'd13, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3B WB1 resident queued", {28'b0, issue_count}, 32'd1);
    tb_check1("T3B WB1 resident initially waits", issue0_valid, 1'b0);

    wb1_valid = 1'b1;
    wb1_rob_idx = 4'd0;
    wb1_pdest = 6'd32;
    wb1_data = 32'h4444_000c;
    set_dispatch0(32'h8000_0048, 5'd12, 1'b1, 5'd0, 1'b0, 5'd14, 1'b1);
    #1;
    tb_check1("T3B WB1 full-only dispatch accepted", dispatch0_ready, 1'b1);
    tb_check1("T3B WB1 full-only resident not selected in N", issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3B WB1 resident issues in N+1", issue0_valid, 1'b1);
    tb_check32("T3B WB1 resident keeps oldest pc", issue0_pc, 32'h8000_0044);
    tb_check1("T3B WB1 dispatch absorbed BusyTable wakeup", issue1_valid, 1'b1);
    tb_check32("T3B WB1 absorbed dispatch pc", issue1_pc, 32'h8000_0048);
    `TB_TICK(clk);
    clear_inputs();
    flush = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3B WB1 cleanup freelist", {25'b0, free_count}, 32'd32);
    tb_check32("T3B WB1 cleanup rob", {27'b0, rob_count}, 32'd0);
    tb_check32("T3B WB1 cleanup iq", {28'b0, issue_count}, 32'd0);

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
    $display("[V8E-DISPATCH-RESET-FLUSH-PASS] parent ready is fail-closed on reset and flush with presented valid");

    // T3N：branch resolve 已在 IntBackend 打成 coherent q packet，本层必须
    // 直接消费该拍 kill。用一个 done head、存活 branch 与 younger 构造
    // 同拍原本可 commit/issue/dispatch 的窗口，再证明 q kill 全部关断，且
    // 下一拍不会出现旧 kill_valid_q 的重复脉冲。
    commit_ready = 1'b0;
    set_dispatch0(32'h8000_0900,
                  5'd1, 1'b1, 5'd2, 1'b1, 5'd7, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3N direct-kill head reaches IQ", issue0_valid, 1'b1);
    tb_check32("T3N direct-kill head ROB index",
               {28'b0, issue0_rob_idx}, 32'd0);
    `TB_TICK(clk);
    clear_inputs();

    wb0_valid = 1'b1;
    wb0_rob_idx = 4'd0;
    wb0_pdest = 6'd32;
    wb0_data = 32'h9000_0007;
    set_dispatch0(32'h8000_0904,
                  5'd0, 1'b0, 5'd0, 1'b0, 5'd0, 1'b0);
    dispatch0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
    set_dispatch1(32'h8000_0908,
                  5'd3, 1'b1, 5'd4, 1'b1, 5'd8, 1'b1);
    #1;
    tb_check1("T3N direct-kill setup branch dispatch ready",
              dispatch0_ready, 1'b1);
    tb_check1("T3N direct-kill setup younger dispatch ready",
              dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    commit_ready = 1'b1;

    // 额外放一对 dispatch 候选，锁住 kill 当拍的 freeze，而不是仅观察
    // ROB 内部状态。
    set_dispatch0(32'h8000_090c,
                  5'd0, 1'b0, 5'd0, 1'b0, 5'd9, 1'b1);
    set_dispatch1(32'h8000_0910,
                  5'd0, 1'b0, 5'd0, 1'b0, 5'd10, 1'b1);
    #1;
    tb_check1("T3N direct-kill setup head could commit", commit0_valid, 1'b1);
    tb_check1("T3N direct-kill setup branch could issue", issue0_valid, 1'b1);
    tb_check1("T3N direct-kill setup younger could issue", issue1_valid, 1'b1);
    tb_check1("T3N direct-kill setup dispatch0 could accept",
              dispatch0_ready, 1'b1);
    tb_check1("T3N direct-kill setup dispatch1 could accept",
              dispatch1_ready, 1'b1);

    branch_mispredict_valid = 1'b1;
    kill_rob_idx = 4'd1;
    #1;
    tb_check1("T3N resolve q directly asserts ROB kill",
              dut.rob_kill_valid_w, 1'b1);
    tb_check32("T3N direct ROB kill keeps coherent index",
               {28'b0, dut.rob_kill_idx_w}, 32'd1);
    tb_check1("T3N q kill freezes dispatch0", dispatch0_ready, 1'b0);
    tb_check1("T3N q kill freezes dispatch1", dispatch1_ready, 1'b0);
    tb_check1("T3N q kill suppresses issue0", issue0_valid, 1'b0);
    tb_check1("T3N q kill suppresses issue1", issue1_valid, 1'b0);
    tb_check1("T3N q kill suppresses commit0", commit0_valid, 1'b0);
    tb_check1("T3N q kill suppresses commit1", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3N direct kill does not repeat next cycle",
              dut.rob_kill_valid_w, 1'b0);
    tb_check1("T3N one-shot kill starts legal ROB walk",
              rob_recover_active, 1'b1);
    tb_check32("T3N kill edge keeps ROB until walk",
               {27'b0, rob_count}, 32'd3);
    tb_check32("T3N IQ synchronously squashes only younger",
               {28'b0, issue_count}, 32'd1);

    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3N single-younger ROB walk completes",
              rob_recover_active, 1'b0);
    tb_check32("T3N ROB retains head and branch",
               {27'b0, rob_count}, 32'd2);
    tb_check32("T3N IQ retains only branch",
               {28'b0, issue_count}, 32'd1);
    tb_check1("T3N activity resumes dispatch", dispatch0_ready, 1'b1);
    tb_check1("T3N activity resumes head commit", commit0_valid, 1'b1);
    tb_check1("T3N activity resumes branch issue", issue0_valid, 1'b1);

    flush = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3N direct-kill cleanup freelist",
               {25'b0, free_count}, 32'd32);
    tb_check32("T3N direct-kill cleanup ROB",
               {27'b0, rob_count}, 32'd0);
    tb_check32("T3N direct-kill cleanup IQ",
               {28'b0, issue_count}, 32'd0);

    run_v8f_query_bridge();

    tb_finish("tb_ooo_dispatch_backend");
  end
endmodule
