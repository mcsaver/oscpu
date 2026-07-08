`include "tb_common.svh"
`include "define.v"

// 【P4 切消费点(2026-07-09)】DUT 的 E1/E3/E4/E5/E6 六处 next_fetch_pc 写已删, PC 经
// redirect_valid/redirect_pc(OooRedirectArbiter 赢家)在文本最后单点回注; 各臂
// outstanding/discard 记账全保留。本 TB 口径同步为「记账臂 + arb 终写」: 原用例中被删
// PC 写的臂改为同拍驱动 redirect_valid/redirect_pc(模拟 arbiter 赢家), 记账期望不变;
// 保留 PC 写的臂(E7/E8/E9/顺序)用例原样。
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

  reg direct_frontend_flush;
  reg branch_fallthrough_keep_outstanding;

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
  reg head0_csr_commit;

  reg drain_complete;
  reg pending_arch_trap;
  reg pending_system;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg pending_jump;
  reg pending_mem;

  reg redirect_valid;
  reg [`XLEN-1:0] redirect_pc;

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
    .direct_frontend_flush_i(direct_frontend_flush),
    .branch_fallthrough_keep_outstanding_i(branch_fallthrough_keep_outstanding),
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
    .head0_csr_commit_i(head0_csr_commit),
    .drain_complete_i(drain_complete),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_system_i(pending_system),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .pending_jump_i(pending_jump),
    .pending_mem_i(pending_mem),
    .redirect_valid_i(redirect_valid),
    .redirect_pc_i(redirect_pc),
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
      direct_frontend_flush = 1'b0;
      branch_fallthrough_keep_outstanding = 1'b0;
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
      head0_csr_commit = 1'b0;
      drain_complete = 1'b0;
      pending_arch_trap = 1'b0;
      pending_system = 1'b0;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      pending_jump = 1'b0;
      pending_mem = 1'b0;
      redirect_valid = 1'b0;
      redirect_pc = {`XLEN{1'b0}};
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

    // ── 顺序/记账基础(未动臂) ──
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

    // ── E7 commit_resolve(保留臂, 记账+PC 都在模块内) ──
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

    // ── E4 direct flush: 记账在模块内, PC 由 arb 终写回注(redirect_pc=direct 赢家) ──
    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_4000);
    clear_inputs();
    direct_frontend_flush = 1'b1;
    branch_fallthrough_keep_outstanding = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_4010;   // arbiter direct 口赢家(e4 构造式)
    tick();
    check_state("direct fallthrough keeps outstanding",
                64'h0000_0000_8000_4010, 1'b1,
                64'h0000_0000_8000_4000, 1'b0);

    clear_inputs();
    direct_frontend_flush = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_5008;   // capture 覆写已并入 e4 构造式(前端侧)
    tick();
    check_state("direct flush adopts arb winner and discards stale",
                64'h0000_0000_8000_5008, 1'b0, {`XLEN{1'b0}}, 1'b1);

    // ── E9 branch_spec restore(保留臂) ──
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

    // ── E7 match_clear(保留臂) ──
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

    // ── E8 pending_jump(保留臂, tie-0 死硅——TB 直激哨兵路径) ──
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

    // ── E3 untracked: 记账在模块内, PC 由 arb 终写(branch 口赢家) ──
    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_9800);
    clear_inputs();
    branch_resolve_untracked = 1'b1;
    core_branch_resolve_next_pc = 64'h0000_0000_8000_9900;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_9900;
    tick();
    check_state("untracked bookkeeping plus arb write",
                64'h0000_0000_8000_9900, 1'b0, {`XLEN{1'b0}}, 1'b1);

    // ── E3-over-E4 override(:263 系记账臂——禁止项②: 记账不得随 PC 写删除) ──
    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_9a00);
    clear_inputs();
    direct_frontend_flush = 1'b1;
    branch_resolve_untracked = 1'b1;
    fetch_req_fire = 1'b1;
    fetch_req_pc = 64'h0000_0000_8000_9b00;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_9b00;  // 年龄律 branch 胜 direct(原 :263 语义)
    tick();
    check_state("untracked-over-flush bookkeeping adopts request",
                64'h0000_0000_8000_9b00, 1'b1,
                64'h0000_0000_8000_9b00, 1'b1);

    // ── E5 csr commit: 记账在模块内, PC 由 arb 终写(trap 口 pre-mux E5) ──
    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_9c00);
    clear_inputs();
    pending_system_csr_commit = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_9d00;
    tick();
    check_state("csr commit clears outstanding and takes arb pc",
                64'h0000_0000_8000_9d00, 1'b0, {`XLEN{1'b0}}, 1'b1);

    // ── E6 drain 终态: 记账 owner 序在模块内, PC 由 arb 终写(trap 口 pre-mux E6) ──
    reset_dut(64'h0000_0000_8000_0000);
    clear_inputs();
    drain_complete = 1'b1;
    pending_system = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_a000;   // mret 目标经 pre-mux 选出
    tick();
    check_state("drained system owner takes arb pc",
                64'h0000_0000_8000_a000, 1'b0, {`XLEN{1'b0}}, 1'b0);

    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_b000);
    clear_inputs();
    drain_complete = 1'b1;
    pending_jump = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_b100;
    tick();
    check_state("drained pending jump drops old outstanding",
                64'h0000_0000_8000_b100, 1'b0, {`XLEN{1'b0}}, 1'b1);

    // ── E1 csr trap: 记账在模块内, PC 由 arb 终写(trap 口 E1 最高档); 同拍 direct
    //    flush 记账被 E1 记账(文本更后)覆盖——原 "late csr trap wins" 语义 ──
    reset_dut(64'h0000_0000_8000_0000);
    issue_fetch(64'h0000_0000_8000_c800);
    clear_inputs();
    csr_trap_mem_valid = 1'b1;
    direct_frontend_flush = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_c000;   // E1 pre-mux 最高档 = csr_trap_target
    tick();
    check_state("late csr trap wins over direct flush",
                64'h0000_0000_8000_c000, 1'b0, {`XLEN{1'b0}}, 1'b1);

    // ── arb 终写压过顺序推进(文本最后 = 最高优先) ──
    reset_dut(64'h0000_0000_8000_0000);
    clear_inputs();
    fetch_req_fire = 1'b1;
    fetch_req_pc = 64'h0000_0000_8000_d000;
    branch_resolve_untracked = 1'b1;        // 给 redirect 一个真实事件语境(E3 记账)
    redirect_valid = 1'b1;
    redirect_pc = 64'h0000_0000_8000_e000;
    tick();
    check_state("arb final write beats sequential request pc",
                64'h0000_0000_8000_e000, 1'b1,
                64'h0000_0000_8000_d000, 1'b0);

    tb_finish("tb_ooo_fetch_pc_outstanding_sequencer");
  end
endmodule
