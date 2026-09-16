// Pure combinational ready-valid policy for the OoO front-end fetch path.
module OooFetchFlowControl #(
  parameter FETCH_COUNT_W = 3
) (
  input fetch_rsp_valid_i,
  input fetch_req_ready_i,
  input fetch_request_blocked_by_trap_i,
  input redirect_fetch_req_valid_i,
  input resolve_redirect_block_i,
  // 【redirect 防火墙】direct 族 redirect 拍封顺序臂(次拍发 arb 终写 target)
  input direct_redirect_block_i,
  // 【B2 S2】pred-taken 改流拍封顺序臂(T1 resolve_redirect_block 同型): 该拍融合
  // 连发的组合地址仍是 fall-through 旧顺序值(wrong-path), target 拍尾才写进
  // next_fetch_pc_q(Sequencer 顺序推进臂输入已换包 pred_next_pc), 次拍顺序臂发出。
  // 单 bit 关断, fetch_req_pc 组合锥零增长(禁止 taken 拍组合改流——刀 F WNS 家族)。
  input pred_taken_block_i,
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
  output fetch_rsp_enqueue_o
);

  // T3V: response-to-dispatch bypass was unreachable in the production
  // ROB-walk configuration.  Removing the port also removes the muxes that a
  // hierarchy-preserving synthesis could not fold through the constant owner.
  assign fifo_storage_pop_o = fifo_pop_i;
  // T3U：response credit 只读寄存 occupancy，禁止 full+pop 的组合
  // look-through。合法状态始终满足 fifo_count+outstanding<=depth；有
  // outstanding response 时 FIFO 不可能已满，因此 pop 旁路没有合法吞吐收益，
  // 却会把 FIFO head decode→backend ready→pop 接回 rsp/request/next-PC。
  assign fifo_can_accept_rsp_o = (fifo_count_i < fifo_depth_i);

  assign fetch_rsp_can_enqueue_o = can_run_i && outstanding_valid_i &&
                                   fifo_can_accept_rsp_o;
  assign fetch_rsp_can_drop_o = !outstanding_valid_i ||
                                stop_pending_busy_i || halted_i ||
                                trap_valid_i || exit_valid_i;
  assign direct_fetch_drop_o = direct_frontend_flush_i ||
                               discard_fetch_rsp_i;
  assign fetch_rsp_ready_o = fetch_rsp_can_enqueue_o ||
                             fetch_rsp_can_drop_o ||
                             direct_fetch_drop_o;
  assign fetch_rsp_fire_o = fetch_rsp_valid_i && fetch_rsp_ready_o;
  assign fetch_rsp_enqueue_o = fetch_rsp_valid_i && fetch_rsp_can_enqueue_o &&
                               !direct_fetch_drop_o;

  // 【F2 障碍①正解】direct flush 拍封死顺序取指臂: 该拍 next_fetch_pc_q 仍是旧值
  // (重取目标下拍才可见), 顺序请求会以 wrong-path 旧地址发出并被 flush 臂登记为
  // 合法 outstanding → wrong-path 包入 FIFO 提交。旧机器靠恒 mispredict 的二次
  // redirect 清洗掩盖; 免 redirect 后必须在源头封死(jal/ret 等经 redirect 臂不受影响)。
  // 【时序 T1】resolve redirect 拍同样封顺序臂(next_fetch_pc_q 旧值, 障碍①同族);
  // target 次拍经顺序臂发出。
  assign can_issue_request_o = can_run_i && !stop_head_i &&
                               !fetch_rsp_control_stop_i &&
                               !pred_taken_block_i &&
                               !discard_fetch_rsp_i &&
                               !direct_frontend_flush_i &&
                               !resolve_redirect_block_i &&
                               !direct_redirect_block_i &&
                               fifo_reserve_available_i &&
                               (!outstanding_valid_i || fetch_rsp_fire_o);
  assign fetch_req_valid_o =
      !fetch_request_blocked_by_trap_i &&
      (redirect_fetch_req_valid_i ||
       branch_prefetch_req_valid_i ||
       can_issue_request_o);
  assign fetch_req_fire_o = fetch_req_valid_o && fetch_req_ready_i;

endmodule
