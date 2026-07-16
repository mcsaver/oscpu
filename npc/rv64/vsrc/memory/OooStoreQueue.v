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
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W
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

  // Dispatch allocation is in program order.  Slot1 may allocate only with slot0.
  input alloc0_valid_i,
  output alloc0_ready_o,
  input [ROB_INDEX_W-1:0] alloc0_rob_idx_i,
  input alloc1_valid_i,
  output alloc1_ready_o,
  input [ROB_INDEX_W-1:0] alloc1_rob_idx_i,

  // Probe-success fill, indexed by ROB tag.  VA is retained for forwarding/tval;
  // PA is retained solely for the later pretranslated physical write.
  input fill0_valid_i,
  input [ROB_INDEX_W-1:0] fill0_rob_idx_i,
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
  // 独立第二 terminal 端口承接同拍 local exception；双端口避免把 B response
  // backpressure 组合耦合回 issue-ready，也不会丢失任一 ROB owner。
  input terminal1_valid_i,
  input [ROB_INDEX_W-1:0] terminal1_rob_idx_i,

  // ROB terminal release.  Ready includes a same-cycle terminal event so a ROB
  // writeback-to-commit bypass cannot strand the entry.
  input release_valid_i,
  input [ROB_INDEX_W-1:0] release_rob_idx_i,
  output release_ready_o,
  output release_fire_o,

  // Physical-write request.  Fire marks request_sent but never releases the entry.
  output req_valid_o,
  output [ROB_INDEX_W-1:0] req_rob_idx_o,
  output [`XLEN-1:0] req_vaddr_o,
  output [`XLEN-1:0] req_paddr_o,
  output req_attr_valid_o,
  output [1:0] req_class_o,
  output req_cacheable_o,
  output [`XLEN-1:0] req_data_o,
  output [`STRB_W-1:0] req_strb_o,
  input req_fire_i,

  // Forwarding/ordering query face.  Addresses here are original virtual/effective
  // addresses; translated mode already disables alias-unsafe forwarding.
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_valid_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_addr_valid_o,
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_addr_o,
  // Canonical physical query view for the future dual-load ordering stage.
  // Keep snoop_addr_o as the existing VA view until that stage is integrated.
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_paddr_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_attr_valid_o,
  output [(1 << ENTRY_COUNT_W) * 2 - 1:0] snoop_class_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_cacheable_o,
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_data_o,
  output [(1 << ENTRY_COUNT_W) * `STRB_W - 1:0] snoop_strb_o,
  output [(1 << ENTRY_COUNT_W) * ROB_INDEX_W - 1:0] snoop_rob_idx_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_request_sent_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_terminal_o,
  output [ENTRY_COUNT_W-1:0] snoop_head_o,
  output [ENTRY_COUNT_W:0] count_o
);

  localparam integer ENTRY_COUNT = (1 << ENTRY_COUNT_W);
  localparam [ENTRY_COUNT_W:0] ENTRY_COUNT_CONST = ENTRY_COUNT;

  reg [ENTRY_COUNT_W-1:0] head_q;
  reg [ENTRY_COUNT_W-1:0] tail_q;
  reg [ENTRY_COUNT_W:0] count_q;
  reg valid_q [0:ENTRY_COUNT-1];
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
  genvar gc;
  generate
    for (gc = 0; gc < ENTRY_COUNT; gc = gc + 1) begin : gen_cam
      assign fill_hit0_w[gc] =
          fill0_valid_i && valid_q[gc] && !filled_q[gc] &&
          (rob_idx_q[gc] == fill0_rob_idx_i);
      assign fill_hit1_w[gc] =
          fill1_valid_i && valid_q[gc] && !filled_q[gc] &&
          (rob_idx_q[gc] == fill1_rob_idx_i);
      assign terminal_hit_w[gc] =
          terminal_valid_i && valid_q[gc] && !terminal_q[gc] &&
          (rob_idx_q[gc] == terminal_rob_idx_i);
      assign terminal1_hit_w[gc] =
          terminal1_valid_i && valid_q[gc] && !terminal_q[gc] &&
          (rob_idx_q[gc] == terminal1_rob_idx_i);
    end
  endgenerate

  assign req_valid_o =
      head_valid_w && filled_q[head_q] && !request_sent_q[head_q] &&
      attr_valid_q[head_q] && !terminal_q[head_q] && rob_head_valid_i &&
      (rob_idx_q[head_q] == rob_head_idx_i);
  assign req_rob_idx_o = rob_idx_q[head_q];
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
      head_valid_w && (rob_idx_q[head_q] == release_rob_idx_i) &&
      (terminal_q[head_q] || terminal_head_now_w);
  assign release_fire_o = release_valid_i && release_ready_o;

  assign alloc0_ready_o = (count_q != ENTRY_COUNT_CONST);
  assign alloc1_ready_o =
      (count_q < (ENTRY_COUNT_CONST - {{ENTRY_COUNT_W{1'b0}}, 1'b1}));
  assign count_o = count_q;
  assign snoop_head_o = head_q;

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

  always @(posedge clk) begin
    if (rst) begin
      head_q <= {ENTRY_COUNT_W{1'b0}};
      tail_q <= {ENTRY_COUNT_W{1'b0}};
      count_q <= {(ENTRY_COUNT_W+1){1'b0}};
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
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
      end
    end else begin
      // CAM updates are accepted even on a squash cycle; a surviving older owner
      // must not lose its response, while killed entries are cleared below.
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
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
          filled_q[alloc0_idx_w] <= 1'b0;
          request_sent_q[alloc0_idx_w] <= 1'b0;
          terminal_q[alloc0_idx_w] <= 1'b0;
          attr_valid_q[alloc0_idx_w] <= 1'b0;
          class_q[alloc0_idx_w] <= `OOO_MEM_CLASS_RSVD;
          rob_idx_q[alloc0_idx_w] <= alloc0_rob_idx_i;
        end
        if (alloc1_fire_w) begin
          valid_q[alloc1_idx_w] <= 1'b1;
          filled_q[alloc1_idx_w] <= 1'b0;
          request_sent_q[alloc1_idx_w] <= 1'b0;
          terminal_q[alloc1_idx_w] <= 1'b0;
          attr_valid_q[alloc1_idx_w] <= 1'b0;
          class_q[alloc1_idx_w] <= `OOO_MEM_CLASS_RSVD;
          rob_idx_q[alloc1_idx_w] <= alloc1_rob_idx_i;
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
  integer terminal_hit_count_r;
  integer terminal1_hit_count_r;
  always @(*) begin : active_count_blk
    integer k;
    active_count_r = 0;
    terminal_hit_count_r = 0;
    terminal1_hit_count_r = 0;
    for (k = 0; k < ENTRY_COUNT; k = k + 1) begin
      if (valid_q[k] && request_sent_q[k]) active_count_r = active_count_r + 1;
      if (terminal_hit_w[k]) terminal_hit_count_r = terminal_hit_count_r + 1;
      if (terminal1_hit_w[k]) terminal1_hit_count_r = terminal1_hit_count_r + 1;
    end
  end

  always @(posedge clk) begin
    if (!rst) begin
      if (fill0_valid_i && !fill0_attr_admitted_w)
        $error("[S1-TYPED-SQ-FILL0] successful probe lacks legal typed attr @%0t",
               $time);
      if (fill1_valid_i && !fill1_attr_admitted_w)
        $error("[S1-TYPED-SQ-FILL1] successful probe lacks legal typed attr @%0t",
               $time);
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
      if (req_fire_i && !req_valid_o)
        $error("[T4N-SQ-REQ-FIRE] physical request fire without eligible head @%0t", $time);
      if (req_cacheable_o !==
          (req_attr_valid_o && (req_class_o == `OOO_MEM_CLASS_CACHED)))
        $error("[S1-TYPED-SQ-LEGACY-REQ] request Boolean diverged from typed attr @%0t",
               $time);
      if (req_valid_o &&
          ((!req_attr_valid_o) ||
           (req_class_o !== class_q[head_q]) ||
           (req_paddr_o !== paddr_q[head_q])))
        $error("[S1-TYPED-SQ-DRAIN-ECHO] drain changed head PA/class provenance @%0t",
               $time);
      if (release_valid_i && !release_ready_o)
        $error("[T4N-SQ-RELEASE] ROB released nonterminal/nonhead store rob=%0d @%0t",
               release_rob_idx_i, $time);
      if (terminal_valid_i && (terminal_hit_count_r != 1))
        $error("[T4N-SQ-TERMINAL0-HIT] terminal0 hit count=%0d rob=%0d @%0t",
               terminal_hit_count_r, terminal_rob_idx_i, $time);
      if (terminal1_valid_i && (terminal1_hit_count_r != 1))
        $error("[T4N-SQ-TERMINAL1-HIT] terminal1 hit count=%0d rob=%0d @%0t",
               terminal1_hit_count_r, terminal1_rob_idx_i, $time);
      if (terminal_valid_i && terminal1_valid_i &&
          (terminal_rob_idx_i == terminal1_rob_idx_i))
        $error("[T4N-SQ-TERMINAL-SAME-TAG] dual terminal ports named rob=%0d @%0t",
               terminal_rob_idx_i, $time);
      if (active_count_r > 1)
        $error("[T4N-SQ-AT-MOST-ONE] multiple physical write owners=%0d @%0t",
               active_count_r, $time);
      for (assert_i = 0; assert_i < ENTRY_COUNT; assert_i = assert_i + 1) begin
        if (valid_q[assert_i] && request_sent_q[assert_i] &&
            (assert_i[ENTRY_COUNT_W-1:0] != head_q))
          $error("[T4N-SQ-PHYSICAL-HEAD] accepted owner is not physical head entry=%0d @%0t",
                 assert_i, $time);
        if (flush_valid_i && flush_all_i && valid_q[assert_i] &&
            request_sent_q[assert_i] &&
            !(release_fire_o && (assert_i[ENTRY_COUNT_W-1:0] == head_q)))
          $error("[T4N-SQ-GLOBAL-NUKE] global flush overlapped live physical store rob=%0d @%0t",
                 rob_idx_q[assert_i], $time);
        if (flush_valid_i && !flush_all_i && valid_q[assert_i] &&
            request_sent_q[assert_i] && !survive_r[assert_i])
          $error("[T4N-SQ-BRANCH-SURVIVE] branch flush killed physical owner rob=%0d @%0t",
                 rob_idx_q[assert_i], $time);
      end
    end
  end
`endif

endmodule
