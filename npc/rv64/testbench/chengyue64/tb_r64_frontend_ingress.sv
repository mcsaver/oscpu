`timescale 1ns/1ps
module tb_r64_frontend_ingress;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,run=1,redirect=0,tlinv=0,pbmt_enable=0,allow_pte=0;
 reg [63:0] target=64'h40000000,satp=64'h8000700000000001,status=64'h000e1800;
 reg [1:0] priv=1;
 wire [1:0] valid,fault;wire [127:0] pc,raw,npc,tval;wire [7:0] len;wire [9:0] cause;
 wire [63:0] protect,ca,pe,pm;wire [1:0] protectpriv;
 wire cv,br,pv,po,prr;wire [55:0] paddr;wire [7:0] cl;wire [2:0] cs;
 reg cache_active=0,pte_active=0;integer beat=0;
 reg [63:0] pte_data=0;
 wire [1:0] consume=redirect?2'b0:(valid[1]?2'd2:(valid[0]?2'd1:2'd0));
 R64Frontend #(.RESET_PC(64'h40000000),.ICACHE_SET_W(1)) dut(
 .clk_i(clk),.rst_i(rst),.run_i(run),.redirect_i(redirect),.redirect_pc_i(target),
 .priv_i(priv),.mstatus_i(status),.satp_i(satp),.pbmt_enable_i(pbmt_enable),.icache_invalidate_i(1'b0),
 .tlb_invalidate_i(tlinv),.tlb_all_vaddr_i(1'b1),.tlb_all_asid_i(1'b1),
 .tlb_vpn_i(27'b0),.tlb_asid_i(16'b0),.valid_o(valid),.consume_i(consume),
 .pc_o(pc),.raw_o(raw),.length_o(len),.predicted_npc_o(npc),.fault_o(fault),.cause_o(cause),.tval_o(tval),
 .prediction_update_i(1'b0),.prediction_pc_i(64'b0),.prediction_conditional_i(1'b0),
 .prediction_indirect_i(1'b0),.prediction_taken_i(1'b0),.prediction_target_i(64'b0),
 .protect_paddr_o(protect),.protect_priv_o(protectpriv),.protect_facts_i(130'b0),.protect_fault_mask_i(8'b0),.protect_uncached_i(1'b0),
 .cache_cmd_valid_o(cv),.cache_cmd_ready_i(!cache_active),.cache_cmd_addr_o(ca),.cache_cmd_len_o(cl),.cache_cmd_size_o(cs),
 .cache_beat_valid_i(cache_active),.cache_beat_ready_o(br),.cache_beat_data_i(64'h0001000100010001),
 .cache_beat_resp_i(2'b0),.cache_beat_last_i(beat==7),
 .pte_valid_o(pv),.pte_ready_i(!pte_active),.pte_compare_or_o(po),.pte_addr_o(paddr),
 .pte_expected_o(pe),.pte_or_mask_o(pm),.pte_rsp_valid_i(pte_active&&allow_pte),.pte_rsp_ready_o(prr),
 .pte_rdata_i(pte_data),.pte_error_i(1'b0),.pte_compare_ok_i(1'b0));
 reg [135:0] contexts[0:2047];reg poisons[0:2047];
 reg [63:0] expected_pa[0:2047];reg [1:0] expected_priv[0:2047];
 integer accepted=0,translated=0,responses=0,old_pte=0,new_pte=0,cycles=0;
 integer held_context=0,poisoned_dispatch=0,full_blocked=0,cancel_held=0,release_waiter=0,accept_with_sfence=0,delivered=0,k;
 reg [63:0] expected_pc=64'h40000000;
 reg holding=0;reg [135:0] held_payload;
 reg [135:0] actual_context;reg [63:0] captured_va,captured_satp;
 reg [1:0] captured_priv;
 always @(posedge clk)if(!rst)begin
  cycles=cycles+1;if(cycles>4000)$fatal(1,"ingress timeout");
  if(holding&&dut.if_req_payload_q!==held_payload)$fatal(1,"held context re-sampled CSR");
  holding=dut.if_req_valid_q&&!dut.if_req_ready_w;held_payload=dut.if_req_payload_q;
  if(holding)held_context=held_context+1;
  if(dut.if_req_valid_q)begin
   if(dut.fetch_r_w)$fatal(1,"full ingress advertised same-edge borrowed credit");
   full_blocked=full_blocked+1;
   if(dut.if_req_ready_w&&dut.fetch_v_w)release_waiter=release_waiter+1;
   if(tlinv||dut.stream_redirect_w)cancel_held=cancel_held+1;
  end
  if(tlinv||dut.stream_redirect_w)
   for(k=translated;k<accepted;k=k+1)poisons[k]=1;
  if(dut.fetch_v_w&&dut.fetch_r_w)begin
   if(tlinv)accept_with_sfence=accept_with_sfence+1;
   contexts[accepted]={dut.fetch_pc_w,priv,satp,status[19:17],status[12:11],pbmt_enable};
   poisons[accepted]=tlinv||dut.stream_redirect_w;accepted=accepted+1;
  end
  if(dut.u_translation.req_valid_i&&dut.u_translation.req_ready_o)begin
   if(translated>=accepted)$fatal(1,"translation accepted no ingress owner");
   actual_context={dut.u_translation.req_vaddr_i,dut.u_translation.req_priv_i,
    dut.u_translation.req_satp_i,dut.u_translation.req_mstatus_i[19:17],
    dut.u_translation.req_mstatus_i[12:11],dut.u_translation.req_pbmt_enable_i};
   if(actual_context!==contexts[translated]||dut.u_translation.req_poison_i!==poisons[translated])
    $fatal(1,"wrong acceptance context/poison owner=%0d got%h expected%h poison%b/%b",
     translated,actual_context,contexts[translated],dut.u_translation.req_poison_i,poisons[translated]);
   captured_va=contexts[translated][135:72];captured_priv=contexts[translated][71:70];
   captured_satp=contexts[translated][69:6];
   expected_priv[translated]=captured_priv;
   expected_pa[translated]=captured_priv==3?captured_va:
    (captured_satp[43:0]==1?64'h80000000:64'hc0000000)+{34'b0,captured_va[29:0]};
   if(dut.u_translation.req_poison_i)poisoned_dispatch=poisoned_dispatch+1;
   translated=translated+1;
  end
  if(accepted-translated>1)$fatal(1,"ingress capacity exceeded");
  if(dut.translation_v_w&&dut.translation_r_w)begin
   if(responses>=translated||protect!==expected_pa[responses]||
      protectpriv!==expected_priv[responses]||dut.translation_fault_w)
    $fatal(1,"translation response context/physical owner %0d PA%h expected%h",responses,protect,expected_pa[responses]);
   responses=responses+1;
  end
  if(pv&&!pte_active)begin
   if(po)$fatal(1,"unexpected speculative PTE effect");
   pte_active<=1;
   if(paddr==56'h1008)begin pte_data<=64'h200000cf;old_pte=old_pte+1;end
   else if(paddr==56'h2008)begin pte_data<=64'h300000cf;new_pte=new_pte+1;end
   else $fatal(1,"wrong captured SATP root PTE address %h",paddr);
  end
  if(pte_active&&allow_pte&&prr)pte_active<=0;
  if(cv&&!cache_active)begin
   if(cl!=7||cs!=3||ca[5:0]!=0)$fatal(1,"cache command contract");
   cache_active<=1;beat<=0;
  end else if(cache_active&&br)begin
   if(beat==7)cache_active<=0;else beat<=beat+1;
  end
  if(redirect)expected_pc=target;
  else for(k=0;k<consume;k=k+1)begin
   if(pc[k*64+:64]!==expected_pc||raw[k*64+:64]!==64'h1||
      len[k*4+:4]!=2||fault[k]||npc[k*64+:64]!==expected_pc+2)
    $fatal(1,"stale instruction escaped redirect %h expected%h",pc[k*64+:64],expected_pc);
   expected_pc=expected_pc+2;delivered=delivered+1;
  end
 end
 initial begin
  repeat(3)@(negedge clk);rst=0;
  wait(dut.if_req_valid_q&&pte_active);
  // The overflow owner remains old S/root1/PBMT0 while CSR inputs change.
  @(negedge clk);priv=3;satp=64'h8000700000000002;status=64'h00020000;pbmt_enable=1;tlinv=1;
  @(negedge clk);tlinv=0;redirect=1;target=64'h81000000;
  @(negedge clk);redirect=0;
  repeat(9)@(negedge clk);
  allow_pte=1;
  wait(delivered>=24);
  // Same ASID, new root, no extra invalidate: poisoned old request must not
  // have recreated its old mapping after the earlier SFENCE.
  @(negedge clk);priv=1;redirect=1;target=64'h40000000;
  @(negedge clk);redirect=0;
  wait(delivered>=56);
  @(negedge clk);run=0;
  repeat(150)@(negedge clk);
  // Empty ingress may make a real acceptance promise on the SFENCE edge.
  // Translation itself is blocked; this new queued owner must retain poison.
  @(negedge clk);run=1;
  @(negedge clk);tlinv=1;
  @(negedge clk);tlinv=0;redirect=1;target=64'h40001000;
  @(negedge clk);redirect=0;
  wait(delivered>=96);
  @(negedge clk);run=0;
  repeat(150)@(negedge clk);
  if(accepted!=translated||translated!=responses||dut.if_req_valid_q||
     held_context<10||poisoned_dispatch<1||old_pte<2||new_pte<1||cancel_held<2||release_waiter<1||accept_with_sfence<1)
    $fatal(1,"ingress coverage/drain accepted%0d translated%0d responses%0d held%0d poison%0d oldpte%0d newpte%0d cancel%0d",
      accepted,translated,responses,held_context,poisoned_dispatch,old_pte,new_pte,cancel_held);
  $display("[PASS] tb_r64_frontend_ingress");
  $display("INGRESS accepted=%0d translated=%0d responses=%0d held_context=%0d full_blocked=%0d poisoned_dispatch=%0d cancel_held=%0d old_root_PTE=%0d new_root_PTE=%0d instructions=%0d release_with_waiter=%0d accept_with_sfence=%0d",
    accepted,translated,responses,held_context,full_blocked,poisoned_dispatch,cancel_held,old_pte,new_pte,delivered,release_waiter,accept_with_sfence);
  $finish;
 end
endmodule
