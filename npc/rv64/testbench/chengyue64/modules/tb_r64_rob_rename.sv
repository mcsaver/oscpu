`timescale 1ns/1ps
module tb_r64_rob_rename;
  localparam T=9, P=6, M=32;
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
  R64Rob #(.META_W(M)) rob (.store_done_valid_i(1'b0),.store_done_ready_o(),.store_done_tag_i(9'b0),.store_done_error_i(1'b0),.store_done_tval_i(64'b0),
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
  task tick; begin @(posedge clk); #1; end endtask
  task quiet; begin req=0;wv=0;wx=0;kill=0; end endtask
  task check; input condition; input [511:0] message;
    begin if(condition!==1'b1) $fatal(1,"%0s",message); end
  endtask
  task birth;
    input integer number;
    input [4:0] a0,a1;
    input [1:0] floating;
    begin
      req=3;rd_write=3;rd_fp=floating;rd_arch={a1,a0};
      ameta={32'(number+1),32'(number)};
      #1;check(alloc==3,"dual birth lacked credit");
      tags[number]=atag[0+:T]; tags[number+1]=atag[T+:T];
      news[number]=pn[0+:P]; news[number+1]=pn[P+:P];
      tick();quiet();
    end
  endtask
  task finish_pair;
    input integer number;
    begin
      wv=3;wt={tags[number+1],tags[number]};
      wp={news[number+1],news[number]};
      wd={64'(number+101),64'(number+100)};
      #1;check(wa==3,"dual exact completion rejected");
      tick();quiet();
    end
  endtask
  initial begin
    tick();rst=0;#1;
    // Same-packet WAW and RAW must carry the first new physical name.
    req=3;rd_write=3;rd_arch={5'd5,5'd5};src_used=6'b001000;
    src_arch[15+:5]=5'd5;
    #1;
    check(pn[0+:P]==32 && pn[P+:P]==33,"initial free register allocation");
    check(po[0+:P]==5 && po[P+:P]==32,"same-packet WAW history");
    check(sp[3*P+:P]==32 && !sr[3],"same-packet RAW dependency");
    tags[0]=atag[0+:T];tags[1]=atag[T+:T];news[0]=pn[0+:P];news[1]=pn[P+:P];
    ameta={32'd1,32'd0};tick();quiet();
    wv=1;wt[0+:T]=tags[1];wp[0+:P]=news[1];wd[63:0]=101;
    #1;check(wa==1,"out-of-order completion");
    tick();quiet();check(cv==0,"younger completion retired early");
    wv=3;wt={tags[0],tags[0]};wp={news[0],news[0]};wd={64'd999,64'd100};
    #1;check(wa==1,"duplicate completion must accept only lane0");
    tick();quiet();cr=3;#1;
    check(cv==3 && cd=={64'd101,64'd100},"ordered dual retirement result");
    tick();cr=0;#1;check(count==0,"ROB did not drain");
    src_used=1;src_arch=5;#1;check(sp[0+:P]==33&&sr[0],"committed WAW map/value readiness");

    // Both namespaces are restored by reverse walk; killed WB is suppressed
    // while an older completion on the same kill edge remains accepted.
    birth(2,6,0,2'b10);
    recovery_preview=1;recovery_tag=tags[2];
    birth(4,6,0,2'b10);recovery_preview=0;
    kill=1;kill_tag=tags[2];
    wv=3;wt={tags[5],tags[2]};wp={news[5],news[2]};wfp=2'b10;
    #1;check(km==32'h38,"younger slot kill mask");
    check(wa==1,"kill and WB exact older/younger arbitration");
    tick();quiet();wfp=0;#1;
    check(rec && uv==3,"rollback did not start two-wide");
    check(ua=={5'd6,5'd0} && ufp==1,"undo must run youngest first");
    tick();check(rec && uv==1,"odd rollback tail");
    tick();check(!rec && count==1,"rollback kept wrong prefix");
    src_arch=6;src_fp=0;#1;
    check(sp[0+:P]==news[2]&&sr[0],"GPR map not restored to surviving producer");
    src_arch=0;src_fp=1;#1;check(sp[0+:P]==0,"FPR f0 rollback lost architectural f0");
    cr=1;#1;check(cv[0],"kill-edge older completion was lost");
    tick();cr=0;

    // Committed map is the only full-flush restoration source.
    birth(6,5,9,0);
    flush=1;tick();flush=0;quiet();
    src_arch=5;src_fp=0;src_used=1;#1;
    check(sp[0+:P]==33 && sr[0],"full flush did not restore committed map");
    check(count==0&&!rec,"full flush ROB state");
    reuse_block=1;req=1;rd_write=0;#1;
    for(i=0;i<20;i=i+1) begin check(alloc==0,"orphan slot was reused");tick();end
    reuse_block=0;#1;check(alloc[0],"released orphan slot did not make progress");
    check(atag[0+:T]!=tags[0],"slot incarnation did not advance");
    tags[8]=atag[0+:T];tick();quiet();
    wv=1;wt[0+:T]=tags[0];#1;check(wa==0,"stale pre-flush completion accepted");
    tick();quiet();flush=1;tick();flush=0;

    // A second older redirect extends recovery before any allocation reuses
    // its history. All six source descriptors include FP operand three.
    birth(10,10,10,3); birth(12,10,10,3);
    recovery_preview=1;recovery_tag=tags[13];birth(14,10,10,3);
    recovery_tag=tags[10];kill=1;kill_tag=tags[13];tick();recovery_preview=0;kill_tag=tags[10];#1;
    check(rec && uv==0 && km==32'h0e,"nested redirect must pause current undo edge");
    tick();quiet();#1;check(uv==3 && count==1,"nested older redirect extent");
    tick();check(uv==3,"nested second undo pair");
    tick();check(uv==1,"nested final undo entry");
    tick();check(!rec,"nested recovery progress");
    src_used=63;src_fp=63;src_arch={6{5'd10}};#1;
    for(j=0;j<6;j=j+1)
      check(sp[j*P+:P]==news[10] && !sr[j],"FP third-source rename/undo");
    wv=1;wt[0+:T]=tags[10];#1;check(ww==1 && canonical_fp[0],"canonical FP WB destination");
    tick();quiet();#1;check(sr==63,"FP all-source wakeup");
    flush=1;tick();flush=0;quiet();#1;

    // A terminal exception retains precise cause/tval but never installs a
    // destination or allows a younger instruction to commit beside it.
    birth(16,7,8,0);
    wv=3;wt={tags[17],tags[16]};wx=1;wc={6'd0,6'd13};wval={64'd0,64'h12345678};
    #1;check(wa==3 && ww==2,"exception completion must not write PRF");
    tick();quiet();cr=3;#1;
    check(cv==1 && cx[0] && !cwr[0] && cc[5:0]==13 && ctval[63:0]==64'h12345678,
          "precise exceptional head event");
    cr=0;flush=1;tick();flush=0;quiet();#1;
    src_used=1;src_fp=0;src_arch=7;#1;
    check(sp[0+:P]==7,"exception installed architectural mapping");

    // The final ROB credits are real: no overwrite when all 32 are live.
    rd_write=0;req=3;cr=0;
    for(i=0;i<16;i=i+1) begin #1;check(alloc==3,"capacity credit missing");tick();end
    #1;check(count==32 && alloc==0,"full ROB admitted overwrite");
    flush=1;tick();flush=0;quiet();#1;

    // Steady dual allocation/completion/retirement through pointer wrap.
    req=0;rd_write=0;cr=3;commits=0;pairs=0;
    wt=0;wv=0;
    for(i=0;i<40;i=i+1) begin
      req=3;ameta={32'(2*i+1),32'(2*i)};
      #1;check(alloc==3,"steady dual allocation bubble");
      if(cf[0]) begin check(cm[0+:M]==commits,"retire order lane0");commits=commits+1;end
      if(cf[1]) begin check(cm[M+:M]==commits,"retire order lane1");commits=commits+1;pairs=pairs+1;end
      tags[0]=atag[0+:T];tags[1]=atag[T+:T];
      tick();
      wv=3;wt={tags[1],tags[0]};wd={64'(2*i+1),64'(2*i)};
    end
    req=0;
    for(j=0;j<3;j=j+1) begin
      #1;
      if(cf[0]) begin check(cm[0+:M]==commits,"drain order lane0");commits=commits+1;end
      if(cf[1]) begin check(cm[M+:M]==commits,"drain order lane1");commits=commits+1;pairs=pairs+1;end
      tick();wv=0;
    end
    check(commits==80&&pairs==40&&count==0,"steady throughput/conservation");
    $display("[R64-ROB-RENAME] RAW/WAW GPR/FPR reverse-undo full-flush exact-WB duplicate/kill stale/reuse PASS");
    $display("[R64-ROB-THROUGHPUT] allocated=80 retired=80 dual_commit_cycles=40 steady_ipc=2");
    $display("[PASS] tb_r64_rob_rename");
    $finish;
  end
endmodule
