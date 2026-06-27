`include "define.v"
`include "tb_common.svh"

module tb_ooo_fetch_request_mux;
  reg outstanding_valid;
  reg fetch_rsp_fire;
  reg [`XLEN-1:0] fetch_rsp_packet_next_pc;
  reg [`XLEN-1:0] next_fetch_pc;
  reg direct_jal_fire;
  reg direct_ret0_fire;
  reg direct_ret1_fire;
  reg direct_branch0_lane1_ret;
  reg pending_jump_nolink_commit;
  reg pending_jump_redirect_after_dispatch;
  reg direct_branch_resolve_redirect;
  reg branch_resolve_redirect;
  reg branch_spec_redirect;
  reg branch_resolve_untracked_redirect;
  reg branch_fallthrough_dispatch;
  reg branch_fallthrough_outstanding_match;
  reg return_cont_dispatch;
  reg [`XLEN-1:0] return_cont_next_pc;
  reg [`XLEN-1:0] ras_top;
  reg branch_target_dispatch;
  reg [`XLEN-1:0] branch_target_cache_next_pc;
  reg [`XLEN-1:0] head_next_pc1;
  reg [`XLEN-1:0] direct_jal_target;
  reg [`XLEN-1:0] direct_ret_target;
  reg [`XLEN-1:0] direct_branch_resolve_next_pc;
  reg [`XLEN-1:0] pending_jump_resolved_target;
  reg [`XLEN-1:0] core_branch_resolve_next_pc;
  reg branch_prefetch_req_valid;
  reg [`XLEN-1:0] branch_prefetch_req_pc;

  wire direct_redirect_fetch;
  wire redirect_fetch_req_valid;
  wire [`XLEN-1:0] redirect_fetch_pc;
  wire [`XLEN-1:0] fetch_req_pc;

  OooFetchRequestMux dut (
    .outstanding_valid_i(outstanding_valid),
    .fetch_rsp_fire_i(fetch_rsp_fire),
    .fetch_rsp_packet_next_pc_i(fetch_rsp_packet_next_pc),
    .next_fetch_pc_i(next_fetch_pc),
    .direct_jal_fire_i(direct_jal_fire),
    .direct_ret0_fire_i(direct_ret0_fire),
    .direct_ret1_fire_i(direct_ret1_fire),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit),
    .pending_jump_redirect_after_dispatch_i(
        pending_jump_redirect_after_dispatch),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect),
    .branch_resolve_redirect_i(branch_resolve_redirect),
    .branch_spec_redirect_i(branch_spec_redirect),
    .branch_resolve_untracked_redirect_i(branch_resolve_untracked_redirect),
    .branch_fallthrough_dispatch_i(branch_fallthrough_dispatch),
    .branch_fallthrough_outstanding_match_i(
        branch_fallthrough_outstanding_match),
    .return_cont_dispatch_i(return_cont_dispatch),
    .return_cont_next_pc_i(return_cont_next_pc),
    .ras_top_i(ras_top),
    .branch_target_dispatch_i(branch_target_dispatch),
    .branch_target_cache_next_pc_i(branch_target_cache_next_pc),
    .head_next_pc1_i(head_next_pc1),
    .direct_jal_target_i(direct_jal_target),
    .direct_ret_target_i(direct_ret_target),
    .direct_branch_resolve_next_pc_i(direct_branch_resolve_next_pc),
    .pending_jump_resolved_target_i(pending_jump_resolved_target),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc),
    .branch_prefetch_req_valid_i(branch_prefetch_req_valid),
    .branch_prefetch_req_pc_i(branch_prefetch_req_pc),
    .direct_redirect_fetch_o(direct_redirect_fetch),
    .redirect_fetch_req_valid_o(redirect_fetch_req_valid),
    .redirect_fetch_pc_o(redirect_fetch_pc),
    .fetch_req_pc_o(fetch_req_pc)
  );

  task automatic check_xlen;
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

  task automatic reset_inputs;
    begin
      outstanding_valid = 1'b0;
      fetch_rsp_fire = 1'b0;
      fetch_rsp_packet_next_pc = 64'h0000_0000_0000_1100;
      next_fetch_pc = 64'h0000_0000_0000_1000;
      direct_jal_fire = 1'b0;
      direct_ret0_fire = 1'b0;
      direct_ret1_fire = 1'b0;
      direct_branch0_lane1_ret = 1'b0;
      pending_jump_nolink_commit = 1'b0;
      pending_jump_redirect_after_dispatch = 1'b0;
      direct_branch_resolve_redirect = 1'b0;
      branch_resolve_redirect = 1'b0;
      branch_spec_redirect = 1'b0;
      branch_resolve_untracked_redirect = 1'b0;
      branch_fallthrough_dispatch = 1'b0;
      branch_fallthrough_outstanding_match = 1'b0;
      return_cont_dispatch = 1'b0;
      return_cont_next_pc = 64'h0000_0000_0000_2200;
      ras_top = 64'h0000_0000_0000_2300;
      branch_target_dispatch = 1'b0;
      branch_target_cache_next_pc = 64'h0000_0000_0000_2400;
      head_next_pc1 = 64'h0000_0000_0000_2500;
      direct_jal_target = 64'h0000_0000_0000_3000;
      direct_ret_target = 64'h0000_0000_0000_3100;
      direct_branch_resolve_next_pc = 64'h0000_0000_0000_3200;
      pending_jump_resolved_target = 64'h0000_0000_0000_3300;
      core_branch_resolve_next_pc = 64'h0000_0000_0000_3400;
      branch_prefetch_req_valid = 1'b0;
      branch_prefetch_req_pc = 64'h0000_0000_0000_4000;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    check_xlen("idle uses next fetch pc", fetch_req_pc, next_fetch_pc);
    tb_check1("idle redirect invalid", redirect_fetch_req_valid, 1'b0);

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_fire = 1'b1;
    #1;
    check_xlen("response fire advances seq pc", fetch_req_pc,
               fetch_rsp_packet_next_pc);

    reset_inputs();
    branch_prefetch_req_valid = 1'b1;
    #1;
    check_xlen("prefetch beats seq", fetch_req_pc, branch_prefetch_req_pc);

    reset_inputs();
    branch_prefetch_req_valid = 1'b1;
    direct_jal_fire = 1'b1;
    #1;
    tb_check1("direct jal is direct redirect", direct_redirect_fetch, 1'b1);
    tb_check1("direct jal redirect valid", redirect_fetch_req_valid, 1'b1);
    check_xlen("redirect beats prefetch", fetch_req_pc, direct_jal_target);

    reset_inputs();
    direct_ret1_fire = 1'b1;
    #1;
    check_xlen("return target selected", redirect_fetch_pc,
               direct_ret_target);

    reset_inputs();
    direct_branch0_lane1_ret = 1'b1;
    return_cont_dispatch = 1'b1;
    #1;
    check_xlen("lane1 ret uses return continuation", redirect_fetch_pc,
               return_cont_next_pc);

    reset_inputs();
    direct_branch0_lane1_ret = 1'b1;
    return_cont_dispatch = 1'b0;
    #1;
    check_xlen("lane1 ret falls back to ras", redirect_fetch_pc, ras_top);

    reset_inputs();
    branch_resolve_redirect = 1'b1;
    branch_target_dispatch = 1'b1;
    #1;
    check_xlen("branch target cache target selected", redirect_fetch_pc,
               branch_target_cache_next_pc);

    reset_inputs();
    branch_resolve_redirect = 1'b1;
    branch_fallthrough_dispatch = 1'b1;
    #1;
    check_xlen("branch fallthrough target selected", redirect_fetch_pc,
               head_next_pc1);

    reset_inputs();
    direct_branch_resolve_redirect = 1'b1;
    #1;
    check_xlen("direct branch resolve target selected", redirect_fetch_pc,
               direct_branch_resolve_next_pc);

    reset_inputs();
    pending_jump_redirect_after_dispatch = 1'b1;
    #1;
    check_xlen("pending jump target selected", redirect_fetch_pc,
               pending_jump_resolved_target);

    reset_inputs();
    branch_spec_redirect = 1'b1;
    #1;
    check_xlen("branch spec restore target selected", redirect_fetch_pc,
               core_branch_resolve_next_pc);

    reset_inputs();
    direct_jal_fire = 1'b1;
    direct_ret0_fire = 1'b1;
    #1;
    check_xlen("direct jal priority over ret", redirect_fetch_pc,
               direct_jal_target);

    reset_inputs();
    direct_jal_fire = 1'b1;
    outstanding_valid = 1'b1;
    fetch_rsp_fire = 1'b0;
    #1;
    tb_check1("outstanding blocks redirect request", redirect_fetch_req_valid,
              1'b0);
    check_xlen("blocked redirect falls to seq", fetch_req_pc, next_fetch_pc);

    reset_inputs();
    direct_jal_fire = 1'b1;
    outstanding_valid = 1'b1;
    fetch_rsp_fire = 1'b1;
    #1;
    tb_check1("response fire unblocks redirect", redirect_fetch_req_valid,
              1'b1);
    check_xlen("unblocked redirect wins", fetch_req_pc, direct_jal_target);

    reset_inputs();
    branch_resolve_redirect = 1'b1;
    branch_fallthrough_dispatch = 1'b1;
    branch_fallthrough_outstanding_match = 1'b1;
    #1;
    tb_check1("fallthrough outstanding suppresses redirect",
              redirect_fetch_req_valid, 1'b0);

    tb_finish("tb_ooo_fetch_request_mux");
  end

endmodule
