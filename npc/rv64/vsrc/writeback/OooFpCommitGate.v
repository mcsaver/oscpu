`include "define.v"

// FP pending 的提交门控属于 writeback：统一产生 fflags、FPR load/result 写回和提交值。
module OooFpCommitGate(
  input csr_trap_mem_valid_i,
  input direct_frontend_flush_i,
  input stop_pending_i,
  input drain_complete_i,
  input pending_arch_trap_i,
  input pending_system_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input pending_jump_i,
  input pending_mem_i,
  input pending_fp_i,
  input pending_fp_long_op_i,
  input [`XLEN-1:0] pending_fp_long_result_i,
  input [4:0] pending_fp_long_fflags_i,
  input [`XLEN-1:0] pending_fp_compute_result_i,
  input [4:0] pending_fp_compute_fflags_i,
  input pending_fp_gpr_write_i,
  input pending_fp_load_i,
  input pending_fp_store_i,
  input pending_fp_double_i,
  input [`XLEN-1:0] pending_fp_addr_i,
  input [`REG_ADDR_W-1:0] pending_fp_rd_i,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input pending_fp_mem_rsp_fire_i,
  output [`XLEN-1:0] pending_fp_result_value_o,
  output fp_fflags_commit_o,
  output [4:0] fp_fflags_o,
  output gpr_commit_o,
  output fpr_load_write_valid_o,
  output [`REG_ADDR_W-1:0] fpr_load_write_addr_o,
  output [`XLEN-1:0] fpr_load_write_data_o,
  output fpr_result_write_valid_o,
  output [`REG_ADDR_W-1:0] fpr_result_write_addr_o,
  output [`XLEN-1:0] fpr_result_write_data_o
);

  wire [4:0] commit_fflags_w =
      pending_fp_long_op_i ? pending_fp_long_fflags_i :
                             pending_fp_compute_fflags_i;
  wire commit_fire_w =
      !csr_trap_mem_valid_i && !direct_frontend_flush_i &&
      stop_pending_i && drain_complete_i && pending_fp_i;
  wire [`XLEN-1:0] shifted_rdata_w =
      mem_rsp_rdata_i >> {pending_fp_addr_i[`XLEN_BYTE_W-1:0], 3'b000};
  wire [`XLEN-1:0] load_value_w =
      pending_fp_double_i ? shifted_rdata_w :
      {32'hffff_ffff, shifted_rdata_w[31:0]};

  assign pending_fp_result_value_o =
      pending_fp_long_op_i ? pending_fp_long_result_i :
                             pending_fp_compute_result_i;
  assign fp_fflags_commit_o =
      commit_fire_w && (commit_fflags_w != 5'b00000);
  assign fp_fflags_o = commit_fflags_w;
  assign gpr_commit_o =
      !direct_frontend_flush_i && stop_pending_i && drain_complete_i &&
      pending_fp_i && pending_fp_gpr_write_i;

  assign fpr_load_write_valid_o = pending_fp_mem_rsp_fire_i && pending_fp_load_i;
  assign fpr_load_write_addr_o = pending_fp_rd_i;
  assign fpr_load_write_data_o = load_value_w;

  assign fpr_result_write_valid_o =
      !csr_trap_mem_valid_i && !direct_frontend_flush_i &&
      stop_pending_i && drain_complete_i && !pending_arch_trap_i &&
      !pending_system_i && !(pending_branch_i && !pending_branch_dispatched_i) &&
      !pending_jump_i && !pending_mem_i && pending_fp_i &&
      !pending_fp_load_i && !pending_fp_store_i && !pending_fp_gpr_write_i;
  assign fpr_result_write_addr_o = pending_fp_rd_i;
  assign fpr_result_write_data_o = pending_fp_result_value_o;

endmodule
