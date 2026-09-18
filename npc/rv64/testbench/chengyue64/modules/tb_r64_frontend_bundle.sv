// Existing independent memory/PC oracle plus coverage of the registered
// prediction-result owner boundary (the registered alignment payload now lives here) under its fixed random backpressure/recovery trace.
`include "tb_r64_early_frontend.sv"
module tb_r64_frontend_bundle;
  tb_r64_early_frontend test();
  integer full_cycles=0,partial=0,repair_only=0,redirect_owned=0,provisional=0;
  reg hold_q=0;
  reg [533:0] held_q;
  wire [533:0] owner_w={test.dut.align_tval_w,test.dut.align_cause_w,
      test.dut.align_fault_w,test.dut.align_length_w,test.dut.align_raw_w,
      test.dut.align_pc_w,test.dut.plan_at_w,test.dut.plan_bad_w,
      test.dut.plan_target_w,test.dut.plan_source_w,test.dut.align_v_w};
  always @(posedge test.clk)begin
    if(!test.rst)begin
      if(hold_q&&!test.redirect&&owner_w!==held_q)
        $fatal(1,"registered frontend owner changed while prediction was blocked");
      if(test.dut.result_count_q==2)full_cycles=full_cycles+1;
      if(test.dut.align_take_w==1&&!test.dut.result_pop_w)partial=partial+1;
      if(test.dut.capture_w&&test.dut.capture_take_w==0)repair_only=repair_only+1;
      if(test.redirect&&test.dut.result_count_q!=0)redirect_owned=redirect_owned+1;
      if(test.dut.capture_jump_w)provisional=provisional+1;
    end
    hold_q=!test.rst&&!test.dut.stream_redirect_w&&
        test.dut.result_count_q!=0&&test.dut.align_take_w==0;
    held_q<=owner_w;
  end
  final begin
    if(full_cycles==0||partial==0||repair_only==0||redirect_owned==0||provisional==0)
      $fatal(1,"frontend bundle coverage full=%0d partial=%0d repair-only=%0d recovery=%0d provisional=%0d",
          full_cycles,partial,repair_only,redirect_owned,provisional);
    $display("[PASS] tb_r64_frontend_bundle owner hold full=%0d partial=%0d repair-only=%0d recovery=%0d provisional=%0d",
        full_cycles,partial,repair_only,redirect_owned,provisional);
  end
endmodule
