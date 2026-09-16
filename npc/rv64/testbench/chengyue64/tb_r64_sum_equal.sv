`timescale 1ns/1ps
module tb_r64_sum_equal;
 reg [3:0] a4=0,b4=0,t4=0;wire eq4;
 reg [63:0] a=0,b=0,t=0;wire eq64;
 R64SumEqual #(.WIDTH(4)) u_small(.a_i(a4),.b_i(b4),.target_i(t4),.equal_o(eq4));
 R64SumEqual #(.WIDTH(64)) full(.a_i(a),.b_i(b),.target_i(t),.equal_o(eq64));
 integer i,j,k,n,yes=0,no=0;
 reg [63:0] state=64'hd72365a10e948fcb,expected;
 function [63:0] random64(input [63:0] old);
 reg [63:0] v;
 begin v=old^(old<<13);v=v^(v>>7);random64=v^(v<<17);end
 endfunction
 initial begin
  for(i=0;i<16;i=i+1)for(j=0;j<16;j=j+1)for(k=0;k<16;k=k+1)begin
   a4=4'(i);b4=4'(j);t4=4'(k);#1;
   if(eq4!==(((i+j)%16)==k))$fatal(1,"exhaustive modular equality %0d+%0d=%0d",i,j,k);
  end
  for(n=0;n<25000;n=n+1)begin
   state=random64(state);a=state;state=random64(state);b=state;
   expected=a+b;state=random64(state);
   t=n%3==0?expected:n%3==1?(expected^(64'b1<<(n%64))):state;
   #1;
   if(eq64!==(expected==t))$fatal(1,"64bit sum equality a=%h b=%h target=%h",a,b,t);
   if(eq64)yes=yes+1;else no=no+1;
  end
  a=64'hffffffffffffffff;b=1;t=0;#1;if(!eq64)$fatal(1,"64bit modular wrap");
  a=64'h8000000000000000;b=64'h8000000000000000;t=0;#1;if(!eq64)$fatal(1,"signed extrema wrap");
  $display("[PASS] tb_r64_sum_equal exhaustive4=4096 random64=25000 equal=%0d unequal=%0d wrap=2",yes,no);$finish;
 end
endmodule
