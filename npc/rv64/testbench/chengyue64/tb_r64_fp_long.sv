`timescale 1ns/1ps
module tb_r64_fp_long;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,fire=0,ready=0,df=0,sqrt_op=0;
 reg [31:0] kill=0;reg [8:0] tag=0;
 reg [63:0] a=0,b=0;reg [2:0] rm=0;
 wire credit,valid;wire [8:0] out_tag;wire [63:0] value;wire [4:0] flags;
 R64FpLong dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),.in_fire_i(fire),
 .in_ready_o(credit),.in_tag_i(tag),.a_i(a),.b_i(b),.double_i(df),.rounding_i(rm),
 .sqrt_i(sqrt_op),.out_valid_o(valid),.out_ready_i(ready),.out_tag_o(out_tag),
 .out_value_o(value),.out_flags_o(flags));
 string path;integer fd,n,rc,op,fmt,rounding,latency,hold_count,k,max_latency;
 reg [63:0] av,bv,expected;reg [4:0] ef;
 initial begin
   if(!$value$plusargs("vectors=%s",path))$fatal(1,"missing vectors");
   fd=$fopen(path,"r");if(!fd)$fatal(1,"vectors open");
   repeat(3)@(negedge clk);rst=0;n=0;max_latency=0;
   while(!$feof(fd))begin
     rc=$fscanf(fd,"%d %d %d %h %h %h %h\n",op,fmt,rounding,av,bv,expected,ef);
     if(rc==7)begin
       while(!credit)@(negedge clk);
       a=av;b=bv;df=fmt;rm=rounding;sqrt_op=op;tag=n;fire=1;
       @(negedge clk);fire=0;latency=0;
       while(!valid)begin @(negedge clk);latency=latency+1;if(latency>121)$fatal(1,"long progress");end
       if(latency>max_latency)max_latency=latency;
       hold_count=n%4;
       repeat(hold_count+1)begin
         if(value!==expected||flags!==ef||out_tag!==(n&511))
           $fatal(1,"long n=%0d op=%0d df=%0d rm=%0d a=%h b=%h got=%h/%h expected=%h/%h",
             n,op,fmt,rounding,av,bv,value,flags,expected,ef);
         @(negedge clk);
       end
       ready=1;@(negedge clk);ready=0;n=n+1;
     end
   end
   for(k=0;k<122;k=k+1)begin
     a=64'h4000000000000000;b=64'h4008000000000000;df=1;sqrt_op=k%2;tag=23;fire=1;
     @(negedge clk);fire=0;repeat(k)@(negedge clk);
     kill=32'h00800000;@(negedge clk);kill=0;
     repeat(126)begin @(negedge clk);if(valid)$fatal(1,"killed long resurrected");end
   end
   for(k=0;k<2;k=k+1)begin
     while(!credit)@(negedge clk);
     a=64'h4000000000000000;b=64'h4008000000000000;df=1;sqrt_op=k;tag=23;
     kill=32'h00800000;fire=1;@(negedge clk);fire=0;kill=0;
     repeat(126)begin @(negedge clk);if(valid)$fatal(1,"admission-killed long escaped");end
     if(!credit)$fatal(1,"admission-killed long credit missing");
   end
   $display("[R64-FP-LONG] SoftFloat RISCV=%0d DIV/SQRT S/D all-rounding flags hold kill=122 max_latency=%0d PASS",n,max_latency);
   $display("[PASS] tb_r64_fp_long");$finish;
 end
 initial begin #20000000;$fatal(1,"timeout");end
endmodule
