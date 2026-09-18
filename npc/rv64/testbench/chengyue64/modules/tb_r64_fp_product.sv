`timescale 1ns/1ps
module tb_r64_fp_product;
 reg clk=0;always #5 clk=~clk;
 reg [4:0] enable=0;reg [52:0] a=0,b=0;wire [105:0] product;
 R64FpProductPipe dut(.clk(clk),.enable_i(enable),.a_i(a),.b_i(b),.product_o(product));
 reg [105:0] expected[0:4];reg [4:0] live=0;reg [63:0] random_q=64'h847ac82317d99b;
 integer i,j,checked=0;
 function [63:0] next_random;input [63:0] x;begin next_random={x[62:0],x[63]^x[62]^x[60]^x[59]};end endfunction
 initial begin
  for(i=0;i<12000;i=i+1)begin
   @(negedge clk);
   random_q=next_random(random_q);a=random_q[52:0];
   random_q=next_random(random_q);b=random_q[62:10];
   if(i<1000)enable=31;else enable=random_q[4:0];
   if(i%97==0)a=0;if(i%101==0)b=53'h1fffffffffffff;
   @(posedge clk);
   for(j=4;j>0;j=j-1)if(enable[j])begin expected[j]=expected[j-1];live[j]=live[j-1];end
   if(enable[0])begin expected[0]=a*b;live[0]=1;end
   #1;
   if(live[4])begin
    checked=checked+1;
    if(product!==expected[4])$fatal(1,"FP 53x53 product mismatch cycle=%0d got=%h expected=%h",i,product,expected[4]);
   end
  end
  $display("[R64-FP-PRODUCT] checked=%0d II1/full53/independent-stage-stalls PASS",checked);
  $display("[PASS] tb_r64_fp_product");$finish;
 end
endmodule
