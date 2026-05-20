`include "define.v"

// 流水线控制面只产生推进、清空和重定向信号；数据计算仍留在 NpcCore 的数据通路中。
module PipelineControl (
  input if_id_valid_i,
  input id_ex_valid_i,
  input id_ex_load_i,
  input id_ex_ecall_i,
  input id_ex_ebreak_i,
  input id_ex_mret_i,
  input id_ex_branch_i,
  input id_ex_jal_i,
  input id_ex_jalr_i,
  input [`REG_ADDR_W-1:0] id_ex_rd_idx_i,
  input [`XLEN-1:0] id_ex_pred_pc_i,

  input dec_uses_rs1_i,
  input dec_uses_rs2_i,
  input [`REG_ADDR_W-1:0] dec_rs1_idx_i,
  input [`REG_ADDR_W-1:0] dec_rs2_idx_i,

  input ex_mem_valid_i,
  input ex_mem_is_mem_i,
  input mem_response_i,
  input mem_fault_i,
  input ex_wait_i,

  input halt_i,
  input fatal_i,

  input ex_fetch_fault_i,
  input ex_illegal_i,
  input ex_redirect_misaligned_i,
  input ex_load_store_misaligned_i,
  input [`XLEN-1:0] ex_control_next_pc_i,
  input [`XLEN-1:0] ex_redirect_pc_i,
  input [`XLEN-1:0] trap_target_i,
  input [`XLEN-1:0] csr_mepc_i,

  input cache_flush_valid_i,
  input [`XLEN-1:0] cache_flush_redirect_pc_i,

  output ex_fire_o,
  output ex_exception_o,
  output ex_exception_fatal_o,
  output ex_mret_redirect_o,
  output ex_any_flush_o,
  output id_accept_o,
  output if_id_consume_o,
  output if_id_can_refill_o,
  output ebreak_fire_o,
  output pipeline_normal_update_o,
  output if_redirect_valid_o,
  output [`XLEN-1:0] if_redirect_pc_o,
  output ex_mem_leave_update_o,
  output ex_mem_load_update_o,
  output mem_wb_from_mem_o,
  output mem_wb_from_ex_o,
  output mem_wb_load_o,
  output bpu_update_valid_o
);

  wire load_use_hazard_w;
  wire ex_mem_leave_w;
  wire ex_mem_can_accept_w;
  wire raw_ex_exception_w;
  wire ex_exception_redirect_w;
  wire ex_branch_redirect_w;
  wire ex_to_mem_w;
  wire id_ex_slot_free_w;

  assign load_use_hazard_w = if_id_valid_i && id_ex_valid_i && id_ex_load_i &&
                             (id_ex_rd_idx_i != {`REG_ADDR_W{1'b0}}) &&
                             ((dec_uses_rs1_i && (dec_rs1_idx_i == id_ex_rd_idx_i)) ||
                              (dec_uses_rs2_i && (dec_rs2_idx_i == id_ex_rd_idx_i)));

  assign ex_mem_leave_w = ex_mem_valid_i &&
                          (ex_mem_is_mem_i ? mem_response_i : 1'b1);
  assign ex_mem_can_accept_w = (~ex_mem_valid_i) || (ex_mem_leave_w && ~mem_fault_i);
  assign ex_fire_o = id_ex_valid_i && ex_mem_can_accept_w &&
                     ~ex_wait_i && ~halt_i && ~fatal_i;

  assign raw_ex_exception_w = ex_fetch_fault_i | ex_illegal_i |
                              ex_redirect_misaligned_i |
                              ex_load_store_misaligned_i |
                              id_ex_ecall_i;
  assign ex_exception_o = ex_fire_o && raw_ex_exception_w;
  assign ex_exception_fatal_o = ex_exception_o && (trap_target_i == {`XLEN{1'b0}});
  assign ex_exception_redirect_w = ex_exception_o && ~ex_exception_fatal_o;
  assign ex_mret_redirect_o = ex_fire_o && id_ex_mret_i;
  assign ex_branch_redirect_w = ex_fire_o && (id_ex_branch_i | id_ex_jal_i | id_ex_jalr_i) &&
                                ~ex_redirect_misaligned_i && ~ex_exception_o &&
                                (id_ex_pred_pc_i != ex_control_next_pc_i);
  assign ebreak_fire_o = ex_fire_o && id_ex_ebreak_i;
  assign ex_any_flush_o = mem_fault_i | ex_exception_o | ex_mret_redirect_o |
                          ex_branch_redirect_w | cache_flush_valid_i |
                          ebreak_fire_o;

  assign id_ex_slot_free_w = (~id_ex_valid_i) || ex_fire_o || mem_fault_i;
  assign id_accept_o = if_id_valid_i && id_ex_slot_free_w &&
                       ~load_use_hazard_w && ~ex_any_flush_o &&
                       ~halt_i && ~fatal_i;
  assign if_id_consume_o = id_accept_o;
  assign if_id_can_refill_o = (~if_id_valid_i) || if_id_consume_o;

  assign pipeline_normal_update_o = ~(mem_fault_i | ex_exception_o | ebreak_fire_o);

  assign if_redirect_valid_o = (mem_fault_i && (trap_target_i != {`XLEN{1'b0}})) |
                               ex_exception_redirect_w | ex_mret_redirect_o |
                               ex_branch_redirect_w | cache_flush_valid_i;
  assign if_redirect_pc_o =
      mem_fault_i ? trap_target_i :
      ex_exception_redirect_w ? trap_target_i :
      ex_mret_redirect_o ? csr_mepc_i :
      cache_flush_valid_i ? cache_flush_redirect_pc_i :
      ex_redirect_pc_i;

  assign ex_to_mem_w = ex_fire_o && ~ex_exception_o && ~id_ex_ebreak_i;
  assign ex_mem_leave_update_o = pipeline_normal_update_o && ex_mem_leave_w;
  assign ex_mem_load_update_o = pipeline_normal_update_o && ex_to_mem_w;
  assign mem_wb_from_mem_o = pipeline_normal_update_o && mem_response_i;
  assign mem_wb_from_ex_o = pipeline_normal_update_o && ex_mem_valid_i && ~ex_mem_is_mem_i;
  assign mem_wb_load_o = mem_wb_from_mem_o | mem_wb_from_ex_o;

  assign bpu_update_valid_o = ex_fire_o &&
                              (id_ex_branch_i | id_ex_jal_i | id_ex_jalr_i) &&
                              ~ex_exception_o;

endmodule
