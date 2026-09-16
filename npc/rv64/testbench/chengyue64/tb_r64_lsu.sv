`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu;
 parameter DEPTH=18;parameter EARLY_STORE=0;localparam IW=$clog2(DEPTH);
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
  reg head_preparation_seen=0;reg late_io_observe=0;integer late_io_ready_cycles=0;
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
    if(late_io_observe)begin
      for(integer lio=0;lio<2;lio=lio+1)begin
        if(dut.query_fire_w[lio]&&dut.query_in_tag_w[lio*9+:9]!=0)
          $fatal(1,"younger query published across unresolved/IO owner");
        if(mv[lio]&&dut.tag_q[mtoken[lio*IW+:IW]]!=0)
          $fatal(1,"younger physical request passed pending IO");
      end
      for(integer lor=1;lor<DEPTH;lor=lor+1)
        if(dut.state_q[0]==2&&dut.state_q[lor]==3)late_io_ready_cycles=late_io_ready_cycles+1;
    end
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
  // Independent payload oracle for the one-edge prepared descriptor path.
  // Read the canonical selected row, not the implementation's onehot mux.
  integer prepared_captures=0;
  reg prepared_check_q=0;
  reg [8:0] prepared_expected_tag_q;
  reg [IW-1:0] prepared_expected_slot_q;
  reg [IW+151:0] prepared_expected_payload_q;
  always @(posedge clk)begin
    prepared_check_q<=!rst&&dut.prepared_capture_w;
    if(!rst&&dut.prepared_capture_w)begin
      prepared_captures=prepared_captures+1;
      prepared_expected_slot_q<=dut.prepared_capture_slot_w;
      prepared_expected_tag_q<=dut.tag_q[dut.prepared_capture_slot_w];
      prepared_expected_payload_q<=
        {dut.misaligned_q[dut.prepared_capture_slot_w],dut.class_q[dut.prepared_capture_slot_w],
         dut.amo_q[dut.prepared_capture_slot_w],dut.mask_q[dut.prepared_capture_slot_w],
         dut.func_q[dut.prepared_capture_slot_w],dut.store_q[dut.prepared_capture_slot_w],
         dut.pa_q[dut.prepared_capture_slot_w],dut.prepared_capture_slot_w};
    end
  end
  always @(negedge clk)if($test$plusargs("prepared-capture")&&prepared_check_q)begin
    if(!dut.prepared_valid_q||!dut.prepared_payload_valid_q||
       dut.prepared_slot_q!==prepared_expected_slot_q||dut.prepared_tag_q!==prepared_expected_tag_q||
       dut.prepared_payload_q!==prepared_expected_payload_q)
      $fatal(1,"prepared descriptor not ready with exact owner at capture edge");
  end
  integer n,before_mem,before_tr,issued,retired,start_cycle,stream_cycles;
  initial begin
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4)@(negedge clk);rst=0;
    // Late physical classification must not let younger ordinary descriptors
    // block the precise head request which releases their ordering barrier.
    if($test$plusargs("late-io"))begin
      head_tag=0;mem_hold=1;tr_delay=1;mem_delay=1;delay_owner=1;delayed_addr=64'he00;late_io_observe=1;
      enqueue(0,64'he00,0,8'h03,0,memory[448],0,0);
      for(n=1;n<17;n=n+1)enqueue(n[8:0],64'(n*8),0,8'h03,0,memory[n],0,0);
      repeat(100)@(negedge clk);
      // Unknown/IO ordering now keeps younger ready loads before publication.
      // Queue saturation belongs to the ordinary-RAM capacity tests.
      if(late_io_ready_cycles==0||mv==0||memcount!=0)
        $fatal(1,"late IO did not hold younger ready loads behind an offered head");
      mem_hold=0;progress_limit=0;
      while(!received[0]&&progress_limit<300)begin @(negedge clk);progress_limit=progress_limit+1;end
      if(!received[0])$fatal(1,"late IO blocked behind younger queued loads");
      retire(0);late_io_observe=0;head_tag=1;progress_limit=0;
      while(!idle&&progress_limit<300)begin @(negedge clk);progress_limit=progress_limit+1;end
      if(!idle||received[16:0]!=17'h1ffff)$fatal(1,"late IO release did not drain younger loads");
      $display("[PASS] tb_r64_lsu late IO blocks younger publication and releases all ready loads");$finish;
    end
    if($test$plusargs("late-special"))begin
      if(!EARLY_STORE)$fatal(1,"late-special fixture requires EARLY_STORE=1");
      trigger_test=1;head_tag=0;mem_hold=1;tr_hold=1;tr_delay=1;mem_delay=1;
      head_addr=64'he00;head_func=8'h03;head_amo=0;
      if($test$plusargs("late-amo"))begin head_addr=64'h200;head_func=8'h83;head_amo=2;end
      if($test$plusargs("late-split"))head_addr=64'h201;
      delay_owner=1;delayed_addr=head_addr;before_mem=memcount;
      // Make both owners eligible together so each translation lane receives
      // one request. Sequential enqueue may now put both in lane 0's two-slot
      // ingress and cannot exercise a younger result overtaking the delayed head.
      @(negedge clk);while(in_ready!=3)@(negedge clk);
      in_fire=3;in_tag={9'd1,9'd0};in_uop=0;operand=0;
      in_uop[196+:8]=head_func;in_uop[155+:5]=head_amo;
      operand[63:0]=head_addr;
      in_uop[`R64_UOP_W+196+:8]=8'h23;
      operand[192+:64]=64'h80;operand[256+:64]=64'hfeed;
      full_tag[0]=0;full_tag[1]=1;active=3;received=0;killed=0;
      expected[0]=memory[head_addr>>3];expected[1]=0;
      expectfault=0;expectcause[0]=0;expectcause[1]=0;
      expecttval[0]=head_addr;expecttval[1]=64'h80;
      @(negedge clk);in_fire=0;
      repeat(4)@(negedge clk);tr_hold=0;
      progress_limit=0;
      while(!(dut.prepared_valid_q&&dut.prepared_tag_q==1)&&progress_limit<40)begin
        @(negedge clk);progress_limit=progress_limit+1;
      end
      if(!dut.prepared_valid_q||dut.prepared_tag_q!=1)$fatal(1,"younger store was not prepared");
      repeat(100)@(negedge clk);
      if(memcount!=before_mem||memory[16]!==64'h1234567880000010)
        $fatal(1,"preempted prepared store escaped into external memory");
      if(!head_preparation_seen||dut.state_q[0]!=4)
        $fatal(1,"late head did not replace younger preparation");
      killed[1]=1;kill=32'hfffffffe;@(negedge clk);kill=0;mem_hold=0;
      progress_limit=0;
      while(!received[0]&&progress_limit<300)begin @(negedge clk);progress_limit=progress_limit+1;end
      if(!received[0])$fatal(1,"late head replacement made no progress");
      retire(0);head_tag=33;
      if(reuse[1])$fatal(1,"cancelled preempted store retained stale owner");
      delay_owner=0;enqueue(33,64'h80,0,8'h03,0,memory[16],0,0);
      progress_limit=0;while(!received[1]&&progress_limit<300)begin @(negedge clk);progress_limit=progress_limit+1;end
      if(!received[1])$fatal(1,"new generation after late head did not complete");
      progress_limit=0;
      while(!idle&&progress_limit<100)begin @(negedge clk);progress_limit=progress_limit+1;end
      if(!idle||memcount!=before_mem+2||memory[16]!==64'h1234567880000010)
        $fatal(1,"late head/store replacement duplicate or stale side effect");
      $display("[PASS] tb_r64_lsu late special preempted store cancel canonical reuse kind=%0h",head_func);$finish;
    end
    if($test$plusargs("trigger"))begin
      trigger_test=1;no_external=1;trigger_enable=3;trigger_address=64'he00;
      before_tr=trcount;before_mem=memcount;
      // Every width, including lowest-byte matching of unaligned RAM values.
      for(n=0;n<4;n=n+1)begin
        head_tag=n[8:0];enqueue(n[8:0],64'he00,0,{6'b0,n[1:0]},0,0,1,3);wait_result(n[4:0]);
        head_tag=9'(n+4);enqueue(9'(n+4),64'he00,64'hfeed,{6'b001000,n[1:0]},0,0,1,3);wait_result(5'(n+4));
      end
      trigger_enable=1;head_tag=8;enqueue(8,64'he00,0,8'h83,2,0,1,3);wait_result(8);
      trigger_enable=2;head_tag=9;enqueue(9,64'he00,0,8'h83,3,0,1,3);wait_result(9);
      head_tag=10;enqueue(10,64'he00,0,8'h83,0,0,1,3);wait_result(10);
      trigger_enable=1;head_tag=11;enqueue(11,64'he00,0,8'h83,0,0,1,3);wait_result(11);
      trigger_address=3;trigger_enable=3;head_tag=12;
      enqueue(12,3,0,8'h83,2,0,1,3);wait_result(12); // trigger outranks atomic alignment
      fp_enable=0;head_tag=13;enqueue(13,3,0,8'h43,0,0,1,2);
      expecttval[13]=0;wait_result(13);fp_enable=1; // illegal FS priority
      // Kill a local exception holder before completion, then reuse exact ROB slot with a new generation.
      trigger_address=64'hd00;out_ready=0;head_tag=14;enqueue(14,64'hd00,0,8'h23,0,0,1,3);
      kill=32'h4000;killed[14]=1;repeat(3)@(negedge clk);kill=0;
      head_tag=46;enqueue(46,64'hd00,0,8'h23,0,0,1,3);
      repeat(12)@(negedge clk);out_ready=3;wait_result(14);
      // Flush a held completed AMO exception; it must not resurrect on release.
      out_ready=0;head_tag=15;enqueue(15,64'hd00,0,8'h83,0,0,1,3);
      while(out_valid==0)@(negedge clk);
      flush=1;killed[15]=1;@(negedge clk);flush=0;out_ready=3;
      repeat(5)@(negedge clk);
      if(trcount!=before_tr||memcount!=before_mem||adupdates!=0)$fatal(1,"trigger had an external side effect");
      // Nonmatching address and execute-only configuration retain ordinary memory behavior.
      no_external=0;trigger_enable=4;trigger_address=0;head_tag=16;
      enqueue(16,0,0,8'h03,0,memory[0],0,0);wait_result(16);
      trigger_enable=1;trigger_address=1;head_tag=17;
      enqueue(17,0,0,8'h03,0,memory[0],0,0);wait_result(17);
      // LR must ignore store qualification, SC must ignore load qualification.
      tr_hold=1;trigger_address=0;trigger_enable=2;head_tag=18;
      enqueue(18,0,0,8'h83,2,0,0,0);
      while(tv==0)@(negedge clk);
      flush=1;killed[18]=1;@(negedge clk);flush=0;
      trigger_enable=1;head_tag=19;enqueue(19,0,0,8'h83,3,0,0,0);
      while(tv==0)@(negedge clk);
      flush=1;killed[19]=1;@(negedge clk);flush=0;
      $display("[PASS] tb_r64_lsu trigger load/store/LR/SC/AMO priority cancel generation hold no-side-effects wb=%0d",wbcount);$finish;
    end
    if($test$plusargs("fast-response"))mem_delay=0;
    if($test$plusargs("bad-owner"))begin bad_response=1;repeat(3)@(negedge clk);$fatal(1,"bad response escaped owner assertion");end
    if($test$plusargs("bad-store-cancel"))begin
      tr_hold=1;head_tag=31;
      enqueue(0,0,64'h55,8'h23,0,0,0,0);
      enqueue(1,0,0,8'h03,0,64'h55,0,0);
      kill=1;repeat(3)@(negedge clk);
      $fatal(1,"older store cancellation escaped consumer contract assertion");
    end
    if($test$plusargs("metadata-hold"))begin
      if(DEPTH!=2)$fatal(1,"metadata-hold requires DEPTH=2");
      out_ready=0;tr_delay=1;mem_delay=1;
      // Eight canonical results must survive repeated reuse of only two LSQ
      // entries. CQ and response holder retain all consumed metadata under WB
      // stall; later allocation overwrites the original per-entry arrays.
      for(n=0;n<8;n=n+1)enqueue(n[8:0],64'(n*8),0,8'h03,0,memory[n],0,0);
      repeat(30)@(negedge clk);
      if(wbcount!=0||dut.raw_valid_w==0||dut.response_queue.reuse_block_o==0)
        $fatal(1,"metadata holder did not retain blocked canonical completions");
      if(dut.tag_q[0]<4||dut.tag_q[1]<4)
        $fatal(1,"metadata test failed to reuse physical LSQ entries");
      out_ready=3;
      while(wbcount<8)@(negedge clk);
      repeat(5)@(negedge clk);
      if(!idle||reuse!=0)$fatal(1,"metadata completion/reuse drain leaked");
      $display("[PASS] tb_r64_lsu eight held results survive two-entry LSQ reuse");
      $finish;
    end
    if($test$plusargs("prepared-hold"))begin
      if(!EARLY_STORE)$fatal(1,"prepared-hold requires EARLY_STORE=1");
      head_tag=0;mem_hold=1;
      enqueue(1,64'h80,64'h1234,8'h23,0,0,0,0);
      repeat(12)@(negedge clk);
      if(!dut.prepared_valid_q)$fatal(1,"prepared owner missing");
      enqueue(2,0,0,8'h03,0,memory[0],0,0);
      head_tag=1;
      repeat(20)@(negedge clk);
      if(!mv[0]||dut.tag_q[mtoken[0+:IW]]!=1||memcount!=0)
        $fatal(1,"prepared owner replaced or accepted under held ready");
      flush=1;killed=6;@(negedge clk);flush=0;
      repeat(4)@(negedge clk);
      if(!idle||reuse!=0||irreversible)$fatal(1,"unissued prepared owner leaked");
      $display("[PASS] tb_r64_lsu prepared-store offer held across younger translation/selection");
      $finish;
    end
    enqueue(0,0,0,8'h03,0,memory[0],0,0);wait_result(0);retire(0);
    enqueue(1,4,0,8'h02,0,64'h12345678,0,0);wait_result(1);retire(1);
    enqueue(2,0,0,8'h02,0,64'hffffffff80000000,0,0);wait_result(2);retire(2);
    enqueue(3,0,0,8'h42,0,64'hffffffff80000000,0,0);wait_result(3);retire(3);
    enqueue(4,3,0,8'ha3,2,0,1,4);wait_result(4);retire(4);
    enqueue(5,64'hf00,0,8'h03,0,0,1,13);wait_result(5);retire(5);
    // Unknown-head store translates early but cannot touch physical memory.
    head_tag=6;before_mem=memcount;
    enqueue(7,64'h1000,64'haabbccdd,8'h22,0,0,0,0);
    enqueue(8,0,0,8'h06,0,64'haabbccdd,0,0);
    wait_result(8);
    if(memcount!=before_mem)$fatal(1,"forwarded load or unauthorized store touched memory");
    head_tag=7;wait_result(7);
    if(!irreversible)$fatal(1,"visible store lost retirement owner before commit");
    retire(7);retire(8);head_tag=9;
    if(irreversible)$fatal(1,"retired store owner leaked");
    // Partial byte forwarding merges cache response with the youngest store.
    head_tag=9;
    enqueue(10,1,64'h77,8'h20,0,0,0,0);
    enqueue(11,0,0,8'h03,0,64'h12345678aabb77dd,0,0);
    wait_result(11);head_tag=10;wait_result(10);retire(10);retire(11);
    // Store A/D probe cannot mutate until it becomes head.
    head_tag=12;before_tr=adupdates;
    enqueue(13,64'hd00,64'h1122,8'h23,0,0,0,0);
    repeat(12)@(negedge clk);
    if(adupdates!=before_tr||received[13])$fatal(1,"speculative store updated D");
    head_tag=13;wait_result(13);
    if(adupdates!=before_tr+1)$fatal(1,"head store did not rewalk for D");
    retire(13);
    // IO read waits at the precise head boundary.
    head_tag=14;before_mem=memcount;
    enqueue(15,64'he00,0,8'h03,0,memory[448],0,0);
    repeat(12)@(negedge clk);if(memcount!=before_mem)$fatal(1,"speculative IO read");
    head_tag=15;wait_result(15);retire(15);
    // Error completion drains its owner and may enter synchronous trap.
    head_tag=16;error_write=1;
    enqueue(16,64'h80,64'hcc,8'h23,0,0,1,7);wait_result(16);
    if(irreversible)$fatal(1,"error result blocks synchronous trap");
    @(negedge clk);flush=1;killed[16]=1;@(negedge clk);flush=0;error_write=0;active=0;received=0;
    // A killed accepted translation remains a reuse blocker until response.
    head_tag=17;tr_delay=30;before_tr=trcount;
    enqueue(17,64'h100,0,8'h03,0,memory[32],0,0);
    wait(trcount>before_tr);repeat(4)@(negedge clk);
    kill=32'h20000;killed[17]=1;@(negedge clk);kill=0;
    if(!reuse[17])$fatal(1,"cancelled translation owner released early");
    while(reuse[17])@(negedge clk);tr_delay=2;active[17]=0;
    // A killed accepted physical load drains and suppresses WB.
    head_tag=18;mem_delay=30;before_mem=memcount;
    enqueue(18,64'h180,0,8'h03,0,memory[48],0,0);
    wait(memcount>before_mem);@(negedge clk);kill=32'h40000;killed[18]=1;
    @(negedge clk);kill=0;if(!reuse[18])$fatal(1,"cancelled physical owner released early");
    while(reuse[18])@(negedge clk);active[18]=0;mem_delay=3;
    repeat(5)@(negedge clk);
    if(!idle||reuse!=0)$fatal(1,"owner leak %h",reuse);
    // FS=Off rejects both FP memory classes before even translation, with
    // illegal-instruction precedence over address misalignment.
    fp_enable=0;before_tr=trcount;before_mem=memcount;head_tag=19;
    enqueue(19,3,0,8'h43,0,0,1,2);expecttval[19]=0;wait_result(19);retire(19);
    head_tag=20;enqueue(20,3,64'h1,8'h63,0,0,1,2);expecttval[20]=0;wait_result(20);retire(20);
    if(trcount!=before_tr||memcount!=before_mem)$fatal(1,"FS-Off memory side effect");
    fp_enable=1;
    // A younger load must not offer before an older store's D-bit rewalk,
    // then its first physical offer must remain stable under held ready.
    head_tag=20;mem_hold=1;
    enqueue(21,64'hd00,64'h3344,8'h23,0,0,0,0);
    enqueue(22,0,0,8'h03,0,memory[0],0,0);
    repeat(12)@(negedge clk);
    if(mv!=0||received[22])$fatal(1,"load crossed unresolved store A/D barrier");
    tr_delay=8;head_tag=21;
    while(mv==0)@(negedge clk);
    repeat(12)@(negedge clk);
    mem_hold=0;tr_delay=2;
    wait_result(21);wait_result(22);retire(21);retire(22);
    // Fill completion and physical-response holders under WB backpressure;
    // kill one load while responses are blocked, then drain unevenly.
    head_tag=0;active=0;received=0;killed=0;expectfault=0;out_ready=0;
    for(n=0;n<16;n=n+1)enqueue(n[8:0],(n%2)*8,0,8'h03,0,memory[n%2],0,0);
    repeat(12)@(negedge clk);
    kill=32'h4000;killed=kill;@(negedge clk);kill=0;
    out_ready=1;repeat(7)@(negedge clk);out_ready=2;repeat(7)@(negedge clk);out_ready=3;
    while((received&32'hbfff)!=32'hbfff)@(negedge clk);
    repeat(4)@(negedge clk);
    if(received[14]||!idle||reuse!=0)$fatal(1,"backpressure/cancel owner leak");
    // Fixed 512-load stream: identical oracle/config except explicit LSQ depth A/B.
    head_tag=0;active=0;received=0;killed=0;expectfault=0;
    tr_delay=1;mem_delay=1;issued=0;retired=0;start_cycle=cycles;
    while(retired<512)begin
      @(negedge clk);
      while(retired<issued&&received[retired%32])begin
        active[retired%32]=0;received[retired%32]=0;retired=retired+1;
      end
      head_tag=retired[8:0];in_fire=0;in_uop=0;operand=0;in_tag=0;
      if(issued<512&&issued-retired<30&&in_ready[0])begin
        in_fire[0]=1;in_tag[0+:9]=issued[8:0];in_uop[196+:8]=8'h03;
        active[issued%32]=1;expected[issued%32]=memory[0];issued=issued+1;
        if(issued<512&&issued-retired<30&&in_ready[1])begin
          in_fire[1]=1;in_tag[9+:9]=issued[8:0];in_uop[`R64_UOP_W+196+:8]=8'h03;
          active[issued%32]=1;expected[issued%32]=memory[0];issued=issued+1;
        end
      end
    end
    in_fire=0;stream_cycles=cycles-start_cycle;
    if(!idle)$fatal(1,"stream owner not released");
    $display("LSU_STREAM depth=%0d instructions=512 cycles=%0d IPC=%f",DEPTH,stream_cycles,512.0/stream_cycles);
    if($test$plusargs("prepared-capture"))begin
      if(prepared_captures==0)$fatal(1,"prepared capture check was vacuous");
      $display("LSU_PREPARED_CAPTURE checked=%0d",prepared_captures);
    end
    $display("[PASS] tb_r64_lsu completions=%0d translations=%0d physical=%0d dual_wb=%0d",wbcount,trcount,memcount,dual);
    $finish;
  end
  initial begin #1000000;$fatal(1,"timeout cycles%0d reuse%h received%h",cycles,reuse,received);end
endmodule
