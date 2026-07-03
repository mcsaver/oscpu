`include "define.v"

// ROB 是乱序执行和精确提交之间的边界：执行可乱序完成，
// 但对外 commit、异常和旧物理寄存器释放必须按 head 顺序发生。
module OooRob #(
  parameter ROB_ENTRIES = (1 << `OOO_ROB_INDEX_W),
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  output [ROB_INDEX_W-1:0] dispatch0_rob_idx_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input dispatch0_rd_en_i,
  // 【B-FP Phase0 地基】FPR 目的标记: commit 时写架构 FPR 而非 GPR(arch_rd 复用为
  // FPR 号)。fflags 随 wb 回填、随 commit 输出。接 0 时行为与旧版逐位一致。
  input dispatch0_is_fp_rd_i,
  input [`REG_ADDR_W-1:0] dispatch0_arch_rd_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_old_pdest_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_new_pdest_i,

  input dispatch1_valid_i,
  output dispatch1_ready_o,
  output [ROB_INDEX_W-1:0] dispatch1_rob_idx_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input dispatch1_rd_en_i,
  input dispatch1_is_fp_rd_i,
  input [`REG_ADDR_W-1:0] dispatch1_arch_rd_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_old_pdest_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest_i,

  input wb0_valid_i,
  input [ROB_INDEX_W-1:0] wb0_rob_idx_i,
  input [`XLEN-1:0] wb0_data_i,
  input wb0_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb0_cause_i,
  input [`XLEN-1:0] wb0_tval_i,
  input [4:0] wb0_fflags_i,

  input wb1_valid_i,
  input [ROB_INDEX_W-1:0] wb1_rob_idx_i,
  input [`XLEN-1:0] wb1_data_i,
  input wb1_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb1_cause_i,
  input [`XLEN-1:0] wb1_tval_i,
  input [4:0] wb1_fflags_i,

  input commit_ready_i,
  input commit1_block_i,
  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output commit0_is_fp_rd_o,
  output [4:0] commit0_fflags_o,
  output [`REG_ADDR_W-1:0] commit0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit0_new_pdest_o,
  output [`XLEN-1:0] commit0_data_o,
  output commit0_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit0_cause_o,
  output [`XLEN-1:0] commit0_tval_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output commit1_rd_en_o,
  output commit1_is_fp_rd_o,
  output [4:0] commit1_fflags_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit1_new_pdest_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,

  output [ROB_INDEX_W-1:0] head_idx_o,
  output head_valid_o,
  output [ROB_COUNT_W-1:0] count_o,
  output empty_o,
  output full_o,

  // B2 ROB-walk 误预测恢复：给定存活分支 rob_idx，多周期反向 walk 把严格更年轻的 uop squash，
  // 并逐拍(2/拍)emit 其 arch_rd/old_pdest/new_pdest 供 rename 还原 + free-list 回收。
  // 详见 design/arch/b2-branch-spec-redirect.md §4.1。kill_valid_i 暂由核接 1'b0（投机未启用）→ 本增量行为中性；
  // walk_* 消费者(rename/free-list 恢复端口)接入见整合切片。
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,    // 存活分支 idx；squash 严格更年轻者(R+1..tail-1)
  output recover_active_o,                   // walk 进行中：核需冻结 dispatch/commit/wb
  output walk0_valid_o,
  output [`REG_ADDR_W-1:0] walk0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] walk0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] walk0_new_pdest_o,
  output walk0_rd_en_o,
  output walk0_is_fp_o,
  output walk1_valid_o,
  output [`REG_ADDR_W-1:0] walk1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] walk1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] walk1_new_pdest_o,
  output walk1_rd_en_o,
  output walk1_is_fp_o
);

  reg valid_q [0:ROB_ENTRIES-1];
  reg done_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] pc_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] next_pc_q [0:ROB_ENTRIES-1];
  reg [`INST_W-1:0] inst_q [0:ROB_ENTRIES-1];
  reg rd_en_q [0:ROB_ENTRIES-1];
  reg [`REG_ADDR_W-1:0] arch_rd_q [0:ROB_ENTRIES-1];
  reg [PHY_REG_ADDR_W-1:0] old_pdest_q [0:ROB_ENTRIES-1];
  reg [PHY_REG_ADDR_W-1:0] new_pdest_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] data_q [0:ROB_ENTRIES-1];
  reg exception_q [0:ROB_ENTRIES-1];
  reg [`TRAP_CAUSE_W-1:0] cause_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] tval_q [0:ROB_ENTRIES-1];
  // 【B-FP Phase0 地基】不进 checkpoint 影子(该机制已被 ROB-walk 取代, 只减不加)
  reg is_fp_rd_q [0:ROB_ENTRIES-1];
  reg [4:0] fflags_q [0:ROB_ENTRIES-1];

  reg [ROB_INDEX_W-1:0] head_q;
  reg [ROB_INDEX_W-1:0] tail_q;
  reg [ROB_COUNT_W-1:0] count_q;

  // B2 ROB-walk 恢复状态机
`ifdef ROB_WALK_DEBUG
  reg [11:0] rob_stall_cnt_q;
`endif
  reg recover_q;
  reg [ROB_INDEX_W-1:0] walk_ptr_q;   // 当前待 squash 的最年轻未处理 entry
  reg [ROB_INDEX_W-1:0] kill_idx_q;   // 存活分支 idx（walk 终点：到它即停）

  reg checkpoint_valid_q [0:ROB_ENTRIES-1];
  reg checkpoint_done_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] checkpoint_pc_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] checkpoint_next_pc_q [0:ROB_ENTRIES-1];
  reg [`INST_W-1:0] checkpoint_inst_q [0:ROB_ENTRIES-1];
  reg checkpoint_rd_en_q [0:ROB_ENTRIES-1];
  reg [`REG_ADDR_W-1:0] checkpoint_arch_rd_q [0:ROB_ENTRIES-1];
  reg [PHY_REG_ADDR_W-1:0] checkpoint_old_pdest_q [0:ROB_ENTRIES-1];
  reg [PHY_REG_ADDR_W-1:0] checkpoint_new_pdest_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] checkpoint_data_q [0:ROB_ENTRIES-1];
  reg checkpoint_exception_q [0:ROB_ENTRIES-1];
  reg [`TRAP_CAUSE_W-1:0] checkpoint_cause_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] checkpoint_tval_q [0:ROB_ENTRIES-1];
  reg [ROB_INDEX_W-1:0] checkpoint_head_q;
  reg [ROB_INDEX_W-1:0] checkpoint_tail_q;
  reg [ROB_COUNT_W-1:0] checkpoint_count_q;

  wire [ROB_INDEX_W-1:0] head1_w;
  wire wb0_head_match_w;
  wire wb1_head_match_w;
  wire wb0_head1_match_w;
  wire wb1_head1_match_w;
  wire head_done_w;
  wire head1_done_w;
  wire [`XLEN-1:0] head_data_w;
  wire [`XLEN-1:0] head1_data_w;
  wire head_exception_w;
  wire head1_exception_w;
  wire [`TRAP_CAUSE_W-1:0] head_cause_w;
  wire [`TRAP_CAUSE_W-1:0] head1_cause_w;
  wire [`XLEN-1:0] head_tval_w;
  wire [`XLEN-1:0] head1_tval_w;
  wire [4:0] head_fflags_w;
  wire [4:0] head1_fflags_w;
  wire commit0_fire_w;
  wire commit1_fire_w;
  wire [1:0] commit_count_w;
  wire [ROB_COUNT_W-1:0] free_slots_w;
  wire dispatch0_fire_w;
  wire dispatch1_fire_w;
  wire [1:0] dispatch_count_w;

  integer idx;

  function [ROB_INDEX_W-1:0] rob_ptr_add;
    input [ROB_INDEX_W-1:0] base;
    input [1:0] inc;
    begin
      rob_ptr_add = base + {{(ROB_INDEX_W-2){1'b0}}, inc};
    end
  endfunction

  assign head1_w = rob_ptr_add(head_q, 2'd1);
  assign wb0_head_match_w =
      wb0_valid_i && valid_q[head_q] && (wb0_rob_idx_i == head_q);
  assign wb1_head_match_w =
      wb1_valid_i && valid_q[head_q] && (wb1_rob_idx_i == head_q);
  assign wb0_head1_match_w =
      wb0_valid_i && valid_q[head1_w] && (wb0_rob_idx_i == head1_w);
  assign wb1_head1_match_w =
      wb1_valid_i && valid_q[head1_w] && (wb1_rob_idx_i == head1_w);
  assign head_done_w = done_q[head_q] || wb0_head_match_w ||
                       wb1_head_match_w;
  assign head1_done_w = done_q[head1_w] || wb0_head1_match_w ||
                        wb1_head1_match_w;
  assign head_data_w = done_q[head_q] ? data_q[head_q] :
                       wb0_head_match_w ? wb0_data_i :
                       wb1_head_match_w ? wb1_data_i : data_q[head_q];
  assign head1_data_w = done_q[head1_w] ? data_q[head1_w] :
                        wb0_head1_match_w ? wb0_data_i :
                        wb1_head1_match_w ? wb1_data_i : data_q[head1_w];
  assign head_exception_w = done_q[head_q] ? exception_q[head_q] :
                            wb0_head_match_w ? wb0_exception_i :
                            wb1_head_match_w ? wb1_exception_i :
                            exception_q[head_q];
  assign head1_exception_w = done_q[head1_w] ? exception_q[head1_w] :
                             wb0_head1_match_w ? wb0_exception_i :
                             wb1_head1_match_w ? wb1_exception_i :
                             exception_q[head1_w];
  assign head_cause_w = done_q[head_q] ? cause_q[head_q] :
                        wb0_head_match_w ? wb0_cause_i :
                        wb1_head_match_w ? wb1_cause_i :
                        cause_q[head_q];
  assign head1_cause_w = done_q[head1_w] ? cause_q[head1_w] :
                         wb0_head1_match_w ? wb0_cause_i :
                         wb1_head1_match_w ? wb1_cause_i :
                         cause_q[head1_w];
  assign head_fflags_w = done_q[head_q] ? fflags_q[head_q] :
                         wb0_head_match_w ? wb0_fflags_i :
                         wb1_head_match_w ? wb1_fflags_i :
                         fflags_q[head_q];
  assign head1_fflags_w = done_q[head1_w] ? fflags_q[head1_w] :
                          wb0_head1_match_w ? wb0_fflags_i :
                          wb1_head1_match_w ? wb1_fflags_i :
                          fflags_q[head1_w];
  assign head_tval_w = done_q[head_q] ? tval_q[head_q] :
                       wb0_head_match_w ? wb0_tval_i :
                       wb1_head_match_w ? wb1_tval_i :
                       tval_q[head_q];
  assign head1_tval_w = done_q[head1_w] ? tval_q[head1_w] :
                        wb0_head1_match_w ? wb0_tval_i :
                        wb1_head1_match_w ? wb1_tval_i :
                        tval_q[head1_w];
  // ---- B2 ROB-walk 恢复（组合）----
  wire [ROB_INDEX_W-1:0] kill_next_start_w = rob_ptr_add(kill_rob_idx_i, 2'd1);
  wire kill_has_younger_w = kill_valid_i && (tail_q != kill_next_start_w);
  // 冻结 dispatch/commit/wb：必须在「kill 脉冲当拍」就冻结，与 IQ 的 squash/issue-gate（均按 kill_valid_i）
  // 严格一致；否则 kill 当拍 ROB 仍放新指令进 ROB、而 IQ 把它的发射项 squash 掉 → 僵尸 ROB 项永不 done。
  wire recovering_w = recover_q || kill_valid_i;
  wire [ROB_INDEX_W-1:0] wptr_m1_w = walk_ptr_q - {{(ROB_INDEX_W-1){1'b0}}, 1'b1};
  wire [ROB_INDEX_W-1:0] kill_next_q_w = rob_ptr_add(kill_idx_q, 2'd1);
  wire lane0_sq_w = recover_q;                           // 不变量：recover 期 walk_ptr_q 恒为更年轻 entry
  wire lane1_sq_w = recover_q && (wptr_m1_w != kill_idx_q);
  wire last_one_w = recover_q && (wptr_m1_w == kill_idx_q);
  wire last_two_w = recover_q && (wptr_m1_w != kill_idx_q) &&
                    ((walk_ptr_q - {{(ROB_INDEX_W-2){1'b0}}, 2'd2}) == kill_idx_q);
  wire walk_done_w = last_one_w || last_two_w;

  assign recover_active_o   = recover_q;
  assign walk0_valid_o      = lane0_sq_w;
  assign walk0_arch_rd_o    = arch_rd_q[walk_ptr_q];
  assign walk0_old_pdest_o  = old_pdest_q[walk_ptr_q];
  assign walk0_new_pdest_o  = new_pdest_q[walk_ptr_q];
  assign walk0_rd_en_o      = rd_en_q[walk_ptr_q];
  assign walk0_is_fp_o      = is_fp_rd_q[walk_ptr_q];
  assign walk1_valid_o      = lane1_sq_w;
  assign walk1_arch_rd_o    = arch_rd_q[wptr_m1_w];
  assign walk1_old_pdest_o  = old_pdest_q[wptr_m1_w];
  assign walk1_new_pdest_o  = new_pdest_q[wptr_m1_w];
  assign walk1_rd_en_o      = rd_en_q[wptr_m1_w];
  assign walk1_is_fp_o      = is_fp_rd_q[wptr_m1_w];

  assign commit0_fire_w = !recovering_w &&
                          commit_ready_i && (count_q != {ROB_COUNT_W{1'b0}}) &&
                          valid_q[head_q] && head_done_w;
  assign commit1_fire_w = commit0_fire_w && !commit1_block_i &&
                          !head_exception_w &&
                          (count_q > {{(ROB_COUNT_W-1){1'b0}}, 1'b1}) &&
                          valid_q[head1_w] && head1_done_w;
  assign commit_count_w = {1'b0, commit0_fire_w} + {1'b0, commit1_fire_w};

  // Dispatch ready 只看当前已登记的 ROB 空位，不借用同拍 commit 释放的槽。
  // 这样避免 dispatch->issue 旁路和 writeback/commit 之间形成组合环。
  assign free_slots_w = ROB_ENTRIES[ROB_COUNT_W-1:0] - count_q;
  assign dispatch0_ready_o = !recovering_w && (free_slots_w != {ROB_COUNT_W{1'b0}});
  assign dispatch0_fire_w = dispatch0_valid_i && dispatch0_ready_o;
  assign dispatch1_ready_o = !recovering_w && (free_slots_w > {{(ROB_COUNT_W-1){1'b0}}, dispatch0_fire_w});
  assign dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;
  assign dispatch_count_w = {1'b0, dispatch0_fire_w} + {1'b0, dispatch1_fire_w};
  assign dispatch0_rob_idx_o = tail_q;
  assign dispatch1_rob_idx_o = rob_ptr_add(tail_q, {1'b0, dispatch0_fire_w});

`ifdef DBRA_PROBE
  always @(posedge clk) begin
    if (commit0_fire_w || commit1_fire_w || kill_valid_i || recover_q)
      $display("[ROBP] c0=%b pc0=%h c1=%b pc1=%h kill=%b kidx=%h recov=%b head=%h cnt=%d",
               commit0_fire_w, pc_q[head_q], commit1_fire_w, pc_q[head1_w],
               kill_valid_i, kill_rob_idx_i, recover_q, head_q, count_q);
  end
`endif
  assign commit0_valid_o = commit0_fire_w;
  assign commit0_pc_o = pc_q[head_q];
  assign commit0_next_pc_o = next_pc_q[head_q];
  assign commit0_inst_o = inst_q[head_q];
  assign commit0_rd_en_o = rd_en_q[head_q];
  assign commit0_is_fp_rd_o = is_fp_rd_q[head_q];
  assign commit0_fflags_o = head_fflags_w;
  assign commit0_arch_rd_o = arch_rd_q[head_q];
  assign commit0_old_pdest_o = old_pdest_q[head_q];
  assign commit0_new_pdest_o = new_pdest_q[head_q];
  assign commit0_data_o = head_data_w;
  assign commit0_exception_o = head_exception_w;
  assign commit0_cause_o = head_cause_w;
  assign commit0_tval_o = head_tval_w;

  assign commit1_valid_o = commit1_fire_w;
  assign commit1_pc_o = pc_q[head1_w];
  assign commit1_next_pc_o = next_pc_q[head1_w];
  assign commit1_inst_o = inst_q[head1_w];
  assign commit1_rd_en_o = rd_en_q[head1_w];
  assign commit1_is_fp_rd_o = is_fp_rd_q[head1_w];
  assign commit1_fflags_o = head1_fflags_w;
  assign commit1_arch_rd_o = arch_rd_q[head1_w];
  assign commit1_old_pdest_o = old_pdest_q[head1_w];
  assign commit1_new_pdest_o = new_pdest_q[head1_w];
  assign commit1_data_o = head1_data_w;
  assign commit1_exception_o = head1_exception_w;
  assign commit1_cause_o = head1_cause_w;
  assign commit1_tval_o = head1_tval_w;

  assign head_idx_o = head_q;
  assign head_valid_o = (count_q != {ROB_COUNT_W{1'b0}});
  assign count_o = count_q;
  assign empty_o = (count_q == {ROB_COUNT_W{1'b0}});
  assign full_o = (count_q == ROB_ENTRIES[ROB_COUNT_W-1:0]);

  always @(posedge clk) begin
    if (rst || flush_i) begin
      head_q <= {ROB_INDEX_W{1'b0}};
      tail_q <= {ROB_INDEX_W{1'b0}};
      count_q <= {ROB_COUNT_W{1'b0}};
      for (idx = 0; idx < ROB_ENTRIES; idx = idx + 1) begin
        valid_q[idx] <= 1'b0;
        done_q[idx] <= 1'b0;
        pc_q[idx] <= {`XLEN{1'b0}};
        next_pc_q[idx] <= {`XLEN{1'b0}};
        inst_q[idx] <= {`INST_W{1'b0}};
        rd_en_q[idx] <= 1'b0;
        arch_rd_q[idx] <= {`REG_ADDR_W{1'b0}};
        old_pdest_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        new_pdest_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        data_q[idx] <= {`XLEN{1'b0}};
        exception_q[idx] <= 1'b0;
        cause_q[idx] <= {`TRAP_CAUSE_W{1'b0}};
        tval_q[idx] <= {`XLEN{1'b0}};
        is_fp_rd_q[idx] <= 1'b0;
        fflags_q[idx] <= 5'b00000;
        checkpoint_valid_q[idx] <= 1'b0;
        checkpoint_done_q[idx] <= 1'b0;
        checkpoint_pc_q[idx] <= {`XLEN{1'b0}};
        checkpoint_next_pc_q[idx] <= {`XLEN{1'b0}};
        checkpoint_inst_q[idx] <= {`INST_W{1'b0}};
        checkpoint_rd_en_q[idx] <= 1'b0;
        checkpoint_arch_rd_q[idx] <= {`REG_ADDR_W{1'b0}};
        checkpoint_old_pdest_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        checkpoint_new_pdest_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        checkpoint_data_q[idx] <= {`XLEN{1'b0}};
        checkpoint_exception_q[idx] <= 1'b0;
        checkpoint_cause_q[idx] <= {`TRAP_CAUSE_W{1'b0}};
        checkpoint_tval_q[idx] <= {`XLEN{1'b0}};
      end
      checkpoint_head_q <= {ROB_INDEX_W{1'b0}};
      checkpoint_tail_q <= {ROB_INDEX_W{1'b0}};
      checkpoint_count_q <= {ROB_COUNT_W{1'b0}};
      recover_q <= 1'b0;
      walk_ptr_q <= {ROB_INDEX_W{1'b0}};
      kill_idx_q <= {ROB_INDEX_W{1'b0}};
    end else if (checkpoint_restore_i) begin
      head_q <= checkpoint_head_q;
      tail_q <= checkpoint_tail_q;
      count_q <= checkpoint_count_q;
      for (idx = 0; idx < ROB_ENTRIES; idx = idx + 1) begin
        valid_q[idx] <= checkpoint_valid_q[idx];
        done_q[idx] <= checkpoint_done_q[idx];
        pc_q[idx] <= checkpoint_pc_q[idx];
        next_pc_q[idx] <= checkpoint_next_pc_q[idx];
        inst_q[idx] <= checkpoint_inst_q[idx];
        rd_en_q[idx] <= checkpoint_rd_en_q[idx];
        arch_rd_q[idx] <= checkpoint_arch_rd_q[idx];
        old_pdest_q[idx] <= checkpoint_old_pdest_q[idx];
        new_pdest_q[idx] <= checkpoint_new_pdest_q[idx];
        data_q[idx] <= checkpoint_data_q[idx];
        exception_q[idx] <= checkpoint_exception_q[idx];
        cause_q[idx] <= checkpoint_cause_q[idx];
        tval_q[idx] <= checkpoint_tval_q[idx];
      end
    end else if (checkpoint_capture_i) begin
      checkpoint_head_q <= head_q;
      checkpoint_tail_q <= tail_q;
      checkpoint_count_q <= count_q;
      for (idx = 0; idx < ROB_ENTRIES; idx = idx + 1) begin
        checkpoint_valid_q[idx] <= valid_q[idx];
        checkpoint_done_q[idx] <= done_q[idx];
        checkpoint_pc_q[idx] <= pc_q[idx];
        checkpoint_next_pc_q[idx] <= next_pc_q[idx];
        checkpoint_inst_q[idx] <= inst_q[idx];
        checkpoint_rd_en_q[idx] <= rd_en_q[idx];
        checkpoint_arch_rd_q[idx] <= arch_rd_q[idx];
        checkpoint_old_pdest_q[idx] <= old_pdest_q[idx];
        checkpoint_new_pdest_q[idx] <= new_pdest_q[idx];
        checkpoint_data_q[idx] <= data_q[idx];
        checkpoint_exception_q[idx] <= exception_q[idx];
        checkpoint_cause_q[idx] <= cause_q[idx];
        checkpoint_tval_q[idx] <= tval_q[idx];
      end
    end else if (recover_q) begin
      // ROB-walk：本拍 squash lane0(恒)/lane1(若仍更年轻)，count 递减；到存活分支即收尾回退 tail。
      // 关键：recovery 窗口内仍须吸收 in-flight 写回——更老(存活)指令的执行结果若恰在此时回写，
      // 丢弃会令其 ROB 项永不 done → head 永久卡死。写回放在 squash 之前，被 squash 的更年轻项由
      // 其后的 valid/done<=0 覆盖（nonblocking 源序后写胜），故对被压制项无副作用。
      if (wb0_valid_i && valid_q[wb0_rob_idx_i]) begin
        done_q[wb0_rob_idx_i] <= 1'b1;
        data_q[wb0_rob_idx_i] <= wb0_data_i;
        exception_q[wb0_rob_idx_i] <= wb0_exception_i;
        cause_q[wb0_rob_idx_i] <= wb0_cause_i;
        tval_q[wb0_rob_idx_i] <= wb0_tval_i;
        fflags_q[wb0_rob_idx_i] <= wb0_fflags_i;
      end
      if (wb1_valid_i && valid_q[wb1_rob_idx_i]) begin
        done_q[wb1_rob_idx_i] <= 1'b1;
        data_q[wb1_rob_idx_i] <= wb1_data_i;
        exception_q[wb1_rob_idx_i] <= wb1_exception_i;
        cause_q[wb1_rob_idx_i] <= wb1_cause_i;
        tval_q[wb1_rob_idx_i] <= wb1_tval_i;
        fflags_q[wb1_rob_idx_i] <= wb1_fflags_i;
      end
      valid_q[walk_ptr_q] <= 1'b0;
      done_q[walk_ptr_q] <= 1'b0;
      if (lane1_sq_w) begin
        valid_q[wptr_m1_w] <= 1'b0;
        done_q[wptr_m1_w] <= 1'b0;
      end
      count_q <= count_q - (lane1_sq_w ? {{(ROB_COUNT_W-2){1'b0}}, 2'd2}
                                       : {{(ROB_COUNT_W-1){1'b0}}, 1'b1});
      if (walk_done_w) begin
        recover_q <= 1'b0;
        tail_q <= kill_next_q_w;
      end else begin
        walk_ptr_q <= walk_ptr_q - {{(ROB_INDEX_W-2){1'b0}}, 2'd2};
      end
    end else if (kill_has_younger_w) begin
      // 启动 walk：从 tail-1（最年轻）开始反向 squash，终点=存活分支 kill_rob_idx。
      // 同样吸收本拍 in-flight 写回（此拍尚未 squash 任何项，无冲突）。
      if (wb0_valid_i && valid_q[wb0_rob_idx_i]) begin
        done_q[wb0_rob_idx_i] <= 1'b1;
        data_q[wb0_rob_idx_i] <= wb0_data_i;
        exception_q[wb0_rob_idx_i] <= wb0_exception_i;
        cause_q[wb0_rob_idx_i] <= wb0_cause_i;
        tval_q[wb0_rob_idx_i] <= wb0_tval_i;
        fflags_q[wb0_rob_idx_i] <= wb0_fflags_i;
      end
      if (wb1_valid_i && valid_q[wb1_rob_idx_i]) begin
        done_q[wb1_rob_idx_i] <= 1'b1;
        data_q[wb1_rob_idx_i] <= wb1_data_i;
        exception_q[wb1_rob_idx_i] <= wb1_exception_i;
        cause_q[wb1_rob_idx_i] <= wb1_cause_i;
        tval_q[wb1_rob_idx_i] <= wb1_tval_i;
        fflags_q[wb1_rob_idx_i] <= wb1_fflags_i;
      end
      recover_q <= 1'b1;
      kill_idx_q <= kill_rob_idx_i;
      walk_ptr_q <= tail_q - {{(ROB_INDEX_W-1){1'b0}}, 1'b1};
    end else begin
      if (commit0_fire_w) begin
        valid_q[head_q] <= 1'b0;
        done_q[head_q] <= 1'b0;
      end
      if (commit1_fire_w) begin
        valid_q[head1_w] <= 1'b0;
        done_q[head1_w] <= 1'b0;
      end

      if (wb0_valid_i && valid_q[wb0_rob_idx_i]) begin
        done_q[wb0_rob_idx_i] <= 1'b1;
        data_q[wb0_rob_idx_i] <= wb0_data_i;
        exception_q[wb0_rob_idx_i] <= wb0_exception_i;
        cause_q[wb0_rob_idx_i] <= wb0_cause_i;
        tval_q[wb0_rob_idx_i] <= wb0_tval_i;
        fflags_q[wb0_rob_idx_i] <= wb0_fflags_i;
      end
      if (wb1_valid_i && valid_q[wb1_rob_idx_i]) begin
        done_q[wb1_rob_idx_i] <= 1'b1;
        data_q[wb1_rob_idx_i] <= wb1_data_i;
        exception_q[wb1_rob_idx_i] <= wb1_exception_i;
        cause_q[wb1_rob_idx_i] <= wb1_cause_i;
        tval_q[wb1_rob_idx_i] <= wb1_tval_i;
        fflags_q[wb1_rob_idx_i] <= wb1_fflags_i;
      end

      if (dispatch0_fire_w) begin
        valid_q[dispatch0_rob_idx_o] <= 1'b1;
        done_q[dispatch0_rob_idx_o] <= 1'b0;
        pc_q[dispatch0_rob_idx_o] <= dispatch0_pc_i;
        next_pc_q[dispatch0_rob_idx_o] <= dispatch0_next_pc_i;
        inst_q[dispatch0_rob_idx_o] <= dispatch0_inst_i;
        rd_en_q[dispatch0_rob_idx_o] <= dispatch0_rd_en_i;
        is_fp_rd_q[dispatch0_rob_idx_o] <= dispatch0_is_fp_rd_i;
        fflags_q[dispatch0_rob_idx_o] <= 5'b00000;
        arch_rd_q[dispatch0_rob_idx_o] <= dispatch0_arch_rd_i;
        old_pdest_q[dispatch0_rob_idx_o] <= dispatch0_old_pdest_i;
        new_pdest_q[dispatch0_rob_idx_o] <= dispatch0_new_pdest_i;
        data_q[dispatch0_rob_idx_o] <= {`XLEN{1'b0}};
        exception_q[dispatch0_rob_idx_o] <= 1'b0;
        cause_q[dispatch0_rob_idx_o] <= {`TRAP_CAUSE_W{1'b0}};
        tval_q[dispatch0_rob_idx_o] <= {`XLEN{1'b0}};
      end
      if (dispatch1_fire_w) begin
        valid_q[dispatch1_rob_idx_o] <= 1'b1;
        done_q[dispatch1_rob_idx_o] <= 1'b0;
        pc_q[dispatch1_rob_idx_o] <= dispatch1_pc_i;
        next_pc_q[dispatch1_rob_idx_o] <= dispatch1_next_pc_i;
        inst_q[dispatch1_rob_idx_o] <= dispatch1_inst_i;
        rd_en_q[dispatch1_rob_idx_o] <= dispatch1_rd_en_i;
        is_fp_rd_q[dispatch1_rob_idx_o] <= dispatch1_is_fp_rd_i;
        fflags_q[dispatch1_rob_idx_o] <= 5'b00000;
        arch_rd_q[dispatch1_rob_idx_o] <= dispatch1_arch_rd_i;
        old_pdest_q[dispatch1_rob_idx_o] <= dispatch1_old_pdest_i;
        new_pdest_q[dispatch1_rob_idx_o] <= dispatch1_new_pdest_i;
        data_q[dispatch1_rob_idx_o] <= {`XLEN{1'b0}};
        exception_q[dispatch1_rob_idx_o] <= 1'b0;
        cause_q[dispatch1_rob_idx_o] <= {`TRAP_CAUSE_W{1'b0}};
        tval_q[dispatch1_rob_idx_o] <= {`XLEN{1'b0}};
      end

      head_q <= rob_ptr_add(head_q, commit_count_w);
      tail_q <= rob_ptr_add(tail_q, dispatch_count_w);
      count_q <= count_q + {{(ROB_COUNT_W-2){1'b0}}, dispatch_count_w} -
                 {{(ROB_COUNT_W-2){1'b0}}, commit_count_w};
    end
`ifdef ROB_WALK_DEBUG
    if (rst) rob_stall_cnt_q <= 12'd0;
    else begin
      rob_stall_cnt_q <= (count_q != {ROB_COUNT_W{1'b0}} && !commit0_fire_w) ? rob_stall_cnt_q + 12'd1 : 12'd0;
      if (rob_stall_cnt_q == 12'd2000)
        $display("[ROBSTALL] head=%0d tail=%0d count=%0d recover=%b validH=%b doneH=%b pcH=%h instH=%h commit_ready=%b kill_valid=%b",
                 head_q, tail_q, count_q, recover_q, valid_q[head_q], done_q[head_q], pc_q[head_q], inst_q[head_q], commit_ready_i, kill_valid_i);
    end
`endif
  end


endmodule
