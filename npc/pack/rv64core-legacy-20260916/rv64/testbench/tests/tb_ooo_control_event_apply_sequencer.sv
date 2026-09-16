`timescale 1ns/1ps
`include "include/define.v"

// V9O typed full-flush apply sequencer:
// C0 captures an accepted head control event; C1 emits exactly one typed apply.
module tb_ooo_control_event_apply_sequencer;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush_i;
  reg request_valid_i;
  reg [`REDIR_REASON_W-1:0] request_reason_i;
  reg [`OOO_ROB_INDEX_W-1:0] request_kill_idx_i;

  wire apply_valid_o;
  wire [`REDIR_REASON_W-1:0] apply_reason_o;
  wire [`OOO_ROB_INDEX_W-1:0] apply_kill_idx_o;

  OooControlEventApplySequencer dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .request_valid_i(request_valid_i),
    .request_reason_i(request_reason_i),
    .request_kill_idx_i(request_kill_idx_i),
    .apply_valid_o(apply_valid_o),
    .apply_reason_o(apply_reason_o),
    .apply_kill_idx_o(apply_kill_idx_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic clear_request;
    begin
      request_valid_i = 1'b0;
      request_reason_i = `REDIR_REASON_NONE;
      request_kill_idx_i = {`OOO_ROB_INDEX_W{1'b0}};
    end
  endtask

  task automatic expect_apply;
    input [255:0] label;
    input exp_valid;
    input [`REDIR_REASON_W-1:0] exp_reason;
    input [`OOO_ROB_INDEX_W-1:0] exp_kill_idx;
    begin
      if (apply_valid_o !== exp_valid) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s valid got=%0b exp=%0b",
                 label, apply_valid_o, exp_valid);
      end
      if (exp_valid && apply_reason_o !== exp_reason) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s reason got=%0d exp=%0d",
                 label, apply_reason_o, exp_reason);
      end
      if (exp_valid && apply_kill_idx_o !== exp_kill_idx) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s kill_idx got=%0d exp=%0d",
                 label, apply_kill_idx_o, exp_kill_idx);
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    rst = 1'b1;
    flush_i = 1'b0;
    clear_request();
    repeat (2) tick();
    rst = 1'b0;
    tick();
    expect_apply("reset clears", 1'b0, `REDIR_REASON_NONE, 4'd0);

    // C0 TRAP request -> C1 typed apply.
    request_valid_i = 1'b1;
    request_reason_i = `REDIR_REASON_TRAP;
    request_kill_idx_i = 4'd3;
    tick();
    expect_apply("trap apply C1", 1'b1, `REDIR_REASON_TRAP, 4'd3);

    clear_request();
    tick();
    expect_apply("single-cycle pulse clears", 1'b0, `REDIR_REASON_NONE, 4'd0);

    // CSR_COMMIT carries a distinct reason and the accepted ROB boundary.
    request_valid_i = 1'b1;
    request_reason_i = `REDIR_REASON_CSR_COMMIT;
    request_kill_idx_i = 4'd14;
    tick();
    expect_apply("csr commit apply", 1'b1, `REDIR_REASON_CSR_COMMIT, 4'd14);

    // Continuous accepted requests form a one-stage typed pipeline.
    request_valid_i = 1'b1;
    request_reason_i = `REDIR_REASON_TRAP;
    request_kill_idx_i = 4'd15;
    tick();
    expect_apply("continuous successor", 1'b1, `REDIR_REASON_TRAP, 4'd15);

    // A global RTL flush dominates a pending/new request.
    flush_i = 1'b1;
    request_valid_i = 1'b1;
    request_reason_i = `REDIR_REASON_CSR_COMMIT;
    request_kill_idx_i = 4'd7;
    tick();
    expect_apply("flush dominates request", 1'b0, `REDIR_REASON_NONE, 4'd0);

    flush_i = 1'b0;
    clear_request();
    tick();
    expect_apply("post flush idle", 1'b0, `REDIR_REASON_NONE, 4'd0);

    tb_finish("tb_ooo_control_event_apply_sequencer");
  end
endmodule
