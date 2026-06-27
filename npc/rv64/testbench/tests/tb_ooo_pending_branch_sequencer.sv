`timescale 1ns/1ps
`include "define.v"

module tb_ooo_pending_branch_sequencer;
  reg clk;
  reg rst;
  reg late_clear;
  reg clear;
  reg clear_dispatched;
  reg capture_direct;
  reg capture_direct_valid;
  reg [`XLEN-1:0] capture_direct_pc;
  reg [`XLEN-1:0] capture_direct_next_pc;
  reg [`INST_W-1:0] capture_direct_inst;
  reg [`REG_ADDR_W-1:0] capture_direct_rs1;
  reg [`REG_ADDR_W-1:0] capture_direct_rs2;
  reg [`XLEN-1:0] capture_direct_imm;
  reg [2:0] capture_direct_cmp_op;
  reg capture_direct_pred_taken;
  reg capture_direct_bht_valid;
  reg [`BPU_BHT_INDEX_W-1:0] capture_direct_bht_idx;
  reg capture_head0;
  reg [`XLEN-1:0] capture_head0_pc;
  reg [`XLEN-1:0] capture_head0_next_pc;
  reg [`INST_W-1:0] capture_head0_inst;
  reg [`REG_ADDR_W-1:0] capture_head0_rs1;
  reg [`REG_ADDR_W-1:0] capture_head0_rs2;
  reg [`XLEN-1:0] capture_head0_imm;
  reg [2:0] capture_head0_cmp_op;
  reg capture_head0_pred_taken;
  reg capture_head0_bht_valid;
  reg [`BPU_BHT_INDEX_W-1:0] capture_head0_bht_idx;
  reg capture_lane1;
  reg capture_lane1_valid;
  reg [`XLEN-1:0] capture_lane1_pc;
  reg [`XLEN-1:0] capture_lane1_next_pc;
  reg [`INST_W-1:0] capture_lane1_inst;
  reg [`REG_ADDR_W-1:0] capture_lane1_rs1;
  reg [`REG_ADDR_W-1:0] capture_lane1_rs2;
  reg [`XLEN-1:0] capture_lane1_imm;
  reg [2:0] capture_lane1_cmp_op;
  reg capture_lane1_pred_taken;
  reg capture_lane1_bht_valid;
  reg [`BPU_BHT_INDEX_W-1:0] capture_lane1_bht_idx;

  wire valid;
  wire dispatched;
  wire [`XLEN-1:0] pc;
  wire [`XLEN-1:0] next_pc;
  wire [`INST_W-1:0] inst;
  wire [`REG_ADDR_W-1:0] rs1;
  wire [`REG_ADDR_W-1:0] rs2;
  wire [`XLEN-1:0] imm;
  wire [2:0] cmp_op;
  wire pred_taken;
  wire bht_valid;
  wire [`BPU_BHT_INDEX_W-1:0] bht_idx;

  integer errors;

  OooPendingBranchSequencer dut (
    .clk(clk),
    .rst(rst),
    .late_clear_i(late_clear),
    .clear_i(clear),
    .clear_dispatched_i(clear_dispatched),
    .capture_direct_i(capture_direct),
    .capture_direct_valid_i(capture_direct_valid),
    .capture_direct_pc_i(capture_direct_pc),
    .capture_direct_next_pc_i(capture_direct_next_pc),
    .capture_direct_inst_i(capture_direct_inst),
    .capture_direct_rs1_i(capture_direct_rs1),
    .capture_direct_rs2_i(capture_direct_rs2),
    .capture_direct_imm_i(capture_direct_imm),
    .capture_direct_cmp_op_i(capture_direct_cmp_op),
    .capture_direct_pred_taken_i(capture_direct_pred_taken),
    .capture_direct_bht_valid_i(capture_direct_bht_valid),
    .capture_direct_bht_idx_i(capture_direct_bht_idx),
    .capture_head0_i(capture_head0),
    .capture_head0_pc_i(capture_head0_pc),
    .capture_head0_next_pc_i(capture_head0_next_pc),
    .capture_head0_inst_i(capture_head0_inst),
    .capture_head0_rs1_i(capture_head0_rs1),
    .capture_head0_rs2_i(capture_head0_rs2),
    .capture_head0_imm_i(capture_head0_imm),
    .capture_head0_cmp_op_i(capture_head0_cmp_op),
    .capture_head0_pred_taken_i(capture_head0_pred_taken),
    .capture_head0_bht_valid_i(capture_head0_bht_valid),
    .capture_head0_bht_idx_i(capture_head0_bht_idx),
    .capture_lane1_i(capture_lane1),
    .capture_lane1_valid_i(capture_lane1_valid),
    .capture_lane1_pc_i(capture_lane1_pc),
    .capture_lane1_next_pc_i(capture_lane1_next_pc),
    .capture_lane1_inst_i(capture_lane1_inst),
    .capture_lane1_rs1_i(capture_lane1_rs1),
    .capture_lane1_rs2_i(capture_lane1_rs2),
    .capture_lane1_imm_i(capture_lane1_imm),
    .capture_lane1_cmp_op_i(capture_lane1_cmp_op),
    .capture_lane1_pred_taken_i(capture_lane1_pred_taken),
    .capture_lane1_bht_valid_i(capture_lane1_bht_valid),
    .capture_lane1_bht_idx_i(capture_lane1_bht_idx),
    .valid_o(valid),
    .dispatched_o(dispatched),
    .pc_o(pc),
    .next_pc_o(next_pc),
    .inst_o(inst),
    .rs1_o(rs1),
    .rs2_o(rs2),
    .imm_o(imm),
    .cmp_op_o(cmp_op),
    .pred_taken_o(pred_taken),
    .bht_valid_o(bht_valid),
    .bht_idx_o(bht_idx)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tb_check1;
    input [255:0] name;
    input actual;
    input expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%0b expected=%0b", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check3;
    input [255:0] name;
    input [2:0] actual;
    input [2:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%01h expected=0x%01h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check5;
    input [255:0] name;
    input [`REG_ADDR_W-1:0] actual;
    input [`REG_ADDR_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%02h expected=0x%02h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check_bht;
    input [255:0] name;
    input [`BPU_BHT_INDEX_W-1:0] actual;
    input [`BPU_BHT_INDEX_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%0h expected=0x%0h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check64;
    input [255:0] name;
    input [`XLEN-1:0] actual;
    input [`XLEN-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%016h expected=0x%016h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check_inst;
    input [255:0] name;
    input [`INST_W-1:0] actual;
    input [`INST_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%08h expected=0x%08h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      late_clear = 1'b0;
      clear = 1'b0;
      clear_dispatched = 1'b0;
      capture_direct = 1'b0;
      capture_direct_valid = 1'b0;
      capture_direct_pc = 64'h0000_0000_8000_1000;
      capture_direct_next_pc = 64'h0000_0000_8000_1004;
      capture_direct_inst = 32'h0020_8063;
      capture_direct_rs1 = 5'd1;
      capture_direct_rs2 = 5'd2;
      capture_direct_imm = 64'h0000_0000_0000_0010;
      capture_direct_cmp_op = `CMP_OP_EQ;
      capture_direct_pred_taken = 1'b0;
      capture_direct_bht_valid = 1'b0;
      capture_direct_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
      capture_head0 = 1'b0;
      capture_head0_pc = 64'h0000_0000_8000_2000;
      capture_head0_next_pc = 64'h0000_0000_8000_2004;
      capture_head0_inst = 32'h0020_9463;
      capture_head0_rs1 = 5'd3;
      capture_head0_rs2 = 5'd4;
      capture_head0_imm = 64'h0000_0000_0000_0020;
      capture_head0_cmp_op = `CMP_OP_NE;
      capture_head0_pred_taken = 1'b1;
      capture_head0_bht_valid = 1'b1;
      capture_head0_bht_idx = {{(`BPU_BHT_INDEX_W-4){1'b0}}, 4'ha};
      capture_lane1 = 1'b0;
      capture_lane1_valid = 1'b0;
      capture_lane1_pc = 64'h0000_0000_8000_3002;
      capture_lane1_next_pc = 64'h0000_0000_8000_3006;
      capture_lane1_inst = 32'h0041_c663;
      capture_lane1_rs1 = 5'd5;
      capture_lane1_rs2 = 5'd6;
      capture_lane1_imm = 64'h0000_0000_0000_0030;
      capture_lane1_cmp_op = `CMP_OP_LT;
      capture_lane1_pred_taken = 1'b0;
      capture_lane1_bht_valid = 1'b1;
      capture_lane1_bht_idx = {{(`BPU_BHT_INDEX_W-4){1'b0}}, 4'hc};
    end
  endtask

  task automatic tick;
    begin
      @(negedge clk);
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    errors = 0;
    clear_inputs();
    rst = 1'b1;
    repeat (2) tick();
    tb_check1("reset valid", valid, 1'b0);
    tb_check1("reset dispatched", dispatched, 1'b0);
    tb_check64("reset pc", pc, {`XLEN{1'b0}});
    tb_check64("reset next_pc", next_pc, {`XLEN{1'b0}});
    tb_check_inst("reset inst", inst, {`INST_W{1'b0}});
    tb_check5("reset rs1", rs1, {`REG_ADDR_W{1'b0}});
    tb_check5("reset rs2", rs2, {`REG_ADDR_W{1'b0}});
    tb_check64("reset imm", imm, {`XLEN{1'b0}});
    tb_check3("reset cmp", cmp_op, `CMP_OP_NONE);
    tb_check1("reset pred", pred_taken, 1'b0);
    tb_check1("reset bht valid", bht_valid, 1'b0);
    tb_check_bht("reset bht idx", bht_idx, {`BPU_BHT_INDEX_W{1'b0}});

    rst = 1'b0;
    clear_inputs();
    capture_direct = 1'b1;
    capture_direct_valid = 1'b1;
    capture_direct_pred_taken = 1'b1;
    capture_direct_bht_valid = 1'b1;
    capture_direct_bht_idx = {{(`BPU_BHT_INDEX_W-4){1'b0}}, 4'h3};
    tick();
    tb_check1("direct valid", valid, 1'b1);
    tb_check1("direct dispatched", dispatched, 1'b1);
    tb_check64("direct pc", pc, 64'h0000_0000_8000_1000);
    tb_check_inst("direct inst", inst, 32'h0020_8063);
    tb_check5("direct rs1", rs1, 5'd1);
    tb_check5("direct rs2", rs2, 5'd2);
    tb_check3("direct cmp", cmp_op, `CMP_OP_EQ);
    tb_check1("direct pred", pred_taken, 1'b1);
    tb_check1("direct bht valid", bht_valid, 1'b1);
    tb_check_bht("direct bht idx", bht_idx,
                 {{(`BPU_BHT_INDEX_W-4){1'b0}}, 4'h3});

    clear_inputs();
    clear_dispatched = 1'b1;
    tick();
    tb_check1("clear dispatched only", dispatched, 1'b0);
    tb_check1("clear dispatched keeps valid", valid, 1'b1);

    clear_inputs();
    clear = 1'b1;
    tick();
    tb_check1("clear valid", valid, 1'b0);
    tb_check1("clear dispatched", dispatched, 1'b0);
    tb_check64("clear keeps pc", pc, 64'h0000_0000_8000_1000);
    tb_check64("clear clears next_pc", next_pc, {`XLEN{1'b0}});
    tb_check1("clear keeps pred", pred_taken, 1'b1);

    clear_inputs();
    capture_direct = 1'b1;
    capture_direct_valid = 1'b0;
    capture_direct_pc = 64'h0000_0000_8000_1800;
    capture_direct_next_pc = 64'h0000_0000_8000_1804;
    capture_direct_inst = 32'h0041_8463;
    capture_direct_rs1 = 5'd7;
    capture_direct_rs2 = 5'd8;
    capture_direct_cmp_op = `CMP_OP_GE;
    tick();
    tb_check1("redirect direct invalid", valid, 1'b0);
    tb_check1("redirect direct dispatched", dispatched, 1'b0);
    tb_check64("redirect direct updates pc", pc, 64'h0000_0000_8000_1800);
    tb_check5("redirect direct updates rs1", rs1, 5'd7);
    tb_check5("redirect direct updates rs2", rs2, 5'd8);
    tb_check3("redirect direct updates cmp", cmp_op, `CMP_OP_GE);

    clear_inputs();
    capture_head0 = 1'b1;
    tick();
    tb_check1("head0 valid", valid, 1'b1);
    tb_check1("head0 dispatched", dispatched, 1'b0);
    tb_check64("head0 pc", pc, 64'h0000_0000_8000_2000);
    tb_check64("head0 next_pc", next_pc, 64'h0000_0000_8000_2004);
    tb_check_inst("head0 inst", inst, 32'h0020_9463);
    tb_check5("head0 rs1", rs1, 5'd3);
    tb_check5("head0 rs2", rs2, 5'd4);
    tb_check3("head0 cmp", cmp_op, `CMP_OP_NE);
    tb_check1("head0 pred", pred_taken, 1'b1);

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b0;
    tick();
    tb_check1("non-branch lane1 valid", valid, 1'b0);
    tb_check1("non-branch lane1 dispatched", dispatched, 1'b0);
    tb_check64("non-branch lane1 pc", pc, 64'h0000_0000_8000_3002);
    tb_check5("non-branch lane1 rs1", rs1, 5'd5);
    tb_check5("non-branch lane1 rs2", rs2, 5'd6);
    tb_check3("non-branch lane1 cmp", cmp_op, `CMP_OP_LT);

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b1;
    clear = 1'b1;
    tick();
    tb_check1("lane1 capture over clear valid", valid, 1'b1);
    tb_check1("lane1 capture over clear dispatched", dispatched, 1'b0);
    tb_check64("lane1 capture over clear pc", pc,
               64'h0000_0000_8000_3002);

    clear_inputs();
    capture_head0 = 1'b1;
    capture_head0_pc = 64'h0000_0000_8000_4000;
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b1;
    tick();
    tb_check1("head0 over lane1 valid", valid, 1'b1);
    tb_check64("head0 over lane1 pc", pc, 64'h0000_0000_8000_4000);

    clear_inputs();
    late_clear = 1'b1;
    capture_head0 = 1'b1;
    capture_head0_pc = 64'h0000_0000_8000_5000;
    tick();
    tb_check1("late clear over capture valid", valid, 1'b0);
    tb_check1("late clear over capture dispatched", dispatched, 1'b0);
    tb_check64("late clear keeps previous pc", pc, 64'h0000_0000_8000_4000);
    tb_check64("late clear clears next_pc", next_pc, {`XLEN{1'b0}});

    if (errors == 0) begin
      $display("PASS tb_ooo_pending_branch_sequencer");
      $finish;
    end
    $display("FAIL tb_ooo_pending_branch_sequencer errors=%0d", errors);
    $finish;
  end

endmodule
