`include "R64Protocol.vh"
// Two independently held completion lanes, each with two fixed payload slots.
// An LSU slot can be released when this queue captures its full ROB-tagged
// result. Q occupancy owns input credit and payload writes; downstream ready
// and cancellation change only ownership and the registered head selector.
module R64LsuCompletion #(
  parameter TAG_W = 9,
  parameter ROB_W = 5
) (
  input                            clk_i,
  input                            rst_i,
  input                            flush_i,
  input      [     (1<<ROB_W)-1:0] kill_mask_i,
  input      [                1:0] in_fire_i,
  output     [                1:0] in_ready_o,
  input      [        2*TAG_W-1:0] in_tag_i,
  input      [2*`R64_RESULT_W-1:0] in_result_i,
  output     [                1:0] out_valid_o,
  output     [                1:0] out_request_o,
  input      [                1:0] out_ready_i,
  output     [        2*TAG_W-1:0] out_tag_o,
  output     [2*`R64_RESULT_W-1:0] out_result_o,
  output reg [     (1<<ROB_W)-1:0] reuse_block_o,
  output                           idle_o
);
  localparam R = `R64_RESULT_W;
  reg [1:0] valid_q[0:1], valid_d[0:1];
  reg [1:0] head_q, head_d;
  reg [TAG_W-1:0] tag_q[0:1][0:1];
  reg [R-1:0] result_q[0:1][0:1];
  reg turn_q;
  wire [1:0] free_w, write_slot_w, take_w, front_remove_w;
  wire [1:0] cancel_w[0:1];
  // Sparse publication is allowed: a canceled first arbiter winner must not
  // remap the live second payload. Port 1 still requires two free lanes.
  // Logical views retain the existing head/skid observation points; payload
  // itself stays in its capture slot for the whole lifetime of an owner.
  wire [1:0] front_q, back_q;
  wire [TAG_W-1:0] front_tag_q[0:1];
  wire [R-1:0] front_result_q[0:1];
  wire first_w = free_w[turn_q] ? turn_q : !turn_q;
  assign in_ready_o = {(&free_w), (|free_w)} & {2{!rst_i && !flush_i}};
  assign idle_o = !(|valid_q[0]) && !(|valid_q[1]);

  genvar lane, slot;
  generate
    for (lane = 0; lane < 2; lane = lane + 1) begin : g_lane
      assign free_w[lane] = !(&valid_q[lane]);
      // With no owner slot0 is prepared; with one owner the other slot is free.
      assign write_slot_w[lane] = valid_q[lane][0];
      assign front_q[lane] = valid_q[lane][head_q[lane]];
      assign back_q[lane] = valid_q[lane][!head_q[lane]];
      assign front_tag_q[lane] = tag_q[lane][head_q[lane]];
      assign front_result_q[lane] = result_q[lane][head_q[lane]];
      assign out_valid_o[lane] = front_q[lane] && !rst_i && !flush_i &&
          !cancel_w[lane][head_q[lane]];
      assign out_tag_o[lane*TAG_W+:TAG_W] = front_tag_q[lane];
      assign out_result_o[lane*R+:R] = front_result_q[lane];
      assign front_remove_w[lane] = front_q[lane] &&
          (out_ready_i[lane] || flush_i || cancel_w[lane][head_q[lane]]);
      assign take_w[lane] = (in_fire_i[0] && (first_w == lane[0])) ||
          (in_fire_i[1] && (first_w != lane[0]));
      // Demand is a hint for next-edge WB credit. It can reserve an empty or
      // canceled grant; only out_valid && out_ready transfers the held owner.
      assign out_request_o[lane] = (|valid_q[lane]) || take_w[lane];
      // Physical-lane assignment is a Q-state fact, independent of final fire.
      wire input_lane = first_w != lane[0];
      wire [TAG_W-1:0] input_tag = input_lane ? in_tag_i[TAG_W+:TAG_W] :
          in_tag_i[0+:TAG_W];
      wire [R-1:0] input_result = input_lane ? in_result_i[R+:R] : in_result_i[0+:R];
      for (slot = 0; slot < 2; slot = slot + 1) begin : g_storage
        assign cancel_w[lane][slot] = kill_mask_i[tag_q[lane][slot][ROB_W-1:0]];
        // Never borrow a departing owner's storage in its removal cycle.
        // Preparation cannot traverse take, out_ready, kill, flush or head.
        wire payload_write_w = !valid_q[lane][slot] && (write_slot_w[lane] == slot);
        always @(posedge clk_i)
          if (!rst_i && payload_write_w) begin
            tag_q[lane][slot] <= input_tag;
            result_q[lane][slot] <= input_result;
          end
      end
    end
  endgenerate

  integer l, s;
  always @* begin
    reuse_block_o = 0;
    head_d = head_q;
    for (l = 0; l < 2; l = l + 1) begin
      valid_d[l] = valid_q[l];
      for (s = 0; s < 2; s = s + 1) begin
        if (valid_q[l][s]) reuse_block_o[tag_q[l][s][ROB_W-1:0]] = 1;
        if (flush_i || cancel_w[l][s]) valid_d[l][s] = 0;
      end
      if (front_remove_w[l]) valid_d[l][head_q[l]] = 0;
      // Capture into Q-free storage has the same priority as the former
      // front_input/back_input path, including cancellation of an older head.
      if (take_w[l]) valid_d[l][write_slot_w[l]] = 1;
      // Head progress depends on existing ownership, never on incoming fire.
      // An empty lane normalizes to slot0 before its new owner becomes visible.
      if (!(|valid_q[l])) head_d[l] = 0;
      else if (front_remove_w[l]) head_d[l] = !head_q[l];
    end
  end
  always @(posedge clk_i) begin
    if (rst_i) begin
      valid_q[0] <= 0;
      valid_q[1] <= 0;
      head_q <= 0;
      turn_q <= 0;
    end else begin
      valid_q[0] <= valid_d[0];
      valid_q[1] <= valid_d[1];
      head_q <= head_d;
      if (|in_fire_i) turn_q <= !first_w;
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk_i)
    if (!rst_i) begin
      if ((in_fire_i & ~in_ready_o) != 0)
        $fatal(1, "R64LsuCompletion credit violation");
      if ((back_q & ~front_q) != 0) $fatal(1, "R64LsuCompletion hole");
    end
`endif
endmodule
