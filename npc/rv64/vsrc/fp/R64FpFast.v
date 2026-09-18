// Short F/D class/compare/sign/move operations and pipelined conversions
// share one allocated-slot owner. A short result completes after two numeric
// stages; conversions use ten. No RAW operand travels with the completion
// owner, and every arithmetic producer has a slot reserved before it starts.
module R64FpFast #(parameter TAG_W=9,parameter ROB_W=5)(
 input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_fire_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 input [31:0] inst_i,input source_double_i,input [63:0] a_i,b_i,input [2:0] rounding_i,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,
 output [63:0] out_value_o,output [4:0] out_flags_o
);
 localparam STAGES=10,SLOT_W=4;
 localparam SIGN=0,DOUBLE=1,FROM_INT=5,TO_INT=6,CROSS=7,LONG=8,UNSIGNED=9,NAN=10,INVALID=11;
 wire [6:0] input_f7_w=inst_i[31:25];
 wire input_double_w=input_f7_w[0];
 wire cross_w=input_f7_w==7'h20||input_f7_w==7'h21;
 wire from_w=input_f7_w==7'h68||input_f7_w==7'h69;
 wire to_w=input_f7_w==7'h60||input_f7_w==7'h61;
 wire source_double_w=source_double_i;
 wire unsigned_w=inst_i[20],long_w=inst_i[21];
 wire integer_sign_w=!unsigned_w&&(long_w?a_i[63]:a_i[31]);
 wire [63:0] integer_input_w=long_w?a_i:unsigned_w?{32'b0,a_i[31:0]}:{{32{a_i[31]}},a_i[31:0]};
 wire [63:0] abox_w,bbox_w;wire [52:0] raw_sig_w;
 wire signed [13:0] base_exp_w;
 wire sa_w,sb_w,na_w,nb_w,sna_w,snb_w,ia_w,za_w,zb_w;
 R64FpDecompose #(.RAW_SPECIAL_NUMERIC(1)) ua(.value_i(a_i),.double_i(source_double_w),
  .boxed_o(abox_w),.sign_o(sa_w),.nan_o(na_w),.snan_o(sna_w),.inf_o(ia_w),.zero_o(za_w),
  .base_exponent_o(base_exp_w),.raw_significand_o(raw_sig_w));
 R64FpDecompose ub(.value_i(b_i),.double_i(input_double_w),.boxed_o(bbox_w),
  .sign_o(sb_w),.nan_o(nb_w),.snan_o(snb_w),.inf_o(),.zero_o(zb_w),
  .base_exponent_o(),.raw_significand_o());
 // [18:14] flags, [13:12] special, [11] integer-invalid, [10] NaN,
 // [9:5] unsigned/long/cross/to/from, [4:2] rm, [1:0] format/sign.
 wire [18:0] control_w={9'b0,
  unsigned_w,long_w,cross_w,to_w,from_w,rounding_i,input_double_w,from_w?integer_sign_w:sa_w};
 reg [18:0] control_q[0:STAGES-1];
 reg [STAGES-1:0] token_q;
 reg [SLOT_W-1:0] slot_q[0:STAGES-1];
 wire [SLOT_W-1:0] allocation_w;
 wire [68:0] completion_data_w;
 wire short1_w=!(control_q[1][FROM_INT]||control_q[1][TO_INT]||control_q[1][CROSS]);
 wire convert9_w=control_q[9][FROM_INT]||control_q[9][TO_INT]||control_q[9][CROSS];
 wire [63:0] direct1_q;
 wire [4:0] direct_flags1_q;
 wire [63:0] fp_value9_w,int_value9_q;
 wire [4:0] fp_flags9_w,int_flags9_q;
 wire [68:0] conversion_w=control_q[9][TO_INT]?{int_flags9_q,int_value9_q}:{fp_flags9_w,fp_value9_w};
 R64FpCompletion #(.SLOT_W(SLOT_W),.CAPACITY(14),.DATA_W(69),.TAG_W(TAG_W),.ROB_W(ROB_W)) owner(
  .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
  .in_valid_i(in_fire_i),.in_ready_o(in_ready_o),.in_tag_i(in_tag_i),.allocation_o(allocation_w),
  .complete_valid_i({token_q[9]&&convert9_w,token_q[1]&&short1_w}),
  .complete_slot_i({slot_q[9],slot_q[1]}),
  .complete_data_i({conversion_w,direct_flags1_q,direct1_q}),
  .out_valid_o(out_valid_o),.out_ready_i(out_ready_i),.out_tag_o(out_tag_o),.out_data_o(completion_data_w));
 assign out_value_o=completion_data_w[63:0];assign out_flags_o=completion_data_w[68:64];
 integer k;
 always @(posedge clk)begin
  if(rst||flush_i)token_q<=0;
  else token_q<={token_q[STAGES-2:0],in_fire_i&&in_ready_o};
  if(in_fire_i&&in_ready_o)begin slot_q[0]<=allocation_w;control_q[0]<=control_w;end
  for(k=1;k<STAGES;k=k+1)if(token_q[k-1])begin
   slot_q[k]<=slot_q[k-1];control_q[k]<=control_q[k-1];
  end
  // Aggregate special-value policy from the registered class flags. It
  // does not belong on the instruction-format input classification cone.
  if(token_q[0])begin
   control_q[1][18:14]<=control_q[0][CROSS]?{sna0_q,4'b0}:5'b0;
   control_q[1][13:12]<=na0_q?2'd3:ia0_q?2'd2:za0_q?2'd1:2'd0;
   control_q[1][INVALID]<=na0_q||ia0_q;
   control_q[1][NAN]<=na0_q;
  end
  if(token_q[1])control_q[2][INVALID]<=control_q[1][INVALID]||fp_exp_q[1]>=64;
 end
 reg [63:0] abox0_q,bbox0_q,move0_q,integer0_q;
 reg [52:0] raw0_q;
 reg signed [13:0] base0_q;
 reg [6:0] f7_0_q;reg [2:0] f3_0_q;
 reg sa0_q,sb0_q,na0_q,nb0_q,sna0_q,snb0_q,ia0_q,za0_q,zb0_q,subnormal0_q;
 wire [63:0] abox=abox0_q,bbox=bbox0_q;
 wire asign=sa0_q,bsign=sb0_q,anan=na0_q,bnan=nb0_q,asnan=sna0_q,bsnan=snb0_q;
 wire ainf=ia0_q,azero=za0_q,bzero=zb0_q,df=control_q[0][DOUBLE];
 wire [6:0] f7=f7_0_q;wire [2:0] f3=f3_0_q;
 // Independent byte comparisons enter with the operands. Stage1 only
 // merges eight compact relation pairs; no full-width compare feeds the
 // sign/min/max result mux in that same stage.
 wire [7:0] byte_eq_w,byte_lt_w;
 reg [7:0] byte_eq0_q,byte_lt0_q;reg single_eq0_q,single_lt0_q;
 genvar chunk;
 generate for(chunk=0;chunk<8;chunk=chunk+1)begin:compare_byte
  localparam N=chunk==7?7:8;
  assign byte_eq_w[chunk]=a_i[chunk*8+:N]==b_i[chunk*8+:N];
  assign byte_lt_w[chunk]=a_i[chunk*8+:N]<b_i[chunk*8+:N];
 end endgenerate
 wire [7:0] compare_eq_w=df?byte_eq0_q:{4'b1111,single_eq0_q,byte_eq0_q[2:0]};
 wire [7:0] compare_lt_w=df?byte_lt0_q:{4'b0,single_lt0_q,byte_lt0_q[2:0]};
 wire [3:0] pair_eq_w,pair_lt_w;wire [1:0] quad_eq_w,quad_lt_w;
 generate for(chunk=0;chunk<4;chunk=chunk+1)begin:compare_pair
  assign pair_eq_w[chunk]=&compare_eq_w[chunk*2+:2];
  assign pair_lt_w[chunk]=compare_lt_w[chunk*2+1]||
   (compare_eq_w[chunk*2+1]&&compare_lt_w[chunk*2]);
 end
 for(chunk=0;chunk<2;chunk=chunk+1)begin:compare_quad
  assign quad_eq_w[chunk]=&pair_eq_w[chunk*2+:2];
  assign quad_lt_w[chunk]=pair_lt_w[chunk*2+1]||
   (pair_eq_w[chunk*2+1]&&pair_lt_w[chunk*2]);
 end endgenerate
 wire magnitude_less=quad_lt_w[1]||(quad_eq_w[1]&&quad_lt_w[0]);
 wire equal_value=(azero&&bzero)||((&quad_eq_w)&&(asign==bsign));
 wire less_value=!(azero&&bzero)&&(asign!=bsign?asign:asign?!magnitude_less&&!equal_value:magnitude_less);
 reg [63:0] direct_w;
 reg [4:0] direct_flags_w;
 reg select_sign;
 reg [9:0] class_bits;
 always @(*)begin
   direct_w=0;direct_flags_w=0;select_sign=asign;class_bits=0;
   case(f7)
     7'h10,7'h11:begin
       case(f3)
         0:select_sign=bsign;
         1:select_sign=!bsign;
         default:select_sign=asign^bsign;
       endcase
       direct_w=df ? {select_sign,abox[62:0]}:{32'hffffffff,select_sign,abox[30:0]};
     end
     7'h14,7'h15:begin
       direct_flags_w[4]=asnan||bsnan;
       if(anan&&bnan)direct_w=df ? 64'h7ff8000000000000:64'hffffffff7fc00000;
       else if(anan)direct_w=bbox;
       else if(bnan)direct_w=abox;
       else if(azero&&bzero)begin
         select_sign=f3[0] ? asign&&bsign:asign||bsign;
         direct_w=df ? {select_sign,63'b0}:{32'hffffffff,select_sign,31'b0};
       end else direct_w=(less_value^f3[0]) ? abox:bbox;
     end
     7'h50,7'h51:begin
       direct_flags_w[4]=f3==2 ? asnan||bsnan:anan||bnan;
       direct_w={63'b0,(!anan&&!bnan&&(f3==2 ? equal_value:f3==1 ? less_value:less_value||equal_value))};
     end
     7'h70,7'h71:begin
       if(f3==0)direct_w=df ? move0_q:{{32{move0_q[31]}},move0_q[31:0]};
       else begin
         if(anan)class_bits[asnan ? 8:9]=1;
         else if(ainf)class_bits[asign ? 0:7]=1;
         else if(azero)class_bits[asign ? 3:4]=1;
         else if(subnormal0_q)class_bits[asign ? 2:5]=1;
         else class_bits[asign ? 1:6]=1;
         direct_w={54'b0,class_bits};
       end
     end
     7'h78,7'h79:direct_w=df ? move0_q:{32'hffffffff,move0_q[31:0]};
     default:begin end
   endcase
 end

 reg [63:0] direct1_reg_q;reg [4:0] direct_flags1_reg_q;
 assign direct1_q=direct1_reg_q;assign direct_flags1_q=direct_flags1_reg_q;
 wire [63:0] abs_base_w,absolute_w;wire [15:0] abs_p_w,abs_g_w;
 reg [63:0] abs_base1_q,absolute2_q;
 reg [15:0] abs_p1_q,abs_g1_q;
 R64CarryPrepare #(.WIDTH(64),.BLOCK(4)) abs_prepare(
  .a_i(control_q[0][SIGN]?~integer0_q:integer0_q),.b_i(64'b0),
  .base_o(abs_base_w),.propagate_o(abs_p_w),.generate_o(abs_g_w));
 R64CarryFinish #(.WIDTH(64),.BLOCK(4)) abs_finish(.base_i(abs_base1_q),
  .propagate_i(abs_p1_q),.generate_i(abs_g1_q),.carry_i(control_q[1][SIGN]),.sum_o(absolute_w),.carry_o());
 wire [52:0] fp_sig_w;wire signed [13:0] fp_exp_w;
 R64FpNormalize #(.IEEE_INPUT(1)) normalize(.raw_significand_i(raw0_q),.base_exponent_i(base0_q),
  .significand_o(fp_sig_w),.exponent_o(fp_exp_w));
 reg [52:0] fp_sig_q[1:3];reg signed [13:0] fp_exp_q[1:3];
 function [66:0] coarse_normalize;
  input [63:0] value;reg [63:0] scan;reg [2:0] count;
  begin
   scan=value;count=0;
   if(scan[63:32]==0)begin scan=scan<<32;count=count+3'd4;end
   if(scan[63:48]==0)begin scan=scan<<16;count=count+3'd2;end
   if(scan[63:56]==0)begin scan=scan<<8;count=count+3'd1;end
   coarse_normalize={count,scan};
  end
 endfunction
 function [66:0] fine_normalize;
  input [63:0] value;reg [63:0] scan;reg [2:0] count;
  begin
   scan=value;count=0;
   if(scan[63:60]==0)begin scan=scan<<4;count=count+3'd4;end
   if(scan[63:62]==0)begin scan=scan<<2;count=count+3'd2;end
   if(!scan[63])begin scan=scan<<1;count=count+3'd1;end
   fine_normalize={count,scan};
  end
 endfunction
 wire [66:0] coarse_w=coarse_normalize(absolute2_q);
 reg [63:0] coarse3_q;reg [2:0] coarse_count3_q;reg integer_zero3_q;
 wire [66:0] fine_w=fine_normalize(coarse3_q);
 wire [5:0] integer_count_w={coarse_count3_q,fine_w[66:64]};
 reg [55:0] round_sig4_q;reg signed [13:0] round_exp4_q;reg [1:0] round_special4_q;
 wire [4:0] round_enable_w=token_q[8:4]&~{5{1'b0}};
 R64FpRoundPipe round(.clk(clk),.enable_i(round_enable_w),
  .sign_i(control_q[4][SIGN]),.double_i(control_q[4][DOUBLE]),.rounding_i(control_q[4][4:2]),
  .exponent_i(round_exp4_q),.significand_i(round_sig4_q),.special_i(round_special4_q),
  .flags_i(control_q[4][18:14]),.value_o(fp_value9_w),.flags_o(fp_flags9_w));

 // FP -> integer aligns a Q64 fixed-point significand over two phases.
 reg [13:0] shift2_q;reg left2_q;
 reg [127:0] fixed3_q,fixed4_q;
 function [127:0] coarse_align;
  input [127:0] value;input [13:0] distance;input left;
  reg [127:0] shifted;
  begin
   shifted=value;
   if(left)begin
    if(distance[4])shifted=shifted<<16;
    if(distance[5])shifted=shifted<<32;
    if(distance[6])shifted=shifted<<64;
    coarse_align=(|distance[13:7])?128'b0:shifted;
   end else begin
    if(distance[4])shifted={16'b0,shifted[127:16]}|{127'b0,(|shifted[15:0])};
    if(distance[5])shifted={32'b0,shifted[127:32]}|{127'b0,(|shifted[31:0])};
    if(distance[6])shifted={64'b0,shifted[127:64]}|{127'b0,(|shifted[63:0])};
    coarse_align=(|distance[13:7])?{127'b0,|value}:shifted;
   end
  end
 endfunction
 function [127:0] fine_align;
  input [127:0] value;input [3:0] distance;input left;
  reg [127:0] shifted;
  begin
   shifted=value;
   if(left)fine_align=shifted<<distance;
   else begin
    if(distance[0])shifted={1'b0,shifted[127:1]}|{127'b0,shifted[0]};
    if(distance[1])shifted={2'b0,shifted[127:2]}|{127'b0,(|shifted[1:0])};
    if(distance[2])shifted={4'b0,shifted[127:4]}|{127'b0,(|shifted[3:0])};
    if(distance[3])shifted={8'b0,shifted[127:8]}|{127'b0,(|shifted[7:0])};
    fine_align=shifted;
   end
  end
 endfunction
 reg [3:0] shift3_q;reg left3_q;
 wire int_inexact_w=|fixed4_q[63:0];wire int_increment_w;
 R64FpRoundDecision int_decision(.sign_i(control_q[4][SIGN]),.rounding_i(control_q[4][4:2]),
  .guard_i(fixed4_q[63]),.sticky_i(|fixed4_q[62:0]),.lsb_i(fixed4_q[64]),
  .increment_o(int_increment_w),.inexact_o());
 wire [64:0] int_base_w,int_rounded_w;wire [16:0] int_p_w,int_g_w;
 reg [64:0] int_base5_q,int_rounded6_q;reg [16:0] int_p5_q,int_g5_q;
 reg [4:0] inexact_q;
 R64CarryPrepare #(.WIDTH(65),.BLOCK(4)) int_prepare(.a_i({1'b0,fixed4_q[127:64]}),
  .b_i({64'b0,int_increment_w}),.base_o(int_base_w),.propagate_o(int_p_w),.generate_o(int_g_w));
 R64CarryFinish #(.WIDTH(65),.BLOCK(4)) int_finish(.base_i(int_base5_q),
  .propagate_i(int_p5_q),.generate_i(int_g5_q),.carry_i(1'b0),.sum_o(int_rounded_w),.carry_o());
 wire [64:0] limit_w=control_q[6][LONG]?
  (control_q[6][UNSIGNED]?65'h0ffffffffffffffff:control_q[6][SIGN]?65'h08000000000000000:65'h07fffffffffffffff):
  (control_q[6][UNSIGNED]?65'h000000000ffffffff:control_q[6][SIGN]?65'h00000000080000000:65'h0000000007fffffff);
 wire int_invalid_w=control_q[6][INVALID]||(int_rounded6_q>limit_w)||
  (control_q[6][UNSIGNED]&&control_q[6][SIGN]&&int_rounded6_q!=0);
 wire [63:0] saturated_w=control_q[6][UNSIGNED]?
  ((!control_q[6][NAN]&&control_q[6][SIGN])?64'b0:control_q[6][LONG]?64'hffffffffffffffff:64'h00000000ffffffff):
  ((!control_q[6][NAN]&&control_q[6][SIGN])?
   (control_q[6][LONG]?64'h8000000000000000:64'hffffffff80000000):
   (control_q[6][LONG]?64'h7fffffffffffffff:64'h000000007fffffff));
 wire [63:0] sign_base_w,signed_w;wire [15:0] sign_p_w,sign_g_w;
 reg [63:0] sign_base7_q,signed8_q,saturated7_q,saturated8_q;
 reg [15:0] sign_p7_q,sign_g7_q;reg invalid7_q,invalid8_q;
 R64CarryPrepare #(.WIDTH(64),.BLOCK(4)) sign_prepare(
  .a_i(control_q[6][SIGN]?~int_rounded6_q[63:0]:int_rounded6_q[63:0]),.b_i(64'b0),
  .base_o(sign_base_w),.propagate_o(sign_p_w),.generate_o(sign_g_w));
 R64CarryFinish #(.WIDTH(64),.BLOCK(4)) sign_finish(.base_i(sign_base7_q),
  .propagate_i(sign_p7_q),.generate_i(sign_g7_q),.carry_i(control_q[7][SIGN]),.sum_o(signed_w),.carry_o());
 reg [63:0] int_value9_reg_q;reg [4:0] int_flags9_reg_q;
 wire [63:0] chosen_integer_w=invalid8_q?saturated8_q:signed8_q;
 assign int_value9_q=int_value9_reg_q;assign int_flags9_q=int_flags9_reg_q;
 always @(posedge clk)begin
  if(in_fire_i&&in_ready_o)begin
   byte_eq0_q<=byte_eq_w;byte_lt0_q<=byte_lt_w;
   single_eq0_q<=a_i[30:24]==b_i[30:24];single_lt0_q<=a_i[30:24]<b_i[30:24];
   abox0_q<=abox_w;bbox0_q<=bbox_w;move0_q<=a_i;integer0_q<=integer_input_w;
   raw0_q<=raw_sig_w;base0_q<=base_exp_w;f7_0_q<=input_f7_w;f3_0_q<=inst_i[14:12];
   sa0_q<=sa_w;sb0_q<=sb_w;na0_q<=na_w;nb0_q<=nb_w;sna0_q<=sna_w;snb0_q<=snb_w;
   ia0_q<=ia_w;za0_q<=za_w;zb0_q<=zb_w;
   subnormal0_q<=source_double_w?a_i[62:52]==0:a_i[30:23]==0;
  end
  if(token_q[0])begin
   direct1_reg_q<=direct_w;direct_flags1_reg_q<=direct_flags_w;
   abs_base1_q<=abs_base_w;abs_p1_q<=abs_p_w;abs_g1_q<=abs_g_w;
   fp_sig_q[1]<=fp_sig_w;fp_exp_q[1]<=fp_exp_w;
  end
  if(token_q[1])begin
   absolute2_q<=absolute_w;fp_sig_q[2]<=fp_sig_q[1];fp_exp_q[2]<=fp_exp_q[1];
   shift2_q<=fp_exp_q[1][13]?-fp_exp_q[1]:fp_exp_q[1];left2_q<=!fp_exp_q[1][13];
  end
  if(token_q[2])begin
   coarse3_q<=coarse_w[63:0];coarse_count3_q<=coarse_w[66:64];integer_zero3_q<=absolute2_q==0;
   fp_sig_q[3]<=fp_sig_q[2];fp_exp_q[3]<=fp_exp_q[2];
   fixed3_q<=coarse_align({63'b0,fp_sig_q[2],12'b0},shift2_q,left2_q);
   shift3_q<=shift2_q[3:0];left3_q<=left2_q;
  end
  if(token_q[3])begin
   round_sig4_q<=control_q[3][FROM_INT]?(fine_w[63:8]|{55'b0,(|fine_w[7:0])}):{fp_sig_q[3],3'b0};
   round_exp4_q<=control_q[3][FROM_INT]?$signed({8'b0,~integer_count_w}):fp_exp_q[3];
   round_special4_q<=control_q[3][FROM_INT]?(integer_zero3_q?2'd1:2'd0):control_q[3][13:12];
   fixed4_q<=fine_align(fixed3_q,shift3_q,left3_q);
  end
  if(token_q[4])begin
   int_base5_q<=int_base_w;int_p5_q<=int_p_w;int_g5_q<=int_g_w;inexact_q[0]<=int_inexact_w;
  end
  if(token_q[5])begin int_rounded6_q<=int_rounded_w;inexact_q[1]<=inexact_q[0];end
  if(token_q[6])begin
   sign_base7_q<=sign_base_w;sign_p7_q<=sign_p_w;sign_g7_q<=sign_g_w;
   invalid7_q<=int_invalid_w;saturated7_q<=saturated_w;inexact_q[2]<=inexact_q[1];
  end
  if(token_q[7])begin
   signed8_q<=signed_w;invalid8_q<=invalid7_q;saturated8_q<=saturated7_q;inexact_q[3]<=inexact_q[2];
  end
  if(token_q[8])begin
   int_value9_reg_q<=control_q[8][LONG]?chosen_integer_w:{{32{chosen_integer_w[31]}},chosen_integer_w[31:0]};
   int_flags9_reg_q<={invalid8_q,3'b0,!invalid8_q&&inexact_q[3]};
  end
 end
`ifdef R64_ASSERT
 always @(posedge clk)if(!rst&&!flush_i&&in_fire_i&&!in_ready_o)
  $fatal(1,"R64 FP fast accepted without completion capacity");
`endif
endmodule
