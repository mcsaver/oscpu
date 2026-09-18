`timescale 1ns/1ps
module tb_r64_lsu_request_queue;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;reg [31:0] kill=0;
 reg [1:0] fire=0,ready_out=0;wire [1:0] ready,valid,occupied;
 reg [17:0] tag=0;reg [31:0] data=0;wire [17:0] out_tag;wire [31:0] out_data;
 wire [31:0] reuse;wire idle;reg [3:0] age_clear=0;wire [7:0] age_out;
 R64LsuRequestQueue #(.DATA_W(16),.AGE_W(4)) dut(
 .out_occupied_o(occupied),.in_age_i(8'hff),.age_clear_i(age_clear),.out_age_o(age_out),.held_age_o(),.clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_fire_i(fire),.in_ready_o(ready),.in_tag_i(tag),.in_data_i(data),
  .out_valid_o(valid),.out_ready_i(ready_out),.out_tag_o(out_tag),.out_data_o(out_data),
  .reuse_block_o(reuse),.idle_o(idle));
 integer n,l,returns=0;reg [1:0] held=0;reg [17:0] held_tag;reg [31:0] held_data;
 always @(posedge clk)if(!rst)begin
  for(l=0;l<2;l=l+1)begin
   if(held[l]&&!flush&&!kill[held_tag[l*9+:5]]&&
     (!valid[l]||out_tag[l*9+:9]!==held_tag[l*9+:9]||out_data[l*16+:16]!==held_data[l*16+:16]))
    $fatal(1,"request descriptor changed while held");
   if(valid[l]&&ready_out[l])begin
    if(out_data[l*16+:16]!==16'(out_tag[l*9+:9]*11))$fatal(1,"request descriptor tag/data mismatch");
    returns=returns+1;
   end
  end
  held=valid&~ready_out;held_tag=out_tag;held_data=out_data;
 end
 task put;input [1:0] lanes;input [8:0] a,b;
  begin
   @(negedge clk);if((ready&lanes)!=lanes)$fatal(1,"fixture exceeded credit");
   fire=lanes;tag={b,a};data={16'(b*11),16'(a*11)};
   @(negedge clk);fire=0;
  end
 endtask
 initial begin
  repeat(3)@(negedge clk);rst=0;
  put(3,1,2);age_clear=4'b0010;put(3,3,4);age_clear=0;
  if(age_out!==8'hdd)$fatal(1,"slot birth did not clear resident and incoming older-source masks");
  repeat(5)begin @(negedge clk);if(ready!=0||out_tag!={9'd2,9'd1}||reuse!=32'h1e)$fatal(1,"full descriptor credit/identity");end
  ready_out=2;repeat(2)@(negedge clk);ready_out=0;
  if(valid!=1||out_tag[0+:9]!=1||ready!=2)$fatal(1,"independent lane response/credit");
  kill=2;#1;if(valid!=0||occupied!=1)$fatal(1,"kill must qualify valid without changing Q occupancy");@(negedge clk);kill=0;@(negedge clk);
  if(valid!=1||out_tag[0+:9]!=3||reuse!=8||age_out[3:0]!=4'hd)$fatal(1,"killed front lost live skid");
  put(2,0,5);flush=1;#1;if(valid!=0||occupied!=3)$fatal(1,"flush must qualify valid without changing Q occupancy");@(negedge clk);flush=0;@(negedge clk);
  if(!idle||reuse!=0||valid!=0||occupied!=0)$fatal(1,"request queue flush owner leak");
  ready_out=3;
  for(n=0;n<64;n=n+1)begin
   @(negedge clk);if(ready!=3)$fatal(1,"request queue lost dual II1");
   fire=3;tag={9'(2*n+65),9'(2*n+64)};data={16'((2*n+65)*11),16'((2*n+64)*11)};
  end
  @(negedge clk);fire=0;repeat(2)@(negedge clk);
  if(!idle||reuse!=0||returns!=130)$fatal(1,"request queue stream accounting %0d",returns);
  $display("[PASS] tb_r64_lsu_request_queue fixed lanes, Q credit, kill/flush, 128 requests dual II1");
  $finish;
 end
 initial begin #100000;$fatal(1,"request queue timeout");end
endmodule
