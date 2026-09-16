`timescale 1ns/1ps
module tb_r64_writeback_lanes;
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
  wire [1:0] wv; reg [1:0] wx=0,wfp=0;
  wire [2*T-1:0] wt;
  wire [127:0] wd; reg [127:0] wval=0;
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
  reg [3:0] shortv=0;reg [4*T-1:0] shorttag=0;reg [4*P-1:0] shortpreg=0;wire [3:0] shortaccept;
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
    .short_valid_i(shortv),.short_tag_i(shorttag),.short_preg_i(shortpreg),.short_accept_o(shortaccept),
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

  reg [1:0] source_valid=0;wire [1:0] source_ready;
  reg [17:0] source_tag=0;reg [127:0] source_data=0;
  reg read_fire=0;wire [1:0] read_valid;wire [383:0] read_operand;
  R64Writeback #(.SOURCES(2),.SOURCE_W(1),.RESULT_W(64)) wb(
    .clk(clk),.rst(rst),.flush_i(1'b0),.kill_mask_i(km),
    .source_valid_i(source_valid),.source_ready_o(source_ready),
    .source_tag_i(source_tag),.source_result_i(source_data),
    .wb_valid_o(wv),.wb_tag_o(wt),.wb_result_o(wd));
  R64RegRead #(.PAYLOAD_W(M)) prf(.in_mem_slot_i(10'b0),.out_mem_slot_o(),
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .in_fire_i({1'b0,read_fire}),.in_ready_o(),.in_tag_i(18'b0),
    .in_payload_i(64'b0),.in_class_i(6'b0),.in_gpr_dst_i(12'b0),
    .in_src_preg_i(sp),.in_src_fp_i(src_fp),.in_src_used_i(src_used),
    .wb_write_i(ww),.wb_fp_i(canonical_fp),.wb_preg_i(canonical_preg),.wb_data_i(wd),
    .alu_bypass_valid_i(2'b0),.alu_bypass_preg_i(12'b0),.alu_bypass_data_i(128'b0),
    .out_valid_o(read_valid),.out_ready_i(2'b11),.out_tag_o(),.out_payload_o(),
    .out_class_o(),.out_operand_o(read_operand),.out_gpr_dst_o());
  task tick;begin @(posedge clk);#1;end endtask
  task check;input good;input [511:0] msg;begin if(good!==1'b1)$fatal(1,"%0s",msg);end endtask
  task born;
    input [1:0] floating;
    begin
      req=3;rd_write=3;rd_fp=floating;rd_arch={5'd6,5'd5};#1;
      check(alloc==3,"dual allocation");
      tags[0]=atag[0+:T];tags[1]=atag[T+:T];
      news[0]=pn[0+:P];news[1]=pn[P+:P];
      tick();req=0;
    end
  endtask
  task send1;
    input [T-1:0] tag;input [63:0] data;
    begin
      source_valid=2;source_tag[T+:T]=tag;source_data[64+:64]=data;
      #1;check(source_ready[1],"physical lane1 grant");
      tick();source_valid=0;
    end
  endtask
  initial begin
    // Real WB -> ROB -> Rename readiness + PRF bypass/storage, both namespaces.
    for(i=0;i<2;i=i+1)begin
      rst=1;req=0;source_valid=0;src_used=0;tick();rst=0;born(i?2'b11:2'b00);
      src_used=1;src_fp=i?1:0;src_arch=5;#1;
      check(!sr[0],"new physical owner started ready");
      shortv=15;shorttag={tags[1],tags[0],tags[1],tags[0]};
      shortpreg={news[1],news[0],news[1],news[0]};#1;
      check(shortaccept==(i ? 4'b0000:4'b1111),"short owner namespace/full owner");
      shortpreg[P+:P]=news[1]^6'd1;shorttag[2*T+5]=~shorttag[2*T+5];#1;
      check(shortaccept==(i ? 4'b0000:4'b1001),"short owner accepted wrong preg or generation");
      shortpreg={news[1],news[0],news[1],news[0]};shorttag={tags[1],tags[0],tags[1],tags[0]};#1;
      check(cv==0&&!sr[0],"read-only short query changed completion/readiness");
      send1(tags[0],64'h123456789abc+i);
      check(wv==2&&wa==2&&ww==2,"lane1-only architectural acceptance");
      check(canonical_preg[P+:P]==news[0]&&canonical_fp[1]==i[0],
          "lane1-only physical destination/namespace");
      read_fire=1;tick();read_fire=0;tick();
      check(sr[0]&&read_valid==1&&read_operand[63:0]==64'h123456789abc+i,
          "lane1-only scoreboard or registered PRF read");
      read_fire=1;tick();read_fire=0;tick();
      check(read_operand[63:0]==64'h123456789abc+i,"lane1-only stored PRF value");
      check(cv==1&&cd[63:0]==64'h123456789abc+i,"lane1-only ROB completion data");
      check(shortaccept==(i ? 4'b0000:4'b1010),"done owner remained early/bypass eligible");
    end
    // Kill arrives after a result entered WB. Raw VALID may persist, while
    // the current ROB owner must reject it at every state-writing boundary.
    rst=1;src_used=0;tick();rst=0;born(0);
    shortv=15;shorttag={tags[1],tags[0],tags[1],tags[0]};shortpreg={news[1],news[0],news[1],news[0]};
    recovery_preview=1;recovery_tag=tags[0];
    send1(tags[1],64'hbad);recovery_preview=0;
    kill=1;kill_tag=tags[0];#1;
    check(wv==2&&km[tags[1][4:0]]&&wa==0&&ww==0,
        "raw killed WB holder reached architectural state");
    check(shortaccept==5,"current kill leaked a short owner query");
    tick();kill=0;
    repeat(3)tick();
    req=1;rd_write=1;rd_fp=0;rd_arch=6;#1;
    check(alloc[0]&&atag[4:0]==tags[1][4:0]&&atag[0+:T]!=tags[1],
        "squashed physical ROB slot did not get a new generation");
    tags[2]=atag[0+:T];news[2]=pn[0+:P];tick();req=0;
    shorttag={tags[1],tags[2],tags[2],tags[1]};
    shortpreg={news[1],news[2]^6'd1,news[2],news[1]};#1;
    check(shortaccept==2,"short query confused stale and current slot generations");
    send1(tags[1],64'hbad2);
    check(wv==2&&wa==0&&ww==0,"stale generation captured after slot reuse");
    tick();send1(tags[2],64'h600d);
    check(wv==2&&wa==2&&ww==2,"new generation completion rejected");
    // The test deliberately retains an upstream raw completion during a ROB
    // flush to verify that only the consumer's acceptance authorizes effects.
    flush=1;#1;check(shortaccept==0,"flush leaked a short owner query");check(wv==2&&wa==0&&ww==0,"ROB flush admitted raw WB residue");
    tick();flush=0;
    $display("[PASS] tb_r64_writeback_lanes GPR/FPR lane1-only bypass/scoreboard/ROB kill-generation-flush short-owner-query");
    $finish;
  end
endmodule
