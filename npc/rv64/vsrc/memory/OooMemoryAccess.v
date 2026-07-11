`include "define.v"

// OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。
// 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥
// → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅
// 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 clk/rst/flush）。
module OooMemoryAccess (
  input clk,
  input rst,
  input backend_drained_q,
  input checkpoint_mem_flush_q,
  input core_local_flush_w,
  input [`XLEN-1:0] core_mem_req_addr_w,
  input core_mem_req_valid_w,
  input [`XLEN-1:0] core_mem_req_wdata_w,
  input core_mem_req_write_w,
  input core_mem_req_probe_w,
  input core_mem_req_pretrans_w,
  input core_mem_req_nokill_w,
  input [`STRB_W-1:0] core_mem_req_wstrb_w,
  input core_mem_rsp_ready_w,
  input mem_req_ready_i,
  input mem_rsp_valid_i,
  input pending_system_satp_write_commit_w,
  input pending_system_sfence_commit_w,
  input pending_system_fencei_commit_w,
  input stop_pending_q,
  output mem_flush_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output mem_req_valid_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output mem_req_write_o,
  output mem_req_probe_o,
  output mem_req_pretrans_o,
  output mem_req_nokill_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  output mem_rsp_ready_o,
  output mmu_flush_o
);


  OooMemoryRequestGate u_memory_request_gate (
    .clk(clk),
    .rst(rst),
    .core_local_flush_i(core_local_flush_w),
    .checkpoint_mem_flush_i(checkpoint_mem_flush_q),
    .pending_system_satp_write_commit_i(pending_system_satp_write_commit_w),
    .pending_system_sfence_commit_i(pending_system_sfence_commit_w),
    .pending_system_fencei_commit_i(pending_system_fencei_commit_w),
    .stop_pending_i(stop_pending_q),
    .backend_drained_i(backend_drained_q),
    .core_mem_req_valid_i(core_mem_req_valid_w),
    .core_mem_req_write_i(core_mem_req_write_w),
    .core_mem_req_probe_i(core_mem_req_probe_w),
    .core_mem_req_pretrans_i(core_mem_req_pretrans_w),
    .core_mem_req_nokill_i(core_mem_req_nokill_w),
    .core_mem_req_addr_i(core_mem_req_addr_w),
    .core_mem_req_wdata_i(core_mem_req_wdata_w),
    .core_mem_req_wstrb_i(core_mem_req_wstrb_w),
    .core_mem_rsp_ready_i(core_mem_rsp_ready_w),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_write_o(mem_req_write_o),
    .mem_req_probe_o(mem_req_probe_o),
    .mem_req_pretrans_o(mem_req_pretrans_o),
    .mem_req_nokill_o(mem_req_nokill_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_wdata_o(mem_req_wdata_o),
    .mem_req_wstrb_o(mem_req_wstrb_o),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_flush_o(mem_flush_o),
    .mmu_flush_o(mmu_flush_o)
  );

endmodule
