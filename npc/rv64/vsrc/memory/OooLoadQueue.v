`include "define.v"

// Shared retire-resident load ordering queue.
//
// The two per-bank OooMemInflightQueue instances remain transport FIFOs.  This
// queue owns the architectural lifetime of every ordinary integer/FP load from
// dispatch through exact ROB retirement.  All identity comparisons use the
// complete ProducerId; a ROB index alone is never an ownership key.
module OooLoadQueue #(
  parameter integer ENTRY_N = 16,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + `OOO_PRODUCER_GEN_W,
  parameter ENTRY_INDEX_W = $clog2(ENTRY_N),
  parameter ENTRY_COUNT_W = $clog2(ENTRY_N + 1)
)(
  input clk,
  input rst,

  input flush_valid_i,
  input flush_all_i,
  input [ROB_INDEX_W-1:0] flush_rob_head_i,
  input [ROB_INDEX_W-1:0] flush_boundary_rob_i,

  // Program-order dispatch allocation.  alloc1 is a prefix extension of
  // alloc0 and may fire only when alloc0 fires.
  input alloc0_valid_i,
  output alloc0_ready_o,
  input [ROB_INDEX_W-1:0] alloc0_rob_idx_i,
  input [PRODUCER_ID_W-1:0] alloc0_producer_id_i,
  input alloc1_valid_i,
  output alloc1_ready_o,
  input [ROB_INDEX_W-1:0] alloc1_rob_idx_i,
  input [PRODUCER_ID_W-1:0] alloc1_producer_id_i,

  // Reservation/issue authorization.  These are read-only Q/CAM lookups and
  // therefore cannot introduce a response-ready to request-valid loop.
  input issue0_valid_i,
  input [PRODUCER_ID_W-1:0] issue0_producer_id_i,
  output issue0_open_o,
  input issue1_valid_i,
  input [PRODUCER_ID_W-1:0] issue1_producer_id_i,
  output issue1_open_o,

  // A launch is the exact bank request fire which creates an MIQ LOAD owner.
  // Retry launches are idempotent and retain the same LQ entry.
  input launch0_valid_i,
  input [PRODUCER_ID_W-1:0] launch0_producer_id_i,
  input launch1_valid_i,
  input [PRODUCER_ID_W-1:0] launch1_producer_id_i,

  // Final-PA query authorization and disposition recording.  OooStoreQueue is
  // the sole store-ordering oracle; the LQ records and enforces the resulting
  // load state.  Repeated attempts must preserve PA/mask/class exactly.
  input query0_valid_i,
  input [PRODUCER_ID_W-1:0] query0_producer_id_i,
  input [`XLEN-1:0] query0_paddr_i,
  input query0_attr_valid_i,
  input [1:0] query0_class_i,
  input [`STRB_W-1:0] query0_strb_i,
  output query0_open_o,
  input query0_update_i,
  input query0_allow_i,
  input query0_forward_i,
  input query0_replay_i,
  input query1_valid_i,
  input [PRODUCER_ID_W-1:0] query1_producer_id_i,
  input [`XLEN-1:0] query1_paddr_i,
  input query1_attr_valid_i,
  input [1:0] query1_class_i,
  input [`STRB_W-1:0] query1_strb_i,
  output query1_open_o,
  input query1_update_i,
  input query1_allow_i,
  input query1_forward_i,
  input query1_replay_i,

  // A successful data response requires an ordered entry.  A transport fault
  // may complete before a usable PA disposition, but still requires exact live
  // ownership.  These outputs actively qualify the bank completion paths.
  input response0_valid_i,
  input [PRODUCER_ID_W-1:0] response0_producer_id_i,
  input response0_fault_i,
  output response0_open_o,
  input response1_valid_i,
  input [PRODUCER_ID_W-1:0] response1_producer_id_i,
  input response1_fault_i,
  output response1_open_o,

  // The two formal WB ports mark architectural completion.  Non-load WB PIDs
  // simply miss this CAM and have no effect.
  input completion0_valid_i,
  input [PRODUCER_ID_W-1:0] completion0_producer_id_i,
  input completion1_valid_i,
  input [PRODUCER_ID_W-1:0] completion1_producer_id_i,

  // Lossless memory-owner terminal dequeue.  Only a killed launched entry is
  // released here; a normal entry remains resident until ROB retirement.
  input terminal0_valid_i,
  input [PRODUCER_ID_W-1:0] terminal0_producer_id_i,
  input terminal1_valid_i,
  input [PRODUCER_ID_W-1:0] terminal1_producer_id_i,

  // Retire lookup is Q-only and may precede commit.  release*_commit_i is the
  // exact ROB commit edge; an entry is freed only when lookup-ready and commit
  // coincide.  This split lets the LQ actively backpressure ROB retirement.
  input release0_valid_i,
  input [PRODUCER_ID_W-1:0] release0_producer_id_i,
  input release0_commit_i,
  // Registered-completion-only readiness for cycle-free ROB C0 pregrant.
  // release0_ready_o may also observe current formal WB for the legacy
  // same-cycle leaf behavior; this Q-only view must not.
  output release0_q_ready_o,
  output release0_ready_o,
  output release0_fire_o,
  input release1_valid_i,
  input [PRODUCER_ID_W-1:0] release1_producer_id_i,
  input release1_commit_i,
  output release1_q_ready_o,
  output release1_ready_o,
  output release1_fire_o,

  output [(1 << PRODUCER_ID_W)-1:0] producer_live_mask_o,
  output [ENTRY_COUNT_W-1:0] count_o
);

  reg valid_q [0:ENTRY_N-1];
  reg launched_q [0:ENTRY_N-1];
  reg pa_valid_q [0:ENTRY_N-1];
  reg ordered_q [0:ENTRY_N-1];
  reg completed_q [0:ENTRY_N-1];
  reg killed_q [0:ENTRY_N-1];
  // A normal terminal ends the physical memory-owner lifetime but does not
  // end ROB retire residency.  Preserve that edge history so a later recovery
  // does not create a killed tombstone waiting for a terminal that already
  // occurred.
  reg terminal_seen_q [0:ENTRY_N-1];
  reg [ROB_INDEX_W-1:0] rob_idx_q [0:ENTRY_N-1];
  reg [PRODUCER_ID_W-1:0] producer_id_q [0:ENTRY_N-1];
  reg [`XLEN-1:0] paddr_q [0:ENTRY_N-1];
  reg attr_valid_q [0:ENTRY_N-1];
  reg [1:0] class_q [0:ENTRY_N-1];
  reg [`STRB_W-1:0] strb_q [0:ENTRY_N-1];

  function [ROB_INDEX_W-1:0] rob_dist;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_dist = idx - head;
    end
  endfunction

  reg alloc0_found_r;
  reg alloc1_found_r;
  reg [ENTRY_INDEX_W-1:0] alloc0_idx_r;
  reg [ENTRY_INDEX_W-1:0] alloc1_idx_r;
  integer alloc_i;
  always @(*) begin
    alloc0_found_r = 1'b0;
    alloc1_found_r = 1'b0;
    alloc0_idx_r = {ENTRY_INDEX_W{1'b0}};
    alloc1_idx_r = {ENTRY_INDEX_W{1'b0}};
    for (alloc_i = 0; alloc_i < ENTRY_N; alloc_i = alloc_i + 1) begin
      if (!valid_q[alloc_i] && !alloc0_found_r) begin
        alloc0_found_r = 1'b1;
        alloc0_idx_r = alloc_i[ENTRY_INDEX_W-1:0];
      end else if (!valid_q[alloc_i] && !alloc1_found_r) begin
        alloc1_found_r = 1'b1;
        alloc1_idx_r = alloc_i[ENTRY_INDEX_W-1:0];
      end
    end
  end

  assign alloc0_ready_o = alloc0_found_r;
  assign alloc1_ready_o = alloc1_found_r;
  wire alloc0_fire_w = alloc0_valid_i && alloc0_ready_o && !flush_valid_i;
  wire alloc1_fire_w = alloc1_valid_i && alloc1_ready_o && alloc0_fire_w;

  wire [ENTRY_N-1:0] issue0_hit_w;
  wire [ENTRY_N-1:0] issue1_hit_w;
  wire [ENTRY_N-1:0] launch0_hit_w;
  wire [ENTRY_N-1:0] launch1_hit_w;
  wire [ENTRY_N-1:0] query0_hit_w;
  wire [ENTRY_N-1:0] query1_hit_w;
  wire [ENTRY_N-1:0] response0_hit_w;
  wire [ENTRY_N-1:0] response1_hit_w;
  wire [ENTRY_N-1:0] completion0_hit_w;
  wire [ENTRY_N-1:0] completion1_hit_w;
  wire [ENTRY_N-1:0] terminal0_hit_w;
  wire [ENTRY_N-1:0] terminal1_hit_w;
  wire [ENTRY_N-1:0] release0_match_w;
  wire [ENTRY_N-1:0] release1_match_w;
  wire [ENTRY_N-1:0] query0_meta_match_w;
  wire [ENTRY_N-1:0] query1_meta_match_w;
  wire [ENTRY_N-1:0] flush_target_w;
  wire query_pair_same_pid_w = query0_valid_i && query1_valid_i &&
      (query0_producer_id_i == query1_producer_id_i);

  genvar g;
  generate
    for (g = 0; g < ENTRY_N; g = g + 1) begin : gen_lq_cam
      assign issue0_hit_w[g] = issue0_valid_i && valid_q[g] &&
          (producer_id_q[g] == issue0_producer_id_i);
      assign issue1_hit_w[g] = issue1_valid_i && valid_q[g] &&
          (producer_id_q[g] == issue1_producer_id_i);
      assign launch0_hit_w[g] = launch0_valid_i && valid_q[g] &&
          (producer_id_q[g] == launch0_producer_id_i);
      assign launch1_hit_w[g] = launch1_valid_i && valid_q[g] &&
          (producer_id_q[g] == launch1_producer_id_i);
      assign query0_hit_w[g] = query0_valid_i && valid_q[g] &&
          (producer_id_q[g] == query0_producer_id_i);
      assign query1_hit_w[g] = query1_valid_i && valid_q[g] &&
          (producer_id_q[g] == query1_producer_id_i);
      assign response0_hit_w[g] = response0_valid_i && valid_q[g] &&
          (producer_id_q[g] == response0_producer_id_i);
      assign response1_hit_w[g] = response1_valid_i && valid_q[g] &&
          (producer_id_q[g] == response1_producer_id_i);
      assign completion0_hit_w[g] = completion0_valid_i && valid_q[g] &&
          (producer_id_q[g] == completion0_producer_id_i);
      assign completion1_hit_w[g] = completion1_valid_i && valid_q[g] &&
          (producer_id_q[g] == completion1_producer_id_i);
      assign terminal0_hit_w[g] = terminal0_valid_i && valid_q[g] &&
          (producer_id_q[g] == terminal0_producer_id_i);
      assign terminal1_hit_w[g] = terminal1_valid_i && valid_q[g] &&
          (producer_id_q[g] == terminal1_producer_id_i);
      assign release0_match_w[g] = release0_valid_i && valid_q[g] &&
          (producer_id_q[g] == release0_producer_id_i);
      assign release1_match_w[g] = release1_valid_i && valid_q[g] &&
          (producer_id_q[g] == release1_producer_id_i);
      assign query0_meta_match_w[g] = !pa_valid_q[g] ||
          ((paddr_q[g] == query0_paddr_i) &&
           (attr_valid_q[g] == query0_attr_valid_i) &&
           (class_q[g] == query0_class_i) &&
           (strb_q[g] == query0_strb_i));
      assign query1_meta_match_w[g] = !pa_valid_q[g] ||
          ((paddr_q[g] == query1_paddr_i) &&
           (attr_valid_q[g] == query1_attr_valid_i) &&
           (class_q[g] == query1_class_i) &&
           (strb_q[g] == query1_strb_i));
      assign flush_target_w[g] = flush_valid_i && valid_q[g] &&
          (flush_all_i ||
           (rob_dist(rob_idx_q[g], flush_rob_head_i) >
            rob_dist(flush_boundary_rob_i, flush_rob_head_i)));
    end
  endgenerate

  reg issue0_open_r;
  reg issue1_open_r;
  reg query0_open_r;
  reg query1_open_r;
  reg response0_open_r;
  reg response1_open_r;
  reg release0_q_ready_r;
  reg release1_q_ready_r;
  reg release0_ready_r;
  reg release1_ready_r;
  reg [(1 << PRODUCER_ID_W)-1:0] producer_live_mask_r;
  reg [ENTRY_COUNT_W-1:0] count_r;
  integer lookup_i;
  always @(*) begin
    issue0_open_r = 1'b0;
    issue1_open_r = 1'b0;
    query0_open_r = 1'b0;
    query1_open_r = 1'b0;
    response0_open_r = 1'b0;
    response1_open_r = 1'b0;
    release0_q_ready_r = 1'b0;
    release1_q_ready_r = 1'b0;
    release0_ready_r = 1'b0;
    release1_ready_r = 1'b0;
    producer_live_mask_r = {(1 << PRODUCER_ID_W){1'b0}};
    count_r = {ENTRY_COUNT_W{1'b0}};
    for (lookup_i = 0; lookup_i < ENTRY_N; lookup_i = lookup_i + 1) begin
      if (valid_q[lookup_i]) begin
        count_r = count_r + {{(ENTRY_COUNT_W-1){1'b0}}, 1'b1};
        producer_live_mask_r[producer_id_q[lookup_i]] = 1'b1;
      end
      if (issue0_hit_w[lookup_i] && !killed_q[lookup_i] &&
          !terminal_seen_q[lookup_i] &&
          !completed_q[lookup_i])
        issue0_open_r = 1'b1;
      if (issue1_hit_w[lookup_i] && !killed_q[lookup_i] &&
          !terminal_seen_q[lookup_i] &&
          !completed_q[lookup_i])
        issue1_open_r = 1'b1;
      if (query0_hit_w[lookup_i] && launched_q[lookup_i] &&
          !killed_q[lookup_i] && !terminal_seen_q[lookup_i] &&
          !completed_q[lookup_i] &&
          query0_meta_match_w[lookup_i] && !query_pair_same_pid_w)
        query0_open_r = 1'b1;
      if (query1_hit_w[lookup_i] && launched_q[lookup_i] &&
          !killed_q[lookup_i] && !terminal_seen_q[lookup_i] &&
          !completed_q[lookup_i] &&
          query1_meta_match_w[lookup_i] && !query_pair_same_pid_w)
        query1_open_r = 1'b1;
      if (response0_hit_w[lookup_i] && launched_q[lookup_i] &&
          !killed_q[lookup_i] && !terminal_seen_q[lookup_i] &&
          !completed_q[lookup_i] &&
          (ordered_q[lookup_i] || response0_fault_i))
        response0_open_r = 1'b1;
      if (response1_hit_w[lookup_i] && launched_q[lookup_i] &&
          !killed_q[lookup_i] && !terminal_seen_q[lookup_i] &&
          !completed_q[lookup_i] &&
          (ordered_q[lookup_i] || response1_fault_i))
        response1_open_r = 1'b1;
      if (release0_match_w[lookup_i] && completed_q[lookup_i])
        release0_q_ready_r = 1'b1;
      if (release1_match_w[lookup_i] && completed_q[lookup_i])
        release1_q_ready_r = 1'b1;
      if (release0_match_w[lookup_i] &&
          (completed_q[lookup_i] || completion0_hit_w[lookup_i] ||
           completion1_hit_w[lookup_i]))
        release0_ready_r = 1'b1;
      if (release1_match_w[lookup_i] &&
          (completed_q[lookup_i] || completion0_hit_w[lookup_i] ||
           completion1_hit_w[lookup_i]))
        release1_ready_r = 1'b1;
    end
  end

  assign issue0_open_o = issue0_open_r;
  assign issue1_open_o = issue1_open_r;
  assign query0_open_o = query0_open_r;
  assign query1_open_o = query1_open_r;
  assign response0_open_o = response0_open_r;
  assign response1_open_o = response1_open_r;
  assign release0_q_ready_o = release0_q_ready_r;
  assign release1_q_ready_o = release1_q_ready_r;
  assign release0_ready_o = release0_ready_r;
  assign release1_ready_o = release1_ready_r;
  assign release0_fire_o = release0_valid_i && release0_ready_o &&
      release0_commit_i;
  assign release1_fire_o = release1_valid_i && release1_ready_o &&
      release1_commit_i;
  assign producer_live_mask_o = producer_live_mask_r;
  assign count_o = count_r;

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < ENTRY_N; i = i + 1) begin
        valid_q[i] <= 1'b0;
        launched_q[i] <= 1'b0;
        pa_valid_q[i] <= 1'b0;
        ordered_q[i] <= 1'b0;
        completed_q[i] <= 1'b0;
        killed_q[i] <= 1'b0;
        terminal_seen_q[i] <= 1'b0;
        rob_idx_q[i] <= {ROB_INDEX_W{1'b0}};
        producer_id_q[i] <= {PRODUCER_ID_W{1'b0}};
        paddr_q[i] <= {`XLEN{1'b0}};
        attr_valid_q[i] <= 1'b0;
        class_q[i] <= `OOO_MEM_CLASS_RSVD;
        strb_q[i] <= {`STRB_W{1'b0}};
      end
    end else begin
      for (i = 0; i < ENTRY_N; i = i + 1) begin
        if ((release0_fire_o && release0_match_w[i]) ||
            (release1_fire_o && release1_match_w[i]) ||
            ((terminal0_hit_w[i] || terminal1_hit_w[i]) && killed_q[i])) begin
          valid_q[i] <= 1'b0;
          launched_q[i] <= 1'b0;
          pa_valid_q[i] <= 1'b0;
          ordered_q[i] <= 1'b0;
          completed_q[i] <= 1'b0;
          killed_q[i] <= 1'b0;
          terminal_seen_q[i] <= 1'b0;
          attr_valid_q[i] <= 1'b0;
          class_q[i] <= `OOO_MEM_CLASS_RSVD;
          strb_q[i] <= {`STRB_W{1'b0}};
        end else if (flush_target_w[i]) begin
          if (((launched_q[i] || launch0_hit_w[i] || launch1_hit_w[i]) &&
               !completed_q[i] && !completion0_hit_w[i] &&
               !completion1_hit_w[i] && !terminal_seen_q[i]) &&
              !(terminal0_hit_w[i] || terminal1_hit_w[i])) begin
            launched_q[i] <= 1'b1;
            completed_q[i] <= 1'b0;
            killed_q[i] <= 1'b1;
            terminal_seen_q[i] <= 1'b0;
          end else begin
            valid_q[i] <= 1'b0;
            launched_q[i] <= 1'b0;
            pa_valid_q[i] <= 1'b0;
            ordered_q[i] <= 1'b0;
            completed_q[i] <= 1'b0;
            killed_q[i] <= 1'b0;
            terminal_seen_q[i] <= 1'b0;
            attr_valid_q[i] <= 1'b0;
            class_q[i] <= `OOO_MEM_CLASS_RSVD;
            strb_q[i] <= {`STRB_W{1'b0}};
          end
        end else begin
          if (completion0_hit_w[i] || completion1_hit_w[i])
            completed_q[i] <= 1'b1;
          if (terminal0_hit_w[i] || terminal1_hit_w[i])
            terminal_seen_q[i] <= 1'b1;
          if (query0_update_i && query0_hit_w[i] && query0_open_o) begin
            pa_valid_q[i] <= 1'b1;
            paddr_q[i] <= query0_paddr_i;
            attr_valid_q[i] <= query0_attr_valid_i;
            class_q[i] <= query0_class_i;
            strb_q[i] <= query0_strb_i;
            ordered_q[i] <= !query0_replay_i &&
                            (query0_allow_i || query0_forward_i);
          end else if (query1_update_i && query1_hit_w[i] && query1_open_o) begin
            pa_valid_q[i] <= 1'b1;
            paddr_q[i] <= query1_paddr_i;
            attr_valid_q[i] <= query1_attr_valid_i;
            class_q[i] <= query1_class_i;
            strb_q[i] <= query1_strb_i;
            ordered_q[i] <= !query1_replay_i &&
                            (query1_allow_i || query1_forward_i);
          end
          if (launch0_hit_w[i] || launch1_hit_w[i])
            launched_q[i] <= 1'b1;
        end
      end

      if (alloc0_fire_w) begin
        valid_q[alloc0_idx_r] <= 1'b1;
        launched_q[alloc0_idx_r] <= 1'b0;
        pa_valid_q[alloc0_idx_r] <= 1'b0;
        ordered_q[alloc0_idx_r] <= 1'b0;
        completed_q[alloc0_idx_r] <= 1'b0;
        killed_q[alloc0_idx_r] <= 1'b0;
        terminal_seen_q[alloc0_idx_r] <= 1'b0;
        rob_idx_q[alloc0_idx_r] <= alloc0_rob_idx_i;
        producer_id_q[alloc0_idx_r] <= alloc0_producer_id_i;
        paddr_q[alloc0_idx_r] <= {`XLEN{1'b0}};
        attr_valid_q[alloc0_idx_r] <= 1'b0;
        class_q[alloc0_idx_r] <= `OOO_MEM_CLASS_RSVD;
        strb_q[alloc0_idx_r] <= {`STRB_W{1'b0}};
      end
      if (alloc1_fire_w) begin
        valid_q[alloc1_idx_r] <= 1'b1;
        launched_q[alloc1_idx_r] <= 1'b0;
        pa_valid_q[alloc1_idx_r] <= 1'b0;
        ordered_q[alloc1_idx_r] <= 1'b0;
        completed_q[alloc1_idx_r] <= 1'b0;
        killed_q[alloc1_idx_r] <= 1'b0;
        terminal_seen_q[alloc1_idx_r] <= 1'b0;
        rob_idx_q[alloc1_idx_r] <= alloc1_rob_idx_i;
        producer_id_q[alloc1_idx_r] <= alloc1_producer_id_i;
        paddr_q[alloc1_idx_r] <= {`XLEN{1'b0}};
        attr_valid_q[alloc1_idx_r] <= 1'b0;
        class_q[alloc1_idx_r] <= `OOO_MEM_CLASS_RSVD;
        strb_q[alloc1_idx_r] <= {`STRB_W{1'b0}};
      end
    end
  end

`ifdef OOO_ASSERT
  integer assert_i;
  integer assert_j;
  integer issue0_hits_r;
  integer issue1_hits_r;
  integer launch0_hits_r;
  integer launch1_hits_r;
  integer query0_hits_r;
  integer query1_hits_r;
  integer response0_hits_r;
  integer response1_hits_r;
  integer live_count_r;
  always @(*) begin
    issue0_hits_r = 0;
    issue1_hits_r = 0;
    launch0_hits_r = 0;
    launch1_hits_r = 0;
    query0_hits_r = 0;
    query1_hits_r = 0;
    response0_hits_r = 0;
    response1_hits_r = 0;
    live_count_r = 0;
    for (assert_i = 0; assert_i < ENTRY_N; assert_i = assert_i + 1) begin
      if (issue0_hit_w[assert_i]) issue0_hits_r = issue0_hits_r + 1;
      if (issue1_hit_w[assert_i]) issue1_hits_r = issue1_hits_r + 1;
      if (launch0_hit_w[assert_i]) launch0_hits_r = launch0_hits_r + 1;
      if (launch1_hit_w[assert_i]) launch1_hits_r = launch1_hits_r + 1;
      if (query0_hit_w[assert_i]) query0_hits_r = query0_hits_r + 1;
      if (query1_hit_w[assert_i]) query1_hits_r = query1_hits_r + 1;
      if (response0_hit_w[assert_i]) response0_hits_r = response0_hits_r + 1;
      if (response1_hit_w[assert_i]) response1_hits_r = response1_hits_r + 1;
      if (valid_q[assert_i]) live_count_r = live_count_r + 1;
    end
  end

  always @(posedge clk) begin
    if (!rst) begin
      if (alloc0_valid_i && alloc0_ready_o &&
          (alloc0_producer_id_i[ROB_INDEX_W-1:0] != alloc0_rob_idx_i)) begin
        $display("[V8V-LQ-ALLOC0-PID] pid=%h rob=%h @%0t",
                 alloc0_producer_id_i, alloc0_rob_idx_i, $time);
        $fatal;
      end
      if (alloc1_valid_i && alloc1_ready_o &&
          (alloc1_producer_id_i[ROB_INDEX_W-1:0] != alloc1_rob_idx_i)) begin
        $display("[V8V-LQ-ALLOC1-PID] pid=%h rob=%h @%0t",
                 alloc1_producer_id_i, alloc1_rob_idx_i, $time);
        $fatal;
      end
      if (alloc1_valid_i && !alloc0_valid_i) begin
        $display("[V8V-LQ-ALLOC-PREFIX] alloc1 without alloc0 @%0t", $time);
        $fatal;
      end
      if (launch0_valid_i && (launch0_hits_r != 1)) begin
        $display("[V8V-LQ-LAUNCH0-HIT] hits=%0d pid=%h @%0t",
                 launch0_hits_r, launch0_producer_id_i, $time);
        $fatal;
      end
      if (launch1_valid_i && (launch1_hits_r != 1)) begin
        $display("[V8V-LQ-LAUNCH1-HIT] hits=%0d pid=%h @%0t",
                 launch1_hits_r, launch1_producer_id_i, $time);
        $fatal;
      end
      if ((issue0_hits_r > 1) || (issue1_hits_r > 1) ||
          (query0_hits_r > 1) || (query1_hits_r > 1) ||
          (response0_hits_r > 1) || (response1_hits_r > 1)) begin
        $display("[V8V-LQ-CAM-ONEHOT] issue=%0d/%0d query=%0d/%0d response=%0d/%0d @%0t",
                 issue0_hits_r, issue1_hits_r, query0_hits_r,
                 query1_hits_r, response0_hits_r, response1_hits_r, $time);
        $fatal;
      end
      if (query0_update_i &&
          (({2'b00, query0_allow_i} + {2'b00, query0_forward_i} +
            {2'b00, query0_replay_i}) != 3'd1)) begin
        $display("[V8V-LQ-QUERY0-DISPOSITION] allow/fwd/replay not onehot @%0t",
                 $time);
        $fatal;
      end
      if (query1_update_i &&
          (({2'b00, query1_allow_i} + {2'b00, query1_forward_i} +
            {2'b00, query1_replay_i}) != 3'd1)) begin
        $display("[V8V-LQ-QUERY1-DISPOSITION] allow/fwd/replay not onehot @%0t",
                 $time);
        $fatal;
      end
      if (query_pair_same_pid_w &&
          (query0_open_o || query1_open_o ||
           query0_update_i || query1_update_i)) begin
        $display("[V8V-LQ-DUAL-QUERY-SAME-PID] duplicate disposition pid=%h @%0t",
                 query0_producer_id_i, $time);
        $fatal;
      end
      if (response0_valid_i && response1_valid_i &&
          (response0_producer_id_i == response1_producer_id_i)) begin
        $display("[V8V-LQ-DUAL-RESPONSE-SAME-PID] pid=%h @%0t",
                 response0_producer_id_i, $time);
        $fatal;
      end
      if (completion0_valid_i && completion1_valid_i &&
          (completion0_producer_id_i == completion1_producer_id_i)) begin
        $display("[V8V-LQ-DUAL-COMPLETION-SAME-PID] pid=%h @%0t",
                 completion0_producer_id_i, $time);
        $fatal;
      end
      if (terminal0_valid_i && terminal1_valid_i &&
          (terminal0_producer_id_i == terminal1_producer_id_i)) begin
        $display("[V8V-LQ-DUAL-TERMINAL-SAME-PID] pid=%h @%0t",
                 terminal0_producer_id_i, $time);
        $fatal;
      end
      if (release0_fire_o && release1_fire_o &&
          (release0_producer_id_i == release1_producer_id_i)) begin
        $display("[V8V-LQ-DUAL-RELEASE-SAME-PID] pid=%h @%0t",
                 release0_producer_id_i, $time);
        $fatal;
      end
      if (count_o != live_count_r[ENTRY_COUNT_W-1:0]) begin
        $display("[V8V-LQ-COUNT] count=%0d live=%0d @%0t",
                 count_o, live_count_r, $time);
        $fatal;
      end
      for (assert_i = 0; assert_i < ENTRY_N; assert_i = assert_i + 1) begin
        if (valid_q[assert_i] &&
            (^producer_id_q[assert_i] === 1'bx)) begin
          $display("[V11H-LQ-PID-KNOWN] entry=%0d pid=%h @%0t",
                   assert_i, producer_id_q[assert_i], $time);
          $fatal;
        end
        if (valid_q[assert_i] &&
            (producer_id_q[assert_i][ROB_INDEX_W-1:0] != rob_idx_q[assert_i])) begin
          $display("[V8V-LQ-PID-INDEX] entry=%0d pid=%h rob=%h @%0t",
                   assert_i, producer_id_q[assert_i], rob_idx_q[assert_i], $time);
          $fatal;
        end
        if (valid_q[assert_i] && killed_q[assert_i] &&
            (!launched_q[assert_i] || completed_q[assert_i] ||
             terminal_seen_q[assert_i])) begin
          $display("[V8V-LQ-KILLED-STATE] entry=%0d @%0t", assert_i, $time);
          $fatal;
        end
        if (valid_q[assert_i] && terminal_seen_q[assert_i] &&
            (terminal0_hit_w[assert_i] || terminal1_hit_w[assert_i])) begin
          $display("[V11H-LQ-DUP-TERMINAL] entry=%0d pid=%h @%0t",
                   assert_i, producer_id_q[assert_i], $time);
          $fatal;
        end
        for (assert_j = assert_i + 1; assert_j < ENTRY_N;
             assert_j = assert_j + 1) begin
          if (valid_q[assert_i] && valid_q[assert_j] &&
              (producer_id_q[assert_i] == producer_id_q[assert_j])) begin
            $display("[V8V-LQ-DUP-PID] entries=%0d/%0d pid=%h @%0t",
                     assert_i, assert_j, producer_id_q[assert_i], $time);
            $fatal;
          end
        end
      end
    end
  end
`endif
endmodule
