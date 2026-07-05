`include "define.v"

module OooMemoryRequestGate (
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
  assign mmu_flush_o =
      pending_system_satp_write_commit_i || pending_system_sfence_commit_i ||
      pending_system_fencei_commit_i;   // fence.i：整块清取指包(clear_i) + fetch 桥复位

endmodule
