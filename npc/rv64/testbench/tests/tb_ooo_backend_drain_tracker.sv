`include "tb_common.svh"

module tb_ooo_backend_drain_tracker;
  reg clk;
  reg rst;
  reg backend_empty;
  reg dispatch_fire;
  reg force_drained;
  wire drained;

  OooBackendDrainTracker dut (
    .clk(clk),
    .rst(rst),
    .backend_empty_i(backend_empty),
    .dispatch_fire_i(dispatch_fire),
    .force_drained_i(force_drained),
    .drained_o(drained)
  );

  task automatic tick;
    begin
      #1 clk = 1'b1;
      #1 clk = 1'b0;
    end
  endtask

  task automatic drive;
    input backend_empty_i;
    input dispatch_fire_i;
    input force_drained_i;
    begin
      backend_empty = backend_empty_i;
      dispatch_fire = dispatch_fire_i;
      force_drained = force_drained_i;
      tick();
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    backend_empty = 1'b0;
    dispatch_fire = 1'b0;
    force_drained = 1'b0;
    tb_errors = 0;

    tick();
    tb_check1("reset starts drained", drained, 1'b1);

    rst = 1'b0;
    drive(1'b1, 1'b0, 1'b0);
    tb_check1("empty without dispatch stays drained", drained, 1'b1);

    drive(1'b1, 1'b1, 1'b0);
    tb_check1("dispatch clears next drained", drained, 1'b0);

    drive(1'b0, 1'b0, 1'b0);
    tb_check1("non-empty backend stays not drained", drained, 1'b0);

    drive(1'b1, 1'b0, 1'b0);
    tb_check1("empty backend re-arms drained", drained, 1'b1);

    drive(1'b0, 1'b1, 1'b1);
    tb_check1("force drained wins over dispatch and non-empty", drained, 1'b1);

    drive(1'b0, 1'b0, 1'b0);
    tb_check1("after force normal update resumes", drained, 1'b0);

    tb_finish("tb_ooo_backend_drain_tracker");
  end
endmodule
