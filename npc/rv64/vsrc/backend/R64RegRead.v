// Native address admission -> physical read -> independently held operands.
// Optional complete certified packets directly allocate the same terminal owner.
// Four GPR and three FPR ports are explicit. Blocked read results remain local
// to ingress; they never keep claiming a port. Each MEM carries the LSQ slot
// allocated at dispatch; the LSQ alone owns memory age and capacity.
// Outputs are raw owners: Execute must reject current kill/flush before effects.
// Cancellation clears local state at the edge without an async READY chain.
module R64RegRead #(
  parameter PREPARED_CANCEL = 0,
  parameter PREG_W = 6,
  parameter PREG_N = (1 << PREG_W),
  parameter COMPACT_FP = 0,
  parameter RAW_FP_ALLOCATION = 0,
  parameter UNIQUE_SERIAL = 0,
  parameter PREQUALIFIED_ISSUE = 0,
  parameter Q_ONLY_TERMINAL = 0,
  parameter ALU_TERMINAL_BYPASS = 0,
  parameter LATE_OPERANDS = 0,
  parameter LOAD_RESOLVED_VALUE = 0,
  parameter ALU_TOKEN_BYPASS = 0,
  // Only MEM may bind an existing LSQ owner from certified current ALU values.
  parameter MEM_TERMINAL_CURRENT = 0,
  // A complete certified input packet may skip the empty physical-read ingress.
  parameter RR_COMPLETE_ADMIT = 0,
  // Keep shared-resource Q readiness separate from local ALU late acceptance;
  // MEM_TERMINAL_CURRENT may additionally qualify the existing MEM bind path.
  parameter SPLIT_VALUE_VALID = 0,
  parameter ROB_W = 5,
  parameter TAG_W = 9,
  parameter PAYLOAD_W = 128,
  parameter LSQ_W = 5,
  // Reuse an empty lane's original GPR ports for canonically ready input sources.
  parameter RR_ADMIT_GPR_READ = 0,
  // Native branches use the same complete snapshot and their own input control.
  parameter RR_COMPLETE_BRANCH_ADMIT = 0
) (
  input                       clk,
  input                       rst,
  input                       flush_i,
  input  [    (1<<ROB_W)-1:0] kill_mask_i,
  input  [    (1<<ROB_W)-1:0] cancel_candidates_i,
  input                       cancel_active_i,
  input  [               1:0] in_fire_i,
  output [               1:0] in_ready_o,
  input  [       2*TAG_W-1:0] in_tag_i,
  input  [       2*LSQ_W-1:0] in_mem_slot_i,
  input  [   2*PAYLOAD_W-1:0] in_payload_i,
  input  [               5:0] in_class_i,
  input  [      2*PREG_W-1:0] in_gpr_dst_i,
  input  [      6*PREG_W-1:0] in_src_preg_i,
  input  [               5:0] in_src_fp_i,
  input  [               5:0] in_src_used_i,
  input  [               5:0] in_src_pending_i,
  input  [2*(3*PREG_W+8)-1:0] in_fp_plan_i,
  input  [               1:0] wb_write_i,
  input  [               1:0] wb_fp_i,
  input  [      2*PREG_W-1:0] wb_preg_i,
  input  [             127:0] wb_data_i,
  // Short ALU result holders bridge early wakeup to canonical WB/PRF.
  // Resident Q candidates select wide late data independently of current
  // owner/recovery authorization. VALID below certifies only narrow use.
  // Completed memory results are non-owning observations. They feed only
  // edge-captured history/local values, never current terminal fast acceptance.
  input  [               1:0] resolved_value_valid_i,
  input  [      2*PREG_W-1:0] resolved_value_preg_i,
  input  [             127:0] resolved_value_data_i,
  input  [               1:0] alu_bypass_resident_i,
  input  [               1:0] alu_bypass_valid_i,
  input  [      2*PREG_W-1:0] alu_bypass_preg_i,
  input  [             127:0] alu_bypass_data_i,
  // Separate token and old-head sources: neither may hide the other.
  input  [               1:0] alu_token_resident_i,
  input  [               1:0] alu_token_valid_i,
  input  [      2*PREG_W-1:0] alu_token_preg_i,
  input  [             127:0] alu_token_data_i,
  // Native bypass mode publishes a resident candidate to Execute. Only
  // VALID/READY transfers it; Execute must not retain an unaccepted candidate.
  // Generic mode retains the original FIFO held-output contract.
  input  [               5:0] fu_credit_i,
  output [               1:0] out_valid_o,
  output [               1:0] out_local_alu_valid_o,
  input  [               1:0] out_ready_i,
  output [       2*TAG_W-1:0] out_tag_o,
  output [       2*LSQ_W-1:0] out_mem_slot_o,
  output [   2*PAYLOAD_W-1:0] out_payload_o,
  output [               5:0] out_class_o,
  output [             383:0] out_operand_o,
  output [      2*PREG_W-1:0] out_gpr_dst_o,
  output [              73:0] out_alu_control_o,
  output [               9:0] out_add_source_o,
  output [              11:0] out_shift_amount_o,
  output [              41:0] out_branch_imm_o,
  output [               9:0] out_branch_control_o
);
  reg [63:0] gpr_q[0:PREG_N-1], fpr_q[0:PREG_N-1];
  reg [PREG_N-1:0] ginit_q, finit_q;
  // Each lane owns one ingress slot and two terminal slots, hiding the credit
  // return without a READY cone. Terminal arrays use lane*2 + local slot.
  // The physical read remains one edge after admission; no latency is added.
  reg [1:0] terminal_head_q, terminal_tail_q;
  reg [1:0] terminal_count_q[0:1];
  reg [3:0] terminal_dead_q;
  wire [1:0] terminal_pop_w, terminal_select_w;
  reg [TAG_W-1:0] tag_q[0:3];
  reg [PAYLOAD_W-1:0] payload_q[0:3];
  reg [2:0] class_q[0:3];
  reg [PREG_W-1:0] gpr_dst_q[0:3];
  // Physical snapshot, high to low: {FPR2, FPR1, FPR0, GPR1, GPR0}.
  // Per-source FP/rank fields map the three logical operands into this snapshot.
  reg [319:0] operand_q[0:3];
  reg [2:0] operand_fp_q[0:3], operand_used_q[0:3];
  reg  [ 5:0] operand_rank_q[0:3];
  reg  [36:0] alu_control_q [0:3];
  reg  [ 4:0] add_source_q  [0:3];
  wire [ 4:0] add_source_w  [0:1];
  reg [5:0] shift_amount_q[0:3], ingress_shift_amount_q[0:1];
  wire [5:0] read_shift_amount_w[0:1];
  reg [20:0] branch_imm_q[0:3];
  reg [4:0] branch_control_q[0:3];
  wire [20:0] branch_imm_w[0:1];
  wire [4:0] branch_control_w[0:1];
  wire [36:0] alu_control_w[0:1];
  // A physical read snapshots storage and forward identities independently.
  // Late WB destination matching only reaches a small hit register; bank/
  // forward selection occurs from this owned snapshot after the read edge.
  reg [11:0] forward_hit_q[0:3], ingress_forward_hit_q[0:1];
  reg [255:0] forward_data_q[0:3], ingress_forward_data_q[0:1];
  // Address/owner admission precedes physical read. A read result can remain
  // in ingress if its output is held, without reserving a physical read port.
  reg [1:0] ingress_valid_q, operand_ready_q;
  reg [TAG_W-1:0] ingress_tag_q[0:1];
  reg [PAYLOAD_W-1:0] ingress_payload_q[0:1];
  reg [2:0] ingress_class_q[0:1], ingress_fp_q[0:1], ingress_used_q[0:1];
  reg [PREG_W-1:0] ingress_dst_q[0:1];
  reg [3*PREG_W-1:0] ingress_src_q[0:1];
  reg [319:0] ingress_operand_q[0:1];
  reg [2:0] ingress_operand_fp_q[0:1], ingress_operand_used_q[0:1];
  reg [5:0] ingress_operand_rank_q[0:1];
  wire [1:0] ingress_live_w, read_select_w, transfer_w, out_live_w, out_room_w;
  wire [1:0] ingress_cancel_w, input_cancel_w, output_cancel_w;
  wire [6*PREG_W-1:0] read_src_w = {ingress_src_q[1], ingress_src_q[0]};
  wire [5:0] read_fp_w = {ingress_fp_q[1], ingress_fp_q[0]};
  wire [5:0] read_used_w = {ingress_used_q[1], ingress_used_q[0]};
  wire [1:0] pending_read_w = ingress_valid_q & ~operand_ready_q;
  // Every new ingress performs its physical read on the next edge even
  // when output is blocked, storing the result locally in that case.
  // Therefore pending reads are exactly a subset of the previous input
  // bundle: independent output stalls cannot merge different FP port budgets.
  assign read_select_w = pending_read_w;
  // This is the already allocated LSQ slot, not a second RR reservation.
  // It follows the same fulltag through ingress and terminal owners.
  reg [LSQ_W-1:0] mem_slot_q[0:3], ingress_mem_slot_q[0:1];
  wire [1:0] out_fire_w;
  wire [PREG_W-1:0] gaddr_w[0:3];
  wire [63:0] gdata_w[0:3];
  reg [PREG_W-1:0] faddr_w[0:2];
  wire [PREG_W-1:0] allocated_faddr_w[0:2];
  reg [11:0] allocated_rank_q;
  wire [11:0] allocated_rank_w;
  wire [5:0]
      allocate_fp_request_w = in_src_used_i & in_src_fp_i & {{3{in_fire_i[1]}}, {3{in_fire_i[0]}}};
  wire [63:0] fdata_w[0:2];
  wire [1:0] frank_w[0:5];
  wire [5:0] frequest_w = read_used_w & read_fp_w & {{3{read_select_w[1]}}, {3{read_select_w[0]}}};
  function [2:0] pop6;
    input [5:0] mask;
    reg [1:0] a, b, c;
    begin
      a = {1'b0, mask[0]} + {1'b0, mask[1]};
      b = {1'b0, mask[2]} + {1'b0, mask[3]};
      c = {1'b0, mask[4]} + {1'b0, mask[5]};
      pop6 = {1'b0, a} + {1'b0, b} + {1'b0, c};
    end
  endfunction
  wire [2:0] fp_ports = pop6(frequest_w);
  genvar source, port, node;
  // The actual IQ grants a complete bundle whose raw FPR demand is <=3.
  // Allocate that bundle before late cancellation; accepted lanes retain their
  // assigned rank even when another lane is cancelled. Empty reads have no
  // owner or side effect. Actual ingress fire/credit and the read edge are
  // unchanged. Generic mode still compacts only the accepted subset.
  generate
    if (COMPACT_FP != 0) begin : g_compact_fp
      wire [3*PREG_W-1:0] address_w;
      R64FpReadJoin #(
        .PREG_W(PREG_W)
      ) fp_join (
        .plan_i(in_fp_plan_i),
        .fire_i(RAW_FP_ALLOCATION != 0 ? 2'b11 : in_fire_i),
        .address_o(address_w),
        .rank_o(allocated_rank_w)
      );
      for (port = 0; port < 3; port = port + 1) begin : g_port
        assign allocated_faddr_w[port] = address_w[port*PREG_W+:PREG_W];
      end
      for (source = 0; source < 6; source = source + 1) begin : g_rank
        assign frank_w[source] = allocated_rank_w[source*2+:2];
      end
    end else begin : g_raw_fp
      for (source = 0; source < 6; source = source + 1) begin : gen_fp_rank
        localparam [5:0] PREVIOUS = (6'b000001 << source) - 1'b1;
        wire [2:0] rank_w = pop6(allocate_fp_request_w & PREVIOUS);
        assign frank_w[source] = rank_w[1:0];
        assign allocated_rank_w[source*2+:2] = rank_w[1:0];
      end
      for (port = 0; port < 3; port = port + 1) begin : gen_fp_address
        for (node = 1; node < 16; node = node + 1) begin : tree
          wire [PREG_W-1:0] addr_w;
          if (node >= 8) begin : leaf
            if (node - 8 < 6) begin : present
              assign addr_w = in_src_preg_i[(node-8)*PREG_W+:PREG_W] &
                  {PREG_W{allocate_fp_request_w[node-8] && frank_w[node-8] == port}};
            end else begin : pad
              assign addr_w = 0;
            end
          end else begin : merge
            assign addr_w = tree[2*node].addr_w | tree[2*node+1].addr_w;
          end
        end
        assign allocated_faddr_w[port] = tree[1].addr_w;
      end
    end
  endgenerate
  wire [3:0] gpr_forward_valid_w = {wb_write_i & ~wb_fp_i, alu_bypass_valid_i};
  wire [4*PREG_W-1:0] gpr_forward_preg_w = {wb_preg_i, alu_bypass_preg_i};
  wire [255:0] gpr_forward_data_w = {wb_data_i, alu_bypass_data_i};
  // Ordinary PRF snapshots retain the four original sources. Optional
  // numerical notices are only used by pending owners and arrival history.
  localparam TOKEN_SOURCES = ALU_TOKEN_BYPASS != 0 ? 2 : 0;
  localparam LATE_SOURCES = 4 + TOKEN_SOURCES + (LOAD_RESOLVED_VALUE != 0 ? 2 : 0);
  wire [LATE_SOURCES-1:0] late_forward_valid_w;
  wire [LATE_SOURCES*PREG_W-1:0] late_forward_preg_w;
  wire [LATE_SOURCES*64-1:0] late_forward_data_w;
  assign late_forward_valid_w[0+:4] = gpr_forward_valid_w;
  assign late_forward_preg_w[0+:4*PREG_W] = gpr_forward_preg_w;
  assign late_forward_data_w[0+:256] = gpr_forward_data_w;
  generate
    if (ALU_TOKEN_BYPASS != 0) begin : g_token_arrivals
      assign late_forward_valid_w[4+:2] = alu_token_valid_i;
      assign late_forward_preg_w[4*PREG_W+:2*PREG_W] = alu_token_preg_i;
      assign late_forward_data_w[256+:128] = alu_token_data_i;
    end
    if (LOAD_RESOLVED_VALUE != 0) begin : g_memory_arrival
      assign late_forward_valid_w[4+TOKEN_SOURCES+:2] = resolved_value_valid_i;
      assign late_forward_preg_w[(4+TOKEN_SOURCES)*PREG_W+:2*PREG_W] = resolved_value_preg_i;
      assign late_forward_data_w[(4+TOKEN_SOURCES)*64+:128] = resolved_value_data_i;
    end
  endgenerate
  // A promise grants only scheduling eligibility. Every resident RR position
  // retains unresolved source identity and captures one-shot real values even
  // while the physical snapshot or terminal queue is blocked.
  reg [2*PREG_W-1:0] late_src_q[0:3];
  reg [1:0] late_pending_q[0:3], late_resolved_q[0:3];
  reg [127:0] late_data_q[0:3];
  reg [1:0] ingress_late_pending_q[0:1], ingress_late_resolved_q[0:1];
  reg [127:0] ingress_late_data_q[0:1];
  wire [LATE_SOURCES*64-1:0] arrival_data_w;
  wire [LATE_SOURCES*PREG_W-1:0] arrival_preg_w;
  wire [LATE_SOURCES-1:0] arrival_valid_w;
  wire [1:0] ingress_history_hit_w[0:1];
  wire [1:0] ingress_effective_pending_w[0:1], ingress_effective_resolved_w[0:1];
  wire [127:0] ingress_effective_data_w[0:1];
  wire [1:0] late_hit_w[0:3], ingress_late_hit_w[0:1];
  wire [127:0] late_data_w[0:3], ingress_late_data_w[0:1];
  generate
    if (LATE_OPERANDS != 0) begin : g_arrival_history
      // Save the complete, already certified arrival event independently of
      // current Issue source selection. Its identity is matched only against
      // the admitted ingress owner at the one-shot physical-read boundary.
      reg [LATE_SOURCES*64-1:0] arrival_data_q;
      reg [LATE_SOURCES*PREG_W-1:0] arrival_preg_q;
      reg [LATE_SOURCES-1:0] arrival_valid_q;
      always @(posedge clk) begin
        arrival_data_q <= late_forward_data_w;
        arrival_preg_q <= late_forward_preg_w;
        arrival_valid_q <= late_forward_valid_w;
      end
      assign arrival_data_w = arrival_data_q;
      assign arrival_preg_w = arrival_preg_q;
      assign arrival_valid_w = arrival_valid_q;
    end else begin : g_no_arrival_history
      assign arrival_data_w = 0;
      assign arrival_preg_w = 0;
      assign arrival_valid_w = 0;
    end
  endgenerate
  wire [3:0] late_ready_w;
  wire [1:0] late_alu_hit_w[0:3];
  wire [127:0] late_alu_data_w[0:3];
  function [LATE_SOURCES-1:0] late_match;
    input [PREG_W-1:0] preg;
    input [LATE_SOURCES-1:0] valid_mask;
    input [LATE_SOURCES*PREG_W-1:0] pregs;
    integer k;
    begin
      for (k=0; k<LATE_SOURCES; k=k+1)
        late_match[k] = preg != 0 && valid_mask[k] && pregs[k*PREG_W+:PREG_W] == preg;
    end
  endfunction
  function [63:0] late_value;
    input [LATE_SOURCES-1:0] hits;
    input [LATE_SOURCES*64-1:0] values;
    integer k;
    begin
      late_value=0;
      // Registered capture has deterministic lane order, matching PRF WB1
      // priority. The independent collision assertion still rejects different
      // real values for one physical owner; priority never makes that legal.
      for (k=0; k<LATE_SOURCES; k=k+1) if (hits[k]) late_value=values[k*64+:64];
      // Canonical WB retains priority above optional numerical observations.
      if(hits[2])late_value=values[128+:64];
      if(hits[3])late_value=values[192+:64];
    end
  endfunction
  // Destination choice is made only after Issue's actual acceptance. Read
  // credit remains Q-only; no current value or Execute READY enters in_ready.
  // WB uses the same highest capture priority as every other numerical holder.
  wire [1:0] direct_eligible_w, direct_admit_w, ingress_admit_w, terminal_push_w;
  wire [1:0] direct_source_ready_w[0:1];
  wire [127:0] direct_value_w[0:1];
  wire [36:0] direct_alu_control_w[0:1];
  wire [4:0] direct_add_source_w[0:1];
  wire [5:0] direct_shift_amount_w[0:1];
  wire [20:0] direct_branch_imm_w[0:1];
  wire [4:0] direct_branch_control_w[0:1];
  genvar direct_lane, direct_source;
  generate for (direct_lane=0; direct_lane<2; direct_lane=direct_lane+1) begin : g_direct_admit
    wire [PAYLOAD_W-1:0] payload_w=in_payload_i[direct_lane*PAYLOAD_W+:PAYLOAD_W];
    wire [2:0] used_w=in_src_used_i[direct_lane*3+:3];
    wire [2:0] fp_w=in_src_fp_i[direct_lane*3+:3];
    wire [2:0] class_w=in_class_i[direct_lane*3+:3];
    for (direct_source=0; direct_source<2; direct_source=direct_source+1) begin : g_source
      wire [PREG_W-1:0] preg_w=in_src_preg_i[(direct_lane*3+direct_source)*PREG_W+:PREG_W];
      wire zero_w=!used_w[direct_source] || preg_w==0;
      wire [LATE_SOURCES-1:0] hits_w=late_match(preg_w,late_forward_valid_w,late_forward_preg_w);
      // Pending is the IQ's canonical-not-ready fact, not a PRF init bit.
      // Same-edge actual arrivals override storage, including WB before its NBA.
      wire prf_ready_w=RR_ADMIT_GPR_READ != 0 &&
          !in_src_pending_i[direct_lane*3+direct_source];
      assign direct_source_ready_w[direct_lane][direct_source]=zero_w || |hits_w || prf_ready_w;
      assign direct_value_w[direct_lane][direct_source*64+:64]=
          zero_w ? 64'b0 : |hits_w ? late_value(hits_w,late_forward_data_w) :
          gdata_w[direct_lane*2+direct_source];
    end
    assign direct_eligible_w[direct_lane]=!rst && !flush_i && !input_cancel_w[direct_lane] &&
        !ingress_valid_q[direct_lane] && terminal_count_q[direct_lane]<2 &&
        (class_w==3'd0 || class_w==3'd4 ||
         (RR_COMPLETE_BRANCH_ADMIT != 0 && PAYLOAD_W>=208 && class_w==3'd1)) && !used_w[2] && !(|(used_w & fp_w)) &&
        (&direct_source_ready_w[direct_lane]);
    assign direct_admit_w[direct_lane]=RR_COMPLETE_ADMIT != 0 &&
        in_fire_i[direct_lane] && direct_eligible_w[direct_lane];
    assign ingress_admit_w[direct_lane]=in_fire_i[direct_lane] && !direct_admit_w[direct_lane];
    assign terminal_push_w[direct_lane]=transfer_w[direct_lane] || direct_admit_w[direct_lane];
    if (PAYLOAD_W>=208) begin : g_native
      wire [31:0] inst_w=payload_w[128+:32];
      wire conditional_w=inst_w[6:0]==7'h63, indirect_w=inst_w[6:0]==7'h67;
      wire [20:0] bi_w={{8{inst_w[31]}},inst_w[31],inst_w[7],inst_w[30:25],inst_w[11:8],1'b0};
      wire [20:0] ji_w={inst_w[31],inst_w[19:12],inst_w[20],inst_w[30:21],1'b0};
      wire [20:0] ii_w={{9{inst_w[31]}},inst_w[31:20]};
      wire [7:0] function_w=class_w==3'd1 ? 8'd0 : payload_w[196+:8];
      R64AluControl decoder(.function_i(function_w),.control_o(direct_alu_control_w[direct_lane]));
      assign direct_branch_imm_w[direct_lane]=indirect_w ? ii_w : conditional_w ? bi_w : ji_w;
      assign direct_branch_control_w[direct_lane]={inst_w[14:12],indirect_w,conditional_w};
      assign direct_add_source_w[direct_lane]=class_w==3'd1 ? {3'b100,!indirect_w,indirect_w} :
          {1'b0,payload_w[207],!payload_w[207],payload_w[205],!payload_w[205] && !payload_w[206]};
      assign direct_shift_amount_w[direct_lane]=payload_w[207] ?
          payload_w[64+:6] : direct_value_w[direct_lane][64+:6];
    end else begin : g_generic
      assign direct_branch_imm_w[direct_lane]=0;
      assign direct_branch_control_w[direct_lane]=0;
      assign direct_alu_control_w[direct_lane]=37'd2;
      assign direct_add_source_w[direct_lane]=5'b00101;
      assign direct_shift_amount_w[direct_lane]=direct_value_w[direct_lane][64+:6];
    end
  end endgenerate
  genvar late_owner, late_source;
  generate
    for (late_owner=0; late_owner<4; late_owner=late_owner+1) begin : g_late_terminal
      for (late_source=0; late_source<2; late_source=late_source+1) begin : g_source
        wire [LATE_SOURCES-1:0] hits_w = late_match(late_src_q[late_owner][late_source*PREG_W+:PREG_W],
            late_forward_valid_w, late_forward_preg_w);
        assign late_hit_w[late_owner][late_source] = LATE_OPERANDS != 0 && |hits_w;
        assign late_data_w[late_owner][late_source*64+:64] = late_value(hits_w, late_forward_data_w);
        wire [PREG_W-1:0] preg_w=late_src_q[late_owner][late_source*PREG_W+:PREG_W];
        wire raw0_w=alu_bypass_resident_i[0] && preg_w!=0 && alu_bypass_preg_i[0+:PREG_W]==preg_w;
        wire raw1_w=alu_bypass_resident_i[1] && preg_w!=0 &&
            alu_bypass_preg_i[PREG_W+:PREG_W]==preg_w;
        // A stale same-preg candidate cannot redirect the wide mux using
        // current kill. Its fixed choice stalls until certified or local WB
        // capture supplies the value; the other raw lane never contaminates it.
        wire token0_w=ALU_TOKEN_BYPASS != 0 && alu_token_resident_i[0] &&
            preg_w!=0 && alu_token_preg_i[0+:PREG_W]==preg_w;
        wire token1_w=ALU_TOKEN_BYPASS != 0 && alu_token_resident_i[1] &&
            preg_w!=0 && alu_token_preg_i[PREG_W+:PREG_W]==preg_w;
        assign late_alu_data_w[late_owner][late_source*64+:64] =
            raw0_w ? alu_bypass_data_i[0+:64] :
            raw1_w ? alu_bypass_data_i[64+:64] :
            token0_w ? alu_token_data_i[0+:64] :
            token1_w ? alu_token_data_i[64+:64] : alu_bypass_data_i[64+:64];
        assign late_alu_hit_w[late_owner][late_source] = LATE_OPERANDS != 0 &&
            (raw0_w ? alu_bypass_valid_i[0] :
             raw1_w ? alu_bypass_valid_i[1] :
             token0_w ? alu_token_valid_i[0] : token1_w && alu_token_valid_i[1]);
      end
      // Canonical WB only discharges the local pending register at the edge.
      // Only a certified resident ALU head or registered numerical token may
      // satisfy the current candidate. WB still updates local readiness at Q.
      assign late_ready_w[late_owner] = LATE_OPERANDS == 0 ||
          !(|(late_pending_q[late_owner] & ~late_alu_hit_w[late_owner]));
    end
    for (late_owner=0; late_owner<2; late_owner=late_owner+1) begin : g_late_ingress
      for (late_source=0; late_source<2; late_source=late_source+1) begin : g_source
        wire [LATE_SOURCES-1:0] resident_hits_w = late_match(
            ingress_src_q[late_owner][late_source*PREG_W+:PREG_W],
            late_forward_valid_w, late_forward_preg_w);
        wire [LATE_SOURCES-1:0] history_hits_w = late_match(
            ingress_src_q[late_owner][late_source*PREG_W+:PREG_W],
            arrival_valid_w, arrival_preg_w);
        assign ingress_late_hit_w[late_owner][late_source] = LATE_OPERANDS != 0 && |resident_hits_w;
        assign ingress_late_data_w[late_owner][late_source*64+:64] =
            late_value(resident_hits_w, late_forward_data_w);
        // A held ingress never replays later history as its admission event.
        // The already-certified earlier event wins over current arrivals.
        assign ingress_history_hit_w[late_owner][late_source] = LATE_OPERANDS != 0 &&
            read_select_w[late_owner] && ingress_late_pending_q[late_owner][late_source] &&
            |history_hits_w;
        assign ingress_effective_pending_w[late_owner][late_source] =
            ingress_late_pending_q[late_owner][late_source] &
            ~ingress_history_hit_w[late_owner][late_source];
        assign ingress_effective_resolved_w[late_owner][late_source] =
            ingress_late_resolved_q[late_owner][late_source] |
            ingress_history_hit_w[late_owner][late_source];
        assign ingress_effective_data_w[late_owner][late_source*64+:64] =
            ingress_history_hit_w[late_owner][late_source] ?
            late_value(history_hits_w, arrival_data_w) :
            ingress_late_data_q[late_owner][late_source*64+:64];
      end
    end
  endgenerate
  genvar p;
  generate
    for (p = 0; p < 4; p = p + 1) begin : gen_gpr_port
      localparam SRC = (p / 2) * 3 + (p % 2);
      // Q-only selection gives every old ingress its original two read ports.
      // The empty lane may inspect an input address regardless of fire/kill;
      // only actual direct admission captures its complete ready packet.
      assign gaddr_w[p] = RR_COMPLETE_ADMIT != 0 && RR_ADMIT_GPR_READ != 0 &&
          !ingress_valid_q[p/2] ? in_src_preg_i[SRC*PREG_W+:PREG_W] :
          read_src_w[SRC*PREG_W+:PREG_W];
      assign gdata_w[p] = (gaddr_w[p] != 0 && ginit_q[gaddr_w[p]]) ? gpr_q[gaddr_w[p]] : 64'b0;
    end
    for (p = 0; p < 3; p = p + 1) begin : gen_fpr_port
      assign fdata_w[p] = finit_q[faddr_w[p]] ? fpr_q[faddr_w[p]] : 64'b0;
    end
  endgenerate
  // Snapshot the physical read ports before mapping them back to logical
  // operands. FP source rank no longer traverses allocation -> PRF -> reverse
  // mapping in one cycle. Held packets retain all relevant physical values.
  wire [639:0] read_operand_w;
  wire [ 11:0] read_rank_w;
  wire [ 23:0] read_forward_hit_w;
  generate
    for (p = 0; p < 6; p = p + 1) begin : gen_operand
      wire [PREG_W-1:0] source_w = read_src_w[p*PREG_W+:PREG_W];
      wire source_live_w = read_used_w[p] && (read_fp_w[p] || source_w != 0);
      wire wb0_hit_w = source_live_w && wb_write_i[0] && wb_fp_i[0] == read_fp_w[p] &&
          wb_preg_i[0+:PREG_W] == source_w;
      wire wb1_hit_w = source_live_w && wb_write_i[1] && wb_fp_i[1] == read_fp_w[p] &&
          wb_preg_i[PREG_W+:PREG_W] == source_w;
      assign read_forward_hit_w[p*4+0] = source_live_w && !read_fp_w[p] && alu_bypass_valid_i[0] &&
          alu_bypass_preg_i[0+:PREG_W] == source_w;
      assign read_forward_hit_w[p*4+1] = source_live_w && !read_fp_w[p] && alu_bypass_valid_i[1] &&
          alu_bypass_preg_i[PREG_W+:PREG_W] == source_w;
      assign read_forward_hit_w[p*4+2] = wb0_hit_w && !(read_fp_w[p] && wb1_hit_w);
      assign read_forward_hit_w[p*4+3] = wb1_hit_w;
      assign read_rank_w[p*2+:2] = allocated_rank_q[p*2+:2];
    end
  endgenerate
  // Compose each resident packet before selecting a terminal head. The head
  // bit controls only the final operand mux, not physical-port rank and
  // forwarding selection cascaded behind a wide packet mux.
  wire [767:0] terminal_operand_w;
  generate
    for (p = 0; p < 12; p = p + 1) begin : gen_terminal_operand
      localparam integer SLOT = p / 3, SOURCE = p % 3;
      wire [63:0] stored_gpr_w;
      if (SOURCE < 2) assign stored_gpr_w = operand_q[SLOT][SOURCE*64+:64];
      else assign stored_gpr_w = 0;
      wire [1:0] rank_q = operand_rank_q[SLOT][SOURCE*2+:2];
      wire [191:0] stored_fpr_w = operand_q[SLOT][128+:192];
      wire [63:0] stored_operand_w = !operand_used_q[SLOT][SOURCE] ? 64'b0 :
          operand_fp_q[SLOT][SOURCE] ? stored_fpr_w[rank_q*64+:64] : stored_gpr_w;
      wire [3:0] hit_w = forward_hit_q[SLOT][SOURCE*4+:4];
      wire [255:0] forward_w = forward_data_q[SLOT];
      // 已锁存的命中资格选择 ALU0/1、WB0/1；无命中才使用物理读快照。
      wire [63:0] alu0_w = forward_w[0+:64] & {64{hit_w[0]}};
      wire [63:0] alu1_w = forward_w[64+:64] & {64{hit_w[1]}};
      wire [63:0] wb0_w = forward_w[128+:64] & {64{hit_w[2]}};
      wire [63:0] wb1_w = forward_w[192+:64] & {64{hit_w[3]}};
      wire [63:0] original_operand_w = (alu0_w | alu1_w) | (wb0_w | wb1_w) |
          (stored_operand_w & {64{!(|hit_w)}});
      if (SOURCE < 2) begin : g_late_source
        // A token value is formed only from arithmetic partial/control Q.
        // There is no current Execute input-to-output combinational shortcut.
        // Wide selection sees only Q state and resident Q routing. Current
        // authorization changes readiness/capture, never this value choice.
        assign terminal_operand_w[p*64+:64] = LATE_OPERANDS != 0 &&
            late_resolved_q[SLOT][SOURCE] ? late_data_q[SLOT][SOURCE*64+:64] :
            LATE_OPERANDS != 0 && late_pending_q[SLOT][SOURCE] ?
            late_alu_data_w[SLOT][SOURCE*64+:64] : original_operand_w;
      end else assign terminal_operand_w[p*64+:64] = original_operand_w;
    end
    for (p = 0; p < 2; p = p + 1) begin : gen_lane
      wire [31:0] selected_terminal_w = p*2+{31'b0, terminal_select_w[p]};
      if (ALU_TERMINAL_BYPASS != 0 && PAYLOAD_W >= 208) begin : g_resident_select
        wire [2:0] head_class_w = class_q[p*2+{31'b0, terminal_head_q[p]}];
        wire [2:0] other_class_w = class_q[p*2+{31'b0, !terminal_head_q[p]}];
        wire [PAYLOAD_W-1:0] head_payload_w = payload_q[p*2+{31'b0, terminal_head_q[p]}];
        // Execute credit bits, high to low: {FP, CLMUL, DIV, MUL, ALU1, ALU0}.
        wire head_credit_w = head_payload_w[199] ? fu_credit_i[4] :
            head_payload_w[198] ? fu_credit_i[3] : fu_credit_i[2];
        wire head_pending_w = SPLIT_VALUE_VALID != 0 && LATE_OPERANDS != 0 &&
            (|late_pending_q[p*2+{31'b0, terminal_head_q[p]}]);
        wire head_blocked_w = (head_class_w == 3'd2 && (!head_credit_w || head_pending_w)) ||
            (head_class_w == 3'd3 && (!fu_credit_i[5] || head_pending_w));
        // Credits are resident FU capacity, independent of this RR candidate.
        // MEM/Serial/branch heads retain their original lane/order boundary.
        wire escape_w = terminal_count_q[p] == 2 && head_blocked_w && !terminal_dead_q[
            p*2+{31'b0, terminal_head_q[p]}] && other_class_w == 3'd0 && fu_credit_i[p];
        assign terminal_select_w[p] = terminal_head_q[p] ^ escape_w;
      end else begin : g_fifo_select
        assign terminal_select_w[p] = terminal_head_q[p];
      end
      assign out_operand_o[p*192+:192] = terminal_select_w[p] ?
          terminal_operand_w[(p*2+1)*192+:192] : terminal_operand_w[p*2*192+:192];
      wire [3:0] shift_hit_w = read_forward_hit_w[(p*3+1)*4+:4];
      // 移位量预计算使用同一组当前旁路来源，保持与 terminal 快照一致。
      wire [63:0] shift_alu0_w = gpr_forward_data_w[0+:64] & {64{shift_hit_w[0]}};
      wire [63:0] shift_alu1_w = gpr_forward_data_w[64+:64] & {64{shift_hit_w[1]}};
      wire [63:0] shift_wb0_w = gpr_forward_data_w[128+:64] & {64{shift_hit_w[2]}};
      wire [63:0] shift_wb1_w = gpr_forward_data_w[192+:64] & {64{shift_hit_w[3]}};
      wire [63:0] read_bypass_b_w = (shift_alu0_w | shift_alu1_w) | (shift_wb0_w | shift_wb1_w) |
          (gdata_w[p*2+1] & {64{!(|shift_hit_w)}});
      assign read_operand_w[p*320+:320] = {
        fdata_w[2], fdata_w[1], fdata_w[0], gdata_w[p*2+1], gdata_w[p*2]
      };
      if (PAYLOAD_W >= 208) begin : alu_predecode
        assign read_shift_amount_w[p] = ingress_payload_q[p][207] ? ingress_payload_q[p][64+:6] :
            read_bypass_b_w[5:0];
        // Opcode control travels alongside the physical read, before any ALU
        // data calculation. Generic short test payloads do not contain an ALU.
        wire [7:0] function_w = ingress_class_q[p] == 3'd1 ? 8'd0 : ingress_payload_q[p][196+:8];
        R64AluControl decoder (
          .function_i(function_w),
          .control_o (alu_control_w[p])
        );
        wire [31:0] inst_w = ingress_payload_q[p][128+:32];
        wire conditional_w = inst_w[6:0] == 7'h63, indirect_w = inst_w[6:0] == 7'h67;
        wire [20:0] bi_w = {
          {8{inst_w[31]}}, inst_w[31], inst_w[7], inst_w[30:25], inst_w[11:8], 1'b0
        };
        wire [20:0] ji_w = {inst_w[31], inst_w[19:12], inst_w[20], inst_w[30:21], 1'b0};
        wire [20:0] ii_w = {{9{inst_w[31]}}, inst_w[31:20]};
        assign branch_imm_w[p] = indirect_w ? ii_w : conditional_w ? bi_w : ji_w;
        assign branch_control_w[p] = {inst_w[14:12], indirect_w, conditional_w};
        // {branch B, immediate B, register B, PC A, register A}.
        assign add_source_w[p] = ingress_class_q[p] == 3'd1 ? {3'b100, !indirect_w, indirect_w} :
            {1'b0, ingress_payload_q[p][207], !ingress_payload_q[p][207], ingress_payload_q[p][205],
             !ingress_payload_q[p][205] && !ingress_payload_q[p][206]};
      end else begin : no_alu_predecode
        assign alu_control_w[p] = 37'd2;
        assign add_source_w[p] = 5'b00101;
        assign read_shift_amount_w[p] = read_bypass_b_w[5:0];
        assign branch_imm_w[p] = 0;
        assign branch_control_w[p] = 0;
      end
      assign out_alu_control_o[p*37+:37] = alu_control_q[selected_terminal_w];
      assign out_add_source_o[p*5+:5] = add_source_q[selected_terminal_w];
      if (PAYLOAD_W >= 208) begin : g_late_shift_native
        assign out_shift_amount_o[p*6+:6] = LATE_OPERANDS != 0 &&
            !payload_q[selected_terminal_w][207] ?
            out_operand_o[p*192+64+:6] : shift_amount_q[selected_terminal_w];
      end else begin : g_late_shift_generic
        assign out_shift_amount_o[p*6+:6] = LATE_OPERANDS != 0 ?
            out_operand_o[p*192+64+:6] : shift_amount_q[selected_terminal_w];
      end
      assign out_branch_imm_o[p*21+:21] = branch_imm_q[selected_terminal_w];
      assign out_branch_control_o[p*5+:5] = branch_control_q[selected_terminal_w];
      wire [ROB_W-1:0] output_slot_w = tag_q[selected_terminal_w][ROB_W-1:0];
      // 每个持有位置保留自己的 owner 查询，不把取消掩码提前合并到宽数据选择。
      assign output_cancel_w[p] = PREPARED_CANCEL ?
          (cancel_active_i && cancel_candidates_i[output_slot_w]) : kill_mask_i[output_slot_w];
      assign ingress_cancel_w[p] = PREPARED_CANCEL ?
          (cancel_active_i && cancel_candidates_i[ingress_tag_q[p][ROB_W-1:0]]) :
          kill_mask_i[ingress_tag_q[p][ROB_W-1:0]];
      assign input_cancel_w[p] = PREPARED_CANCEL ?
          (cancel_active_i && cancel_candidates_i[in_tag_i[p*TAG_W+:ROB_W]]) :
          kill_mask_i[in_tag_i[p*TAG_W+:ROB_W]];
      assign ingress_live_w[p] = ingress_valid_q[p] && !rst && !flush_i && !ingress_cancel_w[p];
      // Output is a raw registered owner. Execute checks the same current
      // kill/flush before any FU/LSU admission; local state cancels at this edge.
      assign out_live_w[p] = terminal_count_q[p] != 0 &&
          !terminal_dead_q[selected_terminal_w];
      // MEM may bind its existing LSQ owner when every pending GPR has a
      // certified resident ALU head/token value. The operand mux uses that same
      // fixed resident selection; WB and memory notices still resolve only at Q.
      // Other shared units retain registered operand readiness. Execute checks
      // current kill/flush and resource acceptance before any actual transfer.
      wire mem_current_ready_w = MEM_TERMINAL_CURRENT != 0 &&
          class_q[selected_terminal_w] == 3'd4 && late_ready_w[selected_terminal_w];
      assign out_valid_o[p] = out_live_w[p] && (SPLIT_VALUE_VALID != 0 ?
          (LATE_OPERANDS == 0 || !(|late_pending_q[selected_terminal_w]) ||
           mem_current_ready_w) : late_ready_w[selected_terminal_w]);
      assign out_local_alu_valid_o[p] = SPLIT_VALUE_VALID != 0 && out_live_w[p] &&
          (class_q[selected_terminal_w] == 3'd0 || class_q[selected_terminal_w] == 3'd1) &&
          late_ready_w[selected_terminal_w];
      // This is a local consumption join only, never a downstream resource fire.
      assign out_fire_w[p] = out_ready_i[p] && (out_valid_o[p] || out_local_alu_valid_o[p]);
      assign terminal_pop_w[p] = terminal_count_q[p] != 0 &&
          (out_fire_w[p] || terminal_dead_q[selected_terminal_w]);
      // Q-only capacity prevents Execute READY/cancellation from re-entering
      // terminal admission. A full queue can pop now and accept ingress next edge.
      assign out_room_w[p] = terminal_count_q[p] < 2 || (Q_ONLY_TERMINAL == 0 && terminal_pop_w[p]);
      assign transfer_w[p] = ingress_valid_q[p] && out_room_w[p] &&
          (operand_ready_q[p] || read_select_w[p]);
      assign in_ready_o[p] = !(terminal_count_q[p][1] && ingress_valid_q[p]);
      assign out_mem_slot_o[p*LSQ_W+:LSQ_W] = mem_slot_q[selected_terminal_w];
      assign out_tag_o[p*TAG_W+:TAG_W] = tag_q[selected_terminal_w];
      assign out_payload_o[p*PAYLOAD_W+:PAYLOAD_W] = payload_q[selected_terminal_w];
      assign out_class_o[p*3+:3] = class_q[selected_terminal_w];
      assign out_gpr_dst_o[p*PREG_W+:PREG_W] = gpr_dst_q[selected_terminal_w];
    end
  endgenerate
  integer late_slot, late_lane, late_operand;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (late_slot=0; late_slot<4; late_slot=late_slot+1) begin
        late_pending_q[late_slot] <= 0;
        late_resolved_q[late_slot] <= 0;
      end
      for (late_lane=0; late_lane<2; late_lane=late_lane+1) begin
        ingress_late_pending_q[late_lane] <= 0;
        ingress_late_resolved_q[late_lane] <= 0;
      end
    end else if (LATE_OPERANDS != 0) begin
      for (late_slot=0; late_slot<4; late_slot=late_slot+1)
        for (late_operand=0; late_operand<2; late_operand=late_operand+1)
          if (late_pending_q[late_slot][late_operand] && late_hit_w[late_slot][late_operand]) begin
            late_pending_q[late_slot][late_operand] <= 0;
            late_resolved_q[late_slot][late_operand] <= 1;
            late_data_q[late_slot][late_operand*64+:64] <= late_data_w[late_slot][late_operand*64+:64];
          end
      for (late_lane=0; late_lane<2; late_lane=late_lane+1) begin
        // Resolve the admission-edge history once, even when terminal credit
        // is absent. Current events can discharge only the remaining pending
        // sources, so a later event cannot overwrite the admitted sample.
        for (late_operand=0; late_operand<2; late_operand=late_operand+1) begin
          if (ingress_history_hit_w[late_lane][late_operand]) begin
            ingress_late_pending_q[late_lane][late_operand] <= 0;
            ingress_late_resolved_q[late_lane][late_operand] <= 1;
            ingress_late_data_q[late_lane][late_operand*64+:64] <=
                ingress_effective_data_w[late_lane][late_operand*64+:64];
          end
          if (ingress_effective_pending_w[late_lane][late_operand] &&
              ingress_late_hit_w[late_lane][late_operand]) begin
            ingress_late_pending_q[late_lane][late_operand] <= 0;
            ingress_late_resolved_q[late_lane][late_operand] <= 1;
            ingress_late_data_q[late_lane][late_operand*64+:64] <=
                ingress_late_data_w[late_lane][late_operand*64+:64];
          end
        end
        if (transfer_w[late_lane]) begin
          late_src_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}] <=
              ingress_src_q[late_lane][0+:2*PREG_W];
          late_pending_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}] <=
              ingress_effective_pending_w[late_lane] & ~ingress_late_hit_w[late_lane];
          late_resolved_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}] <=
              ingress_effective_resolved_w[late_lane] |
              (ingress_effective_pending_w[late_lane] & ingress_late_hit_w[late_lane]);
          for (late_operand=0; late_operand<2; late_operand=late_operand+1)
            late_data_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}][late_operand*64+:64] <=
                ingress_effective_pending_w[late_lane][late_operand] && ingress_late_hit_w[late_lane][late_operand] ?
                ingress_late_data_w[late_lane][late_operand*64+:64] :
                ingress_effective_data_w[late_lane][late_operand*64+:64];
        end
        if (direct_admit_w[late_lane]) begin
          late_src_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}] <=
              in_src_preg_i[late_lane*3*PREG_W+:2*PREG_W];
          late_pending_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}] <= 0;
          late_resolved_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}] <= 0;
          late_data_q[late_lane*2+{31'b0,terminal_tail_q[late_lane]}] <= 0;
        end
        if (ingress_admit_w[late_lane]) begin
          // Refill follows old-owner transfer/capture. NBA pairs that owner
          // with old history; the newly admitted owner reads new history next.
          ingress_late_pending_q[late_lane] <= in_src_pending_i[late_lane*3+:2];
          ingress_late_resolved_q[late_lane] <= 0;
        end
      end
    end
  end
  // Port allocation belongs to the address admission edge. Every pending
  // read is from exactly this previous bundle; completed blocked reads keep
  // their own physical values/rank and never consume these addresses again.
  integer address_port;
  always @(posedge clk) begin
    for (address_port = 0; address_port < 3; address_port = address_port + 1)
    faddr_w[address_port] <= allocated_faddr_w[address_port];
    allocated_rank_q <= allocated_rank_w;
  end
  // Each physical register owns its two write enables. Lane one wins a
  // same-destination collision, matching forwarding and the original port order.
  genvar physical;
  generate
    for (physical = 0; physical < PREG_N; physical = physical + 1) begin : gen_physical_write
      localparam [PREG_W-1:0] PHYSICAL = physical;
      wire hit0 = wb_write_i[0] && wb_preg_i[0+:PREG_W] == PHYSICAL;
      wire hit1 = wb_write_i[1] && wb_preg_i[PREG_W+:PREG_W] == PHYSICAL;
      wire fg0 = hit0 && wb_fp_i[0], fg1 = hit1 && wb_fp_i[1];
      wire gg0 = hit0 && !wb_fp_i[0] && physical != 0;
      wire gg1 = hit1 && !wb_fp_i[1] && physical != 0;
      wire [63:0] fnext = ({64{fg0 && !fg1}} & wb_data_i[0+:64]) | ({64{fg1}} & wb_data_i[64+:64]);
      wire [63:0] gnext = ({64{gg0 && !gg1}} & wb_data_i[0+:64]) | ({64{gg1}} & wb_data_i[64+:64]);
      always @(posedge clk) begin
        if (rst) begin
          finit_q[physical] <= 0;
          ginit_q[physical] <= 0;
        end else begin
          if (fg0 || fg1) begin
            fpr_q[physical]   <= fnext;
            finit_q[physical] <= 1;
          end
          if (gg0 || gg1) begin
            gpr_q[physical]   <= gnext;
            ginit_q[physical] <= 1;
          end
        end
      end
    end
  endgenerate
  integer lane, terminal_slot;
  always @(posedge clk) begin
    if (rst) begin
      terminal_head_q <= 0;
      terminal_tail_q <= 0;
      terminal_dead_q <= 0;
      terminal_count_q[0] <= 0;
      terminal_count_q[1] <= 0;
      ingress_valid_q <= 0;
      operand_ready_q <= 0;
    end else begin
      for (terminal_slot = 0; terminal_slot < 4; terminal_slot = terminal_slot + 1)
      if (PREPARED_CANCEL ?
              (cancel_active_i && cancel_candidates_i[tag_q[terminal_slot][ROB_W-1:0]]) :
              kill_mask_i[tag_q[terminal_slot][ROB_W-1:0]])
        terminal_dead_q[terminal_slot] <= 1;
      for (lane = 0; lane < 2; lane = lane + 1) begin
        if (flush_i) begin
          terminal_head_q[lane] <= 0;
          terminal_tail_q[lane] <= 0;
          terminal_count_q[lane] <= 0;
          terminal_dead_q[lane*2+:2] <= 0;
          ingress_valid_q[lane] <= 0;
          operand_ready_q[lane] <= 0;
        end else begin
          terminal_count_q[lane] <= terminal_count_q[lane] + {1'b0, terminal_push_w[lane]} -
              {1'b0, terminal_pop_w[lane]};
          if (terminal_pop_w[lane]) begin
            if (terminal_select_w[lane] == terminal_head_q[lane])
              terminal_head_q[lane] <= ~terminal_head_q[lane];
            else terminal_tail_q[lane] <= terminal_select_w[lane];
          end
          if (transfer_w[lane]) begin
            terminal_tail_q[lane] <= ~terminal_tail_q[lane];
            terminal_dead_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= ingress_cancel_w[lane];
            tag_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= ingress_tag_q[lane];
            payload_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= ingress_payload_q[lane];
            class_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= ingress_class_q[lane];
            gpr_dst_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= ingress_dst_q[lane];
            mem_slot_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= ingress_mem_slot_q[lane];
            alu_control_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= alu_control_w[lane];
            add_source_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= add_source_w[lane];
            shift_amount_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= operand_ready_q[lane] ?
                ingress_shift_amount_q[lane] : read_shift_amount_w[lane];
            branch_imm_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= branch_imm_w[lane];
            branch_control_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= branch_control_w[lane];
            operand_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= operand_ready_q[lane] ?
                ingress_operand_q[lane] : read_operand_w[lane*320+:320];
            operand_fp_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= operand_ready_q[lane] ?
                ingress_operand_fp_q[lane] : read_fp_w[lane*3+:3];
            operand_used_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= operand_ready_q[lane] ?
                ingress_operand_used_q[lane] : read_used_w[lane*3+:3];
            operand_rank_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= operand_ready_q[lane] ?
                ingress_operand_rank_q[lane] : read_rank_w[lane*6+:6];
            forward_hit_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= operand_ready_q[lane] ?
                ingress_forward_hit_q[lane] : read_forward_hit_w[lane*12+:12];
            forward_data_q[lane*2+{31'b0, terminal_tail_q[lane]}] <= operand_ready_q[lane] ?
                ingress_forward_data_q[lane] : gpr_forward_data_w;
          end
          if (direct_admit_w[lane]) begin
            // Direct capture writes the same terminal owner and metadata as
            // old-ingress transfer. The two events are mutually exclusive.
            terminal_tail_q[lane] <= ~terminal_tail_q[lane];
            terminal_dead_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= 0;
            tag_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= in_tag_i[lane*TAG_W+:TAG_W];
            payload_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= in_payload_i[lane*PAYLOAD_W+:PAYLOAD_W];
            class_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= in_class_i[lane*3+:3];
            gpr_dst_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= in_gpr_dst_i[lane*PREG_W+:PREG_W];
            mem_slot_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= in_mem_slot_i[lane*LSQ_W+:LSQ_W];
            alu_control_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= direct_alu_control_w[lane];
            add_source_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= direct_add_source_w[lane];
            shift_amount_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= direct_shift_amount_w[lane];
            branch_imm_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= direct_branch_imm_w[lane];
            branch_control_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= direct_branch_control_w[lane];
            operand_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= {192'b0,direct_value_w[lane]};
            operand_fp_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= 0;
            operand_used_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= in_src_used_i[lane*3+:3];
            operand_rank_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= 0;
            forward_hit_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= 0;
            forward_data_q[lane*2+{31'b0,terminal_tail_q[lane]}] <= 0;
          end
          if (!ingress_live_w[lane] || transfer_w[lane]) begin
            ingress_valid_q[lane] <= 0;
            operand_ready_q[lane] <= 0;
          end else if (read_select_w[lane]) begin
            ingress_shift_amount_q[lane] <= read_shift_amount_w[lane];
            operand_ready_q[lane] <= 1;
            ingress_operand_q[lane] <= read_operand_w[lane*320+:320];
            ingress_operand_fp_q[lane] <= read_fp_w[lane*3+:3];
            ingress_operand_used_q[lane] <= read_used_w[lane*3+:3];
            ingress_operand_rank_q[lane] <= read_rank_w[lane*6+:6];
            ingress_forward_hit_q[lane] <= read_forward_hit_w[lane*12+:12];
            ingress_forward_data_q[lane] <= gpr_forward_data_w;
          end
          if (ingress_admit_w[lane]) begin
            // Issue already qualifies a new owner; held owners retain cancellation.
            ingress_valid_q[lane] <= PREQUALIFIED_ISSUE != 0 ? 1'b1 : !input_cancel_w[lane];
            operand_ready_q[lane] <= 0;
            ingress_tag_q[lane] <= in_tag_i[lane*TAG_W+:TAG_W];
            ingress_payload_q[lane] <= in_payload_i[lane*PAYLOAD_W+:PAYLOAD_W];
            ingress_class_q[lane] <= in_class_i[lane*3+:3];
            ingress_mem_slot_q[lane] <= in_mem_slot_i[lane*LSQ_W+:LSQ_W];
            ingress_dst_q[lane] <= in_gpr_dst_i[lane*PREG_W+:PREG_W];
            ingress_src_q[lane] <= in_src_preg_i[lane*3*PREG_W+:3*PREG_W];
            ingress_fp_q[lane] <= in_src_fp_i[lane*3+:3];
            ingress_used_q[lane] <= in_src_used_i[lane*3+:3];
          end
        end
      end
    end
  end
`ifdef R64_ASSERT
  initial
    if (ALU_TERMINAL_BYPASS != 0 && (!Q_ONLY_TERMINAL || PAYLOAD_W < 208))
      $fatal(1, "RR resident bypass requires native payload and Q-only terminal credit");
  always @(posedge clk)
    if (!rst && !flush_i)
      for (integer lane_check = 0; lane_check < 2; lane_check = lane_check + 1)
        if (terminal_select_w[lane_check] != terminal_head_q[lane_check] &&
            (terminal_count_q[lane_check] != 2 || transfer_w[lane_check] ||
             out_class_o[lane_check*3+:3] != 0))
          $fatal(1, "RR bypass selected a missing or non-ALU resident owner");
  generate
    if (RAW_FP_ALLOCATION != 0) begin : g_raw_fp_contract
      localparam FP_PLAN_W = 3 * PREG_W + 8;
      wire [2*FP_PLAN_W-1:0] expected_plan_w;
      wire [3*PREG_W-1:0] old_address_w;
      wire [11:0] old_rank_w;
      for (genvar lane = 0; lane < 2; lane = lane + 1) begin : g_plan
        R64FpReadCompact #(
          .PREG_W(PREG_W)
        ) expected_plan (
          .preg_i(in_src_preg_i[lane*3*PREG_W+:3*PREG_W]),
          .used_i(in_src_used_i[lane*3+:3]),
          .fp_i  (in_src_fp_i[lane*3+:3]),
          .plan_o(expected_plan_w[lane*FP_PLAN_W+:FP_PLAN_W])
        );
      end
      R64FpReadJoin #(
        .PREG_W(PREG_W)
      ) original_join (
        .plan_i(in_fp_plan_i),
        .fire_i(in_fire_i),
        .address_o(old_address_w),
        .rank_o(old_rank_w)
      );
      initial if (COMPACT_FP == 0) $fatal(1, "R64 raw FPR allocation requires compact plans");
      always @(posedge clk)
        if (!rst && !flush_i && |in_fire_i) begin
          if (pop6(in_src_used_i & in_src_fp_i) > 3)
            $fatal(1, "R64 raw selected IQ bundle exceeds three FPR ports");
          if (in_fp_plan_i !== expected_plan_w)
            $fatal(1, "R64 raw FPR allocation plan does not belong to selected IQ sources");
        end
      for (genvar src = 0; src < 6; src = src + 1) begin : g_source
        wire [1:0] new_rank_w = allocated_rank_w[src*2+:2];
        wire [1:0] prior_rank_w = old_rank_w[src*2+:2];
        always @(posedge clk)
          if (!rst && !flush_i && in_fire_i[src/3] && in_src_used_i[src] && in_src_fp_i[src]) begin
            if (new_rank_w >= 3 || prior_rank_w >= 3 ||
                allocated_faddr_w[new_rank_w] !== in_src_preg_i[src*PREG_W+:PREG_W] ||
                allocated_faddr_w[new_rank_w] !== old_address_w[prior_rank_w*PREG_W+:PREG_W])
              $fatal(1, "R64 raw FPR allocation changed an accepted source address");
          end
      end
    end
  endgenerate

  // Preserve the original cancellation predicate for owners routed to ingress.
  // Complete direct packets instead allocate terminal ownership at that edge;
  // already-held ingress cancellation remains unchanged.
  reg [1:0] ingress_valid_shadow_q;
  integer qualified_lane;
  always @(posedge clk) begin
    if (rst || flush_i) ingress_valid_shadow_q <= 0;
    else
      for (integer q = 0; q < 2; q = q + 1) begin
        if (!ingress_live_w[q] || transfer_w[q]) ingress_valid_shadow_q[q] <= 0;
        if (ingress_admit_w[q]) ingress_valid_shadow_q[q] <= !kill_mask_i[in_tag_i[q*TAG_W+:ROB_W]];
      end
    if (PREQUALIFIED_ISSUE != 0)
      for (qualified_lane = 0; qualified_lane < 2; qualified_lane = qualified_lane + 1)
      if (in_fire_i[qualified_lane] &&
          (rst || flush_i || kill_mask_i[in_tag_i[qualified_lane*TAG_W+:ROB_W]]))
        $fatal(1, "R64 RR prequalified Issue fire was cancelled");
  end
  always @(negedge clk)
    if (!rst && PREQUALIFIED_ISSUE != 0)
      if (ingress_valid_q !== ingress_valid_shadow_q)
        $fatal(1, "R64 RR qualified admission differs from original predicate");

  integer serial_owner_count, serial_lane, serial_entry;
  // Occupancy is exact even when pop and replacement occur at the same edge:
  // both payload selection and this invariant refer to pre-edge terminal Q.
  always @(*) begin
    serial_owner_count = 0;
    for (serial_lane = 0; serial_lane < 2; serial_lane = serial_lane + 1) begin
      if (ingress_valid_q[serial_lane] && ingress_class_q[serial_lane] == 3'd5)
        serial_owner_count = serial_owner_count + 1;
      for (serial_entry = 0; serial_entry < 2; serial_entry = serial_entry + 1)
      if ((terminal_count_q[serial_lane] == 2 ||
           (terminal_count_q[serial_lane] == 1 && terminal_head_q[serial_lane] == serial_entry[0]))
          && !terminal_dead_q[serial_lane*2+serial_entry] &&
          class_q[serial_lane*2+serial_entry] == 3'd5)
        serial_owner_count = serial_owner_count + 1;
    end
  end
  always @(posedge clk)
    if (!rst && UNIQUE_SERIAL != 0 && serial_owner_count > 1)
      $fatal(1, "RR ingress and terminal Serial owners are not unique");

  // Verification shadow only: every live output keeps the slot that entered
  // with its fulltag. The actual reservation state resides solely in the LSQ.
  reg [TAG_W-1:0] observed_tag_q[0:(1<<ROB_W)-1];
  reg [LSQ_W-1:0] observed_slot_q[0:(1<<ROB_W)-1];
  integer slot_check;
  always @(posedge clk)
    if (!rst && !flush_i) begin
      for (slot_check = 0; slot_check < 2; slot_check = slot_check + 1) begin
        if (in_fire_i[slot_check] && in_class_i[slot_check*3+:3] == 3'd4) begin
          observed_tag_q[in_tag_i[slot_check*TAG_W+:ROB_W]] <= in_tag_i[slot_check*TAG_W+:TAG_W];
          observed_slot_q[in_tag_i[slot_check*TAG_W+:ROB_W]] <=
              in_mem_slot_i[slot_check*LSQ_W+:LSQ_W];
        end
        if (out_valid_o[slot_check] && out_class_o[slot_check*3+:3] == 3'd4 &&
            !output_cancel_w[slot_check] && (observed_tag_q[out_tag_o[slot_check*TAG_W+:ROB_W]] != out_tag_o[
                  slot_check*TAG_W+:TAG_W] || observed_slot_q[out_tag_o[slot_check*TAG_W+:ROB_W]] !=
                  out_mem_slot_o[slot_check*LSQ_W+:LSQ_W]))
          $fatal(1, "R64 RR LSQ slot separated from canonical fulltag");
      end
    end
  reg [1:0] prior_admit_q;
  always @(posedge clk) begin
    if (rst || flush_i) prior_admit_q <= 0;
    else prior_admit_q <= ingress_admit_w;
    if (!rst && !flush_i && (read_select_w & ~prior_admit_q) != 0)
      $fatal(1, "R64 physical read retried beyond its admission bundle");
  end
  // Check the actual owner destination, independently of downstream pop.
  reg [1:0] prior_direct_q;
  always @(posedge clk) begin
    if (rst || flush_i) prior_direct_q <= 0;
    else prior_direct_q <= direct_admit_w;
    if (!rst && !flush_i) begin
      if (RR_ADMIT_GPR_READ != 0)
        for (integer gp=0;gp<4;gp=gp+1)
          if (read_select_w[gp/2] && gaddr_w[gp] !==
              read_src_w[((gp/2)*3+gp%2)*PREG_W+:PREG_W])
            $fatal(1,"RR input PRF read displaced an old ingress port");
      if ((direct_admit_w & transfer_w)!=0)
        $fatal(1,"RR direct admission collided with old ingress transfer");
      if ((direct_admit_w & ~in_fire_i)!=0 || (direct_admit_w & ingress_valid_q)!=0)
        $fatal(1,"RR direct admission lacks an accepted empty-ingress owner");
      if ((prior_direct_q & read_select_w)!=0)
        $fatal(1,"RR directly captured owner retried the physical read");
      for (integer d=0;d<2;d=d+1)
        if (direct_admit_w[d] && (terminal_count_q[d]>=2 ||
            in_src_used_i[d*3+2] || |(in_src_used_i[d*3+:3]&in_src_fp_i[d*3+:3])))
          $fatal(1,"RR direct admission violated Q capacity or integer-source shape");
    end
  end
  integer mem_owner_check;
  always @(posedge clk)
    if (!rst && !flush_i) begin
      for (mem_owner_check = 0; mem_owner_check < 2; mem_owner_check = mem_owner_check + 1) begin
        if (in_fire_i[mem_owner_check] && ingress_live_w[mem_owner_check] &&
            !transfer_w[mem_owner_check])
          $fatal(1, "R64 register read live ingress overwritten");
        if (terminal_count_q[mem_owner_check] > 2) $fatal(1, "R64 register read terminal overflow");
      end
    end
  integer forward_a, forward_b;
  always @(posedge clk)
    if (!rst && !flush_i) begin
      for (forward_a = 0; forward_a < LATE_SOURCES; forward_a = forward_a + 1)
      for (forward_b = forward_a + 1; forward_b < LATE_SOURCES; forward_b = forward_b + 1)
      if (late_forward_valid_w[forward_a] && late_forward_valid_w[forward_b] &&
          late_forward_preg_w[forward_a*PREG_W+:PREG_W] != 0 && late_forward_preg_w[
          forward_a*PREG_W+:PREG_W] == late_forward_preg_w[forward_b*PREG_W+:PREG_W] &&
          late_forward_data_w[forward_a*64+:64] != late_forward_data_w[forward_b*64+:64])
        $fatal(1, "R64 two forwarding stages disagree on a live physical value");
    end

  always @(posedge clk)
    if (!rst) begin
      if ((in_fire_i & ~in_ready_o) != 0) $fatal(1, "R64 register read overwritten while held");
      if (fp_ports > 3) $fatal(1, "R64 FPR read budget exceeded");
      for (lane = 0; lane < 2; lane = lane + 1)
      if (in_fire_i[lane] && in_src_used_i[lane*3+2] && !in_src_fp_i[lane*3+2])
        $fatal(1, "R64 third GPR read requested");
    end
`endif
`ifdef R64_ASSERT
  generate
    if (PREPARED_CANCEL) begin : gen_cancel_contract
      always @(posedge clk)
        if (!rst)
          if (kill_mask_i !== ({(1 << ROB_W) {cancel_active_i}} & cancel_candidates_i))
            $fatal(1, "prepared cancellation does not match canonical kill mask");
    end
  endgenerate
`endif
endmodule
