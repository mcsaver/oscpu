`timescale 1ns/1ps
`include "include/define.v"
`include "common/OooSlotFacts.v"
`include "tb_common.svh"

module tb_ooo_pending_dispatch_arbiter;
  reg csr_trap_mem_valid;
  reg direct_frontend_flush;
  reg can_run;
  reg fifo_has_packet;
  reg csr_irq_pending;
  reg branch_spec_resolve_valid;
  reg pending_branch_commit_resolve;
  reg pending_branch_match_clear;
  reg branch_resolve_untracked;
  reg pending_jump_resolve_ready;
  reg pending_jump_misaligned;
  reg pending_jump_nolink_commit;
  reg pending_jump_redirect_after_dispatch;
  reg pending_system_csr_commit;
  reg stop_pending;
  reg drain_complete;
  reg direct_branch0_fire;
  reg direct_branch1_fire;
  reg head_fetch_fault0;
  reg head_fetch_fault1;
  reg [1:0] head_resp0;
  reg [1:0] head_resp1;
  reg [`XLEN-1:0] head_pc0;
  reg [`XLEN-1:0] head_pc1;
  reg [`INST_W-1:0] head_inst0;
  reg [`INST_W-1:0] head_inst1;
  reg dispatch0_arch_trap;
  reg dispatch0_exit;
  reg dispatch0_ecall;
  reg dispatch0_ebreak;
  reg dispatch0_fp;
  reg dispatch0_system;
  reg dispatch0_branch;
  reg direct_branch0_dispatch_valid;
  reg dispatch0_jal;
  reg direct_jal0_dispatch_valid;
  reg dispatch0_jump;
  reg dispatch0_return;
  reg dispatch0_unsupported;
  reg dispatch_unsupported;
  reg dispatch1_barrier_fire;
  reg head0_csr_illegal;
  reg head0_semihost_ebreak;
  reg head1_system_raw;
  reg head1_branch_raw;
  reg head1_jump_raw;
  reg head1_mem_raw;
  reg head1_fp_enabled;
  reg head1_exit_raw;
  reg head1_ecall_raw;
  reg head1_ebreak_raw;
  reg head1_arch_trap_raw;
  reg head1_illegal_raw;
  reg head1_fp_disabled;
  reg head1_priv_system_illegal;
  reg head1_csr_illegal;
  reg head1_semihost_ebreak;
  reg [`OOO_SLOT_FACTS_W-1:0] dispatch0_facts;
  reg [`OOO_SLOT_FACTS_W-1:0] head1_facts;

  wire pending_system_capture_irq;
  wire pending_system_capture_head0;
  wire pending_system_capture_lane1;
  wire pending_system_clear;
  wire pending_branch_capture_direct;
  wire pending_branch_capture_head0;
  wire pending_branch_capture_lane1;
  wire pending_branch_clear;
  wire pending_jump_capture_head0;
  wire pending_jump_capture_lane1;
  wire pending_jump_clear;
  wire pending_trap_exit_clear_exit;
  wire pending_trap_exit_clear_arch;
  wire pending_trap_exit_capture_exit;
  wire pending_trap_exit_capture_exit_valid;
  wire pending_trap_exit_capture_exit_ecall;
  wire pending_trap_exit_capture_exit_ebreak;
  wire pending_trap_exit_capture_arch;
  wire pending_trap_exit_capture_arch_valid;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_exit_capture_cause;
  wire [`XLEN-1:0] pending_trap_exit_capture_pc;
  wire [`XLEN-1:0] pending_trap_exit_capture_tval;

  OooPendingDispatchArbiter dut (
    .csr_trap_mem_valid_i(csr_trap_mem_valid),
    .direct_frontend_flush_i(direct_frontend_flush),
    .can_run_i(can_run),
    .fifo_has_packet_i(fifo_has_packet),
    .csr_irq_pending_i(csr_irq_pending),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve),
    .pending_branch_match_clear_i(pending_branch_match_clear),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready),
    .pending_jump_misaligned_i(pending_jump_misaligned),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit),
    .pending_jump_redirect_after_dispatch_i(pending_jump_redirect_after_dispatch),
    .pending_system_csr_commit_i(pending_system_csr_commit),
    .stop_pending_i(stop_pending),
    .drain_complete_i(drain_complete),
    .direct_branch0_fire_i(direct_branch0_fire),
    .direct_branch1_fire_i(direct_branch1_fire),
    .head_fetch_fault0_i(head_fetch_fault0),
    .head_fetch_fault1_i(head_fetch_fault1),
    .head_resp0_i(head_resp0),
    .head_resp1_i(head_resp1),
    .head_pc0_i(head_pc0),
    .head_pc1_i(head_pc1),
    .head_inst0_i(head_inst0),
    .head_inst1_i(head_inst1),
    .dispatch0_facts_i(dispatch0_facts),
    .head1_facts_i(head1_facts),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .direct_jal0_dispatch_valid_i(direct_jal0_dispatch_valid),
    .dispatch0_return_i(dispatch0_return),
    .dispatch0_unsupported_i(dispatch0_unsupported),
    .dispatch_unsupported_i(dispatch_unsupported),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .head0_csr_illegal_i(head0_csr_illegal),
    .head1_csr_illegal_i(head1_csr_illegal),
    .rob_walk_mode_i(1'b0),
    .pending_system_capture_irq_o(pending_system_capture_irq),
    .pending_system_capture_head0_o(pending_system_capture_head0),
    .pending_system_capture_lane1_o(pending_system_capture_lane1),
    .pending_system_clear_o(pending_system_clear),
    .pending_branch_capture_direct_o(pending_branch_capture_direct),
    .pending_branch_capture_head0_o(pending_branch_capture_head0),
    .pending_branch_capture_lane1_o(pending_branch_capture_lane1),
    .pending_branch_clear_o(pending_branch_clear),
    .pending_jump_capture_head0_o(pending_jump_capture_head0),
    .pending_jump_capture_lane1_o(pending_jump_capture_lane1),
    .pending_jump_clear_o(pending_jump_clear),
    .pending_trap_exit_clear_exit_o(pending_trap_exit_clear_exit),
    .pending_trap_exit_clear_arch_o(pending_trap_exit_clear_arch),
    .pending_trap_exit_capture_exit_o(pending_trap_exit_capture_exit),
    .pending_trap_exit_capture_exit_valid_o(
        pending_trap_exit_capture_exit_valid),
    .pending_trap_exit_capture_exit_ecall_o(
        pending_trap_exit_capture_exit_ecall),
    .pending_trap_exit_capture_exit_ebreak_o(
        pending_trap_exit_capture_exit_ebreak),
    .pending_trap_exit_capture_arch_o(pending_trap_exit_capture_arch),
    .pending_trap_exit_capture_arch_valid_o(
        pending_trap_exit_capture_arch_valid),
    .pending_trap_exit_capture_cause_o(pending_trap_exit_capture_cause),
    .pending_trap_exit_capture_pc_o(pending_trap_exit_capture_pc),
    .pending_trap_exit_capture_tval_o(pending_trap_exit_capture_tval)
  );

  always @* begin
    dispatch0_facts = {`OOO_SLOT_FACTS_W{1'b0}};
    dispatch0_facts[`OOO_SLOT_FACT_ARCH_TRAP] = dispatch0_arch_trap;
    dispatch0_facts[`OOO_SLOT_FACT_EXIT] = dispatch0_exit;
    dispatch0_facts[`OOO_SLOT_FACT_ECALL] = dispatch0_ecall;
    dispatch0_facts[`OOO_SLOT_FACT_EBREAK] = dispatch0_ebreak;
    dispatch0_facts[`OOO_SLOT_FACT_FP_ENABLED] = dispatch0_fp;
    dispatch0_facts[`OOO_SLOT_FACT_SYSTEM] = dispatch0_system;
    dispatch0_facts[`OOO_SLOT_FACT_BRANCH] = dispatch0_branch;
    dispatch0_facts[`OOO_SLOT_FACT_JAL] = dispatch0_jal;
    dispatch0_facts[`OOO_SLOT_FACT_JALR] = dispatch0_jump;
    dispatch0_facts[`OOO_SLOT_FACT_JUMP] = dispatch0_jal | dispatch0_jump;
    dispatch0_facts[`OOO_SLOT_FACT_SEMIHOST_EBREAK] =
        head0_semihost_ebreak;

    head1_facts = {`OOO_SLOT_FACTS_W{1'b0}};
    head1_facts[`OOO_SLOT_FACT_SYSTEM] = head1_system_raw;
    head1_facts[`OOO_SLOT_FACT_BRANCH] = head1_branch_raw;
    head1_facts[`OOO_SLOT_FACT_JUMP] = head1_jump_raw;
    head1_facts[`OOO_SLOT_FACT_MEM] = head1_mem_raw;
    head1_facts[`OOO_SLOT_FACT_FP_ENABLED] = head1_fp_enabled;
    head1_facts[`OOO_SLOT_FACT_EXIT] = head1_exit_raw;
    head1_facts[`OOO_SLOT_FACT_ECALL] = head1_ecall_raw;
    head1_facts[`OOO_SLOT_FACT_EBREAK] = head1_ebreak_raw;
    head1_facts[`OOO_SLOT_FACT_ARCH_TRAP] = head1_arch_trap_raw;
    head1_facts[`OOO_SLOT_FACT_ILLEGAL] = head1_illegal_raw;
    head1_facts[`OOO_SLOT_FACT_FP_DISABLED] = head1_fp_disabled;
    head1_facts[`OOO_SLOT_FACT_PRIV_SYSTEM_ILLEGAL] =
        head1_priv_system_illegal;
    head1_facts[`OOO_SLOT_FACT_SEMIHOST_EBREAK] =
        head1_semihost_ebreak;
  end

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

  task automatic check_cause;
    input [1023:0] what;
    input [`TRAP_CAUSE_W-1:0] got;
    input [`TRAP_CAUSE_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%0x expected=0x%0x",
                 what, got, exp);
      end
    end
  endtask

  task automatic reset_inputs;
    begin
      csr_trap_mem_valid = 1'b0;
      direct_frontend_flush = 1'b0;
      can_run = 1'b1;
      fifo_has_packet = 1'b1;
      csr_irq_pending = 1'b0;
      branch_spec_resolve_valid = 1'b0;
      pending_branch_commit_resolve = 1'b0;
      pending_branch_match_clear = 1'b0;
      branch_resolve_untracked = 1'b0;
      pending_jump_resolve_ready = 1'b0;
      pending_jump_misaligned = 1'b0;
      pending_jump_nolink_commit = 1'b0;
      pending_jump_redirect_after_dispatch = 1'b0;
      pending_system_csr_commit = 1'b0;
      stop_pending = 1'b0;
      drain_complete = 1'b0;
      direct_branch0_fire = 1'b0;
      direct_branch1_fire = 1'b0;
      head_fetch_fault0 = 1'b0;
      head_fetch_fault1 = 1'b0;
      head_resp0 = 2'b00;
      head_resp1 = 2'b00;
      head_pc0 = 64'h0000_0000_8000_1000;
      head_pc1 = 64'h0000_0000_8000_1004;
      head_inst0 = 32'h0000_0013;
      head_inst1 = 32'h0000_0093;
      dispatch0_arch_trap = 1'b0;
      dispatch0_exit = 1'b0;
      dispatch0_ecall = 1'b0;
      dispatch0_ebreak = 1'b0;
      dispatch0_fp = 1'b0;
      dispatch0_system = 1'b0;
      dispatch0_branch = 1'b0;
      direct_branch0_dispatch_valid = 1'b0;
      dispatch0_jal = 1'b0;
      direct_jal0_dispatch_valid = 1'b0;
      dispatch0_jump = 1'b0;
      dispatch0_return = 1'b0;
      dispatch0_unsupported = 1'b0;
      dispatch_unsupported = 1'b0;
      dispatch1_barrier_fire = 1'b0;
      head0_csr_illegal = 1'b0;
      head0_semihost_ebreak = 1'b0;
      head1_system_raw = 1'b0;
      head1_branch_raw = 1'b0;
      head1_jump_raw = 1'b0;
      head1_mem_raw = 1'b0;
      head1_fp_enabled = 1'b0;
      head1_exit_raw = 1'b0;
      head1_ecall_raw = 1'b0;
      head1_ebreak_raw = 1'b0;
      head1_arch_trap_raw = 1'b0;
      head1_illegal_raw = 1'b0;
      head1_fp_disabled = 1'b0;
      head1_priv_system_illegal = 1'b0;
      head1_csr_illegal = 1'b0;
      head1_semihost_ebreak = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    tb_check1("idle no irq capture", pending_system_capture_irq, 1'b0);
    tb_check1("idle no branch clear", pending_branch_clear, 1'b0);

    reset_inputs();
    csr_irq_pending = 1'b1;
    #1;
    tb_check1("irq captures system", pending_system_capture_irq, 1'b1);
    tb_check1("irq blocks head0 system", pending_system_capture_head0, 1'b0);
    tb_check1("irq clears stale branch", pending_branch_clear, 1'b1);
    tb_check1("irq clears stale trap exit", pending_trap_exit_clear_exit, 1'b1);
    tb_check1("irq does not clear current system entry", pending_system_clear, 1'b0);

    reset_inputs();
    head_fetch_fault0 = 1'b1;
    head_resp0 = 2'b10;
    #1;
    tb_check1("head0 fetch fault captures arch", pending_trap_exit_capture_arch, 1'b1);
    tb_check1("head0 fetch fault arch valid", pending_trap_exit_capture_arch_valid, 1'b1);
    check_cause("head0 fetch page fault cause",
                pending_trap_exit_capture_cause, `EXC_INST_PAGE_FAULT);
    check_xlen("head0 fetch fault pc", pending_trap_exit_capture_pc, head_pc0);
    check_xlen("head0 fetch fault tval", pending_trap_exit_capture_tval, head_pc0);

    reset_inputs();
    dispatch0_system = 1'b1;
    #1;
    tb_check1("legal head0 system capture", pending_system_capture_head0, 1'b1);
    tb_check1("legal head0 system no arch capture",
              pending_trap_exit_capture_arch_valid, 1'b0);

    reset_inputs();
    dispatch0_system = 1'b1;
    head0_csr_illegal = 1'b1;
    head_inst0 = 32'h0010_2073;
    #1;
    tb_check1("illegal csr blocks system capture", pending_system_capture_head0, 1'b0);
    tb_check1("illegal csr captures arch", pending_trap_exit_capture_arch, 1'b1);
    check_cause("illegal csr cause", pending_trap_exit_capture_cause,
                `EXC_ILLEGAL_INST);
    check_xlen("illegal csr tval", pending_trap_exit_capture_tval,
               {32'b0, head_inst0});

    reset_inputs();
    dispatch0_branch = 1'b1;
    direct_branch0_dispatch_valid = 1'b0;
    #1;
    tb_check1("head0 serialized branch capture", pending_branch_capture_head0, 1'b1);
    tb_check1("serialized branch clears jump", pending_jump_clear, 1'b1);
    tb_check1("serialized branch does not clear branch", pending_branch_clear, 1'b0);

    reset_inputs();
    dispatch0_jal = 1'b1;
    direct_jal0_dispatch_valid = 1'b0;
    #1;
    tb_check1("head0 serialized jump capture", pending_jump_capture_head0, 1'b1);
    tb_check1("serialized jump clears branch", pending_branch_clear, 1'b1);
    tb_check1("serialized jump clears trap exit arch", pending_trap_exit_clear_arch, 1'b1);

    reset_inputs();
    dispatch1_barrier_fire = 1'b1;
    #1;
    tb_check1("lane1 empty barrier does not open branch capture",
              pending_branch_capture_lane1, 1'b0);
    tb_check1("lane1 empty barrier does not open jump capture",
              pending_jump_capture_lane1, 1'b0);
    tb_check1("lane1 empty barrier capture exit invalid",
              pending_trap_exit_capture_exit_valid, 1'b0);
    tb_check1("lane1 empty barrier capture arch invalid",
              pending_trap_exit_capture_arch_valid, 1'b0);

    reset_inputs();
    dispatch1_barrier_fire = 1'b1;
    head1_branch_raw = 1'b1;
    #1;
    tb_check1("lane1 branch opens only branch capture",
              pending_branch_capture_lane1, 1'b1);
    tb_check1("lane1 branch keeps jump capture closed",
              pending_jump_capture_lane1, 1'b0);

    reset_inputs();
    dispatch1_barrier_fire = 1'b1;
    head1_jump_raw = 1'b1;
    #1;
    tb_check1("lane1 jump opens only jump capture",
              pending_jump_capture_lane1, 1'b1);
    tb_check1("lane1 jump keeps branch capture closed",
              pending_branch_capture_lane1, 1'b0);

    reset_inputs();
    dispatch1_barrier_fire = 1'b1;
    head1_fp_enabled = 1'b1;
    #1;
    // 【B-FP 簇】FP 迁域 A: lane1 FP 不再 capture(执行在 FP 簇, 经 ROB 真 commit)
    tb_check1("lane1 fp keeps branch capture closed",
              pending_branch_capture_lane1, 1'b0);
    tb_check1("lane1 fp keeps jump capture closed",
              pending_jump_capture_lane1, 1'b0);

    reset_inputs();
    dispatch1_barrier_fire = 1'b1;
    head1_exit_raw = 1'b1;
    head1_ecall_raw = 1'b1;
    #1;
    tb_check1("lane1 exit capture valid", pending_trap_exit_capture_exit_valid, 1'b1);
    tb_check1("lane1 ecall payload", pending_trap_exit_capture_exit_ecall, 1'b1);
    tb_check1("lane1 ebreak payload clear", pending_trap_exit_capture_exit_ebreak, 1'b0);

    reset_inputs();
    dispatch1_barrier_fire = 1'b1;
    head_fetch_fault1 = 1'b1;
    head_resp1 = 2'b01;
    #1;
    tb_check1("lane1 fetch fault arch valid", pending_trap_exit_capture_arch_valid, 1'b1);
    check_cause("lane1 fetch access fault cause",
                pending_trap_exit_capture_cause, `EXC_INST_ACCESS_FAULT);
    check_xlen("lane1 fetch fault pc", pending_trap_exit_capture_pc, head_pc1);
    check_xlen("lane1 fetch fault tval", pending_trap_exit_capture_tval, head_pc1);

    reset_inputs();
    dispatch_unsupported = 1'b1;
    dispatch0_unsupported = 1'b1;
    head_inst0 = 32'hffff_ffff;
    #1;
    tb_check1("slot0 unsupported captures arch", pending_trap_exit_capture_arch_valid, 1'b1);
    check_xlen("slot0 unsupported pc", pending_trap_exit_capture_pc, head_pc0);
    check_xlen("slot0 unsupported tval", pending_trap_exit_capture_tval,
               {32'b0, head_inst0});

    reset_inputs();
    dispatch_unsupported = 1'b1;
    dispatch0_unsupported = 1'b0;
    head_inst1 = 32'heeee_eeee;
    #1;
    tb_check1("lane1 unsupported captures arch", pending_trap_exit_capture_arch_valid, 1'b1);
    check_xlen("lane1 unsupported pc", pending_trap_exit_capture_pc, head_pc1);
    check_xlen("lane1 unsupported tval", pending_trap_exit_capture_tval,
               {32'b0, head_inst1});

    reset_inputs();
    direct_frontend_flush = 1'b1;
    direct_branch0_fire = 1'b1;
    #1;
    tb_check1("direct branch capture", pending_branch_capture_direct, 1'b1);
    tb_check1("direct flush clears jump", pending_jump_clear, 1'b1);
    tb_check1("direct flush clears system", pending_system_clear, 1'b1);
    tb_check1("direct branch clears exit", pending_trap_exit_clear_exit, 1'b1);
    tb_check1("direct flush does not clear branch directly", pending_branch_clear, 1'b0);

    reset_inputs();
    pending_jump_resolve_ready = 1'b1;
    pending_jump_misaligned = 1'b1;
    #1;
    tb_check1("jump redirect clears branch", pending_branch_clear, 1'b1);
    tb_check1("jump redirect clears jump", pending_jump_clear, 1'b1);
    tb_check1("jump redirect clears exit", pending_trap_exit_clear_exit, 1'b1);
    tb_check1("jump redirect does not clear arch", pending_trap_exit_clear_arch, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    drain_complete = 1'b1;
    #1;
    tb_check1("drain clears system", pending_system_clear, 1'b1);
    tb_check1("drain clears trap arch", pending_trap_exit_clear_arch, 1'b1);

    tb_finish("tb_ooo_pending_dispatch_arbiter");
  end
endmodule
