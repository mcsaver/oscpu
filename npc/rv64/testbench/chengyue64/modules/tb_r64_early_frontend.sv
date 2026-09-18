`timescale 1ns/1ps
module tb_r64_early_frontend;
 parameter EARLY_PREDICT=1;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,redirect=0,enable=0,invalidate=0;
 reg [63:0] target=64'h80000000,expected=64'h80000000;
 wire [1:0] valid,fault;reg [1:0] take=0;
 wire [127:0] pc,raw,npc,tval;wire [7:0] length;wire [9:0] cause;
 wire [63:0] pa,ca,pe,pm;wire [1:0] pp;wire cv,br,pv,po,prr;
 wire [7:0] cl;wire [2:0] cs;wire [55:0] paddr;
 reg cr=0,bv=0,bl=0;reg [63:0] bd=0;reg [1:0] bp=0;
 wire [7:0] protection=pa[27:25]==5&&pa[7:4]==0?8'h80:8'b0;
 R64Frontend #(.EARLY_PREDICT(EARLY_PREDICT)) dut(
  .clk_i(clk),.rst_i(rst),.run_i(1'b1),.redirect_i(redirect),.redirect_pc_i(target),
  .priv_i(2'd3),.mstatus_i(64'd0),.satp_i(64'd0),.pbmt_enable_i(1'b1),
  .icache_invalidate_i(invalidate),.tlb_invalidate_i(1'b0),.tlb_all_vaddr_i(1'b1),
  .tlb_all_asid_i(1'b1),.tlb_vpn_i(27'd0),.tlb_asid_i(16'd0),
  .valid_o(valid),.consume_i(take),.pc_o(pc),.raw_o(raw),.length_o(length),
  .predicted_npc_o(npc),.fault_o(fault),.cause_o(cause),.tval_o(tval),
  .prediction_update_i(1'b0),.prediction_pc_i(64'd0),.prediction_conditional_i(1'b0),
  .prediction_indirect_i(1'b0),.prediction_taken_i(1'b0),.prediction_target_i(64'd0),
  .protect_paddr_o(pa),.protect_priv_o(pp),.protect_facts_i(130'b0),.protect_fault_mask_i(protection),.protect_uncached_i(1'b0),
  .cache_cmd_valid_o(cv),.cache_cmd_ready_i(cr),.cache_cmd_addr_o(ca),.cache_cmd_len_o(cl),.cache_cmd_size_o(cs),
  .cache_beat_valid_i(bv),.cache_beat_ready_o(br),.cache_beat_data_i(bd),.cache_beat_resp_i(bp),.cache_beat_last_i(bl),
  .pte_valid_o(pv),.pte_ready_i(1'b0),.pte_compare_or_o(po),.pte_addr_o(paddr),.pte_expected_o(pe),.pte_or_mask_o(pm),
  .pte_rsp_valid_i(1'b0),.pte_rsp_ready_o(prr),.pte_rdata_i(64'd0),.pte_error_i(1'b0),.pte_compare_ok_i(1'b0)
 );
 reg [7:0] bytes[0:2047];
 reg active=0,bt=0;reg [63:0] bus_addr;integer beat=0;
 reg [31:0] random_q=32'h67531429;
 integer delivered=0,cycles=0,fast=0,repairs=0,late=0,tensors=0,reads=0,stale=0;
 integer region=0,lane,i,j,n,start_count,start_fast,first_cycles,second_cycles;
 reg fault_seen=0;reg [63:0] value,next_expected;
 reg [31:0] inst;reg [15:0] ci;integer size,idx;
 function [63:0] base(input integer r);base=64'h80000000+(64'(r)<<25);endfunction
 function [31:0] jal(input integer delta);
  reg [20:0] imm;begin imm=21'(delta);jal={imm[20],imm[10:1],imm[11],imm[19:12],5'd0,7'h6f};end
 endfunction
 function [15:0] cj(input integer delta);
  reg [11:0] imm;begin imm=12'(delta);
   cj={3'b101,imm[11],imm[4],imm[9:8],imm[10],imm[6],imm[7],imm[3:1],imm[5],2'b01};
  end
 endfunction
 task put32(input integer r,input integer off,input [31:0] data);
  integer k;begin for(k=0;k<4;k=k+1)bytes[r*256+off+k]=data[k*8+:8];end
 endtask
 function [63:0] memory(input [63:0] a);
  integer k;reg [63:0] data;
  begin for(k=0;k<8;k=k+1)data[k*8+:8]=bytes[int'(a[27:25])*256+((int'(a[7:0])+k)%256)];
   memory=data;
  end
 endfunction
 task recover(input integer r,input integer off);
  begin
   @(negedge clk);enable=0;redirect=1;take=0;region=r;target=base(r)+64'(off);expected=target;fault_seen=0;
   @(negedge clk);redirect=0;
   repeat(45)@(negedge clk);
   enable=1;
  end
 endtask
 task train;
  begin recover(0,0);start_count=delivered;wait(delivered>start_count+65);end
 endtask
 always @(negedge clk)begin
  random_q={random_q[30:0],random_q[31]^random_q[21]^random_q[1]^random_q[0]};
  cr=!active&&random_q[0];
  if(!bv||bt)begin
   bv=0;
   if(active&&(random_q[2]||random_q[4]))begin
    bv=1;bd=memory(bus_addr+64'(beat*8));bl=beat==7;bp=0;
   end
  end
  take=0;
  if(enable&&!redirect&&!fault_seen&&random_q[6])begin
   if(valid[0])take=1;
   if(valid[1]&&random_q[7])take=2;
  end
 end
 always @(posedge clk)if(!rst)begin
  cycles+=1;bt=bv&&br;
  if(cv&&cr)begin
   if(active||cl!=7||cs!=3||ca[5:0]!=0)$fatal(1,"bad I-cache burst");
   active=1;bus_addr=ca;beat=0;reads+=1;
  end
  if(bt)begin if(bl)active=0;else beat+=1;end
  if(dut.planned_jump_w)fast+=1;
  if(dut.plan_repair_w)repairs+=1;
  if(dut.predicted_redirect_w)late+=1;
  if(dut.u_stream.rsp_fire_w&&dut.u_stream.stale_w)stale+=1;
  if(!redirect)for(lane=0;lane<int'(take);lane=lane+1)begin
   if(pc[lane*64+:64]!==expected)$fatal(1,"stream PC region=%0d got=%h expected=%h",region,pc[lane*64+:64],expected);
   value=memory(expected);inst=value[31:0];ci=value[15:0];
   size=value[1:0]!=3?2:((inst[6:0]==7'h5b&&inst[14:12]==3&&inst[31:27]==0&&inst[25])?8:4);
   if(region==5&&expected==base(5)+12)begin
    if(!fault[lane]||cause[lane*5+:5]!=1||tval[lane*64+:64]!=base(5)+14)
     $fatal(1,"early plan hid source fetch fault");
    fault_seen=1;
   end else begin
    if(fault[lane])$fatal(1,"unexpected fault");
    if(length[lane*4+:4]!=size||raw[lane*64+:64]!==(
       size==2?{48'd0,value[15:0]}:(size==4?{32'd0,value[31:0]}:value)))
      $fatal(1,"instruction spliced across predicted target region=%0d pc=%h",region,expected);
   end
   next_expected=expected+64'(size);
   if(!fault[lane]&&size==4&&inst[6:0]==7'h6f)
    next_expected=expected+{{43{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
   if(!fault[lane]&&size==2&&ci[15:13]==5&&ci[1:0]==1)
    next_expected=expected+{{52{ci[12]}},ci[12],ci[8],ci[10:9],ci[6],ci[7],ci[2],ci[11],ci[5:3],1'b0};
   if(npc[lane*64+:64]!==next_expected)$fatal(1,"prediction mismatch pc=%h",expected);
   expected=next_expected;delivered+=1;if(size==8)tensors+=1;
  end
  if(pv||cycles>20000)$fatal(1,"test failed to progress");
 end
 initial begin
  for(i=0;i<8;i=i+1)for(j=0;j<256;j=j+4)put32(i,j,32'h00108093);
  put32(0,12,jal(-12));
  put32(1,12,jal(20));
  put32(2,12,32'h00000463); // forward conditional defaults not taken
  put32(3,12,32'h0220305b);put32(3,16,32'h0bf0305b);
  put32(4,8,32'h0220305b);put32(4,12,32'h0bf0305b);
  put32(5,12,jal(-12));
  for(j=0;j<14;j=j+2)begin bytes[6*256+j]=1;bytes[6*256+j+1]=0;end
  put32(6,14,jal(-14));
  for(j=0;j<16;j=j+2)begin bytes[7*256+j]=1;bytes[7*256+j+1]=0;end
  {bytes[7*256+15],bytes[7*256+14]}=cj(-12);
  repeat(4)@(negedge clk);rst=0;
  train();
  for(n=1;n<=4;n=n+1)begin
   if(n!=1)train();
   recover(n,0);
   wait(expected>=base(n)+64);
  end
  train();recover(5,0);wait(fault_seen);
  start_fast=fast;recover(6,0);start_count=delivered;
  wait(delivered>=start_count+60);
  if(fast!=start_fast)$fatal(1,"cross-sector branch incorrectly entered early table");
  recover(7,2);start_count=delivered;wait(delivered>=start_count+100);
  if(tensors!=2||!stale||(EARLY_PREDICT!=0&&(fast<15||repairs<5)))
   $fatal(1,"early-path coverage gap fast=%0d repair=%0d tensors=%0d stale=%0d",fast,repairs,tensors,stale);
  @(negedge clk);enable=0;
  $display("[PASS] tb_r64_early_frontend");
  $display("early=%0d cycles=%0d instructions=%0d fast_cuts=%0d repairs=%0d late_redirects=%0d stale_returns=%0d real_refills=%0d",
    EARLY_PREDICT,cycles,delivered,fast,repairs,late,stale,reads);
  $finish;
 end
endmodule
