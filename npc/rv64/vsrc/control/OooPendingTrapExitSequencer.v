`include "include/define.v"

module OooPendingTrapExitSequencer (
  input wire clk,
  input wire rst,

  input wire late_clear_i,
  input wire clear_exit_i,
  input wire clear_arch_i,
  input wire clear_arch_squash_i,

  input wire capture_exit_i,
  input wire capture_exit_valid_i,
  input wire capture_exit_is_ecall_i,
  input wire capture_exit_is_ebreak_i,

  input wire capture_arch_i,
  input wire capture_arch_valid_i,
  input wire [`TRAP_CAUSE_W-1:0] capture_trap_cause_i,
  input wire [`XLEN-1:0] capture_trap_pc_i,
  input wire [`XLEN-1:0] capture_trap_tval_i,

  output reg pending_exit_o,
  output reg pending_exit_is_ecall_o,
  output reg pending_exit_is_ebreak_o,
  output reg pending_arch_trap_o,
  output reg [`TRAP_CAUSE_W-1:0] pending_trap_cause_o,
  output reg [`XLEN-1:0] pending_trap_pc_o,
  output reg [`XLEN-1:0] pending_trap_tval_o
);

  always @(posedge clk) begin
    if (rst) begin
      pending_exit_o <= 1'b0;
      pending_exit_is_ecall_o <= 1'b0;
      pending_exit_is_ebreak_o <= 1'b0;
      pending_arch_trap_o <= 1'b0;
      pending_trap_cause_o <= {`TRAP_CAUSE_W{1'b0}};
      pending_trap_pc_o <= {`XLEN{1'b0}};
      pending_trap_tval_o <= {`XLEN{1'b0}};
    end else begin
      if (clear_exit_i) begin
        pending_exit_o <= 1'b0;
        pending_exit_is_ecall_o <= 1'b0;
        pending_exit_is_ebreak_o <= 1'b0;
      end

      if (clear_arch_i) begin
        // B2 mode=1: 普通 clear_arch 只清 pending_arch_trap; 当 clear 来自 squash(branch
        // resolve/untracked redirect jr-ret/frontend flush)时, 被清的 arch trap 是投机
        // wrong-path(如越过 printf ret 取到 .text 段尾之后的 head illegal), 一并清 cause/pc/tval
        // 的 residual, 否则被 drain 出口的 drain_trap_payload(pc!=0)误用 → CoreMark spurious
        // illegal trap。drain 出口的 clear(非 squash)是真实 trap fire 时, 保留 cause/pc 供
        // trap handler 读 scause/sepc(sv39 page fault/ecall)。
        pending_arch_trap_o <= 1'b0;
        // GAP-6 root-cause 修(2026-07-05): 删原 `&& cause==EXC_ILLEGAL_INST` 症状补丁。
        // squash 的 arch trap 必来自投机 wrong-path, 其 payload 应与 validity 位(上面:55 无条件清)
        // 一起作废——不论 cause。原 ILLEGAL gate 是当初为 CoreMark ILLEGAL 个案打的补丁, 使非-illegal
        // wrong-path fetch-fault residual 残留(实测 sv39 boot 触发 cause=12 INST_PAGE_FAULT residual
        // 7 次) → drain_trap_payload(pc!=0)可误 fire spurious page-fault trap。真实 trap 走非-squash
        // 的 late_clear / drain-clear 路径(不在 squash 源里), scause/sepc 照旧保留。
        if (clear_arch_squash_i) begin
          pending_trap_cause_o <= {`TRAP_CAUSE_W{1'b0}};
          pending_trap_pc_o <= {`XLEN{1'b0}};
          pending_trap_tval_o <= {`XLEN{1'b0}};
        end
      end

      if (capture_exit_i) begin
        pending_exit_o <= capture_exit_valid_i;
        pending_exit_is_ecall_o <= capture_exit_is_ecall_i;
        pending_exit_is_ebreak_o <= capture_exit_is_ebreak_i;
      end

      if (capture_arch_i) begin
        pending_arch_trap_o <= capture_arch_valid_i;
        pending_trap_cause_o <= capture_trap_cause_i;
        pending_trap_pc_o <= capture_trap_pc_i;
        pending_trap_tval_o <= capture_trap_tval_i;
      end

      if (late_clear_i) begin
        pending_exit_o <= 1'b0;
        pending_exit_is_ecall_o <= 1'b0;
        pending_exit_is_ebreak_o <= 1'b0;
        pending_arch_trap_o <= 1'b0;
        pending_trap_cause_o <= {`TRAP_CAUSE_W{1'b0}};
        pending_trap_pc_o <= {`XLEN{1'b0}};
        pending_trap_tval_o <= {`XLEN{1'b0}};
      end
    end
  end

`ifdef OOO_ASSERT
  // GAP-6 payload-lifetime 不变量 (flush 契约 §4)：squash 清 arch trap(validity 位:55 无条件归0)
  // 后, 若同拍无 capture_arch/late_clear 覆写, 下一拍 trap payload(cause/pc/tval)必须全 0——
  // payload 生命周期须对齐 validity 位。修前(:59-60 有 cause==ILLEGAL gate)非-illegal wrong-path
  // fetch-fault(page/access/breakpoint) residual 会残留 → 此断言 fire; 删 gate 后恒静默。
  reg gap6_squash_noload_q;
  always @(posedge clk)
    gap6_squash_noload_q <= !rst && clear_arch_i && clear_arch_squash_i &&
                            !capture_arch_i && !late_clear_i;
  always @(posedge clk) if (!rst && gap6_squash_noload_q)
    if ((pending_trap_cause_o !== {`TRAP_CAUSE_W{1'b0}}) ||
        (pending_trap_pc_o   !== {`XLEN{1'b0}}) ||
        (pending_trap_tval_o !== {`XLEN{1'b0}}))
      $error("[FLUSH-CONTRACT GAP-6] squash 清 arch trap 后 payload 残留: cause=%h pc=%h tval=%h @%0t",
             pending_trap_cause_o, pending_trap_pc_o, pending_trap_tval_o, $time);
`endif

endmodule
