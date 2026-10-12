`timescale 1ns / 1ps
// Public D-side translation/protection boundary. An in-order scoreboard checks
// captured owner attributes through mixed latency, overflow and invalidation.
module tb_r64_data_bare_fast;
  parameter BARE_LATENCY = 1;
  parameter PROTECTION_EMPTY = 1;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, qv = 0, allow_raw = 1, rr = 1, inv = 0, poison = 0;
  reg [63:0] va = 0, status = 0, satp = 0;
  reg [1:0] access_kind = 1, priv = 3;
  reg [3:0] protection = 7;
  reg ad = 0, pbmt_enable = 1;
  reg [15:0] pmp_active = 0;
  reg [895:0] pmp_lower = 0, pmp_upper = 0;
  reg [63:0] pmp_permission = 0;
  wire qr, raw_valid, raw_ready, protection_ready, rv;
  wire [63:0] raw_pa, pa;
  wire [64:0] raw_last;
  wire [3:0] raw_protection, final_protection;
  wire [1:0] raw_priv, raw_pbmt, raw_class, memory_class;
  wire raw_fault, raw_ad, raw_pma_fault, fault, needs_ad;
  wire [4:0] raw_cause, cause;
  wire mv, mrr, mo;
  wire [55:0] ma;
  wire [63:0] expected, mask;
  reg mrv = 0;
  reg [63:0] md = 0, leaf = 64'h200000cf;
  integer delay = 0;
  reg [63:0] pending_data;
  assign raw_ready = allow_raw && protection_ready;
  R64DataTranslation dut (
    .clk_i(clk), .rst_i(rst), .req_valid_i(qv), .req_ready_o(qr),
    .req_protection_i(protection), .rsp_protection_o(raw_protection),
    .rsp_last_o(raw_last), .rsp_pma_class_o(raw_class), .rsp_pma_fault_o(raw_pma_fault),
    .req_poison_i(poison), .req_vaddr_i(va), .req_access_i(access_kind),
    .req_priv_i(priv), .req_mstatus_i(status), .req_satp_i(satp),
    .req_ad_update_i(ad), .req_pbmt_enable_i(pbmt_enable),
    .rsp_valid_o(raw_valid), .rsp_ready_i(raw_ready), .rsp_priv_o(raw_priv),
    .rsp_paddr_o(raw_pa), .rsp_pbmt_o(raw_pbmt), .rsp_needs_ad_o(raw_ad),
    .rsp_fault_o(raw_fault), .rsp_cause_o(raw_cause),
    .invalidate_i(inv), .invalidate_all_vaddr_i(1'b1), .invalidate_all_asid_i(1'b1),
    .invalidate_vpn_i(27'b0), .invalidate_asid_i(16'b0),
    .mem_valid_o(mv), .mem_ready_i(1'b1), .mem_compare_or_o(mo),
    .mem_addr_o(ma), .mem_expected_o(expected), .mem_or_mask_o(mask),
    .mem_rsp_valid_i(mrv), .mem_rsp_ready_o(mrr), .mem_rdata_i(md),
    .mem_error_i(1'b0), .mem_compare_ok_i(1'b0)
  );
  R64DataProtection #(.PMA_PREPARED(1),.EMPTY_FLOW(PROTECTION_EMPTY)) protect (
    .clk_i(clk), .rst_i(rst), .req_valid_i(raw_valid && allow_raw),
    .req_ready_o(protection_ready), .req_paddr_i(raw_pa), .req_last_i(raw_last),
    .req_protection_i(raw_protection), .req_priv_i(raw_priv), .req_pbmt_i(raw_pbmt),
    .req_pma_class_i(raw_class), .req_pma_fault_i(raw_pma_fault),
    .req_fault_i(raw_fault), .req_needs_ad_i(raw_ad), .req_cause_i(raw_cause),
    .pmp_active_i(pmp_active), .pmp_lower_i(pmp_lower), .pmp_upper_i(pmp_upper),
    .pmp_permission_i(pmp_permission), .rsp_valid_o(rv), .rsp_ready_i(rr),
    .rsp_paddr_o(pa), .rsp_class_o(memory_class), .rsp_fault_o(fault),
    .rsp_needs_ad_o(needs_ad), .rsp_cause_o(cause), .rsp_protection_o(final_protection)
  );
  integer cycle = 0, accepted = 0, raw_returned = 0, returned = 0, put = 0;
  integer walks = 0, held_cycles = 0, measured_fast = 0, measured_hit = 0;
  reg [63:0] ep[0:255];
  reg [64:0] el[0:255];
  reg [3:0] eprotect[0:255];
  reg [1:0] epriv[0:255], eclass[0:255], epbmt[0:255];
  reg erf[0:255], epma[0:255], eff[0:255], ead[0:255], seen[0:255];
  reg [4:0] ecause[0:255];
  integer latency[0:255], accepted_at[0:255];
  reg held_raw = 0, held_final = 0;
  wire [146:0] raw_packet = {raw_class, raw_pma_fault, raw_pa, raw_last, raw_protection,
                              raw_priv, raw_pbmt, raw_fault, raw_ad, raw_cause};
  wire [76:0] final_packet = {pa, memory_class, fault, needs_ad, cause, final_protection};
  reg [146:0] saved_raw;
  reg [76:0] saved_final;
  always @(posedge clk) if (!rst) begin
    cycle = cycle + 1;
    if (held_raw && (!raw_valid || raw_packet !== saved_raw))
      $fatal(1, "raw response changed while held");
    if (held_final && (!rv || final_packet !== saved_final))
      $fatal(1, "protected response changed while held");
    held_raw = raw_valid && !raw_ready;
    held_final = rv && !rr;
    saved_raw = raw_packet;
    saved_final = final_packet;
    if (held_raw || held_final) held_cycles = held_cycles + 1;
    if (qv && qr) begin
      if (accepted >= put) $fatal(1, "request lacks expected owner");
      accepted_at[accepted] = cycle;
      accepted = accepted + 1;
    end
    if (raw_valid) begin
      if (raw_returned >= accepted || raw_returned >= put)
        $fatal(1, "raw response lacks request owner");
      if (!seen[raw_returned]) begin
        seen[raw_returned] = 1;
        if (latency[raw_returned] != 0 &&
            cycle - accepted_at[raw_returned] != latency[raw_returned])
          $fatal(1, "latency item=%0d measured=%0d expected=%0d", raw_returned,
                 cycle-accepted_at[raw_returned], latency[raw_returned]);
        if (latency[raw_returned] == BARE_LATENCY) measured_fast = measured_fast + 1;
        if (latency[raw_returned] == 2 && BARE_LATENCY != 2) measured_hit = measured_hit + 1;
      end
      if (raw_fault !== erf[raw_returned] || raw_priv !== epriv[raw_returned] ||
          raw_protection !== eprotect[raw_returned] ||
          (raw_fault && raw_cause !== ecause[raw_returned]) ||
          (!raw_fault && (raw_pa !== ep[raw_returned] || raw_last !== el[raw_returned] ||
           raw_pma_fault !== epma[raw_returned] || raw_class !== eclass[raw_returned] ||
           raw_pbmt !== epbmt[raw_returned] || raw_ad !== ead[raw_returned])))
        $fatal(1, "raw owner item=%0d pa=%h/%h priv=%d/%d pma=%b/%b fault=%b/%b",
               raw_returned, raw_pa, ep[raw_returned], raw_priv, epriv[raw_returned],
               raw_pma_fault, epma[raw_returned], raw_fault, erf[raw_returned]);
      if (raw_ready) raw_returned = raw_returned + 1;
    end
    if (rv && rr) begin
      if(returned<32 && cycle-accepted_at[returned] != BARE_LATENCY+(PROTECTION_EMPTY!=0?0:1))
        $fatal(1,"protected latency item=%0d got=%0d",returned,cycle-accepted_at[returned]);
      if (returned >= raw_returned || fault !== eff[returned] ||
          final_protection !== eprotect[returned] ||
          (fault && cause !== ecause[returned]) ||
          (!fault && (pa !== ep[returned] || needs_ad !== ead[returned])))
        $fatal(1, "protected owner item=%0d fault=%b/%b cause=%d/%d",
               returned, fault, eff[returned], cause, ecause[returned]);
      returned = returned + 1;
    end
    if (mrv && mrr) mrv <= 0;
    if (delay > 0) begin
      delay = delay - 1;
      if (delay == 0) begin mrv <= 1; md <= pending_data; end
    end
    if (mv) begin
      if (ma != 56'h1008 || mo || delay != 0 || mrv)
        $fatal(1, "unexpected PTW address/ownership/atomic op %h", ma);
      walks = walks + 1;
      delay = 5;
      pending_data = leaf;
    end
    if (cycle > 4000) $fatal(1, "data Bare test timeout");
  end
  task add(input [63:0] address, input [1:0] effective_priv, input page_fault,
           input pma_fault, input final_fault, input [4:0] fault_cause, input integer delay_cycles);
    begin
      ep[put] = address;
      el[put] = {1'b0, address} + (65'b1 << protection[1:0]) - 1;
      eprotect[put] = protection; epriv[put] = effective_priv;
      erf[put] = page_fault; epma[put] = pma_fault; eff[put] = final_fault;
      ecause[put] = fault_cause; eclass[put] = pma_fault ? 3 : 0;
      epbmt[put] = 0; ead[put] = 0; latency[put] = delay_cycles; seen[put] = 0;
      put = put + 1;
    end
  endtask
  // Called on a falling edge; returns on the next falling edge after acceptance.
  task send;
    begin
      qv = 1;
      @(posedge clk);
      while (!qr) @(posedge clk);
      @(negedge clk);
      qv = 0;
    end
  endtask
  task drain;
    begin
      while (returned != put) @(negedge clk);
      @(negedge clk);
      if (raw_valid || rv || accepted != put || raw_returned != put)
        $fatal(1, "owners not fully drained");
    end
  endtask
  task invalidate;
    begin
      inv = 1;
      @(negedge clk);
      inv = 0;
    end
  endtask
  integer j, before_walks, before_accept, before_return, start_cycle;
  initial begin
    repeat (3) @(negedge clk);
    rst = 0;
    // 32 requests with alternating access attributes sustain one owner per cycle.
    start_cycle = cycle;
    for (j = 0; j < 32; j = j + 1) begin
      va = 64'h80000ff8 + j*8;
      protection = j[0] ? 4'hb : 4'h7;
      access_kind = j[0] ? 2'd2 : 2'd1;
      add(va, 3, 0, 0, 0, j[0] ? 7 : 5, BARE_LATENCY);
      qv = 1;
      @(posedge clk);
      if (!qr) $fatal(1, "Bare request II exceeded one at %0d", j);
      @(negedge clk);
    end
    qv = 0; drain;
    if (walks != 0) $fatal(1, "Bare issued a page walk");
    $display("MEASURE Bare_requests=32 raw_latency=%0d raw_II=1", BARE_LATENCY);

    // A miss owns outcome while the younger Bare waits in lookup; context
    // changes on following requests must not overwrite either owner.
    protection = 7; access_kind = 1; priv = 1;
    satp = 64'h8000000000000001; va = 64'h40001000;
    add(64'h80001000, 1, 0, 0, 1, 5, 0); send;
    priv = 3; satp = 0; va = 64'h80004000;
    add(va, 3, 0, 0, 0, 5, 0); send;
    priv = 1; satp = 64'h8000000000000001; va = 64'h40002000;
    add(64'h80002000, 1, 0, 0, 1, 5, 0); send; drain;
    before_walks = walks;
    // Old hot Sv39 lookup has priority over the next Bare request.
    va = 64'h40003000;
    add(64'h80003000, 1, 0, 0, 1, 5, 2); send;
    priv = 3; satp = 0; va = 64'h80005000;
    add(va, 3, 0, 0, 0, 5, 0); send; drain;
    if (walks != before_walks) $fatal(1, "hot Sv39/Bare mixture unexpectedly walked");

    // Four independent endpoint fields vary while held; three raw owners
    // remain admissible (overflow, outcome, lookup), with no fourth credit.
    allow_raw = 0;
    before_accept = accepted; before_return = returned;
    for (j = 0; j < 3; j = j + 1) begin
      protection = 4'(4+j); va = 64'h80006000 + j*16;
      add(va, 3, 0, 0, 0, 5, 0); send;
    end
    repeat (5) @(negedge clk);
    if (qr || accepted-before_accept != 3 || returned != before_return)
      $fatal(1, "raw overflow/outcome/lookup capacity changed");
    invalidate;
    repeat (3) @(negedge clk);
    allow_raw = 1; rr = 0;
    repeat (5) @(negedge clk);
    rr = 1; drain;

    // MPRV=1 with MPP=S must still translate; MPP=M and instruction accesses
    // bypass satp. MPP=U must preserve U permissions (this leaf is S-only).
    protection = 7; priv = 3; satp = 64'h8000000000000001;
    status = (64'b1 << 17) | (64'b1 << 11); va = 64'h40007000;
    add(64'h80007000, 1, 0, 0, 1, 5, 0); send; drain;
    status = (64'b1 << 17) | (64'd3 << 11); va = 64'h80007000;
    add(va, 3, 0, 0, 0, 5, BARE_LATENCY); send; drain;
    status = 64'b1 << 17; va = 64'h40007000;
    add(0, 0, 1, 0, 1, 13, 2); send; drain;
    status = (64'b1 << 17) | (64'b1 << 11); access_kind = 0; va = 64'h80008000;
    add(va, 3, 0, 0, 0, 5, BARE_LATENCY); send; drain;
    access_kind = 1; va = 64'h0000008000000000;
    add(0, 1, 1, 0, 1, 13, 2); send; drain;

    // PMP denial remains downstream of a short Bare transfer; M bypasses
    // unlocked entries, while an effective S owner cannot bypass them.
    status = 0; satp = 0; pmp_active = 1;
    pmp_lower[55:0] = 56'h80000000; pmp_upper[55:0] = 56'h8fffffff;
    pmp_permission[3:0] = 4'h8; va = 64'h80009000;
    add(va, 3, 0, 0, 1, 5, BARE_LATENCY); send; drain;
    pmp_permission[3:0] = 0;
    add(va, 3, 0, 0, 0, 5, BARE_LATENCY); send; drain;
    priv = 1;
    add(va, 1, 0, 0, 1, 5, BARE_LATENCY); send; drain;
    pmp_permission[3:0] = 1;
    add(va, 1, 0, 0, 0, 5, BARE_LATENCY); send; drain;
    pmp_active = 0; priv = 3;
    va = 64'h80000ffc; protection = 7;
    add(va, 3, 0, 0, 0, 5, BARE_LATENCY); send; drain;
    va = 64'hfffffffffffffffc; protection = 7;
    add(va, 3, 0, 1, 1, 5, BARE_LATENCY); send; drain;
    va = 64'h0100000080000000;
    add(va, 3, 0, 1, 1, 5, BARE_LATENCY); send; drain;

    // Invalidate a walk with a younger Bare already accepted. The result
    // drains but cannot fill TLB; the next matching request walks again.
    invalidate; priv = 1; satp = 64'h8000000000000001; va = 64'h4000a000;
    before_walks = walks;
    add(64'h8000a000, 1, 0, 0, 1, 5, 0); send;
    priv = 3; satp = 0; va = 64'h8000b000;
    add(va, 3, 0, 0, 0, 5, 0); send;
    while (walks == before_walks) @(negedge clk);
    invalidate; drain;
    priv = 1; satp = 64'h8000000000000001; va = 64'h4000a000;
    before_walks = walks;
    add(64'h8000a000, 1, 0, 0, 1, 5, 0); send; drain;
    if (walks != before_walks+1) $fatal(1, "invalidation resurrected poisoned fill");
    // Pre-admission poison follows the slow request too.
    invalidate; poison = 1;
    add(64'h8000a000, 1, 0, 0, 1, 5, 0); send; poison = 0; drain;
    before_walks = walks;
    add(64'h8000a000, 1, 0, 0, 1, 5, 0); send; drain;
    if (walks != before_walks+1) $fatal(1, "pre-poisoned request filled TLB");
    // A blocked protection packet freezes the permission decision at admission.
    priv=1;satp=0;status=0;protection=7;access_kind=1;
    va=64'h8000c000;pmp_active=1;pmp_permission=1;rr=0;
    add(va,1,0,0,0,5,BARE_LATENCY);send;
    while(!rv)@(negedge clk);
    @(negedge clk);
    pmp_permission=0;
    repeat(5)begin
      if(!rv||fault||pa!=64'h8000c000)$fatal(1,"held protection permission changed");
      @(negedge clk);
    end
    rr=1;drain;
    add(va,1,0,0,1,5,BARE_LATENCY);send;drain;
    // Lowest-index overlap decides permissions, including partial-range deny.
    pmp_active=3;pmp_permission=64'h11;
    pmp_lower[55:0]=56'h80000000;pmp_upper[55:0]=56'h80000fff;
    pmp_lower[111:56]=56'h80000000;pmp_upper[111:56]=56'h8fffffff;
    va=64'h80000ffc;
    add(va,1,0,0,1,5,BARE_LATENCY);send;drain;
    pmp_upper[55:0]=56'h8fffffff;pmp_permission=64'h01;
    add(va,1,0,0,0,5,BARE_LATENCY);send;drain;
    pmp_active=2;
    add(va,1,0,0,1,5,BARE_LATENCY);send;drain;
    $display("PROTECTION_LATENCY empty=%0d Bare_to_final=%0d II=1",PROTECTION_EMPTY,
        BARE_LATENCY+(PROTECTION_EMPTY!=0?0:1));
    if (held_cycles < 10 || measured_fast < 38 || accepted != returned)
      $fatal(1, "missing latency/backpressure/owner coverage");
    $display("[PASS] tb_r64_data_bare_fast requests=%0d raw_latency=%0d measured_fast=%0d hot_hit=%0d walks=%0d held=%0d mixed_order_MPRV_PMP_overflow_poison=1",
             returned, BARE_LATENCY, measured_fast, measured_hit, walks, held_cycles);
    $finish;
  end
endmodule
