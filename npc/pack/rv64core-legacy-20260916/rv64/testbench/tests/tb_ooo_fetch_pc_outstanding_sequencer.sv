`include "tb_common.svh"
`include "define.v"

// 当前生产事件接口：覆盖请求/响应 turnover、重定向冲突、异常和旧响应排空。
module tb_ooo_fetch_pc_outstanding_sequencer;
  reg clk = 0;
  reg rst = 1;
  always #5 clk = !clk;
  reg [`XLEN-1:0] reset_pc = 64'h8000_0000;
  reg req_fire, rsp_fire, enqueue;
  reg [63:0] req_pc, owner_pc, predicted_pc;
  reg redirect, direct_flush, branch_miss, trap, csr_commit, drain_clear;
  reg [63:0] redirect_pc;
  wire [63:0] next_pc, outstanding_pc;
  wire outstanding, discard_rsp;
  integer cycles;
  integer pattern;
  reg [63:0] model_pc;
  reg model_owner, model_discard;
  reg previous_owner;

  OooFetchPcOutstandingSequencer dut (
    .clk(clk), .rst(rst), .reset_pc_i(reset_pc),
    .fetch_req_fire_i(req_fire), .fetch_req_pc_i(req_pc),
    .fetch_req_owner_pc_i(owner_pc),
    .fetch_rsp_fire_i(rsp_fire), .fetch_rsp_enqueue_i(enqueue),
    .fetch_rsp_packet_next_pc_i(predicted_pc),
    .redirect_valid_i(redirect), .redirect_pc_i(redirect_pc),
    .direct_frontend_flush_i(direct_flush),
    .branch_resolve_untracked_i(branch_miss),
    .csr_trap_mem_valid_i(trap), .csr_commit_i(csr_commit),
    .drain_clear_i(drain_clear),
    .next_fetch_pc_o(next_pc), .outstanding_valid_o(outstanding),
    .outstanding_pc_o(outstanding_pc), .discard_fetch_rsp_o(discard_rsp)
  );

  task clear_events;
    begin
      req_fire=0; rsp_fire=0; enqueue=0;
      redirect=0; direct_flush=0; branch_miss=0;
      trap=0; csr_commit=0; drain_clear=0;
      req_pc=64'h8000_0010; predicted_pc=64'h8000_0020;
      redirect_pc=64'h8000_1000;
    end
  endtask

  // reference 按先完成、再接受、最后应用控制事件的顺序更新。
  // 它保留旧生产路径的优先级；额外对输出归属做独立检查。
  task step;
    begin
      previous_owner=model_owner;
      if (rst) begin
        model_pc=reset_pc; model_owner=0; model_discard=0;
      end else begin
        if (enqueue && !req_fire) model_pc=predicted_pc;
        if (req_fire) model_pc=req_pc;
        if (redirect) model_pc=redirect_pc;
        if (rsp_fire) begin model_owner=0; model_discard=0; end
        if (req_fire) model_owner=1;
        if (direct_flush) begin
          model_owner=req_fire;
          model_discard=previous_owner && !rsp_fire;
        end
        if (branch_miss) begin
          model_owner=req_fire;
          model_discard=previous_owner && !rsp_fire;
        end else if (!direct_flush && csr_commit) begin
          model_owner=0;
          model_discard=previous_owner && !rsp_fire;
        end else if (!direct_flush && drain_clear) model_owner=0;
        if (trap) begin
          model_owner=0;
          model_discard=previous_owner && !rsp_fire;
        end
      end
      @(posedge clk); #1;
      if ({next_pc,outstanding,discard_rsp} !== {model_pc,model_owner,model_discard})
        $fatal(1,"fetch state mismatch cycle=%0d pc=%h/%h owner=%b/%b discard=%b/%b",
            cycles,next_pc,model_pc,outstanding,model_owner,discard_rsp,model_discard);
      if (outstanding_pc !== owner_pc)
        $fatal(1,"fetch response PC must come from the accepted bridge owner");
      cycles=cycles+1;
      @(negedge clk);
    end
  endtask

  initial begin
    cycles=0; model_pc=0; model_owner=0; model_discard=0;
    owner_pc=64'h8000_0000;
    clear_events(); step(); rst=0;
    // 请求先占位。更改候选地址不能覆盖已接受请求的 PC。
    req_fire=1; step(); clear_events();
    req_pc=64'hffff_0000; step();
    if (!outstanding || outstanding_pc != 64'h8000_0000)
      $fatal(1,"accepted request ownership lost under stall");
    // 旧响应完成与新请求接受可以同拍进行。
    req_fire=1; rsp_fire=1; enqueue=1; owner_pc=64'h8000_0010; step();
    if (!outstanding) $fatal(1,"turnover inserted a request bubble");
    clear_events(); redirect=1; direct_flush=1; step();
    if (outstanding || !discard_rsp) $fatal(1,"redirect failed to retain old drain");
    // drain clear 不得提前释放旧 response；真正 response fire 才释放。
    clear_events(); drain_clear=1; step();
    if (!discard_rsp) $fatal(1,"logical drain cleared an external transaction");
    clear_events(); rsp_fire=1; step();
    if (discard_rsp) $fatal(1,"stale response did not release credit");
    // 异常与 younger redirect/request 同拍：关闭交付且 PC 使用最终仲裁结果。
    clear_events(); req_fire=1; step();
    trap=1; redirect=1; direct_flush=1; branch_miss=1; csr_commit=1; step();
    if (outstanding || next_pc != redirect_pc)
      $fatal(1,"trap/redirect collision violated architectural priority");
    clear_events(); rsp_fire=1; step();

    // 遍历所有 9 个边界事件组合，第二轮逆序，覆盖不同旧状态下的同拍优先级。
    for (pattern=0; pattern<1024; pattern=pattern+1) begin
      {req_fire,rsp_fire,enqueue,redirect,direct_flush,branch_miss,trap,csr_commit,drain_clear}
          = pattern < 512 ? pattern[8:0] : ~pattern[8:0];
      req_pc=64'h8000_0000+64'(pattern*8);
      predicted_pc=req_pc+64'd8;
      redirect_pc=64'h9000_0000+64'(pattern*16);
      step();
    end
    clear_events(); rst=1; step();
    $display("[COVERAGE] fetch event cycles=%0d",cycles);
    $display("[PASS] tb_ooo_fetch_pc_outstanding_sequencer");
    $finish;
  end
endmodule
