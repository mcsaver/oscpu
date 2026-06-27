// Pure combinational ready-valid policy for the OoO front-end fetch path.
module OooFetchFlowControl #(
  parameter FETCH_COUNT_W = 3
) (
  input fetch_rsp_valid_i,
  input fetch_req_ready_i,
  input fetch_request_blocked_by_trap_i,
  input redirect_fetch_req_valid_i,
  input branch_prefetch_req_valid_i,
  input can_run_i,
  input stop_head_i,
  input fetch_rsp_control_stop_i,
  input discard_fetch_rsp_i,
  input fifo_reserve_available_i,
  input outstanding_valid_i,
  input [FETCH_COUNT_W-1:0] fifo_count_i,
  input [FETCH_COUNT_W-1:0] fifo_depth_i,
  input fifo_pop_i,
  input fetch_rsp_dispatch_bypass_i,
  input direct_frontend_flush_i,
  input stop_pending_busy_i,
  input halted_i,
  input trap_valid_i,
  input exit_valid_i,

  output can_issue_request_o,
  output fetch_req_valid_o,
  output fetch_req_fire_o,
  output fetch_rsp_ready_o,
  output fetch_rsp_fire_o,
  output fifo_storage_pop_o,
  output fifo_can_accept_rsp_o,
  output fetch_rsp_can_enqueue_o,
  output fetch_rsp_can_drop_o,
  output direct_fetch_drop_o,
  output fetch_rsp_bypass_consumed_o,
  output fetch_rsp_enqueue_o
);

  assign fetch_rsp_bypass_consumed_o =
      fetch_rsp_dispatch_bypass_i &&
      (fifo_pop_i || direct_frontend_flush_i);
  assign fifo_storage_pop_o = fifo_pop_i && !fetch_rsp_dispatch_bypass_i;
  assign fifo_can_accept_rsp_o =
      (fifo_count_i < fifo_depth_i) || fifo_storage_pop_o;

  assign fetch_rsp_can_enqueue_o = can_run_i && outstanding_valid_i &&
                                   fifo_can_accept_rsp_o;
  assign fetch_rsp_can_drop_o = !outstanding_valid_i ||
                                stop_pending_busy_i || halted_i ||
                                trap_valid_i || exit_valid_i;
  assign direct_fetch_drop_o = direct_frontend_flush_i ||
                               discard_fetch_rsp_i;
  assign fetch_rsp_ready_o = fetch_rsp_can_enqueue_o ||
                             fetch_rsp_dispatch_bypass_i ||
                             fetch_rsp_can_drop_o ||
                             direct_fetch_drop_o;
  assign fetch_rsp_fire_o = fetch_rsp_valid_i && fetch_rsp_ready_o;
  assign fetch_rsp_enqueue_o = fetch_rsp_valid_i && fetch_rsp_can_enqueue_o &&
                               !direct_fetch_drop_o &&
                               !fetch_rsp_bypass_consumed_o;

  assign can_issue_request_o = can_run_i && !stop_head_i &&
                               !fetch_rsp_control_stop_i &&
                               !discard_fetch_rsp_i &&
                               fifo_reserve_available_i &&
                               (!outstanding_valid_i || fetch_rsp_fire_o);
  assign fetch_req_valid_o =
      !fetch_request_blocked_by_trap_i &&
      (redirect_fetch_req_valid_i ||
       branch_prefetch_req_valid_i ||
       can_issue_request_o);
  assign fetch_req_fire_o = fetch_req_valid_o && fetch_req_ready_i;

endmodule
