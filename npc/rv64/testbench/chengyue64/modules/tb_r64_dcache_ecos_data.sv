`timescale 1ns/1ps
module tb_r64_dcache_ecos_data;
  reg clk=0;
  always #5 clk=~clk;
  reg rst=1, read_en=0, write_en=0;
  reg [7:0] ra=0, wa=0;
  reg way=0;
  reg [63:0] wd=0;
  reg [7:0] wm=0;
  wire rr, wr, idle, forward_hit, probe_ready, refill_probe_ready;
  reg use_r_credit=0, b_way=0;
  reg [7:0] b_addr=0;
  reg last_r_credit, last_b_credit;
  integer r_head_blocks=0, r_tail_merges=0, r_tail_promotions=0, r_drain_allocations=0;
  integer r_key_disagreements=0, r_lookup_checks=0, r_fair_blocks=0;
  wire [63:0] q0, q1;
  R64DcacheData dut (
    .clk_i(clk), .rst_i(rst), .read_i(read_en), .read_ready_o(rr),
    .read_addr_i(ra), .read_data0_o(q0), .read_data1_o(q1),
    .write_i(write_en), .write_ready_o(wr), .write_way_i(way),
    .write_addr_i(wa), .write_data_i(wd), .write_mask_i(wm),
    .probe_way_i(use_r_credit ? b_way : way),
    .probe_addr_i(use_r_credit ? b_addr : wa), .probe_ready_o(probe_ready),
    .refill_probe_way_i(way), .refill_probe_addr_i(wa),
    .refill_probe_ready_o(refill_probe_ready),
    .idle_o(idle), .forward_o(forward_hit)
  );
  reg [63:0] model[0:1][0:255];
  reg [63:0] held0, held1;
  reg have_lookup=0, last_write=0, use_b_credit=0;
  integer b_head_blocks=0, b_tail_merges=0, b_tail_promotions=0, b_drain_allocations=0;
  integer reads=0, writes=0, held_checks=0, forwarded=0, full_blocks=0;
  integer frozen_blocks=0, partial_writes=0, merge_writes=0, fair_blocks=0;
  integer dirty_reads=0, max_dirty_reads=0, i, n;
  reg [31:0] random_q=32'h2adcb587;
  function [31:0] next_random(input [31:0] value);
    reg [31:0] v;
    begin
      v=value^(value<<13);
      v=v^(v>>17);
      next_random=v^(v<<5);
    end
  endfunction
  task step(input rd, input [7:0] raddr, input wt, input wy,
            input [7:0] waddr, input [63:0] value, input [7:0] mask);
    reg rfire, wfire, probe_before_lookup, refill_before_lookup;
    begin
      @(negedge clk);
      ra=raddr; wa=waddr; way=wy; wd=value; wm=mask;
      read_en=0; write_en=0;
      #1;
      probe_before_lookup=probe_ready;
      refill_before_lookup=refill_probe_ready;
      read_en=rd && rr;
      #1;
      if (probe_ready !== probe_before_lookup)
        $fatal(1,"B Q-credit changed with current lookup/drain");
      if (!use_r_credit && probe_ready && !wr)
        $fatal(1,"B Q-credit does not guarantee write acceptance");
      if (refill_probe_ready !== refill_before_lookup)
        $fatal(1,"R Q-credit changed with current lookup/drain");
      if (refill_probe_ready && !wr)
        $fatal(1,"R Q-credit does not guarantee write acceptance");
      last_r_credit=refill_probe_ready; last_b_credit=probe_ready;
      if(use_r_credit)begin
        r_lookup_checks=r_lookup_checks+1;
        if(refill_probe_ready != probe_ready)r_key_disagreements=r_key_disagreements+1;
        if(rd && !rr)r_fair_blocks=r_fair_blocks+1;
      end
      write_en=wt && (use_r_credit ? refill_probe_ready : use_b_credit ? probe_ready : wr);
      rfire=read_en; wfire=write_en; last_write=wfire;
      if(use_r_credit && wt && dut.match_any_w && dut.write_slot_w==dut.head_q)begin
        if(refill_probe_ready)$fatal(1,"R accepted occupied head using foreign B-key credit");
        r_head_blocks=r_head_blocks+1;
      end
      if(use_r_credit && wfire && dut.match_any_w)begin
        r_tail_merges=r_tail_merges+1;
        if(dut.pop_w)r_tail_promotions=r_tail_promotions+1;
      end
      if(use_r_credit && wfire && !dut.match_any_w && dut.pop_w)
        r_drain_allocations=r_drain_allocations+1;
      if(use_b_credit && wt && dut.match_any_w && dut.write_slot_w==dut.head_q)begin
        if(probe_ready)$fatal(1,"B accepted the occupied head key");
        b_head_blocks=b_head_blocks+1;
      end
      if(use_b_credit && wfire && dut.match_any_w)begin
        b_tail_merges=b_tail_merges+1;
        if(dut.pop_w) b_tail_promotions=b_tail_promotions+1;
      end
      if(use_b_credit && wfire && !dut.match_any_w && dut.pop_w)
        b_drain_allocations=b_drain_allocations+1;
      if (wt && !wr && dut.valid_q==3) full_blocks=full_blocks+1;
      if (wt && !wr && dut.locked_w && dut.match_any_w) frozen_blocks=frozen_blocks+1;
      if (rd && !rr) fair_blocks=fair_blocks+1;
      if (forward_hit) forwarded=forwarded+1;
      if (wfire && dut.match_any_w) merge_writes=merge_writes+1;
      if (dut.macro_write_w && dut.mask_q[dut.head_q]!=8'hff) partial_writes=partial_writes+1;
      if (rfire && dut.dirty_w) dirty_reads=dirty_reads+1;
      else if (!dut.dirty_w || dut.begin_drain_w) dirty_reads=0;
      if (dirty_reads>max_dirty_reads) max_dirty_reads=dirty_reads;
      if (dirty_reads>4) $fatal(1,"unbounded dirty lookup grants");
      @(posedge clk);
      if (wfire) begin
        for (integer b=0;b<8;b=b+1)
          if(mask[b]) model[wy][waddr][b*8+:8]=value[b*8+:8];
        writes=writes+1;
      end
      if (rfire) begin
        held0=model[0][raddr]; held1=model[1][raddr];
        have_lookup=1; reads=reads+1;
      end
      #1;
      if (have_lookup) begin
        if (q0 !== held0 || q1 !== held1)
          $fatal(1,"lookup/held mismatch read=%0d addr=%h q=%h/%h expected=%h/%h",
                 rfire,raddr,q0,q1,held0,held1);
        if (!rfire) held_checks=held_checks+1;
      end
    end
  endtask
  task put(input wy,input [7:0] address,input [63:0] value,input [7:0] mask);
    begin
      step(0,0,1,wy,address,value,mask);
      while(!last_write) step(0,0,1,wy,address,value,mask);
    end
  endtask
  initial begin
    repeat(3) @(negedge clk);
    rst=0;
    // Initialize every macro row through the credited write interface.
    for (i=0;i<256;i=i+1) begin
      put(0,8'(i),64'h1122334400000000+64'(i),8'hff);
      put(1,8'(i),64'h8877665500000000+64'(i),8'hff);
    end
    while(!idle) step(0,0,0,0,0,0,0);
    // R and B query deliberately different keys. Expectations below follow
    // accepted traffic (A=head, B=tail), not a copied RTL credit expression.
    use_r_credit=1; b_way=1; b_addr=9;
    step(1,7,1,0,7,64'h123456789abcdef0,8'h05);
    if(!last_write || !last_r_credit || !last_b_credit)$fatal(1,"empty R/B credit missing");
    step(1,7,1,0,7,64'hffeeddccbbaa9988,8'h80);
    if(last_write || last_r_credit || !last_b_credit)$fatal(1,"R head must reject despite free-slot B");
    b_way=0;b_addr=7;
    step(1,7,1,1,9,64'h1020304050607080,8'h33);
    if(!last_write || !last_r_credit || last_b_credit)$fatal(1,"R new tail must accept despite blocked B head");
    b_way=1;b_addr=9;
    step(1,9,1,0,11,64'h1234123412341234,8'hff);
    if(last_write || last_r_credit || !last_b_credit)$fatal(1,"R full unrelated key borrowed B tail credit");
    b_way=0;b_addr=7;
    step(1,9,1,1,9,64'haabbccddeeff0011,8'hc0);
    if(!last_write || !last_r_credit || last_b_credit)$fatal(1,"R tail lost independent merge");
    step(1,9,1,1,9,64'h0102030405060708,8'h04);
    if(!last_write || !last_r_credit || last_b_credit)$fatal(1,"R tail merge lost on head drain");
    b_way=0;b_addr=11;
    for(integer wait_r=0;wait_r<5;wait_r=wait_r+1)begin
      step(1,9,1,1,9,64'h8172635445362718,8'h08);
      if(last_write || last_r_credit || !last_b_credit)
        $fatal(1,"promoted R head borrowed same-edge drain or B-key credit");
    end
    step(1,9,1,1,9,64'h8172635445362718,8'h08);
    if(!last_write)$fatal(1,"R head did not progress after four-read drain");
    b_way=1;b_addr=9;
    step(0,0,1,0,11,64'h8765432187654321,8'h81);
    if(!last_write || last_b_credit)$fatal(1,"R old empty slot allocation during B-head drain failed");
    while(!idle)step(0,0,0,0,0,0,0);
    step(1,7,0,0,0,0,0);step(1,9,0,0,0,0,0);step(1,11,0,0,0,0,0);
    use_r_credit=0;
    // B head remains frozen even with an empty second slot and a live read.
    // Tail merges may coincide with head drain, then the promoted tail must
    // become frozen. Four read grants still force progress for a waiting B.
    use_b_credit=1;
    step(1,8'd7,1,0,8'd7,64'h123456789abcdef0,8'h05);
    step(1,8'd7,1,0,8'd7,64'hffeeddccbbaa9988,8'h80);
    if(last_write)$fatal(1,"B duplicated head into empty slot");
    step(1,8'd7,1,1,8'd9,64'h1020304050607080,8'h33);
    step(1,8'd9,1,1,8'd9,64'haabbccddeeff0011,8'hc0);
    step(1,8'd9,1,1,8'd9,64'h0102030405060708,8'h04);
    step(1,8'd9,1,1,8'd9,64'h8172635445362718,8'h08);
    if(!last_write)$fatal(1,"tail merge lost during head drain");
    for(integer wait_b=0;wait_b<5;wait_b=wait_b+1)begin
      step(1,8'd9,1,1,8'd9,64'hffffffffffffffff,8'h80);
      if(last_write)$fatal(1,"promoted B head used live or same-drain credit");
    end
    step(1,8'd9,1,1,8'd9,64'hffffffffffffffff,8'h80);
    if(!last_write)$fatal(1,"head-key B did not progress after bounded drain");
    step(0,0,1,0,8'd11,64'h8765432187654321,8'hff);
    if(!last_write)$fatal(1,"empty-slot B allocation failed during old head drain");
    while(!idle) step(0,0,0,0,0,0,0);
    step(1,8'd7,0,0,0,0,0);
    step(1,8'd9,0,0,0,0,0);
    step(1,8'd11,0,0,0,0,0);
    use_b_credit=0;
    // Two dirty keys fill the finite queue while lookups retain priority.
    step(1,8'd7,1,0,8'd7,64'hfedcba9876543210,8'h05);
    step(1,8'd7,1,0,8'd7,64'h1020304050607080,8'ha0);
    step(1,8'd7,1,1,8'd9,64'h9988776655443322,8'h33);
    step(1,8'd9,1,0,8'd11,64'h1234567812345678,8'hff);
    step(1,8'd7,1,0,8'd11,64'h1234567812345678,8'hff);
    // The oldest key is frozen for the physical masked write edge.
    repeat(3) step(1,8'd7,1,0,8'd7,64'hffeeddccbbaa9988,8'h80);
    repeat(12) step(0,0,0,0,0,0,0);
    // Independent deterministic byte oracle, simultaneous enqueue/read,
    // both ways, all rows, same-word merges and held-result maintenance.
    for(n=0;n<18000;n=n+1) begin
      random_q=next_random(random_q);
      step(random_q[0]||random_q[1],random_q[9:2],
           random_q[10]||random_q[11],random_q[12],random_q[20:13],
           {random_q,random_q^32'h5a3c9781},random_q[28:21]);
    end
    while(!idle) step(0,0,0,0,0,0,0);
    for(i=0;i<256;i=i+1) step(1,8'(i),0,0,0,0,0);
    if(reads<6000 || writes<2000 || held_checks<2000 || forwarded<20 ||
       full_blocks<100 || frozen_blocks<3 || partial_writes<100 ||
       merge_writes<1 || fair_blocks<1 || max_dirty_reads!=4)
      $fatal(1,"coverage missing reads=%0d writes=%0d held=%0d fwd=%0d full=%0d frozen=%0d partial=%0d merge=%0d fair=%0d max=%0d",
         reads,writes,held_checks,forwarded,full_blocks,frozen_blocks,partial_writes,merge_writes,fair_blocks,max_dirty_reads);
    if(b_head_blocks<6 || b_tail_merges<3 || b_tail_promotions<1 || b_drain_allocations<1)
      $fatal(1,"B Q-credit directed coverage missing");
    if(r_head_blocks<6 || r_tail_merges<2 || r_tail_promotions<1 ||
       r_drain_allocations<1 || r_key_disagreements<8 || r_lookup_checks<12 || r_fair_blocks<2)
      $fatal(1,"R independent-key coverage missing");
    $display("R_QCREDIT head_blocks=%0d tail_merges=%0d tail_promotions=%0d drain_allocations=%0d key_disagreements=%0d lookup_checks=%0d fairness=%0d",
      r_head_blocks,r_tail_merges,r_tail_promotions,r_drain_allocations,r_key_disagreements,r_lookup_checks,r_fair_blocks);
    $display("B_QCREDIT head_blocks=%0d tail_merges=%0d tail_promotions=%0d drain_allocations=%0d",
      b_head_blocks,b_tail_merges,b_tail_promotions,b_drain_allocations);
    $display("[PASS] tb_r64_dcache_ecos_data reads=%0d writes=%0d held=%0d forward=%0d full_backpressure=%0d frozen_key=%0d partial_writes=%0d merge=%0d fairness=%0d max_dirty_reads=%0d",
      reads,writes,held_checks,forwarded,full_blocks,frozen_blocks,partial_writes,merge_writes,fair_blocks,max_dirty_reads);
    $finish;
  end
  initial begin #500000; $fatal(1,"ECOS DCache data timeout"); end
endmodule
