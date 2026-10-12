`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_lsu_error_source_pin;
  parameter EARLY_STORE = 1;
  parameter STORE_ELASTIC = 1;
  // Elaborate the public LSU parameter without changing its parent wrapper.
  defparam dut.lsu.STORE_RESPONSE_ELASTIC = STORE_ELASTIC;
  localparam LOADS = 6;
  parameter DEPTH = 20;
  localparam IW = $clog2(DEPTH);
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0;
  reg [31:0] kill = 0;
  reg head_valid = 1, effect_allow = 1, fp_enable = 1;
  reg [8:0] head_tag = 0;
  reg [1:0] commit_fire = 0;
  reg [17:0] commit_tag = 0;
  reg [1:0] in_fire = 0;
  wire [1:0] in_ready;
  reg [17:0] in_tag = 0;
  reg [2*`R64_UOP_W-1:0] in_uop = 0;
  reg [383:0] operand = 0;
  wire store_valid, store_error;
  reg store_ready = 1;
  wire [8:0] store_tag;
  wire [63:0] store_tval;
  integer fast_completions = 0;
  wire [1:0] out_valid;
  reg [1:0] out_ready = 3;
  wire [17:0] out_tag;
  wire [2*`R64_RESULT_W-1:0] out_result;
  wire [31:0] reuse;
  wire irreversible, idle;
  wire [1:0] tv, tr, tad, tresp, trespready;
  wire [2*IW-1:0] ttoken, trtoken;
  R64TranslationTokenEcho #(.TOKEN_W(IW)) translation_model_tokens (
    .clk_i(clk), .rst_i(rst), .req_fire_i(tv & tr), .req_token_i(ttoken),
    .rsp_fire_i(tresp & trespready), .rsp_token_o(trtoken)
  );
  wire [127:0] tva, tpa;
  wire [3:0] ta, tc;
  wire [1:0] tfault, tneeds;
  wire [9:0] tcause;
  wire [1:0] mv, mr, mcache, mresp, mrespready, merror;
  wire [2*IW-1:0] mtoken, mresptoken;
  wire [127:0] ma, md, mrd;
  wire [3:0] mop;
  wire [5:0] msize;
  wire [15:0] mstrb;
  wire [9:0] mamo;
  // TB-only front-end: previous stimuli reserve in program order, then
  // bind the captured payload one edge later to the real dispatch-owned LSU.
  reg [1:0] bind_fire_q = 0;
  reg [17:0] bind_tag_q = 0;
  reg [2*`R64_UOP_W-1:0] bind_uop_q = 0;
  reg [383:0] bind_operand_q = 0;
  reg [2*IW-1:0] bind_slot_q = 0;
  wire [2*IW-1:0] reserve_slot_w;
  integer new_slot=-1;
  always @(posedge clk) if(!rst && in_fire[0] && in_tag[8:0]==9'd7)
    new_slot=int'(reserve_slot_w[0+:IW]);
  always @(posedge clk) begin
    if (rst || flush) bind_fire_q <= 0;
    else bind_fire_q <= in_fire;
    if (|in_fire) begin
      bind_tag_q <= in_tag;
      bind_uop_q <= in_uop;
      bind_operand_q <= operand;
      bind_slot_q <= reserve_slot_w;
    end
  end
  R64LoadStore #(
    .HEAD_AUTHORIZED_QUERY(1),
    .PREPARED_CANCEL(1),
    .EARLY_STORE(EARLY_STORE),
    .ENTRIES(DEPTH),
    .INDEX_W(IW),
    .CACHE_SET_W(6),
    .AUX(3)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .flush_i(flush),
    .invalidate_i(1'b0),
    .kill_mask_i(kill),
    .cancel_candidates_i(kill),
    .cancel_active_i(1'b1),
    .head_valid_i(head_valid),
    .head_tag_i(head_tag),
    .effect_allow_i(effect_allow),
    .trigger_enable_i(3'b0),
    .trigger_address_i(64'b0),
    .fp_enable_i(fp_enable),
    .translate_active_i(1'b0),
    .store_done_valid_o(store_valid),
    .store_done_ready_i(store_ready),
    .store_done_tag_o(store_tag),
    .store_done_error_o(store_error),
    .store_done_tval_o(store_tval),
    .commit_fire_i(commit_fire),
    .commit_tag_i(commit_tag),
    .reserve_want_i(2'b11),
    .reserve_fire_i(in_fire),
    .reserve_ready_o(in_ready),
    .reserve_slot_o(reserve_slot_w),
    .reserve_tag_i(in_tag),
    .reserve_func_i({in_uop[`R64_UOP_W+196+:8], in_uop[196+:8]}),
    .reserve_amo_i({in_uop[`R64_UOP_W+155+:5], in_uop[155+:5]}),
    .in_fire_i(bind_fire_q),
    .in_ready_o(),
    .in_tag_i(bind_tag_q),
    .in_slot_i(bind_slot_q),
    .in_command_i({bind_uop_q[1*`R64_UOP_W+155+:5], bind_uop_q[1*`R64_UOP_W+196+:8], bind_operand_q[1*192+64+:64], bind_uop_q[1*`R64_UOP_W+64+:64], bind_operand_q[1*192+:64], bind_uop_q[0*`R64_UOP_W+155+:5], bind_uop_q[0*`R64_UOP_W+196+:8], bind_operand_q[0*192+64+:64], bind_uop_q[0*`R64_UOP_W+64+:64], bind_operand_q[0*192+:64]}),
    .out_valid_o(out_valid),
    .out_ready_i(out_ready),
    .out_tag_o(out_tag),
    .out_result_o(out_result),
    .reuse_block_o(reuse),
    .irrevocable_o(irreversible),
    .idle_o(idle),
    .tr_token_o(ttoken),
    .tr_rsp_token_i(trtoken),
    .tr_valid_o(tv),
    .tr_ready_i(tr),
    .tr_vaddr_o(tva),
    .tr_access_o(ta),
    .tr_ad_update_o(tad),
    .tr_rsp_valid_i(tresp),
    .tr_rsp_ready_o(trespready),
    .tr_paddr_i(tpa),
    .tr_class_i(tc),
    .tr_fault_i(tfault),
    .tr_needs_ad_i(tneeds),
    .tr_cause_i(tcause),
    .aux_valid_i(3'b0),
    .aux_ready_o(),
    .aux_addr_i(192'b0),
    .aux_data_i(192'b0),
    .aux_expected_i(192'b0),
    .aux_op_i(6'b0),
    .aux_cache_i(3'b0),
    .aux_size_i(9'b0),
    .aux_strb_i(24'b0),
    .aux_rsp_valid_o(),
    .aux_rsp_ready_i(3'b111),
    .aux_rsp_data_o(),
    .aux_rsp_error_o(),
    .aux_rsp_compare_o(),
    .read_valid_o(rv),
    .read_ready_i(rr),
    .read_addr_o(ra),
    .read_len_o(rl),
    .read_size_o(rz),
    .beat_valid_i(bv),
    .beat_ready_o(br),
    .beat_data_i(bd),
    .beat_resp_i(2'b0),
    .beat_last_i(left == 1),
    .write_valid_o(wv),
    .write_ready_i(wr),
    .write_addr_o(wa),
    .write_size_o(wz),
    .write_data_valid_o(wdv),
    .write_data_ready_i(wdr),
    .write_data_o(wd),
    .write_strb_o(ws),
    .write_rsp_valid_i(bvalid && !b_hold),
    .write_rsp_ready_o(bready_raw),
    .write_resp_i(bresp)
  );
  wire rv, rr, bv, br, wv, wr, wdv, wdr, bready;
  wire [63:0] ra, wa, wd, bd;
  wire [7:0] rl, ws;
  wire [2:0] rz, wz;
  wire bready_raw;
  reg  b_hold = 1;
  assign bready = bready_raw && !b_hold;
  reg reading = 0, aw = 0, ww = 0, bvalid = 0;
  reg [1:0] bresp = 0;
  integer ri = 0, left = 0, wi = 0, read_due = 0, read_txns = 0;
  reg [63:0] wdata;
  reg [ 7:0] wstrb;
  assign rr  = !reading;
  assign bv  = reading && cycles >= read_due;
  assign bd  = memory[ri];
  assign wr  = !aw && !bvalid;
  assign wdr = !ww && !bvalid;
  assign mv  = dut.mv;
  assign mr  = dut.mr;
  always @(posedge clk)
    if (!rst) begin
      if (bv && br) begin
        ri   <= ri + 1;
        left <= left - 1;
        if (left == 1) reading <= 0;
      end
      if (rv && rr) begin
        reading <= 1;
        ri <= ra >> 3;
        left <= rl + 1;
        read_due <= cycles + mem_delay;
        read_txns = read_txns + 1;
      end
      if (wv && wr) begin
        aw = 1;
        wi = wa >> 3;
      end
      if (wdv && wdr) begin
        ww = 1;
        wdata = wd;
        wstrb = ws;
      end
      if (aw && ww && !bvalid) begin
        bvalid <= 1;
        bresp  <= error_write ? 2 : 0;
        if (!error_write)
          for (integer byte_n = 0; byte_n < 8; byte_n = byte_n + 1)
          if (wstrb[byte_n]) memory[wi][8*byte_n+:8] = wdata[8*byte_n+:8];
      end
      if (bvalid && bready) begin
        aw = 0;
        ww = 0;
        bvalid <= 0;
      end
    end
  reg [63:0] memory[0:1023], expected[0:31];
  reg [31:0] active = 0, killed = 0, received = 0;
  reg [31:0] expectfault = 0;
  reg [5:0] expectcause[0:31];
  reg [63:0] expecttval[0:31];
  reg [63:0] tqueue[0:15];
  reg [1:0] taqueue[0:15];
  reg adqueue[0:15];
  integer tdue[0:15], th[0:1], tt[0:1], tn[0:1];
  reg [IW-1:0] mqtoken[0:15];
  reg [63:0] mqdata[0:15];
  reg mqerror[0:15];
  integer mdue[0:15], mh[0:1], mt[0:1], mn[0:1];
  integer cycles = 0, trcount = 0, memcount = 0, wbcount = 0, dual = 0, adupdates = 0;
  integer tr_delay = 2, mem_delay = 3;
  reg tr_hold = 0, mem_hold = 0, error_write = 0;
  reg [31:0] rng = 32'h947312bd;
  reg random_stall = 0;
  genvar g;
  generate
    for (g = 0; g < 2; g = g + 1) begin : gen_model
      assign tr[g] = tn[g] < 7 && !tr_hold && (!random_stall || rng[g]);
      assign tresp[g] = tn[g] != 0 && tdue[g*8+th[g]] <= cycles && !tr_hold;
      assign tpa[g*64+:64] = tqueue[g*8+th[g]] & ~64'h1000;
      assign tc[g*2+:2] = tqueue[g*8+th[g]][11:8] == 4'he ? 2'd2 : 2'd0;
      assign tfault[g] = tqueue[g*8+th[g]][11:8] == 4'hf;
      assign tneeds[g] = tqueue[g*8+th[g]][11:8] == 4'hd && taqueue[g*8+th[g]] == 2 &&
          !adqueue[g*8+th[g]];
      assign tcause[g*5+:5] = taqueue[g*8+th[g]] == 2 ? 5'd15 : 5'd13;
    end
  endgenerate
  integer a, b, tag, index, j, slot;
  reg [63:0] response_data;
  always @(posedge clk)
    if (!rst) begin
      cycles = cycles + 1;
      rng = {rng[30:0], rng[31] ^ rng[21] ^ rng[1] ^ rng[0]};
      for (a = 0; a < 2; a = a + 1) begin
        // Queue outputs must remain the accepted owner through the sampling edge.
        tn[a] <= tn[a] + ((tv[a] && tr[a]) ? 1 : 0) - ((tresp[a] && trespready[a]) ? 1 : 0);
        if (tresp[a] && trespready[a]) th[a] <= (th[a] + 1) % 8;
        if (tv[a] && tr[a]) begin
          tqueue[a*8+tt[a]] = tva[a*64+:64];
          taqueue[a*8+tt[a]] = ta[a*2+:2];
          adqueue[a*8+tt[a]] = tad[a];
          tdue[a*8+tt[a]] = cycles + tr_delay;
          tt[a] <= (tt[a] + 1) % 8;
          trcount = trcount + 1;
          if (tad[a] && ta[a*2+:2] == 2) adupdates = adupdates + 1;
        end
        if (mv[a] && mr[a]) memcount = memcount + 1;
        if (out_valid[a] && out_ready[a]) begin
          tag = out_tag[a*9+:5];
          if (!active[tag] || killed[tag] || received[tag])
            $fatal(
                1,
                "invalid completion tag %0d active%h killed%h received%h",
                tag,
                active,
                killed,
                received
            );
          if (out_result[a*`R64_RESULT_W+64] !== expectfault[tag] ||
              (!expectfault[tag] && out_result[a*`R64_RESULT_W+:64] !== expected[tag]) ||
              (expectfault[tag] && (out_result[a*`R64_RESULT_W+65+:6] !== expectcause[tag] ||
                                    out_result[a*`R64_RESULT_W+71+:64] !== expecttval[tag])))
            $fatal(
                1,
                "bad result tag%0d value%h expected%h exception%b",
                tag,
                out_result[a*`R64_RESULT_W+:64],
                expected[tag],
                out_result[a*`R64_RESULT_W+64]
            );
          received[tag] = 1;
          wbcount = wbcount + 1;
        end
      end
      if (store_valid && store_ready) begin
        tag = store_tag[4:0];
        if (!active[tag] || killed[tag] || received[tag] || store_tag != head_tag)
          $fatal(1, "invalid narrow store completion tag%0d", store_tag);
        if (store_error !== expectfault[tag] || (!store_error && expected[tag] != 0) ||
            (store_error && (expectcause[tag] != 7 || store_tval !== expecttval[tag])))
          $fatal(1, "narrow store completion payload tag%0d", store_tag);
        received[tag] = 1;
        wbcount = wbcount + 1;
        fast_completions = fast_completions + 1;
      end
      if (out_valid == 3 && out_ready == 3) dual = dual + 1;
    end
  task enqueue;
    input [8:0] tagno;
    input [63:0] addr, data;
    input [7:0] fn;
    input [4:0] amo;
    input [63:0] answer;
    input fault;
    input [5:0] cause;
    begin
      @(negedge clk);
      while (!in_ready[0]) @(negedge clk);
      in_fire = 1;
      in_tag = {9'b0, tagno};
      in_uop = 0;
      operand = 0;
      in_uop[196+:8] = fn;
      in_uop[155+:5] = amo;
      operand[63:0] = addr;
      operand[64+:64] = data;
      active[tagno[4:0]] = 1;
      received[tagno[4:0]] = 0;
      killed[tagno[4:0]] = 0;
      expected[tagno[4:0]] = answer;
      expectfault[tagno[4:0]] = fault;
      expectcause[tagno[4:0]] = cause;
      expecttval[tagno[4:0]] = addr;
      @(negedge clk);
      in_fire = 0;
    end
  endtask
  task wait_result;
    input [4:0] tagno;
    begin
      while (!received[tagno]) @(negedge clk);
    end
  endtask
  task retire;
    input [8:0] tagno;
    begin
      @(negedge clk);
      commit_fire = 1;
      commit_tag  = {9'b0, tagno};
      @(negedge clk);
      commit_fire = 0;
      active[tagno[4:0]] = 0;
    end
  endtask



  integer n,budget,error_cycle=-1,wrong_reads=0,source_takes=0,new_slot_at_birth=-1;
  integer source_free_cycle=-1,last_source_take=-1,b_count=0,wrong_refs=0;
  reg witness=0,drain_case=0,kill_case=0,watch_source=0,hold_terminal=0;
  reg [63:0] old_source;
  always @(posedge clk)if(!rst)begin
    if(dut.lsu.store_response_fire_w && watch_source && error_cycle<0)begin
      error_cycle=cycles;
      if(!dut.lsu.mem_store_rsp_error_i || !dut.lsu.source_pin_w[0])
        $fatal(1,"B error lacks resident source pin");
      $display("LOCAL_B cycle=%0d state=%0d alive=%b pin=%b held=%b queryvalid=%b querytake=%b data=%h",
        cycles,dut.lsu.state_q[0],dut.lsu.alive_q[0],dut.lsu.source_pin_w[0],
        dut.lsu.query_held_pin_w[0],dut.lsu.query_valid_w,dut.lsu.query_take_w,dut.lsu.store_q[0]);
    end
    if(bvalid&&bready)b_count=b_count+1;
    if(watch_source)begin
      if(!witness && error_cycle>=0 && cycles>error_cycle &&
         dut.lsu.source_pin_w[0] && !flush && !kill[0] &&
         (dut.lsu.state_q[0]!=6 || dut.lsu.alive_q[0] || dut.lsu.effect_q[0]))
        $fatal(1,"referenced failed source lost local storage ownership");
      for(integer lane=0;lane<2;lane=lane+1)
      for(integer q=0;q<2;q=q+1)
        if(dut.lsu.forward_query.valid_q[lane][q] &&
           dut.lsu.forward_query.data_q[lane][q][DEPTH] &&
           dut.lsu.store_q[0][15:8]!==8'h11)begin
          wrong_refs=wrong_refs+1;
          $display("HELD_SOURCE_CHANGED cycle=%0d lane=%0d queue_slot=%0d query_tag=%0d source_tag=%0d byte=%h",
            cycles,lane,q,dut.lsu.forward_query.tag_q[lane][q],dut.lsu.tag_q[0],dut.lsu.store_q[0][15:8]);
        end
      for(integer l=0;l<2;l=l+1)
        if(dut.lsu.query_valid_w[l]&&dut.lsu.query_front_pin_w[l*DEPTH])begin
          if(dut.lsu.selected_forward_w[l][15:8]!==8'h11)begin
            wrong_reads=wrong_reads+1;
            $display("SOURCE_BYTE_CHANGED cycle=%0d lane=%0d source_state=%0d source_tag=%0d source_data=%h query_tag=%0d selected=%h take=%b",
              cycles,l,dut.lsu.state_q[0],dut.lsu.tag_q[0],dut.lsu.store_q[0],
              dut.lsu.query_tag_w[l*9+:9],dut.lsu.selected_forward_w[l],dut.lsu.query_take_w[l]);
          end
          if(dut.lsu.query_take_w[l])begin source_takes=source_takes+1;last_source_take=cycles;end
        end
      if(error_cycle>=0&&cycles>error_cycle&&dut.lsu.state_q[0]==0&&source_free_cycle<0)
        source_free_cycle=cycles;
      if(error_cycle>=0&&cycles<=error_cycle+8)
        $display("LOCAL_EDGE cycle=%0d rel=%0d state=%0d alive=%b effect=%b pin=%b qpin=%b qvalid=%b qtake=%b offer=%0d credit=%b reserve=%b bind=%b newslot=%0d source=%h flush=%b kill=%h",
          cycles,cycles-error_cycle,dut.lsu.state_q[0],dut.lsu.alive_q[0],dut.lsu.effect_q[0],
          dut.lsu.source_pin_w[0],dut.lsu.query_held_pin_w[0],dut.lsu.query_valid_w,
          dut.lsu.query_take_w, reserve_slot_w[0+:IW],in_ready,in_fire,bind_fire_q,new_slot,dut.lsu.store_q[0],flush,kill);
    end
  end
  initial begin
    witness=$test$plusargs("witness");
    drain_case=$test$plusargs("drain");
    kill_case=$test$plusargs("late-kill");
    hold_terminal=$test$plusargs("hold-terminal");
    if(hold_terminal)store_ready=0;
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    error_write=1;
    mem_delay=120;
    repeat(4)@(negedge clk);rst=0;
    enqueue(0,64'h81,64'h11,8'h20,0,0,1,7);
    while(!bvalid)@(negedge clk);
    for(n=0;n<LOADS;n=n+1)
      enqueue(9'(n+1),n==LOADS-1?64'h80:64'h100+64'(n*64),0,8'h03,0,
              n==LOADS-1?((memory[16]&~64'hff00)|64'h1100):memory[32+n*8],0,0);
    budget=0;
    while((!dut.lsu.query_held_pin_w[0] || dut.lsu.query_take_w!=0 ||
           dut.lsu.descriptor_valid_w!=0) && budget<100)begin @(negedge clk);budget=budget+1;end
    if(budget==100)$fatal(1,"resident blocked query was not reached");
    old_source=dut.lsu.store_q[0];watch_source=1;
    b_hold=0;
    while(error_cycle<0)@(negedge clk);
    // The error terminal is consumed normally. No commit or trap fence is
    // invented at this independent module's admission boundary.
    if(hold_terminal)begin
      repeat(3)begin
        @(negedge clk);
        if(!store_valid||!store_error||store_tag!=0||store_tval!=64'h81||received[0])
          $fatal(1,"held store error terminal changed or duplicated");
      end
      store_ready=1;
    end
    if(!received[0])wait_result(0);
    effect_allow=0;
    if(dut.lsu.alive_q[0]||dut.lsu.effect_q[0])$fatal(1,"error retained live/effect ownership");
    $display("AFTER_ERROR cycle=%0d source_state=%0d offer=%0d pin=%b",cycles,
      dut.lsu.state_q[0],reserve_slot_w[0+:IW],dut.lsu.source_pin_w[0]);
    enqueue(7,64'h180,64'haaaaaaaaaaaaaaaa,8'h23,0,0,0,0);
    repeat(2)@(negedge clk);
    if(witness)begin
      if(new_slot!=0||dut.lsu.tag_q[0]!=7||dut.lsu.store_q[0]!==64'haaaaaaaaaaaaaaaa ||
         !dut.lsu.query_held_pin_w[0]||wrong_refs==0)
        $fatal(1,"old source reuse counterexample not established");
    end else begin
      if(new_slot==0||dut.lsu.state_q[0]!=6||dut.lsu.store_q[0]!==old_source||
         !dut.lsu.query_held_pin_w[0]||wrong_reads!=0)
        $fatal(1,"failed drained source was not locally pinned");
    end
    if(drain_case)begin
      budget=0;
      while(dut.lsu.source_pin_w[0]&&budget<1500)begin @(negedge clk);budget=budget+1;end
      if(budget==1500||wrong_reads||source_takes==0)$fatal(1,"last source read did not drain correctly");
      repeat(2)@(negedge clk);
      if(dut.lsu.state_q[0]!=0||dut.lsu.alive_q[0]||dut.lsu.effect_q[0])
        $fatal(1,"drained error source did not recover free credit");
      // After the last byte capture, reuse source storage before the original
      // load returns physically. Its saved forwarding snapshot must survive.
      enqueue(8,64'h188,64'hbbbbbbbbbbbbbbbb,8'h23,0,0,0,0);
      repeat(2)@(negedge clk);
      if(dut.lsu.tag_q[0]!=8||dut.lsu.store_q[0]!==64'hbbbbbbbbbbbbbbbb)
        $fatal(1,"released source slot was not reused after last capture");
      wait_result(6);
      $display("POST_CAPTURE_REUSE source_slot=0 new_tag=8 load_tag=6 result=%h cycle=%0d",
        expected[6],cycles);
    end
    // Main counterexample restores/cancels after the finite real-recovery-
    // sized window. The optional drain case isolates last-reference lifetime.
    if(kill_case)kill=32'h000000fe;else flush=1;
    killed=active;active=0;
    @(negedge clk);flush=0;kill=0;
    budget=0;
    while((!idle||reuse!=0)&&budget<2000)begin @(negedge clk);budget=budget+1;end
    if(budget==2000||dut.lsu.query_held_pin_w!=0)$fatal(1,"late cancellation did not drain owners");
    watch_source=0;
    if(fast_completions!=1||b_count!=1||memory[16]!==64'h1234567880000010)
      $fatal(1,"store error completion/effect not exactly once");
    // Reclaim the exact source slot after references drain, with a fresh fulltag.
    head_tag=32;effect_allow=1;error_write=0;
    enqueue(32,64'h200,64'h5a,8'h20,0,0,0,0);
    wait_result(0);retire(32);
    repeat(8)@(negedge clk);
    if(!idle||reuse!=0||memory[64][7:0]!==8'h5a||fast_completions!=2||b_count!=2)
      $fatal(1,"post-drain new owner did not recover normal service");
    if(witness)$display("[REPRODUCED] tb_r64_lsu_error_source_pin old FREE/pinned source overwritten via legal birth: new_slot=%0d wrong_reads=%0d wrong_refs=%0d error_cycle=%0d source_free=%0d",
      new_slot,wrong_reads,wrong_refs,error_cycle,source_free_cycle);
    else $display("[PASS] tb_r64_lsu_error_source_pin drain=%0d late_kill=%0d new_slot=%0d source_takes=%0d last_take=%0d free=%0d",
      drain_case,kill_case,new_slot,source_takes,last_source_take,source_free_cycle);
    $finish;
  end
  initial begin #2000000;$fatal(1,"test timeout");end
endmodule
