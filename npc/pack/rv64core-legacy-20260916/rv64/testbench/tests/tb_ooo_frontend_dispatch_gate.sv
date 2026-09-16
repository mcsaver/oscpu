`include "define.v"
`include "tb_common.svh"

module tb_ooo_frontend_dispatch_gate;
  reg dispatch_valid;
  reg dispatch0_exit;
  reg dispatch0_arch_trap;
  reg dispatch0_system;
  reg dispatch0_fp;
  reg dispatch0_branch;
  reg dispatch0_jal;
  reg dispatch0_jump;
  reg dispatch0_unsupported;
  reg dispatch1_unsupported;
  reg dispatch0_ready;
  reg dispatch1_ready;
  reg head0_fp_raw;
  reg head1_fp_raw;
  reg head_fetch_fault1;
  reg head1_exit_raw;
  reg head1_system_raw;
  reg head1_arch_trap_raw;
  reg head1_control_raw;
  reg head1_branch_raw;
  reg head1_jal_raw;
  reg head1_jalr_raw;
  reg head1_jal_call_raw;
  reg head1_return_candidate;
  reg lane0_before_ret_safe;
  // 【B2 S2】包内存储位: head0 预测方向 + slot1 截断位(dual_go 谓词输入)
  reg head0_branch_pred_taken;
  reg head_slot1_valid;

  wire dispatch1_direct_jal;
  wire dispatch1_return;
  wire direct_branch1_dispatch_valid;
  wire dispatch1_barrier;
  wire dispatch1_control_unsupported;
  wire dispatch1_mem_unsupported;
  wire dispatch_unsupported;
  wire dispatch_fire;
  wire dispatch1_barrier_fire;
  wire direct_jal0_fire;
  wire direct_jal1_fire;
  wire direct_ret1_fire;
  wire direct_branch1_fire;
  wire dbranch_dual_go;
  wire frontend_dispatch_to_backend_valid;

  OooFrontendDispatchGate dut (
    .dispatch_valid_i(dispatch_valid),
    // 【F2→B2 S2】存储预测位默认 taken(dual_go=0, 保持原 direct 模型场景语义);
    // dual_go/截断契约场景单独驱动。head1_branch_pred_taken_i 端口已删(branch1
    // fire 死化后无消费), 换 slot1 截断位。
    .head0_branch_pred_taken_i(head0_branch_pred_taken),
    .head_slot1_valid_i(head_slot1_valid),
    .dispatch0_exit_i(dispatch0_exit),
    .dispatch0_arch_trap_i(dispatch0_arch_trap),
    .dispatch0_system_i(dispatch0_system),
    .dispatch0_fp_i(dispatch0_fp),
    .dispatch0_branch_i(dispatch0_branch),
    .dispatch0_jal_i(dispatch0_jal),
    .dispatch0_jump_i(dispatch0_jump),
    .dispatch0_unsupported_i(dispatch0_unsupported),
    .dispatch1_unsupported_i(dispatch1_unsupported),
    .dispatch0_ready_i(dispatch0_ready),
    .dispatch1_ready_i(dispatch1_ready),
    .head0_fp_raw_i(head0_fp_raw),
    .head1_fp_raw_i(head1_fp_raw),
    .head_fetch_fault1_i(head_fetch_fault1),
    .head1_exit_raw_i(head1_exit_raw),
    .head1_system_raw_i(head1_system_raw),
    .head1_arch_trap_raw_i(head1_arch_trap_raw),
    .head1_control_raw_i(head1_control_raw),
    .head1_branch_raw_i(head1_branch_raw),
    .head1_jal_raw_i(head1_jal_raw),
    .head1_jalr_raw_i(head1_jalr_raw),
    .head1_jal_call_raw_i(head1_jal_call_raw),
    .head1_return_candidate_i(head1_return_candidate),
    .lane0_before_ret_safe_i(lane0_before_ret_safe),
    .dispatch1_direct_jal_o(dispatch1_direct_jal),
    .dispatch1_return_o(dispatch1_return),
    .direct_branch1_dispatch_valid_o(direct_branch1_dispatch_valid),
    .dispatch1_barrier_o(dispatch1_barrier),
    .dispatch1_control_unsupported_o(dispatch1_control_unsupported),
    .dispatch1_mem_unsupported_o(dispatch1_mem_unsupported),
    .dispatch_unsupported_o(dispatch_unsupported),
    .dispatch_fire_o(dispatch_fire),
    .dispatch1_barrier_fire_o(dispatch1_barrier_fire),
    .frontend_dispatch_to_backend_valid_o(frontend_dispatch_to_backend_valid),
    .direct_jal0_fire_o(direct_jal0_fire),
    .direct_jal1_fire_o(direct_jal1_fire),
    .direct_ret1_fire_o(direct_ret1_fire),
    .direct_branch1_fire_o(direct_branch1_fire),
    .dbranch_dual_go_o(dbranch_dual_go)
  );

  task automatic reset_inputs;
    begin
      dispatch_valid = 1'b1;
      dispatch0_exit = 1'b0;
      dispatch0_arch_trap = 1'b0;
      dispatch0_system = 1'b0;
      dispatch0_fp = 1'b0;
      dispatch0_branch = 1'b0;
      dispatch0_jal = 1'b0;
      dispatch0_jump = 1'b0;
      dispatch0_unsupported = 1'b0;
      dispatch1_unsupported = 1'b0;
      dispatch0_ready = 1'b1;
      dispatch1_ready = 1'b1;
      head0_fp_raw = 1'b0;
      head1_fp_raw = 1'b0;
      head_fetch_fault1 = 1'b0;
      head1_exit_raw = 1'b0;
      head1_system_raw = 1'b0;
      head1_arch_trap_raw = 1'b0;
      head1_control_raw = 1'b0;
      head1_branch_raw = 1'b0;
      head1_jal_raw = 1'b0;
      head1_jalr_raw = 1'b0;
      head1_jal_call_raw = 1'b0;
      head1_return_candidate = 1'b0;
      lane0_before_ret_safe = 1'b0;
      head0_branch_pred_taken = 1'b1;
      head_slot1_valid = 1'b1;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    tb_check1("plain dual dispatch fires", dispatch_fire, 1'b1);
    tb_check1("plain head reaches backend", frontend_dispatch_to_backend_valid, 1'b1);
    tb_check1("no mem unsupported", dispatch1_mem_unsupported, 1'b0);

    reset_inputs();
    dispatch0_arch_trap = 1'b1;
    #1;
    tb_check1("head0 arch trap blocks ordinary backend",
              frontend_dispatch_to_backend_valid, 1'b0);
    tb_check1("head0 arch trap blocks dual dispatch", dispatch_fire, 1'b0);

    reset_inputs();
    head1_jal_raw = 1'b1;
    #1;
    tb_check1("lane1 direct jal candidate", dispatch1_direct_jal, 1'b1);
    tb_check1("lane1 jal fires through normal dispatch", direct_jal1_fire, 1'b1);

    reset_inputs();
    head1_jal_raw = 1'b1;
    head1_jal_call_raw = 1'b1;
    #1;
    tb_check1("lane1 jal call is not direct jal candidate", dispatch1_direct_jal, 1'b0);
    tb_check1("lane1 jal call still normal dispatches", direct_jal1_fire, 1'b1);

    reset_inputs();
    head1_return_candidate = 1'b1;
    lane0_before_ret_safe = 1'b1;
    #1;
    tb_check1("lane1 return candidate", dispatch1_return, 1'b1);
    tb_check1("lane1 return fire", direct_ret1_fire, 1'b1);

    reset_inputs();
    head1_return_candidate = 1'b1;
    lane0_before_ret_safe = 1'b0;
    head1_jalr_raw = 1'b1;
    #1;
    tb_check1("unsafe return blocked", dispatch1_return, 1'b0);
    // mode=0：unsafe JALR 降级为 barrier（下一拍单独处理）；
    // mode=1（OOO_ROB_WALK_MODE）：非返回 lane1 JALR 走 dual-issue de-pend（非 barrier），
    // 由 backend issue1 强制 mispredict→ROB-walk 修正（riscv-tests 135/0 覆盖含 return JALR）。
    if (!`OOO_ROB_WALK_MODE)
      tb_check1("unsafe jalr becomes barrier", dispatch1_barrier, 1'b1);
    else
      tb_check1("mode1 unsafe jalr de-pend (non-barrier)", dispatch1_barrier, 1'b0);

    reset_inputs();
    head1_branch_raw = 1'b1;
    #1;
    tb_check1("lane1 direct branch candidate", direct_branch1_dispatch_valid, 1'b1);
    // 【B2 S2】head1 taken 分支不再 dispatch 拍 fire(预测介入点前移 fetch resp 拍,
    // taken 已在包 enqueue 拍改流顺序取指): fire 恒 0, 双发照走。
    tb_check1("S2: lane1 branch never fires (fetch-time pred)", direct_branch1_fire, 1'b0);
    tb_check1("S2: lane1 branch still dual dispatches", dispatch_fire, 1'b1);

    reset_inputs();
    head1_branch_raw = 1'b1;
    head_fetch_fault1 = 1'b1;
    #1;
    tb_check1("fault blocks lane1 branch fast path", direct_branch1_dispatch_valid, 1'b0);
    tb_check1("faulted lane1 branch is barrier", dispatch1_barrier, 1'b1);
    tb_check1("barrier fire uses slot0 ready", dispatch1_barrier_fire, 1'b1);

    reset_inputs();
    head1_control_raw = 1'b1;
    #1;
    tb_check1("unsupported lane1 control", dispatch1_control_unsupported, 1'b1);
    tb_check1("unsupported dispatch", dispatch_unsupported, 1'b1);
    tb_check1("unsupported blocks dispatch fire", dispatch_fire, 1'b0);

    reset_inputs();
    dispatch0_unsupported = 1'b1;
    #1;
    tb_check1("slot0 unsupported blocks dispatch", dispatch_unsupported, 1'b1);

    reset_inputs();
    dispatch0_unsupported = 1'b1;
    head0_fp_raw = 1'b1;
    #1;
    tb_check1("slot0 FP raw masks integer unsupported", dispatch_unsupported, 1'b0);

    reset_inputs();
    dispatch1_unsupported = 1'b1;
    head1_fp_raw = 1'b1;
    #1;
    tb_check1("slot1 FP raw masks integer unsupported", dispatch_unsupported, 1'b0);

    reset_inputs();
    dispatch0_jal = 1'b1;
    dispatch0_unsupported = 1'b1;
    #1;
    tb_check1("slot0 jal direct fire suppressed by unsupported", direct_jal0_fire, 1'b0);
    tb_check1("legacy unsupported base still sees slot0 jal", dispatch_unsupported, 1'b1);

    reset_inputs();
    dispatch0_jal = 1'b1;
    #1;
    tb_check1("slot0 jal direct fire", direct_jal0_fire, 1'b1);
    tb_check1("slot0 jal blocks normal dual dispatch", dispatch_fire, 1'b0);

    reset_inputs();
    dispatch0_branch = 1'b1;
    #1;
    tb_check1("slot0 taken branch blocks lane1 base (solo)", dispatch_fire, 1'b0);
    tb_check1("slot0 taken branch dual_go=0", dbranch_dual_go, 1'b0);
    tb_check1("slot0 branch no unsupported", dispatch_unsupported, 1'b0);

    // 【B2 S2】dual_go 存储位驱动契约: stored not-taken && slot1_valid && head1 平凡
    reset_inputs();
    dispatch0_branch = 1'b1;
    head0_branch_pred_taken = 1'b0;
    #1;
    tb_check1("S2: not-taken branch dual_go", dbranch_dual_go, 1'b1);
    tb_check1("S2: not-taken branch dual dispatches", dispatch_fire, 1'b1);

    // 截断位防御: slot1_valid=0(理论上蕴含 pred_taken0=1, 此处独立驱动验证 gate)
    reset_inputs();
    dispatch0_branch = 1'b1;
    head0_branch_pred_taken = 1'b0;
    head_slot1_valid = 1'b0;
    #1;
    tb_check1("S2: slot1_valid=0 blocks dual_go", dbranch_dual_go, 1'b0);
    tb_check1("S2: truncated packet solo dispatch", dispatch_fire, 1'b0);

    // not-taken 但 head1 system: dual_go 禁(F2 修复史 rv64mi-illegal 家族)
    reset_inputs();
    dispatch0_branch = 1'b1;
    head0_branch_pred_taken = 1'b0;
    head1_system_raw = 1'b1;
    #1;
    tb_check1("S2: head1 system blocks dual_go", dbranch_dual_go, 1'b0);

    // V15T-H1：backend raw unsupported 不再回灌 branch dual eligibility；
    // lane1 非法/无需执行类由同一 head classifier 的 arch-trap fact 阻断。
    reset_inputs();
    dispatch0_branch = 1'b1;
    head0_branch_pred_taken = 1'b0;
    head1_arch_trap_raw = 1'b1;
    #1;
    tb_check1("V15T: head1 arch trap blocks dual_go", dbranch_dual_go, 1'b0);

    reset_inputs();
    dispatch0_ready = 1'b0;
    #1;
    tb_check1("ready0 blocks dispatch fire", dispatch_fire, 1'b0);

    tb_finish("tb_ooo_frontend_dispatch_gate");
  end

endmodule
