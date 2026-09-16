`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu_network;
 parameter DEPTH=20;parameter EARLY_STORE=0;localparam IW=$clog2(DEPTH);
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;reg [31:0] kill=0;
  reg [2:0] trigger_enable=0;reg [63:0] trigger_address=0;
  reg trigger_test=0,no_external=0;reg [8:0] full_tag[0:31];
  reg head_valid=1,effect_allow=1,fp_enable=1;reg [8:0] head_tag=0;
  reg [1:0] commit_fire=0;reg [17:0] commit_tag=0;
  reg [1:0] in_fire=0;wire [1:0] in_ready;
  reg [17:0] in_tag=0;reg [2*`R64_UOP_W-1:0] in_uop=0;reg [383:0] operand=0;
  wire [1:0] out_valid;reg [1:0] out_ready=3;
  wire [17:0] out_tag;wire [2*`R64_RESULT_W-1:0] out_result;
  wire [31:0] reuse;wire irreversible,idle;
  wire [1:0] tv,tr,tad,tresp,trespready;wire [127:0] tva,tpa;
  wire [3:0] ta,tc;wire [1:0] tfault,tneeds;wire [9:0] tcause,townersize;wire [5:0] towneraccess;
  wire [1:0] mv,mr,mcache,mresp,mrespready,merror;wire [2*IW-1:0] mtoken,mresptoken;
  wire [127:0] ma,md,mrd;wire [3:0] mop;wire [5:0] msize;wire [15:0] mstrb;wire [9:0] mamo;
  // TB-only front-end: previous stimuli reserve in program order, then
  // bind the captured payload one edge later to the real dispatch-owned LSU.
  reg [1:0] bind_fire_q=0;reg [17:0] bind_tag_q=0;
  reg [2*`R64_UOP_W-1:0] bind_uop_q=0;reg [383:0] bind_operand_q=0;
  reg [2*IW-1:0] bind_slot_q=0;wire [2*IW-1:0] reserve_slot_w;
  always @(posedge clk)begin
    if(rst||flush)bind_fire_q<=0;
    else bind_fire_q<=in_fire;
    if(|in_fire)begin
      bind_tag_q<=in_tag;bind_uop_q<=in_uop;bind_operand_q<=operand;bind_slot_q<=reserve_slot_w;
    end
  end
  R64Lsu #(.EARLY_STORE(EARLY_STORE),.ENTRIES(DEPTH),.INDEX_W(IW)) dut(
   .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
   .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),.trigger_enable_i(trigger_enable),.trigger_address_i(trigger_address),.fp_enable_i(fp_enable),.translate_active_i(1'b0),
   .store_done_valid_o(),.store_done_ready_i(1'b1),.store_done_tag_o(),.store_done_error_o(),.store_done_tval_o(),
   .mem_fast_store_o(),.mem_store_rsp_valid_i(1'b0),.mem_store_rsp_ready_o(),.mem_store_rsp_token_i({IW{1'b0}}),.mem_store_rsp_error_i(1'b0),
   .commit_fire_i(commit_fire),.commit_tag_i(commit_tag),
   .reserve_want_i(2'b11),.reserve_fire_i(in_fire),.reserve_ready_o(in_ready),.reserve_slot_o(reserve_slot_w),
   .reserve_tag_i(in_tag),.reserve_func_i({in_uop[`R64_UOP_W+196+:8],in_uop[196+:8]}),
   .reserve_amo_i({in_uop[`R64_UOP_W+155+:5],in_uop[155+:5]}),
   .in_fire_i(bind_fire_q),.in_ready_o(),.in_tag_i(bind_tag_q),.in_slot_i(bind_slot_q),
   .in_uop_i(bind_uop_q),.in_operand_i(bind_operand_q),
   .out_valid_o(out_valid),.out_ready_i(out_ready),.out_tag_o(out_tag),.out_result_o(out_result),
   .reuse_block_o(reuse),.irrevocable_o(irreversible),.idle_o(idle),
   .tr_valid_o(tv),.tr_ready_i(tr),.tr_vaddr_o(tva),.tr_access_o(ta),.tr_ad_update_o(tad),
   .tr_rsp_valid_i(tresp),.tr_rsp_ready_o(trespready),.tr_paddr_i(tpa),.tr_class_i(tc),
   .tr_fault_i(tfault),.tr_needs_ad_i(tneeds),.tr_cause_i(tcause),
   .tr_owner_access_o(towneraccess),.tr_owner_size_o(townersize),
   .mem_valid_o(mv),.mem_ready_i(mr),.mem_token_o(mtoken),.mem_addr_o(ma),.mem_data_o(md),
   .mem_op_o(mop),.mem_cache_o(mcache),.mem_size_o(msize),.mem_strb_o(mstrb),.mem_amo_o(mamo),
   .mem_rsp_valid_i(mresp),.mem_rsp_ready_o(mrespready),.mem_rsp_token_i(mresptoken),
   .mem_rsp_data_i(mrd),.mem_rsp_error_i(merror),.mem_rsp_offset_i(6'b0));
  reg [63:0] memory[0:1023],expected[0:31];reg [31:0] active=0,killed=0,received=0;
  reg [31:0] expectfault=0;reg [5:0] expectcause[0:31];reg [63:0] expecttval[0:31];
  reg [63:0] tqueue[0:15];reg [1:0] taqueue[0:15];reg adqueue[0:15];
  integer tdue[0:15],th[0:1],tt[0:1],tn[0:1];
  reg [IW-1:0] mqtoken[0:15];reg [63:0] mqdata[0:15];
  reg mqerror[0:15];integer mdue[0:15],mh[0:1],mt[0:1],mn[0:1];
  integer cycles=0,trcount=0,memcount=0,wbcount=0,dual=0,adupdates=0;
  integer tr_delay=2,mem_delay=3;
  reg head_preparation_seen=0;
  reg delay_owner=0;reg [63:0] delayed_addr=0;
  reg tr_hold=0,mem_hold=0,error_write=0,bad_response=0; reg response_hold=0;
  reg [31:0] rng=32'h947312bd;reg random_stall=0;
  genvar g;
  generate for(g=0;g<2;g=g+1)begin:gen_model
    assign tr[g]=tn[g]<7&&!tr_hold&&(!random_stall||rng[g]);
    assign tresp[g]=tn[g]!=0&&tdue[g*8+th[g]]<=cycles&&!tr_hold;
    assign tpa[g*64+:64]=tqueue[g*8+th[g]]&~64'h1000;
    assign tc[g*2+:2]=tqueue[g*8+th[g]][11:8]==4'he ?2'd2:2'd0;
    assign tfault[g]=tqueue[g*8+th[g]][11:8]==4'hf;
    assign tneeds[g]=tqueue[g*8+th[g]][11:8]==4'hd&&taqueue[g*8+th[g]]==2&&!adqueue[g*8+th[g]];
    assign tcause[g*5+:5]=taqueue[g*8+th[g]]==2?5'd15:5'd13;
    assign mr[g]=mn[g]<7&&!mem_hold&&(!random_stall||rng[g+2]);
    assign mresp[g]=(bad_response&&g==0)||(mn[g]!=0&&mdue[g*8+mh[g]]<=cycles&&!response_hold);
    assign mresptoken[g*IW+:IW]=bad_response?{IW{1'b0}}:mqtoken[g*8+mh[g]];
    assign mrd[g*64+:64]=mqdata[g*8+mh[g]];
    assign merror[g]=mqerror[g*8+mh[g]];
  end endgenerate
  integer a,b,tag,index,j,slot;
  reg [63:0] response_data;
  always @(posedge clk)if(!rst)begin
    if(delay_owner&&dut.prepared_valid_q&&dut.prepared_tag_q==0)head_preparation_seen=1;
    if(no_external&&(tv!=0||mv!=0))$fatal(1,"trigger escaped into translation/physical request");
    cycles=cycles+1;rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
    for(a=0;a<2;a=a+1)begin
      // Queue outputs must remain the accepted owner through the sampling edge.
      tn[a]<=tn[a]+((tv[a]&&tr[a])?1:0)-((tresp[a]&&trespready[a])?1:0);
      if(tresp[a]&&trespready[a])th[a]<=(th[a]+1)%8;
      if(tv[a]&&tr[a])begin
        tqueue[a*8+tt[a]]=tva[a*64+:64];taqueue[a*8+tt[a]]=ta[a*2+:2];adqueue[a*8+tt[a]]=tad[a];
        tdue[a*8+tt[a]]=cycles+((delay_owner&&tva[a*64+:64]==delayed_addr)?80:tr_delay);tt[a]<=(tt[a]+1)%8;trcount=trcount+1;
        if(tad[a]&&ta[a*2+:2]==2)adupdates=adupdates+1;
      end
      mn[a]<=mn[a]+((mv[a]&&mr[a])?1:0)-((mresp[a]&&mrespready[a])?1:0);
      if(mresp[a]&&mrespready[a])mh[a]<=(mh[a]+1)%8;
      if(mv[a]&&mr[a])begin
        index=ma[a*64+:64]>>3;response_data=memory[index];
        if(mop[a*2+:2]==1&&!error_write)for(j=0;j<8;j=j+1)
          if(mstrb[a*8+j])memory[index][j*8+:8]=md[a*64+j*8+:8];
        mqtoken[a*8+mt[a]]=mtoken[a*IW+:IW];mqdata[a*8+mt[a]]=response_data;
        mqerror[a*8+mt[a]]=mop[a*2+:2]!=0&&error_write;
        mdue[a*8+mt[a]]=cycles+mem_delay;mt[a]<=(mt[a]+1)%8;memcount=memcount+1;
      end
      if(out_valid[a]&&out_ready[a])begin
        tag=out_tag[a*9+:5];
        if(trigger_test&&out_tag[a*9+:9]!==full_tag[tag])$fatal(1,"trigger generation mismatch");
        if(!active[tag]||killed[tag]||received[tag])$fatal(1,"invalid completion tag %0d active%h killed%h received%h",tag,active,killed,received);
        if(out_result[a*`R64_RESULT_W+64]!==expectfault[tag]||
          (!expectfault[tag]&&out_result[a*`R64_RESULT_W+:64]!==expected[tag])||
          (expectfault[tag]&&(out_result[a*`R64_RESULT_W+65+:6]!==expectcause[tag]||
            out_result[a*`R64_RESULT_W+71+:64]!==expecttval[tag])))
          $fatal(1,"bad result tag%0d value%h expected%h exception%b",tag,out_result[a*`R64_RESULT_W+:64],expected[tag],out_result[a*`R64_RESULT_W+64]);
        received[tag]=1;wbcount=wbcount+1;
      end
    end
    if(out_valid==3&&out_ready==3)dual=dual+1;
  end
  task enqueue;
    input [8:0] tagno;input [63:0] addr,data;input [7:0] fn;input [4:0] amo;
    input [63:0] answer;input fault;input [5:0] cause;
    begin
      @(negedge clk);while(!in_ready[0])@(negedge clk);
      in_fire=1;in_tag={9'b0,tagno};in_uop=0;operand=0;
      in_uop[196+:8]=fn;in_uop[155+:5]=amo;operand[63:0]=addr;operand[64+:64]=data;
      full_tag[tagno[4:0]]=tagno;
      active[tagno[4:0]]=1;received[tagno[4:0]]=0;killed[tagno[4:0]]=0;
      expected[tagno[4:0]]=answer;expectfault[tagno[4:0]]=fault;
      expectcause[tagno[4:0]]=cause;expecttval[tagno[4:0]]=addr;
      @(negedge clk);in_fire=0;
    end
  endtask
  task wait_result;
    input [4:0] tagno;
    begin while(!received[tagno])@(negedge clk);end
  endtask
  task retire;
    input [8:0] tagno;
    begin @(negedge clk);commit_fire=1;commit_tag={9'b0,tagno};@(negedge clk);commit_fire=0;active[tagno[4:0]]=0;end
  endtask
  integer progress_limit;reg [63:0] head_addr;reg [7:0] head_func;reg [4:0] head_amo;
  integer n,before_mem,before_tr,issued,retired,start_cycle,stream_cycles;

  reg [5:0] fair_valid=0;reg [1:0] fair_credit=0;
  integer grants[0:5],age[0:5],max_wait=0,got,total;
  integer refill_events=0;
  always @(posedge clk)if(!rst)for(integer pl=0;pl<2;pl=pl+1)
    if(dut.mfire_w[pl]&&dut.query_take_w[pl]&&!dut.query_full_w[pl]&&
      dut.physical_slot_w[pl]!=dut.query_slot_w[pl])refill_events=refill_events+1;
  integer mode=0,waited,cut_lane,cut_slot,cut_tag,held_mem,early_count;
  reg baseline=0; reg [31:0] wanted;
  initial begin
    baseline=$test$plusargs("baseline");
    if($test$plusargs("reverse"))mode=1;
    if($test$plusargs("dead"))mode=2;
    if($test$plusargs("spill-cancel"))mode=3;
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4)@(negedge clk);rst=0;
    if($test$plusargs("fair"))begin
      // Exercise the production arbiter with synthetic complete sources.
      // Suppress only its sink publication: no fake transaction enters LSU queues.
      force dut.event_valid_w=fair_valid;
      force dut.completion_credit_w=fair_credit;
      force dut.completion_fire_w=2'b0;
      for(n=0;n<6;n=n+1)begin grants[n]=0;age[n]=0;end
      fair_valid=6'h3f;
      for(waited=0;waited<120;waited=waited+1)begin
        @(negedge clk);fair_credit=waited%4==0?2'b0:(waited%2==0?2'b01:2'b11);
        @(posedge clk);got=0;
        for(n=0;n<6;n=n+1)begin
          if(dut.event_grant_w[n])begin grants[n]=grants[n]+1;got=got+1;age[n]=0;end
          else if(fair_credit!=0)begin age[n]=age[n]+1;if(age[n]>max_wait)max_wait=age[n];end
        end
        if(got!=(int'(fair_credit[0])+int'(fair_credit[1])))$fatal(1,"arbiter failed available bandwidth");
      end
      $display("LSU_NETWORK fairness raw0=%0d raw1=%0d fault0=%0d fault1=%0d forward0=%0d forward1=%0d max_service_wait=%0d",
        grants[0],grants[1],grants[2],grants[3],grants[4],grants[5],max_wait);
      if(!baseline&&(max_wait>5||grants[4]==0||grants[5]==0))$fatal(1,"unbounded completion source wait");
      // Sparse sources and one/two free completion lanes must not grant absent sources.
      for(waited=1;waited<64;waited=waited+1)begin
        @(negedge clk);fair_valid=6'(waited);fair_credit=waited%2?2'b11:2'b01;
        @(posedge clk);got=0;total=0;
        for(n=0;n<6;n=n+1)begin
          if(fair_valid[n])total=total+1;
          if(dut.event_grant_w[n])got=got+1;
        end
        if((dut.event_grant_w&~fair_valid)!=0||got!=(total>1&&fair_credit[1]?2:1))
          $fatal(1,"sparse completion arbitration lost/duplicated source");
      end
      $display("[PASS] tb_r64_lsu_network fairness source eligibility, credit, bounded service");$finish;
    end
    if(mode==0)begin
      enqueue(0,64'h81,64'h11,8'h20,0,0,0,0);wait_result(0);
      @(negedge clk);mem_hold=1;held_mem=memcount;
      enqueue(1,64'h80,0,8'h03,0,(memory[16]&~64'hff00)|64'h1100,0,0);
      repeat(12)@(negedge clk);
      enqueue(2,64'h81,0,8'h04,0,64'h11,0,0);
      repeat(24)@(negedge clk);
      early_count=received[2];
      if(memcount!=held_mem)$fatal(1,"blocked partial load issued unexpectedly");
      if(!baseline&&!received[2])$fatal(1,"full-forward load blocked behind physical query");
      retire(0);repeat(3)@(negedge clk);
      $display("LSU_NETWORK partial_forward early_full=%0d source_free=%0d physical_waiting=%0d",
        early_count,dut.state_q[0]==0,memcount==held_mem);
      if(!baseline)begin
        if(dut.state_q[0]!=0||reuse[0])$fatal(1,"snapshot retained committed source");
        head_tag=1;
        enqueue(32,64'h81,64'h5a,8'h20,0,0,0,0);
        repeat(3)@(negedge clk);
        if(dut.tag_q[0]!=32||dut.store_q[0][15:8]!=8'h5a)
          $fatal(1,"source data was not replaced by new owner generation");
      end
      @(negedge clk);mem_hold=0;wait_result(1);wait_result(2);
      if(!baseline)begin kill=1;killed[0]=1;@(negedge clk);kill=0;end
    end else if(mode==1)begin
      enqueue(0,64'h80,64'hfedcba9876543210,8'h23,0,0,0,0);wait_result(0);
      out_ready=0;held_mem=memcount;
      for(n=1;n<=6;n=n+1)enqueue(9'(n),64'h80,0,8'h03,0,64'hfedcba9876543210,0,0);
      enqueue(7,64'h180,0,8'h03,0,memory[48],0,0);
      repeat(35)@(negedge clk);early_count=memcount-held_mem;
      $display("LSU_NETWORK reverse physical_before_backend_release=%0d",early_count);
      if(!baseline&&early_count!=1)$fatal(1,"physical request blocked behind full-forward result");
      out_ready=3;for(n=1;n<=7;n=n+1)wait_result(5'(n));
      retire(0);
    end else if(mode==3)begin
      mem_hold=1;
      for(n=0;n<3;n=n+1)begin
        enqueue(9'(n),64'h80+64'(n*8),0,8'h03,0,memory[16+n],0,0);
        repeat(8)@(negedge clk);
      end
      if(mv==0||memcount!=0)$fatal(1,"held physical request not established");
      @(negedge clk);kill=1;killed[0]=1;
      @(negedge clk);kill=0;repeat(3)@(negedge clk);
      if(reuse[0])$fatal(1,"cancelled physical spill retained old owner");
      head_tag=1;
      enqueue(32,64'h180,0,8'h03,0,memory[48],0,0);
      repeat(8)@(negedge clk);mem_hold=0;
      wait_result(1);wait_result(2);wait_result(0);
      if(refill_events==0)$fatal(1,"old spill issue/new query snapshot edge missing");
      while(!idle)@(negedge clk);
      mem_hold=1;enqueue(4,64'h200,0,8'h03,0,memory[64],0,0);
      repeat(12)@(negedge clk);held_mem=memcount;
      if(mv==0)$fatal(1,"flush spill fixture missing");
      flush=1;killed[4]=1;@(negedge clk);flush=0;mem_hold=0;
      repeat(6)@(negedge clk);
      if(memcount!=held_mem||reuse[4])$fatal(1,"flushed spill escaped physical service");
      $display("LSU_NETWORK spill_cancel refill_events=%0d generation32_data_checked=1 flush_no_issue=1",refill_events);
    end else begin
      out_ready=0;mem_delay=1;
      for(n=0;n<10;n=n+1)enqueue(9'(n),64'(n*8),0,8'h03,0,memory[n],0,0);
      waited=0;cut_lane=-1;
      while(cut_lane<0&&waited<100)begin
        @(negedge clk);waited=waited+1;
        for(n=0;n<2;n=n+1)if(mresp[n]&&!mrespready[n])cut_lane=n;
      end
      if(cut_lane<0)$fatal(1,"dead response raw-credit pressure not reached");
      cut_slot=mresptoken[cut_lane*IW+:IW];cut_tag=dut.tag_q[cut_slot];
      if(!dut.mem_issued_q[cut_slot]||!reuse[cut_tag%32])$fatal(1,"physical owner missing before kill");
      kill=32'b1<<(cut_tag%32);killed[cut_tag%32]=1;
      @(negedge clk);kill=0;repeat(3)@(negedge clk);
      early_count=!dut.mem_issued_q[cut_slot];
      $display("LSU_NETWORK dead drained_while_backend_blocked=%0d raw_credit=%b",early_count,dut.raw_credit_w);
      if(!baseline&&(!early_count||reuse[cut_tag%32]))$fatal(1,"dead aligned load blocked by raw credit");
      out_ready=3;
      wanted=10'h3ff&~killed;
      while((received&wanted)!=wanted)@(negedge clk);
    end
    waited=0;while(!idle&&waited<100)begin @(negedge clk);waited=waited+1;end
    if(!idle)$fatal(1,"network owners did not drain");
    $display("[PASS] tb_r64_lsu_network mode=%0d baseline=%0d completions=%0d",mode,baseline,wbcount);$finish;
  end
  initial begin #100000;$fatal(1,"LSU network timeout");end
endmodule
