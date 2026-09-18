// One native DIV/SQRT owner. Input decomposition, normalization and initial
// recurrence construction are separate phases; the exact result traverses
// the common five-stage rounder. DIV consumes two bits per two cycles; SQRT
// also consumes two. Root multiples update by fixed shift/selection only.
module R64FpLong #(parameter TAG_W=9,parameter ROB_W=5)(
 input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_fire_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 input [63:0] a_i,b_i,input double_i,input [2:0] rounding_i,input sqrt_i,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,
 output [63:0] out_value_o,output [4:0] out_flags_o
);
 localparam GROUP_BITS=ROB_W>=3?8:(1<<ROB_W),GROUPS=(1<<ROB_W)/GROUP_BITS;
 localparam LOCAL_INDEX_W=ROB_W>=3?3:ROB_W;
 localparam IDLE=0,NORMALIZE=1,INITIALIZE=2,DIVIDE=3,SQUARE=4,DIGIT_FINISH=5,FINISH=6,
  RANGE=7,SHIFT=8,LOCAL=9,GLOBAL=10,PACK=11,RESPONSE=12,TRIPLE_PREP=13,TRIPLE_FINISH=14;
 reg [14:0] state_q;
 reg [TAG_W-1:0] tag_q;reg [GROUPS-1:0] birth_killed_q;
 reg [(1<<ROB_W)-1:0] owner_q;
 wire killed_w=(|birth_killed_q)||(|(owner_q&kill_mask_i));
 assign in_ready_o=state_q[IDLE];
 assign out_valid_o=state_q[RESPONSE];
 assign out_tag_o=tag_q;

 wire [52:0] raw_a_w,raw_b_w,normalized_a_w,normalized_b_w;
 wire signed [13:0] base_a_w,base_b_w,normalized_ea_w,normalized_eb_w;
 wire sa_w,sb_w,na_w,nb_w,sna_w,snb_w,ia_w,ib_w,za_w,zb_w;
 R64FpDecompose #(.RAW_SPECIAL_NUMERIC(1)) ua(.value_i(a_i),.double_i(double_i),.boxed_o(),
  .sign_o(sa_w),.nan_o(na_w),.snan_o(sna_w),.inf_o(ia_w),.zero_o(za_w),
  .base_exponent_o(base_a_w),.raw_significand_o(raw_a_w));
 R64FpDecompose #(.RAW_SPECIAL_NUMERIC(1)) ub(.value_i(b_i),.double_i(double_i),.boxed_o(),
  .sign_o(sb_w),.nan_o(nb_w),.snan_o(snb_w),.inf_o(ib_w),.zero_o(zb_w),
  .base_exponent_o(base_b_w),.raw_significand_o(raw_b_w));
 reg [52:0] a0_q,b0_q,a1_q,b1_q;
 reg signed [13:0] ea0_q,eb0_q,ea1_q,eb1_q;
 reg sa0_q,sb0_q,na0_q,nb0_q,sna0_q,snb0_q,ia0_q,ib0_q,za0_q,zb0_q;
 reg sqrt_q,double_q,sign_q;
 reg [2:0] rounding_q;
 reg [1:0] special_q;
 reg [4:0] flags_q;
 R64FpNormalize #(.IEEE_INPUT(1)) normalize_a(.raw_significand_i(a0_q),.base_exponent_i(ea0_q),
  .significand_o(normalized_a_w),.exponent_o(normalized_ea_w));
 R64FpNormalize #(.IEEE_INPUT(1)) normalize_b(.raw_significand_i(b0_q),.base_exponent_i(eb0_q),
  .significand_o(normalized_b_w),.exponent_o(normalized_eb_w));
 wire invalid_w=sqrt_q ? (sna0_q||(sa0_q&&!za0_q&&!na0_q)):
  (sna0_q||snb0_q||(za0_q&&zb0_q)||(ia0_q&&ib0_q));
 wire nan_w=invalid_w||na0_q||(!sqrt_q&&nb0_q);
 wire divide_zero_w=!sqrt_q&&!na0_q&&!nb0_q&&!ia0_q&&!za0_q&&zb0_q;
 wire inf_w=sqrt_q ? ia0_q:(ia0_q||zb0_q);
 wire zero_w=sqrt_q ? za0_q:(za0_q||ib0_q);

 reg signed [13:0] exponent_q;
 reg [5:0] count_q;
 reg [59:0] remainder_q;reg sticky_q;reg [59:0] rhs_q[0:2];
 reg [52:0] divisor_q;
 reg [111:0] radicand_q;
 wire [111:0] initial_radicand_w=ea1_q[0]?{a1_q,59'b0}:{1'b0,a1_q,58'b0};
 reg [55:0] digits_q;
 reg [57:0] root3_q[0:2];
 // DIV produces a radix-4 digit over local/global carry phases.
 // Three local trial summaries and magnitude comparisons run in parallel.
 // The selected summary alone crosses the register into shared global carry.
 wire [59:0] trial_lhs_w=remainder_q;
 wire [59:0] div_base_w[0:2],triple_base_w,difference_w;
 wire [14:0] div_p_w[0:2],div_g_w[0:2],triple_p_w,triple_g_w;
 reg [59:0] local_base_q,trial_lhs_q;
 reg [14:0] local_p_q,local_g_q;
 reg [1:0] digit_q;
 wire [2:0] select_w={fits_w[2],fits_w[1]&&!fits_w[2],!fits_w[1]&&!fits_w[2]};
 wire [2:0] fits_w,equal_w;
 genvar trial;
 generate for(trial=0;trial<3;trial=trial+1)begin:divide_trial
  wire [59:0] rhs_w=rhs_q[trial];
  R64CarryPrepare #(.WIDTH(60),.BLOCK(4)) prepare(
   .a_i(trial_lhs_w),.b_i(~rhs_w),.base_o(div_base_w[trial]),
   .propagate_o(div_p_w[trial]),.generate_o(div_g_w[trial]));
  assign fits_w[trial]=trial_lhs_w>=rhs_w;
  assign equal_w[trial]=trial_lhs_w==rhs_w;
 end endgenerate
 R64CarryPrepare #(.WIDTH(60),.BLOCK(4)) triple_prepare(
  .a_i({7'b0,divisor_q}),.b_i({6'b0,divisor_q,1'b0}),.base_o(triple_base_w),
  .propagate_o(triple_p_w),.generate_o(triple_g_w));
 wire [59:0] selected_base_w=({60{select_w[0]}}&div_base_w[0])|
  ({60{select_w[1]}}&div_base_w[1])|
  ({60{select_w[2]}}&div_base_w[2]);
 wire [14:0] selected_p_w=({15{select_w[0]}}&div_p_w[0])|
  ({15{select_w[1]}}&div_p_w[1])|
  ({15{select_w[2]}}&div_p_w[2]);
 wire [14:0] selected_g_w=({15{select_w[0]}}&div_g_w[0])|
  ({15{select_w[1]}}&div_g_w[1])|
  ({15{select_w[2]}}&div_g_w[2]);
 R64CarryFinish #(.WIDTH(60),.BLOCK(4)) digit_finish(
  .base_i(local_base_q),.propagate_i(local_p_q),.generate_i(local_g_q),
  .carry_i(!state_q[TRIPLE_FINISH]),.sum_o(difference_w),.carry_o());
 wire [59:0] residual_w=(|digit_q)?difference_w:trial_lhs_q;
 wire [55:0] next_digits_w={digits_q[53:0],digit_q};
 reg [55:0] round_sig_q;
 wire smaller_w=a1_q<b1_q;
 wire signed [13:0] difference_exp_w,lower_exp_w;
 R64WideAdd #(.WIDTH(14),.BLOCK(2)) exponent_normal(
  .a_i(ea1_q),.b_i(~eb1_q),.carry_i(1'b1),.sum_o(difference_exp_w),.carry_o());
 R64WideAdd #(.WIDTH(14),.BLOCK(2)) exponent_lower(
  .a_i(ea1_q),.b_i(~eb1_q),.carry_i(1'b0),.sum_o(lower_exp_w),.carry_o());
 wire [4:0] round_enable_w={state_q[PACK],state_q[GLOBAL],state_q[LOCAL],state_q[SHIFT],state_q[RANGE]};
 R64FpRoundPipe round(.clk(clk),.enable_i(round_enable_w),.sign_i(sign_q),.double_i(double_q),
  .rounding_i(rounding_q),.exponent_i(exponent_q),.significand_i(round_sig_q),
  .special_i(special_q),.flags_i(flags_q),.value_o(out_value_o),.flags_o(out_flags_o));

 genvar group;
 generate for(group=0;group<GROUPS;group=group+1)begin:admission_cancel
  wire [GROUP_BITS-1:0] mask_w=kill_mask_i[group*GROUP_BITS+:GROUP_BITS];
  always @(posedge clk)if(state_q[IDLE]&&in_fire_i)
   birth_killed_q[group]<=((in_tag_i[ROB_W-1:0]>>LOCAL_INDEX_W)==ROB_W'(group))&&
    mask_w[in_tag_i[LOCAL_INDEX_W-1:0]];
 end endgenerate

 // Cancellation only changes the transaction owner. Payload clock enables
 // depend on registered phase, never on the late external kill lookup.
 always @(posedge clk)begin
  if(rst||flush_i)state_q<=15'b1;
  else if(!state_q[IDLE]&&killed_w)state_q<=15'b1;
  else begin
   case(1'b1)
    state_q[IDLE]:if(in_fire_i)begin
     tag_q<=in_tag_i;
     owner_q<={{((1<<ROB_W)-1){1'b0}},1'b1}<<in_tag_i[ROB_W-1:0];
     state_q<=15'b1<<NORMALIZE;
    end
    state_q[NORMALIZE]:state_q<=15'b1<<INITIALIZE;
    state_q[INITIALIZE]:state_q<=special_q!=0?(15'b1<<FINISH):(sqrt_q?(15'b1<<SQUARE):(15'b1<<TRIPLE_PREP));
    state_q[TRIPLE_PREP]:state_q<=15'b1<<TRIPLE_FINISH;
    state_q[TRIPLE_FINISH]:state_q<=15'b1<<DIVIDE;
    state_q[DIVIDE],state_q[SQUARE]:state_q<=15'b1<<DIGIT_FINISH;
    state_q[DIGIT_FINISH]:state_q<=(count_q<=2)?(15'b1<<FINISH):
     sqrt_q?(15'b1<<SQUARE):(15'b1<<DIVIDE);
    state_q[FINISH]:state_q<=15'b1<<RANGE;
    state_q[RANGE]:state_q<=15'b1<<SHIFT;
    state_q[SHIFT]:state_q<=15'b1<<LOCAL;
    state_q[LOCAL]:state_q<=15'b1<<GLOBAL;
    state_q[GLOBAL]:state_q<=15'b1<<PACK;
    state_q[PACK]:state_q<=15'b1<<RESPONSE;
    state_q[RESPONSE]:if(out_ready_i)state_q<=15'b1;
    default:state_q<=15'b1;
   endcase
  end
 end
 always @(posedge clk)begin
  if(state_q[IDLE]&&in_fire_i)begin
   a0_q<=raw_a_w;b0_q<=raw_b_w;ea0_q<=base_a_w;eb0_q<=base_b_w;
   sa0_q<=sa_w;sb0_q<=sb_w;na0_q<=na_w;nb0_q<=nb_w;sna0_q<=sna_w;snb0_q<=snb_w;
   ia0_q<=ia_w;ib0_q<=ib_w;za0_q<=za_w;zb0_q<=zb_w;
   sqrt_q<=sqrt_i;double_q<=double_i;rounding_q<=rounding_i;
  end
  if(state_q[NORMALIZE])begin
   a1_q<=normalized_a_w;b1_q<=normalized_b_w;ea1_q<=normalized_ea_w;eb1_q<=normalized_eb_w;
   sign_q<=sqrt_q?sa0_q:sa0_q^sb0_q;
   special_q<=nan_w?2'd3:inf_w?2'd2:zero_w?2'd1:2'd0;
   flags_q<={invalid_w,divide_zero_w,3'b0};
  end
  if(state_q[INITIALIZE])begin
   exponent_q<=sqrt_q?(ea1_q>>>1):(smaller_w?lower_exp_w:difference_exp_w);
   divisor_q<=b1_q;
   remainder_q<=sqrt_q?{56'b0,initial_radicand_w[111:108]}:
    smaller_w?{5'b0,a1_q,2'b0}:{6'b0,a1_q,1'b0};
   rhs_q[0]<=sqrt_q?60'd1:{7'b0,b1_q};
   rhs_q[1]<=sqrt_q?60'd4:{6'b0,b1_q,1'b0};
   rhs_q[2]<=60'd9;sticky_q<=0;
   radicand_q<=initial_radicand_w<<4;
   digits_q<=0;count_q<=double_q?6'd56:6'd28;
   root3_q[0]<=0;root3_q[1]<=1;root3_q[2]<=2;
  end
  if(state_q[TRIPLE_PREP])begin
   local_base_q<=triple_base_w;local_p_q<=triple_p_w;local_g_q<=triple_g_w;
  end
  if(state_q[TRIPLE_FINISH])begin
   rhs_q[2]<=difference_w;
  end
  if(state_q[DIVIDE]||state_q[SQUARE])begin
   local_base_q<=selected_base_w;
   local_p_q<=selected_p_w;local_g_q<=selected_g_w;
   trial_lhs_q<=trial_lhs_w;
   // Exact zero is decided alongside trial comparison, before global carry.
   sticky_q<=(fits_w[0]?!(|(select_w&equal_w)):(|trial_lhs_w))||
    (sqrt_q&&(|radicand_q));
   digit_q<=fits_w[2]?2'd3:fits_w[1]?2'd2:{1'b0,fits_w[0]};
  end
  if(state_q[DIGIT_FINISH])begin
   digits_q<=next_digits_w;
   radicand_q<=radicand_q<<4;
   count_q<=count_q-6'd2;
  end
  // Keep the next iteration's operands in canonical form. No DIV/SQRT
  // type mux precedes local comparison or local carry.
  if(state_q[DIGIT_FINISH])begin
   remainder_q<=sqrt_q?{residual_w[55:0],radicand_q[111:108]}:{residual_w[57:0],2'b0};
  end
  if(state_q[DIGIT_FINISH]&&sqrt_q)begin
   rhs_q[0]<={1'b0,next_digits_w,3'b001};
   rhs_q[1]<={next_digits_w,4'b0100};
   if(digit_q==2'd0)begin
    root3_q[0]<={root3_q[0][55:0],2'd0};
    root3_q[1]<={root3_q[0][55:0],2'd1};
    root3_q[2]<={root3_q[0][55:0],2'd2};
    rhs_q[2]<={root3_q[0][54:0],2'd1,3'b001};
   end
   else if(digit_q==2'd1)begin
    root3_q[0]<={root3_q[0][55:0],2'd3};
    root3_q[1]<={root3_q[1][55:0],2'd0};
    root3_q[2]<={root3_q[1][55:0],2'd1};
    rhs_q[2]<={root3_q[1][54:0],2'd0,3'b001};
   end
   else if(digit_q==2'd2)begin
    root3_q[0]<={root3_q[1][55:0],2'd2};
    root3_q[1]<={root3_q[1][55:0],2'd3};
    root3_q[2]<={root3_q[2][55:0],2'd0};
    rhs_q[2]<={root3_q[1][54:0],2'd3,3'b001};
   end
   else if(digit_q==2'd3)begin
    root3_q[0]<={root3_q[2][55:0],2'd1};
    root3_q[1]<={root3_q[2][55:0],2'd2};
    root3_q[2]<={root3_q[2][55:0],2'd3};
    rhs_q[2]<={root3_q[2][54:0],2'd2,3'b001};
   end
  end
  if(state_q[FINISH])begin
   round_sig_q<=(double_q?digits_q:(digits_q<<28))|
    {55'b0,sticky_q};
  end
 end
`ifdef R64_ASSERT
 always @(posedge clk)if(!rst&&!flush_i)begin
  if(!$onehot(state_q))$fatal(1,"R64 FP long lost phase owner");
  if(in_fire_i&&!in_ready_o)$fatal(1,"R64 FP long accepted without owner credit");
 end
`endif
endmodule
