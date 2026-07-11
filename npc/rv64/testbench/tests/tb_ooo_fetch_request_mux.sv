`include "define.v"
`include "tb_common.svh"

// 【P4 切消费点(2026-07-09)】redirect PC 真源已收敛 OooRedirectArbiter(OooFrontend 内),
// 本 TB 口径同步: PC 侧 = redirect_valid/redirect_pc 单源透传 + core_branch_resolve_next_pc
// 兜底(原 first-match 三元链已删); valid/流控侧(direct_redirect_fetch/
// redirect_fetch_req_valid/fetch_req_pc 三段)语义未动, 用例保留。
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
  reg [`XLEN-1:0] core_branch_resolve_next_pc;
  reg branch_prefetch_req_valid;
  reg [`XLEN-1:0] branch_prefetch_req_pc;
  reg direct_jump_spec_fire;
  reg redirect_valid;
  reg [`XLEN-1:0] redirect_pc;

  wire direct_redirect_fetch;
  wire redirect_fetch_req_valid;
  wire resolve_redirect_block;
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
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc),
    .branch_prefetch_req_valid_i(branch_prefetch_req_valid),
    .branch_prefetch_req_pc_i(branch_prefetch_req_pc),
    .direct_jump_spec_fire_i(direct_jump_spec_fire),
    .redirect_valid_i(redirect_valid),
    .redirect_pc_i(redirect_pc),
    .direct_redirect_fetch_o(direct_redirect_fetch),
    .redirect_fetch_req_valid_o(redirect_fetch_req_valid),
    .resolve_redirect_block_o(resolve_redirect_block),
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
      core_branch_resolve_next_pc = 64'h0000_0000_0000_3400;
      branch_prefetch_req_valid = 1'b0;
      branch_prefetch_req_pc = 64'h0000_0000_0000_4000;
      direct_jump_spec_fire = 1'b0;
      redirect_valid = 1'b0;
      redirect_pc = 64'h0000_0000_0000_5000;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    // ── 顺序/prefetch 档(未动) ──
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

    // ── PC 单源透传: arbiter 赢家拍 redirect_fetch_pc = redirect_pc ──
    reset_inputs();
    branch_prefetch_req_valid = 1'b1;
    direct_jal_fire = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_0000_3000;   // arbiter direct 赢家(e4 构造式)
    #1;
    tb_check1("direct jal is direct redirect", direct_redirect_fetch, 1'b1);
    // 【redirect 防火墙契约】同拍发射退役: valid 恒 0, direct fire 体现在 block 源
    tb_check1("firewall: jal no same-cycle fire", redirect_fetch_req_valid, 1'b0);
    tb_check1("firewall: jal raises direct block", direct_redirect_fetch, 1'b1);
    // 防火墙: redirect 拍请求被 block 不发, fetch_req_pc 该拍 don't-care

    reset_inputs();
    direct_ret1_fire = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_0000_3100;
    #1;
    check_xlen("arb winner pc passes through", redirect_fetch_pc, redirect_pc);

    reset_inputs();
    branch_resolve_untracked_redirect = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = core_branch_resolve_next_pc;  // branch 口赢家 = resolve 真 target
    #1;
    // 【时序 T1 契约反转】resolve 族不再同拍发取指——block 信号封顺序臂, 次拍发 target
    tb_check1("untracked blocks seq not fires", redirect_fetch_req_valid, 1'b0);
    tb_check1("untracked raises resolve block", resolve_redirect_block, 1'b1);
    check_xlen("untracked winner pc", redirect_fetch_pc,
               core_branch_resolve_next_pc);

    // ── 非 arbiter 拍兜底: E7/E9 保留臂进 valid 但无 arb 赢家 → 默认 core resolve ──
    reset_inputs();
    branch_resolve_redirect = 1'b1;
    #1;
    tb_check1("branch resolve blocks not fires",
              redirect_fetch_req_valid, 1'b0);
    tb_check1("branch resolve raises block", resolve_redirect_block, 1'b1);
    check_xlen("no-arb default selects core branch resolve", redirect_fetch_pc,
               core_branch_resolve_next_pc);

    reset_inputs();
    branch_spec_redirect = 1'b1;
    #1;
    check_xlen("branch spec default selects core branch resolve",
               redirect_fetch_pc, core_branch_resolve_next_pc);

    // ── valid/流控职责(未动) ──
    reset_inputs();
    direct_jal_fire = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_0000_3000;
    outstanding_valid = 1'b1;
    fetch_rsp_fire = 1'b0;
    #1;
    tb_check1("outstanding blocks redirect request", redirect_fetch_req_valid,
              1'b0);
    check_xlen("blocked redirect falls to seq", fetch_req_pc, next_fetch_pc);

    reset_inputs();
    direct_jal_fire = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_0000_3000;
    outstanding_valid = 1'b1;
    fetch_rsp_fire = 1'b1;
    #1;
    tb_check1("firewall: rsp fire no same-cycle redirect", redirect_fetch_req_valid,
              1'b0);
    // 防火墙退役: unblocked redirect wins (redirect 拍请求不发, pc don\'t-care)

    reset_inputs();
    branch_resolve_redirect = 1'b1;
    branch_fallthrough_dispatch = 1'b1;
    branch_fallthrough_outstanding_match = 1'b1;
    #1;
    tb_check1("fallthrough outstanding suppresses redirect",
              redirect_fetch_req_valid, 1'b0);

    // ── direct valid 成员集(禁止项①: 不得改接 arb_valid)——pending_jump/直算族仍进 OR ──
    reset_inputs();
    pending_jump_nolink_commit = 1'b1;
    #1;
    tb_check1("pending jump nolink still in direct OR",
              direct_redirect_fetch, 1'b1);

    reset_inputs();
    direct_jump_spec_fire = 1'b1;
    #1;
    tb_check1("jump spec still in direct OR", direct_redirect_fetch, 1'b1);

    // 【B2 S2】刀 K1 的 branch0/1_fire 两口已删(分支 fire 物理死化, taken 重取
    // 降格为顺序流地址选择): redirect_fetch_req_valid 只由 direct_redirect_fetch
    // 家族(jal/ret/jump_spec 等)驱动, arbiter 赢家拍无 direct 成员时不得发请求。
    reset_inputs();
    redirect_valid = 1'b1;
    redirect_pc = 64'h7000;
    #1;
    tb_check1("S2: arbiter winner alone no fetch request",
              redirect_fetch_req_valid, 1'b0);
    check_xlen("S2: arbiter pc passthrough kept", redirect_fetch_pc, 64'h7000);
    // 顺序臂 rsp 项保持 fall-through(taken 拍由 FlowControl.pred_taken_block 关断,
    // not-taken 拍 pred_next_pc≡packet_next_pc): 融合拍地址=packet_next_pc。
    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_fire = 1'b1;
    fetch_rsp_packet_next_pc = 64'h5678;
    #1;
    check_xlen("S2: fused seq arm uses fall-through", fetch_req_pc, 64'h5678);

    tb_finish("tb_ooo_fetch_request_mux");
  end

endmodule
