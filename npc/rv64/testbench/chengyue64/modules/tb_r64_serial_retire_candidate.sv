`timescale 1ns/1ps
`include "R64Protocol.vh"
// Real ROB -> Control/Commit/Lease -> LSU/PhysicalMemory -> AXIWrite chain.
// Only translation and the external AXI target are modeled. Local retire is
// registered exactly as in R64Memory before releasing the older LSU owner.
module tb_r64_serial_retire_candidate;
  parameter HEAD_CLASS=1;
  parameter N1=1;
  parameter N2=1;
  parameter N3=1;
  localparam M=`R64_META_W,C=`R64_MEM_CMD_W,R=`R64_RESULT_W,I=4;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,force_recover=0,software_irq=0,allow_irq=0;
  reg serial_fire=0,serial_result_ready=0;
  reg [8:0] serial_tag=0;
  reg [`R64_SERIAL_CMD_W-1:0] serial_command=0;
  wire serial_ready,serial_result_valid,serial_idle;
  wire icache_invalidate,tlb_invalidate;
  wire [8:0] serial_result_tag;
  wire [`R64_RESULT_W-1:0] serial_result;
  reg last_trap_irq=0;
  reg [1:0] alloc=0,bind_fire=0,trace_ready=3,wb_ready=3;
  reg [2*M-1:0] alloc_meta=0;
  wire [17:0] alloc_tag;
  wire [1:0] alloc_ready,lsq_ready;
  wire [2*I-1:0] lsq_offer;
  reg [17:0] bind_tag=0;
  reg [2*I-1:0] bind_slot=0;
  reg [2*C-1:0] commands=0;
  wire [1:0] cv,cr,cx,cwr,cfp,cs,ov,wa;
  wire [17:0] ct,ot;
  wire [2*M-1:0] cm;
  wire [2*R-1:0] result;
  wire [127:0] cd,ctval;
  wire [11:0] cc;
  wire [9:0] cf,ca;
  wire [5:0] count;
  wire recover,head_exception,flush;
  wire [`R64_EFFECT_W(9)-1:0] memory_effect;
  wire [`R64_RETIRE_W(9)-1:0] retire;
  wire [1:0] fire=retire[1:0];
  wire lease_valid=memory_effect[`R64_EFFECT_MEMORY(9)];
  wire [8:0] lease_tag=memory_effect[8:0];
  wire [31:0] reuse,rob_kill;
  wire mem_irrevocable,mem_idle;
  wire sdv,sdr,sde;
  wire [8:0] sdt;
  wire [63:0] sdval;
  wire trap,trap_irq;
  wire [5:0] trap_cause;
  wire [63:0] trap_pc,trap_tval;
  reg [17:0] pair_tag;
  reg [2*I-1:0] pair_slot;
  reg [`R64_RETIRE_W(9)-1:0] local_retire=0;
  always @(posedge clk)if(rst)local_retire<=0;else local_retire<=retire;
  reg [1:0] alloc_mem=3,alloc_writes=0,forced_wb=0;
  reg [17:0] forced_tag=0;
  reg [2*R-1:0] forced_result=0;
  reg kill_valid=0,preview_valid=0,defer_forced_wb=0;
  reg [8:0] kill_tag=0;
  wire [1:0] actual_wb=forced_wb|(ov&wb_ready);
  wire [17:0] actual_wb_tag={forced_wb[1]?forced_tag[17:9]:ot[17:9],
                             forced_wb[0]?forced_tag[8:0]:ot[8:0]};
  wire [2*R-1:0] actual_wb_result={forced_wb[1]?forced_result[R+:R]:result[R+:R],
                                   forced_wb[0]?forced_result[0+:R]:result[0+:R]};
  wire rd_valid,rd_beat_ready;
  wire [63:0] rd_addr;
  wire [7:0] rd_len;
  reg rd_beat_valid=0,rd_beat_last=0;
  reg [63:0] rd_beat_data=0;
  reg [1:0] rd_beat_resp=0;
  reg read_seen=0;
  integer read_length=0;
  reg [63:0] read_base=0;
  always @(posedge clk)if(!rst)begin
    if(|(forced_wb&ov&wb_ready))$fatal(1,"WB stimulus collided with real LSU value");
    if(rd_valid)begin
      if(read_seen)$fatal(1,"duplicate read command");
      read_seen=1;read_length=int'(rd_len)+1;read_base=rd_addr;
    end
  end
  wire pair_candidate_valid;
  wire [8:0] pair_candidate_tag;
  reg [1:0] alloc_serial=0;
  reg [15:0] alloc_functions=0;
  wire resident_serial_candidate_rob;
  R64Rob #(.DUAL_RETIRE_STORE_LEASE(N3),.SERIAL_PAYLOAD(1),.HEAD_SERIAL_CACHE(HEAD_CLASS),.LOCAL_KILL_FREEZE(1),.BATCH_SUFFIX_ROLLBACK(1)) rob (
    .serial_retire_candidate_o(resident_serial_candidate_rob),
    .batch_apply_o(),.batch_mask_o(),.batch_head_o(),.batch_desc_o(),

    .pair_store_candidate_valid_o(pair_candidate_valid),.pair_store_candidate_tag_o(pair_candidate_tag),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_pending_i(1'b0),
    .recovery_preview_valid_i(preview_valid),.recovery_preview_tag_i(kill_tag),
    .kill_valid_i(kill_valid),.kill_tag_i(kill_tag),.reuse_block_i(reuse),
    .resolve_valid_i(1'b0),.resolve_tag_i(9'b0),.resolve_npc_i(64'b0),
    .alloc_valid_i(alloc),.alloc_ready_o(alloc_ready),.alloc_tag_o(alloc_tag),
    .alloc_meta_i(alloc_meta),.alloc_rd_write_i(alloc_writes),.alloc_rd_fp_i(2'b0),
    .alloc_serial_i(alloc_serial),.alloc_rd_arch_i(10'b0),.alloc_pnew_i(12'b0),.alloc_pold_i(12'b0),
    .store_done_valid_i(sdv),.store_done_ready_o(sdr),.store_done_tag_i(sdt),
    .store_done_error_i(sde),.store_done_tval_i(sdval),
    .wb_valid_i(actual_wb),.wb_tag_i(actual_wb_tag),
    .wb_data_i({actual_wb_result[R+:64],actual_wb_result[`R64_R_DATA]}),
    .wb_exception_i({actual_wb_result[R+64],actual_wb_result[64]}),
    .wb_cause_i({actual_wb_result[R+65+:6],actual_wb_result[65+:6]}),
    .wb_tval_i({actual_wb_result[R+71+:64],actual_wb_result[71+:64]}),.wb_fflags_i(10'b0),.wb_accept_o(wa),
    .commit_ready_i(cr),.commit_valid_o(cv),.commit_serial_o(cs),
    .commit_tag_o(ct),.commit_meta_o(cm),.commit_data_o(cd),.commit_exception_o(cx),
    .commit_cause_o(cc),.commit_tval_o(ctval),.commit_fflags_o(cf),
    .commit_rd_write_o(cwr),.commit_rd_fp_o(cfp),.commit_rd_arch_o(ca),
    .recover_o(recover),.count_o(count),.kill_mask_o(rob_kill),.head_exception_o(head_exception)
  );
  R64Control #(.SUCCESSOR_STORE_LEASE(N1),.ORDINARY_SUCCESSOR_STORE_LEASE(N2),.DUAL_RETIRE_STORE_LEASE(N3)) control (
    .serial_retire_candidate_i(resident_serial_candidate_rob),
    .icache_invalidate_o(icache_invalidate),.tlb_invalidate_o(tlb_invalidate),
    .pair_store_candidate_valid_i(pair_candidate_valid),.pair_store_candidate_tag_i(pair_candidate_tag),
    .clk_i(clk),.rst_i(rst),.run_i(1'b1),.irq_software_i(software_irq),.irq_timer_i(1'b0),
    .irq_external_i(1'b0),.irq_supervisor_external_i(1'b0),.wfi_wait_i(1'b0),.time_i(64'b0),
    .rob_valid_i(cv),.rob_serial_i(cs),.rob_exception_i(cx),.rob_write_i(cwr),.rob_fp_i(cfp),
    .rob_ready_o(cr),.rob_tag_i(ct),.rob_meta_i(cm),.rob_data_i(cd),.rob_tval_i(ctval),
    .rob_cause_i(cc),.rob_arch_i(ca),.rob_flags_i(cf),.rob_count_i(count),
    .head_tag_i(ct[8:0]),.head_serial_i(cs[0]),.head_exception_raw_i(head_exception),
    .recover_i(recover||force_recover),.recovery_i({`R64_RECOVERY_W(32){1'b0}}),
    .memory_effect_o(memory_effect),.serial_fire_i(serial_fire),.serial_tag_i(serial_tag),
    .serial_command_i(serial_command),.serial_ready_o(serial_ready),
    .serial_result_ready_i(serial_result_ready),.serial_result_valid_o(serial_result_valid),
    .serial_result_tag_o(serial_result_tag),.serial_result_o(serial_result),.serial_idle_o(serial_idle),
    .memory_idle_i(mem_idle),.lsu_irrevocable_i(mem_irrevocable),.full_flush_o(flush),
    .retire_o(retire),.tensor_cmd_ready_i(1'b0),.tensor_terminal_valid_i(1'b0),
    .tensor_error_i(1'b0),.tensor_terminal_tag_i(9'b0),.tensor_error_code_i(8'b0),
    .trace_ready_i(trace_ready),.trap_valid_o(trap),.trap_interrupt_o(trap_irq),
    .trap_cause_o(trap_cause),.trap_pc_o(trap_pc),.trap_tval_o(trap_tval)
  );
  wire [1:0] tv,tr,trsp,trspr,ad;
  wire [2*I-1:0] tt,trst;
  wire [127:0] va;
  wire [3:0] access_type;
  reg [1:0] translation_pending=0;
  reg [2*I-1:0] translation_token=0;
  reg [127:0] translation_address=0;
  reg fault_next=0;
  reg [7:0] old_fn=8'h23;
  reg [1:0] old_class=0;
  assign tr=~translation_pending;
  assign trsp=translation_pending;
  assign trst=translation_token;
  always @(posedge clk)begin
    if(rst)translation_pending<=0;
    else for(integer l=0;l<2;l=l+1)begin
      if(trsp[l]&&trspr[l])translation_pending[l]<=0;
      if(tv[l]&&tr[l])begin
        translation_pending[l]<=1;translation_token[l*I+:I]<=tt[l*I+:I];
        translation_address[l*64+:64]<=va[l*64+:64];
      end
    end
  end
  wire [1:0] translation_fault={
    fault_next&&translation_address[127:64]==64'h188,
    fault_next&&translation_address[63:0]==64'h188
  };
  wire wrv,wrr,wdv,wdr,wrsp,wrspready;
  wire [63:0] wraddr,wrdata;
  wire [2:0] wrsize;
  wire [7:0] wrstrb;
  wire [1:0] wrresp;
  R64LoadStore #(.ENTRIES(12),.INDEX_W(I),.AUX(2),.SRC_W(1),
                 .HEAD_AUTHORIZED_QUERY(1),.PREPARED_CANCEL(1)) memory (
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.invalidate_i(1'b0),
    .kill_mask_i(rob_kill),.cancel_candidates_i(rob_kill),.cancel_active_i(|rob_kill),
    .head_valid_i(memory_effect[`R64_EFFECT_PRESENT(9)]),.head_tag_i(lease_tag),
    .effect_allow_i(lease_valid),.trigger_enable_i(3'b0),.trigger_address_i(64'b0),
    .fp_enable_i(1'b1),.translate_active_i(1'b0),
    .store_done_valid_o(sdv),.store_done_ready_i(sdr),.store_done_tag_o(sdt),
    .store_done_error_o(sde),.store_done_tval_o(sdval),
    .commit_fire_i(local_retire[1:0]),.commit_tag_i(local_retire[19:2]),
    .reserve_want_i(alloc&alloc_mem),.reserve_fire_i(alloc&alloc_mem),.reserve_ready_o(lsq_ready),
    .reserve_slot_o(lsq_offer),.reserve_tag_i(alloc_tag),
    .reserve_func_i(alloc_functions),.reserve_amo_i(10'b0),
    .in_fire_i(bind_fire),.in_tag_i(bind_tag),.in_slot_i(bind_slot),.in_command_i(commands),
    .out_valid_o(ov),.out_ready_i(wb_ready),.out_tag_o(ot),.out_result_o(result),
    .reuse_block_o(reuse),.irrevocable_o(mem_irrevocable),.idle_o(mem_idle),
    .tr_valid_o(tv),.tr_ready_i(tr),.tr_token_o(tt),.tr_vaddr_o(va),
    .tr_access_o(access_type),.tr_ad_update_o(ad),
    .tr_rsp_valid_i(trsp),.tr_rsp_ready_o(trspr),.tr_rsp_token_i(trst),
    .tr_paddr_i(translation_address),
    .tr_class_i({(translation_address[127:64]==64'h180 ? old_class : 2'b0),
                 (translation_address[63:0]==64'h180 ? old_class : 2'b0)}),
    .tr_fault_i(translation_fault),
    .tr_needs_ad_i(2'b0),.tr_cause_i({5'd15,5'd15}),
    .aux_valid_i(2'b0),.aux_addr_i(128'b0),.aux_data_i(128'b0),.aux_expected_i(128'b0),
    .aux_op_i(4'b0),.aux_cache_i(2'b0),.aux_size_i(6'b0),.aux_strb_i(16'b0),
    .aux_rsp_ready_i(2'b11),
    .read_valid_o(rd_valid),.read_ready_i(1'b1),.read_addr_o(rd_addr),.read_len_o(rd_len),
    .beat_valid_i(rd_beat_valid),.beat_ready_o(rd_beat_ready),.beat_data_i(rd_beat_data),
    .beat_resp_i(rd_beat_resp),.beat_last_i(rd_beat_last),
    .write_valid_o(wrv),.write_ready_i(wrr),.write_addr_o(wraddr),.write_size_o(wrsize),
    .write_data_valid_o(wdv),.write_data_ready_i(wdr),.write_data_o(wrdata),.write_strb_o(wrstrb),
    .write_rsp_valid_i(wrsp),.write_rsp_ready_o(wrspready),.write_resp_i(wrresp)
  );
  wire [1:0] axi_cmd_ready,axi_data_ready,axi_rsp_valid;
  wire [3:0] axi_rsp_resp;
  assign wrr=axi_cmd_ready[0];assign wdr=axi_data_ready[0];
  assign wrsp=axi_rsp_valid[0];assign wrresp=axi_rsp_resp[1:0];
  wire awvalid,wvalid,bready,protocol_error;
  wire [63:0] awaddr,wdata;
  wire [3:0] awid;
  wire [7:0] wstrb;
  wire wlast;
  reg bvalid=0;
  reg [1:0] bresp=0;
  R64AxiWrite #(.B_BYPASS(1),.FIRST_W_CAPTURE(1)) axi (
    .clk_i(clk),.rst_i(rst),.cmd_valid_i({1'b0,wrv}),.cmd_ready_o(axi_cmd_ready),
    .cmd_addr_i({64'b0,wraddr}),.cmd_len_i(16'b0),.cmd_size_i({3'b0,wrsize}),.cmd_prot_i(6'b0),
    .data_valid_i({1'b0,wdv}),.data_ready_o(axi_data_ready),.data_i({64'b0,wrdata}),
    .strb_i({8'b0,wrstrb}),.rsp_valid_o(axi_rsp_valid),.rsp_ready_i({1'b1,wrspready}),
    .rsp_resp_o(axi_rsp_resp),.awvalid_o(awvalid),.awready_i(1'b1),.awid_o(awid),
    .awaddr_o(awaddr),.wvalid_o(wvalid),.wready_i(1'b1),.wdata_o(wdata),
    .wstrb_o(wstrb),.wlast_o(wlast),.bvalid_i(bvalid),.bready_o(bready),
    .bid_i(4'b0),.bresp_i(bresp),.protocol_error_o(protocol_error)
  );
  integer cycles=0,retired=0,terminals=0,bcount=0,awcount=0,wcount=0,physical=0,traps=0;
  integer checks=0,rollovers=0,old_b=-1,old_retire=-1,next_physical=-1,trap_cycle=-1;
  integer old_local_retire=-1,expected_phys=0,expected_b=0,budget;
  integer physical_by_slot[0:11];
  integer aw_before,w_before,retire_before,trap_before;
  reg measure_pair=0;
  reg [63:0] last_trap_pc,last_trap_tval;
  reg [5:0] last_trap_cause;
  always @(posedge clk)if(!rst)begin
    cycles=cycles+1;
    if(protocol_error)$fatal(1,"AXI protocol error");
    if(awvalid)begin awcount=awcount+1; if(awid!=0)$fatal(1,"unexpected AXI owner");end
    if(wvalid)begin wcount=wcount+1;if(wstrb!=8'hff||!wlast)$fatal(1,"invalid store beat");end
    if(bvalid&&bready)begin bcount=bcount+1;if(measure_pair&&old_b<0)old_b=cycles;end
    if(sdv&&sdr)terminals=terminals+1;
    if(control.successor_grant_w)rollovers=rollovers+1;
    for(integer l=0;l<2;l=l+1)begin
      if(fire[l])begin
        retired=retired+1;
        if(measure_pair&&ct[l*9+:9]==pair_tag[8:0])old_retire=cycles;
      end
      if(local_retire[l]&&local_retire[2+l*9+:9]==pair_tag[8:0])old_local_retire=cycles;
      if(memory.mv[l]&&memory.mr[l])begin
        physical=physical+1;physical_by_slot[memory.mt[l*I+:I]]=physical_by_slot[memory.mt[l*I+:I]]+1;
        if(measure_pair&&memory.mt[l*I+:I]==pair_slot[I+:I])begin
          next_physical=cycles;
          if(old_retire<0||cycles<=old_retire)$fatal(1,"younger effect before predecessor retired");
        end
      end
      if((ov[l]&&wb_ready[l])&&!wa[l])$fatal(1,"real LSU completion rejected by ROB");
    end
    if(trap)begin
      traps=traps+1;trap_cycle=cycles;last_trap_pc=trap_pc;last_trap_tval=trap_tval;last_trap_cause=trap_cause;
      last_trap_irq=trap_irq;
      if(trap_irq&&!allow_irq)$fatal(1,"unexpected IRQ");
    end
  end
  task tick;begin @(posedge clk);#1;end endtask
  task check(input condition,input [767:0] message);
    begin checks=checks+1;if(condition!==1'b1)$fatal(1,"%0s",message);end
  endtask
  function [M-1:0] md(input [63:0] pc);
    md={8'd3,4'd4,pc+64'd4,64'h23,pc};
  endfunction
  function [C-1:0] cmd(input [63:0] address,input [63:0] data);
    cmd={5'b0,(address==64'h180 ? old_fn : 8'h23),data,64'b0,address};
  endfunction
  task reset_phase;
    begin
      rst=1;alloc=0;bind_fire=0;bvalid=0;bresp=0;trace_ready=3;wb_ready=3;fault_next=0;force_recover=0;
      old_fn=8'h23;old_class=0;measure_pair=0;alloc_serial=0;alloc_functions=0;
      software_irq=0;allow_irq=0;serial_fire=0;serial_result_ready=0;serial_command=0;last_trap_irq=0;
       alloc_mem=3;alloc_writes=0;forced_wb=0;forced_tag=0;forced_result=0;
       rd_beat_valid=0;rd_beat_last=0;rd_beat_resp=0;read_seen=0;kill_valid=0;kill_tag=0;preview_valid=0;defer_forced_wb=0;
       repeat(2)tick;rst=0;tick;
      physical=0;retired=0;terminals=0;bcount=0;awcount=0;wcount=0;traps=0;
      for(integer n=0;n<12;n=n+1)physical_by_slot[n]=0;
    end
  endtask
  // All eligibility comes from this real ROB. The unchanged common candidate
  // and Commit expression are independent per-cycle equality oracles.
  integer candidate_checks=0,candidate_high=0,serial_commits=0;
  integer icache_effects=0,tlb_effects=0,stale_wb_rejected=0;
  integer success_cases=0,error_cases=0,trace_holds=0,recover_holds=0;
  integer b_cycle=-1,store_retire_cycle=-1,serial_wb_cycle=-1,serial_retire_cycle=-1;
  reg [8:0] test_serial_tag=0,test_store_tag=0;
  always @(posedge clk) if(!rst) begin
    candidate_checks+=1;
    if(resident_serial_candidate_rob !== (cv[0]&&!cx[0]&&cs[0]))
      $fatal(1,"candidate changed common ROB eligibility");
    if(control.serial_commit !== (fire[0]&&cs[0]))
      $fatal(1,"actual Serial commit changed");
    if(resident_serial_candidate_rob)candidate_high+=1;
    if(sdv&&sdr&&resident_serial_candidate_rob)$fatal(1,"store terminal authorized Serial");
    if(bvalid&&bready)b_cycle=cycles;
    if(fire[0]&&ct[8:0]==test_store_tag)store_retire_cycle=cycles;
    if(control.serial_commit)begin serial_commits+=1;serial_retire_cycle=cycles;end
    if(icache_invalidate)icache_effects+=1;
    if(tlb_invalidate)tlb_effects+=1;
    if((icache_invalidate||tlb_invalidate)&&!control.serial_commit)
      $fatal(1,"Serial effect without matching actual retirement");
  end
  function [M-1:0] serial_md(input[63:0]pc,input[7:0]kind,input[31:0]instruction);
    serial_md={kind,4'd4,pc+64'd4,32'd0,instruction,pc};
  endfunction
  task serial_after_store(input[7:0]kind,input[31:0]instruction,input[4:0]effects,
                          input restart,input integer hold_mode,input error_b);
    integer old_sc,old_ic,old_tl;
    begin
      reset_phase;
      old_sc=serial_commits;old_ic=icache_effects;old_tl=tlb_effects;
      b_cycle=-1;store_retire_cycle=-1;serial_wb_cycle=-1;serial_retire_cycle=-1;
      trace_ready=hold_mode==0?3:(hold_mode==2?2:0);
      if(hold_mode==3)trace_ready=3;
      alloc_mem=1;alloc_writes=0;alloc_serial=2;alloc_functions={8'd0,8'h23};
      alloc_meta={serial_md(64'h80000104,kind,instruction),md(64'h80000100)};
      alloc=3;#1;check(alloc_ready==3&&lsq_ready[0],"store/Serial pair lacked resources");
      test_store_tag=alloc_tag[8:0];test_serial_tag=alloc_tag[17:9];
      pair_tag=alloc_tag;pair_slot=lsq_offer;tick;alloc=0;alloc_serial=0;
      bind_tag=pair_tag;bind_slot=pair_slot;bind_fire=1;
      commands={C'(0),cmd(64'h180,64'h1122334455667788)};tick;bind_fire=0;
      budget=0;while((awcount==0||wcount==0)&&budget<100)begin tick;budget+=1;end
      check(budget<100,"store never issued real AW/W");
      // Recovery preserves an already granted effect; it cannot create a new lease.
      if(hold_mode==3)force_recover=1;
      bresp=error_b?2:0;bvalid=1;#1;
      check(bready&&sdv&&sdr&&!resident_serial_candidate_rob&&!control.serial_commit,
            "actual B/store terminal unexpectedly became Serial candidate");
      check(fire==(error_b||hold_mode!=0?0:1),"B-cycle ordinary store retirement changed");
      tick;bvalid=0;bresp=0;
      if(error_b)begin
        force_recover=0;trace_ready=3;
        budget=0;while(traps==0&&budget<40)begin tick;budget+=1;end
        repeat(3)tick;
        check(budget<40&&count==0&&retired==0&&physical==1&&awcount==1&&wcount==1,
              "store B error did not preserve precise boundary");
        check(serial_commits==old_sc&&icache_effects==old_ic&&tlb_effects==old_tl,
              "younger Serial effect escaped store error");
        check(last_trap_pc==64'h80000100&&last_trap_cause==7,"store error owner changed");
        error_cases+=1;
      end else begin
        if(hold_mode!=0)begin
          repeat(3)begin tick;check(retired==0&&!control.serial_commit&&!resident_serial_candidate_rob,
                                  "held ordinary store created Serial authorization");end
          trace_holds+=1;force_recover=0;trace_ready=3;
        end
        budget=0;while(count!=1&&budget<30)begin tick;budget+=1;end
        check(budget<30&&ct[8:0]==test_serial_tag&&!resident_serial_candidate_rob,
              "Serial successor identity or unfinished state changed");
        trace_ready=0;
        serial_tag=test_serial_tag;serial_command=0;
        serial_command[`R64_SERIAL_PC]=64'h80000104;
        serial_command[`R64_SERIAL_INST]=instruction;
        serial_command[`R64_SERIAL_KIND]=kind;
        serial_command[`R64_SERIAL_OPERAND]=64'h12345678;
        budget=0;while(!serial_ready&&budget<40)begin tick;budget+=1;end
        check(budget<40,"real Serial owner could not issue after store drain");
        serial_fire=1;tick;serial_fire=0;
        budget=0;while(!serial_result_valid&&budget<40)begin tick;budget+=1;end
        check(budget<40&&!serial_result[64]&&serial_result_tag==test_serial_tag,
              "real Serial returned fault or wrong fulltag");
        forced_wb=1;forced_tag={9'd0,test_serial_tag^9'h020};
        forced_result={R'(0),serial_result};#1;
        check(wa==0&&!resident_serial_candidate_rob,"stale generation completed Serial");
        tick;forced_wb=0;stale_wb_rejected+=1;
        forced_wb=1;forced_tag={9'd0,serial_result_tag};forced_result={R'(0),serial_result};
        serial_result_ready=1;#1;
        check(wa==1&&!resident_serial_candidate_rob,"Serial WB completion edge moved");
        serial_wb_cycle=cycles+1;tick;forced_wb=0;serial_result_ready=0;
        check(resident_serial_candidate_rob&&cv[0]&&cs[0]&&ct[8:0]==test_serial_tag,
              "completed resident Serial certificate missing");
        check(control.serial.retire_effect_q==effects,"Serial effect snapshot mismatch");
        repeat(3)begin tick;check(fire==0&&!control.serial_commit&&!icache_invalidate&&!tlb_invalidate,
                                  "Trace00 released Serial");end
        trace_ready=2;repeat(2)begin tick;check(fire==0&&!control.serial_commit,
                                              "Trace10 released Serial");end
        force_recover=1;trace_ready=3;
        repeat(2)begin tick;check(fire==0&&!control.serial_commit&&!icache_invalidate&&!tlb_invalidate,
                                  "recovery released Serial");end
        recover_holds+=1;force_recover=0;
        #1;check(fire==1&&control.serial_commit&&control.serial_commit_tag==test_serial_tag,
                 "matching retirement did not accept Serial");
        check(icache_invalidate==effects[3]&&tlb_invalidate==effects[4],
              "Serial invalidation edge changed");
        tick;
        check(flush==restart,"restart or scratch resume policy changed");
        repeat(3)tick;
        check(count==0&&serial_idle&&retired==2&&serial_commits==old_sc+1,
              "Serial lifetime duplicated/lost retirement");
        check(icache_effects==old_ic+int'(effects[3])&&tlb_effects==old_tl+int'(effects[4]),
              "Serial effect was not exactly once");
        $display("SERIAL_RESIDENT kind=%0d trace_mode=%0d B=%0d store_retire=%0d WB=%0d serial_retire=%0d restart=%0d",
          kind,hold_mode,b_cycle,store_retire_cycle,serial_wb_cycle,serial_retire_cycle,restart);
        success_cases+=1;
      end
    end
  endtask
  initial begin
    serial_after_store(`R64_K_FENCEI,32'h0000100f,5'b01000,1,0,0);
    serial_after_store(`R64_K_SFENCE,32'h12000073,5'b10000,1,1,0);
    serial_after_store(`R64_K_CSR,32'h34009073,5'b00001,1,2,0);
    serial_after_store(`R64_K_CSR,32'h340020f3,5'b00001,0,3,0);
    serial_after_store(`R64_K_MRET,32'h30200073,5'b00010,1,0,0);
    serial_after_store(`R64_K_SRET,32'h10200073,5'b00100,1,1,0);
    serial_after_store(`R64_K_FENCEI,32'h0000100f,5'b01000,1,0,1);
    check(success_cases==6&&error_cases==1&&stale_wb_rejected==6&&candidate_high>0,
          "missing real lifecycle coverage");
    $display("[PASS] tb_r64_serial_retire_candidate HEAD_CLASS=%0d checks=%0d eligibility_cycles=%0d candidate_high=%0d serial_commits=%0d icache=%0d tlb=%0d success=%0d error=%0d staleWB=%0d traceholds=%0d recoverholds=%0d",
      HEAD_CLASS,checks,candidate_checks,candidate_high,serial_commits,icache_effects,tlb_effects,
      success_cases,error_cases,stale_wb_rejected,trace_holds,recover_holds);
    $finish;
  end
  initial begin #200000;$fatal(1,"Serial resident candidate timeout");end
endmodule
