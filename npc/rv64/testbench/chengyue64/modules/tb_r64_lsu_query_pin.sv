`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu_query_pin;
 parameter EARLY_STORE=1;localparam LOADS=6;parameter DEPTH=20;localparam IW=$clog2(DEPTH);
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
  R64LoadStore #(.HEAD_AUTHORIZED_QUERY(1),.PREPARED_CANCEL(1),.EARLY_STORE(EARLY_STORE),.ENTRIES(DEPTH),.INDEX_W(IW),.CACHE_SET_W(6),.AUX(3)) dut(
   .clk_i(clk),.rst_i(rst),.flush_i(flush),.invalidate_i(1'b0),.kill_mask_i(kill),.cancel_candidates_i(kill),.cancel_active_i(1'b1),
   .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),.trigger_enable_i(3'b0),.trigger_address_i(64'b0),.fp_enable_i(fp_enable),.translate_active_i(1'b0),
   .store_done_valid_o(store_valid),.store_done_ready_i(store_ready),.store_done_tag_o(store_tag),.store_done_error_o(store_error),.store_done_tval_o(store_tval),
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
   .aux_valid_i(3'b0),.aux_ready_o(),.aux_addr_i(192'b0),.aux_data_i(192'b0),.aux_expected_i(192'b0),
   .aux_op_i(6'b0),.aux_cache_i(3'b0),.aux_size_i(9'b0),.aux_strb_i(24'b0),
   .aux_rsp_valid_o(),.aux_rsp_ready_i(3'b111),.aux_rsp_data_o(),.aux_rsp_error_o(),.aux_rsp_compare_o(),
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


  integer n,lane_i,storage_i,byte_i,budget,free_slots,query_count,hold_cycles;
  integer load_query_captures=0,b_responses=0,commit_cycle,release_cycle,first_take_cycle=-1;
  integer first_load,free_at_commit,trace_file=0,commit_capture_events=0;string trace_path;
  reg observe=0,baseline=0,outside_mask=0,shadowed=0,referenced=0,retain_source=0,commit_capture=0,multiple=0;
  reg [DEPTH-1:0] winner_union,slot_winners,expected_winners;
  reg [63:0] source_addr,source_data,load_addr,load_answer;
  reg [7:0] source_fn,load_fn;
  always @(posedge clk)if(!rst)begin
    if(bvalid&&bready)b_responses=b_responses+1;
    for(integer qlane=0;qlane<2;qlane=qlane+1)begin
      if(dut.lsu.query_fire_w[qlane]&&dut.lsu.query_in_tag_w[qlane*9+:9]>=9'(first_load))
        load_query_captures=load_query_captures+1;
      if(commit_fire[0]&&dut.lsu.query_fire_w[qlane]&&
         dut.lsu.query_in_tag_w[qlane*9+:9]==9'(first_load+LOADS-1))commit_capture_events=commit_capture_events+1;
      if(observe&&dut.lsu.query_take_w[qlane]&&first_take_cycle<0)first_take_cycle=cycles;
    end
  end
  task sample_state;
    begin
      winner_union=0;free_slots=0;query_count=0;
      for(lane_i=0;lane_i<2;lane_i=lane_i+1)
        for(storage_i=0;storage_i<2;storage_i=storage_i+1)
          if(dut.lsu.forward_query.valid_q[lane_i][storage_i])begin
            slot_winners=0;query_count=query_count+1;
            for(byte_i=0;byte_i<8;byte_i=byte_i+1)
              slot_winners=slot_winners|dut.lsu.forward_query.data_q[lane_i][storage_i][byte_i*DEPTH+:DEPTH];
            winner_union=winner_union|slot_winners;
            if(!baseline&&dut.lsu.forward_query.age_q[lane_i][storage_i]!==slot_winners)
              $fatal(1,"saved query pins differ from actual byte references");
          end
      for(integer fs=0;fs<DEPTH;fs=fs+1)if(dut.lsu.state_q[fs]==0)free_slots=free_slots+1;
    end
  endtask
  task log_state;
    input [159:0] stage_name;
    begin
      sample_state();
      $display("QUERY_PIN stage=%0s cycle=%0d state=%0d alive=%0d effect=%0d reuse=%0d winner_union=%h query_pin=%h source_pin=%h descriptor_valid=%b query_count=%0d free_slots=%0d",
        stage_name,cycles,dut.lsu.state_q[0],dut.lsu.alive_q[0],dut.lsu.effect_q[0],reuse[0],
        winner_union,dut.lsu.query_held_pin_w,dut.lsu.source_pin_w,dut.lsu.descriptor_valid_w,query_count,free_slots);
    end
  endtask
  initial begin
    baseline=$test$plusargs("baseline");
    outside_mask=$test$plusargs("outside-mask");shadowed=$test$plusargs("shadowed");
    referenced=$test$plusargs("referenced");multiple=$test$plusargs("multi-source");
    retain_source=baseline||referenced||multiple;
    if(multiple&&(outside_mask||shadowed||referenced))$fatal(1,"select one forwarding case");
    if((outside_mask&&shadowed)||(referenced&&(outside_mask||shadowed)))$fatal(1,"select one forwarding case");
    commit_capture=$test$plusargs("commit-capture");
    if(commit_capture&&(outside_mask||shadowed||referenced||multiple))$fatal(1,"commit-capture uses nonalias case");
    first_load=(shadowed||multiple)?2:1;
    expected_winners=multiple?DEPTH'(3):(shadowed?DEPTH'(2):((referenced||(baseline&&outside_mask))?DEPTH'(1):DEPTH'(0)));
    if($value$plusargs("trace=%s",trace_path))begin
      trace_file=$fopen(trace_path,"w");if(trace_file==0)$fatal(1,"trace open failed");
      $fdisplay(trace_file,"cycle,store_state,store_alive,store_effect,store_reuse,winner_union,query_pin,source_pin,descriptor_valid,query_count,free_slots");
    end
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4)@(negedge clk);rst=0;
    source_addr=outside_mask?64'h87:((shadowed||referenced||multiple)?64'h81:64'h80);
    source_data=outside_mask?64'ha5:((shadowed||referenced||multiple)?64'h11:64'hfeedface12345678);
    source_fn=(outside_mask||shadowed||referenced||multiple)?8'h20:8'h23;
    // Real store B and narrow completion precede commit.
    enqueue(0,source_addr,source_data,source_fn,0,0,0,0);
    wait_result(0);@(negedge clk);
    if(dut.lsu.state_q[0]!=7||b_responses!=1)$fatal(1,"source store has not completed real B");
    if(shadowed||multiple)begin
      // Either replace source0's byte, or require both sources on distinct bytes.
      enqueue(1,multiple?64'h82:64'h81,64'ha5,8'h20,0,0,0,0);
      wait(dut.lsu.state_q[1]==3);
    end
    // Fill Service, both physical spill slots, and query before checking pins.
    // The last load must still own its uncaptured winners throughout the hold.
    mem_delay=120;
    for(n=0;n<LOADS;n=n+1)begin
      load_addr=(n==LOADS-1&&(outside_mask||shadowed||referenced||multiple))?64'h80:64'h100+64'(n*64);
      load_fn=(n==LOADS-1&&outside_mask)?8'h04:8'h03;
      load_answer=(n==LOADS-1&&outside_mask)?(memory[16]&64'hff):
        ((n==LOADS-1&&(shadowed||referenced||multiple))?(multiple?((memory[16]&~64'hffff00)|64'ha51100):((memory[16]&~64'hff00)|(shadowed?64'ha500:64'h1100))):memory[32+n*8]);
      enqueue(9'(first_load+n),load_addr,0,load_fn,0,load_answer,0,0);
    end
    if(commit_capture)begin
      // Arm at a settled clock phase, not a transient combinational tag.
      @(negedge clk);budget=0;
      while(!((dut.lsu.query_fire_w[0]&&dut.lsu.query_in_tag_w[0+:9]==9'(first_load+LOADS-1))||
              (dut.lsu.query_fire_w[1]&&dut.lsu.query_in_tag_w[9+:9]==9'(first_load+LOADS-1)))&&budget<80)begin
        @(negedge clk);budget=budget+1;
      end
      if(budget==80)$fatal(1,"commit/capture edge not reached");
      commit_fire=1;commit_tag=0;
      @(negedge clk);commit_fire=0;active[0]=0;commit_cycle=cycles;observe=1;
      log_state("commit_capture");
      if(commit_capture_events!=1||dut.lsu.state_q[0]!=6||
         dut.lsu.query_held_pin_w[0]!==baseline||dut.lsu.descriptor_valid_w!=0)
        $fatal(1,"descriptor must protect source across simultaneous commit/capture");
      @(negedge clk);
      release_cycle=baseline?-1:cycles;
      log_state("after_capture");
      free_at_commit=free_slots;
    end else begin
      budget=0;
      while(load_query_captures<LOADS&&budget<80)begin @(negedge clk);budget=budget+1;end
      if(load_query_captures!=LOADS)$fatal(1,"load query capture coverage=%0d",load_query_captures);
      repeat(3)@(negedge clk);
      log_state("before_commit");
      if(query_count==0||dut.lsu.descriptor_valid_w!=0||dut.lsu.query_take_w!=0||
         dut.lsu.query_held_pin_w[0]!==retain_source||winner_union!==expected_winners)
        $fatal(1,"isolated query pin case not established");
      retire(0);commit_cycle=cycles;observe=1;release_cycle=retain_source?-1:cycles;
      log_state("after_commit");free_at_commit=free_slots;
    end
    hold_cycles=0;
    repeat(24)begin
      sample_state();
      if(dut.lsu.state_q[0]!=(retain_source?6:0)||dut.lsu.alive_q[0]||dut.lsu.effect_q[0]||
         reuse[0]!==retain_source||dut.lsu.query_held_pin_w[0]!==retain_source||dut.lsu.descriptor_valid_w!=0||
         query_count==0||dut.lsu.query_take_w!=0||winner_union!==expected_winners)
        $fatal(1,"unused store release/reference invariant failed under stalled query");
      hold_cycles=hold_cycles+1;
      if(trace_file!=0)$fdisplay(trace_file,"%0d,%0d,%0d,%0d,%0d,%h,%h,%h,%b,%0d,%0d",
        cycles,dut.lsu.state_q[0],dut.lsu.alive_q[0],dut.lsu.effect_q[0],reuse[0],
        winner_union,dut.lsu.query_held_pin_w,dut.lsu.source_pin_w,
        dut.lsu.descriptor_valid_w,query_count,free_slots);
      @(negedge clk);
    end
    log_state("after_24_stalls");
    if(!retain_source)begin
      // Reuse both source LSQ slot0 and its ROB slot with the next generation
      // while the old load query is still blocked. A late unused-byte read
      // must not pick up this new store's data.
      head_tag=shadowed?9'd1:9'(first_load);
      enqueue(9'd32,64'h87,64'h5a,8'h20,0,0,0,0);
      if(dut.lsu.tag_q[0]!=32||dut.lsu.query_held_pin_w[0]||dut.lsu.query_take_w!=0)
        $fatal(1,"source slot was not safely reused under query backpressure");
      $display("QUERY_PIN_REUSE slot=0 old_tag=0 new_tag=32 cycle=%0d",cycles);
    end else begin
      budget=0;
      while(dut.lsu.state_q[0]!=0&&budget<500)begin @(negedge clk);budget=budget+1;end
      release_cycle=cycles;
      if(dut.lsu.state_q[0]!=0||reuse[0]||first_take_cycle<0)$fatal(1,"baseline source failed to drain");
      log_state("source_released");
    end
    for(n=0;n<LOADS;n=n+1)wait_result(5'(first_load+n));
    if(shadowed||multiple)begin head_tag=1;wait_result(1);retire(1);end
    for(n=0;n<LOADS;n=n+1)retire(9'(first_load+n));
    if(!retain_source)begin
      @(negedge clk);kill=1;killed[0]=1;active[0]=0;
      @(negedge clk);kill=0;
    end
    repeat(8)@(negedge clk);
    if(!idle||reuse!=0||wbcount!=(LOADS+((shadowed||multiple)?2:1))||read_txns!=LOADS)$fatal(1,"final result/drain mismatch");
    $display("QUERY_PIN_RESULT depth=%0d baseline=%0d outside_mask=%0d shadowed=%0d referenced=%0d commit_capture=%0d multiple=%0d checked_stall_cycles=%0d commit_cycle=%0d release_cycle=%0d pinned_interval=%0d free_at_commit=%0d",
      DEPTH,baseline,outside_mask,shadowed,referenced,commit_capture,multiple,hold_cycles,commit_cycle,release_cycle,release_cycle-commit_cycle,free_at_commit);
    $display("[PASS] tb_r64_lsu_query_pin exact references, commit, backpressure, source reuse and data");
    if(trace_file!=0)$fclose(trace_file);$finish;
  end
  initial begin #200000;$fatal(1,"query pin timeout");end
endmodule
