`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_pipeline;
parameter FETCH_PTR_W=2;
reg clk=0;always #5 clk=~clk;
reg rst=1,run=1,icinv=0,tlinv=0;
wire redirect;wire [63:0] target;
reg [63:0] status=0,satp=0;
reg [1:0] priv=3;wire [1:0] consume;
wire [1:0] valid,fault;
wire [127:0] pc,raw,npc,tval;
wire [7:0] len;wire [9:0] cause;
wire [63:0] protect,ca,pe,pm;wire [1:0] protectpriv;
wire cv,cr,bv,br,bl,pv,pr,po,prv,prr;
wire [55:0] paddr;wire [63:0] bd,pd;wire [1:0] bp;
wire [7:0] cl;wire [2:0] cs;
reg deny=0;
wire [7:0] denied=deny&&protect==64'h80001800 ? 8'hfc:8'b0;
R64Frontend #(.FETCH_PTR_W(FETCH_PTR_W)) dut(
 .clk_i(clk),.rst_i(rst),.run_i(run),.redirect_i(redirect),.redirect_pc_i(target),
 .priv_i(priv),.mstatus_i(status),.satp_i(satp),.pbmt_enable_i(1'b1),.icache_invalidate_i(icinv),
 .tlb_invalidate_i(tlinv),.tlb_all_vaddr_i(1'b1),.tlb_all_asid_i(1'b1),
 .tlb_vpn_i(27'b0),.tlb_asid_i(16'b0),.valid_o(valid),.consume_i(consume),
 .pc_o(pc),.raw_o(raw),.length_o(len),.predicted_npc_o(npc),.fault_o(fault),.cause_o(cause),.tval_o(tval),
 .prediction_update_i(resolve),.prediction_pc_i(resolve_pc),.prediction_conditional_i(resolve_conditional),
 .prediction_indirect_i(resolve_indirect),.prediction_taken_i(resolve_taken),.prediction_target_i(resolve_npc),
 .protect_paddr_o(protect),.protect_priv_o(protectpriv),.protect_facts_i(130'b0),.protect_fault_mask_i(denied),
 .protect_uncached_i(1'b0),.cache_cmd_valid_o(cv),.cache_cmd_ready_i(cr),
 .cache_cmd_addr_o(ca),.cache_cmd_len_o(cl),.cache_cmd_size_o(cs),
 .cache_beat_valid_i(bv),.cache_beat_ready_o(br),.cache_beat_data_i(bd),
 .cache_beat_resp_i(bp),.cache_beat_last_i(bl),.pte_valid_o(pv),.pte_ready_i(pr),
 .pte_compare_or_o(po),.pte_addr_o(paddr),.pte_expected_o(pe),.pte_or_mask_o(pm),
 .pte_rsp_valid_i(prv),.pte_rsp_ready_o(prr),.pte_rdata_i(pd),
 .pte_error_i(1'b0),.pte_compare_ok_i(1'b0)
);
wire [3:0] cmdready,rspvalid,rsplast;
wire [255:0] rspdata;wire [7:0] rspresp;
wire av,rr,protocol_error;
reg ar=0,rv=0,rl=0;reg [3:0] rid=0;reg [63:0] rd=0;
wire [3:0] aid;wire [63:0] aa;wire [7:0] al;
wire [2:0] az,ap;wire [1:0] ab;
assign {pr,cr}=cmdready[1:0];
assign {prv,bv}=rspvalid[1:0];assign pd=rspdata[127:64];assign bd=rspdata[63:0];
assign bp=rspresp[1:0];assign bl=rsplast[0];
R64AxiRead axi(
 .clk_i(clk),.rst_i(rst),.cmd_valid_i({2'b0,pv,cv}),.cmd_ready_o(cmdready),
 .cmd_addr_i({128'b0,8'b0,paddr,ca}),.cmd_len_i({24'b0,cl}),
 .cmd_size_i({6'b0,3'd3,cs}),.cmd_prot_i({6'b0,3'd0,3'd4}),
 .rsp_valid_o(rspvalid),.rsp_ready_i({2'b0,prr,br}),.rsp_data_o(rspdata),
 .rsp_resp_o(rspresp),.rsp_last_o(rsplast),.arvalid_o(av),.arready_i(ar),
 .arid_o(aid),.araddr_o(aa),.arlen_o(al),.arsize_o(az),.arprot_o(ap),.arburst_o(ab),
 .rvalid_i(rv),.rready_o(rr),.rid_i(rid),.rdata_i(rd),.rresp_i(2'b0),.rlast_i(rl),
 .protocol_error_o(protocol_error)
);
localparam M=`R64_META_W,R=`R64_RESULT_W;
wire [1:0] fetch_ready,commit_valid,commit_write,commit_fp,commit_exception;
wire [127:0] commit_data;
wire [2*M-1:0] commit_meta;
wire [9:0] commit_arch;
wire [11:0] commit_cause;
wire resolve,resolve_conditional,resolve_indirect,resolve_taken;
wire [63:0] resolve_pc,resolve_npc;
reg [1:0] commit_ready=3;
reg halted=0;
assign consume={1'b0,valid[0]&&fetch_ready[0]}+{1'b0,valid[1]&&fetch_ready[1]};
wire [1:0] reserve_want,reserve_fire;
R64Backend backend(.store_done_valid_i(1'b0),.store_done_ready_o(),.store_done_tag_i(9'b0),.store_done_error_i(1'b0),.store_done_tval_i(64'b0),.fetch_canonical_i(66'b0),
 .lsu_reserve_want_o(reserve_want),.lsu_reserve_fire_o(reserve_fire),
 .lsu_reserve_ready_i(2'b0),.lsu_reserve_slot_i(10'b0),
 .lsu_reserve_tag_o(),.lsu_reserve_func_o(),.lsu_reserve_amo_o(),.lsu_slot_o(),.clk(clk),.rst(rst),.flush_i(1'b0),.stop_i(!run),.serial_allow_i(1'b1),
 .reuse_block_i(32'b0),.fetch_valid_i(valid),.fetch_ready_o(fetch_ready),
 .fetch_pc_i(pc),.fetch_raw_i(raw),.fetch_pred_npc_i(npc),.fetch_length_i(len),
 .fetch_exception_i(fault),.fetch_cause_i({1'b0,cause[9:5],1'b0,cause[4:0]}),.fetch_tval_i(tval),
 .commit_ready_i(commit_ready),.commit1_allow_i(1'b1),.commit_valid_o(commit_valid),
 .commit_meta_o(commit_meta),.commit_data_o(commit_data),.commit_exception_o(commit_exception),
 .commit_cause_o(commit_cause),.commit_rd_write_o(commit_write),.commit_rd_fp_o(commit_fp),.commit_rd_arch_o(commit_arch),
 .redirect_valid_o(redirect),.redirect_pc_o(target),.resolve_valid_o(resolve),
 .resolve_pc_o(resolve_pc),.resolve_npc_o(resolve_npc),.resolve_conditional_o(resolve_conditional),
 .resolve_indirect_o(resolve_indirect),.resolve_taken_o(resolve_taken),
 .lsu_ready_i(2'b0),.fp_ready_i(1'b0),.serial_ready_i(1'b0),
 .external_valid_i(4'b0),.external_tag_i(36'b0),.external_result_i({4*R{1'b0}}));
always @(posedge clk)if(!rst&&(|reserve_want|| |reserve_fire))
 $fatal(1,"pipeline instruction-only fixture requested unsupported MEM");
reg [7:0] memory[0:8191];
reg [3:0] busy=0;
reg [63:0] bus_addr[0:3];
integer bus_beat[0:3],bus_last[0:3];
integer transactions=0,beats=0,cycles=0,committed=0,pairs=0,redirects=0,predictions=0,resolves=0;
integer branches=0,indirects=0,starved=0,workload=0,n,k,chosen,lane;
integer measure_start=0,measure_stop=0,measure_count=0,boundary_waits=0,hot_dual=0,hot_run=0,hot_longest=0;
reg bus_taken=0,random_stalls=0;
reg [31:0] random_q=32'hb86e510a;
reg [63:0] expected_pc=64'h80000000,regs[0:31];
reg [M-1:0] meta;
reg [31:0] instruction;
reg [63:0] a,b,imm,next_expected,expected_value;
reg expected_write;
function [31:0] rng(input [31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
function [63:0] read_memory(input [63:0] addr);
integer i;reg [63:0] v;
begin
 v=0;
 if(addr>=64'h80000000&&addr<64'h80002000)
 for(i=0;i<8;i=i+1)v[i*8+:8]=memory[(addr-64'h80000000+i)%8192];
 else v=64'h0000001300000013;
 read_memory=v;
end endfunction
function [31:0] addi(input integer rd,rs,im);addi={12'(im),5'(rs),3'b0,5'(rd),7'h13};endfunction
function [31:0] jal(input integer rd,offset);
reg [20:0] im;begin im=offset;jal={im[20],im[10:1],im[11],im[19:12],5'(rd),7'h6f};end endfunction
function [31:0] bne(input integer rs1,rs2,offset);
reg [12:0] im;begin im=offset;bne={im[12],im[10:5],5'(rs2),5'(rs1),3'b001,im[4:1],im[11],7'h63};end endfunction
function [31:0] jalr(input integer rd,rs1,offset);jalr={12'(offset),5'(rs1),3'b0,5'(rd),7'h67};endfunction
task put32(input integer offset,input [31:0] inst);
integer i;begin for(i=0;i<4;i=i+1)memory[offset+i]=inst[i*8+:8];end endtask
// Independent physical-byte bound for completed packet-map owners. A branch
// target packet cannot extend its source; do not use the DUT's decoded row VALID
// to decide whether the assertion about the second lane should run.
wire [5:0] align_available_w=
 ((dut.u_align.count_q!=0&&dut.u_align.own_plan_q[dut.u_align.head_q][67])?
   6'd16:{dut.u_align.count_q,4'b0})-{2'b0,dut.u_align.offset_q};
always @(posedge clk)if(!rst)begin
 cycles=cycles+1;bus_taken=rv&&rr;
 if(protocol_error||po||pv)$fatal(1,"pipeline unexpected AXI/PTW contract");
 if(av&&ar)begin
  if(busy[aid]||aid>1||az!=3||ab!=1||aa[2:0]!=0)$fatal(1,"pipeline AXI AR contract");
  busy[aid]=1;bus_addr[aid]=aa;bus_beat[aid]=0;bus_last[aid]=al;transactions=transactions+1;
 end
 if(bus_taken)begin beats=beats+1;if(rl)busy[rid]=0;else bus_beat[rid]=bus_beat[rid]+1;end
 if(redirect)redirects=redirects+1;
 if(dut.predicted_redirect_w)predictions=predictions+1;
 if(resolve)begin resolves=resolves+1;if(resolve_conditional)branches=branches+1;if(resolve_indirect)indirects=indirects+1;end
 if(dut.raw_align_v_w[0]&&align_available_w==dut.u_align.len0_w)begin
  boundary_waits=boundary_waits+1;
  if(dut.raw_align_v_w[1]!==1'b0)$fatal(1,"absent next halfword exposed lane-1 VALID");
 end
 if(valid==0)starved=starved+1;
 if(workload==3&&!random_stalls&&committed>=1029&&expected_pc>=64'h80000100&&expected_pc<64'h80000700)begin
   if(commit_valid!==3||commit_ready!==3)$fatal(1,"hot whole pipeline lost dual retirement");
   hot_dual=hot_dual+1;hot_run=hot_run+1;if(hot_run>hot_longest)hot_longest=hot_run;
 end else hot_run=0;
 if(commit_valid==3&&commit_ready==3)pairs=pairs+1;
 for(lane=0;lane<2;lane=lane+1)if(commit_valid[lane]&&commit_ready[lane])begin
  meta=commit_meta[lane*M+:M];instruction=meta[95:64];
  if(meta[`R64_M_PC]!==expected_pc)$fatal(1,"pipeline retired wrong PC got=%h expected=%h",meta[`R64_M_PC],expected_pc);
  if({32'b0,instruction}!==(read_memory(expected_pc)&64'hffffffff))$fatal(1,"pipeline raw instruction mismatch");
  a=regs[instruction[19:15]];b=regs[instruction[24:20]];
  next_expected=expected_pc+4;expected_value=0;expected_write=0;
  case(instruction[6:0])
   7'h13:begin expected_value=a+{{52{instruction[31]}},instruction[31:20]};expected_write=instruction[11:7]!=0;end
   7'h6f:begin
    imm={{43{instruction[31]}},instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0};
    next_expected=expected_pc+imm;expected_value=expected_pc+4;expected_write=instruction[11:7]!=0;
   end
   7'h67:begin next_expected=(a+{{52{instruction[31]}},instruction[31:20]})&-64'd2;
    expected_value=expected_pc+4;expected_write=instruction[11:7]!=0;end
   7'h63:begin
    imm={{51{instruction[31]}},instruction[31],instruction[7],instruction[30:25],instruction[11:8],1'b0};
    if(a!=b)next_expected=expected_pc+imm;
   end
   default:begin
    if(instruction!=0||!commit_exception[lane]||commit_cause[lane*6+:6]!=2||commit_write[lane])
       $fatal(1,"pipeline expected precise terminal illegal");
    // Synchronous STOP changes after the sampled retirement edge.
    halted=1;run<=0;
   end
  endcase
  if(!halted)begin
   if(commit_exception[lane]||commit_write[lane]!=expected_write||
      (expected_write&&(commit_fp[lane]||commit_arch[lane*5+:5]!=instruction[11:7]||
                        commit_data[lane*64+:64]!==expected_value)))
     $fatal(1,"pipeline wrong result pc=%h inst=%h got=%h expected=%h",expected_pc,instruction,commit_data[lane*64+:64],expected_value);
   if(expected_write)regs[instruction[11:7]]=expected_value;
   if(meta[`R64_M_NPC]!==next_expected)$fatal(1,"pipeline wrong actual NPC");
  end
  expected_pc=next_expected;committed=committed+1;
  if(committed==257)measure_start=cycles;
  if(committed>257&&!halted)begin measure_stop=cycles;measure_count=measure_count+1;end
 end
 if(halted)begin
  if(workload==3&&!random_stalls&&hot_longest<190)$fatal(1,"insufficient hot whole-pipeline interval");
  $display("[R64-PIPELINE] workload=%0d commits=%0d cycles=%0d hot_instructions=%0d hot_cycles=%0d CPI=%0.6f redirects=%0d predicted_redirects=%0d branches=%0d indirects=%0d pairs=%0d starved=%0d AXI=%0d",
    workload,committed,cycles,measure_count,measure_stop-measure_start,
    real'(measure_stop-measure_start)/measure_count,redirects,predictions,branches,indirects,pairs,starved,transactions);
  $display("COVERAGE boundary_waits=%0d hot_dual_cycles=%0d longest_dual_run=%0d",boundary_waits,hot_dual,hot_longest);
  $display("[PASS] tb_r64_pipeline");$finish;
 end
 if(cycles>50000)$fatal(1,"pipeline timeout committed=%0d expected=%h fv=%b pc=%h ready=%b",committed,expected_pc,valid,pc,fetch_ready);
end
always @(negedge clk)begin
 random_q=rng(random_q);ar=!random_stalls||random_q[0]||random_q[1];
 if(!rv||bus_taken)begin
  rv=0;chosen=-1;
  for(k=0;k<4;k=k+1)if(busy[(k+random_q[3:2])%4]&&chosen<0)chosen=(k+random_q[3:2])%4;
  if(chosen>=0&&(!random_stalls||random_q[4]||random_q[5]))begin
   rv=1;rid=chosen;rd=read_memory(bus_addr[chosen]+bus_beat[chosen]*8);
   rl=bus_beat[chosen]==bus_last[chosen];
  end
 end
 commit_ready=random_stalls&&random_q[7] ? 0:3;
end
initial begin
 if(!$value$plusargs("workload=%d",workload))workload=0;
 random_stalls=$test$plusargs("stalls");
 for(n=0;n<8192;n=n+4)put32(n,0);
 for(n=0;n<32;n=n+1)regs[n]=0;
 put32(0,addi(20,0,100));
 if(workload==0)begin
  for(n=0;n<16;n=n+1)put32(4+4*n,addi(n+1,0,n));
  put32(68,addi(20,20,-1));put32(72,bne(20,0,-68));
 end else if(workload==1)begin
  put32(4,addi(10,0,1));put32(8,jal(1,256-8));
  put32(12,addi(11,0,2));put32(16,jal(1,256-16));
  put32(20,addi(20,20,-1));put32(24,bne(20,0,-20));
  put32(256,addi(3,3,1));put32(260,addi(4,4,1));put32(264,jalr(0,1,0));
 end else if(workload==3)begin
  put32(0,addi(20,0,4));
  for(n=0;n<512;n=n+1)put32(4+4*n,addi(n%16+1,0,n));
  put32(2052,addi(20,20,-1));put32(2056,bne(20,0,-2052));
 end else begin
  put32(4,jal(1,256-4));put32(8,addi(20,20,-1));put32(12,bne(20,0,-8));
  put32(256,addi(8,1,0));put32(260,jal(5,512-260));
  put32(264,addi(1,8,0));put32(268,jalr(0,1,0));
  put32(512,addi(9,5,0));put32(516,jal(1,768-516));
  put32(520,addi(5,9,0));put32(524,jalr(0,5,0));
  put32(768,addi(3,3,1));put32(772,jalr(0,1,0));
 end
 repeat(3)@(negedge clk);rst=0;
end
endmodule
