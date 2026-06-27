`include "define.v"

module OooBranchTargetCacheControlGate (
  input mem_req_valid_i,
  input mem_req_ready_i,
  input mem_req_write_i,
  input [`XLEN-1:0] mem_req_addr_i,
  input mem1_req_valid_i,
  input mem1_req_ready_i,
  input mem1_req_write_i,
  input [`XLEN-1:0] mem1_req_addr_i,

  input core_commit0_valid_i,
  input [`INST_W-1:0] core_commit0_inst_i,
  input core_commit1_valid_i,
  input [`INST_W-1:0] core_commit1_inst_i,

  input direct_frontend_flush_i,
  input direct_branch_resolve_redirect_i,
  input direct_branch0_lane1_ret_i,
  input branch_target_dispatch_i,
  input direct_branch_resolve_taken_i,
  input direct_branch1_fire_i,
  input [`XLEN-1:0] head_pc0_i,
  input [`XLEN-1:0] head_pc1_i,

  output branch_target_store_fire_o,
  output [`XLEN-1:0] branch_target_store_addr_o,
  output branch_target_cache_invalidate_all_o,
  output branch_target_capture_arm_o,
  output [`XLEN-1:0] branch_target_capture_arm_branch_pc_o
);

  wire lane0_store_fire_w =
      mem_req_valid_i && mem_req_ready_i && mem_req_write_i;
  wire lane1_store_fire_w =
      mem1_req_valid_i && mem1_req_ready_i && mem1_req_write_i;

  assign branch_target_store_fire_o =
      lane0_store_fire_w || lane1_store_fire_w;
  assign branch_target_store_addr_o =
      lane0_store_fire_w ? mem_req_addr_i : mem1_req_addr_i;

  assign branch_target_cache_invalidate_all_o =
      (core_commit0_valid_i &&
       (core_commit0_inst_i[6:0] == `OPCODE_MISC_MEM)) ||
      (core_commit1_valid_i &&
       (core_commit1_inst_i[6:0] == `OPCODE_MISC_MEM));

  // 这里只抽出 cache/capture 的组合门控；状态更新仍由父模块和下游 buffer/cache 持有。
  assign branch_target_capture_arm_o =
      direct_frontend_flush_i &&
      direct_branch_resolve_redirect_i &&
      !direct_branch0_lane1_ret_i &&
      !branch_target_dispatch_i &&
      direct_branch_resolve_taken_i;

  assign branch_target_capture_arm_branch_pc_o =
      direct_branch1_fire_i ? head_pc1_i : head_pc0_i;

endmodule
