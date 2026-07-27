`include "define.v"
module OooStopPendingSequencer (
  input wire clk,
  input wire rst,
  input wire flush_i,

  input wire csr_trap_mem_valid_i,
  input wire direct_frontend_flush_i,
  input wire direct_branch0_fire_i,
  input wire direct_branch1_fire_i,
  input wire direct_branch_resolve_redirect_i,
  input wire branch_spec_checkpoint_capture_i,
  input wire branch_spec_resolve_valid_i,
  input wire orphan_stop_pending_i,

  input wire pending_branch_commit_resolve_i,
  input wire pending_branch_match_clear_i,
  input wire branch_resolve_untracked_i,
  input wire pending_jump_resolve_ready_i,
  input wire pending_jump_misaligned_i,
  input wire pending_jump_nolink_commit_i,
  input wire pending_jump_redirect_after_dispatch_i,
  input wire jump_dispatch_fire_i,
  input wire pending_mem_resolve_ready_i,
  input wire system_csr_dispatch_fire_i,
  input wire pending_system_csr_commit_i,
  // 【serialize-at-retire Phase1】head0-CSR 队头提交拍清 stop(它在 dispatch 拍经 dispatch0_system_i 置了
  // stop 停 younger; 提交后须清, 否则 younger 永不 dispatch → 前端死锁)。与 drain 路 pending_system_csr_commit
  // 互斥(head0 路 pending_system_csr_q=0)。flush_i 是顶层恒 0 flush, serial_flush 不经它, 故必须显式清。
  input wire head0_csr_commit_i,
  // 【serialize Phase1 §10.4】head0-CSR 在飞(dispatch→commit)期间保持 stop_pending: head0-CSR 单发 pop 后
  // 不再在 FIFO 头, dispatch0_system set 条件只 1 拍即被 drain 清 → younger CSR 越序被捕获到 drain 与在飞
  // head0-CSR 共存覆写单 pending 死锁。在飞期间强制 stop=1 阻 younger dispatch/捕获, 保证 CSR 序退休。
  input wire head0_csr_inflight_i,
  input wire head0_csr_owner_birth_i,
  input wire head0_csr_owner_kill_i,
  input wire pending_owner_birth_i,
  input wire pending_owner_live_i,
  input wire pending_system_producer_valid_i,
  input wire core_local_flush_i,
  input wire drain_complete_i,

  input wire rob_walk_mode_i,   // B2: mode=1 时 branch/jal/jump 不再起 stop_pending（改投机+ROB-walk）

  output reg stop_pending_o
);

  wire dbranch_domain_a_w = `OOO_DBRANCH_DOMAIN_A;
  wire direct_branch_stop_birth_w =
      direct_frontend_flush_i &&
      (direct_branch0_fire_i || direct_branch1_fire_i) &&
      !dbranch_domain_a_w &&
      !direct_branch_resolve_redirect_i &&
      !drain_complete_i;
  wire pending_jump_terminal_clear_w =
      !direct_frontend_flush_i && pending_jump_resolve_ready_i &&
      (pending_jump_misaligned_i ||
       pending_jump_nolink_commit_i ||
       pending_jump_redirect_after_dispatch_i);
  wire accepted_owner_birth_w =
      pending_owner_birth_i || head0_csr_owner_birth_i;

  // V9X：stop_pending 只保存“存在 serialization owner”这一位状态。
  // pending holder 的 lane/type/recovery 仲裁在 producer 侧完成；本模块不再从
  // raw dispatch 分类镜像第二套 SET 谓词。单一 priority chain 消除多个 NBA
  // 对同一寄存器的文本顺序覆盖。
  always @(posedge clk) begin
    if (rst || flush_i || core_local_flush_i) begin
      stop_pending_o <= 1'b0;
    end else if (pending_system_csr_commit_i || head0_csr_commit_i) begin
      // Exact terminal events own lease/inflight death.
      stop_pending_o <= 1'b0;
    end else if (pending_system_producer_valid_i) begin
      // A post-dispatch CSR lease rejects ordinary pre-ROB clear.  The same
      // C1 reset that clears the ROB/holder is handled at the top priority.
      stop_pending_o <= 1'b1;
    end else if (head0_csr_inflight_i && !head0_csr_owner_kill_i) begin
      // Queue-head CSR remains the owner through C0; exact older-control kill
      // or C1 reset releases it with the frontend inflight register.
      stop_pending_o <= 1'b1;
    end else if (csr_trap_mem_valid_i) begin
      stop_pending_o <= 1'b0;
    end else if (direct_frontend_flush_i &&
                 (direct_branch0_fire_i || direct_branch1_fire_i)) begin
      // Domain-A branches use ROB-walk and never create a drain stop.
      stop_pending_o <= direct_branch_stop_birth_w;
    end else if (accepted_owner_birth_w) begin
      // Birth has already passed the holder's lane/type/recovery arbitration.
      stop_pending_o <= 1'b1;
    end else if ((!direct_frontend_flush_i &&
                  (branch_spec_checkpoint_capture_i ||
                   branch_spec_resolve_valid_i ||
                   branch_resolve_untracked_i)) ||
                 orphan_stop_pending_i ||
                 pending_branch_commit_resolve_i ||
                 pending_branch_match_clear_i ||
                 head0_csr_owner_kill_i ||
                 pending_jump_terminal_clear_w) begin
      stop_pending_o <= 1'b0;
    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i) begin
      stop_pending_o <= 1'b0;
    end
  end

  // These legacy level-ready inputs deliberately do not alter owner state.
  // They remain in the interface until the surrounding dead pending branch /
  // jump / memory consumers are removed in their own bounded slice.
  wire legacy_hold_inputs_unused_w =
      jump_dispatch_fire_i ||
      pending_mem_resolve_ready_i ||
      system_csr_dispatch_fire_i ||
      rob_walk_mode_i;

`ifdef OOO_ASSERT
  reg stop_pending_prev_q;
  reg accepted_owner_birth_prev_q;
  always @(posedge clk) begin
    if (rst || flush_i || core_local_flush_i) begin
      stop_pending_prev_q <= 1'b0;
      accepted_owner_birth_prev_q <= 1'b0;
    end else begin
      if (rob_walk_mode_i && !stop_pending_prev_q && stop_pending_o &&
          !accepted_owner_birth_prev_q) begin
        $error("[V9X-STOP-BIRTH-WITNESS] stop rose without accepted holder/queue-head birth @%0t",
               $time);
        $fatal;
      end
      if (pending_system_producer_valid_i && !stop_pending_o) begin
        $error("[V9X-STOP-LEASE-HOLD] exact pending CSR lease lost stop owner @%0t",
               $time);
        $fatal;
      end
      if (head0_csr_inflight_i &&
          !head0_csr_owner_kill_i && !stop_pending_o) begin
        $error("[V9X-STOP-QCSR-HOLD] queue-head CSR inflight lost stop owner @%0t",
               $time);
        $fatal;
      end
      if (rob_walk_mode_i && stop_pending_o &&
          !pending_owner_live_i &&
          !pending_system_producer_valid_i &&
          !head0_csr_inflight_i) begin
        $error("[V9X-STOP-OWNER-LIVE] stop_pending has no registered serialization owner @%0t",
               $time);
        $fatal;
      end
      stop_pending_prev_q <= stop_pending_o;
      accepted_owner_birth_prev_q <=
          accepted_owner_birth_w || direct_branch_stop_birth_w;
    end
  end
`endif

endmodule
