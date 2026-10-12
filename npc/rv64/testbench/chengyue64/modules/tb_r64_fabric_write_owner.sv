`timescale 1ns / 1ps
module tb_r64_fabric_write_owner #(parameter WRITE_B_EMPTY_FLOW=1, AW_EMPTY_ADMIT=1);
  localparam [2:0] READ_MEMORY_MASK=0;
  localparam integer N = 96, M = 64, S = 3;
  reg clk_i = 0;
  always #5 clk_i = ~clk_i;
  reg bad_last;
  initial bad_last = $test$plusargs("bad-last");
  reg [1023:0] outputs_before;
  reg rst_i = 1;
  reg arvalid_i = 0;
  wire arready_o;
  reg [3:0] arid_i = 0;
  reg [63:0] araddr_i = 0;
  reg [7:0] arlen_i = 0;
  reg [2:0] arsize_i = 0, arprot_i = 0;
  reg [1:0] arburst_i = 1;
  wire rvalid_o;
  reg rready_i = 0;
  wire [3:0] rid_o;
  wire [63:0] rdata_o;
  wire [1:0] rresp_o;
  wire rlast_o;
  reg awvalid_i = 0;
  wire awready_o;
  reg [3:0] awid_i = 0;
  reg [63:0] awaddr_i = 0;
  reg [7:0] awlen_i = 0;
  reg [2:0] awsize_i = 0;
  reg [1:0] awburst_i = 1;
  reg wvalid_i = 0;
  wire wready_o;
  reg [63:0] wdata_i = 0;
  reg [7:0] wstrb_i = 0;
  reg wlast_i = 0;
  wire bvalid_o;
  reg bready_i = 0;
  wire [3:0] bid_o;
  wire [1:0] bresp_o;
  wire [S-1:0] s_arvalid_o;
  reg [S-1:0] s_arready_i = 0;
  wire [S*64-1:0] s_araddr_o;
  wire [S*3-1:0] s_arsize_o, s_arprot_o;
  reg [S-1:0] s_rvalid_i = 0;
  wire [S-1:0] s_rready_o;
  reg [S*64-1:0] s_rdata_i = 0;
  reg [S*2-1:0] s_rresp_i = 0;
  wire [S-1:0] s_awvalid_o;
  reg [S-1:0] s_awready_i = 0;
  wire [S*64-1:0] s_awaddr_o;
  wire [S*3-1:0] s_awsize_o;
  wire [S-1:0] s_wvalid_o;
  reg [S-1:0] s_wready_i = 0;
  wire [S*64-1:0] s_wdata_o;
  wire [S*8-1:0] s_wstrb_o;
  reg [S-1:0] s_bvalid_i = 0;
  wire [S-1:0] s_bready_o;
  reg [S*2-1:0] s_bresp_i = 0;
  wire protocol_error_o;
  R64AxiFabric #(
    .SLAVES(S),.WRITE_B_EMPTY_FLOW(WRITE_B_EMPTY_FLOW),.AW_EMPTY_ADMIT(AW_EMPTY_ADMIT),
    .SLAVE_W(2),
    .READ_MEMORY_MASK(READ_MEMORY_MASK),
    .BASE({64'h10000000, 64'ha0000000, 64'h80000000}),
    .MASK({64'hfffffffffffff000, 64'hfffffffff0000000, 64'hfffffffff0000000}),
    .MEMORY(3'b011),
    .EXECUTABLE(3'b011)
  ) dut (
    .*
  );


  integer cycle=0,checks=0,aw_count=0,w_count=0,b_count=0,lite_aw=0,lite_w=0,lite_b=0;
  integer bseen[0:15],alive[0:15],bcycle[0:15],awcycle[0:15];
  reg [1:0] gotresp[0:15];
  integer direct=0,blocked=0,old_priority=0,dual_b=0,bad_capture=0,aw_direct=0,aw_fallback=0;
  integer old_skid=0,duplicate_hold=0,full_hold=0;
  reg hold_b=0;reg[5:0] held_b;
  reg [S-1:0] hold_aw=0,hold_w=0;
  reg [66:0] held_aw[0:S-1];reg[71:0] held_w[0:S-1];
  integer last_lite_b=-1,last_bad_terminal=-1;
  always @(posedge clk_i)begin
    cycle+=1;
    if(!rst_i&&!dut.reset_q)begin
      if(awvalid_i&&awready_o)begin
        alive[awid_i]+=1;aw_count+=1;awcycle[awid_i]=cycle;
        if(dut.wadmit_w&&!dut.awi_q)aw_direct+=1;else aw_fallback+=1;
      end
      if(wvalid_i&&wready_o)w_count+=1;
      if(hold_b&&(!bvalid_o||{bid_o,bresp_o}!==held_b))$fatal(1,"B owner/data changed under backpressure");
      hold_b=bvalid_o&&!bready_i;held_b={bid_o,bresp_o};
      if(hold_b)blocked+=1;
      if(bvalid_o&&bready_i)begin
        if(alive[bid_o]<=0)$fatal(1,"B without accepted live ID");
        alive[bid_o]-=1;b_count+=1;bseen[bid_o]+=1;gotresp[bid_o]=bresp_o;bcycle[bid_o]=cycle;
      end
      if(dut.bdirect_pop_w)direct+=1;
      if(dut.bout_q&&|dut.wreturn_w)old_priority+=1;
      if((s_bvalid_i&s_bready_o)==3'b011)dual_b+=1;
      if(dut.awi_q)old_skid+=1;
      if(dut.awi_q&&dut.wduplicate_r)duplicate_hold+=1;
      if(dut.awi_q&&(!dut.wfree_r||dut.oc_q==2))full_hold+=1;
      if(dut.wbeat_w&&dut.wbad_q[dut.wh_w]&&dut.wn_q[dut.wh_w]==0)begin
        bad_capture+=1;last_bad_terminal=cycle;
        if(!dut.bout_q && !dut.wterminal_q[dut.wh_w] &&
           (dut.wh_w==0 || !(dut.wterminal_q[0]||dut.wterminal_now_w[0])) &&
           dut.bdirect_offer_w)$fatal(1,"bad-current owner bypassed registered terminal");
      end
      for(integer j=0;j<S;j+=1)begin
        if(hold_aw[j]&&(!s_awvalid_o[j]||{s_awaddr_o[j*64+:64],s_awsize_o[j*3+:3]}!==held_aw[j]))
          $fatal(1,"external AW changed while blocked");
        if(hold_w[j]&&(!s_wvalid_o[j]||{s_wdata_o[j*64+:64],s_wstrb_o[j*8+:8]}!==held_w[j]))
          $fatal(1,"external W changed while blocked");
        hold_aw[j]=s_awvalid_o[j]&&!s_awready_i[j];
        hold_w[j]=s_wvalid_o[j]&&!s_wready_i[j];
        held_aw[j]={s_awaddr_o[j*64+:64],s_awsize_o[j*3+:3]};
        held_w[j]={s_wdata_o[j*64+:64],s_wstrb_o[j*8+:8]};
        if(s_awvalid_o[j]&&s_awready_i[j])lite_aw+=1;
        if(s_wvalid_o[j]&&s_wready_i[j])lite_w+=1;
        if(s_bvalid_i[j]&&s_bready_o[j])begin lite_b+=1;last_lite_b=cycle;end
      end
    end else begin hold_b=0;hold_aw=0;hold_w=0;end
  end
  task tick;begin @(posedge clk_i);#1;@(negedge clk_i);end endtask
  task check(input yes,input[511:0] why);begin checks+=1;if(yes!==1'b1)$fatal(1,"%0s",why);end endtask
  task clean;
    begin
      rst_i=1;awvalid_i=0;wvalid_i=0;bready_i=0;s_bvalid_i=0;s_bresp_i=0;
      s_awready_i=7;s_wready_i=7;repeat(3)tick();rst_i=0;repeat(2)tick();
      for(integer i=0;i<16;i+=1)begin bseen[i]=0;alive[i]=0;bcycle[i]=-1;awcycle[i]=-1;gotresp[i]=0;end
    end
  endtask
  task aw(input integer id,input [63:0] addr,input integer len,input [2:0] size,input [1:0] burst);
    begin
      awid_i=4'(id);awaddr_i=addr;awlen_i=8'(len);awsize_i=size;awburst_i=burst;awvalid_i=1;
      #1;while(!awready_o)tick();tick();awvalid_i=0;
      awid_i=15;awaddr_i=64'hbad;awlen_i=255;awsize_i=7;awburst_i=3;
    end
  endtask
  task data_beat(input [63:0] value,input last);
    begin
      wdata_i=value;wstrb_i=8'hff;wlast_i=last;wvalid_i=1;
      #1;while(!wready_o)tick();tick();wvalid_i=0;
    end
  endtask
  task response(input [2:0] mask,input [5:0] value);
    reg [2:0] ready_before;
    reg [6:0] offer_before;
    begin
      while((s_bready_o&mask)!=mask)tick();
      ready_before=s_bready_o;bready_i=~bready_i;#1;
      check(s_bready_o===ready_before,"upstream BREADY affected Lite B credit");
      bready_i=~bready_i;s_bvalid_i=mask;s_bresp_i=value;#1;
      offer_before={bvalid_o,bid_o,bresp_o};bready_i=~bready_i;#1;
      check({bvalid_o,bid_o,bresp_o}===offer_before&&s_bready_o===ready_before,
        "current B offer/data or Lite credit depends on upstream BREADY");
      bready_i=~bready_i;tick();s_bvalid_i=0;s_bresp_i=0;
    end
  endtask
  task await_b(input integer id,input integer count,input [1:0] resp);
    integer n;
    begin n=0;while(bseen[id]<count&&n<50)begin tick();n+=1;end
      check(bseen[id]==count&&gotresp[id]===resp,"upstream B response/count wrong");end
  endtask
  integer saved_aw,saved_w,saved_b,b0_cycle,n;
  reg [1:0] wait_live;
  initial begin
    clean();
    // First final B error must appear in this edge's direct BRESP, and both
    // endpoint/AXI owners are released only on their respective handshakes.
    bready_i=1;aw(2,64'h80000000,0,3,1);data_beat(64'h1234,!bad_last);
    response(1,bad_last?6'b0:6'b000010);await_b(2,1,2);
    check(bcycle[2]-last_lite_b==(WRITE_B_EMPTY_FLOW?0:1),"direct final B latency");
    check(dut.wlive_q==0&&dut.wbusy_q==0,"final B ownership leaked");
    if(bad_last)begin check(protocol_error_o,"WLAST error was hidden");$display("[PASS] malformed WLAST response preserved");$finish;end

    // Error from an earlier beat remains ORed with a different last-beat error.
    clean();bready_i=1;aw(3,64'h80000100,2,3,1);
    data_beat(1,0);response(1,6'b000001);
    data_beat(2,0);response(1,0);
    data_beat(3,1);response(1,6'b000010);await_b(3,1,3);

    // Blocked first offer captures final error and ID once. A second endpoint
    // may return behind it; the old B owner must not change.
    clean();aw(4,64'h80000200,0,3,1);data_beat(4,1);
    aw(5,64'ha0000200,0,3,1);data_beat(5,1);
    response(1,6'b000010);repeat(3)tick();
    check(bvalid_o&&bid_o==4&&bresp_o==2&&dut.wlive_q==3,"blocked B lost owner/error");
    check(!dut.wbusy_q[0],"real B did not release endpoint while upstream blocked");
    response(2,6'b001100);repeat(4)tick();
    check(bvalid_o&&bid_o==4&&bresp_o==2,"new terminal replaced old bout");
    bready_i=1;await_b(4,1,2);await_b(5,1,3);repeat(3)tick();
    check(bseen[4]==1&&bseen[5]==1,"duplicate B after stalled direct capture");


    // A held slot-one owner outranks a newly completed slot-zero candidate.
    // Exercise both error assignments, including the direct-to-held edge.
    for(n=0;n<2;n+=1)begin
      clean();aw(4,64'h80000200,0,3,1);data_beat(4,1);
      aw(5,64'ha0000200,0,3,1);data_beat(5,1);
      response(2,n?6'b001100:6'b001000);repeat(2)tick();
      check(bvalid_o&&bid_o==5&&bresp_o==(n?3:2)&&dut.bowner_q==1,
        "slot-one response failed blocked capture");
      response(1,n?6'b000010:6'b000011);repeat(3)tick();
      check(bvalid_o&&bid_o==5&&bresp_o==(n?3:2),"new slot-zero candidate replaced held slot-one B");
      bready_i=1;await_b(5,1,n?3:2);await_b(4,1,n?2:3);
      check(bcycle[5]<bcycle[4],"held slot-one response lost priority");
    end

    // Two independent endpoints return in the same cycle. Select owner zero
    // once and keep the other terminal owner until its upstream handshake.
    clean();bready_i=1;aw(6,64'h80000300,0,3,1);data_beat(6,1);
    aw(7,64'ha0000300,0,3,1);data_beat(7,1);
    response(3,6'b000110);await_b(6,1,2);await_b(7,1,1);
    check(bcycle[6]<bcycle[7],"simultaneous endpoints changed candidate priority");

    // Same ID may enter the skid but cannot own a second slot before B.
    clean();aw(1,64'h80000400,0,3,1);data_beat(1,1);
    aw(1,64'ha0000400,0,3,1);repeat(3)tick();
    check(dut.awi_q&&dut.wduplicate_r,"duplicate AW did not stay in skid");
    bready_i=1;response(1,0);await_b(1,1,0);
    repeat(3)tick();check(!dut.awi_q,"same-ID descriptor failed after old B release");
    data_beat(2,1);response(2,0);await_b(1,2,0);

    // Both owner slots busy: a third accepted descriptor captures all fields
    // in the skid, without borrowing the upcoming B release.
    clean();aw(8,64'h80000500,0,3,1);data_beat(8,1);
    aw(9,64'ha0000500,0,3,1);data_beat(9,1);
    aw(10,64'h80000600,0,2,1);repeat(2)tick();
    check(dut.awi_q&&!dut.wfree_r,"full-owner AW did not fallback");
    bready_i=1;response(1,0);await_b(8,1,0);repeat(3)tick();
    check(!dut.awi_q,"third descriptor failed to admit after Q credit");
    data_beat(10,1);response(1,0);await_b(10,1,0);response(2,0);await_b(9,1,0);

    // Bad MMIO burst/unmapped/alignment/page/size/burst descriptors drain W
    // locally and never create a physical endpoint side effect.
    for(n=0;n<6;n+=1)begin
      clean();saved_aw=lite_aw;saved_w=lite_w;bready_i=1;
      case(n)
        0:aw(11,64'h10000000,1,3,1);
        1:aw(11,64'h50000000,1,3,1);
        2:aw(11,64'h80000001,1,3,1);
        3:aw(11,64'h80000ff8,1,3,1);
        4:aw(11,64'h80000000,1,4,1);
        5:aw(11,64'h80000000,1,3,2);
      endcase
      data_beat(1,0);data_beat(2,1);await_b(11,1,3);
      check(bcycle[11]-last_bad_terminal==1,"bad-current bypassed original terminal capture");
      check(lite_aw==saved_aw&&lite_w==saved_w,"invalid AW leaked to endpoint");
    end

    // AW and W are independently registered even when input AW bypasses the
    // empty skid. Hold each physical channel without changing its payload.
    clean();s_awready_i=0;s_wready_i=0;
    data_beat(64'hfeef,1);aw(12,64'h80000700,0,1,1);repeat(3)tick();
    check(s_awvalid_o[0]&&s_wvalid_o[0]&&s_awaddr_o[0+:64]==64'h80000700&&s_wdata_o[0+:64]==64'hfeef,
      "AW-empty path failed registered independent AW/W");
    s_wready_i=1;repeat(3)tick();check(!s_bready_o[0],"B accepted before missing AW");
    s_awready_i=1;repeat(2)tick();bready_i=1;response(1,0);await_b(12,1,0);

    // Reset wins a current final Lite response. No direct offer survives the
    // external reset or local reset clearing edge.
    clean();aw(13,64'h80000800,0,3,1);data_beat(13,1);while(!s_bready_o[0])tick();
    s_bvalid_i=1;s_bresp_i=2;bready_i=1;rst_i=1;#1;
    check(!bvalid_o,"direct B leaked on asserted reset");
    tick();s_bvalid_i=0;rst_i=0;#1;check(!bvalid_o,"direct B survived local reset edge");repeat(2)tick();
    check(dut.wlive_q==0&&dut.wterminal_q==0&&dut.wbusy_q==0&&!bvalid_o,"reset retained B owner");

    check(old_priority>0&&dual_b>0&&blocked>0&&bad_capture>=6&&duplicate_hold>0&&full_hold>0,
      "write owner coverage gap");
    if(WRITE_B_EMPTY_FLOW)check(direct>0,"direct B coverage absent");else check(direct==0,"B option disabled but bypassed");
    if(AW_EMPTY_ADMIT)check(aw_direct>0&&aw_fallback>0,"AW direct/fallback coverage absent");
    $display("[PASS] tb_r64_fabric_write_owner AW=%0d B=%0d checks=%0d directB=%0d blocked=%0d old=%0d dual=%0d bad=%0d directAW=%0d fallbackAW=%0d sameID=%0d full=%0d",
      AW_EMPTY_ADMIT,WRITE_B_EMPTY_FLOW,checks,direct,blocked,old_priority,dual_b,bad_capture,aw_direct,aw_fallback,duplicate_hold,full_hold);
    $finish;
  end
  initial begin #200000;$fatal(1,"write owner timeout");end
endmodule
