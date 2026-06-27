`timescale 1ns/1ps
`include "define.v"

module tb_ooo_pending_jump_sequencer;
  reg clk;
  reg rst;
  reg late_clear;
  reg clear;
  reg clear_dispatched;
  reg dispatch_fire;
  reg [`XLEN-1:0] dispatch_target;
  reg capture_head0;
  reg capture_head0_jalr;
  reg [`XLEN-1:0] capture_head0_pc;
  reg [`XLEN-1:0] capture_head0_next_pc;
  reg [`INST_W-1:0] capture_head0_inst;
  reg [`REG_ADDR_W-1:0] capture_head0_rs1;
  reg [`XLEN-1:0] capture_head0_imm;
  reg capture_lane1;
  reg capture_lane1_valid;
  reg capture_lane1_jalr;
  reg [`XLEN-1:0] capture_lane1_pc;
  reg [`XLEN-1:0] capture_lane1_next_pc;
  reg [`INST_W-1:0] capture_lane1_inst;
  reg [`REG_ADDR_W-1:0] capture_lane1_rs1;
  reg [`XLEN-1:0] capture_lane1_imm;

  wire valid;
  wire dispatched;
  wire jalr;
  wire [`XLEN-1:0] pc;
  wire [`XLEN-1:0] next_pc;
  wire [`INST_W-1:0] inst;
  wire [`REG_ADDR_W-1:0] rs1;
  wire [`XLEN-1:0] imm;
  wire [`XLEN-1:0] target;

  integer errors;

  OooPendingJumpSequencer dut (
    .clk(clk),
    .rst(rst),
    .late_clear_i(late_clear),
    .clear_i(clear),
    .clear_dispatched_i(clear_dispatched),
    .dispatch_fire_i(dispatch_fire),
    .dispatch_target_i(dispatch_target),
    .capture_head0_i(capture_head0),
    .capture_head0_jalr_i(capture_head0_jalr),
    .capture_head0_pc_i(capture_head0_pc),
    .capture_head0_next_pc_i(capture_head0_next_pc),
    .capture_head0_inst_i(capture_head0_inst),
    .capture_head0_rs1_i(capture_head0_rs1),
    .capture_head0_imm_i(capture_head0_imm),
    .capture_lane1_i(capture_lane1),
    .capture_lane1_valid_i(capture_lane1_valid),
    .capture_lane1_jalr_i(capture_lane1_jalr),
    .capture_lane1_pc_i(capture_lane1_pc),
    .capture_lane1_next_pc_i(capture_lane1_next_pc),
    .capture_lane1_inst_i(capture_lane1_inst),
    .capture_lane1_rs1_i(capture_lane1_rs1),
    .capture_lane1_imm_i(capture_lane1_imm),
    .valid_o(valid),
    .dispatched_o(dispatched),
    .jalr_o(jalr),
    .pc_o(pc),
    .next_pc_o(next_pc),
    .inst_o(inst),
    .rs1_o(rs1),
    .imm_o(imm),
    .target_o(target)
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
      dispatch_fire = 1'b0;
      dispatch_target = 64'h0000_0000_8000_0000;
      capture_head0 = 1'b0;
      capture_head0_jalr = 1'b0;
      capture_head0_pc = 64'h0000_0000_8000_1000;
      capture_head0_next_pc = 64'h0000_0000_8000_1004;
      capture_head0_inst = 32'h0000_006f;
      capture_head0_rs1 = 5'd0;
      capture_head0_imm = 64'h0000_0000_0000_0010;
      capture_lane1 = 1'b0;
      capture_lane1_valid = 1'b0;
      capture_lane1_jalr = 1'b0;
      capture_lane1_pc = 64'h0000_0000_8000_2002;
      capture_lane1_next_pc = 64'h0000_0000_8000_2006;
      capture_lane1_inst = 32'h0000_006f;
      capture_lane1_rs1 = 5'd0;
      capture_lane1_imm = 64'h0000_0000_0000_0008;
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
    tb_check1("reset jalr", jalr, 1'b0);
    tb_check64("reset pc", pc, {`XLEN{1'b0}});
    tb_check64("reset next_pc", next_pc, {`XLEN{1'b0}});
    tb_check_inst("reset inst", inst, {`INST_W{1'b0}});
    tb_check5("reset rs1", rs1, {`REG_ADDR_W{1'b0}});
    tb_check64("reset imm", imm, {`XLEN{1'b0}});
    tb_check64("reset target", target, {`XLEN{1'b0}});

    rst = 1'b0;
    clear_inputs();
    capture_head0 = 1'b1;
    capture_head0_jalr = 1'b1;
    capture_head0_pc = 64'h0000_0000_8000_3000;
    capture_head0_next_pc = 64'h0000_0000_8000_3004;
    capture_head0_inst = 32'h0002_8067;
    capture_head0_rs1 = 5'd5;
    capture_head0_imm = 64'h0000_0000_0000_0020;
    tick();
    tb_check1("head0 capture valid", valid, 1'b1);
    tb_check1("head0 capture dispatched", dispatched, 1'b0);
    tb_check1("head0 capture jalr", jalr, 1'b1);
    tb_check64("head0 capture pc", pc, 64'h0000_0000_8000_3000);
    tb_check64("head0 capture next_pc", next_pc, 64'h0000_0000_8000_3004);
    tb_check_inst("head0 capture inst", inst, 32'h0002_8067);
    tb_check5("head0 capture rs1", rs1, 5'd5);
    tb_check64("head0 capture imm", imm, 64'h0000_0000_0000_0020);
    tb_check64("head0 capture clears target", target, {`XLEN{1'b0}});

    clear_inputs();
    dispatch_fire = 1'b1;
    dispatch_target = 64'h0000_0000_8000_4020;
    tick();
    tb_check1("dispatch marks dispatched", dispatched, 1'b1);
    tb_check1("dispatch keeps valid", valid, 1'b1);
    tb_check64("dispatch target", target, 64'h0000_0000_8000_4020);
    tb_check64("dispatch keeps pc", pc, 64'h0000_0000_8000_3000);

    clear_inputs();
    clear_dispatched = 1'b1;
    tick();
    tb_check1("clear dispatched only", dispatched, 1'b0);
    tb_check1("clear dispatched keeps valid", valid, 1'b1);
    tb_check64("clear dispatched keeps target", target,
               64'h0000_0000_8000_4020);

    clear_inputs();
    clear = 1'b1;
    tick();
    tb_check1("clear valid", valid, 1'b0);
    tb_check1("clear dispatched", dispatched, 1'b0);
    tb_check1("clear keeps jalr", jalr, 1'b1);
    tb_check64("clear keeps pc", pc, 64'h0000_0000_8000_3000);
    tb_check_inst("clear keeps inst", inst, 32'h0002_8067);
    tb_check5("clear keeps rs1", rs1, 5'd5);
    tb_check64("clear keeps imm", imm, 64'h0000_0000_0000_0020);
    tb_check64("clear clears next_pc", next_pc, {`XLEN{1'b0}});
    tb_check64("clear keeps target", target, 64'h0000_0000_8000_4020);

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b0;
    capture_lane1_jalr = 1'b0;
    capture_lane1_pc = 64'h0000_0000_8000_5002;
    capture_lane1_next_pc = 64'h0000_0000_8000_5006;
    capture_lane1_inst = 32'h0000_006f;
    capture_lane1_rs1 = 5'd0;
    capture_lane1_imm = 64'h0000_0000_0000_0040;
    tick();
    tb_check1("non-jump lane1 capture valid", valid, 1'b0);
    tb_check1("non-jump lane1 capture jalr", jalr, 1'b0);
    tb_check64("non-jump lane1 capture pc", pc, 64'h0000_0000_8000_5002);
    tb_check64("non-jump lane1 capture next_pc", next_pc,
               64'h0000_0000_8000_5006);
    tb_check_inst("non-jump lane1 capture inst", inst, 32'h0000_006f);
    tb_check5("non-jump lane1 capture rs1", rs1, 5'd0);
    tb_check64("non-jump lane1 capture imm", imm,
               64'h0000_0000_0000_0040);
    tb_check64("non-jump lane1 clears target", target, {`XLEN{1'b0}});

    clear_inputs();
    dispatch_fire = 1'b1;
    dispatch_target = 64'h0000_0000_8000_6000;
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b1;
    capture_lane1_jalr = 1'b1;
    capture_lane1_pc = 64'h0000_0000_8000_6002;
    capture_lane1_next_pc = 64'h0000_0000_8000_6006;
    capture_lane1_inst = 32'h0003_0067;
    capture_lane1_rs1 = 5'd6;
    capture_lane1_imm = 64'h0000_0000_0000_0060;
    tick();
    tb_check1("lane1 capture over dispatch valid", valid, 1'b1);
    tb_check1("lane1 capture over dispatch dispatched", dispatched, 1'b0);
    tb_check1("lane1 capture over dispatch jalr", jalr, 1'b1);
    tb_check64("lane1 capture over dispatch pc", pc,
               64'h0000_0000_8000_6002);
    tb_check64("lane1 capture over dispatch target", target, {`XLEN{1'b0}});

    clear_inputs();
    clear = 1'b1;
    capture_head0 = 1'b1;
    capture_head0_jalr = 1'b0;
    capture_head0_pc = 64'h0000_0000_8000_7000;
    capture_head0_next_pc = 64'h0000_0000_8000_7004;
    capture_head0_inst = 32'h0000_806f;
    capture_head0_rs1 = 5'd1;
    capture_head0_imm = 64'h0000_0000_0000_0080;
    tick();
    tb_check1("head0 capture over clear valid", valid, 1'b1);
    tb_check1("head0 capture over clear dispatched", dispatched, 1'b0);
    tb_check1("head0 capture over clear jalr", jalr, 1'b0);
    tb_check64("head0 capture over clear pc", pc,
               64'h0000_0000_8000_7000);

    clear_inputs();
    late_clear = 1'b1;
    capture_head0 = 1'b1;
    capture_head0_jalr = 1'b1;
    capture_head0_pc = 64'h0000_0000_8000_8000;
    capture_head0_next_pc = 64'h0000_0000_8000_8004;
    capture_head0_inst = 32'h0004_0067;
    capture_head0_rs1 = 5'd8;
    capture_head0_imm = 64'h0000_0000_0000_00a0;
    tick();
    tb_check1("late clear over capture valid", valid, 1'b0);
    tb_check1("late clear over capture dispatched", dispatched, 1'b0);
    tb_check64("late clear keeps previous pc", pc, 64'h0000_0000_8000_7000);
    tb_check64("late clear clears next_pc", next_pc, {`XLEN{1'b0}});

    if (errors == 0) begin
      $display("PASS tb_ooo_pending_jump_sequencer");
      $finish;
    end
    $display("FAIL tb_ooo_pending_jump_sequencer errors=%0d", errors);
    $finish;
  end

endmodule
