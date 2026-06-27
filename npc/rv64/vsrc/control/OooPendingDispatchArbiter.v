`include "include/define.v"
`include "common/OooSlotFacts.vh"

// Pure combinational pending-owner event arbitration for OooAluFetchCore.
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

  input dispatch0_arch_trap_i,
  input dispatch0_exit_i,
  input dispatch0_ecall_i,
  input dispatch0_ebreak_i,
  input dispatch0_fp_i,
  input dispatch0_system_i,
  input dispatch0_branch_i,
  input direct_branch0_dispatch_valid_i,
  input dispatch0_jal_i,
  input direct_jal0_dispatch_valid_i,
  input dispatch0_jump_i,
  input dispatch0_return_i,
  input dispatch0_unsupported_i,
  input dispatch_unsupported_i,
  input dispatch1_barrier_fire_i,

  input head0_csr_illegal_i,
  input head0_semihost_ebreak_i,
  input head1_system_raw_i,
  input head1_exit_raw_i,
  input head1_ecall_raw_i,
  input head1_ebreak_raw_i,
  input head1_arch_trap_raw_i,
  input head1_illegal_raw_i,
  input head1_fp_disabled_i,
  input head1_priv_system_illegal_i,
  input head1_csr_illegal_i,
  input head1_semihost_ebreak_i,

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

  output pending_fp_capture_head0_o,
  output pending_fp_capture_lane1_o,
  output pending_fp_clear_o,

  output pending_mem_capture_lane1_o,
  output pending_mem_clear_o,

  output pending_trap_exit_clear_exit_o,
  output pending_trap_exit_clear_arch_o,
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
  wire dispatch0_fp_w = dispatch0_facts_i[`OOO_SLOT_FACT_FP_ENABLED];
  wire dispatch0_system_w = dispatch0_facts_i[`OOO_SLOT_FACT_SYSTEM];
  wire dispatch0_branch_w = dispatch0_facts_i[`OOO_SLOT_FACT_BRANCH];
  wire dispatch0_jal_w = dispatch0_facts_i[`OOO_SLOT_FACT_JAL];
  wire dispatch0_jump_w = dispatch0_facts_i[`OOO_SLOT_FACT_JALR];
  wire head0_semihost_ebreak_w =
      dispatch0_facts_i[`OOO_SLOT_FACT_SEMIHOST_EBREAK];
  wire head1_system_raw_w = head1_facts_i[`OOO_SLOT_FACT_SYSTEM];
  wire head1_exit_raw_w = head1_facts_i[`OOO_SLOT_FACT_EXIT];
  wire head1_ecall_raw_w = head1_facts_i[`OOO_SLOT_FACT_ECALL];
  wire head1_ebreak_raw_w = head1_facts_i[`OOO_SLOT_FACT_EBREAK];
  wire head1_arch_trap_raw_w = head1_facts_i[`OOO_SLOT_FACT_ARCH_TRAP];
  wire head1_illegal_raw_w = head1_facts_i[`OOO_SLOT_FACT_ILLEGAL];
  wire head1_fp_disabled_w = head1_facts_i[`OOO_SLOT_FACT_FP_DISABLED];
  wire head1_priv_system_illegal_w =
      head1_facts_i[`OOO_SLOT_FACT_PRIV_SYSTEM_ILLEGAL];
  wire head1_semihost_ebreak_w =
      head1_facts_i[`OOO_SLOT_FACT_SEMIHOST_EBREAK];
  wire direct_branch_fire_w =
      direct_branch0_fire_i || direct_branch1_fire_i;
  wire lane0_branch_pending_w =
      dispatch0_branch_w && !direct_branch0_dispatch_valid_i;
  wire lane0_jump_pending_w =
      (dispatch0_jal_w && !direct_jal0_dispatch_valid_i) ||
      (dispatch0_jump_w && !dispatch0_return_i);
  wire lane1_barrier_base_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_fp_w &&
      !dispatch0_system_w &&
      !lane0_branch_pending_w &&
      !lane0_jump_pending_w &&
      dispatch1_barrier_fire_i;

  assign pending_system_capture_irq_o =
      capture_base_w && csr_irq_pending_i;
  assign pending_system_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_fp_w &&
      dispatch0_system_w && !head0_csr_illegal_i;
  assign pending_system_capture_lane1_o =
      lane1_barrier_base_w &&
      head1_system_raw_w && !head1_csr_illegal_i &&
      !head1_arch_trap_raw_w;

  assign pending_branch_capture_direct_o =
      direct_frontend_flush_i && direct_branch_fire_w;
  assign pending_branch_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_fp_w &&
      !dispatch0_system_w &&
      lane0_branch_pending_w;
  assign pending_branch_capture_lane1_o = lane1_barrier_base_w;

  assign pending_jump_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_fp_w &&
      !dispatch0_system_w &&
      !lane0_branch_pending_w &&
      lane0_jump_pending_w;
  assign pending_jump_capture_lane1_o = lane1_barrier_base_w;

  assign pending_fp_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      dispatch0_fp_w;
  assign pending_fp_capture_lane1_o = lane1_barrier_base_w;

  assign pending_mem_capture_lane1_o = lane1_barrier_base_w;

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
       dispatch0_fp_w ||
       dispatch0_system_w ||
       lane0_jump_pending_w ||
       dispatch_unsupported_i);
  wire jump_capture_clear_w =
      capture_base_w &&
      (csr_irq_pending_i ||
       head_fetch_fault0_i ||
       dispatch0_arch_trap_w ||
       dispatch0_exit_w ||
       dispatch0_fp_w ||
       dispatch0_system_w ||
       lane0_branch_pending_w ||
       dispatch_unsupported_i);
  wire mem_capture_clear_w =
      capture_base_w &&
      (csr_irq_pending_i ||
       head_fetch_fault0_i ||
       dispatch0_arch_trap_w ||
       dispatch0_exit_w ||
       dispatch0_fp_w ||
       dispatch0_system_w ||
       lane0_branch_pending_w ||
       lane0_jump_pending_w ||
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
  assign pending_fp_clear_o = drain_clear_w;
  assign pending_system_clear_o =
      csr_trap_mem_valid_i ||
      direct_frontend_flush_i ||
      resolve_clear_w ||
      pending_jump_clear_from_resolve_w;
  assign pending_mem_clear_o =
      direct_frontend_flush_i ||
      resolve_clear_w ||
      pending_jump_clear_from_resolve_w ||
      mem_capture_clear_w;

  wire trap_exit_capture_fetch_fault0_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      head_fetch_fault0_i;
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
      !dispatch0_fp_w &&
      dispatch0_system_w && head0_csr_illegal_i;
  wire trap_exit_capture_lane1_w = pending_fp_capture_lane1_o;
  wire trap_exit_capture_unsupported_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      !dispatch0_fp_w &&
      !dispatch0_system_w &&
      !lane0_branch_pending_w &&
      !lane0_jump_pending_w &&
      !dispatch1_barrier_fire_i &&
      dispatch_unsupported_i;

  wire trap_exit_lane1_arch_valid_w =
      head_fetch_fault1_i || head1_csr_illegal_i ||
      head1_arch_trap_raw_w;
  wire [`TRAP_CAUSE_W-1:0] trap_exit_lane1_cause_w =
      head1_semihost_ebreak_w ? `EXC_BREAKPOINT :
      head1_illegal_raw_w ? `EXC_ILLEGAL_INST :
      head1_fp_disabled_w ? `EXC_ILLEGAL_INST :
      head1_priv_system_illegal_w ? `EXC_ILLEGAL_INST :
      head1_csr_illegal_i ? `EXC_ILLEGAL_INST :
      ((head_resp1_i == 2'b10) ? `EXC_INST_PAGE_FAULT :
                                  `EXC_INST_ACCESS_FAULT);
  wire [`XLEN-1:0] trap_exit_lane1_tval_w =
      head1_semihost_ebreak_w ? {`XLEN{1'b0}} :
      head1_illegal_raw_w ? head_inst1_i :
      head1_fp_disabled_w ? head_inst1_i :
      head1_priv_system_illegal_w ? head_inst1_i :
      head1_csr_illegal_i ? head_inst1_i :
      head_pc1_i;

  assign pending_trap_exit_capture_exit_o =
      trap_exit_capture_exit0_w || trap_exit_capture_lane1_w;
  assign pending_trap_exit_capture_exit_valid_o =
      trap_exit_capture_exit0_w ||
      (trap_exit_capture_lane1_w && head1_exit_raw_w);
  assign pending_trap_exit_capture_exit_ecall_o =
      trap_exit_capture_exit0_w ? dispatch0_ecall_w : head1_ecall_raw_w;
  assign pending_trap_exit_capture_exit_ebreak_o =
      trap_exit_capture_exit0_w ? dispatch0_ebreak_w : head1_ebreak_raw_w;

  assign pending_trap_exit_capture_arch_o =
      trap_exit_capture_fetch_fault0_w ||
      trap_exit_capture_arch0_w ||
      trap_exit_capture_csr_illegal0_w ||
      trap_exit_capture_lane1_w ||
      trap_exit_capture_unsupported_w;
  assign pending_trap_exit_capture_arch_valid_o =
      trap_exit_capture_fetch_fault0_w ||
      trap_exit_capture_arch0_w ||
      trap_exit_capture_csr_illegal0_w ||
      trap_exit_capture_unsupported_w ||
      (trap_exit_capture_lane1_w && trap_exit_lane1_arch_valid_w);
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
       dispatch0_fp_w ||
       dispatch0_system_w ||
       lane0_branch_pending_w ||
       lane0_jump_pending_w ||
       dispatch_unsupported_i);
  wire trap_exit_capture_clear_arch_w =
      capture_base_w &&
      (csr_irq_pending_i ||
       dispatch0_exit_w ||
       dispatch0_fp_w ||
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

endmodule
