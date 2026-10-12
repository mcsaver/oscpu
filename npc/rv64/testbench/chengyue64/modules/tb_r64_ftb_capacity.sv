`timescale 1ns/1ps
module tb_r64_ftb_capacity;
  parameter integer FTB_INDEX_W=5;
  localparam integer N=1<<FTB_INDEX_W;
  localparam [63:0] BASE=64'h80000000, DEST=64'h80010000;
  reg clk=0; always #5 clk=~clk;
  reg rst=1,run=0,redirect=0,invalidate=0,learn=0,resolve=0,repair=0;
  reg [63:0] address=BASE,lpc=0,ltarget=0,rpc=0,rtarget=0,repair_pc=0;
  reg [3:0] llen=0;
  reg taken=0,qr=0,sv=0,pr=0;
  reg [127:0] sd=128'h123456789abcdef0_fedcba9876543210;
  wire qv,sr,pv,pf,pplan,pword;
  wire [63:0] qp,pp;
  wire [127:0] pd;
  wire [4:0] pcause;
  wire [7:0] pmask;
  wire [2:0] poff;
  wire [62:0] ptgt;
  integer checks=0,row;
  reg [67:0] saved_plan;
  R64FetchStream #(.EARLY_PREDICT(1),.FTB_INDEX_W(FTB_INDEX_W)) dut(
    .clk_i(clk),.rst_i(rst),.run_i(run),.redirect_i(redirect),
    .redirect_block_i(address[63:4]),.redirect_offset_i(address[3:1]),.invalidate_i(invalidate),
    .learn_i(learn),.learn_pc_i(lpc),.learn_length_i(llen),.learn_target_i(ltarget),
    .resolve_i(resolve),.resolve_pc_i(rpc),.resolve_taken_i(taken),.resolve_target_i(rtarget),
    .repair_i(repair),.repair_block_i(repair_pc),
    .req_valid_o(qv),.req_ready_i(qr),.req_pc_o(qp),.rsp_valid_i(sv),.rsp_ready_o(sr),
    .rsp_data_i(sd),.rsp_fault_i(1'b0),.rsp_cause_i(5'd1),.rsp_access_mask_i(8'h5a),
    .packet_valid_o(pv),.packet_ready_i(pr),.packet_pc_o(pp),.packet_data_o(pd),
    .packet_fault_o(pf),.packet_cause_o(pcause),.packet_access_mask_o(pmask),
    .packet_plan_valid_o(pplan),.packet_plan_offset_o(poff),
    .packet_plan_word_o(pword),.packet_plan_target_o(ptgt));
  task tick; begin @(posedge clk); #1; @(negedge clk); end endtask
  task ck(input logic ok,input string text); begin
    checks++; if(ok!==1'b1) $fatal(1,"I=%0d %s",FTB_INDEX_W,text);
  end endtask
  task train(input [63:0] pc,input [3:0] length,input [63:0] target);
    begin learn=1;lpc=pc;llen=length;ltarget=target;tick();learn=0;end
  endtask
  task request(input [63:0] pc); begin
    ck(!qv && dut.owner_count_q==0 && dut.packet_count_q==0,"probe starts drained");
    address=pc;redirect=1;tick();redirect=0;run=1;tick();run=0;
    ck(qv && qp=={pc[63:4],4'b0},"actual request capture");
  end endtask
  task drain(input [63:0] pc,input logic hit,input [2:0] off,input logic word,input [63:0] target);
    begin
      ck(dut.req_plan_q[67]===hit,"request snapshot hit");
      if(hit) ck(dut.req_plan_q[66:0]=={off,word,target[63:1]},"request snapshot fields");
      qr=1;tick();qr=0;
      ck(sr && !qv,"accepted unique request owner");
      sv=1;tick();sv=0;
      ck(pv && pp==pc && pd==sd && !pf && pcause==1 && pmask==8'h5a,"packet owner/payload");
      ck(pplan===hit,"packet plan hit");
      if(hit) ck({poff,pword,ptgt}=={off,word,target[63:1]},"packet plan snapshot");
      pr=1;tick();pr=0;
      ck(!pv && !sr,"response and packet both drained");
    end
  endtask
  task probe(input [63:0] pc,input logic hit,input [2:0] off,input logic word,input [63:0] target);
    begin request(pc);drain(pc,hit,off,word,target);end
  endtask
  initial begin
    repeat(3)tick();rst=0;
    for(row=0;row<N;row++) train(BASE+64'(row*16+2),row[0]?4'd4:4'd2,DEST+64'(row*32));
    for(row=0;row<N;row++) probe(BASE+64'(row*16),1,1,row[0],DEST+64'(row*32));
    // The larger index separates addresses formerly competing at low five bits.
    train(BASE+64'h36,4,DEST+64'h1000);
    train(BASE+64'h236,2,DEST+64'h2000);
    probe(BASE+64'h30,FTB_INDEX_W>5,3,1,DEST+64'h1000);
    probe(BASE+64'h230,1,3,0,DEST+64'h2000);
    // Remaining same-index, different-signature aliases still replace.
    train(BASE+64'(N*16)+64'h36,4,DEST+64'h3000);
    probe(BASE+64'h30,0,0,0,0);
    probe(BASE+64'(N*16)+64'h30,1,3,1,DEST+64'h3000);
    // Bits above PC[24:4] remain ignored as before, not expanded by capacity.
    probe(BASE+64'h2000000+64'(N*16)+64'h30,1,3,1,DEST+64'h3000);
    train(BASE+64'h66,4,DEST+64'h4000);
    probe(BASE+64'h60,1,3,1,DEST+64'h4000);
    probe(BASE+64'h66,1,3,1,DEST+64'h4000);
    probe(BASE+64'h68,0,0,0,0);
    train(BASE+64'h66,6,DEST+64'h5000);
    train(BASE+64'h6e,4,DEST+64'h5000);
    probe(BASE+64'h60,1,3,1,DEST+64'h4000);
    train(BASE+64'h6e,2,DEST+64'h6000);
    probe(BASE+64'h60,1,7,0,DEST+64'h6000);
    // Same-edge update qualification uses old Q; learn then resolve then repair.
    train(BASE+64'h82,2,DEST);
    learn=1;lpc=BASE+64'(N*16)+64'h82;llen=4;ltarget=DEST+2;
    resolve=1;rpc=BASE+64'h82;taken=1;rtarget=DEST+4;tick();learn=0;resolve=0;
    probe(BASE+64'(N*16)+64'h80,1,1,1,DEST+4);
    learn=1;lpc=BASE+64'h82;llen=2;ltarget=DEST+6;
    resolve=1;rpc=BASE+64'(N*16)+64'h82;taken=1;rtarget=DEST+8;
    repair=1;repair_pc=BASE+64'h80;tick();learn=0;resolve=0;repair=0;
    probe(BASE+64'h80,0,0,0,0);
    learn=1;invalidate=1;tick();learn=0;invalidate=0;
    probe(BASE+64'h80,0,0,0,0);
    // Every physical repair index, including high rows, is reachable.
    for(row=0;row<N;row++) train(BASE+64'(row*16+2),2,DEST+64'(row*32));
    for(row=N-1;row>=0;row--) begin
      repair=1;repair_pc=BASE+64'(row*16);tick();repair=0;
      ck(!dut.target_valid_q[row],"repair clears requested physical row");
      if(row>0) ck(dut.target_valid_q[row-1],"repair does not truncate/alias another row");
      probe(BASE+64'(row*16),0,0,0,0);
    end
    // Held request, accepted owner, and held packet all retain the original snapshot.
    train(BASE+64'(N*16-14),4,DEST+64'h7000);
    request(BASE+64'(N*16-16));saved_plan=dut.req_plan_q;
    train(BASE+64'(2*N*16-14),2,DEST+64'h8000);
    repeat(3)begin tick();ck(qv && dut.req_plan_q==saved_plan,"held request ignores replacement");end
    qr=1;tick();qr=0;
    invalidate=1;tick();invalidate=0;
    repeat(3)begin tick();ck(sr && !pv,"owner survives delayed response and invalidate");end
    sv=1;tick();sv=0;
    repeat(3)begin tick();ck(pv && {pplan,poff,pword,ptgt}==saved_plan && pd==sd,"held packet retains original plan");end
    pr=1;tick();pr=0;
    // A redirected held request still drains its original accepted response exactly once.
    train(BASE+64'h12,2,DEST);
    request(BASE+64'h10);saved_plan=dut.req_plan_q;
    address=BASE+64'h8000;redirect=1;tick();redirect=0;
    ck(qv && dut.req_plan_q==saved_plan,"redirect does not withdraw held request");
    qr=1;tick();qr=0;sv=1;tick();sv=0;
    ck(!pv && !sr,"stale redirected response drains without packet");
    $display("[PASS] tb_r64_ftb_capacity I=%0d rows=%0d checks=%0d",FTB_INDEX_W,N,checks);
    $finish;
  end
  initial begin #1000000;$fatal(1,"timeout");end
endmodule
