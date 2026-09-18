`timescale 1ns/1ps
module tb_r64_fp_fast_pipeline;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,fire=0,ready=0;reg [31:0] kill=0,inst=0;
 reg [8:0] tag=0;reg [63:0] a=0,b=0;reg [2:0] rm=0;
 wire credit,valid;wire [8:0] otag;wire [63:0] value;wire [4:0] flags;
 integer mode,age,cancel_kind,cases=0,t,latency[0:3];
 reg [63:0] expected;
 R64FpFast dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.inst_i(inst),.source_double_i(inst[25]^(inst[31:26]==6'h10)),.a_i(a),.b_i(b),.rounding_i(rm),
  .out_valid_o(valid),.out_ready_i(ready),.out_tag_o(otag),.out_value_o(value),.out_flags_o(flags));
 task tick;begin @(posedge clk);#1;end endtask
 task select_op(input integer op);begin
  case(op)
   0:begin inst=(32'h79<<25);a=64'h123456789abcdef0;expected=a;end
   1:begin inst=(32'h69<<25)|(32'd2<<20);a=42;expected=64'h4045000000000000;end
   2:begin inst=(32'h61<<25)|(32'd2<<20);a=64'h4045000000000000;expected=42;end
   3:begin inst=(32'h20<<25)|(32'd1<<20);a=64'h3ff8000000000000;expected=64'hffffffff3fc00000;end
  endcase
 end endtask
 task issue(input integer identity);begin
  t=0;while(!credit&&t<40)begin tick();t=t+1;end
  if(!credit)$fatal(1,"fast admission progress");
  tag=9'(identity);fire=1;tick();fire=0;
 end endtask
 task await_result(input integer identity);begin
  t=0;while(!valid&&t<40)begin tick();t=t+1;end
  if(!valid||otag!=9'(identity)||value!==expected||flags!=0)
   $fatal(1,"fast result owner/data mismatch mode=%0d age=%0d tag=%h/%h value=%h/%h",mode,age,otag,identity,value,expected);
 end endtask
 initial begin
  tick();rst=0;
  for(mode=0;mode<4;mode=mode+1)begin
   flush=1;tick();flush=0;select_op(mode);issue(5);
   await_result(5);latency[mode]=t+1;
   ready=1;tick();ready=0;repeat(3)tick();
  end
  if(latency[0]!=3||latency[1]!=11||latency[2]!=11||latency[3]!=11)
   $fatal(1,"short/convert phase contract changed %0d/%0d/%0d/%0d",latency[0],latency[1],latency[2],latency[3]);
  for(cancel_kind=0;cancel_kind<2;cancel_kind=cancel_kind+1)
   for(mode=0;mode<4;mode=mode+1)
    for(age=0;age<13;age=age+1)begin
     flush=1;tick();flush=0;select_op(mode);issue(5);
     repeat(age)tick();
     if(cancel_kind==0)kill=32'h20;else flush=1;
     // Raw same-cycle VALID is not permission to capture. The real FP
     // Execute boundary rejects it; the local owner must withdraw at edge.
     tick();kill=0;flush=0;
     if(valid)$fatal(1,"canceled fast owner survived edge");
     select_op(mode);issue(37);await_result(37);
     repeat(8)begin
      if(!valid||otag!=37||value!==expected||flags!=0)$fatal(1,"held replacement mutated");
      tick();
     end
     ready=1;tick();ready=0;
     repeat(15)begin tick();if(valid)$fatal(1,"old fast producer resurrected");end
     cases=cases+1;
    end
  $display("[R64-FP-FAST-PIPELINE] short=%0d convert=%0d cycles owner cancel/flush/reuse matrix=%0d PASS",
   latency[0],latency[1],cases);
  $display("[PASS] tb_r64_fp_fast_pipeline");$finish;
 end
 initial begin #200000;$fatal(1,"fast owner timeout");end
endmodule
