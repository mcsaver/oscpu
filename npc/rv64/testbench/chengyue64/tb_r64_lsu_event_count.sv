`timescale 1ns/1ps
module tb_r64_lsu_event_count;
 reg clk=0;always #5 clk=~clk;
 reg [5:0] valid_mask,before_mask;reg [1:0] credit;
 R64Lsu #(.ENTRIES(20),.INDEX_W(5),.HEAD_AUTHORIZED_QUERY(1),.PREPARED_CANCEL(1)) dut(
  .clk_i(clk),.rst_i(1'b1));
 integer v,b,c,i,count,cases=0;reg [1:0] expected;
 initial begin
  // Exhaust the actual production combinational slice. The rest of the LSU
  // stays in reset; this test makes no claim about forced transaction traffic.
  for(b=0;b<64;b=b+1)for(v=0;v<64;v=v+1)for(c=0;c<4;c=c+1)begin
   before_mask=6'(b);valid_mask=6'(v);credit=2'(c);count=0;
   force dut.event_valid_w=valid_mask;
   force dut.event_before_q=before_mask;
   force dut.completion_credit_w=credit;
   for(i=0;i<6;i=i+1)if(v&(1<<i))count=count+1;
   expected={count>=2,count>=1}&credit;#1;
   if(dut.completion_fire_w!==expected||
      dut.completion_fire_w!==({|dut.event_second_w,|dut.event_first_w}&credit))
     $fatal(1,"actual LSU event count equivalence failed before=%0h valid=%0h credit=%0h",before_mask,valid_mask,credit);
   cases=cases+1;
  end
  release dut.event_valid_w;release dut.event_before_q;release dut.completion_credit_w;
  $display("[PASS] tb_r64_lsu_event_count actual_rtl_exhaustive_cases=%0d",cases);$finish;
 end
endmodule
