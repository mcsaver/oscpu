`timescale 1ns/1ps
module tb_r64_fp_fast;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] km=0;
  reg fire=0,ready=1;
  wire credit,valid;
  reg [8:0] tag=0;
  wire [8:0] otag;
  reg [63:0] a=0,b=0,c=0;
  reg df=0,np=0,nc=0;
  reg [2:0] rm=0;
  reg [1:0] kind=0; reg [31:0] inst=0;
  wire [63:0] result;
  wire [4:0] flags;
  reg [63:0] expected[0:79999];
  reg [4:0] expected_flags[0:79999];
  integer file,status,op,fmt,mode,accepted,completed,cycles,longest,run,k,j;
  reg pending=0,held=0;
  reg [63:0] hold_result;
  reg [4:0] hold_flags;
  reg [8:0] hold_tag;
  reg [1023:0] path;
  R64FpFast dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.a_i(a),.b_i(b),.inst_i(inst),.source_double_i(inst[25]^(inst[31:26]==6'h10)),.rounding_i(rm),
    .out_valid_o(valid),.out_ready_i(ready),.out_tag_o(otag),.out_value_o(result),.out_flags_o(flags));
  task tick;begin @(posedge clk);#1;end endtask
  initial begin
    if(!$value$plusargs("vectors=%s",path))path="fp-fast-vectors.txt";
    file=$fopen(path,"r");if(!file)$fatal(1,"missing FP arithmetic oracle");
    tick();rst=0;accepted=0;completed=0;cycles=0;longest=0;run=0;
    while(completed<80000&&cycles<120000)begin
      fire=0;
      if(!pending&&accepted<80000)begin
        status=$fscanf(file,"%h %d %h %h %h %h\n",inst,mode,a,b,expected[accepted],expected_flags[accepted]);
        if(status!=6)$fatal(1,"FP arithmetic oracle truncated");
        rm=mode;
        tag=9'(accepted);pending=1;
      end
      ready=cycles<2000 ? 1:(($random&7)!=0);#1;
      if(held&&(result!==hold_result||flags!==hold_flags||otag!==hold_tag||!valid))
        $fatal(1,"FP elastic output mutated while held");
      if(valid&&ready)begin
        if(otag!==9'(completed)||result!==expected[completed]||flags!==expected_flags[completed])
          $fatal(1,"FAST vector=%0d tag=%h result=%h/%h expected=%h/%h",completed,otag,result,flags,expected[completed],expected_flags[completed]);
        completed=completed+1;run=run+1;if(run>longest)longest=run;
      end else run=0;
      held=valid&&!ready;hold_result=result;hold_flags=flags;hold_tag=otag;
      if(pending&&credit)begin fire=1;pending=0;accepted=accepted+1;end
      tick();cycles=cycles+1;
    end
    if(accepted!=80000||completed!=80000||longest<1900)$fatal(1,"FAST throughput/conservation");
    fire=0;ready=0;
    for(k=0;k<2;k=k+1)begin
      flush=1;tick();flush=0;
      inst=32'hd2200053;tag=20;a=64'h3ff0000000000000;b=64'h4000000000000000;c=0;df=1;kind=0;rm=0;np=0;nc=0;
      fire=1;tick();fire=0;repeat(k)tick();km=32'h00100000;#1;
      if(valid)$fatal(1,"FP killed owner exposed output at stage %0d",k);
      tick();km=0;ready=1;
      repeat(8)begin tick();if(valid)$fatal(1,"FP killed stage owner reappeared");end
      ready=0;
    end
    $display("[R64-FP-FAST] SoftFloat RISCV=80000 S/D convert/compare/class/sign/move all-rounding backpressure=PASS longest_1percycle=%0d kill_stages=2",longest);
    $display("[PASS] tb_r64_fp_fast");$finish;
  end
endmodule
