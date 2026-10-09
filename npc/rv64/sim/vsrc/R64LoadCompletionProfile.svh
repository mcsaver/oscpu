// Opt-in simulation observation only: no signal drives production RTL.
// All events use the same pre-edge sample. Latency 0 therefore means capture
// at the response edge; the 16th histogram bin includes every latency >=16.
// Full canonical tags distinguish generations; kill/flush ends a tracked life.
// Opportunities are overlapping predicates, not recoverable cycle estimates.
`define R64_LOAD_L `R64_SYSTEM_HIER.core.memory.unit.lsu
`define R64_LOAD_R `R64_SYSTEM_HIER.core.backend.rob
// Fixed SystemTop uses canonical {4-bit generation, 5-bit ROB slot}.
localparam integer LP_TAG_W = 9;
localparam integer LP_ROB_W = 5;
localparam integer LP_SLOTS = 1 << LP_ROB_W;
reg [LP_SLOTS-1:0] lp_active, lp_cq_seen;
reg [LP_TAG_W-1:0] lp_tag [0:LP_SLOTS-1];
reg [63:0] lp_response_cycle [0:LP_SLOTS-1], lp_cq_cycle [0:LP_SLOTS-1];
reg [63:0] lp_response_to_cq [0:16], lp_response_to_wb [0:16], lp_cq_to_wb [0:16];
reg [63:0] lp_eligible, lp_raw_empty, lp_raw_empty_credit, lp_raw_empty_two_credit;
reg [63:0] lp_cq_captured, lp_wb_accepted, lp_cancelled, lp_tag_collision;
reg [63:0] lp_head_notdone, lp_head_notdone_unfrozen, lp_freeze;
integer lp_i, lp_lane, lp_mem_slot, lp_rob_slot, lp_bucket, lp_pending;
reg [LP_TAG_W-1:0] lp_current_tag;
reg [63:0] lp_latency;
always @(posedge clk_i) begin
  if (rst_i) begin
    lp_active = 0;
    lp_cq_seen = 0;
    lp_eligible = 0;
    lp_raw_empty = 0;
    lp_raw_empty_credit = 0;
    lp_raw_empty_two_credit = 0;
    lp_cq_captured = 0;
    lp_wb_accepted = 0;
    lp_cancelled = 0;
    lp_tag_collision = 0;
    lp_head_notdone = 0;
    lp_head_notdone_unfrozen = 0;
    lp_freeze = 0;
    for (lp_i = 0; lp_i < LP_SLOTS; lp_i = lp_i + 1) begin
      lp_tag[lp_i] = 0;
      lp_response_cycle[lp_i] = 0;
      lp_cq_cycle[lp_i] = 0;
    end
    for (lp_i = 0; lp_i < 17; lp_i = lp_i + 1) begin
      lp_response_to_cq[lp_i] = 0;
      lp_response_to_wb[lp_i] = 0;
      lp_cq_to_wb[lp_i] = 0;
    end
  end else if (run_i) begin
    if (`R64_LOAD_R.freeze_w) lp_freeze = lp_freeze + 1;
    if (`R64_LOAD_R.count_q != 0 && `R64_LOAD_R.valid_q[`R64_LOAD_R.head_q] &&
        !`R64_LOAD_R.done_q[`R64_LOAD_R.head_q]) begin
      lp_head_notdone = lp_head_notdone + 1;
      if (!`R64_LOAD_R.freeze_w) lp_head_notdone_unfrozen = lp_head_notdone_unfrozen + 1;
    end
    for (lp_i = 0; lp_i < LP_SLOTS; lp_i = lp_i + 1)
      if (lp_active[lp_i] && (`R64_LOAD_L.flush_i || `R64_LOAD_L.kill_mask_i[lp_i])) begin
        lp_active[lp_i] = 0;
        lp_cq_seen[lp_i] = 0;
        lp_cancelled = lp_cancelled + 1;
      end
    // Incoming eligibility is measured before any raw-queue bypass decision.
    for (lp_lane = 0; lp_lane < 2; lp_lane = lp_lane + 1) begin
      lp_mem_slot = int'(`R64_LOAD_L.input_response_slot_w[lp_lane]);
      if (`R64_LOAD_L.mem_rsp_valid_i[lp_lane] && `R64_LOAD_L.mem_rsp_ready_o[lp_lane] &&
          `R64_LOAD_L.input_response_live_w[lp_lane] &&
          !`R64_LOAD_L.mem_rsp_error_i[lp_lane] &&
          `R64_LOAD_L.state_q[lp_mem_slot] == `R64_LOAD_L.MEMORY &&
          `R64_LOAD_L.mem_issued_q[lp_mem_slot] &&
          !`R64_LOAD_L.store_w[lp_mem_slot] && !`R64_LOAD_L.atomic_w[lp_mem_slot] &&
          !`R64_LOAD_L.misaligned_q[lp_mem_slot] && `R64_LOAD_L.class_q[lp_mem_slot] < 2) begin
        lp_eligible = lp_eligible + 1;
        if (`R64_LOAD_L.response_queue.valid_q[lp_lane] == 0) begin
          lp_raw_empty = lp_raw_empty + 1;
          if (|`R64_LOAD_L.completion_credit_w) lp_raw_empty_credit = lp_raw_empty_credit + 1;
          if (&`R64_LOAD_L.completion_credit_w)
            lp_raw_empty_two_credit = lp_raw_empty_two_credit + 1;
        end
        lp_current_tag = `R64_LOAD_L.raw_in_tag_w[lp_lane*LP_TAG_W+:LP_TAG_W];
        lp_rob_slot = int'(lp_current_tag[LP_ROB_W-1:0]);
        if (lp_active[lp_rob_slot]) lp_tag_collision = lp_tag_collision + 1;
        lp_active[lp_rob_slot] = 1;
        lp_cq_seen[lp_rob_slot] = 0;
        lp_tag[lp_rob_slot] = lp_current_tag;
        lp_response_cycle[lp_rob_slot] = profile_cycles_q;
      end
    end
    for (lp_lane = 0; lp_lane < 2; lp_lane = lp_lane + 1) begin
      lp_current_tag = `R64_LOAD_L.completion_tag_w[lp_lane*LP_TAG_W+:LP_TAG_W];
      lp_rob_slot = int'(lp_current_tag[LP_ROB_W-1:0]);
      if (`R64_LOAD_L.completion_fire_w[lp_lane] && lp_active[lp_rob_slot] &&
          lp_tag[lp_rob_slot] == lp_current_tag && !lp_cq_seen[lp_rob_slot]) begin
        lp_latency = profile_cycles_q - lp_response_cycle[lp_rob_slot];
        lp_bucket = lp_latency >= 16 ? 16 : int'(lp_latency);
        lp_response_to_cq[lp_bucket] = lp_response_to_cq[lp_bucket] + 1;
        lp_cq_captured = lp_cq_captured + 1;
        lp_cq_cycle[lp_rob_slot] = profile_cycles_q;
        lp_cq_seen[lp_rob_slot] = 1;
      end
    end
    // wb_accept is the existing ROB ownership/cancellation authority.
    for (lp_lane = 0; lp_lane < 2; lp_lane = lp_lane + 1) begin
      lp_current_tag = `R64_LOAD_R.wb_tag_i[lp_lane*LP_TAG_W+:LP_TAG_W];
      lp_rob_slot = int'(lp_current_tag[LP_ROB_W-1:0]);
      if (`R64_LOAD_R.wb_accept_o[lp_lane] && lp_active[lp_rob_slot] &&
          lp_tag[lp_rob_slot] == lp_current_tag) begin
        lp_latency = profile_cycles_q - lp_response_cycle[lp_rob_slot];
        lp_bucket = lp_latency >= 16 ? 16 : int'(lp_latency);
        lp_response_to_wb[lp_bucket] = lp_response_to_wb[lp_bucket] + 1;
        if (lp_cq_seen[lp_rob_slot]) begin
          lp_latency = profile_cycles_q - lp_cq_cycle[lp_rob_slot];
          lp_bucket = lp_latency >= 16 ? 16 : int'(lp_latency);
          lp_cq_to_wb[lp_bucket] = lp_cq_to_wb[lp_bucket] + 1;
        end
        lp_wb_accepted = lp_wb_accepted + 1;
        lp_active[lp_rob_slot] = 0;
        lp_cq_seen[lp_rob_slot] = 0;
      end
    end
  end
end
final begin
  $display("LOAD_PROFILE eligible=%0d raw_empty=%0d raw_empty_credit=%0d raw_empty_two_credit=%0d",
           lp_eligible, lp_raw_empty, lp_raw_empty_credit, lp_raw_empty_two_credit);
  lp_pending = 0;
  for (lp_i = 0; lp_i < LP_SLOTS; lp_i = lp_i + 1)
    if (lp_active[lp_i]) lp_pending = lp_pending + 1;
  $display("LOAD_PROFILE cq_captured=%0d wb_accepted=%0d cancelled=%0d pending=%0d tag_collision=%0d",
           lp_cq_captured, lp_wb_accepted, lp_cancelled, lp_pending, lp_tag_collision);
  $display("LOAD_PROFILE head_notdone=%0d head_notdone_unfrozen=%0d freeze=%0d",
           lp_head_notdone, lp_head_notdone_unfrozen, lp_freeze);
  for (lp_i = 0; lp_i < 17; lp_i = lp_i + 1)
    $display("LOAD_PROFILE latency_bin=%0d response_to_cq=%0d response_to_wb=%0d cq_to_wb=%0d",
             lp_i, lp_response_to_cq[lp_i], lp_response_to_wb[lp_i], lp_cq_to_wb[lp_i]);
end
`undef R64_LOAD_L
`undef R64_LOAD_R
