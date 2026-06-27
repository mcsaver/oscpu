`timescale 1ns/1ps
`include "define.v"

module tb_ooo_synthetic_lane1_ret_sequencer;
  reg clk;
  reg rst;
  reg ret_commit;
  reg branch_drop_match;
  reg branch_commit1;
  reg capture;
  reg capture_branch_seen;
  reg capture_branch_drop;
  reg [`XLEN-1:0] capture_branch_pc;
  reg [`XLEN-1:0] capture_ret_pc;
  reg [`XLEN-1:0] capture_ret_next_pc;
  reg [`INST_W-1:0] capture_ret_inst;
  reg satp_clear;
  reg trap_clear;

  wire ret_pending;
  wire ret_branch_seen;
  wire [`XLEN-1:0] ret_branch_pc;
  wire [`XLEN-1:0] ret_pc;
  wire [`XLEN-1:0] ret_next_pc;
  wire [`INST_W-1:0] ret_inst;
  wire branch_drop_pending;
  wire [`XLEN-1:0] branch_drop_pc;

  integer errors;

  OooSyntheticLane1RetSequencer dut (
    .clk(clk),
    .rst(rst),
    .ret_commit_i(ret_commit),
    .branch_drop_match_i(branch_drop_match),
    .branch_commit1_i(branch_commit1),
    .capture_i(capture),
    .capture_branch_seen_i(capture_branch_seen),
    .capture_branch_drop_i(capture_branch_drop),
    .capture_branch_pc_i(capture_branch_pc),
    .capture_ret_pc_i(capture_ret_pc),
    .capture_ret_next_pc_i(capture_ret_next_pc),
    .capture_ret_inst_i(capture_ret_inst),
    .satp_clear_i(satp_clear),
    .trap_clear_i(trap_clear),
    .ret_pending_o(ret_pending),
    .ret_branch_seen_o(ret_branch_seen),
    .ret_branch_pc_o(ret_branch_pc),
    .ret_pc_o(ret_pc),
    .ret_next_pc_o(ret_next_pc),
    .ret_inst_o(ret_inst),
    .branch_drop_pending_o(branch_drop_pending),
    .branch_drop_pc_o(branch_drop_pc)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic check1;
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

  task automatic check64;
    input [255:0] name;
    input [`XLEN-1:0] actual;
    input [`XLEN-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%h expected=%h", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic check32;
    input [255:0] name;
    input [`INST_W-1:0] actual;
    input [`INST_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%h expected=%h", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      ret_commit = 1'b0;
      branch_drop_match = 1'b0;
      branch_commit1 = 1'b0;
      capture = 1'b0;
      capture_branch_seen = 1'b0;
      capture_branch_drop = 1'b0;
      capture_branch_pc = 64'h8000_1000;
      capture_ret_pc = 64'h8000_1004;
      capture_ret_next_pc = 64'h8000_2000;
      capture_ret_inst = 32'h0000_8067;
      satp_clear = 1'b0;
      trap_clear = 1'b0;
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic expect_idle;
    input [255:0] name;
    begin
      check1({name, " pending"}, ret_pending, 1'b0);
      check1({name, " seen"}, ret_branch_seen, 1'b0);
      check64({name, " branch_pc"}, ret_branch_pc, {`XLEN{1'b0}});
      check64({name, " ret_pc"}, ret_pc, {`XLEN{1'b0}});
      check64({name, " ret_next"}, ret_next_pc, {`XLEN{1'b0}});
      check32({name, " inst"}, ret_inst, {`INST_W{1'b0}});
      check1({name, " drop"}, branch_drop_pending, 1'b0);
      check64({name, " drop_pc"}, branch_drop_pc, {`XLEN{1'b0}});
    end
  endtask

  task automatic capture_ret;
    input seen;
    input drop;
    input [`XLEN-1:0] branch_pc;
    input [`XLEN-1:0] lane1_pc;
    input [`XLEN-1:0] lane1_next_pc;
    input [`INST_W-1:0] lane1_inst;
    begin
      clear_inputs();
      capture = 1'b1;
      capture_branch_seen = seen;
      capture_branch_drop = drop;
      capture_branch_pc = branch_pc;
      capture_ret_pc = lane1_pc;
      capture_ret_next_pc = lane1_next_pc;
      capture_ret_inst = lane1_inst;
      tick();
      clear_inputs();
    end
  endtask

  initial begin
    errors = 0;
    clear_inputs();
    rst = 1'b1;
    repeat (2) tick();
    rst = 1'b0;
    tick();
    expect_idle("reset");

    capture_ret(1'b0, 1'b0, 64'h8000_0100, 64'h8000_0104,
                64'h8000_0800, 32'h0000_8067);
    check1("capture pending", ret_pending, 1'b1);
    check1("capture branch unseen", ret_branch_seen, 1'b0);
    check64("capture branch pc", ret_branch_pc, 64'h8000_0100);
    check64("capture ret pc", ret_pc, 64'h8000_0104);
    check64("capture ret next", ret_next_pc, 64'h8000_0800);
    check32("capture ret inst", ret_inst, 32'h0000_8067);
    check1("capture no drop", branch_drop_pending, 1'b0);

    branch_commit1 = 1'b1;
    tick();
    clear_inputs();
    check1("branch commit marks seen", ret_branch_seen, 1'b1);
    check1("branch commit keeps pending", ret_pending, 1'b1);

    ret_commit = 1'b1;
    tick();
    clear_inputs();
    expect_idle("ret commit clears");

    capture_ret(1'b1, 1'b1, 64'h8000_0200, 64'h8000_0204,
                64'h8000_0900, 32'h0000_8067);
    check1("drop capture pending", ret_pending, 1'b1);
    check1("drop capture seen", ret_branch_seen, 1'b1);
    check1("drop capture branch drop", branch_drop_pending, 1'b1);
    check64("drop capture pc", branch_drop_pc, 64'h8000_0200);

    branch_drop_match = 1'b1;
    tick();
    clear_inputs();
    check1("drop match clears only drop", branch_drop_pending, 1'b0);
    check1("drop match keeps ret", ret_pending, 1'b1);
    check1("drop match keeps seen", ret_branch_seen, 1'b1);

    ret_commit = 1'b1;
    capture = 1'b1;
    capture_branch_pc = 64'h8000_0300;
    capture_ret_pc = 64'h8000_0304;
    capture_ret_next_pc = 64'h8000_0a00;
    capture_ret_inst = 32'h0000_8067;
    tick();
    clear_inputs();
    check1("capture overrides commit pending", ret_pending, 1'b1);
    check64("capture overrides commit pc", ret_pc, 64'h8000_0304);

    satp_clear = 1'b1;
    tick();
    clear_inputs();
    expect_idle("satp clear");

    capture_ret(1'b1, 1'b1, 64'h8000_0400, 64'h8000_0404,
                64'h8000_0b00, 32'h0000_8067);
    branch_commit1 = 1'b1;
    branch_drop_match = 1'b1;
    tick();
    clear_inputs();
    check1("drop match priority clears drop", branch_drop_pending, 1'b0);
    check1("drop match priority keeps seen", ret_branch_seen, 1'b1);

    capture = 1'b1;
    satp_clear = 1'b1;
    trap_clear = 1'b1;
    capture_branch_pc = 64'h8000_0500;
    capture_ret_pc = 64'h8000_0504;
    capture_ret_next_pc = 64'h8000_0c00;
    tick();
    clear_inputs();
    expect_idle("trap clear wins");

    if (errors == 0) begin
      $display("PASS tb_ooo_synthetic_lane1_ret_sequencer");
      $finish;
    end
    $display("FAIL tb_ooo_synthetic_lane1_ret_sequencer errors=%0d", errors);
    $finish(1);
  end
endmodule
