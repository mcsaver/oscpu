`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_lsu_response_descriptor;
  parameter C2 = 1;
  localparam DIRECT = 1;
  parameter BIND_BYPASS = 1;
  localparam N=12, I=$clog2(N), C=`R64_MEM_CMD_W, R=`R64_RESULT_W;
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
  integer descriptor_cycle[0:N-1];
  reg [63:0] expect_data[0:31];
  reg [31:0] expect_output=0, received=0;
  reg [1:0] commit_fire=0;
  reg [17:0] commit_tag=0;
  reg store_response=0;
  reg [I-1:0] store_response_slot=0;
  reg [255:0] held;
  R64Lsu #(.ENTRIES(N),.INDEX_W(I),.BIND_TRANSLATION_BYPASS(BIND_BYPASS),
             .TRANSLATION_QUERY_BYPASS(1),.RESPONSE_DESCRIPTOR_BYPASS(C2)) dut (
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
    .mem_store_rsp_token_i(store_response_slot),.mem_store_rsp_error_i(1'b0)
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
        outputs=outputs+1;
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
      total=0;outputs=0;expect_output=0;received=0;commit_fire=0;store_response=0;
      for(integer n=0;n<N;n=n+1)begin translations[n]=0;physical[n]=0;physcycle[n]=-1;descriptor_cycle[n]=-1;end
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
  initial begin
    // Known nonalias store requires the original forwarding probe. It permits
    // the descriptor shortcut while retaining the canonical older relation.
    reset_phase;store_ready(0,8'h23,64'h100,64'h1111222233334444);mem_ready=3;
    load_response(1,64'h180,64'hfedcba9876543210);start_cycle=cycle+1;
    check(dut.translation_descriptor_take_w==(C2?1:0),"response descriptor qualification");
    finish_response;descriptor_arrival(1);
    check(descriptor_cycle[slots[1]]-start_cycle==(C2?0:2),"response descriptor edge gap");
    $display("MEASURE C2=%0d translation_response_to_descriptor=%0d",C2,descriptor_cycle[slots[1]]-start_cycle);
    await_physical(1);return_memory(1);wait_output(1);

    // Complete and partial forward sources still pass through query matching.
    reset_phase;store_ready(0,8'h23,64'h180,64'haabbccddeeff0011);mem_ready=3;
    load_response(1,64'h180,64'haabbccddeeff0011);finish_response;wait_output(1);
    check(total==0,"full forwarding touched physical memory");
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);mem_ready=3;
    load_response(1,64'h180,64'hfedcba9876547710);finish_response;
    await_physical(1);return_memory(1);wait_output(1);
    check(dut.forward_mask_q[slots[1]]==8'h02,"partial forward mask changed");

    // Same-byte youngest store wins, and independent byte winners are merged.
    reset_phase;store_ready(0,8'h20,64'h181,64'h11);
    store_ready(1,8'h20,64'h181,64'h22);store_ready(2,8'h20,64'h182,64'h33);mem_ready=3;
    load_response(3,64'h180,64'hfedcba9876332210);finish_response;
    await_physical(1);return_memory(3);wait_output(3);
    check(dut.forward_mask_q[slots[3]]==8'h06,"multiple source byte masks changed");

    // A real completed older store can retire at response capture. Memory
    // already contains its successful B, so a freed source is read coherently.
    // Immediately reusing its slot for a younger aliased store must clear age.
    reset_phase;store_ready(0,8'h20,64'h181,64'h77);
    head_valid=1;head_tag=0;effect_allow=1;mem_ready=1;await_physical(1);
    store_response_slot=slots[0];store_response=1;tick;store_response=0;
    check(dut.state_q[slots[0]]==7&&!dut.mem_issued_q[slots[0]],"successful older B fixture");
    head_valid=0;effect_allow=0;mem_ready=0;
    load_response(1,64'h180,64'hfedcba9876547710);
    commit_fire=1;commit_tag=0;finish_response;commit_fire=0;
    check(!dut.alive_q[slots[0]]&&!dut.effect_q[slots[0]],"same-edge source retirement did not release");
    allocate(2,8'h20);check(slots[2]==slots[0],"source slot was not reused");
    bind_one(2,8'h20,64'h181);
    mem_ready=3;await_physical(2);
    mrsp=1;mrsp_token={I'(0),slots[1]};mrsp_data={64'b0,64'hfedcba9876547710};
    tick;mrsp=0;wait_output(1);
    check(dut.forward_mask_q[slots[1]]==0,"retired/recycled source supplied stale forwarded bytes");
    check(!dut.older_q[slots[1]][slots[2]],"source birth failed to clear older relation");

    // Both response lanes independently publish descriptors in the same edge.
    reset_phase;store_ready(0,8'h23,64'h100,64'h1111);
    launch(1,3,64'h180);launch(2,3,64'h188);mem_ready=3;
    response(0,1,64'h180);response(1,2,64'h188);start_cycle=cycle+1;
    check(dut.translation_descriptor_take_w==(C2?3:0),"dual descriptor response");
    finish_response;descriptor_arrival(1);descriptor_arrival(2);await_physical(2);
    check(descriptor_cycle[slots[1]]==descriptor_cycle[slots[2]],"dual descriptors serialized");

    // Full downstream queues use the old READY/mholder fallback, then drain
    // exactly once. No data, winner or owner can be lost at a publication miss.
    reset_phase;store_ready(0,8'h23,64'h100,64'h1111);
    for(integer n=1;n<=10;n=n+1)begin
      launch(9'(n),3,64'h200+64'(n*8));response(0,9'(n),64'h200+64'(n*8));
      if(!dut.descriptor_credit_w[0]||dut.mvalid_q[0]||dut.mem_select_valid_w[0])
        check(!dut.translation_descriptor_take_w[0],"response stole occupied descriptor path");
      finish_response;
    end
    check(total==0,"physical stalled fixture accepted request");
    mem_ready=3;await_physical(10);
    for(integer n=1;n<=10;n=n+1)check(physical[slots[n]]==1,"descriptor fallback lost owner");
    check(blocked_credit>0&&competing>0,"queue-full/mholder fallback not reached");

    // Older unknown stores are ordering barriers until their attributes exist.
    reset_phase;allocate(0,8'h23);launch(1,3,64'h180);
    response(0,1,64'h180);check(dut.translation_descriptor_take_w==0,"unknown older store bypassed");
    finish_response;repeat(4)tick;check(total==0,"unknown older store made physical request");
    reset_phase;allocate(0,3);launch(1,3,64'h180);
    response(0,1,64'h180);check(dut.translation_descriptor_take_w==0,"unknown older load attribute bypassed");
    finish_response;repeat(3)tick;check(total==0,"unknown older load attribute made physical request");
    // The old direct-query remains first choice and does not double-publish.
    reset_phase;launch(0,3,64'h180);mem_ready=3;response(0,0,64'h180);
    check(dut.descriptor_tr_take_w[0]&&!dut.translation_descriptor_take_w[0],"existing query priority");
    finish_response;await_physical(1);check(descriptor_cycle[slots[0]]==-1,"direct query duplicated descriptor");

    // Success/fault/AD/special qualification stays separate from descriptor credit.
    for(integer kind_case=0;kind_case<7;kind_case=kind_case+1)begin
      reset_phase;store_ready(0,8'h23,64'h100,64'h1111);
      launch(1,kind_case==3?8'h43:(kind_case==4?8'h83:(kind_case==5?8'h23:8'h03)),
             kind_case==6 ? 64'h181 : 64'h180);
      if(kind_case==0)tr_class=2;
      if(kind_case==1)tr_fault=1;
      if(kind_case==2)needs_ad=1;
      response(0,1,64'h180);check(dut.translation_descriptor_take_w==0,"cold owner entered descriptor shortcut");
      finish_response;
    end

    // A canceled translation drains once; held descriptor cancellation cannot
    // emit a completion or be confused with a later full generation.
    reset_phase;store_ready(0,8'h23,64'h100,64'h1111);launch(1,3,64'h180);
    kill=2;response(0,1,64'h180);check(dut.translation_descriptor_take_w==0,"killed response published descriptor");
    finish_response;kill=0;repeat(3)tick;check(total==0&&outputs==0,"dead translation escaped");
    allocate(9'd33,3);translations[slots[1]]=0;descriptor_cycle[slots[1]]=-1;
    bind_one(9'd33,3,64'h188);accept_translation(9'd33);mem_ready=3;
    response(0,9'd33,64'h188);finish_response;await_physical(1);
    check(dut.tag_q[slots[1]]==33,"new fulltag owner lost identity");

    $display("[PASS] tb_r64_lsu_response_descriptor C2=%0d checks=%0d descriptor_shortcuts=%0d no_credit=%0d competing=%0d forwarding_dual_fallback_order_fault_cancel_reuse=1",
             C2,checks,desc_accepts,blocked_credit,competing);$finish;
  end
  initial begin #150000;$fatal(1,"response descriptor timeout");end
endmodule
