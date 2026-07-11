`timescale 1ns/1ps
`include "define.v"

module tb_ooo_control_commit_sequencer;
  reg clk;
  reg rst;

  reg pending_jump_nolink_commit;
  reg [`XLEN-1:0] pending_jump_pc;
  reg [`INST_W-1:0] pending_jump_inst;
  reg [`XLEN-1:0] pending_jump_target;

  reg drain_complete;
  reg drain_pending_arch_trap;
  reg drain_pending_system;
  reg drain_pending_system_ecall;
  reg drain_pending_system_irq;
  reg drain_pending_system_mret;
  reg [`XLEN-1:0] pending_system_pc;
  reg [`INST_W-1:0] pending_system_inst;
  reg [`XLEN-1:0] pending_system_next_pc;
  reg [`XLEN-1:0] csr_ret_target;

  reg drain_pending_branch_undispatched;
  reg drain_pending_branch_misaligned;
  reg [`XLEN-1:0] pending_branch_pc;
  reg [`INST_W-1:0] pending_branch_inst;
  reg [`XLEN-1:0] pending_branch_next_pc;

  reg drain_pending_jump;
  reg drain_pending_mem;
  reg head0_csr_commit;


  wire ctrl_commit_valid;
  wire [`XLEN-1:0] ctrl_commit_pc;
  wire [`INST_W-1:0] ctrl_commit_inst;
  wire [`XLEN-1:0] ctrl_commit_next_pc;
  wire ctrl_commit_rd_en;
  wire [`REG_ADDR_W-1:0] ctrl_commit_rd_addr;
  wire [`XLEN-1:0] ctrl_commit_rd_data;
  wire ctrl_commit_write;
  wire core_serial_flush;

  integer errors;

  OooControlCommitSequencer dut (
    .clk(clk),
    .rst(rst),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit),
    .pending_jump_pc_i(pending_jump_pc),
    .pending_jump_inst_i(pending_jump_inst),
    .pending_jump_target_i(pending_jump_target),
    .drain_complete_i(drain_complete),
    .drain_pending_arch_trap_i(drain_pending_arch_trap),
    .drain_pending_system_i(drain_pending_system),
    .drain_pending_system_ecall_i(drain_pending_system_ecall),
    .drain_pending_system_irq_i(drain_pending_system_irq),
    .drain_pending_system_mret_i(drain_pending_system_mret),
    .pending_system_pc_i(pending_system_pc),
    .pending_system_inst_i(pending_system_inst),
    .pending_system_next_pc_i(pending_system_next_pc),
    .csr_ret_target_i(csr_ret_target),
    .drain_pending_branch_undispatched_i(
        drain_pending_branch_undispatched),
    .drain_pending_branch_misaligned_i(drain_pending_branch_misaligned),
    .pending_branch_pc_i(pending_branch_pc),
    .pending_branch_inst_i(pending_branch_inst),
    .pending_branch_next_pc_i(pending_branch_next_pc),
    .drain_pending_jump_i(drain_pending_jump),
    .drain_pending_mem_i(drain_pending_mem),
    .head0_csr_commit_i(head0_csr_commit),
    .ctrl_commit_valid_o(ctrl_commit_valid),
    .ctrl_commit_pc_o(ctrl_commit_pc),
    .ctrl_commit_inst_o(ctrl_commit_inst),
    .ctrl_commit_next_pc_o(ctrl_commit_next_pc),
    .ctrl_commit_rd_en_o(ctrl_commit_rd_en),
    .ctrl_commit_rd_addr_o(ctrl_commit_rd_addr),
    .ctrl_commit_rd_data_o(ctrl_commit_rd_data),
    .ctrl_commit_write_o(ctrl_commit_write),
    .core_serial_flush_o(core_serial_flush)
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
        $display("FAIL %0s actual=%h expected=%h", name, actual, expected);
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

  task automatic clear_inputs;
    begin
      pending_jump_nolink_commit = 1'b0;
      pending_jump_pc = 64'h8000_0000;
      pending_jump_inst = 32'h0000_006f;
      pending_jump_target = 64'h8000_0100;
      drain_complete = 1'b0;
      drain_pending_arch_trap = 1'b0;
      drain_pending_system = 1'b0;
      drain_pending_system_ecall = 1'b0;
      drain_pending_system_irq = 1'b0;
      drain_pending_system_mret = 1'b0;
      pending_system_pc = 64'h8000_0200;
      pending_system_inst = 32'h3020_0073;
      pending_system_next_pc = 64'h8000_0204;
      csr_ret_target = 64'h8020_0000;
      drain_pending_branch_undispatched = 1'b0;
      drain_pending_branch_misaligned = 1'b0;
      pending_branch_pc = 64'h8000_0300;
      pending_branch_inst = 32'h0000_0063;
      pending_branch_next_pc = 64'h8000_0400;
      drain_pending_jump = 1'b0;
      drain_pending_mem = 1'b0;
      head0_csr_commit = 1'b0;
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
      tb_check1({name, " valid"}, ctrl_commit_valid, 1'b0);
      tb_check1({name, " rd_en"}, ctrl_commit_rd_en, 1'b0);
      tb_check1({name, " write"}, ctrl_commit_write, 1'b0);
      tb_check1({name, " serial"}, core_serial_flush, 1'b0);
    end
  endtask

  initial begin
    errors = 0;
    clear_inputs();
    rst = 1'b1;
    repeat (2) tick();
    rst = 1'b0;
    tick();
    expect_idle("reset clears");

    clear_inputs();
    pending_jump_nolink_commit = 1'b1;
    pending_jump_pc = 64'h8000_1000;
    pending_jump_inst = 32'h0000_8067;
    pending_jump_target = 64'h8000_2220;
    tick();
    tb_check1("jump commit valid", ctrl_commit_valid, 1'b1);
    tb_check64("jump commit pc", ctrl_commit_pc, 64'h8000_1000);
    tb_check32("jump commit inst", ctrl_commit_inst, 32'h0000_8067);
    tb_check64("jump commit next", ctrl_commit_next_pc, 64'h8000_2220);
    tb_check1("jump no rd", ctrl_commit_rd_en, 1'b0);
    tb_check1("jump no serial", core_serial_flush, 1'b0);
    clear_inputs();
    tick();
    expect_idle("jump pulse clears");

    // 队头 CSR 提交只触发一拍串行化 flush，不伪造控制提交。
    clear_inputs();
    head0_csr_commit = 1'b1;
    tick();
    tb_check1("head0 csr serial pulse", core_serial_flush, 1'b1);
    tb_check1("head0 csr no pseudo commit", ctrl_commit_valid, 1'b0);
    clear_inputs();
    tick();
    expect_idle("head0 csr serial pulse clears");

    clear_inputs();
    drain_complete = 1'b1;
    drain_pending_system = 1'b1;
    drain_pending_system_mret = 1'b1;
    pending_system_pc = 64'h8000_2000;
    pending_system_inst = 32'h3020_0073;
    csr_ret_target = 64'h8020_0080;
    tick();
    tb_check1("mret commit valid", ctrl_commit_valid, 1'b1);
    tb_check64("mret commit pc", ctrl_commit_pc, 64'h8000_2000);
    tb_check32("mret commit inst", ctrl_commit_inst, 32'h3020_0073);
    tb_check64("mret commit next", ctrl_commit_next_pc, 64'h8020_0080);

    clear_inputs();
    drain_complete = 1'b1;
    drain_pending_system = 1'b1;
    pending_system_pc = 64'h8000_2100;
    pending_system_inst = 32'h1200_0073;
    pending_system_next_pc = 64'h8000_2104;
    tick();
    tb_check1("system control commit valid", ctrl_commit_valid, 1'b1);
    tb_check64("system control next", ctrl_commit_next_pc, 64'h8000_2104);

    clear_inputs();
    drain_complete = 1'b1;
    drain_pending_system = 1'b1;
    drain_pending_system_ecall = 1'b1;
    tick();
    expect_idle("ecall does not pseudo commit");

    clear_inputs();
    drain_complete = 1'b1;
    drain_pending_system = 1'b1;
    drain_pending_system_irq = 1'b1;
    tick();
    expect_idle("irq does not pseudo commit");

    clear_inputs();
    drain_complete = 1'b1;
    drain_pending_branch_undispatched = 1'b1;
    pending_branch_pc = 64'h8000_3000;
    pending_branch_inst = 32'h0005_0463;
    pending_branch_next_pc = 64'h8000_3080;
    tick();
    tb_check1("branch fallback commit valid", ctrl_commit_valid, 1'b1);
    tb_check64("branch fallback pc", ctrl_commit_pc, 64'h8000_3000);
    tb_check32("branch fallback inst", ctrl_commit_inst, 32'h0005_0463);
    tb_check64("branch fallback next", ctrl_commit_next_pc, 64'h8000_3080);

    clear_inputs();
    drain_complete = 1'b1;
    drain_pending_branch_undispatched = 1'b1;
    drain_pending_branch_misaligned = 1'b1;
    tick();
    expect_idle("misaligned branch does not pseudo commit");

    // 【B-FP 簇】pending-FP 壳已拆: drain_fp_commit 场景组删除
    // (arch-trap/jump/mem suppress×3 + fp gpr commit + fp x0 + jump 优先)。
    clear_inputs();
    pending_jump_nolink_commit = 1'b1;
    pending_jump_pc = 64'h8000_6000;
    pending_jump_inst = 32'h0000_006f;
    pending_jump_target = 64'h8000_6060;
    drain_complete = 1'b1;
    tick();
    tb_check1("jump priority valid", ctrl_commit_valid, 1'b1);
    tb_check64("jump priority pc", ctrl_commit_pc, 64'h8000_6000);
    tb_check1("jump priority no serial", core_serial_flush, 1'b0);

    if (errors == 0) begin
      $display("PASS tb_ooo_control_commit_sequencer");
      $finish;
    end
    $fatal(1, "FAIL tb_ooo_control_commit_sequencer errors=%0d", errors);
  end
endmodule
