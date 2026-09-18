`timescale 1ns/1ps
module tb_r64_trap_prepare;
 reg clk=0;always #5 clk=~clk;
 reg prepare=0,irq=0;reg [5:0] cause=0;reg [63:0] vector=0;
 wire [63:0] target;
 R64TrapVectorStage dut(clk,prepare,vector,irq,cause,target);
 reg [63:0] expected,saved,random_q=64'h56781fe05467812a;
 integer i,j,k,checks=0;
 initial begin
  for(i=0;i<256;i=i+1)for(j=0;j<64;j=j+1)for(k=0;k<2;k=k+1)begin
   @(negedge clk);random_q={random_q[62:0],random_q[63]^random_q[62]^random_q[60]^random_q[59]};
   vector=i<128?{56'hfffffffffffffe,8'(i*2+k)}:{random_q[63:2],1'b0,1'(k)};
   cause=6'(j);irq=i[0];prepare=1;
   expected={vector[63:2],2'b0}+((irq&&vector[0])?{56'b0,cause,2'b0}:64'b0);
   @(negedge clk);prepare=0;
   if(target!==expected)$fatal(1,"prepared trap target incorrect vector=%h cause=%0d irq=%b got=%h expected=%h",vector,cause,irq,target,expected);
   saved=target;vector=~vector;cause=~cause;irq=~irq;
   @(negedge clk);if(target!==saved)$fatal(1,"prepared trap target changed without a request");
   checks=checks+1;
  end
  $display("[PASS] tb_r64_trap_prepare checks=%0d direct/vector/64causes/highcarry/held",checks);$finish;
 end
endmodule
