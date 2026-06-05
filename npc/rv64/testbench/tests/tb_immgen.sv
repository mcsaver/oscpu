`include "define.v"

module tb_immgen;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg [`INST_W-1:0] inst;
  reg [2:0] imm_type;
  wire [`XLEN-1:0] imm;

  ImmGen dut (
    .inst_imm_i(inst[31:7]),
    .imm_type_i(imm_type),
    .imm_o(imm)
  );

  task automatic run_imm;
    input [1023:0] name;
    input [`INST_W-1:0] inst_value;
    input [2:0] type_value;
    input [`XLEN-1:0] exp;
    begin
      inst = inst_value;
      imm_type = type_value;
      #1;
      tb_check32(name, imm, exp);
    end
  endtask

  initial begin
    tb_errors = 0;

    run_imm("I -1", rv32_i(12'hfff, 5'd1, `FUNCT3_ADD_SUB, 5'd2, `OPCODE_OP_IMM), `IMM_TYPE_I, 32'hffff_ffff);
    run_imm("S -16", rv32_s(12'hff0, 5'd3, 5'd4, `FUNCT3_SW), `IMM_TYPE_S, 32'hffff_fff0);
    run_imm("B -4", rv32_b(13'h1ffc, 5'd2, 5'd1, `FUNCT3_BEQ), `IMM_TYPE_B, 32'hffff_fffc);
    run_imm("U", rv32_u(20'habcde, 5'd5, `OPCODE_LUI), `IMM_TYPE_U, 32'habcde000);
    run_imm("J 2048", rv32_j(21'd2048, 5'd1), `IMM_TYPE_J, 32'd2048);
    run_imm("X zero", 32'hffff_ffff, `IMM_TYPE_X, 32'h0000_0000);

    tb_finish("tb_immgen");
  end
endmodule
