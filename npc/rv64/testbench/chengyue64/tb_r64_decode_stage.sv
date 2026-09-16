`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_decode_stage;
  localparam U=`R64_UOP_W,M=`R64_META_W,W=U+M+32;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,clear=0,stop=0;
  reg [1:0] iv=0,take=0;wire [1:0] ready,ov;
  reg [127:0] pc=0,raw=0,pred=0,tval=0;
  reg [7:0] len=0;reg [1:0] exc=0;reg [11:0] cause=0;
  wire [2*U-1:0] uop;wire [2*M-1:0] meta;
  wire [5:0] cls,sfp,sused;wire [1:0] wr,dfp,serial;
  wire [9:0] rd;wire [29:0] src;
  wire [W-1:0] expected_in[0:1],actual[0:1];
  wire [65:0] expanded;wire [69:0] prepared_control;
  R64DecodeStage #(.PREDECODED(1),.PREPARED_NPC(1),.PRECONTROLLED(1)) dut(.control_i(prepared_control),.sequential_npc_i({pc[127:64]+{60'b0,len[7:4]},pc[63:0]+{60'b0,len[3:0]}}),.canonical_i(expanded),.clk(clk),.rst(rst),.clear_i(clear),.stop_i(stop),
    .in_valid_i(iv),.in_ready_o(ready),.pc_i(pc),.raw_i(raw),
    .pred_npc_i(pred),.length_i(len),.exception_i(exc),.cause_i(cause),
    .tval_i(tval),.out_valid_o(ov),.out_take_i(take),.uop_o(uop),
    .meta_o(meta),.class_o(cls),.src_fp_o(sfp),.src_used_o(sused),
    .rd_write_o(wr),.rd_fp_o(dfp),.rd_arch_o(rd),.src_arch_o(src),.serial_o(serial));
  genvar l;
  generate for(l=0;l<2;l=l+1)begin:reference_decode
    R64DecodeControl prepare(.canonical_i(expanded[l*33+:33]),.raw_i(raw[l*64+:64]),
      .length_i(len[l*4+:4]),.control_o(prepared_control[l*35+:35]));
    wire [31:0] compressed;wire bad_compressed;
    R64Rvc expand(.c_i(raw[l*64+:16]),.inst_o(compressed),.illegal_o(bad_compressed));
    assign expanded[l*33+:33]=len[l*4+:4]==2 ? {bad_compressed,compressed}:{1'b0,raw[l*64+:32]};
    wire [U-1:0] u;wire [M-1:0] m;wire [2:0] c,f,s;
    wire w,d,z;wire [4:0] r;wire [14:0] a;
    R64DecodeReference reference(.canonical_i(33'b0),.pc_i(pc[l*64+:64]),.raw_i(raw[l*64+:64]),
      .length_i(len[l*4+:4]),.pred_npc_i(pred[l*64+:64]),
      .fetch_exception_i(exc[l]),.fetch_cause_i(cause[l*6+:6]),
      .fetch_tval_i(tval[l*64+:64]),.uop_o(u),.meta_o(m),.class_o(c),
      .rd_write_o(w),.rd_fp_o(d),.rd_arch_o(r),.src_arch_o(a),
      .src_fp_o(f),.src_used_o(s),.serial_o(z),.illegal_o());
    assign expected_in[l]={u,m,c,w,d,r,a,f,s,z};
    assign actual[l]={uop[l*U+:U],meta[l*M+:M],cls[l*3+:3],wr[l],dfp[l],
      rd[l*5+:5],src[l*15+:15],sfp[l*3+:3],sused[l*3+:3],serial[l]};
  end endgenerate
  reg [W-1:0] queue[0:16383];
  integer front=0,back=0,seed=32'h4819302,cycles=0,n,j;
  integer accepted=0,dispatched=0,cancelled=0,full_pop=0,dual=0,partial=0,held=0;
  reg [1:0] want_ready,saved_ready;
  task step;
    input integer sends,pops;
    input bit cancel_now,stop_now;
    reg [1:0] fire;
    begin
      @(negedge clk);
      clear=cancel_now;stop=stop_now;take=0;
      iv=sends==2 ? 3:sends==1 ? 1:0;
      for(j=0;j<4;j=j+1)begin
        raw[j*32+:32]=$random(seed);pc[j*32+:32]=$random(seed);
        pred[j*32+:32]=$random(seed);tval[j*32+:32]=$random(seed);
      end
      // Include ordinary, compressed, long, fault and illegal instructions.
      if(cycles%4==0)raw={32'b0,32'h00110113,32'b0,32'h00208113};
      if(cycles%4==1)raw={32'b0,32'h300110f3,32'b0,32'h005120a3};
      len=(cycles%3==0) ? 8'h22 : (cycles%3==1) ? 8'h44:8'h88;
      if(cycles>=208&&cycles<240)begin pc={64'hfffffffffffffff1,64'hffffffffffffffff};len={4'(cycles),4'(cycles+1)};end
      exc=(cycles%5==0) ? 2'($random(seed)):0;
      cause=12'($random(seed));
      #1;
      want_ready=(clear||stop) ? 0 : (back-front<=2) ? 3 : (back-front==3) ? 1:0;
      if(ready!==want_ready)$fatal(1,"Q credit count=%0d ready=%b wanted=%b",back-front,ready,want_ready);
      if(ov!==(clear ? 2'b0 : back-front>=2 ? 2'b11 : back>front ? 2'b01:2'b0))
        $fatal(1,"decoded validity disagrees with abstract queue");
      for(j=0;j<2;j=j+1)if(ov[j]&&actual[j]!==queue[front+j])
        $fatal(1,"decoded owner/payload changed cycle=%0d entry=%0d lane=%0d",cycles,front+j,j);
      saved_ready=ready;
      if(!clear&&!stop)take=(pops==2&&ov==3) ? 3 : (pops>0&&ov[0]) ? 1:0;
      #1;
      if(ready!==saved_ready)$fatal(1,"downstream take leaked into ingress credit");
      fire=iv&ready;
      if(back-front==4&&take!=0)full_pop=full_pop+1;
      if(take==3&&fire==3)dual=dual+1;
      if(take==1)partial=partial+1;
      if(ov!=0&&take==0)held=held+1;
      if(clear)begin cancelled=cancelled+back-front;front=back;end
      else begin
        for(j=0;j<2;j=j+1)if(take[j])begin front=front+1;dispatched=dispatched+1;end
        for(j=0;j<2;j=j+1)if(fire[j])begin queue[back]=expected_in[j];back=back+1;accepted=accepted+1;end
      end
      @(posedge clk);#1;cycles=cycles+1;
    end
  endtask
  initial begin
    @(posedge clk);#1;rst=0;
    step(2,0,0,0);step(2,0,0,0);step(2,2,0,0);
    for(n=0;n<200;n=n+1)step(2,2,0,0);
    if(dual!=200)$fatal(1,"four slots failed steady two-wide throughput");
    step(1,1,0,0);step(2,1,0,0);step(2,0,0,1);step(2,2,1,0);
    for(n=0;n<3000;n=n+1)
      step(($unsigned($random(seed))%3),($unsigned($random(seed))%3),n%71==0,n%29==0);
    repeat(4)step(0,2,0,0);
    if(back!=front||accepted!=dispatched+cancelled||full_pop<10||partial<100||held<100)
      $fatal(1,"missing queue lifecycle/throughput coverage");
    $display("[PASS] tb_r64_decode_stage accepted=%0d dispatched=%0d cancelled=%0d full_pop=%0d dual=%0d partial=%0d held=%0d",
      accepted,dispatched,cancelled,full_pop,dual,partial,held);
    $finish;
  end
endmodule
