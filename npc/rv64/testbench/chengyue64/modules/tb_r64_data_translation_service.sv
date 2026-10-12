`timescale 1ns / 1ps
// Only the public endpoint appears here: arbitrary 9-bit client tokens, no
// LSQ/ROB hierarchy. Scoreboard identities survive stalls and caller cancellation.
module tb_r64_data_translation_service;
  localparam T = 9;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, run = 0, invalidate = 0;
  integer mode = 0, limit = 4, cycles = 0;
  integer sent[0:1], received[0:1];
  wire [1:0] valid, ready, rsp_valid, fault, needs_ad;
  reg [1:0] rsp_ready = 0;
  wire [2*T-1:0] token, rsp_token;
  wire [127:0] va, pa;
  wire [3:0] access_kind, memory_class;
  wire [7:0] protection;
  wire [9:0] cause;
  wire idle;
  wire [1:0] pv, pr, pcas, prv, prr;
  wire [111:0] paddr;
  wire [127:0] pexpected, pmask;
  reg [1:0] pending = 0;
  integer due[0:1];
  integer walks = 0, cancelled_drains = 0, held_cycles = 0, dual_returns = 0;
  reg [T-1:0] expected_token[0:1][0:31];
  reg [63:0] expected_pa[0:1][0:31];
  reg expected_fault[0:1][0:31], cancelled[0:1][0:31];
  reg [4:0] expected_cause[0:1][0:31];
  reg [1:0] held = 0;
  reg [T+72:0] held_payload[0:1];
  genvar g;
  generate for (g = 0; g < 2; g = g + 1) begin : lane
    assign valid[g] = run && sent[g] < limit;
    assign token[g*T+:T] = T'(9'h120 + g*64 + sent[g]*3);
    assign va[g*64+:64] = mode == 0 ? (64'h80000000 + g*1024 + sent[g]*8) :
        (mode == 1 ? 64'h0000008000000000 : 64'h4000);
    assign access_kind[g*2+:2] = sent[g][0] ? 2'd2 : 2'd1;
    assign protection[g*4+:4] = {sent[g][0], !sent[g][0], 2'(sent[g])};
    assign pr[g] = !pending[g] && cycles % 3 != 0;
    assign prv[g] = pending[g] && cycles >= due[g];
  end endgenerate
  R64DataTranslationService #(.TOKEN_W(T)) dut (
    .clk_i(clk), .rst_i(rst),
    .req_valid_i(valid), .req_ready_o(ready), .req_token_i(token),
    .req_vaddr_i(va), .req_access_i(access_kind), .req_protection_i(protection),
    .req_ad_update_i(2'b0), .rsp_valid_o(rsp_valid), .rsp_ready_i(rsp_ready),
    .rsp_token_o(rsp_token), .rsp_paddr_o(pa), .rsp_class_o(memory_class),
    .rsp_fault_o(fault), .rsp_needs_ad_o(needs_ad), .rsp_cause_o(cause), .idle_o(idle),
    .privilege_i(mode == 0 ? 2'd3 : 2'd1), .mstatus_i(64'b0),
    .satp_i(mode == 0 ? 64'b0 : 64'h8000000000000001), .pbmt_enable_i(1'b1),
    .pmp_active_i(16'b0), .pmp_lower_i(896'b0), .pmp_upper_i(896'b0),
    .pmp_permission_i(64'b0), .tlb_invalidate_i(invalidate),
    .tlb_all_vaddr_i(1'b1), .tlb_all_asid_i(1'b1), .tlb_vpn_i(27'b0),
    .tlb_asid_i(16'b0), .mem_valid_o(pv), .mem_ready_i(pr),
    .mem_compare_or_o(pcas), .mem_addr_o(paddr), .mem_expected_o(pexpected),
    .mem_or_mask_o(pmask), .mem_rsp_valid_i(prv), .mem_rsp_ready_o(prr),
    .mem_rdata_i(128'b0), .mem_error_i(2'b11), .mem_compare_ok_i(2'b0)
  );
  integer l, n;
  reg [T+72:0] payload;
  always @(posedge clk) begin
    if (rst) begin
      cycles <= 0; held <= 0; pending <= 0;
      for (integer a = 0; a < 2; a = a + 1) begin
        sent[a] <= 0; received[a] <= 0; due[a] <= 0;
      end
    end else begin
      cycles <= cycles + 1;
      if (&(rsp_valid & rsp_ready)) dual_returns = dual_returns + 1;
      for (integer a = 0; a < 2; a = a + 1) begin
        payload = {rsp_token[a*T+:T], pa[a*64+:64], memory_class[a*2+:2],
                   fault[a], needs_ad[a], cause[a*5+:5]};
        if (held[a] && (!rsp_valid[a] || payload !== held_payload[a]))
          $fatal(1, "translation terminal changed under backpressure lane=%0d", a);
        held[a] <= rsp_valid[a] && !rsp_ready[a];
        held_payload[a] <= payload;
        if (rsp_valid[a] && !rsp_ready[a]) held_cycles = held_cycles + 1;
        if (valid[a] && ready[a]) begin
          expected_token[a][sent[a]] = token[a*T+:T];
          expected_pa[a][sent[a]] = va[a*64+:64];
          expected_fault[a][sent[a]] = mode != 0;
          expected_cause[a][sent[a]] = mode == 1 ?
              (access_kind[a*2+:2] == 1 ? 5'd13 : 5'd15) :
              (access_kind[a*2+:2] == 1 ? 5'd5 : 5'd7);
          cancelled[a][sent[a]] = 0;
          sent[a] <= sent[a] + 1;
        end
        if (rsp_valid[a] && rsp_ready[a]) begin
          if (received[a] >= sent[a] || rsp_token[a*T+:T] !== expected_token[a][received[a]] ||
              fault[a] !== expected_fault[a][received[a]] || needs_ad[a] ||
              (fault[a] && cause[a*5+:5] !== expected_cause[a][received[a]]) ||
              (!fault[a] && (pa[a*64+:64] !== expected_pa[a][received[a]] ||
                            memory_class[a*2+:2] != 0)))
            $fatal(1, "translation scoreboard lane=%0d item=%0d token=%h expected=%h fault=%b cause=%d",
                   a, received[a], rsp_token[a*T+:T], expected_token[a][received[a]], fault[a], cause[a*5+:5]);
          if (cancelled[a][received[a]]) cancelled_drains = cancelled_drains + 1;
          received[a] <= received[a] + 1;
        end
        if (pv[a] && pr[a]) begin
          pending[a] <= 1; due[a] <= cycles + 4 + a;
          walks = walks + 1;
        end
        if (prv[a] && prr[a]) pending[a] <= 0;
      end
    end
  end
  task wait_received;
    input integer count;
    begin
      while (received[0] < count || received[1] < count) @(negedge clk);
      @(negedge clk);
      if (!idle) $fatal(1, "token leases did not drain");
    end
  endtask
  initial begin
    repeat (3) @(negedge clk);
    rst = 0; run = 1;
    while (sent[0] < 4 || sent[1] < 4) @(negedge clk);
    limit = 8;
    repeat (8) @(negedge clk);
    if (sent[0] != 4 || sent[1] != 4 || ready != 0 || idle || rsp_valid != 3)
      $fatal(1, "four token leases must bound each independent lane");
    // The caller cancels all first-wave instructions while service terminals
    // are held. The endpoint has no cancel port and must drain every token.
    for (l = 0; l < 2; l = l + 1)
      for (n = 0; n < 4; n = n + 1) cancelled[l][n] = 1;
    invalidate = 1;
    repeat (2) @(negedge clk);
    invalidate = 0; run = 0; rsp_ready = 1;
    while (received[0] < 4) @(negedge clk);
    if (received[1] != 0 || idle) $fatal(1, "lane1 lease lost during lane0 drain");
    rsp_ready = 3; run = 1; limit = 16;
    wait_received(16);
    run = 0; mode = 1; limit = 20; rsp_ready = 0;
    @(negedge clk);
    run = 1;
    repeat (12) @(negedge clk);
    rsp_ready = 3;
    wait_received(20);
    run = 0; mode = 2; limit = 24;
    @(negedge clk);
    run = 1;
    while (pending == 0) @(negedge clk);
    invalidate = 1;
    repeat (2) @(negedge clk);
    invalidate = 0;
    wait_received(24);
    if (cancelled_drains != 8 || walks != 8 || held_cycles < 16 || dual_returns == 0)
      $fatal(1, "missing token/fault/stall/cancellation coverage");
    $display("[PASS] tb_r64_data_translation_service tokens=%0d cancelled_drains=%0d pagewalk_errors=%0d held_cycles=%0d dual_returns=%0d",
             received[0]+received[1], cancelled_drains, walks, held_cycles, dual_returns);
    $finish;
  end
  initial begin
    #50000; $fatal(1, "translation service timeout");
  end
endmodule
