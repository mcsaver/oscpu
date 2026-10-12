`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_lsu_prepared_reuse;
  parameter DEPTH = 6;
  parameter EARLY_STORE = 1;
  localparam IW = $clog2(DEPTH);
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0;
  reg [31:0] kill = 0;
  reg [ 2:0] trigger_enable = 0;
  reg [63:0] trigger_address = 0;
  reg trigger_test = 0, no_external = 0;
  reg [8:0] full_tag[0:31];
  reg head_valid = 1, effect_allow = 1, fp_enable = 1;
  reg [8:0] head_tag = 0;
  reg [1:0] commit_fire = 0;
  reg [17:0] commit_tag = 0;
  reg [1:0] in_fire = 0;
  wire [1:0] in_ready;
  reg [17:0] in_tag = 0;
  reg [2*`R64_UOP_W-1:0] in_uop = 0;
  reg [383:0] operand = 0;
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
  R64Lsu #(
    .EARLY_STORE(EARLY_STORE),
    .ENTRIES(DEPTH),
    .INDEX_W(IW)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .flush_i(flush),
    .kill_mask_i(kill),
    .head_valid_i(head_valid),
    .head_tag_i(head_tag),
    .effect_allow_i(effect_allow),
    .trigger_enable_i(trigger_enable),
    .trigger_address_i(trigger_address),
    .fp_enable_i(fp_enable),
    .translate_active_i(1'b0),
    .store_done_valid_o(),
    .store_done_ready_i(1'b1),
    .store_done_tag_o(),
    .store_done_error_o(),
    .store_done_tval_o(),
    .mem_fast_store_o(),
    .mem_store_rsp_valid_i(1'b0),
    .mem_store_rsp_ready_o(),
    .mem_store_rsp_token_i({IW{1'b0}}),
    .mem_store_rsp_error_i(1'b0),
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
    .mem_valid_o(mv),
    .mem_ready_i(mr),
    .mem_token_o(mtoken),
    .mem_addr_o(ma),
    .mem_data_o(md),
    .mem_op_o(mop),
    .mem_cache_o(mcache),
    .mem_size_o(msize),
    .mem_strb_o(mstrb),
    .mem_amo_o(mamo),
    .mem_rsp_valid_i(mresp),
    .mem_rsp_ready_o(mrespready),
    .mem_rsp_token_i(mresptoken),
    .mem_rsp_data_i(mrd),
    .mem_rsp_error_i(merror),
    .mem_rsp_offset_i(6'b0)
  );
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
  reg head_preparation_seen = 0;
  reg late_io_observe = 0;
  integer late_io_ready_cycles = 0;
  reg delay_owner = 0;
  reg [63:0] delayed_addr = 0;
  reg tr_hold = 0, mem_hold = 0, error_write = 0, bad_response = 0;
  reg [31:0] rng = 32'h947312bd;
  reg random_stall = 0;
  reg [1:0] response_hold = 0;
  reg error_read = 0;
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
      assign mr[g] = mn[g] < 7 && !mem_hold && (!random_stall || rng[g+2]);
      assign mresp[g] = (bad_response && g == 0) ||
          (mn[g] != 0 && mdue[g*8+mh[g]] <= cycles && !mem_hold && !response_hold[g]);
      assign mresptoken[g*IW+:IW] = bad_response ? {IW{1'b0}} : mqtoken[g*8+mh[g]];
      assign mrd[g*64+:64] = mqdata[g*8+mh[g]];
      assign merror[g] = mqerror[g*8+mh[g]];
    end
  endgenerate
  integer a, b, tag, index, j, slot;
  reg [63:0] response_data;
  always @(posedge clk)
    if (!rst) begin
      if (delay_owner && dut.prepared_valid_q && dut.prepared_tag_q == 0) head_preparation_seen = 1;
      if (no_external && (tv != 0 || mv != 0))
        $fatal(1, "trigger escaped into translation/physical request");
      if (late_io_observe) begin
        for (integer lio = 0; lio < 2; lio = lio + 1) begin
          if (dut.query_fire_w[lio] && dut.query_in_tag_w[lio*9+:9] != 0)
            $fatal(1, "younger query published across unresolved/IO owner");
          if (mv[lio] && dut.tag_q[mtoken[lio*IW+:IW]] != 0)
            $fatal(1, "younger physical request passed pending IO");
        end
        for (integer lor = 1; lor < DEPTH; lor = lor + 1)
        if (dut.state_q[0] == 2 && dut.state_q[lor] == 3)
          late_io_ready_cycles = late_io_ready_cycles + 1;
      end
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
          tdue[a*8+tt[a]] = cycles +
              ((delay_owner && tva[a*64+:64] == delayed_addr) ? 80 : tr_delay);
          tt[a] <= (tt[a] + 1) % 8;
          trcount = trcount + 1;
          if (tad[a] && ta[a*2+:2] == 2) adupdates = adupdates + 1;
        end
        mn[a] <= mn[a] + ((mv[a] && mr[a]) ? 1 : 0) - ((mresp[a] && mrespready[a]) ? 1 : 0);
        if (mresp[a] && mrespready[a]) mh[a] <= (mh[a] + 1) % 8;
        if (mv[a] && mr[a]) begin
          index = ma[a*64+:64] >> 3;
          response_data = memory[index];
          if (mop[a*2+:2] == 1 && !error_write)
            for (j = 0; j < 8; j = j + 1) if (mstrb[a*8+j]) memory[index][j*8+:8] = md[a*64+j*8+:8];
          mqtoken[a*8+mt[a]] = mtoken[a*IW+:IW];
          mqdata[a*8+mt[a]] = response_data;
          mqerror[a*8+mt[a]] = (mop[a*2+:2] != 0 && error_write) ||
              (mop[a*2+:2] == 0 && error_read);
          mdue[a*8+mt[a]] = cycles + mem_delay;
          mt[a] <= (mt[a] + 1) % 8;
          memcount = memcount + 1;
        end
        if (out_valid[a] && out_ready[a]) begin
          tag = out_tag[a*9+:5];
          if (trigger_test && out_tag[a*9+:9] !== full_tag[tag])
            $fatal(1, "trigger generation mismatch");
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
      full_tag[tagno[4:0]] = tagno;
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

  integer n, limit, held_lane, snapshots = 0, direct_reuse = 0;
  reg [63:0] saved_reference;
  reg watch = 0;
  always @(posedge clk)
    if (!rst && dut.prepared_direct_take_w && dut.prepared_slot_q == 2) begin
      direct_reuse = direct_reuse + 1;
      if (dut.prepared_tag_q != 6)
        $fatal(1, "unexpected direct owner in reused slot");
    end
  always @(negedge clk)
    if (!rst && watch && (dut.gen_forward_snapshot[2].prepare_w != 0 ||
        dut.mem_issued_q[2] || (dut.prepared_valid_q && dut.prepared_slot_q == 2))) begin
      $display("REUSE_HISTORY cycle=%0d slot=2 tag=%0d fn=%h state=%0d issued=%b mask=%h data=%h refmask=%h refdata=%h prepare=%b take=%b direct=%b",
          cycles,dut.tag_q[2],dut.func_q[2],dut.state_q[2],dut.mem_issued_q[2],
          dut.forward_mask_q[2],dut.forward_q[2],
          dut.gen_forward_snapshot[2].published_mask_reference_q,
          dut.gen_forward_snapshot[2].published_reference_q,
          dut.gen_forward_snapshot[2].prepare_w,dut.query_take_w,dut.prepared_direct_take_w);
    end
  task bounded_query;
    begin
      limit=0;
      while (dut.gen_forward_snapshot[2].prepare_w == 0 && limit<120) begin
        @(negedge clk);limit=limit+1;
      end
      if (dut.gen_forward_snapshot[2].prepare_w == 0)
        $fatal(1,"target query never resident, hold=%b occupied=%b slots=%0d/%0d",
            dut.physical_hold_valid_q,dut.query_occupied_w,dut.query_slot_w[0],dut.query_slot_w[1]);
      held_lane=dut.gen_forward_snapshot[2].prepare_w[0] ? 0 : 1;
      if (dut.query_take_w[held_lane]) $fatal(1,"target query was not backpressured");
      @(negedge clk);
      if (dut.query_take_w[held_lane]) $fatal(1,"held target query unexpectedly published");
      snapshots=snapshots+1;
    end
  endtask
  initial begin
    for(n=0;n<1024;n=n+1)memory[n]=64'h1234567880000000+n;
    for(n=0;n<2;n=n+1)begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4)@(negedge clk);rst=0;head_tag=31;effect_allow=0;watch=1;
    // The third allocated slot first owns a real partially forwarded load.
    enqueue(0,8,64'h1111,8'h23,0,0,0,0);
    enqueue(1,1,64'h77,8'h20,0,0,0,0);
    enqueue(2,0,0,8'h03,0,64'h1234567880007700,0,0);
    wait_result(2);
    if(dut.forward_mask_q[2]!==8'h02 || dut.forward_q[2][15:8]!==8'h77 ||
       dut.gen_forward_snapshot[2].published_mask_reference_q!==8'h02)
      $fatal(1,"initial partial forwarding history not established");
    saved_reference=dut.gen_forward_snapshot[2].published_reference_q;
    $display("OLD_LOAD_RETIRED slot=2 mask=%h data=%h",dut.forward_mask_q[2],saved_reference);
    effect_allow=1;head_tag=0;wait_result(0);retire(0);
    // Keep slot zero owned so subsequent owners genuinely reuse slot two.
    effect_allow=0;head_tag=1;
    enqueue(3,1,64'h99,8'h20,0,0,0,0);
    effect_allow=1;wait_result(1);retire(1);retire(2);
    effect_allow=0;head_tag=3;mem_hold=1;
    // An older independent request occupies physical holder zero.
    enqueue(4,64'h80,0,8'h03,0,memory[16],0,0);
    limit=0;
    while(dut.physical_hold_valid_q==0 && limit<80)begin @(negedge clk);limit=limit+1;end
    if(dut.physical_hold_valid_q==0)$fatal(1,"older physical holder not established");
    // The reused row now prewrites different forwarding bytes but is cancelled
    // before query_take; it must not publish a new reference or external request.
    enqueue(5,0,0,8'h03,0,64'h1234567880009900,0,0);
    if(dut.tag_q[2]!==5)$fatal(1,"middle load did not reuse target slot");
    bounded_query;
    if(dut.forward_q[2][15:8]!==8'h99 ||
       dut.gen_forward_snapshot[2].published_reference_q!==saved_reference)
      $fatal(1,"cancelled query did not separate snapshot from published reference");
    $display("CANCEL_UNPUBLISHED slot=2 snapshot=%h published=%h",
        dut.forward_q[2],dut.gen_forward_snapshot[2].published_reference_q);
    kill=32'h20;killed[5]=1;
    @(negedge clk);kill=0;active[5]=0;
    limit=0;
    while((dut.state_q[2]!=0 || reuse[5]) && limit<80)begin @(negedge clk);limit=limit+1;end
    if(dut.state_q[2]!=0 || reuse[5])$fatal(1,"cancelled query leaked owner");
    enqueue(6,64'h100,64'hfacebeef12345678,8'h23,0,0,0,0);
    if(dut.tag_q[2]!==6)$fatal(1,"prepared store did not reuse target slot");
    // Allow the older load and store to drain before granting the new store.
    mem_hold=0;effect_allow=1;head_tag=3;
    wait_result(3);retire(3);wait_result(4);retire(4);head_tag=6;
    wait_result(6);retire(6);
    if(dut.forward_mask_q[2]!==0)$fatal(1,"direct-store owner inherited forwarded-byte validity");
    if(memory[32]!==64'hfacebeef12345678 || snapshots!=1 || direct_reuse!=1 ||
       received[5] || !idle || reuse!=0 || irreversible)
      $fatal(1,"reuse regression incomplete or transaction/data corruption");
    $display("[PASS] tb_r64_lsu_prepared_reuse partial-forward load, unpublished query cancel, same-slot direct store snapshots=%0d direct=%0d",snapshots,direct_reuse);
    $finish;
  end
  initial begin #100000; $fatal(1,"reuse timeout cycle=%0d tags=%0d/%0d/%0d states=%0d/%0d/%0d received=%h",
      cycles,dut.tag_q[0],dut.tag_q[1],dut.tag_q[2],dut.state_q[0],dut.state_q[1],dut.state_q[2],received);end
endmodule
