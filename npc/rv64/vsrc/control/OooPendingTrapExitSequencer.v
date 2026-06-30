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
        // 仅清 ILLEGAL residual: CoreMark 越过 ret 取到 .text 段尾之后的投机 head decode
        // illegal(cause=2)被 jr/ret squash 后 cause/pc 残留 → drain_trap_payload 误用。其他
        // cause(page fault/ecall/load fault)保留 cause/pc, trap handler 仍可读 scause/sepc。
        if (clear_arch_squash_i &&
            (pending_trap_cause_o == `EXC_ILLEGAL_INST)) begin
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

endmodule
