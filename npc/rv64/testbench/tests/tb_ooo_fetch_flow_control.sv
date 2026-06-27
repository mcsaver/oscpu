`include "tb_common.svh"

module tb_ooo_fetch_flow_control;
  localparam FETCH_COUNT_W = 3;

  reg fetch_rsp_valid;
  reg fetch_req_ready;
  reg fetch_request_blocked_by_trap;
  reg redirect_fetch_req_valid;
  reg branch_prefetch_req_valid;
  reg can_run;
  reg stop_head;
  reg fetch_rsp_control_stop;
  reg discard_fetch_rsp;
  reg fifo_reserve_available;
  reg outstanding_valid;
  reg [FETCH_COUNT_W-1:0] fifo_count;
  reg [FETCH_COUNT_W-1:0] fifo_depth;
  reg fifo_pop;
  reg fetch_rsp_dispatch_bypass;
  reg direct_frontend_flush;
  reg stop_pending_busy;
  reg halted;
  reg trap_valid;
  reg exit_valid;

  wire can_issue_request;
  wire fetch_req_valid;
  wire fetch_req_fire;
  wire fetch_rsp_ready;
  wire fetch_rsp_fire;
  wire fifo_storage_pop;
  wire fifo_can_accept_rsp;
  wire fetch_rsp_can_enqueue;
  wire fetch_rsp_can_drop;
  wire direct_fetch_drop;
  wire fetch_rsp_bypass_consumed;
  wire fetch_rsp_enqueue;

  OooFetchFlowControl #(
    .FETCH_COUNT_W(FETCH_COUNT_W)
  ) dut (
    .fetch_rsp_valid_i(fetch_rsp_valid),
    .fetch_req_ready_i(fetch_req_ready),
    .fetch_request_blocked_by_trap_i(fetch_request_blocked_by_trap),
    .redirect_fetch_req_valid_i(redirect_fetch_req_valid),
    .branch_prefetch_req_valid_i(branch_prefetch_req_valid),
    .can_run_i(can_run),
    .stop_head_i(stop_head),
    .fetch_rsp_control_stop_i(fetch_rsp_control_stop),
    .discard_fetch_rsp_i(discard_fetch_rsp),
    .fifo_reserve_available_i(fifo_reserve_available),
    .outstanding_valid_i(outstanding_valid),
    .fifo_count_i(fifo_count),
    .fifo_depth_i(fifo_depth),
    .fifo_pop_i(fifo_pop),
    .fetch_rsp_dispatch_bypass_i(fetch_rsp_dispatch_bypass),
    .direct_frontend_flush_i(direct_frontend_flush),
    .stop_pending_busy_i(stop_pending_busy),
    .halted_i(halted),
    .trap_valid_i(trap_valid),
    .exit_valid_i(exit_valid),
    .can_issue_request_o(can_issue_request),
    .fetch_req_valid_o(fetch_req_valid),
    .fetch_req_fire_o(fetch_req_fire),
    .fetch_rsp_ready_o(fetch_rsp_ready),
    .fetch_rsp_fire_o(fetch_rsp_fire),
    .fifo_storage_pop_o(fifo_storage_pop),
    .fifo_can_accept_rsp_o(fifo_can_accept_rsp),
    .fetch_rsp_can_enqueue_o(fetch_rsp_can_enqueue),
    .fetch_rsp_can_drop_o(fetch_rsp_can_drop),
    .direct_fetch_drop_o(direct_fetch_drop),
    .fetch_rsp_bypass_consumed_o(fetch_rsp_bypass_consumed),
    .fetch_rsp_enqueue_o(fetch_rsp_enqueue)
  );

  task automatic reset_inputs;
    begin
      fetch_rsp_valid = 1'b0;
      fetch_req_ready = 1'b1;
      fetch_request_blocked_by_trap = 1'b0;
      redirect_fetch_req_valid = 1'b0;
      branch_prefetch_req_valid = 1'b0;
      can_run = 1'b1;
      stop_head = 1'b0;
      fetch_rsp_control_stop = 1'b0;
      discard_fetch_rsp = 1'b0;
      fifo_reserve_available = 1'b1;
      outstanding_valid = 1'b0;
      fifo_count = 3'd0;
      fifo_depth = 3'd4;
      fifo_pop = 1'b0;
      fetch_rsp_dispatch_bypass = 1'b0;
      direct_frontend_flush = 1'b0;
      stop_pending_busy = 1'b0;
      halted = 1'b0;
      trap_valid = 1'b0;
      exit_valid = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_inputs();
    tb_check1("normal request valid", fetch_req_valid, 1'b1);
    tb_check1("normal request fire", fetch_req_fire, 1'b1);
    tb_check1("no response fire", fetch_rsp_fire, 1'b0);

    reset_inputs();
    outstanding_valid = 1'b1;
    #1;
    tb_check1("outstanding blocks normal issue", can_issue_request, 1'b0);
    tb_check1("outstanding blocks request valid", fetch_req_valid, 1'b0);

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_valid = 1'b1;
    #1;
    tb_check1("response ready when can enqueue", fetch_rsp_ready, 1'b1);
    tb_check1("response fire releases request issue", can_issue_request, 1'b1);
    tb_check1("same-cycle response allows request valid", fetch_req_valid, 1'b1);
    tb_check1("response enqueues", fetch_rsp_enqueue, 1'b1);

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_valid = 1'b1;
    fifo_count = 3'd4;
    fifo_pop = 1'b1;
    #1;
    tb_check1("full fifo accepts with pop", fifo_can_accept_rsp, 1'b1);
    tb_check1("full fifo enqueue with pop", fetch_rsp_enqueue, 1'b1);
    tb_check1("storage pop when no bypass", fifo_storage_pop, 1'b1);

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_valid = 1'b1;
    fetch_rsp_dispatch_bypass = 1'b1;
    fifo_pop = 1'b1;
    #1;
    tb_check1("bypass consumed", fetch_rsp_bypass_consumed, 1'b1);
    tb_check1("bypass does not storage-pop", fifo_storage_pop, 1'b0);
    tb_check1("bypass consumed does not enqueue", fetch_rsp_enqueue, 1'b0);

    reset_inputs();
    outstanding_valid = 1'b1;
    fetch_rsp_valid = 1'b1;
    discard_fetch_rsp = 1'b1;
    #1;
    tb_check1("discard is direct drop", direct_fetch_drop, 1'b1);
    tb_check1("direct drop ready", fetch_rsp_ready, 1'b1);
    tb_check1("direct drop suppresses enqueue", fetch_rsp_enqueue, 1'b0);

    reset_inputs();
    fetch_request_blocked_by_trap = 1'b1;
    redirect_fetch_req_valid = 1'b1;
    #1;
    tb_check1("trap blocks request valid", fetch_req_valid, 1'b0);

    reset_inputs();
    outstanding_valid = 1'b0;
    fetch_rsp_valid = 1'b1;
    #1;
    tb_check1("no outstanding response can drop", fetch_rsp_can_drop, 1'b1);
    tb_check1("drop-only response ready", fetch_rsp_ready, 1'b1);
    tb_check1("drop-only response fires", fetch_rsp_fire, 1'b1);

    reset_inputs();
    branch_prefetch_req_valid = 1'b1;
    can_run = 1'b0;
    #1;
    tb_check1("branch prefetch request source valid", fetch_req_valid, 1'b1);
    tb_check1("branch prefetch request fire", fetch_req_fire, 1'b1);

    tb_finish("tb_ooo_fetch_flow_control");
  end

endmodule
