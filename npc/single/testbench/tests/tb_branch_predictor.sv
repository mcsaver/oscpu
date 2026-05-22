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
  wire [9:0] predict_bht_idx;
  wire predict_control;
  wire predict_branch;
  wire predict_jalr;
  wire predict_ret;
  wire predict_btb_hit;
  wire predict_bht_valid;
  wire predict_bht_taken;
  wire predict_ras_lookup;
  wire predict_ras_hit;
  wire predict_ras_overflow;
  reg rollback;
  reg update_valid;
  reg [`XLEN-1:0] update_pc;
  reg [`INST_W-1:0] update_inst;
  reg [`XLEN-1:0] update_seq_pc;
  reg [`XLEN-1:0] update_next_pc;
  reg update_taken;
  reg [9:0] update_bht_idx;
  reg [9:0] saved_bht_idx;
  integer train_i;

  BranchPredictor dut (
    .clk(clk),
    .rst(rst),
    .predict_valid_i(predict_valid),
    .predict_pc_i(predict_pc),
    .predict_inst_i(predict_inst),
    .predict_seq_pc_i(predict_seq_pc),
    .predict_next_pc_o(predict_next_pc),
    .predict_bht_idx_o(predict_bht_idx),
    .predict_control_o(predict_control),
    .predict_branch_o(predict_branch),
    .predict_jalr_o(predict_jalr),
    .predict_ret_o(predict_ret),
    .predict_btb_hit_o(predict_btb_hit),
    .predict_bht_valid_o(predict_bht_valid),
    .predict_bht_taken_o(predict_bht_taken),
    .predict_ras_lookup_o(predict_ras_lookup),
    .predict_ras_hit_o(predict_ras_hit),
    .predict_ras_overflow_o(predict_ras_overflow),
    .rollback_i(rollback),
    .update_valid_i(update_valid),
    .update_pc_i(update_pc),
    .update_inst_i(update_inst),
    .update_seq_pc_i(update_seq_pc),
    .update_next_pc_i(update_next_pc),
    .update_taken_i(update_taken),
    .update_bht_idx_i(update_bht_idx)
  );

  task automatic reset_dut;
    begin
      rst = 1'b1;
      predict_valid = 1'b0;
      predict_pc = 32'h0;
      predict_inst = 32'h0;
      predict_seq_pc = 32'h0;
      rollback = 1'b0;
      update_valid = 1'b0;
      update_pc = 32'h0;
      update_inst = 32'h0;
      update_seq_pc = 32'h0;
      update_next_pc = 32'h0;
      update_taken = 1'b0;
      update_bht_idx = 10'h0;
      saved_bht_idx = 10'h0;
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    reset_dut();
    tb_check32("reset gshare counter weak taken", {30'b0, dut.bht_q[0]}, 32'd2);
    tb_check32("reset local counter weak taken", {30'b0, dut.local_pht_q[0]}, 32'd2);

    predict_valid = 1'b0;
    predict_pc = 32'h8000_0000;
    predict_inst = rv32_b(13'd8, 5'd2, 5'd1, `FUNCT3_BEQ);
    predict_seq_pc = 32'h8000_0004;
    #1;
    tb_check32("predict invalid seq", predict_next_pc, 32'h8000_0004);

    predict_valid = 1'b1;
    #1;
    tb_check32("cold forward branch uses BTFNT not taken", predict_next_pc, 32'h8000_0004);
    tb_check1("branch cold bht invalid", predict_bht_valid, 1'b0);
    saved_bht_idx = predict_bht_idx;
    predict_valid = 1'b0;

    for (train_i = 0; train_i < 11; train_i = train_i + 1) begin
      predict_valid = 1'b1;
      #1;
      saved_bht_idx = predict_bht_idx;
      predict_valid = 1'b0;
      update_valid = 1'b1;
      update_pc = 32'h8000_0000;
      update_inst = predict_inst;
      update_seq_pc = 32'h8000_0004;
      update_next_pc = 32'h8000_0008;
      update_taken = 1'b1;
      update_bht_idx = saved_bht_idx;
      `TB_TICK(clk);
      update_valid = 1'b0;
      update_taken = 1'b0;
    end
    predict_valid = 1'b1;
    #1;
    tb_check32("gshare branch trains taken", predict_next_pc, 32'h8000_0008);
    tb_check1("branch trained bht valid", predict_bht_valid, 1'b1);
    predict_valid = 1'b0;

    reset_dut();
    update_valid = 1'b1;
    update_pc = 32'h8000_0800;
    update_inst = rv32_b(13'd8, 5'd2, 5'd1, `FUNCT3_BEQ);
    update_seq_pc = 32'h8000_0804;
    update_next_pc = 32'h8000_0808;
    update_taken = 1'b1;
    update_bht_idx = 10'h000;
    `TB_TICK(clk);
    update_valid = 1'b0;
    update_taken = 1'b0;
    predict_pc = 32'h8000_0810;
    predict_seq_pc = 32'h8000_0814;
    predict_inst = rv32_b(13'd8, 5'd2, 5'd1, `FUNCT3_BEQ);
    predict_valid = 1'b1;
    #1;
    tb_check32("local pht pc bits avoid low-bit alias", predict_next_pc, 32'h8000_0814);
    predict_valid = 1'b0;

    reset_dut();
    predict_pc = 32'h8000_0800;
    predict_seq_pc = 32'h8000_0804;
    predict_inst = rv32_b(13'd8, 5'd2, 5'd1, `FUNCT3_BEQ);
    for (train_i = 0; train_i < 48; train_i = train_i + 1) begin
      update_valid = 1'b1;
      update_pc = predict_pc;
      update_inst = predict_inst;
      update_seq_pc = predict_seq_pc;
      update_taken = ((train_i % 2) == 0);
      update_next_pc = update_taken ? 32'h8000_0808 : predict_seq_pc;
      // 故意不使用预测时的 gshare index，确保这个用例验证的是 per-PC local history。
      update_bht_idx = 10'h000;
      `TB_TICK(clk);
      update_valid = 1'b0;
      update_taken = 1'b0;
    end
    predict_valid = 1'b1;
    #1;
    tb_check32("local history overrides weak forward static", predict_next_pc, 32'h8000_0808);
    predict_valid = 1'b0;

    predict_pc = 32'h8000_0100;
    predict_seq_pc = 32'h8000_0104;
    predict_inst = rv32_b(13'h1ffc, 5'd2, 5'd1, `FUNCT3_BEQ);
    predict_valid = 1'b1;
    #1;
    tb_check32("cold backward branch uses BTFNT", predict_next_pc, 32'h8000_00fc);
    predict_valid = 1'b0;

    predict_inst = rv32_j(21'd16, 5'd1);
    predict_pc = 32'h8000_0180;
    predict_seq_pc = 32'h8000_0184;
    predict_valid = 1'b1;
    #1;
    tb_check32("jal direct target", predict_next_pc, 32'h8000_0190);
    `TB_TICK(clk);
    predict_valid = 1'b0;

    predict_pc = 32'h8000_0300;
    predict_seq_pc = 32'h8000_0304;
    predict_inst = rv32_i(12'h000, 5'd1, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_JALR);
    predict_valid = 1'b1;
    #1;
    tb_check32("speculative ras push target", predict_next_pc, 32'h8000_0184);
    `TB_TICK(clk);
    predict_valid = 1'b0;
    predict_valid = 1'b1;
    #1;
    tb_check32("speculative ras pop empty falls back", predict_next_pc, 32'h8000_0304);
    predict_valid = 1'b0;

    predict_pc = 32'h8000_0200;
    predict_seq_pc = 32'h8000_0204;
    predict_inst = rv32_j(21'd32, 5'd1);
    predict_valid = 1'b1;
    #1;
    tb_check32("rollback setup jal target", predict_next_pc, 32'h8000_0220);
    `TB_TICK(clk);
    predict_valid = 1'b0;
    rollback = 1'b1;
    `TB_TICK(clk);
    rollback = 1'b0;
    predict_pc = 32'h8000_0400;
    predict_seq_pc = 32'h8000_0404;
    predict_inst = rv32_i(12'h000, 5'd1, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_JALR);
    predict_valid = 1'b1;
    #1;
    tb_check32("rollback drops killed speculative push", predict_next_pc, 32'h8000_0404);
    predict_valid = 1'b0;

    update_valid = 1'b1;
    update_pc = 32'h8000_0500;
    update_inst = rv32_j(21'd32, 5'd1);
    update_seq_pc = 32'h8000_0504;
    update_next_pc = 32'h8000_0520;
    update_taken = 1'b1;
    rollback = 1'b1;
    `TB_TICK(clk);
    update_valid = 1'b0;
    update_taken = 1'b0;
    rollback = 1'b0;
    predict_pc = 32'h8000_0600;
    predict_seq_pc = 32'h8000_0604;
    predict_inst = rv32_i(12'h000, 5'd1, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_JALR);
    predict_valid = 1'b1;
    #1;
    tb_check32("rollback keeps resolved call update", predict_next_pc, 32'h8000_0504);
    `TB_TICK(clk);
    predict_valid = 1'b0;

    predict_pc = 32'h8000_0700;
    predict_seq_pc = 32'h8000_0704;
    predict_valid = 1'b1;
    #1;
    tb_check32("resolved return speculative pop", predict_next_pc, 32'h8000_0704);
    predict_valid = 1'b0;

    tb_finish("tb_branch_predictor");
  end
endmodule
