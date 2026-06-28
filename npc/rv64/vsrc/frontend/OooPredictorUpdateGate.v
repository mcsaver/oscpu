`include "define.v"

// Predictor 更新事件由 frontend 产生，避免 core glue 直接拼 BTB/cache 条件。
module OooPredictorUpdateGate (
  input branch_target_capture_hit_i,
  input branch_target_capture_safe_i,
  input pending_jump_resolve_ready_i,
  input pending_jump_jalr_i,
  input pending_jump_misaligned_i,

  output branch_target_cache_capture_o,
  output jalr_btb_update_o
);

  assign branch_target_cache_capture_o =
      branch_target_capture_hit_i && branch_target_capture_safe_i;
  assign jalr_btb_update_o =
      pending_jump_resolve_ready_i && pending_jump_jalr_i &&
      !pending_jump_misaligned_i;

endmodule
