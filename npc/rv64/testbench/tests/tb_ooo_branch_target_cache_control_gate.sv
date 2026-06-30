`include "define.v"

module tb_ooo_branch_target_cache_control_gate;
  `include "tb_common.svh"

  reg mem_req_valid;
  reg mem_req_ready;
  reg mem_req_write;
  reg [`XLEN-1:0] mem_req_addr;

  reg core_commit0_valid;
  reg [`INST_W-1:0] core_commit0_inst;
  reg core_commit1_valid;
  reg [`INST_W-1:0] core_commit1_inst;

  reg direct_frontend_flush;
  reg direct_branch_resolve_redirect;
  reg direct_branch0_lane1_ret;
  reg branch_target_dispatch;
  reg direct_branch_resolve_taken;
  reg direct_branch1_fire;
  reg [`XLEN-1:0] head_pc0;
  reg [`XLEN-1:0] head_pc1;

  wire branch_target_store_fire;
  wire [`XLEN-1:0] branch_target_store_addr;
  wire branch_target_cache_invalidate_all;
  wire branch_target_capture_arm;
  wire [`XLEN-1:0] branch_target_capture_arm_branch_pc;

  OooBranchTargetCacheControlGate dut (
    .mem_req_valid_i(mem_req_valid),
    .mem_req_ready_i(mem_req_ready),
    .mem_req_write_i(mem_req_write),
    .mem_req_addr_i(mem_req_addr),
    .core_commit0_valid_i(core_commit0_valid),
    .core_commit0_inst_i(core_commit0_inst),
    .core_commit1_valid_i(core_commit1_valid),
    .core_commit1_inst_i(core_commit1_inst),
    .direct_frontend_flush_i(direct_frontend_flush),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret),
    .branch_target_dispatch_i(branch_target_dispatch),
    .direct_branch_resolve_taken_i(direct_branch_resolve_taken),
    .direct_branch1_fire_i(direct_branch1_fire),
    .head_pc0_i(head_pc0),
    .head_pc1_i(head_pc1),
    .branch_target_store_fire_o(branch_target_store_fire),
    .branch_target_store_addr_o(branch_target_store_addr),
    .branch_target_cache_invalidate_all_o(branch_target_cache_invalidate_all),
    .branch_target_capture_arm_o(branch_target_capture_arm),
    .branch_target_capture_arm_branch_pc_o(branch_target_capture_arm_branch_pc)
  );

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      mem_req_valid = 1'b0;
      mem_req_ready = 1'b0;
      mem_req_write = 1'b0;
      mem_req_addr = 64'h0000_0000_8000_1000;
      core_commit0_valid = 1'b0;
      core_commit0_inst = 32'h0000_0013;
      core_commit1_valid = 1'b0;
      core_commit1_inst = 32'h0000_0013;
      direct_frontend_flush = 1'b0;
      direct_branch_resolve_redirect = 1'b0;
      direct_branch0_lane1_ret = 1'b0;
      branch_target_dispatch = 1'b0;
      direct_branch_resolve_taken = 1'b0;
      direct_branch1_fire = 1'b0;
      head_pc0 = 64'h0000_0000_8000_0100;
      head_pc1 = 64'h0000_0000_8000_0104;
    end
  endtask

  task automatic set_capture_ready;
    begin
      direct_frontend_flush = 1'b1;
      direct_branch_resolve_redirect = 1'b1;
      direct_branch0_lane1_ret = 1'b0;
      branch_target_dispatch = 1'b0;
      direct_branch_resolve_taken = 1'b1;
    end
  endtask

  initial begin
    tb_errors = 0;
    clear_inputs();
    #1;
    tb_check1("idle store fire", branch_target_store_fire, 1'b0);
    // mem1(双发射 load 第二端口)死硅删除后,store addr 恒取 mem0 端口地址。
    tb_check64("idle store addr from lane0",
               branch_target_store_addr, 64'h0000_0000_8000_1000);

    clear_inputs();
    mem_req_valid = 1'b1;
    mem_req_ready = 1'b1;
    mem_req_write = 1'b1;
    mem_req_addr = 64'h0000_0000_8000_1118;
    #1;
    tb_check1("lane0 store fire", branch_target_store_fire, 1'b1);
    tb_check64("lane0 store addr priority",
               branch_target_store_addr, 64'h0000_0000_8000_1118);

    clear_inputs();
    mem_req_valid = 1'b1;
    mem_req_ready = 1'b1;
    mem_req_write = 1'b0;
    #1;
    tb_check1("store handshake requires write and ready",
              branch_target_store_fire, 1'b0);

    clear_inputs();
    core_commit0_valid = 1'b1;
    core_commit0_inst = {25'h0, `OPCODE_MISC_MEM};
    #1;
    tb_check1("commit0 misc-mem invalidates",
              branch_target_cache_invalidate_all, 1'b1);

    clear_inputs();
    core_commit1_valid = 1'b1;
    core_commit1_inst = {25'h0, `OPCODE_MISC_MEM};
    #1;
    tb_check1("commit1 misc-mem invalidates",
              branch_target_cache_invalidate_all, 1'b1);

    clear_inputs();
    core_commit0_valid = 1'b1;
    core_commit0_inst = 32'h0000_0013;
    core_commit1_valid = 1'b1;
    core_commit1_inst = 32'h0000_0013;
    #1;
    tb_check1("non misc-mem does not invalidate",
              branch_target_cache_invalidate_all, 1'b0);

    clear_inputs();
    set_capture_ready();
    #1;
    tb_check1("capture arm positive", branch_target_capture_arm, 1'b1);
    tb_check64("capture arm lane0 pc",
               branch_target_capture_arm_branch_pc,
               64'h0000_0000_8000_0100);

    direct_branch1_fire = 1'b1;
    #1;
    tb_check64("capture arm lane1 pc",
               branch_target_capture_arm_branch_pc,
               64'h0000_0000_8000_0104);

    direct_frontend_flush = 1'b0;
    #1;
    tb_check1("no flush blocks capture", branch_target_capture_arm, 1'b0);
    set_capture_ready();
    direct_branch_resolve_redirect = 1'b0;
    #1;
    tb_check1("no redirect blocks capture", branch_target_capture_arm, 1'b0);
    set_capture_ready();
    direct_branch_resolve_taken = 1'b0;
    #1;
    tb_check1("not taken blocks capture", branch_target_capture_arm, 1'b0);
    set_capture_ready();
    direct_branch0_lane1_ret = 1'b1;
    #1;
    tb_check1("lane1 ret blocks capture", branch_target_capture_arm, 1'b0);
    set_capture_ready();
    branch_target_dispatch = 1'b1;
    #1;
    tb_check1("branch target dispatch blocks capture",
              branch_target_capture_arm, 1'b0);

    tb_finish("tb_ooo_branch_target_cache_control_gate");
  end
endmodule
