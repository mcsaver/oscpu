// Pure combinational source facts for branch/JALR prefetch.
`include "define.v"

module OooBranchPrefetchSourceGate (
  input [`XLEN-1:0] pending_branch_pc_i,
  input [`XLEN-1:0] pending_branch_imm_i,
  input [`XLEN-1:0] pending_branch_next_pc_i,
  input pending_branch_pred_taken_i,
  input stop_pending_i,
  input pending_jump_i,
  input pending_jump_jalr_i,
  input [`REG_ADDR_W-1:0] pending_jump_rd_i,
  input [`REG_ADDR_W-1:0] pending_jump_rs1_i,
  input [`XLEN-1:0] pending_jump_imm_i,
  input ras_empty_i,

  output [`XLEN-1:0] pending_branch_target_o,
  output [`XLEN-1:0] branch_pred_pc_o,
  output jalr_ret_hint_o,
  output jalr_btb_lookup_o
);

  assign pending_branch_target_o =
      pending_branch_pc_i + pending_branch_imm_i;

  assign branch_pred_pc_o =
      pending_branch_pred_taken_i ? pending_branch_target_o :
                                    pending_branch_next_pc_i;

  assign jalr_ret_hint_o =
      pending_jump_i &&
      pending_jump_jalr_i &&
      (pending_jump_rd_i == {`REG_ADDR_W{1'b0}}) &&
      ((pending_jump_rs1_i == 5'd1) || (pending_jump_rs1_i == 5'd5)) &&
      (pending_jump_imm_i == {`XLEN{1'b0}});

  assign jalr_btb_lookup_o =
      stop_pending_i &&
      pending_jump_i &&
      pending_jump_jalr_i &&
      !(jalr_ret_hint_o && !ras_empty_i);

endmodule
