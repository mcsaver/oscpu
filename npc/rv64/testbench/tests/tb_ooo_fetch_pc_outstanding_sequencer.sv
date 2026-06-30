`include "tb_common.svh"
`include "define.v"

module tb_ooo_fetch_pc_outstanding_sequencer;
  reg clk;
  reg rst;
  reg [`XLEN-1:0] reset_pc;

  reg fetch_rsp_enqueue;
  reg fetch_rsp_bypass_consumed;
  reg fetch_rsp_fire;
  reg [`XLEN-1:0] fetch_rsp_packet_next_pc;
  reg fetch_req_fire;
  reg [`XLEN-1:0] fetch_req_pc;

  reg csr_trap_mem_valid;
  reg [`XLEN-1:0] csr_trap_target;
  reg [`XLEN-1:0] csr_ret_target;

  reg direct_frontend_flush;
  reg branch_fallthrough_keep_outstanding;
  reg direct_jal_fire;
  reg [`XLEN-1:0] direct_jal_target;
  reg direct_ret_fire;
  reg [`XLEN-1:0] direct_ret_target;
  reg direct_branch_fire;
  reg direct_branch1_fire;
  reg direct_branch0_lane1_ret;
  reg return_cont_dispatch;
  reg [`XLEN-1:0] return_cont_next_pc;
  reg [`XLEN-1:0] ras_top;
  reg branch_target_dispatch;
  reg [`XLEN-1:0] branch_target_cache_next_pc;
  reg branch_fallthrough_dispatch;
  reg [`XLEN-1:0] head_next_pc1;
  reg direct_branch_resolve_redirect;
  reg [`XLEN-1:0] direct_branch_resolve_next_pc;
  reg direct_branch_spec_start;
  reg [`XLEN-1:0] direct_branch_pred_pc;
  reg [`XLEN-1:0] head_next_pc0;
  reg branch_fallthrough_capture_rsp;

  reg branch_spec_resolve_valid;
  reg branch_spec_restore;
  reg core_branch_resolve_misaligned;
  reg [`XLEN-1:0] core_branch_resolve_next_pc;

  reg pending_branch_commit_resolve;
  reg pending_branch_match_clear;
  reg pending_branch_misaligned;
  reg [`XLEN-1:0] pending_branch_next_pc;

  reg branch_prefetch_pending_match;
  reg [`XLEN-1:0] branch_prefetch_pc;
  reg branch_prefetch_hit_available;
  reg [`XLEN-1:0] branch_prefetch_hit_packet_next_pc;

  reg branch_resolve_untracked;

  reg pending_jump_resolve_ready;
  reg pending_jump_misaligned;
  reg pending_jump_nolink_commit;
  reg pending_jump_redirect_after_dispatch;
  reg jalr_prefetch_pending_match;
  reg jalr_prefetch_hit_available;
  reg [`XLEN-1:0] jalr_prefetch_hit_packet_next_pc;
  reg [`XLEN-1:0] pending_jump_resolved_target;

  reg pending_system_csr_commit;
  reg [`XLEN-1:0] pending_system_next_pc;

  reg drain_complete;
  reg pending_arch_trap;
  reg pending_system;
  reg pending_system_ecall;
  reg pending_system_irq;
  reg pending_system_mret;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg pending_jump;
  reg [`XLEN-1:0] pending_jump_target;
  reg pending_mem;
  reg [`XLEN-1:0] pending_mem_next_pc;
  reg pending_fp;
  reg [`XLEN-1:0] pending_fp_next_pc;

  wire [`XLEN-1:0] next_fetch_pc;
  wire outstanding_valid;
  wire [`XLEN-1:0] outstanding_pc;
  wire discard_fetch_rsp;

  OooFetchPcOutstandingSequencer dut (
    .clk(clk),
    .rst(rst),
    .reset_pc_i(reset_pc),
    .fetch_rsp_enqueue_i(fetch_rsp_enqueue),
    .fetch_rsp_bypass_consumed_i(fetch_rsp_bypass_consumed),
    .fetch_rsp_fire_i(fetch_rsp_fire),
    .fetch_rsp_packet_next_pc_i(fetch_rsp_packet_next_pc),
    .fetch_req_fire_i(fetch_req_fire),
    .fetch_req_pc_i(fetch_req_pc),
    .csr_trap_mem_valid_i(csr_trap_mem_valid),
    .csr_trap_target_i(csr_trap_target),
    .csr_ret_target_i(csr_ret_target),
    .direct_frontend_flush_i(direct_frontend_flush),
    .branch_fallthrough_keep_outstanding_i(branch_fallthrough_keep_outstanding),
    .direct_jal_fire_i(direct_jal_fire),
    .direct_jal_target_i(direct_jal_target),
    .direct_ret_fire_i(direct_ret_fire),
    .direct_ret_target_i(direct_ret_target),
    .direct_branch_fire_i(direct_branch_fire),
    .direct_branch1_fire_i(direct_branch1_fire),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret),
    .return_cont_dispatch_i(return_cont_dispatch),
    .return_cont_next_pc_i(return_cont_next_pc),
    .ras_top_i(ras_top),
    .branch_target_dispatch_i(branch_target_dispatch),
    .branch_target_cache_next_pc_i(branch_target_cache_next_pc),
    .branch_fallthrough_dispatch_i(branch_fallthrough_dispatch),
    .head_next_pc1_i(head_next_pc1),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect),
    .direct_branch_resolve_next_pc_i(direct_branch_resolve_next_pc),
    .direct_branch_spec_start_i(direct_branch_spec_start),
    .direct_branch_pred_pc_i(direct_branch_pred_pc),
    .head_next_pc0_i(head_next_pc0),
    .branch_fallthrough_capture_rsp_i(branch_fallthrough_capture_rsp),
    .direct_jump_spec_fire_i(1'b0),
    .direct_jump_spec_target_i('0),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid),
    .branch_spec_restore_i(branch_spec_restore),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve),
    .pending_branch_match_clear_i(pending_branch_match_clear),
    .pending_branch_misaligned_i(pending_branch_misaligned),
    .pending_branch_next_pc_i(pending_branch_next_pc),
    .branch_prefetch_pending_match_i(branch_prefetch_pending_match),
    .branch_prefetch_pc_i(branch_prefetch_pc),
    .branch_prefetch_hit_available_i(branch_prefetch_hit_available),
    .branch_prefetch_hit_packet_next_pc_i(branch_prefetch_hit_packet_next_pc),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready),
    .pending_jump_misaligned_i(pending_jump_misaligned),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit),
    .pending_jump_redirect_after_dispatch_i(pending_jump_redirect_after_dispatch),
    .jalr_prefetch_pending_match_i(jalr_prefetch_pending_match),
    .jalr_prefetch_hit_available_i(jalr_prefetch_hit_available),
    .jalr_prefetch_hit_packet_next_pc_i(jalr_prefetch_hit_packet_next_pc),
    .pending_jump_resolved_target_i(pending_jump_resolved_target),
    .pending_system_csr_commit_i(pending_system_csr_commit),
    .pending_system_next_pc_i(pending_system_next_pc),
    .drain_complete_i(drain_complete),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_system_i(pending_system),
    .pending_system_ecall_i(pending_system_ecall),
    .pending_system_irq_i(pending_system_irq),
    .pending_system_mret_i(pending_system_mret),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .pending_jump_i(pending_jump),
    .pending_jump_target_i(pending_jump_target),
    .pending_mem_i(pending_mem),
    .pending_mem_next_pc_i(pending_mem_next_pc),
    .pending_fp_i(pending_fp),
    .pending_fp_next_pc_i(pending_fp_next_pc),
    .next_fetch_pc_o(next_fetch_pc),
    .outstanding_valid_o(outstanding_valid),
    .outstanding_pc_o(outstanding_pc),
    .discard_fetch_rsp_o(discard_fetch_rsp)
  );

  task automatic tick;
    begin
      #1 clk = 1'b1;
      #1 clk = 1'b0;
    end
  endtask

  task automatic clear_inputs;
    begin
      fetch_rsp_enqueue = 1'b0;
      fetch_rsp_bypass_consumed = 1'b0;
      fetch_rsp_fire = 1'b0;
      fetch_rsp_packet_next_pc = {`XLEN{1'b0}};
      fetch_req_fire = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      csr_trap_mem_valid = 1'b0;
      csr_trap_target = {`XLEN{1'b0}};
      csr_ret_target = {`XLEN{1'b0}};
      direct_frontend_flush = 1'b0;
      branch_fallthrough_keep_outstanding = 1'b0;
      direct_jal_fire = 1'b0;
      direct_jal_target = {`XLEN{1'b0}};
      direct_ret_fire = 1'b0;
      direct_ret_target = {`XLEN{1'b0}};
      direct_branch_fire = 1'b0;
      direct_branch1_fire = 1'b0;
      direct_branch0_lane1_ret = 1'b0;
      return_cont_dispatch = 1'b0;
      return_cont_next_pc = {`XLEN{1'b0}};
      ras_top = {`XLEN{1'b0}};
      branch_target_dispatch = 1'b0;
      branch_target_cache_next_pc = {`XLEN{1'b0}};
      branch_fallthrough_dispatch = 1'b0;
      head_next_pc1 = {`XLEN{1'b0}};
      direct_branch_resolve_redirect = 1'b0;
      direct_branch_resolve_next_pc = {`XLEN{1'b0}};
      direct_branch_spec_start = 1'b0;
      direct_branch_pred_pc = {`XLEN{1'b0}};
      head_next_pc0 = {`XLEN{1'b0}};
      branch_fallthrough_capture_rsp = 1'b0;
      branch_spec_resolve_valid = 1'b0;
      branch_spec_restore = 1'b0;
      core_branch_resolve_misaligned = 1'b0;
      core_branch_resolve_next_pc = {`XLEN{1'b0}};
      pending_branch_commit_resolve = 1'b0;
      pending_branch_match_clear = 1'b0;
      pending_branch_misaligned = 1'b0;
      pending_branch_next_pc = {`XLEN{1'b0}};
      branch_prefetch_pending_match = 1'b0;
      branch_prefetch_pc = {`XLEN{1'b0}};
      branch_prefetch_hit_available = 1'b0;
      branch_prefetch_hit_packet_next_pc = {`XLEN{1'b0}};
      branch_resolve_untracked = 1'b0;
      pending_jump_resolve_ready = 1'b0;
      pending_jump_misaligned = 1'b0;
      pending_jump_nolink_commit = 1'b0;
      pending_jump_redirect_after_dispatch = 1'b0;
      jalr_prefetch_pending_match = 1'b0;
      jalr_prefetch_hit_available = 1'b0;
      jalr_prefetch_hit_packet_next_pc = {`XLEN{1'b0}};
      pending_jump_resolved_target = {`XLEN{1'b0}};
      pending_system_csr_commit = 1'b0;
      pending_system_next_pc = {`XLEN{1'b0}};
      drain_complete = 1'b0;
      pending_arch_trap = 1'b0;
      pending_system = 1'b0;
      pending_system_ecall = 1'b0;
      pending_system_irq = 1'b0;
      pending_system_mret = 1'b0;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      pending_jump = 1'b0;
      pending_jump_target = {`XLEN{1'b0}};
      pending_mem = 1'b0;
      pending_mem_next_pc = {`XLEN{1'b0}};
      pending_fp = 1'b0;
      pending_fp_next_pc = {`XLEN{1'b0}};
    end
  endtask

  task automatic reset_dut;
    input [`XLEN-1:0] pc;
    begin
      clear_inputs();
      reset_pc = pc;
      rst = 1'b1;
      tick();
      rst = 1'b0;
      clear_inputs();
    end
  endtask

  task automatic check_state;
    input [1023:0] what;
    input [`XLEN-1:0] exp_next_pc;
    input exp_outstanding_valid;
    input [`XLEN-1:0] exp_outstanding_pc;
    input exp_discard;
    begin
      if (next_fetch_pc !== exp_next_pc) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s next_pc got=0x%016x expected=0x%016x",
                 what, next_fetch_pc, exp_next_pc);
      end
      tb_check1({what, " outstanding_valid"}, outstanding_valid,
                exp_outstanding_valid);
      if (outstanding_pc !== exp_outstanding_pc) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s outstanding_pc got=0x%016x expected=0x%016x",
                 what, outstanding_pc, exp_outstanding_pc);
      end
      tb_check1({what, " discard"}, discard_fetch_rsp, exp_discard);
    end
  endtask

  task automatic issue_fetch;
    input [`XLEN-1:0] pc;
    begin
      clear_inputs();
      fetch_req_fire = 1'b1;
      fetch_req_pc = pc;
      tick();
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b0;
    reset_pc = 64'h0000_0000_8000_0000;
    tb_errors = 0;
    clear_inputs();

    reset_dut(64'h0000_0000_8000_0000);
    check_state("reset", 64'h0000_0000_8000_0000, 1'b0,
                {`XLEN{1'b0}}, 1'b0);

    issue_fetch(64'h0000_0000_8000_1000);
    check_state("request arms outstanding", 64'h0000_0000_8000_1000,
                1'b1, 64'h0000_0000_8000_1000, 1'b0);

    clear_inputs();
    fetch_rsp_fire = 1'b1;
    fetch_rsp_enqueue = 1'b1;
    fetch_rsp_packet_next_pc = 64'h0000_0000_8000_1004;
    tick();
    check_state("response advances pc and clears outstanding",
                64'h0000_0000_8000_1004, 1'b0,
                64'h0000_0000_8000_1000, 1'b0);

    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_2000);
    clear_inputs();
    pending_branch_commit_resolve = 1'b1;
    pending_branch_next_pc = 64'h0000_0000_8000_3000;
    tick();
    check_state("pending branch commit drops stale outstanding",
                64'h0000_0000_8000_3000, 1'b0, {`XLEN{1'b0}}, 1'b1);

    clear_inputs();
    fetch_rsp_fire = 1'b1;
    tick();
    check_state("stale response clears discard",
                64'h0000_0000_8000_3000, 1'b0, {`XLEN{1'b0}}, 1'b0);

    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_4000);
    clear_inputs();
    direct_frontend_flush = 1'b1;
    branch_fallthrough_keep_outstanding = 1'b1;
    direct_branch_fire = 1'b1;
    branch_fallthrough_dispatch = 1'b1;
    head_next_pc1 = 64'h0000_0000_8000_4010;
    tick();
    check_state("direct fallthrough keeps outstanding",
                64'h0000_0000_8000_4010, 1'b1,
                64'h0000_0000_8000_4000, 1'b0);

    clear_inputs();
    direct_frontend_flush = 1'b1;
    direct_branch_fire = 1'b1;
    branch_fallthrough_dispatch = 1'b1;
    head_next_pc1 = 64'h0000_0000_8000_5004;
    branch_fallthrough_capture_rsp = 1'b1;
    fetch_rsp_packet_next_pc = 64'h0000_0000_8000_5008;
    tick();
    check_state("fallthrough response capture overrides direct branch pc",
                64'h0000_0000_8000_5008, 1'b0, {`XLEN{1'b0}}, 1'b1);

    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_6000);
    clear_inputs();
    branch_spec_resolve_valid = 1'b1;
    branch_spec_restore = 1'b1;
    fetch_req_fire = 1'b1;
    fetch_req_pc = 64'h0000_0000_8000_7000;
    core_branch_resolve_next_pc = 64'h0000_0000_8000_7004;
    tick();
    check_state("branch spec restore redirects and adopts request",
                64'h0000_0000_8000_7004, 1'b1,
                64'h0000_0000_8000_7000, 1'b1);

    reset_dut(64'h0000_0000_8000_0000);
    clear_inputs();
    pending_branch_match_clear = 1'b1;
    branch_prefetch_pending_match = 1'b1;
    branch_prefetch_pc = 64'h0000_0000_8000_8000;
    branch_prefetch_hit_available = 1'b1;
    branch_prefetch_hit_packet_next_pc = 64'h0000_0000_8000_8008;
    core_branch_resolve_next_pc = 64'h0000_0000_8000_8010;
    tick();
    check_state("pending branch match adopts prefetch outstanding",
                64'h0000_0000_8000_8008, 1'b1,
                64'h0000_0000_8000_8000, 1'b0);

    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_8800);
    clear_inputs();
    pending_jump_resolve_ready = 1'b1;
    pending_jump_nolink_commit = 1'b1;
    fetch_req_fire = 1'b1;
    fetch_req_pc = 64'h0000_0000_8000_9000;
    jalr_prefetch_hit_available = 1'b1;
    jalr_prefetch_hit_packet_next_pc = 64'h0000_0000_8000_9008;
    pending_jump_resolved_target = 64'h0000_0000_8000_9998;
    tick();
    check_state("pending jalr hit redirects and discards overlap",
                64'h0000_0000_8000_9008, 1'b1,
                64'h0000_0000_8000_9000, 1'b1);

    reset_dut(64'h0000_0000_8000_0000);
    clear_inputs();
    drain_complete = 1'b1;
    pending_system = 1'b1;
    pending_system_mret = 1'b1;
    csr_ret_target = 64'h0000_0000_8000_a000;
    tick();
    check_state("drained mret selects csr return target",
                64'h0000_0000_8000_a000, 1'b0, {`XLEN{1'b0}}, 1'b0);

    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_b000);
    clear_inputs();
    drain_complete = 1'b1;
    pending_jump = 1'b1;
    pending_jump_target = 64'h0000_0000_8000_b100;
    tick();
    check_state("drained pending jump drops old outstanding",
                64'h0000_0000_8000_b100, 1'b0, {`XLEN{1'b0}}, 1'b1);

    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_c800);
    clear_inputs();
    csr_trap_mem_valid = 1'b1;
    csr_trap_target = 64'h0000_0000_8000_c000;
    direct_frontend_flush = 1'b1;
    direct_jal_fire = 1'b1;
    direct_jal_target = 64'h0000_0000_dead_beef;
    tick();
    check_state("late csr trap wins over direct flush",
                64'h0000_0000_8000_c000, 1'b0, {`XLEN{1'b0}}, 1'b1);

    tb_finish("tb_ooo_fetch_pc_outstanding_sequencer");
  end
endmodule

