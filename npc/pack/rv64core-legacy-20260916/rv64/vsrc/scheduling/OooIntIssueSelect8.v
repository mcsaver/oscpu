// Eight-slot scheduler with separate integer readiness and memory-age
// domains.  The two grants are operand-read packets, not program-order lanes.
// Memory reservations hold captured operands and do not reserve an ALU.
module OooIntIssueSelect8 (
  input [7:0] valid_i,
  input [7:0] base_ready_i,
  input [7:0] memory_i,
  input [7:0] alu_capable_i,
  input [7:0] plain_memory_capable_i,
  input universal_owner_present_i,
  // Q-only enable for exposing resident entries 0/1 as the next ordinary
  // memory pair while the Universal terminal is owned by reservation Q.
  // This input must not depend on issue READY or downstream transport READY.
  input memory_pair_peek_enable_i,

  output [7:0] eligible_o,
  output issue0_found_o,
  output [2:0] issue0_idx_o,
  output [7:0] issue0_onehot_o,
  output issue1_found_o,
  output [2:0] issue1_idx_o,
  output [7:0] issue1_onehot_o,
  output issue_pair_swapped_o,
  output memory_pair_peek_valid_o
);


  // INT and MEM have independent age domains but share two operand-read
  // packets.  Payload remains in the same eight slots: no duplicated window
  // or additional PRF port is needed.  Only memory predecessors constrain
  // the oldest MEM candidate; an unrelated unready integer is not a fence.
  function [7:0] first_onehot;
    input [7:0] request;
    reg [7:0] p1;
    reg [7:0] p2;
    reg [7:0] p4;
    begin
      p1 = request | (request << 1);
      p2 = p1 | (p1 << 2);
      p4 = p2 | (p2 << 4);
      first_onehot = request & ~{p4[6:0], 1'b0};
    end
  endfunction

  wire [7:0] memory_valid_w = valid_i & memory_i;
  wire [7:0] memory_first_w = first_onehot(memory_valid_w);
  wire [7:0] memory_second_w =
      first_onehot(memory_valid_w & ~memory_first_w);
  wire memory_first_ready_w = |(memory_first_w & base_ready_i);
  wire memory_pair_ready_w = memory_first_ready_w &&
      (|(memory_first_w & plain_memory_capable_i)) &&
      (|(memory_second_w & base_ready_i & plain_memory_capable_i));
  // A corrupt hole cannot create memory authority.  Real states are packed;
  // preserve the fail-closed boundary in addition to the packed assertion.
  wire packed_head_w = valid_i[0];
  wire [7:0] integer_ready_w = base_ready_i & ~memory_i;
  wire [7:0] memory_ready_w =
      {8{!universal_owner_present_i && packed_head_w}} &
      ((memory_first_w & base_ready_i) |
       ({8{memory_pair_ready_w}} & memory_second_w));
  wire [7:0] eligible_w = integer_ready_w | memory_ready_w;
  assign eligible_o = eligible_w;

  wire [7:0] first_req_onehot_w = first_onehot(eligible_w);
  wire [7:0] second_req_onehot_w =
      first_onehot(eligible_w & ~first_req_onehot_w);
  wire [7:0] first_alu_onehot_w =
      first_onehot(integer_ready_w & alu_capable_i);
  wire first_req_valid_w = |first_req_onehot_w;
  wire second_req_valid_w = |second_req_onehot_w;
  wire first_req_is_alu_w = |(first_req_onehot_w & alu_capable_i);
  wire [7:0] partner_onehot_w =
      first_req_is_alu_w ? second_req_onehot_w : first_alu_onehot_w;
  wire partner_valid_w = |partner_onehot_w;
  wire partner_is_alu_w = |(partner_onehot_w & alu_capable_i);
  // A pair of MEM uops consumes both existing read packets atomically.  The
  // first MEM must also be the oldest eligible instruction for normal issue.
  wire memory_pair_w = !universal_owner_present_i && packed_head_w &&
      memory_pair_ready_w && (|(first_req_onehot_w & memory_first_w));
  // Old reservation operands are already captured.  They never own an ALU.
  // The optional pair refill face can use both read packets only when no
  // ready INT is requesting them; downstream consume does not enter select.
  wire owner_memory_pair_peek_w = universal_owner_present_i &&
      memory_pair_peek_enable_i && packed_head_w && memory_pair_ready_w &&
      !(|integer_ready_w);
  wire swap_w = !owner_memory_pair_peek_w && !memory_pair_w &&
      first_req_valid_w && first_req_is_alu_w &&
      partner_valid_w && !partner_is_alu_w;
  wire [7:0] issue0_onehot_w =
      (owner_memory_pair_peek_w || memory_pair_w) ? memory_first_w :
      (swap_w ? partner_onehot_w : first_req_onehot_w);
  wire [7:0] issue1_onehot_w =
      (owner_memory_pair_peek_w || memory_pair_w) ? memory_second_w :
      (swap_w ? first_req_onehot_w : partner_onehot_w);

  // onehot→index 仅是三组平衡 OR；payload array mux 继续复用 IQ 既有实现。
  assign issue0_idx_o[2] = |issue0_onehot_w[7:4];
  assign issue0_idx_o[1] = |(issue0_onehot_w & 8'b1100_1100);
  assign issue0_idx_o[0] = |(issue0_onehot_w & 8'b1010_1010);
  assign issue1_idx_o[2] = |issue1_onehot_w[7:4];
  assign issue1_idx_o[1] = |(issue1_onehot_w & 8'b1100_1100);
  assign issue1_idx_o[0] = |(issue1_onehot_w & 8'b1010_1010);

  assign issue0_found_o = (|issue0_onehot_w) && !owner_memory_pair_peek_w;
  assign issue1_found_o = (|issue1_onehot_w) && !owner_memory_pair_peek_w;
  assign issue0_onehot_o = issue0_onehot_w;
  assign issue1_onehot_o = issue1_onehot_w;
  assign issue_pair_swapped_o = swap_w;
  assign memory_pair_peek_valid_o = owner_memory_pair_peek_w;

endmodule
