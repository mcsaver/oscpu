`include "define.v"

module tb_branch_predictor;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg clk;
  reg rst;
  reg predict_valid;
  reg [`XLEN-1:0] predict_pc;
  reg [`INST_W-1:0] predict_inst;
  reg [`XLEN-1:0] predict_seq_pc;
  wire [`XLEN-1:0] predict_next_pc;
  reg update_valid;
  reg [`XLEN-1:0] update_pc;
  reg [`INST_W-1:0] update_inst;
  reg [`XLEN-1:0] update_seq_pc;
  reg [`XLEN-1:0] update_next_pc;
  reg update_taken;

  BranchPredictor dut (
    .clk(clk),
    .rst(rst),
    .predict_valid_i(predict_valid),
    .predict_pc_i(predict_pc),
    .predict_inst_i(predict_inst),
    .predict_seq_pc_i(predict_seq_pc),
    .predict_next_pc_o(predict_next_pc),
    .update_valid_i(update_valid),
    .update_pc_i(update_pc),
    .update_inst_i(update_inst),
    .update_seq_pc_i(update_seq_pc),
    .update_next_pc_i(update_next_pc),
    .update_taken_i(update_taken)
  );

  task automatic reset_dut;
    begin
      rst = 1'b1;
      predict_valid = 1'b0;
      update_valid = 1'b0;
      update_taken = 1'b0;
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    reset_dut();

    predict_valid = 1'b0;
    predict_pc = 32'h8000_0000;
    predict_inst = rv32_b(13'd8, 5'd2, 5'd1, `FUNCT3_BEQ);
    predict_seq_pc = 32'h8000_0004;
    #1;
    tb_check32("predict invalid seq", predict_next_pc, 32'h8000_0004);

    predict_valid = 1'b1;
    #1;
    tb_check32("branch initially weak not taken", predict_next_pc, 32'h8000_0004);

    update_valid = 1'b1;
    update_pc = 32'h8000_0000;
    update_inst = predict_inst;
    update_seq_pc = 32'h8000_0004;
    update_next_pc = 32'h8000_0008;
    update_taken = 1'b1;
    `TB_TICK(clk);
    update_valid = 1'b0;
    #1;
    tb_check32("branch trains taken", predict_next_pc, 32'h8000_0008);

    predict_inst = rv32_j(21'd16, 5'd1);
    predict_pc = 32'h8000_0100;
    predict_seq_pc = 32'h8000_0104;
    #1;
    tb_check32("jal direct target", predict_next_pc, 32'h8000_0110);

    update_valid = 1'b1;
    update_pc = 32'h8000_0200;
    update_inst = rv32_j(21'd32, 5'd1);
    update_seq_pc = 32'h8000_0204;
    update_next_pc = 32'h8000_0220;
    update_taken = 1'b1;
    `TB_TICK(clk);
    update_valid = 1'b0;
    predict_pc = 32'h8000_0300;
    predict_seq_pc = 32'h8000_0304;
    predict_inst = rv32_i(12'h000, 5'd1, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_JALR);
    #1;
    tb_check32("ras return target", predict_next_pc, 32'h8000_0204);

    update_valid = 1'b1;
    update_pc = 32'h8000_0300;
    update_inst = predict_inst;
    update_seq_pc = 32'h8000_0304;
    update_next_pc = 32'h8000_0204;
    update_taken = 1'b1;
    `TB_TICK(clk);
    update_valid = 1'b0;
    predict_pc = 32'h8000_0400;
    predict_seq_pc = 32'h8000_0404;
    #1;
    tb_check32("ras pop empty falls back", predict_next_pc, 32'h8000_0404);

    tb_finish("tb_branch_predictor");
  end
endmodule
