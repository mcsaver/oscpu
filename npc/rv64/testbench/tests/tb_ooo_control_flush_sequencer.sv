`timescale 1ns/1ps

module tb_ooo_control_flush_sequencer;
  reg clk;
  reg rst;
  reg trap_flush_req;
  reg priv_predictor_boundary;
  reg backend_drained;
  reg checkpoint_restore;

  wire core_trap_flush;
  wire trap_redirect_squash;
  wire checkpoint_mem_flush;

  integer errors;

  OooControlFlushSequencer dut (
    .clk(clk),
    .rst(rst),
    .trap_flush_req_i(trap_flush_req),
    .priv_predictor_boundary_i(priv_predictor_boundary),
    .backend_drained_i(backend_drained),
    .checkpoint_restore_i(checkpoint_restore),
    .core_trap_flush_o(core_trap_flush),
    .trap_redirect_squash_o(trap_redirect_squash),
    .checkpoint_mem_flush_o(checkpoint_mem_flush)
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

  task automatic clear_inputs;
    begin
      trap_flush_req = 1'b0;
      priv_predictor_boundary = 1'b0;
      backend_drained = 1'b0;
      checkpoint_restore = 1'b0;
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic expect_outputs;
    input [255:0] name;
    input expected_trap_flush;
    input expected_squash;
    input expected_mem_flush;
    begin
      tb_check1({name, " trap"}, core_trap_flush, expected_trap_flush);
      tb_check1({name, " squash"}, trap_redirect_squash, expected_squash);
      tb_check1({name, " mem"}, checkpoint_mem_flush, expected_mem_flush);
    end
  endtask

  initial begin
    errors = 0;
    clear_inputs();
    rst = 1'b1;
    repeat (2) tick();
    rst = 1'b0;
    tick();
    expect_outputs("reset clears", 1'b0, 1'b0, 1'b0);

    clear_inputs();
    trap_flush_req = 1'b1;
    tick();
    expect_outputs("trap request pulses", 1'b1, 1'b0, 1'b0);
    clear_inputs();
    tick();
    expect_outputs("trap pulse clears", 1'b0, 1'b0, 1'b0);

    clear_inputs();
    checkpoint_restore = 1'b1;
    tick();
    expect_outputs("checkpoint restore pulses", 1'b0, 1'b0, 1'b1);
    tick();
    expect_outputs("checkpoint restore follows high input", 1'b0, 1'b0, 1'b1);
    checkpoint_restore = 1'b0;
    tick();
    expect_outputs("checkpoint restore clears", 1'b0, 1'b0, 1'b0);

    clear_inputs();
    priv_predictor_boundary = 1'b1;
    backend_drained = 1'b0;
    tick();
    expect_outputs("boundary sets squash", 1'b0, 1'b1, 1'b0);
    priv_predictor_boundary = 1'b0;
    tick();
    expect_outputs("squash holds while backend busy", 1'b0, 1'b1, 1'b0);
    backend_drained = 1'b1;
    tick();
    expect_outputs("squash clears when backend drained", 1'b0, 1'b0, 1'b0);

    clear_inputs();
    priv_predictor_boundary = 1'b1;
    backend_drained = 1'b1;
    tick();
    expect_outputs("boundary wins over drained clear", 1'b0, 1'b1, 1'b0);
    priv_predictor_boundary = 1'b0;
    tick();
    expect_outputs("drained clears after boundary cycle", 1'b0, 1'b0, 1'b0);

    clear_inputs();
    trap_flush_req = 1'b1;
    priv_predictor_boundary = 1'b1;
    checkpoint_restore = 1'b1;
    tick();
    expect_outputs("combined events", 1'b1, 1'b1, 1'b1);
    clear_inputs();
    tick();
    expect_outputs("combined pulses clear but squash holds", 1'b0, 1'b1, 1'b0);
    backend_drained = 1'b1;
    tick();
    expect_outputs("combined squash drains", 1'b0, 1'b0, 1'b0);

    clear_inputs();
    priv_predictor_boundary = 1'b1;
    tick();
    expect_outputs("pre reset squash set", 1'b0, 1'b1, 1'b0);
    rst = 1'b1;
    trap_flush_req = 1'b1;
    checkpoint_restore = 1'b1;
    tick();
    expect_outputs("reset wins over requests", 1'b0, 1'b0, 1'b0);
    rst = 1'b0;
    clear_inputs();
    tick();
    expect_outputs("post reset idle", 1'b0, 1'b0, 1'b0);

    if (errors == 0) begin
      $display("PASS tb_ooo_control_flush_sequencer");
      $finish;
    end
    $fatal(1, "FAIL tb_ooo_control_flush_sequencer errors=%0d", errors);
  end
endmodule
