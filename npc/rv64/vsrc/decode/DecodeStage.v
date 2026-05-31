`include "define.v"

module DecodeStage (
  input [`INST_W-1:0] inst_i,
  output [`CTRL_BUS_W-1:0] ctrl_o,
  output [`REG_ADDR_W-1:0] rs1_idx_o,
  output [`REG_ADDR_W-1:0] rs2_idx_o,
  output [`REG_ADDR_W-1:0] rd_idx_o,
  output [`XLEN-1:0] imm_o
);

  DecodeUnit u_decode (
    .inst_i(inst_i),
    .ctrl_o(ctrl_o),
    .rs1_idx_o(rs1_idx_o),
    .rs2_idx_o(rs2_idx_o),
    .rd_idx_o(rd_idx_o)
  );

  ImmGen u_imm_gen (
    .inst_i(inst_i),
    .imm_type_i(ctrl_o[`CTRL_IMM_TYPE_MSB:`CTRL_IMM_TYPE_LSB]),
    .imm_o(imm_o)
  );

endmodule
