`include "include/define.v"
`include "common/OooSlotFacts.v"

// Pure combinational pending-owner event arbitration for OooCoreTopGlue.
module OooPendingDispatchArbiter (
  input csr_trap_mem_valid_i,
  input direct_frontend_flush_i,
  input can_run_i,
  input fifo_has_packet_i,
  input csr_irq_pending_i,

  input branch_spec_resolve_valid_i,
  input pending_branch_commit_resolve_i,
  input pending_branch_match_clear_i,
  input branch_resolve_untracked_i,
  input pending_jump_resolve_ready_i,
  input pending_jump_misaligned_i,
  input pending_jump_nolink_commit_i,
  input pending_jump_redirect_after_dispatch_i,
  input pending_system_csr_commit_i,
  input stop_pending_i,
  input drain_complete_i,

  input direct_branch0_fire_i,
  input direct_branch1_fire_i,
  input head_fetch_fault0_i,
  input head_fetch_fault1_i,
  input [1:0] head_resp0_i,
  input [1:0] head_resp1_i,
  input [`XLEN-1:0] head_pc0_i,
  input [`XLEN-1:0] head_pc1_i,
  input [`INST_W-1:0] head_inst0_i,
  input [`INST_W-1:0] head_inst1_i,
  input [`OOO_SLOT_FACTS_W-1:0] dispatch0_facts_i,
  input [`OOO_SLOT_FACTS_W-1:0] head1_facts_i,

  input direct_branch0_dispatch_valid_i,
  input direct_jal0_dispatch_valid_i,
  input dispatch0_return_i,
  input dispatch0_unsupported_i,
  input dispatch_unsupported_i,
  input dispatch1_barrier_fire_i,

  input head0_csr_illegal_i,
  input head1_csr_illegal_i,
  input rob_walk_mode_i,   // B2: mode=1 时 branch/jump 不再进 pending capture（改投机+ROB-walk）

  output pending_system_capture_irq_o,
  output pending_system_capture_head0_o,
  output pending_system_capture_lane1_o,
  output pending_system_clear_o,

  output pending_branch_capture_direct_o,
  output pending_branch_capture_head0_o,
  output pending_branch_capture_lane1_o,
  output pending_branch_clear_o,

  output pending_jump_capture_head0_o,
  output pending_jump_capture_lane1_o,
  output pending_jump_clear_o,

  output pending_trap_exit_clear_exit_o,
  output pending_trap_exit_clear_arch_o,
  output pending_trap_exit_clear_arch_squash_o,
  output pending_trap_exit_capture_exit_o,
  output pending_trap_exit_capture_exit_valid_o,
  output pending_trap_exit_capture_exit_ecall_o,
  output pending_trap_exit_capture_exit_ebreak_o,
  output pending_trap_exit_capture_arch_o,
  output pending_trap_exit_capture_arch_valid_o,
  output [`TRAP_CAUSE_W-1:0] pending_trap_exit_capture_cause_o,
  output [`XLEN-1:0] pending_trap_exit_capture_pc_o,
  output [`XLEN-1:0] pending_trap_exit_capture_tval_o
);

  wire capture_base_w =
      !csr_trap_mem_valid_i && !direct_frontend_flush_i &&
      can_run_i && fifo_has_packet_i;
  wire dispatch0_arch_trap_w =
      dispatch0_facts_i[`OOO_SLOT_FACT_ARCH_TRAP];
  wire dispatch0_exit_w = dispatch0_facts_i[`OOO_SLOT_FACT_EXIT];
  wire dispatch0_ecall_w = dispatch0_facts_i[`OOO_SLOT_FACT_ECALL];
  wire dispatch0_ebreak_w = dispatch0_facts_i[`OOO_SLOT_FACT_EBREAK];
  // 【B-FP 簇】FP 迁域 A: head0=FP 与普通 ALU 指令完全同构, 不再参与任何
  // pending capture/clear 门控(旧 !dispatch0_fp_w gate 在 lane1 barrier fire
  // 整包 pop 时挡死 lane1 system capture → 与 FP 同包的 CSR 指令被静默丢弃)。
  wire dispatch0_system_w = dispatch0_facts_i[`OOO_SLOT_FACT_SYSTEM];
  wire dispatch0_branch_w = dispatch0_facts_i[`OOO_SLOT_FACT_BRANCH];
  wire dispatch0_jal_w = dispatch0_facts_i[`OOO_SLOT_FACT_JAL];
  wire dispatch0_jump_w = dispatch0_facts_i[`OOO_SLOT_FACT_JALR];
  wire head0_semihost_ebreak_w =
      dispatch0_facts_i[`OOO_SLOT_FACT_SEMIHOST_EBREAK];
  wire direct_branch_fire_w =
      direct_branch0_fire_i || direct_branch1_fire_i;
  wire lane0_branch_pending_w =
      dispatch0_branch_w && !direct_branch0_dispatch_valid_i && !rob_walk_mode_i;
  wire lane0_jump_pending_w =
      ((dispatch0_jal_w && !direct_jal0_dispatch_valid_i) ||
       (dispatch0_jump_w && !dispatch0_return_i)) && !rob_walk_mode_i;
  wire lane1_barrier_base_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_system_w &&
      !lane0_branch_pending_w &&
      !lane0_jump_pending_w &&
      dispatch1_barrier_fire_i;
  wire lane1_system_capture_w;
  wire lane1_branch_capture_w;
  wire lane1_jump_capture_w;
  wire lane1_fp_capture_w;
  wire trap_exit_capture_lane1_w;
  wire trap_exit_lane1_arch_valid_w;
  wire trap_exit_lane1_exit_valid_w;
  wire trap_exit_lane1_exit_ecall_w;
  wire trap_exit_lane1_exit_ebreak_w;
  wire [`TRAP_CAUSE_W-1:0] trap_exit_lane1_cause_w;
  wire [`XLEN-1:0] trap_exit_lane1_tval_w;

  OooPendingLane1CaptureGate u_lane1_capture_gate (
    .barrier_base_i(lane1_barrier_base_w),
    .head_fetch_fault_i(head_fetch_fault1_i),
    .head_resp_i(head_resp1_i),
    .head_pc_i(head_pc1_i),
    .head_inst_i(head_inst1_i),
    .facts_i(head1_facts_i),
    .csr_illegal_i(head1_csr_illegal_i),
    .system_capture_o(lane1_system_capture_w),
    .branch_capture_o(lane1_branch_capture_w),
    .jump_capture_o(lane1_jump_capture_w),
    .fp_capture_o(lane1_fp_capture_w),
    .trap_exit_capture_o(trap_exit_capture_lane1_w),
    .trap_exit_arch_valid_o(trap_exit_lane1_arch_valid_w),
    .trap_exit_exit_valid_o(trap_exit_lane1_exit_valid_w),
    .trap_exit_exit_ecall_o(trap_exit_lane1_exit_ecall_w),
    .trap_exit_exit_ebreak_o(trap_exit_lane1_exit_ebreak_w),
    .trap_exit_cause_o(trap_exit_lane1_cause_w),
    .trap_exit_tval_o(trap_exit_lane1_tval_w)
  );

  assign pending_system_capture_irq_o =
      capture_base_w && csr_irq_pending_i;
  assign pending_system_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      dispatch0_system_w && !head0_csr_illegal_i;
  assign pending_system_capture_lane1_o = lane1_system_capture_w;

  assign pending_branch_capture_direct_o =
      direct_frontend_flush_i && direct_branch_fire_w && !rob_walk_mode_i;
  assign pending_branch_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_system_w &&
      lane0_branch_pending_w;
  assign pending_branch_capture_lane1_o =
      lane1_branch_capture_w && !rob_walk_mode_i;

  assign pending_jump_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_system_w &&
      !lane0_branch_pending_w &&
      lane0_jump_pending_w;
  assign pending_jump_capture_lane1_o =
      lane1_jump_capture_w && !rob_walk_mode_i;


  wire pending_jump_clear_from_resolve_w =
      !direct_frontend_flush_i && pending_jump_resolve_ready_i &&
      (pending_jump_misaligned_i ||
       pending_jump_nolink_commit_i ||
       pending_jump_redirect_after_dispatch_i);
  wire drain_clear_w =
      !csr_trap_mem_valid_i && !direct_frontend_flush_i &&
      stop_pending_i && drain_complete_i;
  wire resolve_clear_w =
      (!direct_frontend_flush_i && branch_spec_resolve_valid_i) ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i ||
      (!direct_frontend_flush_i && branch_resolve_untracked_i) ||
      (!direct_frontend_flush_i && pending_system_csr_commit_i) ||
      drain_clear_w;

  wire branch_capture_clear_w =
      capture_base_w &&
      (csr_irq_pending_i ||
       head_fetch_fault0_i ||
       dispatch0_arch_trap_w ||
       dispatch0_exit_w ||
       dispatch0_system_w ||
       lane0_jump_pending_w ||
       dispatch_unsupported_i);
  wire jump_capture_clear_w =
      capture_base_w &&
      (csr_irq_pending_i ||
       head_fetch_fault0_i ||
       dispatch0_arch_trap_w ||
       dispatch0_exit_w ||
       dispatch0_system_w ||
       lane0_branch_pending_w ||
       dispatch_unsupported_i);

  assign pending_branch_clear_o =
      resolve_clear_w ||
      pending_jump_clear_from_resolve_w ||
      branch_capture_clear_w;
  assign pending_jump_clear_o =
      direct_frontend_flush_i ||
      resolve_clear_w ||
      pending_jump_clear_from_resolve_w ||
      jump_capture_clear_w;
  assign pending_system_clear_o =
      csr_trap_mem_valid_i ||
      direct_frontend_flush_i ||
      resolve_clear_w ||
      pending_jump_clear_from_resolve_w;

  wire trap_exit_capture_fetch_fault0_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      head_fetch_fault0_i;   // mode=1 也 capture; 投机 wrong-path fetch fault residual 由
                             // clear_arch_squash cause-gate 在被 squash 时清(见 OooPendingTrapExitSequencer)
  wire trap_exit_capture_arch0_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      dispatch0_arch_trap_w;
  wire trap_exit_capture_exit0_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      dispatch0_exit_w;
  wire trap_exit_capture_csr_illegal0_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      dispatch0_system_w && head0_csr_illegal_i;
  wire trap_exit_capture_unsupported_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_system_w &&
      !lane0_branch_pending_w &&
      !lane0_jump_pending_w &&
      !dispatch1_barrier_fire_i &&
      dispatch_unsupported_i;

  assign pending_trap_exit_capture_exit_o =
      trap_exit_capture_exit0_w || trap_exit_capture_lane1_w;
  assign pending_trap_exit_capture_exit_valid_o =
      trap_exit_capture_exit0_w ||
      trap_exit_lane1_exit_valid_w;
  assign pending_trap_exit_capture_exit_ecall_o =
      trap_exit_capture_exit0_w ? dispatch0_ecall_w :
                                  trap_exit_lane1_exit_ecall_w;
  assign pending_trap_exit_capture_exit_ebreak_o =
      trap_exit_capture_exit0_w ? dispatch0_ebreak_w :
                                  trap_exit_lane1_exit_ebreak_w;

  // capture 触发必须与 arch_valid 一致。lane1 barrier(barrier_base)/unsupported 不代表真实 arch trap：
  // mode=1 下它们是 dispatch-time 投机（启动 _trm_init 的 csrw 0x80001ffc 被预取到 lane1 barrier），
  // 用 barrier_base 触发会让 pending_trap_cause 落到 lane1_cause default=INST_ACCESS_FAULT 并残留整个
  // 运行 → 最后被 drain_trap_payload 误用 spurious trap。改用已 gate 的 arch_valid 表达式触发。
  assign pending_trap_exit_capture_arch_o =
      trap_exit_capture_fetch_fault0_w ||
      trap_exit_capture_arch0_w ||
      trap_exit_capture_csr_illegal0_w ||
      (trap_exit_capture_unsupported_w && !rob_walk_mode_i) ||
      (trap_exit_capture_lane1_w && trap_exit_lane1_arch_valid_w &&
       !(rob_walk_mode_i &&
         (trap_exit_lane1_cause_w == `EXC_INST_ACCESS_FAULT)));
  assign pending_trap_exit_capture_arch_valid_o =
      trap_exit_capture_fetch_fault0_w ||
      trap_exit_capture_arch0_w ||
      trap_exit_capture_csr_illegal0_w ||
      (trap_exit_capture_unsupported_w && !rob_walk_mode_i) ||
      // mode=1：lane1 arch trap capture 是 dispatch-time 投机——启动 _trm_init 的 csrw(0x80001ffc)
      // 被预取到 lane1 barrier，arch_valid 经 facts.arch_trap_raw 置位，cause 落到 default
      // INST_ACCESS_FAULT 并残留整个运行 → drain_trap_payload 误用 spurious trap。真实 arch trap
      // 走 commit 路径，riscv-tests 135/0 可证 mode=1 不依赖此 dispatch-capture。
      (trap_exit_capture_lane1_w && trap_exit_lane1_arch_valid_w &&
       !(rob_walk_mode_i &&
         (trap_exit_lane1_cause_w == `EXC_INST_ACCESS_FAULT)));
  assign pending_trap_exit_capture_cause_o =
      trap_exit_capture_fetch_fault0_w ?
          ((head_resp0_i == 2'b10) ? `EXC_INST_PAGE_FAULT :
                                     `EXC_INST_ACCESS_FAULT) :
      trap_exit_capture_arch0_w ?
          (head0_semihost_ebreak_w ? `EXC_BREAKPOINT :
                                     `EXC_ILLEGAL_INST) :
      trap_exit_capture_csr_illegal0_w ? `EXC_ILLEGAL_INST :
      trap_exit_capture_lane1_w ? trap_exit_lane1_cause_w :
                                  `EXC_ILLEGAL_INST;
  assign pending_trap_exit_capture_pc_o =
      (trap_exit_capture_lane1_w ||
       (trap_exit_capture_unsupported_w &&
        !dispatch0_unsupported_i)) ? head_pc1_i : head_pc0_i;
  assign pending_trap_exit_capture_tval_o =
      trap_exit_capture_fetch_fault0_w ? head_pc0_i :
      trap_exit_capture_arch0_w ?
          (head0_semihost_ebreak_w ? {`XLEN{1'b0}} : head_inst0_i) :
      trap_exit_capture_csr_illegal0_w ? head_inst0_i :
      trap_exit_capture_lane1_w ? trap_exit_lane1_tval_w :
      dispatch0_unsupported_i ? head_inst0_i : head_inst1_i;

  wire trap_exit_capture_clear_exit_w =
      capture_base_w &&
      (csr_irq_pending_i ||
       head_fetch_fault0_i ||
       dispatch0_arch_trap_w ||
       dispatch0_system_w ||
       lane0_branch_pending_w ||
       lane0_jump_pending_w ||
       dispatch_unsupported_i);
  wire trap_exit_capture_clear_arch_w =
      capture_base_w &&
      (csr_irq_pending_i ||
       dispatch0_exit_w ||
       dispatch0_system_w ||
       lane0_jump_pending_w);
  wire trap_exit_clear_resolve_w =
      (!direct_frontend_flush_i && branch_spec_resolve_valid_i) ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i ||
      (!direct_frontend_flush_i && branch_resolve_untracked_i) ||
      (!direct_frontend_flush_i && pending_system_csr_commit_i) ||
      drain_clear_w;

  assign pending_trap_exit_clear_exit_o =
      trap_exit_clear_resolve_w ||
      (direct_frontend_flush_i && direct_branch_fire_w) ||
      pending_jump_clear_from_resolve_w ||
      trap_exit_capture_clear_exit_w;
  assign pending_trap_exit_clear_arch_o =
      trap_exit_clear_resolve_w ||
      direct_frontend_flush_i ||
      trap_exit_capture_clear_arch_w;
  // B2 mode=1: squash 来源(branch resolve/untracked redirect jr-ret/frontend flush)的 clear_arch
  // 表示被清的 arch trap 来自投机 wrong-path(如越过 printf ret 取到 .text 段尾之后的 head
  // illegal), 需一并清 pending_trap 的 cause/pc residual, 否则被 drain 出口的 drain_trap_payload
  // (pc!=0)误用 → CoreMark(未设 mtvec)spurious illegal trap。drain 出口的 clear(drain_clear_w /
  // pending_system_csr_commit)是真实 arch trap fire 时, 保留 cause/pc 供 trap handler 读
  // scause/sepc(sv39 page fault/ecall)。
  assign pending_trap_exit_clear_arch_squash_o =
      (!direct_frontend_flush_i && branch_spec_resolve_valid_i) ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i ||
      (!direct_frontend_flush_i && branch_resolve_untracked_i) ||
      direct_frontend_flush_i;


endmodule
