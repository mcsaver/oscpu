`timescale 1ns/1ps
module tb_r64_rr_qcredit #(parameter Q_ONLY_TERMINAL=0,parameter TARGET_INGRESS_KILL=0);
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;
 reg [31:0] km=0;
 reg [1:0] fire=0,ready=0,wv=0,wfp=0;
 reg [17:0] it=0;reg [63:0] ip=0;reg [5:0] ic=0,fp=0,used=0;
 reg [35:0] src=0;reg [11:0] wp=0;reg [127:0] wd=0;reg [9:0] inslot=0;
 wire [1:0] ir,ov;wire [17:0] ot;wire [63:0] op;wire [383:0] operands;
 wire [9:0] outslot;wire [5:0] oc;
 R64RegRead #(.PAYLOAD_W(32),.Q_ONLY_TERMINAL(Q_ONLY_TERMINAL)) dut(
  .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
  .cancel_candidates_i(km),.cancel_active_i(|km),
  .in_fire_i(fire),.in_ready_o(ir),.in_tag_i(it),.in_payload_i(ip),.in_class_i(ic),
  .in_gpr_dst_i(12'b0),.in_src_preg_i(src),.in_src_fp_i(fp),.in_src_used_i(used),
  .in_fp_plan_i(52'b0),
  .wb_write_i(wv),.wb_fp_i(wfp),.wb_preg_i(wp),.wb_data_i(wd),
  .alu_bypass_valid_i(2'b0),.alu_bypass_preg_i(12'b0),.alu_bypass_data_i(128'b0),
  .out_valid_o(ov),.out_ready_i(ready),.out_tag_o(ot),.out_payload_o(op),.out_class_o(oc),
  .out_operand_o(operands),.out_gpr_dst_o(),.in_mem_slot_i(inslot),.out_mem_slot_o(outslot));
 integer rd[0:1],wr[0:1],issued[0:1];
 reg alive[0:1][0:8191];
 reg [8:0] tags[0:1][0:8191];
 reg [31:0] payloads[0:1][0:8191];
 reg [4:0] slots[0:1][0:8191];
 reg [2:0] classes[0:1][0:8191];
 reg [1:0] held=0;reg [17:0] ht;reg [63:0] hp;reg [383:0] ho;
 integer trace_fd;reg [1023:0] trace_path;
 integer cycle,lane,k,accepted=0,returned=0,cancelled=0,full_pop=0,defer_transfer=0;
 integer killed_full_ingress=0;
 integer hot_dual=0,flushes=0,kill_windows=0,backpressured=0,ready_changes=0;
 task edge_tick;begin @(posedge clk);#1;end endtask
 task demand;input good;input [511:0] message;begin
   if(good!==1'b1)$fatal(1,"cycle%0d mode%0d %0s",cycle,Q_ONLY_TERMINAL,message);
 end endtask
 task observe;
 begin
  for(lane=0;lane<2;lane=lane+1)begin
   if(flush)begin
    for(k=rd[lane];k<wr[lane];k=k+1)if(alive[lane][k])cancelled=cancelled+1;
    rd[lane]=wr[lane];held[lane]=0;
   end else begin
    if(held[lane]&&!km[ht[lane*9+:5]])begin
     demand(ov[lane]&&ot[lane*9+:9]==ht[lane*9+:9]&&
      op[lane*32+:32]==hp[lane*32+:32]&&operands[lane*192+:192]==ho[lane*192+:192],
      "held packet/operands changed");
    end
    for(k=rd[lane];k<wr[lane];k=k+1)
     if(alive[lane][k]&&km[tags[lane][k][4:0]])begin alive[lane][k]=0;cancelled=cancelled+1;end
    while(rd[lane]<wr[lane]&&!alive[lane][rd[lane]])rd[lane]=rd[lane]+1;
    if(ov[lane]&&ready[lane]&&!km[ot[lane*9+:5]])begin
     demand(rd[lane]<wr[lane],"unowned/duplicate output");
     demand(ot[lane*9+:9]==tags[lane][rd[lane]]&&op[lane*32+:32]==payloads[lane][rd[lane]]&&
      outslot[lane*5+:5]==slots[lane][rd[lane]]&&oc[lane*3+:3]==classes[lane][rd[lane]],
      "FIFO fulltag/payload/class/slot order");
     if(lane==0) demand(operands[0+:192]=={64'd303,64'd202,64'd101},"FP3 packet data");
     else demand(operands[192+:128]=={64'd22,64'd11},"GPR2 packet data");
     alive[lane][rd[lane]]=0;rd[lane]=rd[lane]+1;returned=returned+1;
    end
    if(fire[lane]&&!km[it[lane*9+:5]])begin
     demand(ir[lane],"accepted without registered owner credit");
     tags[lane][wr[lane]]=it[lane*9+:9];payloads[lane][wr[lane]]=ip[lane*32+:32];
     slots[lane][wr[lane]]=inslot[lane*5+:5];classes[lane][wr[lane]]=ic[lane*3+:3];
     alive[lane][wr[lane]]=1;wr[lane]=wr[lane]+1;accepted=accepted+1;
    end
    if(dut.terminal_count_q[lane]==2&&dut.terminal_pop_w[lane]&&dut.ingress_valid_q[lane])begin
     full_pop=full_pop+1;
     if(!dut.transfer_w[lane])defer_transfer=defer_transfer+1;
     demand(dut.transfer_w[lane] == (Q_ONLY_TERMINAL==0),"full-pop transfer mode");
    end
    if(ov[lane]&&!ready[lane])backpressured=backpressured+1;
    held[lane]=ov[lane]&&!ready[lane]&&!km[ot[lane*9+:5]];
   end
  end
  ht=ot;hp=op;ho=operands;
 end
 endtask
 initial begin
  trace_fd=0;if($value$plusargs("trace=%s",trace_path))trace_fd=$fopen(trace_path,"w");
  for(lane=0;lane<2;lane=lane+1)begin rd[lane]=0;wr[lane]=0;issued[lane]=lane;end
  edge_tick();rst=0;
  wv=3;wp={6'd2,6'd1};wd={64'd22,64'd11};edge_tick();
  wfp=3;wd={64'd202,64'd101};edge_tick();
  wv=1;wp=3;wd=303;edge_tick();wv=0;wfp=0;
  used=6'b011111;fp=6'b000111;src={6'd0,6'd2,6'd1,6'd3,6'd2,6'd1};
  for(cycle=0;cycle<4200;cycle=cycle+1)begin
   @(negedge clk);flush=0;km=0;fire=0;
   if(cycle<300)ready=3;
   else if(cycle<1200)ready=(cycle%64<36)?0:(cycle%64<56?3:2'(cycle%3+1));
   else begin
    ready=(cycle%47<22)?0:2'(cycle%4);
    if(cycle%173==12)begin flush=1;flushes=flushes+1;end
    else if(cycle%71==7)begin
     km=32'b1<<((cycle/71)%32);kill_windows=kill_windows+1;
    end
   end
   if(TARGET_INGRESS_KILL&&cycle>=1200&&cycle<1224)begin
    ready=0;flush=0;km=0;
    if(cycle==1220)begin
     demand(dut.terminal_count_q[0]==2&&dut.ingress_valid_q[0],"targeted full ingress coverage");
     ready=1;km=32'b1<<dut.ingress_tag_q[0][4:0];killed_full_ingress=killed_full_ingress+1;
    end
   end
   if(cycle>=4100)begin ready=3;flush=0;km=0;end
   for(lane=0;lane<2;lane=lane+1)begin
    it[lane*9+:9]=9'(issued[lane]);ip[lane*32+:32]=32'(issued[lane]+10000*lane);
    inslot[lane*5+:5]=5'(issued[lane]^13);ic[lane*3+:3]=(cycle%3==0)?4:(lane==0?6:0);
   end
   #1;
   if(!flush&&cycle<4100)begin
    fire=ir;
    for(lane=0;lane<2;lane=lane+1)if(km[it[lane*9+:5]])fire[lane]=0;
   end
   #1;
   if(cycle>=4&&cycle<300)begin demand(ov==3&&fire==3,"hot dual issue bubble");hot_dual=hot_dual+1;end
   if(trace_fd)begin
    $fwrite(trace_fd,"%0d %h %h ",cycle,ir,fire);
    for(lane=0;lane<2;lane=lane+1)
     if(!flush&&ov[lane]&&!km[ot[lane*9+:5]])
      $fwrite(trace_fd,"%h:%h:%h:%h:%h ",ot[lane*9+:9],op[lane*32+:32],outslot[lane*5+:5],oc[lane*3+:3],operands[lane*192+:192]);
     else $fwrite(trace_fd,"- ");
    $fwrite(trace_fd,"\n");
   end
   observe();
   for(lane=0;lane<2;lane=lane+1)if(fire[lane])issued[lane]=issued[lane]+2;
   edge_tick();
  end
  demand(!ov&&dut.ingress_valid_q==0,"final drain progress");
  demand(accepted==returned+cancelled,"owner conservation");
  if(TARGET_INGRESS_KILL)demand(killed_full_ingress==1,"targeted full+pop ingress cancellation");
  demand(full_pop>50&&hot_dual==296&&flushes>10&&kill_windows>20&&backpressured>500,"coverage");
  demand((Q_ONLY_TERMINAL!=0&&defer_transfer==full_pop)||(Q_ONLY_TERMINAL==0&&defer_transfer==0),"deferred transfer count");
  $display("[PASS] rr_qcredit mode=%0d cycles=%0d accepted=%0d returned=%0d cancel=%0d fullpop=%0d deferred=%0d hotdual=%0d held=%0d flush=%0d kill=%0d",
   Q_ONLY_TERMINAL,cycle,accepted,returned,cancelled,full_pop,defer_transfer,hot_dual,backpressured,flushes,kill_windows);
  if(trace_fd)$fclose(trace_fd);
  $finish;
 end
endmodule
