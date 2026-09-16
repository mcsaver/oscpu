// Four carryless product bits per cycle with a 64-bit accumulator. HIGH/REV
// traverse multiplier bits backwards, retaining only the requested product
// window instead of keeping a 128-bit accumulator.
module R64Clmul #(parameter TAG_W=9,parameter ROB_W=5,parameter PREQUALIFIED_INPUT=0)(
  input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
  input in_valid_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
  input [63:0] a_i,b_i,input [1:0] function_i,
  output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,output [63:0] out_data_o
);
  localparam IDLE=0,RUN=1,RESPONSE=2;
  reg [2:0] state_q;
  wire running_q=state_q[RUN],result_valid_q=state_q[RESPONSE];
  reg low_q,birth_killed_q;
  reg [(1<<ROB_W)-1:0] owner_q;
  reg [3:0] iteration_q;
  reg [TAG_W-1:0] tag_q;
  reg [63:0] a_q,b_q,acc_q;
  wire killed_w=birth_killed_q||(|(owner_q&kill_mask_i));
  assign in_ready_o=state_q[IDLE];
  assign out_valid_o=result_valid_q;
  assign out_tag_o=tag_q;assign out_data_o=acc_q;
  wire [63:0] term_w[0:3];
  genvar k;
  generate for(k=0;k<4;k=k+1)begin:gen_term
    assign term_w[k]=(low_q ? b_q[k]:b_q[63-k]) ? ((low_q) ? (a_q<<k):(a_q>>k)):64'b0;
  end endgenerate
  wire [63:0] next_acc_w=acc_q^((term_w[0]^term_w[1])^(term_w[2]^term_w[3]));
  // Owner phase is the only cancellation target. Raw terminal VALID is
  // not architectural permission; the shared WB rejects current kills.
  always @(posedge clk)begin
    if(rst||flush_i)state_q<=3'b001;
    else if(!state_q[IDLE]&&killed_w)state_q<=3'b001;
    else begin
      if(state_q[IDLE]&&in_valid_i)begin
        state_q<=3'b010;
        birth_killed_q<=PREQUALIFIED_INPUT ? 1'b0 : kill_mask_i[in_tag_i[ROB_W-1:0]];
        tag_q<=in_tag_i;
        owner_q<={{((1<<ROB_W)-1){1'b0}},1'b1}<<in_tag_i[ROB_W-1:0];
      end
      if(running_q&&(iteration_q==15||b_q==0))state_q<=3'b100;
      if(result_valid_q&&out_ready_i)state_q<=3'b001;
    end
  end
  // All arithmetic enables are registered phases, without a kill lookup.
  always @(posedge clk)begin
    if(running_q)begin
      acc_q<=next_acc_w;a_q<=low_q?a_q<<4:a_q>>4;b_q<=low_q?b_q>>4:b_q<<4;
      iteration_q<=iteration_q+1'b1;
    end
    if(state_q[IDLE]&&in_valid_i)begin
      acc_q<=0;iteration_q<=0;low_q<=function_i==1;
      a_q<=function_i==3?{1'b0,a_i[63:1]}:a_i;b_q<=b_i;
    end
  end
`ifdef R64_ASSERT
 // This mode is a boundary contract, not permission to ignore cancellation.
 // The upstream producer must have rejected current kill/reset/flush before
 // emitting the actual admission pulse. Later owner kills remain local.
 always @(posedge clk)begin
  if(PREQUALIFIED_INPUT&&in_valid_i&&in_ready_o&&
     (rst||flush_i||kill_mask_i[in_tag_i[ROB_W-1:0]]))
   $fatal(1,"numeric prequalified input accepted cancelled owner");
 end

  always @(posedge clk)if(!rst&&!flush_i)begin
    if(!$onehot(state_q))$fatal(1,"CLMUL phase ownership");
  end
`endif
endmodule
