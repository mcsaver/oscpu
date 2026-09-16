`include "tb_r64_early_frontend.sv"
module tb_r64_frontend_training;
  tb_r64_early_frontend test();
  integer dropped=0;
  reg [4:0] cancelled_index;
  initial begin
    wait(!test.rst);
    wait(test.dut.learn_valid_q!=0);
    @(negedge test.clk);
    cancelled_index=test.dut.learn_valid_q[1]?
        test.dut.learn_pc_q[72:68]:test.dut.learn_pc_q[8:4];
    test.invalidate=1;
    @(posedge test.clk);#1;
    if(test.dut.learn_valid_q!=0||test.dut.u_stream.target_valid_q!=0)
      $fatal(1,"invalidate retained a delayed frontend training owner");
    @(negedge test.clk);test.invalidate=0;
    @(posedge test.clk);#1;
    if(test.dut.u_stream.target_valid_q[cancelled_index])
      $fatal(1,"cancelled frontend training resurrected an invalidated entry");
    dropped=dropped+1;
  end
  final begin
    if(dropped!=1)$fatal(1,"frontend delayed-training cancellation not covered");
    $display("[PASS] tb_r64_frontend_training delayed hint invalidation, no resurrection, complete instruction oracle");
  end
endmodule
