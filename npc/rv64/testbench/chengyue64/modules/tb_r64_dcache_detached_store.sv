`timescale 1ns / 1ps
module tb_r64_dcache_detached_store;
  parameter DETACH=1;
  parameter FLOW=1;
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
  wire rv, rr, br;
  wire [63:0] ra;
  wire [7:0] rl;
  wire [2:0] rs;
  reg bv = 0;
  reg [63:0] bd = 0;
  reg [1:0] be = 0;
  reg bl = 0;
  wire wv, wdv, wr, wdready, bready;
  wire [63:0] wa, wd;
  wire [7:0] ws;
  wire [2:0] wz;
  reg write_pause = 0, aw_block=0, w_block=0;
  reg [1:0] response_hold = 0, fast_store = 0;
  wire fast_valid, fast_error;
  wire [5:0] fast_token;
  reg fast_ready = 1;
  reg bvalid = 0;
  // Delay external B presentation when aligning B with a selected read edge.
  // Consumer backpressure alone no longer delays a real B accepted by the
  // elastic terminal. The separate +fifo-held-b case exercises that holder.
  reg align_b_delivery=0;
  wire bus_bvalid=bvalid && (!align_b_delivery || fast_ready);
  reg [1:0] bresp = 0;
  wire idle, mutation;
  wire [60:0] mutationword;
  R64Dcache #(
    .SET_W(6),
    .SPLIT_STORE_OWNER(1), .FAST_STORE_DETACH(DETACH), .HIT_RESPONSE_EMPTY_FLOW(FLOW)
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
    .write_rsp_valid_i(bus_bvalid),
    .write_rsp_ready_o(bready),
    .write_resp_i(bresp),
    .idle_o(idle),
    .mutation_o(mutation),
    .mutation_word_o(mutationword)
  );
  reg [63:0] memory  [0:2047];
  reg [63:0] expected[  0:63];
  reg [63:0] live = 0, expect_error = 0, expect_compare = 0;
  reg force_read_error = 0, force_write_error = 0, random_stall = 1;
  reg [31:0] rng = 32'h39b4e921;
  reg reading = 0, readerror = 0;
  reg read_pause = 0;
  reg [63:0] done = 0;
  integer readindex = 0, readleft = 0, readbeat = 0;
  reg awseen = 0, wseen = 0, writeerror = 0;
  integer writeindex = 0, bdelay = 0;
  reg [63:0] writedata;
  reg [ 7:0] writestrb;
  integer accepts = 0, returns = 0, readcmds = 0, writecmds = 0, dual = 0, cycles = 0, stalls = 0;
  integer k, t, n, j, before_reads, operation;
  reg [4:0] atomic_op[0:8];
  reg [63:0] atomic_answer[0:8];
  reg [31:0] word_answer[0:8];
  reg [1:0] admitted;
  assign rr = !reading && (!random_stall || rng[0]);
  assign wr = !aw_block && !awseen && !bvalid && (!random_stall || rng[1]);
  assign wdready = !w_block && !wseen && !bvalid && (!random_stall || rng[2]);
  always @(negedge clk) begin
    if (!rst) begin
      rng = {rng[30:0], rng[31] ^ rng[21] ^ rng[1] ^ rng[0]};
      rsp_ready = (random_stall ? {rng[3] | rng[4], rng[5] | rng[6]} : 2'b11) & ~response_hold;
      if (!bv || br) begin
        bv = reading && !read_pause && (!random_stall || rng[7]);
        bd = memory[readindex];
        be = readerror && readbeat == 1 ? 2'b10 : 0;
        // Single beat errors must also be observable.
        if (readerror && readleft == 1) be = 2;
        bl = readleft == 1;
      end
    end
  end
  always @(posedge clk)
    if (!rst) begin
      cycles = cycles + 1;
      if (rv && rr) begin
        reading   = 1;
        readindex = int'((ra >> 3) & 2047);
        readleft  = rl + 1;
        readbeat  = 0;
        readerror = force_read_error;
        readcmds  = readcmds + 1;
      end
      if (bv && br) begin
        readindex = readindex + 1;
        readleft  = readleft - 1;
        readbeat  = readbeat + 1;
        if (readleft == 0) reading = 0;
      end
      if (wv && wr) begin
        awseen = 1;
        writeindex = int'((wa >> 3) & 2047);
        writeerror = force_write_error;
        writecmds = writecmds + 1;
      end
      if (wdv && wdready) begin
        wseen = 1;
        writedata = wd;
        writestrb = ws;
      end
      if (awseen && wseen && !bvalid && !write_pause) begin
        bdelay = bdelay + 1;
        if (bdelay == 4) begin
          bvalid <= 1;
          bresp  <= writeerror ? 2 : 0;
          if (!writeerror)
            for (j = 0; j < 8; j = j + 1)
            if (writestrb[j]) memory[writeindex][8*j+:8] = writedata[8*j+:8];
        end
      end
      if (bus_bvalid && bready) begin
        bvalid <= 0;
        awseen = 0;
        wseen  = 0;
        bdelay = 0;
      end
      if (fast_valid && fast_ready) begin
        t = fast_token;
        if (!live[t] || fast_error !== expect_error[t]) $fatal(1, "fast store owner/error");
        live[t] = 0;
        done[t] = 1;
        returns = returns + 1;
      end
      if ((req_valid & req_ready) == 3) dual = dual + 1;
      if ((req_valid & ~req_ready) != 0) stalls = stalls + 1;
      for (k = 0; k < 2; k = k + 1) begin
        if (rsp_valid[k] && rsp_ready[k]) begin
          t = rsp_token[k*6+:6];
          if (!live[t]) $fatal(1, "response without token");
          if (rsp_error[k] !== expect_error[t] || rsp_compare[k] !== expect_compare[t] ||
              (!rsp_error[k] && rsp_data[k*64+:64] !== expected[t]))
            $fatal(
                1,
                "response token %0d data %h expected %h error %b/%b compare %b/%b",
                t,
                rsp_data[k*64+:64],
                expected[t],
                rsp_error[k],
                expect_error[t],
                rsp_compare[k],
                expect_compare[t]
            );
          live[t] = 0;
          done[t] = 1;
          returns = returns + 1;
        end
        if (req_valid[k] && req_ready[k]) begin
          t = req_token[k*6+:6];
          if (live[t]) $fatal(1, "token reused");
          live[t] = 1;
          done[t] = 0;
          accepts = accepts + 1;
        end
      end
    end
  task command;
    input [63:0] addr;
    input [1:0] op;
    input cache;
    input [63:0] data, cmp, answer;
    input [7:0] strb;
    input [4:0] amo;
    input [2:0] size;
    input error, compare;
    begin
      @(negedge clk);
      req_valid = 1;
      req_addr = {64'b0, addr};
      req_op = {2'b0, op};
      req_cache = {1'b1, cache};
      req_data = {64'b0, data};
      req_expected = {64'b0, cmp};
      req_strb = {8'hff, strb};
      req_amo = {5'b0, amo};
      req_size = {3'd3, size};
      req_token = 0;
      expected[0] = answer;
      expect_error[0] = error;
      expect_compare[0] = compare;
      do @(posedge clk); while (!req_ready[0]);
      @(negedge clk);
      req_valid = 0;
      while (live != 0) @(negedge clk);
    end
  endtask


  integer born[0:63], returned[0:63], bcycle, wait_cycles;
  integer mutation_checks=0, held_checks=0, simultaneous_hit_b=0, simultaneous_take_b=0;
  integer blocked_read_beats=0, parallel_bank_writes=0, same_bank_misses=0;
  reg [63:0] write_address=0;
  reg [1:0] held_valid=0;
  reg [71:0] held_payload[0:1];
  reg fast_b_pending=0, fast_b_seen=0;
  reg [5:0] fast_b_owner=0;
  reg held_fast=0;
  reg [6:0] held_fast_payload=0;
  always @(posedge clk) if(!rst) begin
    if(wv&&wr)write_address=wa;
    if(mutation)begin
      if(!bvalid||!bready||bresp!=0||mutationword!==write_address[63:3])
        $fatal(1,"mutation did not preserve detached store address");
      mutation_checks=mutation_checks+1;
    end
    if(req_valid[0]&&req_ready[0]&&fast_store[0])begin
      if(fast_b_pending)$fatal(1,"second fast store reused pending B owner");
      fast_b_pending=1;fast_b_seen=0;fast_b_owner=req_token[5:0];
    end
    if(bus_bvalid&&bready&&fast_b_pending)begin
      if(fast_b_seen)$fatal(1,"fast store accepted B twice");
      fast_b_seen=1;
    end
    if(fast_valid&&fast_ready)begin
      if(!fast_b_pending||!fast_b_seen||fast_token!==fast_b_owner)
        $fatal(1,"store completed without its previously accepted real B");
      fast_b_pending=0;fast_b_seen=0;
      bcycle=int'($time/10);
    end
    if(held_fast && (!fast_valid || {fast_token,fast_error}!==held_fast_payload))
      $fatal(1,"backpressured detached B changed token/error");
    held_fast=fast_valid&&!fast_ready;
    held_fast_payload={fast_token,fast_error};
    if(bus_bvalid&&bready&&(|dut.hit_response_take_w))simultaneous_hit_b=simultaneous_hit_b+1;
    if(bus_bvalid&&bready&&(|dut.take_w))simultaneous_take_b=simultaneous_take_b+1;
    if(bv&&dut.fill_port_block_w)begin
      if(br)$fatal(1,"B/refill collision accepted twice");
      blocked_read_beats=blocked_read_beats+1;
    end
    if(dut.fill_write_w&&dut.store_write_w)parallel_bank_writes=parallel_bank_writes+1;
    for(integer z=0;z<2;z=z+1)begin
      if(held_valid[z])begin
        if(!rsp_valid[z] || {rsp_token[z*6+:6],rsp_data[z*64+:64],rsp_error[z],rsp_compare[z]}
            !==held_payload[z])$fatal(1,"held read changed across B or invalidate");
        held_checks=held_checks+1;
      end
      held_valid[z]=rsp_valid[z]&&!rsp_ready[z];
      held_payload[z]={rsp_token[z*6+:6],rsp_data[z*64+:64],rsp_error[z],rsp_compare[z]};
      if(req_valid[z]&&req_ready[z])born[req_token[z*6+:6]]=int'($time/10);
      if(rsp_valid[z]&&rsp_ready[z])returned[rsp_token[z*6+:6]]=int'($time/10);
    end
  end
  function automatic integer mi(input [63:0] a);
    mi=int'((a>>3)&2047);
  endfunction
  task automatic launch(input integer tok,input [63:0] a,input [1:0] op,
      input fast,input [63:0] data,input [7:0] mask,input error);
    begin
      @(negedge clk);#1;
      req_valid=1;req_addr={64'd0,a};req_op={2'd0,op};req_cache=3;
      req_size={3'd3,3'd3};req_token=12'(tok);req_data={64'd0,data};
      req_strb={8'hff,mask};req_amo=0;fast_store=fast?1:0;
      expected[tok]=op==0?memory[mi(a)]:0;
      expect_error[tok]=error;expect_compare[tok]=0;
      do @(posedge clk);while(!req_ready[0]);
      @(negedge clk);#1;req_valid=0;fast_store=0;
    end
  endtask
  task automatic drain;
    begin
      wait_cycles=0;
      while(live!=0&&wait_cycles<120)begin @(negedge clk);#1;wait_cycles=wait_cycles+1;end
      if(live!=0)$fatal(1,"owners did not drain %h",live);
    end
  endtask
  task automatic warm(input [63:0] a);
    begin command(a,0,1,0,0,memory[mi(a)],255,0,3,0,0);end
  endtask
  task automatic begin_store(input [63:0] a,input error);
    begin
      @(negedge clk);#1;write_pause=1;force_write_error=error;fast_ready=1;
      launch(10,a,1,1,64'hf1e2d3c4b5a69788,8'h3c,error);
      while(!dut.store_active_q)begin @(negedge clk);#1;end
      if(DETACH && dut.stage_valid_q[a[3]])
        $fatal(1,"accepted command plus W did not release fast store bank");
      if(done[10])$fatal(1,"store terminal before B");
    end
  endtask
  task automatic release_b;
    begin @(negedge clk);#1;write_pause=0;bdelay=3;end
  endtask
  task automatic pause_b_valid;
    begin
      align_b_delivery=1;fast_ready=0;release_b();
      while(!bvalid)begin @(negedge clk);#1;end
    end
  endtask
  task automatic blocked_candidate(input [63:0] a);
    begin
      @(negedge clk);#1;
      req_addr={64'd0,a};req_op=0;req_valid=1;req_cache=3;fast_store=0;
      #1;if(req_ready[0])$fatal(1,"owner exclusion admitted address %h",a);
      @(negedge clk);#1;req_valid=0;
    end
  endtask

  integer bank,beat,mode,offer_cycle,latency,slow_cmds,measurements=0;
  reg [63:0] sa,ha,ma,third;
  initial begin
    random_stall=0;
    for(n=0;n<2048;n=n+1)memory[n]=64'h3456000000000000+64'(n);
    repeat(4)@(negedge clk);#1;rst=0;
    if($test$plusargs("fifo-held-b"))begin
      // Three independent owners share bank0: a held fast-store terminal,
      // an other-bank miss refilling alternating banks, and continuous hot
      // reads. Refill can consume the credit that first offered B used.
      warm(64'h100);warm(64'h200);begin_store(64'h100,0);
      read_pause=1;launch(11,64'h308,0,0,0,255,0);
      while(dut.state_q!=2)begin @(negedge clk);#1;end
      @(negedge clk);#1;
      read_pause=0;write_pause=0;bdelay=3;fast_ready=0;
      for(integer tick=0;tick<40;tick=tick+1)begin
        req_valid=1;req_addr=64'h200;req_op=0;req_cache=3;
        req_token=12'(16+(tick%8));fast_store=0;
        expected[16+(tick%8)]=memory[mi(64'h200)];
        expect_error[16+(tick%8)]=0;expect_compare[16+(tick%8)]=0;
        @(posedge clk);
        @(negedge clk);#1;
      end
      req_valid=0;
      if(!fast_valid||fast_token!=10||done[10]||!done[11])
        $fatal(1,"held FIFO B terminal or independent miss lost");
      if(!fast_b_seen||!dut.store_active_q)
        $fatal(1,"real B receipt did not retain its unconsumed terminal owner");
      fast_ready=1;drain();warm(64'h100);
      if(mutation_checks!=1||fast_b_pending||accepts!=returns)
        $fatal(1,"held B duplicated side effect or terminal");
      $display("[PASS] tb_r64_dcache_detached_store fifo_held_b accepted=%0d returned=%0d mutation=%0d",
               accepts,returns,mutation_checks);
      $finish;
    end
    // The real Dhrystone bank/set pair: destination set61 versus source set15.
    // Both A/B runs hold B for exactly the same number of clock edges.
    for(bank=0;bank<2;bank=bank+1)begin
      sa=64'h8010ef60+64'(bank*8);ha=64'h800023c0+64'(bank*8);
      warm(sa);warm(ha);begin_store(sa,0);
      offer_cycle=int'($time/10)+1;done[11]=0;
      fork
        launch(11,ha,0,0,0,255,0);
        begin
          repeat(8)@(negedge clk);#1;
          if(DETACH && !done[11])$fatal(1,"same bank hit waited for delayed B");
          if(!DETACH && done[11])$fatal(1,"baseline unexpectedly released store bank");
          release_b();
        end
      join
      drain();latency=returned[11]-offer_cycle;
      if(DETACH && returned[11]>=bcycle)$fatal(1,"load did not return before precise B");
      if(!DETACH && born[11]<=bcycle)$fatal(1,"baseline accepted before store B");
      $display("DETACHED_STORE_LATENCY enabled=%0d flow=%0d bank=%0d offer_to_return=%0d accept_to_return=%0d load=%0d B=%0d",
          DETACH,FLOW,bank,latency,returned[11]-born[11],returned[11],bcycle);
      measurements=measurements+1;warm(sa);
    end
    if(DETACH)begin
      // Transfer the complete descriptor only after both independent actual
      // command and W handshakes; either one may be arbitrarily delayed.
      for(mode=0;mode<2;mode=mode+1)begin
        sa=64'h8010ef60;ha=64'h800023c0;
        warm(sa);warm(ha);
        write_pause=1;aw_block=mode==0;w_block=mode==1;
        launch(10,sa,1,1,64'h193a4b5c6d7e8f01,8'ha5,0);
        repeat(3)@(negedge clk);
        #1;if(dut.store_active_q||!dut.stage_valid_q[0]||
            awseen!==!aw_block||wseen!==!w_block)
          $fatal(1,"store descriptor transferred before both command and W");
        aw_block=0;w_block=0;
        while(!dut.store_active_q)begin @(negedge clk);#1;end
        launch(11,ha,0,0,0,255,0);
        release_b();drain();warm(sa);
      end
      // A non-fast ordinary store still owns the bank/output path until B.
      sa=64'h8010ef60;ha=64'h800023c0;
      warm(sa);warm(ha);write_pause=1;
      launch(10,sa,1,0,64'h1020304050607080,8'hff,0);
      while(!dut.store_active_q)begin @(negedge clk);#1;end
      if(!dut.stage_valid_q[0])$fatal(1,"nonfast store released shared output owner");
      done[11]=0;
      fork
        launch(11,ha,0,0,0,255,0);
        begin
          repeat(6)@(negedge clk);#1;
          if(done[11])$fatal(1,"nonfast store let same-bank load reuse stage");
          release_b();
        end
      join
      drain();warm(sa);
      // B concurrent with the same-bank lookup hit, an incoming load, or a
      // held terminal must preserve the read token and the old store identity.
      for(bank=0;bank<2;bank=bank+1)
      for(mode=0;mode<5;mode=mode+1)begin
        sa=64'h8010ef60+64'(bank*8);ha=64'h800023c0+64'(bank*8);
        warm(sa);warm(ha);begin_store(sa,mode==3);pause_b_valid();
        if(mode==2)response_hold=bank?2:1;
        if(mode==1)begin
          // Actual new request take and B consume at the same edge.
          @(negedge clk);#1;
          req_valid=1;req_addr={64'd0,ha};req_op=0;req_cache=3;req_token=11;
          expected[11]=memory[mi(ha)];expect_error[11]=0;expect_compare[11]=0;
          fast_ready=1;
          @(posedge clk);
          if(!req_ready[0]||!bready)$fatal(1,"B plus new take fixture failed");
          @(negedge clk);#1;req_valid=0;
        end else begin
          launch(11,ha,0,0,0,255,0);
          // launch returns at the negedge immediately before the hit edge.
          if(mode==4)begin
            invalidate=1;
            @(negedge clk);#1;invalidate=0;
          end
          fast_ready=1;
        end
        if(mode==2)begin
          repeat(4)@(negedge clk);
          #1;if(done[11]||!done[10])$fatal(1,"held load/B ownership fixture failed");
          invalidate=1;
          @(negedge clk);#1;invalidate=0;response_hold=0;
        end
        drain();force_write_error=0;warm(sa);warm(ha);
      end

      // Full same-bank miss/refill while the detached store waits for B.
      // Align B with every R beat, both bank orientations. An independent
      // memory model and full-line readback catch overwritten data/masks.
      for(bank=0;bank<2;bank=bank+1)
      for(beat=0;beat<11;beat=beat+1)begin
        @(negedge clk);#1;invalidate=1;
        @(negedge clk);#1;invalidate=0;
        sa=64'h8010ef60+64'(bank*8);ma=64'h80002800+64'(bank*8);
        warm(sa);begin_store(sa,beat==8);pause_b_valid();
        force_read_error=beat==9;
        read_pause=1;slow_cmds=readcmds;
        launch(11,ma,0,0,0,255,beat==9);
        while(dut.state_q!=2)begin @(negedge clk);#1;end
        if(!dut.store_active_q||readcmds!=slow_cmds+1)
          $fatal(1,"same bank miss did not start with detached B owner");
        same_bank_misses=same_bank_misses+1;
        if(beat==10)begin
          @(negedge clk);#1;invalidate=1;
          @(negedge clk);#1;invalidate=0;
        end
        read_pause=0;
        while(!(bv&&readbeat==(beat%8)))begin @(negedge clk);#1;end
        fast_ready=1;drain();force_write_error=0;force_read_error=0;warm(sa);
        for(operation=0;operation<8;operation=operation+1)
          warm({ma[63:6],6'd0}+64'(operation*8));
      end

      // The detached store and the slow read impose separate exclusions.
      // Holding R creates time to challenge both owners using a third load.
      for(bank=0;bank<2;bank=bank+1)begin
        @(negedge clk);#1;invalidate=1;
        @(negedge clk);#1;invalidate=0;
        sa=64'h8010ef60+64'(bank*8);ma=64'h80002800+64'(bank*8);
        third=64'h80002c40+64'((1-bank)*8);
        warm(sa);warm(third);begin_store(sa,0);read_pause=1;
        launch(11,ma,0,0,0,255,0);
        while(dut.state_q!=2)begin @(negedge clk);#1;end
        blocked_candidate(ma+16); // Slow owner's bank even at another word.
        blocked_candidate({sa[63:6],6'd0}+64'((1-bank)*8)); // Store set.
        blocked_candidate({ma[63:6],6'd0}+64'((1-bank)*8)); // Slow read set.
        // Both offers target the same input bank. Lane zero is excluded by
        // store set; the accepted lane-one address/token must drive lookup.
        @(negedge clk);#1;
        req_valid=3;req_op=0;req_cache=3;
        req_addr={third,({sa[63:6],6'd0}+64'((1-bank)*8))};
        req_token={6'd12,6'd13};expected[12]=memory[mi(third)];
        expect_error[12]=0;expect_compare[12]=0;
        @(posedge clk);
        if(req_ready!==2)$fatal(1,"dual-owner lane-one candidate not isolated");
        @(negedge clk);#1;req_valid=0;
        repeat(4)@(negedge clk);
        #1;if(!done[12]||done[11]||done[10])
          $fatal(1,"third hit did not respect two independent owners");
        read_pause=0;release_b();drain();warm(sa);warm(ma);
      end
      if(blocked_read_beats<8||parallel_bank_writes<8||same_bank_misses!=22)
        $fatal(1,"refill/B coverage block%0d parallel%0d misses%0d",
          blocked_read_beats,parallel_bank_writes,same_bank_misses);
      if((FLOW && simultaneous_hit_b<2)||simultaneous_take_b<2||held_checks<4)
        $fatal(1,"same-edge/held coverage hit%0d take%0d held%0d",
            simultaneous_hit_b,simultaneous_take_b,held_checks);
    end
    if(live!=0||accepts!=returns||measurements!=2||mutation_checks<2)
      $fatal(1,"detached store transaction conservation");
    $display("[PASS] tb_r64_dcache_detached_store detach=%0d flow=%0d accepted=%0d returned=%0d mutation=%0d B_hit=%0d B_take=%0d collisions=%0d parallel=%0d held=%0d",
        DETACH,FLOW,accepts,returns,mutation_checks,simultaneous_hit_b,
        simultaneous_take_b,blocked_read_beats,parallel_bank_writes,held_checks);
    $finish;
  end
  initial begin #1000000;$fatal(1,"detached store test timeout");end
endmodule
