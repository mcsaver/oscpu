`include "define.v"

// Program-order store queue with a precise late-B terminal.
//
// A plain store has three deliberately distinct lifecycle events:
//   1. req_fire_i          : the physical write was accepted exactly once;
//   2. terminal_valid_i    : probe fault or physical-write B response arrived;
//   3. release_valid_i     : the terminal ROB entry commits and releases the SQ head.
//
// A successful translation/protection probe only fills VA/PA/data/strb.  It does
// not make the ROB entry done.  The physical write is exposed only when both the
// physical SQ head and ROB head name the same store.  The entry remains resident
// after request fire and after B, so forwarding and precise error ownership do
// not depend on a transient MIQ entry.
module OooStoreQueue #(
  parameter ENTRY_COUNT_W = 2,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + `OOO_PRODUCER_GEN_W,
  parameter OWNER_TOKEN_W = 5,
  parameter MMU_EPOCH_W = 2
)(
  input clk,
  input rst,

  // Selective branch squash keeps the non-younger prefix.  Global squash may
  // clear speculative/probe-fault entries, but must never nuke an accepted
  // physical write owner; OOO_ASSERT makes that architectural contract explicit.
  input flush_valid_i,
  input flush_all_i,
  input [ROB_INDEX_W-1:0] flush_rob_head_i,
  input [ROB_INDEX_W-1:0] flush_boundary_rob_i,

  input rob_head_valid_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,
  input [PRODUCER_ID_W-1:0] rob_head_producer_id_i,
  input rob_head_owner_open_i,
  input rob_head_launch_open_i,

  // Dispatch allocation is in program order.  Slot1 may allocate only with slot0.
  input alloc0_valid_i,
  output alloc0_ready_o,
  input [ROB_INDEX_W-1:0] alloc0_rob_idx_i,
  input [PRODUCER_ID_W-1:0] alloc0_producer_id_i,
  input alloc1_valid_i,
  output alloc1_ready_o,
  input [ROB_INDEX_W-1:0] alloc1_rob_idx_i,
  input [PRODUCER_ID_W-1:0] alloc1_producer_id_i,

  // The backend binds the exact owner once, at memory-reservation capture.
  // Dispatch allocation alone never invents or consumes an owner token.
  input owner_bind_valid_i,
  input [ROB_INDEX_W-1:0] owner_bind_rob_idx_i,
  input [PRODUCER_ID_W-1:0] owner_bind_producer_id_i,
  input [1:0] owner_bind_kind_i,
  input [OWNER_TOKEN_W-1:0] owner_bind_token_i,
  input [MMU_EPOCH_W-1:0] owner_bind_mmu_epoch_i,
  input [`XLEN-1:0] owner_bind_fault_tval_i,
  // A memory-memory issue pair binds two independently allocated STORE
  // owners in the same edge.  This is a second exact CAM update, not a
  // readiness/credit path: dispatch has already guaranteed both SQ entries.
  input owner_bind1_valid_i,
  input [ROB_INDEX_W-1:0] owner_bind1_rob_idx_i,
  input [PRODUCER_ID_W-1:0] owner_bind1_producer_id_i,
  input [1:0] owner_bind1_kind_i,
  input [OWNER_TOKEN_W-1:0] owner_bind1_token_i,
  input [MMU_EPOCH_W-1:0] owner_bind1_mmu_epoch_i,
  input [`XLEN-1:0] owner_bind1_fault_tval_i,

  // Probe-success fill, indexed by ROB tag.  VA is retained for forwarding/tval;
  // PA is retained solely for the later pretranslated physical write.
  input fill0_valid_i,
  input [ROB_INDEX_W-1:0] fill0_rob_idx_i,
  input [1:0] fill0_owner_kind_i,
  input [OWNER_TOKEN_W-1:0] fill0_owner_token_i,
  input [MMU_EPOCH_W-1:0] fill0_mmu_epoch_i,
  input [`XLEN-1:0] fill0_fault_tval_i,
  input [`XLEN-1:0] fill0_vaddr_i,
  input [`XLEN-1:0] fill0_paddr_i,
  input fill0_attr_valid_i,
  input [1:0] fill0_class_i,
  // Migration-only derived view; assertion-only, never stored or routed.
  input fill0_cacheable_i,
  input [`XLEN-1:0] fill0_data_i,
  input [`STRB_W-1:0] fill0_strb_i,
  input fill1_valid_i,
  input [ROB_INDEX_W-1:0] fill1_rob_idx_i,
  input [1:0] fill1_owner_kind_i,
  input [OWNER_TOKEN_W-1:0] fill1_owner_token_i,
  input [MMU_EPOCH_W-1:0] fill1_mmu_epoch_i,
  input [`XLEN-1:0] fill1_fault_tval_i,
  input [`XLEN-1:0] fill1_vaddr_i,
  input [`XLEN-1:0] fill1_paddr_i,
  input fill1_attr_valid_i,
  input [1:0] fill1_class_i,
  input fill1_cacheable_i,
  input [`XLEN-1:0] fill1_data_i,
  input [`STRB_W-1:0] fill1_strb_i,

  // One terminal event per store: probe fault (no request) or physical B response.
  input terminal_valid_i,
  input [ROB_INDEX_W-1:0] terminal_rob_idx_i,
  input [1:0] terminal_owner_kind_i,
  input [OWNER_TOKEN_W-1:0] terminal_owner_token_i,
  input [MMU_EPOCH_W-1:0] terminal_mmu_epoch_i,
  input [`XLEN-1:0] terminal_fault_tval_i,
  // 独立第二 terminal 端口承接同拍 local exception；双端口避免把 B response
  // backpressure 组合耦合回 issue-ready，也不会丢失任一 ROB owner。
  input terminal1_valid_i,
  input [ROB_INDEX_W-1:0] terminal1_rob_idx_i,
  input [1:0] terminal1_owner_kind_i,
  input [OWNER_TOKEN_W-1:0] terminal1_owner_token_i,
  input [MMU_EPOCH_W-1:0] terminal1_mmu_epoch_i,
  input [`XLEN-1:0] terminal1_fault_tval_i,

  // ROB terminal release.  Ready includes a same-cycle terminal event so a ROB
  // writeback-to-commit bypass cannot strand the entry.
  input release_valid_i,
  input [ROB_INDEX_W-1:0] release_rob_idx_i,
  input [PRODUCER_ID_W-1:0] release_producer_id_i,
  output release_ready_o,
  output release_fire_o,

  // Physical-write request.  Fire marks request_sent but never releases the entry.
  output req_valid_o,
  output [ROB_INDEX_W-1:0] req_rob_idx_o,
  output [PRODUCER_ID_W-1:0] req_producer_id_o,
  output [1:0] req_owner_kind_o,
  output [OWNER_TOKEN_W-1:0] req_owner_token_o,
  output [MMU_EPOCH_W-1:0] req_mmu_epoch_o,
  output [`XLEN-1:0] req_fault_tval_o,
  output [`XLEN-1:0] req_vaddr_o,
  output [`XLEN-1:0] req_paddr_o,
  output req_attr_valid_o,
  output [1:0] req_class_o,
  output req_cacheable_o,
  output [`XLEN-1:0] req_data_o,
  output [`STRB_W-1:0] req_strb_o,
  input req_fire_i,

  // Exact STORE token terminals for the owner tracker.  The backend suppresses
  // a squashed probe token still present in MIQ until bridge drop-terminal.
  output [(1 << OWNER_TOKEN_W)-1:0] owner_release_mask_o,

  // Forwarding/ordering query face.  Addresses here are original virtual/effective
  // addresses; translated mode already disables alias-unsafe forwarding.
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_valid_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_addr_valid_o,
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_addr_o,
  // Canonical physical query view.  Legacy snoop_addr_o remains the VA-only
  // compatibility observation; v8t/F3 decisions use the explicit query faces.
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_paddr_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_attr_valid_o,
  output [(1 << ENTRY_COUNT_W) * 2 - 1:0] snoop_class_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_cacheable_o,
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_data_o,
  output [(1 << ENTRY_COUNT_W) * `STRB_W - 1:0] snoop_strb_o,
  output [(1 << ENTRY_COUNT_W) * ROB_INDEX_W - 1:0] snoop_rob_idx_o,
  output [(1 << ENTRY_COUNT_W) * PRODUCER_ID_W - 1:0]
      snoop_producer_id_o,
  // Observational owner-token view for the global holder census.  Consumers
  // must qualify each token with snoop_owner_valid_o; neither signal
  // participates in allocation, forwarding, request, or release decisions.
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_owner_valid_o,
  output [(1 << ENTRY_COUNT_W) * OWNER_TOKEN_W - 1:0]
      snoop_owner_token_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_request_sent_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_terminal_o,
  output [ENTRY_COUNT_W-1:0] snoop_head_o,

  // v8t/F3 canonical final-PA byte queries.  The backend first maps each
  // bridge owner token to its exact edge-old full ProducerId; the SQ then
  // observes only registered entry state and returns one of
  // allow/forward/replay.  replay means hold the bridge-local query and try
  // again -- it is not a ROB redirect or token reallocation.
  input query0_valid_i,
  input [PRODUCER_ID_W-1:0] query0_producer_id_i,
  input [`XLEN-1:0] query0_paddr_i,
  input query0_attr_valid_i,
  input [1:0] query0_class_i,
  input [`STRB_W-1:0] query0_strb_i,
  output query0_allow_o,
  output query0_forward_o,
  output query0_replay_o,
  output [`XLEN-1:0] query0_forward_data_o,
  input query1_valid_i,
  input [PRODUCER_ID_W-1:0] query1_producer_id_i,
  input [`XLEN-1:0] query1_paddr_i,
  input query1_attr_valid_i,
  input [1:0] query1_class_i,
  input [`STRB_W-1:0] query1_strb_i,
  output query1_allow_o,
  output query1_forward_o,
  output query1_replay_o,
  output [`XLEN-1:0] query1_forward_data_o,
  output [ENTRY_COUNT_W:0] count_o
);

  localparam integer ENTRY_COUNT = (1 << ENTRY_COUNT_W);
  localparam [ENTRY_COUNT_W:0] ENTRY_COUNT_CONST = ENTRY_COUNT;
  localparam [1:0] OWNER_KIND_STORE = 2'b01;

  reg [ENTRY_COUNT_W-1:0] head_q;
  reg [ENTRY_COUNT_W-1:0] tail_q;
  reg [ENTRY_COUNT_W:0] count_q;
  reg valid_q [0:ENTRY_COUNT-1];
  reg owner_valid_q [0:ENTRY_COUNT-1];
  reg [1:0] owner_kind_q [0:ENTRY_COUNT-1];
  reg [OWNER_TOKEN_W-1:0] owner_token_q [0:ENTRY_COUNT-1];
  reg [MMU_EPOCH_W-1:0] mmu_epoch_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] fault_tval_q [0:ENTRY_COUNT-1];
  reg filled_q [0:ENTRY_COUNT-1];
  reg request_sent_q [0:ENTRY_COUNT-1];
  reg terminal_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] vaddr_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] paddr_q [0:ENTRY_COUNT-1];
  reg attr_valid_q [0:ENTRY_COUNT-1];
  reg [1:0] class_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] data_q [0:ENTRY_COUNT-1];
  reg [`STRB_W-1:0] strb_q [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] rob_idx_q [0:ENTRY_COUNT-1];
  reg [PRODUCER_ID_W-1:0] producer_id_q [0:ENTRY_COUNT-1];

  integer i;
`ifdef OOO_ASSERT
  integer assert_i;
  integer active_count_r;
`endif

  function [ROB_INDEX_W-1:0] rob_dist;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_dist = idx - head;
    end
  endfunction

  function typed_attr_admitted;
    input attr_valid;
    input [1:0] mem_class;
    begin
      typed_attr_admitted = 1'b0;
      case ({attr_valid, mem_class})
        {1'b1, `OOO_MEM_CLASS_CACHED},
        {1'b1, `OOO_MEM_CLASS_NC},
        {1'b1, `OOO_MEM_CLASS_IO}: typed_attr_admitted = 1'b1;
        default: typed_attr_admitted = 1'b0;
      endcase
    end
  endfunction

  wire fill0_attr_admitted_w =
      typed_attr_admitted(fill0_attr_valid_i, fill0_class_i);
  wire fill1_attr_admitted_w =
      typed_attr_admitted(fill1_attr_valid_i, fill1_class_i);

  wire head_valid_w = (count_q != {(ENTRY_COUNT_W+1){1'b0}}) &&
                       valid_q[head_q];
  wire alloc0_fire_w = alloc0_valid_i && alloc0_ready_o && !flush_valid_i;
  wire alloc1_fire_w = alloc1_valid_i && alloc1_ready_o && alloc0_fire_w;
  wire [ENTRY_COUNT_W-1:0] alloc0_idx_w = tail_q;
  wire [ENTRY_COUNT_W-1:0] alloc1_idx_w =
      tail_q + {{(ENTRY_COUNT_W-1){1'b0}}, 1'b1};

  wire [ENTRY_COUNT-1:0] fill_hit0_w;
  wire [ENTRY_COUNT-1:0] fill_hit1_w;
  wire [ENTRY_COUNT-1:0] terminal_hit_w;
  wire [ENTRY_COUNT-1:0] terminal1_hit_w;
  wire [ENTRY_COUNT-1:0] owner_bind_hit_w;
  wire [ENTRY_COUNT-1:0] owner_bind1_hit_w;
`ifdef OOO_ASSERT
  // fault_tval is capture provenance, not CAM identity.  These echo-only
  // comparators disappear from non-assert production logic and never gate a
  // fill, terminal, release, or request path.
  wire [ENTRY_COUNT-1:0] fill0_tval_echo_hit_w;
  wire [ENTRY_COUNT-1:0] fill1_tval_echo_hit_w;
  wire [ENTRY_COUNT-1:0] terminal_tval_echo_hit_w;
  wire [ENTRY_COUNT-1:0] terminal1_tval_echo_hit_w;
`endif
  genvar gc;
  generate
    for (gc = 0; gc < ENTRY_COUNT; gc = gc + 1) begin : gen_cam
      assign owner_bind_hit_w[gc] = owner_bind_valid_i &&
          (owner_bind_kind_i == OWNER_KIND_STORE) && valid_q[gc] &&
          !owner_valid_q[gc] &&
          (producer_id_q[gc] == owner_bind_producer_id_i) &&
          (rob_idx_q[gc] == owner_bind_rob_idx_i);
      assign owner_bind1_hit_w[gc] = owner_bind1_valid_i &&
          (owner_bind1_kind_i == OWNER_KIND_STORE) && valid_q[gc] &&
          !owner_valid_q[gc] &&
          (producer_id_q[gc] == owner_bind1_producer_id_i) &&
          (rob_idx_q[gc] == owner_bind1_rob_idx_i);
      assign fill_hit0_w[gc] =
          fill0_valid_i && valid_q[gc] && owner_valid_q[gc] &&
          !filled_q[gc] && (rob_idx_q[gc] == fill0_rob_idx_i) &&
          (owner_kind_q[gc] == fill0_owner_kind_i) &&
          (owner_token_q[gc] == fill0_owner_token_i) &&
          (mmu_epoch_q[gc] == fill0_mmu_epoch_i);
      assign fill_hit1_w[gc] =
          fill1_valid_i && valid_q[gc] && owner_valid_q[gc] &&
          !filled_q[gc] && (rob_idx_q[gc] == fill1_rob_idx_i) &&
          (owner_kind_q[gc] == fill1_owner_kind_i) &&
          (owner_token_q[gc] == fill1_owner_token_i) &&
          (mmu_epoch_q[gc] == fill1_mmu_epoch_i);
      assign terminal_hit_w[gc] =
          terminal_valid_i && valid_q[gc] && !terminal_q[gc] &&
          (rob_idx_q[gc] == terminal_rob_idx_i) &&
          ((owner_valid_q[gc] &&
            (owner_kind_q[gc] == terminal_owner_kind_i) &&
            (owner_token_q[gc] == terminal_owner_token_i) &&
            (mmu_epoch_q[gc] == terminal_mmu_epoch_i)) ||
           (owner_bind_hit_w[gc] &&
            (owner_bind_kind_i == terminal_owner_kind_i) &&
            (owner_bind_token_i == terminal_owner_token_i) &&
            (owner_bind_mmu_epoch_i == terminal_mmu_epoch_i)) ||
           (owner_bind1_hit_w[gc] &&
            (owner_bind1_kind_i == terminal_owner_kind_i) &&
            (owner_bind1_token_i == terminal_owner_token_i) &&
            (owner_bind1_mmu_epoch_i == terminal_mmu_epoch_i)));
      assign terminal1_hit_w[gc] =
          terminal1_valid_i && valid_q[gc] && !terminal_q[gc] &&
          (rob_idx_q[gc] == terminal1_rob_idx_i) &&
          ((owner_valid_q[gc] &&
            (owner_kind_q[gc] == terminal1_owner_kind_i) &&
            (owner_token_q[gc] == terminal1_owner_token_i) &&
            (mmu_epoch_q[gc] == terminal1_mmu_epoch_i)) ||
           (owner_bind_hit_w[gc] &&
            (owner_bind_kind_i == terminal1_owner_kind_i) &&
            (owner_bind_token_i == terminal1_owner_token_i) &&
            (owner_bind_mmu_epoch_i == terminal1_mmu_epoch_i)) ||
           (owner_bind1_hit_w[gc] &&
            (owner_bind1_kind_i == terminal1_owner_kind_i) &&
            (owner_bind1_token_i == terminal1_owner_token_i) &&
            (owner_bind1_mmu_epoch_i == terminal1_mmu_epoch_i)));
`ifdef OOO_ASSERT
      assign fill0_tval_echo_hit_w[gc] = fill_hit0_w[gc] &&
          (fault_tval_q[gc] == fill0_fault_tval_i);
      assign fill1_tval_echo_hit_w[gc] = fill_hit1_w[gc] &&
          (fault_tval_q[gc] == fill1_fault_tval_i);
      assign terminal_tval_echo_hit_w[gc] = terminal_hit_w[gc] &&
          ((owner_valid_q[gc] &&
            (fault_tval_q[gc] == terminal_fault_tval_i)) ||
           (owner_bind_hit_w[gc] &&
            (owner_bind_fault_tval_i == terminal_fault_tval_i)) ||
           (owner_bind1_hit_w[gc] &&
            (owner_bind1_fault_tval_i == terminal_fault_tval_i)));
      assign terminal1_tval_echo_hit_w[gc] = terminal1_hit_w[gc] &&
          ((owner_valid_q[gc] &&
            (fault_tval_q[gc] == terminal1_fault_tval_i)) ||
           (owner_bind_hit_w[gc] &&
            (owner_bind_fault_tval_i == terminal1_fault_tval_i)) ||
           (owner_bind1_hit_w[gc] &&
            (owner_bind1_fault_tval_i == terminal1_fault_tval_i)));
`endif
    end
  endgenerate

  assign req_valid_o =
      head_valid_w && owner_valid_q[head_q] && filled_q[head_q] &&
      !request_sent_q[head_q] &&
      attr_valid_q[head_q] && !terminal_q[head_q] && rob_head_valid_i &&
      rob_head_launch_open_i &&
      (producer_id_q[head_q] == rob_head_producer_id_i) &&
      (rob_idx_q[head_q] == rob_head_idx_i);
  assign req_rob_idx_o = rob_idx_q[head_q];
  assign req_producer_id_o = producer_id_q[head_q];
  assign req_owner_kind_o = owner_kind_q[head_q];
  assign req_owner_token_o = owner_token_q[head_q];
  assign req_mmu_epoch_o = mmu_epoch_q[head_q];
  assign req_fault_tval_o = fault_tval_q[head_q];
  assign req_vaddr_o = vaddr_q[head_q];
  assign req_paddr_o = paddr_q[head_q];
  assign req_attr_valid_o = head_valid_w && filled_q[head_q] &&
                            attr_valid_q[head_q];
  assign req_class_o = req_attr_valid_o ? class_q[head_q] :
                       `OOO_MEM_CLASS_RSVD;
  assign req_cacheable_o = req_attr_valid_o &&
                           (req_class_o == `OOO_MEM_CLASS_CACHED);
  assign req_data_o = data_q[head_q];
  assign req_strb_o = strb_q[head_q];

  wire terminal_head_now_w = terminal_hit_w[head_q] ||
                             terminal1_hit_w[head_q];
  assign release_ready_o =
      head_valid_w &&
      (producer_id_q[head_q] == release_producer_id_i) &&
      (rob_idx_q[head_q] == release_rob_idx_i) &&
      (terminal_q[head_q] || terminal_head_now_w);
  assign release_fire_o = release_valid_i && release_ready_o;

  assign alloc0_ready_o = (count_q != ENTRY_COUNT_CONST);
  assign alloc1_ready_o =
      (count_q < (ENTRY_COUNT_CONST - {{ENTRY_COUNT_W{1'b0}}, 1'b1}));
  assign count_o = count_q;
  assign snoop_head_o = head_q;

  // Physical byte CAM semantics:
  //   * head-to-tail traversal means a later matching entry is the younger
  //     older store and overwrites the byte selected by an earlier entry;
  //   * a not-yet-filled/invalid-typed older entry, or any older IO store,
  //     is a conservative ordering poison and therefore replays;
  //   * complete coverage may be assembled from multiple ordinary stores;
  //     partial coverage waits rather than reading memory and merging;
  //   * terminal stores are already externally complete and no longer block.
  reg query0_allow_r;
  reg query0_forward_r;
  reg query0_replay_r;
  reg [`XLEN-1:0] query0_forward_data_r;
  always @(*) begin : query0_phys_byte_cam_blk
    integer entry_i;
    integer load_byte_i;
    integer store_byte_i;
    reg [ENTRY_COUNT_W-1:0] entry_idx_r;
    reg entry_older_r;
    reg poison_r;
    reg overlap_r;
    reg [`STRB_W-1:0] covered_r;
    reg [`XLEN-1:0] load_byte_addr_r;
    reg [`XLEN-1:0] store_byte_addr_r;
    query0_allow_r = 1'b0;
    query0_forward_r = 1'b0;
    query0_replay_r = 1'b0;
    query0_forward_data_r = {`XLEN{1'b0}};
    poison_r = 1'b0;
    overlap_r = 1'b0;
    covered_r = {`STRB_W{1'b0}};
    entry_idx_r = {ENTRY_COUNT_W{1'b0}};
    entry_older_r = 1'b0;
    load_byte_addr_r = {`XLEN{1'b0}};
    store_byte_addr_r = {`XLEN{1'b0}};
    for (entry_i = 0; entry_i < ENTRY_COUNT; entry_i = entry_i + 1) begin
      entry_idx_r = head_q + entry_i[ENTRY_COUNT_W-1:0];
      entry_older_r = request_sent_q[entry_idx_r] ||
          ((producer_id_q[entry_idx_r] != query0_producer_id_i) &&
           (rob_dist(rob_idx_q[entry_idx_r], rob_head_idx_i) <
            rob_dist(query0_producer_id_i[ROB_INDEX_W-1:0],
                     rob_head_idx_i)));
      if (valid_q[entry_idx_r] && entry_older_r &&
          !terminal_q[entry_idx_r]) begin
        if (!filled_q[entry_idx_r] ||
            !typed_attr_admitted(attr_valid_q[entry_idx_r],
                                 class_q[entry_idx_r]) ||
            (strb_q[entry_idx_r] == {`STRB_W{1'b0}})) begin
          poison_r = 1'b1;
        end else if ((query0_class_i == `OOO_MEM_CLASS_IO) ||
                     (class_q[entry_idx_r] == `OOO_MEM_CLASS_IO)) begin
          poison_r = 1'b1;
        end else begin
          for (load_byte_i = 0; load_byte_i < `STRB_W;
               load_byte_i = load_byte_i + 1) begin
            for (store_byte_i = 0; store_byte_i < `STRB_W;
                 store_byte_i = store_byte_i + 1) begin
              load_byte_addr_r = query0_paddr_i + load_byte_i;
              store_byte_addr_r = paddr_q[entry_idx_r] + store_byte_i;
              if (query0_strb_i[load_byte_i] &&
                  strb_q[entry_idx_r][store_byte_i] &&
                  (load_byte_addr_r == store_byte_addr_r)) begin
                overlap_r = 1'b1;
                if (class_q[entry_idx_r] != query0_class_i) begin
                  poison_r = 1'b1;
                end else begin
                  covered_r[load_byte_i] = 1'b1;
                  query0_forward_data_r[load_byte_i*8 +: 8] =
                      data_q[entry_idx_r][store_byte_i*8 +: 8];
                end
              end
            end
          end
        end
      end
    end
    // Plain case/default is intentionally four-state fail-closed in
    // simulation: any unknown validity, age basis, poison, overlap or
    // coverage fact can only select replay (or all-zero when query-valid is
    // not exactly one), never an optimistic memory admission.
    case (query0_valid_i)
      1'b1: begin
        case ({typed_attr_admitted(query0_attr_valid_i, query0_class_i),
               (|query0_strb_i), rob_head_valid_i, poison_r})
          4'b1110: begin
            case (overlap_r)
              1'b0: query0_allow_r = 1'b1;
              1'b1: begin
                case ((covered_r & query0_strb_i) == query0_strb_i)
                  1'b1: query0_forward_r = 1'b1;
                  default: query0_replay_r = 1'b1;
                endcase
              end
              default: query0_replay_r = 1'b1;
            endcase
          end
          default: query0_replay_r = 1'b1;
        endcase
      end
      default: begin end
    endcase
  end
  assign query0_allow_o = query0_allow_r;
  assign query0_forward_o = query0_forward_r;
  assign query0_replay_o = query0_replay_r;
  assign query0_forward_data_o = query0_forward_data_r;

  reg query1_allow_r;
  reg query1_forward_r;
  reg query1_replay_r;
  reg [`XLEN-1:0] query1_forward_data_r;
  always @(*) begin : query1_phys_byte_cam_blk
    integer entry_i;
    integer load_byte_i;
    integer store_byte_i;
    reg [ENTRY_COUNT_W-1:0] entry_idx_r;
    reg entry_older_r;
    reg poison_r;
    reg overlap_r;
    reg [`STRB_W-1:0] covered_r;
    reg [`XLEN-1:0] load_byte_addr_r;
    reg [`XLEN-1:0] store_byte_addr_r;
    query1_allow_r = 1'b0;
    query1_forward_r = 1'b0;
    query1_replay_r = 1'b0;
    query1_forward_data_r = {`XLEN{1'b0}};
    poison_r = 1'b0;
    overlap_r = 1'b0;
    covered_r = {`STRB_W{1'b0}};
    entry_idx_r = {ENTRY_COUNT_W{1'b0}};
    entry_older_r = 1'b0;
    load_byte_addr_r = {`XLEN{1'b0}};
    store_byte_addr_r = {`XLEN{1'b0}};
    for (entry_i = 0; entry_i < ENTRY_COUNT; entry_i = entry_i + 1) begin
      entry_idx_r = head_q + entry_i[ENTRY_COUNT_W-1:0];
      entry_older_r = request_sent_q[entry_idx_r] ||
          ((producer_id_q[entry_idx_r] != query1_producer_id_i) &&
           (rob_dist(rob_idx_q[entry_idx_r], rob_head_idx_i) <
            rob_dist(query1_producer_id_i[ROB_INDEX_W-1:0],
                     rob_head_idx_i)));
      if (valid_q[entry_idx_r] && entry_older_r &&
          !terminal_q[entry_idx_r]) begin
        if (!filled_q[entry_idx_r] ||
            !typed_attr_admitted(attr_valid_q[entry_idx_r],
                                 class_q[entry_idx_r]) ||
            (strb_q[entry_idx_r] == {`STRB_W{1'b0}})) begin
          poison_r = 1'b1;
        end else if ((query1_class_i == `OOO_MEM_CLASS_IO) ||
                     (class_q[entry_idx_r] == `OOO_MEM_CLASS_IO)) begin
          poison_r = 1'b1;
        end else begin
          for (load_byte_i = 0; load_byte_i < `STRB_W;
               load_byte_i = load_byte_i + 1) begin
            for (store_byte_i = 0; store_byte_i < `STRB_W;
                 store_byte_i = store_byte_i + 1) begin
              load_byte_addr_r = query1_paddr_i + load_byte_i;
              store_byte_addr_r = paddr_q[entry_idx_r] + store_byte_i;
              if (query1_strb_i[load_byte_i] &&
                  strb_q[entry_idx_r][store_byte_i] &&
                  (load_byte_addr_r == store_byte_addr_r)) begin
                overlap_r = 1'b1;
                if (class_q[entry_idx_r] != query1_class_i) begin
                  poison_r = 1'b1;
                end else begin
                  covered_r[load_byte_i] = 1'b1;
                  query1_forward_data_r[load_byte_i*8 +: 8] =
                      data_q[entry_idx_r][store_byte_i*8 +: 8];
                end
              end
            end
          end
        end
      end
    end
    case (query1_valid_i)
      1'b1: begin
        case ({typed_attr_admitted(query1_attr_valid_i, query1_class_i),
               (|query1_strb_i), rob_head_valid_i, poison_r})
          4'b1110: begin
            case (overlap_r)
              1'b0: query1_allow_r = 1'b1;
              1'b1: begin
                case ((covered_r & query1_strb_i) == query1_strb_i)
                  1'b1: query1_forward_r = 1'b1;
                  default: query1_replay_r = 1'b1;
                endcase
              end
              default: query1_replay_r = 1'b1;
            endcase
          end
          default: query1_replay_r = 1'b1;
        endcase
      end
      default: begin end
    endcase
  end
  assign query1_allow_o = query1_allow_r;
  assign query1_forward_o = query1_forward_r;
  assign query1_replay_o = query1_replay_r;
  assign query1_forward_data_o = query1_forward_data_r;

  genvar gs;
  generate
    for (gs = 0; gs < ENTRY_COUNT; gs = gs + 1) begin : gen_snoop
      assign snoop_valid_o[gs] = valid_q[gs];
      assign snoop_addr_valid_o[gs] = valid_q[gs] && filled_q[gs];
      assign snoop_addr_o[gs * `XLEN +: `XLEN] = vaddr_q[gs];
      assign snoop_paddr_o[gs * `XLEN +: `XLEN] = paddr_q[gs];
      assign snoop_attr_valid_o[gs] = valid_q[gs] && filled_q[gs] &&
                                      attr_valid_q[gs];
      assign snoop_class_o[gs * 2 +: 2] = snoop_attr_valid_o[gs] ?
          class_q[gs] : `OOO_MEM_CLASS_RSVD;
      assign snoop_cacheable_o[gs] = snoop_attr_valid_o[gs] &&
          (snoop_class_o[gs * 2 +: 2] == `OOO_MEM_CLASS_CACHED);
      assign snoop_data_o[gs * `XLEN +: `XLEN] = data_q[gs];
      assign snoop_strb_o[gs * `STRB_W +: `STRB_W] = strb_q[gs];
      assign snoop_rob_idx_o[gs * ROB_INDEX_W +: ROB_INDEX_W] = rob_idx_q[gs];
      assign snoop_producer_id_o[
          gs * PRODUCER_ID_W +: PRODUCER_ID_W] = producer_id_q[gs];
      assign snoop_owner_valid_o[gs] = valid_q[gs] && owner_valid_q[gs];
      assign snoop_owner_token_o[
          gs * OWNER_TOKEN_W +: OWNER_TOKEN_W] = owner_token_q[gs];
      assign snoop_request_sent_o[gs] = valid_q[gs] && request_sent_q[gs];
      assign snoop_terminal_o[gs] = valid_q[gs] && terminal_q[gs];
    end
  endgenerate

  // Branch squash retains the non-younger prefix.  An accepted physical owner
  // is always retained defensively; assertions below prove that this exception
  // is never needed to excuse an illegal global nuke or branch-age violation.
  reg survive_r [0:ENTRY_COUNT-1];
  reg [ENTRY_COUNT_W:0] survive_count_r;
  always @(*) begin : survive_blk
    integer k;
    survive_count_r = {(ENTRY_COUNT_W+1){1'b0}};
    for (k = 0; k < ENTRY_COUNT; k = k + 1) begin
      survive_r[k] = valid_q[k] &&
          (request_sent_q[k] ||
           (!flush_all_i &&
            (rob_dist(rob_idx_q[k], flush_rob_head_i) <=
             rob_dist(flush_boundary_rob_i, flush_rob_head_i))));
      if (survive_r[k])
        survive_count_r = survive_count_r +
            {{ENTRY_COUNT_W{1'b0}}, 1'b1};
    end
  end

  wire release_in_survive_w = release_fire_o && survive_r[head_q];
  wire [ENTRY_COUNT_W:0] kept_after_release_w =
      survive_count_r - {{ENTRY_COUNT_W{1'b0}}, release_in_survive_w};
  wire [ENTRY_COUNT_W-1:0] head_after_release_w =
      head_q + {{(ENTRY_COUNT_W-1){1'b0}}, release_fire_o};

  reg [(1 << OWNER_TOKEN_W)-1:0] owner_release_mask_r;
  integer owner_release_i;
  always @(*) begin
    owner_release_mask_r = {(1 << OWNER_TOKEN_W){1'b0}};
    for (owner_release_i = 0; owner_release_i < ENTRY_COUNT;
         owner_release_i = owner_release_i + 1) begin
      if (((release_fire_o &&
            (owner_release_i[ENTRY_COUNT_W-1:0] == head_q)) ||
           (flush_valid_i && !survive_r[owner_release_i])) &&
          valid_q[owner_release_i]) begin
        if (owner_valid_q[owner_release_i])
          owner_release_mask_r[owner_token_q[owner_release_i]] = 1'b1;
        else if (owner_bind_hit_w[owner_release_i])
          owner_release_mask_r[owner_bind_token_i] = 1'b1;
        else if (owner_bind1_hit_w[owner_release_i])
          owner_release_mask_r[owner_bind1_token_i] = 1'b1;
      end
    end
  end
  assign owner_release_mask_o = owner_release_mask_r;

  always @(posedge clk) begin
    if (rst) begin
      head_q <= {ENTRY_COUNT_W{1'b0}};
      tail_q <= {ENTRY_COUNT_W{1'b0}};
      count_q <= {(ENTRY_COUNT_W+1){1'b0}};
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
        owner_valid_q[i] <= 1'b0;
        owner_kind_q[i] <= 2'b00;
        owner_token_q[i] <= {OWNER_TOKEN_W{1'b0}};
        mmu_epoch_q[i] <= {MMU_EPOCH_W{1'b0}};
        fault_tval_q[i] <= {`XLEN{1'b0}};
        filled_q[i] <= 1'b0;
        request_sent_q[i] <= 1'b0;
        terminal_q[i] <= 1'b0;
        vaddr_q[i] <= {`XLEN{1'b0}};
        paddr_q[i] <= {`XLEN{1'b0}};
        attr_valid_q[i] <= 1'b0;
        class_q[i] <= `OOO_MEM_CLASS_RSVD;
        data_q[i] <= {`XLEN{1'b0}};
        strb_q[i] <= {`STRB_W{1'b0}};
        rob_idx_q[i] <= {ROB_INDEX_W{1'b0}};
        producer_id_q[i] <= {PRODUCER_ID_W{1'b0}};
      end
    end else begin
      // CAM updates are accepted even on a squash cycle; a surviving older owner
      // must not lose its response, while killed entries are cleared below.
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        if (owner_bind_hit_w[i]) begin
          owner_valid_q[i] <= 1'b1;
          owner_kind_q[i] <= owner_bind_kind_i;
          owner_token_q[i] <= owner_bind_token_i;
          mmu_epoch_q[i] <= owner_bind_mmu_epoch_i;
          fault_tval_q[i] <= owner_bind_fault_tval_i;
        end else if (owner_bind1_hit_w[i]) begin
          owner_valid_q[i] <= 1'b1;
          owner_kind_q[i] <= owner_bind1_kind_i;
          owner_token_q[i] <= owner_bind1_token_i;
          mmu_epoch_q[i] <= owner_bind1_mmu_epoch_i;
          fault_tval_q[i] <= owner_bind1_fault_tval_i;
        end
        if (fill_hit0_w[i]) begin
          filled_q[i] <= 1'b1;
          vaddr_q[i] <= fill0_vaddr_i;
          paddr_q[i] <= fill0_paddr_i;
          attr_valid_q[i] <= fill0_attr_admitted_w;
          class_q[i] <= fill0_attr_admitted_w ? fill0_class_i :
                        `OOO_MEM_CLASS_RSVD;
          data_q[i] <= fill0_data_i;
          strb_q[i] <= fill0_strb_i;
        end else if (fill_hit1_w[i]) begin
          filled_q[i] <= 1'b1;
          vaddr_q[i] <= fill1_vaddr_i;
          paddr_q[i] <= fill1_paddr_i;
          attr_valid_q[i] <= fill1_attr_admitted_w;
          class_q[i] <= fill1_attr_admitted_w ? fill1_class_i :
                        `OOO_MEM_CLASS_RSVD;
          data_q[i] <= fill1_data_i;
          strb_q[i] <= fill1_strb_i;
        end
        if (terminal_hit_w[i] || terminal1_hit_w[i])
          terminal_q[i] <= 1'b1;
      end

      if (req_fire_i && req_valid_o)
        request_sent_q[head_q] <= 1'b1;

      if (release_fire_o) begin
        valid_q[head_q] <= 1'b0;
        owner_valid_q[head_q] <= 1'b0;
        filled_q[head_q] <= 1'b0;
        request_sent_q[head_q] <= 1'b0;
        terminal_q[head_q] <= 1'b0;
        attr_valid_q[head_q] <= 1'b0;
        class_q[head_q] <= `OOO_MEM_CLASS_RSVD;
        head_q <= head_after_release_w;
      end

      if (flush_valid_i) begin
        for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
          if (valid_q[i] && !survive_r[i]) begin
            valid_q[i] <= 1'b0;
            owner_valid_q[i] <= 1'b0;
            filled_q[i] <= 1'b0;
            request_sent_q[i] <= 1'b0;
            terminal_q[i] <= 1'b0;
            attr_valid_q[i] <= 1'b0;
            class_q[i] <= `OOO_MEM_CLASS_RSVD;
          end
        end
        head_q <= head_after_release_w;
        tail_q <= head_after_release_w +
                  kept_after_release_w[ENTRY_COUNT_W-1:0];
        count_q <= kept_after_release_w;
      end else begin
        if (alloc0_fire_w) begin
          valid_q[alloc0_idx_w] <= 1'b1;
          owner_valid_q[alloc0_idx_w] <= 1'b0;
          filled_q[alloc0_idx_w] <= 1'b0;
          request_sent_q[alloc0_idx_w] <= 1'b0;
          terminal_q[alloc0_idx_w] <= 1'b0;
          attr_valid_q[alloc0_idx_w] <= 1'b0;
          class_q[alloc0_idx_w] <= `OOO_MEM_CLASS_RSVD;
          rob_idx_q[alloc0_idx_w] <= alloc0_rob_idx_i;
          producer_id_q[alloc0_idx_w] <= alloc0_producer_id_i;
        end
        if (alloc1_fire_w) begin
          valid_q[alloc1_idx_w] <= 1'b1;
          owner_valid_q[alloc1_idx_w] <= 1'b0;
          filled_q[alloc1_idx_w] <= 1'b0;
          request_sent_q[alloc1_idx_w] <= 1'b0;
          terminal_q[alloc1_idx_w] <= 1'b0;
          attr_valid_q[alloc1_idx_w] <= 1'b0;
          class_q[alloc1_idx_w] <= `OOO_MEM_CLASS_RSVD;
          rob_idx_q[alloc1_idx_w] <= alloc1_rob_idx_i;
          producer_id_q[alloc1_idx_w] <= alloc1_producer_id_i;
        end
        tail_q <= tail_q +
            {{(ENTRY_COUNT_W-1){1'b0}}, alloc0_fire_w} +
            {{(ENTRY_COUNT_W-1){1'b0}}, alloc1_fire_w};
        count_q <= count_q +
            {{ENTRY_COUNT_W{1'b0}}, alloc0_fire_w} +
            {{ENTRY_COUNT_W{1'b0}}, alloc1_fire_w} -
            {{ENTRY_COUNT_W{1'b0}}, release_fire_o};
      end
    end
  end

`ifdef OOO_ASSERT
  integer owner_bind_hit_count_r;
  integer owner_bind1_hit_count_r;
  integer owner_bind_token_dup_count_r;
  integer owner_bind1_token_dup_count_r;
  integer owner_bind_cross_hit_count_r;
  integer fill0_hit_count_r;
  integer fill1_hit_count_r;
  integer terminal_hit_count_r;
  integer terminal1_hit_count_r;
  integer fill0_tval_echo_hit_count_r;
  integer fill1_tval_echo_hit_count_r;
  integer terminal_tval_echo_hit_count_r;
  integer terminal1_tval_echo_hit_count_r;
  always @(*) begin : active_count_blk
    integer k;
    active_count_r = 0;
    owner_bind_hit_count_r = 0;
    owner_bind1_hit_count_r = 0;
    owner_bind_token_dup_count_r = 0;
    owner_bind1_token_dup_count_r = 0;
    owner_bind_cross_hit_count_r = 0;
    fill0_hit_count_r = 0;
    fill1_hit_count_r = 0;
    terminal_hit_count_r = 0;
    terminal1_hit_count_r = 0;
    fill0_tval_echo_hit_count_r = 0;
    fill1_tval_echo_hit_count_r = 0;
    terminal_tval_echo_hit_count_r = 0;
    terminal1_tval_echo_hit_count_r = 0;
    for (k = 0; k < ENTRY_COUNT; k = k + 1) begin
      if (valid_q[k] && request_sent_q[k]) active_count_r = active_count_r + 1;
      if (owner_bind_hit_w[k]) owner_bind_hit_count_r = owner_bind_hit_count_r + 1;
      if (owner_bind1_hit_w[k])
        owner_bind1_hit_count_r = owner_bind1_hit_count_r + 1;
      if (owner_bind_hit_w[k] && owner_bind1_hit_w[k])
        owner_bind_cross_hit_count_r = owner_bind_cross_hit_count_r + 1;
      if (owner_bind_valid_i && owner_valid_q[k] &&
          (owner_token_q[k] == owner_bind_token_i))
        owner_bind_token_dup_count_r = owner_bind_token_dup_count_r + 1;
      if (owner_bind1_valid_i && owner_valid_q[k] &&
          (owner_token_q[k] == owner_bind1_token_i))
        owner_bind1_token_dup_count_r = owner_bind1_token_dup_count_r + 1;
      if (fill_hit0_w[k]) fill0_hit_count_r = fill0_hit_count_r + 1;
      if (fill_hit1_w[k]) fill1_hit_count_r = fill1_hit_count_r + 1;
      if (terminal_hit_w[k]) terminal_hit_count_r = terminal_hit_count_r + 1;
      if (terminal1_hit_w[k]) terminal1_hit_count_r = terminal1_hit_count_r + 1;
      if (fill0_tval_echo_hit_w[k])
        fill0_tval_echo_hit_count_r = fill0_tval_echo_hit_count_r + 1;
      if (fill1_tval_echo_hit_w[k])
        fill1_tval_echo_hit_count_r = fill1_tval_echo_hit_count_r + 1;
      if (terminal_tval_echo_hit_w[k])
        terminal_tval_echo_hit_count_r = terminal_tval_echo_hit_count_r + 1;
      if (terminal1_tval_echo_hit_w[k])
        terminal1_tval_echo_hit_count_r = terminal1_tval_echo_hit_count_r + 1;
    end
  end

  always @(posedge clk) begin
    if (!rst) begin
      if (owner_bind_valid_i && (owner_bind_kind_i != OWNER_KIND_STORE)) begin
        $display("[S2-G1-SQ-BIND-KIND] non-STORE owner kind=%0d @%0t",
                 owner_bind_kind_i, $time);
        $fatal;
      end
      if (owner_bind1_valid_i &&
          (owner_bind1_kind_i != OWNER_KIND_STORE)) begin
        $display("[V8P-SQ-BIND1-KIND] non-STORE owner kind=%0d @%0t",
                 owner_bind1_kind_i, $time);
        $fatal;
      end
      if (owner_bind_valid_i &&
          (owner_bind_producer_id_i[ROB_INDEX_W-1:0] !=
           owner_bind_rob_idx_i)) begin
        $display("[V8G-SQ-BIND-PID-INDEX] pid=%h raw=%h @%0t",
                 owner_bind_producer_id_i, owner_bind_rob_idx_i, $time);
        $fatal;
      end
      if (owner_bind1_valid_i &&
          (owner_bind1_producer_id_i[ROB_INDEX_W-1:0] !=
           owner_bind1_rob_idx_i)) begin
        $display("[V8P-SQ-BIND1-PID-INDEX] pid=%h raw=%h @%0t",
                 owner_bind1_producer_id_i, owner_bind1_rob_idx_i, $time);
        $fatal;
      end
      if (owner_bind_valid_i && (owner_bind_hit_count_r != 1)) begin
        $display("[S2-G1-SQ-BIND-HIT] bind hit count=%0d rob=%0d @%0t",
                 owner_bind_hit_count_r, owner_bind_rob_idx_i, $time);
        $fatal;
      end
      if (owner_bind1_valid_i && (owner_bind1_hit_count_r != 1)) begin
        $display("[V8P-SQ-BIND1-HIT] bind hit count=%0d rob=%0d @%0t",
                 owner_bind1_hit_count_r, owner_bind1_rob_idx_i, $time);
        $fatal;
      end
      if (owner_bind_valid_i && (owner_bind_token_dup_count_r != 0)) begin
        $display("[S2-G1-SQ-BIND-DUP-TOKEN] token=%0d already live @%0t",
                 owner_bind_token_i, $time);
        $fatal;
      end
      if (owner_bind1_valid_i &&
          (owner_bind1_token_dup_count_r != 0)) begin
        $display("[V8P-SQ-BIND1-DUP-TOKEN] token=%0d already live @%0t",
                 owner_bind1_token_i, $time);
        $fatal;
      end
      if (owner_bind_valid_i && owner_bind1_valid_i &&
          ((owner_bind_producer_id_i == owner_bind1_producer_id_i) ||
           (owner_bind_rob_idx_i == owner_bind1_rob_idx_i) ||
           (owner_bind_token_i == owner_bind1_token_i) ||
           (owner_bind_cross_hit_count_r != 0))) begin
        $display("[V8P-SQ-DUAL-BIND-DISTINCT] dual binds alias pid/rob/token/entry @%0t",
                 $time);
        $fatal;
      end
      if (fill0_valid_i && (fill0_hit_count_r != 1)) begin
        $display("[S2-G1-SQ-FILL0-OWNER] exact owner hit count=%0d rob=%0d @%0t",
                 fill0_hit_count_r, fill0_rob_idx_i, $time);
        $fatal;
      end
      if (fill1_valid_i && (fill1_hit_count_r != 1)) begin
        $display("[S2-G1-SQ-FILL1-OWNER] exact owner hit count=%0d rob=%0d @%0t",
                 fill1_hit_count_r, fill1_rob_idx_i, $time);
        $fatal;
      end
      if (fill0_valid_i && (fill0_hit_count_r == 1) &&
          (fill0_tval_echo_hit_count_r != 1)) begin
        $display("[S2-G1-SQ-FILL0-TVAL-ECHO] response tval drifted from bind capture @%0t",
                 $time);
        $fatal;
      end
      if (fill1_valid_i && (fill1_hit_count_r == 1) &&
          (fill1_tval_echo_hit_count_r != 1)) begin
        $display("[S2-G1-SQ-FILL1-TVAL-ECHO] response tval drifted from bind capture @%0t",
                 $time);
        $fatal;
      end
      if (fill0_valid_i && !fill0_attr_admitted_w)
        $error("[S1-TYPED-SQ-FILL0] successful probe lacks legal typed attr @%0t",
               $time);
      if (fill1_valid_i && !fill1_attr_admitted_w)
        $error("[S1-TYPED-SQ-FILL1] successful probe lacks legal typed attr @%0t",
               $time);
      if (fill0_valid_i && (fill0_strb_i == {`STRB_W{1'b0}})) begin
        $display("[V8T-SQ-FILL0-DATA-VALID] successful fill has no enabled data byte @%0t",
                 $time);
        $fatal;
      end
      if (fill1_valid_i && (fill1_strb_i == {`STRB_W{1'b0}})) begin
        $display("[V8T-SQ-FILL1-DATA-VALID] successful fill has no enabled data byte @%0t",
                 $time);
        $fatal;
      end
      if (fill0_valid_i &&
          (fill0_cacheable_i !==
           (fill0_attr_admitted_w &&
            (fill0_class_i == `OOO_MEM_CLASS_CACHED))))
        $error("[S1-TYPED-SQ-LEGACY0] fill0 Boolean diverged from typed attr @%0t",
               $time);
      if (fill1_valid_i &&
          (fill1_cacheable_i !==
           (fill1_attr_admitted_w &&
            (fill1_class_i == `OOO_MEM_CLASS_CACHED))))
        $error("[S1-TYPED-SQ-LEGACY1] fill1 Boolean diverged from typed attr @%0t",
               $time);
      if (query0_valid_i) begin
        case ({query0_allow_o, query0_forward_o, query0_replay_o})
          3'b100,
          3'b010,
          3'b001: begin end
          default: begin
            $display("[V8T-SQ-QUERY0-ONEHOT] query decision is not known one-hot @%0t",
                     $time);
            $fatal;
          end
        endcase
        if ((^query0_producer_id_i === 1'bx) ||
            (^query0_paddr_i === 1'bx) ||
            (^query0_strb_i === 1'bx)) begin
          $display("[V8T-SQ-QUERY0-KNOWN] exact query payload contains unknown bits @%0t",
                   $time);
          $fatal;
        end
      end else if (query0_allow_o || query0_forward_o || query0_replay_o) begin
        $display("[V8T-SQ-QUERY0-QUIET] invalid query produced a decision @%0t",
                 $time);
        $fatal;
      end
      if (query1_valid_i) begin
        case ({query1_allow_o, query1_forward_o, query1_replay_o})
          3'b100,
          3'b010,
          3'b001: begin end
          default: begin
            $display("[V8T-SQ-QUERY1-ONEHOT] query decision is not known one-hot @%0t",
                     $time);
            $fatal;
          end
        endcase
        if ((^query1_producer_id_i === 1'bx) ||
            (^query1_paddr_i === 1'bx) ||
            (^query1_strb_i === 1'bx)) begin
          $display("[V8T-SQ-QUERY1-KNOWN] exact query payload contains unknown bits @%0t",
                   $time);
          $fatal;
        end
      end else if (query1_allow_o || query1_forward_o || query1_replay_o) begin
        $display("[V8T-SQ-QUERY1-QUIET] invalid query produced a decision @%0t",
                 $time);
        $fatal;
      end
      if (query0_valid_i && query1_valid_i &&
          (query0_producer_id_i == query1_producer_id_i)) begin
        $display("[V8T-SQ-DUAL-QUERY-DISTINCT] two bank queries named one full PID @%0t",
                 $time);
        $fatal;
      end
      if (req_fire_i && !req_valid_o)
        $error("[T4N-SQ-REQ-FIRE] physical request fire without eligible head @%0t", $time);
      if (req_valid_o &&
          ((req_producer_id_o !== producer_id_q[head_q]) ||
           (req_producer_id_o !== rob_head_producer_id_i) ||
           !rob_head_launch_open_i)) begin
        $display("[V8G-SQ-REQ-PID] physical request escaped full-PID/head-open gate @%0t",
                 $time);
        $fatal;
      end
      if (req_cacheable_o !==
          (req_attr_valid_o && (req_class_o == `OOO_MEM_CLASS_CACHED)))
        $error("[S1-TYPED-SQ-LEGACY-REQ] request Boolean diverged from typed attr @%0t",
               $time);
      if (req_valid_o &&
          ((!req_attr_valid_o) ||
           (req_owner_kind_o !== OWNER_KIND_STORE) ||
           (req_owner_token_o !== owner_token_q[head_q]) ||
           (req_mmu_epoch_o !== mmu_epoch_q[head_q]) ||
           (req_fault_tval_o !== fault_tval_q[head_q]) ||
           (req_class_o !== class_q[head_q]) ||
           (req_paddr_o !== paddr_q[head_q])))
        $error("[S1-TYPED-SQ-DRAIN-ECHO] drain changed head PA/class provenance @%0t",
               $time);
      if (release_valid_i && !release_ready_o)
        $error("[T4N-SQ-RELEASE] ROB released nonterminal/nonhead store rob=%0d @%0t",
               release_rob_idx_i, $time);
      if (release_valid_i &&
          (release_producer_id_i[ROB_INDEX_W-1:0] !=
           release_rob_idx_i)) begin
        $display("[V8G-SQ-RELEASE-PID-INDEX] pid=%h raw=%h @%0t",
                 release_producer_id_i, release_rob_idx_i, $time);
        $fatal;
      end
      if (terminal_valid_i && (terminal_hit_count_r != 1)) begin
        $display("[T4N-SQ-TERMINAL0-HIT] terminal0 hit count=%0d rob=%0d @%0t",
                 terminal_hit_count_r, terminal_rob_idx_i, $time);
        $fatal;
      end
      if (terminal1_valid_i && (terminal1_hit_count_r != 1)) begin
        $display("[T4N-SQ-TERMINAL1-HIT] terminal1 hit count=%0d rob=%0d @%0t",
                 terminal1_hit_count_r, terminal1_rob_idx_i, $time);
        $fatal;
      end
      if (terminal_valid_i && (terminal_hit_count_r == 1) &&
          (terminal_tval_echo_hit_count_r != 1)) begin
        $display("[S2-G1-SQ-TERMINAL0-TVAL-ECHO] terminal tval drifted from bind capture @%0t",
                 $time);
        $fatal;
      end
      if (terminal1_valid_i && (terminal1_hit_count_r == 1) &&
          (terminal1_tval_echo_hit_count_r != 1)) begin
        $display("[S2-G1-SQ-TERMINAL1-TVAL-ECHO] terminal tval drifted from bind capture @%0t",
                 $time);
        $fatal;
      end
      if (terminal_valid_i && terminal1_valid_i &&
          (terminal_rob_idx_i == terminal1_rob_idx_i)) begin
        $display("[T4N-SQ-TERMINAL-SAME-TAG] dual terminal ports named rob=%0d @%0t",
                 terminal_rob_idx_i, $time);
        $fatal;
      end
      if (active_count_r > 1)
        $error("[T4N-SQ-AT-MOST-ONE] multiple physical write owners=%0d @%0t",
               active_count_r, $time);
      for (assert_i = 0; assert_i < ENTRY_COUNT; assert_i = assert_i + 1) begin
        if (valid_q[assert_i] && request_sent_q[assert_i] &&
            (assert_i[ENTRY_COUNT_W-1:0] != head_q))
          $error("[T4N-SQ-PHYSICAL-HEAD] accepted owner is not physical head entry=%0d @%0t",
                 assert_i, $time);
        if (valid_q[assert_i] && request_sent_q[assert_i] &&
            !terminal_q[assert_i] &&
            ((!rob_head_valid_i) || (!rob_head_owner_open_i) ||
             (assert_i[ENTRY_COUNT_W-1:0] != head_q) ||
             (rob_idx_q[assert_i] != rob_head_idx_i) ||
             (producer_id_q[assert_i] != rob_head_producer_id_i))) begin
          $display("[V9L-SQ-POST-LAUNCH-OWNER] issued store lost exact ROB-head ownership before B token=%0d pid=%h @%0t",
                   owner_token_q[assert_i], producer_id_q[assert_i], $time);
          $fatal;
        end
        if (valid_q[assert_i] &&
            (producer_id_q[assert_i][ROB_INDEX_W-1:0] !=
             rob_idx_q[assert_i])) begin
          $display("[V8G-SQ-PID-INDEX] entry=%0d pid=%h raw=%h @%0t",
                   assert_i, producer_id_q[assert_i], rob_idx_q[assert_i],
                   $time);
          $fatal;
        end
        if (flush_valid_i && flush_all_i && valid_q[assert_i] &&
            request_sent_q[assert_i] && !survive_r[assert_i]) begin
          $display("[T4N-SQ-GLOBAL-SURVIVE] global flush lost accepted store rob=%0d @%0t",
                   rob_idx_q[assert_i], $time);
          $fatal;
        end
        if (flush_valid_i && !flush_all_i && valid_q[assert_i] &&
            request_sent_q[assert_i] && !survive_r[assert_i])
          $error("[T4N-SQ-BRANCH-SURVIVE] branch flush killed physical owner rob=%0d @%0t",
                 rob_idx_q[assert_i], $time);
      end
    end
  end
`endif

endmodule
