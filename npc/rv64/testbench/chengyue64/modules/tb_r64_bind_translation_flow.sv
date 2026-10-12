`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_bind_translation_flow;
  parameter FLOW=1, STORE_HOT=1;
  parameter BIND_TO_TRANSLATION = 1;
  localparam N=12, I=$clog2(N), C=`R64_MEM_CMD_W;
  reg clk=0;
  always #5 clk=~clk;
  reg rst=1, flush=0;
  reg [31:0] kill=0;
  reg [1:0] reserve=0, bind_fire=0, tr_ready=0, tr_rsp=0;
  reg [17:0] reserve_tag=0, bind_tag=0;
  reg [15:0] reserve_func=0;
  reg [9:0] reserve_amo=0;
  reg [2*I-1:0] bind_slot=0, rsp_token=0;
  reg [2*C-1:0] command=0;
  reg [2:0] trigger_enable=0;
  reg [63:0] trigger_address=0;
  reg fp_enable=1,head_valid=0,effect_allow=0,allow_ad_replay=0;
  reg [8:0] head_tag=0;
  reg [1:0] needs_ad=0;
  wire [1:0] reserve_ready, tv, ta_ad, rsp_ready, ov;
  wire [2*I-1:0] reserve_slot, token;
  wire [127:0] va;
  wire [3:0] access_kind;
  wire [7:0] protection;
  wire [31:0] reuse;
  wire idle;
  wire [17:0] out_tag;
  wire [2*`R64_RESULT_W-1:0] result;
  reg [I-1:0] slots[0:31];
  integer accepted[0:15],accept_cycle[0:15];
  integer start_cycle,budget;
  integer total=0, cycle=0, j, before_count;
  R64Lsu #(.ENTRIES(N),.INDEX_W(I),.BIND_TRANSLATION_BYPASS(BIND_TO_TRANSLATION==1),
    .BIND_TRANSLATION_EMPTY_FLOW(FLOW), .BIND_STORE_TRANSLATION(STORE_HOT)) dut (
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),
    .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),
    .trigger_enable_i(trigger_enable),.trigger_address_i(trigger_address),
    .fp_enable_i(fp_enable),.translate_active_i(1'b0),
    .commit_fire_i(2'b0),.commit_tag_i(18'b0),
    .reserve_want_i(2'b11),.reserve_fire_i(reserve),
    .reserve_ready_o(reserve_ready),.reserve_slot_o(reserve_slot),
    .reserve_tag_i(reserve_tag),.reserve_func_i(reserve_func),.reserve_amo_i(reserve_amo),
    .in_fire_i(bind_fire),.in_tag_i(bind_tag),.in_slot_i(bind_slot),.in_command_i(command),
    .out_valid_o(ov),.out_ready_i(2'b11),.out_tag_o(out_tag),.out_result_o(result),
    .reuse_block_o(reuse),.idle_o(idle),
    .tr_valid_o(tv),.tr_ready_i(tr_ready),.tr_vaddr_o(va),
    .tr_access_o(access_kind),.tr_ad_update_o(ta_ad),.tr_token_o(token),
    .tr_request_protection_o(protection),
    .tr_rsp_valid_i(tr_rsp),.tr_rsp_ready_o(rsp_ready),.tr_rsp_token_i(rsp_token),
    .tr_paddr_i(128'b0),.tr_class_i(4'b0),.tr_fault_i(2'b0),
    .tr_needs_ad_i(needs_ad),.tr_cause_i(10'b0),
    .mem_ready_i(2'b0),.mem_rsp_valid_i(2'b0),.mem_rsp_token_i({2*I{1'b0}}),
    .mem_rsp_data_i(128'b0),.mem_rsp_error_i(2'b0),.mem_rsp_offset_i(6'b0),
    .store_done_ready_i(1'b1),.mem_store_rsp_valid_i(1'b0),
    .mem_store_rsp_token_i({I{1'b0}}),.mem_store_rsp_error_i(1'b0)
  );
  always @(posedge clk) if (!rst) begin
    cycle=cycle+1;
    for(integer n=0;n<2;n=n+1) if(tv[n]&&tr_ready[n]) begin
      if(accepted[token[n*I+:I]] != 0 &&
          !(allow_ad_replay && token[n*I+:I]==slots[0] && accepted[slots[0]]==1 &&
            ta_ad[n] && access_kind[n*2+:2]==2))
        $fatal(1,"duplicate translation token");
      accepted[token[n*I+:I]]=accepted[token[n*I+:I]]+1;
      accept_cycle[token[n*I+:I]]=cycle;
      total=total+1;
    end
  end
  task tick;
    begin @(posedge clk); #1; end
  endtask
  task check(input condition,input [767:0] message);
    begin if(condition!==1'b1) $fatal(1,"%0s",message); end
  endtask
  function [C-1:0] cmd(input [63:0] address,input [7:0] fn,input [4:0] amo);
    cmd={amo,fn,64'b0,64'b0,address};
  endfunction
  task reset_phase;
    begin
      rst=1; reserve=0; bind_fire=0; tr_ready=0; tr_rsp=0; flush=0; kill=0;
      trigger_enable=0; fp_enable=1; total=0;head_valid=0;effect_allow=0;allow_ad_replay=0;needs_ad=0;
      for(integer n=0;n<16;n=n+1)begin accepted[n]=0;accept_cycle[n]=-1;end
      tick; rst=0; #1;
    end
  endtask
  task allocate(input [1:0] mask,input [8:0] tag0,input [8:0] tag1,
                input [7:0] fn0,input [7:0] fn1);
    begin
      reserve=mask; reserve_tag={tag1,tag0};reserve_func={fn1,fn0};reserve_amo=0;
      #1;check((reserve_ready&mask)==mask,"allocation credit");
      if(mask[0])slots[tag0[4:0]]=reserve_slot[0+:I];
      if(mask[1])slots[tag1[4:0]]=reserve_slot[I+:I];
      tick;reserve=0;
    end
  endtask
  task bind_pair(input [1:0] mask,input [8:0] tag0,input [8:0] tag1,
                 input [63:0] addr0,input [63:0] addr1,input [7:0] fn0,input [7:0] fn1);
    begin
      bind_fire=mask;bind_tag={tag1,tag0};bind_slot={slots[tag1[4:0]],slots[tag0[4:0]]};
      command={cmd(addr1,fn1,0),cmd(addr0,fn0,0)};
      tick;bind_fire=0;
    end
  endtask
  task wait_hot;
    begin for(integer n=1;n<BIND_TO_TRANSLATION;n=n+1)begin check(tv==0,"early translation");tick;end end
  endtask
  task cold(input [7:0] fn,input [63:0] address);
    begin
      reset_phase;allocate(1,0,1,fn,0);bind_pair(1,0,1,address,0,fn,0);
      check(tv==0,"cold operation entered bind_fire shortcut");
      tick;check(tv==1 && va[63:0]==address,"cold operation lost original translation");
    end
  endtask
  initial begin
    // Real accept edges, with the public translation endpoint ready before bind.
    reset_phase;allocate(1,0,1,3,0);tr_ready=3;start_cycle=cycle+1;
    bind_pair(1,0,1,64'h80000700,0,3,0);
    budget=0;while(total==0 && budget<8)begin tick;budget=budget+1;end
    check(total==1 && accept_cycle[slots[0]]-start_cycle==(FLOW?0:1),
          "actual load bind-to-translation edge");
    check(dut.tr_issued_q[slots[0]] && dut.bound_q[slots[0]],
          "direct acceptance lost issued bit under new-bind initialization");
    repeat(4)tick;check(total==1,"direct accepted load also enqueued");
    $display("BIND_FLOW load_accept_gap=%0d FLOW=%0d STORE_HOT=%0d",
      accept_cycle[slots[0]]-start_cycle,FLOW,STORE_HOT);

    reset_phase;allocate(1,0,1,8'h23,0);tr_ready=3;start_cycle=cycle+1;
    bind_pair(1,0,1,64'h80000708,0,8'h23,0);
    budget=0;while(total==0 && budget<8)begin tick;budget=budget+1;end
    check(total==1 && accept_cycle[slots[0]]-start_cycle==(STORE_HOT?(FLOW?0:1):2),
          "actual store bind-to-translation edge");
    check(dut.tr_issued_q[slots[0]],"direct store acceptance lost issued bit");
    repeat(4)tick;check(total==1,"direct accepted store also enqueued");
    $display("BIND_FLOW store_accept_gap=%0d FLOW=%0d STORE_HOT=%0d",
      accept_cycle[slots[0]]-start_cycle,FLOW,STORE_HOT);

    // Reversed hot binds must set issued after *both* admission lanes initialize.
    reset_phase;allocate(3,0,1,3,3);tr_ready=3;start_cycle=cycle+1;
    bind_pair(3,1,0,64'h80000718,64'h80000710,3,3);
    repeat(3)tick;
    check(total==2 && dut.tr_issued_q[slots[0]] && dut.tr_issued_q[slots[1]] &&
          accept_cycle[slots[0]]-start_cycle==(FLOW?0:1) &&
          accept_cycle[slots[1]]==accept_cycle[slots[0]],"remapped direct dual owner");
    // A currently killed occupied head cannot be replaced by a fresh hot owner.
    reset_phase;allocate(3,0,1,3,3);allocate(1,2,3,3,0);
    bind_pair(1,0,1,64'h80000720,0,3,0);
    kill=1;tr_ready=1;
    bind_pair(1,2,3,64'h80000730,0,3,0);
    check(total==0,"current-killed occupied head lent its empty-flow slot");
    kill=0;repeat(5)tick;
    check(total==1&&accepted[slots[2]]==1,"queued replacement did not drain once");
    $display("BIND_FLOW remap_issued_priority=1 dead_occupied_no_replacement=1");
    reset_phase;allocate(1,0,1,3,0);
    bind_pair(1,0,1,64'h80000008,0,3,0);wait_hot;
    check(tv==1&&va[63:0]==64'h80000008&&token[0+:I]==slots[0]&&
          protection[3:0]==7&&access_kind[1:0]==1&&ta_ad[0],"isolated load owner/latency");
    $display("MEASURE LSU_bind_to_queued_translation=%0d",BIND_TO_TRANSLATION);
    repeat(4)begin tick;check(tv==1&&va[63:0]==64'h80000008,"translation hold payload");end
    tr_ready=3;tick;check(total==1,"single accepted load");tr_ready=0;
    if($test$plusargs("latency-only")) begin
      $display("[PASS] tb_r64_bind_translation_flow isolated bind_latency=%0d one_translation=1",BIND_TO_TRANSLATION);
      $finish;
    end

    reset_phase;allocate(3,0,1,3,2);
    bind_pair(3,0,1,64'h80000010,64'h80000024,3,2);wait_hot;
    check(tv==3&&token=={slots[1],slots[0]}&&va=={64'h80000024,64'h80000010}&&
          protection==8'h67,"dual bind_fire lane/rank metadata");
    tr_ready=3;tick;check(total==2,"dual translations not unique");

    // Reservation age wins over reverse operand-arrival lane order.
    reset_phase;allocate(3,0,1,3,2);
    bind_pair(3,1,0,64'h80000024,64'h80000010,2,3);wait_hot;
    check(tv==3&&token=={slots[1],slots[0]}&&va=={64'h80000024,64'h80000010}&&
          protection==8'h67,"reverse-age hot binds selected input order");
    tr_ready=3;tick;check(total==2,"reverse-age dual requests not unique");

    // A real older store first requests translation without head permission.
    // Its needs-AD response makes a head replay; that old replay keeps lane0
    // while two reverse-age hot binds compete for only spare lane1.
    reset_phase;allocate(3,0,1,8'h23,3);allocate(1,2,3,3,0);
    bind_pair(1,0,1,64'h80000400,0,8'h23,0);tick;
    check(tv==1&&!ta_ad[0]&&access_kind[1:0]==2,"initial store AD fixture");
    tr_ready=1;tick;tr_ready=0;
    rsp_token={I'(0),slots[0]};tr_rsp=1;needs_ad=1;tick;tr_rsp=0;needs_ad=0;
    check(dut.needs_ad_q[slots[0]],"needs AD response did not persist");
    head_valid=1;head_tag=0;effect_allow=1;allow_ad_replay=1;
    bind_pair(3,2,1,64'h80000420,64'h80000410,3,3);
    if(BIND_TO_TRANSLATION==1)
      check(tv==3&&token=={slots[1],slots[0]}&&ta_ad[0]&&
            va=={64'h80000410,64'h80000400},"old AD priority or hot age priority");
    else check(tv==1&&token[0+:I]==slots[0]&&ta_ad[0],"baseline AD priority");
    tr_ready=3;repeat(6)tick;
    check(total==4&&accepted[slots[0]]==2&&accepted[slots[1]]==1&&accepted[slots[2]]==1,
          "AD and hot fallback did not transfer exactly once");
    $display("BIND_ORDER reverse_hot=1 old_AD_priority=1 AD_plus_two_hot=1");
    // Input lane1 can use physical translation lane0's spare queue credit.
    reset_phase;allocate(1,0,1,3,0);
    bind_pair(2,1,0,0,64'h80000030,0,3);wait_hot;
    check(tv==1&&token[0+:I]==slots[0]&&va[63:0]==64'h80000030,
          "single bind_fire lane1 did not use first spare translation lane");

    // The older FP owner keeps lane0 priority. A hot bind can use spare
    // lane1 on that edge; NORMAL admits the younger NEW one edge later into
    // lane0's second queue slot. Check the actual ordered handshake in both.
    reset_phase;allocate(3,0,1,8'h43,3);
    bind_pair(1,0,1,64'h80000040,0,8'h43,0);
    bind_pair(2,0,1,0,64'h80000048,0,3);
    if(BIND_TO_TRANSLATION==1)
      check(tv==3&&token=={slots[1],slots[0]}&&va=={64'h80000048,64'h80000040},
            "existing NEW did not precede hot bind_fire");
    else begin
      check(tv==1&&token[0+:I]==slots[0]&&va[63:0]==64'h80000040,
            "NORMAL older NEW owner");
      tick;
      check(tv==1&&token[0+:I]==slots[0]&&va[63:0]==64'h80000040,
            "NORMAL younger NEW displaced held older head");
      tr_ready=1;tick;
      check(total==1&&tv==1&&token[0+:I]==slots[1]&&va[63:0]==64'h80000048&&
            protection[3:0]==7&&access_kind[1:0]==1&&ta_ad[0],
            "NORMAL queued younger NEW owner/metadata");
    end
    tr_ready=3;tick;check(total==2&&tv==0,"old NEW plus younger bind not accepted exactly once");

    reset_phase;allocate(3,0,1,8'h43,8'h43);allocate(3,2,3,3,3);
    bind_pair(3,0,1,64'h80000050,64'h80000058,8'h43,8'h43);
    bind_pair(3,2,3,64'h80000060,64'h80000068,3,3);
    check(tv==3&&token=={slots[1],slots[0]},"two existing NEW owners lost priority");
    tr_ready=3;tick;tick;tick;
    check(total==4,"two old plus two fallback loads did not issue exactly once");

    // Fill both physical queue slots in each lane, then bind_fire two more loads.
    // No same-cycle downstream pop is borrowed as allocation credit.
    reset_phase;allocate(3,0,1,3,3);allocate(3,2,3,3,3);allocate(3,4,5,3,3);
    bind_pair(3,0,1,64'h80000100,64'h80000108,3,3);
    bind_pair(3,2,3,64'h80000110,64'h80000118,3,3);
    bind_pair(3,4,5,64'h80000120,64'h80000128,3,3);
    repeat(3)tick;
    check(tv==3&&dut.translation_credit_w==0,"full queue fixture");
    tr_ready=3;repeat(6)tick;check(total==6,"Q-full bind_fire fallback duplicated or lost request");

    // Full Q at the start of the edge cannot lend the credit released by a
    // simultaneous actual pop to a newly bound row.
    reset_phase;allocate(3,0,1,3,3);allocate(3,2,3,3,3);allocate(3,4,5,3,3);
    bind_pair(3,0,1,64'h80000140,64'h80000148,3,3);
    bind_pair(3,2,3,64'h80000150,64'h80000158,3,3);
    check(dut.translation_credit_w==0,"full Q plus pop setup");
    tr_ready=3;
    bind_pair(3,4,5,64'h80000160,64'h80000168,3,3);
    check(accepted[slots[4]]==0&&accepted[slots[5]]==0&&
          dut.state_q[slots[4]]==dut.NEW&&dut.state_q[slots[5]]==dut.NEW,
          "same-edge pop lent unregistered hot admission credit");
    repeat(6)tick;check(total==6,"full Q plus pop fallback lost or duplicated request");

    cold(8'h03,64'h80000203);
    cold(8'h43,64'h80000208);
    cold(8'h83,64'h80000210);
    if(!STORE_HOT)cold(8'h23,64'h80000218);
    reset_phase;trigger_enable=1;trigger_address=64'hdead;
    allocate(1,0,1,3,0);bind_pair(1,0,1,64'h80000220,0,3,0);
    check(tv==0,"active trigger took shortcut");tick;check(tv==0,"trigger check not retained");
    tick;check(tv==1,"checked load failed to translate");
    reset_phase;fp_enable=0;allocate(1,0,1,8'h43,0);
    bind_pair(1,0,1,64'h80000228,0,8'h43,0);
    repeat(5)begin tick;check(tv==0,"disabled FP translated");end
    reset_phase;trigger_enable=1;trigger_address=64'h80000230;
    allocate(1,0,1,3,0);bind_pair(1,0,1,trigger_address,0,3,0);
    repeat(5)begin tick;check(tv==0,"matched trigger translated");end

    // Wrong-generation bind_fire cannot consume a queue slot. Matching kill on
    // the bind_fire edge likewise prevents admission, including its fast path.
    reset_phase;allocate(1,0,1,3,0);
    bind_pair(1,9'h20,1,64'h80000300,0,3,0);
    repeat(2)begin tick;check(tv==0,"stale bind_fire acquired translation");end
    kill=1;bind_pair(1,0,1,64'h80000300,0,3,0);kill=0;
    repeat(3)begin tick;check(tv==0,"same-edge kill published hot bind_fire");end
    allocate(1,9'h20,1,3,0);
    bind_pair(1,0,1,64'h80000308,0,3,0);tick;check(tv==0,"reused slot accepted old fulltag");
    bind_pair(1,9'h20,1,64'h80000310,0,3,0);wait_hot;check(tv==1,"reused fulltag lost owner");
    kill=1;#1;check(tv==0,"queued killed hot load still offered");tick;kill=0;
    repeat(3)tick;check(idle&&reuse==0,"unissued killed queue leaked owner");

    reset_phase;allocate(1,0,1,3,0);bind_pair(1,0,1,64'h80000320,0,3,0);wait_hot;
    flush=1;#1;check(tv==0,"flush failed to suppress queued request");tick;flush=0;
    repeat(3)tick;check(idle&&reuse==0,"flush retained unissued owner");
    reset_phase;allocate(1,0,1,3,0);flush=1;
    bind_pair(1,0,1,64'h80000328,0,3,0);flush=0;
    repeat(3)tick;check(tv==0&&idle,"same-edge flush admitted bind_fire");

    // Once translation accepts the token, kill must drain its response before
    // the physical LSQ slot becomes reusable, with no completion publication.
    reset_phase;allocate(1,0,1,3,0);bind_pair(1,0,1,64'h80000330,0,3,0);wait_hot;
    tr_ready=1;tick;tr_ready=0;check(total==1,"accepted-kill fixture");
    kill=1;tick;kill=0;check(reuse[0]&&!idle,"accepted token released before drain");
    rsp_token={I'(0),slots[0]};tr_rsp=1;tick;tr_rsp=0;
    repeat(5)begin tick;check(ov==0,"killed translation published completion");end
    check(idle&&reuse==0,"accepted killed token failed to drain");
    $display("[PASS] tb_r64_bind_translation_flow queued_bind_latency=%0d dual_rank_old_NEW_full_credit_trigger_FP_alignment_kill_flush_fulltag=1",
             BIND_TO_TRANSLATION);
    $finish;
  end
  initial begin #100000;$fatal(1,"bind_fire translation timeout");end
endmodule
