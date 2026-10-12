`include "R64Protocol.vh"
// The wide selector depends only on registered occupancy and RR state.
// Same-cycle cancellation suppresses publication without changing selection.
// A selected dead source consumes a scheduling slot, never another live owner.
module R64LsuCompletionArbiter #(parameter TAG_W=9) (
  input clk_i, rst_i,
  input [5:0] source_occupied_i, source_live_i,
  input [6*TAG_W-1:0] source_tag_i,
  input [6*`R64_RESULT_W-1:0] source_result_i,
  output [5:0] source_take_o,
  input [1:0] completion_credit_i,
  output [1:0] completion_fire_o,
  // Resident selection notice has no ready/ack and must not depend on credit.
  // It may repeat or disappear; only source_take_o changes source ownership.
  output [1:0] selected_live_o,
  output reg [2*TAG_W-1:0] completion_tag_o,
  output reg [2*`R64_RESULT_W-1:0] completion_result_o
);
  localparam R=`R64_RESULT_W;
  reg [5:0] before_q;
  wire [35:0] order_w;
  wire [5:0] first_w,second_w;
  wire first_valid_w,second_valid_w;
  wire [2:0] unused_first_slot,unused_second_slot;
  wire [5:0] last_w=completion_credit_i[1] && second_valid_w ?
      second_w : (first_w & {6{completion_credit_i[0]}});
  reg [5:0] before_d;
  integer s;
  always @* begin
    before_d=0;
    for(s=0;s<5;s=s+1)
      before_d=before_d | ({6{last_w[s]}} & ((6'b1 << (s+1))-1'b1));
  end
  always @(posedge clk_i)
    if(rst_i) before_q<=0;
    else if(|source_take_o) before_q<=before_d;
  genvar i,j;
  generate for(i=0;i<6;i=i+1) begin:g_order
    for(j=0;j<6;j=j+1) begin:g_precedence
      assign order_w[i*6+j]=(before_q[i] && !before_q[j]) ||
          ((before_q[i]==before_q[j]) && j<i);
    end
  end endgenerate
  R64LsuOrderSelect #(.N(6),.SLOT_W(3)) select_sources (
    .valid_i(source_occupied_i),.older_i(order_w),
    .first_mask_o(first_w),.second_mask_o(second_w),
    .first_valid_o(first_valid_w),.second_valid_o(second_valid_w),
    .first_slot_o(unused_first_slot),.second_slot_o(unused_second_slot)
  );
  assign source_take_o=(first_w & {6{completion_credit_i[0] && !rst_i}}) |
      (second_w & {6{completion_credit_i[1] && !rst_i}});
  assign selected_live_o={
      (|(second_w & source_live_i)) && !rst_i,
      (|(first_w & source_live_i)) && !rst_i};
  assign completion_fire_o={
      (|(second_w & source_live_i)) && completion_credit_i[1] && !rst_i,
      (|(first_w & source_live_i)) && completion_credit_i[0] && !rst_i};
  integer e;
  always @* begin
    completion_tag_o=0; completion_result_o=0;
    for(e=0;e<6;e=e+1) begin
      completion_tag_o[0+:TAG_W]=completion_tag_o[0+:TAG_W] |
          ({TAG_W{first_w[e]}} & source_tag_i[e*TAG_W+:TAG_W]);
      completion_tag_o[TAG_W+:TAG_W]=completion_tag_o[TAG_W+:TAG_W] |
          ({TAG_W{second_w[e]}} & source_tag_i[e*TAG_W+:TAG_W]);
      completion_result_o[0+:R]=completion_result_o[0+:R] |
          ({R{first_w[e]}} & source_result_i[e*R+:R]);
      completion_result_o[R+:R]=completion_result_o[R+:R] |
          ({R{second_w[e]}} & source_result_i[e*R+:R]);
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk_i) if(!rst_i) begin
    if((source_live_i & ~source_occupied_i)!=0)
      $fatal(1,"completion source published without resident ownership");
    if((source_take_o & ~source_occupied_i)!=0)
      $fatal(1,"completion arbiter took absent source");
  end
`endif
endmodule
