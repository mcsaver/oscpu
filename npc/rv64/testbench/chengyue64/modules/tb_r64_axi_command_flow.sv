`timescale 1ns / 1ps
module tb_r64_axi_command_flow #(
  parameter B_BYPASS = 1,
  parameter FIRST_W_CAPTURE = 1,
  parameter CMD_EMPTY_FLOW = 1
);
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1;
  reg [1:0] cv = 0, dv = 0, rr = 0;
  wire [1:0] cr, dr, rv;
  reg [127:0] ca = 0, di = 0;
  reg [15:0] cl = 0, st = 0;
  reg [5:0] cs = {2{3'd3}}, cp = 0;
  wire [3:0] rp;
  wire av, wv, wl, br;
  reg ar = 0, wr = 0, bv = 0;
  wire [3:0] ai;
  wire [63:0] aa, wd;
  wire [7:0] an, ws;
  wire [2:0] az, ap;
  wire [1:0] ab;
  reg [3:0] bi = 0;
  reg [1:0] bp = 0;
  wire error;
  R64AxiWrite #(
    .B_BYPASS(B_BYPASS),
    .FIRST_W_CAPTURE(FIRST_W_CAPTURE),
    .CMD_EMPTY_FLOW(CMD_EMPTY_FLOW)
  ) dut (
    clk,
    rst,
    cv,
    cr,
    ca,
    cl,
    cs,
    cp,
    dv,
    dr,
    di,
    st,
    rv,
    rr,
    rp,
    av,
    ar,
    ai,
    aa,
    an,
    az,
    ap,
    ab,
    wv,
    wr,
    wd,
    ws,
    wl,
    bv,
    br,
    bi,
    bp,
    error
  );
  integer launched[0:1], produced[0:1], length[0:1];
  reg [63:0] address[0:1];
  reg active[0:1], awseen[0:1], wseen[0:1], bsent[0:1];
  integer order_id[0:2047], order_len[0:2047];
  reg [63:0] order_addr[0:2047];
  integer tail = 0, awhead = 0, whead = 0, wbeat = 0, total = 0, beats = 0, c, cycle, choice;
  integer direct_count = 0, buffered_count = 0;
  integer first_capture=0, single_capture=0, multi_capture=0;
  reg [7:0] direct_lengths=0;
  integer cmd_cycle[0:1], shortest_first_w=1000, shortest_aw=1000;
  reg monitor = 0;
  integer directed_cases=0, aw_pop_push=0, old_stage_replace=0;
  reg [3:0] ready_combinations=0;
  integer early_w = 0, early_aw = 0, wblocked = 0, bblocked = 0;
  reg [31:0] random_q = 32'h52034caa;
  reg hold_aw = 0, hold_w = 0;
  reg [78:0] held_aw;
  reg [72:0] held_w;
  reg [1:0] hold_rsp = 0;
  reg [1:0] held_rsp[0:1];
  reg negative;
  reg bus_taken_q = 0;
  function [31:0] rng(input [31:0] x);
    rng = {x[30:0], x[31] ^ x[21] ^ x[1] ^ x[0]};
  endfunction
  function [63:0] data_for(input [63:0] addr, input integer beat);
    data_for = addr ^ 64'h1758_cea9_8430_376e ^ {56'b0, beat[7:0]};
  endfunction
  function [7:0] strb_for(input [63:0] addr, input integer beat);
    strb_for = addr[13:6] ^ beat[7:0];
  endfunction
  function [1:0] resp_for(input [63:0] addr);
    resp_for = addr[7:6] == 3 ? 2'b10 : 2'b0;
  endfunction

  always @(posedge clk)
    if (!rst && monitor) begin
      bus_taken_q = bv && br;
      if(dut.aw_push_w && dut.aw_pop_w)aw_pop_push=aw_pop_push+1;
      if(dut.wvalid_q && dut.w_fire_w && dut.direct_data_take_w)
        old_stage_replace=old_stage_replace+1;
      if(dut.awcount_q>2 || dut.wcount_q>2 || dut.bcount_q>2)
        $fatal(1,"queue count overflow");
      if(dut.cmd_fire_w)ready_combinations[{ar,wr}]=1;
      if(dut.direct_data_take_w) begin
        first_capture=first_capture+1;
        direct_lengths[cl[dut.grant_r*8+:8]]=1;
        if(dut.direct_last_w)single_capture=single_capture+1;
        else multi_capture=multi_capture+1;
      end
      if (dut.bdirect_pop_w) direct_count = direct_count + 1;
      if (dut.bpush_w) buffered_count = buffered_count + 1;
      if (hold_aw && (!av || {ai, aa, an, az} !== held_aw)) $fatal(1, "AW changed while blocked");
      if (hold_w && (!wv || {wd, ws, wl} !== held_w)) $fatal(1, "W changed while blocked");
      hold_aw = av && !ar;
      held_aw = {ai, aa, an, az};
      hold_w  = wv && !wr;
      held_w  = {wd, ws, wl};
      for (c = 0; c < 2; c = c + 1) begin
        if (hold_rsp[c] && (!rv[c] || rp[c*2+:2] !== held_rsp[c])) $fatal(1, "client B unstable");
        hold_rsp[c] = rv[c] && !rr[c];
        held_rsp[c] = rp[c*2+:2];
        if (rv[c] && rr[c]) begin
          if (!active[c] || !awseen[c] || !wseen[c] || rp[c*2+:2] !== resp_for(address[c]))
            $fatal(1, "response owner/error client %0d", c);
          active[c] = 0;
          total = total + 1;
        end
        if (cv[c] && cr[c]) begin
          if (active[c]) $fatal(1, "client ID reused before terminal");
          active[c] = 1;
          cmd_cycle[c] = cycle;
          address[c] = ca[c*64+:64];
          length[c] = cl[c*8+:8] + 1;
          produced[c] = 0;
          awseen[c] = 0;
          wseen[c] = 0;
          bsent[c] = 0;
          order_id[tail] = c;
          order_len[tail] = length[c];
          order_addr[tail] = address[c];
          tail = tail + 1;
          launched[c] = launched[c] + 1;
        end
        if (dv[c] && dr[c]) produced[c] = produced[c] + 1;
      end
      if (av && ar) begin
        if (awhead >= tail || ai != order_id[awhead] || aa !== order_addr[awhead] ||
            an != order_len[awhead] - 1 || az != 3 || ap != 0 || ab != 1)
          $fatal(1, "AW descriptor or command order mismatch");
        if(cycle-cmd_cycle[ai]<shortest_aw)shortest_aw=cycle-cmd_cycle[ai];
        awseen[ai] = 1;
        if (!wseen[ai]) early_aw = early_aw + 1;
        awhead = awhead + 1;
      end
      if (wv && wr) begin
        if(wbeat==0 && cycle-cmd_cycle[order_id[whead]]<shortest_first_w)
          shortest_first_w=cycle-cmd_cycle[order_id[whead]];
        if (whead >= tail || wd !== data_for(
                order_addr[whead], wbeat
            ) || ws !== strb_for(
                order_addr[whead], wbeat
            ) || wl != (wbeat == order_len[whead] - 1))
          $fatal(1, "W order/data/last mismatch head=%0d beat=%0d", whead, wbeat);
        beats = beats + 1;
        wbeat = wbeat + 1;
        if (wl) begin
          wseen[order_id[whead]] = 1;
          if (!awseen[order_id[whead]]) early_w = early_w + 1;
          whead = whead + 1;
          wbeat = 0;
        end
      end
      if (bv && br && !negative) bsent[bi] = 1;
      if (wv && !wr) wblocked = wblocked + 1;
      if (bv && !br) bblocked = bblocked + 1;
    end

  task reset_direct;
    begin
      @(negedge clk);
      rst=1;cv=0;dv=0;rr=0;ar=0;wr=0;bv=0;
      repeat(3)@(negedge clk);
      rst=0;
    end
  endtask
  task directed(input integer ready_mask);
    integer elapsed, aw_at, w_at;
    reg af,wf;
    begin
      reset_direct();
      ca[63:0]=64'h800001c0;cl=0;cp=6'b000101;
      di[63:0]=64'hfedcba9876543210;st[7:0]=8'ha5;
      cv=1;dv=1;rr=0;ar=ready_mask[1];wr=ready_mask[0];
      #1;
      if(cr!=1 || (FIRST_W_CAPTURE && dr!=1))$fatal(1,"empty admission changed");
      if(av !== (CMD_EMPTY_FLOW!=0) ||
         wv !== (CMD_EMPTY_FLOW!=0 && FIRST_W_CAPTURE!=0))
        $fatal(1,"direct valid depends on downstream ready mask=%0d",ready_mask);
      af=av&&ar;wf=wv&&wr;aw_at=af?0:-1;w_at=wf?0:-1;
      @(posedge clk);
      @(negedge clk);
      cv=0;
      if(FIRST_W_CAPTURE)begin dv=0;di=0;st=0;end
      ca=0;cp=0;
      for(elapsed=1;elapsed<=3;elapsed=elapsed+1)begin
        #1;
        if(!af && (!av || aa!=64'h800001c0 || ap!=5 || an!=0 || ai!=0))
          $fatal(1,"blocked AW did not enter original queue");
        if(!wf && (FIRST_W_CAPTURE || elapsed>=2) &&
           (!wv || wd!=64'hfedcba9876543210 || ws!=8'ha5 || !wl))
          $fatal(1,"blocked W did not enter original stage");
        if(av&&ar)begin if(af)$fatal(1,"duplicate AW");af=1;aw_at=elapsed;end
        if(wv&&wr)begin if(wf)$fatal(1,"duplicate W");wf=1;w_at=elapsed;end
        @(posedge clk);
        @(negedge clk);
        if(!FIRST_W_CAPTURE)begin dv=0;di=0;st=0;end
      end
      ar=1;wr=1;
      for(elapsed=4;elapsed<12 && (!af||!wf);elapsed=elapsed+1)begin
        #1;
        if(av&&ar)begin if(af)$fatal(1,"duplicate AW");af=1;aw_at=elapsed;end
        if(wv&&wr)begin if(wf)$fatal(1,"duplicate W");wf=1;w_at=elapsed;end
        @(posedge clk);@(negedge clk);
      end
      if(!af||!wf)$fatal(1,"directed channel missing");
      // A registered endpoint may return immediately after the last handshake.
      bv=1;bi=0;bp=2;rr=0;
      @(posedge clk);@(negedge clk);bv=0;
      repeat(3)begin
        #1;if(rv!=1||rp[1:0]!=2||error||cr!=0)$fatal(1,"held B owner/error");
        @(posedge clk);@(negedge clk);
      end
      rr=1;
      @(posedge clk);@(negedge clk);
      if(dut.busy_q!=0 || rv!=0)$fatal(1,"terminal did not release once");
      directed_cases=directed_cases+1;
    end
  endtask
  task earliest_response;
    integer elapsed, aw_at, w_at;
    reg af,wf;
    begin
      reset_direct();
      cv=1;dv=1;ar=1;wr=1;rr=1;ca=64'h80000000;cl=0;
      di=64'h8765432112345678;st=8'hff;cp=0;
      af=0;wf=0;aw_at=-1;w_at=-1;
      for(elapsed=0;elapsed<8 && (!af||!wf);elapsed=elapsed+1)begin
        #1;
        if(av&&ar)begin af=1;aw_at=elapsed;end
        if(wv&&wr)begin wf=1;w_at=elapsed;end
        @(posedge clk);@(negedge clk);
        cv=0;
        if(FIRST_W_CAPTURE || elapsed>=1)dv=0;
      end
      if(aw_at!=(CMD_EMPTY_FLOW?0:1) ||
         w_at!=(FIRST_W_CAPTURE?(CMD_EMPTY_FLOW?0:1):2))
        $fatal(1,"earliest channel latency AW=%0d W=%0d",aw_at,w_at);
      // This is the first edge *after* both real AW and WLAST handshakes.
      bv=1;bi=0;bp=0;
      #1;
      if(!br || !dut.busy_q[0] || !dut.aw_sent_q[0] || !dut.w_sent_q[0] ||
         (B_BYPASS && rv!=1))
        $fatal(1,"earliest legal B lost owner");
      @(posedge clk);@(negedge clk);bv=0;
      if(!B_BYPASS)begin @(posedge clk);@(negedge clk);end
      if(error || dut.busy_q!=0 || rv!=0)$fatal(1,"earliest B completion");
      $display("EARLIEST_B cmd_to_AW=%0d cmd_to_W=%0d cmd_to_B=%0d",aw_at,w_at,elapsed);
      directed_cases=directed_cases+1;
    end
  endtask

  task negative_case;
    begin
      reset_direct();
      if($test$plusargs("same-edge-b"))begin
        cv=1;dv=1;ar=1;wr=1;bv=1;bi=0;
      end else if($test$plusargs("invalid-id") || $test$plusargs("duplicate-b"))begin
        cv=1;dv=1;ar=1;wr=1;cl=0;
        @(posedge clk);@(negedge clk);cv=0;
        while(!dut.w_sent_q[0] || !dut.aw_sent_q[0])begin
          @(posedge clk);@(negedge clk);
          if(dut.w_sent_q[0])dv=0;
        end
        dv=0;bv=1;bi=$test$plusargs("invalid-id")?4'h8:4'h0;rr=0;
        if($test$plusargs("duplicate-b"))begin
          @(posedge clk);@(negedge clk);
          // Keep the first response queued, then repeat the same physical B.
        end
      end else begin bv=1;bi=0;end
      repeat(5)@(negedge clk);
      $fatal(1,"invalid B was not rejected by production assertion");
    end
  endtask

  initial begin
    negative = $test$plusargs("early-b") || $test$plusargs("same-edge-b") ||
      $test$plusargs("invalid-id") || $test$plusargs("duplicate-b");
    if(negative)negative_case();
    for(integer mask=0;mask<4;mask=mask+1)directed(mask);
    earliest_response();
    reset_direct();
    cp=0;monitor=1;
    for (c = 0; c < 2; c = c + 1) begin
      launched[c] = 0;
      produced[c] = 0;
      length[c] = 0;
      active[c] = 0;
      awseen[c] = 0;
      wseen[c] = 0;
      bsent[c] = 0;
      address[c] = 0;
    end
    repeat (3) @(negedge clk);
    rst = 0;
    if (negative) begin
      bv = 1;
      bi = 0;
      bp = 0;
      repeat (5) @(negedge clk);
      $fatal(1, "premature B was not rejected");
    end
    for (cycle = 0; cycle < 20000 && total < 512; cycle = cycle + 1) begin
      random_q = rng(random_q);
      ar = cycle >= 35 && (random_q[0] || random_q[1]);
      wr = random_q[2] || random_q[3];
      rr = random_q[5:4];
      for (c = 0; c < 2; c = c + 1) begin
        cv[c] = launched[c] < 256;
        ca[c*64+:64] = 64'h80000000 + (c << 20) + (launched[c] << 6);
        cl[c*8+:8] = launched[c] % 8;
        dv[c] = ((active[c] && produced[c] < length[c]) || (!active[c] && cv[c])) && random_q[8+c];
        di[c*64+:64] = data_for(active[c]?address[c]:ca[c*64+:64], active[c]?produced[c]:0);
        st[c*8+:8] = strb_for(active[c]?address[c]:ca[c*64+:64], active[c]?produced[c]:0);
      end
      if (!bv || bus_taken_q) begin
        bv = 0;
        choice = -1;
        for (c = 0; c < 2; c = c + 1)
        if (active[c] && awseen[c] && wseen[c] && !bsent[c] && (choice < 0 || random_q[12]))
          choice = c;
        if (choice >= 0 && random_q[13]) begin
          bv = 1;
          bi = choice;
          bp = resp_for(address[choice]);
        end
      end
      @(negedge clk);
    end
    if (total != 512 || beats != 2304 || early_w == 0 || early_aw < 100 || wblocked < 500 || error)
      $fatal(
          1,
          "coverage total=%0d beats=%0d earlyW=%0d earlyAW=%0d stalls=%0d",
          total,
          beats,
          early_w,
          early_aw,
          wblocked
      );
    if (B_BYPASS && (direct_count == 0 || buffered_count == 0))
      $fatal(1, "B bypass coverage missing");
    $display("B_PATH bypass=%0d direct=%0d buffered=%0d", B_BYPASS, direct_count, buffered_count);
    if(FIRST_W_CAPTURE && (single_capture==0||multi_capture==0||direct_lengths!=8'hff))
      $fatal(1,"command-first-W coaccept coverage missing total=%0d single=%0d multi=%0d",first_capture,single_capture,multi_capture);
    if(!FIRST_W_CAPTURE && first_capture!=0)$fatal(1,"disabled first capture fired");
    if(shortest_first_w!=(FIRST_W_CAPTURE?(CMD_EMPTY_FLOW?0:1):2))
      $fatal(1,"minimum command to physical first W latency got=%0d",shortest_first_w);
    $display("FIRST_W capture=%0d single=%0d multi=%0d min_cmd_to_W=%0d",first_capture,single_capture,multi_capture,shortest_first_w);
    if(shortest_aw!=(CMD_EMPTY_FLOW?0:1) || ready_combinations!=4'b1111 ||
       aw_pop_push==0 || (FIRST_W_CAPTURE && old_stage_replace==0))
      $fatal(1,"flow coverage AW=%0d ready=%b AWreplace=%0d Wreplace=%0d",
        shortest_aw,ready_combinations,aw_pop_push,old_stage_replace);
    $display("COMMAND_FLOW enable=%0d first=%0d min_AW=%0d min_W=%0d directed=%0d AWreplace=%0d Wreplace=%0d",
      CMD_EMPTY_FLOW,FIRST_W_CAPTURE,shortest_aw,shortest_first_w,directed_cases,aw_pop_push,old_stage_replace);
    $display("[PASS] tb_r64_axi_command_flow");
    $display(
        "COVERAGE transactions=%0d beats=%0d W_before_AW=%0d AW_before_W=%0d W_stalls=%0d B_stalls=%0d",
        total, beats, early_w, early_aw, wblocked, bblocked);
    $finish;
  end
endmodule
