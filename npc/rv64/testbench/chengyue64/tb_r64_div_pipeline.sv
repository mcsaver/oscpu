`timescale 1ns/1ps
module tb_r64_div_pipeline;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,iv=0,ready=0,word=0;
 reg [31:0] kill=0;
 reg [8:0] tag=0;
 reg [63:0] a=0,b=0;
 reg [2:0] fn=4;
 wire ir,ov;
 wire [8:0] ot;
 wire [63:0] od;
 R64Divide dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_valid_i(iv),.in_ready_o(ir),.in_tag_i(tag),.a_i(a),.b_i(b),.function_i(fn),.word_i(word),
  .out_valid_o(ov),.out_ready_i(ready),.out_tag_o(ot),.out_data_o(od));
 reg [31:0] random_q=32'h0b794a23;
 reg [63:0] aa,bb,expected;
 integer w,f,n,i,mode,age,latency,total=0,maximum=0,canceled=0;
 function [63:0] sext;input [31:0] x;begin sext={{32{x[31]}},x};end endfunction
 task tick;begin @(posedge clk);#1;@(negedge clk);end endtask
 task check_result;
 begin
  aa=word?(fn[0]?{32'b0,a[31:0]}:sext(a[31:0])):a;
  bb=word?(fn[0]?{32'b0,b[31:0]}:sext(b[31:0])):b;
  if(bb==0)expected=fn[1]?aa:64'hffffffffffffffff;
  else if(!fn[0]&&aa==64'h8000000000000000&&bb==-64'd1)expected=fn[1]?0:aa;
  else if(fn[0])expected=fn[1]?aa%bb:aa/bb;
  else expected=fn[1]?$signed(aa)%$signed(bb):$signed(aa)/$signed(bb);
  if(word)expected=sext(expected[31:0]);
  #1;if(!ir)$fatal(1,"DIV missing idle owner credit");
  iv=1;tick();iv=0;latency=0;
  while(!ov&&latency<80)begin tick();latency=latency+1;end
  if(!ov||ot!==tag||od!==expected)$fatal(1,"DIV numeric fn=%0d word=%0d a=%h b=%h got=%h expected=%h latency=%0d",fn,word,a,b,od,expected,latency);
  if(latency>maximum)maximum=latency;
  repeat(6)begin tick();if(!ov||ot!==tag||od!==expected)$fatal(1,"DIV held terminal changed");end
  ready=1;tick();ready=0;total=total+1;
 end
 endtask
 initial begin
  tick();rst=0;
  for(w=0;w<2;w=w+1)for(f=0;f<4;f=f+1)for(n=0;n<128;n=n+1)begin
   random_q={random_q[30:0],random_q[31]^random_q[21]^random_q[1]^random_q[0]};
   a={random_q,random_q^32'h53a901c7};b={~random_q,random_q^32'h19fc637b};
   case(n)
    0:begin a=0;b=0;end
    1:begin a=-1;b=1;end
    2:begin a=64'h8000000000000000;b=-1;end
    3:begin a=64'h8000000000000000;b=1;end
    4:begin a=64'h7fffffffffffffff;b=64'h8000000000000000;end
    5:begin a=1;b=64'h7fffffffffffffff;end
    6:begin a=-1;b=2;end
    7:begin a=-1;b=3;end
    8:begin a=64'h0000000080000000;b=-1;end
    9:begin a=-1;b=0;end
    10:begin a=64'hffffffff80000001;b=64'hffffffff80000000;end
    11:begin a=64'h000000007fffffff;b=64'h0000000080000000;end
    default:begin end
   endcase
   word=w!=0;fn={1'b1,f[1:0]};tag=9'(n);check_result();
  end
  if(maximum!=72)$fatal(1,"DIV maximum deterministic latency changed: %0d",maximum);
  for(mode=0;mode<2;mode=mode+1)for(age=0;age<76;age=age+1)begin
   word=0;fn=5;tag=77;a=-1;b=1;iv=1;tick();iv=0;repeat(age)tick();
   if(mode==0)kill=32'h2000;else flush=1;
   tick();kill=0;flush=0;
   if(ov||!ir)$fatal(1,"DIV cancellation failed age=%0d mode=%0d",age,mode);
   canceled=canceled+1;
   // Reuse the exact physical ROB slot with a new generation immediately.
   tag=109;a=97;b=7;check_result();
  end
  $display("[R64-DIV-PIPELINE] operations=%0d cancellation_ages=%0d max_latency=%0d full64/word/zero/overflow/held/generation PASS",total,canceled,maximum);
  $display("[PASS] tb_r64_div_pipeline");$finish;
 end
endmodule
