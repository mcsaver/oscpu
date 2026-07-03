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
  input wire drain_complete_i,

  input wire can_run_i,
  input wire fifo_has_packet_i,
  input wire csr_irq_pending_i,
  input wire head_fetch_fault0_i,
  input wire dispatch0_arch_trap_i,
  input wire dispatch0_exit_i,
  // 【B-FP 簇】FP 迁域 A: head0=FP 与普通指令同构, 不再参与 stop_pending 决策
  // (旧 fp 臂在 lane1 barrier fire 拍抢先把 stop_pending 写 0, 使同包 lane1
  // capture 的 CSR 指令永远等不到 drain→注入)。端口保留避免上层接线扰动。
  input wire dispatch0_fp_i,
  input wire dispatch0_system_i,
  input wire head0_csr_illegal_i,
  input wire dispatch0_branch_i,
  input wire direct_branch0_dispatch_valid_i,
  input wire dispatch0_jal_i,
  input wire direct_jal0_dispatch_valid_i,
  input wire dispatch0_jump_i,
  input wire dispatch0_return_i,
  input wire dispatch1_barrier_fire_i,
  input wire dispatch_unsupported_i,
  input wire rob_walk_mode_i,   // B2: mode=1 时 branch/jal/jump 不再起 stop_pending（改投机+ROB-walk）

  output reg stop_pending_o
);

  wire dbranch_domain_a_w = `OOO_DBRANCH_DOMAIN_A;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      stop_pending_o <= 1'b0;
    end else begin
      if (csr_trap_mem_valid_i) begin
        stop_pending_o <= 1'b0;
      end else if (direct_frontend_flush_i) begin
        if (direct_branch0_fire_i || direct_branch1_fire_i) begin
          // domain-A(#105 总闸拆除): 分支现经普通 dispatch 进 ROB 按序提交, 由后端
          // resolve + pred_npc 比对 + ROB-walk kill 保证正确性, 不再需要 stop+全 drain。
          // (旧 direct+drain 模型: 预测正确也 stop+drain, 占 99.997% stop 事件。)
          stop_pending_o <= dbranch_domain_a_w ? 1'b0 :
              (!direct_branch_resolve_redirect_i && !drain_complete_i);
        end
      end

      if (!direct_frontend_flush_i && branch_spec_checkpoint_capture_i) begin
        stop_pending_o <= 1'b0;
      end

      if (!direct_frontend_flush_i && branch_spec_resolve_valid_i) begin
        stop_pending_o <= 1'b0;
      end

      if (orphan_stop_pending_i) begin
        stop_pending_o <= 1'b0;
      end

      if (pending_branch_commit_resolve_i) begin
        stop_pending_o <= 1'b0;
      end else if (pending_branch_match_clear_i) begin
        stop_pending_o <= 1'b0;
      end else if (!direct_frontend_flush_i && branch_resolve_untracked_i) begin
        stop_pending_o <= 1'b0;
      end else if (!direct_frontend_flush_i && pending_jump_resolve_ready_i) begin
        if (pending_jump_misaligned_i) begin
          stop_pending_o <= 1'b0;
        end else if (pending_jump_nolink_commit_i) begin
          stop_pending_o <= 1'b0;
        end else if (pending_jump_redirect_after_dispatch_i) begin
          stop_pending_o <= 1'b0;
        end else if (jump_dispatch_fire_i) begin
          // Hold this priority slot; target/dispatched state is owned elsewhere.
        end
      end else if (!direct_frontend_flush_i && pending_mem_resolve_ready_i) begin
        // Hold this priority slot; pending memory state is owned elsewhere.
      end else if (!direct_frontend_flush_i && system_csr_dispatch_fire_i) begin
        // Hold this priority slot; pending SYSTEM dispatched state is owned elsewhere.
      end else if (!direct_frontend_flush_i && pending_system_csr_commit_i) begin
        stop_pending_o <= 1'b0;
      end else if (!csr_trap_mem_valid_i &&
          !direct_frontend_flush_i && stop_pending_o && drain_complete_i) begin
        stop_pending_o <= 1'b0;
      end else if (!csr_trap_mem_valid_i &&
          !direct_frontend_flush_i && can_run_i && fifo_has_packet_i) begin
        if (csr_irq_pending_i) begin
          stop_pending_o <= 1'b1;
        end else if (head_fetch_fault0_i) begin
          // fetch fault(inst access/page fault)stop_pending → drain → arch trap。
          // mode=1 也 capture:投机 wrong-path fetch fault(CoreMark 越界 access fault)的
          // residual 由 OooPendingTrapExitSequencer 的 clear_arch_squash cause-gate 在被
          // mispredict squash 时清掉;真实 fetch fault(sv39 S-mode inst page fault cause=12,
          // 不被 squash)保留 → 正常 trap。这样 sv39 boot 与 CoreMark 同时成立。
          stop_pending_o <= 1'b1;
        end else if (dispatch0_arch_trap_i) begin
          stop_pending_o <= 1'b1;
        end else if (dispatch0_exit_i) begin
          stop_pending_o <= 1'b1;
        end else if (dispatch0_system_i && head0_csr_illegal_i) begin
          stop_pending_o <= 1'b1;
        end else if (dispatch0_system_i) begin
          stop_pending_o <= 1'b1;
        end else if (dispatch0_branch_i && !direct_branch0_dispatch_valid_i &&
                     !rob_walk_mode_i) begin
          stop_pending_o <= 1'b1;
        end else if (((dispatch0_jal_i && !direct_jal0_dispatch_valid_i) ||
                      (dispatch0_jump_i && !dispatch0_return_i)) &&
                     !rob_walk_mode_i) begin
          stop_pending_o <= 1'b1;
        end else if (dispatch1_barrier_fire_i) begin
          stop_pending_o <= 1'b1;
        end else if (dispatch_unsupported_i) begin
          stop_pending_o <= 1'b1;
        end
      end

      if (csr_trap_mem_valid_i) begin
        stop_pending_o <= 1'b0;
      end
    end
  end
  wire dispatch0_fp_unused_w = dispatch0_fp_i;

endmodule
