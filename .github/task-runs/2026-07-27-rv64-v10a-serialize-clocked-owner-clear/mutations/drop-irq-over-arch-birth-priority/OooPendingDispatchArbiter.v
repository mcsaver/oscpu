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
  // 【serialize Phase1】head0-CSR 队头提交(→serial_flush)清 pending_system: head0-CSR 与同窗口另一条
  // lane1/younger 系统op(drain)可能共存于中间态, head0-CSR commit 拍 serial_flush 刷 younger, 那条 pending
  // 系统op(younger)须一并清(否则 pending_system 残留卡死 stop_pending → 前端冻结, 见 sbi 死锁)。
  input head0_csr_commit_i,
  input stop_pending_i,
  input drain_complete_i,

  input direct_branch0_fire_i,
  input direct_branch1_fire_i,
  input head_fetch_fault0_i,
  input head_fetch_fault1_i,
  input [`XLEN-1:0] head_fetch_fault_tval_i,
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

  // [wave5b 死硅拆除] pending_branch/jump capture+clear 输出臂(7 根)已删——capture 全被
  // !rob_walk_mode_i(OOO_ROB_WALK_MODE=1'b1 → =0) 门死，前端 sequencer 亦删。系统/陷阱臂与
  // 共享骨架(capture_base_w/lane0_*_pending_w/resolve_clear_w/pending_jump_clear_from_resolve_w
  // /lane1 capture gate)保留：它们仍喂 pending_system_clear/trap_exit 等 KEEP 输出。

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

  // T3Y：所有 set/capture 事件都由 head/lane 分类与真实 dispatch fire 约束，
  // 与 JAL/RET/JALR-spec 的 direct fire 结构互斥。删除 late direct mask，避免
  // backend-ready/direct-flush 锥进入 pending trap 的宽 payload D；真实 direct
  // squash/clear 输出仍在本模块下方保留，父层断言守住互斥契约。
  wire capture_base_w =
      !csr_trap_mem_valid_i && can_run_i && fifo_has_packet_i;
  wire dispatch0_arch_trap_w =
      dispatch0_facts_i[`OOO_SLOT_FACT_ARCH_TRAP];
  wire dispatch0_exit_w = dispatch0_facts_i[`OOO_SLOT_FACT_EXIT];
  wire dispatch0_ecall_w = dispatch0_facts_i[`OOO_SLOT_FACT_ECALL];
  wire dispatch0_ebreak_w = dispatch0_facts_i[`OOO_SLOT_FACT_EBREAK];
  // 【B-FP 簇】FP 迁域 A: head0=FP 与普通 ALU 指令完全同构, 不再参与任何
  // pending capture/clear 门控(旧 !dispatch0_fp_w gate 在 lane1 barrier fire
  // 整包 pop 时挡死 lane1 system capture → 与 FP 同包的 CSR 指令被静默丢弃)。
  wire dispatch0_system_w = dispatch0_facts_i[`OOO_SLOT_FACT_SYSTEM];
  // 【serialize-at-retire Phase1 §4#4】head0-CSR 队头化: 合法 head0-CSR 改走正常 ROB dispatch(不再 capture
  // 进 pending_system), 由 serial commit 提交。此处 dispatch0_csr_w="是 head0-可队头化 CSR"; :147 的
  // pending_system_capture_head0 排除它(已有 !head0_csr_illegal, 合法/非法 CSR 均不 head0-capture:
  // 合法→ROB, 非法→trap_exit_capture_csr_illegal0 drain-trap)。ecall/mret/wfi/sfence(csr=0)仍 capture。
  // ★排除 FP CSR(fflags/frm/fcsr): 与前端 §4#1 一致——FP CSR 本阶段不队头化, 须仍 capture 进 drain
  //   (否则既不 admit ROB 又不 capture = 丢失)。故对 FP CSR dispatch0_csr_w=0 → capture_head0 照常 fire。
  wire head0_fp_csr_w =
      (head_inst0_i[31:20] == `CSR_FFLAGS) ||
      (head_inst0_i[31:20] == `CSR_FRM) ||
      (head_inst0_i[31:20] == `CSR_FCSR);
  wire dispatch0_csr_w =
      `OOO_CSR_QUEUE_HEAD &&
      dispatch0_facts_i[`OOO_SLOT_FACT_CSR] && !head0_fp_csr_w;
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
    .head_fetch_fault_tval_i(head_fetch_fault_tval_i),
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
      dispatch0_system_w && !dispatch0_csr_w && !head0_csr_illegal_i;
  assign pending_system_capture_lane1_o = lane1_system_capture_w;

  // [wave5b 死硅拆除] pending_branch_capture_direct/head0/lane1 + pending_jump_capture_head0/lane1
  // 五条 capture assign 已删（capture 恒 0）。lane1_branch_capture_w / lane1_jump_capture_w 现转
  // lane1 capture gate 的未读输出（gate 为 KEEP，不递归删其端口）。

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

  // [wave5b 死硅拆除] branch_capture_clear_w / jump_capture_clear_w + pending_branch_clear_o /
  // pending_jump_clear_o 已删（clear 输出只喂已删的前端 sequencer）。resolve_clear_w /
  // pending_jump_clear_from_resolve_w 保留，仍喂 pending_system_clear_o + trap_exit clears(KEEP)。
  assign pending_system_clear_o =
      csr_trap_mem_valid_i ||
      direct_frontend_flush_i ||
      head0_csr_commit_i ||
      resolve_clear_w ||
      pending_jump_clear_from_resolve_w;

  wire trap_exit_capture_fetch_fault0_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      head_fetch_fault0_i;   // mode=1 也 capture; 投机 wrong-path fetch fault residual 由
                             // clear_arch_squash cause-gate 在被 squash 时清(见 OooPendingTrapExitSequencer)
  wire trap_exit_capture_arch0_w =
      capture_base_w &&
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
       // rob-walk 下仍过滤无 provenance 的 pseudo default ACCESS；真实 lane1
       // fetch AF 由 head_fetch_fault1_i 证明 owner，必须 capture 后等待 branch resolve。
       !(rob_walk_mode_i && !head_fetch_fault1_i &&
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
       !(rob_walk_mode_i && !head_fetch_fault1_i &&
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
      trap_exit_capture_fetch_fault0_w ? head_fetch_fault_tval_i :
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
