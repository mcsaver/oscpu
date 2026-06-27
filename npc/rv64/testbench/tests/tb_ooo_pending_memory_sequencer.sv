`timescale 1ns/1ps
`include "define.v"

module tb_ooo_pending_memory_sequencer;
  reg clk;
  reg rst;
  reg late_clear;
  reg clear;
  reg clear_dispatched;
  reg dispatch_fire;
  reg capture_lane1;
  reg capture_valid;
  reg [`XLEN-1:0] capture_pc;
  reg [`INST_W-1:0] capture_inst;
  reg [`XLEN-1:0] capture_next_pc;

  wire valid;
  wire dispatched;
  wire [`XLEN-1:0] pc;
  wire [`INST_W-1:0] inst;
  wire [`XLEN-1:0] next_pc;

  integer errors;

  OooPendingMemorySequencer dut (
    .clk(clk),
    .rst(rst),
    .late_clear_i(late_clear),
    .clear_i(clear),
    .clear_dispatched_i(clear_dispatched),
    .dispatch_fire_i(dispatch_fire),
    .capture_lane1_i(capture_lane1),
    .capture_valid_i(capture_valid),
    .capture_pc_i(capture_pc),
    .capture_inst_i(capture_inst),
    .capture_next_pc_i(capture_next_pc),
    .valid_o(valid),
    .dispatched_o(dispatched),
    .pc_o(pc),
    .inst_o(inst),
    .next_pc_o(next_pc)
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
      capture_lane1 = 1'b0;
      capture_valid = 1'b0;
      capture_pc = 64'h0000_0000_8000_1000;
      capture_inst = 32'h0000_3023;
      capture_next_pc = 64'h0000_0000_8000_1004;
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
    tb_check_inst("reset inst", inst, {`INST_W{1'b0}});
    tb_check64("reset next_pc", next_pc, {`XLEN{1'b0}});

    rst = 1'b0;
    clear_inputs();
    capture_lane1 = 1'b1;
    capture_valid = 1'b1;
    capture_pc = 64'h0000_0000_8000_2002;
    capture_inst = 32'h00a1_3023;
    capture_next_pc = 64'h0000_0000_8000_2006;
    tick();
    tb_check1("capture valid", valid, 1'b1);
    tb_check1("capture clears dispatched", dispatched, 1'b0);
    tb_check64("capture pc", pc, 64'h0000_0000_8000_2002);
    tb_check_inst("capture inst", inst, 32'h00a1_3023);
    tb_check64("capture next_pc", next_pc, 64'h0000_0000_8000_2006);

    clear_inputs();
    dispatch_fire = 1'b1;
    tick();
    tb_check1("dispatch marks dispatched", dispatched, 1'b1);
    tb_check1("dispatch keeps valid", valid, 1'b1);

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
    tb_check64("clear keeps pc", pc, 64'h0000_0000_8000_2002);
    tb_check_inst("clear keeps inst", inst, 32'h00a1_3023);
    tb_check64("clear clears next_pc", next_pc, {`XLEN{1'b0}});

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_valid = 1'b0;
    capture_pc = 64'h0000_0000_8000_3002;
    capture_inst = 32'h0000_2023;
    capture_next_pc = 64'h0000_0000_8000_3006;
    tick();
    tb_check1("non-mem capture valid", valid, 1'b0);
    tb_check64("non-mem capture pc", pc, 64'h0000_0000_8000_3002);
    tb_check_inst("non-mem capture inst", inst, 32'h0000_2023);
    tb_check64("non-mem capture next_pc", next_pc, 64'h0000_0000_8000_3006);

    clear_inputs();
    dispatch_fire = 1'b1;
    capture_lane1 = 1'b1;
    capture_valid = 1'b1;
    capture_pc = 64'h0000_0000_8000_4002;
    capture_inst = 32'h00b1_b023;
    capture_next_pc = 64'h0000_0000_8000_4006;
    tick();
    tb_check1("capture over dispatch valid", valid, 1'b1);
    tb_check1("capture over dispatch dispatched", dispatched, 1'b0);
    tb_check64("capture over dispatch pc", pc, 64'h0000_0000_8000_4002);

    clear_inputs();
    late_clear = 1'b1;
    capture_lane1 = 1'b1;
    capture_valid = 1'b1;
    capture_pc = 64'h0000_0000_8000_5002;
    capture_inst = 32'h00c1_b023;
    capture_next_pc = 64'h0000_0000_8000_5006;
    tick();
    tb_check1("late clear over capture valid", valid, 1'b0);
    tb_check1("late clear over capture dispatched", dispatched, 1'b0);
    tb_check64("late clear keeps previous pc", pc, 64'h0000_0000_8000_4002);
    tb_check64("late clear clears next_pc", next_pc, {`XLEN{1'b0}});

    if (errors == 0) begin
      $display("PASS tb_ooo_pending_memory_sequencer");
      $finish;
    end
    $display("FAIL tb_ooo_pending_memory_sequencer errors=%0d", errors);
    $finish;
  end

endmodule
