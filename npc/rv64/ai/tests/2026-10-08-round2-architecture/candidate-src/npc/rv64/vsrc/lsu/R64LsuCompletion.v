`include "R64Uop.vh"
// Two independent completion lanes, each with two fixed payload slots. An LSU
// slot can be released when this queue captures its full ROB-tagged result.
// Only owner bits and a head pointer change on pop/cancel; payload never moves.
// Credit, rank-to-lane routing and empty-slot preparation depend only on Q state.
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
  reg [1:0] occupied_q[0:1];
  reg [1:0] head_q;
  reg [TAG_W-1:0] slot_tag_q[0:3];
  reg [R-1:0] slot_result_q[0:3];
  reg turn_q;
  wire [1:0] free_w = {!(&occupied_q[1]), !(&occupied_q[0])};
  wire first_w = free_w[turn_q] ? turn_q : !turn_q;
  assign in_ready_o = {(&free_w), (|free_w)} & {2{!rst_i && !flush_i}};
  assign idle_o = (occupied_q[0] | occupied_q[1]) == 0;
  genvar g, s;
  generate
    for (g = 0; g < 2; g = g + 1) begin : gen_lane
      wire [TAG_W-1:0] head_tag = head_q[g] ? slot_tag_q[g*2+1] : slot_tag_q[g*2];
      assign out_valid_o[g] = occupied_q[g][head_q[g]] && !flush_i &&
          !kill_mask_i[head_tag[ROB_W-1:0]] && !rst_i;
      assign out_tag_o[g*TAG_W+:TAG_W] = head_tag;
      assign out_result_o[g*R+:R] = head_q[g] ? slot_result_q[g*2+1] : slot_result_q[g*2];
      // Sparse input 10 retains rank 1's physical lane; never compact on kill.
      wire input_lane = first_w != g[0];
      wire take = in_fire_i[input_lane];
      wire [TAG_W-1:0] input_tag = input_lane ? in_tag_i[TAG_W+:TAG_W] : in_tag_i[0+:TAG_W];
      wire [R-1:0] input_result = input_lane ? in_result_i[R+:R] : in_result_i[0+:R];
      wire target_slot = occupied_q[g][head_q[g]] ? !head_q[g] : head_q[g];
      // Port demand may precede registered VALID. This is only a hint; killed
      // or empty requests cannot transfer a tag/value without current VALID.
      assign out_request_o[g] = (|occupied_q[g]) || take;
      wire [1:0] survive;
      for (s = 0; s < 2; s = s + 1) begin : gen_slot
        wire drop = kill_mask_i[slot_tag_q[g*2+s][ROB_W-1:0]] ||
            ((head_q[g] == s[0]) && out_ready_i[g]);
        assign survive[s] = occupied_q[g][s] && !drop;
        wire payload_write = !rst_i && free_w[g] && (target_slot == s[0]);
        // Empty storage has no semantic owner. Reset inhibits preparation,
        // while cancel and final capture never enter payload D/enable.
        always @(posedge clk_i) begin
          if (payload_write) begin
            slot_tag_q[g*2+s] <= input_tag;
            slot_result_q[g*2+s] <= input_result;
          end
          if (rst_i || flush_i) occupied_q[g][s] <= 0;
          else occupied_q[g][s] <= survive[s] || (take && target_slot == s[0]);
        end
`ifdef R64_ASSERT
        reg checked_q = 0;
        reg previously_occupied_q, previously_captured_q, previously_reset_q;
        reg [TAG_W+R-1:0] captured_payload_q;
        always @(posedge clk_i) begin
          if (payload_write && (rst_i || occupied_q[g][s]))
            $fatal(1, "R64LsuCompletion prewrites occupied/reset slot");
          if (take && target_slot == s[0] && !payload_write)
            $fatal(1, "R64LsuCompletion capture without same-edge payload write");
          if (checked_q) begin
            if (occupied_q[g][s] && !previously_occupied_q && !previously_captured_q)
              $fatal(1, "R64LsuCompletion owner appeared without capture");
            if (previously_reset_q && occupied_q[g][s])
              $fatal(1, "R64LsuCompletion owner survived reset");
            if (previously_captured_q &&
                (!occupied_q[g][s] || {slot_tag_q[g*2+s], slot_result_q[g*2+s]} !== captured_payload_q))
              $fatal(1, "R64LsuCompletion capture did not retain current full payload");
          end
          checked_q <= 1;
          previously_occupied_q <= occupied_q[g][s];
          previously_reset_q <= rst_i;
          previously_captured_q <= !rst_i && !flush_i && take && target_slot == s[0];
          captured_payload_q <= {input_tag, input_result};
        end
`endif
      end
      always @(posedge clk_i) begin
        if (rst_i) head_q[g] <= 0;
        // An old surviving owner always precedes a newly captured owner.
        else if (survive[head_q[g]]) head_q[g] <= head_q[g];
        else if (survive[!head_q[g]]) head_q[g] <= !head_q[g];
        else if (take) head_q[g] <= target_slot;
      end
`ifdef R64_ASSERT
      always @(posedge clk_i)
        if (!rst_i) begin
          if ((|occupied_q[g]) && !occupied_q[g][head_q[g]])
            $fatal(1, "R64LsuCompletion head has no owner");
          if (take && (!free_w[g] || occupied_q[g][target_slot]))
            $fatal(1, "R64LsuCompletion overwrites occupied slot");
        end
`endif
    end
  endgenerate
  integer l, k;
  always @* begin
    reuse_block_o = 0;
    for (l = 0; l < 2; l = l + 1)
      for (k = 0; k < 2; k = k + 1)
        if (occupied_q[l][k]) reuse_block_o[slot_tag_q[l*2+k][ROB_W-1:0]] = 1;
  end
  always @(posedge clk_i) begin
    if (rst_i) turn_q <= 0;
    else if (in_fire_i[0]) turn_q <= !first_w;
    else if (in_fire_i[1]) turn_q <= first_w;
  end
`ifdef R64_ASSERT
  always @(posedge clk_i)
    if ((in_fire_i & ~in_ready_o) != 0)
      $fatal(1, "R64LsuCompletion credit violation");
`endif
endmodule
