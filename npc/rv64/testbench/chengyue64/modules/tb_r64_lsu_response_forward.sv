`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_lsu_response_forward;
  parameter FORWARD=1, PREPARED_CANCEL=0;
  parameter C2 = 1;
  localparam DIRECT = 1;
  parameter BIND_BYPASS = 1;
  localparam N=12, I=$clog2(N), QW=8*N+I+153, C=`R64_MEM_CMD_W, R=`R64_RESULT_W;
  reg clk=0;
  always #5 clk=~clk;
  reg rst=1, flush=0, head_valid=0, effect_allow=0;
  reg [31:0] kill=0;
  reg [8:0] head_tag=0;
  reg [1:0] reserve=0, bind_fire=0, tr_ready=0, tr_rsp=0, needs_ad=0, tr_fault=0;
  reg [17:0] reserve_tag=0, bind_tag=0;
  reg [15:0] reserve_func=0;
  reg [2*I-1:0] bind_slot=0, rsp_token=0, mrsp_token=0;
  reg [2*C-1:0] command=0;
  reg [127:0] pa=0, mrsp_data=0;
  reg [3:0] tr_class=0;
  reg [1:0] mem_ready=0, mrsp=0;
  wire [1:0] reserve_ready,tv,ta_ad,rsp_ready,ov,mv,mrsp_ready,mcache;
  wire [2*I-1:0] reserve_slot,token,mtoken;
  wire [127:0] va,ma,md;
  wire [3:0] access_kind,mop;
  wire [5:0] msize;
  wire [15:0] mstrb;
  wire [9:0] mamo;
  wire [31:0] reuse;
  wire idle;
  wire [17:0] out_tag;
  wire [2*R-1:0] result;
  reg [I-1:0] slots[0:31];
  integer translations[0:N-1], physical[0:N-1], physcycle[0:N-1];
  integer total=0, cycle=0, outputs=0, checks=0, direct_total=0, fallbacks=0;
  integer start_cycle, before_count, budget, desc_accepts=0, blocked_credit=0, competing=0;
  integer descriptor_cycle[0:N-1], query_cycle[0:N-1], output_cycle[0:31];
  integer forward_accepts=0, incoming_pin_commit=0, direct_full=0,direct_partial=0,direct_nomatch=0;
  reg [63:0] expect_data[0:31];
  reg [31:0] expect_output=0, received=0;
  reg [1:0] commit_fire=0;
  reg [17:0] commit_tag=0;
  reg store_response=0, store_error=0;
  reg [I-1:0] store_response_slot=0;
  reg [255:0] held;
  R64Lsu #(.ENTRIES(N),.INDEX_W(I),.BIND_TRANSLATION_BYPASS(BIND_BYPASS),
             .TRANSLATION_QUERY_BYPASS(1),.RESPONSE_DESCRIPTOR_BYPASS(C2),
              .RESPONSE_FORWARD_QUERY(FORWARD),.PREPARED_CANCEL(PREPARED_CANCEL)) dut (
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),
    .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),
    .trigger_enable_i(3'b0),.trigger_address_i(64'b0),
    .fp_enable_i(1'b1),.translate_active_i(1'b0),
    .commit_fire_i(commit_fire),.commit_tag_i(commit_tag),
    .reserve_want_i(2'b11),.reserve_fire_i(reserve),
    .reserve_ready_o(reserve_ready),.reserve_slot_o(reserve_slot),
    .reserve_tag_i(reserve_tag),.reserve_func_i(reserve_func),.reserve_amo_i(10'b0),
    .in_fire_i(bind_fire),.in_tag_i(bind_tag),.in_slot_i(bind_slot),.in_command_i(command),
    .out_valid_o(ov),.out_ready_i(2'b11),.out_tag_o(out_tag),.out_result_o(result),
    .reuse_block_o(reuse),.idle_o(idle),
    .tr_valid_o(tv),.tr_ready_i(tr_ready),.tr_vaddr_o(va),
    .tr_access_o(access_kind),.tr_ad_update_o(ta_ad),.tr_token_o(token),
    .tr_rsp_valid_i(tr_rsp),.tr_rsp_ready_o(rsp_ready),.tr_rsp_token_i(rsp_token),
    .tr_paddr_i(pa),.tr_class_i(tr_class),.tr_fault_i(tr_fault),
    .tr_needs_ad_i(needs_ad),.tr_cause_i({5'd13,5'd13}),
    .mem_valid_o(mv),.mem_ready_i(mem_ready),.mem_token_o(mtoken),
    .mem_addr_o(ma),.mem_data_o(md),.mem_op_o(mop),.mem_cache_o(mcache),
    .mem_size_o(msize),.mem_strb_o(mstrb),.mem_amo_o(mamo),
    .mem_rsp_valid_i(mrsp),.mem_rsp_ready_o(mrsp_ready),.mem_rsp_token_i(mrsp_token),
    .mem_rsp_data_i(mrsp_data),.mem_rsp_error_i(2'b0),.mem_rsp_offset_i(6'b0),
    .store_done_ready_i(1'b1),.mem_store_rsp_valid_i(store_response),
    .mem_store_rsp_token_i(store_response_slot),.mem_store_rsp_error_i(store_error)
  );
  always @(posedge clk) if(!rst) begin
    cycle=cycle+1;
    for(integer l=0;l<2;l=l+1) begin
      if(tv[l]&&tr_ready[l]) translations[token[l*I+:I]]=translations[token[l*I+:I]]+1;
      if(mv[l]&&mem_ready[l]) begin
        if(physical[mtoken[l*I+:I]]!=0) $fatal(1,"duplicate physical owner");
        physical[mtoken[l*I+:I]]=physical[mtoken[l*I+:I]]+1;
        physcycle[mtoken[l*I+:I]]=cycle;total=total+1;
      end
      if(dut.query_fire_w[l])query_cycle[dut.query_in_data_w[l*QW+dut.QD+:I]]=cycle;
      if(dut.translation_forward_take_w[l])begin
        forward_accepts+=1;
        if(dut.query_in_data_w[l*QW+dut.QH])direct_full+=1;
        else if(dut.translation_forward_pin_w[l*N+:N]!=0)direct_partial+=1;
        else direct_nomatch+=1;
        if(commit_fire!=0&&dut.translation_forward_pin_w[l*N+slots[0]])incoming_pin_commit+=1;
      end
      if(dut.translation_direct_take_w[l]) direct_total=direct_total+1;
      if(tr_rsp[l]&&dut.query_fire_w[l]) fallbacks=fallbacks+1;
      if(dut.translation_descriptor_take_w[l])desc_accepts=desc_accepts+1;
      if(tr_rsp[l]&&!dut.descriptor_credit_w[l])blocked_credit=blocked_credit+1;
      if(tr_rsp[l]&&(dut.mvalid_q[l]||dut.mem_select_valid_w[l]))competing=competing+1;
      if(dut.descriptor_queue_fire_w[l])begin
        if(descriptor_cycle[dut.descriptor_in_data_w[l*dut.DESC_W+:I]]!=-1)
          $fatal(1,"duplicate descriptor owner publication");
        descriptor_cycle[dut.descriptor_in_data_w[l*dut.DESC_W+:I]]=cycle;
      end
      if(ov[l])begin
        outputs=outputs+1;output_cycle[out_tag[l*9+:5]]=cycle;
        if(expect_output[out_tag[l*9+:5]])begin
          if(received[out_tag[l*9+:5]] || result[l*R+64] ||
             result[l*R+:64]!==expect_data[out_tag[l*9+:5]])
            $fatal(1,"wrong forwarding result tag%0d got%h expected%h exception%b",
                   out_tag[l*9+:9],result[l*R+:64],expect_data[out_tag[l*9+:5]],result[l*R+64]);
          received[out_tag[l*9+:5]]=1;
        end
      end
    end
  end
  task tick; begin @(posedge clk);#1;end endtask
  task check(input condition,input [767:0] message);
    begin checks=checks+1;if(condition!==1'b1)$fatal(1,"%0s",message);end
  endtask
  function [C-1:0] cmd(input [63:0] address,input [7:0] fn);
    cmd={5'b0,fn,64'habc0123411223344,64'b0,address};
  endfunction
  function [255:0] payload(input integer lane);
    payload={mtoken[lane*I+:I],ma[lane*64+:64],md[lane*64+:64],
             mop[lane*2+:2],mcache[lane],msize[lane*3+:3],mstrb[lane*8+:8],mamo[lane*5+:5]};
  endfunction
  task reset_phase;
    begin
      rst=1;reserve=0;bind_fire=0;tr_ready=0;tr_rsp=0;needs_ad=0;tr_fault=0;
      flush=0;kill=0;head_valid=0;effect_allow=0;tr_class=0;mem_ready=0;mrsp=0;
      total=0;outputs=0;expect_output=0;received=0;commit_fire=0;store_response=0;store_error=0;
      for(integer n=0;n<N;n=n+1)begin translations[n]=0;physical[n]=0;physcycle[n]=-1;descriptor_cycle[n]=-1;query_cycle[n]=-1;end
      for(integer n=0;n<32;n+=1)output_cycle[n]=-1;
      tick;rst=0;#1;
    end
  endtask
  task allocate(input [8:0] tagno,input [7:0] fn);
    begin
      reserve=1;reserve_tag={9'b0,tagno};reserve_func={8'b0,fn};#1;
      check(reserve_ready[0],"allocation credit");slots[tagno[4:0]]=reserve_slot[0+:I];
      tick;reserve=0;
    end
  endtask
  task bind_one(input [8:0] tagno,input [7:0] fn,input [63:0] address);
    begin
      bind_fire=1;bind_tag={9'b0,tagno};bind_slot={I'(0),slots[tagno[4:0]]};
      command={C'(0),cmd(address,fn)};tick;bind_fire=0;
    end
  endtask
  task accept_translation(input [8:0] tagno);
    begin
      tr_ready=3;budget=0;
      while(translations[slots[tagno[4:0]]]==0 && budget<20)begin tick;budget=budget+1;end
      tr_ready=0;check(budget<20,"translation request absent");
    end
  endtask
  task launch(input [8:0] tagno,input [7:0] fn,input [63:0] address);
    begin allocate(tagno,fn);bind_one(tagno,fn,address);accept_translation(tagno);end
  endtask
  task response(input integer lane,input [8:0] tagno,input [63:0] address);
    begin
      tr_rsp[lane]=1;rsp_token[lane*I+:I]=slots[tagno[4:0]];pa[lane*64+:64]=address;#1;
    end
  endtask
  task finish_response;
    begin tick;tr_rsp=0;#1;end
  endtask
  task await_physical(input integer count);
    begin
      budget=0;while(total<count && budget<30)begin tick;budget=budget+1;end
      check(total==count,"missing or duplicate physical acceptance");
    end
  endtask
  task return_memory(input [8:0] tagno);
    begin
      mrsp=1;mrsp_token={I'(0),slots[tagno[4:0]]};
      mrsp_data={64'b0,64'hfedcba9876543210};#1;
      check(mrsp_ready[0],"response ingress absent");tick;mrsp=0;
    end
  endtask
  task cold_response(input [7:0] fn,input [63:0] address,
                     input [1:0] cls,input fault,input ad);
    begin
      reset_phase;launch(0,fn,address);mem_ready=3;tr_class={2'b0,cls};tr_fault={1'b0,fault};needs_ad={1'b0,ad};
      response(0,0,address);check(dut.translation_direct_offer_w==0 && mv==0,"cold response bypassed qualification");
      finish_response;
      if(fn==8'h43)begin check(mv==1,"FP lost existing query route");await_physical(1);end
      else begin repeat(2)tick;check(total==0,"cold operation issued without head permission");end
    end
  endtask

  task store_ready(input [8:0] tagno,input [7:0] fn,input [63:0] address,input [63:0] data);
    begin
      allocate(tagno,fn);bind_fire=1;bind_tag={9'b0,tagno};bind_slot={I'(0),slots[tagno[4:0]]};
      command={C'(0),5'b0,fn,data,64'b0,address};tick;bind_fire=0;accept_translation(tagno);
      response(0,tagno,address);finish_response;tick;
      check(dut.state_q[slots[tagno[4:0]]]==3,"known older store fixture");
    end
  endtask
  task load_response(input [8:0] tagno,input [63:0] address,input [63:0] expected);
    begin
      launch(tagno,3,address);expect_output[tagno[4:0]]=1;expect_data[tagno[4:0]]=expected;
      response(0,tagno,address);
    end
  endtask
  task wait_output(input [8:0] tagno);
    begin
      budget=0;while(!received[tagno[4:0]]&&budget<30)begin tick;budget=budget+1;end
      check(budget<30,"load completion absent");
    end
  endtask
  task descriptor_arrival(input [8:0] tagno);
    begin
      budget=0;while(descriptor_cycle[slots[tagno[4:0]]]<0&&budget<20)begin tick;budget=budget+1;end
      check(budget<20,"descriptor publication absent");
    end
  endtask
  task load_on(input integer lane,input [8:0] tagno,input [7:0] fn,
               input [63:0] address,input [63:0] expected);
    begin launch(tagno,fn,address);expect_output[tagno[4:0]]=1;expect_data[tagno[4:0]]=expected;
      response(lane,tagno,address);end
  endtask
  task query_arrival(input [8:0] tagno);
    begin
      budget=0;while(query_cycle[slots[tagno[4:0]]]<0&&budget<20)begin tick;budget+=1;end
      check(budget<20,"query publication absent");
    end
  endtask
  task complete_store;
    begin
      head_valid=1;head_tag=0;effect_allow=1;mem_ready=1;await_physical(1);
      store_response_slot=slots[0];store_response=1;tick;store_response=0;
      check(dut.state_q[slots[0]]==7&&!dut.mem_issued_q[slots[0]],"actual successful B fixture");
      head_valid=0;effect_allow=0;mem_ready=0;
    end
  endtask
  integer target_lane,expected_gap,before_fwd;
  reg [I-1:0] old_source;
  reg [8:0] killed_descriptor;
  reg [63:0] saved_match_pa;
  reg [N-1:0] saved_match_age;
  integer qfull_pop_cases=0,occupied_kill_cases=0,prepared_kill_cases=0,failed_source_cases=0,shadowed_error_cases=0;
  initial begin
    // Registered prepared lane0 retains priority; lane1 may use the same matcher.
    // Test both response lanes with known, uncommitted older stores.
    for(target_lane=0;target_lane<2;target_lane+=1)begin
      reset_phase;store_ready(0,8'h23,64'h100,64'h1111222233334444);mem_ready=3;
      load_on(target_lane,1,3,64'h180,64'hfedcba9876543210);start_cycle=cycle+1;
      check(dut.translation_forward_take_w==(FORWARD&&target_lane==1?2:0),"prepared/response route qualification");
      finish_response;query_arrival(1);
      expected_gap=FORWARD&&target_lane==1?0:1;
      check(query_cycle[slots[1]]-start_cycle==expected_gap,"response to query no-match gap");
      await_physical(1);
      check(physcycle[slots[1]]-start_cycle==expected_gap+1,"response to actual physical gap");
      $display("FORWARD_MEASURE lane=%0d enable=%0d match=none tr_to_query=%0d tr_to_physical=%0d",
        target_lane,FORWARD,query_cycle[slots[1]]-start_cycle,physcycle[slots[1]]-start_cycle);
      return_memory(1);wait_output(1);
    end
    // The original eight youngest-byte selectors provide the same full/partial
    // values; full forwarding must never create a physical read.
    reset_phase;store_ready(0,8'h23,64'h180,64'haabbccddeeff0011);mem_ready=3;
    load_on(1,1,3,64'h180,64'haabbccddeeff0011);start_cycle=cycle+1;
    finish_response;query_arrival(1);wait_output(1);
    check(query_cycle[slots[1]]-start_cycle==(FORWARD?0:1),"full forwarding query gap");
    check(output_cycle[1]-start_cycle==(FORWARD?3:4),"full forwarding canonical completion gap");
    check(total==0,"full forwarding touched physical memory");
    $display("FORWARD_MEASURE enable=%0d match=full tr_to_query=%0d tr_to_completion=%0d",
      FORWARD,query_cycle[slots[1]]-start_cycle,output_cycle[1]-start_cycle);
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);mem_ready=3;
    load_on(1,1,3,64'h180,64'hfedcba9876547710);start_cycle=cycle+1;
    finish_response;await_physical(1);return_memory(1);wait_output(1);
    check(dut.forward_mask_q[slots[1]]==8'h02,"partial forward byte mask");
    check(physcycle[slots[1]]-start_cycle==(FORWARD?1:2),"partial forwarding physical gap");
    // Youngest store wins an overlapping byte; an independent store supplies
    // another byte. Access masks and signed extraction still use original logic.
    reset_phase;store_ready(0,8'h20,64'h181,64'h11);
    store_ready(1,8'h20,64'h181,64'h80);store_ready(2,8'h20,64'h182,64'h33);mem_ready=3;
    load_on(1,3,3,64'h180,64'hfedcba9876338010);finish_response;
    await_physical(1);return_memory(3);wait_output(3);
    check(dut.forward_mask_q[slots[3]]==8'h06,"multiple youngest byte masks");
    reset_phase;store_ready(0,8'h20,64'h181,64'h80);mem_ready=3;
    load_on(1,1,8'h00,64'h181,64'hffffffffffffff80);finish_response;wait_output(1);
    check(total==0,"signed-byte full forwarding touched physical memory");
    reset_phase;store_ready(0,8'h20,64'h183,64'h80);mem_ready=3;
    load_on(1,1,8'h02,64'h180,64'hffffffff80543210);finish_response;
    await_physical(1);return_memory(1);wait_output(1);
    check(dut.forward_mask_q[slots[1]]==8'h08,"signed-word partial access mask");
    reset_phase;store_ready(0,8'h21,64'h180,64'h2211);
    store_ready(1,8'h21,64'h182,64'h8877);store_ready(2,8'h20,64'h181,64'h99);mem_ready=3;
    load_on(1,3,8'h02,64'h180,64'hffffffff88779911);finish_response;wait_output(3);
    check(total==0,"multiple youngest-source full word touched physical memory");

    // Actual B-completed store retires exactly on the new response-query edge.
    // New winner pins must retain its data until next-edge query read completes.
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);complete_store;
    load_on(0,1,3,64'h180,64'hfedcba9876547710);old_source=slots[0];
    commit_fire=1;commit_tag=0;#1;
    check(dut.translation_forward_take_w==(FORWARD?1:0),"retiring source response route");
    if(FORWARD)check(dut.source_pin_w[old_source],"incoming winner did not protect same-edge source commit");
    finish_response;commit_fire=0;
    check(!dut.alive_q[old_source]&&!dut.effect_q[old_source],"retired source retained architectural effect");
    check(dut.state_q[old_source]==(FORWARD?6:0),"incoming winner did not select PINNED");
    if(FORWARD)begin
      check(!dut.free_w[old_source]&&dut.query_held_pin_w[old_source],"source reusable before query data read");
      tick;check(dut.state_q[old_source]==6,"source released on same read edge");
      tick;check(dut.state_q[old_source]==0,"source not released after final query read");
    end
    allocate(2,8'h20);check(slots[2]==old_source,"unreferenced store source not reusable");
    bind_one(2,8'h20,64'h181);
    mem_ready=3;await_physical(2);
    mrsp=1;mrsp_token={I'(0),slots[1]};
    mrsp_data={64'b0,FORWARD?64'hfedcba9876543210:64'hfedcba9876547710};
    tick;mrsp=0;wait_output(1);
    check(dut.forward_mask_q[slots[1]]==(FORWARD?8'h02:8'h00),"recycled source corrupted frozen bytes");

    // With no prepared occupant, both response lanes may capture pins to the
    // same completed store. Its lifetime is the union of both held queries.
    reset_phase;store_ready(0,8'h23,64'h180,64'h9988776655443322);complete_store;
    launch(1,3,64'h180);launch(2,3,64'h180);
    expect_output=6;expect_data[1]=64'h9988776655443322;expect_data[2]=expect_data[1];
    response(0,1,64'h180);response(1,2,64'h180);commit_fire=1;commit_tag=0;
    check(dut.translation_forward_take_w==(FORWARD?3:0),"dual response forward publication");
    finish_response;commit_fire=0;
    if(FORWARD)begin
      check(dut.query_front_pin_w[slots[0]]&&dut.query_front_pin_w[N+slots[0]],"dual source pin union");
      wait_output(1);wait_output(2);check(total==1,"dual full forwards created physical loads");
    end else begin
      mem_ready=3;await_physical(3);
      mrsp=3;mrsp_token={slots[2],slots[1]};
      mrsp_data={64'h9988776655443322,64'h9988776655443322};tick;mrsp=0;
      wait_output(1);wait_output(2);
    end

    // Query capacity is not borrowed from a same-edge departure. Block both
    // physical lanes, overflow the query/descriptor paths, then drain once.
    reset_phase;store_ready(0,8'h23,64'h100,64'h1111);
    for(integer n=1;n<=10;n+=1)begin
      launch(9'(n),3,64'h200+64'(n*8));response(1,9'(n),64'h200+64'(n*8));
      if(!dut.query_credit_w[1])check(!dut.translation_forward_take_w[1],"new query borrowed absent Q credit");
      finish_response;
    end
    check(total==0,"stalled physical fixture accepted request");
    launch(11,3,64'h300);response(1,11,64'h300);
    check(!dut.query_credit_w[1]&&dut.query_valid_w[1],"full query fixture");
    mem_ready=2;#1;
    check(dut.query_take_w[1]&&!dut.translation_forward_take_w[1]&&!dut.query_credit_w[1],
      "new response borrowed same-edge query departure");
    qfull_pop_cases+=1;finish_response;
    mem_ready=3;await_physical(11);
    for(integer n=1;n<=11;n+=1)check(physical[slots[n]]==1,"fallback lost or duplicated owner");

    // A killed occupied descriptor still owns the matcher until the edge.
    // The new translation must fall back despite current out_valid dropping.
    reset_phase;store_ready(0,8'h23,64'h100,64'h1111);
    for(integer n=1;n<=10;n+=1)begin
      launch(9'(n),3,64'h200+64'(n*8));response(1,9'(n),64'h200+64'(n*8));finish_response;
    end
    launch(11,3,64'h300);response(1,11,64'h300);
    check(dut.descriptor_occupied_w[1]&&dut.descriptor_valid_w[1],"occupied descriptor fixture");
    killed_descriptor=dut.descriptor_tag_w[9+:9];
    saved_match_pa=dut.match_pa_w[64+:64];saved_match_age=dut.match_age_w[N+:N];
    kill=32'b1<<killed_descriptor[4:0];#1;
    check(dut.descriptor_occupied_w[1]&&!dut.descriptor_valid_w[1]&&
      !dut.translation_forward_route_w[1]&&!dut.translation_forward_take_w[1]&&
      dut.match_pa_w[64+:64]===saved_match_pa&&dut.match_age_w[N+:N]===saved_match_age,
      "current descriptor kill changed matcher identity");
    occupied_kill_cases+=1;finish_response;kill=0;mem_ready=3;await_physical(10);
    for(integer n=1;n<=11;n+=1)
      check(physical[slots[n]]==(9'(n)==killed_descriptor?0:1),"occupied killed descriptor fallback conservation");

    // Registered prepared ownership also blocks the new lane0 path on its
    // cancellation edge, even though there is no current head lease.
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);launch(1,3,64'h180);
    response(0,1,64'h180);
    check(dut.prepared_valid_q&&dut.prepared_payload_valid_q&&!dut.prepared_offer_w,
      "unleased prepared owner fixture");
    kill=3;#1;
    check(dut.prepared_valid_q&&dut.prepared_killed_w&&!dut.translation_forward_route_w[0]&&
      !dut.translation_forward_take_w[0],"current prepared kill opened new matcher route");
    prepared_kill_cases+=1;finish_response;kill=0;repeat(4)tick;
    check(total==0&&outputs==0,"cancelled prepared owner or load escaped");

    // A real source B error rejects only a new packet which references it.
    // The other response lane, whose byte winner set is empty, may still use
    // its own route. Recovery is deliberately delayed; no immediate-flush
    // assumption is used to protect an already-created erroneous byte pin.
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);
    head_valid=1;head_tag=0;effect_allow=1;mem_ready=1;await_physical(1);
    head_valid=0;effect_allow=0;mem_ready=0;
    launch(1,3,64'h180);launch(2,3,64'h188);
    response(0,1,64'h180);response(1,2,64'h188);
    saved_match_pa=dut.match_pa_w[0+:64];saved_match_age=dut.match_age_w[0+:N];
    store_response_slot=slots[0];store_error=1;store_response=1;#1;
    check(dut.store_done_valid_o&&dut.store_done_error_o,"actual B error did not reach canonical terminal");
    check(dut.translation_forward_take_w==(FORWARD?2:0),"failed source suppressed wrong response lane");
    check(dut.match_pa_w[0+:64]===saved_match_pa&&dut.match_age_w[0+:N]===saved_match_age,
      "B error changed matcher identity");
    if(FORWARD)check(dut.translation_descriptor_take_w[0]&&
      !dut.query_fire_w[0]&&dut.query_fire_w[1],"failed source did not use canonical descriptor fallback");
    failed_source_cases+=1;finish_response;store_response=0;store_error=0;
    repeat(5)begin tick;check(!dut.query_held_pin_w[slots[0]],"failed source left a delayed byte reference");end
    check(outputs==0&&total==1,"B error manufactured load completion or physical store");
    kill=7;tick;kill=0;repeat(5)tick;
    check(outputs==0&&total==1,"delayed local recovery leaked failed-source load");

    // An older failing store which is shadowed by the exact younger winner
    // must not suppress the independent new query. Speculative load completion
    // is permitted here; neither younger architectural commit nor a store effect
    // is issued before delayed cancellation.
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);
    head_valid=1;head_tag=0;effect_allow=1;mem_ready=1;await_physical(1);
    head_valid=0;effect_allow=0;mem_ready=0;
    store_ready(1,8'h20,64'h181,64'h66);
    load_on(1,2,8'h00,64'h181,64'h66);
    store_response_slot=slots[0];store_error=1;store_response=1;#1;
    check(dut.store_done_valid_o&&dut.store_done_error_o,"shadowed actual B error missing");
    if(FORWARD)begin
      check(!dut.translation_forward_pin_w[N+slots[0]]&&dut.translation_forward_pin_w[N+slots[1]],
        "shadowed failed store retained exact winner pin");
      check(!dut.gen_holder_credit[1].translation_failed_source_w&&dut.translation_forward_take_w==2,
        "nonwinner B error suppressed exact younger source");
    end
    shadowed_error_cases+=1;finish_response;store_response=0;store_error=0;
    wait_output(2);check(total==1,"shadowed-source full forwarding created physical effect");
    kill=7;tick;kill=0;repeat(5)tick;

    // Existing C1 stays first choice, unknown older owners still block,
    // and FP/atomic/store/MMIO/misaligned/fault/AD responses remain on old paths.
    reset_phase;launch(0,3,64'h180);mem_ready=3;response(0,0,64'h180);
    check(dut.descriptor_tr_take_w[0]&&!dut.translation_forward_take_w[0]&&
      !dut.translation_descriptor_take_w[0],"C1 response priority");
    finish_response;await_physical(1);
    reset_phase;allocate(0,8'h23);launch(1,3,64'h180);response(1,1,64'h180);
    check(dut.translation_forward_take_w==0,"unknown older store bypassed");finish_response;
    for(integer kind_case=0;kind_case<7;kind_case+=1)begin
      reset_phase;store_ready(0,8'h23,64'h100,64'h1111);
      launch(1,kind_case==3?8'h43:(kind_case==4?8'h83:(kind_case==5?8'h23:8'h03)),
        kind_case==6?64'h181:64'h180);
      if(kind_case==0)tr_class=8;
      if(kind_case==1)tr_fault=2;
      if(kind_case==2)needs_ad=2;
      response(1,1,64'h180);check(dut.translation_forward_take_w==0,"excluded response entered forwarding shortcut");
      finish_response;
    end
    // Cancellation changes publication only, not candidate identity. A killed
    // translation drains; a later full generation must use its own source.
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);launch(1,3,64'h180);
    response(1,1,64'h180);held=256'(dut.query_in_data_w[QW+:QW]);
    kill=2;#1;
    check(dut.translation_forward_take_w==0&&held===256'(dut.query_in_data_w[QW+:QW]),
      "current kill changed wide response identity");
    finish_response;kill=0;repeat(3)tick;check(total==0&&outputs==0,"cancelled response escaped");
    allocate(33,3);translations[slots[1]]=0;query_cycle[slots[1]]=-1;
    bind_one(33,3,64'h188);accept_translation(33);mem_ready=3;
    response(1,33,64'h188);finish_response;await_physical(1);
    check(dut.tag_q[slots[1]]==33,"reused fulltag candidate lost generation");
    if(FORWARD)check(forward_accepts>5&&direct_full>0&&direct_partial>0&&direct_nomatch>0&&incoming_pin_commit>0,
      "response forwarding coverage vacuous");
    check(qfull_pop_cases==1&&occupied_kill_cases==1&&prepared_kill_cases==1&&failed_source_cases==1&&shadowed_error_cases==1,"new priority/credit cases vacuous");
    $display("[PASS] tb_r64_lsu_response_forward enable=%0d cancel=%0d checks=%0d captures=%0d full=%0d partial=%0d nomatch=%0d commitpin=%0d qfullpop=%0d oldkill=%0d preparedkill=%0d Berror=%0d Berror_shadowed=%0d",
      FORWARD,PREPARED_CANCEL,checks,forward_accepts,direct_full,direct_partial,direct_nomatch,incoming_pin_commit,
      qfull_pop_cases,occupied_kill_cases,prepared_kill_cases,failed_source_cases,shadowed_error_cases);$finish;
  end
  initial begin #150000;$fatal(1,"response forwarding timeout");end
endmodule
