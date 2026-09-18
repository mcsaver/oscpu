`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_fp_execute;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,fire=0,ready=1,enabled=1;
 reg [31:0] kill=0;reg [8:0] tag=0;reg [2:0] frm=0;
 reg [`R64_UOP_W-1:0] uop=0;reg [191:0] operands=0;
 wire credit,valid;wire [8:0] out_tag;wire [`R64_RESULT_W-1:0] result;
 R64FpExecute dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.in_uop_i(uop),.in_operand_i(operands),
 .fp_enabled_i(enabled),.frm_i(frm),.out_valid_o(valid),.out_ready_i(ready),
 .out_tag_o(out_tag),.out_result_o(result));
 reg [31:0] pending=0;
 reg [8:0] owner[0:31];
 reg [`R64_RESULT_W-1:0] expected[0:31];
 reg [`R64_RESULT_W-1:0] candidate,held_result;
 reg [8:0] held_tag;
 reg prepared=0,held=0;
 integer accepted=0,completed=0,killed=0,cycles=0,longest=0,run=0,phase=0,n,slot;
 integer fmafd,longfd,fastfd,rc,op,df,rm,source;
 reg [31:0] inst;
 reg [63:0] a,b,c,value;
 reg [4:0] flags;
 string directory,path;
 reg rounding_used;
 task tick;begin @(posedge clk);#1;end endtask
 initial begin
   if(!$value$plusargs("vectors_dir=%s",directory))$fatal(1,"missing vectors_dir");
   path=$sformatf("%0s/fp-fma-vectors.txt",directory);fmafd=$fopen(path,"r");
   path=$sformatf("%0s/fp-long-vectors.txt",directory);longfd=$fopen(path,"r");
   path=$sformatf("%0s/fp-fast-vectors.txt",directory);fastfd=$fopen(path,"r");
   if(!fmafd||!longfd||!fastfd)$fatal(1,"FP owner missing numeric vectors");
   tick();rst=0;
   for(phase=0;phase<2;phase=phase+1)begin
     accepted=0;completed=0;killed=0;cycles=0;longest=0;run=0;prepared=0;pending=0;held=0;
     while((accepted<(phase==0 ? 1000:6000)||pending!=0)&&cycles<300000)begin
       fire=0;flush=0;kill=0;
       if(phase==1&&cycles%97==96)begin
         slot=(cycles/97)%32;
         if(pending[slot])begin kill[slot]=1;pending[slot]=0;killed=killed+1;end
       end
       if(phase==1&&cycles%701==700)begin
         flush=1;
         for(n=0;n<32;n=n+1)if(pending[n])killed=killed+1;
         pending=0;
       end
       if(!prepared&&accepted<(phase==0 ? 1000:6000))begin
         a=64'h3ff0000000000000;b=64'h4000000000000000;c=0;
         inst=32'h02000053;value=64'h4008000000000000;flags=0;rm=0;rounding_used=1;
         if(phase==1)begin
           source=accepted%3;
           if(source==0)begin
             rc=$fscanf(fmafd,"%d %d %d %h %h %h %h %h\n",op,df,rm,a,b,c,value,flags);
             if(rc!=8)$fatal(1,"FMA vectors truncated");
             case(op)
               0:inst=32'h00000053;
               1:inst=32'h08000053;
               2:inst=32'h10000053;
               3:inst=32'h00000043;
               4:inst=32'h00000047;
               5:inst=32'h0000004b;
               default:inst=32'h0000004f;
             endcase
             inst[25]=df;inst[14:12]=rm;
           end else if(source==1)begin
             rc=$fscanf(longfd,"%d %d %d %h %h %h %h\n",op,df,rm,a,b,value,flags);
             if(rc!=7)$fatal(1,"long vectors truncated");
             inst=op ? 32'h58000053:32'h18000053;inst[25]=df;inst[14:12]=rm;
           end else begin
             rc=$fscanf(fastfd,"%h %d %h %h %h %h\n",inst,rm,a,b,value,flags);
             if(rc!=6)$fatal(1,"fast vectors truncated");
             rounding_used=inst[31:25]==7'h20||inst[31:25]==7'h21||
               inst[31:25]==7'h60||inst[31:25]==7'h61||inst[31:25]==7'h68||inst[31:25]==7'h69;
           end
         end
         enabled=!(phase==1&&accepted%47==46);frm=rm;
         if(phase==1&&rounding_used&&accepted%23==22)inst[14:12]=7;
         if(phase==1&&accepted%31==30)begin
           inst=32'h02007053;frm=6;rounding_used=1;
         end
         candidate={flags,64'b0,6'b0,1'b0,value};
         if(!enabled||(rounding_used&&inst[14:12]==7&&frm>4))
           candidate={5'b0,32'b0,inst,6'd2,1'b1,64'b0};
         uop=0;uop[`R64_U_CMD]={32'b0,inst};uop[`R64_U_LEN]=4;
         operands={c,b,a};tag=accepted;prepared=1;
       end
       ready=phase==0 ? 1:(($random&7)!=0);#1;
       if(held&&!flush&&!kill[held_tag[4:0]]&&
           (!valid||result!==held_result||out_tag!==held_tag))$fatal(1,"FP owner held output changed");
       if(valid&&ready)begin
         slot=out_tag[4:0];
         if(!pending[slot]||owner[slot]!==out_tag||result!==expected[slot])
           $fatal(1,"FP owner wrong/duplicate tag=%h result=%h expected=%h",out_tag,result,expected[slot]);
         pending[slot]=0;completed=completed+1;run=run+1;if(run>longest)longest=run;
       end else run=0;
       held=valid&&!ready;held_tag=out_tag;held_result=result;
       if(prepared&&!flush&&!kill[tag[4:0]]&&!pending[tag[4:0]]&&credit)begin
         fire=1;pending[tag[4:0]]=1;owner[tag[4:0]]=tag;expected[tag[4:0]]=candidate;
         accepted=accepted+1;prepared=0;
       end
       tick();cycles=cycles+1;
     end
     if(pending!=0||accepted!=(phase==0 ? 1000:6000)||completed+killed!=accepted)
       $fatal(1,"FP owner progress/conservation accepted=%0d completed=%0d killed=%0d",accepted,completed,killed);
     if(phase==0&&longest<990)$fatal(1,"FP owner 1/cycle throughput failed");
     $display("[R64-FP-EXECUTE] phase=%0d accepted=%0d completed=%0d canceled=%0d cycles=%0d longest_1percycle=%0d PASS",
        phase,accepted,completed,killed,cycles,longest);
   end
   $display("[PASS] tb_r64_fp_execute");$finish;
 end
endmodule
