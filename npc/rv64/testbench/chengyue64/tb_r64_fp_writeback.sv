`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_fp_writeback;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,iv=0;
 reg [31:0] kill=0;
 reg [8:0] tag=0;
 reg [63:0] a=0,b=0;
 reg link_enable=1;
 wire [139:0] fp_result;
 reg [`R64_UOP_W-1:0] uop=0;
 wire ir,mv;
 wire [8:0] mt;
 wire [63:0] md;
 wire [2:0] ready;
 wire [1:0] wv;
 wire [17:0] wt;
 wire [279:0] wr;
 reg [1:0] competition=0;
 wire [2:0] valid={mv&&link_enable,competition};
 wire [26:0] tags={mt,9'd30,9'd29};
 wire [419:0] data={fp_result,140'd30,140'd29};
 R64FpExecute fp(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_fire_i(iv&&ir),.in_ready_o(ir),.in_tag_i(tag),.in_uop_i(uop),.in_operand_i({64'b0,b,a}),
  .fp_enabled_i(1'b1),.frm_i(3'b0),.out_valid_o(mv),.out_ready_i(ready[2]&&link_enable),
  .out_tag_o(mt),.out_result_o(fp_result));
 assign md=fp_result[63:0];
 R64Writeback #(.SOURCES(3),.SOURCE_W(2)) writeback(.clk(clk),.rst(rst),.flush_i(flush),
  .kill_mask_i(kill),.source_valid_i(valid),.source_ready_o(ready),.source_tag_i(tags),.source_result_i(data),
  .wb_valid_o(wv),.wb_tag_o(wt),.wb_result_o(wr));
 reg expected_live[0:511];
 reg [63:0] expected_data[0:511];
 integer i,l,drive,accepted=0,completed=0,canceled=0,timeout,seen_killed_valid=0,seen_deferred_kill=0;
 reg [8:0] sample_tag;
 always @(posedge clk)if(!rst)begin
  if(flush)begin
   for(i=0;i<512;i=i+1)if(expected_live[i])begin expected_live[i]=0;canceled=canceled+1;end
  end else begin
   for(i=0;i<512;i=i+1)if(expected_live[i]&&kill[i%32])begin expected_live[i]=0;canceled=canceled+1;end
   for(l=0;l<2;l=l+1)if(wv[l])begin
    sample_tag=wt[l*9+:9];
    if(sample_tag!=29&&sample_tag!=30)begin
     if(!expected_live[sample_tag]||wr[l*140+:64]!==expected_data[sample_tag])
      $fatal(1,"FP WB accepted stale/killed/duplicate/numerically incorrect owner %0d",sample_tag);
     expected_live[sample_tag]=0;completed=completed+1;
    end
   end
   if(iv&&ir)begin
    if(expected_live[tag])$fatal(1,"test duplicated live full tag");
    expected_live[tag]=!kill[tag[4:0]];expected_data[tag]=64'h4008000000000000;accepted=accepted+1;
    if(kill[tag[4:0]])canceled=canceled+1;
   end
   if(fp.fma.out_valid_o&&kill[fp.fma.out_tag_o[4:0]])begin
    if(!fp.result_ready[0])seen_deferred_kill=seen_deferred_kill+1;
    seen_killed_valid=seen_killed_valid+1;
   end
  end
 end
 task tick;begin @(posedge clk);#1;@(negedge clk);end endtask
 task issue;input [8:0] owner;input [63:0] x,y;begin
  tag=owner;a=x;b=y;iv=1;timeout=0;#1;
  while(!ir)begin tick();timeout=timeout+1;if(timeout>100)$fatal(1,"FP admission timeout");end
  tick();iv=0;
 end endtask
 initial begin
  for(i=0;i<512;i=i+1)begin expected_live[i]=0;expected_data[i]=0;end
  uop[128+:32]=32'h02000053;
  tick();rst=0;
  issue(5,64'h3ff0000000000000,64'h4000000000000000);timeout=0;
  while(!fp.fma.out_valid_o)begin tick();timeout=timeout+1;if(timeout>40)$fatal(1,"FMA terminal timeout");end
  kill=32'h20;#1;
  if(!fp.fma.out_valid_o||!fp.result_ready[0])$fatal(1,"FMA actual capture cancel boundary not exercised");
  tick();kill=0;#1;
  if(fp.output_valid_q||fp.fma.out_valid_o)$fatal(1,"FP copied canceled source into fresh holder");
  issue(37,64'h3ff0000000000000,64'h4000000000000000);
  repeat(30)tick();
  // Keep an older FP output live while another FMA reaches its terminal.
  // The younger killed FMA must release without any downstream READY.
  link_enable=0;
  issue(8,64'h3ff0000000000000,64'h4000000000000000);
  timeout=0;while(!mv)begin tick();timeout=timeout+1;if(timeout>40)$fatal(1,"FP holder timeout");end
  issue(9,64'h3ff0000000000000,64'h4000000000000000);
  timeout=0;while(!fp.fma.out_valid_o)begin tick();timeout=timeout+1;if(timeout>40)$fatal(1,"blocked FMA timeout");end
  kill=32'h200;#1;if(fp.result_ready[0])$fatal(1,"FMA kill without READY was not exercised");
  tick();kill=0;#1;if(fp.fma.out_valid_o)$fatal(1,"FMA tombstone failed to withdraw");
  link_enable=1;repeat(30)tick();
  issue(41,64'h3ff0000000000000,64'h4000000000000000);flush=1;tick();flush=0;repeat(16)tick();
  competition=3;
  for(drive=0;drive<12;drive=drive+1)issue(9'(100+drive),64'h3ff0000000000000,64'h4000000000000000);
  repeat(100)tick();competition=0;repeat(10)tick();
  for(i=0;i<512;i=i+1)if(expected_live[i])$fatal(1,"FP owner never completed");
  if(accepted!=completed+canceled||seen_killed_valid!=2||seen_deferred_kill!=1)
   $fatal(1,"FP WB conservation accepted=%0d complete=%0d canceled=%0d boundary=%0d",accepted,completed,canceled,seen_killed_valid);
  $display("[R64-FP-WB] accepted=%0d completed=%0d canceled=%0d source-cancel/blocked/generation/real-WB PASS",accepted,completed,canceled);
  $display("[PASS] tb_r64_fp_writeback");$finish;
 end
endmodule
