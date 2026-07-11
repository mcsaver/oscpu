`include "define.v"

module OooMemoryRequestGate (
  input clk,
  input rst,
  input core_local_flush_i,
  input checkpoint_mem_flush_i,
  input pending_system_satp_write_commit_i,
  input pending_system_sfence_commit_i,
  input pending_system_fencei_commit_i,

  input stop_pending_i,
  input backend_drained_i,

  input core_mem_req_valid_i,
  input core_mem_req_write_i,
  input core_mem_req_probe_i,
  input core_mem_req_pretrans_i,
  input core_mem_req_nokill_i,
  input [`XLEN-1:0] core_mem_req_addr_i,
  input [`XLEN-1:0] core_mem_req_wdata_i,
  input [`STRB_W-1:0] core_mem_req_wstrb_i,
  input core_mem_rsp_ready_i,

  input mem_req_ready_i,
  input mem_rsp_valid_i,


  output mem_req_valid_o,
  output mem_req_write_o,
  output mem_req_probe_o,
  output mem_req_pretrans_o,
  output mem_req_nokill_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  output mem_rsp_ready_o,

  output mem_flush_o,
  output mmu_flush_o
);

  // 【B-FP 簇】pending-FP 直写旁路已拆(FP 访存走整数 LSU/SQ)。
  assign mem_req_valid_o =
      core_mem_req_valid_i;
  assign mem_req_write_o =
      core_mem_req_write_i;
  assign mem_req_probe_o =
      core_mem_req_probe_i;
  assign mem_req_pretrans_o =
      core_mem_req_pretrans_i;
  assign mem_req_nokill_o =
      core_mem_req_nokill_i;
  assign mem_req_addr_o =
      core_mem_req_addr_i;
  assign mem_req_wdata_o =
      core_mem_req_wdata_i;
  assign mem_req_wstrb_o =
      core_mem_req_wstrb_i;
  assign mem_rsp_ready_o =
      core_mem_rsp_ready_i;

  assign mem_flush_o = core_local_flush_i || checkpoint_mem_flush_i;
  // 【拓扑防火墙 v2(2026-07-11)】mmu_flush 出口打拍: 组合生成链(rsp→wb→ROB
  // commit→retire_count→drain_complete→本式)当拍打进 fetch/mem 桥与 cache/TLB
  // 清除口, 是 dcache-rdata→…→fetch dec→pred 传递闭包的真缝合点。satp/sfence/
  // fence.i 都是 stop+drain 整机静止事件, flush 晚一拍到达零语义影响(重启取指
  // 本就在 serialize 开销里)。全体消费者同拍延迟, 一致性保持。
  reg mmu_flush_q;
  always @(posedge clk) begin
    mmu_flush_q <= !rst &&
        (pending_system_satp_write_commit_i || pending_system_sfence_commit_i ||
         pending_system_fencei_commit_i);
  end
  assign mmu_flush_o = mmu_flush_q;

endmodule
