`timescale 1ns/1ps
module tb_r64_div_writeback;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,iv=0;
 reg [31:0] kill=0;
 reg [8:0] tag=0;
 reg [63:0] a=0,b=0;
 wire ir,mv;
 wire [8:0] mt;
 wire [63:0] md;
 wire [2:0] ready;
 wire [1:0] wv;
 wire [17:0] wt;
 wire [279:0] wr;
 reg [1:0] competition=0;
 wire [2:0] valid={mv,competition};
 wire [26:0] tags={mt,9'd30,9'd29};
 wire [419:0] data={{76'b0,md},140'd30,140'd29};
 R64Divide divide(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_valid_i(iv),.in_ready_o(ir),.in_tag_i(tag),.a_i(a),.b_i(b),.function_i(3'b101),.word_i(1'b0),
  .out_valid_o(mv),.out_ready_i(ready[2]),.out_tag_o(mt),.out_data_o(md));
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
      $fatal(1,"DIV WB accepted stale/killed/duplicate/numerically incorrect owner %0d",sample_tag);
     expected_live[sample_tag]=0;completed=completed+1;
    end
   end
   if(iv&&ir)begin
    if(expected_live[tag])$fatal(1,"test duplicated live full tag");
    expected_live[tag]=!kill[tag[4:0]];expected_data[tag]=a/b;accepted=accepted+1;
    if(kill[tag[4:0]])canceled=canceled+1;
   end
   if(mv&&kill[mt[4:0]])begin
    if(!ready[2])seen_deferred_kill=seen_deferred_kill+1;
    seen_killed_valid=seen_killed_valid+1;
   end
  end
 end
 task tick;begin @(posedge clk);#1;@(negedge clk);end endtask
 task issue;input [8:0] owner;input [63:0] x,y;begin
  tag=owner;a=x;b=y;iv=1;timeout=0;#1;
  while(!ir)begin tick();timeout=timeout+1;if(timeout>100)$fatal(1,"DIV admission timeout");end
  tick();iv=0;
 end endtask
 initial begin
  for(i=0;i<512;i=i+1)begin expected_live[i]=0;expected_data[i]=0;end
  tick();rst=0;
  issue(5,7,9);timeout=0;
  while(!mv)begin tick();timeout=timeout+1;if(timeout>20)$fatal(1,"DIV terminal timeout");end
  // A live raw FU VALID in the same cycle as KILL must be drained but never
  // authorize WB capture, even when the source owns a registered grant.
  kill=32'h20;#1;if(!mv)$fatal(1,"registered cancel boundary was not exercised");tick();kill=0;#1;if(mv)$fatal(1,"DIV failed to retire canceled VALID without WB grant");
  repeat(5)tick();
  issue(7,13,17);tick();kill=32'h80;tick();kill=0;
  issue(39,19,23);repeat(20)tick();
  competition=3;
  issue(41,29,31);flush=1;tick();flush=0;repeat(12)tick();
  // Two constantly eligible ALUs cannot starve the numeric completion.
  for(drive=0;drive<12;drive=drive+1)begin
   issue(9'(100+drive),64'(drive+3),64'(drive+7));
  end
  repeat(60)tick();competition=0;repeat(10)tick();
  for(i=0;i<512;i=i+1)if(expected_live[i])$fatal(1,"DIV owner never completed");
  if(accepted!=completed+canceled||seen_killed_valid!=1||seen_deferred_kill!=1)
   $fatal(1,"DIV WB conservation accepted=%0d complete=%0d canceled=%0d boundary=%0d",accepted,completed,canceled,seen_killed_valid);
  $display("[R64-DIV-WB] accepted=%0d completed=%0d canceled=%0d synchronous-cancel/full-tag/registered-grant PASS",accepted,completed,canceled);
  $display("[PASS] tb_r64_div_writeback");$finish;
 end
endmodule
