`timescale 1ns/1ps
module tb_r64_lsu_response_ingress #(parameter EXPECT_LATENCY=1);
  reg clk=0;
  always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] kill=0;
  reg [1:0] iv=0,il=3,orr=0;
  wire [1:0] ir,ov,occ;
  reg [17:0] it=0;
  reg [127:0] idata=0;
  wire [17:0] ot;
  wire [127:0] odata;
  wire [31:0] reuse;
  wire idle;
  R64LsuResponseIngress #(.DATA_W(64)) dut(
    .clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
    .in_valid_i(iv),.in_ready_o(ir),.in_live_i(il),.in_tag_i(it),.in_data_i(idata),
    .out_occupied_o(occ),.out_valid_o(ov),.out_ready_i(orr),.out_tag_o(ot),
    .out_data_o(odata),.reuse_block_o(reuse),.idle_o(idle));
  integer accepted[0:511],returned[0:511],born[0:511];
  reg alive[0:511];
  integer cycle=0,accepted_total=0,returned_total=0,canceled=0,dual=0,latency_sum=0;
  integer l,t,n,k;
  reg [1:0] held=0;
  reg [17:0] held_tag;
  reg [127:0] held_data;
  always @(posedge clk) if(!rst) begin
    cycle=cycle+1;
    for(t=0;t<512;t=t+1)
      if(alive[t] && (flush || kill[t%32])) begin alive[t]=0; canceled=canceled+1; end
    if((iv & ir)==3) dual=dual+1;
    for(l=0;l<2;l=l+1) begin
      if(held[l] && !flush && !kill[held_tag[l*9+:5]] &&
         (ot[l*9+:9]!==held_tag[l*9+:9] || odata[l*64+:64]!==held_data[l*64+:64] || !ov[l]))
        $fatal(1,"ingress backpressure changed held owner");
      if(ov[l]) begin
        t=int'(ot[l*9+:9]);
        if(!alive[t] || accepted[t]!=1 || cycle-born[t]<EXPECT_LATENCY ||
           odata[l*64+:64]!==64'h1234000000000000+t || !reuse[t%32])
          $fatal(1,"ingress invalid/early/wrong-owner publication tag=%0d age=%0d",t,cycle-born[t]);
        if(orr[l]) begin
          if(t<32) begin
            if(cycle-born[t]!=EXPECT_LATENCY) $fatal(1,"ingress unstalled latency tag=%0d age=%0d expected=%0d",t,cycle-born[t],EXPECT_LATENCY);
            latency_sum=latency_sum+cycle-born[t];
          end
          returned[t]=returned[t]+1; alive[t]=0; returned_total=returned_total+1;
          if(returned[t]!=1) $fatal(1,"duplicate ingress result");
        end
      end
      if(iv[l] && ir[l]) begin
        t=int'(it[l*9+:9]);
        accepted[t]=accepted[t]+1; born[t]=cycle; accepted_total=accepted_total+1;
        alive[t]=il[l] && !flush && !kill[t%32];
        if(!alive[t]) canceled=canceled+1;
        if(accepted[t]!=1) $fatal(1,"fixture duplicate tag");
      end
    end
    held=ov & ~orr; held_tag=ot; held_data=odata;
  end
  initial begin
    for(t=0;t<512;t=t+1) begin accepted[t]=0;returned[t]=0;born[t]=0;alive[t]=0;end
    repeat(3) @(negedge clk); rst=0;
    // Resident payload isolation must still accept two packets on every edge.
    orr=3;
    for(n=0;n<16;n=n+1) begin
      @(negedge clk);
      if(ir!==3) $fatal(1,"unstalled ingress lost dual-lane credit");
      iv=3;it={9'(2*n+1),9'(2*n)};
      idata={64'h1234000000000001+64'(2*n),64'h1234000000000000+64'(2*n)};
    end
    @(negedge clk);iv=0;
    repeat(5) @(negedge clk);
    if(!idle || accepted_total!=32 || returned_total!=32)
      $fatal(1,"unstalled ingress throughput/ordering failure");
    // Deterministic dual-lane stream, arbitrary completion stalls, kill while
    // receiving, held cancellation, flush+capture, dead accepted packets.
    for(n=0;n<96;n=n+1) begin
      @(negedge clk);
      orr=(n%9<4) ? 0 : (n%7==0 ? 1 : 3);
      flush=n==22 || n==59;
      kill=(n%11==3) ? (32'b1 << ((n-3)%32)) : 0;
      il=n%13==5 ? 1 : 3;
      iv=ir;
      it={9'(2*n+65),9'(2*n+64)};
      idata={64'h1234000000000041+64'(2*n),64'h1234000000000040+64'(2*n)};
    end
    @(negedge clk); iv=0;flush=0;kill=0;orr=3;
    repeat(12) @(negedge clk);
    if(!idle || reuse!=0 || accepted_total!=returned_total+canceled || dual<16)
      $fatal(1,"ingress drain/accounting accepted=%0d returned=%0d canceled=%0d dual=%0d latency_sum=%0d",
             accepted_total,returned_total,canceled,dual,latency_sum);
    for(k=0;k<512;k=k+1) if(alive[k]) $fatal(1,"missing ingress result tag=%0d",k);
    $display("[PASS] tb_r64_lsu_response_ingress accepted=%0d returned=%0d canceled=%0d dual=%0d latency_sum=%0d",
             accepted_total,returned_total,canceled,dual,latency_sum);
    $finish;
  end
  initial begin #20000;$fatal(1,"ingress timeout");end
endmodule
