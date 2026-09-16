`timescale 1ns/1ps
`include "R64Uop.vh"
// Real native ROB is wired back to commit READY, lane-1 permission and FLUSH.
// This catches VALID->FLUSH combinational loops rather than mocking them away.
module tb_r64_commit;
 localparam M=`R64_META_W;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;wire flush;
 reg recovery_preview=0;reg [8:0] recovery_tag=0;
 reg branch_kill=0;reg [8:0] branch_tag=0;wire [31:0] rob_kill;
 reg real_lsu=0;
 reg [1:0] av=0,awr=3,afp=0,aser=0,wv=0,wx=0;
 reg [2*M-1:0] am=0;
 reg [17:0] wt=0;wire [17:0] at;
 reg [127:0] wd=0,wtval=0;reg [11:0] wc=0;reg [9:0] wf=0;
 wire [1:0] ar,wa,cv,cr,cx,cwr,cfp;
 wire [17:0] ct;wire [2*M-1:0] cm;wire [127:0] cd,ctval;
 wire [11:0] cc;wire [9:0] cflags;wire allow1,recover;
 wire [5:0] count;
 reg [1:0] trace_ready=3;
 reg irq=0,lsu_irrevocable=0,serial_irrevocable=0,force_recover=0;
 reg [5:0] irq_cause=7;
 reg [63:0] trap_target=64'h80001000;
 wire [1:0] fire,retired;wire [127:0] npc;
 wire dirty,serial_commit,trap,interrupt,stop,redirect,effect_allow,serial_allow,trap_prepare;
 wire [4:0] flags;wire [8:0] serial_tag;
 wire [5:0] trap_cause;wire [63:0] epc,tval,redirect_target;
 reg auto_release_lsu=0,auto_release_serial=0;
 reg [8:0] external_tag=0;
 integer total=0,pairs=0,traps=0,serials=0,flushes=0,i,before_total,before_traps;
 reg [17:0] saved,previous;
 reg [63:0] last_trap_pc,last_trap_tval;reg [5:0] last_cause;reg last_interrupt;
 R64Rob rob(.store_done_valid_i(1'b0),.store_done_ready_o(),.store_done_tag_i(9'b0),.store_done_error_i(1'b0),.store_done_tval_i(64'b0),.clk(clk),.rst(rst),.flush_i(flush),.recovery_preview_valid_i(recovery_preview),.recovery_preview_tag_i(recovery_tag),.kill_valid_i(branch_kill),.kill_tag_i(branch_tag),
 .reuse_block_i(32'b0),.resolve_valid_i(1'b0),.resolve_tag_i(9'b0),.resolve_npc_i(64'b0),
 .alloc_valid_i(av),.alloc_ready_o(ar),.alloc_tag_o(at),.alloc_meta_i(am),
 .alloc_rd_write_i(awr),.alloc_rd_fp_i(afp),.alloc_serial_i(aser),.alloc_rd_arch_i({5'd2,5'd1}),
 .alloc_pnew_i({6'd34,6'd33}),.alloc_pold_i({6'd2,6'd1}),
 .wb_valid_i(real_lsu?lv:wv),.wb_tag_i(real_lsu?lt:wt),.wb_data_i(real_lsu?ldata:wd),
 .wb_exception_i(real_lsu?lexception:wx),.wb_cause_i(real_lsu?lcause:wc),.wb_tval_i(real_lsu?ltval:wtval),
 .wb_fflags_i(real_lsu?lflags:wf),.wb_accept_o(wa),
 .commit_ready_i(cr),.commit1_allow_i(allow1),.commit_valid_o(cv),.commit_tag_o(ct),.commit_meta_o(cm),
 .commit_data_o(cd),.commit_exception_o(cx),.commit_cause_o(cc),.commit_tval_o(ctval),.commit_fflags_o(cflags),
 .commit_rd_write_o(cwr),.commit_rd_fp_o(cfp),.recover_o(recover),.count_o(count),.kill_mask_o(rob_kill));
 R64Commit dut(.trap_prepare_o(trap_prepare),.clk_i(clk),.rst_i(rst),.rob_valid_i(cv),.rob_ready_o(cr),.commit1_allow_o(allow1),
 .rob_tag_i(ct),.rob_meta_i(cm),.rob_data_i(cd),.rob_exception_i(cx),.rob_cause_i(cc),.rob_tval_i(ctval),
 .rob_rd_write_i(cwr),.rob_rd_fp_i(cfp),.rob_fflags_i(cflags),.retire_ready_i(trace_ready),
 .rob_empty_i(count==0),.recover_i(recover||force_recover),
 .lsu_irrevocable_i(lsu_irrevocable||li),.serial_irrevocable_i(serial_irrevocable),
 .irq_pending_i(irq),.irq_cause_i(irq_cause),.trap_target_i(trap_target),
 .retire_fire_o(fire),.retire_npc_o(npc),.retired_count_o(retired),.fp_dirty_o(dirty),.fp_flags_o(flags),
 .serial_commit_o(serial_commit),.serial_tag_o(serial_tag),
 .trap_o(trap),.trap_interrupt_o(interrupt),.trap_cause_o(trap_cause),.trap_pc_o(epc),.trap_tval_o(tval),
 .stop_birth_o(stop),.full_flush_o(flush),.redirect_o(redirect),.redirect_target_o(redirect_target),
 .effect_allow_o(effect_allow),.serial_allow_o(serial_allow));
 // Actual LSU request/response holders retain the oldest store through
 // a younger branch's real ROB kill/undo walk. Only translation/service are
 // simple handshakes; the production authorization assertion remains enabled.
 wire [1:0] lr,lv,tv,trr,mv,mrr;
 wire [17:0] lt;wire [2*`R64_RESULT_W-1:0] lresult;
 wire [127:0] ldata,ltval,ma,md;wire [11:0] lcause;
 wire [9:0] lflags,mtoken;wire [1:0] lexception,mc;
 wire [3:0] mop;wire [5:0] msize;wire [15:0] mstrb;
 wire li,lidle;
 reg [1:0] lf=0,tr=0,trv=0,mr=0,mrv=0;
 reg [17:0] litag=0;reg [2*`R64_UOP_W-1:0] luop=0;
 reg [383:0] lop=0;reg [9:0] mrtoken=0;
 integer physical_accepts=0,lsu_completions=0,recovery_hold_cycles=0;
 reg [8:0] store_tag;
 reg [63:0] held_addr,held_data;reg [4:0] held_token;
 genvar l;
 generate for(l=0;l<2;l=l+1)begin:g_lsu_result
  assign ldata[l*64+:64]=lresult[l*`R64_RESULT_W+:64];
  assign lexception[l]=lresult[l*`R64_RESULT_W+64];
  assign lcause[l*6+:6]=lresult[l*`R64_RESULT_W+65+:6];
  assign ltval[l*64+:64]=lresult[l*`R64_RESULT_W+71+:64];
  assign lflags[l*5+:5]=lresult[l*`R64_RESULT_W+135+:5];
 end endgenerate
 // TB-only adapter keeps original commit/physical-effect stimuli. Reserve
 // the fulltag first, then bind the captured payload at the following edge.
 reg [1:0] bind_fire_q=0;reg [17:0] bind_tag_q=0;
 reg [2*`R64_UOP_W-1:0] bind_uop_q=0;reg [383:0] bind_operand_q=0;
 reg [9:0] bind_slot_q=0;wire [9:0] reserve_slot_w;
 always @(posedge clk)begin
  if(rst||flush)bind_fire_q<=0;else bind_fire_q<=lf;
  if(|lf)begin bind_tag_q<=litag;bind_uop_q<=luop;bind_operand_q<=lop;bind_slot_q<=reserve_slot_w;end
 end
 R64Lsu #(.EARLY_STORE(0)) lsu(
 .store_done_valid_o(),.store_done_ready_i(1'b1),.store_done_tag_o(),.store_done_error_o(),.store_done_tval_o(),
 .mem_fast_store_o(),.mem_store_rsp_valid_i(1'b0),.mem_store_rsp_ready_o(),.mem_store_rsp_token_i(5'b0),.mem_store_rsp_error_i(1'b0),.clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(rob_kill),
 .head_valid_i(count!=0),.head_tag_i(ct[8:0]),.effect_allow_i(effect_allow),.trigger_enable_i(3'b0),.trigger_address_i(64'b0),.fp_enable_i(1'b1),.translate_active_i(1'b0),
 .commit_fire_i(fire),.commit_tag_i(ct),.reserve_want_i(2'b11),.reserve_fire_i(lf),.reserve_ready_o(lr),.reserve_slot_o(reserve_slot_w),
 .reserve_tag_i(litag),.reserve_func_i({luop[`R64_UOP_W+196+:8],luop[196+:8]}),
 .reserve_amo_i({luop[`R64_UOP_W+155+:5],luop[155+:5]}),
 .in_fire_i(bind_fire_q),.in_ready_o(),.in_tag_i(bind_tag_q),.in_slot_i(bind_slot_q),
 .in_uop_i(bind_uop_q),.in_operand_i(bind_operand_q),
 .out_valid_o(lv),.out_ready_i({2{real_lsu}}),.out_tag_o(lt),.out_result_o(lresult),
 .reuse_block_o(),.irrevocable_o(li),.idle_o(lidle),
 .tr_valid_o(tv),.tr_ready_i(tr),.tr_vaddr_o(),.tr_access_o(),.tr_ad_update_o(),
 .tr_rsp_valid_i(trv),.tr_rsp_ready_o(trr),.tr_paddr_i({64'b0,64'h1000}),
 .tr_class_i(4'b0),.tr_fault_i(2'b0),.tr_needs_ad_i(2'b0),.tr_cause_i(10'b0),
 .tr_owner_access_o(),.tr_owner_size_o(),
 .mem_valid_o(mv),.mem_ready_i(mr),.mem_token_o(mtoken),.mem_addr_o(ma),.mem_data_o(md),
 .mem_op_o(mop),.mem_cache_o(mc),.mem_size_o(msize),.mem_strb_o(mstrb),.mem_amo_o(),
 .mem_rsp_valid_i(mrv),.mem_rsp_ready_o(mrr),.mem_rsp_token_i(mrtoken),
 .mem_rsp_data_i(128'b0),.mem_rsp_offset_i(6'b0),.mem_rsp_error_i(2'b0));
 always @(posedge clk)if(!rst)begin
   if(mv[0]&&mr[0])physical_accepts=physical_accepts+1;
   if(real_lsu&&lv[0])lsu_completions=lsu_completions+1;
 end
 always @(posedge clk)if(!rst)begin
   total=total+retired;if(fire==3)pairs=pairs+1;
   if(flush)flushes=flushes+1;
   if(serial_commit)serials=serials+1;
   if(trap)begin traps=traps+1;last_trap_pc=epc;last_trap_tval=tval;last_cause=trap_cause;last_interrupt=interrupt;end
   if(auto_release_lsu&&fire[0]&&ct[8:0]==external_tag)lsu_irrevocable=0;
   if(auto_release_serial&&serial_commit&&serial_tag==external_tag)serial_irrevocable=0;
   if(dirty&&serial_commit)$fatal(1,"CSR/serial and FP retirement overlapped");
 end
 task tick;begin @(posedge clk);#1;end endtask
 task check(input condition,input [511:0] message);begin if(condition!==1'b1)$fatal(1,"%0s",message);end endtask
 function [M-1:0] meta(input [63:0] pc,input [7:0] kind,input [63:0] raw,input [3:0] len);
   meta={kind,len,pc+{60'b0,len},raw,pc};
 endfunction
 task reset_phase;begin
   recovery_preview=0;branch_kill=0;real_lsu=0;lf=0;tr=0;trv=0;mr=0;mrv=0;
   av=0;wv=0;wx=0;wc=0;wf=0;wtval=0;wd=0;awr=3;afp=0;aser=0;
   irq=0;lsu_irrevocable=0;serial_irrevocable=0;force_recover=0;auto_release_lsu=0;auto_release_serial=0;
   trace_ready=3;rst=1;tick();rst=0;#1;
 end endtask
 task birth(input [1:0] mask);begin
   av=mask;#1;check((ar&mask)==mask,"ROB birth lost capacity");saved=at;tick();av=0;
 end endtask
 task complete(input [1:0] mask);begin
   wv=mask;wt=saved;#1;check((wa&mask)==mask,"ROB completion rejected");tick();wv=0;
 end endtask
 task expect_trap(input [63:0] pc,input [63:0] value,input [5:0] cause,input irq_expected);begin
   #1;check(trap_prepare&&!trap&&!flush&&stop&&fire==0&&!effect_allow,"trap preparation must freeze the unique event without early flush");
   tick();#1;
   check(trap&&flush&&redirect&&stop&&fire==0&&!effect_allow,"registered trap event contract");
   check(epc===pc&&tval===value&&trap_cause==cause&&interrupt==irq_expected,"trap record mismatch");
   check(redirect_target==trap_target,"trap vector target mismatch");
   check(cv==0,"ROB VALID was not frozen by registered FLUSH");
   tick();#1;check(!trap&&!flush&&count==0,"trap repeated or ROB not cleared");
 end endtask
 initial begin
   tick();rst=0;
   // Ingress, completion and retirement overlap at two instructions/cycle.
   before_total=total;
   for(i=0;i<100;i=i+1)begin
     am={meta(64'h80000004+i*8,0,64'h13,4),meta(64'h80000000+i*8,0,64'h13,4)};
     av=3;wv=i==0 ? 0:3;wt=previous;#1;
     check(ar==3,"steady ROB capacity");previous=at;tick();
   end
   av=0;wv=3;wt=previous;tick();wv=0;repeat(4)tick();
   check(total-before_total==200&&pairs==100,"commit did not sustain dual retirement");
   $display("[R64-COMMIT] normal=200 instructions / 100 dual-retire cycles PASS");
   // Independent lane backpressure remains a retirement prefix.
   reset_phase();before_total=total;trace_ready=0;
   am={meta(64'h104,0,64'h13,4),meta(64'h100,0,64'h13,4)};birth(3);complete(3);
   repeat(3)begin #1;check(fire==0&&!flush&&count==2,"retirement changed while backpressured");tick();end
   trace_ready=2;#1;check(fire==0,"lane1 retired without lane0 acceptance");tick();
   trace_ready=1;#1;check(fire==1,"lane0 did not retire under lane1 backpressure");tick();
   trace_ready=3;#1;check(fire==1,"second held instruction lost");tick();check(total-before_total==2,"held pair duplicated");
   // Lane-1 exception leaves lane0 retirement intact, then becomes a head trap.
   reset_phase();before_total=total;before_traps=traps;trace_ready=0;
   am={meta(64'h204,16,64'hffffaaaabbbb6002,2),meta(64'h200,0,64'h13,4)};
   birth(3);wx=2;wc={6'd2,6'b0};wtval={64'hdeadbeef,64'b0};wf={5'h1f,5'b0};complete(3);
   trace_ready=3;#1;check(fire==1&&!flush&&!trap&&flags==0,"lane1 exception retired or leaked flags");tick();
   #1;check(cv[0]&&cx[0]&&fire==0&&!flush&&stop&&!effect_allow,"head exception generated combinational flush");tick();
   expect_trap(64'h204,64'h6002,2,0);
   check(total-before_total==1&&traps-before_traps==1,"exception changed minstret/trap count");
   // Cause 2 reconstructs original 16/32/64 raw rather than expanded FU CMD.
   for(i=0;i<3;i=i+1)begin
     reset_phase();before_total=total;
     am={M'(0),meta(64'h300,16,64'hfedcba9887654321,i==0 ? 2:i==1 ? 4:8)};
     birth(1);wx=1;wc=2;wtval=128'hffffffffffffffff;complete(1);
     trace_ready=0;#1;check(!flush&&fire==0,"head fault flush must wait one register boundary");
     tick();expect_trap(64'h300,i==0 ? 64'h4321:i==1 ? 64'h87654321:64'hfedcba9887654321,2,0);
     check(total==before_total,"illegal instruction retired");
   end
   // Non-illegal tval is preserved; synchronous exception wins pending IRQ.
   reset_phase();am={M'(0),meta(64'h400,2,64'h13,4)};birth(1);
   wx=1;wc=13;wtval=64'hdead000000001234;complete(1);irq=1;tick();irq=0;
   expect_trap(64'h400,64'hdead000000001234,13,0);
   // Serial lane1 waits for sole-head retirement. Its effects precede flush.
   reset_phase();trace_ready=0;afp=1;aser=2;
   am={meta(64'h504,6,64'h300110f3,4),meta(64'h500,5,64'h02000053,4)};birth(3);wf=5'b00101;complete(3);
   trace_ready=3;#1;check(fire==1&&dirty&&flags==5&&!serial_commit,"CSR shared retirement with older FP");tick();
   #1;check(fire==1&&serial_commit&&!dirty&&!flush&&stop,"serial side effect not at real commit");tick();
   #1;check(flush&&!trap&&redirect_target==64'h508&&fire==0,"serial recovery not delayed to next cycle");tick();
   // FENCE, FENCE.I, SFENCE and WFI use the same explicit success boundary;
   // delayed completion keeps head effects enabled even while IRQ requests drain.
   for(i=11;i<=14;i=i+1)begin
     reset_phase();aser=1;awr=0;
     am={M'(0),meta(64'h580,i,64'h0000000f,4)};birth(1);irq=1;
     repeat(3)begin #1;check(stop&&effect_allow&&serial_allow&&fire==0&&!flush,"fence waiting for older memory deadlocked IRQ drain");tick();end
     complete(1);#1;check(serial_commit&&!flush,"fence side effect before or after real commit");tick();irq=0;
     check(flush&&!trap&&redirect_target==64'h584,"fence context recovery lifecycle");tick();
   end
   // Both xRET kinds use the captured result target, not sequential ROB NPC.
   for(i=0;i<2;i=i+1)begin
     reset_phase();aser=1;awr=0;am={M'(0),meta(64'h600,i==0 ? 9:10,64'h30200073,4)};
     birth(1);wd=64'h90000000+i*16;complete(1);#1;
     check(serial_commit&&npc[63:0]==wd[63:0]&&!flush,"xRET retired with sequential NPC");tick();
     check(flush&&redirect_target==wd[63:0]&&!trap,"xRET recovery target lost");tick();
     irq=1;tick();irq=0;expect_trap(wd[63:0],0,7,1);
   end
   // Initial IRQ EPC is RESET_PC; record survives pending deassert/cause change.
   reset_phase();irq=1;irq_cause=11;#1;check(stop&&effect_allow&&serial_allow&&!flush,"IRQ stopped drain effects");tick();
   irq=0;irq_cause=3;expect_trap(64'h80000000,0,11,1);
   // A subsequent interrupt before any handler instruction retires uses the
   // architectural trap destination, not the pre-trap last retired address.
   irq=1;irq_cause=3;tick();irq=0;expect_trap(trap_target,0,3,1);
   // An uncommitted successful store must drain despite pending IRQ.
   reset_phase();irq_cause=7;trace_ready=0;awr=0;
   am={M'(0),meta(64'h700,3,64'h00103023,4)};birth(1);complete(1);
   lsu_irrevocable=1;auto_release_lsu=1;external_tag=saved[8:0];irq=1;
   repeat(5)begin #1;check(stop&&effect_allow&&serial_allow&&!trap&&!flush,"IRQ deadlocked older memory owner");tick();end
   trace_ready=3;#1;check(fire==1,"pending IRQ blocked store retirement");tick();
   check(count==0&&!lsu_irrevocable&&!flush,"store owner not released at commit");tick();irq=0;
   expect_trap(64'h704,0,7,1);
   // Tensor success retains serial owner until commit, then context flush,
   // then IRQ. IRQ cannot slip between external terminal and retirement.
   reset_phase();trace_ready=0;aser=1;awr=0;
   am={M'(0),meta(64'h800,15,64'h0a00305b0200305b,8)};birth(1);complete(1);
   serial_irrevocable=1;auto_release_serial=1;external_tag=saved[8:0];irq=1;
   repeat(3)begin #1;check(!flush&&effect_allow,"IRQ flushed successful unretired Tensor");tick();end
   trace_ready=3;#1;check(serial_commit,"Tensor retirement stalled under IRQ");tick();
   check(flush&&!trap&&redirect_target==64'h808&&!serial_irrevocable,"Tensor context flush ordering");tick();
   check(!flush&&!trap,"IRQ overlapped serial CSR visibility cycle");tick();irq=0;
   expect_trap(64'h808,0,7,1);
   // Empty ROB alone is insufficient while an external lease or recovery lives.
   reset_phase();irq=1;lsu_irrevocable=1;
   repeat(3)begin tick();check(!flush&&effect_allow,"IRQ ignored external owner");end
   lsu_irrevocable=0;force_recover=1;
   repeat(3)begin tick();check(!flush&&stop,"IRQ ignored recovery");end
   force_recover=0;tick();irq=0;expect_trap(64'h80000000,0,7,1);
   // Regression: an older store keeps its already-present physical VALID
   // while a younger branch flushes twelve entries via the actual undo walk.
   reset_phase();before_total=total;trace_ready=0;awr=0;
   am={meta(64'h904,1,64'h63,4),meta(64'h900,3,64'h00203023,4)};birth(3);
   store_tag=saved[8:0];branch_tag=saved[17:9];
   recovery_preview=1;recovery_tag=branch_tag;
   for(i=0;i<6;i=i+1)begin
     am={meta(64'h90c+i*8,0,64'h13,4),meta(64'h908+i*8,0,64'h13,4)};birth(3);
   end
   real_lsu=1;litag={9'b0,store_tag};luop=0;
   luop[`R64_U_FUNC]=8'h23;luop[`R64_U_PC]=64'h900;luop[`R64_U_CMD]=64'h00203023;
   lop=0;lop[63:0]=64'h1000;lop[127:64]=64'h0123456789abcdef;
   lf=1;#1;check(lr[0],"real LSU admission credit");tick();lf=0;
   while(!tv[0])tick();tr=1;tick();tr=0;
   trv=1;#1;check(trr[0],"real translation owner missing");tick();trv=0;
   while(!mv[0])tick();
   held_addr=ma[63:0];held_data=md[63:0];held_token=mtoken[4:0];
   check(held_addr==64'h1000&&held_data==64'h0123456789abcdef&&mop[1:0]==1&&mstrb[7:0]==8'hff,"store physical holder payload");
   recovery_preview=0;irq=1;branch_kill=1;#1;
   check(!rob_kill[store_tag[4:0]]&&!rob_kill[branch_tag[4:0]],"partial kill included retained head/boundary");
   tick();branch_kill=0;
   repeat(2)begin
     #1;check(recover&&fire==0&&stop&&effect_allow&&serial_allow,"partial recovery revoked retained-head authorization");
     check(mv[0]&&ma[63:0]===held_addr&&md[63:0]===held_data&&mtoken[4:0]===held_token,
       "held store changed or disappeared during younger recovery");
     recovery_hold_cycles=recovery_hold_cycles+1;tick();
   end
   mr=1;#1;check(recover&&effect_allow&&mv[0],"store cannot be accepted during recovery");
   tick();mr=0;check(li,"accepted head store lost irrevocable ownership");
   mrtoken={5'b0,held_token};mrv=1;#1;check(mrr[0],"store response backpressured without reason");
   tick();mrv=0;
   while(recover)begin #1;check(fire==0&&effect_allow&&!flush,"undo walk changed commit/effect split");tick();end
   while(!cv[0])tick();
   check(li&&count==2&&physical_accepts==1&&lsu_completions==1,"store terminal/owner duplicated across recovery");
   trace_ready=3;#1;check(fire==1,"recovered head store did not retire");tick();
   check(!li,"head store retained irreversible state after commit");real_lsu=0;
   wv=1;wt={9'b0,branch_tag};#1;check(wa[0],"retained branch completion rejected");tick();wv=0;
   tick();check(count==0&&total-before_total==2,"younger killed entries retired or retained pair lost");
   tick();irq=0;expect_trap(64'h908,0,7,1);
   check(physical_accepts==1&&lsu_completions==1&&recovery_hold_cycles==2,
      "real side-effect recovery coverage");
   $display("[R64-COMMIT-RECOVERY] killed_younger=12 held_cycles=2 physical_accept=1 completion=1 retained_retire=2 IRQ_after_drain PASS");
   $display("[R64-COMMIT] total_retired=%0d traps=%0d serial=%0d registered_flush=%0d precise/IRQ-drain/xRET/FP/RAW/hold PASS",
      total,traps,serials,flushes);
   $display("[PASS] tb_r64_commit");$finish;
 end
 initial begin #1000000;$fatal(1,"commit timeout/combinational feedback");end
endmodule
