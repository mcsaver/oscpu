`timescale 1ns/1ps
module tb_r64_fetch_translation_owners;
reg clk=0;always #5 clk=~clk;
reg rst=1,qv=0,rr=0,inv=0,qpoison=0;
wire qr,rv,mv,mrr,mo;reg mr=1,mrv=0;
reg [63:0] va=0,status=0,satp=0;
reg [1:0] access=1,priv=1;reg ad=1,pbmt_en=1;
wire [63:0] pa,expected,mask;wire [55:0] ma;
wire [1:0] pbmt;wire needs_ad,fault;wire [4:0] cause;
reg [63:0] md=0;reg mok=0;
wire qr_ref,rv_ref,mv_ref,mrr_ref,mo_ref,fault_ref,needs_ad_ref;
wire[63:0]pa_ref,expected_ref,mask_ref;wire[55:0]ma_ref;
wire[1:0]pbmt_ref,priv_ref,priv_new;wire[4:0]cause_ref;
wire[3:0]unused_protection;wire[64:0]unused_last;
always @(posedge clk)if({unused_protection,unused_last}!==69'b0)$fatal(1,"default unused metadata not zero");
R64FetchTranslation dut(
 .req_protection_i(4'b0),.rsp_protection_o(unused_protection),.rsp_last_o(unused_last),
 .clk_i(clk),.rst_i(rst),.req_poison_i(qpoison),.req_valid_i(qv),.req_ready_o(qr),
 .req_vaddr_i(va),.req_access_i(access),.req_priv_i(priv),.req_mstatus_i(status),
 .req_satp_i(satp),.req_ad_update_i(ad),.req_pbmt_enable_i(pbmt_en),.rsp_valid_o(rv),.rsp_ready_i(rr),
 .rsp_priv_o(priv_new),.rsp_paddr_o(pa),.rsp_pbmt_o(pbmt),.rsp_needs_ad_o(needs_ad),
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
integer put=0;reg [1:0] expect_priv[0:1023];
reg stalled=0;reg [74:0] saved_rsp;
wire [74:0] rsp_packet={priv_new,pa,pbmt,needs_ad,fault,cause};
always @(posedge clk) if(!rst) begin
 cycles=cycles+1;
 if(qv&&qr) accepted=accepted+1;
 if(stalled&&(!rv||rsp_packet!==saved_rsp)) $fatal(1,"translation response unstable");
 stalled=rv&&!rr;saved_rsp=rsp_packet;
 if(rv&&rr) begin
  if(returned>=accepted||returned>=put) $fatal(1,"response lacks owner");
  if(priv_new!==expect_priv[returned])$fatal(1,"captured privilege n=%0d got=%d expected=%d",returned,priv_new,expect_priv[returned]);
  if(fault!==expect_fault[returned]||
     (fault&&cause!==expect_cause[returned])||
     (!fault&&(pa!==expect_pa[returned]||needs_ad!==expect_ad[returned]||
                pbmt!==expect_pbmt[returned])))
   $fatal(1,"translation result n=%0d pa=%h fault=%d cause=%0d ad=%d pbmt=%0d expected %h %d %0d %d %0d",
     returned,pa,fault,cause,needs_ad,pbmt,expect_pa[returned],expect_fault[returned],
     expect_cause[returned],expect_ad[returned],expect_pbmt[returned]);
  $display("TRACE %0d %h %h %b %b %h %h",returned,pa,pbmt,needs_ad,fault,cause,priv_new);
  returned=returned+1;
 end
 if(mrv&&mrr) mrv<=0;
 if(delay>0) begin
  delay=delay-1;
  if(delay==0) begin mrv<=1;md<=pending_data;mok<=pending_ok;end
 end
 if(mv&&mr) begin
  if((ma!=56'h1008&&ma!=56'h2008)||delay!=0||mrv) $fatal(1,"PTE service ownership/address %h",ma);
  memops=memops+1;pending_data=ma==56'h1008 ? 64'h200000cf : 64'h40000000300000cf;pending_ok=0;delay=3;
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

task send_only(input [63:0] address,input [1:0] epbmt,input [1:0] epriv);
begin
 @(negedge clk);expect_priv[put]=epriv;add_expected(address,0,0,0,epbmt);qv=1;
 @(posedge clk);while(!qr)@(posedge clk);
 @(negedge clk);qv=0;
end endtask
integer before_ops,full_stalls;
initial begin
 repeat(3)@(negedge clk);rst=0;rr=0;
 satp=64'h8000700000000001;priv=1;access=1;va=64'h40001234;
 send_only(64'h80001234,0,1);
 satp=64'h8000900000000002;priv=1;access=0;va=64'h40002340;
 send_only(64'hc0002340,2,1);
 satp=64'h8002300000000011;priv=3;access=0;va=64'hff80000340003338;
 send_only(64'hff80000340003338,0,3);
 if(dut.reserved_q!=3||qr)$fatal(1,"three owner capacity not reached");
 // Every request has been accepted. Changing all live request fields cannot
 // reinterpret the queued lookup or active walker descriptor.
 satp=64'hffffffffffffffff;status=64'hffffffffffffffff;priv=0;access=2;va=64'hdeadbeef;pbmt_en=0;qpoison=1;
 inv=1;repeat(2)@(negedge clk);inv=0;repeat(2)@(negedge clk);inv=1;@(negedge clk);inv=0;
 full_stalls=0;
 repeat(12)begin @(negedge clk);if(qr)$fatal(1,"borrowed full capacity");full_stalls=full_stalls+1;end
 rr=1;while(returned<put)@(negedge clk);rr=0;
 if(accepted!=3||returned!=3||dut.reserved_q!=0)$fatal(1,"initial owners did not drain");
 // The second request was accepted before SFENCE but reached terminal later.
 // Its fill must remain poisoned even after unrelated context appeared.
 satp=64'h8000900000000002;priv=1;access=0;va=64'h40002340;status=0;pbmt_en=1;qpoison=0;
 before_ops=memops;expect_priv[put]=1;run(64'hc0002340,0,0,0,2);
 if(memops!=before_ops+1)$fatal(1,"queued pre-SFENCE owner refilled stale TLB");
 before_ops=memops;expect_priv[put]=1;run(64'hc0002340,0,0,0,2);
 if(memops!=before_ops)$fatal(1,"new post-SFENCE owner failed to fill");
 // Poison arriving at request acceptance survives miss discovery and W_START.
 satp=64'h8001500000000001;va=64'h40004560;qpoison=1;
 expect_priv[put]=1;run(64'h80004560,0,0,0,0);
 before_ops=memops;qpoison=0;expect_priv[put]=1;run(64'h80004560,0,0,0,0);
 if(memops!=before_ops+1)$fatal(1,"accepted poison lost before walk fill");
 va=64'hff80000040001234;expect_priv[put]=1;run(0,1,12,0,0);
 
 // An unpoisoned fill must use the walking VA/ASID, not the younger lookup.
 rr=0;satp=64'h8001900000000001;priv=1;access=0;va=64'h40006780;
 send_only(64'h80006780,0,1);
 priv=3;va=64'h0000000080007760;
 send_only(64'h0000000080007760,0,3);
 rr=1;while(returned<put)@(negedge clk);rr=0;
 priv=1;va=64'h40006780;before_ops=memops;
 expect_priv[put]=1;run(64'h80006780,0,0,0,0);
 if(memops!=before_ops)$fatal(1,"walk fill used younger lookup VPN/ASID");
 if(accepted!=11||returned!=11||memops!=6||updates!=0)$fatal(1,"capacity scenario coverage %0d %0d %0d",accepted,returned,memops);
 $display("[PASS] tb_r64_fetch_translation_owners full_credit_stalls=%0d accepted=%0d responses=%0d PTE=%0d VA_root_ASID_priv_held_SFENCE_poison=1",full_stalls,accepted,returned,memops);
 $finish;
end
endmodule
