
`timescale 1ns/1ps
`include "R64Uop.vh"
// Two actual 20-entry LSUs. Reserve remains in program order. Only bind
// payload/fire lanes are reversed. Translation/memory models retain each
// accepted request until a real response handshake, as in the reserve fixture.
module tb_r64_direct_bind_trigger;
 localparam N=20,IW=5,U=`R64_UOP_W,R=`R64_RESULT_W;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;reg [31:0] kill=0;
 reg [2:0] trigger_enable=3;reg [63:0] trigger_address=64'h1fff;
 reg fp_enable=0,nomem=1;reg [8:0] head_tag=0;
 reg [1:0] rwant=0,rfire=0,bfire=0,out_ready=0;
 reg [17:0] rtag=0,btag=0;reg [15:0] rfunc=0;reg [9:0] ramo=0,bslot=0;
 reg [2*U-1:0] buop=0;reg [383:0] operand=0;
 wire [1:0] rready[0:1],bready[0:1],ovalid[0:1],tv[0:1],mv[0:1];
 wire [9:0] rslot[0:1],mtoken[0:1];
 wire [17:0] otag[0:1];wire [2*R-1:0] ores[0:1];
 wire [127:0] tva[0:1],ma[0:1],md[0:1];wire [3:0] mop[0:1];
 wire [1:0] trspready[0:1],mrspready[0:1],fast_store[0:1];
 wire [31:0] reuse[0:1];wire [1:0] irrevocable,idle,drained,store_done;
 reg [1:0] tqv[0:1],mqv[0:1];
 reg [127:0] tqdata[0:1],mqdata[0:1];reg [9:0] mqtoken[0:1];
 integer cycles=0,tr_count[0:1],mem_count[0:1],wb_count[0:1];
 reg [511:0] seen[0:1];reg [1:0] held[0:1];
 reg [17:0] held_tag[0:1];reg [2*R-1:0] held_result[0:1];
 reg [R-1:0] expected;
 integer waits,s0,s1,oldslot,newslot,m,l,t;
 genvar g;
 generate for(g=0;g<2;g=g+1)begin:g_dut
  wire [1:0] in_fire=g==0?bfire:{bfire[0],bfire[1]};
  wire [17:0] in_tag=g==0?btag:{btag[8:0],btag[17:9]};
  wire [9:0] in_slot=g==0?bslot:{bslot[4:0],bslot[9:5]};
  wire [2*U-1:0] in_uop=g==0?buop:{buop[0+:U],buop[U+:U]};
  wire [383:0] in_operand=g==0?operand:{operand[191:0],operand[383:192]};
  wire [1:0] trdy=(~tqv[g])|trspready[g],mrdy=(~mqv[g])|mrspready[g];
  R64Lsu #(.ENTRIES(N),.INDEX_W(IW),.PREPARED_CANCEL(1),.HEAD_AUTHORIZED_QUERY(1)) dut(
   .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
   .cancel_candidates_i(kill),.cancel_active_i(|kill),
   .trigger_enable_i(trigger_enable),.trigger_address_i(trigger_address),
   .head_valid_i(1'b1),.head_tag_i(head_tag),.effect_allow_i(1'b1),
   .fp_enable_i(fp_enable),.translate_active_i(1'b1),
   .store_done_valid_o(store_done[g]),.store_done_ready_i(1'b1),.store_done_tag_o(),.store_done_error_o(),.store_done_tval_o(),
   .mem_store_rsp_valid_i(1'b0),.mem_store_rsp_ready_o(),.mem_store_rsp_token_i(5'b0),.mem_store_rsp_error_i(1'b0),
   .mem_fast_store_o(fast_store[g]),.commit_fire_i(2'b0),.commit_tag_i(18'b0),
   .reserve_want_i(rwant),.reserve_fire_i(rfire),.reserve_ready_o(rready[g]),.reserve_slot_o(rslot[g]),
   .reserve_tag_i(rtag),.reserve_func_i(rfunc),.reserve_amo_i(ramo),
   .in_fire_i(in_fire),.in_ready_o(bready[g]),.in_slot_i(in_slot),.in_tag_i(in_tag),.in_uop_i(in_uop),.in_operand_i(in_operand),
   .out_valid_o(ovalid[g]),.out_ready_i(out_ready),.out_tag_o(otag[g]),.out_result_o(ores[g]),
   .reuse_block_o(reuse[g]),.irrevocable_o(irrevocable[g]),.idle_o(idle[g]),.drain_idle_o(drained[g]),
   .tr_valid_o(tv[g]),.tr_ready_i(trdy),.tr_vaddr_o(tva[g]),.tr_access_o(),.tr_ad_update_o(),
   .tr_rsp_valid_i(tqv[g]),.tr_rsp_ready_o(trspready[g]),.tr_paddr_i(tqdata[g]),.tr_class_i(4'b0),
   .tr_fault_i(2'b0),.tr_needs_ad_i(2'b0),.tr_cause_i(10'b0),
   .tr_request_protection_o(),.tr_owner_access_o(),.tr_owner_size_o(),
   .mem_valid_o(mv[g]),.mem_ready_i(mrdy),.mem_token_o(mtoken[g]),.mem_addr_o(ma[g]),.mem_data_o(md[g]),
   .mem_op_o(mop[g]),.mem_cache_o(),.mem_size_o(),.mem_strb_o(),.mem_amo_o(),
   .mem_rsp_valid_i(mqv[g]),.mem_rsp_ready_o(mrspready[g]),.mem_rsp_token_i(mqtoken[g]),
   .mem_rsp_data_i(mqdata[g]),.mem_rsp_error_i(2'b0),.mem_rsp_offset_i(6'b0));
  always @(posedge clk)begin
   if(rst)begin tqv[g]<=0;mqv[g]<=0;end
   else for(integer p=0;p<2;p=p+1)begin
    if(tqv[g][p]&&trspready[g][p])tqv[g][p]<=0;
    if(tv[g][p]&&trdy[p])begin tqv[g][p]<=1;tqdata[g][p*64+:64]<=tva[g][p*64+:64];end
    if(mqv[g][p]&&mrspready[g][p])mqv[g][p]<=0;
    if(mv[g][p]&&mrdy[p])begin
     mqv[g][p]<=1;mqtoken[g][p*5+:5]<=mtoken[g][p*5+:5];
     mqdata[g][p*64+:64]<=64'h12345678abcdef01;
    end
   end
  end
 end endgenerate
 function [U-1:0] packet(input [7:0] fn);
  begin packet=0;packet[196+:8]=fn;end
 endfunction
 task tick;begin @(posedge clk);#1;end endtask
 task neg;begin @(negedge clk);end endtask
 task wait_idle;
  begin waits=0;while(idle!=3&&waits<100)begin tick();waits=waits+1;end
   if(idle!=3)$fatal(1,"LSU failed to drain real owners");end
 endtask
 always @(posedge clk)if(!rst)begin
  cycles=cycles+1;
  if(rready[0]!==rready[1]||rslot[0]!==rslot[1]||bready[0]!==bready[1])
   $fatal(1,"bind permutation changed reserve identity/credit");
  if(ovalid[0]!==ovalid[1])$fatal(1,"permutation changed result cycle");
  for(m=0;m<2;m=m+1)begin
   if(nomem&&(tv[m]!=0||mv[m]!=0||store_done[m]||irrevocable[m]||fast_store[m]!=0))
    $fatal(1,"fault/cancelled owner escaped NOMEM boundary");
   for(l=0;l<2;l=l+1)begin
    if(tv[m][l]&&((!tqv[m][l])||trspready[m][l]))tr_count[m]=tr_count[m]+1;
    if(mv[m][l]&&((!mqv[m][l])||mrspready[m][l]))begin
     if(mop[m][l*2+:2]!=0||ma[m][l*64+:64]!=64'h1800)$fatal(1,"unexpected physical owner/side effect");
     mem_count[m]=mem_count[m]+1;
    end
    if(held[m][l]&&!kill[held_tag[m][l*9+:5]])begin
     if(!ovalid[m][l]||otag[m][l*9+:9]!==held_tag[m][l*9+:9]||ores[m][l*R+:R]!==held_result[m][l*R+:R])
      $fatal(1,"held completion owner changed");
    end
    held[m][l]=ovalid[m][l]&&!out_ready[l];
    held_tag[m][l*9+:9]=otag[m][l*9+:9];held_result[m][l*R+:R]=ores[m][l*R+:R];
    if(ovalid[m][l])begin
     if(otag[0][l*9+:9]!==otag[1][l*9+:9]||ores[0][l*R+:R]!==ores[1][l*R+:R])
      $fatal(1,"result owner/cause/tval differ after bind reversal");
    end
    if(ovalid[m][l]&&out_ready[l])begin
     t=otag[m][l*9+:9];
     if(seen[m][t])$fatal(1,"duplicate fulltag completion");
     case(t)
      0:expected={5'b0,64'b0,6'd2,1'b1,64'b0};
      1:expected={5'b0,64'h1fff,6'd3,1'b1,64'b0};
      // Actual LSU retains response VA in the tuple even when exception=0.
      34:expected={5'b0,64'h1800,6'b0,1'b0,64'h12345678abcdef01};
      default:$fatal(1,"killed/stale/unexpected fulltag completion %0d",t);
     endcase
     if(ores[m][l*R+:R]!==expected)$fatal(1,"incorrect fulltag result/cause/tval %0d",t);
     seen[m][t]=1;wb_count[m]=wb_count[m]+1;
    end
   end
  end
 end
 initial begin
  for(m=0;m<2;m=m+1)begin
   seen[m]=0;tr_count[m]=0;mem_count[m]=0;wb_count[m]=0;held[m]=0;
  end
  tick();neg();rst=0;
  // Program-order reserve: FP load first, integer load second.
  rwant=3;rtag={9'd1,9'd0};rfunc={8'h03,8'h43};ramo=0;#1;
  if(rready[0]!=3)$fatal(1,"initial reserve credit unavailable");
  s0=rslot[0][4:0];s1=rslot[0][9:5];rfire=3;tick();neg();rfire=0;rwant=0;
  bslot={5'(s1),5'(s0)};btag=rtag;buop={packet(8'h03),packet(8'h43)};
  operand={128'b0,64'h1fff,128'b0,64'h1fff};bfire=3;tick();neg();bfire=0;
  if(g_dut[0].dut.cause_q[s0]!=2||g_dut[0].dut.cause_q[s1]!=4||
     g_dut[1].dut.cause_q[s0]!=2||g_dut[1].dut.cause_q[s1]!=4)
   $fatal(1,"bind-local fault owner association incorrect");
  if(g_dut[0].dut.admission_check_mask_q[0]!=(20'b1<<s0)||
     g_dut[1].dut.admission_check_mask_q[1]!=(20'b1<<s0))
   $fatal(1,"trigger check lost reversed owner mask");
  tick();neg();
  if(g_dut[0].dut.cause_q[s0]!=2||g_dut[0].dut.cause_q[s1]!=3||
     g_dut[1].dut.cause_q[s0]!=2||g_dut[1].dut.cause_q[s1]!=3)
   $fatal(1,"trigger priority/cause became input-lane dependent");
  repeat(8)tick();neg();out_ready=3;wait_idle();
  if(wb_count[0]!=2||wb_count[1]!=2)$fatal(1,"paired local faults not both returned");
  // Cancel exactly while the saved admission-check mask is pending.
  neg();head_tag=2;rwant=1;rtag={9'b0,9'd2};rfunc={8'b0,8'h03};#1;
  oldslot=rslot[0][4:0];rfire=1;tick();neg();rfire=0;rwant=0;
  bslot={5'b0,5'(oldslot)};btag={9'b0,9'd2};buop={packet(0),packet(8'h03)};
  operand={320'b0,64'h1fff};bfire=1;tick();neg();bfire=0;
  if(!g_dut[0].dut.admission_check_mask_q[0][oldslot]||
     !g_dut[1].dut.admission_check_mask_q[1][oldslot])$fatal(1,"kill missed pending-check window");
  kill[2]=1;tick();neg();kill=0;
  if(g_dut[0].dut.state_q[oldslot]!=0||g_dut[1].dut.state_q[oldslot]!=0||
     g_dut[0].dut.alive_q[oldslot]||g_dut[1].dut.alive_q[oldslot])
   $fatal(1,"cancelled pending-check owner did not release");
  // Real allocator, same physical LSQ slot and same ROB slot, new fulltag.
  head_tag=34;rwant=1;rtag={9'b0,9'd34};rfunc={8'b0,8'h03};#1;
  newslot=rslot[0][4:0];if(newslot!=oldslot)$fatal(1,"test missed same-slot reuse");
  rfire=1;tick();neg();rfire=0;rwant=0;
  if(g_dut[0].dut.tag_q[newslot]!=34||g_dut[1].dut.tag_q[newslot]!=34||
     g_dut[0].dut.bound_q[newslot]||g_dut[1].dut.bound_q[newslot]||
     g_dut[0].dut.admission_check_mask_q[0][newslot]||
     g_dut[1].dut.admission_check_mask_q[1][newslot])
   $fatal(1,"new reserve inherited stale check/bound identity");
  bslot={5'b0,5'(newslot)};btag={9'b0,9'd34};buop={packet(0),packet(8'h03)};
  operand={320'b0,64'h1800};nomem=0;bfire=1;tick();neg();bfire=0;
  tick();neg();
  if(g_dut[0].dut.cause_q[newslot]!=0||g_dut[1].dut.cause_q[newslot]!=0)
   $fatal(1,"cancelled admission check corrupted new generation");
  wait_idle();repeat(5)tick();
  for(m=0;m<2;m=m+1)if(wb_count[m]!=3||!seen[m][34]||seen[m][2]||tr_count[m]!=1||mem_count[m]!=1)
   $fatal(1,"owner conservation or NOMEM leak counts");
  $display("[PASS] tb_r64_direct_bind_trigger reserve_order_unchanged=1 pair_cause=2,3 pair_tval=0,1fff pending_tag=2 reused_tag=34 lsq_slot=%0d reversed_bind=1 NOMEM_fault_cancel=PASS tr_per_model=1 mem_per_model=1 completions_per_model=3 cycles=%0d",newslot,cycles);
  $finish;
 end
 initial begin #200000;$fatal(1,"timeout");end
endmodule
