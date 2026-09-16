`timescale 1ns/1ps
module tb_r64_store_done;
  localparam T=9, P=6, M=204;
  reg clk=0; always #5 clk=~clk;
  reg rst=1, flush=0, kill=0;
  reg recovery_preview=0;reg [8:0] recovery_tag=0;
  reg [T-1:0] kill_tag=0;
  reg [31:0] reuse_block=0;
  reg [1:0] req=0, rd_write=0, rd_fp=0;
  reg [9:0] rd_arch=0;
  reg [29:0] src_arch=0;
  reg [5:0] src_fp=0, src_used=0;
  wire [1:0] rr, ar;
  wire [1:0] alloc = req & rr & ar;
  wire [2*T-1:0] atag;
  reg [2*M-1:0] ameta=0;
  wire [2*P-1:0] pn,po;
  wire [6*P-1:0] sp;
  wire [5:0] sr;
  reg [1:0] wv=0, wx=0, wfp=0;
  reg [2*T-1:0] wt=0;
  reg [127:0] wd=0,wval=0;
  reg [11:0] wc=0;
  reg [2*P-1:0] wp=0;
  wire [1:0] wa,ww,canonical_fp;
  wire [2*P-1:0] canonical_preg;
  reg [1:0] cr=0;
  wire [1:0] cv,cx,cwr,cfp,uv,uwr,ufp;
  wire [2*T-1:0] ct;
  wire [2*M-1:0] cm;
  wire [127:0] cd,ctval;
  wire [11:0] cc;
  wire [9:0] ca,ua;
  wire [2*P-1:0] cpn,cpo,upn,upo;
  wire [31:0] km;
  wire rec;
  wire [5:0] count;
  wire [4:0] head;
  wire [1:0] cf=cv&cr;
  reg [T-1:0] tags[0:31];
  reg [P-1:0] news[0:31];
  integer i,j,commits,pairs;
  reg sdv=0,sde=0;reg [8:0] sdt=0;reg [63:0] sdval=0;wire sdr;
  R64Rob #(.META_W(M)) rob (.store_done_valid_i(sdv),.store_done_ready_o(sdr),.store_done_tag_i(sdt),.store_done_error_i(sde),.store_done_tval_i(sdval),
    .clk(clk),.rst(rst),.flush_i(flush),.recovery_preview_valid_i(recovery_preview),.recovery_preview_tag_i(recovery_tag),.kill_valid_i(kill),.kill_tag_i(kill_tag),
    .resolve_valid_i(1'b0),.resolve_tag_i(9'b0),.resolve_npc_i(64'b0),.reuse_block_i(reuse_block),.alloc_valid_i(alloc),.alloc_ready_o(ar),.alloc_tag_o(atag),
    .alloc_meta_i(ameta),.alloc_rd_write_i(rd_write),.alloc_rd_fp_i(rd_fp),
    .alloc_serial_i(2'b0),.alloc_rd_arch_i(rd_arch),.alloc_pnew_i(pn),.alloc_pold_i(po),
    .wb_valid_i(wv),.wb_tag_i(wt),.wb_data_i(wd),.wb_exception_i(wx),
    .wb_cause_i(wc),.wb_tval_i(wval),.wb_fflags_i(10'b0),.wb_accept_o(wa),.wb_rd_write_o(ww),.wb_rd_fp_o(canonical_fp),.wb_preg_o(canonical_preg),
    .commit_ready_i(cr),.commit1_allow_i(1'b1),.commit_valid_o(cv),
    .commit_tag_o(ct),.commit_meta_o(cm),.commit_data_o(cd),.commit_exception_o(cx),
    .commit_cause_o(cc),.commit_tval_o(ctval),.commit_fflags_o(),
    .commit_rd_write_o(cwr),.commit_rd_fp_o(cfp),.commit_rd_arch_o(ca),
    .commit_pnew_o(cpn),.commit_pold_o(cpo),
    .undo_valid_o(uv),.undo_rd_write_o(uwr),.undo_rd_fp_o(ufp),
    .undo_rd_arch_o(ua),.undo_pnew_o(upn),.undo_pold_o(upo),
    .kill_mask_o(km),.recover_o(rec),.count_o(count),.head_slot_o(head)
  );
  R64Rename rename (
    .clk(clk),.rst(rst),.restore_i(flush),.request_valid_i(req),
    .rd_write_i(rd_write),.rd_fp_i(rd_fp),.rd_arch_i(rd_arch),
    .src_arch_i(src_arch),.src_fp_i(src_fp),.src_used_i(src_used),
    .alloc_ready_o(rr),.pnew_o(pn),.pold_o(po),.src_preg_o(sp),.src_ready_o(sr),
    .alloc_fire_i(alloc),.wb_accept_i(ww),.wb_fp_i(canonical_fp),.wb_preg_i(canonical_preg),
    .commit_fire_i(cf),.commit_rd_write_i(cwr),.commit_rd_fp_i(cfp),
    .commit_rd_arch_i(ca),.commit_pnew_i(cpn),.commit_pold_i(cpo),
    .undo_valid_i(uv),.undo_rd_write_i(uwr),.undo_rd_fp_i(ufp),
    .undo_rd_arch_i(ua),.undo_pnew_i(upn),.undo_pold_i(upo)
  );

  task tick;begin @(posedge clk);#1;end endtask
  task check;input condition;input [511:0] msg;
    begin if(condition!==1'b1)$fatal(1,"%0s",msg);end
  endtask
  task pair;input integer start;
    begin
      req=3;rd_write=0;rd_fp=0;ameta=0;
      ameta[196+:8]=3;ameta[M+196+:8]=0;
      ameta[0+:64]=64'(start*4);ameta[M+:64]=64'(start*4+4);
      #1;check(alloc==3,"store fixture allocation");
      tags[start]=atag[0+:T];tags[start+1]=atag[T+:T];tick();req=0;
    end
  endtask
  initial begin
    tick();rst=0;
    pair(0);pair(2);
    sdv=1;sdt=tags[0]^9'h020;#1;check(!sdr,"stale generation accepted");tick();
    check(cv==0,"stale store completed head");
    recovery_preview=1;recovery_tag=tags[1];
    sdt=tags[2];#1;check(!sdr,"young ordinary store accepted");tick();
    recovery_preview=0;
    sdt=tags[0];sde=0;sdval=64'h80000008;
    // The older side effect survives a simultaneous younger branch recovery.
    kill=1;kill_tag=tags[1];wv=1;wt[0+:T]=tags[1];wd=7;
    #1;check(sdr&&wa[0],"head terminal plus unrelated WB/recovery");
    tick();sdv=0;kill=0;wv=0;
    while(rec)tick();
    check(cv[0]&&!cx[0]&&cc[0+:6]==0&&cd[0+:64]==0,"success store completion lost in kill mask");
    check(ct[0+:T]==tags[0]&&ct[T+:T]==tags[1],"recovery changed retained owner");
    cr=3;tick();cr=0;check(count==0,"retained pair retirement");

    pair(4);recovery_preview=1;recovery_tag=tags[5];pair(6);recovery_preview=0;
    kill=1;kill_tag=tags[5];tick();kill=0;
    check(rec,"error completion recovery fixture");
    sdv=1;sdt=tags[4];sde=1;sdval=64'h80000ffd;
    #1;check(sdr,"error terminal not accepted");tick();sdv=0;
    check(cv[0]&&cx[0]&&cc[0+:6]==7&&ctval[0+:64]==sdval&&!cwr[0],
      "store B error lost precise cause/tval/no-destination");
    repeat(5)begin tick();check(cv[0]&&cx[0]&&ctval[0+:64]==sdval,"fault record changed under retirement backpressure");end
    // Repeat terminal cannot modify an already complete owner.
    sdv=1;sde=0;#1;check(!sdr,"duplicate terminal accepted");tick();sdv=0;
    check(cx[0],"duplicate terminal erased error");
    flush=1;tick();flush=0;
    pair(6);sdt=tags[4];sdv=1;#1;check(!sdr,"old generation survived fullflush");
    sdt=tags[6];flush=1;#1;check(!sdr,"fullflush accepted a narrow terminal");
    tick();sdv=0;flush=0;check(count==0,"fullflush left a store owner");
    $display("[PASS] tb_r64_store_done success/error stale/young/duplicate kill+WB backpressure flush");
    $finish;
  end
endmodule
