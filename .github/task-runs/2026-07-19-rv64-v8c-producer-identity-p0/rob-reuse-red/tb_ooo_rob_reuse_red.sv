`include "define.v"

// 这是 current-RED characterization，而不是修复：它只用 production OooRob
// 端口复现“迟到旧写回按 raw ROB index 命中新槽”的 registered 状态别名。
module tb_ooo_rob_reuse_red;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam ROB_COUNT_W = `OOO_ROB_COUNT_W;
  localparam PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W;

  localparam [`XLEN-1:0] BRANCH_PC_BASE = 64'h0000_0000_8000_1000;
  localparam [`XLEN-1:0] OLD_PC_OFFSET = 64'h4;
  localparam [`XLEN-1:0] NEW_PC_OFFSET = 64'h100;
  localparam [`XLEN-1:0] OLD_DATA = 64'h0dd0_0dd0_aaaa_5555;
  localparam [`XLEN-1:0] NEW_DATA = 64'h0ee0_0ee0_1234_5678;
  localparam [PHY_REG_ADDR_W-1:0] REUSED_PDEST = 6'd17;

  reg clk;
  reg rst;
  reg flush;

  reg dispatch0_valid;
  wire dispatch0_ready;
  wire [ROB_INDEX_W-1:0] dispatch0_rob_idx;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`XLEN-1:0] dispatch0_next_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  reg dispatch0_rd_en;
  reg dispatch0_is_fp_rd;
  reg [`REG_ADDR_W-1:0] dispatch0_arch_rd;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_old_pdest;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_new_pdest;

  reg dispatch1_valid;
  wire dispatch1_ready;
  wire [ROB_INDEX_W-1:0] dispatch1_rob_idx;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`XLEN-1:0] dispatch1_next_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg dispatch1_rd_en;
  reg dispatch1_is_fp_rd;
  reg [`REG_ADDR_W-1:0] dispatch1_arch_rd;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_old_pdest;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest;

  reg wb0_valid;
  reg [ROB_INDEX_W-1:0] wb0_rob_idx;
  reg [`XLEN-1:0] wb0_data;
  reg wb0_exception;
  reg [`TRAP_CAUSE_W-1:0] wb0_cause;
  reg [`XLEN-1:0] wb0_tval;
  reg [4:0] wb0_fflags;
  reg [PHY_REG_ADDR_W-1:0] wb0_pdest;

  reg wb1_valid;
  reg [ROB_INDEX_W-1:0] wb1_rob_idx;
  reg [`XLEN-1:0] wb1_data;
  reg wb1_exception;
  reg [`TRAP_CAUSE_W-1:0] wb1_cause;
  reg [`XLEN-1:0] wb1_tval;
  reg [4:0] wb1_fflags;
  reg [PHY_REG_ADDR_W-1:0] wb1_pdest;

  reg commit_ready;
  reg commit1_block;
  reg mem_quiet;
  reg head0_context_permit;
  reg fencei_retire_permit;
  wire head0_retire_candidate_valid;
  wire head0_identity_valid;
  wire [`OOO_CONTEXT_ID_W-1:0] head0_identity;

  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire [`XLEN-1:0] commit0_next_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire commit0_rd_en;
  wire commit0_is_fp_rd;
  wire [4:0] commit0_fflags;
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
  wire commit1_is_fp_rd;
  wire [4:0] commit1_fflags;
  wire [`REG_ADDR_W-1:0] commit1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit1_new_pdest;
  wire [`XLEN-1:0] commit1_data;
  wire commit1_exception;
  wire [`TRAP_CAUSE_W-1:0] commit1_cause;
  wire [`XLEN-1:0] commit1_tval;

  wire [ROB_INDEX_W-1:0] head_idx;
  wire head_valid;
  wire [ROB_COUNT_W-1:0] count;
  wire empty;
  wire full;

  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  wire recover_active;
  wire walk0_valid;
  wire [`REG_ADDR_W-1:0] walk0_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] walk0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] walk0_new_pdest;
  wire walk0_rd_en;
  wire walk0_is_fp;
  wire walk1_valid;
  wire [`REG_ADDR_W-1:0] walk1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] walk1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] walk1_new_pdest;
  wire walk1_rd_en;
  wire walk1_is_fp;

  reg [`XLEN-1:0] scenario_branch_pc;
  reg [`XLEN-1:0] scenario_old_pc;
  reg [`XLEN-1:0] scenario_new_pc;

  OooRob dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_rob_idx_o(dispatch0_rob_idx),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_next_pc),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_rd_en_i(dispatch0_rd_en),
    .dispatch0_is_fp_rd_i(dispatch0_is_fp_rd),
    .dispatch0_arch_rd_i(dispatch0_arch_rd),
    .dispatch0_old_pdest_i(dispatch0_old_pdest),
    .dispatch0_new_pdest_i(dispatch0_new_pdest),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_rob_idx_o(dispatch1_rob_idx),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_next_pc),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_rd_en_i(dispatch1_rd_en),
    .dispatch1_is_fp_rd_i(dispatch1_is_fp_rd),
    .dispatch1_arch_rd_i(dispatch1_arch_rd),
    .dispatch1_old_pdest_i(dispatch1_old_pdest),
    .dispatch1_new_pdest_i(dispatch1_new_pdest),
    .wb0_valid_i(wb0_valid),
    .wb0_rob_idx_i(wb0_rob_idx),
    .wb0_data_i(wb0_data),
    .wb0_exception_i(wb0_exception),
    .wb0_cause_i(wb0_cause),
    .wb0_tval_i(wb0_tval),
    .wb0_fflags_i(wb0_fflags),
    .wb0_pdest_i(wb0_pdest),
    .wb1_valid_i(wb1_valid),
    .wb1_rob_idx_i(wb1_rob_idx),
    .wb1_data_i(wb1_data),
    .wb1_exception_i(wb1_exception),
    .wb1_cause_i(wb1_cause),
    .wb1_tval_i(wb1_tval),
    .wb1_fflags_i(wb1_fflags),
    .wb1_pdest_i(wb1_pdest),
    .commit_ready_i(commit_ready),
    .commit1_block_i(commit1_block),
    .mem_quiet_i(mem_quiet),
    .head0_context_permit_i(head0_context_permit),
    .fencei_retire_permit_i(fencei_retire_permit),
    .head0_retire_candidate_valid_o(head0_retire_candidate_valid),
    .head0_identity_valid_o(head0_identity_valid),
    .head0_identity_o(head0_identity),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_is_fp_rd_o(commit0_is_fp_rd),
    .commit0_fflags_o(commit0_fflags),
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
    .commit1_is_fp_rd_o(commit1_is_fp_rd),
    .commit1_fflags_o(commit1_fflags),
    .commit1_arch_rd_o(commit1_arch_rd),
    .commit1_old_pdest_o(commit1_old_pdest),
    .commit1_new_pdest_o(commit1_new_pdest),
    .commit1_data_o(commit1_data),
    .commit1_exception_o(commit1_exception),
    .commit1_cause_o(commit1_cause),
    .commit1_tval_o(commit1_tval),
    .head_idx_o(head_idx),
    .head_valid_o(head_valid),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .recover_active_o(recover_active),
    .walk0_valid_o(walk0_valid),
    .walk0_arch_rd_o(walk0_arch_rd),
    .walk0_old_pdest_o(walk0_old_pdest),
    .walk0_new_pdest_o(walk0_new_pdest),
    .walk0_rd_en_o(walk0_rd_en),
    .walk0_is_fp_o(walk0_is_fp),
    .walk1_valid_o(walk1_valid),
    .walk1_arch_rd_o(walk1_arch_rd),
    .walk1_old_pdest_o(walk1_old_pdest),
    .walk1_new_pdest_o(walk1_new_pdest),
    .walk1_rd_en_o(walk1_rd_en),
    .walk1_is_fp_o(walk1_is_fp)
  );

  task automatic tick;
    begin
      #5 clk = 1'b1;
      #1;
      #4 clk = 1'b0;
      #1;
    end
  endtask

  task automatic expect_true;
    input condition;
    input [8*160-1:0] message;
    begin
      if (condition !== 1'b1) begin
        $display("[TB-FAIL] %0s", message);
        $fatal(1);
      end
    end
  endtask

  task automatic idle_inputs;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = {`XLEN{1'b0}};
      dispatch0_next_pc = {`XLEN{1'b0}};
      dispatch0_inst = {`INST_W{1'b0}};
      dispatch0_rd_en = 1'b0;
      dispatch0_is_fp_rd = 1'b0;
      dispatch0_arch_rd = {`REG_ADDR_W{1'b0}};
      dispatch0_old_pdest = {PHY_REG_ADDR_W{1'b0}};
      dispatch0_new_pdest = {PHY_REG_ADDR_W{1'b0}};
      dispatch1_valid = 1'b0;
      dispatch1_pc = {`XLEN{1'b0}};
      dispatch1_next_pc = {`XLEN{1'b0}};
      dispatch1_inst = {`INST_W{1'b0}};
      dispatch1_rd_en = 1'b0;
      dispatch1_is_fp_rd = 1'b0;
      dispatch1_arch_rd = {`REG_ADDR_W{1'b0}};
      dispatch1_old_pdest = {PHY_REG_ADDR_W{1'b0}};
      dispatch1_new_pdest = {PHY_REG_ADDR_W{1'b0}};
      wb0_valid = 1'b0;
      wb0_rob_idx = {ROB_INDEX_W{1'b0}};
      wb0_data = {`XLEN{1'b0}};
      wb0_exception = 1'b0;
      wb0_cause = {`TRAP_CAUSE_W{1'b0}};
      wb0_tval = {`XLEN{1'b0}};
      wb0_fflags = 5'b0;
      wb0_pdest = {PHY_REG_ADDR_W{1'b0}};
      wb1_valid = 1'b0;
      wb1_rob_idx = {ROB_INDEX_W{1'b0}};
      wb1_data = {`XLEN{1'b0}};
      wb1_exception = 1'b0;
      wb1_cause = {`TRAP_CAUSE_W{1'b0}};
      wb1_tval = {`XLEN{1'b0}};
      wb1_fflags = 5'b0;
      wb1_pdest = {PHY_REG_ADDR_W{1'b0}};
      commit_ready = 1'b0;
      commit1_block = 1'b0;
      mem_quiet = 1'b1;
      head0_context_permit = 1'b1;
      fencei_retire_permit = 1'b1;
      kill_valid = 1'b0;
      kill_rob_idx = {ROB_INDEX_W{1'b0}};
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      idle_inputs();
      tick();
      tick();
      rst = 1'b0;
      tick();
      expect_true(empty && (count == 0) && (head_idx == 0) &&
                  (dispatch0_rob_idx == 0),
                  "reset 后 ROB 应为空且 head/tail=0");
    end
  endtask

  // 15 个真实 allocate->WB->commit 把空 ROB 的 head/tail 推到 15；没有层级 force。
  task automatic rotate_empty_ring_to_15;
    integer k;
    begin
      for (k = 0; k < 15; k = k + 1) begin
        dispatch0_valid = 1'b1;
        dispatch0_pc = 64'h0000_0000_7000_0000 + k * 64'd8;
        dispatch0_next_pc = dispatch0_pc + 64'd4;
        dispatch0_inst = 32'h0000_0013;
        dispatch0_rd_en = 1'b0;
        #1;
        expect_true(dispatch0_ready && (dispatch0_rob_idx == k[ROB_INDEX_W-1:0]),
                    "ring rotate dispatch index 不连续");
        tick();
        dispatch0_valid = 1'b0;

        wb0_valid = 1'b1;
        wb0_rob_idx = k[ROB_INDEX_W-1:0];
        wb0_data = 64'hf000_0000_0000_0000 + k;
        wb0_pdest = {PHY_REG_ADDR_W{1'b0}};
        tick();
        wb0_valid = 1'b0;
        #1;
        expect_true(head0_retire_candidate_valid && (count == 1),
                    "ring rotate filler WB 未形成 retire candidate");

        commit_ready = 1'b1;
        #1;
        expect_true(commit0_valid, "ring rotate filler 未能正常 commit");
        tick();
        commit_ready = 1'b0;
        #1;
        expect_true(empty && (count == 0), "ring rotate filler commit 后 ROB 非空");
      end
      expect_true((head_idx == 4'hf) && (dispatch0_rob_idx == 4'hf),
                  "15 次真实退休后 head/tail 应位于 wrap 边界 15");
    end
  endtask

  // 构造 branch@15 + old@0，并用 production ROB walk squash old，再让 new 重用 slot0。
  task automatic prepare_reused_slot0;
    input [`XLEN-1:0] pc_bias;
    begin
      scenario_branch_pc = BRANCH_PC_BASE + pc_bias;
      scenario_old_pc = scenario_branch_pc + OLD_PC_OFFSET;
      scenario_new_pc = scenario_branch_pc + NEW_PC_OFFSET;

      dispatch0_valid = 1'b1;
      dispatch0_pc = scenario_branch_pc;
      dispatch0_next_pc = scenario_branch_pc + 64'd8;
      dispatch0_inst = 32'h0000_0463; // beq x0,x0,+8；本 TB 只关心 ROB 元数据。
      dispatch0_rd_en = 1'b0;
      dispatch0_arch_rd = 5'd0;
      dispatch0_old_pdest = 6'd0;
      dispatch0_new_pdest = 6'd0;

      dispatch1_valid = 1'b1;
      dispatch1_pc = scenario_old_pc;
      dispatch1_next_pc = scenario_old_pc + 64'd4;
      dispatch1_inst = 32'h0012_8293;
      dispatch1_rd_en = 1'b1;
      dispatch1_arch_rd = 5'd5;
      dispatch1_old_pdest = 6'd16;
      dispatch1_new_pdest = REUSED_PDEST;
      #1;
      expect_true(dispatch0_ready && dispatch1_ready &&
                  (dispatch0_rob_idx == 4'hf) && (dispatch1_rob_idx == 4'h0),
                  "双发 wrap 分配必须是 branch@15 + old@0");
      tick();
      dispatch0_valid = 1'b0;
      dispatch1_valid = 1'b0;
      expect_true((count == 2) && (head_idx == 4'hf),
                  "branch/old 双发后 ROB 应有两项");

      wb0_valid = 1'b1;
      wb0_rob_idx = 4'hf;
      wb0_data = 64'h0;
      wb0_pdest = 6'd0;
      tick();
      wb0_valid = 1'b0;
      #1;
      expect_true(head0_retire_candidate_valid,
                  "存活 branch 的正常 WB 应使其 ready");

      kill_valid = 1'b1;
      kill_rob_idx = 4'hf;
      #1;
      expect_true(!dispatch0_ready && !head0_retire_candidate_valid,
                  "kill 脉冲当拍必须冻结 dispatch/retire");
      tick();
      kill_valid = 1'b0;
      #1;
      expect_true(recover_active && walk0_valid && !walk1_valid &&
                  (walk0_new_pdest == REUSED_PDEST),
                  "真实 ROB walk 应选中严格年轻的 old@0");
      tick();
      #1;
      expect_true(!recover_active && (count == 1) &&
                  (dispatch0_rob_idx == 4'h0),
                  "ROB walk 结束后 tail 必须回退到 old 的 slot0");

      commit_ready = 1'b1;
      #1;
      expect_true(commit0_valid && (commit0_pc == scenario_branch_pc),
                  "恢复后存活 branch 应正常退休");
      tick();
      commit_ready = 1'b0;
      #1;
      expect_true(empty && (head_idx == 4'h0) && (dispatch0_rob_idx == 4'h0),
                  "branch 退休后空 ROB 的 head/tail 必须都在0");

      dispatch0_valid = 1'b1;
      dispatch0_pc = scenario_new_pc;
      dispatch0_next_pc = scenario_new_pc + 64'd4;
      dispatch0_inst = 32'h0023_0313;
      dispatch0_rd_en = 1'b1;
      dispatch0_arch_rd = 5'd6;
      dispatch0_old_pdest = 6'd16;
      // 故意让 old/new 的 pdest 相同，证明已有 pdest sentinel 不能区分同 pdest 槽重用。
      dispatch0_new_pdest = REUSED_PDEST;
      #1;
      expect_true(dispatch0_ready && (dispatch0_rob_idx == 4'h0),
                  "new 必须真实重用已 squash 的 slot0");
      tick();
      dispatch0_valid = 1'b0;
      #1;
      expect_true((count == 1) && head_valid && (head_idx == 4'h0) &&
                  !head0_retire_candidate_valid,
                  "new 分配后尚无自身 WB，不得提前 ready");
    end
  endtask

  task automatic exercise_late_old_writeback_alias;
    begin
      reset_dut();
      rotate_empty_ring_to_15();
      prepare_reused_slot0(64'h0);

      // old 原由 dispatch1 分配；在 squash/new 重用后才从 wb1 迟到返回。
      wb1_valid = 1'b1;
      wb1_rob_idx = 4'h0;
      wb1_data = OLD_DATA;
      wb1_pdest = REUSED_PDEST;
      #1;
      expect_true(!head0_retire_candidate_valid,
                  "迟到旧写回采样沿前 new 仍应未完成");
      tick();
      wb1_valid = 1'b0;
      #1;
      expect_true(head0_retire_candidate_valid && !commit0_valid &&
                  (commit0_pc == scenario_new_pc) && (commit0_data == OLD_DATA),
                  "current RED：迟到旧写回应已错误更新 new 的 registered done/payload");
      $display("[ROB-REUSE-RED][WITNESS] branch_idx=15 old_dispatch_lane=1 old_idx=0 new_dispatch_lane=0 new_idx=0 stale_wb_lane=1 registered_done=1 payload_alias=1 new_pc=%h old_data=%h",
               scenario_new_pc, commit0_data);

      commit_ready = 1'b1;
      #1;
      expect_true(commit0_valid && (commit0_pc == scenario_new_pc) &&
                  (commit0_data == OLD_DATA) &&
                  (commit0_new_pdest == REUSED_PDEST),
                  "错误 done 后应可观察到 new 元数据绑定 old payload 的 commit");
      tick();
      commit_ready = 1'b0;
      #1;
      expect_true(empty, "current-RED witness commit 后 ROB 应回到空态");
    end
  endtask

  task automatic exercise_correct_new_writeback_control;
    begin
      reset_dut();
      rotate_empty_ring_to_15();
      prepare_reused_slot0(64'h0000_0000_0010_0000);

      // 完全相同的 branch recovery/slot reuse，只把 new 自己的写回作为正控制。
      wb0_valid = 1'b1;
      wb0_rob_idx = 4'h0;
      wb0_data = NEW_DATA;
      wb0_pdest = REUSED_PDEST;
      tick();
      wb0_valid = 1'b0;
      #1;
      expect_true(head0_retire_candidate_valid &&
                  (commit0_pc == scenario_new_pc) && (commit0_data == NEW_DATA),
                  "正确 new WB 正控制必须形成对应 candidate/payload");
      commit_ready = 1'b1;
      #1;
      expect_true(commit0_valid && (commit0_data == NEW_DATA),
                  "正确 new WB 正控制必须能退休");
      $display("[ROB-REUSE-RED][POSITIVE] branch_idx=15 old_idx=0 new_idx=0 new_wb_lane=0 registered_done=1 payload_match=1 new_pc=%h new_data=%h",
               scenario_new_pc, commit0_data);
      tick();
      commit_ready = 1'b0;
      #1;
      expect_true(empty, "正确 new WB 正控制退休后 ROB 应为空");
    end
  endtask

  wire _unused_outputs = full | head0_identity_valid | (|head0_identity) |
      (|commit0_next_pc) | (|commit0_inst) | commit0_rd_en |
      commit0_is_fp_rd | (|commit0_fflags) | (|commit0_arch_rd) |
      (|commit0_old_pdest) | commit0_exception | (|commit0_cause) |
      (|commit0_tval) | commit1_valid | (|commit1_pc) |
      (|commit1_next_pc) | (|commit1_inst) | commit1_rd_en |
      commit1_is_fp_rd | (|commit1_fflags) | (|commit1_arch_rd) |
      (|commit1_old_pdest) | (|commit1_new_pdest) | (|commit1_data) |
      commit1_exception | (|commit1_cause) | (|commit1_tval) |
      (|walk0_arch_rd) | (|walk0_old_pdest) | walk0_rd_en | walk0_is_fp |
      (|walk1_arch_rd) | (|walk1_old_pdest) | (|walk1_new_pdest) |
      walk1_rd_en | walk1_is_fp | (|scenario_old_pc);

  initial begin
    exercise_late_old_writeback_alias();
    exercise_correct_new_writeback_control();
    $display("[ROB-REUSE-RED][PASS] expected_current_red=1 positive_control=1 branch_recovery=1 slot_wrap=1");
    $finish;
  end

  initial begin
    #20000;
    $display("[TB-FAIL] timeout");
    $fatal(1);
  end
endmodule
