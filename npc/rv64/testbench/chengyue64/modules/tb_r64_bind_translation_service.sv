`timescale 1ns/1ps
`include "R64Protocol.vh"
// Actual LSU and translation/protection/token endpoint. Only physical memory
// and page-table storage are independent test endpoints.
module tb_r64_bind_translation_service #(parameter FLOW=1,STORE_HOT=1);
  localparam N=12,I=4,C=`R64_MEM_CMD_W,R=`R64_RESULT_W;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;
  reg[31:0] kill=0;
  reg[1:0] reserve=0,bind_fire=0,req_enable=3,rsp_enable=3,physical_enable=0;
  reg[17:0] reserve_tag=0,bind_tag=0;
  reg[15:0] reserve_func=0;
  reg[2*I-1:0] bind_slot=0;
  reg[2*C-1:0] command=0;
  reg head_valid=0,effect_allow=0;
  reg[8:0] head_tag=0;
  reg[1:0] privilege=3;
  reg[63:0] mstatus=0,satp=0;
  reg[15:0] pmp_active=0;
  reg[895:0] pmp_lower=0,pmp_upper=0;
  reg[63:0] pmp_permission=0;
  wire[1:0] reserve_ready,tv,tr_ready,service_ready,service_rsp,lsu_rsp_ready;
  wire[2*I-1:0] reserve_slot,token,rsp_token;
  wire[127:0] va,pa;
  wire[3:0] access_kind,classes;
  wire[7:0] protection;
  wire[1:0] ad,fault,needs_ad,ov,mv,mready,mrsp_ready;
  wire[9:0] causes;
  wire[17:0] out_tag;
  wire[2*R-1:0] result;
  wire[31:0] reuse;
  wire idle,service_idle;
  wire[127:0] ma;
  wire[2*I-1:0] mtoken;
  reg[1:0] mrsp=0;
  reg[2*I-1:0] mrsp_token=0;
  reg[127:0] mrsp_data=0;
  wire[1:0] pv,pcas,prr;
  wire[111:0] paddr;
  wire[127:0] pexpected,pmask;
  reg[1:0] pending=0,pcmp=0;
  reg[127:0] prdata=0;
  reg[63:0] leaf_pte=64'h20000007;
  integer due[0:1];
  wire[1:0] pr=~pending;
  wire[1:0] prv={pending[1]&&cycles>=due[1],pending[0]&&cycles>=due[0]};
  wire[1:0] terminal=service_rsp & rsp_enable;
  assign tr_ready=service_ready & req_enable;
  assign mready=~mrsp & physical_enable;
  R64Lsu #(.ENTRIES(N),.INDEX_W(I),.BIND_TRANSLATION_EMPTY_FLOW(FLOW),
    .BIND_STORE_TRANSLATION(STORE_HOT)) lsu(
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .cancel_candidates_i(kill),.cancel_active_i(|kill),
    .head_valid_i(head_valid),.head_tag_i(head_tag),.effect_allow_i(effect_allow),
    .trigger_enable_i(3'b0),.trigger_address_i(64'b0),.fp_enable_i(1'b1),
    .translate_active_i(satp[63]),.commit_fire_i(2'b0),.commit_tag_i(18'b0),
    .reserve_want_i(2'b11),.reserve_fire_i(reserve),.reserve_ready_o(reserve_ready),
    .reserve_slot_o(reserve_slot),.reserve_tag_i(reserve_tag),.reserve_func_i(reserve_func),.reserve_amo_i(10'b0),
    .in_fire_i(bind_fire),.in_slot_i(bind_slot),.in_tag_i(bind_tag),.in_command_i(command),
    .out_valid_o(ov),.out_ready_i(2'b11),.out_tag_o(out_tag),.out_result_o(result),
    .reuse_block_o(reuse),.idle_o(idle),
    .tr_valid_o(tv),.tr_ready_i(tr_ready),.tr_token_o(token),.tr_vaddr_o(va),
    .tr_access_o(access_kind),.tr_ad_update_o(ad),.tr_request_protection_o(protection),
    .tr_rsp_valid_i(terminal),.tr_rsp_ready_o(lsu_rsp_ready),.tr_rsp_token_i(rsp_token),
    .tr_paddr_i(pa),.tr_class_i(classes),.tr_fault_i(fault),.tr_needs_ad_i(needs_ad),.tr_cause_i(causes),
    .mem_valid_o(mv),.mem_ready_i(mready),.mem_addr_o(ma),.mem_token_o(mtoken),
    .mem_rsp_valid_i(mrsp),.mem_rsp_ready_o(mrsp_ready),.mem_rsp_token_i(mrsp_token),
    .mem_rsp_data_i(mrsp_data),.mem_rsp_error_i(2'b0),.mem_rsp_offset_i(6'b0),
    .store_done_ready_i(1'b1),.mem_store_rsp_valid_i(1'b0),
    .mem_store_rsp_token_i(I'(0)),.mem_store_rsp_error_i(1'b0)
  );
  R64DataTranslationService #(.TOKEN_W(I)) service(
    .clk_i(clk),.rst_i(rst),.req_valid_i(tv&req_enable),.req_ready_o(service_ready),
    .req_token_i(token),.req_vaddr_i(va),.req_access_i(access_kind),.req_protection_i(protection),
    .req_ad_update_i(ad),.rsp_valid_o(service_rsp),.rsp_ready_i(lsu_rsp_ready&rsp_enable),
    .rsp_token_o(rsp_token),.rsp_paddr_o(pa),.rsp_class_o(classes),.rsp_fault_o(fault),
    .rsp_needs_ad_o(needs_ad),.rsp_cause_o(causes),.idle_o(service_idle),
    .privilege_i(privilege),.mstatus_i(mstatus),.satp_i(satp),.pbmt_enable_i(1'b1),
    .pmp_active_i(pmp_active),.pmp_lower_i(pmp_lower),.pmp_upper_i(pmp_upper),.pmp_permission_i(pmp_permission),
    .tlb_invalidate_i(1'b0),.tlb_all_vaddr_i(1'b1),.tlb_all_asid_i(1'b1),.tlb_vpn_i(27'b0),.tlb_asid_i(16'b0),
    .mem_valid_o(pv),.mem_ready_i(pr),.mem_compare_or_o(pcas),.mem_addr_o(paddr),
    .mem_expected_o(pexpected),.mem_or_mask_o(pmask),.mem_rsp_valid_i(prv),.mem_rsp_ready_o(prr),
    .mem_rdata_i(prdata),.mem_error_i(2'b0),.mem_compare_ok_i(pcmp)
  );
  reg[I-1:0] slots[0:31];
  integer accepts[0:N-1],responses[0:N-1],accept_edge[0:N-1],response_edge[0:N-1],physical[0:N-1];
  reg[63:0] expected_va[0:N-1];
  reg expected_store[0:N-1],accepted_ad[0:N-1];
  reg[8:0] slot_tag[0:N-1];
  reg expected_fault=0;
  integer expected_cause=0;
  integer cycles=0,checks=0,outputs=0,walks=0,cas_count=0,needa_count=0;
  integer start_cycle,budget;
  reg[63:0] last_value=0;
  reg[1:0] held=0;
  reg[74:0] held_payload[0:1];
  function[63:0] memory_value(input[63:0]address);
    memory_value=address ^ 64'h1234567800000000;
  endfunction
  task check(input bit good,input[767:0]message);
    begin checks=checks+1;if(good!==1'b1)$fatal(1,"%0s cycle=%0d",message,cycles);end
  endtask
  always @(posedge clk)begin
    cycles=cycles+1;
    if(rst)begin pending<=0;mrsp<=0;held<=0;end
    else begin
      for(integer l=0;l<2;l=l+1)begin
        if(tv[l]&&tr_ready[l])begin
          integer t;t=int'(token[l*I+:I]);
          check(va[l*64+:64]===expected_va[t],"actual token/VA changed");
          check(access_kind[l*2+:2]==(expected_store[t]?2:1),"actual operation changed");
          check(protection[l*4+:4]==(expected_store[t]?4'b1011:4'b0111),"actual protection changed");
          if(expected_store[t])check(ad[l]==(head_valid && slot_tag[t]==head_tag && effect_allow),"nonhead store gained AD authority");
          accepts[t]=accepts[t]+1;accept_edge[t]=cycles;accepted_ad[t]=ad[l];
        end
        if(terminal[l]&&lsu_rsp_ready[l])begin
          integer t;t=int'(rsp_token[l*I+:I]);
          check(responses[t]<accepts[t],"service response without prior actual token acceptance");
          check(cycles>accept_edge[t],"bind and protected terminal collapsed onto one edge");
          check(fault[l]==expected_fault,"PMP/translation fault changed");
          if(fault[l])check(causes[l*5+:5]==5'(expected_cause),"precise access-fault cause");
          else check(pa[l*64+:64]==(satp[63]?(64'h80000000|expected_va[t]):expected_va[t]),"translated PA mismatch");
          if(needs_ad[l])begin check(expected_store[t]&&!accepted_ad[t],"invalid needs-AD return");needa_count=needa_count+1;end
          responses[t]=responses[t]+1;response_edge[t]=cycles;
        end
        if(held[l] && !flush && !kill[slot_tag[token[l*I+:I]][4:0]])
          check(tv[l]&&{token[l*I+:I],va[l*64+:64],protection[l*4+:4],access_kind[l*2+:2],ad[l]}===held_payload[l],
                "blocked translation payload did not survive row/Q fallback");
        held[l]<=tv[l]&&!tr_ready[l];
        held_payload[l]<={token[l*I+:I],va[l*64+:64],protection[l*4+:4],access_kind[l*2+:2],ad[l]};
        if(mv[l]&&mready[l])begin
          integer t;t=int'(mtoken[l*I+:I]);check(!expected_store[t],"store side effect before explicit fixture permission");
          check(physical[t]==0,"duplicate physical operation");physical[t]=physical[t]+1;
          mrsp[l]<=1;mrsp_token[l*I+:I]<=mtoken[l*I+:I];mrsp_data[l*64+:64]<=memory_value(ma[l*64+:64]);
        end
        if(mrsp[l]&&mrsp_ready[l])mrsp[l]<=0;
        if(ov[l])begin
          reg[R-1:0] value;value=result[l*R+:R];
          check(out_tag[l*9+:9]===slot_tag[slots[out_tag[l*9+:5]]],"completion fulltag generation");
          outputs=outputs+1;check(value[`R64_R_EXCEPTION]==expected_fault,"canonical completion exception");
          if(expected_fault)check(value[`R64_R_CAUSE]==6'(expected_cause),"canonical precise fault cause");
          else begin last_value=value[`R64_R_DATA];check(last_value==memory_value(expected_va[slots[out_tag[l*9+:5]]]),"load value changed");end
        end
        if(pv[l]&&pr[l])begin
          check(paddr[l*56+:56]==56'h1000,"unexpected Sv39 root page-table address");
          pending[l]<=1;due[l]<=cycles+3;prdata[l*64+:64]<=leaf_pte;
          pcmp[l]<=leaf_pte==pexpected[l*64+:64];walks=walks+1;
          if(pcas[l])begin
            check(effect_allow&&head_valid,"page-table AD write before head lease");
            check(leaf_pte==pexpected[l*64+:64],"page-table compare identity");
            leaf_pte<=leaf_pte|pmask[l*64+:64];cas_count=cas_count+1;
          end
        end
        if(prv[l]&&prr[l])pending[l]<=0;
      end
    end
  end
  task tick;begin @(posedge clk);#1;end endtask
  task reset_phase;
    begin
      rst=1;reserve=0;bind_fire=0;kill=0;flush=0;req_enable=3;rsp_enable=3;physical_enable=0;
      head_valid=0;effect_allow=0;head_tag=0;privilege=3;mstatus=0;satp=0;pmp_active=0;pmp_lower=0;pmp_upper=0;pmp_permission=0;
      expected_fault=0;expected_cause=0;outputs=0;walks=0;cas_count=0;needa_count=0;leaf_pte=64'h20000007;
      for(integer n=0;n<N;n=n+1)begin accepts[n]=0;responses[n]=0;accept_edge[n]=-1;response_edge[n]=-1;physical[n]=0;end
      repeat(2)tick;rst=0;#1;
    end
  endtask
  task allocate(input[1:0]mask,input[8:0]tag0,tag1,input[7:0]fn0,fn1);
    begin
      reserve=mask;reserve_tag={tag1,tag0};reserve_func={fn1,fn0};#1;check((reserve_ready&mask)==mask,"reserve credit");
      if(mask[0])begin slots[tag0[4:0]]=reserve_slot[0+:I];slot_tag[reserve_slot[0+:I]]=tag0;end
      if(mask[1])begin slots[tag1[4:0]]=reserve_slot[I+:I];slot_tag[reserve_slot[I+:I]]=tag1;end
      tick;reserve=0;
    end
  endtask
  task bind_pair(input[1:0]mask,input[8:0]tag0,tag1,input[63:0]addr0,addr1,input[7:0]fn0,fn1);
    begin
      bind_fire=mask;bind_tag={tag1,tag0};bind_slot={slots[tag1[4:0]],slots[tag0[4:0]]};
      command={{5'b0,fn1,64'h42,64'b0,addr1},{5'b0,fn0,64'h41,64'b0,addr0}};
      if(mask[0])begin expected_va[slots[tag0[4:0]]]=addr0;expected_store[slots[tag0[4:0]]]=fn0[5];end
      if(mask[1])begin expected_va[slots[tag1[4:0]]]=addr1;expected_store[slots[tag1[4:0]]]=fn1[5];end
      tick;bind_fire=0;
    end
  endtask
  task await_response(input integer slot,count);
    begin budget=0;while(responses[slot]<count&&budget<150)begin tick;budget=budget+1;end
      check(responses[slot]==count,"service response timeout/duplicate");end
  endtask
  task await_output;
    begin budget=0;while(outputs==0&&budget<80)begin tick;budget=budget+1;end
      check(outputs==1,"completion timeout/duplicate");repeat(4)tick;check(outputs==1,"extra completion");end
  endtask
  initial begin
    reset_phase;physical_enable=3;allocate(1,0,1,3,0);start_cycle=cycles+1;
    bind_pair(1,0,1,64'h80000008,0,3,0);await_response(slots[0],1);await_output;
    check(accept_edge[slots[0]]-start_cycle==(FLOW?0:1),"bare load accept latency");
    check(response_edge[slots[0]]-accept_edge[slots[0]]==1,"Bare endpoint gained an unregistered terminal");
    $display("BIND_SERVICE load_accept=%0d protected_response=%0d complete_value=%h",
      accept_edge[slots[0]]-start_cycle,response_edge[slots[0]]-start_cycle,last_value);

    reset_phase;allocate(1,0,1,8'h23,0);start_cycle=cycles+1;
    bind_pair(1,0,1,64'h80000010,0,8'h23,0);await_response(slots[0],1);
    check(accept_edge[slots[0]]-start_cycle==(STORE_HOT?(FLOW?0:1):2),"bare store accept latency");
    check(response_edge[slots[0]]-accept_edge[slots[0]]==1&&!lsu.effect_q[slots[0]],"bare store terminal or authority");
    $display("BIND_SERVICE store_accept=%0d protected_response=%0d",
      accept_edge[slots[0]]-start_cycle,response_edge[slots[0]]-start_cycle);

    reset_phase;physical_enable=3;req_enable=0;allocate(3,0,1,3,3);
    bind_pair(3,1,0,64'h80000028,64'h80000020,3,3);
    repeat(6)tick;check(accepts[slots[0]]==0&&accepts[slots[1]]==0,"blocked endpoint accepted");
    req_enable=3;await_response(slots[0],1);await_response(slots[1],1);
    budget=0;while(outputs<2&&budget<50)begin tick;budget=budget+1;end
    check(outputs==2&&accepts[slots[0]]==1&&accepts[slots[1]]==1,"dual reverse fallback lost owner");

    // Effective U privilege under MPRV must still fail denied PMP; the bind
    // shortcut cannot bypass the registered translation/protection terminal.
    for(integer store_case=0;store_case<2;store_case=store_case+1)begin
      reset_phase;mstatus=64'h20000;pmp_active=1;pmp_lower[0+:56]=56'h80000000;pmp_upper[0+:56]=56'h80000fff;
      expected_fault=1;expected_cause=store_case?7:5;
      allocate(1,0,1,store_case?8'h23:8'h03,0);
      bind_pair(1,0,1,64'h80000030,0,store_case?8'h23:8'h03,0);
      await_response(slots[0],1);await_output;check(mv==0,"faulted owner reached physical memory");
    end
    $display("BIND_SERVICE MPRV_PMP_load_store_fault=1");

    // Real invalid Sv39 leaf produces precise page faults on the same
    // canonical response path as ordinary translation, without physical issue.
    for(integer store_case=0;store_case<2;store_case=store_case+1)begin
      reset_phase;privilege=1;satp=64'h8000000000000001;pmp_active=1;pmp_upper={896{1'b1}};pmp_permission=7;leaf_pte=0;
      expected_fault=1;expected_cause=store_case?15:13;
      allocate(1,0,1,store_case?8'h23:8'h03,0);
      bind_pair(1,0,1,64'h5000,0,store_case?8'h23:8'h03,0);
      await_response(slots[0],1);await_output;
      check(mv==0&&cas_count==0,"page fault issued memory or A/D write");
    end
    $display("BIND_SERVICE Sv39_load_store_page_fault=1");

    reset_phase;privilege=1;satp=64'h8000000000000001;pmp_active=1;pmp_upper={896{1'b1}};pmp_permission=7;
    allocate(1,0,1,8'h23,0);bind_pair(1,0,1,64'h4000,0,8'h23,0);await_response(slots[0],1);
    check(needa_count==1&&cas_count==0&&lsu.needs_ad_q[slots[0]]&&!lsu.effect_q[slots[0]],"nonhead store performed AD write");
    head_valid=1;head_tag=0;effect_allow=1;await_response(slots[0],2);
    check(cas_count==1&&(leaf_pte&64'hc0)==64'hc0&&!lsu.needs_ad_q[slots[0]],"head store failed real Sv39 AD replay");
    check(accepts[slots[0]]==2,"AD replay accepted more than one owner per phase");
    $display("BIND_SERVICE Sv39_store_needsAD=1 head_replay=1 walks=%0d cas=%0d",walks,cas_count);

    reset_phase;rsp_enable=0;allocate(1,0,1,3,0);bind_pair(1,0,1,64'h80000040,0,3,0);
    repeat(5)tick;check(service_rsp!=0&&accepts[slots[0]]==1,"held service terminal fixture");
    kill=1;tick;kill=0;repeat(3)tick;
    check(reuse[0]&&!idle&&!service_idle,"accepted killed token released before actual response drain");
    rsp_enable=3;await_response(slots[0],1);repeat(5)tick;
    check(idle&&service_idle&&reuse==0&&outputs==0,"killed token did not drain exactly once");
    physical_enable=3;allocate(1,9'h20,1,3,0);bind_pair(1,9'h20,1,64'h80000048,0,3,0);
    await_output;check(idle&&service_idle,"fulltag reuse failed after drain");

    reset_phase;rsp_enable=0;allocate(1,0,1,3,0);bind_pair(1,0,1,64'h80000050,0,3,0);
    repeat(4)tick;flush=1;tick;flush=0;check(reuse[0]&&!idle,"flush lost accepted token");
    rsp_enable=3;await_response(slots[0],1);repeat(5)tick;check(idle&&outputs==0,"flushed translation published");
    $display("[PASS] tb_r64_bind_translation_service FLOW=%0d STORE_HOT=%0d checks=%0d realBare_Sv39_PMP_fallback_kill_flush_fulltag",
      FLOW,STORE_HOT,checks);$finish;
  end
  initial begin #50000;$fatal(1,"bind service timeout");end
endmodule
