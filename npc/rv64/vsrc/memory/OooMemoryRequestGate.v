`include "define.v"

module OooMemoryRequestGate (
  input core_local_flush_i,
  input checkpoint_mem_flush_i,
  input pending_system_satp_write_commit_i,
  input pending_system_sfence_commit_i,

  input stop_pending_i,
  input pending_fp_i,
  input backend_drained_i,
  input pending_fp_mem_pending_i,
  input pending_fp_mem_done_i,
  input pending_fp_store_i,
  input [`XLEN-1:0] pending_fp_mem_aligned_addr_i,
  input [`XLEN-1:0] pending_fp_mem_wdata_i,
  input [`STRB_W-1:0] pending_fp_mem_wstrb_i,

  input core_mem_req_valid_i,
  input core_mem_req_write_i,
  input [`XLEN-1:0] core_mem_req_addr_i,
  input [`XLEN-1:0] core_mem_req_wdata_i,
  input [`STRB_W-1:0] core_mem_req_wstrb_i,
  input core_mem_rsp_ready_i,

  input mem_req_ready_i,
  input mem_rsp_valid_i,

  output pending_fp_mem_req_valid_o,
  output pending_fp_mem_req_fire_o,
  output pending_fp_mem_rsp_fire_o,

  output mem_req_valid_o,
  output mem_req_write_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  output mem_rsp_ready_o,

  output mem_flush_o,
  output mmu_flush_o
);

  wire pending_fp_mem_req_valid_w =
      stop_pending_i && pending_fp_i && backend_drained_i &&
      !pending_fp_mem_pending_i && !pending_fp_mem_done_i;

  assign pending_fp_mem_req_valid_o = pending_fp_mem_req_valid_w;
  assign pending_fp_mem_req_fire_o =
      pending_fp_mem_req_valid_w && mem_req_ready_i;
  assign pending_fp_mem_rsp_fire_o =
      pending_fp_mem_pending_i && mem_rsp_valid_i;

  assign mem_req_valid_o =
      pending_fp_mem_req_valid_w ? 1'b1 : core_mem_req_valid_i;
  assign mem_req_write_o =
      pending_fp_mem_req_valid_w ? pending_fp_store_i : core_mem_req_write_i;
  assign mem_req_addr_o =
      pending_fp_mem_req_valid_w ? pending_fp_mem_aligned_addr_i :
                                  core_mem_req_addr_i;
  assign mem_req_wdata_o =
      pending_fp_mem_req_valid_w ? pending_fp_mem_wdata_i :
                                  core_mem_req_wdata_i;
  assign mem_req_wstrb_o =
      pending_fp_mem_req_valid_w ? pending_fp_mem_wstrb_i :
                                  core_mem_req_wstrb_i;
  assign mem_rsp_ready_o =
      pending_fp_mem_pending_i ? 1'b1 : core_mem_rsp_ready_i;

  assign mem_flush_o = core_local_flush_i || checkpoint_mem_flush_i;
  assign mmu_flush_o =
      pending_system_satp_write_commit_i || pending_system_sfence_commit_i;

endmodule
