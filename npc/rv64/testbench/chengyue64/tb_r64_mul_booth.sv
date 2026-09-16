`timescale 1ns/1ps
module tb_r64_mul_booth;
 localparam N=20000;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,iv=0,ready=1,word=0;wire ir,ov;
 reg [63:0] a=0,b=0;reg [2:0] fn=0;reg [8:0] tag=0;
 wire [63:0] result;wire [8:0] otag;
 R64Multiply dut(.clk(clk),.rst(rst),.flush_i(1'b0),.kill_mask_i(32'b0),
  .in_valid_i(iv),.in_ready_o(ir),.in_tag_i(tag),.a_i(a),.b_i(b),.function_i(fn),.word_i(word),
  .out_valid_o(ov),.out_ready_i(ready),.out_tag_o(otag),.out_data_o(result));
 reg [63:0] expected[0:N-1];
 reg [63:0] edges[0:15];
 reg [63:0] random_q=64'hb79ac3490673128d;
 reg pending=0;
 integer accepted=0,completed=0,cycles=0,run=0,longest=0,index;
 function [63:0] next_random;input [63:0] x;reg [63:0] y;begin
  y=x^(x<<13);y=y^(y>>7);next_random=y^(y<<17);
 end endfunction
 function [63:0] reference_product;
  input [63:0] x,y;input [2:0] op;input w;
  reg signed [127:0] sx,sy;reg [127:0] full;
  begin
   sx=(op==1||op==2)?{{64{x[63]}},x}:{64'b0,x};
   sy=op==1?{{64{y[63]}},y}:{64'b0,y};
   full=sx*sy;
   reference_product=w?{{32{full[31]}},full[31:0]}:op==0?full[63:0]:full[127:64];
  end
 endfunction
 always @(posedge clk)if(!rst)begin
  if(ov&&ready)begin
   if(completed>=accepted||otag!==9'(completed)||result!==expected[completed])
    $fatal(1,"Booth arithmetic index=%0d tag=%h result=%h expected=%h",completed,otag,result,expected[completed]);
   completed=completed+1;run=run+1;if(run>longest)longest=run;
  end else run=0;
  if(iv&&ir)begin expected[accepted]=reference_product(a,b,fn,word);accepted=accepted+1;pending=0;end
 end
 initial begin
  edges[0]=0;edges[1]=1;edges[2]=2;edges[3]=3;
  edges[4]=64'hffffffffffffffff;edges[5]=64'hfffffffffffffffe;
  edges[6]=64'h8000000000000000;edges[7]=64'h7fffffffffffffff;
  edges[8]=64'h0000000080000000;edges[9]=64'hffffffff80000000;
  edges[10]=64'h5555555555555555;edges[11]=64'haaaaaaaaaaaaaaaa;
  edges[12]=64'hcccccccccccccccc;edges[13]=64'h3333333333333333;
  edges[14]=64'h00000000ffffffff;edges[15]=64'hffffffff00000000;
  repeat(2)@(negedge clk);rst=0;
  while(completed<N&&cycles<40000)begin
   @(negedge clk);cycles=cycles+1;random_q=next_random(random_q);
   ready=cycles<2000||(random_q[1:0]!=0);
   if(!pending&&accepted<N)begin
    index=accepted;fn={1'b0,index[1:0]};word=fn==0&&index[10];
    if(index<2048)begin a=edges[(index>>2)&15];b=edges[(index>>6)&15];end
    else begin a=random_q;random_q=next_random(random_q);b=random_q;end
    tag=9'(index);pending=1;
   end
   iv=pending;
  end
  iv=0;
  if(accepted!=N||completed!=N||longest<1900)$fatal(1,"Booth II1/conservation failure");
  $display("[R64-MUL-BOOTH] vectors=%0d signed/unsigned/high/word/edge-cross/backpressure II1=%0d PASS",completed,longest);
  $display("[PASS] tb_r64_mul_booth");$finish;
 end
endmodule
