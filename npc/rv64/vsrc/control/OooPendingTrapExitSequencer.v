`include "include/define.v"

module OooPendingTrapExitSequencer (
  input wire clk,
  input wire rst,

  input wire late_clear_i,
  input wire clear_exit_i,
  input wire clear_arch_i,

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
        pending_arch_trap_o <= 1'b0;
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
