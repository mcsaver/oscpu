// Nineteen fixed-advance stages share one S/D arithmetic datapath; a reserved terminal owns backpressure:
// decompose -> normalize -> product5 -> scale/order/align3 -> carry2 -> coarse/fine normalize -> range/jam/local/global/pack5.
// ADD uses an exact unity product and MUL uses a same-sign zero addend;
// every operation rounds once. Only the final pack selects 24/53 precision.
module R64FpFma #(parameter TAG_W=9,parameter ROB_W=5)(
  input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
  input in_fire_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
  input [63:0] a_i,b_i,c_i,input double_i,input [2:0] rounding_i,
  input [1:0] kind_i,input negate_product_i,negate_addend_i,
  output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,
  output [63:0] out_value_o,output [4:0] out_flags_o
);
  wire [52:0] sig_w[0:2];
  wire signed [13:0] exp_w[0:2];
  wire [2:0] sign_w,nan_w,snan_w,inf_w,zero_w;
  wire [191:0] operands_w={c_i,b_i,a_i};
  genvar k;
  generate for(k=0;k<3;k=k+1)begin:gen_unpack
    R64FpDecompose #(.RAW_SPECIAL_NUMERIC(1)) unpack(.value_i(operands_w[k*64+:64]),.double_i(double_i),
      .boxed_o(),.sign_o(sign_w[k]),.nan_o(nan_w[k]),.snan_o(snan_w[k]),
      .inf_o(inf_w[k]),.zero_o(zero_w[k]),.base_exponent_o(exp_w[k]),.raw_significand_o(sig_w[k]));
  end endgenerate
  wire add_w=kind_i==0,mul_w=kind_i==1;
  // Format classification ends at the first register. Combining three
  // operand classes and the operation belongs to normalization's next stage.
  reg [2:0] sign0_q,nan0_q,snan0_q,inf0_q,zero0_q;
  reg [1:0] kind0_q;
  reg np0_q,nc0_q;
  wire add0_w=kind0_q==0,mul0_w=kind0_q==1;
  wire psign1_w=sign0_q[0]^(add0_w?1'b0:sign0_q[1])^np0_q;
  wire csign1_w=(add0_w?sign0_q[1]:mul0_w?psign1_w:sign0_q[2])^nc0_q;
  wire pzero1_w=zero0_q[0]||(!add0_w&&zero0_q[1]);
  wire pinf1_w=inf0_q[0]||(!add0_w&&inf0_q[1]);
  wire cinf1_w=add0_w?inf0_q[1]:!mul0_w&&inf0_q[2];
  wire czero1_w=add0_w?zero0_q[1]:mul0_w||zero0_q[2];
  wire any_nan1_w=nan0_q[0]||nan0_q[1]||(!add0_w&&!mul0_w&&nan0_q[2]);
  wire any_snan1_w=snan0_q[0]||snan0_q[1]||(!add0_w&&!mul0_w&&snan0_q[2]);
  wire invalid_product1_w=!add0_w&&((zero0_q[0]&&inf0_q[1])||(inf0_q[0]&&zero0_q[1]));
  wire invalid1_w=any_snan1_w||invalid_product1_w||
   (pinf1_w&&cinf1_w&&!nan0_q[0]&&(add0_w||!nan0_q[1])&&psign1_w!=csign1_w);
  wire zero_sign1_w=psign1_w==csign1_w?psign1_w:control_q[0][11:9]==2;
  wire [1:0] special1_w=any_nan1_w||invalid1_w?2'd3:
   pinf1_w||cinf1_w?2'd2:pzero1_w&&czero1_w?2'd1:2'd0;
  wire special_sign1_w=pinf1_w?psign1_w:cinf1_w?csign1_w:zero_sign1_w;
  localparam STAGES=19;
  wire [STAGES-1:0] stage_live_w;
  wire [68:0] terminal_w;
  reg [12:0] control_q[0:STAGES-1];
  wire [12:0] control_w={double_i,rounding_i,9'b0};
  wire [12:0] control1_w={control_q[0][12:9],special1_w,special_sign1_w,{invalid1_w,4'b0},zero_sign1_w};
  R64NumericOwner #(.STAGES(STAGES),.SLOT_W(5),.CAPACITY(22),.DATA_W(69),.TAG_W(TAG_W),.ROB_W(ROB_W)) owner(
   .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .in_valid_i(in_fire_i),.in_ready_o(in_ready_o),.in_tag_i(in_tag_i),.stage_live_o(stage_live_w),
   .result_i({flags18_q,value18_q}),.out_valid_o(out_valid_o),.out_ready_i(out_ready_i),
   .out_tag_o(out_tag_o),.out_data_o(terminal_w));
  generate for(k=0;k<STAGES;k=k+1)begin:stage
   wire ready_w=1'b1;
   wire live_w=stage_live_w[k];
   if(k==0)begin
    always @(posedge clk)if(in_fire_i)control_q[k]<=control_w;
   end else if(k==1)begin
    always @(posedge clk)if(stage[0].live_w)control_q[k]<=control1_w;
   end else begin
    always @(posedge clk)if(stage[k-1].live_w)control_q[k]<=control_q[k-1];
   end
  end endgenerate
  reg [52:0] a0_q,b0_q,c0_q;
  reg signed [13:0] ea0_q,eb0_q,ec0_q;
  wire [52:0] normalized_sig_w[0:2];
  wire signed [13:0] normalized_exp_w[0:2];
  R64FpNormalize #(.IEEE_INPUT(1)) normalize_a(.raw_significand_i(a0_q),.base_exponent_i(ea0_q),
    .significand_o(normalized_sig_w[0]),.exponent_o(normalized_exp_w[0]));
  R64FpNormalize #(.IEEE_INPUT(1)) normalize_b(.raw_significand_i(b0_q),.base_exponent_i(eb0_q),
    .significand_o(normalized_sig_w[1]),.exponent_o(normalized_exp_w[1]));
  R64FpNormalize #(.IEEE_INPUT(1)) normalize_c(.raw_significand_i(c0_q),.base_exponent_i(ec0_q),
    .significand_o(normalized_sig_w[2]),.exponent_o(normalized_exp_w[2]));
  reg [52:0] a1_q,b1_q,c1_q;
  reg signed [13:0] ea1_q,eb1_q,ec1_q;
  reg ps1_q,cs1_q;
  wire [105:0] product6_q;
  reg [52:0] c6_q;
  reg signed [13:0] ep6_q,ec6_q;
  reg ps6_q,cs6_q;
  reg [52:0] c2_q;
  reg signed [13:0] ep2_q,ec2_q;
  reg ps2_q,cs2_q;
  reg [52:0] c_mid_q[0:2];
  reg signed [13:0] ep_mid_q[0:2],ec_mid_q[0:2];
  reg ps_mid_q[0:2],cs_mid_q[0:2];
  wire [4:0] product_enable_w;
  genvar product_stage;
  generate for(product_stage=0;product_stage<5;product_stage=product_stage+1)begin:product_enable
   assign product_enable_w[product_stage]=stage[product_stage+2].ready_w&&stage[product_stage+1].live_w;
  end endgenerate
  R64FpProductPipe product(.clk(clk),.enable_i(product_enable_w),.a_i(a1_q),.b_i(b1_q),.product_o(product6_q));
  // Normalize product scale before ordering, then calculate both exponent
  // distances in parallel. The wide sticky shifter has its own next stage.
  reg [105:0] product7_q;
  reg [52:0] c7_q;
  reg signed [13:0] ep7_q,ec7_q;
  reg ps7_q,cs7_q;
  wire [127:0] pbase_w=product7_q[105]?{3'b0,product7_q,19'b0}:{2'b0,product7_q,20'b0};
  wire [127:0] cbase_w={3'b0,c7_q,72'b0};
  wire product_larger_w=(c7_q==0)||((product7_q!=0)&&
   ((ep7_q>ec7_q)||((ep7_q==ec7_q)&&(pbase_w>=cbase_w))));
  wire [13:0] distance_pc_w=ep7_q-ec7_q,distance_cp_w=ec7_q-ep7_q;
  reg [127:0] big8_q,small8_q;
  reg [13:0] distance8_q;
  reg signed [13:0] reference8_q;
  reg subtract8_q,sign8_q;
  function [127:0] shift_jam;
    input [127:0] value;input [13:0] distance;
    reg [127:0] shifted,prefix;
    integer bit_index;
    begin
      // Sticky is selected from a parallel prefix, not accumulated behind
      // each barrel mux. All upper result bits use an ordinary right shift.
      for(bit_index=0;bit_index<128;bit_index=bit_index+1)
        prefix[bit_index]=|(value & ((128'd1<<bit_index)-128'd1))|value[bit_index];
      shifted=value>>distance[6:0];
      shifted[0]=prefix[distance[6:0]];
      shift_jam=(|distance[13:7]) ? {127'b0,|value}:shifted;
    end
  endfunction
  reg [127:0] big9_q,small9_q;
  reg signed [13:0] reference9_q;
  reg subtract9_q,sign9_q;
  reg [127:0] magnitude11_q;
  reg signed [13:0] reference11_q;
  reg sign11_q;
  wire [127:0] sum_w;
  reg [127:0] base10_q;
  reg [31:0] propagate10_q,generate10_q;
  reg subtract10_q,sign10_q;
  reg signed [13:0] reference10_q;
  wire [127:0] base_w;
  wire [31:0] propagate_w,generate_w;
  R64CarryPrepare #(.WIDTH(128),.BLOCK(4)) magnitude_prepare(.a_i(big9_q),.b_i(small9_q),
   .base_o(base_w),.propagate_o(propagate_w),.generate_o(generate_w));
  R64CarryFinish #(.WIDTH(128),.BLOCK(4)) magnitude_finish(.base_i(base10_q),
   .propagate_i(propagate10_q),.generate_i(generate10_q),.carry_i(subtract10_q),
   .sum_o(sum_w),.carry_o());
  // Coarse and fine leading-zero decisions are separate numerical phases.
  // Exponent subtraction by multiples of16 precedes the final four-bit count.
  function [130:0] normalize_coarse;
    input [127:0] value;reg [127:0] scan;reg [2:0] count;
    begin
      scan=value;count=0;
      if(scan[127:64]==0)begin count=count+3'd4;scan=scan<<64;end
      if(scan[127:96]==0)begin count=count+3'd2;scan=scan<<32;end
      if(scan[127:112]==0)begin count=count+3'd1;scan=scan<<16;end
      normalize_coarse={count,scan};
    end
  endfunction
  function [131:0] normalize_fine;
    input [127:0] value;reg [127:0] scan;reg [3:0] count;
    begin
      scan=value;count=0;
      if(scan[127:120]==0)begin count=count+4'd8;scan=scan<<8;end
      if(scan[127:124]==0)begin count=count+4'd4;scan=scan<<4;end
      if(scan[127:126]==0)begin count=count+4'd2;scan=scan<<2;end
      if(!scan[127])begin count=count+4'd1;scan=scan<<1;end
      normalize_fine={count,scan};
    end
  endfunction
  wire [130:0] coarse_w=normalize_coarse(magnitude11_q);
  reg [127:0] coarse12_q;
  reg signed [13:0] reference12_q;
  reg sign12_q;
  wire [131:0] fine_w=normalize_fine(coarse12_q);
  wire [127:0] normalized_w=fine_w[127:0];
  reg [55:0] sig13_q;
  reg signed [13:0] exp13_q;
  reg sign13_q;
  wire [63:0] value18_q;
  wire [4:0] flags18_q;
  wire [4:0] round_enable_w;
  genvar round_stage;
  generate for(round_stage=0;round_stage<5;round_stage=round_stage+1)begin:round_enable
   assign round_enable_w[round_stage]=stage_live_w[round_stage+13];
  end endgenerate
  R64FpRoundPipe round(.clk(clk),.enable_i(round_enable_w),.sign_i(control_q[13][8:7]!=0 ? control_q[13][6]:sign13_q),
    .double_i(control_q[13][12]),.rounding_i(control_q[13][11:9]),
    .exponent_i(exp13_q),.significand_i(sig13_q),.special_i(control_q[13][8:7]),
    .flags_i(control_q[13][5:1]),.value_o(value18_q),.flags_o(flags18_q));
  assign out_value_o=terminal_w[63:0];assign out_flags_o=terminal_w[68:64];
  genvar metadata_stage;
  generate for(metadata_stage=0;metadata_stage<3;metadata_stage=metadata_stage+1)begin:product_metadata
   always @(posedge clk)if(stage[metadata_stage+3].ready_w&&stage[metadata_stage+2].live_w)begin
    if(metadata_stage==0)begin
     c_mid_q[metadata_stage]<=c2_q;ep_mid_q[metadata_stage]<=ep2_q;ec_mid_q[metadata_stage]<=ec2_q;
     ps_mid_q[metadata_stage]<=ps2_q;cs_mid_q[metadata_stage]<=cs2_q;
    end else begin
     c_mid_q[metadata_stage]<=c_mid_q[metadata_stage-1];ep_mid_q[metadata_stage]<=ep_mid_q[metadata_stage-1];
     ec_mid_q[metadata_stage]<=ec_mid_q[metadata_stage-1];ps_mid_q[metadata_stage]<=ps_mid_q[metadata_stage-1];
     cs_mid_q[metadata_stage]<=cs_mid_q[metadata_stage-1];
    end
   end
  end endgenerate

  always @(posedge clk)begin
    if(stage[0].ready_w&&in_fire_i)begin
      a0_q<=sig_w[0];b0_q<=add_w ? 53'h10000000000000:sig_w[1];
      c0_q<=add_w ? sig_w[1]:mul_w ? 53'b0:sig_w[2];
      ea0_q<=exp_w[0];eb0_q<=add_w ? 14'sd0:exp_w[1];ec0_q<=add_w ? exp_w[1]:mul_w ? 14'sd0:exp_w[2];
      sign0_q<=sign_w;nan0_q<=nan_w;snan0_q<=snan_w;inf0_q<=inf_w;zero0_q<=zero_w;
      kind0_q<=kind_i;np0_q<=negate_product_i;nc0_q<=negate_addend_i;
    end
    if(stage[1].ready_w&&stage[0].live_w)begin
      a1_q<=normalized_sig_w[0];b1_q<=normalized_sig_w[1];c1_q<=normalized_sig_w[2];
      ea1_q<=normalized_exp_w[0];eb1_q<=normalized_exp_w[1];ec1_q<=normalized_exp_w[2];
      ps1_q<=psign1_w;cs1_q<=csign1_w;
    end
    if(stage[2].ready_w&&stage[1].live_w)begin
      c2_q<=c1_q;ep2_q<=ea1_q+eb1_q;ec2_q<=ec1_q;ps2_q<=ps1_q;cs2_q<=cs1_q;
    end
    if(stage[6].ready_w&&stage[5].live_w)begin
      c6_q<=c_mid_q[2];ep6_q<=ep_mid_q[2];ec6_q<=ec_mid_q[2];ps6_q<=ps_mid_q[2];cs6_q<=cs_mid_q[2];
    end
    if(stage[6].live_w)begin
      product7_q<=product6_q;c7_q<=c6_q;ep7_q<=ep6_q+$signed({13'b0,product6_q[105]});
      ec7_q<=ec6_q;ps7_q<=ps6_q;cs7_q<=cs6_q;
    end
    if(stage[7].live_w)begin
      big8_q<=product_larger_w?pbase_w:cbase_w;small8_q<=product_larger_w?cbase_w:pbase_w;
      distance8_q<=product_larger_w?distance_pc_w:distance_cp_w;
      reference8_q<=product_larger_w?ep7_q:ec7_q;
      subtract8_q<=ps7_q^cs7_q;sign8_q<=product_larger_w?ps7_q:cs7_q;
    end
    if(stage[8].live_w)begin
      big9_q<=big8_q;
      // Complementing the aligned small operand is independent of local carry preparation.
      small9_q<=shift_jam(small8_q,distance8_q)^{128{subtract8_q}};
      reference9_q<=reference8_q;subtract9_q<=subtract8_q;sign9_q<=sign8_q;
    end
    if(stage[9].live_w)begin
      base10_q<=base_w;propagate10_q<=propagate_w;generate10_q<=generate_w;
      subtract10_q<=subtract9_q;reference10_q<=reference9_q;sign10_q<=sign9_q;
    end
    if(stage[10].live_w)begin magnitude11_q<=sum_w;reference11_q<=reference10_q+14'sd3;sign11_q<=sign10_q;end
    if(stage[11].live_w)begin
      coarse12_q<=coarse_w[127:0];
      reference12_q<=reference11_q-$signed({7'b0,coarse_w[130:128],4'b0});
      sign12_q<=magnitude11_q==0?control_q[11][0]:sign11_q;
    end
    if(stage[12].live_w)begin
      sig13_q<=normalized_w[127:72]|{55'b0,(|normalized_w[71:0])};
      exp13_q<=reference12_q-$signed({10'b0,fine_w[131:128]});sign13_q<=sign12_q;
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk)if(!rst&&!flush_i)begin
    if(in_fire_i&&!in_ready_o)$fatal(1,"R64 FP FMA accepted without terminal reservation");
    if(in_fire_i&&kind_i==3)$fatal(1,"R64 FP FMA unknown operation");
    if(stage[11].live_w&&magnitude11_q[127])$fatal(1,"R64 FP magnitude overflow");
  end
`endif
endmodule
