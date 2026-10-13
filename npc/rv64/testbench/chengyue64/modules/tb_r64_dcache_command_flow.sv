`timescale 1ns / 1ps
module tb_r64_dcache_command_flow;
  parameter FLOW=1;
  parameter SPLIT=1;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, invalidate = 0, reservation_clear = 0;
  reg  [ 1:0] req_valid = 0;
  wire [ 1:0] req_ready;
  reg  [11:0] req_token = 0;
  reg [127:0] req_addr = 0, req_data = 0, req_expected = 0;
  reg [ 3:0] req_op = 0;
  reg [ 1:0] req_cache = 3;
  reg [ 5:0] req_size = {3'd3, 3'd3};
  reg [15:0] req_strb = 16'hffff;
  reg [ 9:0] req_amo = 0;
  wire [1:0] rsp_valid, rsp_error, rsp_compare;
  reg  [  1:0] rsp_ready = 3;
  wire [ 11:0] rsp_token;
  wire [127:0] rsp_data;
  wire rv, br;
  reg rr=1;
  wire [63:0] ra;
  wire [7:0] rl;
  wire [2:0] rs;
  reg bv = 0;
  reg [63:0] bd = 0;
  reg [1:0] be = 0;
  reg bl = 0;
  wire wv, wdv, bready;
  reg wr=1, wdready=1;
  wire [63:0] wa, wd;
  wire [7:0] ws;
  wire [2:0] wz;
  reg write_pause = 0, aw_block=0, w_block=0;
  reg [1:0] response_hold = 0, fast_store = 0;
  wire fast_valid, fast_error;
  wire [5:0] fast_token;
  reg fast_ready = 1;
  reg bvalid = 0;
  reg [1:0] bresp = 0;
  wire idle, mutation;
  wire [60:0] mutationword;
  R64Dcache #(
    .SET_W(6),
    .SPLIT_STORE_OWNER(SPLIT), .STORE_COMMAND_EMPTY_FLOW(FLOW)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .invalidate_i(invalidate),
    .reservation_clear_i(reservation_clear),
    .req_fast_store_i(fast_store),
    .store_rsp_valid_o(fast_valid),
    .store_rsp_ready_i(fast_ready),
    .store_rsp_token_o(fast_token),
    .store_rsp_error_o(fast_error),
    .req_valid_i(req_valid),
    .req_ready_o(req_ready),
    .req_token_i(req_token),
    .req_addr_i(req_addr),
    .req_op_i(req_op),
    .req_cache_i(req_cache),
    .req_size_i(req_size),
    .req_data_i(req_data),
    .req_expected_i(req_expected),
    .req_strb_i(req_strb),
    .req_amo_i(req_amo),
    .rsp_valid_o(rsp_valid),
    .rsp_ready_i(rsp_ready),
    .rsp_token_o(rsp_token),
    .rsp_data_o(rsp_data),
    .rsp_error_o(rsp_error),
    .rsp_compare_o(rsp_compare),
    .read_valid_o(rv),
    .read_ready_i(rr),
    .read_addr_o(ra),
    .read_len_o(rl),
    .read_size_o(rs),
    .beat_valid_i(bv),
    .beat_ready_o(br),
    .beat_data_i(bd),
    .beat_resp_i(be),
    .beat_last_i(bl),
    .write_valid_o(wv),
    .write_ready_i(wr),
    .write_addr_o(wa),
    .write_size_o(wz),
    .write_data_valid_o(wdv),
    .write_data_ready_i(wdready),
    .write_data_o(wd),
    .write_strb_o(ws),
    .write_rsp_valid_i(bvalid),
    .write_rsp_ready_o(bready),
    .write_resp_i(bresp),
    .idle_o(idle),
    .mutation_o(mutation),
    .mutation_word_o(mutationword)
  );

  reg [63:0] memory[0:2047];
  reg [63:0] live=0, done=0, expected_error=0, expected_fast=0, expected_store=0;
  reg [63:0] expected[0:63];
  reg [63:0] expect_address[0:63], expect_write_data[0:63];
  reg [7:0] expect_strb[0:63];
  reg [2:0] expect_size[0:63];
  reg [63:0] bdone=0, expected_lr=0;
  reg reference_reserved=0;
  reg [60:0] reference_word=0;
  integer reservation_checks=0;
  integer born[0:63], cmd_edge[0:63], data_edge[0:63], b_edge[0:63], done_edge[0:63];
  integer cycles=0, accepts=0, returns=0, commands=0, writes=0, bs=0, mutations=0;
  integer scenarios=0, early_fast=0, simultaneous_b=0, detach_count=0, held_checks=0;
  integer min_cmd=999, max_cmd=0, min_b=999, max_b=0;
  integer outcomes[0:3];
  reg response_error=0;
  integer response_delay=0;
  reg reading=0;
  integer readindex=0, readleft=0;
  reg awseen=0, wseen=0;
  reg [63:0] busaddr=0, busdata=0;
  reg [7:0] busstrb=0;
  integer bustoken=0, pending_token=0, wait_b=0;
  reg bus_error=0;
  reg [1:0] held_rsp=0;
  reg [71:0] held_payload[0:1];
  reg held_fast=0;
  reg [6:0] held_fast_payload=0;
  reg aw_held=0, w_held=0;
  reg [66:0] aw_payload;
  reg [71:0] w_payload;
  integer i,j,t,b,ix;
  always @(negedge clk) if(!rst) begin
    if(!bv || br)begin
      bv=reading;
      bd=memory[readindex];
      bl=readleft==1;
      be=0;
    end
  end

  // The model accepts command and data independently, then registers B.
  // DELAY=0 returns the earliest legal B exactly one edge after both accepts.
  // Every memory byte is committed only on successful actual B acceptance.
  always @(posedge clk) if(!rst)begin
    cycles=cycles+1;
    for(integer lane=0;lane<2;lane=lane+1)begin
      if(req_valid[lane]&&req_ready[lane])begin
        t=int'(req_token[lane*6+:6]); ix=int'((req_addr[lane*64+:64]>>3)&2047);
        if(live[t])$fatal(1,"token reused before completion");
        live[t]=1;done[t]=0;bdone[t]=0;born[t]=cycles;
        expected_error[t]=response_error && req_op[lane*2+:2]!=0;
        expected_fast[t]=fast_store[lane];
        expected_store[t]=req_op[lane*2+:2]!=0;
        expected[t]=req_op[lane*2+:2]==1 ? 0 : memory[ix];
        expected_lr[t]=req_op[lane*2+:2]==3 && req_amo[lane*5+:5]==2;
        if(expected_lr[t])expected_store[t]=0;
        if(req_op[lane*2+:2]==3 && req_amo[lane*5+:5]==3)begin
          expected[t]=reference_reserved && reference_word==req_addr[lane*64+3+:61] ? 0 : 1;
          expected_store[t]=expected[t]==0;
          reference_reserved=0;
        end else if(req_op[lane*2+:2]==1 && reference_word==req_addr[lane*64+3+:61])
          reference_reserved=0;
        expect_address[t]=req_addr[lane*64+:64];
        expect_write_data[t]=req_data[lane*64+:64];
        if(req_op[lane*2+:2]==3 && req_amo[lane*5+:5]==0)
          expect_write_data[t]=memory[ix]+req_data[lane*64+:64];
        expect_strb[t]=req_strb[lane*8+:8];
        expect_size[t]=req_size[lane*3+:3];
        accepts=accepts+1;
        if(req_op[lane*2+:2]!=0)pending_token=t;
        if((!req_cache[lane]||req_op[lane*2+:2]!=1) && (wv||wdv))
          $fatal(1,"atomic/uncached request escaped the registered preparation path");
      end
      if(held_rsp[lane] && (!rsp_valid[lane] ||
          {rsp_token[lane*6+:6],rsp_data[lane*64+:64],rsp_error[lane],rsp_compare[lane]}!==held_payload[lane]))
        $fatal(1,"held normal response changed");
      held_rsp[lane]=rsp_valid[lane]&&!rsp_ready[lane];
      held_payload[lane]={rsp_token[lane*6+:6],rsp_data[lane*64+:64],rsp_error[lane],rsp_compare[lane]};
      if(held_rsp[lane])held_checks=held_checks+1;
    end
    if(aw_held && (!wv||{wa,wz}!==aw_payload))$fatal(1,"command changed while stalled");
    if(w_held && (!wdv||{wd,ws}!==w_payload))$fatal(1,"data changed while stalled");
    aw_held=wv&&!wr;aw_payload={wa,wz};
    w_held=wdv&&!wdready;w_payload={wd,ws};
    if(wv&&wr)begin
      if(awseen||bvalid)$fatal(1,"duplicate command");
      if(wa!==expect_address[pending_token]||wz!==expect_size[pending_token])
        $fatal(1,"command not from accepted packet");
      awseen=1;busaddr=wa;bustoken=pending_token;bus_error=response_error;
      cmd_edge[bustoken]=cycles;commands=commands+1;
    end
    if(wdv&&wdready)begin
      if(wseen||bvalid)$fatal(1,"duplicate data");
      if(wd!==expect_write_data[pending_token]||ws!==expect_strb[pending_token])
        $fatal(1,"write data/mask not from accepted packet");
      wseen=1;busdata=wd;busstrb=ws;data_edge[pending_token]=cycles;writes=writes+1;
    end
    if(awseen&&wseen&&!bvalid)begin
      if(wait_b==response_delay)begin bvalid<=1;bresp<=bus_error ? 2 : 0;end
      else wait_b=wait_b+1;
    end
    if(dut.detach_store_w)begin
      detach_count=detach_count+1;
      if(bvalid&&bready)$fatal(1,"consumed B recreated owner");
    end
    if(mutation)begin
      if(!bvalid||!bready||bresp!=0||mutationword!==busaddr[63:3])
        $fatal(1,"mutation lost B owner");
      mutations=mutations+1;
    end
    if(bvalid&&bready)begin
      if(!awseen||!wseen)$fatal(1,"B without both accepted channels");
      if(!live[bustoken]||bdone[bustoken])$fatal(1,"B owner completed twice");
      bdone[bustoken]=1;b_edge[bustoken]=cycles;bs=bs+1;
      if(!bresp)for(integer byteix=0;byteix<8;byteix=byteix+1)
        if(busstrb[byteix])memory[int'((busaddr>>3)&2047)][byteix*8+:8]=busdata[byteix*8+:8];
      if(dut.state_q==5)simultaneous_b=simultaneous_b+1;
      awseen=0;wseen=0;wait_b=0;bvalid<=0;
    end
    if(held_fast&&(!fast_valid||{fast_token,fast_error}!==held_fast_payload))
      $fatal(1,"held fast response changed owner");
    held_fast=fast_valid&&!fast_ready;held_fast_payload={fast_token,fast_error};
    if(held_fast)held_checks=held_checks+1;
    if(fast_valid&&fast_ready)begin
      t=int'(fast_token);
      if(!live[t]||!expected_fast[t]||!bdone[t]||fast_error!==expected_error[t])
        $fatal(1,"fast response owner/B/error");
      live[t]=0;done[t]=1;done_edge[t]=cycles;returns=returns+1;
    end
    for(integer lane=0;lane<2;lane=lane+1)if(rsp_valid[lane]&&rsp_ready[lane])begin
      t=int'(rsp_token[lane*6+:6]);
      if(!live[t]||expected_fast[t]||rsp_error[lane]!==expected_error[t]||
          (!rsp_error[lane]&&rsp_data[lane*64+:64]!==expected[t])||rsp_compare[lane])
        $fatal(1,"response token=%0d value=%h expected=%h error=%b/%b",t,
          rsp_data[lane*64+:64],expected[t],rsp_error[lane],expected_error[t]);
      if(expected_store[t]&&!bdone[t])$fatal(1,"store completed before B");
      if(expected_lr[t]&&!rsp_error[lane])begin
        reference_reserved=1;reference_word=expect_address[t][63:3];
      end
      live[t]=0;done[t]=1;done_edge[t]=cycles;returns=returns+1;
    end
    if(rv&&rr)begin
      if(reading)$fatal(1,"read owner duplicated");
      reading=1;readindex=int'((ra>>3)&2047);readleft=int'(rl)+1;
    end
    if(bv&&br)begin
      readindex=readindex+1;readleft=readleft-1;
      if(readleft==0)reading=0;
    end
  end

  task offer;
    input [63:0] a,d;
    input [1:0] op;
    input cached,fast;
    input [7:0] mask;
    input [4:0] amo;
    input [5:0] tok;
    begin
      @(negedge clk);
      req_valid=1;req_addr={64'b0,a};req_data={64'b0,d};req_op={2'b0,op};
      req_cache={1'b1,cached};fast_store={1'b0,fast};req_strb={8'hff,mask};
      req_amo={5'b0,amo};req_token={6'b0,tok};req_size={3'd3,3'd3};
      do @(posedge clk);while(!req_ready[0]);
      #1;
      @(negedge clk);req_valid=0;fast_store=0;
    end
  endtask
  task drain;
    integer timeout_count;
    begin
      timeout_count=0;
      while(live!=0||!idle)begin
        @(negedge clk);timeout_count=timeout_count+1;
        if(timeout_count>100)$fatal(1,"drain timeout live=%h state=%d",live,dut.state_q);
      end
    end
  endtask
  task load_check;
    input [63:0] a;
    begin offer(a,0,0,1,0,8'hff,0,6'd1);drain();end
  endtask
  task store_case;
    input [1:0] ports;
    input fast,hot,bank;
    input integer policy;
    input err,inv;
    reg [63:0] a,d;
    integer gap;
    begin
      // All hot/miss choices use different tags and sets between successive
      // cases; the independent memory array is also the load-result oracle.
      a=64'h1000+64'((scenarios%16)*64)+64'(bank)*8;
      if(hot)load_check(a);
      else begin @(negedge clk);invalidate=1;@(negedge clk);invalidate=0;end
      d=64'h5acd10328796b4ef ^ (64'(scenarios)*64'h1020304050607);
      @(negedge clk);wr=ports[1];wdready=ports[0];
      fast_ready=policy!=2;rsp_ready=policy==2 ? 0 : 3;
      response_delay=policy==1 ? 5 : 0;response_error=err;
      offer(a,d,1,1,fast,8'h69 ^ 8'(scenarios),0,6'd2);
      scenarios=scenarios+1;outcomes[ports]=outcomes[ports]+1;
      if(FLOW)begin
        if({dut.command_sent_q,dut.data_sent_q}!==ports)
          $fatal(1,"initial independent sent flags %b expected %b",
            {dut.command_sent_q,dut.data_sent_q},ports);
        if(dut.state_q!==(ports==3 ? 4'd5:4'd4))
          $fatal(1,"initial state does not encode the four outcomes");
        if(dut.store_active_q)$fatal(1,"detached before registered cache lookup");
      end
      if(inv)invalidate=1;
      repeat(2)@(negedge clk);
      invalidate=0;
      wr=1;wdready=1;
      if(policy==2)begin repeat(5)@(negedge clk);fast_ready=1;rsp_ready=3;end
      drain();
      if(cmd_edge[2]<born[2]||data_edge[2]<born[2])$fatal(1,"write before actual cache accept");
      if(ports==3)begin
        gap=cmd_edge[2]-born[2];
        if(gap!=(FLOW?0:1)||data_edge[2]-born[2]!=gap)$fatal(1,"cmd/data edge A/B mismatch");
        if(gap<min_cmd)min_cmd=gap;if(gap>max_cmd)max_cmd=gap;
        if(policy==0 && fast)begin
          gap=b_edge[2]-born[2];
          if(gap!=(FLOW?1:2)||done_edge[2]!=b_edge[2])$fatal(1,"earliest precise B edge");
          early_fast=early_fast+1;if(gap<min_b)min_b=gap;if(gap>max_b)max_b=gap;
        end
      end
      response_error=0;response_delay=0;fast_ready=1;rsp_ready=3;
      load_check(a);
    end
  endtask
  initial begin
    for(i=0;i<2048;i=i+1)memory[i]=64'h0918273645546372 ^ (64'(i)*64'h1030507090b0d0f);
    for(i=0;i<4;i=i+1)outcomes[i]=0;
    repeat(3)@(negedge clk);rst=0;
    for(integer p=0;p<4;p=p+1)
      for(integer f=0;f<2;f=f+1)
        for(integer hot=0;hot<2;hot=hot+1)
          for(integer bank=0;bank<2;bank=bank+1)
            for(integer policy=0;policy<3;policy=policy+1)
              store_case(2'(p),1'(f),1'(hot),1'(bank),policy,0,0);
    // Error and invalidate at earliest B or during later owner migration.
    for(integer f=0;f<2;f=f+1)
      for(integer bank=0;bank<2;bank=bank+1)begin
        store_case(3,1'(f),1,1'(bank),0,1,0);
        store_case(3,1'(f),1,1'(bank),0,0,1);
        store_case(3,1'(f),1,1'(bank),1,0,1);
        store_case(1,1'(f),1,1'(bank),1,1,1);
      end
    // Noncache ordinary store and arithmetic AMO never use input forwarding.
    offer(64'h3008,64'h903012456789abcd,1,0,0,8'h53,0,6'd3);drain();load_check(64'h3008);
    offer(64'h3080,64'h31,3,1,0,8'hff,0,6'd4);drain();load_check(64'h3080);
    // Reservation behavior is checked through LR/store/SC responses, including
    // an unsuccessful store B. Same-word stores invalidate; other words retain.
    for(integer f=0;f<2;f=f+1)
      for(integer other_word=0;other_word<2;other_word=other_word+1)begin
        offer(64'h3180,0,3,1,0,8'hff,2,6'd5);drain();
        response_error=1;
        offer(64'h3180+64'(other_word)*8,64'habc,1,1,1'(f),8'hff,0,6'd6);drain();
        response_error=0;
        offer(64'h3180,64'h563412,3,1,0,8'hff,3,6'd7);drain();
        if(expected[7]!==64'(1-other_word))$fatal(1,"reservation oracle did not distinguish words");
        load_check(64'h3180);reservation_checks=reservation_checks+1;
      end
    // Earliest B can be held while the ready lookup descriptor migrates to
    // storeQ. Reuse the same bank for another set before releasing that B.
    if(SPLIT)begin
      load_check(64'h3e00);load_check(64'h3c40);
      fast_ready=0;
      offer(64'h3e00,64'habc123fed6540987,1,1,1,8'h36,0,6'd8);
      repeat(2)@(negedge clk);
      if((!bvalid&&!dut.fast_b_valid_q)||!fast_valid||!dut.store_active_q)$fatal(1,"held earliest B did not migrate");
      offer(64'h3c40,0,0,1,0,8'hff,0,6'd9);
      while(!done[9])@(negedge clk);
      if(done[8]||!fast_valid||fast_token!=8)$fatal(1,"bank reuse lost held B");
      @(negedge clk);fast_ready=1;drain();load_check(64'h3e00);
    end
    // No upstream acceptance or downstream side effect during invalidation.
    @(negedge clk);invalidate=1;req_valid=1;req_op=1;req_cache=3;req_addr=64'h3200;
    repeat(3)begin @(posedge clk);if(req_ready[0]||wv||wdv)$fatal(1,"invalidate admitted store");end
    @(negedge clk);req_valid=0;invalidate=0;
    if(accepts!=returns||commands!=writes||commands!=bs||live!=0)
      $fatal(1,"transaction conservation");
    if(early_fast<4||held_checks==0||(FLOW&&simultaneous_b==0))$fatal(1,"missing coverage");
    for(i=0;i<4;i=i+1)if(outcomes[i]<16)$fatal(1,"missing channel combination");
    $display("[PASS] tb_r64_dcache_command_flow flow=%0d split=%0d accepted=%0d returned=%0d cmd=%0d data=%0d B=%0d mutation=%0d cases=%0d early=%0d cmd_gap=%0d..%0d B_gap=%0d..%0d BRESP_B=%0d detach=%0d held=%0d LRSC=%0d outcomes=%0d,%0d,%0d,%0d",
      FLOW,SPLIT,accepts,returns,commands,writes,bs,mutations,scenarios,early_fast,min_cmd,max_cmd,min_b,max_b,
      simultaneous_b,detach_count,held_checks,reservation_checks,outcomes[0],outcomes[1],outcomes[2],outcomes[3]);
    $finish;
  end
  initial begin #2000000;$fatal(1,"global timeout");end
endmodule
