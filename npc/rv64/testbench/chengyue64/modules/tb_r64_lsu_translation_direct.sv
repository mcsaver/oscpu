`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_lsu_translation_direct;
  parameter DIRECT = 1;
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
  integer start_cycle, before_count, budget;
  reg [255:0] held;
  R64Lsu #(.ENTRIES(N),.INDEX_W(I),.BIND_TRANSLATION_BYPASS(BIND_BYPASS),
             .TRANSLATION_QUERY_BYPASS(DIRECT)) dut (
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),
    .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),
    .trigger_enable_i(3'b0),.trigger_address_i(64'b0),
    .fp_enable_i(1'b1),.translate_active_i(1'b0),
    .commit_fire_i(2'b0),.commit_tag_i(18'b0),
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
    .store_done_ready_i(1'b1),.mem_store_rsp_valid_i(1'b0),
    .mem_store_rsp_token_i({I{1'b0}}),.mem_store_rsp_error_i(1'b0)
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
      if(ov[l]) outputs=outputs+1;
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
      total=0;outputs=0;
      for(integer n=0;n<N;n=n+1)begin translations[n]=0;physical[n]=0;physcycle[n]=-1;end
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
  initial begin
    reset_phase;launch(0,3,64'h80000100);mem_ready=3;
    response(0,0,64'h80000100);start_cycle=cycle+1;
    check(mv==(DIRECT?1:0),"single response issue phase");finish_response;await_physical(1);
    check(physcycle[slots[0]]-start_cycle==(DIRECT?0:1),"translation physical edge gap");
    check(dut.mem_issued_q[slots[0]] && dut.state_q[slots[0]]==4,"accepted direct owner not MEMORY");
    $display("MEASURE translation_response_to_physical=%0d bind_bypass=%0d",physcycle[slots[0]]-start_cycle,BIND_BYPASS);
    return_memory(0);repeat(4)tick;check(outputs==1&&idle,"single completion lifecycle");

    // Two independently accepted translation responses can issue both lanes.
    reset_phase;launch(0,3,64'h80000200);launch(1,3,64'h80000208);mem_ready=3;
    response(0,0,64'h80000200);response(1,1,64'h80000208);
    check(mv==(DIRECT?3:0),"dual response direct issue");finish_response;await_physical(2);
    check(physcycle[slots[0]]==physcycle[slots[1]],"dual response serialized");

    // VALID is independent of READY. Stalling transfers the same payload to
    // query and then the physical holder, with no extra memory acceptance.
    reset_phase;launch(0,3,64'h80000300);response(0,0,64'h80001300);
    if(DIRECT)begin check(mv==1,"ready-zero suppressed direct valid");held=payload(0);end
    finish_response;check(mv==1,"stall failed query fallback");
    if(!DIRECT)held=payload(0);
    for(integer n=0;n<5;n=n+1)begin
      check(payload(0)===held && mv==1,"stalled payload changed");tick;
    end
    check(total==0&&dut.physical_hold_valid_q[0],"stall lost physical holder");
    mem_ready=1;await_physical(1);repeat(3)tick;check(total==1,"fallback duplicated direct request");

    // Old query and held physical requests win over new translation responses.
    reset_phase;launch(0,3,64'h80000400);launch(1,3,64'h80000408);launch(2,3,64'h80000410);
    response(0,0,64'h80000400);finish_response;
    response(0,1,64'h80000408);
    check(dut.query_occupied_w[0]&&!dut.translation_direct_offer_w[0]&&mtoken[0+:I]==slots[0],
          "resident query lost priority");finish_response;
    response(0,2,64'h80000410);
    check(dut.physical_hold_valid_q[0]&&!dut.translation_direct_offer_w[0]&&mtoken[0+:I]==slots[0],
          "physical holder lost priority");finish_response;
    mem_ready=1;await_physical(3);
    check(physcycle[slots[0]]<physcycle[slots[1]]&&physcycle[slots[1]]<physcycle[slots[2]],"queue order changed");

    // The prepared route owns lane0 even before it has a ROB head lease.
    reset_phase;allocate(0,3);launch(1,8'h23,64'h80000508);
    response(0,1,64'h80000508);finish_response;repeat(3)tick;
    check(dut.prepared_direct_route_w&&!dut.prepared_offer_w,"prepared route fixture");
    bind_one(0,3,64'h80000500);accept_translation(0);mem_ready=3;
    response(0,0,64'h80000500);
    check(dut.descriptor_tr_take_w[0]&&!dut.translation_direct_offer_w[0]&&mv==0,
          "load stole unoffered prepared route");finish_response;await_physical(1);
    check(physical[slots[0]]==1&&physical[slots[1]]==0,"prepared priority fallback owner");

    // Qualification retains FP, MMIO, faults, A/D, split and atomic cold paths.
    cold_response(8'h43,64'h80000600,0,0,0);
    cold_response(3,64'h80000600,2,0,0);
    cold_response(3,64'h80000600,0,1,0);
    cold_response(3,64'h80000600,0,0,1);
    cold_response(3,64'h80000601,0,0,0);
    cold_response(8'h83,64'h80000600,0,0,0);
    cold_response(8'h23,64'h80000600,0,0,0);
    reset_phase;allocate(0,8'h23);launch(1,3,64'h80000680);mem_ready=3;
    response(0,1,64'h80000680);
    check(!dut.descriptor_tr_take_w[0]&&!dut.translation_direct_offer_w[0],"older store ordering bypassed");
    finish_response;repeat(3)tick;check(total==0,"unbound older store barrier bypassed");

    // Same-edge cancellation suppresses an offer but drains the translation.
    reset_phase;launch(0,3,64'h80000700);mem_ready=3;kill=1;
    response(0,0,64'h80000700);check(mv==0,"killed response issued");finish_response;
    kill=0;repeat(4)tick;check(total==0&&outputs==0&&idle,"translation kill did not drain");
    reset_phase;launch(0,3,64'h80000700);mem_ready=3;flush=1;
    response(0,0,64'h80000700);check(mv==0,"flushed response issued");finish_response;
    flush=0;repeat(4)tick;check(total==0&&outputs==0&&idle,"translation flush did not drain");

    // A stalled response must also be cancellable after its fallback capture,
    // both while resident in query and after moving into the physical holder.
    for(integer hold_stage=0;hold_stage<2;hold_stage=hold_stage+1)begin
      reset_phase;launch(0,3,64'h80000780);response(0,0,64'h80000780);finish_response;
      if(hold_stage!=0)tick;
      kill=1;mem_ready=3;#1;check(mv==0,"cancelled fallback exposed physical request");
      tick;kill=0;repeat(4)tick;
      check(total==0&&outputs==0&&idle&&reuse==0,"cancelled fallback leaked owner");
    end

    // Accepted memory owner survives kill for drain. Reusing its ROB index
    // and LSQ slot cannot retain an old forwarding mask or produce old WB.
    reset_phase;launch(0,3,64'h80000800);mem_ready=3;
    response(0,0,64'h80000800);finish_response;await_physical(1);
    kill=1;tick;kill=0;check(reuse[0]&&!idle,"accepted killed memory owner released early");
    return_memory(0);repeat(4)tick;check(outputs==0&&idle,"killed memory published completion");
    allocate(9'd32,3);physical[slots[0]]=0;translations[slots[0]]=0;
    bind_one(9'd32,3,64'h80000808);accept_translation(9'd32);
    response(0,9'd32,64'h80000808);
    if(DIRECT)check(dut.physical_tag_w[0]==9'd32,"direct full tag reused stale generation");
    finish_response;await_physical(2);return_memory(9'd32);repeat(4)tick;
    check(outputs==1&&idle,"new full-tag owner lost completion");
    $display("[PASS] tb_r64_lsu_translation_direct direct=%0d checks=%0d direct_accepts=%0d query_fallbacks=%0d dual_stall_old_query_held_prepared_cold_order_kill_flush_reuse=1",
             DIRECT,checks,direct_total,fallbacks);$finish;
  end
  initial begin #100000;$fatal(1,"translation direct timeout");end
endmodule
