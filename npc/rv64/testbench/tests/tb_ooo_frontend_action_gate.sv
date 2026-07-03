`include "tb_common.svh"

module tb_ooo_frontend_action_gate;
  reg direct_jal_fire;
  reg direct_branch0_fire;
  reg direct_branch1_fire;
  reg direct_ret0_fire;
  reg direct_ret1_fire;
  reg can_run;
  reg fifo_has_packet;
  reg branch_spec_dispatch_block;
  reg head_fetch_fault0;
  reg dispatch0_exit;
  reg dispatch0_arch_trap;
  reg dispatch0_system;
  reg dispatch0_branch;
  reg dispatch0_jal;
  reg dispatch0_jump;
  reg dispatch1_barrier;
  reg dispatch1_direct_jal;
  reg direct_branch1_dispatch_valid;
  reg dispatch_unsupported;
  reg dispatch_fire;
  reg dbranch_dispatch_fire;  // domain-A: 分支普通 dispatch fire(pop 源)
  reg dispatch1_barrier_fire;
  reg direct_jal0_fire;
  reg fetch_rsp_fire;
  reg fetch_rsp_can_enqueue;
  reg fetch_dec0_control_stop;
  reg fetch_dec1_control_stop;
  reg csr_trap_mem_valid;
  reg csr_trap_ex_valid;
  reg csr_trap_irq_valid;
  reg core_trap_flush;
  reg core_serial_flush;

  wire direct_frontend_flush;
  wire stop_head;
  wire fifo_pop;
  wire fetch_rsp_control_stop;
  wire fetch_request_blocked_by_trap;

  OooFrontendActionGate dut (
    .direct_jal_fire_i(direct_jal_fire),
    .direct_branch0_fire_i(direct_branch0_fire),
    .direct_branch1_fire_i(direct_branch1_fire),
    .direct_ret0_fire_i(direct_ret0_fire),
    .direct_ret1_fire_i(direct_ret1_fire),
    .can_run_i(can_run),
    .fifo_has_packet_i(fifo_has_packet),
    .branch_spec_dispatch_block_i(branch_spec_dispatch_block),
    .head_fetch_fault0_i(head_fetch_fault0),
    .dispatch0_exit_i(dispatch0_exit),
    .dispatch0_arch_trap_i(dispatch0_arch_trap),
    .dispatch0_system_i(dispatch0_system),
    .dispatch0_branch_i(dispatch0_branch),
    .dispatch0_jal_i(dispatch0_jal),
    .dispatch0_jump_i(dispatch0_jump),
    .dispatch1_barrier_i(dispatch1_barrier),
    .dispatch1_direct_jal_i(dispatch1_direct_jal),
    .direct_branch1_dispatch_valid_i(direct_branch1_dispatch_valid),
    .dispatch_unsupported_i(dispatch_unsupported),
    .dispatch_fire_i(dispatch_fire),
    .dbranch_dispatch_fire_i(dbranch_dispatch_fire),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .direct_jal0_fire_i(direct_jal0_fire),
    .direct_jump_spec_fire_i(1'b0),
    .fetch_rsp_fire_i(fetch_rsp_fire),
    .fetch_rsp_can_enqueue_i(fetch_rsp_can_enqueue),
    .fetch_dec0_control_stop_i(fetch_dec0_control_stop),
    .fetch_dec1_control_stop_i(fetch_dec1_control_stop),
    .csr_trap_mem_valid_i(csr_trap_mem_valid),
    .csr_trap_ex_valid_i(csr_trap_ex_valid),
    .csr_trap_irq_valid_i(csr_trap_irq_valid),
    .core_trap_flush_i(core_trap_flush),
    .core_serial_flush_i(core_serial_flush),
    .direct_frontend_flush_o(direct_frontend_flush),
    .stop_head_o(stop_head),
    .fifo_pop_o(fifo_pop),
    .fetch_rsp_control_stop_o(fetch_rsp_control_stop),
    .fetch_request_blocked_by_trap_o(fetch_request_blocked_by_trap)
  );

  task automatic reset_inputs;
    begin
      direct_jal_fire = 1'b0;
      direct_branch0_fire = 1'b0;
      direct_branch1_fire = 1'b0;
      direct_ret0_fire = 1'b0;
      direct_ret1_fire = 1'b0;
      can_run = 1'b1;
      fifo_has_packet = 1'b1;
      branch_spec_dispatch_block = 1'b0;
      head_fetch_fault0 = 1'b0;
      dispatch0_exit = 1'b0;
      dispatch0_arch_trap = 1'b0;
      dispatch0_system = 1'b0;
      dispatch0_branch = 1'b0;
      dispatch0_jal = 1'b0;
      dispatch0_jump = 1'b0;
      dispatch1_barrier = 1'b0;
      dispatch1_direct_jal = 1'b0;
      direct_branch1_dispatch_valid = 1'b0;
      dispatch_unsupported = 1'b0;
      dispatch_fire = 1'b0;
      dbranch_dispatch_fire = 1'b0;
      dispatch1_barrier_fire = 1'b0;
      direct_jal0_fire = 1'b0;
      fetch_rsp_fire = 1'b0;
      fetch_rsp_can_enqueue = 1'b0;
      fetch_dec0_control_stop = 1'b0;
      fetch_dec1_control_stop = 1'b0;
      csr_trap_mem_valid = 1'b0;
      csr_trap_ex_valid = 1'b0;
      csr_trap_irq_valid = 1'b0;
      core_trap_flush = 1'b0;
      core_serial_flush = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    tb_check1("idle no direct flush", direct_frontend_flush, 1'b0);
    tb_check1("idle no stop head", stop_head, 1'b0);
    tb_check1("idle no fifo pop", fifo_pop, 1'b0);
    tb_check1("idle no control stop", fetch_rsp_control_stop, 1'b0);
    tb_check1("idle request unblocked", fetch_request_blocked_by_trap, 1'b0);

    reset_inputs();
    direct_branch1_fire = 1'b1;
    #1;
    tb_check1("direct branch flushes frontend", direct_frontend_flush, 1'b1);
    tb_check1("direct branch does not imply fifo pop", fifo_pop, 1'b0);

    reset_inputs();
    direct_ret0_fire = 1'b1;
    #1;
    tb_check1("direct return flushes frontend", direct_frontend_flush, 1'b1);

    reset_inputs();
    dispatch0_branch = 1'b1;
    #1;
    // domain-A(OOO_DBRANCH_DOMAIN_A=1): 分支走普通 dispatch, 不停取指头。
    tb_check1("slot0 branch no longer stops head (domain-A)", stop_head, 1'b0);
    // domain-A: 分支普通 dispatch fire 驱动 FIFO pop。
    dbranch_dispatch_fire = 1'b1;
    #1;
    tb_check1("dbranch dispatch fire pops fifo (domain-A)", fifo_pop, 1'b1);
    dbranch_dispatch_fire = 1'b0;
    #1;

    reset_inputs();
    dispatch1_barrier = 1'b1;
    #1;
    tb_check1("lane1 barrier stops head", stop_head, 1'b1);

    reset_inputs();
    dispatch_unsupported = 1'b1;
    #1;
    tb_check1("unsupported stops head", stop_head, 1'b1);

    reset_inputs();
    dispatch0_jump = 1'b1;
    branch_spec_dispatch_block = 1'b1;
    #1;
    tb_check1("branch spec blocks stop head", stop_head, 1'b0);

    reset_inputs();
    dispatch0_jump = 1'b1;
    can_run = 1'b0;
    #1;
    tb_check1("can_run gates stop head", stop_head, 1'b0);

    reset_inputs();
    dispatch0_jump = 1'b1;
    fifo_has_packet = 1'b0;
    #1;
    tb_check1("head packet gates stop head", stop_head, 1'b0);

    reset_inputs();
    dispatch_fire = 1'b1;
    #1;
    tb_check1("normal dispatch pops fifo", fifo_pop, 1'b1);

    reset_inputs();
    dispatch1_barrier_fire = 1'b1;
    #1;
    tb_check1("barrier dispatch pops fifo", fifo_pop, 1'b1);

    reset_inputs();
    direct_jal0_fire = 1'b1;
    #1;
    tb_check1("lane0 direct jal pops fifo", fifo_pop, 1'b1);
    tb_check1("lane0 direct jal flushes frontend", direct_frontend_flush, 1'b0);

    reset_inputs();
    direct_jal_fire = 1'b1;
    direct_jal0_fire = 1'b1;
    #1;
    tb_check1("direct jal fire flushes frontend", direct_frontend_flush, 1'b1);
    tb_check1("direct jal0 fire also pops fifo", fifo_pop, 1'b1);

    reset_inputs();
    fetch_rsp_fire = 1'b1;
    fetch_rsp_can_enqueue = 1'b1;
    fetch_dec1_control_stop = 1'b1;
    #1;
    tb_check1("enqueued control response stops issue",
              fetch_rsp_control_stop, 1'b1);

    reset_inputs();
    fetch_rsp_fire = 1'b1;
    fetch_dec0_control_stop = 1'b1;
    #1;
    tb_check1("non-enqueue response does not control-stop",
              fetch_rsp_control_stop, 1'b0);

    reset_inputs();
    csr_trap_irq_valid = 1'b1;
    #1;
    tb_check1("csr irq blocks request", fetch_request_blocked_by_trap, 1'b1);

    reset_inputs();
    core_serial_flush = 1'b1;
    #1;
    tb_check1("serial flush blocks request", fetch_request_blocked_by_trap,
              1'b1);

    tb_finish("tb_ooo_frontend_action_gate");
  end

endmodule
