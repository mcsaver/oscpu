`include "include/define.v"

module tb_ooo_trap_exit_output_sequencer;
  reg clk;
  reg rst;
  reg trap_i;
  reg [`TRAP_CAUSE_W-1:0] trap_cause_i;
  reg [`XLEN-1:0] trap_pc_i;
  reg [`XLEN-1:0] trap_tval_i;
  reg exit_i;
  reg exit_is_ecall_i;
  reg exit_is_ebreak_i;

  wire trap_valid_o;
  wire [`TRAP_CAUSE_W-1:0] trap_cause_o;
  wire [`XLEN-1:0] trap_pc_o;
  wire [`XLEN-1:0] trap_tval_o;
  wire exit_valid_o;
  wire exit_is_ecall_o;
  wire exit_is_ebreak_o;
  wire halted_o;

  OooTrapExitOutputSequencer dut (
    .clk(clk),
    .rst(rst),
    .trap_i(trap_i),
    .trap_cause_i(trap_cause_i),
    .trap_pc_i(trap_pc_i),
    .trap_tval_i(trap_tval_i),
    .exit_i(exit_i),
    .exit_is_ecall_i(exit_is_ecall_i),
    .exit_is_ebreak_i(exit_is_ebreak_i),
    .trap_valid_o(trap_valid_o),
    .trap_cause_o(trap_cause_o),
    .trap_pc_o(trap_pc_o),
    .trap_tval_o(trap_tval_o),
    .exit_valid_o(exit_valid_o),
    .exit_is_ecall_o(exit_is_ecall_o),
    .exit_is_ebreak_o(exit_is_ebreak_o),
    .halted_o(halted_o)
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
      trap_i = 1'b0;
      trap_cause_i = {`TRAP_CAUSE_W{1'b0}};
      trap_pc_i = {`XLEN{1'b0}};
      trap_tval_i = {`XLEN{1'b0}};
      exit_i = 1'b0;
      exit_is_ecall_i = 1'b0;
      exit_is_ebreak_i = 1'b0;
    end
  endtask

  task expect_state;
    input exp_trap;
    input [`TRAP_CAUSE_W-1:0] exp_cause;
    input [`XLEN-1:0] exp_pc;
    input [`XLEN-1:0] exp_tval;
    input exp_exit;
    input exp_ecall;
    input exp_ebreak;
    input exp_halted;
    begin
      if (trap_valid_o !== exp_trap ||
          trap_cause_o !== exp_cause ||
          trap_pc_o !== exp_pc ||
          trap_tval_o !== exp_tval ||
          exit_valid_o !== exp_exit ||
          exit_is_ecall_o !== exp_ecall ||
          exit_is_ebreak_o !== exp_ebreak ||
          halted_o !== exp_halted) begin
        $display("FAIL trap=%0b cause=%0h pc=%0h tval=%0h exit=%0b/%0b/%0b halted=%0b",
                 trap_valid_o, trap_cause_o, trap_pc_o, trap_tval_o,
                 exit_valid_o, exit_is_ecall_o, exit_is_ebreak_o, halted_o);
        $finish;
      end
    end
  endtask

  initial begin
    clear_inputs();
    rst = 1'b1;
    tick();
    expect_state(1'b0, {`TRAP_CAUSE_W{1'b0}}, {`XLEN{1'b0}},
                 {`XLEN{1'b0}}, 1'b0, 1'b0, 1'b0, 1'b0);

    rst = 1'b0;
    trap_i = 1'b1;
    trap_cause_i = `EXC_INST_ADDR_MISALIGN;
    trap_pc_i = 64'h8000_0040;
    trap_tval_i = 64'h8000_0042;
    tick();
    expect_state(1'b1, `EXC_INST_ADDR_MISALIGN, 64'h8000_0040,
                 64'h8000_0042, 1'b0, 1'b0, 1'b0, 1'b1);

    clear_inputs();
    tick();
    expect_state(1'b1, `EXC_INST_ADDR_MISALIGN, 64'h8000_0040,
                 64'h8000_0042, 1'b0, 1'b0, 1'b0, 1'b1);

    clear_inputs();
    trap_i = 1'b1;
    trap_cause_i = `EXC_ILLEGAL_INST;
    trap_pc_i = 64'h8000_0100;
    trap_tval_i = 64'h0000_0013;
    tick();
    expect_state(1'b1, `EXC_ILLEGAL_INST, 64'h8000_0100,
                 64'h0000_0013, 1'b0, 1'b0, 1'b0, 1'b1);

    rst = 1'b1;
    clear_inputs();
    tick();
    expect_state(1'b0, {`TRAP_CAUSE_W{1'b0}}, {`XLEN{1'b0}},
                 {`XLEN{1'b0}}, 1'b0, 1'b0, 1'b0, 1'b0);

    rst = 1'b0;
    exit_i = 1'b1;
    exit_is_ecall_i = 1'b1;
    tick();
    expect_state(1'b0, {`TRAP_CAUSE_W{1'b0}}, {`XLEN{1'b0}},
                 {`XLEN{1'b0}}, 1'b1, 1'b1, 1'b0, 1'b1);

    clear_inputs();
    tick();
    expect_state(1'b0, {`TRAP_CAUSE_W{1'b0}}, {`XLEN{1'b0}},
                 {`XLEN{1'b0}}, 1'b1, 1'b1, 1'b0, 1'b1);

    rst = 1'b1;
    clear_inputs();
    tick();
    expect_state(1'b0, {`TRAP_CAUSE_W{1'b0}}, {`XLEN{1'b0}},
                 {`XLEN{1'b0}}, 1'b0, 1'b0, 1'b0, 1'b0);

    rst = 1'b0;
    trap_i = 1'b1;
    trap_cause_i = `EXC_BREAKPOINT;
    trap_pc_i = 64'h8000_0200;
    trap_tval_i = 64'h0;
    exit_i = 1'b1;
    exit_is_ebreak_i = 1'b1;
    tick();
    expect_state(1'b1, `EXC_BREAKPOINT, 64'h8000_0200,
                 64'h0, 1'b1, 1'b0, 1'b1, 1'b1);

    $display("PASS tb_ooo_trap_exit_output_sequencer");
    $finish;
  end
endmodule
