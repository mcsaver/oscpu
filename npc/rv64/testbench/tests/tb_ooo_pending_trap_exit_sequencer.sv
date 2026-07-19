`include "include/define.v"

module tb_ooo_pending_trap_exit_sequencer;
  reg clk;
  reg rst;
  reg late_clear_i;
  reg clear_exit_i;
  reg clear_arch_i;
  reg clear_arch_squash_i;
  reg capture_exit_i;
  reg capture_exit_valid_i;
  reg capture_exit_is_ecall_i;
  reg capture_exit_is_ebreak_i;
  reg capture_arch_i;
  reg capture_arch_valid_i;
  reg [`TRAP_CAUSE_W-1:0] capture_trap_cause_i;
  reg [`XLEN-1:0] capture_trap_pc_i;
  reg [`XLEN-1:0] capture_trap_tval_i;

  wire pending_exit_o;
  wire pending_exit_is_ecall_o;
  wire pending_exit_is_ebreak_o;
  wire pending_arch_trap_o;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_cause_o;
  wire [`XLEN-1:0] pending_trap_pc_o;
  wire [`XLEN-1:0] pending_trap_tval_o;

  OooPendingTrapExitSequencer dut (
    .clk(clk),
    .rst(rst),
    .late_clear_i(late_clear_i),
    .clear_exit_i(clear_exit_i),
    .clear_arch_i(clear_arch_i),
    .clear_arch_squash_i(clear_arch_squash_i),
    .capture_exit_i(capture_exit_i),
    .capture_exit_valid_i(capture_exit_valid_i),
    .capture_exit_is_ecall_i(capture_exit_is_ecall_i),
    .capture_exit_is_ebreak_i(capture_exit_is_ebreak_i),
    .capture_arch_i(capture_arch_i),
    .capture_arch_valid_i(capture_arch_valid_i),
    .capture_trap_cause_i(capture_trap_cause_i),
    .capture_trap_pc_i(capture_trap_pc_i),
    .capture_trap_tval_i(capture_trap_tval_i),
    .pending_exit_o(pending_exit_o),
    .pending_exit_is_ecall_o(pending_exit_is_ecall_o),
    .pending_exit_is_ebreak_o(pending_exit_is_ebreak_o),
    .pending_arch_trap_o(pending_arch_trap_o),
    .pending_trap_cause_o(pending_trap_cause_o),
    .pending_trap_pc_o(pending_trap_pc_o),
    .pending_trap_tval_o(pending_trap_tval_o)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task tick;
    begin
      @(negedge clk);
      @(posedge clk);
      #1;
    end
  endtask

  task clear_inputs;
    begin
      late_clear_i = 1'b0;
      clear_exit_i = 1'b0;
      clear_arch_i = 1'b0;
      clear_arch_squash_i = 1'b0;
      capture_exit_i = 1'b0;
      capture_exit_valid_i = 1'b0;
      capture_exit_is_ecall_i = 1'b0;
      capture_exit_is_ebreak_i = 1'b0;
      capture_arch_i = 1'b0;
      capture_arch_valid_i = 1'b0;
      capture_trap_cause_i = {`TRAP_CAUSE_W{1'b0}};
      capture_trap_pc_i = {`XLEN{1'b0}};
      capture_trap_tval_i = {`XLEN{1'b0}};
    end
  endtask

  task expect_state;
    input exp_exit;
    input exp_ecall;
    input exp_ebreak;
    input exp_arch;
    input [`TRAP_CAUSE_W-1:0] exp_cause;
    input [`XLEN-1:0] exp_pc;
    input [`XLEN-1:0] exp_tval;
    begin
      if (pending_exit_o !== exp_exit ||
          pending_exit_is_ecall_o !== exp_ecall ||
          pending_exit_is_ebreak_o !== exp_ebreak ||
          pending_arch_trap_o !== exp_arch ||
          pending_trap_cause_o !== exp_cause ||
          pending_trap_pc_o !== exp_pc ||
          pending_trap_tval_o !== exp_tval) begin
        $display("FAIL state exit=%0b/%0b/%0b arch=%0b cause=%0h pc=%0h tval=%0h",
                 pending_exit_o, pending_exit_is_ecall_o,
                 pending_exit_is_ebreak_o, pending_arch_trap_o,
                 pending_trap_cause_o, pending_trap_pc_o,
                 pending_trap_tval_o);
        $finish;
      end
    end
  endtask

  initial begin
    clear_inputs();
    rst = 1'b1;
    tick();
    expect_state(1'b0, 1'b0, 1'b0, 1'b0, {`TRAP_CAUSE_W{1'b0}},
                 {`XLEN{1'b0}}, {`XLEN{1'b0}});

    rst = 1'b0;
    capture_arch_i = 1'b1;
    capture_arch_valid_i = 1'b1;
    capture_trap_cause_i = `EXC_ILLEGAL_INST;
    capture_trap_pc_i = 64'h8000_1234;
    capture_trap_tval_i = 64'h0000_0013;
    tick();
    expect_state(1'b0, 1'b0, 1'b0, 1'b1, `EXC_ILLEGAL_INST,
                 64'h8000_1234, 64'h0000_0013);

    clear_inputs();
    clear_arch_i = 1'b1;
    tick();
    expect_state(1'b0, 1'b0, 1'b0, 1'b0, `EXC_ILLEGAL_INST,
                 64'h8000_1234, 64'h0000_0013);

    clear_inputs();
    capture_exit_i = 1'b1;
    capture_exit_valid_i = 1'b1;
    capture_exit_is_ebreak_i = 1'b1;
    tick();
    expect_state(1'b1, 1'b0, 1'b1, 1'b0, `EXC_ILLEGAL_INST,
                 64'h8000_1234, 64'h0000_0013);

    clear_inputs();
    clear_exit_i = 1'b1;
    capture_exit_i = 1'b1;
    capture_exit_valid_i = 1'b1;
    capture_exit_is_ecall_i = 1'b1;
    tick();
    expect_state(1'b1, 1'b1, 1'b0, 1'b0, `EXC_ILLEGAL_INST,
                 64'h8000_1234, 64'h0000_0013);

    clear_inputs();
    capture_arch_i = 1'b1;
    capture_arch_valid_i = 1'b1;
    capture_trap_cause_i = `EXC_BREAKPOINT;
    capture_trap_pc_i = 64'h8000_2000;
    capture_trap_tval_i = 64'h0;
    tick();
    expect_state(1'b1, 1'b1, 1'b0, 1'b1, `EXC_BREAKPOINT,
                 64'h8000_2000, 64'h0);

    clear_inputs();
    clear_exit_i = 1'b1;
    capture_exit_i = 1'b1;
    capture_exit_valid_i = 1'b0;
    capture_exit_is_ecall_i = 1'b1;
    capture_arch_i = 1'b1;
    capture_arch_valid_i = 1'b0;
    capture_trap_cause_i = `EXC_INST_ACCESS_FAULT;
    capture_trap_pc_i = 64'h8000_3000;
    capture_trap_tval_i = 64'h8000_3000;
    tick();
    expect_state(1'b0, 1'b1, 1'b0, 1'b0, `EXC_INST_ACCESS_FAULT,
                 64'h8000_3000, 64'h8000_3000);

    // A redirect/squash and the wrong-path head trap can be observed in the
    // same cycle.  Squash owns the younger payload: capture must not revive
    // an orphan pending trap after the stop sequencer has already cleared.
    clear_inputs();
    clear_arch_i = 1'b1;
    clear_arch_squash_i = 1'b1;
    capture_arch_i = 1'b1;
    capture_arch_valid_i = 1'b1;
    capture_trap_cause_i = `EXC_ILLEGAL_INST;
    capture_trap_pc_i = 64'h8000_031c;
    capture_trap_tval_i = 64'hc000_1073;
    tick();
    expect_state(1'b0, 1'b1, 1'b0, 1'b0, {`TRAP_CAUSE_W{1'b0}},
                 {`XLEN{1'b0}}, {`XLEN{1'b0}});

    clear_inputs();
    capture_exit_i = 1'b1;
    capture_exit_valid_i = 1'b1;
    capture_exit_is_ebreak_i = 1'b1;
    capture_arch_i = 1'b1;
    capture_arch_valid_i = 1'b1;
    capture_trap_cause_i = `EXC_ILLEGAL_INST;
    capture_trap_pc_i = 64'h8000_4000;
    capture_trap_tval_i = 64'hdead_beef;
    late_clear_i = 1'b1;
    tick();
    expect_state(1'b0, 1'b0, 1'b0, 1'b0, {`TRAP_CAUSE_W{1'b0}},
                 {`XLEN{1'b0}}, {`XLEN{1'b0}});

    $display("PASS tb_ooo_pending_trap_exit_sequencer");
    $finish;
  end
endmodule
