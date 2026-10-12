`timescale 1ns/1ps
`include "R64Protocol.vh"
// Real ROB -> Control/Commit/Lease -> LSU/PhysicalMemory -> AXIWrite chain.
// Only translation and the external AXI target are modeled. Local retire is
// registered exactly as in R64Memory before releasing the older LSU owner.
module tb_r64_successor_store_lease;
  parameter N1=1;
  localparam M=`R64_META_W,C=`R64_MEM_CMD_W,R=`R64_RESULT_W,I=4;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,force_recover=0;
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
  wire resident_serial_candidate_rob;
  R64Rob rob (
    .serial_retire_candidate_o(resident_serial_candidate_rob),
    .batch_apply_o(),.batch_mask_o(),.batch_head_o(),.batch_desc_o(),

    .pair_store_candidate_valid_o(),.pair_store_candidate_tag_o(),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_pending_i(1'b0),
    .recovery_preview_valid_i(1'b0),.recovery_preview_tag_i(9'b0),
    .kill_valid_i(1'b0),.kill_tag_i(9'b0),.reuse_block_i(reuse),
    .resolve_valid_i(1'b0),.resolve_tag_i(9'b0),.resolve_npc_i(64'b0),
    .alloc_valid_i(alloc),.alloc_ready_o(alloc_ready),.alloc_tag_o(alloc_tag),
    .alloc_meta_i(alloc_meta),.alloc_rd_write_i(2'b0),.alloc_rd_fp_i(2'b0),
    .alloc_serial_i(2'b0),.alloc_rd_arch_i(10'b0),.alloc_pnew_i(12'b0),.alloc_pold_i(12'b0),
    .store_done_valid_i(sdv),.store_done_ready_o(sdr),.store_done_tag_i(sdt),
    .store_done_error_i(sde),.store_done_tval_i(sdval),
    .wb_valid_i(ov&wb_ready),.wb_tag_i(ot),
    .wb_data_i({result[R+:64],result[`R64_R_DATA]}),
    .wb_exception_i({result[R+64],result[64]}),
    .wb_cause_i({result[R+65+:6],result[65+:6]}),
    .wb_tval_i({result[R+71+:64],result[71+:64]}),.wb_fflags_i(10'b0),.wb_accept_o(wa),
    .commit_ready_i(cr),.commit_valid_o(cv),.commit_serial_o(cs),
    .commit_tag_o(ct),.commit_meta_o(cm),.commit_data_o(cd),.commit_exception_o(cx),
    .commit_cause_o(cc),.commit_tval_o(ctval),.commit_fflags_o(cf),
    .commit_rd_write_o(cwr),.commit_rd_fp_o(cfp),.commit_rd_arch_o(ca),
    .recover_o(recover),.count_o(count),.kill_mask_o(rob_kill),.head_exception_o(head_exception)
  );
  R64Control #(.SUCCESSOR_STORE_LEASE(N1)) control (
    .serial_retire_candidate_i(resident_serial_candidate_rob),
    .pair_store_candidate_valid_i(1'b0),.pair_store_candidate_tag_i(9'b0),
    .clk_i(clk),.rst_i(rst),.run_i(1'b1),.irq_software_i(1'b0),.irq_timer_i(1'b0),
    .irq_external_i(1'b0),.irq_supervisor_external_i(1'b0),.wfi_wait_i(1'b0),.time_i(64'b0),
    .rob_valid_i(cv),.rob_serial_i(cs),.rob_exception_i(cx),.rob_write_i(cwr),.rob_fp_i(cfp),
    .rob_ready_o(cr),.rob_tag_i(ct),.rob_meta_i(cm),.rob_data_i(cd),.rob_tval_i(ctval),
    .rob_cause_i(cc),.rob_arch_i(ca),.rob_flags_i(cf),.rob_count_i(count),
    .head_tag_i(ct[8:0]),.head_serial_i(cs[0]),.head_exception_raw_i(head_exception),
    .recover_i(recover||force_recover),.recovery_i({`R64_RECOVERY_W(32){1'b0}}),
    .memory_effect_o(memory_effect),.serial_fire_i(1'b0),.serial_tag_i(9'b0),
    .serial_command_i({`R64_SERIAL_CMD_W{1'b0}}),.serial_result_ready_i(1'b1),
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
    .reserve_want_i(alloc),.reserve_fire_i(alloc),.reserve_ready_o(lsq_ready),
    .reserve_slot_o(lsq_offer),.reserve_tag_i(alloc_tag),
    .reserve_func_i({8'h23,old_fn}),.reserve_amo_i(10'b0),
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
    .read_ready_i(1'b1),.beat_valid_i(1'b0),.beat_data_i(64'b0),.beat_resp_i(2'b0),.beat_last_i(1'b0),
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
      if(trap_irq)$fatal(1,"unexpected IRQ");
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
      old_fn=8'h23;old_class=0;measure_pair=0;repeat(2)tick;rst=0;tick;
      physical=0;retired=0;terminals=0;bcount=0;awcount=0;wcount=0;traps=0;
      for(integer n=0;n<12;n=n+1)physical_by_slot[n]=0;
    end
  endtask
  task launch_pair(input fault);
    begin
      fault_next=fault;alloc_meta={md(64'h80000104),md(64'h80000100)};
      alloc=3;#1;check(alloc_ready==3&&lsq_ready==3,"pair birth lacked resources");
      pair_tag=alloc_tag;pair_slot=lsq_offer;tick;alloc=0;
      bind_fire=3;bind_tag=pair_tag;bind_slot=pair_slot;
      commands={cmd(64'h188,64'h2222222222222222),cmd(64'h180,64'h1111111111111111)};
      old_b=-1;old_retire=-1;next_physical=-1;old_local_retire=-1;measure_pair=1;
      tick;bind_fire=0;
      budget=0;
      while((awcount<=bcount||wcount<=bcount) && budget<100)begin tick;budget=budget+1;end
      check(budget<100,"old store missing real AW/W");
      if(!fault)begin
        budget=0;while(!(memory.lsu.prepared_valid_q&&memory.lsu.prepared_tag_q==pair_tag[17:9])&&budget<40)begin tick;budget=budget+1;end
        check(budget<40,"successor was not prepared before B");
      end
      check(physical_by_slot[pair_slot[0+:I]]==1&&physical_by_slot[pair_slot[I+:I]]==0,
            "speculative successor physical acceptance");
    end
  endtask
  task send_b(input error);
    begin
      check(awcount>bcount&&wcount>bcount,"B sent before AW/W");
      bresp=error?2:0;bvalid=1;#1;check(bready,"B missing FIFO capacity");tick;bvalid=0;bresp=0;
    end
  endtask
  task wait_next;
    begin
      budget=0;while(next_physical<0&&budget<20)begin tick;budget=budget+1;end
      check(budget<20,"successor physical request absent");
    end
  endtask
  task drain_pair;
    begin
      budget=0;while((awcount<=bcount||wcount<=bcount)&&budget<40)begin tick;budget=budget+1;end
      check(budget<40,"successor AW/W absent");send_b(0);
      budget=0;while((count!=0||!mem_idle||reuse!=0)&&budget<40)begin tick;budget=budget+1;end
      check(budget<40&&!mem_irrevocable&&!lease_valid,"pair owner did not release");
      measure_pair=0;
    end
  endtask
  task await_trap;
    begin
      budget=0;while(traps==0&&budget<40)begin tick;budget=budget+1;end
      check(budget<40,"precise trap did not progress");repeat(3)tick;
      check(count==0&&mem_idle&&reuse==0&&!lease_valid&&!mem_irrevocable,"trap did not drain owners");
    end
  endtask
  initial begin
    reset_phase;launch_pair(0);
    if($test$plusargs("bad-order-no-retire"))begin
      memory.lsu.older_q[1][0]=0;tick;
      $fatal(1,"age checker missed corrupted nonretiring live relation");
    end
    repeat(5)begin tick;check(physical==1&&retired==0&&lease_tag==pair_tag[8:0],"B delay advanced successor");end
    send_b(0);
    if($test$plusargs("bad-retire-tag"))begin
      local_retire[2+:9]=local_retire[2+:9]^9'h20;tick;
      $fatal(1,"age checker exempted a wrong-generation local retire");
    end
    check(old_b==old_retire,"successful real B not same-edge retire");wait_next;
    check(next_physical-old_b==(N1?1:2),"successor lease exposed gap mismatch");
    if(N1)check(old_local_retire==next_physical,"local old release/new physical did not share edge");
    $display("MEASURE N1=%0d real_B_to_next_physical=%0d old_retire=%0d next=%0d",N1,next_physical-old_b,old_retire,next_physical);
    drain_pair;check(retired==2&&terminals==2&&physical==2&&awcount==2&&wcount==2,"normal pair conservation");

    reset_phase;launch_pair(0);trace_ready=0;send_b(0);
    check(!lease_valid&&old_retire<0&&physical==1,"Trace hold activated successor");
    repeat(4)begin tick;check(!lease_valid&&physical==1&&retired==0&&memory.lsu.retiring_store_age_w==0,
          "Trace hold granted lease or age exemption without retirement");end
    trace_ready=1;tick;wait_next;
    check(next_physical-old_retire==(N1?1:2),"grant from empty lease missed retirement edge");trace_ready=3;drain_pair;

    reset_phase;launch_pair(0);aw_before=awcount;w_before=wcount;send_b(1);await_trap;
    check(physical==1&&awcount==aw_before&&wcount==w_before&&retired==0&&terminals==1,
          "B error authorized younger effect");
    check(last_trap_cause==7&&last_trap_tval==64'h180&&last_trap_pc==64'h80000100,
          "B error lost precise trap payload");

    // Successor translation fault is a real LSU completion held before WB.
    // Accept it at exactly the predecessor's successful real B/retire edge.
    reset_phase;wb_ready=0;launch_pair(1);
    budget=0;while(ov==0&&budget<40)begin tick;budget=budget+1;end
    check(budget<40&&result[`R64_R_EXCEPTION]&&ot[8:0]==pair_tag[17:9],"fault completion fixture");
    check(!cv[1],"successor fault already visible before WB");
    wb_ready=3;bvalid=1;#1;check(fire==1&&wa!=0,"fault WB not coincident real B retirement");
    tick;bvalid=0;check(retired==1,"old store not retired once during next fault");await_trap;
    check(physical==1&&awcount==1&&wcount==1&&terminals==1&&retired==1,
          "same-edge successor fault produced physical/AW/W");
    check(last_trap_cause==15&&last_trap_tval==64'h188&&last_trap_pc==64'h80000104,
          "successor fault lost precise trap payload");
    $display("FAULT_PROOF N1=%0d physical=1 AW=1 W=1 successor_physical=0 cause=15 tval=188",N1);

    // Retirement frozen through B cannot activate a hinted successor.
    reset_phase;launch_pair(0);force_recover=1;send_b(0);
    repeat(3)begin tick;check(retired==0&&physical==1&&!lease_valid,"recovery activated successor");end
    force_recover=0;trace_ready=0;tick;trace_ready=3;tick;wait_next;drain_pair;

    // Kind STORE also represents FP and noncached/MMIO stores. Their real
    // successful retirement releases an LSU owner under the same full tag.
    // MMIO uses the ordinary response/WB path rather than the narrow terminal.
    for(integer store_class=0;store_class<3;store_class=store_class+1)begin
      reset_phase;
      if(store_class==0)old_fn=8'h63;
      else old_class=2'(store_class);
      launch_pair(0);send_b(0);wait_next;
      check(next_physical-old_retire==(N1?1:2),"store class successor lease gap");
      if(N1)check(old_local_retire==next_physical,"store class retirement/release boundary");
      $display("STORE_CLASS N1=%0d FP=%0d class=%0d retire_to_next=%0d",
               N1,old_fn[6],old_class,next_physical-old_retire);
      drain_pair;
      check(retired==2&&physical==2&&awcount==2&&wcount==2,"store class lost external lifecycle");
    end

    // Repeated real pairs cross the finite ROB slot wrap with exact full tags.
    reset_phase;
    for(integer n=0;n<18;n=n+1)begin
      for(integer q=0;q<12;q=q+1)physical_by_slot[q]=0;
      launch_pair(0);send_b(0);wait_next;drain_pair;
    end
    check(retired==36&&physical==36&&terminals==36&&awcount==36&&wcount==36,
          "wrap lost or duplicated store lifecycle");
    check(pair_tag[8:5]!=0,"full tag generation did not wrap");
    check(N1?rollovers>20:rollovers==0,"rollover coverage");
    $display("[PASS] tb_r64_successor_store_lease N1=%0d checks=%0d rollovers=%0d real_B_Trace_fault_recovery_wrap=1",N1,checks,rollovers);
    $finish;
  end
  initial begin #200000;$fatal(1,"successor lease timeout");end
endmodule
