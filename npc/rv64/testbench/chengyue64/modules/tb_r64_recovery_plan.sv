`timescale 1ns/1ps
module tb_r64_recovery_plan;
reg clk=0;always #5 clk=~clk;
reg rst=1,flush=0,kv=0,pv=0;
reg [8:0] kt=0,pt=0;
reg [1:0] av=0,wv=0,cr=0;
reg [17:0] wt=0;
wire [1:0] ar,cv,uv;wire [17:0] at,ct;wire [31:0] km;wire rec;wire[5:0] count;
R64Rob #(.META_W(64),.NPC_LSB(0)) dut(
.clk(clk),.rst(rst),.flush_i(flush),.kill_valid_i(kv),.kill_tag_i(kt),
.recovery_preview_valid_i(pv),.recovery_preview_tag_i(pt),.reuse_block_i(32'b0),
.resolve_valid_i(1'b0),.resolve_tag_i(9'b0),.resolve_npc_i(64'b0),
.alloc_valid_i(av),.alloc_ready_o(ar),.alloc_tag_o(at),.alloc_meta_i(128'b0),
.alloc_rd_write_i(2'b0),.alloc_rd_fp_i(2'b0),.alloc_serial_i(2'b0),.alloc_rd_arch_i(10'b0),
.alloc_pnew_i(12'b0),.alloc_pold_i(12'b0),
.store_done_valid_i(1'b0),.store_done_tag_i(9'b0),.store_done_error_i(1'b0),.store_done_tval_i(64'b0),
.wb_valid_i(wv),.wb_tag_i(wt),.wb_data_i(128'b0),.wb_exception_i(2'b0),
.wb_cause_i(12'b0),.wb_tval_i(128'b0),.wb_fflags_i(10'b0),
.short_valid_i(4'b0),.short_tag_i(36'b0),.short_preg_i(24'b0),
.commit_ready_i(cr),.commit1_allow_i(1'b1),.commit_valid_o(cv),.commit_tag_o(ct),
.undo_valid_o(uv),.kill_mask_o(km),.recover_o(rec),.count_o(count));
task tick;begin @(posedge clk);#1;end endtask
task check;input c;input[511:0] msg;begin if(c!==1'b1)$fatal(1,"%0s",msg);end endtask
task clear;begin rst=1;flush=0;pv=0;kv=0;av=0;wv=0;cr=0;tick();tick();rst=0;end endtask
task fill8;begin av=3;repeat(4)begin #1;check(ar==3,"birth credit");tick();end av=0;end endtask
integer loops,lap,pair;
initial begin
clear();fill8();
wv=3;wt={9'h021,9'h020};tick();wv=0;
pv=1;pt=9'h024;av=3;cr=3;#1;check(cv==3,"two older retirement available");tick();
pv=1;pt=9'h022;av=0;cr=0;kv=1;kt=9'h024;#1;
check(km==32'h000003e0,"same-edge births must be killed");
check(dut.plan_keep_q==3,"retained count includes two old retirement");
tick();kt=9'h022;pv=0;#1;
check(km==32'h18,"nested older redirect must kill retained younger");
check(count==3&&dut.undo_count_q==5,"first recovery count");tick();kv=0;
check(count==1&&dut.undo_count_q==7,"nested recovery extends undo");
loops=0;while(rec&&loops<16)begin tick();loops=loops+1;end
check(!rec&&loops==4,"seven owners undo in four cycles");
$display("[CASE] birth+two-retire+nested-older PASS");
clear();fill8();pv=1;pt=9'h024;tick();
kv=1;kt=9'h024;pt=9'h026;tick();kv=0;pv=0;
check(!dut.plan_valid_q,"younger preview must cancel on older redirect");
$display("[CASE] younger-preview cancelled PASS");
clear();fill8();pv=1;pt=9'h024;tick();pv=0;flush=1;tick();flush=0;
check(!dut.plan_valid_q&&count==0,"full flush cancels plan");
av=3;tick();av=0;check(at[8:0]!=9'h020,"new generation allocation advanced");
pv=1;pt=9'h020;tick();pv=0;kv=1;kt=9'h020;#1;
check(km==0&&!dut.plan_valid_q,"old generation cannot activate new owners");tick();kv=0;
check(count==2,"stale plan damaged replacement owners");
$display("[CASE] flush+slot-generation reuse PASS");
clear();
for(lap=0;lap<3;lap=lap+1)begin
 fill8();wv=3;
 for(pair=0;pair<4;pair=pair+1)begin
  wt[8:0]=9'(32+lap*8+pair*2);wt[17:9]=9'(33+lap*8+pair*2);tick();
 end
 wv=0;cr=3;repeat(4)tick();cr=0;check(count==0,"head preparation drain");
end
fill8();wv=3;wt={9'h039,9'h038};tick();wv=0;
pv=1;pt=9'h03c;av=3;cr=3;tick();pv=0;av=0;cr=0;kv=1;kt=9'h03c;#1;
check(km==32'he0000003,"wrapped younger births include new generation slots");
check(dut.plan_keep_q==3,"wrapped retained count");tick();kv=0;
$display("[CASE] head-wrap+new-generation-birth victims PASS");
$display("[PASS] tb_r64_recovery_plan");$finish;
end
endmodule
