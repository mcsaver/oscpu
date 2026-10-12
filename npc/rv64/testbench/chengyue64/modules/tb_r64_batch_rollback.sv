`timescale 1ns / 1ps
module tb_r64_batch_rollback;
  parameter BATCH=1;
  localparam T = 9, P = 6, M = 204;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0, kill = 0;
  reg recovery_preview = 0;
  reg [8:0] recovery_tag = 0;
  reg [T-1:0] kill_tag = 0;
  reg [31:0] reuse_block = 0;
  reg [1:0] req = 0, rd_write = 0, rd_fp = 0;
  reg [ 9:0] rd_arch = 0;
  reg [29:0] src_arch = 0;
  reg [5:0] src_fp = 0, src_used = 0;
  wire [1:0] rr, ar;
  wire [1:0] alloc = req & rr & ar;
  wire [2*T-1:0] atag;
  reg [2*M-1:0] ameta = 0;
  wire [2*P-1:0] pn, po;
  wire [6*P-1:0] sp;
  wire [5:0] sr;
  reg [1:0] wv = 0, wx = 0, wfp = 0;
  reg [2*T-1:0] wt = 0;
  reg [127:0] wd = 0, wval = 0;
  reg [11:0] wc = 0;
  reg [2*P-1:0] wp = 0;
  wire [1:0] wa, ww, canonical_fp;
  wire [2*P-1:0] canonical_preg;
  reg [1:0] cr = 0;
  wire [1:0] cv, cx, cwr, cfp, uv, uwr, ufp;
  wire [2*T-1:0] ct;
  wire [2*M-1:0] cm;
  wire [127:0] cd, ctval;
  wire [11:0] cc;
  wire [9:0] ca, ua;
  wire [2*P-1:0] cpn, cpo, upn, upo;
  wire [31:0] km;
  wire rec;
  wire [5:0] count;
  wire [4:0] head;
  wire [1:0] cf = cv & cr;
  reg [T-1:0] tags[0:31];
  reg [P-1:0] news[0:31];
  integer i, j, commits, pairs;
  wire apply;
  wire [31:0] bmask;
  wire [4:0] bhead;
  wire [607:0] bdesc;
  wire [63:0] greclaim,freclaim;
  reg sdvalid=0,sderror=0;
  wire sdready;
  reg [8:0] sdtag=0;
  R64Rob #(
    .BATCH_SUFFIX_ROLLBACK(BATCH),
    .META_W(M)
  ) rob (
    .serial_retire_candidate_o(),
    .batch_apply_o(apply),.batch_mask_o(bmask),.batch_head_o(bhead),.batch_desc_o(bdesc),

    .pair_store_candidate_valid_o(),.pair_store_candidate_tag_o(),
    .store_done_valid_i(sdvalid),
    .store_done_ready_o(sdready),
    .store_done_tag_i(sdtag),
    .store_done_error_i(sderror),
    .store_done_tval_i(64'b0),
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .recovery_preview_valid_i(recovery_preview),
    .recovery_preview_tag_i(recovery_tag),
    .kill_valid_i(kill),
    .kill_tag_i(kill_tag),
    .resolve_valid_i(1'b0),
    .resolve_tag_i(9'b0),
    .resolve_npc_i(64'b0),
    .reuse_block_i(reuse_block),
    .alloc_valid_i(alloc),
    .alloc_ready_o(ar),
    .alloc_tag_o(atag),
    .alloc_meta_i(ameta),
    .alloc_rd_write_i(rd_write),
    .alloc_rd_fp_i(rd_fp),
    .alloc_serial_i(2'b0),
    .alloc_rd_arch_i(rd_arch),
    .alloc_pnew_i(pn),
    .alloc_pold_i(po),
    .wb_valid_i(wv),
    .wb_tag_i(wt),
    .wb_data_i(wd),
    .wb_exception_i(wx),
    .wb_cause_i(wc),
    .wb_tval_i(wval),
    .wb_fflags_i(10'b0),
    .wb_accept_o(wa),
    .wb_rd_write_o(ww),
    .wb_rd_fp_o(canonical_fp),
    .wb_preg_o(canonical_preg),
    .commit_ready_i(cr),
    .commit_valid_o(cv),
    .commit_tag_o(ct),
    .commit_meta_o(cm),
    .commit_data_o(cd),
    .commit_exception_o(cx),
    .commit_cause_o(cc),
    .commit_tval_o(ctval),
    .commit_fflags_o(),
    .commit_rd_write_o(cwr),
    .commit_rd_fp_o(cfp),
    .commit_rd_arch_o(ca),
    .commit_pnew_o(cpn),
    .commit_pold_o(cpo),
    .undo_valid_o(uv),
    .undo_rd_write_o(uwr),
    .undo_rd_fp_o(ufp),
    .undo_rd_arch_o(ua),
    .undo_pnew_o(upn),
    .undo_pold_o(upo),
    .kill_mask_o(km),
    .recover_o(rec),
    .count_o(count),
    .head_slot_o(head)
  );
  R64Rename #(.BATCH_SUFFIX_ROLLBACK(BATCH)) rename (
    .batch_apply_i(apply),.batch_mask_i(bmask),.batch_head_i(bhead),.batch_desc_i(bdesc),
    .batch_greclaim_o(greclaim),.batch_freclaim_o(freclaim),
    .clk(clk),
    .rst(rst),
    .restore_i(flush),
    .request_valid_i(req),
    .rd_write_i(rd_write),
    .rd_fp_i(rd_fp),
    .rd_arch_i(rd_arch),
    .src_arch_i(src_arch),
    .src_fp_i(src_fp),
    .src_used_i(src_used),
    .alloc_ready_o(rr),
    .pnew_o(pn),
    .pold_o(po),
    .src_preg_o(sp),
    .alloc_fire_i(alloc),
    .commit_fire_i(cf),
    .commit_rd_write_i(cwr),
    .commit_rd_fp_i(cfp),
    .commit_rd_arch_i(ca),
    .commit_pnew_i(cpn),
    .commit_pold_i(cpo),
    .undo_valid_i(uv),
    .undo_rd_write_i(uwr),
    .undo_rd_fp_i(ufp),
    .undo_rd_arch_i(ua),
    .undo_pnew_i(upn),
    .undo_pold_i(upo)
  );

  wire [1:0] birth_write=alloc & rd_write &
      {rd_fp[1]||rd_arch[9:5]!=0,rd_fp[0]||rd_arch[4:0]!=0};
  wire [1:0] reclaim_write=uv & uwr & {ufp[1]||ua[9:5]!=0,ufp[0]||ua[4:0]!=0};
  R64Scoreboard #(.BATCH_SUFFIX_ROLLBACK(BATCH)) scoreboard(
    .clk(clk),.rst(rst),.flush_i(flush),.birth_write_i(birth_write),
    .birth_fp_i(rd_fp),.birth_preg_i(pn),.wb_write_i(ww),.wb_fp_i(canonical_fp),
    .wb_preg_i(canonical_preg),.reclaim_write_i(reclaim_write),.reclaim_fp_i(ufp),
    .reclaim_preg_i(upn),.query_preg_i(sp),.query_fp_i(src_fp),.query_ready_o(sr),
    .batch_apply_i(apply),.batch_greclaim_i(greclaim),.batch_freclaim_i(freclaim));

  // Independent lifetime ledger. Kill invokes sequential youngest-to-oldest
  // history undo immediately in the model; compare after DUT recovery drains.
  // It does not read the DUT batch mask, reducer, free bits, or chosen winner.
  integer gm[0:31],fm[0:31],gc[0:31],fc[0:31];
  reg [63:0] gf,ff,gb,fb,oldgf,oldff;
  reg live[0:31],writing[0:31],floating[0:31],raw_write[0:31];
  integer owner[0:31],serialno[0:31],dest[0:31],newp[0:31],oldp[0:31];
  integer sequence_id=0,checks=0,births=0,retirements=0,kills=0,victims=0;
  integer applied=0,nested=0,older_wb_recover=0,store_terminal_recover=0;
  integer victim_x0=0,victim_f0=0,victim_fp_p0=0,generation_wrap=0,
    publication_older_wb=0,store_error=0,store_success=0;
  integer publication_hist[0:32];
  initial for(integer h=0;h<=32;h+=1)publication_hist[h]=0;
  always @(posedge clk)if(!rst&&rob.redirect_accept_o)publication_hist[$countones(km)]+=1;
  integer l,slot,bank,a,np,op,s,seq,boundaryseq,expectpreg,waits;
  reg [63:0] usedg,usedf;
  reg [31:0] seen_birth=0;
  always @(posedge clk)begin
    if(rst)begin
      gf=64'hffffffff00000000;ff=gf;gb=0;fb=0;
      for(s=0;s<32;s+=1)begin gm[s]=s;fm[s]=s;gc[s]=s;fc[s]=s;live[s]=0;end
    end else if(flush)begin
      usedg=0;usedf=0;
      for(s=0;s<32;s+=1)begin
        gm[s]=gc[s];fm[s]=fc[s];usedg[gc[s]]=1;usedf[fc[s]]=1;live[s]=0;
      end
      gf=~usedg;ff=~usedf;gb=0;fb=0;
    end else begin
      oldgf=gf;oldff=ff;
      for(l=0;l<2;l+=1)if(wa[l])begin
        slot=int'(wt[l*T+:5]);
        if(!live[slot]||owner[slot]!=int'(wt[l*T+:T]))
          $fatal(1,"canonical WB accepted stale ledger owner");
        if(rec)older_wb_recover+=1;
        if(rob.redirect_accept_o)publication_older_wb+=1;
        if(ww[l])begin
          if(floating[slot])fb[newp[slot]]=0;else gb[newp[slot]]=0;
        end
      end
      if(sdvalid&&sdready&&rec)begin
        store_terminal_recover+=1;if(sderror)store_error+=1;else store_success+=1;
      end
      for(l=0;l<2;l+=1)if(cf[l])begin
        slot=int'(ct[l*T+:5]);
        if(!live[slot]||owner[slot]!=int'(ct[l*T+:T]))$fatal(1,"retire identity");
        if(writing[slot])begin
          if(floating[slot])begin fc[dest[slot]]=newp[slot];ff[oldp[slot]]=1;end
          else begin gc[dest[slot]]=newp[slot];gf[oldp[slot]]=1;end
        end
        live[slot]=0;retirements+=1;
      end
      if(rob.redirect_accept_o)begin
        kills+=1;if(rec)nested+=1;
        slot=int'(kill_tag[4:0]);boundaryseq=serialno[slot];
        if(!live[slot]||owner[slot]!=int'(kill_tag))$fatal(1,"kill identity");
        for(seq=sequence_id;seq>boundaryseq;seq-=1)
          for(s=0;s<32;s+=1)if(live[s]&&serialno[s]==seq)begin
            if(raw_write[s]&&!floating[s]&&dest[s]==0)victim_x0+=1;
            if(writing[s]&&floating[s]&&dest[s]==0)victim_f0+=1;
            if(writing[s]&&floating[s]&&newp[s]==0)victim_fp_p0+=1;
            if(writing[s])begin
              if(floating[s])begin fm[dest[s]]=oldp[s];ff[newp[s]]=1;fb[newp[s]]=0;end
              else begin gm[dest[s]]=oldp[s];gf[newp[s]]=1;gb[newp[s]]=0;end
            end
            live[s]=0;victims+=1;
          end
      end
      if(apply)applied+=1;
      for(l=0;l<2;l+=1)if(alloc[l])begin
        slot=int'(atag[l*T+:5]);a=int'(rd_arch[l*5+:5]);bank=int'(rd_fp[l]);
        np=int'(pn[l*P+:P]);op=int'(po[l*P+:P]);
        if(live[slot])$fatal(1,"birth overwrote ledger owner");
        if(seen_birth[slot]&&int'(atag[l*T+:T])<owner[slot])generation_wrap+=1;
        seen_birth[slot]=1;
        owner[slot]=int'(atag[l*T+:T]);serialno[slot]=sequence_id;sequence_id+=1;
        live[slot]=1;raw_write[slot]=rd_write[l];writing[slot]=rd_write[l]&&(bank!=0||a!=0);
        floating[slot]=bank!=0;dest[slot]=a;newp[slot]=np;oldp[slot]=op;births+=1;
        if(writing[slot])begin
          expectpreg=-1;
          for(s=63;s>=0;s-=1)if(bank!=0?oldff[s]:oldgf[s])expectpreg=s;
          if(np!=expectpreg||op!=(bank!=0?fm[a]:gm[a]))$fatal(1,"birth map/free allocation differs from ledger");
          if(bank!=0)begin fm[a]=np;ff[np]=0;fb[np]=1;oldff[np]=0;end
          else begin gm[a]=np;gf[np]=0;gb[np]=1;oldgf[np]=0;end
        end
      end
    end
  end
  task checkstate;
    begin
      if(!rec)begin
        checks+=1;
        for(integer q=0;q<32;q+=1)
          if(rename.gmap_q[q]!==6'(gm[q])||rename.fmap_q[q]!==6'(fm[q])||
             rename.gcommit_q[q]!==6'(gc[q])||rename.fcommit_q[q]!==6'(fc[q]))
            $fatal(1,"map ledger mismatch arch=%0d batch=%0d",q,BATCH);
        if(rename.gfree_q!==gf||rename.ffree_q!==ff||
           scoreboard.gbusy_q!==gb||scoreboard.fbusy_q!==fb)
          $fatal(1,"free/busy conservation mismatch batch=%0d gf=%h/%h ff=%h/%h gb=%h/%h fb=%h/%h",
            BATCH,rename.gfree_q,gf,rename.ffree_q,ff,scoreboard.gbusy_q,gb,scoreboard.fbusy_q,fb);
      end
    end
  endtask
  task tick;begin @(posedge clk);#1;checkstate();end endtask
  task check(input bit cond,input string msg);begin if(!cond)$fatal(1,"%s",msg);end endtask
  task quiet;begin req=0;wv=0;kill=0;recovery_preview=0;cr=0;sdvalid=0;end endtask
  task clear;begin quiet();flush=1;tick();flush=0;tick();end endtask
  task fill(input integer n,input integer mode);
    integer k,lan,ix,aa;
    begin
      k=0;
      while(k<n)begin
        req=k+1<n?3:1;rd_write=0;rd_fp=0;rd_arch=0;ameta=0;
        for(lan=0;lan<2;lan+=1)if(req[lan])begin
          ix=k+lan;rd_write[lan]=mode!=2;
          rd_fp[lan]=(mode==1&&ix%2==1)||(mode==4);
          aa=mode==1?(ix%4==1?0:10):5;rd_arch[lan*5+:5]=5'(aa);
          if(mode==1&&ix%7==3)begin rd_fp[lan]=0;rd_arch[lan*5+:5]=0;end
          if(mode==3&&ix==0)begin rd_write[lan]=0;ameta[lan*M+196+:8]=3;end
        end
        #1;check(alloc==req,"fill lacked real credits");
        tags[k]=atag[0+:T];news[k]=pn[0+:P];
        if(req[1])begin tags[k+1]=atag[T+:T];news[k+1]=pn[P+:P];end
        k+=int'(alloc[0])+int'(alloc[1]);tick();
      end
      req=0;
    end
  endtask
  task prepare(input integer boundary);
    begin recovery_preview=1;recovery_tag=tags[boundary];tick();recovery_preview=0;end
  endtask
  task publish(input integer boundary);
    begin kill=1;kill_tag=tags[boundary];#1;check(rob.redirect_accept_o,"real kill missing");
      check(cf==0&&alloc==0,"publication admitted namespace transition");tick();kill=0;end
  endtask
  task drain(input integer v);
    begin
      waits=0;
      while(rec&&waits<20)begin check(cf==0&&alloc==0,"recover must freeze");tick();waits+=1;end
      check(!rec,"rollback did not terminate");
      check(waits==(v==0?0:(BATCH?1:(v+1)/2)),"actual recovery cycle mismatch");
      $display("BATCH_LATENCY mode=%0d victims=%0d recover_edges=%0d",BATCH,v,waits);
    end
  endtask
  integer c,v,mode,k;
  reg [63:0] savegf,saveff;
  reg [8:0] recycled_tag,late_tag;
  reg [5:0] recycled_preg;
  integer late_rejected=0,blocked_reuse=0;
  initial begin
    tick();rst=0;tick();
    for(c=0;c<64;c+=1)begin
      clear();
      v=c%32;
      mode=c%3;fill(v+1,mode);prepare(0);publish(0);drain(v);
      // Surviving unresolved boundary's destination must remain busy.
      if(mode==0)check(scoreboard.gbusy_q[news[0]],"bulk clear destroyed retained older readiness");
    end
    // Move live head/tail across slot 31 while keeping legal generation history.
    clear();fill(30,2);cr=3;
    for(k=0;k<30;k+=2)begin wv=3;wt={tags[k+1],tags[k]};tick();end
    wv=0;while(count!=0)tick();cr=0;
    check(head==30,"wrap origin not reached");
    fill(32,1);prepare(0);publish(0);drain(31);

    // A new accepted older kill exactly replaces every would-be apply edge.
    clear();fill(10,1);prepare(7);
    recovery_preview=1;recovery_tag=tags[5];publish(7);
    savegf=rename.gfree_q;saveff=rename.ffree_q;
    recovery_preview=1;recovery_tag=tags[1];kill=1;kill_tag=tags[5];#1;
    check(!apply&&uv==0,"nested kill failed to defer all undo");tick();
    check(rename.gfree_q==savegf&&rename.ffree_q==saveff,"nested edge partly released physicals");
    recovery_preview=0;kill_tag=tags[1];#1;check(!apply&&uv==0,"second nested apply escaped");tick();kill=0;
    drain(8);
    // Stale raw kill is not an accepted redirect and cannot defer Q apply.
    clear();fill(8,0);prepare(0);publish(0);
    kill=1;kill_tag=tags[0]^9'h020;#1;
    check(!rob.redirect_accept_o&&(!BATCH||apply),"stale raw kill suppressed actual batch apply");
    drain(7);kill=0;

    // Freed pnew may be reused only after the independent ROB slot lease drains.
    late_tag=tags[1];reuse_block=32'h2;req=1;rd_write=1;rd_fp=0;rd_arch=5;
    repeat(3)begin #1;check(alloc==0,"draining owner slot reused");tick();blocked_reuse+=1;end
    reuse_block=0;#1;check(alloc==1,"released slot did not regain real credit");
    recycled_tag=atag[0+:9];recycled_preg=pn[0+:6];
    check(recycled_tag!=late_tag&&recycled_preg==news[1],"fulltag/preg reuse fixture absent");
    tick();req=0;wv=1;wt[0+:9]=late_tag;#1;
    check(wa==0&&ww==0,"late victim fulltag accepted after preg reuse");late_rejected+=1;tick();
    check(scoreboard.gbusy_q[recycled_preg],"stale WB woke recycled destination");
    wt[0+:9]=recycled_tag;#1;check(wa==1&&ww==1,"new fulltag WB not accepted");tick();wv=0;

    // Actual older retirement at preview preserves both committed and free history.
    clear();fill(10,0);wv=3;wt={tags[1],tags[0]};tick();wv=0;cr=3;
    prepare(4);cr=0;publish(4);drain(5);
    // Commit a WAW chain, then preserve a new uncommitted older writer across undo.
    clear();fill(4,0);cr=3;
    for(k=0;k<4;k+=2)begin wv=3;wt={tags[k+1],tags[k]};tick();end
    wv=0;while(count!=0)tick();cr=0;
    fill(10,0);prepare(0);publish(0);drain(9);
    // Older completion remains legal on publication and apply; a killed WB does not.
    clear();fill(8,0);prepare(2);
    wv=3;wt={tags[7],tags[0]};kill=1;kill_tag=tags[2];#1;
    check(wa==1,"publication lost older WB or accepted victim");tick();kill=0;
    wt={tags[7],tags[2]};#1;check(wa==1,"apply lost older WB or accepted victim");tick();wv=0;
    while(rec)tick();
    // A real head-store terminal uses its exact canonical tag during apply.
    for(c=0;c<2;c+=1)begin
      clear();fill(8,3);prepare(1);publish(1);
      sdvalid=1;sdtag=tags[0];sderror=c!=0;#1;
      check(sdready&&cf==0,"recovery suppressed canonical head B or allowed retirement");
      tick();sdvalid=0;while(rec)tick();
      check(cv[0]&&cx[0]==(c!=0),"head store terminal error/success was lost");
    end
    // Retiring an FPR f0 writer frees physical FPR 0; a younger f0 writer
    // can then own preg0, which bulk reclaim must clear just like any FPR.
    clear();req=1;rd_write=1;rd_fp=1;rd_arch=0;ameta=0;#1;
    check(alloc==1,"initial FPR f0 writer lacked credit");recycled_tag=atag[0+:9];
    tick();req=0;wv=1;wt[0+:9]=recycled_tag;tick();wv=0;cr=1;tick();cr=0;
    check(rename.ffree_q[0],"committed FPR f0 did not release old physical0");
    fill(2,1);check(news[1]==0,"FPR physical0 victim fixture absent");
    prepare(0);publish(0);drain(1);
    check(!scoreboard.fbusy_q[0]&&rename.ffree_q[0],"FPR physical0 not reclaimed");

    // Full flush dominates pending apply and restores only committed mappings.
    clear();fill(32,4);check(rename.ffree_q==0,"true FPR physical exhaustion missing");
    prepare(0);publish(0);flush=1;#1;check(!apply,"fullflush allowed batch apply");tick();flush=0;
    check(!rec&&$countones(rename.ffree_q)==32,"fullflush failed free restore");
    quiet();tick();
    check(kills>=65&&nested==2&&older_wb_recover>0&&store_terminal_recover==2,"required recovery event coverage absent");
    check(BATCH?applied>=39:applied==0,"apply coverage/disabled path");
    check(victim_x0>0&&victim_f0>0&&victim_fp_p0==1&&generation_wrap>0&&publication_older_wb==1&&store_error==1&&store_success==1,
          "bank/older terminal directed coverage missing");
    $display("BATCH_CORNER x0=%0d f0=%0d fp_p0=%0d generation_wrap=%0d publication_older_wb=%0d apply_older_wb=%0d store_success=%0d store_error=%0d",
      victim_x0,victim_f0,victim_fp_p0,generation_wrap,publication_older_wb,older_wb_recover,store_success,store_error);
    check(late_rejected==1&&blocked_reuse==3,"reuse boundary coverage missing");
    $display("BATCH_LEDGER mode=%0d checks=%0d births=%0d retired=%0d kills=%0d victims=%0d apply=%0d nested=%0d olderwb=%0d storeterminal=%0d laterejected=%0d reuseblocked=%0d",
      BATCH,checks,births,retirements,kills,victims,applied,nested,older_wb_recover,store_terminal_recover,late_rejected,blocked_reuse);
    for(integer h=0;h<=32;h+=1)if(publication_hist[h]!=0)
      $display("BATCH_PUBLICATION victims=%0d count=%0d",h,publication_hist[h]);
    $display("[PASS] tb_r64_batch_rollback");$finish;
  end
endmodule
