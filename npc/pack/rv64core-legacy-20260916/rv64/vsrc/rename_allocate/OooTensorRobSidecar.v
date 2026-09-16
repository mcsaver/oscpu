`include "define.v"

// Single-entry direct-NPU transaction owner.  Allocation is required to occur
// in the same cycle as the logical Tensor ROB allocation; the full ProducerId
// is then the sole identity through launch, terminal response and completion.
//
// The sidecar intentionally launches only after exact ROB-head authorization,
// source readiness and the two existing memory-drain facts.  Once cmd fires it
// is non-cancellable: recovery can only kill WAIT/OFFER, never SENT/COMPLETE.
module OooTensorRobSidecar #(
  parameter PRODUCER_ID_W = `OOO_PRODUCER_ID_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter OPCLASS_W = 8,
  parameter ERROR_W = 8
) (
  input clk,
  input rst,

  input alloc_valid_i,
  output alloc_ready_o,
  // The integrator may authorize an EMPTY-owner allocation to become the
  // architectural ROB head on this same edge.  This permission is separate
  // from alloc_ready_o so source/head/memory eligibility can never feed back
  // into dispatch acceptance.
  input alloc_launch_open_i,
  input [PRODUCER_ID_W-1:0] alloc_producer_id_i,
  input [`XLEN-1:0] alloc_pc_i,
  input [`XLEN-1:0] alloc_next_pc_i,
  input [63:0] alloc_cmd_bits_i,
  input alloc_cmd_is_64_i,
  input alloc_required_i,
  input [OPCLASS_W-1:0] alloc_opclass_i,
  input [PHY_REG_ADDR_W-1:0] alloc_src_preg_i,
  input alloc_src_ready_i,

  // A ready dependency still needs its stored PRF value.  The request stays
  // resident until the shared read port grants it; matching WB wakes bypass
  // this path with newer data.
  output src_read_valid_o,
  output [PHY_REG_ADDR_W-1:0] src_read_preg_o,
  input src_read_ready_i,
  input [`XLEN-1:0] src_read_value_i,

  input wake0_valid_i,
  input [PHY_REG_ADDR_W-1:0] wake0_preg_i,
  input [`XLEN-1:0] wake0_value_i,
  input wake1_valid_i,
  input [PHY_REG_ADDR_W-1:0] wake1_preg_i,
  input [`XLEN-1:0] wake1_value_i,

  input prelaunch_kill_valid_i,
  input [PRODUCER_ID_W-1:0] prelaunch_kill_producer_id_i,
  input prelaunch_flush_i,

  input rob_head_valid_i,
  input [PRODUCER_ID_W-1:0] rob_head_producer_id_i,
  input rob_head_launch_open_i,
  input mem_idle_i,
  input mem_retire_quiet_i,

  output cmd_valid_o,
  input cmd_ready_i,
  output [PRODUCER_ID_W-1:0] cmd_producer_id_o,
  output [63:0] cmd_bits_o,
  output [`XLEN-1:0] cmd_rs_value_o,
  output cmd_is_64_o,
  output cmd_required_o,
  output [OPCLASS_W-1:0] cmd_opclass_o,

  // The link wrapper tags the terminal response with the ProducerId sampled
  // at command fire.  A stale/mismatched terminal is drained but cannot create
  // an architectural completion.
  input terminal_valid_i,
  output terminal_ready_o,
  input [PRODUCER_ID_W-1:0] terminal_producer_id_i,
  input [`XLEN-1:0] terminal_data_i,
  input terminal_error_i,
  input [ERROR_W-1:0] terminal_error_code_i,

  output completion_valid_o,
  input completion_ready_i,
  input completion_query_match_i,
  output [PRODUCER_ID_W-1:0] completion_producer_id_o,
  output [`XLEN-1:0] completion_data_o,
  output completion_error_o,
  output [ERROR_W-1:0] completion_error_code_o,

  output owner_valid_o,
  output serialize_active_o,
  output [PRODUCER_ID_W-1:0] owner_producer_id_o,
  output [`XLEN-1:0] owner_pc_o,
  output [`XLEN-1:0] owner_next_pc_o,
  output sent_o,
  output cmd_fire_o,
  output terminal_match_o,
  output completion_fire_o,
  output stale_terminal_drop_o,
  output stale_completion_drop_o,

  output reg [31:0] issued_count_o,
  output reg [31:0] terminal_count_o,
  output reg [31:0] completion_count_o,
  output reg [31:0] wait_head_cycles_o,
  output reg [31:0] wait_drain_cycles_o,
  output reg [31:0] npu_backpressure_cycles_o,
  output reg [31:0] serialize_cycles_o
);

  localparam [2:0] OWNER_EMPTY = 3'd0;
  localparam [2:0] OWNER_WAIT = 3'd1;
  localparam [2:0] OWNER_OFFER = 3'd2;
  localparam [2:0] OWNER_SENT = 3'd3;
  localparam [2:0] OWNER_COMPLETE = 3'd4;

  reg [2:0] state_q;
  reg [PRODUCER_ID_W-1:0] producer_id_q;
  reg [`XLEN-1:0] pc_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [63:0] cmd_bits_q;
  reg cmd_is_64_q;
  reg required_q;
  reg [OPCLASS_W-1:0] opclass_q;
  reg [PHY_REG_ADDR_W-1:0] src_preg_q;
  reg src_dep_ready_q;
  reg src_operand_valid_q;
  reg [`XLEN-1:0] src_value_q;
  reg [`XLEN-1:0] completion_data_q;
  reg completion_error_q;
  reg [ERROR_W-1:0] completion_error_code_q;
  reg stale_terminal_drop_q;
  reg stale_completion_drop_q;

  wire alloc_fire_w = alloc_valid_i && alloc_ready_o;
  wire alloc_zero_source_w = alloc_cmd_is_64_i ||
      (alloc_src_preg_i == {PHY_REG_ADDR_W{1'b0}});
  // BusyTable may expose a same-cycle WB as ready.  Only the matching WB
  // payload, never the edge-old PRF read, can make that value valid at birth.
  wire alloc_wake0_match_w = !alloc_zero_source_w && wake0_valid_i &&
      (wake0_preg_i == alloc_src_preg_i);
  wire alloc_wake1_match_w = !alloc_zero_source_w && wake1_valid_i &&
      (wake1_preg_i == alloc_src_preg_i);
  wire alloc_operand_valid_w = alloc_zero_source_w ||
      alloc_wake0_match_w || alloc_wake1_match_w;
  wire [`XLEN-1:0] alloc_src_value_w = alloc_zero_source_w ?
      {`XLEN{1'b0}} :
      alloc_wake1_match_w ? wake1_value_i : wake0_value_i;
  // EMPTY-owner fall-through is intentionally narrower than resident WAIT:
  // a merely-ready dependency cannot use the edge-old PRF value.  Only a
  // zero source or matching same-edge WB supplies an authoritative operand.
  // cmd_ready_i is deliberately absent so a denied offer is captured in the
  // registered OWNER_OFFER skid without changing dispatch readiness.
  wire alloc_launch_eligible_w = alloc_fire_w && alloc_launch_open_i &&
      alloc_operand_valid_w && mem_idle_i && mem_retire_quiet_i;
  wire resident_wake0_match_w = (state_q == OWNER_WAIT) &&
      !cmd_is_64_q && (src_preg_q != {PHY_REG_ADDR_W{1'b0}}) &&
      wake0_valid_i && (wake0_preg_i == src_preg_q);
  wire resident_wake1_match_w = (state_q == OWNER_WAIT) &&
      !cmd_is_64_q && (src_preg_q != {PHY_REG_ADDR_W{1'b0}}) &&
      wake1_valid_i && (wake1_preg_i == src_preg_q);
  wire exact_head_w = rob_head_valid_i &&
                      (rob_head_producer_id_i == producer_id_q);
  wire src_read_fire_w = src_read_valid_o && src_read_ready_i;
  wire src_dep_ready_now_w = src_dep_ready_q ||
      resident_wake0_match_w || resident_wake1_match_w;
  wire src_operand_valid_now_w = src_operand_valid_q ||
      resident_wake0_match_w || resident_wake1_match_w || src_read_fire_w;
  wire [`XLEN-1:0] src_value_now_w = resident_wake1_match_w ? wake1_value_i :
      resident_wake0_match_w ? wake0_value_i :
      src_read_fire_w ? src_read_value_i : src_value_q;
  wire launch_eligible_now_w = (state_q == OWNER_WAIT) && exact_head_w &&
      rob_head_launch_open_i && src_dep_ready_now_w &&
      src_operand_valid_now_w && mem_idle_i && mem_retire_quiet_i;
  wire prelaunch_kill_match_w = prelaunch_kill_valid_i &&
      (prelaunch_kill_producer_id_i == producer_id_q) &&
      ((state_q == OWNER_WAIT) || (state_q == OWNER_OFFER));
  wire prelaunch_flush_w = prelaunch_flush_i &&
      ((state_q == OWNER_WAIT) || (state_q == OWNER_OFFER));
  wire prelaunch_cancel_w = prelaunch_kill_match_w || prelaunch_flush_w;
  wire cmd_fire_w = cmd_valid_o && cmd_ready_i;
  wire terminal_fire_w = terminal_valid_i && terminal_ready_o;
  wire terminal_match_w = terminal_fire_w &&
                          (terminal_producer_id_i == producer_id_q);
  wire completion_accept_w = completion_valid_o && completion_ready_i;
  wire completion_fire_w = completion_accept_w && completion_query_match_i;
  wire completion_stale_w = completion_accept_w && !completion_query_match_i;

`ifdef CONFIG_NPC_OOO_STATS
  // Simulation-only first-blocker attribution.  This classification observes
  // the current (pre-edge) owner state and the same prospective source facts
  // used by the WAIT fall-through.  It must never feed production control.
  localparam [4:0] ATTR_NONE = 5'd0;
  localparam [4:0] ATTR_PRELAUNCH_CANCEL = 5'd1;
  localparam [4:0] ATTR_WAIT_NOT_EXACT_HEAD = 5'd2;
  localparam [4:0] ATTR_WAIT_LAUNCH_GATE = 5'd3;
  localparam [4:0] ATTR_WAIT_SRC_DEPENDENCY = 5'd4;
  localparam [4:0] ATTR_WAIT_SRC_VALUE = 5'd5;
  localparam [4:0] ATTR_WAIT_MEM_ACTIVE = 5'd6;
  localparam [4:0] ATTR_WAIT_MEM_RETIRE = 5'd7;
  localparam [4:0] ATTR_LAUNCH_TO_OFFER = 5'd8;
  localparam [4:0] ATTR_OFFER_BACKPRESSURE = 5'd9;
  localparam [4:0] ATTR_OFFER_ACCEPT = 5'd10;
  localparam [4:0] ATTR_SENT_TERMINAL_ABSENT = 5'd11;
  localparam [4:0] ATTR_SENT_TERMINAL_STALE = 5'd12;
  localparam [4:0] ATTR_SENT_TERMINAL_ACCEPT = 5'd13;
  localparam [4:0] ATTR_COMPLETE_WB_BACKPRESSURE = 5'd14;
  localparam [4:0] ATTR_COMPLETE_STALE_DROP = 5'd15;
  localparam [4:0] ATTR_COMPLETE_WB_ACCEPT = 5'd16;
  localparam [4:0] ATTR_INVALID_STATE = 5'd17;
  localparam [4:0] ATTR_SENT_TERMINAL_COMPLETION_STALE = 5'd18;
  localparam [4:0] ATTR_SENT_TERMINAL_WB_ACCEPT = 5'd19;

  reg [4:0] attribution_class_w;
  reg [31:0] attribution_prelaunch_cancel_cycles_q;
  reg [31:0] attribution_wait_not_exact_head_cycles_q;
  reg [31:0] attribution_wait_launch_gate_cycles_q;
  reg [31:0] attribution_wait_src_dependency_cycles_q;
  reg [31:0] attribution_wait_src_value_cycles_q;
  reg [31:0] attribution_wait_mem_active_cycles_q;
  reg [31:0] attribution_wait_mem_retire_cycles_q;
  reg [31:0] attribution_launch_to_offer_cycles_q;
  reg [31:0] attribution_offer_backpressure_cycles_q;
  reg [31:0] attribution_offer_accept_cycles_q;
  reg [31:0] attribution_sent_terminal_absent_cycles_q;
  reg [31:0] attribution_sent_terminal_stale_cycles_q;
  reg [31:0] attribution_sent_terminal_accept_cycles_q;
  reg [31:0] attribution_complete_wb_backpressure_cycles_q;
  reg [31:0] attribution_complete_stale_drop_cycles_q;
  reg [31:0] attribution_complete_wb_accept_cycles_q;
  reg [31:0] attribution_invalid_state_cycles_q;
  reg [31:0] attribution_sent_terminal_completion_stale_cycles_q;
  reg [31:0] attribution_sent_terminal_wb_accept_cycles_q;
  // Event counter, not a twentieth owner-cycle attribution class.  It proves
  // that an offer accepted on an EMPTY allocation edge used the new bypass.
  reg [31:0] alloc_direct_issue_count_q;

  always @(*) begin
    attribution_class_w = ATTR_NONE;
    if (alloc_launch_eligible_w) begin
      if (!cmd_ready_i)
        attribution_class_w = ATTR_LAUNCH_TO_OFFER;
      else
        attribution_class_w = ATTR_OFFER_ACCEPT;
    end else if (state_q != OWNER_EMPTY) begin
      if (prelaunch_cancel_w) begin
        attribution_class_w = ATTR_PRELAUNCH_CANCEL;
      end else begin
        case (state_q)
          OWNER_WAIT: begin
            if (!exact_head_w)
              attribution_class_w = ATTR_WAIT_NOT_EXACT_HEAD;
            else if (!rob_head_launch_open_i)
              attribution_class_w = ATTR_WAIT_LAUNCH_GATE;
            else if (!src_dep_ready_now_w)
              attribution_class_w = ATTR_WAIT_SRC_DEPENDENCY;
            else if (!src_operand_valid_now_w)
              attribution_class_w = ATTR_WAIT_SRC_VALUE;
            else if (!mem_idle_i)
              attribution_class_w = ATTR_WAIT_MEM_ACTIVE;
            else if (!mem_retire_quiet_i)
              attribution_class_w = ATTR_WAIT_MEM_RETIRE;
            else if (!cmd_ready_i)
              attribution_class_w = ATTR_LAUNCH_TO_OFFER;
            else
              attribution_class_w = ATTR_OFFER_ACCEPT;
          end
          OWNER_OFFER: begin
            if (!cmd_ready_i)
              attribution_class_w = ATTR_OFFER_BACKPRESSURE;
            else
              attribution_class_w = ATTR_OFFER_ACCEPT;
          end
          OWNER_SENT: begin
            if (!terminal_fire_w)
              attribution_class_w = ATTR_SENT_TERMINAL_ABSENT;
            else if (!terminal_match_w)
              attribution_class_w = ATTR_SENT_TERMINAL_STALE;
            else if (!completion_accept_w)
              // The exact terminal was captured into the resident COMPLETE
              // skid because neither WB lane could accept it this edge.
              attribution_class_w = ATTR_SENT_TERMINAL_ACCEPT;
            else if (!completion_query_match_i)
              attribution_class_w = ATTR_SENT_TERMINAL_COMPLETION_STALE;
            else
              attribution_class_w = ATTR_SENT_TERMINAL_WB_ACCEPT;
          end
          OWNER_COMPLETE: begin
            if (!completion_accept_w)
              attribution_class_w = ATTR_COMPLETE_WB_BACKPRESSURE;
            else if (!completion_query_match_i)
              attribution_class_w = ATTR_COMPLETE_STALE_DROP;
            else
              attribution_class_w = ATTR_COMPLETE_WB_ACCEPT;
          end
          default: attribution_class_w = ATTR_INVALID_STATE;
        endcase
      end
    end
  end

  // The addition is intentionally modulo 2^32, matching serialize_cycles_o.
  wire [31:0] attribution_sum_w =
      attribution_prelaunch_cancel_cycles_q +
      attribution_wait_not_exact_head_cycles_q +
      attribution_wait_launch_gate_cycles_q +
      attribution_wait_src_dependency_cycles_q +
      attribution_wait_src_value_cycles_q +
      attribution_wait_mem_active_cycles_q +
      attribution_wait_mem_retire_cycles_q +
      attribution_launch_to_offer_cycles_q +
      attribution_offer_backpressure_cycles_q +
      attribution_offer_accept_cycles_q +
      attribution_sent_terminal_absent_cycles_q +
      attribution_sent_terminal_stale_cycles_q +
      attribution_sent_terminal_accept_cycles_q +
      attribution_complete_wb_backpressure_cycles_q +
      attribution_complete_stale_drop_cycles_q +
      attribution_complete_wb_accept_cycles_q +
      attribution_invalid_state_cycles_q +
      attribution_sent_terminal_completion_stale_cycles_q +
      attribution_sent_terminal_wb_accept_cycles_q;
`endif

  // A global prelaunch flush also blocks a new birth while EMPTY.  This keeps
  // the module-local allocation contract closed even when an integrator does
  // not separately gate its dispatch valid in the flush cycle.
  assign alloc_ready_o = (state_q == OWNER_EMPTY) && !rst &&
                         !prelaunch_flush_i;
  assign src_read_valid_o = (state_q == OWNER_WAIT) && src_dep_ready_q &&
      !src_operand_valid_q && !cmd_is_64_q &&
      (src_preg_q != {PHY_REG_ADDR_W{1'b0}}) && !prelaunch_cancel_w;
  assign src_read_preg_o = src_preg_q;
  // WAIT is a fall-through producer once every architectural launch condition
  // is true.  ready is deliberately absent from both valid and payload: a
  // denied transfer is captured by OWNER_OFFER as a one-entry skid holder.
  assign cmd_valid_o = (alloc_launch_eligible_w ||
                        (state_q == OWNER_OFFER) || launch_eligible_now_w) &&
                       !prelaunch_cancel_w;
  assign cmd_producer_id_o = alloc_launch_eligible_w ? alloc_producer_id_i :
                                                       producer_id_q;
  assign cmd_bits_o = alloc_launch_eligible_w ? alloc_cmd_bits_i : cmd_bits_q;
  assign cmd_rs_value_o = alloc_launch_eligible_w ? alloc_src_value_w :
      (state_q == OWNER_WAIT) ? src_value_now_w : src_value_q;
  assign cmd_is_64_o = alloc_launch_eligible_w ? alloc_cmd_is_64_i :
                                                 cmd_is_64_q;
  assign cmd_required_o = alloc_launch_eligible_w ? alloc_required_i :
                                                    required_q;
  assign cmd_opclass_o = alloc_launch_eligible_w ? alloc_opclass_i : opclass_q;

  // A single command is in flight, so every terminal beat can be drained.
  // Only the exact full-id response advances the architectural owner.
  assign terminal_ready_o = (state_q == OWNER_SENT);

  // A matching terminal is a fall-through completion producer.  valid and
  // payload are independent of completion_ready_i; a denied transfer is
  // captured into OWNER_COMPLETE, which remains the stable one-entry skid.
  // terminal_ready_o deliberately remains state-only, so the downstream ROB
  // query/WB arbitration cannot feed back into terminal acceptance.
  assign completion_valid_o = (state_q == OWNER_COMPLETE) || terminal_match_w;
  assign completion_producer_id_o = producer_id_q;
  assign completion_data_o = terminal_match_w ? terminal_data_i :
                                                completion_data_q;
  assign completion_error_o = terminal_match_w ? terminal_error_i :
                                                 completion_error_q;
  assign completion_error_code_o = terminal_match_w ? terminal_error_code_i :
                                                      completion_error_code_q;

  assign owner_valid_o = (state_q != OWNER_EMPTY);
  // This is the externally observable serialization edge.  A direct EMPTY
  // offer counts even though registered owner residency begins only after the
  // edge; owner_valid_o remains Q-only for internal live-mask correctness.
  assign serialize_active_o = owner_valid_o || alloc_launch_eligible_w;
  assign owner_producer_id_o = producer_id_q;
  assign owner_pc_o = pc_q;
  assign owner_next_pc_o = next_pc_q;
  assign sent_o = (state_q == OWNER_SENT) || (state_q == OWNER_COMPLETE);
  assign cmd_fire_o = cmd_fire_w;
  assign terminal_match_o = terminal_match_w;
  assign completion_fire_o = completion_fire_w;
  assign stale_terminal_drop_o = stale_terminal_drop_q;
  assign stale_completion_drop_o = stale_completion_drop_q;

  always @(posedge clk) begin
    if (rst) begin
      state_q <= OWNER_EMPTY;
      producer_id_q <= {PRODUCER_ID_W{1'b0}};
      pc_q <= {`XLEN{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      cmd_bits_q <= 64'b0;
      cmd_is_64_q <= 1'b0;
      required_q <= 1'b0;
      opclass_q <= {OPCLASS_W{1'b0}};
      src_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      src_dep_ready_q <= 1'b0;
      src_operand_valid_q <= 1'b0;
      src_value_q <= {`XLEN{1'b0}};
      completion_data_q <= {`XLEN{1'b0}};
      completion_error_q <= 1'b0;
      completion_error_code_q <= {ERROR_W{1'b0}};
      stale_terminal_drop_q <= 1'b0;
      stale_completion_drop_q <= 1'b0;
      issued_count_o <= 32'b0;
      terminal_count_o <= 32'b0;
      completion_count_o <= 32'b0;
      wait_head_cycles_o <= 32'b0;
      wait_drain_cycles_o <= 32'b0;
      npu_backpressure_cycles_o <= 32'b0;
      serialize_cycles_o <= 32'b0;
`ifdef CONFIG_NPC_OOO_STATS
      attribution_prelaunch_cancel_cycles_q <= 32'b0;
      attribution_wait_not_exact_head_cycles_q <= 32'b0;
      attribution_wait_launch_gate_cycles_q <= 32'b0;
      attribution_wait_src_dependency_cycles_q <= 32'b0;
      attribution_wait_src_value_cycles_q <= 32'b0;
      attribution_wait_mem_active_cycles_q <= 32'b0;
      attribution_wait_mem_retire_cycles_q <= 32'b0;
      attribution_launch_to_offer_cycles_q <= 32'b0;
      attribution_offer_backpressure_cycles_q <= 32'b0;
      attribution_offer_accept_cycles_q <= 32'b0;
      attribution_sent_terminal_absent_cycles_q <= 32'b0;
      attribution_sent_terminal_stale_cycles_q <= 32'b0;
      attribution_sent_terminal_accept_cycles_q <= 32'b0;
      attribution_complete_wb_backpressure_cycles_q <= 32'b0;
      attribution_complete_stale_drop_cycles_q <= 32'b0;
      attribution_complete_wb_accept_cycles_q <= 32'b0;
      attribution_invalid_state_cycles_q <= 32'b0;
      attribution_sent_terminal_completion_stale_cycles_q <= 32'b0;
      attribution_sent_terminal_wb_accept_cycles_q <= 32'b0;
      alloc_direct_issue_count_q <= 32'b0;
`endif
    end else begin
      stale_terminal_drop_q <= 1'b0;
      stale_completion_drop_q <= 1'b0;

      if (serialize_active_o)
        serialize_cycles_o <= serialize_cycles_o + 32'd1;
      if ((state_q == OWNER_WAIT) && !exact_head_w)
        wait_head_cycles_o <= wait_head_cycles_o + 32'd1;
      if ((state_q == OWNER_WAIT) && exact_head_w &&
          (!mem_idle_i || !mem_retire_quiet_i))
        wait_drain_cycles_o <= wait_drain_cycles_o + 32'd1;
      if (cmd_valid_o && !cmd_ready_i)
        npu_backpressure_cycles_o <= npu_backpressure_cycles_o + 32'd1;

`ifdef CONFIG_NPC_OOO_STATS
      if (alloc_launch_eligible_w && cmd_fire_w)
        alloc_direct_issue_count_q <= alloc_direct_issue_count_q + 32'd1;
      case (attribution_class_w)
        ATTR_PRELAUNCH_CANCEL:
          attribution_prelaunch_cancel_cycles_q <=
              attribution_prelaunch_cancel_cycles_q + 32'd1;
        ATTR_WAIT_NOT_EXACT_HEAD:
          attribution_wait_not_exact_head_cycles_q <=
              attribution_wait_not_exact_head_cycles_q + 32'd1;
        ATTR_WAIT_LAUNCH_GATE:
          attribution_wait_launch_gate_cycles_q <=
              attribution_wait_launch_gate_cycles_q + 32'd1;
        ATTR_WAIT_SRC_DEPENDENCY:
          attribution_wait_src_dependency_cycles_q <=
              attribution_wait_src_dependency_cycles_q + 32'd1;
        ATTR_WAIT_SRC_VALUE:
          attribution_wait_src_value_cycles_q <=
              attribution_wait_src_value_cycles_q + 32'd1;
        ATTR_WAIT_MEM_ACTIVE:
          attribution_wait_mem_active_cycles_q <=
              attribution_wait_mem_active_cycles_q + 32'd1;
        ATTR_WAIT_MEM_RETIRE:
          attribution_wait_mem_retire_cycles_q <=
              attribution_wait_mem_retire_cycles_q + 32'd1;
        ATTR_LAUNCH_TO_OFFER:
          attribution_launch_to_offer_cycles_q <=
              attribution_launch_to_offer_cycles_q + 32'd1;
        ATTR_OFFER_BACKPRESSURE:
          attribution_offer_backpressure_cycles_q <=
              attribution_offer_backpressure_cycles_q + 32'd1;
        ATTR_OFFER_ACCEPT:
          attribution_offer_accept_cycles_q <=
              attribution_offer_accept_cycles_q + 32'd1;
        ATTR_SENT_TERMINAL_ABSENT:
          attribution_sent_terminal_absent_cycles_q <=
              attribution_sent_terminal_absent_cycles_q + 32'd1;
        ATTR_SENT_TERMINAL_STALE:
          attribution_sent_terminal_stale_cycles_q <=
              attribution_sent_terminal_stale_cycles_q + 32'd1;
        ATTR_SENT_TERMINAL_ACCEPT:
          attribution_sent_terminal_accept_cycles_q <=
              attribution_sent_terminal_accept_cycles_q + 32'd1;
        ATTR_COMPLETE_WB_BACKPRESSURE:
          attribution_complete_wb_backpressure_cycles_q <=
              attribution_complete_wb_backpressure_cycles_q + 32'd1;
        ATTR_COMPLETE_STALE_DROP:
          attribution_complete_stale_drop_cycles_q <=
              attribution_complete_stale_drop_cycles_q + 32'd1;
        ATTR_COMPLETE_WB_ACCEPT:
          attribution_complete_wb_accept_cycles_q <=
              attribution_complete_wb_accept_cycles_q + 32'd1;
        ATTR_INVALID_STATE:
          attribution_invalid_state_cycles_q <=
              attribution_invalid_state_cycles_q + 32'd1;
        ATTR_SENT_TERMINAL_COMPLETION_STALE:
          attribution_sent_terminal_completion_stale_cycles_q <=
              attribution_sent_terminal_completion_stale_cycles_q + 32'd1;
        ATTR_SENT_TERMINAL_WB_ACCEPT:
          attribution_sent_terminal_wb_accept_cycles_q <=
              attribution_sent_terminal_wb_accept_cycles_q + 32'd1;
        default: begin end
      endcase
`endif

      if (alloc_fire_w) begin
        if (alloc_launch_eligible_w) begin
          if (cmd_fire_w) begin
            state_q <= OWNER_SENT;
            issued_count_o <= issued_count_o + 32'd1;
          end else begin
            state_q <= OWNER_OFFER;
          end
        end else begin
          state_q <= OWNER_WAIT;
        end
        producer_id_q <= alloc_producer_id_i;
        pc_q <= alloc_pc_i;
        next_pc_q <= alloc_next_pc_i;
        cmd_bits_q <= alloc_cmd_bits_i;
        cmd_is_64_q <= alloc_cmd_is_64_i;
        required_q <= alloc_required_i;
        opclass_q <= alloc_opclass_i;
        src_preg_q <= alloc_src_preg_i;
        src_dep_ready_q <= alloc_zero_source_w || alloc_src_ready_i ||
                           alloc_wake0_match_w || alloc_wake1_match_w;
        src_operand_valid_q <= alloc_zero_source_w ||
                               alloc_wake0_match_w || alloc_wake1_match_w;
        src_value_q <= alloc_zero_source_w ? {`XLEN{1'b0}} :
                       alloc_wake1_match_w ? wake1_value_i :
                       alloc_wake0_match_w ? wake0_value_i :
                                             {`XLEN{1'b0}};
      end else if (prelaunch_kill_match_w || prelaunch_flush_w) begin
        state_q <= OWNER_EMPTY;
        producer_id_q <= {PRODUCER_ID_W{1'b0}};
        pc_q <= {`XLEN{1'b0}};
        next_pc_q <= {`XLEN{1'b0}};
        cmd_bits_q <= 64'b0;
        cmd_is_64_q <= 1'b0;
        required_q <= 1'b0;
        opclass_q <= {OPCLASS_W{1'b0}};
        src_preg_q <= {PHY_REG_ADDR_W{1'b0}};
        src_dep_ready_q <= 1'b0;
        src_operand_valid_q <= 1'b0;
        src_value_q <= {`XLEN{1'b0}};
        completion_data_q <= {`XLEN{1'b0}};
        completion_error_q <= 1'b0;
        completion_error_code_q <= {ERROR_W{1'b0}};
      end else begin
        case (state_q)
          OWNER_WAIT: begin
            src_dep_ready_q <= src_dep_ready_now_w;
            src_operand_valid_q <= src_operand_valid_now_w;
            src_value_q <= src_value_now_w;
            // A free shared-port grant or matching wake can supply this edge's
            // fall-through payload.  A ready consumer accepts it directly;
            // otherwise the prospective value is already captured above and
            // OWNER_OFFER becomes the stable skid holder.
            if (launch_eligible_now_w) begin
              if (cmd_fire_w) begin
                state_q <= OWNER_SENT;
                issued_count_o <= issued_count_o + 32'd1;
              end else begin
                state_q <= OWNER_OFFER;
              end
            end
          end
          OWNER_OFFER: begin
            // Payload is immutable in OFFER.  Prelaunch cancellation was
            // handled above; after the command fire the owner is irrevocable.
            if (cmd_fire_w) begin
              state_q <= OWNER_SENT;
              issued_count_o <= issued_count_o + 32'd1;
            end
          end
          OWNER_SENT: begin
            if (terminal_fire_w) begin
              if (terminal_match_w) begin
                terminal_count_o <= terminal_count_o + 32'd1;
                if (completion_accept_w) begin
                  state_q <= OWNER_EMPTY;
                  producer_id_q <= {PRODUCER_ID_W{1'b0}};
                  pc_q <= {`XLEN{1'b0}};
                  next_pc_q <= {`XLEN{1'b0}};
                  cmd_bits_q <= 64'b0;
                  cmd_is_64_q <= 1'b0;
                  required_q <= 1'b0;
                  opclass_q <= {OPCLASS_W{1'b0}};
                  src_preg_q <= {PHY_REG_ADDR_W{1'b0}};
                  src_dep_ready_q <= 1'b0;
                  src_operand_valid_q <= 1'b0;
                  src_value_q <= {`XLEN{1'b0}};
                  completion_data_q <= {`XLEN{1'b0}};
                  completion_error_q <= 1'b0;
                  completion_error_code_q <= {ERROR_W{1'b0}};
                  if (completion_fire_w)
                    completion_count_o <= completion_count_o + 32'd1;
                  else
                    stale_completion_drop_q <= 1'b1;
                end else begin
                  state_q <= OWNER_COMPLETE;
                  completion_data_q <= terminal_data_i;
                  completion_error_q <= terminal_error_i;
                  completion_error_code_q <= terminal_error_code_i;
                end
              end else begin
                stale_terminal_drop_q <= 1'b1;
              end
            end
          end
          OWNER_COMPLETE: begin
            if (completion_fire_w || completion_stale_w) begin
              state_q <= OWNER_EMPTY;
              producer_id_q <= {PRODUCER_ID_W{1'b0}};
              pc_q <= {`XLEN{1'b0}};
              next_pc_q <= {`XLEN{1'b0}};
              cmd_bits_q <= 64'b0;
              cmd_is_64_q <= 1'b0;
              required_q <= 1'b0;
              opclass_q <= {OPCLASS_W{1'b0}};
              src_preg_q <= {PHY_REG_ADDR_W{1'b0}};
              src_dep_ready_q <= 1'b0;
              src_operand_valid_q <= 1'b0;
              src_value_q <= {`XLEN{1'b0}};
              completion_data_q <= {`XLEN{1'b0}};
              completion_error_q <= 1'b0;
              completion_error_code_q <= {ERROR_W{1'b0}};
              if (completion_fire_w)
                completion_count_o <= completion_count_o + 32'd1;
              else
                stale_completion_drop_q <= 1'b1;
            end
          end
          default: begin
            state_q <= OWNER_EMPTY;
            producer_id_q <= {PRODUCER_ID_W{1'b0}};
            pc_q <= {`XLEN{1'b0}};
            next_pc_q <= {`XLEN{1'b0}};
            cmd_bits_q <= 64'b0;
            cmd_is_64_q <= 1'b0;
            required_q <= 1'b0;
            opclass_q <= {OPCLASS_W{1'b0}};
            src_preg_q <= {PHY_REG_ADDR_W{1'b0}};
            src_dep_ready_q <= 1'b0;
            src_operand_valid_q <= 1'b0;
            src_value_q <= {`XLEN{1'b0}};
            completion_data_q <= {`XLEN{1'b0}};
            completion_error_q <= 1'b0;
            completion_error_code_q <= {ERROR_W{1'b0}};
          end
        endcase
      end
    end
  end

`ifdef OOO_ASSERT
  localparam integer CMD_HOLD_W = PRODUCER_ID_W + 64 + `XLEN + 2 +
                                  OPCLASS_W;
  wire [CMD_HOLD_W-1:0] cmd_hold_payload_w =
      {cmd_producer_id_o, cmd_bits_o, cmd_rs_value_o, cmd_is_64_o,
       cmd_required_o, cmd_opclass_o};
  reg cmd_stall_check_q;
  reg [CMD_HOLD_W-1:0] cmd_stall_payload_q;
  reg src_read_hold_check_q;
  reg [PHY_REG_ADDR_W-1:0] src_read_hold_preg_q;
  reg wait_offer_check_q;
  reg wait_direct_fire_check_q;
  reg [CMD_HOLD_W-1:0] wait_offer_payload_q;
  reg cmd_fire_count_check_q;
  reg issued_count_check_valid_q;
  reg [31:0] issued_count_snapshot_q;
  reg sent_hold_check_q;
  reg sent_complete_check_q;
  reg sent_direct_clear_check_q;
  reg complete_hold_check_q;
  reg completion_stall_check_q;
  reg clear_check_q;
  reg terminal_count_check_q;
  reg completion_count_check_q;
  reg [31:0] terminal_count_snapshot_q;
  reg [31:0] completion_count_snapshot_q;
  localparam integer COMPLETION_HOLD_W = PRODUCER_ID_W + `XLEN + 1 + ERROR_W;
  reg [COMPLETION_HOLD_W-1:0] sent_complete_payload_q;
  reg [COMPLETION_HOLD_W-1:0] completion_stall_payload_q;
  wire [COMPLETION_HOLD_W-1:0] completion_hold_payload_w =
      {completion_producer_id_o, completion_data_o, completion_error_o,
       completion_error_code_o};

  always @(posedge clk) begin
    if (rst) begin
      cmd_stall_check_q <= 1'b0;
      cmd_stall_payload_q <= {CMD_HOLD_W{1'b0}};
      src_read_hold_check_q <= 1'b0;
      src_read_hold_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      wait_offer_check_q <= 1'b0;
      wait_direct_fire_check_q <= 1'b0;
      wait_offer_payload_q <= {CMD_HOLD_W{1'b0}};
      cmd_fire_count_check_q <= 1'b0;
      issued_count_check_valid_q <= 1'b0;
      issued_count_snapshot_q <= 32'b0;
      sent_hold_check_q <= 1'b0;
      sent_complete_check_q <= 1'b0;
      sent_direct_clear_check_q <= 1'b0;
      complete_hold_check_q <= 1'b0;
      completion_stall_check_q <= 1'b0;
      clear_check_q <= 1'b0;
      terminal_count_check_q <= 1'b0;
      completion_count_check_q <= 1'b0;
      terminal_count_snapshot_q <= 32'b0;
      completion_count_snapshot_q <= 32'b0;
      sent_complete_payload_q <= {COMPLETION_HOLD_W{1'b0}};
      completion_stall_payload_q <= {COMPLETION_HOLD_W{1'b0}};
    end else begin
`ifdef CONFIG_NPC_OOO_STATS
      if (attribution_sum_w !== serialize_cycles_o)
        $error("[TENSOR-ATTR-SUM] attribution sum=%0d does not equal serialize=%0d @%0t",
               attribution_sum_w, serialize_cycles_o, $time);
      if ((state_q !== OWNER_EMPTY) && (state_q !== OWNER_WAIT) &&
          (state_q !== OWNER_OFFER) && (state_q !== OWNER_SENT) &&
          (state_q !== OWNER_COMPLETE))
        $error("[TENSOR-ATTR-STATE] illegal owner state escaped attribution @%0t",
               $time);
      if (!serialize_active_o && (attribution_class_w !== ATTR_NONE))
        $error("[TENSOR-ATTR-IDLE] idle owner received attribution class %0d @%0t",
               attribution_class_w, $time);
      if (serialize_active_o &&
          ((^attribution_class_w === 1'bx) ||
           (attribution_class_w == ATTR_NONE)))
        $error("[TENSOR-ATTR-ONEHOT] active serialization edge lacks one exact attribution class @%0t",
               $time);
      if (attribution_class_w == ATTR_INVALID_STATE)
        $error("[TENSOR-ATTR-INVALID] invalid-state attribution must remain zero @%0t",
               $time);
      if ((attribution_class_w == ATTR_WAIT_SRC_VALUE) &&
          (!src_read_valid_o || src_read_fire_w))
        $error("[TENSOR-ATTR-SRC-VALUE] source-value wait lacks a denied resident read @%0t",
               $time);
      if ((attribution_class_w == ATTR_LAUNCH_TO_OFFER) &&
          (((launch_eligible_now_w !== 1'b1) &&
            (alloc_launch_eligible_w !== 1'b1)) ||
           (cmd_ready_i !== 1'b0)))
        $error("[TENSOR-ATTR-LAUNCH] skid boundary is not an eligible ready-low WAIT edge @%0t",
               $time);
      if (((attribution_class_w == ATTR_OFFER_ACCEPT) &&
           (cmd_fire_w !== 1'b1)) ||
          ((cmd_fire_w === 1'b1) &&
           (attribution_class_w != ATTR_OFFER_ACCEPT)))
        $error("[TENSOR-ATTR-OFFER] offer-accept class disagrees with command fire @%0t",
               $time);
      if (((attribution_class_w == ATTR_SENT_TERMINAL_ACCEPT) &&
           ((terminal_match_w !== 1'b1) ||
            (completion_accept_w !== 1'b0))) ||
          ((terminal_match_w === 1'b1) &&
           (completion_accept_w === 1'b0) &&
           (attribution_class_w != ATTR_SENT_TERMINAL_ACCEPT)))
        $error("[TENSOR-ATTR-TERMINAL] terminal-fallback class disagrees with denied exact terminal @%0t",
               $time);
      if (((attribution_class_w == ATTR_COMPLETE_WB_ACCEPT) &&
           ((state_q !== OWNER_COMPLETE) ||
            (completion_fire_w !== 1'b1))) ||
          ((attribution_class_w == ATTR_SENT_TERMINAL_WB_ACCEPT) &&
           ((state_q !== OWNER_SENT) ||
            (completion_fire_w !== 1'b1))) ||
          ((completion_fire_w === 1'b1) &&
           (attribution_class_w != ATTR_COMPLETE_WB_ACCEPT) &&
           (attribution_class_w != ATTR_SENT_TERMINAL_WB_ACCEPT)))
        $error("[TENSOR-ATTR-COMPLETION] WB-accept class disagrees with completion fire @%0t",
               $time);
      if (((attribution_class_w == ATTR_SENT_TERMINAL_COMPLETION_STALE) &&
           !((state_q == OWNER_SENT) && terminal_match_w &&
             completion_accept_w && !completion_query_match_i)) ||
          (((state_q == OWNER_SENT) && terminal_match_w &&
            completion_accept_w && !completion_query_match_i) &&
           (attribution_class_w != ATTR_SENT_TERMINAL_COMPLETION_STALE)))
        $error("[TENSOR-ATTR-DIRECT-STALE] direct completion stale class disagrees with SENT handshake @%0t",
               $time);
      if (attribution_offer_accept_cycles_q !== issued_count_o)
        $error("[TENSOR-ATTR-ISSUED] offer accepts=%0d issued=%0d @%0t",
               attribution_offer_accept_cycles_q, issued_count_o, $time);
      if ((attribution_sent_terminal_accept_cycles_q +
           attribution_sent_terminal_completion_stale_cycles_q +
           attribution_sent_terminal_wb_accept_cycles_q) !== terminal_count_o)
        $error("[TENSOR-ATTR-TERMINAL-COUNT] fallback=%0d direct_stale=%0d direct_wb=%0d terminal=%0d @%0t",
               attribution_sent_terminal_accept_cycles_q,
               attribution_sent_terminal_completion_stale_cycles_q,
               attribution_sent_terminal_wb_accept_cycles_q,
               terminal_count_o, $time);
      if ((attribution_complete_wb_accept_cycles_q +
           attribution_sent_terminal_wb_accept_cycles_q) !==
          completion_count_o)
        $error("[TENSOR-ATTR-COMPLETION-COUNT] resident=%0d direct=%0d completion=%0d @%0t",
               attribution_complete_wb_accept_cycles_q,
               attribution_sent_terminal_wb_accept_cycles_q,
               completion_count_o, $time);
      if (alloc_direct_issue_count_q > issued_count_o)
        $error("[TENSOR-ALLOC-DIRECT-COUNT] direct=%0d exceeds issued=%0d @%0t",
               alloc_direct_issue_count_q, issued_count_o, $time);
`endif
      if (((state_q == OWNER_OFFER) && !src_operand_valid_q) ||
          (cmd_valid_o &&
           !((alloc_launch_eligible_w && alloc_operand_valid_w) ||
             ((state_q == OWNER_OFFER) && src_operand_valid_q) ||
             ((state_q == OWNER_WAIT) && src_operand_valid_now_w))))
        $error("[TENSOR-OFFER-OPERAND-VALID] command offered without a captured operand @%0t",
               $time);
      if (src_read_valid_o &&
          ((src_read_ready_i !== 1'b0) &&
           (src_read_ready_i !== 1'b1)))
        $error("[TENSOR-SRC-READ-GRANT-KNOWN] resident read request sees unknown grant @%0t",
               $time);
      // This interface receives the arbiter's qualified grant (named ready to
      // retain normal valid/ready wiring).  Cancellation intentionally gates
      // valid combinationally, so a same-cycle kill/flush is the sole legal
      // case in which an already-present external grant may outlive request.
      if ((src_read_ready_i === 1'b1) && !src_read_valid_o &&
          !prelaunch_cancel_w)
        $error("[TENSOR-SRC-READ-GRANT-REQUEST] grant asserted without a resident request @%0t",
               $time);
      if (src_read_valid_o &&
          (!src_dep_ready_q || src_operand_valid_q ||
           (src_preg_q == {PHY_REG_ADDR_W{1'b0}}) || cmd_is_64_q))
        $error("[TENSOR-SRC-READ-REQUEST-STATE] source request escaped its dependency/value contract @%0t",
               $time);
      if (src_operand_valid_q && !src_dep_ready_q)
        $error("[TENSOR-SRC-OPERAND-DEP] captured operand lacks dependency readiness @%0t",
               $time);
      if (src_read_valid_o && (^src_read_preg_o === 1'bx))
        $error("[TENSOR-SRC-READ-PREG-KNOWN] resident request has unknown preg @%0t",
               $time);
      if (cmd_valid_o && (^cmd_hold_payload_w === 1'bx))
        $error("[TENSOR-CMD-PAYLOAD-KNOWN] offered command has unknown payload @%0t",
               $time);
      if ((state_q == OWNER_SENT) && terminal_match_w &&
          (!completion_valid_o ||
           (completion_producer_id_o !== producer_id_q) ||
           (completion_data_o !== terminal_data_i) ||
           (completion_error_o !== terminal_error_i) ||
           (completion_error_code_o !== terminal_error_code_i)))
        $error("[TENSOR-TERMINAL-WB-FALLTHROUGH] exact terminal did not expose its completion payload @%0t",
               $time);
      if (completion_valid_o &&
          !((state_q == OWNER_COMPLETE) ||
            ((state_q == OWNER_SENT) && terminal_match_w)))
        $error("[TENSOR-COMPLETION-VALID-SOURCE] completion valid escaped terminal fall-through/COMPLETE skid @%0t",
               $time);
      if ((state_q == OWNER_SENT) && terminal_match_w &&
          completion_accept_w && !completion_query_match_i &&
          completion_fire_w)
        $error("[TENSOR-TERMINAL-DIRECT-STALE] stale fall-through created an architectural WB fire @%0t",
               $time);
      if (prelaunch_cancel_w &&
          (src_read_valid_o || cmd_valid_o || cmd_fire_w))
        $error("[TENSOR-PRELAUNCH-CANCEL-NO-FIRE] cancel failed to gate request/command fire @%0t",
               $time);
      if ((state_q == OWNER_WAIT) && launch_eligible_now_w &&
          !prelaunch_cancel_w &&
          (!cmd_valid_o ||
           (cmd_rs_value_o !== src_value_now_w)))
        $error("[TENSOR-WAIT-FALLTHROUGH] eligible WAIT did not directly expose its prospective payload @%0t",
               $time);
      if ((state_q == OWNER_WAIT) && launch_eligible_now_w &&
          !prelaunch_cancel_w && cmd_ready_i && !cmd_fire_w)
        $error("[TENSOR-WAIT-DIRECT-FIRE] ready eligible WAIT did not fire directly @%0t",
               $time);
      if (alloc_launch_eligible_w &&
          (!cmd_valid_o ||
           (cmd_producer_id_o !== alloc_producer_id_i) ||
           (cmd_bits_o !== alloc_cmd_bits_i) ||
           (cmd_rs_value_o !== alloc_src_value_w) ||
           (cmd_is_64_o !== alloc_cmd_is_64_i) ||
           (cmd_required_o !== alloc_required_i) ||
           (cmd_opclass_o !== alloc_opclass_i)))
        $error("[TENSOR-ALLOC-FALLTHROUGH] eligible EMPTY allocation did not expose its prospective command @%0t",
               $time);
      if (alloc_launch_eligible_w && cmd_ready_i && !cmd_fire_w)
        $error("[TENSOR-ALLOC-DIRECT-FIRE] ready eligible EMPTY allocation did not fire directly @%0t",
               $time);
      if (cmd_fire_w &&
          !(alloc_launch_eligible_w ||
            ((state_q == OWNER_WAIT) && launch_eligible_now_w &&
             !prelaunch_cancel_w) ||
            ((state_q == OWNER_OFFER) && !prelaunch_cancel_w)))
        $error("[TENSOR-CMD-FIRE-SOURCE] command fire escaped allocation/WAIT fall-through or OFFER ownership @%0t",
               $time);
      if (src_read_hold_check_q && !prelaunch_cancel_w &&
          (!src_read_valid_o ||
           (src_read_preg_o !== src_read_hold_preg_q)))
        $error("[TENSOR-SRC-READ-HOLD] resident request changed before grant/wake/cancel @%0t",
               $time);
      if (cmd_stall_check_q && !prelaunch_cancel_w &&
          (!cmd_valid_o || (cmd_hold_payload_w !== cmd_stall_payload_q)))
        $error("[TENSOR-CMD-BACKPRESSURE-STABLE] command payload changed under backpressure @%0t",
               $time);
      if (wait_offer_check_q &&
          ((state_q !== OWNER_OFFER) ||
           (cmd_hold_payload_w !== wait_offer_payload_q)))
        $error("[TENSOR-WAIT-OFFER-SKID] denied WAIT payload did not cross into stable OFFER on the same edge @%0t",
               $time);
      if (wait_direct_fire_check_q && (state_q !== OWNER_SENT))
        $error("[TENSOR-WAIT-DIRECT-SENT] direct WAIT fire did not enter SENT on the same edge @%0t",
               $time);
      if (issued_count_check_valid_q &&
          (issued_count_o !==
           (issued_count_snapshot_q +
            (cmd_fire_count_check_q ? 32'd1 : 32'd0))))
        $error("[TENSOR-CMD-FIRE-COUNT] issued count changed without exactly one prior command fire @%0t",
               $time);
      if (sent_hold_check_q && (state_q !== OWNER_SENT))
        $error("[TENSOR-SENT-NONCANCEL] SENT owner changed without matching terminal @%0t",
               $time);
      if (sent_complete_check_q &&
          ((state_q !== OWNER_COMPLETE) || !completion_valid_o ||
           (completion_hold_payload_w !== sent_complete_payload_q)))
        $error("[TENSOR-SENT-COMPLETE-SKID] denied terminal completion did not enter a stable COMPLETE skid @%0t",
               $time);
      if (sent_direct_clear_check_q && (state_q !== OWNER_EMPTY))
        $error("[TENSOR-SENT-DIRECT-CLEAR] accepted terminal fall-through did not clear the owner @%0t",
               $time);
      if (complete_hold_check_q && (state_q !== OWNER_COMPLETE))
        $error("[TENSOR-COMPLETE-NONCANCEL] COMPLETE owner changed without completion accept @%0t",
               $time);
      if (completion_stall_check_q &&
          (!completion_valid_o ||
           (completion_hold_payload_w !== completion_stall_payload_q)))
        $error("[TENSOR-COMPLETION-BACKPRESSURE-STABLE] completion payload changed before acceptance @%0t",
               $time);
      if (clear_check_q &&
          ((state_q !== OWNER_EMPTY) ||
           (producer_id_q !== {PRODUCER_ID_W{1'b0}}) ||
           (pc_q !== {`XLEN{1'b0}}) ||
           (next_pc_q !== {`XLEN{1'b0}}) ||
           (cmd_bits_q !== 64'b0) || cmd_is_64_q || required_q ||
           (opclass_q !== {OPCLASS_W{1'b0}}) ||
           (src_preg_q !== {PHY_REG_ADDR_W{1'b0}}) ||
           src_dep_ready_q || src_operand_valid_q ||
           (src_value_q !== {`XLEN{1'b0}}) ||
           (completion_data_q !== {`XLEN{1'b0}}) ||
           completion_error_q ||
           (completion_error_code_q !== {ERROR_W{1'b0}})))
        $error("[TENSOR-OWNER-CLEAR] cancel/completion accept did not fully scrub owner state @%0t",
               $time);
      if (terminal_count_o !==
          (terminal_count_snapshot_q +
           (terminal_count_check_q ? 32'd1 : 32'd0)))
        $error("[TENSOR-TERMINAL-COUNT] terminal count changed without exactly one prior full-id terminal @%0t",
               $time);
      if (completion_count_o !==
          (completion_count_snapshot_q +
           (completion_count_check_q ? 32'd1 : 32'd0)))
        $error("[TENSOR-COMPLETION-COUNT] completion count changed without exactly one prior ROB/WB fire @%0t",
               $time);

      src_read_hold_check_q <= src_read_valid_o &&
          (src_read_ready_i !== 1'b1) &&
          !resident_wake1_match_w && !resident_wake0_match_w &&
          !prelaunch_kill_match_w && !prelaunch_flush_w;
      if (src_read_valid_o)
        src_read_hold_preg_q <= src_read_preg_o;

      cmd_stall_check_q <= cmd_valid_o && !cmd_ready_i &&
          !prelaunch_kill_match_w && !prelaunch_flush_w;
      if (cmd_valid_o && !cmd_ready_i)
        cmd_stall_payload_q <= cmd_hold_payload_w;

      // These one-cycle shadows sample the event that the sequential owner
      // consumes on this edge, then inspect the resulting state at the next
      // edge.  Recovery signals are deliberately not exceptions for the two
      // irreversible states.
      wait_offer_check_q <= (alloc_launch_eligible_w ||
                             (launch_eligible_now_w &&
                              !prelaunch_cancel_w)) && !cmd_ready_i;
      wait_direct_fire_check_q <= (alloc_launch_eligible_w ||
                                   (launch_eligible_now_w &&
                                    !prelaunch_cancel_w)) && cmd_ready_i;
      if ((alloc_launch_eligible_w ||
           (launch_eligible_now_w && !prelaunch_cancel_w)) && !cmd_ready_i)
        wait_offer_payload_q <= cmd_hold_payload_w;
      cmd_fire_count_check_q <= cmd_fire_w;
      issued_count_check_valid_q <= 1'b1;
      issued_count_snapshot_q <= issued_count_o;
      sent_hold_check_q <= (state_q == OWNER_SENT) && !terminal_match_w;
      sent_complete_check_q <= (state_q == OWNER_SENT) && terminal_match_w &&
                               !completion_accept_w;
      sent_direct_clear_check_q <= (state_q == OWNER_SENT) &&
                                   terminal_match_w && completion_accept_w;
      if ((state_q == OWNER_SENT) && terminal_match_w &&
          !completion_accept_w)
        sent_complete_payload_q <= completion_hold_payload_w;
      complete_hold_check_q <= (state_q == OWNER_COMPLETE) &&
                               !completion_accept_w;
      completion_stall_check_q <= completion_valid_o &&
                                  !completion_ready_i;
      if (completion_valid_o && !completion_ready_i)
        completion_stall_payload_q <= completion_hold_payload_w;
      clear_check_q <= prelaunch_cancel_w || completion_accept_w;
      terminal_count_check_q <= terminal_match_w;
      completion_count_check_q <= completion_fire_w;
      terminal_count_snapshot_q <= terminal_count_o;
      completion_count_snapshot_q <= completion_count_o;
    end
  end
`endif

endmodule
