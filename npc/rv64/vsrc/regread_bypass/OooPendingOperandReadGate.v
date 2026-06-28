`include "define.v"

// Pending owner 需要的架构操作数读取归到 regread/bypass 边界，避免 core glue 解包 GPR 总线。
module OooPendingOperandReadGate(
  input [`XLEN * `REG_NUM - 1:0] gprs_i,
  input [`REG_ADDR_W-1:0] pending_branch_rs1_i,
  input [`REG_ADDR_W-1:0] pending_branch_rs2_i,
  input [`REG_ADDR_W-1:0] pending_jump_rs1_i,
  input [`INST_W-1:0] pending_fp_inst_i,
  output [`XLEN-1:0] pending_branch_rs1_data_o,
  output [`XLEN-1:0] pending_branch_rs2_data_o,
  output [`XLEN-1:0] pending_jump_rs1_data_o,
  output [`REG_ADDR_W-1:0] pending_fp_rs1_idx_o,
  output [`REG_ADDR_W-1:0] pending_fp_rs2_idx_o,
  output [`REG_ADDR_W-1:0] pending_fp_rs3_idx_o,
  output [`XLEN-1:0] pending_fp_int_rs1_value_o
);

  function [`XLEN-1:0] arch_gpr;
    input [`XLEN * `REG_NUM - 1:0] gprs;
    input [`REG_ADDR_W-1:0] idx;
    begin
      arch_gpr = gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

  assign pending_branch_rs1_data_o = arch_gpr(gprs_i, pending_branch_rs1_i);
  assign pending_branch_rs2_data_o = arch_gpr(gprs_i, pending_branch_rs2_i);
  assign pending_jump_rs1_data_o = arch_gpr(gprs_i, pending_jump_rs1_i);

  assign pending_fp_rs1_idx_o = pending_fp_inst_i[19:15];
  assign pending_fp_rs2_idx_o = pending_fp_inst_i[24:20];
  assign pending_fp_rs3_idx_o = pending_fp_inst_i[31:27];
  assign pending_fp_int_rs1_value_o =
      arch_gpr(gprs_i, pending_fp_rs1_idx_o);

endmodule
