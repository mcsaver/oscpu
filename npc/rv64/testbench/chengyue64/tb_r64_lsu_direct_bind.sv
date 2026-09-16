`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu_direct_bind;
 parameter EARLY_STORE=1;parameter DEPTH=20;localparam IW=$clog2(DEPTH);
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;reg [31:0] kill=0;
  reg head_valid=1,effect_allow=1,fp_enable=1;reg [8:0] head_tag=0;
  reg [1:0] commit_fire=0;reg [17:0] commit_tag=0;
  reg [1:0] in_fire=0;wire [1:0] in_ready;
  reg [17:0] in_tag=0;reg [2*`R64_UOP_W-1:0] in_uop=0;reg [383:0] operand=0;
  wire store_valid,store_error;reg store_ready=1;wire [8:0] store_tag;wire [63:0] store_tval;integer fast_completions=0;
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
  R64LoadStore #(.EARLY_STORE(EARLY_STORE),.ENTRIES(DEPTH),.INDEX_W(IW),.CACHE_SET_W(2)) dut(
   .clk_i(clk),.rst_i(rst),.flush_i(flush),.invalidate_i(1'b0),.kill_mask_i(kill),
   .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),.trigger_enable_i(3'b0),.trigger_address_i(64'b0),.fp_enable_i(fp_enable),.translate_active_i(1'b0),
   .store_done_valid_o(store_valid),.store_done_ready_i(store_ready),.store_done_tag_o(store_tag),.store_done_error_o(store_error),.store_done_tval_o(store_tval),
   .commit_fire_i(commit_fire),.commit_tag_i(commit_tag),
   .reserve_want_i(2'b11),.reserve_fire_i(in_fire),.reserve_ready_o(in_ready),.reserve_slot_o(reserve_slot_w),
   .reserve_tag_i(in_tag),.reserve_func_i({in_uop[`R64_UOP_W+196+:8],in_uop[196+:8]}),
   .reserve_amo_i({in_uop[`R64_UOP_W+155+:5],in_uop[155+:5]}),
   .in_fire_i({bind_fire_q[0],bind_fire_q[1]}),.in_ready_o(),.in_tag_i({bind_tag_q[8:0],bind_tag_q[17:9]}),.in_slot_i({bind_slot_q[0+:IW],bind_slot_q[IW+:IW]}),
   .in_uop_i({bind_uop_q[0+:`R64_UOP_W],bind_uop_q[`R64_UOP_W+:`R64_UOP_W]}),.in_operand_i({bind_operand_q[191:0],bind_operand_q[383:192]}),
   .out_valid_o(out_valid),.out_ready_i(out_ready),.out_tag_o(out_tag),.out_result_o(out_result),
   .reuse_block_o(reuse),.irrevocable_o(irreversible),.idle_o(idle),
   .tr_valid_o(tv),.tr_ready_i(tr),.tr_vaddr_o(tva),.tr_access_o(ta),.tr_ad_update_o(tad),
   .tr_rsp_valid_i(tresp),.tr_rsp_ready_o(trespready),.tr_paddr_i(tpa),.tr_class_i(tc),
   .tr_fault_i(tfault),.tr_needs_ad_i(tneeds),.tr_cause_i(tcause),
   .tr_owner_access_o(towneraccess),.tr_owner_size_o(townersize),
   .aux_valid_i(4'b0),.aux_ready_o(),.aux_addr_i(256'b0),.aux_data_i(256'b0),.aux_expected_i(256'b0),
   .aux_op_i(8'b0),.aux_cache_i(4'b0),.aux_size_i(12'b0),.aux_strb_i(32'b0),
   .aux_rsp_valid_o(),.aux_rsp_ready_i(4'b1111),.aux_rsp_data_o(),.aux_rsp_error_o(),.aux_rsp_compare_o(),
   .read_valid_o(rv),.read_ready_i(rr),.read_addr_o(ra),.read_len_o(rl),.read_size_o(rz),
   .beat_valid_i(bv),.beat_ready_o(br),.beat_data_i(bd),.beat_resp_i(2'b0),.beat_last_i(left==1),
   .write_valid_o(wv),.write_ready_i(wr),.write_addr_o(wa),.write_size_o(wz),
   .write_data_valid_o(wdv),.write_data_ready_i(wdr),.write_data_o(wd),.write_strb_o(ws),
   .write_rsp_valid_i(bvalid&&!b_hold),.write_rsp_ready_o(bready_raw),.write_resp_i(bresp));
  wire rv,rr,bv,br,wv,wr,wdv,wdr,bready;wire [63:0] ra,wa,wd,bd;wire [7:0] rl,ws;wire [2:0] rz,wz;
  wire bready_raw;reg b_hold=0;assign bready=bready_raw&&!b_hold;
  reg reading=0,aw=0,ww=0,bvalid=0;reg [1:0] bresp=0;
  integer ri=0,left=0,wi=0,read_due=0,read_txns=0;
  reg [63:0] wdata;reg [7:0] wstrb;
  assign rr=!reading;assign bv=reading&&cycles>=read_due;assign bd=memory[ri];
  assign wr=!aw&&!bvalid;assign wdr=!ww&&!bvalid;
  assign mv=dut.mv;assign mr=dut.mr;
  always @(posedge clk)if(!rst)begin
    if(bv&&br)begin ri<=ri+1;left<=left-1;if(left==1)reading<=0;end
    if(rv&&rr)begin reading<=1;ri<=ra>>3;left<=rl+1;read_due<=cycles+mem_delay;read_txns=read_txns+1;end
    if(wv&&wr)begin aw=1;wi=wa>>3;end
    if(wdv&&wdr)begin ww=1;wdata=wd;wstrb=ws;end
    if(aw&&ww&&!bvalid)begin
      bvalid<=1;bresp<=error_write?2:0;
      if(!error_write)for(integer byte_n=0;byte_n<8;byte_n=byte_n+1)
        if(wstrb[byte_n])memory[wi][8*byte_n+:8]=wdata[8*byte_n+:8];
    end
    if(bvalid&&bready)begin aw=0;ww=0;bvalid<=0;end
  end
  reg [63:0] memory[0:1023],expected[0:31];reg [31:0] active=0,killed=0,received=0;
  reg [31:0] expectfault=0;reg [5:0] expectcause[0:31];reg [63:0] expecttval[0:31];
  reg [63:0] tqueue[0:15];reg [1:0] taqueue[0:15];reg adqueue[0:15];
  integer tdue[0:15],th[0:1],tt[0:1],tn[0:1];
  reg [IW-1:0] mqtoken[0:15];reg [63:0] mqdata[0:15];
  reg mqerror[0:15];integer mdue[0:15],mh[0:1],mt[0:1],mn[0:1];
  integer cycles=0,trcount=0,memcount=0,wbcount=0,dual=0,adupdates=0;
  integer tr_delay=2,mem_delay=3;
  reg tr_hold=0,mem_hold=0,error_write=0;
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
  end endgenerate
  integer a,b,tag,index,j,slot;
  reg [63:0] response_data;
  always @(posedge clk)if(!rst)begin
    cycles=cycles+1;rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
    for(a=0;a<2;a=a+1)begin
      // Queue outputs must remain the accepted owner through the sampling edge.
      tn[a]<=tn[a]+((tv[a]&&tr[a])?1:0)-((tresp[a]&&trespready[a])?1:0);
      if(tresp[a]&&trespready[a])th[a]<=(th[a]+1)%8;
      if(tv[a]&&tr[a])begin
        tqueue[a*8+tt[a]]=tva[a*64+:64];taqueue[a*8+tt[a]]=ta[a*2+:2];adqueue[a*8+tt[a]]=tad[a];
        tdue[a*8+tt[a]]=cycles+tr_delay;tt[a]<=(tt[a]+1)%8;trcount=trcount+1;
        if(tad[a]&&ta[a*2+:2]==2)adupdates=adupdates+1;
      end
      if(mv[a]&&mr[a])memcount=memcount+1;
      if(out_valid[a]&&out_ready[a])begin
        tag=out_tag[a*9+:5];
        if(!active[tag]||killed[tag]||received[tag])$fatal(1,"invalid completion tag %0d active%h killed%h received%h",tag,active,killed,received);
        if(out_result[a*`R64_RESULT_W+64]!==expectfault[tag]||
          (!expectfault[tag]&&out_result[a*`R64_RESULT_W+:64]!==expected[tag])||
          (expectfault[tag]&&(out_result[a*`R64_RESULT_W+65+:6]!==expectcause[tag]||
            out_result[a*`R64_RESULT_W+71+:64]!==expecttval[tag])))
          $fatal(1,"bad result tag%0d value%h expected%h exception%b",tag,out_result[a*`R64_RESULT_W+:64],expected[tag],out_result[a*`R64_RESULT_W+64]);
        received[tag]=1;wbcount=wbcount+1;
      end
    end
    if(store_valid&&store_ready)begin
      tag=store_tag[4:0];
      if(!active[tag]||killed[tag]||received[tag]||store_tag!=head_tag)
        $fatal(1,"invalid narrow store completion tag%0d",store_tag);
      if(store_error!==expectfault[tag]||(!store_error&&expected[tag]!=0)||
        (store_error&&(expectcause[tag]!=7||store_tval!==expecttval[tag])))
        $fatal(1,"narrow store completion payload tag%0d",store_tag);
      received[tag]=1;wbcount=wbcount+1;fast_completions=fast_completions+1;
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
  integer n,before_mem,before_tr,issued,retired,start_cycle,stream_cycles;
  initial begin
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4)@(negedge clk);rst=0;
    if($test$plusargs("source-pin"))begin
      for(n=0;n<3;n=n+1)begin
        head_tag=9'(4*n);out_ready=3;
        enqueue(9'(4*n),n==1?64'd1:64'd0,n==1?64'ha5:64'hfeedface12345678,
          n==1?8'h20:8'h23,0,0,0,0);
        wait_result(5'(4*n));
        out_ready=0;
        enqueue(9'(4*n+1),0,0,8'h03,0,memory[0],0,0);
        wait(dut.lsu.query_fire_w!=0);
        @(negedge clk);commit_fire=1;commit_tag={9'b0,9'(4*n)};
        @(negedge clk);commit_fire=0;active[4*n]=0;
        if(dut.lsu.state_q[0]!=6||dut.lsu.alive_q[0]||dut.lsu.effect_q[0]||!reuse[4*n])
          $fatal(1,"committed source not pinned across winner capture");
        if(n==2)begin
          flush=1;killed[4*n+1]=1;@(negedge clk);flush=0;
          repeat(6)@(negedge clk);
          if(!idle||reuse!=0||received[4*n+1])
            $fatal(1,"flush failed to cancel pinned query without completion");
        end else begin
          repeat(6)@(negedge clk);
          if(reuse[4*n]||dut.lsu.state_q[0]!=0)
            $fatal(1,"source pin survived completed data capture");
          // Reuse the source LSQ slot while its consumer still waits at WB.
          enqueue(9'(4*n+2),8,0,8'h03,0,memory[1],0,0);
          if(dut.lsu.tag_q[0]!=9'(4*n+2))
            $fatal(1,"source slot was not reused by independent load");
          out_ready=3;wait_result(5'(4*n+1));wait_result(5'(4*n+2));
          retire(9'(4*n+1));retire(9'(4*n+2));
          repeat(5)@(negedge clk);
          if(!idle||reuse!=0)$fatal(1,"source pin scenario owner leak");
        end
      end
      $display("[PASS] tb_r64_lsu_direct_bind source commit/winner capture, partial/full data, reuse under WB hold, flush");
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
    // Through the real shared physical owner, verify LR/SC and AMO.W
    // request decoding plus upper-word sign extension at LSU completion.
    head_tag=22;enqueue(22,4,0,8'ha2,2,64'h12345678,0,0);wait_result(22);retire(22);
    head_tag=23;enqueue(23,4,64'h800000ff,8'ha2,3,0,0,0);wait_result(23);retire(23);
    head_tag=24;enqueue(24,4,64'h7777,8'ha2,3,1,0,0);wait_result(24);retire(24);
    head_tag=25;enqueue(25,4,64'h1,8'ha2,0,64'hffffffff800000ff,0,0);wait_result(25);retire(25);
    if(memory[0]!==64'h80000100aabb77dd)$fatal(1,"coupled AMO word lane corruption");
    if(EARLY_STORE)begin
      // An unissued prepared descriptor is cancellable, and a later generation
      // of the same ROB slot must use its own descriptor and return identity.
      head_tag=25;before_mem=memcount;
      enqueue(26,64'h200,64'hbad,8'h23,0,0,0,0);
      repeat(12)@(negedge clk);
      if(!dut.lsu.prepared_valid_q||memcount!=before_mem)$fatal(1,"store preparation escaped authorization");
      kill=32'b1<<26;killed[26]=1;@(negedge clk);kill=0;
      repeat(3)@(negedge clk);
      if(reuse[26]||dut.lsu.prepared_valid_q)$fatal(1,"killed preparation owner leak");
      active[26]=0;head_tag=57;
      enqueue(58,64'h208,64'h123456789abcdef,8'h23,0,0,0,0);
      repeat(10)@(negedge clk);store_ready=0;b_hold=1;head_tag=58;
      while(!bvalid)@(negedge clk);
      repeat(9)begin
        if(store_valid||received[26]||!irreversible||!reuse[26])$fatal(1,"store retired without B");
        @(negedge clk);
      end
      b_hold=0;
      while(!store_valid)@(negedge clk);
      if($test$plusargs("bad-store-flush"))begin flush=1;@(negedge clk);$fatal(1,"missing irreversible flush assertion");end
      repeat(8)begin
        if(!store_valid||store_tag!=58||store_error||!reuse[26]||!irreversible||received[26])
          $fatal(1,"held narrow store lost terminal/retirement owner");
        @(negedge clk);
      end
      if(memory[65]!==64'h123456789abcdef)$fatal(1,"prepared replacement data/PA stale");
      store_ready=1;wait_result(26);retire(58);
      // A drained B error may be cancelled before consumer acceptance;
      // it must not retain irreversible state or reappear after trap flush.
      head_tag=59;error_write=1;store_ready=0;
      enqueue(59,64'h210,64'h7777,8'h23,0,0,1,7);
      while(!store_valid)@(negedge clk);
      if(!store_error||store_tval!=64'h210||irreversible)$fatal(1,"drained B error terminal contract");
      flush=1;@(negedge clk);flush=0;store_ready=1;error_write=0;active[27]=0;
      repeat(3)@(negedge clk);
      if(store_valid||reuse[27]||received[27])$fatal(1,"flushed B error resurrected");
    end
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
    if(EARLY_STORE)begin
      // A forwarded owner may wait for CQ credit while its source store
      // completes B and retires. The captured bytes/tag must remain stable across source removal;
      // an unrelated held physical response may coexist.
      head_tag=64;active=0;received=0;killed=0;expectfault=0;out_ready=3;
      enqueue(64,64'h500,64'hfedcba9876543210,8'h23,0,0,0,0);
      wait_result(0);out_ready=0;
      for(n=65;n<69;n=n+1)enqueue(n[8:0],8,0,8'h03,0,memory[1],0,0);
      for(n=0;n<64&&dut.lsu.completion_credit_w!=0;n=n+1)@(negedge clk);
      if(dut.lsu.completion_credit_w!=0)$fatal(1,"forward retirement test did not fill CQ");
      @(negedge clk);while(in_ready!=3)@(negedge clk);
      in_fire=3;in_tag={9'd70,9'd69};in_uop=0;operand=0;
      in_uop[196+:8]=8'h03;in_uop[`R64_UOP_W+196+:8]=8'h03;
      operand[0+:64]=8;operand[192+:64]=64'h500;
      active[5]=1;active[6]=1;expected[5]=memory[1];expected[6]=64'hfedcba9876543210;
      @(negedge clk);in_fire=0;
      for(n=0;n<64&&!dut.lsu.forward_valid_q[1];n=n+1)@(negedge clk);
      if(!dut.lsu.forward_valid_q[1])$fatal(1,"forward terminal not held behind CQ");
      head_tag=64;wait_result(0);retire(64);
      repeat(12)@(negedge clk);
      if(received[6]||memory[160]!==64'hfedcba9876543210)$fatal(1,"retired forward source visibility");
      out_ready=3;
      for(n=65;n<71;n=n+1)begin wait_result(n[4:0]);retire(n[8:0]);end
      repeat(4)@(negedge clk);
      if(!idle||reuse!=0)$fatal(1,"forward source retirement owner leak");
    end
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
        in_fire[0]=1;in_tag[0+:9]=issued[8:0];in_uop[196+:8]=8'h03;operand[0+:64]=(issued%2)*8;
        active[issued%32]=1;expected[issued%32]=memory[issued%2];issued=issued+1;
        if(issued<512&&issued-retired<30&&in_ready[1])begin
          in_fire[1]=1;in_tag[9+:9]=issued[8:0];in_uop[`R64_UOP_W+196+:8]=8'h03;operand[192+:64]=(issued%2)*8;
          active[issued%32]=1;expected[issued%32]=memory[issued%2];issued=issued+1;
        end
      end
    end
    in_fire=0;stream_cycles=cycles-start_cycle;
    if(!idle)$fatal(1,"stream owner not released");
    $display("LSU_CACHE_STREAM depth=%0d instructions=512 cycles=%0d IPC=%f",DEPTH,stream_cycles,512.0/stream_cycles);
    // Same prepared store ROI for EARLY_STORE=0/1. Consumer handshake is
    // measured here; the real ROB candidate also removes the generic WB stage.
    active=0;received=0;killed=0;expectfault=0;stream_cycles=0;
    for(n=0;n<16;n=n+1)begin
      head_tag=9'd255+n[8:0];
      enqueue(9'd256+n[8:0],64'h400+n*8,64'h12340000+n,8'h23,0,0,0,0);
      repeat(10)@(negedge clk);head_tag=9'd256+n[8:0];start_cycle=cycles;
      wait_result(n[4:0]);stream_cycles=stream_cycles+cycles-start_cycle;retire(9'd256+n[8:0]);
    end
    $display("LSU_STORE_ROI early=%0d stores=16 head_to_terminal_sum=%0d fast_completions=%0d",EARLY_STORE,stream_cycles,fast_completions);
    $display("[PASS] tb_r64_lsu_direct_bind completions=%0d translations=%0d physical=%0d dual_wb=%0d",wbcount,trcount,memcount,dual);
    $finish;
  end
  initial begin #1000000;$fatal(1,"timeout cycles%0d reuse%h received%h",cycles,reuse,received);end
endmodule
