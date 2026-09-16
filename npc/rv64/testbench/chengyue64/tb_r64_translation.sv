`timescale 1ns/1ps
module tb_r64_translation;
reg clk=0;always #5 clk=~clk;
reg rst=1,qv=0,rr=0,inv=0;
wire qr,rv,mv,mrr,mo;reg mr=1,mrv=0;
reg [63:0] va=0,status=0,satp=0;
reg [1:0] access=1,priv=1;reg ad=1,pbmt_en=1;
wire [63:0] pa,expected,mask;wire [55:0] ma;
wire [1:0] pbmt;wire needs_ad,fault;wire [4:0] cause;
reg [63:0] md=0;reg mok=0;
R64Translation dut(
 .clk_i(clk),.rst_i(rst),.req_poison_i(1'b0),.req_valid_i(qv),.req_ready_o(qr),
 .req_vaddr_i(va),.req_access_i(access),.req_priv_i(priv),.req_mstatus_i(status),
 .req_satp_i(satp),.req_ad_update_i(ad),.req_pbmt_enable_i(pbmt_en),.rsp_valid_o(rv),.rsp_ready_i(rr),
 .rsp_priv_o(),.rsp_paddr_o(pa),.rsp_pbmt_o(pbmt),.rsp_needs_ad_o(needs_ad),
 .rsp_fault_o(fault),.rsp_cause_o(cause),.invalidate_i(inv),
 .invalidate_all_vaddr_i(1'b1),.invalidate_all_asid_i(1'b1),
 .invalidate_vpn_i(27'b0),.invalidate_asid_i(16'b0),
 .mem_valid_o(mv),.mem_ready_i(mr),.mem_compare_or_o(mo),.mem_addr_o(ma),
 .mem_expected_o(expected),.mem_or_mask_o(mask),.mem_rsp_valid_i(mrv),
 .mem_rsp_ready_o(mrr),.mem_rdata_i(md),.mem_error_i(1'b0),.mem_compare_ok_i(mok)
);
reg [63:0] leaf=64'h200000cf;
integer delay=0,memops=0,updates=0,accepted=0,returned=0,cycles=0;
reg [63:0] pending_data;
reg pending_ok;
reg [63:0] expect_pa[0:1023];
reg expect_fault[0:1023],expect_ad[0:1023];
reg [4:0] expect_cause[0:1023];
reg [1:0] expect_pbmt[0:1023];
integer put=0;
reg stalled=0;reg [73:0] saved_rsp;
wire [73:0] rsp_packet={pa,pbmt,needs_ad,fault,cause,1'b0};
always @(posedge clk) if(!rst) begin
 cycles=cycles+1;
 if(qv&&qr) accepted=accepted+1;
 if(stalled&&(!rv||rsp_packet!==saved_rsp)) $fatal(1,"translation response unstable");
 stalled=rv&&!rr;saved_rsp=rsp_packet;
 if(rv&&rr) begin
  if(returned>=accepted||returned>=put) $fatal(1,"response lacks owner");
  if(fault!==expect_fault[returned]||
     (fault&&cause!==expect_cause[returned])||
     (!fault&&(pa!==expect_pa[returned]||needs_ad!==expect_ad[returned]||
                pbmt!==expect_pbmt[returned])))
   $fatal(1,"translation result n=%0d pa=%h fault=%d cause=%0d ad=%d pbmt=%0d expected %h %d %0d %d %0d",
     returned,pa,fault,cause,needs_ad,pbmt,expect_pa[returned],expect_fault[returned],
     expect_cause[returned],expect_ad[returned],expect_pbmt[returned]);
  returned=returned+1;
 end
 if(mrv&&mrr) mrv<=0;
 if(delay>0) begin
  delay=delay-1;
  if(delay==0) begin mrv<=1;md<=pending_data;mok<=pending_ok;end
 end
 if(mv&&mr) begin
  if(ma!=56'h1008||delay!=0||mrv) $fatal(1,"PTE service ownership/address %h",ma);
  memops=memops+1;pending_data=leaf;pending_ok=0;delay=3;
  if(mo) begin
   updates=updates+1;
   if(leaf===expected) begin leaf=leaf|mask;pending_ok=1;end
  end
 end
 if(cycles>4000) $fatal(1,"translation test timeout");
end
task add_expected(input [63:0] address,input bad,input [4:0] ecause,input ead,input [1:0] epbmt);
begin
 expect_pa[put]=address;expect_fault[put]=bad;expect_cause[put]=ecause;
 expect_ad[put]=ead;expect_pbmt[put]=epbmt;put=put+1;
end endtask
task run(input [63:0] address,input bad,input [4:0] ecause,input ead,input [1:0] epbmt);
begin
 @(negedge clk);add_expected(address,bad,ecause,ead,epbmt);qv=1;
 @(posedge clk);while(!qr) @(posedge clk);
 @(negedge clk);qv=0;
 while(!rv) @(negedge clk);
 repeat(3) @(negedge clk);
 rr=1;@(negedge clk);rr=0;
end endtask
task invalidate;
begin @(negedge clk);inv=1;@(negedge clk);inv=0;end
endtask
task burst(input translated);
integer j,start_cycles,start_accept,start_return;
begin
 @(negedge clk);rr=1;start_cycles=cycles;start_accept=accepted;start_return=returned;
 for(j=0;j<128;j=j+1) begin
  va=translated?(64'h40002000+j*16):(64'hff80000000002000+j*16);
  add_expected(translated?(64'h80002000+j*16):va,0,0,0,0);qv=1;
  @(posedge clk);
  if(!qr) $fatal(1,"translation hot path lost II=1 cycle %0d",j);
  if(j>=2&&(!rv||fault)) $fatal(1,"translation hot response bubble");
  @(negedge clk);
 end
 qv=0;
 while(returned<put) @(negedge clk);
 rr=0;
 if(accepted-start_accept!=128||returned-start_return!=128||cycles-start_cycles!=130)
   $fatal(1,"hot path latency/throughput %0d/%0d cycles=%0d",
     accepted-start_accept,returned-start_return,cycles-start_cycles);
end endtask
integer before_ops,before_updates;
initial begin
 repeat(3) @(negedge clk);rst=0;
 burst(0);if(memops!=0)$fatal(1,"Bare touched PTW");
 satp=64'h8000700000000001;va=64'h40001234;
 run(64'h80001234,0,0,0,0);before_ops=memops;
 burst(1);if(memops!=before_ops)$fatal(1,"TLB hit burst walked");
 // Effective M privilege bypasses satp; MPRV only applies to data accesses.
 priv=3;status=0;va=64'hff80000040001234;run(va,0,0,0,0);
 status=(64'b1<<17)|(64'b1<<11);va=64'h40001234;
 run(64'h80001234,0,0,0,0);
 access=0;va=64'hff80000040001234;run(va,0,0,0,0);
 access=1;run(0,1,13,0,0);
 // Probe missing A/D is read-only; authorization forces a fresh atomic walk.
 priv=1;status=0;va=64'h40001234;invalidate;
 leaf=64'h400000002000000f;ad=0;before_updates=updates;
 run(64'h80001234,0,0,1,2);
 if(updates!=before_updates||leaf[7:6]!=0)$fatal(1,"probe mutated PTE");
 before_ops=memops;run(64'h80001234,0,0,1,2);
 if(memops!=before_ops)$fatal(1,"probe TLB hit walked");
 ad=1;run(64'h80001234,0,0,0,2);
 if(updates!=before_updates+1||leaf[7:6]!=1)$fatal(1,"missing read A update");
 access=2;run(64'h80001234,0,0,0,2);
 if(updates!=before_updates+2||leaf[7:6]!=3)$fatal(1,"missing store D update");
 pbmt_en=0;run(0,1,15,0,0);pbmt_en=1;
 // Permission changes are evaluated on hits against captured effective context.
 invalidate;leaf=64'h200000d9;access=0;priv=0;
 run(64'h80001234,0,0,0,0);
 access=1;run(0,1,13,0,0);status=64'b1<<19;run(64'h80001234,0,0,0,0);
 priv=1;run(0,1,13,0,0);status=status|(64'b1<<18);run(64'h80001234,0,0,0,0);
 access=0;run(0,1,12,0,0);access=2;run(0,1,15,0,0);
 // SFENCE while a response is outstanding poisons fill, but drains the owner.
 invalidate;leaf=64'h200000cf;access=1;priv=1;status=0;before_ops=memops;
 fork
  run(64'h80001234,0,0,0,0);
  begin wait(memops>before_ops);invalidate;end
 join
 before_ops=memops;run(64'h80001234,0,0,0,0);
 if(memops!=before_ops+1)$fatal(1,"invalidation resurrected in-flight TLB fill");
 before_ops=memops;run(64'h80001234,0,0,0,0);
 if(memops!=before_ops)$fatal(1,"subsequent valid fill missing");
 if(returned!=put||accepted!=put)$fatal(1,"undrained translation owners");
 $display("[PASS] tb_r64_translation");
 $display("COVERAGE requests=%0d PTE_ops=%0d atomic_updates=%0d Bare_II1=128 TLB_II1=128 MPRV_SUM_MXR_A_D_SFENCE=1",
  accepted,memops,updates);
 $finish;
end
endmodule
