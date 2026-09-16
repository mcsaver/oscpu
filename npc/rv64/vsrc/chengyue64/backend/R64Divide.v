// Tagged radix-4 division with two bounded numerical phases per digit.
// Local carry preparation is shared by ABS, 3*divisor, subtraction and sign
// correction. The quotient advances by two fixed bits, with no barrel insert.
module R64Divide #(parameter TAG_W=9,parameter ROB_W=5,parameter PREQUALIFIED_INPUT=0)(
 input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_valid_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 input [63:0] a_i,b_i,input [2:0] function_i,input word_i,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,output [63:0] out_data_o
);
 localparam IDLE=0,ABS_PREP=1,ABS_FINISH=2,CLASSIFY=3,NORMALIZE=4,ALIGN=5,
  DIGIT_PREP=6,DIGIT_FINISH=7,SIGN_PREP=8,SIGN_FINISH=9,PACK=10,RESPONSE=11;
 reg [11:0] state_q;
 reg incoming_dead_q;
 reg [(1<<ROB_W)-1:0] owner_q;
 reg negative1_q,negative2_q;
 reg [2:0] digit_fits_q;
 reg [TAG_W-1:0] tag_q;
 reg [63:0] src1_q,src2_q,quotient_q,remainder_q,result_q;
 reg signed_q,word_q,rem_result_q,quotient_negative_q,remainder_negative_q;
 reg [65:0] divisor_q,divisor3_q;
 reg [5:0] shift_q;
 reg [6:0] leading1_q,leading2_q;
 wire signed_input_w=!function_i[0];
 wire [63:0] input1_w=word_i ? {{32{signed_input_w&&a_i[31]}},a_i[31:0]}:a_i;
 wire [63:0] input2_w=word_i ? {{32{signed_input_w&&b_i[31]}},b_i[31:0]}:b_i;
 wire negative1_w=negative1_q,negative2_w=negative2_q;
 wire killed_w=!state_q[IDLE]&&(incoming_dead_q||(|(kill_mask_i&owner_q)));
 // These report registered ownership. WB rejects same-cycle kill/flush
 // before capture; the unit releases canceled ownership at this clock edge.
 assign in_ready_o=state_q[IDLE];
 assign out_valid_o=state_q[RESPONSE];
 assign out_tag_o=tag_q;
 assign out_data_o=result_q;
 // Eight local byte encoders operate in parallel. The global network
 // selects a nonzero byte; no shifted 64-bit intermediate is replicated.
 function [6:0] clz64;
  input [63:0] value;
  reg [7:0] nonzero,chosen;
  reg [2:0] local_count[0:7];
  reg [7:0] byte_value;
  reg [5:0] result;
  integer g;
  begin
   for(g=0;g<8;g=g+1)begin
    byte_value=value[g*8+:8];nonzero[g]=|byte_value;
    casez(byte_value)
     8'b1???????:local_count[g]=0;
     8'b01??????:local_count[g]=1;
     8'b001?????:local_count[g]=2;
     8'b0001????:local_count[g]=3;
     8'b00001???:local_count[g]=4;
     8'b000001??:local_count[g]=5;
     8'b0000001?:local_count[g]=6;
     default:local_count[g]=7;
    endcase
   end
   result=0;
   for(g=0;g<8;g=g+1)begin
    chosen[g]=nonzero[g]&&((nonzero>>(g+1))==0);
    result=result|({6{chosen[g]}}&{(3'd7-g[2:0]),local_count[g]});
   end
   clz64=value==0?7'd64:{1'b0,result};
  end
 endfunction
 wire [6:0] quotient_msb_w=leading2_q-leading1_q;
 wire [63:0] magnitude_w=rem_result_q?remainder_q:quotient_q;
 wire negative_result_w=rem_result_q?remainder_negative_q:quotient_negative_q;
 reg [66:0] arithmetic_a_w[0:2],arithmetic_b_w[0:2];
 reg [2:0] arithmetic_carry_w;
 always @(*)begin
  arithmetic_a_w[0]={3'b0,remainder_q};arithmetic_a_w[1]={3'b0,remainder_q};
  arithmetic_a_w[2]={3'b0,remainder_q};
  arithmetic_b_w[0]=~{1'b0,divisor_q};
  arithmetic_b_w[1]=~{divisor_q,1'b0};
  arithmetic_b_w[2]=~{1'b0,divisor3_q};
  arithmetic_carry_w=3'b111;
  if(state_q[ABS_PREP])begin
   arithmetic_a_w[0]={3'b0,src1_q}^{67{negative1_w}};
   arithmetic_a_w[1]={3'b0,src2_q}^{67{negative2_w}};
   arithmetic_b_w[0]=0;arithmetic_b_w[1]=0;
   arithmetic_carry_w[0]=negative1_w;arithmetic_carry_w[1]=negative2_w;
  end
  if(state_q[CLASSIFY])begin
   arithmetic_a_w[2]={3'b0,src2_q};arithmetic_b_w[2]={2'b0,src2_q,1'b0};
   arithmetic_carry_w[2]=0;
  end
  if(state_q[SIGN_PREP])begin
   arithmetic_a_w[0]={3'b0,magnitude_w}^{67{negative_result_w}};
   arithmetic_b_w[0]=0;arithmetic_carry_w[0]=negative_result_w;
  end
 end
 wire [66:0] arithmetic_result_w[0:2];
 wire [2:0] arithmetic_co_w;
 genvar unit;
 generate for(unit=0;unit<3;unit=unit+1)begin:arithmetic
  wire [66:0] base_w;
  wire [16:0] p_w,g_w;
  reg [66:0] base_q;
  reg [16:0] p_q,g_q;
  reg carry_q;
  R64CarryPrepare #(.WIDTH(67),.BLOCK(4)) prepare(.a_i(arithmetic_a_w[unit]),.b_i(arithmetic_b_w[unit]),
   .base_o(base_w),.propagate_o(p_w),.generate_o(g_w));
  R64CarryFinish #(.WIDTH(67),.BLOCK(4)) finish(.base_i(base_q),.propagate_i(p_q),.generate_i(g_q),
   .carry_i(carry_q),.sum_o(arithmetic_result_w[unit]),.carry_o(arithmetic_co_w[unit]));
  always @(posedge clk)if(state_q[ABS_PREP]||state_q[CLASSIFY]||state_q[DIGIT_PREP]||state_q[SIGN_PREP])begin
   base_q<=base_w;p_q<=p_w;g_q<=g_w;carry_q<=arithmetic_carry_w[unit];
  end
 end endgenerate
 // Exact borrow decisions are made in the preparation phase, in parallel
 // with the local sums. They do not wait for the final low-bit sum and then
 // fan out across the remainder selection.
 wire [3:0] select_w={digit_fits_q[2],digit_fits_q[1]&&!digit_fits_q[2],
  digit_fits_q[0]&&!digit_fits_q[1],!digit_fits_q[0]};
 wire [1:0] digit_w={select_w[3]||select_w[2],select_w[3]||select_w[1]};
 wire [63:0] remainder_next_w=({64{select_w[0]}}&remainder_q)|
  ({64{select_w[1]}}&arithmetic_result_w[0][63:0])|
  ({64{select_w[2]}}&arithmetic_result_w[1][63:0])|
  ({64{select_w[3]}}&arithmetic_result_w[2][63:0]);
 wire zero_divisor_w=src2_q==0;
 wire overflow_w=signed_q&&src1_q==64'h8000000000000000&&src2_q==64'hffffffffffffffff;
 wire [63:0] special_w=rem_result_q?(zero_divisor_w?src1_q:64'b0):
  (zero_divisor_w?64'hffffffffffffffff:src1_q);
 always @(posedge clk)begin
  if(in_valid_i&&in_ready_o)begin
   incoming_dead_q<=PREQUALIFIED_INPUT ? 1'b0 : kill_mask_i[in_tag_i[ROB_W-1:0]];
   owner_q<={{((1<<ROB_W)-1){1'b0}},1'b1}<<in_tag_i[ROB_W-1:0];
   negative1_q<=signed_input_w&&(word_i?a_i[31]:a_i[63]);
   negative2_q<=signed_input_w&&(word_i?b_i[31]:b_i[63]);
  end
  if(state_q[DIGIT_PREP])begin
   digit_fits_q[0]<={3'b0,remainder_q}>={1'b0,divisor_q};
   digit_fits_q[1]<={3'b0,remainder_q}>={divisor_q,1'b0};
   digit_fits_q[2]<={3'b0,remainder_q}>={1'b0,divisor3_q};
  end
 end
 // Cancellation changes transaction ownership only. Numerical state may
 // finish its current phase at the same edge; IDLE then hides it until reuse.
 // Thus the late kill tree does not gate hundreds of payload-register clocks.
 always @(posedge clk)begin
  if(rst||flush_i||killed_w)state_q<=12'b1<<IDLE;
  else case(1'b1)
   state_q[IDLE]:if(in_valid_i)state_q<=12'b1<<ABS_PREP;
   state_q[ABS_PREP]:state_q<=(zero_divisor_w||overflow_w)?(12'b1<<RESPONSE):(12'b1<<ABS_FINISH);
   state_q[ABS_FINISH]:state_q<=12'b1<<CLASSIFY;
   state_q[CLASSIFY]:state_q<=src1_q<src2_q?(12'b1<<SIGN_PREP):(12'b1<<NORMALIZE);
   state_q[NORMALIZE]:state_q<=12'b1<<ALIGN;
   state_q[ALIGN]:state_q<=12'b1<<DIGIT_PREP;
   state_q[DIGIT_PREP]:state_q<=12'b1<<DIGIT_FINISH;
   state_q[DIGIT_FINISH]:state_q<=shift_q==0?(12'b1<<SIGN_PREP):(12'b1<<DIGIT_PREP);
   state_q[SIGN_PREP]:state_q<=12'b1<<SIGN_FINISH;
   state_q[SIGN_FINISH]:state_q<=12'b1<<PACK;
   state_q[PACK]:state_q<=12'b1<<RESPONSE;
   state_q[RESPONSE]:if(out_ready_i)state_q<=12'b1<<IDLE;
   default:state_q<=12'b1<<IDLE;
  endcase
 end
 always @(posedge clk)begin
  case(1'b1)
   state_q[IDLE]:if(in_valid_i)begin
    tag_q<=in_tag_i;src1_q<=input1_w;src2_q<=input2_w;
    signed_q<=signed_input_w;word_q<=word_i;rem_result_q<=function_i[1];
   end
   state_q[ABS_PREP]:begin
    quotient_q<=0;quotient_negative_q<=negative1_w^negative2_w;remainder_negative_q<=negative1_w;
    // A normal divide overwrites this before RESPONSE. Avoid operand-dependent clock gating.
    result_q<=word_q?{{32{special_w[31]}},special_w[31:0]}:special_w;
   end
   state_q[ABS_FINISH]:begin
    src1_q<=arithmetic_result_w[0][63:0];src2_q<=arithmetic_result_w[1][63:0];
    remainder_q<=arithmetic_result_w[0][63:0];
   end
   state_q[CLASSIFY]:begin leading1_q<=clz64(src1_q);leading2_q<=clz64(src2_q);end
   state_q[NORMALIZE]:begin
    shift_q<={quotient_msb_w[5:1],1'b0};divisor_q<={2'b0,src2_q};
    divisor3_q<=arithmetic_result_w[2][65:0];
   end
   state_q[ALIGN]:begin divisor_q<=divisor_q<<shift_q;divisor3_q<=divisor3_q<<shift_q;end
   state_q[DIGIT_FINISH]:begin
    quotient_q<={quotient_q[61:0],digit_w};remainder_q<=remainder_next_w;
    divisor_q<=divisor_q>>2;divisor3_q<=divisor3_q>>2;shift_q<=shift_q-6'd2;
   end
   state_q[SIGN_FINISH]:result_q<=arithmetic_result_w[0][63:0];
   state_q[PACK]:result_q<=word_q?{{32{result_q[31]}},result_q[31:0]}:result_q;
   default:begin end
  endcase
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
  if(state_q==0||(state_q&(state_q-1'b1))!=0)$fatal(1,"R64 DIV illegal phase ownership");
  if((state_q[DIGIT_PREP]||state_q[DIGIT_FINISH])&&(divisor_q==0||shift_q[0]))
   $fatal(1,"R64 DIV invalid divisor/digit alignment");
  if(state_q[DIGIT_FINISH]&&((select_w&(select_w-1'b1))!=0||select_w==0))
   $fatal(1,"R64 DIV non-exclusive quotient selection");
 end
`endif
endmodule
