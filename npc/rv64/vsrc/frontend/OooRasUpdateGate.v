`include "define.v"

module OooRasUpdateGate (
  input priv_predictor_boundary_i,
  input branch_spec_restore_i,
  input branch_resolve_untracked_i,
  input direct_jal_call_unsafe_i,

  input direct_ret0_fire_i,
  input direct_ret1_fire_i,
  input pending_jump_return_fire_i,
  input direct_branch0_lane1_ret_i,

  input direct_jal_call_i,
  input pending_jump_call_fire_i,
  input [`XLEN-1:0] pending_jump_next_pc_i,
  input [`XLEN-1:0] direct_jal_link_i,

  output ras_clear_o,
  output ras_pop_o,
  output ras_push_o,
  output [`XLEN-1:0] ras_push_value_o
);

  assign ras_clear_o =
      priv_predictor_boundary_i ||
      branch_spec_restore_i ||
      branch_resolve_untracked_i ||
      direct_jal_call_unsafe_i;

  assign ras_pop_o =
      direct_ret0_fire_i ||
      direct_ret1_fire_i ||
      pending_jump_return_fire_i ||
      direct_branch0_lane1_ret_i;

  assign ras_push_o = direct_jal_call_i || pending_jump_call_fire_i;
  assign ras_push_value_o =
      pending_jump_call_fire_i ? pending_jump_next_pc_i : direct_jal_link_i;

endmodule
