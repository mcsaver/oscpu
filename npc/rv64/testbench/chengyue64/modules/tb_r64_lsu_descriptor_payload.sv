`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu_descriptor_payload;
 parameter DEPTH=20;parameter CORE_MODE=1;parameter EARLY_STORE=1;localparam IW=$clog2(DEPTH);
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
  wire [31:0] reuse;wire irreversible,idle,drained;
  wire [1:0] tv,tr,tad,tresp,trespready;wire [127:0] tva,tpa;
  wire [3:0] ta,tc;wire [1:0] tfault,tneeds;wire [9:0] tcause,townersize;wire [5:0] towneraccess;
  wire [1:0] mv,mr,mcache,mresp,mrespready,merror;wire [2*IW-1:0] mtoken,mresptoken;
  wire [127:0] ma,md,mrd;wire [3:0] mop;wire [5:0] msize;wire [15:0] mstrb;wire [9:0] mamo;
  reg [1:0] rwant=0,rfire=0;wire [1:0] rready;wire [2*IW-1:0] rslot;
  reg [17:0] rtag=0;reg [15:0] rfunc=0;reg [9:0] ramo=0;
  reg [2*IW-1:0] bslot=0;reg [IW-1:0] saved_slot[0:31];
  R64Lsu #(.HEAD_AUTHORIZED_QUERY(CORE_MODE),.PREPARED_CANCEL(CORE_MODE),.EARLY_STORE(EARLY_STORE),.ENTRIES(DEPTH),.INDEX_W(IW)) dut(
   .reserve_want_i(rwant),.reserve_fire_i(rfire),.reserve_ready_o(rready),.reserve_slot_o(rslot),
   .reserve_tag_i(rtag),.reserve_func_i(rfunc),.reserve_amo_i(ramo),.in_slot_i(bslot),
   .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
   .cancel_candidates_i(kill),.cancel_active_i(1'b1),
   .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),.trigger_enable_i(trigger_enable),.trigger_address_i(trigger_address),.fp_enable_i(fp_enable),.translate_active_i(1'b0),
   .store_done_valid_o(),.store_done_ready_i(1'b1),.store_done_tag_o(),.store_done_error_o(),.store_done_tval_o(),
   .mem_fast_store_o(),.mem_store_rsp_valid_i(1'b0),.mem_store_rsp_ready_o(),.mem_store_rsp_token_i({IW{1'b0}}),.mem_store_rsp_error_i(1'b0),
   .commit_fire_i(commit_fire),.commit_tag_i(commit_tag),
   .in_fire_i(in_fire),.in_ready_o(in_ready),.in_tag_i(in_tag),.in_uop_i(in_uop),.in_operand_i(operand),
   .out_valid_o(out_valid),.out_ready_i(out_ready),.out_tag_o(out_tag),.out_result_o(out_result),
   .reuse_block_o(reuse),.irrevocable_o(irreversible),.idle_o(idle),.drain_idle_o(drained),
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
  reg tr_hold=0,mem_hold=0,error_write=0,bad_response=0;
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
    assign mresp[g]=(bad_response&&g==0)||(mn[g]!=0&&mdue[g*8+mh[g]]<=cycles&&!mem_hold);
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
        if(out_tag[a*9+:9]!==full_tag[tag])$fatal(1,"trigger generation mismatch");
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
  task reserve_one;
    input integer lane;input [8:0] tagno;input [7:0] fn;input [4:0] amo;
    begin
      @(negedge clk);rwant=2'b1<<lane;rtag=0;rfunc=0;ramo=0;
      rtag[lane*9+:9]=tagno;rfunc[lane*8+:8]=fn;ramo[lane*5+:5]=amo;
      #1;if(!rready[lane])$fatal(1,"reserve_one no credit");
      saved_slot[tagno[4:0]]=rslot[lane*IW+:IW];rfire=2'b1<<lane;
      @(negedge clk);rfire=0;rwant=0;
    end
  endtask
  task bind_one;
    input integer lane;input [8:0] tagno;input [63:0] addr,data;
    input [7:0] fn;input [4:0] amo;input [63:0] answer;
    begin
      @(negedge clk);in_fire=2'b1<<lane;in_tag=0;in_uop=0;operand=0;bslot=0;
      in_tag[lane*9+:9]=tagno;bslot[lane*IW+:IW]=saved_slot[tagno[4:0]];
      in_uop[lane*`R64_UOP_W+196+:8]=fn;in_uop[lane*`R64_UOP_W+155+:5]=amo;
      operand[lane*192+:64]=addr;operand[lane*192+64+:64]=data;
      full_tag[tagno[4:0]]=tagno;active[tagno[4:0]]=1;received[tagno[4:0]]=0;
      killed[tagno[4:0]]=0;expected[tagno[4:0]]=answer;expectfault[tagno[4:0]]=0;
      expectcause[tagno[4:0]]=0;expecttval[tagno[4:0]]=addr;
      @(negedge clk);in_fire=0;
    end
  endtask
  task wait_result;
    input [4:0] slotno;integer budget;
    begin
      budget=0;while(!received[slotno]&&budget<200)begin @(negedge clk);budget=budget+1;end
      if(!received[slotno])$fatal(1,"missing result %0d reuse%h",slotno,reuse);
    end
  endtask
  task retire;
    input [8:0] tagno;
    begin @(negedge clk);commit_fire=1;commit_tag={9'b0,tagno};
      @(negedge clk);commit_fire=0;active[tagno[4:0]]=0;end
  endtask
  task clear_all;
    begin @(negedge clk);flush=1;active=0;received=0;
      @(negedge clk);flush=0;kill=0;
      repeat(4)@(negedge clk);
      if(!idle)$fatal(1,"nonissued clear retained owner");
    end
  endtask

  // Observe accepted external events; data/exception correctness is checked
  // above against the independent memory model and explicit expected values.
  integer response_cycle[0:31],physical_cycle[0:31],bypass_count[0:31];
  integer translation_events=0,dual_bypass=0,blocked_credit=0,descriptor_priority=0;
  reg expect_fast=1;
  always @(posedge clk)if(!rst)begin
    if(dut.descriptor_tr_take_w==3)dual_bypass=dual_bypass+1;
    for(integer lane=0;lane<2;lane=lane+1)begin
      if(tresp[lane]&&trespready[lane])begin
        response_cycle[dut.tag_q[dut.response_slot_w[lane]][4:0]]=$time/10;
        translation_events=translation_events+1;
        if(dut.descriptor_tr_take_w[lane])
          bypass_count[dut.tag_q[dut.response_slot_w[lane]][4:0]]=
            bypass_count[dut.tag_q[dut.response_slot_w[lane]][4:0]]+1;
        if(!dut.query_credit_w[lane])blocked_credit=blocked_credit+1;
        if(dut.descriptor_valid_w[lane])descriptor_priority=descriptor_priority+1;
      end
      if(mv[lane]&&mr[lane])
        physical_cycle[dut.tag_q[mtoken[lane*IW+:IW]][4:0]]=$time/10;
    end
  end
  task clear_observations;
    begin
      for(integer k=0;k<32;k=k+1)begin
        response_cycle[k]=-1;physical_cycle[k]=-1;bypass_count[k]=0;
      end
    end
  endtask
  task bind_pair;
    input [8:0] tag0,tag1;input [63:0] addr0,addr1;
    begin
      @(negedge clk);in_fire=3;in_tag={tag1,tag0};
      bslot={saved_slot[tag1[4:0]],saved_slot[tag0[4:0]]};
      in_uop=0;operand=0;
      in_uop[196+:8]=8'h03;in_uop[`R64_UOP_W+196+:8]=8'h03;
      operand[63:0]=addr0;operand[192+:64]=addr1;
      full_tag[tag0[4:0]]=tag0;full_tag[tag1[4:0]]=tag1;
      active[tag0[4:0]]=1;active[tag1[4:0]]=1;
      received[tag0[4:0]]=0;received[tag1[4:0]]=0;
      killed[tag0[4:0]]=0;killed[tag1[4:0]]=0;
      expected[tag0[4:0]]=memory[(addr0&~64'h1000)>>3];
      expected[tag1[4:0]]=memory[(addr1&~64'h1000)>>3];
      expectfault[tag0[4:0]]=0;expectfault[tag1[4:0]]=0;
      @(negedge clk);in_fire=0;
    end
  endtask

  // Shadow the unchanged request queue with the previous gated input producer.
  // Only valid records are compared; empty storage may contain arbitrary data.
  localparam DW=IW+152;
  wire [1:0] ref_credit,ref_valid,ref_fire;
  reg [17:0] ref_in_tag;reg [2*DW-1:0] ref_in_data;reg [2*DEPTH-1:0] ref_in_age;
  wire [17:0] ref_tag;wire [2*DW-1:0] ref_data;wire [2*DEPTH-1:0] ref_age;
  wire [DEPTH-1:0] ref_held;wire [31:0] ref_reuse;wire ref_idle;
  genvar dl;
  generate for(dl=0;dl<2;dl=dl+1)begin:g_old_fire
    assign ref_fire[dl]=dut.mvalid_q[dl]&&!flush&&!kill[dut.mtag_q[dl][4:0]]&&ref_credit[dl];
  end endgenerate
  integer old_lane;
  always @*begin
    ref_in_tag=0;ref_in_data=0;ref_in_age=0;
    for(old_lane=0;old_lane<2;old_lane=old_lane+1)if(ref_fire[old_lane])begin
      ref_in_tag[old_lane*9+:9]=dut.mtag_q[old_lane];
      ref_in_age[old_lane*DEPTH+:DEPTH]=dut.older_q[dut.mslot_q[old_lane]];
      ref_in_data[old_lane*DW+:DW]={
        dut.misaligned_q[dut.mslot_q[old_lane]],dut.class_q[dut.mslot_q[old_lane]],
        dut.amo_q[dut.mslot_q[old_lane]],dut.mask_q[dut.mslot_q[old_lane]],
        dut.func_q[dut.mslot_q[old_lane]],dut.store_q[dut.mslot_q[old_lane]],
        dut.pa_q[dut.mslot_q[old_lane]],dut.mslot_q[old_lane]};
    end
  end
  R64LsuRequestQueue #(.PREPARED_CANCEL(CORE_MODE),.DATA_W(DW),.TAG_W(9),.ROB_W(5),.AGE_W(DEPTH)) old_queue(
 .out_occupied_o(),
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(1'b1),
    .in_fire_i(ref_fire),.in_ready_o(ref_credit),.in_tag_i(ref_in_tag),.in_data_i(ref_in_data),
    .in_age_i(ref_in_age),.age_clear_i(dut.source_birth_w),.out_age_o(ref_age),.held_age_o(ref_held),
    .out_valid_o(ref_valid),.out_ready_i(dut.descriptor_pop_w),.out_tag_o(ref_tag),.out_data_o(ref_data),
    .reuse_block_o(ref_reuse),.idle_o(ref_idle));
  integer accepted[0:1],held_cycles=0,replacements=0,killed_with_credit=0,flush_occupied=0,prewrite_differences=0;
  reg baseline=0;
  always @(posedge clk)if(!rst)begin
    if({ref_credit,ref_valid,ref_fire,ref_reuse,ref_idle,ref_held}!==
       {dut.descriptor_credit_w,dut.descriptor_valid_w,dut.descriptor_queue_fire_w,
        dut.descriptor_reuse_w,dut.descriptor_idle_w,dut.unused_descriptor_held_age_w})
      $fatal(1,"descriptor control/owner differs from gated reference");
    for(integer dc=0;dc<2;dc=dc+1)begin
      if(ref_valid[dc]&&
         {ref_tag[dc*9+:9],ref_data[dc*DW+:DW],ref_age[dc*DEPTH+:DEPTH]}!==
         {dut.descriptor_tag_w[dc*9+:9],dut.descriptor_data_w[dc*DW+:DW],dut.descriptor_age_w[dc*DEPTH+:DEPTH]})
        $fatal(1,"valid descriptor tag/data/age differs from gated reference");
      if(ref_fire[dc])accepted[dc]=accepted[dc]+1;
      if(ref_valid[dc]&&!dut.descriptor_pop_w[dc])held_cycles=held_cycles+1;
      if(ref_fire[dc]&&ref_valid[dc]&&dut.descriptor_pop_w[dc])replacements=replacements+1;
      if(dut.mvalid_q[dc]&&ref_credit[dc]&&kill[dut.mtag_q[dc][4:0]])killed_with_credit=killed_with_credit+1;
      if(!ref_fire[dc]&&(^dut.descriptor_in_data_w[dc*DW+:DW])!==1'bx&&
         dut.descriptor_in_data_w[dc*DW+:DW]!=0)prewrite_differences=prewrite_differences+1;
    end
    if(flush&&(!ref_idle||dut.mvalid_q!=0))flush_occupied=flush_occupied+1;
  end
  integer n,wave,victim0,victim1,limit;reg [8:0] base;
  initial begin
    baseline=$test$plusargs("baseline");accepted[0]=0;accepted[1]=0;
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    clear_observations();
    repeat(4)@(negedge clk);rst=0;head_valid=0;effect_allow=0;
    for(wave=0;wave<2;wave=wave+1)begin
      base=9'(wave*32);mem_hold=1;
      reserve_one(0,base,8'h23,0);bind_one(0,base,64'h80,64'hfeedface,8'h23,0,0);
      wait(dut.state_q[saved_slot[0]]==3);
      for(n=1;n<=14;n=n+1)reserve_one(n%2,base+9'(n),8'h03,0);
      for(n=1;n<=14;n=n+2)bind_pair(base+9'(n),base+9'(n+1),64'h100+64'(n*8),64'h108+64'(n*8));
      repeat(16)@(negedge clk);
      if(dut.descriptor_credit_w!=0||dut.query_credit_w!=0||dut.mvalid_q!=3)
        $fatal(1,"descriptor/query/holder full case not reached");
      if(wave==1)begin
        clear_all();mem_hold=0;
      end else begin
        // Cancel a holder while both descriptor queues are full.
        victim0=int'(dut.mtag_q[0][4:0]);kill=32'b1<<victim0;killed[victim0]=1;active[victim0]=0;
        @(negedge clk);kill=0;
        mem_hold=0;limit=0;
        // Cancel another valid holder exactly when free descriptor credit
        // would otherwise admit it. Data may prewrite, but valid must not.
        @(negedge clk);
        while((dut.mvalid_q&dut.descriptor_credit_w)==0&&limit<40)begin @(negedge clk);limit=limit+1;end
        if(limit==40)$fatal(1,"kill with descriptor credit not reached");
        if(dut.mvalid_q[0]&&dut.descriptor_credit_w[0])victim1=int'(dut.mtag_q[0][4:0]);
        else victim1=int'(dut.mtag_q[1][4:0]);
        kill=32'b1<<victim1;killed[victim1]=1;active[victim1]=0;
        @(negedge clk);kill=0;
        for(n=1;n<=14;n=n+1)if(n!=victim0&&n!=victim1)wait_result(n[4:0]);
        repeat(4)@(negedge clk);
        if(received[victim0]||received[victim1])$fatal(1,"killed holder completed");
        clear_all();
      end
    end
    // Fresh generations after flushing full queues must use the new payload.
    reserve_one(0,64,8'h23,0);bind_one(0,64,64'h80,64'hf00d1234,8'h23,0,0);
    wait(dut.state_q[saved_slot[0]]==3);
    reserve_one(0,65,8'h03,0);reserve_one(1,66,8'h03,0);
    bind_pair(65,66,64'h180,64'h188);wait_result(1);wait_result(2);clear_all();
    if(accepted[0]<4||accepted[1]<4||held_cycles==0||replacements==0||killed_with_credit==0||flush_occupied==0)
      $fatal(1,"descriptor coverage missing lanes/hold/replace/kill/flush");
    if(!baseline&&prewrite_differences==0)$fatal(1,"raw invalid payload difference was not exercised");
    $display("DESCRIPTOR_PAYLOAD depth=%0d core_mode=%0d baseline=%0d accepted0=%0d accepted1=%0d held=%0d replace=%0d killed_credit=%0d flush_occupied=%0d invalid_nonzero=%0d",
      DEPTH,CORE_MODE,baseline,accepted[0],accepted[1],held_cycles,replacements,killed_with_credit,flush_occupied,prewrite_differences);
    $display("[PASS] tb_r64_lsu_descriptor_payload valid equivalence, dual lanes, full, replace, kill, flush, generation and data");
    $finish;
  end
  initial begin #300000;$fatal(1,"descriptor payload timeout");end
endmodule
