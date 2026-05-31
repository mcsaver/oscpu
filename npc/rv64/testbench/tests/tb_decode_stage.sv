`include "define.v"

module tb_decode_stage;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg [`INST_W-1:0] inst;
  wire [`CTRL_BUS_W-1:0] ctrl;
  wire [`REG_ADDR_W-1:0] rs1_idx;
  wire [`REG_ADDR_W-1:0] rs2_idx;
  wire [`REG_ADDR_W-1:0] rd_idx;
  wire [`XLEN-1:0] imm;

  DecodeStage dut (
    .inst_i(inst),
    .ctrl_o(ctrl),
    .rs1_idx_o(rs1_idx),
    .rs2_idx_o(rs2_idx),
    .rd_idx_o(rd_idx),
    .imm_o(imm)
  );

  initial begin
    tb_errors = 0;

    inst = rv32_i(12'hffc, 5'd2, `FUNCT3_ADD_SUB, 5'd3, `OPCODE_OP_IMM); #1;
    tb_check1("addi legal", ctrl[`CTRL_ILLEGAL_BIT], 1'b0);
    tb_check32("addi imm", imm, 32'hffff_fffc);
    tb_check32("addi rs1", {27'b0, rs1_idx}, 32'd2);
    tb_check32("addi rd", {27'b0, rd_idx}, 32'd3);

    inst = rv32_b(13'd12, 5'd4, 5'd5, `FUNCT3_BNE); #1;
    tb_check1("bne branch", ctrl[`CTRL_BRANCH_BIT], 1'b1);
    tb_check32("bne imm", imm, 32'd12);
    tb_check32("bne rs2", {27'b0, rs2_idx}, 32'd4);

    inst = rv32_u(20'h12345, 5'd8, `OPCODE_LUI); #1;
    tb_check1("lui rd", ctrl[`CTRL_RD_EN_BIT], 1'b1);
    tb_check32("lui imm", imm, 32'h1234_5000);

    tb_finish("tb_decode_stage");
  end
endmodule
