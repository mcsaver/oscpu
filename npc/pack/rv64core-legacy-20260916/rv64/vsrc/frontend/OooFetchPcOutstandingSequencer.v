`include "define.v"

// 取指控制只保留 PC、当前路径归属和旧响应排空三个状态。
// AXI/MMU 请求本体由 OooFetchAxiBridge 持有；这里不复制其 PC 或取消外部事务。
module OooFetchPcOutstandingSequencer (
  input clk,
  input rst,
  input [`XLEN-1:0] reset_pc_i,

  input fetch_req_fire_i,
  input [`XLEN-1:0] fetch_req_pc_i,
  input [`XLEN-1:0] fetch_req_owner_pc_i,
  input fetch_rsp_fire_i,
  input fetch_rsp_enqueue_i,
  input [`XLEN-1:0] fetch_rsp_packet_next_pc_i,

  // redirect 已由前端按指令年龄仲裁。PC 只从这个入口改流。
  input redirect_valid_i,
  input [`XLEN-1:0] redirect_pc_i,
  input direct_frontend_flush_i,
  input branch_resolve_untracked_i,
  input csr_trap_mem_valid_i,
  input csr_commit_i,
  input drain_clear_i,

  output [`XLEN-1:0] next_fetch_pc_o,
  output outstanding_valid_o,
  output [`XLEN-1:0] outstanding_pc_o,
  output discard_fetch_rsp_o
);
  reg [`XLEN-1:0] next_fetch_pc_q;
  reg outstanding_valid_q;
  reg discard_fetch_rsp_q;

  wire path_flush_w = direct_frontend_flush_i || branch_resolve_untracked_i;
  wire discard_old_owner_w = csr_trap_mem_valid_i || path_flush_w || csr_commit_i;

  assign next_fetch_pc_o = next_fetch_pc_q;
  assign outstanding_valid_o = outstanding_valid_q;
  assign outstanding_pc_o = fetch_req_owner_pc_i;
  assign discard_fetch_rsp_o = discard_fetch_rsp_q;

  // 请求和响应同拍完成时，新请求接管槽位；普通响应推进预测 PC。
  // redirect 始终优先，不能被同拍旧路径 response 覆写。
  always @(posedge clk) begin
    if (rst)
      next_fetch_pc_q <= reset_pc_i;
    else if (redirect_valid_i)
      next_fetch_pc_q <= redirect_pc_i;
    else if (fetch_req_fire_i)
      next_fetch_pc_q <= fetch_req_pc_i;
    else if (fetch_rsp_enqueue_i)
      next_fetch_pc_q <= fetch_rsp_packet_next_pc_i;
  end

  // 优先级：异常 > 改流 > CSR/排空完成 > 请求接管 > 响应归还。
  // path_flush 同拍的已接受请求仍需登记，异常则关闭架构交付资格。
  always @(posedge clk) begin
    if (rst || csr_trap_mem_valid_i)
      outstanding_valid_q <= 1'b0;
    else if (path_flush_w)
      outstanding_valid_q <= fetch_req_fire_i;
    else if (csr_commit_i || drain_clear_i)
      outstanding_valid_q <= 1'b0;
    else if (fetch_req_fire_i)
      outstanding_valid_q <= 1'b1;
    else if (fetch_rsp_fire_i)
      outstanding_valid_q <= 1'b0;
  end

  // 丢弃标记仅表示尚未返回的旧路径 response。redirect 不清除桥内事务，
  // stale response 返回后归还 credit。drain_clear 不改变这个排空标记。
  always @(posedge clk) begin
    if (rst)
      discard_fetch_rsp_q <= 1'b0;
    else if (discard_old_owner_w)
      discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
    else if (fetch_rsp_fire_i)
      discard_fetch_rsp_q <= 1'b0;
  end

`ifdef OOO_ASSERT
  reg check_valid_q;
  reg redirect_seen_q;
  reg [`XLEN-1:0] redirect_pc_seen_q;
  reg trap_seen_q;
  reg drained_response_seen_q;
  always @(posedge clk) begin
    if (rst) begin
      check_valid_q <= 1'b0;
      redirect_seen_q <= 1'b0;
      redirect_pc_seen_q <= {`XLEN{1'b0}};
      trap_seen_q <= 1'b0;
      drained_response_seen_q <= 1'b0;
    end else begin
      check_valid_q <= 1'b1;
      redirect_seen_q <= redirect_valid_i;
      redirect_pc_seen_q <= redirect_pc_i;
      trap_seen_q <= csr_trap_mem_valid_i;
      drained_response_seen_q <= fetch_rsp_fire_i;
      if (check_valid_q) begin
        if (redirect_seen_q && next_fetch_pc_q != redirect_pc_seen_q)
          $error("[FETCH-REDIRECT] redirect target lost");
        if (trap_seen_q && outstanding_valid_q)
          $error("[FETCH-TRAP] trapped path remained deliverable");
        if (drained_response_seen_q && discard_fetch_rsp_q)
          $error("[FETCH-DRAIN] completed stale response retained");
      end
    end
  end
`endif
endmodule
