`timescale 1ns/1ps
module tb_r64_frontend_prepared;
parameter PREPARED=1;
parameter FETCH_PTR_W=2;
reg clk=0;always #5 clk=~clk;
reg rst=1,run=1,redirect=0,icinv=0,tlinv=0;
reg [63:0] target=64'h80000000,status=0,satp=0;
reg [1:0] priv=3,consume=0;
wire [1:0] valid,fault;
wire [127:0] pc,raw,npc,tval;
wire [7:0] len;wire [9:0] cause;
wire [63:0] protect,ca,pe,pm;wire [1:0] protectpriv;
wire cv,cr,bv,br,bl,pv,pr,po,prv,prr;
wire [55:0] paddr;wire [63:0] bd,pd;wire [1:0] bp;
wire [7:0] cl;wire [2:0] cs;
reg deny=0;
wire [7:0] denied;wire uncached;wire [129:0] facts;wire unused_nc;
wire [15:0] pa=deny?16'h8001:16'h8000;
wire [895:0] plo={56'b0,784'b0,56'h80001804};
wire [895:0] phi={56'hffffffffffffff,784'b0,56'h8000180f};
wire [63:0] permissions={4'h4,56'b0,4'h8};
R64FetchProtection protect_ref(protect,protectpriv,pa,plo,phi,permissions,denied,uncached);
R64FetchProtectionPrepare prepare(protect,protectpriv,pa,plo,phi,permissions,facts,unused_nc);
R64Frontend #(.FETCH_PTR_W(FETCH_PTR_W),.PREPARED_PROTECTION(PREPARED)) dut(
 .clk_i(clk),.rst_i(rst),.run_i(run),.redirect_i(redirect),.redirect_pc_i(target),
 .priv_i(priv),.mstatus_i(status),.satp_i(satp),.pbmt_enable_i(1'b1),.icache_invalidate_i(icinv),
 .tlb_invalidate_i(tlinv),.tlb_all_vaddr_i(1'b1),.tlb_all_asid_i(1'b1),
 .tlb_vpn_i(27'b0),.tlb_asid_i(16'b0),.valid_o(valid),.consume_i(consume),
 .pc_o(pc),.raw_o(raw),.length_o(len),.predicted_npc_o(npc),.fault_o(fault),.cause_o(cause),.tval_o(tval),
 .prediction_update_i(1'b0),.prediction_pc_i(64'b0),.prediction_conditional_i(1'b0),
 .prediction_indirect_i(1'b0),.prediction_taken_i(1'b0),.prediction_target_i(64'b0),
 .protect_paddr_o(protect),.protect_priv_o(protectpriv),.protect_fault_mask_i(denied),
 .protect_uncached_i(uncached),.protect_facts_i(facts),.cache_cmd_valid_o(cv),.cache_cmd_ready_i(cr),
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
reg [7:0] memory[0:8191];
reg [3:0] busy=0;
reg [63:0] bus_addr[0:3];
integer bus_beat[0:3],bus_last[0:3];
integer transactions=0,beats=0,pte_reads=0,cycles=0,delivered=0,dual=0,redirects=0;
reg bus_taken=0,random_stalls=1,accept_enable=1;
reg [31:0] random_q=32'hb86e510a;
reg [63:0] expected_pc=64'h80000000;
integer n,j,k,chosen,phase=0,hot_cycles=0;
reg fault_seen=0;
function [31:0] rng(input [31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
function [63:0] read_memory(input [63:0] addr);
integer i;reg [63:0] v;
begin
 v=0;
 if(addr==64'h1008)v=64'h200000cf;
 else if(addr>=64'h80000000&&addr<64'h80002000)
 for(i=0;i<8;i=i+1)v[i*8+:8]=memory[(addr-64'h80000000+i)%8192];
 else v=64'h0000001300000013;
 read_memory=v;
end endfunction
function [31:0] jal(input integer offset);
reg [20:0] imm;
begin imm=offset;jal={imm[20],imm[10:1],imm[11],imm[19:12],5'd0,7'h6f};end endfunction
task put32(input integer offset,input [31:0] inst);
integer i;begin for(i=0;i<4;i=i+1)memory[offset+i]=inst[i*8+:8];end endtask
task check_instruction(input integer lane);
reg [63:0] v,physical,next_expected,bits;
reg [31:0] instruction;
integer size;
begin
 if(pc[lane*64+:64]!==expected_pc)$fatal(1,"frontend stale/reordered PC got=%h expected=%h",pc[lane*64+:64],expected_pc);
 if(phase==3&&expected_pc==64'h80001802)begin
  if(!fault[lane]||cause[lane*5+:5]!=1||tval[lane*64+:64]!=64'h80001804)
   $fatal(1,"partial sector protection lost exact fault");
  fault_seen=1;expected_pc=expected_pc+len[lane*4+:4];
 end else if(phase==5)begin
  if(!fault[lane]||cause[lane*5+:5]!=12||tval[lane*64+:64]!=expected_pc)
   $fatal(1,"noncanonical instruction page fault");
  fault_seen=1;expected_pc=expected_pc+len[lane*4+:4];
 end else begin
  if(fault[lane])$fatal(1,"unexpected fetch fault pc=%h cause=%d",expected_pc,cause[lane*5+:5]);
  physical=expected_pc[63:30]==1?expected_pc+64'h40000000:expected_pc;
  v=read_memory(physical);size=v[1:0]==3?4:2;
  bits=size==2?{48'b0,v[15:0]}:{32'b0,v[31:0]};
  if(raw[lane*64+:64]!==bits||len[lane*4+:4]!=size)
   $fatal(1,"frontend instruction mismatch pc=%h raw=%h expected=%h",expected_pc,raw[lane*64+:64],bits);
  instruction=v[31:0];next_expected=expected_pc+size;
  if(size==4&&instruction[6:0]==7'h6f)
   next_expected=expected_pc+{{43{instruction[31]}},instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0};
  if(npc[lane*64+:64]!==next_expected)
   $fatal(1,"direct prediction pc=%h next=%h expected=%h",expected_pc,npc[lane*64+:64],next_expected);
  expected_pc=next_expected;
 end
 delivered=delivered+1;
end endtask
always @(posedge clk) if(!rst)begin
 cycles=cycles+1;bus_taken=rv&&rr;
 if(protocol_error||po)$fatal(1,"frontend AXI/PTW contract");
 if(av&&ar)begin
  if(busy[aid]||aid>1||az!=3||ab!=1||aa[2:0]!=0)$fatal(1,"AXI AR contract");
  busy[aid]=1;bus_addr[aid]=aa;bus_beat[aid]=0;bus_last[aid]=al;transactions=transactions+1;
  if(aid==1)pte_reads=pte_reads+1;
 end
 if(bus_taken)begin
  beats=beats+1;
  if(rl)busy[rid]=0;
  else bus_beat[rid]=bus_beat[rid]+1;
 end
 if(!redirect)begin
  if(consume==2)dual=dual+1;
  if(consume>=1)check_instruction(0);
  if(consume==2)check_instruction(1);
  if(phase==1&&expected_pc>=64'h80000100&&expected_pc<64'h80000700)begin
   if(valid!=3||consume!=2)$fatal(1,"hot complete frontend lost two instructions/cycle");
   hot_cycles=hot_cycles+1;
  end
 end
 if(cycles>20000)$fatal(1,"frontend timeout");
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
 consume=0;
 if(accept_enable&&!fault_seen&&!redirect)begin
  if(valid[0])consume=1;
  if(valid[1])consume=2;
  if(random_stalls&&random_q[8])consume=0;
  else if(random_stalls&&random_q[9]&&consume==2)consume=1;
 end
end
task recovery(input [63:0] address);
begin
 @(negedge clk);redirect=1;target=address;consume=0;expected_pc=address;
 redirects=redirects+1;
 @(negedge clk);redirect=0;
end endtask
initial begin
 for(n=0;n<8192;n=n+4)put32(n,32'h00108093);
 put32(2044,jal(-2044));
 for(n=4096;n<4352;n=n+2)begin memory[n]=1;memory[n+1]=0;end
 put32(4102,32'h00500113);put32(4158,32'h00700193);
 memory[6144]=1;memory[6145]=0;put32(6146,32'h00600213);
 repeat(3)@(negedge clk);rst=0;
 // Warm and traverse a 2 KiB loop; JAL is predicted before decode admission.
 wait(delivered>600);@(negedge clk);random_stalls=0;
 // A warmed target can now share a consumer bundle with the loop branch.
 // Synchronize on the first sector, not an intermediate per-lane scoreboard value.
 wait(expected_pc>=64'h80000000&&expected_pc<64'h80000010);phase=1;
 wait(expected_pc>=64'h80000700);@(negedge clk);phase=2;random_stalls=1;
 if(hot_cycles<190)$fatal(1,"insufficient hot path interval %0d",hot_cycles);
 recovery(64'h80001002);
 wait(expected_pc>=64'h800010c0);
 // Repeated recovery while requests are backpressured must drain old owners.
 for(j=0;j<25;j=j+1)begin
  recovery(64'h80000000+(j*28)%1024);
  repeat(3+j%5)@(negedge clk);
 end
 phase=3;deny=1;recovery(64'h80001800);
 wait(fault_seen);@(negedge clk);accept_enable=0;run=0;
 repeat(30)@(negedge clk);
 fault_seen=0;deny=0;phase=4;priv=1;satp=64'h8000000000000001;
 tlinv=1;run=1;recovery(64'h40000000);tlinv=0;accept_enable=1;
 wait(expected_pc>=64'h40000100);
 if(pte_reads<1)$fatal(1,"Sv39 frontend never used AXI PTE owner");
 phase=5;fault_seen=0;recovery(64'h0000010040000000);
 wait(fault_seen);@(negedge clk);accept_enable=0;run=0;
 $display("[PASS] tb_r64_frontend_prepared");
 $display("COVERAGE instructions=%0d dual=%0d AXI_transactions=%0d beats=%0d hot_dual_cycles=%0d recovery=%0d PTE_reads=%0d precise_partial_PMP=1",
  delivered,dual,transactions,beats,hot_cycles,redirects,pte_reads);
 $finish;
end
endmodule
