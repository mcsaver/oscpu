`timescale 1ns/1ps
module tb_r64_mul_pipeline;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,iv=0,ready=0,word=0;
 reg [31:0] kill=0;
 reg [8:0] tag=0;
 reg [63:0] a=0,b=0;
 reg [2:0] fn=0;
 wire ir,ov;
 wire [8:0] ot;
 wire [63:0] od;
 R64Multiply dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_valid_i(iv),.in_ready_o(ir),.in_tag_i(tag),.a_i(a),.b_i(b),.function_i(fn),.word_i(word),
  .out_valid_o(ov),.out_ready_i(ready),.out_tag_o(ot),.out_data_o(od));
 reg [63:0] gold[0:8191];
 reg [8:0] owner[0:8191];
 reg dead[0:8191];
 integer rd=0,wr=0,accepted=0,completed=0,killed=0,flushed=0,i,j,serial=0;
 reg [31:0] random_q=32'h936f127b;
 reg held=0;
 reg [63:0] held_data;
 reg [8:0] held_tag;
 function [63:0] product;
  input [63:0] aa,bb;input [2:0] f;input w;
  reg signed [127:0] x,y,z;
  begin
   x={{64{(f==1||f==2)&&aa[63]}},aa};y={{64{f==1&&bb[63]}},bb};z=x*y;
   product=w ? {{32{z[31]}},z[31:0]}:f==0 ? z[63:0]:z[127:64];
  end
 endfunction
 task step;
 begin
  #1;
  if(flush)begin
   for(j=rd;j<wr;j=j+1)if(!dead[j])flushed=flushed+1;
   rd=wr;held=0;
  end else begin
   for(j=rd;j<wr;j=j+1)if(!dead[j]&&kill[owner[j][4:0]])begin dead[j]=1;killed=killed+1;end
   while(rd<wr&&dead[rd])rd=rd+1;
   if(held&&!kill[held_tag[4:0]]&&(!ov||od!==held_data||ot!==held_tag))
    $fatal(1,"MUL stable terminal violated");
   if(ov&&ready&&!kill[ot[4:0]])begin
    if(rd>=wr||owner[rd]!==ot||gold[rd]!==od)$fatal(1,"MUL numerical/tag mismatch rd=%0d wr=%0d",rd,wr);
    rd=rd+1;completed=completed+1;
   end
   if(iv&&ir)begin
    gold[wr]=product(a,b,fn,word);owner[wr]=tag;dead[wr]=kill[tag[4:0]];
    if(dead[wr])killed=killed+1;
    wr=wr+1;accepted=accepted+1;
   end
   held=ov&&!ready&&!kill[ot[4:0]];held_tag=ot;held_data=od;
  end
  @(posedge clk);#1;@(negedge clk);
 end
 endtask
 initial begin
  @(posedge clk);#1;@(negedge clk);rst=0;step();
  // Eight requests reserve the whole terminal capacity even before completion.
  iv=1;ready=0;
  for(i=0;i<8;i=i+1)begin
   tag=9'(i);a=64'(i+1);b=-1;fn=3;#1;if(!ir)$fatal(1,"MUL premature admission stall");step();
  end
  iv=0;
  repeat(40)begin #1;if(ir)$fatal(1,"MUL overbooked terminal");step();end
  ready=1;repeat(12)step();
  // A transient cancellation followed by generation reuse while the old
  // canceled token remains in flight must not either resurrect or kill reuse.
  iv=1;tag=12;a=-1;b=-1;fn=1;step();
  iv=0;kill=32'h1000;step();kill=0;
  iv=1;tag=44;a=19;b=23;fn=0;step();iv=0;repeat(12)step();
  // Independent LFSR stimuli include long backpressure, kill at all stages,
  // fullflush, packed completion/admission and physical-index reuse.
  for(i=0;i<3000;i=i+1)begin
   random_q={random_q[30:0],random_q[31]^random_q[21]^random_q[1]^random_q[0]};
   ready=(i%113)>=37&&random_q[0];
   flush=(i%257)==256;
   kill=random_q[7:2]==6'd13 ? (32'b1<<random_q[12:8]):32'b0;
   iv=random_q[13]&&!flush;
   tag=9'(serial);a={random_q,~random_q};b={~random_q,random_q^32'h8e57391b};
   fn={1'b0,random_q[15:14]};word=random_q[18:16]==0;if(word)fn=0;
   #1;if(iv&&ir)serial=serial+1;
   step();
  end
  iv=0;flush=0;kill=0;ready=1;repeat(32)step();
  while(rd<wr&&dead[rd])rd=rd+1;
  if(rd!=wr||accepted!=completed+killed+flushed)$fatal(1,"MUL token conservation %0d != %0d+%0d+%0d",accepted,completed,killed,flushed);
  $display("[R64-MUL-PIPELINE] accepted=%0d completed=%0d canceled=%0d flushed=%0d reservation/backpressure/reuse PASS",accepted,completed,killed,flushed);
  $display("[PASS] tb_r64_mul_pipeline");$finish;
 end
endmodule
