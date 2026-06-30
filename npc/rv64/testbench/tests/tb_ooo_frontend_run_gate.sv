`include "define.v"
`include "tb_common.svh"

module tb_ooo_frontend_run_gate;
  localparam FETCH_COUNT_W = 3;

  reg run;
  reg core_trap_flush;
  reg core_serial_flush;
  reg stop_pending;
  reg pending_exit;
  reg pending_branch;
  reg pending_jump;
  reg pending_mem;
  reg pending_fp;
  reg pending_arch_trap;
  reg pending_system;
  reg synth_lane1_ret_pending;
  reg synth_lane1_branch_drop_pending;
  reg branch_spec_checkpoint_pending;
  reg branch_spec_active;
  reg halted;
  reg trap_valid;
  reg exit_valid;
  reg fifo_storage_head_valid;
  reg outstanding_valid;
  reg fetch_rsp_valid;
  reg discard_fetch_rsp;
  reg [FETCH_COUNT_W-1:0] fifo_count;
  reg [FETCH_COUNT_W-1:0] fifo_depth;

  wire orphan_stop_pending;
  wire stop_pending_busy;
  wire can_run;
  wire fifo_empty_storage;
  wire fetch_rsp_dispatch_bypass;
  wire [FETCH_COUNT_W-1:0] outstanding_count;
  wire fifo_reserve_available;

  OooFrontendRunGate #(
    .FETCH_COUNT_W(FETCH_COUNT_W)
  ) dut (
    .run_i(run),
    .core_trap_flush_i(core_trap_flush),
    .core_serial_flush_i(core_serial_flush),
    .stop_pending_i(stop_pending),
    .pending_exit_i(pending_exit),
    .pending_branch_i(pending_branch),
    .pending_jump_i(pending_jump),
    .pending_mem_i(pending_mem),
    .pending_fp_i(pending_fp),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_system_i(pending_system),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending),
    .synth_lane1_branch_drop_pending_i(synth_lane1_branch_drop_pending),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .branch_spec_active_i(branch_spec_active),
    .halted_i(halted),
    .trap_valid_i(trap_valid),
    .exit_valid_i(exit_valid),
    .fifo_storage_head_valid_i(fifo_storage_head_valid),
    .outstanding_valid_i(outstanding_valid),
    .fetch_rsp_valid_i(fetch_rsp_valid),
    .discard_fetch_rsp_i(discard_fetch_rsp),
    .fifo_count_i(fifo_count),
    .fifo_depth_i(fifo_depth),
    .orphan_stop_pending_o(orphan_stop_pending),
    .stop_pending_busy_o(stop_pending_busy),
    .can_run_o(can_run),
    .fifo_empty_storage_o(fifo_empty_storage),
    .fetch_rsp_dispatch_bypass_o(fetch_rsp_dispatch_bypass),
    .outstanding_count_o(outstanding_count),
    .fifo_reserve_available_o(fifo_reserve_available)
  );

  task automatic reset_inputs;
    begin
      run = 1'b1;
      core_trap_flush = 1'b0;
      core_serial_flush = 1'b0;
      stop_pending = 1'b0;
      pending_exit = 1'b0;
      pending_branch = 1'b0;
      pending_jump = 1'b0;
      pending_mem = 1'b0;
      pending_fp = 1'b0;
      pending_arch_trap = 1'b0;
      pending_system = 1'b0;
      synth_lane1_ret_pending = 1'b0;
      synth_lane1_branch_drop_pending = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      branch_spec_active = 1'b0;
      halted = 1'b0;
      trap_valid = 1'b0;
      exit_valid = 1'b0;
      fifo_storage_head_valid = 1'b0;
      outstanding_valid = 1'b0;
      fetch_rsp_valid = 1'b0;
      discard_fetch_rsp = 1'b0;
      fifo_count = 3'd0;
      fifo_depth = 3'd4;
      #1;
    end
  endtask

  task automatic check_blocker;
    input [1023:0] tag;
    begin
      #1;
      tb_check1({tag, " blocks can_run"}, can_run, 1'b0);
      tb_check1({tag, " suppresses bypass"}, fetch_rsp_dispatch_bypass, 1'b0);
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    tb_check1("idle can run", can_run, 1'b1);
    tb_check1("fifo storage empty", fifo_empty_storage, 1'b1);
    tb_check32("no outstanding count", {29'b0, outstanding_count}, 32'd0);
    tb_check1("empty fifo reserve available", fifo_reserve_available, 1'b1);

    reset_inputs();
    stop_pending = 1'b1;
    #1;
    tb_check1("orphan stop detected", orphan_stop_pending, 1'b1);
    tb_check1("orphan stop not busy", stop_pending_busy, 1'b0);
    tb_check1("orphan stop does not block can_run", can_run, 1'b1);

    reset_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    #1;
    tb_check1("owned stop is not orphan", orphan_stop_pending, 1'b0);
    tb_check1("owned stop is busy", stop_pending_busy, 1'b1);
    tb_check1("owned stop blocks can_run", can_run, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    branch_spec_active = 1'b1;
    #1;
    tb_check1("branch spec owns stop", stop_pending_busy, 1'b1);
    tb_check1("branch spec stop blocks can_run", can_run, 1'b0);

    reset_inputs();
    core_trap_flush = 1'b1;
    check_blocker("trap flush");

    reset_inputs();
    core_serial_flush = 1'b1;
    check_blocker("serial flush");

    reset_inputs();
    halted = 1'b1;
    check_blocker("halted");

    reset_inputs();
    trap_valid = 1'b1;
    check_blocker("trap valid");

    reset_inputs();
    exit_valid = 1'b1;
    check_blocker("exit valid");

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_valid = 1'b1;
    #1;
    // mode=1（OOO_ROB_WALK_MODE）禁用 fetch-rsp dispatch-bypass（强制经 FIFO，打破投机组合环），
    // 故 mode=1 期望 bypass=0；mode=0 保留 fifo-empty 快路径 bypass=1。
    tb_check1("response bypass when fifo empty", fetch_rsp_dispatch_bypass,
              !`OOO_ROB_WALK_MODE);
    tb_check32("one outstanding count", {29'b0, outstanding_count}, 32'd1);

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_valid = 1'b1;
    fifo_storage_head_valid = 1'b1;
    #1;
    tb_check1("fifo head suppresses bypass", fifo_empty_storage, 1'b0);
    tb_check1("nonempty fifo suppresses bypass", fetch_rsp_dispatch_bypass,
              1'b0);

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_valid = 1'b1;
    discard_fetch_rsp = 1'b1;
    #1;
    tb_check1("discard suppresses bypass", fetch_rsp_dispatch_bypass, 1'b0);

    reset_inputs();
    fifo_count = 3'd3;
    outstanding_valid = 1'b0;
    #1;
    tb_check1("last fifo slot available without outstanding",
              fifo_reserve_available, 1'b1);

    reset_inputs();
    fifo_count = 3'd3;
    outstanding_valid = 1'b1;
    #1;
    tb_check1("outstanding consumes last fifo slot", fifo_reserve_available,
              1'b0);

    reset_inputs();
    fifo_count = 3'd4;
    #1;
    tb_check1("full fifo has no reserve", fifo_reserve_available, 1'b0);

    tb_finish("tb_ooo_frontend_run_gate");
  end

endmodule
