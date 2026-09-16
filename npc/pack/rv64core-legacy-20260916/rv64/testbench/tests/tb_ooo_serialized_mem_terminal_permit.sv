`timescale 1ns/1ps
`include "define.v"

module tb_ooo_serialized_mem_terminal_permit;
  `include "tb_common.svh"

  localparam ROB_COUNT_W = 5;
  localparam ISSUE_COUNT_W = 4;

  reg clk;
  reg rst;
  reg cancel;
  reg stop_pending;
  reg backend_drained_q;
  reg [2:0] owner;
  reg mem_owner_terminalized;

  reg [ROB_COUNT_W-1:0] rob_count;
  reg [ISSUE_COUNT_W-1:0] issue_count;
  reg mem_retire_quiet;
  reg mem_idle;
  reg pending_control_ready;
  reg pending_system;
  reg pending_system_fence;
  reg pending_system_csr;
  reg pending_arch_trap;
  reg pending_exit;

  wire permit_ready;
  wire backend_drained;
  wire system_csr_dispatch_valid;
  wire drain_complete;

  OooSerializedMemTerminalPermit permit (
    .clk(clk),
    .rst(rst),
    .cancel_i(cancel),
    .stop_pending_i(stop_pending),
    .backend_drained_q_i(backend_drained_q),
    .owner_i(owner),
    .mem_owner_terminalized_i(mem_owner_terminalized),
    .consume_i(drain_complete),
    .ready_o(permit_ready)
  );

  OooPendingDrainResolveGate #(
    .ROB_COUNT_W(ROB_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) drain_gate (
    .rob_count_i(rob_count),
    .issue_count_i(issue_count),
    .tensor_pre_rob_owner_live_i(1'b0),
    .synth_lane1_ret_pending_i(1'b0),
    .synth_lane1_branch_drop_pending_i(1'b0),
    .direct_frontend_flush_i(1'b0),
    .stop_pending_i(stop_pending),
    .backend_drained_q_i(backend_drained_q),
    .pending_control_ready_i(pending_control_ready),
    .dispatch0_ready_i(1'b1),
    .branch_resolve_pending_match_i(1'b0),
    .branch_spec_active_i(1'b0),
    .branch_spec_checkpoint_pending_i(1'b0),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_exit_i(pending_exit),
    .pending_branch_i(1'b0),
    .pending_branch_dispatched_i(1'b0),
    .pending_jump_i(1'b0),
    .pending_jump_dispatched_i(1'b0),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_nolink_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .mem_retire_quiet_i(mem_retire_quiet),
    .mem_idle_i(mem_idle),
    .mem_owner_terminalized_i(mem_owner_terminalized),
    .serialized_mem_terminal_ready_i(permit_ready),
    .pending_system_i(pending_system),
    .pending_system_fence_i(pending_system_fence),
    .pending_system_csr_i(pending_system_csr),
    .pending_system_dispatched_i(1'b0),
    .system_csr_dispatch_cancel_i(cancel),
    .backend_drained_o(backend_drained),
    .jump_dispatch_valid_o(),
    .system_csr_dispatch_valid_o(system_csr_dispatch_valid),
    .system_csr_dispatch_fire_o(),
    .pending_branch_commit_resolve_o(),
    .pending_branch_match_clear_o(),
    .pending_replay_wait_o(),
    .drain_complete_o(drain_complete)
  );

  task automatic tick;
    begin
      #4;
      clk = 1'b1;
      #1;
      clk = 1'b0;
      #1;
    end
  endtask

  task automatic clear_inputs;
    begin
      cancel = 1'b0;
      stop_pending = 1'b0;
      backend_drained_q = 1'b0;
      owner = 3'b000;
      mem_owner_terminalized = 1'b0;
      rob_count = {ROB_COUNT_W{1'b0}};
      issue_count = {ISSUE_COUNT_W{1'b0}};
      mem_retire_quiet = 1'b1;
      mem_idle = 1'b1;
      pending_control_ready = 1'b0;
      pending_system = 1'b0;
      pending_system_fence = 1'b0;
      pending_system_csr = 1'b0;
      pending_arch_trap = 1'b0;
      pending_exit = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
      clear_inputs();
      rst = 1'b1;
      tick();
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic drive_noncsr_system_owner;
    begin
      stop_pending = 1'b1;
      backend_drained_q = 1'b1;
      owner = 3'b001;
      pending_system = 1'b1;
      pending_system_csr = 1'b0;
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b0;
    tb_errors = 0;

    reset_dut();
    stop_pending = 1'b1;
    backend_drained_q = 1'b1;
    owner = 3'b011;
    mem_owner_terminalized = 1'b1;
    tick();
    tb_check1("V16A non-onehot owner cannot arm", permit_ready, 1'b0);

    // owner A arm/hold；registered permit 不直接完成 control，raw drain 与
    // pending_control_ready 仍由 consumer 当拍重查。
    reset_dut();
    drive_noncsr_system_owner();
    mem_owner_terminalized = 1'b0;
    tick();
    tb_check1("V16A active holder blocks arm", permit_ready, 1'b0);
    mem_owner_terminalized = 1'b1;
    tick();
    tb_check1("V16A exact terminal arms owner A", permit_ready, 1'b1);
    tb_check1("V16A permit alone does not complete", drain_complete, 1'b0);
    tick();
    tb_check1("V16A same owner holds permit", permit_ready, 1'b1);

    // capture 后伪造 memory birth/active holder：permit 仍是 owner A 的 Q，
    // 但 raw backend drain 必须阻止 completion。
    pending_control_ready = 1'b1;
    mem_owner_terminalized = 1'b0;
    issue_count = {{(ISSUE_COUNT_W-1){1'b0}}, 1'b1};
    #1;
    tb_check1("V16A stale permit visible before raw drain", permit_ready, 1'b1);
    tb_check1("V16A raw issue state blocks stale permit consume",
              backend_drained, 1'b0);
    tb_check1("V16A raw drain recheck blocks completion",
              drain_complete, 1'b0);
    issue_count = {ISSUE_COUNT_W{1'b0}};
    mem_owner_terminalized = 1'b1;
    #1;
    tb_check1("V16A legal owner A consumes after raw drain",
              drain_complete, 1'b1);
    tick();
    stop_pending = 1'b0;
    owner = 3'b000;
    pending_system = 1'b0;
    #1;
    tb_check1("V16A consume clears permit", permit_ready, 1'b0);
    $display("[V16A-SERIALIZED-PERMIT-RAW-DRAIN-RECHECK] PASS");

    // owner A→B 不需要依赖 stop 的低电平气泡：current owner compare 当拍
    // 令 A permit 无效，B 必须重新 arm。
    reset_dut();
    drive_noncsr_system_owner();
    mem_owner_terminalized = 1'b1;
    tick();
    tb_check1("V16A owner A ready", permit_ready, 1'b1);
    owner = 3'b010;
    pending_system = 1'b0;
    pending_arch_trap = 1'b1;
    #1;
    tb_check1("V16A owner B cannot consume owner A permit",
              permit_ready, 1'b0);
    tick();
    tb_check1("V16A mismatch edge clears stale permit",
              permit_ready, 1'b0);
    tick();
    tb_check1("V16A owner B must rearm", permit_ready, 1'b1);
    $display("[V16A-SERIALIZED-PERMIT-OWNER-MATCH] A-to-B PASS");

    // cancel 与 arm 同沿必须 clear-dominant；held permit 遇到 feedback-free
    // 高优先级 cancel 时，本拍 ready/drain 立即被封住，不能等到下一沿。
    reset_dut();
    drive_noncsr_system_owner();
    mem_owner_terminalized = 1'b1;
    cancel = 1'b1;
    tick();
    tb_check1("V16A arm plus cancel cannot create permit",
              permit_ready, 1'b0);
    cancel = 1'b0;
    tick();
    tb_check1("V16A owner rearms only after cancel drops",
              permit_ready, 1'b1);
    pending_control_ready = 1'b1;
    cancel = 1'b1;
    #1;
    tb_check1("V16A held cancel suppresses ready immediately",
              permit_ready, 1'b0);
    tb_check1("V16A held cancel suppresses drain immediately",
              drain_complete, 1'b0);
    tick();
    tb_check1("V16A cancel clears held permit", permit_ready, 1'b0);
    cancel = 1'b0;
    #1;
    tb_check1("V16A cancel drop cannot resurrect held permit",
              permit_ready, 1'b0);
    $display("[V16B-SERIALIZED-PERMIT-CANCEL-CYCLE-BLOCK] arm-held-cancel PASS");

    reset_dut();
    drive_noncsr_system_owner();
    mem_owner_terminalized = 1'b1;
    tick();
    stop_pending = 1'b0;
    #1;
    tb_check1("V16A stop drop invalidates ready immediately",
              permit_ready, 1'b0);
    tick();
    stop_pending = 1'b1;
    #1;
    tb_check1("V16A stop resurrection cannot reuse permit",
              permit_ready, 1'b0);

    // ordinary FENCE 仍逐拍读取完整 mem_idle；permit 只替换 exact-terminal
    // 长锥，不能把 collector terminal 当成 full memory idle。
    reset_dut();
    drive_noncsr_system_owner();
    pending_system_fence = 1'b1;
    mem_owner_terminalized = 1'b1;
    mem_idle = 1'b0;
    pending_control_ready = 1'b1;
    tick();
    tb_check1("V16A FENCE permit arms", permit_ready, 1'b1);
    tb_check1("V16A FENCE current mem_idle blocks completion",
              drain_complete, 1'b0);
    mem_idle = 1'b1;
    #1;
    tb_check1("V16A FENCE completes only with current mem_idle",
              drain_complete, 1'b1);
    $display("[V16A-SERIALIZED-PERMIT-FENCE-CURRENT-IDLE] PASS");

    // CSR replay 保持旧的 current scalar：它不进入三位 serialized owner
    // permit，且 dispatch eligibility 仍读取本拍 terminalized。
    reset_dut();
    stop_pending = 1'b1;
    backend_drained_q = 1'b1;
    pending_system = 1'b1;
    pending_system_csr = 1'b1;
    owner = 3'b000;
    mem_owner_terminalized = 1'b0;
    #1;
    tb_check1("V16A CSR current scalar blocks dispatch",
              system_csr_dispatch_valid, 1'b0);
    mem_owner_terminalized = 1'b1;
    #1;
    tb_check1("V16A CSR current scalar still admits dispatch",
              system_csr_dispatch_valid, 1'b1);
    tb_check1("V16A CSR never reuses serialized permit",
              permit_ready, 1'b0);
    $display("[V16A-SERIALIZED-PERMIT-CSR-CURRENT-SCALAR] PASS");

    tb_finish("tb_ooo_serialized_mem_terminal_permit");
  end
endmodule
