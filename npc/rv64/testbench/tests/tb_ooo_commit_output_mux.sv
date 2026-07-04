`timescale 1ns/1ps
`include "define.v"

module tb_ooo_commit_output_mux;
  reg ctrl_commit_valid;
  reg [`XLEN-1:0] ctrl_commit_pc;
  reg [`INST_W-1:0] ctrl_commit_inst;
  reg [`XLEN-1:0] ctrl_commit_next_pc;
  reg ctrl_commit_rd_en;
  reg [`REG_ADDR_W-1:0] ctrl_commit_rd_addr;
  reg [`XLEN-1:0] ctrl_commit_rd_data;
  reg ctrl_commit_write;

  reg synth_lane1_branch_append;
  reg [`XLEN-1:0] synth_branch_append_pc;
  reg [`INST_W-1:0] synth_branch_append_inst;
  reg [`XLEN-1:0] synth_branch_append_next_pc;

  reg core_commit0_valid;
  reg [`XLEN-1:0] core_commit0_pc;
  reg [`XLEN-1:0] core_commit0_next_pc;
  reg [`INST_W-1:0] core_commit0_inst;
  reg core_commit0_rd_en;
  reg [`REG_ADDR_W-1:0] core_commit0_rd_addr;
  reg [`XLEN-1:0] core_commit0_rd_data;
  reg core_commit0_exception;
  reg core_commit0_write;

  reg core_commit1_valid;
  reg [`XLEN-1:0] core_commit1_pc;
  reg [`XLEN-1:0] core_commit1_next_pc;
  reg [`INST_W-1:0] core_commit1_inst;
  reg core_commit1_rd_en;
  reg [`REG_ADDR_W-1:0] core_commit1_rd_addr;
  reg [`XLEN-1:0] core_commit1_rd_data;
  reg core_commit1_exception;
  reg core_commit1_write;

  reg [1:0] core_retire_count;

  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire [`XLEN-1:0] commit0_next_pc;
  wire commit0_rd_en;
  wire [`REG_ADDR_W-1:0] commit0_rd_addr;
  wire [`XLEN-1:0] commit0_rd_data;
  wire commit0_exception;
  wire commit0_write;

  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire [`XLEN-1:0] commit1_next_pc;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_rd_addr;
  wire [`XLEN-1:0] commit1_rd_data;
  wire commit1_exception;
  wire commit1_write;
  wire [1:0] retire_count;

  integer errors;

  OooCommitOutputMux dut (
    .ctrl_commit_valid_i(ctrl_commit_valid),
    .ctrl_commit_pc_i(ctrl_commit_pc),
    .ctrl_commit_inst_i(ctrl_commit_inst),
    .ctrl_commit_next_pc_i(ctrl_commit_next_pc),
    .ctrl_commit_rd_en_i(ctrl_commit_rd_en),
    .ctrl_commit_rd_addr_i(ctrl_commit_rd_addr),
    .ctrl_commit_rd_data_i(ctrl_commit_rd_data),
    .ctrl_commit_write_i(ctrl_commit_write),
    .synth_lane1_branch_append_i(synth_lane1_branch_append),
    .synth_branch_append_pc_i(synth_branch_append_pc),
    .synth_branch_append_inst_i(synth_branch_append_inst),
    .synth_branch_append_next_pc_i(synth_branch_append_next_pc),
    .core_commit0_valid_i(core_commit0_valid),
    .core_commit0_pc_i(core_commit0_pc),
    .core_commit0_next_pc_i(core_commit0_next_pc),
    .core_commit0_inst_i(core_commit0_inst),
    .core_commit0_rd_en_i(core_commit0_rd_en),
    .core_commit0_rd_addr_i(core_commit0_rd_addr),
    .core_commit0_rd_data_i(core_commit0_rd_data),
    .core_commit0_exception_i(core_commit0_exception),
    .core_commit0_write_i(core_commit0_write),
    .core_commit1_valid_i(core_commit1_valid),
    .core_commit1_pc_i(core_commit1_pc),
    .core_commit1_next_pc_i(core_commit1_next_pc),
    .core_commit1_inst_i(core_commit1_inst),
    .core_commit1_rd_en_i(core_commit1_rd_en),
    .core_commit1_rd_addr_i(core_commit1_rd_addr),
    .core_commit1_rd_data_i(core_commit1_rd_data),
    .core_commit1_exception_i(core_commit1_exception),
    .core_commit1_write_i(core_commit1_write),
    .core_retire_count_i(core_retire_count),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_rd_addr_o(commit0_rd_addr),
    .commit0_rd_data_o(commit0_rd_data),
    .commit0_exception_o(commit0_exception),
    .commit0_write_o(commit0_write),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_rd_addr_o(commit1_rd_addr),
    .commit1_rd_data_o(commit1_rd_data),
    .commit1_exception_o(commit1_exception),
    .commit1_write_o(commit1_write),
    .retire_count_o(retire_count)
  );

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

  task automatic tb_check2;
    input [255:0] name;
    input [1:0] actual;
    input [1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%0d expected=%0d", name, actual, expected);
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
        $display("FAIL %0s actual=%0d expected=%0d", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check32;
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

  task automatic tb_check64;
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

  task automatic clear_inputs;
    begin
      ctrl_commit_valid = 1'b0;
      ctrl_commit_pc = 64'h8000_1000;
      ctrl_commit_inst = 32'h3020_0073;
      ctrl_commit_next_pc = 64'h8000_2000;
      ctrl_commit_rd_en = 1'b1;
      ctrl_commit_rd_addr = 5'd11;
      ctrl_commit_rd_data = 64'h1111_2222_3333_4444;
      ctrl_commit_write = 1'b1;

      synth_lane1_branch_append = 1'b0;
      synth_branch_append_pc = 64'h8000_3000;
      synth_branch_append_inst = 32'h0000_0063;
      synth_branch_append_next_pc = 64'h8000_3100;

      core_commit0_valid = 1'b1;
      core_commit0_pc = 64'h8000_0000;
      core_commit0_next_pc = 64'h8000_0004;
      core_commit0_inst = 32'h0010_0093;
      core_commit0_rd_en = 1'b1;
      core_commit0_rd_addr = 5'd1;
      core_commit0_rd_data = 64'haaaa_0000_0000_0001;
      core_commit0_exception = 1'b0;
      core_commit0_write = 1'b1;

      core_commit1_valid = 1'b1;
      core_commit1_pc = 64'h8000_0004;
      core_commit1_next_pc = 64'h8000_0008;
      core_commit1_inst = 32'h0020_0113;
      core_commit1_rd_en = 1'b1;
      core_commit1_rd_addr = 5'd2;
      core_commit1_rd_data = 64'hbbbb_0000_0000_0002;
      core_commit1_exception = 1'b0;
      core_commit1_write = 1'b1;

      core_retire_count = 2'd2;
    end
  endtask

  task automatic expect_commit0_core0;
    input [255:0] name;
    input [`XLEN-1:0] expected_next_pc;
    begin
      tb_check1({name, " c0 valid"}, commit0_valid, core_commit0_valid);
      tb_check64({name, " c0 pc"}, commit0_pc, core_commit0_pc);
      tb_check32({name, " c0 inst"}, commit0_inst, core_commit0_inst);
      tb_check64({name, " c0 next"}, commit0_next_pc, expected_next_pc);
      tb_check1({name, " c0 rd_en"}, commit0_rd_en, core_commit0_rd_en);
      tb_check5({name, " c0 rd"}, commit0_rd_addr, core_commit0_rd_addr);
      tb_check64({name, " c0 data"}, commit0_rd_data, core_commit0_rd_data);
      tb_check1({name, " c0 exc"}, commit0_exception, core_commit0_exception);
      tb_check1({name, " c0 write"}, commit0_write, core_commit0_write);
    end
  endtask

  task automatic expect_commit1_core1;
    input [255:0] name;
    input [`XLEN-1:0] expected_next_pc;
    begin
      tb_check1({name, " c1 valid"}, commit1_valid, core_commit1_valid);
      tb_check64({name, " c1 pc"}, commit1_pc, core_commit1_pc);
      tb_check32({name, " c1 inst"}, commit1_inst, core_commit1_inst);
      tb_check64({name, " c1 next"}, commit1_next_pc, expected_next_pc);
      tb_check1({name, " c1 rd_en"}, commit1_rd_en, core_commit1_rd_en);
      tb_check5({name, " c1 rd"}, commit1_rd_addr, core_commit1_rd_addr);
      tb_check64({name, " c1 data"}, commit1_rd_data, core_commit1_rd_data);
      tb_check1({name, " c1 exc"}, commit1_exception, core_commit1_exception);
      tb_check1({name, " c1 write"}, commit1_write, core_commit1_write);
    end
  endtask

  task automatic expect_commit1_zero_side_effects;
    input [255:0] name;
    begin
      tb_check1({name, " c1 rd_en"}, commit1_rd_en, 1'b0);
      tb_check5({name, " c1 rd"}, commit1_rd_addr, {`REG_ADDR_W{1'b0}});
      tb_check64({name, " c1 data"}, commit1_rd_data, {`XLEN{1'b0}});
      tb_check1({name, " c1 exc"}, commit1_exception, 1'b0);
      tb_check1({name, " c1 write"}, commit1_write, 1'b0);
    end
  endtask

  initial begin
    errors = 0;

    clear_inputs();
    #1;
    expect_commit0_core0("baseline", 64'h8000_0004);
    expect_commit1_core1("baseline", 64'h8000_0008);
    tb_check2("baseline retire", retire_count, 2'd2);

    clear_inputs();
    core_commit0_inst = 32'h0080_006f;
    core_commit1_inst = 32'h0080_00ef;
    #1;
    expect_commit0_core0("jal c0", 64'h8000_0008);
    expect_commit1_core1("jal c1", 64'h8000_000c);

    clear_inputs();
    ctrl_commit_valid = 1'b1;
    core_retire_count = 2'd0;
    #1;
    tb_check1("ctrl c0 valid", commit0_valid, 1'b1);
    tb_check64("ctrl c0 pc", commit0_pc, ctrl_commit_pc);
    tb_check32("ctrl c0 inst", commit0_inst, ctrl_commit_inst);
    tb_check64("ctrl c0 next", commit0_next_pc, ctrl_commit_next_pc);
    tb_check1("ctrl c0 rd_en", commit0_rd_en, ctrl_commit_rd_en);
    tb_check5("ctrl c0 rd", commit0_rd_addr, ctrl_commit_rd_addr);
    tb_check64("ctrl c0 data", commit0_rd_data, ctrl_commit_rd_data);
    tb_check1("ctrl c0 exc", commit0_exception, 1'b0);
    tb_check1("ctrl c0 write", commit0_write, ctrl_commit_write);
    tb_check1("ctrl c1 valid", commit1_valid, 1'b0);
    tb_check64("ctrl c1 pc", commit1_pc, {`XLEN{1'b0}});
    expect_commit1_zero_side_effects("ctrl");
    tb_check2("ctrl retire", retire_count, 2'd1);

    clear_inputs();
    synth_lane1_branch_append = 1'b1;
    core_retire_count = 2'd1;
    #1;
    expect_commit0_core0("branch append", 64'h8000_0004);
    tb_check1("branch append c1 valid", commit1_valid, 1'b1);
    tb_check64("branch append c1 pc", commit1_pc, synth_branch_append_pc);
    tb_check32("branch append c1 inst", commit1_inst,
               synth_branch_append_inst);
    tb_check64("branch append c1 next", commit1_next_pc,
               synth_branch_append_next_pc);
    expect_commit1_zero_side_effects("branch append");
    tb_check2("branch append retire", retire_count, 2'd2);

    clear_inputs();
    ctrl_commit_valid = 1'b1;
    synth_lane1_branch_append = 1'b1;
    core_retire_count = 2'd0;
    #1;
    tb_check64("ctrl priority c0 pc", commit0_pc, ctrl_commit_pc);
    tb_check1("ctrl priority c1 valid", commit1_valid, 1'b0);
    tb_check2("ctrl priority retire", retire_count, 2'd2);

    if (errors == 0) begin
      $display("PASS tb_ooo_commit_output_mux");
      $finish;
    end

    $display("FAIL tb_ooo_commit_output_mux errors=%0d", errors);
    $fatal(1);
  end
endmodule
