`timescale 1ns/1ps
module tb_r64_fp_grs;
 reg sign_bit,df;reg [2:0] rm;reg [55:0] sig;reg [13:0] distance;
 wire increment,inexact;
 R64FpRoundIndexedDecision dut(.sign_i(sign_bit),.double_i(df),.rounding_i(rm),
  .significand_i(sig),.shift_i(distance),.increment_o(increment),.inexact_o(inexact));
 reg [63:0] random_q=64'h1bf9546210129ace;
 reg [55:0] shifted,discarded;
 reg g,st,l,inc,nx;
 integer i;
 function [63:0] next_random;input [63:0] x;reg [63:0] y;begin y=x^(x<<13);y=y^(y>>7);next_random=y^(y<<17);end endfunction
 initial begin
  for(i=0;i<100000;i=i+1)begin
   random_q=next_random(random_q);sig=random_q[55:0];df=i[0];sign_bit=i[1];rm=i[4:2];
   distance=i<8192?14'((i>>5)&255):random_q[13:0];
   if(i%31==0)sig=0;if(i%37==0)sig=56'hffffffffffffff;
   if(distance>=56)shifted={55'b0,|sig};
   else begin shifted=sig>>distance;discarded=sig<<(56-distance);shifted[0]=shifted[0]|(|discarded);end
   g=df?shifted[2]:shifted[31];st=df?(|shifted[1:0]):(|shifted[30:0]);l=df?shifted[3]:shifted[32];
   nx=g|st;
   case(rm)
    0:inc=g&&(st||l);
    1:inc=0;
    2:inc=sign_bit&&nx;
    3:inc=!sign_bit&&nx;
    4:inc=g;
    default:inc=0;
   endcase
   #1;
   if({inexact,increment}!=={nx,inc})$fatal(1,"indexed GRS mismatch i=%0d df=%0d sign=%0d rm=%0d shift=%0d sig=%h",i,df,sign_bit,rm,distance,sig);
  end
  $display("[R64-FP-GRS] 100000 direct-index vs mathematical jam shifts full14bit/rm/precision PASS");
  $display("[PASS] tb_r64_fp_grs");$finish;
 end
endmodule
